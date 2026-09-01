BEGIN;

-- =============================================================================
-- CC_0031: reclassify four Season 2 revisions from substantive to clarifying
-- =============================================================================
-- Created 2026-09-01 with Chris Cantrell. Acts on the 28 revisions Chris Andrews
-- staged for Season 2, all of which were proposed `substantive`.
--
-- WHAT THIS DOES, per topic (data-centers, medicare/aid, city-sanitation,
-- rent-regulation): re-proposes Andrews' revision with IDENTICAL content and
-- change_class = 'clarifying', approves it, moves the Season 2 pin onto it, and
-- rejects the superseded substantive proposal.
--
-- WHY: `substantive` bumps `version`, and the recalibration check short-circuits
-- on version equality BEFORE it ever compares rung text:
--
--     if (row.answered_version === row.effective_version) continue;
--       -- backend/src/lib/compassUserLensService.ts
--
-- So the class, not the text, decides whether a user is asked to re-answer. In
-- these four the rung's POSITION is intact and only its phrasing moved — a
-- bundled extra deleted, or a specific generalised — so the recorded answer
-- still represents the view its author held. 15 of the 113 answers in scope stop
-- being flagged. The other 24 revisions are correctly substantive and are left
-- untouched.
--
-- 🔴 THIS WINDOW CLOSES WHEN SEASON 2 OPENS, AND NOT ONLY BECAUSE OF
--    change_class. `admin_season_pin_revision` raises NOT_DRAFT once the season
--    leaves 'draft', and season_pin_is_immutable enforces the same at the table.
--    After the season opens this migration cannot run at all, and the
--    classification could not be corrected by any later revision either.
--
-- ⚠ ATTRIBUTION CHANGES, DELIBERATELY. Andrews wrote this prose; re-proposing
--    records Chris Cantrell as `proposed_by` on the new revisions. That is the
--    intended record — it says who made the CLASSIFICATION call — but it does
--    mean the four new rows no longer name their author. Andrews' originals
--    survive as `rejected` rows carrying his authorship and the full text.
--
-- WHAT IS *NOT* CLAIMED: this does not assert the edits are cosmetic. Rent
-- Regulation rung 1 loses "strong tenant protections and just-cause eviction
-- requirements", and the two users sitting on that rung will never be asked
-- about it. That is a judgement call taken knowingly (Chris Cantrell,
-- 2026-09-01), not an accident of the mechanism.
--
-- CONTENT IS COPIED FROM THE DATABASE, NOT TRANSCRIBED. Twenty rungs of prose
-- retyped into a migration is twenty chances to introduce a silent edit — and a
-- silent edit here is invisible precisely because no prompt fires. The post-
-- verify gate proves byte-identity with inform.ladder_fingerprint(), which
-- hashes value/text/description/supporting_points/example_perspectives.
--
-- 🔴 ORDER IS FORCED: reject -> propose -> approve -> pin. The obvious order
--    (propose first, so the season is never pinned to a rejected revision) is
--    IMPOSSIBLE — `compass_topic_revisions_one_open` is a partial unique index
--    on topic_id WHERE status IN ('draft','approved'), so a topic may hold only
--    one open revision and the new proposal cannot exist beside Andrews' until
--    his is closed. Found by dry-running this migration inside a rolled-back
--    transaction, not by reading the schema.
--
--    The gap that ordering creates is real but unobservable: the whole
--    migration is one transaction, so no reader ever sees Season 2 pinned to a
--    rejected revision. If this is ever split into separate statements, the
--    ordering problem comes back.
--
-- IDEMPOTENT: each topic is skipped if it already carries an approved
-- 'clarifying' revision, so a re-run is a no-op.
--
-- TO REVERT: the same four RPCs in reverse — re-propose as 'substantive',
-- approve, re-pin, reject the clarifying row. Nothing here is destructive; every
-- superseded proposal is retained as a `rejected` row with its text intact.
--
-- IDs (verified 2026-09-01, prod kxsdzaojfaibhuzmclfq):
--   Season 2 (draft):     86d893a1-c1a2-4bbf-b4e5-69ec43221194
--   Actor (C. Cantrell):  4e6dde8f-2bd0-4054-824f-4164744165ea
-- The season is resolved by number below rather than hard-coded, so this stays
-- correct across environments. The actor is an identity, so it is literal.
-- =============================================================================

