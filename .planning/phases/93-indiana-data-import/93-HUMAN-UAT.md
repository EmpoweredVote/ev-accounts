---
status: partial
phase: 93-indiana-data-import
source: [93-VERIFICATION.md]
started: 2026-03-22T19:00:00Z
updated: 2026-03-22T19:00:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Live Gateway download
expected: `./server import-budgets --source=gateway --dry-run` successfully downloads and parses CSV data from gateway.ifionline.org without errors
result: [pending]

### 2. DB insertion and idempotency
expected: Running import twice produces data in Supabase with no duplicates; `/treasury/budgets` returns non-zero data for Ellettsville
result: [pending]

### 3. Monroe County display name
expected: "Monroe County" displays as the entity name in Treasury Tracker frontend (not "Monroe County, City" or similar)
result: [pending]

## Summary

total: 3
passed: 0
issues: 0
pending: 3
skipped: 0
blocked: 0

## Gaps
