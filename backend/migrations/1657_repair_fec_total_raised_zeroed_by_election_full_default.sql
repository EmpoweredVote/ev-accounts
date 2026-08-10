-- Migration 1657: repair total_raised on the 70 finance_summary rows the FEC
--                 loader silently zeroed
--
-- ============================================================================
-- ROOT CAUSE (fixed in code alongside this migration)
-- ============================================================================
-- scripts/run-fec-finance-summary.ts and scripts/ehn-fec-finance.ts both called
--   GET /v1/candidates/totals/?candidate_id=X&cycle=2026
-- and ended with `return Number(data.results[0]?.receipts ?? 0)`.
--
-- `election_full` defaults to TRUE on that endpoint, which asks for totals over the
-- candidate's full ELECTION cycle rather than the two-year period. A member who is not
-- on the 2026 ballot has no 2026 election cycle, so FEC returned ZERO results -- and
-- `?? 0` recorded that absence as a genuine $0.
--
-- Confirmed against the live API for Alex Padilla (S2CA00955, election_years [2022, 2028]):
--   cycle=2026                      -> 0 results        -> stored $0
--   cycle=2026&election_full=false  -> receipts 1502700.32
--
-- 70 rows carried `"cycle":"2026","total_raised":0`, and 67 of them had itemized
-- top_donors sitting right beside the zero -- the tell that the zero was never real.
--
-- ============================================================================
-- WHAT THIS MIGRATION WRITES
-- ============================================================================
-- Re-fetched all 70 with election_full=false (2026-08-09):
--   65 rows  -> real receipts, restored below. Combined total: $217,222,685.32
--   5 rows  -> `total_raised` key REMOVED rather than left at 0 (see below)
--
-- Largest corrections: Mark Kelly $40,775,022.69, Bernie Sanders $24,928,186.19,
-- Chris Murphy $13,308,354.14, Andy Barr $9,981,055.48, John Kennedy $9,951,156.42.
--
-- The key is REMOVED, not set to 0, for two distinct reasons -- in both cases we do not
-- know the figure, and an absent key reads as unknown while 0 asserts a fact:
--   * 3 rows (H0TX07170 Wesley Hunt, H4MA06090 Seth Moulton, S0NH00201) return no
--     totals row even WITH election_full=false. Genuinely unknown.
--   * 2 rows are a CROSSWALK defect, not a totals defect: Adam Schiff (H0CA27085) and
--     Jim Banks (H6IN03229) are SENATORS whose transparent_motivations.politician_sources
--     row still points at their old HOUSE candidate id (H-prefix). Those dormant House
--     committees really did raise $0, but that is not a fact about the senator. Their
--     Senate committee totals remain unknown until the crosswalk is repointed.
--     🔴 FOLLOW-UP: repoint Schiff and Banks to their Senate FEC candidate ids.
--
-- This matches the code fix: fetchTotalRaised now returns null instead of 0, and the
-- callers omit the key entirely rather than writing a number they do not have.
--
-- Guarded on `total_raised = 0` so it is idempotent and cannot overwrite a corrected
-- value on replay. Joined via politician_sources.external_id, the same crosswalk the
-- loader uses.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Restore the 65 real totals.
-- ---------------------------------------------------------------------------
WITH fec_totals(fec_id, receipts) AS (
  VALUES
    ('H0VA07133', 1781840.34),
    ('H2CA28113', 32.42),
    ('S0AR00150', 507948.80),
    ('S0AZ00350', 40775022.69),
    ('S0CO00211', 213775.00),
    ('S0CT00177', 612252.45),
    ('S0IA00028', 328050.45),
    ('S0KS00091', 1301304.17),
    ('S0KY00156', 3928653.80),
    ('S0ND00093', 389847.03),
    ('S0NY00410', 2803029.34),
    ('S0UT00165', 2255168.97),
    ('S0WI00197', 1087713.28),
    ('S2AL00145', 2706560.51),
    ('S2CA00955', 1502700.32),
    ('S2CT00132', 13308354.14),
    ('S2HI00106', 562722.93),
    ('S2MA00170', 4413931.40),
    ('S2ME00109', 64111.13),
    ('S2MO00544', 3340312.22),
    ('S2NC00505', 1307989.26),
    ('S2NE00094', 831699.62),
    ('S2NM00088', 1459066.06),
    ('S2PA00661', 5402323.53),
    ('S2SD00068', 4141899.89),
    ('S2VA00142', 787827.87),
    ('S2VT00235', 218689.73),
    ('S2WA00189', 2800143.55),
    ('S2WI00219', 2823440.81),
    ('S4AK00099', 1287064.23),
    ('S4AZ00139', 4345411.03),
    ('S4DE00060', 1016908.07),
    ('S4HI00136', 1484359.04),
    ('S4LA00065', 9951156.42),
    ('S4MD00327', 1768461.20),
    ('S4MI00470', 5242246.82),
    ('S4MT00183', 1524206.08),
    ('S4NJ00466', 1659590.26),
    ('S4OH00192', 2734380.58),
    ('S4OK00232', 988742.02),
    ('S4SC00240', 5328235.86),
    ('S4UT00282', 737002.94),
    ('S4VT00033', 24928186.19),
    ('S4WV00332', 79577.55),
    ('S6IL00292', 5148750.00),
    ('S6IN00191', 4401018.38),
    ('S6KY00286', 9981055.48),
    ('S6MA00296', 5651172.00),
    ('S6MD03441', 1973280.44),
    ('S6MN00267', 2516029.34),
    ('S6NH00091', 2539768.24),
    ('S6NV00200', 2219394.25),
    ('S6OR00110', 1615078.40),
    ('S6PA00274', 2313557.84),
    ('S6RI00221', 500288.30),
    ('S6WY00068', 1554351.61),
    ('S8FL00273', 1582501.06),
    ('S8ID00027', 1090241.69),
    ('S8MO00160', 1696757.65),
    ('S8MS00196', 224073.35),
    ('S8ND00120', 1139407.09),
    ('S8NV00156', 1475853.35),
    ('S8NY00082', 990635.71),
    ('S8TN00337', 3087690.15),
    ('S8WA00194', 789840.99)
)
UPDATE essentials.politicians p
SET finance_summary = jsonb_set(p.finance_summary, '{total_raised}', to_jsonb(f.receipts))
FROM transparent_motivations.politician_sources ps, fec_totals f
WHERE ps.essentials_politician_id = p.id
  AND ps.source_system LIKE 'fec%'
  AND ps.external_id = f.fec_id
  AND p.finance_summary->>'cycle' = '2026'
  AND (p.finance_summary->>'total_raised')::numeric = 0;

-- ---------------------------------------------------------------------------
-- 2. Drop the false zero where the real figure is unknown.
-- ---------------------------------------------------------------------------
WITH unknown_total(fec_id) AS (
  VALUES
    ('H0CA27085'),
    ('H0TX07170'),
    ('H4MA06090'),
    ('H6IN03229'),
    ('S0NH00201')
)
UPDATE essentials.politicians p
SET finance_summary = p.finance_summary - 'total_raised'
FROM transparent_motivations.politician_sources ps, unknown_total u
WHERE ps.essentials_politician_id = p.id
  AND ps.source_system LIKE 'fec%'
  AND ps.external_id = u.fec_id
  AND p.finance_summary->>'cycle' = '2026'
  AND (p.finance_summary->>'total_raised')::numeric = 0;

COMMIT;
