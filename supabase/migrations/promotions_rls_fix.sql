-- Fix: Add missing INSERT policy for promotions table
-- Super admins need to be able to create promo codes

CREATE POLICY "Super admins can insert promotions"
  ON promotions FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'super_admin'
    )
  );
