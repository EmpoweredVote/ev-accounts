-- CA_0083_cannabis_policy_topic.sql
-- Author: Chris Andrews (CA_ namespace, Andrews' slot). Next free CA_#### above CA_0082.
--
-- =============================================================================
-- CA_0083: "Cannabis Policy" — a NEW compass topic (revision model) + pin to Season 2
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
--
-- WHAT THIS ADDS
-- A new voter-facing compass topic scoring where an official (or a voter) stands on the legal
-- status of cannabis, from criminal prohibition to minimal-restriction legalization. The live
-- compass had 44 topics and NO drug/cannabis topic; the nearest neighbours (public-safety-approach,
-- jail-capacity, the judicial-* criminal-justice cluster) all score a different axis, so this
-- orphans no quotes and duplicates no topic. topic_key is frozen at 'cannabis-policy'
-- (essentials.quotes joins on it — a rename later would orphan its quotes).
--
-- SCOPE DECISION (Chris Andrews, 2026-08-31)
-- The axis was deliberately scoped NARROW to cannabis only ("Cannabis Policy"), not the broad
-- prohibition-to-harm-reduction "Drug Policy" axis. Rationale: cannabis is a clean single axis with
-- a dense record of real state/local votes and ballot measures, so every rung seats real
-- officials. A future harder-drugs topic can take the broad axis without colliding on topic_key.
--
-- WHY ONE AXIS, AND ITS POLARITY
-- The single axis is GOVERNMENT CONTROL over cannabis, decreasing monotonically 1 -> 5. Polarity
-- follows the corpus default (value 1 = maximum government action):
--     1 = criminal prohibition (most control)
--     5 = minimal-restriction legalization (least control)
-- Do not "correct" this to a progressive-1 reading; here the deregulatory pole is value 5 by design.
--
-- THE FIVE RUNGS ARE ONE AXIS WITH FOUR REAL THRESHOLDS (not an effort-dial). Each rung is a
-- distinct, recognizable legal model, and each seats real, sourced officials (grounding pass,
-- WebSearch 2026-08-31):
--     1  Keep cannabis fully illegal; enforce criminal penalties.
--          Seats: Idaho / Kansas officials (no medical or recreational); federal Schedule I defenders.
--     1->2  carve out a medical-only exception from blanket prohibition.
--     2  Allow cannabis ONLY for medical use with a physician's authorization (recreational still
--        criminal — this is MORE restrictive on the general user than rung 3, which is why it sits
--        below decriminalization).
--          Seats: the 16 medical-only states — e.g. Texas, Utah; FL Gov. DeSantis opposed the 2024
--          recreational measure while Florida medical use is legal.
--     2->3  stop treating personal possession as a crime for everyone, not just patients.
--     3  Decriminalize personal possession (civil fine, no jail) but keep commercial SALES illegal
--        — no legal market. The "no sales" clause is the load-bearing discriminator that separates
--        this chair from rung 4; it is not an independent second position.
--          Seats: North Carolina (decriminalized small possession since 1977, no legal market);
--          Virginia (possession legalized 2021, retail sales never enacted).
--     3->4  open a legal, licensed, taxed commercial market.
--     4  Legalize recreational cannabis and regulate it through a licensed, taxed commercial market.
--          Seats: Colorado (Amendment 64), Washington (I-502) — 24 recreational states.
--     4->5  strip the market down to minimal restriction (home cultivation, treat like an ordinary
--        product; the fight over home-grow bans and high excise taxes lives here).
--     5  Legalize cannabis and treat it like an ordinary legal product, with minimal restrictions
--        on growing and using it.
--          Seats: full-deschedule / home-cultivation advocates; opponents of home-grow bans.
--
-- ALL LEVELS (federal + state + local), NOT judicial. Each level holds a genuine lever: federal
-- scheduling (Schedule I vs. reschedule to medical vs. deschedule), state legalization /
-- decriminalization statutes and ballot measures, and local decriminalization ordinances,
-- dispensary opt-in/opt-out, and enforcement priority. Judicial is excluded — a judge sets no
-- cannabis-legalization policy.
--
-- HOW IT IS CREATED
-- Through the ADR 0004 revision model, via the prod RPC inform.admin_create_topic_with_revision
-- (CA_0026, applied 2026-08-28), which writes all five layers atomically — identity row, legacy
-- 1..5 ladder (5:5 parity), a founding v1 revision (revision=1, version=1,
-- change_class='substantive', status='published', is_current=true, rung_map=NULL), the five stance
-- revisions, and the role scopes. The legacy admin_create_topic_with_stances RPC is INSUFFICIENT
-- (writes no revision, so the season read path cannot see or pin the topic).
--
-- THEN PINNED into Season 2 (draft) via inform.admin_season_add_topic, which pins the topic's
-- current published v1 revision. is_live stays false and the topic is NOT promoted — a draft season
-- promotes nothing, so this changes NO voter surface today. It goes live only when Season 2 OPENS
-- (inform.admin_open_season) — a separate, later step. Season 1 (open) is untouched.
--
-- IDEMPOTENT: the create runs only when topic_key 'cannabis-policy' is absent; the pin is guarded by
-- a season_questions existence check (admin_season_add_topic itself raises ALREADY_IN_SEASON on a
-- duplicate). A re-run is a no-op. The post-verify gate asserts the full shape either way.
-- To revert: remove the Season 2 season_questions row, then delete the topic row (its
-- revisions/stances/roles cascade). No pre-existing object is altered.
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Create the topic (guarded so a re-run does not hit DUPLICATE_TOPIC_KEY).
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_topics WHERE topic_key = 'cannabis-policy'
  ) THEN
    PERFORM inform.admin_create_topic_with_revision(
      'Cannabis Policy',                                   -- p_title
      'How should the government regulate cannabis?',      -- p_question_text
      'Cannabis Policy',                                   -- p_short_title -> topic_key 'cannabis-policy'
      false,                                               -- p_is_live (staged)
      '[
        {"value":1,"text":"Keep cannabis fully illegal and enforce criminal penalties for possessing or selling it."},
        {"value":2,"text":"Allow cannabis only for medical use, available to patients with a physician''s authorization."},
        {"value":3,"text":"Remove criminal penalties for personal possession, replacing them with civil fines, but keep commercial sales illegal."},
        {"value":4,"text":"Legalize recreational cannabis and regulate it through a licensed, taxed commercial market."},
        {"value":5,"text":"Legalize cannabis and treat it like an ordinary legal product, with minimal restrictions on growing and using it."}
      ]'::jsonb,                                           -- p_stances
      '854fbc06-40fc-458d-b523-20ef8e5ad1b2',              -- p_actor_id (Chris Andrews)
      '["federal","state","local"]'::jsonb                 -- p_role_scopes (all levels; no judicial)
    );
    RAISE NOTICE 'CA_0083: created topic cannabis-policy';
  ELSE
    RAISE NOTICE 'CA_0083: topic cannabis-policy already present — create skipped';
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 2. Pin into Season 2 (draft). Serves nothing until the season opens.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_actor  CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';   -- Chris Andrews
  v_season CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';   -- Season 2 (draft)
  v_topic  uuid;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0083: Season 2 is not a draft — question set is frozen, refusing to pin';
  END IF;

  SELECT id INTO v_topic FROM inform.compass_topics WHERE topic_key = 'cannabis-policy';
  IF v_topic IS NULL THEN
    RAISE EXCEPTION 'CA_0083: topic cannabis-policy is missing after create';
  END IF;

  IF EXISTS (SELECT 1 FROM inform.season_questions WHERE season_id = v_season AND topic_id = v_topic) THEN
    RAISE NOTICE 'CA_0083: cannabis-policy already in Season 2 — pin skipped';
  ELSE
    PERFORM inform.admin_season_add_topic(v_season, v_topic, v_actor);
    RAISE NOTICE 'CA_0083: pinned cannabis-policy to Season 2';
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 3. Post-verify gate. Asserts the created shape AND the Season 2 pin.
--    A wrong count RAISEs and aborts the whole transaction (nothing partial commits).
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_season CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_topic uuid;
  v_n     int;
  v_t1    text;
  v_t5    text;
