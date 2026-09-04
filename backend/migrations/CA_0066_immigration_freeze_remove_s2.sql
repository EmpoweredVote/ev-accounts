BEGIN;

-- =============================================================================
-- CA_0066: Immigration — freeze the v2 rework and drop the topic from Season 2
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2,
--   candrews@empowered.vote).
--
-- WHAT: two metadata steps on the national `immigration` topic
--   (id 4e2c69ce-…), leaving Season 1 and all seated answers untouched:
--     1. REMOVE immigration from the Season 2 draft's question set (was q17,
--        pinned to v1 revision 688b8adc-…).
--     2. REJECT the open v2 draft (revision 530f35cd-…, version 2, 'substantive',
--        status 'draft') with a recorded reason.
--   Season 1 (2d5d67d1-…, OPEN) is NOT touched: immigration stays live there as
--   q17 on v1/rev1. The 1678 Season-1 politician_answers are NOT touched.
--   Season 2 (86d893a1-…) is a DRAFT and is NOT opened here.
--
-- WHY (decision 2026-08-31, Chris Andrews). The immigration cluster is already four
--   topics, and three of them own the salient dimensions in Season 2:
--     · deportation      (S2 q9)  — removal of the undocumented already here
--     · border-security  (S2 q46) — the border / asylum
--     · local-immigration(S2 q28) — local police vs ICE cooperation
--   The broad `immigration` topic overlapped deportation by 72% (1212 of its 1678
--   seated politicians are also seated on deportation), and its own evidence is 65%
--   about the undocumented — i.e. deportation's axis, not a distinct one. Running it
--   in Season 2 alongside those three would ask voters a near-duplicate question.
--
--   The abandoned v2 draft tried to fix immigration's double-barrels by collapsing the
--   ladder to a pure legal-admission dial ("much/modestly easier … stop most legal
--   immigration"). Admission volume is the ONE dimension no sibling owns, but it is
--   also the least-cited (14% of immigration's evidence), and a bare volume dial reads
--   wrong and amputates the services dimension. Rather than rush a rev-3 re-scope plus a
--   heavy re-audit (re-seating ~1200 rows that rest on deportation-flavoured evidence)
--   before Season 2 opens, the decision is to NOT carry immigration into Season 2 now.
--   A proper "legal front door" rebuild (admission + treatment of legal/prospective
--   immigrants) can be authored fresh later if that dimension is wanted back.
--
-- WHY SAFE: removing a topic from a DRAFT season only edits that season's question set;
--   answers live on Season 1 and are untouched. Rejecting a draft revision cannot affect
--   the live v1/rev1 that Season 1 serves. No voter-visible change in Season 1.
--
-- Idempotent: re-running after success is a no-op (topic already absent from S2; v2
--   already rejected).
-- =============================================================================

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2'; -- Chris Andrews
  v_topic    CONSTANT uuid := '4e2c69ce-591e-4197-9cd5-7aceff79d390'; -- immigration
  v_season1  CONSTANT uuid := '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'; -- Season 1 (open)
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194'; -- Season 2 (draft)
  v_v1       CONSTANT uuid := '688b8adc-3832-4edb-b227-1fdb238e3c49'; -- v1/rev1 (live)
  v_v2       CONSTANT uuid := '530f35cd-c990-4563-878e-86f03ea154de'; -- v2/rev2 (draft to reject)
  v_reason   CONSTANT text :=
    'Immigration v2 double-barrel rework abandoned. The admission-only dial mis-scopes the '
    || 'topic, and Season 2 already carries deportation (q9), border-security (q46) and '
    || 'local-immigration (q28), which own removal, the border and local enforcement; '
    || 'immigration overlapped deportation 72% (1212/1678 seated). Decision 2026-08-31 '
    || '(Chris Andrews): remove immigration from Season 2, keep it live in Season 1 on v1, '
    || 'reject this draft. A legal-front-door rebuild can be authored fresh later.';
  v_status   text;
  v_present  int;
BEGIN
  -- Preconditions.
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_topic AND topic_key = 'immigration') THEN
    RAISE EXCEPTION 'CA_0066: immigration topic id mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = v_v2 AND topic_id = v_topic AND revision = 2 AND version = 2
                   AND change_class = 'substantive') THEN
    RAISE EXCEPTION 'CA_0066: v2 substantive draft missing/mismatched';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season2 AND number = 2 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0066: Season 2 is not a draft (its question set would be frozen)';
  END IF;

  -- Step 1: remove immigration from the Season 2 draft, idempotent.
  SELECT count(*) INTO v_present FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_present > 0 THEN
    PERFORM inform.admin_season_remove_topic(v_season2, v_topic, v_actor);
    RAISE NOTICE 'CA_0066: immigration removed from Season 2.';
  ELSE
    RAISE NOTICE 'CA_0066: immigration already absent from Season 2; skipping remove.';
  END IF;

  -- Step 2: reject the v2 draft, idempotent (the RPC errors if already decided).
  SELECT status INTO v_status FROM inform.compass_topic_revisions WHERE id = v_v2;
  IF v_status IN ('draft','approved') THEN
    PERFORM inform.admin_reject_topic_revision(v_v2, v_actor, v_reason);
    RAISE NOTICE 'CA_0066: v2 rejected (% -> rejected).', v_status;
  ELSIF v_status = 'rejected' THEN
    RAISE NOTICE 'CA_0066: v2 already rejected; skipping reject.';
  ELSE
    RAISE EXCEPTION 'CA_0066: v2 in unexpected status % (expected draft/approved/rejected)', v_status;
  END IF;
