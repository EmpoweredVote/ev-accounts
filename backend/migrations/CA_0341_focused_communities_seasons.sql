BEGIN;

-- =============================================================================
-- CA_0341: season-aware read RPCs for the Focused Communities module
--          (connect.get_season_list / get_season_detail / get_season_chairs)
-- =============================================================================
-- Created 2026-10-31 with Chris Andrews.
--
-- 🔴 RENUMBERED FROM CA_0340 ON 2026-11-01, AND THE DATABASE STILL SAYS CA_0340.
-- This file took slot 340 without reserving it. The LegiScan governor-signing lane then
-- reserved 340 properly (steward, 2026-10-31 21:02) and landed
-- CA_0340_braun_governor_term_start.sql on master, so two files held one slot and CI caught it.
-- This is the newer claim on the slot, so this is the file that moved.
--
-- It was already applied to production under the name ca_0340_focused_communities_seasons at
-- 2026-10-31 17:23, and supabase_migrations.schema_migrations still records that name. Nothing
-- is broken by the difference: apply ORDER is the timestamped version column, not the filename,
-- and re-running this file is a no-op. But if you are matching files to applied rows, this is
-- the one pair whose names do not match, and this paragraph is why.
--
-- WHAT THIS DOES
-- Adds three read-only functions in the connect schema, intended for
-- focused_communities_app (CA_0323; see SAFETY for who else can call them), that return a Compass topic as it stood in a
-- given season:
--   get_season_list(p_topic_id, p_include_drafts)
--       the seasons a topic appears in (number, name, status, opened/closed).
--   get_season_detail(p_topic_id, p_season_number, p_include_drafts)
--       the topic revision pinned to that season: question, change class, season
--       note, topic note, rationale and rung_map.
--   get_season_chairs(p_topic_id, p_season_number, p_include_drafts)
--       the stance ("chair") texts of that revision, in value order.
--
-- WHY RPCs, AND WHY SECURITY DEFINER
-- The module's role has no access to the inform schema at all — and must not
-- (inform holds editorial workflow data: proposers, approvers, review refs, drafts).
-- These functions are the only door: they run with the owner's rights, expose a fixed
-- set of columns, and filter out draft seasons unless the caller asks for them.
-- Same pattern as connect.get_stances_for_community.
--
-- SAFETY
--   * Each function pins its own search_path (connect, inform, pg_temp). A SECURITY
--     DEFINER function without one is a privilege-escalation hole, and these reach
--     across a security boundary.
--   * REVOKE ALL ... FROM PUBLIC removes PUBLIC's EXECUTE; the GRANT then makes
--     focused_communities_app the only module-level caller. service_role keeps EXECUTE
--     through the connect schema's default ACL, exactly as it does for
--     get_stances_for_community. anon and authenticated get nothing.
--   * get_season_chairs returns `ordinal` (1-based, by value ascending) and NEVER the
--     raw `value`. A chair's 1-5 number is never shown to users; ordinal exists only
--     so the server can join a chair to the revision's rung_map.
--   * Timestamps are returned as text via to_json(col) #>> '{}' — the Node pg driver
--     truncates timestamptz to milliseconds, which breaks cursors downstream.
--   * Enum columns (seasons.status, compass_topic_revisions.change_class) are cast
--     ::text to satisfy the declared return types.
--
-- Idempotent — safe to re-run. There is no migration runner (see CLAUDE.md).
-- =============================================================================

-- 1. Seasons a topic appears in.
CREATE OR REPLACE FUNCTION connect.get_season_list(p_topic_id uuid, p_include_drafts boolean)
RETURNS TABLE(season_number int, season_name text, status text, opened_at text, closed_at text)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO 'connect', 'inform', 'pg_temp'
AS $fn$
  SELECT s.number,
         s.name,
         s.status::text,
         to_json(s.opened_at) #>> '{}',
         to_json(s.closed_at) #>> '{}'
  FROM inform.season_questions sq
  JOIN inform.seasons s ON s.id = sq.season_id
  WHERE sq.topic_id = p_topic_id
    AND (p_include_drafts OR s.status::text <> 'draft')
  ORDER BY s.number;
