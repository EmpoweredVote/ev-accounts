---
phase: 77-city-infrastructure-official-records
reviewed: 2026-05-28T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - backend/migrations/217_sj_government_structure.sql
  - backend/migrations/218_sj_officials.sql
  - backend/migrations/219_sj_headshots.sql
findings:
  critical: 0
  warning: 2
  info: 2
  total: 4
status: issues_found
---

# Phase 77: Code Review Report

**Reviewed:** 2026-05-28
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Three PostgreSQL migration files seeding San Jose city government structure (migration 217), 11 officials and their offices (migration 218), and audit-only headshot records (migration 219). All three files are correctly wrapped in `BEGIN`/`COMMIT` transactions. Idempotency guards are present on every `INSERT`. The overall pattern is consistent with the Berkeley/SD/Fremont precedent migrations (213–215). The migration ledger status for 219 as audit-only is clearly documented. No critical correctness or data-loss issues found.

Two warnings affect idempotency or correctness under specific re-run conditions. Two info items cover stale documentation and a licensing note for a CC-BY-SA image.

---

## Warnings

### WR-01: Mayor office INSERT uses over-broad district_type filter — risks duplicate office row if geo_id `0668000` ever gains a LOCAL row

**File:** `backend/migrations/218_sj_officials.sql:395-396`

**Issue:** The Mayor's office INSERT selects from `essentials.districts` where `geo_id = '0668000' AND district_type IN ('LOCAL', 'LOCAL_EXEC')`. Migration 217 creates exactly one district row for `geo_id = '0668000'` with `district_type = 'LOCAL_EXEC'`, so today there is only one matching row and the INSERT fires once. However, if a future migration (or replay error) inadvertently adds a second row for geo_id `0668000` with `district_type = 'LOCAL'`, the `CROSS JOIN` would produce two candidate rows. The `WHERE NOT EXISTS` guard at lines 399–402 checks `(district_id, politician_id)` uniqueness — it would suppress the second insert if the first had already created an office for the `LOCAL_EXEC` district, but would allow an insert for the `LOCAL` district, producing a second unwanted `offices` row for the Mayor.

All other council member inserts correctly pin to a single geo_id with `district_type = 'LOCAL'` (not `IN`), so this inconsistency is isolated to the Mayor block.

**Fix:** Narrow the filter to match exactly what was created in migration 217:

```sql
-- Before (line 396)
  AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')

-- After
  AND d.district_type = 'LOCAL_EXEC'
```

---

### WR-02: `photo_origin_url` UPDATE guards not present on all headshot rows in migration 219 — only `IS NULL` check, no transaction-level uniqueness

**File:** `backend/migrations/219_sj_headshots.sql:49-51` (and all 10 analogous UPDATE blocks)

**Issue:** Every `UPDATE essentials.politicians SET photo_origin_url = '...' WHERE external_id = N AND photo_origin_url IS NULL` is safely guarded. However, the matching `INSERT INTO essentials.politician_images` uses `WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = ...)`. If the audit-only file is replayed in a new environment where migration 219 from the ledger sequence has a number collision (the ledger already has two other files called 219: `219_sacramento_government_structure.sql` and `219_fremont_officials_stances.sql`), a runner applying migrations in numeric order could apply the wrong `219_*.sql` file, leaving politician_images rows absent and silently skipping this file if it applies before the politician rows exist (the subquery `SELECT id FROM essentials.politicians WHERE external_id = -640001` would return NULL, causing the INSERT to write a NULL `politician_id` if not caught by a NOT NULL constraint, or silently insert 0 rows if it is constrained).

The root cause is the file-numbering conflict: there are now **three** files named `219_*.sql` in `backend/migrations/`:
- `backend/migrations/219_sacramento_government_structure.sql`
- `backend/migrations/219_fremont_officials_stances.sql`
- `backend/migrations/219_sj_headshots.sql`

Even though 219_sj_headshots.sql is marked audit-only (not in ledger), its presence in the same directory creates ambiguity. A developer bootstrapping a new environment from the migrations directory would have three files that sort to the same sequence position.

**Fix:** Rename `219_sj_headshots.sql` to a clearly non-runnable name to eliminate any risk of accidental application by migration tooling. Recommended convention consistent with other audit-only files (if this is the established pattern):

```
backend/migrations/219_sj_headshots.AUDIT-ONLY.sql
```

Or add a prominent file-level guard at the very top (before `BEGIN`) that prevents execution if run by a migration runner:

```sql
-- AUDIT-ONLY: DO NOT APPLY VIA MIGRATION RUNNER.
-- This file is not in the Supabase migrations ledger.
-- See header comment for details.
-- Sequence 219 is occupied by: 219_sacramento_government_structure.sql
--                          and: 219_fremont_officials_stances.sql
```

The current header comment (lines 1–28) does document the audit-only status clearly, but a file naming convention that prevents accidental application would be safer.

---

## Info

### IN-01: Stale comment references "plan 64-03" instead of plan 77-01

**File:** `backend/migrations/218_sj_officials.sql:407`

**Issue:** The comment reads:
```sql
-- REQUIRED: plan 64-03 queries politicians JOIN offices ON o.id = p.office_id
```
Phase 64 is San Diego. This is a copy-paste artifact from migration 208 (SD officials). The correct reference for San Jose is Phase 77, plan 77-01.

**Fix:**
```sql
-- REQUIRED: plan 77-01 queries politicians JOIN offices ON o.id = p.office_id
```

---

### IN-02: Matt Mahan headshot uses CC-BY-SA 4.0 license — ShareAlike terms require attribution and downstream licensing compliance

**File:** `backend/migrations/219_sj_headshots.sql:43`

**Issue:** The `photo_license` value for Matt Mahan is `'cc-by-sa-4.0'`. All other 10 officials use `'public_domain'`. CC-BY-SA 4.0 requires:
1. Attribution to the original author/source when the image is displayed.
2. Any derivative works (including crops/resizes performed during processing) must be distributed under the same CC-BY-SA 4.0 terms.

The image was "cropped from bottom to get 4:5; resized 600x750" (line 38 comment), making it a derivative. If the platform displays this headshot without attribution, it is out of compliance with the license terms.

**Fix:** Ensure the UI layer that renders politician headshots checks `photo_license` and surfaces attribution when the value is not `'public_domain'`. Alternatively, source a public-domain replacement image for Matt Mahan (official government portraits are typically public domain). If the current image is kept, add an attribution record.

---

_Reviewed: 2026-05-28_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
