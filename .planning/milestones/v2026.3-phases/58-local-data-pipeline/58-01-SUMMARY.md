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
    - EV-Backend/scripts/FEASIBILITY_LOCAL_DATA.md
  modified: []

key-decisions:
  - "feasibility_local_data.py written programmatically: report generated from live HTTP probes, not hand-authored"
  - "Script uses separate requests per Legistar PersonId (OData v3 does not support in operator)"
  - "Name matching uses ILIKE on last name first, RapidFuzz token_sort_ratio threshold=80 as fallback"
  - "Local scope confirmed = committees and legislation only — vote attribution infeasible at both sources (VoteRecords 404, OnBoard has no vote data)"
  - "LA County plan 58-03 scoped to OfficeRecords only — MatterRequester NULL for 98% of recent matters, MoverName only pre-2010"
  - "Bloomington plan 58-02 will import sponsors where found (~50% coverage) and skip + log where absent"
  - "Courtney Daily missing from DB (MISS) — requires investigation before 58-02 import"
  - "Barger and Mitchell return AMBIG matches — 58-03 must use Legistar PersonId as primary key, not name matching"

patterns-established:
  - "Feasibility scripts follow import_state_legislative.py pattern: dotenv .env.local, argparse, --dry-run flag"
  - "check_bloomington() / check_lacounty() functions return findings dicts for programmatic report writing"

requirements-completed: [LOCAL-01]

# Metrics
duration: ~85min (two sessions)
completed: 2026-03-03
---

# Phase 58 Plan 01: Local Data Pipeline Feasibility Check Summary

**Python feasibility script probes Bloomington OnBoard HTML and LA County Legistar REST API live — confirms committees importable at both sources, vote attribution infeasible, 11/14 politicians matched in DB**

## Performance

- **Duration:** ~85 min (two sessions — Task 1 prior session, Task 2 continuation)
- **Started:** 2026-03-02T20:00:00Z
- **Completed:** 2026-03-03T01:21:42Z
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Created `feasibility_local_data.py` with all 4 probe sections: LA County Legistar, Bloomington OnBoard, politician name matching, and programmatic Markdown report writing
- Ran full feasibility script with live DB — generated `FEASIBILITY_LOCAL_DATA.md` with complete capability matrix, endpoint-by-endpoint results, and scoped import recommendations
- Confirmed all committee IDs working (Bloomington: 1, 77, 81, 49; LA County: all 5 supervisor PersonIds returning active OfficeRecords)
- Confirmed vote attribution infeasible: Legistar `/VoteRecords` returns 404, OnBoard has no vote data anywhere
- Matched 11 of 14 politicians (3/5 LA supervisors exact, 2 ambiguous; 8/9 Bloomington members exact, 1 missing)

## Task Commits

1. **Task 1: Create feasibility check script** - `b7732c8` (feat)
2. **Task 2: Run feasibility script and generate report** - `34d0888` (feat)

## Files Created/Modified

- `EV-Backend/scripts/feasibility_local_data.py` - 912-line feasibility check script with 4 probe sections and programmatic report writing
- `EV-Backend/scripts/FEASIBILITY_LOCAL_DATA.md` - Generated feasibility report with capability matrix, per-endpoint HTTP results, name match table, and scoped import recommendations

## Decisions Made

- Used `check_lacounty()` / `check_bloomington()` / `check_name_matching()` separate functions returning dicts — enables write_report() to format results programmatically without re-querying
- Dual matching strategy: ILIKE on last name first (covers unambiguous cases), RapidFuzz fallback (covers hyphenated names, middle initials, etc.)
- BeautifulSoup member extraction uses `/onboard/members/{id}` link pattern as primary, text-line fallback for committees with different HTML structure
- **Plan 58-03 scoped to committees only** — MatterRequester NULL 98%, MoverName only pre-2010; recent legislation attribution is infeasible
- **Plan 58-02 sponsor import is best-effort** — ~50% coverage confirmed from 3 sampled items, skip+log pattern for missing sponsors

## Deviations from Plan

None — plan executed exactly as specified. Script matches all plan requirements: 4 probe sections, 3 CLI flags, follows import_state_legislative.py pattern.

## Issues Encountered

- EV-Backend is a separate git repository from the workspace root — committed to `EV-Backend` repo directly (not workspace root). This is the correct pattern for all EV-Backend script work.

## Issues Encountered

- **2 LA supervisors ambiguous (Kathryn Barger, Holly J. Mitchell):** ILIKE returned multiple rows from DB; RapidFuzz also returned AMBIG. Plan 58-03 must use Legistar PersonId as primary bridge key, not name matching — confirmed design decision.
- **Courtney Daily missing (MISS):** No record in `essentials.politicians`. Likely not cached for Bloomington ZIP codes yet. Plan 58-02 should either trigger a BallotReady re-fetch for ZIP 47401/47403 or document this gap and import the 8 matched members.

## User Setup Required

None — feasibility complete. Script was run with live DB. No new infrastructure required for plans 58-02 or 58-03.

## Self-Check

- [x] `EV-Backend/scripts/feasibility_local_data.py` exists (b7732c8)
- [x] `EV-Backend/scripts/FEASIBILITY_LOCAL_DATA.md` exists (34d0888)
- [x] Report contains Capability Matrix with both jurisdictions
- [x] Report contains per-endpoint HTTP results for LA County Legistar (7 endpoints)
- [x] Report contains per-committee HTML results for Bloomington OnBoard (4 committees)
- [x] Report contains name match table (14 politicians: 5 supervisors + 9 council members)
- [x] Report contains scoped import recommendations for 58-02 and 58-03
- [x] Vote attribution documented as infeasible with evidence (VoteRecords 404, OnBoard no vote data)
- [x] Commit b7732c8 exists in EV-Backend repo
- [x] Commit 34d0888 exists in EV-Backend repo

## Self-Check: PASSED

## Next Phase Readiness

- **58-02 (Bloomington import) is ready to plan:** 8/9 council members matchable, all 4 committee IDs confirmed, sponsor regex confirmed working on live pages. Known gap: Courtney Daily.
- **58-03 (LA County import) is ready to plan:** All 5 supervisor PersonIds confirmed active, 29 committee memberships ready to import. Known gap: Barger and Mitchell require PersonId-based bridging (no name-match).
- **Both plans are authorized** — user reviewed and approved feasibility report.

---
*Phase: 58-local-data-pipeline*
*Completed: 2026-03-03*
