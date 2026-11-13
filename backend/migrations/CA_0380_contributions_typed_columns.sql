-- CA_0380_contributions_typed_columns.sql
-- Promote the raw_record JSON keys that the site and the FEC scripts read into real columns on
-- transparent_motivations.contributions, and fill them on every write with a trigger.
--
-- Created 2026-11-13 with Chris Andrews. Steward slot CA_0380. ev-cto decision 0038, Part D step 1.
-- Plan: ev-cto tasks/2026-11-13-disk-io-d2-copy-plan.md. Inventory: tasks/2026-11-13-disk-io-d1-raw-record-inventory.md.
--
-- WHY. raw_record is ~80% of every contributions row (33 GB table). Part D moves it out. Before it can go,
-- every key that is read must live in a column. This file only ADDS: nothing reads the new columns yet, and
-- raw_record is untouched. Readers switch in the next PR (with a raw_record fallback); the copy into a
-- compact table, which fills the columns for the existing ~29.1M rows, is a later step.
--
-- WHAT THIS ADDS
--   28 nullable columns (no default, so ADD COLUMN is a catalog change only — no table rewrite).
--   transparent_motivations.contribution_typed            composite type with those 28 fields
--   transparent_motivations.contribution_typed_fields(jsonb)  the ONE mapping from JSON keys to columns.
--     The trigger, the later copy and its row-by-row check all call it, so the mapping exists once.
--   trigger contributions_fill_typed (BEFORE INSERT OR UPDATE): when raw_record is set on insert, or changes
--     on update, every typed column is recomputed from it. So all 7 adapters, the admin "move" route and the
--     scripts fill the columns with no code change. Rows whose raw_record is NULL are left alone.
--
-- COLUMN CHOICES (changed from the D1 list after reading every reader, 2026-11-13):
--   * Name and entity-code keys get ONE COLUMN PER JSON KEY (src_<key>), not a merged column. Three readers
--     combine the name keys in three different orders (DONOR_NAME_SQL; identify-legal-donors.ts;
--     backfill-donor-name-normalized.ts), and one falls back to donor_name_normalized. A merged column
--     cannot reproduce all three, so a merge would change what pages show. Per-key columns make every
--     reader an exact rename. Sparse: each row fills only its own source's keys.
--   * Employer, occupation, city, state ARE merged (donor_*): every reader reads them as
--     COALESCE(contributor_x, con_x) in that order, in SQL and in TypeScript.
--   * No fec_sub_id: source_transaction_id already holds the FEC sub_id (fecAdapter.ts).
--   * fec_file_number_present: ~3% of FEC rows hold the key with a JSON null. Supersession and
--     backfill-fec-file-numbers.ts test key EXISTENCE (raw_record ? 'file_number'), so it is kept exactly.
--   * Values are copied as raw_record->>'key' (JSON null and absent both become NULL, as ->> reads them
--     today). report_year -> int and file_number -> bigint as the readers already cast them; a value that
--     is not a whole number becomes NULL (measured: none in a 0.05% sample). is_individual is a JSON
--     boolean (measured: always) -> boolean.
--
-- LOCKS. ADD COLUMN and CREATE TRIGGER each take a brief exclusive lock. lock_timeout 3s: if a long
-- query holds the table, this fails fast instead of queueing every reader behind it. Re-run later.
--
-- Creates only; overwrites no stored value.
--
-- STATUS: APPLIED to production 2026-11-13 16:16 UTC (apply-migration-file.mjs); post-verify passed. Dry-run read-back:
--   6,115 sampled rows across all 5 sources re-fired the trigger, 0 mismatches against raw_record. Five tamper
--   controls each failed on their own gate (mapping x2, trigger name, column name, trigger assignment).
--
-- ROLLBACK (no data lives only in these columns until raw_record is dropped):
--   drop trigger if exists contributions_fill_typed on transparent_motivations.contributions;
--   drop function if exists transparent_motivations.contributions_fill_typed();
--   drop function if exists transparent_motivations.contribution_typed_fields(jsonb);
--   alter table transparent_motivations.contributions drop column if exists src_contributor_name, ... (all 28);
--   drop type if exists transparent_motivations.contribution_typed;

