---
phase: 90-location-based-filtering
plan: 02
subsystem: ui
tags: [react, zustand, location-filter, read-rank, essentials, cross-app]

# Dependency graph
requires:
  - phase: 90-location-based-filtering
    plan: 01
    provides: AddressFilterInput component, locationFilter store state, searchPoliticians API
provides:
  - IssueHub renders AddressFilterInput and filters issues by 2+ unique local-rep quote threshold
  - EvaluationPhase filters quotesToEvaluate to local-rep quotes only when locationFilter active
  - App.tsx parses ?address= query param on mount and auto-applies locationFilter
  - Essentials Layout dynamically appends ?address= to Read & Rank nav link when ?q= address is active
affects: [essentials, ev-readrank, cross-app-context]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Read-only filtering at render time — store preserves all quotes; effectiveQuotesToEvaluate derived from store"
    - "Cross-app context via URL query param (?address= in readrank, ?q= in essentials)"
    - "defaultNavItems mutation pattern — map over ev-ui exports to override specific dropdown item href"

key-files:
  created: []
  modified:
    - EV-readrank/src/components/IssueHub.tsx
    - EV-readrank/src/components/EvaluationPhase.tsx
    - EV-readrank/src/App.tsx
    - essentials/src/components/Layout.jsx

key-decisions:
  - "EvaluationPhase uses effectiveQuotesToEvaluate (derived at render) — store mutation avoided so clearing filter restores full quote set without re-selecting issue"
  - "Essentials Layout switches from SiteHeader to Header + defaultNavItems to enable custom navItems prop"
  - "App.tsx strips ?address= param immediately after reading to prevent re-processing on navigation"

patterns-established:
  - "Pattern: derive filtered arrays at render from store state, never mutate store for display-only filtering"

requirements-completed: [LOC-02, LOC-03, LOC-04]

# Metrics
duration: 3min
completed: 2026-03-16
---

# Phase 90 Plan 02: Location Filtering Wiring Summary

**IssueHub filters by 2+ unique local-rep quote threshold, EvaluationPhase shows only local-rep quotes, App.tsx auto-applies ?address= on mount, and Essentials dynamically appends address to Read & Rank nav link**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-16T01:32:59Z
- **Completed:** 2026-03-16T01:35:32Z
- **Tasks:** 2 of 3 (Task 3 is human-verify checkpoint)
- **Files modified:** 4

## Accomplishments

- IssueHub now renders AddressFilterInput between editorial header and progress summary; when filter is active, only issues with 2+ unique local-rep quotes appear with a "Showing N of M issues" count
- EvaluationPhase derives `effectiveQuotesToEvaluate` read-only from `locationFilter.politicianIds` — all progress/counter/completion logic uses the filtered array while the store preserves all quotes
- App.tsx uses `useSearchParams` to parse `?address=` on mount, strips the param immediately, calls `searchPoliticians`, and sets `locationFilter` in the store
- Essentials Layout replaces `SiteHeader` with `Header + defaultNavItems` to support dynamic navItems; when `?q=` is present in the URL the "Read & Rank" dropdown href becomes `https://readrank.empowered.vote?address=<encoded>`

## Task Commits

1. **Task 1: IssueHub filtering + EvaluationPhase quote filtering + App.tsx ?address= parsing** - `a965267` (feat) — EV-readrank repo
2. **Task 2: Essentials Layout dynamic Read & Rank nav link** - `2f4a654` (feat) — essentials repo

## Files Created/Modified

- `EV-readrank/src/components/IssueHub.tsx` - Added AddressFilterInput render, locationFilter destructure, filteredIssues logic, displayedIssues rendering
- `EV-readrank/src/components/EvaluationPhase.tsx` - Added locationFilter destructure and effectiveQuotesToEvaluate derived array
- `EV-readrank/src/App.tsx` - Added useSearchParams, useEffect for ?address= parsing, searchPoliticians call, setLocationFilter
- `essentials/src/components/Layout.jsx` - Replaced SiteHeader with Header + defaultNavItems; dynamic navItems with ?address= appended to Read & Rank href

## Decisions Made

- Used read-only derived filtering (`effectiveQuotesToEvaluate`) rather than mutating the store — preserves full quote set so clearing the filter instantly restores all quotes without requiring a re-fetch or re-select
- Essentials Layout switches from `SiteHeader` to `Header` directly because `SiteHeader` hardcodes `defaultNavItems` and does not accept a `navItems` prop
- App.tsx strips the `?address=` param immediately after reading (replace history) to avoid re-processing on SPA navigation

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

- EV-readrank and essentials are separate git repos (not tracked by the workspace .planning/ git repo) — committed to each project's own git repo directly

## Next Phase Readiness

- Task 3 (human-verify checkpoint) awaits user verification of the complete location filtering flow
- Both builds pass: `npm run build` exits 0 in EV-readrank and essentials
- Pre-deploy blockers remain in STATE.md: CORS for readrank.empowered.vote and VITE_GOOGLE_MAPS_API_KEY in Cloudflare Pages

---
*Phase: 90-location-based-filtering*
*Completed: 2026-03-16*
