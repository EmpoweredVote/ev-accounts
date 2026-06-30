---
phase: 152-coordinate-verification-gate
plan: 01
subsystem: data-verification
tags: [gate, read-only, coordinate-smoke, ushc-06, wave-1, national-lower]
dependency_graph:
  requires: [149-verify.sql, 150-verify.sql, 151-verify.sql]
  provides: [USHC-06, 152-verify.sql, 152-coordinate-smoke.ts]
  affects: [v2.20-milestone-gate]
tech_stack:
  added: []
  patterns: [ST_PointOnSurface-centroid, ST_Covers-surfacing-join, RAISE-EXCEPTION-labeled-assertions, CREATE-TEMP-TABLE-ON-COMMIT-DROP]
key_files:
  created:
    - backend/scripts/152-verify.sql
    - backend/scripts/152-coordinate-smoke.ts
  modified: []
decisions:
  - "FL-ASYMMETRY: USHC-06-UNSOURCED is an existence check (answer rows lacking sourced context), NOT a coverage assertion — FL ~138 partisan new candidates intentionally have no stances (deferred Phase 153); coverage assertion would false-fail"
  - "NY race count is 26 (not 28) — plan frontmatter listed 26 NY correctly; confirmed live from prod query"
  - "All 4 smoke samples are contested (minActive=2): CA-2 Huffman, TX-7 Fletcher, FL-1 crowded, NY-17 Lawler — all live-confirmed 2026-06-30 before finalizing"
  - "USHC-06-FL-PROVISIONAL uses LIKE 'PROVISIONAL:%' in SQL (not NOTICE format string to avoid % interpolation) — fixed RAISE NOTICE to not include % in string"
  - "Per-phase granular skip pins stay in 149/150/151-verify.sql; this milestone gate asserts only structural invariants (scope, null-pid, dup-name, dup-incumbent, unsourced, provisional, party-column)"
metrics:
  duration: "~20 minutes"
  completed: "2026-06-30"
  tasks_completed: 2
  files_created: 2
---

# Phase 152 Plan 01: Coordinate Verification Gate Summary

Authored the two consolidated, read-only v2.20 Wave-1 milestone gate artifacts (USHC-06): a SQL gate asserting structural invariants across all 144 Wave-1 House districts, and a TypeScript coordinate-surfacing smoke proving 4/4 states surface their House race with a challenger-inclusive field.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | 152-verify.sql — 8-assertion USHC-06 milestone gate | d42f6915 | backend/scripts/152-verify.sql |
| 2 | 152-coordinate-smoke.ts — 4-state coordinate smoke | cf4f7702 | backend/scripts/152-coordinate-smoke.ts |

## Gate Results

### 152-verify.sql (exit 0, all 8 assertions PASS)

```
PASS USHC-06-SCOPE: 52 CA + 38 TX + 28 FL + 26 NY = 144 distinct NATIONAL_LOWER races
PASS USHC-06-ACTIVE: all 144 Wave-1 House races have >=1 active candidate (1 race(s) have <2 — uncontested-seat allowance, e.g. FL-10 Frost)
PASS USHC-06-NULLPID: 0 active candidates with NULL politician_id across all 144 districts
PASS USHC-06-DUPNAME: 0 duplicate full_name within any state (CA/TX/FL/NY) among active candidates
PASS USHC-06-DUPINCUMBENT: 0 politician_id active in 2+ distinct races across the 144 districts
PASS USHC-06-UNSOURCED: 0 unsourced answer rows across all active Wave-1 candidates (CA/TX/FL/NY — existence check, FL-asymmetry-safe)
PASS USHC-06-FL-PROVISIONAL: all 28 FL House races marked PROVISIONAL (Phase 153 will prune after Aug-18 primary)
PASS USHC-06-PARTY: race_candidates has no party/party_affiliation column (party reads from races.primary_party only — antipartisan structural invariant)
ALL ASSERTIONS PASSED (...)
```

### 152-coordinate-smoke.ts (exit 0, COORDINATE SMOKE GREEN 4/4)

```
PASS CA 0602: 1 House race — 2 active, 1 challenger(s), 0 null pid
PASS TX 4807: 1 House race — 2 active, 1 challenger(s), 0 null pid
PASS FL 1201: 1 House race — 5 active, 4 challenger(s), 0 null pid
PASS NY 3617: 1 House race — 2 active, 1 challenger(s), 0 null pid

COORDINATE SMOKE GREEN: 4/4 states surface their US House race with full challenger-inclusive field (CA/TX/NY/FL).
```

## Milestone Totals (prod-verified 2026-06-30)

| State | Races | Active | Challengers | Null PID |
|-------|-------|--------|-------------|----------|
| CA | 52 | 104 | 61 | 0 |
| TX | 38 | 76 | 51 | 0 |
| FL | 28 | 181 | 161 | 0 |
| NY | 26 | 54 | 33 | 0 |
| **Total** | **144** | **415** | **306** | **0** |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] RAISE NOTICE format string with PROVISIONAL:% literal**
- **Found during:** Task 1 (first run of 152-verify.sql)
- **Issue:** `RAISE NOTICE 'FAIL USHC-06-FL-PROVISIONAL: only %/28 FL House races carry the PROVISIONAL:% description sentinel', v_prov` — the second `%` in `PROVISIONAL:%` was interpreted as a PostgreSQL RAISE format placeholder, causing `too few parameters specified for RAISE`
- **Fix:** Changed `PROVISIONAL:%` to `PROVISIONAL:*` in RAISE EXCEPTION message; kept LIKE 'PROVISIONAL:%' in the actual SQL assertion (correct). Also changed the header comment from `PROVISIONAL:%` to `PROVISIONAL:` to avoid confusion
- **Files modified:** backend/scripts/152-verify.sql
- **Commit:** d42f6915 (inline fix before commit)

## Threat Flags

None — both scripts are SELECT-only read-only gate artifacts. No new network endpoints, auth paths, file access patterns, or schema changes introduced.

## Known Stubs

None — gate artifacts, no UI rendering or data wiring concerns.

## Self-Check

- [x] backend/scripts/152-verify.sql — created and verified (exit 0)
- [x] backend/scripts/152-coordinate-smoke.ts — created and verified (exit 0)
- [x] Commits d42f6915 and cf4f7702 exist on master
- [x] All 8 USHC-06 labeled assertions appear in NOTICE output
- [x] Final SQL line: `ALL ASSERTIONS PASSED`
- [x] Final smoke line: `COORDINATE SMOKE GREEN: 4/4 states surface their US House race with full challenger-inclusive field (CA/TX/NY/FL)`

## Self-Check: PASSED
