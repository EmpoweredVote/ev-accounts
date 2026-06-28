---
phase: 139-single-low-rep-states-house-rep-stances
plan: 01
status: complete
requirements: [USHS-13]
---

# 139-01 SUMMARY — HI + ID + MT House (6 reps)

**Completed:** 2026-06-20
**Scope:** external_id −15001,−15002,−16001,−16002,−30001,−30002 (6 reps), all previously 0 stances.

## Result

64 sourced answers + 64 paired sourced context rows pushed to production. **0 unsourced.** 15 quotes inserted + selected, 0 leaks.

| ext_id | District | Rep | Answers | Note |
|--------|----------|-----|---------|------|
| −15001 | HI-1 | Ed Case (D) | 8 | Blue Dog; SSM=1 (sole 1997 HI vote vs marriage-ban + quote); voting-rights=4 (broke w/ Dems on SAVE Act) |
| −15002 | HI-2 | Jill N. Tokuda (D) | 6 | sworn in 2023; SSM=2 (Equality Caucus published platform) |
| −16001 | ID-1 | Russ Fulcher | 16 | SSM=5 (2006 ID constitutional-amendment AYE vote); abortion=5 (no exceptions + felony-penalty) |
| −16002 | ID-2 | Michael K. Simpson | 17 | SSM=2 (voted FOR RFMA + Fairness for All); ukraine=2 ($14B aid vote) — moderate appropriator |
| −30001 | MT-1 | Ryan K. Zinke | 13 | fmr Interior Sec; SSM=4 (opposes SSM but no amendment vote → capped); PCT-questionnaire-sourced rows |
| −30002 | MT-2 | Troy Downing | 4 | thin source-blocked 2024 freshman (Ballotpedia empty, OnTheIssues none, site offline) — honest partial |

Per-scope verification (−15001..−30002): answers = 64, unsourced = 0.

## Calibration notes

- **Dropped 4 caucus-proxy rows before push:** Case civil-rights=2 (vague "sustained record" + caucus, no topic-specific vote); Tokuda civil-rights=2 (caucus-cluster), healthcare=2 (CPC platform inference — CPC spans M4A→public-option), ukraine-support=2 (Ukraine Caucus membership — same basis dropped for Flood in 138).
- **Kept** Case SSM=1 (concrete 1997 vote + quote) and Tokuda SSM=2 (Equality Caucus has a published marriage-equality platform — same standard as kept-Vasquez in 138).
- Fulcher SSM=5 retained (documented 2006 Idaho constitutional-amendment vote). Simpson SSM=2 (RFMA) and Zinke SSM=4 (no amendment vote → capped) both well-calibrated.

## Artifacts

- `backend/data/stance-research/2026-06-20-hi-id-mt-house.csv` (committed)
- `backend/data/stance-research/hi-id-mt-house/`

## Self-Check: PASSED
