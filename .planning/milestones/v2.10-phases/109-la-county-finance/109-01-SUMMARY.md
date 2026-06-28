---
phase: 109-la-county-finance
plan: "01"
subsystem: campaign-finance-verification
tags: [campaign-finance, la-county, verification, sql-assertions, wave-0]
dependency_graph:
  requires: []
  provides:
    - backend/scripts/verify-la-county-109.sql
  affects:
    - transparent_motivations.politician_sources
    - essentials.politicians.finance_summary
tech_stack:
  added: []
  patterns:
    - SQL assertion script pattern (mirrors verify-la-county-108.sql)
key_files:
  created:
    - backend/scripts/verify-la-county-109.sql
  modified: []
decisions:
  - "RAISE EXCEPTION removed from comments to satisfy acceptance criteria (plain grep check)"
  - "Assertion 8 is a coverage report (non-blocking) — zero-row cities document gaps, not failures"
metrics:
  duration: "3m"
  completed: "2026-06-09T01:57:57Z"
  tasks_completed: 1
  tasks_total: 1
  files_created: 1
  files_modified: 0
requirements: [LAFI-01, LAFI-02]
---

# Phase 109 Plan 01: Verification SQL Scaffold Summary

**One-liner:** 8-assertion SQL phase-gate script for LA County Finance covering LAFI-01 (LA City Socrata) and LAFI-02 (Netfile per-city coverage) — tolerates empty Wave 0 state, exits 0.

## What Was Built

Created `backend/scripts/verify-la-county-109.sql` as the Phase 109 Wave 0 deliverable — the single source of truth for "is Phase 109 done?" that every later wave executor uses as its automated verify command.

## Assertion List

| # | Requirement | Intent | Expected Threshold |
|---|-------------|--------|-------------------|
| 1 | LAFI-01 | COUNT confirmed la_socrata sources | >= 15 (Lattimore/Jurado may be 0) |
| 2 | LAFI-01 | finance_summary coverage for la_socrata officials | officials_with_summary >= 15, null <= 3 |
| 3 | LAFI-01 | finance_summary shape integrity (LA_SOCRATA) | bad_shape = 0 |
| 4 | LAFI-02 | COUNT confirmed la_county_netfile sources | >= 1 (at least one city accessible) |
| 5 | LAFI-02 | finance_summary coverage for la_county_netfile officials | officials_with_summary >= 1 when source > 0 |
| 6 | LAFI-02 | finance_summary shape integrity (LA_COUNTY_NETFILE) | bad_shape = 0 |
| 7 | LAFI-01 + LAFI-02 | Negative: no placeholder or fabricated finance_summary | placeholder_rows = 0 |
| 8 | LAFI-02 | Per-city Netfile coverage report (all 27 cities) | Coverage report only (non-blocking) |

## Sample Run Output (Wave 0 State)

```
Phase 109 LA County Finance — Verification Gate
===================================================================

--- ASSERTION 1: LAFI-01 --- confirmed_sources: 256  (PASS: >= 15)
--- ASSERTION 2: LAFI-01 --- officials_with_confirmed_source: 253, officials_with_summary: 2, null: 251
                              (EXPECTED: Wave 1/2 ingestion not yet run — null acceptable at Wave 0)
--- ASSERTION 3: LAFI-01 --- bad_shape: 0  (PASS)
--- ASSERTION 4: LAFI-02 --- netfile_sources: 180  (PASS: >= 1)
--- ASSERTION 5: LAFI-02 --- officials_with_netfile_source: 180, officials_with_summary: 0
                              (EXPECTED: finance_summary write script not yet run — Wave 2 deliverable)
--- ASSERTION 6: LAFI-02 --- bad_shape: 0  (PASS)
--- ASSERTION 7            --- placeholder_rows: 0  (PASS)
--- ASSERTION 8            --- 10 cities with politicians shown (Wave 3 cities only in join result)

Exit code: 0
```

**Key observation from Wave 0 run:**
- 256 la_socrata confirmed sources exist (prior work from seeding scripts)
- 180 la_county_netfile confirmed sources exist (prior work)
- Only 2 officials have finance_summary today — Waves 1 and 2 will bring LAFI-01 to >= 15 and LAFI-02 to >= 1
- Assertion 8 shows 10 cities (Wave 3 cities) — the other 17 cities (LA City, BH, SM, Wave 1 Tier 1 cities) may have politicians linked via different office chain paths; Wave 2 results will clarify

## Deviations from Plan

None — plan executed exactly as written.

The only minor adjustment: removed the phrase "RAISE EXCEPTION" from the header comment (it appeared in "never RAISE EXCEPTION" context) to satisfy the acceptance criteria grep check cleanly.

## Known Stubs

None. The script is a pure verification tool with no data stubs.

## Threat Flags

None. This file is a read-only SQL assertion script with no writes, no auth paths, and no new network endpoints.

## Self-Check: PASSED

- `backend/scripts/verify-la-county-109.sql` exists: VERIFIED
- Commit efbe820 exists: VERIFIED
- psql exits 0: VERIFIED (tested against production DB)
- All 8 assertions present: VERIFIED
- ASSERTION 1: LAFI-01 literal present: VERIFIED
- ASSERTION 4: LAFI-02 literal present: VERIFIED
- ASSERTION 7 placeholder check present: VERIFIED
- All 27 city names present: VERIFIED
- source_system = 'la_socrata' present: VERIFIED
- source_system = 'la_county_netfile' present: VERIFIED
- finance_summary->>'source' present: VERIFIED
- No RAISE EXCEPTION: VERIFIED
- No DO $$: VERIFIED
