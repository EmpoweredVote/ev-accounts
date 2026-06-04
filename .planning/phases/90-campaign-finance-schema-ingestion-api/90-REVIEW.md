---
phase: 90-campaign-finance-schema-ingestion-api
reviewed: 2026-06-04T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - backend/migrations/268_finance_summary_column.sql
  - backend/scripts/run-fec-finance-summary.ts
  - backend/src/lib/essentialsBrowseService.ts
  - backend/src/lib/essentialsService.ts
  - backend/test/essentialsService-finance-summary.test.ts
findings:
  critical: 2
  warning: 3
  info: 2
  total: 7
status: issues_found
---

# Phase 90: Code Review Report

**Reviewed:** 2026-06-04T00:00:00Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Phase 90 adds a `finance_summary` JSONB column to `essentials.politicians`, a FEC ingestion script to populate it, and surface-level changes to `essentialsService.ts` and `essentialsBrowseService.ts` to read it. The migration and the ingestion script are well-structured. The primary problem is a pervasive, systematic omission: `p.finance_summary` is missing from the SQL SELECT lists in **four of the seven** query paths that return `PoliticianFlatRecord` objects. The mapper code for those paths correctly assigns `row.finance_summary ?? null`, so when the column is absent from the SELECT the result silently evaluates from `undefined` to `null` — FINA-03 compliance is intact for `getPoliticiansFlatList` and `getPoliticianById`, but every other query path will always return `finance_summary: null` for federal politicians even after ingestion.

The test file only exercises `getPoliticiansFlatList` and `getPoliticianById` and therefore does not catch the missing SELECTs in the other paths.

---

## Critical Issues

### CR-01: `finance_summary` missing from SELECT in `getRepresentativesByAddress` (both district and statewide queries)

**File:** `backend/src/lib/essentialsService.ts:588-696`
**Issue:** `getRepresentativesByAddress` returns `PoliticianFlatRecord[]`. Its row mapper at line 782 includes `finance_summary: row.finance_summary ?? null`. However, neither `districtQueryText` (lines 588–649) nor `statewideQueryText` (lines 652–696) SELECT `p.finance_summary`. The column value will always be `undefined` → coerced to `null` by the `?? null` fallback. Federal senators and House members found via address lookup will never have finance data surfaced, even after ingestion.

**Fix:** Add `p.finance_summary,` to both SELECT column lists in this function, immediately after `p.is_incumbent`:
```sql
-- In districtQueryText (after line 594: p.urls, p.email_addresses, p.bio_text, p.slug, p.is_incumbent,)
p.finance_summary,

-- In statewideQueryText (after line 658: p.urls, p.email_addresses, p.bio_text, p.slug, p.is_incumbent,)
p.finance_summary,
```

---

### CR-02: `finance_summary` missing from SELECT in `getRepresentativesByJurisdiction` and `getLocalOfficialsByUserId` (shared `SELECT_FIELDS` constant)

**File:** `backend/src/lib/essentialsService.ts:1506-1528` and `1676-1698`
**Issue:** Both `getRepresentativesByJurisdiction` and `getLocalOfficialsByUserId` define a `SELECT_FIELDS` local constant that enumerates every politician column — but both omit `p.finance_summary`. Their row mappers (lines 1642 and 1773) reference `row.finance_summary`, so the value is silently `null` instead of coming from the DB. Connected users hitting `GET /api/essentials/representatives/me` will never see finance data for their senators or representatives.

**Fix:** Add `p.finance_summary,` to the `SELECT_FIELDS` string in both functions, after `p.is_incumbent`:
```sql
-- essentialsService.ts line ~1511 (getRepresentativesByJurisdiction SELECT_FIELDS):
p.web_form_url, p.urls, p.email_addresses, p.bio_text, p.slug, p.is_incumbent,
p.finance_summary,   -- ADD THIS LINE

-- essentialsService.ts line ~1681 (getLocalOfficialsByUserId SELECT_FIELDS):
p.web_form_url, p.urls, p.email_addresses, p.bio_text, p.slug, p.is_incumbent,
p.finance_summary,   -- ADD THIS LINE
```

---

## Warnings

### WR-01: `getPoliticiansByArea` and `getPoliticiansByGovernmentList` in `essentialsBrowseService.ts` always return `finance_summary: null` — hardcoded, not read from DB

**File:** `backend/src/lib/essentialsBrowseService.ts:310` and `616`
**Issue:** Both browse-by-area functions set `finance_summary: null` unconditionally in their row mappers. Unlike the `essentialsService.ts` paths this is a deliberate hardcode rather than a missing SELECT — but the effect is the same: federal senators and House members returned through the browse endpoints will never surface finance data. If the intent is that browse paths don't surface finance data, that must be explicitly documented; if finance data should be surfaced uniformly across all politician responses, these paths need the same fix as CR-01/CR-02.

