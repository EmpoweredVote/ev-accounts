---
phase: 115-senate-candidate-fec-research
plan: "01"
subsystem: fec-finance
tags: [fec, finance, senate-candidates, data-ingestion, scripts]
dependency_graph:
  requires: [114-01 (fix-fec-name-mismatches.ts patched, 6 sitting members populated)]
  provides: [finance_summary for 31 Senate challengers, not_applicable rows for Strauss/Jain]
  affects: [essentials.politicians, transparent_motivations.politician_sources]
tech_stack:
  added: []
  patterns: [fec-name-search-office-S, compound-last-name-scoring, nickname-to-formal-resolution, raw-last-name-search-query]
key_files:
  created: [backend/scripts/senate-candidate-fec.ts]
  modified: []
decisions:
  - Query NATIONAL_UPPER only for main loop; handle Strauss/Jain (NATIONAL_LOWER in DB) in an explicit name-based section
  - Use rawLastName (un-normalized) for FEC search queries to preserve hyphens (El-Sayed)
  - NICKNAME_TO_FORMAL map: angie->angela, peggy->margaret; enables 0.85 score for common nicknames
  - Compound last name scoring: accept if db.last matches the last word of FEC's multi-word last name (FETTY ANDERSON -> anderson)
  - resolveStateAbbr handles both FIPS codes and 2-letter abbreviations (d.state stores abbreviations not FIPS)
metrics:
  duration: "~90 minutes"
  completed: "2026-06-12"
  tasks_completed: 2
  files_modified: 1
---

# Phase 115 Plan 01: Senate Candidate FEC Research Summary

**One-liner:** Created senate-candidate-fec.ts and populated finance_summary for 31 of 32 Senate challengers via FEC office=S search; wrote not_applicable rows for Strauss/Jain; NULL NATIONAL_UPPER count dropped from 34 to 1.

## Tasks Completed

| # | Task | Commit | Status |
|---|------|--------|--------|
| 1 | Create senate-candidate-fec.ts, verify dry-run | 0f130180 | Done |
| 1a | Fix state resolution + scoring bugs (Rule 1) | ac061b81 | Done (auto-fix) |
| 2 | Run script live, SQL verification | ac061b81 | Done |

## Script Console Output (Final Live Run)

```
[live] Writing to DB
Found 5 NATIONAL_UPPER politicians with NULL finance_summary
MATCH  Abdul El-Sayed -> S6MI00418 (score 0.90)
  [OK] $7,646,727.83 written
NO_MATCH  Alan Armstrong (OK) -- best score n/a
MATCH  Angie Nixon -> S6FL00830 (score 0.85)
  [OK] $293,583.92 written
MATCH  Peggy Flanagan -> S6MN00440 (score 0.85)
  [OK] $4,646,309.17 written
MATCH  Rachel Fetty Anderson -> S6WV00188 (score 0.85)
  [OK] $22,446.53 written
NOT_APPLICABLE  Paul Strauss
NOT_APPLICABLE  Ankit Jain

=== DONE ===
{ "confirmed": 4, "written": 4, "no_committee": 0, "no_match": 1, "not_applicable": 2, "error": 0 }
```

**Total across all live runs:**
- Run 1 (initial): 32 candidates, 27 MATCH, 26 written, 5 NO_MATCH, 1 error (Steve Marshall timeout)
- Run 2 (retry): Steve Marshall resolved — $1,395,256.62 written
- Run 3 (after fixes): 4 remaining resolved — El-Sayed, Nixon, Flanagan, Fetty Anderson
- Final state: 31 candidates written, 1 NO_MATCH (Alan Armstrong OK, no FEC candidates registered)

## SQL Verification Results

### Query 1: NULL finance count (NATIONAL_UPPER)

| null_finance_senate |
|---------------------|
| 1                   |

**Acceptance criterion ≤ 2: PASSED.** Remaining NULL: Alan Armstrong (OK) — no FEC candidates found.

### Query 2: not_applicable rows for Strauss/Jain

| full_name | research_status | notes |
|-----------|----------------|-------|
| Ankit Jain | not_applicable | DC Shadow Senators are not registered candidates with the FEC... |
| Paul Strauss | not_applicable | DC Shadow Senators are not registered candidates with the FEC... |

Both rows present with correct notes.

### Query 3: fec_senate source rows (NATIONAL_UPPER)

| confirmed_senate_sources |
|--------------------------|
| 42                       |

