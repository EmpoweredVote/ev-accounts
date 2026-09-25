-- CA_0288_me_city_school_boards_to_school_districts.sql
-- Portland, Augusta and Westbrook (Maine): give each city's school board a SCHOOL district on its TIGER school-
-- district polygon (G5420), and move the 25 school-board offices onto it from the city's LOCAL district.
--
-- WHY. These 25 offices were filed on the city's LOCAL district (G4110 city polygon), the same district that carries
-- the council and mayor:
--   Portland  f58183f6 (G4110 2360545)  9 offices "School Board Member (...)"          9 held
--   Augusta   16002e5c (G4110 2302100)  9 offices "School Committee Member (...)" + "School Board Chair"   0 held
--   Westbrook 0851d8d6 (G4110 2382105)  7 offices "School Board Member (...)"          0 held
-- The compass `school` level (CA_0256) applies only to district_type SCHOOL, and topicApplicability returns level
-- null for a school board on a LOCAL district (SCHOOL_BOARD_OFFICE_RE), so none of these can be researched.
-- Re-typing the city districts to SCHOOL is NOT an option: GEOFENCE_DISTRICT_JOIN (districtQueries.ts) and
-- MTFCC_DISTRICT_TYPE_GUARD (geoIdGuard.ts) match G4110 only to LOCAL/LOCAL_EXEC, so the council and mayor would
-- become unreachable by address. A SCHOOL district on the G5420 polygon is reached by the existing
-- `G5400/G5410/G5420 -> SCHOOL` clause; no code change is needed.
--
-- PREREQUISITE: the three G5420 polygons must be in essentials.geofence_boundaries. Load them first with
--   npx tsx scripts/load-me-school-boundaries.ts      (TIGER 2024 UNSD, source 'tiger_unsd_me_2024')
-- which now carries 2309930 Portland, 2302640 Augusta, 2313560 Westbrook. The pre-flight fails without them.
--
-- WHAT THIS FILE DOES.
--   1. Inserts 3 SCHOOL districts (state 'me', mtfcc G5420, geo_id = the TIGER GEOID), labelled with the school
--      unit's name so topicApplicability reads them as `school`.
--   2. Moves the 25 pinned offices: offices.district_id only. The office rows keep their ids, so their office_terms
--      (keyed on office_id) move with them unchanged -- Portland's 9 held terms included. The chambers stay where
--      they are (under the city government), so browse-by-government still lists each board under its city, as the
--      city elects it.
-- NOT TOUCHED: the council and mayor offices, the city districts, governments, chambers, people, terms.
-- offices_missing_terms does not move (same offices, same terms).
--
-- SEEDING GAP, NOT FIXED HERE: Augusta and Westbrook hold no one on ANY office -- council, mayor or school board --
-- all flagged is_vacant with no term. That is unknown occupancy, not a vacancy. No holder is invented here.
--
-- No migration runner exists; this file records SQL applied by hand.
-- STATUS: APPLIED to prod 2026-09-24 (operator approval: Chris Andrews), after load-me-school-boundaries.ts (3 inserted,
--   5 already present) and CA_0287. Verified after: SCHOOL districts hold 9 / 9 / 7, city districts 9 / 9 / 8, a re-run
--   inside BEGIN ... ROLLBACK moved nothing, check:reachability at baseline, buildDistrictQuery at each city hall returns
--   the city district and the SCHOOL district. Before that: dry run (BEGIN ... ROLLBACK, polygons loaded inside) 2026-09-24:
--   gates pass, a re-run is a no-op, a planted district on 2309930 trips the pre-flight. Each school polygon equals its
--   city polygon (intersection = 100% of both). buildDistrictQuery at each city hall then returned the city district
--   (council + mayor) AND the new SCHOOL district; Lewiston returned only its SCHOOL board, no phantom seats.
--
-- ROLLBACK: UPDATE essentials.offices SET district_id = <old city district> for the 25 ids below, then
--   DELETE FROM essentials.districts WHERE district_type = 'SCHOOL' AND geo_id IN ('2309930','2302640','2313560');
-- IDEMPOTENT: a re-run finds the districts present and every office already moved; it changes nothing and every
-- gate still passes.

