---
phase: 163-wi-co-al-sc-la-candidate-seeding-create-elections-races-then
plan: 08
title: AL 2026 US House stances
status: complete
executed: 2026-07-06
execution_mode: 1 politician-stance-researcher agent per district (7 agents, 3 waves @≤3 concurrent), Sonnet
---

# 163-08 SUMMARY — Alabama 2026 US House stances

**Result:** AL's full 2026 US House new-candidate field is stance-complete on PROD — 0 unsourced, chairs-not-polarity, primary-source-verified, 0 surname leaks. INCLUDES AL-2 severe/withheld-district candidates (race hidden from /elections, stances still complete).

## Coverage
- **20/21 new AL candidates sourced, 97 federal-24 answers, 0 unsourced. 1 whole-record honest-skip.**
- Band -10799..-10101 (fips 01). AL incumbents (-1001..-1007) all partial-tier → out of scope.
- 7 per-district agents, 3 waves @ ≤3 concurrency: W1 = AL-1/2/3, W2 = AL-4/5/6, W3 = AL-7. Each wave pushed to PROD on completion.

### Per-candidate row counts (on PROD)
- AL-1 (OPEN — Moore→Senate): Carl 12 (R, ex-Rep, congressional record), Mills 5 (R), Jones 5 (D nominee), Sidwell 4 (R); **Burger — SKIP**
- AL-2 (SPECIAL, withheld/severe — GOP special primary): Marques 6, McKee 6, Harris 3, Richardson 3, Matthews 2, Horn 1 (all R)
- AL-3 (D vs Rogers): McInnis 6
- AL-4 (D vs Aderholt): Pusczek 11
- AL-5 (D vs Strong): Sneed 8
- AL-6 (SPECIAL — Palmer's seat open): Dixon 6 (R), Mercer 5 (D), Bouma-Sims 4 (D), Kennedy 4 (D), Pilkington 4 (D)
- AL-7 (SPECIAL — GOP special primary): Akin 1 (R), Perry 1 (R)

### Whole-record skip (GATE-PIN for 163-11)
| external_id | name | district | reason |
|---|---|---|---|
| -10101 | Lucas Burger | AL-1 | R primary candidate; no campaign website, Ballotpedia/BallotReady/GoodParty profiles all empty of policy content. Trail in `al-2026-house/_SKIPS.md`. |

## Standards applied
- Chairs-not-polarity; never party-inferred (AL-2's 6 GOP challengers scored ONLY from their own thin sites — 4/6 had generic "secure the border" language → immigration/deportation skipped, not inferred).
- Wrong-person / domain-collision guarded: David Perry (AL-7, discarded a same-name finance exec's bio), Bouma-Sims (AL-6, located real site via search).
- Hostile-source exclusion: Ashtyn Kennedy (AL-6, a 1819News personal-conduct allegation excluded — not a stated policy position).
- AI-inferred aggregators (GoodParty/Civoren/Branch.vote) excluded; recency rule applied.

## Flags for downstream
- **SPECIAL ELECTIONS (data-model note):** AL-2, AL-6, and AL-7 candidates are running in **Aug-11-2026 SPECIAL primaries** (AL-2 = redrawn Black-opportunity seat; AL-6 = Palmer open; AL-7 = per agent, GOP special primary vs Sewell). AL-1 is an open seat (Moore→Senate). Confirm the seeded election/race framing matches "special" where applicable during the 163-11 gate.
- **http-only source (T-check):** Jacob Bouma-Sims (-10602, AL-6) sources are `http://jacob4aldistrict6.com` — his host's TLS cert is misconfigured (issued for the shared-panel domain), so https genuinely fails. `_merge.ts` accepts `https?://` so it passed; flagged in case any downstream validation is https-only.
- **FEC DEMO_KEY exhausted (429) mid-run** — AL-2/AL-6 agents fell back to campaign sites + algop.org + BallotReady. No coverage lost, but party/status was verified via secondary sources for a few candidates.
- Aug-11-2026 primaries → PROVISIONAL/loser cull after that date.

## Files
- backend/data/stance-research/al-2026-house/ (scaffold, 21 per-candidate CSVs, _AGENT_BRIEF.md, _SKIPS.md, _merged-al-2026-house.csv)
- _merge.ts IN_SCOPE = the 21 AL new-candidate band (incl. AL-2 withheld); _push.ts/_push_uuid.ts state-agnostic.

## For 163-11 gate
- AL 0-unsourced + 20/21 covered with the 1 pinned skip (Burger -10101) above.
- AL-2/AL-6/AL-7 special-election framing to confirm; AL-2 candidates on the withheld "Polygon Pending" election per 163-04 seed.
