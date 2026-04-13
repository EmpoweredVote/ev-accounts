-- =============================================================================
-- Seed: 2026 LA County Primary — State, Federal & Statewide Races
--
-- Adds the missing tiers to the 2026 LA County Primary election:
--   STATE_LOWER   — CA Assembly District 54
--   STATE_UPPER   — CA Senate District 26
--   NATIONAL_LOWER — US House Congressional District 34
--   COUNTY        — LA County Sheriff, Assessor
--   SCHOOL        — LAUSD Board (Districts 2, 4, 6 — up in gubernatorial year 2026)
--   Statewide     — CA Governor, Lt. Governor, AG, Sec of State, Treasurer,
--                   Controller, Insurance Commissioner, Supt. of Public Instruction
--
-- ANTIPARTISAN NOTE: California uses a top-2 (jungle) primary — all candidates
-- run together regardless of party. primary_party = NULL for all CA races.
--
-- SOURCE NOTES:
--   - Office IDs pulled from essentials.offices linked to existing district records
--   - Incumbents marked is_incumbent=true; verify challenger list against:
--       CA Secretary of State: https://www.sos.ca.gov/elections/upcoming-elections/2026-statewide-primary
--       LA County Registrar: https://lavote.gov
--   - DA (Nathan Hochman) excluded — won Nov 2024, term through 2028, not up in 2026 primary
--   - US Senate excluded — both CA Senate seats (Padilla through 2028, Schiff through 2031)
--     are NOT up in 2026
--   - CA Senate D26: Ben Allen potentially term-limited (3 terms 2014-2026); seat seeded
--     without incumbent pending verification
--
-- IDEMPOTENT: ON CONFLICT (election_id, position_name, primary_party) DO NOTHING
--             Candidates: INSERT ... WHERE NOT EXISTS check on (race_id, full_name)
--
-- Usage: psql $DATABASE_URL -f scripts/seed-la-county-2026-primary-state-federal.sql
-- =============================================================================

BEGIN;

-- =============================================================================
-- Reference the existing 2026 LA County Primary election
-- =============================================================================

DO $$
DECLARE
  v_election_id uuid;
BEGIN
  SELECT id INTO v_election_id
  FROM essentials.elections
  WHERE name = '2026 LA County Primary' AND state = 'CA';

  IF v_election_id IS NULL THEN
    RAISE EXCEPTION '2026 LA County Primary election not found — run base seed first';
  END IF;
END $$;

-- =============================================================================
-- Part A: Geofence-matched races (office_id → district → geofence → ST_Covers)
-- Each office_id here is already linked to the correct district in the DB.
-- =============================================================================

WITH election AS (
  SELECT id FROM essentials.elections
  WHERE name = '2026 LA County Primary' AND state = 'CA'
)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT e.id, v.office_id::uuid, v.position_name, NULL, 1, v.description
FROM election e,
(VALUES
  -- ── STATE LEGISLATURE ──────────────────────────────────────────────────────
  -- Assembly District 54 (downtown LA, Koreatown, Pico-Union, Culver City area)
  -- office_id: a2f330df-16cd-42be-bcd5-006e57cf1d69 (Assembly Member, district STATE_LOWER geo_id 06054)
  ('a2f330df-16cd-42be-bcd5-006e57cf1d69',
   'CA State Assembly District 54',
   'CA Assembly District 54 — covers downtown LA, Koreatown, Pico-Union'),

  -- Senate District 26 (Hollywood, Silver Lake, Culver City, Malibu area)
  -- office_id: 111f6884-8eae-4447-9fbb-df0e281e0eb4 (Senator, district STATE_UPPER geo_id 06026)
  -- NOTE: Ben Allen potentially term-limited (3 terms 2014-2026) — verify with CA SoS
  ('111f6884-8eae-4447-9fbb-df0e281e0eb4',
   'CA State Senate District 26',
   'CA Senate District 26 — covers Hollywood, Silver Lake, Malibu, Culver City'),

  -- ── FEDERAL ───────────────────────────────────────────────────────────────
  -- US House Congressional District 34 (downtown LA, East LA, Montebello area)
  -- office_id: 4e1ab309-a5d2-4c98-9a0d-11034f4896b2 (Representative, district NATIONAL_LOWER geo_id 0634)
  ('4e1ab309-a5d2-4c98-9a0d-11034f4896b2',
   'U.S. Representative District 34',
   'CA Congressional District 34 — downtown LA, East LA, Montebello, Commerce'),

  -- ── COUNTY-WIDE ───────────────────────────────────────────────────────────
  -- Sheriff (county-wide — geofenced to LA County district, appears for all LA County addresses)
  -- office_id: dd507d10-a106-42e6-a275-2385154aa072 (Sheriff, district COUNTY geo_id 06037)
  ('dd507d10-a106-42e6-a275-2385154aa072',
   'LA County Sheriff',
   'Los Angeles County Sheriff — county-wide elected office, 4-year term'),

  -- Assessor (county-wide)
  -- office_id: ada7f5e7-d955-4c14-ac0b-ff390d4bddae (Assessor, district COUNTY geo_id 06037)
  ('ada7f5e7-d955-4c14-ac0b-ff390d4bddae',
   'LA County Assessor',
   'Los Angeles County Assessor — county-wide elected office, 4-year term')

  -- NOTE: LA County DA (Nathan Hochman, office_id d0bb1ce7) is NOT included —
  -- Hochman won in Nov 2024 general election; term runs through 2028.
  -- LAUSD board races added separately below (need board-district-level offices).

) AS v(office_id, position_name, description)
ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

