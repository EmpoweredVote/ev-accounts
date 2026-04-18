---
phase: 125-tier-2-ux-polish-bundle
plan: "01"
subsystem: ui
tags: [react, google-maps, autocomplete, address-formatting, cross-reference]

# Dependency graph
requires:
  - phase: 122-cross-app-loop-polish
    provides: elections data infrastructure, fetchElectionsByAddress API
  - phase: 114-ux-walkthrough
    provides: gap report with G-114-001, G-114-002, G-114-004 findings

provides:
  - Google Places Autocomplete on Landing page address input
  - Title-case normalization for ALL CAPS Census Geocoder addresses
  - Cross-reference annotation on Representatives cards for officials running for different office
  - Eager elections pre-fetch on address query for cross-ref availability

affects: [essentials, 125-02-compass-wave, 125-03-readrank-treasury-wave]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - toAddressTitleCase helper for Census Geocoder ALL CAPS normalization with state/street abbreviation awareness
    - electionCrossRef useMemo map from politician_id to running-for position
    - Eager elections pre-fetch replaces lazy-on-tab-click pattern

key-files:
  created: []
  modified:
    - essentials/src/pages/Landing.jsx
    - essentials/src/pages/Results.jsx

key-decisions:
  - "G-114-001: Reuse existing useGooglePlacesAutocomplete hook on Landing page — same pattern as Results.jsx, navigate to /results on selection"
  - "G-114-002: Apply toAddressTitleCase at display time only; raw formattedAddress preserved for geocoding/API calls"
  - "G-114-004: Eagerly fetch elections data on activeQuery (not lazy) to enable cross-ref on Representatives tab without requiring tab switch"
  - "G-114-004: Cross-ref annotation is a clickable button that switches to Elections tab directly"

patterns-established:
  - "toAddressTitleCase: normalize Census Geocoder uppercase addresses for display — handles state abbreviations (IN, CA) and street types (AVE, BLVD)"
  - "Eager elections pre-fetch: fetch when address query is set, not only when Elections tab clicked — enables cross-app data availability"

requirements-completed: []

# Metrics
duration: 3min
completed: 2026-04-17
---

# Phase 125 Plan 01: Essentials UX Polish (Wave 1) Summary

**Google Places Autocomplete on Landing page, ALL CAPS address normalization to title case, and cross-reference annotations for officials running for different office on the Representatives tab**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-04-17T21:10:47Z
- **Completed:** 2026-04-17T21:13:32Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments

- G-114-001: Landing page now shows Google Places Autocomplete dropdown as users type their address — same UX as the Results page re-search bar
- G-114-002: Addresses from the Census Geocoder (returned in ALL CAPS) are now displayed in readable title case in all results headers and the address bar
- G-114-004: Sitting officials who are running for a different office now show a clickable "Running for [office] — see Elections tab" annotation on their Representatives card; requires eagerly pre-fetching elections data on address load

## Task Commits

Each task was committed atomically:

1. **Task 1: G-114-001 autocomplete on Landing** - `c094b1c` (feat)
2. **Task 2: G-114-002 address title case** - `d049d5c` (feat)
3. **Task 3: G-114-004 cross-reference annotation** - `32eb9e7` (feat)

**Plan metadata:** (docs commit — see below)

## Files Created/Modified

- `essentials/src/pages/Landing.jsx` - Added `useRef`, `useGooglePlacesAutocomplete` import, `addressInputRef`, hook wired to address input with auto-navigate on selection
- `essentials/src/pages/Results.jsx` - Added `toAddressTitleCase()` helper, applied to address display locations and address bar sync; changed elections fetch from lazy-on-tab to eager-on-query; added `electionCrossRef` useMemo map; added cross-reference annotation below politician cards

## Decisions Made

- Reused the existing `useGooglePlacesAutocomplete` hook rather than any new implementation — consistent with the Results page pattern.
- `toAddressTitleCase` preserves state abbreviations (IN, CA, NY, etc.) and common street abbreviations (AVE, BLVD, ST) as abbreviated form while capitalizing proper names.
- Elections pre-fetch made eager rather than lazy: this has a minor network cost (one extra API call per address search) but is necessary for the cross-reference feature to work without requiring the user to click Elections tab first.
- Cross-reference annotation is rendered as a button (not just text) so clicking it directly switches to the Elections tab — immediately actionable.

## Deviations from Plan

None - plan executed exactly as specified in CONTEXT.md decisions D-01 through D-04.

## Issues Encountered

None. Build passed cleanly on first attempt (vite build: 746 modules, no errors).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Wave 1 (Essentials) complete. All 3 gaps closed: G-114-001, G-114-002, G-114-004.
- Wave 2 (Compass): G-114-011 (geo-aware state pre-selection in compare picker) and G-114-014 (Matt Pierce headshot in compare panel).
- Wave 3 (Read & Rank + Treasury): G-114-020 (page title), G-114-021 (geo-prioritization), G-114-023, G-114-024, G-114-025.
- No blockers. Branch `feat/125-essentials-ux-polish` in essentials repo ready to merge.

## Known Stubs

None - all three gaps are fully resolved with wired functionality.

## Self-Check: PASSED

- Landing.jsx: FOUND
- Results.jsx: FOUND
- SUMMARY.md: FOUND
- Commit c094b1c (G-114-001): FOUND
- Commit d049d5c (G-114-002): FOUND
- Commit 32eb9e7 (G-114-004): FOUND

---
*Phase: 125-tier-2-ux-polish-bundle*
*Completed: 2026-04-17*
