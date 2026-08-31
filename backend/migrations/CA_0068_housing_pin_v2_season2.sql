BEGIN;

-- =============================================================================
-- CA_0068: Housing (housing) — pin the already-approved v2 five-chair reshuffle
--          into Season 2 (Season 2 is a draft; it is NOT opened here)
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
--
-- WHAT: one metadata step on the housing v2 rework
--   (topic 669cac97-…, revision 3, version 2, change_class 'substantive', already
--    status='approved' — parked by CA_0043 with no season pin):
--     1. REPIN Season 2's housing question from v1 (revision 234c3f2a-…) to v2
--        (revision 598c879d-…).
--   No approve step is needed: CA_0043 already approved this revision. It stays
--   unpublished (is_current=false, published_at NULL) — a substantive rewrite goes
--   live only when its bound season opens, never by direct publish.
--   Season 2 (86d893a1-…) is a DRAFT and is NOT opened here.
--   This migration writes NO politician_answers / politician_context rows — see the
--   DEFERRED RE-AUDIT block below.
--
-- WHY THE PIN WAS MISSING. CA_0043 (2026-08-30) reshuffled housing into five mutually
--   -exclusive chairs and PARKED the result at 'approved' with no season pin (the pin
--   was intentionally deferred behind a re-audit). A season serves its PINNED revision,
--   so Season 2 kept pointing at v1 and showed the old wording. Decision 2026-08-31
--   (Chris Andrews): pin v2 into Season 2 NOW, before the re-audit, so the full Season 2
--   composition is visible; run the re-audit afterward, before Season 2 opens. This
--   migration moves only the pin.
--
-- THE REWORK (reviewed 2026-08-30, Chris Andrews) — all five chairs reworded into a
--   government-reach ladder; rung_map = {"1":1,"2":3,"3":4,"4":5,"5":5} (keys OLD chairs,
--   values NEW chairs — a seat-carry map, NOT a text map). New chair 2 (public option)
--   opens empty and is populated only by the re-audit:
--     Chair 1: "Directly build and operate public housing so anyone who needs a home can
--       get one" -> "Make government the main provider — build and operate public housing
--       so everyone is guaranteed a home."
--     Chair 2 (NEW public option): "Build a large public housing sector that competes with
--       the private market to hold prices down, while private housing stays the norm."
--     Chair 3: "Build no public housing, but set binding rules on the private market like
--       rent caps or required affordable units."
--     Chair 4: "Set no binding rules, but offer subsidies and tax breaks so more affordable
--       housing gets built."
--     Chair 5: "Rely on the market to set prices and supply — at most, cut the regulations
--       and zoning limits that block private building."
--
-- ⚠⚠ DEFERRED RE-AUDIT — OWED BEFORE SEASON 2 OPENS ⚠⚠
--   Season 2 must NOT be opened on this revision until the reshuffled chairs are re-audited
--   against the new wording. ~875 of 1,785 seated rows need a verdict (mechanical rung_map
--   carry is not a verdict). Measured 2026-08-30: old ch2 (757→new3) ~133 carry / ~314
--   funding-only re-home to 2/4/1 / ~309 blank; old ch3 (672→new4) ~79 deregulation-only
--   move to 5 / ~67 opaque; old ch1 (113→new1) ~18 public-option candidates move to new 2 /
--   87 opaque. New chair 2 is populated ONLY by that re-audit. Run
--   scripts/audit-chair-evidence.mjs on each re-audit migration. No carry file exists yet.
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
  v_topic    CONSTANT uuid := '669cac97-66a6-4087-b036-936fbe62efb3'; -- housing
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194'; -- Season 2 (draft)
  v_v1       CONSTANT uuid := '234c3f2a-0bbf-4a8f-ab6b-5344e080f783'; -- v1 (rev1, published/current)
  v_v2       CONSTANT uuid := '598c879d-f387-461c-9120-fbbbf6314bbc'; -- v2 (rev3, substantive, approved)
  v_status   text;
  v_cur      uuid;
  v_same     int;
