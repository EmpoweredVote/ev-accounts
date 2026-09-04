BEGIN;

-- =============================================================================
-- CC_0067: stamp answered_revision_id when the answer is written
-- =============================================================================
-- Created 2026-09-04 with Chris Cantrell, found while diagnosing the Season 2
-- open.
--
-- 🔴 NOTHING HAS EVER STAMPED THIS COLUMN ON WRITE. `CA_0012` backfilled it once
-- (applied 2026-08-21, 184 responses) with `UPDATE ... WHERE
-- answered_revision_id IS NULL`, and that is the only writer in the repo's
-- history. `upsert_compass_answer` does not set it, the column has no DEFAULT,
-- and the one BEFORE trigger on the table
-- (`compass_responses_assign_season`) sets only `season_id`.
--
-- Measured on prod: every day before 2026-09-04 is 100% stamped — that is
-- CA_0012's backfill — and the rows written on 2026-09-04 are 0% stamped.
--
-- 🔴 WHY THAT QUIETLY DEFUSES THE WHOLE RE-ASK. CC_0061 returns 'fresh' when
-- `answered_revision_id IS NULL`, deliberately:
--
--   "An answer with no stamped revision is treated as fresh, not flagged.
--    Nagging someone because of a NULL we wrote is worse than missing a
--    genuine revision. (3 of 187 rows in prod pre-date stamping.)"
--
-- That reasoning is right, and it was written believing the NULL case covered
-- THREE ROWS. In fact it covers every answer written from 2026-08-21 onward, so
-- no answer given from now on could ever be flagged, moved or invalidated by a
-- future season rollover. The Season 2 re-ask worked only because the corpus it
-- ran against had been backfilled. The escape hatch had quietly become the rule.
--
-- ⚠ A TRIGGER, NOT A CHANGE TO upsert_compass_answer, BECAUSE THE RPC IS NOT THE
-- ONLY WRITER. `promoteCompassImportDraft` promotes a guest's compass, and admin
-- and migration paths write here too. Stamping in one caller would leave the
-- others silently unstamped, which is the defect this migration exists to close.
--
-- ⚠ IT RESOLVES THE REVISION EXACTLY AS getPromotedTopics() AND CC_0061 DO
-- (ADR 0006 Option Y): the LATEST revision of the version the season PINNED, not
-- is_current. Any other resolution would stamp an answer against a revision the
-- disposition rule does not compare against, and the comparison would be
-- meaningless in both directions.
--
-- 🔴 IT NEVER FAILS A WRITE. If the topic is not in the open season's set, or no
-- publishable revision resolves, the stamp is left NULL and the answer is stored
-- anyway. Losing a person's stated view because we could not label it would be a
-- far worse bug than the one being fixed — and CC_0061 already treats NULL as
-- fresh, which is the safe direction.

CREATE OR REPLACE FUNCTION inform.compass_responses_stamp_revision()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO ''
AS $function$
DECLARE
  v_revision uuid;
  v_restamp  boolean;
BEGIN
  -- Decide whether this write is a NEW statement of a position.
  IF TG_OP = 'INSERT' THEN
    v_restamp := NEW.answered_revision_id IS NULL;
  ELSE
    -- A changed value or write-in is the user answering again, so the stamp must
    -- move to the wording they answered against this time. Reviving a
    -- soft-deleted row counts too: the upsert path clears deleted_at when
    -- somebody re-answers a question they had reset.
    v_restamp :=
      NEW.value        IS DISTINCT FROM OLD.value
      OR NEW.write_in_text IS DISTINCT FROM OLD.write_in_text
      OR (OLD.deleted_at IS NOT NULL AND NEW.deleted_at IS NULL)
      OR NEW.answered_revision_id IS NULL;
  END IF;

  IF NOT v_restamp THEN
    RETURN NEW;
  END IF;

  -- The revision the open season actually serves for this topic. Mirrors
  -- getPromotedTopics()'s lateral (ADR 0006 Option Y).
  SELECT e.id INTO v_revision
    FROM inform.compass_topics_promoted p
    JOIN inform.compass_topic_revisions pin ON pin.id = p.season_revision_id
    JOIN inform.compass_topic_revisions e
      ON e.topic_id = pin.topic_id
     AND e.version  = pin.version
     AND e.status IN ('published', 'superseded')
   WHERE p.id = NEW.topic_id
   ORDER BY e.revision DESC
   LIMIT 1;

  -- NULL is tolerated on purpose — see the header. Never raise here.
  IF v_revision IS NOT NULL THEN
    NEW.answered_revision_id := v_revision;
  END IF;

  RETURN NEW;