DO $$
DECLARE
  v_actor  CONSTANT uuid   := '4e6dde8f-2bd0-4054-824f-4164744165ea';
  v_keys   CONSTANT text[] := ARRAY['data-centers','medicare/aid','city-sanitation','rent-regulation'];
  v_reason CONSTANT text   :=
    'Reclassified to clarifying (CC_0031): re-proposed with identical content; '
    'only change_class differs. The rung positions are unchanged, so no '
    'recalibration prompt should fire.';
  v_season  uuid;
  v_topic   uuid;
  v_old     inform.compass_topic_revisions%ROWTYPE;
  v_stances jsonb;
  v_new_id  uuid;
  k         text;
BEGIN
  SELECT id INTO v_season FROM inform.seasons WHERE number = 2 AND status = 'draft';
  IF v_season IS NULL THEN
    RAISE EXCEPTION
      'CC_0031: Season 2 is missing or no longer draft — its pins are frozen and this migration cannot run';
  END IF;

  FOREACH k IN ARRAY v_keys LOOP
    SELECT id INTO v_topic FROM inform.compass_topics WHERE topic_key = k;
    IF v_topic IS NULL THEN
      RAISE EXCEPTION 'CC_0031: topic % not found', k;
    END IF;

    IF EXISTS (
      SELECT 1 FROM inform.compass_topic_revisions
       WHERE topic_id = v_topic AND status = 'approved' AND change_class = 'clarifying'
    ) THEN
      RAISE NOTICE 'CC_0031: % already reclassified — skipped', k;
      CONTINUE;
    END IF;

    SELECT * INTO v_old
      FROM inform.compass_topic_revisions
     WHERE topic_id = v_topic AND status = 'approved' AND change_class = 'substantive';
    IF NOT FOUND THEN
      RAISE EXCEPTION 'CC_0031: % has no approved substantive revision to reclassify', k;
    END IF;

    -- Read the ladder back out rather than retyping it. Only value and text are
    -- carried because these staged rows hold nothing else — verified 2026-09-01:
    -- 0 of 20 rungs across these four topics has a description, a supporting
    -- point, or an example perspective. The gate below proves the copy is exact.
    SELECT jsonb_agg(jsonb_build_object('value', sr.value, 'text', sr.text) ORDER BY sr.value)
      INTO v_stances
      FROM inform.compass_stance_revisions sr
     WHERE sr.topic_revision_id = v_old.id;

    IF v_stances IS NULL OR jsonb_array_length(v_stances) <> 5 THEN
      RAISE EXCEPTION 'CC_0031: % staged revision does not carry exactly 5 rungs', k;
    END IF;

    -- Reject FIRST — one_open forbids two open revisions on a topic. v_old is a
    -- snapshot taken above, so it still carries the pre-reject review_ref; the
    -- reject appends its "REJECTED: ..." suffix to the stored row only, and the
    -- new revision inherits the clean reference.
    PERFORM inform.admin_reject_topic_revision(v_old.id, v_actor, v_reason);

    v_new_id := inform.admin_propose_topic_revision(
      k, v_actor, 'clarifying',
      v_old.title, v_old.short_title, v_old.question_text,
      v_stances, v_old.rationale, v_old.public_note, v_old.review_ref, v_old.rung_map);

    PERFORM inform.admin_approve_topic_revision(v_new_id, v_actor);
    PERFORM inform.admin_season_pin_revision(v_season, v_topic, v_new_id, v_actor);

    RAISE NOTICE 'CC_0031: % reclassified to clarifying — revision % (was %)',
      k, v_new_id, v_old.id;
  END LOOP;
