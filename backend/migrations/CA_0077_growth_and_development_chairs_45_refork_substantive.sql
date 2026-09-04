BEGIN;

-- =============================================================================
-- CA_0077: Growth and Development Pace (growth-and-development) — reword the five
--          chairs into plain voter-facing language and de-barrel chairs 1 and 4
--          (chairs 1-3, clarifying), and re-cut the chair 4/5 boundary off
--          "how much deregulation" (a magnitude rating) onto a real policy fork —
--          actively promote growth WITH guardrails vs step back and let the market
--          set the pace (substantive), approve the new revision, and pin it into
--          Season 2 (a DRAFT; NOT open).
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
--
-- TOPIC fb25c1ac-… ('growth-and-development', "Growth and Development Pace").
--   Scope: local + state (both required). 429 seated rows on the OPEN Season-1 v1
--   today (18/113/196/96/6 at chairs 1/2/3/4/5). This topic is ALSO carried by
--   Season 2 (draft), which pins the same v1 today. Reviewed 2026-08-31 under the
--   single-revision ("unchanged") review pass.
--
-- WHAT THIS DOES — three metadata steps, NO answer/context rows written:
--   1. PROPOSE a new substantive revision (becomes rev 2 / version 2) with the
--      reviewed five chairs. The QUESTION IS UNCHANGED.
--   2. APPROVE it (draft -> approved). NOT published: a substantive rewrite goes
--      live only when its bound season opens, so is_current stays false and
--      published_at stays NULL.
--   3. PIN Season 2 (86d893a1-…, a DRAFT) from v1 (rev 1, aafe1e1c-…) to the new
--      revision. Season 1 (OPEN) is left on v1 — nothing a voter sees today moves.
--
-- THE EDIT THAT DROVE THIS (review 2026-08-31, Chris Andrews):
--   • ONE axis, and it holds: how permissive government is of the PACE of growth,
--     from "actively restrain" (chair 1) to "step back, market sets the pace"
--     (chair 5). This is a PACE spine, NOT a government-size spine — public spending
--     PEAKS in the middle (chair 3, invest ahead), while chair 1's action is
--     regulatory restraint and chair 5's is withdrawal. So "chair 1 = most
--     government" is FALSE here (the off-axis trap flagged in CLAUDE.md). The spine
--     is coherent as pace-permissiveness; regulation restrains at chair 1 and
--     deregulation accelerates at chair 5 (opposite mechanisms at opposite poles),
--     so NO re-axis is needed (unlike local-environment). Mechanism (regulation /
--     public investment / deregulation) is placing-EVIDENCE, not the rung's claim.
--   • Chairs 1-3 were reworded into plain language and de-barreled where they welded
--     separable policies (chair 1 welded a growth cap with a voter-referendum
--     requirement). SAME positions, clearer words — CLARIFYING, so their seats
--     (18/113/196) carry forward with NO re-audit, per the 2026-08-28 rewording
--     ruling.
--   • Old chair 4 was a triple double-barrel welding deregulation ("streamline
--     permitting, reduce fees") with active subsidy ("actively recruit development")
--     — two mechanisms pulling opposite ways. Old chairs 4 and 5 were separated only
--     by MAGNITUDE ("reduce fees" vs "remove barriers ENTIRELY / let market decide")
--     — a strength rating, not a distinct position: only 6 of 429 seats ever reached
--     chair 5. Re-cut onto a real fork a source can state: chair 4 = government
--     actively pushes growth but KEEPS GUARDRAILS; chair 5 = government STEPS BACK
--     and the market sets the pace (constraints removed beyond basic health/safety).
--
--   CURRENT -> NEW (value : text):
--     Q : (UNCHANGED) "How should government manage population growth and new development?"
--     1 : "Impose growth limits; require voter approval for major annexations or large-scale developments"
--       -> "Hold the pace of growth down — cap major new development, and let residents vote directly on the largest projects."
--     2 : "Allow growth only where existing infrastructure can support it; slow approvals until capacity catches up"
--       -> "Allow growth only as fast as current infrastructure can handle — make new development wait for capacity."
--     3 : "Plan proactively — invest in infrastructure ahead of growth to support responsible expansion"
--       -> "Welcome steady growth — invest in roads, water and schools ahead of demand so expansion isn''t held back."
--     4 : "Streamline permitting, reduce fees, and actively recruit development to grow the tax base"
--       -> "Actively push for faster growth — cut red tape and recruit new development, while keeping basic guardrails."
--     5 : "Remove regulatory barriers to development entirely; let market demand determine growth pace"
--       -> "Step back and let the market set the pace — remove development constraints beyond basic health and safety."
--
-- CLASS: substantive -> version 2. rung_map is identity {1:1,2:2,3:3,4:4,5:5}: the
--   five positions stay in order (restrain most at 1, market-led at 5); chairs 4 and
--   5 are reworded in place, they do not move rung.
--
-- ⚠⚠ DEFERRED RE-AUDIT — OWED BEFORE SEASON 2 OPENS ⚠⚠
--   This is NOT a whole-set re-audit. Chairs 1-3 changed only their WORDING, not
--   their meaning, so their seats (18/113/196) carry forward with NO re-audit.
--   Only CHAIRS 4 and 5 move meaning (the boundary between them is re-cut from
--   magnitude to conditionality — keep guardrails vs step back), so their seats are
--   the re-audit scope:
--     • CHAIR 5 — 6 seated rows — MUST be re-read against "step back, market sets
--       the pace": confirm each person really holds the hands-off/market-led
--       position and was not just seated for being "pro-development" (which now maps
--       to chair 4).
--     • CHAIR 4 — 96 seated rows — SCAN for anyone who actually holds the hands-off
--       "remove all rules / market decides" position who should migrate UP to chair 5.
--   Do NOT open Season 2 on this revision until that 6-row read (+ 96-row chair-4
--   scan) is done. That is a SEPARATE, approved migration against politician_answers.
--   (Per-stance description/supporting_points live in the FROZEN legacy
--   compass_stances copy, 0 source reads; the voter-facing revision is text-only,
--   nothing to restore here. The legacy chair 4/5 descriptions now mismatch the new
--   wording but are dormant — leave them.)
--
-- WHY SAFE NOW: a season's pinned wording is served only for the OPEN season.
--   Season 2 is a draft, so this pin changes nothing a voter sees today; Season 1
--   (open) keeps serving v1 via the version mechanic (it pins version 1; approving a
--   version-2 revision does not change what version 1 resolves to). No answer rows
--   are touched. NOTE: because the CLARIFYING plain-language edits on chairs 1-3 are
--   bundled into this version-2 revision, they reach voters only when Season 2 opens
--   — Season 1 keeps the old wording. That is intended (this is Season-2 prep; Option
--   A). If the plain 1-3 wording is wanted live in Season 1 too, that needs a
--   separate clarifying v1 revision.
--
-- Idempotent: re-running after success is a no-op (the revision already
--   exists/approved; Season 2 already pins it).
-- Model: CA_0072 (propose substantive + approve + pin S2); question here is
--   UNCHANGED, so the revision is located by its NEW chair-5 text, not by the stem.
-- =============================================================================

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';               -- Chris Andrews
  v_topic    CONSTANT uuid := 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4';               -- growth-and-development
  v_topickey CONSTANT text := 'growth-and-development';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';               -- Season 2 (draft)
  v_rev1     CONSTANT uuid := 'aafe1e1c-8855-45b3-9986-740381f45228';               -- v1 (rev 1, published/current)
  v_stem     CONSTANT text := 'How should government manage population growth and new development?';
  v_chair5   CONSTANT text := 'Step back and let the market set the pace — remove development constraints beyond basic health and safety.';
  v_rungmap  CONSTANT jsonb := '{"1":1,"2":2,"3":3,"4":4,"5":5}'::jsonb;
  v_stances  CONSTANT jsonb := jsonb_build_array(
    jsonb_build_object('value',1,'text','Hold the pace of growth down — cap major new development, and let residents vote directly on the largest projects.'),
    jsonb_build_object('value',2,'text','Allow growth only as fast as current infrastructure can handle — make new development wait for capacity.'),
    jsonb_build_object('value',3,'text','Welcome steady growth — invest in roads, water and schools ahead of demand so expansion isn''t held back.'),
    jsonb_build_object('value',4,'text','Actively push for faster growth — cut red tape and recruit new development, while keeping basic guardrails.'),
    jsonb_build_object('value',5,'text','Step back and let the market set the pace — remove development constraints beyond basic health and safety.')
  );
  v_new      uuid;
  v_status   text;
  v_cur      uuid;
BEGIN
  -- Preconditions -----------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_topic AND topic_key = v_topickey) THEN
    RAISE EXCEPTION 'CA_0077: topic id/key mismatch for %', v_topickey;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = v_rev1 AND topic_id = v_topic AND revision = 1 AND version = 1
                   AND is_current AND status = 'published') THEN
    RAISE EXCEPTION 'CA_0077: live v1 (rev 1) is not in the expected published/current state';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season2 AND number = 2 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0077: Season 2 is not a draft (pin would be frozen)';
  END IF;

  -- Step 1: find-or-create the re-fork revision (rev 2 / v2). Idempotent. --------
  -- Located by chair-5 NEW text (the question is unchanged, so it cannot discriminate).
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
      'Growth and Development Pace', 'Growth and Development Pace',
      v_stem, v_stances,
      -- rationale
      'Single-revision review 2026-08-31 (Chris Andrews). The ladder is ONE coherent axis — how '
      || 'permissive government is of the PACE of growth, from actively restrain (chair 1) to step back / '
      || 'market-led (chair 5). It is a pace spine, NOT a government-size spine: public spending peaks in '
      || 'the middle (chair 3 invests ahead), chair 1 restrains via regulation and chair 5 withdraws, so '
      || 'chair 1 is NOT "most government". Opposite mechanisms at opposite poles (regulation at 1, '
      || 'deregulation at 5) confirm the spine holds — no re-axis. Chairs 1-3 reworded into plain language '
      || 'and chair 1 de-barreled (it welded a growth cap with a voter-referendum requirement); same '
      || 'positions, clearer words — CLARIFYING, so their 18/113/196 seats carry forward. Old chair 4 was a '
      || 'triple double-barrel welding deregulation (streamline permitting, reduce fees) with active subsidy '
      || '(actively recruit) — mechanisms pulling opposite ways; and old chairs 4 and 5 were separated only '
      || 'by magnitude (reduce fees vs remove barriers ENTIRELY / market decides), a strength rating that '
      || 'left chair 5 a 6-of-429 caricature. Re-cut onto a real fork: chair 4 = actively push growth but '
      || 'KEEP GUARDRAILS; chair 5 = step back, market sets the pace (constraints removed beyond basic '
      || 'health/safety). Substantive (version 2) because chairs 4 and 5 move meaning; their re-audit scope '
      || 'is chair 5 (6 rows re-read) + a chair-4 hands-off-migrant scan (96 rows), owed before Season 2 '
      || 'opens. Question unchanged. Approved + pinned to Season 2 only; Season 1 stays on v1.',
      -- public_note
      'Rewrote the five options in plainer language, and fixed the two most pro-growth options so they '
      || 'describe a real difference — actively push growth but keep basic guardrails, vs step back and let '
      || 'the market set the pace — instead of just "reduce fees" vs "remove all rules".',
      -- review_ref
      'Single-revision review 2026-08-31 (Chris Andrews), reviewunchangedtopicprompt.md growth-and-development '
      || 'pass; seat distribution 18/113/196/96/6 at chairs 1-5 (429 total).',
      v_rungmap);
    RAISE NOTICE 'CA_0077: proposed re-fork revision %', v_new;
  ELSE
    RAISE NOTICE 'CA_0077: re-fork revision already exists (%); skipping propose.', v_new;
  END IF;

  -- Step 2: approve (draft -> approved), NOT published. Idempotent. --------------
  SELECT status INTO v_status FROM inform.compass_topic_revisions WHERE id = v_new;
  IF v_status = 'draft' THEN
    PERFORM inform.admin_approve_topic_revision(v_new, v_actor);
    RAISE NOTICE 'CA_0077: re-fork revision approved (not published).';
  ELSIF v_status = 'approved' THEN
    RAISE NOTICE 'CA_0077: re-fork revision already approved; skipping approve.';
  ELSE
    RAISE EXCEPTION 'CA_0077: re-fork revision in unexpected status % (expected draft or approved)', v_status;
  END IF;

  -- Step 3: pin Season 2 v1 -> new revision. Idempotent. ------------------------
  SELECT topic_revision_id INTO v_cur FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_cur = v_new THEN
    RAISE NOTICE 'CA_0077: Season 2 already pins the re-fork revision; skipping pin.';
  ELSE
    PERFORM inform.admin_season_pin_revision(v_season2, v_topic, v_new, v_actor);
    RAISE NOTICE 'CA_0077: Season 2 repinned % -> % (re-fork revision)', v_cur, v_new;
  END IF;
