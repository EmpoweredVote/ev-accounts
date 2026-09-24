-- CA_0245_la_county_supervisors_one_government.sql
--
-- Los Angeles County Board of Supervisors: move the board onto the one County government row and put its five
-- districts on the type and boundary code they actually have. Same fault and same fix as Orange County (CA_0238).
--
-- WHY (measured 2026-09-24)
-- -------------------------
--   1. Two "Los Angeles County, California, US" government rows, both geo_id 06037:
--        841f214e  type 'LOCAL'   the Board of Supervisors (5 seats) + three EMPTY chambers ("County Officers",
--                                 "Office of the District Attorney", "Office of the Sheriff": 0 offices each)
--        4236875b  type 'County'  Countywide Elected Officials (3) + Superior Court (473)
--      CA_0199 retyped sub-county districts only under governments typed 'County', so the supervisors were missed.
--   2. The five supervisor districts are district_type LOCAL, mtfcc X0001 — but their geofences (loaded by
--      scripts/load-la-county-supervisor-boundaries.ts) are mtfcc X0005. The address join ignores
--      districts.mtfcc, so address search worked; two readers do not:
--        electionService.getElectionsByCoordinate  gbo.mtfcc = d.mtfcc  -> LA supervisor races never matched
--        readrankService race frame                 cb.mtfcc = d.mtfcc  -> no map frame for those races
--      No user-visible break today (the only races, the 2026-06-02 D1/D3 primaries, are past the 30-day window;
--      no November supervisor race exists), but the next seeded race would have been invisible by coordinate.
--
-- CHANGES
-- -------
--   1. Chamber 9de1e8c8 (Board of Supervisors) -> government 4236875b.
--   2. Districts 1-5: district_type LOCAL -> COUNTY, mtfcc X0001 -> X0005 (only where the X0005 geofence exists).
--   3. Delete the three empty chambers and the empty 841f214e government (pre-images below).
--   government_bodies needs nothing: its five rows key on the district geo_ids, which do not change.
--
-- PRE-IMAGES of deleted rows
--   essentials.governments (841f214e-6de4-4137-aa18-71b179c56d56, 'Los Angeles County, California, US', type 'LOCAL',
--     state 'CA', city 'Los Angeles County', geo_id '06037')
--   essentials.chambers (government_id 841f214e..., policy_engagement_level 'full', all other columns NULL/empty unless shown):
--     cb7aabfd-5a91-4443-8092-e1ea21f75c70  external_id -100005, 'County Officers' / 'Los Angeles County Officers',
--                                           term_length '4 years', election_frequency '4 years'
--     57aa29c9-f464-40b9-a144-d1107cd5002a  'Office of the District Attorney' / 'Office of the District Attorney'
--     84a66a3a-1b63-4718-9e6e-c59a0201c66e  'Office of the Sheriff' / 'Office of the Sheriff'
--   (No row in offices, meetings.meetings, discovered_sources, source_outlets or _retired_ca0206_offices references
--   the three chambers; only chambers references the government.)
--
-- No migration runner exists; this file records SQL applied by hand.
-- STATUS: NOT APPLIED.
--
-- ROLLBACK: re-insert the pre-image government and chambers; move chamber 9de1e8c8 back to 841f214e; set the five
--   districts back to district_type 'LOCAL', mtfcc 'X0001'.
-- IDEMPOTENT: every statement is guarded on the pre-change state; a re-run changes 0 rows.

BEGIN;