set local lock_timeout = '3s';

-- Idempotent: a re-run drops and recreates the type and its mapping function (nothing else depends on them).
drop function if exists transparent_motivations.contribution_typed_fields(jsonb);
drop type if exists transparent_motivations.contribution_typed;
create type transparent_motivations.contribution_typed as (
  -- donor name parts, one column per source key
  src_contributor_name          text,   -- FEC
  src_con_name                  text,   -- LA Socrata
  src_tran_naml                 text,   -- NetFile
  src_tran_namf                 text,   -- NetFile
  src_contributorname           text,   -- Indiana  (ContributorName)
  src_ctrib_naml                text,   -- Cal-Access (CTRIB_NAML)
  src_ctrib_namf                text,   -- Cal-Access (CTRIB_NAMF)
  -- donor detail, merged: COALESCE(contributor_x, con_x) everywhere
  donor_employer                text,
  donor_occupation              text,
  donor_city                    text,
  donor_state                   text,
  -- donor type inputs, one column per source key
  src_type                      text,   -- Indiana CFA-4 'type'
  src_entity_type               text,   -- FEC / Socrata / NetFile
  src_entity_cd                 text,   -- Cal-Access ENTITY_CD
  src_contributortype           text,   -- Indiana ContributorType
  src_recordtypedescription     text,   -- OCPF recordTypeDescription
  src_is_individual             boolean,-- pre-2004 FEC
  src_contributor_committee_id  text,   -- pre-slim FEC
  -- LA independent-expenditure / matching-funds exclusion
  src_schedule                  text,
  src_con_desc                  text,
  -- FEC filing identity (supersession, retirement scripts) and audit
  fec_committee_id              text,
  fec_report_year               integer,
  fec_report_type               text,
  fec_file_number               bigint,
  fec_file_number_present       boolean,
  fec_memo_code                 text,
  fec_transaction_id            text,
  fec_amendment_indicator       text
);

create or replace function transparent_motivations.contribution_typed_fields(r jsonb)
returns transparent_motivations.contribution_typed
language sql
immutable
parallel safe
set search_path to 'pg_catalog'
as $$
  select row(
    r->>'contributor_name',
    r->>'con_name',
    r->>'Tran_NamL',
    r->>'Tran_NamF',
    r->>'ContributorName',
    r->>'CTRIB_NAML',
    r->>'CTRIB_NAMF',
    coalesce(r->>'contributor_employer',   r->>'con_empr'),
    coalesce(r->>'contributor_occupation', r->>'con_occp'),
    coalesce(r->>'contributor_city',       r->>'con_city_nm'),
    coalesce(r->>'contributor_state',      r->>'con_state_nm'),
    r->>'type',
    r->>'entity_type',
    r->>'ENTITY_CD',
    r->>'ContributorType',
    r->>'recordTypeDescription',
    case jsonb_typeof(r->'is_individual')
      when 'boolean' then (r->'is_individual')::boolean
      when 'string'  then (r->>'is_individual') = 'true'
    end,
    r->>'contributor_committee_id',
    r->>'schedule',
    r->>'con_desc',
    r->>'committee_id',
    case when r->>'report_year' ~ '^-?[0-9]{1,9}$' then (r->>'report_year')::integer end,
    r->>'report_type',
    case when r->>'file_number' ~ '^-?[0-9]{1,18}$' then (r->>'file_number')::bigint end,
    case when r is null then null else r ? 'file_number' end,
    r->>'memo_code',
    r->>'transaction_id',
    r->>'amendment_indicator'
  )::transparent_motivations.contribution_typed
$$;

comment on function transparent_motivations.contribution_typed_fields(jsonb) is
  'The one mapping from contributions.raw_record keys to the typed columns (CA_0380). Used by the fill '
  'trigger, the Part D copy and its row-by-row check. Change it only together with all three.';

