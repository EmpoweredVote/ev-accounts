# 134-05 SUMMARY — AZ House Reps Batch A (AZ-1..AZ-5)

**Plan:** 134-05 · **Phase:** 134 (NJ + WA + AZ House Rep Stances) · **Requirement:** USHS-08
**Status:** ✅ Complete · **Date:** 2026-06-19

## What was delivered

Sourced compass stances for AZ-1..AZ-5 (external_id −4001..−4005), pushed to production. **69 answers, 69 paired sourced context rows, 0 unsourced; 22 quotes inserted, 22 Read & Rank selected (0 leaks).**

| external_id | rep | district | party | stances | notable |
|-------------|-----|----------|-------|---------|---------|
| −4001 | David Schweikert | AZ-1 | R | 17 | swing-seat fiscal hawk; climate=5, taxes=5, tariffs=1 (free-trade), ssm=5 |
| −4002 | Eli Crane | AZ-2 | R | 12 | Freedom Caucus; immigration=5, deportation=5, ukraine=5 (NO on aid), misinfo=5 |
| −4003 | Yassamin Ansari | AZ-3 | D | 9 | freshman (Phoenix council record); climate=2, immigration=2 (ICE abolition call), ssm=1 |
| −4004 | Greg Stanton | AZ-4 | D | 11 | New Dem; abortion=2, ssm=1, climate=3, healthcare=2 (not M4A) |
| −4005 | Andy Biggs | AZ-5 | R | 20 | ex-Freedom Caucus chair; abortion=5 (personhood), climate=5, ukraine=5, ssm=5; deepest GOP coverage |

## Evidence-over-party calls
- Schweikert tariffs=1 (documented free-trade fiscal conservative, no protectionist record) — a deliberate divergence from the populist-tariff GOP wing, matched to his record.
- Biggs medicare/aid corrected 5→4 by the agent (ACA-repeal votes documented but no full-privatization vote) and trans-athletes dropped (inference-only) — disciplined evidence bar on a hard-right member.
- Ansari (freshman, 9 topics) honest-partialed; same-sex-marriage=1 rests on documented LGBTQ+ advocacy actions (hosted Phoenix's first LGBTQ+ block party), not party inference; 16 topics skipped.

## Verification (per-scope, isolation-safe)
- AZ-A in-scope answers = 69; AZ-A unsourced contexts = 0 (verified via local pg pool).
- `_push.ts` (AZ-A): `{answers:69, contexts:69, quotesIns:22, quotesDup:0, selected:22, leaks:[]}` — zero rollbacks.
- Merge: `{files:5, total_rows:69, problems:0}`. (Note: AZ external_ids are −4001..−4005, single-thousands range for state_fips 4.)

## Self-Check: PASSED

## Files
- `backend/data/stance-research/2026-06-19-az-house-batch-a.csv` (record CSV, 69 rows)
- `backend/data/stance-research/az-house-a/` — 5 per-rep CSVs, `_TOPIC_SCALE.txt`, `_merge.ts`, `_push.ts`
