-- verify-sc-counties-probes.sql
-- Knight Foundation program, wave SC-4 acceptance evidence. READ-ONLY.
--
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/verify-sc-counties-probes.sql
--
-- Asserts that an address inside each county resolves to the RIGHT council member and to the
-- county's officers. 🔴 This is the only reliable detector: `check:reachability` is green when
-- nothing was swept, and a count of offices is green when every one of them is unreachable.
--
-- 🔴 THE JOIN IS ON (geo_id, mtfcc), NEVER geo_id ALONE. '45079' is Richland County AND State
-- House District 79; '45051' is Horry County AND State House District 51.
--
-- Coordinates are Census geocoder matches, read 2026-09-20.

\echo ''
\echo '=== 1. THE PROBE: Richland County Administration Building, 2020 Hampton St, Columbia ==='
\echo '    Expect the Richland council district for this address, 6 countywide officers and 3'
\echo '    soil-and-water seats (one of which is VACANT and shows a NULL holder), plus the'
\echo '    Columbia city and South Carolina legislative answers SC-2 and SC-3 already seated.'

WITH a(lon,lat) AS (VALUES (-81.022011, 34.009336))
SELECT d.mtfcc, d.label, o.title, p.full_name, ot.start_precision
  FROM a
  JOIN essentials.geofence_boundaries gb
    ON ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(a.lon,a.lat),4326))
  JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc
  JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.politicians p ON p.id = och.politician_id
  LEFT JOIN essentials.office_terms ot ON ot.office_id = o.id AND ot.politician_id = p.id
 ORDER BY d.mtfcc, o.title, p.full_name;

\echo ''
\echo '=== 2. THE PROBE: Horry County Government and Justice Center, 1301 2nd Ave, Conway ==='
\echo '    Expect the Horry council district for this address, the AT-LARGE CHAIRMAN, 6 officers'
\echo '    and 3 soil-and-water seats. Conway is not Myrtle Beach, so NO city answer here.'

WITH a(lon,lat) AS (VALUES (-79.048643, 33.832444))
SELECT d.mtfcc, d.label, o.title, p.full_name, ot.start_precision
  FROM a
  JOIN essentials.geofence_boundaries gb
    ON ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(a.lon,a.lat),4326))
  JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc
  JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.politicians p ON p.id = och.politician_id
  LEFT JOIN essentials.office_terms ot ON ot.office_id = o.id AND ot.politician_id = p.id
 ORDER BY d.mtfcc, o.title, p.full_name;

\echo ''
\echo '=== 3. THE PROBE: Myrtle Beach City Hall, 937 Broadway St ==='
\echo '    A city address inside Horry: expect the SC-3 city answers AND the SC-4 county answers.'

WITH a(lon,lat) AS (VALUES (-78.882689, 33.695093))
SELECT d.mtfcc, d.label, o.title, p.full_name
  FROM a
  JOIN essentials.geofence_boundaries gb
    ON ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(a.lon,a.lat),4326))
  JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc
  JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.politicians p ON p.id = och.politician_id
 ORDER BY d.mtfcc, o.title;

\echo ''
\echo '=== 4. NEGATIVE CONTROL: Charleston City Hall, 80 Broad St ==='
\echo '    Charleston is in neither county. Expect ZERO rows from this wave.'

WITH a(lon,lat) AS (VALUES (-79.930863, 32.776537))
SELECT count(*) AS sc4_answers_outside_both_counties
  FROM a
  JOIN essentials.geofence_boundaries gb
    ON ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(a.lon,a.lat),4326))
  JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc
  JOIN essentials.offices o ON o.district_id = d.id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
 WHERE g.state = 'SC' AND g.geo_id IN ('45079','45051');

\echo ''
\echo '=== 5. PER-DISTRICT CONTROL: every one of the 22 polygons resolves to EXACTLY ONE office ==='
\echo '    22 rows, offices_hit must be 1 and holder must be non-null on every one.'

WITH pt AS (
  SELECT gb.mtfcc, gb.geo_id, ST_PointOnSurface(gb.geometry) g
    FROM essentials.geofence_boundaries gb WHERE gb.mtfcc IN ('X0060','X0061'))
SELECT pt.mtfcc, pt.geo_id, count(*) AS offices_hit,
       string_agg(p.full_name, ', ' ORDER BY p.full_name) AS holder
  FROM pt
  JOIN essentials.geofence_boundaries b2 ON b2.mtfcc = pt.mtfcc AND ST_Covers(b2.geometry, pt.g)
  JOIN essentials.districts d ON d.geo_id = b2.geo_id AND d.mtfcc = b2.mtfcc
  JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.politicians p ON p.id = och.politician_id
 GROUP BY pt.mtfcc, pt.geo_id
 ORDER BY pt.mtfcc, length(pt.geo_id), pt.geo_id;

\echo ''
\echo '=== 6. THE VACANCY IS VISIBLE AS A VACANCY, not as a missing office ==='

SELECT g.name AS government, o.title, o.is_vacant,
       (SELECT count(*) FROM essentials.office_terms ot WHERE ot.office_id = o.id) AS terms
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
 WHERE g.state='SC' AND g.geo_id IN ('45079','45051') AND o.is_vacant
 ORDER BY g.name, o.title;
