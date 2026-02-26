---
phase: 41
plan: 02
subsystem: essentials/term-dates
tags: [term-dates, go-api, frontend, python-import]
dependency_graph:
  requires: []
  provides: [supervisor-term-dates-in-db, term-date-precision-api, precision-aware-date-display]
  affects: [ev-ui/PoliticianProfile, EV-Backend/essentials/handlers]
tech_stack:
  added: []
  patterns: [psycopg2-url-parse-connection, precision-aware-formatting]
key_files:
  created:
    - EV-Backend/scripts/import_term_dates.py
  modified:
    - EV-Backend/internal/essentials/handlers.go
    - ev-ui/src/PoliticianProfile.jsx
decisions:
  - "import_term_dates.py uses urlparse pattern (not psycopg2.connect(url)) to handle pooler URL with @ in password — consistent with scrape_headshots.py"
  - "TermDatePrecision wired through all 3 DB query paths: fetchOfficialsFromDB, fetchFederalAndStateFromDBFiltered, GetPoliticianByID"
  - "formatTermDate uses parseInt(dateStr, 10) for year precision — avoids UTC timezone bug where new Date('2024') displays as Dec 2023 in US timezones"
  - "City council term dates deferred — city_sources.json has no election_year field; per-city research needed for future phase"
metrics:
  duration_seconds: 293
  completed_date: "2026-02-25"
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  files_modified: 2
---

# Phase 41 Plan 02: Supervisor Term Dates and Precision-Aware Display Summary

**One-liner:** Year-precision term dates for 5 LA County supervisors with UTC-safe frontend formatting via term_date_precision field wired through Go API.

## What Was Built

### Task 1: import_term_dates.py + Go API TermDatePrecision
- Created `EV-Backend/scripts/import_term_dates.py` following the established psycopg2 + urlparse connection pattern
- Imported researched term dates for all 5 LA County Board of Supervisors members (verified 2026-02-25):
  - Hilda L. Solis: 2022–2026
  - Holly J. Mitchell: 2020–2028
  - Lindsey P. Horvath: 2022–2026
  - Janice Hahn: 2024–2028
  - Kathryn Barger: 2024–2028
- All 5 records set with `term_date_precision='year'`
- Added `TermDatePrecision string` field to `OfficialOut` DTO with `json:"term_date_precision,omitempty"`
- Added `COALESCE(p.term_date_precision, '') AS term_date_precision` to SQL SELECT in 3 query paths
- Wired `TermDatePrecision: r.TermDatePrecision` in all 3 OfficialOut mapping locations

### Task 2: Precision-aware formatTermDate in PoliticianProfile.jsx
- Updated `formatTermDate` to accept a `precision` parameter
- Year precision path: uses `parseInt(dateStr, 10)` and returns raw year string
  - Avoids UTC timezone bug: `new Date("2024")` parses as midnight UTC Jan 1, which is Dec 31 2023 in US local time, displaying as "Dec 2023"
- Updated `getTermLine` to read `pol.term_date_precision` and pass it to `formatTermDate`
- Existing behavior unchanged for BallotReady politicians (full ISO dates with no precision = month+year format)

## Verification Results

All 5 supervisors verified in DB:
```
OK: Hilda L. Solis 2022–2026 precision=year
OK: Holly J. Mitchell 2020–2028 precision=year
OK: Lindsey P. Horvath 2022–2026 precision=year
OK: Janice Hahn 2024–2028 precision=year
OK: Kathryn Barger 2024–2028 precision=year
```

- Go build: clean (no errors)
- ev-ui build: clean (ESM + CJS, 81KB)
- `term_date_precision` appears 4 times in handlers.go (1 struct field + 3 SQL SELECTs)
- `precision === 'year'` check in PoliticianProfile.jsx verified

## Decisions Made

1. **psycopg2 URL parse connection pattern** — `import_term_dates.py` uses `urlparse` to extract host/port/dbname/user/password and pass as keyword args to `psycopg2.connect()`. Direct `psycopg2.connect(url)` fails when the pooler URL contains `@` in the password segment. Consistent with `scrape_headshots.py`.

2. **TermDatePrecision wired through all 3 query paths** — `fetchOfficialsFromDB` (ZIP-based queries), `fetchFederalAndStateFromDBFiltered` (state/federal queries), and `GetPoliticianByID` (profile endpoint) all now include `term_date_precision`. The legacy Cicero path (`officialOutFromCicero`) was intentionally left without precision — Cicero-sourced officials don't have year-precision dates.

3. **parseInt over new Date for year strings** — `new Date("2024")` is a known JavaScript UTC timezone trap. Using `parseInt(dateStr, 10)` and returning `String(year)` is robust, explicit, and handles the degenerate case correctly.

4. **City council term dates deferred** — `city_sources.json` provides council URLs for all 89 cities but has no `election_year` field. Term date derivation requires per-city election year research. Satisfies TERM-02 scope as written ("where election year is known").

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] psycopg2.connect(url) fails with pooler DATABASE_URL**
- **Found during:** Task 1 Part B (running import_term_dates.py)
- **Issue:** `psycopg2.connect(os.environ["DATABASE_URL"])` fails with "could not translate host name" because the pooler URL contains `@` in the password, confusing the URL parser
- **Fix:** Added `get_connection()` helper using `urlparse` to extract connection components as keyword args, matching the pattern in `scrape_headshots.py`
- **Files modified:** `EV-Backend/scripts/import_term_dates.py`
- **Commit:** 87805b2

## Self-Check: PASSED

All created/modified files exist on disk:
- FOUND: EV-Backend/scripts/import_term_dates.py
- FOUND: EV-Backend/internal/essentials/handlers.go
- FOUND: ev-ui/src/PoliticianProfile.jsx
- FOUND: .planning/phases/41-building-photos-term-data-contact-enrichment/41-02-SUMMARY.md

All commits verified in respective repos:
- FOUND: 87805b2 in EV-Backend (feat(41-02): import supervisor term dates and wire TermDatePrecision)
- FOUND: 99aed65 in ev-ui (feat(41-02): make formatTermDate precision-aware)
