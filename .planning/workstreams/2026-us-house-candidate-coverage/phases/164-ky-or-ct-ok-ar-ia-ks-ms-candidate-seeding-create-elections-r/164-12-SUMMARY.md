---
phase: 164-ky-or-ct-ok-ar-ia-ks-ms-candidate-seeding-create-elections-r
plan: 12
state: AR+MS
status: complete
completed: 2026-07-06
requirements: [USHC3-05]
---

# 164-12 SUMMARY — AR + MS Stances

Two smallest decided states, pushed per state to **PROD**. 0 unsourced, 0 surname leaks.

## AR — 5/6 stance-complete (20 sourced answers), 1 whole-record skip
- Scaffold `ar-2026-house/` (IN_SCOPE = 6 AR ids). 1 agent (all 4 districts). Merge: 5 files, 20 rows, 0 problems. Push: 20 answers/20 contexts/20 quotes, 0 leaks. Gate: 0 unsourced.
- Per-candidate: Yarbrough Green 1, Parsons 2 (AR-1); Jones 5 (AR-2); Ryerse 7 (AR-3); Russell 5 (AR-4).
- **Skip (gate-pinned, trail in `_SKIPS.md`):** -50302 Bobby Wilson (AR-3 L) — positions (appliance-efficiency, "sovereign money", nuclear) don't map to any of the 24 scales without over-inferring.
- Integrity: James Russell agent caught + dropped a hallucinated AIPAC/DC-statehood row on re-verification.

## MS — 8/8 stance-complete (38 sourced answers), 0 skips
- Scaffold `ms-2026-house/` (IN_SCOPE = 8 MS ids). 2 agents (MS-1/2, MS-3/4). Merge: 8 files, 38 rows, 0 problems. Push: 38 answers/38 contexts/34 quotes, 0 leaks. Gate: 0 unsourced.
- Per-candidate: Cliff Johnson 4, Baucom 1 (MS-1); Eller 5, Foster 4 (MS-2); Chiaradio 5, Kiehle 10 (MS-3); Hulum 6, Boyanton 3 (MS-4).
- Integrity: Hulum's rows drew on his actual MS state-legislature voting record (freedomindex/mspolicy scorecards — actions over words); Baucom thin (1 row, Ballotpedia 403-walled); a CSV-breaking unescaped-comma URL bug caught + fixed.

## Files (gitignored → PROD durable store)
`backend/data/stance-research/ar-2026-house/` + `ms-2026-house/` scaffolds + `_SKIPS.md` (AR) + gitignored CSVs.

## Self-Check: PASSED
AR 5/6 + MS 8/8 stance-complete; 1 AR skip with written trail; 0 unsourced on prod for both; ≤3 concurrency; verification pass per agent. **All 6 Wave-2 stance plans complete.**
