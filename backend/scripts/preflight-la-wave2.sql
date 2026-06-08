-- Pre-flight verification script for Phase 108 Wave 2
-- Run before applying migrations 300-303
-- Usage: psql $DATABASE_URL -f backend/scripts/preflight-la-wave2.sql

-- =============================================================================
-- Q1: Beverly Hills office row count (RESEARCH.md Open Question 2)
-- =============================================================================
SELECT 'Q1_BH_DISTRICT' AS label, id, label AS district_label, district_type
FROM essentials.districts
WHERE geo_id = '0606308';

SELECT 'Q1_BH_OFFICE_COUNT' AS label,
       COUNT(*) AS bh_office_count,
       array_agg(o.title ORDER BY o.title) AS titles
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '0606308';

-- =============================================================================
-- Q2: Santa Monica office row count
-- =============================================================================
SELECT 'Q2_SM_DISTRICT' AS label, id, label AS district_label, district_type
FROM essentials.districts
WHERE geo_id = '0670000';

SELECT 'Q2_SM_OFFICE_COUNT' AS label,
       COUNT(*) AS sm_office_count,
       array_agg(o.title ORDER BY o.title) AS titles
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '0670000';

-- =============================================================================
-- Q3: LA City Clerk office existence (RESEARCH.md Open Question 3)
-- =============================================================================
SELECT 'Q3_LA_CLERK_OFFICE' AS label, o.id, o.title, o.district_id, o.politician_id
FROM essentials.offices o
JOIN essentials.districts d ON o.district_id = d.id
WHERE o.title ILIKE '%clerk%'
  AND d.geo_id = '0644000';

SELECT 'Q3_LA_CHAMBERS' AS label, c.id, c.name
FROM essentials.chambers c
WHERE c.government_id = (
  SELECT id FROM essentials.governments WHERE name = 'City of Los Angeles' AND state = 'CA'
);

-- =============================================================================
-- Q4: Confirm City Controller and City Attorney offices occupancy status
-- =============================================================================
SELECT 'Q4_LA_CITY_OFFICES' AS label,
       id,
       title,
       politician_id
FROM essentials.offices
WHERE id IN (
  '5a873c59-72ac-488f-8b2c-44dfd04d065c',  -- City Attorney
  'e5435b0e-c7a7-4c93-9b4f-cc647db0b9f6'   -- City Controller
);

-- =============================================================================
-- Q5: External_id range clean for -700001..-700049
-- =============================================================================
SELECT 'Q5_EXTERNAL_ID_RANGE' AS label,
       COUNT(*) AS used
FROM essentials.politicians
WHERE external_id BETWEEN -700049 AND -700001;
