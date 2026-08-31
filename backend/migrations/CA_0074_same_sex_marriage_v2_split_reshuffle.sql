BEGIN;

-- =============================================================================
-- CA_0074: Same-Sex Marriage (same-sex-marriage) — split the pro-equality pole
--          into two rungs, drop the off-axis "let each state decide" rung, move
--          the religious-exemption rung down a slot, capitalise all five chairs,
--          approve the new revision, and pin it into Season 2 (a DRAFT; NOT open).
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
--
-- TOPIC c5ab4eab-… ('same-sex-marriage', "Same-Sex Marriage"). Scope: federal +
--   state (both required). Season-2 question #36. 901 seated rows on the open
--   Season-1 v1 today (494/145/28/61/173 at chairs 1/2/3/4/5). Reviewed 2026-08-31
--   under the single-revision ("unchanged") review pass.
--
-- WHAT THIS DOES — three metadata steps, NO answer/context rows written:
--   1. PROPOSE a new substantive revision (becomes rev 2 / version 2) with the
--      reviewed question (UNCHANGED) + five re-shuffled chairs.
--   2. APPROVE it (draft -> approved). NOT published: a substantive rewrite goes
--      live only when its bound season opens, so is_current stays false and
--      published_at stays NULL.
--   3. PIN Season 2 (86d893a1-…, a DRAFT) from v1 (rev 1, 5d26a058-…) to the new
--      revision. Season 1 (open) is left on v1.
--
-- THE REVIEW THAT DROVE THE EDIT (single-revision review 2026-08-31, Chris Andrews):
--   • ONE SPECTRUM (check 1): old chair 3 ("let each state decide … without federal
--     interference") measured WHO decides (federalism), not HOW MUCH legal recognition
--     the marriage receives. A pro-equality federalist and an anti-equality federalist
--     both landed there for opposite reasons — the orthogonal-rung signature. That rung
--     is REMOVED; the ladder is re-axed onto one spine: degree of legal equality, from
--     full civil equality (chair 1) down to a legal ban (chair 5).
--   • SEAT PILE-UP: old chair 1 held 494 of 901 seats (55%) — one rung doing more than
--     half the work, i.e. the pro-equality side was under-resolved. It is split into two
--     distinct, evidence-able positions: chair 1 = full civil equality (marriage PLUS
--     protection from discrimination — the Equality-Act scope); chair 2 = marriage
--     equality alone (equal benefits and protections, nothing broader). The fork is the
--     SCOPE of legal equality, not "how strongly" — a source can state either.
--   • Old chair 2 (marriage + religious-organisation exemption) keeps its meaning but
--     moves to slot 3, and is made explicit ("religious organizations' right to decline
--     to perform or host these marriages") so it excludes chair 2 cleanly.
--   • Chairs 4 (civil unions) and 5 (ban) keep their meaning and slots.
--   • All five chairs are capitalised, matching the 33-of-48-topic majority convention
--     (same-sex-marriage was one of 15 lowercase stragglers).
--
--   CURRENT -> NEW (value : text):
--     Q (UNCHANGED): "What legal recognition should same-sex marriages receive?"
--     old 1 "require all states to recognize same-sex marriages and provide full federal
--            benefits and protections."
--       -> new 2 "Guarantee same-sex marriage the same benefits and protections as any
--                 other marriage."   (reworded; same core position — see rung_map old1->2)
--     new 1 (NEW, opens empty): "Guarantee same-sex couples full legal equality — equal
--            marriage plus protection from discrimination (such as in jobs and housing)."
--     old 2 "allow same-sex marriage nationwide while protecting some organizations'
--            right to decline participation."
--       -> new 3 "Allow same-sex marriage, but protect religious organizations' right to
--                 decline to perform or host these marriages."   (rung_map old2->3)
--     old 3 "let each state decide its own same-sex marriage laws without federal
--            interference."
--       -> REMOVED (rung_map old3->"invalidated")
--     old 4 "recognize civil unions for same-sex couples but reserve marriage for
--            opposite-sex couples."
--       -> new 4 "Recognize civil unions for same-sex couples, but reserve marriage for
--                 opposite-sex couples."   (capitalised; unchanged meaning)
--     old 5 "make same-sex marriage illegal and define marriage as only between one man
--            and one woman."
--       -> new 5 "Make same-sex marriage illegal and define marriage as only between one
--                 man and one woman."   (capitalised; unchanged meaning)
--
-- CLASS: substantive -> version 2. rung_map (keys = OLD rungs, values = NEW rung; ADR
--   0004 §4): {"1":2,"2":3,"3":"invalidated","4":4,"5":5}. New chair 1 has NO old source
--   and opens EMPTY — it is populated only by the re-audit, never by a mechanical carry.
--
-- ⚠⚠ DEFERRED RE-AUDIT — OWED BEFORE SEASON 2 OPENS ⚠⚠
--   The rung_map is a mechanical carry, not a verdict. Human-read scope ≈ 522 rows:
--     • old chair 1 (494) mechanically carries to new 2. The re-audit READS all 494 and
--       pulls up to new 1 those whose evidence supports full civil equality
--       (broad anti-discrimination protection), not marriage recognition alone. If few
--       carry evidence beyond marriage itself, new chair 1 stays sparse — reconsider the
--       split then.
--     • old chair 3 (28, states-decide) is INVALIDATED (blanked). The re-audit READS
--       each to its true position on the new spine (many -> new 3/4/5, or an honest
--       blank). A "leave it to the states" quote does not by itself place a chair.
--     • old chair 2 (145) -> new 3, old chair 4 (61) -> new 4, old chair 5 (173) -> new 5
--       keep their meaning: mechanical carry, spot-check only, no full read.
--   Do NOT open Season 2 on this revision until that ~522-row pass is done. It is a
--   SEPARATE, approved migration against politician_answers. Run
--   `node scripts/audit-chair-evidence.mjs` on it.
--   (Per-stance description/supporting_points live in the FROZEN legacy compass_stances
--   copy, 0 source reads; the voter-facing revision is text-only, nothing to restore
--   here. The legacy descriptions now mismatch the new wording but are dormant — leave
--   them.)
--
-- WHY SAFE NOW: a season's pinned wording is served only for the OPEN season. Season 2
--   is a draft, so this pin changes nothing a voter sees today; Season 1 (open) keeps
--   serving v1 via the version mechanic (it pins version 1; approving a version-2
--   revision does not change what version 1 resolves to). No answer rows are touched.
--   NOTE: the question text is unchanged, and chairs 4/5 change only capitalisation, but
--   because those edits are bundled into this version-2 revision they reach voters only
--   when Season 2 opens — Season 1 keeps the old lowercase wording. That is intended
--   (this is Season-2 prep).
--
-- Idempotent: re-running after success is a no-op (the revision already exists/approved;
--   Season 2 already pins it), guarded on the NEW chair-1 text.
-- Model: CA_0043 (reshuffle + rung_map + new empty chair + "invalidated"), CA_0071
--   (propose substantive + approve + pin S2).
-- =============================================================================

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';               -- Chris Andrews
  v_topic    CONSTANT uuid := 'c5ab4eab-702f-49b8-9277-8ea53f3835c6';               -- same-sex-marriage
  v_topickey CONSTANT text := 'same-sex-marriage';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';               -- Season 2 (draft)
  v_rev1     CONSTANT uuid := '5d26a058-0678-449e-ab76-85a31562c1f1';               -- v1 (rev 1, published/current)
  v_stem     CONSTANT text := 'What legal recognition should same-sex marriages receive?';
  v_chair1   CONSTANT text := 'Guarantee same-sex couples full legal equality — equal marriage plus protection from discrimination (such as in jobs and housing).';
  v_rungmap  CONSTANT jsonb := '{"1":2,"2":3,"3":"invalidated","4":4,"5":5}'::jsonb;
  v_stances  CONSTANT jsonb := jsonb_build_array(
    jsonb_build_object('value',1,'text','Guarantee same-sex couples full legal equality — equal marriage plus protection from discrimination (such as in jobs and housing).'),
    jsonb_build_object('value',2,'text','Guarantee same-sex marriage the same benefits and protections as any other marriage.'),
    jsonb_build_object('value',3,'text','Allow same-sex marriage, but protect religious organizations'' right to decline to perform or host these marriages.'),
    jsonb_build_object('value',4,'text','Recognize civil unions for same-sex couples, but reserve marriage for opposite-sex couples.'),
    jsonb_build_object('value',5,'text','Make same-sex marriage illegal and define marriage as only between one man and one woman.')
  );
  v_new      uuid;
  v_open     int;
  v_status   text;
  v_cur      uuid;
BEGIN
  -- Preconditions -----------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_topic AND topic_key = v_topickey) THEN
    RAISE EXCEPTION 'CA_0074: topic id/key mismatch for %', v_topickey;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = v_rev1 AND topic_id = v_topic AND revision = 1 AND version = 1
                   AND is_current AND status = 'published') THEN
    RAISE EXCEPTION 'CA_0074: live v1 (rev 1) is not in the expected published/current state';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season2 AND number = 2 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0074: Season 2 is not a draft (pin would be frozen)';
  END IF;

  -- Step 1: find-or-create the reshuffle revision (rev 2 / v2). Idempotent. -------
  SELECT r.id INTO v_new
  FROM inform.compass_topic_revisions r
  WHERE r.topic_id = v_topic
    AND r.change_class = 'substantive'
    AND r.version = 2
    AND r.status IN ('draft','approved')
    AND EXISTS (SELECT 1 FROM inform.compass_stance_revisions s
                WHERE s.topic_revision_id = r.id AND s.value = 1 AND s.text = v_chair1);
  IF v_new IS NULL THEN
    -- Do not create a second competing draft: assert no OTHER open revision exists.
    SELECT count(*) INTO v_open FROM inform.compass_topic_revisions
     WHERE topic_id = v_topic AND status IN ('draft','approved');
    IF v_open <> 0 THEN
      RAISE EXCEPTION 'CA_0074: an unexpected open (draft/approved) revision exists (%); resolve before proposing', v_open;
    END IF;
    v_new := inform.admin_propose_topic_revision(
      v_topickey, v_actor, 'substantive',
      'Same-Sex Marriage', 'Same-Sex Marriage',
      v_stem, v_stances,
      -- rationale
      'Single-revision review 2026-08-31 (Chris Andrews). Two structural fixes plus a styling sweep. '
      || '(1) ONE SPECTRUM: old chair 3 ("let each state decide … without federal interference") measured WHO '
      || 'decides, not how much recognition the marriage receives, so pro- and anti-equality federalists both '
      || 'landed there for opposite reasons; that off-axis rung is removed and the ladder re-axed onto a single '
      || 'degree-of-legal-equality spine. (2) PILE-UP: old chair 1 held 494 of 901 seats (55%); it is split into '
      || 'two evidence-able rungs — new chair 1 = full civil equality (marriage plus anti-discrimination '
      || 'protection), new chair 2 = marriage equality alone. The fork is the SCOPE of equality, not "how '
      || 'strongly". Old chair 2 (religious-organisation exemption) keeps its meaning, moves to slot 3, and is '
      || 'made explicit. Chairs 4 (civil unions) and 5 (ban) keep meaning and slot; all five capitalised. '
      || 'Substantive (version 2): a new rung is inserted and one rung removed, so the value axis re-indexes. '
      || 'rung_map {"1":2,"2":3,"3":"invalidated","4":4,"5":5}; new chair 1 opens empty. Re-audit scope ≈ 522 '
      || 'human-read rows (494 old-chair-1 split + 28 invalidated states-decide), owed before Season 2 opens; '
      || 'old chairs 2/4/5 carry mechanically. Approved + pinned to Season 2 only; Season 1 stays on v1.',
      -- public_note
      'Reworked the options so they measure one thing — how much legal equality same-sex marriage should have — '
      || 'and split the top choice into two: full legal equality including protection from discrimination, and '
      || 'equal marriage benefits on their own. Removed the "leave it to each state" option, which mixed in a '
      || 'separate question about who decides. The religious-exemption option is now clearer, and civil unions '
      || 'and a ban remain as the lower options.',
      -- review_ref
      'Single-revision review 2026-08-31 (Chris Andrews), reviewunchangedtopicprompt.md same-sex-marriage pass; '
      || 'seat distribution 494/145/28/61/173 at chairs 1-5.',
      v_rungmap);
    RAISE NOTICE 'CA_0074: proposed reshuffle revision %', v_new;
  ELSE
    RAISE NOTICE 'CA_0074: reshuffle revision already exists (%); skipping propose.', v_new;
  END IF;

  -- Step 2: approve (draft -> approved), NOT published. Idempotent. --------------
  SELECT status INTO v_status FROM inform.compass_topic_revisions WHERE id = v_new;
  IF v_status = 'draft' THEN
    PERFORM inform.admin_approve_topic_revision(v_new, v_actor);
    RAISE NOTICE 'CA_0074: reshuffle revision approved (not published).';
  ELSIF v_status = 'approved' THEN
    RAISE NOTICE 'CA_0074: reshuffle revision already approved; skipping approve.';
  ELSE
    RAISE EXCEPTION 'CA_0074: reshuffle revision in unexpected status % (expected draft or approved)', v_status;
  END IF;

  -- Step 3: pin Season 2 v1 -> new revision. Idempotent. ------------------------
  SELECT topic_revision_id INTO v_cur FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_cur = v_new THEN
    RAISE NOTICE 'CA_0074: Season 2 already pins the reshuffle revision; skipping pin.';
  ELSE
    PERFORM inform.admin_season_pin_revision(v_season2, v_topic, v_new, v_actor);
    RAISE NOTICE 'CA_0074: Season 2 repinned % -> % (reshuffle revision)', v_cur, v_new;
  END IF;
