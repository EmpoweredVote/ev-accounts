---
phase: quick-260404-vqs
plan: 01
subsystem: essentials-frontend
tags: [ui, compass, politician-card, icon-overlay]
dependency_graph:
  requires: []
  provides: [single-compass-icon-per-card, clickable-small-compass-icon]
  affects: [essentials/src/components/IconOverlay.jsx, essentials/src/pages/Results.jsx]
tech_stack:
  added: []
  patterns: [e.currentTarget anchor, stopPropagation on icon click]
key_files:
  created: []
  modified:
    - essentials/src/components/IconOverlay.jsx
    - essentials/src/pages/Results.jsx
decisions:
  - Use e.currentTarget instead of document.querySelector for popover anchor — cleaner and no DOM coupling
metrics:
  duration: ~5 minutes
  completed: 2026-04-04
  tasks_completed: 2
  files_modified: 2
---

# Phase quick-260404-vqs Plan 01: Remove Duplicate Large Compass Icon Summary

**One-liner:** Removed large teal compass button from PoliticianCard and made the existing small 14px IconOverlay compass icon clickable to open CompassPreview.

## What Was Built

Two-file change to eliminate the duplicate compass icon on politician cards with stances:

1. **IconOverlay.jsx** — Added `onClick` prop to `IconWithTooltip` (with `stopPropagation` and conditional `cursor: pointer`), added `onCompassClick` prop to `IconOverlay`, and wired it to the compass icon instance.

2. **Results.jsx** — Removed `onCompassClick` from `PoliticianCard` (which rendered the large teal button), and moved the handler to `IconOverlay` using `e.currentTarget` as the popover anchor instead of a `document.querySelector` DOM lookup.

## Decisions Made

- **e.currentTarget over document.querySelector:** The old approach queried `.ev-compass-button` by class from a data attribute, which is brittle. The new approach passes the click event and uses `e.currentTarget` (the icon span itself) directly as the anchor element — more reliable and self-contained.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, or schema changes introduced.

## Self-Check: PASSED

- `essentials/src/components/IconOverlay.jsx` — modified, verified via read
- `essentials/src/pages/Results.jsx` — modified, verified via read
- Commit `5a4a94f` — feat(quick-260404-vqs): add onCompassClick prop to IconOverlay compass icon
- Commit `1af2d9b` — feat(quick-260404-vqs): remove large compass button, wire click to IconOverlay
- Build: passed (`✓ built in 1.49s`)
