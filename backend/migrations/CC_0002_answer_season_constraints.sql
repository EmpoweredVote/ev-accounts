BEGIN;

-- ✅ APPLIED TO PRODUCTION 2026-08-26. THE IRREVERSIBLE STEP IS DONE.
-- Verified after applying, read back from the catalog:
--   politician_answers_pkey  = PRIMARY KEY (politician_id, topic_id, season_id)
--   politician_context_pkey  = PRIMARY KEY (politician_id, topic_id, season_id)
--   scaffolding: politician_answers_legacy_pair_scaffold +
--                politician_context_legacy_pair_scaffold   (BOTH UP — see below)
--   3 new FKs: answers pin, context pin, evidence -> context on the triple
--   value CHECK = value IN (1,2,3,4,5); pin-immutability trigger present
--   evidence rows with no season: 0 of 183
--   33,164 answers / 33,818 context / 183 evidence — all unchanged
--
-- Dry run first inside BEGIN…ROLLBACK, and the revert was confirmed before
-- applying: both PKs back to (politician_id, topic_id), no scaffolding, no
-- trigger, the half-step CHECK restored.
--
-- Constraints exercised against the LIVE schema in a rolled-back txn, 6/6:
--   1 season-unaware ON CONFLICT (politician_id, topic_id) -> STILL WORKS
--   2 half step for a politician        -> refused by CHECK
--   3 citing an unpinned revision       -> refused by the pin FK
--   4 moving a closed season's pin      -> refused, PIN_IMMUTABLE
--   5 inserting a season-2 answer       -> refused, the interlock holds
--   6 deleting a context row            -> its evidence cascaded, 0 orphans
-- And the rewritten evidence INSERT: 1 row inserted with season_id set, matching
-- its context row's season; a bogus season was refused by the FK.
--
-- 🔴🔴 THE SCAFFOLDING IS UP, AND THAT MEANS THIS DATABASE STILL CANNOT HOLD
-- TWO SEASONS. That is deliberate. It keeps every season-unaware consumer
-- correct — ON CONFLICT on the bare pair resolves, and no bare-pair join can
-- fan out, because one row per pair is still enforced. Drop it only after the
-- season-aware code is deployed and the five RPCs are migrated, and only then
-- open season 2. Order: deploy code -> migrate RPCs -> drop scaffolding ->
-- open season 2 -> add the closed-season immutability trigger.


-- =============================================================================
-- CC_0002: Key the answer tables by season. THE IRREVERSIBLE STEP.
-- =============================================================================
-- Task 6 of docs/superpowers/plans/2026-08-25-compass-seasons.md, plus three
-- things that plan did not know about. Requires CC_0001 and CA_0017-CA_0019.
--
-- After this, `(politician_id, topic_id)` is no longer unique in principle, and
-- every consumer that joins on the bare pair is wrong. That is why the gate
-- (`npm run check:answer-seasons`) exists and why it had to go green first.
--
-- 🔴 THREE ADDITIONS TO THE PLAN, ALL FOUND BY RUNNING IT.
--
-- 1. THE SCAFFOLDING INDEX. A unique index on the OLD pair, added here and
--    dropped in a later migration. It is what makes the intermediate state safe,
--    and it does two jobs at once:
--      · `ON CONFLICT (politician_id, topic_id)` still resolves, so the five
--        SECURITY DEFINER functions and any not-yet-deployed code keep working
--        instead of raising 42P10.
--      · It enforces one row per pair, so NOTHING CAN FAN OUT while it is up —
--        including `inform.admin_approve_rewrite_framing`, whose bare-pair join
--        would otherwise seed duplicate rewrite proposals silently.
--    It is also an interlock: season 2 CANNOT be opened until it is dropped,
--    which is exactly the order we want. Verified 2026-08-26 — inserting a
--    season-2 row while it is up is refused with a unique violation.
--    ⚠ IT MUST BE DROPPED before season 2 opens. Until then this database
--    physically cannot hold two seasons of answers.
--
-- 2. `inform.politician_context_evidence` IS IN SCOPE. Its composite FK depends
--    on `politician_context_pkey`, so dropping that PK fails with 2BP01 until
--    the FK goes. The table therefore needs a `season_id` of its own, or the
--    citations read has nothing to align evidence to.
--    season_id stays NULLABLE here, deliberately: two live INSERT sites in
--    `researchEvidenceService.ts` do not supply it, and NOT NULL would break
--    them on deploy. They are updated in the same branch to derive it from the
--    context row. Once no NULLs remain, NOT NULL is a one-line follow-up.
--    ⚠ The composite FK is MATCH SIMPLE, so a row with a NULL season_id is not
--    FK-checked and will not cascade when its context row is deleted. That is
--    the price of staying deployable; it is why the follow-up matters.
--
-- 3. The value CHECK swap is safe: 0 of 33,164 rows use a half step and the
--    distinct values are exactly 1.0-5.0 (measured 2026-08-26). Half steps
--    remain legal on `inform.compass_responses`, which is the citizen signal.
--
-- Pre-flight, measured 2026-08-26:
--   0 answers and 0 context rows would fail the new composite pin FK.
--   183 evidence rows, 0 of them without a context row — so the season backfill
--     from context reaches every one.
--   Both value CHECKs exist under the names this migration drops.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. politician_context_evidence gets a season, before any PK moves
-- -----------------------------------------------------------------------------
ALTER TABLE inform.politician_context_evidence
  ADD COLUMN IF NOT EXISTS season_id uuid REFERENCES inform.seasons(id);

