BEGIN;

-- =============================================================================
-- CA_0034: Religious Freedom — pin the approved v2 into Season 2 (draft; not opened)
-- =============================================================================
-- Created 2026-08-30 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
--
-- WHAT: repin Season 2's religious-freedom question from v1 (6c4b402f) to the approved
--   substantive v2 (dfbd847a, version 2) created by CA_0030. Season 2 is a DRAFT and is
--   NOT opened here.
--
-- WHY SAFE NOW: a season's pinned wording is served only for the OPEN season
--   (compassService.getPromotedTopics joins seasons status='open'). Season 2 is draft,
--   so this pin changes nothing a voter sees today. Season 1 keeps serving v1.
--
-- WHY ONLY THE PIN (answer re-seating is NOT here): the compare read path collapses to
--   the NEWEST season's answer per topic with no status gate
--   (compassService.getCompassPoliticians / getPoliticianCurrentAnswers), so writing any
--   Season-2 answer row while Season 2 is a draft would leak into the LIVE Season-1
--   compass (a value-0 blank would drop that politician immediately). The re-seating is
--   therefore staged in CA_0035, guarded to run only once Season 2 is open. The verified
--   chair-1 re-audit (11 carry / 1 move / 13 blank, primary sources) is recorded in
--   backend/data/season2-carry/religious-freedom-chair1-dispositions.json.
--
-- Idempotent: re-running after success is a no-op (the pin already equals v2).
-- =============================================================================

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
  v_topic    CONSTANT uuid := '6b9ba6d9-1001-43f5-b073-4d37130696fd'; -- religious-freedom
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194'; -- Season 2
  v_v2       CONSTANT uuid := 'dfbd847a-294c-49d2-9ac3-69270ea03054'; -- approved v2 (rev3)
  v_cur      uuid;
BEGIN
  -- Preconditions
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id=v_topic AND topic_key='religious-freedom') THEN
    RAISE EXCEPTION 'CA_0034: religious-freedom topic id mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id=v_v2 AND topic_id=v_topic AND version=2 AND status='approved') THEN
    RAISE EXCEPTION 'CA_0034: v2 revision is not approved';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id=v_season2 AND number=2 AND status='draft') THEN
    RAISE EXCEPTION 'CA_0034: Season 2 is not a draft (pin would be frozen)';
  END IF;

  SELECT topic_revision_id INTO v_cur FROM inform.season_questions
   WHERE season_id=v_season2 AND topic_id=v_topic;

  IF v_cur = v_v2 THEN
    RAISE NOTICE 'CA_0034 already applied — Season 2 already pins v2; skipping.';
  ELSE
    PERFORM inform.admin_season_pin_revision(v_season2, v_topic, v_v2, v_actor);
    RAISE NOTICE 'CA_0034: Season 2 religious-freedom repinned % -> % (v2)', v_cur, v_v2;
  END IF;
END $$;

-- POST-VERIFY
DO $$
DECLARE
  v_pin uuid;
  v_open_ver int;
BEGIN
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions
   WHERE season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd';
  IF v_pin <> 'dfbd847a-294c-49d2-9ac3-69270ea03054' THEN
    RAISE EXCEPTION 'CA_0034 post-verify: Season 2 pin is % (expected v2)', v_pin;
  END IF;

  -- Season 1 (open) still resolves version 1 for religious-freedom.
  SELECT eff.version INTO v_open_ver
  FROM inform.season_questions sq
  JOIN inform.seasons s ON s.id=sq.season_id AND s.status='open'
  JOIN inform.compass_topic_revisions pin ON pin.id=sq.topic_revision_id
  JOIN LATERAL (
    SELECT ee.version FROM inform.compass_topic_revisions ee
    WHERE ee.topic_id=pin.topic_id AND ee.version=pin.version
      AND ee.status IN ('published','superseded')
    ORDER BY ee.revision DESC LIMIT 1
  ) eff ON true
  WHERE sq.topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd';
  IF v_open_ver IS NOT NULL AND v_open_ver <> 1 THEN
    RAISE EXCEPTION 'CA_0034 post-verify: open season resolves version % (expected 1)', v_open_ver;
  END IF;

  RAISE NOTICE 'CA_0034 post-verify OK: Season 2 pins v2; Season 1 still serves v1.';
END $$;

COMMIT;
