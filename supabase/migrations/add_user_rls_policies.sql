-- Add INSERT and UPDATE RLS policies for public.users table
-- Users can insert their own profile row
DROP POLICY IF EXISTS "users_insert_own" ON users;
CREATE POLICY "users_insert_own"
  ON users
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Users can update their own profile row
DROP POLICY IF EXISTS "users_update_own" ON users;
CREATE POLICY "users_update_own"
  ON users
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);
