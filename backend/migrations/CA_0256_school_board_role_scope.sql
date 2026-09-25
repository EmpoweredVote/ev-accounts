BEGIN;

-- =============================================================================
-- CA_0256: a `school` role_scope level for K-12 school boards — the Education Lens
-- =============================================================================
-- Created 2026-09-24 for Chris Andrews (slot reserved from the steward:
-- `steward slot CA --purpose "school role_scope level for the Education Lens ..."`).
--
-- THE RULINGS THIS CARRIES OUT (Chris Andrews):
--   2026-09-23  School boards are in scope for stance research WITH AN EDUCATION
--               LENS ONLY: a `school` level, whose topics are chosen rung by rung
--               and approved by the operator.
--   2026-09-24  The approved topic set is EXACTLY the eight open-season
--               `education-*` topics (the live Education Lens). `school-vouchers`
--               is EXCLUDED. The school-board badge condition in the program spec
--               (L644-648) is lifted: research starts now, and the Education Lens
--               is enough for display. The level covers K-12 boards only;
--               community-college trustee boards stay out (enforced in code, see
--               below). STATE_BOARD_EDUCATION offices stay at `state`.
--
-- THE EVIDENCE FOR THE TOPIC SET: the per-rung review in
--   .superpowers/sdd/2026-09-23-stance-program-reconciliation/school-scope-proposal.md
-- §3 reads every rung of the pinned ladder of each topic and asks CLAUDE.md's
-- question — does a school board hold a lever on this rung? On each of the eight
-- `education-*` topics a board can act on every rung in at least some states
-- (policy, budget, levy/referendum resolution, contract, materials adoption, or a
-- vote on a charter petition). `school-vouchers` fails all five rungs: vouchers
-- are a state program and a board can only pass a resolution about them. The
-- seven Season 1 rows that seat school-board members on vouchers (proposal
-- §3.9) are closed-season history and are NOT touched here.
--
-- WHY THE CHECK IS WIDENED, AGAINST CC_0052's NOTE. CC_0052 said "do not fix the
-- coarseness here by widening the CHECK" — at that time there was no ruling that
-- school boards take a different topic set from mayors and councils. The
-- 2026-09-23 ruling is that ruling: `local` means city/county/township offices,
-- and a school board now has its own level. Nothing else in the tier model
-- changes.
--
-- WHAT THIS DOES:
--   1. chk_role_scope_tier gains 'school' (federal|state|local|judicial|school).
--   2. One compass_topic_roles row (topic_id, 'school') for each of the eight
--      topics, looked up by topic_key. is_required is left at its default (true),
--      matching the existing `local` and `state` rows on these topics.
--   3. REMOVES NOTHING. The existing `local` and `state` rows on these eight
--      topics stay as they are; what `local` should carry once school boards
--      leave it is the proposal's open Q4, for a later ruling.
--
-- READ-SIDE CONTRACT (backend/src/lib/topicApplicability.ts, same change):
--   a topic with NO role rows does NOT apply at `school` — unlike federal, state
--   and local, where an empty role set means cross-cutting. So only topics with
--   an explicit `school` row reach a school board, and today that is these eight.
--   levelForDistrict maps SCHOOL -> 'school', except a community-college board
--   (district label matches /community college/i, proposal §5: no column marks
--   them), which maps to null — level unknown, never a guess.
--
-- KNOWN GAP, NOT FIXED HERE: inform.admin_create_topic_with_revision still
-- validates p_role_scopes against federal|state|local|judicial, so the admin
-- create path cannot scope a NEW topic to `school`. No new topic needs it today.
--
-- SAFE TO RE-RUN: DROP CONSTRAINT IF EXISTS + ADD, and ON CONFLICT DO NOTHING
-- against the (topic_id, role_scope) primary key. The post-verify gate below
-- RAISEs on any wrong count, so a failed run rolls the whole transaction back.
-- =============================================================================

-- Snapshot every existing (non-school) row, so the gate can prove none was removed.
CREATE TEMP TABLE _ca0256_before ON COMMIT DROP AS
SELECT topic_id, role_scope, is_required
  FROM inform.compass_topic_roles
 WHERE role_scope <> 'school';

-- 1. Widen the tier CHECK.
ALTER TABLE inform.compass_topic_roles
  DROP CONSTRAINT IF EXISTS chk_role_scope_tier;

ALTER TABLE inform.compass_topic_roles
  ADD CONSTRAINT chk_role_scope_tier
  CHECK (role_scope IN ('federal', 'state', 'local', 'judicial', 'school'));

-- 2. The eight Education Lens topics, by key. school-vouchers is deliberately absent.
DO $$
DECLARE
  v_found int;
