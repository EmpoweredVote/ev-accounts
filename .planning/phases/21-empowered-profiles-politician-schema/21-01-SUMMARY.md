---
phase: 21-empowered-profiles-politician-schema
plan: 01
subsystem: database
tags: [postgres, supabase, migrations, typescript, rpc, security-definer]

# Dependency graph
requires:
  - phase: 20-location-endpoints
    provides: database.types.ts manual update pattern for migration columns
  - phase: 17-live-alpha-deployment
    provides: DROP FUNCTION pattern for changing RETURNS TABLE signatures (Issue 4)
provides:
  - inform.politicians with 9 new columns (district, jurisdiction, vacancy)
  - admin_list_politicians() RPC updated to return all 19 columns
  - database.types.ts Row/Insert/Update shapes updated for inform.politicians
affects:
  - phase: 21-02 (politician endpoints — uses new columns in API responses)
  - phase: 22 (Essentials — consumes district/jurisdiction fields from politicians)
  - VQ (Validation Quests — consumes vacancy + district fields for consensus records)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - DROP FUNCTION before CREATE OR REPLACE when RETURNS TABLE signature changes
    - ADD COLUMN IF NOT EXISTS for idempotent multi-statement migrations
    - Manual database.types.ts update when migrations add columns (no auto-generation)

key-files:
  created:
    - backend/migrations/033_politician_schema.sql
    - supabase/migrations/20260313000033_politician_schema.sql
  modified:
    - backend/src/types/database.types.ts

key-decisions:
  - "DROP FUNCTION IF EXISTS before CREATE OR REPLACE — required when RETURNS TABLE changes; CREATE OR REPLACE alone raises 'cannot change return type'"
  - "is_vacant: boolean (not nullable) in Row shape — NOT NULL DEFAULT false in DB; Insert/Update use optional boolean?"
  - "ADD COLUMN IF NOT EXISTS throughout — safe to re-run migration; idempotency critical for live deploy workflow"

patterns-established:
  - "Migration 033 pattern: ALTER TABLE + DROP FUNCTION + CREATE OR REPLACE + GRANT in single BEGIN/COMMIT block"
  - "Types update ordering: alphabetical field ordering within Row/Insert/Update shapes"

# Metrics
duration: 3min
completed: 2026-03-14
---

# Phase 21 Plan 01: Politician Schema Columns + RPC Update Summary

**Migration 033 adds 9 columns to inform.politicians (district, jurisdiction, vacancy fields) and recreates admin_list_politicians() with the full 19-column return set; database.types.ts updated and TypeScript strict compilation passes.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-14T07:04:45Z
- **Completed:** 2026-03-14T07:07:29Z
- **Tasks:** 2 of 2
- **Files modified:** 3

## Accomplishments

- Created migration 033 in both backend/migrations/ and supabase/migrations/ with identical SQL content
- ALTER TABLE adds 9 new columns (representing_city, representing_state, district_type, district_label, district_id, chamber_name, chamber_name_formal, government_name, is_vacant) using ADD COLUMN IF NOT EXISTS throughout
- Dropped and recreated admin_list_politicians() RPC with 20-column RETURNS TABLE signature (was 11 columns)
- Updated database.types.ts inform.politicians Row/Insert/Update shapes — is_vacant is boolean (not nullable) in Row, optional in Insert/Update
- TypeScript strict compilation passes with 0 errors

## Task Commits

Each task was committed atomically:

1. **Task 1: Create migration 033 — politician schema columns + RPC update** - `a08ede4` (feat)
2. **Task 2: Update database.types.ts + verify TypeScript compilation** - `f34336e` (feat)

## Files Created/Modified

- `backend/migrations/033_politician_schema.sql` — Migration 033: ALTER TABLE + DROP FUNCTION + CREATE OR REPLACE admin_list_politicians + GRANT
- `supabase/migrations/20260313000033_politician_schema.sql` — Timestamped copy, identical content
- `backend/src/types/database.types.ts` — inform.politicians Row (19 fields), Insert (19 fields), Update (19 fields) updated

## Decisions Made

- **DROP FUNCTION before CREATE OR REPLACE** — RETURNS TABLE signature is adding 9 columns; CREATE OR REPLACE alone raises "cannot change return type of existing function". Same pattern as 17-03-SUMMARY Issue 4.
- **is_vacant: boolean (not nullable) in Row** — column is NOT NULL DEFAULT false in DB. Insert/Update shapes use `is_vacant?: boolean` (optional) because the DB default handles omission.
- **ADD COLUMN IF NOT EXISTS** — All 9 columns use IF NOT EXISTS for idempotency, consistent with the safe-to-re-run migration contract.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required. Migration 033 will be applied to the live DB in the alpha deployment runbook (Phase 17 scripts handle the apply step).

## Next Phase Readiness

- inform.politicians schema is now complete with all fields needed by Essentials and VQ
- admin_list_politicians() RPC is ready to return the full field set
- TypeScript types are in sync — no compilation errors will appear when Phase 21-02 adds endpoints that use the new columns
- Phase 21-02 (politician endpoints) can proceed immediately

---
*Phase: 21-empowered-profiles-politician-schema*
*Completed: 2026-03-14*
