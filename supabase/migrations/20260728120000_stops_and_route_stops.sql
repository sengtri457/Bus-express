CREATE TABLE IF NOT EXISTS stops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS route_stops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
  stop_id UUID NOT NULL REFERENCES stops(id) ON DELETE CASCADE,
  stop_order INT NOT NULL DEFAULT 0,
  arrival_offset INT NOT NULL DEFAULT 0,
  departure_offset INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_route_stops_route_id ON route_stops(route_id);
CREATE INDEX IF NOT EXISTS idx_route_stops_stop_id ON route_stops(stop_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_route_stops_unique_order
  ON route_stops(route_id, stop_order);

ALTER TABLE stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE route_stops ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Operators can manage stops"
  ON stops
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'operator_admin'
    )
  );

CREATE POLICY "Everyone can read stops"
  ON stops
  FOR SELECT
  USING (true);

CREATE POLICY "Operators can manage route stops"
  ON route_stops
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'operator_admin'
    )
  );

CREATE POLICY "Everyone can read route stops"
  ON route_stops
  FOR SELECT
  USING (true);
