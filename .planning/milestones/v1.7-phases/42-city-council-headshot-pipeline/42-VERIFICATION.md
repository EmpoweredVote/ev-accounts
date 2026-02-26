---
phase: 42-city-council-headshot-pipeline
verified: 2026-02-25T23:45:00Z
status: gaps_found
score: 7/8 must-haves verified
re_verification: true
re_verification_meta:
  previous_status: gaps_found
  previous_score: 6/8
  previous_verified: 2026-02-25T22:00:00Z
  gaps_closed:
    - "generate_headshot_manifest.py created (422 lines): queries DB for LOCAL/LOCAL_EXEC CA politicians without Supabase headshots, cross-references city_sources.json rosters by name, groups by city sorted by gap size descending, outputs research CSV"
    - "headshot_research_manifest.csv generated: 300 politicians across 82 cities with council_url per city"
    - "Pomona override URL failure confirmed (Akamai 403) and Santa Monica override URL failure confirmed (404 — files moved) — both cities re-processed with scraper; no headshots gained but failure cause documented"
    - "city_sources.json: all 89 cities have headshot_status; Pomona and Santa Monica reset and re-processed (headshot_status: scraped, headshot_count: 0)"
    - "Commit 1c69fd4 verified in git log"
  gaps_remaining:
    - "PHOTO-03: Coverage is 84/391 = 21.5%, still far below 80% (313/391) threshold — Plan 05 added 0 new headshots (Pomona/Santa Monica override URLs were broken)"
    - "ROADMAP Success Criterion 1: 80%+ HEAD request coverage not achieved"
    - "ROADMAP Success Criterion 2: Majority of council members still show initials avatars, not headshots"
  regressions: []
gaps:
  - truth: "Coverage validation via HEAD requests confirms 80%+ of LOCAL/LOCAL_EXEC politician CDN URLs return HTTP 200"
    status: failed
    reason: "Plan 05 confirmed coverage remains at 84/391 = 21.5%. Pomona (5 overrides) and Santa Monica (7 overrides) both had broken override URLs — Pomona showpublisheddocument paths blocked by Akamai 403, Santa Monica /sites/default/files/Council/ paths return 404 (files moved). Plan 05 added 0 new headshots. Plan 06 (manual browser research sprint for 285 remaining politicians) has been deferred by the user. The 80% target requires 313 headshots; 229 are still missing."
    artifacts:
      - path: "EV-Backend/scripts/city_sources.json"
        issue: "76 scraped cities, 84 total headshots. Pomona headshot_count=0 (5 broken overrides). Santa Monica headshot_count=0 (7 broken overrides). 34 cities have headshot_count > 0; 42 scraped cities still have 0 headshots."
    missing:
      - "229 additional headshot uploads to reach 80% threshold (313 of 391 politicians)"
      - "Plan 06 manual browser research sprint: visit city council pages for ~80 cities, add headshot_url overrides to city_sources.json for 217+ members, then run --force-retry to process"
      - "Correct Pomona replacement URLs (pomonaca.gov is Akamai-protected; need direct image URLs that bypass CDN bot detection, or use official press release photos)"
      - "Correct Santa Monica replacement URLs (old /sites/default/files/Council/ path is broken; find new image paths via DevTools Network tab on santamonica.gov/city-council)"

  - truth: "Visiting a city council member profile for a covered city shows a headshot photo the majority of the time"
    status: failed
    reason: "84/391 = 21.5% overall coverage. Plan 05 made no change to database coverage. For any random ZIP code in LA County, 78.5% of council member profiles show initials avatars. ROADMAP Success Criterion 2 requires the majority (>50%) of council members across tested cities to show headshots. Plan 06 is deferred — the manual curation sprint needed to close this gap has not been done."
    artifacts:
      - path: "EV-Backend/scripts/city_sources.json"
        issue: "34 cities have headshot_count > 0 out of 89 total cities. 42 scraped cities have headshot_count=0. 12 cities in 'failed' state, 1 city in 'blocked' state."
    missing:
      - "Execution of Plan 06: manual headshot URL curation sprint (headshot_research_manifest.csv provides the city-by-city research checklist)"
      - "After Plan 06 manual research: run 'python3 scrape_city_headshots.py --force-retry' to process all new headshot_url overrides"
