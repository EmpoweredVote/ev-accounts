-- 1498_ut_city_council_address_reachability.sql
--
-- USER-VISIBLE OUTAGE FIX. In six of Utah's largest cities -- Salt Lake City, Provo, Ogden, Sandy,
-- West Jordan, West Valley City (~760k residents) -- address search returns NO district council
-- member. Verified by running the real resolveOfficialsAtPoint join
-- (backend/src/lib/essentialsService.ts:722-776) against each city-hall coordinate: Salt Lake City
-- returned the Mayor alone; the others returned Mayor + At-Large only. Murray, which is healthy,
-- correctly returns its LOCAL "Murray City Council, District 3" alongside the Mayor.
--
-- CAUSE: geography and occupancy live on two DIFFERENT districts rows per seat.
--
--   LIVE row  geo_id/ocd_id = .../place:<city>/council_district:N
--             active holder, all the stances, chamber_id set, seats NULL,
--             and NO geofence_boundaries row -- so it never enters the ST_Covers join
--   GEO row   geo_id/ocd_id = .../place:<city>/ward:N
--             owns the real polygon (mtfcc X0001, source ugrc_sgid_2026, valid, 47-1015 points),
--             seats=1, holds the contacts, but its holder is a DUPLICATE politician row with
--             is_active=false
--
-- The address query ends `AND (p.is_active = true OR o.is_vacant = true)`, so BOTH halves fail
-- independently: the row with the polygon is filtered for having an inactive holder, and the row
-- with the real holder has no polygon to match. Neither row is individually broken enough for any
-- existing guard to flag, which is why this survived.
--
-- WHY ward:N IS THE SURVIVING KEY -- durability, not aesthetics. backend/data/arcgis_sources.json
-- defines every UT city council layer as layer_class 'city_ward', mtfcc X0001, geo_id_template
-- 'ocd-division/country:us/state:ut/place:<city>/ward:{N}'; load-arcgis-from-config.ts:128 sets
-- ocd_id = geo_id and inserts ON CONFLICT (geo_id, mtfcc) DO NOTHING. So ward:N is what the
-- importer RE-ASSERTS on every run -- re-keying the geofences to council_district:N would be undone
-- (or duplicated) by the next UGRC import. Confirmed from the other side too: 10 UT cities are
-- ALREADY healthy in exactly this shape (Cottonwood Heights, Herriman, Holladay, Midvale,
-- Millcreek, Murray, Riverton, South Jordan, South Salt Lake, Taylorsville -- 47 seats where the
-- ward:N district holds BOTH the polygon and an active holder). Same method as migration 1496:
-- let the non-duplicated peers settle the shape.
--
-- 28 seats in scope: 26 MERGE+DELETE and 2 REPOINT-ONLY. The two repoint-only seats are Salt Lake
-- City districts 4 and 5, which are half-migrated hybrids carrying ocd_id=ward:N with
-- geo_id=council_district:N and have no ward twin district at all -- that is precisely why the SLC
-- city-hall point, which sits inside the ward:4 polygon, matched ZERO districts.
--
-- ORDER IS LOAD-BEARING. essentials.districts has NO inbound foreign keys -- offices.district_id is
-- a bare column. Deleting a district is therefore neither blocked nor cascaded; it would silently
-- ORPHAN any office still pointing at it. So: delete GEO offices, then GEO districts, and only
-- then repoint the LIVE district's geo_id. Repointing last also avoids ever having two LOCAL rows
-- share geo_id=ward:N inside the transaction, which would fan the ST_Covers join out.
--
-- Retired politician rows are left is_active=false and undeleted -- reversible, and invisible per
-- ADR 0002 once their term is gone (same call as 1496).
--
-- NOT in scope, deliberately: At-Large / Citywide offices are mis-parented to the LOCAL_EXEC
-- "<City> Mayor" district instead of the LOCAL "<City> City Council" district. Those ARE currently
-- address-reachable (the place-level G4110 geofence joins to LOCAL_EXEC too,
-- essentialsService.ts:738), so that is a district_type defect, not an outage. Separate migration,
-- together with the stale SLC geofence names (ward:4 is still named "Eva Lopez", ward:5 "Darin
-- Mano" -- neither holds that seat any more).
--
-- Idempotent: the mapping selects only rows still in the pre-fix shape, so on a re-run it maps
-- nothing and every UPDATE/DELETE below joins to zero rows. The pre-flight therefore accepts a
-- mapping of EITHER 28 (not yet applied) or 0 (already applied) and aborts on anything else, which
-- would mean a partial application. The post-verify gate deliberately asserts the END STATE from
-- the database rather than counting the delta, so it is meaningful in both cases.

BEGIN;

CREATE TEMP TABLE _ut_seat_map (
  place      text,
  n          int,
  live_dist  uuid,
  geo_dist   uuid,
  ward_key   text
) ON COMMIT DROP;

INSERT INTO _ut_seat_map (place, n, live_dist, geo_dist, ward_key)
WITH live AS (
  SELECT d.id,
         regexp_replace(d.geo_id, '^.*/place:([a-z_]+)/council_district:[0-9]+$', '\1') AS place,
         regexp_replace(d.geo_id, '^.*/council_district:([0-9]+)$', '\1')::int          AS n
    FROM essentials.districts d
   WHERE lower(d.state) = 'ut'
     AND d.district_type = 'LOCAL'
     AND d.geo_id ~ '/place:[a-z_]+/council_district:[0-9]+$'
), geo AS (
  SELECT d.id,
         regexp_replace(d.geo_id, '^.*/place:([a-z_]+)/ward:[0-9]+$', '\1') AS place,
         regexp_replace(d.geo_id, '^.*/ward:([0-9]+)$', '\1')::int          AS n
    FROM essentials.districts d
   WHERE lower(d.state) = 'ut'
     AND d.district_type = 'LOCAL'
     AND d.geo_id ~ '/place:[a-z_]+/ward:[0-9]+$'
)
SELECT l.place, l.n, l.id, g.id,
       format('ocd-division/country:us/state:ut/place:%s/ward:%s', l.place, l.n)
  FROM live l
  LEFT JOIN geo g ON g.place = l.place AND g.n = l.n;

-- ── pre-flight: refuse to run if the mapping does not describe reality ──────────────────
DO $$
DECLARE v_n int; v_bad int;
BEGIN
  SELECT count(*) INTO v_n FROM _ut_seat_map;
  -- 28 = not yet applied; 0 = already applied (re-run). Anything else means a PARTIAL application,
  -- which must not be papered over.
  IF v_n NOT IN (0, 28) THEN
    RAISE EXCEPTION '1498: mapped % seats -- expected 28 (fresh) or 0 (re-run); partial state, aborting', v_n;
  END IF;
  IF v_n = 0 THEN
    RAISE NOTICE '1498: already applied -- all statements will match zero rows; gate still verifies end state';
  END IF;

  -- every target ward key must have exactly one polygon, or we would repoint a district at nothing
  SELECT count(*) INTO v_bad
    FROM _ut_seat_map m
   WHERE (SELECT count(*) FROM essentials.geofence_boundaries gb WHERE gb.geo_id = m.ward_key) <> 1;
  IF v_bad > 0 THEN
    RAISE EXCEPTION '1498: % ward keys do not resolve to exactly one geofence', v_bad;
  END IF;

  -- NEVER delete a seat that is actually occupied: no GEO-side office may have an active holder
  SELECT count(*) INTO v_bad
    FROM _ut_seat_map m
    JOIN essentials.offices o ON o.district_id = m.geo_dist
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE p.is_active;
  IF v_bad > 0 THEN
    RAISE EXCEPTION '1498: % ward-side offices have an ACTIVE holder -- aborting', v_bad;
  END IF;

  -- and no GEO-side office may carry a race (races.office_id is ON DELETE NO ACTION)
  SELECT count(*) INTO v_bad
    FROM _ut_seat_map m
    JOIN essentials.offices o ON o.district_id = m.geo_dist
    JOIN essentials.races r ON r.office_id = o.id;
  IF v_bad > 0 THEN
    RAISE EXCEPTION '1498: % ward-side offices carry a race -- aborting', v_bad;
  END IF;
END $$;

-- 1. Move the contact rows -- the only data the ward side holds that the live side lacks.
UPDATE essentials.politician_contacts pc
   SET politician_id = live_p.politician_id
  FROM _ut_seat_map m
  JOIN essentials.offices go ON go.district_id = m.geo_dist
  JOIN essentials.office_current_holder goch ON goch.office_id = go.id
  JOIN essentials.offices lo ON lo.district_id = m.live_dist
  JOIN essentials.office_current_holder live_p ON live_p.office_id = lo.id
 WHERE pc.politician_id = goch.politician_id
   AND live_p.politician_id IS NOT NULL;

-- 2. Carry seats=1 from the ward-side office onto the surviving office.
UPDATE essentials.offices lo
   SET seats = 1
  FROM _ut_seat_map m
 WHERE lo.district_id = m.live_dist
   AND lo.seats IS NULL
   AND EXISTS (SELECT 1 FROM essentials.offices go
                WHERE go.district_id = m.geo_dist AND go.seats = 1);

-- 3. Drop the duplicate ward-side terms, then the ward-side offices.
DELETE FROM essentials.office_terms t
 USING _ut_seat_map m, essentials.offices o
 WHERE o.district_id = m.geo_dist
   AND t.office_id = o.id;

DELETE FROM essentials.offices o
 USING _ut_seat_map m
 WHERE o.district_id = m.geo_dist
   AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id)
   AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.office_id = o.id);

