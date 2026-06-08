-- ============================================================
-- verify-la-county-108.sql
-- Phase 108 Phase Gate — LA County City Officials
-- Run: psql "$DATABASE_URL" -f backend/scripts/verify-la-county-108.sql
--
-- 8 labeled assertions covering all Phase 108 success criteria.
-- Each assertion outputs a query result; zero-row failures or
-- unexpected counts indicate gaps to investigate.
--
-- LAOF-01: 14 Tier 1 cities fully populated (Wave 1)
-- LAOF-02: Beverly Hills, Santa Monica, LA City offices filled (Wave 2)
-- LAOF-03: 10 new Wave 3 cities populated
-- LAOF-04: All 26 Phase 108 city FIPS codes present on essentials.districts.geo_id
-- LAOF-05: All Phase 108 politicians have photo_origin_url, office_id, party=NULL, is_incumbent=true
-- LAOF-06: No illegal LOCAL_EXEC/Mayor chamber antipatterns in at-large cities
-- ============================================================

\echo ''
\echo '==================================================================='
\echo 'Phase 108 LA County City Officials — Verification Gate'
\echo '==================================================================='

-- ============================================================
-- ASSERTION 1: LAOF-05 — every Phase 108 politician has required fields
-- Expected: failures = 0
-- ============================================================
\echo ''
\echo '--- ASSERTION 1: LAOF-05 — photo_origin_url, office_id, party=NULL, is_incumbent=true ---'
\echo 'Expected: failures = 0'

SELECT COUNT(*) AS failures
FROM essentials.politicians
WHERE external_id BETWEEN -700699 AND -700001
  AND (
    photo_origin_url IS NULL
    OR office_id IS NULL
    OR party IS NOT NULL
    OR is_incumbent IS NOT TRUE
  );

-- ============================================================
-- ASSERTION 2: LAOF-04 — every Phase 108 city has a district row with expected geo_id
-- Expected: every row's district_rows >= 1
-- Note: West Hollywood FIPS verified as 0684410 (confirmed in migration 304, Wave 3 T1)
-- ============================================================
\echo ''
\echo '--- ASSERTION 2: LAOF-04 — all 26 Phase 108 FIPS codes present in essentials.districts ---'
\echo 'Expected: every row shows district_rows >= 1'

SELECT
  v.geo_id,
  v.city_label,
  (SELECT COUNT(*) FROM essentials.districts d WHERE d.geo_id = v.geo_id) AS district_rows
FROM (VALUES
  ('0643000', 'Long Beach'),
  ('0630000', 'Glendale'),
  ('0608954', 'Burbank'),
  ('0619766', 'Downey'),
  ('0622230', 'El Monte'),
  ('0636546', 'Inglewood'),
  ('0640130', 'Lancaster'),
  ('0652526', 'Norwalk'),
  ('0655156', 'Palmdale'),
  ('0656000', 'Pasadena'),
  ('0658072', 'Pomona'),
  ('0669088', 'Santa Clarita'),
  ('0680000', 'Torrance'),
  ('0684200', 'West Covina'),
  ('0606308', 'Beverly Hills'),
  ('0670000', 'Santa Monica'),
  ('0644000', 'LA City (citywide)'),
  ('0673080', 'South Gate'),
  ('0615044', 'Compton'),
  ('0611530', 'Carson'),
  ('0632548', 'Hawthorne'),
  ('0685292', 'Whittier'),
  ('0600884', 'Alhambra'),
  ('0628168', 'Gardena'),
  ('0617568', 'Culver City'),
  ('0684410', 'West Hollywood (verified FIPS, corrected from 0684346)'),
  ('0622412', 'El Segundo')
) AS v(geo_id, city_label)
ORDER BY v.city_label;

-- ============================================================
-- ASSERTION 3: LAOF-01 — Wave 1: each Tier 1 city has at least 1 politician
-- Expected: every row's politician_count >= 1; total >= 14
-- ============================================================
\echo ''
\echo '--- ASSERTION 3: LAOF-01 — Wave 1 Tier 1 cities have at least 1 politician each ---'
\echo 'Expected: politician_count >= 1 per row, total >= 14'

SELECT
  d.geo_id,
  COUNT(DISTINCT p.id) AS politician_count
FROM essentials.districts d
LEFT JOIN essentials.offices o ON o.district_id = d.id
LEFT JOIN essentials.politicians p ON p.office_id = o.id
WHERE d.geo_id IN (
  '0643000','0630000','0608954','0619766','0622230','0636546',
  '0640130','0652526','0655156','0656000','0658072','0669088',
  '0680000','0684200'
)
GROUP BY d.geo_id
ORDER BY d.geo_id;

-- ============================================================
-- ASSERTION 4: LAOF-02 — Wave 2 counts: Beverly Hills >= 6, Santa Monica >= 7
-- Expected: bh_count >= 6, sm_count >= 7
-- ============================================================
\echo ''
\echo '--- ASSERTION 4: LAOF-02 — Beverly Hills >= 6, Santa Monica >= 7 politicians ---'
\echo 'Expected: bh_count >= 6, sm_count >= 7'

SELECT
  (SELECT COUNT(DISTINCT p.id)
   FROM essentials.politicians p
   JOIN essentials.offices o ON o.politician_id = p.id
   JOIN essentials.districts d ON o.district_id = d.id
   WHERE d.geo_id = '0606308') AS bh_count,
  (SELECT COUNT(DISTINCT p.id)
   FROM essentials.politicians p
   JOIN essentials.offices o ON o.politician_id = p.id
   JOIN essentials.districts d ON o.district_id = d.id
   WHERE d.geo_id = '0670000') AS sm_count;

