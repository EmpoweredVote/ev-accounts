BEGIN;

-- =============================================================================
-- CA_0063: Homelessness — approve the v2 rework and pin it into Season 2
--          (Season 2 is a draft; it is NOT opened here)
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
--
-- WHAT: two metadata steps on the homelessness v2 de-barrel rework
--   (topic 4938766b-…, revision 6958fa99-…, version 2, change_class 'substantive'):
--     1. APPROVE it (draft -> approved). NOT published: a substantive/major rewrite goes
--        live only when its bound season opens, never by a direct publish, so is_current
--        stays false and published_at stays NULL.
--     2. REPIN Season 2's homelessness question from v1 (revision bab0fb79-…) to v2.
--   Season 2 (86d893a1-…) is a DRAFT and is NOT opened here.
--   This migration writes NO politician_answers / politician_context rows — see the
--   DEFERRED RE-AUDIT block below.
--
-- THE REWORK (reviewed 2026-08-31, Chris Andrews) — chairs 1, 2, 4, 5 reworded; chair 3
--   byte-identical. All four edits drop a trailing barrel; three are clean widenings, one
--   (chair 4) also narrows:
--     Chair 1 (34 seated): drop "redirecting enforcement budgets…"; add "and shelter" and
--       "with no penalties of any kind".  Widen + confirmatory-at-the-pole. No seat invalidated.
--     Chair 2 (291 seated): drop "while investing in shelter capacity, outreach workers, and
--       voluntary service connections"; add "and camping in public spaces". The surviving
--       clause "decriminalizing public sleeping" is present in BOTH wordings, so the drop only
--       relaxes an extra requirement — it widens the chair. No seat invalidated.
--     Chair 3 (164 seated): unchanged.
--     Chair 4 (123 seated): drop "while requiring jurisdictions to maintain basic shelter
--       options" (widen) AND narrow "graduated warnings and penalties" -> "graduated warnings
--       and CIVIL penalties".  ⚠ The "civil" qualifier moves the chair-4/chair-5 boundary onto
--       penalty TYPE. Under v1 the 4/5 line bundled penalty severity AND services, and seaters
--       resolved criminal-penalty bans to chair 4 when they were graduated and shelter-paired.
--       ~19 of the 123 chair-4 rows carry criminal-flavoured evidence, and ~10 are clear
--       criminal-mechanism camping bans (Abbott — Class C misdemeanor; Hall — HB505 misdemeanor;
--       Kimberlin — fines + jail; Yang Shao — $1,000 + 6 months jail; Stewart — criminal
--       enforcement; Mahan/Mattucci/Chen/Hochman — arrest on refusal; Hoover — AB-257 criminal
--       penalties) that now point to chair 5.  These are the rows the deferred re-audit owes.
--     Chair 5 (27 seated): drop "relying on existing social services for those who seek help".
--       All 27 rest on the criminal-ban posture (the dropped clause is off-axis). Widen. No
--       seat invalidated.
--
-- WHY THIS IS A MAJOR (not a minor clarify).  The chair-4 narrowing re-sorts real seated rows
--   across the 4/5 boundary: their evidence (criminal misdemeanor/jail) was gathered against
--   chair-4 wording ("penalties", unqualified) that no longer exists. That is the re-audit
--   trigger from the 2026-08-28 rewording ruling, so the revision stays 'substantive' and is
--   NOT published — it is only staged for Season 2 (approve + pin), exactly like CA_0046.
--
-- ⚠⚠ DEFERRED RE-AUDIT — OWED BEFORE SEASON 2 OPENS ⚠⚠
--   Season 2 must NOT be opened on this revision until the chair-4 rows are re-audited against
--   the new "civil penalties" wording and the criminal-mechanism bans (~10 firm, ~19 to review
--   of the 123 chair-4 rows) are moved to chair 5. Chairs 1, 2 and 5 are clean widenings and
--   chair 3 is unchanged, so NO re-audit is owed on them (the draft's own self-flag of 475 rows
--   over-counts — the real debt is the chair-4 subset). Opening Season 2 before that re-audit
--   would let those rows assert a "civil penalties" position their evidence contradicts.
--   The same re-audit pass should re-author the per-stance description and example_perspectives
--   that the v2 draft blanked (v1 carried a description + 3 example_perspectives per chair; the
--   old prose was written for the old double-barrelled wording and is deliberately left blank
--   here rather than restored onto reworked chairs — all three fields are dormant/unread today).
--
-- WHY SAFE NOW: a season's pinned wording is served only for the OPEN season. Season 2 is a
--   draft, so this pin changes nothing a voter sees today; Season 1 (open) keeps serving v1r1
--   via the version mechanic (it pins version 1; publishing/approving a version-2 revision does
--   not change what version 1 resolves to). No answer rows are touched.
--
-- Idempotent: re-running after success is a no-op (v2 already approved; pin already equals v2).
-- =============================================================================

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
  v_topic    CONSTANT uuid := '4938766b-b45a-46e3-93bd-b8b30651271a'; -- homelessness
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194'; -- Season 2 (draft)
  v_v2       CONSTANT uuid := '6958fa99-e317-45d7-8076-d11a0a78c897'; -- v2 (rev2, substantive)
  v_status   text;
  v_cur      uuid;
