-- 1883_trivia_collections_featured.sql
--
-- Adds `trivia.collections.featured` — the editorial shelf flag behind the CTC Dashboard's
-- "Featured Collections" strip.
--
-- No migration runner exists; this file records SQL applied by hand.
--
-- =============================================================================================
-- WHY A FLAG ORTHOGONAL TO `tier`, AND NOT A NEW TIER
-- =============================================================================================
-- The shelf is EDITORIAL SURFACE, not taxonomy. A collection keeps its real tier and is
-- ADDITIONALLY promoted, so it can be featured for a while and demoted later without ever
-- lying about what it is. Folding "featured" into `tier` would have forced `war-in-iran` to
-- stop being `international` for as long as it was promoted, and would have made demotion a
-- data migration rather than a toggle.
--
-- The strip on the Dashboard is labelled "Featured Collections" TODAY but is really just the
-- first 10 collections sorted tier-then-name. Because `international` sorts last, the events
-- collections this shelf exists to surface can never appear in it. This column is what makes
-- the label true.
--
-- =============================================================================================
-- WHY THREE COLLECTIONS ARE PRE-FLAGGED, INCLUDING TWO NOBODY CAN SEE
-- =============================================================================================
-- `world-news` (393) and `climate-change` (394) were created is_active = false on 2026-09-20 so
-- the nightly pipeline would stop discarding their lanes (it resolves a lane's collection by
-- slug and never reads is_active). They stay invisible to users because the collections API
-- requires is_active = true AND >= 8 playable questions for an international collection.
--
-- Flagging them now means activation is a single is_active flip, with no second trip here and
-- no window where a collection is live but missing from the shelf it was created for.
--
-- `us-news` is deliberately absent: it has no row at all. Both intended US-domestic feeds are
-- unusable (NPR blocks bot access to article bodies as policy; AP sits behind Cloudflare), so
-- the collection is on hold rather than unbuilt-by-oversight.
-- =============================================================================================

ALTER TABLE trivia.collections
  ADD COLUMN IF NOT EXISTS featured boolean NOT NULL DEFAULT false;

UPDATE trivia.collections
   SET featured = true,
       updated_at = NOW()
 WHERE slug IN ('war-in-iran', 'world-news', 'climate-change');

-- Verify: expect exactly the three rows above, war-in-iran the only one is_active.
--   SELECT slug, tier, is_active, featured FROM trivia.collections WHERE featured ORDER BY slug;
