-- CA_0356_gun_policy_s3_rev5_rung3_rewrite.sql
-- Author: Chris Andrews (CA_ namespace). Slot reserved from the steward allocator 2026-11-03.
--
-- =============================================================================
-- CA_0356: gun-policy — Season 3 revision 5, approved
--           and pinned in the DRAFT season
-- =============================================================================
-- Replacing an approved, pinned, never-published revision follows CA_0334 / CA_0336 (voting-rights).
-- Template: .claude/skills/season-topic-prep/templates/stage4-revision.sql (structure of CA_0314,
-- education-equity-programs, applied 2026-10-20). Fill every placeholder (a name in double curly
-- braces); a grep of the filled file for two opening curly braces must print nothing before the dry
-- run. Recipe: .claude/skills/season-topic-prep/STAGE4-RECIPE.md.
--
-- Drafted 2026-11-03, offline, as the Stage 4 package of the Season 3 prep for this
-- topic. Actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2 (Chris Andrews).
--
-- APPLIED 2026-11-03 on production after Chris Andrews' yes #2: revision 5 = 41349e39-394a-47b9-81c6-a79f8ec60425 (v3, approved/parked,
-- pinned in draft Season 3); revision 4 76a098af… rejected; open Season 2 pin unchanged (1a72d5df…).
-- Dry run on prod 2026-11-03 (body twice inside BEGIN, forced RAISE): gate OK on both runs; first run re-pinned
-- the draft season to revision 3, rejected revision 4 and proposed/approved/pinned revision 5; second run skipped
-- propose/approve; voter answers reworded x3; rollback confirmed (4 revisions, revision 4 still approved and pinned).
--
-- WHAT THIS DOES
--   0. Replaces revision 4 (76a098af-cf9f-499c-abb8-5a0a0863114a, approved and parked by CA_0338, pinned in
--      the draft season): moves the draft-season pin back to the published control (revision 3), then
--      rejects revision 4 with a reason, so the propose sees no open revision. All in this one transaction.
--   1. Proposes revision 5 of gun-policy: change_class substantive, version 3.
--      Rungs:
--        1  Ban civilian gun ownership, except with a licence for hunting or sport.
--        2  Ban a type of firearm or magazine, such as assault-style weapons.
--        3  Add limits on buying, having or carrying a gun, such as checking every buyer, red-flag orders, waiting periods or bans on guns in hospitals.
--        4  Make carrying a gun easier, such as honoring carry permits from other states.
--        5  Repeal laws that require a permit or registration for a gun, such as the permit to carry.
--      Rung map (key = the OLD rung of revision 44615418-e111-4f2f-a256-92fcf74b0f2f; "invalidated" allowed): {"1": 1, "2": 2, "3": 3, "4": 4, "5": 5}
--   2. Sets the new guidance on the draft row. guidance is NOT a propose parameter; the trigger would
--      otherwise copy the previous revision's line. guidance is outside the immutable-content trigger.
--   3. Approves it and PARKS it (approved, NOT published; is_current stays on the previous revision).
--      The open season keeps serving the previous revision.
--   4. Pins it into the draft season (replacing the step 0 pin). The pin is inert until that season opens.
--   Writes nothing to politician_answers, politician_context or compass_responses.
--
-- L1 POLES (stored internally as the first line of rationale, not shown to voters)
--   Civilians may not own guns, except licensed hunting or sport guns  <->  No permit or registration is needed to own or carry a gun
--
-- EVIDENCE: Stage 3 results (~/Documents/GitHub/.planning/research/s3-prep-gun-policy/ (local): stage5/rung-rewrite-proposal-sessC.md, stage5/README.md (SESSION C), stage3/rev5-check/results.md, stage3/results.md, stage4-r5/).
-- SEAT COST (T5): the draft Season 3 holds no politician answers on this topic, so no seat moves and none carries; the 100 Season 2 answers stay on the Season 2 pin; 3 live voter answers (rungs 1, 1, 2) are kept as reworded; Stage 5 codes in the research folder (827 seated, 177 on rung 3) are re-stamped to this revision before any write
-- EXPERT REVIEW: owed, not done; 165 seated rows queued in stage3/expert-queue.json.
--
-- 🔴 Do not push `--season draft` research for this topic before this is applied: rows written earlier
--    pin the previous revision in the draft season, and the precondition below refuses to re-pin.
-- 🔴 Season question counts in the gate (60 open, 60 draft) were read on 2026-11-03.
--    RE-READ THEM just before the dry run and again before applying.
--
-- Idempotent: steps are guarded on revision number 5 with the five new rung texts (on any
-- revision other than the previous one, so a clarifying revision with unchanged rungs works); a re-run
-- is a no-op and the gate still asserts the full shape.
-- =============================================================================