BEGIN
  SELECT count(*) INTO v_found
    FROM inform.compass_topics
   WHERE topic_key IN (
     'education-ai', 'education-charter-authorization', 'education-curriculum',
     'education-equity-programs', 'education-gender-identity', 'education-library-books',
     'education-school-budget', 'education-school-police');
  IF v_found <> 8 THEN
    RAISE EXCEPTION 'CA_0256 pre-check: expected 8 education-* topics by key, found %', v_found;
  END IF;
END $$;

INSERT INTO inform.compass_topic_roles (topic_id, role_scope)
SELECT t.id, 'school'
  FROM inform.compass_topics t
 WHERE t.topic_key IN (
   'education-ai', 'education-charter-authorization', 'education-curriculum',
   'education-equity-programs', 'education-gender-identity', 'education-library-books',
   'education-school-budget', 'education-school-police')
ON CONFLICT (topic_id, role_scope) DO NOTHING;

-- =============================================================================
-- POST-VERIFY GATE
-- =============================================================================
DO $$
DECLARE
  v_def        text;
  v_school     int;
  v_keys       text[];
  v_expected   text[] := ARRAY[
    'education-ai', 'education-charter-authorization', 'education-curriculum',
    'education-equity-programs', 'education-gender-identity', 'education-library-books',
    'education-school-budget', 'education-school-police'];
  v_vouchers   int;
  v_before     int;
  v_missing    int;
  v_changed    int;
  v_after_non  int;
BEGIN
  -- (a) The CHECK admits exactly the five levels — no more, no fewer. Exact equality on the
  --     definition as Postgres renders it (pg_get_constraintdef, prod 2026-09-24), not a
  --     LIKE per value, which would also pass a CHECK carrying a sixth value.
  SELECT pg_get_constraintdef(c.oid) INTO v_def
    FROM pg_constraint c
   WHERE c.conrelid = 'inform.compass_topic_roles'::regclass
     AND c.conname = 'chk_role_scope_tier';
  IF v_def IS DISTINCT FROM
     'CHECK ((role_scope = ANY (ARRAY[''federal''::text, ''state''::text, ''local''::text, ''judicial''::text, ''school''::text])))'
  THEN
    RAISE EXCEPTION 'CA_0256 gate: chk_role_scope_tier is wrong: %', v_def;
  END IF;

  -- (b) Exactly eight school rows, on exactly the eight keys.
  SELECT count(*), array_agg(t.topic_key ORDER BY t.topic_key)
    INTO v_school, v_keys
    FROM inform.compass_topic_roles r
    JOIN inform.compass_topics t ON t.id = r.topic_id
   WHERE r.role_scope = 'school';
  IF v_school <> 8 THEN
    RAISE EXCEPTION 'CA_0256 gate: expected 8 school rows, found % (%)', v_school, v_keys;
  END IF;
  IF v_keys <> (SELECT array_agg(k ORDER BY k) FROM unnest(v_expected) k) THEN
    RAISE EXCEPTION 'CA_0256 gate: school rows are on the wrong topics: %', v_keys;
  END IF;

  -- (c) school-vouchers is NOT at the school level.
  SELECT count(*) INTO v_vouchers
    FROM inform.compass_topic_roles r
    JOIN inform.compass_topics t ON t.id = r.topic_id
   WHERE r.role_scope = 'school' AND t.topic_key = 'school-vouchers';
  IF v_vouchers <> 0 THEN
    RAISE EXCEPTION 'CA_0256 gate: school-vouchers carries a school row — it is excluded (ruling 2026-09-24)';
  END IF;

  -- (d) No existing row removed or altered, and none added outside `school`.
  SELECT count(*) INTO v_before FROM _ca0256_before;
  SELECT count(*) INTO v_missing
    FROM _ca0256_before b
   WHERE NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles r
                      WHERE r.topic_id = b.topic_id AND r.role_scope = b.role_scope);
  SELECT count(*) INTO v_changed
    FROM _ca0256_before b
    JOIN inform.compass_topic_roles r ON r.topic_id = b.topic_id AND r.role_scope = b.role_scope
   WHERE r.is_required IS DISTINCT FROM b.is_required;
  SELECT count(*) INTO v_after_non FROM inform.compass_topic_roles WHERE role_scope <> 'school';
  IF v_missing <> 0 OR v_changed <> 0 OR v_after_non <> v_before THEN
    RAISE EXCEPTION 'CA_0256 gate: existing rows disturbed — before %, after %, missing %, is_required changed %',
      v_before, v_after_non, v_missing, v_changed;
  END IF;

  RAISE NOTICE 'CA_0256 gate OK: check = %; school rows = % (%); vouchers school rows = 0; non-school rows % before, % after, 0 missing, 0 changed',
    v_def, v_school, array_to_string(v_keys, ', '), v_before, v_after_non;
END $$;

COMMIT;
