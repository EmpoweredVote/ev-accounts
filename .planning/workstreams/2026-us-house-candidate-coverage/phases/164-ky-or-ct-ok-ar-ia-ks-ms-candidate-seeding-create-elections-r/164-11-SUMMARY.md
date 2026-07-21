---
phase: 164-ky-or-ct-ok-ar-ia-ks-ms-candidate-seeding-create-elections-r
plan: 11
state: OK+IA
status: complete
completed: 2026-07-06
requirements: [USHC3-05]
---

# 164-11 SUMMARY — OK + IA Stances

Two decided states, pushed per state to **PROD**. 0 unsourced, 0 surname leaks throughout.

## OK — 7/10 stance-complete (47 sourced answers), 3 whole-record skips
- Scaffold `ok-2026-house/` (IN_SCOPE = 10 OK ids; band capped so the 43 US-Senate-cycle records at -400101..-400143 are excluded). 2 agents (OK-1/2/3, OK-4/5). Merge: 7 files, 47 rows, 0 problems. Push: 47 answers/47 contexts/38 quotes, 0 leaks. Gate: 0 unsourced.
- Per-candidate: Tedford 8, Croisant 14, Wade 10, Byrd 3 (OK-1/2/3); Jacob 6, Nelson 5, Henri 1 (OK-4/5).
- **Skips (gate-pinned, trails in `_SKIPS.md`):** -400202 Ronnie Hopkins (2026 site 404; only an inferred ukraine row from stale 2024 "cut foreign aid" — dropped per no-inference, then skipped), -400402 Rocco Bonacci (no FEC/site, disability-advocacy coverage only), -400503 Austin Nieves (no FEC/site, prior run withdrawn).

## IA — 9/9 stance-complete (73 sourced answers), 0 skips
- Scaffold `ia-2026-house/` (IN_SCOPE = 9 IA ids; band was empty pre-seed). 2 agents (IA-1/2, IA-3/4). Merge: 9 files, 73 rows, 0 problems. Push: 73 answers/73 contexts/63 quotes, 0 leaks. Gate: 0 unsourced.
- Per-candidate: Bohannan 15, Bridgford 3 (IA-1); Mitchell 12, James 6, Bushaw 6, Stewart 2 (IA-2 open); Trone Garriott 16 (IA-3); McGowan 5, Dawson 8 (IA-4 open).

## Integrity calls (verified)
- **OK Hopkins ukraine row DROPPED** by orchestrator (inferred + stale 2024) → whole-record skip, consistent with the Chai/Todd ukraine-inference drops.
- IA Joe Mitchell: one DCCC (opposition PAC) quote flagged, corroborated by an underlying IA House floor-vote record.
- IA Chris McGowan: 2 rows lean on Trump-endorsement text his own campaign site displays as representative — flagged, accepted as self-adopted (own site, not party inference).
- IA Dave Dawson: identity double-checked against homonyms (former IA House member, Sioux City).
- IA Trone Garriott: deepest record (16) from IA Senate roll-call votes + campaign site; 8 topics honest-skipped, not padded.
- Open-seat departing incumbents (Hern OK-1, Hinson IA-2, Feenstra IA-4) absent from all stance work.

## Files (gitignored → PROD durable store)
`backend/data/stance-research/ok-2026-house/` + `ia-2026-house/` scaffolds + `_SKIPS.md` (OK) + gitignored CSVs.

## Self-Check: PASSED
OK 7/10 + IA 9/9 stance-complete; 3 OK skips with written trails; 0 unsourced on prod for both; ≤3 concurrency; verification pass per agent.
