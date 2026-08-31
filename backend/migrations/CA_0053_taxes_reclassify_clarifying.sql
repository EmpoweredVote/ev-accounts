-- CA_0053_taxes_reclassify_clarifying.sql
--
-- Reclassify the pending `taxes` rework from a MAJOR (substantive) revision to a
-- MINOR (clarifying) one, then publish it into the open season.
--
-- WHAT WAS THERE
--   `taxes` (topic f7e5678d-dadd-4556-a2fc-446e24642ceb), question 40 in both
--   Season 1 (open) and Season 2 (draft), both pinning revision 1 (version 1,
--   published/current). Revision 2 (bd82ed56…, version 2, change_class
--   'substantive', status 'approved', unpinned) held a reword of chairs 3/4/5.
--
-- WHY MINOR, NOT MAJOR
--   The reword only removes an over-demanding clause and broadens a chair; it
--   never mis-seats a politician who is already seated:
--     chair 1,2  — identical.
--     chair 3    — "close loopholes" widened to "close loopholes OR grant narrow
--                  relief". Broadening: everyone already at chair 3 still fits.
--     chair 4    — dropped the double-barrel service clause ("and scale back
--                  public services to match") -> "cut taxes broadly, incl. main
--                  rates". The seated politician holds the core (cut taxes
--                  broadly); the removed limb is what wrongly BLANKED rows that
--                  stated no service consequence (e.g. the identical half-point
--                  sales-tax cuts from Orcutt (R) and Krishnadasan (D)).
--     chair 5    — reworded, same meaning (drastic cut + shrink government).
--   Removing an off-axis / over-demanding limb never invalidates an existing
--   seating (the seated politician holds the core) — the same class as the
--   fossil-fuels rework, which was likewise published as MINOR. The only debt is
--   UNDER-seating (blanked rows that now fit chairs 3/4), which is payable at any
--   time and does not block a publish. So the change belongs in the open season
--   now, not held for the Season 2 open.
--
-- MECHANICS
--   `change_class` is immutable on a revision, and revision 2 is version 2 (the
--   substantive bump). The season read path serves "the latest published revision
--   OF THE PINNED VERSION" (compass_topics_promoted + the LATERAL in
--   getPromotedTopics), so a version-2 revision stays invisible until a season
--   pins version 2 — which is exactly why it reads as major. Re-proposing the
--   identical wording as 'clarifying' keeps version 1 and only bumps the revision
--   number; on publish, Season 1 (open) and Season 2 (draft) both resolve their
--   version-1 pin to the new revision automatically, with no repin.
--   Reclassifying therefore = reject revision 2, re-propose it as 'clarifying',
--   approve, publish. This migration does exactly that, via the same admin RPCs
--   the review UI calls.
--
--   The re-propose also RESTORES the per-stance `description` and
--   `example_perspectives` that revision 2 had dropped to NULL/[] (revision 1
--   carried rich values). Neither field is read by any voter or admin surface
--   today (both are dormant), so this is faithfulness only — the reword should
--   not silently lose content. The improved TEXT comes from revision 2; the
--   descriptions and example perspectives come from revision 1.
--
-- Idempotent: the whole action is guarded on revision 2 still being an approved
-- substantive v2 draft; a re-run after success is a no-op.

DO $$
DECLARE
  v_topic_id uuid;
  v_rev1_id  uuid;   -- published v1 — description / example_perspectives source
  v_rev2_id  uuid;   -- approved substantive v2 draft — text source, to be rejected
  v_actor    uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';  -- same actor that approved rev2
  v_stances  jsonb;
  v_rat      text;
  v_note     text;
  v_new_rev  uuid;
BEGIN
  SELECT id INTO v_topic_id FROM inform.compass_topics WHERE topic_key = 'taxes';
  IF v_topic_id IS NULL THEN
    RAISE EXCEPTION 'CA_0053: topic "taxes" not found';
  END IF;

  SELECT id INTO v_rev1_id
    FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic_id AND version = 1 AND revision = 1;
  IF v_rev1_id IS NULL THEN
    RAISE EXCEPTION 'CA_0053: taxes v1 revision 1 not found';
  END IF;

  -- Guard: only act while the substantive v2 draft is still an open, approved draft.
  SELECT id INTO v_rev2_id
    FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic_id
     AND version = 2
     AND change_class = 'substantive'
     AND status = 'approved';
  IF v_rev2_id IS NULL THEN
    RAISE NOTICE 'CA_0053: no approved substantive v2 draft for taxes — already reclassified; skipping';
    RETURN;
  END IF;

  -- Carry rev2's rationale / public note onto the clarifying revision (they
  -- already describe the reword). Capture before rejecting.
  SELECT rationale, public_note INTO v_rat, v_note
    FROM inform.compass_topic_revisions WHERE id = v_rev2_id;

  -- Build the clarifying ladder: rev2 TEXT + rev1 DESCRIPTION + rev1 EXAMPLE_PERSPECTIVES.
  SELECT jsonb_agg(
           jsonb_build_object(
             'value',                b.value,
             'text',                 b.text,
             'description',          a.description,
             'example_perspectives', to_jsonb(a.example_perspectives)
           ) ORDER BY b.value)
    INTO v_stances
    FROM inform.compass_stance_revisions b
    JOIN inform.compass_stance_revisions a
      ON a.topic_revision_id = v_rev1_id AND a.value = b.value
   WHERE b.topic_revision_id = v_rev2_id;

  IF v_stances IS NULL OR jsonb_array_length(v_stances) <> 5 THEN
    RAISE EXCEPTION 'CA_0053: expected 5 stances, built %', COALESCE(jsonb_array_length(v_stances), 0);
  END IF;

  -- 1) Reject the substantive draft (only path to change its class).
  PERFORM inform.admin_reject_topic_revision(
    v_rev2_id, v_actor,
    'Reclassified to clarifying (minor) — reword removes an over-demanding clause and broadens chair 3; no seated row is mis-seated, so it belongs in the open season rather than the Season 2 open. Re-proposed as version 1 by CA_0053.');

  -- 2) Re-propose the identical wording as CLARIFYING (keeps version 1), identity rung_map.
  v_new_rev := inform.admin_propose_topic_revision(
    'taxes',
    v_actor,
    'clarifying',
    'Taxation and Public Spending',
    'Taxes',
    'How should government balance what it collects in taxes against what it spends on public services?',
    v_stances,
    v_rat,
    v_note,
    NULL,
    '{"1":1,"2":2,"3":3,"4":4,"5":5}'::jsonb
  );

  -- 3) Approve.
  PERFORM inform.admin_approve_topic_revision(v_new_rev, v_actor);

  -- 4) Publish -> is_current; both seasons (version-1 pins) serve it, no repin.
  PERFORM inform.admin_publish_topic_revision(v_new_rev, v_actor);

  RAISE NOTICE 'CA_0053: taxes reclassified to clarifying and published as %', v_new_rev;