alter table transparent_motivations.contributions
  add column if not exists src_contributor_name         text,
  add column if not exists src_con_name                 text,
  add column if not exists src_tran_naml                text,
  add column if not exists src_tran_namf                text,
  add column if not exists src_contributorname          text,
  add column if not exists src_ctrib_naml               text,
  add column if not exists src_ctrib_namf               text,
  add column if not exists donor_employer               text,
  add column if not exists donor_occupation             text,
  add column if not exists donor_city                   text,
  add column if not exists donor_state                  text,
  add column if not exists src_type                     text,
  add column if not exists src_entity_type              text,
  add column if not exists src_entity_cd                text,
  add column if not exists src_contributortype          text,
  add column if not exists src_recordtypedescription    text,
  add column if not exists src_is_individual            boolean,
  add column if not exists src_contributor_committee_id text,
  add column if not exists src_schedule                 text,
  add column if not exists src_con_desc                 text,
  add column if not exists fec_committee_id             text,
  add column if not exists fec_report_year              integer,
  add column if not exists fec_report_type              text,
  add column if not exists fec_file_number              bigint,
  add column if not exists fec_file_number_present      boolean,
  add column if not exists fec_memo_code                text,
  add column if not exists fec_transaction_id           text,
  add column if not exists fec_amendment_indicator      text;

create or replace function transparent_motivations.contributions_fill_typed()
returns trigger
language plpgsql
set search_path to 'transparent_motivations', 'pg_catalog'
as $$
declare
  t transparent_motivations.contribution_typed;
begin
  if new.raw_record is null then
    return new;
  end if;
  if tg_op = 'UPDATE' and new.raw_record is not distinct from old.raw_record then
    return new;
  end if;
  t := transparent_motivations.contribution_typed_fields(new.raw_record);
  new.src_contributor_name         := t.src_contributor_name;
  new.src_con_name                 := t.src_con_name;
  new.src_tran_naml                := t.src_tran_naml;
  new.src_tran_namf                := t.src_tran_namf;
  new.src_contributorname          := t.src_contributorname;
  new.src_ctrib_naml               := t.src_ctrib_naml;
  new.src_ctrib_namf               := t.src_ctrib_namf;
  new.donor_employer               := t.donor_employer;
  new.donor_occupation             := t.donor_occupation;
  new.donor_city                   := t.donor_city;
  new.donor_state                  := t.donor_state;
  new.src_type                     := t.src_type;
  new.src_entity_type              := t.src_entity_type;
  new.src_entity_cd                := t.src_entity_cd;
  new.src_contributortype          := t.src_contributortype;
  new.src_recordtypedescription    := t.src_recordtypedescription;
  new.src_is_individual            := t.src_is_individual;
  new.src_contributor_committee_id := t.src_contributor_committee_id;
  new.src_schedule                 := t.src_schedule;
  new.src_con_desc                 := t.src_con_desc;
  new.fec_committee_id             := t.fec_committee_id;
  new.fec_report_year              := t.fec_report_year;
  new.fec_report_type              := t.fec_report_type;
  new.fec_file_number              := t.fec_file_number;
  new.fec_file_number_present      := t.fec_file_number_present;
  new.fec_memo_code                := t.fec_memo_code;
  new.fec_transaction_id           := t.fec_transaction_id;
  new.fec_amendment_indicator      := t.fec_amendment_indicator;
  return new;
end
$$;

drop trigger if exists contributions_fill_typed on transparent_motivations.contributions;
create trigger contributions_fill_typed
  before insert or update on transparent_motivations.contributions
  for each row execute function transparent_motivations.contributions_fill_typed();

-- Post-verify.
do $$
declare
  n_cols int;
  probe  transparent_motivations.contribution_typed;
  got_name   text;
  got_fileno bigint;
