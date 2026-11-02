BEGIN;

-- =============================================================================
-- CA_0343: a Focused Community for every Season 2 Compass question
-- =============================================================================
-- Created 2026-10-31 with Chris Andrews.
--
-- WHAT THIS DOES
-- Creates the 17 Focused Communities that Season 2 questions were missing, and
-- records each one's slug back on its Compass topic so the two stay in step.
--
-- WHY IT EXISTS
-- Season 2 carries 60 topics. 43 had a community; 17 did not, and the 17 were
-- exactly the topics new in Season 2 — no Season 1 topic ever lost its community.
--
-- 🔴 THIS DELIBERATELY BREAKS AN EXISTING INVARIANT. Read before re-running.
-- Before this migration the rule was exact, in both directions:
--     is_live = true   -> 44 topics, 44 with a community
--     is_live = false  -> 20 topics,  0 with a community
-- and inform.compass_topics.fc_community_slug was populated on exactly those 44,
-- matching connect.communities.slug in all 44 cases. A Focused Community was not
-- something created alongside a question; it was a consequence of the Compass
-- PUBLISHING one.
--
-- All 17 topics here are is_live = false. Chris chose on 2026-10-31 to create the
-- communities ahead of the Compass rather than wait, knowing the cost: the argument
-- tree (CA_0342) is permanent across seasons by design, so claims written against
-- these questions now are rooted in wording the Compass has not shipped and could
-- still revise. That is the drift the seasons feature exists to make visible, and
-- it is a product call, not a technical one.
--
-- This migration does NOT flip is_live. Publishing the topics in the Compass stays
-- a separate, deliberate act.
--
-- WHAT IT DOES NOT INVENT
-- name    is the Compass topic's own title, verbatim.
-- slug    is the Compass topic's own topic_key, verbatim. Verified distinct across
--         all 17 and free of any collision with connect.communities.slug or any
--         entry in slug_history.
-- description is left NULL. Every existing community has editorial copy in Chris's
--         voice; none is invented here. The column is nullable and the directory
--         must tolerate it. Fill them editorially.
--
-- WHAT HAPPENS AUTOMATICALLY
-- CA_0342 §7a put an AFTER INSERT trigger on connect.communities that seeds each
-- new community its argument-tree root claim. These 17 arrive complete: no
-- backfill, no second migration, and the §9 gate below proves it row by row.
--
-- There is no migration runner (see CLAUDE.md): this file documents the change and
-- lets a DB rebuild re-apply it. Idempotent — safe to re-run.
-- =============================================================================

-- 0. Preconditions. This migration assumes CA_0342 has run.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'connect' AND c.relname = 'communities'
      AND t.tgname = 'trg_communities_seed_root_claim' AND NOT t.tgisinternal
  ) THEN
    RAISE EXCEPTION 'CA_0343: trg_communities_seed_root_claim is missing — run CA_0342 first, or these communities would be created without argument-tree roots';
  END IF;
END $$;

-- 1. The 17 communities. Guarded so a re-run is a no-op; the UNIQUE on slug and
--    the one-community-per-topic reality would both reject a duplicate anyway.
INSERT INTO connect.communities (topic_id, slug, name)
SELECT t.id, t.topic_key, t.title
FROM inform.compass_topics t
JOIN inform.season_questions sq ON sq.topic_id = t.id
JOIN inform.seasons s ON s.id = sq.season_id AND s.number = 2
WHERE NOT EXISTS (SELECT 1 FROM connect.communities c WHERE c.topic_id = t.id);

-- 2. Keep the Compass's own pointer in step. Every one of the 44 pre-existing
--    communities is named by its topic's fc_community_slug; leaving these 17 null
--    would make the column mean "live topics only" instead of "topics with a
--    community", which is not what the other 44 rows say it means.
UPDATE inform.compass_topics t
   SET fc_community_slug = c.slug
  FROM connect.communities c
 WHERE c.topic_id = t.id
   AND t.fc_community_slug IS DISTINCT FROM c.slug;

-- 3. Post-verify gate — fail loudly if this migration did not achieve what it claims.
DO $$
DECLARE
  v_s2_total    INT;
  v_s2_missing  INT;
  v_communities INT;
  v_roots       INT;
  v_rootless    INT;
  v_slug_gaps   INT;
  v_blank       INT;
BEGIN
  -- a. Every Season 2 topic now has a community.
  SELECT count(*) INTO v_s2_total
  FROM inform.season_questions sq JOIN inform.seasons s ON s.id = sq.season_id AND s.number = 2;

  SELECT count(*) INTO v_s2_missing
  FROM inform.season_questions sq
  JOIN inform.seasons s ON s.id = sq.season_id AND s.number = 2
  WHERE NOT EXISTS (SELECT 1 FROM connect.communities c WHERE c.topic_id = sq.topic_id);

  IF v_s2_missing <> 0 THEN
    RAISE EXCEPTION 'CA_0343: % of % Season 2 topics still have no Focused Community', v_s2_missing, v_s2_total;
  END IF;

  -- b. Every community has exactly one root claim — the trigger did its work for
  --    the new rows, and nothing disturbed the existing ones.
  SELECT count(*) INTO v_communities FROM connect.communities;
  SELECT count(*) INTO v_roots FROM connect.claims WHERE parent_claim_id IS NULL;
  IF v_roots <> v_communities THEN
    RAISE EXCEPTION 'CA_0343: % root claims for % communities — expected one each', v_roots, v_communities;
  END IF;

  SELECT count(*) INTO v_rootless
  FROM connect.communities c
  WHERE NOT EXISTS (SELECT 1 FROM connect.claims k WHERE k.community_id = c.id AND k.parent_claim_id IS NULL);
  IF v_rootless <> 0 THEN
    RAISE EXCEPTION 'CA_0343: % communities have no root claim', v_rootless;
  END IF;

  -- c. Each new root carries its community's name as its body, and no author.
  SELECT count(*) INTO v_blank
  FROM connect.communities c
  JOIN connect.claims k ON k.community_id = c.id AND k.parent_claim_id IS NULL
  WHERE k.body IS DISTINCT FROM c.name
     OR k.author_id IS NOT NULL
     OR k.author_display_name IS NOT NULL
     OR k.side IS NOT NULL
     OR k.depth <> 0
     OR cardinality(k.path) <> 0;
  IF v_blank <> 0 THEN
    RAISE EXCEPTION 'CA_0343: % root claims are not shaped like roots of their community', v_blank;
  END IF;

  -- d. The Compass pointer matches, for every community without exception.
  SELECT count(*) INTO v_slug_gaps
  FROM connect.communities c
  JOIN inform.compass_topics t ON t.id = c.topic_id
  WHERE t.fc_community_slug IS DISTINCT FROM c.slug;
  IF v_slug_gaps <> 0 THEN
    RAISE EXCEPTION 'CA_0343: % topics disagree with their community slug', v_slug_gaps;
  END IF;

  RAISE NOTICE 'CA_0343 OK — % communities, all % Season 2 topics covered, % root claims seeded by trigger, fc_community_slug in step.',
    v_communities, v_s2_total, v_roots;
END $$;

COMMIT;
