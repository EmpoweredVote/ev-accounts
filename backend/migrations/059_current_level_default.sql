-- Fix current_level column default on connect.connected_profiles.
--
-- Bug: new accounts created via complete_connect_flow start with current_level = 0
-- because award_xp (the only writer of current_level) is never called at enrollment.
-- calculate_level(0) correctly returns level 1, so the default should be 1.
--
-- Backfill: any account with 0 XP and current_level = 0 is also corrected here.
-- (In practice only one such account existed at time of migration.)

ALTER TABLE connect.connected_profiles
  ALTER COLUMN current_level SET DEFAULT 1;

UPDATE connect.connected_profiles
  SET current_level = 1
  WHERE total_xp = 0 AND current_level = 0;
