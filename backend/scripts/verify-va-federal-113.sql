-- ============================================================
-- verify-va-federal-113.sql
-- Phase 113 Phase Gate — VA Federal House Reps Stances + Finance
-- Run: psql "$DATABASE_URL" -f backend/scripts/verify-va-federal-113.sql
--
-- 7 labeled assertions covering all Phase 113 success criteria.
-- Each assertion outputs a query result; zero-row failures or
-- unexpected counts indicate gaps to investigate.
-- Script tolerates zero rows — all assertions are SELECT counts only.
-- Exits 0 even before Wave 2 finance data exists (no error on empty state).
--
-- VAST-04: 105 politician_answers rows for 11 VA federal House reps (ext_id BETWEEN -5102011 AND -5102001)
-- VAST-05: Every answer row paired with politician_context containing at least one real source URL
-- VAFI-01: finance_summary populated for 11 VA federal House reps (FEC source)
-- VAFI-02: Per-rep finance coverage report; gaps documented in SUMMARY
-- ============================================================

\echo ''
\echo '==================================================================='
\echo 'Phase 113 VA Federal Stances + Finance — Verification Gate'
\echo '==================================================================='

-- ============================================================
-- ASSERTION 1: VAST-04 — politician_answers count for 11 VA federal House reps
-- Expected: answer_rows = 105 (matches migration 341 header)
-- Scope: external_id BETWEEN -5102011 AND -5102001
-- ============================================================
\echo ''
\echo '--- ASSERTION 1: VAST-04 — politician_answers count for 11 VA federal House reps ---'
\echo 'Expected: answer_rows = 105'

SELECT COUNT(*) AS answer_rows
FROM inform.politician_answers pa
JOIN essentials.politicians p ON p.id = pa.politician_id
WHERE p.external_id BETWEEN -5102011 AND -5102001;

-- ============================================================
-- ASSERTION 2: VAST-05 — every answer has a matching politician_context row
-- Expected: answers_missing_context = 0
-- Every politician_answers row must have a corresponding politician_context row.
-- ============================================================
\echo ''
\echo '--- ASSERTION 2: VAST-05 — every answer has a matching politician_context row ---'
\echo 'Expected: answers_missing_context = 0'

SELECT COUNT(*) AS answers_missing_context
FROM inform.politician_answers pa
JOIN essentials.politicians p ON p.id = pa.politician_id
WHERE p.external_id BETWEEN -5102011 AND -5102001
  AND NOT EXISTS (
    SELECT 1
    FROM inform.politician_context pc
    WHERE pc.politician_id = pa.politician_id
      AND pc.topic_id = pa.topic_id
  );

-- ============================================================
-- ASSERTION 3: VAST-05 — every politician_context has at least one source URL (no empty-array rows)
-- Expected: context_rows_without_sources = 0
-- A sourced stance requires sources IS NOT NULL and array_length >= 1.
-- ============================================================
\echo ''
\echo '--- ASSERTION 3: VAST-05 — every politician_context has at least one source URL (no empty-array rows) ---'
\echo 'Expected: context_rows_without_sources = 0'

SELECT COUNT(*) AS context_rows_without_sources
FROM inform.politician_context pc
JOIN essentials.politicians p ON p.id = pc.politician_id
WHERE p.external_id BETWEEN -5102011 AND -5102001
  AND (
    pc.sources IS NULL
    OR array_length(pc.sources, 1) IS NULL
    OR array_length(pc.sources, 1) = 0
  );

-- ============================================================
-- ASSERTION 4: VAST-04 negative — no politician_context rows with NULL reasoning
-- Expected: null_reasoning_rows = 0
-- Guards against stances written without sourced reasoning text.
-- ============================================================
\echo ''
\echo '--- ASSERTION 4: VAST-04 negative — no politician_context rows with NULL reasoning ---'
\echo 'Expected: null_reasoning_rows = 0'

SELECT COUNT(*) AS null_reasoning_rows
FROM inform.politician_context pc
JOIN essentials.politicians p ON p.id = pc.politician_id
WHERE p.external_id BETWEEN -5102011 AND -5102001
  AND pc.reasoning IS NULL;

-- ============================================================
-- ASSERTION 5: VAFI-01 — finance_summary coverage for 11 VA federal House reps
-- Expected before Wave 2: reps_with_summary = 0 (tolerant — Wave 2 will populate).
-- Expected after Wave 2: reps_with_summary >= 9
-- (Vindman/McGuire/Subramanyam/Walkinshaw may have no FEC ID on first run.)
-- ============================================================
\echo ''
\echo '--- ASSERTION 5: VAFI-01 — finance_summary coverage for 11 VA federal House reps ---'
\echo 'Expected before Wave 2: reps_with_summary = 0 (tolerant). After Wave 2: reps_with_summary >= 9'

SELECT
  COUNT(*) AS reps_total,
  COUNT(p.finance_summary) AS reps_with_summary,
  COUNT(*) - COUNT(p.finance_summary) AS reps_null_summary
FROM essentials.politicians p
WHERE p.external_id BETWEEN -5102011 AND -5102001;

-- ============================================================
-- ASSERTION 6: VAFI-01 — finance_summary shape integrity (source=FEC, total_raised present, cycle present)
-- Expected: bad_shape = 0
-- Every non-null finance_summary must identify as FEC with total_raised and cycle populated.
-- ============================================================
\echo ''
\echo '--- ASSERTION 6: VAFI-01 — finance_summary shape integrity (source=FEC, total_raised present, cycle present) ---'
\echo 'Expected: bad_shape = 0'

SELECT COUNT(*) AS bad_shape
FROM essentials.politicians
WHERE external_id BETWEEN -5102011 AND -5102001
  AND finance_summary IS NOT NULL
  AND (
    finance_summary->>'source' IS DISTINCT FROM 'FEC'
    OR finance_summary->>'total_raised' IS NULL
    OR finance_summary->>'cycle' IS NULL
  );

-- ============================================================
-- ASSERTION 7: VAFI-01 + VAFI-02 — per-rep finance coverage report
-- Expected: coverage report only; zero-row populated column is non-blocking (document gaps in SUMMARY).
-- Shows full_name, external_id, whether finance_summary is populated, and source.
-- ============================================================
\echo ''
\echo '--- ASSERTION 7: VAFI-01 + VAFI-02 — per-rep finance coverage report ---'
\echo 'Expected: coverage report only; NULL summary is pre-Wave 2 baseline (non-blocking)'

SELECT
  p.full_name,
  p.external_id,
  CASE WHEN p.finance_summary IS NOT NULL THEN 'populated' ELSE 'NULL' END AS summary_status,
  p.finance_summary->>'source' AS source
FROM essentials.politicians p
WHERE p.external_id BETWEEN -5102011 AND -5102001
ORDER BY p.external_id DESC;

\echo ''
\echo '==================================================================='
\echo 'Verification complete. Review above for any unexpected counts.'
\echo 'VAST-04: answer_rows = 105, answers_missing_context = 0'
\echo 'VAST-05: context_rows_without_sources = 0, null_reasoning_rows = 0'
\echo 'VAFI-01: reps_with_summary >= 9 (after Wave 2), bad_shape = 0'
\echo 'VAFI-02: per-rep coverage report reviewed; gaps documented in SUMMARY'
\echo '==================================================================='
