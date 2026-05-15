---
phase: quick-021
plan: 01
subsystem: api
tags: [compass, candidates, elections, pool.query, express]

# Dependency graph
requires:
  - phase: quick-016/017 (CA SoS candidate ingestion)
    provides: essentials.race_candidates rows with politician_id links
  - phase: v1.0 (empower schema)
    provides: empower.empowered_profiles with politician_id FK
  - phase: v1.2 (compass_responses)
    provides: inform.compass_responses per-user answer rows
provides:
  - getCandidates() export in compassService.ts — active election candidates with compass answers
  - getCandidateAnswers(candidateId) export in compassService.ts — per-candidate answer lookup
  - GET /compass/candidates/:id/answers route (404 on missing)
  - GET /compass/politicians?include_candidates=true — merged incumbent + candidate array
affects:
  - CompassV2 compare UI — can now load candidate compass profiles
  - Any future election/candidate feature that needs compass alignment data

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Parallel Promise.all for merging two pool.query result sets in a single route handler"
    - "Three-step candidate→politician→user→answers lookup via pool.query() exclusively"
    - "Optional query param feature flag (include_candidates=true) for backward-compat route extension"

key-files:
  created: []
  modified:
    - backend/src/lib/compassService.ts
    - backend/src/routes/compass.ts

key-decisions:
  - "GET /politicians backward compat preserved — no param = unchanged response, no is_candidate/is_incumbent fields on existing incumbents unless include_candidates=true"
  - "Candidate route (/candidates/:id/answers) registered before /politicians routes to avoid Express :id param capture"
  - "getCandidateAnswers returns null (not empty array) on missing candidate — lets route return 404 vs 200 [] unambiguously"

patterns-established:
  - "Optional merge pattern: route checks query param, if false returns existing path unchanged, if true runs both queries in parallel and merges"

# Metrics
duration: 12min
completed: 2026-05-14
---

# Quick Task 021: Add Candidate Support to Compass Compare Summary

**Compass compare now supports election candidates via empowered_profile-linked compass answers — two new service functions and a new /candidates/:id/answers route with backward-compatible /politicians extension**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-05-14T00:00:00Z
- **Completed:** 2026-05-14T00:12:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Added `getCandidates()` to compassService.ts — queries `essentials.race_candidates` joined to elections/offices/districts, filters to active candidates with future election dates and at least one compass answer via empowered_profile, returns same shape as `getCompassPoliticians()` plus `is_candidate: true` and `is_incumbent`
- Added `getCandidateAnswers(candidateId)` — three-step pool.query() chain (race_candidates → politician_id → empowered_profiles → compass_responses), returns null on any missing link enabling clean 404 responses
- New `GET /compass/candidates/:id/answers` route with UUID validation and 404 for missing candidates
- Extended `GET /compass/politicians?include_candidates=true` to run both queries in parallel and merge, adding `is_candidate: false, is_incumbent: true` to incumbents

## Task Commits

1. **Task 1: Add getCandidates() and getCandidateAnswers() to compassService** - `ce2ef5d` (feat)
2. **Task 2: Wire routes in compass.ts** - `5eb3852` (feat)

**Plan metadata:** see below (docs commit)

## Files Created/Modified
- `backend/src/lib/compassService.ts` - Added getCandidates() and getCandidateAnswers() exports (~106 lines)
- `backend/src/routes/compass.ts` - Updated import, added /candidates/:id/answers route, extended /politicians handler (~62 lines)

## Decisions Made
- GET /politicians without param: returns exactly what it did before (no `is_candidate`/`is_incumbent` fields on rows) for strict backward compatibility
- Candidate route registered before all /politicians/* routes to prevent Express route matching "candidates" as a :id param value
- `getCandidateAnswers` returns null (not empty array) when candidate or empowered_profile not found — clean semantic distinction from "candidate exists but has no answers" (returns `[]`)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- CompassV2 compare UI can now request `GET /compass/politicians?include_candidates=true` to get a merged list
- `GET /compass/candidates/:id/answers` provides per-candidate compass data for side-by-side comparison
- No DB migration needed — queries existing essentials/empower/inform schema

---
*Phase: quick-021*
*Completed: 2026-05-14*
