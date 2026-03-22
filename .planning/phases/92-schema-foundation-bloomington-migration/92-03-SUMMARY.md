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
- **Tasks:** 1 of 2 complete (Task 2 is a human-verify checkpoint)
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

**Task 2 (checkpoint:human-verify):** Awaiting human verification of error state UI and data loading.

## Files Created/Modified

- `treasury-tracker/src/data/dataLoader.ts` - API-only data loader; throws on failure; exports `listMunicipalities` calling `/treasury/municipalities`
- `treasury-tracker/src/App.tsx` - Imports `loadBudgetData`; local `loadDataset` deleted; both useEffects call `loadBudgetData`; error state updated with "Budget data unavailable" + Retry button

## Decisions Made

1. **API throws on failure** — dataLoader.ts `loadBudgetData` throws `new Error(...)` on non-ok response instead of silently falling back. Callers handle via `.catch` block. This is the correct model for D-06 (API-only data source).

2. **setBudgetData(null) on error** — The second useEffect `.catch` block now explicitly sets `setBudgetData(null)` so the error UI renders. Previously, `setLoading(false)` was called without clearing budgetData, which could leave stale data visible.

3. **Retry via window.location.reload()** — Per UI-SPEC.md, this is the correct mechanism (re-triggers all useEffect data loading).

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — no placeholder values. When the Go backend is unavailable, the error state renders with "Budget data unavailable" rather than stale/empty data.

## Next Phase Readiness

- Task 2 (human-verify) is a checkpoint — user must verify the error state UI by running `npm run dev` without the Go backend
- After approval, Plan 03 is complete and Phase 92 execution can proceed to Plan 04 (if any) or wrap up

## Self-Check: PASSED

Files modified:
- `treasury-tracker/src/data/dataLoader.ts` — exists, API-only
- `treasury-tracker/src/App.tsx` — exists, uses loadBudgetData

Commits:
- `1081336` — feat(92-03): remove static fallback from dataLoader, wire App.tsx to API via loadBudgetData

---
*Phase: 92-schema-foundation-bloomington-migration*
*Completed: 2026-03-22*