END $$;

-- ---------------------------------------------------------------------------
-- Post-verify gate
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_topic_id uuid;
  v_cur_id   uuid;
  v_cur_ver  int;
  v_cur_class inform.change_class;
  v_cur_status text;
  v_nstance  int;
  v_ndesc    int;
  v_open_eff uuid;   -- revision the OPEN season (Season 1) resolves to
BEGIN
  SELECT id INTO v_topic_id FROM inform.compass_topics WHERE topic_key = 'taxes';

  -- Exactly one published + current revision.
  SELECT count(*) INTO v_nstance
    FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic_id AND is_current = true AND status = 'published';
  IF v_nstance <> 1 THEN
    RAISE EXCEPTION 'CA_0053 verify: expected exactly 1 published/current revision, found %', v_nstance;
  END IF;

  SELECT id, version, change_class, status
    INTO v_cur_id, v_cur_ver, v_cur_class, v_cur_status
    FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic_id AND is_current = true AND status = 'published';

  IF v_cur_ver <> 1 THEN
    RAISE EXCEPTION 'CA_0053 verify: current revision must be version 1, is %', v_cur_ver;
  END IF;
  IF v_cur_class <> 'clarifying' THEN
    RAISE EXCEPTION 'CA_0053 verify: current revision must be clarifying, is %', v_cur_class;
  END IF;

  -- No substantive v2 draft left in an open (draft/approved) state.
  SELECT count(*) INTO v_nstance
    FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic_id AND version = 2
     AND status IN ('draft', 'approved');
  IF v_nstance <> 0 THEN
    RAISE EXCEPTION 'CA_0053 verify: a v2 draft is still open (%), expected none', v_nstance;
  END IF;

  -- Five stances, all with a restored description and the reworded chair-3 text.
  SELECT count(*), count(description)
    INTO v_nstance, v_ndesc
    FROM inform.compass_stance_revisions
   WHERE topic_revision_id = v_cur_id;
  IF v_nstance <> 5 THEN
    RAISE EXCEPTION 'CA_0053 verify: expected 5 stances, found %', v_nstance;
  END IF;
  IF v_ndesc <> 5 THEN
    RAISE EXCEPTION 'CA_0053 verify: expected 5 restored descriptions, found %', v_ndesc;
  END IF;

  PERFORM 1 FROM inform.compass_stance_revisions
   WHERE topic_revision_id = v_cur_id AND value = 3
     AND text ILIKE '%granting narrow relief%';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CA_0053 verify: chair-3 reworded text not present on current revision';
  END IF;
  PERFORM 1 FROM inform.compass_stance_revisions
   WHERE topic_revision_id = v_cur_id AND value = 4
     AND text ILIKE '%scale back public services%';
  IF FOUND THEN
    RAISE EXCEPTION 'CA_0053 verify: chair-4 still carries the old service-cut clause';
  END IF;

  -- The OPEN season (Season 1) must now resolve its version-1 pin to the new revision.
  SELECT e.id INTO v_open_eff
    FROM inform.season_questions sq
    JOIN inform.seasons s      ON s.id = sq.season_id AND s.status = 'open'
    JOIN inform.compass_topic_revisions pin ON pin.id = sq.topic_revision_id
    JOIN inform.compass_topic_revisions e
      ON e.topic_id = pin.topic_id
     AND e.version  = pin.version
     AND e.status IN ('published', 'superseded')
   WHERE sq.topic_id = v_topic_id
   ORDER BY e.revision DESC
   LIMIT 1;
  IF v_open_eff IS DISTINCT FROM v_cur_id THEN
    RAISE EXCEPTION 'CA_0053 verify: open season resolves to % but current is %', v_open_eff, v_cur_id;
  END IF;

  RAISE NOTICE 'CA_0053 verify OK: taxes now clarifying v1 rev % (published/current), open season serves it', v_cur_id;
END $$;
