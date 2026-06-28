---
phase: 114-fec-script-fix-and-sitting-members
plan: "01"
subsystem: fec-finance
tags: [fec, finance, scripts, data-ingestion]
dependency_graph:
  requires: []
  provides: [finance_summary for 6 federal politicians, patched fix-fec-name-mismatches.ts]
  affects: [essentials.politicians, transparent_motivations.politician_sources]
tech_stack:
  added: []
  patterns: [committee-id-fallback, multi-cycle-totals, direct-fec-name-search]
key_files:
  created: [backend/scripts/_verify-114-01.ts, backend/scripts/_verify-114-01b.ts]
  modified: [backend/scripts/fix-fec-name-mismatches.ts]
decisions:
  - Use DIRECT_FEC_ID_OVERRIDES map for politicians with stale YAML FEC IDs (Ivey H2MD04315→H2MD04232, Self H2TX03290→H2TX00064)
  - Restrict resolveViaDirectSearch to known CA House members only (LaMalfa/Swalwell) to avoid false positives for non-CA or non-House politicians
  - Use DELETE+INSERT pattern for DIRECT path upsert (no unique constraint on politician_id+source_system alone)
  - Fix primary committee lookup field: /candidates/search/ returns .committee_id not .id
metrics:
  duration: "~45 minutes"
  completed: "2026-06-11"
  tasks_completed: 2
  files_modified: 3
---

# Phase 114 Plan 01: FEC Script Fix and Sitting Members Summary

**One-liner:** Patched fix-fec-name-mismatches.ts with committee fallback, multi-cycle totals, and CA House direct search; ingested finance_summary for 6 target politicians (Ivey, Self, Warnock, Cruz, LaMalfa, Swalwell).

## Tasks Completed

| # | Task | Commit | Status |
|---|------|--------|--------|
| 1 | Apply three patches to fix-fec-name-mismatches.ts | a5f5844c | Done |
| 1a | Restrict direct FEC search to known CA House members + fix constraint error | cd3a90b5 | Done (auto-fix) |
| 1b | Correct .committee_id field name + add DIRECT_FEC_ID_OVERRIDES | 23ad256c | Done (auto-fix) |
| 2 | Run script live — finance_summary populated for all 6 targets | ec35bc7d | Done |

## Script Console Output (Task 2 — final live run)

```
[live] Writing to DB
[yaml] Fetching congress-legislators YAML...
[yaml] Built name map: 728 entries

Found 36 federal politicians with NULL finance_summary

...
MATCH     Glenn Ivey → H2MD04232
  [OK] $562,697.55 written
...
MATCH     Keith Self → H2TX00064
  [OK] $504,420.20 written
...

=== DONE ===
{
  "matched": 2,
  "written": 2,
  "no_committee": 0,
  "no_match": 34,
  "error": 0
}
```

First live run (before FEC ID override fix):
- Doug LaMalfa → H2CA02142 — DIRECT — $770,380.18 written
- Eric Swalwell → H2CA15094 — DIRECT — $1,712,405.47 written
- Raphael Warnock → S0GA00559 — MATCH — $206,593,947.75 written (cycle: 2022 via multi-cycle fallback)
- Ted Cruz → S2TX00312 — MATCH — $107,113,865.62 written (cycle: 2024 via multi-cycle fallback)

## SQL Verification Results (Task 2)

### Query 1: finance_summary for 6 targets

| full_name | has_summary | cycle | total_raised |
|-----------|-------------|-------|--------------|
| Doug LaMalfa | true | 2026 | 770380.18 |
| Eric Swalwell | true | 2026 | 1712405.47 |
| Glenn Ivey | true | 2026 | 562697.55 |
| Keith Self | true | 2026 | 504420.20 |
| Raphael Warnock | true | 2022 | 206593947.75 |
| Ted Cruz | true | 2024 | 107113865.62 |

All 6 targets: has_summary = true. (Eric Swalwell appeared twice in the raw JOIN — confirmed single politician record via separate query; double row is a multi-office JOIN artifact, not a data issue.)

