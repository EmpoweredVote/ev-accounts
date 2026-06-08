---
status: partial
phase: 107-dc-finance
source: [107-VERIFICATION.md]
started: 2026-06-08T18:31:00Z
updated: 2026-06-08T18:31:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. DB write confirmation — EHN finance_summary populated

expected: `SELECT finance_summary FROM essentials.politicians WHERE id = '4dbc8de1-9984-42a5-b2aa-5445bf0619b9'` returns non-null JSONB with `source='FEC'`, `cycle='2026'`, `total_raised=53774.8`, `top_donors=[{employer:'TGV ROCKETS', amount:1000, count:1}]`
result: [pending]

## Summary

total: 1
passed: 0
issues: 0
pending: 1
skipped: 0
blocked: 0

## Gaps
