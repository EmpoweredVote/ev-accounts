# 150-03 SUMMARY — TX 2026 House race_candidates

**Status:** ✅ Complete
**Wave:** 2
**Migration:** `backend/migrations/1110_seed_tx_2026_house_candidates.sql`
**Reconciliation:** `backend/data/seed-tx-2026-house/150-03-tx-reconciliation.csv` (76 rows)

## Result

- **48 NEW** politician records (band `-(4810000+cd*100+seq)`, -4810101..-4813802; band verified empty pre-insert) + **76 race_candidates** (48 new + 28 reuse) on all 38 TX races.
- Verification: 38 races, 76 active candidates, 0 NULL politician_id, 0 duplicate full_name within TX. Casar active TX-37; Crenshaw absent. (plan automated check: **TX OK**.)

## D-03 reuse resolutions (live-confirmed 2026-06-29, NOT inferred)

| Candidate | District | Decision | politician_id / external_id |
|-----------|----------|----------|------------------------------|
| Greg Casar | TX-37 (active) | REUSE (redistricted from TX-35) | -100335 (24e22813), is_incumbent=false |
| Steve Toth | TX-2 (active) | REUSE (existing TX state-rep record) | -100515 (579a5a6f), is_incumbent=false |
| **Dan Barrios** | TX-32 (active) | **REUSE** (Richardson councilmember = same person, web-confirmed) | **e8c863a7** (ext NULL), is_incumbent=false |
| Colin Allred | TX-33 (active) | **NEW** (live DB returned 0 matches — CONTEXT 2024-Senate guess was FALSE) | -4813301 |
| Troy Nehls | TX-22 | REUSE ("Trever Nehls" in field = typo) | -100322 |

25 renominated home incumbents reused their 148 pids. Lost/retired/redistricted-away incumbents (TX-2 Crenshaw, TX-8/10/19/21/37/38 retired, TX-9 Green / TX-30 Crockett / TX-32 Johnson / TX-33 Veasey redistricted-away) have **no active row** in their old seat. The 4 redistricted-away incumbents are absent from **every** 2026 TX field → **no USHC-02c reuse-pin addition needed** in 150-verify.sql (only Casar, already pinned).

## Stance scope (for 150-07..10)

In-scope = **all 76 active TX candidates** (D-01 TX: all incumbents were zero-stance + all challengers → full federal-24). Batches: 150-07 = TX-1..10, 150-08 = TX-11..20, 150-09 = TX-21..30, 150-10 = TX-31..38.

⚠ **Dan Barrios (TX-32, e8c863a7) already carries 4 stances + 1 image** from his prior Richardson local build. The stance wave (150-09 / TX-21..30? no — TX-32 is in 150-10 TX-31..38) must (a) verify those 4 existing stances are sourced (USHC-05a), and (b) top him up toward federal-24. He already has a headshot → not a USHC-04 new-headshot target.

## New-candidate external_id list (48) — for headshots (150-05) + stances (150-07..10)

-4810101 Yolanda Prince TX-1 · -4810201 Shaun Finnie TX-2 · -4810301 Evan Hunt TX-3 · -4810401 Jason Pearce TX-4 · -4810501 Chelsey Hockett TX-5 · -4810601 Danny Minton TX-6 · -4810701 Alexander Hale TX-7 · -4810801 Jessica Steinmann TX-8 · -4810802 Laura Jones TX-8 · -4810901 Leticia Gutierrez TX-9 · -4810902 Alex Mealer TX-9 · -4811001 Chris Gober TX-10 · -4811002 Caitlin Rourk TX-10 · -4811101 Claire Reynolds TX-11 · -4811201 Angela Rodriguez Prilliman TX-12 · -4811301 Mark Nair TX-13 · -4811401 Thurman Bartie TX-14 · -4811501 Bobby Pulido TX-15 · -4811601 Adam Bauman TX-16 · -4811701 Casey Shepard TX-17 · -4811801 Ronald Whitfield TX-18 · -4811901 Tom Sell TX-19 · -4811902 Kyle Rable TX-19 · -4812001 Edgardo Baez TX-20 · -4812101 Mark Teixeira TX-21 · -4812102 Kristin Hook TX-21 · -4812201 Marquette Greene-Scott TX-22 · -4812301 Brandon Herrera TX-23 · -4812302 Katy Padilla Stout TX-23 · -4812401 Kevin Burge TX-24 · -4812501 Dione Sims TX-25 · -4812601 Steven Shook TX-26 · -4812701 Tanya Lloyd TX-27 · -4812801 Tano Tijerina TX-28 · -4812901 Martha Fierro TX-29 · -4813001 Frederick Haynes III TX-30 · -4813002 Everett Jackson TX-30 · -4813101 Justin Early TX-31 · -4813201 Jace Yarbrough TX-32 · -4813301 Colin Allred TX-33 · -4813302 Patrick Gillespie TX-33 · -4813401 Eric Flores TX-34 · -4813501 Johnny Garcia TX-35 · -4813502 Carlos De La Cruz TX-35 · -4813601 Rhonda Hart TX-36 · -4813701 Lauren Peña TX-37 · -4813801 Jon Bonck TX-38 · -4813802 Melissa McDonough TX-38

## 37 zero-stance TX incumbent pids (active in 2026 → in stance scope)

The 25 renominated home incumbents (TX-1/3/4/5/6/7/11/12/13/14/15/16/17/18/20/22/24/25/26/27/28/29/31/34/36 pids -100301..-100336 per 148-incumbent-map.csv) + Casar -100335 (TX-37) + Steve Toth -100515 (TX-2). Redistricted-away/retired incumbents are NOT active → not researched. All are at 0 federal stances and get the full federal-24 set.
