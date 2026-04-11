---
status: partial
phase: 108-councilscribe-roster-client-cli
source: [108-VERIFICATION.md]
started: 2026-04-11
updated: 2026-04-11
---

## Current Test

[awaiting human testing]

## Tests

### 1. Live endpoint smoke test
expected: `python refresh_roster.py --body bloomington-common-council` writes `~/CouncilScribe/config/rosters/bloomington-common-council.json` containing aliases for Piedmont-Smith and Asare, fetched against production `accounts.empowered.vote`.
result: [pending]

### 2. Offline byte-identity test (airplane mode)
expected: With an existing cache present, disable network and re-run `refresh_roster.py --body bloomington-common-council` — CLI exits non-zero with clear stderr error AND cache file sha256 is byte-identical before/after.
result: [pending]

### 3. Staleness warning visibility on real backdated cache
expected: Backdate `fetched_at` in an existing cache to >30 days ago, call `load_roster(body_slug="bloomington-common-council")`, confirm a WARNING line appears on stderr (and `logging.warning` fires) without blocking the load.
result: [pending]

## Summary

total: 3
passed: 0
issues: 0
pending: 3
skipped: 0
blocked: 0

## Gaps
