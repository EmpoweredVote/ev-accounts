---
phase: 165-small-delegation-states-candidate-seeding-17-states-create-e
plan: 10
state: UT
status: complete
completed: 2026-07-07
requirements: [USHC3-05]
---

# 165-10 SUMMARY — UT stance research pushed to PROD

## What was built
ut-2026-house scaffold (live-regenerated federal-24 scale) + stance research for the full UT 2026 field, pushed to PROD. **81 answers total, 0 unsourced, 0 surname leaks.**

## Coverage
- **UUID-keyed reused primary-winner pids (all confirmed 0-stance live → in scope, pushed via _push_uuid.ts; CSVs renamed `_uuid-*.csv` so _merge.ts skips them):** Ben McAdams b78f058c **16 topics** (former UT-4 rep — congress.gov/OnTheIssues/campaign platform; stale-evidence caveats flagged), Peter Crosby e3cbc264 **8** (campaign site + ydutah.com questionnaire), Kent Udell a7e29796 **8** (campaign site + Ballotpedia mirror via Playwright), Jonny Larsen 6708ceaa **11** (JS-SPA site + Ballotpedia-preserved fuller platform text).
- **New challengers via _push.ts (38 answers):** -490101 Owen 1, -490102 West 3, -490103 Montgomery 9, -490201 Cottam 5 (2024 Candidate Connection, staleness flagged), -490202 Bowen 1, -490301 Easley 1, -490302 Hooslyn 7, -490303 Scott 6, -490401 Wright 4, -490402 Burt 1.
- **Whole-record honest-skips (gate-pin for 165-17):** **-490203 Robert M. Moesinger** (single-issue electoral-structure platform maps to no tracked scale) and **-490304 Michael R. Stoddard** (audits/sound-money/militia planks map to no tracked scale) — search trails in `ut-2026-house/_SKIPS.md`.
- UT incumbents Moore/Maloy/Kennedy: partial-tier → correctly NOT topped up.

## Method notes
3-concurrency held; district-batched agents for minor candidates (RESEARCH-sanctioned). Ballotpedia consistently WebFetch/jina-walled but renders via Playwright DOM textContent extraction. Push results: merged external 38/38 sourced; UUID pushes 16+8+8+11. Canonical sources-array unsourced query = 0.

## Self-Check: PASSED
0 unsourced on PROD; every UT new challenger + all 4 reused primary-winner pids covered or pinned-skipped with trails; incumbents skipped per tier. Gate pins: -490203, -490304.
