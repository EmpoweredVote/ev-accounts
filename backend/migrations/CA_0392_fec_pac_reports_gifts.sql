-- CA_0392_fec_pac_reports_gifts.sql
-- PAC money a campaign reported receiving (Schedule A line 11C) and refunding (Schedule B line 20C), summed per
-- report and per giving committee. The source of record for "took no PAC money over the career".
-- STATUS: APPLIED to prod 2026-11-18 via apply-migration-file.mjs after a dry run (operator approval: Chris Andrews,
--   "Approve, start building"). Post-verify passed.
--
-- Created 2026-11-18 with Chris Andrews. Steward slot CA_0392. Design: "PAC money over a whole career, from our
-- own database" (approved 2026-11-18).
--
-- WHY NOT contributions. One row per gift would be 3–4 million rows (~1.5 GB at contributions' row width), and
-- contributions is mid-copy (ev-cto 0038 Part D, CA_0381–CA_0389). A sum per (report, giver) is ~600k rows and
-- ~60–80 MB. Each report keeps its file_number, so every gift can still be found on fec.gov.
--
-- WHAT THIS ADDS.
--   fec_pac_reports  one row per campaign report that carries PAC money, with the report's OWN summary-page
--                    totals beside the sum of its itemized rows, so every report is checked against itself.
--                    source 'efiling' = the raw .fec filing (FEC's daily bulk zips, or docquery for the
--                    backfill); report_key is the report type and coverage period, so an amendment replaces
--                    its original. source 'api' = FEC's processed Schedule A/B for a whole cycle, used where no
--                    electronic filing exists (Senate before 2019, paper-era House); report_key 'api:<cycle>'.
--   fec_pac_efiling_days  one row per FEC daily e-filing zip read, so the nightly run knows where to start.
--   fec_pac_gifts    per report, per giving (or refunded) committee: received, refunded, number of gifts.
--                    giver_key is the FEC committee id, or 'NAME:<normalised name>' when the filing gave none.
--
-- Creates only; overwrites no value. RLS on, no policies: only ev_api (BYPASSRLS) reads and writes.
--
-- ROLLBACK:
--   drop table if exists transparent_motivations.fec_pac_efiling_days;
--   drop table if exists transparent_motivations.fec_pac_gifts;
--   drop table if exists transparent_motivations.fec_pac_reports;

create table if not exists transparent_motivations.fec_pac_reports (
  committee_id      text          not null check (committee_id ~ '^C[0-9]{8}$'),
  report_key        text          not null,
  cycle             smallint      not null check (cycle between 1976 and 2100 and cycle % 2 = 0),
  source            text          not null check (source in ('efiling', 'api')),
  file_number       bigint,
  form              text,         -- F3N / F3A / F3T for an e-filing; null for 'api'
  report_type       text,         -- Q1, Q2, 12G, 30G, YE, TER, ... ; null for 'api'
  coverage_start    date,
  coverage_end      date,
  line11c_total     numeric(14,2),           -- the filing's summary page; null for 'api'
  line20c_total     numeric(14,2),
  line11c_itemized  numeric(14,2) not null,  -- sum of its itemized 11C rows (memo rows excluded)
  line20c_itemized  numeric(14,2) not null,
  reconciled        boolean,                 -- itemized = summary within $1 or 0.5%; null for 'api'
  loaded_at         timestamptz   not null default now(),
  primary key (committee_id, report_key),
  check ((source = 'api') = (report_key like 'api:%'))
);
create index if not exists fec_pac_reports_by_cycle on transparent_motivations.fec_pac_reports (committee_id, cycle);

comment on table transparent_motivations.fec_pac_reports is
  'Campaign reports carrying PAC gifts (11C) or refunds to committees (20C), each with its own summary totals and '
  'the sum of its itemized rows. efiling = raw .fec filing, api = FEC processed data for a whole cycle. CA_0392.';

create table if not exists transparent_motivations.fec_pac_gifts (
  committee_id text          not null,
  report_key   text          not null,
  giver_key    text          not null,  -- FEC committee id, or 'NAME:<normalised name>'
  giver_id     text          check (giver_id is null or giver_id ~ '^C[0-9]{8}$'),
  giver_id_from text         check (giver_id_from in ('filing', 'name_match')),
                             -- name_match: the filing gave no id, and exactly one committee in that cycle's
                             -- FEC committee master carries the giver's name
  giver_name   text,
  received     numeric(14,2) not null default 0,
  refunded     numeric(14,2) not null default 0,
  n_gifts      integer       not null default 0,
  primary key (committee_id, report_key, giver_key),
  foreign key (committee_id, report_key)
    references transparent_motivations.fec_pac_reports (committee_id, report_key) on delete cascade,
  check ((giver_id is null) = (giver_key like 'NAME:%')),
  check ((giver_id is null) = (giver_id_from is null))
);

comment on table transparent_motivations.fec_pac_gifts is
  'Per campaign report, per giving committee: PAC money received (11C) and refunded (20C). Replaced whole when '
  'its report is amended (delete the report row; this cascades). CA_0392.';

create table if not exists transparent_motivations.fec_pac_efiling_days (
  day          date        primary key,  -- the FEC daily zip bulk-downloads/electronic/YYYYMMDD.zip
  zip_bytes    bigint,
  filings      integer     not null,     -- .fec files in the zip
  kept         integer     not null,     -- campaign reports of our committees that carried PAC money
  loaded_at    timestamptz not null default now()
);

comment on table transparent_motivations.fec_pac_efiling_days is
  'One row per FEC daily e-filing zip the PAC-career job has read. The next run starts after the latest day; '
  'a missing day is a gap to re-read. CA_0392.';

alter table transparent_motivations.fec_pac_reports enable row level security;
alter table transparent_motivations.fec_pac_gifts enable row level security;
alter table transparent_motivations.fec_pac_efiling_days enable row level security;
revoke all on transparent_motivations.fec_pac_reports, transparent_motivations.fec_pac_gifts,
  transparent_motivations.fec_pac_efiling_days from public, anon, authenticated;
grant select, insert, update, delete on transparent_motivations.fec_pac_reports,
  transparent_motivations.fec_pac_gifts, transparent_motivations.fec_pac_efiling_days to ev_api;

do $$
begin
  if to_regclass('transparent_motivations.fec_pac_reports') is null
     or to_regclass('transparent_motivations.fec_pac_gifts') is null then
    raise exception 'CA_0392: a table was not created';
  end if;
  if not has_table_privilege('ev_api', 'transparent_motivations.fec_pac_gifts', 'insert')
     or not has_table_privilege('ev_api', 'transparent_motivations.fec_pac_reports', 'delete') then
    raise exception 'CA_0392: ev_api cannot write the PAC tables';
  end if;
  if has_table_privilege('anon', 'transparent_motivations.fec_pac_gifts', 'select') then
    raise exception 'CA_0392: anon can read fec_pac_gifts';
  end if;
  if not (select relrowsecurity from pg_class where oid = 'transparent_motivations.fec_pac_reports'::regclass)
     or not (select relrowsecurity from pg_class where oid = 'transparent_motivations.fec_pac_gifts'::regclass)
     or not (select relrowsecurity from pg_class where oid = 'transparent_motivations.fec_pac_efiling_days'::regclass) then
    raise exception 'CA_0392: RLS is off';
  end if;
end
$$;
