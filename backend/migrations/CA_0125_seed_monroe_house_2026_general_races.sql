-- CA_0125_seed_monroe_house_2026_general_races.sql
-- Indiana House districts covering Monroe County, 2026 general (Nov 3, 2026).
-- Districts 60/61/62 existed only on the '2026 Indiana Primary'; District 46 was absent
-- from both the primary and the general even though it covers ~17% of Monroe County
-- (Ellettsville / western county). The general held no state-house races at all.
--
-- Extends 'IN 2026 Statewide General'. Reuses the existing, geofenced STATE_LOWER offices
-- (geo_id 18046/18060/18061/18062, mtfcc G5220) — HD-46's office already exists, it just
-- never had a race. No office/district creation.
--
-- The four districts covering Monroe were confirmed by geofence area (18062 ~61%, 18046
-- ~17%, 18060 ~17%, 18061 ~5%). Districts 45 and 65 touch the county boundary at 0.00%
-- (edge slivers) and are excluded.
--
-- ADDS 4 RACES / 7 CANDIDATES (certified general field):
--   District 46   Bob Heaton (R, inc), James H. Pittsford III (D)
--   District 60   Peggy Mayfield (R, inc), Carrie L. Syczylo (D)
--   District 61   Matt Pierce (D, inc) — UNOPPOSED (no Republican filed)
--   District 62   Dave Hall (R, inc), Amy Huffman Oliver (D)
--
-- INCUMBENCY is taken from the certified/cross-checked sources, NOT the DB's primary
-- is_incumbent flags, which were wrong for 60 and 62 (redistricting artifacts): Mayfield
-- (not Waters) holds 60; Hall (not Oliver) holds 62. Pierce won the contested D-61 primary
-- over Lilliana Young and is unopposed in November. No Libertarian/independent filed in
-- any of the four.
--
-- Party never stored (antipartisan; primary_party NULL on a general race). Six of seven
-- candidates link to their existing politician rows (Heaton via the HD-46 office holder;
-- the 60/61/62 nominees via their primary filer rows). Pittsford (D-46) had no prior
-- record (HD-46 was never seeded) → politician_id NULL.
--
-- SOURCE: The Indiana Citizen 2026 general candidate list (mirrors IN Election Division
-- filings), cross-checked vs Ballotpedia + local news (IDS, Daily Journal, Brown County
-- Democrat) for primary winners. The SoS raw xlsx link was 404 at retrieval. 2026-09-21.
--
-- IDEMPOTENCY: races guard on (election_id, position_name); candidates on
-- (race_id, lower(full_name)).

BEGIN;

-- ─── Races (reuse existing STATE_LOWER offices by id; primary_party NULL) ───────────────
CREATE TEMP TABLE hse_race_seed (position_name text, office_id uuid) ON COMMIT DROP;
INSERT INTO hse_race_seed VALUES
  ('State Representative, District 046', '445584b2-cff8-4040-941f-9c6df1e53037'),
  ('State Representative, District 060', '4e827459-027f-4998-b86d-c01355c44ed8'),
  ('State Representative, District 061', '7b3f68ef-bd9b-4316-9e39-89091b6e9aa1'),
  ('State Representative, District 062', '847135b4-5bd6-46e2-87e4-41bd792097bd');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid, s.office_id, s.position_name, NULL, 1
FROM hse_race_seed s
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r
  WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid AND r.position_name=s.position_name
);

-- ─── Candidates (certified Nov field; incumbency from cross-checked sources) ────────────
CREATE TEMP TABLE hse_cand_seed
  (position_name text, full_name text, first_name text, last_name text,
   is_incumbent boolean, politician_id uuid) ON COMMIT DROP;
