-- ============================================================
-- Race-free seat holding
--
-- The unique index added in 20260722120000 means a plain INSERT
-- now fails whenever any hold row exists for a seat — including
-- a stale one the same passenger left behind, which surfaced to
-- users as "reserved by another passenger" on their own seats.
--
-- This upserts instead:
--   * my own hold        -> extended
--   * an expired hold    -> taken over
--   * someone else's live hold -> left alone, seat reported taken
--
-- SECURITY DEFINER because seat_holds has no UPDATE policy, and
-- because taking over another passenger's expired row is exactly
-- what RLS is there to prevent. The rules are enforced by the
-- WHERE clause below instead.
-- ============================================================

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

  -- A confirmed/pending/boarded booking always wins over a hold.
  -- seat_number is varchar; cast so it matches the text[] locals and the
  -- declared RETURNS TABLE types (PL/pgSQL will not widen it implicitly).
  SELECT array_agg(DISTINCT b.seat_number::text) INTO v_taken
    FROM bookings b
   WHERE b.trip_id     = p_trip_id
     AND b.seat_number = ANY (p_seats)
     AND b.status IN ('confirmed', 'pending', 'boarded');

  IF v_taken IS NOT NULL THEN
    RAISE EXCEPTION 'SEAT_TAKEN:%', array_to_string(v_taken, ',');
  END IF;

  RETURN QUERY
  WITH upserted AS (
    INSERT INTO seat_holds (trip_id, seat_number, passenger_id, expires_at)
    SELECT p_trip_id, s, v_uid, v_expiry
      FROM unnest(p_seats) AS s
    ON CONFLICT (trip_id, seat_number) DO UPDATE
       SET passenger_id = EXCLUDED.passenger_id,
           expires_at   = EXCLUDED.expires_at
     WHERE seat_holds.passenger_id = EXCLUDED.passenger_id
        OR seat_holds.expires_at   < now()
    RETURNING seat_holds.seat_number, seat_holds.expires_at
  )
  SELECT upserted.seat_number::text, upserted.expires_at FROM upserted;
END;
$$;

GRANT EXECUTE ON FUNCTION public.hold_seats(uuid, text[], integer)
  TO authenticated;
