-- ============================================================
-- FIX: RLS policies for operators table & Storage bucket
-- Run this in your Supabase SQL Editor
-- ============================================================

-- Helper function: check if the current user is a super_admin.
-- Uses SECURITY DEFINER to bypass any RLS on the users table.
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND role = 'super_admin'
  );
$$;

-- ── STORAGE BUCKET: operator-logos ──────────────────────────
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'operator-logos',
  'operator-logos',
  true,
  5242880,
  ARRAY['image/png', 'image/jpeg', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Allow authenticated users to upload logos
DROP POLICY IF EXISTS "Authenticated users can upload operator logos" ON storage.objects;
CREATE POLICY "Authenticated users can upload operator logos"
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'operator-logos'
    AND auth.role() = 'authenticated'
  );

-- Allow public read access to logos
DROP POLICY IF EXISTS "Public can read operator logos" ON storage.objects;
CREATE POLICY "Public can read operator logos"
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'operator-logos');

-- ── OPERATORS ───────────────────────────────────────────────
ALTER TABLE operators ENABLE ROW LEVEL SECURITY;

-- Allow super_admin full access to operators
DROP POLICY IF EXISTS "Super admin can manage operators" ON operators;
CREATE POLICY "Super admin can manage operators"
  ON operators
  FOR ALL
  USING (public.is_super_admin())
  WITH CHECK (public.is_super_admin());

-- Allow all authenticated users to read operators (needed for lookups)
DROP POLICY IF EXISTS "Anyone can view operators" ON operators;
CREATE POLICY "Anyone can view operators"
  ON operators
  FOR SELECT
  USING (true);
