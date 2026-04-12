---
phase: 112-data-completeness-audit
reviewed: 2026-04-12T00:00:00Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - ev-accounts/backend/scripts/audit-112-assemble.ts
  - ev-accounts/backend/scripts/audit-112-candidates.ts
  - ev-accounts/backend/scripts/audit-112-geofence.ts
  - ev-accounts/backend/scripts/audit-112-headshots.ts
  - ev-accounts/backend/scripts/audit-112-profile.ts
  - ev-accounts/backend/scripts/audit-112-quotes.ts
  - ev-accounts/backend/scripts/audit-112-races.ts
  - ev-accounts/backend/scripts/audit-112-stances.ts
findings:
  critical: 0
  warning: 4
  info: 7
  total: 11
status: issues_found
---

# Phase 112: Code Review Report

**Reviewed:** 2026-04-12
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

Reviewed 8 TypeScript audit scripts for Monroe County May 5, 2026 primary data completeness. All scripts are read-only database queries with consistent structure: dotenv loading, election-existence gate, parameterized query, CSV-to-stdout output, and stderr progress. Security posture is good — DATABASE_URL is environment-sourced (never CLI), SQL uses parameterized queries where user-supplied values exist (geofence coordinates), and there are no secrets, eval, or shell injection patterns.

No critical issues. The main concerns are: (1) broken CSV aggregation in the assembler's `extractSummary` — `linked_to_politician` is counted as "linked candidates" when it is actually per-race column, (2) an incorrect assembler parse call that only passes the first line of CSV, (3) inconsistent/hand-rolled CSV escaping in several scripts that will produce malformed CSV if a candidate's name contains an embedded newline, and (4) several DRY-RUN paths write to stderr instead of stdout (inconsistent with the stated dry-run contract). The balance are info-level cleanups.

## Warnings

### WR-01: Assembler `extractSummary` double-counts the "linked candidates" metric

**File:** `ev-accounts/backend/scripts/audit-112-assemble.ts:182-189`
**Issue:** The summary reduces `linked_to_politician` across all candidate CSV rows and reports the sum as "linkedCandidates." That column in `audit-112-candidates.ts` is `COUNT(rc.politician_id)` grouped by race — i.e. the number of linked candidates **in that race**. Summing per-race counts yields the correct global total only because each candidate appears in exactly one race, but the same is true for `total_candidates` and `stub_candidates`. That part is fine. However, the downstream executive summary then compares this value against `stanceCoverage` / `quoteCoverage`, which filter by `is_linked === 'linked'` in the per-candidate CSVs. The two denominators do not match when a candidate appears with a NULL politician_id but a non-empty full_name — the candidates CSV groups by race (all rows counted) while the stances/quotes CSV groups by `(full_name, politician_id)`, deduping stubs with identical names. The reported "X/Y linked candidates have stances" therefore uses a different Y than the candidate-linkage summary.
**Fix:** Source `linkedCandidates` from the same denominator used by stances/quotes — i.e. count rows where `is_linked === 'linked'` in one canonical CSV (e.g., `headshots.csv`, which has one row per `race_candidates` record). Alternatively, document that the two counts intentionally differ.

### WR-02: Assembler parses only the first line of each CSV for the markdown table

**File:** `ev-accounts/backend/scripts/audit-112-assemble.ts:328-329`
**Issue:**
```ts
const csvData = script.name === 'geofence' ? raw : raw; // geofence handled specially below
const csv = script.name === 'geofence' ? parseCsv(raw.split('\n')[0]) : parseCsv(raw);
```
For the geofence script, `parseCsv(raw.split('\n')[0])` passes only the header line, so the stored `csv` for the geofence entry has `rows: []`. This value is then read by `extractSummary` (which does not use geofence) and by the per-section renderer — but the per-section renderer short-circuits to `renderGeofenceSection(result.raw)` using the raw string, so the wrong parse result is harmlessly discarded. The unused `csvData` line is dead code and the ternary is misleading. More importantly, if a future change reads `results.get('geofence').csv` it will silently get an empty table.
**Fix:** Drop the dead `csvData` line and store the geofence entry with a sentinel or the fully-parsed main section:
```ts
const csv = script.name === 'geofence'
  ? parseCsv(raw.split('\nUNLINKED_RACES,')[0])
  : parseCsv(raw);
```

