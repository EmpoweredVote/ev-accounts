---
phase: 35-politician-deduplication
plan: 02
subsystem: api
tags: [typescript, pool-query, essentials, inform, politicians, postgrest]

# Dependency graph
requires:
  - phase: 35-politician-deduplication-plan-01
    provides: inform.politicians dropped; essentials.politicians is unified source of truth; FK reassignment complete

provides:
  - compassService.getCompassPoliticians() reads from essentials.politicians via pool.query()
  - essentialsService.getPoliticiansGrouped() reads from essentials.politicians via pool.query()
  - adminService.adminCreatePolitician() writes to essentials.politicians via pool.query()
  - adminService.adminUpdatePolitician() writes to essentials.politicians via pool.query()
  - adminService.adminSetPoliticianContext() uses pool.query() (PostgREST anti-pattern eliminated)
  - seedPoliticians.ts targets essentials.politicians and compiles cleanly

affects:
  - 38-express-ports-wave3-essentials (essentials schema not PostgREST-exposed; all reads must use pool.query())
  - frontend CompassV2 (GET /compass/politicians response no longer includes office_title; returns essentials-native fields)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "pool.query() for essentials schema reads: essentials is not in PostgREST exposed schemas; direct SQL required for all reads"
    - "essentials.politicians full_name is regular column (not GENERATED) — must be provided on insert"

key-files:
  created: []
  modified:
    - backend/src/lib/compassService.ts
    - backend/src/lib/essentialsService.ts
    - backend/src/lib/adminService.ts
    - scripts/seedPoliticians.ts

key-decisions:
  - "essentials schema is NOT in PostgREST exposed schema list — supabaseAnon.schema('essentials') fails at runtime; must use pool.query() for all essentials reads and writes"
  - "PoliticianRecord interface updated: removed inform-specific columns (office_title, district_type, is_candidate, representing_city, etc.); added essentials-native columns (party, is_incumbent, slug, bio_text)"
  - "getPoliticiansGrouped() grouping changed from office_title to party (essentials has no office_title)"
  - "adminCreatePolitician auto-derives full_name from first+last if not provided (essentials full_name is a regular column)"
  - "seedPoliticians.ts seed records updated: added full_name, removed all inform-specific district/chamber columns, added essentials columns"

patterns-established:
  - "essentials schema not PostgREST-exposed: use pool.query() for ALL essentials reads and writes — no supabaseAnon.schema('essentials') anywhere"
  - "Dynamic UPDATE with pool.query(): build SET clauses from Object.entries(data), parameterize values array, append WHERE id = $N"

# Metrics
duration: 12min
completed: 2026-03-20
---

# Phase 35 Plan 02: Politician Deduplication Summary

**All application code migrated from inform.politicians to essentials.politicians via pool.query(); PostgREST anti-pattern eliminated from adminSetPoliticianContext; essentials schema confirmed not PostgREST-exposed**

## Performance

- **Duration:** 12 min
- **Started:** 2026-03-20T05:43:28Z
- **Completed:** 2026-03-20T05:56:09Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Migrated `getCompassPoliticians()` and `getPoliticiansGrouped()` to query `essentials.politicians` via `pool.query()` instead of `supabaseAnon.schema('inform')`
- Migrated `adminCreatePolitician()` and `adminUpdatePolitician()` to write to `essentials.politicians` via `pool.query()`
- Eliminated the PostgREST anti-pattern in `adminSetPoliticianContext()` — now uses `pool.query()` with proper upsert SQL against `inform.politician_context`
- Updated `PoliticianRecord` interface and `PoliticianGroup` type to reflect essentials-native columns
- Updated `seedPoliticians.ts` to target `essentials.politicians` with correct column set
- Zero TypeScript compilation errors across all 4 modified files

## Task Commits

Each task was committed atomically:

1. **Task 1: compassService.ts + essentialsService.ts** — `958f467` (feat)
2. **Task 2: adminService.ts — schema switch + PostgREST fix** — `fb3559f` (feat)
3. **Task 3: seedPoliticians.ts** — `534fad7` (chore)

