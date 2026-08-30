BEGIN;

-- =============================================================================
-- CA_0037: Childcare — pin the approved v2 into Season 2 (draft; not opened)
-- =============================================================================
-- Created 2026-08-30 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2,
-- candrews@empowered.vote).
--
-- WHAT: repin Season 2's childcare question from v1 (revision 30cb4666) to the approved
--   substantive v2 (revision 0e9fe0f2, version 2) parked by CA_0036. Season 2 is a DRAFT
--   and is NOT opened here.
--
-- WHY SAFE NOW: a season's pinned wording is served only for the OPEN season
--   (compassService.getPromotedTopics joins seasons status='open'). Season 2 is draft,
--   so this pin changes nothing a voter sees today. Season 1 keeps serving v1r1.
--
-- WHY ONLY THE PIN (answer re-seating is NOT here): the compare read path collapses to
--   the NEWEST season's answer per topic with no status gate
--   (compassService.getCompassPoliticians / getPoliticianCurrentAnswers), so writing any
--   Season-2 answer row while Season 2 is a draft would leak into the LIVE Season-1
--   compass (a blank/removed seating would drop that politician immediately). The
--   re-seating of the twelve option-4 axis-orphans is therefore staged in CA_0038,
--   guarded to run only once Season 2 is open. The re-audit dispositions are recorded in
--   backend/data/season2-carry/childcare-chair4-reaudit.json (heuristic worklist) and,
--   once verified to primary sources, in the dispositions file consumed by CA_0038.
--
-- Mirrors CA_0034 (religious-freedom Season-2 pin) exactly. Idempotent: re-running after
-- success is a no-op (the pin already equals v2).
-- =============================================================================

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
  v_topic    CONSTANT uuid := 'c1ac1330-47f7-44ec-baf3-c913d926b97c'; -- childcare
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194'; -- Season 2
  v_v2       CONSTANT uuid := '0e9fe0f2-cfab-4553-99cd-c3195d08e236'; -- approved v2 (rev2)
  v_cur      uuid;
BEGIN
  -- Preconditions
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_topic AND topic_key = 'childcare') THEN
    RAISE EXCEPTION 'CA_0037: childcare topic id mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = v_v2 AND topic_id = v_topic AND version = 2 AND status = 'approved') THEN
    RAISE EXCEPTION 'CA_0037: v2 revision is not approved (run CA_0036 first)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season2 AND number = 2 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0037: Season 2 is not a draft (pin would be frozen)';
  END IF;

  SELECT topic_revision_id INTO v_cur FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;

  IF v_cur = v_v2 THEN
    RAISE NOTICE 'CA_0037 already applied — Season 2 already pins v2; skipping.';
  ELSE
    PERFORM inform.admin_season_pin_revision(v_season2, v_topic, v_v2, v_actor);
    RAISE NOTICE 'CA_0037: Season 2 childcare repinned % -> % (v2)', v_cur, v_v2;
  END IF;
END $$;

-- =============================================================================
-- POST-VERIFY
-- =============================================================================
DO $$
DECLARE
  v_pin      uuid;
  v_open_ver int;
BEGIN
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND topic_id  = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';
  IF v_pin <> '0e9fe0f2-cfab-4553-99cd-c3195d08e236' THEN
    RAISE EXCEPTION 'CA_0037 post-verify: Season 2 pin is % (expected v2)', v_pin;
  END IF;

  -- Season 1 (open) still resolves version 1 for childcare.
  SELECT eff.version INTO v_open_ver
  FROM inform.season_questions sq
  JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
  JOIN inform.compass_topic_revisions pin ON pin.id = sq.topic_revision_id
  JOIN LATERAL (
    SELECT ee.version FROM inform.compass_topic_revisions ee
    WHERE ee.topic_id = pin.topic_id AND ee.version = pin.version
      AND ee.status IN ('published','superseded')
    ORDER BY ee.revision DESC LIMIT 1
  ) eff ON true
  WHERE sq.topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';
  IF v_open_ver IS NOT NULL AND v_open_ver <> 1 THEN
    RAISE EXCEPTION 'CA_0037 post-verify: open season resolves version % (expected 1)', v_open_ver;
  END IF;

  RAISE NOTICE 'CA_0037 post-verify OK: Season 2 pins v2; Season 1 still serves v1.';
END $$;

COMMIT;
