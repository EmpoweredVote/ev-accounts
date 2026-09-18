-- CC_0123_pa_counties_structure.sql
-- Knight Foundation program, wave PA-4 (structure half). Slot RESERVED from the allocator.
--
-- Stage 4 for Pennsylvania, and the two halves of it look nothing alike.
--
-- 🔴 PHILADELPHIA HAS NO COUNTY COMMISSION, BECAUSE THE CITY COUNCIL IS IT. What a consolidated
-- city keeps is its separately elected ROW OFFICES (spec §3.2): District Attorney, City
-- Controller, Sheriff, Register of Wills and THREE City Commissioners — 7 seats, hung on the
-- SAME government row PA-3 created, exactly as Columbus and Macon-Bibb hang theirs. No second
-- government is invented for a county that is the city.
--
-- 🔴 CENTRE COUNTY IS AN ORDINARY COUNTY AND STILL MATCHES NO TEMPLATE. Read off its own page:
--   · a CONTROLLER, not three Auditors — Pennsylvania counties elect one or the other;
--   · a combined PROTHONOTARY AND CLERK OF COURTS, and a combined REGISTER OF WILLS AND CLERK OF
--     THE ORPHANS' COURT — two offices where a template would write four;
--   · 🔴 TWO JURY COMMISSIONERS. Act 2013-11 let Pennsylvania counties abolish that office and
--     many did. Centre did not, and nothing but the county's own page would have said so.
--   Three commissioners in their own chamber, ten officers in another: 13 seats.
--
-- 🔴 ELECTED JUDGES ARE IN SCOPE AND ARE NOT IN THIS MIGRATION. Centre County elects Court of
-- Common Pleas judges and six Magisterial District Judges; Philadelphia elects its judiciary too.
-- Under the NC-3 inclusion ruling they belong in the data — in the JUDGES WAVE that North
-- Carolina already owes. Deferring is a scheduling decision, recorded here, not a ruling that
-- they do not count.
--
-- 🟢 NO DISTRICT IS CREATED. Both countywide polygons already exist: Philadelphia County 42101
-- and Centre County 42027, both G4020. The migration ASSERTS them and fails if either is absent.
-- ⚠ Philadelphia's county polygon and its place polygon measure the same 142.422 sq mi, so the
-- row offices resolve for exactly the addresses the Mayor does. That is a property of a
-- consolidated city, and the probe after the apply checks it rather than assuming it.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 0. Pre-flight: the two countywide polygons and the city government ───────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries
   WHERE mtfcc = 'G4020' AND state = '42' AND geo_id IN ('42101','42027');
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'PA-4: expected the Philadelphia and Centre county polygons, found %', v_n;
  END IF;
  SELECT count(*) INTO v_n FROM essentials.districts
   WHERE lower(state) = 'pa' AND mtfcc = 'G4020' AND geo_id IN ('42101','42027');
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'PA-4: expected the two countywide DISTRICT rows, found %', v_n;
  END IF;
  SELECT count(*) INTO v_n FROM essentials.governments WHERE state = 'PA' AND geo_id = '4260000';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'PA-4: the City of Philadelphia government row is missing — run CC_0121 first';
  END IF;
END $$;

-- ─── 1. Centre County's government row ────────────────────────────────────────
INSERT INTO essentials.governments (name, type, state, geo_id)
SELECT 'Centre County, Pennsylvania, US', 'County', 'PA', '42027'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE state = 'PA' AND geo_id = '42027');

-- ─── 2. Three chambers ────────────────────────────────────────────────────────
INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, 'City and County Elected Officials', 'City and County Elected Officials', 7
FROM essentials.governments g
WHERE g.state = 'PA' AND g.geo_id = '4260000'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = 'City and County Elected Officials');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, 'Board of County Commissioners', 'Board of County Commissioners', 3
FROM essentials.governments g
WHERE g.state = 'PA' AND g.geo_id = '42027'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = 'Board of County Commissioners');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, 'County Elected Officials', 'County Elected Officials', 10
FROM essentials.governments g
WHERE g.state = 'PA' AND g.geo_id = '42027'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = 'County Elected Officials');

