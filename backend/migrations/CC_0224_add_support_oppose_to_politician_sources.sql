-- CC_0224 — ADR 0008: give a source a DIRECTION, so outside spending can say what it is.
--
-- Decision: `docs/adr/0008-outside-spending-support-or-oppose.md`.
-- Audits that hit this wall three times in one day: `CC_0221`, `CC_0222`, `CC_0223`.
--
-- 🔴 **DDL. THIS MIGRATION CANNOT BE APPLIED WITH `DATABASE_URL`.** Prod authenticates as `ev_api`,
-- which is not the table owner — `ALTER TABLE` returns `must be owner of table politician_sources`.
-- **Apply it through the Supabase MCP, which connects as `postgres`.** Probed 2026-10-10: `ev_api`
-- refused, `postgres` succeeded inside a `BEGIN … ROLLBACK`.
--
--
-- ══ WHAT THIS IS FOR ═════════════════════════════════════════════════════════════════════════
--
-- `OutsideSpendingCommittee` reports money spent **about** a politician by a committee they do not
-- control. It has no field for which **direction** that money ran. A committee formed to elect
-- somebody and a committee formed to recall them are the same object in that shape — and so are
-- their donor lists, where one is people who funded them and the other is people who funded a
-- campaign against them.
--
-- 🔴 **Three sources publish as outside spending today and all three are support committees — but
-- none is EVIDENCED as support.** They read as support because their names happen to contain
-- "for", "working families for" and "supporting". The corpus is accidentally safe, not safely
-- designed. **The first oppose committee anyone types `ie_committee` publishes silently as money
-- the politician raised.**
--
-- Five committees are withheld on this, two carrying **$227,172.80 on LIVE incumbents**:
-- Gipson's `1448127` ($194,000, support) and the Newsom recall `1418587` ($33,172.80, **oppose**).
--
--
-- ══ THE SHAPE, AND WHY IT IS NULLABLE ════════════════════════════════════════════════════════
--
-- `support_oppose` is **nullable with no default, and the read path REQUIRES it** (`CC_0224`'s
-- companion change to `getOutsideSpendingForPolitician`). Unknown is **withheld**, exactly as a
-- `disputed` source is withheld, and exactly as a blank compass spoke is correct.
--
-- 🔴 **There is deliberately no default, because the only unsafe direction is the one a default
-- would pick.** Defaulting to `'support'` would publish opposition spending as a politician's own
-- backing. A default of `'oppose'` would do the reverse. Neither is a guess this corpus may make.
--
-- ⚠ **The grain is the SOURCE ROW, not the committee.** One committee can support one candidate
-- and oppose another; `politician_sources` is already per (politician, source_system, external_id),
-- and FPPC Form 460 Part 7 records direction the same way — per candidate, with its own
-- SUPPORT/OPPOSE checkboxes.
--
-- ⚠ **It applies to every `source_type`, not just `ie_committee`.** A candidate's own committee has
-- no meaningful direction and will stay NULL; constraining the column to IE rows would need a
-- cross-column CHECK that buys nothing and would have to be relaxed the first time a ballot-measure
-- committee needs one (ADR 0008 §7 leaves measures open).
--
-- ⚠ **This migration sets NO VALUES.** Evidencing the directions is a separate, sourced step
-- against Form 460 Part 7 — `CC_0225`. Between the two, the three currently-published committees
-- go dark. ADR 0008 §5 accepts that explicitly.

BEGIN;

ALTER TABLE transparent_motivations.politician_sources
  ADD COLUMN IF NOT EXISTS support_oppose text;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
     WHERE conname = 'politician_sources_support_oppose_check'
       AND conrelid = 'transparent_motivations.politician_sources'::regclass
  ) THEN
    ALTER TABLE transparent_motivations.politician_sources
      ADD CONSTRAINT politician_sources_support_oppose_check
      CHECK (support_oppose IS NULL OR support_oppose IN ('support','oppose'));
  END IF;
END $$;

COMMENT ON COLUMN transparent_motivations.politician_sources.support_oppose IS
  'ADR 0008. Direction of an outside-spending committee RELATIVE TO THIS POLITICIAN: '
  'support | oppose | NULL. NULL means UNKNOWN, not neutral, and '
  'getOutsideSpendingForPolitician WITHHOLDS it — there is no safe default, because defaulting '
  'would publish money raised against a politician as money they raised. Evidence it from FPPC '
  'Form 460 cover page Part 7, which carries SUPPORT/OPPOSE checkboxes per candidate under '
  'penalty of perjury. Per source row, not per committee: one committee can support one '
  'candidate and oppose another.';

DO $$
DECLARE
  v_cnt int;
BEGIN
  -- 1. The column exists and is nullable with no default. A default would be the bug.
  SELECT count(*) INTO v_cnt FROM information_schema.columns
   WHERE table_schema='transparent_motivations' AND table_name='politician_sources'
     AND column_name='support_oppose' AND is_nullable='YES' AND column_default IS NULL;
  IF v_cnt <> 1 THEN
    RAISE EXCEPTION 'CC_0224: support_oppose is missing, NOT NULL, or has a default — all three are wrong';
  END IF;

  -- 2. The CHECK exists.
  SELECT count(*) INTO v_cnt FROM pg_constraint
   WHERE conname = 'politician_sources_support_oppose_check'
     AND conrelid = 'transparent_motivations.politician_sources'::regclass;
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'CC_0224: the support_oppose CHECK was not created'; END IF;

  -- 3. 🔴 The CHECK actually refuses a bad value. A constraint that cannot be seen to reject is
  --    not known to work — plant the control and watch it fail.
  BEGIN
    UPDATE transparent_motivations.politician_sources
       SET support_oppose = 'neutral'
     WHERE id = (SELECT id FROM transparent_motivations.politician_sources LIMIT 1);
    RAISE EXCEPTION 'CC_0224: the CHECK ACCEPTED ''neutral'' — the constraint is not working';
  EXCEPTION WHEN check_violation THEN
    NULL;  -- expected: this is the control passing
  END;

  -- 4. Nothing was given a value. This migration is DDL only.
  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources
   WHERE support_oppose IS NOT NULL;
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0224: % rows already carry a direction, expected 0', v_cnt; END IF;

  RAISE NOTICE 'CC_0224: support_oppose added, CHECK verified by a rejected control, 0 rows valued';
END $$;

COMMIT;
