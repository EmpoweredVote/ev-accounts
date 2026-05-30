-- =============================================================================
-- PATCH: 2026 Utah Primary — Add SD-21, SD-23, CD-1 D primary + missing candidates
--
-- What this adds on top of seed-ut-2026-06-23-primary.sql:
--   • Utah State Senate District 21 (R + D) — with office_id for geofence-based matching
--   • Utah State Senate District 23 (R + D) — with office_id (covers Orem test address)
--   • U.S. House District 1 Democratic primary (4 candidates)
--   • Utah County Auditor: Travis Hoban (2nd R candidate — was missing)
--   • Utah State Senate District 11: add Democratic race + MacKenzie Miller
--
-- Also applied separately (code fix, not SQL):
--   • electionService.ts: state code .toUpperCase() so Part B works for lowercase districts
--
-- Idempotent — safe to re-run.
-- Usage: psql "$DATABASE_URL" -f scripts/seed-ut-2026-06-23-primary-patch.sql
-- =============================================================================

BEGIN;

-- =============================================================================
-- Step 1: Ensure the election row exists (already seeded; this is a no-op)
-- =============================================================================

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state, description)
VALUES (
  '2026 Utah Primary',
  '2026-06-23',
  'primary',
  'state',
  'UT',
  'Utah 2026 Primary — Salt Lake & Utah County federal, state, and county races'
)
ON CONFLICT (name, election_date, state)
DO UPDATE SET description = EXCLUDED.description, updated_at = now();

-- =============================================================================
-- Step 2: Upsert new races
--   SD-21 and SD-23 get office_id so they show via Part A (geofence-specific)
--   rather than Part B (all-state).
-- =============================================================================

WITH election AS (
  SELECT id FROM essentials.elections
  WHERE name = '2026 Utah Primary' AND election_date = '2026-06-23' AND state = 'UT'
)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT
  e.id,
  v.office_id::uuid,
  v.position_name,
  v.primary_party,
  v.seats
FROM election e,
(VALUES
  -- U.S. House District 1: only the D primary (4-way); R: Riley Owen won convention outright, no R primary
  (NULL,                                      'U.S. House District 1',           'Democratic', 1),

  -- State Senate District 21 (Brady Brammer's district: Highland/Alpine/Lehi/American Fork)
  -- office_id = 6d0dadea-... → geo_id 49021, mtfcc G5210 → geofence match only for addresses in SD-21
  ('6d0dadea-3e19-4a7d-a700-429e7dc99631',   'Utah State Senate District 21',   'Republican', 1),
  ('6d0dadea-3e19-4a7d-a700-429e7dc99631',   'Utah State Senate District 21',   'Democratic', 1),

  -- State Senate District 23 (Keith Grover's district: Provo/Lindon/Pleasant Grove/Vineyard)
  -- office_id = 16336c50-... → geo_id 49023, mtfcc G5210 → geofence covers the Orem test address
  ('16336c50-9fa9-4ef8-b8d9-061c0b898454',   'Utah State Senate District 23',   'Republican', 1),
  ('16336c50-9fa9-4ef8-b8d9-061c0b898454',   'Utah State Senate District 23',   'Democratic', 1),

  -- State Senate District 11: add missing Democratic race
  (NULL,                                      'Utah State Senate District 11',   'Democratic', 1)
) AS v(office_id, position_name, primary_party, seats)
ON CONFLICT (election_id, position_name, primary_party)
  DO UPDATE SET
    office_id  = COALESCE(EXCLUDED.office_id, essentials.races.office_id),
    updated_at = now();

-- =============================================================================
-- Step 3: Insert candidates
--   Guard: WHERE NOT EXISTS prevents duplicates on re-run.
--   Incumbents: politician_id linked so photo/bio/stances flow to candidate card.
-- =============================================================================

-- helper CTE reused in each insert
WITH election AS (
  SELECT id AS eid FROM essentials.elections
  WHERE name = '2026 Utah Primary' AND election_date = '2026-06-23' AND state = 'UT'
)

-- ── U.S. House District 1 — Democratic primary ───────────────────────────────
INSERT INTO essentials.race_candidates
  (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, v.full_name, v.first_name, v.last_name, false, 'active', 'sos_filing'
FROM election e
JOIN essentials.races r
  ON r.election_id = e.eid
  AND r.position_name = 'U.S. House District 1'
  AND r.primary_party = 'Democratic',
(VALUES
  ('Liban Mohamed',   'Liban',   'Mohamed'),
  ('Ben McAdams',     'Ben',     'McAdams'),
  ('Nate Blouin',     'Nate',    'Blouin'),
  ('Michael Farrell', 'Michael', 'Farrell')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id = r.id AND rc.full_name = v.full_name
);

-- ── Utah State Senate District 21 — Republican primary ───────────────────────
WITH election AS (
  SELECT id AS eid FROM essentials.elections
  WHERE name = '2026 Utah Primary' AND election_date = '2026-06-23' AND state = 'UT'
)
INSERT INTO essentials.race_candidates
  (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, politician_id, source)
SELECT r.id, v.full_name, v.first_name, v.last_name, v.is_incumbent, 'active',
       v.politician_id::uuid, 'sos_filing'
FROM election e
JOIN essentials.races r
  ON r.election_id = e.eid
  AND r.position_name = 'Utah State Senate District 21'
  AND r.primary_party = 'Republican',
(VALUES
  ('Brady Brammer', 'Brady', 'Brammer', true,  '070c1c1c-ac9d-42e0-bff2-3f4467504cba'),
  ('Kelly Smith',   'Kelly', 'Smith',   false, NULL)
) AS v(full_name, first_name, last_name, is_incumbent, politician_id)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id = r.id AND rc.full_name = v.full_name
);

-- ── Utah State Senate District 21 — Democratic ───────────────────────────────
WITH election AS (
  SELECT id AS eid FROM essentials.elections
  WHERE name = '2026 Utah Primary' AND election_date = '2026-06-23' AND state = 'UT'
)
INSERT INTO essentials.race_candidates
  (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, 'Kandee Myers', 'Kandee', 'Myers', false, 'active', 'sos_filing'
FROM election e
JOIN essentials.races r
  ON r.election_id = e.eid
  AND r.position_name = 'Utah State Senate District 21'
  AND r.primary_party = 'Democratic'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id = r.id AND rc.full_name = 'Kandee Myers'
);

-- ── Utah State Senate District 23 — Republican ───────────────────────────────
WITH election AS (
  SELECT id AS eid FROM essentials.elections
  WHERE name = '2026 Utah Primary' AND election_date = '2026-06-23' AND state = 'UT'
)
INSERT INTO essentials.race_candidates
  (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, politician_id, source)
SELECT r.id, 'Keith Grover', 'Keith', 'Grover', true, 'active',
       'dd75cf82-f0b2-4820-9356-28ccf0ee58f9'::uuid, 'sos_filing'
FROM election e
JOIN essentials.races r
  ON r.election_id = e.eid
  AND r.position_name = 'Utah State Senate District 23'
  AND r.primary_party = 'Republican'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id = r.id AND rc.full_name = 'Keith Grover'
);

-- ── Utah State Senate District 23 — Democratic ───────────────────────────────
WITH election AS (
  SELECT id AS eid FROM essentials.elections
  WHERE name = '2026 Utah Primary' AND election_date = '2026-06-23' AND state = 'UT'
)
INSERT INTO essentials.race_candidates
  (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, 'Tucker Smith', 'Tucker', 'Smith', false, 'active', 'sos_filing'
FROM election e
JOIN essentials.races r
  ON r.election_id = e.eid
  AND r.position_name = 'Utah State Senate District 23'
  AND r.primary_party = 'Democratic'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id = r.id AND rc.full_name = 'Tucker Smith'
);

-- ── Utah County Auditor — add Travis Hoban (was missing) ────────────────────
WITH election AS (
  SELECT id AS eid FROM essentials.elections
  WHERE name = '2026 Utah Primary' AND election_date = '2026-06-23' AND state = 'UT'
)
INSERT INTO essentials.race_candidates
  (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, 'Travis Hoban', 'Travis', 'Hoban', false, 'active', 'sos_filing'
FROM election e
JOIN essentials.races r
  ON r.election_id = e.eid
  AND r.position_name = 'Utah County Auditor'
  AND r.primary_party = 'Republican'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id = r.id AND rc.full_name = 'Travis Hoban'
);

-- ── Utah State Senate District 11 — Democratic (MacKenzie Miller) ────────────
WITH election AS (
  SELECT id AS eid FROM essentials.elections
  WHERE name = '2026 Utah Primary' AND election_date = '2026-06-23' AND state = 'UT'
)
INSERT INTO essentials.race_candidates
  (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, 'MacKenzie Miller', 'MacKenzie', 'Miller', false, 'active', 'sos_filing'
FROM election e
JOIN essentials.races r
  ON r.election_id = e.eid
  AND r.position_name = 'Utah State Senate District 11'
  AND r.primary_party = 'Democratic'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id = r.id AND rc.full_name = 'MacKenzie Miller'
);

COMMIT;

-- =============================================================================
-- Verification queries (run manually after applying)
-- =============================================================================
-- New race counts:
--   SELECT r.position_name, r.primary_party, r.office_id IS NOT NULL AS has_office_id, COUNT(rc.id) AS candidates
--   FROM essentials.races r
--   JOIN essentials.elections e ON r.election_id = e.id
--   LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
--   WHERE e.name = '2026 Utah Primary'
--     AND r.position_name IN (
--       'Utah State Senate District 21', 'Utah State Senate District 23',
--       'U.S. House District 1', 'Utah County Auditor', 'Utah State Senate District 11'
--     )
--   GROUP BY r.position_name, r.primary_party, has_office_id
--   ORDER BY r.position_name, r.primary_party;
--
-- Address check after applying:
--   GET /api/essentials/elections-by-address?address=877+W+1050+N+Orem+UT
--   Should return: HD-56 (Part A) + SD-23 (Part A) + SD-21 (Part A) + U.S. House 3 (Part B) + UT County offices (Part B)
-- =============================================================================
