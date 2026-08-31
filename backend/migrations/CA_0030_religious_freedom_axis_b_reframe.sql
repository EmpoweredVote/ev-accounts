BEGIN;

-- =============================================================================
-- CA_0030: Religious Freedom — substantive v2 (Axis-B reframe), parked for Season 2
-- =============================================================================
-- Created 2026-08-29 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2,
-- candrews@empowered.vote).
--
-- WHAT THIS DOES
--   Supersedes the abandoned v2 draft (rev2, ec4b073f) with a fresh SUBSTANTIVE
--   version-2 revision that:
--     * reframes the question from Axis A (role of religion in government / public
--       institutions) to Axis B (religious freedom vs. protection from
--       discrimination) — the axis the ladder already measures:
--           OLD  "What role should religion play in government, public
--                 institutions, and policymaking?"
--           NEW  "How should the law balance religious freedom with protection
--                 from discrimination?"
--     * splits chair 1's double-barrel, keeping the exemptions clause and dropping
--       the church-state-separation clause:
--           OLD  "strictly separate religion from all public institutions and
--                 prohibit religious exemptions from civil rights laws."
--           NEW  "prohibit religious exemptions from civil rights and
--                 anti-discrimination laws."
--     * leaves chairs 2-5 byte-identical.
--   Identity rung map (positions do not move; chair 1 is reworded in place).
--
-- WHY SUBSTANTIVE, NOT MINOR (decision 2026-08-29, Chris Andrews)
--   This is the mirror of the CA_0028 residential-zoning call, and it lands the
--   OTHER way. There the dropped barrels were off-axis limbs no seating depended
--   on, so the split was CLARIFYING. Here the dropped clause — "strictly separate
--   religion from all public institutions" — is LOAD-BEARING. Of the 25 answers
--   seated on chair 1, five are seated on church-state separation ALONE, with no
--   evidence about religious exemptions:
--       Jared Huffman, Jennifer Booker, John Croisant, Keith B. Goodenough,
--       Rachel Fetty Anderson.
--   The new chair 1 does not describe them. Per CLAUDE.md ("evidence must describe
--   THAT chair"), those seatings become unevidenced under the new wording, so the
--   change bumps `version` and waits for a season change. It does not enter open
--   Season 1 (ADR 0006 sec 2).
--
-- WHY PARKED (approved, NOT published)
--   A major revision is proposed and approved but LEFT UNPUBLISHED, then pinned by
--   the next season when it opens (ADR 0006 sec 4, the abortion-v2 pattern).
--   Season 2 is not open yet (blocked on the CC_0002 scaffold drop), so v2 rests at
--   `approved`. An approved/unpublished revision is is_current=false and is served
--   to no one: reads resolve through the open season's pin to the latest
--   published/superseded revision of the PINNED version (v1), so Season 1 keeps
--   showing v1r1 untouched. Publishing v2 now is deliberately avoided — see below.
--
-- WHY NOT PUBLISH NOW (the machinery gate)
--   admin_publish_topic_revision REFUSES any rung map that moves or invalidates a
--   rung (REPOINTING_NOT_IMPLEMENTED — answer re-pointing and the answer-delete
--   guard are not built). The only publishable map is all-identity, which asserts
--   "every old-chair-1 answer belongs at new chair 1" — false for the five above.
--   So the honest disposition of those five cannot ride inside a publish; it is a
--   Season-2 CARRY step (see below). Parking at `approved` sidesteps the false
--   identity assertion entirely, because a parked revision serves no one.
--
-- SEASON-2 CARRY LIST (handled at Season 2 assembly, NOT here)
--   Re-source the five separation-only seatings for a religious-exemptions stance;
--   blank the spoke only where no such evidence exists (decision 2026-08-29:
--   "re-source first, blank if none"). This migration writes NO change to
--   politician_answers or politician_context, so no answer-delete guard applies.
--
-- SUPERSEDES: rejected draft rev2 (ec4b073f). One reviewable draft per topic.
--
-- Idempotent: re-running after success is a no-op; each lifecycle step is guarded.
-- =============================================================================

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
  v_key      CONSTANT text := 'religious-freedom';
  v_rev2     CONSTANT uuid := 'ec4b073f-a000-474d-95b8-7ba91710698b';
  v_question CONSTANT text := 'How should the law balance religious freedom with protection from discrimination?';
  v_chair1   CONSTANT text := 'prohibit religious exemptions from civil rights and anti-discrimination laws.';
  v_topic_id uuid;
  v_new_id   uuid;
  v_stances  jsonb;
BEGIN
  SELECT id INTO v_topic_id FROM inform.compass_topics WHERE topic_key = v_key;
  IF v_topic_id IS NULL THEN
    RAISE EXCEPTION 'CA_0030: topic % not found', v_key;
  END IF;

  -- Idempotency: an approved/published substantive v2 with the new question and
  -- the reworded chair 1 already exists? Nothing to do.
  IF EXISTS (
    SELECT 1
    FROM inform.compass_topic_revisions r
    JOIN inform.compass_stance_revisions s
      ON s.topic_revision_id = r.id AND s.value = 1
    WHERE r.topic_id = v_topic_id
      AND r.change_class = 'substantive'
      AND r.version = 2
      AND r.status IN ('approved', 'published')
      AND r.question_text = v_question
      AND s.text = v_chair1
  ) THEN
    RAISE NOTICE 'CA_0030 already applied — substantive v2 present; skipping.';
    RETURN;
  END IF;

  -- 1) Close the abandoned v2 draft, if still open.
  IF EXISTS (SELECT 1 FROM inform.compass_topic_revisions
             WHERE id = v_rev2 AND status IN ('draft', 'approved')) THEN
    PERFORM inform.admin_reject_topic_revision(
      v_rev2, v_actor,
      'Superseded 2026-08-29 (Chris Andrews) by CA_0030, which reframes the '
      || 'question onto Axis B (religious freedom vs. protection from '
      || 'discrimination) in addition to splitting the chair-1 double-barrel. '
      || 'One reviewable draft per topic.');
  END IF;

  -- 2) Propose the substantive v2 (version bumps to 2; identity rung map).
  --    Reuse an existing matching draft/approved/published row if a prior partial
  --    run already created it (resumable).
  SELECT r.id INTO v_new_id
  FROM inform.compass_topic_revisions r
  JOIN inform.compass_stance_revisions s
    ON s.topic_revision_id = r.id AND s.value = 1
  WHERE r.topic_id = v_topic_id
    AND r.change_class = 'substantive'
    AND r.version = 2
    AND r.status IN ('draft', 'approved', 'published')
    AND r.question_text = v_question
    AND s.text = v_chair1
  ORDER BY r.revision DESC
  LIMIT 1;

  IF v_new_id IS NULL THEN
    v_stances := jsonb_build_array(
      jsonb_build_object('value', 1, 'text', v_chair1),
      jsonb_build_object('value', 2, 'text',
        'protect religious freedom while ensuring it doesn''t override anti-discrimination protections in employment and housing.'),
      jsonb_build_object('value', 3, 'text',
        'balance protecting religious practices with maintaining equal treatment under the law for all citizens.'),
      jsonb_build_object('value', 4, 'text',
        'protect religious freedom and allow faith-based exemptions from laws that conflict with sincere religious beliefs.'),
      jsonb_build_object('value', 5, 'text',
        'strongly protect religious freedom and allow religious organizations complete autonomy in their operations and hiring practices.')
    );

    v_new_id := inform.admin_propose_topic_revision(
      v_key, v_actor, 'substantive',
      'Religious Freedom', 'Religious Freedom',
      v_question,
      v_stances,
      -- rationale (internal)
      'Substantive v2. Axis-B reframe: the question moves from "role of religion in '
      || 'government/public institutions/policymaking" (Axis A) to "how should the law '
      || 'balance religious freedom with protection from discrimination" (Axis B) — the '
      || 'axis chairs 2-5 already measure (188/192 seatings at chair 2 cite it, and so '
      || 'on). Chair 1''s double-barrel is split, keeping the exemptions clause and '
      || 'dropping "strictly separate religion from all public institutions". That '
      || 'dropped clause is LOAD-BEARING, unlike the off-axis limbs re-scoped as '
      || 'clarifying in CA_0028: five of the 25 chair-1 seatings (Jared Huffman, '
      || 'Jennifer Booker, John Croisant, Keith B. Goodenough, Rachel Fetty Anderson) '
      || 'rest on church-state separation alone and are not described by the new chair. '
      || 'Hence substantive (version bump), parked at approved for Season 2 (ADR 0006 '
      || 'sec 4). Identity rung map: chair 1 reworded in place, no rung moves. SEASON-2 '
      || 'CARRY: re-source those five for a religious-exemptions stance; blank the spoke '
      || 'only where none exists. Supersedes rejected draft rev2 (ec4b073f).',
      -- public_note (reader-facing)
      'Reframed the question and option 1 around religious exemptions and '
      || 'anti-discrimination law, the scale''s actual axis, so option 1 now states a '
      || 'single position instead of two welded together. Options 2-5 are unchanged.',
      -- review_ref
      'CA_0030 — substantive v2 Axis-B reframe (question + chair 1); parked for '
      || 'Season 2; supersedes rejected draft rev2 (ec4b073f).',
      -- rung_map (identity: chair 1 reworded in place, no rung moves)
      '{"1":1,"2":2,"3":3,"4":4,"5":5}'::jsonb
    );
  END IF;

  -- 3) Approve if still draft. DO NOT publish — park for Season 2.
  IF EXISTS (SELECT 1 FROM inform.compass_topic_revisions
             WHERE id = v_new_id AND status = 'draft') THEN
    PERFORM inform.admin_approve_topic_revision(v_new_id, v_actor);
  END IF;

  RAISE NOTICE 'CA_0030: approved (parked, unpublished) substantive v2 %', v_new_id;