-- ─── 3. The 20 offices ────────────────────────────────────────────────────────
-- ⚠ Three City Commissioners share one title on one district, and so do three County
-- Commissioners and two Jury Commissioners. The guard counts how many of that (title, district)
-- pair already exist, so a re-run adds none and a missing one is still added.
INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, v.title, 'PA', 1, false, 'full'
FROM (VALUES
  (0, 'District Attorney', 'City and County Elected Officials', '4260000', '42101', 'G4020'),
  (1, 'City Controller', 'City and County Elected Officials', '4260000', '42101', 'G4020'),
  (2, 'Sheriff', 'City and County Elected Officials', '4260000', '42101', 'G4020'),
  (3, 'Register of Wills', 'City and County Elected Officials', '4260000', '42101', 'G4020'),
  (4, 'City Commissioner', 'City and County Elected Officials', '4260000', '42101', 'G4020'),
  (5, 'City Commissioner', 'City and County Elected Officials', '4260000', '42101', 'G4020'),
  (6, 'City Commissioner', 'City and County Elected Officials', '4260000', '42101', 'G4020'),
  (7, 'County Commissioner', 'Board of County Commissioners', '42027', '42027', 'G4020'),
  (8, 'County Commissioner', 'Board of County Commissioners', '42027', '42027', 'G4020'),
  (9, 'County Commissioner', 'Board of County Commissioners', '42027', '42027', 'G4020'),
  (10, 'Controller', 'County Elected Officials', '42027', '42027', 'G4020'),
  (11, 'Coroner', 'County Elected Officials', '42027', '42027', 'G4020'),
  (12, 'District Attorney', 'County Elected Officials', '42027', '42027', 'G4020'),
  (13, 'Jury Commissioner', 'County Elected Officials', '42027', '42027', 'G4020'),
  (14, 'Jury Commissioner', 'County Elected Officials', '42027', '42027', 'G4020'),
  (15, 'Prothonotary and Clerk of Courts', 'County Elected Officials', '42027', '42027', 'G4020'),
  (16, 'Recorder of Deeds', 'County Elected Officials', '42027', '42027', 'G4020'),
  (17, 'Register of Wills and Clerk of the Orphans'' Court', 'County Elected Officials', '42027', '42027', 'G4020'),
  (18, 'Sheriff', 'County Elected Officials', '42027', '42027', 'G4020'),
  (19, 'Treasurer', 'County Elected Officials', '42027', '42027', 'G4020')
) AS v(ord, title, chamber_name, gov_geo_id, district_geo_id, district_mtfcc)
JOIN essentials.governments g ON g.state = 'PA' AND g.geo_id = v.gov_geo_id
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = v.chamber_name
JOIN essentials.districts d ON d.geo_id = v.district_geo_id AND d.mtfcc = v.district_mtfcc AND lower(d.state) = 'pa'
WHERE (
  SELECT count(*) FROM essentials.offices o WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = v.title
) < (
  SELECT count(*) FROM (VALUES
    (0, 'District Attorney', 'City and County Elected Officials'),
    (1, 'City Controller', 'City and County Elected Officials'),
    (2, 'Sheriff', 'City and County Elected Officials'),
    (3, 'Register of Wills', 'City and County Elected Officials'),
    (4, 'City Commissioner', 'City and County Elected Officials'),
    (5, 'City Commissioner', 'City and County Elected Officials'),
    (6, 'City Commissioner', 'City and County Elected Officials'),
    (7, 'County Commissioner', 'Board of County Commissioners'),
    (8, 'County Commissioner', 'Board of County Commissioners'),
    (9, 'County Commissioner', 'Board of County Commissioners'),
    (10, 'Controller', 'County Elected Officials'),
    (11, 'Coroner', 'County Elected Officials'),
    (12, 'District Attorney', 'County Elected Officials'),
    (13, 'Jury Commissioner', 'County Elected Officials'),
    (14, 'Jury Commissioner', 'County Elected Officials'),
    (15, 'Prothonotary and Clerk of Courts', 'County Elected Officials'),
    (16, 'Recorder of Deeds', 'County Elected Officials'),
    (17, 'Register of Wills and Clerk of the Orphans'' Court', 'County Elected Officials'),
    (18, 'Sheriff', 'County Elected Officials'),
    (19, 'Treasurer', 'County Elected Officials')
  ) AS w(ord, title, chamber_name) WHERE w.title = v.title AND w.chamber_name = v.chamber_name
    AND w.ord <= v.ord
);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────
DO $$
DECLARE v_gov int; v_ch int; v_phl int; v_board int; v_off int; v_jury int; v_dist int; v_orphan int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments WHERE state = 'PA' AND geo_id = '42027' AND type = 'County';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'PA-4: expected 1 Centre County government row, got %', v_gov; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','42027');
  IF v_ch <> 5 THEN RAISE EXCEPTION 'PA-4: expected 5 chambers across the city and Centre County, got %', v_ch; END IF;

  SELECT count(*) INTO v_phl FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id = '4260000' AND c.name = 'City and County Elected Officials';
  IF v_phl <> 7 THEN RAISE EXCEPTION 'PA-4: expected 7 Philadelphia row offices, got %', v_phl; END IF;

  SELECT count(*) INTO v_board FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id = '42027' AND c.name = 'Board of County Commissioners';
  IF v_board <> 3 THEN RAISE EXCEPTION 'PA-4: expected 3 Centre County commissioners, got %', v_board; END IF;

  SELECT count(*) INTO v_off FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id = '42027' AND c.name = 'County Elected Officials';
  IF v_off <> 10 THEN RAISE EXCEPTION 'PA-4: expected 10 Centre County row officers, got %', v_off; END IF;

  -- 🔴 THE OFFICE A TEMPLATE WOULD HAVE DROPPED. Centre kept its jury commissioners; if this
  -- count ever reads 0, someone has "tidied" the roster against a state-wide assumption.
  SELECT count(*) INTO v_jury FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id = '42027' AND o.title = 'Jury Commissioner';
  IF v_jury <> 2 THEN RAISE EXCEPTION 'PA-4: expected 2 Centre County jury commissioners, got %', v_jury; END IF;

  -- 🟢 NO NEW DISTRICT. Pennsylvania's countywide district count must be exactly what it was.
  SELECT count(*) INTO v_dist FROM essentials.districts WHERE lower(state) = 'pa' AND mtfcc = 'G4020';
  IF v_dist <> 67 THEN RAISE EXCEPTION 'PA-4: Pennsylvania should still have 67 county districts, has %', v_dist; END IF;

  SELECT count(*) INTO v_orphan FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   JOIN essentials.districts d ON d.id = o.district_id
   LEFT JOIN essentials.geofence_boundaries b ON b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','42027') AND b.id IS NULL;
  IF v_orphan <> 0 THEN
    RAISE EXCEPTION 'PA-4: % office(s) sit on a district with no polygon — unreachable by any address', v_orphan;
  END IF;

  RAISE NOTICE 'PA-4 structure OK: Centre County created, % Philadelphia row offices, % commissioners, % county officers, 0 new districts',
    v_phl, v_board, v_off;
END $$;

COMMIT;
