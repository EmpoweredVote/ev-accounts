---
phase: 136-wi-al-sc-ky-house-rep-stances
status: passed
requirements: [USHS-10]
verified: 2026-06-19
---

# Phase 136 Verification — WI + AL + SC + KY House Rep Stances

**Status: PASSED** (goal-backward, evidence from production `kxsdzaojfaibhuzmclfq`)

## Phase Goal

All in-scope WI (8) + AL (7) + SC (7) + KY (6) US House reps = **28 reps** have sourced compass stances, each backed by a real source URL.

## Success Criteria

| # | Criterion | Result |
|---|-----------|--------|
| 1 | Every in-scope rep (28, no pre-existing answers) has ≥1 sourced stance | **PASS** — phase-wide query: reps=28, reps_with_answers=28, total_answers=367 |
| 2 | Every answer row has a paired sourced `inform.politician_context` row — zero unsourced | **PASS** — unsourced_inscope=0 (verified per-scope per batch AND phase-wide) |
| 3 | No-evidence topics honest-skipped per rep; no party-inference | **PASS** — freshman honest-partials (Figures AL-2, Biggs SC-3, Wied WI-8) + source-blocked honest-partials (Fry SC-7=3, McGarvey KY-3=6); 4 over-read SSM=5 rows dropped (Timmons SC-4, Norman SC-5 — Equality-Act-opposition only); kept vote-backed SSM=5 (Rogers AL-3, Aderholt AL-4, Harold Rogers KY-5, Barr KY-6) |

## Coverage by batch (per-scope external_id verification)

| Plan | Scope | external_id | Reps | Answers |
|------|-------|-------------|------|---------|
| 136-01 | WI-A | −55001..−55004 | 4 | 62 |
| 136-02 | WI-B | −55005..−55008 | 4 | 42 |
| 136-03 | AL-A | −1001..−1004 | 4 | 34 |
| 136-04 | AL-B | −1005..−1007 | 3 | 50 |
| 136-05 | SC-A | −45001..−45004 | 4 | 55 |
| 136-06 | SC-B | −45005..−45007 | 3 | 37 |
| 136-07 | KY-A | −21001..−21003 | 3 | 35 |
| 136-08 | KY-B | −21004..−21006 | 3 | 52 |
| **Total** | | | **28** | **367** |

## Method integrity

- Five-chairs / evidence-over-party framing; values matched to the per-topic 1–5 stance texts (25 federal topics), never party-inferred.
- AL single-thousands external_id range (−1001..−1007) handled correctly; merge flagged 0 out-of-scope rows; no collision with other states (push keys on literal external_id).
- SSM=5 calibration discipline applied: dropped over-reads resting on Equality-Act-opposition alone (Timmons, Norman); retained those with documented constitutional-amendment votes/positions (Rogers AL, Aderholt, Harold Rogers, Barr).
- isidewith-only rows dropped; Fry re-researched once before accepting the honest 3-topic result.
- Push isolation verified via per-scope external_id counts (not the global counter).
- 3-concurrency held throughout; WebFetch-only.

USHS-10 closed.
