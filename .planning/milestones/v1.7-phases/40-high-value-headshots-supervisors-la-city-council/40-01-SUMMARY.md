---
phase: 40-high-value-headshots-supervisors-la-city-council
plan: 01
subsystem: infra
tags: [python, supabase, storage, scraping, headshots, la-county, pipeline-config, psycopg2]

# Dependency graph
requires:
  - phase: 39-schema-and-infrastructure-preparation
    provides: upload_photo_to_storage() in utils.py, load_pipeline_config(), pipeline_config.json, photo_license column on politician_images, politician-photos Supabase bucket
provides:
  - pipeline_config.json headshots registry: 5 supervisor + 15 council photo source URLs with license tracking
  - scrape_headshots.py: config-driven headshot scraper with Supabase Storage upload and idempotent DB upsert
  - 14/15 LA City Council photo URLs verified (Monica Rodriguez CD7 has no available portrait)
  - 5/5 LA County Supervisor photo URLs verified (kc-usercontent.com CDN)
affects:
  - 41-contact-and-building-enrichment
  - 42-biography-enrichment
  - 44-data-quality-and-validation

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Config-driven headshot registry in pipeline_config.json — photo URLs verified once, stable for months, no fragile runtime HTML scraping
    - Content-type derived from response Content-Type header (not URL extension) — avoids image/jpeg default for .webp files
    - Idempotent upsert via SELECT then UPDATE/INSERT — no UNIQUE constraint required on politician_images
    - Per-politician error handling with try/except in scrape loop — one failed download does not abort the batch
    - 1-second download delay between requests — rate limiting for government CDNs

key-files:
  created:
    - EV-Backend/scripts/scrape_headshots.py
  modified:
    - EV-Backend/scripts/pipeline_config.json

key-decisions:
  - "Wikipedia Commons photos assigned cc_by_sa_4.0 license — 10 of 15 council members have Commons portraits"
  - "Monica Rodriguez CD7 set to null photo_url — no portrait available (only landscape action photos on cd7.lacity.gov, no Wikipedia article)"
  - "Storage filenames use human-readable name slugs (e.g., hilda-l-solis.jpg) not UUIDs — readable in Supabase bucket browser"
  - "scrape_headshots.py does not import SQLAlchemy — uses psycopg2 directly consistent with other Phase 40 scripts"
  - "Content-type detected from response header not URL — government CDNs sometimes serve .jpg URLs with image/webp content-type"

patterns-established:
  - "Headshot registry pattern: headshots.supervisors and headshots.la_city_council arrays in pipeline_config.json la_county section"
  - "Null photo_url with note field for officials with no available headshot — script skips with informative message"

requirements-completed: [PHOTO-01, PHOTO-02, PHOTO-04, PHOTO-05]

# Metrics
duration: 10min
completed: 2026-02-25
---

# Phase 40 Plan 01: High-Value Headshots — Config and Script Summary

**Config-driven headshot scraper with 19/20 verified photo URLs (14 Wikipedia Commons CC-licensed, 5 government CDN) and idempotent Supabase Storage upload pipeline**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-02-25T01:51:37Z
- **Completed:** 2026-02-25T02:01:53Z
- **Tasks:** 2 of 2 completed
- **Files modified:** 2

## Accomplishments
- Populated pipeline_config.json with verified headshot URLs for all 5 LA County supervisors (kc-usercontent.com JPEG CDN) and 14/15 LA City Council members (10 Wikipedia Commons + 4 government sites)
- Created scrape_headshots.py (~200 lines) with download, Supabase Storage upload, and idempotent DB upsert logic
- Documented Monica Rodriguez CD7 as null (no portrait available anywhere — only landscape action photos on the district site, no Wikipedia article)
- License tracking implemented across all 19 entries: scraped_no_license for government sites, press_use for CD4 press kit, cc_by_sa_4.0 for Wikipedia Commons

## Task Commits

Each task was committed atomically in EV-Backend repo:

1. **Task 1: Verify and populate photo URLs for all 20 officials in pipeline_config.json** - `5a729d9` (feat)
2. **Task 2: Create scrape_headshots.py with download, upload, and idempotent upsert logic** - `a321e54` (feat)

## Files Created/Modified
- `EV-Backend/scripts/pipeline_config.json` - Added headshots section with supervisors (5) and la_city_council (15) arrays
- `EV-Backend/scripts/scrape_headshots.py` - New script: config-driven headshot scraper with download_image, find_politician_id, upsert_politician_image, process_headshot, main functions

## Decisions Made
- Wikipedia Commons chosen as primary source for 10 council members that lack dedicated headshots on their district sites — CC-licensed, stable URLs, proper portrait orientation
- Monica Rodriguez (CD7) assigned null photo_url with documented note — cd7.lacity.gov has only landscape event/action photos; no Wikipedia Commons portrait exists
- Storage filenames are human-readable name slugs rather than UUIDs — makes Supabase bucket browser navigable
- Content-type detection uses HTTP response header, not URL extension — protects against .jpg URLs served as image/webp by some government CDNs

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- cd7.lacity.gov (Monica Rodriguez CD7): site has no dedicated headshot — only landscape event/action photos confirmed via HTTP download and dimension check (1400x800). Wikipedia search returned no Monica Rodriguez article for an LA politician. Documented as null per plan instructions.
- cd2.lacity.gov (Adrin Nazarian CD2) and cd3.lacity.gov (Bob Blumenfield CD3): government sites have no dedicated portrait. Wikipedia confirmed portraits for both (2018 official photos).

## User Setup Required
None - no new external service configuration required. Supabase bucket and credentials are from Phase 39 setup.

## Next Phase Readiness
- `python3 scrape_headshots.py --dry-run --group supervisors` downloads supervisor photos without touching Supabase or DB
- `python3 scrape_headshots.py` runs the full pipeline (requires DATABASE_URL + SUPABASE_URL + SUPABASE_SERVICE_KEY in .env.local)
- Monica Rodriguez (CD7) headshot remains unresolved — may need manual search for a press release image in a future pass
- Phase 41 enrichment scripts can follow the same pattern: add a new section to pipeline_config.json headshots and call the scraper

## Self-Check: PASSED

- FOUND: EV-Backend/scripts/pipeline_config.json (headshots section added)
- FOUND: EV-Backend/scripts/scrape_headshots.py (431 lines, all 5 required functions)
- FOUND: commit 5a729d9 (Task 1 - pipeline_config.json headshots registry)
- FOUND: commit a321e54 (Task 2 - scrape_headshots.py)

---
*Phase: 40-high-value-headshots-supervisors-la-city-council*
*Completed: 2026-02-25*