Warnock: cycle=2022 (multi-cycle fallback — not on 2026 Senate ballot, no 2026 data)
Cruz: cycle=2024 (multi-cycle fallback — 2024 re-election cycle data found)

### Query 2: LaMalfa/Swalwell politician_sources

| full_name | source_system | external_id | research_status |
|-----------|---------------|-------------|-----------------|
| Doug LaMalfa | fec_house | H2CA02142 | confirmed |
| Eric Swalwell | fec_house | H2CA15094 | confirmed |

Both confirmed. external_id starts with 'H' as expected.

### Query 3: NULL finance count

| null_finance_federal |
|----------------------|
| 34 |

Down from 40 (baseline) — reduced by 6 as planned. Meets acceptance criteria (≤38).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] FEC /candidates/search/ returns `.committee_id` not `.id` in principal_committees**
- **Found during:** Task 2 (live run) — Ivey and Self getting `[skip] No committee`
- **Issue:** TypeScript type was `Array<{ id: string }>` but FEC API returns `committee_id` field
- **Fix:** Changed type and field access to `.committee_id`; also added `DIRECT_FEC_ID_OVERRIDES` for Ivey/Self since their congress-legislators YAML FEC IDs were stale (H2MD04315 → H2MD04232, H2TX03290 → H2TX00064)
- **Files modified:** backend/scripts/fix-fec-name-mismatches.ts
- **Commit:** 23ad256c

**2. [Rule 1 - Bug] `ON CONFLICT (essentials_politician_id, source_system)` constraint does not exist**
- **Found during:** Task 2 (first live run) — David Roth hit the DIRECT path incorrectly
- **Issue:** transparent_motivations.politician_sources has no unique constraint on (essentials_politician_id, source_system); also David Roth (Senate) was incorrectly triggering the CA House direct search
- **Fix:** Added `isKnownCaHouseMember` guard to limit resolveViaDirectSearch to LaMalfa/Swalwell only; used DELETE+INSERT pattern instead of ON CONFLICT DO UPDATE
- **Files modified:** backend/scripts/fix-fec-name-mismatches.ts
- **Commit:** cd3a90b5

## Residual NO_MATCH List (34 politicians — for Phase 115)

Senate challengers (2026 ballot, not sitting members — expected no YAML entries):
Abdul El-Sayed, Alan Armstrong, Angie Nixon, Annie Andrews, Charles Booker, Dakarai Larriett, Dan Osborn, David Brock Smith, David Roth, Derek Dooley, Don Tracy, Graham Platner, Hallie Shoffner, James Byrd, Janak Joshi, John Fleming, John Sununu, Juliana Stratton, Kurt Alme, Mallory McMorrow, Michael Whatley, Peggy Flanagan, Rachel Fetty Anderson, Roy Cooper, Royce White, Scott Colom, Seth Bodnar, Sherrod Brown, Steve Marshall, Zach Wahls

Sitting but not matched (Phase 115):
Mary Peltola (AK-House — not CA House member)

Permanent not_applicable:
Paul Strauss (DC Shadow Rep), Ankit Jain (candidate), Alex Vindman (candidate)

## Known Stubs

None.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. Script is a one-time data ingestion tool using parameterized queries throughout.

## Self-Check

- [x] backend/scripts/fix-fec-name-mismatches.ts contains `candidate/${fecId}/committees/` (fallback URL)
- [x] File contains `committee_id` (fallback field name)
- [x] File contains `for (const cycle of [FEC_CYCLE, '2024', '2022'])` (multi-cycle loop)
- [x] File contains `cycle: usedCycle` in return statement
- [x] File contains `resolveViaDirectSearch` function
- [x] File contains `let fecId` (not const)
- [x] File contains `DIRECT_FEC_ID_OVERRIDES` map
- [x] SQL verification: all 6 targets have non-null finance_summary
- [x] SQL verification: LaMalfa/Swalwell have confirmed fec_house rows with H-prefix external_id
- [x] SQL verification: NULL count = 34 (≤38 acceptance criterion met)
- [x] Commits a5f5844c, cd3a90b5, 23ad256c, ec35bc7d all present in git log

## Self-Check: PASSED
