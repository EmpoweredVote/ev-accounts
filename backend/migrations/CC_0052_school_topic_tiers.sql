BEGIN;

-- =============================================================================
-- CC_0052: tier-scope the eight school-board topics to local + state
-- =============================================================================
-- Created 2026-09-02 with Chris Cantrell, before Season 2 opens.
--
-- THE BUG. The eight school topics added for Season 2 have NO rows in
-- inform.compass_topic_roles, and getCompassTopics reads an empty role set as
-- "cross-cutting":
--
--     const hasAnyRoleRows = topicRoles.length > 0;
--     applies_federal = hasAnyRoleRows ? ... : true;     // <- the default
--     applies_state   = hasAnyRoleRows ? ... : true;
--     applies_local   = hasAnyRoleRows ? ... : true;
--     applies_judicial = hasAnyRoleRows ? ... : false;
--
-- So today "Charter Schools" and "Police in Schools" are marked as applying to
-- FEDERAL offices — a U.S. House member's profile offers them. That is wrong on
-- its face, and it is worse than cosmetic now: research starts the moment
-- Season 2 opens, and an answer seated against the wrong office is expensive to
-- unwind once Season 1 is closed and CC_0044's immutability trigger is armed.
--
-- WHAT THIS DOES. Gives all eight `local` and `state` rows, which by the logic
-- above turns federal OFF (a topic with any rows is scoped to exactly those it
-- names) and leaves judicial off as it already is.
--   - `local`  — school boards are local offices. 777 seated members, 167
--                districts.
--   - `state`  — state boards of education are state offices (24 seated: the DC
--                SBOE and the Utah State Board), and state legislatures write
--                charter, curriculum and library-materials law directly.
--
-- 🔴 WHAT THIS CANNOT DO, AND WHY THE LENS STILL MATTERS. `role_scope` is
-- CHECK-constrained to exactly federal|state|local|judicial:
--
--     chk_role_scope_tier CHECK (role_scope IN ('federal','state','local','judicial'))
--
-- There is no SCHOOL tier and there cannot be one without changing that
-- constraint. So this migration CANNOT say "school boards only" — `local` also
-- means mayors and city councils, and `state` also means governors and
-- legislators. Precise district-level targeting lives in a different mechanism
-- entirely: inform.compass_lenses.auto_district_types, where the Education Lens
-- already carries {SCHOOL, STATE_BOARD_EDUCATION}. That is the one that gets
-- school boards exactly right; this one only stops the federal nonsense.
--
-- Do not "fix" the coarseness here by widening the CHECK. The tier flags feed
-- profile display across the whole product; the lens is the per-office tool.
--
-- is_required defaults to true and is left at the default, matching all 107
-- existing rows.
--
-- SAFE TO RE-RUN — ON CONFLICT DO NOTHING against the (topic_id, role_scope)
-- primary key.
-- =============================================================================

INSERT INTO inform.compass_topic_roles (topic_id, role_scope)
SELECT t.id, s.scope
  FROM inform.compass_topics t
  CROSS JOIN (VALUES ('local'), ('state')) AS s(scope)
 WHERE t.title IN (
   'Artificial Intelligence in Schools',
   'Charter Schools',
   'Curriculum and Contested Topics',
   'Equity and Inclusion Programs in Schools',
   'Parental Notification and Transgender Students',
   'Police in Schools',
   'School Budget and Spending Priorities',
   'School Library Books and Instructional Materials'
 )
ON CONFLICT (topic_id, role_scope) DO NOTHING;


DO $$
DECLARE
  v_titles text[] := ARRAY[
    'Artificial Intelligence in Schools','Charter Schools','Curriculum and Contested Topics',
    'Equity and Inclusion Programs in Schools','Parental Notification and Transgender Students',
    'Police in Schools','School Budget and Spending Priorities',
    'School Library Books and Instructional Materials'];
  v_topics    int;
  v_bad       text;
BEGIN
  SELECT count(*) INTO v_topics
    FROM inform.compass_topics WHERE title = ANY(v_titles);
  IF v_topics <> 8 THEN
    RAISE EXCEPTION 'CC_0052: matched % topics by title, expected 8 — a title changed', v_topics;
  END IF;

  -- Every one of the eight must now hold exactly local + state, and nothing else.
  SELECT string_agg(x.title || ' -> ' || x.scopes, '; ')
    INTO v_bad
    FROM (
      SELECT t.title,
             coalesce(string_agg(r.role_scope, ',' ORDER BY r.role_scope), '(none)') AS scopes
        FROM inform.compass_topics t
        LEFT JOIN inform.compass_topic_roles r ON r.topic_id = t.id
       WHERE t.title = ANY(v_titles)
       GROUP BY t.title
    ) x
   WHERE x.scopes <> 'local,state';

  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0052: these are not scoped local+state: %', v_bad;
  END IF;

  -- The whole point: none of them is federal any more.
  IF EXISTS (
    SELECT 1 FROM inform.compass_topics t
      JOIN inform.compass_topic_roles r ON r.topic_id = t.id
     WHERE t.title = ANY(v_titles) AND r.role_scope = 'federal'
  ) THEN
    RAISE EXCEPTION 'CC_0052: a school topic still carries the federal scope';
  END IF;

  RAISE NOTICE 'CC_0052 OK: 8 school topics scoped local+state; federal default removed.';
END $$;

COMMIT;
