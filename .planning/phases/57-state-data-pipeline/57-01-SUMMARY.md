---
phase: 57-state-data-pipeline
plan: "01"
subsystem: database
tags: [python, legiscan, postgresql, psycopg2, state-legislature, legislative-data]

# Dependency graph
requires:
  - phase: 56-federal-bills-votes
    provides: "legislative_* tables schema and existing bill/vote upsert patterns"
  - phase: 55-legislative-foundation
    provides: "legislative_politician_id_map table, budget counter infrastructure"
provides:
  - "Python import script for IN and CA state legislative data via LegiScan API"
  - "requirements-state.txt with minimal Python dependencies"
  - "LegiScan session discovery, legislator bridge building, bill+vote+committee import pipeline"
affects: [57-02, frontend-legislative-profile]

# Tech tracking
tech-stack:
  added: [psycopg2-binary, requests, python-dotenv]
  patterns:
    - "getMasterList parsed as dict (not list) — key '0' is session metadata, always skipped"
    - "Single-match-only guard for legislator name matching — 0 or 2+ matches skipped"
    - "Inline vote import during bill loop — avoids double getBill API calls"
    - "LegiScan budget counter atomic rename matches Go client pattern"
    - "congress_number=0 for all state committee memberships (required by unique index)"

key-files:
  created:
    - EV-Backend/scripts/import_state_legislative.py
    - EV-Backend/scripts/requirements-state.txt
  modified: []

key-decisions:
  - "Inline vote import during import_bills avoids double getBill calls — votes fetched once per bill, committee data extracted in same pass"
  - "Jurisdiction stored as lowercase full name ('indiana' not 'IN') to match existing federal pattern"
  - "Committee memberships re-fetch getSessionPeople after bill pass — committee_db_map only populated after bills are processed"

patterns-established:
  - "State import pattern: getSessionList -> getSessionPeople (bridge) -> getMasterList -> getBill (per bill, inline votes) -> getSessionPeople (memberships)"
  - "Bridge rows use id_type='legiscan', source='legiscan-state-people'"

requirements-completed: [STATE-01, STATE-03]

# Metrics
duration: 3min
completed: 2026-03-02
---

# Phase 57 Plan 01: State Legislative Import Script Summary

**Python LegiScan import pipeline for IN/CA state bills, votes, and committee data writing to existing essentials.legislative_* tables**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-02T16:31:50Z
- **Completed:** 2026-03-02T16:35:02Z
- **Tasks:** 1 of 2 complete (paused at Task 2: human-action checkpoint)
- **Files modified:** 2

## Accomplishments
- Created `import_state_legislative.py` (453 lines) with full IN/CA LegiScan import pipeline
- Implemented all required functions: legiscan_query, find_session_id, build_legislator_bridge, import_bills (with inline import_votes_for_bill), extract_and_upsert_committees, normalize_bill_status, normalize_vote_cast, upsert_committee_memberships_from_people
- Budget counter reads/writes `~/.ev-backend/legiscan_counter.json` with atomic rename — synced with Go client
- Created `requirements-state.txt` with minimal dependencies (psycopg2-binary, requests, python-dotenv)
- Python syntax verified: `python3 -c "import ast; ast.parse(...)"` passes

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Python import script** - `25c183c` (feat) — EV-Backend repo

**Note:** Task 2 (install deps + run Indiana import) is a human-action checkpoint — requires manual execution with LEGISCAN_API_KEY and DATABASE_URL credentials.

## Files Created/Modified
- `EV-Backend/scripts/import_state_legislative.py` - Full LegiScan import pipeline for IN/CA state legislative data
- `EV-Backend/scripts/requirements-state.txt` - Python dependencies (psycopg2-binary, requests, python-dotenv)

## Decisions Made
- Inline vote import during import_bills avoids double getBill calls — votes fetched once per bill in the same loop, committee data extracted in same pass
- Jurisdiction stored as lowercase full name ("indiana" not "IN") to match existing federal pattern in the schema
- Committee memberships are created after the bill import loop populates the committee_db_map — getSessionPeople is re-fetched for the membership pass (1 additional API call per session)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- EV-Backend has its own git repository separate from the workspace root. Committed from within `/Users/chrisandrews/Documents/GitHub/EV-Backend/` rather than the workspace root.

## User Setup Required

Task 2 requires the following to run the Indiana import:

1. **Install dependencies:**
   ```bash
   cd /Users/chrisandrews/Documents/GitHub/EV-Backend/scripts
   source .venv/bin/activate
   pip install -r requirements-state.txt
   ```

2. **Run dry-run first:**
   ```bash
   python import_state_legislative.py --state IN --sessions current,previous --dry-run --verbose
   ```

3. **Run actual import:**
   ```bash
   python import_state_legislative.py --state IN --sessions current,previous --verbose
   ```

**Environment variables required:** `LEGISCAN_API_KEY` and `DATABASE_URL` (loaded from `.env.local` in EV-Backend root).

## Next Phase Readiness
- Script is ready to run once credentials are available
- After Indiana import completes, the existing API endpoints (`GET /politician/{id}/bills`, `/votes`, `/committees`) automatically serve Indiana state data
- Phase 57-02 covers California import and any schema adjustments needed based on real data

---
*Phase: 57-state-data-pipeline*
*Completed: 2026-03-02*
