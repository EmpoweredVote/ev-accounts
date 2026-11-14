-- CC_0426: Wood Village, Oregon -- two of the five council offices were titled by the ROLE their
--          holder happens to carry, not by the SEAT they occupy. Retitle both, and retire the
--          executive district the mayoral one sat on, because this city elects no executive.
--
-- CC_0425 seeded this city's two 2026-11-03 ballots and said, in its own follow-ups, that this was
-- left open deliberately: folding an occupancy-labelling edit into a ballot seed would have mixed
-- two unrelated acts. This is that pass. It touches no race and no `office_terms` row.
--
-- === WHAT THE CITY SAYS (sources committed under backend/data/local-races-2026-audit/sources/) ===
-- Charter, current as amended 2015-05-19 -- or-wood-village-charter-2026-11-14.txt:
--   Section 8.  "The council shall be composed of five councilors elected from the city at large."
--   Section 9.  "Councilors shall be elected at the biennial general election for a term of office
--                of four years."
--   Section 10. "The council, from its members shall elect a mayor at the first meeting of the
--                council in each odd numbered year for a term of two years."
-- Council roster at woodvillageor.gov, retrieved 2026-11-14 -- or-wood-village-council-roster-...txt:
--   Jairo Rios-Campos  Mayor              term ends 12/31/2028
--   Dara Tan           Council President  term ends 12/31/2028
--   John Miner                            term ends 12/31/2026
--   Charlene Gothard                      term ends 12/31/2026
--   Patricia Smith                        term ends 12/31/2028
--
-- Five people, five offices, and the count was never wrong. Only two of the five labels were, and
-- they are the two the city's own page decorates with a role.
--
-- === THE RULE THIS APPLIES IS ALREADY IN THE REPO ===
-- `backend/data/seed-me-municipal-2026/ROSTERS.md` R5/R9, applied by CC_0292 across six Maine
-- cities: a rotating chair is a parenthetical on a seat, NEVER its own office, and the test is the
-- sentence that says who ELECTS the presiding officer. Section 10 says the council does, from its
-- own members -- the same shape as Caribou's charter and the opposite of Calais', where the voters
-- elect the mayor and the office is real. CC_0292's fix was "Mayor -> At-Large 7"; this is the
-- same retitle.
--
-- 🟢 WOOD VILLAGE IS THE EASY HALF OF THAT SHAPE, AND THAT IS WHY IT SURVIVED. In all six Maine
--    cities the phantom office ATE a seat, so the council came out one short and the shortfall
--    looked like an ordinary vacancy -- a countable defect. Here the phantom office IS the fifth
--    seat: five offices, five councilors, nothing missing, nothing to count. ▶ A labelling defect
--    with no arithmetic consequence is invisible to every gate in this repo. The only thing that
--    finds one is reading the body's own charter against its own roster.
--
-- === WHAT WAS WRONG, AND WHY EACH PART IS NOT COSMETIC ===
--
-- 1. `Council President` (office 4897db37-5c80-4bd9-8057-026f3cc622a3, held by Dara Tan).
--    A title only. The office already sits on the council's own district with the other three.
--
-- 2. `Mayor` (office eed3e9b8-3193-48d7-88b2-7c5f1473aff0, held by Jairo Rios-Campos) is three
--    separate assertions, and renaming it alone would have left the other two standing:
--
--    a. the TITLE says the city elects a mayor;
--    b. `is_appointed_position = true` -- and the API derives a voter-facing field straight from
--       it: `is_elected: !row.is_appointed_position` (essentialsService.ts, and seven more mappers
--       in essentialsBrowseService.ts). So today this council seat is published as NOT ELECTED,
--       against Section 9, which elects every councilor at the biennial general election. Retitling
--       without clearing the flag would publish "City Councilor, not elected", which is worse than
--       what is there now: at least `Mayor` + appointed is internally consistent, as a description
--       of a city that does not exist;
--    c. it sits alone on a SECOND district -- `Wood Village (Citywide)`, district_type
--       `LOCAL_EXEC` -- while the other four sit on `Wood Village (At-Large)`, `LOCAL`.
--       `LOCAL_EXEC` is not decoration: it is how this repo says "this row is the municipality's
--       executive" (audit-district-urls.mjs states it outright -- "a municipality holds its council
--       seats as N `LOCAL` rows and its executive as a `LOCAL_EXEC` row"), and
--       electionGrouping.ts types a mayoral race into it. Measured: 266 LOCAL_EXEC districts carry
--       309 offices, 228 of them mayor-titled. The type is doing real work everywhere else, so
--       leaving a councilor on it is the same false claim wearing a schema's clothes.
--
-- ⚠ ADDRESS SEARCH DOES NOT CHANGE, AND THAT IS NOT A REASON TO SKIP ANY OF IT. districtQueries.ts
--   admits `LOCAL` and `LOCAL_EXEC` through the same geofence arm, and both rows carry the same
--   geo_id, so a Wood Village address already returns all five seats and still will. The defect is
--   in what the five rows SAY, not in whether a voter reaches them.
--
-- === 🔴 VALUES OVERWRITTEN -- THERE IS NO HISTORY TABLE FOR ANY OF THESE ===
--
--   offices eed3e9b8-3193-48d7-88b2-7c5f1473aff0
--     title                  'Mayor'                                -> 'City Councilor'
--     is_appointed_position  true                                   -> false
--     district_id            74cc6acb-511f-4808-a318-066dd8b620bd   -> 98ce622b-d560-4090-9db6-5b4b92d3cbe5
--   offices 4897db37-5c80-4bd9-8057-026f3cc622a3
--     title                  'Council President'                    -> 'City Councilor'
--   chambers 4f37f2d0-f4b3-4106-8659-3870b0378d98  (Wood Village City Council)
--     official_count         NULL                                   -> 5          (Charter Section 8)
--
--   DELETED ROW, essentials.districts 74cc6acb-511f-4808-a318-066dd8b620bd, in full:
--     label 'Wood Village (Citywide)' · district_type 'LOCAL_EXEC' · state 'or' ·
--     geo_id '4183950' · ocd_id 'ocd-division/country:us/state:or/place:wood_village' ·
--     population 4717 · population_source_year 2023 · census_unit_id '173686' ·
--     official_web_url 'https://www.woodvillageor.gov/' · representation_basis 'residency' ·
--     mtfcc, city, subtype, valid_from, valid_to, retention, district_id, external_id,
--     is_judicial, tiger_geoid, government_id, num_officials, last_update_date,
--     has_unknown_boundaries all NULL.
--
-- 🟢 THE DELETE LOSES NOTHING, AND THAT IS MEASURED, NOT ASSUMED. The surviving row
--    98ce622b-d560-4090-9db6-5b4b92d3cbe5 is byte-identical to the deleted one in EVERY column
--    except `id`, `label` and `district_type` -- same geo_id, same ocd_id, same population and
--    source year, same census_unit_id, same official_web_url, same state, same
--    representation_basis. A gate below asserts that while both rows still exist, so the claim is
--    checked against prod rather than recorded on trust.
--
-- 🔴 REPOINT BEFORE DELETING. `essentials.districts` has NO inbound foreign key (CLAUDE.md), so
--    deleting a district that still carries an office orphans it in silence -- no error, and the
--    office simply stops resolving. The office is moved first and the delete REFUSES unless the row
--    is already empty. Nothing else points at it: measured, zero races (races hang off offices, not
--    districts), zero `inform.politicians.district_id` rows, and no FK anywhere in any schema.
--
-- 🔴 AND THE EMPTY DISTRICT COULD NOT JUST BE LEFT. `check-address-reachability.mjs` is a
--    MASTER-ONLY gate, so it fails on the NEXT PR and names an innocent author. Oregon is clean
--    today -- `address-reachability-baseline.json` carries no `or|` bucket of ANY kind -- and the
--    gate fires on any NEW bucket. Measured against all 32 Oregon LOCAL/LOCAL_EXEC districts:
--    0 office-less, 0 of the DEAD_GEOGRAPHY shape. Both are re-asserted below, which is CLAUDE.md's
--    rule for a master-only check: carry it into the migration that could trip it.
--    (DEAD_GEOGRAPHY itself requires `offices > 0`, so an emptied district would have slipped past
--    that one specifically -- and left a polygon-backed row resolving nobody for the next session
--    to seat something into by mistake.)
--
-- === DELIBERATELY NOT DONE ===
-- * The two roles are NOT recorded in the schema. There is no column for a rotating chair and
--   inventing one here would be a convention set by a one-city migration. CC_0292 did the same --
--   Caribou's Deputy Mayor and Bath's Chairperson live in that wave's ROSTERS.md, not in a column.
--   Who is mayor and who is president is written up in local-races-2026-audit/NOTES.md.
-- * The five seats are NOT numbered. The city numbers its own -- CC_0425 established Position 1 as
--   Gothard's and Position 4 as Miner's FROM THE BALLOT -- but the 2024 ballot is what maps the
--   other three, and guessing which of Rios-Campos, Tan and Smith holds 2, 3 or 5 would assert a
--   fact about a named person that no source states. All five keep the untitled `City Councilor`
--   the other three already carried.
-- * 🔴 TWO MAINE OFFICES CARRY THIS EXACT RESIDUE AND ARE NOT FIXED HERE. CC_0292 retitled six
--   phantom mayors and cleared no flags, so Presque Isle `Council Member (At-Large 7)` (Debra
--   Plummer) and Rockland `Council Member (At-Large 5)` (Adam Lachman) still read
--   `is_appointed_position = true` and still publish as not elected. Measured 2026-11-13, in prod.
--   Maine is a closed wave with its own notes; this is written up as a follow-up rather than
--   reached into from an Oregon migration.

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 0. Pin the rows by WHO HOLDS THEM, not by what they are called.
--    The titles are the thing being changed, so matching on them would make this check pass
--    vacuously on a re-run and would not prove the UUIDs are the right ones in the first place.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n integer;
BEGIN
  SELECT count(*) INTO v_n
    FROM essentials.offices o
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE (o.id = 'eed3e9b8-3193-48d7-88b2-7c5f1473aff0' AND p.full_name = 'Jairo Rios-Campos')
      OR (o.id = '4897db37-5c80-4bd9-8057-026f3cc622a3' AND p.full_name = 'Dara Tan');
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'CC_0426: expected the two offices to be held by Rios-Campos and Tan; matched % of 2.', v_n;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE c.id = '4f37f2d0-f4b3-4106-8659-3870b0378d98'
       AND c.name_formal = 'Wood Village City Council'
       AND g.name = 'City of Wood Village, Oregon, US'
  ) THEN RAISE EXCEPTION 'CC_0426: chamber 4f37f2d0 is not the Wood Village City Council.'; END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 1. Dara Tan's seat. Council President is a role the council confers, not a seat voters fill.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