begin
  select count(*) into n_cols
    from pg_attribute ta
   where ta.attrelid = 'transparent_motivations.contribution_typed'::regclass
     and ta.attnum > 0 and not ta.attisdropped;
  if n_cols <> 28 then
    raise exception 'CA_0380: expected 28 fields in contribution_typed, found %', n_cols;
  end if;

  -- Every field of the type is a column on contributions, same name and same type. (A count of columns
  -- alone passed a tamper that renamed one; the trigger would then fail on the first insert.)
  select count(*) into n_cols
    from pg_attribute ta
   where ta.attrelid = 'transparent_motivations.contribution_typed'::regclass
     and ta.attnum > 0 and not ta.attisdropped
     and not exists (select 1 from pg_attribute ca
                      where ca.attrelid = 'transparent_motivations.contributions'::regclass
                        and ca.attname = ta.attname and ca.atttypid = ta.atttypid and not ca.attisdropped);
  if n_cols <> 0 then
    raise exception 'CA_0380: % field(s) of contribution_typed have no same-named, same-typed column on contributions', n_cols;
  end if;

  if not exists (select 1 from pg_trigger
                  where tgrelid = 'transparent_motivations.contributions'::regclass
                    and tgname = 'contributions_fill_typed' and tgenabled = 'O') then
    raise exception 'CA_0380: trigger contributions_fill_typed missing or disabled';
  end if;

  -- The mapping, on a hand-written record per source shape.
  probe := transparent_motivations.contribution_typed_fields(
    '{"contributor_name":"DOE, JANE","contributor_employer":"ACME","contributor_city":"BLOOMINGTON",
      "entity_type":"IND","is_individual":true,"committee_id":"C00123456","report_year":2024,
      "report_type":"Q3","file_number":null,"memo_code":"X"}'::jsonb);
  if probe.src_contributor_name is distinct from 'DOE, JANE' or probe.donor_employer is distinct from 'ACME'
     or probe.src_entity_type is distinct from 'IND' or probe.src_is_individual is distinct from true
     or probe.fec_report_year is distinct from 2024 or probe.fec_file_number is not null
     or probe.fec_file_number_present is distinct from true or probe.fec_memo_code is distinct from 'X' then
    raise exception 'CA_0380: FEC-shaped probe mapped wrong: %', probe;
  end if;

  probe := transparent_motivations.contribution_typed_fields(
    '{"con_name":"SMITH JOHN","con_empr":"CITY","schedule":"I","con_desc":"Matching funds"}'::jsonb);
  if probe.src_con_name is distinct from 'SMITH JOHN' or probe.donor_employer is distinct from 'CITY'
     or probe.src_schedule is distinct from 'I' or probe.fec_file_number_present is distinct from false then
    raise exception 'CA_0380: Socrata-shaped probe mapped wrong: %', probe;
  end if;

  probe := transparent_motivations.contribution_typed_fields(
    '{"CTRIB_NAML":"LEE","CTRIB_NAMF":"ANN","ENTITY_CD":"IND","report_year":"n/a"}'::jsonb);
  if probe.src_ctrib_naml is distinct from 'LEE' or probe.src_entity_cd is distinct from 'IND'
     or probe.fec_report_year is not null or probe.src_contributor_name is not null then
    raise exception 'CA_0380: Cal-Access-shaped probe mapped wrong: %', probe;
  end if;

  -- The trigger, fired for real on one row inside a savepoint that is always rolled back, so no stored
  -- row changes. Proves the trigger runs and writes every column it names.
  begin
    update transparent_motivations.contributions c
       set raw_record = c.raw_record || '{"contributor_name":"CA_0380 PROBE","file_number":42}'::jsonb
     where c.id = (select id from transparent_motivations.contributions
                    where data_source = 'fec' and raw_record is not null limit 1)
    returning c.src_contributor_name, c.fec_file_number into got_name, got_fileno;
    raise exception 'CA_0380 probe rollback';
  exception when raise_exception then
    if sqlerrm <> 'CA_0380 probe rollback' then raise; end if;
  end;
  if got_name is distinct from 'CA_0380 PROBE' or got_fileno is distinct from 42 then
    raise exception 'CA_0380: trigger did not fill the columns on UPDATE (name %, file_number %)', got_name, got_fileno;
  end if;
end
$$;
