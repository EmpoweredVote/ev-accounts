---
phase: 158-coordinate-verification-gate
plan: 01
type: execute
status: complete
requirements: [USHC2-06]
commit: 7ac3b738
---

# Phase 158-01 SUMMARY — Coordinate Verification Gate (89 decided-state districts)

## What was built

Two write-free scripts, both green against prod `.env` (exit 0):

1. **`backend/scripts/158-verify.sql`** — consolidated read-only milestone gate modeled
   structurally on `152-verify.sql`, re-scoped from 4 states/144 to the 6 decided Wave-2
   states / 89 districts. One `_house` TEMP TABLE (`ON COMMIT DROP`), six election ids
   resolved by exact name (RAISE EXCEPTION on any NULL), 8 labeled assertions in one DO block.
2. **`backend/scripts/158-coordinate-smoke.ts`** — 6-state ST_Covers surfacing smoke modeled
   on `152-coordinate-smoke.ts`, extended from 4 to 6 states with the Pitfall-5 challenger-present
   guard on every sample.

## Gate results — 158-verify.sql (all 8 PASS, exit 0)

| Assertion | Result |
|-----------|--------|
| USHC2-06-SCOPE | PA 17 + IL 17 + OH 15 + GA 14 + NC 14 + NJ 12 = **89** distinct NATIONAL_LOWER races |
| USHC2-06-ACTIVE | all 89 have ≥1 active; **2** races <2-active (NJ-8 Menendez / PA-3 Rabb) reported as NOTICE allowance, not failure |
| USHC2-06-NULLPID | 0 active candidates with NULL politician_id |
| USHC2-06-DUPNAME | 0 duplicate full_name within any state |
| USHC2-06-DUPINCUMBENT | 0 politician_id active in 2+ distinct races (v2.4 two-Andy-Barrs invariant) |
| USHC2-06-UNSOURCED | 0 unsourced answer rows (existence check, asymmetry-safe — mirrors 152) |
| USHC2-06-VACANCY | GA-13 Clark+Chavez active/no-incumbent; NJ-12 Watson Coleman 0-active + Hamawy+Mele active; NJ-8 exactly 1 active Menendez (incumbent) |
| USHC2-06-PARTY | race_candidates has no party/party_affiliation column (antipartisan structural invariant) |

Final stdout line: `ALL ASSERTIONS PASSED (USHC2-06-SCOPE / ... / USHC2-06-PARTY)`.

## Smoke results — 158-coordinate-smoke.ts (COORDINATE SMOKE GREEN 6/6, exit 0)

| State | geoId | active / challengers / null_pid |
|-------|-------|--------------------------------|
| PA-1  | 4201  | 2 / 1 / 0 |
| IL-1  | 1701  | 2 / 1 / 0 |
| OH-1  | 3901  | 3 / 2 / 0 |
| GA-5  | 1305  | 2 / 1 / 0 |
| NC-6  | 3706  | 2 / 1 / 0 |
| NJ-6  | 3406  | 2 / 1 / 0 |

Each sample: exactly 1 House race surfaced, ≥2 active, ≥1 challenger (Pitfall-5 two-path
guard exercised), 0 null pid. MIN_DISTRICTS=6 met.

## Write-free confirmation

Both files SELECT-only (SQL DDL limited to `CREATE TEMP TABLE ... ON COMMIT DROP`).
Grep for `INSERT/UPDATE/DELETE/--commit` finds only a comment line — no write DML. No
migration, no deploy. Per-candidate granular stance/headshot skip pins remain OWNED by
155/156/157-verify.sql — this gate asserts milestone invariants fresh, does not re-pin.

## Scope note

MI (13) + VA (11) are seeded and asserted separately by the **date-gated Phase 159**
(both primaries Aug 4, 2026). The full 113-district v2.21 milestone closes as the **union**
of this 89-district gate + Phase 159's MI+VA gate. This gate references neither MI nor VA.

## Commit

`7ac3b738` — test(158): consolidated 89-district Wave-2 coordinate verification gate (USHC2-06). Data/planning + read-only scripts only; no deploy needed.