END $$;

-- =============================================================================
-- POST-VERIFY
-- =============================================================================
DO $$
DECLARE
  v_topic    CONSTANT uuid := 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_rev1     CONSTANT uuid := 'aafe1e1c-8855-45b3-9986-740381f45228';
  v_stem     CONSTANT text := 'How should government manage population growth and new development?';
  v_chair5   CONSTANT text := 'Step back and let the market set the pace — remove development constraints beyond basic health and safety.';
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
  -- Locate the re-fork revision by its NEW chair-5 text (question is unchanged).
  SELECT r.id, r.status, r.published_at, r.is_current, r.revision, r.version, r.change_class::text, r.question_text
    INTO v_new, v_status, v_pub, v_iscur, v_rev, v_ver, v_class, v_qtext
  FROM inform.compass_topic_revisions r
  WHERE r.topic_id = v_topic
    AND EXISTS (SELECT 1 FROM inform.compass_stance_revisions s
                WHERE s.topic_revision_id = r.id AND s.value = 5 AND s.text = v_chair5);
  IF v_new IS NULL THEN RAISE EXCEPTION 'CA_0077 verify: re-fork revision not found'; END IF;

  IF v_status <> 'approved' THEN RAISE EXCEPTION 'CA_0077 verify: new rev status is % (expected approved)', v_status; END IF;
  IF v_pub IS NOT NULL THEN RAISE EXCEPTION 'CA_0077 verify: new rev has published_at (must stay unpublished)'; END IF;
  IF v_iscur THEN RAISE EXCEPTION 'CA_0077 verify: new rev is_current is true (must stay false until Season 2 opens)'; END IF;
  IF v_rev <> 2 THEN RAISE EXCEPTION 'CA_0077 verify: new rev revision is % (expected 2)', v_rev; END IF;
  IF v_ver <> 2 THEN RAISE EXCEPTION 'CA_0077 verify: new rev version is % (expected 2)', v_ver; END IF;
  IF v_class <> 'substantive' THEN RAISE EXCEPTION 'CA_0077 verify: new rev change_class is % (expected substantive)', v_class; END IF;
  IF v_qtext <> v_stem THEN RAISE EXCEPTION 'CA_0077 verify: new rev question_text changed (expected unchanged stem)'; END IF;

  -- Exactly five rungs, all carrying the reviewed NEW text.
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions WHERE topic_revision_id = v_new;
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0077 verify: new rev has % rungs (expected 5)', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions s WHERE s.topic_revision_id = v_new AND (
       (s.value = 1 AND s.text = 'Hold the pace of growth down — cap major new development, and let residents vote directly on the largest projects.')
    OR (s.value = 2 AND s.text = 'Allow growth only as fast as current infrastructure can handle — make new development wait for capacity.')
    OR (s.value = 3 AND s.text = 'Welcome steady growth — invest in roads, water and schools ahead of demand so expansion isn''t held back.')
    OR (s.value = 4 AND s.text = 'Actively push for faster growth — cut red tape and recruit new development, while keeping basic guardrails.')
    OR (s.value = 5 AND s.text = 'Step back and let the market set the pace — remove development constraints beyond basic health and safety.'));
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0077 verify: new rev rungs do not all match the reviewed wording (matched %)', v_n; END IF;

  -- No old wording leaked into the new revision.
  IF EXISTS (SELECT 1 FROM inform.compass_stance_revisions s WHERE s.topic_revision_id = v_new
             AND (s.text ILIKE '%voter approval%' OR s.text ILIKE '%annexation%'
               OR s.text ILIKE '%capacity catches up%' OR s.text ILIKE '%Plan proactively%'
               OR s.text ILIKE '%responsible expansion%' OR s.text ILIKE '%Streamline permitting%'
               OR s.text ILIKE '%reduce fees%' OR s.text ILIKE '%grow the tax base%'
               OR s.text ILIKE '%regulatory barriers%' OR s.text ILIKE '%market demand%')) THEN
    RAISE EXCEPTION 'CA_0077 verify: new rev still carries old chair wording';
  END IF;

  -- v1 still the published/current revision, and exactly one such.
  SELECT is_current, status INTO v_v1cur, v_v1stat FROM inform.compass_topic_revisions WHERE id = v_rev1;
  IF NOT v_v1cur THEN RAISE EXCEPTION 'CA_0077 verify: v1 is no longer is_current'; END IF;
  IF v_v1stat <> 'published' THEN RAISE EXCEPTION 'CA_0077 verify: v1 status is % (expected published)', v_v1stat; END IF;
  IF (SELECT count(*) FROM inform.compass_topic_revisions
       WHERE topic_id = v_topic AND is_current = true AND status = 'published') <> 1 THEN
    RAISE EXCEPTION 'CA_0077 verify: expected exactly 1 published/current revision (still v1)';
  END IF;

  -- Season 2 pins the new revision.
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_pin <> v_new THEN RAISE EXCEPTION 'CA_0077 verify: Season 2 pin is % (expected new rev %)', v_pin, v_new; END IF;

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
    RAISE EXCEPTION 'CA_0077 verify: open season resolves version % (expected 1)', v_openver;
  END IF;

  RAISE NOTICE 'CA_0077 post-verify OK: re-fork rev 2/v2 approved (unpublished); Season 2 pins it; Season 1 still serves v1. Chair 5 6-row re-read (+96-row chair-4 scan) deferred before Season 2 opens.';
END $$;

COMMIT;
