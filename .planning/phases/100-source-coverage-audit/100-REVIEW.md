---
phase: 100-source-coverage-audit
reviewed: 2026-06-05T00:00:00Z
depth: standard
files_reviewed: 1
files_reviewed_list:
  - backend/scripts/run-source-coverage-audit.ts
findings:
  critical: 1
  warning: 3
  info: 3
  total: 7
status: issues_found
---

# Phase 100: Code Review Report

**Reviewed:** 2026-06-05
**Depth:** standard
**Files Reviewed:** 1
**Status:** issues_found

## Summary

Reviewed `backend/scripts/run-source-coverage-audit.ts` — a one-shot read-only audit script that queries the live production DB via `pg.Pool` and writes a markdown report + CSV. No user input surfaces into SQL (no injection risk). No secrets are echoed. The main defects are: one data-correctness blocker in the v2.5 cohort range exclusion (Sacramento block 66 leaks in), one cosmetic corruption bug in the MD cohort `pct_sourced` cell, a `majority_unsourced` boundary that is inconsistent with its label, and a missing `is_active` guard on the MD officials query.

---

## Critical Issues

### CR-01: v2.5 Cohort Exclusion Range Fails to Exclude Block 66 (Sacramento)

**File:** `backend/scripts/run-source-coverage-audit.ts:264-265`

**Issue:** The intent is to include external_id blocks 63, 64, 65, 67, 68 (SF, SJ, SD, Fremont, Berkeley) and exclude block 66 (Sacramento). The outer range `BETWEEN -689999 AND -630000` includes blocks 63–68. The exclusion `NOT BETWEEN -669999 AND -660000` is meant to remove block 66 (-660001 to -660999).

In PostgreSQL, `BETWEEN a AND b` means `a <= x <= b`. On the number line: -669999 < -660001 < -660000. So `-660001 <= -660000` is **false** — -660001 is one unit below -660000. The exclusion window `BETWEEN -669999 AND -660000` does **not** capture -660001 through -660999. Every Sacramento official (block 66, IDs like -660001, -660002, ...) passes the NOT BETWEEN check and is included in the v2.5 cohort count. The audit numbers for "v2.5 — City Officials" are silently inflated.

**Fix:** Shift the lower bound of the exclusion window down by 1 to capture the full block 66:

```sql
-- Before (broken):
WHERE p.external_id BETWEEN -689999 AND -630000
  AND p.external_id NOT BETWEEN -669999 AND -660000

-- After (correct):
WHERE p.external_id BETWEEN -689999 AND -630000
  AND p.external_id NOT BETWEEN -669999 AND -660001
```

The corrected bound `-660001` means `BETWEEN -669999 AND -660001` captures all values from -669999 up to and including -660001, which fully excludes the block 66 range (-660001 to -660999).

---

## Warnings

### WR-01: `pct_sourced` Appended With `%` for MD Cohort Row — Produces Malformed Table Cell

**File:** `backend/scripts/run-source-coverage-audit.ts:300` and `532`

**Issue:** The MD officials cohort hardcodes `pct_sourced` as:
```
'0.0 (0 stances — Phase 103 STAX-02 scope)'
```
The `buildReport` function at line 532 unconditionally appends `%` after every `c.pct_sourced` value:
```ts
`| ${c.cohort} | ${c.total_stances} | ${c.sourced_stances} | ${c.unsourced_stances} | ${c.pct_sourced}% |`
```
The MD row will render as:
```
| Migrations 269–271 — MD Officials (...) | 0 | 0 | 0 | 0.0 (0 stances — Phase 103 STAX-02 scope)% |
```
The stray `%` corrupts the cell and renders the annotation unreadable in the final markdown report.

**Fix:** Either omit the `%` suffix in `buildReport` by making it conditional, or strip the note from `pct_sourced` and put it in a separate note column or the cohort label:

```ts
// Option A: Keep suffix unconditional, move the note out of pct_sourced
cohorts.push({
  cohort: 'Migrations 269–271 — MD Officials (...) — Phase 103 STAX-02 scope',
  total_stances: mdRow.total,
  sourced_stances: mdRow.sourced,
  unsourced_stances: String(mdTotal - mdSourced),
  pct_sourced: '0.0',
});

// Option B: Make the % conditional in buildReport
`| ${c.pct_sourced.includes('%') ? c.pct_sourced : c.pct_sourced + '%'} |`
```

---

### WR-02: `majority_unsourced` Uses Strict `>` — Excludes Exactly-50%-Unsourced Politicians

**File:** `backend/scripts/run-source-coverage-audit.ts:362-365` and `417-429` and `443-446`

