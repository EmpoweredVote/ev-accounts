---
phase: 149-ca-candidate-seeding-race-candidates-only-turnkey
plan: 10
subsystem: data
tags: [stances, federal-24, ca-house, chairs-not-polarity, evidence-only, honest-skip]
requirements-completed: [USHC-05]
completed: 2026-06-29
---

# Phase 149 Plan 10: CA-49..52 Federal-24 Stances Summary (final stance batch)

CA-49..52 in-scope set (7). **5 candidates stanced (69 rows, 0 unsourced); 2 whole-record honest-skips.**

## Stanced (5)
| candidate | district | pid | fed24 | note |
|---|---|---|---|---|
| Mike Levin | CA-49 | 821be1ee-… | 18 | D inc |
| Scott Peters | CA-50 | 3a9072fc-… | 15 | D inc moderate New Dem (trans-athletes over-read deleted; healthcare=3 pharma signal) |
| Sara Jacobs | CA-51 | 51e4c723-… | 14 | D inc progressive |
| Juan Vargas | CA-52 | afa3cab9-… | 15 | D inc (tariffs=1 free-trade) |
| Armen Kurdian | CA-49 | 9167576d-… | 7 | NEW; R, Navy vet |

### Whole-record honest-skips (2) — PIN in 149-verify.sql `_stance_skip`
| candidate | district | pid | reason |
|---|---|---|---|
| Richardo Cabrera | CA-51 | 89d14c56-e548-4afa-9977-06c2e94d8718 | no live campaign site/FEC/Ballotpedia; only an Instagram handle |
| Jeff Belle | CA-52 | 501169b7-ff66-42fe-a65d-0fa399169798 | no discoverable public policy record |

## Verification (T-149-12)
- Repaired trailing-comma/quad-quote; 70 rows parsed clean, 0 issues.
- Deleted 1 over-read: Peters trans-athletes=3 (sourced to a 2016 "don't elevate gender identity as protected class" statement, not a sports-eligibility position).
- Push: answers 69, contexts 69, quotes 0, leaks 0.

## Self-Check: PASSED — 5 b7 pids carry federal-24; 0 unsourced; 2 whole-record skips pinned.
