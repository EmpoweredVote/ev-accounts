---
phase: 64-headshot-upload-and-coverage-validation
plan: 02
subsystem: database
tags: [python, psycopg2, supabase, csv, headshots, upload-pipeline, coverage-validation]

requires:
  - phase: 64-headshot-upload-and-coverage-validation
    provides: upload_manifest_headshots.py created in Plan 01 with dry-run validation

provides:
  - 180 LA County city council headshots live on Supabase CDN (politician_photos bucket)
  - essentials.politician_images upserted with 180 new CDN URLs (inserted for new politicians)
  - coverage_report.py --check 1 exits 0 — PASS (100% CDN health, 260/260 URLs return HTTP 200)
  - utils.py PHOTO_BUCKET corrected to politician_photos (underscore) for dev Supabase project

affects:
  - essentials frontend — profile pages for newly covered politicians will show headshots
  - 64-03 coverage validation (if planned) — CDN health already PASSED

tech-stack:
  added:
    - supabase==2.28.0 installed into scripts/.venv (was missing; required for upload_photo_to_storage)
  patterns:
    - "Run scripts with scripts/.venv/bin/python3 to ensure all deps available"
    - "PHOTO_BUCKET constant in utils.py must match actual Supabase bucket name (underscore vs hyphen)"

key-files:
  created: []
  modified:
    - EV-Backend/scripts/utils.py — PHOTO_BUCKET corrected from politician-photos to politician_photos

key-decisions:
  - "PHOTO_BUCKET in utils.py updated to politician_photos (underscore) — dev Supabase project bucket uses underscore; production migration note: production bucket name must be confirmed"
  - "180/246 successful uploads accepted — 66 failures are systematic 403-blocked government CDNs (same as dry-run), not script bugs"
  - "coverage_report.py --check 1 measures CDN health (100%) not population coverage (66.8%) — CDN health is the PHOTO-05 gate criterion"

patterns-established:
  - "supabase package must be in venv for upload scripts — install with .venv/bin/pip install supabase==2.28.0"

requirements-completed:
  - PHOTO-03
  - PHOTO-04
  - PHOTO-05

duration: 21min
completed: 2026-03-06
---

# Phase 64 Plan 02: Real Headshot Upload + Coverage Validation Summary

**180 LA County headshots uploaded to Supabase CDN (politician_photos bucket), 503 total CDN headshots in DB, coverage_report.py --check 1 PASSES at 100% CDN health — PHOTO-05 gate confirmed.**

## Performance

- **Duration:** 21 min
- **Started:** 2026-03-06T18:13:08Z
- **Completed:** 2026-03-06T18:33:51Z
- **Tasks:** 2/2 complete (1 auto + 1 human-verify approved)
- **Files modified:** 1

## Accomplishments

- Real upload executed: 180 headshots successfully downloaded, uploaded to Supabase Storage, and upserted into essentials.politician_images
- 66 download failures accepted as expected — same systematic 403-blocked government CDNs documented in Plan 01 dry-run
- coverage_report.py --check 1 exits 0 — PASS: 260/260 CDN URLs return HTTP 200 (100% health vs 80% threshold)
- Population coverage: 263/394 LA County politicians have headshots (66.8%) — CDN health check gates on health %, not population %
- Auto-fixed bucket name mismatch (utils.py PHOTO_BUCKET) — dev project uses underscores

## Task Commits

1. **Task 1: Execute real upload of 246 headshots to Supabase CDN** - `68bb477` (fix) — includes bucket name correction + upload execution
2. **Task 2: Visual verification of headshots on profile pages** - Human checkpoint approved — headshots confirmed displaying on politician cards and profile pages for multiple LA County ZIP codes (90210, 91502, 90401)

## Files Created/Modified

- `EV-Backend/scripts/utils.py` — PHOTO_BUCKET corrected from `politician-photos` to `politician_photos` (dev Supabase project uses underscore bucket name)

## Decisions Made

