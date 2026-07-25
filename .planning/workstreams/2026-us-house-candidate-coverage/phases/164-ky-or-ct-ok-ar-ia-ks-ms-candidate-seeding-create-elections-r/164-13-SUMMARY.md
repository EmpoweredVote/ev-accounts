---
phase: 164-ky-or-ct-ok-ar-ia-ks-ms-candidate-seeding-create-elections-r
plan: 13
status: complete
completed: 2026-07-06
requirements: [USHC3-02, USHC3-03, USHC3-04, USHC3-05]
---

# 164-13 SUMMARY — Phase-closing 38-district mini-gate

## Result — BOTH ARTIFACTS GREEN against prod
- **`backend/scripts/164-verify.sql`** — 12 assertions PASS (psql exit 0, no RAISE EXCEPTION).
- **`backend/scripts/164-coordinate-smoke.ts`** — 8/8 positive samples PASS (MIN_DISTRICTS=8).

## 164-verify.sql assertions (all PASS)
1. **SCOPE**: KY 6 + OR 6 + CT 5 + OK 5 + AR 4 + IA 4 + KS 4 + MS 4 = **38** NATIONAL_LOWER races.
2. **NULLOFFICE**: 0 of 38 races have NULL office_id.
3. **NULLPID**: 0 active candidates with NULL politician_id.
4. **DUPNAME**: 0 duplicate full_name within any state.
5. **PARTY**: race_candidates has no party column (antipartisan invariant).
6. **OPEN-SEAT** (NEW): Massie (4d92b909), Barr (164fb70e), Hern (96e589b9), Hinson (91aa37bf), Feenstra (c25acca0) each have **0 active race_candidates rows**.
7. **OR-REUSE** (NEW): the 6 OR races are exactly the pre-existing UUIDs (8dfd6e35/504a156a/61297fac/c5023da0/17a4b696/dd25e913), **no new OR general authored**, exactly 1 rc per (race_id, politician_id).
8. **PROVISIONAL** (NEW): CT (5) + KS (4) races carry `PROVISIONAL:`; the 6 decided states do not.
9. **COLLISION-BAND** (NEW): D-04 sub-band floors honored — KY-1 ≥200, **OK-1 ≥44** (in-century fix: the audit's 200 would have collided with OK-3 seq1), OR-1 ≥14, KS-1 ≥3, KS-2 ≥10.
10. **HEADSHOT**: every active new candidate has an image or a pinned honest-skip (**85 pinned**, 9 uploaded).
11. **UNSOURCED**: 0 unsourced stance rows across the in-scope set.
12. **COVERAGE**: every new candidate has ≥1 sourced stance or a pinned whole-record skip (**13 pinned**).

## Coordinate smoke (8/8 PASS)
KY-4 (4 active/4 chal), OR-4 (3/2), CT-1 (5/4), OK-1 (2/2), AR-2 (2/1), IA-2 (4/4), KS-4 (11/10), MS-2 (3/2). Each surfaces exactly 1 challenger-inclusive House race, 0 null pid. All PostGIS via `public.` prefix.

## Phase-164 totals
- **38 districts / 8 states.** 94 new candidate records + races (migs 1231-1245). Elections: 7 new state generals + OR reuse of `OR 2026 General`.
- Stances: **~454 sourced answers across 76 stance-covered candidates, 0 unsourced**; 13 whole-record stance skips; 85 headshot honest-skips; 9 headshots uploaded.
- Zero redistricting → no withholding (unlike 162/163).

## STANDING INVARIANTS for Phase 166 (consolidated 178-district gate) to inherit
- **OPEN-SEAT**: Massie/Barr/Hern/Hinson/Feenstra must remain 0-active-rows.
- **OR-REUSE**: OR's 6 races stay on the pre-existing UUIDs; no new OR general.
- (Plus the 13 stance + 85 headshot pins carry forward.)

## Files (committed — backend/scripts is tracked)
- `backend/scripts/164-verify.sql`
- `backend/scripts/164-coordinate-smoke.ts`

## Self-Check: PASSED
Both gate artifacts green against prod. Phase 164 proven end-to-end (USHC3-02/03/04/05, 38 districts).
