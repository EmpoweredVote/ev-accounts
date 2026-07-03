---
phase: 149-ca-candidate-seeding-race-candidates-only-turnkey
plan: 09
subsystem: data
tags: [stances, federal-24, ca-house, chairs-not-polarity, evidence-only, honest-skip]
requirements-completed: [USHC-05]
completed: 2026-06-29
---

# Phase 149 Plan 09: CA-45..48 Federal-24 Stances Summary

CA-45..48 in-scope set (6). **5 candidates stanced (45 rows, 0 unsourced); 1 whole-record honest-skip.**

## Stanced (5)
| candidate | district | pid | fed24 | note |
|---|---|---|---|---|
| Lou Correa | CA-46 | c06165d2-… | 15 | D inc (moderate/Problem Solvers) |
| Dave Min | CA-47 | 59b9f70a-… | 12 | D inc freshman (fmr state senator) |
| Jim Desmond | CA-48 | 16b7ad30-… | 6 | NEW; R, SD County Supervisor (misinformation over-read deleted) |
| David Pan | CA-46 | 8ef374f4-… | 6 | NEW; conservative challenger (privatize Medicare/SS) |
| Jenny Le Roux | CA-47 | d4b3447f-… | 6 | NEW; R |

### Whole-record honest-skips (1) — PIN in 149-verify.sql `_stance_skip`
| candidate | district | pid | reason |
|---|---|---|---|
| Chuong Vo | CA-45 | f74dcb04-a66f-47c4-8da4-bae285acf0f1 | campaign site under-construction placeholder; not on current Cerritos council page; no Ballotpedia/news |

## Verification (T-149-12)
- Repaired trailing-comma + quadruple-quote (leroux); 46 rows parsed clean, 0 issues.
- Deleted 1 over-read: Desmond misinformation=5 (sourced to COVID-skepticism/anti-mandate, not a content-moderation/platform-regulation position).
- Push: answers 45, contexts 45, quotes 0, leaks 0.

## Self-Check: PASSED — 5 b6 pids carry federal-24; 0 unsourced; 1 whole-record skip pinned.
