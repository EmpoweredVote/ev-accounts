# 134-06 SUMMARY — AZ House Reps Batch B (AZ-6..AZ-9)

**Plan:** 134-06 · **Phase:** 134 (NJ + WA + AZ House Rep Stances) · **Requirement:** USHS-08
**Status:** ✅ Complete · **Date:** 2026-06-19

## What was delivered

Sourced compass stances for AZ-6..AZ-9 (external_id −4006..−4009), pushed to production. **44 answers, 44 paired sourced context rows, 0 unsourced; 3 quotes inserted, 3 Read & Rank selected (0 leaks).** Completes the AZ delegation and all of Phase 134.

| external_id | rep | district | party | stances | notable |
|-------------|-----|----------|-------|---------|---------|
| −4006 | Juan Ciscomani | AZ-6 | R | 9 | swing-seat; healthcare=3/medicare=3 (resisted Medicaid-cut framing but voted OBBB), deportation=4 (Laken Riley) |
| −4007 | Adelita Grijalva | AZ-7 | D | 8 | 2025 special-election freshman; healthcare=1 (M4A cosponsor HR 3069), climate=2 (100% LCV); scored own record only |
| −4008 | Abraham Hamadeh | AZ-8 | R | 7 | freshman; immigration=5, deportation=5, climate=5 (all Wikipedia-sourced) |
| −4009 | Paul Gosar | AZ-9 | R | 20 | Freedom Caucus; immigration=5 (10-yr moratorium), ukraine=5, ssm=5, redistricting=5; deepest coverage |

## Evidence-over-party calls
- Ciscomani healthcare=3 / medicare=3: publicly opposed Medicaid cuts yet voted for OBBB work requirements — swing-district nuance captured at 3, not the typical GOP 4–5.
- Grijalva scored on HER record only (M4A cosponsorship, LCV 100%, Pima County housing, TUSD board) — explicitly NOT her late father's positions; 17 topics honest-skipped (thin 2025 freshman record).
- Gosar abortion=4 (rape/incest/maternal exceptions, no criminal penalties on women) and tariffs=3 (USMCA YES, mixed trade score) — calibrated to documented record rather than assumed hard-5 across the board.

## Verification — Phase 134 close-out (all 31 reps)
- **NJ 158 + WA 138 + AZ 113 (AZ-A 69 + AZ-B 44) = 409 answers across 31/31 in-scope reps; 0 unsourced contexts in scope** (verified via local pg pool).
- `_push.ts` (AZ-B): `{answers:44, contexts:44, quotesIns:3, quotesDup:0, selected:3, leaks:[]}` — zero rollbacks.
- Merge: `{files:4, total_rows:44, problems:0}`.

## Phase 134 totals
- NJ-A 97 + NJ-B 61 + WA-A 61 + WA-B 77 + AZ-A 69 + AZ-B 44 = **409 answers, 31 reps, 0 unsourced.** USHS-08 closed.
- Honest-partials (thin freshman/special-election records, no party inference): Conaway NJ-3 (9), McIver NJ-10 (6), Mejia NJ-11 (7), Pou NJ-9 (9), Grijalva AZ-7 (8), Hamadeh AZ-8 (7), Ansari AZ-3 (9).

## Self-Check: PASSED

## Files
- `backend/data/stance-research/2026-06-19-az-house-batch-b.csv` (record CSV, 44 rows)
- `backend/data/stance-research/az-house-b/` — 4 per-rep CSVs, `_TOPIC_SCALE.txt`, `_merge.ts`, `_push.ts`
