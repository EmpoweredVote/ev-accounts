BEGIN;

-- =============================================================================
-- CA_0069: Medicare/aid (medicare/aid) — pin the already-approved v2 double-barrel
--          split into Season 2 (Season 2 is a draft; it is NOT opened here)
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
--
-- WHAT: one metadata step on the medicare/aid v2 rework
--   (topic cab61e8a-…, revision 3, version 2, change_class 'substantive', already
--    status='approved' — parked with no season pin):
--     1. REPIN Season 2's medicare/aid question from v1 (revision 92e96359-…) to v2
--        (revision ac7e986d-…).
--   No approve step is needed: the revision is already approved (2026-08-28). It stays
--   unpublished (is_current=false, published_at NULL) — a substantive rewrite goes live
--   only when its bound season opens, never by direct publish.
--   Season 2 (86d893a1-…) is a DRAFT and is NOT opened here.
--   This migration writes NO politician_answers / politician_context rows — see the
--   DEFERRED RE-AUDIT block below.
--
-- WHY THE PIN WAS MISSING. The v2 rework (rev 3) was approved 2026-08-28 and parked with
--   no season pin; the pin was intentionally deferred behind a re-audit. A season serves
--   its PINNED revision, so Season 2 kept pointing at v1 and showed the old wording.
--   Decision 2026-08-31 (Chris Andrews): pin v2 into Season 2 NOW, before the re-audit, so
--   the full Season 2 composition is visible; run the re-audit afterward, before Season 2
--   opens. This migration moves only the pin.
--
-- THE REWORK (rewording ruling 2026-08-28) — two double-barrel splits; chairs 1, 3, 5 are
--   byte-identical to v1 (their seats are untouched). rung_map = identity {1..5}:
--     Chair 2: "lower Medicare age to 55 AND expand Medicaid significantly" (two programs,
--       two votes) -> "significantly expand Medicare or Medicaid eligibility, stopping short
--       of universal coverage".
--     Chair 4: "partially privatize Medicare AND reduce Medicaid coverage" -> "scale back
--       both programs, shifting more coverage to private insurance".
--
-- ⚠⚠ DEFERRED RE-AUDIT — OWED BEFORE SEASON 2 OPENS ⚠⚠
--   Season 2 must NOT be opened on this revision until the reworded chairs are re-audited
--   against the new wording. The 247 rows seated on chair 4, plus the rows carried under the
--   chair-2 rewrite, were evidenced against the old two-part wording; under v2 they may assert
--   a position their evidence does not fully support. Current v1 seats: ch1 256 / ch2 333 /
--   ch3 290 / ch4 247 / ch5 19. Chairs 1, 3, 5 are unchanged, so no re-audit is owed on them.
--   No carry file exists yet. Run scripts/audit-chair-evidence.mjs on each re-audit migration.
--
-- WHY SAFE NOW: a season's pinned wording is served only for the OPEN season. Season 2 is
--   a draft, so this pin changes nothing a voter sees today; Season 1 (open) keeps serving
--   v1 via the version mechanic (it pins version 1; an approved version-2 revision does
--   not change what version 1 resolves to). No answer rows are touched.
--
-- Idempotent: re-running after success is a no-op (pin already equals v2).
-- =============================================================================

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
  v_topic    CONSTANT uuid := 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'; -- medicare/aid
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194'; -- Season 2 (draft)
  v_v1       CONSTANT uuid := '92e96359-57a9-4c7e-a78e-a6f1af105ec6'; -- v1 (rev1, published/current)
  v_v2       CONSTANT uuid := 'ac7e986d-f6df-484d-b36d-ebfb2da23df4'; -- v2 (rev3, substantive, approved)
  v_status   text;
  v_cur      uuid;
BEGIN
  -- Preconditions.
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_topic AND topic_key = 'medicare/aid') THEN
    RAISE EXCEPTION 'CA_0069: medicare/aid topic id mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = v_v2 AND topic_id = v_topic AND revision = 3 AND version = 2
                   AND change_class = 'substantive' AND status = 'approved') THEN
    RAISE EXCEPTION 'CA_0069: v2 revision missing/mismatched (expected rev3, version2, substantive, approved)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season2 AND number = 2 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0069: Season 2 is not a draft (pin would be frozen)';
  END IF;

  -- v2 carries five chairs.
  IF (SELECT count(*) FROM inform.compass_stance_revisions WHERE topic_revision_id = v_v2) <> 5 THEN
    RAISE EXCEPTION 'CA_0069: v2 does not carry exactly 5 chairs';
  END IF;

  -- Lock the pin to the reviewed wording: reworded chairs 2 and 4 carry the new text.
  IF NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions
                 WHERE topic_revision_id = v_v2 AND value = 2
                   AND text ILIKE '%expand Medicare or Medicaid eligibility%'
                   AND text NOT ILIKE '%age to 55%') THEN
    RAISE EXCEPTION 'CA_0069: chair-2 text is not the reviewed v2 wording';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions
                 WHERE topic_revision_id = v_v2 AND value = 4
                   AND text ILIKE '%scale back both programs%'
                   AND text ILIKE '%private insurance%') THEN
    RAISE EXCEPTION 'CA_0069: chair-4 text is not the reviewed v2 wording';
  END IF;

  -- Chairs 1, 3, 5 must be byte-identical to the live v1 revision (unchanged).
  IF EXISTS (
    SELECT 1
      FROM inform.compass_stance_revisions cur
      JOIN inform.compass_stance_revisions old
        ON old.value = cur.value AND old.topic_revision_id = v_v1
     WHERE cur.topic_revision_id = v_v2 AND cur.value IN (1, 3, 5) AND cur.text <> old.text) THEN
    RAISE EXCEPTION 'CA_0069: an unchanged chair (1/3/5) diverged from the live v1 text';
  END IF;

  -- Repin Season 2 v1 -> v2, idempotent.
  SELECT topic_revision_id INTO v_cur FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_cur IS NULL THEN
    RAISE EXCEPTION 'CA_0069: Season 2 has no medicare/aid question pin to move';
  ELSIF v_cur = v_v2 THEN
    RAISE NOTICE 'CA_0069: Season 2 already pins v2; skipping pin.';
  ELSE
    PERFORM inform.admin_season_pin_revision(v_season2, v_topic, v_v2, v_actor);
    RAISE NOTICE 'CA_0069: Season 2 medicare/aid repinned % -> % (v2)', v_cur, v_v2;
  END IF;

  -- v2 stays parked at approved/unpublished (no approve, no publish here).
  SELECT status INTO v_status FROM inform.compass_topic_revisions WHERE id = v_v2;
  IF v_status <> 'approved' THEN
    RAISE EXCEPTION 'CA_0069: v2 status changed to % (must stay approved)', v_status;
  END IF;