human_verification:
  - test: "After completing Plan 06 manual curation sprint, open essentials app (cd essentials && npm run dev), search ZIP 90502 (Torrance), 90802 (Long Beach), 90210 (Beverly Hills), 91101 (Pasadena), 90280 (South Gate), 90401 (Santa Monica), 91766 (Pomona). Count council members showing headshots vs. initials avatars across all 7 cities."
    expected: "80%+ of council members across all 7 tested cities show headshot photos, not initials avatars."
    why_human: "SQL confirms 21.5% overall coverage (84/391). This checkpoint cannot pass until Plan 06 is executed. headshot_research_manifest.csv (300 politicians, 82 cities) is ready to use as the research guide."
---

# Phase 42: City Council Headshot Pipeline Verification Report

**Phase Goal:** Users can see headshots for 80%+ of city council members across all 89 LA County cities, all images stored in Supabase Storage
**Verified:** 2026-02-25T23:45:00Z
**Status:** gaps_found
**Re-verification:** Yes — after Plan 05 gap closure (manifest creation + Pomona/Santa Monica override processing)

## Re-Verification Summary

Plan 05 completed the manifest generator deliverable (`generate_headshot_manifest.py`, 422 lines) and produced `headshot_research_manifest.csv` (300 politicians across 82 cities). However, Plan 05 added 0 new headshots: the Pomona and Santa Monica override URLs were broken (Akamai 403 and 404 respectively). Coverage remains at 84/391 = 21.5%.

Plan 06 (manual browser research sprint for ~285 politicians) has been **deferred by the user**. No SUMMARY exists for Plan 06. The gap between current coverage (21.5%) and the 80% PHOTO-03 target remains open by design — the tooling infrastructure is complete; the missing piece is the human data entry sprint.

**Plan 05 gaps closed:**
- `generate_headshot_manifest.py` created: substantive (422 lines), wired to DB and city_sources.json, produces research CSV
- `headshot_research_manifest.csv` generated: 300 rows, 82 cities, council_url per city for browser research
- Pomona and Santa Monica override URL failures fully diagnosed and documented
- city_sources.json updated: Pomona and Santa Monica reset and re-processed (failure cause confirmed)

**Gaps that remain (unchanged from previous verification):**
- PHOTO-03: 84/391 = 21.5% vs. 80% threshold — 229 headshots still missing
- ROADMAP Success Criteria 1 and 2 are still unmet
- Plan 06 deferred (user decision — requires manual browser research, ~4-6 hours)

## Goal Achievement

### Observable Truths (Mapped to ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Coverage validation via HEAD requests confirms 80%+ of LOCAL/LOCAL_EXEC CDN URLs return HTTP 200 (SC1) | FAILED | 84/391 = 21.5%. Plan 05 added 0 new headshots. 313 required, 229 missing. Plan 06 deferred. |
| 2 | Visiting a council member profile for a covered city shows a headshot photo the majority of the time (SC2) | FAILED | 21.5% overall coverage. 42 scraped cities still have headshot_count=0. Plan 06 not executed. |
| 3 | Scraping runs at no faster than one city per 1.5 seconds (SC3, PIPE-02) | VERIFIED | `INTER_CITY_DELAY = 1.5` at line 115; elapsed-time check at lines 1168-1172. Unchanged from Plan 04. |
| 4 | Cloudflare-blocked cities are marked "blocked" (not "failed") and skipped on re-run (SC4) | VERIFIED | city_sources.json: Burbank headshot_status="blocked". 76 scraped, 12 failed, 1 blocked confirmed. |
| 5 | scrape_city_headshots.py has all 12 required functions | VERIFIED | 1247-line file unchanged from Plan 04. All 12 functions confirmed in prior verification; no regression. |
| 6 | CSS background-image extraction strategies (1b, 2b) and manual headshot_url override support exist | VERIFIED | Confirmed in prior verification; file unchanged; no regression. |
| 7 | generate_headshot_manifest.py exists, is substantive (min 60 lines), and produces a research CSV for Plan 06 | VERIFIED | 422 lines; SQL with DISTINCT ON (p.id) and LEFT JOIN politician_images at lines 92/100; argparse with --output and --include-blocked; headshot_research_manifest.csv (301 rows) confirmed on disk. NEW in this verification. |
| 8 | city_sources.json has headshot_status for every one of the 89 cities | VERIFIED | 76 scraped + 12 failed + 1 blocked = 89 total; all have headshot_status set. Pomona and Santa Monica re-processed. |

