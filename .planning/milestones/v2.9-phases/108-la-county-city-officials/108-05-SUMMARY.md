---
phase: 108-la-county-city-officials
plan: 05
status: complete
completed: 2026-06-08
gap_closure: true
requirements:
  - LAOF-06
---

# Plan 108-05 Summary: Fix Assertion 7 Join Path

## What Was Built

Repaired the broken join in Assertion 7 of `backend/scripts/verify-la-county-108.sql`.

The original query joined `essentials.districts d ON d.government_id = g.id` — a column that does not exist on the `essentials.districts` table. This caused a column-not-found error at runtime, preventing the Phase 108 verification gate from running all 8 assertions.

The fix replaces the broken join with the correct three-hop path through `essentials.chambers` as intermediary:

```sql
-- Before (broken):
JOIN essentials.districts d ON d.government_id = g.id
LEFT JOIN essentials.offices o ON o.district_id = d.id
LEFT JOIN essentials.politicians p
  ON p.office_id = o.id

-- After (correct):
JOIN essentials.chambers ch ON ch.government_id = g.id
JOIN essentials.offices o ON o.chamber_id = ch.id
JOIN essentials.districts d ON d.id = o.district_id
LEFT JOIN essentials.politicians p
  ON p.id = o.politician_id
```

## Key Files

### Modified
- `backend/scripts/verify-la-county-108.sql` — Assertion 7 join path corrected (lines 193-198)

## Verification

All acceptance criteria confirmed:
- `grep "ON d.government_id" verify-la-county-108.sql` → 0 matches ✓
- `grep "ch.government_id = g.id" verify-la-county-108.sql` → 1 match ✓
- All 8 ASSERTION labels still present (16 occurrences = 8 assertions × 2 each: comment header + echo line) ✓
- Diff is surgical: only the 5-line join block was changed ✓

## Deviations

None. Exact replacement specified in WR-07 (108-REVIEW.md) applied as written.

## Self-Check: PASSED

Broken join removed. Correct join via chambers intermediary in place. Phase 108 verification gate can now execute all 8 assertions without a column-not-found error.