BEGIN;

-- ── 0. Preconditions ─────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics
                 WHERE id = '56125933-b82a-46c5-847b-b2e9a146b89f' AND topic_key = 'gun-policy') THEN
    RAISE EXCEPTION 'CA_0356 precondition: gun-policy topic id/key mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons
                 WHERE id = '7b3a066c-815d-43b2-a6a0-6a3029778075' AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0356 precondition: the target season is not a draft (its pins would be frozen)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons
                 WHERE id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND status = 'open') THEN
    RAISE EXCEPTION 'CA_0356 precondition: 86d893a1-c1a2-4bbf-b4e5-69ec43221194 is not the open season';
  END IF;
  -- The open season's pin for this topic. It is usually 44615418-e111-4f2f-a256-92fcf74b0f2f, but not when a clarifying
  -- revision was published after the open season locked its pins (the season keeps the older pin and
  -- is served the newer text by version). Fill 1a72d5df-746f-4469-ab9b-1d3e8bc33b8d from the facts query's 'pin' row.
  IF NOT EXISTS (SELECT 1 FROM inform.season_questions
                 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id = '56125933-b82a-46c5-847b-b2e9a146b89f'
                   AND topic_revision_id = '1a72d5df-746f-4469-ab9b-1d3e8bc33b8d') THEN
    RAISE EXCEPTION 'CA_0356 precondition: the open season does not pin 1a72d5df-746f-4469-ab9b-1d3e8bc33b8d for this topic';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = '44615418-e111-4f2f-a256-92fcf74b0f2f' AND is_current AND status = 'published') THEN
    RAISE EXCEPTION 'CA_0356 precondition: 44615418-e111-4f2f-a256-92fcf74b0f2f is not the current published revision';
  END IF;
  -- Revision 5 replaces revision 4 (76a098af-cf9f-499c-abb8-5a0a0863114a, approved and parked by CA_0338, pinned in the draft
  -- season). On a first run it must still be approved and pinned there; on a re-run it is rejected.
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = '76a098af-cf9f-499c-abb8-5a0a0863114a' AND topic_id = '56125933-b82a-46c5-847b-b2e9a146b89f'
                   AND status IN ('approved','rejected')) THEN
    RAISE EXCEPTION 'CA_0356 precondition: revision 4 76a098af-cf9f-499c-abb8-5a0a0863114a is missing or not approved/rejected';
  END IF;
  IF EXISTS (SELECT 1 FROM inform.compass_topic_revisions WHERE id = '76a098af-cf9f-499c-abb8-5a0a0863114a' AND status = 'approved')
     AND NOT EXISTS (SELECT 1 FROM inform.season_questions
                      WHERE season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075' AND topic_id = '56125933-b82a-46c5-847b-b2e9a146b89f'
                        AND topic_revision_id = '76a098af-cf9f-499c-abb8-5a0a0863114a') THEN
    RAISE EXCEPTION 'CA_0356 precondition: revision 4 is approved but the draft season does not pin it';
  END IF;
  -- A draft-season answer on this topic carries the previous revision in its pin key; re-pinning
  -- under it would strand the row. There must be none.
  IF EXISTS (SELECT 1 FROM inform.politician_answers
              WHERE topic_id = '56125933-b82a-46c5-847b-b2e9a146b89f' AND season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075') THEN
    RAISE EXCEPTION 'CA_0356 precondition: the draft season already holds politician answers for this topic';
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
    jsonb_build_object('value', 1, 'text', $r1$Ban civilian gun ownership, except with a licence for hunting or sport.$r1$),
    jsonb_build_object('value', 2, 'text', $r2$Ban a type of firearm or magazine, such as assault-style weapons.$r2$),
    jsonb_build_object('value', 3, 'text', $r3$Add limits on buying, having or carrying a gun, such as checking every buyer, red-flag orders, waiting periods or bans on guns in hospitals.$r3$),
    jsonb_build_object('value', 4, 'text', $r4$Make carrying a gun easier, such as honoring carry permits from other states.$r4$),
    jsonb_build_object('value', 5, 'text', $r5$Repeal laws that require a permit or registration for a gun, such as the permit to carry.$r5$)
  );
  v_open     uuid;
  v_new      uuid;