**Score:** 7/8 truths verified (Truths 1 and 2 fail — PHOTO-03 blocking gap; Truth 7 newly VERIFIED from Plan 05)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `EV-Backend/scripts/scrape_city_headshots.py` | Enhanced batch scraper, min 300 lines, 12 functions | VERIFIED | 1247 lines; all 12 functions; PIPE-02 rate limiting at line 115; unchanged from Plan 04 |
| `EV-Backend/scripts/city_sources.json` | headshot_status for all 89 cities | VERIFIED | 89 cities: 76 scraped, 12 failed, 1 blocked; Pomona and Santa Monica re-processed |
| `EV-Backend/scripts/generate_headshot_manifest.py` | Research manifest generator, min 60 lines | VERIFIED | 422 lines; argparse --output/--include-blocked; DISTINCT ON SQL; LEFT JOIN politician_images; cross-references city_sources.json roster by name |
| `EV-Backend/scripts/headshot_research_manifest.csv` | CSV listing all remaining politicians without headshots, grouped by city | VERIFIED | 301 rows (300 politicians + header); columns: city_name, city_id, council_url, member_name, role, has_existing_override, headshot_status |
| `essentials.politician_images` rows | 313+ CDN rows for LOCAL/LOCAL_EXEC politicians (80% of 391) | FAILED | 84 CDN rows (21.5%). Plan 05 added 0 new rows. Target requires 313 rows; 229 more needed. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `scrape_city_headshots.py` | `utils.py` | `from utils import load_env, load_supabase_env, upload_photo_to_storage` | WIRED | Confirmed in prior verification; unchanged |
| `scrape_city_headshots.py` | `city_sources.json` | Reads city list + roster; writes headshot_status per city | WIRED | Confirmed in prior verification; unchanged |
| `scrape_city_headshots.py` | `essentials.politician_images` | psycopg2 upsert_politician_image() | WIRED | Confirmed in prior verification; unchanged |
| `generate_headshot_manifest.py` | `essentials.politician_images` | `LEFT JOIN essentials.politician_images pi` (line 100) with DISTINCT ON (p.id) (line 92) | WIRED | Grep confirms both patterns; CSV output confirms successful run |
| `generate_headshot_manifest.py` | `city_sources.json` | json.load() for city metadata + roster name cross-reference | WIRED | Script loads city_sources.json; --include-blocked filters by headshot_status |
| `generate_headshot_manifest.py` | `headshot_research_manifest.csv` | CSV output via argparse --output flag | WIRED | headshot_research_manifest.csv on disk (301 rows) confirms successful execution |
| `city_sources.json` headshot_url overrides | `scrape_city_headshots.py` | Lines 819-824: member.get("headshot_url") checked before HTML extraction | WIRED (tooling ready) | 38 overrides in JSON across 9 cities. Plan 06 adds 217+ new overrides for remaining politicians — deferred by user. |
| `essentials.politician_images` | Supabase Storage CDN | url column contains *.supabase.co URLs | VERIFIED (84 rows) | 84 CDN rows confirmed by Plan 04 SUMMARY; no new rows from Plan 05 |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| PHOTO-03 | 42-01 through 42-06 | User sees headshot for 80%+ of city council members across 89 LA County cities | BLOCKED | 84/391 = 21.5% coverage. Plan 05 added 0 headshots. Plan 06 deferred. Target (313 headshots) requires 229 more. Pipeline infrastructure is complete; data gap requires manual research sprint. |
| PIPE-02 | 42-01 through 42-05 | Scraping respects rate limits with delays between requests | SATISFIED | `INTER_CITY_DELAY = 1.5` at line 115; elapsed-time enforcement at lines 1168-1172; `DOWNLOAD_DELAY = 0.5` for per-image delays. generate_headshot_manifest.py does not scrape, so rate limiting not applicable there. |

**Orphaned requirements check:** No additional Phase 42 requirements appear in REQUIREMENTS.md beyond PHOTO-03 and PIPE-02.

**REQUIREMENTS.md accuracy note (persists across Plans 03-05):** PHOTO-03 is marked `[x]` (complete) in REQUIREMENTS.md despite actual database coverage being 21.5%. This has not been corrected.

### Plan 05 Deviation: Pomona and Santa Monica Override URLs Are Broken

The plan expected:
- "Pomona and Santa Monica manual headshot_url overrides have been processed — their headshot_count is now > 0" — NOT MET
- "Coverage has improved from 84/391 to at least 96/391" — NOT MET

