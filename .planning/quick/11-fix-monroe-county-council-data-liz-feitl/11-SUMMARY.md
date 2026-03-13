---
phase: 11-fix-monroe-county-council-data-liz-feitl
plan: 01
subsystem: essentials
tags: [data-fix, geofence, monroe-county, sql-migration]
dependency_graph:
  requires: []
  provides: [monroe-county-council-visibility]
  affects: [essentials-address-lookup]
tech_stack:
  added: []
  patterns: [idempotent-sql-migration]
key_files:
  created:
    - EV-Backend/internal/essentials/migrations/fix_monroe_county_council.sql
  modified:
    - EV-Backend/internal/essentials/geofence_lookup.go
decisions:
  - "Used zip column (not zip_code) matching the ZipPolitician GORM model"
  - "Wrapped migration in BEGIN/COMMIT transaction for atomicity"
  - "Used ON CONFLICT DO NOTHING for idempotent zip_politicians inserts"
metrics:
  duration: 76s
  completed: "2026-03-13T01:55:11Z"
  tasks_completed: 2
  tasks_total: 3
---

# Quick Task 11: Fix Monroe County Council Data Summary

MTFCC X0001 mapping expanded to include COUNTY district type, plus SQL migration to fix Liz Feitl office linkage, remove duplicate politicians, and populate zip_politicians.

## What Changed

### Task 1: Fix MTFCC mapping for COUNTY districts
- **Commit:** 92b39c2
- **File:** `EV-Backend/internal/essentials/geofence_lookup.go`
- Changed `X0001` MTFCC mapping from `{"LOCAL"}` to `{"LOCAL", "COUNTY"}`
- This allows geofence matches with MTFCC X0001 (sub-district boundaries) to resolve to districts with `district_type='COUNTY'`, enabling Monroe County Council districts to appear in address lookups

### Task 2: SQL migration for data fixes
- **Commit:** e632f66
- **File:** `EV-Backend/internal/essentials/migrations/fix_monroe_county_council.sql`
- 5-step idempotent migration wrapped in a transaction:
  1. Reassign Cheryl Munson's vacant at-large office to Liz Feitl
  2. Delete Liz Feitl's incorrect Assessor district office link
  3. Remove 4 duplicate politician records (districts 1-4) from quick-8 migration
  4. Populate zip_politicians for Liz Feitl across all Monroe County ZIPs
  5. Mark Cheryl Munson as inactive

### Task 3: Human action required (checkpoint -- not executed)
The SQL migration must be run manually against the database. See post-execution steps below.

## Post-Execution Steps (User Action Required)

1. **Run the SQL migration** against the database:
   - Open Supabase SQL Editor or connect via psql
   - Paste and execute contents of `EV-Backend/internal/essentials/migrations/fix_monroe_county_council.sql`

2. **Verify Liz Feitl's office:**
   ```sql
   SELECT p.full_name, o.title, d.label, d.district_type
   FROM essentials.offices o
   JOIN essentials.politicians p ON o.politician_id = p.id
   JOIN essentials.districts d ON o.district_id = d.id
   WHERE p.id = 'b3830ff1-3b9b-463a-bb7d-311bf1bf0168';
   ```
   Expected: Liz Feitl linked to "Monroe County Council - At Large" with district_type COUNTY

3. **Verify no duplicates:**
   ```sql
   SELECT slug FROM essentials.politicians WHERE slug LIKE '%monroe-county-council-d%';
   ```
   Expected: 0 rows

4. **Verify zip_politicians:**
   ```sql
   SELECT COUNT(*) FROM essentials.zip_politicians WHERE politician_id = 'b3830ff1-3b9b-463a-bb7d-311bf1bf0168';
   ```
   Expected: non-zero count

5. **Deploy updated backend** (go build + restart) and search a Monroe County address (e.g., Bloomington, IN 47401)
   Expected: All Monroe County Council members appear in Local tier

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed zip_politicians column name in SQL migration**
- **Found during:** Task 2
- **Issue:** Plan referenced `zip_code` column but the actual GORM model and database use `zip`
- **Fix:** Used correct column name `zip` in the INSERT statement
- **Files modified:** `EV-Backend/internal/essentials/migrations/fix_monroe_county_council.sql`
- **Commit:** e632f66

## Self-Check: PASSED

- All created/modified files exist on disk
- Both task commits (92b39c2, e632f66) verified in git log
