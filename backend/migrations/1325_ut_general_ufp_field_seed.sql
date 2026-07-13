-- =====================================================================================
-- Seed: 2026 Utah General election + general races for the 8 districts with a
-- Utah Forward Party (UFP) candidate, incl. SD-11's actual INCUMBENT Emily Buss.
--
-- WHY: the UT local seed modeled only party PRIMARIES ("2026 Utah Primary",
--   R/D races). Third-party candidates nominate by convention and never appear in
--   those races, so the whole UFP field was invisible — including a sitting senator
--   (Buss, SD-11, UFP) missing from her own re-election race. Flagged in
--   `.planning/todos/2026-07-09-ut-primary-losers-cull.md`; independent-candidate
--   evidence-parity rule says verify + seed, not passively hold.
--
-- MODEL: mirrors the Senate-seed general pattern (NE 2026 Statewide General /
--   Osborn): one general race per seat, primary_party='', full field as
--   race_candidates; third-party label lives on politicians.party ('Independent'
--   precedent). UNLIKE the statewide NE race, these races keep the district
--   office_id (UT state-leg geofencing rides office_id -> districts.geo_id).
--
-- EVIDENCE: Ballotpedia office pages fetched 2026-07-12 via /wiki/api.php parse
--   (Utah State Senate District 9/11/13/21, Utah House of Representatives District
--   23/28/29/53), matching the 2026-07-09 agent pass. Full general fields:
--     SD-9 : Jennifer "Jen" Plumb (D, inc) / Thaddeus A. Evans (R) / J. Lowry Snow (UFP)
--     SD-11: Emily Buss (UFP, INC) / MacKenzie Miller (D) / Brooks Benson (R)
--     SD-13: Silvia Catten (D) / Ryan L. Mahoney (R) / Colin Smith (UFP)   [open seat]
--     SD-21: Brady Brammer (R, inc) / Kandee Myers (D) / Wayne Woodfield (UFP)
--     HD-23: Hoang Nguyen (D, inc) / Franklin Robinson (R) / Cabot Nelson (UFP)
--     HD-28: Nicholeen Peck (R, inc) / Anita Dalrymple (D) / Wales Nematollahi (UFP)
--     HD-29: Sara Snow (D) / Sheldon Birch (R) / Jonathan Garrard (Constitution) /
--            Tynley Bean (UFP)                                            [open seat]
--     HD-53: Kay Christofferson (R, inc) / Kevin Slater (D) / John Boyd (UFP)
--   Garrard (Constitution Party, HD-29) is seeded too — same evidence bar, same
--   parity rule. SOS corroboration attempted 2026-07-12: vote.utah.gov's filing
--   list is behind the address-keyed votesearch app; the ~Sept-Oct
--   voteinfo.utah.gov pamphlet re-check re-verifies this field officially.
--   J. Lowry Snow (UFP, SD-9) is NOT the DB's incumbent "Adam Snow" homonym —
--   verified distinct. R/D general rows are copied from each district's primary
--   races WHERE candidate_status='active' (post-cull = exactly the primary winner
--   or sole filer; verified 1 active per primary race at authoring time).
--
-- Buss (pid 70b5e5a8-2ae4-454e-b75e-adb200b7b91d, external_id -334574) already
-- exists with the State Senator District 11 office — she gets party + the general
-- rc row only. 8 new politicians (data_source='ballotpedia', external_id NULL per
-- UT-challenger convention).
--
-- AUDIT-ONLY / unregistered (no schema_migrations ledger entry). Idempotent.
-- =====================================================================================

BEGIN;

-- 1. The general election ------------------------------------------------------------
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT '2026 Utah General', '2026-11-03', 'general', 'state', 'UT'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = '2026 Utah General');

