# 150-07 PROGRESS (PARTIAL) — TX-1..10 stances, Playwright-verified method

**Status:** 🟡 PARTIAL — method validated; 5 of 20 in-scope TX-1..10 candidates pushed
**Wave:** 3

## Validated Playwright method (repeatable for 150-07..11)

WebFetch is 403/blank-walled on all primary sources (GovTrack, congress.gov, house.gov, Ballotpedia). **Playwright MCP bypasses the walls.** For incumbents, Ballotpedia's per-member **"Key votes" section** exposes 119th-Congress roll-call votes (primary-grade) — far better than the OnTheIssues fallback the agents used.

Repeatable steps (orchestrator-run, not subagent — Playwright is a single shared browser, no parallelism):
1. `browser_navigate https://ballotpedia.org/<First_Last>`
2. `browser_evaluate` → parse the "Key votes" table for each marquee bill's Yea/Nay (look back ~40 chars before the bill name for the vote token).
3. **Map ONLY Yea votes to chairs** (chairs-not-polarity rule below). Cite the Ballotpedia member URL + congress.gov bill URL.

### Marquee 119th-Congress vote → federal-24 chair map (Yea):
| Bill | topic_key | value | chair text |
|------|-----------|-------|------------|
| Laken Riley Act (S.5) | deportation | 4 | "deport everyone without legal status, starting with those who have criminal records" |
| SAVE Act (H.R.22) | voting-rights | 4 | "require photo ID + update voter rolls" (documentary proof of citizenship) |
| Protection of Women & Girls in Sports Act (H.R.28) | trans-athletes | 4 | "compete only on teams matching biological sex assigned at birth" |
| 2025 Budget Reconciliation (H.Con.Res.14, TCJA extension) | taxes | 4 | "cut taxes for everyone and scale back public services" |

### ⚠ CHAIRS-NOT-POLARITY RULE (critical method finding):
A **Yea** means the bill's content **IS** the member's position → clean chair mapping. A **Nay** only tells you what they *oppose*, not their exact chair — mapping a Nay to a chair is directional approximation (FORBIDDEN). **Democrats who vote Nay on these GOP bills need their POSITIVE stated positions** (house.gov issues page / Candidate Connection survey) to pin a chair; do NOT infer chair 1/2 from a Nay alone. Honest-skip the topic if no positive evidence.

## Pushed this batch (5 GOP TX-1..10 incumbents, 20 stances, 0 unsourced — gate slice PASS)

| pid | candidate | topics (all value 4, roll-call-backed) |
|-----|-----------|----------------------------------------|
| -100301 | Nathaniel Moran TX-1 | deportation, voting-rights, trans-athletes, taxes |
| -100303 | Keith Self TX-3 | deportation, voting-rights, trans-athletes, taxes |
| -100304 | Pat Fallon TX-4 | deportation, voting-rights, trans-athletes, taxes |
| -100305 | Lance Gooden TX-5 | deportation, voting-rights, trans-athletes, taxes |
| -100306 | Jake Ellzey TX-6 | deportation, voting-rights, trans-athletes, taxes |

All five voted Yea on all four marquee bills (verified individually via Playwright; Fletcher TX-7 voted Nay on all four — confirms non-party-line read works).

## Remaining in TX-1..10 (15 candidates) — next session

- **Lizzie Fletcher TX-7 (-100307, D)**: voted Nay on all four marquee bills → needs her positive positions (fletcher.house.gov/issues) to pin chairs; do NOT infer from Nays.
- **Steve Toth TX-2 (-100515)**: already has 14 federal stances (state-rep record) → verify those are sourced, optionally top up.
- **13 new challengers** (Prince, Finnie, Hunt, Pearce, Hockett, Minton, Hale, Steinmann, Jones, Mealer, Gutierrez, Rourk, Gober): mostly obscure, no roll-call record → campaign sites / Candidate Connection via Playwright; expect many whole-record honest-skips (pin in `_stance_skip` of 150-verify.sql by UUID, ORDER BY).

## Note
The agent-dispatch path (politician-stance-researcher) is NOT viable for incumbents here — agents can't use Playwright (rate-limit quota) and WebFetch is walled, so they fall back to aggregators + over-read (Moran agent run produced abortion=4 over-read, discarded). The orchestrator-run Playwright path above is the validated replacement. Scratch CSV: `tx-2026-house-b1/incumbents-rollcall-verified.csv` (gitignored; DB is source of truth).