BEGIN
  -- Preconditions.
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_topic AND topic_key = 'homelessness') THEN
    RAISE EXCEPTION 'CA_0063: homelessness topic id mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = v_v2 AND topic_id = v_topic AND revision = 2 AND version = 2
                   AND change_class = 'substantive') THEN
    RAISE EXCEPTION 'CA_0063: v2 substantive revision missing/mismatched';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season2 AND number = 2 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0063: Season 2 is not a draft (pin would be frozen)';
  END IF;

  -- Lock the pin to the exact reviewed wording: guard against pinning a wrong/edited revision.
  IF NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions
                 WHERE topic_revision_id = v_v2 AND value = 4
                   AND text ILIKE '%civil penalties%' AND text NOT ILIKE '%shelter options%') THEN
    RAISE EXCEPTION 'CA_0063: chair-4 text is not the reviewed "civil penalties" wording';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions
                 WHERE topic_revision_id = v_v2 AND value = 2
                   AND text ILIKE '%camping in public spaces%' AND text NOT ILIKE '%outreach workers%') THEN
    RAISE EXCEPTION 'CA_0063: chair-2 text is not the reviewed wording';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions
                 WHERE topic_revision_id = v_v2 AND value = 1 AND text ILIKE '%no penalties of any kind%') THEN
    RAISE EXCEPTION 'CA_0063: chair-1 text is not the reviewed wording';
  END IF;
  IF EXISTS (SELECT 1 FROM inform.compass_stance_revisions
             WHERE topic_revision_id = v_v2 AND value = 5 AND text ILIKE '%existing social services%') THEN
    RAISE EXCEPTION 'CA_0063: chair-5 still carries the dropped existing-services clause';
  END IF;
  -- Chair 3 must be byte-identical to the live v1 revision.
  IF EXISTS (
    SELECT 1
      FROM inform.compass_stance_revisions cur
      JOIN inform.compass_stance_revisions old
        ON old.value = cur.value
       AND old.topic_revision_id = (SELECT id FROM inform.compass_topic_revisions
                                     WHERE topic_id = v_topic AND version = 1 AND revision = 1)
     WHERE cur.topic_revision_id = v_v2 AND cur.value = 3 AND cur.text <> old.text) THEN
    RAISE EXCEPTION 'CA_0063: chair-3 diverged from the live v1 text (expected byte-identical)';
  END IF;

  -- Step 1: approve v2 (draft -> approved), idempotent. NOT published.
  SELECT status INTO v_status FROM inform.compass_topic_revisions WHERE id = v_v2;
  IF v_status = 'draft' THEN
    PERFORM inform.admin_approve_topic_revision(v_v2, v_actor);
    RAISE NOTICE 'CA_0063: v2 approved (draft -> approved), not published.';
  ELSIF v_status = 'approved' THEN
    RAISE NOTICE 'CA_0063: v2 already approved; skipping approve.';
  ELSE
    RAISE EXCEPTION 'CA_0063: v2 in unexpected status % (expected draft or approved)', v_status;
  END IF;

  -- Step 2: repin Season 2 v1 -> v2, idempotent.
  SELECT topic_revision_id INTO v_cur FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_cur = v_v2 THEN
    RAISE NOTICE 'CA_0063: Season 2 already pins v2; skipping pin.';
  ELSE
    PERFORM inform.admin_season_pin_revision(v_season2, v_topic, v_v2, v_actor);
    RAISE NOTICE 'CA_0063: Season 2 homelessness repinned % -> % (v2)', v_cur, v_v2;
  END IF;
END $$;

-- =============================================================================
-- POST-VERIFY
-- =============================================================================
DO $$
DECLARE
  v_topic    CONSTANT uuid := '4938766b-b45a-46e3-93bd-b8b30651271a';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_v1       CONSTANT uuid := 'bab0fb79-19dd-43ed-ab73-b50ac3f934b9';
  v_v2       CONSTANT uuid := '6958fa99-e317-45d7-8076-d11a0a78c897';
  v_status   text;
  v_pub      timestamptz;
  v_iscur    boolean;
  v_v1_cur   boolean;
  v_v1_stat  text;
  v_pin      uuid;
  v_open_ver int;
BEGIN
  -- v2 is approved, NOT published, NOT current.
  SELECT status, published_at, is_current INTO v_status, v_pub, v_iscur
    FROM inform.compass_topic_revisions WHERE id = v_v2;
  IF v_status <> 'approved' THEN RAISE EXCEPTION 'CA_0063 verify: v2 status is % (expected approved)', v_status; END IF;
  IF v_pub IS NOT NULL THEN RAISE EXCEPTION 'CA_0063 verify: v2 has a published_at (must stay unpublished)'; END IF;
  IF v_iscur THEN RAISE EXCEPTION 'CA_0063 verify: v2 is_current is true (must stay false until Season 2 opens)'; END IF;

  -- v1 is still the current/published revision (untouched by approve).
  SELECT is_current, status INTO v_v1_cur, v_v1_stat
    FROM inform.compass_topic_revisions WHERE id = v_v1;
  IF NOT v_v1_cur THEN RAISE EXCEPTION 'CA_0063 verify: v1 is no longer is_current'; END IF;
  IF v_v1_stat <> 'published' THEN RAISE EXCEPTION 'CA_0063 verify: v1 status is % (expected published)', v_v1_stat; END IF;

  -- Exactly one published/current revision for the topic (still v1).
  IF (SELECT count(*) FROM inform.compass_topic_revisions
       WHERE topic_id = v_topic AND is_current = true AND status = 'published') <> 1 THEN
    RAISE EXCEPTION 'CA_0063 verify: expected exactly 1 published/current revision';
  END IF;

  -- Season 2 pins v2.
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_pin <> v_v2 THEN
    RAISE EXCEPTION 'CA_0063 verify: Season 2 pin is % (expected v2)', v_pin;
  END IF;

  -- Season 1 (open) still resolves version 1 for homelessness.
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
    RAISE EXCEPTION 'CA_0063 verify: open season resolves version % (expected 1)', v_open_ver;
  END IF;

  RAISE NOTICE 'CA_0063 post-verify OK: v2 approved (unpublished); Season 2 pins v2; Season 1 still serves v1. Chair-4 re-audit deferred.';
END $$;

COMMIT;
