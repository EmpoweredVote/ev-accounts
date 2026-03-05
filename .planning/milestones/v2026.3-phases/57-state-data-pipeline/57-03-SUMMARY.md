---
phase: 57-state-data-pipeline
plan: "03"
subsystem: database
tags: [python, open-states, committee-memberships, legiscan, state-legislative]

# Dependency graph
requires:
  - phase: 57-state-data-pipeline
    provides: "Indiana and California legislative sessions, bills, votes, and committee tables populated; legislative_politician_id_map bridge table populated; known test politician UUIDs (Rodric Bray, Lisa Calderon)"
provides:
  - "import_state_committees.py: Python script to import state legislative committee memberships from Open States API v3"
  - "Budget warning fix: import_state_legislative.py now emits < 5000 non-fatal warning for CA imports before the < 100 hard exit"
affects: [57-VERIFICATION, frontend-profile-sections]

# Tech tracking
tech-stack:
  added: ["Open States API v3 (https://v3.openstates.org)"]
  patterns: ["Two-pass committee matching: name match first, then create new row if unmatched", "Single-match-only guard for politician name resolution", "Bridge table upsert for openstates OCD person IDs", "6-second rate limit enforcement for Open States 10/min free tier"]

key-files:
  created:
    - "EV-Backend/scripts/import_state_committees.py"
  modified:
    - "EV-Backend/scripts/import_state_legislative.py"

key-decisions:
  - "Open States jurisdiction param accepts state name ('Indiana', 'California'), not abbreviation ('IN', 'CA') — matches API v3 spec"
  - "Committee matching uses case-insensitive name lookup against existing DB committees before creating new rows — avoids duplicating the 41 IN / 60 CA committees already populated from LegiScan bill referrals"
  - "Politician lookup uses ILIKE first_name prefix to handle middle initials (e.g., 'Vernon G.' matches 'Vernon') with hard single-match guard (0 or 2+ = skip, never assume)"
  - "Memberships use congress_number=0 for state legislators (non-federal), matching the existing model pattern"
  - "Bridge rows use id_type='openstates' with OCD person IDs to speed future re-runs"
  - "Budget warning (< 5000 CA) is non-fatal warning only — script continues; < 100 hard exit unchanged"

patterns-established:
  - "Open States API two-pass committee match: name lookup → create new with source='openstates'"
  - "Single-match guard for all politician name resolution: 0 or 2+ matches → log + skip, never guess"

requirements-completed: [STATE-01, STATE-02, STATE-03]

# Metrics
duration: 15min
completed: 2026-03-04
---

# Phase 57 Plan 03: Open States Committee Membership Import Summary

**Python import script for state legislative committee memberships via Open States API v3 with two-pass committee matching, single-match politician lookup guard, and OCD bridge rows**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-03-04T03:24:47Z
- **Completed:** 2026-03-04T03:40:00Z
- **Tasks:** 1/2 complete (Task 2 is checkpoint:human-action — awaiting OPENSTATES_API_KEY and manual import run)
- **Files modified:** 2

## Accomplishments
- Created `import_state_committees.py` (660 lines): fetches all committee pages from Open States API, matches to existing DB committees by name, creates new committees where unmatched, links members to politicians via name matching with single-match guard
- Fixed `import_state_legislative.py` budget warning: added < 5000 non-fatal CA-only warning before the existing < 100 hard exit, closing the Plan 57-02 spec mismatch
- Script supports --state IN|CA, --dry-run, --verbose; uses OPENSTATES_API_KEY and DATABASE_URL from .env.local

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Open States committee import script and fix budget warning** - `0abc68f` (feat) — EV-Backend repo

**Plan metadata:** (pending — awaiting Task 2 checkpoint resolution)

## Files Created/Modified
- `EV-Backend/scripts/import_state_committees.py` - New script: Open States API v3 committee membership import for IN/CA
- `EV-Backend/scripts/import_state_legislative.py` - Modified: added < 5000 budget warning for CA (non-fatal, matches Plan 57-02 spec)

## Decisions Made
- Open States jurisdiction param accepts state name strings ("Indiana", "California"), not state codes ("IN", "CA") — verified against API v3 spec in PLAN.md context
- Two-pass committee matching: name match to existing 41 IN / 60 CA committees first (from LegiScan bill referrals), then create new rows with source='openstates' — avoids duplicating existing data
- Politician lookup uses `ILIKE first_name || '%'` to handle middle initials, with strict single-match-only guard. Zero or 2+ matches → log at DEBUG level → skip. Never guess on ambiguous politician identity.
- `congress_number=0` for all state legislators — consistent with the existing membership model used for federal members where congress number is meaningless at state level
- Bridge rows use `id_type='openstates'` with OCD-division person IDs to short-circuit name lookups on future re-runs
- Rate limiting: 6-second sleep between API pages enforces the 10 requests/minute free tier limit

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None — all dependencies (psycopg2, requests, python-dotenv) already in requirements-state.txt. No new packages needed.

## User Setup Required

**Task 2 requires manual steps before committee data can be imported into the database:**

1. Register for Open States API key at https://openstates.org/accounts/signup/
2. Get API key from https://openstates.org/accounts/profile/
3. Add `OPENSTATES_API_KEY=your-key-here` to `EV-Backend/.env.local`
4. Run dry-run: `python import_state_committees.py --state IN --dry-run --verbose`
5. Run for real: `python import_state_committees.py --state IN --verbose`
6. Verify via API: `GET /essentials/politician/97c61094-b962-48b2-b6ef-de96b5f9bb7a/committees` (Rodric Bray, Indiana)
7. Run California: `python import_state_committees.py --state CA --verbose`
8. Verify via API: `GET /essentials/politician/0afa998d-94e9-4af4-ba00-256c38869398/committees` (Lisa Calderon, California)

## Next Phase Readiness
- Script is ready to run once OPENSTATES_API_KEY is configured
- No Go backend changes needed — existing committee handler serves Open States data automatically
- ROADMAP Phase 57 success criterion 3 ("GET /politician/{id}/committees returns committee data for known state legislators") will be satisfied after Task 2 runs

---
*Phase: 57-state-data-pipeline*
*Completed: 2026-03-04 (Task 1 only; Task 2 awaiting human action)*

## Self-Check: PASSED

- FOUND: EV-Backend/scripts/import_state_committees.py
- FOUND: EV-Backend/scripts/import_state_legislative.py
- FOUND: .planning/phases/57-state-data-pipeline/57-03-SUMMARY.md
- FOUND commit: 0abc68f (feat(57-03): add Open States committee membership import script and fix budget warning)
