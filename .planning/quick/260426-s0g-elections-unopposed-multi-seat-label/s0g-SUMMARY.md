---
phase: quick-s0g
plan: "01"
subsystem: elections-ui
tags: [elections, unopposed, multi-seat, ev-ui, essentials]
dependency_graph:
  requires: []
  provides: [string-safe running_unopposed banner, seats-aware isUnopposed logic]
  affects: [CompassCardVertical, CompassCardHorizontal, ElectionsView]
tech_stack:
  added: []
  patterns: [backwards-compatible prop polymorphism (string | boolean)]
key_files:
  created: []
  modified:
    - ev-ui/src/CompassCardVertical.jsx
    - ev-ui/src/CompassCardHorizontal.jsx
    - ev-ui/package.json
    - essentials/src/components/ElectionsView.jsx
decisions:
  - "Use typeof check (string vs boolean) on running_unopposed prop so existing callers passing `true` continue to work without changes"
  - "Pass seats count through processedElections to make it available at render time"
  - "isUnopposed = activeCandidates.length > 0 && activeCandidates.length <= seats (covers both single and multi-seat)"
metrics:
  duration: "<5 min (already executed)"
  completed: "2026-04-26"
---

# Quick Task s0g: Elections Unopposed Multi-Seat Label Summary

One-liner: String-safe running_unopposed banner in both CompassCard components + seats-aware ElectionsView isUnopposed logic with "(N seats)" label for multi-seat races, published as ev-ui 0.6.4.

## What Was Done

### Task 1: ev-ui — string-safe running_unopposed prop (0.6.4)

Both card components (`CompassCardVertical.jsx` and `CompassCardHorizontal.jsx`) were updated to render `running_unopposed` as a string when it is one, falling back to `'Running Unopposed'` when it is boolean `true`. This is a backwards-compatible change — all existing callers passing `true` continue to work unchanged.

`ev-ui/package.json` bumped from `0.6.3` to `0.6.4`. Tag `v0.6.4` pushed to origin, triggering the npm publish + auto-bump pipeline for consumer repos.

**Commit:** `e7cfca0` — `feat(ev-ui): support string running_unopposed prop in CompassCard components (0.6.4)`

### Task 2: essentials ElectionsView — seats-aware isUnopposed + string label

Three targeted edits to `ElectionsView.jsx`:

- **Edit A:** Added `seats: race.seats ?? 1` to the `processedElections` race object so seat count is available at render time.
- **Edit B:** Replaced `const isUnopposed = activeCandidates.length === 1` with `const seats = race.seats ?? 1; const isUnopposed = activeCandidates.length > 0 && activeCandidates.length <= seats` — correct for both single and multi-seat races.
- **Edit C:** `running_unopposed` in `polForCard` now passes `` `Running Unopposed (${seats} seats)` `` as a string for multi-seat races, and `true` for single-seat races (unchanged display).

**Commit:** `64abc7a` — `feat(essentials): label multi-seat unopposed races with seat count in ElectionsView`

## Verification

- Single-seat races with 1 active candidate: show "Running Unopposed" (boolean true path, no change)
- Multi-seat races where active candidates <= seats: show "Running Unopposed (N seats)"
- Zero-candidate races (isEmpty): show "No candidates have filed" message, not the banner
- Withdrawn candidates: do not show the banner (guard unchanged)
- ev-ui 0.6.4 tag confirmed pushed to origin (`refs/tags/v0.6.4`)

## Deviations from Plan

None — plan executed exactly as written. All changes were already committed when this session ran.

## Self-Check: PASSED

- `e7cfca0` confirmed in ev-ui git log
- `64abc7a` confirmed in essentials git log
- `v0.6.4` tag confirmed at origin via `git ls-remote --tags origin`
- All four files modified as specified in plan frontmatter
