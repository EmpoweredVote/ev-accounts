---
phase: 97-schema-foundation-data-audit
plan: 03
subsystem: database
tags: [indiana, election-data, xlsx, data-sources, antipartisan, phase-98]

# Dependency graph
requires:
  - phase: 97-schema-foundation-data-audit
    provides: 042_election_schema.sql schema columns to validate real data against
provides:
  - Indiana SoS sample parsing script (ev-accounts/backend/scripts/sample-indiana-candidates.ts) — live download of 12,289 actual candidates, schema-validated
  - DATA_SOURCES.md — three-source documentation with actual column names, coverage gaps, and Phase 98 import recommendations
  - Discovery that SoS Excel lacks LAST NAME and INCUMBENT columns (differs from RESEARCH.md assumptions)
  - Confirmed clean schema fit: real Indiana SoS data maps to 042 without schema changes
affects: [98, election-import-pipeline, electionService]

# Tech tracking
tech-stack:
  added: [xlsx (npm, devDep) — Excel parsing for Indiana SoS candidate files]
  patterns:
    - "SoS Excel row range: skip rows 0-1 (metadata/blank), start parsing at row 2 (header)"
    - "Party column exclusion: explicit skip with console.log noting antipartisan policy (D-04)"
    - "Incumbent identification: not available in SoS filing data — match by politician_id at import time"
    - "DATE FILED in SoS Excel is Excel serial date format (e.g. 46042) — convert via Date.UTC(1900, 0, n-1)"

key-files:
  created:
    - ev-accounts/backend/scripts/sample-indiana-candidates.ts
    - .planning/phases/97-schema-foundation-data-audit/DATA_SOURCES.md
  modified:
    - ev-accounts/backend/package.json (xlsx devDependency added)
    - ev-accounts/backend/package-lock.json

key-decisions:
  - "Indiana SoS Excel actual columns: OFFICE, CANDIDATE NAME, POLITICAL PARTY, DISTRICT, DATE FILED — no LAST NAME or INCUMBENT (differs from RESEARCH.md which listed 7 columns)"
  - "DISTRICT column contains full description string (e.g. 'United States Representative, Eighth District') not just a district number — use as position_name directly"
  - "is_incumbent flag cannot be set from SoS filing data — must be determined at import time by matching CANDIDATE NAME against essentials.politicians records"
  - "DATE FILED is stored as Excel serial date integer (not ISO string) — Phase 98 parser must convert"

patterns-established:
  - "Excel row skip pattern: xlsx.utils.sheet_to_json(ws, { range: 2, defval: '' }) to skip SoS metadata rows"

requirements-completed: [DATA-01]

# Metrics
duration: ~13min
completed: 2026-03-29
---

# Phase 97 Plan 03: Data Sources & Schema Validation Summary

**Live download of 12,289 real Indiana SoS candidates confirms clean schema fit — all 042 columns mapped without schema changes, party excluded, and three-source documentation produced with Phase 98 import pipeline recommendations**

## Performance

- **Duration:** ~13 min
- **Started:** 2026-03-29T20:37:50Z
- **Completed:** 2026-03-29T20:51:00Z
- **Tasks:** 2 (Task 1: parsing script; Task 2: DATA_SOURCES.md documentation)
- **Files modified:** 4

## Accomplishments

- Created and ran `sample-indiana-candidates.ts` against the live Indiana SoS Primary Excel file — 12,289 real candidates successfully parsed and mapped to 042 schema
- Discovered the actual Excel structure differs from RESEARCH.md assumptions: ALL CAPS column names, no separate "Last Name" or "Incumbent" columns, DISTRICT column contains full description strings
- Confirmed clean schema fit: all 7 validation checks pass on real data; no schema redesign needed
- Documented three data sources (Indiana SoS, Monroe County, LA County) with specific URLs, coverage gaps, and Phase 98 import recommendations in DATA_SOURCES.md
- Explicitly excluded `POLITICAL PARTY` column per antipartisan policy (D-04) with logged warning

## Task Commits

Each task was committed atomically:

