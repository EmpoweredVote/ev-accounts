---
phase: 90-campaign-finance-schema-ingestion-api
reviewed: 2026-06-04T18:41:41Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - backend/migrations/268_finance_summary_column.sql
  - backend/test/essentialsService-finance-summary.test.ts
  - backend/scripts/run-fec-finance-summary.ts
  - backend/src/lib/essentialsService.ts
  - backend/src/lib/essentialsBrowseService.ts
findings:
  critical: 2
  warning: 4
  info: 3
  total: 9
status: issues_found
---

# Phase 90: Code Review Report

**Reviewed:** 2026-06-04T18:41:41Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Phase 90 adds a `finance_summary` JSONB column to `essentials.politicians`, an FEC ingestion script to populate it, and surfaces the field in `essentialsService.ts`. The migration and the ingestion script are well-structured. The primary problem is a pervasive, systematic omission: `p.finance_summary` is missing from the SQL SELECT lists in four of the seven query paths that return `PoliticianFlatRecord` objects. The mapper code for those paths correctly writes `row.finance_summary ?? null`, so when the column is absent from the SELECT, the result silently evaluates from `undefined` to `null` — FINA-03 compliance is intact for `getPoliticiansFlatList` and `getPoliticianById` only. Every other query path will always return `finance_summary: null` for federal politicians even after ingestion.

The test file only exercises `getPoliticiansFlatList` and `getPoliticianById` and therefore does not catch the missing SELECTs in the other paths. `essentialsBrowseService.ts` hard-codes `finance_summary: null` in two functions and does not select the column at all.

---

## Critical Issues

### CR-01: `finance_summary` missing from SELECT in `getRepresentativesByAddress` (both district and statewide sub-queries)

**File:** `backend/src/lib/essentialsService.ts:588-696`
**Issue:** `getRepresentativesByAddress` returns `PoliticianFlatRecord[]`. Its row mapper at line 782 includes `finance_summary: row.finance_summary ?? null`. However, neither `districtQueryText` (lines 588–649) nor `statewideQueryText` (lines 652–696) selects `p.finance_summary`. The column value will always be `undefined` → coerced to `null` by the `?? null` fallback. Federal senators and House members found via address lookup will never have finance data surfaced, even after ingestion completes. The same omission exists in `getRepresentativesByJurisdiction` (lines 1506–1528) and `getLocalOfficialsByUserId` (lines 1676–1698) — both define a `SELECT_FIELDS` local constant that omits `p.finance_summary`, while their row mappers at lines 1642 and 1773 reference `row.finance_summary`.

**Fix:** Add `p.finance_summary,` to every SELECT column list that feeds a `PoliticianFlatRecord` mapper. For `getRepresentativesByAddress`, add after `p.is_incumbent` in both `districtQueryText` and `statewideQueryText`. For `getRepresentativesByJurisdiction` and `getLocalOfficialsByUserId`, add to each function's `SELECT_FIELDS` constant after `p.is_incumbent`:

```sql
p.web_form_url, p.urls, p.email_addresses, p.bio_text, p.slug, p.is_incumbent,
p.finance_summary,    -- ADD THIS LINE
```

---

### CR-02: `essentialsBrowseService` hard-codes `finance_summary: null` in both browse functions

**File:** `backend/src/lib/essentialsBrowseService.ts:310` and `616`
**Issue:** Both `getPoliticiansByArea` (line 310) and `getPoliticiansByGovernmentList` (line 616) hard-code `finance_summary: null` unconditionally in their row mappers. Neither function selects `p.finance_summary` from the DB in any of their queries. Senators and House members returned by area-browse or government-list browse endpoints will always show `finance_summary: null` regardless of ingestion state. Unlike the `essentialsService.ts` paths (where the column is simply missing from SELECT), this is a deliberate hardcode — but the effect is identical. The `getPoliticiansByArea` function also uses inline image/committee fetch logic instead of delegating to `batchFetchImages`/`batchFetchCommittees`, so there is no secondary mechanism to backfill the data.

**Fix:** Add `p.finance_summary` to every SELECT clause in both functions (the main query, statewide query, congressional intersection query, and city-district query in `getPoliticiansByGovernmentList`). Change both hardcoded `null` values in the row mappers to:

```typescript
finance_summary: (row.finance_summary as FinanceSummary | null) ?? null,
```

If finance data is intentionally excluded from browse endpoints by product decision, add an explicit comment to that effect at lines 310 and 616 to prevent future confusion.

---

## Warnings

### WR-01: Deduplication key in `getRepresentativesByJurisdiction` collapses all vacant/null-ID offices to one key

**File:** `backend/src/lib/essentialsService.ts:1587-1590`
**Issue:** The deduplication logic uses `(row.id as string) ?? String(row.external_id)` as the seen-set key. When `row.id` is `null` (vacant office — the query uses `LEFT JOIN essentials.politicians p`) and `row.external_id` is also null, the key becomes the string `"null"`. All vacant offices with no `external_id` collapse to the same deduplication key. The second (and all subsequent) vacant offices with null ID and null external_id are silently dropped from the response.

**Fix:** Use a composite fallback that is unique per row:
```typescript
const key = (row.id as string | null) != null
  ? (row.id as string)
  : `vacant-${row.geo_id ?? ''}-${row.district_id ?? ''}`;
if (seen.has(key)) return false;
seen.add(key);
return true;
```

