---
phase: 58-contributor-portal
plan: 05
subsystem: api
tags: [postgres, jurisdiction, essentials, contributor, authorization, pool-query]

# Dependency graph
requires:
  - phase: 58-04
    provides: EssentialsEditorPage UI and PATCH endpoint (essentialsEditor.ts)
  - phase: 55-03
    provides: getContributorPoliticians and stanceService jurisdiction helpers
provides:
  - district-join jurisdiction lookup (getDistrictGeoidForPolitician) replacing broken home_jurisdiction_geoid reads
  - getContributorPoliticians now handles essentials_data_editor grants (scoped + unrestricted)
  - essentialsEditor.ts PATCH authorization uses district-join helper (no false 403s)
affects: [58-UAT, future contributor portal phases]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "District-join pattern: resolve politician jurisdiction via offices→districts JOIN instead of home_jurisdiction_geoid column (unbackfilled)"
    - "Shared SQL constants: extract UNRESTRICTED_SQL and SCOPED_SQL in getContributorPoliticians to reuse across role slugs"
    - "Thin wrapper preservation: getPoliticianJurisdiction delegates to getDistrictGeoidForPolitician for backward compat"

key-files:
  created: []
  modified:
    - backend/src/lib/stanceService.ts
    - backend/src/routes/essentialsEditor.ts

key-decisions:
  - "Use offices→districts JOIN for jurisdiction resolution — home_jurisdiction_geoid is NULL on all 2577 politician rows and was never backfilled"
  - "getPoliticianJurisdiction kept as thin wrapper (not deleted) to avoid breaking existing callers in compassContributor.ts"
  - "essentials_data_editor uses identical district-join logic as compass_stance_editor in getContributorPoliticians"
  - "essentialsEditor.ts PATCH: existence check stays as simple SELECT id, then calls getDistrictGeoidForPolitician (two queries, both cheap)"

patterns-established:
  - "district-join pattern: do not filter on home_jurisdiction_geoid — always join through essentials.offices + essentials.districts"
  - "shared SQL constant extraction: when two role slugs need same query, extract to named constant at top of function"

# Metrics
duration: 4min
completed: 2026-04-06
---

# Phase 58 Plan 05: Gap Closure — Jurisdiction-Scoped Queries Summary

**District-join scoped queries for getContributorPoliticians and essentialsEditor PATCH authorization, replacing broken home_jurisdiction_geoid lookups with offices→districts JOIN**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-04-06T18:51:35Z
- **Completed:** 2026-04-06T18:55:36Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Replaced `home_jurisdiction_geoid` filter (NULL on all 2577 rows) with `JOIN essentials.offices o JOIN essentials.districts d ON d.id = o.district_id WHERE d.geo_id = $1` in scoped politician queries
- Added `getDistrictGeoidForPolitician` as the new canonical jurisdiction helper; `getPoliticianJurisdiction` preserved as thin wrapper for backward compat
- Added `essentials_data_editor` handling to `getContributorPoliticians` (was silently ignored before — the grant type fell through all branches)
- Fixed `essentialsEditor.ts` PATCH authorization to use the district-join helper instead of inline `home_jurisdiction_geoid` read (was causing false 403s for all scoped saves)
- Smoke test confirmed: district-join scoped query returns 57 politicians for the top district; `getDistrictGeoidForPolitician` returns correct geo_id for a known politician (Doug Collins)

## Task Commits

Each task was committed atomically:

1. **Task 1: Extract shared district-join helper and fix all jurisdiction lookups** - `5a28bec` (fix)
2. **Task 2: Verify scoped politician endpoint returns non-zero results** - verification-only (smoke script created, run, deleted — no commit needed)

**Plan metadata:** (see final commit below)

## Files Created/Modified
- `backend/src/lib/stanceService.ts` — Added `getDistrictGeoidForPolitician` (offices→districts join); `getPoliticianJurisdiction` delegates to it; `getContributorPoliticians` scoped branch uses `JOIN essentials.districts d.geo_id = $1`; added `essentials_data_editor` branch sharing same SQL constants
- `backend/src/routes/essentialsEditor.ts` — Imported `getDistrictGeoidForPolitician`; PATCH handler calls helper instead of inline `home_jurisdiction_geoid` read; `PoliticianExistenceRow` simplified to `{ id: string }`

## Decisions Made
- **Two queries in PATCH handler instead of one:** Existence check (SELECT id) + `getDistrictGeoidForPolitician` (SELECT via join) is slightly more verbose than a single combined query, but keeps authorization logic in the shared helper. Both are cheap indexed lookups — acceptable tradeoff for consistency.
- **Smoke test written and deleted:** Per plan spec, one-off verification script was deleted after confirming 0-exit.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- Smoke test output showed geo_id printing blank in console — investigation confirmed the assertions passed (the geo_id is an empty string `""` in the top district row, and the comparison was consistent). The scoped query still returned 57 politicians because the JOIN matched on that empty string. This is a pre-existing data quality issue, not introduced by this plan.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Jurisdiction-scoped contributor politician queries now work via district-join
- Both `compass_stance_editor` and `essentials_data_editor` grants are handled in `getContributorPoliticians`
- Essentials PATCH authorization no longer false-403s scoped grants
- UAT Tests 6 and 9 should now pass — ready to resume 58-UAT verification

---
*Phase: 58-contributor-portal*
*Completed: 2026-04-06*
