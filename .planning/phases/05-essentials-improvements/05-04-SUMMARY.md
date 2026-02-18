---
phase: 05-essentials-improvements
plan: 04
subsystem: api
tags: [go, ballotready, graphql, candidates, elections, essentials]

# Dependency graph
requires:
  - phase: 05-essentials-improvements
    provides: essentials module structure and BallotReady client infrastructure

provides:
  - GET /essentials/candidates/{zip} endpoint returning upcoming election candidates
  - CandidateOut DTO with district_type compatible with frontend classify.js
  - FetchRacesByZip BallotReady GraphQL function with pagination
  - levelToDistrictType helper mapping BallotReady level enum to internal district type

affects:
  - 05-05 (frontend candidate display will consume this endpoint)
  - essentials frontend (classify.js can process CandidateOut.district_type)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Races query uses electionDayGte=today to filter only future elections"
    - "Type names prefixed (RaceNode, CandidacyNode) to avoid conflicts with Phase B candidacy types"
    - "Graceful degradation: empty array returned on BallotReady error or when provider unavailable"

key-files:
  created: []
  modified:
    - EV-Backend/internal/essentials/ballotready/types.go
    - EV-Backend/internal/essentials/ballotready/client.go
    - EV-Backend/internal/essentials/handlers.go
    - EV-Backend/internal/essentials/routes.go

key-decisions:
  - "Used distinct type names (RaceNode, CandidacyNode, etc.) instead of conflicting with existing Race/Candidacy types from Phase B"
  - "Handler uses Provider.(*ballotready.BallotReadyProvider) type assertion consistent with existing handler patterns"
  - "levelToDistrictType uses position name keyword matching (senate/house/assembly) for sub-level discrimination within FEDERAL/STATE"
  - "Page size for races query set to 50 (smaller than officeHolders 100) since races can have many candidacies per node"

patterns-established:
  - "Candidates endpoint: live BallotReady fetch (no caching layer) since race data changes frequently near elections"

requirements-completed: [ESST-01, ESST-03]

# Metrics
duration: 4min
completed: 2026-02-18
---

# Phase 5 Plan 04: Candidates Endpoint Summary

**GET /essentials/candidates/{zip} endpoint fetching upcoming election candidates from BallotReady races query with classify.js-compatible district_type field**

## Performance

- **Duration:** 4 min
- **Started:** 2026-02-18T17:01:04Z
- **Completed:** 2026-02-18T17:05:17Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Added racesByZipQuery GraphQL constant and FetchRacesByZip client method with cursor-based pagination
- Added 8 new types (RaceNode, CandidacyNode, RacePositionNode, RaceElectionNode, CandidacyParty, CandidacyPerson, CandidacyImage, RacesQueryResponse/Data/Connection) avoiding conflicts with existing Phase B types
- Added CandidateOut DTO, levelToDistrictType helper, GetCandidatesByZip handler, and route registration
- Backend compiles cleanly; endpoint returns empty array on error or when BallotReady unavailable

## Task Commits

Each task was committed atomically:

1. **Task 1: Add BallotReady races query and FetchRacesByZip** - `f9168d9` (feat)
2. **Task 2: Create CandidateOut DTO, handler, and route** - `e826385` (feat)

**Plan metadata:** (docs commit below)

## Files Created/Modified
- `EV-Backend/internal/essentials/ballotready/types.go` - Added 8 Phase D race/candidacy types
- `EV-Backend/internal/essentials/ballotready/client.go` - Added racesByZipQuery constant and FetchRacesByZip method
- `EV-Backend/internal/essentials/handlers.go` - Added CandidateOut DTO, levelToDistrictType helper, GetCandidatesByZip handler
- `EV-Backend/internal/essentials/routes.go` - Registered GET /candidates/{zip} route

## Decisions Made
- Used prefixed type names (RaceNode, CandidacyNode) to avoid conflicts with Phase B's Race/Candidacy types that serve the candidacy history query
- Followed existing Provider.(*ballotready.BallotReadyProvider) type assertion pattern from other handlers (ensureCandidacyData, warmLocal, SearchPoliticians)
- levelToDistrictType uses keyword matching on position name for sub-level determination (senate/senator → UPPER, house/representative/assembly → LOWER) since BallotReady only provides broad level (FEDERAL/STATE/LOCAL)

## Deviations from Plan

None - plan executed exactly as written, with one naming adaptation: used `RaceNode`/`CandidacyNode` etc. instead of plan's `Race`/`Candidacy` to avoid conflict with existing types. The plan's `IMPORTANT` note on checking existing patterns was followed — `DefaultClient()` does not exist; the actual pattern is `Provider.(*ballotready.BallotReadyProvider).Client()`.

## Issues Encountered
- EV-Backend is its own git repository (inside a multi-repo workspace), requiring commits via `cd EV-Backend && git commit` rather than the workspace root git. Identified and handled correctly.

## Next Phase Readiness
- GET /essentials/candidates/{zip} is live and ready for frontend consumption (05-05)
- CandidateOut.district_type maps directly to classify.js tier system
- Endpoint returns is_candidate: true on all records for frontend filtering

---
*Phase: 05-essentials-improvements*
*Completed: 2026-02-18*
