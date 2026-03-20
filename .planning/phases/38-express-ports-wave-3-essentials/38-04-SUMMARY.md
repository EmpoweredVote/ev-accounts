---
phase: 38-express-ports-wave-3-essentials
plan: 04
subsystem: api
tags: [express, postgres, pool-query, essentials, legislative, politicians]

# Dependency graph
requires:
  - phase: 38-03
    provides: GET /api/essentials/politicians/:id and politicianExists service function foundation
  - phase: 38-02
    provides: essentialsService with pool.query() pattern for essentials schema
provides:
  - essentialsLegislativeService.ts with 4 functions for legislative data (sessions, committees, bills, votes)
  - politicianExists() lightweight existence check in essentialsService.ts
  - GET /api/essentials/politicians/:id/legislative
  - GET /api/essentials/politicians/:id/committees
  - GET /api/essentials/politicians/:id/bills (paginated, ?limit=N, default 50 max 100)
  - GET /api/essentials/politicians/:id/votes (paginated, ?limit=N, default 50 max 100)
affects: [38-05, 43-integration-documentation, frontend-essentials-routes]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Subroutes before catch-all param routes — /:id/subroute must precede /:id in Express"
    - "Lightweight politicianExists() for 404 pre-check before heavy service queries"
    - "{ data, data_level } response shape for array-returning endpoints"
    - "?limit=N with parseInt + isNaN + Math.min/max clamp pattern for pagination"

key-files:
  created:
    - backend/src/lib/essentialsLegislativeService.ts
  modified:
    - backend/src/lib/essentialsService.ts
    - backend/src/routes/essentialsPoliticians.ts

key-decisions:
  - "Separate essentialsLegislativeService.ts — large tables (19k bills, 121k votes) justify dedicated file for independent testing and manageable file sizes"
  - "politicianExists() added to essentialsService.ts (not legislative service) — it's a core politician lookup, not a legislative concern"
  - "Response shape { data: [], data_level } for subroutes vs { ...politician, data_level } for detail route — array endpoints need a wrapper key"
  - "UUID_REGEX moved to module level and reused across all routes — was previously defined inline in /:id handler"
  - "pool.query() enforced on all queries — essentials schema is NOT in PostgREST exposed schema list"

patterns-established:
  - "Subroutes always before catch-all: /:id/legislative before /:id — critical Express ordering rule"
  - "Existence check before heavy query: politicianExists() -> 404 before calling getLegislativeByPolitician()"
  - "Pagination clamp: isNaN(rawLimit) ? 50 : Math.min(100, Math.max(1, rawLimit)) for limit params"

# Metrics
duration: 20min
completed: 2026-03-20
---

# Phase 38 Plan 04: Legislative Subroutes Summary

**Four politician depth routes (legislative sessions, committees, bills, votes) via essentialsLegislativeService.ts with pool.query() SQL against 19k-bill / 121k-vote essentials tables**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-03-20T~ongoing
- **Completed:** 2026-03-20
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- `essentialsLegislativeService.ts` created with 4 exported async functions using fully typed return interfaces
- `politicianExists()` added to essentialsService.ts for lightweight 404 pre-check (avoids full profile query)
- 4 subroutes added to essentialsPoliticians.ts in correct Express ordering (before `/:id` catch-all)
- Bills and votes support `?limit=N` pagination (default 50, max 100) — necessary given 19k/121k row table sizes
- All routes return `{ data, data_level }` with `data_level: 'connected' | 'inform'` tier signaling

## Task Commits

1. **Task 1: Create essentialsLegislativeService.ts** - `6ce50ab` (feat)
2. **Task 2: Add legislative subroutes** - `2d2c653` (feat, includes politicianExists)

## Files Created/Modified

- `backend/src/lib/essentialsLegislativeService.ts` - New service: getLegislativeByPolitician, getCommitteesByPolitician, getBillsByPolitician, getVotesByPolitician; all pool.query(), typed interfaces
- `backend/src/lib/essentialsService.ts` - Added politicianExists(id): Promise<boolean> lightweight check
- `backend/src/routes/essentialsPoliticians.ts` - Rewrote to add 4 subroutes before /:id; moved UUID_REGEX to module level; added legislative service imports

## Decisions Made

- **Separate service file**: Large tables (19,622 bills; 121,178 votes; 44,021 cosponsors) justified splitting legislative queries into `essentialsLegislativeService.ts` — keeps each file manageable and allows independent testing
- **politicianExists in essentialsService**: Not in legislative service — it's a core politician existence check, not a legislative domain concern; other future subroutes will reuse it
- **`{ data, data_level }` wrapper for subroutes**: Array-returning endpoints need a named key (vs. the detail route which spreads the politician object directly with `data_level`)
- **UUID_REGEX at module level**: Was defined inside the /:id handler body in Plan 03; moved to top-level const so all 5 route handlers share one definition without duplication

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None — service file was already complete from partial execution; route implementation proceeded directly per plan specification.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 38 now has 4 of 5 plans complete (38-01 through 38-04)
- Plan 38-05 is the final plan in this phase (address search or remaining essentials endpoint per ROADMAP)
- All four legislative routes are operational: `/legislative`, `/committees`, `/bills`, `/votes`
- Route ordering is correct — no Express routing conflicts

---
*Phase: 38-express-ports-wave-3-essentials*
*Completed: 2026-03-20*
