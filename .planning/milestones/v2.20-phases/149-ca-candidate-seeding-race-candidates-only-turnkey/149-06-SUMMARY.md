---
phase: 149-ca-candidate-seeding-race-candidates-only-turnkey
plan: 06
subsystem: data
tags: [stances, federal-24, ca-house, chairs-not-polarity, evidence-only, honest-skip]
requirements-completed: [USHC-05]
completed: 2026-06-29
---

# Phase 149 Plan 06: CA-19..26 Federal-24 Stances Summary

CA-19..26 in-scope set (13). **11 candidates stanced (120 rows, 0 unsourced); 2 whole-record honest-skips.** Values primary-source-verified; no party inference; quotes withheld (see [[project-149-stance-gate-standard]]).

## Stanced (11)
| candidate | district | pid | fed24 | note |
|---|---|---|---|---|
| Jimmy Panetta | CA-19 | 29a4c8f8-… | 19 | D inc |
| Jim Costa | CA-21 | 196e8502-… | 16 | D inc (Blue Dog: fossil-fuels=4 Keystone, estate-tax repeal) |
| Salud Carbajal | CA-24 | 565438e0-… | 14 | D inc (trans-athletes over-read deleted) |
| Vince Fong | CA-20 | e228243c-… | 7 | R inc freshman (sources 403-walled) |
| David Valadao | CA-22 | 42bff283-… | 14 | R inc moderate (abortion=3, RfMA yes, SSM=2) |
| Raul Ruiz | CA-25 | 5238b298-… | 15 | D inc |
| Randy Villegas | CA-22 | 36fad2d6-… | 15 | NEW; Visalia school board (progressive) |
| Peter Verbica | CA-19 | c8d2b53b-… | 8 | NEW; R, prior BoE candidate |
| Kyle Kirkland | CA-21 | d2ff9bbf-… | 5 | NEW; R, Fresno casino exec |
| Bob Smith | CA-24 | e85c17b3-… | 6 | NEW; R, Navy vet (identity confirmed) |
| Sam Gallucci | CA-26 | 9ca4ac11-… | 1 | NEW; R, only 1 documentable stance (deportation) |

### Whole-record honest-skips (2) — PIN in 149-verify.sql `_stance_skip`
| candidate | district | pid | reason |
|---|---|---|---|
| Sandra Van Scotter | CA-20 | c9712cc3-16cd-4817-a6cc-133dc5a387b4 | campaign site ECONNREFUSED; no Ballotpedia/news/FEC platform |
| Tessa Lynn Hodge | CA-23 | 36803909-3fa9-43e7-98d4-068f832c4a35 | all campaign domains dead; no Ballotpedia/news |

## Verification (T-149-12)
- Repaired trailing-comma malformations + 3 unquoted-reasoning rows in costa.csv (embedded commas "$5,000"/"Act, 2019" + embedded quote on Dobbs line). 121 rows then parsed clean, 0 issues.
- Deleted 1 over-read: Carbajal trans-athletes=1 (sourced to trans-healthcare-ban opposition, not a trans-sports position).
- Push: answers 120, contexts 120, quotes 0, leaks 0.

## Self-Check: PASSED — 11 b3 pids carry federal-24; 0 unsourced; 2 whole-record skips pinned above.
