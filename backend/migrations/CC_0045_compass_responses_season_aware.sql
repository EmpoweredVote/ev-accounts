BEGIN;

-- =============================================================================
-- CC_0045: make user compass answers season-aware — STAGE 1 OF 2
-- =============================================================================
-- Created 2026-09-02 with Chris Cantrell.
--
-- THE GOAL (Chris, 2026-09-02): "For the individual, they should also be able to
-- see previous stances from earlier seasons — but only be able to update the
-- answers on the current season."
--
-- Today that is impossible. inform.compass_responses is keyed
-- (user_id, topic_id) with no season anywhere on the row, so a person has
-- exactly one answer per topic for all time and re-answering OVERWRITES it.
-- politician_answers has been season-aware since CC_0002; the user side never
-- was. This closes that gap.
--
-- 🔴 STAGE 1 CHANGES NO BEHAVIOUR. That is the point. It puts the column, the
-- key and the backfill in place while a scaffold index keeps exactly one row per
-- (user, topic) — so every existing read returns precisely what it returns
-- today. Stage 2 drops the scaffold and turns the history on. See the bottom of
-- this header for what stage 2 must do and why it must land BEFORE Season 2
-- opens.
--
-- WHY NOW: there are 189 user response rows in production. Adding the column is
-- nearly free today. After Season 2 opens with real traffic it becomes a
-- migration with genuine ambiguity about which season each existing row belongs
-- to — and every day of growth makes it worse.
--
-- -----------------------------------------------------------------------------
-- HOW season_id GETS FILLED, AND WHY NO RPC IS EDITED HERE
-- -----------------------------------------------------------------------------
-- Four SECURITY DEFINER functions INSERT into this table:
--   public.upsert_compass_answer          (the main write path)
--   public.import_compass_calibrations
--   public.migrate_guest_compass_state
--   public.promote_compass_import_draft
-- and every one of them uses ON CONFLICT (user_id, topic_id).
--
-- Rather than edit four security-sensitive functions, a BEFORE INSERT trigger
-- fills season_id with the open season when the caller does not supply one.
-- BEFORE triggers run before NOT NULL is checked, so the column can still be
-- NOT NULL. This is strictly safer: it covers every current write path AND every
-- future one, with no chance of one being missed. Verified that no other writer
-- exists — all PostgREST use of this table in backend/src is .select() only.
--
-- The trigger is named to sort BEFORE the closed-season trigger stage 2 will
-- add, so season_id is populated before anything inspects it.
--
-- -----------------------------------------------------------------------------
-- THE SCAFFOLD — deliberate, and copied from CC_0002
-- -----------------------------------------------------------------------------
-- compass_responses_legacy_pair_scaffold is a UNIQUE index on
-- (user_id, topic_id): the same trick CC_0002 used on politician_answers and
-- that CC_0040 finally removed. While it stands:
--   - ON CONFLICT (user_id, topic_id) in all four RPCs still resolves, unedited;
--   - a user physically cannot hold rows in two seasons;
--   - therefore no read can double-count, and every existing query is correct
--     with no change at all.
-- It is what makes stage 1 safe to ship on its own.
--
-- 🔴 WHAT STAGE 2 MUST DO, IN THIS ORDER, BEFORE SEASON 2 OPENS:
--   1. Teach every read to collapse newest-season-wins, exactly as the
--      politician side does (DISTINCT ON (topic_id) ... ORDER BY topic_id,
--      s.number DESC). ~12 sites across compassService, compassStatsService,
--      compassUserLensService, candidateService, profileService and
--      routes/compass.ts.
--   2. Season-scope public.reset_compass_answers. It currently does
--      UPDATE ... WHERE user_id = p_user_id with no season predicate, which
--      after the scaffold drops would soft-delete a person's history in every
--      season, and once the closed-season trigger is attached would simply
--      raise.
--   3. Repoint the four ON CONFLICT clauses to the real primary key.
--   4. Drop the scaffold.
--   5. Attach inform.closed_season_is_immutable() (CC_0044) to this table.
--
-- ⚠ DO NOT ATTACH THE CLOSED-SEASON TRIGGER YET. With the scaffold up and
-- Season 2 open, a returning user's write would ON CONFLICT onto their Season 1
-- row — a closed season — and the trigger would abort it. Every returning user
-- would fail to answer. Steps 4 and 5 belong together, after 1-3.
--
-- ⚠ OPENING SEASON 2 WITH THIS SCAFFOLD STILL UP IS NOT FATAL BUT IS WRONG:
-- answers would keep landing on the Season 1 row and no history would ever
-- accumulate. Stage 2 is a prerequisite for the open, not a follow-up.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. The column, backfilled to Season 1.
-- -----------------------------------------------------------------------------
-- Added nullable, backfilled, then made NOT NULL — the standard three-step, so
-- the table is never briefly in violation.
--
-- Every existing row is backfilled to Season 1 because Season 1 is the only
-- season that has ever been open: Season 2 has never opened and holds zero
-- answers of any kind. There is no ambiguity to resolve, which is exactly why
-- this is cheap today and would not be later.