-- 4. Drop the now-empty ward districts. MUST happen before the repoint below, because
--    districts.geo_id is not unique: two LOCAL rows sharing ward:N would fan the join out.
DELETE FROM essentials.districts d
 USING _ut_seat_map m
 WHERE d.id = m.geo_dist
   AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id);

-- 5. Point the surviving district at the polygon. Set ocd_id too, so the row is self-consistent
--    and matches what load-arcgis-from-config.ts writes (ocd_id = geo_id).
UPDATE essentials.districts d
   SET geo_id = m.ward_key,
       ocd_id = m.ward_key
  FROM _ut_seat_map m
 WHERE d.id = m.live_dist;

-- The gate's survivor set, derived from the END STATE rather than from the temp mapping, so the
-- same assertions hold whether this is a first run or a re-run.
CREATE TEMP TABLE _ut_survivors ON COMMIT DROP AS
SELECT DISTINCT och.politician_id
  FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id = d.id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
 WHERE lower(d.state) = 'ut'
   AND d.district_type = 'LOCAL'
   AND d.geo_id ~ '/place:(ogden|provo|salt_lake_city|sandy|west_jordan|west_valley_city)/ward:[0-9]+$'
   AND och.politician_id IS NOT NULL;

-- ── post-verify gate ───────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_pointed int; v_fanout int; v_orphans int; v_stances int;
  v_contacts_live int; v_contacts_geo int; v_imgs int;
  v_healthy_offices int; v_healthy_active int; v_unreachable int;