BEGIN;

SET LOCAL lock_timeout = '10s';

-- ─── The move set (pinned) ───────────────────────────────────────────────────────────────────────
CREATE TEMP TABLE _unit (geo_id text PRIMARY KEY, label text NOT NULL, ocd_slug text NOT NULL,
                         city_district uuid NOT NULL, school_chamber uuid NOT NULL,
                         n_school int NOT NULL, n_city int NOT NULL) ON COMMIT DROP;
INSERT INTO _unit VALUES
  ('2309930', 'Portland Public Schools',     'portland_public_schools',     'f58183f6-1cd3-4184-81c4-a624093d00ed', '8f3877bd-121e-4bb9-8634-16c26a6fcdcb', 9, 9),
  ('2302640', 'Augusta Public Schools',      'augusta_public_schools',      '16002e5c-8b08-4d80-815d-9322d7c8feb0', '72043e44-0711-4648-9367-7e0e6f6ebf97', 9, 9),
  ('2313560', 'Westbrook School Department', 'westbrook_school_department', '0851d8d6-00c2-4fcc-ad3f-5e0b7771fccb', '146db7f7-9b7a-44b6-a0f7-e22d5cc39492', 7, 8);

CREATE TEMP TABLE _mv (office_id uuid PRIMARY KEY, geo_id text NOT NULL, title text NOT NULL) ON COMMIT DROP;
INSERT INTO _mv VALUES
  ('c1b37966-430c-451d-8595-8ee889126f66', '2309930', 'School Board Member (At-Large 1)'),
  ('5ba8054c-3170-4c4e-b59b-28fa21c77d49', '2309930', 'School Board Member (At-Large 2)'),
  ('27293ab6-19cc-49b4-9e7b-b1388156d75a', '2309930', 'School Board Member (At-Large 3)'),
  ('f22bc07a-6cc1-4701-a40d-d83957d037de', '2309930', 'School Board Member (At-Large 4)'),
  ('ccabbc96-8704-4ffd-99df-bec76b582ff3', '2309930', 'School Board Member (District 1)'),
  ('0f7814bc-39a1-413a-8446-fc6827e33a95', '2309930', 'School Board Member (District 2)'),
  ('73597ba4-718d-4377-baaa-c3e52306e108', '2309930', 'School Board Member (District 3)'),
  ('079fe469-a734-4fec-9a1d-658cdffaf81e', '2309930', 'School Board Member (District 4)'),
  ('a323f87d-0e85-47c3-b569-de10e9680fb2', '2309930', 'School Board Member (District 5)'),
  ('19fc2b5d-8e16-4556-87fb-7c41d255e95c', '2302640', 'School Board Chair'),
  ('81e8321e-f194-4e4d-9d38-c2cbb7e84d27', '2302640', 'School Committee Member (At-Large 1)'),
  ('7919d61f-4830-4d7d-a017-f8fa42740373', '2302640', 'School Committee Member (At-Large 2)'),
  ('8d588d59-d9ca-425b-bbc1-bf533f41c42e', '2302640', 'School Committee Member (At-Large 3)'),
  ('3182b209-4812-4540-af46-0b9338254b0e', '2302640', 'School Committee Member (At-Large 4)'),
  ('204a5bd2-824b-4c21-bc91-7441fca82f7d', '2302640', 'School Committee Member (Ward 1)'),
  ('b2a3f1ee-f8e0-4288-9192-3e1ee794cdfb', '2302640', 'School Committee Member (Ward 2)'),
  ('178356ab-deab-4a59-bae8-0eeeb71d6e9a', '2302640', 'School Committee Member (Ward 3)'),
  ('0eafec3a-197c-4077-ab7f-cf0f5485f27e', '2302640', 'School Committee Member (Ward 4)'),
  ('293cc9b3-bf32-4e7a-8440-e09c4a3c138a', '2313560', 'School Board Member (At-Large 1)'),
  ('72695dcc-2a50-44f1-905d-54c472019c51', '2313560', 'School Board Member (At-Large 2)'),
  ('1c5afa63-8243-4e0a-83fb-2eb2a990a0bf', '2313560', 'School Board Member (Ward 1)'),
  ('a05e44b3-6ea1-4220-ae66-9b0b8d49ac93', '2313560', 'School Board Member (Ward 2)'),
  ('8b0e158a-1d28-41f9-9268-cee05ce1d36d', '2313560', 'School Board Member (Ward 3)'),
  ('e127a75d-eb9f-4d19-917b-1e21147f3133', '2313560', 'School Board Member (Ward 4)'),
  ('6d54094e-ae05-43a4-a26c-6d8a7fa65304', '2313560', 'School Board Member (Ward 5)');

CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.offices) AS offices,
       (SELECT count(*) FROM essentials.office_terms) AS terms,
       (SELECT count(*) FROM essentials.offices_missing_terms) AS missing_terms,
       (SELECT count(*) FROM essentials.office_current_holder och JOIN _mv ON _mv.office_id = och.office_id
         WHERE och.politician_id IS NOT NULL) AS held,
       (SELECT md5(string_agg(t::text, '|' ORDER BY t.id)) FROM essentials.office_terms t
          JOIN _mv ON _mv.office_id = t.office_id) AS terms_md5;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_bad text;
BEGIN
  -- the polygons are loaded (scripts/load-me-school-boundaries.ts)
  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries gb JOIN _unit u ON u.geo_id = gb.geo_id
   WHERE gb.mtfcc = 'G5420' AND gb.state = '23' AND gb.geometry IS NOT NULL;
  IF v_n <> 3 THEN RAISE EXCEPTION 'PRE: % of 3 G5420 polygons present -- run scripts/load-me-school-boundaries.ts first', v_n; END IF;

  -- no other district already sits on these geo_ids (a second one would double every office found there)
  SELECT string_agg(d.id::text || ' ' || d.district_type, ', ') INTO v_bad FROM essentials.districts d JOIN _unit u ON u.geo_id = d.geo_id
   WHERE NOT (d.district_type = 'SCHOOL' AND d.label = u.label);
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'PRE: unexpected district(s) already on a target geo_id: %', v_bad; END IF;

  -- each office is the reviewed one, in its school chamber, on its city district (first run) or already moved
  SELECT count(*) INTO v_n FROM _mv
    JOIN _unit u ON u.geo_id = _mv.geo_id
    JOIN essentials.offices o ON o.id = _mv.office_id AND o.title = _mv.title AND o.chamber_id = u.school_chamber
    LEFT JOIN essentials.districts nd ON nd.id = o.district_id
   WHERE o.district_id = u.city_district OR (nd.district_type = 'SCHOOL' AND nd.geo_id = u.geo_id);
  IF v_n <> 25 THEN RAISE EXCEPTION 'PRE: only % of 25 offices match their reviewed title/chamber/district', v_n; END IF;

  -- the school chambers hold exactly these offices, and no school-board title is left behind on a city district
  SELECT count(*) INTO v_n FROM essentials.offices o JOIN _unit u ON u.school_chamber = o.chamber_id;
  IF v_n <> 25 THEN RAISE EXCEPTION 'PRE: the 3 school chambers hold % offices, expected 25', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.offices o JOIN _unit u ON u.city_district = o.district_id
   WHERE o.id NOT IN (SELECT office_id FROM _mv) AND o.title ~* '\mschool\M|board of (public )?education';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % unpinned school office(s) on the city districts', v_n; END IF;
END $$;

-- ─── 1. SCHOOL districts ─────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.districts (id, label, district_type, state, mtfcc, geo_id, ocd_id, representation_basis)
SELECT gen_random_uuid(), u.label, 'SCHOOL', 'me', 'G5420', u.geo_id,
       'ocd-division/country:us/state:me/school_district:' || u.ocd_slug, 'residency'
  FROM _unit u
 WHERE NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.geo_id = u.geo_id AND d.district_type = 'SCHOOL');

