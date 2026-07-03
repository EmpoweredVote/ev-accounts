# 150-04 SUMMARY — NY 2026 House race_candidates

**Status:** ✅ Complete
**Wave:** 2
**Migration:** `backend/migrations/1111_seed_ny_2026_house_candidates.sql`
**Reconciliation:** `backend/data/seed-ny-2026-house/150-04-ny-reconciliation.csv` (54 rows)

## Result

- **33 NEW** politician records (band `-(3610000+cd*100+seq)`, -3610101..-3612601; band verified empty) + **54 race_candidates** (33 new + 21 reuse) on all 26 NY races.
- Verification (plan check + in-migration assertions): 26 races, 54 active, 0 NULL pid, 0 dup full_name within NY, Goldman/Espaillat absent, Lander/Cohen/Smullen active. **NY OK.**
- Gate post-Wave-2: **USHC-03a/b, USHC-02a/c, D-05, D-02 all PASS.**

## D-05 lost-primary + retired resolutions

| District | Incumbent (NO active row) | Active winner(s) |
|----------|---------------------------|------------------|
| NY-10 | Goldman (c7f357ce, lost) | Brad Lander (NEW -3611001), Jennifer Moore |
| NY-13 | Espaillat (26636234, lost) | Darializa Avila Chevalier (NEW -3611301), Jomo M. Williams, **Bob Cohen (WF)** |
| NY-7 | Velázquez (retired) | Claire Valdez, Melvin Rivera |
| NY-12 | Nadler (retired) | Micah Lasher, Caroline Shinkle |
| NY-21 | Stefanik (retired) | Anthony Constantino, Blake Gendebien, **Robert Smullen (Conservative)** |

D-02 minor lines seeded: NY-13 Bob Cohen + NY-21 Robert Smullen (3-candidate races). All 33 new names live-confirmed 0-match (no dedup reuse needed — clean, unlike TX's Barrios/Toth/Casar). 21 renominated incumbents reused their 148 pids.

## Stance scope (for 150-11)

In-scope = **only the 33 NEW NY candidates** (D-01: NY's 25 partial incumbents + NY-14 AOC are LEFT AS-IS this phase, NOT topped up). The gate's `_in_scope` NY branch is the new band only.

## New-candidate external_id list (33) — for headshots (150-06) + stances (150-11)

-3610101 Chris Gallant NY-1 · -3610201 Patrick Halpin NY-2 · -3610301 Mike LiPetri NY-3 · -3610401 Jeanine Driscoll NY-4 · -3610501 George Marsh NY-5 · -3610601 Joseph Chou NY-6 · -3610701 Claire Valdez NY-7 · -3610702 Melvin Rivera NY-7 · -3610801 Lewis Mizrahi NY-8 · -3610901 Joel Anabilah-Azumah NY-9 · -3611001 Brad Lander NY-10 · -3611002 Jennifer Moore NY-10 · -3611101 Michael DeCillis NY-11 · -3611201 Micah Lasher NY-12 · -3611202 Caroline Shinkle NY-12 · -3611301 Darializa Avila Chevalier NY-13 · -3611302 Jomo M. Williams NY-13 · -3611303 Bob Cohen NY-13 · -3611401 Diamant Hysenaj NY-14 · -3611501 Stylo Sapaskis NY-15 · -3611601 Joseph Cinquemani NY-16 · -3611701 Cait Conley NY-17 · -3611801 Jacqueline Auringer NY-18 · -3611901 Peter Oberacker NY-19 · -3612001 Ralph Ambrosio NY-20 · -3612101 Anthony Constantino NY-21 · -3612102 Blake Gendebien NY-21 · -3612103 Robert Smullen NY-21 · -3612201 Kailee Buller NY-22 · -3612301 Aaron Gies NY-23 · -3612401 Alissa Ellman NY-24 · -3612501 Virginia McIntyre NY-25 · -3612601 Dennis Hannon NY-26

## Headshot scope (150-06)

All 33 NY new records lack a politician_images row (USHC-04 fails for them pre-Wave-4, expected). Combined with 48 TX new = **81 new candidates needing headshots** across 150-05 (TX) + 150-06 (NY).
