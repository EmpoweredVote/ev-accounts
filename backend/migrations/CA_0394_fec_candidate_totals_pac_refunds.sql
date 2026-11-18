-- CA_0394_fec_candidate_totals_pac_refunds.sql
-- Two columns on fec_candidate_totals that the PAC-career check needs: refunds to committees, and how far the
-- totals reach.
-- STATUS: APPLIED to prod 2026-11-18 via apply-migration-file.mjs after a dry run (operator approval: Chris Andrews,
--   "Approve, start building"). Post-verify passed.
--
-- Created 2026-11-18 with Chris Andrews. Steward slot CA_0394. Design: "PAC money over a whole career, from our
-- own database" (approved 2026-11-18).
--
-- WHY. A person's PAC verdict is on money KEPT (gifts minus refunds), and each cycle's itemized gifts must add up
-- to FEC's own total for that cycle. FEC's candidate totals carry both figures
-- (refunded_other_political_committee_contributions, coverage_end_date); the table kept neither. The table was
-- also filled once (2026-07-21, 630 of 1,661 ids) and never refreshed; the weekly fec-candidate-totals job now
-- refreshes it and fills the missing ids.
--
-- Adds nullable columns only; overwrites no value. Existing rows keep NULL until the next refresh.
-- The table is owned by ev_api, so this runs as ev_api.
--
-- ROLLBACK:
--   alter table transparent_motivations.fec_candidate_totals drop column if exists pac_refunds,
--     drop column if exists coverage_end_date;

set local role ev_api;

alter table transparent_motivations.fec_candidate_totals
  add column if not exists pac_refunds       numeric(16,2),
  add column if not exists coverage_end_date date;

comment on column transparent_motivations.fec_candidate_totals.pac_refunds is
  'FEC refunded_other_political_committee_contributions for the cycle (Schedule B line 20C). CA_0394.';
comment on column transparent_motivations.fec_candidate_totals.coverage_end_date is
  'FEC coverage_end_date: the last day these totals cover. CA_0394.';

reset role;

do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'transparent_motivations'
                   and table_name = 'fec_candidate_totals' and column_name = 'pac_refunds')
     or not exists (select 1 from information_schema.columns where table_schema = 'transparent_motivations'
                   and table_name = 'fec_candidate_totals' and column_name = 'coverage_end_date') then
    raise exception 'CA_0394: a column was not added';
  end if;
end
$$;
