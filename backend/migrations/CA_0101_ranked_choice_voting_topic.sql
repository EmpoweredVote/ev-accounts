BEGIN;

-- =============================================================================
-- CA_0101: "Ranked-Choice Voting" — a new compass topic (revision model), pinned to S2
-- =============================================================================
-- Created 2026-09-01 with Chris Andrews.
--
-- WHAT THIS ADDS
-- A new voter-facing compass topic scoring how far an official (or a voter) would
-- move the voting METHOD away from single-choice, first-past-the-post elections.
-- topic_key is frozen at 'ranked-choice-voting' (essentials.quotes joins on it).
-- It fills a real gap: the corpus covers ballot ACCESS/integrity (voting-rights),
-- MAP-drawing (redistricting), MONEY (campaign-finance) and INFORMATION
-- (misinformation), but NO topic covered how votes are cast and counted. RCV is a
-- live 2024-2026 issue at every level — Maine/Alaska statewide, NYC/SF/Minneapolis
-- municipal, six state bans in 2024 — so role scopes are federal + state + local.
--
-- WHY IT IS BUILT THIS WAY (design decisions, so a later maintainer need not
-- re-derive them)
--
--   * ONE AXIS: OPENNESS TO CHANGING THE VOTING METHOD, from the fullest departure
--     from single-choice voting to forbidding any departure. Value 1 = most change;
--     value 5 = ban the alternative. The five rungs fall monotonically along that
--     one line, read as ++ / + / 0 / - / -- :
--         1  proportional (multi-winner) ranked-choice voting — the deepest change;
--            drops winner-take-all so the body mirrors the whole electorate
--         2  single-winner ranked-choice voting — keeps winner-take-all, changes
--            only how the one winner is found (produces a majority winner)
--         3  keep single-choice as the standard, but permit RCV where communities
--            choose it (the neutral center — open, but not pushing)
--         4  keep single-choice and oppose adopting RCV, WITHOUT banning it
--         5  ban RCV by law (the entrenchment pole)
--
--   * WHY PROPORTIONAL IS "FURTHER" THAN RCV (rung 1 vs rung 2). Not two unrelated
--     systems — two depths of one change. RCV keeps single-winner/winner-take-all;
--     proportional abandons it and rebuilds the body to mirror the electorate. A
--     bigger structural change sits further out. Both use ranked ballots, which
--     keeps rung 1 ON the same axis rather than jumping to a different mechanism.
--
--   * WHY 3-5 SHARE ONE SYSTEM (single-choice) IS NOT LOPSIDED. There are many ways
--     to REFORM voting (proportional, RCV, ...) but only ONE status quo. The axis
--     measures openness-to-change, not "which of N systems", so the anti/neutral
--     side names one system while varying in HOW HARD it is held: permit (3) /
--     refuse (4) / forbid (5). Those are three DISTINCT legal postures with real
--     adherents and real laws — not an effort-dial. Chris ruled 2026-09-01 to keep
--     rung 3 as the neutral "permit where wanted" center rather than adding a third
--     reform system (approval voting, top-two): those live on a DIFFERENT axis
--     (primary/ballot structure, not the count) and cannot be cleanly ordered
--     against RCV, which would break the single axis.
--
--   * RUNG 4 vs RUNG 5 IS DECLINE vs OUTLAW. Rung 4 keeps single-choice and opposes
--     adoption but stops short of a ban; rung 5 passes a law banning RCV. Rung 4's
--     "but stop short of banning it" is the explicit differentiator (a BORDERLINE
--     double-barrel kept by decision — it is one posture, scoped against rung 5).
--     Rung 5 says "Ban ranked-choice voting by law" WITHOUT "so no community can
--     use it": that overreached (it read as a nationwide ban no one can enact). The
--     real rung-5 holder bans it within their OWN jurisdiction (a state preempting
--     its own cities — Missouri 2024, grandfathering only St. Louis), not across
--     state lines.
--
--   * POLARITY IS THE CORPUS DEFAULT (value 1 = maximum change/action). This ladder
--     is NOT reversed (unlike AI Oversight / Tariffs). Do not "correct" it.
--
--   * RUNG 2 WORDING FOLLOWS THE POLLING, NOT THE JARGON. It drops "instant runoff"
--     and leads with the majority-winner idea (~86-88% of 2024 RCV-state voters
--     said it is important the winner has a majority, YouGov), phrased the way that
--     tested simple (your vote shifts to your next choice). See the JSON draft:
--     backend/data/topic-drafts/2026-09-01-ranked-choice-voting.json
--
--   * EACH RUNG SEATS REAL, SOURCED POSITIONS (grounding pass, WebSearch 2026-09-01):
--         1  Fair Representation Act (Rep. Beyer) multi-winner RCV; Lee Drutman /
--            proportional-RCV advocates; Cambridge MA multi-winner local elections
--         2  Maine and Alaska statewide RCV; NYC/SF/Minneapolis municipal; FairVote
--         3  "local option" officials; places that permit but do not mandate RCV
--         4  voters who rejected RCV adoption in CO, NV, OR, ID (2024) — no ban
--         5  the six states that BANNED RCV in 2024 (AL, KY, LA, MS, MO, OK); FL (2022)
--
-- HOW IT IS CREATED
-- Through the ADR 0004 revision model, via the prod RPC
-- inform.admin_create_topic_with_revision (CA_0026). The RPC writes all five
-- layers atomically — identity row, legacy 1..5 ladder, a founding v1 revision
-- (revision=1, version=1, change_class='substantive', status='published',
-- is_current=true, rung_map=NULL), the five stance revisions, and the role
-- scopes. The RPC has no argument for the design rationale, so it lives in these
-- comments (CA_0027/CA_0092 are the models). The legacy
-- admin_create_topic_with_stances RPC is INSUFFICIENT — it writes no revision.
--
-- PINNED TO SEASON 2, NOT LIVE YET. is_live=false. The migration pins the founding
-- v1 revision into the DRAFT Season 2 (inform.admin_season_add_topic,
-- auto-numbered) and assigns the "Governance, Democracy, and Institutional Reform"
-- category. It shows on NO voter surface until Season 2 OPENS
-- (inform.admin_open_season). Pinning into a DRAFT season does not promote it — the
-- season-gated promoted view lists only OPEN-season topics — so the gate asserts
-- "not promoted".
--
-- ⚠ IT WILL OPEN WITH EMPTY SPOKES. No politician is seated on ranked-choice-voting
-- yet (a brand-new topic has no answers). Until a stance-research pass seats real
-- 2026 officials at the five rungs, every official shows a BLANK spoke here. Run
-- research BEFORE Season 2 opens, or the topic launches unanswered.
--
-- IDEMPOTENT: the create runs only when topic_key 'ranked-choice-voting' is absent;
-- the season pin runs only when the topic is not already in Season 2; the category
-- link uses ON CONFLICT DO NOTHING. A re-run is a no-op. The post-verify gate
-- asserts the full shape either way. To revert: delete the topic row (revisions,
-- stances, roles, season_questions and category links cascade). No existing object
-- is altered.
--
-- IDs (verified 2026-09-01):
--   Season 2 (draft): 86d893a1-c1a2-4bbf-b4e5-69ec43221194  (resolved by number=2 below)
--   Governance category: 6e958103-8877-4421-9279-39e96e00e6f9
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Create the topic (guarded so a re-run does not hit DUPLICATE_TOPIC_KEY).
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_topics WHERE topic_key = 'ranked-choice-voting'
  ) THEN
    PERFORM inform.admin_create_topic_with_revision(
      'Ranked-Choice Voting and Electoral Method',                          -- p_title
      'How should votes be cast and counted in elections?',                 -- p_question_text
      'Ranked-Choice Voting',                                               -- p_short_title -> topic_key 'ranked-choice-voting'
      false,                                                                -- p_is_live (staged)
      '[
        {"value":1,"text":"Replace winner-take-all elections with proportional ranked-choice voting — ranked ballots fill several seats at once, so seats reflect how everyone voted."},
        {"value":2,"text":"Adopt ranked-choice voting for single-winner offices: voters rank candidates, and if a top choice can''t win, the vote shifts to the next choice until someone has a majority."},
        {"value":3,"text":"Allow ranked-choice voting where communities choose it, while keeping single-choice voting as the standard."},
        {"value":4,"text":"Keep single-choice voting and oppose adopting ranked-choice voting, but stop short of banning it."},
        {"value":5,"text":"Ban ranked-choice voting by law."}
      ]'::jsonb,                                                            -- p_stances
      NULL,                                                                 -- p_actor_id
      '["federal","state","local"]'::jsonb                                  -- p_role_scopes (every level sets its own voting method)
    );
    RAISE NOTICE 'CA_0101: created topic ranked-choice-voting';
  ELSE
    RAISE NOTICE 'CA_0101: topic ranked-choice-voting already present — create skipped';
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 2. Pin the founding v1 revision into DRAFT Season 2 (auto-numbered), and
--    assign the "Governance, Democracy, and Institutional Reform" category.
--    Both idempotent. Season resolved by number so it stays env-correct.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_topic  uuid;
  v_season uuid;
  v_cat    uuid := '6e958103-8877-4421-9279-39e96e00e6f9';  -- Governance, Democracy, and Institutional Reform
