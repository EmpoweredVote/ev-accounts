---
phase: 137-la-ct-in-ok-ar-ia-house-rep-stances
plan: 06
status: complete
requirements: [USHS-11]
---

# 137-06 SUMMARY — IA House (IA-1..IA-4)

**Completed:** 2026-06-20
**Scope:** external_id −19001..−19004 (4 reps), all previously 0 stances.

## Result

41 sourced answers + 41 paired sourced context rows pushed to production. **0 unsourced.** 4 quotes inserted + selected, 0 leaks.

| ext_id | District | Rep | Answers | Note |
|--------|----------|-----|---------|------|
| −19001 | IA-1 | Mariannette Miller-Meeks | 10 | SSM capped at 4 by agent (belief-quote, no ban vote — rule applied) |
| −19002 | IA-2 | Ashley Hinson | 10 | |
| −19003 | IA-3 | Zach Nunn | 10 | |
| −19004 | IA-4 | Randy Feenstra | 11 | SSM correctly skipped (Equality-Act opposition insufficient) |

Per-scope verification (−19001..−19004): answers=41, unsourced=0.

## Phase 137 closeout

Final plan. Phase-wide verification confirms **29/29 in-scope reps covered, 339 total answers, 0 unsourced in-scope** (LA 6, CT 5, IN 5, OK 5, AR 4, IA 4).

## Execution note

Feenstra's CSV had a malformed quote-field wrap (`,""text""` instead of a valid quoted field) — fixed with a line-scoped `sed 's/""/"/g'` after confirming no legitimately-escaped `""` existed elsewhere in the file, then re-merged clean.

## Artifacts

- `backend/data/stance-research/2026-06-19-ia-house.csv` (committed)
- `backend/data/stance-research/ia-house/`

## Self-Check: PASSED
