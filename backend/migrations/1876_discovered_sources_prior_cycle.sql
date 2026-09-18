-- Slice 2B flag-vs-guard: flag a tracked candidate's OWN prior-cycle answers.
-- Spec: on-the-record/docs/superpowers/specs/2026-09-17-slice2-comparable-source-hubs-design.md
--       ("Decided 2026-09-18" — flag, not guard).
-- Steward slot 1876.
--
-- The discovery engine sets prior_cycle=true + source_cycle_year for a tracked candidate's
-- own answers to the same standardized questions from an EARLIER cycle (e.g. a Ballotpedia
-- Candidate Connection survey completed in a prior year). These stay comparable, so they are
-- FLAGGED for review (kept pending), not rejected. The review UI shows the flag + cycle year
-- and ranks prior-cycle rows below current-cycle ones; curators must attribute a prior-cycle
-- quote to its cycle, never present it as a current statement.
--
-- 🔴 Ordering: apply this migration BEFORE deploying the on-the-record engine change that
-- writes these columns, or the insert fails on a missing column (cf. the original_vs_clip
-- lesson). Idempotent (add column if not exists), so re-running is safe.

alter table essentials.discovered_sources
  add column if not exists prior_cycle boolean not null default false,
  add column if not exists source_cycle_year text;

comment on column essentials.discovered_sources.prior_cycle is
  'Slice 2B: true = a tracked candidate''s own answers from an EARLIER cycle (flagged for review, not rejected).';
comment on column essentials.discovered_sources.source_cycle_year is
  'Slice 2B: the cycle year of the content when known (e.g. ''2020''); pairs with prior_cycle.';

-- Post-verify gate.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_schema = 'essentials' AND table_name = 'discovered_sources'
                   AND column_name = 'prior_cycle') THEN
    RAISE EXCEPTION 'discovered_sources.prior_cycle missing after migration';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_schema = 'essentials' AND table_name = 'discovered_sources'
                   AND column_name = 'source_cycle_year') THEN
    RAISE EXCEPTION 'discovered_sources.source_cycle_year missing after migration';
  END IF;
END $$;
