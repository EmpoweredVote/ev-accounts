BEGIN;

-- =============================================================================
-- CA_0046: Rent Regulation — approve v2 and pin it into Season 2 (draft; not opened)
-- =============================================================================
-- Created 2026-08-30 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2,
-- candrews@empowered.vote).
--
-- WHAT: two steps on the rent-regulation v2 de-barrel (revision 6836f9f4, version 2 —
--   "Expand rent control to cover all rental units communitywide"):
--     1. APPROVE it (draft -> approved). NOT published: a substantive/major rewrite goes
--        live only when its bound season opens, never by a direct publish.
--     2. REPIN Season 2's rent-regulation question from v1 (revision 99429ab5) to v2.
--   Season 2 is a DRAFT and is NOT opened here.
--
-- WHY SAFE NOW: a season's pinned wording is served only for the OPEN season
--   (compassService.getPromotedTopics joins seasons status='open'). Season 2 is draft, so
--   this pin changes nothing a voter sees today; Season 1 keeps serving v1r1. The seatings
--   were already corrected in-place for BOTH seasons by CA_0045 (36 -> 7/167/24/29/10), so
--   there is no answer re-seat to stage here — this migration is metadata only (approve +
--   pin), no politician_answers / politician_context writes.
--
-- Mirrors CA_0034 / CA_0037 (religious-freedom / childcare Season-2 pins), with the extra
-- approve step because rent-regulation's v2 was proposed but never approved. Idempotent:
-- re-running after success is a no-op (v2 already approved; pin already equals v2).
-- =============================================================================

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
  v_topic    CONSTANT uuid := 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'; -- rent-regulation
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194'; -- Season 2
  v_v2       CONSTANT uuid := '6836f9f4-79e4-4d94-ad36-d195f5d2e7a2'; -- v2 (rev2)
  v_status   text;
  v_cur      uuid;
BEGIN
  -- Preconditions
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_topic AND topic_key = 'rent-regulation') THEN
    RAISE EXCEPTION 'CA_0046: rent-regulation topic id mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = v_v2 AND topic_id = v_topic AND revision = 2 AND version = 2) THEN
    RAISE EXCEPTION 'CA_0046: v2 revision missing';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season2 AND number = 2 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0046: Season 2 is not a draft (pin would be frozen)';
  END IF;

  -- Step 1: approve v2 (draft -> approved), idempotent.
  SELECT status INTO v_status FROM inform.compass_topic_revisions WHERE id = v_v2;
  IF v_status = 'draft' THEN
    PERFORM inform.admin_approve_topic_revision(v_v2, v_actor);
    RAISE NOTICE 'CA_0046: v2 approved (draft -> approved), not published.';
  ELSIF v_status = 'approved' THEN
    RAISE NOTICE 'CA_0046: v2 already approved; skipping approve.';
  ELSE
    RAISE EXCEPTION 'CA_0046: v2 in unexpected status % (expected draft or approved)', v_status;
  END IF;

  -- Step 2: repin Season 2 v1 -> v2, idempotent.
  SELECT topic_revision_id INTO v_cur FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_cur = v_v2 THEN
    RAISE NOTICE 'CA_0046: Season 2 already pins v2; skipping pin.';
  ELSE
    PERFORM inform.admin_season_pin_revision(v_season2, v_topic, v_v2, v_actor);
    RAISE NOTICE 'CA_0046: Season 2 rent-regulation repinned % -> % (v2)', v_cur, v_v2;
  END IF;
END $$;

-- =============================================================================
-- POST-VERIFY
-- =============================================================================
DO $$
DECLARE
  v_status    text;
  v_pub       timestamptz;
  v_iscur     boolean;
  v_pin       uuid;
  v_v1_cur    boolean;
  v_open_ver  int;
BEGIN
  -- v2 is approved, NOT published, NOT current.
  SELECT status, published_at, is_current INTO v_status, v_pub, v_iscur
    FROM inform.compass_topic_revisions WHERE id = '6836f9f4-79e4-4d94-ad36-d195f5d2e7a2';
  IF v_status <> 'approved' THEN RAISE EXCEPTION 'CA_0046 verify: v2 status is % (expected approved)', v_status; END IF;
  IF v_pub IS NOT NULL THEN RAISE EXCEPTION 'CA_0046 verify: v2 has a published_at (must stay unpublished)'; END IF;
  IF v_iscur THEN RAISE EXCEPTION 'CA_0046 verify: v2 is_current is true (must stay false until the season opens)'; END IF;

  -- v1 is still the current/published revision (untouched by approve).
  SELECT is_current INTO v_v1_cur FROM inform.compass_topic_revisions WHERE id = '99429ab5-e0bc-47b9-b8e8-cd9d6e0136a4';
  IF NOT v_v1_cur THEN RAISE EXCEPTION 'CA_0046 verify: v1 is no longer is_current'; END IF;

  -- Season 2 pins v2.
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND topic_id  = 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF v_pin <> '6836f9f4-79e4-4d94-ad36-d195f5d2e7a2' THEN
    RAISE EXCEPTION 'CA_0046 verify: Season 2 pin is % (expected v2)', v_pin;
  END IF;

  -- Season 1 (open) still resolves version 1 for rent-regulation.
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
  WHERE sq.topic_id = 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF v_open_ver IS NOT NULL AND v_open_ver <> 1 THEN
    RAISE EXCEPTION 'CA_0046 verify: open season resolves version % (expected 1)', v_open_ver;
  END IF;

  RAISE NOTICE 'CA_0046 post-verify OK: v2 approved (unpublished); Season 2 pins v2; Season 1 still serves v1.';
END $$;

COMMIT;
