BEGIN;

-- =============================================================================
-- CC_0044: closed seasons are read-only — ADR 0005 §1.6 rollout step 5
-- =============================================================================
-- Created 2026-09-02 with Chris Cantrell. The last unfinished step of the season
-- rollout, and the one ADR 0005 says is "easy to forget":
--
--   1. Deploy the season-aware code.          done, PR #177
--   2. Migrate the five RPCs.                 done, CC_0003
--   3. Drop the scaffolding indexes.          done, CC_0040
--   4. Open Season 2.                         PENDING — Chris's call
--   5. Add the closed-season immutability trigger.   <- THIS
--
-- WHAT IT ENFORCES: once a season is `closed`, its politician_answers and
-- politician_context rows can no longer be inserted, updated or deleted. That is
-- what makes "Season 1 is the historical record" a property of the database
-- rather than a habit.
--
-- 🔴 WHY THIS IS NOT THEORETICAL. Season 1 answer rows have already been deleted
-- repeatedly by re-audit migrations: CA_0035 (13 rows), CA_0038, CA_0039,
-- CA_0044, CA_0045, CA_0052, CA_0056 (58 rows), CC_0037 (12 rows). Every one was
-- individually defensible and every one edited history. Nothing at the schema
-- level objected, because nothing could. ADR 0005 §1.6: "nothing at the schema
-- level currently stops a write into a closed season. Today the write paths
-- cannot do it, because they only ever target the open one. A direct write
-- could." A direct write did, eight times.
--
-- ⚠ THIS CHANGES NOTHING TODAY, ON PURPOSE. Season 1 is still `open` and Season
-- 2 is `draft`; the trigger fires on neither. It arms itself at the moment
-- admin_open_season closes Season 1 — which is exactly why it must land BEFORE
-- the changeover, not after. Installing it afterwards means the window where
-- Season 1 is closed and unprotected is however long it takes someone to
-- remember.
--
-- DRAFT AND OPEN STAY WRITABLE, both deliberately:
--   - `draft` is where Season 2 rows are staged before the open.
--   - `open` is the season being researched. That is the whole point.
--
-- AN UPDATE IS CHECKED ON BOTH SIDES. Moving a row from a closed season into an
-- open one by UPDATE ... SET season_id would launder history forward, so the
-- OLD season is checked as well as the NEW one.
--
-- THE ESCAPE HATCH, AND WHY THERE IS ONE. Unlike ADR 0004's revision
-- immutability — where "write a new revision instead" is always the right
-- answer — a closed season can have a genuine need for surgery: a defamation
-- claim, a legal takedown, a person exercising a deletion right. With no hatch
-- the only recourse is DROP TRIGGER, which removes the protection globally and
-- relies on someone remembering to put it back. So instead:
--
--     SET LOCAL inform.allow_closed_season_write = 'on';
--
-- transaction-scoped, impossible to set by accident, and visible in the
-- migration that used it. The rule that matters is social, and is stated here so
-- there is no ambiguity later: USING IT REQUIRES A MIGRATION THAT SAYS WHY IN
-- ITS HEADER. It is not for re-audits. A re-audit belongs in the OPEN season as
-- a new row that shadows the old one — that is what the per-season primary key
-- and the newest-season-wins read are for.
-- =============================================================================

CREATE OR REPLACE FUNCTION inform.closed_season_is_immutable()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO ''
AS $function$
DECLARE
  v_status     inform.season_status;
  v_old_status inform.season_status;
  v_season_id  uuid;
  v_allowed    boolean;
