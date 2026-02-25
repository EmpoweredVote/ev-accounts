---
phase: 42-city-council-headshot-pipeline
plan: 02
subsystem: data-pipeline
tags: [python, web-scraping, playwright, beautifulsoup, psycopg2, supabase, cloudflare, wikipedia]

# Dependency graph
requires:
  - phase: 42-01
    provides: scrape_city_headshots.py, Cloudflare detection, name-proximity extraction, --check-coverage flag

provides:
  - headshot_status tracking for all 89 cities in city_sources.json
  - 55 city council headshots uploaded to Supabase Storage CDN
  - False positive cleanup: 3 wrong Wikipedia matches removed
  - SQL/CDN coverage baseline: 64/391 LOCAL/LOCAL_EXEC politicians with CDN headshots (16.4%)

affects:
  - Future phases that rely on headshot coverage for city council members

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Wikipedia strategy 3 has false positive risk for common names (Ray Pearl->historical Dr. Raymond Pearl, Octavio Martinez->Mexican general)
    - Name-proximity extraction only works when member images are HTML-inline near name text nodes; CSS-grid card galleries fail
    - 16-17 cities failed with DNS/SSL errors (dead URLs in city_sources.json need research)
    - duplicate_url_detected catches logo pollution: Claremont served same Jennifer Stark photo for all 4 members
    - Retry loop: reset fetch_failed cities, keep blocked and duplicate_url_detected

key-files:
  created: []
  modified:
    - EV-Backend/scripts/city_sources.json

key-decisions:
  - "80% SQL coverage target NOT met: 64/391 = 16.4% — name-proximity HTML extraction works for city sites that embed per-member portrait imgs inline; fails for CMS card galleries and JS-rendered pages"
  - "False positive cleanup: deleted 3 Wikipedia wrong matches — 668-byte Octavio Martinez PNG (Mexican flag), 20KB Ray Pearl (historical biologist 1879-1940), Adrin Nazarian with Ara Najarian photo"
  - "No duplicate (politician_id, type=default) rows confirmed; plan verification query had bug (GROUP BY full_name catches homonyms like two Alex Padillas with different UUIDs)"
  - "19 failed cities have persistent DNS/SSL errors indicating dead city_sources.json URLs that need manual URL research"

patterns-established:
  - "Pattern: run scraper, remove false positives, run --check-coverage to validate remaining images"
  - "Pattern: city URLs in city_sources.json may go stale — DNS errors on retry indicate city changed domain"

requirements-completed: []

# Metrics
duration: 55min
completed: 2026-02-25
---

# Phase 42 Plan 02: Execute City Council Headshot Scraper Summary

**scrape_city_headshots.py executed against all 89 LA County cities: 55 headshots uploaded, 16.4% SQL coverage (64/391 politicians), 80% target not met due to CSS card gallery layouts that block name-proximity extraction**

## Performance

- **Duration:** 55 min
- **Started:** 2026-02-25T13:15:00Z
- **Completed:** 2026-02-25T14:10:00Z
- **Tasks:** 1 complete, 1 checkpoint (human-verify, blocking)
- **Files modified:** 1

## Accomplishments

- Executed scrape_city_headshots.py against all 89 LA County cities (2 runs: initial + retry of failed cities)
- Processed 69 cities successfully, 1 Cloudflare-blocked (Burbank), 19 failed with persistent errors
- Uploaded 55 headshots from 27 cities to Supabase Storage CDN under la_county/cities/{city}/
- headshot_status field set for every city in city_sources.json (scraped/blocked/failed)
- Identified and removed 3 false positive Wikipedia matches before checkpoint
- SQL verification confirms: no government hotlinks, no duplicate rows by politician_id

## Task Commits

Each task was committed atomically:

1. **Task 1: Execute scrape_city_headshots.py and verify database results** - `717af6a` (feat)

Task 2 is a blocking checkpoint — awaiting human verification of headshot appearance on profile pages.

## Files Created/Modified

- `EV-Backend/scripts/city_sources.json` - headshot_status added for all 89 cities (scraped/blocked/failed)

## Decisions Made

