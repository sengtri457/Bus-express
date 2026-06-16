-- ============================================================
-- FIX: RLS policies for bookings & trips
-- Run this in your Supabase SQL Editor (Dashboard → SQL Editor)
-- ============================================================

-- ── BOOKINGS ──────────────────────────────────────────────────
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- Allow ALL authenticated users to see ALL bookings (needed for seat availability).
DROP POLICY IF EXISTS "Anyone can view bookings" ON bookings;
CREATE POLICY "Anyone can view bookings"
  ON bookings FOR SELECT
  USING (true);

-- Each user can only insert their own booking.
DROP POLICY IF EXISTS "Users can insert their own bookings" ON bookings;
CREATE POLICY "Users can insert their own bookings"
  ON bookings FOR INSERT
  WITH CHECK (auth.uid() = passenger_id);

-- Each user can update their own booking (e.g. cancellation).
DROP POLICY IF EXISTS "Users can update their own bookings" ON bookings;
CREATE POLICY "Users can update their own bookings"
  ON bookings FOR UPDATE
  USING (auth.uid() = passenger_id);

-- ── TRIPS ─────────────────────────────────────────────────────
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;

-- Allow ALL authenticated users to see trips.
DROP POLICY IF EXISTS "Anyone can view trips" ON trips;
CREATE POLICY "Anyone can view trips"
  ON trips FOR SELECT
  USING (true);

-- Allow any authenticated user to insert a trip (booking flow).
DROP POLICY IF EXISTS "Authenticated users can insert trips" ON trips;
CREATE POLICY "Authenticated users can insert trips"
  ON trips FOR INSERT
  WITH CHECK (true);

-- Allow drivers / conductors to update trips (status, GPS coordinates).
DROP POLICY IF EXISTS "Authenticated users can update trips" ON trips;
CREATE POLICY "Authenticated users can update trips"
  ON trips FOR UPDATE
  USING (true)
  WITH CHECK (true);

-- ── TICKETS & PAYMENTS (read-only for ticket display) ────────
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own tickets" ON tickets;
CREATE POLICY "Users can view their own tickets"
  ON tickets FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM bookings
      WHERE bookings.id = tickets.booking_id
        AND bookings.passenger_id = auth.uid()
    )
  );

ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own payments" ON payments;
CREATE POLICY "Users can view their own payments"
  ON payments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM bookings
      WHERE bookings.id = payments.booking_id
        AND bookings.passenger_id = auth.uid()
    )
  );
