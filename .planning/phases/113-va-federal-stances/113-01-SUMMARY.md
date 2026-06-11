---
phase: 113-va-federal-stances
plan: "01"
subsystem: verification
tags: [sql-assertions, va-federal, phase-gate, vast-04, vast-05, vafi-01, vafi-02]
dependency_graph:
  requires:
    - "supabase/migrations/20260610000011_341_va_federal_reps_stances.sql (applied)"
    - "essentials.politicians (ext_id BETWEEN -5102011 AND -5102001)"
  provides:
    - "backend/scripts/verify-va-federal-113.sql — psql phase gate for Phase 113"
  affects:
    - "Wave 2 executor (113-02) can use this script as automated verify command"
tech_stack:
  added: []
  patterns:
    - "SELECT-only assertions (no RAISE EXCEPTION / DO $$) — script always exits psql 0"
    - "JOIN to essentials.politicians for external_id scoping of inform.* assertions"
    - "CASE WHEN finance_summary IS NOT NULL THEN 'populated' ELSE 'NULL' pattern for coverage report"
key_files:
  created:
    - backend/scripts/verify-va-federal-113.sql
  modified: []
decisions:
  - "All 7 assertions are plain SELECT counts — no RAISE EXCEPTION or DO $$ so script exits 0 on empty/pre-Wave-2 state"
  - "VAFI-01 assertion 5 documents pre-Wave-2 baseline as reps_with_summary = 0 (tolerant threshold)"
  - "VAST-04/VAST-05 assertions scope to external_id BETWEEN -5102011 AND -5102001 via JOIN on essentials.politicians"
metrics:
  duration: "~8 minutes"
  completed: "2026-06-11"
  tasks_completed: 1
  tasks_total: 1
  files_created: 1
  files_modified: 0
---

# Phase 113 Plan 01: VA Federal Verification Scaffold Summary

Phase 113 Wave 0 SQL phase-gate — 7 labeled psql assertions covering VAST-04, VAST-05, VAFI-01, VAFI-02 for 11 VA federal House reps (external_id BETWEEN -5102011 AND -5102001), exits 0 on any state including pre-Wave-2 zero finance_summary.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Scaffold verify-va-federal-113.sql with labeled assertions | 3ff3214d | backend/scripts/verify-va-federal-113.sql |

## Assertion List and Actual psql Output

All 7 assertions run against current DB state (migration 341 applied, Wave 2 not yet executed).

### ASSERTION 1: VAST-04 — politician_answers count for 11 VA federal House reps

```
Expected: answer_rows = 105
answer_rows
-----------
        105   ✅ PASS
```

### ASSERTION 2: VAST-05 — every answer has a matching politician_context row

```
Expected: answers_missing_context = 0
answers_missing_context
-----------------------
                      0   ✅ PASS
```

### ASSERTION 3: VAST-05 — every politician_context has at least one source URL

```
Expected: context_rows_without_sources = 0
context_rows_without_sources
----------------------------
                           0   ✅ PASS
```

### ASSERTION 4: VAST-04 negative — no politician_context rows with NULL reasoning

```
Expected: null_reasoning_rows = 0
null_reasoning_rows
-------------------
                  0   ✅ PASS
```

### ASSERTION 5: VAFI-01 — finance_summary coverage for 11 VA federal House reps

```
Expected before Wave 2: reps_with_summary = 0 (tolerant). After Wave 2: >= 9
reps_total | reps_with_summary | reps_null_summary
-----------+-------------------+-------------------
        11 |                 0 |                11   ✅ PASS (pre-Wave-2 baseline)
```

### ASSERTION 6: VAFI-01 — finance_summary shape integrity

```
Expected: bad_shape = 0
bad_shape
---------
        0   ✅ PASS
```

### ASSERTION 7: VAFI-01 + VAFI-02 — per-rep finance coverage report

```
     full_name      | external_id | summary_status | source
--------------------+-------------+----------------+--------
 Rob Wittman        |    -5102001 | NULL           |
 Jen Kiggans        |    -5102002 | NULL           |
 Bobby Scott        |    -5102003 | NULL           |
 Jennifer McClellan |    -5102004 | NULL           |
 Ben Cline          |    -5102005 | NULL           |
 Morgan Griffith    |    -5102006 | NULL           |
 Eugene Vindman     |    -5102007 | NULL           |
 Don Beyer          |    -5102008 | NULL           |
 John McGuire       |    -5102009 | NULL           |
 Suhas Subramanyam  |    -5102010 | NULL           |
 James Walkinshaw   |    -5102011 | NULL           |
```

Pre-Wave-2 baseline: all 11 reps show NULL finance_summary. Wave 2 (113-02) will populate via FEC ingestion.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None. This plan creates only a verification scaffold (read-only SQL). No data is written.

## Threat Flags

None. Script contains read-only SELECT statements only; no new network endpoints or auth paths introduced.

## Self-Check

### Created files exist

- backend/scripts/verify-va-federal-113.sql: FOUND
- .planning/phases/113-va-federal-stances/113-01-SUMMARY.md: FOUND

### Commits exist

- 3ff3214d (feat(113-01): add Phase 113 SQL phase-gate): FOUND

### Required string checks

- ASSERTION 1: VAST-04: FOUND (2 occurrences)
- ASSERTION 2: VAST-05: FOUND (2 occurrences)
- ASSERTION 5: VAFI-01: FOUND (2 occurrences)
- BETWEEN -5102011 AND -5102001: FOUND (9 occurrences)
- finance_summary: FOUND (15 occurrences)
- RAISE EXCEPTION: NOT FOUND (0 occurrences — correct)
- DO $$: NOT FOUND (0 occurrences — correct)

## Self-Check: PASSED
