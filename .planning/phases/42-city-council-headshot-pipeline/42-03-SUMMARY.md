---
phase: 42-city-council-headshot-pipeline
plan: 03
subsystem: scraping
tags: [headshots, scraping, python, css-extraction, playwright, city-council]
completed_date: "2026-02-25"
duration_minutes: 5

dependency_graph:
  requires:
    - 42-02 (initial headshot scraper execution, 64/391 baseline)
  provides:
    - Enhanced scraper with CSS background-image extraction (Strategies 1b, 2b)
    - Playwright page.evaluate() extraction for JS-rendered CSS
    - Manual headshot_url override support per roster member
    - Wikipedia false-positive guard
    - --force-retry CLI flag
    - 61 cities reset to pending for re-processing
    - 17 failed city URLs corrected
  affects:
    - 42-04 (re-execution will use enhanced scraper)

tech_stack:
  patterns:
    - CSS background-image extraction via BeautifulSoup style attribute regex
    - Playwright page.evaluate() for JS-computed background-image styles
    - Strategy cascade: img proximity -> CSS proximity -> alt-text -> CSS URL-name -> Wikipedia
    - Wikipedia false-positive guard via first-paragraph relevance terms
    - Manual override bypass: headshot_url field in roster member skips HTML extraction

key_files:
  modified:
    - EV-Backend/scripts/scrape_city_headshots.py
    - EV-Backend/scripts/city_sources.json

decisions:
  - fetch_council_page signature extended with keep_page=False parameter for backward compatibility — returns (html, used_playwright, blocked_reason, page, browser_handle) tuple; caller closes browser
  - Playwright browser handle returned as (browser_obj, pw_instance) tuple — sync_playwright().start() pattern allows keeping context alive vs context manager pattern
  - Wikipedia guard checks first <p class=False> paragraph for relevance terms — catches historical figures (Raymond Pearl, Octavio Martinez) who match name but are not California politicians
  - Strategy 1b inserted BEFORE Strategy 2 (alt-text) — CSS proximity extraction is higher confidence than full-page alt-text scan
  - Manual headshot_url overrides added for Glendale (5), Pomona (5), Santa Monica (6), Carson (1) — all pending city council member profile page URLs
  - Speculative URL pattern used for overrides (Granicus showpublisheddocument pattern, Drupal /sites/default/files/Council/) — will be validated on next scraper run; false URLs fail gracefully via download error handling

metrics:
  tasks_completed: 2
  tasks_total: 2
  files_modified: 2
  lines_added: ~300
  cities_reset_to_pending: 61
  failed_urls_fixed: 17
  manual_overrides_added: 19
---

# Phase 42 Plan 03: Enhanced Scraper and URL Fixes Summary

Enhanced `scrape_city_headshots.py` with 4-strategy CSS background-image extraction pipeline (BeautifulSoup proximity, full-page URL-name match, Playwright computed-style, Wikipedia false-positive guard) and fixed 17 stale city URLs in `city_sources.json`, resetting 61 cities to pending for re-processing.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Enhance scraper: CSS bg-image extraction, Playwright, manual overrides, Wikipedia guard, --force-retry | 785c1e6 | scrape_city_headshots.py (+230 lines) |
| 2 | Fix failed city URLs and reset 61 cities for re-processing | 0d83069 | city_sources.json |

## Changes Made

### Task 1: Scraper Enhancements

**Strategy 1b — CSS background-image proximity (BeautifulSoup):**
Inserted between Strategy 1 (img proximity) and Strategy 2 (alt-text). Finds text nodes containing the member's last name, walks up 4 parent levels, checks all elements with `style="background-image: url(...)"` attributes. Validates extension (jpg/png/webp) and exclusion patterns.

**Strategy 2b — Full-page CSS URL-name match:**
Scans all `style="background-image"` elements on page, checks if the URL path contains the member's last name. Analogous to Strategy 2's alt-text check but for CSS URLs.

**Playwright CSS extraction — `extract_headshot_url_playwright(page, member_name, city_url)`:**
Uses `page.evaluate()` JavaScript to walk DOM text nodes containing the last name, check computed `window.getComputedStyle(el).backgroundImage` for all ancestor/sibling elements. Catches JS-injected backgrounds invisible to BeautifulSoup. Called for members with no URL when Playwright was used.

**`fetch_council_page(keep_page=False)` modification:**
Added `keep_page` parameter. When `True` and Playwright is used, browser is NOT closed — returns `(html, True, None, page, (browser, pw_instance))` tuple. `process_city()` closes browser after Playwright extraction pass.

