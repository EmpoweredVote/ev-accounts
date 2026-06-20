---
phase: 137-la-ct-in-ok-ar-ia-house-rep-stances
plan: 03
status: complete
requirements: [USHS-11]
---

# 137-03 SUMMARY — IN House (IN-1,2,3,5,6 — non-contiguous)

**Completed:** 2026-06-20
**Scope:** external_id −18001,−18002,−18003,−18005,−18006 (5 reps, NON-CONTIGUOUS — IN-4/−18004 out of scope), all previously 0 stances.

## Result

49 sourced answers + 49 paired sourced context rows pushed to production. **0 unsourced.** 11 quotes inserted + selected, 0 leaks.

| ext_id | District | Rep | Answers | Note |
|--------|----------|-----|---------|------|
| −18001 | IN-1 | Frank Mrvan | 13 | (D) |
| −18002 | IN-2 | Rudy Yakym | 11 | SSM correctly honest-skipped (no documented anti-recognition vote — calibration rule applied by agent) |
| −18003 | IN-3 | Marlin Stutzman | 15 | returning member; SSM=5 backed by 2005 IN constitutional-amendment vote |
| −18005 | IN-5 | Victoria Spartz | 5 | source-blocked honest-partial (Ballotpedia empty, OnTheIssues 404, most sources 403) |
| −18006 | IN-6 | Jefferson Shreve | 5 | 2024 freshman honest-partial |

Per-scope verification (−18001,−18002,−18003,−18005,−18006): answers=49, unsourced=0. **−18004 confirmed absent from merged CSV** (non-contiguous IN_SCOPE held); IN-4 untouched (push keyed to the 5 explicit external_ids).

## Execution note (anomaly)

The Shreve research agent hung ~6.5h on a WebFetch stall/retry loop before returning valid output; re-dispatched Spartz solo with an explicit "try each URL once, no retry" instruction and it completed in ~3.6 min. No data lost. Lesson for 138+: add the brisk/no-retry instruction to every agent prompt and avoid co-dispatching a long-tail agent that blocks the wave.

## Artifacts

- `backend/data/stance-research/2026-06-19-in-house.csv` (committed)
- `backend/data/stance-research/in-house/`

## Self-Check: PASSED
