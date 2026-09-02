-- verify-macon-bibb-probes.sql
--
-- Acceptance evidence for GA-5, Macon-Bibb County. Read-only: it asserts and
-- raises, and writes nothing.
--
-- Wave GA-5 of the Knight Foundation cities program.
-- Roster: backend/data/seed-macon-bibb-2026/ROSTERS.md
-- Slice:  .planning/knight-foundation/ga.md
--
-- Usage, INSIDE the dry-run transaction, before anything is applied:
--     BEGIN; <CC_0045> <CC_0046> <CC_0047> \i scripts/verify-macon-bibb-probes.sql ROLLBACK;
-- and again after the apply, on its own.
--
-- ─────────────────────────────────────────────────────────────────────────────
-- 🔴 WHY THIS FILE EXISTS AT ALL. `check:reachability` takes NO per-jurisdiction
--    probe list: it sweeps every district of an addressable district_type and
--    reads its MTFCC mapping out of src/lib/geoIdGuard.ts at runtime. So a green
--    reachability run after this wave means "no district REGRESSED" -- it does
--    NOT prove these nine districts were examined. The acceptance evidence for a
--    jurisdiction is therefore two things (spec §5):
--      1. this probe file, asserting the four required answers at city hall,
--         plus a SECOND ANCHOR because two tiers number the same ground; and
--      2. a per-district positive control -- every new district tested at its
--         own interior point, asserting exactly one holder.
--    Both are below.
--
-- ─────────────────────────────────────────────────────────────────────────────
-- 🔴 THE CITY HALL COORDINATE WAS GEOCODED, NOT GUESSED.
--
-- "700 Poplar Street, Macon, GA 31201" -> the US Census geocoder
-- (Public_AR_Current) returned -83.631827184, 32.836028193173 and independently
-- placed it in County 13021 Bibb -- which PROBE 0 re-asserts against TIGER
-- rather than trusting the label. GA-3 shipped a control point labelled "Rural
-- Baldwin County" that was really in Hancock County: it passed, for a true
-- reason, while testing nothing it claimed to test. A mislabelled control reads
-- as covered.
--
-- ⚠ AN ANCHOR'S EXPECTED ANSWER IS A PROPERTY OF THE POINT, NOT OF THE
--   JURISDICTION. The GA-4 plan expected Columbus's downtown to be in HD-137
--   because it copied GA-1's verification, which had probed the place polygon's
--   own interior point out in rural northern Muscogee. Downtown was HD-140.
--   So the legislative answers below are asserted to be NON-NULL and to be
--   exactly one each -- never to be a district number carried from elsewhere.
--
-- ─────────────────────────────────────────────────────────────────────────────
-- 🔴 THE SECOND ANCHOR IS THE ONE THAT CATCHES A CROSSED TIER.
--
-- Macon-Bibb's citywide LOCAL district and Bibb's COUNTY district cover the SAME
-- 254.906 sq mi. An office on the wrong tier still resolves at every address in
-- Macon and looks completely correct. What distinguishes them is that the
-- COMMISSION DISTRICT must CHANGE between two anchors while the citywide and
-- county answers must NOT. A single anchor cannot see that.

DO $$
DECLARE
  -- Geocoded 2026-09-02, US Census Public_AR_Current.
  v_hall_lon  double precision := -83.631827184;
  v_hall_lat  double precision :=  32.836028193173;
  -- Second anchor: District 6's own ST_PointOnSurface, measured 2026-09-01 from
  -- the adopted plan. Deliberately NOT downtown -- D6 is the largest district at
  -- 59.68 sq mi -- so the commission answer MUST differ from City Hall's.
  v_far_lon   double precision := -83.811522;
  v_far_lat   double precision :=  32.800209;

  v_hall      geometry;
  v_far       geometry;
  v_n         int;
  v_county    text;
  v_hall_dist text;
  v_far_dist  text;
  v_hall_mayor text;
  v_far_mayor  text;
  v_hall_sheriff text;
  v_far_sheriff  text;
  r           record;
