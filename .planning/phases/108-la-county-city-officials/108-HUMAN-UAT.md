---
status: partial
phase: 108-la-county-city-officials
source: [108-VERIFICATION.md]
started: 2026-06-08T00:00:00Z
updated: 2026-06-08T00:00:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Assertion 7 in verify-la-county-108.sql schema check
expected: `SELECT COUNT(*) FROM essentials.districts WHERE district_type='LOCAL_EXEC' AND label LIKE ...` returns 0 for Alhambra/Culver City/WeHo/El Segundo/South Gate — AND no schema error on the join path used
result: [pending]

### 2. Smoke test live execution
expected: `SMOKE_TEST_BEARER_TOKEN=<la-area-jwt> npx tsx backend/scripts/smoke-la-representatives-me.ts` exits 0 and shows >= 1 Phase 108 politician (external_id < -700000) in the response
result: [pending]

### 3. Downey district idempotency (CR-01)
expected: `SELECT COUNT(*) FROM essentials.districts WHERE geo_id='0619766' AND district_type='LOCAL'` returns exactly 5 (no duplicate from snapshot isolation issue)
result: [pending]

## Summary

total: 3
passed: 0
issues: 0
pending: 3
skipped: 0
blocked: 0

## Gaps
