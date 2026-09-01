BEGIN;

-- =============================================================================
-- CA_0087: "Israel Military Aid" — a new compass topic (revision model)
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews.
--
-- WHAT THIS ADDS
-- A new voter-facing compass topic recording where an official (or a voter)
-- stands on U.S. military aid to Israel. topic_key is frozen at
-- 'israel-military-aid' (essentials.quotes joins on it). This is the compass's
-- SECOND foreign-policy topic; the first and only sibling is Ukraine Support.
--
-- WHY IT IS BUILT THIS WAY (design decisions, so a later maintainer need not
-- re-derive them)
--
--   * ONE AXIS: LEVEL OF U.S. MILITARY SUPPORT. Every rung varies along a single
--     line — how much military support the United States gives Israel — from
--     full unconditional aid down to a complete cutoff. It is NOT a two-state /
--     ceasefire / diplomacy axis; those are off-axis limbs and were kept out.
--     State-level divestment and anti-BDS laws are a DIFFERENT axis (a state
--     lever, not a military-aid lever) and are deliberately excluded — this
--     topic is federal-only.
--
--   * FEDERAL SCOPE ONLY. Military aid to a foreign country (Foreign Military
--     Financing, direct arms sales, the U.S.-Israel defense-cooperation MOU) is
--     a purely federal lever. A city council or a state legislator holds no
--     instrument over it. So role_scopes = ['federal'] — matching the sibling
--     Ukraine Support topic, which is also federal-only.
--
--   * POLARITY MATCHES UKRAINE SUPPORT (deliberate, not the corpus default).
--     The corpus lean is "value 1 = maximum government action". Here value 1 is
--     the MAXIMUM-SUPPORT / hawkish pole and value 5 is END-ALL-AID, chosen to
--     read the SAME DIRECTION as the sibling foreign-aid topic Ukraine Support
--     (rev 3): 1 = significantly increase aid ... 5 = end all aid immediately.
--     The two foreign-aid topics must read the same way so a voter is not
--     whipsawed between them. Do not "correct" this to a progressive-1 reading.
--         1 = full aid, no conditions   ...   5 = end all military aid.
--
--   * THE FIVE RUNGS ARE ONE AXIS WITH FOUR REAL THRESHOLDS (not an effort-dial).
--     Each rung is a distinct, recognizable policy posture, and each seats real,
--     sourced 2026 officials (grounding pass, 2026-08-31 — see the topic-draft
--     JSON at backend/data/topic-drafts/2026-08-31-israel-military-aid.json):
--         1  Full military aid, NO new conditions. Republicans and the 7 Senate
--            Democrats who caucused with them in April 2026 to continue arms
--            sales (Schumer, Fetterman, Gillibrand, Coons, Blumenthal, Cortez
--            Masto, Rosen); AIPAC-aligned members.
--         2  Continue aid, but CONDITION it on compliance with humanitarian and
--            human-rights law. Van Hollen / Durbin / Kaine / Schatz amendment
--            requiring U.S. aid to comply with U.S. and international law; the
--            push to apply the Leahy Law to the IDF. Aid keeps flowing; strings
--            are attached.
--         3  DEFENSIVE-ONLY. Block offensive weapons sales (bombs, rifles) while
--            continuing defensive support such as missile defense. This is the
--            actual structure of the Sanders joint resolutions of disapproval,
--            which carve out air-defense systems "used for strictly defensive
--            purposes"; Welch, Murphy, and the ~33-40 senators who backed them.
--         4  SHARP DRAW-DOWN toward zero. Cut the military-aid package back
--            sharply as a step toward ending it — beyond rung 3 (which keeps
--            defensive aid flowing) but short of a full cutoff. The July 2026
--            House vote (104-314) to strip $3.3B in Foreign Military Financing;
--            the 100+ House Democrats who voted for it.
--         5  END ALL military aid to Israel. Abdul El-Sayed (won the 2026
--            Michigan Democratic Senate primary on exactly this), Rashida Tlaib,
--            the progressive wing.
--
--   * RUNG 3 IS ONE POSTURE, NOT A DOUBLE-BARREL. "Block offensive weapons while
--     continuing defensive support" reads as two clauses but is a SINGLE
--     recognized position — the offensive/defensive line is the whole point of
--     the chair, and anyone who sits in it holds both halves by definition. It
--     is how the real resolutions are drafted (offensive blocked, air defense
--     carved out). Kept as one rung on purpose.
--
--   * NO POLITICIANS ARE SEATED HERE. This migration creates the topic and its
--     empty 1..5 ladder only. It seats nobody, so the chair-evidence gate
--     (audit-chair-evidence.mjs) does not apply. Seating is later, per-person,
--     evidence-gated work.
--
-- HOW IT IS CREATED
-- Through the ADR 0004 revision model, via the prod RPC
-- inform.admin_create_topic_with_revision (CA_0026, applied 2026-08-28), which
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
-- (inform.admin_open_season, CA_0024). Whether it enters Season 2 is a separate
-- decision with Chris; pinning is a later, separate migration.
--
-- IDEMPOTENT: the create runs only when topic_key 'israel-military-aid' is
-- absent, so a re-run is a no-op. The post-verify gate then asserts the full
-- shape either way. To revert: delete the topic row (its revisions / stances /
-- roles cascade). No existing object is altered.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Create the topic (guarded so a re-run does not hit DUPLICATE_TOPIC_KEY).
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_topics WHERE topic_key = 'israel-military-aid'
  ) THEN
    PERFORM inform.admin_create_topic_with_revision(
      'U.S. Military Aid to Israel',                                   -- p_title
      'What level of military aid should the U.S. provide to Israel?', -- p_question_text
      'Israel Military Aid',                                           -- p_short_title -> topic_key 'israel-military-aid'
      false,                                                          -- p_is_live (staged)
      '[
        {"value":1,"text":"Continue full military aid to Israel with no new conditions."},
        {"value":2,"text":"Continue aid to Israel, but require it to comply with humanitarian and human-rights law."},
        {"value":3,"text":"Block offensive weapons sales while continuing defensive support such as missile defense."},
        {"value":4,"text":"Sharply cut military aid to Israel as a step toward ending it."},
        {"value":5,"text":"End all military aid to Israel."}
      ]'::jsonb,                                                      -- p_stances
      NULL,                                                           -- p_actor_id (users has no email/lookup key; see CA_0027)
      '["federal"]'::jsonb                                            -- p_role_scopes (federal-only; military aid is a federal lever)
    );
    RAISE NOTICE 'CA_0087: created topic israel-military-aid';
  ELSE
    RAISE NOTICE 'CA_0087: topic israel-military-aid already present — create skipped';
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
  v_key   text;
  v_t1    text;
  v_t5    text;
