BEGIN;

-- =============================================================================
-- CA_0067: City Sanitation (city-sanitation) — pin the already-approved v2
--          rework into Season 2 (Season 2 is a draft; it is NOT opened here)
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
--
-- WHAT: one metadata step on the city-sanitation v2 rework
--   (topic 7687de4f-…, revision 3, version 2, change_class 'substantive', already
--    status='approved' — parked by CA_0040 with no season pin):
--     1. REPIN Season 2's city-sanitation question from v1 (revision 5c260a5f-…) to v2
--        (revision 35acdf20-…).
--   No approve step is needed: CA_0040 already approved this revision. It stays
--   unpublished (is_current=false, published_at NULL) — a substantive rewrite goes
--   live only when its bound season opens, never by direct publish.
--   Season 2 (86d893a1-…) is a DRAFT and is NOT opened here.
--   This migration writes NO politician_answers / politician_context rows — see the
--   DEFERRED RE-AUDIT block below.
--
-- WHY THE PIN WAS MISSING. CA_0040 (2026-08-30) reviewed city-sanitation, de-barreled
--   chairs 1-3 onto a public->private provision spine, and PARKED the result at
--   'approved' with no season pin. A season serves its PINNED revision, so Season 2
--   kept pointing at v1 and showed the old wording. This migration moves only the pin.
--
-- THE REWORK (reviewed 2026-08-30, Chris Andrews) — chairs 1-3 de-barreled; chairs
--   4 and 5 are byte-identical to v1 (their seats are untouched):
--     Chair 1: "Significantly expand sanitation staffing, cleaning frequency, and free
--       community disposal access; treat poor conditions as a services failure"
--       -> "Significantly expand public sanitation services, treating cleanliness as
--       the city's responsibility". Collapses the staffing/frequency/disposal barrels.
--     Chair 2: "Increase sanitation crews and prioritize historically underserved
--       neighborhoods to equalize cleanliness communitywide"
--       -> "Concentrate sanitation resources on the most neglected, worst-served
--       neighborhoods to close long-standing service gaps". Drops the standalone
--       "increase crews" barrel that overlapped chair 1; keeps the equity clause
--       (CONCENTRATE vs chair 1's SPREAD).
--     Chair 3: "Maintain current sanitation services while enforcing anti-dumping laws
--       for businesses and large property owners"
--       -> "Maintain current public sanitation services and target enforcement at the
--       businesses and large property owners who create the most waste".
--
-- ⚠⚠ DEFERRED RE-AUDIT — OWED BEFORE SEASON 2 OPENS ⚠⚠
--   Season 2 must NOT be opened on this revision until chairs 1-3 are re-audited against
--   the new wording. Carry file: backend/data/season2-carry/city-sanitation-reaudit.json
--   — 86 rows on chairs 1-3, of which ~13 are chair-2 axis-orphans (seated on general
--   expansion with NO equity signal — the load-bearing reason the v2 chair 2 narrowing
--   is substantive). Those rows were evidenced against v1's broader wording; under v2
--   they assert a position their evidence does not support. Decision (CA_0040):
--   re-source first, blank if none, applied to the Season-2 answer set at assembly.
--   Chairs 4 and 5 are unchanged, so no re-audit is owed on them.
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
  v_topic    CONSTANT uuid := '7687de4f-4d0b-462a-b803-bdfb23b16b42'; -- city-sanitation
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194'; -- Season 2 (draft)
  v_v1       CONSTANT uuid := '5c260a5f-c7e3-46af-98e9-8b17aa85a87f'; -- v1 (rev1, published/current)
  v_v2       CONSTANT uuid := '35acdf20-ffcb-423d-8b99-a1e236ae82c5'; -- v2 (rev3, substantive, approved)
  v_status   text;
  v_cur      uuid;
BEGIN
  -- Preconditions.
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_topic AND topic_key = 'city-sanitation') THEN
    RAISE EXCEPTION 'CA_0067: city-sanitation topic id mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = v_v2 AND topic_id = v_topic AND revision = 3 AND version = 2
                   AND change_class = 'substantive' AND status = 'approved') THEN
    RAISE EXCEPTION 'CA_0067: v2 revision missing/mismatched (expected rev3, version2, substantive, approved)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season2 AND number = 2 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0067: Season 2 is not a draft (pin would be frozen)';
  END IF;

  -- Lock the pin to the exact reviewed wording: guard against pinning a wrong/edited revision.
  -- Chair 1: reworded to "city's responsibility" (dropped the staffing/frequency/disposal barrels).
  IF NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions
                 WHERE topic_revision_id = v_v2 AND value = 1
                   AND text ILIKE '%public sanitation services%' AND text ILIKE '%city''s responsibility%') THEN
    RAISE EXCEPTION 'CA_0067: chair-1 text is not the reviewed v2 wording';
  END IF;
  -- Chair 2: reworded to "concentrate" (dropped the "increase crews" barrel; kept equity).
  IF NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions
                 WHERE topic_revision_id = v_v2 AND value = 2
                   AND text ILIKE '%concentrate sanitation resources%' AND text NOT ILIKE '%increase sanitation crews%') THEN
    RAISE EXCEPTION 'CA_0067: chair-2 text is not the reviewed v2 wording';
  END IF;
  -- Chair 3: reworded to "create the most waste" (dropped "anti-dumping laws").
  IF NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions
                 WHERE topic_revision_id = v_v2 AND value = 3
                   AND text ILIKE '%create the most waste%') THEN
    RAISE EXCEPTION 'CA_0067: chair-3 text is not the reviewed v2 wording';
  END IF;
  -- Chairs 4 and 5 must be byte-identical to the live v1 revision.
  IF EXISTS (
    SELECT 1
      FROM inform.compass_stance_revisions cur
      JOIN inform.compass_stance_revisions old
        ON old.value = cur.value AND old.topic_revision_id = v_v1
     WHERE cur.topic_revision_id = v_v2 AND cur.value IN (4, 5) AND cur.text <> old.text) THEN
    RAISE EXCEPTION 'CA_0067: an unchanged chair (4/5) diverged from the live v1 text';
  END IF;

  -- Repin Season 2 v1 -> v2, idempotent.
  SELECT topic_revision_id INTO v_cur FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_cur IS NULL THEN
    RAISE EXCEPTION 'CA_0067: Season 2 has no city-sanitation question pin to move';
  ELSIF v_cur = v_v2 THEN
    RAISE NOTICE 'CA_0067: Season 2 already pins v2; skipping pin.';
  ELSE
    PERFORM inform.admin_season_pin_revision(v_season2, v_topic, v_v2, v_actor);
    RAISE NOTICE 'CA_0067: Season 2 city-sanitation repinned % -> % (v2)', v_cur, v_v2;
  END IF;

  -- v2 stays parked at approved/unpublished (no approve, no publish here).
  SELECT status INTO v_status FROM inform.compass_topic_revisions WHERE id = v_v2;
  IF v_status <> 'approved' THEN
    RAISE EXCEPTION 'CA_0067: v2 status changed to % (must stay approved)', v_status;
  END IF;
