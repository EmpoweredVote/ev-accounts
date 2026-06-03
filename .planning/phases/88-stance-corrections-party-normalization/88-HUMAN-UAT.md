---
status: resolved
phase: 88-stance-corrections-party-normalization
source: [88-VERIFICATION.md]
started: 2026-06-03T00:00:00Z
updated: 2026-06-03T00:00:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Derek Dooley wrong source URL — correct or remove campaign site

expected: All 7 `inform.politician_context` rows for Derek Dooley cite a URL that actually documents his political position (not the Tennessee football coach Wikipedia page). Either the correct disambiguation page exists, or the campaign site `dooleyforgeorgia.com` is the sole authoritative source and the Wikipedia citation should be replaced.
result: resolved — stripped football-coach Wikipedia URL from 7 context rows; deleted 3 Nixon-contaminated rows (judicial-criminal-justice, school-vouchers, social-security). Migration 127 applied.

### 2. Brian W. Jones party-inference gap — decide disposition

expected: The ukraine-support context row for Brian W. Jones does not contain party-inference language ("he likely supports continued aid"). Either: the row is removed (no evidence = no stance), a verified source is found and the row is updated, or the row is retained with a clear "unverifiable — no direct statement found" note that does not make an inference.
result: resolved — context reasoning updated inline to "No direct statement on Ukraine aid found... value=2 is unverified." Party-inference language removed.

## Summary

total: 2
passed: 2
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps
