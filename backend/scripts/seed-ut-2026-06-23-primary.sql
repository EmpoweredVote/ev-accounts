-- =============================================================================
-- Seed: 2026 Utah Primary — Salt Lake County & Utah County
--       Federal, State Senate/House, County Offices, State Board of Education
--
-- Source: Utah Lt. Governor certified filings (vote.utah.gov/2026-candidate-filings/)
--         Salt Lake County Clerk (slco.org/clerk/elections/)
--         Utah County Elections (utahcounty.gov/election/)
-- Election: 2026 Utah Primary, June 23, 2026
--
-- SCOPE: Races relevant to Salt Lake County and Utah County residents —
--        U.S. House (UT-2, UT-3, UT-4), Utah State Senate (SD-9,11,12,13,14,18,19),
--        Utah State House (HD-21–49 SL County; HD-50–65 Utah County),
--        SL County offices, Utah County offices, Utah SBOE (Districts 5,7,8,11,14).
--
-- CITY NOTE: Utah municipal/city races are NONPARTISAN and held in ODD years.
--            No Salt Lake City, Provo, Sandy, or other city primary exists in 2026.
--
-- candidate_status values:
--   'active' = on the June 23 primary ballot OR won convention (60%+) → straight to general
--   'filed'  = administrative status; verify before treating as ballot candidate
--
-- IDEMPOTENT:
--   Election: ON CONFLICT (name, election_date, state) DO UPDATE
--   Races:    ON CONFLICT (election_id, position_name, primary_party) DO UPDATE
--   Candidates: INSERT ... WHERE NOT EXISTS (race_id, full_name)
--
-- KNOWN GAPS:
--   - Utah County Commission Seat B (D): "J. Allen" — full first name not publicly findable.
--     Seeded as 'J. Allen'; update when confirmed.
--   - HD-64: Jeff Burton (R) has status 'filed' on vote.utah.gov — verify qualification.
--   - All office_id = NULL. Races surface via electionService Part B (state-wide lookup).
--     Backfill office_id per district once geofence linkage is confirmed.
--   - No Utah STATE_UPPER records exist in essentials.politicians. Senate incumbents
--     seeded with politician_id = NULL and is_incumbent = true.
--   - SL County House incumbents (HD-21–49) not in DB; seeded with politician_id = NULL.
--
-- Usage: psql $DATABASE_URL -f scripts/seed-ut-2026-06-23-primary.sql
-- =============================================================================

BEGIN;

-- =============================================================================
-- Step 1: Upsert the election
-- =============================================================================

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state, description)
VALUES (
  '2026 Utah Primary',
  '2026-06-23',
  'primary',
  'state',
  'UT',
  'Utah 2026 Primary — Salt Lake County & Utah County federal, state, and county races'
)
ON CONFLICT (name, election_date, state)
DO UPDATE SET
  description = EXCLUDED.description,
  updated_at = now();

-- =============================================================================
-- Step 2: Upsert all races
-- One row per (position_name, primary_party). office_id = NULL for all races
-- (will be backfilled once district geofences are confirmed).
-- =============================================================================

WITH election AS (
  SELECT id FROM essentials.elections
  WHERE name = '2026 Utah Primary' AND election_date = '2026-06-23' AND state = 'UT'
)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT e.id, NULL, v.position_name, v.primary_party, v.seats, v.description
FROM election e,
(VALUES
  -- ── FEDERAL — U.S. House ─────────────────────────────────────────────────
  ('U.S. House District 2',  'Republican', 1, 'UT-2 Republican Primary — covers SL County / southern Ogden area'),
  ('U.S. House District 2',  'Democratic', 1, 'UT-2 Democratic — Peter Crosby convention winner (no primary)'),
  ('U.S. House District 3',  'Republican', 1, 'UT-3 Republican Primary — covers Utah County Provo/Orem area'),
  ('U.S. House District 3',  'Democratic', 1, 'UT-3 Democratic — Kent Udell convention winner (no primary)'),
  ('U.S. House District 4',  'Republican', 1, 'UT-4 Republican — Mike Kennedy convention winner (no primary)'),
  ('U.S. House District 4',  'Democratic', 1, 'UT-4 Democratic — Jonny Larsen convention winner (no primary)'),

  -- ── UTAH STATE SENATE ────────────────────────────────────────────────────
  ('Utah State Senate District 9',  'Democratic', 1, 'SD-9 Democratic Primary — covers SLC/Holladay'),
  ('Utah State Senate District 9',  'Republican', 1, 'SD-9 Republican Primary — covers SLC/Holladay'),
  ('Utah State Senate District 11', 'Republican', 1, 'SD-11 Republican — Brooks Benson convention winner'),
  ('Utah State Senate District 12', 'Democratic', 1, 'SD-12 Democratic Primary — Taylorsville/West Valley City/Kearns'),
  ('Utah State Senate District 12', 'Republican', 1, 'SD-12 Republican Primary — Taylorsville/West Valley City/Kearns'),
  ('Utah State Senate District 13', 'Democratic', 1, 'SD-13 Democratic Primary — open seat (Blouin retiring)'),
  ('Utah State Senate District 13', 'Republican', 1, 'SD-13 Republican Primary — open seat challenger'),
  ('Utah State Senate District 14', 'Democratic', 1, 'SD-14 Democratic Primary — SLC/Millcreek/Murray'),
  ('Utah State Senate District 18', 'Republican', 1, 'SD-18 Republican Primary — Bluffdale/Herriman/Riverton/Saratoga Springs'),
  ('Utah State Senate District 18', 'Democratic', 1, 'SD-18 Democratic — A. Dane Anderson convention winner'),
  ('Utah State Senate District 19', 'Republican', 1, 'SD-19 Republican Primary — Sandy/Draper'),
  ('Utah State Senate District 19', 'Democratic', 1, 'SD-19 Democratic Primary — Sandy/Draper'),

  -- ── UTAH STATE HOUSE — SALT LAKE COUNTY (HD-21 to HD-49) ────────────────
  ('Utah State House District 21', 'Democratic', 1, 'HD-21 Democratic Primary — open seat (Hollins retiring)'),
  ('Utah State House District 22', 'Republican', 1, 'HD-22 Republican'),
  ('Utah State House District 22', 'Democratic', 1, 'HD-22 Democratic'),
  ('Utah State House District 23', 'Republican', 1, 'HD-23 Republican'),
  ('Utah State House District 23', 'Democratic', 1, 'HD-23 Democratic'),
  ('Utah State House District 24', 'Republican', 1, 'HD-24 Republican'),
  ('Utah State House District 24', 'Democratic', 1, 'HD-24 Democratic'),
  ('Utah State House District 25', 'Republican', 1, 'HD-25 Republican'),
  ('Utah State House District 25', 'Democratic', 1, 'HD-25 Democratic'),
  ('Utah State House District 26', 'Republican', 1, 'HD-26 Republican'),
  ('Utah State House District 26', 'Democratic', 1, 'HD-26 Democratic'),
  ('Utah State House District 27', 'Republican', 1, 'HD-27 Republican'),
  ('Utah State House District 27', 'Democratic', 1, 'HD-27 Democratic'),
  ('Utah State House District 28', 'Republican', 1, 'HD-28 Republican'),
  ('Utah State House District 28', 'Democratic', 1, 'HD-28 Democratic'),
  ('Utah State House District 29', 'Republican', 1, 'HD-29 Republican Primary — open seat (Bolinder retiring)'),
  ('Utah State House District 29', 'Democratic', 1, 'HD-29 Democratic'),
  ('Utah State House District 30', 'Republican', 1, 'HD-30 Republican'),
  ('Utah State House District 30', 'Democratic', 1, 'HD-30 Democratic'),
  ('Utah State House District 31', 'Republican', 1, 'HD-31 Republican'),
  ('Utah State House District 31', 'Democratic', 1, 'HD-31 Democratic'),
  ('Utah State House District 32', 'Republican', 1, 'HD-32 Republican'),
  ('Utah State House District 32', 'Democratic', 1, 'HD-32 Democratic'),
  ('Utah State House District 33', 'Republican', 1, 'HD-33 Republican'),
  ('Utah State House District 33', 'Democratic', 1, 'HD-33 Democratic'),
  ('Utah State House District 34', 'Democratic', 1, 'HD-34 Democratic Primary — open seat (Spackman Moss retiring)'),
  ('Utah State House District 35', 'Republican', 1, 'HD-35 Republican'),
  ('Utah State House District 35', 'Democratic', 1, 'HD-35 Democratic'),
  ('Utah State House District 36', 'Republican', 1, 'HD-36 Republican'),
  ('Utah State House District 37', 'Republican', 1, 'HD-37 Republican'),
  ('Utah State House District 37', 'Democratic', 1, 'HD-37 Democratic'),
  ('Utah State House District 38', 'Republican', 1, 'HD-38 Republican Primary — open seat (Acton retiring)'),
  ('Utah State House District 39', 'Republican', 1, 'HD-39 Republican'),
  ('Utah State House District 39', 'Democratic', 1, 'HD-39 Democratic'),
  ('Utah State House District 40', 'Democratic', 1, 'HD-40 Democratic Primary — incumbent vs. challenger'),
  ('Utah State House District 41', 'Republican', 1, 'HD-41 Republican Primary — open seat on R side'),
  ('Utah State House District 41', 'Democratic', 1, 'HD-41 Democratic'),
  ('Utah State House District 42', 'Republican', 1, 'HD-42 Republican'),
  ('Utah State House District 42', 'Democratic', 1, 'HD-42 Democratic'),
  ('Utah State House District 43', 'Republican', 1, 'HD-43 Republican'),
  ('Utah State House District 43', 'Democratic', 1, 'HD-43 Democratic'),
  ('Utah State House District 44', 'Republican', 1, 'HD-44 Republican Primary — incumbent vs. challenger'),
  ('Utah State House District 44', 'Democratic', 1, 'HD-44 Democratic'),
  ('Utah State House District 45', 'Republican', 1, 'HD-45 Republican'),
  ('Utah State House District 45', 'Democratic', 1, 'HD-45 Democratic'),
  ('Utah State House District 46', 'Republican', 1, 'HD-46 Republican'),
  ('Utah State House District 46', 'Democratic', 1, 'HD-46 Democratic'),
  ('Utah State House District 47', 'Republican', 1, 'HD-47 Republican'),
  ('Utah State House District 48', 'Republican', 1, 'HD-48 Republican Primary — open seat (Fiefia moved to Senate)'),
  ('Utah State House District 48', 'Democratic', 1, 'HD-48 Democratic'),
  ('Utah State House District 49', 'Republican', 1, 'HD-49 Republican'),
  ('Utah State House District 49', 'Democratic', 1, 'HD-49 Democratic'),

  -- ── UTAH STATE HOUSE — UTAH COUNTY (HD-50 to HD-65) ─────────────────────
  ('Utah State House District 50', 'Republican', 1, 'HD-50 Republican'),
  ('Utah State House District 50', 'Democratic', 1, 'HD-50 Democratic'),
  ('Utah State House District 51', 'Republican', 1, 'HD-51 Republican'),
  ('Utah State House District 51', 'Democratic', 1, 'HD-51 Democratic'),
  ('Utah State House District 52', 'Republican', 1, 'HD-52 Republican'),
  ('Utah State House District 52', 'Democratic', 1, 'HD-52 Democratic'),
  ('Utah State House District 53', 'Republican', 1, 'HD-53 Republican'),
  ('Utah State House District 53', 'Democratic', 1, 'HD-53 Democratic'),
  ('Utah State House District 54', 'Republican', 1, 'HD-54 Republican'),
  ('Utah State House District 54', 'Democratic', 1, 'HD-54 Democratic'),
  ('Utah State House District 55', 'Republican', 1, 'HD-55 Republican'),
  ('Utah State House District 55', 'Democratic', 1, 'HD-55 Democratic'),
  ('Utah State House District 56', 'Republican', 1, 'HD-56 Republican'),
  ('Utah State House District 56', 'Democratic', 1, 'HD-56 Democratic'),
  ('Utah State House District 57', 'Republican', 1, 'HD-57 Republican'),
  ('Utah State House District 58', 'Republican', 1, 'HD-58 Republican'),
  ('Utah State House District 58', 'Democratic', 1, 'HD-58 Democratic'),
  ('Utah State House District 60', 'Republican', 1, 'HD-60 Republican'),
  ('Utah State House District 61', 'Republican', 1, 'HD-61 Republican'),
  ('Utah State House District 61', 'Democratic', 1, 'HD-61 Democratic'),
  ('Utah State House District 62', 'Republican', 1, 'HD-62 Republican'),
  ('Utah State House District 62', 'Democratic', 1, 'HD-62 Democratic'),
  ('Utah State House District 63', 'Republican', 1, 'HD-63 Republican'),
  ('Utah State House District 63', 'Democratic', 1, 'HD-63 Democratic'),
  ('Utah State House District 64', 'Republican', 1, 'HD-64 Republican'),
  ('Utah State House District 65', 'Republican', 1, 'HD-65 Republican'),

  -- ── SALT LAKE COUNTY OFFICES ─────────────────────────────────────────────
  ('Salt Lake County Sheriff',          'Republican', 1, 'SL County Sheriff — Republican Primary'),
  ('Salt Lake County Sheriff',          'Democratic', 1, 'SL County Sheriff — Democratic'),
  ('Salt Lake County District Attorney','Democratic', 1, 'SL County DA — Democratic Primary'),
  ('Salt Lake County District Attorney','Republican', 1, 'SL County DA — Republican'),
  ('Salt Lake County Council District 1','Democratic', 1, 'SL County Council D1 — Democratic'),
  ('Salt Lake County Council District 3','Democratic', 1, 'SL County Council D3 — Democratic'),
  ('Salt Lake County Council District 3','Republican', 1, 'SL County Council D3 — Republican'),
  ('Salt Lake County Council District 5','Republican', 1, 'SL County Council D5 — Republican Primary'),
  ('Salt Lake County Council District 5','Democratic', 1, 'SL County Council D5 — Democratic'),
  ('Salt Lake County Council At-Large A','Republican', 1, 'SL County Council At-Large A — Republican'),
  ('Salt Lake County Council At-Large A','Democratic', 1, 'SL County Council At-Large A — Democratic'),
  ('Salt Lake County Surveyor',          'Republican', 1, 'SL County Surveyor — Republican Primary'),
  ('Salt Lake County Auditor',           'Republican', 1, 'SL County Auditor — Republican'),
  ('Salt Lake County Auditor',           'Democratic', 1, 'SL County Auditor — Democratic'),
  ('Salt Lake County Assessor',          'Republican', 1, 'SL County Assessor — Republican'),
  ('Salt Lake County Assessor',          'Democratic', 1, 'SL County Assessor — Democratic'),
  ('Salt Lake County Clerk',             'Democratic', 1, 'SL County Clerk — Democratic'),
  ('Salt Lake County Recorder',          'Democratic', 1, 'SL County Recorder — Democratic'),

  -- ── UTAH COUNTY OFFICES ──────────────────────────────────────────────────
  ('Utah County Commission Seat A', 'Republican', 1, 'Utah County Commission Seat A — Republican Primary'),
  ('Utah County Commission Seat A', 'Democratic', 1, 'Utah County Commission Seat A — Democratic'),
  ('Utah County Commission Seat B', 'Republican', 1, 'Utah County Commission Seat B — Republican Primary (3-way)'),
  ('Utah County Commission Seat B', 'Democratic', 1, 'Utah County Commission Seat B — Democratic'),
  ('Utah County Clerk',   'Republican', 1, 'Utah County Clerk — Republican Primary'),
  ('Utah County Auditor', 'Republican', 1, 'Utah County Auditor — Republican'),
  ('Utah County Sheriff', 'Republican', 1, 'Utah County Sheriff — Republican'),
  ('Utah County Attorney','Republican', 1, 'Utah County Attorney — Republican'),

  -- ── UTAH STATE BOARD OF EDUCATION ────────────────────────────────────────
  -- District 7: special election for unexpired term (vacancy from Molly Hart); runs on June 23 ballot.
  ('Utah State Board of Education District 5',  'Republican', 1, 'USBE D5 Republican — covers parts of SL County'),
  ('Utah State Board of Education District 5',  'Democratic', 1, 'USBE D5 Democratic'),
  ('Utah State Board of Education District 7',  'Republican', 1, 'USBE D7 Republican — special election (unexpired term), Sandy/Draper/Cottonwood Heights/Alta'),
  ('Utah State Board of Education District 7',  'Democratic', 1, 'USBE D7 Democratic — special election (unexpired term)'),
  ('Utah State Board of Education District 8',  'Republican', 1, 'USBE D8 Republican Primary — Holladay/Murray area'),
  ('Utah State Board of Education District 8',  'Democratic', 1, 'USBE D8 Democratic'),
  ('Utah State Board of Education District 11', 'Republican', 1, 'USBE D11 Republican Primary — S. SL County / N. Utah County'),
  ('Utah State Board of Education District 11', 'Democratic', 1, 'USBE D11 Democratic'),
  ('Utah State Board of Education District 14', 'Republican', 1, 'USBE D14 Republican Primary (4-way) — Utah County'),
  ('Utah State Board of Education District 14', 'Democratic', 1, 'USBE D14 Democratic')
) AS v(position_name, primary_party, seats, description)
ON CONFLICT (election_id, position_name, primary_party)
DO UPDATE SET
  seats = EXCLUDED.seats,
  description = EXCLUDED.description,
  updated_at = now();

-- =============================================================================
-- Step 3: Insert candidates (idempotent via NOT EXISTS on race_id + full_name)
--
-- Helper macro used throughout:
--   WITH race AS (SELECT r.id AS rid FROM essentials.races r
--                 JOIN essentials.elections e ON r.election_id = e.id
--                 WHERE e.name = '2026 Utah Primary' AND e.election_date = '2026-06-23'
--                   AND e.state = 'UT'
--                   AND r.position_name = '<pos>' AND r.primary_party = '<party>')
-- =============================================================================

-- ── FEDERAL — U.S. House ─────────────────────────────────────────────────────

-- UT-2 Republican Primary (Blake Moore vs. Karianne Lisonbee)
-- Moore: incumbent UT-1 running in new UT-2 after redistricting
-- Lisonbee: current UT State House D-14 rep; challenger for federal seat
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, v.pid::uuid, v.full_name, v.first_name, v.last_name, v.is_inc, v.cstatus, 'sos_filing'
FROM (
  SELECT r.id AS rid FROM essentials.races r JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Utah Primary' AND e.election_date = '2026-06-23' AND e.state = 'UT'
    AND r.position_name = 'U.S. House District 2' AND r.primary_party = 'Republican'
) race,
(VALUES
  ('e365a1d4-2de3-4fb6-b416-d78227836553', 'Blake Moore',      'Blake',    'Moore',    true,  'active'),
  ('da3ae2d0-95ab-4292-9d49-51f4576fe56b', 'Karianne Lisonbee','Karianne', 'Lisonbee', false, 'active')
) AS v(pid, full_name, first_name, last_name, is_inc, cstatus)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- UT-2 Democratic (Peter Crosby — convention winner, no primary)
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'sos_filing'
FROM (
  SELECT r.id AS rid FROM essentials.races r JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Utah Primary' AND e.election_date = '2026-06-23' AND e.state = 'UT'
    AND r.position_name = 'U.S. House District 2' AND r.primary_party = 'Democratic'
) race,
(VALUES ('Peter Crosby','Peter','Crosby')) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- UT-3 Republican Primary (Celeste Maloy vs. Phil Lyman)
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, v.pid::uuid, v.full_name, v.first_name, v.last_name, v.is_inc, 'active', 'sos_filing'
FROM (
  SELECT r.id AS rid FROM essentials.races r JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Utah Primary' AND e.election_date = '2026-06-23' AND e.state = 'UT'
    AND r.position_name = 'U.S. House District 3' AND r.primary_party = 'Republican'
) race,
(VALUES
  ('a7983eb6-bae0-4269-856b-f4554fb5ce29', 'Celeste Maloy', 'Celeste', 'Maloy', true),
  (NULL,                                    'Phil Lyman',    'Phil',    'Lyman', false)
) AS v(pid, full_name, first_name, last_name, is_inc)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- UT-3 Democratic + UT-4 Republican + UT-4 Democratic (all convention winners)
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, NULL, v.full_name, v.first_name, v.last_name, v.is_inc, 'active', 'sos_filing'
FROM essentials.races r
JOIN essentials.elections e ON r.election_id = e.id,
(VALUES
  ('U.S. House District 3','Democratic','Kent Udell',   'Kent',  'Udell',  false),
  ('U.S. House District 4','Republican','Mike Kennedy', 'Mike',  'Kennedy',true),
  ('U.S. House District 4','Democratic','Jonny Larsen', 'Jonny', 'Larsen', false)
) AS v(pos, party, full_name, first_name, last_name, is_inc)
WHERE e.name = '2026 Utah Primary' AND e.election_date = '2026-06-23' AND e.state = 'UT'
  AND r.position_name = v.pos AND r.primary_party = v.party
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.full_name = v.full_name
  );

-- ── UTAH STATE SENATE ─────────────────────────────────────────────────────────

-- Batch: all Senate candidates in one INSERT via JOIN
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, NULL, v.full_name, v.first_name, v.last_name, v.is_inc, v.cstatus, 'sos_filing'
FROM essentials.races r
JOIN essentials.elections e ON r.election_id = e.id,
(VALUES
  -- SD-9
  ('Utah State Senate District 9','Democratic','Jen Plumb',         'Jen',      'Plumb',    true,  'active'),
  ('Utah State Senate District 9','Republican','Thaddeus A. Evans', 'Thaddeus', 'Evans',    false, 'active'),
  -- SD-11
  ('Utah State Senate District 11','Republican','Brooks Benson',    'Brooks',   'Benson',   false, 'active'),
  -- SD-12
  ('Utah State Senate District 12','Democratic','Karen Kwan',       'Karen',    'Kwan',     true,  'active'),
  ('Utah State Senate District 12','Republican','Deidre Tyler',     'Deidre',   'Tyler',    false, 'active'),
  -- SD-13 (3-way D primary — open seat)
  ('Utah State Senate District 13','Democratic','Silvia Catten',    'Silvia',   'Catten',   false, 'active'),
  ('Utah State Senate District 13','Democratic','Evan Done',        'Evan',     'Done',     false, 'active'),
  ('Utah State Senate District 13','Democratic','Taylor J. Paden',  'Taylor',   'Paden',    false, 'active'),
  ('Utah State Senate District 13','Republican','Ryan L. Mahoney',  'Ryan',     'Mahoney',  false, 'active'),
  -- SD-14 (2-way D primary)
  ('Utah State Senate District 14','Democratic','Stephanie Pitcher','Stephanie','Pitcher',  true,  'active'),
  ('Utah State Senate District 14','Democratic','Tayler Khater',    'Tayler',   'Khater',   false, 'active'),
  -- SD-18 (2-way R primary; spans SL + Utah County)
  ('Utah State Senate District 18','Republican','Daniel McCay',     'Daniel',   'McCay',    true,  'active'),
  ('Utah State Senate District 18','Republican','Doug Fiefia',      'Doug',     'Fiefia',   false, 'active'),
  ('Utah State Senate District 18','Democratic','A. Dane Anderson', 'A. Dane',  'Anderson', false, 'active'),
  -- SD-19
  ('Utah State Senate District 19','Republican','Kirk Cullimore',   'Kirk',     'Cullimore',true,  'active'),
  ('Utah State Senate District 19','Democratic','Shana Anderson',   'Shana',    'Anderson', false, 'active')
) AS v(pos, party, full_name, first_name, last_name, is_inc, cstatus)
WHERE e.name = '2026 Utah Primary' AND e.election_date = '2026-06-23' AND e.state = 'UT'
  AND r.position_name = v.pos AND r.primary_party = v.party
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.full_name = v.full_name
  );

-- ── UTAH STATE HOUSE — SALT LAKE COUNTY (HD-21 to HD-49) ─────────────────────

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, NULL, v.full_name, v.first_name, v.last_name, v.is_inc, v.cstatus, 'sos_filing'
FROM essentials.races r
JOIN essentials.elections e ON r.election_id = e.id,
(VALUES
  ('Utah State House District 21','Democratic','Stephen Otterstrom','Stephen','Otterstrom',false,'active'),
  ('Utah State House District 21','Democratic','Aaron Wiley',       'Aaron',  'Wiley',     false,'active'),
  ('Utah State House District 22','Republican','Char Varga',        'Char',   'Varga',      false,'active'),
  ('Utah State House District 22','Democratic','Jen Dailey-Provost','Jen',    'Dailey-Provost',true,'active'),
  ('Utah State House District 23','Republican','Franklin D. Robinson','Franklin','Robinson',false,'active'),
  ('Utah State House District 23','Democratic','Hoang Nguyen',      'Hoang',  'Nguyen',    true, 'active'),
  ('Utah State House District 24','Republican','Braeden J. Oswald', 'Braeden','Oswald',    false,'active'),
  ('Utah State House District 24','Democratic','Grant Amjad Miller','Grant Amjad','Miller',true, 'active'),
  ('Utah State House District 25','Republican','Richard T. Nowak',  'Richard','Nowak',     false,'active'),
  ('Utah State House District 25','Democratic','Angela Romero',     'Angela', 'Romero',    true, 'active'),
  ('Utah State House District 26','Republican','Matt MacPherson',   'Matt',   'MacPherson',true, 'active'),
  ('Utah State House District 26','Democratic','Michael E. Finch',  'Michael','Finch',     false,'active'),
  ('Utah State House District 27','Republican','Anthony Loubet',    'Anthony','Loubet',    true, 'active'),
  ('Utah State House District 27','Democratic','Liz Oates',         'Liz',    'Oates',     false,'active'),
  ('Utah State House District 28','Republican','Nicholeen Peck',    'Nicholeen','Peck',    true, 'active'),
  ('Utah State House District 28','Democratic','Anita Dalrymple',   'Anita',  'Dalrymple', false,'active'),
  ('Utah State House District 29','Republican','Alexis Wheeler',    'Alexis', 'Wheeler',   false,'active'),
  ('Utah State House District 29','Republican','Sheldon Birch',     'Sheldon','Birch',     false,'active'),
  ('Utah State House District 29','Democratic','Sara Snow',         'Sara',   'Snow',      false,'active'),
  ('Utah State House District 30','Republican','Dave Parke',        'Dave',   'Parke',     false,'active'),
  ('Utah State House District 30','Democratic','Jake Fitisemanu',   'Jake',   'Fitisemanu',true, 'active'),
  ('Utah State House District 31','Republican','Melody Jones',      'Melody', 'Jones',     false,'active'),
  ('Utah State House District 31','Democratic','Verona Mauga',      'Verona', 'Mauga',     true, 'active'),
  ('Utah State House District 32','Republican','Aileen Hampton',    'Aileen', 'Hampton',   false,'active'),
  ('Utah State House District 32','Democratic','Sahara Hayes',      'Sahara', 'Hayes',     true, 'active'),
  ('Utah State House District 33','Republican','Anna Reeves',       'Anna',   'Reeves',    false,'active'),
  ('Utah State House District 33','Democratic','Doug Owens',        'Doug',   'Owens',     true, 'active'),
  ('Utah State House District 34','Democratic','Julie Jackson',     'Julie',  'Jackson',   false,'active'),
  ('Utah State House District 34','Democratic','Erin Jemison',      'Erin',   'Jemison',   false,'active'),
  ('Utah State House District 35','Republican','Monique I. Ketcham','Monique','Ketcham',   false,'active'),
  ('Utah State House District 35','Democratic','Rosalba Dominguez', 'Rosalba','Dominguez', true, 'active'),
  ('Utah State House District 36','Republican','James A. Dunnigan', 'James',  'Dunnigan',  true, 'active'),
  ('Utah State House District 37','Republican','Casey Saxton',      'Casey',  'Saxton',    false,'active'),
  ('Utah State House District 37','Democratic','Ashlee Matthews',   'Ashlee', 'Matthews',  true, 'active'),
  ('Utah State House District 38','Republican','Chris McConnehey',  'Chris',  'McConnehey',false,'active'),
  ('Utah State House District 38','Republican','Gloria Vindas',     'Gloria', 'Vindas',    false,'active'),
  ('Utah State House District 39','Republican','Ken Ivory',         'Ken',    'Ivory',     true, 'active'),
  ('Utah State House District 39','Democratic','Drew Howells',      'Drew',   'Howells',   false,'active'),
  ('Utah State House District 40','Democratic','Wendy Davis',       'Wendy',  'Davis',     false,'active'),
  ('Utah State House District 40','Democratic','Andrew Stoddard',   'Andrew', 'Stoddard',  true, 'active'),
  ('Utah State House District 41','Republican','Darren Croft',      'Darren', 'Croft',     false,'active'),
  ('Utah State House District 41','Republican','Eryn A. Russo',     'Eryn',   'Russo',     false,'active'),
  ('Utah State House District 41','Democratic','John Arthur',       'John',   'Arthur',    true, 'active'),
  ('Utah State House District 42','Republican','Clint Okerlund',    'Clint',  'Okerlund',  true, 'active'),
  ('Utah State House District 42','Democratic','Iva Williams',      'Iva',    'Williams',  false,'active'),
  ('Utah State House District 43','Republican','Steve Eliason',     'Steve',  'Eliason',   true, 'active'),
  ('Utah State House District 43','Democratic','Ofa Matagi',        'Ofa',    'Matagi',    false,'active'),
  ('Utah State House District 44','Republican','Jordan Teuscher',   'Jordan', 'Teuscher',  true, 'active'),
  ('Utah State House District 44','Republican','Scott Stephenson',  'Scott',  'Stephenson',false,'active'),
  ('Utah State House District 44','Democratic','Jess Birtcher',     'Jess',   'Birtcher',  false,'active'),
  ('Utah State House District 45','Republican','Tracy Miller',      'Tracy',  'Miller',    true, 'active'),
  ('Utah State House District 45','Democratic','Rod Moser',         'Rod',    'Moser',     false,'active'),
  ('Utah State House District 46','Republican','Cal Roberts',       'Cal',    'Roberts',   true, 'active'),
  ('Utah State House District 46','Democratic','Braxten Rutherford','Braxten','Rutherford',false,'active'),
  ('Utah State House District 47','Republican','Mark A. Strong',    'Mark',   'Strong',    true, 'active'),
  ('Utah State House District 48','Republican','Nik Anderson',      'Nik',    'Anderson',  false,'active'),
  ('Utah State House District 48','Republican','Jake Hunsaker',     'Jake',   'Hunsaker',  false,'active'),
  ('Utah State House District 48','Democratic','Benyde Walker',     'Benyde', 'Walker',    false,'active'),
  ('Utah State House District 49','Republican','Candice B. Pierucci','Candice','Pierucci', true, 'active'),
  ('Utah State House District 49','Democratic','Lillian Bowles',    'Lillian','Bowles',    false,'active')
) AS v(pos, party, full_name, first_name, last_name, is_inc, cstatus)
WHERE e.name = '2026 Utah Primary' AND e.election_date = '2026-06-23' AND e.state = 'UT'
  AND r.position_name = v.pos AND r.primary_party = v.party
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.full_name = v.full_name
  );

-- ── UTAH STATE HOUSE — UTAH COUNTY (HD-50 to HD-65) ──────────────────────────
-- All incumbents have verified politician_ids. Seeded with incumbent links.

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, v.pid::uuid, v.full_name, v.first_name, v.last_name, v.is_inc, 'active', 'sos_filing'
FROM essentials.races r
JOIN essentials.elections e ON r.election_id = e.id,
(VALUES
  ('Utah State House District 50','Republican','7ebd1d5d-f51f-49fd-98df-3e5223e49208','Stephanie Gricius',  'Stephanie','Gricius',     true),
  ('Utah State House District 50','Democratic',NULL,                                   'Kristin Meyer',      'Kristin',  'Meyer',       false),
  ('Utah State House District 51','Republican','ef01b369-5092-4548-bfc3-e3fd611b1039','Leah Hansen',        'Leah',     'Hansen',      true),
  ('Utah State House District 51','Democratic',NULL,                                   'Brett Nielsen',      'Brett',    'Nielsen',     false),
  ('Utah State House District 52','Republican','a42272fb-f41b-4a64-86d5-a0a0eeec5b82','Cory Maloy',         'Cory',     'Maloy',       true),
  ('Utah State House District 52','Democratic',NULL,                                   'Nicole Melling',     'Nicole',   'Melling',     false),
  ('Utah State House District 53','Republican','2fa5347c-fb56-443d-8f1d-c1bff270bf9e','Kay J. Christofferson','Kay',   'Christofferson',true),
  ('Utah State House District 53','Democratic',NULL,                                   'Kevin R. Slater',    'Kevin',    'Slater',      false),
  ('Utah State House District 54','Republican','596c0496-20ba-41f6-8b9a-f511bc7c2de8','Kristen S. Chevrier','Kristen',  'Chevrier',    true),
  ('Utah State House District 54','Democratic',NULL,                                   'Kristina Robinson',  'Kristina', 'Robinson',    false),
  ('Utah State House District 55','Republican','8928852d-0688-431b-aad2-bf55275583fb','Jon Hawkins',         'Jon',      'Hawkins',     true),
  ('Utah State House District 55','Democratic',NULL,                                   'Travis Hysell',       'Travis',   'Hysell',      false),
  ('Utah State House District 56','Republican','61816aa4-4de0-4e1a-a249-cea5e2a8d169','Val L. Peterson',     'Val',      'Peterson',    true),
  ('Utah State House District 56','Democratic',NULL,                                   'Natassja Grossman',   'Natassja', 'Grossman',    false),
  ('Utah State House District 57','Republican','ec7d4cce-d016-48ba-82d1-4f246d44542e','Nelson T. Abbott',    'Nelson',   'Abbott',      true),
  ('Utah State House District 58','Republican','f214eee8-0e54-450a-8a2b-1ca8ce8e9182','David Shallenberger', 'David',    'Shallenberger',true),
  ('Utah State House District 58','Democratic',NULL,                                   'Karli Black',         'Karli',    'Black',       false),
  ('Utah State House District 60','Republican','e5c70a0f-1b0a-4ea2-b159-a4d421223929','Grant Pace',          'Grant',    'Pace',        true),
  ('Utah State House District 61','Republican','63901c61-d007-4cbd-b3bc-c50a4eaa73f3','Lisa Shepherd',       'Lisa',     'Shepherd',    true),
  ('Utah State House District 61','Democratic',NULL,                                   'Alan Jimenez',        'Alan',     'Jimenez',     false),
  ('Utah State House District 62','Republican','0b36a14c-3d2d-4e05-88ab-47a738d1283b','Norman K. Thurston',  'Norman',   'Thurston',    true),
  ('Utah State House District 62','Democratic',NULL,                                   'David Chappell',      'David',    'Chappell',    false),
  ('Utah State House District 63','Republican','bca7a17c-82d9-4cbc-8858-7763d4c5fe87','Stephen L. Whyte',    'Stephen',  'Whyte',       true),
  ('Utah State House District 63','Democratic',NULL,                                   'Mark Youngquist',     'Mark',     'Youngquist',  false),
  ('Utah State House District 64','Republican','b86c57b4-9835-4fa3-8924-c52e52f19a66','Jackie Larson',        'Jackie',   'Larson',      true),
  ('Utah State House District 65','Republican','2477ac16-810e-4d5c-a71e-a4f3b8f29d1e','Doug Welton',         'Doug',     'Welton',      true)
) AS v(pos, party, pid, full_name, first_name, last_name, is_inc)
WHERE e.name = '2026 Utah Primary' AND e.election_date = '2026-06-23' AND e.state = 'UT'
  AND r.position_name = v.pos AND r.primary_party = v.party
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.full_name = v.full_name
  );

-- HD-64 Jeff Burton: status 'filed' on vote.utah.gov — verify qualification before treating as ballot candidate
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, NULL, 'Jeff Burton', 'Jeff', 'Burton', false, 'filed', 'sos_filing'
FROM essentials.races r JOIN essentials.elections e ON r.election_id = e.id
WHERE e.name = '2026 Utah Primary' AND e.election_date = '2026-06-23' AND e.state = 'UT'
  AND r.position_name = 'Utah State House District 64' AND r.primary_party = 'Republican'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.full_name = 'Jeff Burton'
  );

-- ── SALT LAKE COUNTY OFFICES ──────────────────────────────────────────────────

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, v.pid::uuid, v.full_name, v.first_name, v.last_name, v.is_inc, v.cstatus, 'county_clerk'
FROM essentials.races r
JOIN essentials.elections e ON r.election_id = e.id,
(VALUES
  -- Sheriff R primary
  ('Salt Lake County Sheriff','Republican',NULL,'Shane Manwaring','Shane','Manwaring',false,'active'),
  ('Salt Lake County Sheriff','Republican',NULL,'Nicholas Roberts','Nicholas','Roberts',false,'active'),
  ('Salt Lake County Sheriff','Democratic',NULL,'Rosie Rivera',   'Rosie', 'Rivera',  false,'active'),
  -- DA D primary
  ('Salt Lake County District Attorney','Democratic',NULL,'Sim Gill',       'Sim',   'Gill',    true, 'active'),
  ('Salt Lake County District Attorney','Democratic',NULL,'Shawn Robinson', 'Shawn', 'Robinson',false,'active'),
  ('Salt Lake County District Attorney','Republican',NULL,'Kent Davis',     'Kent',  'Davis',   false,'active'),
  -- Council D1 (D-only; Jiro Johnson linked to politician record)
  ('Salt Lake County Council District 1','Democratic','d1bd8ce5-1323-4476-8663-be3295998e36','Jiro Johnson','Jiro','Johnson',true,'active'),
  -- Council D3
  ('Salt Lake County Council District 3','Democratic',NULL,'Luke Maynes','Luke','Maynes',false,'active'),
  ('Salt Lake County Council District 3','Republican',NULL,'Mike Bird',  'Mike','Bird',  false,'active'),
  -- Council D5 R primary
  ('Salt Lake County Council District 5','Republican',NULL,'Chris Null',    'Chris', 'Null',    false,'active'),
  ('Salt Lake County Council District 5','Republican',NULL,'Traci Crockett','Traci', 'Crockett',false,'active'),
  ('Salt Lake County Council District 5','Democratic',NULL,'Sara Cimmers',  'Sara',  'Cimmers', false,'active'),
  -- Council At-Large A
  ('Salt Lake County Council At-Large A','Republican',NULL,'Kathleen Anderson','Kathleen','Anderson',false,'active'),
  ('Salt Lake County Council At-Large A','Democratic',NULL,'Zach Robinson',    'Zach',    'Robinson',false,'active'),
  -- Surveyor R primary
  ('Salt Lake County Surveyor','Republican',NULL,'Bradley Park',   'Bradley','Park',      false,'active'),
  ('Salt Lake County Surveyor','Republican',NULL,'Kent Setterberg','Kent',   'Setterberg',false,'active'),
  -- Auditor, Assessor, Clerk, Recorder
  ('Salt Lake County Auditor',  'Republican',NULL,'Chris Harding', 'Chris',    'Harding', false,'active'),
  ('Salt Lake County Auditor',  'Democratic',NULL,'Ali Cloward',   'Ali',      'Cloward', false,'active'),
  ('Salt Lake County Assessor', 'Republican',NULL,'Chris Stavros', 'Chris',    'Stavros', false,'active'),
  ('Salt Lake County Assessor', 'Democratic',NULL,'Joel Frost',    'Joel',     'Frost',   false,'active'),
  ('Salt Lake County Clerk',    'Democratic',NULL,'Lannie Chapman','Lannie',   'Chapman', false,'active'),
  ('Salt Lake County Recorder', 'Democratic',NULL,'Rashelle Hobbs','Rashelle', 'Hobbs',   false,'active')
) AS v(pos, party, pid, full_name, first_name, last_name, is_inc, cstatus)
WHERE e.name = '2026 Utah Primary' AND e.election_date = '2026-06-23' AND e.state = 'UT'
  AND r.position_name = v.pos AND r.primary_party = v.party
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.full_name = v.full_name
  );

-- ── UTAH COUNTY OFFICES ───────────────────────────────────────────────────────

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, NULL, v.full_name, v.first_name, v.last_name, v.is_inc, v.cstatus, 'county_clerk'
FROM essentials.races r
JOIN essentials.elections e ON r.election_id = e.id,
(VALUES
  -- Commission Seat A R primary
  ('Utah County Commission Seat A','Republican','Brent Bowles',     'Brent',       'Bowles',   false,'active'),
  ('Utah County Commission Seat A','Republican','Michelle Kaufusi', 'Michelle',    'Kaufusi',  false,'active'),
  ('Utah County Commission Seat A','Democratic','Jeanne Marie Bowen','Jeanne Marie','Bowen',   false,'active'),
  -- Commission Seat B R 3-way primary
  ('Utah County Commission Seat B','Republican','David Spencer',    'David',       'Spencer',  false,'active'),
  ('Utah County Commission Seat B','Republican','Carolina Herrin',  'Carolina',    'Herrin',   false,'active'),
  ('Utah County Commission Seat B','Republican','Isaac Paxman',     'Isaac',       'Paxman',   false,'active'),
  -- KNOWN GAP: "J. Allen" — full first name not publicly findable; seeded as-is.
  -- Update first_name/full_name when confirmed via Utah County Elections office (801-851-8683).
  ('Utah County Commission Seat B','Democratic','J. Allen',         'J.',          'Allen',    false,'active'),
  -- Clerk R primary
  ('Utah County Clerk',   'Republican','Aaron Davidson','Aaron','Davidson',true, 'active'),
  ('Utah County Clerk',   'Republican','Corey Astill',  'Corey','Astill',  false,'active'),
  -- Auditor, Sheriff, Attorney (uncontested R)
  ('Utah County Auditor', 'Republican','Gina Tanner','Gina','Tanner',false,'active'),
  ('Utah County Sheriff', 'Republican','Mike Smith',  'Mike','Smith', false,'active'),
  ('Utah County Attorney','Republican','Jeff Gray',   'Jeff','Gray',  false,'active')
) AS v(pos, party, full_name, first_name, last_name, is_inc, cstatus)
WHERE e.name = '2026 Utah Primary' AND e.election_date = '2026-06-23' AND e.state = 'UT'
  AND r.position_name = v.pos AND r.primary_party = v.party
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.full_name = v.full_name
  );

-- ── UTAH STATE BOARD OF EDUCATION ─────────────────────────────────────────────
-- D7 is a special election for an unexpired term (vacancy from Molly Hart → Supt appointment).
-- Runs on the regular June 23 primary ballot. Both candidates are election_candidates
-- (nominated at special party conventions April 25, 2026 — one each, no intraparty contest).

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, NULL, v.full_name, v.first_name, v.last_name, v.is_inc, v.cstatus, 'sos_filing'
FROM essentials.races r
JOIN essentials.elections e ON r.election_id = e.id,
(VALUES
  ('Utah State Board of Education District 5','Republican','J. Michael Clara','J. Michael','Clara',     false,'active'),
  ('Utah State Board of Education District 5','Democratic','Sara Reale',       'Sara',       'Reale',    true, 'active'),
  ('Utah State Board of Education District 7','Republican','Erin Longacre',    'Erin',       'Longacre', true, 'active'),
  ('Utah State Board of Education District 7','Democratic','James Martin',     'James',      'Martin',   false,'active'),
  ('Utah State Board of Education District 8','Republican','Nicole McDermott', 'Nicole',     'McDermott',false,'active'),
  ('Utah State Board of Education District 8','Republican','Trina Christensen','Trina',      'Christensen',false,'active'),
  ('Utah State Board of Education District 8','Democratic','Araueni Olivares', 'Araueni',    'Olivares', false,'active'),
  ('Utah State Board of Education District 11','Republican','Terry Hutchinson','Terry',      'Hutchinson',false,'active'),
  ('Utah State Board of Education District 11','Republican','Tracy Nuttall',   'Tracy',      'Nuttall',  false,'active'),
  ('Utah State Board of Education District 11','Democratic','Lacey Peterson',  'Lacey',      'Peterson', false,'active'),
  ('Utah State Board of Education District 14','Republican','Linda Hanks',     'Linda',      'Hanks',    false,'active'),
  ('Utah State Board of Education District 14','Republican','Nichole Isom',    'Nichole',    'Isom',     false,'active'),
  ('Utah State Board of Education District 14','Republican','Courtnee Justice','Courtnee',   'Justice',  false,'active'),
  ('Utah State Board of Education District 14','Republican','Will Pierce',     'Will',       'Pierce',   false,'active'),
  ('Utah State Board of Education District 14','Democratic','Danielle Stratton','Danielle',  'Stratton', false,'active')
) AS v(pos, party, full_name, first_name, last_name, is_inc, cstatus)
WHERE e.name = '2026 Utah Primary' AND e.election_date = '2026-06-23' AND e.state = 'UT'
  AND r.position_name = v.pos AND r.primary_party = v.party
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.full_name = v.full_name
  );

COMMIT;

-- =============================================================================
-- Verification queries (run manually after seeding):
--
-- Race count:
--   SELECT COUNT(*) FROM essentials.races r
--   JOIN essentials.elections e ON r.election_id = e.id
--   WHERE e.name = '2026 Utah Primary';
--   -- Expected: ~131
--
-- Candidate count per race (contested primaries only):
--   SELECT r.position_name, r.primary_party, COUNT(rc.*) AS candidates
--   FROM essentials.races r
--   JOIN essentials.elections e ON r.election_id = e.id
--   LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
--   WHERE e.name = '2026 Utah Primary'
--     AND rc.candidate_status = 'active'
--   GROUP BY r.position_name, r.primary_party
--   HAVING COUNT(rc.*) > 1
--   ORDER BY r.position_name;
--
-- Incumbent links verified:
--   SELECT rc.full_name, rc.politician_id, rc.is_incumbent
--   FROM essentials.race_candidates rc
--   JOIN essentials.races r ON r.id = rc.race_id
--   JOIN essentials.elections e ON r.election_id = e.id
--   WHERE e.name = '2026 Utah Primary' AND rc.is_incumbent = true
--   ORDER BY rc.full_name;
-- =============================================================================
