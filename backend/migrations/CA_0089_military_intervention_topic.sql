BEGIN;

-- =============================================================================
-- CA_0089: "Foreign Military Intervention" — a new compass topic (revision model)
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews.
--
-- WHAT THIS ADDS
-- A new voter-facing compass topic recording where a federal official (or a
-- voter) stands on the U.S.'s posture toward using military force abroad.
-- topic_key is frozen at 'military-intervention' (essentials.quotes joins on it).
--
-- WHY IT EXISTS
-- The live compass carries 44 topics but only ONE foreign-policy topic (Ukraine
-- Support), and that one is chained to a single ongoing conflict. "Should the US
-- have struck Iran?" is a one-time event, not a standing spectrum, so it fails
-- the axis test. This topic is the DURABLE reframe: the U.S.'s general posture on
-- projecting military force — from acting as the world's police to pulling back.
-- It absorbs the Iran question (and the next such question) without tying the
-- topic to one news cycle.
--
-- WHY IT IS BUILT THIS WAY (design decisions, so a later maintainer need not
-- re-derive them)
--
--   * ONE AXIS: FORCE-PROJECTION POSTURE. The whole ladder varies along a single
--     line — how actively the U.S. should use military force abroad — from global
--     primacy (value 1) to restraint/withdrawal (value 5). It is NOT a magnitude
--     dial ("a lot / some / none"): each rung is a distinct, recognizable posture
--     (who does what, and when), each seating real, sourced politicians.
--
--   * FEDERAL-ONLY SCOPE. War-powers authorizations, troop deployments, alliance
--     commitments, and the use of force abroad are federal levers (Congress and
--     the President). State and local officials hold no lever here, so a spoke at
--     those levels could only be evidenced by opinion — the exact shape the
--     evidence standard refuses. role_scopes = ['federal'] only. Not judicial.
--
--   * POLARITY MATCHES THE CORPUS DEFAULT: value 1 = most military action.
--         1 = actively lead and police the world  ...  5 = withdraw and end it.
--     Chosen deliberately (not every ladder runs this way — see AI Oversight,
--     Tariffs). Do not "correct" it.
--
--   * THE FIVE RUNGS ARE ONE AXIS WITH FOUR REAL THRESHOLDS (not an effort-dial):
--         1→2  drops proactive world-policing; acts only when OUR interests/allies
--              are threatened (reactive, not offensive)
--         2→3  makes diplomacy and sanctions the DEFAULT tool; force needs to be a
--              last resort with authorization
--         3→4  refuses overseas force entirely; homeland defense only (but keeps
--              the existing military/alliance footprint as deterrence)
--         4→5  actively DISMANTLES the footprint — withdraw troops, wind down
--              overseas commitments, end intervention (a change to the footprint,
--              not just a rule about when to use it)
--     The 4 vs 5 line is real: chair 4 KEEPS the footprint but won't act; chair 5
--     PULLS OUT of what already exists. Someone can hold 4 (no new wars, keep NATO
--     and the bases) without holding 5 (leave NATO, close bases).
--
--     Each rung seats real, sourced people (grounding pass via WebSearch,
--     2026-08-31):
--         1  Tom Cotton (R-AR), the late Lindsey Graham (R-SC): American
--            leadership requires overwhelming military dominance; confront hostile
--            regimes before they threaten the U.S.
--         2  Mainstream hawks / liberal interventionists who back striking Iran's
--            nuclear program or defending treaty allies but reject general
--            world-policing; John Fetterman (D-PA) voted AGAINST the Iran War
--            Powers Resolution (i.e. to allow the strike).
--         3  Iran War Powers Resolution sponsors (S.J.Res., failed 47-53,
--            2025-06-27): Tim Kaine (D-VA), Chris Murphy (D-CT), Adam Schiff
--            (D-CA), Chris Van Hollen (D-MD), Cory Booker (D-NJ) — diplomacy
--            first, force only with clear authorization.
--         4  Restrainer realists (J.D. Vance-aligned): keep a capable military but
--            limit its use to defending U.S. territory; stay out of others' wars.
--         5  Bipartisan War Powers Caucus: Rand Paul (R-KY), Thomas Massie (R-KY),
--            Ro Khanna (D-CA), Andy Biggs (R-AZ) — end endless wars, wind down
--            overseas commitments, bring troops home.
--
--   * CLOSEST EXISTING TOPIC = Ukraine Support (ukraine-support). Distinct: that
--     topic scores support for ONE conflict; this scores the general use-of-force
--     posture. No overlap in topic_key; no quotes orphaned (a new topic has none).
--
-- HOW IT IS CREATED
-- Through the ADR 0004 revision model, via the prod RPC
-- inform.admin_create_topic_with_revision (CA_0026, applied 2026-08-28). The RPC
-- writes all five layers atomically — identity row, legacy 1..5 ladder (5:5
-- parity), a founding v1 revision (revision=1, version=1,
-- change_class='substantive', status='published', is_current=true,
-- rung_map=NULL), the five stance revisions, and the role scope(s). The legacy
-- inform.admin_create_topic_with_stances RPC is INSUFFICIENT — it writes no
-- revision, so the season read path (ADR 0006) cannot see or pin the topic.
--
-- STAGED, NOT LIVE. is_live=false and no season pins it, so it shows on NO voter
-- surface. The season-gated promoted view (CA_0021) gates display, not is_live.
-- It goes live only when a DRAFT season pins it (inform.admin_season_add_topic,
-- CA_0022) and that season OPENS (inform.admin_open_season). Pinning is a
-- separate, later step (the Season 2 decision).
--
-- IDEMPOTENT: the create runs only when topic_key 'military-intervention' is
-- absent, so a re-run is a no-op. The post-verify gate then asserts the full
-- shape either way. To revert: delete the topic row (its revisions/stances/roles
-- cascade). No existing object is altered.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Create the topic (guarded so a re-run does not hit DUPLICATE_TOPIC_KEY).
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_topics WHERE topic_key = 'military-intervention'
  ) THEN
    PERFORM inform.admin_create_topic_with_revision(
      'Foreign Military Intervention',                        -- p_title
      'How should the United States use military force abroad?', -- p_question_text
      'Military Intervention',                                -- p_short_title -> topic_key 'military-intervention'
      false,                                                  -- p_is_live (staged)
      '[
        {"value":1,"text":"Use US military power to actively lead and police conflicts around the world."},
        {"value":2,"text":"Intervene militarily when clear US interests or allied nations are directly threatened."},
        {"value":3,"text":"Prefer diplomacy and economic sanctions, using military force only as a last resort."},
        {"value":4,"text":"Avoid overseas military action except to defend US territory from direct attack."},
        {"value":5,"text":"Withdraw from overseas military commitments and end foreign military intervention."}
      ]'::jsonb,                                              -- p_stances
      NULL,                                                   -- p_actor_id
      '["federal"]'::jsonb                                    -- p_role_scopes (federal only — war powers are a federal lever)
    );
    RAISE NOTICE 'CA_0089: created topic military-intervention';
  ELSE
    RAISE NOTICE 'CA_0089: topic military-intervention already present — create skipped';
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
  SELECT id INTO v_topic FROM inform.compass_topics WHERE topic_key = 'military-intervention';
  IF v_topic IS NULL THEN
    RAISE EXCEPTION 'CA_0089: topic military-intervention is missing after create';
  END IF;

  -- exactly one published/current v1 substantive revision, rung_map NULL
  SELECT count(*) INTO v_n FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic AND is_current AND status = 'published'
     AND revision = 1 AND version = 1 AND change_class = 'substantive'
     AND rung_map IS NULL;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0089: expected 1 published/current v1 substantive revision (rung_map NULL), got %', v_n;
  END IF;

  -- five distinct stance-revision values on the current revision
  SELECT count(DISTINCT sr.value) INTO v_n
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current;
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CA_0089: expected 5 stance revisions, got %', v_n;
  END IF;

  -- five legacy stances (corpus 5:5 invariant)
  SELECT count(*) INTO v_n FROM inform.compass_stances WHERE topic_id = v_topic;
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CA_0089: expected 5 legacy stances, got %', v_n;
  END IF;

  -- exactly one role row: federal (never state/local/judicial)
  SELECT count(*) INTO v_n FROM inform.compass_topic_roles WHERE topic_id = v_topic;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0089: expected exactly 1 role row, got %', v_n;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'federal') THEN
    RAISE EXCEPTION 'CA_0089: expected a federal role row';
  END IF;
  IF EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope <> 'federal') THEN
    RAISE EXCEPTION 'CA_0089: unexpected non-federal role row';
  END IF;

  -- polarity guard: value 1 is the "police the world" pole, value 5 the
  -- "withdraw / end intervention" pole. Catches an accidental ladder inversion.
  SELECT sr.text INTO v_t1
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current AND sr.value = 1;
  SELECT sr.text INTO v_t5
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current AND sr.value = 5;
  IF v_t1 NOT ILIKE '%police%' OR v_t5 NOT ILIKE '%withdraw%' THEN
    RAISE EXCEPTION 'CA_0089: polarity check failed (v1=%, v5=%)', v_t1, v_t5;
  END IF;

  -- must NOT be live yet: no season pins it, so the season-gated promoted view
  -- must not list it.
  IF EXISTS (SELECT 1 FROM inform.compass_topics_promoted WHERE id = v_topic) THEN
    RAISE EXCEPTION 'CA_0089: topic leaked into an open season before being pinned';
  END IF;

  RAISE NOTICE 'CA_0089 OK — military-intervention staged (1 published/current v1, 5 rungs, 5 legacy stances, 1 federal role, polarity 1=police/5=withdraw, not promoted)';
END $$;

COMMIT;
