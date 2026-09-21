-- CA_0127_seed_monroe_school_boards_2026_general.sql
-- Monroe County 2026 general: school-board seats. Nonpartisan and November-only, so they
-- never appeared on the '2026 Indiana Primary' and are absent from the general — a pure seed.
--
-- Extends 'IN 2026 Statewide General'. Creates 5 offices and 5 races / 6 candidates.
--
-- 🔴 VOTING METHOD: both corporations elect AT-LARGE — every voter in the whole corporation
-- votes for every open seat; the "district"/"township" only sets where a candidate must
-- live. So each seat is geofenced to the WHOLE corporation, NOT a sub-district:
--   MCCSC seats  -> whole-MCCSC district (geo_id 1800630)
--   RBB seats    -> whole-RBB districts  (geo_id 1809480)
-- (MCCSC's per-board-district geofences exist but must NOT be used for who-votes; they set
--  candidate residency only. Board electoral districts were last redrawn in 2023 for 2024;
--  2026 uses that same map.)
--
-- ADDS:
--   MCCSC Board District 1   Erin Wyatt (inc) — unopposed
--   MCCSC Board District 3   Ashley Pirani (inc) — unopposed
--   MCCSC Board District 7   Aja Jester (inc) — unopposed          (Cole Pospisil filed then withdrew)
--   RBB Board, Richland Twp  Kelly D. Scholl, Dennis R. Adams — open seat, CONTESTED
--   RBB Board, Bean Blossom  Christa Curtis — open seat, unopposed
-- Districts 2/4/5/6 of MCCSC and the RBB at-large seat are NOT up in 2026.
--
-- MODELLING: reuses existing district rows (whole-MCCSC 9bdc2b0f; RBB Richland a2c00ac4 /
-- Bean Blossom 76d0828f — all already geofenced to their whole corporation) and creates the
-- seat offices (none existed). MCCSC offices attach the existing per-district MCCSC chambers;
-- RBB offices use chamber_id NULL (no Richland/Bean Blossom chamber exists). Nonpartisan
-- (partisan_type 'nonpartisan' on the office; primary_party NULL on the race). Candidates
-- have no prior politician rows → politician_id NULL.
--
-- SOURCE: Indiana Secretary of State Election Division certified school-board list (via The
-- Indiana Citizen, 2026-08-12); method + seats cross-checked vs B Square Bulletin and Indiana
-- Public Media. Retrieved 2026-09-21.
--
-- IDEMPOTENCY: offices guard on (district_id, title); races on (election_id, position_name);
-- candidates on (race_id, lower(full_name)).

BEGIN;

-- ─── Offices (seats) ────────────────────────────────────────────────────────────────────
CREATE TEMP TABLE sb_office_seed (title text, district_id uuid, chamber_id uuid) ON COMMIT DROP;
INSERT INTO sb_office_seed VALUES
  ('Monroe County Community School Board - District 1', '9bdc2b0f-6e27-4480-854b-be820d99013a', '04237619-4003-476d-8975-b78b5ddfc5d0'),
  ('Monroe County Community School Board - District 3', '9bdc2b0f-6e27-4480-854b-be820d99013a', '78d7c53f-8648-49da-a626-2d3692ab2479'),
  ('Monroe County Community School Board - District 7', '9bdc2b0f-6e27-4480-854b-be820d99013a', '8b5973bb-7f0c-4b3c-a558-692f43a1b046'),
  ('Richland-Bean Blossom School Board - Richland Township',    'a2c00ac4-0e1b-4a91-b670-4d6b3ef09c6e', NULL),
  ('Richland-Bean Blossom School Board - Bean Blossom Township','76d0828f-b78f-417d-9c49-21b129ba05b9', NULL);

INSERT INTO essentials.offices
  (title, district_id, chamber_id, partisan_type, representing_state, seats,
   is_appointed_position, is_vacant, faces_retention_vote)
SELECT s.title, s.district_id, s.chamber_id, 'nonpartisan', 'IN', 1, false, false, false
FROM sb_office_seed s
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o WHERE o.district_id=s.district_id AND o.title=s.title
);

-- ─── Races (position_name = office title; primary_party NULL) ────────────────────────────
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid, o.id, s.title, NULL, 1
FROM sb_office_seed s
JOIN essentials.offices o ON o.district_id=s.district_id AND o.title=s.title
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r
  WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid AND r.position_name=s.title
);

