---
status: partial
phase: 108-la-county-city-officials
source: [108-VERIFICATION.md]
started: 2026-06-08T00:00:00Z
updated: 2026-06-08T12:00:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Run verify-la-county-108.sql against live DB (all 8 assertions)
note: Structural fix applied by plan 108-05 — Assertion 7 join path corrected (governments→chambers→offices→districts). The schema error is resolved. Runtime execution still needed.
expected: `psql "$DATABASE_URL" -f backend/scripts/verify-la-county-108.sql` runs without error; Assertion 1 failures=0; Assertion 2 all 26 FIPS rows present; Assertion 5 controller_seated=t, attorney_vacant=t, clerk_appointed=t; Assertion 7 returns wave3_politicians_in_local_exec=0 per row (or zero rows if no LOCAL_EXEC districts exist for those cities)
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