BEGIN
  -- The new revision is the approved/published revision 5 whose five rungs match these texts
  -- exactly. Requiring the number stops an older revision that happens to share the rung texts from
  -- being taken for it.
  SELECT r.id INTO v_new FROM inform.compass_topic_revisions r
   WHERE r.topic_id = v_topic AND r.id <> '44615418-e111-4f2f-a256-92fcf74b0f2f' AND r.revision = 5
     AND r.status IN ('approved','published')
     AND (SELECT count(*) FROM inform.compass_stance_revisions s
           JOIN jsonb_array_elements(v_rungs) AS x(elem) ON (x.elem->>'value')::int = s.value AND x.elem->>'text' = s.text
          WHERE s.topic_revision_id = r.id) = 5
   ORDER BY r.revision DESC LIMIT 1;

  IF v_new IS NOT NULL THEN
    RAISE NOTICE 'CA_0356: approved revision already present (%) — skipping propose/approve.', v_new;
  ELSE
    -- Replace revision 4: move the draft-season pin back to the published control, then reject
    -- revision 4, so the propose below sees no open revision. admin_season_pin_revision accepts a
    -- published revision; admin_reject_topic_revision accepts an approved one.
    IF EXISTS (SELECT 1 FROM inform.compass_topic_revisions WHERE id = '76a098af-cf9f-499c-abb8-5a0a0863114a' AND status = 'approved') THEN
      PERFORM inform.admin_season_pin_revision(v_draft, v_topic, '44615418-e111-4f2f-a256-92fcf74b0f2f', v_actor);
      PERFORM inform.admin_reject_topic_revision('76a098af-cf9f-499c-abb8-5a0a0863114a', v_actor,
        $why$Replaced by revision 5: gun-policy Stage 5 Session C rewrote rung 3 (runner Chris Andrews, 2026-11-03). Research folder stage5/rung-rewrite-proposal-sessC.md.$why$);
      RAISE NOTICE 'CA_0356: draft season re-pinned to revision 3 and revision 4 rejected (replaced)';
    END IF;

    SELECT id INTO v_open FROM inform.compass_topic_revisions
     WHERE topic_id = v_topic AND status IN ('draft','approved');
    IF v_open IS NOT NULL THEN
      RAISE EXCEPTION 'CA_0356: topic already has an open revision % — resolve it first', v_open;
    END IF;

    v_new := inform.admin_propose_topic_revision(
      v_key, v_actor, 'substantive',
      $t$Gun Policy$t$, $st$Gun Policy$st$,
      $q$How should the government regulate firearms?$q$,
      v_rungs,
      $rat$L1 poles: ban = "Civilians may not own guns, except licensed hunting or sport guns"; no permit = "No permit or registration is needed to own or carry a gun".
Axis: how far the law restricts civilian guns.
Season 3 rewrite of revision 3 (Season 2): Draft B of the season-topic-prep skill's Wording path (revision 4, approved and parked 2026-10-30 by CA_0338), with rung 3 rewritten after Stage 5 (revision 5, which replaces revision 4). Each rung names one kind of gun law: 1 bans civilian ownership in general (a licence for hunting or sport allowed); 2 bans a defined type of firearm or magazine; 3 adds a limit on buying, having or carrying a gun short of a type ban (a buyer check of any scope, a court order that removes guns from a person found dangerous, a minimum age, a licence to buy, a waiting period or purchase limit, a ban on carrying in named places, serial-number and unserialised-gun rules); 4 widens where or by whom a gun may be carried while the permit system stays; 5 repeals a permit, licence or registration requirement.
Why the control failed: rung 3 joined "allow all types" to universal checks (L6; a checks law says nothing about bans, so every checks seat was compound-partial); rung 4 rested on absences ("no new restrictions", "at most"; L5, T6), so its reciprocity seats were direction-only; rung 5 joined a repeal of major restrictions to permitless carry (L6, federal) and used the degree word "major" (L4); rung 1 used "tightly" (L4); the rungs crossed three objects (which guns, checks on a sale, carrying) as compounds (L2); no poles were named (L1). The commonest recent state laws (red-flag orders, minimum ages, magazine limits, partial checks) matched no rung.
Rung map: identity (1->1 ... 5->5). Rung 1 drops "tightly"; rung 2 widens from one class to a type of firearm or magazine; rung 3 keeps the checks act as an example and widens to limits on buying, having or carrying a gun (revision 4 named only who may have one); rung 4 keeps the act "loosen rules on carrying" and drops the absence clauses; rung 5 becomes one act (repeal a permit or registration requirement).
Stage 3 on a frozen set of 304 items (241 people), seed 20261029-gp1: T1 149/196 = 76.0% of affirmative items (control 76/196 = 38.8%, Draft A 119/196 = 60.7%), no regression; T3 10/10 pre-registered order pairs (control 2/10); T6 1 lint hit, accepted ("every" inside an example); blind validation 47/48 = 97.9%; T7 voter placement 24/30 (age-and-waiting-period and licence-to-buy views were not placed on rung 3). Adversarial check: 17 attacks, each closed (closures C1-C6 confirmed by a second reviewer) or ruled as a dispute (D3, D4). A Stage 5 preview of 170 people found 39.2% doesn't-fit under this draft (bar 20%), no theme over 1 in 10; ruling P1 keeps this draft and keeps the data (rung backlog).
Rulings (Chris Andrews): R0a-1 keep one topic, Wording path (2026-10-29); census Q1 a law's own penalty is not a second subject (2026-10-29); J1-J8 sampling and readings (2026-10-29; J7 self-defense parts are not criminal-justice evidence); Q1-Q7 drafting (2026-10-29: Q2 no rung for keep current law, own words backing one's own state's current law read on that law; Q3 magazines on rung 2; Q4 repeal of a type ban, waiting period or minimum age direction-only; Q5 a federal bar on state carry permits is rung 5; Q6 home-made firearm rules direction-only; Q7 class decided at Stage 4); D1-D4 disputes (2026-10-30); P1 carry on with Draft B, keep the data (2026-10-30).
Stage 5 (2026-11-03, revision 4): coding 6 units (federal, VA, TX, PA, IN, MA) gave doesn't-fit 204 of 925 = 22.1%, over the 1-in-5 bar. Session C rewrote rung 3 (material, widened: the 202 coded rung 3 seats all still fit) and ruled: place bans, waiting periods, purchase limits and ghost-gun rules are rung 3 acts (replaces annex Q6); an easier carry permit is rung 4 (annex only); auto-sear bans copy federal law (no rung act); the licence rule (a carry widening that keeps the permit does not conflict with a rung 3 limit on who may have a gun or how guns are bought; it does conflict with type bans and place bans; permit repeal conflicts with rungs 1-3), from a look at the 22 two-sided records and a Florida roll-call test; a gun-crime part does not make a gun bill multi-subject (topic-scoped, narrows census Q1); a sponsorship of a near-unanimous bill is gated like the vote; near-unanimous means under 10% of votes cast. After re-coding 215 people: doesn't-fit 131 of 958 = 13.7%, 827 seated (rungs 2:260 3:177 4:103 5:287), no theme over 3%.
Revision 5 light Stage 3 check (stage3/rev5-check, pre-registered): T1 and T3 unchanged on the frozen set (149/196, 10/10; no frozen instrument changes); T7 voter placement 28/30 (revision 4: 24/30; the waiting-period view now placed on rung 3 by 3 of 3); adversarial check of the 41 new rung 3 seats: 17 attacks, 15 closed (second review reopened none), 2 disputes ruled.
T5: the draft Season 3 holds no politician answers on this topic, so no seat moves and none carries; Stage 5 codes everyone. The 100 Season 2 answers stay on the Season 2 pin; on their evidence 98 of 99 scored seats fit this ladder. Substantive because rungs 3, 4 and 5 change what a voter is asked against revision 3. 3 live voter answers (rungs 1, 1, 2) kept on their rungs.
Expert review is owed: 165 seated rows that rest on a bill or ordinance are queued (stage3/expert-queue.json); disputes ruled: 4 at Stage 3, 2 at the revision 5 check.$rat$,
      $pub$This question still asks how the government should regulate firearms, from banning guns for civilians to needing no permit or registration at all. The old options mixed different kinds of law in one option (for example, "allow all types of firearms, but require universal background checks"), so many real gun laws fit no option. Each option now names one kind of gun law: banning all guns, banning a type of gun or magazine, adding limits on buying, having or carrying a gun (such as checks on every buyer, waiting periods, or bans on guns in certain places), making it easier to carry a gun, or removing permit and registration rules. The old option 4, "add no new restrictions", is now "make carrying a gun easier". If you answered this question before, your answer is kept on the matching option; please check that it still describes your view.$pub$,
      $ref$~/Documents/GitHub/.planning/research/s3-prep-gun-policy/ (local): stage5/rung-rewrite-proposal-sessC.md, stage5/README.md (SESSION C), stage3/rev5-check/results.md, stage3/results.md, stage4-r5/$ref$,
      '{"1": 1, "2": 2, "3": 3, "4": 4, "5": 5}'::jsonb
    );

    -- guidance is not a propose parameter: set it on the draft row BEFORE approving.
    UPDATE inform.compass_topic_revisions SET guidance = v_guidance
     WHERE id = v_new AND status = 'draft';
    IF NOT FOUND THEN RAISE EXCEPTION 'CA_0356: could not set guidance on draft revision %', v_new; END IF;

    PERFORM inform.admin_approve_topic_revision(v_new, v_actor);  -- approve, NOT publish (park)
    RAISE NOTICE 'CA_0356: proposed + approved (parked) substantive revision %', v_new;
  END IF;

  PERFORM inform.admin_season_pin_revision(v_draft, v_topic, v_new, v_actor);
  RAISE NOTICE 'CA_0356: draft season pinned to revision %', v_new;
