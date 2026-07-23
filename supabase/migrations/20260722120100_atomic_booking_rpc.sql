-- ============================================================
-- Atomic multi-seat booking
--
-- Replaces the per-seat insert loop in the confirmation screen.
-- A function body is one transaction, so a conflict on the last
-- seat rolls back the earlier ones instead of leaving a partial
-- booking that the passenger has already been charged for.
--
-- Also enforces that the caller actually owns a live hold on
-- every seat, closing the window where a hold expired while the
-- passenger sat on the confirmation screen.
--
-- Depends on 20260722120000_seat_concurrency_guards.sql.
-- ============================================================

CREATE OR REPLACE FUNCTION public.create_pending_bookings(
  p_trip_id     uuid,
  p_seats       text[],
  p_price       numeric,
  p_name        text DEFAULT NULL,
  p_age         int  DEFAULT NULL,
  p_phone       text DEFAULT NULL,
  p_nationality text DEFAULT NULL
)
RETURNS TABLE (booking_id uuid, seat text)
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_uid     uuid := auth.uid();
  v_missing text[];
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'AUTH_REQUIRED';
  END IF;

  IF p_seats IS NULL OR array_length(p_seats, 1) IS NULL THEN
    RAISE EXCEPTION 'NO_SEATS';
  END IF;

  -- Reap stale holds first (SECURITY DEFINER, so it clears every
  -- passenger's expired rows, not just this caller's).
  PERFORM public.clean_expired_holds();

  -- Every requested seat must still be held by this caller.
  SELECT array_agg(s) INTO v_missing
    FROM unnest(p_seats) AS s
   WHERE NOT EXISTS (
     SELECT 1
       FROM seat_holds h
      WHERE h.trip_id      = p_trip_id
        AND h.seat_number  = s
        AND h.passenger_id = v_uid
        AND h.expires_at   > now()
   );

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'HOLD_EXPIRED:%', array_to_string(v_missing, ',');
  END IF;

  RETURN QUERY
  WITH inserted AS (
    INSERT INTO bookings (
      trip_id, passenger_id, seat_number, status, total_price,
      booked_at, booking_channel,
      passenger_name, passenger_age, passenger_phone, passenger_nationality
    )
    SELECT p_trip_id, v_uid, s, 'pending', p_price,
           now(), 'online',
           p_name, p_age, p_phone, p_nationality
      FROM unnest(p_seats) AS s
    RETURNING id, seat_number
  )
  -- seat_number is varchar; cast to match the declared RETURNS TABLE type.
  SELECT inserted.id, inserted.seat_number::text FROM inserted;

EXCEPTION
  WHEN unique_violation THEN
    -- Someone else confirmed one of these seats between our hold
    -- check and the insert. The whole batch is rolled back.
    RAISE EXCEPTION 'SEAT_TAKEN';
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_pending_bookings(
  uuid, text[], numeric, text, int, text, text
) TO authenticated;


-- ============================================================
-- Trip resolution, race-free
--
-- The app lazily creates a trip row when none exists for a
-- schedule/date. Two passengers arriving together could each
-- create one, splitting the seat map. Paired with the unique
-- index on (schedule_id, trip_date), this always returns the
-- single winning row.
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_or_create_trip(
  p_schedule_id  uuid,
  p_trip_date    date,
  p_bus_id       uuid DEFAULT NULL,
  p_driver_id    uuid DEFAULT NULL,
  p_conductor_id uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_trip_id uuid;
BEGIN
  INSERT INTO trips (schedule_id, trip_date, bus_id, driver_id, conductor_id, status)
  VALUES (p_schedule_id, p_trip_date, p_bus_id, p_driver_id, p_conductor_id, 'scheduled')
  ON CONFLICT (schedule_id, trip_date) DO NOTHING
  RETURNING id INTO v_trip_id;

  IF v_trip_id IS NULL THEN
    SELECT id INTO v_trip_id
      FROM trips
     WHERE schedule_id = p_schedule_id
       AND trip_date   = p_trip_date;
  END IF;

  RETURN v_trip_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_or_create_trip(uuid, date, uuid, uuid, uuid)
  TO authenticated;
