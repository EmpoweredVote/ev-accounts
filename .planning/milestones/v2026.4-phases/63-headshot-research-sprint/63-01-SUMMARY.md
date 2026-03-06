---
phase: 63-headshot-research-sprint
plan: "01"
subsystem: database
tags: [python, csv, psycopg2, headshots, manifest, data-pipeline]

# Dependency graph
requires: []
provides:
  - "Updated generate_headshot_manifest.py with politician_id and research tracking columns"
  - "Regenerated headshot_research_manifest.csv: 304 rows, 12 columns, no duplicates, includes Burbank"
affects: [64-headshot-upload-sprint]

# Tech tracking
tech-stack:
  added: [psycopg2-binary, sqlalchemy (local dependencies for script execution)]
  patterns: [seen_ids deduplication set in manifest generator, research tracking columns appended after existing schema columns]

key-files:
  created: []
  modified:
    - EV-Backend/scripts/generate_headshot_manifest.py
    - EV-Backend/scripts/headshot_research_manifest.csv

key-decisions:
  - "Added politician_id from p.id (UUID primary key) to enable direct DB upsert in Phase 64 without fuzzy name matching"
  - "Deduplication via seen_ids set added to fix 5 politicians appearing twice in old 300-row manifest"
  - "research_status defaults to pending for all rows; Phase 63 plans 02-08 will fill found/not_found/blocked"

patterns-established:
  - "Research tracking columns appended after existing columns to preserve backward compatibility"
  - "seen_ids deduplication pattern: track by politician DB id before matching to city roster"

requirements-completed: [PHOTO-01]

# Metrics
duration: 2min
completed: 2026-03-05
---

# Phase 63 Plan 01: Headshot Manifest Update Summary

**Extended manifest generator with politician_id + research tracking columns, regenerated 12-column CSV covering 304 politicians across 83 cities including Burbank (blocked) with zero duplicates**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-05T18:17:05Z
- **Completed:** 2026-03-05T18:19:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `politician_id`, `found_url`, `source_page_url`, `research_status`, and `research_date` columns to generate_headshot_manifest.py
- Fixed duplicate rows (5 politicians appeared twice in old 300-row manifest) via `seen_ids` deduplication
- Regenerated manifest to 304 rows (12 columns, all `research_status=pending`, every row has a valid politician_id UUID)
- Burbank (previously excluded) now included: 3 politicians with `headshot_status=blocked`

## Task Commits

Each task was committed atomically to the EV-Backend repo:

1. **Task 1: Extend generate_headshot_manifest.py with politician_id and research columns** - `8125563` (feat)
2. **Task 2: Regenerate manifest with --include-blocked** - `da8b84f` (feat)

**Plan metadata:** (docs commit below)

## Files Created/Modified

- `EV-Backend/scripts/generate_headshot_manifest.py` - Added 5 new CSV columns, deduplication logic via seen_ids, updated docstring and CLI help
- `EV-Backend/scripts/headshot_research_manifest.csv` - Regenerated: 304 rows, 12 columns, includes blocked cities, all research_status=pending

## Decisions Made

- Used `seen_ids` set (tracking by `pol["id"]`) before city roster matching to prevent duplicate rows — duplicates arose from the name-based matching finding the same politician via multiple roster entries
- Appended new columns after existing 7 rather than inserting mid-row to preserve any downstream references to column positions

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Installed missing psycopg2-binary and sqlalchemy**
- **Found during:** Task 2 (running the manifest generator)
- **Issue:** psycopg2 and sqlalchemy not installed in the current Python environment
- **Fix:** `pip3 install psycopg2-binary sqlalchemy --break-system-packages`
- **Files modified:** None (system packages only)
- **Verification:** Script ran successfully after installation
- **Committed in:** Not committed (local dev dependencies)

---

**Total deviations:** 1 auto-fixed (blocking — missing dependencies)
**Impact on plan:** Dependency installation unblocked execution immediately; no scope creep.

## Issues Encountered

- The manifest output shows 308 politicians from the DB query but only 304 matched to city roster entries — 4 politicians (Karen Ruth Bass, Janet Nguyen, Doug Chaffee, Adrin Nazarian) are not in city_sources.json. These appear to be non-city-council officials (county supervisors, state legislators) that match the LOCAL/LOCAL_EXEC district type filter. They are out of scope for this manifest — the 304 matched rows are correct.

## User Setup Required

None - no external service configuration required. The manifest CSV is ready for plans 02-08 to fill in research data.

## Next Phase Readiness

- `headshot_research_manifest.csv` is ready for the research sprint (plans 02-08)
- Every row has `politician_id` (UUID) enabling direct `essentials.politician_images` upsert in Phase 64
- `research_status=pending` on all 304 rows — plans 02-08 will update to `found`, `not_found`, or `blocked`
- 289 politicians need new URL research; 15 have existing `headshot_url` overrides in city_sources.json

## Self-Check: PASSED

- FOUND: EV-Backend/scripts/generate_headshot_manifest.py
- FOUND: EV-Backend/scripts/headshot_research_manifest.csv
- FOUND: .planning/phases/63-headshot-research-sprint/63-01-SUMMARY.md
- FOUND: commit 8125563 (Task 1)
- FOUND: commit da8b84f (Task 2)

---
*Phase: 63-headshot-research-sprint*
*Completed: 2026-03-05*
