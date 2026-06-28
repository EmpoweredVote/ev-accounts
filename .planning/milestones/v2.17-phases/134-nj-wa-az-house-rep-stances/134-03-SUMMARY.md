# 134-03 SUMMARY — WA House Reps Batch A (WA-1..WA-5)

**Plan:** 134-03 · **Phase:** 134 (NJ + WA + AZ House Rep Stances) · **Requirement:** USHS-08
**Status:** ✅ Complete · **Date:** 2026-06-19

## What was delivered

Sourced compass stances for WA-1..WA-5 (external_id −53001..−53005), pushed to production. **61 answers, 61 paired sourced context rows, 0 unsourced; 2 quotes inserted, 2 Read & Rank selected (0 leaks — agents found few verbatim quotes this batch; quotes are optional).**

| external_id | rep | district | party | stances | notable |
|-------------|-----|----------|-------|---------|---------|
| −53001 | Suzan DelBene | WA-1 | D | 17 | DCCC chair; abortion=1, ssm=1, redistricting=1, voting=1 |
| −53002 | Rick Larsen | WA-2 | D | 16 | T&I ranking; abortion=1, climate=3 (opposed GND), healthcare=2 (rejects M4A) |
| −53003 | Marie Gluesenkamp Perez | WA-3 | D | 11 | Blue Dog swing-seat; deportation=4 (Laken Riley, 1 of 5 Dems), immigration=4, voting=4 (SAVE Act), trans-athletes=4 |
| −53004 | Dan Newhouse | WA-4 | R | 8 | impeachment survivor; ssm=2 (YES RMA), immigration=2 (Farm Workforce lead), ukraine=2 — but climate=5/fossil=4 |
| −53005 | Michael Baumgartner | WA-5 | R | 9 | freshman (WA Senate record); climate=5/fossil=5 (0% LCV), taxes=4/medicare=4 (OBBB), voting=4 (SAVE Act) |

## Evidence-over-party calls
- Gluesenkamp Perez's heavily cross-party record captured by documented votes: Laken Riley (1 of 5 House Dems), SAVE Act (×2), NDAA trans/abortion restrictions, against student-debt relief — LCV 57% and falling. deportation/immigration/voting/trans-athletes all =4.
- Newhouse's GOP-divergent record: same-sex-marriage=2 (voted YES on Respect for Marriage Act), immigration=2 (Farm Workforce Modernization lead), ukraine=2 (consistent aid) — while climate=5/fossil=4/taxes=4 reflect his conservative core.
- Larsen healthcare=2 and climate=3 (explicitly opposed Green New Deal / Medicare for All) — matched to documented positions, not the generic Dem baseline.

## Verification (per-scope, isolation-safe)
- WA-A in-scope answers = 61; WA-A unsourced contexts = 0 (verified via local pg pool — MCP token had expired).
- `_push.ts` (WA-A): `{answers:61, contexts:61, quotesIns:2, quotesDup:0, selected:2, leaks:[]}` — zero rollbacks.
- Merge: `{files:5, total_rows:61, problems:0}`.

## Self-Check: PASSED

## Files
- `backend/data/stance-research/2026-06-19-wa-house-batch-a.csv` (record CSV, 61 rows)
- `backend/data/stance-research/wa-house-a/` — 5 per-rep CSVs, `_TOPIC_SCALE.txt`, `_merge.ts`, `_push.ts`
