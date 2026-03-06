---
phase: 64-headshot-upload-and-coverage-validation
plan: 01
subsystem: database
tags: [python, psycopg2, supabase, csv, headshots, upload-pipeline]

requires:
  - phase: 63-headshot-research-sprint
    provides: headshot_research_manifest.csv with 246 found URLs and politician_id UUIDs

provides:
  - EV-Backend/scripts/upload_manifest_headshots.py — CSV-driven batch upload pipeline with dry-run support
  - Dry-run validation showing 175-180/246 (71-73%) URLs successfully downloadable

affects:
  - 64-02-PLAN.md — actual upload run (proceeds with 175-180 successful downloads rather than 246)

tech-stack:
  added: []
  patterns:
    - "CSV-driven batch pipeline with --dry-run flag for pre-flight validation"
    - "Per-row commit isolation (conn.commit() after each successful upsert)"
    - "Copy helper functions verbatim from scrape_city_headshots.py rather than importing (avoids Playwright dep)"

key-files:
  created:
    - EV-Backend/scripts/upload_manifest_headshots.py
  modified: []

key-decisions:
  - "Copy helper functions verbatim from scrape_city_headshots.py (not import) — scraper has Playwright dep that would block import in CI"
  - "Per-row DB commit (not per-batch) for failure isolation — consistent with scrape_city_headshots.py pattern"
  - "66-71/246 URLs fail 403 during dry-run — document failures, proceed with whatever succeeds per plan instructions (no manual fix attempts)"
  - "content_type_to_ext() extracted from inline dict in scrape_city_headshots.py as a standalone helper"

patterns-established:
  - "Manifest upload pipeline: read CSV -> filter found rows -> download -> upload CDN -> upsert DB"
  - "photo_license classification: wikimedia/wikipedia = cc_by_sa_4.0, else scraped_no_license"

requirements-completed:
  - PHOTO-03
  - PHOTO-04

duration: 25min
completed: 2026-03-06
---

# Phase 64 Plan 01: Headshot Upload Script + Dry-Run Validation Summary

**CSV-driven batch upload pipeline (upload_manifest_headshots.py) reads 246 found manifest rows, downloads images with 403-retry logic, uploads to Supabase Storage CDN, and upserts essentials.politician_images — dry-run confirms 175-180/246 (71-73%) URLs downloadable with 66-71 CivicPlus/government CDN 403 failures documented.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-03-06T17:43:04Z
- **Completed:** 2026-03-06T18:08:30Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Created `upload_manifest_headshots.py` (432 lines) with all required helper functions copied verbatim from `scrape_city_headshots.py`
- Script imports cleanly, has `run_upload()` function, `--dry-run` and `--manifest` CLI flags via argparse
- Dry-run executed against all 246 found rows — downloads validated, failures documented by domain
- 175-180 successful downloads confirmed across two dry-run executions (results vary due to Wayback Machine connection instability)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create upload_manifest_headshots.py with dry-run support** - `4dfac0a` (feat) — EV-Backend repo
2. **Task 2: Run dry-run to verify downloads** - no file changes (execution-only task)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `EV-Backend/scripts/upload_manifest_headshots.py` — 432-line CSV-driven batch upload pipeline
  - `get_connection()` — psycopg2 direct connection (port 5432, not 6543 pooler)
  - `make_storage_path()` — deterministic CDN path: `la_county/cities/{city_slug}/{name_slug}.{ext}`
  - `upsert_politician_image()` — idempotent INSERT/UPDATE on (politician_id, type='default')
  - `download_image()` — browser UA, Wikipedia UA, 403 retry with Referer header
  - `content_type_to_ext()` — MIME type to file extension mapping
  - `get_photo_license()` — wikimedia/wikipedia = cc_by_sa_4.0, else scraped_no_license
  - `run_upload()` — main pipeline function
  - `main()` — argparse CLI entry point

## Decisions Made

- Copy helper functions verbatim from `scrape_city_headshots.py` (not import). The scraper imports Playwright which blocks module import in scripts context. Verbatim copy keeps the new script self-contained with no heavy dependencies.
- Per-row `conn.commit()` for failure isolation — a failed upload/upsert on one politician doesn't roll back successful ones.
- 66-71 download failures treated as documentation items per plan instructions. Plan explicitly stated "Do NOT attempt manual fixes."

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

### Dry-run Download Failures (66-71/246)

The dry-run revealed systematic 403 failures from specific government CMS platforms that block direct script downloads:

**Failures by domain (from dry-run execution):**
| Domain | Count | CMS Platform |
|--------|-------|--------------|
| www.pomonaca.gov | 6 | CivicPlus |
| www.pvestates.org | 5 | CivicPlus |
| www.torranceca.gov | 5 | CivicPlus |
| www.hermosabeach.gov | 5 | CivicPlus |
| www.weho.org | 4 | CivicPlus/Akamai |
| www.rollinghillsestates.gov | 4 | CivicPlus |
| www.lakewoodcity.org | 4 | CivicPlus |
| www.commerceca.gov | 4 | Akamai |
| cms9files.revize.com | 4 | Revize CMS |
| www.cityofcalabasas.com | 4 | CivicPlus |
| www.cityofvernonca.gov | 4 | CivicPlus |
| www.hgcity.org | 4 | Government CDN |
| www.cityofhawthorne.org | 3 | Akamai |
| www.sanfernando.gov | 3 | WordPress CDN |
| www.southpasadenaca.gov | 2 | CivicPlus |
| www.cityofbell.gov | 2 | Government CDN |
| www.culvercity.gov | 2 | Government CDN |
| web.archive.org | 4-8 | Wayback Machine (transient timeout) |

**Root cause:** These URLs returned valid images in a browser session during Phase 63 research but return 403 to direct `requests` downloads. The `download_image()` function already implements 403 retry with Referer header, but these CivicPlus/Akamai sites require additional session cookies or JavaScript execution that a simple HTTP client cannot replicate.

**Impact on coverage math:**
- 175-180 successful uploads (varies per run due to Wayback transience)
- Pre-existing ~84 headshots from v1.7 batch
- Post-upload estimate: ~84 + 175 = ~259 out of ~391 LA County politicians = ~66%
- This is below the 80% PHOTO-05 threshold

**Plan 02 implication:** Plan 02 (real upload run) will proceed with ~175-180 successful uploads. Coverage validation (Plan 03) will reveal whether the 80% threshold is met or whether manual resolution of the 66 failures is needed to reach 80%.

### Wayback Machine Instability

~4-8 of the 246 found URLs use Wayback Machine `im_` URLs. These intermittently fail with "Connection refused" on web.archive.org (port 443). On re-run some succeed and some fail — results are non-deterministic based on current Wayback availability.

## Self-Check: PASSED

- FOUND: `EV-Backend/scripts/upload_manifest_headshots.py` (432 lines)
- FOUND: `64-01-SUMMARY.md`
- FOUND: commit `4dfac0a` in EV-Backend repo (`git log --oneline -3` verified)

Note: EV-Backend is a separate nested git repository — commit is in `EV-Backend/.git`, not the workspace root `.git`.

## Next Phase Readiness

- `upload_manifest_headshots.py` is ready for Plan 02 real upload execution
- Download failures are documented — Plan 02 will proceed with whatever succeeds (~175-180 images)
- Plan 02 should run without `--dry-run` flag to execute actual uploads to Supabase Storage CDN
- Plan 03 coverage validation will confirm if 80% threshold passes or if manual intervention is needed for the 66 failing URLs

---
*Phase: 64-headshot-upload-and-coverage-validation*
*Completed: 2026-03-06*
