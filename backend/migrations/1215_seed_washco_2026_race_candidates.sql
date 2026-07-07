-- Migration 1215: Seed confirmed Nov 3 2026 west-metro candidate slate (race_candidates + new politicians)
--
-- Phase 185-02 (v20.0 WashCo 2026 Elections & Discovery, Plan 02). Wires the confirmed candidate field
-- onto the 25 west-metro OR 2026 General races authored in migration 1213.
--
-- NUMBERING: Plan 01 recorded BASE=1213 (races). The shared live counter drifted (a parallel IN 2026
--   House workstream took 1213/1214 as well — 1213 collides cosmetically, 1214_seed_in_2026_house_candidates).
--   Live max at write time = 1214, so this candidates migration is 1215 (live_max+1). Discovery = 1216.
--
-- 8 candidate-bearing races (the only races with an independently-confirmed, citable Nov-2026 slate as of
--   2026-07-04; the other 17 west-metro races correctly ship with 0 race_candidates — filing periods for
--   Hillsboro/Tigard/Forest Grove/Sherwood/Tualatin Pos1&3 have not opened/closed and NO name is citable.
--   Never fabricate a name — RESEARCH Pitfall 3 / T-185-02). Re-fetch 2026-07-04 reconfirmed: Forest Grove
--   "filing not yet opened"; Sherwood open (June 3) but no published slate; Tigard bot-blocked/no names.
--
--   Washington County Chair (runoff)  : Nafisa Fai (REUSE -410110), Pam Treece (REUSE -410111)
--   Washington County Commissioner D4  : Steve Callaway (NEW -4850001), Kipperlyn Sinclair (REUSE -4134104)
--   Beaverton City Council Position 1  : Rachel Philip (NEW -4850002), Evelyn Kocher (NEW -4850003)
--   Tualatin Mayor                     : Octavio Gonzalez (REUSE -4174956), Valerie Pratt (REUSE -4174957)
--   Tualatin City Council Position 5   : Beth Dittman (NEW -4850004)
--   Cornelius Mayor                    : Jeffrey C. Dalin (REUSE -4115551, incumbent, unopposed)
--   Cornelius City Council Seat A      : Edgar Baker (REUSE -4115553, incumbent)
--   Cornelius City Council Seat B      : Edén López (REUSE -4115554, incumbent)
--
-- REUSE discipline (D-185-03): the 8 already-seeded people (Fai/Treece Ph175, Sinclair Ph177,
--   Gonzalez/Pratt Ph179, Dalin/Baker/López Ph182) point to their EXISTING politician_id via external_id
--   lookup — NO new duplicate politician row. Only 4 genuinely-new challengers get new politician rows
--   (band -4850001..-4850099 verified empty live 2026-07-04).
--
-- is_incumbent = true ONLY for a sitting officeholder defending their OWN seat: Dalin/Baker/López
--   (Cornelius, keeping their seats). Fai/Treece (moving from D1/D2 to Chair), Sinclair (Hillsboro->county),
--   Gonzalez/Pratt (Pos5/Pos6 -> Mayor) are running for a DIFFERENT seat -> is_incumbent=false.
--
-- ANTIPARTISAN: race_candidates has NO party column (schema-enforced). No party value anywhere.
-- Every row carries a mandatory real source URL (the jurisdiction's official election page).
-- race_id resolved by the unique position_name authored in 1213 (election-scoped, unambiguous).
--
-- Idempotent: NOT EXISTS on (external_id) for politicians; NOT EXISTS on (race_id, full_name) for
--   race_candidates (no DB unique constraint there). ON CONFLICT (external_id) DO NOTHING is ALSO valid on
--   politicians but NOT EXISTS is used for symmetry. A re-run inserts 0 rows.
-- No schema_migrations ledger INSERT (data-seed, 1110 family).

BEGIN;

-- 1. Insert the 4 genuinely-new west-metro challengers.
INSERT INTO essentials.politicians (id, external_id, full_name, first_name, last_name, is_active)
SELECT gen_random_uuid(), v.ext, v.full_name, v.first_name, v.last_name, true
FROM (VALUES
  (-4850001, 'Steve Callaway',  'Steve',  'Callaway'),   -- WashCo D4 (former Hillsboro Mayor)
  (-4850002, 'Rachel Philip',   'Rachel', 'Philip'),      -- Beaverton Position 1
  (-4850003, 'Evelyn Kocher',   'Evelyn', 'Kocher'),      -- Beaverton Position 1
  (-4850004, 'Beth Dittman',    'Beth',   'Dittman')      -- Tualatin Position 5
) v(ext, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.ext);

-- 2. Insert the 12 race_candidates onto the 8 candidate-bearing races.
--    race_id resolved by unique position_name; politician_id by external_id (reuse and new alike).
INSERT INTO essentials.race_candidates
  (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT gen_random_uuid(),
       (SELECT r.id FROM essentials.races r
          JOIN essentials.elections el ON el.id = r.election_id
         WHERE el.name = 'OR 2026 General' AND el.state ILIKE 'or' AND r.position_name = v.pos),
       (SELECT p.id FROM essentials.politicians p WHERE p.external_id = v.ext),
       v.full_name, v.first_name, v.last_name, v.is_incumbent, 'active', v.source
FROM (VALUES
  -- Washington County Chair (runoff)
  ('Washington County Chair',                 -410110,  'Nafisa Fai',        'Nafisa',  'Fai',       false, 'https://www.washingtoncountyor.gov/elections'),
  ('Washington County Chair',                 -410111,  'Pam Treece',        'Pam',     'Treece',    false, 'https://www.washingtoncountyor.gov/elections'),
  -- Washington County Commissioner District 4 (runoff)
  ('Washington County Commissioner District 4', -4850001, 'Steve Callaway',    'Steve',   'Callaway',  false, 'https://www.washingtoncountyor.gov/elections'),
  ('Washington County Commissioner District 4', -4134104, 'Kipperlyn Sinclair','Kipperlyn','Sinclair', false, 'https://www.washingtoncountyor.gov/elections'),
  -- Beaverton City Council Position 1 (runoff)
  ('Beaverton City Council Position 1',       -4850002, 'Rachel Philip',     'Rachel',  'Philip',    false, 'https://beavertonoregon.gov/944/Elections'),
  ('Beaverton City Council Position 1',       -4850003, 'Evelyn Kocher',     'Evelyn',  'Kocher',    false, 'https://beavertonoregon.gov/944/Elections'),
  -- Tualatin Mayor (open)
  ('Tualatin Mayor',                          -4174956, 'Octavio Gonzalez',  'Octavio', 'Gonzalez',  false, 'https://tualatinoregon.gov/city-council/elections/'),
  ('Tualatin Mayor',                          -4174957, 'Valerie Pratt',     'Valerie', 'Pratt',     false, 'https://tualatinoregon.gov/city-council/elections/'),
  -- Tualatin City Council Position 5 (open)
  ('Tualatin City Council Position 5',        -4850004, 'Beth Dittman',      'Beth',    'Dittman',   false, 'https://tualatinoregon.gov/city-council/elections/'),
  -- Cornelius (incumbents defending own seats)
  ('Cornelius Mayor',                         -4115551, 'Jeffrey C. Dalin',  'Jeffrey', 'Dalin',     true,  'https://www.corneliusor.gov/385/Elections-2024'),
  ('Cornelius City Council Seat A',           -4115553, 'Edgar Baker',       'Edgar',   'Baker',     true,  'https://www.corneliusor.gov/385/Elections-2024'),
  ('Cornelius City Council Seat B',           -4115554, 'Edén López',        'Edén',    'López',     true,  'https://www.corneliusor.gov/385/Elections-2024')
) v(pos, ext, full_name, first_name, last_name, is_incumbent, source)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  JOIN essentials.races r ON r.id = rc.race_id
  JOIN essentials.elections el ON el.id = r.election_id
  WHERE el.name = 'OR 2026 General' AND el.state ILIKE 'or'
    AND r.position_name = v.pos AND rc.full_name = v.full_name
);

-- 3. Post-write assertions — abort on any invariant failure. Scoped to west-metro OR 2026 races.
DO $$
DECLARE
  or_eid    uuid;
  v_active  int;
  v_nullpid int;
  v_dup     int;
  v_nosrc   int;
  v_newpols int;
  v_sinclair int;
BEGIN
  SELECT id INTO or_eid FROM essentials.elections WHERE name='OR 2026 General' AND state ILIKE 'or';

  SELECT count(*) FILTER (WHERE rc.candidate_status='active'),
         count(*) FILTER (WHERE rc.candidate_status='active' AND rc.politician_id IS NULL),
         count(*) FILTER (WHERE rc.candidate_status='active' AND (rc.source IS NULL OR rc.source=''))
    INTO v_active, v_nullpid, v_nosrc
  FROM essentials.race_candidates rc
  JOIN essentials.races r ON r.id = rc.race_id
  JOIN essentials.offices o ON o.id = r.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE r.election_id = or_eid
    AND d.geo_id IN ('41067','washco-or-commissioner-district-4','4105350','4134100',
                     '4173650','4174950','4126200','4167100','4115550');
  IF v_active <> 12 THEN RAISE EXCEPTION 'FAIL: expected 12 active west-metro race_candidates, got %', v_active; END IF;
  IF v_nullpid <> 0 THEN RAISE EXCEPTION 'FAIL: % active rows with NULL politician_id', v_nullpid; END IF;
  IF v_nosrc <> 0 THEN RAISE EXCEPTION 'FAIL: % active rows with empty source (citation mandatory)', v_nosrc; END IF;

  SELECT count(*) INTO v_dup FROM (
    SELECT rc.race_id, lower(rc.full_name)
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    WHERE r.election_id = or_eid AND rc.candidate_status='active'
    GROUP BY rc.race_id, lower(rc.full_name) HAVING count(*) > 1) q;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'FAIL: % duplicate full_name within a race', v_dup; END IF;

  -- Only the 4 intended new challengers exist in the band (no accidental dup for a reuse candidate).
  SELECT count(*) INTO v_newpols FROM essentials.politicians
   WHERE external_id BETWEEN -4850099 AND -4850001;
  IF v_newpols <> 4 THEN RAISE EXCEPTION 'FAIL: expected 4 new challenger politicians in band, got %', v_newpols; END IF;

  -- Sinclair reuses her existing Hillsboro row (no new duplicate created for her).
  SELECT count(*) INTO v_sinclair FROM essentials.politicians WHERE full_name='Kipperlyn Sinclair';
  IF v_sinclair <> 1 THEN RAISE EXCEPTION 'FAIL: Kipperlyn Sinclair should have exactly 1 politician row, got %', v_sinclair; END IF;

  RAISE NOTICE 'OK: 12 active west-metro race_candidates, 0 NULL pid, 0 dup, 0 empty source, 4 new challengers, Sinclair not duplicated';
END $$;

COMMIT;
