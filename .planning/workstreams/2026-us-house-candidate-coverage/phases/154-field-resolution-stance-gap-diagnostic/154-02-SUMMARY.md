---
phase: 154-field-resolution-stance-gap-diagnostic
plan: 02
status: complete
completed: 2026-06-30
requirements: [USHC2-01]
---

# 154-02 SUMMARY — Field Table + Validator + Baseline Gate

## What was built

- `.planning/phases/154-field-resolution-stance-gap-diagnostic/154-field-table.csv` — 113-row, 15-column Nov-3 general-ballot field table. 89 `decided` (PA/IL/OH/GA/NC/NJ) + 24 `pending-primary (Aug-4)` (MI 13 + VA 11). Decided fields resolved from official/results sources (Wikipedia state results boxes + Ballotpedia per-race, primary-results-driven), one cited `source_url` per row.
- `.planning/phases/154-field-resolution-stance-gap-diagnostic/154-FIELD-TABLE.md` — human-readable summary (per-state counts, the 12 non-incumbent-nominee districts, the four special seats, stance-gap note, the VA pre-scaffold finding).
- `backend/scripts/diag-154-validate-field-table.py` — read-only CSV-shape gate (113 rows; per-state counts; 89/24 field_status partition; source_url + nominee_status present; non-exempt incumbent_pid present; VA existing_race_id UUID-shaped / 102 others blank). Exit 0.
- `backend/scripts/154-verify.sql` — write-free pre-seeding DB baseline gate (A1 district counts=113; A2 candidate/race-scaffold invariant; A3 holder invariant). `ALL ASSERTIONS PASSED`, psql exit 0. Asserts NOTHING about MI/VA nominees.

## Field resolution — research (3-concurrent web agents per state)

All 6 decided states' 2026 primaries are held; fields resolved with HIGH confidence. **12 decided-state districts where the sitting incumbent is NOT the 2026 nominee** (the lost-incumbent/retirement trap — resolved from results, never incumbency, D-04):

| District | Status | Sitting incumbent (not running) | 2026 nominees (new records) |
|---|---|---|---|
| PA-3 | retired | Dwight Evans | Chris Rabb |
| IL-2 | retired | Robin Kelly (→ Senate) | Donna Miller / Michael Noack / Ashley Banks |
| IL-4 | retired | Chuy García | Patty Garcia + 6 (large indie field) |
| IL-7 | retired | Danny Davis | La Shawn Ford / Chad Koppie |
| IL-8 | retired | Raja Krishnamoorthi (→ Senate) | Melissa Bean / Jennifer Davis |
| IL-9 | retired | Jan Schakowsky | Daniel Biss / John Elleson |
| GA-1 | open-seat-vacancy | Buddy Carter (→ Senate) | Jim Kingston / Amanda Hollowell |
| GA-10 | open-seat-vacancy | Mike Collins (→ Senate) | Houston Gaines / Pamela DeLancy |
| GA-11 | retired | Barry Loudermilk | John Cowan / Chris Harden |
| GA-13 | open-seat-vacancy | VACANT (Scott deceased) | Jasmine Clark / Jonathan Chavez |
| NJ-11 | special-seated | (Mejia already seated) | Joe Hathaway |
| NJ-12 | retired | Bonnie Watson Coleman | Adam Hamawy / Gregg Mele |

Decided-state new-record counts (feed Phases 155/156/157): **PA 20, IL 28, OH 19, GA 18, NC 25, NJ 15**. MI/VA new-record counts deferred to Phase 159 (Aug-4 primaries).

## Two material baseline findings (overrides for downstream phases)

1. **VA's 11 House races are ALREADY scaffolded** in the DB (0 candidates each) under the existing "2026 Virginia General Election" (election_date 2026-11-03). CONTEXT assumed no pre-seeded races. The field table pins all 11 VA `existing_race_id`s + `target_election`; **Phase 159 must REUSE these races** (wire `race_candidates` onto them), not create duplicates. The other 102 rows (PA/IL/OH/GA/NC/NJ/MI) have no pre-seeded race → blank.
2. **Special seats are mostly already current** (Wave-1 finding, carried in): GA-14 Fuller / NJ-11 Mejia / VA-11 Walkinshaw are already correctly-seeded incumbents — only GA-13 is a true vacancy.

## Deviations from plan (driven by live-DB reality, not scope reduction)

- Plan Task 2/3 assumed `existing_race_id` blank for ALL 113 + the verify gate asserting **0** pre-seeded races. The live DB has **11 pre-scaffolded VA races** → (a) field table populates VA `existing_race_id` (mirrors Phase 148's CA pre-seeded-race handling), (b) validator requires VA UUID / others blank, (c) gate A2 asserts the real invariant: **0 race_candidates** on any Wave-2 House race + the 11-VA / 0-non-VA race split. This is a more accurate baseline, not a relaxation.
- Plan expected 0-holder set `{1313,3411,5111}`; live DB shows only `{1313}` (GA-13). Gate A3 encodes the real Wave-1 result `{1313}`.

## Verification

- Task 1: `csv.DictReader` → 113 rows / 89 decided / 24 pending; 15 cols; all source_url+nominee_status; 0 non-exempt blank pid.
- Task 2: `python3 scripts/diag-154-validate-field-table.py` → PASS, exit 0.
- Task 3: `psql -v ON_ERROR_STOP=1 -f scripts/154-verify.sql` → A1/A2/A3 PASS, `ALL ASSERTIONS PASSED (154 baseline)`, exit 0. No MI/VA nominee assertion (`grep` confirms gate references race_candidates only for the 0-seeded invariant, not MI/VA nominee existence).

## Self-Check: PASSED

## Key files
- created: `154-field-table.csv`, `154-FIELD-TABLE.md`, `backend/scripts/diag-154-validate-field-table.py`, `backend/scripts/154-verify.sql`