BEGIN
  -- current_setting(..., true) returns NULL rather than raising when the GUC was
  -- never set, which is the normal case on every ordinary write.
  v_allowed := COALESCE(
    NULLIF(current_setting('inform.allow_closed_season_write', true), ''),
    'off'
  ) = 'on';

  IF v_allowed THEN
    RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
  END IF;

  -- NEW is unassigned in a DELETE trigger and referencing it would raise, so the
  -- operation decides which record to read rather than COALESCE over both.
  IF TG_OP = 'DELETE' THEN
    v_season_id := OLD.season_id;
  ELSE
    v_season_id := NEW.season_id;
  END IF;

  SELECT status INTO v_status FROM inform.seasons WHERE id = v_season_id;

  IF v_status = 'closed' THEN
    RAISE EXCEPTION
      'CLOSED_SEASON_IMMUTABLE: % on %.% targets season %, which is closed. A '
      'closed season is the historical record (ADR 0005 §1.6 step 5). To correct '
      'a politician''s position, write a row in the OPEN season — it shadows the '
      'old one on read without destroying it. If this really must edit history, '
      'SET LOCAL inform.allow_closed_season_write = ''on'' inside a migration '
      'that states why.',
      TG_OP, TG_TABLE_SCHEMA, TG_TABLE_NAME, v_season_id;
  END IF;

  -- An UPDATE that moves a row out of a closed season would launder history into
  -- the present, so the outgoing season is checked too.
  IF TG_OP = 'UPDATE' AND OLD.season_id IS DISTINCT FROM NEW.season_id THEN
    SELECT status INTO v_old_status FROM inform.seasons WHERE id = OLD.season_id;
    IF v_old_status = 'closed' THEN
      RAISE EXCEPTION
        'CLOSED_SEASON_IMMUTABLE: UPDATE on %.% would move a row out of season '
        '%, which is closed. Rows do not migrate between seasons; write a new '
        'row in the open season instead.',
        TG_TABLE_SCHEMA, TG_TABLE_NAME, OLD.season_id;
    END IF;
  END IF;

  RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$function$;

COMMENT ON FUNCTION inform.closed_season_is_immutable() IS
  'ADR 0005 s1.6 step 5. Blocks INSERT/UPDATE/DELETE against a closed season on '
  'the answer tables. Escape hatch: SET LOCAL inform.allow_closed_season_write '
  '= ''on'', which requires a migration stating why.';

DROP TRIGGER IF EXISTS politician_answers_closed_season_immutable
  ON inform.politician_answers;
CREATE TRIGGER politician_answers_closed_season_immutable
  BEFORE INSERT OR UPDATE OR DELETE ON inform.politician_answers
  FOR EACH ROW EXECUTE FUNCTION inform.closed_season_is_immutable();

DROP TRIGGER IF EXISTS politician_context_closed_season_immutable
  ON inform.politician_context;
CREATE TRIGGER politician_context_closed_season_immutable
  BEFORE INSERT OR UPDATE OR DELETE ON inform.politician_context
  FOR EACH ROW EXECUTE FUNCTION inform.closed_season_is_immutable();


-- -----------------------------------------------------------------------------
-- Verification. Proves the trigger by exercising it, not by trusting it exists.
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_open            uuid;
  v_draft           uuid;
  v_pol             uuid;
  v_topic           uuid;
  v_rev             uuid;
  v_fired           boolean;
  v_deleted_blocked boolean;
  v_hatch_works     boolean;
