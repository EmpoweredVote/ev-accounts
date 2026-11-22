-- CA_0412_gun_policy_s3_rev6_rung4_rewrite.sql
-- Author: Chris Andrews (CA_ namespace). Slot reserved from the steward allocator 2026-11-22.
-- APPLIED 2026-11-22 on production after Chris Andrews' yes ("Yes, apply"): revision 6 = af752af5-ccd9-4225-acdf-f904faa088e2
-- (v3, approved/parked, pinned in draft Season 3); revision 5 41349e39… rejected; 3,337 answer and 3,337 context rows
-- carried; open Season 2 pin unchanged (1a72d5df…).
-- Dry run on prod 2026-11-22 (body twice inside BEGIN, forced RAISE): gate OK on both runs; first run carried
-- 3,337 + 3,337 rows; second run skipped every step (0 rows carried); voter answers reworded x4; rollback confirmed
-- from a new session. The answer count (3337) was read just before each run.
--
-- =============================================================================
-- CA_0412: gun-policy — Season 3 revision 6 (rung 4 reworded), approved and pinned in the DRAFT season;
--          the draft-season rows are carried from revision 5
-- =============================================================================
-- Built from CA_0356 (revision 5) and the carry step of CA_0334 (voting-rights).
--
-- WHAT THIS DOES
--   0b. Drops the two pin keys, moves the draft-season pin back to the published control (revision 3) and rejects
--       revision 5 (41349e39-394a-47b9-81c6-a79f8ec60425), approved and parked by CA_0356, never published.
--   1.  Proposes revision 6: change_class substantive, version 3, identity rung map from revision 3. Rungs:
--        1  Ban civilian gun ownership, except with a permit for hunting or sport.
--        2  Ban a type of firearm or magazine, such as assault-style weapons.
--        3  Add limits on buying, having or carrying a gun, such as checking every buyer, red-flag orders, waiting periods or bans on guns in hospitals.
--        4  Make buying, having or carrying a gun easier, such as honoring carry permits from other states, ending a waiting period or ending a red-flag law.
--        5  Repeal laws that require a permit or registration for a gun, such as the permit to carry.
--       Sets guidance (unchanged), approves and PARKS it (not published; the open season is untouched).
--   1b. Pins revision 6 in the draft season, re-points every draft-season politician_answers and
--       politician_context row on this topic from revision 5 to revision 6 (no value, reasoning or evidence
--       changes), and re-adds the pin keys, which re-checks every row. All in one transaction.
--   2.  Post-verify gate.
--
-- Checked at the dry run: no other table holds this topic's revision id in a key the re-pin breaks
-- (stance_research_review keeps the revision it was reviewed against; 1 pending review row still cites revision 5
-- and must be re-coded before it is approved); season question counts 60 open, 60 draft on 2026-11-22.
-- 🔴 Other sessions write gun-policy rows into the draft season. Between the count read and the apply, nobody
--    may write: a row written on revision 5 after the apply would fail its pin key.
-- After the apply: set revision_id and ladder_text in stage5/coder-config.json, update the bill tables and
-- coder-rulings.md, run the re-code round, run the adversarial check, then write the changed rows.
-- =============================================================================

BEGIN;

