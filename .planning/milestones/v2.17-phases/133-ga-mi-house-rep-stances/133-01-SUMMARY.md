# 133-01 SUMMARY — GA House Reps Batch A (GA-1..GA-7)

**Plan:** 133-01 · **Phase:** 133 (GA + MI House Rep Stances) · **Requirement:** USHS-07
**Status:** ✅ Complete · **Date:** 2026-06-19

## What was delivered

Sourced compass stances for GA-1..GA-7 (external_id −13001..−13007), pushed to production. **106 answers, 106 paired sourced context rows, 0 unsourced; 24 quotes inserted, 23 Read & Rank selected (0 leaks).**

| external_id | rep | district | party | stances | notable |
|-------------|-----|----------|-------|---------|---------|
| −13001 | Earl L. Carter | GA-1 | R | 15 | FairTax lead sponsor → taxes=5; 0% LCV → climate=5; ssm=5 |
| −13002 | Sanford D. Bishop Jr. | GA-2 | D | 18 | Blue Dog; deportation=4 (Laken Riley YES), ssm=4 (2004/06 amendments), religious-freedom=4 |
| −13003 | Brian Jack | GA-3 | R | 8 | freshman; OBBB-anchored record (climate=5, taxes=5, immigration=5) |
| −13004 | Henry C. Johnson Jr. | GA-4 | D | 18 | CPC; abortion=1, climate=2 (97% LCV), redistricting=1 |
| −13005 | Nikema Williams | GA-5 | D | 18 | progressive; healthcare=1 (M4A), trans-athletes=1, voting=1 |
| −13006 | Lucy McBath | GA-6 | D | 17 | healthcare=2 (rejects M4A), medicare=2 (age-55), deportation=3 (Laken Riley) |
| −13007 | Richard McCormick | GA-7 | R | 12 | physician; abortion=5 (Life at Conception), fossil=5 (0% LCV), religious-freedom=5 |

## Evidence-over-party calls
- Bishop (D) scored conservative on several topics matching his Blue Dog record: deportation=4 (Laken Riley Act, one of 46 House Dems), same-sex-marriage=4 (voted YES on 2004/2006 marriage amendments), religious-freedom=4 (Istook Amendment cosponsor) — documented votes, not party inference.
- McBath healthcare=2 (explicitly rejects Medicare for All) vs Williams healthcare=1 (M4A supporter) — two GA Democrats split by documented record.
- Jack (freshman, 8 topics) and McCormick (12) honest-partialed the rest — no isidewith inference.

## Verification
- Production answers 21457 → 21563 (+106); contexts 21088 → 21194 (+106). GA-A in-scope answers = 106; GA-A unsourced contexts = 0.
- `_push.ts` (GA-A): `{answers:106, contexts:106, quotesIns:24, quotesDup:0, selected:23, leaks:[]}` — zero rollbacks. Non-in-scope politician counts unchanged.
- Merge: `{files:7, total_rows:106, problems:0}`.

## Self-Check: PASSED

## Files
- `backend/data/stance-research/2026-06-19-ga-house-batch-a.csv` (record CSV, 106 rows)
- `backend/data/stance-research/ga-house-a/` — 7 per-rep CSVs, `_TOPIC_SCALE.txt`, `_merge.ts`, `_push.ts`
