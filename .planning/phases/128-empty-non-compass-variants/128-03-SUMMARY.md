---
phase: 128-empty-non-compass-variants
plan: "03"
subsystem: essentials/prototype
tags: [react, CompassCardHorizontal, computeVariant, prototype, ev-ui, deep-link]
status: complete

dependency_graph:
  requires:
    - phase: 128-01
      provides: computeVariant named export in essentials/src/lib/classify.js
    - phase: 128-02
      provides: variant + onBuildCompass props on CompassCardHorizontal in @empoweredvote/ev-ui
  provides:
    - Prototype.jsx wired to CompassCardHorizontal with computeVariant page-level classification
    - handleBuildCompass deep-link to compass.empowered.vote with ?return= param
  affects: [Phase 129 — wire live Results.jsx and Profile.jsx to CompassCardHorizontal]

tech-stack:
  added: []
  patterns:
    - "page-level computeVariant call: variant={computeVariant(pol, userAnswers)} at render site"
    - "COMPASS_URL module-level constant with VITE_COMPASS_URL env fallback"
    - "handleBuildCompass window.open with ?return=encodeURIComponent(window.location.href)"

key-files:
  created: []
  modified:
    - essentials/src/pages/Prototype.jsx

key-decisions:
  - "Use useCompass() from CompassContext directly — prototype route is inside CompassProvider tree (App.jsx verified)"
  - "computeVariant called at render site per card, not pre-computed in useMemo — list is small and function is O(1)"
  - "A/B/C SegmentedControl and variant useState removed entirely — tied to old CompassFirstCard which is now gone"

requirements-completed: [STATE-01, STATE-02, STATE-03]

duration: ~8min
completed: 2026-04-25
---

# Phase 128 Plan 03: Prototype.jsx CompassCardHorizontal Wire-Up Summary

**STATUS: CHECKPOINT-PAUSED — Task 1 complete, Task 2 (human-verify) awaiting browser verification**

**Prototype.jsx switched from CompassFirstCard to CompassCardHorizontal with computeVariant classification and compass.empowered.vote deep-link via handleBuildCompass**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-04-25T00:00:00Z
- **Completed (Task 1):** 2026-04-25
- **Tasks:** 1 of 2 complete (Task 2 is human-verify checkpoint)
- **Files modified:** 1

## Accomplishments

- Replaced `CompassFirstCard` import (and `VARIANT_CONFIG`, `MOCK_STANCES`) with `CompassCardHorizontal` from `@empoweredvote/ev-ui`
- Added `computeVariant` import from `../lib/classify` — called per card as `variant={computeVariant(pol, userAnswers)}`
- Added `useCompass()` hook call to read `userAnswers` from CompassContext (CompassProvider already wraps the prototype route in App.jsx)
- Added `COMPASS_URL` module-level constant following the pattern established in `CompassCard.jsx`
- Added `handleBuildCompass()` opening `compass.empowered.vote/?return=<encoded-url>` in a new tab
- Removed A/B/C variant `SegmentedControl` and its `useState('A')` — those were tied to the removed `CompassFirstCard`
- Replaced `VARIANT_CONFIG[variant].gridCols` Tailwind class with inline 2-column grid style
- Build passes: `cd essentials && npm run build` exits 0

## Task Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Switch Prototype.jsx to CompassCardHorizontal + computeVariant + handleBuildCompass | 4a48160 (essentials) | essentials/src/pages/Prototype.jsx |
| 2 | Human-verify all four variants render correctly | PENDING — checkpoint | (verification only) |

## Files Created/Modified

- `essentials/src/pages/Prototype.jsx` — switched component, added classification + deep-link, removed A/B/C toggle

## Decisions Made

- `useCompass()` used directly — prototype route is wrapped by `CompassProvider` (App.jsx line 49 confirmed)
- No `useMemo` for variant pre-computation — `computeVariant` is O(1) and the Bloomington dataset is small
- Inline `onClick={() => {}}` no-op on each card — prototype harness, navigation not needed for verification

## Deviations from Plan

None — plan executed exactly as written.

## Checkpoint Status

**Task 2 is a `checkpoint:human-verify` gate.** The implementation is complete. Human verification requires:

1. `cd essentials && npm run dev` — open http://localhost:5173/prototype
2. Verify variant='empty' for all cards (clear localStorage compass answers, reload)
3. Verify variant='administrative' for clerk/treasurer/etc. politicians (with >= 3 userAnswers)
4. Verify variant='judicial' for JUDICIAL district_type politicians (with >= 3 userAnswers)
5. Verify variant='compass' for normal politicians with >= 3 answers (existing Phase 127 radar)
6. Toggle compass/portrait SegmentedControl — verify slot content changes across all variants
7. Click "Build your compass" CTA — verify new tab opens at `https://compass.empowered.vote/?return=<encoded-url>`

## Known Stubs

None. All props are wired to live data sources (`useCompass()` for `userAnswers`, `usePoliticianData()` for politicians).

## Threat Flags

None. `window.open` uses the pre-existing `?return=` contract (same as `CompassCard.jsx` and `CompassPreview.jsx`). `window.location.href` is trusted browser state, not user input. No new security surface introduced.

## Self-Check: PASSED

- essentials/src/pages/Prototype.jsx: modified and verified
- Task 1 commit 4a48160: in essentials git log
- `grep -c CompassCardHorizontal`: 2 (import + JSX)
- `grep -c computeVariant`: 2 (import + JSX prop)
- `grep -c CompassFirstCard`: 0
- `grep -c MOCK_STANCES`: 0
- `grep -c VARIANT_CONFIG`: 0
- `grep -c "useState('A')"`: 0
- `npm run build`: exits 0

---
*Phase: 128-empty-non-compass-variants*
*Plan: 03*
*Checkpoint paused: 2026-04-25*
