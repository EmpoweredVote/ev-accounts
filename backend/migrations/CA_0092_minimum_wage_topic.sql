BEGIN;

-- =============================================================================
-- CA_0092: "Minimum Wage" — a new compass topic (revision model), pinned to S2
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews.
--
-- WHAT THIS ADDS
-- A new voter-facing compass topic scoring how an official (or a voter) would
-- have government set the minimum wage. topic_key is frozen at 'minimum-wage'
-- (essentials.quotes joins on it). It fills a real gap: the corpus spreads the
-- economy across Taxes, Tariffs, Social Security, Medicare, Housing and Economic
-- Development, but NO topic covered pay/wages directly. Cost of living is the #1
-- issue in 2026 midterm polling, and the minimum wage is the cleanest single-axis
-- wage lever. Cities and states set their own floors, so all three levels hold a
-- real lever — hence role scopes federal + state + local.
--
-- WHY IT IS BUILT THIS WAY (design decisions, so a later maintainer need not
-- re-derive them)
--
--   * ONE AXIS: THE STRENGTH AND SELF-SUSTAINMENT OF A GOVERNMENT-SET WAGE FLOOR.
--     Value 1 = the strongest floor (high AND rising on its own); value 5 = no
--     floor at all. The five rungs fall monotonically along that one line:
--         1  a floor that rises automatically with prices (indexed) — strongest,
--            needs no future vote to keep pace
--         2  a legislated higher floor with NO escalator — strong, but erodes
--            between votes (the pre-2009 federal model; why $7.25 lost value)
--         3  a low national baseline, with higher rates DEVOLVED to states/cities
--         4  the floor frozen at its current level; the market sets pay above it
--         5  no floor — pay set by employer/worker agreement alone
--
--   * POLARITY IS THE CORPUS DEFAULT HERE (value 1 = maximum government action).
--     Unlike AI Oversight / Tariffs, this ladder is NOT reversed. Do not "correct"
--     it in either direction.
--
--   * RUNGS 1 vs 2 ARE A MECHANISM DISTINCTION, NOT A MAGNITUDE DIAL. Both raise
--     the floor. They differ on whether it self-escalates (rung 1, indexed) or
--     must be re-raised by periodic legislative vote (rung 2). This deliberately
--     avoids the "significantly / moderately raise" effort-dial trap: the line is
--     automatic-vs-manual upkeep, a concrete, recognizable difference. The entire
--     real-world indexing fight is exactly this line — Missouri Prop A (2024) and
--     Alaska (2024) voters CHOSE indexing; the old federal statute did not, which
--     is why $7.25 eroded. Chris ruled 2026-08-31 to KEEP rung 1's "raise + index"
--     bundled: indexing is the strongest form of a floor (the top of the axis) and
--     one real coalition posture carries both; splitting it out would need a 6th
--     rung. Recorded as a BORDERLINE double-barrel, kept by decision.
--
--   * RUNG 3 NAMES "STATES AND CITIES" ON PURPOSE. The level-agnostic gate warns
--     against naming levels, but the devolution posture IS "the floor belongs to
--     lower levels." The words carry the rung's meaning; removing them would gut
--     it. Only rung 3 references levels — rungs 1, 2, 4, 5 are level-neutral, so a
--     city councilmember and a U.S. senator still land on the same 5-point scale.
--
--   * EACH RUNG SEATS REAL, SOURCED POSITIONS (grounding pass, WebSearch,
--     2026-08-31):
--         1  Raise the Wage Act of 2025 (Sanders/Scott; ~29 Senate + 175 House
--            cosponsors): $17 by 2030 AND index to median wage growth. State
--            ballot measures MO Prop A / Alaska: $15 then indexed to inflation.
--         2  GOP "gradually raise to $10" bill (Cotton/Romney) and the original
--            $15 push with no escalator — a fixed statutory number, manual upkeep.
--         3  The dominant Republican "let states decide by cost of living"
--            posture; 31 states already set floors above the federal $7.25.
--         4  192 House Republicans voted against the 2025 Raise the Wage Act;
--            ~76% of GOP voters oppose raising it — hold $7.25, market sets pay.
--         5  Libertarian / free-market abolition of a mandated wage floor
--            (historically Sen. Lamar Alexander; free-market economists).
--
-- HOW IT IS CREATED
-- Through the ADR 0004 revision model, via the prod RPC
-- inform.admin_create_topic_with_revision (CA_0026). The RPC writes all five
-- layers atomically — identity row, legacy 1..5 ladder, a founding v1 revision
-- (revision=1, version=1, change_class='substantive', status='published',
-- is_current=true, rung_map=NULL), the five stance revisions, and the role
-- scopes. The RPC has no argument for the design rationale, so it lives in these
-- comments (CA_0027 is the model). The legacy admin_create_topic_with_stances RPC
-- is INSUFFICIENT — it writes no revision.
--
-- PINNED TO SEASON 2, NOT LIVE YET. Chris ruled 2026-08-31 to stage this into
-- Season 2. is_live=false. The migration then pins the founding v1 revision into
-- the DRAFT Season 2 (inform.admin_season_add_topic, auto-numbered), and assigns
-- the "Economic Policy and Labor" category. It shows on NO voter surface until
-- Season 2 OPENS (inform.admin_open_season). Pinning a topic into a DRAFT season
-- does not promote it — the season-gated promoted view lists only OPEN-season
-- topics — so the gate still asserts "not promoted".
--
-- IDEMPOTENT: the create runs only when topic_key 'minimum-wage' is absent; the
-- season pin runs only when the topic is not already in Season 2; the category
-- link uses ON CONFLICT DO NOTHING. A re-run is a no-op. The post-verify gate
-- asserts the full shape either way. To revert: delete the topic row (revisions,
-- stances, roles, season_questions and category links cascade). No existing
-- object is altered.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Create the topic (guarded so a re-run does not hit DUPLICATE_TOPIC_KEY).
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_topics WHERE topic_key = 'minimum-wage'
  ) THEN
    PERFORM inform.admin_create_topic_with_revision(
      'Minimum Wage',                                                       -- p_title
      'What approach should government take to the minimum wage?',          -- p_question_text
      'Minimum Wage',                                                       -- p_short_title -> topic_key 'minimum-wage'
      false,                                                               -- p_is_live (staged)
      '[
        {"value":1,"text":"Raise the wage floor and tie it to the cost of living, so it rises automatically each year without new legislation."},
        {"value":2,"text":"Raise the wage floor to a set higher level, then adjust it only when lawmakers vote to."},
        {"value":3,"text":"Keep a modest national wage floor as a baseline and let states and cities set higher rates."},
        {"value":4,"text":"Hold the wage floor at its current level and let the market set pay above it."},
        {"value":5,"text":"Remove the wage floor entirely and let employers and workers set pay by agreement."}
      ]'::jsonb,                                                           -- p_stances
      NULL,                                                                -- p_actor_id
      '["federal","state","local"]'::jsonb                                 -- p_role_scopes (all three levels hold a wage-floor lever)
    );
    RAISE NOTICE 'CA_0092: created topic minimum-wage';
  ELSE
    RAISE NOTICE 'CA_0092: topic minimum-wage already present — create skipped';
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 2. Pin the founding v1 revision into DRAFT Season 2 (auto-numbered), and
--    assign the "Economic Policy and Labor" category. Both idempotent.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_topic  uuid;
  v_season uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';  -- Season 2 (status=draft)
  v_cat    uuid := 'e167477a-d3b6-43ea-8348-d451946bfdda';  -- Economic Policy and Labor
