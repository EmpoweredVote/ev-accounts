BEGIN;

-- =============================================================================
-- CA_0073: Homelessness Response (homelessness-response) — RE-AXIS. Replace the
--          enforcement ladder with a public-funding ladder, reword the question,
--          approve the new revision, and pin it into Season 2 (a DRAFT; NOT open).
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
--
-- TOPIC 6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f ('homelessness-response',
--   "Homelessness Response"). Scope: local only (required). 440 seated rows on the
--   open Season-1 v1 today (29/176/164/65/6 at chairs 1/2/3/4/5). Reviewed
--   2026-08-31 under the single-revision ("unchanged") review pass.
--
-- WHAT THIS DOES — three metadata steps, NO answer/context rows written:
--   1. PROPOSE a new substantive revision (becomes rev 2 / version 2) with the
--      reviewed question + five funding chairs.
--   2. APPROVE it (draft -> approved). NOT published: a substantive rewrite goes
--      live only when its bound season opens, so is_current stays false and
--      published_at stays NULL.
--   3. PIN Season 2 (86d893a1-…, a DRAFT) from v1 (rev 1, d39da7dd-…) to the new
--      revision. Season 1 (open, 2d5d67d1-…) is left on v1.
--
-- WHY A RE-AXIS (review 2026-08-31, Chris Andrews):
--   • DUPLICATION. As written, 'homelessness-response' measured the SAME axis as the
--     sibling topic 'homelessness' ("Criminalization of Homelessness", Season 2 q14):
--     a services<->enforcement spine (housing-first/decriminalise -> strict
--     enforcement). Proof: 271 politicians are seated on both topics, 199 (73%) on the
--     EXACT same chair and 270/271 (99.6%) within one chair; chair 3 was seated
--     identically on both (164 rows). Two adjacent Season-2 questions asked one thing.
--   • The fix is to give this topic a DISTINCT axis. 'homelessness' keeps the
--     enforcement axis (how much you POLICE public space). This topic is re-cut onto
--     the independent axis of how much a community FUNDS the response — from a
--     guaranteed, dedicated commitment down to withdrawing public money. A voter can
--     hold any combination (fund heavily AND enforce, or neither), so the two topics
--     no longer duplicate.
--   • ONE axis only. The new ladder moves a single variable: the size and form of the
--     public funding role. Enforcement, approach/conditionality (housing-first vs
--     treatment-first) and targeting (universal vs most-vulnerable) are deliberately
--     EXCLUDED — each would be a second axis.
--   • Endpoints differ in KIND, not degree (so chairs are positions, not a rating):
--     guarantee / expand / maintain / delegate / withdraw. Chair 1 is a dedicated,
--     permanent commitment (a levy/bond/functional-zero pledge), not merely "a lot"
--     (chair 2 = a discretionary increase). Chair 5 STOPS public money (chair 4 = a
--     limited amount still flows to private groups who lead).
--
--   RENAME (season-gated, ships with Season 2 only; title/short_title live on the
--     revision, so Season 1 keeps "Homelessness Response"):
--     title       "Homelessness Response" -> "Homelessness Funding"
--     short_title "Homelessness Response" -> "Homelessness Funding"
--     Reason: the sibling topic is "Criminalization of Homelessness" (short
--     "Homelessness"). Two near-identical labels are confusing; "Homelessness Funding"
--     names this topic's new axis and separates the pair. (The compass_topics topic-row
--     label is NOT touched here — it is not season-gated; leave the registry rename as a
--     separate choice if wanted.)
--
--   CURRENT -> NEW (value : text):
--     Q : "What should be your community's primary strategy for addressing homelessness?"
--       -> "How much should your community spend on housing and services to reduce homelessness?"
--     1 : "Housing-first: provide permanent supportive housing with no preconditions; avoid criminalization entirely"
--       -> "Guarantee housing and support services through dedicated, permanent public funding"
--     2 : "Expand shelter capacity and services as the primary strategy; use enforcement only after services are offered"
--       -> "Expand housing and support services by increasing public funding"
--     3 : "Invest in outreach, shelter, and mental health services while enforcing reasonable public space rules"
--       -> "Maintain current housing and service programs at today's funding level, with no major new spending"
--     4 : "Enforce anti-camping ordinances as the primary tool while maintaining basic outreach programs"
--       -> "Provide limited public funding to nonprofits and charities to lead the response, rather than running public programs"
--     5 : "Prioritize strict enforcement of trespassing and camping bans; minimize public spending on homeless services"
--       -> "Withdraw government funding for housing and support services, treating homelessness as a matter for private charity and the market"
--
-- CLASS: substantive -> version 2. rung_map is identity {1:1,2:2,3:3,4:4,5:5}: the
--   re-axis is DIRECTION-PRESERVING (the maximum-public-provision end stays at chair 1,
--   the minimum-public-provision end stays at chair 5 — old chair 5 already read
--   "minimize public spending", which is new chair 5). Identity keeps the eventual
--   Season-2 publish clear of the "moved rung" refusal. It does NOT carry seats:
--   rung_map is user-lens metadata (ADR 0004) for what a returning voter sees about a
--   prior answer, not an answer migration.
--
-- ⚠⚠ DEFERRED RE-AUDIT — OWED BEFORE SEASON 2 OPENS — WHOLE SET ⚠⚠
--   Unlike CA_0071 (chair-5 only), this is a WHOLE-SET re-audit. Every chair's MEANING
--   changed (enforcement posture -> funding posture), so all 440 seated rows
--   (29/176/164/65/6) were evidenced against wording that no longer exists and must be
--   re-read against the funding axis and re-seated from evidence, or blanked.
--     • Expect a heavy reshuffle and MANY honest blanks: enforcement evidence often
--       says nothing about funding posture. The seated count carried into Season 2 will
--       likely be well below 440. A blank spoke beats a guessed chair.
--     • That pass is a SEPARATE, approved migration against politician_answers, and must
--       re-author the per-stance description/supporting_points in the FROZEN legacy
--       compass_stances copy (CA_0012, 0 source reads), whose current prose describes
--       the enforcement axis and now mismatches every chair. The voter-facing revision
--       here is text-only; nothing to restore in this migration.
--   Do NOT open Season 2 on this revision until that whole-set pass is done.
--
-- WHY SAFE NOW: a season's pinned wording is served only for the OPEN season. Season 2
--   is a draft, so this pin changes nothing a voter sees today; Season 1 (open) keeps
--   serving v1 via the version mechanic (it pins version 1; approving a version-2
--   revision does not change what version 1 resolves to). No answer rows are touched.
--
-- Idempotent: re-running after success is a no-op (the revision already exists/approved;
--   Season 2 already pins it).
-- Model: CA_0071 (deportation re-axis), CA_0070 (judicial re-axis: propose substantive
--   + approve + pin S2).
-- =============================================================================

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';               -- Chris Andrews
  v_topic    CONSTANT uuid := '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f';               -- homelessness-response
  v_topickey CONSTANT text := 'homelessness-response';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';               -- Season 2 (draft)
  v_rev1     CONSTANT uuid := 'd39da7dd-d99f-4850-8610-61176c821300';               -- v1 (rev 1, published/current)
  v_stem     CONSTANT text := 'How much should your community spend on housing and services to reduce homelessness?';
  v_chair5   CONSTANT text := 'Withdraw government funding for housing and support services, treating homelessness as a matter for private charity and the market';
  v_rungmap  CONSTANT jsonb := '{"1":1,"2":2,"3":3,"4":4,"5":5}'::jsonb;
  v_stances  CONSTANT jsonb := jsonb_build_array(
    jsonb_build_object('value',1,'text','Guarantee housing and support services through dedicated, permanent public funding'),
    jsonb_build_object('value',2,'text','Expand housing and support services by increasing public funding'),
    jsonb_build_object('value',3,'text','Maintain current housing and service programs at today''s funding level, with no major new spending'),
    jsonb_build_object('value',4,'text','Provide limited public funding to nonprofits and charities to lead the response, rather than running public programs'),
    jsonb_build_object('value',5,'text','Withdraw government funding for housing and support services, treating homelessness as a matter for private charity and the market')
  );
  v_new      uuid;
  v_status   text;
  v_cur      uuid;
