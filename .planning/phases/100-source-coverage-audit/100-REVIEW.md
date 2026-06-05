---
phase: 100-source-coverage-audit
reviewed: 2026-06-05T00:00:00Z
depth: standard
files_reviewed: 1
files_reviewed_list:
  - backend/scripts/run-source-coverage-audit.ts
findings:
  critical: 1
  warning: 4
  info: 2
  total: 7
status: issues_found
---

# Phase 100: Code Review Report

**Reviewed:** 2026-06-05T00:00:00Z
**Depth:** standard
**Files Reviewed:** 1
**Status:** issues_found

## Summary

Reviewed `backend/scripts/run-source-coverage-audit.ts` — a one-shot read-only CLI audit script that queries the live production database via `pg.Pool` and writes a Markdown report and CSV. No user input flows into SQL, so there is no injection risk. The high-level structure is sound: `pool.query()` is correctly used for non-public schemas, `COALESCE(SUM, 0)` handles the NULL-on-no-rows case, and the `DISTINCT ON` tier subqueries correctly prevent multi-office Cartesian inflation.

One critical bug was found: the MD cohort object stores a prose string in the `pct_sourced` field, and the report builder unconditionally appends `%`, producing a malformed and misleading Markdown table cell in the already-written `100-AUDIT-REPORT.md`. Additionally: the v2.3 senators cohort query lacks DISTINCT protection against multi-office double-counting; `DATABASE_URL` is never validated before pool construction; the output directory is assumed to exist; and the unsourced detection CASE expression is duplicated four times in Query D, creating a four-point maintenance surface for any future definition change.

---

## Critical Issues

### CR-01: MD Cohort `pct_sourced` Prose String Gets Stray `%` Appended — Corrupts Report Output

**File:** `backend/scripts/run-source-coverage-audit.ts:300-301` and `:532`

**Issue:** The MD officials cohort object hardcodes `pct_sourced` as a prose string rather than a numeric value:

```ts
// line 300-301
pct_sourced: '0.0 (0 stances — Phase 103 STAX-02 scope)',
```

`buildReport()` at line 532 unconditionally appends `%` to every cohort's `pct_sourced` value:

```ts
`| ${c.cohort} | ${c.total_stances} | ${c.sourced_stances} | ${c.unsourced_stances} | ${c.pct_sourced}% |`
```

The MD row renders in the already-written `100-AUDIT-REPORT.md` as:

```
| Migrations 269–271 — MD Officials (...) | 0 | 0 | 0 | 0.0 (0 stances — Phase 103 STAX-02 scope)% |
```

The trailing `%` corrupts the annotation and makes the cell value nonsensical. If this report is used as a Phase 103 planning input, the malformed cell could cause downstream confusion about the zero-stance state of MD officials.

**Fix:** Move the note out of the numeric field. The cleanest option is to keep `pct_sourced` as a plain numeric string and put the scope note in the cohort label or a separate field:

```ts
cohorts.push({
  cohort: 'Migrations 269–271 — MD Officials (Wes Moore, Aruna Miller, Anthony Brown, Brooke Lierman, Dereck Davis) [Phase 103 STAX-02 scope]',
  total_stances: mdRow.total,
  sourced_stances: mdRow.sourced,
  unsourced_stances: String(mdTotal - mdSourced),
  pct_sourced: '0.0',   // zero stances; computed to be consistent
});
```

Alternatively, make the `%` suffix conditional in `buildReport`:

```ts
const pctCell = /^\d/.test(c.pct_sourced) ? `${c.pct_sourced}%` : c.pct_sourced;
return `| ${c.cohort} | ${c.total_stances} | ${c.sourced_stances} | ${c.unsourced_stances} | ${pctCell} |`;
```

The existing `100-AUDIT-REPORT.md` must be regenerated after the fix.

---

## Warnings

### WR-01: v2.3 Senators Cohort Query Missing DISTINCT — Double-Counts Stances for Multi-Office Senators

**File:** `backend/scripts/run-source-coverage-audit.ts:200-211`

**Issue:** The senators cohort query uses inner joins to `offices` and `districts` without any DISTINCT protection:

```sql
JOIN essentials.offices o ON o.politician_id = pa.politician_id AND o.is_vacant = false
JOIN essentials.districts d ON d.id = o.district_id AND d.district_type = 'NATIONAL_UPPER'
```

If a senator has more than one non-vacant `NATIONAL_UPPER` office record (e.g., a class-transfer record, a data import anomaly, or overlapping term records), each `politician_answers` row is fanned out once per matching office, doubling that senator's contribution to `total` and `sourced`. The main tier query (Query B) and per-politician target list (Query D) both use a `DISTINCT ON` subquery to prevent exactly this. The senators cohort does not, so its totals are inconsistent with the tier breakdown if any senator has multiple matching office rows.

**Fix:** Replace the inner joins with an `EXISTS` subquery, which prevents fan-out regardless of duplicate office rows:

```sql
FROM inform.politician_answers pa
LEFT JOIN inform.politician_context pc
  ON pc.politician_id = pa.politician_id
  AND pc.topic_id = pa.topic_id
JOIN essentials.politicians p ON p.id = pa.politician_id AND p.is_active = true
WHERE EXISTS (
  SELECT 1
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE o.politician_id = pa.politician_id
    AND o.is_vacant = false
    AND d.district_type = 'NATIONAL_UPPER'
)
```

