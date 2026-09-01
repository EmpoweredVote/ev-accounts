BEGIN;

-- =============================================================================
-- CA_0091: "Defense Spending" — a new compass topic (revision model)
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews.
--
-- WHAT THIS ADDS
-- A new voter-facing compass topic recording how much a candidate (or a voter)
-- thinks the government should spend on the military. topic_key is frozen at
-- 'defense-spending' (essentials.quotes joins on it — do not rename the key).
-- The topic is created STAGED (is_live=false) and PINNED into draft Season 2, so
-- it goes live only when Season 2 opens.
--
-- WHY THIS TOPIC
-- The live compass has 44 topics but only one foreign-policy axis (Ukraine
-- Support), which depends on one conflict staying in the news. Defense Spending
-- is the evergreen foreign/fiscal axis: it does not expire, and it seats nearly
-- every federal candidate on a recorded budget vote (the NDAA and defense
-- appropriations recur every year).
--
-- WHY IT IS BUILT THIS WAY (design decisions, so a later maintainer need not
-- re-derive them)
--
--   * ONE AXIS: BUDGET SIZE (dollars for the military). The five rungs vary along
--     a single line — how large the military budget should be. Value 1 = the
--     largest budget (most government action, matching the corpus default), value
--     5 = the deepest cut.
--
--   * GLOBAL FORCE POSTURE IS A DELIBERATELY EXCLUDED SECOND AXIS. An early draft
--     rung 5 read "cut deeply AND pull back from overseas commitments" — a
--     double-barrel. Budget size and global engagement are independent: an
--     "America First" restrainer can want to end foreign commitments while KEEPING
--     a large budget (missile defense, navy, border), and a fiscal hawk can want
--     cuts while keeping alliances. So NO rung names overseas commitments,
--     alliances, or intervention. The axis is money only. If a posture axis is
--     wanted later, build it as a separate topic.
--
--   * THIS IS A GENUINE MAGNITUDE AXIS, LIKE ABORTION'S GESTATIONAL THRESHOLDS.
--     The topic is inherently "how many dollars", so the rungs are magnitudes.
--     That is allowed because each rung is a CONCRETE, RECOGNIZABLE posture that
--     seats real politicians on a real vote — not a vague "more/less" effort-dial.
--     The four thresholds:
--         1→2  substantial buildup  vs  moderate real growth
--         2→3  real growth above inflation  vs  flat (inflation only)
--         3→4  hold the line  vs  an actual cut below current levels
--         4→5  a modest trim  vs  a dramatic, roughly-halving cut
--
--   * EACH RUNG SEATS REAL, SOURCED PEOPLE (grounding pass, 2026-08-31):
--         1  Sen. Roger Wicker's "Peace Through Strength" (5% of GDP, $1T+);
--            Sen. Tom Cotton; Trump's NATO 5% push.
--         2  The bipartisan NDAA mainstream — FY25 ~$895B passed the Senate 83-12;
--            most of the Senate Armed Services Committee; Sen. Jack Reed.
--         3  The 2023 Fiscal Responsibility Act's 1% caps (flat in real terms);
--            deficit-conscious members who resist real growth.
--         4  The Pocan-Lee / Sanders 10% cut amendments — a modest reduction
--            below current levels (the redirect-to-domestic caucus, described here
--            purely as the size of the cut, since redirection is a second question).
--         5  The deep-cut pole — anti-war left and libertarian non-interventionists
--            (Sen. Rand Paul, Rep. Thomas Massie), and the recurring "we would
--            still outspend China at half the budget" argument.
--
--   * FEDERAL ONLY. role_scopes = ['federal']. The military budget is set by
--     Congress; state and local officials hold no lever over it, and judicial is
--     excluded. This matches the sibling federal-only fiscal topics (Tariffs,
--     Social Security).
--
--   * QUESTION IS NEUTRAL AND OPEN ("How much should the government spend on the
--     military?") — names the budget axis without prescribing a direction and
--     without a double-barrel.
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
-- STAGED, THEN PINNED INTO SEASON 2. is_live=false, so the topic shows on NO
-- voter surface on its own (the season-gated promoted view, CA_0021, gates
-- display, not is_live). It is then pinned into the DRAFT Season 2
-- (id 86d893a1-c1a2-4bbf-b4e5-69ec43221194) with inform.admin_season_add_topic
-- (CA_0022), which auto-selects the v1 published/current revision and assigns the
-- next question number. It goes live only when Season 2 OPENS
-- (inform.admin_open_season). Until then it is NOT in compass_topics_promoted
-- (that view is gated to the OPEN season, Season 1).
--
-- IDEMPOTENT: the create runs only when topic_key 'defense-spending' is absent,
-- and the pin runs only when the topic is not already in Season 2, so a re-run is
-- a no-op. The post-verify gate then asserts the full shape either way.
-- To revert: remove the Season 2 pin (inform.admin_season_remove_topic) and
-- delete the topic row (its revisions/stances/roles cascade). No existing object
-- is altered.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Create the topic (guarded so a re-run does not hit DUPLICATE_TOPIC_KEY).
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_topics WHERE topic_key = 'defense-spending'
  ) THEN
    PERFORM inform.admin_create_topic_with_revision(
      'Defense Spending',                                    -- p_title
      'How much should the government spend on the military?', -- p_question_text
      'Defense Spending',                                    -- p_short_title -> topic_key 'defense-spending'
      false,                                                 -- p_is_live (staged)
      '[
        {"value":1,"text":"Increase military spending substantially, launching a major buildup to expand the armed forces and their capabilities."},
        {"value":2,"text":"Increase military spending moderately, growing the budget above inflation to keep pace with rising threats."},
        {"value":3,"text":"Hold military spending roughly flat, allowing it to rise only with inflation."},
        {"value":4,"text":"Reduce military spending modestly below current levels."},
        {"value":5,"text":"Cut military spending dramatically, roughly halving the budget or more."}
      ]'::jsonb,                                             -- p_stances
      NULL,                                                  -- p_actor_id (users has no email/lookup key; see CA_0027)
      '["federal"]'::jsonb                                   -- p_role_scopes (federal only — budget is set by Congress)
    );
    RAISE NOTICE 'CA_0091: created topic defense-spending';
  ELSE
    RAISE NOTICE 'CA_0091: topic defense-spending already present — create skipped';
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- Pin the topic into draft Season 2 (guarded so a re-run does not hit
-- ALREADY_IN_SEASON). add_topic auto-selects the v1 published/current revision
-- and assigns question_number = max+1.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_topic  uuid;
  v_season uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';  -- Season 2 (draft)
