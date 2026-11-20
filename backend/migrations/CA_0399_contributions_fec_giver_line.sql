-- CA_0399_contributions_fec_giver_line.sql
-- Keep the giving committee's FEC id and the form line on every FEC contribution row.
--
-- Created 2026-11-19 with Chris Andrews. Steward slot CA_0399. Approved 2026-11-19 ("Yes, build 1–4"): close the
-- gaps between the fec-burst pull and the PAC-career tables (CA_0390–CA_0394).
--
-- WHY. Since the Part D swap (CA_0398, 2026-11-19) FEC rows keep no raw_record: contributions_strip_fec_raw nulls it
-- after contributions_fill_typed has copied the keys into typed columns. A key the mapping does not copy is lost.
-- The burst never kept FEC's contributor_id (the giving committee) or line_number, so a PAC gift could not be tied
-- to its committee, or to a kind (corporate, trade group, union) through fec_committee_kinds (CA_0391).
-- src_contributor_committee_id already exists (CA_0380) but reads only 'contributor_committee_id', a key that only
-- pre-slim rows ever carried: in a 0.05% sample of FEC rows on 2026-11-19 it was filled on none of ~15,000.
--
-- WHAT THIS CHANGES.
--   contribution_typed                  + attribute fec_line_number text
--   contributions                       + column fec_line_number text (nullable, no default: catalog change only)
--   contribution_typed_fields(jsonb)    src_contributor_committee_id := coalesce(contributor_committee_id,
--                                       contributor_id); fec_line_number := line_number ('11A', '11C', '20A', ...)
--   contributions_fill_typed()          also assigns fec_line_number
-- Existing rows are not touched here. The burst's ON CONFLICT now refreshes raw_record on a re-fetched FEC row, so
-- the trigger fills both columns on every row it fetches again; scripts/fec-burst-gaps-backfill.ts re-fetches the
-- committee lines (11B, 11C) and the refund lines (20A-C) for every FEC source and cycle.
--
-- Overwrites no stored value. Replaces two function bodies; the old ones are in CA_0380 (and live as of
-- 2026-11-19, read with pg_get_functiondef before writing this file): identical except for the two lines marked.
--
-- LOCKS. ADD COLUMN takes a brief ACCESS EXCLUSIVE lock on contributions; lock_timeout 3s fails fast.
--
-- ROLLBACK (no data lives only in fec_line_number; src_contributor_committee_id keeps what it holds):
--   re-run the CA_0380 definitions of contribution_typed_fields and contributions_fill_typed (drop the function
--   first, then alter type ... drop attribute fec_line_number), then
--   alter table transparent_motivations.contributions drop column if exists fec_line_number;
--
-- STATUS: APPLIED to prod 2026-11-20 00:13 UTC via apply-migration-file.mjs (operator approval: Chris Andrews, "Yes, apply
--   it"); post-verify probe passed. Before that: dry run OK; two tampers each stopped by their own gate (mapping without
--   contributor_id -> mapping check; trigger without the fec_line_number assignment -> 'insert-line update-line').
--   First backfill (Chris Murphy S2CT00132, 2024 + 2026): 647 rows inserted (28 PAC/party gifts on 11C, 619 refunds),
--   all 28 committee gifts that FEC gave an id carry it; no FEC row kept its JSON.

set local lock_timeout = '3s';

alter type transparent_motivations.contribution_typed add attribute fec_line_number text;

alter table transparent_motivations.contributions add column if not exists fec_line_number text;

comment on column transparent_motivations.contributions.fec_line_number is
  'FEC form line of the row (11A individuals, 11C PACs, 11B parties, 20A/B/C refunds, ...). FEC rows only. CA_0399.';

create or replace function transparent_motivations.contribution_typed_fields(r jsonb)
 returns transparent_motivations.contribution_typed
 language sql
 immutable parallel safe
 set search_path to 'pg_catalog'
as $function$
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
    coalesce(r->>'contributor_committee_id', r->>'contributor_id'),   -- CA_0399: + contributor_id
    r->>'schedule',
    r->>'con_desc',
    r->>'committee_id',
    case when r->>'report_year' ~ '^-?[0-9]{1,9}$' then (r->>'report_year')::integer end,
    r->>'report_type',
    case when r->>'file_number' ~ '^-?[0-9]{1,18}$' then (r->>'file_number')::bigint end,
    case when r is null then null else r ? 'file_number' end,
    r->>'memo_code',
    r->>'transaction_id',
    r->>'amendment_indicator',
    r->>'line_number'                                                 -- CA_0399: new
  )::transparent_motivations.contribution_typed
$function$;

create or replace function transparent_motivations.contributions_fill_typed()
 returns trigger
 language plpgsql
 set search_path to 'transparent_motivations', 'pg_catalog'