-- 2. General races (office_id copied from the district's primary races) ---------------
INSERT INTO essentials.races (position_name, primary_party, election_id, office_id, seats)
SELECT DISTINCT pr.position_name, '', ge.id, pr.office_id, 1
FROM essentials.races pr
JOIN essentials.elections pe ON pe.id = pr.election_id AND pe.name = '2026 Utah Primary'
CROSS JOIN (SELECT id FROM essentials.elections WHERE name = '2026 Utah General') ge
WHERE pr.position_name IN (
  'Utah State Senate District 9','Utah State Senate District 11',
  'Utah State Senate District 13','Utah State Senate District 21',
  'Utah State House District 23','Utah State House District 28',
  'Utah State House District 29','Utah State House District 53')
AND NOT EXISTS (
  SELECT 1 FROM essentials.races g
  WHERE g.election_id = ge.id AND g.position_name = pr.position_name);

-- 3. New third-party politicians -------------------------------------------------------
INSERT INTO essentials.politicians (full_name, first_name, last_name, party, is_active, is_incumbent, data_source)
SELECT v.full_name, v.first_name, v.last_name, v.party, true, false, 'ballotpedia'
FROM (VALUES
  ('J. Lowry Snow',    'J. Lowry', 'Snow',        'Utah Forward Party'),
  ('Colin Smith',      'Colin',    'Smith',       'Utah Forward Party'),
  ('Wayne Woodfield',  'Wayne',    'Woodfield',   'Utah Forward Party'),
  ('Cabot Nelson',     'Cabot',    'Nelson',      'Utah Forward Party'),
  ('Wales Nematollahi','Wales',    'Nematollahi', 'Utah Forward Party'),
  ('Tynley Bean',      'Tynley',   'Bean',        'Utah Forward Party'),
  ('John Boyd',        'John',     'Boyd',        'Utah Forward Party'),
  ('Jonathan Garrard', 'Jonathan', 'Garrard',     'Constitution Party')
) AS v(full_name, first_name, last_name, party)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politicians p
  WHERE p.full_name = v.full_name AND p.data_source = 'ballotpedia');

-- Buss: label her party (row exists, party was NULL)
UPDATE essentials.politicians
SET party = 'Utah Forward Party'
WHERE id = '70b5e5a8-2ae4-454e-b75e-adb200b7b91d' AND (party IS NULL OR party = '');

-- 4a. R/D general rows: copy each primary race's ACTIVE candidate ---------------------
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, candidate_status, is_incumbent, source)
SELECT g.id, rc.politician_id, rc.full_name, rc.first_name, rc.last_name, 'active', rc.is_incumbent, 'ballotpedia'
FROM essentials.races pr
JOIN essentials.elections pe ON pe.id = pr.election_id AND pe.name = '2026 Utah Primary'
JOIN essentials.race_candidates rc ON rc.race_id = pr.id AND rc.candidate_status = 'active'
JOIN essentials.elections ge ON ge.name = '2026 Utah General'
JOIN essentials.races g ON g.election_id = ge.id AND g.position_name = pr.position_name
WHERE pr.position_name IN (
  'Utah State Senate District 9','Utah State Senate District 11',
  'Utah State Senate District 13','Utah State Senate District 21',
  'Utah State House District 23','Utah State House District 28',
  'Utah State House District 29','Utah State House District 53')
AND NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates x
  WHERE x.race_id = g.id AND x.politician_id = rc.politician_id);

-- 4b. Third-party general rows ---------------------------------------------------------
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, candidate_status, is_incumbent, source)
SELECT g.id, p.id, p.full_name, p.first_name, p.last_name, 'active', v.is_inc, 'ballotpedia'
FROM (VALUES
  ('Utah State Senate District 9',  'J. Lowry Snow',     false),
  ('Utah State Senate District 11', 'Emily Buss',        true),
  ('Utah State Senate District 13', 'Colin Smith',       false),
  ('Utah State Senate District 21', 'Wayne Woodfield',   false),
  ('Utah State House District 23',  'Cabot Nelson',      false),
  ('Utah State House District 28',  'Wales Nematollahi', false),
  ('Utah State House District 29',  'Jonathan Garrard',  false),
  ('Utah State House District 29',  'Tynley Bean',       false),
  ('Utah State House District 53',  'John Boyd',         false)
) AS v(position_name, full_name, is_inc)
JOIN essentials.elections ge ON ge.name = '2026 Utah General'
JOIN essentials.races g ON g.election_id = ge.id AND g.position_name = v.position_name
JOIN essentials.politicians p ON p.full_name = v.full_name
  AND (p.data_source = 'ballotpedia' OR p.id = '70b5e5a8-2ae4-454e-b75e-adb200b7b91d')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates x
  WHERE x.race_id = g.id AND x.politician_id = p.id);

COMMIT;