-- ---------------------------------------------------------------------------
-- 0. Pre-flight.
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int; n2 int;
BEGIN
  -- 0a. The County row is the one recorded.
  SELECT count(*) INTO n FROM essentials.governments
   WHERE id = '4236875b-3909-4ae4-ae91-41ae21c07a45' AND type = 'County' AND geo_id = '06037' AND state = 'CA';
  IF n <> 1 THEN RAISE EXCEPTION 'County government 4236875b not as recorded'; END IF;

  -- 0b. The board chamber is on the LOCAL row (first run) or the County row (re-run), with five offices.
  SELECT count(*) INTO n FROM essentials.chambers WHERE id = '9de1e8c8-8f8c-4c6e-a77d-6c41c8d363ab'
     AND name_formal = 'Los Angeles County Board of Supervisors'
     AND government_id IN ('841f214e-6de4-4137-aa18-71b179c56d56', '4236875b-3909-4ae4-ae91-41ae21c07a45');
  SELECT count(*) INTO n2 FROM essentials.offices WHERE chamber_id = '9de1e8c8-8f8c-4c6e-a77d-6c41c8d363ab';
  IF n <> 1 OR n2 <> 5 THEN RAISE EXCEPTION 'board chamber as recorded: %, offices: % (want 1, 5)', n, n2; END IF;

  -- 0c. The three chambers to delete are still empty, and nothing else hangs on the LOCAL government.
  SELECT count(*) INTO n FROM essentials.offices WHERE chamber_id IN
    ('cb7aabfd-5a91-4443-8092-e1ea21f75c70', '57aa29c9-f464-40b9-a144-d1107cd5002a', '84a66a3a-1b63-4718-9e6e-c59a0201c66e');
  SELECT (SELECT count(*) FROM meetings.meetings WHERE chamber_id IN ('cb7aabfd-5a91-4443-8092-e1ea21f75c70', '57aa29c9-f464-40b9-a144-d1107cd5002a', '84a66a3a-1b63-4718-9e6e-c59a0201c66e'))
       + (SELECT count(*) FROM essentials.discovered_sources WHERE chamber_id IN ('cb7aabfd-5a91-4443-8092-e1ea21f75c70', '57aa29c9-f464-40b9-a144-d1107cd5002a', '84a66a3a-1b63-4718-9e6e-c59a0201c66e'))
       + (SELECT count(*) FROM essentials.source_outlets WHERE chamber_id IN ('cb7aabfd-5a91-4443-8092-e1ea21f75c70', '57aa29c9-f464-40b9-a144-d1107cd5002a', '84a66a3a-1b63-4718-9e6e-c59a0201c66e'))
       + (SELECT count(*) FROM essentials.districts WHERE government_id = '841f214e-6de4-4137-aa18-71b179c56d56')
       + (SELECT count(*) FROM essentials.chambers WHERE government_id = '841f214e-6de4-4137-aa18-71b179c56d56'
            AND id NOT IN ('9de1e8c8-8f8c-4c6e-a77d-6c41c8d363ab', 'cb7aabfd-5a91-4443-8092-e1ea21f75c70',
                           '57aa29c9-f464-40b9-a144-d1107cd5002a', '84a66a3a-1b63-4718-9e6e-c59a0201c66e'))
    INTO n2;
  IF n > 0 OR n2 > 0 THEN RAISE EXCEPTION 'rows to delete are referenced: offices %, other %', n, n2; END IF;

  -- 0d. Every supervisor district has its X0005 geofence.
  SELECT count(*) INTO n FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE o.chamber_id = '9de1e8c8-8f8c-4c6e-a77d-6c41c8d363ab'
     AND d.geo_id = 'ocd-division/country:us/state:ca/county:los_angeles/council_district:' || d.district_id
     AND EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb WHERE gb.geo_id = d.geo_id AND gb.mtfcc = 'X0005');
  IF n <> 5 THEN RAISE EXCEPTION 'supervisor districts with an X0005 geofence: % of 5', n; END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Board onto the County government.
-- ---------------------------------------------------------------------------
UPDATE essentials.chambers SET government_id = '4236875b-3909-4ae4-ae91-41ae21c07a45'
 WHERE id = '9de1e8c8-8f8c-4c6e-a77d-6c41c8d363ab' AND government_id = '841f214e-6de4-4137-aa18-71b179c56d56';

