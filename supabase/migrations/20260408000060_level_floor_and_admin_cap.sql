-- Ensure minimum level is 1 for all connected users
-- Level 0 was a display bug — everyone starts at level 1 (0 XP = level 1, no invites yet)
UPDATE connect.connected_profiles
SET current_level = 1
WHERE current_level = 0;

-- Set unlimited invite cap for admin user (chris@empowered.vote)
UPDATE connect.connected_profiles
SET invite_cap_override = -1
WHERE user_id = '4e6dde8f-2bd0-4054-824f-4164744165ea';
