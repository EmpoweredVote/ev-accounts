---
phase: 60-indiana-california-committee-import
plan: 01
subsystem: database
tags: [python, psycopg2, openstates, iga, committee-import, migration, tracker]

# Dependency graph
requires:
  - phase: 57-state-legislative-infrastructure
    provides: import_state_committees.py with IGA + Open States clients
  - phase: v2026.3
    provides: legislative_committees and legislative_committee_memberships tables

provides:
  - import_state_committees.py with committee_import_tracker.json tracking
  - CA data source decision documented in code (Open States confirmed)
  - Standing committee filter for Open States path (classification=="committee")
  - migrate_old_committees.py for old->new schema migration
affects:
  - 60-02 (Plan 02 runs the actual import using these enhanced scripts)
  - 61 (Validation phase reads from legislative_committees populated by Plan 02)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - committee_import_tracker.json atomic write pattern (matches LegiScan tracker)
    - Old-to-new schema migration with ON CONFLICT DO NOTHING for idempotency

key-files:
  created:
    - EV-Backend/scripts/migrate_old_committees.py
  modified:
    - EV-Backend/scripts/import_state_committees.py

key-decisions:
  - "CA leginfo.legislature.ca.gov has no REST/JSON API (JSF web app); Open States confirmed as CA source"
  - "Standing committee filter for Open States: classification=='committee' (excludes subcommittee/conference)"
  - "Import tracker uses atomic temp-file+rename write (same as LegiScan tracker pattern)"

patterns-established:
  - "committee_import_tracker.json: {state: {last_run, committees_imported, memberships_created, match_failures, source, dry_run}}"
  - "Migration scripts query old tables, use ON CONFLICT DO NOTHING to be idempotent alongside fresh imports"

requirements-completed:
  - STATE-01
  - STATE-02

# Metrics
duration: 25min
completed: 2026-03-05
---

# Phase 60 Plan 01: Committee Import Infrastructure Summary

**import_state_committees.py enhanced with committee_import_tracker.json, CA Open States decision, and standing-committee filter; migrate_old_committees.py created for old-to-new schema migration**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-03-05T18:08:00Z
- **Completed:** 2026-03-05T18:33:00Z
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments

- Researched CA leginfo.legislature.ca.gov API: confirmed no REST/JSON endpoint exists (JSF web app, session-based cookies). Open States API v3 confirmed as CA data source. Decision documented in module docstring.
- Added `committee_import_tracker.json` tracking to `import_state_committees.py` using atomic temp-file+rename pattern matching `legiscan_import_tracker.json`. Logs previous run info at startup; saves `{state: {last_run, committees_imported, memberships_created, match_failures, source, dry_run}}` after each run.
- Added standing-committee filter to Open States path: `classification == "committee"` (excludes subcommittees and conference committees), matching IGA's `type == "standing"` filter for Indiana.
- Created `migrate_old_committees.py` with full migration logic from `essentials.committees` + `politician_committees` to `essentials.legislative_committees` + `legislative_committee_memberships`. Supports `--dry-run` and `--verbose`. Exits cleanly with code 0 when no state data found in old tables.

## Task Commits

Each task was committed atomically (commits in EV-Backend repo):

1. **Task 1: Research CA leginfo API and enhance import script with tracking** - `aab387f` (feat)
2. **Task 2: Create old table migration script** - `8870d32` (feat)

## Files Created/Modified

- `EV-Backend/scripts/import_state_committees.py` - Added TRACKER_PATH, read/save/log tracker functions, CA data source decision in docstring, classification filter for Open States path, json/tempfile/datetime/Path imports at module level
- `EV-Backend/scripts/migrate_old_committees.py` - New migration script: queries old tables for state committee data, derives jurisdiction/chamber from district fields, maps position->role, inserts into v2026.3 tables with ON CONFLICT DO NOTHING

## Decisions Made

- **CA data source:** leginfo.legislature.ca.gov probed at multiple paths (`/api/`, `/cgi-bin/`, committee-specific URLs) — all returned HTTP 404 or JSF session responses. No public REST/JSON API found. Open States API v3 is confirmed for CA.
- **Standing committee filter (Open States):** `classification == "committee"` applied during page accumulation in `fetch_all_committees()`. This filters out subcommittees and conference committees before they reach the database layer, matching the IGA `type == "standing"` filter.
- **Tracker location:** `~/.ev-backend/committee_import_tracker.json` — consistent with `~/.ev-backend/legiscan_import_tracker.json` from `import_state_legislative.py`.
- **Migration script approach:** Python script (not SQL) for consistency with all other import scripts in `scripts/`. Uses `ON CONFLICT DO NOTHING` rather than upsert to preserve any richer data written by the fresh import.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

- Python 3.14 (system `python3`) lacks `psycopg2` and `dotenv` packages. Packages are installed in the project's `scripts/.venv/` (Python 3.13). Verification commands use `.venv/bin/python3` — consistent with how existing scripts are run.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `import_state_committees.py` is ready to run Plan 02 imports (IN with IGA, CA with Open States API key)
- `migrate_old_committees.py` can be run with `--dry-run` first to confirm old tables are empty, then without for migration if needed
- Plan 02 needs `OPENSTATES_API_KEY` set in `EV-Backend/.env.local` for the CA import

---
*Phase: 60-indiana-california-committee-import*
*Completed: 2026-03-05*
