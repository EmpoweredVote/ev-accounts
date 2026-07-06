---
phase: 163-wi-co-al-sc-la-candidate-seeding-create-elections-races-then
plan: 09
title: LA 2026 US House stances
status: complete
executed: 2026-07-06
execution_mode: 1 politician-stance-researcher agent per district (7 agents incl. LA-5 split A/B, 3 waves @≤3 concurrent), Sonnet
---

# 163-09 SUMMARY — Louisiana 2026 US House stances

**Result:** LA's full 2026 US House new-candidate field is stance-complete on PROD — 0 unsourced, chairs-not-polarity, primary-source-verified, 0 surname leaks. This was the phase's heaviest slice (27 targets, LA-5 open seat = 13 filers). INCLUDES LA-2 + LA-6 severe/withheld-district candidates. LA runs a JUNGLE primary — party was never a stance shortcut.

## Coverage
- **22/27 new LA candidates sourced, 109 federal-24 answers, 0 unsourced. 5 whole-record honest-skips.**
- Band -220699..-220101 (fips 22). LA incumbents (-22001..-22006) all partial-tier → out of scope.
- 7 per-district agents (LA-5's 13 split into batch A[7]+B[6]), 3 waves @ ≤3 concurrency: W1 = LA-1/2/3, W2 = LA-4/6/5a, W3 = LA-5b. Each wave pushed to PROD on completion.

### Per-candidate row counts (on PROD)
- LA-1 (vs Scalise): **Arrington SKIP, Long SKIP** (both no findable policy content)
- LA-2 (WITHHELD/severe, vs Carter): **Collins SKIP** (one-page shell site)
- LA-3 (vs Higgins): LeBrun 8, Day 7; **Walker SKIP**
- LA-4 (vs Speaker Johnson): Morott 13 (R), Gromlich 6 (D), Cable 5 (D), Nichols 2 (R)
- LA-5 (OPEN — Letlow→Senate, 13-candidate field): Echols 7 (R), Fleenor 7 (D), Foy 7 (D), Nyman 7 (D), Garcia 6 (D), Cordell 5 (R), Wyatt 5 (R), Mebruer 4 (R), Firment 3 (R), Miguez 3 (R), Edmonds 2 (R), McKay 2 (D), Magee 1 (R)
- LA-6 (WITHHELD/severe, vs Fields): Davis 7 (R), Appeaning 1 (R), Johnson 1 (R); **Williams SKIP**

### Whole-record skips (GATE-PIN for 163-11) — all trails in `la-2026-house/_SKIPS.md`
| external_id | name | district | reason |
|---|---|---|---|
| -220101 | Randall Arrington | LA-1 | R; only party self-ID, no policy content; Ballotpedia walled, BallotReady/CandidateRanking "no positions", no site |
| -220102 | Jim Long | LA-1 | D; zero issue content anywhere; collision-avoided a diff-spelled "Jim Lange" |
| -220201 | Renada Collins | LA-2 | D; campaign site is a one-page shell (/issues,/platform,/about all 404); one general dignity quote, no scale fit |
| -220303 | Caleb Walker | LA-3 | no site; socials login-walled; only a "Patients Over Profits" pledge (too indirect); debate video unextractable |
| -220604 | Peter Williams | LA-6 | R (perennial, ex-D); identity well-verified but only generic constituent-advocacy language, no scale-mappable specifics |

## Standards applied
- Chairs-not-polarity; never party-inferred (jungle ballot — explicitly held the bar: Morott campaign-finance=2 against party-typical assumption; McKay's "Conservative Louisianan" X bio re-verified against his Democratic registration before use).
- Domain-collision / identity guarded: Chris Johnson (LA-6, FEC H6LA06141 = Christian Rashad Johnson), Jim Long (avoided "Jim Lange"), Conrad Cable (real domain conrad4congress2026.com).
- Sources: campaign sites (rarely name-guessable in LA — found via DuckDuckGo-via-jina), sitting-legislator bill authorship (Miguez SB208, Firment HB419, Edmonds SB313/GATOR), bayouprogressive.com forum coverage (LA-5 Dem field), BallotReady. Ballotpedia fully dead for LA; FEC DEMO_KEY rate-limited.

## Flags for downstream
- **⚠ SEED MIS-KEY — Rick Edmonds (-220503):** seeded under LA-5, but his own site + Ballotpedia say he's running for **LA-6** (Letlow's old seat). Combined with Larry Davis (-220602) who "switched LA-5→LA-6 in Feb 2026," there is real LA-5/LA-6 filing churn. Edmonds' stances (school-vouchers/taxes) are valid regardless of district. **Recommend operator verify Edmonds' district vs the 163-06 seed and re-key if needed (Phase-167 / 164.1 cross-state work).**
- **FIELD-DATA — Tia LeBrun (-220302):** switched registration D→No Party (~June 2026, per Bayou Progressive) — do not label Democrat; note for the 167 re-pull.
- LA-2 + LA-6 candidates are on the WITHHELD "Polygon Pending" election per 163-06 seed (severe districts, hidden from /elections; stances complete regardless).
- LA jungle primary Nov 2026; *Callais* redistricting case → a gubernatorial attempt to suspend the 2026 congressional primary was a live LA-5 issue (scored under redistricting). Post-election cull applies.

## Files
- backend/data/stance-research/la-2026-house/ (scaffold, 27 per-candidate CSVs, _AGENT_BRIEF.md, _SKIPS.md, _merged-la-2026-house.csv)
- _merge.ts IN_SCOPE = the 27 LA new-candidate band (incl. LA-2/LA-6 withheld); _push.ts/_push_uuid.ts state-agnostic.

## For 163-11 gate
- LA 0-unsourced + 22/27 covered with the 5 pinned skips above.
- Confirm LA exactly-6-jungle-races (primary_party NULL) still holds; LA-2/LA-6 on withheld election.
- **Resolve the Edmonds -220503 LA-5-vs-LA-6 district question before the gate's per-district race-count assertions.**