-- ── 0. Preconditions ─────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics
                 WHERE id = '56125933-b82a-46c5-847b-b2e9a146b89f' AND topic_key = 'gun-policy') THEN
    RAISE EXCEPTION 'CA_0412 precondition: gun-policy topic id/key mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons
                 WHERE id = '7b3a066c-815d-43b2-a6a0-6a3029778075' AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0412 precondition: the target season is not a draft (its pins would be frozen)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons
                 WHERE id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND status = 'open') THEN
    RAISE EXCEPTION 'CA_0412 precondition: 86d893a1-c1a2-4bbf-b4e5-69ec43221194 is not the open season';
  END IF;
  -- The open season's pin for this topic. It is usually 44615418-e111-4f2f-a256-92fcf74b0f2f, but not when a clarifying
  -- revision was published after the open season locked its pins (the season keeps the older pin and
  -- is served the newer text by version). Fill 1a72d5df-746f-4469-ab9b-1d3e8bc33b8d from the facts query's 'pin' row.
  IF NOT EXISTS (SELECT 1 FROM inform.season_questions
                 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id = '56125933-b82a-46c5-847b-b2e9a146b89f'
                   AND topic_revision_id = '1a72d5df-746f-4469-ab9b-1d3e8bc33b8d') THEN
    RAISE EXCEPTION 'CA_0412 precondition: the open season does not pin 1a72d5df-746f-4469-ab9b-1d3e8bc33b8d for this topic';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = '44615418-e111-4f2f-a256-92fcf74b0f2f' AND is_current AND status = 'published') THEN
    RAISE EXCEPTION 'CA_0412 precondition: 44615418-e111-4f2f-a256-92fcf74b0f2f is not the current published revision';
  END IF;
  -- Revision 6 replaces revision 5 (41349e39-394a-47b9-81c6-a79f8ec60425, approved and parked by CA_0356, pinned in the draft
  -- season). On a first run it must still be approved and pinned there; on a re-run it is rejected.
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = '41349e39-394a-47b9-81c6-a79f8ec60425' AND topic_id = '56125933-b82a-46c5-847b-b2e9a146b89f'
                   AND status IN ('approved','rejected')) THEN
    RAISE EXCEPTION 'CA_0412 precondition: revision 5 41349e39-394a-47b9-81c6-a79f8ec60425 is missing or not approved/rejected';
  END IF;
  IF EXISTS (SELECT 1 FROM inform.compass_topic_revisions WHERE id = '41349e39-394a-47b9-81c6-a79f8ec60425' AND status = 'approved')
     AND NOT EXISTS (SELECT 1 FROM inform.season_questions
                      WHERE season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075' AND topic_id = '56125933-b82a-46c5-847b-b2e9a146b89f'
                        AND topic_revision_id = '41349e39-394a-47b9-81c6-a79f8ec60425') THEN
    RAISE EXCEPTION 'CA_0412 precondition: revision 5 is approved but the draft season does not pin it';
  END IF;
  -- The draft-season rows on this topic are CARRIED to the new revision, not refused (RULINGS.md, Stage 4:
  -- "a draft that replaces an approved, unpublished revision"; runner 2026-11-22). The count was read just
  -- before the dry run; other sessions write rows on this topic, so RE-READ it before every run.
  IF (SELECT count(*) FROM inform.politician_answers
       WHERE topic_id = '56125933-b82a-46c5-847b-b2e9a146b89f' AND season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075') <> 3337 THEN
    RAISE EXCEPTION 'CA_0412 precondition: expected 3337 draft-season answers on this topic (re-measure; another session may have written rows)';
  END IF;
  IF EXISTS (SELECT 1 FROM inform.politician_answers
              WHERE topic_id = '56125933-b82a-46c5-847b-b2e9a146b89f' AND season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075'
                AND topic_revision_id NOT IN ('41349e39-394a-47b9-81c6-a79f8ec60425')
                AND topic_revision_id NOT IN (SELECT id FROM inform.compass_topic_revisions WHERE topic_id = '56125933-b82a-46c5-847b-b2e9a146b89f' AND revision = 6)) THEN
    RAISE EXCEPTION 'CA_0412 precondition: a draft-season answer cites a revision other than 5 or 6';
  END IF;
END $$;

CREATE TEMP TABLE IF NOT EXISTS slot_pre_answers ON COMMIT DROP AS
  SELECT politician_id, value FROM inform.politician_answers
   WHERE topic_id = '56125933-b82a-46c5-847b-b2e9a146b89f' AND season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075';

-- ── 0b. Reject revision 5 (approved, pinned, never published) ───────────────────────────────────
-- The pin keys are dropped first: the draft-season rows cite revision 5 until step 1b re-points them.
ALTER TABLE inform.politician_answers DROP CONSTRAINT IF EXISTS politician_answers_pin_fkey;
ALTER TABLE inform.politician_context DROP CONSTRAINT IF EXISTS politician_context_pin_fkey;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM inform.compass_topic_revisions WHERE id = '41349e39-394a-47b9-81c6-a79f8ec60425' AND status = 'approved') THEN
    PERFORM inform.admin_season_pin_revision('7b3a066c-815d-43b2-a6a0-6a3029778075', '56125933-b82a-46c5-847b-b2e9a146b89f', '44615418-e111-4f2f-a256-92fcf74b0f2f', '854fbc06-40fc-458d-b523-20ef8e5ad1b2');
    PERFORM inform.admin_reject_topic_revision('41349e39-394a-47b9-81c6-a79f8ec60425', '854fbc06-40fc-458d-b523-20ef8e5ad1b2',
      $why$Replaced before Season 3 opened by revision 6: rung 4 reworded from "Make carrying a gun easier" to "Make buying, having or carrying a gun easier" (runner Chris Andrews, 2026-11-21 and 2026-11-22). Research folder stage5/RUNG-REVIEW-2-2026-11-21.md.$why$);
    RAISE NOTICE 'CA_0412: draft season re-pinned to revision 3 and revision 5 rejected (replaced)';
  ELSE
    RAISE NOTICE 'CA_0412: revision 5 already rejected — skipping';
  END IF;
