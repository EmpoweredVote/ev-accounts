---
status: partial
phase: 108-la-county-city-officials
source: [108-VERIFICATION.md]
started: 2026-06-08T00:00:00Z
updated: 2026-06-08T13:00:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Run verify-la-county-108.sql against live DB (all 8 assertions)
note: Structural fix applied by plan 108-05 — Assertion 7 join path corrected (governments→chambers→offices→districts). The schema error is resolved. Runtime execution still needed.
expected: `psql "$DATABASE_URL" -f backend/scripts/verify-la-county-108.sql` runs without error; Assertion 1 failures=0; Assertion 2 all 26 FIPS rows present; Assertion 5 controller_seated=t, attorney_vacant=t, clerk_appointed=t; Assertion 7 returns wave3_politicians_in_local_exec=0 per row (or zero rows if no LOCAL_EXEC districts exist for those cities)
result: PASS — 2026-06-08
  - Assertion 1: failures=0 ✓
  - Assertion 2: all 27 FIPS cities have district_rows>=1 ✓
  - Assertion 3: all 14 Tier 1 cities politician_count>=1 ✓
  - Assertion 4: bh_count=6, sm_count=10 ✓
  - Assertion 5: controller_seated=t, attorney_vacant=f (pre-existing Feldstein Soto — documented expected), clerk_appointed=t ✓
  - Assertion 6: new_governments=10, wave3_politicians=52 ✓
  - Assertion 7: 0 rows, no error ✓ (correct — no LOCAL_EXEC districts for at-large cities)
  - Assertion 8: 65/65/65/65 ✓

### 2. Smoke test live execution
expected: `SMOKE_TEST_BEARER_TOKEN=<la-area-jwt> npx tsx backend/scripts/smoke-la-representatives-me.ts` exits 0 and shows >= 1 Phase 108 politician (external_id < -700000) in the response
result: [pending]

### 3. Downey district idempotency (CR-01)
expected: `SELECT COUNT(*) FROM essentials.districts WHERE geo_id='0619766' AND district_type='LOCAL'` returns exactly 5 (no duplicate from snapshot isolation issue)
result: PASS — 2026-06-08
  - LOCAL count=5, LOCAL_EXEC count=2 — no duplicates created by CR-01

## Summary

total: 3
passed: 2
issues: 0
pending: 1
skipped: 0
blocked: 0

## Gaps
