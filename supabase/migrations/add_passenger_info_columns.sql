-- Add passenger info columns to bookings table
ALTER TABLE bookings
  ADD COLUMN IF NOT EXISTS passenger_name TEXT,
  ADD COLUMN IF NOT EXISTS passenger_age INT,
  ADD COLUMN IF NOT EXISTS passenger_phone TEXT,
  ADD COLUMN IF NOT EXISTS passenger_nationality TEXT;

-- Add passenger info columns to users table
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS age INT,
  ADD COLUMN IF NOT EXISTS nationality TEXT;
