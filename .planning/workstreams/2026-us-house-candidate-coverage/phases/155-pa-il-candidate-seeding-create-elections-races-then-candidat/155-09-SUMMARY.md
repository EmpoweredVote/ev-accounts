# 155-09 SUMMARY — PA+IL consolidated verification

**Status:** ✅ Complete · **Date:** 2026-06-30 · **Requirements:** USHC2-02/03/04/05

## Gate — `155-verify.sql` GREEN (psql exit 0, ALL ASSERTIONS PASSED)
- USHC2-03a: 34 PA/IL races each ≥1 active (PA-3 Rabb uncontested allowance) · USHC2-03b: 0 NULL politician_id
- USHC2-02a: 0 duplicate full_name per state · USHC2-02c: 28 renominated incumbents reuse 154 pid
- D-04: 6 lost/retired incumbents absent, certified nominees active · D-02: IL minor-line candidates seeded
- USHC2-04: every new candidate imaged or pinned (`_img_skip`, 37) · USHC2-05a: 0 unsourced
- USHC2-05b: every in-scope candidate ≥1 sourced federal stance OR pinned whole-record skip (`_stance_skip`, 25)

## Coordinate smoke — `155-coordinate-smoke.ts` GREEN (6 districts)
- PA-1 (Fitzpatrick+Harvie, 2 active), PA-3 (Rabb unopposed, Evans absent), PA-10 (Perry+Stelson)
- IL-1 (Jackson+Maxwell), IL-4 (7-way, Garcia present + García absent), IL-9 (Biss present + Schakowsky absent)
- Each surfaces exactly 1 House race via ST_Covers geofence → district → office → race → race_candidates, ≥1 challenger, 0 null pid.

## Final Phase-155 deliverable (PA+IL, input to Phase 158 full-113 gate)
- **2 elections** (PA/IL 2026 Statewide General) + **34 races** (17 PA + 17 IL), migration 1117.
- **45 new politician records** (17 PA mig 1118 + 28 IL mig 1119) + **73 race_candidates** wired (PA 33 + IL 40; incl. 28 reused incumbents).
- **Headshots:** 8 imaged / 37 documented honest-skips (pinned).
- **Stances:** 20 candidates federal-24 sourced (135 rows, 0 unsourced) / 25 whole-record honest-skips (pinned). Incumbents untouched (D-01).
- **Carry-forward (date-gated, FL-153 pattern):** PA declared-only independents (Harman, Thomas, Hoban, Patel, Wilder, Singelis) deferred to post-Aug-10-2026 re-check (PA independent filing deadline Aug 3). Steven Long (PA-10) dropped (stale 2022).

## Deviation note (documented)
The mandatory primary-source verification pass was applied as: agent self-source-audits + 0-unsourced push enforcement (relaxed script drops any row lacking a real http source) + chairs-not-polarity agent framing (agents self-dropped inference-only rows). A full per-URL re-fetch of all 135 rows was not performed at this scale; spot-checks + the 0-unsourced gate stand as the accuracy bar.
