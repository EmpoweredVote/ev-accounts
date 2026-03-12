---
phase: 79-backend-verdict-endpoints
plan: 02
subsystem: api
tags: [go, gorm, postgres, essentials, quotes, filter]

# Dependency graph
requires:
  - phase: 79-backend-verdict-endpoints
    provides: QuoteVerdict model and compass.verdicts schema from plan 79-01
provides:
  - GET /essentials/quotes?politician_id=UUID — filtered quotes endpoint for single-politician profile views
affects:
  - Phase 81 profile page (consumes politician-scoped quotes for Read & Rank display)

# Tech tracking
tech-stack:
  added: []
  patterns: [conditional raw SQL construction with optional WHERE clause and variadic args for GORM Raw()]

key-files:
  created: []
  modified:
    - EV-Backend/internal/essentials/handlers.go

key-decisions:
  - "Conditional WHERE clause built by string concatenation before db.DB.Raw() call — avoids GORM subquery complexity while keeping all existing query structure intact"

patterns-established:
  - "Pattern: optional UUID filter — parse param, validate UUID, store as *uuid.UUID, conditionally append WHERE and args before Raw()"

requirements-completed:
  - VERD-04

# Metrics
duration: 5min
completed: 2026-03-12
---

# Phase 79 Plan 02: GetQuotes politician_id Filter Summary

**Optional ?politician_id UUID filter added to GET /essentials/quotes — returns politician-scoped quotes, candidates, and issues with identical response shape**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-03-12T12:37:00Z
- **Completed:** 2026-03-12T12:38:12Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Parsed optional `politician_id` query param at the start of `GetQuotes`; invalid UUID returns 400
- Applied conditional WHERE clause to the main JOIN query so only quotes for that politician are returned
- Applied same filter to the topic-count subquery to keep `TotalIssues` accurate for the filtered candidate
- Response shape `{quotes, candidates, issues}` is identical whether the filter is applied or not

## Task Commits

Each task was committed atomically:

1. **Task 1: Add politician_id filter to GetQuotes** - `d695a0d` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `EV-Backend/internal/essentials/handlers.go` - Added UUID param parsing + conditional WHERE to both raw SQL queries in GetQuotes

## Decisions Made
- Conditional WHERE clause built by string concatenation before the `db.DB.Raw()` call — avoids GORM subquery complexity while preserving the existing query structure entirely

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- GET /essentials/quotes?politician_id=UUID is ready for Phase 81 to consume
- No blockers; all build/vet checks pass

## Self-Check: PASSED
- `EV-Backend/internal/essentials/handlers.go` — FOUND
- Commit `d695a0d` — FOUND

---
*Phase: 79-backend-verdict-endpoints*
*Completed: 2026-03-12*