BEGIN
  -- END STATE, asserted from the DB (not from the delta) so this is meaningful on a re-run too:
  -- no council_district-keyed district may remain anywhere in UT ...
  SELECT count(*) INTO v_pointed
    FROM essentials.districts d
   WHERE lower(d.state) = 'ut' AND d.district_type = 'LOCAL'
     AND d.geo_id ~ '/place:[a-z_]+/council_district:[0-9]+$';
  IF v_pointed <> 0 THEN
    RAISE EXCEPTION '1498: % UT LOCAL districts still keyed council_district (unreachable)', v_pointed;
  END IF;

  -- ... and all 28 seats in the six cities sit on a ward key with exactly one polygon and a holder
  SELECT count(*) INTO v_pointed
    FROM essentials.districts d
   WHERE lower(d.state) = 'ut' AND d.district_type = 'LOCAL'
     AND d.geo_id ~ '/place:(ogden|provo|salt_lake_city|sandy|west_jordan|west_valley_city)/ward:[0-9]+$'
     AND (SELECT count(*) FROM essentials.geofence_boundaries gb WHERE gb.geo_id = d.geo_id) = 1
     AND EXISTS (SELECT 1 FROM essentials.offices o
                   JOIN essentials.office_current_holder och ON och.office_id = o.id
                   JOIN essentials.politicians p ON p.id = och.politician_id AND p.is_active
                  WHERE o.district_id = d.id);
  IF v_pointed <> 28 THEN
    RAISE EXCEPTION '1498: only %/28 city-council seats have polygon + active holder', v_pointed;
  END IF;

  -- no UT LOCAL geo_id may be shared by two districts (the fan-out that would duplicate reps)
  SELECT count(*) INTO v_fanout FROM (
    SELECT 1 FROM essentials.districts d
     WHERE lower(d.state) = 'ut' AND d.district_type = 'LOCAL'
     GROUP BY d.geo_id HAVING count(*) > 1
  ) x;
  IF v_fanout <> 0 THEN
    RAISE EXCEPTION '1498: % UT LOCAL geo_ids are shared by more than one district', v_fanout;
  END IF;

  -- districts has no FK, so prove nothing was orphaned
  SELECT count(*) INTO v_orphans
    FROM essentials.offices o
   WHERE o.district_id IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.id = o.district_id);
  IF v_orphans <> 0 THEN
    RAISE EXCEPTION '1498: % offices were orphaned by a district delete', v_orphans;
  END IF;

  -- The stances that justified keeping the council_district side must all survive, and the contacts
  -- must have landed on those same holders. Both are counted off the END-STATE survivor set (six
  -- cities, ward-keyed) rather than the temp map, so a re-run checks the same thing.
  SELECT count(*) INTO v_stances
    FROM inform.politician_answers a
   WHERE a.politician_id IN (SELECT politician_id FROM _ut_survivors);
  IF v_stances <> 43 THEN
    RAISE EXCEPTION '1498: expected 43 surviving stance answers, found %', v_stances;
  END IF;

  -- 25 = the 24 moved off the ward side + 1 Erika Carlsen (SLC district 5) already had. She is a
  -- REPOINT-ONLY seat, so she is not among the 24 merged pairs.
  SELECT count(*) INTO v_contacts_live
    FROM essentials.politician_contacts pc
   WHERE pc.politician_id IN (SELECT politician_id FROM _ut_survivors);
  IF v_contacts_live <> 25 THEN
    RAISE EXCEPTION '1498: expected 25 contacts on survivors, found %', v_contacts_live;
  END IF;

  -- 27 of 28 survivors have a headshot (Jennifer Napier-Pearce, SLC district 4, has none)
  SELECT count(DISTINCT i.politician_id) INTO v_imgs
    FROM essentials.politician_images i
   WHERE i.politician_id IN (SELECT politician_id FROM _ut_survivors);
  IF v_imgs < 27 THEN
    RAISE EXCEPTION '1498: only % survivors have a headshot (expected >= 27)', v_imgs;
  END IF;

  -- REGRESSION GUARD: the 10 already-healthy ward cities must be untouched (47 seats, 47 active)
  SELECT count(*), count(*) FILTER (WHERE p.is_active)
    INTO v_healthy_offices, v_healthy_active
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE lower(d.state) = 'ut' AND d.district_type = 'LOCAL'
     AND d.geo_id ~ '/place:(cottonwood_heights|herriman|holladay|midvale|millcreek|murray|riverton|south_jordan|south_salt_lake|taylorsville)/ward:[0-9]+$';
  IF v_healthy_offices <> 47 OR v_healthy_active <> 47 THEN
    RAISE EXCEPTION '1498: healthy-city regression -- expected 47/47, got %/%', v_healthy_offices, v_healthy_active;
  END IF;

  -- END-TO-END: every one of the six city halls must now return that CITY's own LOCAL council seat
  -- with an ACTIVE holder, exactly as Murray already does. This is the check that would have caught
  -- the original defect, and the only one here that exercises the real address-search path.
  --
  -- The `place:<slug>` scoping is load-bearing, NOT cosmetic. Salt Lake County's council districts
  -- are themselves typed district_type='LOCAL' with mtfcc X0001, so an unscoped probe counts a
  -- COUNTY councilor as success: before this migration, the Sandy and West Valley City points
  -- "resolved" only Dea Theodore and Carlos A. Moreno of the county council. An unscoped gate would
  -- have reported 4 broken cities instead of 6 and passed while city seats stayed unreachable.
  SELECT count(*) INTO v_unreachable
    FROM (VALUES
      ('salt_lake_city',  -111.8868, 40.7596),
      ('ogden',           -111.9738, 41.2230),
      ('west_jordan',     -111.9391, 40.6097),
      ('west_valley_city',-112.0011, 40.6916),
      ('provo',           -111.6585, 40.2338),
      ('sandy',           -111.8841, 40.5649)
    ) AS pt(place, lng, lat)
   WHERE NOT EXISTS (
     SELECT 1
       FROM essentials.geofence_boundaries gb
       JOIN essentials.districts d ON d.geo_id = gb.geo_id
       JOIN essentials.offices o ON o.district_id = d.id
       JOIN essentials.office_current_holder och ON och.office_id = o.id
       JOIN essentials.politicians p ON p.id = och.politician_id
      WHERE gb.mtfcc = 'X0001'
        AND d.district_type = 'LOCAL'
        AND p.is_active
        AND d.geo_id LIKE '%/place:' || pt.place || '/ward:%'
        AND public.ST_Covers(gb.geometry,
              public.ST_SetSRID(public.ST_MakePoint(pt.lng, pt.lat), 4326))
   );
  IF v_unreachable <> 0 THEN
    RAISE EXCEPTION '1498: % of 6 city halls still return no active council member', v_unreachable;
  END IF;

  RAISE NOTICE '1498 OK: 28 UT council seats address-reachable; 43 stances, 24 contacts preserved; 6/6 city halls resolve';
END $$;

COMMIT;
