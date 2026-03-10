---
phase: 18-compassv2-api-contract
plan: 04
subsystem: docs
tags: [api-contract, compass, compassv2, bearer-auth, guest-state, anonymous-mode]

# Dependency graph
requires:
  - phase: 18-compassv2-api-contract
    provides: Anonymous compass mode, guest state migration, decimal values, completed_onboarding root field (Plans 01-03)
provides:
  - External-facing API contract document (docs/COMPASS_CONTRACT.md) for CompassV2 integration
  - Full request/response shapes for all compass and auth endpoints
  - Guest state migration specification (request shape, success behavior, failure behavior)
  - Anonymous mode implementation guide with per-route behavior table
  - Complete error codes table
affects:
  - CompassV2 frontend integration (Chris Andrews)
  - Future API documentation updates

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "API contract as a single developer-facing markdown document in /docs/"

key-files:
  created:
    - docs/COMPASS_CONTRACT.md
  modified: []

key-decisions:
  - "COMPASS_CONTRACT.md placed in /docs/ directory (created new) — accessible at repo root level for external developer"
  - "POST /auth/login user stub note documented explicitly — tier is always inform in login response, caller must hit /account/me for real tier"
  - "selected_topics migration limitation noted — Connected-only feature, localStorage fallback documented"
  - "GET /compass/selected-topics authenticated behavior (403 NOT_CONNECTED) distinguished from unauthenticated behavior (empty list)"

patterns-established:
  - "External API contract: single markdown doc in /docs/ covering base URL, auth, all endpoints, error codes, implementation guide"

# Metrics
duration: 3min
completed: 2026-03-10
---

# Phase 18 Plan 04: CompassV2 API Contract Summary

**docs/COMPASS_CONTRACT.md — 717-line external API reference covering auth, all compass endpoints, guest state migration, decimal value constraints, and anonymous mode implementation guide for CompassV2 integration**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-10T14:11:05Z
- **Completed:** 2026-03-10T14:13:53Z
- **Tasks:** 1/1
- **Files modified:** 1

## Accomplishments

- Created `docs/COMPASS_CONTRACT.md` — complete API contract usable as a standalone reference for CompassV2 integration without reading server code
- Documented guest state migration flow with full request shape, atomicity guarantees, and best-effort failure behavior
- Documented all 8 sections: overview, base URL, auth, account endpoints, auth endpoints, compass endpoints, error codes, anonymous mode guide

## Task Commits

Each task was committed atomically:

1. **Task 1: Create docs directory and write COMPASS_CONTRACT.md** - `1ab0674` (docs)

**Plan metadata:** (below)

## Files Created/Modified

- `docs/COMPASS_CONTRACT.md` — External API contract for CompassV2 developer covering all endpoints, request/response shapes, error codes, and anonymous mode implementation

## Decisions Made

- `COMPASS_CONTRACT.md` placed in `/docs/` (new directory) — accessible and clearly separated from source code
- Login response user stub documented with explicit note that `tier` is always `"inform"` in that response — caller must use `GET /account/me` for the real tier
- `GET /compass/selected-topics` behavior for authenticated-but-not-connected users (403 NOT_CONNECTED) explicitly distinguished from unauthenticated behavior (empty list) — these are different code paths
- `selected_topics` migration limitation in guest_state documented: Connected-only feature, recommend storing in localStorage and submitting after Connect enrollment

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `docs/COMPASS_CONTRACT.md` is complete and ready to share with Chris Andrews for CompassV2 integration
- All five CV2 requirements (CV2-01 through CV2-05) are covered by the document — the accounts side has been implemented in Plans 01-03, this document specifies the contracts
- Phase 18 is complete (4/4 plans executed)

---
*Phase: 18-compassv2-api-contract*
*Completed: 2026-03-10*
