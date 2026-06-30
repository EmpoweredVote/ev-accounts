# 155-03 SUMMARY — PA candidate records + race wiring

**Status:** ✅ Complete · **Date:** 2026-06-30 · **Requirements:** USHC2-02, USHC2-03

## What was done
Migration **`1118_seed_pa_2026_house_candidates.sql`** applied to prod: **17 new politicians + 33 race_candidates** across all 17 PA US House races. 16 sitting incumbents REUSED (is_incumbent=true, 154 incumbent_pid); 17 new challengers/open-seat. Reconciliation: `backend/data/seed-pa-2026-house/155-03-pa-reconciliation.csv` (33 rows).

## Verification (per-state PA-scoped)
- ✅ 17 races, 33 active race_candidates, 16 incumbents, 0 NULL politician_id, 0 duplicate full_name.
- ✅ PA-3 Dwight Evans (-42003 / 3c962502…) ABSENT from active field; Chris Rabb (D) active (unopposed — no R qualified).
- ✅ Idempotent: re-run inserted 0 rows.

## D-03 dedup result
All 17 new PA names returned **0 prior records** in live DB (last-name ILIKE search) → all genuinely NEW. PA-8 Bresnahan renominated (154 CSV comma artifact resolved, pid ac16b65b…); challenger Paige Cognetti new.

## New-candidate external_id list (for 155-05 headshots + 155-07 stances)
-420101 Bob Harvie · -420201 Jessica Arriaga · -420301 Chris Rabb · -420401 Aurora Stuski · -420501 Nicholas Manganaro · -420601 Marty Young · -420701 Bob Brooks · -420801 Paige Cognetti · -420901 Rachel Wallace · -421001 Janelle Stelson · -421101 Nancy Mannion · -421201 James Hayes · -421301 Beth Farnham · -421401 David Alan Bradstock · -421501 Ray Bilger · -421601 Justin Wagner · -421701 Tony Guy

## ⚠ Deviation from 154 field — PA independents DEFERRED (date-gated carry-forward)
Live re-confirm (Ballotpedia/Wikipedia, 2026-06-30) found **PA's independent nomination-paper deadline is Aug 3, 2026** — as of today **no independent is ballot-certified**. Per D-03 inclusion bar (seed only ballot-qualified), the following declared-only independents were **OMITTED** and deferred to a **post-Aug-10 date-gated re-check**:
- PA-10 **Isabelle Harman** (Ind), PA-13 **Cody Thomas** (Ind) — were in the 154 field as tentative; not yet qualified.
- Newly-declared (not in 154): PA-1 John Hoban, PA-4 Milan Patel, PA-11 Jeffrey Wilder, PA-16 Nick Singelis.
- **PA-10 "Steven Long" DROPPED entirely** — stale 2022 PA-10 independent carryover, no 2026 evidence.
- PA-14 seeded under legal name **David Alan Bradstock** (campaigns as "Alan").

**Impact:** the 155-02 gate's D-02-minor PA pins (Harman/Long/Thomas) must be removed (handled in the gate update); the deferred PA independents become a new carry-forward (analogous to FL Phase 153). All PA **major-party** races are complete and correct.
