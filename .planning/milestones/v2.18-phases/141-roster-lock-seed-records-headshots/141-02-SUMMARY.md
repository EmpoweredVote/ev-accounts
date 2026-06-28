# 141-02 SUMMARY — Indiana SoS + Treasurer re-link + role_canonical

**Status:** ✅ Complete
**Requirements:** SEXR-02, SEXR-03
**Migration applied to prod:** 950 (planned 947, +3 renumber)

## What was built
Migration 950 closes Indiana's two Big-5 record gaps and tags all 5 IN in-scope offices.

- **New labeled districts:** `Indiana Secretary of State` + `Indiana Treasurer`, `state='IN'`, `geo_id='18'`.
- **New offices** linking the EXISTING politicians Diego Morales (ext 642977, SoS) and Daniel Elliott (ext 688298, Treasurer) to those districts, with `role_canonical='secretary_of_state'`/`'treasurer'`, titles preserved (D-07). Reused the chamber each politician's existing shared-"Indiana" office already uses (no new chambers/governments created).
- **role_canonical backfill** on existing IN Gov (499460) / LtGov (499415) / AG (499453) offices.

## IN-specific traps handled
- **Pitfall 4 (22 duplicate "State of Indiana" governments):** all 22 are referenced and the 5 existing IN Big-5 offices each use a *different* government_id — there is NO single canonical government. Resolved by **not creating any new chamber/government** and instead reusing the existing chamber via the politician's current office row. Preflight keyed on politician existence, never `COUNT(*)=1` on government name.
- **Pitfall 2 (dual-office double-display):** legacy shared-"Indiana" offices left untouched (D-09). Feed de-dupes by politician id (`SELECT DISTINCT ON (COALESCE(p.id,o.id))` in essentialsService) → the new labeled office does not double-display.

## Verification
- Applied clean: 2 districts + 2 offices inserted, 3 role backfills (Gov/LtGov/AG); POST assertions all passed (5 IN Big-5 roles, 2 labeled geo_id=18 districts, 1 SoS + 1 treasurer office, Morales/Elliott count=2 no duplicates).
- **Idempotent:** re-run = all INSERT 0 0 / UPDATE 0, NOTICE OK, COMMIT.

## Deviations
- Migration renumber 947→950 (+3, same as 141-01).
- Reused existing chambers rather than creating new ones — the 22-government duplication made "the canonical government" undefined; reusing the politician's own existing chamber is lower-risk and still produces correctly-labeled geo_id=18 districts. Achieves SEXR-02/03 intent exactly.

## Self-Check: PASSED