$fn$;

-- 2. The topic revision pinned to one season. Zero rows if absent, or draft and not permitted.
CREATE OR REPLACE FUNCTION connect.get_season_detail(p_topic_id uuid, p_season_number int, p_include_drafts boolean)
RETURNS TABLE(season_number int, season_name text, status text, question_text text, change_class text,
              season_note text, topic_note text, rationale text, rung_map jsonb)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO 'connect', 'inform', 'pg_temp'
AS $fn$
  SELECT s.number,
         s.name,
         s.status::text,
         r.question_text,
         r.change_class::text,
         s.public_note,
         r.public_note,
         r.rationale,
         r.rung_map
  FROM inform.season_questions sq
  JOIN inform.seasons s ON s.id = sq.season_id
  JOIN inform.compass_topic_revisions r ON r.id = sq.topic_revision_id
  WHERE sq.topic_id = p_topic_id
    AND s.number = p_season_number
    AND (p_include_drafts OR s.status::text <> 'draft');
$fn$;

-- 3. The stance texts of that revision. ordinal is NOT the stance value (see header).
CREATE OR REPLACE FUNCTION connect.get_season_chairs(p_topic_id uuid, p_season_number int, p_include_drafts boolean)
RETURNS TABLE(ordinal int, text text, description text, supporting_points text[], example_perspectives text[])
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO 'connect', 'inform', 'pg_temp'
AS $fn$
  SELECT (row_number() OVER (ORDER BY st.value ASC))::int,
         st.text,
         st.description,
         st.supporting_points,
         st.example_perspectives
  FROM inform.season_questions sq
  JOIN inform.seasons s ON s.id = sq.season_id
  JOIN inform.compass_stance_revisions st ON st.topic_revision_id = sq.topic_revision_id
  WHERE sq.topic_id = p_topic_id
    AND s.number = p_season_number
    AND (p_include_drafts OR s.status::text <> 'draft')
  ORDER BY st.value ASC;
$fn$;

-- 4. Grants: the role is the only non-owner caller.
REVOKE ALL ON FUNCTION connect.get_season_list(uuid, boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION connect.get_season_detail(uuid, int, boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION connect.get_season_chairs(uuid, int, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION connect.get_season_list(uuid, boolean) TO focused_communities_app;
GRANT EXECUTE ON FUNCTION connect.get_season_detail(uuid, int, boolean) TO focused_communities_app;
GRANT EXECUTE ON FUNCTION connect.get_season_chairs(uuid, int, boolean) TO focused_communities_app;

-- 5. Post-verify gate.
DO $$
BEGIN
  IF NOT has_function_privilege('focused_communities_app', 'connect.get_season_list(uuid, boolean)', 'EXECUTE') THEN
    RAISE EXCEPTION 'CA_0341: missing EXECUTE on connect.get_season_list(uuid, boolean)';
  END IF;
  IF NOT has_function_privilege('focused_communities_app', 'connect.get_season_detail(uuid, int, boolean)', 'EXECUTE') THEN
    RAISE EXCEPTION 'CA_0341: missing EXECUTE on connect.get_season_detail(uuid, integer, boolean)';
  END IF;
  IF NOT has_function_privilege('focused_communities_app', 'connect.get_season_chairs(uuid, int, boolean)', 'EXECUTE') THEN
    RAISE EXCEPTION 'CA_0341: missing EXECUTE on connect.get_season_chairs(uuid, integer, boolean)';
  END IF;
  IF has_schema_privilege('focused_communities_app', 'inform', 'USAGE') THEN
    RAISE WARNING 'CA_0341: focused_communities_app can USE schema inform — investigate the wall';
  END IF;
  RAISE NOTICE 'CA_0341 OK — season RPCs created (SECURITY DEFINER, search_path pinned), EXECUTE granted to focused_communities_app (PUBLIC revoked).';
END $$;

COMMIT;
