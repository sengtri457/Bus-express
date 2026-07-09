-- ============================================================
-- FIX: RLS policies for seat_holds table
-- ============================================================

ALTER TABLE seat_holds ENABLE ROW LEVEL SECURITY;

-- Allow ALL authenticated users to see ALL seat holds (needed for seat selection screen).
DROP POLICY IF EXISTS "Anyone can view seat holds" ON seat_holds;
CREATE POLICY "Anyone can view seat holds"
  ON seat_holds FOR SELECT
  USING (true);

-- Each user can only insert their own seat holds.
DROP POLICY IF EXISTS "Users can insert their own seat holds" ON seat_holds;
CREATE POLICY "Users can insert their own seat holds"
  ON seat_holds FOR INSERT
  WITH CHECK (auth.uid() = passenger_id);

-- Each user can delete their own seat holds.
DROP POLICY IF EXISTS "Users can delete their own seat holds" ON seat_holds;
CREATE POLICY "Users can delete their own seat holds"
  ON seat_holds FOR DELETE
  USING (auth.uid() = passenger_id);
