-- CA_0199_county_subdistricts_local_to_county.sql
--
-- Retype the 59 sub-county districts (commissioner precincts, supervisor and council districts) of ten
-- county governments from district_type LOCAL to COUNTY, the type the other 15 county governments already
-- use for the same kind of seat. Give Salt Lake County's three council districts that carry no mtfcc the
-- X0001 their three sibling districts and their geofences carry.
--
-- WHY
-- ---
-- A county's own seats are typed two ways today. Measured 2026-09-23 over every office whose chamber
-- belongs to a governments.type = 'County' row and whose district is not the whole county:
--   COUNTY  138 offices, 15 governments (Allen IN, Dane WI, Racine WI, Miami-Dade, Ramsey MN, ...)
--   LOCAL    59 offices, 10 governments (this file)
-- No reader wants LOCAL for these, and three of them are hurt by it:
--   * essentials frontend (src/lib/groupHierarchy.js, main b1e54bf2): sub-groups key on district_type, so a
--     county chamber that holds both types renders as TWO sub-groups under the SAME heading. Travis County:
--     "Travis County Commissioners Court" (the County Judge, COUNTY) and again "Travis County Commissioners
--     Court" (the four precinct commissioners, LOCAL). Four chambers mix the two types: Travis TX, Horry
--     SC, Salt Lake UT, Washington OR.
--   * readrankService frame lookup: an X-coded COUNTY district frames to its county (G4020); an X-coded
--     LOCAL district frames to the smallest CITY containing it ("city ward -> city"). A commissioner
--     precinct is framed as a ward of whichever city it happens to overlap.
--   * Consistency: the same seat shape reads differently by county in every consumer that branches on
--     COUNTY vs LOCAL (frontend branch badge, election race grouping, Read & Rank).
-- All 59 are county seats (titles Commissioner / Supervisor / Council Member, each on its county's
-- legislative chamber); none of the 59 district rows is used by an office outside these ten chambers.
--
-- WHAT DOES NOT CHANGE
-- --------------------
--   * Address reachability. GEOFENCE_DISTRICT_JOIN and MTFCC_DISTRICT_TYPE_GUARD admit both LOCAL and
--     COUNTY for every X-coded geofence (X0001 explicitly; the rest through the X catch-all), and all 57
--     districts with a geofence are X-coded. Orange County CA's two districts (Supervisor Districts 1 and
--     4) carry OCD geo_ids ('ocd-division/country:us/state:ca/county:orange/council_district:N') with NO
--     geofence behind them, so no address reaches them either way. (Separate gap, not fixed here: that
--     Board of Supervisors holds only these 2 of its 5 seats.)
--   * Compass: the Local Lens auto_district_types is {LOCAL, LOCAL_EXEC, COUNTY}.
--   * Campaign finance: both services bucket LOCAL and COUNTY together.
--   * No office, chamber, government, politician, office_terms or race row.
--
-- WHAT A USER WILL SEE CHANGE
-- ---------------------------
--   * Travis / Horry / Salt Lake / Washington OR: one sub-group per chamber instead of two same-named ones.
--   * Branch badge (essentials src/utils/branchType.js): LOCAL is "Legislative"; COUNTY reads the title —
--     "commission" -> "Executive", "council" -> "Legislative", "supervisor" -> none. Commissioners in El Paso
--     CO, Travis and Washington OR therefore read "Executive", as Allen, Kitsap and the other COUNTY-typed
--     commissioners already do.
--   * Elections view (essentials src/components/ElectionsView.jsx): a COUNTY race whose position reads
--     "<X> County <rest>" groups under "<X> County"; a LOCAL race is its own heading. Five races are on
--     these offices, all 2026-11-03: King County Council Districts 2/4/6 (+1) and Washington County
--     Commissioner District 4. They move under "King County" / "Washington County".
--
-- ORDER — ev-accounts PR #670 MUST BE DEPLOYED FIRST
-- ---------------------------------------------------
-- pickCountyFromDistrictRows used to report the FIRST COUNTY row of an address lookup as the user's county,
-- in politician-id order. Retyping these 59 before that fix would add 10 wrong-county points (King 3,
-- El Paso 1, Horry 1, Richland 1, Travis 1, Washington OR 1, ...) to the 18 that already exist
-- (Miami-Dade, Ramsey, Buncombe, Leon, Racine). #670 requires a 5-digit FIPS geo_id; none of the 59 has
-- one (gate 3d).
--
-- SALT LAKE mtfcc
-- ---------------
-- Council Districts 1/3/5 carry mtfcc X0001; 2/4/6 carry NULL, and all six geofences are X0001. Address
-- matching keys on the geofence's mtfcc, so NULL does not hide them, but readrank's frame lookup reads
-- d.mtfcc and skips a NULL. Set to X0001, guarded on the matching X0001 geofence existing.
--
-- No migration runner exists; this file records SQL applied by hand. No DELETE.
-- STATUS: NOT APPLIED.
--
-- ROLLBACK:
--   UPDATE essentials.districts SET district_type = 'LOCAL'
--    WHERE id IN (SELECT district_id FROM <the ca0199_target list below>);
--   UPDATE essentials.districts SET mtfcc = NULL
--    WHERE id IN ('93846289-81a1-4fee-b161-fc5cf38c6461', 'b78e9348-53c8-4ddb-a1f4-ce7092ce59e6',
--                 'a2775bb7-e570-4ff1-9123-b6dff022bc8c');
-- IDEMPOTENT: both UPDATEs are guarded on the old value; a re-run changes 0 rows and every gate passes.

