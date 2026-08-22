-- verify-nc-tiger-import.sql — NC wave 1. Read-only; run after the sldu/sldl load.
\echo '== district counts (expect STATE_LOWER 120, STATE_UPPER 50) =='
SELECT district_type, count(*)
FROM essentials.districts
WHERE lower(state) = 'nc' AND district_type IN ('STATE_LOWER', 'STATE_UPPER')
GROUP BY 1 ORDER BY 1;

\echo '== geofence polygons (expect G5220 120, G5210 50) =='
SELECT mtfcc, count(*)
FROM essentials.geofence_boundaries
WHERE state = '37' AND mtfcc IN ('G5220', 'G5210')
GROUP BY 1 ORDER BY 1;

\echo '== every district has geometry (expect 0) =='
SELECT count(*) AS districts_without_geometry
FROM essentials.districts d
WHERE lower(d.state) = 'nc' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
  AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries g WHERE g.geo_id = d.geo_id);

\echo '== identity anchors (expect HD-116/SD-49, HD-115, HD-114/SD-46, HD-30/SD-22) =='
-- 🔴 THE mtfcc PAIRING IN THIS JOIN IS LOAD-BEARING — see "The geo_id collision" below.
WITH pts(label, lon, lat) AS (VALUES
  ('Asheville',      -82.555413969974, 35.596748465412),
  ('Weaverville',    -82.560275346056, 35.695581782572),
  ('Black Mountain', -82.320007628946, 35.619686277732),
  ('Durham City Hall', -78.8996816092, 35.996066837243)
)
SELECT p.label, d.district_type, d.label AS district
FROM pts p
JOIN essentials.geofence_boundaries g
  ON g.state = '37' AND g.mtfcc IN ('G5220','G5210')
 AND public.ST_Covers(g.geometry, public.ST_SetSRID(public.ST_MakePoint(p.lon, p.lat), 4326))
JOIN essentials.districts d
  ON d.geo_id = g.geo_id
 AND ((g.mtfcc = 'G5210' AND d.district_type = 'STATE_UPPER')
   OR (g.mtfcc = 'G5220' AND d.district_type = 'STATE_LOWER'))
ORDER BY p.label, d.district_type;
