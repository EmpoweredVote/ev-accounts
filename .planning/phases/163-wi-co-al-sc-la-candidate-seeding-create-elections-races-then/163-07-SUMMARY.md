---
phase: 163-wi-co-al-sc-la-candidate-seeding-create-elections-races-then
plan: 07
title: WI 2026 US House stances
status: complete
executed: 2026-07-06
execution_mode: 1 politician-stance-researcher agent per district (8 agents, 3 waves @≤3 concurrent), Sonnet
---

# 163-07 SUMMARY — Wisconsin 2026 US House stances

**Result:** WI's full 2026 US House new-candidate field is stance-complete on PROD — 0 unsourced, chairs-not-polarity, primary-source-verified, 0 surname leaks.

## Coverage
- **27/28 new WI candidates sourced, 162 federal-24 answers, 0 unsourced. 1 whole-record honest-skip.**
- Band -550899..-550101 (fips 55). All incumbents reused from prior seeds are out of scope; WI-7 is an OPEN seat (Tiffany → Governor).
- 8 per-district agents, 3 waves @ ≤3 concurrency: W1 = WI-1/2/3, W2 = WI-4/5/6, W3 = WI-7/8. First wave validated (clean merge) before fanning out. Each wave pushed to PROD on completion (resilience — CSVs gitignored).

### Per-candidate row counts (on PROD)
- WI-1 (D primary vs Steil): Santos 15, Aranda 8, Burgelis 4, Berman 1
- WI-2 (D vs Pocan): Alexander 3
- WI-3 (swing, vs Van Orden): Berge 12, Cooke 8, Provance 4 (I)
- WI-4 (D+R+I vs Moore): Donahue 7, Rogers 2 (R), Burks 2 (I); **Nath — SKIP**
- WI-5 (D vs Fitzgerald): Beck 6
- WI-6 (open field vs Grothman): Bell 10 (D), Thurow 6 (I), Smith 4 (D), Fitzgibbon 4 (I/L-endorsed), Arndt 3 (Green)
- WI-7 (OPEN, Tiffany→Gov): Clark 11 (D), Alfonso 7 (R), Baum 7 (R), Armstrong 7 (D), Murray 4 (D), Ebben 3 (R), Hermening 3 (R)
- WI-8 (D primary vs Wied): Crosson 8, deVille 7, Scheffler 6

### Whole-record skip (GATE-PIN for 163-11)
| external_id | name | district | reason |
|---|---|---|---|
| -550402 | Purnima Nath | WI-4 | Republican primary challenger to Moore (FEC H4WI04282); site is identity/culture-war content (Hindu-American advocacy, foreign-policy criticism) with no language mapping to any 1–5 anchor on the 24 topics. Trail in `wi-2026-house/_SKIPS.md`. |

## Standards applied
- Chairs-not-polarity; never party-inferred. Multiple agent-level exclusions of vague/collective statements (e.g. Alexander's explicit abortion non-position; Beck's commemorative Pride posts; deVille's one-word "Body Autonomy").
- Domain-collision guarded: Provance (WI-3, discarded a same-name Knudtson site), Armstrong (WI-7, cleared vs a Dane County homonym), Arndt (WI-6, endthecartel.com verified via FEC), Murray (WI-7, real site gingerforus.com). Beck: unverifiable aggregator claims (localcandidates.org) excluded.
- Sources: campaign sites, verified Bluesky (AT Protocol public API), BallotReady, local news, FEC committee records. iSideWith/AI-inferred/aggregator claims excluded. Recency rule applied (Alexander's 2022 issues content = his currently-linked material).

## Flags for downstream
- **SEED-GAP (Phase-167):** WI-8 has a 4th Democrat, **Benjamin Hable**, reported running but NOT in the seeded field — verify + backfill on the post-primary re-pull.
- Aug-11-2026 WI primary → PROVISIONAL/loser cull after that date (consistent with prior phases). These are seeded primary fields.
- Ballotpedia was jina/proxy-walled for most WI races (known behavior); campaign sites + Bluesky + FEC carried the load.

## Files
- backend/data/stance-research/wi-2026-house/ (scaffold, 28 per-candidate CSVs, _AGENT_BRIEF.md, _SKIPS.md, _merged-wi-2026-house.csv)
- _merge.ts IN_SCOPE = the 28 WI new-candidate band; _push.ts/_push_uuid.ts state-agnostic.

## For 163-11 gate
- WI 0-unsourced + 27/28 covered with the 1 pinned skip (Nath -550402) above.
