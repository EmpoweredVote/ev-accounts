---
phase: 113-va-federal-stances
plan: "02"
subsystem: essentials.politicians.finance_summary
tags: [campaign-finance, fec, vpap, va-federal, finance-summary, vafi-01, vafi-02]
dependency_graph:
  requires: [113-01]
  provides: [finance_summary for 11 VA federal House reps, VAFI-01 closed, VAFI-02 closed]
  affects: [essentials.politicians, transparent_motivations.politician_sources]
tech_stack:
  added: []
  patterns: [politician_sources FEC crosswalk, FEC Path 2 primary lookup, idempotent ON CONFLICT UPDATE]
key_files:
  created: [.planning/phases/113-va-federal-stances/113-02-SUMMARY.md]
  modified:
    - backend/scripts/run-fec-finance-summary.ts (no code changes — script used as-is)
    - essentials.politicians (finance_summary column populated for 11 VA reps)
    - transparent_motivations.politician_sources (5 FEC linkage rows inserted)
decisions:
  - "Inserted 5 politician_sources rows directly via psql (data, not schema) to resolve FEC name mismatches without script changes"
  - "VPAP assessed as HTML-only on 2026-06-11 — VAFI-02 closes as vpap-documented per DC OCF precedent"
  - "Jennifer McClellan timeout during re-run is non-blocking — her data was already populated from prior run (confirmed via SELECT)"
metrics:
  duration: "~25 minutes total (20 min FEC script + 5 min setup)"
  completed: "2026-06-11"
  tasks_completed: 3
  files_modified: 2
---

# Phase 113 Plan 02: VA Federal Finance Summary

One-liner: FEC finance_summary populated for all 11 VA federal House reps (11/11) via politician_sources crosswalk fix; VPAP assessed HTML-only; both VAFI-01 and VAFI-02 closed.

## What Was Built

This plan closed VAFI-01 and VAFI-02, the two open finance requirements for Phase 113.

**VAFI-01 (FEC finance_summary):**
- Inserted 5 `transparent_motivations.politician_sources` rows to resolve name mismatches between DB informal names (Rob, Jen, Don) and YAML legal names (Robert, Jennifer, Donald)
- Re-ran `run-fec-finance-summary.ts` — the script's Path 2 (politician_sources crosswalk) picked up all 5 previously-missing reps
- Result: 11/11 VA federal House reps now have `finance_summary` populated with source='FEC', cycle='2026'

**VAFI-02 (VPAP assessment):**
- VPAP (vpap.org) assessed on 2026-06-11
- Finding: HTML-only candidate pages; no API endpoint, no CSV/JSON download buttons confirmed
- Disposition: vpap-documented — closes VAFI-02 per DC OCF precedent (phase 107: "assess... document findings if not machine-readable")

## FEC Run Log Summary (re-run on 2026-06-11)

```json
{"processed":280,"succeeded":236,"skipped_no_fec_id":39,"errors":5,"durationSec":1375.4}
```

- **processed:** 280 active federal politicians
- **succeeded:** 236 (finance_summary written)
- **skipped_no_fec_id:** 39 (no FEC ID in politician_sources or congress-legislators YAML)
- **errors:** 5 (API timeouts — all had prior data in DB; non-blocking)

### Error details (timeouts — all had pre-existing data)
- Jennifer McClellan: timeout (data already in DB from prior run: $891,048.16 raised)
- Kevin Hern: timeout
- Raphael Warnock: timeout
- Roger Marshall: timeout
- Ted Cruz: timeout

## Per-Rep VA Finance Summary Table

| full_name | external_id | populated | source | total_raised |
|-----------|-------------|-----------|--------|--------------|
| Rob Wittman | -5102001 | YES | FEC | $3,398,633.75 |
| Jen Kiggans | -5102002 | YES | FEC | $4,746,033.32 |
| Bobby Scott | -5102003 | YES | FEC | $415,325.06 |
| Jennifer McClellan | -5102004 | YES | FEC | $891,048.16 |
| Ben Cline | -5102005 | YES | FEC | $1,025,397.33 |
| Morgan Griffith | -5102006 | YES | FEC | $1,462,404.58 |
| Eugene Vindman | -5102007 | YES | FEC | $9,673,622.49 |
| Don Beyer | -5102008 | YES | FEC | $1,628,106.55 |
| John McGuire | -5102009 | YES | FEC | $0 (no 2026 receipts) |
| Suhas Subramanyam | -5102010 | YES | FEC | $991,879.02 |
| James Walkinshaw | -5102011 | YES | FEC | $2,279,096.13 |

All 11/11 reps populated. 0 skipped. 0 NULL.

### FEC ID Resolution path for the 5 previously-missing reps

