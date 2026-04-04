---
phase: 57-ctc-civic-spaces-integration
plan: 02
subsystem: api
tags: [typescript, smoke-test, integration-guide, contributor-roles, caching, ctc, civic-spaces]

# Dependency graph
requires:
  - phase: 57-ctc-civic-spaces-integration-01
    provides: contributor roles endpoints (GET /api/contributor/me, POST /api/roles/check) with Redis cache
provides:
  - Standalone smoke script (backend/scripts/smoke-phase57.ts) validating full grant/check/revoke/expire lifecycle
  - Integration guide section 8.26 Contributor Roles with endpoint docs, cache semantics, and CTC/Civic Spaces patterns
affects:
  - CTC (Civic Trivia Championship) developers integrating role-gated features
  - Civic Spaces developers integrating volunteer role checks

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Gated lifecycle tests: SMOKE_ADMIN_TOKEN gates the expensive grant/revoke/wait path; static checks always run"
    - "SKIP-with-instructions: tests that require external setup print [SKIP] + enabling instructions rather than failing"

key-files:
  created:
    - backend/scripts/smoke-phase57.ts
  modified:
    - docs/INTEGRATION-GUIDE-v2.md

key-decisions:
  - "Smoke script reads SMOKE_TOKEN from env (can't sign JWTs without key); exits 1 with usage if not set"
  - "Cache TTL lifecycle gated on SMOKE_ADMIN_TOKEN so the 4-second wait doesn't block quick smoke runs"
  - "Integration guide section 8.26 placed under existing section 8 (not a new top-level section)"
  - "Cache note framed from external dev perspective: design to tolerate 90s window, not treat checks as real-time"

patterns-established:
  - "Phase smoke scripts: sequential checks, [PASS]/[FAIL]/[SKIP] output, Results N/N summary, exit 1 on any fail"

# Metrics
duration: 2min
completed: 2026-04-04
---

# Phase 57 Plan 02: Smoke Script + Integration Guide Summary

**Smoke script proves grant/check/revoke/expire lifecycle end-to-end; integration guide section 8.26 gives CTC and Civic Spaces developers a complete reference for both contributor role endpoints including cache semantics.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-04T04:53:29Z
- **Completed:** 2026-04-04T04:54:59Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Created `backend/scripts/smoke-phase57.ts` — sequential checks for GET /api/contributor/me and POST /api/roles/check with grant/revoke lifecycle gated on SMOKE_ADMIN_TOKEN
- Appended section 8.26 Contributor Roles to `docs/INTEGRATION-GUIDE-v2.md` documenting both endpoints with response shapes, NULL-scope semantics, cache behavior, and CTC/Civic Spaces integration patterns
- Smoke script prints usage instructions and exits 1 when SMOKE_TOKEN is not provided

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Phase 57 smoke script** - `780251f` (feat)
2. **Task 2: Append Contributor Roles section to integration guide** - `72b6da9` (docs)

**Plan metadata:** (see final docs commit)

## Files Created/Modified
- `backend/scripts/smoke-phase57.ts` - 324-line smoke script for Phase 57 contributor roles lifecycle
- `docs/INTEGRATION-GUIDE-v2.md` - Added section 8.26 Contributor Roles (51 lines)

## Decisions Made
- Smoke script reads `SMOKE_TOKEN` from environment — cannot sign JWTs without the private key, so callers must provide a valid JWT
- Cache TTL lifecycle check gated on `SMOKE_ADMIN_TOKEN` with `[SKIP]` fallback, so the 4-second wait doesn't block quick smoke runs without admin access
- Admin grant/revoke calls use `SMOKE_ADMIN_TOKEN` but check endpoint uses `SMOKE_TOKEN` — tests the perspective of an external app (non-admin user)
- Integration guide section goes under existing section 8, not as a new top-level section — it's one endpoint group among many

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 57 Plan 02 complete. Both smoke artifacts exist and are runnable.
- To run full lifecycle test: `SMOKE_TOKEN=<jwt> SMOKE_ADMIN_TOKEN=<admin-jwt> BASE_URL=https://api.empowered.vote npx tsx backend/scripts/smoke-phase57.ts`
- CTC and Civic Spaces teams can reference `docs/INTEGRATION-GUIDE-v2.md` section 8.26 for integration without further communication.
- Phase 57 is complete (Plans 01 and 02 both done).

---
*Phase: 57-ctc-civic-spaces-integration*
*Completed: 2026-04-04*