UPDATE essentials.offices
   SET title = 'City Councilor'
 WHERE id = '4897db37-5c80-4bd9-8057-026f3cc622a3';

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 2. Jairo Rios-Campos' seat: all three assertions at once. The repoint MUST precede the delete.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
UPDATE essentials.offices
   SET title                 = 'City Councilor',
       is_appointed_position = false,
       district_id           = '98ce622b-d560-4090-9db6-5b4b92d3cbe5'
 WHERE id = 'eed3e9b8-3193-48d7-88b2-7c5f1473aff0';

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 3. Retire the executive district. Guarded twice: the surviving row must already carry every
--    value this one holds, and this one must already be empty.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_offices integer;
BEGIN
  IF EXISTS (SELECT 1 FROM essentials.districts WHERE id = '74cc6acb-511f-4808-a318-066dd8b620bd') THEN

    IF NOT EXISTS (
      SELECT 1
        FROM essentials.districts dead
        JOIN essentials.districts live ON live.id = '98ce622b-d560-4090-9db6-5b4b92d3cbe5'
       WHERE dead.id = '74cc6acb-511f-4808-a318-066dd8b620bd'
         AND to_jsonb(dead) - 'id' - 'label' - 'district_type'
           = to_jsonb(live) - 'id' - 'label' - 'district_type'
    ) THEN
      RAISE EXCEPTION 'CC_0426: the surviving district does not carry every value of the one being deleted.';
    END IF;

    SELECT count(*) INTO v_offices
      FROM essentials.offices WHERE district_id = '74cc6acb-511f-4808-a318-066dd8b620bd';
    IF v_offices <> 0 THEN
      RAISE EXCEPTION 'CC_0426: refusing to delete a district that still carries % office(s) -- they would be orphaned in silence.', v_offices;
    END IF;

    DELETE FROM essentials.districts WHERE id = '74cc6acb-511f-4808-a318-066dd8b620bd';
  END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 4. State the council's size, so a sixth office or a missing fifth is countable next time.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
