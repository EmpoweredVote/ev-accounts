BEGIN;

-- ✅ APPLIED TO PRODUCTION 2026-08-29. Dry-run first (BEGIN…ROLLBACK): post-verify
-- gate passed; topic created with a published, is_current v1 revision (rung_map
-- NULL), 5 rungs, one federal role row, 5 legacy stances, and NOT promoted (no
-- season pins it). Then applied for real; verified border-security has one
-- published/current v1 revision with 5 rungs, is_live=false.

-- =============================================================================
-- CA_0025: New federal compass topic — "Border Security"
-- =============================================================================
-- Created 2026-08-29 with Chris Andrews from a research-grounded design pass.
-- Splits the border/asylum axis out of the immigration space: this topic owns
-- "what happens at a crossing / asylum claim." Legal-immigration LEVELS were
-- deliberately deferred (a magnitude dial, decision pending Season 2); Deportation
-- and Local Immigration Enforcement remain their own topics; benefits/services
-- and family-vs-skills composition are left as possible future topics.
--
-- The axis orders on the asylum/enforcement response — a fair hearing for all
-- (repeal of 8 U.S.C. §1325) → seal the border (2025 proclamation). Each rung
-- seats real legislation. "Open borders" is a strawman and is deliberately NOT
-- the left pole; the left pole is "civil, not criminal — a hearing for everyone."
--
-- Creation follows the revision model (ADR 0004): a topic is not just its legacy
-- compass_stances row — it needs a published, is_current compass_topic_revisions
-- v1 (rung_map NULL, no prior ladder), which is what the Option Y season read
-- path (ADR 0006) and the CA_0022 season-composition RPCs require to pin it.
-- The legacy public.admin_create_topic_with_stances RPC predates all of this and
-- creates no revision, so this migration writes every layer directly, mirroring
-- the CA_0012 backfill.
--
-- is_live = false: staged, not launched. It appears on NO voter surface — Season 1
-- does not list it in season_questions, and the promoted view is season-gated, not
-- is_live-gated. It goes live only when Season 2 pins it (admin_season_add_topic)
-- and opens. is_live does not gate season display, so false is the honest choice.
-- =============================================================================

DO $$
DECLARE
  v_topic UUID;
  v_rev   UUID;
