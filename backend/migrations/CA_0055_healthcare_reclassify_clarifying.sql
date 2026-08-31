-- CA_0055_healthcare_reclassify_clarifying.sql
--
-- Reclassify the pending `healthcare` rework from a MAJOR (substantive) revision
-- to a MINOR (clarifying) one, then publish it into the open season.
--
-- WHAT WAS THERE
--   `healthcare` (topic e8dad4a8-eb93-4931-91f5-d8fb5d7dd529), question pinned in
--   Season 1 (open) and Season 2 (draft), both pinning revision 1 (version 1,
--   published/current). Revision 2 (7919d777…, version 2, change_class
--   'substantive', status 'draft', unpinned) held a one-chair reword.
--
-- THE CHANGE (chair 1 only; chairs 2-5 are byte-identical)
--   v1 chair 1: "…free and available to everyone, paid for AND RUN BY the public sector"
--   v2 chair 1: "…free and available to everyone, FULLY PAID FOR by the public sector"
--   It drops the words "and run by" — removing the public-OPERATION (delivery)
--   claim and keeping only the public-PAYMENT claim. In model terms it moves the
--   chair from the NHS model (public pay + public delivery) to the Medicare-for-
--   All model (public pay; delivery unspecified). That is structurally a double-
--   barrel split, which the 2026-08-28 rewording ruling files as "material".
--
-- WHY MINOR, NOT MAJOR (evidence-based; ruling by Chris Andrews, 2026-08-30)
--   The material category exists to force a re-audit when seated rows' evidence
--   no longer fits the words. Here the dropped barrel is the one the evidence
--   never carried, so no seat is invalidated:
--     - A review of all 354 chair-1 rows found them seated on single-payer /
--       Medicare-for-All support — a PAYMENT model ("cosponsor of the Medicare
--       for All Act", "explicit Medicare for All advocate"). Almost none are
--       evidenced on government-RUN delivery; where "run by" appears in the
--       reasoning it is the writer echoing the old chair wording, not evidence.
--       So the v2 text matches the evidence already gathered BETTER than v1 did.
--     - A chair-2 leakage check found no single-payer-only rows wrongly held
--       below chair 1 by the old "run by" clause; the chair-2 single-payer
--       mentions are incidental (a years-old co-sponsorship, a study pathway)
--       and those rows genuinely hold the mixed model.
--   Removing a barrel that carried no evidentiary weight mis-seats no existing
--   row — the same class as the fossil-fuels and taxes reworks, both published as
--   MINOR. So the change belongs in the open season now, not held for the
--   Season 2 open. No re-audit and no re-seat are owed (a chair-1-only re-audit
--   would be entirely confirmatory).
--
-- MECHANICS
--   `change_class` is immutable on a revision, and revision 2 is version 2 (the
--   substantive bump). The season read path serves "the latest published revision
--   OF THE PINNED VERSION" (compass_topics_promoted + the LATERAL in
--   getPromotedTopics), so a version-2 revision stays invisible until a season
--   pins version 2 — which is why it reads as major. Re-proposing the identical
--   wording as 'clarifying' keeps version 1 and only bumps the revision number;
--   on publish, Season 1 (open) and Season 2 (draft) both resolve their version-1
--   pin to the new revision automatically, with no repin.
--   Reclassifying therefore = reject revision 2, re-propose it as 'clarifying',
--   approve, publish. This migration does exactly that, via the same admin RPCs
--   the review UI calls.
--
--   The re-propose also RESTORES the per-stance `description` and
--   `example_perspectives` that revision 2 had dropped to NULL/[] (revision 1
--   carried rich values). Neither field is read by any voter or admin surface
--   today (both are dormant), so this is faithfulness only — the reword should
--   not silently lose content. The improved chair-1 TEXT comes from revision 2;
--   the descriptions and example perspectives come from revision 1.
--
-- Idempotent: the whole action is guarded on revision 2 still being an open
-- substantive v2 draft; a re-run after success is a no-op.

DO $$
DECLARE
  v_topic_id uuid;
  v_rev1_id  uuid;   -- published v1 — description / example_perspectives source
  v_rev2_id  uuid;   -- open substantive v2 draft — text source, to be rejected
  v_actor    uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';  -- actor that proposed rev2
  v_stances  jsonb;
  v_new_rev  uuid;
  v_rat      text := 'Reclassified the pending healthcare rework from MAJOR (substantive, version 2) '
                     'to MINOR (clarifying, version 1) and published into the open season. The reword '
                     'splits chair 1''s double barrel — "paid for and run by the public sector" -> '
                     '"fully paid for by the public sector" — dropping the public-OPERATION (delivery) '
                     'claim and keeping public PAYMENT. An evidence review of all 354 chair-1 rows found '
                     'them seated on single-payer / Medicare-for-All support (a payment model); almost '
                     'none are evidenced on government-run delivery, so the dropped barrel carried no '
                     'evidentiary weight and no seated row is mis-seated by its removal. A chair-2 '
                     'leakage check found no single-payer-only rows wrongly held below chair 1. Because '
                     'no existing seat is invalidated, the change belongs in the open season now rather '
                     'than held for the Season 2 open. Chairs 2-5 are unchanged. Reclassification '
                     'decision by Chris Andrews, 2026-08-30 (CA_0055).';
  v_note     text := 'Reworded option 1 to state a single position — publicly funded universal coverage — '
                     'instead of bundling public funding together with public operation of care.';
