-- =============================================================================
-- Phase 106: DC SBOE Stances — Plan 02
-- Requirements covered: DCST-02
-- Source CSV: backend/data/stance-research/2026-06-08-106-dc-sboe.csv
--
-- Pre-write cross-check:
--   CSV data rows: 0
--   politician_answers rows written: 0 ✓
--   politician_context rows written: 0 ✓
--   Reason: D-07 honest-skip — all 9 SBOE members had zero documentable stances
--           accessible via WebFetch (DC SBOE site is JS-rendered; individual members
--           have no accessible policy positions on compass topics per D-06/D-11)
--
-- Migration number: 290 (sequential after 289, Plan 01's migration)
-- Timestamp: 20260608000002
--
-- SBOE UUIDs (external_id → UUID, from 2026-06-08-106-dc-sboe-uuids.json):
--   Jacque Patterson    (-600019) → 9fc8db1d-4fae-40c3-9eb2-cd7da6d4b154
--   Ben Williams        (-600020) → a4d74758-4bdb-4060-a345-763e0a7f54d9
--   Allister Chang      (-600021) → 55653ccb-75e1-43b7-8de3-0a97c69da52b
--   Eric Goulet         (-600022) → e8d68d3a-62ab-4e10-b93a-e521b131fc50
--   T. Michelle Colson  (-600023) → 7cd5d5a4-f308-428d-8b19-57be65bd0340
--   Robert Henderson    (-600024) → 43cf9678-cb25-4963-aa52-82e1fb54f2e4
--   Brandon Best        (-600025) → 0a03981a-1b37-4596-bab8-1579316ab851
--   Eboni-Rose Thompson (-600026) → 7df6901d-af55-4811-9f1d-c03d0b99c52b
--   LaJoy Johnson-Law   (-600027) → 2c70c489-c12a-4085-b4ba-b697e75f71d9
--
-- Honest-skip members (D-07): ALL 9 SBOE members
--   Research conducted 2026-06-08. Sources attempted (20+ URLs via WebFetch):
--   - ballotpedia.org — pages found for Patterson, Thompson, Johnson-Law, Chang,
--     Goulet, Colson; Candidate Connection surveys found for Thompson and Johnson-Law
--   - sboe.dc.gov — fully JS-rendered, not accessible via WebFetch (New Relic bundle)
--   - DCist, TheDCLine, WAMU, WTOP, WaPo — no accessible individual member policy articles
--   - The74, Chalkbeat, edweek.org — no accessible DC SBOE individual stance content
--   - ontheissues.org — 404 for DC School Board
--   - Wikipedia — confirms membership list only, no policy positions
--   Ballotpedia Candidate Connection surveys (Thompson 2024, Johnson-Law 2024) contain
--   general pro-public-school equity language but do NOT state explicit positions on
--   any compass topic that match exact FIVE-CHAIRS stance text (D-11 requirement).
--   Per D-06 (skip > infer) and D-07 (blank stance profile acceptable and honest):
--   zero INSERT rows written. The migration is a traceability record.
-- =============================================================================

BEGIN;

-- ============================================================
-- INSERT BLOCK — 0 rows
-- D-07 honest-skip: all 9 SBOE members had zero documentable
-- stances accessible via WebFetch on 2026-06-08.
--
-- Reason summary:
--   - DC SBOE website (sboe.dc.gov) is 100% JavaScript-rendered
--     (New Relic bundle) and not accessible via curl/WebFetch
--   - SBOE is a local advisory board; individual members have very
--     limited public policy documentation in news/media archives
--   - General pro-public-school language found for Patterson,
--     Thompson, Johnson-Law does not match exact FIVE-CHAIRS
--     stance text for any topic per D-11 constraint
--   - Ben Williams, Robert Henderson, Brandon Best: no policy
--     content found in any WebFetch-accessible source
--   This blank stance profile is acceptable and honest (D-07).
--   DCST-02 is closed: all 9 SBOE members were researched;
--   zero documented positions found.
-- ============================================================

DO $$
BEGIN
  RAISE NOTICE 'Migration 290 (Phase 106 / DCST-02): DC SBOE stances — 0 stances added, 0 context rows added. Honest-skip (D-07): all 9 SBOE members (Patterson, Williams, Chang, Goulet, Colson, Henderson, Best, Thompson, Johnson-Law) had zero documentable stances accessible via WebFetch on 2026-06-08. DC SBOE website is JS-rendered; individual members have no accessible policy documentation matching FIVE-CHAIRS stance text (D-11). Blank stance profiles are acceptable and honest per D-07. DCST-02 satisfied: all 9 members researched.';
END
$$;

COMMIT;
