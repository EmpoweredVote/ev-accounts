---
phase: 102
status: findings
reviewed: 2026-06-06
depth: standard
files_reviewed: 2
files_reviewed_list:
  - backend/scripts/run-house-source-triage.ts
  - supabase/migrations/20260606000002_269_house_source_remediation.sql
findings:
  critical: 0
  warning: 3
  info: 3
  total: 6
---

# Phase 102: Code Review Report

**Reviewed:** 2026-06-06
**Depth:** standard
**Files Reviewed:** 2
**Status:** findings

## Summary

The migration is structurally sound — wrapped in BEGIN/COMMIT, idempotent schema_migrations insert, correct DELETE-before-context ordering, and all UUIDs are hardcoded literals with no injection surface. The triage script has no SQL injection risk (all interpolated strings are hardcoded constants, never user input), pool lifecycle is correctly managed, and the dry-run path is safe. Three warnings are flagged: a Markdown table injection risk from unescaped `|` in source URLs written into report cells, a CSV quoting gap for the `party` field, and a type annotation mismatch on `source_status`. Three info items cover code duplication, a fragile pipe-delimiter choice, and magic-number batching text hardcoded in the report builder.

---

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Markdown table cells not escaped — pipe characters in source URLs break table rendering

**File:** `backend/scripts/run-house-source-triage.ts:764-769, 793-798, 822-827, 851-856`

**Issue:** Source URLs retrieved from `inform.politician_context.sources` are joined with `, ` and written directly into Markdown table cells:

```typescript
const sourcesDisplay = d.current_sources && d.current_sources.length > 0
  ? d.current_sources.join(', ')
  : '_(none)_';
houseUnsourcedSection += `| ${d.topic_key} | ${d.current_value} | ${sourcesDisplay} |\n`;
```

A source URL containing a `|` character (e.g. a URL with query parameters like `?a=1|b=2`, or a miscoded entry) will split the cell and corrupt every subsequent column in that table row. `d.full_name` and `d.state` in the section headers are also interpolated without escaping, and politician names with parentheses or pipe characters would similarly break the heading structure.

**Fix:** Escape or strip `|` before interpolation into table cells:

```typescript
const escapeCell = (s: string) => s.replace(/\|/g, '\\|');
const sourcesDisplay = d.current_sources && d.current_sources.length > 0
  ? d.current_sources.map(escapeCell).join(', ')
  : '_(none)_';
```

Apply `escapeCell` to `d.topic_key`, `d.current_value.toString()`, `rep.full_name`, `rep.state`, `rep.party` wherever they appear inside table cells.

---

### WR-02: CSV `party` field is unquoted — comma in value would corrupt row structure

**File:** `backend/scripts/run-house-source-triage.ts:938`

**Issue:** The CSV row builder quotes `full_name` and `affected_topic_keys` but leaves `party`, `state`, `scope`, `total_stances`, `unsourced_count`, `weak_count`, and `classification` as bare interpolated values:

```typescript
return `${escapedName},${r.politician_id},${r.scope},${r.state},${r.party},${r.total_stances},${r.unsourced_count},${r.weak_count},${topicKeys},${r.classification}`;
```

`party` values from the DB are currently short strings (e.g. `R`, `D`, `Independent`) and do not contain commas. However, if a party value were ever `"American Conservative, Reform"` or similar, it would silently shift all subsequent fields in the row without any parse-time error. The risk is low given current data, but the fix is trivial.

**Fix:** Quote all string fields, not just `full_name` and `affected_topic_keys`:

```typescript
const q = (s: string) => `"${String(s).replace(/"/g, '""')}"`;
return `${q(r.full_name)},${q(r.politician_id)},${q(r.scope)},${q(r.state)},${q(r.party)},${r.total_stances},${r.unsourced_count},${r.weak_count},${topicKeys},${q(r.classification)}`;
```

Numeric-typed columns (`total_stances`, `unsourced_count`, `weak_count`) are safe to leave unquoted since they are cast to `::text` as integers in SQL.

---

### WR-03: `source_status` typed as `string` but SQL CASE can return NULL

**File:** `backend/scripts/run-house-source-triage.ts:122, 541-543, 623-625`

**Issue:** The `DetailRow` interface declares `source_status: string` (non-nullable), but the SQL CASE expression in both `queryHouseTopicDetail` and `queryDeferredCandidateTopicDetail` has an `ELSE NULL` branch:

```sql
CASE
  WHEN ... THEN 'unsourced'
  WHEN ... THEN 'weak'
  ELSE NULL          -- ← returns NULL when neither condition matches