BEGIN
  SELECT id INTO v_topic FROM inform.compass_topics WHERE topic_key = 'minimum-wage';
  IF v_topic IS NULL THEN
    RAISE EXCEPTION 'CA_0092: topic minimum-wage is missing before pin';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM inform.season_questions
     WHERE season_id = v_season AND topic_id = v_topic
  ) THEN
    PERFORM inform.admin_season_add_topic(v_season, v_topic, NULL);
    RAISE NOTICE 'CA_0092: pinned minimum-wage into Season 2';
  ELSE
    RAISE NOTICE 'CA_0092: minimum-wage already in Season 2 — pin skipped';
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
  v_season uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_cat    uuid := 'e167477a-d3b6-43ea-8348-d451946bfdda';
  v_n      int;
  v_t1     text;
  v_t5     text;
BEGIN
  SELECT id INTO v_topic FROM inform.compass_topics WHERE topic_key = 'minimum-wage';
  IF v_topic IS NULL THEN
    RAISE EXCEPTION 'CA_0092: topic minimum-wage is missing after create';
  END IF;

  -- exactly one published/current v1 substantive revision, rung_map NULL
  SELECT count(*) INTO v_n FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic AND is_current AND status = 'published'
     AND revision = 1 AND version = 1 AND change_class = 'substantive'
     AND rung_map IS NULL;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0092: expected 1 published/current v1 substantive revision (rung_map NULL), got %', v_n;
  END IF;

  -- five distinct stance-revision values on the current revision
  SELECT count(DISTINCT sr.value) INTO v_n
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current;
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CA_0092: expected 5 stance revisions, got %', v_n;
  END IF;

  -- five legacy stances (corpus 5:5 invariant)
  SELECT count(*) INTO v_n FROM inform.compass_stances WHERE topic_id = v_topic;
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CA_0092: expected 5 legacy stances, got %', v_n;
  END IF;

  -- exactly the three requested role rows: federal, state, local (never judicial)
  SELECT count(*) INTO v_n FROM inform.compass_topic_roles WHERE topic_id = v_topic;
  IF v_n <> 3 THEN
    RAISE EXCEPTION 'CA_0092: expected exactly 3 role rows, got %', v_n;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'federal')
     OR NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'state')
     OR NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'local') THEN
    RAISE EXCEPTION 'CA_0092: expected federal + state + local role rows';
  END IF;
  IF EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'judicial') THEN
    RAISE EXCEPTION 'CA_0092: unexpected judicial role row';
  END IF;

  -- polarity guard: value 1 is the strongest floor (indexed/auto-rising),
  -- value 5 removes the floor. Catches an accidental ladder inversion.
  SELECT sr.text INTO v_t1
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current AND sr.value = 1;
  SELECT sr.text INTO v_t5
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current AND sr.value = 5;
  IF v_t1 NOT ILIKE '%automatically%' OR v_t5 NOT ILIKE '%Remove the wage floor%' THEN
    RAISE EXCEPTION 'CA_0092: polarity check failed (v1=%, v5=%)', v_t1, v_t5;
  END IF;

  -- pinned into Season 2, on the current published revision
  SELECT count(*) INTO v_n
    FROM inform.season_questions sq
    JOIN inform.compass_topic_revisions r ON r.id = sq.topic_revision_id
   WHERE sq.season_id = v_season AND sq.topic_id = v_topic
     AND r.is_current AND r.status = 'published';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0092: expected minimum-wage pinned once into Season 2 on its current revision, got %', v_n;
  END IF;

  -- category assigned
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_topic_categories
     WHERE topic_id = v_topic AND category_id = v_cat
  ) THEN
    RAISE EXCEPTION 'CA_0092: minimum-wage not assigned to the Economic Policy and Labor category';
  END IF;

  -- must NOT be live yet: Season 2 is a DRAFT, so the season-gated promoted view
  -- (open-season only) must not list it.
  IF EXISTS (SELECT 1 FROM inform.compass_topics_promoted WHERE id = v_topic) THEN
    RAISE EXCEPTION 'CA_0092: topic leaked into an open season before Season 2 opened';
  END IF;

  RAISE NOTICE 'CA_0092 OK — minimum-wage staged (1 published/current v1, 5 rungs, 5 legacy stances, 3 roles federal+state+local, polarity 1=indexed/5=no-floor, pinned to draft Season 2, category assigned, not promoted)';
END $$;

COMMIT;
