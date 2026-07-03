---
phase: 150-tx-ny-candidate-seeding-create-races-then-candidates
plan: 12
wave: 4
status: complete
requirements: [USHC-02, USHC-03, USHC-04, USHC-05]
---

# 150-12 SUMMARY — Phase 150 end-to-end gate + coordinate smoke (TX + NY)

## Outcome

Phase 150 verified end-to-end. The consolidated `150-verify.sql` gate runs **all assertions PASS, psql exit 0** read-only against prod, and the new `150-coordinate-smoke.ts` surfaces the full candidate field for **3 TX + 4 NY** in-district House coordinates with the lost-primary winner present and lost incumbent absent. Phase 150 is closeable.

## What shipped

- **`backend/scripts/150-coordinate-smoke.ts`** (new, read-only) — clones the validated 149 smoke and parameterizes for two states. Per state: resolves the named election (`TX/NY 2026 Statewide General`), computes an interior centroid per sample district via `ST_PointOnSurface`, runs the `getElectionsByCoordinate` Part-A join (geofence `ST_Covers` → district → office → race, `NATIONAL_LOWER`, geo prefix `48`/`36`), and asserts ≥2 active candidates incl. ≥1 challenger, 0 null politician_id, exactly 1 race matched. NY-13/NY-21 require ≥3 active. Lost-primary seats (TX-2 geo 4802, NY-10 geo 3610, NY-13 geo 3613) additionally assert the WINNER is active by name and the lost incumbent is ABSENT.
- **`backend/scripts/150-verify.sql`** — no edits needed; honest-skip + reuse pins were already complete from waves 150-03..11. Confirmed write-free and per-state-scoped.

## Gate result (read-only prod, exit 0)

```
PASS USHC-03a: all 64 TX/NY House races have >=1 active candidate (0 race(s) have <2)
PASS USHC-03b: 0 active TX/NY House candidates with NULL politician_id
PASS USHC-02a: 0 duplicate full_name within TX and within NY (D-03)
PASS USHC-02c: all 47 pinned renominated/cross-district incumbents reuse their 148 pid
PASS D-05: Crenshaw/Goldman/Espaillat absent; Toth/Lander/Avila Chevalier active
PASS D-02: NY-13 Cohen + NY-21 Smullen seeded as active (minor lines not dropped)
PASS USHC-04: every newly-seeded TX/NY candidate has a politician_images row
PASS USHC-05a: 0 unsourced stance rows for the in-scope TX/NY candidate set
PASS USHC-05b: every in-scope candidate has >=1 sourced federal stance or is a pinned whole-record honest-skip
ALL ASSERTIONS PASSED (USHC-02/03/04/05 + D-01/02/03/05)
```

## Coordinate smoke result (exit 0)

```
PASS TX 4802: 2 active, 2 challenger(s), 0 null pid [winner=Steve Toth, Dan Crenshaw absent]
PASS TX 4823: 2 active, 2 challenger(s), 0 null pid   (TX-23 open seat)
PASS TX 4838: 2 active, 2 challenger(s), 0 null pid
PASS NY 3601: 2 active, 1 challenger(s), 0 null pid
PASS NY 3610: 2 active, 2 challenger(s), 0 null pid [winner=Brad Lander, Daniel S. Goldman absent]
PASS NY 3613: 3 active, 3 challenger(s), 0 null pid [winner=Darializa Avila Chevalier, Adriano Espaillat absent]
PASS NY 3621: 3 active, 3 challenger(s), 0 null pid
COORDINATE SMOKE GREEN: 7 TX+NY House districts surface their full field
```

## Final tallies (TX + NY, this is the TX+NY half of the Phase 152 full-144 gate input)

| Metric | TX | NY |
|--------|----|----|
| House races (districts) | 38 | 26 |
| Active candidates total | 76 | 54 |
| Newly-seeded candidate records (new external_id band) | 48 | 33 |

- **New candidate records total: 81** (48 TX + 33 NY).
- **Stance in-scope set: 109** = all 76 active TX (TX incumbents were all zero-stance) + 33 new NY (NY partial incumbents + AOC EXCLUDED per D-01 asymmetry).
- **Stanced: 90** in-scope candidates carry ≥1 sourced federal stance; **412 sourced answers**, **0 unsourced**.
- **Whole-record stance honest-skips: 19** (pinned by exact UUID with explicit ORDER BY in `_stance_skip`): 3 from 150-07 (TX-1/18/29), 1 from 150-10 (Eric Flores TX-34), 15 from 150-11 (NY new challengers + minor-line). All genuinely no-record (no Candidate Connection survey, no fetchable campaign-site quote; party-inference refused — chairs-not-polarity).
- **Headshot honest-skips: 70** pinned by external_id (43 TX from 150-05, 27 NY from 150-06); 11 auto-imaged (5 TX, 6 NY).
- **D-05**: lost-primary incumbents Crenshaw (TX-2) / Goldman (NY-10) / Espaillat (NY-13) absent from active field; winners Toth / Lander / Avila Chevalier active.
- **D-02**: fusion minor-line candidates NY-13 Bob Cohen + NY-21 Robert Smullen seeded as active.

## Verification

- Gate: `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/150-verify.sql` → all PASS, exit 0, write-free.
- Smoke: `node --import tsx scripts/150-coordinate-smoke.ts` → 7/7 districts green, exit 0.
- No assertion was relaxed to force green (T-150-33); no DB writes (data already live from prior waves).