UPDATE inform.politician_context_evidence e
   SET season_id = c.season_id
  FROM inform.politician_context c
 WHERE c.politician_id = e.politician_id
   AND c.topic_id      = e.topic_id
   AND e.season_id IS NULL;

COMMENT ON COLUMN inform.politician_context_evidence.season_id IS
  'The season whose context row this evidence supports. Nullable only because '
  'two write paths predate it; a NULL means "not yet attributed" and is NOT '
  'FK-checked, because the composite FK is MATCH SIMPLE.';

-- Must go before politician_context_pkey can be dropped (2BP01 otherwise).
ALTER TABLE inform.politician_context_evidence
  DROP CONSTRAINT IF EXISTS politician_context_evidence_politician_id_topic_id_fkey;


-- -----------------------------------------------------------------------------
-- 2. The key swap
-- -----------------------------------------------------------------------------
ALTER TABLE inform.politician_answers DROP CONSTRAINT politician_answers_pkey;
ALTER TABLE inform.politician_answers
  ADD CONSTRAINT politician_answers_pkey
  PRIMARY KEY (politician_id, topic_id, season_id);

ALTER TABLE inform.politician_context DROP CONSTRAINT politician_context_pkey;
ALTER TABLE inform.politician_context
  ADD CONSTRAINT politician_context_pkey
  PRIMARY KEY (politician_id, topic_id, season_id);

-- Adding the PK on a nullable column is not possible, so this is implied above;
-- stated explicitly for topic_revision_id, which the PK does not cover.
ALTER TABLE inform.politician_answers
  ALTER COLUMN topic_revision_id SET NOT NULL;
ALTER TABLE inform.politician_context
  ALTER COLUMN topic_revision_id SET NOT NULL;

-- Re-establish evidence -> context on the new key.
ALTER TABLE inform.politician_context_evidence
  ADD CONSTRAINT politician_context_evidence_context_fkey
  FOREIGN KEY (politician_id, topic_id, season_id)
  REFERENCES inform.politician_context (politician_id, topic_id, season_id)
  ON DELETE CASCADE;


-- -----------------------------------------------------------------------------
-- 3. THE SCAFFOLDING. Temporary. See note 1 at the top.
-- -----------------------------------------------------------------------------
CREATE UNIQUE INDEX IF NOT EXISTS politician_answers_legacy_pair_scaffold
  ON inform.politician_answers (politician_id, topic_id);
CREATE UNIQUE INDEX IF NOT EXISTS politician_context_legacy_pair_scaffold
  ON inform.politician_context (politician_id, topic_id);

COMMENT ON INDEX inform.politician_answers_legacy_pair_scaffold IS
  'SCAFFOLDING, DROP ME. Keeps ON CONFLICT (politician_id, topic_id) resolving '
  'and prevents any bare-pair join from fanning out, while season-unaware '
  'consumers are still deployed. It also makes a second season IMPOSSIBLE — '
  'drop it, and only then open season 2.';
COMMENT ON INDEX inform.politician_context_legacy_pair_scaffold IS
  'SCAFFOLDING, DROP ME. See politician_answers_legacy_pair_scaffold.';


-- -----------------------------------------------------------------------------
-- 4. A row cannot cite a ladder its season never pinned
-- -----------------------------------------------------------------------------
ALTER TABLE inform.politician_answers
  ADD CONSTRAINT politician_answers_pin_fkey
  FOREIGN KEY (season_id, topic_id, topic_revision_id)
  REFERENCES inform.season_questions (season_id, topic_id, topic_revision_id);
ALTER TABLE inform.politician_context
  ADD CONSTRAINT politician_context_pin_fkey
  FOREIGN KEY (season_id, topic_id, topic_revision_id)
  REFERENCES inform.season_questions (season_id, topic_id, topic_revision_id);


-- -----------------------------------------------------------------------------
-- 5. A politician takes one of the five we publish
-- -----------------------------------------------------------------------------
-- Half steps are the CITIZEN signal and stay legal on compass_responses. They
-- were never legal for a politician in intent, only in the constraint.
ALTER TABLE inform.politician_answers
  DROP CONSTRAINT IF EXISTS politician_answers_value_half_step;
ALTER TABLE inform.politician_answers
  DROP CONSTRAINT IF EXISTS politician_answers_value_check;
