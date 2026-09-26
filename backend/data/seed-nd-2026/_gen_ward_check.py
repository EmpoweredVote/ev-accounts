"""Build a read-only PostGIS query that dissolves the 11 Grand Forks precinct parts into 7 wards
and measures them against the city place polygon already in production."""
import json, io, sys

path = sys.argv[1] if len(sys.argv) > 1 else 'data/seed-nd-2026/gf_wards.geojson'
d = json.load(io.open(path, encoding='utf-8'))
rows = []
for f in d['features']:
    ward = f['properties']['Ward']
    num = ward.rsplit(' ', 1)[1]
    g = json.dumps(f['geometry']).replace("'", "''")
    rows.append(f"    ('{num}', ST_SetSRID(ST_GeomFromGeoJSON('{g}'), 4326))")

sql = """
WITH parts(ward, g) AS (VALUES
%s
),
wards AS (
  SELECT ward, ST_MakeValid(ST_Union(g)) AS g FROM parts GROUP BY ward
),
city AS (
  SELECT ST_MakeValid(geometry) AS g FROM essentials.geofence_boundaries
   WHERE state='38' AND mtfcc='G4110' AND geo_id='3832060'
),
allw AS (SELECT ST_MakeValid(ST_Union(g)) AS g FROM wards)
SELECT
  (SELECT count(*) FROM wards) AS ward_count,
  round((SELECT ST_Area(g::geography)/2589988.11 FROM city)::numeric, 4) AS city_sqmi,
  round((SELECT ST_Area(g::geography)/2589988.11 FROM allw)::numeric, 4) AS wards_union_sqmi,
  round((SELECT ST_Area(ST_Intersection(a.g, c.g)::geography)/2589988.11 FROM allw a, city c)::numeric, 4) AS overlap_sqmi,
  round((SELECT ST_Area(ST_Difference(c.g, a.g)::geography)/2589988.11 FROM allw a, city c)::numeric, 4) AS city_not_in_any_ward_sqmi,
  round((SELECT ST_Area(ST_Difference(a.g, c.g)::geography)/2589988.11 FROM allw a, city c)::numeric, 4) AS ward_outside_city_sqmi,
  (SELECT count(*) FROM wards w1 JOIN wards w2 ON w1.ward < w2.ward
     WHERE ST_Area(ST_Intersection(w1.g, w2.g)::geography) > 1000) AS overlapping_ward_pairs;
""" % ',\n'.join(rows)

io.open('data/seed-nd-2026/_ward_check.sql', 'w', encoding='utf-8', newline='\n').write(sql)

per = """
WITH parts(ward, g) AS (VALUES
%s
),
wards AS (SELECT ward, ST_MakeValid(ST_Union(g)) AS g FROM parts GROUP BY ward)
SELECT w.ward,
       round((ST_Area(w.g::geography)/2589988.11)::numeric, 4) AS sqmi,
       round(ST_Y(ST_PointOnSurface(w.g))::numeric, 6) AS lat,
       round(ST_X(ST_PointOnSurface(w.g))::numeric, 6) AS lon
FROM wards w ORDER BY w.ward::int;
""" % ',\n'.join(rows)
io.open('data/seed-nd-2026/_ward_detail.sql', 'w', encoding='utf-8', newline='\n').write(per)
print('wrote _ward_check.sql and _ward_detail.sql from', len(d['features']), 'parts')