BEGIN;

-- The 59 districts this file retypes, by fixed id. `county` is for the gates and for humans.
CREATE TEMP TABLE ca0199_target ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('1b9d32e1-3d25-4a7e-a3c5-eaf7aafd83fd'::uuid, 'El Paso County / CO', 'El Paso County Commissioner District 1', 'X0033'),
  ('353f6c87-eb60-4e5f-96a7-eb698db700cc'::uuid, 'El Paso County / CO', 'El Paso County Commissioner District 2', 'X0033'),
  ('f2013f83-e9c4-4fd0-ae31-0cf572f85aa3'::uuid, 'El Paso County / CO', 'El Paso County Commissioner District 3', 'X0033'),
  ('9fef9400-c75a-42de-9abf-ea981ae7e531'::uuid, 'El Paso County / CO', 'El Paso County Commissioner District 4', 'X0033'),
  ('7b11f449-0c63-474f-99bd-b8940f077d21'::uuid, 'El Paso County / CO', 'El Paso County Commissioner District 5', 'X0033'),
  ('b14db65a-73ed-49cb-8967-f0690503e314'::uuid, 'Horry County / SC', 'Horry County Council District 1', 'X0061'),
  ('b143cdfa-3d4e-4627-aa31-f26e96e2fc77'::uuid, 'Horry County / SC', 'Horry County Council District 10', 'X0061'),
  ('e678e816-34ca-46d6-8105-fe8816075888'::uuid, 'Horry County / SC', 'Horry County Council District 11', 'X0061'),
  ('b83d7592-71ec-4c86-8a52-af88f06f306e'::uuid, 'Horry County / SC', 'Horry County Council District 2', 'X0061'),
  ('03a3a8ef-cf96-457e-b275-9b6888aa0ab2'::uuid, 'Horry County / SC', 'Horry County Council District 3', 'X0061'),
  ('6b427a59-9917-4ad8-9c6b-7da3ecd94369'::uuid, 'Horry County / SC', 'Horry County Council District 4', 'X0061'),
  ('4f284756-c11b-4d53-9836-7c762a76218c'::uuid, 'Horry County / SC', 'Horry County Council District 5', 'X0061'),
  ('f9ea21e4-66ac-44d5-94dd-47009e497c88'::uuid, 'Horry County / SC', 'Horry County Council District 6', 'X0061'),
  ('757de0d3-bd5a-47fd-befd-8fb62f4d9523'::uuid, 'Horry County / SC', 'Horry County Council District 7', 'X0061'),
  ('0d9039e4-c22c-4669-b9c0-6007c309e192'::uuid, 'Horry County / SC', 'Horry County Council District 8', 'X0061'),
  ('518cc11a-5e70-4f17-af90-5c6c122a25c2'::uuid, 'Horry County / SC', 'Horry County Council District 9', 'X0061'),
  ('3b0fcaa3-16e6-4ad4-a957-8eeefc5519fd'::uuid, 'King County / WA', 'King County Council District 1', 'X0026'),
  ('0b78bf25-6abb-4faf-a031-45863c3c9de3'::uuid, 'King County / WA', 'King County Council District 2', 'X0026'),
  ('42fa3487-a495-4434-97b4-541c338da89b'::uuid, 'King County / WA', 'King County Council District 3', 'X0026'),
  ('0d7da278-80e3-4540-85fc-b878af21e7b3'::uuid, 'King County / WA', 'King County Council District 4', 'X0026'),
  ('5646e220-bf7b-465e-b06e-603cf82b6a4a'::uuid, 'King County / WA', 'King County Council District 5', 'X0026'),
  ('09487e6f-045e-4460-93cf-a65d3291def6'::uuid, 'King County / WA', 'King County Council District 6', 'X0026'),
  ('660b7063-2c1c-4f07-8f15-8f7420144cd4'::uuid, 'King County / WA', 'King County Council District 7', 'X0026'),
  ('455d1967-3130-4f99-855c-e5a48e3e7790'::uuid, 'King County / WA', 'King County Council District 8', 'X0026'),
  ('756ba853-03f8-49dc-ae14-a3c0f6044a84'::uuid, 'King County / WA', 'King County Council District 9', 'X0026'),
  ('5393320a-27d0-4f51-846d-354717aabf5b'::uuid, 'Orange County / CA', 'District 1', ''),
  ('da597252-46be-452b-b496-bd6e63f9a91e'::uuid, 'Orange County / CA', 'District 4', ''),
  ('f34b2697-d704-4c33-bc56-02cb0db65849'::uuid, 'Pima County / AZ', 'Pima County Supervisor District 1', 'X0019'),
  ('c502a7f5-a209-4b27-bcb7-1c721541209e'::uuid, 'Pima County / AZ', 'Pima County Supervisor District 2', 'X0019'),
  ('42e2b9ea-50fe-4edf-b93a-4fcedbbff395'::uuid, 'Pima County / AZ', 'Pima County Supervisor District 3', 'X0019'),
  ('4207262c-b039-4f07-b5da-3e52fc4ed1fd'::uuid, 'Pima County / AZ', 'Pima County Supervisor District 4', 'X0019'),
  ('c4f8426d-ea35-48a8-b368-cb31b4a3414d'::uuid, 'Pima County / AZ', 'Pima County Supervisor District 5', 'X0019'),
  ('5373513a-6b70-42f7-98fd-63b856753420'::uuid, 'Richland County / SC', 'Richland County Council District 1', 'X0060'),
  ('e5360dbc-0a7f-47e5-aabc-2924c68d92b5'::uuid, 'Richland County / SC', 'Richland County Council District 10', 'X0060'),
  ('b436b630-72d6-4b23-ad6d-b58cda253f2e'::uuid, 'Richland County / SC', 'Richland County Council District 11', 'X0060'),
  ('e658250c-c435-42e6-b925-4056b3f90055'::uuid, 'Richland County / SC', 'Richland County Council District 2', 'X0060'),
  ('71ca057f-1a7c-455d-b151-eb5c9e7fc62f'::uuid, 'Richland County / SC', 'Richland County Council District 3', 'X0060'),
  ('0e679231-a676-400f-b250-9abc460694fd'::uuid, 'Richland County / SC', 'Richland County Council District 4', 'X0060'),
  ('a1f92714-0a8e-415d-8b9c-77d865d6a192'::uuid, 'Richland County / SC', 'Richland County Council District 5', 'X0060'),
  ('d8b3c776-982d-4277-90c0-83e02653cb39'::uuid, 'Richland County / SC', 'Richland County Council District 6', 'X0060'),
  ('e9398aae-4ef7-48d8-b9a8-f3ed7092aa73'::uuid, 'Richland County / SC', 'Richland County Council District 7', 'X0060'),
  ('62959a45-38fb-4088-999e-73c22bb7dff7'::uuid, 'Richland County / SC', 'Richland County Council District 8', 'X0060'),
  ('18726f85-47b0-4e18-a509-b4870cccbb28'::uuid, 'Richland County / SC', 'Richland County Council District 9', 'X0060'),
  ('8e18b5af-84d5-4418-801a-987b3b0da649'::uuid, 'Riverside County / CA', 'Riverside County Supervisor District 1', 'X0021'),
  ('0cd13dbf-71f2-48e7-a6c8-474ec8bcd414'::uuid, 'Riverside County / CA', 'Riverside County Supervisor District 2', 'X0021'),
  ('7ebc1118-4ad9-46f1-889d-4517f9c56946'::uuid, 'Riverside County / CA', 'Riverside County Supervisor District 3', 'X0021'),
  ('64b751d7-5d4b-4b6d-a42f-5be085bdfcfe'::uuid, 'Riverside County / CA', 'Riverside County Supervisor District 4', 'X0021'),
  ('05bdbc53-7c8e-479b-ae18-5ad957b94a32'::uuid, 'Riverside County / CA', 'Riverside County Supervisor District 5', 'X0021'),
  ('93846289-81a1-4fee-b161-fc5cf38c6461'::uuid, 'Salt Lake County / ut', 'Council District 2', NULL),
  ('b78e9348-53c8-4ddb-a1f4-ce7092ce59e6'::uuid, 'Salt Lake County / ut', 'Council District 4', NULL),
  ('a2775bb7-e570-4ff1-9123-b6dff022bc8c'::uuid, 'Salt Lake County / ut', 'Council District 6', NULL),
  ('8def1425-c5dc-48f9-a1d9-5afe20a5faa2'::uuid, 'Travis County / TX', 'Travis County Commissioner Precinct 1', 'X0031'),
  ('8ef18c85-ffb5-4e9b-8dab-4bea1427b037'::uuid, 'Travis County / TX', 'Travis County Commissioner Precinct 2', 'X0031'),
  ('b8a30e7e-bce9-4fbc-a241-78aad620a95e'::uuid, 'Travis County / TX', 'Travis County Commissioner Precinct 3', 'X0031'),
  ('b194440e-9c9c-46d0-a830-098a9fa429fd'::uuid, 'Travis County / TX', 'Travis County Commissioner Precinct 4', 'X0031'),
  ('01bd5c5d-c873-4f1b-b444-01dff7a4bb12'::uuid, 'Washington County / OR', 'Washington County Commissioner District 1', 'X0018'),
  ('ede0beef-3977-45cc-9e90-959e4938c6a6'::uuid, 'Washington County / OR', 'Washington County Commissioner District 2', 'X0018'),
  ('cc0b9b42-41f0-416a-b2e8-66b6e2e42f30'::uuid, 'Washington County / OR', 'Washington County Commissioner District 3', 'X0018'),
  ('d415a86d-251e-4528-b80a-f3340240aba9'::uuid, 'Washington County / OR', 'Washington County Commissioner District 4', 'X0018')
) AS v(district_id, county, label, mtfcc);