END $$;

-- ── 1. Lifecycle: propose → set guidance → approve (park) → pin in the draft season ─────────────
DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
  v_key      CONSTANT text := 'gun-policy';
  v_topic    CONSTANT uuid := '56125933-b82a-46c5-847b-b2e9a146b89f';
  v_draft    CONSTANT uuid := '7b3a066c-815d-43b2-a6a0-6a3029778075';
  v_guidance CONSTANT text := $g$Where the balance falls between access to firearms and restrictions meant to reduce harm.$g$;
  v_rungs    CONSTANT jsonb := jsonb_build_array(
    jsonb_build_object('value', 1, 'text', $r1$Ban civilian gun ownership, except with a permit for hunting or sport.$r1$),
    jsonb_build_object('value', 2, 'text', $r2$Ban a type of firearm or magazine, such as assault-style weapons.$r2$),
    jsonb_build_object('value', 3, 'text', $r3$Add limits on buying, having or carrying a gun, such as checking every buyer, red-flag orders, waiting periods or bans on guns in hospitals.$r3$),
    jsonb_build_object('value', 4, 'text', $r4$Make buying, having or carrying a gun easier, such as honoring carry permits from other states, ending a waiting period or ending a red-flag law.$r4$),
    jsonb_build_object('value', 5, 'text', $r5$Repeal laws that require a permit or registration for a gun, such as the permit to carry.$r5$)
  );
  v_open     uuid;
  v_new      uuid;
