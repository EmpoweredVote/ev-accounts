-- CA_0059_jail_capacity_reclassify_clarifying.sql
--
-- Reclassify the pending `jail-capacity` rework from a MAJOR (substantive) revision
-- to a MINOR (clarifying) one, then publish it into the open season.
--
-- WHAT WAS THERE
--   `jail-capacity` (topic c267e137-0ff9-4e7d-9d13-e3cea1756cd0), pinned in Season 1
--   (open) as question 18, at revision 1 (version 1, published/current). Revision 2
--   (6a79f4de…, version 2, change_class 'substantive', status 'draft', identity
--   rung_map, UNPINNED) held a two-chair double-barrel reword. Season 2 (draft) does
--   NOT pin this topic at all, so as a version-2 revision it could never reach a
--   voter surface without a new Season-2 version-2 pin — which is why it read as major.
--
-- THE CHANGE (chairs 2 and 5 only; chairs 1, 3, 4 are byte-identical)
--   chair 2 (104 seated):
--     v1: "…through PRETRIAL DIVERSION, BAIL REFORM, AND TREATMENT ALTERNATIVES rather than building new capacity"
--     v2: "…through ALTERNATIVES TO INCARCERATION rather than building new capacity"
--     Replaces a three-item conjunction with the umbrella term that SUBSUMES all
--     three named items (bail reform included). Bail reform, pretrial diversion, and
--     treatment are all alternatives to incarceration, so the umbrella is a strict
--     BROADENING of the chair, not a narrowing.
--   chair 5 (10 seated):
--     v1: "Expanding jail capacity AND ENFORCEMENT as the primary response to crime, prioritizing detention over alternatives"
--     v2: "Expanding jail capacity as the primary response to crime, prioritizing detention over alternatives"
--     Drops the welded "and enforcement" conjunct. Also a strict BROADENING (one
--     fewer required conjunct).
--   Both edits are the same shape as the healthcare and taxes reworks: an
--   over-demanding / welded limb removed, which the 2026-08-28 rewording ruling
--   files structurally as "material".
--
-- WHY MINOR, NOT MAJOR (evidence-based; ruling by Chris Andrews, 2026-08-31)
--   The material category exists to force a re-audit when seated rows' evidence no
--   longer fits the words (CA_0055 refinement). A BROADENING edit cannot invalidate
--   a seat: every row that satisfied the stricter old wording still satisfies the
--   looser new wording. So mis-seating risk is zero; at most the reword opens an
--   optional backfill of previously-blanked rows (under-seating).
--     - chair 2: "alternatives to incarceration" fully covers the old enumeration
--       (diversion / bail reform / treatment). No chair-2 seat can be invalidated,
--       so no per-row check is owed for correctness.
--     - chair 5: the only thin risk was a row seated PURELY on the dropped
--       "enforcement" barrel (policing rhetoric with no detention/capacity
--       evidence), which the capacity-only v2 text would no longer describe. All 10
--       chair-5 rows were read (2026-08-31). Every one carries detention-first /
--       incarceration-expansion / anti-diversion evidence that the surviving v2
--       wording ("Expanding jail capacity as the primary response to crime,
--       prioritizing detention over alternatives") still describes:
--         Steve Hilton  — "Expanding Prison Capacity To Fight Crime" paper (capacity, explicit)
--         Carl DeMaio   — repeal parole reform, prosecute juveniles as adults ("expanding incarceration")
--         Marsha Blackburn — mandatory minimums, "incarceration expansion over diversion"
--         Tom Cotton    — "under-incarceration problem", against First Step Act
--         David Haggan  — bail bill to expand pretrial DETENTION ("detention over release")
--         James Risch   — against First Step Act (opposing sentence reduction)
--         Ashley Moody  — anti-reform / detainer compliance / opposing First Step Act
--         John Kennedy  — against First Step Act, tough-on-crime penalties
--         Rick Scott    — capital punishment, executions, opposes diversion / detention-first
--         Tommy Tuberville — "expanding detention capacity", opposes bail reform / diversion
--       Rows that also mention enforcement (Moody, Kennedy, Tuberville, Scott) pair
--       it with detention / incarceration evidence — none is seated on the dropped
--       barrel alone. So no chair-5 seat is invalidated by its removal.
--   Removing barrels that carried no seat-placing weight mis-seats no existing row —
--   the same class as fossil-fuels, taxes, and healthcare, all published as MINOR.
--   The change belongs in the open season now, not held for the Season 2 open. No
--   re-audit and no re-seat are owed; the rev2 rationale's "⚠ RE-AUDIT 114 rows"
--   line was the pre-CA_0055 conservative default and does not survive this review.
--
-- MECHANICS
--   `change_class` is immutable on a revision, and revision 2 is version 2 (the
--   substantive bump). The season read path serves "the latest published revision
--   OF THE PINNED VERSION" (season_questions pin + the LATERAL in getPromotedTopics),
--   so a version-2 revision stays invisible until a season pins version 2.
--   Re-proposing the identical wording as 'clarifying' keeps version 1 and only
--   bumps the revision number; on publish, Season 1 (open) resolves its version-1
--   pin to the new revision automatically, with no repin.
--   Reclassifying therefore = reject revision 2, re-propose it as 'clarifying',
--   approve, publish. This migration does exactly that, via the same admin RPCs the
--   review UI calls.
--
--   The re-propose also RESTORES the per-stance `description` and
--   `example_perspectives` that revision 2 had dropped to NULL/[] (revision 1
--   carried rich values). Neither field is read by any voter or admin surface today
--   (both are dormant), so this is faithfulness only. The improved chair-2 and
--   chair-5 TEXT comes from revision 2; the descriptions and example perspectives
--   come from revision 1.
--
-- Idempotent: the whole action is guarded on revision 2 still being an open
-- substantive v2 draft; a re-run after success is a no-op.

DO $$
DECLARE
  v_topic_id uuid;
  v_rev1_id  uuid;   -- published v1 — description / example_perspectives source
  v_rev2_id  uuid;   -- open substantive v2 draft — text source, to be rejected
  v_actor    uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';  -- chrisandrewsedu; actor that proposed rev2
  v_stances  jsonb;
  v_new_rev  uuid;
  v_rat      text := 'Reclassified the pending jail-capacity rework from MAJOR (substantive, version 2) '
                     'to MINOR (clarifying, version 1) and published into the open season. The reword '
                     'broadens two chairs by removing welded limbs: chair 2 "pretrial diversion, bail '
                     'reform, and treatment alternatives" -> "alternatives to incarceration" (the umbrella '
                     'that subsumes all three), and chair 5 "expanding jail capacity and enforcement" -> '
                     '"expanding jail capacity" (drops the enforcement conjunct). Both are strict '
                     'broadenings, so no seat is invalidated: every row that met the stricter old wording '
                     'meets the looser new wording. All 10 chair-5 rows were read and each carries '
                     'detention-first / incarceration-expansion evidence the surviving wording still '
                     'describes; none was seated on the dropped "enforcement" barrel alone. Chair 2 needs '
                     'no per-row check (pure umbrella broadening). Because no existing seat is invalidated, '
                     'the change belongs in the open season now rather than held for the Season 2 open. '
                     'Chairs 1, 3, 4 are unchanged. Reclassification decision by Chris Andrews, 2026-08-31 '
                     '(CA_0059).';
  v_note     text := 'Reworded options 2 and 5 so each states a single position a person could hold on its '
                     'own, instead of two or more welded together that supporters routinely split on.';
BEGIN
  SELECT id INTO v_topic_id FROM inform.compass_topics WHERE topic_key = 'jail-capacity';
  IF v_topic_id IS NULL THEN
    RAISE EXCEPTION 'CA_0059: topic "jail-capacity" not found';
  END IF;

  SELECT id INTO v_rev1_id
    FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic_id AND version = 1 AND revision = 1;
  IF v_rev1_id IS NULL THEN
    RAISE EXCEPTION 'CA_0059: jail-capacity v1 revision 1 not found';
  END IF;

  -- Guard: only act while the substantive v2 draft is still open (draft or approved).
  SELECT id INTO v_rev2_id
    FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic_id
     AND version = 2
     AND change_class = 'substantive'
     AND status IN ('draft', 'approved');
  IF v_rev2_id IS NULL THEN
    RAISE NOTICE 'CA_0059: no open substantive v2 draft for jail-capacity — already reclassified; skipping';
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
    RAISE EXCEPTION 'CA_0059: expected 5 stances, built %', COALESCE(jsonb_array_length(v_stances), 0);
  END IF;

  -- 1) Reject the substantive draft (only path to change its class).
  PERFORM inform.admin_reject_topic_revision(
    v_rev2_id, v_actor,
    'Reclassified to clarifying (minor) — chairs 2 and 5 are broadened by removing welded limbs '
    '("bail reform" folded into "alternatives to incarceration"; "and enforcement" dropped). A '
    'broadening invalidates no seat, and all 10 chair-5 rows were verified to carry '
    'detention/incarceration evidence the surviving wording still describes. Belongs in the open '
    'season, not the Season 2 open. Re-proposed as version 1 by CA_0059.');

  -- 2) Re-propose the identical wording as CLARIFYING (keeps version 1), identity rung_map.
  v_new_rev := inform.admin_propose_topic_revision(
    'jail-capacity',
    v_actor,
    'clarifying',
    'Jail Capacity and Incarceration Alternatives',
    'Jail Capacity',
    'How should government respond to jail overcrowding and criminal justice demand?',
    v_stances,
    v_rat,
    v_note,
    NULL,
    '{"1":1,"2":2,"3":3,"4":4,"5":5}'::jsonb
  );

  -- 3) Approve.
  PERFORM inform.admin_approve_topic_revision(v_new_rev, v_actor);

  -- 4) Publish -> is_current; Season 1 (version-1 pin) serves it, no repin.
  PERFORM inform.admin_publish_topic_revision(v_new_rev, v_actor);

  RAISE NOTICE 'CA_0059: jail-capacity reclassified to clarifying and published as %', v_new_rev;
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
  SELECT id INTO v_topic_id FROM inform.compass_topics WHERE topic_key = 'jail-capacity';

  -- Exactly one published + current revision.
  SELECT count(*) INTO v_nrev
    FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic_id AND is_current = true AND status = 'published';
  IF v_nrev <> 1 THEN
    RAISE EXCEPTION 'CA_0059 verify: expected exactly 1 published/current revision, found %', v_nrev;
  END IF;

  SELECT id, version, change_class
    INTO v_cur_id, v_cur_ver, v_cur_class
    FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic_id AND is_current = true AND status = 'published';

  IF v_cur_ver <> 1 THEN
    RAISE EXCEPTION 'CA_0059 verify: current revision must be version 1, is %', v_cur_ver;
  END IF;
  IF v_cur_class <> 'clarifying' THEN
    RAISE EXCEPTION 'CA_0059 verify: current revision must be clarifying, is %', v_cur_class;
  END IF;

  -- No substantive v2 draft left in an open (draft/approved) state.
  SELECT count(*) INTO v_nrev
    FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic_id AND version = 2
     AND status IN ('draft', 'approved');
  IF v_nrev <> 0 THEN
    RAISE EXCEPTION 'CA_0059 verify: a v2 draft is still open (%), expected none', v_nrev;
  END IF;

  -- Five stances, all with a restored description.
  SELECT count(*), count(description)
    INTO v_nstance, v_ndesc
    FROM inform.compass_stance_revisions
   WHERE topic_revision_id = v_cur_id;
  IF v_nstance <> 5 THEN
    RAISE EXCEPTION 'CA_0059 verify: expected 5 stances, found %', v_nstance;
  END IF;
  IF v_ndesc <> 5 THEN
    RAISE EXCEPTION 'CA_0059 verify: expected 5 restored descriptions, found %', v_ndesc;
  END IF;

  -- Chair 2 carries the umbrella wording and NOT the old "bail reform" enumeration.
  PERFORM 1 FROM inform.compass_stance_revisions
   WHERE topic_revision_id = v_cur_id AND value = 2
     AND text ILIKE '%alternatives to incarceration%';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CA_0059 verify: chair-2 umbrella text not present on current revision';
  END IF;
  PERFORM 1 FROM inform.compass_stance_revisions
   WHERE topic_revision_id = v_cur_id AND value = 2
     AND text ILIKE '%bail reform%';
  IF FOUND THEN
    RAISE EXCEPTION 'CA_0059 verify: chair-2 still carries the old "bail reform" enumeration';
  END IF;

  -- Chair 5 carries the capacity-only wording and NOT the old "and enforcement" conjunct.
  PERFORM 1 FROM inform.compass_stance_revisions
   WHERE topic_revision_id = v_cur_id AND value = 5
     AND text ILIKE '%Expanding jail capacity as the primary response%';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CA_0059 verify: chair-5 reworded text not present on current revision';
  END IF;
  PERFORM 1 FROM inform.compass_stance_revisions
   WHERE topic_revision_id = v_cur_id AND value = 5
     AND text ILIKE '%capacity and enforcement%';
  IF FOUND THEN
    RAISE EXCEPTION 'CA_0059 verify: chair-5 still carries the old "and enforcement" conjunct';
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
    RAISE EXCEPTION 'CA_0059 verify: open season resolves to % but current is %', v_open_eff, v_cur_id;
  END IF;

  RAISE NOTICE 'CA_0059 verify OK: jail-capacity now clarifying v1 rev % (published/current), open season serves it', v_cur_id;
END $$;
