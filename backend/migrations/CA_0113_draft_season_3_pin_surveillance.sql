BEGIN;

-- =============================================================================
-- CA_0113: draft Season 3, carried from Season 2, pinning surveillance-technology
-- =============================================================================
-- Created 2026-09-12.
--
-- WHAT THIS DOES
-- Creates the DRAFT Season 3 via inform.admin_create_draft_season with
-- p_carry_from_open = true (so Season 2's whole question set comes along), then
-- pins `surveillance-technology` (CA_0111) into it. Result: 61 questions, being
-- Season 2's 60 plus the new one.
--
-- WHY IT IS NEEDED, AND IT IS NOT ONLY ABOUT DISPLAY
-- `surveillance-technology` was created by CA_0111 with no season pin, because
-- inform.admin_season_add_topic refuses a non-draft season and Season 2 has been
-- open since 2026-09-04. The consequence is larger than "it is not visible yet":
--
--   -> inform.politician_answers has
--       politician_answers_pin_fkey FOREIGN KEY (season_id, topic_id, topic_revision_id)
--         REFERENCES inform.season_questions(season_id, topic_id, topic_revision_id)
--
-- so with zero pins the topic is COMPLETELY UNWRITABLE. Measured, not assumed --
-- a trial insert of a researched row returned:
--
--   23503 ... violates foreign key constraint "politician_answers_pin_fkey"
--   DETAIL: Key (season_id, topic_id, topic_revision_id)=(...) is not present in
--           table "season_questions".
--
-- 11 Nashville council rows are already researched and waiting on exactly this
-- (backend/data/stance-research/2026-09-12-nashville-surveillance-technology.
--  PENDING-SEASON-PIN.csv). This migration is what makes them writable.
--
-- 🔴 ANSWERS FOR THIS TOPIC MUST CARRY SEASON 3's ID, NOT THE OPEN SEASON'S.
-- The pin lives in Season 3, so that is the only season_id the FK will accept for
-- surveillance-technology. apply-nashville-metro-council-stances.ts resolves the
-- season as `WHERE status = 'open'`, which is Season 2 -- it will FAIL on this
-- topic until it is given the right season. That is a deliberate note, not an
-- oversight: the applier is correct for every topic Season 2 pins.
--
-- WHAT IT DOES NOT DO
-- It does NOT open Season 3. inform.admin_open_season is a separate, later,
-- deliberate step and it is a product decision -- opening Season 3 is what would
-- switch the voter-facing question set from 60 to 61 and start showing a spoke
-- that is blank for almost every official. Nothing on any voter surface changes
-- from this migration: the season-gated promoted view lists OPEN-season topics
-- only, and the post-verify gate below asserts exactly that.
-- Season 2 is left open and untouched; the RPC neither closes nor edits it.
--
-- 🔑 CARRIED TOPICS ARE RE-PINNED TO THEIR *CURRENT* PUBLISHED REVISION, not to
-- the revision Season 2 pinned. That is the RPC's behaviour and it is the point of
-- a new season, but it means Season 3 is NOT a copy of Season 2: for the four
-- topics where Season 2 pins revision 1 while is_current is revision 3-4
-- (public-safety-approach, residential-zoning, taxes, transportation-priorities)
-- Season 3 carries the NEWER wording. Anyone comparing answers across the two
-- seasons is comparing different question text for those four.
--
-- The public_note is a transparency surface under ADR 0005 -- the RPC refuses to
-- create a season without one. It is editable later via
-- inform.admin_update_draft_season while the season remains a draft.
--
-- IDEMPOTENT: the create runs only when no season numbered 3 exists; the pin runs
-- only when the topic is not already in it. A re-run is a no-op and the gate still
-- asserts the full shape. To revert while it is still a draft:
-- inform.admin_delete_draft_season.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Create the draft season, carrying Season 2's question set.
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE number = 3) THEN
    PERFORM inform.admin_create_draft_season(
      NULL,                                                     -- p_actor_id
      'Season 3',                                               -- p_name
      'Season 3 carries forward Season 2''s full question set and adds one new '
        || 'question, Surveillance Technology: how a community should use '
        || 'surveillance technology like license plate readers and facial '
        || 'recognition. It is a draft - nothing in it is shown to voters until '
        || 'the season is opened.',                             -- p_public_note
      true                                                      -- p_carry_from_open
    );
    RAISE NOTICE 'CA_0113: created draft Season 3';
  ELSE
    RAISE NOTICE 'CA_0113: a season numbered 3 already exists - create skipped';
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 2. Pin surveillance-technology into it.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_season uuid;
  v_topic  uuid := 'fc056106-6078-4aad-be8a-461df1cb7fbd';
