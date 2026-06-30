---
phase: 151-fl-candidate-seeding-provisional-qualified-field
plan: 06
wave: 4
status: complete
requirements: [USHC-02, USHC-03, USHC-04, USHC-05]
---

# 151-06 SUMMARY — Phase 151 end-to-end gate + FL coordinate smoke

## Outcome
Phase 151 verified end-to-end. `151-verify.sql` runs **all 13 assertions PASS, psql exit 0** read-only against prod; new `151-coordinate-smoke.ts` surfaces **4/4 FL House districts** with their full provisional field. Phase 151 is closeable.

## Gate result (read-only prod, exit 0, write-free)
```
PASS USHC-03a: all 28 FL House races have >=1 active candidate (1 race <2 — FL-10 uncontested)
PASS USHC-03b: 0 active FL House candidates with NULL politician_id
PASS USHC-03c: FL-20 vacant office present (NULL pid), its race links
PASS D-04: all 28 FL House races marked PROVISIONAL
PASS USHC-02a: 0 duplicate full_name among active FL candidates
PASS USHC-02b: 3 cross-district reuse incumbents active in new seat
PASS USHC-02c: Cherfilus-McCormick active FL-20 as NEW record
PASS D-05: retired/redistricted incumbents absent in old seat
PASS in-scope: all 17 independents resolved
PASS USHC-04: every in-scope independent has a headshot or pinned skip
PASS USHC-05a: 0 unsourced stance rows for the 17 independents
PASS USHC-05b: every in-scope independent >=1 sourced stance or pinned skip
ALL ASSERTIONS PASSED (USHC-02/03/04/05 + D-01/02/03/04/05)
```

## Coordinate smoke result (exit 0)
```
PASS FL 1201: 1 House race — 5 active, 4 challenger(s), 0 null pid
PASS FL 1210: 1 House race — 1 active, 0 challenger(s), 0 null pid [uncontested]
PASS FL 1219: 1 House race — 14 active, 14 challenger(s), 0 null pid
PASS FL 1220: 1 House race — 10 active, 10 challenger(s), 0 null pid [incl. Wasserman Schultz + Cherfilus-McCormick]
COORDINATE SMOKE GREEN: 4/4 FL House districts
```
FL-10 (Frost) uncontested handled via minActive=1 with the challenger check gated on minActive>=2 (the plan-checker's Note A — kept correct). FL-20 new open-seat office surfaces with the redistricted reuse incumbent + the NEW Cherfilus record.

## Final Phase-151 tallies (the FL provisional half of the Phase 152 full-144 gate input)
- **28 FL House races** (all PROVISIONAL), 1 election + 1 new FL-20 office.
- **181 active candidates** (full qualified field), **158 new records** + 23 reuse (20 home incumbents + 3 cross-district), 0 null politician_id, 0 dup full_name.
- **Stance in-scope = 17 independent/NPA new candidates** (Nov-final): 6 stanced (36 sourced answers, 0 unsourced), 11 whole-record honest-skips (pinned by UUID).
- **Headshots:** 17/17 honest-skip (no free-license portrait), pinned by external_id.
- 27 partial incumbents + 138 partisan new candidates: records only, stances/headshots **deferred to Phase 153** (post-Aug-18 prune).

## Verification
- Gate: `psql -v ON_ERROR_STOP=1 -f scripts/151-verify.sql` → 13 PASS, exit 0, write-free.
- Smoke: `node --import tsx scripts/151-coordinate-smoke.ts` → 4/4, exit 0.
- No assertion relaxed; no DB writes from gate/smoke.

## Artifacts
- `backend/scripts/151-coordinate-smoke.ts` (new, read-only).
- `backend/scripts/151-verify.sql` (honest-skip pins finalized in 151-04/05).
