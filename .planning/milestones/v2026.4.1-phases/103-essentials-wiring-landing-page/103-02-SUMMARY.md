---
phase: 103-essentials-wiring-landing-page
plan: "02"
subsystem: essentials-frontend
tags: [landing-page, coverage-cards, navigation, ui]
dependency_graph:
  requires: []
  provides: [coverage-cards, browse-by-location, address-divider]
  affects: [essentials/src/pages/Landing.jsx]
tech_stack:
  added: []
  patterns: [tailwind-css-4, react-router-navigate, coverage-cards]
key_files:
  created: []
  modified:
    - essentials/src/pages/Landing.jsx
decisions:
  - Coverage cards use COVERAGE_AREAS constant with county/state/address entries for Monroe County IN and LA County CA
  - H1 changed from font-bold to font-semibold to align with 2-weight typography system per UI-SPEC
  - Browse by location link uses navigate('/results?mode=browse') consistent with React Router pattern
metrics:
  duration: "43s"
  completed: "2026-04-04"
  tasks_completed: 1
  tasks_total: 1
  files_changed: 1
requirements_completed: [NAV-01, NAV-02]
---

# Phase 103 Plan 02: Landing Page Coverage Cards Summary

Coverage area cards with teal-bordered buttons for Monroe County IN and LA County CA, plus "Browse by location" link and "or search by address" divider inserted above the existing address search input.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add coverage cards, browse link, and divider to Landing.jsx | 18c0b77 (essentials) | essentials/src/pages/Landing.jsx |

## What Was Built

Updated `essentials/src/pages/Landing.jsx` to add:

1. **COVERAGE_AREAS constant** — Array of two objects with `county`, `state`, and `address` fields for Monroe County IN (100 W Kirkwood Ave, Bloomington, IN 47404) and Los Angeles County CA (500 W Temple St, Los Angeles, CA 90012).

2. **"We currently cover:" label** — 14px gray-500 text above the coverage cards.

3. **Coverage card row** — Two teal-bordered `<button>` elements side-by-side (stacked on mobile) using `flex-1 text-left px-4 py-3 bg-white border-2 border-[var(--ev-teal)]` with hover shadow and focus ring. Each card shows county name (16px semibold teal) and state (14px gray-600). Click navigates to `/results?q={encodeURIComponent(address)}`.

4. **"Browse by location →" link** — 14px teal text button below the cards, navigates to `/results?mode=browse`.

5. **"or search by address" divider** — Horizontal rule with centered text overlay (`absolute left-1/2 -translate-x-1/2`) positioned between coverage section and address input.

6. **H1 typography fix** — Changed `font-bold` to `font-semibold` to align with the 2-weight (400/600) typography system specified in UI-SPEC.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — coverage cards link to real government building addresses that return full representative data through the existing PostGIS geofence matching pipeline.

## Self-Check: PASSED

- essentials/src/pages/Landing.jsx: FOUND
- Commit 18c0b77 in essentials repo: FOUND
- `npm run build` exits 0: CONFIRMED
- All 14 acceptance criteria verified: PASSED
