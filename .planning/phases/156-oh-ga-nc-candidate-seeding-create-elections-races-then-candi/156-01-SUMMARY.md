# 156-01 SUMMARY — OH/GA/NC elections + races scaffold

**Status:** COMPLETE ✅
**Migration:** `backend/migrations/1127_seed_oh_ga_nc_2026_house_elections_races.sql`

## What was built
Idempotent BEGIN/COMMIT migration that:
1. Created the GA-13 (geo 1313) NATIONAL_LOWER vacancy **office** (FL-20 / mig-1115 pattern) — the district row already existed; only the office was missing. `is_vacant=true`, `politician_id=NULL`, no ghost incumbent, no incumbent race_candidates row.
2. Created 3 elections (`election_date=2026-11-03`, `election_type=general`, `jurisdiction_level=state`).
3. Created 15 OH + 14 GA (incl. GA-13) + 14 NC races on each district's existing `U.S. House of Representatives` office (chamber resolved by EXACT name), `primary_party=NULL`, `seats=1`.

## Key facts for Wave 2 (156-03/04/05)
| State | Election UUID |
|-------|---------------|
| OH 2026 Statewide General | `32657ce8-8606-420b-8782-ca2c7f01c5ae` |
| GA 2026 Statewide General | `e4d22b2e-2c87-4fec-9b5a-c0680e99d2c7` |
| NC 2026 Statewide General | `12e0bce3-d4c3-4e09-ba5d-18e8bc68be5e` |

- **GA-13 office CREATED** (was absent): office id `0d031c4f-07d4-4adb-8839-2bf25f5c533e` (district geo 1313, is_vacant=true, no incumbent). Clark/Chavez wire as active non-incumbent candidates in 156-04; NO incumbent-absent pin in the gate.
- All 42 other OH/GA/NC House offices pre-existed; all 43 races resolve to a non-null office_id.
- geo_id → cd: OH 3901..3915 → 1..15; GA 1301..1314 → 1..14; NC 3701..3714 → 1..14.

## Verification
- Plan automated check: `OK: 3 elections, OH 15, GA 14, NC 14 races, 0 null office_id`.
- Idempotency: re-run inserted 0 rows across all 7 statements (all `INSERT 0 0`).
- No geo_id failed office lookup; no non-vacancy office/district rows created.

## Pre-check evidence (live prod, pre-seed)
- GA-13 office count = 0 → created here.
- OH 15 / NC 14 / GA 13 offices existed (GA-13 was the sole gap).
- 0 pre-existing OH/GA/NC 2026 elections; 0 pre-existing races on those offices.
- All 42 existing offices on chamber `U.S. House of Representatives`.