END $$;

-- =============================================================================
-- POST-VERIFY
-- =============================================================================
DO $$
DECLARE
  v_topic    CONSTANT uuid := 'c5ab4eab-702f-49b8-9277-8ea53f3835c6';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_rev1     CONSTANT uuid := '5d26a058-0678-449e-ab76-85a31562c1f1';
  v_stem     CONSTANT text := 'What legal recognition should same-sex marriages receive?';
  v_chair1   CONSTANT text := 'Guarantee same-sex couples full legal equality — equal marriage plus protection from discrimination (such as in jobs and housing).';
  v_rungmap  CONSTANT jsonb := '{"1":2,"2":3,"3":"invalidated","4":4,"5":5}'::jsonb;
  v_new      uuid;
  v_status   text;
  v_pub      timestamptz;
  v_iscur    boolean;
  v_rev      int;
  v_ver      int;
  v_class    text;
  v_map      jsonb;
  v_qtext    text;
  v_n        int;
  v_v1cur    boolean;
  v_v1stat   text;
  v_pin      uuid;
  v_openver  int;
BEGIN
  -- Locate the reshuffle revision by the NEW chair-1 text (unique to v2).
  SELECT r.id, r.status, r.published_at, r.is_current, r.revision, r.version,
         r.change_class::text, r.rung_map, r.question_text
    INTO v_new, v_status, v_pub, v_iscur, v_rev, v_ver, v_class, v_map, v_qtext
  FROM inform.compass_topic_revisions r
  WHERE r.topic_id = v_topic
    AND EXISTS (SELECT 1 FROM inform.compass_stance_revisions s
                WHERE s.topic_revision_id = r.id AND s.value = 1 AND s.text = v_chair1);
  IF v_new IS NULL THEN RAISE EXCEPTION 'CA_0074 verify: reshuffle revision not found'; END IF;

  IF v_status <> 'approved' THEN RAISE EXCEPTION 'CA_0074 verify: new rev status is % (expected approved)', v_status; END IF;
  IF v_pub IS NOT NULL THEN RAISE EXCEPTION 'CA_0074 verify: new rev has published_at (must stay unpublished)'; END IF;
  IF v_iscur THEN RAISE EXCEPTION 'CA_0074 verify: new rev is_current is true (must stay false until Season 2 opens)'; END IF;
  IF v_rev <> 2 THEN RAISE EXCEPTION 'CA_0074 verify: new rev revision is % (expected 2)', v_rev; END IF;
  IF v_ver <> 2 THEN RAISE EXCEPTION 'CA_0074 verify: new rev version is % (expected 2)', v_ver; END IF;
  IF v_class <> 'substantive' THEN RAISE EXCEPTION 'CA_0074 verify: new rev change_class is % (expected substantive)', v_class; END IF;
  IF v_map IS DISTINCT FROM v_rungmap THEN RAISE EXCEPTION 'CA_0074 verify: new rev rung_map is % (expected %)', v_map, v_rungmap; END IF;
  IF v_qtext <> v_stem THEN RAISE EXCEPTION 'CA_0074 verify: question_text changed (expected unchanged stem)'; END IF;

  -- Exactly five rungs, values 1..5 distinct, all carrying the reviewed NEW text.
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions WHERE topic_revision_id = v_new;
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0074 verify: new rev has % rungs (expected 5)', v_n; END IF;
  SELECT count(DISTINCT value) INTO v_n FROM inform.compass_stance_revisions WHERE topic_revision_id = v_new;
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0074 verify: new rev rung values not 5 distinct (got %)', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions s WHERE s.topic_revision_id = v_new AND (
       (s.value = 1 AND s.text = 'Guarantee same-sex couples full legal equality — equal marriage plus protection from discrimination (such as in jobs and housing).')
    OR (s.value = 2 AND s.text = 'Guarantee same-sex marriage the same benefits and protections as any other marriage.')
    OR (s.value = 3 AND s.text = 'Allow same-sex marriage, but protect religious organizations'' right to decline to perform or host these marriages.')
    OR (s.value = 4 AND s.text = 'Recognize civil unions for same-sex couples, but reserve marriage for opposite-sex couples.')
    OR (s.value = 5 AND s.text = 'Make same-sex marriage illegal and define marriage as only between one man and one woman.'));
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0074 verify: new rev rungs do not all match the reviewed wording (matched %)', v_n; END IF;

  -- No removed/old wording leaked into the new revision.
  IF EXISTS (SELECT 1 FROM inform.compass_stance_revisions s WHERE s.topic_revision_id = v_new
             AND (s.text ILIKE '%each state decide%' OR s.text ILIKE '%federal interference%'
               OR s.text ILIKE '%nationwide%' OR s.text ILIKE '%require all states%'
               OR s.text ILIKE '%decline participation%')) THEN
    RAISE EXCEPTION 'CA_0074 verify: new rev still carries removed/old chair wording';
  END IF;
  -- Every chair capitalised.
  IF EXISTS (SELECT 1 FROM inform.compass_stance_revisions s WHERE s.topic_revision_id = v_new
             AND s.text !~ '^[A-Z]') THEN
    RAISE EXCEPTION 'CA_0074 verify: a new chair does not start with a capital letter';
  END IF;

  -- v1 still the published/current revision, and exactly one such.
  SELECT is_current, status INTO v_v1cur, v_v1stat FROM inform.compass_topic_revisions WHERE id = v_rev1;
  IF NOT v_v1cur THEN RAISE EXCEPTION 'CA_0074 verify: v1 is no longer is_current'; END IF;
  IF v_v1stat <> 'published' THEN RAISE EXCEPTION 'CA_0074 verify: v1 status is % (expected published)', v_v1stat; END IF;
  IF (SELECT count(*) FROM inform.compass_topic_revisions
       WHERE topic_id = v_topic AND is_current = true AND status = 'published') <> 1 THEN
    RAISE EXCEPTION 'CA_0074 verify: expected exactly 1 published/current revision (still v1)';
  END IF;

  -- Season 2 pins the new revision.
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_pin <> v_new THEN RAISE EXCEPTION 'CA_0074 verify: Season 2 pin is % (expected new rev %)', v_pin, v_new; END IF;

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
    RAISE EXCEPTION 'CA_0074 verify: open season resolves version % (expected 1)', v_openver;
  END IF;

  RAISE NOTICE 'CA_0074 post-verify OK: reshuffle rev 2/v2 approved (unpublished); Season 2 pins it; Season 1 still serves v1. ~522-row re-audit (494 old-chair-1 split + 28 invalidated states-decide) deferred before Season 2 opens.';
END $$;

COMMIT;
