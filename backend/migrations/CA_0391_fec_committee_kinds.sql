-- CA_0391_fec_committee_kinds.sql
-- FEC's codes for a committee, cycle by cycle, so a PAC gift's kind is read for the cycle it was given in.
-- STATUS: APPLIED to prod 2026-11-18 via apply-migration-file.mjs after a dry run (operator approval: Chris Andrews,
--   "Approve, start building"). Post-verify passed.
--
-- Created 2026-11-18 with Chris Andrews. Steward slot CA_0391. Design: "PAC money over a whole career, from our
-- own database" (approved 2026-11-18).
--
-- WHY PER CYCLE. FEC's codes sometimes flip for one cycle: the NEA Fund is labor in 2022 and 2026 but
-- corporation in 2024. Ruling 2026-11-18 (Chris Andrews): a gift's kind is read for its own cycle, overruled only
-- when the cycles on both sides agree with each other (committeeKindAt in src/lib/pacCareer.ts). That needs the
-- neighbouring cycles, so a committee's codes are kept for EVERY cycle FEC lists it in.
--
-- WHAT THIS ADDS. transparent_motivations.fec_committee_kinds, loaded from FEC's cm{YY} bulk files by the
-- PAC-career job, only for committees that appear as a giver or recipient in fec_pac_gifts (~150k rows, ~15 MB).
--
-- Creates only; overwrites no value. RLS on, no policies: only ev_api (BYPASSRLS) reads and writes.
--
-- ROLLBACK: drop table if exists transparent_motivations.fec_committee_kinds;

create table if not exists transparent_motivations.fec_committee_kinds (
  committee_id text     not null check (committee_id ~ '^C[0-9]{8}$'),
  cycle        smallint not null check (cycle between 1976 and 2100 and cycle % 2 = 0),
  name         text,
  cmte_tp      text,  -- CMTE_TP: H/S/P campaign, X/Y party, Q/N PAC, O super PAC, ...
  cmte_dsgn    text,  -- CMTE_DSGN: P principal, A authorized, D leadership PAC, J joint fundraiser, ...
  org_tp       text,  -- ORG_TP: C corporation, W corporation without capital stock, L labor, M membership,
                      --        T trade association, V cooperative
  loaded_at    timestamptz not null default now(),
  primary key (committee_id, cycle)
);

comment on table transparent_motivations.fec_committee_kinds is
  'FEC committee master codes (cm{YY}) per committee per cycle, for committees in fec_pac_gifts. Read a gift''s '
  'kind for its own cycle (committeeKindAt). CA_0391.';

alter table transparent_motivations.fec_committee_kinds enable row level security;
revoke all on transparent_motivations.fec_committee_kinds from public, anon, authenticated;
grant select, insert, update, delete on transparent_motivations.fec_committee_kinds to ev_api;

do $$
begin
  if to_regclass('transparent_motivations.fec_committee_kinds') is null then
    raise exception 'CA_0391: fec_committee_kinds was not created';
  end if;
  if not has_table_privilege('ev_api', 'transparent_motivations.fec_committee_kinds', 'insert') then
    raise exception 'CA_0391: ev_api cannot write fec_committee_kinds';
  end if;
  if has_table_privilege('anon', 'transparent_motivations.fec_committee_kinds', 'select') then
    raise exception 'CA_0391: anon can read fec_committee_kinds';
  end if;
  if not (select relrowsecurity from pg_class where oid = 'transparent_motivations.fec_committee_kinds'::regclass) then
    raise exception 'CA_0391: RLS is off';
  end if;
end
$$;
