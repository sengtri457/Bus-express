-- ============================================================
-- FIX: Enable Public Read Access for Routes, Schedules, & Buses
-- Run this in your Supabase SQL Editor (Dashboard → SQL Editor)
-- Or push it using Supabase CLI (supabase db push)
-- ============================================================

-- ── ROUTES ────────────────────────────────────────────────────
ALTER TABLE routes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view routes" ON routes;
CREATE POLICY "Anyone can view routes"
  ON routes FOR SELECT
  USING (true);

-- ── SCHEDULES ─────────────────────────────────────────────────
ALTER TABLE schedules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view schedules" ON schedules;
CREATE POLICY "Anyone can view schedules"
  ON schedules FOR SELECT
  USING (true);

-- ── BUSES ─────────────────────────────────────────────────────
ALTER TABLE buses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view buses" ON buses;
CREATE POLICY "Anyone can view buses"
  ON buses FOR SELECT
  USING (true);