INSERT INTO hse_cand_seed VALUES
  ('State Representative, District 046', 'Bob Heaton',              'Bob',    'Heaton',    true,  '77261f08-6172-4a58-a5d6-446c2b84a50e'::uuid),
  ('State Representative, District 046', 'James H. Pittsford III',  'James',  'Pittsford', false, NULL::uuid),
  ('State Representative, District 060', 'Peggy Mayfield',          'Peggy',  'Mayfield',  true,  'f84421ea-eb49-44c3-a6a7-a3cfaf5dc745'::uuid),
  ('State Representative, District 060', 'Carrie L. Syczylo',       'Carrie', 'Syczylo',   false, '35392708-1b50-48e0-a62d-b09c61a25192'::uuid),
  ('State Representative, District 061', 'Matt Pierce',             'Matt',   'Pierce',    true,  '72dd5219-490f-48bb-986e-183a6098d602'::uuid),
  ('State Representative, District 062', 'Dave Hall',               'Dave',   'Hall',      true,  'e971c7f2-3ab2-483d-97a4-7fe919365f98'::uuid),
  ('State Representative, District 062', 'Amy Huffman Oliver',      'Amy',    'Oliver',    false, 'a6926086-aa11-4f42-bcd7-bf74c1e1a540'::uuid);

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, cs.politician_id, cs.full_name, cs.first_name, cs.last_name, cs.is_incumbent, 'active',
       'The Indiana Citizen 2026 general candidate list (mirrors IN Election Division filings), cross-checked vs Ballotpedia + local news (IDS/Daily Journal/Brown County Democrat) for primary winners. Retrieved 2026-09-21.'
FROM hse_cand_seed cs
JOIN essentials.races r
  ON r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid AND r.position_name=cs.position_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id=r.id AND lower(rc.full_name)=lower(cs.full_name)
);

-- ─── Post-verify gate ───────────────────────────────────────────────────────────────────
DO $$
DECLARE v_races int; v_cands int; v_orphan int; v_party int; v_dup int; v_geo int;
BEGIN
  SELECT count(*) INTO v_races FROM essentials.races r
   WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
     AND r.position_name IN ('State Representative, District 046','State Representative, District 060',
                             'State Representative, District 061','State Representative, District 062');

  SELECT count(*) INTO v_cands FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
   WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
     AND r.position_name IN ('State Representative, District 046','State Representative, District 060',
                             'State Representative, District 061','State Representative, District 062');

  -- 🔴 No NULL office_id (invisible to address lookup); all offices must be geofenced Monroe House districts.
  SELECT count(*) INTO v_orphan FROM essentials.races r
   WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
     AND r.position_name LIKE 'State Representative, District 0%' AND r.office_id IS NULL;

  SELECT count(*) INTO v_geo FROM essentials.races r
    JOIN essentials.offices o ON o.id=r.office_id JOIN essentials.districts d ON d.id=o.district_id
   WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
     AND r.position_name IN ('State Representative, District 046','State Representative, District 060',
                             'State Representative, District 061','State Representative, District 062')
     AND d.geo_id NOT IN ('18046','18060','18061','18062');

  SELECT count(*) INTO v_party FROM essentials.races r
   WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
     AND r.position_name IN ('State Representative, District 046','State Representative, District 060',
                             'State Representative, District 061','State Representative, District 062')
     AND r.primary_party IS NOT NULL;

  SELECT count(*) INTO v_dup FROM (
    SELECT rc.race_id, lower(rc.full_name) n FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
     WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
       AND r.position_name LIKE 'State Representative, District 0%'
     GROUP BY 1,2 HAVING count(*)>1) x;

  IF v_races  <> 4 THEN RAISE EXCEPTION 'House races: expected 4, got %', v_races; END IF;
  IF v_cands  <> 7 THEN RAISE EXCEPTION 'House candidates: expected 7, got %', v_cands; END IF;
  IF v_orphan <> 0 THEN RAISE EXCEPTION '% race(s) with NULL office_id', v_orphan; END IF;
  IF v_geo    <> 0 THEN RAISE EXCEPTION '% race(s) on a non-Monroe House district', v_geo; END IF;
  IF v_party  <> 0 THEN RAISE EXCEPTION '% general race(s) carry primary_party', v_party; END IF;
  IF v_dup    <> 0 THEN RAISE EXCEPTION '% duplicate candidate name(s) within a race', v_dup; END IF;
END $$;

COMMIT;
