---
phase: quick-260404-w7r
plan: 01
subsystem: essentials-ui / ev-ui
tags: [icon-overlay, politician-card, layout, refactor]
dependency_graph:
  requires: []
  provides: [footer-prop-politician-card, static-icon-overlay]
  affects: [essentials/src/pages/Results.jsx, essentials/src/components/ElectionsView.jsx, essentials/src/components/CompassFirstCard.jsx]
tech_stack:
  added: []
  patterns: [footer-prop-pattern, static-flow-layout]
key_files:
  created: []
  modified:
    - ev-ui/src/PoliticianCard.jsx
    - essentials/src/components/IconOverlay.jsx
    - essentials/src/pages/Results.jsx
    - essentials/src/components/ElectionsView.jsx
    - essentials/src/components/CompassFirstCard.jsx
decisions:
  - IconOverlay switches from absolute positioning to static flow — no wrapper hacks needed anywhere
  - PoliticianCard uses minHeight instead of fixed height to accommodate variable footer content
metrics:
  duration: ~5 minutes
  completed: 2026-04-05T03:15:58Z
  tasks_completed: 2
  files_modified: 5
---

# Phase quick-260404-w7r Plan 01: Move IconOverlay to left-aligned footer in card content flow

**One-liner:** Moved icon badges (ballot, compass, branch) from absolute bottom-right photo overlay to static left-aligned footer row inside PoliticianCard content area, eliminating position:relative wrappers and CSS !important hacks.

## Tasks Completed

| Task | Description | Commit | Repo |
|------|-------------|--------|------|
| 1 | Add footer prop to PoliticianCard, change height to minHeight, convert IconOverlay to static flow | ed12358 (ev-ui), d85793a (essentials) | ev-ui, essentials |
| 2 | Wire IconOverlay as footer prop in Results, ElectionsView; clean up CompassFirstCard !important hack | f3b1e02 | essentials |

## What Changed

**ev-ui/src/PoliticianCard.jsx:**
- Added `footer` prop (ReactNode) rendered below subtitle inside the content div
- Changed `height: '96px'` to `minHeight: '96px'` for horizontal variant so cards grow with footer content

**essentials/src/components/IconOverlay.jsx:**
- Removed `position: 'absolute'`, `bottom`, `right`, `zIndex`, `background`, `borderRadius`
- Now uses `display: 'flex'`, `gap: 4`, `alignItems: 'center'`, `justifyContent: 'flex-start'`, `padding: 0`
- Updated JSDoc to reflect new static-flow positioning

**essentials/src/pages/Results.jsx:**
- Removed `style={{ position: 'relative' }}` from wrapper div
- Moved `<IconOverlay>` from sibling element to `footer` prop on PoliticianCard

**essentials/src/components/ElectionsView.jsx:**
- Same pattern: removed `position: 'relative'` wrapper, passed IconOverlay as `footer` prop

**essentials/src/components/CompassFirstCard.jsx:**
- Removed entire `compass-card-icons` wrapper + `<style>` block with `!important` overrides
- IconOverlay now renders directly in flow with a plain `alignSelf` wrapper div

## Verification

- `cd ev-ui && npm run build` — passed, no errors
- `cd essentials && npm run build` — passed, no errors (pre-existing duplicate key warning in Prototype.jsx, unrelated)

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None — pure layout/styling change, no new network surface.

## Self-Check: PASSED

- ev-ui/src/PoliticianCard.jsx — modified (footer prop, minHeight)
- essentials/src/components/IconOverlay.jsx — modified (static flow)
- essentials/src/pages/Results.jsx — modified (footer prop)
- essentials/src/components/ElectionsView.jsx — modified (footer prop)
- essentials/src/components/CompassFirstCard.jsx — modified (no !important hacks)
- Commits verified: ed12358 (ev-ui PoliticianCard), d85793a (essentials IconOverlay), f3b1e02 (essentials consumers)
