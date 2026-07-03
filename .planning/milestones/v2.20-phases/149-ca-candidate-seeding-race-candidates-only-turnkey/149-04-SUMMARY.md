---
phase: 149-ca-candidate-seeding-race-candidates-only-turnkey
plan: 04
subsystem: data
tags: [stances, federal-24, ca-house, chairs-not-polarity, evidence-only, honest-skip]
requirements-completed: [USHC-05]
completed: 2026-06-29
---

# Phase 149 Plan 04: CA-1..9 Federal-24 Stances Summary

Researched + primary-source-verified + pushed federal-24 chairs-not-polarity, evidence-only stances for the CA-1..9 in-scope set (15 candidates). **10 candidates stanced (144 answer+context rows, 0 unsourced); 5 whole-record honest-skips.** No party inference; values verified against documented votes/ratings.

## In-scope set (15) — result
| candidate | district | pid | fed24 topics | note |
|---|---|---|---|---|
| Jared Huffman | CA-2 | 960e5acd-… | 16 | D incumbent |
| Ami Bera | CA-3 | 0d635e23-… | 17 | D incumbent (Blue Dog — centrist values 3 on healthcare/SS/medicare) |
| Mike Thompson | CA-4 | 4466bd8c-… | 17 | D incumbent |
| Tom McClintock | CA-5 | f7704cd1-… | 21 | R incumbent (libertarian: ai=1, tariffs=3) |
| Kevin Kiley | CA-6 | 645a79be-… | 14 | left GOP→NPP; tariffs=3, redistricting=2, ukraine=2 (defied Trump) |
| Doris Matsui | CA-7 | 5be0c642-… | 17 | D incumbent |
| John Garamendi | CA-8 | 28eeeb86-… | 17 | D incumbent |
| Josh Harder | CA-9 | 3ab13c27-… | 16 | D incumbent (Central Valley moderate) |
| Richard Pan | CA-6 | 21664fc0-… | 8 | NEW; fmr CA state senator (SB277/276) |
| John McBride | CA-9 | 1bea8f46-… | 1 | NEW; campaign-site only (taxes=5) |

### Whole-record honest-skips (5) — PIN in 149-verify.sql `_stance_skip`
| candidate | district | pid | reason |
|---|---|---|---|
| Robin Littau | CA-2 | 810bce3f-817c-47f6-9b70-d2917e30ac3a | campaign site slogans only; no documentable chair on any topic |
| Robb Tucker | CA-3 | 5d028097-0ffc-41d9-aafb-b0d095f35ee4 | 1st-term county supervisor, no record; campaign site has no issue pages |
| Eric Jones | CA-4 | 9e28793b-bb53-433c-be6f-44db5bf2e780 | only an FEC filing; no campaign site/Ballotpedia/news |
| Michael Masuda | CA-5 | 0ae92a48-6bda-4e84-acf5-bcd04ad865b8 | campaign site unreachable; no fetchable platform |
| Rudy Recile | CA-8 | 24d474ef-9223-49b1-bf7d-3bdcd3678300 | all campaign-site variants ECONNREFUSED; no Ballotpedia/news |

## Verification pass (T-149-12 mandatory)
- Structural: repaired 6 malformed CSVs (documented trap — trailing-comma 11-col on bera/kiley/richard_pan/thompson/harder; quadruple-quote typo on thompson l17). All 145 rows then parsed clean, 0 structural issues.
- Primary-source re-fetch spot-checks: McBride campaign page (both quotes verbatim, BUT immigration=4 was a slogan over-read of "Stronger Southern Border" → **row deleted**); Kiley ukraine=2 confirmed (voted YES $1.3B, forced floor vote via discharge petition); Huffman campaign-finance quote verbatim-confirmed; McClintock climate + Garamendi taxes quote strings NOT locatable on cited URL (values independently sourced).
- **Quotes withheld from push** (deferred): could not verify ~quote strings at scale; aggregator quotes were ~60% verbatim-locatable on the exact cited URL. Pushed values + reasoning + sources only (0 quotes). Read & Rank quotes are a separate verified follow-up. See [[project-149-stance-gate-standard]].
- Rows deleted in verification: 1 (McBride immigration over-read).

## Push
- `_push_uuid.ts` (UUID-keyed): answers 144, contexts 144, quotes 0, leaks 0.
- 0-unsourced verified for all 10 batch pids.

## Self-Check: PASSED
- DB: 10 b1 pids carry federal-24 answers, 0 unsourced.
- 5 whole-record skips documented above for gate pinning.
