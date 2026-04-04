---
phase: 103-essentials-wiring-landing-page
plan: "03"
subsystem: essentials-frontend
tags: [elections, ui, antipartisan, icon-overlay, tier-colors]
dependency_graph:
  requires: [103-01]
  provides: [ElectionsView-position-grouped]
  affects: [essentials/src/components/ElectionsView.jsx]
tech_stack:
  added: []
  patterns: [position-grouped-elections, party-sub-labels, tier-hue-differentiation, icon-overlay-on-candidate-cards]
key_files:
  created: []
  modified:
    - essentials/src/components/ElectionsView.jsx
decisions:
  - Party sub-label text uses text-sm text-gray-500 (antipartisan — no party-affiliated colors)
  - seededShuffle runs per race (per party ballot), not on merged position group — preserves per-party randomization
  - ballot object always constructed for election candidates (they are on ballot by definition)
  - hasStances=false for all election candidates — candidates lack compass stances data
metrics:
  duration: "~5 minutes"
  completed: "2026-04-04"
  tasks_completed: 1
  tasks_total: 1
  files_changed: 1
requirements_completed: [VIS-02, VIS-04]
---

# Phase 103 Plan 03: Election Page Position Grouping Summary

Election page restructured to group candidates by position (one CategorySection per race) rather than by position+party, with lightweight party sub-labels for primaries and icon overlays on candidate cards.

## What Was Built

Restructured `ElectionsView.jsx` to consolidate the election page grouping logic:

**Before:** Each party ballot for a position created a separate heavy CategorySection header (e.g., "Monroe County Council — Democratic Primary" and "Monroe County Council — Republican Primary" as distinct sections).

**After:** One CategorySection per position (e.g., "Monroe County Council") with lightweight `text-sm text-gray-500` party sub-labels inside for primary elections. General elections show candidates with no party label.

### Key Changes

1. **Position grouping data structure** — `processedElections` useMemo now builds `tierPositions` (nested by tier then cleanedPosition) instead of `tierMap` (flat list per tier). Each position group has a `parties` array with shuffled candidates per party ballot.

2. **Party sub-labels** — Gray 14px text rendered inline within the position group for primaries. Never uses party-affiliated colors (antipartisan principle enforced).

3. **Tier hues** — `tier` prop passed to CategorySection for Local/State/Federal hue differentiation via `tierPropMap`.

4. **Icon overlays** — Each candidate card wrapped in `position: relative` div with `<IconOverlay>` rendering:
   - Ballot icon (always shown — candidates are on ballot by definition)
   - Branch icon via `getBranch(districtType, cleanedPosition)`
   - Compass icon (false — candidates lack stances data)

5. **Image focal point** — `imageFocalPoint="center 20%"` added to PoliticianCard for better headshot cropping.

6. **seededShuffle preserved** — Runs per race (per party ballot), maintaining antipartisan ordering within each party group independently.

## Task Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Restructure election page grouping with position groups, tier hues, icon overlays | d783c71 | essentials/src/components/ElectionsView.jsx |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

- `hasStances = false` for all election candidates. This is intentional — election candidates do not have compass stances in the current data model. The ballot icon always shows; the compass icon is suppressed. Future plan PROF-04 will wire candidate stances data.

## Verification

- `cd essentials && npm run build` exits 0 (739 modules transformed, no errors)
- All acceptance criteria verified via grep:
  - `import IconOverlay from './IconOverlay'` present
  - `import { getBranch } from '../utils/branchType'` present
  - `tierPositions` present in data structure and rendering
  - `displayTitle: ballotLabel` absent (old pattern removed)
  - `tier={tierProp}` on CategorySection present
  - `{partyGroup.party} Primary` sub-label present
  - `text-sm text-gray-500` on party sub-label present
  - `seededShuffle` preserved
  - `imageFocalPoint="center 20%"` on PoliticianCard present
  - No partisan colors (#FF0000, #0000FF, red, blue) in sub-labels
  - `<IconOverlay` wired on candidate cards
  - `getBranch(` called per candidate
  - `position: 'relative'` on candidate card wrapper

## Self-Check: PASSED
