---
phase: 52-compare-politician-list-filters
plan: "01"
subsystem: CompassV2/compare-filters
tags: [react, hooks, filters, ui-components, compare-panel]
dependency_graph:
  requires: []
  provides: [useFilteredPoliticians, PoliticianFilters, filtered-inline-picker]
  affects: [CompassV2/compare-panel, InlinePoliticianPicker]
tech_stack:
  added: []
  patterns: [useMemo-for-derived-state, auto-clear-effect, static-lookup-maps]
key_files:
  created:
    - CompassV2/src/hooks/useFilteredPoliticians.js
    - CompassV2/src/components/PoliticianFilters.jsx
  modified:
    - CompassV2/src/components/InlinePoliticianPicker.jsx
decisions:
  - "JUDICIAL district type always mapped to Local tier in compass context — chamber_name not available in /compass/politicians endpoint to distinguish state appellate courts"
  - "Auto-clear stateFilter via useEffect watching level changes — avoids stale state/invalid filter combos without extra user action"
  - "levelCounts reflect state-filtered counts (not total) so pills show how many exist at current state"
  - "availableStates derived from current level filter — state dropdown only shows states with politicians at selected level"
metrics:
  duration: "~2 minutes"
  completed: "2026-02-28"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 1
---

# Phase 52 Plan 01: Politician List Filter Infrastructure Summary

**One-liner:** Level pill toggles (All/Federal/State/Local) and state dropdown wired into InlinePoliticianPicker via useFilteredPoliticians hook with dynamic counts and auto-clear logic.

## What Was Built

### useFilteredPoliticians hook (`CompassV2/src/hooks/useFilteredPoliticians.js`)

Custom hook that manages filter state and computes derived values from the raw politician array:

- `tierFromDistrictType(dt)` — internal helper mapping BallotReady district types to Federal/State/Local tiers. JUDICIAL always maps to Local (compass API lacks chamber_name for appellate detection).
- `STATE_NAMES` — static map of all 50 states + DC + territories (PR, GU, VI, AS, MP) for display names.
- `level` / `setLevel` — current level filter, defaults to "All".
- `stateFilter` / `setStateFilter` — current 2-letter state code or "".
- `clearAll()` — resets both filters.
- `hasActiveFilters` — boolean, true when level !== "All" or stateFilter !== "".
- `levelCounts` — `{ Federal, State, Local }` counts. When stateFilter is active, counts only include politicians matching that state. Memoized.
- `availableStates` — sorted `{ code, name }` array of states with politicians at current level. Memoized.
- `filtered` — politician array after applying level + state filters (text query remains in picker). Memoized.
- Auto-clear effect: when `level` changes, if `stateFilter` produces zero results at new level, it clears automatically.

### PoliticianFilters component (`CompassV2/src/components/PoliticianFilters.jsx`)

Purely presentational component — all state passed in as props from the hook:

- **Level pills row** (`px-3 pt-2 pb-1`): "All" pill always visible; Federal/State/Local pills render only when count > 0. Active pill uses `bg-[#00657c] text-white` (ev-muted-blue). Each pill is a `<button>` calling `onLevelChange`.
- **State dropdown + clear controls row** (`px-3 pb-2`): `<select>` with "State" placeholder and sorted state options. Clear "x" buttons appear when stateFilter or level is active. "Clear all" underline link appears when `hasActiveFilters`, positioned `ml-auto`.
- Compact — both rows ~60px total height so politician list dominates.

### InlinePoliticianPicker integration (`CompassV2/src/components/InlinePoliticianPicker.jsx`)

- Imports `useFilteredPoliticians` and `PoliticianFilters`.
- Calls `useFilteredPoliticians(politicians)` after existing `usePoliticianList()` call.
- `options` useMemo now filters from `filtered` (post-level/state filter) rather than raw `politicians`, composing text search with AND logic.
- `PoliticianFilters` rendered between search input and the divider/action rows.
- Divider added after PoliticianFilters, before "Clear comparison" button.
- Empty state message distinguishes filter-caused vs search-caused empty results.
- Filter state persists across dropdown open/close cycles (component stays mounted; only dropdown visibility changes).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create useFilteredPoliticians hook and PoliticianFilters component | fec9ff3 | useFilteredPoliticians.js (new), PoliticianFilters.jsx (new) |
| 2 | Wire filters into InlinePoliticianPicker | b37aa3e | InlinePoliticianPicker.jsx (modified) |

## Verification

- `cd CompassV2 && npx vite build` passes with no errors (both tasks).
- No pre-existing build warnings were introduced by this work (chunk size warning pre-existed).

## Decisions Made

1. **JUDICIAL always Local** — The `/compass/politicians` endpoint does not return `chamber_name`, which would be needed to distinguish state appellate courts from local courts. All JUDICIAL district types map to Local tier in this context. Acceptable simplification.

2. **Auto-clear via useEffect** — When level changes, a `useEffect` checks if current stateFilter produces any results. If not, stateFilter is cleared. Dependency array intentionally excludes `stateFilter` to avoid feedback loop.

3. **levelCounts reflect state-filtered totals** — Pills show how many politicians exist at each level within the currently selected state, not global totals. This prevents confusing "Federal (12)" when state filter would yield 0 federal politicians.

4. **availableStates scoped to current level** — State dropdown only includes states that have politicians at the currently selected level, preventing impossible filter combinations.

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED

Files verified:
- FOUND: CompassV2/src/hooks/useFilteredPoliticians.js
- FOUND: CompassV2/src/components/PoliticianFilters.jsx
- FOUND: CompassV2/src/components/InlinePoliticianPicker.jsx (modified)

Commits verified (CompassV2 repo):
- FOUND: fec9ff3 feat(52-01): add useFilteredPoliticians hook and PoliticianFilters component
- FOUND: b37aa3e feat(52-01): wire PoliticianFilters into InlinePoliticianPicker