as $function$
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
  new.fec_line_number              := t.fec_line_number;              -- CA_0399: new
  return new;
end
$function$;

-- Post-verify. A live probe, undone by its own exception: an FEC insert carrying contributor_id and line_number must
-- come back with both columns filled and raw_record stripped; an FEC update that re-sends the JSON (what the burst's
-- ON CONFLICT now does) must fill them on a row that had none; a state-source row keeps its JSON.
do $$
declare
  ps_id uuid;
  probe_id uuid;
  probe_ids uuid[] := '{}';
  r record;
  fails text := '';
begin
  if (select count(*) from pg_attribute where attrelid = 'transparent_motivations.contributions'::regclass
        and attname = 'fec_line_number' and not attisdropped) <> 1 then
    raise exception 'CA_0399: column fec_line_number missing';
  end if;
  if (transparent_motivations.contribution_typed_fields('{"contributor_id":"C00000001","line_number":"11C"}'::jsonb)).src_contributor_committee_id
       is distinct from 'C00000001'
     or (transparent_motivations.contribution_typed_fields('{"contributor_committee_id":"C00000002","contributor_id":"C00000001"}'::jsonb)).src_contributor_committee_id
       is distinct from 'C00000002'
     or (transparent_motivations.contribution_typed_fields('{"line_number":"20A"}'::jsonb)).fec_line_number
       is distinct from '20A' then
    raise exception 'CA_0399: mapping function did not pick up contributor_id / line_number';
  end if;

  select id into ps_id from transparent_motivations.politician_sources limit 1;

  begin
    insert into transparent_motivations.contributions
      (politician_source_id, amount, contribution_date, election_cycle, confidence_level, data_source,
       source_transaction_id, raw_record, donor_name_normalized)
    values (ps_id, 1000, date '2024-01-01', '2024', 'HIGH', 'fec', 'ca399-probe-' || gen_random_uuid(),
            '{"contributor_name":"PROBE PAC","entity_type":"PAC","contributor_id":"C00000001","line_number":"11C",
              "committee_id":"C00000009","file_number":1,"report_year":2024,"report_type":"Q1"}'::jsonb, 'probe pac')
    returning id into probe_id;
    probe_ids := probe_ids || probe_id;
    select * into r from transparent_motivations.contributions where id = probe_id;
    if r.raw_record is not null then fails := fails || ' insert-json-kept'; end if;
    if r.src_contributor_committee_id is distinct from 'C00000001' then fails := fails || ' insert-giver'; end if;
    if r.fec_line_number is distinct from '11C' then fails := fails || ' insert-line'; end if;

    -- a stored row with neither column, then a re-fetch that re-sends the JSON
    update transparent_motivations.contributions
       set src_contributor_committee_id = null, fec_line_number = null where id = probe_id;
    update transparent_motivations.contributions
       set raw_record = '{"contributor_name":"PROBE PAC","contributor_id":"C00000003","line_number":"11C"}'::jsonb
     where id = probe_id;
    select * into r from transparent_motivations.contributions where id = probe_id;
    if r.raw_record is not null then fails := fails || ' update-json-kept'; end if;
    if r.src_contributor_committee_id is distinct from 'C00000003' then fails := fails || ' update-giver'; end if;
    if r.fec_line_number is distinct from '11C' then fails := fails || ' update-line'; end if;

    insert into transparent_motivations.contributions
      (politician_source_id, amount, contribution_date, election_cycle, confidence_level, data_source,
       source_transaction_id, raw_record, donor_name_normalized)
    values (ps_id, 10, date '2024-01-01', '2024', 'HIGH', 'cal_access', 'ca399-probe-' || gen_random_uuid(),
            '{"CTRIB_NAML":"PROBE"}'::jsonb, 'probe')
    returning id into probe_id;
    probe_ids := probe_ids || probe_id;
    select * into r from transparent_motivations.contributions where id = probe_id;
    if r.raw_record is null then fails := fails || ' state-json-stripped'; end if;
    if r.fec_line_number is not null then fails := fails || ' state-line'; end if;

    raise exception using errcode = 'P0399', message = fails;
  exception when sqlstate 'P0399' then
    fails := sqlerrm;
  end;

  if fails <> '' then
    raise exception 'CA_0399: probe failed:%', fails;
  end if;
  -- by primary key: a LIKE on source_transaction_id would read the whole table. Variables survive the undone block.
  if cardinality(probe_ids) <> 2 then
    raise exception 'CA_0399: expected 2 probe rows, got %', cardinality(probe_ids);
  end if;
  if exists (select 1 from transparent_motivations.contributions where id = any(probe_ids)) then
    raise exception 'CA_0399: probe rows were not undone';
  end if;
end
$$;
