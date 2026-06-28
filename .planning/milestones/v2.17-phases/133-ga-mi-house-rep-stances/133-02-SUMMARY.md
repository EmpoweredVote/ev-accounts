# 133-02 SUMMARY — GA House Reps Batch B (GA-8..GA-12, GA-14)

**Plan:** 133-02 · **Phase:** 133 (GA + MI House Rep Stances) · **Requirement:** USHS-07
**Status:** ✅ Complete · **Date:** 2026-06-19

## What was delivered

Sourced compass stances for GA-8..GA-12 + GA-14 (external_id −13008..−13012, −13014), pushed to production. **74 answers, 74 paired sourced context rows, 0 unsourced; 28 quotes inserted, 28 Read & Rank selected (0 leaks).** This completes the Georgia delegation.

| external_id | rep | district | party | stances | notable |
|-------------|-----|----------|-------|---------|---------|
| −13008 | Austin Scott | GA-8 | R | 15 | abortion=4 (Life at Conception + maternal exception), ukraine=2 (Armed Services), ssm=5 |
| −13009 | Andrew Clyde | GA-9 | R | 15 | Freedom Caucus; civil-rights=5 (NO on Emmett Till/Juneteenth), climate=5 (0% LCV) |
| −13010 | Mike Collins | GA-10 | R | 13 | Laken Riley Act author; immigration=5, deportation=5, abortion=5 |
| −13011 | Barry Loudermilk | GA-11 | R | 14 | taxes=5 (FairTax/IRS abolition), ssm=5 (anti-Obergefell), religious-freedom=5 |
| −13012 | Rick W. Allen | GA-12 | R | 16 | ssm=5 (NO on Respect for Marriage Act), ukraine=4 (NO on Sept-2023 aid), trans-athletes=4 |
| −13014 | Clay Fuller | GA-14 | R | 1 | brand-new freshman (took office Apr 2026); only deportation=5 documented (campaign statement); honest-partial, auto-fill later |

## Evidence-over-party / data-quality calls
- Several Clyde rows rest on the AFA candidate voter-guide questionnaire (candidate-completed, above the isidewith bar); the agent dropped 10 topics where only a generic "free enterprise" posture existed rather than topic-specific evidence.
- Fuller is a special-election freshman with no voting record — only his verbatim campaign immigration-enforcement line cleared the bar (deportation=5). The other 24 topics honest-skipped, not party-inferred. He auto-fills on a future re-run once he accrues a House record.
- Scott ukraine=2 (consistent Armed Services support) and Allen/Collins ukraine=4 (NO on aid) — GA Republicans split by documented votes, not assumed.

## Verification
- Production answers 21563 → 21637 (+74). GA-B in-scope answers = 74; GA-B unsourced contexts = 0.
- `_push.ts` (GA-B): `{answers:74, contexts:74, quotesIns:28, quotesDup:0, selected:28, leaks:[]}` — zero rollbacks.
- Merge: `{files:6, total_rows:74, problems:0}`.

## Georgia delegation close-out
- GA-A 106 + GA-B 74 = **180 answers across all 13 in-scope GA reps, 0 unsourced.**

## Self-Check: PASSED

## Files
- `backend/data/stance-research/2026-06-19-ga-house-batch-b.csv` (record CSV, 74 rows)
- `backend/data/stance-research/ga-house-b/` — 6 per-rep CSVs, `_TOPIC_SCALE.txt`, `_merge.ts`, `_push.ts`
