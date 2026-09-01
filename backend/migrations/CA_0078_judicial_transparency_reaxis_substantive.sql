BEGIN;

-- =============================================================================
-- CA_0078: Transparency in Legal Proceedings (judicial-transparency) — re-cut the
--          five chairs so they are exclusive ceilings on ONE axis (strength of the
--          openness presumption), approve the new revision, and pin it into
--          Season 2 (a DRAFT; NOT open). The question text is unchanged.
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
--
-- TOPIC 6674d87e-… ('judicial-transparency', "Transparency in Legal Proceedings").
--   Scope: judicial only (required). 34 seated rows on the open Season-1 v1 today
--   (4/20/6/3/1 at chairs 1/2/3/4/5). Reviewed 2026-08-31 under the single-revision
--   ("unchanged") review pass.
--
-- WHAT THIS DOES — three metadata steps, NO answer/context rows written:
--   1. PROPOSE a new substantive revision (becomes rev 2 / version 2) with the same
--      question and five re-cut chairs.
--   2. APPROVE it (draft -> approved). NOT published: a substantive rewrite goes live
--      only when its bound season opens, so is_current stays false and published_at
--      stays NULL.
--   3. PIN Season 2 (86d893a1-…, a DRAFT) from v1 (rev 1, b873ee70-…) to the new
--      revision. Season 1 (open, 2d5d67d1-…) is left on v1.
--
-- WHY THE RE-CUT (review 2026-08-31, Chris Andrews):
--   The v1 ladder was one coherent axis (public access, open -> closed) and its levers
--   are genuinely judicial (sealing records, closing hearings, protective orders,
--   publishing reasoned opinions). But the MIDDLE rungs were cut by WHICH REASONS
--   justify sealing, not by HOW STRONG the openness presumption is — and reasons stack:
--     • Chair 2 ("seal for a compelling, documented reason") and chair 3 ("protect
--       victims, seal juvenile records") named the SAME ceiling: chair 3's carve-outs
--       ARE the documented reasons chair 2 permits. Two chairs, one position — breaks
--       exclusivity (check 3) and evidence-ability (check 6).
--     • Chairs 4 and 5 differed only by how broadly to protect, with no statement of
--       where the presumption of openness sat — a thin, degree-only boundary.
--   Fix: re-cut all five rungs onto the STRENGTH OF THE OPENNESS PRESUMPTION, so each
--   chair is a distinct ceiling a source can place a judge at:
--     1 = never seal (absolute openness)
--     2 = seal only where the LAW REQUIRES it; no judge discretion beyond that
--     3 = open by default; discretionary sealing only on a strong, case-specific showing
--     4 = presumption weakened; seal readily when sensitive interests are in play
--     5 = no presumption; CLOSED by default, the judge decides what becomes public
--   Editorial argument baked into v1 chairs 1 and 5 ("Secrecy breeds injustice"; "The law
--   is complicated. Public access … can distort outcomes.") is dropped; each chair now
--   states a plain position.
--
--   CURRENT (v1) -> NEW (v2)  (value : text):
--     Q : "How much should the public know about what happens in court?"  (UNCHANGED)
--     1 : "Everything possible should be public — hearings, evidence, rulings, and the
--          reasoning behind them. Secrecy breeds injustice."
--       -> "Everything in court should be public. Courts should never seal records or
--          close hearings."
--     2 : "Default to open proceedings. Sealing records or closing hearings requires a
--          compelling, documented reason."
--       -> "Courts should be open except where the law requires privacy, like juvenile
--          records. Judges shouldn't seal anything beyond that."
--     3 : "Balance openness with legitimate needs for privacy — protect victims, seal
--          juvenile records, but keep the courtroom open as a rule."
--       -> "Courts should be open by default. A judge can seal records or close a hearing
--          only when there's a strong, specific reason that outweighs the public's
--          interest."
--     4 : "Courts should protect sensitive information broadly — personal details,
--          ongoing investigations, and anything that could prejudice a fair trial."
--       -> "Openness matters, but so do privacy and fair trials. Judges should seal or
--          close proceedings whenever sensitive information is at stake."
--     5 : "The law is complicated. Public access to proceedings can distort outcomes.
--          Broad judicial discretion to limit access protects the integrity of the
--          process."
--       -> "Court proceedings should be closed to the public by default. A judge decides
--          what, if anything, becomes public."
--
-- CLASS: substantive -> version 2. rung_map is identity {1:1,2:2,3:3,4:4,5:5}: the five
--   positions stay ordered (max openness at 1, max closure at 5); the ceilings between
--   them are re-cut, they do not swap rung.
--
-- ⚠⚠ DEFERRED RE-AUDIT — OWED BEFORE SEASON 2 OPENS ⚠⚠
--   This is a WHOLE-SET re-audit (like CA_0070, unlike CA_0071's single chair). Every
--   rung's ceiling shifted, so all 34 seated rows must be re-read against the new
--   wording before Season 2 opens. Distribution at review (v1): 4/20/6/3/1 at chairs
--   1-5. The 20 chair-2 rows are the movers: most were seated on "open by default, seal
--   for a good reason", which maps to the NEW chair 3 (discretionary, high bar), not the
--   NEW chair 2 (law-required-only) — expect a real 2 -> 3 shift. Do NOT open Season 2
--   on this revision until that pass is done. It is a SEPARATE, approved migration
--   against politician_answers.
--   (Per-stance description/supporting_points live in the FROZEN legacy compass_stances
--   copy, 0 source reads; the voter-facing revision is text-only, nothing to restore.)
--
-- WHY SAFE NOW: a season's pinned wording is served only for the OPEN season. Season 2
--   is a draft, so this pin changes nothing a voter sees today; Season 1 (open) keeps
--   serving v1 via the version mechanic. No answer rows are touched.
--
-- Idempotent: re-running after success is a no-op (the revision already exists/approved;
--   Season 2 already pins it).
-- Model: CA_0071 / CA_0070 (propose substantive + approve + pin S2).
-- =============================================================================

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';               -- Chris Andrews
  v_topic    CONSTANT uuid := '6674d87e-999d-433a-aab7-3f626f59fd5f';               -- judicial-transparency
  v_topickey CONSTANT text := 'judicial-transparency';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';               -- Season 2 (draft)
  v_rev1     CONSTANT uuid := 'b873ee70-0d6f-427c-bf7d-02cecd03779b';               -- v1 (rev 1, published/current)
  v_stem     CONSTANT text := 'How much should the public know about what happens in court?';
  v_chair5   CONSTANT text := 'Court proceedings should be closed to the public by default. A judge decides what, if anything, becomes public.';
  v_rungmap  CONSTANT jsonb := '{"1":1,"2":2,"3":3,"4":4,"5":5}'::jsonb;
  v_stances  CONSTANT jsonb := jsonb_build_array(
    jsonb_build_object('value',1,'text','Everything in court should be public. Courts should never seal records or close hearings.'),
    jsonb_build_object('value',2,'text','Courts should be open except where the law requires privacy, like juvenile records. Judges shouldn''t seal anything beyond that.'),
    jsonb_build_object('value',3,'text','Courts should be open by default. A judge can seal records or close a hearing only when there''s a strong, specific reason that outweighs the public''s interest.'),
    jsonb_build_object('value',4,'text','Openness matters, but so do privacy and fair trials. Judges should seal or close proceedings whenever sensitive information is at stake.'),
    jsonb_build_object('value',5,'text','Court proceedings should be closed to the public by default. A judge decides what, if anything, becomes public.')
  );
  v_new      uuid;
  v_status   text;
  v_cur      uuid;
BEGIN
  -- Preconditions -----------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_topic AND topic_key = v_topickey) THEN
    RAISE EXCEPTION 'CA_0078: topic id/key mismatch for %', v_topickey;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = v_rev1 AND topic_id = v_topic AND revision = 1 AND version = 1
                   AND is_current AND status = 'published') THEN
    RAISE EXCEPTION 'CA_0078: live v1 (rev 1) is not in the expected published/current state';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season2 AND number = 2 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0078: Season 2 is not a draft (pin would be frozen)';
  END IF;

  -- Step 1: find-or-create the re-cut revision (rev 2 / v2). Idempotent. --------
  --   Question is UNCHANGED from v1, so locate the new revision by the unique v2
  --   chair-5 text (never key on question here — v1 shares it).
  SELECT r.id INTO v_new
  FROM inform.compass_topic_revisions r
  WHERE r.topic_id = v_topic
    AND r.change_class = 'substantive'
    AND r.version = 2
    AND r.status IN ('draft','approved')
    AND EXISTS (SELECT 1 FROM inform.compass_stance_revisions s
                WHERE s.topic_revision_id = r.id AND s.value = 5 AND s.text = v_chair5);
  IF v_new IS NULL THEN
    v_new := inform.admin_propose_topic_revision(
      v_topickey, v_actor, 'substantive',
      'Transparency in Legal Proceedings', 'Legal Transparency',
      v_stem, v_stances,
      -- rationale
      'Single-revision review 2026-08-31 (Chris Andrews). The v1 ladder was one coherent '
      || 'axis (public access, open->closed) with genuinely judicial levers, but its middle rungs '
      || 'were cut by WHICH reasons justify sealing rather than by HOW STRONG the openness '
      || 'presumption is, and reasons stack. Chair 2 ("seal for a compelling, documented reason") '
      || 'and chair 3 ("protect victims, seal juvenile records") named the SAME ceiling — chair 3''s '
      || 'carve-outs are the documented reasons chair 2 permits — which broke exclusivity and '
      || 'evidence-ability; chairs 4 and 5 differed only by degree. Re-cut all five rungs onto the '
      || 'strength of the openness presumption so each is a distinct, evidence-able ceiling: '
      || '1 = never seal; 2 = seal only where the law requires it, no discretion beyond that; '
      || '3 = open by default, discretionary sealing only on a strong case-specific showing; '
      || '4 = presumption weakened, seal readily when sensitive interests are in play; '
      || '5 = no presumption, closed by default, the judge decides what becomes public. Editorial '
      || 'argument in v1 chairs 1 and 5 dropped. Substantive (version 2) because every rung''s '
      || 'ceiling moved: WHOLE-SET re-audit of all 34 seated rows (4/20/6/3/1) owed before Season 2 '
      || 'opens — the 20 chair-2 rows are the movers (most map to the new chair 3). Approved + pinned '
      || 'to Season 2 only; Season 1 stays on v1.',
      -- public_note
      'Rewrote the five options so each is a clearly different position on how open courts should be '
      || '— from "never seal anything" to "closed by default, the judge decides what becomes public" '
      || '— instead of overlapping on which reasons justify sealing. The question is unchanged.',
      -- review_ref
      'Single-revision review 2026-08-31 (Chris Andrews), reviewunchangedtopicprompt.md '
      || 'judicial-transparency pass; seat distribution 4/20/6/3/1 at chairs 1-5 (34 rows).',
      v_rungmap);
    RAISE NOTICE 'CA_0078: proposed re-cut revision %', v_new;
  ELSE
    RAISE NOTICE 'CA_0078: re-cut revision already exists (%); skipping propose.', v_new;
  END IF;

  -- Step 2: approve (draft -> approved), NOT published. Idempotent. --------------
  SELECT status INTO v_status FROM inform.compass_topic_revisions WHERE id = v_new;
  IF v_status = 'draft' THEN
    PERFORM inform.admin_approve_topic_revision(v_new, v_actor);
    RAISE NOTICE 'CA_0078: re-cut revision approved (not published).';
  ELSIF v_status = 'approved' THEN
    RAISE NOTICE 'CA_0078: re-cut revision already approved; skipping approve.';
  ELSE
    RAISE EXCEPTION 'CA_0078: re-cut revision in unexpected status % (expected draft or approved)', v_status;
  END IF;

  -- Step 3: pin Season 2 v1 -> new revision. Idempotent. ------------------------
  SELECT topic_revision_id INTO v_cur FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_cur = v_new THEN
    RAISE NOTICE 'CA_0078: Season 2 already pins the re-cut revision; skipping pin.';
  ELSE
    PERFORM inform.admin_season_pin_revision(v_season2, v_topic, v_new, v_actor);
    RAISE NOTICE 'CA_0078: Season 2 repinned % -> % (re-cut revision)', v_cur, v_new;
  END IF;
END $$;

-- =============================================================================
-- POST-VERIFY
-- =============================================================================
DO $$
DECLARE
  v_topic    CONSTANT uuid := '6674d87e-999d-433a-aab7-3f626f59fd5f';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_rev1     CONSTANT uuid := 'b873ee70-0d6f-427c-bf7d-02cecd03779b';
  v_stem     CONSTANT text := 'How much should the public know about what happens in court?';
  v_chair5   CONSTANT text := 'Court proceedings should be closed to the public by default. A judge decides what, if anything, becomes public.';
  v_new      uuid;
  v_status   text;
  v_pub      timestamptz;
  v_iscur    boolean;
  v_rev      int;
  v_ver      int;
  v_class    text;
  v_qtext    text;
  v_n        int;
  v_v1cur    boolean;
  v_v1stat   text;
  v_pin      uuid;
  v_openver  int;
BEGIN
  -- Locate the re-cut revision by the unique v2 chair-5 text.
  SELECT r.id, r.status, r.published_at, r.is_current, r.revision, r.version, r.change_class::text, r.question_text
    INTO v_new, v_status, v_pub, v_iscur, v_rev, v_ver, v_class, v_qtext
  FROM inform.compass_topic_revisions r
  WHERE r.topic_id = v_topic
    AND EXISTS (SELECT 1 FROM inform.compass_stance_revisions s
                WHERE s.topic_revision_id = r.id AND s.value = 5 AND s.text = v_chair5);
  IF v_new IS NULL THEN RAISE EXCEPTION 'CA_0078 verify: re-cut revision not found'; END IF;

  IF v_status <> 'approved' THEN RAISE EXCEPTION 'CA_0078 verify: new rev status is % (expected approved)', v_status; END IF;
  IF v_pub IS NOT NULL THEN RAISE EXCEPTION 'CA_0078 verify: new rev has published_at (must stay unpublished)'; END IF;
  IF v_iscur THEN RAISE EXCEPTION 'CA_0078 verify: new rev is_current is true (must stay false until Season 2 opens)'; END IF;
  IF v_rev <> 2 THEN RAISE EXCEPTION 'CA_0078 verify: new rev revision is % (expected 2)', v_rev; END IF;
  IF v_ver <> 2 THEN RAISE EXCEPTION 'CA_0078 verify: new rev version is % (expected 2)', v_ver; END IF;
  IF v_class <> 'substantive' THEN RAISE EXCEPTION 'CA_0078 verify: new rev change_class is % (expected substantive)', v_class; END IF;
  IF v_qtext <> v_stem THEN RAISE EXCEPTION 'CA_0078 verify: new rev question_text changed (expected unchanged)'; END IF;

  -- Exactly five rungs, all carrying the reviewed NEW text.
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions WHERE topic_revision_id = v_new;
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0078 verify: new rev has % rungs (expected 5)', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions s WHERE s.topic_revision_id = v_new AND (
       (s.value = 1 AND s.text = 'Everything in court should be public. Courts should never seal records or close hearings.')
    OR (s.value = 2 AND s.text = 'Courts should be open except where the law requires privacy, like juvenile records. Judges shouldn''t seal anything beyond that.')
    OR (s.value = 3 AND s.text = 'Courts should be open by default. A judge can seal records or close a hearing only when there''s a strong, specific reason that outweighs the public''s interest.')
    OR (s.value = 4 AND s.text = 'Openness matters, but so do privacy and fair trials. Judges should seal or close proceedings whenever sensitive information is at stake.')
    OR (s.value = 5 AND s.text = 'Court proceedings should be closed to the public by default. A judge decides what, if anything, becomes public.'));
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0078 verify: new rev rungs do not all match the reviewed wording (matched %)', v_n; END IF;

  -- No old wording leaked into the new revision.
  IF EXISTS (SELECT 1 FROM inform.compass_stance_revisions s WHERE s.topic_revision_id = v_new
             AND (s.text ILIKE '%Secrecy breeds injustice%' OR s.text ILIKE '%compelling, documented reason%'
               OR s.text ILIKE '%The law is complicated%' OR s.text ILIKE '%can distort outcomes%'
               OR s.text ILIKE '%keep the courtroom open as a rule%')) THEN
    RAISE EXCEPTION 'CA_0078 verify: new rev still carries old chair wording';
  END IF;

  -- v1 still the published/current revision, and exactly one such.
  SELECT is_current, status INTO v_v1cur, v_v1stat FROM inform.compass_topic_revisions WHERE id = v_rev1;
  IF NOT v_v1cur THEN RAISE EXCEPTION 'CA_0078 verify: v1 is no longer is_current'; END IF;
  IF v_v1stat <> 'published' THEN RAISE EXCEPTION 'CA_0078 verify: v1 status is % (expected published)', v_v1stat; END IF;
  IF (SELECT count(*) FROM inform.compass_topic_revisions
       WHERE topic_id = v_topic AND is_current = true AND status = 'published') <> 1 THEN
    RAISE EXCEPTION 'CA_0078 verify: expected exactly 1 published/current revision (still v1)';
  END IF;

  -- Season 2 pins the new revision.
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_pin <> v_new THEN RAISE EXCEPTION 'CA_0078 verify: Season 2 pin is % (expected new rev %)', v_pin, v_new; END IF;

  -- Season 1 (open) still resolves version 1.
  SELECT eff.version INTO v_openver
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
  IF v_openver IS NOT NULL AND v_openver <> 1 THEN
    RAISE EXCEPTION 'CA_0078 verify: open season resolves version % (expected 1)', v_openver;
  END IF;

  RAISE NOTICE 'CA_0078 post-verify OK: re-cut rev 2/v2 approved (unpublished); Season 2 pins it; Season 1 still serves v1. Whole-set 34-row re-audit deferred before Season 2 opens.';
END $$;

COMMIT;
