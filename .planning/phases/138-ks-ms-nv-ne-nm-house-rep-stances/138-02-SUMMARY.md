---
phase: 138-ks-ms-nv-ne-nm-house-rep-stances
plan: 02
status: complete
requirements: [USHS-12]
---

# 138-02 SUMMARY — MS House (MS-1..MS-4)

**Completed:** 2026-06-20
**Scope:** external_id −28001..−28004 (4 reps), all previously 0 stances.

## Result

54 sourced answers + 54 paired sourced context rows pushed to production. **0 unsourced.** 15 quotes inserted + selected, 0 leaks.

| ext_id | District | Rep | Answers | Note |
|--------|----------|-----|---------|------|
| −28001 | MS-1 | Trent Kelly | 13 | SSM=4 (FADA cosponsor, no documented outright-ban vote — correctly not 5) |
| −28002 | MS-2 | Bennie G. Thompson | 22 | (D) long-serving; SSM=2 (FMA 2004 → RFMA 2022 evolution); redistricting=4 — sole House Dem to vote against For the People Act over its redistricting mandate |
| −28003 | MS-3 | Michael Guest | 12 | abortion=5 (Life at Conception, Born-Alive, no exceptions); SSM honest-skipped |
| −28004 | MS-4 | Mike Ezell | 7 | thin source-blocked freshman (Ballotpedia empty, OnTheIssues 404) — honest partial; climate/fossil anchored on LCV 1% |

Per-scope verification (−28001..−28004): answers = 54, unsourced = 0.

## Calibration notes

- **Dropped 3 Thompson proxy-inferred rows before push:** ai-regulation=3 and data-centers=3 (both scored from Homeland Security Committee membership — committee role is not a documented stance) and trans-athletes=1 ("scored on overall LGBTQ rights record," no documented position on trans athletes in sports). All three explicitly self-flagged "no direct vote/statement found."
- Kelly SSM=4 not 5 — FADA cosponsorship is a religious-exemption posture, not an anti-recognition vote.
- Ezell honest-partial (7) accepted — source wall for a low-profile freshman; honest-skip beats inference.

## Artifacts

- `backend/data/stance-research/2026-06-20-ms-house.csv` (committed)
- `backend/data/stance-research/ms-house/`

## Self-Check: PASSED
