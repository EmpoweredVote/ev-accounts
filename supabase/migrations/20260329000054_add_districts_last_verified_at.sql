ALTER TABLE connect.connected_profiles
  ADD COLUMN IF NOT EXISTS districts_last_verified_at TIMESTAMPTZ;
