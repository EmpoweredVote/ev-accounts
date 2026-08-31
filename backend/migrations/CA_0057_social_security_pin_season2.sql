BEGIN;

-- =============================================================================
-- CA_0057: Social Security — pin v2 into Season 2 (draft; not opened)
-- =============================================================================
-- Created 2026-08-30 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2,
-- candrews@empowered.vote).
--
-- WHAT: repin Season 2's social-security question from v1 (revision a624f5d1) to the
--   approved v2 (revision 8defc029, version 2 — "gradually reduce future benefits rather
--   than raise taxes to keep Social Security solvent"). Season 2 is a DRAFT and is NOT
--   opened here.
--
-- PRECONDITIONS MET: v2 was approved by CA_0054 (draft->approved, unpublished). The 98
--   chair-4 seatings were re-audited by CA_0056 (dist -> 107/208/180/26/78) so Season 2
--   inherits corrected seatings when it opens.
--
-- WHY SAFE NOW: a season's pinned wording is served only for the OPEN season
--   (compassService.getPromotedTopics joins seasons status='open'). Season 2 is draft, so
--   this pin changes nothing a voter sees today; Season 1 keeps serving v1r1. Metadata
--   only (repin) — no politician_answers / politician_context writes here.
--
-- Mirrors CA_0046 (rent-regulation Season-2 pin), minus the approve step (v2 already
-- approved by CA_0054). Idempotent: re-running after success is a no-op (pin already v2).
-- =============================================================================

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
  v_topic    CONSTANT uuid := '87d20824-a6e9-407b-983c-65440084a0ab'; -- social-security
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194'; -- Season 2
  v_v2       CONSTANT uuid := '8defc029-0b7e-426f-b838-a2e170f566c9'; -- v2 (rev2)
  v_v2_status text;
  v_cur      uuid;
BEGIN
  -- Preconditions
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_topic AND topic_key = 'social-security') THEN
    RAISE EXCEPTION 'CA_0057: social-security topic id mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season2 AND number = 2 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0057: Season 2 is not a draft (pin would be frozen)';
  END IF;
  SELECT status INTO v_v2_status FROM inform.compass_topic_revisions
   WHERE id = v_v2 AND topic_id = v_topic AND revision = 2 AND version = 2;
  IF v_v2_status IS NULL THEN
    RAISE EXCEPTION 'CA_0057: v2 revision missing';
  ELSIF v_v2_status <> 'approved' THEN
    RAISE EXCEPTION 'CA_0057: v2 status is % (expected approved before pinning)', v_v2_status;
  END IF;

  -- Repin Season 2 v1 -> v2, idempotent.
  SELECT topic_revision_id INTO v_cur FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_cur = v_v2 THEN
    RAISE NOTICE 'CA_0057: Season 2 already pins v2; skipping pin.';
  ELSE
    PERFORM inform.admin_season_pin_revision(v_season2, v_topic, v_v2, v_actor);
    RAISE NOTICE 'CA_0057: Season 2 social-security repinned % -> % (v2)', v_cur, v_v2;
  END IF;
END $$;

-- =============================================================================
-- POST-VERIFY
-- =============================================================================
DO $$
DECLARE
  v_pin      uuid;
  v_v1_cur   boolean;
  v_v2_pub   timestamptz;
  v_open_ver int;
BEGIN
  -- Season 2 pins v2.
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND topic_id  = '87d20824-a6e9-407b-983c-65440084a0ab';
  IF v_pin <> '8defc029-0b7e-426f-b838-a2e170f566c9' THEN
    RAISE EXCEPTION 'CA_0057 verify: Season 2 pin is % (expected v2)', v_pin;
  END IF;

  -- v2 stays approved-not-published (pinning must not publish it).
  SELECT published_at INTO v_v2_pub FROM inform.compass_topic_revisions
   WHERE id = '8defc029-0b7e-426f-b838-a2e170f566c9';
  IF v_v2_pub IS NOT NULL THEN
    RAISE EXCEPTION 'CA_0057 verify: v2 has a published_at (must stay unpublished until S2 opens)';
  END IF;

  -- v1 is still current/published (untouched).
  SELECT is_current INTO v_v1_cur FROM inform.compass_topic_revisions
   WHERE id = 'a624f5d1-8aad-426b-bf46-b5788d8e620d';
  IF NOT v_v1_cur THEN RAISE EXCEPTION 'CA_0057 verify: v1 is no longer is_current'; END IF;

  -- Season 1 (open) still resolves version 1 for social-security.
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
  WHERE sq.topic_id = '87d20824-a6e9-407b-983c-65440084a0ab';
  IF v_open_ver IS NOT NULL AND v_open_ver <> 1 THEN
    RAISE EXCEPTION 'CA_0057 verify: open season resolves version % (expected 1)', v_open_ver;
  END IF;

  RAISE NOTICE 'CA_0057 post-verify OK: Season 2 pins v2 (approved, unpublished); Season 1 still serves v1.';
END $$;

COMMIT;