END $$;

-- =============================================================================
-- POST-VERIFY
-- =============================================================================
DO $$
DECLARE
  v_topic    CONSTANT uuid := '7687de4f-4d0b-462a-b803-bdfb23b16b42';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_v1       CONSTANT uuid := '5c260a5f-c7e3-46af-98e9-8b17aa85a87f';
  v_v2       CONSTANT uuid := '35acdf20-ffcb-423d-8b99-a1e236ae82c5';
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
  IF v_nrev <> 3 THEN RAISE EXCEPTION 'CA_0067 verify: expected 3 revisions for topic, found %', v_nrev; END IF;

  -- v2 is approved, NOT published, NOT current.
  SELECT status, published_at, is_current INTO v_status, v_pub, v_iscur
    FROM inform.compass_topic_revisions WHERE id = v_v2;
  IF v_status <> 'approved' THEN RAISE EXCEPTION 'CA_0067 verify: v2 status is % (expected approved)', v_status; END IF;
  IF v_pub IS NOT NULL THEN RAISE EXCEPTION 'CA_0067 verify: v2 has a published_at (must stay unpublished)'; END IF;
  IF v_iscur THEN RAISE EXCEPTION 'CA_0067 verify: v2 is_current is true (must stay false until Season 2 opens)'; END IF;

  -- v1 is still the current/published revision (untouched).
  SELECT is_current, status INTO v_v1_cur, v_v1_stat
    FROM inform.compass_topic_revisions WHERE id = v_v1;
  IF NOT v_v1_cur THEN RAISE EXCEPTION 'CA_0067 verify: v1 is no longer is_current'; END IF;
  IF v_v1_stat <> 'published' THEN RAISE EXCEPTION 'CA_0067 verify: v1 status is % (expected published)', v_v1_stat; END IF;

  -- Exactly one published/current revision for the topic (still v1).
  IF (SELECT count(*) FROM inform.compass_topic_revisions
       WHERE topic_id = v_topic AND is_current = true AND status = 'published') <> 1 THEN
    RAISE EXCEPTION 'CA_0067 verify: expected exactly 1 published/current revision';
  END IF;

  -- Season 2 pins v2 (the new revision).
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_pin <> v_v2 THEN
    RAISE EXCEPTION 'CA_0067 verify: Season 2 pin is % (expected v2)', v_pin;
  END IF;

  -- The reworded chairs (1/2/3) on the pinned S2 revision carry the NEW text, not the old.
  SELECT count(*) INTO v_bad
    FROM inform.compass_stance_revisions cur
    JOIN inform.compass_stance_revisions old ON old.value = cur.value AND old.topic_revision_id = v_v1
   WHERE cur.topic_revision_id = v_v2 AND cur.value IN (1, 2, 3) AND cur.text = old.text;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CA_0067 verify: % reworded chair(s) still match the old v1 text', v_bad;
  END IF;

  -- Unchanged chairs (4/5) on the pinned S2 revision are byte-identical to v1.
  SELECT count(*) INTO v_bad
    FROM inform.compass_stance_revisions cur
    JOIN inform.compass_stance_revisions old ON old.value = cur.value AND old.topic_revision_id = v_v1
   WHERE cur.topic_revision_id = v_v2 AND cur.value IN (4, 5) AND cur.text <> old.text;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CA_0067 verify: an unchanged chair (4/5) diverged from the v1 text';
  END IF;

  -- Season 1 (open) still resolves version 1 for city-sanitation.
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
    RAISE EXCEPTION 'CA_0067 verify: open season resolves version % (expected 1)', v_open_ver;
  END IF;

  RAISE NOTICE 'CA_0067 post-verify OK: Season 2 pins v2 (approved, unpublished); Season 1 still serves v1. Chairs 1/2/3 re-audit deferred (86 rows, ~13 orphans) before Season 2 opens.';
END $$;

COMMIT;
