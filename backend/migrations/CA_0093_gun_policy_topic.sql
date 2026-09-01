BEGIN;

-- =============================================================================
-- CA_0093: "Gun Policy" — a new compass topic (revision model)
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews.
--
-- 🔴 SLOT HISTORY: applied to prod 2026-08-31 as CA_0087 (with CA_0088 pin,
-- CA_0089 re-axis). All three were renumbered to CA_0093/CA_0094/CA_0095 the same
-- day to resolve a shared-checkout collision (israel_military_aid took CA_0087,
-- military_intervention CA_0089). The prod objects embed NO migration number, so
-- the applied data is unaffected — EXCEPT the v2 rationale/review_ref prose
-- (written by CA_0095), which still say "CA_0087 founding create": that was this
-- file's slot at apply time. That prose is historical and non-load-bearing.
--
-- WHAT THIS ADDS
-- A new voter-facing compass topic scoring where an official (or a voter) stands
-- on firearm regulation. topic_key is frozen at 'gun-policy'
-- (essentials.quotes joins on it). The live compass had 44 topics and NO
-- firearms topic — the single largest coverage gap for a U.S. voting compass,
-- and a live 2026 midterm issue. No existing topic is a home for it
-- (public-safety-approach and jail-capacity are adjacent but measure other axes).
--
-- AXIS: how far the law restricts civilian firearms. Value 1 = most government
-- action; value 5 = the deregulatory pole. Corpus-default polarity (not reversed).
--
-- ⚠ THIS FOUNDING v1 WAS SUPERSEDED IN THE SAME SESSION BY CA_0095, before the
-- topic ever went public. On review with Chris the five rungs were found to be
-- CUMULATIVE, not mutually exclusive (a voter who bans assault weapons also wants
-- universal checks, so one person sat in several chairs). CA_0095 re-axes the
-- ladder to mutually-exclusive "furthest you would go" chairs and pins THAT into
-- Season 2. This v1 is kept only because a published revision is immutable and
-- cannot be deleted (the legacy compass_stances freeze trigger blocks the
-- cascade). It never reached a voter surface. Read CA_0095 for the live design.
--
-- HOW IT IS CREATED
-- Through the ADR 0004 revision model, via the prod RPC
-- inform.admin_create_topic_with_revision (CA_0026). The RPC writes all five
-- layers atomically — identity row, legacy 1..5 ladder, a founding v1 revision
-- (revision=1, version=1, change_class='substantive', status='published',
-- is_current=true, rung_map=NULL), the five stance revisions, and the role scopes.
--
-- STAGED, NOT LIVE. is_live=false and (initially, CA_0094) pinned into draft
-- Season 2 only. It goes live only when Season 2 OPENS. CA_0095 repins Season 2
-- from this v1 to the re-axed v2.
--
-- IDEMPOTENT: create runs only when topic_key 'gun-policy' is absent.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Create the topic (guarded so a re-run does not hit DUPLICATE_TOPIC_KEY).
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_topics WHERE topic_key = 'gun-policy'
  ) THEN
    PERFORM inform.admin_create_topic_with_revision(
      'Gun Policy',                                                        -- p_title
      'How should the government regulate firearms?',                      -- p_question_text
      'Gun Policy',                                                        -- p_short_title -> topic_key 'gun-policy'
      false,                                                              -- p_is_live (staged)
      '[
        {"value":1,"text":"Ban civilian ownership of semi-automatic assault-style weapons."},
        {"value":2,"text":"Require universal background checks on all gun sales and transfers."},
        {"value":3,"text":"Keep current gun laws and add only limited safeguards such as waiting periods."},
        {"value":4,"text":"Oppose new firearm restrictions and keep existing gun laws unchanged."},
        {"value":5,"text":"Repeal major gun restrictions, including permits required to carry a concealed firearm."}
      ]'::jsonb,                                                          -- p_stances (initial ladder; re-axed by CA_0095)
      NULL,                                                               -- p_actor_id
      '["federal","state","local"]'::jsonb                               -- p_role_scopes (all three set firearm rules)
    );
    RAISE NOTICE 'CA_0093: created topic gun-policy';
  ELSE
    RAISE NOTICE 'CA_0093: topic gun-policy already present — create skipped';
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- Post-verify gate.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_topic uuid;
  v_n     int;
  v_t1    text;
  v_t5    text;
BEGIN
  SELECT id INTO v_topic FROM inform.compass_topics WHERE topic_key = 'gun-policy';
  IF v_topic IS NULL THEN
    RAISE EXCEPTION 'CA_0093: topic gun-policy is missing after create';
  END IF;

  SELECT count(*) INTO v_n FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic AND revision = 1 AND version = 1
     AND change_class = 'substantive' AND rung_map IS NULL;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0093: expected 1 v1 substantive revision (rung_map NULL), got %', v_n;
  END IF;

  SELECT count(DISTINCT sr.value) INTO v_n
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.revision = 1;
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CA_0093: expected 5 stance revisions on v1, got %', v_n;
  END IF;

  SELECT count(*) INTO v_n FROM inform.compass_stances WHERE topic_id = v_topic;
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CA_0093: expected 5 legacy stances, got %', v_n;
  END IF;

  SELECT count(*) INTO v_n FROM inform.compass_topic_roles WHERE topic_id = v_topic;
  IF v_n <> 3 THEN
    RAISE EXCEPTION 'CA_0093: expected exactly 3 role rows, got %', v_n;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'federal')
     OR NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'state')
     OR NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'local') THEN
    RAISE EXCEPTION 'CA_0093: expected federal + state + local role rows';
  END IF;
  IF EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'judicial') THEN
    RAISE EXCEPTION 'CA_0093: unexpected judicial role row';
  END IF;

  -- polarity guard on v1
  SELECT sr.text INTO v_t1
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.revision = 1 AND sr.value = 1;
  SELECT sr.text INTO v_t5
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.revision = 1 AND sr.value = 5;
  IF v_t1 NOT ILIKE '%Ban%' OR v_t5 NOT ILIKE '%Repeal%' THEN
    RAISE EXCEPTION 'CA_0093: polarity check failed (v1=%, v5=%)', v_t1, v_t5;
  END IF;

  RAISE NOTICE 'CA_0093 OK — gun-policy created staged (v1 initial ladder; re-axed by CA_0095)';
END $$;

COMMIT;
