-- 1924_alexandria_school_district_geoid.sql
-- 1924: Alexandria City Public Schools is filed under ALBEMARLE COUNTY's GEOID. Re-key it.
--
-- DEFECT. TIGER's unified school district codes are 5100090 = Albemarle County Public Schools
-- (1,866 km2, around Charlottesville) and 5100120 = Alexandria City Public Schools (39.75 km2, in
-- the DC suburbs). We hold Alexandria's district -- its polygon, its name, its nine seated board
-- members -- under 5100090. Three rows carry the wrong id: essentials.districts,
-- essentials.governments and essentials.geofence_boundaries. 5100120 is free in all three.
--
-- ⚠ NOBODY IS MISROUTED BY THIS, and that is worth stating plainly because it was first reported
-- as a live routing failure. The geofence polygon is genuinely Alexandria's, routing is spatial,
-- so an Alexandria address resolves through this polygon to the Alexandria school board, correctly
-- named. An Albemarle County address resolves to no school district at all, which is simply "not
-- covered" -- we hold no Albemarle row of any kind. Probed both before writing this.
--
-- WHAT IT ACTUALLY COSTS:
--   * Anything that reads GEOIDs is misinformed. check-tiger-layer-fidelity.mjs compared our
--     Alexandria polygon against TIGER's Albemarle record and reported a 47-fold area error and a
--     156 km displacement -- a true measurement of a false premise. That is how this was found.
--   * It is a collision waiting to happen: loading Albemarle County Public Schools, which a
--     Virginia pass would do, would land on an occupied id.
--   * The geofence row carries NULL name and NULL source -- no provenance at all. One of exactly
--     two such rows in the table (the other is California's G4000 outline).
--
-- PROVENANCE, MEASURED NOT ASSUMED. Our polygon is TIGER's 5100120:
--     ours  39.8 km2, centroid 38.818 / -77.086
--     TIGER 39.75 km2 (AREALAND 38,682,329 + AREAWATER 1,069,027), centroid +38.8184547 /
--           -077.0862029   (tigerWMS_ACS2024 layer 14, read 2026-10-21)
--   Area agrees to ~0.1% and the centroids are the same point to three decimals. So this re-keys
--   the row and records where the geometry came from; it does not replace any geometry.
--
-- Pure DML. Apply with: npx tsx scripts/_apply-file.ts <abs path>

BEGIN;

UPDATE essentials.districts
   SET geo_id = '5100120'
 WHERE geo_id = '5100090' AND district_type = 'SCHOOL' AND mtfcc = 'G5420';

UPDATE essentials.governments
   SET geo_id = '5100120'
 WHERE geo_id = '5100090' AND mtfcc = 'G5420';

UPDATE essentials.geofence_boundaries
   SET geo_id = '5100120',
       name = 'Alexandria City Public Schools',
       source = 'Census TIGERweb tigerWMS_ACS2024 layer 14 (Unified School Districts), GEOID '
                || '5100120. Identified 2026-10-21 by check-tiger-layer-fidelity.mjs, which '
                || 'flagged this row as 156 km displaced while it was mis-keyed to 5100090 '
                || '(Albemarle County Public Schools). Confirmed by area 39.8 km2 vs TIGER 39.75 '
                || 'and an identical centroid. The row previously carried NULL name and NULL '
                || 'source; migration 1924 re-keyed it and recorded this.'
 WHERE geo_id = '5100090' AND mtfcc = 'G5420';

DO $$
DECLARE n int; nm text; cd text;
BEGIN
  -- 1. nothing is left on Albemarle's id, in any of the three tables
  SELECT (SELECT count(*) FROM essentials.districts WHERE geo_id = '5100090')
       + (SELECT count(*) FROM essentials.governments WHERE geo_id = '5100090')
       + (SELECT count(*) FROM essentials.geofence_boundaries WHERE geo_id = '5100090')
    INTO n;
  IF n <> 0 THEN RAISE EXCEPTION '1924: % row(s) still on 5100090', n; END IF;

  -- 2. exactly one row of each now carries Alexandria's own id
  SELECT count(*) INTO n FROM essentials.districts WHERE geo_id = '5100120' AND district_type = 'SCHOOL';
  IF n <> 1 THEN RAISE EXCEPTION '1924: % district rows on 5100120, want 1', n; END IF;
  SELECT count(*) INTO n FROM essentials.governments WHERE geo_id = '5100120';
  IF n <> 1 THEN RAISE EXCEPTION '1924: % government rows on 5100120, want 1', n; END IF;
  SELECT count(*) INTO n FROM essentials.geofence_boundaries WHERE geo_id = '5100120' AND mtfcc = 'G5420';
  IF n <> 1 THEN RAISE EXCEPTION '1924: % geofence rows on 5100120, want 1', n; END IF;

  -- 3. the geofence row is no longer anonymous
  SELECT name INTO nm FROM essentials.geofence_boundaries WHERE geo_id = '5100120' AND mtfcc = 'G5420';
  IF nm IS DISTINCT FROM 'Alexandria City Public Schools' THEN
    RAISE EXCEPTION '1924: geofence name is %, want Alexandria City Public Schools', coalesce(nm, 'NULL');
  END IF;

  -- 4. ALL NINE board members are still seated and still reachable. The re-key must not disturb
  --    occupancy -- this is the whole point of changing an id rather than deleting and reinserting.
  SELECT count(*) INTO n
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id AND och.politician_id IS NOT NULL
   WHERE d.geo_id = '5100120' AND d.district_type = 'SCHOOL';
  IF n <> 9 THEN RAISE EXCEPTION '1924: % seated school board members, want 9', n; END IF;

  -- 5. END TO END: an Old Town Alexandria point still resolves, through the polygon and the
  --    district, to the Alexandria school board. It did before this migration; it must after.
  SELECT d.label INTO cd
    FROM essentials.geofence_boundaries gb
    JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.district_type = 'SCHOOL'
   WHERE gb.mtfcc = 'G5420'
     AND public.ST_Covers(gb.geometry, public.ST_SetSRID(public.ST_MakePoint(-77.0469, 38.8048), 4326));
  IF cd IS DISTINCT FROM 'Alexandria City Public Schools' THEN
    RAISE EXCEPTION '1924: Old Town Alexandria resolves to %, want Alexandria City Public Schools', coalesce(cd, 'NOTHING');
  END IF;

  RAISE NOTICE '1924 OK: Alexandria City Public Schools re-keyed 5100090 -> 5100120; 9 members still seated and reachable';
END $$;

COMMIT;