BEGIN
  SELECT id INTO v_topic FROM inform.compass_topics WHERE topic_key = 'cannabis-policy';
  IF v_topic IS NULL THEN
    RAISE EXCEPTION 'CA_0083: topic cannabis-policy is missing after create';
  END IF;

  -- exactly one published/current v1 substantive revision, rung_map NULL
  SELECT count(*) INTO v_n FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic AND is_current AND status = 'published'
     AND revision = 1 AND version = 1 AND change_class = 'substantive'
     AND rung_map IS NULL;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0083: expected 1 published/current v1 substantive revision (rung_map NULL), got %', v_n;
  END IF;

  -- five distinct stance-revision values on the current revision
  SELECT count(DISTINCT sr.value) INTO v_n
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current;
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CA_0083: expected 5 stance revisions, got %', v_n;
  END IF;

  -- five legacy stances (corpus 5:5 invariant)
  SELECT count(*) INTO v_n FROM inform.compass_stances WHERE topic_id = v_topic;
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CA_0083: expected 5 legacy stances, got %', v_n;
  END IF;

  -- exactly the three requested role rows: federal, state, local (never judicial)
  SELECT count(*) INTO v_n FROM inform.compass_topic_roles WHERE topic_id = v_topic;
  IF v_n <> 3 THEN
    RAISE EXCEPTION 'CA_0083: expected exactly 3 role rows, got %', v_n;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'federal')
     OR NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'state')
     OR NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'local') THEN
    RAISE EXCEPTION 'CA_0083: expected federal + state + local role rows';
  END IF;
  IF EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'judicial') THEN
    RAISE EXCEPTION 'CA_0083: unexpected judicial role row';
  END IF;

  -- polarity guard: value 1 is the prohibition pole, value 5 the legalization pole.
  -- Catches an accidental ladder inversion at author time.
  SELECT sr.text INTO v_t1
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current AND sr.value = 1;
  SELECT sr.text INTO v_t5
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current AND sr.value = 5;
  IF v_t1 NOT ILIKE '%illegal%' OR v_t5 NOT ILIKE '%legalize%' THEN
    RAISE EXCEPTION 'CA_0083: polarity check failed (v1=%, v5=%)', v_t1, v_t5;
  END IF;

  -- pinned into Season 2, to the current published revision
  IF NOT EXISTS (
    SELECT 1 FROM inform.season_questions sq
    JOIN inform.compass_topic_revisions r ON r.id = sq.topic_revision_id
    WHERE sq.season_id = v_season AND sq.topic_id = v_topic
      AND r.is_current AND r.status = 'published'
  ) THEN
    RAISE EXCEPTION 'CA_0083: cannabis-policy is not pinned to Season 2 at its current published revision';
  END IF;

  -- still staged: is_live=false and NOT promoted (draft season promotes nothing)
  IF (SELECT is_live FROM inform.compass_topics WHERE id = v_topic) THEN
    RAISE EXCEPTION 'CA_0083: cannabis-policy is_live=true (must stay staged until Season 2 opens)';
  END IF;
  IF EXISTS (SELECT 1 FROM inform.compass_topics_promoted WHERE id = v_topic) THEN
    RAISE EXCEPTION 'CA_0083: cannabis-policy leaked into an open season before Season 2 opened';
  END IF;

  RAISE NOTICE 'CA_0083 OK — cannabis-policy staged (1 published/current v1, 5 rungs, 5 legacy stances, 3 roles federal+state+local, polarity 1=illegal/5=legalize), pinned to Season 2 (draft), unpromoted. Goes live when Season 2 opens.';
END $$;

COMMIT;
