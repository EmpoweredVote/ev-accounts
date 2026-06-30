# 155-02 SUMMARY — write-free PA/IL verify gate

**Status:** ✅ Complete · **Date:** 2026-06-30 · **Requirements:** USHC2-02/03/04/05

## What was done
Authored **`backend/scripts/155-verify.sql`** — the read-only, per-state PA/IL-scoped labeled-assertion gate for Phase 155 (adapted from the validated `150-verify.sql`). This is the PER-PHASE gate; the milestone gate is Phase 158.

## Assertion labels
- **USHC2-03a** — all 17 PA + 17 IL races have ≥1 active candidate (hard floor ≥1; NOTICE for <2, PA-3 Rabb uncontested allowance); exact race count 17/17.
- **USHC2-03b** — 0 active race_candidates with NULL politician_id (per-state).
- **USHC2-02a** — 0 duplicate full_name among active candidates within each state (D-03).
- **USHC2-02c** — 28 renominated incumbents (16 PA + 12 IL) reuse their 154 incumbent_pid as active is_incumbent candidates.
- **D-04** — 6 lost/retired incumbents (PA-3 Evans, IL-2 Kelly, IL-4 García, IL-7 Davis, IL-8 Krishnamoorthi, IL-9 Schakowsky) ABSENT from active field; certified nominees present.
- **D-02** — minor-line candidates seeded: PA-10 Harman + Long, PA-13 Thomas, IL-2 Banks.
- **USHC2-04** — every new candidate (new external_id band) has a politician_images row; `_img_skip` honest-skip pins.
- **USHC2-05a** — 0 unsourced stance rows for the in-scope set.
- **USHC2-05b** — each in-scope candidate ≥1 sourced federal stance OR pinned whole-record skip (`_stance_skip`).

## Key encodings
- **D-01 symmetry:** BOTH PA and IL incumbents are all-partial → EXCLUDED from the stance/headshot in-scope set (`_new_cands` = new external_id band only: PA −429999..−420000, IL −179999..−170000). Their pre-existing partial coverage cannot false-fail.
- **Per-state scoping:** every query scoped via `NATIONAL_LOWER + substr(geo_id,1,2) IN ('42','17')` within the named PA/IL elections — no cross-state count.
- **Write-free:** only `CREATE TEMP TABLE … ON COMMIT DROP`; verify grep confirms no DELETE/UPDATE/INSERT INTO essentials|inform.
- **143 honest-skip lesson:** `_stance_skip` (UUID) and `_img_skip` (external_id) are TEMP tables (empty now), pinned with explicit ORDER BY when populated.

## How later waves invoke it mid-wave
`cd /c/EV-Accounts/backend && set -a && source .env && set +a && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/155-verify.sql`

## TODO pins added by later waves (the 150 model)
- **155-04:** add the IL-4 (geo 1704) certified-general D-nominee winner row to `_winners` (154 listed the 7-name primary field; certified general re-confirmed in 155-04).
- **155-05/06:** populate `_img_skip` with headshot honest-skips (external_id + reason, ORDER BY external_id).
- **155-07/08:** populate `_stance_skip` with whole-record stance honest-skips (UUID + reason, ORDER BY politician_id).

## Self-test (pre-seed)
Runs read-only against prod; parses + executes, scope sanity PASSES (17 PA + 17 IL races found), then fails at USHC2-03a (34 races, 0 active candidates) — the documented expected pre-seed state. Goes green after Waves 2–3.
