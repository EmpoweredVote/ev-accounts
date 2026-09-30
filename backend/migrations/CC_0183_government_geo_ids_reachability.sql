-- CC_0183_government_geo_ids_reachability.sql
-- Slot RESERVED from the allocator. Not part of the St. Louis waves; it fixes a reachability
-- defect they share with four other places.
--
-- Sets essentials.governments.geo_id on FIVE city/county governments that are seeded, occupied and
-- unreachable from the Essentials landing page, and gives the City of Wichita the two chambers its
-- seven offices have been missing. Creates NO people, NO terms, NO districts and NO offices.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE DEFECT, AND WHY IT IS INVISIBLE. An Essentials landing-page chip is a row in the
-- frontend's `src/lib/coverage.js`, and the common shape carries `browseGovernmentList: ['<geo_id>']`.
-- The API resolves it in essentialsBrowseService.getPoliticiansByGovernmentList with
--
--     FROM essentials.governments g JOIN essentials.chambers ch ON ch.government_id = g.id
--     JOIN essentials.offices o ON o.chamber_id = ch.id ...
--     WHERE g.geo_id = ANY($1)
--
-- so a government with a NULL geo_id CANNOT BE NAMED BY ANY BROWSE URL. Nothing errors, no gate
-- fires, and address search keeps working perfectly — because address search goes
-- districts -> offices -> office_current_holder and never touches essentials.governments.
-- That is exactly why this survived: every place below answers an address today.
--
-- Reported 2026-09-29 by the operator, who noticed Wichita and Lexington missing from the landing
-- page. `coverage.js` already carried the diagnosis, written the same day:
--   "TWO KNIGHT CITIES ARE STILL UNREACHABLE AND ARE DELIBERATELY NOT LISTED HERE, because a chip
--    is keyed on governments.geo_id and theirs is NULL ... Give them a geo_id (2146027 and
--    2079000) and they become one-line additions here."
-- This migration is that fix, widened to the four places carrying the identical defect.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 EVERY geo_id BELOW WAS VERIFIED AGAINST A DISTRICT THAT EXISTS IN PRODUCTION AND CARRIES A
-- POLYGON, rather than composed from a name. Measured 2026-09-29:
--
--   2079000  G4110  City of Wichita (Mayor)                              KS
--   2146027  G4110  Lexington-Fayette Urban County Government (citywide) KY
--   2965000  G4110  St. Louis (Citywide) / (Board of Aldermen, Citywide) MO
--   29189    G4020  St. Louis County                                     MO
--   1805860  G4110  Bloomington City Mayor / City Clerk / At-Large       IN
--
-- 🔴🔴 INDIANAPOLIS IS DELIBERATELY NOT FIXED HERE, AND THE GATE IS WHY. It was in this
-- migration until the first dry-run, which refused it:
--     CC_0183 gate: 1 government geo_id(s) are now shared by more than one row
-- Indianapolis and Marion County are consolidated (Unigov) and its Mayor sits on the COUNTY
-- polygon 18097/G4020 — but `Marion County, Indiana, US` ALREADY CARRIES 18097, with 38 chambers
-- and 38 offices. The place code 1836003 appears NOWHERE in essentials.districts, so it would name
-- ground the database does not hold.
--   So Indianapolis has NO geo_id that is both correct and free. 18097 duplicates; 1836003 points
--   at nothing. Either would be a guess, and the honest move is to leave its 6 seats unreachable
--   by browse (they still answer an address) until somebody decides how a consolidated city-county
--   should be modelled here. That is a design question, not a data fix.
-- 🟢 The gate caught this before anything was written. It is the reason the table above is five
-- rows and not six.
--
-- ⚠ ST. LOUIS COUNTY IS A COUNTY geo_id (29189/G4020) FOR THE SAME REASON — its three countywide
-- seats sit on the county polygon. 🔴 And `St. Louis County` ALSO EXISTS IN MINNESOTA (27137); the
-- gate below asserts that the Minnesota government's geo_id is untouched.
--
-- 🟢 NO COLLISION IS POSSIBLE: essentials.governments.geo_id was measured 2026-09-29 to have ZERO
-- duplicate values, and the gate re-asserts that afterwards over the whole table.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 WICHITA HAS A SECOND, DIFFERENT DEFECT, AND THE geo_id ALONE WOULD NOT HAVE FIXED IT.
-- All SEVEN of its offices carry `chamber_id = NULL`, so its government row reports 0 chambers and
-- 0 offices and the browse query's `JOIN essentials.chambers` drops every one. Lexington-Fayette,
-- by contrast, is fully wired (4 chambers, 34 offices, 0 null) and needed only the geo_id — which
-- is why the two had to be diagnosed separately rather than as one symptom.
--   ⚠ A NULL chamber_id is NOT by itself a defect: 356 of 10,469 offices carry one, including the
--   whole DC Council and the LA Superior Court bench. It is a defect HERE because Wichita has a
--   government row that is meant to hold these seats.
-- The 7 offices, all seated, all with polygons: Mayor (Lily Wu) on 2079000/G4110/LOCAL_EXEC, and
-- Council Members District 1-6 on wichita-ks-council-district-N/X0070/LOCAL.
--
-- ⚠ BLOOMINGTON IN IS ALREADY REACHABLE and is included anyway. Its chip uses the ADDRESS shape
-- (`{ label: 'Bloomington', address: '100 W Kirkwood Ave, ...' }`), which Landing.jsx routes
-- straight to /results. Its geo_id is still correct to set: the value is right, the column is the
-- canonical key, and leaving one row NULL invites the next person to read the column as optional.
--
-- ⚠ ~80 LOS ANGELES COUNTY CITIES AND SPECIAL DISTRICTS ALSO CARRY A NULL geo_id AND ARE
-- DELIBERATELY NOT TOUCHED HERE. None of them is a landing-page chip, none was reported, and each
-- would need its own Census code verified. Widening this migration to them would be a different
-- job done carelessly. Recorded so the omission is a decision rather than an oversight.
--
-- 🔴 THIS MIGRATION DOES NOT MAKE ANY CITY APPEAR ON ITS OWN. A chip must also be added to
-- `src/lib/coverage.js` in the Essentials frontend repo. Wichita and Lexington-Fayette have
-- certified banners in `buildingImages.js` and get chips in the same pass; St. Louis city,
-- St. Louis County and Indianapolis have NO banner yet and get their chips when one is certified.
--
-- Idempotent: every UPDATE is value-guarded, every INSERT is NOT EXISTS-guarded. Ends with a
-- post-verify gate.

