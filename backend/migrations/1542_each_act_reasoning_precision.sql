-- 1542_each_act_reasoning_precision.sql
--
-- Correct one sentence written by migration 1541, in the row it wrote for
-- Val Hoyle / Reproductive Rights and Abortion Access. The chair does not change; the citation does not
-- change; only a clause that the cited page does not support is replaced with what the page does say.
--
--   Review: data/stance-research/pretenure-reresearch/ADJUDICATION-TRANCHE-3.md
--   Rollback: restore the previous `reasoning` string, which is quoted verbatim in the WHERE clause
--             below, so this migration is exactly reversible from its own text.
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1542_each_act_reasoning_precision.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- WHAT WAS WRONG, AND HOW IT GOT PAST ME
-- ---------------------------------------------------------------------------------------------------
-- 1541's row said the EACH Act would "permit premium tax credits to pay for it". That phrasing came from
-- the CRS summary in BILLSTATUS, which describes it as a downstream CONSEQUENCE of repealing ACA
-- section 1303 -- section 1303 is what requires segregation of subsidy funds from abortion coverage.
-- CRS is not wrong. But the page the row CITES is the bill text, and the bill text contains no
-- tax-credit, section 36B, cost-sharing, exchange, or qualified-health-plan language at all; its
-- section 5 simply reads "Section 1303 of the Patient Protection and Affordable Care Act (42 U.S.C.
-- 18023) is repealed."
--
-- 🔴 THIS IS THE EXACT DEFECT CLASS THE WHOLE WORKSTREAM EXISTS TO REMOVE -- a claim that is true in
-- substance but is not carried by the source cited beside it. Migrations 1494/1507/1508 retired 1,157
-- rows for it. Writing it into a repair migration, one day after documenting the rule, is worth
-- recording plainly rather than quietly fixing.
--
-- HOW IT WAS CAUGHT: after applying 1541 I held its own 9 rows to the standard
-- `audit-stance-citations.mjs` applies -- fetch each cited page and check that the row's distinctive
-- claim terms appear in the body. 15 of 16 citations carried every term. This was the sixteenth.
-- ⚠ The lesson is narrower than "verify sources": it is that a CRS SUMMARY AND THE BILL TEXT ARE
-- DIFFERENT DOCUMENTS. Reasoning drawn from the summary must either cite the summary or be reworded to
-- what the text says. Here it is reworded, because the bill text is the stronger citation.
--
-- The chair is unaffected. Chair 1 rests on section 4(a), which requires the health programs defined in
-- section 3(2) -- Medicaid, CHIP and Medicare are named there explicitly -- to cover abortion services.
-- That is public funding, stated on the page, and it remains the reason this is chair 1 rather than a
-- position that keeps abortion legal without paying for it.

BEGIN;

UPDATE inform.politician_context
   SET reasoning = 'Hoyle was an original co-sponsor of the EACH Act, which would require the federal health programs it defines — Medicaid, the Children''s Health Insurance Program and Medicare among them — to cover abortion services, require the federal government to ensure access to those services in facilities it runs or contracts with, and repeal section 1303 of the Affordable Care Act. She was also an original co-sponsor of the Women''s Health Protection Act, which bars governmental restrictions on abortion before viability and permits it afterward where a patient''s life or health requires it. Public funding is the element that separates this position from one that keeps abortion legal and accessible without paying for it, and the EACH Act is an affirmative commitment to it.'
 WHERE politician_id = 'f6202cef-4e46-4db5-a9c0-c69ac9a8eccd'
   AND topic_id      = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'
   AND reasoning     = 'Hoyle was an original co-sponsor of the EACH Act, which would require Medicaid, Medicare and CHIP to cover abortion, repeal the provisions letting states bar coverage in exchange plans, and permit premium tax credits to pay for it. She was also an original co-sponsor of the Women''s Health Protection Act, which bars governmental restrictions on abortion before viability and permits it afterward where a patient''s life or health requires it. Public funding is the element that separates this position from one that keeps abortion legal and accessible without paying for it, and the EACH Act is an affirmative commitment to it.';

DO $$
DECLARE v_n int;
BEGIN
  -- A 0-row UPDATE means the text drifted; a 2-row UPDATE means the key is not unique. Both are bugs.
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE politician_id = 'f6202cef-4e46-4db5-a9c0-c69ac9a8eccd'
     AND topic_id      = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'
     AND reasoning LIKE '%repeal section 1303 of the Affordable Care Act%';
  IF v_n <> 1 THEN RAISE EXCEPTION 'expected exactly 1 corrected row, found % — the prior text did not match', v_n; END IF;

  -- The unsupported clause must be gone.
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE politician_id = 'f6202cef-4e46-4db5-a9c0-c69ac9a8eccd'
     AND topic_id      = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'
     AND reasoning ILIKE '%premium tax credit%';
  IF v_n <> 0 THEN RAISE EXCEPTION 'the unsupported premium-tax-credit clause survives'; END IF;

  -- Chair and citations must be untouched by this migration.
  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE politician_id = 'f6202cef-4e46-4db5-a9c0-c69ac9a8eccd'
     AND topic_id      = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'
     AND value = 1;
  IF v_n <> 1 THEN RAISE EXCEPTION 'chair is no longer 1 — this migration must not change it'; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE politician_id = 'f6202cef-4e46-4db5-a9c0-c69ac9a8eccd'
     AND topic_id      = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'
     AND sources = ARRAY['https://www.govinfo.gov/content/pkg/BILLS-118hr561ih/html/BILLS-118hr561ih.htm',
                         'https://www.govinfo.gov/content/pkg/BILLS-118hr12ih/html/BILLS-118hr12ih.htm'];
  IF v_n <> 1 THEN RAISE EXCEPTION 'sources changed — this migration must not touch them'; END IF;
END $$;

COMMIT;
