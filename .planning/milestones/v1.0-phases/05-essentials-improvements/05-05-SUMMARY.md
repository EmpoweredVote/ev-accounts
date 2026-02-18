---
phase: 05-essentials-improvements
plan: "05"
subsystem: ui
tags: [react, essentials, candidates, toggle, badge, ev-ui, election-date]

# Dependency graph
requires:
  - phase: 05-02
    provides: ev-ui 0.1.17 with badge prop on PoliticianCard
  - phase: 05-03
    provides: getTermLine helper and renderPoliticianCard pattern in Results.jsx
  - phase: 05-04
    provides: GET /essentials/candidates/{zip} backend endpoint

provides:
  - Candidate toggle in Results.jsx (Show Candidates checkbox, defaults off)
  - fetchCandidates function in api.jsx for /essentials/candidates/{zip}
  - Candidate cards with coral badge and election date below card

affects:
  - essentials Results page (candidate display layer)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Lazy candidate fetch: useEffect fires only when showCandidates=true — no premature API calls"
    - "Candidates merged after officials in byTier useMemo — officials always appear first per group"
    - "renderPoliticianCard helper consolidates official and candidate rendering — single code path for badge/term/election date"
    - "Election date rendered below card in coral (#ff5740) with em-dash separator for race name"

key-files:
  created: []
  modified:
    - essentials/src/lib/api.jsx
    - essentials/package.json
    - essentials/package-lock.json
    - essentials/src/pages/Results.jsx

key-decisions:
  - "fetchCandidates returns empty array for non-ZIP queries — no candidate-by-address endpoint exists yet; graceful degradation"
  - "showCandidates toggle defaults to false — officials-only is the default experience per ESST-01"
  - "renderPoliticianCard extracted as module-scope function (not inline lambda) — receives handlePoliticianClick as parameter since it closes over navigate"
  - "Candidate id prefixed with candidate- to avoid collision with official IDs in React key prop"
  - "candidateData cleared when toggle turned off — no stale data persists between toggle cycles"

patterns-established:
  - "Toggle-gated data fetch: useEffect with showCandidates dependency and cancellation flag"

requirements-completed:
  - ESST-01
  - ESST-02
  - ESST-03

# Metrics
duration: 2min
completed: 2026-02-18
---

# Phase 5 Plan 05: Candidate Toggle Integration Summary

**Candidate toggle with lazy fetch, coral badge, and election date rendering integrated into Essentials Results page — officials-only by default, candidates revealed inline via opt-in checkbox**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-02-18T17:12:14Z
- **Completed:** 2026-02-18T17:14:30Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `fetchCandidates(zipOrQuery)` export to `api.jsx` — fetches `/essentials/candidates/{zip}`, returns empty array for non-ZIP queries (address searches) and on network errors
- Installed `@chrisandrewsedu/ev-ui@0.1.17` in essentials (updated package.json and package-lock.json)
- Added `showCandidates` toggle state to Results.jsx (defaults to `false` — officials-only experience)
- Implemented lazy fetch: `useEffect` only fires when `showCandidates=true`, with cancellation flag for cleanup
- Added `classifiedCandidates` useMemo that maps candidate objects through `classifyCategory()` for tier grouping
- Updated `byTier` useMemo to merge candidates after officials within the same tier groups
- Extracted `renderPoliticianCard(pol, handlePoliticianClick)` helper consolidating all card rendering logic
- Candidate cards receive `badge="Candidate"` prop (renders coral pill via ev-ui 0.1.17)
- Candidate cards have no `onClick` (no profile page yet for candidates)
- Election date rendered below candidate cards in coral (#ff5740) with `—` separator for race name
- Added `formatElectionDate` helper (same pattern as `formatTermDate`) for "Nov 2026" format
- Toggle UI: subtle checkbox with muted gray text, positioned above ResultsHeader, only shown when `activeQuery` exists

## Task Commits

Commits in essentials repo:

1. **Task 1: Add fetchCandidates to api module and install ev-ui 0.1.17** - `a32e45b` (feat)
2. **Task 2: Integrate candidate toggle and badge rendering in Results.jsx** - `694feae` (feat)

## Files Created/Modified

- `essentials/src/lib/api.jsx` - Added `fetchCandidates` export at end of file
- `essentials/package.json` - Updated `@chrisandrewsedu/ev-ui` from `^0.1.14` to `^0.1.17`
- `essentials/package-lock.json` - Lock file updated for ev-ui 0.1.17
- `essentials/src/pages/Results.jsx` - Toggle state, candidate fetch effect, classifiedCandidates/byTier update, renderPoliticianCard helper, toggle checkbox UI, formatElectionDate helper

## Decisions Made

- `fetchCandidates` returns empty array for non-ZIP queries: no candidate-by-address endpoint exists yet; graceful degradation prevents broken UX for address searches
- `showCandidates` defaults to `false`: officials-only is the intended default experience per ESST-01 (users opt in)
- `renderPoliticianCard` extracted as module-scope function (not inline) because it receives `handlePoliticianClick` as a parameter — avoids closure-over-state issues
- Candidate `id` prefixed with `candidate-` to prevent React key collisions with official IDs
- `candidateData` cleared when toggle turned off via `if (!showCandidates) { setCandidateData([]); return; }` in useEffect

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- essentials is its own git repository (not tracked by the workspace root git). Commits were made to the essentials repo directly — consistent with the pattern observed in 05-03 and 05-04.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All 5 plans in Phase 5 (Essentials Improvements) are now complete
- Candidate toggle is live in Results page; requires ESST-01, ESST-02, ESST-03 all satisfied
- Real candidate data flows from BallotReady via the `/essentials/candidates/{zip}` endpoint built in 05-04
- No further work required for this phase

---
*Phase: 05-essentials-improvements*
*Completed: 2026-02-18*
