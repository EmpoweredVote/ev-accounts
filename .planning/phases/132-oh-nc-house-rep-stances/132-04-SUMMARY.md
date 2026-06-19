# 132-04 SUMMARY — NC House Reps Batch B (NC-8..NC-14)

**Plan:** 132-04 · **Phase:** 132 (OH + NC House Rep Stances) · **Requirement:** USHS-06
**Status:** ✅ Complete · **Date:** 2026-06-19

## What was delivered

Sourced compass stances for NC-8..NC-14 (external_id −37008..−37014), pushed to production. **77 answers, 77 paired sourced context rows, 0 unsourced; 25 Read & Rank quotes (0 leaks).** This completes phase 132 (all of OH + NC).

| external_id | rep | district | party | stances | notable |
|-------------|-----|----------|-------|---------|---------|
| −37008 | Mark Harris | NC-8 | R | 14 | pastor; abortion=5, ssm=5 (2012 Amendment 1 lead) |
| −37009 | Richard Hudson | NC-9 | R | 18 | NRCC chair; full conservative record |
| −37010 | Pat Harrigan | NC-10 | R | 2 | freshman; **19 isidewith-only rows dropped** (below evidence bar) |
| −37011 | Chuck Edwards | NC-11 | R | 5 | sourcing-limited (most sources 403/429) |
| −37012 | Alma S. Adams | NC-12 | D | 17 | progressive (CBC, HBCU Caucus) |
| −37013 | Brad Knott | NC-13 | R | 5 | freshman; **12 isidewith-only rows dropped** |
| −37014 | Tim Moore | NC-14 | R | 16 | fmr NC House Speaker; abortion=3 (SB20), trans-athletes=4 (Fairness Act), ssm=5 |

## Data-quality call (isidewith.com)
The two newest freshmen (Harrigan, Knott) initially scored 21/17 almost entirely from **isidewith.com**, an aggregator whose candidate "positions" are characterizations rather than documented votes/statements/scorecards. Per the evidence-over-party standard, **31 isidewith-only rows were dropped** (Harrigan 19, Knott 12) — keeping only vote/scorecard/Wikipedia/campaign-statement-backed rows. Harrigan→2, Knott→5 (honest partials; auto-fill on a future re-run). User-approved drop.

## Evidence-over-party calls
- Moore abortion=3 (NC SB20 12-week framework, exact value-3 text), trans-athletes=4 (Fairness in Women's Sports Act = biological-sex, not total ban).
- Harris ssm=5 / abortion=5 from documented 2012 Amendment 1 leadership + no-exceptions pro-life record.

## Phase 132 close-out verification (full OH + NC)
- Production: **29 in-scope reps — 28 with sourced stances, 1 documented honest-skip (McDowell NC-6), 349 total answers, 0 unsourced.**
- Batch totals: OH-A 99 + OH-B 86 + NC-A 87 + NC-B 77 = 349.
- `_push.ts` (NC-B): `{answers:77, contexts:77, quotesIns:25, quotesDup:0, selected:25, leaks:[]}` — zero rollbacks.

## Self-Check: PASSED

## Files
- `backend/data/stance-research/2026-06-18-nc-house-batch-b.csv` (record CSV, 77 rows post-filter)
- `backend/data/stance-research/nc-house-b/` — 7 per-rep CSVs, `_TOPIC_SCALE.txt`, `_merge.ts`, `_push.ts`
