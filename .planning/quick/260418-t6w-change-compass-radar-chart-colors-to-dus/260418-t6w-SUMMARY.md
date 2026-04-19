---
phase: 260418-t6w
plan: "01"
subsystem: ev-ui
tags: [radar-chart, colors, design-system, dusk, sage, vertex-dots]
dependency_graph:
  requires: []
  provides: [radar-chart-dusk-sage-colors, radar-chart-vertex-dots]
  affects: [CompassV2, essentials, read-rank]
tech_stack:
  added: []
  patterns: [circle-dots-at-svg-vertices, compareCoords-array-refactor]
key_files:
  modified:
    - ev-ui/src/RadarChartCore.jsx
decisions:
  - "Dots are static (not animated) — snap to position on re-render rather than tweening with spring; acceptable tradeoff to avoid second spring complexity"
  - "Refactored comparePoints build to produce compareCoords [[x,y],...] array alongside the string, enabling dot rendering without parsing"
  - "Rendering order: user polygon → user dots → compare polygon → compare dots → hitboxes; user dots sit under compare polygon (consistent with layering intent)"
metrics:
  duration: "~5 minutes"
  completed: "2026-04-18"
  tasks_completed: 1
  tasks_total: 2
  files_modified: 1
---

# Phase 260418-t6w Plan 01: Radar Chart Colors + Vertex Dots Summary

**One-liner:** Swapped RadarChartCore polygon colors from Coral/LightBlue to Dusk (#7C6B9E) / Sage (#5A9A6E) and added white-bordered circle dots at every data vertex for both polygons.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Replace polygon colors with Dusk/Sage and render bordered vertex dots | 81ab11f | ev-ui/src/RadarChartCore.jsx |

## What Was Built

- **User polygon:** fill `rgba(124, 107, 158, 0.4)`, stroke `#7C6B9E` — applied to both static (`countChanged`) and animated branches
- **Compare polygon:** fill `rgba(90, 154, 110, 0.3)`, stroke `#5A9A6E` — applied to both static and animated branches
- **User vertex dots:** `<circle r=5 fill="#7C6B9E" stroke="#FFFFFF" strokeWidth={2}>` rendered from `pointsArr`
- **Compare vertex dots:** `<circle r=4 fill="#5A9A6E" stroke="#FFFFFF" strokeWidth={2}>` rendered from `compareCoords`
- **compareCoords refactor:** The `cpts` build was refactored to produce a `compareCoords: [[x,y],...]` array, with `comparePoints` derived from it — cleaner data flow, no string parsing needed for dots

## Verification

- `npm run build` in `ev-ui/` passed cleanly (ESM + CJS bundles, no errors)
- No occurrences of `255, 87, 64` or `89, 176, 196` remain in RadarChartCore.jsx
- Both polygon render branches (static + animated) use new colors
- `<circle>` elements render for each vertex with `stroke="#FFFFFF"` and `strokeWidth={2}`

## Checkpoint: Human Verification Required (Task 2)

Visual verification in a running CompassV2 instance is required before publishing. Follow these steps:

```bash
# 1. Link local ev-ui build into CompassV2
cd ev-ui && npm run build && npm link
cd ../CompassV2 && npm link @empoweredvote/ev-ui && npm run dev
```

2. Open http://localhost:5173 and navigate to the Compass page.
3. Answer a few topics so the user polygon renders. Confirm:
   - User polygon fill is soft purple/violet (Dusk), NOT coral/orange
   - Each vertex has a visible white-ringed dot
4. Open the politician comparison picker, select any politician. Confirm:
   - Compare polygon fill is muted green (Sage), NOT cyan/light blue
   - Compare polygon vertices also have white-ringed dots
5. Toggle spoke inversion and add/remove a topic to confirm animation still works (polygons tween, dots snap to new positions)
6. When done verifying, unlink:
   ```bash
   cd CompassV2 && npm unlink @empoweredvote/ev-ui && npm install
   cd ../ev-ui && npm unlink
   ```

After visual approval, publish with:
```bash
cd ev-ui && npm version patch && git push origin main --follow-tags
```
This triggers the auto-bump pipeline to update all consumer repos.

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED

- `/Users/chrisandrews/Documents/GitHub/ev-ui/src/RadarChartCore.jsx` — FOUND, modified
- Commit `81ab11f` — FOUND in git log
- `#7C6B9E` present in file — confirmed
- `#5A9A6E` present in file — confirmed
- No `255, 87, 64` or `89, 176, 196` remaining — confirmed
- `npm run build` succeeded — confirmed
