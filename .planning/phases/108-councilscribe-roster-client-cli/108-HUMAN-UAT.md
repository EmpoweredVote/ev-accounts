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
expected: `python refresh_roster.py --body bloomington-common-council` writes `~/CouncilScribe/config/rosters/bloomington-common-council.json` containing aliases for Piedmont-Smith and Asare, fetched against production.
result: PASSED (2026-04-11). `EV_ACCOUNTS_URL=https://api.empowered.vote python refresh_roster.py --body bloomington-common-council` returned "Wrote .../bloomington-common-council.json (9 members)". Cache contains all 9 sitting Bloomington Common Council members. Both targets verified:
  - **Isabel Piedmont-Smith** — aliases include `['Isabel Piedmont-Smith', 'Isabel Piedmont Smith', 'Piedmont-Smith', 'Piedmont Smith', ...]` (D-02 hyphen-space expansion confirmed on live data).
  - **Isak Asare** — aliases include `['Isak Asare', 'Asare', ...]`.
  - Cache shape: `body_key='Bloomington Common Council'`, `body_slug='bloomington-common-council'`, ISO `fetched_at`, `politicians[]` with `politician_slug`/`full_name`/`title`/`district_label`/`aliases`. Confirms CSROSTER-01, CSROSTER-02.
note: endpoint lives at `api.empowered.vote`, not `accounts.empowered.vote` as CLAUDE.md claims — CLAUDE.md hosting note is stale.

### 2. Offline byte-identity test (airplane mode)
expected: With an existing cache present, disable network and re-run `refresh_roster.py --body bloomington-common-council` — CLI exits non-zero with clear stderr error AND cache file sha256 is byte-identical before/after.
result: [pending — operator has other traffic running, can't toggle network now]

### 3. Staleness warning visibility on real backdated cache
expected: Backdate `fetched_at` in an existing cache to >30 days ago, call `load_roster(body_slug="bloomington-common-council")`, confirm a WARNING line appears on stderr (and `logging.warning` fires) without blocking the load.
result: PASSED (2026-04-11). Backdated cache to `2026-02-01` (69 days), ran `load_roster(body_slug="bloomington-common-council")`. Stderr received both `WARNING:root:Roster 'bloomington-common-council' is 69 days old (fetched 2026-02-01)...` (logging.warning) AND `WARNING: Roster 'bloomington-common-council' is 69 days old...` (direct stderr). Load did not block — stdout returned `LOAD_OK 1` with 1 member. Confirms CSROSTER-05.

## Summary

total: 3
passed: 2
issues: 0
pending: 1
skipped: 0
blocked: 0

## Gaps

### G1 — Phase 107 deployment (RESOLVED 2026-04-11)
severity: resolved
resolution: Phase 107 ev-accounts backend (migration 060 + essentialsBodies route/service/test + index.ts wiring) committed as `a162c5e` on ev-accounts `master`, rebased on 10 upstream commits, pushed to origin, auto-deployed by Render. Migration 060 applied to prod Supabase (`kxsdzaojfaibhuzmclfq`) via MCP — verified `essentials.chambers.slug` populated with `bloomington-common-council`. Test 1 re-run successfully against `api.empowered.vote`.

### G2 — Minor client robustness (RESOLVED 2026-04-11 in Phase 108.1)
severity: resolved
resolution: Phase 108.1 shipped `2a60f2b` in CouncilScribe repo. `fetch_body_roster` now wraps `resp.json()` in `try/except ValueError as exc` (catches `JSONDecodeError` via inheritance, matching existing 404/422 pattern) and raises `EssentialsClientError(f"Non-JSON response from {url}: {resp.text[:200]}", status=resp.status_code) from exc`. New regression test `test_fetch_body_roster_non_json_200_wrapped` pins the behavior. Full suite: 49/49 green. Phase 108.1 verification: 5/5 must-haves passed.