END;
$function$;

COMMENT ON FUNCTION inform.compass_responses_stamp_revision() IS
  'Stamps compass_responses.answered_revision_id with the revision the OPEN season '
  'serves for that topic, on insert and whenever the answer itself changes. Resolved '
  'exactly as getPromotedTopics does (ADR 0006 Option Y). Never fails a write: an '
  'unresolvable topic leaves the stamp NULL, which CC_0061 reads as fresh (CC_0067).';

DROP TRIGGER IF EXISTS compass_responses_stamp_revision ON inform.compass_responses;
CREATE TRIGGER compass_responses_stamp_revision
  BEFORE INSERT OR UPDATE ON inform.compass_responses
  FOR EACH ROW EXECUTE FUNCTION inform.compass_responses_stamp_revision();

-- -----------------------------------------------------------------------------
-- Prove it stamps, in a subtransaction that always rolls back.
-- -----------------------------------------------------------------------------
-- A BEGIN/EXCEPTION block is an implicit subtransaction, so the probe writes a
-- real row, inspects the stamp the trigger applied, then aborts back out. No
-- user's data is touched and nothing survives the block either way.
DO $$
DECLARE
  v_user     uuid;
  v_topic    uuid;
  v_stamped  uuid;
  v_expected uuid;
BEGIN
  SELECT user_id INTO v_user FROM inform.compass_responses LIMIT 1;

  -- A question the open season asks that this user has no row for, so a plain
  -- INSERT is valid.
  SELECT p.id INTO v_topic
    FROM inform.compass_topics_promoted p
   WHERE NOT EXISTS (
     SELECT 1 FROM inform.compass_responses r
      WHERE r.user_id = v_user AND r.topic_id = p.id
        AND r.season_id = (SELECT id FROM inform.seasons WHERE status = 'open')
   )
   LIMIT 1;

  IF v_user IS NULL OR v_topic IS NULL THEN
    RAISE WARNING 'CC_0067: no (user, unanswered promoted topic) pair available — trigger installed but NOT exercised. Verify by hand.';
    RETURN;
  END IF;

  SELECT e.id INTO v_expected
    FROM inform.compass_topics_promoted p
    JOIN inform.compass_topic_revisions pin ON pin.id = p.season_revision_id
    JOIN inform.compass_topic_revisions e
      ON e.topic_id = pin.topic_id AND e.version = pin.version
     AND e.status IN ('published','superseded')
   WHERE p.id = v_topic
   ORDER BY e.revision DESC LIMIT 1;

  BEGIN
    INSERT INTO inform.compass_responses (user_id, topic_id, value, updated_at)
    VALUES (v_user, v_topic, 3, now())
    RETURNING answered_revision_id INTO v_stamped;

    IF v_stamped IS NULL THEN
      RAISE EXCEPTION 'CC_0067: the trigger did not stamp a new answer on a promoted topic';
    END IF;
    IF v_expected IS NOT NULL AND v_stamped <> v_expected THEN
      RAISE EXCEPTION 'CC_0067: stamped % but the season serves % for that topic', v_stamped, v_expected;
    END IF;

    RAISE NOTICE 'CC_0067 OK: a new answer stamps % (the revision the open season serves). Probe rolled back.', v_stamped;

    -- Abort the subtransaction. This is the only way out.
    RAISE EXCEPTION 'CC_0067_PROBE_ROLLBACK';
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLERRM <> 'CC_0067_PROBE_ROLLBACK' THEN
        RAISE;
      END IF;
  END;
END $$;

COMMIT;