END $$;

-- =============================================================================
-- POST-VERIFY GATE
-- =============================================================================
DO $$
DECLARE
  v_topic_id uuid;
  v_v2_id    uuid;
  v_v2_ver   int;
  v_v2_stat  text;
  v_v2_curr  boolean;
  v_chair1   text;
  v_rungs    int;
  v_cur_ver  int;
  v_eff_ver  int;
BEGIN
  SELECT id INTO v_topic_id FROM inform.compass_topics WHERE topic_key = 'religious-freedom';

  -- The parked v2 exists, is substantive version 2, approved (NOT published), and
  -- is_current = false (it must serve no one).
  SELECT r.id, r.version, r.status::text, r.is_current
    INTO v_v2_id, v_v2_ver, v_v2_stat, v_v2_curr
  FROM inform.compass_topic_revisions r
  JOIN inform.compass_stance_revisions s
    ON s.topic_revision_id = r.id AND s.value = 1
  WHERE r.topic_id = v_topic_id
    AND r.change_class = 'substantive'
    AND r.version = 2
    AND r.question_text = 'How should the law balance religious freedom with protection from discrimination?'
    AND s.text = 'prohibit religious exemptions from civil rights and anti-discrimination laws.'
  ORDER BY r.revision DESC
  LIMIT 1;

  IF v_v2_id IS NULL THEN
    RAISE EXCEPTION 'CA_0030 post-verify: substantive v2 revision not found';
  END IF;
  IF v_v2_ver <> 2 THEN
    RAISE EXCEPTION 'CA_0030 post-verify: version is % (expected 2)', v_v2_ver;
  END IF;
  IF v_v2_stat <> 'approved' THEN
    RAISE EXCEPTION 'CA_0030 post-verify: status is % (expected approved — must NOT be published)', v_v2_stat;
  END IF;
  IF v_v2_curr THEN
    RAISE EXCEPTION 'CA_0030 post-verify: v2 is is_current (expected false — a parked revision serves no one)';
  END IF;

  SELECT count(*) INTO v_rungs FROM inform.compass_stance_revisions WHERE topic_revision_id = v_v2_id;
  IF v_rungs <> 5 THEN
    RAISE EXCEPTION 'CA_0030 post-verify: v2 has % rungs (expected 5)', v_rungs;
  END IF;

  -- Chairs 2-5 carried byte-identical from v1r1.
  IF (SELECT text FROM inform.compass_stance_revisions WHERE topic_revision_id = v_v2_id AND value = 5)
     <> 'strongly protect religious freedom and allow religious organizations complete autonomy in their operations and hiring practices.' THEN
    RAISE EXCEPTION 'CA_0030 post-verify: chair 5 text drifted from v1';
  END IF;

  -- is_current is STILL version 1 (v2 is parked, so v1 keeps serving).
  SELECT version INTO v_cur_ver FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic_id AND is_current;
  IF v_cur_ver <> 1 THEN
    RAISE EXCEPTION 'CA_0030 post-verify: is_current version is % (expected 1 — v2 must not be current)', v_cur_ver;
  END IF;

  -- The open season still resolves version 1 for this topic (Season 1 undisturbed),
  -- resolved exactly as compassService.getPromotedTopics does.
  SELECT eff.version INTO v_eff_ver
  FROM inform.season_questions sq
  JOIN inform.seasons s   ON s.id  = sq.season_id AND s.status = 'open'
  JOIN inform.compass_topic_revisions pin ON pin.id = sq.topic_revision_id
  JOIN LATERAL (
    SELECT ee.version
    FROM inform.compass_topic_revisions ee
    WHERE ee.topic_id = pin.topic_id
      AND ee.version  = pin.version
      AND ee.status IN ('published', 'superseded')
    ORDER BY ee.revision DESC
    LIMIT 1
  ) eff ON true
  WHERE sq.topic_id = v_topic_id;

  IF v_eff_ver IS NOT NULL AND v_eff_ver <> 1 THEN
    RAISE EXCEPTION 'CA_0030 post-verify: open season resolves version % for religious-freedom (expected 1 — v2 must stay out of Season 1)', v_eff_ver;
  END IF;

  -- The old draft is closed.
  IF EXISTS (SELECT 1 FROM inform.compass_topic_revisions
             WHERE id = 'ec4b073f-a000-474d-95b8-7ba91710698b' AND status IN ('draft', 'approved')) THEN
    RAISE EXCEPTION 'CA_0030 post-verify: rev2 (ec4b073f) is still open (expected rejected)';
  END IF;

  RAISE NOTICE 'CA_0030 post-verify OK: parked substantive v2 % (approved, is_current=false); open season still serves v1', v_v2_id;
END $$;

COMMIT;