BEGIN
  -- Preconditions -----------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_topic AND topic_key = v_topickey) THEN
    RAISE EXCEPTION 'CA_0073: topic id/key mismatch for %', v_topickey;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = v_rev1 AND topic_id = v_topic AND revision = 1 AND version = 1
                   AND is_current AND status = 'published') THEN
    RAISE EXCEPTION 'CA_0073: live v1 (rev 1) is not in the expected published/current state';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season2 AND number = 2 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0073: Season 2 is not a draft (pin would be frozen)';
  END IF;

  -- Step 1: find-or-create the re-axis revision (rev 2 / v2). Idempotent. --------
  SELECT r.id INTO v_new
  FROM inform.compass_topic_revisions r
  WHERE r.topic_id = v_topic
    AND r.change_class = 'substantive'
    AND r.version = 2
    AND r.status IN ('draft','approved')
    AND r.question_text = v_stem
    AND EXISTS (SELECT 1 FROM inform.compass_stance_revisions s
                WHERE s.topic_revision_id = r.id AND s.value = 5 AND s.text = v_chair5);
  IF v_new IS NULL THEN
    v_new := inform.admin_propose_topic_revision(
      v_topickey, v_actor, 'substantive',
      'Homelessness Funding', 'Homelessness Funding',
      v_stem, v_stances,
      -- rationale
      'Single-revision review 2026-08-31 (Chris Andrews). RE-AXIS. As written this topic '
      || 'duplicated the sibling topic ''homelessness'' (Criminalization of Homelessness, S2 q14): both '
      || 'ran one services<->enforcement axis. 271 politicians seated on both, 199 (73%) on the exact same '
      || 'chair, 270/271 (99.6%) within one chair; chair 3 seated identically (164 each). To make them two '
      || 'real questions, ''homelessness'' keeps the enforcement axis and this topic is re-cut onto an '
      || 'independent axis: the size and form of the PUBLIC FUNDING role, from a guaranteed dedicated '
      || 'commitment (chair 1) to withdrawing public money (chair 5). One axis only — enforcement, '
      || 'approach/conditionality and targeting are excluded as separate axes. Endpoints differ in kind not '
      || 'degree (guarantee/expand/maintain/delegate/withdraw). Substantive (version 2): every chair''s '
      || 'meaning changes, so this owes a WHOLE-SET re-audit of all 440 seated rows (29/176/164/65/6) against '
      || 'the funding axis before Season 2 opens — expect heavy reshuffle and many honest blanks. Approved + '
      || 'pinned to Season 2 only; Season 1 stays on v1.',
      -- public_note
      'Reworked this question so it is no longer a near-duplicate of the other homelessness question. It now '
      || 'asks one thing — how much your community should spend on housing and services — with five distinct '
      || 'options from a guaranteed, dedicated commitment to withdrawing public funding. The other homelessness '
      || 'question covers enforcement of public spaces.',
      -- review_ref
      'Single-revision review 2026-08-31 (Chris Andrews), reviewunchangedtopicprompt.md homelessness-response '
      || 'pass; seat distribution 29/176/164/65/6 at chairs 1-5; duplication vs ''homelessness'' 271 shared / '
      || '199 exact-match / 99.6% within one chair.',
      v_rungmap);
    RAISE NOTICE 'CA_0073: proposed re-axis revision %', v_new;
  ELSE
    RAISE NOTICE 'CA_0073: re-axis revision already exists (%); skipping propose.', v_new;
  END IF;

  -- Step 2: approve (draft -> approved), NOT published. Idempotent. --------------
  SELECT status INTO v_status FROM inform.compass_topic_revisions WHERE id = v_new;
  IF v_status = 'draft' THEN
    PERFORM inform.admin_approve_topic_revision(v_new, v_actor);
    RAISE NOTICE 'CA_0073: re-axis revision approved (not published).';
  ELSIF v_status = 'approved' THEN
    RAISE NOTICE 'CA_0073: re-axis revision already approved; skipping approve.';
  ELSE
    RAISE EXCEPTION 'CA_0073: re-axis revision in unexpected status % (expected draft or approved)', v_status;
  END IF;

  -- Step 3: pin Season 2 v1 -> new revision. Idempotent. ------------------------
  SELECT topic_revision_id INTO v_cur FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_cur = v_new THEN
    RAISE NOTICE 'CA_0073: Season 2 already pins the re-axis revision; skipping pin.';
  ELSE
    PERFORM inform.admin_season_pin_revision(v_season2, v_topic, v_new, v_actor);
    RAISE NOTICE 'CA_0073: Season 2 repinned % -> % (re-axis revision)', v_cur, v_new;
  END IF;
