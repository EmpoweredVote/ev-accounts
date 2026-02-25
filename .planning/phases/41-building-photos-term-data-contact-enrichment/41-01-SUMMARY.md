---
phase: 41-building-photos-term-data-contact-enrichment
plan: 01
subsystem: database
tags: [wikimedia, supabase, python, building-photos, cdn, essentials]

# Dependency graph
requires:
  - phase: 39-schema-and-infrastructure-preparation
    provides: essentials.building_photos table, Supabase Storage bucket, upload_photo_to_storage utility
  - phase: 40-high-value-headshots
    provides: Established pipeline pattern (scrape_headshots.py, pipeline_config.json, utils.py)
provides:
  - 11 city hall building photos uploaded to Supabase Storage CDN (la_county/building_photos/ prefix)
  - essentials.building_photos table populated with CDN URLs, license, and attribution for 11 LA County cities
  - fetch_building_photos.py — reusable Wikimedia Commons fetch + Supabase upload script
  - pipeline_config.json building_photos section with 11 verified Wikimedia file titles
  - buildingImages.js CURATED_LOCAL expanded with CDN URLs for all 11 LA County cities
affects:
  - 41-02-PLAN.md (term date enrichment — same pipeline pattern)
  - 41-03-PLAN.md (contact import — same pipeline pattern)
  - essentials app frontend (buildingImages.js now serves CDN photos for 11 cities)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Wikimedia Commons imageinfo API fetch with extmetadata for CC license + attribution
    - HTML tag stripping with re.sub for Wikimedia Artist field (returns <a href=...> HTML)
    - License enum mapping from Wikimedia LicenseShortName to internal values
    - Time.sleep(1.0) rate limiting between Wikimedia API calls
    - CDN URL hardcoded in buildingImages.js CURATED_LOCAL (simpler than API endpoint for fixed 11 cities)

key-files:
  created:
    - EV-Backend/scripts/fetch_building_photos.py
  modified:
    - EV-Backend/scripts/pipeline_config.json
    - essentials/src/lib/buildingImages.js

key-decisions:
  - "buildingImages.js CURATED_LOCAL uses hardcoded CDN URLs (not API endpoint) — simpler for fixed 11 cities, avoids Go endpoint complexity"
  - "LA City (0644000) now served from Supabase CDN instead of static /images/la-city-hall.jpg — CDN is re-scrape-safe"
  - "File extension derived from HTTP Content-Type header (not URL extension) — consistent with scrape_headshots.py pattern"

patterns-established:
  - "Wikimedia API pattern: fetch_wikimedia_image_info() returns dict(url, license, attribution, wiki_title) or None"
  - "Building photo storage path: la_county/building_photos/{place_geoid}.{ext}"

requirements-completed: [BLDG-01, BLDG-02, BLDG-03]

# Metrics
duration: 5min
completed: 2026-02-25
---

# Phase 41 Plan 01: Building Photos — Wikimedia Commons fetch and Supabase CDN upload for 11 LA County cities

**11 Wikimedia Commons city hall photos fetched, uploaded to Supabase Storage, and served via CDN URLs in buildingImages.js CURATED_LOCAL — replacing static file fallbacks with CC-licensed photos**

## Performance

- **Duration:** 5 min
- **Started:** 2026-02-25T15:21:00Z
- **Completed:** 2026-02-25T15:26:05Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- All 11 confirmed LA County city hall photos fetched from Wikimedia Commons API with license + attribution metadata
- Photos uploaded to Supabase Storage (`politician-photos` bucket, `la_county/building_photos/` prefix) with stable CDN URLs
- `essentials.building_photos` table populated with 11 rows — CDN URL, source URL, license, attribution, wiki_title, fetched_at
- `essentials/src/lib/buildingImages.js` CURATED_LOCAL expanded from 2 entries to 12 (11 LA County cities + bloomington)
- LA City now served from Supabase CDN instead of bundled static file — satisfies BLDG-01
- `fetch_building_photos.py` supports `--dry-run` flag; all 11 dry-run + live runs had 0 errors

## Task Commits

Each task was committed atomically:

1. **Task 1: Add building_photos config and create fetch_building_photos.py** - `442d1d9` (feat) — EV-Backend repo
2. **Task 2: Run script and update buildingImages.js with CDN URLs** - `9982ad2` (feat) — essentials repo

## Files Created/Modified
- `EV-Backend/scripts/fetch_building_photos.py` — Wikimedia API fetch, image download, Supabase upload, DB upsert script with dry-run support
- `EV-Backend/scripts/pipeline_config.json` — Added `building_photos` array with 11 entries (city, place_geoid, wiki_title, license)
- `essentials/src/lib/buildingImages.js` — CURATED_LOCAL expanded with 11 Supabase CDN URLs for LA County cities

## Decisions Made
- Used hardcoded CDN URLs in buildingImages.js (Pattern: Alternative Simplest Approach from RESEARCH.md) instead of a new Go API endpoint — avoids architectural complexity for a fixed set of 11 cities
- LA City CDN URL replaces `/images/la-city-hall.jpg` static reference — CDN is more maintainable (re-scrape updates the photo without code deploy)
- Content-type from HTTP response header (not URL extension) — consistent with scrape_headshots.py; some Wikimedia .JPG files are served as image/jpeg not image/jpg

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None. All 11 cities confirmed available on Wikimedia Commons and uploaded successfully on first run.

## User Setup Required
None - no external service configuration required beyond existing .env.local credentials (already set up in Phase 39).

## Next Phase Readiness
- Building photos live on CDN, CURATED_LOCAL updated — frontend will show city hall photos for 11 LA County cities immediately
- `fetch_building_photos.py` pattern can be reused for additional cities in future phases
- Phase 41-02 (term dates) and 41-03 (contacts) can proceed independently — same pipeline infrastructure

---
*Phase: 41-building-photos-term-data-contact-enrichment*
*Completed: 2026-02-25*
