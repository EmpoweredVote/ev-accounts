---
phase: 120-ma-city-officials-seeding
reviewed: 2026-06-15T00:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - backend/migrations/687_newton_tiger_geoid_backfill.sql
  - backend/scripts/verify-phase-120.sql
findings:
  critical: 1
  warning: 1
  info: 1
  total: 3
status: issues_found
---

# Phase 120: Code Review Report

**Reviewed:** 2026-06-15
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Two files reviewed: the Newton tiger_geoid backfill migration (687) and the 9-assertion phase gate script. The migration logic itself is sound — the UPDATE is correctly scoped, the idempotency guard (`WHERE tiger_geoid IS NULL`) is correct, and the transaction wrapping is proper. However, a version number collision exists on disk that was papered over rather than resolved, and Assertion 8 in the verification script contains a structural logic flaw that makes it silently non-testing for its stated purpose.

---

## Critical Issues

### CR-01: Migration version collision — two files claim version '687' on disk

**File:** `backend/migrations/687_newton_tiger_geoid_backfill.sql:68` and `backend/migrations/687_leblanc_stances.sql` (entire file)

**Issue:** Two migration files on disk both carry version number `687`:
- `687_newton_tiger_geoid_backfill.sql` — registers `('687')` in `supabase_migrations.schema_migrations` (line 68)
- `687_leblanc_stances.sql` — is a separate, unrelated migration (Randall LeBlanc Waltham stances) that is presumably also numbered 687

The 120-01-SUMMARY explicitly notes "Ledger entry '687' pre-existed in DB" (a migration with version '687' had already been applied). The `ON CONFLICT DO NOTHING` clause silently suppressed the collision in production, but this means one of these two migrations is not actually tracked in the ledger — its version ownership is ambiguous. If `687_leblanc_stances.sql` was applied first (and registered '687'), then Newton tiger_geoid backfill's ledger INSERT was silently a no-op. If Newton ran first, LeBlanc stances has no ledger entry at all.

Additionally, any downstream tooling or CI that checks the migration directory for version uniqueness will either fail or produce wrong results. The `622_medford_fix_and_city_tiger_geoid_backfill.sql` / `622_micley_stances.sql` pair exhibits the same problem, suggesting a systemic pattern.

**Fix:** Renumber one file. The newton_tiger_geoid_backfill migration should be assigned the next unused version number (check `SELECT MAX(version) FROM supabase_migrations.schema_migrations` and pick a free slot, e.g., `688` or whichever is unoccupied). Update both the filename and the `INSERT INTO supabase_migrations.schema_migrations (version) VALUES ('687')` on line 68. Then re-apply the ledger entry for whichever migration was displaced.

```sql
-- In the renamed file (e.g. 688_newton_tiger_geoid_backfill.sql), change:
INSERT INTO supabase_migrations.schema_migrations (version) VALUES ('688') ON CONFLICT (version) DO NOTHING;
-- and update the file header comment accordingly.
```

---

## Warnings

### WR-01: Assertion 8 cannot detect politicians missing office records — the JOIN excludes them

**File:** `backend/scripts/verify-phase-120.sql:136-148`

**Issue:** Assertion 8 is intended to detect politicians with `NULL office_id`. However, the query uses an INNER JOIN through `essentials.offices`:

```sql
SELECT COUNT(*) INTO v_count
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id   -- INNER JOIN
JOIN essentials.districts d ON d.id = o.district_id
WHERE d.geo_id IN (...)
  AND d.state = 'ma'
  AND p.office_id IS NULL;
```

A politician row with no matching `offices` row at all is silently excluded from the result set by the INNER JOIN — it never appears in `p` within this query. Only politicians who DO have an `offices` record AND whose `politicians.office_id` is NULL would be counted.

This means the assertion has two blind spots:
1. A politician with no `offices` row whatsoever (complete FK orphan) — passes silently.
2. If `politicians.office_id` is a denormalized field pointing to the *primary* office, politicians linked via `offices` but with a NULL `office_id` are caught — but that's likely a small subset of the actual integrity concern.

The test passes (v_count = 0) in the summary output, but it proves less than it claims. Any politician orphaned from offices entirely is undetectable by this query.

**Fix:** Replace the INNER JOIN approach with a NOT EXISTS / LEFT JOIN check that explicitly looks for politicians linked to a district with no offices entry:

```sql
-- Detect politicians with office records whose office_id is NULL (original intent):
SELECT COUNT(*) INTO v_count
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON d.id = o.district_id
WHERE d.geo_id IN ('2545560','2562535','2537490','2523000','2572600','2539835','2545000')
  AND d.state = 'ma'
  AND p.office_id IS NULL;

-- ALSO add a second check for FK orphans (politicians with no offices row at all):
SELECT COUNT(DISTINCT p.id) INTO v_orphan_count
FROM essentials.politicians p
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o WHERE o.politician_id = p.id
)
AND p.id IN (
  -- scope to the 7-city set via a subquery
  SELECT DISTINCT o2.politician_id
  FROM essentials.offices o2
  JOIN essentials.districts d2 ON d2.id = o2.district_id
  WHERE d2.geo_id IN ('2545560','2562535','2537490','2523000','2572600','2539835','2545000')
    AND d2.state = 'ma'
);
```

Alternatively, restructure Assertion 8 to use a LEFT JOIN from a known-good district set and look for politicians the city migrations claimed to seed but which lack office linkage.

---

## Info

### IN-01: Pre-flight check runs after the UPDATE — logical ordering is inverted

**File:** `backend/migrations/687_newton_tiger_geoid_backfill.sql:29-57`

**Issue:** The `v_geofence_exists` pre-flight check (verifying that a G4110 geofence boundary exists for `geo_id='2545560'`) is evaluated inside the DO block that runs AFTER the `UPDATE essentials.districts` on line 22. If the geofence boundary does not exist, the RAISE EXCEPTION at line 56-58 will correctly abort the transaction — but the UPDATE has already executed at that point (it's just not yet committed). In the current design this is safe because the entire block is inside a `BEGIN/COMMIT` transaction and the EXCEPTION causes a ROLLBACK. However, the intent of "pre-flight" is to check preconditions before making changes, not after.

This is not a correctness bug under the current transaction model, but it is misleading: the DO block comment says "Pre-flight" yet the check is actually a post-UPDATE assertion. Any future refactor that moves the UPDATE out of the transaction (e.g., applying it via a tool that auto-commits) would break this safety guarantee silently.

**Fix:** Move the geofence existence check to its own DO block before the `UPDATE`, or add a clear comment that this is a post-update assertion relying on transaction rollback for safety, not a true pre-flight:

```sql
-- Option A: True pre-flight (separate DO block before UPDATE)
DO $$
DECLARE v_geofence_exists INT;
BEGIN
  SELECT COUNT(*) INTO v_geofence_exists
  FROM essentials.geofence_boundaries
  WHERE geo_id = '2545560' AND mtfcc = 'G4110';
  IF v_geofence_exists = 0 THEN
    RAISE EXCEPTION 'Pre-flight failed: no G4110 geofence_boundary for geo_id=2545560';
  END IF;
END $$;

UPDATE essentials.districts ...;  -- runs only if pre-flight passed
```

---

_Reviewed: 2026-06-15_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
