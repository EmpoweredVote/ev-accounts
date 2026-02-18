---
phase: 09-building-imagery
plan: 01
subsystem: ui
tags: [images, assets, react, vite, essentials]

# Dependency graph
requires:
  - phase: 08-layout
    provides: sidebar with building image display and scroll-spy tier-swap wiring
provides:
  - Real JPEG photographs for 5 government buildings (US Capitol, Indiana Statehouse, California State Capitol, Bloomington City Hall, LA City Hall)
  - Updated CURATED path mapping in buildingImages.js pointing to .jpg photo files
affects: [essentials]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "CURATED map holds city-specific real photograph paths (.jpg); FALLBACK holds generic SVG illustration paths (.svg)"

key-files:
  created:
    - essentials/public/images/us-capitol.jpg
    - essentials/public/images/indiana-state-house.jpg
    - essentials/public/images/california-state-capitol.jpg
    - essentials/public/images/bloomington-city-hall.jpg
    - essentials/public/images/la-city-hall.jpg
  modified:
    - essentials/src/lib/buildingImages.js

key-decisions:
  - "Sourced all photos from Wikimedia Commons (public domain / CC-licensed) to avoid licensing concerns"
  - "Optimized oversized images with sips to keep all under 200KB for fast load in 300px-wide sidebar"
  - "FALLBACK.Federal stays as .svg (generic SVG for unsupported locations, not the Capitol photo)"

patterns-established:
  - "Photo assets: CURATED keys are lowercase city names matching getBuildingImages() city.includes() checks"

requirements-completed: [IMG-01, IMG-02, IMG-03, IMG-04, IMG-05, IMG-06]

# Metrics
duration: 3min
completed: 2026-02-18
---

# Phase 9 Plan 01: Building Imagery Summary

**5 real government building JPEGs from Wikimedia Commons added to essentials sidebar; CURATED map updated from SVG placeholders to photo files for Bloomington and LA**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-18T23:53:51Z
- **Completed:** 2026-02-18T23:56:38Z
- **Tasks:** 1 of 2 complete (Task 2 is human-verify checkpoint)
- **Files modified:** 6

## Accomplishments
- Downloaded 5 real building photographs from Wikimedia Commons (public domain)
- Optimized all images to under 200KB using macOS sips tool
- Updated `buildingImages.js` CURATED paths from `.svg` to `.jpg` filenames
- FALLBACK paths unchanged — SVGs remain as fallback for unsupported cities
- Build passes (`npm run build` succeeds without errors)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add real building photographs and update image mapping** - `bcd63c5` (feat)

## Files Created/Modified
- `essentials/public/images/us-capitol.jpg` - US Capitol west-side photo, 179KB, 1200x621px
- `essentials/public/images/indiana-state-house.jpg` - Indiana Statehouse, 140KB, 800x562px
- `essentials/public/images/california-state-capitol.jpg` - California State Capitol, 165KB, 618x800px
- `essentials/public/images/bloomington-city-hall.jpg` - Bloomington Showers building, 191KB, 1280x720px
- `essentials/public/images/la-city-hall.jpg` - Los Angeles City Hall, 141KB, 600x800px
- `essentials/src/lib/buildingImages.js` - CURATED paths updated to .jpg filenames

## Decisions Made
- Sourced all photos from Wikimedia Commons (public domain / Creative Commons licensed) to avoid any licensing concerns for a civic app
- Used macOS `sips` to resize California State Capitol (648K → 165K) and LA City Hall (549K → 141K) and Indiana Statehouse (320K → 140K)
- Bloomington City Hall and US Capitol were already under 200KB after download
- FALLBACK.Federal stays as `us-capitol.svg` — generic SVG fallback for unsupported cities; the photo is only served via CURATED entries

## Deviations from Plan

None — plan executed exactly as written. The only minor discovery was that Wikimedia Commons 1280px thumbnail URLs required a browser-style User-Agent header to serve successfully (not a deviation, just a curl flag).

## Issues Encountered
- First curl attempts for Indiana Statehouse returned HTML error pages (Wikimedia rate-limiting plain curl UA). Fixed by adding `-H "User-Agent: Mozilla/5.0..."` header.
- The `essentials/` directory has its own git repo separate from the workspace root — committed to `essentials/.git` rather than the workspace root git.

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness
- All 5 building photos are committed and the build passes
- Human verification (Task 2) required: visit http://localhost:5175/ and test ZIP 47401 (Bloomington), 90001 (LA), 10001 (New York fallback)
- After approval, phase 9 is complete

---
*Phase: 09-building-imagery*
*Completed: 2026-02-18*
