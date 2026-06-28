# 133-03 SUMMARY — MI House Reps Batch A (MI-1..MI-7)

**Plan:** 133-03 · **Phase:** 133 (GA + MI House Rep Stances) · **Requirement:** USHS-07
**Status:** ✅ Complete · **Date:** 2026-06-19

## What was delivered

Sourced compass stances for MI-1..MI-7 (external_id −26001..−26007), pushed to production. **106 answers, 106 paired sourced context rows, 0 unsourced; 35 quotes inserted, 35 Read & Rank selected (0 leaks).**

| external_id | rep | district | party | stances | notable |
|-------------|-----|----------|-------|---------|---------|
| −26001 | Jack Bergman | MI-1 | R | 11 | ssm=5 (NO on RFMA), climate=5 (7% LCV), abortion=4 |
| −26002 | John Moolenaar | MI-2 | R | 16 | uniform value=4 moderate-conservative record; tariffs=4 (China hawk, not universal) |
| −26003 | Hillary Scholten | MI-3 | D | 14 | ssm=1 (Equality Caucus), abortion=2, immigration=3 (Laken Riley YES + pathway) |
| −26004 | Bill Huizenga | MI-4 | R | 16 | social-security=5 (personal accounts), taxes=5 (flat tax), ssm=5 |
| −26005 | Tim Walberg | MI-5 | R | 18 | minister; healthcare=5, religious-freedom=5, school-vouchers=5 (Ed&Workforce chair) |
| −26006 | Debbie Dingell | MI-6 | D | 19 | progressive but auto-pragmatic: climate=3 (auto industry), most domestic=2; 99% LCV |
| −26007 | Tom Barrett | MI-7 | R | 12 | freshman (state-senate record drawn on); uniform 4–5; climate=5 (0% LCV) |

## Evidence-over-party calls
- Scholten immigration=3 / deportation=3 (voted for Laken Riley Act AND backs citizenship pathways) — documented split record, not party assumption; ssm=1 (Equality Caucus) is the most progressive chair.
- Dingell scored 2 (not 1) on most domestic topics and climate=3 (not 2) reflecting her documented auto-industry pragmatism vs. Progressive Caucus membership — matched to record, not ideology.
- Moolenaar's record maps uniformly to value=4 (moderate-conservative), distinct from the harder-5 records of Walberg/Huizenga — distinguished by actual votes (e.g. tariffs=4 China-targeted, not universal).

## Verification (per-scope, isolation-safe)
- GA delegation unchanged at 180; MI-A in-scope answers = 106; MI-B still 0 (not yet pushed). My push is keyed strictly to in-scope external_ids → writes provably isolated.
- `_push.ts` (MI-A): `{answers:106, contexts:106, quotesIns:35, quotesDup:0, selected:35, leaks:[]}` — zero rollbacks.
- MI-A unsourced contexts = 0. Merge: `{files:7, total_rows:106, problems:0}` (Walberg deduped 19→18 cleanly).
- Note: the global `politician_answers` counter drifted by more than my 106 between checkpoints due to concurrent background production activity (cron/FEC jobs); the per-scope counts above are the authoritative invariant.

## Self-Check: PASSED

## Files
- `backend/data/stance-research/2026-06-19-mi-house-batch-a.csv` (record CSV, 106 rows)
- `backend/data/stance-research/mi-house-a/` — 7 per-rep CSVs, `_TOPIC_SCALE.txt`, `_merge.ts`, `_push.ts`
