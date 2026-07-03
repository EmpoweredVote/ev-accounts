---
phase: 151-fl-candidate-seeding-provisional-qualified-field
plan: 01
wave: 1
status: complete
requirements: [USHC-03]
---

# 151-01 SUMMARY — FL election + FL-20 office + 28 provisional races

## Outcome
Migration `1115_seed_fl_2026_house_elections_races.sql` applied to prod (`kxsdzaojfaibhuzmclfq`). Inserted **1 election + 1 FL-20 office + 28 PROVISIONAL races**. Verification passed; idempotent on re-run (0 additional rows).

## Key IDs (for Wave 2)
- **FL election UUID:** `1c868ba1-3169-4f0a-84a2-f41b349ef313` (`FL 2026 Statewide General`, date 2026-11-03, general/state/FL)
- **New FL-20 office UUID:** `5dd1387d-f8c9-4583-aaa3-09ab2ed538ba` (geo 1220 NATIONAL_LOWER, title `U.S. Representative`, politician_id NULL, is_vacant=true)
- **Chamber used:** `c2facc31-7b13-428c-b7b9-32d0d3b95f76` (`U.S. House of Representatives`), resolved by **exact name** (the planned `ILIKE 'U.S. House%'` was ambiguous — also matches `U.S. House of Representatives - Indiana Nth ...` rows; corrected to exact-name match).

## Deviations from plan (both schema-driven, verified live)
1. `essentials.elections.election_date` is a **`date`** column, not timestamptz — used `'2026-11-03'::date` (plan draft had `'...T08:00:00Z'::timestamptz`). CA template row confirmed date-only.
2. Chamber lookup changed from `ILIKE 'U.S. House%'` to **exact** `name = 'U.S. House of Representatives'` (returns exactly 1; ILIKE matched multiple Indiana-specific chambers).

## Verification (passed)
- 1 `FL 2026 Statewide General` election.
- 1 FL-20 office (geo 1220), politician_id NULL.
- 28 races on FL NATIONAL_LOWER offices, 0 null office_id, 28 distinct geos, all 28 `description LIKE 'PROVISIONAL:%'`.
- Re-run: `INSERT 0 0` × 3 (election, office, races) — idempotency proven.

## Notes for downstream
- All 28 FL House districts (geo 1201..1228) now carry exactly 1 provisional race; FL-20 race now links to the new office (non-null office_id). No `race_candidates` yet (Wave 2 / 151-03).
- `races.primary_party` left NULL (D-05 antipartisan invariant); provisional marker lives in `description` (D-04) — Phase 153 flips it on prune.
