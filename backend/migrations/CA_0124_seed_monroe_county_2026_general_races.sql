-- CA_0124_seed_monroe_county_2026_general_races.sql
-- Monroe County, Indiana 2026 general: the county row offices a Monroe voter sees on
-- Nov 3, 2026. These existed only on the '2026 Indiana Primary'; the general held none.
--
-- Extends 'IN 2026 Statewide General' (2026-11-03). Indiana keeps every level in one
-- statewide election per type (its primary does the same), so county races live here.
--
-- ADDS 10 RACES / 12 CANDIDATES (reusing the existing, already-geofenced county offices —
-- no office/district creation):
--   Prosecuting Attorney     Erika Oliphant (D, inc) — unopposed
--   Clerk                    Tree Martin Lucas (D), Julie M. Hays (R) — open seat
--   Recorder                 Amy Swain (D, inc) — unopposed
--   Sheriff                  Ruben Marte (D, inc) — unopposed
--   Assessor                 Judith A. Sharp (D, inc), Lisa Jeneé Trimble (Independent)
--   Commissioner District 1  Trent Deckard (D) — open seat, unopposed
--   Council District 1       Peter James Iversen (D, inc) — unopposed
--   Council District 2       Kate Wiltz (D, inc) — unopposed
--   Council District 3       Martha Hawk (R, inc) — unopposed
--   Council District 4       Jennifer Crossley (D, inc) — unopposed
--
-- GENERAL FIELD, NOT PRIMARY FILERS. The primary held filers with no recorded winner;
-- these are the certified November nominees (contested primaries resolved to winners:
-- Clerk D → Lucas, Assessor D → Sharp, Prosecutor D → Oliphant, Commissioner D → Deckard).
-- Independents/write-ins that skip the primary are handled: Trimble (I) filed by petition
-- for Assessor and IS added; Joe Davis (lost the Clerk D primary, write-in bid blocked
-- under the sore-loser law) is NOT on the printed ballot and is EXCLUDED. Republicans
-- filed only for Clerk (Hays) and Council D3 (Hawk); the other Democratic winners are
-- effectively unopposed — that is the ballot, not a truncated import.
--
-- OFFICES REUSED (already geofenced): countywide offices sit on geo_id '18105'; the four
-- County Council districts on '18105-mcc-d1..d4'. Party never stored (antipartisan;
-- primary_party NULL on a general race). Candidates link to the SAME politician rows the
-- primary filers already carried (reused link for the same person, not a name match); the
-- petition independent Trimble has no prior record → politician_id NULL.
--
-- Also corrects a name typo on one politician: 'Matha Hawk' → 'Martha Hawk'.
--
-- SOURCE: Ballotpedia "Monroe County, Indiana, elections, 2026" cross-checked against
-- B Square Bulletin / Indiana Daily Student / WFHB (May-5 primary results + general
-- filings). The county filing page was offline; re-verify vs the state-certified list.
-- Retrieved 2026-09-21.
--
-- IDEMPOTENCY: races guard on (election_id, position_name); candidates on
-- (race_id, lower(full_name)); the typo fix is guarded on the old value.

BEGIN;

-- ─── Name-typo correction ──────────────────────────────────────────────────────────────
UPDATE essentials.politicians SET full_name='Martha Hawk'
 WHERE id='6972209b-13b7-4595-b7f1-8f6df06de1e9'::uuid AND full_name='Matha Hawk';

-- ─── Races (reuse existing offices by id; primary_party NULL: general) ──────────────────
CREATE TEMP TABLE mon_race_seed (position_name text, office_id uuid) ON COMMIT DROP;
INSERT INTO mon_race_seed VALUES
  ('Monroe County Prosecuting Attorney',    'c8b096f2-9e0b-4e34-b4cf-8f828d04bb33'),
  ('Monroe County Clerk',                   'b82f753c-27a1-4353-a0cb-53b5b249a901'),
  ('Monroe County Recorder',                '60e8610a-89c2-46c9-9b8e-b0841fa77842'),
  ('Monroe County Sheriff',                 '0cad79dc-c277-45bf-9e6b-1cc37be0c51f'),
  ('Monroe County Assessor',                '0a75b673-57db-48f7-b358-9d0c7d4c1bc3'),
  ('Monroe County Commissioner District 1', '361f3973-27f0-4fb5-9955-cfca6b54d526'),
  ('Monroe County Council District 1',      '89227923-28e3-4808-bf2a-d1fe3bb87d97'),
  ('Monroe County Council District 2',      '7aab5c7f-e76e-4b0a-8762-d4c3c66227b7'),
  ('Monroe County Council District 3',      'baddfa3d-b890-4f27-b224-0a87db91173e'),
  ('Monroe County Council District 4',      '1c986210-78ab-4c68-a3ba-4264fc7b7250');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid, s.office_id, s.position_name, NULL, 1
FROM mon_race_seed s
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r
  WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid AND r.position_name=s.position_name
);