**Issue:** The expression `SUM(...) > COUNT(pa.topic_id) / 2.0` marks a politician as `majority_unsourced = true` only when strictly more than half their stances are unsourced. A politician with exactly 50% unsourced (e.g., 3 unsourced out of 6 total) returns `3 > 3.0 = false` and is **not** flagged. The column name `majority_unsourced` and the sort that places `true` rows first strongly imply ">= 50%" to readers using the CSV to triage remediation work. A politician at exactly half unsourced will be silently de-prioritized.

**Fix:** Change `>` to `>=` if the intent is "half or more unsourced":

```sql
-- Before:
SUM(...) > COUNT(pa.topic_id) / 2.0

-- After (if >= 50% is the intended threshold):
SUM(...) >= COUNT(pa.topic_id) / 2.0
```

This expression appears in three places: the SELECT (line 362–365), the HAVING (lines 417–429 does not use this — OK), and the ORDER BY (lines 443–446). All three must be updated consistently.

---

### WR-03: `queryMdOfficials` Lacks `is_active = true` Filter

**File:** `backend/scripts/run-source-coverage-audit.ts:501-513`

**Issue:** Every other query in this script guards against deactivated politicians with `WHERE p.is_active = true` or `AND p.is_active = true`. `queryMdOfficials` omits this filter:

```sql
WHERE p.external_id BETWEEN -240005 AND -240001
```

If any of the five MD officials are later deactivated (e.g., Wes Moore leaves office), they would still appear in the MD Officials section of the audit report while being absent from the executive summary and tier breakdown (which all use `is_active = true`). The report would then document officials the platform no longer tracks, and the stance counts shown would contradict the totals above.

**Fix:**

```sql
WHERE p.external_id BETWEEN -240005 AND -240001
  AND p.is_active = true
```

---

## Info

### IN-01: `pct_sourced` Rounding Method Differs Between SQL Queries and JavaScript (Query C)

**File:** `backend/scripts/run-source-coverage-audit.ts:220` and `244` and `274`

**Issue:** Queries A, B, D, E compute `pct_sourced` in Postgres using `ROUND(..., 1)`, which applies banker's rounding (round half to even). Query C (milestone cohorts) computes `pct_sourced` in JavaScript:

```ts
String(Math.round((sourced / total) * 1000) / 10)
```

`Math.round` always rounds 0.5 up (away from zero), which can produce a result that differs from Postgres `ROUND` by 0.1 at the midpoint boundary. The executive summary and tier table (computed by Postgres) may show 55.5% for a cohort while the milestone table (computed by JS) shows 55.6% for that same cohort's slice. This is a minor inconsistency but could generate misleading comparisons between report sections.

**Fix:** Use Postgres to compute `pct_sourced` in Query C's sub-queries, or implement the same banker's rounding in JS:

```ts
// Simple fix: delegate to Postgres for consistency
// Add pct_sourced to the SELECT in each cohort subquery:
ROUND(COALESCE(SUM(...), 0) * 100.0 / NULLIF(COUNT(*), 0), 1)::text AS pct_sourced
```

---

### IN-02: Dry-Run Path Returns Without Explicit `process.exit` — Potential Hang Risk

**File:** `backend/scripts/run-source-coverage-audit.ts:697-701`

**Issue:** The dry-run exit path calls `pool.end()` and `return`s from `main()` without `process.exit(0)`. The non-dry-run happy path (line 721) uses `process.exit(0)`. If any async handle other than the pool is open at the time `main()` returns in dry-run mode, Node will hang. Currently no such handles exist, but the inconsistency between the two exit paths is a maintenance trap.

**Fix:** Add `process.exit(0)` after `pool.end()` in the dry-run branch for consistency:

```ts
if (DRY_RUN) {
  console.error('\nDry run complete — no files written.');
  await pool.end();
  process.exit(0);  // consistent with non-dry-run path
}
```

---

### IN-03: `queryTotal` and `queryWeakSources` Access `rows[0]` Without Guard

**File:** `backend/scripts/run-source-coverage-audit.ts:127` and `489`

**Issue:** Both functions return `result.rows[0]` directly. For `COUNT`/`SUM` aggregate queries with no `GROUP BY`, Postgres always returns exactly one row, so this cannot fail in practice. However the TypeScript types for `result.rows[0]` are technically `TotalRow | undefined` — any future refactor adding a `WHERE FALSE` short-circuit or UNION branch could trigger a `TypeError` that is invisible to the type checker because `pool.query<TotalRow>` does not narrow the return to a non-optional type.

**Fix:** Add a defensive check or assertion, which also documents the invariant:

```ts
const row = result.rows[0];
if (!row) throw new Error('queryTotal returned no rows — unexpected DB state');
return row;
```

---

_Reviewed: 2026-06-05_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
