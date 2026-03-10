---
phase: 18-compassv2-api-contract
plan: 01
subsystem: database
tags: [postgres, supabase, rpc, plpgsql, numeric, migration]

# Dependency graph
requires:
  - phase: 17-live-alpha-deployment
    provides: live production DB with migrations 026-029 applied
  - phase: 16-compass-admin
    provides: inform.compass_responses and inform.compass_change_history schema with INT value columns
provides:
  - Migration 030: compass_responses.value as NUMERIC(3,1), updated upsert_compass_answer RPC, new migrate_guest_compass_state RPC
affects:
  - 18-02-plan (compass API routes — Zod schema uses p_value, calls upsert_compass_answer)
  - 18-03-plan (guest migration endpoint — calls migrate_guest_compass_state RPC directly)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Per-row FK exception handler in PL/pgSQL FOR loop — catches foreign_key_violation per iteration, allows partial success"
    - "Conditional UPDATE pattern: only update when field IS NULL OR = empty — avoids clobbering post-signup activity"
    - "NUMERIC(3,1) for half-integer compass positions — INT stances (1-5) coexist with write-in positions (0.5 increments)"

key-files:
  created:
    - backend/migrations/030_decimal_compass_values.sql
  modified: []

key-decisions:
  - "compass_responses.value CHECK constraint bounds: 0.5–5.5 (not 1–5) — outer half-positions allow write-in just outside defined stance range"
  - "migrate_guest_compass_state uses ON CONFLICT DO NOTHING throughout — never overwrites post-signup activity"
  - "upsert_compass_answer gains SET search_path = '' in this migration — was absent from migration 025 version"
  - "database.types.ts requires no manual change — NUMERIC(3,1) maps to number same as INT in TypeScript"

patterns-established:
  - "Migration 030 section structure: schema change → history columns → updated RPC → new RPC"

# Metrics
duration: 2min
completed: 2026-03-10
---

# Phase 18 Plan 01: Decimal Compass Values Summary

**NUMERIC(3,1) compass value column + updated upsert RPC + new migrate_guest_compass_state RPC enabling write-in half-integer positions and atomic guest state migration on signup**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-10T14:08:44Z
- **Completed:** 2026-03-10T14:10:26Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Created migration 030 with four sections: CHECK constraint drop/re-add, column type change on compass_responses.value (INT → NUMERIC(3,1)), matching type change on compass_change_history old_value/new_value, updated upsert_compass_answer with NUMERIC parameter and SET search_path = '', new migrate_guest_compass_state RPC
- migrate_guest_compass_state handles FK violations per-row (stale guest topic IDs skip rather than abort), uses ON CONFLICT DO NOTHING to never overwrite post-signup activity
- TypeScript compilation passes 0 errors — NUMERIC(3,1) maps to number in TypeScript identically to INT, no database.types.ts changes needed

## Task Commits

Each task was committed atomically:

1. **Task 1: Schema migration — decimal compass values** - `602d1ac` (feat)
2. **Task 2: Regenerate database types and verify TypeScript compilation** - no separate commit needed (database.types.ts unchanged; TS passes clean from Task 1)

**Plan metadata:** (docs commit below)

## Files Created/Modified
- `backend/migrations/030_decimal_compass_values.sql` - Migration with column type change, constraint update, upsert RPC update, guest migration RPC

## Decisions Made
- **CHECK constraint bounds 0.5–5.5, not 1–5** — outer half-positions (0.5, 5.5) allow write-in placement just outside the defined stance range; plan specified this explicitly.
- **database.types.ts unchanged** — NUMERIC(3,1) and INT both map to TypeScript `number`; manual edit would be superfluous and risks introducing drift vs. a future `supabase gen types` run.
- **SET search_path = '' added to upsert_compass_answer** — was absent from migration 025 version; added here to bring the function in line with project security conventions established in v1.2.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None — no external service configuration required. Migration 030 must be applied to the live DB via `node backend/scripts/applyMigration.js 030` (same process as 026–029).

## Next Phase Readiness
- Migration 030 file is ready to apply to production DB (done as part of a Phase 18 deployment step or alongside Plan 18-02/18-03 route work)
- Plan 18-02 (compass route updates) can proceed — upsert_compass_answer now accepts NUMERIC, enabling Zod schema to drop `.int()` validator
- Plan 18-03 (guest migration endpoint) can proceed — migrate_guest_compass_state RPC exists and is ready to call
- TypeScript compilation baseline is clean

---
*Phase: 18-compassv2-api-contract*
*Completed: 2026-03-10*
