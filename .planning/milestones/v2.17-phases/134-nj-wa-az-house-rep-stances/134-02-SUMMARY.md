# 134-02 SUMMARY — NJ House Reps Batch B (NJ-7..NJ-12)

**Plan:** 134-02 · **Phase:** 134 (NJ + WA + AZ House Rep Stances) · **Requirement:** USHS-08
**Status:** ✅ Complete · **Date:** 2026-06-19

## What was delivered

Sourced compass stances for NJ-7..NJ-12 (external_id −34007..−34012), pushed to production. **61 answers, 61 paired sourced context rows, 0 unsourced; 8 quotes inserted, 8 Read & Rank selected (0 leaks).** Completes the NJ delegation.

| external_id | rep | district | party | stances | notable |
|-------------|-----|----------|-------|---------|---------|
| −34007 | Thomas H. Kean Jr. | NJ-7 | R | 10 | swing-seat moderate by reputation but LCV 9–22%; abortion=3 (pro-choice, won't codify), most else =4 |
| −34008 | Robert Menendez | NJ-8 | D | 11 | abortion=2, climate=2 (100% LCV); scored own record only (not his father's) |
| −34009 | Nellie Pou | NJ-9 | D | 9 | freshman (NJ Senate record); deportation=2 (only Trump-district Dem vs Laken Riley), trans-athletes=1 |
| −34010 | LaMonica McIver | NJ-10 | D | 6 | special-election freshman; deportation=1/immigration=1 ("abolish ICE"), climate=2 |
| −34011 | Analilia Mejia | NJ-11 | D | 7 | new member (Apr 2025 special); healthcare=1 (M4A), taxes=1, campaign-finance=2 (no corporate PAC) |
| −34012 | Bonnie Watson Coleman | NJ-12 | D | 18 | CPC; abortion=1, healthcare=1 (M4A Caucus), civil-rights=1 (CROWN Act author) |

## Evidence-over-party calls
- Kean abortion=3 (self-described pro-choice but voted against WHPA + for Born-Alive, "best at the state level") — matched to the documented split, not his moderate reputation; his LCV 9–22% put climate/fossil/energy at 4.
- Pou deportation=2: one of the only Trump-district Democrats to vote AGAINST the Laken Riley Act — a documented divergence.
- The four freshmen (Pou 9, McIver 6, Mejia 7, plus NJ-A's Conaway) honest-partialed; thin federal footprints, most .gov sources 403'd. No party inference.

## Execution note (CSV repair)
- Kean's per-rep CSV had a stray trailing `"` (lone quote in the empty final field) on every row → csv-parse "Invalid Closing Quote". Fixed with `sed 's/,"$/,/'` (a line ending in `,"` is always the artifact: a valid empty final field ends in `,`, a valid quoted final field ends in `text"`). Re-merge: 0 problems. (New lesson for 135+: lone-trailing-quote is distinct from the quad-quote artifact the `_merge.ts` repair handles.)

## Verification (per-scope, isolation-safe)
- NJ delegation = 158 answers (NJ-A 97 + NJ-B 61); NJ unsourced contexts = 0.
- `_push.ts` (NJ-B): `{answers:61, contexts:61, quotesIns:8, quotesDup:0, selected:8, leaks:[]}` — zero rollbacks.
- Merge: `{files:6, total_rows:61, problems:0}`.

## Self-Check: PASSED

## Files
- `backend/data/stance-research/2026-06-19-nj-house-batch-b.csv` (record CSV, 61 rows)
- `backend/data/stance-research/nj-house-b/` — 6 per-rep CSVs, `_TOPIC_SCALE.txt`, `_merge.ts`, `_push.ts`
