---
phase: 92-schema-foundation-bloomington-migration
plan: "03"
subsystem: ui
tags: [treasury-tracker, react, dataLoader, api-only, error-state]

requires:
  - phase: 92-01
    provides: municipality-api-routes

provides:
  - api-only-data-loader
  - error-state-with-retry-button

affects: [treasury-tracker-frontend, phase-93-import-scripts]

tech-stack:
  added: []
  patterns: [api-only-fetch-no-fallback, throw-on-api-failure]

key-files:
  created: []
  modified:
    - treasury-tracker/src/data/dataLoader.ts
    - treasury-tracker/src/App.tsx

key-decisions:
  - "API is the sole data source — dataLoader.ts throws on failure instead of silently falling back to JSON or placeholder data (D-06)"
  - "listCities renamed to listMunicipalities calling /treasury/municipalities (aligns with Plan 01 backend rename)"
  - "App.tsx .catch sets setBudgetData(null) so error state renders — previously loading never showed error UI"
  - "Loading guard fix: if (loading || !operatingBudgetData) was blocking error state — removed operatingBudgetData dependency and added null-setting in totals catch block"

patterns-established:
  - "Pattern: loadBudgetData throws Error on non-ok response; callers handle via .catch → setBudgetData(null)"

requirements-completed: [DATA-04]

duration: 2min
completed: 2026-03-22
---

# Phase 92 Plan 03: Frontend API-Only Data Loading Summary

**dataLoader.ts rewritten to API-only (throws on failure), App.tsx loadDataset deleted and replaced with loadBudgetData calls, error state upgraded to "Budget data unavailable" with muted-blue Retry button**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-22T19:55:31Z
- **Completed:** 2026-03-22T19:57:31Z
- **Tasks:** 2 of 2 complete (Task 2 human-verify approved via Playwright)
- **Files modified:** 2

## Accomplishments

- Removed three-tier fallback (API → static JSON → mock) from dataLoader.ts — API is now the sole source and throws on failure
- Renamed `listCities` to `listMunicipalities` pointing at `/treasury/municipalities` (aligns with Plan 01 backend rename)
- Deleted `loadDataset` function from App.tsx that directly fetched `./data/*.json` files, bypassing dataLoader entirely
- Updated both `useEffect` hooks in App.tsx to call `loadBudgetData` (operating, revenue, active dataset)
- Second useEffect `.catch` now sets `setBudgetData(null)` so error state actually renders
- Error state upgraded from "Unable to load data / Please check the console for errors" to "Budget data unavailable" with muted-blue (#00657c) Retry button per UI-SPEC.md

## Task Commits

Each task was committed atomically:

1. **Task 1: Simplify dataLoader.ts to API-only and update App.tsx data loading** - `1081336` (feat)
2. **Deviation fix: Loading guard blocked error state** - `5f9fbcc` (fix)

**Task 2 (checkpoint:human-verify):** Approved via Playwright — error state renders correctly with "Budget data unavailable" and muted-blue Retry button.

## Files Created/Modified

- `treasury-tracker/src/data/dataLoader.ts` - API-only data loader; throws on failure; exports `listMunicipalities` calling `/treasury/municipalities`
- `treasury-tracker/src/App.tsx` - Imports `loadBudgetData`; local `loadDataset` deleted; both useEffects call `loadBudgetData`; error state updated with "Budget data unavailable" + Retry button

## Decisions Made

1. **API throws on failure** — dataLoader.ts `loadBudgetData` throws `new Error(...)` on non-ok response instead of silently falling back. Callers handle via `.catch` block. This is the correct model for D-06 (API-only data source).

2. **setBudgetData(null) on error** — The second useEffect `.catch` block now explicitly sets `setBudgetData(null)` so the error UI renders. Previously, `setLoading(false)` was called without clearing budgetData, which could leave stale data visible.

3. **Retry via window.location.reload()** — Per UI-SPEC.md, this is the correct mechanism (re-triggers all useEffect data loading).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Loading guard blocked error state rendering**
- **Found during:** Task 2 (human-verify checkpoint — Playwright verification)
- **Issue:** The condition `if (loading || !operatingBudgetData)` caused the loading spinner to persist indefinitely when the API was unreachable. `operatingBudgetData` stayed null even after the main dataset load failed, so the `!budgetData` error state was never reached.
- **Fix:** Removed `operatingBudgetData` from the loading guard condition; updated the totals `Promise.all` catch block to set `setOperatingBudgetData(null)` so the guard exits correctly; error state now renders as designed.
- **Files modified:** `treasury-tracker/src/App.tsx`
- **Verification:** Playwright screenshot confirmed "Budget data unavailable" heading and Retry button visible when API is offline.
- **Committed in:** `5f9fbcc` (treasury-tracker)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** Fix was essential for the error state to function. The plan's acceptance criteria required error state to render on API failure — the loading guard bug prevented this entirely.

## Known Stubs

None — no placeholder values. When the Go backend is unavailable, the error state renders with "Budget data unavailable" rather than stale/empty data.

## Next Phase Readiness

- Phase 92 complete: schema constraints fixed (92-01), Bloomington data imported (92-02), frontend fully API-driven (92-03)
- Phase 93 (Indiana Data Import) is unblocked — `loadBudgetData(year, municipalityName, dataset)` serves any imported entity
- Phase 95 (Entity Switcher) depends on `listMunicipalities` returning all entities — endpoint is wired; needs switcher UI only
- Blocker for Phase 93: Download and inspect Indiana Gateway sample files for Ellettsville and Monroe County before writing transforms

## Self-Check: PASSED

Files modified:
- `treasury-tracker/src/data/dataLoader.ts` — exists, API-only
- `treasury-tracker/src/App.tsx` — exists, uses loadBudgetData

Commits:
- `1081336` — feat(92-03): remove static fallback from dataLoader, wire App.tsx to API via loadBudgetData

---
*Phase: 92-schema-foundation-bloomington-migration*
*Completed: 2026-03-22*