END $$;

-- ---------------------------------------------------------------------------
-- Post-verify gate. Every claim the header makes is asserted here.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_keys   CONSTANT text[] := ARRAY['data-centers','medicare/aid','city-sanitation','rent-regulation'];
  v_season uuid;
  v_status inform.season_status;
  v_topic  uuid;
  v_new    inform.compass_topic_revisions%ROWTYPE;
  v_pub_version int;
  v_pinned uuid;
  v_rejected_id uuid;
  v_n      int;
  k        text;
BEGIN
  SELECT id, status INTO v_season, v_status FROM inform.seasons WHERE number = 2;
  IF v_status <> 'draft' THEN
    RAISE EXCEPTION 'CC_0031: Season 2 is % (expected draft)', v_status;
  END IF;

  FOREACH k IN ARRAY v_keys LOOP
    SELECT id INTO v_topic FROM inform.compass_topics WHERE topic_key = k;

    -- exactly one approved revision, and it is the clarifying one
    SELECT count(*) INTO v_n FROM inform.compass_topic_revisions
     WHERE topic_id = v_topic AND status = 'approved';
    IF v_n <> 1 THEN
      RAISE EXCEPTION 'CC_0031: % has % approved revisions (expected 1)', k, v_n;
    END IF;

    SELECT * INTO v_new FROM inform.compass_topic_revisions
     WHERE topic_id = v_topic AND status = 'approved';
    IF v_new.change_class <> 'clarifying' THEN
      RAISE EXCEPTION 'CC_0031: the approved revision for % is % (expected clarifying)', k, v_new.change_class;
    END IF;

    -- the whole point: version did NOT advance past the published lineage
    SELECT version INTO v_pub_version FROM inform.compass_topic_revisions
     WHERE topic_id = v_topic AND is_current AND status = 'published';
    IF v_new.version <> v_pub_version THEN
      RAISE EXCEPTION
        'CC_0031: % version bumped to % (published is %) — a clarifying revision must not advance version',
        k, v_new.version, v_pub_version;
    END IF;

    -- Season 2 points at the new revision
    SELECT topic_revision_id INTO v_pinned FROM inform.season_questions
     WHERE season_id = v_season AND topic_id = v_topic;
    IF v_pinned IS DISTINCT FROM v_new.id THEN
      RAISE EXCEPTION 'CC_0031: Season 2 pins % for % (expected %)', v_pinned, k, v_new.id;
    END IF;

    -- the superseded proposal is rejected, not lingering as approved
    SELECT id INTO v_rejected_id FROM inform.compass_topic_revisions
     WHERE topic_id = v_topic AND status = 'rejected' AND change_class = 'substantive'
     ORDER BY revision DESC LIMIT 1;
    IF v_rejected_id IS NULL THEN
      RAISE EXCEPTION 'CC_0031: % has no rejected substantive revision — the reject did not land', k;
    END IF;

    -- and the content is byte-identical to what Andrews wrote
    IF inform.ladder_fingerprint(v_new.id) IS DISTINCT FROM inform.ladder_fingerprint(v_rejected_id) THEN
      RAISE EXCEPTION
        'CC_0031: % ladder differs from the revision it replaces — the copy was not faithful', k;
    END IF;
  END LOOP;

  -- the other 24 are untouched
  SELECT count(*) INTO v_n FROM inform.compass_topic_revisions
   WHERE status = 'approved' AND change_class = 'substantive';
  IF v_n <> 24 THEN
    RAISE EXCEPTION
      'CC_0031: % substantive revisions still approved (expected 24) — something outside the four was changed', v_n;
  END IF;

  RAISE NOTICE 'CC_0031 OK — 4 revisions reclassified to clarifying, content identical, Season 2 repinned, 24 substantive untouched';
END $$;

COMMIT;
