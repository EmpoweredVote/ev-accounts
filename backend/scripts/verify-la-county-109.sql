-- ============================================================
-- verify-la-county-109.sql
-- Phase 109 Phase Gate — LA County Finance
-- Run: psql "$DATABASE_URL" -f backend/scripts/verify-la-county-109.sql
--
-- 8 labeled assertions covering all Phase 109 success criteria.
-- Each assertion outputs a query result; zero-row failures or
-- unexpected counts indicate gaps to investigate.
-- Script tolerates zero rows — all assertions are SELECT counts only.
-- Exits 0 even before Wave 1/2 data exists (no error on empty state).
--
-- LAFI-01: finance_summary non-null for all LA City officials with confirmed Socrata sources
-- LAFI-02: finance_summary populated or NULL-with-doc for all 26 other cities' officials
-- ============================================================

\echo ''
\echo '==================================================================='
\echo 'Phase 109 LA County Finance — Verification Gate'
\echo '==================================================================='

-- ============================================================
-- ASSERTION 1: LAFI-01 — confirmed la_socrata sources exist for LA City officials
-- Expected: confirmed_sources >= 15
-- (18 officials total; Lattimore is appointed and may have 0, Jurado may have 0)
-- ============================================================
\echo ''
\echo '--- ASSERTION 1: LAFI-01 — confirmed la_socrata sources exist for LA City officials ---'
\echo 'Expected: confirmed_sources >= 15 (18 officials; Lattimore + Jurado may have 0)'

SELECT COUNT(*) AS confirmed_sources
FROM transparent_motivations.politician_sources
WHERE source_system = 'la_socrata'
  AND research_status = 'confirmed';

-- ============================================================
-- ASSERTION 2: LAFI-01 — finance_summary coverage for la_socrata-sourced officials
-- Expected: officials_with_summary >= 15, officials_null_summary <= 3
-- (Lattimore appointed 2025-09, Jurado new, at most one other acceptable)
-- ============================================================
\echo ''
\echo '--- ASSERTION 2: LAFI-01 — finance_summary coverage for la_socrata-sourced officials ---'
\echo 'Expected: officials_with_summary >= 15, officials_null_summary <= 3'

SELECT
  COUNT(*) AS officials_with_confirmed_source,
  COUNT(p.finance_summary) AS officials_with_summary,
  COUNT(*) - COUNT(p.finance_summary) AS officials_null_summary
FROM essentials.politicians p
JOIN transparent_motivations.politician_sources ps
  ON ps.essentials_politician_id = p.id
WHERE ps.source_system = 'la_socrata'
  AND ps.research_status = 'confirmed';

-- ============================================================
-- ASSERTION 3: LAFI-01 — finance_summary shape integrity for la_socrata officials
-- Expected: bad_shape = 0
-- (Every non-null finance_summary with source=LA_SOCRATA must have total_raised + cycle)
-- ============================================================
\echo ''
\echo '--- ASSERTION 3: LAFI-01 — finance_summary shape integrity for la_socrata officials ---'
\echo 'Expected: bad_shape = 0'

SELECT COUNT(*) AS bad_shape
FROM essentials.politicians p
WHERE p.finance_summary IS NOT NULL
  AND p.finance_summary->>'source' = 'LA_SOCRATA'
  AND (
    p.finance_summary->>'total_raised' IS NULL
    OR p.finance_summary->>'cycle' IS NULL
  );

-- ============================================================
-- ASSERTION 4: LAFI-02 — confirmed la_county_netfile sources exist
-- Expected: netfile_sources >= 1 (at least one city accessible via Netfile)
-- ============================================================
\echo ''
\echo '--- ASSERTION 4: LAFI-02 — confirmed la_county_netfile sources exist ---'
\echo 'Expected: netfile_sources >= 1 (at least one city accessible via Netfile LACO)'

SELECT COUNT(*) AS netfile_sources
FROM transparent_motivations.politician_sources
WHERE source_system = 'la_county_netfile'
  AND research_status = 'confirmed';

-- ============================================================
-- ASSERTION 5: LAFI-02 — finance_summary coverage for la_county_netfile-sourced officials
-- Expected: officials_with_summary >= 1 when officials_with_netfile_source > 0
-- NULL summary acceptable only when ingest returned zero contributions
-- ============================================================
\echo ''
\echo '--- ASSERTION 5: LAFI-02 — finance_summary coverage for la_county_netfile-sourced officials ---'
\echo 'Expected: officials_with_summary >= 1 when officials_with_netfile_source > 0'

