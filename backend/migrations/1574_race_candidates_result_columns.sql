-- 1574_race_candidates_result_columns.sql
--
-- Give `essentials.race_candidates` somewhere to record what actually HAPPENED in a race.
--
--   Rollback: ALTER TABLE essentials.race_candidates
--               DROP CONSTRAINT IF EXISTS race_candidates_result_check,
--               DROP CONSTRAINT IF EXISTS race_candidates_result_needs_source,
--               DROP COLUMN IF EXISTS result,
--               DROP COLUMN IF EXISTS result_source,
--               DROP COLUMN IF EXISTS result_recorded_at;
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1574_race_candidates_result_columns.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- THE GAP
-- ---------------------------------------------------------------------------------------------------
-- `candidate_status` has exactly three values in production today:
--
--     active 2722 · filed 132 · withdrawn 130
--
-- None of them means "lost". So when an election is held, there is no honest way to say so. Every
-- entrant in a finished race stays `active` forever, and the only way to make a loser stop looking
-- like a live candidate is to mislabel them `withdrawn` — which asserts something false: that they
-- quit, rather than that they ran and were beaten.
--
-- That mislabelling is already in the data. Migration 1457 cleared Michigan's provisional
-- general-election field by setting non-qualifiers to `withdrawn`, and its own source note has to
-- spell out the ambiguity it created: "listed withdrawn/disqualified, OR absent after the filing
-- deadline". Three different facts, one status value, distinguishable only by reading prose.
--
-- ---------------------------------------------------------------------------------------------------
-- THE SHAPE
-- ---------------------------------------------------------------------------------------------------
-- `result` is a SEPARATE axis from `candidate_status`, not an extension of it. Status answers "is this
-- person standing in this race"; result answers "how did this race end for them". They are orthogonal:
-- a candidate can be `active` + `won`, or `active` + `lost`, or `withdrawn` + NULL.
--
--   won      — carried the race (includes running unopposed)
--   lost     — ran and was defeated
--   advanced — cleared a primary/top-two round and continues to a later round
--   runoff   — no outright winner; this candidate is in the runoff
--   withdrew — left the race before it was decided, so no outcome was recorded
--
-- 🔑 `result_source` is NOT optional decoration — a CHECK constraint makes it structurally impossible
-- to record an outcome without a citation. This project has spent an entire audit (migrations
-- 1530-1573) retiring assertions that were recorded without a checkable source, including 1,166
-- citations pointing at pages that never existed. An outcome column with a nullable source would be
-- the same defect with a new column name. The constraint is the point of this migration as much as
-- the column is.
--
-- NOTE ON SCOPE: this is the storage layer only. Nothing reads `result` yet — no API field, no UI
-- surface. Populating it and displaying it are separate, later work.
-- ---------------------------------------------------------------------------------------------------

ALTER TABLE essentials.race_candidates
  ADD COLUMN IF NOT EXISTS result            text,
  ADD COLUMN IF NOT EXISTS result_source     text,
  ADD COLUMN IF NOT EXISTS result_recorded_at timestamptz;

-- Vocabulary gate: NULL means "not yet known / not yet recorded", never "lost".
ALTER TABLE essentials.race_candidates
  DROP CONSTRAINT IF EXISTS race_candidates_result_check;
ALTER TABLE essentials.race_candidates
  ADD CONSTRAINT race_candidates_result_check
  CHECK (result IS NULL OR result IN ('won', 'lost', 'advanced', 'runoff', 'withdrew'));

-- Evidence gate: an outcome without a citation cannot be written at all.
ALTER TABLE essentials.race_candidates
  DROP CONSTRAINT IF EXISTS race_candidates_result_needs_source;
ALTER TABLE essentials.race_candidates
  ADD CONSTRAINT race_candidates_result_needs_source
  CHECK (result IS NULL OR (result_source IS NOT NULL AND btrim(result_source) <> ''));

COMMENT ON COLUMN essentials.race_candidates.result IS
  'How the race ended for this candidate: won | lost | advanced | runoff | withdrew. NULL = not yet recorded, NOT lost. Orthogonal to candidate_status.';
COMMENT ON COLUMN essentials.race_candidates.result_source IS
  'Citation for `result` — official canvass/SoS results page preferred. Required by CHECK whenever result is non-NULL.';
COMMENT ON COLUMN essentials.race_candidates.result_recorded_at IS
  'When the outcome was written. Distinct from last_verified_at, which tracks candidacy re-verification.';