END $$;

-- =============================================================================
-- POST-VERIFY
-- =============================================================================
DO $$
DECLARE
  v_topic    CONSTANT uuid := '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_rev1     CONSTANT uuid := 'd39da7dd-d99f-4850-8610-61176c821300';
  v_stem     CONSTANT text := 'How much should your community spend on housing and services to reduce homelessness?';
  v_chair5   CONSTANT text := 'Withdraw government funding for housing and support services, treating homelessness as a matter for private charity and the market';
  v_new      uuid;
  v_status   text;
  v_pub      timestamptz;
  v_iscur    boolean;
  v_rev      int;
  v_ver      int;
  v_class    text;
  v_title    text;
  v_short    text;
  v_n        int;
  v_v1cur    boolean;
  v_v1stat   text;
  v_pin      uuid;
  v_openver  int;
BEGIN
  -- Locate the re-axis revision by stem + chair-5 text.
  SELECT r.id, r.status, r.published_at, r.is_current, r.revision, r.version, r.change_class::text,
         r.title, r.short_title
    INTO v_new, v_status, v_pub, v_iscur, v_rev, v_ver, v_class, v_title, v_short
  FROM inform.compass_topic_revisions r
  WHERE r.topic_id = v_topic AND r.question_text = v_stem
    AND EXISTS (SELECT 1 FROM inform.compass_stance_revisions s
                WHERE s.topic_revision_id = r.id AND s.value = 5 AND s.text = v_chair5);
  IF v_new IS NULL THEN RAISE EXCEPTION 'CA_0073 verify: re-axis revision not found'; END IF;

  IF v_status <> 'approved' THEN RAISE EXCEPTION 'CA_0073 verify: new rev status is % (expected approved)', v_status; END IF;
  IF v_title <> 'Homelessness Funding' THEN RAISE EXCEPTION 'CA_0073 verify: new rev title is % (expected Homelessness Funding)', v_title; END IF;
  IF v_short IS DISTINCT FROM 'Homelessness Funding' THEN RAISE EXCEPTION 'CA_0073 verify: new rev short_title is % (expected Homelessness Funding)', v_short; END IF;
  IF v_pub IS NOT NULL THEN RAISE EXCEPTION 'CA_0073 verify: new rev has published_at (must stay unpublished)'; END IF;
  IF v_iscur THEN RAISE EXCEPTION 'CA_0073 verify: new rev is_current is true (must stay false until Season 2 opens)'; END IF;
  IF v_rev <> 2 THEN RAISE EXCEPTION 'CA_0073 verify: new rev revision is % (expected 2)', v_rev; END IF;
  IF v_ver <> 2 THEN RAISE EXCEPTION 'CA_0073 verify: new rev version is % (expected 2)', v_ver; END IF;
  IF v_class <> 'substantive' THEN RAISE EXCEPTION 'CA_0073 verify: new rev change_class is % (expected substantive)', v_class; END IF;

  -- Exactly five rungs, all carrying the reviewed NEW text.
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions WHERE topic_revision_id = v_new;
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0073 verify: new rev has % rungs (expected 5)', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions s WHERE s.topic_revision_id = v_new AND (
       (s.value = 1 AND s.text = 'Guarantee housing and support services through dedicated, permanent public funding')
    OR (s.value = 2 AND s.text = 'Expand housing and support services by increasing public funding')
    OR (s.value = 3 AND s.text = 'Maintain current housing and service programs at today''s funding level, with no major new spending')
    OR (s.value = 4 AND s.text = 'Provide limited public funding to nonprofits and charities to lead the response, rather than running public programs')
    OR (s.value = 5 AND s.text = 'Withdraw government funding for housing and support services, treating homelessness as a matter for private charity and the market'));
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0073 verify: new rev rungs do not all match the reviewed wording (matched %)', v_n; END IF;

  -- No enforcement-axis wording leaked into the new (funding) revision.
  IF EXISTS (SELECT 1 FROM inform.compass_stance_revisions s WHERE s.topic_revision_id = v_new
             AND (s.text ILIKE '%enforc%' OR s.text ILIKE '%camping%' OR s.text ILIKE '%trespass%'
               OR s.text ILIKE '%criminaliz%' OR s.text ILIKE '%housing-first%'
               OR s.text ILIKE '%public space%' OR s.text ILIKE '%shelter capacity%')) THEN
    RAISE EXCEPTION 'CA_0073 verify: new rev still carries enforcement-axis wording';
  END IF;
  IF v_stem ILIKE '%primary strategy%' THEN
    RAISE EXCEPTION 'CA_0073 verify: new question still carries old "primary strategy" wording';
  END IF;

  -- v1 still the published/current revision, and exactly one such.
  SELECT is_current, status INTO v_v1cur, v_v1stat FROM inform.compass_topic_revisions WHERE id = v_rev1;
  IF NOT v_v1cur THEN RAISE EXCEPTION 'CA_0073 verify: v1 is no longer is_current'; END IF;
  IF v_v1stat <> 'published' THEN RAISE EXCEPTION 'CA_0073 verify: v1 status is % (expected published)', v_v1stat; END IF;
  IF (SELECT count(*) FROM inform.compass_topic_revisions
       WHERE topic_id = v_topic AND is_current = true AND status = 'published') <> 1 THEN
    RAISE EXCEPTION 'CA_0073 verify: expected exactly 1 published/current revision (still v1)';
  END IF;

  -- Season 2 pins the new revision.
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_pin <> v_new THEN RAISE EXCEPTION 'CA_0073 verify: Season 2 pin is % (expected new rev %)', v_pin, v_new; END IF;

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
    RAISE EXCEPTION 'CA_0073 verify: open season resolves version % (expected 1)', v_openver;
  END IF;

  RAISE NOTICE 'CA_0073 post-verify OK: re-axis rev 2/v2 approved (unpublished); Season 2 pins it; Season 1 still serves v1. WHOLE-SET 440-row re-audit deferred before Season 2 opens.';
END $$;

COMMIT;
