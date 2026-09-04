BEGIN;

-- =============================================================================
-- CA_0064: Civil Rights — approve v2 and pin it into Season 2 (draft; not opened)
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2,
-- candrews@empowered.vote).
--
-- WHAT: two steps on the civil-rights v2 double-barrel split (revision 2010cab0,
--   version 2). The only text change from v1 is chair 1:
--       v1: "mandate racial equity requirements in all institutions and provide reparations"
--       v2: "mandate racial equity requirements in all institutions"
--   Chairs 2-5 are byte-identical to v1; rung_map is identity (1->1 .. 5->5).
--     1. APPROVE v2 (draft -> approved). NOT published: a substantive/major rewrite goes
--        live only when its bound season opens, never by a direct publish.
--     2. REPIN Season 2's civil-rights question from v1 (revision 839b4b5b) to v2.
--   Season 2 is a DRAFT and is NOT opened here.
--
-- CLASSIFICATION (major, confirmed 2026-08-31): the split stays substantive/major, NOT
--   clarifying. The Healthcare (CA_0055) minor-exception licenses a split as clarifying only
--   when the dropped barrel carried NO weight (was redundant with the surviving barrel). Here
--   the opposite holds: of 210 chair-1 seatings, 34 (16%) cite reparations in evidence and a
--   few rest primarily on it, and v2's own rationale states the two are "plainly separable
--   policies -- many back one and not the other." That separability is the definition of a
--   material change. So v2 keeps version=2 and stages into Season 2 rather than publishing.
--
-- RE-AUDIT STILL OWED (deferred by author 2026-08-31): the 210 chair-1 rows need a re-audit
--   against the narrowed wording BEFORE Season 2 opens (audit-chair-evidence.mjs). The split
--   is a narrowing, so no currently-seated chair-1 row becomes wrong (old evidence for both
--   barrels still supports the narrower claim); the open question is whether equity-only
--   supporters now in chair 2 / blank belong at chair 1. This migration does NOT touch
--   politician_answers / politician_context -- it is metadata only (approve + pin). Mirrors the
--   CA_0058 (misinformation) pattern: approved + pinned to S2 with the re-audit owed before open.
--
-- WHY SAFE NOW: a season's pinned wording is served only for the OPEN season
--   (compassService.getPromotedTopics joins seasons status='open'). Season 2 is draft, so this
--   pin changes nothing a voter sees today; Season 1 keeps serving v1r1.
--
-- Mirrors CA_0046 (rent-regulation approve+pin) structurally. Idempotent: re-running after
-- success is a no-op (v2 already approved; pin already equals v2).
-- =============================================================================

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
  v_topic    CONSTANT uuid := '0bc588c6-39e1-4084-b5de-cac909b8b762'; -- civil-rights
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194'; -- Season 2
  v_v2       uuid;  -- bound below from (revision=2, version=2)
  v_status   text;
  v_cur      uuid;
BEGIN
  -- Bind v2 by identity from the row itself to avoid a transcription slip.
  SELECT id INTO v_v2 FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic AND revision = 2 AND version = 2;

  -- Preconditions
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_topic AND topic_key = 'civil-rights') THEN
    RAISE EXCEPTION 'CA_0064: civil-rights topic id mismatch';
  END IF;
  IF v_v2 IS NULL THEN
    RAISE EXCEPTION 'CA_0064: v2 revision (revision=2, version=2) missing';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season2 AND number = 2 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0064: Season 2 is not a draft (pin would be frozen)';
  END IF;
  -- Guard the actual text change: chair 1 must be the de-barreled wording.
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_stance_revisions
     WHERE topic_revision_id = v_v2 AND value = 1
       AND text = 'mandate racial equity requirements in all institutions'
  ) THEN
    RAISE EXCEPTION 'CA_0064: v2 chair-1 text is not the expected de-barreled wording';
  END IF;

  -- Step 1: approve v2 (draft -> approved), idempotent.
  SELECT status INTO v_status FROM inform.compass_topic_revisions WHERE id = v_v2;
  IF v_status = 'draft' THEN
    PERFORM inform.admin_approve_topic_revision(v_v2, v_actor);
    RAISE NOTICE 'CA_0064: v2 approved (draft -> approved), not published.';
  ELSIF v_status = 'approved' THEN
    RAISE NOTICE 'CA_0064: v2 already approved; skipping approve.';
  ELSE
    RAISE EXCEPTION 'CA_0064: v2 in unexpected status % (expected draft or approved)', v_status;
  END IF;

  -- Step 2: repin Season 2 v1 -> v2, idempotent.
  SELECT topic_revision_id INTO v_cur FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_cur = v_v2 THEN
    RAISE NOTICE 'CA_0064: Season 2 already pins v2; skipping pin.';
  ELSE
    PERFORM inform.admin_season_pin_revision(v_season2, v_topic, v_v2, v_actor);
    RAISE NOTICE 'CA_0064: Season 2 civil-rights repinned % -> % (v2)', v_cur, v_v2;
  END IF;
END $$;

-- =============================================================================
-- POST-VERIFY
-- =============================================================================
DO $$
DECLARE
  v_topic   CONSTANT uuid := '0bc588c6-39e1-4084-b5de-cac909b8b762';
  v_season2 CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_v1      CONSTANT uuid := '839b4b5b-dd16-45a5-8dce-8e54f85165f6'; -- v1 (rev1)
  v_v2      uuid;
  v_status  text;
  v_pub     timestamptz;
  v_iscur   boolean;
  v_pin     uuid;
  v_v1_cur  boolean;
  v_open_ver int;
BEGIN
  SELECT id INTO v_v2 FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic AND revision = 2 AND version = 2;

  -- v2 is approved, NOT published, NOT current.
  SELECT status, published_at, is_current INTO v_status, v_pub, v_iscur
    FROM inform.compass_topic_revisions WHERE id = v_v2;
  IF v_status <> 'approved' THEN RAISE EXCEPTION 'CA_0064 verify: v2 status is % (expected approved)', v_status; END IF;
  IF v_pub IS NOT NULL THEN RAISE EXCEPTION 'CA_0064 verify: v2 has a published_at (must stay unpublished)'; END IF;
  IF v_iscur THEN RAISE EXCEPTION 'CA_0064 verify: v2 is_current is true (must stay false until the season opens)'; END IF;

  -- v1 is still the current/published revision (untouched by approve).
  SELECT is_current INTO v_v1_cur FROM inform.compass_topic_revisions WHERE id = v_v1;
  IF NOT v_v1_cur THEN RAISE EXCEPTION 'CA_0064 verify: v1 is no longer is_current'; END IF;

  -- Season 2 pins v2.
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_pin <> v_v2 THEN
    RAISE EXCEPTION 'CA_0064 verify: Season 2 pin is % (expected v2 %)', v_pin, v_v2;
  END IF;

  -- Season 1 (open) still resolves version 1 for civil-rights.
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
    RAISE EXCEPTION 'CA_0064 verify: open season resolves version % (expected 1)', v_open_ver;
  END IF;

  RAISE NOTICE 'CA_0064 post-verify OK: v2 approved (unpublished); Season 2 pins v2; Season 1 still serves v1.';
END $$;

COMMIT;
