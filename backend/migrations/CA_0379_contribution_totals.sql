-- CA_0379_contribution_totals.sql
-- A one-row table of whole-table campaign-finance totals, refreshed once a day at the end of
-- ev-jobs-fec-burst, so readers stop aggregating the 33 GB contributions table themselves.
--
-- Created 2026-11-13 with Chris Andrews. Steward slot CA_0379. ev-cto decision 0038 (Part A2).
--
-- WHY. ev-landing/briefing/refresh.mjs ran count(*), count(DISTINCT politician_source_id), sum(amount)
-- and a count(DISTINCT election_cycle) over all of transparent_motivations.contributions on every run.
-- Measured in pg_stat_statements 2026-11-13: 9 runs since the 2026-11-12 stats reset, 19.2 GB read from
-- disk and 3.5 GB of temp (the DISTINCT sorts) PER RUN, ~4.6 minutes each. That was the second-largest
-- Disk IO consumer on E.V Backend, which is on the Small compute size and had depleted its daily Disk IO
-- budget twice (Supabase emails 2026-10-20 and 2026-11-13).
--
-- WHAT THIS ADDS.
--   transparent_motivations.contribution_totals            one row (id = true), the six briefing figures
--   transparent_motivations.refresh_contribution_totals()  recomputes that row; returns it
-- The refresh reads the table ONCE: a single sequential scan grouped by (election_cycle,
-- politician_source_id) — ~5,800 groups, held in memory — and derives every figure from those groups.
-- No DISTINCT sort, so no temp spill. Cost: one heap read of contributions (~19 GB today, about half
-- after decision 0038 Part D moves raw_record out), once a day, instead of once per briefing run.
--
-- The figures match the briefing's old query exactly: count(*), count(DISTINCT politician_source_id),
-- round(sum(amount)), and distinct/min/max of election_cycle among values matching ^(19|20)[0-9]{2}$.
--
-- CALLER: src/jobs/registry.ts 'fec-burst' (the last step of ev-jobs-fec-burst). The caller must raise
-- statement_timeout first; the server default (30 s) is far too short for a full scan.
--
-- Creates only; overwrites no value. RLS on, no policies: only ev_api and postgres read it.
--
-- STATUS: APPLIED to prod 2026-11-13 via apply-migration-file.mjs (operator approval: Chris Andrews, "Yes, apply it").
--   Dry run OK before (plus a tamper control: dropping the anon revoke fails the gate). Verified after: table and
--   function exist, RLS on, ev_api can read and run, anon cannot. The table is EMPTY until the first refresh, which
--   runs with the first fec-burst after this PR deploys.
--
-- ROLLBACK:
--   drop function if exists transparent_motivations.refresh_contribution_totals();
--   drop table if exists transparent_motivations.contribution_totals;

create table if not exists transparent_motivations.contribution_totals (
  id            boolean primary key default true check (id),
  contributions bigint      not null,
  dollars       numeric     not null,
  politicians   integer     not null,
  cycles        integer     not null,
  min_cycle     text,
  max_cycle     text,
  refreshed_at  timestamptz not null default now(),
  refresh_ms    integer
);

comment on table transparent_motivations.contribution_totals is
  'One row of whole-table totals over transparent_motivations.contributions, refreshed daily by '
  'refresh_contribution_totals() at the end of ev-jobs-fec-burst. Read this instead of aggregating '
  'contributions in production (ev-cto decision 0038). CA_0379.';

alter table transparent_motivations.contribution_totals enable row level security;
revoke all on transparent_motivations.contribution_totals from public, anon, authenticated;
grant select on transparent_motivations.contribution_totals to ev_api;

create or replace function transparent_motivations.refresh_contribution_totals()
returns transparent_motivations.contribution_totals
language plpgsql
volatile
security definer
set search_path to 'transparent_motivations', 'pg_catalog'
as $$
declare
  t0  timestamptz := clock_timestamp();
  out transparent_motivations.contribution_totals;
begin
  with g as (
    -- ONE sequential scan. ~5,800 (cycle, politician) groups fit in memory, so no sort and no temp.
    select c.election_cycle, c.politician_source_id, count(*) as n, sum(c.amount) as amt
      from transparent_motivations.contributions c
     group by c.election_cycle, c.politician_source_id
  ), cyc as (
    select g.election_cycle
      from g
     where g.election_cycle ~ '^(19|20)[0-9]{2}$'
     group by g.election_cycle
  )
  select true,
         coalesce((select sum(g.n) from g), 0)::bigint,
         coalesce(round((select sum(g.amt) from g)), 0),
         (select count(distinct g.politician_source_id) from g)::int,
         (select count(*) from cyc)::int,
         (select min(cyc.election_cycle) from cyc),
         (select max(cyc.election_cycle) from cyc),
         now(),
         null
    into out;

  out.refresh_ms := (extract(epoch from clock_timestamp() - t0) * 1000)::int;

  insert into transparent_motivations.contribution_totals as t
         (id, contributions, dollars, politicians, cycles, min_cycle, max_cycle, refreshed_at, refresh_ms)
  values (true, out.contributions, out.dollars, out.politicians, out.cycles, out.min_cycle, out.max_cycle,
          out.refreshed_at, out.refresh_ms)
  on conflict (id) do update set
         contributions = excluded.contributions, dollars = excluded.dollars,
         politicians = excluded.politicians, cycles = excluded.cycles,
         min_cycle = excluded.min_cycle, max_cycle = excluded.max_cycle,
         refreshed_at = excluded.refreshed_at, refresh_ms = excluded.refresh_ms;

  return out;
end
$$;

revoke all on function transparent_motivations.refresh_contribution_totals() from public, anon, authenticated;
grant execute on function transparent_motivations.refresh_contribution_totals() to ev_api;

-- Post-verify: both objects exist, ev_api can use them, anon cannot.
do $$
begin
  if to_regclass('transparent_motivations.contribution_totals') is null then
    raise exception 'CA_0379: contribution_totals was not created';
  end if;
  if to_regprocedure('transparent_motivations.refresh_contribution_totals()') is null then
    raise exception 'CA_0379: refresh_contribution_totals() was not created';
  end if;
  if not has_table_privilege('ev_api', 'transparent_motivations.contribution_totals', 'select') then
    raise exception 'CA_0379: ev_api cannot read contribution_totals';
  end if;
  if not has_function_privilege('ev_api', 'transparent_motivations.refresh_contribution_totals()', 'execute') then
    raise exception 'CA_0379: ev_api cannot run refresh_contribution_totals()';
  end if;
  if has_function_privilege('anon', 'transparent_motivations.refresh_contribution_totals()', 'execute') then
    raise exception 'CA_0379: anon can run refresh_contribution_totals() — the revoke did not take';
  end if;
  if not (select relrowsecurity from pg_class where oid = 'transparent_motivations.contribution_totals'::regclass) then
    raise exception 'CA_0379: RLS is off on contribution_totals';
  end if;
end
$$;