BEGIN
  SELECT id INTO v_topic FROM inform.compass_topics WHERE topic_key = 'defense-spending';
  IF v_topic IS NULL THEN
    RAISE EXCEPTION 'CA_0091: topic defense-spending is missing before season pin';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM inform.season_questions
     WHERE season_id = v_season AND topic_id = v_topic
  ) THEN
    PERFORM inform.admin_season_add_topic(v_season, v_topic, NULL);
    RAISE NOTICE 'CA_0091: pinned defense-spending into Season 2';
  ELSE
    RAISE NOTICE 'CA_0091: defense-spending already pinned in Season 2 — pin skipped';
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- Assign the topic to the "Foreign Policy and National Security" category
-- (idempotent; PK is (topic_id, category_id)). Looked up by topic_key so the
-- step does not depend on a hardcoded topic id.
-- ---------------------------------------------------------------------------
INSERT INTO inform.compass_topic_categories (topic_id, category_id)
SELECT t.id, 'f41cef76-e438-4a0a-a9f3-13beba247f73'::uuid
  FROM inform.compass_topics t
 WHERE t.topic_key = 'defense-spending'
ON CONFLICT (topic_id, category_id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Post-verify gate. Asserts the topic exists in exactly the shape a
-- season-pinnable revision-model topic must have, that it is pinned into
-- Season 2 (draft, not yet live), and that it carries its category. A wrong
-- count RAISEs and aborts the whole transaction (default P0001), so nothing
-- partial commits.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_topic  uuid;
  v_season uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';  -- Season 2 (draft)
  v_rev    uuid;
  v_n      int;
  v_t1     text;
  v_t5     text;
BEGIN
  SELECT id INTO v_topic FROM inform.compass_topics WHERE topic_key = 'defense-spending';
  IF v_topic IS NULL THEN
    RAISE EXCEPTION 'CA_0091: topic defense-spending is missing after create';
  END IF;

  -- exactly one published/current v1 substantive revision, rung_map NULL
  SELECT count(*) INTO v_n FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic AND is_current AND status = 'published'
     AND revision = 1 AND version = 1 AND change_class = 'substantive'
     AND rung_map IS NULL;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0091: expected 1 published/current v1 substantive revision (rung_map NULL), got %', v_n;
  END IF;

  -- five distinct stance-revision values on the current revision
  SELECT count(DISTINCT sr.value) INTO v_n
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current;
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CA_0091: expected 5 stance revisions, got %', v_n;
  END IF;

  -- five legacy stances (corpus 5:5 invariant)
  SELECT count(*) INTO v_n FROM inform.compass_stances WHERE topic_id = v_topic;
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CA_0091: expected 5 legacy stances, got %', v_n;
  END IF;

  -- exactly one role row: federal (never state/local/judicial)
  SELECT count(*) INTO v_n FROM inform.compass_topic_roles WHERE topic_id = v_topic;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0091: expected exactly 1 role row, got %', v_n;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'federal') THEN
    RAISE EXCEPTION 'CA_0091: expected a federal role row';
  END IF;
  IF EXISTS (SELECT 1 FROM inform.compass_topic_roles
              WHERE topic_id = v_topic AND role_scope IN ('state','local','judicial')) THEN
    RAISE EXCEPTION 'CA_0091: unexpected non-federal role row';
  END IF;

  -- topic_key frozen exactly (essentials.quotes joins on it)
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics
                  WHERE id = v_topic AND topic_key = 'defense-spending') THEN
    RAISE EXCEPTION 'CA_0091: topic_key drifted from defense-spending';
  END IF;

  -- polarity guard: value 1 is the "increase"/buildup pole, value 5 the "cut" pole.
  -- Catches an accidental ladder inversion at author time.
  SELECT sr.text INTO v_t1
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current AND sr.value = 1;
  SELECT sr.text INTO v_t5
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current AND sr.value = 5;
  IF v_t1 NOT ILIKE 'Increase%' OR v_t5 NOT ILIKE 'Cut%' THEN
    RAISE EXCEPTION 'CA_0091: polarity check failed (v1=%, v5=%)', v_t1, v_t5;
  END IF;

  -- pinned into Season 2, on the current published revision
  SELECT r.id INTO v_rev
    FROM inform.compass_topic_revisions r
   WHERE r.topic_id = v_topic AND r.is_current AND r.status = 'published';
  SELECT count(*) INTO v_n FROM inform.season_questions
   WHERE season_id = v_season AND topic_id = v_topic AND topic_revision_id = v_rev;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0091: expected 1 Season 2 pin on the current revision, got %', v_n;
  END IF;

  -- must NOT be live yet: Season 2 is a DRAFT, so the season-gated promoted view
  -- (which serves the OPEN season) must not list it.
  IF EXISTS (SELECT 1 FROM inform.compass_topics_promoted WHERE id = v_topic) THEN
    RAISE EXCEPTION 'CA_0091: topic leaked into the open season before Season 2 opened';
  END IF;

  -- assigned to the Foreign Policy and National Security category
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_topic_categories
     WHERE topic_id = v_topic
       AND category_id = 'f41cef76-e438-4a0a-a9f3-13beba247f73'
  ) THEN
    RAISE EXCEPTION 'CA_0091: expected Foreign Policy and National Security category assignment';
  END IF;

  RAISE NOTICE 'CA_0091 OK — defense-spending staged (1 published/current v1, 5 rungs, 5 legacy stances, 1 federal role, polarity 1=increase/5=cut, pinned into draft Season 2, category assigned, not promoted)';
END $$;

COMMIT;
