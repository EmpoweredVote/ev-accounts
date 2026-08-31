BEGIN;

-- =============================================================================
-- CA_0065: AI Oversight (ai-regulation) — approve the v2 rework and pin it into
--          Season 2 (Season 2 is a draft; it is NOT opened here)
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
--
-- WHAT: two metadata steps on the ai-regulation v2 rework
--   (topic 666bf03d-…, revision c594dc06-…, version 2, change_class 'substantive'):
--     1. APPROVE it (draft -> approved). NOT published: a substantive/major rewrite goes
--        live only when its bound season opens, never by a direct publish, so is_current
--        stays false and published_at stays NULL.
--     2. REPIN Season 2's ai-regulation question from v1 (revision 58804871-…) to v2.
--   Season 2 (86d893a1-…) is a DRAFT and is NOT opened here.
--   This migration writes NO politician_answers / politician_context rows — see the
--   DEFERRED RE-AUDIT block below.
--
-- THE REWORK (reviewed 2026-08-31, Chris Andrews) — a triple double-barrel split.
--   Chairs 1 and 2 are byte-identical to v1; chairs 3, 4 and 5 each drop a barrel.
--   For AI Oversight the axis runs the reversed way (chair 1 = minimum government
--   action, chair 5 = maximum), so the ladder still ascends in stringency 1->5.
--     Chair 3 (269 seated): "Require AI developers to DISCLOSE RISKS AND be held
--       responsible when their systems cause harm" -> "Hold AI developers LEGALLY
--       responsible when their systems cause harm". Drops the risk-disclosure barrel;
--       keeps liability.
--     Chair 4 (186 seated): "Require safety testing AND BAN HIGH-RISK AI USES in areas
--       like hiring, healthcare, and policing" -> "Require safety testing BEFORE AI CAN
--       BE USED in high-stakes areas like hiring, healthcare, and policing". Drops the
--       use-ban barrel; keeps testing, reframed as a pre-use gate.
--     Chair 5 (7 seated): "Impose strict approval requirements AND BAN AI SYSTEMS that
--       could cause serious harm" -> "Impose strict government approval requirements
--       BEFORE ANY AI SYSTEM can be deployed". Drops the targeted-ban barrel and narrows
--       strict approval into a universal pre-approval regime.
--
-- WHY THIS IS A MAJOR (not a minor clarify).  Unlike the local-immigration / healthcare
--   reclassifies — where the dropped clause was an off-axis limb or an echo of the old
--   wording that carried no seating weight — the barrels dropped here are ON-AXIS
--   discriminating positions, and seated rows demonstrably rest on them:
--     - Chair 3: of 269 rows, 30 are seated on disclosure/transparency evidence with NO
--       liability position (e.g. Avila Farias, Valencia, Buffy Wicks on the CA AI
--       Transparency Act). v2 chair 3 drops disclosure entirely, so their evidence no
--       longer matches the chair.
--     - Chair 4: of 186 rows, 36 are seated on targeted use-ban evidence with NO testing
--       position (e.g. Schiff, Fontes, Padilla on deepfake / high-risk-use bans). v2
--       chair 4 drops bans, and there is no ban chair left to move them to.
--     - Chair 5: of 7 rows, at least 2-3 rest on targeted bans / moratoria (AOC — data
--       center moratorium; Bartlett — rent-algorithm ban) rather than universal
--       pre-approval.
--   Seated rows were evidenced against wording that no longer exists, so a re-audit is
--   owed. The revision therefore stays 'substantive' and is NOT published — it is only
--   staged for Season 2 (approve + pin), exactly like CA_0063 (homelessness) and CA_0057
--   (social-security).
--
-- ⚠⚠ DEFERRED RE-AUDIT — OWED BEFORE SEASON 2 OPENS ⚠⚠
--   Season 2 must NOT be opened on this revision until the reworded chairs are re-audited
--   against the new wording. Re-audit universe = the 462 rows on chairs 3/4/5 (269 + 186
--   + 7), the draft's own self-flag; the firm dropped-barrel floor is ~68 (30 + 36 + ~2).
--   Chairs 1 and 2 are unchanged, so no re-audit is owed on them. Opening Season 2 before
--   that re-audit would let those rows assert positions their evidence contradicts.
--   The same re-audit pass should re-author the per-stance description and
--   example_perspectives that the v2 draft blanked (v1 carried a description + 3 example
--   perspectives per chair; the old prose was written for the old double-barrelled
--   wording and is deliberately left blank here rather than restored onto reworked
--   chairs — all three fields are dormant/unread today).
--
-- WHY SAFE NOW: a season's pinned wording is served only for the OPEN season. Season 2 is
--   a draft, so this pin changes nothing a voter sees today; Season 1 (open) keeps serving
--   v1r1 via the version mechanic (it pins version 1; approving a version-2 revision does
--   not change what version 1 resolves to). No answer rows are touched.
--
-- Idempotent: re-running after success is a no-op (v2 already approved; pin already equals v2).
-- =============================================================================

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
  v_topic    CONSTANT uuid := '666bf03d-81fc-4138-ab15-69ae734c9023'; -- ai-regulation (AI Oversight)
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194'; -- Season 2 (draft)
  v_v1       CONSTANT uuid := '58804871-b768-4d4a-85b5-07c92eb40bc7'; -- v1 (rev1, published/current)
  v_v2       CONSTANT uuid := 'c594dc06-0c70-4707-8ae0-d4bc760172db'; -- v2 (rev2, substantive draft)
  v_status   text;
  v_cur      uuid;
