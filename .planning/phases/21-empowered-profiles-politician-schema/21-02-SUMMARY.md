---
phase: 21-empowered-profiles-politician-schema
plan: 02
subsystem: api
tags: [supabase, typescript, postgresql, politicians, essentials]

# Dependency graph
requires:
  - phase: 21-01
    provides: Migration 033 — inform.politicians 9 new district columns + database.types.ts update
provides:
  - essentialsService.ts updated with all 9 new politician fields and is_vacant=false filter
  - PoliticianRecord interface includes representing_city, representing_state, district_type, district_label, district_id, chamber_name, chamber_name_formal, government_name, is_vacant
  - GET /api/essentials/politicians returns all new fields, always present even when null
  - Idempotent seed script for Bloomington IN + LA CA politician district data
  - Runbook for executing and extending politician seed
affects: [22-validation-quests-integration, essentials-app, downstream-politician-consumers]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Supabase select string must be a single string literal for TypeScript type inference (not concatenation)"
    - "Dual filter pattern: is_active=true AND is_vacant=false for politician queries"
    - "Seed script upsert on (first_name, last_name) for idempotent politician records"

key-files:
  created:
    - scripts/seedPoliticians.ts
    - docs/RUNBOOK-POLITICIAN-SEED.md
  modified:
    - backend/src/lib/essentialsService.ts

key-decisions:
  - "is_vacant filter added to essentialsService alongside is_active — both required, vacant seats must be excluded from API responses"
  - "Supabase select concatenated string causes GenericStringError type inference failure — must use single string literal for type safety"
  - "Seed upsert uses (first_name, last_name) conflict target — sufficient for placeholder seed records; real officeholder records should use id-based upsert"

patterns-established:
  - "PoliticianRecord whitelist: all new fields always included in response object even when null — no optional fields in response shape"
  - "Seed script pattern: validate env vars at startup, exit 1 on error, log each upserted record, exit 0 on success"

# Metrics
duration: 8min
completed: 2026-03-14
---

# Phase 21 Plan 02: Essentials Politician Endpoint + Seed Script Summary

**GET /api/essentials/politicians extended to return 9 new district fields (district_type, chamber_name, government_name, etc.) with is_vacant=false filter; idempotent seed covers Bloomington IN and LA CA**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-03-14T07:06:13Z
- **Completed:** 2026-03-14T07:14:40Z
- **Tasks:** 2
- **Files modified/created:** 3

## Accomplishments

- PoliticianRecord interface updated with all 9 new fields from migration 033 — response shape now includes representing_city, representing_state, district_type, district_label, district_id, chamber_name, chamber_name_formal, government_name, is_vacant
- getPoliticiansGrouped() now filters is_vacant=false alongside is_active=true — vacant seats excluded from all API responses
- Idempotent seed script (scripts/seedPoliticians.ts) covers 4 records: Indiana 9th Congressional, Indiana SD-40, Indiana HD-60, LA County — safe to re-run via upsert ON CONFLICT
- Runbook (docs/RUNBOOK-POLITICIAN-SEED.md) documents prerequisites, execution command, verification steps, and extension guide

## Task Commits

Each task was committed atomically:

1. **Task 1: Update essentialsService.ts — new fields + is_vacant filter** - `48ef674` (feat)
2. **Task 2: Create seed script + runbook** - `97f202a` (feat)

**Plan metadata:** (this commit — docs: complete plan)

## Files Created/Modified

- `backend/src/lib/essentialsService.ts` - PoliticianRecord interface extended with 9 new fields; select query updated; is_vacant=false filter added; response whitelist updated
- `scripts/seedPoliticians.ts` - Idempotent seed script for Bloomington IN + LA CA politician district data; upserts on (first_name, last_name)
- `docs/RUNBOOK-POLITICIAN-SEED.md` - Runbook: prerequisites, execution, verification, extension guide, district_id format reference

## Decisions Made

- **is_vacant=false filter position:** Added as a second `.eq()` filter on the same query chain alongside `.eq('is_active', true)` — both are always applied, vacant seat exclusion is unconditional.
- **Select string must be a single literal:** Supabase TypeScript client infers column types from the select string literal. Using string concatenation (`'col1, ' + 'col2'`) breaks type inference and causes `GenericStringError` type errors. All columns must be in one literal string.
- **Seed conflict target:** `(first_name, last_name)` chosen for the upsert conflict target because the placeholder seed records don't have predetermined UUIDs. When updating to real officeholder data with known IDs, use `(id)` instead.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] TypeScript GenericStringError from concatenated select string**
- **Found during:** Task 1 (essentialsService.ts update)
- **Issue:** Initial implementation split the select string across two lines using `+` concatenation for readability. Supabase's TypeScript client cannot infer column types from concatenated strings — produces `GenericStringError[]` type error.
- **Fix:** Collapsed all column names into a single string literal on one line.
- **Files modified:** backend/src/lib/essentialsService.ts
- **Verification:** `cd backend && npx tsc --noEmit` exits 0
- **Committed in:** 48ef674 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug — TypeScript type inference)
**Impact on plan:** Minor fix, no scope change. Required for TypeScript strict compliance.

## Issues Encountered

None beyond the auto-fixed TypeScript issue above.

## User Setup Required

None — no external service configuration required for this plan. Seed script requires env vars already set for any environment that runs the backend.

## Next Phase Readiness

- GET /api/essentials/politicians is fully updated — all 9 new fields present in responses
- Seed script ready to execute against any environment after migration 033 is applied
- Phase 21 complete (both plans done) — empowered_profiles politician schema fully built out
- Phase 22 (Validation Quests integration) can proceed — politician district data available via endpoint

---
*Phase: 21-empowered-profiles-politician-schema*
*Completed: 2026-03-14*