END AS source_status
```

The WHERE clause that follows does filter to only unsourced or weak rows, so `NULL` cannot appear in practice. However the type annotation is incorrect: if the WHERE clause were ever relaxed or a query were reused elsewhere, downstream callers filtering on `d.source_status === 'unsourced'` would silently miss `null` rows without a TypeScript compile error.

**Fix:** Either change the ELSE branch to `ELSE 'sourced'` to make the intent explicit and match the type, or update the interface:

```typescript
interface DetailRow {
  // ...
  source_status: 'unsourced' | 'weak' | null;
}
```

---

## Info

### IN-01: Four query functions share near-identical SQL — extract shared CTE builder to reduce drift risk

**File:** `backend/scripts/run-house-source-triage.ts:180-660`

**Issue:** `queryHouseSummary` / `queryDeferredCandidateSummary` and `queryHouseTargets` / `queryDeferredCandidateTargets` are exact structural duplicates — the only differences are the CTE name (`house_politicians` vs `deferred_candidates`) and the alias used inside the query body (`hp` vs `dc`). The weak-source CASE expression is copy-pasted six times across the file. If the sourced definition (locked D-01) needs to change, every copy must be updated in sync.

**Fix:** Parameterize by CTE string and alias, or extract a shared `buildWeakCaseExpr()` function that returns the CASE SQL fragment. The existing `SOURCED_CASE` / `UNSOURCED_CASE` constants are a good pattern — extend it to the weak-source CASE.

---

### IN-02: Pipe delimiter for `affected_topic_keys` is fragile — topic_keys with `|` would corrupt split

**File:** `backend/scripts/run-house-source-triage.ts:358, 481, 371, 494`

**Issue:** `array_to_string(affected_topic_keys, '|')` in SQL is split on `|` in JavaScript. Current topic_keys are alphanumeric with hyphens and will never contain `|`. But this is an implicit contract with no enforcement — if a future topic_key were added containing `|`, the split would silently produce extra elements and corrupt `affected_topic_keys` arrays in `TargetRow`. The PHP-era pipe delimiter is a known fragility pattern.

**Fix:** Use a delimiter that cannot appear in a topic_key by convention — `||` (double-pipe) is a common choice, or simply use the PostgreSQL array format directly and parse it server-side:

```sql
-- Pass as Postgres text array, let the pg driver parse it
array_agg(DISTINCT t.topic_key) FILTER (...) AS affected_topic_keys
```

Then receive it as `string[]` directly (the `pg` driver parses Postgres array literals into JS arrays), removing the round-trip through `array_to_string` and `.split('|')` entirely.

---

### IN-03: Batching recommendation and dispatch order are hardcoded in `buildReport` — will produce stale output if triage results differ from research-time expectations

**File:** `backend/scripts/run-house-source-triage.ts:879-883`

**Issue:** The scoping note embedded in the report hardcodes the expected outcome from Phase 102 research:

```typescript
`- 1 research plan covers all 3 deferred candidates (one research-stances agent dispatch per candidate)
- Dispatch order: Dooley (GA, 6 weak topics), Shoffner (AR, 5 weak topics), Alme (MT, 8 weak topics)`
```

These lines are static strings — they do not derive from the query results. If the triage script is re-run after further remediation (e.g., partial fixes applied between runs), the generated report will still say "6 weak topics" for Dooley even if the count has changed. The rest of the report body (tables, counts) correctly reflects live DB state.

**Fix:** Derive the dispatch order summary from `deferredTargets` and `deferredDetails` dynamically:

```typescript
const dispatchLines = deferredTargets.map((t) => {
  const weakCount = deferredDetails.filter(
    (d) => d.politician_id === t.politician_id && d.source_status === 'weak'
  ).length;
  return `- ${t.full_name} (${t.state}, ${weakCount} weak topics)`;
}).join('\n');
```

---

_Reviewed: 2026-06-06_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
