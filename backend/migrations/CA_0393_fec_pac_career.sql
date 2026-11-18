-- CA_0393_fec_pac_career.sql
-- One row per person: PAC money kept over the whole federal career, by kind, and a verdict.
-- STATUS: APPLIED to prod 2026-11-18 via apply-migration-file.mjs after a dry run (operator approval: Chris Andrews,
--   "Approve, start building"). Post-verify passed.
--
-- Created 2026-11-18 with Chris Andrews. Steward slot CA_0393. Design: "PAC money over a whole career, from our
-- own database" (approved 2026-11-18).
--
-- Rebuilt by the PAC-career job (src/lib/pacCareerJob.ts) after any run that changed a report, a code or a total,
-- the same way contribution_totals (CA_0379) is. Pages and outreach lists read this table, never the gifts.
--
-- DEFINITIONS (rulings 2026-11-18, Chris Andrews):
--   corporate   company PACs only: FEC organization types C and W.
--   trade       trade-association PACs (T). Shown separately; not corporate.
--   coop        cooperative PACs (V). Shown separately; not corporate.
--   other_pac   every other non-party committee that is not a candidate's campaign (labor, membership,
--               ideological, leadership PACs, super PACs).
--   candidate   another candidate's own campaign committee. Shown apart; not PAC money.
--   party       party committees. Not PAC money.
--   kept        received minus refunded, over the career.
-- A gift's kind is read for its own cycle, overruled only when the cycles on both sides agree with each other.
--
-- verdict (in this order, as PR #1532's verdictOf):
--   no_receipts        FEC's totals show no money raised in any cycle (filed as a candidate, never raised).
--   takes_corporate    corporate PAC money kept, on the campaign's own filings. Positive evidence, so it stands
--                      even when another cycle does not reconcile.
--   unverified         a cycle does not reconcile with FEC's totals, a gift's giver has no kind, a cycle or id
--                      has no FEC totals, or one of the person's FEC ids still needs review (why_unverified says
--                      which). Never published as a "no PAC" claim.
--   no_corporate_pac   nothing kept from corporate PACs; some trade, coop or other PAC money kept.
--   no_pac             nothing kept from corporate, trade, coop or other PACs.
--
-- Creates only; overwrites no value. RLS on, no policies: only ev_api (BYPASSRLS) reads and writes.
--
-- ROLLBACK: drop table if exists transparent_motivations.fec_pac_career;

create table if not exists transparent_motivations.fec_pac_career (
  politician_id         uuid          primary key references essentials.politicians(id) on delete cascade,
  verdict               text          not null
                          check (verdict in ('no_receipts', 'takes_corporate', 'unverified', 'no_corporate_pac', 'no_pac')),
  why_unverified        text[]        not null default '{}',
  kept_corporate        numeric(14,2) not null default 0,
  kept_trade            numeric(14,2) not null default 0,
  kept_coop             numeric(14,2) not null default 0,
  kept_other_pac        numeric(14,2) not null default 0,
  kept_candidate        numeric(14,2) not null default 0,
  kept_party            numeric(14,2) not null default 0,
  kept_unknown          numeric(14,2) not null default 0,
  last_corporate_cycle  smallint,     -- last cycle holding a corporate gift that was not later refunded
  career_receipts       numeric(16,2),
  first_cycle           smallint,
  last_cycle            smallint,
  through               date,         -- latest coverage_end_date among FEC's totals
  cycles_checked        integer       not null default 0,
  cycles_unreconciled   smallint[]    not null default '{}',
  fec_candidate_ids     text[]        not null default '{}',
  computed_at           timestamptz   not null default now()
);

comment on table transparent_motivations.fec_pac_career is
  'Per person: PAC money kept over the whole federal career by kind, and a verdict (no_pac, no_corporate_pac, '
  'takes_corporate, unverified, no_receipts). Rebuilt by the PAC-career job. Only verified rows may be published. CA_0393.';

alter table transparent_motivations.fec_pac_career enable row level security;
revoke all on transparent_motivations.fec_pac_career from public, anon, authenticated;
grant select, insert, update, delete on transparent_motivations.fec_pac_career to ev_api;

do $$
begin
  if to_regclass('transparent_motivations.fec_pac_career') is null then
    raise exception 'CA_0393: fec_pac_career was not created';
  end if;
  if not has_table_privilege('ev_api', 'transparent_motivations.fec_pac_career', 'insert') then
    raise exception 'CA_0393: ev_api cannot write fec_pac_career';
  end if;
  if has_table_privilege('anon', 'transparent_motivations.fec_pac_career', 'select') then
    raise exception 'CA_0393: anon can read fec_pac_career';
  end if;
  if not (select relrowsecurity from pg_class where oid = 'transparent_motivations.fec_pac_career'::regclass) then
    raise exception 'CA_0393: RLS is off';
  end if;
end
$$;
