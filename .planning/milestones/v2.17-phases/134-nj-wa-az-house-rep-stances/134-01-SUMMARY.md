# 134-01 SUMMARY — NJ House Reps Batch A (NJ-1..NJ-6)

**Plan:** 134-01 · **Phase:** 134 (NJ + WA + AZ House Rep Stances) · **Requirement:** USHS-08
**Status:** ✅ Complete · **Date:** 2026-06-19

## What was delivered

Sourced compass stances for NJ-1..NJ-6 (external_id −34001..−34006), pushed to production. **97 answers, 97 paired sourced context rows, 0 unsourced; 19 quotes inserted, 18 Read & Rank selected (0 leaks).**

| external_id | rep | district | party | stances | notable |
|-------------|-----|----------|-------|---------|---------|
| −34001 | Donald Norcross | NJ-1 | D | 17 | labor Dem; abortion=1, ssm=1, school-vouchers=1 |
| −34002 | Jefferson Van Drew | NJ-2 | R | 16 | party-switcher; post-switch record scored (immigration=4, ukraine=4 (NO on aid), abortion=4) |
| −34003 | Herbert Conaway Jr. | NJ-3 | D | 9 | freshman (NJ Assembly Health Chair record); religious-freedom=2, ssm=1; digital-footprint gap |
| −34004 | Christopher H. Smith | NJ-4 | R | 15 | 40-yr member; ssm=5, social-security=5, but climate=3 (62% LCV, 2nd-highest GOP) + taxes=3 (NO on TCJA, SALT) |
| −34005 | Josh Gottheimer | NJ-5 | D | 17 | Problem Solvers; taxes=4 (SALT, anti-increase), voting=4 (SAVE Act crossover), deportation=4 (Laken Riley) |
| −34006 | Frank Pallone Jr. | NJ-6 | D | 23 | E&C ranking member; abortion=1, taxes=1, healthcare=2; deepest coverage |

## Evidence-over-party calls
- Van Drew scored on his ACTUAL post-2020-switch record (Laken Riley, OBBB, voted AGAINST Ukraine aid & NATO expansion) — not either party label.
- Smith's GOP-divergent record captured: climate=3 (62% LCV), taxes=3 (voted NO on 2017 TCJA over SALT), ukraine=2 (decades-long Helsinki Commission hawk) — while ssm=5 / social-security=5 reflect his conservative core.
- Gottheimer's moderate record: taxes=4 (opposes income-tax increases), voting-rights=4 (2025 SAVE Act crossover), deportation=4 (one of 46 Dems on Laken Riley) — explicitly distinct from the generic Dem baseline.
- Conaway (freshman, 9 topics) honest-partialed — most federal sources 403'd and his campaign site is down; NJ Assembly record + one NJ Globe interview carried the documented rows.

## Verification (per-scope, isolation-safe)
- NJ-A in-scope answers = 97; NJ-A unsourced contexts = 0. Push keyed strictly to in-scope external_ids → writes isolated.
- `_push.ts` (NJ-A): `{answers:97, contexts:97, quotesIns:19, quotesDup:0, selected:18, leaks:[]}` — zero rollbacks.
- Merge: `{files:6, total_rows:97, problems:0}`.

## Self-Check: PASSED

## Files
- `backend/data/stance-research/2026-06-19-nj-house-batch-a.csv` (record CSV, 97 rows)
- `backend/data/stance-research/nj-house-a/` — 6 per-rep CSVs, `_TOPIC_SCALE.txt`, `_merge.ts`, `_push.ts`