BEGIN
  -- Preconditions.
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_topic AND topic_key = 'housing') THEN
    RAISE EXCEPTION 'CA_0068: housing topic id mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = v_v2 AND topic_id = v_topic AND revision = 3 AND version = 2
                   AND change_class = 'substantive' AND status = 'approved') THEN
    RAISE EXCEPTION 'CA_0068: v2 revision missing/mismatched (expected rev3, version2, substantive, approved)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season2 AND number = 2 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0068: Season 2 is not a draft (pin would be frozen)';
  END IF;

  -- v2 carries five chairs.
  IF (SELECT count(*) FROM inform.compass_stance_revisions WHERE topic_revision_id = v_v2) <> 5 THEN
    RAISE EXCEPTION 'CA_0068: v2 does not carry exactly 5 chairs';
  END IF;

  -- Lock the pin to the reviewed wording: distinctive phrases on the new ladder.
  IF NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions
                 WHERE topic_revision_id = v_v2 AND value = 1 AND text ILIKE '%main provider%') THEN
    RAISE EXCEPTION 'CA_0068: chair-1 text is not the reviewed v2 wording';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions
                 WHERE topic_revision_id = v_v2 AND value = 2 AND text ILIKE '%competes with the private market%') THEN
    RAISE EXCEPTION 'CA_0068: chair-2 (public option) text is not the reviewed v2 wording';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions
                 WHERE topic_revision_id = v_v2 AND value = 3 AND text ILIKE '%build no public housing%') THEN
    RAISE EXCEPTION 'CA_0068: chair-3 text is not the reviewed v2 wording';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions
                 WHERE topic_revision_id = v_v2 AND value = 4 AND text ILIKE '%subsidies and tax breaks%') THEN
    RAISE EXCEPTION 'CA_0068: chair-4 text is not the reviewed v2 wording';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions
                 WHERE topic_revision_id = v_v2 AND value = 5 AND text ILIKE '%rely on the market%') THEN
    RAISE EXCEPTION 'CA_0068: chair-5 text is not the reviewed v2 wording';
  END IF;

  -- Every chair was reworded: no v2 chair equals its v1 same-value text (full reshuffle).
  SELECT count(*) INTO v_same
    FROM inform.compass_stance_revisions cur
    JOIN inform.compass_stance_revisions old ON old.value = cur.value AND old.topic_revision_id = v_v1
   WHERE cur.topic_revision_id = v_v2 AND cur.text = old.text;
  IF v_same <> 0 THEN
    RAISE EXCEPTION 'CA_0068: % chair(s) still match the old v1 text (expected full reshuffle)', v_same;
  END IF;

  -- Repin Season 2 v1 -> v2, idempotent.
  SELECT topic_revision_id INTO v_cur FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_cur IS NULL THEN
    RAISE EXCEPTION 'CA_0068: Season 2 has no housing question pin to move';
  ELSIF v_cur = v_v2 THEN
    RAISE NOTICE 'CA_0068: Season 2 already pins v2; skipping pin.';
  ELSE
    PERFORM inform.admin_season_pin_revision(v_season2, v_topic, v_v2, v_actor);
    RAISE NOTICE 'CA_0068: Season 2 housing repinned % -> % (v2)', v_cur, v_v2;
  END IF;

  -- v2 stays parked at approved/unpublished (no approve, no publish here).
  SELECT status INTO v_status FROM inform.compass_topic_revisions WHERE id = v_v2;
  IF v_status <> 'approved' THEN
    RAISE EXCEPTION 'CA_0068: v2 status changed to % (must stay approved)', v_status;
  END IF;
END $$;

-- =============================================================================
-- POST-VERIFY
-- =============================================================================
DO $$
DECLARE
  v_topic    CONSTANT uuid := '669cac97-66a6-4087-b036-936fbe62efb3';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_v1       CONSTANT uuid := '234c3f2a-0bbf-4a8f-ab6b-5344e080f783';
  v_v2       CONSTANT uuid := '598c879d-f387-461c-9120-fbbbf6314bbc';
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
  IF v_nrev <> 3 THEN RAISE EXCEPTION 'CA_0068 verify: expected 3 revisions for topic, found %', v_nrev; END IF;

  -- v2 is approved, NOT published, NOT current.
  SELECT status, published_at, is_current INTO v_status, v_pub, v_iscur
    FROM inform.compass_topic_revisions WHERE id = v_v2;
  IF v_status <> 'approved' THEN RAISE EXCEPTION 'CA_0068 verify: v2 status is % (expected approved)', v_status; END IF;
  IF v_pub IS NOT NULL THEN RAISE EXCEPTION 'CA_0068 verify: v2 has a published_at (must stay unpublished)'; END IF;
  IF v_iscur THEN RAISE EXCEPTION 'CA_0068 verify: v2 is_current is true (must stay false until Season 2 opens)'; END IF;

  -- v1 is still the current/published revision (untouched).
  SELECT is_current, status INTO v_v1_cur, v_v1_stat
    FROM inform.compass_topic_revisions WHERE id = v_v1;
  IF NOT v_v1_cur THEN RAISE EXCEPTION 'CA_0068 verify: v1 is no longer is_current'; END IF;
  IF v_v1_stat <> 'published' THEN RAISE EXCEPTION 'CA_0068 verify: v1 status is % (expected published)', v_v1_stat; END IF;

  -- Exactly one published/current revision for the topic (still v1).
  IF (SELECT count(*) FROM inform.compass_topic_revisions
       WHERE topic_id = v_topic AND is_current = true AND status = 'published') <> 1 THEN
    RAISE EXCEPTION 'CA_0068 verify: expected exactly 1 published/current revision';
  END IF;

  -- Season 2 pins v2 (the new revision).
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_pin <> v_v2 THEN
    RAISE EXCEPTION 'CA_0068 verify: Season 2 pin is % (expected v2)', v_pin;
  END IF;

  -- All five chairs on the pinned S2 revision carry NEW text (none matches v1 same-value).
  SELECT count(*) INTO v_bad
    FROM inform.compass_stance_revisions cur
    JOIN inform.compass_stance_revisions old ON old.value = cur.value AND old.topic_revision_id = v_v1
   WHERE cur.topic_revision_id = v_v2 AND cur.text = old.text;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CA_0068 verify: % chair(s) still match the old v1 text', v_bad;
  END IF;

  -- Season 1 (open) still resolves version 1 for housing.
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
    RAISE EXCEPTION 'CA_0068 verify: open season resolves version % (expected 1)', v_open_ver;
  END IF;

  RAISE NOTICE 'CA_0068 post-verify OK: Season 2 pins housing v2 (approved, unpublished); Season 1 still serves v1. Five-chair re-audit deferred (~875 of 1785 rows) before Season 2 opens.';
END $$;

COMMIT;
