-- Migration 1064: Move Los Angeles Mayor race to the 2026 general election
-- (Originally drafted as 797; renumbered to keep the migrations dir monotonic.
--  Already applied to production — committed as a durable record.)
--
-- The LA Mayor race was originally linked to the 2026 LA County Primary
-- (June 2, 2026). The decisive election is the November general, so this
-- migration:
--   1. Ensures a "2026 LA County General" election row exists (2026-11-03).
--   2. Repoints the Los Angeles Mayor race to that election.
--
-- Race ID (Los Angeles Mayor): 24bc3631-22cf-41ab-a731-672481502214
-- Old election (2026 LA County Primary, 2026-06-02): 1ebca37f-cf96-47f4-bc2b-47ef266721fe

BEGIN;

-- Step 1: Ensure the 2026 LA County General election exists
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
VALUES ('2026 LA County General', '2026-11-03', 'general', 'county', 'CA')
ON CONFLICT (name, election_date, state) DO NOTHING;

-- Step 2: Move the Los Angeles Mayor race to the general election
UPDATE essentials.races
SET election_id = (
  SELECT id FROM essentials.elections
  WHERE name = '2026 LA County General' AND state = 'CA'
)
WHERE id = '24bc3631-22cf-41ab-a731-672481502214';

-- Verify
SELECT r.position_name, e.name AS election_name, e.election_date
FROM essentials.races r
JOIN essentials.elections e ON e.id = r.election_id
WHERE r.id = '24bc3631-22cf-41ab-a731-672481502214';

COMMIT;
