-- Reviews & ratings for completed trips (passenger rates trip & driver)

CREATE TABLE IF NOT EXISTS reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT NOT NULL DEFAULT '',
  driver_id UUID REFERENCES users(id) ON DELETE SET NULL,
  driver_rating INT CHECK (driver_rating IS NULL OR (driver_rating >= 1 AND driver_rating <= 5)),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_reviews_booking_id ON reviews(booking_id);
CREATE INDEX IF NOT EXISTS idx_reviews_trip_id ON reviews(trip_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_driver_id ON reviews(driver_id);
CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON reviews(created_at DESC);

ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read reviews"
  ON reviews FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own reviews"
  ON reviews FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own reviews"
  ON reviews FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Helper: get average rating for a driver
CREATE OR REPLACE FUNCTION get_driver_avg_rating(p_driver_id UUID)
RETURNS DECIMAL(3,2)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  avg_rating DECIMAL(3,2);
BEGIN
  SELECT COALESCE(AVG(driver_rating)::DECIMAL(3,2), 0)
  INTO avg_rating
  FROM reviews
  WHERE driver_id = p_driver_id AND driver_rating IS NOT NULL;
  RETURN avg_rating;
END;
$$;

-- Helper: get average rating for a trip
CREATE OR REPLACE FUNCTION get_trip_avg_rating(p_trip_id UUID)
RETURNS DECIMAL(3,2)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  avg_rating DECIMAL(3,2);
BEGIN
  SELECT COALESCE(AVG(rating)::DECIMAL(3,2), 0)
  INTO avg_rating
  FROM reviews
  WHERE trip_id = p_trip_id;
  RETURN avg_rating;
END;
$$;