BEGIN
  SELECT id, topic_key INTO v_topic, v_key
    FROM inform.compass_topics WHERE topic_key = 'israel-military-aid';
  IF v_topic IS NULL THEN
    RAISE EXCEPTION 'CA_0087: topic israel-military-aid is missing after create';
  END IF;

  -- topic_key frozen correctly (derived from short_title 'Israel Military Aid')
  IF v_key <> 'israel-military-aid' THEN
    RAISE EXCEPTION 'CA_0087: topic_key wrong, got %', v_key;
  END IF;

  -- exactly one published/current v1 substantive revision, rung_map NULL
  SELECT count(*) INTO v_n FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic AND is_current AND status = 'published'
     AND revision = 1 AND version = 1 AND change_class = 'substantive'
     AND rung_map IS NULL;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0087: expected 1 published/current v1 substantive revision (rung_map NULL), got %', v_n;
  END IF;

  -- five distinct stance-revision values on the current revision
  SELECT count(DISTINCT sr.value) INTO v_n
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current;
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CA_0087: expected 5 stance revisions, got %', v_n;
  END IF;

  -- five legacy stances (corpus 5:5 invariant)
  SELECT count(*) INTO v_n FROM inform.compass_stances WHERE topic_id = v_topic;
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CA_0087: expected 5 legacy stances, got %', v_n;
  END IF;

  -- exactly one role row: federal (never state/local/judicial)
  SELECT count(*) INTO v_n FROM inform.compass_topic_roles WHERE topic_id = v_topic;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0087: expected exactly 1 role row, got %', v_n;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'federal') THEN
    RAISE EXCEPTION 'CA_0087: expected a federal role row';
  END IF;
  IF EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope <> 'federal') THEN
    RAISE EXCEPTION 'CA_0087: unexpected non-federal role row';
  END IF;

  -- polarity guard: value 1 is the "full aid, no conditions" pole, value 5 the
  -- "end all aid" pole. Catches an accidental ladder inversion at author time.
  SELECT sr.text INTO v_t1
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current AND sr.value = 1;
  SELECT sr.text INTO v_t5
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current AND sr.value = 5;
  IF v_t1 NOT ILIKE '%full military aid%' OR v_t5 NOT ILIKE '%End all military aid%' THEN
    RAISE EXCEPTION 'CA_0087: polarity check failed (v1=%, v5=%)', v_t1, v_t5;
  END IF;

  -- must NOT be live yet: no season pins it, so the season-gated promoted view
  -- must not list it.
  IF EXISTS (SELECT 1 FROM inform.compass_topics_promoted WHERE id = v_topic) THEN
    RAISE EXCEPTION 'CA_0087: topic leaked into an open season before being pinned';
  END IF;

  RAISE NOTICE 'CA_0087 OK — israel-military-aid staged (1 published/current v1, 5 rungs, 5 legacy stances, 1 role federal, polarity 1=full-aid/5=end-all, not promoted)';
END $$;

COMMIT;