Confirmed failure causes:
- **Pomona:** `https://www.pomonaca.gov/home/showpublisheddocument/15001` etc. return HTTP 403 from Akamai CDN bot detection. The URLs were valid when added but Akamai protection has since been applied.
- **Santa Monica:** `https://www.santamonica.gov/sites/default/files/Council/negrete-lana-600x600.jpg` etc. return HTTP 404. Files were moved or deleted from those Drupal paths.

The manifest generator deliverable was fully completed. The +12 headshot target is now part of the Plan 06 manual research queue, flagged with `has_existing_override=True` in the CSV.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `city_sources.json` | — | 12 cities with `headshot_status: "failed"` | WARNING | Skipped on re-run without --force-retry; ~50+ politicians with no headshot path |
| `city_sources.json` | — | Pomona (5 overrides, headshot_count=0) and Santa Monica (7 overrides, headshot_count=0) | WARNING | 12 override entries exist in JSON but produce 0 headshots — override URLs are broken; Plan 06 identifies correct replacement URLs |
| `city_sources.json` | — | 42 scraped cities with headshot_count=0 | WARNING | Scraper ran and found nothing automatable; only manual override + re-run can improve them |

No empty implementations, placeholder functions, or return null stubs found in scrape_city_headshots.py or generate_headshot_manifest.py.

### Human Verification Required

#### 1. Final Coverage Checkpoint (Blocked Until Plan 06)

**Test:** After completing Plan 06 manual curation sprint and running `python3 scrape_city_headshots.py --force-retry`, start the Go backend (`cd EV-Backend && go run .`) and open the essentials app (`cd essentials && npm run dev`). Search ZIP codes: 90502 (Torrance), 90802 (Long Beach), 90210 (Beverly Hills), 91101 (Pasadena), 90280 (South Gate), 90401 (Santa Monica), 91766 (Pomona).
**Expected:** 80%+ of council members across all 7 tested cities show headshot photos, not initials avatars.
**Why human:** SQL confirms 21.5% overall coverage (84/391). This checkpoint cannot pass until Plan 06 manual research sprint adds 217+ headshot_url overrides. The research manifest at `EV-Backend/scripts/headshot_research_manifest.csv` (300 politicians, 82 cities) is ready to use.

### Gaps Summary

**Current state after Plans 01-05:**

Plans 01-04 built and optimized the automated pipeline. Plan 05 built the research tooling for the manual sprint.

What is present and working:
- `scrape_city_headshots.py`: 1247 lines, 12 functions, fully tested, PIPE-02 enforced
- 5-strategy extraction cascade, Playwright JS evaluation, manual headshot_url override support (38 entries)
- `generate_headshot_manifest.py`: 422 lines, DB query + city_sources.json cross-reference, CSV output
- `headshot_research_manifest.csv`: 300 politicians across 82 cities, sorted by gap size
- All 89 cities have headshot_status in city_sources.json
- 84 headshots in Supabase Storage CDN (all valid per Plan 05 --check-coverage)

**What is deferred:**

Plan 06 requires ~4-6 hours of manual browser research:
1. Open `EV-Backend/scripts/headshot_research_manifest.csv` sorted by city gap size
2. Work through cities (Santa Monica 7 missing, Artesia 6, Redondo Beach 6, El Monte 6, Pomona 6, Lynwood 6, etc.)
3. For each politician, visit the city council page, right-click the headshot image, copy URL
4. Add `"headshot_url": "https://..."` to the roster member entry in city_sources.json
5. After 217+ overrides added: run `python3 scrape_city_headshots.py --force-retry`

**Coverage path to 80%:**

| Step | Action | Expected Result |
|------|--------|-----------------|
| Current | 84/391 headshots (21.5%) | Baseline |
| Plan 06 Task 1 (manual research) | Add 217+ headshot_url overrides for ~55 cities | city_sources.json updated |
| Plan 06 Task 2 (--force-retry) | Process all new overrides via scraper | ~301+/391 = ~77-80% |
| Plan 06 Task 3 (human verify) | Confirm headshots appear on profile pages | Checkpoint: approved |

The Cloudflare-protected and CivicPlus/XHR-rendered cities that block all automation can still be researched manually in a browser — that is the purpose of Plan 06.

---

_Verified: 2026-02-25T23:45:00Z_
_Verifier: Claude (gsd-verifier)_
_Re-verification after: Plan 42-05 (manifest generation + Pomona/Santa Monica override processing)_
_Previous verification: 2026-02-25T22:00:00Z (after Plans 42-03 and 42-04)_