BEGIN
  -- The new revision is the approved/published revision 5 whose five rungs match these texts
  -- exactly. Requiring the number stops an older revision that happens to share the rung texts from
  -- being taken for it.
  SELECT r.id INTO v_new FROM inform.compass_topic_revisions r
   WHERE r.topic_id = v_topic AND r.id <> '44615418-e111-4f2f-a256-92fcf74b0f2f' AND r.revision = 6
     AND r.status IN ('approved','published')
     AND (SELECT count(*) FROM inform.compass_stance_revisions s
           JOIN jsonb_array_elements(v_rungs) AS x(elem) ON (x.elem->>'value')::int = s.value AND x.elem->>'text' = s.text
          WHERE s.topic_revision_id = r.id) = 5
   ORDER BY r.revision DESC LIMIT 1;

  IF v_new IS NOT NULL THEN
    RAISE NOTICE 'CA_0412: approved revision already present (%) — skipping propose/approve.', v_new;
  ELSE
    SELECT id INTO v_open FROM inform.compass_topic_revisions
     WHERE topic_id = v_topic AND status IN ('draft','approved');
    IF v_open IS NOT NULL THEN
      RAISE EXCEPTION 'CA_0412: topic already has an open revision % — resolve it first', v_open;
    END IF;

    v_new := inform.admin_propose_topic_revision(
      v_key, v_actor, 'substantive',
      $t$Gun Policy$t$, $st$Gun Policy$st$,
      $q$How should the government regulate firearms?$q$,
      v_rungs,
      $rat$L1 poles: ban = "Civilians may not own guns, except licensed hunting or sport guns"; no permit = "No permit or registration is needed to own or carry a gun".
Axis: how far the law restricts civilian guns.
Season 3 rewrite of revision 3 (Season 2). It replaces revision 5 (approved 2026-11-03 by CA_0356, pinned in the draft season, never published). Rungs 2, 3 and 5 are revision 5's, word for word. Rung 4 is widened from "Make carrying a gun easier, such as honoring carry permits from other states." to "Make buying, having or carrying a gun easier, such as honoring carry permits from other states, ending a waiting period or ending a red-flag law.", so that it mirrors rung 3 ("buying, having or carrying"). Rung 1 says "permit" where revision 5 said "licence", the word rungs 4 and 5 use; rung 1 holds no politician.
Why: Stage 5 coded 4,523 people in 31 groups. A person whose record removes or cuts back a general limit on buying or having a gun (a buyer check, a waiting period, a buying age, a permit to buy, a red-flag law, a type ban) fitted no rung, because rung 4 named carrying only (rung review 2, 2026-11-21, pattern C).
What counts at rung 4 beyond revision 5 (annex): a bill that removes or cuts back such a limit for the public or a broad class such as carry-permit holders, a short-barrel gun taken off a state ban included (runner, 2026-11-22). Not counted: gun rights given back to people barred for a record or an order; an exemption for one named group or one narrow kind of transfer; a change to who runs a check; a suppressor-only bill (runner, 2026-11-22: side only); a bar on a law that does not exist.
Checks (stage5/RUNG-REVIEW-2-2026-11-21.md sections 3, 7, 14, 15; stage3/rev6-check): every seated person with vote lines in 19 states was checked by script against a 51-bill count list: about 72 blanks seat at rung 4; 24 seats hold a listed act and are re-coded (19 of them blanks in the database at the time of this migration; the other 5 are named in the report); 289 rung 4 and 5 seats hold a listed act and do not move. In the 11 groups without vote lines a search of every code's reasoning found no rung 2 or 3 seat beside a counted easing act. All 524 rung 4 seats of revision 5 still fit: "carrying" stays in the rung. Voter placement (pre-registered, three voters): 30/30 on the ten standing views (revision 5: 28/30); end a waiting period 3/3, buying age 3/3, permit holders skip the buyer check 3/3, repeal a red-flag law 3/3. A first wording with the waiting-period example alone placed the red-flag view 1/3; the runner chose the three-example text (2026-11-22).
T5: the draft Season 3 rows on this topic are carried to this revision unchanged in this migration (RULINGS.md, Stage 4: a draft that replaces an approved, unpublished revision); the people the count list touches are then coded again and re-written through the review queue. The 100 Season 2 answers stay on the Season 2 pin. Substantive against revision 3, as revision 5 was. Rung map: identity.
Expert review is owed, as for revision 5.$rat$,
      $pub$This question still asks how the government should regulate firearms, from banning guns for civilians to needing no permit or registration at all. The old options mixed different kinds of law in one option (for example, "allow all types of firearms, but require universal background checks"), so many real gun laws fit no option. Each option now names one kind of gun law: banning all guns, banning a type of gun or magazine, adding limits on buying, having or carrying a gun (such as checks on every buyer, waiting periods, or bans on guns in certain places), making it easier to buy, have or carry a gun (such as honoring other states' carry permits, ending a waiting period or ending a red-flag law), or removing permit and registration rules. The old option 4, "add no new restrictions", is now "make buying, having or carrying a gun easier". If you answered this question before, your answer is kept on the matching option; please check that it still describes your view.$pub$,
      $ref$~/Documents/GitHub/.planning/research/s3-prep-gun-policy/ (local): stage5/RUNG-REVIEW-2-2026-11-21.md, stage5/rr4/, stage3/rev6-check/results.md, stage4-r6/$ref$,
      '{"1": 1, "2": 2, "3": 3, "4": 4, "5": 5}'::jsonb
    );

    -- guidance is not a propose parameter: set it on the draft row BEFORE approving.
    UPDATE inform.compass_topic_revisions SET guidance = v_guidance
     WHERE id = v_new AND status = 'draft';
    IF NOT FOUND THEN RAISE EXCEPTION 'CA_0412: could not set guidance on draft revision %', v_new; END IF;

    PERFORM inform.admin_approve_topic_revision(v_new, v_actor);  -- approve, NOT publish (park)
    RAISE NOTICE 'CA_0412: proposed + approved (parked) substantive revision %', v_new;
  END IF;

END $$;

-- ── 1b. Pin the new revision and carry the draft-season rows to it ───────────────────────────────
DO $$
DECLARE
  v_actor CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
  v_topic CONSTANT uuid := '56125933-b82a-46c5-847b-b2e9a146b89f';
  v_draft CONSTANT uuid := '7b3a066c-815d-43b2-a6a0-6a3029778075';
  v_rev5  CONSTANT uuid := '41349e39-394a-47b9-81c6-a79f8ec60425';
  v_new   uuid;
  v_a     int;
  v_c     int;
BEGIN
  SELECT r.id INTO v_new FROM inform.compass_topic_revisions r
   WHERE r.topic_id = v_topic AND r.revision = 6 AND r.status = 'approved';
  IF v_new IS NULL THEN RAISE EXCEPTION 'CA_0412 carry: approved revision 6 not found'; END IF;
  PERFORM inform.admin_season_pin_revision(v_draft, v_topic, v_new, v_actor);
  UPDATE inform.politician_answers SET topic_revision_id = v_new
   WHERE topic_id = v_topic AND season_id = v_draft AND topic_revision_id = v_rev5;
  GET DIAGNOSTICS v_a = ROW_COUNT;
  UPDATE inform.politician_context SET topic_revision_id = v_new
   WHERE topic_id = v_topic AND season_id = v_draft AND topic_revision_id = v_rev5;
  GET DIAGNOSTICS v_c = ROW_COUNT;
  RAISE NOTICE 'CA_0412: draft season pinned to revision %; carried % answer and % context row(s)', v_new, v_a, v_c;
END $$;
ALTER TABLE inform.politician_answers
  ADD CONSTRAINT politician_answers_pin_fkey
  FOREIGN KEY (season_id, topic_id, topic_revision_id)
  REFERENCES inform.season_questions (season_id, topic_id, topic_revision_id);
ALTER TABLE inform.politician_context
  ADD CONSTRAINT politician_context_pin_fkey
  FOREIGN KEY (season_id, topic_id, topic_revision_id)
  REFERENCES inform.season_questions (season_id, topic_id, topic_revision_id);

-- ── 2. Post-verify gate ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_topic CONSTANT uuid := '56125933-b82a-46c5-847b-b2e9a146b89f';
  v_openS CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_draft CONSTANT uuid := '7b3a066c-815d-43b2-a6a0-6a3029778075';
  v_prev  CONSTANT uuid := '44615418-e111-4f2f-a256-92fcf74b0f2f';
  v_openPin CONSTANT uuid := '1a72d5df-746f-4469-ab9b-1d3e8bc33b8d';
  v_rungs CONSTANT jsonb := jsonb_build_array(
    jsonb_build_object('value', 1, 'text', $r1$Ban civilian gun ownership, except with a permit for hunting or sport.$r1$),
    jsonb_build_object('value', 2, 'text', $r2$Ban a type of firearm or magazine, such as assault-style weapons.$r2$),
    jsonb_build_object('value', 3, 'text', $r3$Add limits on buying, having or carrying a gun, such as checking every buyer, red-flag orders, waiting periods or bans on guns in hospitals.$r3$),
    jsonb_build_object('value', 4, 'text', $r4$Make buying, having or carrying a gun easier, such as honoring carry permits from other states, ending a waiting period or ending a red-flag law.$r4$),
    jsonb_build_object('value', 5, 'text', $r5$Repeal laws that require a permit or registration for a gun, such as the permit to carry.$r5$)
  );
  v_new   uuid;
  v_ver   int;
  v_num   int;
  v_stat  text;
  v_curr  boolean;
  v_title text;
  v_short text;
  v_q     text;
  v_g     text;
  v_rat   text;
  v_map   jsonb;
  v_n     int;
  v_pin   uuid;
  v_disp  text;
BEGIN
  SELECT r.id, r.version, r.revision, r.status::text, r.is_current, r.title, r.short_title,
         r.question_text, r.guidance, r.rationale, r.rung_map
    INTO v_new, v_ver, v_num, v_stat, v_curr, v_title, v_short, v_q, v_g, v_rat, v_map
  FROM inform.compass_topic_revisions r
  WHERE r.topic_id = v_topic AND r.id <> '44615418-e111-4f2f-a256-92fcf74b0f2f' AND r.revision = 6
    AND (SELECT count(*) FROM inform.compass_stance_revisions s
          JOIN jsonb_array_elements(v_rungs) AS x(elem) ON (x.elem->>'value')::int = s.value AND x.elem->>'text' = s.text
         WHERE s.topic_revision_id = r.id) = 5
  ORDER BY r.revision DESC LIMIT 1;

  IF v_new IS NULL THEN RAISE EXCEPTION 'CA_0412 verify: new revision not found (rung text mismatch?)'; END IF;
  IF v_num <> 6 THEN RAISE EXCEPTION 'CA_0412 verify: revision number is % (expected 6)', v_num; END IF;
  IF v_ver <> 3 THEN RAISE EXCEPTION 'CA_0412 verify: version is % (expected 3)', v_ver; END IF;
  IF v_stat <> 'approved' THEN RAISE EXCEPTION 'CA_0412 verify: status is % (expected approved — must NOT be published)', v_stat; END IF;
  IF v_curr THEN RAISE EXCEPTION 'CA_0412 verify: new revision is is_current (the open season would drift)'; END IF;
  IF v_title <> $t$Gun Policy$t$ OR v_short <> $st$Gun Policy$st$ THEN
    RAISE EXCEPTION 'CA_0412 verify: title/short title are "%" / "%"', v_title, v_short;
  END IF;
  IF v_q <> $q$How should the government regulate firearms?$q$ THEN RAISE EXCEPTION 'CA_0412 verify: question text is "%"', v_q; END IF;
  IF v_g IS DISTINCT FROM $g$Where the balance falls between access to firearms and restrictions meant to reduce harm.$g$ THEN
    RAISE EXCEPTION 'CA_0412 verify: guidance is "%" (the previous line was inherited?)', v_g;
  END IF;
  IF v_rat NOT LIKE 'L1 poles: %' THEN RAISE EXCEPTION 'CA_0412 verify: rationale does not start with the L1 poles line'; END IF;
  IF v_map <> '{"1": 1, "2": 2, "3": 3, "4": 4, "5": 5}'::jsonb THEN RAISE EXCEPTION 'CA_0412 verify: rung map is %', v_map; END IF;
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions WHERE topic_revision_id = v_new;
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0412 verify: new revision has % rungs (expected 5)', v_n; END IF;

  -- The previous revision is still the current published one (the open season is unaffected).
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                  WHERE id = v_prev AND is_current AND status = 'published') THEN
    RAISE EXCEPTION 'CA_0412 verify: 44615418-e111-4f2f-a256-92fcf74b0f2f is no longer current/published';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions WHERE id = '41349e39-394a-47b9-81c6-a79f8ec60425' AND status = 'rejected') THEN
    RAISE EXCEPTION 'CA_0412 verify: revision 5 41349e39-394a-47b9-81c6-a79f8ec60425 is not rejected';
  END IF;
  -- The open season's pin is unchanged (1a72d5df-746f-4469-ab9b-1d3e8bc33b8d); the draft season pins the new one.
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_openS AND topic_id = v_topic;
  IF v_pin IS DISTINCT FROM v_openPin THEN RAISE EXCEPTION 'CA_0412 verify: open-season pin is % (expected 1a72d5df-746f-4469-ab9b-1d3e8bc33b8d, unchanged)', v_pin; END IF;
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_draft AND topic_id = v_topic;
  IF v_pin IS DISTINCT FROM v_new THEN RAISE EXCEPTION 'CA_0412 verify: draft-season pin is % (expected %)', v_pin, v_new; END IF;

  -- Season sizes unchanged: a re-pin, not an add. RE-READ these counts before the dry run and before
  -- applying: another season migration may have run since 2026-11-03.
  SELECT count(*) INTO v_n FROM inform.season_questions WHERE season_id = v_openS;
  IF v_n <> 60 THEN RAISE EXCEPTION 'CA_0412 verify: open season holds % questions (expected 60)', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.season_questions WHERE season_id = v_draft;
  IF v_n <> 60 THEN RAISE EXCEPTION 'CA_0412 verify: draft season holds % questions (expected 60)', v_n; END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_draft AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0412 verify: the target season is no longer a draft';
  END IF;

  -- The draft-season rows were carried, unchanged, to the new revision.
  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE topic_id = v_topic AND season_id = v_draft AND topic_revision_id = v_new;
  IF v_n <> 3337 THEN RAISE EXCEPTION 'CA_0412 verify: % draft-season answers cite the new revision (expected 3337)', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE topic_id = v_topic AND season_id = v_draft AND topic_revision_id <> v_new;
  IF v_n <> 0 THEN RAISE EXCEPTION 'CA_0412 verify: % draft-season context rows do not cite the new revision', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_answers a
   WHERE a.topic_id = v_topic AND a.season_id = v_draft
     AND NOT EXISTS (SELECT 1 FROM slot_pre_answers p WHERE p.politician_id = a.politician_id AND p.value = a.value);
  IF v_n <> 0 THEN RAISE EXCEPTION 'CA_0412 verify: % carried answer(s) changed value or person', v_n; END IF;
  IF (SELECT count(*) FROM pg_constraint
       WHERE conname IN ('politician_answers_pin_fkey','politician_context_pin_fkey')) <> 2 THEN
    RAISE EXCEPTION 'CA_0412 verify: a pin key is missing after the carry';
  END IF;

  -- What opening the draft season will do to voter answers (report only; the open season is not touched).
  -- Counts ANSWER ROWS of compass_responses (not deleted), not voters: take the expected figure from the
  -- 'voter_answer_rows' lines of templates/stage4-facts.sql, never from compass_answer_dispositions.
  SELECT string_agg(d || ' x' || c, ', ') INTO v_disp FROM (
    SELECT inform.compass_answer_disposition(r.answered_revision_id, v_new, r.value) AS d, count(*) AS c
      FROM inform.compass_responses r
     WHERE r.topic_id = v_topic AND r.deleted_at IS NULL
     GROUP BY 1) z;
  RAISE NOTICE 'CA_0412: voter answers against the new revision at season open: % (expected, as answer rows: reworded x4 (4 live answer rows on revision 3: two at rung 1, one at rung 2, one at rung 5; identity map))', coalesce(v_disp, 'none');

  RAISE NOTICE 'CA_0412 post-verify OK: revision % approved/parked (v3, is_current=false), draft season -> new, open season -> previous.', v_new;
END $$;

COMMIT;
