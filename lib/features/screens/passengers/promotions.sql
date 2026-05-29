-- Promotions table
CREATE TABLE IF NOT EXISTS promotions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code            TEXT UNIQUE NOT NULL,
  discount_type   TEXT NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
  discount_value  NUMERIC NOT NULL,
  min_purchase    NUMERIC,
  max_usage       INT,
  max_per_user    INT,
  used_count      INT DEFAULT 0,
  is_active       BOOLEAN DEFAULT true,
  expires_at      TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT now()
);

-- Per-user usage tracking
CREATE TABLE IF NOT EXISTS promotion_usages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  promotion_id    UUID NOT NULL REFERENCES promotions(id),
  user_id         UUID NOT NULL REFERENCES users(id),
  used_at         TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE promotion_usages ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Anyone can read promotions"
  ON promotions FOR SELECT USING (true);

-- Need update policy so used_count can be incremented
CREATE POLICY "Authenticated users can update promotions"
  ON promotions FOR UPDATE
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Users can insert their own usage"
  ON promotion_usages FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can read their own usage"
  ON promotion_usages FOR SELECT
  USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_promotion_usages_promo_user
  ON promotion_usages(promotion_id, user_id);

-- Sample promo codes (max_per_user = 3 means 3 uses per account)
INSERT INTO promotions (code, discount_type, discount_value, min_purchase, max_usage, max_per_user, is_active)
VALUES
  ('WELCOME10', 'percentage', 10, NULL, 100, 3, true),
  ('FLAT5',     'fixed',      5.00, 20.00, 50, 2, true),
  ('SAVE20',    'percentage', 20, 50.00, 30, 1, true)
ON CONFLICT (code) DO NOTHING;