-- ---------------------------------------------------------------------------
-- 2. Districts: COUNTY, on the code their geofences carry.
-- ---------------------------------------------------------------------------
UPDATE essentials.districts d SET district_type = 'COUNTY', mtfcc = 'X0005'
  FROM essentials.offices o
 WHERE o.district_id = d.id AND o.chamber_id = '9de1e8c8-8f8c-4c6e-a77d-6c41c8d363ab'
   AND (d.district_type, d.mtfcc) IS DISTINCT FROM ('COUNTY', 'X0005')
   AND EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb WHERE gb.geo_id = d.geo_id AND gb.mtfcc = 'X0005');

-- ---------------------------------------------------------------------------
-- 3. Delete the empty chambers and the empty LOCAL government.
-- ---------------------------------------------------------------------------
DELETE FROM essentials.chambers c
 WHERE c.id IN ('cb7aabfd-5a91-4443-8092-e1ea21f75c70', '57aa29c9-f464-40b9-a144-d1107cd5002a', '84a66a3a-1b63-4718-9e6e-c59a0201c66e')
   AND c.government_id = '841f214e-6de4-4137-aa18-71b179c56d56'
   AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id);

DELETE FROM essentials.governments g
 WHERE g.id = '841f214e-6de4-4137-aa18-71b179c56d56' AND g.type = 'LOCAL'
   AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id)
   AND NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.government_id = g.id);

-- ---------------------------------------------------------------------------
-- 4. Post-verify.
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int; names text;
BEGIN
  -- 4a. One LA County government, carrying the board, the officers and the court.
  SELECT count(*) INTO n FROM essentials.governments WHERE state = 'CA' AND geo_id = '06037';
  IF n <> 1 THEN RAISE EXCEPTION '% governments with geo_id 06037 (want 1)', n; END IF;
  SELECT count(*) INTO n FROM essentials.chambers WHERE government_id = '4236875b-3909-4ae4-ae91-41ae21c07a45'
     AND name_formal IN ('Los Angeles County Board of Supervisors', 'Los Angeles County Countywide Elected Officials', 'Los Angeles County Superior Court');
  IF n <> 3 THEN RAISE EXCEPTION 'County government carries % of the 3 chambers', n; END IF;

  -- 4b. Five held seats, holders unchanged, districts COUNTY / X0005.
  SELECT count(*), string_agg(d.district_id || ':' || p.last_name, ',' ORDER BY d.district_id) INTO n, names
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE o.chamber_id = '9de1e8c8-8f8c-4c6e-a77d-6c41c8d363ab' AND d.district_type = 'COUNTY' AND d.mtfcc = 'X0005';
  IF n <> 5 OR names <> '1:Solis,2:Mitchell,3:Horvath,4:Hahn,5:Barger' THEN
    RAISE EXCEPTION 'board: % seats COUNTY/X0005, holders % (want 5, 1:Solis,2:Mitchell,3:Horvath,4:Hahn,5:Barger)', n, names;
  END IF;

  -- 4c. The election coordinate path now reaches each district's geofence (the join getElectionsByCoordinate uses),
  --     and a point in each reaches only its own supervisor through the address join.
  SELECT count(*) INTO n FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.geofence_boundaries gbo ON gbo.geo_id = d.geo_id AND gbo.mtfcc = d.mtfcc
   WHERE o.chamber_id = '9de1e8c8-8f8c-4c6e-a77d-6c41c8d363ab'
     AND (SELECT count(*) FROM essentials.geofence_boundaries gb
            JOIN essentials.districts d2 ON d2.geo_id = gb.geo_id AND gb.mtfcc LIKE 'X%'
             AND gb.mtfcc NOT IN ('X0001','X0002','X0003','X0004') AND d2.district_type IN ('LOCAL','COUNTY')
            JOIN essentials.offices o2 ON o2.district_id = d2.id AND o2.chamber_id = '9de1e8c8-8f8c-4c6e-a77d-6c41c8d363ab'
           WHERE ST_Covers(gb.geometry, ST_PointOnSurface(gbo.geometry))) = 1;
  IF n <> 5 THEN RAISE EXCEPTION 'race-path + address round trip: % of 5', n; END IF;

  RAISE NOTICE 'OK: LA County Board of Supervisors on the one 06037 County government; 5/5 districts COUNTY on X0005';
END $$;

COMMIT;
