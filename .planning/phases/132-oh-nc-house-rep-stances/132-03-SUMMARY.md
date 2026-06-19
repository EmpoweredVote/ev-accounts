# 132-03 SUMMARY — NC House Reps Batch A (NC-1..NC-7)

**Plan:** 132-03 · **Phase:** 132 (OH + NC House Rep Stances) · **Requirement:** USHS-06
**Status:** ✅ Complete · **Date:** 2026-06-18

## What was delivered

Sourced compass stances for the NC-1..NC-7 US House reps (external_id −37001..−37007), pushed to production. **87 answers, 87 paired sourced context rows, 0 unsourced; 24 Read & Rank quotes selected (0 surname leaks).** 6 reps scored; NC-6 (McDowell) is a documented honest-skip.

| external_id | rep | district | party | stances | notable |
|-------------|-----|----------|-------|---------|---------|
| −37001 | Donald G. Davis | NC-1 | D | 8 | **moderate-conservative D**: medicare=4, trans-athletes=4, deportation=3 (documented R-aligned votes) |
| −37002 | Deborah K. Ross | NC-2 | D | 20 | progressive (fmr ACLU-NC) |
| −37003 | Gregory F. Murphy | NC-3 | R | 10 | physician; conservative |
| −37004 | Valerie P. Foushee | NC-4 | D | 13 | progressive (M4A cosponsor, ICE-dismantle) |
| −37005 | Virginia Foxx | NC-5 | R | 19 | long record; tariffs=3 (selective) |
| −37006 | Addison P. McDowell | NC-6 | R | **0** | **honest-skip** — Nov-2024 freshman, 40+ sources blocked/empty, no documentable record |
| −37007 | David Rouzer | NC-7 | R | 17 | conservative; abortion=4 (20-wk ban, not total) |

## Evidence-over-party calls (not party-inferred)
- Davis (D) scored 3–4 on trans-athletes/medicare/deportation from documented votes that break with his party — exactly the evidence-over-party standard.
- Foxx `tariffs=3` (selective: NO CAFTA, YES USMCA, sugar tariffs).
- McDowell left at 0 rather than party-padded — auto-fills on a future re-run once he has a record (v2.16 honest-skip handling).

## Verification
- Production: NC-1..7 answers = 8/20/10/13/19/0/17 = **87 total; 0 unsourced**; McDowell intentionally 0.
- `_push.ts`: `{answers:87, contexts:87, quotesIns:24, quotesDup:0, selected:24, leaks:[]}` — zero rollbacks.

## Self-Check: PASSED

## Files
- `backend/data/stance-research/2026-06-18-nc-house-batch-a.csv` (record CSV, 87 rows)
- `backend/data/stance-research/nc-house-a/` — 7 per-rep CSVs (mcdowell.csv header-only = honest-skip), `_TOPIC_SCALE.txt`, `_merge.ts`, `_push.ts`
