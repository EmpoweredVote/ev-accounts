-- 1582_is_live_candidate_predicate.sql
--
-- Define "is this person actually still standing in this race?" ONCE, in the database, so the
-- eleven places that currently answer it by hand stop drifting apart.
--
--   Rollback: DROP FUNCTION IF EXISTS essentials.is_live_candidate(text, text);
--             (revert the call sites in backend/src/lib/*.ts first — they depend on it)
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1582_is_live_candidate_predicate.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- WHY THIS EXISTS
-- ---------------------------------------------------------------------------------------------------
-- Migration 1574 added `result`, and 1575-1581 populated it — 67 rows are now `not_nominated`, people
-- who ran and did not become their race's nominee. Nothing in the API knew that. Liveness was tested
-- as `COALESCE(candidate_status,'active') <> 'withdrawn'`, hand-written in ELEVEN places across seven
-- services:
--
--   electionsMapService  ×3  (active_count / stanced_count / motivated_count on the elections map)
--   readrankService      ×3  (rankable topics, race pipeline, question sourcing)
--   readrankCoverageService ×2 · readrankQuestionsService ×1
--   electionService      ×1  (candidate detail)
--   compassService       ×1  · essentialsService ×1   (these two use strict `= 'active'`)
--
-- Every one of them counted a defeated primary candidate as a live candidate. Fixing that by editing
-- eleven literals is how you get twelve behaviours: the next service to be written copies whichever
-- literal it happened to see. A predicate that must be repeated is a predicate that will diverge.
--
-- ---------------------------------------------------------------------------------------------------
-- 🔑 TWO DIMENSIONS, DELIBERATELY NOT COLLAPSED
-- ---------------------------------------------------------------------------------------------------
-- `candidate_status` and `result` answer different questions and this function keeps both:
--
--     withdrawn      — they quit                      (status axis)
--     not_nominated  — they ran and lost/failed to qualify   (result axis)
--
-- Either one ends a candidacy, so either one makes this false.
--
-- ⚠️ WHAT THIS FUNCTION IS *NOT*. Nine of the eleven call sites mean "not withdrawn", but TWO —
-- compassService and essentialsService — test `candidate_status = 'active'`, which ALSO excludes
-- `filed` (132 rows). That is a stricter rule, and whether `filed` should count is a separate product
-- question nobody has asked. So those two sites keep their `= 'active'` test and additionally call
-- this function; they are not silently loosened by this migration. The function centralises the
-- not_nominated rule for all eleven, not the status rule for all eleven.
--
-- IMMUTABLE + STRICT-free on purpose: `result` is NULL for ~97% of rows and NULL must mean "still
-- standing", not "unknown, exclude". A STRICT function would return NULL there and silently drop
-- every candidate whose outcome has not been recorded — i.e. almost all of them.
--
-- ⚠️ `won` AND `lost` RETURN TRUE, AND THAT IS INTENTIONAL. They look like they should end a
-- candidacy, but they can only ever be set on a race that has ALREADY HAPPENED, and excluding them
-- would change what past elections render rather than fix what upcoming ones count. Every call site
-- either scopes to `election_date >= CURRENT_DATE` (compassService, essentialsService) or is driven
-- by a caller-supplied date; on an upcoming race `won`/`lost` cannot occur, so including them costs
-- nothing today. Making a finished race show zero candidates is a past-election DISPLAY decision —
-- it would, for instance, make ElectionsView's hide-empty-races rule erase the race entirely — and
-- it is not this migration's to make. This predicate excludes exactly the two states that mean
-- "will not be on the ballot going forward".
--
-- Effect on the corpus at time of writing: 2,984 rows · 2,854 live under the old inline test ·
-- 2,802 live under this one. The 52-row difference is exactly the `not_nominated` population.
-- ---------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION essentials.is_live_candidate(
  p_candidate_status text,
  p_result           text
) RETURNS boolean
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $$
  SELECT COALESCE(p_candidate_status, 'active') <> 'withdrawn'
     AND p_result IS DISTINCT FROM 'not_nominated'
$$;

COMMENT ON FUNCTION essentials.is_live_candidate(text, text) IS
  'True when a race_candidates row is still a standing candidacy. False if they withdrew (candidate_status) or did not become the nominee (result). NULL result means "not yet recorded", which counts as live. Single source of truth — do not re-inline this test.';