**Fix:** Either (a) add `p.finance_summary` to each SELECT in `essentialsBrowseService.ts` and change the hardcoded `null` to `row.finance_summary ?? null`, or (b) add a code comment at lines 310 and 616 explicitly documenting "finance_summary intentionally omitted from browse endpoints" to prevent future confusion.

---

### WR-02: Ingestion script uses `process.exit(1)` after `void pool.end()` in the fatal-error handler — pool may not be fully drained before exit

**File:** `backend/scripts/run-fec-finance-summary.ts:457-461`
**Issue:** The `main().catch()` handler calls `void pool.end()` (fire-and-forget) then immediately `process.exit(1)`. The `pg` pool's `end()` is async; calling it without `await` and then exiting means in-flight queries may be aborted mid-write, and `pool.end()` itself may not complete. Any partial `updateFinanceSummary` write in progress at error time could leave the DB in a partially updated state without the error ever being surfaced to the operator.

```typescript
// Current (line 457–461):
main().catch(err => {
  console.error('[run-fec-finance-summary] Fatal error:', err);
  void pool.end();
  process.exit(1);
});

// Fix: await pool.end() before exit
main().catch(async (err) => {
  console.error('[run-fec-finance-summary] Fatal error:', err);
  try { await pool.end(); } catch { /* ignore pool close errors on fatal path */ }
  process.exit(1);
});
```

---

### WR-03: Test suite regex for `PoliticianFlatRecord` interface will false-positive match body content of an *earlier* interface if it has no newline before `export`

**File:** `backend/test/essentialsService-finance-summary.test.ts:23`
**Issue:** The regex `/export interface PoliticianFlatRecord\s*\{([\s\S]*?)(?=\nexport |\nfunction |\nconst |\nclass )/` uses a lookahead for `\nexport ` (with a leading newline and trailing space). In the actual source, `export interface FinanceSummary` immediately precedes `PoliticianFlatRecord` and `export interface AddressSearchResult` immediately follows it. The lookahead `\nexport ` should reliably terminate the match at `AddressSearchResult`. However, the regex does **not** anchor to the end of the interface block with a closing `}` — if a future interface is inserted without a blank line before `export`, the lookahead pattern `\nexport ` fails and the capture bleeds into the next interface body, causing the test to remain green even if `finance_summary` is removed from `PoliticianFlatRecord` but present elsewhere in the bleed region. This is a low-probability but real fragility.

**Fix:** Tighten the termination pattern to also accept `\n}` (close-brace on its own line) as an end anchor:
```typescript
const match = /export interface PoliticianFlatRecord\s*\{([\s\S]*?)(?=\n\}|\nexport |\nfunction |\nconst |\nclass )/.exec(SRC_NC);
```

---

## Info

### IN-01: `run-fec-finance-summary.ts` logs full partial API key to stdout

**File:** `backend/scripts/run-fec-finance-summary.ts:347`
**Issue:** `console.log(\`[run-fec-finance-summary] FEC API key: ${apiKey.slice(0, 8)}...\`)` logs the first 8 characters of the API key. For a 40-character key this leaks 20% of the key entropy into any log aggregator. The intent is clearly a sanity check that the env var is set, not to expose key material.

**Fix:**
```typescript
// Log only key length confirmation, not any key characters:
console.log(`[run-fec-finance-summary] FEC API key: set (${apiKey.length} chars)`);
```

---

### IN-02: `essentialsService-finance-summary.test.ts` does not test that `finance_summary` is absent from `getPoliticiansGrouped` (which correctly omits it)

**File:** `backend/test/essentialsService-finance-summary.test.ts`
**Issue:** `getPoliticiansGrouped` returns `PoliticianRecord[]` (not `PoliticianFlatRecord[]`) and deliberately omits `finance_summary` — it queries a minimal column set. There is no test asserting that `getPoliticiansGrouped` does NOT select `p.finance_summary`, which means a future accidental addition of finance data to that path would go undetected. This is informational only since the current code is correct.

**Fix:** Consider adding a negative assertion test:
```typescript
it('getPoliticiansGrouped does NOT reference finance_summary', () => {
  const fnMatch = /export async function getPoliticiansGrouped[\s\S]*?const queryText\s*=\s*`([\s\S]*?)`/.exec(SRC_NC);
  expect(fnMatch).toBeTruthy();
  expect(fnMatch![1]).not.toMatch(/finance_summary/);
});
```

---

_Reviewed: 2026-06-04T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