**Plan metadata:** (docs commit below)

## Files Created/Modified

- `backend/src/lib/compassService.ts` — `getCompassPoliticians()` switched to `pool.query()` targeting `essentials.politicians`; removed `office_title` from SELECT (not in essentials)
- `backend/src/lib/essentialsService.ts` — `getPoliticiansGrouped()` switched to `pool.query()` targeting `essentials.politicians`; `PoliticianRecord` and `PoliticianGroup` interfaces updated; grouping now by `party` instead of `office_title`; import changed from `supabaseAnon` to `pool`
- `backend/src/lib/adminService.ts` — `adminCreatePolitician()` and `adminUpdatePolitician()` write to `essentials.politicians` via `pool.query()`; `adminSetPoliticianContext()` PostgREST replaced with `pool.query()` INSERT ... ON CONFLICT DO UPDATE
- `scripts/seedPoliticians.ts` — Schema changed from `inform` to `essentials`; seed records updated with `full_name` (regular column), essentials columns added, inform-specific columns removed; JSDoc updated to note legacy status

## Decisions Made

- **essentials schema not PostgREST-exposed:** Discovered during TypeScript compile that `supabaseAnon.schema('essentials')` fails — `essentials` is not in the PostgREST exposed schema list (`public, connect, empower, inform, graphql_public, validation_quests`). All essentials reads must use `pool.query()` directly. This is the correct pattern anyway per project architecture (pool.query for non-public writes), and now applies to reads as well.
- **PoliticianGroup grouping changed to party:** `essentials.politicians` has no `office_title` column. The grouping key for `getPoliticiansGrouped()` was changed from `office_title` to `party`. This is a response shape change for `GET /api/essentials/politicians` — consuming frontend code will need to handle `{ party, incumbent, candidates }` instead of `{ office_title, incumbent, candidates }`.
- **is_candidate → is_incumbent:** essentials has `is_incumbent` boolean instead of `is_candidate`. The non-candidate filter was updated to `is_incumbent = true`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] essentials schema not exposed via PostgREST — supabaseAnon.schema('essentials') fails**

- **Found during:** Task 1 (TypeScript compilation)
- **Issue:** Plan specified changing `.schema('inform')` to `.schema('essentials')` using `supabaseAnon`. TypeScript immediately reported `'essentials'` is not assignable to `"public" | "connect" | "empower" | "inform"`. Confirmed at runtime: REST API returns "The schema must be one of the following: public, connect, empower, inform, graphql_public, validation_quests".
- **Fix:** Converted both `getCompassPoliticians()` and `getPoliticiansGrouped()` to use `pool.query()` with direct SQL against `essentials.politicians`. This is actually more correct than the plan's proposed approach — it follows the established pool.query() pattern for non-public schemas.
- **Files modified:** `backend/src/lib/compassService.ts`, `backend/src/lib/essentialsService.ts`
- **Verification:** TypeScript compiles cleanly; no PostgREST calls remain for essentials schema
- **Committed in:** `958f467`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The supabaseAnon approach was never viable — essentials isn't exposed via PostgREST. Switching to pool.query() is the correct fix and consistent with the established architecture pattern. No scope creep.

## Issues Encountered

None beyond the PostgREST exposure issue documented above.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Phase 35 is now complete: `essentials.politicians` is the sole source of truth, all application code points to it, and the PostgREST anti-pattern is eliminated
- **Important note for Phase 36+ (essentials routes):** The essentials schema is not PostgREST-exposed — all essentials reads AND writes must use `pool.query()`. Do not attempt `supabaseAdmin.schema('essentials')` or `supabaseAnon.schema('essentials')` anywhere.
- **Response shape change:** `GET /api/essentials/politicians` now returns `{ party, incumbent, candidates }` groups instead of `{ office_title, incumbent, candidates }`. Frontend consuming this endpoint needs updating.
- `inform.politician_answers` and `inform.politician_context` remain in the inform schema and are correctly untouched

---
*Phase: 35-politician-deduplication*
*Completed: 2026-03-20*