UPDATE essentials.chambers
   SET official_count = 5
 WHERE id = '4f37f2d0-f4b3-4106-8659-3870b0378d98';

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- POST-VERIFY
-- ─────────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_offices   integer;
  v_titled    integer;
  v_roles     integer;
  v_district  integer;
  v_appointed integer;
  v_held      integer;
  v_wv_dist   integer;
  v_or_scope  integer;
  v_or_dead   integer;
  v_or_empty  integer;
  v_count     integer;
  v_unflagged integer;
BEGIN
  -- The chamber still holds five seats, all of them councilors, and no role is an office.
  SELECT count(*),
         count(*) FILTER (WHERE o.title = 'City Councilor'),
         count(*) FILTER (WHERE o.title IN ('Mayor', 'Council President'))
    INTO v_offices, v_titled, v_roles
    FROM essentials.offices o
   WHERE o.chamber_id = '4f37f2d0-f4b3-4106-8659-3870b0378d98';
  IF v_offices <> 5 THEN
    RAISE EXCEPTION 'CC_0426: the Wood Village council holds % offices, not the 5 Charter Section 8 prescribes.', v_offices;
  END IF;
  IF v_titled <> 5 OR v_roles <> 0 THEN
    RAISE EXCEPTION 'CC_0426: % of 5 offices are titled City Councilor and % still carry a role as a title.', v_titled, v_roles;
  END IF;

  -- All five on the council's own district, and the executive district is gone.
  SELECT count(*) INTO v_district
    FROM essentials.offices o
   WHERE o.chamber_id = '4f37f2d0-f4b3-4106-8659-3870b0378d98'
     AND o.district_id = '98ce622b-d560-4090-9db6-5b4b92d3cbe5';
  IF v_district <> 5 THEN
    RAISE EXCEPTION 'CC_0426: % of 5 council offices sit on the At-Large district.', v_district;
  END IF;

  SELECT count(*) INTO v_wv_dist
    FROM essentials.districts WHERE label LIKE 'Wood Village%';
  IF v_wv_dist <> 1 THEN
    RAISE EXCEPTION 'CC_0426: Wood Village has % districts, not 1 -- the executive row was not retired.', v_wv_dist;
  END IF;

  -- Every councilor is elected. `is_elected` is published as NOT is_appointed_position.
  SELECT count(*) INTO v_appointed
    FROM essentials.offices o
   WHERE o.chamber_id = '4f37f2d0-f4b3-4106-8659-3870b0378d98'
     AND o.is_appointed_position IS DISTINCT FROM false;
  IF v_appointed <> 0 THEN
    RAISE EXCEPTION 'CC_0426: % council seat(s) still publish as not elected, against Charter Section 9.', v_appointed;
  END IF;

  -- 🔴 A RETITLE MUST NOT MOVE A PERSON. All five pinned by name against the office each held
  --    before this ran -- the holders are the one thing in this file that must not change.
  SELECT count(*) INTO v_held
    FROM essentials.office_current_holder och
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE (och.office_id = 'eed3e9b8-3193-48d7-88b2-7c5f1473aff0' AND p.full_name = 'Jairo Rios-Campos')
      OR (och.office_id = '4897db37-5c80-4bd9-8057-026f3cc622a3' AND p.full_name = 'Dara Tan')
      OR (och.office_id = '39ab78a4-2b85-4ffd-b4ac-315ec7c79494' AND p.full_name = 'Patricia Smith')
      OR (och.office_id = '8e42ac99-e2bb-4ea5-b8f6-02372ca0b4a6' AND p.full_name = 'John Miner')
      OR (och.office_id = 'c6c3259e-8883-4893-9fe4-50384d131f72' AND p.full_name = 'Charlene Gothard');
  IF v_held <> 5 THEN
    RAISE EXCEPTION 'CC_0426: % of the 5 councilors still hold the seat they held before this ran.', v_held;
  END IF;

  -- CC_0425's ballot mapping is untouched: Position 1 is Gothard's seat, Position 4 is Miner's.
  IF NOT EXISTS (
    SELECT 1 FROM essentials.races r
      JOIN essentials.office_current_holder och ON och.office_id = r.office_id
      JOIN essentials.politicians p ON p.id = och.politician_id
     WHERE r.position_name = 'Wood Village City Council Position 1' AND p.full_name = 'Charlene Gothard'
  ) THEN RAISE EXCEPTION 'CC_0426: Position 1 no longer sits on the office Charlene Gothard holds.'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM essentials.races r
      JOIN essentials.office_current_holder och ON och.office_id = r.office_id
      JOIN essentials.politicians p ON p.id = och.politician_id
     WHERE r.position_name = 'Wood Village City Council Position 4' AND p.full_name = 'John Miner'
  ) THEN RAISE EXCEPTION 'CC_0426: Position 4 no longer sits on the office John Miner holds.'; END IF;

  SELECT official_count INTO v_count
    FROM essentials.chambers WHERE id = '4f37f2d0-f4b3-4106-8659-3870b0378d98';
  IF v_count IS DISTINCT FROM 5 THEN
    RAISE EXCEPTION 'CC_0426: the chamber states its size as %, not 5.', v_count;
  END IF;

  -- 🔴 The master-only reachability gate, carried here as a delta. Oregon has no bucket of any
  --    kind in address-reachability-baseline.json, and that gate fires on any NEW one.
  SELECT count(*),
         count(*) FILTER (WHERE offices > 0 AND active_holders = 0 AND vacant_offices = 0),
         count(*) FILTER (WHERE offices = 0)
    INTO v_or_scope, v_or_dead, v_or_empty
    FROM (
      SELECT d.id,
             count(off.id) AS offices,
             count(*) FILTER (WHERE pp.is_active) AS active_holders,
             count(*) FILTER (WHERE off.is_vacant) AS vacant_offices
        FROM essentials.districts d
        LEFT JOIN essentials.offices off ON off.district_id = d.id
        LEFT JOIN essentials.office_current_holder och2 ON och2.office_id = off.id
        LEFT JOIN essentials.politicians pp ON pp.id = och2.politician_id
       WHERE lower(d.state) = 'or'
         AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')
         AND d.representation_basis = 'residency'
       GROUP BY d.id
    ) s;
  IF v_or_scope < 30 THEN
    RAISE EXCEPTION 'CC_0426: the Oregon reachability check examined only % districts -- it is reading the wrong rows.', v_or_scope;
  END IF;
  IF v_or_dead <> 0 OR v_or_empty <> 0 THEN
    RAISE EXCEPTION 'CC_0426: Oregon now has % district(s) resolving nobody and % with no office at all; the master-only reachability gate would fire on the next PR.', v_or_dead, v_or_empty;
  END IF;

  -- A retitle seats nobody.
  SELECT count(*) FILTER (WHERE NOT o.is_vacant) INTO v_unflagged
    FROM essentials.offices_missing_terms m JOIN essentials.offices o ON o.id = m.office_id;
  IF v_unflagged <> 238 THEN
    RAISE EXCEPTION 'CC_0426: drift baseline reads %, not 238.', v_unflagged;
  END IF;

  RAISE NOTICE 'CC_0426 OK: 5 Wood Village offices all titled City Councilor on one district, 0 roles as offices, 0 appointed, all 5 holders unmoved, executive district retired, chamber states 5, % Oregon districts clean, drift baseline 238.', v_or_scope;
END $$;

COMMIT;
