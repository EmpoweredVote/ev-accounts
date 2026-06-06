---
phase: 101-candidate-profiles
reviewed: 2026-06-05T23:30:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - backend/scripts/run-senator-source-triage.ts
  - supabase/migrations/20260606000001_268_senator_source_remediation.sql
findings:
  critical: 1
  warning: 4
  info: 2
  total: 7
status: issues_found
---

# Phase 101: Code Review Report

**Reviewed:** 2026-06-05T23:30:00Z
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Two files reviewed: the senator-scope triage script (`run-senator-source-triage.ts`) and
the source remediation migration (`20260606000001_268_senator_source_remediation.sql`).

The migration itself is structurally sound: properly wrapped in `BEGIN/COMMIT`, UUIDs are
hardcoded (no user input), and the DELETE ordering (context before answers) avoids FK
violations. The triage script correctly implements the locked sourced/unsourced definition
and scopes to 100 sitting senators via `DISTINCT ON (p.id) + is_incumbent = true`.

One critical correctness bug was found: the post-migration verification block inside the
migration omits the `is_incumbent = true` filter that the triage script established as
required to scope to exactly 100 senators. This means the RAISE NOTICE counts include 43
2026 Senate candidates, making V1=0 an unreliable assertion — the migration could have
silently passed its own verification check while leaving candidate stances unsourced. Four
warnings cover the pool-leak path in the triage script, the `classification = 'both'` edge
case producing misleading output, a pipe-delimiter collision risk in topic keys, and the
`!~ trim()` double-trim inconsistency between the triage script and the migration. Two info
items flag the `process.exit(0)` that suppresses pool cleanup and a magic string repetition.

---

## Critical Issues

### CR-01: Migration V1/V2 verification queries omit `is_incumbent = true` — scope diverges from triage script

**File:** `supabase/migrations/20260606000001_268_senator_source_remediation.sql:68-95`

**Issue:** The triage script (Plan 01) discovered that `district_type = 'NATIONAL_UPPER'`
alone returns 143 politicians (100 sitting senators + 43 2026 candidates), and it added
`AND p.is_incumbent = true` to scope correctly to 100 senators. The post-migration
verification block in this migration does **not** carry that filter:

```sql
-- V1 (line 69-74):
SELECT DISTINCT p.id
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id AND o.is_vacant = false
JOIN essentials.districts d ON d.id = o.district_id
WHERE d.district_type = 'NATIONAL_UPPER' AND p.is_active = true
-- ^^^ missing: AND p.is_incumbent = true
```

The same omission is in the V2 block (lines 91-96).

**Consequence:** When this migration ran, V1 checked unsourced stances across all 143
NATIONAL_UPPER politicians, not just the 100 senators this phase was responsible for.
The RAISE NOTICE asserted V1=0 but that count included 2026 Senate candidates — the
19 pre-existing homepage-only rows for Dooley/Shoffner/Alme were counted in V2 but
silently excluded from V1 only because they happened to have context rows. The
verification is measuring a broader population than FEDX-01 requires, so RAISE NOTICE
"unsourced senator stances: 0" is semantically misleading: it means "unsourced
NATIONAL_UPPER active politician stances = 0" which is a different (stronger) claim.
In the other direction, if any 2026 candidate had an unsourced stance, V1 would have
reported a non-zero count even though FEDX-01 only covers sitting senators — a false
positive would cause confusion on re-run.

**Fix:** Add `AND p.is_incumbent = true` to both subqueries:

```sql
-- V1 fix
WHERE pa.politician_id IN (
  SELECT DISTINCT p.id
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.politician_id = p.id AND o.is_vacant = false
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type = 'NATIONAL_UPPER'
    AND p.is_active = true
    AND p.is_incumbent = true   -- ADD THIS
)

-- V2 fix (same addition)
WHERE pc.politician_id IN (
  SELECT DISTINCT p.id
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.politician_id = p.id AND o.is_vacant = false
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type = 'NATIONAL_UPPER'
    AND p.is_active = true
    AND p.is_incumbent = true   -- ADD THIS
)
```

