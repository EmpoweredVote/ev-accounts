---
phase: 104-local-remediation-city-officials
reviewed: 2026-06-07T00:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - supabase/migrations/20260607000001_283_phase104_city_official_remediation.sql
  - backend/scripts/_apply-migration-283.ts
findings:
  critical: 1
  warning: 2
  info: 1
  total: 4
status: issues_found
---

# Phase 104: Code Review Report

**Reviewed:** 2026-06-07
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Migration 283 handles two city-official stance remediations: a DELETE (Mahmood/abortion, no evidence found) and an UPSERT with ARRAY_CAT (Moreno/city-sanitation, value upgraded 3→2 with a real source URL appended). The SQL structure, transaction boundaries, cohort scoping, and deletion ordering all follow established project patterns. One critical correctness bug exists in the ARRAY_CAT path: if the existing `politician_context` row has `sources = NULL`, the `||` concat returns NULL rather than the new array, silently zeroing out the freshly appended URL. This would leave the Moreno stance in a post-upgrade unsourced state — exactly what the phase is trying to fix. The apply script has two quality issues: STAX-03 check failures emit a warning but exit 0, and the path derivation is cwd-dependent in a way that silently resolves wrong if the script is run from the repo root.

## Critical Issues

### CR-01: ARRAY_CAT NULL propagation — Moreno context update silently drops sources if existing row has NULL sources

**File:** `supabase/migrations/20260607000001_283_phase104_city_official_remediation.sql:66-68`

**Issue:** The ON CONFLICT DO UPDATE clause uses:

```sql
SET sources = politician_context.sources || EXCLUDED.sources;
```

In PostgreSQL, `NULL || ARRAY[...]` evaluates to `NULL`, not `ARRAY[...]`. If the existing `politician_context` row for Moreno has `sources = NULL` (i.e., it was inserted without sources at some point), the ARRAY_CAT returns NULL and the new URL is silently discarded. The row would then appear in the V1 unsourced count (NULL sources), meaning STAX-03 would fail even though the smoke check `RAISE NOTICE` would already have emitted 0 — because the `RAISE NOTICE` runs after the INSERT/UPDATE settles in the same transaction, but the ARRAY_CAT NULL collapse would have already happened before the DO $$...END $$ block.

In practice, the Moreno context row was originally inserted with `sources = ARRAY['https://www.vivianmorenosd.com']` (non-NULL) so this is low-probability for this specific row. However, the migration is written as a general ARRAY_CAT pattern and the V1/V2 smoke checks passing at runtime is the only guard — if sources were NULL the smoke check would catch it, but only if the migration is run and inspected; it would not prevent the bad write from committing.

**Fix:** Use `COALESCE` to guard against NULL on the left side:

```sql
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = COALESCE(politician_context.sources, ARRAY[]::text[]) || EXCLUDED.sources;
```

This ensures that even if the existing row has `sources = NULL`, the concat produces `ARRAY['https://www.vivianmorenosd.com/better']` rather than NULL.

## Warnings

### WR-01: Apply script exits 0 when STAX-03 verification fails — pipeline cannot detect requirement failure

**File:** `backend/scripts/_apply-migration-283.ts:39-41` and `67-69`

**Issue:** When `v1 !== 0` or `v2 !== 0` (i.e., unsourced or weak-source stances still exist after migration), the script logs a WARNING string but does not call `process.exit(1)`. The script exits 0. Any CI/CD pipeline, shell automation, or orchestrator running this script will interpret success even when STAX-03 is not satisfied. The `process.exit(1)` on line 77 only fires for SQL execution errors, not for post-migration requirement failures.

**Fix:** Exit with a non-zero code when the STAX-03 target is not met:

```typescript
if (v1 !== 0) {
  console.error('WARNING: STAX-03 V1 not satisfied — unsourced stances remain in city cohort');
  process.exit(1);
}
```

```typescript
if (v2 !== 0) {
  console.error('WARNING: STAX-03 V2 not satisfied — weak-source-only stances remain in city cohort');
  process.exit(1);
}
```

### WR-02: SQL path in apply script is cwd-dependent — silently resolves wrong if run from repo root

**File:** `backend/scripts/_apply-migration-283.ts:9`

**Issue:** The path is constructed as:

```typescript
path.join(process.cwd(), '..', 'supabase', 'migrations', '20260607000001_...')
```

This resolves correctly only when `process.cwd()` is `backend/` (e.g., `cd backend && npx tsx scripts/_apply-migration-283.ts`). If run from the repo root (`npx tsx backend/scripts/_apply-migration-283.ts`), `process.cwd()` is the repo root and the resolved path becomes `../supabase/migrations/...` — one level above the repo root, which does not exist. The error message from `readFileSync` would be an ENOENT for an unexpected path, making the failure confusing.

Compare: prior scripts `_apply-migration-280.ts` and `_apply-migration-281.ts` (lines 8) use `path.join(process.cwd(), 'migrations', '...')` with no `..` traversal — those scripts target `backend/migrations/` and expect cwd=`backend/`. Migration 283 is in `supabase/migrations/` (repo-level) which is why the `..` was added, but this creates inconsistency in where the script must be invoked from.

**Fix:** Use `import.meta.url` (or `__dirname` equivalent for ESM) to anchor the path relative to the script file, not cwd:

```typescript
import { fileURLToPath } from 'url';
const __dirname = path.dirname(fileURLToPath(import.meta.url));

const sql = readFileSync(
  path.join(__dirname, '..', '..', 'supabase', 'migrations', '20260607000001_283_phase104_city_official_remediation.sql'),
  'utf8'
);
```

This is cwd-independent and works regardless of where the script is invoked from.

## Info

### IN-01: Subquery for topic_id lookup has no guard against zero rows — DELETEs silently no-op if topic_key is missing

**File:** `supabase/migrations/20260607000001_283_phase104_city_official_remediation.sql:37` and `41`

**Issue:** Both DELETE statements resolve `topic_id` via an unchecked subquery:

```sql
WHERE topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion')
```

If `topic_key = 'abortion'` returns no rows, the subquery returns NULL, and `topic_id = NULL` is always false — the DELETE silently deletes nothing. There is no RAISE EXCEPTION or assertion that the topic existed. The same pattern applies to the city-sanitation topic in the UPSERT block (lines 52-54). This is consistent with the established pattern in phases 101-103, but it means a typo in a topic_key (or a topic that was removed) produces a silent no-op rather than a migration failure. Since this migration has already been applied successfully (per 104-VERIFICATION.md), this is informational only.

**Fix (optional, for future migrations):** Add a pre-check:

```sql
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE topic_key = 'abortion') THEN
    RAISE EXCEPTION 'topic_key abortion not found — aborting migration';
  END IF;
END $$;
```

---

_Reviewed: 2026-06-07_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
