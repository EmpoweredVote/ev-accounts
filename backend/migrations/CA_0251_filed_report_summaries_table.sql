-- CA_0251_filed_report_summaries_table.sql
-- Spec: docs/superpowers/specs/2026-09-24-filed-report-summaries-design.md
--
-- One row per filed campaign-finance summary sheet (Indiana CFA-4 first). It exists because a $0 report
-- leaves no contribution rows, so the only honest statement about such a politician -- "filed, $0 raised"
-- -- had nowhere to live, and Essentials told voters the filing was "being processed".
--
-- Money columns are NULL when the sheet's line is BLANK. Never coerce a blank to 0.
-- Rows are written only by reviewed migrations (scripts/cfa-summaries-to-migration.ts), never by the importer.
-- RLS default-deny (CTO decision 0015): reads go through pool.query.
-- ON DELETE RESTRICT: moving a link keeps its id; deleting a link that carries a report must fail loudly.

CREATE TABLE IF NOT EXISTS transparent_motivations.filed_report_summaries (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  politician_source_id  uuid NOT NULL REFERENCES transparent_motivations.politician_sources(id) ON DELETE RESTRICT,
  form                  text NOT NULL,
  report_type           text NOT NULL CHECK (report_type IN ('pre_primary','pre_election','annual','nomination','final','other')),
  is_amendment          boolean NOT NULL DEFAULT false,
  period_start          date NOT NULL,
  period_end            date NOT NULL,
  filed_on              date,
  filed_with            text NOT NULL,
  cash_start            numeric(14,2),
  receipts_itemized     numeric(14,2),
  receipts_unitemized   numeric(14,2),
  receipts_total        numeric(14,2),
  receipts_ytd          numeric(14,2),
  expenditures_total    numeric(14,2),
  expenditures_ytd      numeric(14,2),
  cash_end              numeric(14,2),
  debts_owed_by         numeric(14,2),
  debts_owed_to         numeric(14,2),
  source_pdf            text NOT NULL,
  source                text NOT NULL,
  created_at            timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT filed_report_summaries_period_chk CHECK (period_end >= period_start),
  CONSTRAINT filed_report_summaries_uniq UNIQUE (politician_source_id, form, report_type, period_start, period_end, is_amendment)
);

CREATE INDEX IF NOT EXISTS filed_report_summaries_source_idx
  ON transparent_motivations.filed_report_summaries (politician_source_id);

ALTER TABLE transparent_motivations.filed_report_summaries ENABLE ROW LEVEL SECURITY;

COMMENT ON TABLE transparent_motivations.filed_report_summaries IS
  'One row per filed campaign-finance summary sheet (CFA-4 first). NULL money = blank line on the sheet. Written only by reviewed migrations. CA_0251.';

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM information_schema.columns
   WHERE table_schema = 'transparent_motivations' AND table_name = 'filed_report_summaries';
  IF n <> 22 THEN RAISE EXCEPTION 'CA_0251: expected 22 columns, found %', n; END IF;
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid = 'transparent_motivations.filed_report_summaries'::regclass) THEN
    RAISE EXCEPTION 'CA_0251: RLS not enabled';
  END IF;
END $$;