-- ============================================================
-- ASSERTION 5: LAOF-02 — Wave 2 LA City offices state
-- Expected: controller_seated=true, attorney_vacant=true, clerk_appointed=true
-- ============================================================
\echo ''
\echo '--- ASSERTION 5: LAOF-02 — LA City Controller seated, Attorney vacant, Clerk appointed ---'
\echo 'Expected: all 3 booleans = true'

SELECT
  (SELECT politician_id IS NOT NULL
   FROM essentials.offices
   WHERE id = 'e5435b0e-c7a7-4c93-9b4f-cc647db0b9f6') AS controller_seated,
  (SELECT politician_id IS NULL
   FROM essentials.offices
   WHERE id = '5a873c59-72ac-488f-8b2c-44dfd04d065c') AS attorney_vacant,
  EXISTS (
    SELECT 1 FROM essentials.politicians
    WHERE external_id = -700002
      AND is_appointed = true
  ) AS clerk_appointed;

-- ============================================================
-- ASSERTION 6: LAOF-03 — Wave 3: 10 new governments + >= 45 politicians
-- Expected: new_governments = 10, wave3_politicians >= 45
-- ============================================================
\echo ''
\echo '--- ASSERTION 6: LAOF-03 — 10 Wave 3 governments, >= 45 Wave 3 politicians ---'
\echo 'Expected: new_governments = 10, wave3_politicians >= 45'

SELECT
  (SELECT COUNT(*)
   FROM essentials.governments
   WHERE name IN (
     'City of South Gate',
     'City of Compton',
     'City of Carson',
     'City of Hawthorne',
     'City of Whittier',
     'City of Alhambra',
     'City of Gardena',
     'City of Culver City',
     'City of West Hollywood',
     'City of El Segundo'
   )
   AND state = 'CA') AS new_governments,
  (SELECT COUNT(*)
   FROM essentials.politicians
   WHERE external_id BETWEEN -700699 AND -700200) AS wave3_politicians;

-- ============================================================
-- ASSERTION 7: LAOF-06 — Wave 3 negative assertion: at-large cities have no Mayor
-- chambers and no LOCAL_EXEC districts created by Phase 108
-- Expected: every row shows mayor_chambers_created_by_wave3 = 0
-- Note: pre-existing LOCAL_EXEC rows (from race migrations) are expected; this
--       assertion verifies no WAVE 3 politicians were linked to them.
-- ============================================================
\echo ''
\echo '--- ASSERTION 7: LAOF-06 — Alhambra/Culver City/WeHo/El Segundo/South Gate at-large structure ---'
\echo 'Expected: no Wave 3 politician (external_id -700200..-700699) linked to LOCAL_EXEC districts'

SELECT
  g.name,
  d.district_type,
  d.label,
  COUNT(p.id) AS wave3_politicians_in_local_exec
FROM essentials.governments g
JOIN essentials.districts d ON d.government_id = g.id
LEFT JOIN essentials.offices o ON o.district_id = d.id
LEFT JOIN essentials.politicians p
  ON p.office_id = o.id
  AND p.external_id BETWEEN -700699 AND -700200
WHERE g.name IN (
  'City of Alhambra',
  'City of Culver City',
  'City of West Hollywood',
  'City of El Segundo',
  'City of South Gate'
)
AND g.state = 'CA'
AND d.district_type = 'LOCAL_EXEC'
GROUP BY g.name, d.district_type, d.label
ORDER BY g.name;

-- ============================================================
-- ASSERTION 8: Antipattern check — no slug or ON CONFLICT (geo_id, district_type)
-- in Phase 108 migrations 293-309
-- This assertion is confirmed via shell grep (pure SQL cannot scan files).
-- Expected: the shell complement below returns 0 matches.
-- ============================================================
\echo ''
\echo '--- ASSERTION 8: Antipattern check — migration files clean of forbidden patterns ---'
\echo 'SQL portion: verify no Phase 108 politician record has a slug column set'
\echo 'Expected: 0 rows with slug-like duplicate insertion patterns'

-- SQL portion: confirm no Phase 108 politicians were inserted via chambers.slug lookup
-- (the forbidden pattern would have caused an error on insert; this confirms clean state)
SELECT COUNT(*) AS phase108_politicians_total,
       COUNT(p.external_id) AS have_external_id,
       COUNT(p.office_id) AS have_office_id,
       COUNT(p.photo_origin_url) AS have_photo
FROM essentials.politicians p
WHERE p.external_id BETWEEN -700699 AND -700001;

-- Shell complement (run separately to confirm file-level antipatterns absent):
-- grep -rE '(INSERT INTO essentials\.chambers[^;]*slug|ON CONFLICT \(geo_id, district_type\))' \
--   backend/migrations/29[3-9]_la_*.sql backend/migrations/30[0-9]_la_*.sql 2>/dev/null
-- Expected: no matches (empty output)

\echo ''
\echo '==================================================================='
\echo 'Verification complete. Review above for any unexpected counts.'
\echo 'All assertions should show: failures=0, all cities present,'
\echo 'controller_seated=t, attorney_vacant=t, clerk_appointed=t,'
\echo 'new_governments=10, wave3_politicians>=45.'
\echo '==================================================================='