1. **Task 1: Indiana SoS sample parsing script** - `b3a6ef5` (feat — ev-accounts repo)
2. **Task 2: DATA_SOURCES.md documentation** - `2746837` (feat — planning worktree)

**Plan metadata:** _(this summary commit — docs: complete 97-03 plan)_

## Files Created/Modified

- `ev-accounts/backend/scripts/sample-indiana-candidates.ts` — TypeScript script that downloads Indiana SoS Primary Excel, parses with xlsx, maps OFFICE+DISTRICT → position_name and CANDIDATE NAME → full_name, explicitly excludes POLITICAL PARTY column, validates all schema enums, graceful mock fallback
- `.planning/phases/97-schema-foundation-data-audit/DATA_SOURCES.md` — Full data source documentation with actual column names (confirmed from live download), 3 sample records, schema fit assessment, Monroe County coverage gap (9 council + 12 county/township races), LA County gaps, antipartisan enforcement summary, Phase 98 import pipeline recommendations
- `ev-accounts/backend/package.json` — xlsx devDependency added
- `ev-accounts/backend/package-lock.json` — lockfile updated

## Decisions Made

**1. Indiana SoS Excel actual column names differ from research assumptions**
RESEARCH.md expected `Office, Candidate Name, Last Name, Political Party, District, Date Filed, Incumbent`. The actual file has 5 columns: `OFFICE, CANDIDATE NAME, POLITICAL PARTY, DISTRICT, DATE FILED`. No separate Last Name or Incumbent. The `DISTRICT` column contains the full position description string. The parsing script now handles the actual structure confirmed from live download.

**2. is_incumbent requires politician_id matching at import time**
There is no Incumbent column in the SoS filing data. Incumbents must be identified by matching `CANDIDATE NAME` against `essentials.politicians.full_name` during import. The script defaults `is_incumbent = false` and documents this as a Phase 98 responsibility.

**3. DATE FILED is Excel serial date format**
The SoS Excel stores `DATE FILED` as an integer (e.g., 46042 = 2026-01-15). Phase 98 parser must convert using `new Date(Date.UTC(1900, 0, serialDate - 1))`. Documented in DATA_SOURCES.md.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] xlsx import ESM/CJS interop**
- **Found during:** Task 1 first run
- **Issue:** `xlsx.readFile is not a function` — `import('xlsx')` returns module object with `default` property in tsx/ESM context
- **Fix:** Changed to `const xlsxModule = await import('xlsx'); xlsx = xlsxModule.default ?? xlsxModule;`
- **Files modified:** `sample-indiana-candidates.ts`
- **Commit:** b3a6ef5

**2. [Rule 1 - Bug] Excel header row at index 2, not 0**
- **Found during:** Task 1 first successful download
- **Issue:** First 2 rows are metadata/blank; default `sheet_to_json` parsed them as data, producing empty records
- **Fix:** Added `range: 2` option to `xlsx.utils.sheet_to_json()` to start at the actual header row
- **Files modified:** `sample-indiana-candidates.ts`
- **Commit:** b3a6ef5

**3. [Rule 1 - Bug] RESEARCH.md column names incorrect**
- **Found during:** Task 1 live data validation
- **Issue:** RESEARCH.md listed expected columns including "Last Name" and "Incumbent" — actual file has neither
- **Fix:** Updated COLUMN_MAPPING to match actual column names, updated parseExcelRow to extract last_name from full_name, documented is_incumbent limitation
- **Impact on Phase 98:** Incumbent identification must be done via politician_id matching, not a source column
- **Files modified:** `sample-indiana-candidates.ts`, `DATA_SOURCES.md`
- **Commit:** b3a6ef5

## Known Stubs

None — all documentation reflects real data validated from live source.

## Self-Check: PASSED

- FOUND: `ev-accounts/backend/scripts/sample-indiana-candidates.ts`
- FOUND: `.planning/phases/97-schema-foundation-data-audit/DATA_SOURCES.md`
- FOUND: commit `b3a6ef5` (ev-accounts — parsing script)
- FOUND: commit `2746837` (planning worktree — DATA_SOURCES.md)

---
*Phase: 97-schema-foundation-data-audit*
*Completed: 2026-03-29*
