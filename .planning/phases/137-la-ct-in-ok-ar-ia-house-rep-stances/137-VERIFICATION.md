---
phase: 137-la-ct-in-ok-ar-ia-house-rep-stances
status: passed
requirements: [USHS-11]
verified: 2026-06-20
---

# Phase 137 Verification — LA + CT + IN + OK + AR + IA House Rep Stances

**Status: PASSED** (goal-backward, evidence from production `kxsdzaojfaibhuzmclfq`)

## Phase Goal

All in-scope LA (6) + CT (5) + IN (5) + OK (5) + AR (4) + IA (4) US House reps = **29 reps** have sourced compass stances, each backed by a real source URL.

## Success Criteria

| # | Criterion | Result |
|---|-----------|--------|
| 1 | Every in-scope rep (29, no pre-existing answers) has ≥1 sourced stance | **PASS** — phase-wide query: reps=29, reps_with_answers=29, total_answers=339 |
| 2 | Every answer row has a paired sourced context row — zero unsourced | **PASS** — unsourced_inscope=0 (per-scope per batch AND phase-wide) |
| 3 | No-evidence topics honest-skipped per rep; no party-inference | **PASS** — freshman/returning honest-partials (Cleo Fields LA-6, Shreve IN-6, Stutzman IN-3); source-blocked honest-partials (Lucas OK-3=3, Himes CT-4=7, Spartz IN-5=5); over-read drops (Letlow LA-5 vouchers, Hern OK-1 SSM) |

## Coverage by batch (per-scope external_id verification)

| Plan | State | external_id | Reps | Answers |
|------|-------|-------------|------|---------|
| 137-01 | LA | −22001..−22006 | 6 | 69 |
| 137-02 | CT | −9001..−9005 | 5 | 70 |
| 137-03 | IN | −18001,−18002,−18003,−18005,−18006 (non-contiguous) | 5 | 49 |
| 137-04 | OK | −40001..−40005 | 5 | 49 |
| 137-05 | AR | −5001..−5004 (single-thousands) | 4 | 61 |
| 137-06 | IA | −19001..−19004 | 4 | 41 |
| **Total** | | | **29** | **339** |

## Method integrity

- Five-chairs / evidence-over-party framing; values matched to the per-topic 1–5 stance texts (25 federal topics), never party-inferred.
- **IN non-contiguous set held** — −18004 confirmed absent from the merged CSV; IN-4 untouched.
- **AR single-thousands range** (−5001..−5004) handled; merge IN_SCOPE held.
- SSM=5 calibration discipline applied (now 8 drops across 135–137): KEPT vote/amendment-backed (Scalise LA-1 authored amendment, Higgins LA-3 anti-RFMA, Stutzman IN-3 + Cole OK-4 + Westerman AR-4 constitutional-amendment votes; Johnson LA-4 correctly self-placed at 4); DROPPED belief-quote/Equality-Act-only (Hern OK-1); agents correctly auto-skipped/capped SSM for Yakym IN-2, Miller-Meeks IA-1, Feenstra IA-4.
- CSV artifacts repaired: stray-trailing-quote (`,"`→`,`) on Crawford; malformed quote-wrap (`""text""`) on Feenstra.
- Push isolation verified via per-scope external_id counts (not the global counter).

## Execution note

The IN batch's Shreve research agent hung ~6.5h on a WebFetch stall before returning valid output; subsequent agents ran under an explicit "try each URL once, no retry" instruction and completed in 1–5 min each. No data lost.

USHS-11 closed.