ALTER TABLE inform.compass_responses
  ADD COLUMN IF NOT EXISTS season_id uuid;

UPDATE inform.compass_responses
   SET season_id = (SELECT id FROM inform.seasons WHERE number = 1)
 WHERE season_id IS NULL;

ALTER TABLE inform.compass_responses
  ALTER COLUMN season_id SET NOT NULL;

ALTER TABLE inform.compass_responses
  DROP CONSTRAINT IF EXISTS compass_responses_season_id_fkey;
ALTER TABLE inform.compass_responses
  ADD CONSTRAINT compass_responses_season_id_fkey
  FOREIGN KEY (season_id) REFERENCES inform.seasons(id);


-- -----------------------------------------------------------------------------
-- 2. The key: one row per (user, topic, season).
-- -----------------------------------------------------------------------------
-- Mirrors politician_answers_pkey exactly. This is the change that makes a
-- per-season answer representable at all.

ALTER TABLE inform.compass_responses
  DROP CONSTRAINT compass_responses_pkey;
ALTER TABLE inform.compass_responses
  ADD CONSTRAINT compass_responses_pkey
  PRIMARY KEY (user_id, topic_id, season_id);


-- -----------------------------------------------------------------------------
-- 3. The scaffold. Stage 2 drops this; nothing else should.
-- -----------------------------------------------------------------------------

CREATE UNIQUE INDEX IF NOT EXISTS compass_responses_legacy_pair_scaffold
  ON inform.compass_responses (user_id, topic_id);

COMMENT ON INDEX inform.compass_responses_legacy_pair_scaffold IS
  'CC_0045 stage 1 scaffold, modelled on CC_0002. Holds users to one answer row '
  'per topic across all seasons so the four ON CONFLICT (user_id, topic_id) RPCs '
  'and every existing read keep working unchanged. Dropping it is stage 2 and '
  'must happen together with the season-collapse read changes — see CC_0045.';


-- -----------------------------------------------------------------------------
-- 4. Fill season_id automatically on insert.
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION inform.compass_responses_assign_season()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO ''
AS $function$
BEGIN
  IF NEW.season_id IS NULL THEN
    SELECT id INTO NEW.season_id FROM inform.seasons WHERE status = 'open';
    IF NEW.season_id IS NULL THEN
      -- Matches how the politician write paths behave with no open season: a
      -- clean refusal, not a row filed under a guess. ADR 0005 Part 2 describes
      -- the day this actually happened.
      RAISE EXCEPTION
        'NO_OPEN_SEASON: cannot record a compass answer while no season is open';
    END IF;
  END IF;
  RETURN NEW;
END;
$function$;

COMMENT ON FUNCTION inform.compass_responses_assign_season() IS
  'CC_0045. Fills compass_responses.season_id with the open season when a writer '
  'does not supply one, so the four ON CONFLICT RPCs did not need editing. Named '
  'to sort before the closed-season trigger stage 2 adds.';