END $$;

-- =============================================================================
-- POST-VERIFY
-- =============================================================================
DO $$
DECLARE
  v_topic    CONSTANT uuid := '4e2c69ce-591e-4197-9cd5-7aceff79d390';
  v_season1  CONSTANT uuid := '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_v1       CONSTANT uuid := '688b8adc-3832-4edb-b227-1fdb238e3c49';
  v_v2       CONSTANT uuid := '530f35cd-c990-4563-878e-86f03ea154de';
  v_status   text;
  v_ref      text;
  v_v1_cur   boolean;
  v_v1_stat  text;
  v_s1_pin   uuid;
  v_answers  bigint;
  v_cluster  text;
BEGIN
  -- immigration is gone from Season 2.
  IF EXISTS (SELECT 1 FROM inform.season_questions WHERE season_id = v_season2 AND topic_id = v_topic) THEN
    RAISE EXCEPTION 'CA_0066 verify: immigration is still pinned in Season 2';
  END IF;

  -- The other three cluster topics remain in Season 2 (untouched).
  SELECT string_agg(t.topic_key, ',' ORDER BY t.topic_key) INTO v_cluster
    FROM inform.season_questions sq JOIN inform.compass_topics t ON t.id = sq.topic_id
   WHERE sq.season_id = v_season2 AND t.topic_key IN ('deportation','border-security','local-immigration');
  IF v_cluster IS DISTINCT FROM 'border-security,deportation,local-immigration' THEN
    RAISE EXCEPTION 'CA_0066 verify: Season 2 cluster is "%" (expected the other three intact)', v_cluster;
  END IF;

  -- v2 is rejected, with the reason recorded, still unpublished / not current.
  SELECT status, review_ref INTO v_status, v_ref FROM inform.compass_topic_revisions WHERE id = v_v2;
  IF v_status <> 'rejected' THEN RAISE EXCEPTION 'CA_0066 verify: v2 status is % (expected rejected)', v_status; END IF;
  IF v_ref NOT ILIKE '%REJECTED:%' THEN RAISE EXCEPTION 'CA_0066 verify: v2 rejection reason not recorded'; END IF;
  IF EXISTS (SELECT 1 FROM inform.compass_topic_revisions WHERE id = v_v2 AND (is_current OR published_at IS NOT NULL)) THEN
    RAISE EXCEPTION 'CA_0066 verify: v2 is current/published (must be neither)';
  END IF;

  -- v1 is untouched: still the current/published revision.
  SELECT is_current, status INTO v_v1_cur, v_v1_stat FROM inform.compass_topic_revisions WHERE id = v_v1;
  IF NOT v_v1_cur THEN RAISE EXCEPTION 'CA_0066 verify: v1 is no longer is_current'; END IF;
  IF v_v1_stat <> 'published' THEN RAISE EXCEPTION 'CA_0066 verify: v1 status is % (expected published)', v_v1_stat; END IF;
  IF (SELECT count(*) FROM inform.compass_topic_revisions
       WHERE topic_id = v_topic AND is_current = true AND status = 'published') <> 1 THEN
    RAISE EXCEPTION 'CA_0066 verify: expected exactly 1 published/current immigration revision';
  END IF;

  -- Season 1 (open) still carries immigration, still pinned to v1.
  SELECT topic_revision_id INTO v_s1_pin FROM inform.season_questions
   WHERE season_id = v_season1 AND topic_id = v_topic;
  IF v_s1_pin IS NULL THEN RAISE EXCEPTION 'CA_0066 verify: immigration was dropped from Season 1 (must stay)'; END IF;
  IF v_s1_pin <> v_v1 THEN RAISE EXCEPTION 'CA_0066 verify: Season 1 pin is % (expected v1 %)', v_s1_pin, v_v1; END IF;

  -- No seated answers were touched.
  SELECT count(*) INTO v_answers FROM inform.politician_answers
   WHERE topic_id = v_topic AND value IS NOT NULL AND value <> 0;
  IF v_answers <> 1678 THEN RAISE EXCEPTION 'CA_0066 verify: seated answer count is % (expected 1678 untouched)', v_answers; END IF;

  RAISE NOTICE 'CA_0066 post-verify OK: immigration removed from Season 2; v2 rejected; Season 1 keeps immigration on v1; 1678 answers untouched.';
END $$;

COMMIT;
