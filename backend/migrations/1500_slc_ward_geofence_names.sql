-- 1500_slc_ward_geofence_names.sql
--
-- The 7 Salt Lake City council-district geofences are named after their COUNCILMEMBER instead of
-- their district, and two of those names are wrong: `ward:4` reads "Eva Lopez" and `ward:5` "Darin
-- Mano", neither of whom has held the seat since January 2026 (they were replaced by Jennifer
-- Napier-Pearce and Erika Carlsen). Naming a boundary after its occupant guarantees this: the person
-- changes, the district does not.
--
-- WHY A MIGRATION IS NEEDED AT ALL -- checked the importer first, and this is the whole reason:
-- `scripts/load-arcgis-from-config.ts:146` inserts `ON CONFLICT (geo_id, mtfcc) DO NOTHING`. It never
-- updates an existing row, so correcting `field_map.name` in data/arcgis_sources.json (done in the
-- same commit) only affects a FRESH import. The 7 rows already in the table would keep their person
-- names forever. Conversely the config change is not optional either: without it, a delete-and-
-- reimport would put the person names straight back. Both halves are required, and neither alone is
-- sufficient.
--
-- The new values are the source's own `LABEL` field -- 'Council District 1' .. 'Council District 7' --
-- read live from the SLC ArcGIS layer on 2026-07-30, not invented here:
--   services.arcgis.com/mMBpeYj0vPFotzbe/arcgis/rest/services/Salt_Lake_City_Council_Districts
-- That field is what its peers already key on (west_valley_city -> LABEL 'District N',
-- ogden -> NAME 'Municipal District N'), and it matches Murray's existing 'Council District N'.
--
-- SAFE FOR EVERY READER OF geofence_boundaries.name, checked before writing:
--   * coverageService.computeUniverse slugs `name` to match synthesized ocd_id slugs, but
--     UNIVERSE_LAYERS only covers mtfcc G4020 / G4110 / G5420. These rows are X0001, so the admin
--     coverage dashboard never reads them and no sticky-slug matching can break.
--   * pickCountyFromDistrictRows only considers mtfcc G4020 / district_type COUNTY rows.
--   * getRepresentativesByAddress returns `gb.name AS geofence_name` in the payload, which is the
--     one visible change -- and there a district label is strictly better than a stale person name.
--
-- Idempotent: keyed on the exact old value, so a re-run matches zero rows.
--
-- NOT FIXED HERE. The same defect affects 31 more ward geofences in seven other UT cities, whose
-- configs also point field_map.name at a person field: holladay 5 (Representa), riverton 5
-- (CC_Name), taylorsville 5, cottonwood_heights 4 (Member), herriman 4 (Representative),
-- millcreek 4 (COUNCILMEMBER), west_jordan 4 (Council_Member). Each needs its own source layer
-- inspected to find whether a label field even exists, so it is real work rather than a trivial
-- extension of this one. Tracked separately.
-- (south_salt_lake and south_jordan look odd but are FINE: 'South Salt Lake Dist #1' is a label, and
-- south_jordan's bare '1'..'5' are numbers, not people.)

BEGIN;

UPDATE essentials.geofence_boundaries SET name = 'Council District 1'
 WHERE geo_id = 'ocd-division/country:us/state:ut/place:salt_lake_city/ward:1'
   AND mtfcc = 'X0001' AND name = 'Victoria Petro';

UPDATE essentials.geofence_boundaries SET name = 'Council District 2'
 WHERE geo_id = 'ocd-division/country:us/state:ut/place:salt_lake_city/ward:2'
   AND mtfcc = 'X0001' AND name = 'Alejandro Puy';

UPDATE essentials.geofence_boundaries SET name = 'Council District 3'
 WHERE geo_id = 'ocd-division/country:us/state:ut/place:salt_lake_city/ward:3'
   AND mtfcc = 'X0001' AND name = 'Chris Wharton';

UPDATE essentials.geofence_boundaries SET name = 'Council District 4'
 WHERE geo_id = 'ocd-division/country:us/state:ut/place:salt_lake_city/ward:4'
   AND mtfcc = 'X0001' AND name = 'Eva Lopez';

UPDATE essentials.geofence_boundaries SET name = 'Council District 5'
 WHERE geo_id = 'ocd-division/country:us/state:ut/place:salt_lake_city/ward:5'
   AND mtfcc = 'X0001' AND name = 'Darin Mano';

UPDATE essentials.geofence_boundaries SET name = 'Council District 6'
 WHERE geo_id = 'ocd-division/country:us/state:ut/place:salt_lake_city/ward:6'
   AND mtfcc = 'X0001' AND name = 'Dan Dugan';

UPDATE essentials.geofence_boundaries SET name = 'Council District 7'
 WHERE geo_id = 'ocd-division/country:us/state:ut/place:salt_lake_city/ward:7'
   AND mtfcc = 'X0001' AND name = 'Sarah Young';

-- ── post-verify gate ───────────────────────────────────────────────────────────────────
DO $$
DECLARE v_named int; v_person int; v_geom int;
BEGIN
  -- all 7 now carry their own district label
  SELECT count(*) INTO v_named
    FROM essentials.geofence_boundaries gb
   WHERE gb.mtfcc = 'X0001'
     AND gb.geo_id ~ '/place:salt_lake_city/ward:[0-9]+$'
     AND gb.name = 'Council District ' || regexp_replace(gb.geo_id, '^.*/ward:([0-9]+)$', '\1');
  IF v_named <> 7 THEN
    RAISE EXCEPTION '1500: only %/7 SLC ward geofences carry their district label', v_named;
  END IF;

  -- and none is named after a person any more
  SELECT count(*) INTO v_person
    FROM essentials.geofence_boundaries gb
   WHERE gb.mtfcc = 'X0001'
     AND gb.geo_id ~ '/place:salt_lake_city/ward:[0-9]+$'
     AND gb.name !~* 'district';
  IF v_person <> 0 THEN
    RAISE EXCEPTION '1500: % SLC ward geofences still carry a non-district name', v_person;
  END IF;

  -- renaming must not have touched geometry: all 7 polygons still valid and non-empty, so address
  -- search is unaffected (these are the polygons migration 1498 repointed the districts onto)
  SELECT count(*) INTO v_geom
    FROM essentials.geofence_boundaries gb
   WHERE gb.mtfcc = 'X0001'
     AND gb.geo_id ~ '/place:salt_lake_city/ward:[0-9]+$'
     AND gb.geometry IS NOT NULL
     AND public.ST_IsValid(gb.geometry)
     AND NOT public.ST_IsEmpty(gb.geometry);
  IF v_geom <> 7 THEN
    RAISE EXCEPTION '1500: only %/7 SLC ward polygons are still valid', v_geom;
  END IF;

  RAISE NOTICE '1500 OK: 7 SLC ward geofences renamed to Council District 1-7, geometry untouched';
END $$;

COMMIT;