BEGIN
  IF EXISTS (SELECT 1 FROM inform.compass_topics WHERE topic_key = 'border-security') THEN
    RAISE NOTICE 'CA_0025: border-security already exists — skipping creation';
    RETURN;
  END IF;

  -- (a) Identity row. topic_key set explicitly (the derive trigger would produce
  --     the same value from short_title, and leaves an explicit value untouched).
  INSERT INTO inform.compass_topics
    (title, short_title, question_text, is_live, went_live_at, topic_key)
  VALUES
    ('Border Security', 'Border Security',
     'How should the government handle people who cross the border?',
     false, NULL, 'border-security')
  RETURNING id INTO v_topic;

  -- (b) Legacy ladder — parity with the corpus 5:5 invariant. NOT read by the
  --     season path (voters read compass_stance_revisions under Option Y); kept so
  --     legacy/admin readers see a full ladder.
  INSERT INTO inform.compass_stances (topic_id, value, text) VALUES
    (v_topic, 1, 'Give everyone who crosses the border a fair asylum hearing.'),
    (v_topic, 2, 'Expand orderly, legal ways to seek asylum at the border.'),
    (v_topic, 3, 'Combine strong enforcement with a faster asylum process.'),
    (v_topic, 4, 'Sharply restrict who can claim asylum at the border.'),
    (v_topic, 5, 'End asylum and quickly turn back anyone who crosses illegally.');

  -- (c) v1 topic revision — founding content: published + current, rung_map NULL.
  INSERT INTO inform.compass_topic_revisions
    (topic_id, revision, version, change_class,
     title, short_title, question_text,
     rationale, public_note, rung_map,
     status, is_current,
     proposed_by, proposed_at, approved_by, approved_at, published_by, published_at)
  VALUES
    (v_topic, 1, 1, 'substantive',
     'Border Security', 'Border Security',
     'How should the government handle people who cross the border?',
     'Founding revision for a new federal compass topic (ADR 0004). Border/asylum axis split out of the immigration space via a research-grounded design pass (2026-08-29, Chris Andrews). Axis: the government''s response to a crossing/asylum claim, from a fair hearing for all (repeal §1325) to sealing the border (2025 proclamation); each rung seats real legislation. Left pole is civil-not-criminal, not the "open borders" strawman.',
     'First published version of this topic.',
     NULL,
     'published', true,
     NULL, now(), NULL, NULL, NULL, now())
  RETURNING id INTO v_rev;

  -- (d) The 5 rungs of that revision (the voter-facing ladder under Option Y).
  INSERT INTO inform.compass_stance_revisions
    (topic_revision_id, value, text, description, supporting_points, example_perspectives)
  VALUES
    (v_rev, 1, 'Give everyone who crosses the border a fair asylum hearing.',            NULL, '{}', '{}'),
    (v_rev, 2, 'Expand orderly, legal ways to seek asylum at the border.',               NULL, '{}', '{}'),
    (v_rev, 3, 'Combine strong enforcement with a faster asylum process.',               NULL, '{}', '{}'),
    (v_rev, 4, 'Sharply restrict who can claim asylum at the border.',                   NULL, '{}', '{}'),
    (v_rev, 5, 'End asylum and quickly turn back anyone who crosses illegally.',         NULL, '{}', '{}');

  -- (e) Federal-only scope. A single 'federal' row flips applies_state/local to
  --     false (absence would default the topic to all three tiers).
  INSERT INTO inform.compass_topic_roles (topic_id, role_scope, is_required)
  VALUES (v_topic, 'federal', true);

  RAISE NOTICE 'CA_0025: created border-security topic % (revision %)', v_topic, v_rev;
END $$;

-- ---------------------------------------------------------------------------
-- Post-verify gate
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_topic UUID;
  v_n     INT;
BEGIN
  SELECT id INTO v_topic FROM inform.compass_topics WHERE topic_key = 'border-security';
  IF v_topic IS NULL THEN
    RAISE EXCEPTION 'CA_0025: border-security topic missing';
  END IF;

  -- exactly one published, current revision
  SELECT count(*) INTO v_n FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic AND is_current AND status = 'published';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0025: expected exactly 1 published/current revision, got %', v_n;
  END IF;

  -- exactly 5 stance revisions, values 1..5
  SELECT count(DISTINCT sr.value) INTO v_n
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current;
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CA_0025: expected 5 distinct stance-revision values, got %', v_n;
  END IF;

  -- exactly 5 legacy stances (corpus 5:5 invariant)
  SELECT count(*) INTO v_n FROM inform.compass_stances WHERE topic_id = v_topic;
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CA_0025: expected 5 legacy stances, got %', v_n;
  END IF;

  -- exactly one federal role row, nothing else
  SELECT count(*) INTO v_n FROM inform.compass_topic_roles WHERE topic_id = v_topic;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0025: expected exactly 1 role row, got %', v_n;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles
                  WHERE topic_id = v_topic AND role_scope = 'federal') THEN
    RAISE EXCEPTION 'CA_0025: federal role row missing';
  END IF;

  -- must NOT appear on any voter surface yet (no season pins it)
  IF EXISTS (SELECT 1 FROM inform.compass_topics_promoted WHERE id = v_topic) THEN
    RAISE EXCEPTION 'CA_0025: border-security is promoted (in an open season) — it must not be until Season 2 pins it';
  END IF;

  RAISE NOTICE 'CA_0025 OK — border-security: 1 published/current v1 revision, 5 rungs, federal-only, not promoted';
END $$;

COMMIT;