Note: the migration has already been applied. This fix belongs in the next migration that
touches senator verification queries, or in a follow-up migration if the verification
block is re-run for audit purposes.

---

## Warnings

### WR-01: Pool not closed on error path when `writeFileSync` throws

**File:** `backend/scripts/run-senator-source-triage.ts:605-614`

**Issue:** After queries complete, `writeFileSync` is called directly in `main()` without
a try/catch. If either write fails (disk full, permission error on the path), the function
throws, the top-level `.catch` calls `pool.end()` correctly — but only because the catch
handler was added. However `pool.end()` in the catch handler is called with `.catch(() => {})`
which silently swallows pool-close errors. More importantly: the `process.exit(0)` at
line 633 runs only on the happy path. The catch handler at line 637 calls `process.exit(1)`.
The combination is fine for the error path, but the `pool.end()` in the catch handler is
not awaited:

```ts
main().catch((err) => {
  console.error('Fatal error:', err);
  pool.end().catch(() => {});   // NOT awaited — process may exit before pool closes
  process.exit(1);
});
```

`pool.end()` is async; calling it without `await` before `process.exit(1)` means the
pool teardown may not complete, potentially leaving dangling connections on the DB server.
For a one-shot script this is low-impact in practice, but it is the same pattern as the
corrected happy path (which does `await pool.end()`).

**Fix:**
```ts
main().catch(async (err) => {
  console.error('Fatal error:', err);
  try { await pool.end(); } catch { /* ignore */ }
  process.exit(1);
});
```

---

### WR-02: `classification = 'both'` edge case — `CASE` falls through to `'both'` when both counts are zero

**File:** `backend/scripts/run-senator-source-triage.ts:288-292`

**Issue:** The final SELECT in `querySenatorTargets` computes classification:

```sql
CASE
  WHEN unsourced_count > 0 AND weak_count = 0 THEN 'unsourced_only'
  WHEN unsourced_count = 0 AND weak_count > 0 THEN 'weak_only'
  ELSE 'both'
END AS classification
```

Any senator row that makes it past the `HAVING` clause has at least one of
`unsourced_count > 0` or `weak_count > 0`, so the `ELSE 'both'` should never fire for
a zero/zero row. However, this `CASE` is evaluated in the outer query over `per_senator`,
and the `HAVING` clause is on `per_senator` — both clauses reference the same aggregated
values so there is no logical gap.

The actual bug is subtler: if `unsourced_count = 0 AND weak_count = 0` (theoretically
impossible given the HAVING, but possible if the CTE is copy-pasted without the HAVING),
the `ELSE 'both'` produces a misleading `'both'` label for a senator with no issues.
The `determineBatchingTier` call and all downstream report sections assume every row in
`targets` has at least one problem; if a zero/zero row ever appears, it would inflate
`totalFlagged`, `batchingLabel`, and batch plan counts.

More concretely: the `ELSE` branch should never be reached only because of the HAVING.
If that HAVING is removed or modified in a future copy-paste, the misclassification
would be silent. A defensive `ELSE 'unknown'` (or adding an explicit
`WHEN unsourced_count > 0 AND weak_count > 0 THEN 'both'`) would surface this.

**Fix:**
```sql
CASE
  WHEN unsourced_count > 0 AND weak_count = 0 THEN 'unsourced_only'
  WHEN unsourced_count = 0 AND weak_count > 0 THEN 'weak_only'
  WHEN unsourced_count > 0 AND weak_count > 0 THEN 'both'
  ELSE 'unknown'   -- should never fire; surfaces logic errors
END AS classification
```

---

### WR-03: `affected_topic_keys` pipe-delimiter collides if a topic_key ever contains `|`

**File:** `backend/scripts/run-senator-source-triage.ts:287,299`

**Issue:** Topic keys are joined with `'|'` in SQL (`array_to_string(affected_topic_keys, '|')`)
and then split on `'|'` in TypeScript (`r.affected_topic_keys.split('|')`). Current
topic keys (`ai-regulation`, `climate`, etc.) do not contain `|`, so this works today.
But there is no schema constraint on `compass_topics.topic_key` preventing a `|` character,
and the pattern has no escaping. If a future topic key contained `|`, the split would
silently corrupt the key list in the CSV and the report.

