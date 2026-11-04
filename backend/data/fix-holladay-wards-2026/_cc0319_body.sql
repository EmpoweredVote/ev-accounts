-- ── Pre-flight ────────────────────────────────────────────────────────────────
DO $$
DECLARE v_rows int; v_before int; v_after int; v_unknown int; v_hits int;
BEGIN
  SELECT count(*) INTO v_rows FROM ak_holladay_fix;
  IF v_rows <> 5 THEN
    RAISE EXCEPTION 'CC_0319 pre-flight: the generated VALUES carry % rows, expected 5', v_rows;
  END IF;

  SELECT count(*) INTO v_rows
    FROM essentials.geofence_boundaries WHERE geo_id LIKE '%holladay%';
  IF v_rows <> 5 THEN
    RAISE EXCEPTION 'CC_0319 pre-flight: expected 5 Holladay ward polygons in production, found %', v_rows;
  END IF;

  -- 🔴 Every row must be recognisably EITHER the recorded pre-image OR the repaired state.
  -- Anything else means production holds geometry this migration has no record of.
  SELECT count(*) FILTER (WHERE md5(ST_AsBinary(gb.geometry)::text) = f.md5_before),
         count(*) FILTER (WHERE md5(ST_AsBinary(gb.geometry)::text) = f.md5_after),
         count(*) FILTER (WHERE md5(ST_AsBinary(gb.geometry)::text) NOT IN (f.md5_before, f.md5_after))
    INTO v_before, v_after, v_unknown
    FROM essentials.geofence_boundaries gb
    JOIN ak_holladay_fix f ON f.geo_id = gb.geo_id;

  IF v_unknown > 0 THEN
    RAISE EXCEPTION 'CC_0319 pre-flight: % ward(s) match NEITHER the recorded pre-image nor the '
                    'repaired state. Production has drifted from the capture at '
                    'backend/data/fix-holladay-wards-2026/original-geometry-3857.json, so this '
                    'would overwrite a value nothing has a record of. STOP.', v_unknown;
  END IF;
  IF v_before <> 5 AND v_after <> 5 THEN
    RAISE EXCEPTION 'CC_0319 pre-flight: a MIXTURE — % ward(s) un-repaired and % repaired. A '
                    'half-repaired set means someone else has been here; re-running the '
                    'reprojection over good polygons would throw them into the Atlantic.',
                    v_before, v_after;
  END IF;

  SELECT count(*) INTO v_hits
    FROM essentials.geofence_boundaries
   WHERE geo_id LIKE '%holladay%'
     AND ST_Contains(geometry, ST_SetSRID(ST_MakePoint(-111.8247, 40.6689), 4326));
  IF v_before = 5 AND v_hits <> 0 THEN
    RAISE EXCEPTION 'CC_0319 pre-flight: wards read as un-repaired, yet City Hall already '
                    'resolves to % of them', v_hits;
  END IF;

  RAISE NOTICE 'CC_0319 pre-flight OK: 5 wards, % un-repaired / % already repaired, none unknown.',
               v_before, v_after;
END $$;

-- ── The repair ────────────────────────────────────────────────────────────────
-- Literal WGS84 rings. No ST_Transform, so nothing reads public.spatial_ref_sys.
-- `source` is appended to, never replaced, and only once.
UPDATE essentials.geofence_boundaries gb
   SET geometry = ST_GeomFromText(f.wkt, 4326),
       source   = CASE WHEN gb.source LIKE '%CC_0319%' THEN gb.source
                       ELSE gb.source
                            || ' | CC_0319 2026-10-31: reprojected EPSG:3857 -> EPSG:4326. The'
                            || ' coordinates were Web Mercator metres stored under SRID 4326, so'
                            || ' these five wards matched no address. Pre-image kept at'
                            || ' backend/data/fix-holladay-wards-2026/original-geometry-3857.json.'
                  END
  FROM ak_holladay_fix f
 WHERE f.geo_id = gb.geo_id;

-- ── Post-verify gate ──────────────────────────────────────────────────────────
DO $$
DECLARE
  v_inrange int; v_md5 int; v_hits int; v_pairs int; v_overlap int; v_outside_bbox int;
  v_city numeric; v_wards numeric; v_cover numeric; v_slop numeric; v_src int;
  -- 1 m2 at 40.67 N, in square degrees. See the header note on units.
  c_m2_in_deg2 CONSTANT numeric := 1.06e-10;