BEGIN
  SELECT id INTO v_open  FROM inform.seasons WHERE status = 'open'  LIMIT 1;
  SELECT id INTO v_draft FROM inform.seasons WHERE status = 'draft' LIMIT 1;

  IF v_open IS NULL THEN
    RAISE EXCEPTION 'CC_0044: no open season — refusing to verify against an unknown state';
  END IF;
  IF v_draft IS NULL THEN
    RAISE EXCEPTION 'CC_0044: no draft season — the closed-season probe below has nothing to close, and an unverified trigger is not worth installing';
  END IF;

  -- (a) The open season must still be writable. A trigger that blocks the open
  --     season would take compass research down, which is the failure ADR 0005
  --     Part 2 describes.
  -- ⚠ The topic must exist in the DRAFT season too, or probe (b) below inserts
  -- zero rows, never fires the trigger, and reports a false pass. One topic
  -- (Immigration, CA_0066) is in the open season and NOT in the draft, so
  -- picking any old answer row is not safe.
  SELECT pa.politician_id, pa.topic_id, pa.topic_revision_id
    INTO v_pol, v_topic, v_rev
    FROM inform.politician_answers pa
   WHERE pa.season_id = v_open
     AND (v_draft IS NULL OR EXISTS (
           SELECT 1 FROM inform.season_questions sq
            WHERE sq.season_id = v_draft AND sq.topic_id = pa.topic_id))
   LIMIT 1;

  IF v_pol IS NULL THEN
    RAISE EXCEPTION 'CC_0044: the open season has no answer rows to test against';
  END IF;

  UPDATE inform.politician_answers
     SET updated_at = updated_at
   WHERE politician_id = v_pol AND topic_id = v_topic AND season_id = v_open;
  -- reaching here means the open season accepted a write

  -- (b)(c)(d) A closed season must refuse INSERT and DELETE, and the escape
  --     hatch must still open it. No season is closed yet, so the probe closes
  --     one momentarily inside a subtransaction and rolls that back. Nothing
  --     below survives; the whole DO block sits inside the migration's own
  --     transaction as well.
  --
  --     DELETE is probed specifically because deletion — not insertion — is what
  --     actually happened to Season 1 eight times.
  v_fired := false;
  v_deleted_blocked := false;
  v_hatch_works := false;
  BEGIN
    -- seasons_dates_follow_status requires a closed season to carry both
    -- opened_at and closed_at, so the probe cannot just flip the status.
    UPDATE inform.seasons
       SET status = 'closed', opened_at = now(), closed_at = now()
     WHERE id = v_draft;

    BEGIN
      INSERT INTO inform.politician_answers
        (politician_id, topic_id, season_id, topic_revision_id, value)
      SELECT v_pol, sq.topic_id, v_draft, sq.topic_revision_id, 3
        FROM inform.season_questions sq
       WHERE sq.season_id = v_draft AND sq.topic_id = v_topic
       LIMIT 1;
    EXCEPTION WHEN OTHERS THEN
      IF SQLERRM LIKE 'CLOSED_SEASON_IMMUTABLE:%' THEN v_fired := true; ELSE RAISE; END IF;
    END;

    UPDATE inform.seasons SET status = 'closed', closed_at = now() WHERE id = v_open;

    BEGIN
      DELETE FROM inform.politician_answers
       WHERE politician_id = v_pol AND topic_id = v_topic AND season_id = v_open;
    EXCEPTION WHEN OTHERS THEN
      IF SQLERRM LIKE 'CLOSED_SEASON_IMMUTABLE:%' THEN v_deleted_blocked := true; ELSE RAISE; END IF;
    END;

    PERFORM set_config('inform.allow_closed_season_write', 'on', true);
    DELETE FROM inform.politician_answers
     WHERE politician_id = v_pol AND topic_id = v_topic AND season_id = v_open;
    v_hatch_works := true;
    PERFORM set_config('inform.allow_closed_season_write', 'off', true);

    RAISE EXCEPTION 'CC_0044_ROLLBACK_PROBE';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM <> 'CC_0044_ROLLBACK_PROBE' THEN RAISE; END IF;
  END;

  IF NOT v_fired THEN
    RAISE EXCEPTION 'CC_0044: INSERT into a CLOSED season was NOT blocked';
  END IF;
  IF NOT v_deleted_blocked THEN
    RAISE EXCEPTION 'CC_0044: DELETE from a CLOSED season was NOT blocked — the exact failure this exists to prevent';
  END IF;
  IF NOT v_hatch_works THEN
    RAISE EXCEPTION 'CC_0044: the escape hatch did not permit a deliberate write — a closed season would be uncorrectable';
  END IF;

  RAISE NOTICE 'CC_0044 OK: open writable; closed refuses INSERT and DELETE; escape hatch works.';
END $$;

COMMIT;
