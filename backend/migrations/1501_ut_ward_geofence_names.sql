-- 1501_ut_ward_geofence_names.sql
--
-- 31 UT city-council ward geofences are named after their COUNCILMEMBER instead of their district,
-- across seven cities. Migration 1500 fixed the same defect for Salt Lake City's 7; this finishes it.
--
--   cottonwood_heights 4   herriman 4   holladay 5   millcreek 4
--   riverton 5             taylorsville 5            west_jordan 4
--
-- Same reasoning as 1500: a boundary must not be named after its occupant, because the person
-- changes and the district does not. SLC proved the failure mode -- two of its boundaries were still
-- named for members who left office in January 2026, and because the loader is
-- ON CONFLICT (geo_id, mtfcc) DO NOTHING (scripts/load-arcgis-from-config.ts) a re-import would never
-- have corrected them. Config fix + migration are both required; neither alone is sufficient.
--
-- WHAT EACH NEW NAME IS, AND WHERE IT CAME FROM. Every source layer was fetched and inspected on
-- 2026-07-30 before choosing. Three had a real label attribute and are now read from it; four had
-- none, so the name is synthesized from the district number via the new `field_map.name_template`:
--
--   riverton      -> 'Council District #1'..'#5'  source LABEL, verbatim (the '#' is theirs)
--   herriman      -> 'District 1'..'4'            source Label
--   millcreek     -> 'District 1'..'4'            source DIST (the same field district_num reads
--                                                  through extract_int)
--   holladay      -> 'District 1'..'5'            SYNTHESIZED. Its only label-ish field reads
--                                                  'Proposed District 1 - 6,174' -- a redistricting
--                                                  proposal with population baked in, not a name.
--   taylorsville  -> 'District 1'..'5'            SYNTHESIZED. Its NAME field is a census-block
--                                                  description ('Block 1000, Block Group 1, Census
--                                                  Tract 1135.10, Salt Lake County, Utah').
--   west_jordan   -> 'District 1'..'4'            SYNTHESIZED. No label attribute exists at all
--                                                  (only District_Quad plus area columns).
--   cottonwood_heights -> 'District 1'..'4'       SYNTHESIZED, AND UNVERIFIED: gis.chcity.org
--                                                  resolves but refuses connections (IP-restricted,
--                                                  same as the alternate WVC host noted in the
--                                                  config). Its fields could not be inspected, so a
--                                                  template is used rather than guessing a field
--                                                  name. If that host becomes reachable, check
--                                                  whether a real label field exists.
--
-- Names deliberately are NOT normalised to one house style across cities: each keeps what its own
-- source says ('Municipal District N' for Ogden, 'District N' for West Valley, 'Council District #N'
-- for Riverton). Faithful-to-source beats uniform, and the pre-existing rows already differ this way.
--
-- SAFE FOR EVERY READER of geofence_boundaries.name, same analysis as 1500: coverageService's
-- UNIVERSE_LAYERS slug matching only covers mtfcc G4020/G4110/G5420 and these are X0001, so the admin
-- coverage dashboard never reads them; pickCountyFromDistrictRows only considers G4020/COUNTY. The one
-- visible change is `geofence_name` in the reps payload, where a district label beats a person.
--
-- Idempotent: guarded by `name IS DISTINCT FROM` the computed target, so a re-run matches zero rows.

BEGIN;

UPDATE essentials.geofence_boundaries gb
   SET name = replace(t.tmpl, '{N}', regexp_replace(gb.geo_id, '^.*/ward:([0-9]+)$', '\1'))
  FROM (VALUES
    ('cottonwood_heights', 'District {N}'),
    ('herriman',           'District {N}'),
    ('holladay',           'District {N}'),
    ('millcreek',          'District {N}'),
    ('riverton',           'Council District #{N}'),
    ('taylorsville',       'District {N}'),
    ('west_jordan',        'District {N}')
  ) AS t(place, tmpl)
 WHERE gb.mtfcc = 'X0001'
   AND gb.geo_id ~ ('/place:' || t.place || '/ward:[0-9]+$')
   AND gb.name IS DISTINCT FROM
       replace(t.tmpl, '{N}', regexp_replace(gb.geo_id, '^.*/ward:([0-9]+)$', '\1'));

-- ── post-verify gate ───────────────────────────────────────────────────────────────────
DO $$
DECLARE v_named int; v_unlabelled int; v_geom int; v_total int;
BEGIN
  -- all 31 now carry their own district label
  SELECT count(*) INTO v_named
    FROM essentials.geofence_boundaries gb
    JOIN (VALUES
      ('cottonwood_heights', 'District {N}'), ('herriman', 'District {N}'),
      ('holladay', 'District {N}'),           ('millcreek', 'District {N}'),
      ('riverton', 'Council District #{N}'),  ('taylorsville', 'District {N}'),
      ('west_jordan', 'District {N}')
    ) AS t(place, tmpl) ON gb.geo_id ~ ('/place:' || t.place || '/ward:[0-9]+$')
   WHERE gb.mtfcc = 'X0001'
     AND gb.name = replace(t.tmpl, '{N}', regexp_replace(gb.geo_id, '^.*/ward:([0-9]+)$', '\1'));
  IF v_named <> 31 THEN
    RAISE EXCEPTION '1501: only %/31 ward geofences carry their district label', v_named;
  END IF;

  -- and NO UT ward geofence anywhere is still named after a person. Accepts every legitimate shape
  -- in the table: 'District N', 'Council District N', 'Council District #N', 'Municipal District N',
  -- 'Provo Council District N', 'South Salt Lake Dist #N', and south_jordan's bare '1'..'5'.
  SELECT count(*), count(*) FILTER (
           WHERE gb.name IS NULL
              OR (gb.name !~* '(district|dist)' AND gb.name !~ '^[0-9]+$'))
    INTO v_total, v_unlabelled
    FROM essentials.geofence_boundaries gb
   WHERE gb.mtfcc = 'X0001' AND gb.geo_id ~ '/place:[a-z_]+/ward:[0-9]+$';
  IF v_unlabelled <> 0 THEN
    RAISE EXCEPTION '1501: % of % UT ward geofences still carry a non-district name', v_unlabelled, v_total;
  END IF;

  -- renaming must not have touched geometry -- several of these polygons are what migration 1498
  -- repointed the council districts onto, so address search depends on them
  SELECT count(*) INTO v_geom
    FROM essentials.geofence_boundaries gb
   WHERE gb.mtfcc = 'X0001' AND gb.geo_id ~ '/place:[a-z_]+/ward:[0-9]+$'
     AND (gb.geometry IS NULL OR NOT public.ST_IsValid(gb.geometry) OR public.ST_IsEmpty(gb.geometry));
  IF v_geom <> 0 THEN
    RAISE EXCEPTION '1501: % UT ward polygons are now invalid/empty', v_geom;
  END IF;

  RAISE NOTICE '1501 OK: 31 ward geofences renamed across 7 cities; all % UT ward names are district labels', v_total;
END $$;

COMMIT;
