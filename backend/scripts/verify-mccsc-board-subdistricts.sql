\set ON_ERROR_STOP on
-- Verify the MCCSC board-subdistrict pilot. Read-only. Run after
-- import-mccsc-board-district-polygons.ts. Any FAIL aborts with non-zero exit.

\echo '=== 1) 7 X0002 geofences + 7 SCHOOL sub-districts exist ==='
DO $$
DECLARE g int; d int;
BEGIN
  SELECT count(*) INTO g FROM essentials.geofence_boundaries
   WHERE geo_id LIKE '1800630-board-d%' AND mtfcc='X0002';
  SELECT count(*) INTO d FROM essentials.districts
   WHERE geo_id LIKE '1800630-board-d%' AND district_type='SCHOOL' AND mtfcc='X0002';
  IF g <> 7 THEN RAISE EXCEPTION '1 FAIL: geofences=% (expected 7)', g; END IF;
  IF d <> 7 THEN RAISE EXCEPTION '1 FAIL: sub-districts=% (expected 7)', d; END IF;
  RAISE NOTICE '1 PASS: geofences=7, sub-districts=7';
END $$;

\echo '=== 2) Each sub-district holds exactly 1 office; corp holds 0 ==='
DO $$
DECLARE bad int; corp int;
BEGIN
  SELECT count(*) INTO bad FROM (
    SELECT d.id FROM essentials.districts d
    LEFT JOIN essentials.offices o ON o.district_id=d.id
    WHERE d.geo_id LIKE '1800630-board-d%'
    GROUP BY d.id HAVING count(o.id) <> 1
  ) x;
  SELECT count(*) INTO corp FROM essentials.offices o
    JOIN essentials.districts d ON d.id=o.district_id WHERE d.geo_id='1800630';
  IF bad <> 0 THEN RAISE EXCEPTION '2 FAIL: % sub-districts do not have exactly 1 office', bad; END IF;
  IF corp <> 0 THEN RAISE EXCEPTION '2 FAIL: % offices still on the corp district', corp; END IF;
  RAISE NOTICE '2 PASS: 7 sub-districts x1 office; corp=0';
END $$;

\echo '=== 3) Point-in-polygon: each test point resolves to exactly ONE board member ==='
-- Uses the SAME geofence join the app uses (mtfcc X0002 + SCHOOL).
DO $$
DECLARE
  pts double precision[][] := ARRAY[
    ARRAY[-86.606, 39.145, 3],   -- user ~6240 W Ison Rd -> District 3
    ARRAY[-86.5264, 39.1653, 6], -- downtown Bloomington -> District 6
    ARRAY[-86.48, 39.17, 1],     -- east side -> District 1
    ARRAY[-86.52, 39.08, 2]      -- south -> District 2
  ];
  i int; g geometry; cnt int; got text;
BEGIN
  FOR i IN 1 .. array_length(pts,1) LOOP
    g := public.ST_SetSRID(public.ST_MakePoint(pts[i][1], pts[i][2]), 4326);
    SELECT count(*), string_agg(d.district_id, ',')
      INTO cnt, got
      FROM essentials.geofence_boundaries gb
      JOIN essentials.districts d ON d.geo_id=gb.geo_id
       AND gb.mtfcc='X0002' AND d.district_type='SCHOOL'
     WHERE d.geo_id LIKE '1800630-board-d%'
       AND public.ST_Covers(gb.geometry, g);
    IF cnt <> 1 THEN
      RAISE EXCEPTION '3 FAIL: point (%,%) matched % board districts (%), expected 1',
        pts[i][1], pts[i][2], cnt, got;
    END IF;
    IF got <> 'board-d' || pts[i][3]::int THEN
      RAISE EXCEPTION '3 FAIL: point (%,%) -> % (expected board-d%)',
        pts[i][1], pts[i][2], got, pts[i][3]::int;
    END IF;
    RAISE NOTICE '3 ok: point (%,%) -> %', pts[i][1], pts[i][2], got;
  END LOOP;
  RAISE NOTICE '3 PASS: every test point resolves to exactly one board member';
END $$;

\echo '=== ALL CHECKS PASSED ==='