END $$;

-- =============================================================================
-- POST-VERIFY
-- =============================================================================
DO $$
DECLARE
  v_topic    CONSTANT uuid := 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_v1       CONSTANT uuid := '92e96359-57a9-4c7e-a78e-a6f1af105ec6';
  v_v2       CONSTANT uuid := 'ac7e986d-f6df-484d-b36d-ebfb2da23df4';
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
  -- Revision count for the topic is unchanged at 3 (pin adds no revision).
  SELECT count(*) INTO v_nrev FROM inform.compass_topic_revisions WHERE topic_id = v_topic;
  IF v_nrev <> 3 THEN RAISE EXCEPTION 'CA_0069 verify: expected 3 revisions for topic, found %', v_nrev; END IF;

  -- v2 is approved, NOT published, NOT current.
  SELECT status, published_at, is_current INTO v_status, v_pub, v_iscur
    FROM inform.compass_topic_revisions WHERE id = v_v2;
  IF v_status <> 'approved' THEN RAISE EXCEPTION 'CA_0069 verify: v2 status is % (expected approved)', v_status; END IF;
  IF v_pub IS NOT NULL THEN RAISE EXCEPTION 'CA_0069 verify: v2 has a published_at (must stay unpublished)'; END IF;
  IF v_iscur THEN RAISE EXCEPTION 'CA_0069 verify: v2 is_current is true (must stay false until Season 2 opens)'; END IF;

  -- v1 is still the current/published revision (untouched).
  SELECT is_current, status INTO v_v1_cur, v_v1_stat
    FROM inform.compass_topic_revisions WHERE id = v_v1;
  IF NOT v_v1_cur THEN RAISE EXCEPTION 'CA_0069 verify: v1 is no longer is_current'; END IF;
  IF v_v1_stat <> 'published' THEN RAISE EXCEPTION 'CA_0069 verify: v1 status is % (expected published)', v_v1_stat; END IF;

  -- Exactly one published/current revision for the topic (still v1).
  IF (SELECT count(*) FROM inform.compass_topic_revisions
       WHERE topic_id = v_topic AND is_current = true AND status = 'published') <> 1 THEN
    RAISE EXCEPTION 'CA_0069 verify: expected exactly 1 published/current revision';
  END IF;

  -- Season 2 pins v2 (the new revision).
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_pin <> v_v2 THEN
    RAISE EXCEPTION 'CA_0069 verify: Season 2 pin is % (expected v2)', v_pin;
  END IF;

  -- The reworded chairs (2/4) on the pinned S2 revision carry NEW text, not the old.
  SELECT count(*) INTO v_bad
    FROM inform.compass_stance_revisions cur
    JOIN inform.compass_stance_revisions old ON old.value = cur.value AND old.topic_revision_id = v_v1
   WHERE cur.topic_revision_id = v_v2 AND cur.value IN (2, 4) AND cur.text = old.text;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CA_0069 verify: % reworded chair(s) still match the old v1 text', v_bad;
  END IF;

  -- Unchanged chairs (1/3/5) on the pinned S2 revision are byte-identical to v1.
  SELECT count(*) INTO v_bad
    FROM inform.compass_stance_revisions cur
    JOIN inform.compass_stance_revisions old ON old.value = cur.value AND old.topic_revision_id = v_v1
   WHERE cur.topic_revision_id = v_v2 AND cur.value IN (1, 3, 5) AND cur.text <> old.text;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CA_0069 verify: an unchanged chair (1/3/5) diverged from the v1 text';
  END IF;

  -- Season 1 (open) still resolves version 1 for medicare/aid.
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
    RAISE EXCEPTION 'CA_0069 verify: open season resolves version % (expected 1)', v_open_ver;
  END IF;

  RAISE NOTICE 'CA_0069 post-verify OK: Season 2 pins medicare/aid v2 (approved, unpublished); Season 1 still serves v1. Chairs 2/4 re-audit deferred (247 chair-4 rows + carried chair-2 rows) before Season 2 opens.';
END $$;

COMMIT;
