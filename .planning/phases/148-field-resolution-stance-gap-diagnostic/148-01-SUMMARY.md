---
phase: 148-field-resolution-stance-gap-diagnostic
plan: 01
subsystem: civic-data-diagnostics
tags: [diagnostic, read-only, incumbent-map, stance-gap, us-house, wave-1]
requires:
  - "essentials.districts / offices / politicians (live prod, read-only)"
  - "inform.politician_answers (live prod, read-only)"
provides:
  - "148-incumbent-map.csv — per-district incumbent->politician_id + stance_count + top_up_tier + vacancy flag (DB half of the field table, keyed on geo_id)"
  - "backend/scripts/diag-148-incumbent-stance-gap.ts — re-runnable SELECT-only diagnostic"
affects:
  - "Phase 149 (CA) / 150 (TX+NY) / 151 (FL) — read incumbent_pid to reuse records, top_up_tier to scope stance work"
tech-stack:
  added: []
  patterns:
    - "Map incumbent by (district_type='NATIONAL_LOWER', geo_id) — never computed external_id"
    - "COUNT(*) on inform.politician_answers (no id column)"
    - "Vacancy = office with holder_ct != 1 (HAVING COUNT(o.politician_id) <> 1)"
key-files:
  created:
    - backend/scripts/diag-148-incumbent-stance-gap.ts
    - .planning/phases/148-field-resolution-stance-gap-diagnostic/148-incumbent-map.csv
  modified: []
decisions:
  - "external_id verified per-state (CA -6000301 confirmed live) — geo_id join is authoritative, computed external_id would mis-key CA/TX"
metrics:
  duration: "~5 min"
  completed: "2026-06-28"
  tasks: 2
  files: 2
---

# Phase 148 Plan 01: Field Resolution + Stance-Gap Diagnostic (DB Half) Summary

Read-only production diagnostic that maps all 144 Wave-1 (CA/TX/FL/NY) US House districts to their seated incumbent's existing `essentials.politicians.id` by `(district_type='NATIONAL_LOWER', geo_id)`, reports each incumbent's compass stance count with a top-up tier, and enumerates the two confirmed vacancies — captured as a git-tracked 144-row CSV keyed on geo_id for the seeding phases to consume.

## What Was Built

1. **`backend/scripts/diag-148-incumbent-stance-gap.ts`** — SELECT-only, re-runnable diagnostic using the in-repo `pg` `pool` (`import { pool } from '../src/lib/db.js'`) + `import 'dotenv/config'`. Runs four read-only queries (incumbent map, per-state stance-gap summary, vacancy detection, per-state district tally) and then writes the CSV artifact. Hard-guards on exactly 144 data rows before writing; no INSERT/UPDATE/DELETE, no `--commit`.
2. **`148-incumbent-map.csv`** — 145 lines (1 header + 144 data): 142 mapped incumbents + 2 VACANT rows. Columns: `state, cd, geo_id, incumbent_name, incumbent_pid, incumbent_external_id, incumbent_is_active, incumbent_stance_count, incumbent_top_up_tier`.

## Exact Per-State Stance-Gap Counts (live 2026-06-28)

| State (FIPS) | Incumbents | zero | partial (1–23) | done (≥24) | min / max / avg |
|--------------|:----------:|:----:|:--------------:|:----------:|:----------------:|
| CA (06) | 52 | 36 | 7 | 9 | 0 / 29 / 7.5 |
| FL (12) | 27 | 0 | 27 | 0 | 6 / 23 / 14.6 |
| NY (36) | 26 | 0 | 25 | 1 | 4 / 24 / 15.8 |
| TX (48) | 37 | 37 | 0 | 0 | 0 / 0 / 0.0 |

CSV-wide top-up tier totals across all 144 rows: **73 zero / 59 partial / 10 done / 2 vacant**. This confirms the milestone's stale "incumbents already stanced" assumption is FALSE for Wave-1 House — ~134/142 mapped incumbents are below the federal-24 bar (73 at zero), so incumbent stance top-up is a substantial 149–151 workstream.

## Vacancies

Both confirmed vacancies surfaced exactly via Query C (`HAVING COUNT(o.politician_id) <> 1`):

| geo_id | District | office_ct | holder_ct | CSV row |
|--------|----------|:---------:|:---------:|---------|
| 1220 | FL-20 | 0 | 0 | `FL,20,1220,VACANT,,,,0,vacant` |
| 4823 | TX-23 | 1 | 0 | `TX,23,4823,VACANT,,,,0,vacant` |

Both rows carry empty `incumbent_pid` / `incumbent_external_id` / `incumbent_is_active`, `incumbent_stance_count=0`, `incumbent_top_up_tier=vacant`. No incumbent record exists to reuse — all general candidates there are new records.

## Unexpected (non-1) Holders

**None.** Query C returned exactly the two known vacancies and no other district with a non-1 holder count. Every other Wave-1 district (142) has exactly one seated incumbent mapped to a UUID by the geo_id join. (Sanity check: CA-1 LaMalfa external_id is `-6000301`, matching the verified CA scheme — confirming the join resolves identity by geo_id, not a computed formula that would have mis-keyed CA/TX.)

## Verification Results

- Query A returned **142** mapped incumbent rows (144 − 2 vacancies). ✅
- Query B printed **4** state rows; TX all-37 at zero_stance, CA 36 at zero (majority). ✅
- Query C returned **exactly** the 2 vacancies (1220, 4823). ✅
- Per-state district tally reconciled **CA 52 / TX 38 / FL 28 / NY 26 = 144**. ✅
- CSV is **145 lines** (1 header + 144 data), exactly **2** VACANT rows, every non-vacant row has a UUID `incumbent_pid`, per-state CSV counts reconcile. ✅
- Script exited 0 with no `column pa.id does not exist` error. ✅

## Deviations from Plan

None — plan executed exactly as written. Both tasks were satisfied by a single script run (Task 2's CSV write is gated behind Task 1's read-only queries within the same script, per the plan's allowance), committed as two separate atomic commits.

## Commits

- `0c2295f8` — feat(148-01): add read-only incumbent + stance-gap diagnostic script
- `81c2f5ee` — feat(148-01): emit 144-row incumbent-map CSV (DB half of field table)

## Known Stubs

None. The CSV is fully populated from live DB data; the two empty-`incumbent_pid` rows are correct vacancy representations, not stubs.

## Self-Check: PASSED

- FOUND: backend/scripts/diag-148-incumbent-stance-gap.ts
- FOUND: .planning/phases/148-field-resolution-stance-gap-diagnostic/148-incumbent-map.csv
- FOUND: .planning/phases/148-field-resolution-stance-gap-diagnostic/148-01-SUMMARY.md
- FOUND commit: 0c2295f8
- FOUND commit: 81c2f5ee