### WR-03: Hand-rolled CSV escaping does not handle embedded newlines or nulls

**File:** `ev-accounts/backend/scripts/audit-112-headshots.ts:106-113`, `audit-112-profile.ts:121-127`, `audit-112-quotes.ts:95-101`, `audit-112-stances.ts:104-115`
**Issue:** These four scripts escape only the `full_name` field with an inline `"${name.replace(/"/g, '""')}"`. Other fields (`cdn_url`, `stub_photo_url`) are written raw. A URL containing a comma (rare but possible in query strings) or a name containing a literal newline character will corrupt the CSV. The `audit-112-races.ts` and `audit-112-candidates.ts` scripts use a proper `escapeCsv()` helper — the headshots/profile/quotes/stances scripts should too. Also, `rc.full_name` is typed as non-null but there is no DB-level NOT NULL guarantee visible here; a null value would throw on `.replace()`.
**Fix:** Lift `escapeCsv()` into a shared helper (or copy into each script) and apply it to every field:
```ts
function escapeCsv(value: string | number | null | undefined): string {
  if (value === null || value === undefined) return '';
  const str = String(value);
  return /[",\n\r]/.test(str) ? `"${str.replace(/"/g, '""')}"` : str;
}
```

### WR-04: DRY-RUN paths mix stdout and stderr inconsistently

**File:** `ev-accounts/backend/scripts/audit-112-headshots.ts:90-98`, `audit-112-profile.ts:107-115`, `audit-112-quotes.ts:78-86`, `audit-112-stances.ts:86-94`
**Issue:** The script headers document that "Progress messages go to stderr" and CSV data goes to stdout. In DRY-RUN, `audit-112-races.ts` and `audit-112-candidates.ts` write their summary to **stdout** via `console.log`, while headshots/profile/quotes/stances write to **stderr** via `console.error`. The assembler captures stdout via `execSync` and saves it to `{name}.csv`. When run with `--dry-run`, the four stderr-only scripts produce empty CSV files (0 bytes) while races.csv and candidates.csv contain summary text that is not valid CSV. Downstream `parseCsv` will treat these as headers-only and silently produce empty tables. The `rowCount` calculation at line 333 of the assembler (`split('\n').filter(...).length - 1`) will then report -1 rows for empty stdout.
**Fix:** Standardize DRY-RUN output. Either route all DRY-RUN summaries to stderr (and have the assembler skip CSV writes when `--dry-run` is set), or route them all to stdout as `key,value` CSV. Also guard against negative rowCount: `Math.max(0, nonEmptyLines - 1)`.

## Info

### IN-01: `audit-112-candidates.ts` GROUP BY includes `r.id` but not in SELECT

**File:** `ev-accounts/backend/scripts/audit-112-candidates.ts:103`
**Issue:** `GROUP BY r.id, r.position_name, r.primary_party` groups by race identity (correct, since two distinct races can share a `position_name`), but the SELECT emits only `position_name, primary_party`. If two races in the same party share a name, the CSV will have two indistinguishable rows. This may be intentional for human-eyeballing but is subtle.
**Fix:** Add `r.id` to the SELECT and CSV output, or document that duplicate rows indicate distinct race records.

### IN-02: `audit-112-races.ts` declares `ElectionRow.id` as `number` but pg UUIDs are strings

**File:** `ev-accounts/backend/scripts/audit-112-races.ts:35-38`
**Issue:** `interface ElectionRow { id: number; ... }`. The `audit-112-assemble.ts` and `audit-112-candidates.ts` type it as `string`, and Supabase/PostgreSQL UUIDs are returned as strings by `pg`. This type declaration is wrong but harmless because the value is only interpolated into a log line. `race_candidates.politician_id` is typed as `number | null` in headshots/profile/quotes/stances — confirm with schema whether that column is `bigint` (string) or `integer` (number).
**Fix:** Align with schema. For UUID columns use `string`; for integer keys use `number`. Consider sharing a `types.ts` across these 8 scripts.

### IN-03: `audit-112-stances.ts` — LEFT JOIN with filter in JOIN clause is correct but fragile

**File:** `ev-accounts/backend/scripts/audit-112-stances.ts:73-74`
**Issue:** `LEFT JOIN inform.politician_answers pa ON pa.politician_id = rc.politician_id` followed by `LEFT JOIN inform.compass_topics ct ON ct.id = pa.topic_id AND ct.is_live = true` is the right pattern to filter inactive topics without dropping candidates. However, `COUNT(DISTINCT pa.topic_id)` counts **all** topic_ids regardless of `ct.is_live`, so the count can exceed the "live topic count" denominator when a politician has answers for archived topics. The join restricts which rows are emitted but `COUNT(DISTINCT pa.topic_id)` uses `pa.topic_id` not `ct.id`.
**Fix:** Count `COUNT(DISTINCT ct.id)` instead of `COUNT(DISTINCT pa.topic_id)` so that only live topics contribute to `answered_topic_count`.

### IN-04: `audit-112-profile.ts` — COUNT(DISTINCT …) on three joined tables is correct but O(n*m*k)

**File:** `ev-accounts/backend/scripts/audit-112-profile.ts:83-98`
**Issue:** Three LEFT JOINs (`politician_contacts`, `degrees`, `experiences`) with `COUNT(DISTINCT pc.id) / COUNT(DISTINCT d.id) / COUNT(DISTINCT ex.id)` works correctly but generates a Cartesian product per politician. For the Monroe audit scope (< 200 candidates) this is fine; flagged only as a note for future reuse against larger datasets.
**Fix:** No action required at this scale. If reused against >10k politicians, rewrite as three subquery-based counts or CTEs.

### IN-05: `audit-112-assemble.ts` — `execSync` buffer limit not set

**File:** `ev-accounts/backend/scripts/audit-112-assemble.ts:319-327`
**Issue:** `execSync` defaults to a 1 MB stdout buffer. For Monroe audit (< 200 candidates) this is safe, but a larger election dataset would silently throw `ENOBUFS`. Also, per-script wall time for 8 sequential `execSync` calls means the outer script re-opens a `pg.Pool` 8 times — minor efficiency note, not correctness.
**Fix:** Set `maxBuffer: 10 * 1024 * 1024` on the execSync call. Pool re-opening is acceptable for this audit-only workflow.

### IN-06: Pool is not always awaited on error paths

**File:** All 7 audit scripts (e.g., `audit-112-races.ts:142-146`)
**Issue:** The outer `.catch()` calls `pool.end()` without awaiting it before `process.exit(1)`. `pg.Pool.end()` returns a promise; on `process.exit` the connection close may not flush cleanly. Not a functional bug (the process dies anyway) but generates async warnings in Node 20.
**Fix:**
```ts
main().catch(async (err) => {
  console.error('Fatal error:', err);
  await pool.end().catch(() => {});
  process.exit(1);
});
```

### IN-07: `audit-112-geofence.ts` — hard-coded test addresses will silently become stale

**File:** `ev-accounts/backend/scripts/audit-112-geofence.ts:74-123`
**Issue:** Six Monroe County addresses with pre-geocoded lat/lng are embedded as constants. This is justified (noted in the header — avoids external API calls), but if TIGER 2025 geofences shift slightly or if one of these street addresses is redrawn into a different district, the expected township/district will become incorrect and the smoke test will report false-positive mismatches. The `expectedTownship` and `expectedStateDistrict` fields are declared but never compared against query output — they are documentation-only.
**Fix:** Either compare `expectedStateDistrict` to resolved races and emit a mismatch column, or add a comment explaining the fields are advisory. Consider extracting addresses to a JSON fixture so coordinate refreshes don't require code changes.

---

_Reviewed: 2026-04-12_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
