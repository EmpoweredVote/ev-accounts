-- verify-nashville-wave1a-probes.sql
-- Nashville wave 1a acceptance. Run after CC_0004 + CC_0005.
--
--   cd backend && psql "$DATABASE_URL" -f scripts/verify-nashville-wave1a-probes.sql
--
-- The migration gates prove the rows exist. They do not prove a resident can
-- find these people, which is a different question and the one that matters.
--
-- 🔴 EVERY POSITIVE PROBE IS PAIRED WITH A CONTROL THAT PROVES THE QUERY CAN
-- FAIL. A spatial join that cannot fire returns zero rows, which satisfies a
-- "found nothing wrong" reading of every negative assertion while telling you
-- nothing at all. Probe 4 is what makes probes 1 to 3 mean anything.
--
-- Probe 2 is the load-bearing one. Belle Meade is a separately incorporated city
-- inside Davidson County, and TIGER place 4752006 -- the "metropolitan
-- government (balance)" -- excludes it. If anyone ever re-points these seats at
-- the place polygon, probe 2 is the only thing here that notices.

\echo ''
\echo '=== 1. Metro Courthouse: one council district plus every countywide seat ==='
SELECT count(och.politician_id) AS metro_officials
  FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
 WHERE (d.mtfcc = 'X0035' OR (d.geo_id = '47037' AND d.district_type = 'COUNTY'))
   AND EXISTS (
     SELECT 1 FROM essentials.geofence_boundaries b
      WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc
        AND public.ST_Covers(b.geometry, public.ST_SetSRID(public.ST_MakePoint(-86.7761, 36.1665), 4326))
   );
\echo 'EXPECT 8  = 1 district member + 5 at-large + Vice Mayor + Mayor'

\echo ''
\echo '=== 2. Belle Meade City Hall: the satellite-city test ==='
SELECT count(och.politician_id) AS metro_officials
  FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
 WHERE (d.mtfcc = 'X0035' OR (d.geo_id = '47037' AND d.district_type = 'COUNTY'))
   AND EXISTS (
     SELECT 1 FROM essentials.geofence_boundaries b
      WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc
        AND public.ST_Covers(b.geometry, public.ST_SetSRID(public.ST_MakePoint(-86.8583, 36.1006), 4326))
   );
\echo 'EXPECT 8  -- 7 means the county polygon is missing; 0 means the place polygon was used'

\echo ''
\echo '=== 3. Belle Meade resolves council district 23 specifically ==='
SELECT d.geo_id, o.title, p.full_name
  FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id = d.id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  JOIN essentials.politicians p ON p.id = och.politician_id
  JOIN essentials.geofence_boundaries b ON b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc
 WHERE d.mtfcc = 'X0035'
   AND public.ST_Covers(b.geometry, public.ST_SetSRID(public.ST_MakePoint(-86.8583, 36.1006), 4326));
\echo 'EXPECT exactly one row: nashville-tn-council-district-23, Thom Druffel'

\echo ''
\echo '=== 4. CONTROL OF THE CONTROL: Brentwood, Williamson County ==='
SELECT count(*) AS metro_seats_outside_davidson
  FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id = d.id
  JOIN essentials.geofence_boundaries b ON b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc
 WHERE d.mtfcc = 'X0035'
   AND public.ST_Covers(b.geometry, public.ST_SetSRID(public.ST_MakePoint(-86.7828, 35.9739), 4326));
\echo 'EXPECT 0  -- probes 1 to 3 are only meaningful because this one is 0'

\echo ''
\echo '=== 5. Every council district resolves exactly one seated member ==='
SELECT count(*) AS districts_not_returning_exactly_one
  FROM essentials.districts d
 WHERE d.mtfcc = 'X0035'
   AND (SELECT count(och.politician_id)
          FROM essentials.offices o
          LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
         WHERE o.district_id = d.id) <> 1;
\echo 'EXPECT 0'

\echo ''
\echo '=== 6. The Vice Mayor explanation is present, and will render ==='
SELECT o.title, o.voting_powers, length(o.representation_note) AS note_len
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE d.geo_id = '47037' AND d.district_type = 'COUNTY' AND o.title = 'Vice Mayor';
\echo 'EXPECT one row: non_voting, note_len > 80. voting_powers full would hide the note.'

\echo ''
\echo '=== 7. Nothing landed on Davidson County, NORTH CAROLINA ==='
SELECT count(*) AS nc_davidson_offices
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE d.geo_id = '37057' AND d.district_type = 'COUNTY';
\echo 'EXPECT 0'

\echo ''
\echo '=== 8. Exactly one Mike Cortese ==='
SELECT count(*) AS cortese_rows,
       count(*) FILTER (WHERE (SELECT count(*) FROM essentials.office_current_holder och
                                WHERE och.politician_id = p.id) > 0) AS seated
  FROM essentials.politicians p WHERE p.full_name = 'Mike Cortese';
\echo 'EXPECT 1 row, 1 seated -- 2 means the reuse failed and prod holds a duplicate'

\echo ''
\echo '=== 9. offices_missing_terms did not grow ==='
SELECT count(*) AS unflagged_missing_terms
  FROM essentials.offices_missing_terms
 WHERE is_vacant IS NOT TRUE;
\echo 'EXPECT <= 699  -- the migration-1464 baseline'

\echo ''
\echo '=== 10. Term precision was not invented ==='
SELECT t.start_precision, count(*) AS terms, min(t.term_start) AS earliest, max(t.term_start) AS latest
  FROM essentials.office_terms t
  JOIN essentials.offices o ON o.id = t.office_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE d.mtfcc = 'X0035' OR (d.geo_id = '47037' AND d.district_type = 'COUNTY')
 GROUP BY t.start_precision ORDER BY 2 DESC;
\echo 'EXPECT month 41 (2019-09-01 and 2023-09-01), day 1 (the Mayor, 2023-09-25)'

\echo ''
\echo '=== 11. Spatial roundtrip over ALL 35 districts ==='
-- 🔴 WHY THIS EXISTS EVEN THOUGH check:reachability RUNS. That gate reported no
-- Nashville findings, and absence from a findings list has two readings: the
-- districts passed, or the districts were never scanned. This probe does not
-- depend on the gate's own district enumeration -- it takes an interior point of
-- each polygon and asks the question a resident asks. Silence from a detector is
-- not a pass until something independent says so.
WITH pts AS (
  SELECT d.id, d.geo_id, public.ST_PointOnSurface(b.geometry) AS pt
    FROM essentials.districts d
    JOIN essentials.geofence_boundaries b ON b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc
   WHERE d.mtfcc = 'X0035'
), resolved AS (
  SELECT p.geo_id,
         (SELECT count(*) FROM essentials.districts d2
            JOIN essentials.geofence_boundaries b2 ON b2.geo_id = d2.geo_id AND b2.mtfcc = d2.mtfcc
           WHERE d2.mtfcc = 'X0035' AND public.ST_Covers(b2.geometry, p.pt)) AS districts_hit,
         (SELECT count(och.politician_id) FROM essentials.offices o
            LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
           WHERE o.district_id = p.id) AS members
    FROM pts p
)
SELECT count(*) AS districts_probed,
       count(*) FILTER (WHERE districts_hit = 1) AS resolved_to_exactly_one,
       count(*) FILTER (WHERE members = 1) AS with_one_seated_member,
       count(*) FILTER (WHERE districts_hit <> 1 OR members <> 1) AS failures
  FROM resolved;
\echo 'EXPECT 35 / 35 / 35 / 0'
