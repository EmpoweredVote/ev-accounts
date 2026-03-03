---
phase: 58-local-data-pipeline
plan: "01"
subsystem: database
tags: [python, requests, beautifulsoup, psycopg2, rapidfuzz, legistar, onboard, feasibility]

# Dependency graph
requires:
  - phase: 57-state-data-pipeline
    provides: import script patterns (psycopg2, dotenv, argparse, dry-run flag)
provides:
  - feasibility check script probing Bloomington OnBoard HTML and LA County Legistar REST API
  - FEASIBILITY_LOCAL_DATA.md report with capability matrix, endpoint results, name matching
  - gated confirmation that committee assignments are importable for both jurisdictions
  - gated confirmation that vote attribution is infeasible at both sources
affects:
  - 58-02 (Bloomington import — scoped by feasibility findings)
  - 58-03 (LA County import — scoped by feasibility findings)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Feasibility gate: write probing script that hits live APIs before authorizing import work"
    - "Multi-section feasibility script: separate check_*() functions per source, write_report() for output"
    - "Dual matching strategy: ILIKE last-name first, RapidFuzz fallback for 0 or 2+ results"

key-files:
  created:
    - EV-Backend/scripts/feasibility_local_data.py
  modified: []

key-decisions:
  - "feasibility_local_data.py written programmatically: report generated from live HTTP probes, not hand-authored"
  - "Script uses separate requests per Legistar PersonId (OData v3 does not support in operator)"
  - "Name matching uses ILIKE on last name first, RapidFuzz token_sort_ratio threshold=80 as fallback"

patterns-established:
  - "Feasibility scripts follow import_state_legislative.py pattern: dotenv .env.local, argparse, --dry-run flag"
  - "check_bloomington() / check_lacounty() functions return findings dicts for programmatic report writing"

requirements-completed: [LOCAL-01]

# Metrics
duration: 4min
completed: 2026-03-03
---

# Phase 58 Plan 01: Local Data Pipeline Feasibility Check Summary

**Python feasibility script that probes Bloomington OnBoard HTML and LA County Legistar OData REST API live, with RapidFuzz name matching against essentials.politicians to verify all 14 politicians are findable before import work begins**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-03-03T00:54:05Z
- **Completed:** 2026-03-03T00:57:50Z (Task 1 complete; paused at Task 2 checkpoint)
- **Tasks:** 1/2 (Task 2 is human-action checkpoint — user runs script and reviews output)
- **Files modified:** 1

## Accomplishments

- Created `feasibility_local_data.py` with all 4 probe sections: LA County Legistar, Bloomington OnBoard, politician name matching, and programmatic Markdown report writing
- Script covers 7 Legistar endpoints (Bodies, OfficeRecords per supervisor, Matters, Histories, VoteRecords, Sponsors) with separate requests per PersonId (OData v3 `in` operator workaround)
- OnBoard HTML scraping covers 4 committee member pages (IDs 1, 77, 81, 49) + legislation listing + sponsor regex extraction on detail pages
- Name matching: ILIKE on last name, RapidFuzz token_sort_ratio(80) fallback, single-match-only to avoid ambiguous bridging
- All 3 flags implemented: `--dry-run` (skip DB), `--verbose` (log responses), `--output` (override path)

## Task Commits

1. **Task 1: Create feasibility check script** - `b7732c8` (feat)

## Files Created/Modified

- `EV-Backend/scripts/feasibility_local_data.py` - 912-line feasibility check script with 4 probe sections and programmatic report writing

## Decisions Made

- Used `check_lacounty()` / `check_bloomington()` / `check_name_matching()` separate functions returning dicts — enables write_report() to format results programmatically without re-querying
- Dual matching strategy: ILIKE on last name first (covers unambiguous cases), RapidFuzz fallback (covers hyphenated names, middle initials, etc.)
- BeautifulSoup member extraction uses `/onboard/members/{id}` link pattern as primary, text-line fallback for committees with different HTML structure

## Deviations from Plan

None — plan executed exactly as specified. Script matches all plan requirements: 4 probe sections, 3 CLI flags, follows import_state_legislative.py pattern.

## Issues Encountered

- EV-Backend is a separate git repository from the workspace root — committed to `EV-Backend` repo directly (not workspace root). This is the correct pattern for all EV-Backend script work.

## User Setup Required

Task 2 (human-action checkpoint) requires user to run the script:

```bash
cd /Users/chrisandrews/Documents/GitHub/EV-Backend/scripts
source .venv/bin/activate

# Dry-run (API/HTML probes only, no DB):
python feasibility_local_data.py --dry-run --verbose

# Full check (requires DATABASE_URL in .env.local):
python feasibility_local_data.py --verbose
```

Then review `FEASIBILITY_LOCAL_DATA.md` and respond "approved" or with adjustments for import scope.

## Self-Check

- [x] `EV-Backend/scripts/feasibility_local_data.py` exists and passes syntax check
- [x] Script has all 4 probe sections (check_lacounty, check_bloomington, check_name_matching, write_report)
- [x] Script accepts --dry-run, --verbose, --output flags
- [x] Commit b7732c8 exists in EV-Backend repo

## Self-Check: PASSED

## Next Phase Readiness

- Script ready to run — user needs to execute and review output
- After user reviews FEASIBILITY_LOCAL_DATA.md, plans 58-02 and 58-03 are authorized to proceed
- Import scope for both plans is gated on feasibility findings

---
*Phase: 58-local-data-pipeline*
*Completed: 2026-03-03 (partial — paused at Task 2 human-action checkpoint)*
