# 155-04 SUMMARY — IL candidate records + race wiring

**Status:** ✅ Complete · **Date:** 2026-06-30 · **Requirements:** USHC2-02, USHC2-03

## What was done
Migration **`1119_seed_il_2026_house_candidates.sql`** applied to prod: **28 new politicians + 40 race_candidates** across all 17 IL US House races. 12 sitting incumbents REUSED (is_incumbent=true, 154 incumbent_pid); 28 new challengers/open-seat nominees. Reconciliation: `backend/data/seed-il-2026-house/155-04-il-reconciliation.csv` (40 rows).

## Verification (per-state IL-scoped)
- ✅ 17 races, 40 active race_candidates, 12 incumbents, 0 NULL politician_id, 0 duplicate full_name.
- ✅ 5 retired/Senate-run incumbents (IL-2 Kelly, IL-4 García, IL-7 Davis, IL-8 Krishnamoorthi, IL-9 Schakowsky) ABSENT from active field; certified nominees active.
- ✅ Idempotent: re-run inserted 0 rows.

## D-03 certified-general re-confirm — IL-4 suspicion RESOLVED (false alarm)
Live re-confirm (Ballotpedia + Wikipedia general-election tables, 2026-06-30) found the **IL-4 7-candidate field IS the genuine certified general**: Illinois lets independents/new-party candidates **petition directly onto the general ballot** (skipping the March primary), so the open García seat legitimately drew a 7-way general — Patty Garcia (D primary winner) + Lupe Castillo (R) + Ed Hershey (Working Class Party) + 4 independents (Church, Getty, Macías, Sigcho-Lopez). **No trimming needed.** IL-2 = Donna Miller (D) / Mike Noack (R) / Ashley Banks (Ind). Open-seat D nominees IL-7/8/9: La Shawn Ford / Melissa Bean / Daniel Biss.

## D-03 dedup result
All 28 new IL names returned **0 prior records** — including established figures Melissa Bean (former US Rep IL-8), Daniel Biss (Evanston mayor), La Shawn Ford (IL state rep), Byron Sigcho-Lopez (Chicago alderman), Donna Miller (Cook County commissioner). None pre-existed → all genuinely NEW. Mary E. Miller (IL-15 R incumbent, reused) ≠ Donna Miller (IL-2 new).

## New-candidate external_id band (for 155-06 headshots + 155-08 stances)
IL new records occupy **−170101 … −170701** (band −179999..−170000). 28 records: IL-1 Maxwell; IL-2 Miller/Noack/Banks; IL-3 Oakley; IL-4 Garcia/Castillo/Hershey/Church/Getty/Macías/Sigcho-Lopez; IL-5 Hanson; IL-6 Conforti; IL-7 Ford/Koppie; IL-8 Bean/Davis; IL-9 Biss/Elleson; IL-10 Lambrecht; IL-11 Walter; IL-12 Fortier; IL-13 Wilson; IL-14 Marter; IL-15 Todd; IL-16 Nolley; IL-17 Vancil.

## Gate update (155-verify.sql)
- Added IL-4 winner pin `('IL','1704','Patty Garcia')` to `_winners`.
- Reset `_minor` to seeded set (IL-2 Banks, IL-4 Hershey + Sigcho-Lopez); removed the deferred PA independents.
- Post-Wave-2 gate run: USHC2-03a/03b/02a/02c + D-04 + D-02 all **PASS**; USHC2-04/05 fail (Wave 3 headshots/stances pending — expected).
