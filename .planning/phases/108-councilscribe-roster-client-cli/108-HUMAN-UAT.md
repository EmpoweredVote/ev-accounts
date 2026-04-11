---
status: partial
phase: 108-councilscribe-roster-client-cli
source: [108-VERIFICATION.md]
started: 2026-04-11
updated: 2026-04-11
---

## Current Test

[awaiting human: test 2 airplane-mode]

## Tests

### 1. Live endpoint smoke test
expected: `python refresh_roster.py --body bloomington-common-council` writes `~/CouncilScribe/config/rosters/bloomington-common-council.json` containing aliases for Piedmont-Smith and Asare, fetched against production `accounts.empowered.vote`.
result: blocked — production `/api/essentials/bodies/:slug/roster` returns HTTP 200 `text/html` (admin SPA catch-all). Phase 107's `backend/src/routes/essentialsBodies.ts` is present in the local ev-accounts tree but **untracked in git** (not committed, not deployed). Upstream deployment required before this test can run.

### 2. Offline byte-identity test (airplane mode)
expected: With an existing cache present, disable network and re-run `refresh_roster.py --body bloomington-common-council` — CLI exits non-zero with clear stderr error AND cache file sha256 is byte-identical before/after.
result: [pending — operator has other traffic running, can't toggle network now]

### 3. Staleness warning visibility on real backdated cache
expected: Backdate `fetched_at` in an existing cache to >30 days ago, call `load_roster(body_slug="bloomington-common-council")`, confirm a WARNING line appears on stderr (and `logging.warning` fires) without blocking the load.
result: PASSED (2026-04-11). Backdated cache to `2026-02-01` (69 days), ran `load_roster(body_slug="bloomington-common-council")`. Stderr received both `WARNING:root:Roster 'bloomington-common-council' is 69 days old (fetched 2026-02-01)...` (logging.warning) AND `WARNING: Roster 'bloomington-common-council' is 69 days old...` (direct stderr). Load did not block — stdout returned `LOAD_OK 1` with 1 member. Confirms CSROSTER-05.

## Summary

total: 3
passed: 1
issues: 0
pending: 1
skipped: 0
blocked: 1

## Gaps

### G1 — Phase 107 endpoint not deployed (upstream blocker)
severity: blocking for Test 1 only (not a Phase 108 defect)
symptom: `/api/essentials/bodies/bloomington-common-council/roster` on production returns `text/html` (admin SPA) instead of JSON.
cause: `ev-accounts/backend/src/routes/essentialsBodies.ts` and related service file are untracked in the ev-accounts git repo. Phase 107's backend work was not committed or deployed.
fix location: ev-accounts repo, not CouncilScribe. Commit Phase 107 changes and redeploy accounts.empowered.vote, then re-run Test 1.

### G2 — Minor client robustness (non-blocking, outside Phase 108 must_haves)
severity: advisory
symptom: When the endpoint returns HTTP 200 with non-JSON (e.g., HTML from a catch-all), `fetch_body_roster` lets `requests.exceptions.JSONDecodeError` escape instead of wrapping it in `EssentialsClientError`.
scope: Not in Phase 108's acceptance truths (the offline/error spec targets network-layer failures). File as a follow-up hardening task if desired.
fix location: `CouncilScribe/src/essentials_client.py::fetch_body_roster` — catch `RequestsJSONDecodeError` (and/or validate `Content-Type`) and raise `EssentialsClientError`.