---

### WR-02: Fatal error handler in ingestion script uses fire-and-forget `pool.end()` before `process.exit`

**File:** `backend/scripts/run-fec-finance-summary.ts:457-461`
**Issue:** The `main().catch()` handler calls `void pool.end()` (fire-and-forget) and then immediately calls `process.exit(1)`. The `pg` pool's `end()` is async; without `await`, any in-flight `updateFinanceSummary` write may be aborted mid-commit. If a write was partially applied before the fatal error, `process.exit(1)` terminates the process before `pool.end()` drains the pool or logs the error. In practice a script-level fatal crash is rare, but the pattern is unsafe.

**Fix:**
```typescript
main().catch(async (err) => {
  console.error('[run-fec-finance-summary] Fatal error:', err);
  try { await pool.end(); } catch { /* ignore pool close errors on fatal path */ }
  process.exit(1);
});
```

---

### WR-03: `vacant_since` type mismatch in `getPoliticiansByGovernmentList` violates the `PoliticianFlatRecord` contract

**File:** `backend/src/lib/essentialsBrowseService.ts:615`
**Issue:** `getPoliticiansByGovernmentList` maps `vacant_since` as:
```typescript
vacant_since: row.vacant_since as string ?? '',
```
The `PoliticianFlatRecord` interface declares `vacant_since: string | null`. The `?? ''` fallback converts a DB `NULL` to an empty string `''` instead of `null`. Callers that check `if (politician.vacant_since !== null)` to detect vacancies will incorrectly evaluate this as truthy for politicians with no `vacant_since` date. All other mappers in `essentialsService.ts` consistently use `vacant_since: row.vacant_since ?? null` (lines 530, 778, 1638, 1769). This is the only outlier.

**Fix:**
```typescript
vacant_since: (row.vacant_since as string | null) ?? null,
```

---

### WR-04: Test regex for `PoliticianFlatRecord` can bleed into adjacent interface body on formatting change

**File:** `backend/test/essentialsService-finance-summary.test.ts:23`
**Issue:** The regex at line 23 uses the lookahead `(?=\nexport |\nfunction |\nconst |\nclass )` to terminate the interface body capture. This works correctly today because `export interface AddressSearchResult` follows with a blank line containing `\nexport `. However, if a future refactor collapses the blank line or inserts a non-export/non-function line (e.g., a comment block) between the two interfaces, the lookahead fails to terminate and the regex captures content from the next interface body. A `finance_summary` field in `AddressSearchResult` or any later interface would cause the test to pass even if `PoliticianFlatRecord` no longer declares it. The tests for `getPoliticiansFlatList` queryText (line 39) and `getPoliticianById` baseQuery (line 46) share similar fragility.

**Fix:** Tighten the interface body termination to also accept the close-brace on its own line:
```typescript
const match = /export interface PoliticianFlatRecord\s*\{([\s\S]*?)(?=\n\}|\nexport |\nfunction |\nconst |\nclass )/.exec(SRC_NC);
```

---

## Info

### IN-01: Ingestion script logs 8 characters of API key to stdout on every run

**File:** `backend/scripts/run-fec-finance-summary.ts:347`
**Issue:** Line 347 logs `FEC API key: ${apiKey.slice(0, 8)}...` to stdout. For a 40-character FEC API key this exposes 20% of the key's character entropy into any log aggregator or terminal scrollback. The FEC developer API key is low-sensitivity (rate-limited, public-rate access), but the pattern contradicts log hygiene standards.

**Fix:**
```typescript
console.log(`[run-fec-finance-summary] FEC API key: set (${apiKey.length} chars)`);
```

---

### IN-02: `skipped_no_fec_id` counter conflates two distinct skip reasons

**File:** `backend/scripts/run-fec-finance-summary.ts:379` and `389`
**Issue:** `skipped_no_fec_id` is incremented both when no FEC ID is found (line 379) and when a committee ID cannot be resolved for a known FEC ID (line 389, labeled "no committee"). These are distinct failure modes: one means the crosswalk has no match at all; the other means the FEC candidate record exists but has no registered principal committee. Post-run analysis cannot distinguish the two from the summary output.

**Fix:** Introduce a separate `skipped_no_committee` counter and log both in the final summary:
```typescript
let skipped_no_fec_id = 0;
let skipped_no_committee = 0;
// ... line 379: skipped_no_fec_id++
// ... line 389: skipped_no_committee++
// ... final summary: { ..., skipped_no_fec_id, skipped_no_committee, ... }
```

---

### IN-03: `getAreasForState` passes FIPS code as query parameter with no inline documentation of the storage format

**File:** `backend/src/lib/essentialsBrowseService.ts:84`
**Issue:** `getAreasForState` converts the state abbreviation to FIPS via `ABBREV_TO_FIPS` before passing the result as `$1` for `WHERE gb.state = $1`. This is correct if `geofence_boundaries.state` stores FIPS codes — but the assumption is undocumented. If `geofence_boundaries.state` stores abbreviations (as some other tables do), every area query returns an empty result set silently. There is no comment and no assertion to document the FIPS expectation.

**Fix:** Add an inline comment:
```sql
-- WHERE gb.state = $1  (state = FIPS code, e.g. '06' for CA — NOT state abbreviation)
```

---

_Reviewed: 2026-06-04T18:41:41Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
