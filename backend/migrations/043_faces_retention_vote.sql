-- =============================================================================
-- Migration 043: faces_retention_vote column on essentials.offices
--
-- Adds faces_retention_vote boolean to essentials.offices per D-10 decision.
-- This flag indicates that the current holder of this office faces a retention
-- vote rather than a contested election.
--
-- DESIGN RATIONALE (D-10):
-- The flag is a property of the seat/position, not the individual. When a judge
-- leaves and a new judge is appointed, the replacement automatically inherits
-- the faces_retention_vote flag without any data entry. This is more normalized
-- than storing the flag on essentials.politicians.
--
-- DISTINCTION FROM districts.retention:
-- essentials.districts.retention is a pre-existing boolean from BallotReady
-- geofence boundary data — it describes district-level characteristics.
-- essentials.offices.faces_retention_vote is an operational flag for the
-- Phase 100 elected/appointed filter UI behavior. These are separate concepts
-- with different sources and semantics.
--
-- INDIANA JUDICIAL RETENTION (confirmed from official Indiana Courts website):
-- Retention vote applies ONLY to appellate-level courts:
--   - Indiana Supreme Court
--   - Indiana Court of Appeals (judges appear on ballot only in their region)
--   - Indiana Tax Court
--
-- Circuit court and superior court judges are NOT subject to retention votes.
-- They run in partisan elections — a completely different mechanism. This
-- migration sets faces_retention_vote = true only for the three appellate courts.
--
-- All changes use IF NOT EXISTS / conditional UPDATE for idempotency.
-- =============================================================================

BEGIN;

-- =============================================================================
-- Step 1: Add faces_retention_vote column to essentials.offices
-- =============================================================================

ALTER TABLE essentials.offices
  ADD COLUMN IF NOT EXISTS faces_retention_vote boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN essentials.offices.faces_retention_vote IS
  'True for offices where the incumbent faces a retention vote rather than a contested election.
   In Indiana, this applies to Supreme Court, Court of Appeals, and Tax Court judges only
   (appellate level). Circuit and superior court judges run in partisan elections and do NOT
   have retention votes.
   This flag enables dual-filter behavior: retention judges appear under both the Elected
   and Appointed filters in the Phase 100 representatives filter UI.
   NOTE: This is different from essentials.districts.retention, which is BallotReady
   geofence boundary data. This column is an operational flag for voter-facing display.';

-- =============================================================================
-- Step 2: Flag Indiana retention offices
--
-- Sets faces_retention_vote = true for offices in Indiana where:
-- - The office is an appointed position (is_appointed_position = true)
-- - The chamber name matches one of the three appellate courts
--
-- Only appellate-level courts. Circuit/Superior courts in Indiana run in
-- partisan elections and do NOT have retention votes.
-- =============================================================================

UPDATE essentials.offices o
SET faces_retention_vote = true
FROM essentials.chambers ch
JOIN essentials.governments g ON g.id = ch.government_id
WHERE o.chamber_id = ch.id
  AND g.state = 'IN'
  AND o.is_appointed_position = true
  AND (
    ch.name ILIKE '%supreme court%'
    OR ch.name ILIKE '%court of appeals%'
    OR ch.name ILIKE '%tax court%'
  );

-- =============================================================================
-- Step 3: Verification query (commented out — for manual verification only)
--
-- Run this after migration to confirm Indiana retention offices were flagged:
--
-- SELECT o.id, o.title, ch.name, g.name, o.faces_retention_vote
-- FROM essentials.offices o
-- LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
-- LEFT JOIN essentials.governments g ON g.id = ch.government_id
-- WHERE g.state = 'IN' AND o.is_appointed_position = true
-- ORDER BY ch.name, o.title;
--
-- Expected: faces_retention_vote = true for Supreme Court, Court of Appeals,
-- and Tax Court offices; false for Circuit and Superior court offices.
-- =============================================================================

COMMIT;
