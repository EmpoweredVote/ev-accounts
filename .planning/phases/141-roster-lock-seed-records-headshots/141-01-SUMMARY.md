# 141-01 SUMMARY — Gate + role_canonical backfill (8 states) + UT external_id fix

**Status:** ✅ Complete
**Requirements:** SEXR-01, SEXR-03
**Migration applied to prod (kxsdzaojfaibhuzmclfq):** 949 (renumbered from planned 946 — 946–948 taken by pasadena migrations)

## What was built

### Task 1 — Phase gate `backend/scripts/verify-phase-141.sql`
Read-only labeled-assertion gate mirroring `verify-phase-132-140.sql`. Six labeled `RAISE EXCEPTION` blocks:
- **SEXR-01** — 209 distinct in-scope `(state, role_canonical)` STATE_EXEC pairs.
- **SEXR-02** — per-role breakdown gov=50 / lt=43 / ag=43 / sos=35 / treasurer=38.
- **SEXR-03** — no duplicated `(state, role_canonical)` pair (dual-office/double-seed guard, D-09) + no phase-labeled Big-5 district with NULL-role office.
- **SEXR-04** — every newly-seeded exec (41-state `-(fips*100000+seq)` range, excluding UT `-49000xx`, PLUS IN Morales 642977 / Elliott 688298) has a `politician_images` row. Scoped by STATE_EXEC+role join, NOT bare external_id sign.
- **D-10a** — no in-scope Big-5 district with non-uppercase state.
- **D-10b** — no in-scope Big-5 district with NULL/empty geo_id (scoped to role-bearing districts → excludes legacy shared non-Big-5 districts).

Headshot assertions reference `essentials.politician_images.url` (NOT photo_origin_url). Gate runs without syntax error; RAISEs on SEXR-01 (found 2) until seeds land — expected mid-phase.

### Task 2 — Migration 949
- **PART A (UT fix, D-08):** assigned `-4900001..-4900005` to UT's 5 STATE_EXEC politicians (Cox→1 Gov, Henderson→2 LtGov, Brown→3 AG, Cannon→4 State Auditor [non-Big-5], Oaks→5 Treasurer). Idempotent preflight: RAISEs only if a range id is held by a non-UT-exec politician.
- **PART B (role_canonical backfill, 8 states CA/MA/MD/ME/OR/TX/UT/VA):** 29 in-scope Big-5 offices tagged, scoped by politician external_id, guarded `WHERE role_canonical IS NULL`. TX Comptroller (-100205) → `treasurer` (D-01). MA SoS/Treasurer already set → no-op'd by guard.
- Indiana EXCLUDED (owned by 141-02). No INSERTs (D-09). Titles untouched (D-07).

## Verification
- Applied clean inside BEGIN/COMMIT; POST assertion fired: "29 in-scope Big-5 offices backfilled; UT external_ids fixed; TX Comptroller=treasurer".
- **Idempotent:** re-run = all 10 UPDATE 0, NOTICE OK, COMMIT.
- UT ids confirmed: -4900001 governor (Cox), -4900002 lt_governor (Henderson), -4900003 attorney_general (Brown), -4900004 NULL-role (Cannon, Auditor), -4900005 treasurer (Oaks).

## Deviations
- **Migration renumber 946→949** (+3) — 946–948 were consumed by pasadena city migrations added after planning. Plans anticipated this ("bump if taken"). The whole phase shifts +3: 141-02→950, 03→951, 04→952, 05→953, 06→954, 07→955; headshots 956–960.
- **Preflight idempotency fix** — initial Part A preflight asserted the UT ids simply didn't exist, which broke re-run. Rewrote to exempt UT's own execs. Data was already correctly committed; fix only affects re-runnability.

## Self-Check: PASSED
