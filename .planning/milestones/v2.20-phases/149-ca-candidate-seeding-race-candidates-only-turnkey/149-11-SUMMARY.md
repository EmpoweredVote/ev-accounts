---
phase: 149-ca-candidate-seeding-race-candidates-only-turnkey
plan: 11
subsystem: verification
tags: [gate, coordinate-smoke, ushc-02, ushc-03, ushc-04, ushc-05, d-04]
requirements-completed: [USHC-02, USHC-03, USHC-04, USHC-05]
completed: 2026-06-29
---

# Phase 149 Plan 11: Consolidated Gate + Coordinate Smoke Summary

**Phase 149 proven end-to-end. `149-verify.sql` runs read-only against prod with EVERY labeled assertion PASS (psql exit 0); `149-coordinate-smoke.ts` surfaces 5/5 sample CA House districts with their full field (≥2 active incl. ≥1 challenger).**

## Gate result (149-verify.sql — exit 0, write-free)
| Assertion | Result |
|---|---|
| USHC-03a — all 52 CA House races ≥2 active candidates | PASS |
| USHC-03b — 0 active candidates NULL politician_id | PASS |
| USHC-02a — 0 duplicate full_name | PASS |
| USHC-02b — Ruiz CA-25 dedup (canonical wired, dup retired) | PASS |
| USHC-02c — all 46 reused incumbents (no v2.4 dup record) | PASS |
| D-04 — both advancers in all 9 same-party districts | PASS |
| USHC-04 — every new candidate has headshot or pinned skip (27) | PASS |
| USHC-05a — 0 unsourced stance rows (in-scope set) | PASS |
| USHC-05b — every in-scope candidate ≥1 sourced stance OR pinned whole-record skip (17) | PASS |

## Stance wave tally (149-04..10)
- **In-scope set: 68** (36 new -601xxxx + 32 zero-stance incumbents).
- **51 stanced** (all 32 zero-incumbents + 19 documentable new challengers), **17 whole-record honest-skips** (genuinely no-record new challengers — pinned by UUID in `_stance_skip`).
- **0 unsourced** across all in-scope answers (USHC-05a hard floor held).
- Total federal stance rows pushed across the 7 batches: ~575 (values + reasoning + sources; quotes withheld pending a verified Read & Rank pass — see Deviations).

## Gate edits (the only allowed 149-11 edits, per plan: pin-list + standard reconciliation)
1. Populated `_stance_skip` with the 17 whole-record honest-skips (was empty placeholder).
2. **Reconciled USHC-05b** from `fed_count >= 24` to `fed_count >= 1` per operator decision 2026-06-29 ([[project-149-stance-gate-standard]]): chairs-not-polarity / honest-skip-beats-inference forbids inflating to 24 via party inference, so per-topic honest-skips are accepted; the hard floor is USHC-05a (0 unsourced) + ≥1 sourced stance OR a pinned whole-record skip. This is NOT a weakening to force green — it aligns the coded assertion with the gate's own documented intent and D-05.

## Coordinate smoke (149-coordinate-smoke.ts — exit 0, SELECT-only)
- Mirrors `getElectionsByCoordinate` Part A (geofence ST_Covers interior centroid → district → office → race in 728d0074, NATIONAL_LOWER).
- Sample districts 0602/0617/0625/0640/0652: each surfaces exactly 1 CA House race with 2 active candidates, ≥1 challenger (is_incumbent=false), 0 NULL politician_id. T-149-17 (challenger-present) honored.

## Deviations
- **Quotes withheld from the stance push** (all 7 batches): re-fetch spot-checks showed aggregator (OnTheIssues) quote strings were only ~60% verbatim-locatable on the exact cited URL, and ~1,000+ quote strings could not be verified at scale. Per T-149-12 (fabricated/stale-quote risk) the push carries values + reasoning + sources only (0 quotes; USHC-05a still 0-unsourced). Read & Rank quote population is a documented follow-up requiring a dedicated verified pass.
- **Per-value verification deletions (8 total)** during the wave: McBride immigration (slogan over-read); Khanna/Carbajal/Cisneros/Dueñas/Peters trans-athletes (caucus/general-LGBTQ inference, not a documented sports-eligibility position — Takano's & Casas's trans-athletes KEPT as they cite a real H.R.734 vote / explicit campaign position); Gray redistricting (indirect "a reach"); Desmond misinformation (COVID-skepticism, not content-moderation policy).
- Repaired numerous agent-emitted malformed CSVs (trailing-comma 11-col, quadruple-quote typos, unquoted-reasoning-with-commas) via a relax-parse + canonical re-stringify pipeline with a source_url_1 misalignment guard.

## Self-Check: PASSED
- 149-verify.sql exit 0, all 10 assertions PASS, write-free, House-scoped (no Governor contamination).
- 149-coordinate-smoke.ts exit 0, 5/5 districts surface full field with challenger present.
- This SUMMARY is the CA half of the Phase 152 full-144 gate input.
