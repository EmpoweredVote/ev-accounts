---
phase: 103-essentials-wiring-landing-page
plan: "01"
subsystem: essentials
tags: [ev-ui, icons, tooltips, tier-hues, accessibility, floating-ui]
dependency_graph:
  requires: []
  provides: [IconOverlay, getBranch, tier-props-on-CategorySection]
  affects: [essentials/src/pages/Results.jsx]
tech_stack:
  added: ["@floating-ui/react@0.27.19", "@chrisandrewsedu/ev-ui@0.1.55"]
  patterns: [accessible-tooltip-pattern, icon-overlay-pattern, tier-color-tokens]
key_files:
  created:
    - essentials/src/components/IconOverlay.jsx
    - essentials/src/utils/branchType.js
  modified:
    - essentials/package.json
    - essentials/src/pages/Results.jsx
decisions:
  - "Icon overlay positioned bottom-right per PLAN acceptance criteria (right: 4px)"
  - "?mode=browse useEffect uses empty deps array to fire once on mount only"
metrics:
  duration: "~15 minutes"
  completed: "2026-04-04"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 2
---

# Phase 103 Plan 01: Essentials Wiring — Tier Hues & Icon Overlays Summary

ev-ui v0.1.55 tier color tokens wired into CategorySection, icon badge overlay (BallotIcon/CompassIcon/BranchIcon) with @floating-ui/react accessible tooltips positioned bottom-right on politician cards, replacing the old "On Ballot" text badge.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Install deps, create IconOverlay and branchType | cb999a6 | package.json, package-lock.json, IconOverlay.jsx, branchType.js |
| 2 | Wire tier hues and icon overlays into Results.jsx | f35e110 | Results.jsx |

## What Was Built

### Task 1: Dependencies + New Files

**`essentials/src/utils/branchType.js`**
- `getBranch(districtType, officeTitle)` maps all district types to `'Executive'` / `'Legislative'` / `'Judicial'` / `null`
- COUNTY type uses a title-based heuristic (council/commissioner → Legislative; sheriff/clerk/auditor/etc. → Executive)

**`essentials/src/components/IconOverlay.jsx`**
- `IconOverlay({ ballot, hasStances, branch })` renders a semi-transparent pill in the bottom-right corner of the politician card photo area
- Uses `@floating-ui/react` with `useFloating`, `useHover`, `useFocus`, `useDismiss`, `useRole`, `FloatingPortal`
- `offset(8)` middleware for tooltip spacing; `flip()` and `shift()` for viewport edge handling
- `autoUpdate` for scroll/resize repositioning
- Icon rendering order: BallotIcon → CompassIcon → BranchIcon
- Each icon wrapped in a focusable `<span>` with `aria-label` and 5px padding for 24px touch target
- Tooltip: dark `#2F3237` background, `#EBEDEF` text, `zIndex: 70`, Manrope font

**Packages installed:**
- `@chrisandrewsedu/ev-ui@0.1.55` (upgraded from 0.1.53)
- `@floating-ui/react@0.27.19` (new)

### Task 2: Results.jsx Wiring

- Added `import IconOverlay` and `import { getBranch }` at top of Results.jsx
- Local `CategorySection` instances now pass `tier="local"`
- State `CategorySection` instances now pass `tier="state"`
- Federal `CategorySection` instances now pass `tier="federal"`
- `renderPoliticianCard` now:
  - Wraps the outer `<div>` with `style={{ position: 'relative' }}`
  - Computes `branch = getBranch(pol.district_type, pol.office_title)`
  - Adds `imageFocalPoint="center 20%"` to `PoliticianCard` for better headshot cropping
  - Removes the old `badge={ballot ? "On Ballot" : undefined}` prop
  - Adds `<IconOverlay ballot={ballot} hasStances={hasStances} branch={branch} />` sibling
- Added `useEffect` to activate `'browse'` search mode when `?mode=browse` query param is present on mount

## Verification

- `npm ls @chrisandrewsedu/ev-ui` → `@chrisandrewsedu/ev-ui@0.1.55` ✓
- `npm ls @floating-ui/react` → `@floating-ui/react@0.27.19` ✓
- `npm run build` → exit 0, 739 modules transformed ✓

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — all data sources (ballot, hasStances, branch) are wired to live computed values in renderPoliticianCard.

## Self-Check: PASSED

Files created:
- `/Users/chrisandrews/Documents/GitHub/essentials/src/components/IconOverlay.jsx` — exists ✓
- `/Users/chrisandrews/Documents/GitHub/essentials/src/utils/branchType.js` — exists ✓

Commits:
- `cb999a6` — Task 1 ✓
- `f35e110` — Task 2 ✓
