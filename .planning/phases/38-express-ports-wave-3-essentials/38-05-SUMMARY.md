---
phase: 38-express-ports-wave-3-essentials
plan: "05"
subsystem: api
tags: [express, postgresql, pool-query, essentials-schema, go-parity, cons-11]

# Dependency graph
requires:
  - phase: 38-02
    provides: address-search route and essentials router mounted in index.ts
  - phase: 38-04
    provides: legislative subroutes and politicianExists helper
provides:
  - getGovernmentById service function with nested chambers list
  - getChamberById service function with parent government context
  - getDistrictById service function with active politicians, chamber, government
  - GET /api/essentials/governments/:id route (422 UUID guard, 404, data_level)
  - GET /api/essentials/chambers/:id route (422 UUID guard, 404, data_level)
  - GET /api/essentials/districts/:id route (422 UUID guard, 404, data_level)
  - Complete essentials route inventory documented in index.ts
  - CONS-11 fulfilled — all essentials routes served by ev-accounts Express API
affects: [39-compass-additions, 40-frontend-auth-updates, 43-integration-documentation]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "UUID regex validation before service call — /^[0-9a-f]{8}-...$/i → 422 VALIDATION_ERROR"
    - "Shared UUID_RE constant within route file for entity routes"
    - "Promise.all parallel queries for government+chambers (govenmentById) to reduce latency"
    - "Separate sequential query for district politicians (avoids cross-join with district row)"

key-files:
  created: []
  modified:
    - backend/src/lib/essentialsService.ts
    - backend/src/routes/essentials.ts
    - backend/src/index.ts

key-decisions:
  - "getDistrictById uses two separate queries (district+context, then politicians) to avoid Cartesian product when a district has multiple politicians mapped via multiple offices"
  - "GovernmentDetail nested chambers fetched via Promise.all parallel to base query for latency"
  - "ChamberDetail fetches government via JOIN in single query (1:1 relationship)"
  - "UUID regex constant shared across all three entity routes within essentials.ts"
  - "Route inventory comment block added to index.ts for CONS-11 documentation"

patterns-established:
  - "Entity route pattern: optionalAuth → UUID validation → service call → null=404 → data_level spread"
  - "All entity null strings coerced to '' per Go convention"

# Metrics
duration: 3min
completed: 2026-03-20
---

# Phase 38 Plan 05: Governments, Chambers, Districts Entity Routes Summary

**Three entity detail routes (governments/:id, chambers/:id, districts/:id) completing CONS-11 — all 11 essentials routes now served by ev-accounts Express API with no Go server dependency**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-20T19:57:22Z
- **Completed:** 2026-03-20T20:00:37Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- `getGovernmentById` — fetches government (id, name, type, state, city) with nested chambers list via Promise.all parallel queries
- `getChamberById` — fetches chamber with parent government context via single JOIN query
- `getDistrictById` — fetches district with active politicians (separate query to avoid Cartesian product), chamber, and government context
- Three entity routes added to essentials.ts — all with UUID validation, 404 for missing, data_level signaling
- Route inventory comment block in index.ts documenting all 11 essentials routes with CONS-11 fulfillment note
- CONS-11 fulfilled: ev-accounts Express API serves all essentials routes; Go server no longer required for any essentials data

## Complete Essentials Route Inventory (Phase 38 complete)

| Route | Plan | Notes |
|-------|------|-------|
| GET /api/essentials/candidates/:zip | 38-02 | ZIP → politicians list |
| GET /api/essentials/politicians | 38-02 | Flat list, Go-parity shape |
| GET /api/essentials/politicians/:id/legislative | 38-04 | Sessions reachable via bills/votes |
| GET /api/essentials/politicians/:id/committees | 38-04 | Committee memberships |
| GET /api/essentials/politicians/:id/bills | 38-04 | Paginated, sponsor+cosponsor |
| GET /api/essentials/politicians/:id/votes | 38-04 | Paginated voting record |
| GET /api/essentials/politicians/:id | 38-03 | Full profile with nested data |
| GET /api/essentials/address-search | 38-02 | Census Geocoder + PostGIS |
| GET /api/essentials/governments/:id | **38-05** | With nested chambers list |
| GET /api/essentials/chambers/:id | **38-05** | With parent government |
| GET /api/essentials/districts/:id | **38-05** | With politicians, chamber, government |

## Task Commits

Each task was committed atomically:

1. **Task 1: Add entity service functions + entity routes** - `218a5cd` (feat)
2. **Task 2: Register essentials router in index.ts + verify route inventory** - `1c63542` (feat)

**Plan metadata:** (included in STATE.md + docs commit)

## Files Created/Modified

- `backend/src/lib/essentialsService.ts` — Added GovernmentDetail, GovernmentSummary, ChamberDetail, DistrictDetail, DistrictPoliticianSummary, ChamberSummary interfaces + 3 exported async functions
- `backend/src/routes/essentials.ts` — Added UUID_RE constant + 3 entity GET routes (governments, chambers, districts)
- `backend/src/index.ts` — Added route inventory comment block documenting CONS-11 fulfillment and all 11 essentials routes

## Decisions Made

- **getDistrictById uses two separate queries** — base district+context query first (with LIMIT 1 to avoid duplication when district has multiple offices), then separate politicians query by district_id. Avoids Cartesian product that would arise from JOINing politicians in the same query as the district row.
- **Promise.all for getGovernmentById** — government and chambers fetched in parallel (two independent queries) to minimize latency. ChamberById uses single JOIN query since government is 1:1.
- **UUID_RE shared constant** — single regex constant at top of entity route block, referenced by all three routes. Not imported from a shared module (not worth the overhead for three routes in one file).
- **governments table has no is_elected or election_frequency** — confirmed from Phase 38 Plan 03 research; election_frequency lives on chambers, is_elected derived from offices.is_appointed_position.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- **Phase 38 complete** — CONS-11 fulfilled. All 11 essentials routes operational in ev-accounts Express API.
- **Phase 39 (Compass Additions)** — CONS-12 and CONS-13 ready to implement. No blockers from Phase 38.
- **Integration documentation note** — when Phase 43 produces integration docs for Chris Andrews' team, the complete essentials route inventory is documented in `backend/src/index.ts` at the essentials mount block.
- **Essentials XP provisioning** — still deferred to v1.7 (`essentials-rep-lookup` XP source not yet in `serviceKeyAuth.ts`); not blocking Phase 39.

---
*Phase: 38-express-ports-wave-3-essentials*
*Completed: 2026-03-20*