-- =============================================================================
-- Part B: Statewide races (office_id IS NULL — matched by election.state = 'CA')
-- These appear for ALL CA addresses via the electionService Part B query.
-- Primary_party must not be NULL for the unique constraint — use empty string sentinel.
-- =============================================================================

WITH election AS (
  SELECT id FROM essentials.elections
  WHERE name = '2026 LA County Primary' AND state = 'CA'
)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT e.id, NULL, v.position_name, NULL, 1, v.description
FROM election e,
(VALUES
  ('CA Governor',
   'Governor of California — open seat (Gavin Newsom term-limited). 4-year term.'),

  ('CA Lieutenant Governor',
   'Lieutenant Governor of California. Eleni Kounalakis is incumbent (re-elected 2022).'),

  ('CA Attorney General',
   'Attorney General of California. Rob Bonta is incumbent (won 2022 general election).'),

  ('CA Secretary of State',
   'Secretary of State of California. Shirley Weber is incumbent (won 2022 general election).'),

  ('CA State Treasurer',
   'State Treasurer of California. Fiona Ma is incumbent (re-elected 2022).'),

  ('CA State Controller',
   'State Controller of California. Malia Cohen is incumbent (elected 2022).'),

  ('CA Insurance Commissioner',
   'Insurance Commissioner of California. Ricardo Lara is incumbent (re-elected 2022).'),

  ('CA Superintendent of Public Instruction',
   'Superintendent of Public Instruction. Tony Thurmond is incumbent (re-elected 2022).')

) AS v(position_name, description)
ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

-- =============================================================================
-- Part C: LAUSD Board races
--
-- LAUSD has 7 board districts. In gubernatorial years (2022, 2026) the even-
-- numbered districts are up: District 2, District 4, District 6.
--
-- Current board members per office records already in DB:
--   District 2 — Scott Schmerelson  (office_id: 013b6024-cbda-4746-8826-e33baa541081)
--   District 4 — Nick Melvoin       (office_id: 6b906b77-f0f9-4ff9-b852-b0a11bfa4af6)
--   District 6 — Kelly Gonez        (office_id: 0b95c93e-4b15-48c7-a21f-83155f7c5a24)
--
-- NOTE: These offices are all linked to the LAUSD at-large district (geo_id 0622710).
-- Any address within the LAUSD boundary will see all 3 board races. This is a known
-- limitation of the current data model — LAUSD board sub-district geofences are not
-- yet loaded. For now this is acceptable: a voter in LAUSD sees all 3 board races
-- on their ballot (2 of the 3 may not apply to their specific sub-district).
-- TODO: Load LAUSD board sub-district geofences for precise matching.
-- =============================================================================

