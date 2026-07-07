-- 1254_seed_ak_2026_house_election_race.sql
-- Phase 165-03: 'AK 2026 Statewide General' election + 1 at-large U.S. House race on the EXISTING
--   NATIONAL_LOWER office for geo_id 0200. JUNGLE/TOP-FOUR MODEL: primary_party=NULL (LA/CA
--   convention; the idx_races_election_position_no_party unique index supports this shape). RCV is
--   research-only — no schema change. PROVISIONAL: declared pre-primary field, cull >= 2026-08-18
--   (AK top-four primary date verified from elections.alaska.gov 2026-07-07). office_id never NULL.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'AK 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'AK'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'AK 2026 Statewide General');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative At-Large', NULL, 1, 'PROVISIONAL: pre-primary qualified field (top-four-RCV), cull >= 2026-08-18'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '0200'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'AK 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);

COMMIT;
