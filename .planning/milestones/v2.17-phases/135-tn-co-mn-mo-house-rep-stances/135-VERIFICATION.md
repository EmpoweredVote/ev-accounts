---
phase: 135-tn-co-mn-mo-house-rep-stances
status: passed
requirements: [USHS-09]
verified: 2026-06-19
---

# Phase 135 Verification — TN + CO + MN + MO House Rep Stances

**Status: PASSED** (goal-backward, evidence from production `kxsdzaojfaibhuzmclfq`)

## Phase Goal

All in-scope TN (9) + CO (8) + MN (8) + MO (8) US House reps = **33 reps** have sourced compass stances, each backed by a real source URL.

## Success Criteria

| # | Criterion | Result |
|---|-----------|--------|
| 1 | Every in-scope rep (33, no pre-existing answers) has ≥1 sourced stance | **PASS** — phase-wide query: reps=33, reps_with_answers=33, total_answers=418 |
| 2 | Every answer row has a paired `inform.politician_context` row with a real source URL — zero unsourced | **PASS** — unsourced_inscope=0 (verified per-scope per batch AND phase-wide) |
| 3 | No-evidence topics honest-skipped per rep; no party-inference | **PASS** — honest-partials documented (freshmen + source-blocked incumbents); 3 over-read rows dropped (Rose SSM, Onder SSM, Crank religious-freedom) for leaning on indirect/group evidence rather than the documented chair |

## Coverage by batch (per-scope external_id verification)

| Plan | Scope | external_id | Reps | Answers |
|------|-------|-------------|------|---------|
| 135-01 | TN-A | −47001..−47005 | 5 | 74 |
| 135-02 | TN-B | −47006..−47009 | 4 | 53 |
| 135-03 | CO-A | −8001..−8004 | 4 | 62 |
| 135-04 | CO-B | −8005..−8008 | 4 | 33 |
| 135-05 | MN-A | −27001..−27004 | 4 | 45 |
| 135-06 | MN-B | −27005..−27008 | 4 | 64 |
| 135-07 | MO-A | −29001..−29004 | 4 | 31 |
| 135-08 | MO-B | −29005..−29008 | 4 | 56 |
| **Total** | | | **33** | **418** |

## Method integrity

- Five-chairs / evidence-over-party framing; values matched to the per-topic 1–5 stance texts (25 federal topics), never party-inferred.
- isidewith-only rows dropped; freshmen (Van Epps, Hurd, Crank, Evans, Morrison, Bell, Onder) became honest-partials as expected.
- Push isolation verified via per-scope external_id counts (not the global counter, which drifts from concurrent prod jobs).
- 3-concurrency held throughout; WebFetch-only.

USHS-09 closed.