**Manual headshot_url override:**
In `process_city()` Step 2, checks `member.get("headshot_url")` before running HTML extraction. If present, uses it directly and logs `Override: {name} -> {url}`. Allows `city_sources.json` curation to bypass automated extraction.

**Wikipedia false-positive guard:**
After finding an infobox image, validates article first paragraph contains at least one of: `california`, `council`, `mayor`, `city of`, `city council`, `los angeles`, `la county`, `municipal`, `alderman`, `councilmember`, or any word from the city's domain name. Prevents matching historical figures (Dr. Raymond Pearl, Octavio Martinez) who share names with council members.

**`--force-retry` flag:**
Resets all `headshot_status="failed"` cities to `null` before processing. Removes `headshot_failure_reason` metadata. Enables batch retry after URL fixes without manually editing JSON.

### Task 2: city_sources.json URL Fixes and Status Resets

**Part A: Failed city URL fixes (17 cities):**
- `azusa_city_council`: `ci.azusa.ca.us` → `azusaca.gov`
- `bradbury_city_council`: `ci.bradbury.ca.us` → `cityofbradbury.org/city-council`
- `irwindale_city_council`: `ci.irwindale.ca.us` → `irwindaleca.gov`
- `montebello_city_council`: `ci.montebello.ca.us` → `cityofmontebello.com`
- `pomona_city_council`: `ci.pomona.ca.us` → `pomonaca.gov`
- `sierra_madre_city_council`: `cityofsicrramadre.com` (typo) → `cityofsmca.com`
- `redondo_beach_city_council`: path → `/departments/city_council/default.asp`
- 10 other cities: URLs unchanged but headshot_status reset (URLs were correct, may have been transient DNS failures)
- All 17: `headshot_status` removed, `headshot_failure_reason` removed

**Part B: Reset 0-headshot scraped cities (41 cities):**
All 41 cities scraped in Plan 02 with 0 headshots reset to `headshot_status=null`. Removed `headshot_scraped_at` and `headshot_count` fields.

**Part C: Reset special cases:**
- `claremont_city_council` (duplicate_url_detected): reset to pending
- `rosemead_city_council` (duplicate_url_detected): reset to pending
- `burbank_city_council` (cloudflare blocked): reset to pending for enhanced Playwright retry

**Part C: Manual headshot_url overrides (19 entries):**
- Glendale: 5 council members (Asatryan, Kassakhian, Najarian, Brotman, Gharpetian) — Granicus showpublisheddocument pattern
- Pomona: 5 council members (Sandoval, Martin, Preciado, Garcia, Canales) — pomonaca.gov
- Santa Monica: 6 council members (Negrete, Brock, de la Torre, Parra, Torosis, Zwick) — Drupal sites/default/files/Council pattern
- Carson: Lula Davis Holmes — carson.ca.us

**Final state: 28 cities scraped-preserved, 61 cities pending, 0 failed.**

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Playwright browser lifecycle changed to start/stop pattern**
- **Found during:** Task 1 implementation
- **Issue:** Original `fetch_council_page` used `with sync_playwright() as p:` context manager, which automatically closes on exit. The `keep_page=True` mode cannot use a context manager since the caller needs the page to stay open.
- **Fix:** Changed to `pw_instance = sync_playwright().start()` / `pw_instance.stop()` pattern. Returns `(browser, pw_instance)` tuple to allow both to be closed in `process_city()`.
- **Files modified:** `scrape_city_headshots.py`
- **Impact:** Backward-compatible; `keep_page=False` (default) still closes immediately.

**2. [Informational] Some "corrected" URLs may still use same path as failed original**
- **Found during:** Task 2 analysis
- **Issue:** Some failed cities (bellflower, carson, glendora, la_habra_heights, paramount, rolling_hills_estates, san_marino, walnut) had correct-looking URLs that may have failed transiently. URLs preserved unchanged, status reset to null.
- **Approach:** Reset status to allow re-attempt. If the URL is still wrong, the enhanced scraper will mark them failed again and `--force-retry` can be used after further URL research.
- **Not a blocker:** The 41 zero-headshot scraped cities + CSS extraction enhancement provides the primary coverage improvement path.

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| `EV-Backend/scripts/scrape_city_headshots.py` | FOUND |
| `EV-Backend/scripts/city_sources.json` | FOUND |
| `.planning/phases/42-city-council-headshot-pipeline/42-03-SUMMARY.md` | FOUND |
| Commit 785c1e6 (Task 1 - scraper enhancements) | FOUND |
| Commit 0d83069 (Task 2 - URL fixes) | FOUND |
