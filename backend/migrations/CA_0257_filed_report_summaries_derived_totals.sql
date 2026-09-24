-- CA_0257_filed_report_summaries_derived_totals.sql
-- Spec: docs/superpowers/specs/2026-09-24-filed-report-summaries-design.md (§ Derived totals, operator ruling 2026-09-24)
--
-- Filers often leave line 15c ("raised") and 17c ("spent") BLANK on a $0 CFA-4 while writing 0 on lines 13, 16
-- and 18 (Dorothy Granger's pre-primary 2026). CA_0251 stores blanks as NULL, so her panel would read
-- "Raised — · Spent —" for a report that says $0. The sheet's own arithmetic answers it:
--   line 16 = line 13 + line 15c   ⇒ 15c = 16 − 13
--   line 18 = line 16 − line 17c   ⇒ 17c = 16 − 18
-- So a blank 15c / 17c may be filled from the sheet — never guessed — and the row says it was.
--
--   total_available            line 16, column A, as written (NULL = blank)
--   receipts_total_derived     receipts_total came from 16 − 13, not from line 15c
--   expenditures_total_derived expenditures_total came from 16 − 18, not from line 17c
--
-- A derived flag with no value is refused by CHECK. Table is empty at this migration, so the
-- DEFAULT false is exact for every existing row. IDEMPOTENT.

ALTER TABLE transparent_motivations.filed_report_summaries
  ADD COLUMN IF NOT EXISTS total_available            numeric(14,2),
  ADD COLUMN IF NOT EXISTS receipts_total_derived     boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS expenditures_total_derived boolean NOT NULL DEFAULT false;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'filed_report_summaries_receipts_derived_chk') THEN
    ALTER TABLE transparent_motivations.filed_report_summaries
      ADD CONSTRAINT filed_report_summaries_receipts_derived_chk
      CHECK (NOT receipts_total_derived OR (receipts_total IS NOT NULL AND total_available IS NOT NULL AND cash_start IS NOT NULL));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'filed_report_summaries_expenditures_derived_chk') THEN
    ALTER TABLE transparent_motivations.filed_report_summaries
      ADD CONSTRAINT filed_report_summaries_expenditures_derived_chk
      CHECK (NOT expenditures_total_derived OR (expenditures_total IS NOT NULL AND total_available IS NOT NULL AND cash_end IS NOT NULL));
  END IF;
END $$;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM information_schema.columns
   WHERE table_schema = 'transparent_motivations' AND table_name = 'filed_report_summaries';
  IF n <> 25 THEN RAISE EXCEPTION 'CA_0257: expected 25 columns, found %', n; END IF;
  SELECT count(*) INTO n FROM pg_constraint
   WHERE conname IN ('filed_report_summaries_receipts_derived_chk', 'filed_report_summaries_expenditures_derived_chk');
  IF n <> 2 THEN RAISE EXCEPTION 'CA_0257: expected 2 derived-flag CHECKs, found %', n; END IF;
END $$;
