---
phase: 163-wi-co-al-sc-la-candidate-seeding-create-elections-races-then
plan: 10
title: CO + SC 2026 US House stances (consolidated)
status: complete
executed: 2026-07-05 (CO) / 2026-07-06 (SC)
execution_mode: 1 politician-stance-researcher agent per district, Sonnet, ≤3 concurrent (shared)
---

# 163-10 SUMMARY — CO + SC 2026 US House stances

**Result:** Both small decided states are stance-complete on PROD, 0 unsourced, chairs-not-polarity, primary-source-verified. CO (9 new candidates) and SC (16 new candidates) closed in one consolidated plan.

## CO half (executed 2026-07-05)
- **9/9 new CO candidates sourced, 50 answers, 0 unsourced, 0 whole-record skips.**
- Band -80899..-80101. Partial-tier CO incumbents (-8001..-8008) out of scope; DeGette (610bb358, lost-primary) not researched.
- Per-candidate: Rutinel 11, Romero 8, Killin 7, Laubacher 6, Kiros 5, Bennett 5, Dennison 4, Peterson 3, Clark 1.

## SC half (executed 2026-07-06)
- **13/16 new SC candidates sourced, 83 answers, 0 unsourced. 3 whole-record honest-skips (written trails in `sc-2026-house/_SKIPS.md`).**
- Band -450799..-450101. Partial-tier SC incumbents (-45002..-45007) out of scope; open-seat vacancies Mace (-45001) / Norman (-45005) are REUSE-NO-ROW (no active rows, nothing to research).
- 7 per-district agents, 3 waves @ ≤3 concurrency: W1 = SC-1/2/3, W2 = SC-4/5/6, W3 = SC-7. First wave validated (clean merge) before dispatching more.
- Per-candidate: Dittmer 12, McClain 11, Kaplan 11, Vincent 10, Lacore 9, Lehmacher 7, Khalifa 5, Reeside 5, Climer 5, Honeycutt 3, Corriea 3, Peterson 1, Oddo 1.

### SC whole-record skips (GATE-PIN for 163-11)
| external_id | name | district | reason |
|---|---|---|---|
| -450104 | Margo Ellis | SC-1 | Alliance Party nominee; no campaign site, Ballotpedia blank/403, all trackers stub pages, dormant socials — zero scoreable evidence |
| -450202 | Dayna Alane Smith | SC-2 | SC Workers Party sole nominee; only evidence was the SCWP party platform (party-inference). **Operator ruled 2026-07-06** that a party platform ≠ the candidate's own words even for a micro-party sole nominee → all 8 draft rows dropped |
| -450402 | Jessica Ethridge | SC-4 | Libertarian nominee; 3-plank Wix template too vague to pin; 2022 Lt-Gov-era positions (asset forfeiture, cannabis) don't map to the 24 federal keys |

## Standards applied (both states)
- Chairs-not-polarity; never party-inferred (Smith drop + several agent-level exclusions of collectively-attributed quotes, e.g. Vincent SC-7 religious-freedom).
- Every answer pairs to an `inform.politician_context` row with real fetched `sources[]`.
- iSideWith/AI-inferred sources excluded; recency rule applied (e.g. Dittmer abortion via 2023 activist statement, her most recent clear position).
- 0 surname leaks on push (both pushes).

## Files
- backend/data/stance-research/co-2026-house/ (scaffold + 163-10-co-stances.csv + _merged-co-2026-house.csv)
- backend/data/stance-research/sc-2026-house/ (scaffold, 16 per-candidate CSVs, _AGENT_BRIEF.md, _SKIPS.md, _merged-sc-2026-house.csv)
- _merge.ts IN_SCOPE = the 9 CO / 16 SC new-candidate bands; _push.ts/_push_uuid.ts state-agnostic (verbatim from mn-2026-house).

## For 163-11 gate
- CO 0-unsourced + 9/9 covered; SC 0-unsourced + 13/16 covered with the 3 pinned skips above.
- Live federal-24 topic count re-verified 2026-07-06 (24 keys; 44 total live topics − 20 non-federal).
