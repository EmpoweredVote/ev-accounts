# 134-04 SUMMARY — WA House Reps Batch B (WA-6..WA-10)

**Plan:** 134-04 · **Phase:** 134 (NJ + WA + AZ House Rep Stances) · **Requirement:** USHS-08
**Status:** ✅ Complete · **Date:** 2026-06-19

## What was delivered

Sourced compass stances for WA-6..WA-10 (external_id −53006..−53010), pushed to production. **77 answers, 77 paired sourced context rows, 0 unsourced; 21 quotes inserted, 21 Read & Rank selected (0 leaks).** Completes the WA delegation.

| external_id | rep | district | party | stances | notable |
|-------------|-----|----------|-------|---------|---------|
| −53006 | Emily Randall | WA-6 | D | 12 | freshman (WA Senate record); abortion=1 (SB 5242), ssm=1, deportation=2 (NO Laken Riley) |
| −53007 | Pramila Jayapal | WA-7 | D | 21 | former CPC chair; healthcare=1 (M4A lead sponsor), most topics =1; ukraine=3 (negotiation letter), tariffs=3 |
| −53008 | Kim Schrier | WA-8 | D | 17 | pediatrician swing-seat; deportation=3 (Laken Riley YES), climate=3, healthcare=2 (public option) |
| −53009 | Adam Smith | WA-9 | D | 12 | HASC ranking; abortion=2, ssm=1, ukraine=2 (led $95B supplemental); housing=3 |
| −53010 | Marilyn Strickland | WA-10 | D | 15 | New Dem; abortion=1, healthcare=2 (not M4A), most domestic =2 |

## Evidence-over-party calls
- Jayapal scored mostly =1 but ukraine=3 (the 2022 negotiation letter, later withdrawn; opposed cluster munitions) and tariffs=3 (voted against TPP/USMCA as written for labor/env standards) — matched to documented nuance, not a blanket progressive 1.
- Schrier deportation=3 (voted YES on Laken Riley) and healthcare=2/climate=3 — swing-seat record distinct from the Seattle progressives.
- Smith abortion=2 (NAY on Hyde-style H.R.7, not a public-funding-at-all-stages 1) — calibrated to the exact text.

## Verification (per-scope, isolation-safe)
- WA delegation = 138 answers (WA-A 61 + WA-B 77); WA unsourced contexts = 0 (verified via local pg pool).
- `_push.ts` (WA-B): `{answers:77, contexts:77, quotesIns:21, quotesDup:0, selected:21, leaks:[]}` — zero rollbacks.
- Merge: `{files:5, total_rows:77, problems:0}`.

## Self-Check: PASSED

## Files
- `backend/data/stance-research/2026-06-19-wa-house-batch-b.csv` (record CSV, 77 rows)
- `backend/data/stance-research/wa-house-b/` — 5 per-rep CSVs, `_TOPIC_SCALE.txt`, `_merge.ts`, `_push.ts`
