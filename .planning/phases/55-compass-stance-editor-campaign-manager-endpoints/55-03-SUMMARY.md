---
phase: 55-compass-stance-editor-campaign-manager-endpoints
plan: 03
subsystem: api
tags: [typescript, express, postgres, pool.query, role-grants, compass, politicians, stance-editor, campaign-manager]

# Dependency graph
requires:
  - phase: 55-01
    provides: stanceService.ts with getContributorPoliticians; UserRoleGrant.id; essentials.politicians.home_jurisdiction_geoid
  - phase: 55-02
    provides: compassContributor.ts router; requireRole middleware pattern; PUT /stances routes
provides:
  - GET /api/compass/contributors/politicians — jurisdiction-filtered or resource-scoped politician list
  - Read complement to the stance write routes in Plan 02
affects:
  - any frontend consuming contributor politician list (campaign_manager UI, stance_editor UI)
  - Phase 56+ if additional contributor read endpoints are added

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "GET route registered before parameterized PUT routes in same router to prevent path capture"
    - "Grant filtering in handler: getCachedUserRoles → filter to contributor slugs → pass filtered array to service"
    - "Empty array is valid 200 — caller handles no-match display logic"

key-files:
  created: []
  modified:
    - backend/src/routes/compassContributor.ts

key-decisions:
  - "GET /contributors/politicians registered before /stances/:politicianId routes — avoids any future path ambiguity"
  - "Handler filters grants to ['compass_stance_editor','campaign_manager'] before calling service — service receives only relevant grants"
  - "Empty array (200) on no matches per LOCKED decisions — not a 404"

patterns-established:
  - "getContributorPoliticians deduplicates by politician ID across overlapping grants — caller does not need to deduplicate"
  - "No stances included in response — stances fetched separately via GET /compass/politicians/:id/answers"

# Metrics
duration: 8min
completed: 2026-04-03
---

# Phase 55 Plan 03: Compass Contributor GET Politicians Summary

**GET /api/compass/contributors/politicians endpoint returning jurisdiction-filtered or resource-scoped politician list for compass_stance_editor and campaign_manager roles**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-03T00:00:00Z
- **Completed:** 2026-04-03T00:08:00Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Added `getContributorPoliticians` to the stanceService import in compassContributor.ts
- Registered `GET /contributors/politicians` before parameterized PUT routes to prevent path capture
- Applied `requireAuth` + `requireRole(['compass_stance_editor', 'campaign_manager'])` middleware
- Handler filters grants to compass-relevant slugs before delegating to service
- Full backend build (`npm run build` + `npx tsc --noEmit`) passes with zero errors

## Task Commits

Each task was committed atomically:

1. **Task 1: Add GET /contributors/politicians to compassContributor.ts** - `27c405a` (feat)
2. **Task 2: End-to-end build verification** - (no code changes needed; build already clean)

**Plan metadata:** (docs commit below)

## Files Created/Modified
- `backend/src/routes/compassContributor.ts` - Added `getContributorPoliticians` import and `GET /contributors/politicians` route handler (29 lines added)

## Decisions Made
- Empty array is a valid 200 response (per LOCKED decisions from 55-01/02 planning) — not a 404.
- Handler explicitly filters grants before passing to service rather than letting the service silently ignore non-contributor slugs.

## Deviations from Plan

None - plan executed exactly as written. `getContributorPoliticians` was already implemented in stanceService.ts (Plan 01). Only the route registration in compassContributor.ts was needed.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All 3 Phase 55 routes registered and compiling:
  1. `GET /contributors/politicians` — read: who can I edit?
  2. `PUT /stances/:politicianId/bulk` — write: batch update
  3. `PUT /stances/:politicianId/:topicId` — write: single update
- Route order prevents Express path-capture conflicts
- Phase 55 complete — ready for Phase 56 (or whatever comes next in v1.9 Roles milestone)

---
*Phase: 55-compass-stance-editor-campaign-manager-endpoints*
*Completed: 2026-04-03*
