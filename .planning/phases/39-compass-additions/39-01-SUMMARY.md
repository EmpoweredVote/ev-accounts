---
phase: 39-compass-additions
plan: 01
subsystem: database
tags: [postgres, migrations, rpc, rls, compass, verdicts, numeric]

# Dependency graph
requires:
  - phase: 30-decimal-compass-values
    provides: NUMERIC(3,1) type on compass_responses.value + range CHECK constraint
  - phase: 35-politician-deduplication
    provides: essentials.politicians as sole politician source; inform.politician_answers FK target
  - phase: 38-express-ports-wave3-essentials
    provides: essentials schema confirmed in DB; essentials.quotes table accessible

provides:
  - inform.politician_answers.value migrated from INT to NUMERIC(3,1)
  - Half-step CHECK constraint on politician_answers.value (0.5 increments, 0.5–5.5)
  - Half-step CHECK constraint on compass_responses.value (tightened from range-only)
  - inform.compass_verdicts table with RLS owner-read policy and two indexes
  - admin_update_politician_answers RPC — full-replacement (DELETE not-in-payload + upsert)
  - upsert_compass_verdicts RPC — atomic batch verdict persistence
  - applyMigrations.ts updated with 037 + 038 entries and verification queries

affects:
  - 39-02 (compare routes use politician_answers decimal values)
  - 39-03 (verdict routes depend on compass_verdicts table and upsert RPC)
  - admin compass routes (PUT /api/compass/politicians/:id/answers uses full-replacement RPC)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Full-replacement RPC pattern: collect payload IDs → DELETE WHERE NOT IN payload → upsert payload rows"
    - "NULLIF(elem->>'rank', 'null')::integer for JSON null handling in PL/pgSQL"
    - "Half-step CHECK formula: (value * 2) = ROUND(value * 2) AND value >= 0.5 AND value <= 5.5"

key-files:
  created:
    - backend/migrations/038_compass_additions.sql
  modified:
    - backend/scripts/applyMigrations.ts

key-decisions:
  - "compass_verdicts PK is (user_id, quote_id) — UPSERT ON CONFLICT replaces prior session verdict"
  - "rank stored as raw ordinal integer, not normalized — normalization deferred to presentation layer (rank/session_size)"
  - "admin_update_politician_answers is full-replacement not additive — any answer not in payload is deleted"
  - "upsert_compass_verdicts grants only to service_role (not authenticated) — called via server-side RPC only"

patterns-established:
  - "Full-replacement RPC: use array_agg to collect payload IDs, DELETE WHERE NOT IN array, then upsert loop"

# Metrics
duration: 3min
completed: 2026-03-20
---

# Phase 39 Plan 01: Compass Additions Migration Summary

**NUMERIC(3,1) column migration + half-step CHECK constraints + compass_verdicts table with RLS + full-replacement admin_update_politician_answers RPC + upsert_compass_verdicts RPC**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-20T21:43:25Z
- **Completed:** 2026-03-20T21:45:52Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Created complete `038_compass_additions.sql` covering all 7 DDL sections in correct dependency order
- Added missing 037 migration entry to applyMigrations.ts (was on disk but not in the runner)
- Full-replacement `admin_update_politician_answers` RPC replaces upsert-only version from migration 025 — answers not in payload are now deleted, enabling true CRUD from the admin UI

## Task Commits

1. **Task 1: Create 038_compass_additions.sql migration** — `2556bb5` (feat)
2. **Task 2: Update applyMigrations.ts with 037 and 038 entries** — `798ceaa` (chore)

**Plan metadata:** (see final commit below)

## Files Created/Modified

- `backend/migrations/038_compass_additions.sql` — All Phase 39 DDL: column migration, CHECK constraints, verdicts table + RLS + indexes, updated admin RPC, new upsert RPC
- `backend/scripts/applyMigrations.ts` — Added 037 and 038 to MIGRATIONS array, PRE_VERIFY_QUERIES, POST_VERIFY_QUERIES; updated header comment

## Decisions Made

- **NULLIF for JSON null handling** — `NULLIF(elem->>'rank', 'null')::integer` handles clients sending JSON null as the string `"null"` for unsupported quotes' rank field
- **service_role only on upsert_compass_verdicts** — This RPC is called server-side only (authenticated user's verdicts submitted via the accounts API, not directly from the client). Contrast with `admin_update_politician_answers` which grants `service_role, authenticated` for direct admin UI calls.
- **compass_verdicts in inform schema** — Consistent with all other compass tables; user opinion/judgment data belongs in `inform`, not `connect`
- **HEAD comment updated** — applyMigrations.ts header said "026–036"; bumped to "026–038" to stay accurate

## Deviations from Plan

None — plan executed exactly as written. The header comment update in applyMigrations.ts was a minor housekeeping fix (not a deviation — it was incorrect documentation, not unplanned scope).

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required. Migration will be applied via `applyMigrations.ts` when DATABASE_URL is set to the direct connection string.

## Next Phase Readiness

- Plan 02 (compare routes) is unblocked — politician_answers.value is now NUMERIC(3,1); compare endpoint can compute decimal-precision alignment scores
- Plan 03 (verdicts routes) is unblocked — inform.compass_verdicts table exists with correct schema and RLS; upsert_compass_verdicts RPC is ready for the POST /api/compass/verdicts endpoint

---
*Phase: 39-compass-additions*
*Completed: 2026-03-20*
