---
phase: 127
plan: 01
subsystem: ev-ui
tags: [ev-ui, component-library, react, floating-ui, svg, icons]
dependency_graph:
  requires: []
  provides:
    - ev-ui/src/PlaceholderRadar.jsx
    - ev-ui/src/IconOverlay.jsx
    - "@floating-ui/react peerDependency in ev-ui"
  affects:
    - ev-ui/src/CompassCardHorizontal.jsx (Plan 02 — imports both new files)
tech_stack:
  added:
    - "@floating-ui/react ^0.27.0 (peerDependency + devDependency)"
  patterns:
    - token-only styling (colorScales, borderRadius, spacing, semanticTokens)
    - floating-ui programmatic tooltip role via useRole hook
    - pure presentational SVG component (no state, no event handlers)
key_files:
  created:
    - ev-ui/src/PlaceholderRadar.jsx
    - ev-ui/src/IconOverlay.jsx
  modified:
    - ev-ui/package.json
    - ev-ui/package-lock.json
decisions:
  - "@floating-ui/react ^0.27.0 matches essentials consumer version (^0.27.19 installed)"
  - "PlaceholderRadar: pure SVG, no state — size and r math are dimensional constants (not spacing tokens)"
  - "IconOverlay: spacing[1] (4px) used for icon padding instead of source 5px (4px scale conformance per UI-SPEC)"
  - "IconOverlay role=tooltip set via floating-ui useRole hook (programmatic), not JSX attribute — verbatim from source"
metrics:
  duration: "~15 minutes"
  completed: "2026-04-19T02:24:28Z"
  tasks_completed: 3
  files_created: 2
  files_modified: 2
requirements:
  - CARD-03
---

# Phase 127 Plan 01: Leaf Component Primitives — Summary

**One-liner:** @floating-ui/react peer dep declared + PlaceholderRadar (dashed-octagon SVG) + IconOverlay (floating-ui tooltip row) ported to ev-ui with token rewiring

## What Was Built

Scaffolded the two leaf components required by `CompassCardHorizontal` (Plan 02):

1. **ev-ui/src/PlaceholderRadar.jsx** — Pure presentational SVG rendering a dashed octagon for the compass empty state. Ported verbatim from `essentials/src/components/CompassFirstCard.jsx` lines 56-83. Colors rewired to `colorScales.teal['050']` (background) and `colorScales.gray['200']` (stroke); border radius uses `borderRadius.sm`.

2. **ev-ui/src/IconOverlay.jsx** — Affordance icon row (BallotIcon / CompassIcon / BranchIcon) with accessible floating-ui tooltips. Ported verbatim from `essentials/src/components/IconOverlay.jsx` with two mechanical changes: icon import changed from `@empoweredvote/ev-ui` to `./icons.js` (avoids circular reference), tooltip colors wired to `semanticTokens.light.tooltip` (background + text).

3. **ev-ui/package.json** — `@floating-ui/react: ^0.27.0` added to both `peerDependencies` and `devDependencies` (NOT `dependencies`), preventing duplicate React context in consumers.

## Commits (ev-ui repo — feat/compass-first-card branch)

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add @floating-ui/react peer + dev dep | c7394ce | ev-ui/package.json, package-lock.json |
| 2 | PlaceholderRadar.jsx | 045a5a5 | ev-ui/src/PlaceholderRadar.jsx |
| 3 | IconOverlay.jsx | 831afd9 | ev-ui/src/IconOverlay.jsx |

## Deviations from Plan

### Minor Deviations (documented, within discretion)

**1. [Spacing] IconOverlay icon padding: spacing[1] (4px) vs source 5px**
- The source `essentials/src/components/IconOverlay.jsx` uses `padding: '5px'` on the icon wrapper span.
- The plan explicitly prescribes `spacing[1]` (4px) per UI-SPEC §Spacing Scale Exceptions to conform to the 4px base unit.
- Applied as directed — this was a known and documented change in the plan.

**2. [Verification] role="tooltip" acceptance criteria grep check**
- The plan's acceptance criteria says `grep 'role="tooltip"'` should match.
- The floating-ui pattern uses `useRole(context, { role: 'tooltip' })` — a JS object, not a JSX attribute.
- This is verbatim from the source `essentials/src/components/IconOverlay.jsx`.
- The plan's automated `<verify>` block does NOT check for this (only checks for semanticTokens and absence of hex strings) — automated verify PASSES.
- The tooltip role IS set correctly via floating-ui's programmatic approach.

No architectural deviations. No Rule 4 blockers encountered.

## Verification Results

All plan verification criteria met:
- `cd ev-ui && npm run build` exits 0 (175KB ESM, 187KB CJS)
- Build artifact `ev-ui/dist/index.mjs` does NOT export PlaceholderRadar or IconOverlay (internal)
- `grep -rE "#[0-9a-fA-F]{3,6}" ev-ui/src/PlaceholderRadar.jsx ev-ui/src/IconOverlay.jsx` — no hex strings
- `grep -r "dangerouslySetInnerHTML" ev-ui/src/PlaceholderRadar.jsx ev-ui/src/IconOverlay.jsx` — no matches (T-127-01 threat mitigated)
- `@floating-ui/react` declared in both peerDependencies and devDependencies, absent from dependencies

## Threat Surface Scan

No new security surface introduced:
- T-127-01 (Tampering via tooltip copy): React auto-escaping verified — no `dangerouslySetInnerHTML` anywhere in ported code.
- T-127-02 (Info disclosure via floating portal): Tooltip content is UI chrome only — no PII surface.

## Known Stubs

None. Both components are complete leaf primitives with no data-dependent stubs.

## Self-Check: PASSED

- [x] ev-ui/src/PlaceholderRadar.jsx exists
- [x] ev-ui/src/IconOverlay.jsx exists
- [x] ev-ui/package.json contains @floating-ui/react in peerDependencies and devDependencies
- [x] Commits c7394ce, 045a5a5, 831afd9 exist in ev-ui feat/compass-first-card branch
- [x] Build passes (ESM + CJS)
- [x] No hex strings in new files
- [x] No barrel exports added (Plan 02 concern)
- [x] No version bump performed