- Confirmed no duplicate (politician_id, type=default) rows exist. The plan's verification query used `GROUP BY full_name` which incorrectly flagged two different "Alex Padilla" politicians (Inglewood city council + US Senator) as duplicates — these are distinct politician_ids.
- Removed 3 confirmed false positive Wikipedia matches:
  - Octavio Martinez (Whittier): matched https://en.wikipedia.org/wiki/Octavio_Martinez (historical Mexican general), got 668-byte Mexican flag PNG
  - Ray Pearl (Westlake Village): matched https://en.wikipedia.org/wiki/Ray_Pearl (historical biologist 1879-1940), photo wrong person
  - Adrin Nazarian (Glendale): name-proximity matched Ara Najarian's photo on Glendale council page (both on same council, different member)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed 3 false positive Wikipedia and name-proximity matches**
- **Found during:** Task 1 (database verification step)
- **Issue:** Wikipedia strategy 3 matched common names to historical figures; name-proximity matched wrong council member in Glendale
- **Fix:** Deleted 3 DB records with confirmed wrong photos before checkpoint
- **Files modified:** essentials.politician_images (3 rows deleted)
- **Verification:** Remaining 64 CDN headshots verified — no obvious mismatches in sample review
- **Committed in:** 717af6a (Task 1 commit includes cleanup)

---

**Total deviations:** 1 auto-fixed (Rule 1 bug — false positive cleanup)
**Impact on plan:** Essential for data quality. Prevents wrong headshots appearing on profile pages. No scope creep.

## Issues Encountered

**Coverage gap:** The plan target of 80% (313+ of 391 politicians) was not met. Actual coverage: 16.4% (64/391). The name-proximity extraction strategy works when city council pages embed per-member portrait images as inline `<img>` tags near the member's name text. However, the majority of LA County city websites use CMS-rendered CSS card galleries where the images are loaded via background-image CSS (not `<img>` tags), or the image src attributes contain generic council photo filenames without per-member proximity anchors. Playwright renders the full page but still only captures `<img>` tags in the DOM — CSS background images are not captured.

**Failed cities (19):** 16 have persistent DNS or SSL errors indicating dead URLs in city_sources.json. These are not transient failures — they fail identically on retry. Manual URL research needed.

**Status distribution:**
- Scraped: 69 cities (55 headshots total)
- Blocked (Cloudflare): 1 city (Burbank)
- Failed: 19 cities (16 DNS/fetch_failed, 2 duplicate_url_detected, 1 SSL error)
- Cities with at least 1 headshot: 27 of 69 scraped

**Best performers (100% roster coverage):** Long Beach (8/8), Covina (5/5), Pico Rivera (4/4), Santa Clarita (4/4) — these cities have inline per-member portrait images with names as adjacent text nodes.

## User Setup Required

None — scraper ran using existing .env.local credentials from Phase 39.

## Next Phase Readiness

- All 89 cities have headshot_status set in city_sources.json
- 55 headshots from 27 cities are live in Supabase Storage CDN
- The 80% coverage target requires ~249 additional headshots
- Human checkpoint (Task 2) is BLOCKING — user must verify that headshots appear on profile pages for the ~27 cities that do have photos
- To increase coverage further, the city_sources.json roster entries would need `headshot_url` manually populated per member for the cities that failed extraction, OR a different extraction strategy for CSS background-image galleries

## Checkpoint Reached

Task 2 is a blocking human-verify checkpoint. Human must verify that headshots appear on profile pages for the cities that were successfully scraped (Long Beach, Covina, Glendale, etc.) before this plan can be marked complete.

---
*Phase: 42-city-council-headshot-pipeline*
*Completed: 2026-02-25*

## Self-Check

- FOUND: `EV-Backend/scripts/city_sources.json` (modified with headshot_status for all 89 cities)
- FOUND: commit `717af6a` — feat(42-02): execute batch headshot scraper for 89 LA County cities
- FOUND: 64 CDN headshot rows in essentials.politician_images with supabase.co URLs (verified via SQL)
- FOUND: `.planning/phases/42-city-council-headshot-pipeline/42-02-SUMMARY.md` (this file)

## Self-Check: PASSED
