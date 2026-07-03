---
phase: 149-ca-candidate-seeding-race-candidates-only-turnkey
plan: 08
subsystem: data
tags: [stances, federal-24, ca-house, chairs-not-polarity, evidence-only, honest-skip, same-party-general]
requirements-completed: [USHC-05]
completed: 2026-06-29
---

# Phase 149 Plan 08: CA-38..44 Federal-24 Stances Summary

CA-38..44 in-scope set (10), incl. the CA-40 R-vs-R same-party general (Calvert + Young Kim). **6 candidates stanced (74 rows, 0 unsourced); 4 whole-record honest-skips.** Values primary-source-verified; no party inference; quotes withheld.

## Stanced (6)
| candidate | district | pid | fed24 | note |
|---|---|---|---|---|
| Mark Takano | CA-39 | 0af35a49-… | 17 | D inc (trans-athletes=1 sourced to H.R.734 vote — real, kept) |
| Ken Calvert | CA-40 | 97b8516d-… | 18 | R inc (SSM=2 via 2022 RfMA vote, recency rule) |
| Young Kim | CA-40 | 504a0b06-… | 15 | R inc moderate (SSM=3 RfMA no; civil-rights=3) |
| Nanette Barragán | CA-44 | 5bd54ac0-… | 16 | D inc |
| Brian Burley | CA-42 | 00f01100-… | 3 | NEW; R, prior candidate, sparse site |
| Pedro Antonio Casas | CA-38 | 93d3b4e6-… | 5 | NEW; D, conservative-leaning (vouchers=4, trans-athletes=4, deportation=4) |

### Whole-record honest-skips (4) — PIN in 149-verify.sql `_stance_skip`
| candidate | district | pid | reason |
|---|---|---|---|
| Steve Manos | CA-39 | bc5be510-c286-4ab4-8f95-faa01fcaec27 | campaign site directory-only; Ballotpedia empty; no news |
| Mitch Clemmons | CA-41 | eb9c3296-90ef-4b6e-a4ed-bcd85a40c072 | campaign site no issues pages; no Ballotpedia/news; party unconfirmed |
| Cristian Morales | CA-43 | a4dd0a2c-564f-4e5c-9e1b-9bb942964cab | no reachable campaign site; no Ballotpedia/news |
| Genevieve Angel | CA-44 | ccf9173a-5288-4dad-ab4c-7f6f3dda4d2b | 23% primary (R); no reachable site; no Ballotpedia/news |

## Verification (T-149-12)
- Repaired trailing-comma malformations + quadruple-quote typos (calvert 12 occurrences) + dangling-quote (burley). 74 rows parsed clean, 0 issues.
- No value over-reads deleted this batch (Takano trans-athletes=1 KEPT — sourced to an actual H.R.734 vote, not caucus inference; Casas trans-athletes=4 KEPT — explicit campaign position).
- Push: answers 74, contexts 74, quotes 0, leaks 0.

## Self-Check: PASSED — 6 b5 pids carry federal-24; 0 unsourced; 4 whole-record skips pinned above.
