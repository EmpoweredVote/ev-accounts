---
phase: 260418-tqy
plan: 01
subsystem: essentials
tags: [elections, ui, eager-load, animation, responsive]
dependency_graph:
  requires: []
  provides: [elections-eager-load, pulsing-dot, responsive-tab-label]
  affects: [essentials/src/pages/Results.jsx]
tech_stack:
  added: []
  patterns: [useMemo for label derivation, eager useEffect on activeQuery, Tailwind animate-pulse]
key_files:
  created: []
  modified:
    - essentials/src/pages/Results.jsx
decisions:
  - Elections data fetches on activeQuery (eager) instead of activeView (lazy) so dot appears before tab click
  - STATE_NAMES map added as module-level const alongside STATE_ABBREVS for reuse
  - electionsLabelSuffix useMemo placed after buildingImageMap (both depend on userState)
  - animate-pulse applied to dot span; dot still conditionally rendered on electionsData presence
metrics:
  duration: ~10 minutes
  completed: 2026-04-18
  tasks_completed: 2
  tasks_total: 3
  files_modified: 1
---

# Quick Task 260418-tqy: Elections Tab Label and Glowing Dot Fix - Summary

**One-liner:** Eager-load elections data on address search with pulsing yellow dot and responsive desktop label showing next upcoming election state/type/date.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Eager-load elections data and add pulsing dot | da0a440 (essentials) | essentials/src/pages/Results.jsx |
| 2 | Derive and render responsive tab label for next upcoming election | da0a440 (essentials) | essentials/src/pages/Results.jsx |
| 3 | Verify tab label + pulsing dot in browser | (human-verify — skipped per constraints) | — |

## What Was Built

**Task 1 — Eager-load + pulsing dot:**
- Changed the elections `useEffect` dependency from `[activeView, activeQuery]` to `[activeQuery]`, removing the `activeView !== 'elections'` guard
- Elections data now fetches alongside politicians fetch as soon as an address search completes
- Added `animate-pulse` class to the yellow dot `<span>` so it visually pulses when elections data is present

**Task 2 — Responsive tab label:**
- Added `STATE_NAMES` const (all 50 states + DC) at module level near `STATE_ABBREVS`
- Added `electionsLabelSuffix` useMemo inside `Results()` that:
  - Filters elections to upcoming only (date >= today at midnight)
  - Sorts by date ascending and picks the nearest
  - Derives: `{StateName} {CapitalizedType} · {MMM D, YYYY}`
  - Returns `null` if no upcoming elections exist
- Updated Elections tab button to render two `<span>` elements:
  - `<span className="sm:hidden">Elections</span>` — mobile only
  - `<span className="hidden sm:inline">...</span>` — desktop only, includes suffix if available
- Fallback: plain "Elections" on desktop when `electionsLabelSuffix` is null

**Label format examples:**
- Desktop with elections: `Elections - Indiana Primary · May 6, 2026`
- Desktop with no state parse: `Elections - Primary · May 6, 2026`
- Desktop with no upcoming elections: `Elections`
- Mobile (any state): `Elections`

## Human Verification Checklist (Task 3 — skipped, for manual review)

1. `cd essentials && npm run dev`
2. Open http://localhost:5173 at desktop width (>640px)
3. Search "200 W Kirkwood Ave, Bloomington, IN, 47404"
4. BEFORE clicking Elections tab: confirm yellow dot appears and pulses within ~1-2s of politicians loading
5. Confirm tab label reads "Elections - Indiana Primary · May 6, 2026" (or nearest upcoming election)
6. Resize below 640px: label should truncate to plain "Elections", dot remains
7. No dot shown when electionsData is empty or no upcoming elections found

## Deviations from Plan

None — plan executed exactly as written.

## Build Verification

`cd essentials && npm run build` — passed cleanly (746 modules, no errors, only pre-existing chunk size warning unrelated to this change).

## Self-Check: PASSED

- File modified: `essentials/src/pages/Results.jsx` — FOUND
- Commit `da0a440` in essentials repo — FOUND
- Build passes — CONFIRMED