BEGIN
  SELECT id INTO v_season FROM inform.seasons WHERE number = 2;
  IF v_season IS NULL THEN
    RAISE EXCEPTION 'CA_0101: Season 2 not found';
  END IF;

  SELECT id INTO v_topic FROM inform.compass_topics WHERE topic_key = 'ranked-choice-voting';
  IF v_topic IS NULL THEN
    RAISE EXCEPTION 'CA_0101: topic ranked-choice-voting is missing before pin';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM inform.season_questions
     WHERE season_id = v_season AND topic_id = v_topic
  ) THEN
    PERFORM inform.admin_season_add_topic(v_season, v_topic, NULL);
    RAISE NOTICE 'CA_0101: pinned ranked-choice-voting into Season 2';
  ELSE
    RAISE NOTICE 'CA_0101: ranked-choice-voting already in Season 2 — pin skipped';
  END IF;

  INSERT INTO inform.compass_topic_categories (topic_id, category_id)
  VALUES (v_topic, v_cat)
  ON CONFLICT (topic_id, category_id) DO NOTHING;
END $$;

-- ---------------------------------------------------------------------------
-- 3. Post-verify gate. A wrong count RAISEs and aborts the transaction, so
--    nothing partial commits.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_topic  uuid;
  v_season uuid;
  v_status inform.season_status;
  v_cat    uuid := '6e958103-8877-4421-9279-39e96e00e6f9';
  v_n      int;
  v_key    text;
  v_t1     text;
  v_t5     text;
