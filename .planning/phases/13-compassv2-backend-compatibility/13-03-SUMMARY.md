---
phase: 13-compassv2-backend-compatibility
plan: "03"
subsystem: api
tags: [express, supabase, politicians, essentials, compassv2, public-endpoint]

# Dependency graph
requires:
  - phase: 13-01
    provides: "inform.politicians table with is_candidate column (migration 026)"
provides:
  - "GET /api/essentials/politicians — unauthenticated endpoint returning politicians grouped by office_title"
  - "essentialsService.ts lib with getPoliticiansGrouped() using supabaseAnon"
  - "PoliticianRecord and PoliticianGroup TypeScript interfaces"
affects:
  - compassv2-frontend
  - 13-04

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Service lib pattern: lib/essentialsService.ts mirrors lib/candidateService.ts — route imports service, service owns all DB access"
    - "supabaseAnon for inform schema public reference data (no RLS bypass needed)"
    - "as any cast for migration-added columns not yet in database.types.ts"

key-files:
  created:
    - backend/src/lib/essentialsService.ts
    - backend/src/routes/essentialsPoliticians.ts
  modified:
    - backend/src/index.ts

key-decisions:
  - "supabaseAnon (not supabaseAdmin) for politicians — public reference data, RLS sufficient, no bypass needed"
  - "is_candidate column cast via (supabaseAnon as any) — migration 026 adds column but database.types.ts not yet regenerated"
  - "Throw on DB error, never return silent empty array — matches plan contract"
  - "optionalAuth on route — endpoint is public, auth not required"
  - "Comments in new files must not contain the string 'supabaseAdmin' — architecture test does string match, not import scan"

patterns-established:
  - "essentialsService.ts: new lib file pattern for unauthenticated public endpoints — service owns supabaseAnon, route imports service"
  - "Grouping pattern: Map<office_title, PoliticianGroup> then sort non-null alphabetical first, null last"

# Metrics
duration: 4min
completed: 2026-03-06
---

# Phase 13 Plan 03: Essentials Politicians Endpoint Summary

**GET /api/essentials/politicians returns active politicians grouped by office_title via supabaseAnon, accessible without authentication, satisfying COMP2-02**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-06T21:35:22Z
- **Completed:** 2026-03-06T21:39:27Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Created `essentialsService.ts` with `getPoliticiansGrouped(includeCandidates)` — queries `inform.politicians` via `supabaseAnon`, groups by `office_title`, throws on DB error
- Created `essentialsPoliticians.ts` route with `optionalAuth`, `?include_candidates=true` query param support, and `{ code: 'INTERNAL_ERROR' }` error shape
- Mounted route at `/api/essentials/politicians` in `index.ts` after the existing candidates route
- Architecture test passes: neither new file references the service-role client

## Task Commits

Each task was committed atomically:

1. **Task 1: Create essentialsService.ts with getPoliticiansGrouped** - `f0fe914` (feat)
2. **Task 2: Create essentialsPoliticians route and mount in index.ts** - `34ea0d3` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `backend/src/lib/essentialsService.ts` - Service lib with `getPoliticiansGrouped()`, `PoliticianRecord`, `PoliticianGroup` types; uses `supabaseAnon` only
- `backend/src/routes/essentialsPoliticians.ts` - Express route for `GET /api/essentials/politicians` with `optionalAuth` and `?include_candidates` param
- `backend/src/index.ts` - Added import and mount for `essentialsPoliticiansRouter`

## Decisions Made
- `supabaseAnon` chosen over the service-role client — `inform.politicians` is public reference data, no user-owned fields, no RLS bypass required
- `is_candidate` field accessed via `(supabaseAnon as any)` cast because migration 026 adds the column but `database.types.ts` has not been regenerated yet; the cast is scoped to just the query builder, and normal `PoliticianRecord` types are used for all returned data
- Comments in new service files must not contain the literal string that identifies the service-role export — the architecture test uses `content.includes()` string matching (not import graph analysis), so JSDoc references trigger false positives
- `getPoliticiansGrouped` throws the Supabase error object on failure rather than returning an empty array — route catches and maps to `{ code: 'INTERNAL_ERROR', message: '...' }`

## Deviations from Plan

None — plan executed exactly as written.

One implementation detail required care: the plan specified `supabaseAnon` exclusively, but the initial JSDoc comment block in `essentialsService.ts` referenced the forbidden string in explanatory text. The architecture test scans file content with `includes()`, so the comment was reworded to avoid the match. This is a faithful implementation of the plan's constraint, not a deviation.

## Issues Encountered
None.

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness
- `GET /api/essentials/politicians` is live and mounted. CompassV2 can call this endpoint to render incumbent and challenger cards grouped by race.
- Requires migration 026 applied to live DB for `is_candidate` column to exist. Without it, the Supabase query will fail at runtime (the `(as any)` cast bypasses TypeScript but not the DB schema).
- 13-04 (batch answers + selected topics endpoints) can proceed independently — no dependency on this plan's output.

---
*Phase: 13-compassv2-backend-compatibility*
*Completed: 2026-03-06*
