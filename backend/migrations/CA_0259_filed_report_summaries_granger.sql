-- CA_0259: filed CFA-4 summary sheets (1 report).
-- Generated 2026-09-24 by scripts/cfa-summaries-to-migration.ts from a CSV reviewed against the PDFs.
-- Spec: docs/superpowers/specs/2026-09-24-filed-report-summaries-design.md
-- Each row attaches to the politician's ONE confirmed IN_MONROE_COUNTY_LOCAL candidate committee. Zero or two
-- such links would write 0 or 2 rows, which the gate below refuses. NULL = the line was blank on the sheet.
-- *_derived = a blank 15c / 17c filled from the sheet's own arithmetic (16 − 13, 16 − 18); CA_0257 CHECKs it.
-- IDEMPOTENT: ON CONFLICT DO NOTHING; a re-run writes nothing and the gate still passes.

-- 1. Dorothy Granger — pre_primary 2026-01-01..2026-04-10 (Granger, Dorothy/CFA-4_Pre-Primary2026.pdf)
INSERT INTO transparent_motivations.filed_report_summaries
  (politician_source_id, form, report_type, is_amendment, period_start, period_end, filed_on, filed_with,
   cash_start, receipts_itemized, receipts_unitemized, receipts_total, receipts_ytd, total_available, expenditures_total, expenditures_ytd, cash_end, debts_owed_by, debts_owed_to, receipts_total_derived, expenditures_total_derived, source_pdf, source)
SELECT ps.id, 'CFA-4', 'pre_primary', false, '2026-01-01', '2026-04-10',
       '2026-04-15', 'Monroe Circuit Court Clerk',
       '0.00', NULL, NULL, '0.00', NULL, '0.00', '0.00', NULL, '0.00', '0.00', '0.00', true, true,
       'Granger, Dorothy/CFA-4_Pre-Primary2026.pdf', 'CA_0259'
  FROM transparent_motivations.politician_sources ps
 WHERE ps.essentials_politician_id = '06464416-e8f4-4df1-af4c-2d785863721e'
   AND ps.source_system = 'IN_MONROE_COUNTY_LOCAL'
   AND ps.research_status = 'confirmed'
   AND ps.source_type = 'candidate_committee'
ON CONFLICT ON CONSTRAINT filed_report_summaries_uniq DO NOTHING;

DO $$
DECLARE n int; s numeric;
BEGIN
  SELECT count(*), COALESCE(sum(COALESCE(receipts_total, 0)), 0) INTO n, s
    FROM transparent_motivations.filed_report_summaries WHERE source = 'CA_0259';
  IF n <> 1 THEN RAISE EXCEPTION 'CA_0259: expected 1 rows, found %', n; END IF;
  IF s <> 0.00 THEN RAISE EXCEPTION 'CA_0259: receipts_total sum % <> 0.00', s; END IF;
END $$;