### WR-02: `DATABASE_URL` Not Validated Before Pool Construction

**File:** `backend/scripts/run-source-coverage-audit.ts:34`

**Issue:** The pool is constructed immediately after `dotenv.config()` without checking that `DATABASE_URL` is present:

```ts
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
```

`pg.Pool` accepts `connectionString: undefined` without throwing at construction time. The failure surfaces only at the first `pool.query()` call with a generic connection error that gives no indication the env var is absent. The most common failure mode for this script run in a new environment or CI context is a missing `.env` file — and this produces a maximally confusing diagnostic.

**Fix:** Guard immediately after `dotenv.config()`:

```ts
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

if (!process.env.DATABASE_URL) {
  console.error('Fatal: DATABASE_URL is not set. Ensure backend/.env exists and contains DATABASE_URL.');
  process.exit(1);
}

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
```

### WR-03: `writeFileSync` Throws Unhelpful `ENOENT` If Output Directory Does Not Exist

**File:** `backend/scripts/run-source-coverage-audit.ts:713-716`

**Issue:** Both `writeFileSync` calls assume `.planning/phases/100-source-coverage-audit/` already exists. If the directory is absent (fresh clone, renamed phase directory, different working tree), the write throws `ENOENT: no such file or directory, open '...100-AUDIT-REPORT.md'` with no user-friendly message. This happens after all six database queries have already run and succeeded.

**Fix:** Add `mkdirSync` before the writes:

```ts
import { writeFileSync, mkdirSync } from 'node:fs';

// In main(), before writeFileSync calls:
mkdirSync(phaseDir, { recursive: true });
writeFileSync(reportPath, report, 'utf8');
writeFileSync(csvPath, csv, 'utf8');
```

### WR-04: Unsourced Detection CASE Expression Duplicated Four Times in Query D — Four-Point Maintenance Surface

**File:** `backend/scripts/run-source-coverage-audit.ts:322-334`, `:336-351`, `:417-429`, `:433-459`

**Issue:** The "is this stance unsourced?" CASE expression (the logical inverse of `SOURCED_CASE`) is copy-pasted verbatim four times within `queryTargetList()` alone: once for `unsourced_count`, once for `unsourced_pct`, once in the `HAVING` clause, and once in the `ORDER BY` clause. The `SOURCED_CASE` constant at line 95 already establishes the pattern of centralizing this logic, but the inverse was never extracted. If the "sourced" definition changes for a future v2.8 audit (e.g., adding a minimum URL path-depth requirement), all four copies in Query D must be updated in lockstep with `SOURCED_CASE`. A mismatch between them would produce inconsistent counts within the same query — `unsourced_count` could differ from what the `ORDER BY` uses.

**Fix:** Add a module-level `UNSOURCED_CASE` constant mirroring the pattern of `SOURCED_CASE`:

```ts
const UNSOURCED_CASE = `
  CASE
    WHEN pc.politician_id IS NULL
         OR pc.sources IS NULL
         OR array_length(pc.sources, 1) IS NULL
         OR NOT EXISTS (
           SELECT 1 FROM unnest(pc.sources) AS s(url)
           WHERE url IS NOT NULL AND trim(url) <> ''
         )
    THEN 1
    ELSE 0
  END`;
```

Then replace all four inline copies in `queryTargetList()` with `${UNSOURCED_CASE}`, and verify that `SOURCED_CASE` and `UNSOURCED_CASE` are exact logical inverses (swap `THEN 1 ELSE 0` ↔ `THEN 0 ELSE 1`).

---

## Info

### IN-01: `queryMdOfficials` Lacks `is_active = true` Filter — Inconsistent With All Other Queries

**File:** `backend/scripts/run-source-coverage-audit.ts:501-513`

**Issue:** Every other query in this script filters `WHERE p.is_active = true`. `queryMdOfficials` only filters by `external_id` range:

```sql
WHERE p.external_id BETWEEN -240005 AND -240001
```

If any of the five MD officials are later deactivated (e.g., Wes Moore leaves office mid-term), they will still appear in the MD Officials section of the report while being absent from the executive summary and tier breakdown. The resulting report would document politicians the platform no longer tracks, with stance counts that contradict the totals above.

**Fix:**

```sql
WHERE p.external_id BETWEEN -240005 AND -240001
  AND p.is_active = true
```

### IN-02: Dry-Run Path Returns Without `process.exit` — Inconsistent With Non-Dry-Run Path

**File:** `backend/scripts/run-source-coverage-audit.ts:697-701`

**Issue:** The dry-run path calls `pool.end()` and `return`s from `main()`. The non-dry-run path (line 721) explicitly calls `process.exit(0)`. If any async handle other than the pool is ever added (e.g., an HTTP client, a file watcher), the dry-run path will hang while the non-dry-run path exits cleanly. Currently no such handles exist, but the inconsistency is a maintenance trap.

**Fix:** Add `process.exit(0)` after `pool.end()` in the dry-run branch:

```ts
if (DRY_RUN) {
  console.error('\nDry run complete — no files written.');
  await pool.end();
  process.exit(0);
}
```

---

_Reviewed: 2026-06-05T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
