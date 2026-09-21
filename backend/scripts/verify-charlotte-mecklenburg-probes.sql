-- verify-charlotte-mecklenburg-probes.sql
-- Knight Foundation program, wave NC-3 acceptance evidence. READ-ONLY.
--
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/verify-charlotte-mecklenburg-probes.sql
--
-- Asserts that an address resolves to the RIGHT council member and the RIGHT county
-- commissioner. 🔴 This is the only reliable detector: `check:reachability` is green when nothing
-- was swept, and a count of offices is green when every one of them is unreachable.
--
-- 🔴 A THIRD AUTHORITY AGREES. The Mecklenburg Board of Elections publishes its own address
-- lookup at apps.meckboe.org, which is neither the GIS layers this wave loaded nor the rosters it
-- seated. For 600 E 4TH ST 28202 it returns CONGRESSIONAL DISTRICT 12, NC SENATE DISTRICT 41,
-- NC HOUSE DISTRICT 102, BOARD OF COMMISSIONERS DISTRICT 4 and CITY COUNCIL DISTRICT 1 -- every
-- one matching section 1 below, read 2026-09-17.

\echo ''
\echo '=== 1. THE PROBE: Charlotte-Mecklenburg Government Center, 600 E 4th St ==='
\echo '    Expect 17 NC-3 answers: 1 council district + 5 citywide + 1 commissioner district + 10 countywide.'

WITH a(lon,lat) AS (VALUES (-80.8390, 35.2226))
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
\echo '=== 2. PER-DISTRICT CONTROL: every district resolves to EXACTLY ONE office, and the right holder ==='
\echo '    13 rows, offices_hit must be 1 on every one.'

WITH pt AS (
  SELECT gb.mtfcc, gb.geo_id, ST_PointOnSurface(gb.geometry) g
    FROM essentials.geofence_boundaries gb WHERE gb.mtfcc IN ('X0056','X0057'))
SELECT pt.mtfcc, pt.geo_id, count(*) AS offices_hit,
       string_agg(p.full_name, ', ' ORDER BY p.full_name) AS holder
  FROM pt
  JOIN essentials.geofence_boundaries b2 ON b2.mtfcc = pt.mtfcc AND ST_Covers(b2.geometry, pt.g)
  JOIN essentials.districts d ON d.geo_id = b2.geo_id AND d.mtfcc = b2.mtfcc
  JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.politicians p ON p.id = och.politician_id
 GROUP BY 1,2 ORDER BY 1,2;

\echo ''
\echo '=== 3. NEGATIVE CONTROLS: the answer must SHRINK as you leave each jurisdiction ==='
\echo '    City Hall 17 · Huntersville (in county, outside city) 11 · Gastonia (outside the county) 0.'
\echo '    ⚠ Count only rows that reach a real NC-3 office. A LEFT JOIN that keeps office-less rows'
\echo '      reports Gastonia as non-zero, which is a bug in the probe, not in the data.'

WITH anchors(who, lon, lat) AS (VALUES
  ('Charlotte City Hall',                    -80.83900, 35.22260),
  ('Huntersville (in county, outside city)', -80.84280, 35.41070),
  ('Gastonia (outside the county)',          -81.18730, 35.26210)),
hits AS (
  SELECT a.who, d.mtfcc, o.id AS office_id
    FROM anchors a
    JOIN essentials.geofence_boundaries gb
      ON ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(a.lon,a.lat),4326))
    JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id IN ('3712000','37119'))
SELECT a.who,
       count(*) FILTER (WHERE h.mtfcc='X0056') AS council_dist,
       count(*) FILTER (WHERE h.mtfcc='G4110') AS citywide,
       count(*) FILTER (WHERE h.mtfcc='X0057') AS comm_dist,
       count(*) FILTER (WHERE h.mtfcc='G4020') AS countywide,
       count(h.office_id) AS nc3_answers
  FROM anchors a LEFT JOIN hits h ON h.who = a.who
 GROUP BY a.who ORDER BY 6 DESC;

\echo ''
\echo '=== 4. THE SHAPE: 28 offices, 28 seated, and the deliberate ABSENCES ==='
\echo '    Mecklenburg must have NO Chair office (its chair is elected by the board) and exactly'
\echo '    THREE soil and water supervisors (the board has five; two are state-appointed).'

SELECT g.name AS government, c.name AS chamber,
       count(*) AS offices, count(och.politician_id) AS seated
  FROM essentials.governments g
  JOIN essentials.chambers c ON c.government_id = g.id
  JOIN essentials.offices o ON o.chamber_id = c.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
 WHERE g.geo_id IN ('3712000','37119')
 GROUP BY 1,2 ORDER BY 1,2;

\echo ''
\echo '=== 5. THE geo_id COLLISION: 37119 is BOTH Mecklenburg County and State House District 119 ==='
\echo '    Two rows. The county polygon carries 10 offices -- 3 at-large commissioners, 4 elected'
\echo '    officers and 3 soil and water supervisors; the other 6 sit on the X0057 commissioner'
\echo '    districts, making 16. State House District 119 must carry exactly 1.'

SELECT d.mtfcc, d.district_type, d.label, count(o.id) AS offices
  FROM essentials.districts d
  LEFT JOIN essentials.offices o ON o.district_id = d.id
 WHERE d.geo_id = '37119'
 GROUP BY 1,2,3 ORDER BY 1;
