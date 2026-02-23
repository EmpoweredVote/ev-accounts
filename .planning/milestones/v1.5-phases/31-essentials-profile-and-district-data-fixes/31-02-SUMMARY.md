---
phase: 31-essentials-profile-and-district-data-fixes
plan: "02"
subsystem: ev-ui
tags: [ev-ui, component-library, profile, card, avatar, subtitle, publishing]
dependency_graph:
  requires: []
  provides: [ev-ui@0.1.27, PoliticianProfile-v2, PoliticianCard-v2]
  affects: [essentials]
tech_stack:
  added: []
  patterns: [initials-avatar, contextual-subtitle, labeled-term-dates]
key_files:
  created: []
  modified:
    - ev-ui/src/PoliticianProfile.jsx
    - ev-ui/src/PoliticianCard.jsx
    - ev-ui/package.json
decisions:
  - "Photo shape changed to circle (borderRadius 50%) on both profile placeholder and actual photo for visual consistency"
  - "getTermLine() updated to 'First elected: X — Term ends: Y' labeled format per user decision"
  - "buildSubtitle() handles LOCAL edge case where chamber_name equals office_title — falls back to district_label"
  - "PoliticianCard imagePlaceholder uses borderRadius 50% on horizontal (circle) but 0 on vertical (rectangle) to match image area shape"
  - "bio_text and normalizeNotes helper removed entirely from PoliticianProfile — no bio rendered"
metrics:
  duration: "2 minutes"
  completed: "2026-02-23"
  tasks: 3
  files_modified: 3
---

# Phase 31 Plan 02: ev-ui Profile and Card Component Updates Summary

**One-liner:** Updated ev-ui PoliticianProfile and PoliticianCard with contextual subtitle, labeled term dates, initials avatars, removed bio_text rendering, published as @chrisandrewsedu/ev-ui@0.1.27.

## What Was Built

Updated two ev-ui components to implement the profile/card display decisions from the phase research:

### PoliticianProfile changes (`ev-ui/src/PoliticianProfile.jsx`)

1. **buildSubtitle() helper** — composes contextual subtitle from `chamber_name` and `district_id`. Handles the LOCAL edge case where BallotReady sets `chamber_name === office_title` (falls back to `district_label`). Standard case: `"Indiana Senate, District 40"`.

2. **Labeled term dates** — `getTermLine()` now outputs `"First elected: Jan 2020 — Term ends: Dec 2024"` instead of the old range format `"Jan 2020 – Dec 2024"`.

3. **Reordered info sections** — new order: office title → subtitle (chamber + district) → office description (italic) → term dates → years in office. Removed bio_text section.

4. **Circular initials avatar** — placeholder changed from a 3:4 rectangle with light gray background to a circle with `evTeal` background and white text. Photo `<img>` also updated to circle shape for visual consistency.

5. **bio_text removed** — deleted the `bio`/`normalizeNotes` computation block and the bio `<p>` render entirely.

### PoliticianCard changes (`ev-ui/src/PoliticianCard.jsx`)

1. **subtitle prop** — added optional third line below title for chamber + district context.

2. **Initials avatar** — replaced "No photo" text with `getInitials(name)` logic (first + last initial). Style updated: `evTeal` background, white bold text, circle on horizontal cards, rectangle on vertical cards.

3. **JSDoc updated** — documented the new subtitle prop.

### Version bump

`ev-ui/package.json` bumped from `0.1.26` to `0.1.27` and published to GitHub npm registry.

## Commits

| Task | Description | Hash | Files |
|------|-------------|------|-------|
| 1 | Update PoliticianProfile | b32a1bf | ev-ui/src/PoliticianProfile.jsx |
| 2 | Update PoliticianCard | 6d0be45 | ev-ui/src/PoliticianCard.jsx |
| 3 | Bump version + publish | 9c89beb | ev-ui/package.json |

## Decisions Made

- Photo shape changed to circle on both placeholder and actual photo in PoliticianProfile for visual consistency
- `getTermLine()` updated to labeled "First elected / Term ends" format per user decision (acceptable even though `valid_from` reflects current term start, not original first election)
- `buildSubtitle()` handles LOCAL edge case: when `chamber_name === office_title`, use `district_label` directly
- `PoliticianCard.imagePlaceholder` uses `borderRadius: '50%'` on horizontal cards (80x80 square becomes circle) but `0` on vertical (4:5 rectangle, initials centered without circular crop)
- bio_text and `normalizeNotes` helper removed entirely — no biography rendered on profile

## Deviations from Plan

**1. [Rule 1 - Bug] Photo img also updated to circle shape**

- **Found during:** Task 1
- **Issue:** The plan specified changing the placeholder to a circle but the existing `photo` style used `aspectRatio: '3/4'` creating a portrait rectangle. With the placeholder now circular, the photo would be a different shape than the placeholder, creating visual inconsistency.
- **Fix:** Updated `photoWrap` to use explicit `height` matching `width` (120px/192px), and updated `photo` style to use `borderRadius: '50%'` and `height: 100%` to match the circular placeholder shape.
- **Files modified:** ev-ui/src/PoliticianProfile.jsx
- **Commit:** b32a1bf

## Self-Check: PASSED

All files found, all commits verified.