BEGIN
  SELECT id INTO v_topic FROM inform.compass_topics WHERE topic_key = 'ranked-choice-voting';
  IF v_topic IS NULL THEN
    RAISE EXCEPTION 'CA_0101: topic ranked-choice-voting is missing after create';
  END IF;

  -- topic_key frozen correctly (essentials.quotes joins on it)
  SELECT topic_key INTO v_key FROM inform.compass_topics WHERE id = v_topic;
  IF v_key <> 'ranked-choice-voting' THEN
    RAISE EXCEPTION 'CA_0101: topic_key is % (expected ranked-choice-voting)', v_key;
  END IF;

  -- exactly one published/current v1 substantive revision, rung_map NULL
  SELECT count(*) INTO v_n FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic AND is_current AND status = 'published'
     AND revision = 1 AND version = 1 AND change_class = 'substantive'
     AND rung_map IS NULL;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0101: expected 1 published/current v1 substantive revision (rung_map NULL), got %', v_n;
  END IF;

  -- five distinct stance-revision values on the current revision
  SELECT count(DISTINCT sr.value) INTO v_n
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current;
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CA_0101: expected 5 stance revisions, got %', v_n;
  END IF;

  -- five legacy stances (corpus 5:5 invariant)
  SELECT count(*) INTO v_n FROM inform.compass_stances WHERE topic_id = v_topic;
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CA_0101: expected 5 legacy stances, got %', v_n;
  END IF;

  -- exactly the three requested role rows: federal, state, local (never judicial)
  SELECT count(*) INTO v_n FROM inform.compass_topic_roles WHERE topic_id = v_topic;
  IF v_n <> 3 THEN
    RAISE EXCEPTION 'CA_0101: expected exactly 3 role rows, got %', v_n;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'federal')
     OR NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'state')
     OR NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'local') THEN
    RAISE EXCEPTION 'CA_0101: expected federal + state + local role rows';
  END IF;
  IF EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'judicial') THEN
    RAISE EXCEPTION 'CA_0101: unexpected judicial role row';
  END IF;

  -- polarity guard: value 1 is proportional (deepest change), value 5 bans RCV.
  -- Catches an accidental ladder inversion.
  SELECT sr.text INTO v_t1
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current AND sr.value = 1;
  SELECT sr.text INTO v_t5
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current AND sr.value = 5;
  IF v_t1 NOT ILIKE '%proportional%' OR v_t5 NOT ILIKE '%Ban ranked-choice voting%' THEN
    RAISE EXCEPTION 'CA_0101: polarity check failed (v1=%, v5=%)', v_t1, v_t5;
  END IF;

  -- season must still be a DRAFT (opening it is a separate, later step)
  SELECT id, status INTO v_season, v_status FROM inform.seasons WHERE number = 2;
  IF v_status <> 'draft' THEN
    RAISE EXCEPTION 'CA_0101: Season 2 is % (expected draft)', v_status;
  END IF;

  -- pinned into Season 2, on the current published revision
  SELECT count(*) INTO v_n
    FROM inform.season_questions sq
    JOIN inform.compass_topic_revisions r ON r.id = sq.topic_revision_id
   WHERE sq.season_id = v_season AND sq.topic_id = v_topic
     AND r.is_current AND r.status = 'published';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0101: expected ranked-choice-voting pinned once into Season 2 on its current revision, got %', v_n;
  END IF;

  -- category assigned
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_topic_categories
     WHERE topic_id = v_topic AND category_id = v_cat
  ) THEN
    RAISE EXCEPTION 'CA_0101: ranked-choice-voting not assigned to the Governance category';
  END IF;

  -- must NOT be live yet: Season 2 is a DRAFT, so the season-gated promoted view
  -- (open-season only) must not list it.
  IF EXISTS (SELECT 1 FROM inform.compass_topics_promoted WHERE id = v_topic) THEN
    RAISE EXCEPTION 'CA_0101: topic leaked into an open season before Season 2 opened';
  END IF;

  RAISE NOTICE 'CA_0101 OK — ranked-choice-voting staged (1 published/current v1, 5 rungs, 5 legacy stances, 3 roles federal+state+local, polarity 1=proportional/5=ban, pinned to draft Season 2, category assigned, not promoted)';
END $$;

COMMIT;
