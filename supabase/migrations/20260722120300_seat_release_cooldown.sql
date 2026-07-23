-- ============================================================
-- Seat release cooldown
--
-- Abandoning checkout no longer frees the seat instantly. The
-- hold is converted into a short "cooldown" that blocks every
-- passenger — including the one who just released it — until it
-- lapses.
--
-- A cooldown row is an ordinary seat_holds row with is_cooldown
-- set, so clean_expired_holds() already reaps it and the unique
-- index still applies.
-- ============================================================

ALTER TABLE seat_holds
  ADD COLUMN IF NOT EXISTS is_cooldown boolean NOT NULL DEFAULT false;

-- ------------------------------------------------------------
-- release_seats() — convert my holds into a cooldown
--
-- SECURITY DEFINER because the row must survive as a blocker
-- that its own owner cannot immediately reclaim; the ownership
-- check is enforced below instead of by RLS.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.release_seats(
  p_trip_id          uuid,
  p_seats            text[],
  p_cooldown_seconds integer DEFAULT 30
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid     uuid := auth.uid();
  v_touched integer;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'AUTH_REQUIRED';
  END IF;

  IF p_seats IS NULL OR array_length(p_seats, 1) IS NULL THEN
    RETURN 0;
  END IF;

  -- A zero/negative cooldown means "free it immediately".
  IF p_cooldown_seconds <= 0 THEN
    DELETE FROM seat_holds
     WHERE trip_id      = p_trip_id
       AND passenger_id = v_uid
       AND seat_number  = ANY (p_seats);
    GET DIAGNOSTICS v_touched = ROW_COUNT;
    RETURN v_touched;
  END IF;

  UPDATE seat_holds
     SET expires_at  = now() + make_interval(secs => p_cooldown_seconds),
         is_cooldown = true
   WHERE trip_id      = p_trip_id
     AND passenger_id = v_uid
     AND seat_number  = ANY (p_seats);

  GET DIAGNOSTICS v_touched = ROW_COUNT;
  RETURN v_touched;
END;
$$;

GRANT EXECUTE ON FUNCTION public.release_seats(uuid, text[], integer)
  TO authenticated;

-- ------------------------------------------------------------
-- hold_seats() — respect an active cooldown
--
-- Previously a passenger could always reclaim their own hold.
-- A cooldown row must now block even its owner until it lapses,
-- otherwise releasing and immediately re-selecting would bypass
-- the cooldown entirely.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.hold_seats(
  p_trip_id     uuid,
  p_seats       text[],
  p_ttl_seconds integer DEFAULT 600
)
RETURNS TABLE (held_seat text, expires timestamptz)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid    uuid        := auth.uid();
  v_expiry timestamptz := now() + make_interval(secs => p_ttl_seconds);
  v_taken  text[];
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'AUTH_REQUIRED';
  END IF;

  IF p_seats IS NULL OR array_length(p_seats, 1) IS NULL THEN
    RAISE EXCEPTION 'NO_SEATS';
  END IF;

  PERFORM public.clean_expired_holds();

  SELECT array_agg(DISTINCT b.seat_number::text) INTO v_taken
    FROM bookings b
   WHERE b.trip_id     = p_trip_id
     AND b.seat_number = ANY (p_seats)
     AND b.status IN ('confirmed', 'pending', 'boarded');

  IF v_taken IS NOT NULL THEN
    RAISE EXCEPTION 'SEAT_TAKEN:%', array_to_string(v_taken, ',');
  END IF;

  -- Seats sitting in an active cooldown are refused outright, so the
  -- caller gets COOLDOWN rather than a misleading "someone else has it".
  SELECT array_agg(DISTINCT h.seat_number::text) INTO v_taken
    FROM seat_holds h
   WHERE h.trip_id     = p_trip_id
     AND h.seat_number = ANY (p_seats)
     AND h.is_cooldown
     AND h.expires_at  > now();

  IF v_taken IS NOT NULL THEN
    RAISE EXCEPTION 'COOLDOWN:%', array_to_string(v_taken, ',');
  END IF;

  RETURN QUERY
  WITH upserted AS (
    INSERT INTO seat_holds (trip_id, seat_number, passenger_id, expires_at, is_cooldown)
    SELECT p_trip_id, s, v_uid, v_expiry, false
      FROM unnest(p_seats) AS s
    ON CONFLICT (trip_id, seat_number) DO UPDATE
       SET passenger_id = EXCLUDED.passenger_id,
           expires_at   = EXCLUDED.expires_at,
           is_cooldown  = false
     WHERE seat_holds.expires_at < now()
        OR (seat_holds.passenger_id = EXCLUDED.passenger_id
            AND NOT seat_holds.is_cooldown)
    RETURNING seat_holds.seat_number, seat_holds.expires_at
  )
  SELECT upserted.seat_number::text, upserted.expires_at FROM upserted;
END;
$$;

GRANT EXECUTE ON FUNCTION public.hold_seats(uuid, text[], integer)
  TO authenticated;
