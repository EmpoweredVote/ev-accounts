---
phase: 149-ca-candidate-seeding-race-candidates-only-turnkey
plan: 05
subsystem: data
tags: [stances, federal-24, ca-house, chairs-not-polarity, evidence-only, honest-skip]
requirements-completed: [USHC-05]
completed: 2026-06-29
---

# Phase 149 Plan 05: CA-10..18 Federal-24 Stances Summary

CA-10..18 in-scope set (15). **12 candidates stanced (146 rows, 0 unsourced); 3 whole-record honest-skips.** Values primary-source-verified; no party inference; quotes withheld pending verified pass (see [[project-149-stance-gate-standard]]).

## Stanced (12)
| candidate | district | pid | fed24 | note |
|---|---|---|---|---|
| Mark DeSaulnier | CA-10 | bc29096f-… | 22 | D inc |
| Lateefah Simon | CA-12 | 39db6eee-… | 19 | D inc |
| Adam Gray | CA-13 | 1b473093-… | 9 | D inc (Central Valley moderate; redistricting over-read deleted) |
| Kevin Mullin | CA-15 | 9c880377-… | 9 | D inc |
| Sam Liccardo | CA-16 | 7ceb0371-… | 10 | D inc (fmr SJ mayor; congressional sources 403-walled) |
| Ro Khanna | CA-17 | 07255876-… | 19 | D inc (trans-athletes inference deleted) |
| Zoe Lofgren | CA-18 | 956281d7-… | 22 | D inc |
| Kevin Lincoln | CA-13 | bb10c11e-… | 6 | NEW; fmr Stockton mayor (R) |
| Jamie Joyce | CA-12 | 580f3720-… | 4 | NEW |
| Peter Sundin Soulé | CA-16 | dfcad8ca-… | 7 | NEW |
| Ritesh Tandon | CA-17 | 31e72d49-… | 14 | NEW; repeat challenger, developed policy site |
| Shane Lewis | CA-18 | f7f3750b-… | 5 | NEW |

### Whole-record honest-skips (3) — PIN in 149-verify.sql `_stance_skip`
| candidate | district | pid | reason |
|---|---|---|---|
| Jeff Frese | CA-10 | 8e0e5b01-94f4-46a5-b998-28ebfd1b1f4e | no campaign web presence; no Ballotpedia/news |
| Melissa Hernandez | CA-14 | 89e9dcfa-bf12-4eb4-922d-42e56272d9d5 | 17.2% primary (didn't advance); campaign sites ECONNREFUSED; no platform |
| Charles Hoelter | CA-15 | 15d4989e-34bd-4901-bdb5-d7bb11b0f1b6 | paper-filing challenger, $0 raised, no platform |

## Verification (T-149-12)
- Repaired 9 trailing-comma-malformed CSVs; 148 rows then parsed clean, 0 structural issues.
- Deleted 2 over-reads: Khanna trans-athletes=1 (agent self-flagged as inferred from general LGBTQ advocacy, no trans-sports position); Gray redistricting=2 (agent: indirect "a reach").
- Spot-checks verbatim-confirmed: DeSaulnier abortion + trans-athletes quotes on OnTheIssues.
- Push: answers 146, contexts 146, quotes 0, leaks 0.

## Self-Check: PASSED — 12 b2 pids carry federal-24; 0 unsourced; 3 whole-record skips pinned above.
