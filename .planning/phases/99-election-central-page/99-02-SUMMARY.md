---
phase: 99-election-central-page
plan: "02"
subsystem: ui
tags: [react, elections, frontend, essentials, tailwind]

requires:
  - phase: 99-01
    provides: GET /api/essentials/elections-by-address endpoint with geofence + statewide matching

provides:
  - Elections page at /elections in essentials.empowered.vote
  - fetchElectionsByAddress() in essentials api.jsx
  - Address-driven election discovery with race/candidate grouping

affects: [essentials, election-central-page]

tech-stack:
  added: []
  patterns:
    - "publicFetch for public endpoints (no auth required)"
    - "classifyCategory(district_type) for tier grouping in election context"
    - "Antipartisan: election_type shown generically (Primary Election), never party name"

key-files:
  created:
    - "essentials/src/pages/Elections.jsx"
  modified:
    - "essentials/src/lib/api.jsx"
    - "essentials/src/App.jsx"

key-decisions:
  - "publicFetch used (not apiFetch) — elections data is public, no auth required"
  - "Reused classifyCategory() with {district_type} duck-typed object for tier grouping"
  - "Antipartisan: primary_party field never shown; election_type shown as 'Primary Election' / 'General Election'"
  - "Empty elections return graceful empty state (not error) per backend contract"

requirements-completed: []

duration: 3min
completed: 2026-03-30
---

# Phase 99 Plan 02: Election Central Page Frontend — Summary

**Elections page in essentials app: address input → fetchElectionsByAddress() → grouped races/candidates by Federal/State/Local tier**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-30T01:08:31Z
- **Completed:** 2026-03-30T01:11:06Z (checkpoint pending human verify)
- **Tasks:** 2 of 3 complete (Task 3 at checkpoint)
- **Files modified:** 3

## Accomplishments

- `fetchElectionsByAddress(address)` added to essentials api.jsx — uses publicFetch, handles 503 gracefully
- `Elections.jsx` page created with address form, loading/empty/error states, elections grouped by tier
- Route `/elections` wired into App.jsx router
- Build passes cleanly (no TypeScript or JS errors)

## Task Commits (in essentials repo)

1. **Task 1: fetchElectionsByAddress API function** - `92460ca` (feat)
2. **Task 2: Elections page component** - `970ba27` (feat)
3. **Task 3 (partial): Wire route into App.jsx** - `fbca6b4` (feat) — awaiting human verify

## Files Created/Modified

- `essentials/src/pages/Elections.jsx` - Election Central page with address form, election/race/candidate display
- `essentials/src/lib/api.jsx` - Added `fetchElectionsByAddress()` function
- `essentials/src/App.jsx` - Added Elections import and `/elections` route

## Decisions Made

- **publicFetch for elections**: Elections data is public (no auth required per backend contract using `optionalAuth`). Used `publicFetch` not `apiFetch` to avoid redirect loops.
- **classifyCategory() reuse**: The existing `classifyCategory()` function takes any object with `district_type`. Pass `{ district_type: race.district_type, office_title: race.position_name }` to get tier grouping.
- **Antipartisan enforcement**: `primary_party` field from API never rendered. Election type shown as "Primary Election" / "General Election" — no party labels anywhere.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - build passes cleanly.

## CHECKPOINT PENDING

Task 3 is at a `checkpoint:human-verify` gate. The route has been wired (commit `fbca6b4`). Human must:
1. Start dev server: `cd essentials && npm run dev`
2. Navigate to `http://localhost:5173/elections`
3. Confirm address form renders
4. Enter address and verify elections list or empty state appears
5. Confirm no console errors

## Next Phase Readiness

- `/elections` route live in essentials app
- Backend `GET /api/essentials/elections-by-address` already deployed (phase 99-01)
- After human verify: plan 02 complete, phase 99 done

---
*Phase: 99-election-central-page*
*Completed: 2026-03-30 (pending human verify)*

## Self-Check: PASSED

- FOUND: essentials/src/pages/Elections.jsx
- FOUND: essentials/src/lib/api.jsx (with fetchElectionsByAddress)
- FOUND: essentials/src/App.jsx (with /elections route)
- Commits verified: 92460ca, 970ba27, fbca6b4 in essentials repo
- Build passes: vite build succeeds with no errors