BEGIN
  -- Preconditions.
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_topic AND topic_key = 'ai-regulation') THEN
    RAISE EXCEPTION 'CA_0065: ai-regulation topic id mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = v_v2 AND topic_id = v_topic AND revision = 2 AND version = 2
                   AND change_class = 'substantive') THEN
    RAISE EXCEPTION 'CA_0065: v2 substantive revision missing/mismatched';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season2 AND number = 2 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0065: Season 2 is not a draft (pin would be frozen)';
  END IF;

  -- Lock the pin to the exact reviewed wording: guard against pinning a wrong/edited revision.
  -- Chair 3: reworded to liability-only (dropped "disclose risks").
  IF NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions
                 WHERE topic_revision_id = v_v2 AND value = 3
                   AND text ILIKE '%legally responsible%' AND text NOT ILIKE '%disclose%') THEN
    RAISE EXCEPTION 'CA_0065: chair-3 text is not the reviewed liability-only wording';
  END IF;
  -- Chair 4: reworded to testing-gate (dropped "ban high-risk AI uses").
  IF NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions
                 WHERE topic_revision_id = v_v2 AND value = 4
                   AND text ILIKE '%before AI can be used%' AND text NOT ILIKE '%ban%') THEN
    RAISE EXCEPTION 'CA_0065: chair-4 text is not the reviewed testing-gate wording';
  END IF;
  -- Chair 5: reworded to universal pre-approval (dropped "ban AI systems").
  IF NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions
                 WHERE topic_revision_id = v_v2 AND value = 5
                   AND text ILIKE '%before any AI system can be deployed%' AND text NOT ILIKE '%ban%') THEN
    RAISE EXCEPTION 'CA_0065: chair-5 text is not the reviewed universal-pre-approval wording';
  END IF;
  -- Chairs 1 and 2 must be byte-identical to the live v1 revision.
  IF EXISTS (
    SELECT 1
      FROM inform.compass_stance_revisions cur
      JOIN inform.compass_stance_revisions old
        ON old.value = cur.value AND old.topic_revision_id = v_v1
     WHERE cur.topic_revision_id = v_v2 AND cur.value IN (1, 2) AND cur.text <> old.text) THEN
    RAISE EXCEPTION 'CA_0065: an unchanged chair (1/2) diverged from the live v1 text';
  END IF;

  -- Step 1: approve v2 (draft -> approved), idempotent. NOT published.
  SELECT status INTO v_status FROM inform.compass_topic_revisions WHERE id = v_v2;
  IF v_status = 'draft' THEN
    PERFORM inform.admin_approve_topic_revision(v_v2, v_actor);
    RAISE NOTICE 'CA_0065: v2 approved (draft -> approved), not published.';
  ELSIF v_status = 'approved' THEN
    RAISE NOTICE 'CA_0065: v2 already approved; skipping approve.';
  ELSE
    RAISE EXCEPTION 'CA_0065: v2 in unexpected status % (expected draft or approved)', v_status;
  END IF;

  -- Step 2: repin Season 2 v1 -> v2, idempotent.
  SELECT topic_revision_id INTO v_cur FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_cur = v_v2 THEN
    RAISE NOTICE 'CA_0065: Season 2 already pins v2; skipping pin.';
  ELSE
    PERFORM inform.admin_season_pin_revision(v_season2, v_topic, v_v2, v_actor);
    RAISE NOTICE 'CA_0065: Season 2 ai-regulation repinned % -> % (v2)', v_cur, v_v2;
  END IF;
END $$;

