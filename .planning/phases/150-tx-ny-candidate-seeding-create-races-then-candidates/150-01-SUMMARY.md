# 150-01 SUMMARY — TX/NY 2026 House elections + races scaffold

**Status:** ✅ Complete
**Wave:** 1
**Migration:** `backend/migrations/1109_seed_tx_ny_2026_house_elections_races.sql`

## What was built

Authored + applied the `essentials.elections` + `essentials.races` scaffold that TX/NY require before any candidates can be wired (the one structural addition vs CA, which was turnkey).

- **2 elections** inserted, mirroring the CA 2026 Statewide General shape (`election_type='general'`, `jurisdiction_level='state'`, `election_date='2026-11-03T08:00:00.000Z'`).
- **64 races** inserted (38 TX geo_id 4801..4838 + 26 NY geo_id 3601..3626), each `office_id` resolved to the existing NATIONAL_LOWER U.S. Representative office by `districts.geo_id`. `primary_party=NULL`, `seats=1`. No `race_candidates` yet.
- 0 races with NULL office_id; no offices/districts rows created.

## Election UUIDs (for Wave 2 — 150-03 TX, 150-04 NY)

| State | Election UUID |
|-------|---------------|
| TX | `783b7506-dd52-47a1-a85a-9ffc363f8a04` |
| NY | `80a2b03d-f583-4156-a272-d51abbda0b0a` |

## Verification

- Pre-flight live check: 1:1 office per TX/NY district (0 districts with ≠1 office), 0 pre-existing TX/NY House races.
- In-migration `DO $$` assertions passed (2 elections / 38 TX / 26 NY / 0 null office_id).
- Post-apply node/pg verification (plan `<automated>` block): **OK**.
- TX-23 (4823, vacant seat) race created — office exists despite vacancy, per plan.

## Deviations

None. Used `'2026-11-03T08:00:00.000Z'::timestamptz` (CA's exact stored instant) rather than bare `'2026-11-03'::timestamptz` to mirror CA exactly — date portion is 2026-11-03 either way.

## Idempotency

NOT EXISTS guards on `(name)` for elections and `(election_id, office_id)` for races. Re-run inserts 0 rows (no DB unique constraint; application-enforced).
