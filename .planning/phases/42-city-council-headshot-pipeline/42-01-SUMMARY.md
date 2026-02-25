---
phase: 42-city-council-headshot-pipeline
plan: 01
subsystem: data-pipeline
tags: [python, web-scraping, playwright, beautifulsoup, psycopg2, supabase, cloudflare, rapidfuzz, wikipedia]

# Dependency graph
requires:
  - phase: 40-high-value-headshots-supervisors-la-city-council
    provides: upload_photo_to_storage(), idempotent upsert pattern, Supabase Storage bucket
  - phase: 41-photos-term-dates-contacts
    provides: politician_images schema with photo_license column
  - phase: 37-city-council-scraper
    provides: city_sources.json with 89-city roster, scrape_city_councils.py patterns

provides:
  - scrape_city_headshots.py: batch headshot scraper for 89 LA County city councils
  - Cloudflare detection with cf-ray + status-code dual check
  - Name-proximity heuristic with Wikipedia fallback for headshot extraction
  - Per-city status tracking (headshot_status, headshot_scraped_at, headshot_count)
  - --check-coverage flag for HEAD-request CDN validation (PHOTO-03)

affects:
  - 42-02: execution and coverage validation plan uses this script

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Cloudflare detection: BOTH HTTP status (403/429/503) AND cf-ray/server header — status alone causes false positives
    - Name-proximity headshot extraction: walk up to 4 parent DOM levels from name text node to find nearby img
    - Wikipedia fallback: fetch https://en.wikipedia.org/wiki/First_Last, extract .infobox img, 2s pre-request delay
    - Duplicate URL detection: if all city members share the same extracted URL, mark as failed (not scraped)
    - Levenshtein fuzzy last-name matching (threshold<=1) as fallback after ILIKE exact match fails
    - make_storage_path: strips _city_council suffix, slugifies name, returns la_county/cities/{city}/{name}.ext

key-files:
  created:
    - EV-Backend/scripts/scrape_city_headshots.py
  modified: []

key-decisions:
  - "extract_headshot_url uses 3-strategy approach: name proximity, alt-text scan, Wikipedia fallback — returns None over wrong image (false negatives preferred)"
  - "Cloudflare detection requires BOTH status code AND header — 403 without cf-ray is a regular error, not a Cloudflare block"
  - "Duplicate URL detection clears all member URLs for a city when all map to same image — prevents logo pollution"
  - "find_politician_id queries only scraped politicians for fuzzy fallback (LIMIT 5000) to avoid false matches with BallotReady-synced officials"

patterns-established:
  - "Pattern: per-city headshot pipeline — fetch page -> extract URLs -> detect duplicates -> download -> upload -> upsert -> commit"
  - "Pattern: make_storage_path('burbank_city_council', 'Jess Talamantes', 'jpg') -> 'la_county/cities/burbank/jess-talamantes.jpg'"

requirements-completed: [PHOTO-03, PIPE-02]

# Metrics
duration: 4min
completed: 2026-02-25
---

# Phase 42 Plan 01: City Council Headshot Scraper Summary

**scrape_city_headshots.py — 11-function batch headshot scraper for 89 LA County city councils with Cloudflare detection, BeautifulSoup name-proximity extraction, Playwright fallback, and CDN coverage validation**

## Performance

- **Duration:** 4 min
- **Started:** 2026-02-25T18:05:25Z
- **Completed:** 2026-02-25T18:09:59Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Built complete `scrape_city_headshots.py` (962 lines) with all 11 required functions ready to run against live DB
- All unit-level validations pass: import, storage paths, Cloudflare detection, headshot extraction heuristic, --help
- Script enforces 1.5s inter-city delay (PIPE-02), per-city DB COMMIT isolation, idempotent re-run via headshot_status field
- Wikipedia fallback (Strategy 3) augments city-site extraction for higher-profile council members with Wikipedia articles

## Task Commits

Each task was committed atomically:

1. **Task 1: Create scrape_city_headshots.py with all core functions** - `07ea1bc` (feat)
2. **Task 2: Validate script syntax and dry-run behavior** - `07ea1bc` (validated, no changes needed)

**Plan metadata:** see final docs commit

## Files Created/Modified
- `EV-Backend/scripts/scrape_city_headshots.py` - Batch headshot scraper for 89 LA County city councils

## Decisions Made
- `extract_headshot_url` uses a 3-strategy cascade: (1) name-proximity walking DOM parents, (2) alt-text scan, (3) Wikipedia infobox. Returns None rather than a wrong image — false negatives are acceptable, false positives (logo for a council member) are not.
- Cloudflare detection requires BOTH HTTP status (403/429/503) AND cf-ray or server:cloudflare header. A plain 403 from nginx is marked "failed" (will retry), not "blocked" (would skip forever).
- `find_politician_id` fuzzy fallback limits search to `source = 'scraped'` politicians to avoid ambiguous matches with BallotReady-synced officials who may share last names.
- Duplicate URL detection (Pitfall 3 from RESEARCH.md): after extracting all member URLs for a city, if they are all identical and more than one exists, the city is marked failed with "duplicate_url_detected" reason for manual review.

## Deviations from Plan

None — plan executed exactly as written. All 11 functions implemented, all validation steps passed on first attempt with no bug fixes required.

## Issues Encountered
- The workspace root `/Users/chrisandrews/Documents/GitHub` is not a tracked git repo — all files show as untracked. EV-Backend is its own git repo. Committed from `EV-Backend/` directory instead of workspace root. This is consistent with prior commits in the EV-Backend repo history.
- Task 2 (validation) required no code changes — script was correct on first write. Task 2 has no separate commit because no source files were modified.

## User Setup Required
None — no external service configuration required. Script uses existing .env.local credentials from Phase 39.

## Next Phase Readiness
- `scrape_city_headshots.py` is ready to run against the live database
- Plan 42-02 executes the scraper, validates coverage, and verifies headshots appear on profile pages
- Run with `python3 scrape_city_headshots.py --limit 10` first to spot-check extraction quality before full run
- Run `--check-coverage` after full run to validate 80%+ CDN availability (PHOTO-03)

---
*Phase: 42-city-council-headshot-pipeline*
*Completed: 2026-02-25*

## Self-Check: PASSED

- FOUND: `EV-Backend/scripts/scrape_city_headshots.py`
- FOUND: `.planning/phases/42-city-council-headshot-pipeline/42-01-SUMMARY.md`
- FOUND: commit `07ea1bc` — feat(42-01): create scrape_city_headshots.py batch headshot scraper
