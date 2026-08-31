BEGIN;

-- =============================================================================
-- CA_0027: "2020 Presidential Election" — a new compass topic (revision model)
-- =============================================================================
-- Created 2026-08-29 with Chris Andrews.
--
-- WHAT THIS ADDS
-- A new voter-facing compass topic recording where an official (or a voter)
-- stands on the outcome of the 2020 U.S. presidential election. topic_key is
-- frozen at '2020-election' (essentials.quotes joins on it — see below).
--
-- WHY IT IS BUILT THIS WAY (design decisions, so a later maintainer need not
-- re-derive them)
--
--   * BELIEF AXIS, NOT A POLICY AXIS. Almost every compass topic scores what
--     government should DO. This one scores a stated position about a past
--     factual event. That is a deliberate departure (the corpus already carries
--     "Misinformation", so belief-adjacent topics are not unprecedented). The
--     stance grammar is therefore plain declarative sentences ("The election
--     was fair and Joe Biden won legitimately."), not policy imperatives
--     ("require…", "expand…"). Each rung reads naturally BOTH as a voter's own
--     answer and as a candidate's assessed position.
--
--   * ALL LEVELS (federal + state + local), NOT judicial. This is a belief /
--     attribution topic, so "scope" is about WHO can hold and state a position,
--     not who has a policy lever (there is none over a past national event).
--     Officials at every level have publicly taken a side on 2020, and voters
--     want to know whether their local and state officials — city council,
--     mayor, state legislator, secretary of state — said it was stolen. So it
--     applies to federal, state and local candidates alike. Judicial is
--     excluded: opining on 2020 is a norm-violation for the bench, so those
--     seats carry no spoke here.
--
--   * POLARITY IS NOT THE CORPUS DEFAULT. The corpus lean is "value 1 = maximum
--     government action / progressive pole", but this is a belief axis, so that
--     rule does not apply. Orientation was chosen DELIBERATELY to match the
--     sibling topic Voting Rights, where value 5 is the fraud-concerned end:
--         1 = the election was legitimate  ...  5 = the election was stolen.
--     Do not "correct" this to a progressive-1 reading.
--
--   * THE FIVE RUNGS ARE ONE AXIS WITH FOUR REAL THRESHOLDS (not an effort-dial):
--         1→2  concedes real process problems (but claims no fraud)
--         2→3  concedes actual fraud occurred
--         3→4  fraud might have changed WHO WON
--         4→5  hedged "may have" hardens into asserted "was stolen"
--     Each rung seats real, sourced people (grounding pass, 2026-08-29):
--         1  CISA/Chris Krebs "most secure election in American history";
--            the "Lost, Not Stolen" report by eight senior Republicans.
--         2  Republicans who accepted the result yet backed new election laws /
--            audits "to restore confidence" (e.g. state officials who signed
--            post-2020 "election integrity" laws while affirming Biden won).
--         3  AG Bill Barr (Dec 2020): "we have not seen fraud on a scale that
--            could have affected a different outcome in the election."
--         4  Sen. Ron Johnson's "many unexplained irregularities"; the ~10% of
--            2022 GOP nominees who "cast doubt" without full denial.
--         5  Donald Trump ("rigged"/"stolen"); the ~35% of 2022 GOP nominees
--            who fully rejected Biden's win.
--
--   * "REFUSED TO GIVE A STRAIGHT ANSWER" IS A BLANK SPOKE, NOT A RUNG. A large,
--     deliberate cohort dodged the question ("evasively complained of
--     'irregularities'" and would not say whether Biden won). Encoding that as a
--     middle rung would conflate a non-answer with a moderate view and mix two
--     axes. Per compass convention it is a BLANK SPOKE — and, because it is the
--     biggest non-pole group here, the evasion MUST be captured as a sourced
--     Read & Rank quote so the blank does not read as "not yet researched".
--
-- HOW IT IS CREATED
-- Through the ADR 0004 revision model, via the prod RPC
-- inform.admin_create_topic_with_revision (CA_0026, applied 2026-08-28). The RPC
-- writes all five layers atomically — identity row, legacy 1..5 ladder (5:5
-- parity), a founding v1 revision (revision=1, version=1,
-- change_class='substantive', status='published', is_current=true,
-- rung_map=NULL), the five stance revisions, and the role scope. The legacy
-- inform.admin_create_topic_with_stances RPC is INSUFFICIENT — it writes no
-- revision, so the season read path (ADR 0006) cannot see or pin the topic.
--
-- STAGED, NOT LIVE. is_live=false and no season pins it, so it shows on NO voter
-- surface. The season-gated promoted view (CA_0021) is what gates display, not
-- is_live. It goes live only when a DRAFT season pins it
-- (inform.admin_season_add_topic, CA_0022) and that season OPENS
-- (inform.admin_open_season, CA_0024). Pinning is a separate, later step.
--
-- IDEMPOTENT: the create runs only when topic_key '2020-election' is absent, so a
-- re-run is a no-op. The post-verify gate then asserts the full shape either way.
-- To revert: delete the topic row (its revisions/stances/roles cascade). No
-- existing object is altered.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Create the topic (guarded so a re-run does not hit DUPLICATE_TOPIC_KEY).
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_topics WHERE topic_key = '2020-election'
  ) THEN
    PERFORM inform.admin_create_topic_with_revision(
      '2020 Presidential Election',                                        -- p_title
      'What is your view of the outcome of the 2020 presidential election?', -- p_question_text
      '2020 Election',                                                     -- p_short_title -> topic_key '2020-election'
      false,                                                              -- p_is_live (staged)
      '[
        {"value":1,"text":"The election was fair and Joe Biden won legitimately."},
        {"value":2,"text":"Joe Biden won, but the election had real problems worth fixing."},
        {"value":3,"text":"There was some fraud, but not enough to change the result."},
        {"value":4,"text":"Fraud or irregularities may have been enough to change the result."},
        {"value":5,"text":"The election was stolen from Donald Trump through widespread fraud."}
      ]'::jsonb,                                                          -- p_stances
      NULL,                                                               -- p_actor_id (see comment; users has no email/lookup key)
      '["federal","state","local"]'::jsonb                               -- p_role_scopes (all levels; belief topic — anyone can state a view)
    );
    RAISE NOTICE 'CA_0027: created topic 2020-election';
  ELSE
    RAISE NOTICE 'CA_0027: topic 2020-election already present — create skipped';
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- Post-verify gate. Asserts the topic exists in exactly the shape a
-- season-pinnable revision-model topic must have. A wrong count RAISEs and
-- aborts the whole transaction (default P0001), so nothing partial commits.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_topic uuid;
  v_n     int;
  v_t1    text;
  v_t5    text;
