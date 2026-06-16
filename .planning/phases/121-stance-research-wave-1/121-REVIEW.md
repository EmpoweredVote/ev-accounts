---
phase: 121-stance-research-wave-1
reviewed: 2026-06-15T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - backend/data/stance-research/2026-06-15-medford-mullane.csv
  - backend/migrations/700_liz_mullane_stances.sql
  - backend/scripts/verify-phase-121.sql
findings:
  critical: 1
  warning: 1
  info: 1
  total: 3
status: resolved
fixes_applied:
  - CR-01: simplified assertion 7 in verify-phase-121.sql; removed dead v_migration_applied branch (commit 95e6bb96)
  - WR-01: clarified migration 700 comment; explicit that both 680 and 700 must run in sequence (commit 9e5185f8)
  - IN-01: skipped (info only, not in fix scope)
---

# Phase 121: Code Review Report

**Reviewed:** 2026-06-15
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Three files were reviewed: the stance research CSV for Liz Mullane (6 rows, 6 topics), migration 700 that materialises those stances, and the phase gate verification script. The CSV and migration are structurally sound — all six stances are paired (answers + context), UUIDs cross-verify against earlier migrations, values are within plausible range, sources are non-empty, and the migration is wrapped in a single transaction. One blocker was found in the verify script, one warning in the migration, and one info item in the CSV.

## Critical Issues

### CR-01: Assertion 7 `v_migration_applied` check is always FALSE — the migration never self-registers

**File:** `backend/scripts/verify-phase-121.sql:146`

**Issue:** Assertion 7 queries `supabase_migrations.schema_migrations WHERE version = '700'` to determine whether migration 700 has been applied before deciding which failure message to raise. Migration 700 (`700_liz_mullane_stances.sql`) does **not** contain an `INSERT INTO supabase_migrations.schema_migrations` statement — confirmed by inspection of the file. All other stance migrations in the 680–700 range (681–698, 700) follow this same pattern: they do not self-register. Only non-stance infrastructure migrations in this era (699, and earlier batch migrations) do self-register.

Consequence: `v_migration_applied` will always be `FALSE` at runtime, regardless of whether migration 700 has actually been applied. If any Medford official still has zero stances after migration 700 runs, the assertion fires the wrong error branch (`ELSIF v_count <> 0 AND NOT v_migration_applied`) with a misleading message telling the operator to "Apply migration 700 first" — when migration 700 was already applied and a different problem exists (e.g., the politician is not linked to the Medford district via `essentials.offices`). This is a silent diagnostic failure: the assertion still raises an exception, but the operator will spend time re-applying a migration that is already in effect.

**Fix:** Either drop the `v_migration_applied` branch entirely (the two RAISE EXCEPTION cases produce identical behaviour — both halt the script) or add a self-registration line to migration 700 so it is detectable:

Option A — simplify assertion 7 to remove the dead branch:
```sql
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM (
    SELECT p.id
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.geo_id = '2539835'
    AND NOT EXISTS (
      SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id
    )
  ) officials_with_zero_stances;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 7 FAILED [MAST-06]: % Medford officials have zero stances. Verify migration 700 was applied and politician office links are intact.', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 7 PASSED [MAST-06]: % Medford officials with zero stances (expected 0)', v_count;
END $$;
```

Option B — add self-registration to migration 700 (end of file, after COMMIT):
```sql
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('700') ON CONFLICT (version) DO NOTHING;
```

Option A is preferred; it requires no migration change and matches the pattern used by assertions 1–6 and 8–9 which have no migration-detection complexity.

---

## Warnings

### WR-01: Migration 700 comment header describes migration 680 as an "honest-skip" but 680 is a full honest-skip migration — the two co-exist and could conflict on a fresh apply

**File:** `backend/migrations/700_liz_mullane_stances.sql:8`

**Issue:** The migration comment states "Migration 680 was applied as an honest-skip (no evidence found at that time). This migration supersedes the honest-skip by inserting those stances." This framing is accurate for additive upsert behaviour, and the `ON CONFLICT DO UPDATE` clauses mean the migration is safe to run in any order. However, if a future operator reads this comment and interprets "supersedes" as meaning migration 680 should be dropped or skipped, they may omit 680 from a fresh environment replay — resulting in a gap between migrations 679 and 681 that could confuse migration runners that depend on sequential version numbering.

Additionally, the comment says "This migration supersedes the honest-skip" but migration 700 does not alter, replace, or delete migration 680. Both migrations will run independently. The word "supersedes" is misleading about the relationship.

**Fix:** Revise the comment to be explicit that both migrations must be applied:
```
-- Context: Migration 680 was applied as an honest-skip (no INSERT rows — no evidence
--   found at that time). This migration (700) ADDS the stances discovered in June 2026
--   on top of 680's empty transaction. Both 680 and 700 must remain in the migration
--   sequence; do not skip 680 when replaying from scratch.
```

---

## Info

### IN-01: CSV `reasoning` column uses a shorter summary than the migration's `reasoning` column for the same stances

**File:** `backend/data/stance-research/2026-06-15-medford-mullane.csv:2-7`

**Issue:** The CSV file contains abbreviated reasoning text (one-sentence summaries) while the migration's `politician_context` INSERT statements contain significantly more detailed reasoning with direct quotes. This is a documentation consistency gap — the CSV is the canonical research artifact used for audit and traceability, but an auditor reading the CSV alone would see less evidence than what was committed to the database. For example, the `housing` CSV entry has 189 characters of reasoning; the migration inserts 685 characters including direct candidate quotes. There is no functional bug, but it reduces audit fidelity.

**Fix:** Either accept this gap as intentional (CSV = summary, migration = authoritative) and add a header comment to that effect in the CSV template, or align CSV reasoning to match migration reasoning verbatim. The project's existing stances CSVs vary in this regard, so no hard rule exists yet.

---

_Reviewed: 2026-06-15_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