DROP TRIGGER IF EXISTS compass_responses_assign_season ON inform.compass_responses;
CREATE TRIGGER compass_responses_assign_season
  BEFORE INSERT ON inform.compass_responses
  FOR EACH ROW EXECUTE FUNCTION inform.compass_responses_assign_season();


-- -----------------------------------------------------------------------------
-- 5. Verification. Exercises the behaviour rather than trusting the DDL.
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_s1        uuid;
  v_open      uuid;
  v_unfilled  int;
  v_rows      int;
  v_pk        text;
  v_user      uuid;
  v_topic     uuid;
  v_assigned  uuid;
  v_blocked   boolean;
BEGIN
  SELECT id INTO v_s1   FROM inform.seasons WHERE number = 1;
  SELECT id INTO v_open FROM inform.seasons WHERE status = 'open';

  -- (a) Nothing was left behind by the backfill.
  SELECT count(*) INTO v_unfilled
    FROM inform.compass_responses WHERE season_id IS NULL;
  IF v_unfilled <> 0 THEN
    RAISE EXCEPTION 'CC_0045: % rows still have a null season_id', v_unfilled;
  END IF;

  SELECT count(*) INTO v_rows
    FROM inform.compass_responses WHERE season_id <> v_s1;
  IF v_rows <> 0 THEN
    RAISE EXCEPTION 'CC_0045: % rows are filed under a season other than Season 1', v_rows;
  END IF;

  -- (b) The key really is the three-column one.
  SELECT pg_get_constraintdef(oid) INTO v_pk
    FROM pg_constraint WHERE conrelid = 'inform.compass_responses'::regclass
     AND contype = 'p';
  IF v_pk <> 'PRIMARY KEY (user_id, topic_id, season_id)' THEN
    RAISE EXCEPTION 'CC_0045: primary key is "%", expected the three-column key', v_pk;
  END IF;

  -- (c) The scaffold is present — stage 1 is not safe without it.
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes
     WHERE schemaname = 'inform'
       AND indexname = 'compass_responses_legacy_pair_scaffold'
  ) THEN
    RAISE EXCEPTION 'CC_0045: the scaffold index is missing — reads could double-count';
  END IF;

  -- (d) An insert that supplies no season_id lands in the OPEN season, and a
  --     second row for the same (user, topic) in another season is refused by
  --     the scaffold. Both proved against a real row, then rolled back.
  SELECT user_id, topic_id INTO v_user, v_topic
    FROM inform.compass_responses LIMIT 1;

  IF v_user IS NOT NULL THEN
    v_blocked := false;
    BEGIN
      DELETE FROM inform.compass_responses
       WHERE user_id = v_user AND topic_id = v_topic;

      INSERT INTO inform.compass_responses (user_id, topic_id, value, visibility, inverted)
      VALUES (v_user, v_topic, 3, 'private', false);

      SELECT season_id INTO v_assigned
        FROM inform.compass_responses
       WHERE user_id = v_user AND topic_id = v_topic;

      IF v_assigned IS DISTINCT FROM v_open THEN
        RAISE EXCEPTION
          'CC_0045: an insert with no season_id landed in %, expected the open season %',
          v_assigned, v_open;
      END IF;

      BEGIN
        INSERT INTO inform.compass_responses
          (user_id, topic_id, season_id, value, visibility, inverted)
        SELECT v_user, v_topic, id, 4, 'private', false
          FROM inform.seasons WHERE status = 'draft' LIMIT 1;
      EXCEPTION WHEN unique_violation THEN
        v_blocked := true;
      END;

      RAISE EXCEPTION 'CC_0045_ROLLBACK_PROBE';
    EXCEPTION WHEN OTHERS THEN
      IF SQLERRM <> 'CC_0045_ROLLBACK_PROBE' THEN RAISE; END IF;
    END;

    IF NOT v_blocked THEN
      RAISE EXCEPTION
        'CC_0045: a second season row was accepted — the scaffold is not holding, and reads can double-count';
    END IF;
  END IF;

  RAISE NOTICE 'CC_0045 OK: season_id backfilled to Season 1, 3-column PK, scaffold holding, inserts default to the open season.';
END $$;

COMMIT;