-- ─── Candidates (certified Nov field; link to existing politician rows) ─────────────────
CREATE TEMP TABLE mon_cand_seed
  (position_name text, full_name text, first_name text, last_name text,
   is_incumbent boolean, politician_id uuid) ON COMMIT DROP;
INSERT INTO mon_cand_seed VALUES
  ('Monroe County Prosecuting Attorney',    'Erika Oliphant',      'Erika',  'Oliphant',  true,  'ed914571-dd22-4ab5-b764-92a1a465e980'::uuid),
  ('Monroe County Clerk',                   'Tree Martin Lucas',   'Tree',   'Lucas',     false, 'ba1e0001-2026-4000-8000-000000000010'::uuid),
  ('Monroe County Clerk',                   'Julie M. Hays',       'Julie',  'Hays',      false, 'ba1e0001-2026-4000-8000-000000000008'::uuid),
  ('Monroe County Recorder',                'Amy Swain',           'Amy',    'Swain',     true,  'fa4cbcff-06c5-4f31-a034-0c9b4b268868'::uuid),
  ('Monroe County Sheriff',                 'Ruben Marte',         'Ruben',  'Marte',     true,  'b8d4f904-23c8-4baa-8426-fbc44aafdf88'::uuid),
  ('Monroe County Assessor',                'Judith A. Sharp',     'Judith', 'Sharp',     true,  'ba1e0001-2026-4000-8000-000000000013'::uuid),
  ('Monroe County Assessor',                'Lisa Jeneé Trimble',  'Lisa',   'Trimble',   false, NULL::uuid),
  ('Monroe County Commissioner District 1', 'Trent Deckard',       'Trent',  'Deckard',   false, 'db4e6911-9dbb-430e-831c-08be094fd637'::uuid),
  ('Monroe County Council District 1',      'Peter James Iversen', 'Peter',  'Iversen',   true,  '10c70231-d5a0-48c3-ac29-1480b2eaa6db'::uuid),
  ('Monroe County Council District 2',      'Kate Wiltz',          'Kate',   'Wiltz',     true,  '73855d5c-f1f3-4701-90af-997d26fbe0df'::uuid),
  ('Monroe County Council District 3',      'Martha Hawk',         'Martha', 'Hawk',      true,  '6972209b-13b7-4595-b7f1-8f6df06de1e9'::uuid),
  ('Monroe County Council District 4',      'Jennifer Crossley',   'Jennifer','Crossley', true,  '30753c4d-e145-417f-8448-c2192e010a14'::uuid);

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, cs.politician_id, cs.full_name, cs.first_name, cs.last_name, cs.is_incumbent, 'active',
       'Ballotpedia "Monroe County, Indiana, elections, 2026" cross-checked vs B Square Bulletin / Indiana Daily Student / WFHB (May-5 primary results + general filings). Retrieved 2026-09-21.'
FROM mon_cand_seed cs
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
     AND r.position_name LIKE 'Monroe County%';

  SELECT count(*) INTO v_cands FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id=rc.race_id
   WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
     AND r.position_name LIKE 'Monroe County%';

  -- 🔴 Every race must resolve to a district or it is invisible to address lookup.
  SELECT count(*) INTO v_orphan FROM essentials.races r
   WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
     AND r.position_name LIKE 'Monroe County%' AND r.office_id IS NULL;

  -- Every reused office must sit on a geofenced Monroe district (countywide or a council district).
  SELECT count(*) INTO v_geo FROM essentials.races r
    JOIN essentials.offices o ON o.id=r.office_id
    JOIN essentials.districts d ON d.id=o.district_id
   WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
     AND r.position_name LIKE 'Monroe County%'
     AND d.geo_id NOT IN ('18105','18105-mcc-d1','18105-mcc-d2','18105-mcc-d3','18105-mcc-d4');

  SELECT count(*) INTO v_party FROM essentials.races r
   WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
     AND r.position_name LIKE 'Monroe County%' AND r.primary_party IS NOT NULL;

  SELECT count(*) INTO v_dup FROM (
    SELECT rc.race_id, lower(rc.full_name) n FROM essentials.race_candidates rc
      JOIN essentials.races r ON r.id=rc.race_id
     WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
       AND r.position_name LIKE 'Monroe County%'
     GROUP BY 1,2 HAVING count(*)>1) x;

  IF v_races  <> 10 THEN RAISE EXCEPTION 'Monroe county races: expected 10, got %', v_races; END IF;
  IF v_cands  <> 12 THEN RAISE EXCEPTION 'Monroe county candidates: expected 12, got %', v_cands; END IF;
  IF v_orphan <> 0  THEN RAISE EXCEPTION '% race(s) with NULL office_id', v_orphan; END IF;
  IF v_geo    <> 0  THEN RAISE EXCEPTION '% race(s) on a non-geofenced Monroe district', v_geo; END IF;
  IF v_party  <> 0  THEN RAISE EXCEPTION '% general race(s) carry primary_party', v_party; END IF;
  IF v_dup    <> 0  THEN RAISE EXCEPTION '% duplicate candidate name(s) within a race', v_dup; END IF;
END $$;

COMMIT;