The CSV builder (`buildCsv`) also writes `affected_topic_keys` pipe-delimited inside a
quoted field. A topic key with `|` would split into spurious entries when consumed by
any downstream CSV reader that expects the `|` separator to be meaningful.

**Fix:** Use a delimiter that cannot appear in a slug-style topic key, such as `;` or
`,`, or use the Postgres array literal syntax and parse it properly. Alternatively, add
a DB-level check constraint: `CHECK (topic_key ~ '^[a-z0-9-]+$')` to guarantee
topic keys are slug-safe.

---

### WR-04: Regex `trim()` applied inconsistently between triage script and migration

**File:** `backend/scripts/run-senator-source-triage.ts:163,217,244,375` vs `supabase/migrations/20260606000001_268_senator_source_remediation.sql:102`

**Issue:** The homepage-only regex check in the triage script applies `trim()` before
the `!~` test:

```sql
-- triage script (e.g. line 163):
AND trim(url) !~ '^https?://[^/]+/?$'
```

The migration's V2 verification block also applies `trim()` (line 102):
```sql
AND trim(u) !~ '^https?://[^/]+/?$'
```

These two are consistent. However the `EXISTS` companion clause in the triage script
uses `trim(url) <> ''` but the regex test applies to the already-trimmed string
`trim(url)`. This is correct. The inconsistency is minor: the script uses `<>` for
blank check but `!=` is used in the migration (`trim(u) != ''` at lines 81 and 101 vs
`trim(url) <> ''` in the triage script). In Postgres `!=` and `<>` are identical
operators, so this is not a functional bug, but it is a consistency gap between the
two files that makes auditing the "locked definition" harder.

**Fix:** Standardise on `<>` (the SQL standard operator) in both files. When copying
the SOURCED/UNSOURCED definition to future scripts, use a single canonical source file
or a shared SQL file to prevent drift.

---

## Info

### IN-01: `process.exit(0)` in `main()` preempts async resource cleanup visibility

**File:** `backend/scripts/run-senator-source-triage.ts:633`

**Issue:** The happy path ends with:
```ts
await pool.end();
process.exit(0);
```

The `await pool.end()` is correct. The explicit `process.exit(0)` is redundant —
Node exits naturally when the event loop drains — and it prevents any registered
`process.on('exit', ...)` handlers from seeing a clean shutdown. It is a minor style
issue for a one-shot script, but the pattern diverges from the `--dry-run` path (which
just returns from `main()` without `process.exit`).

**Fix:** Remove `process.exit(0)` from the happy path; `await pool.end()` is sufficient.

---

### IN-02: `HOMEPAGE_ONLY_REGEX` constant includes surrounding single-quotes as part of the string literal

**File:** `backend/scripts/run-senator-source-triage.ts:84`

**Issue:**
```ts
const HOMEPAGE_ONLY_REGEX = `'^https?://[^/]+/?$'`;
```

The single-quotes are baked into the TypeScript constant and are required because the
value is interpolated directly into a SQL string context
(`trim(url) !~ ${HOMEPAGE_ONLY_REGEX}`). This is correct SQL but the constant's type
does not communicate that it carries its own quoting. If the constant were ever used
outside a direct string-interpolation context (e.g., passed to a parameterised query
as `$1`), the embedded quotes would be sent as part of the regex pattern and the match
would silently fail (the pattern would be `'^https?://[^/]+/?$'` with literal
apostrophes, not a valid Postgres regex).

This is not a current bug — all usages are via template-literal interpolation. But the
naming and convention make the quoting implicit and surprising.

**Fix:** Either document clearly in the constant's JSDoc that it includes SQL quoting
characters, or define it without quotes and add them at each usage site:

```ts
/** Postgres regex pattern — do NOT include in parameterised query as $1 */
const HOMEPAGE_ONLY_REGEX_PATTERN = `^https?://[^/]+/?$`;
// usage: `trim(url) !~ '${HOMEPAGE_ONLY_REGEX_PATTERN}'`
```

---

_Reviewed: 2026-06-05T23:30:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
