---
phase: 16-v12-gap-closure
plan: 01
subsystem: api, ui
tags: [supabase, soft-delete, typescript, react, compass, admin-ui]

# Dependency graph
requires:
  - phase: 13-compassv2-backend-compatibility
    provides: "soft-delete via deleted_at on compass_responses + reset_compass_answers RPC"
  - phase: 14-compass-admin-backend
    provides: "admin_create_topic_with_stances RPC that superseded adminCreateTopic"
  - phase: 15-compass-admin-react-ui
    provides: "CategoriesPage, TopicsPage, PoliticiansPage components under fix"
provides:
  - "GET /compass/answers filters soft-deleted rows via .is('deleted_at', null)"
  - "POST /compass/answers/batch filters soft-deleted rows via .is('deleted_at', null)"
  - "CategoriesPage correctly reads plain array from /compass/categories"
  - "adminCreateTopic dead code removed from adminService.ts"
  - "All local interface id fields in TopicsPage, CategoriesPage, PoliticiansPage typed as string"
affects:
  - "CompassV2 frontend — DELETE /answers/me now correctly produces empty GET /answers response"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "PostgREST soft-delete guard: always chain .is('deleted_at', null) on compass_responses reads, never .eq()"
    - "API shape trust: type apiFetch<T> to the actual response shape, not a wrapper — validate against live response"

key-files:
  created: []
  modified:
    - backend/src/routes/compass.ts
    - backend/src/lib/adminService.ts
    - admin/src/pages/admin/CategoriesPage.tsx
    - admin/src/pages/admin/TopicsPage.tsx
    - admin/src/pages/admin/PoliticiansPage.tsx

key-decisions:
  - "Use .is('deleted_at', null) not .eq() — PostgREST requires IS NULL syntax for null comparisons"
  - "adminCreateTopic removed cleanly; adminCreateTopicWithStances (Phase 14 RPC wrapper) is the sole create path"

patterns-established:
  - "Soft-delete guard pattern: .is('deleted_at', null) chained after .select() or .in() on compass_responses"

# Metrics
duration: 4min
completed: 2026-03-07
---

# Phase 16 Plan 01: v1.2 Gap Closure — Bug Fixes Summary

**Five targeted v1.2 audit bugs closed: soft-delete filter on two read paths, CategoriesPage array shape mismatch, adminCreateTopic dead code, and five id type annotation corrections across three admin pages**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-03-07T17:36:02Z
- **Completed:** 2026-03-07T17:39:55Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- GET /compass/answers and POST /compass/answers/batch now filter soft-deleted rows with `.is('deleted_at', null)` — DELETE /answers/me is no longer cosmetic
- CategoriesPage fixed to consume `/compass/categories` as a plain array (not `{ categories: [] }`) — renders without runtime TypeError
- Removed `adminCreateTopic` direct-insert dead code from adminService.ts (superseded by `admin_create_topic_with_stances` RPC in Phase 14)
- All local `id`, `topic_id` fields in TopicsPage, CategoriesPage, and PoliticiansPage corrected from `number` to `string` (Supabase UUIDs)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add deleted_at filter to both compass response read paths** - `ee0575f` (fix)
2. **Task 2: Fix CategoriesPage response shape + remove adminCreateTopic dead code** - `27bcf6d` (fix)
3. **Task 3: Fix id type annotations in TopicsPage and PoliticiansPage** - `32a1501` (fix)

## Files Created/Modified
- `backend/src/routes/compass.ts` - Added `.is('deleted_at', null)` to GET /answers and POST /answers/batch queries
- `backend/src/lib/adminService.ts` - Deleted `adminCreateTopic` function (lines 259–285 of original)
- `admin/src/pages/admin/CategoriesPage.tsx` - Fixed response shape (plain array); fixed Category.id and Topic.id to string
- `admin/src/pages/admin/TopicsPage.tsx` - Fixed Stance.id, Topic.id, selectedId state, stanceEdits Record key to string
- `admin/src/pages/admin/PoliticiansPage.tsx` - Fixed Topic.id, Stance.id, Stance.topic_id, PoliticianAnswer.topic_id, topicStances Record key, handleStancesNeeded param, TopicAnswerRowProps.onStancesNeeded param, PoliticianDetailPanel props to string

## Decisions Made
- `.is('deleted_at', null)` used instead of `.eq('deleted_at', null)` — PostgREST generates IS NULL for `.is()` and incorrectly handles null comparisons with `.eq()`
- `adminCreateTopic` deleted entirely rather than kept as deprecated stub — no callers exist; the RPC path (`adminCreateTopicWithStances`) is the only correct creation path

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered
- The plan's verification `grep -c "adminCreateTopic"` returns 1 (not 0) because `adminCreateTopicWithStances` contains the substring. The standalone `adminCreateTopic` function is fully removed — the one count is the active RPC wrapper function.

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness
- All five v1.2 audit gaps from COMP2-01 and CADM-13 are closed
- CompassV2 frontend can now reliably use DELETE /compass/answers/me and see empty GET /compass/answers afterward
- CategoriesPage admin UI is unblocked (no runtime crash on load)
- Both backend/ and admin/ tsc --noEmit pass with zero errors
- Ready for remaining Phase 16 plans (if any) or v1.2 release prep

---
*Phase: 16-v12-gap-closure*
*Completed: 2026-03-07*