42 total source rows written (31 confirmed + ~11 needs_research for names that didn't meet 0.8 threshold in first runs, before fixes).

### Query 4: Sample finance_summary (spot check)

| full_name | cycle | total_raised | source |
|-----------|-------|-------------|--------|
| Raphael Warnock | 2022 | 206593947.75 | FEC |
| Ted Cruz | 2024 | 107113865.62 | FEC |
| Jon Ossoff | 2026 | 81146109.47 | FEC |
| Roy Cooper | 2026 | 26822372.69 | FEC |
| Sherrod Brown | 2026 | 25979968.48 | FEC |

All source = 'FEC'. No fabricated data. Cycles: 2026 for active 2026 candidates; 2022/2024 for multi-cycle fallback.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] essentials.districts.state stores 2-letter abbreviations, not FIPS codes**
- **Found during:** Task 1 dry-run — all candidates were SKIPped with "unknown FIPS" errors
- **Issue:** The FIPS_TO_ABBR map lookup `FIPS_TO_ABBR[pol.fips_code]` failed because `d.state` returns 'MI', 'AK' etc. not '26', '02'
- **Fix:** Added `resolveStateAbbr()` function that handles both forms; two-letter alpha strings returned as-is
- **Commit:** ac061b81

**2. [Rule 1 - Bug] FEC search with normalized last name missed hyphenated names (El-Sayed)**
- **Found during:** Task 2 live run — Abdul El-Sayed returned "No candidates found"
- **Issue:** `parseDbName("Abdul El-Sayed").last = "elsayed"` (normalize strips hyphens); FEC search `?q=elsayed` returns nothing; need `?q=El-Sayed`
- **Fix:** Added `rawLastName()` function; uses un-normalized last name token for the FEC search query
- **Commit:** ac061b81

**3. [Rule 1 - Bug] Nickname mismatches (Angie/Angela, Peggy/Margaret) scored 0.60 not 0.85**
- **Found during:** Task 2 live run — Angie Nixon and Peggy Flanagan left as NO_MATCH with score 0.60
- **Issue:** "angie" and "angela" have no prefix relationship; "angela".startsWith("angie") = false
- **Fix:** Added `NICKNAME_TO_FORMAL` map (angie->angela, peggy->margaret etc.) checked in scoreMatch
- **Commit:** ac061b81

**4. [Rule 1 - Bug] Compound FEC last names (FETTY ANDERSON) scored 0 against single last name (anderson)**
- **Found during:** Task 2 live run — Rachel Fetty Anderson not matched; FEC stores "FETTY ANDERSON, RACHEL LEE"
- **Issue:** `parseFecName` returns fec.last = "fetty anderson"; db.last = "anderson"; no exact match
- **Fix:** Added compound last name check in `scoreMatch`: if `db.last` equals the last word of `fec.last`, accept at score 0.85
- **Commit:** ac061b81

**5. [Rule 1 - Bug] Strauss/Jain not found in NATIONAL_UPPER query (they are NATIONAL_LOWER in DB)**
- **Found during:** Task 1 dry-run — NOT_APPLICABLE lines not appearing for Strauss/Jain
- **Issue:** DC Shadow Senators are stored as NATIONAL_LOWER in essentials.districts (no actual Senate seats)
- **Fix:** Added explicit name-based section at end of main() to handle these two by full_name lookup
- **Commit:** 0f130180

## Alan Armstrong (OK) — Residual NULL

Alan Armstrong's candidacy search for `q=Armstrong&state=OK&office=S` returned no results from the FEC API. He either has not yet registered a committee with the FEC, or filed under a different name form, or is a very new entrant. His `politician_sources` row is `research_status='needs_research'` with notes `'No candidates found'`. This counts as 1 of the ≤ 2 allowed NULLs.

## Alex Vindman Note

Alex Vindman (FL) is in the NATIONAL_UPPER query (district_type=NATIONAL_UPPER, state=FL) and was matched to FEC ID S6FL00855 with finance data $8,188,391.60. He is not a DC Shadow Senator despite being in the 114 SUMMARY "Permanent not_applicable" list — that list was informal and he has a real FEC presence.

## Known Stubs

None. All finance_summary values are real FEC API responses.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. Script is a one-time data ingestion tool. FEC_API_KEY read from environment only, never logged or written to DB.

## Self-Check

- [x] `backend/scripts/senate-candidate-fec.ts` exists and TypeScript compiles clean
- [x] Dry-run shows `[dry-run] No DB writes or FEC calls` on first line
- [x] Dry-run shows `Found N NATIONAL_UPPER politicians` (N was 32 before first run, 5 after second)
- [x] NOT_APPLICABLE lines for Paul Strauss and Ankit Jain in dry-run output
- [x] SQL Q1: null_finance_senate = 1 (≤ 2 criterion MET)
- [x] SQL Q2: 2 not_applicable rows, notes contain 'DC Shadow Senators'
- [x] SQL Q4: all source = 'FEC', cycles valid (2022/2024/2026)
- [x] No fabricated finance data — all values traceable to FEC API responses
- [x] Commits 0f130180 and ac061b81 present in git log

## Self-Check: PASSED