-- Pre-image of every OTHER district's type, for the post-verify. Only (type, count) — 200k+ rows is
-- more than a snapshot needs; a count per type catches any stray change.
CREATE TEMP TABLE ca0199_type_counts ON COMMIT DROP AS
SELECT district_type, count(*) AS n
  FROM essentials.districts
 WHERE id NOT IN (SELECT district_id FROM ca0199_target)
 GROUP BY district_type;

-- ---------------------------------------------------------------------------
-- 0. Pre-flight. Refuse to run against a state this file was not written for.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  n_found int; n_bad int; n_foreign int; n_untracked int; n_fips int; n_gov int;
BEGIN
  -- 0a. All 59 exist with the label and mtfcc recorded above, typed LOCAL (first run) or COUNTY (re-run).
  SELECT count(d.id),
         count(d.id) FILTER (WHERE d.label IS DISTINCT FROM t.label
                               OR d.district_type NOT IN ('LOCAL', 'COUNTY')
                               OR (COALESCE(d.mtfcc, '') IS DISTINCT FROM COALESCE(t.mtfcc, '')
                                   AND NOT (t.county LIKE 'Salt Lake%' AND d.mtfcc = 'X0001')))
    INTO n_found, n_bad
    FROM ca0199_target t LEFT JOIN essentials.districts d ON d.id = t.district_id;
  IF n_found <> 59 OR n_bad > 0 THEN
    RAISE EXCEPTION 'targets: % of 59 found, % not as recorded (label / type / mtfcc)', n_found, n_bad;
  END IF;

  -- 0b. Every office on a target district sits on a chamber of a County-type government, and the
  --     ten governments are the ones named.
  SELECT count(*) FILTER (WHERE g.type IS DISTINCT FROM 'County'),
         count(DISTINCT g.id)
    INTO n_foreign, n_gov
    FROM ca0199_target t
    JOIN essentials.offices o ON o.district_id = t.district_id
    LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id;
  IF n_foreign > 0 OR n_gov <> 10 THEN
    RAISE EXCEPTION 'target offices: % outside a County government, % governments (want 0, 10)', n_foreign, n_gov;
  END IF;

  -- 0c. No OTHER LOCAL district sits under a County-type government's chamber (a new one would be left
  --     behind by this fixed list).
  SELECT count(DISTINCT d.id) INTO n_untracked
    FROM essentials.governments g
    JOIN essentials.chambers ch ON ch.government_id = g.id
    JOIN essentials.offices o ON o.chamber_id = ch.id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.type = 'County' AND d.district_type = 'LOCAL'
     AND d.id NOT IN (SELECT district_id FROM ca0199_target);
  IF n_untracked > 0 THEN
    RAISE EXCEPTION '% LOCAL district(s) under a County government are not in this file''s list', n_untracked;
  END IF;

  -- 0d. None of the 59 carries a county FIPS geo_id (they are seats, not the county; PR #670 relies on it).
  SELECT count(*) INTO n_fips
    FROM ca0199_target t JOIN essentials.districts d ON d.id = t.district_id
   WHERE d.geo_id ~ '^\d{5}$';
  IF n_fips > 0 THEN
    RAISE EXCEPTION '% target district(s) carry a 5-digit geo_id', n_fips;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Retype.
-- ---------------------------------------------------------------------------
UPDATE essentials.districts d
   SET district_type = 'COUNTY'
  FROM ca0199_target t
 WHERE d.id = t.district_id
   AND d.district_type = 'LOCAL';

-- ---------------------------------------------------------------------------
-- 2. Salt Lake County Council Districts 2/4/6: mtfcc NULL -> X0001, only where the X0001 geofence exists.
-- ---------------------------------------------------------------------------
UPDATE essentials.districts d
   SET mtfcc = 'X0001'
  FROM ca0199_target t
 WHERE d.id = t.district_id
   AND t.county LIKE 'Salt Lake%'
   AND d.mtfcc IS NULL
   AND EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb WHERE gb.geo_id = d.geo_id AND gb.mtfcc = 'X0001');

