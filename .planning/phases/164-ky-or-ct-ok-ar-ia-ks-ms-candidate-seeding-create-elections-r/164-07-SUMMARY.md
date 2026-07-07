---
phase: 164-ky-or-ct-ok-ar-ia-ks-ms-candidate-seeding-create-elections-r
plan: 07
state: KS
status: complete
completed: 2026-07-06
requirements: [USHC3-05]
federal_24_count: 24
---

# 164-07 SUMMARY — KS Stances

## Result
All 22 new KS candidates resolved on **PROD**: **18 stance-complete (90 sourced answers), 4 gate-pinned whole-record skips**, 0 unsourced, 0 surname leaks. Federal-24 topic set verified LIVE (44 active − 20 non-federal = 24; unchanged since phase 162).

## Pipeline
- Scaffold `ks-2026-house/` (copied `_merge/_push/_push_uuid.ts` + `_TOPIC_SCALE_FULL.txt` from mn-2026-house; `_merge.ts` IN_SCOPE retargeted to the 22 KS ids; `_AGENT_BRIEF.md` written).
- 6 `politician-stance-researcher` agents (Sonnet) at 3-concurrency, 1 per district (KS-4 split into 2). Wave A (KS-1/2/3) validated (0 merge problems) before Wave B (KS-4a/4b).
- Merge: 18 files, 90 rows, 0 problems. Push (`_push.ts`): 90 answers + 90 contexts + 69 quotes, 0 leaks. Gate: 0 unsourced (context sources non-empty for every answer).

## Per-candidate row counts (18 covered)
McRoberts 9, Reinhold 6, Musser 5, Jacob 3 (KS-1); Young 3, Coover 2, Curwick 3 (KS-2); Preu 10, Jenkins 5, LaPorte 2 (KS-3); McCollum 3, Carmichael 7, Tyndell 7, Epley 5, Gilbert 11, J.Mitchell 5, Cranmer 3, Catanese 1 (KS-4).

## Whole-record skips (gate-pinned for 164-13, trails in `_SKIPS.md`)
- **-200304 Gavin Solomon** — serial multi-state congressional filer (NY-12 2024; FL-27/TX-26/CA-27/OH-01/CT-4/TX-Sen 2026), zero Kansas footprint, no platform anywhere.
- **-200305 Blake Stanley** — FEC committee C00925412 terminated; no site/social/news/positions.
- **-200401 Michael Gaynor** — fringe filer, no locatable web presence/platform.
- **-200408 Daniel Schneider** — withdrew from KS-4 (Ballotpedia "withdrawn/disqualified"); pivoted to a KS state-house race → federal-race skip (avoid misattributing a state platform).

## Notable evidence-integrity calls (by agents, verified)
- Jordan Mitchell (-200407): dodged a "Jordan Metcalf" homonym; identity confirmed via Wayback of expired `jordanmitchellforcongress.org`.
- Eric Jenkins / Cole Epley: JS-SPA sites returned inconsistent "verbatim" text across fetches → `quote_text` left blank, reasoning kept description-only.
- Chad Young: journalist paraphrase corrected to blank quote (not misattributed).
- Cole Epley: suspended + endorsed Carmichael but remains on the Aug-4 ballot → legitimate partial record, not a skip.

## Files (CSVs gitignored → PROD is durable store)
`backend/data/stance-research/ks-2026-house/`: `_merge.ts`, `_push.ts`, `_push_uuid.ts`, `_AGENT_BRIEF.md`, `_TOPIC_SCALE_FULL.txt`, `_SKIPS.md` (+ gitignored per-candidate CSVs + `_merged-ks-2026-house.csv`).

## Self-Check: PASSED
0 unsourced on prod; 18/22 stance-complete; 4 skips with written trails; ≤3 concurrency; primary-source verification pass per agent; no partial-tier incumbent topped up.
