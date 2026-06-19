# 132-01 SUMMARY — OH House Reps Batch A (OH-1..OH-8)

**Plan:** 132-01 · **Phase:** 132 (OH + NC House Rep Stances) · **Requirement:** USHS-06
**Status:** ✅ Complete · **Date:** 2026-06-18

## What was delivered

Sourced compass stances for all 8 Ohio US House reps in batch A (external_id −39001..−39008), pushed to production. **99 answers, 99 paired sourced context rows, 0 unsourced; 27 Read & Rank quotes selected (0 surname leaks).**

| external_id | rep | district | party | stances | notable |
|-------------|-----|----------|-------|---------|---------|
| −39001 | Greg Landsman | OH-1 | D | 11 | moderate New Dem; LCV-backed climate/fossil |
| −39002 | David J. Taylor | OH-2 | R | 6 | freshman (2025); scored off OBBBA H.R.1 vote |
| −39003 | Joyce Beatty | OH-3 | D | 19 | full progressive record (fmr CBC chair) |
| −39004 | Jim Jordan | OH-4 | R | 18 | Judiciary chair; full conservative record |
| −39005 | Robert E. Latta | OH-5 | R | 17 | long-serving; LCV 3% |
| −39006 | Michael A. Rulli | OH-6 | R | 4 | 2024 special; only OH state-senate record documentable |
| −39007 | Max L. Miller | OH-7 | R | 6 | thin web footprint; abortion=3 (state-deference, flagged close call) |
| −39008 | Warren Davidson | OH-8 | R | 18 | **tariffs=1 (free-trader, against party); NO on OBBBA** |

## Evidence-over-party calls (not party-inferred)
- Davidson `tariffs=1` (eliminate tariffs/free trade) — documented free-trader, opposite current GOP posture.
- Miller `abortion=3` held (pro-life but state-deference, no federal-ban support) rather than inflated; limitation noted in reasoning.
- Freshmen (Taylor/Rulli/Miller) honest-skipped where no record — no party-padding.

## How (validated v2.16 pipeline)
- 25 federal topics fetched fresh → `oh-house-a/_TOPIC_SCALE.txt` (44 live − 11 city − 8 judicial-*).
- `politician-stance-researcher` agents at **3-concurrency** (3 waves: 3+3+2), WebFetch-only, five-chairs framing. Held clean — no rate-limit/empty-output.
- Per-rep CSVs → `_merge.ts` canonical re-parse(`relax_quotes`/`relax_column_count`)/re-stringify + validate (0 problems) → `2026-06-18-oh-house-batch-a.csv`.
- Push via external_id-keyed `oh-house-a/_push.ts` (copied from pa-house-a): answers + context + quotes in one txn, ON CONFLICT DO UPDATE, suffix-aware surname leak-check.

## Escaping lesson (carry-forward)
The agents emitted **valid** RFC-4180 (`"""quote"""` = literal-quoted field). The v2.16 "pre-collapse `"""`→`""`" repair is WRONG when applied unconditionally — it corrupts valid triple-quotes. Corrected `_merge.ts` to only collapse genuine quad+ (`"{4,}`) artifacts and rely on csv-parse `relax_quotes`. 0 problems after fix.

## Verification
- Production query: all 8 reps have expected answer counts (11/6/19/18/17/4/6/18 = 99); **0 unsourced** for every rep.
- `_push.ts` reported: `{answers:99, contexts:99, quotesIns:27, quotesDup:0, selected:27, leaks:[]}` — zero rollbacks.

## Self-Check: PASSED

## Files
- `backend/data/stance-research/2026-06-18-oh-house-batch-a.csv` (record CSV, 99 rows)
- `backend/data/stance-research/oh-house-a/` — 8 per-rep CSVs, `_TOPIC_SCALE.txt`, `_merge.ts`, `_push.ts`
