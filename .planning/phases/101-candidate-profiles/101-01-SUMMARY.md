---
phase: 101-candidate-profiles
plan: 01
subsystem: api
tags: [typescript, express, postgresql, postgis, election, candidates]

# Dependency graph
requires:
  - phase: 99-election-central-page
    provides: elections API and race_candidates table with candidate_status, politician_id
  - phase: 98-election-data-import
    provides: essentials.races, essentials.elections, essentials.race_candidates schema and data
provides:
  - GET /api/essentials/race-candidates/:id endpoint returning CandidateDetail with nullable politician_id
  - getCandidateById() service function in electionService.ts
  - CI-safe integration tests verifying route wiring and UUID validation
affects:
  - 101-02 (frontend CandidateProfile.jsx — consumes this endpoint to resolve candidate UUID to detail + politician_id)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Route-before-UUID_RE pattern: UUID_RE declared immediately after router = Router() so all route handlers can reference it"
    - "getCandidateById with LATERAL JOIN for incumbent photo enrichment — consistent with getElectionsByCoordinate pattern"
    - "CI-safe tests: [404, 500] union check for DB-dependent paths with no live DB"

key-files:
  created: []
  modified:
    - ev-accounts/backend/src/lib/electionService.ts
    - ev-accounts/backend/src/routes/essentials.ts
    - ev-accounts/tests/integration/essentials-elections.test.ts

key-decisions:
  - "UUID_RE moved to top of essentials.ts (after router declaration) so new race-candidates route can reference it without forward-reference issue"
  - "CandidateDetail interface includes election_date and election_type for frontend context display without a second fetch"

patterns-established:
  - "Candidate lookup: getCandidateById excludes withdrawn candidates via candidate_status != 'withdrawn' at SQL layer"

requirements-completed: [PROF-01]

# Metrics
duration: 15min
completed: 2026-03-30
---

# Phase 101 Plan 01: Candidate Profile API Summary

**GET /api/essentials/race-candidates/:id endpoint with CandidateDetail shape including nullable politician_id linkage for incumbent/challenger disambiguation**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-03-30T20:20:00Z
- **Completed:** 2026-03-30T20:37:58Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Added `CandidateDetail` interface and `getCandidateById()` to `electionService.ts` with LATERAL JOIN photo enrichment and withdrawn-candidate filtering
- Wired `GET /race-candidates/:id` route in `essentials.ts` with UUID validation (422), 404 for missing/withdrawn, 500 for server errors
- Moved `UUID_RE` declaration to top of router file to support new route (previously only used by routes at lines 285+)
- Added 4 CI-safe integration tests covering 422 validation, 404/500 for unknown UUID, and JSON content-type assertion

## Task Commits

Each task was committed atomically:

1. **Task 1: Add getCandidateById to electionService.ts and wire route in essentials.ts** - `17344e4` (feat)
2. **Task 2: Add integration tests for race-candidates endpoint** - `95beabf` (test)

**Plan metadata:** (docs commit below)

## Files Created/Modified
- `ev-accounts/backend/src/lib/electionService.ts` - Added `CandidateDetail` interface and `getCandidateById()` function
- `ev-accounts/backend/src/routes/essentials.ts` - Added `GET /race-candidates/:id` route, moved `UUID_RE` to top, updated import
- `ev-accounts/tests/integration/essentials-elections.test.ts` - Added 4 CI-safe tests for new endpoint

## Decisions Made
- `UUID_RE` moved from line 271 to immediately after `const router = Router()` — existing routes at lines 285+ use it unaffected, new route at top of file now can too
- `CandidateDetail` includes `position_name`, `election_date`, `election_type` so the frontend can display race context without a second fetch to the elections endpoint

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None. The pre-existing test failures in `gems.test.ts`, `compass.test.ts`, `architecture.test.ts`, and `env-validation.test.ts` are unrelated to this plan's changes and were present before execution.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `GET /api/essentials/race-candidates/:id` endpoint is live in `ev-accounts`
- Plan 101-02 can now build `CandidateProfile.jsx` on top of this endpoint — the URL `:id` param is a `race_candidates.id`, resolved here to candidate detail + optional `politician_id`
- No blockers for 101-02

---
*Phase: 101-candidate-profiles*
*Completed: 2026-03-30*

## Self-Check: PASSED

- electionService.ts: FOUND
- essentials.ts: FOUND
- essentials-elections.test.ts: FOUND
- 101-01-SUMMARY.md: FOUND
- Commit 17344e4: FOUND
- Commit 95beabf: FOUND
