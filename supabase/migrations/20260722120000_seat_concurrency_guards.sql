-- ============================================================
-- Seat concurrency guards
--
-- Makes double-booking physically impossible at the database
-- level. Application-side holds are a UX affordance only; these
-- constraints are what actually serialise competing writers.
--
-- Safe to re-run. Aborts with a readable message if existing
-- data already violates a constraint we are about to add.
-- ============================================================

-- ------------------------------------------------------------
-- 0. Pre-flight: refuse to run against already-conflicting data
-- ------------------------------------------------------------

DO $$
DECLARE
  dup_bookings int;
  dup_trips    int;
BEGIN
  SELECT count(*) INTO dup_bookings FROM (
    SELECT trip_id, seat_number
    FROM bookings
    WHERE status IN ('confirmed', 'pending', 'boarded')
    GROUP BY trip_id, seat_number
    HAVING count(*) > 1
  ) d;

  IF dup_bookings > 0 THEN
    RAISE EXCEPTION
      'Cannot add seat uniqueness: % seat(s) are already double-booked. Run the audit query in the migration header comment, resolve the duplicates (cancel the later booking), then re-run.',
      dup_bookings;
  END IF;

  SELECT count(*) INTO dup_trips FROM (
    SELECT schedule_id, trip_date
    FROM trips
    GROUP BY schedule_id, trip_date
    HAVING count(*) > 1
  ) d;

  IF dup_trips > 0 THEN
    RAISE EXCEPTION
      'Cannot add trip uniqueness: % duplicate (schedule_id, trip_date) pair(s) exist. Merge their bookings onto one trip row first.',
      dup_trips;
  END IF;
END $$;

-- Audit query for resolving duplicates by hand:
--
--   SELECT trip_id, seat_number, count(*), array_agg(id) AS booking_ids
--   FROM bookings
--   WHERE status IN ('confirmed','pending','boarded')
--   GROUP BY trip_id, seat_number HAVING count(*) > 1;

-- ------------------------------------------------------------
-- 1. trips — one trip row per schedule per date
--
-- Without this, two passengers hitting a schedule that has no
-- trip row yet can each create one, splitting the seat map
-- across two trips and defeating every other guard here.
-- ------------------------------------------------------------

CREATE UNIQUE INDEX IF NOT EXISTS trips_schedule_date_unique
  ON trips (schedule_id, trip_date);

-- ------------------------------------------------------------
-- 2. seat_holds — one live hold per seat per trip
--
-- Holds are ephemeral, so de-duplicating by deletion is safe.
-- ------------------------------------------------------------

DELETE FROM seat_holds WHERE expires_at < now();

DELETE FROM seat_holds a
  USING seat_holds b
 WHERE a.ctid < b.ctid
   AND a.trip_id = b.trip_id
   AND a.seat_number = b.seat_number;

-- The table may already carry an equivalent constraint under a
-- different name (e.g. unique_trip_seat_hold). IF NOT EXISTS only
-- compares the index name, so check the columns to avoid creating a
-- redundant duplicate index.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM pg_constraint
     WHERE conrelid = 'seat_holds'::regclass
       AND contype  = 'u'
       AND pg_get_constraintdef(oid) ILIKE 'UNIQUE (trip_id, seat_number)'
  ) AND NOT EXISTS (
    SELECT 1
      FROM pg_indexes
     WHERE tablename = 'seat_holds'
       AND indexdef ILIKE '%UNIQUE%(trip_id, seat_number)%'
  ) THEN
    CREATE UNIQUE INDEX seat_holds_trip_seat_unique
      ON seat_holds (trip_id, seat_number);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS seat_holds_expires_at_idx
  ON seat_holds (expires_at);

-- ------------------------------------------------------------
-- 3. bookings — one active booking per seat per trip
--
-- Partial, so cancelling a booking frees the seat for resale.
-- ------------------------------------------------------------

CREATE UNIQUE INDEX IF NOT EXISTS bookings_trip_seat_active_unique
  ON bookings (trip_id, seat_number)
  WHERE status IN ('confirmed', 'pending', 'boarded');

-- ------------------------------------------------------------
-- 4. clean_expired_holds()
--
-- RLS restricts DELETE on seat_holds to a row's own passenger,
-- so clients cannot reap other users' abandoned holds. Combined
-- with the unique index above that would let one abandoned
-- checkout block a seat permanently. SECURITY DEFINER lets this
-- run above RLS.
-- ------------------------------------------------------------

-- An earlier hand-created version returns void; a return type cannot
-- be changed in place, so drop it first. Callers use PERFORM, which
-- resolves at runtime, so nothing depends on it structurally.
DROP FUNCTION IF EXISTS public.clean_expired_holds();

CREATE OR REPLACE FUNCTION public.clean_expired_holds()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  removed integer;
BEGIN
  DELETE FROM seat_holds WHERE expires_at < now();
  GET DIAGNOSTICS removed = ROW_COUNT;
  RETURN removed;
END;
$$;

GRANT EXECUTE ON FUNCTION public.clean_expired_holds() TO authenticated, anon;

-- ------------------------------------------------------------
-- 5. Scheduled reaping (optional — needs the pg_cron extension)
--
-- The app also calls clean_expired_holds() opportunistically, so
-- this is a safety net rather than a requirement. Enable pg_cron
-- under Database → Extensions first, then run:
--
--   SELECT cron.schedule(
--     'clean-expired-seat-holds', '*/5 * * * *',
--     $$SELECT public.clean_expired_holds()$$
--   );
-- ------------------------------------------------------------