BEGIN
  SELECT id INTO v_season FROM inform.seasons WHERE number = 3;
  IF v_season IS NULL THEN
    RAISE EXCEPTION 'CA_0113: Season 3 missing before pin';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM inform.season_questions
     WHERE season_id = v_season AND topic_id = v_topic
  ) THEN
    PERFORM inform.admin_season_add_topic(v_season, v_topic, NULL);
    RAISE NOTICE 'CA_0113: pinned surveillance-technology into Season 3';
  ELSE
    RAISE NOTICE 'CA_0113: surveillance-technology already pinned - skipped';
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 3. Post-verify gate.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_season uuid;
  v_topic  uuid := 'fc056106-6078-4aad-be8a-461df1cb7fbd';
  v_status inform.season_status;
  v_n      int;
  v_s2     int;
BEGIN
  SELECT id, status INTO v_season, v_status FROM inform.seasons WHERE number = 3;
  IF v_season IS NULL THEN
    RAISE EXCEPTION 'CA_0113: Season 3 is missing after create';
  END IF;

  -- It must be a DRAFT. Opening it is a separate product decision.
  IF v_status <> 'draft' THEN
    RAISE EXCEPTION 'CA_0113: Season 3 is % (expected draft)', v_status;
  END IF;

  -- Exactly one draft season may exist.
  SELECT count(*) INTO v_n FROM inform.seasons WHERE status = 'draft';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0113: expected exactly 1 draft season, got %', v_n;
  END IF;

  -- Season 2 must still be OPEN and still hold its own 60 questions: this
  -- migration must not have disturbed the live season.
  SELECT count(*) INTO v_s2
    FROM inform.season_questions sq
    JOIN inform.seasons s ON s.id = sq.season_id
   WHERE s.number = 2;
  IF v_s2 <> 60 THEN
    RAISE EXCEPTION 'CA_0113: Season 2 now holds % questions (expected 60)', v_s2;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE number = 2 AND status = 'open') THEN
    RAISE EXCEPTION 'CA_0113: Season 2 is no longer the open season';
  END IF;

  -- Season 3 = Season 2's 60 carried + surveillance-technology.
  SELECT count(*) INTO v_n FROM inform.season_questions WHERE season_id = v_season;
  IF v_n <> 61 THEN
    RAISE EXCEPTION 'CA_0113: Season 3 holds % questions (expected 61)', v_n;
  END IF;

  -- The new topic is pinned, on its current published revision.
  SELECT count(*) INTO v_n
    FROM inform.season_questions sq
    JOIN inform.compass_topic_revisions r ON r.id = sq.topic_revision_id
   WHERE sq.season_id = v_season AND sq.topic_id = v_topic
     AND r.is_current AND r.status = 'published';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0113: surveillance-technology pinned % times on a current published revision (expected 1)', v_n;
  END IF;

  -- Every carried pin points at a published revision.
  SELECT count(*) INTO v_n
    FROM inform.season_questions sq
    JOIN inform.compass_topic_revisions r ON r.id = sq.topic_revision_id
   WHERE sq.season_id = v_season AND r.status <> 'published';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CA_0113: % Season 3 pins point at an unpublished revision', v_n;
  END IF;

  -- Still not on any voter surface: the promoted view is open-season only, and
  -- Season 3 is a draft.
  IF EXISTS (SELECT 1 FROM inform.compass_topics_promoted WHERE id = v_topic) THEN
    RAISE EXCEPTION 'CA_0113: surveillance-technology reached a voter surface while Season 3 is a draft';
  END IF;

  RAISE NOTICE 'CA_0113 OK - Season 3 draft with 61 questions (60 carried + surveillance-technology on its current revision), Season 2 still open with 60, nothing promoted';
END $$;

COMMIT;
