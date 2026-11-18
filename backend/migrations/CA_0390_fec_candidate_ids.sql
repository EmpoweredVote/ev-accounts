-- CA_0390_fec_candidate_ids.sql
-- Every FEC candidate id a person has run under, and which campaign committees served each id in each cycle.
-- STATUS: APPLIED to prod 2026-11-18 via apply-migration-file.mjs after a dry run (operator approval: Chris Andrews,
--   "Approve, start building"). Post-verify passed.
--
-- Created 2026-11-18 with Chris Andrews. Steward slot CA_0390. Design: "PAC money over a whole career, from our
-- own database" (approved by Chris Andrews 2026-11-18). Reference: PR #1532 (scripts/pac-career/pac-career.ts).
--
-- WHY A SEPARATE TABLE. politician_sources links ONE FEC id per person for most people; a career view needs
-- every id (a House run, then a Senate run). PR #1532 found extra ids for 203 people by name and state in FEC's
-- candidate master files. Those cannot go into politician_sources as confirmed rows: every confirmed FEC row
-- there joins the nightly fec-burst, which would spend API calls and load individual donors into the 34 GB
-- contributions table for campaigns that ended years ago. This table is read by the PAC-career job only.
--
-- WHAT THIS ADDS.
--   transparent_motivations.fec_candidate_ids         (politician, FEC id) with how it was found and its status
--   transparent_motivations.fec_candidate_committees  (FEC id, cycle) -> campaign committee, from FEC's ccl files
-- Seeds fec_candidate_ids with every confirmed FEC link in politician_sources (found_by = 'linked'). The job
-- keeps those in step and adds 'name_state_match' rows as 'needs_review'. No verdict counts a person who has a
-- needs_review id.
--
-- Creates and inserts only; overwrites no value. RLS on, no policies: only ev_api (BYPASSRLS) reads and writes.
--
-- ROLLBACK:
--   drop table if exists transparent_motivations.fec_candidate_committees;
--   drop table if exists transparent_motivations.fec_candidate_ids;

create table if not exists transparent_motivations.fec_candidate_ids (
  politician_id    uuid        not null references essentials.politicians(id) on delete cascade,
  fec_candidate_id text        not null check (fec_candidate_id ~ '^[HSP][0-9A-Z]{8}$'),
  found_by         text        not null check (found_by in ('linked', 'name_state_match')),
  status           text        not null check (status in ('confirmed', 'needs_review', 'rejected')),
  evidence         text,
  reviewed_at      timestamptz,
  reviewed_by      text,
  totals_fetched_at timestamptz,  -- last time FEC's per-cycle totals were read for this id; NULL = never,
                                  -- which keeps the person unverified (no rows can mean "never fetched")
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  primary key (politician_id, fec_candidate_id)
);
create index if not exists fec_candidate_ids_by_id on transparent_motivations.fec_candidate_ids (fec_candidate_id);

comment on table transparent_motivations.fec_candidate_ids is
  'Every FEC candidate id per person, for the PAC-career verdicts. linked = mirrors a confirmed politician_sources '
  'row; name_state_match = found in FEC candidate master files by name and state, needs review before it counts. '
  'Not read by the contributions ingest. CA_0390.';

create table if not exists transparent_motivations.fec_candidate_committees (
  fec_candidate_id text     not null,
  cycle            smallint not null check (cycle between 1976 and 2100 and cycle % 2 = 0),
  committee_id     text     not null check (committee_id ~ '^C[0-9]{8}$'),
  designation      text     not null check (designation in ('P', 'A')),
  loaded_at        timestamptz not null default now(),
  primary key (fec_candidate_id, cycle, committee_id)
);
create index if not exists fec_candidate_committees_by_committee
  on transparent_motivations.fec_candidate_committees (committee_id, cycle);

comment on table transparent_motivations.fec_candidate_committees is
  'Campaign committees (designation P principal, A authorized) that served an FEC candidate id in a cycle, from '
  'FEC''s ccl{YY} bulk files. Loaded only for ids in fec_candidate_ids. CA_0390.';

alter table transparent_motivations.fec_candidate_ids enable row level security;
alter table transparent_motivations.fec_candidate_committees enable row level security;
revoke all on transparent_motivations.fec_candidate_ids, transparent_motivations.fec_candidate_committees
  from public, anon, authenticated;
grant select, insert, update, delete on transparent_motivations.fec_candidate_ids,
  transparent_motivations.fec_candidate_committees to ev_api;

insert into transparent_motivations.fec_candidate_ids (politician_id, fec_candidate_id, found_by, status, evidence)
select distinct ps.essentials_politician_id, upper(trim(ps.external_id)), 'linked', 'confirmed',
       'politician_sources ' || ps.source_system
  from transparent_motivations.politician_sources ps
 where ps.source_system like 'fec%'
   and ps.research_status = 'confirmed'
   and upper(trim(ps.external_id)) ~ '^[HSP][0-9A-Z]{8}$'
on conflict (politician_id, fec_candidate_id) do nothing;

-- Post-verify: every confirmed, well-formed FEC link is seeded, nothing else is, and only ev_api can reach it.
do $$
declare
  want int;
  got  int;
  odd  int;
begin
  select count(distinct (ps.essentials_politician_id, upper(trim(ps.external_id)))) into want
    from transparent_motivations.politician_sources ps
   where ps.source_system like 'fec%' and ps.research_status = 'confirmed'
     and upper(trim(ps.external_id)) ~ '^[HSP][0-9A-Z]{8}$';
  select count(*) into got from transparent_motivations.fec_candidate_ids where found_by = 'linked';
  if got <> want then
    raise exception 'CA_0390: seeded % linked ids, expected %', got, want;
  end if;
  if want < 1600 then
    raise exception 'CA_0390: only % confirmed FEC links found (1,661 on 2026-11-18) — wrong database?', want;
  end if;
  -- A confirmed link whose id is malformed is skipped above; say how many, so none is lost silently.
  select count(*) into odd from transparent_motivations.politician_sources ps
   where ps.source_system like 'fec%' and ps.research_status = 'confirmed' and trim(ps.external_id) <> ''
     and upper(trim(ps.external_id)) !~ '^[HSP][0-9A-Z]{8}$';
  raise notice 'CA_0390: seeded % linked ids; % confirmed link(s) skipped as malformed', got, odd;
  if not has_table_privilege('ev_api', 'transparent_motivations.fec_candidate_ids', 'insert') then
    raise exception 'CA_0390: ev_api cannot write fec_candidate_ids';
  end if;
  if not has_table_privilege('ev_api', 'transparent_motivations.fec_candidate_committees', 'insert') then
    raise exception 'CA_0390: ev_api cannot write fec_candidate_committees';
  end if;
  if has_table_privilege('anon', 'transparent_motivations.fec_candidate_ids', 'select') then
    raise exception 'CA_0390: anon can read fec_candidate_ids';
  end if;
  if not (select relrowsecurity from pg_class where oid = 'transparent_motivations.fec_candidate_ids'::regclass)
     or not (select relrowsecurity from pg_class where oid = 'transparent_motivations.fec_candidate_committees'::regclass) then
    raise exception 'CA_0390: RLS is off';
  end if;
end
$$;
