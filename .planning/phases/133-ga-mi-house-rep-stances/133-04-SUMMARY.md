# 133-04 SUMMARY — MI House Reps Batch B (MI-8..MI-13)

**Plan:** 133-04 · **Phase:** 133 (GA + MI House Rep Stances) · **Requirement:** USHS-07
**Status:** ✅ Complete · **Date:** 2026-06-19

## What was delivered

Sourced compass stances for MI-8..MI-13 (external_id −26008..−26013), pushed to production. **93 answers, 93 paired sourced context rows, 0 unsourced; 26 quotes inserted, 26 Read & Rank selected (0 leaks).** This completes the Michigan delegation and all of Phase 133.

| external_id | rep | district | party | stances | notable |
|-------------|-----|----------|-------|---------|---------|
| −26008 | Kristen McDonald Rivet | MI-8 | D | 14 | freshman New Dem; ssm=1, redistricting=1, abortion=2, climate=3 (state record + 85% LCV) |
| −26009 | Lisa McClain | MI-9 | R | 16 | GOP Conference Chair; uniform 4, climate=5 (1% LCV), ukraine=2 (voted FOR aid) |
| −26010 | John James | MI-10 | R | 12 | abortion=5 (100% pro-life), conservative econ record; civil-rights skipped (conflicting signals) |
| −26011 | Haley Stevens | MI-11 | D | 18 | New Dem; abortion=2, climate=3, deportation=3, trans-athletes=2 (voted vs GOP ban) |
| −26012 | Rashida Tlaib | MI-12 | D | 16 | Squad/CPC; abortion=1, healthcare=1, deportation=1, taxes=1, voting=1 — most progressive of the set |
| −26013 | Shri Thanedar | MI-13 | D | 17 | CPC; abortion=1 (HR 238/1285), deportation=2 (Abolish ICE Act), ai-regulation=3 (AI Disclosure Act) |

## Evidence-over-party calls
- McClain ukraine=2 (voted FOR Lend-Lease 417–10 and the 2024 aid package) — not the isolationist GOP wing; matched to documented votes.
- Stevens trans-athletes=2 and Tlaib trans-athletes skipped while Thanedar's was skipped — each driven by a documented vote or its absence, not a blanket progressive assumption.
- Tlaib ukraine-support honest-skipped despite a strong anti-intervention pattern — the agent refused to score without a confirmed source (evidence bar held).
- Thanedar's record is bill-sponsorship-rich (Abolish ICE Act, Right to Medicare Act, AI Disclosure Act) giving concrete chair matches.

## Verification (per-scope, isolation-safe)
- **Phase close-out:** GA delegation = 180 (13 reps); MI delegation = 199 (13 reps); **26/26 in-scope reps covered; 0 unsourced contexts in scope.**
- MI-B contributed 93 (answers/contexts). `_push.ts` (MI-B): `{answers:93, contexts:93, quotesIns:26, quotesDup:0, selected:26, leaks:[]}` — zero rollbacks.
- Merge: `{files:6, total_rows:93, problems:0}`.

## Phase 133 totals
- GA-A 106 + GA-B 74 + MI-A 106 + MI-B 93 = **379 answers across 26 reps, 0 unsourced.** USHS-07 closed.
- Two honest-partials: Clay Fuller GA-14 (1 stance, special-election freshman) and Brian Jack GA-3 (8). All other 24 reps substantively covered.

## Self-Check: PASSED

## Files
- `backend/data/stance-research/2026-06-19-mi-house-batch-b.csv` (record CSV, 93 rows)
- `backend/data/stance-research/mi-house-b/` — 6 per-rep CSVs, `_TOPIC_SCALE.txt`, `_merge.ts`, `_push.ts`