BEGIN
  SELECT id INTO v_topic FROM inform.compass_topics WHERE topic_key = '2020-election';
  IF v_topic IS NULL THEN
    RAISE EXCEPTION 'CA_0027: topic 2020-election is missing after create';
  END IF;

  -- exactly one published/current v1 substantive revision, rung_map NULL
  SELECT count(*) INTO v_n FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic AND is_current AND status = 'published'
     AND revision = 1 AND version = 1 AND change_class = 'substantive'
     AND rung_map IS NULL;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0027: expected 1 published/current v1 substantive revision (rung_map NULL), got %', v_n;
  END IF;

  -- five distinct stance-revision values on the current revision
  SELECT count(DISTINCT sr.value) INTO v_n
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current;
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CA_0027: expected 5 stance revisions, got %', v_n;
  END IF;

  -- five legacy stances (corpus 5:5 invariant)
  SELECT count(*) INTO v_n FROM inform.compass_stances WHERE topic_id = v_topic;
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CA_0027: expected 5 legacy stances, got %', v_n;
  END IF;

  -- exactly the three requested role rows: federal, state, local (never judicial)
  SELECT count(*) INTO v_n FROM inform.compass_topic_roles WHERE topic_id = v_topic;
  IF v_n <> 3 THEN
    RAISE EXCEPTION 'CA_0027: expected exactly 3 role rows, got %', v_n;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'federal')
     OR NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'state')
     OR NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'local') THEN
    RAISE EXCEPTION 'CA_0027: expected federal + state + local role rows';
  END IF;
  IF EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'judicial') THEN
    RAISE EXCEPTION 'CA_0027: unexpected judicial role row';
  END IF;

  -- polarity guard: value 1 is the "legitimate" pole, value 5 the "stolen" pole.
  -- Catches an accidental ladder inversion at author time.
  SELECT sr.text INTO v_t1
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current AND sr.value = 1;
  SELECT sr.text INTO v_t5
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current AND sr.value = 5;
  IF v_t1 NOT ILIKE '%legitimately%' OR v_t5 NOT ILIKE '%stolen%' THEN
    RAISE EXCEPTION 'CA_0027: polarity check failed (v1=%, v5=%)', v_t1, v_t5;
  END IF;

  -- must NOT be live yet: no season pins it, so the season-gated promoted view
  -- must not list it.
  IF EXISTS (SELECT 1 FROM inform.compass_topics_promoted WHERE id = v_topic) THEN
    RAISE EXCEPTION 'CA_0027: topic leaked into an open season before being pinned';
  END IF;

  RAISE NOTICE 'CA_0027 OK — 2020-election staged (1 published/current v1, 5 rungs, 5 legacy stances, 3 roles federal+state+local, polarity 1=legit/5=stolen, not promoted)';
END $$;

COMMIT;