-- ─── Candidates (nonpartisan; new people → politician_id NULL) ───────────────────────────
CREATE TEMP TABLE sb_cand_seed (position_name text, full_name text, first_name text, last_name text, is_incumbent boolean)
  ON COMMIT DROP;
INSERT INTO sb_cand_seed VALUES
  ('Monroe County Community School Board - District 1', 'Erin Wyatt',    'Erin',    'Wyatt',   true),
  ('Monroe County Community School Board - District 3', 'Ashley Pirani', 'Ashley',  'Pirani',  true),
  ('Monroe County Community School Board - District 7', 'Aja Jester',    'Aja',     'Jester',  true),
  ('Richland-Bean Blossom School Board - Richland Township',    'Kelly D. Scholl',  'Kelly',   'Scholl', false),
  ('Richland-Bean Blossom School Board - Richland Township',    'Dennis R. Adams',  'Dennis',  'Adams',  false),
  ('Richland-Bean Blossom School Board - Bean Blossom Township','Christa Curtis',   'Christa', 'Curtis', false);

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, NULL::uuid, cs.full_name, cs.first_name, cs.last_name, cs.is_incumbent, 'active',
       'Indiana Secretary of State Election Division certified school-board list (via The Indiana Citizen, 2026-08-12); at-large method + seats cross-checked vs B Square Bulletin / Indiana Public Media. Retrieved 2026-09-21.'
FROM sb_cand_seed cs
JOIN essentials.races r
  ON r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid AND r.position_name=cs.position_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id=r.id AND lower(rc.full_name)=lower(cs.full_name)
);

-- ─── Post-verify gate ───────────────────────────────────────────────────────────────────
DO $$
DECLARE v_off int; v_races int; v_cands int; v_orphan int; v_party int; v_dup int; v_nogeo int;
BEGIN
  SELECT count(*) INTO v_off
    FROM essentials.offices o JOIN sb_office_seed s ON s.district_id=o.district_id AND s.title=o.title;

  SELECT count(*) INTO v_races
    FROM essentials.races r JOIN sb_office_seed s ON s.title=r.position_name
   WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid;

  SELECT count(*) INTO v_cands
    FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
    JOIN sb_office_seed s ON s.title=r.position_name
   WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid;

  SELECT count(*) INTO v_orphan
    FROM essentials.races r JOIN sb_office_seed s ON s.title=r.position_name
   WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid AND r.office_id IS NULL;

  -- Every seat must sit on a district that has a geofence (whole MCCSC 1800630 / whole RBB 1809480).
  SELECT count(*) INTO v_nogeo
    FROM essentials.races r JOIN sb_office_seed s ON s.title=r.position_name
    JOIN essentials.offices o ON o.id=r.office_id JOIN essentials.districts d ON d.id=o.district_id
   WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb WHERE gb.geo_id=d.geo_id);

  SELECT count(*) INTO v_party
    FROM essentials.races r JOIN sb_office_seed s ON s.title=r.position_name
   WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid AND r.primary_party IS NOT NULL;

  SELECT count(*) INTO v_dup FROM (
    SELECT rc.race_id, lower(rc.full_name) n
      FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
      JOIN sb_office_seed s ON s.title=r.position_name
     WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
     GROUP BY 1,2 HAVING count(*)>1) x;

  IF v_off    <> 5 THEN RAISE EXCEPTION 'school offices: expected 5, got %', v_off; END IF;
  IF v_races  <> 5 THEN RAISE EXCEPTION 'school races: expected 5, got %', v_races; END IF;
  IF v_cands  <> 6 THEN RAISE EXCEPTION 'school candidates: expected 6, got %', v_cands; END IF;
  IF v_orphan <> 0 THEN RAISE EXCEPTION '% race(s) with NULL office_id', v_orphan; END IF;
  IF v_nogeo  <> 0 THEN RAISE EXCEPTION '% race(s) on a district with no geofence', v_nogeo; END IF;
  IF v_party  <> 0 THEN RAISE EXCEPTION '% race(s) carry primary_party', v_party; END IF;
  IF v_dup    <> 0 THEN RAISE EXCEPTION '% duplicate candidate name(s) within a race', v_dup; END IF;
END $$;

COMMIT;
