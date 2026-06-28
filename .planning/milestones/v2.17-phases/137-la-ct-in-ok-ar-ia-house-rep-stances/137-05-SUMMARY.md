---
phase: 137-la-ct-in-ok-ar-ia-house-rep-stances
plan: 05
status: complete
requirements: [USHS-11]
---

# 137-05 SUMMARY — AR House (AR-1..AR-4)

**Completed:** 2026-06-20
**Scope:** external_id −5001..−5004 (4 reps, single-thousands range), all previously 0 stances.

## Result

61 sourced answers + 61 paired sourced context rows pushed to production. **0 unsourced.** 9 quotes inserted + selected, 0 leaks.

| ext_id | District | Rep | Answers |
|--------|----------|-----|---------|
| −5001 | AR-1 | Eric Crawford | 15 |
| −5002 | AR-2 | French Hill | 17 |
| −5003 | AR-3 | Steve Womack | 15 |
| −5004 | AR-4 | Bruce Westerman | 14 (SSM=5 backed by co-sponsored 2015 constitutional amendment) |

Per-scope verification (−5001..−5004): answers=61, unsourced=0. AR single-thousands range; merge IN_SCOPE held.

## Execution note

Crawford's per-rep CSV had the stray-trailing-quote artifact (every row ended `,"`); fixed with `sed -i 's/,"$/,/'` then re-merged clean (the documented repair). All AR research agents ran briskly (~1.5 min each) under the no-retry instruction.

## Artifacts

- `backend/data/stance-research/2026-06-19-ar-house.csv` (committed)
- `backend/data/stance-research/ar-house/`

## Self-Check: PASSED
