# 132-02 SUMMARY — OH House Reps Batch B (OH-9..OH-15)

**Plan:** 132-02 · **Phase:** 132 (OH + NC House Rep Stances) · **Requirement:** USHS-06
**Status:** ✅ Complete · **Date:** 2026-06-18

## What was delivered

Sourced compass stances for all 7 Ohio US House reps in batch B (external_id −39009..−39015), pushed to production. **86 answers, 86 paired sourced context rows, 0 unsourced; 31 Read & Rank quotes selected (0 surname leaks).** This completes OH House coverage.

| external_id | rep | district | party | stances | notable |
|-------------|-----|----------|-------|---------|---------|
| −39009 | Marcy Kaptur | OH-9 | D | 18 | **tariffs=4** (protectionist Dem); abortion=2 (mixed history) |
| −39010 | Michael R. Turner | OH-10 | R | 4 | sourcing-limited; agent dropped party-inferred drafts |
| −39011 | Shontel M. Brown | OH-11 | D | 14 | progressive record |
| −39012 | Troy Balderson | OH-12 | R | 17 | conservative record |
| −39013 | Emilia Strong Sykes | OH-13 | D | 11 | swing-district moderate (climate=3) |
| −39014 | David P. Joyce | OH-14 | R | 9 | **moderate**: climate=3, same-sex-marriage=2 (RMA vote) |
| −39015 | Mike Carey | OH-15 | R | 13 | coal bg → climate=5/fossil=5; ssm=2 (RMA vote) |

## Evidence-over-party calls (not party-inferred)
- Kaptur `tariffs=4` (protectionist Democrat — votes against FTAs/WTO).
- Joyce/Carey `same-sex-marriage=2` (documented Respect for Marriage Act votes despite R).
- Turner held to 4 documented stances; agent explicitly dropped drafts that rested on party inference.

## Escaping lesson (corrected carry-forward)
kaptur.csv emitted a genuine **quad-quote artifact** (`""""Access…"""` in a de-id field). The correct repair is the documented **`""""`→`"""`** (4→3) collapse — NOT `"""`→`""` (which corrupts valid literal-quoted fields, as 132-01 showed). `_merge.ts` repair now collapses 4+ quotes to 3 and relies on `csv-parse` `relax_quotes`; 0 problems after fix. Both lessons now encoded in the merge tooling.

## Verification
- Production: all 15 OH reps (−39001..−39015) have ≥1 stance; **185 total OH answers; 0 unsourced.**
- `_push.ts`: `{answers:86, contexts:86, quotesIns:31, quotesDup:0, selected:31, leaks:[]}` — zero rollbacks.

## Self-Check: PASSED

## Files
- `backend/data/stance-research/2026-06-18-oh-house-batch-b.csv` (record CSV, 86 rows)
- `backend/data/stance-research/oh-house-b/` — 7 per-rep CSVs, `_TOPIC_SCALE.txt`, `_merge.ts`, `_push.ts`