- Updated `PHOTO_BUCKET = "politician_photos"` in utils.py to match the actual bucket name in the dev Supabase project. The existing 323 pre-upload CDN records all use the `politician_photos` URL path, confirming underscore is the correct name for this project.
- 180/246 successful uploads treated as complete per plan instructions — failures are documented systematic 403 blocks from government CDNs, not script bugs.
- coverage_report.py --check 1 CDN health (100%) is the PHOTO-05 gate, not population coverage (66.8%). This distinction is intentional — the check validates that uploaded headshots are accessible, not that every politician has one.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed PHOTO_BUCKET name mismatch preventing all uploads**
- **Found during:** Task 1 (Execute real upload)
- **Issue:** utils.py had `PHOTO_BUCKET = "politician-photos"` (hyphen) but the dev Supabase project's bucket is named `politician_photos` (underscore). Every upload attempt returned `{'statusCode': 404, 'error': Bucket not found}`.
- **Fix:** Updated `PHOTO_BUCKET = "politician_photos"` in utils.py line 139.
- **Files modified:** `EV-Backend/scripts/utils.py`
- **Verification:** Upload ran successfully after fix — 180 ok, 66 failed (expected 403s only)
- **Committed in:** `68bb477` (Task 1 commit)

**2. [Rule 3 - Blocking] Installed missing supabase package in scripts/.venv**
- **Found during:** Task 1 (Execute real upload) — first attempt
- **Issue:** `upload_photo_to_storage()` in utils.py imports `supabase` package which was not installed in the scripts/.venv environment (only psycopg2 and requests were present).
- **Fix:** Ran `.venv/bin/pip install supabase==2.28.0` to install the package specified in requirements.txt.
- **Files modified:** .venv/lib/... (venv site-packages — not committed)
- **Verification:** Import succeeds after install; upload proceeded to Supabase Storage.
- **Committed in:** `68bb477` (Task 1 commit, utils.py change only — venv changes not committed per .gitignore)

---

**Total deviations:** 2 auto-fixed (2 Rule 3 blocking)
**Impact on plan:** Both auto-fixes necessary to unblock upload. No scope creep. Upload produced expected results once fixed.

## Issues Encountered

### Download Failures (66/246)

The 66 download failures are identical to the dry-run failures documented in Plan 01:

| Failure Type | Count | Examples |
|---|---|---|
| Government CDN 403 blocks | ~55 | pomonaca.gov, torranceca.gov, hermosabeach.gov, hgcity.org, southpasadenaca.gov, sanfernando.gov, cityofbell.gov, culvercity.gov |
| Wayback Machine connection refused | ~8 | web.archive.org port 443 (transient, varies per run) |
| 404 (archive removed) | ~3 | claremontca.gov via Wayback |

The `download_image()` function already retries with Referer on 403 — these failures persist because the government CDNs require browser sessions or JavaScript execution that HTTP clients cannot replicate.

## Self-Check: PASSED

- FOUND: `EV-Backend/scripts/utils.py` updated (git shows modification)
- FOUND: commit `68bb477` in EV-Backend repo (`git log --oneline -1` verified)
- FOUND: coverage_report.py --check 1 exits 0 with output "PASS (CDN health 100.0% vs 80% threshold)"
- FOUND: 503 total Supabase CDN headshots in DB (confirmed via psycopg2 query)

## Next Phase Readiness

- Phase 64 complete. All 4 success criteria satisfied: CDN URLs live, politician_images records updated, coverage_report.py --check 1 PASSES, headshots human-verified on profile pages.
- 180 new headshots live on Supabase CDN, 503 total CDN headshots in DB.
- PHOTO-03, PHOTO-04, PHOTO-05 requirements marked complete.
- v2026.4 milestone (State Data Completion & Image Coverage) is complete — Phases 60-66 all done.
- 66 failing government CDN URLs remain unresolved (CivicPlus/Akamai blocks). Deferring to future sprint if population coverage (currently 66.8%) needs to reach 80%.

---
*Phase: 64-headshot-upload-and-coverage-validation*
*Completed: 2026-03-06*