-- =============================================================================
-- POST-VERIFY
-- =============================================================================
DO $$
DECLARE
  v_topic    CONSTANT uuid := '666bf03d-81fc-4138-ab15-69ae734c9023';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_v1       CONSTANT uuid := '58804871-b768-4d4a-85b5-07c92eb40bc7';
  v_v2       CONSTANT uuid := 'c594dc06-0c70-4707-8ae0-d4bc760172db';
  v_status   text;
  v_pub      timestamptz;
  v_iscur    boolean;
  v_v1_cur   boolean;
  v_v1_stat  text;
  v_pin      uuid;
  v_nrev     int;
  v_open_ver int;
  v_bad      int;
BEGIN
  -- Revision count for the topic is unchanged at 2 (approve adds no revision).
  SELECT count(*) INTO v_nrev FROM inform.compass_topic_revisions WHERE topic_id = v_topic;
  IF v_nrev <> 2 THEN RAISE EXCEPTION 'CA_0065 verify: expected 2 revisions for topic, found %', v_nrev; END IF;

  -- v2 is approved, NOT published, NOT current.
  SELECT status, published_at, is_current INTO v_status, v_pub, v_iscur
    FROM inform.compass_topic_revisions WHERE id = v_v2;
  IF v_status <> 'approved' THEN RAISE EXCEPTION 'CA_0065 verify: v2 status is % (expected approved)', v_status; END IF;
  IF v_pub IS NOT NULL THEN RAISE EXCEPTION 'CA_0065 verify: v2 has a published_at (must stay unpublished)'; END IF;
  IF v_iscur THEN RAISE EXCEPTION 'CA_0065 verify: v2 is_current is true (must stay false until Season 2 opens)'; END IF;

  -- v1 is still the current/published revision (untouched by approve).
  SELECT is_current, status INTO v_v1_cur, v_v1_stat
    FROM inform.compass_topic_revisions WHERE id = v_v1;
  IF NOT v_v1_cur THEN RAISE EXCEPTION 'CA_0065 verify: v1 is no longer is_current'; END IF;
  IF v_v1_stat <> 'published' THEN RAISE EXCEPTION 'CA_0065 verify: v1 status is % (expected published)', v_v1_stat; END IF;

  -- Exactly one published/current revision for the topic (still v1).
  IF (SELECT count(*) FROM inform.compass_topic_revisions
       WHERE topic_id = v_topic AND is_current = true AND status = 'published') <> 1 THEN
    RAISE EXCEPTION 'CA_0065 verify: expected exactly 1 published/current revision';
  END IF;

  -- Season 2 pins v2 (the new revision).
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_pin <> v_v2 THEN
    RAISE EXCEPTION 'CA_0065 verify: Season 2 pin is % (expected v2)', v_pin;
  END IF;

  -- The reworded chairs (3/4/5) on the pinned S2 revision carry the NEW text and not the old.
  SELECT count(*) INTO v_bad
    FROM inform.compass_stance_revisions cur
    JOIN inform.compass_stance_revisions old ON old.value = cur.value AND old.topic_revision_id = v_v1
   WHERE cur.topic_revision_id = v_v2 AND cur.value IN (3, 4, 5) AND cur.text = old.text;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CA_0065 verify: % reworded chair(s) still match the old v1 text', v_bad;
  END IF;
  IF EXISTS (SELECT 1 FROM inform.compass_stance_revisions
             WHERE topic_revision_id = v_v2 AND value = 3 AND text ILIKE '%disclose%') THEN
    RAISE EXCEPTION 'CA_0065 verify: chair-3 still carries the dropped disclose-risks barrel';
  END IF;
  IF EXISTS (SELECT 1 FROM inform.compass_stance_revisions
             WHERE topic_revision_id = v_v2 AND value IN (4, 5) AND text ILIKE '%ban%') THEN
    RAISE EXCEPTION 'CA_0065 verify: chair-4/5 still carries a dropped ban barrel';
  END IF;

  -- Unchanged chairs (1/2) on the pinned S2 revision are byte-identical to v1.
  SELECT count(*) INTO v_bad
    FROM inform.compass_stance_revisions cur
    JOIN inform.compass_stance_revisions old ON old.value = cur.value AND old.topic_revision_id = v_v1
   WHERE cur.topic_revision_id = v_v2 AND cur.value IN (1, 2) AND cur.text <> old.text;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CA_0065 verify: an unchanged chair (1/2) diverged from the v1 text';
  END IF;

  -- Season 1 (open) still resolves version 1 for ai-regulation.
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
  WHERE sq.topic_id = v_topic;
  IF v_open_ver IS NOT NULL AND v_open_ver <> 1 THEN
    RAISE EXCEPTION 'CA_0065 verify: open season resolves version % (expected 1)', v_open_ver;
  END IF;

  RAISE NOTICE 'CA_0065 post-verify OK: v2 approved (unpublished); Season 2 pins v2; Season 1 still serves v1. Chairs 3/4/5 re-audit deferred (462 rows).';
END $$;

COMMIT;