WITH election AS (
  SELECT id FROM essentials.elections
  WHERE name = '2026 LA County Primary' AND state = 'CA'
)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT e.id, v.office_id::uuid, v.position_name, NULL, 1, v.description
FROM election e,
(VALUES
  ('013b6024-cbda-4746-8826-e33baa541081',
   'LAUSD Board of Education District 2',
   'Los Angeles Unified School District Board — District 2'),

  ('6b906b77-f0f9-4ff9-b852-b0a11bfa4af6',
   'LAUSD Board of Education District 4',
   'Los Angeles Unified School District Board — District 4'),

  ('0b95c93e-4b15-48c7-a21f-83155f7c5a24',
   'LAUSD Board of Education District 6',
   'Los Angeles Unified School District Board — District 6')

) AS v(office_id, position_name, description)
ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

-- =============================================================================
-- Part D: Seed known incumbents as race_candidates
--
-- Only adding incumbents we're confident about. Challenger candidates must be
-- added from the official CA SoS 2026 primary candidate filing list.
--
-- NOT adding incumbents for:
--   - CA Senate D26 (Ben Allen potentially term-limited — verify with CA SoS)
--   - CA Governor (open seat — Newsom term-limited)
--   - LAUSD board (verify current members against LAUSD.edu board page)
-- =============================================================================

-- CA Assembly District 54 — Isaac Bryan (incumbent, elected 2020, re-elected 2022 & 2024)
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT
  r.id,
  p.id,
  p.full_name,
  p.first_name,
  p.last_name,
  true,
  'active',
  'incumbent_lookup'
FROM essentials.races r
JOIN essentials.elections e ON e.id = r.election_id
JOIN essentials.politicians p ON lower(p.full_name) = lower('Isaac Bryan')
WHERE e.name = '2026 LA County Primary'
  AND r.position_name = 'CA State Assembly District 54'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Isaac Bryan')
  )
LIMIT 1;

-- US House CD-34 — Jimmy Gomez (incumbent, serving since 2017)
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT
  r.id,
  p.id,
  p.full_name,
  p.first_name,
  p.last_name,
  true,
  'active',
  'incumbent_lookup'
FROM essentials.races r
JOIN essentials.elections e ON e.id = r.election_id
JOIN essentials.politicians p ON lower(p.full_name) = lower('Jimmy Gomez')
WHERE e.name = '2026 LA County Primary'
  AND r.position_name = 'U.S. Representative District 34'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jimmy Gomez')
  )
LIMIT 1;

-- LA County Sheriff — Robert Luna (elected 2022, 4-year term, up in 2026)
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT
  r.id,
  p.id,
  p.full_name,
  p.first_name,
  p.last_name,
  true,
  'active',
  'incumbent_lookup'
FROM essentials.races r
JOIN essentials.elections e ON e.id = r.election_id
JOIN essentials.politicians p ON lower(p.full_name) = lower('Robert Luna')
WHERE e.name = '2026 LA County Primary'
  AND r.position_name = 'LA County Sheriff'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Robert Luna')
  )
LIMIT 1;

-- CA Attorney General — Rob Bonta (incumbent, won 2022 general)
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT
  r.id,
  p.id,
  p.full_name,
  p.first_name,
  p.last_name,
  true,
  'active',
  'incumbent_lookup'
FROM essentials.races r
JOIN essentials.elections e ON e.id = r.election_id
JOIN essentials.politicians p ON lower(p.full_name) = lower('Rob Bonta')
WHERE e.name = '2026 LA County Primary'
  AND r.position_name = 'CA Attorney General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Rob Bonta')
  )
LIMIT 1;

-- =============================================================================
-- Verification query — run after applying to confirm races were created
-- =============================================================================

SELECT
  d.district_type,
  r.position_name,
  r.office_id IS NOT NULL AS has_office_link,
  COUNT(rc.id) AS candidate_count
FROM essentials.races r
JOIN essentials.elections e ON e.id = r.election_id
LEFT JOIN essentials.offices o ON o.id = r.office_id
LEFT JOIN essentials.districts d ON d.id = o.district_id
LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
WHERE e.name = '2026 LA County Primary'
ORDER BY d.district_type NULLS LAST, r.position_name;

COMMIT;