BEGIN;

-- ─── 1. The six geo_ids, plus the two rows missing type and state ─────────────
-- 🔴 Matched on the exact government NAME, which is unique here, and guarded on geo_id IS NULL so
-- a row that already carries one is never overwritten.

CREATE TEMP TABLE gov_fix(name text, geo_id text, gov_type text, gov_state text) ON COMMIT DROP;

INSERT INTO gov_fix VALUES
  ('City of Wichita, Kansas, US',                             '2079000', 'City',  'KS'),
  ('Lexington-Fayette Urban County Government, Kentucky, US', '2146027', 'City',  'KY'),
  ('City of St. Louis, Missouri, US',                         '2965000', NULL,    NULL),
  ('St. Louis County, Missouri, US',                          '29189',   NULL,    NULL),
  ('City of Bloomington, Indiana, US',                        '1805860', NULL,    NULL);
  -- 🔴 NO City of Indianapolis row. See the header: 18097 belongs to Marion County and 1805860's
  -- place-code equivalent (1836003) names no district. The first dry-run's gate refused it.

UPDATE essentials.governments g
   SET geo_id = f.geo_id,
       -- Only the two NULL rows carry a type/state here; COALESCE never overwrites an existing one.
       type   = COALESCE(g.type,  f.gov_type),
       state  = COALESCE(g.state, f.gov_state)
  FROM gov_fix f
 WHERE g.name = f.name
   AND g.geo_id IS NULL;

-- ─── 2. Wichita's two chambers ────────────────────────────────────────────────
-- Shaped after the other city governments: a named body for the council, and "Office of the X"
-- for the single-holder executive.

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, v.name, v.name, v.n
FROM essentials.governments g
CROSS JOIN (VALUES
  ('Wichita City Council', 6),
  ('Office of the Mayor',  1)
) AS v(name, n)
WHERE g.name = 'City of Wichita, Kansas, US'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 3. Attach Wichita's seven orphaned offices ───────────────────────────────
-- 🔴 Keyed on (geo_id, district_type), never on a label, and scoped to offices that are currently
-- orphaned. An office already holding a chamber_id is not touched.

UPDATE essentials.offices o
   SET chamber_id = c.id
  FROM essentials.districts d, essentials.governments g, essentials.chambers c
 WHERE o.district_id = d.id
   AND g.name = 'City of Wichita, Kansas, US'
   AND c.government_id = g.id
   AND c.name = 'Wichita City Council'
   AND o.chamber_id IS NULL
   AND d.mtfcc = 'X0070'
   AND d.district_type::text = 'LOCAL'
   AND lower(d.state) = 'ks';

UPDATE essentials.offices o
   SET chamber_id = c.id
  FROM essentials.districts d, essentials.governments g, essentials.chambers c
 WHERE o.district_id = d.id
   AND g.name = 'City of Wichita, Kansas, US'
   AND c.government_id = g.id
   AND c.name = 'Office of the Mayor'
   AND o.chamber_id IS NULL
   AND d.geo_id = '2079000'
   AND d.district_type::text = 'LOCAL_EXEC'
   AND lower(d.state) = 'ks'
   AND o.title = 'Mayor';

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  r record;
  v_dupe int; v_wich_ch int; v_wich_off int; v_wich_seated int; v_wich_null int;
  v_mn_geo text; v_browse int; v_reach int;
