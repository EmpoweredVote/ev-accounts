BEGIN;

-- =============================================================================
-- CA_0054: Social Security — approve v2 (draft -> approved); NOT published, NOT pinned
-- =============================================================================
-- Created 2026-08-30 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2,
-- candrews@empowered.vote).
--
-- WHAT: approve the social-security v2 de-barrel (revision 8defc029, version 2). It moves
--   draft -> approved. It is NOT published and NOT pinned to any season here.
--
-- WHAT v2 CHANGES: only chair 4. Chairs 1, 2, 3 and 5 are byte-identical to v1.
--     v1 chair 4: "gradually raise the retirement age and reduce benefits for higher
--                  earners to save Social Security."
--     v2 chair 4: "gradually reduce future benefits rather than raise taxes to keep
--                  Social Security solvent."
--
-- WHY MAJOR (substantive), not minor: the reword is not a clean de-barrel. It makes three
--   meaning shifts, and the third changes chair membership:
--     1. drops the "raise the retirement age" mechanism;
--     2. drops "for higher earners" (means-testing) — now an across-the-board cut;
--     3. ADDS "rather than raise taxes" — a policy commitment (opposition to tax rises)
--        the v1 wording never required.
--   A person seated on v1 for raising the retirement age who also accepts lifting the
--   payroll-tax cap fits v1 chair 4 but NOT v2 chair 4. So the reword changes the sourced
--   claim each seated row carries. That is substantive -> it goes live only when its bound
--   season opens, never by a direct publish. Matches the corpus de-barrel precedent
--   (Religious Freedom, Childcare, Housing, Campaign Finance, City Sanitation).
--
-- PENDING (NOT in this migration): 98 rows sit in chair 4. They were seated on the v1
--   wording and MUST be re-audited against the v2 wording (esp. the new "rather than raise
--   taxes" clause) BEFORE v2 is pinned into Season 2. This migration only approves; the
--   re-audit and the Season 2 pin are separate follow-ups.
--
-- WHY SAFE NOW: approve does not set is_current and does not set published_at. v1 stays the
--   current/published revision and keeps serving on every voter surface. No
--   politician_answers / politician_context writes. Idempotent: re-running after success is
--   a no-op (v2 already approved).
-- =============================================================================

DO $$
DECLARE
  v_actor  CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
  v_topic  CONSTANT uuid := '87d20824-a6e9-407b-983c-65440084a0ab'; -- social-security
  v_v2     CONSTANT uuid := '8defc029-0b7e-426f-b838-a2e170f566c9'; -- v2 (rev2)
  v_status text;
BEGIN
  -- Preconditions
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_topic AND topic_key = 'social-security') THEN
    RAISE EXCEPTION 'CA_0054: social-security topic id mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = v_v2 AND topic_id = v_topic AND revision = 2 AND version = 2) THEN
    RAISE EXCEPTION 'CA_0054: v2 revision missing';
  END IF;

  -- Approve v2 (draft -> approved), idempotent.
  SELECT status INTO v_status FROM inform.compass_topic_revisions WHERE id = v_v2;
  IF v_status = 'draft' THEN
    PERFORM inform.admin_approve_topic_revision(v_v2, v_actor);
    RAISE NOTICE 'CA_0054: v2 approved (draft -> approved), not published.';
  ELSIF v_status = 'approved' THEN
    RAISE NOTICE 'CA_0054: v2 already approved; skipping approve.';
  ELSE
    RAISE EXCEPTION 'CA_0054: v2 in unexpected status % (expected draft or approved)', v_status;
  END IF;
END $$;

-- =============================================================================
-- POST-VERIFY
-- =============================================================================
DO $$
DECLARE
  v_status text;
  v_pub    timestamptz;
  v_iscur  boolean;
  v_v1_cur boolean;
BEGIN
  -- v2 is approved, NOT published, NOT current.
  SELECT status, published_at, is_current INTO v_status, v_pub, v_iscur
    FROM inform.compass_topic_revisions WHERE id = '8defc029-0b7e-426f-b838-a2e170f566c9';
  IF v_status <> 'approved' THEN RAISE EXCEPTION 'CA_0054 verify: v2 status is % (expected approved)', v_status; END IF;
  IF v_pub IS NOT NULL THEN RAISE EXCEPTION 'CA_0054 verify: v2 has a published_at (must stay unpublished)'; END IF;
  IF v_iscur THEN RAISE EXCEPTION 'CA_0054 verify: v2 is_current is true (must stay false until the season opens)'; END IF;

  -- v1 is still the current/published revision (untouched by approve).
  SELECT is_current INTO v_v1_cur FROM inform.compass_topic_revisions WHERE id = 'a624f5d1-8aad-426b-bf46-b5788d8e620d';
  IF NOT v_v1_cur THEN RAISE EXCEPTION 'CA_0054 verify: v1 is no longer is_current'; END IF;

  RAISE NOTICE 'CA_0054 post-verify OK: v2 approved (unpublished, not current); v1 still current.';
END $$;

COMMIT;