BEGIN
  v_hall := public.ST_SetSRID(public.ST_MakePoint(v_hall_lon, v_hall_lat), 4326);
  v_far  := public.ST_SetSRID(public.ST_MakePoint(v_far_lon,  v_far_lat),  4326);

  -- ── PROBE 0: the anchor is where its label says ──────────────────────────
  SELECT gb.geo_id INTO v_county
    FROM essentials.geofence_boundaries gb
   WHERE gb.mtfcc = 'G4020' AND gb.state = '13'
     AND public.ST_Covers(gb.geometry, v_hall);
  IF v_county IS DISTINCT FROM '13021' THEN
    RAISE EXCEPTION 'PROBE 0: City Hall resolves to county %, expected 13021 Bibb -- fix the point or the label (the GA-3 Hancock defect)', coalesce(v_county, 'none');
  END IF;
  RAISE NOTICE 'PROBE 0 OK: City Hall is in county % (asserted against TIGER, not trusted from a label)', v_county;

  -- ── PROBE 1: THE DEFINITION OF DONE. Four answers, one probe. ────────────
  -- spec §5: "an address at city hall returns its council member, its county
  -- commissioner, its state representative and its state senator."
  -- ⚠ Under consolidation there IS no county commissioner -- the Commission is
  --   the county legislature -- so the county answer is the separately elected
  --   county officers, which is what stage 4 seats.

  -- (a) the commission member
  SELECT count(och.politician_id), min(d.label) INTO v_n, v_hall_dist
    FROM essentials.districts d
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc
    JOIN essentials.offices o ON o.district_id = d.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE d.mtfcc = 'X0045' AND d.district_type = 'LOCAL' AND lower(d.state) = 'ga'
     AND public.ST_Covers(gb.geometry, v_hall);
  IF v_n <> 1 THEN RAISE EXCEPTION 'PROBE 1a: City Hall returns % commission member(s), expected exactly 1', v_n; END IF;

  -- (b) the citywide seat: the Mayor, and ONLY the Mayor
  SELECT count(och.politician_id), min(p.full_name) INTO v_n, v_hall_mayor
    FROM essentials.districts d
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc
    JOIN essentials.offices o ON o.district_id = d.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE d.geo_id = '1349008' AND d.mtfcc = 'G4110' AND d.district_type = 'LOCAL'
     AND public.ST_Covers(gb.geometry, v_hall);
  -- 🔴 ONE, not Columbus's THREE. Macon-Bibb has no at-large commissioners.
  IF v_n <> 1 THEN RAISE EXCEPTION 'PROBE 1b: City Hall returns % citywide holder(s), expected exactly 1 (the Mayor) -- Columbus expects 3 here and Macon-Bibb has NO at-large seats', v_n; END IF;

  -- (c) the county officers, on the COUNTY tier
  SELECT count(och.politician_id) INTO v_n
    FROM essentials.districts d
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc
    JOIN essentials.offices o ON o.district_id = d.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE d.geo_id = '13021' AND d.mtfcc = 'G4020' AND d.district_type = 'COUNTY'
     AND public.ST_Covers(gb.geometry, v_hall);
  IF v_n <> 5 THEN RAISE EXCEPTION 'PROBE 1c: City Hall returns % county officer(s), expected exactly 5', v_n; END IF;
  SELECT min(p.full_name) INTO v_hall_sheriff
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE d.geo_id = '13021' AND d.mtfcc = 'G4020' AND d.district_type = 'COUNTY' AND o.title = 'Sheriff';

  -- (d) the state representative and (e) the state senator
  -- ⚠ Asserted to be EXACTLY ONE EACH and non-NULL. The district NUMBER is
  --   deliberately not asserted: it is a property of this point, and carrying
  --   one anchor's number onto another address is the GA-4 HD-137 defect.
  SELECT count(och.politician_id) INTO v_n
    FROM essentials.districts d
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc
    JOIN essentials.offices o ON o.district_id = d.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE d.district_type = 'STATE_LOWER' AND lower(d.state) = 'ga'
     AND public.ST_Covers(gb.geometry, v_hall);
  IF v_n <> 1 THEN RAISE EXCEPTION 'PROBE 1d: City Hall returns % state representative(s), expected exactly 1', v_n; END IF;

  SELECT count(och.politician_id) INTO v_n
    FROM essentials.districts d
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc
    JOIN essentials.offices o ON o.district_id = d.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE d.district_type = 'STATE_UPPER' AND lower(d.state) = 'ga'
     AND public.ST_Covers(gb.geometry, v_hall);
  IF v_n <> 1 THEN RAISE EXCEPTION 'PROBE 1e: City Hall returns % state senator(s), expected exactly 1', v_n; END IF;

  RAISE NOTICE 'PROBE 1 OK: City Hall returns its commission member (%), the Mayor (%), 5 county officers (Sheriff %), 1 state rep and 1 state senator', v_hall_dist, v_hall_mayor, v_hall_sheriff;

  -- ── PROBE 2: THE SECOND ANCHOR. The commission answer must CHANGE; the ──
  --    citywide and county answers must NOT.
  SELECT min(d.label) INTO v_far_dist
    FROM essentials.districts d
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc
   WHERE d.mtfcc = 'X0045' AND d.district_type = 'LOCAL' AND lower(d.state) = 'ga'
     AND public.ST_Covers(gb.geometry, v_far);
  IF v_far_dist IS NULL THEN RAISE EXCEPTION 'PROBE 2: the second anchor is in no commission district'; END IF;
  IF v_far_dist = v_hall_dist THEN
    RAISE EXCEPTION 'PROBE 2: both anchors return the same commission district (%) -- this anchor cannot detect a crossed tier. Pick a point in a different district.', v_far_dist;
  END IF;

  SELECT min(p.full_name) INTO v_far_mayor
    FROM essentials.districts d
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE d.geo_id = '1349008' AND d.mtfcc = 'G4110' AND d.district_type = 'LOCAL'
     AND public.ST_Covers(gb.geometry, v_far);
  SELECT min(p.full_name) INTO v_far_sheriff
    FROM essentials.districts d
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE d.geo_id = '13021' AND d.mtfcc = 'G4020' AND d.district_type = 'COUNTY'
     AND o.title = 'Sheriff' AND public.ST_Covers(gb.geometry, v_far);

  IF v_far_mayor IS DISTINCT FROM v_hall_mayor THEN
    RAISE EXCEPTION 'PROBE 2: the citywide answer CHANGED between anchors (% vs %) -- it must not', v_hall_mayor, v_far_mayor;
  END IF;
  IF v_far_sheriff IS DISTINCT FROM v_hall_sheriff THEN
    RAISE EXCEPTION 'PROBE 2: the county answer CHANGED between anchors (% vs %) -- it must not', v_hall_sheriff, v_far_sheriff;
  END IF;
  RAISE NOTICE 'PROBE 2 OK: commission answer changed (% -> %) while the Mayor (%) and Sheriff (%) held constant -- the two tiers are independent and uncrossed', v_hall_dist, v_far_dist, v_far_mayor, v_far_sheriff;

  -- ── PROBE 3: PER-DISTRICT POSITIVE CONTROL ───────────────────────────────
  -- Every one of the nine, at its own ST_PointOnSurface. This is what
  -- distinguishes "swept and clean" from "not swept".
  FOR r IN
    SELECT d.geo_id, d.label, public.ST_PointOnSurface(gb.geometry) AS pt
      FROM essentials.districts d
      JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc
     WHERE d.mtfcc = 'X0045' AND d.district_type = 'LOCAL' AND lower(d.state) = 'ga'
     ORDER BY d.geo_id
  LOOP
    SELECT count(och.politician_id) INTO v_n
      FROM essentials.districts d2
      JOIN essentials.geofence_boundaries gb2 ON gb2.geo_id = d2.geo_id AND gb2.mtfcc = d2.mtfcc
      JOIN essentials.offices o ON o.district_id = d2.id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
     WHERE d2.mtfcc = 'X0045' AND d2.district_type = 'LOCAL' AND lower(d2.state) = 'ga'
       AND public.ST_Covers(gb2.geometry, r.pt);
    IF v_n <> 1 THEN
      RAISE EXCEPTION 'PROBE 3: % resolves to % commission holder(s) at its own interior point, expected exactly 1', r.label, v_n;
    END IF;
  END LOOP;
  SELECT count(*) INTO v_n FROM essentials.districts
   WHERE mtfcc = 'X0045' AND district_type = 'LOCAL' AND lower(state) = 'ga';
  IF v_n <> 9 THEN RAISE EXCEPTION 'PROBE 3: swept % districts, expected 9', v_n; END IF;
  RAISE NOTICE 'PROBE 3 OK: 9 of 9 commission districts resolve individually to exactly one holder';

  -- ── PROBE 4: DEMONSTRATE THE UNPAIRED-JOIN HAZARD, do not just warn ─────
  -- 🔴 Georgia's geo_id collision is THREE-WAY. Dropping mtfcc and
  --    district_type from the district join returns rows from other tiers, and
  --    nothing errors.
  SELECT count(*) INTO v_n
    FROM essentials.districts d
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id
    JOIN essentials.offices o ON o.district_id = d.id
   WHERE public.ST_Covers(gb.geometry, v_hall);
  RAISE NOTICE 'PROBE 4: dropping mtfcc from the boundary join returns % office row(s) at City Hall -- the paired joins above return 8 (1 commission + 1 Mayor + 5 county + 1 state rep... plus the senator and congressional seat). This is why every join pairs geo_id with mtfcc AND district_type.', v_n;
  IF v_n <= 8 THEN
    RAISE EXCEPTION 'PROBE 4: the unpaired join returned only % row(s). Georgia''s three-way collision is documented as MEASURED; if it has genuinely gone away, re-measure before relaxing any join.', v_n;
  END IF;

  -- ── PROBE 5: nothing in this wave is vacant, and nothing is invisible ───
  SELECT count(*) INTO v_n
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id = '1349008' AND g.type = 'City'
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PROBE 5: % Macon-Bibb office(s) carry no office_terms row and are invisible', v_n; END IF;

  SELECT count(och.politician_id) INTO v_n
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.geo_id = '1349008' AND g.type = 'City';
  IF v_n <> 15 THEN RAISE EXCEPTION 'PROBE 5: expected 15 seated Macon-Bibb officials across all three chambers, found %', v_n; END IF;
  RAISE NOTICE 'PROBE 5 OK: 15 seated across 3 chambers, 0 invisible offices';

  RAISE NOTICE 'ALL MACON-BIBB PROBES PASSED';
END $$;