BEGIN
  SELECT count(*) INTO v_inrange
    FROM essentials.geofence_boundaries
   WHERE geo_id LIKE '%holladay%'
     AND ST_XMin(geometry) >= -180 AND ST_XMax(geometry) <= 180
     AND ST_YMin(geometry) >=  -90 AND ST_YMax(geometry) <=  90;
  IF v_inrange <> 5 THEN
    RAISE EXCEPTION 'CC_0319 post-verify: % of 5 wards are within valid lon/lat range', v_inrange;
  END IF;

  -- 🔴 The literals landed byte-for-byte on the state that was measured and verified.
  SELECT count(*) INTO v_md5
    FROM essentials.geofence_boundaries gb
    JOIN ak_holladay_fix f ON f.geo_id = gb.geo_id
   WHERE md5(ST_AsBinary(gb.geometry)::text) = f.md5_after;
  IF v_md5 <> 5 THEN
    RAISE EXCEPTION 'CC_0319 post-verify: only % of 5 wards match the expected post-repair WKB '
                    'MD5. The literal WKT in this file does not reproduce the geometry it was '
                    'generated from.', v_md5;
  END IF;

  -- 🔴 THE ONE THAT MATTERS: the seats are reachable, and by EXACTLY ONE ward.
  SELECT count(*) INTO v_hits
    FROM essentials.geofence_boundaries
   WHERE geo_id LIKE '%holladay%'
     AND ST_Contains(geometry, ST_SetSRID(ST_MakePoint(-111.8247, 40.6689), 4326));
  IF v_hits <> 1 THEN
    RAISE EXCEPTION 'CC_0319 post-verify: Holladay City Hall resolves to % ward(s), expected '
                    'exactly 1. 0 means still unreachable; more than 1 means the wards overlap.', v_hits;
  END IF;

  -- Every ward must sit ON Holladay. A bounding box replaces the metre distance test, which
  -- would have needed ::geography. This box is ~12 km across and centred on the city.
  SELECT count(*) INTO v_outside_bbox
    FROM essentials.geofence_boundaries
   WHERE geo_id LIKE '%holladay%'
     AND NOT ST_Within(ST_Centroid(geometry),
                       ST_MakeEnvelope(-111.90, 40.60, -111.75, 40.74, 4326));
  IF v_outside_bbox <> 0 THEN
    RAISE EXCEPTION 'CC_0319 post-verify: % ward centroid(s) fall outside the Holladay bounding '
                    'box — the geometry did not land on the city', v_outside_bbox;
  END IF;

  -- Tiling: adjacency is expected, overlap is not.
  SELECT count(*),
         count(*) FILTER (WHERE ST_Area(ST_Intersection(a.geometry, b.geometry)) > c_m2_in_deg2)
    INTO v_pairs, v_overlap
    FROM essentials.geofence_boundaries a
    JOIN essentials.geofence_boundaries b
      ON a.geo_id < b.geo_id AND b.geo_id LIKE '%holladay%'
   WHERE a.geo_id LIKE '%holladay%';
  IF v_pairs <> 10 THEN
    RAISE EXCEPTION 'CC_0319 post-verify: examined % ward pairs, expected 10 — a gate that reads '
                    'nothing finds nothing wrong', v_pairs;
  END IF;
  IF v_overlap <> 0 THEN
    RAISE EXCEPTION 'CC_0319 post-verify: % ward pair(s) overlap by more than about 1 m2', v_overlap;
  END IF;

  -- Coverage against the city's own TIGER polygon, as a RATIO of square degrees.
  SELECT ST_Area(c.geometry), ST_Area(u.g),
         round((ST_Area(ST_Intersection(u.g, c.geometry)) / ST_Area(c.geometry) * 100)::numeric, 2),
         round((ST_Area(ST_Difference(u.g, c.geometry)) / ST_Area(c.geometry) * 100)::numeric, 2)
    INTO v_city, v_wards, v_cover, v_slop
    FROM (SELECT geometry FROM essentials.geofence_boundaries
           WHERE mtfcc = 'G4110' AND state = '49' AND geo_id = '4936070') c
   CROSS JOIN (SELECT ST_Union(geometry) AS g FROM essentials.geofence_boundaries
                WHERE geo_id LIKE '%holladay%') u;
  IF v_city IS NULL THEN
    RAISE EXCEPTION 'CC_0319 post-verify: the Holladay city polygon (G4110 / 4936070) is missing, '
                    'so coverage could not be measured at all';
  END IF;
  IF v_cover < 99.0 THEN
    RAISE EXCEPTION 'CC_0319 post-verify: the five wards cover only % percent of Holladay city, '
                    'expected at least 99 percent', v_cover;
  END IF;
  IF v_slop > 2.0 THEN
    RAISE EXCEPTION 'CC_0319 post-verify: % percent of the city area-equivalent falls outside it, '
                    'expected under 2 percent of digitising slop', v_slop;
  END IF;

  SELECT count(*) INTO v_src
    FROM essentials.geofence_boundaries
   WHERE geo_id LIKE '%holladay%'
     AND source LIKE '%manual_digitize_holladay-wards-2022%'
     AND source LIKE '%CC_0319%';
  IF v_src <> 5 THEN
    RAISE EXCEPTION 'CC_0319 post-verify: % of 5 wards carry both the original provenance string '
                    'and the repair note — source must be appended to, never replaced', v_src;
  END IF;

  RAISE NOTICE 'CC_0319 OK: 5 Holladay wards in WGS84, all matching the expected MD5. City Hall '
               'resolves to exactly 1 ward (was 0). Wards cover % percent of the city with % '
               'percent outside; 10 pairs examined, 0 overlapping. No reprojection call and no '
               'geography cast, so nothing here read the spatial reference table.', v_cover, v_slop;
END $$;

COMMIT;