-- ─── 2. Move the offices (terms follow: they are keyed on office_id) ─────────────────────────────
UPDATE essentials.offices o
   SET district_id = nd.id
  FROM _mv
  JOIN _unit u ON u.geo_id = _mv.geo_id
  JOIN essentials.districts nd ON nd.geo_id = u.geo_id AND nd.district_type = 'SCHOOL'
 WHERE o.id = _mv.office_id
   AND o.district_id = u.city_district;

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_md5 text; b record; r record;
BEGIN
  SELECT * INTO b FROM _before;

  FOR r IN SELECT u.*, (SELECT d.id FROM essentials.districts d WHERE d.geo_id = u.geo_id AND d.district_type = 'SCHOOL') AS sd
             FROM _unit u LOOP
    IF r.sd IS NULL THEN RAISE EXCEPTION 'POST: no SCHOOL district for %', r.geo_id; END IF;
    SELECT count(*) INTO v_n FROM essentials.districts WHERE geo_id = r.geo_id;
    IF v_n <> 1 THEN RAISE EXCEPTION 'POST: % districts on geo_id %, expected 1', v_n, r.geo_id; END IF;
    SELECT count(*) INTO v_n FROM essentials.offices WHERE district_id = r.sd;
    IF v_n <> r.n_school THEN RAISE EXCEPTION 'POST: % holds % offices, expected %', r.label, v_n, r.n_school; END IF;
    -- the city keeps its council and mayor, and nothing else
    SELECT count(*) INTO v_n FROM essentials.offices WHERE district_id = r.city_district;
    IF v_n <> r.n_city THEN RAISE EXCEPTION 'POST: city district % holds % offices, expected %', r.city_district, v_n, r.n_city; END IF;
    SELECT count(*) INTO v_n FROM essentials.offices WHERE district_id = r.city_district AND chamber_id = r.school_chamber;
    IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % school office(s) still on city district %', v_n, r.city_district; END IF;
    -- the school polygon reaches the city: a point inside the city polygon is inside the school polygon too
    SELECT count(*) INTO v_n
      FROM essentials.geofence_boundaries c
      JOIN essentials.districts cd ON cd.id = r.city_district AND c.geo_id = cd.geo_id AND c.mtfcc = 'G4110'
      JOIN essentials.geofence_boundaries s ON s.geo_id = r.geo_id AND s.mtfcc = 'G5420'
     WHERE ST_Covers(s.geometry, ST_PointOnSurface(c.geometry));
    IF v_n <> 1 THEN RAISE EXCEPTION 'POST: the % polygon does not cover a point inside its city', r.label; END IF;
  END LOOP;

  -- terms moved with their offices, byte for byte; nothing else changed size
  SELECT md5(string_agg(t::text, '|' ORDER BY t.id)) INTO v_md5 FROM essentials.office_terms t JOIN _mv ON _mv.office_id = t.office_id;
  IF v_md5 IS DISTINCT FROM b.terms_md5 THEN RAISE EXCEPTION 'POST: the moved offices'' terms changed'; END IF;
  SELECT count(*) INTO v_n FROM essentials.office_current_holder och JOIN _mv ON _mv.office_id = och.office_id WHERE och.politician_id IS NOT NULL;
  IF v_n <> b.held OR v_n <> 9 THEN RAISE EXCEPTION 'POST: % held seats among the moved offices, expected 9 (all Portland)', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.offices;
  IF v_n <> b.offices THEN RAISE EXCEPTION 'POST: offices % -> %', b.offices, v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms;
  IF v_n <> b.terms THEN RAISE EXCEPTION 'POST: office_terms % -> %', b.terms, v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.offices_missing_terms;
  IF v_n <> b.missing_terms THEN RAISE EXCEPTION 'POST: offices_missing_terms % -> %', b.missing_terms, v_n; END IF;

  RAISE NOTICE 'CA_0288 applied: 3 SCHOOL districts (Portland, Augusta, Westbrook); 25 school-board offices moved off the city districts';
END $$;

COMMIT;