-- ---------------------------------------------------------------------------
-- 3. Post-verify. Any wrong count aborts.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  n_county int; n_local_left int; n_mixed int; n_slc int; n_other_changed int; n_fence_bad int; n_admissible int;
BEGIN
  -- 3a. All 59 are COUNTY.
  SELECT count(*) INTO n_county
    FROM ca0199_target t JOIN essentials.districts d ON d.id = t.district_id
   WHERE d.district_type = 'COUNTY';
  IF n_county <> 59 THEN
    RAISE EXCEPTION 'retyped: % of 59 are COUNTY', n_county;
  END IF;

  -- 3b. No LOCAL district is left under a County-type government's chamber.
  SELECT count(DISTINCT d.id) INTO n_local_left
    FROM essentials.governments g
    JOIN essentials.chambers ch ON ch.government_id = g.id
    JOIN essentials.offices o ON o.chamber_id = ch.id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.type = 'County' AND d.district_type = 'LOCAL';
  IF n_local_left > 0 THEN
    RAISE EXCEPTION '% LOCAL district(s) left under a County government', n_local_left;
  END IF;

  -- 3c. The frontend contract: no chamber touched here mixes LOCAL with COUNTY any more.
  SELECT count(*) INTO n_mixed
    FROM (SELECT o.chamber_id
            FROM essentials.offices o
            JOIN essentials.districts d ON d.id = o.district_id
           WHERE o.chamber_id IN (SELECT o2.chamber_id FROM essentials.offices o2
                                   WHERE o2.district_id IN (SELECT district_id FROM ca0199_target))
             AND d.district_type IN ('LOCAL', 'COUNTY')
           GROUP BY o.chamber_id
          HAVING count(DISTINCT d.district_type) > 1) x;
  IF n_mixed > 0 THEN
    RAISE EXCEPTION '% chamber(s) still mix LOCAL and COUNTY', n_mixed;
  END IF;

  -- 3d. Salt Lake: all six council districts carry X0001.
  SELECT count(*) INTO n_slc
    FROM essentials.districts d
   WHERE d.geo_id LIKE 'ocd-division/country:us/state:ut/county:salt_lake/council_district:%'
     AND d.district_type = 'COUNTY' AND d.mtfcc = 'X0001';
  IF n_slc <> 6 THEN
    RAISE EXCEPTION 'Salt Lake council districts on X0001 / COUNTY: % (want 6)', n_slc;
  END IF;

  -- 3e. Every target that has geography (57; Orange County's two OCD geo_ids have no geofence) sits on a
  --     geofence the address join admits for COUNTY: an X-coded layer other than X0002/X0003/X0004.
  SELECT count(*) FILTER (WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb
                                         WHERE gb.geo_id = d.geo_id AND gb.mtfcc LIKE 'X%'
                                           AND gb.mtfcc NOT IN ('X0002', 'X0003', 'X0004'))),
         count(*) FILTER (WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb WHERE gb.geo_id = d.geo_id)
                            AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb
                                             WHERE gb.geo_id = d.geo_id AND gb.mtfcc LIKE 'X%'
                                               AND gb.mtfcc NOT IN ('X0002', 'X0003', 'X0004')))
    INTO n_admissible, n_fence_bad
    FROM ca0199_target t JOIN essentials.districts d ON d.id = t.district_id;
  IF n_admissible <> 57 OR n_fence_bad > 0 THEN
    RAISE EXCEPTION 'retyped districts on an admissible geofence: % (want 57), % on an inadmissible one', n_admissible, n_fence_bad;
  END IF;

  -- 3f. No other district changed type.
  SELECT count(*) INTO n_other_changed
    FROM ((SELECT district_type, count(*) AS n FROM essentials.districts
            WHERE id NOT IN (SELECT district_id FROM ca0199_target) GROUP BY district_type
           EXCEPT SELECT * FROM ca0199_type_counts)
          UNION ALL
          (SELECT * FROM ca0199_type_counts
           EXCEPT SELECT district_type, count(*) FROM essentials.districts
                   WHERE id NOT IN (SELECT district_id FROM ca0199_target) GROUP BY district_type)) x;
  IF n_other_changed > 0 THEN
    RAISE EXCEPTION 'other districts changed type (% differing type counts)', n_other_changed;
  END IF;

  RAISE NOTICE 'OK: 59 sub-county districts in 10 county governments are COUNTY; 0 LOCAL left under County governments; 0 mixed chambers; Salt Lake 6/6 on X0001';
END $$;

COMMIT;