BEGIN
  SELECT id INTO v_topic_id FROM inform.compass_topics WHERE topic_key = 'healthcare';
  IF v_topic_id IS NULL THEN
    RAISE EXCEPTION 'CA_0055: topic "healthcare" not found';
  END IF;

  SELECT id INTO v_rev1_id
    FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic_id AND version = 1 AND revision = 1;
  IF v_rev1_id IS NULL THEN
    RAISE EXCEPTION 'CA_0055: healthcare v1 revision 1 not found';
  END IF;

  -- Guard: only act while the substantive v2 draft is still open (draft or approved).
  SELECT id INTO v_rev2_id
    FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic_id
     AND version = 2
     AND change_class = 'substantive'
     AND status IN ('draft', 'approved');
  IF v_rev2_id IS NULL THEN
    RAISE NOTICE 'CA_0055: no open substantive v2 draft for healthcare — already reclassified; skipping';
    RETURN;
  END IF;

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
    RAISE EXCEPTION 'CA_0055: expected 5 stances, built %', COALESCE(jsonb_array_length(v_stances), 0);
  END IF;

  -- 1) Reject the substantive draft (only path to change its class).
  PERFORM inform.admin_reject_topic_revision(
    v_rev2_id, v_actor,
    'Reclassified to clarifying (minor) — the chair-1 double-barrel split drops the '
    'public-operation claim, which the 354 seated rows were never evidenced on (they hold '
    'single-payer / Medicare-for-All, a payment model). No seat is mis-seated, so it belongs '
    'in the open season rather than the Season 2 open. Re-proposed as version 1 by CA_0055.');

  -- 2) Re-propose the identical wording as CLARIFYING (keeps version 1), identity rung_map.
  v_new_rev := inform.admin_propose_topic_revision(
    'healthcare',
    v_actor,
    'clarifying',
    'Healthcare Access',
    'Healthcare',
    'What role should government play in healthcare access?',
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

  RAISE NOTICE 'CA_0055: healthcare reclassified to clarifying and published as %', v_new_rev;
END $$;

-- ---------------------------------------------------------------------------
-- Post-verify gate
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_topic_id  uuid;
  v_cur_id    uuid;
  v_cur_ver   int;
  v_cur_class inform.change_class;
  v_nrev      int;
  v_nstance   int;
  v_ndesc     int;
  v_open_eff  uuid;   -- revision the OPEN season (Season 1) resolves to
BEGIN
  SELECT id INTO v_topic_id FROM inform.compass_topics WHERE topic_key = 'healthcare';

  -- Exactly one published + current revision.
  SELECT count(*) INTO v_nrev
    FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic_id AND is_current = true AND status = 'published';
  IF v_nrev <> 1 THEN
    RAISE EXCEPTION 'CA_0055 verify: expected exactly 1 published/current revision, found %', v_nrev;
  END IF;

  SELECT id, version, change_class
    INTO v_cur_id, v_cur_ver, v_cur_class
    FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic_id AND is_current = true AND status = 'published';

  IF v_cur_ver <> 1 THEN
    RAISE EXCEPTION 'CA_0055 verify: current revision must be version 1, is %', v_cur_ver;
  END IF;
  IF v_cur_class <> 'clarifying' THEN
    RAISE EXCEPTION 'CA_0055 verify: current revision must be clarifying, is %', v_cur_class;
  END IF;

  -- No substantive v2 draft left in an open (draft/approved) state.
  SELECT count(*) INTO v_nrev
    FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic_id AND version = 2
     AND status IN ('draft', 'approved');
  IF v_nrev <> 0 THEN
    RAISE EXCEPTION 'CA_0055 verify: a v2 draft is still open (%), expected none', v_nrev;
  END IF;

  -- Five stances, all with a restored description.
  SELECT count(*), count(description)
    INTO v_nstance, v_ndesc
    FROM inform.compass_stance_revisions
   WHERE topic_revision_id = v_cur_id;
  IF v_nstance <> 5 THEN
    RAISE EXCEPTION 'CA_0055 verify: expected 5 stances, found %', v_nstance;
  END IF;
  IF v_ndesc <> 5 THEN
    RAISE EXCEPTION 'CA_0055 verify: expected 5 restored descriptions, found %', v_ndesc;
  END IF;

  -- Chair 1 carries the reworded (payment-only) text and NOT the old "run by" clause.
  PERFORM 1 FROM inform.compass_stance_revisions
   WHERE topic_revision_id = v_cur_id AND value = 1
     AND text ILIKE '%fully paid for by the public sector%';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CA_0055 verify: chair-1 reworded text not present on current revision';
  END IF;
  PERFORM 1 FROM inform.compass_stance_revisions
   WHERE topic_revision_id = v_cur_id AND value = 1
     AND text ILIKE '%run by the public sector%';
  IF FOUND THEN
    RAISE EXCEPTION 'CA_0055 verify: chair-1 still carries the old "run by" clause';
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
    RAISE EXCEPTION 'CA_0055 verify: open season resolves to % but current is %', v_open_eff, v_cur_id;
  END IF;

  RAISE NOTICE 'CA_0055 verify OK: healthcare now clarifying v1 rev % (published/current), open season serves it', v_cur_id;
END $$;
