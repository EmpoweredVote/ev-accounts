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
    - essentials/src/pages/Results.jsx

key-decisions:
  - "Sourced all photos from Wikimedia Commons (public domain / CC-licensed) to avoid licensing concerns"
  - "Optimized oversized images with sips to keep all under 200KB for fast load in 300px-wide sidebar"
  - "FALLBACK.Federal stays as .svg (generic SVG for unsupported locations, not the Capitol photo)"
  - "Extract city name from chamber_name regex when representing_city is empty — BallotReady transform doesn't populate representing_city"

patterns-established:
  - "Photo assets: CURATED keys are lowercase city names matching getBuildingImages() city.includes() checks"
  - "Chamber name city extraction: /^(\\w[\\w\\s]+?)\\s+City\\b/ for deriving city from BallotReady chamber_name"

requirements-completed: [IMG-01, IMG-02, IMG-03, IMG-04, IMG-05, IMG-06]

# Metrics
duration: 3min
completed: 2026-02-18
---

# Phase 9 Plan 01: Building Imagery Summary

**5 real government building JPEGs from Wikimedia Commons added to essentials sidebar; CURATED map updated from SVG placeholders to photo files for Bloomington and LA**

## Performance

- **Duration:** 12 min
- **Started:** 2026-02-18T23:53:51Z
- **Completed:** 2026-02-18
- **Tasks:** 2/2 complete (incl. human-verify approved)
- **Files modified:** 7

## Accomplishments
- Downloaded 5 real building photographs from Wikimedia Commons (public domain)
- Optimized all images to under 200KB using macOS sips tool
- Updated `buildingImages.js` CURATED paths from `.svg` to `.jpg` filenames
- FALLBACK paths unchanged — SVGs remain as fallback for unsupported cities
- Build passes (`npm run build` succeeds without errors)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add real building photographs and update image mapping** - `bcd63c5` (feat)
2. **Task 2: Verify building photos display correctly** - human-verify approved
3. **Fix: City name derivation from chamber_name** - `bd39af7` (fix)

## Files Created/Modified
- `essentials/public/images/us-capitol.jpg` - US Capitol west-side photo, 179KB, 1200x621px
- `essentials/public/images/indiana-state-house.jpg` - Indiana Statehouse, 140KB, 800x562px
- `essentials/public/images/california-state-capitol.jpg` - California State Capitol, 165KB, 618x800px
- `essentials/public/images/bloomington-city-hall.jpg` - Bloomington Showers building, 191KB, 1280x720px
- `essentials/public/images/la-city-hall.jpg` - Los Angeles City Hall, 141KB, 600x800px
- `essentials/src/lib/buildingImages.js` - CURATED paths updated to .jpg filenames
- `essentials/src/pages/Results.jsx` - Added chamber_name fallback for city derivation when representing_city is empty

## Decisions Made
- Sourced all photos from Wikimedia Commons (public domain / Creative Commons licensed) to avoid any licensing concerns for a civic app
- Used macOS `sips` to resize California State Capitol (648K → 165K) and LA City Hall (549K → 141K) and Indiana Statehouse (320K → 140K)
- Bloomington City Hall and US Capitol were already under 200KB after download
- FALLBACK.Federal stays as `us-capitol.svg` — generic SVG fallback for unsupported cities; the photo is only served via CURATED entries

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] City name derivation from chamber_name**
- **Found during:** Task 2 (Human verification)
- **Issue:** BallotReady data doesn't populate representing_city, so Bloomington image matching failed — all politicians had empty city field
- **Fix:** Added fallback in Results.jsx representingCity derivation to extract city from LOCAL politicians' chamber_name via regex `/^(\w[\w\s]+?)\s+City\b/`
- **Files modified:** essentials/src/pages/Results.jsx
- **Verification:** Bloomington photos now display correctly; LA and fallback unaffected
- **Committed in:** bd39af7

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** Essential fix for BallotReady data gap. No scope creep.

## Issues Encountered
- BallotReady transform.go doesn't map SubAreaName to RepresentingCity (backend gap). Frontend workaround applied; backend fix deferred.
- Wikimedia Commons 1280px thumbnail URLs required browser-style User-Agent header to serve successfully.

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness
- Building imagery complete for Bloomington and LA
- Scroll-spy and tier filter photo swap verified by human
- Ready for Phase 10 (Term Dates)

---
*Phase: 09-building-imagery*
*Completed: 2026-02-18*
