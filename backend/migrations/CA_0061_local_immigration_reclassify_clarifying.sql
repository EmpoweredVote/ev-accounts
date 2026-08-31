-- CA_0061_local_immigration_reclassify_clarifying.sql
--
-- Reclassify the pending `local-immigration` ("Local Immigration Enforcement")
-- rework from a MAJOR (substantive) revision to a MINOR (clarifying) one, then
-- publish it into the open season.
--
-- WHAT WAS THERE
--   `local-immigration` (topic b9ccee94-ad96-4f10-b655-889d8e5abe92; note the
--   frozen key predates the "Local Immigration Enforcement" short_title, so the
--   key stays 'local-immigration' and is never recomputed). Question pinned in
--   Season 1 (open) and Season 2 (draft), both pinning revision 1 (version 1,
--   published/current). Revision 2 (version 2, change_class 'substantive',
--   status 'draft', unpinned) held a one-chair reword and was filed in the
--   2026-08-28 "file them all" double-barrel batch with a self-flagged 146-row
--   re-audit "before Season 2 carry".
--
-- THE CHANGE (chair 2 only; chairs 1, 3, 4, 5 are byte-identical)
--   v1 chair 2: "Comply only with court-ordered detainers; PROTECT UNDOCUMENTED
--                CRIME VICTIMS AND WITNESSES FROM REFERRAL"
--   v2 chair 2: "Comply with ICE detainers only when they are ordered by a court"
--   It drops the second barrel — the victim/witness-protection clause — and keeps
--   the detainer-compliance threshold. That is structurally a double-barrel split,
--   which the 2026-08-28 rewording ruling files as "material" by default.
--
-- WHY MINOR, NOT MAJOR (evidence-based; ruling by Chris Andrews, 2026-08-31)
--   The material category exists to force a re-audit when seated rows' evidence
--   no longer fits the words. Here the dropped barrel is the one the evidence
--   never carried, so no seat is invalidated:
--     - A review of all 146 chair-2 rows found 0 seated on the victim/witness
--       barrel alone. 102 cite the detainer / cooperation-limit posture directly,
--       24 cite both (the surviving barrel still holds them), and the remaining
--       20 rest on "limit local cooperation with ICE" evidence (opposing
--       detention centers, sanctuary-style votes, the Safe Communities Act,
--       driver's-license bills) — the surviving axis position, not victim
--       protection. Where victim/witness language appears it is an incidental
--       companion, never the reason a row sits at chair 2 rather than 1 or 3.
--     - The victim/witness clause is an off-axis limb: it does not discriminate
--       between chairs on the cooperation axis. Dropping it WIDENS chair 2 (a
--       court-orders-only official who says nothing about victims now fits
--       cleanly), so no currently seated row falls out.
--   Removing a barrel that carried no evidentiary weight mis-seats no existing
--   row — the same class as the healthcare, fossil-fuels and taxes reworks, all
--   published as MINOR. So the change belongs in the open season now, not held
--   for the Season 2 open. No re-audit and no re-seat are owed (a chair-2-only
--   re-audit would be entirely confirmatory). The improvement in wording is real
--   but forward-looking: it only clarifies FUTURE Season 2 research, it does not
--   re-seat the past.
--
-- MECHANICS
--   `change_class` is immutable on a revision, and revision 2 is version 2 (the
--   substantive bump). The season read path serves "the latest published revision
--   OF THE PINNED VERSION", so a version-2 revision stays invisible until a season
--   pins version 2 — which is why it reads as major. Re-proposing the identical
--   chair-2 wording as 'clarifying' keeps version 1 and only bumps the revision
--   number; on publish, Season 1 (open) and Season 2 (draft) both resolve their
--   version-1 pin to the new revision automatically, with no repin.
--   Reclassifying therefore = reject revision 2, re-propose it as 'clarifying',
--   approve, publish. This migration does exactly that, via the same admin RPCs
--   the review UI calls.
--
--   The re-propose also RESTORES the per-stance `description`,
--   `supporting_points` and `example_perspectives` that revision 2 had dropped to
--   NULL/[] (revision 1 carried rich values: a description plus 3 supporting
--   points and 3 example perspectives per chair). None of the three is read by any
--   voter or admin surface today (all dormant), so this is faithfulness only — the
--   reword should not silently lose content. The improved chair-2 TEXT comes from
--   revision 2; the description, supporting points and example perspectives come
--   from revision 1.
--
-- Idempotent: the whole action is guarded on revision 2 still being an open
-- substantive v2 draft; a re-run after success is a no-op.

DO $$
DECLARE
  v_topic_id uuid;
  v_rev1_id  uuid;   -- published v1 — description / supporting / examples source
  v_rev2_id  uuid;   -- open substantive v2 draft — text source, to be rejected
  v_actor    uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';  -- actor that proposed rev2
  v_stances  jsonb;
  v_new_rev  uuid;
  v_rat      text := 'Reclassified the pending local-immigration (Local Immigration Enforcement) rework '
                     'from MAJOR (substantive, version 2) to MINOR (clarifying, version 1) and published '
                     'into the open season. The reword splits chair 2''s double barrel — "Comply only '
                     'with court-ordered detainers; protect undocumented crime victims and witnesses '
                     'from referral" -> "Comply with ICE detainers only when they are ordered by a '
                     'court" — dropping the victim/witness-protection clause and keeping the detainer-'
                     'compliance threshold. An evidence review of all 146 chair-2 rows found 0 seated '
                     'on the victim/witness barrel alone: 102 cite the detainer / cooperation-limit '
                     'posture, 24 cite both, and the other 20 rest on limiting local cooperation with '
                     'ICE. The dropped barrel is an off-axis limb that carried no seating weight, and '
                     'its removal WIDENS chair 2, so no seated row is mis-seated. Because no existing '
                     'seat is invalidated, the change belongs in the open season now rather than held '
                     'for the Season 2 open. Chairs 1, 3, 4 and 5 are unchanged. Reclassification '
                     'decision by Chris Andrews, 2026-08-31 (CA_0061).';
  v_note     text := 'Reworded option 2 to state a single position — comply with ICE detainers only '
                     'when a court has ordered them — instead of bundling that threshold together with '
                     'a separate victim-and-witness protection policy.';
BEGIN
  SELECT id INTO v_topic_id FROM inform.compass_topics WHERE topic_key = 'local-immigration';
  IF v_topic_id IS NULL THEN
    RAISE EXCEPTION 'CA_0061: topic "local-immigration" not found';
  END IF;

  SELECT id INTO v_rev1_id
    FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic_id AND version = 1 AND revision = 1;
  IF v_rev1_id IS NULL THEN
    RAISE EXCEPTION 'CA_0061: local-immigration v1 revision 1 not found';
  END IF;

  -- Guard: only act while the substantive v2 draft is still open (draft or approved).
  SELECT id INTO v_rev2_id
    FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic_id
     AND version = 2
     AND change_class = 'substantive'
     AND status IN ('draft', 'approved');
  IF v_rev2_id IS NULL THEN
    RAISE NOTICE 'CA_0061: no open substantive v2 draft for local-immigration — already reclassified; skipping';
    RETURN;
  END IF;

  -- Build the clarifying ladder: rev2 TEXT + rev1 DESCRIPTION + rev1 SUPPORTING_POINTS
  -- + rev1 EXAMPLE_PERSPECTIVES.
  SELECT jsonb_agg(
           jsonb_build_object(
             'value',                b.value,
             'text',                 b.text,
             'description',          a.description,
             'supporting_points',    to_jsonb(a.supporting_points),
             'example_perspectives', to_jsonb(a.example_perspectives)
           ) ORDER BY b.value)
    INTO v_stances
    FROM inform.compass_stance_revisions b
    JOIN inform.compass_stance_revisions a
      ON a.topic_revision_id = v_rev1_id AND a.value = b.value
   WHERE b.topic_revision_id = v_rev2_id;

  IF v_stances IS NULL OR jsonb_array_length(v_stances) <> 5 THEN
    RAISE EXCEPTION 'CA_0061: expected 5 stances, built %', COALESCE(jsonb_array_length(v_stances), 0);
  END IF;

  -- 1) Reject the substantive draft (only path to change its class).
  PERFORM inform.admin_reject_topic_revision(
    v_rev2_id, v_actor,
    'Reclassified to clarifying (minor) — the chair-2 double-barrel split drops the '
    'victim/witness-protection clause, which the 146 seated rows were never evidenced on '
    '(all 146 rest on the detainer / cooperation-limit posture). No seat is mis-seated, so it '
    'belongs in the open season rather than the Season 2 open. Re-proposed as version 1 by CA_0061.');

  -- 2) Re-propose the identical wording as CLARIFYING (keeps version 1), identity rung_map.
  v_new_rev := inform.admin_propose_topic_revision(
    'local-immigration',
    v_actor,
    'clarifying',
    'Local Immigration Enforcement',
    'Local Immigration Enforcement',
    'How should your community''s law enforcement relate to federal immigration enforcement?',
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

  RAISE NOTICE 'CA_0061: local-immigration reclassified to clarifying and published as %', v_new_rev;
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
  v_nsupp     int;
  v_nex       int;
  v_open_eff  uuid;   -- revision the OPEN season (Season 1) resolves to
BEGIN
  SELECT id INTO v_topic_id FROM inform.compass_topics WHERE topic_key = 'local-immigration';

  -- Exactly one published + current revision.
  SELECT count(*) INTO v_nrev
    FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic_id AND is_current = true AND status = 'published';
  IF v_nrev <> 1 THEN
    RAISE EXCEPTION 'CA_0061 verify: expected exactly 1 published/current revision, found %', v_nrev;
  END IF;

  SELECT id, version, change_class
    INTO v_cur_id, v_cur_ver, v_cur_class
    FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic_id AND is_current = true AND status = 'published';

  IF v_cur_ver <> 1 THEN
    RAISE EXCEPTION 'CA_0061 verify: current revision must be version 1, is %', v_cur_ver;
  END IF;
  IF v_cur_class <> 'clarifying' THEN
    RAISE EXCEPTION 'CA_0061 verify: current revision must be clarifying, is %', v_cur_class;
  END IF;

  -- No substantive v2 draft left in an open (draft/approved) state.
  SELECT count(*) INTO v_nrev
    FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic_id AND version = 2
     AND status IN ('draft', 'approved');
  IF v_nrev <> 0 THEN
    RAISE EXCEPTION 'CA_0061 verify: a v2 draft is still open (%), expected none', v_nrev;
  END IF;

  -- Five stances, all with restored description, supporting points and examples.
  SELECT count(*),
         count(description),
         count(*) FILTER (WHERE array_length(supporting_points, 1) = 3),
         count(*) FILTER (WHERE array_length(example_perspectives, 1) = 3)
    INTO v_nstance, v_ndesc, v_nsupp, v_nex
    FROM inform.compass_stance_revisions
   WHERE topic_revision_id = v_cur_id;
  IF v_nstance <> 5 THEN
    RAISE EXCEPTION 'CA_0061 verify: expected 5 stances, found %', v_nstance;
  END IF;
  IF v_ndesc <> 5 THEN
    RAISE EXCEPTION 'CA_0061 verify: expected 5 restored descriptions, found %', v_ndesc;
  END IF;
  IF v_nsupp <> 5 THEN
    RAISE EXCEPTION 'CA_0061 verify: expected 5 chairs with 3 supporting points, found %', v_nsupp;
  END IF;
  IF v_nex <> 5 THEN
    RAISE EXCEPTION 'CA_0061 verify: expected 5 chairs with 3 example perspectives, found %', v_nex;
  END IF;

  -- Chair 2 carries the reworded (single-position) text and NOT the old victim clause.
  PERFORM 1 FROM inform.compass_stance_revisions
   WHERE topic_revision_id = v_cur_id AND value = 2
     AND text ILIKE '%only when they are ordered by a court%';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CA_0061 verify: chair-2 reworded text not present on current revision';
  END IF;
  PERFORM 1 FROM inform.compass_stance_revisions
   WHERE topic_revision_id = v_cur_id AND value = 2
     AND text ILIKE '%crime victims and witnesses%';
  IF FOUND THEN
    RAISE EXCEPTION 'CA_0061 verify: chair-2 still carries the old victim/witness clause';
  END IF;

  -- Chairs 1, 3, 4, 5 unchanged from the published v1 revision-1 text.
  PERFORM 1
    FROM inform.compass_stance_revisions cur
    JOIN inform.compass_stance_revisions old
      ON old.value = cur.value
     AND old.topic_revision_id = (SELECT id FROM inform.compass_topic_revisions
                                   WHERE topic_id = v_topic_id AND version = 1 AND revision = 1)
   WHERE cur.topic_revision_id = v_cur_id
     AND cur.value IN (1, 3, 4, 5)
     AND cur.text <> old.text;
  IF FOUND THEN
    RAISE EXCEPTION 'CA_0061 verify: an unchanged chair (1/3/4/5) diverged from revision 1 text';
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
    RAISE EXCEPTION 'CA_0061 verify: open season resolves to % but current is %', v_open_eff, v_cur_id;
  END IF;

  RAISE NOTICE 'CA_0061 verify OK: local-immigration now clarifying v1 rev % (published/current), open season serves it', v_cur_id;
END $$;