| Rep | DB name | YAML name | FEC ID | Resolved via |
|-----|---------|-----------|--------|--------------|
| Rob Wittman | "Rob" | "Robert" | H8VA01147 | politician_sources (Path 2) |
| Jen Kiggans | "Jen" | "Jennifer" | H2VA02064 | politician_sources (Path 2) |
| Bobby Scott | "Bobby Scott" | "Robert C. Bobby Scott" | H6VA01117 | politician_sources (Path 2) |
| Morgan Griffith | "Morgan Griffith" | "H. Morgan Griffith" | H0VA09055 | politician_sources (Path 2) |
| Don Beyer | "Don" | "Donald" | H4VA08224 | politician_sources (Path 2) |

The 4 newly sworn-in reps (Vindman/McGuire/Subramanyam/Walkinshaw) resolved via congress-legislators YAML (Path 1) — they appear in the YAML despite joining in Jan/Sept 2025.

## VPAP Assessment (VAFI-02)

- **Date assessed:** 2026-06-11
- **URLs visited:** vpap.org/candidates/ — searched for Winsome Earle-Sears, Jason Miyares, Glenn Youngkin, and VA state senate candidates
- **Finding:** HTML-only candidate pages. No download button, no CSV/JSON export, no public API endpoint discoverable. robots.txt returns HTTP 403 (automated access blocked). Terms of Service references "RSS, API and downloads" but no public API endpoint is accessible.
- **Per REQUIREMENTS.md Out of Scope:** "VPAP scraping / unofficial data — Only machine-readable official sources"
- **Disposition:** vpap-documented — VAFI-02 closed. No ingestion script written; none needed.
- **Precedent:** Same pattern as DC OCF (phase 107): assessed, HTML-only confirmed, documented, requirement closed.

## Phase Gate Output (verify-va-federal-113.sql)

```
--- ASSERTION 5: VAFI-01 — finance_summary coverage for 11 VA federal House reps ---
Expected before Wave 2: reps_with_summary = 0 (tolerant). After Wave 2: reps_with_summary >= 9
 reps_total | reps_with_summary | reps_null_summary 
------------+-------------------+-------------------
         11 |                11 |                 0

--- ASSERTION 6: VAFI-01 — finance_summary shape integrity (source=FEC, total_raised present, cycle present) ---
Expected: bad_shape = 0
 bad_shape 
-----------
         0
```

**ASSERTION 5: PASS** — reps_with_summary = 11 (>= 9 threshold)
**ASSERTION 6: PASS** — bad_shape = 0

All other assertions (VAST-04, VAST-05) also pass:
- answer_rows = 105
- answers_missing_context = 0
- context_rows_without_sources = 0
- null_reasoning_rows = 0

## Requirements Closure

| Requirement | Status | Evidence |
|-------------|--------|----------|
| VAFI-01 | CLOSED | 11/11 VA reps have finance_summary; ASSERTION 5 = 11, ASSERTION 6 = 0 |
| VAFI-02 | CLOSED (vpap-documented) | VPAP HTML-only confirmed 2026-06-11; no machine-readable data available |
| VAST-04 | CLOSED (from 113-01) | migration 341 — politician_answers rows for 11 VA reps |
| VAST-05 | CLOSED (from 113-01) | migration 341 — politician_context rows with source URLs |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] FEC name mismatch — 5 reps missing from Path 1 crosswalk**
- **Found during:** Task A (pre-execution analysis from Task 1 handoff)
- **Issue:** script's Path 1b (name map) could not match informal DB names (Rob, Jen, Don) to legal YAML names (Robert, Jennifer, Donald). Path 1a (bioguide) also failed for some.
- **Fix:** Inserted 5 confirmed rows into `transparent_motivations.politician_sources` with FEC IDs directly. Path 2 (primary crosswalk) then resolved them on re-run.
- **Files modified:** transparent_motivations.politician_sources (5 rows via psql)
- **Commit:** data insertion via psql — no migration file (data record, not schema)

### Acceptable script behavior (not deviations)

- **Jennifer McClellan timeout:** API timeout during re-run — her data was already populated from a prior run. Not a failure; idempotent script behavior confirmed.
- **5 non-VA politicians with timeouts:** Kevin Hern, Raphael Warnock, Roger Marshall, Ted Cruz — FEC API timeouts on 2026 cycle totals endpoint. All had prior data in DB. Non-blocking per plan.
- **39 skip_no_fec_id:** Non-VA candidates/state officials with no FEC federal ID — expected behavior, non-blocking.

## Known Stubs

None. All 11 VA reps have real FEC data with non-null total_raised values.

## Self-Check: PASSED

- [x] 5 politician_sources rows confirmed via SELECT (5 rows returned)
- [x] 11/11 VA reps have finance_summary (confirmed via SELECT)
- [x] ASSERTION 5: reps_with_summary = 11
- [x] ASSERTION 6: bad_shape = 0
- [x] VPAP finding documented
- [x] VAFI-01 and VAFI-02 both confirmed closed