BEGIN
  -- 1. Every one of the six carries exactly the geo_id it was verified against.
  FOR r IN SELECT * FROM gov_fix LOOP
    PERFORM 1 FROM essentials.governments g WHERE g.name = r.name AND g.geo_id = r.geo_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'CC_0183 gate: % does not carry geo_id % — it has %',
        r.name, r.geo_id,
        coalesce((SELECT geo_id FROM essentials.governments WHERE name = r.name), 'NULL (or no such row)');
    END IF;
  END LOOP;

  -- 2. 🔴 Every geo_id written must name a district that actually exists WITH A POLYGON, or the
  -- chip would resolve to a government whose ground is not in the database.
  SELECT count(*) INTO v_reach FROM gov_fix f
   WHERE NOT EXISTS (
     SELECT 1 FROM essentials.districts d
      JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc
     WHERE d.geo_id = f.geo_id);
  IF v_reach <> 0 THEN
    RAISE EXCEPTION 'CC_0183 gate: % geo_id(s) name no district with a polygon', v_reach;
  END IF;

  -- 3. 🔴 geo_id must stay unique across the WHOLE table, not just among these six.
  SELECT count(*) INTO v_dupe FROM (
    SELECT geo_id FROM essentials.governments WHERE geo_id IS NOT NULL
     GROUP BY geo_id HAVING count(*) > 1) x;
  IF v_dupe <> 0 THEN
    RAISE EXCEPTION 'CC_0183 gate: % government geo_id(s) are now shared by more than one row', v_dupe;
  END IF;

  -- 4. 🔴🔴 MINNESOTA'S St. Louis County MUST NOT HAVE BEEN TOUCHED. Same label, same seat count.
  SELECT geo_id INTO v_mn_geo FROM essentials.governments
   WHERE name = 'St. Louis County, Minnesota, US';
  IF v_mn_geo IS DISTINCT FROM NULL AND v_mn_geo = '29189' THEN
    RAISE EXCEPTION 'CC_0183 gate: the MINNESOTA St. Louis County government now carries Missouri''s geo_id 29189';
  END IF;

  -- 5. Wichita is fully wired: 2 chambers, 7 offices on them, 7 seated, 0 left orphaned.
  SELECT count(*) INTO v_wich_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Wichita, Kansas, US';
  IF v_wich_ch <> 2 THEN RAISE EXCEPTION 'CC_0183 gate: Wichita has % chamber(s), expected 2', v_wich_ch; END IF;

  SELECT count(*) INTO v_wich_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Wichita, Kansas, US';
  IF v_wich_off <> 7 THEN RAISE EXCEPTION 'CC_0183 gate: Wichita has % office(s) on a chamber, expected 7', v_wich_off; END IF;

  -- 🔴 count och.politician_id, NOT *: office_current_holder LEFT JOINs from offices.
  SELECT count(och.politician_id) INTO v_wich_seated FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'City of Wichita, Kansas, US';
  IF v_wich_seated <> 7 THEN RAISE EXCEPTION 'CC_0183 gate: Wichita has % seated, expected 7', v_wich_seated; END IF;

  SELECT count(*) INTO v_wich_null FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ks' AND o.chamber_id IS NULL
     AND (d.mtfcc = 'X0070' OR d.geo_id = '2079000');
  IF v_wich_null <> 0 THEN RAISE EXCEPTION 'CC_0183 gate: % Wichita office(s) are still orphaned from a chamber', v_wich_null; END IF;

  -- 6. 🔴 THE ASSERTION THAT MATTERS: run the browse query's own shape for each of the five and
  -- require it to return occupants. This is the thing that was broken; a count of columns is not.
  SELECT count(*) INTO v_browse FROM gov_fix f
   WHERE NOT EXISTS (
     SELECT 1
       FROM essentials.governments g
       JOIN essentials.chambers ch ON ch.government_id = g.id
       JOIN essentials.offices o ON o.chamber_id = ch.id
       JOIN essentials.office_current_holder och ON och.office_id = o.id
       JOIN essentials.politicians p ON p.id = och.politician_id
      WHERE g.geo_id = f.geo_id AND p.is_active = true);
  IF v_browse <> 0 THEN
    RAISE EXCEPTION 'CC_0183 gate: % of the five still return NO occupants through governments -> chambers -> offices, which is the exact join the landing page uses', v_browse;
  END IF;

  RAISE NOTICE 'CC_0183 gate PASSED: 5 governments carry a verified geo_id, every one names a district with a polygon, geo_id is unique table-wide, Minnesota untouched, Wichita wired to 2 chambers with 7 offices and 7 seated and 0 orphans, and all five now return occupants through the landing page''s own join.';
END $$;

COMMIT;
