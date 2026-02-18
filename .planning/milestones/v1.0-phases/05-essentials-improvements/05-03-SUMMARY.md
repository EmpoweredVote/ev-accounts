---
phase: 05-essentials-improvements
plan: 03
subsystem: ui
tags: [react, essentials, politician-cards, scroll-spy, building-images, intersection-observer]

# Dependency graph
requires:
  - phase: 05-01
    provides: term_start/term_end fields in OfficialOut API response
provides:
  - Term dates displayed below politician cards in "Mon YYYY — Mon YYYY" format
  - Building image swap on scroll via IntersectionObserver scroll-spy
  - buildingImages.js module with curated Bloomington/LA images and generic fallbacks
  - 7 SVG placeholder images in essentials/public/images/
affects:
  - essentials Results page (display layer)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "IntersectionObserver with -40%/0/-60%/0 rootMargin for mid-viewport tier detection"
    - "data-tier attributes on section divs enable scroll-spy without refs"
    - "getBuildingImages(city) returns tier->path map; fallback chain: curated->FALLBACK"
    - "Term date hidden entirely when term_start absent — no empty placeholder"

key-files:
  created:
    - essentials/src/lib/buildingImages.js
    - essentials/public/images/us-capitol.svg
    - essentials/public/images/indiana-state-capitol.svg
    - essentials/public/images/california-state-capitol.svg
    - essentials/public/images/bloomington-city-hall.svg
    - essentials/public/images/la-city-hall.svg
    - essentials/public/images/city-hall-generic.svg
    - essentials/public/images/state-capitol-generic.svg
  modified:
    - essentials/src/pages/Results.jsx

key-decisions:
  - "SVG placeholder files with .svg extension instead of .jpg — simpler MVP; real photos replace by updating buildingImages.js mapping"
  - "Term date rendered below card in wrapper div (not inside PoliticianCard title prop) — avoids ev-ui modifications and clamping issues"
  - "Scroll-spy only active when selectedFilter === All — specific tier filters use static image for that tier"
  - "margin-left: 92px on term date p tag aligns with card content area (80px image + 12px padding)"

patterns-established:
  - "Building image selection: getBuildingImages(city).toLowerCase() checks for city substring match"
  - "Tier wrapping: all three tier blocks (Local/State/Federal) use <div data-tier='X'> for IntersectionObserver targeting"

requirements-completed: [ESST-04, ESST-06]

# Metrics
duration: 3min
completed: 2026-02-18
---

# Phase 5 Plan 03: Term Dates + Building Images Summary

**Term dates on politician cards with IntersectionObserver scroll-spy that swaps building images per tier, with curated Bloomington/LA images and SVG placeholders for all localities**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-18T17:07:10Z
- **Completed:** 2026-02-18T17:09:55Z
- **Tasks:** 2
- **Files modified:** 9 (1 modified, 8 created)

## Accomplishments
- Created `buildingImages.js` with `getBuildingImages()` returning tier-to-image-path maps — curated for Bloomington IN and Los Angeles CA, generic fallback for all other localities
- Added 7 SVG placeholder images (300x375, 4:5 aspect ratio) with colored backgrounds and building name labels
- Added `formatTermDate` / `getTermLine` helpers to Results.jsx — renders "Jan 2023 — Dec 2026" format, hidden when `term_start` absent
- Implemented IntersectionObserver scroll-spy with `-40% 0px -60% 0px` rootMargin — swaps building image as user scrolls through tier sections in "All" filter mode
- Wrapped all three tier sections (Local/State/Federal) in `data-tier` divs for observer targeting
- Static building image selected from tier filter when a specific tier (not "All") is active
- Build passes cleanly: `npx vite build` succeeds in 717ms

## Task Commits

Each task was committed atomically:

1. **Task 1: Building images module and SVG placeholders** - `495f7c6` (feat)
2. **Task 2: Term dates and scroll-spy building images to Results.jsx** - `3eb0106` (feat)

## Files Created/Modified
- `essentials/src/lib/buildingImages.js` - getBuildingImages(city) with CURATED + FALLBACK maps
- `essentials/public/images/us-capitol.svg` - US Capitol placeholder (used for Federal tier)
- `essentials/public/images/indiana-state-capitol.svg` - Indiana state capitol placeholder
- `essentials/public/images/california-state-capitol.svg` - California state capitol placeholder
- `essentials/public/images/bloomington-city-hall.svg` - Bloomington City Hall placeholder
- `essentials/public/images/la-city-hall.svg` - LA City Hall placeholder
- `essentials/public/images/city-hall-generic.svg` - Generic local government placeholder
- `essentials/public/images/state-capitol-generic.svg` - Generic state capitol placeholder
- `essentials/src/pages/Results.jsx` - All scroll-spy, term date, and building image logic

## Decisions Made
- Used `.svg` extension (not `.jpg`) in buildingImages.js for MVP — simpler to create valid placeholder files; real photographs can replace them later by updating the filenames in the module
- Term dates rendered in a wrapper `<div>` below `PoliticianCard` rather than modifying the `title` prop — avoids line-clamping truncation issues and keeps ev-ui unchanged
- `margin-left: 92px` on the term date `<p>` element aligns it visually with the card's text content area (80px image + 12px padding)
- Scroll-spy IntersectionObserver only instantiated when `selectedFilter === 'All'` — when a specific tier filter is active, building image is derived statically from `buildingImageMap[selectedFilter]`

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Term dates are live on all politician cards in Results page when backend provides `term_start`/`term_end`
- Building images scaffold is in place; real photos can be dropped in by replacing SVG files and updating `buildingImages.js` filenames
- Ready for plan 04 (already completed) and plan 05

---
*Phase: 05-essentials-improvements*
*Completed: 2026-02-18*