END $$;

-- ── 2. Post-verify gate ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_topic CONSTANT uuid := '56125933-b82a-46c5-847b-b2e9a146b89f';
  v_openS CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_draft CONSTANT uuid := '7b3a066c-815d-43b2-a6a0-6a3029778075';
  v_prev  CONSTANT uuid := '44615418-e111-4f2f-a256-92fcf74b0f2f';
  v_openPin CONSTANT uuid := '1a72d5df-746f-4469-ab9b-1d3e8bc33b8d';
  v_rungs CONSTANT jsonb := jsonb_build_array(
    jsonb_build_object('value', 1, 'text', $r1$Ban civilian gun ownership, except with a licence for hunting or sport.$r1$),
    jsonb_build_object('value', 2, 'text', $r2$Ban a type of firearm or magazine, such as assault-style weapons.$r2$),
    jsonb_build_object('value', 3, 'text', $r3$Add limits on buying, having or carrying a gun, such as checking every buyer, red-flag orders, waiting periods or bans on guns in hospitals.$r3$),
    jsonb_build_object('value', 4, 'text', $r4$Make carrying a gun easier, such as honoring carry permits from other states.$r4$),
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
  WHERE r.topic_id = v_topic AND r.id <> '44615418-e111-4f2f-a256-92fcf74b0f2f' AND r.revision = 5
    AND (SELECT count(*) FROM inform.compass_stance_revisions s
          JOIN jsonb_array_elements(v_rungs) AS x(elem) ON (x.elem->>'value')::int = s.value AND x.elem->>'text' = s.text
         WHERE s.topic_revision_id = r.id) = 5
  ORDER BY r.revision DESC LIMIT 1;

  IF v_new IS NULL THEN RAISE EXCEPTION 'CA_0356 verify: new revision not found (rung text mismatch?)'; END IF;
  IF v_num <> 5 THEN RAISE EXCEPTION 'CA_0356 verify: revision number is % (expected 5)', v_num; END IF;
  IF v_ver <> 3 THEN RAISE EXCEPTION 'CA_0356 verify: version is % (expected 3)', v_ver; END IF;
  IF v_stat <> 'approved' THEN RAISE EXCEPTION 'CA_0356 verify: status is % (expected approved — must NOT be published)', v_stat; END IF;
  IF v_curr THEN RAISE EXCEPTION 'CA_0356 verify: new revision is is_current (the open season would drift)'; END IF;
  IF v_title <> $t$Gun Policy$t$ OR v_short <> $st$Gun Policy$st$ THEN
    RAISE EXCEPTION 'CA_0356 verify: title/short title are "%" / "%"', v_title, v_short;
  END IF;
  IF v_q <> $q$How should the government regulate firearms?$q$ THEN RAISE EXCEPTION 'CA_0356 verify: question text is "%"', v_q; END IF;
  IF v_g IS DISTINCT FROM $g$Where the balance falls between access to firearms and restrictions meant to reduce harm.$g$ THEN
    RAISE EXCEPTION 'CA_0356 verify: guidance is "%" (the previous line was inherited?)', v_g;
  END IF;
  IF v_rat NOT LIKE 'L1 poles: %' THEN RAISE EXCEPTION 'CA_0356 verify: rationale does not start with the L1 poles line'; END IF;
  IF v_map <> '{"1": 1, "2": 2, "3": 3, "4": 4, "5": 5}'::jsonb THEN RAISE EXCEPTION 'CA_0356 verify: rung map is %', v_map; END IF;
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions WHERE topic_revision_id = v_new;
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0356 verify: new revision has % rungs (expected 5)', v_n; END IF;

  -- The previous revision is still the current published one (the open season is unaffected).
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                  WHERE id = v_prev AND is_current AND status = 'published') THEN
    RAISE EXCEPTION 'CA_0356 verify: 44615418-e111-4f2f-a256-92fcf74b0f2f is no longer current/published';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions WHERE id = '76a098af-cf9f-499c-abb8-5a0a0863114a' AND status = 'rejected') THEN
    RAISE EXCEPTION 'CA_0356 verify: revision 4 76a098af-cf9f-499c-abb8-5a0a0863114a is not rejected';
  END IF;
  -- The open season's pin is unchanged (1a72d5df-746f-4469-ab9b-1d3e8bc33b8d); the draft season pins the new one.
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_openS AND topic_id = v_topic;
  IF v_pin IS DISTINCT FROM v_openPin THEN RAISE EXCEPTION 'CA_0356 verify: open-season pin is % (expected 1a72d5df-746f-4469-ab9b-1d3e8bc33b8d, unchanged)', v_pin; END IF;
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_draft AND topic_id = v_topic;
  IF v_pin IS DISTINCT FROM v_new THEN RAISE EXCEPTION 'CA_0356 verify: draft-season pin is % (expected %)', v_pin, v_new; END IF;

  -- Season sizes unchanged: a re-pin, not an add. RE-READ these counts before the dry run and before
  -- applying: another season migration may have run since 2026-11-03.
  SELECT count(*) INTO v_n FROM inform.season_questions WHERE season_id = v_openS;
  IF v_n <> 60 THEN RAISE EXCEPTION 'CA_0356 verify: open season holds % questions (expected 60)', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.season_questions WHERE season_id = v_draft;
  IF v_n <> 60 THEN RAISE EXCEPTION 'CA_0356 verify: draft season holds % questions (expected 60)', v_n; END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_draft AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0356 verify: the target season is no longer a draft';
  END IF;

  -- No answers written into the draft season by this migration.
  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE topic_id = v_topic AND season_id = v_draft;
  IF v_n <> 0 THEN RAISE EXCEPTION 'CA_0356 verify: % draft-season politician answers on this topic (expected 0)', v_n; END IF;

  -- What opening the draft season will do to voter answers (report only; the open season is not touched).
  -- Counts ANSWER ROWS of compass_responses (not deleted), not voters: take the expected figure from the
  -- 'voter_answer_rows' lines of templates/stage4-facts.sql, never from compass_answer_dispositions.
  SELECT string_agg(d || ' x' || c, ', ') INTO v_disp FROM (
    SELECT inform.compass_answer_disposition(r.answered_revision_id, v_new, r.value) AS d, count(*) AS c
      FROM inform.compass_responses r
     WHERE r.topic_id = v_topic AND r.deleted_at IS NULL
     GROUP BY 1) z;
  RAISE NOTICE 'CA_0356: voter answers against the new revision at season open: % (expected, as answer rows: reworded x3 (3 live answer rows on revision 3: two at rung 1, one at rung 2; identity map))', coalesce(v_disp, 'none');

  RAISE NOTICE 'CA_0356 post-verify OK: revision % approved/parked (v3, is_current=false), draft season -> new, open season -> previous.', v_new;
END $$;

COMMIT;
