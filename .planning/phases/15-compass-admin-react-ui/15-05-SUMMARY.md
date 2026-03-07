---
phase: 15-compass-admin-react-ui
plan: 05
subsystem: api
tags: [express, supabase, typescript, compass, admin]

# Dependency graph
requires:
  - phase: 14-compass-admin-backend
    provides: admin routes and adminService.ts pattern established
  - phase: 15-compass-admin-react-ui
    provides: TopicsPage and PoliticiansPage frontend callers using GET /topics/:id/stances
provides:
  - GET /api/admin/compass/topics/:id/stances — bare Stance[] array endpoint
  - getTopicStances(topicId) service function in adminService.ts
affects:
  - frontend consumers: TopicsPage stance editor, PoliticiansPage StanceSelector

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Gap closure: backend endpoint added to unblock existing frontend callers"
    - "Bare array response: GET stances returns Stance[] directly, no wrapper key"

key-files:
  created: []
  modified:
    - backend/src/lib/adminService.ts
    - backend/src/routes/admin.ts

key-decisions:
  - "Route placement: GET /compass/topics/:id/stances inserted between PATCH /compass/topics/:id and PATCH /compass/stances/:id for logical grouping"

patterns-established:
  - "Stance query pattern: .schema('inform').from('compass_stances').select('id,topic_id,value,text').eq('topic_id', id).order('value', ascending)"

# Metrics
duration: 5min
completed: 2026-03-07
---

# Phase 15 Plan 05: Compass Admin Stance Endpoint (Gap Closure) Summary

**GET /api/admin/compass/topics/:id/stances endpoint added — unblocks TopicsPage stance editor and PoliticiansPage StanceSelector RadioGroup from permanent loading state**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-03-07T05:14:21Z
- **Completed:** 2026-03-07T05:19:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Added `getTopicStances(topicId)` to adminService.ts — queries `inform.compass_stances` filtered by topic_id, ordered by value ascending
- Registered `GET /compass/topics/:id/stances` in admin router returning bare `Stance[]` array (no wrapper key)
- Closed the gap identified in 15-VERIFICATION.md: Phase 14 delivered 12 routes but omitted this one, leaving two frontend callers silently 404ing

## Task Commits

Each task was committed atomically:

1. **Task 1: Add getTopicStances service function** - `ef8aed4` (feat)
2. **Task 2: Add GET /compass/topics/:id/stances route** - `30c186d` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `backend/src/lib/adminService.ts` - Added `getTopicStances(topicId)` export after `adminUpdateStance`
- `backend/src/routes/admin.ts` - Added `getTopicStances` to import block; added GET route between PATCH topics/:id and PATCH stances/:id

## Decisions Made
- Route placed between PATCH /compass/topics/:id and PATCH /compass/stances/:id to keep compass/topics routes grouped together
- Response is bare array (no wrapper key) — consistent with STATE.md accumulated decision "GET stances returns array directly" and matches `apiFetch<Stance[]>` call sites in frontend

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- `npx tsc` did not resolve to local tsc (not in PATH); used `./node_modules/.bin/tsc` directly. No impact on outcome.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 15 is now fully complete: all 5 plans shipped
- Backend and frontend are aligned — compass admin UI is functional end-to-end
- TopicsPage stance editor can populate and save stance text edits
- PoliticiansPage StanceSelector RadioGroup renders 5 stance options and allows selection
- No remaining blockers for Phase 15

---
*Phase: 15-compass-admin-react-ui*
*Completed: 2026-03-07*