SELECT
  COUNT(*) AS officials_with_netfile_source,
  COUNT(p.finance_summary) AS officials_with_summary
FROM essentials.politicians p
JOIN transparent_motivations.politician_sources ps
  ON ps.essentials_politician_id = p.id
WHERE ps.source_system = 'la_county_netfile'
  AND ps.research_status = 'confirmed';

-- ============================================================
-- ASSERTION 6: LAFI-02 — finance_summary shape integrity for la_county_netfile officials
-- Expected: bad_shape = 0
-- (Every non-null finance_summary with source=LA_COUNTY_NETFILE must have total_raised + cycle)
-- ============================================================
\echo ''
\echo '--- ASSERTION 6: LAFI-02 — finance_summary shape integrity for la_county_netfile officials ---'
\echo 'Expected: bad_shape = 0'

SELECT COUNT(*) AS bad_shape
FROM essentials.politicians p
WHERE p.finance_summary IS NOT NULL
  AND p.finance_summary->>'source' = 'LA_COUNTY_NETFILE'
  AND (
    p.finance_summary->>'total_raised' IS NULL
    OR p.finance_summary->>'cycle' IS NULL
  );

-- ============================================================
-- ASSERTION 7: LAFI-01 + LAFI-02 negative — no placeholder or fabricated finance data
-- Expected: placeholder_rows = 0
-- (Every non-null finance_summary must use a valid source and have total_raised >= 0)
-- ============================================================
\echo ''
\echo '--- ASSERTION 7: LAFI-01 + LAFI-02 negative — no placeholder or fabricated finance_summary ---'
\echo 'Expected: placeholder_rows = 0'

SELECT COUNT(*) AS placeholder_rows
FROM essentials.politicians
WHERE finance_summary IS NOT NULL
  AND (
    finance_summary->>'source' NOT IN ('FEC', 'LA_SOCRATA', 'LA_COUNTY_NETFILE')
    OR (finance_summary->>'total_raised')::numeric < 0
  );

-- ============================================================
-- ASSERTION 8: LAFI-02 coverage report — per-city Netfile coverage for all 27 LA County cities
-- Expected: zero-row failures are non-blocking; this is a coverage report for reviewers.
-- Every row should show either politicians_with_netfile_source > 0 or a documented gap
-- in the Wave 2 SUMMARY.
-- ============================================================
\echo ''
\echo '--- ASSERTION 8: LAFI-02 — per-city Netfile coverage report (all 27 LA County cities) ---'
\echo 'Expected: coverage report only; zero-row cities are documented gaps, not blocking failures'

SELECT
  g.name AS city,
  COUNT(DISTINCT p.id) AS politicians_total,
  COUNT(DISTINCT ps.id) FILTER (
    WHERE ps.source_system = 'la_county_netfile'
      AND ps.research_status = 'confirmed'
  ) AS politicians_with_netfile_source,
  COUNT(DISTINCT p.id) FILTER (
    WHERE p.finance_summary IS NOT NULL
  ) AS politicians_with_summary
FROM essentials.governments g
JOIN essentials.chambers ch ON ch.government_id = g.id
JOIN essentials.offices o ON o.chamber_id = ch.id
JOIN essentials.politicians p ON p.office_id = o.id
LEFT JOIN transparent_motivations.politician_sources ps
  ON ps.essentials_politician_id = p.id
WHERE g.state = 'CA'
  AND g.name IN (
    'City of Los Angeles',
    'City of Long Beach',
    'City of Glendale',
    'City of Burbank',
    'City of Downey',
    'City of El Monte',
    'City of Inglewood',
    'City of Lancaster',
    'City of Norwalk',
    'City of Palmdale',
    'City of Pasadena',
    'City of Pomona',
    'City of Santa Clarita',
    'City of Torrance',
    'City of West Covina',
    'City of Beverly Hills',
    'City of Santa Monica',
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
GROUP BY g.name
ORDER BY g.name;

\echo ''
\echo '==================================================================='
\echo 'Verification complete. Review above for any unexpected counts.'
\echo 'LAFI-01: confirmed_sources >= 15, officials_with_summary >= 15,'
\echo '         officials_null_summary <= 3, bad_shape = 0'
\echo 'LAFI-02: netfile_sources >= 1, officials_with_summary >= 1 per city'
\echo '         with confirmed source, bad_shape = 0, placeholder_rows = 0'
\echo '==================================================================='