ALTER TABLE inform.politician_answers
  ADD CONSTRAINT politician_answers_value_whole_1_to_5
  CHECK (value IN (1, 2, 3, 4, 5));


-- -----------------------------------------------------------------------------
-- 6. The pin cannot move once a season leaves draft
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION inform.season_pin_is_immutable()
RETURNS trigger LANGUAGE plpgsql AS $fn$
DECLARE v_status inform.season_status;
BEGIN
  SELECT status INTO v_status FROM inform.seasons WHERE id = OLD.season_id;
  IF v_status <> 'draft' AND NEW.topic_revision_id IS DISTINCT FROM OLD.topic_revision_id THEN
    RAISE EXCEPTION 'PIN_IMMUTABLE: season % is %, its pins cannot move',
      OLD.season_id, v_status;
  END IF;
  RETURN NEW;
END $fn$;

DROP TRIGGER IF EXISTS season_questions_pin_immutable ON inform.season_questions;
CREATE TRIGGER season_questions_pin_immutable
  BEFORE UPDATE ON inform.season_questions
  FOR EACH ROW EXECUTE FUNCTION inform.season_pin_is_immutable();


-- -----------------------------------------------------------------------------
DO $$
DECLARE v_n int;
BEGIN
  -- The keys
  IF (SELECT pg_get_constraintdef(c.oid) FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid
       WHERE t.relname='politician_answers' AND c.contype='p')
     <> 'PRIMARY KEY (politician_id, topic_id, season_id)' THEN
    RAISE EXCEPTION 'politician_answers primary key is wrong: %',
      (SELECT pg_get_constraintdef(c.oid) FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid
        WHERE t.relname='politician_answers' AND c.contype='p'); END IF;
  IF (SELECT pg_get_constraintdef(c.oid) FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid
       WHERE t.relname='politician_context' AND c.contype='p')
     <> 'PRIMARY KEY (politician_id, topic_id, season_id)' THEN
    RAISE EXCEPTION 'politician_context primary key is wrong'; END IF;

  -- The scaffolding must be PRESENT. Its absence here would mean the
  -- intermediate state is unsafe, not that we are further along.
  IF (SELECT count(*) FROM pg_indexes WHERE schemaname='inform'
       AND indexname IN ('politician_answers_legacy_pair_scaffold',
                         'politician_context_legacy_pair_scaffold')) <> 2 THEN
    RAISE EXCEPTION 'the scaffolding indexes are missing — season-unaware consumers would break'; END IF;

  -- The pin FKs
  IF (SELECT count(*) FROM pg_constraint
       WHERE conname IN ('politician_answers_pin_fkey','politician_context_pin_fkey')) <> 2 THEN
    RAISE EXCEPTION 'the composite pin foreign keys are missing'; END IF;

  -- Evidence
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_schema='inform' AND table_name='politician_context_evidence'
                    AND column_name='season_id') THEN
    RAISE EXCEPTION 'politician_context_evidence has no season_id'; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context_evidence WHERE season_id IS NULL;
  IF v_n <> 0 THEN
    RAISE EXCEPTION '% evidence rows did not get a season', v_n; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
                  WHERE conname='politician_context_evidence_context_fkey') THEN
    RAISE EXCEPTION 'the evidence -> context foreign key was not re-established'; END IF;

  -- The value CHECK
  IF EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid
              WHERE t.relname='politician_answers'
                AND c.conname IN ('politician_answers_value_half_step',
                                  'politician_answers_value_check')) THEN
    RAISE EXCEPTION 'an old value CHECK is still present on politician_answers'; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
                  WHERE conname='politician_answers_value_whole_1_to_5') THEN
    RAISE EXCEPTION 'the whole-number value CHECK was not added'; END IF;

  -- The trigger
  IF NOT EXISTS (SELECT 1 FROM pg_trigger
                  WHERE tgname='season_questions_pin_immutable' AND NOT tgisinternal) THEN
    RAISE EXCEPTION 'the pin-immutability trigger is missing'; END IF;

  -- Nothing may have been created or destroyed.
  IF (SELECT count(*) FROM inform.politician_answers) <> 33164 THEN
    RAISE EXCEPTION 'answer count changed during constrain: %',
      (SELECT count(*) FROM inform.politician_answers); END IF;
  IF (SELECT count(*) FROM inform.politician_context) <> 33818 THEN
    RAISE EXCEPTION 'context count changed during constrain: %',
      (SELECT count(*) FROM inform.politician_context); END IF;
  IF (SELECT count(*) FROM inform.politician_context_evidence) <> 183 THEN
    RAISE EXCEPTION 'evidence count changed during constrain: %',
      (SELECT count(*) FROM inform.politician_context_evidence); END IF;

  RAISE NOTICE 'constrain OK — keys swapped, pins enforced, value whole 1-5, scaffolding UP';
END $$;

COMMIT;
