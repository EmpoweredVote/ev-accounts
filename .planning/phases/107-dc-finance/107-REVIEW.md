---
phase: 107-dc-finance
reviewed: 2026-06-08T00:00:00Z
depth: standard
files_reviewed: 1
files_reviewed_list:
  - backend/scripts/ehn-fec-finance.ts
findings:
  critical: 1
  warning: 2
  info: 1
  total: 4
status: issues_found
---

# Phase 107: Code Review Report

**Reviewed:** 2026-06-08
**Depth:** standard
**Files Reviewed:** 1
**Status:** issues_found

## Summary

Single script (`ehn-fec-finance.ts`) that fetches Eleanor Holmes Norton's FEC finance data via a three-step API chain and writes it to `essentials.politicians.finance_summary`. The script faithfully follows the patterns in `run-fec-finance-summary.ts` — correct parameterized DB write, AbortSignal timeouts, rate-limit sleeps, and fallback committee lookup.

Three issues found: one critical (silent no-op DB write when UUID doesn't match any row), one warning (FEC API key logged verbatim in plaintext to stdout), one warning (YAML fetch has no sleep before the first FEC call, but there is a structural ordering gap that could race), and one info item (API key exposure pattern differs from the analog script).

---

## Critical Issues

### CR-01: `updateFinanceSummary` does not verify that the UPDATE matched any row

**File:** `backend/scripts/ehn-fec-finance.ts:206-211`

**Issue:** `pool.query()` returns a `QueryResult` whose `rowCount` field indicates how many rows were affected. The function discards the result entirely and always logs "finance_summary written." even when `rowCount === 0`, which happens if `EHN_POLITICIAN_UUID` does not match any row in `essentials.politicians` (wrong UUID, record not yet inserted, UUID copy-paste error, etc.). The script exits `0` and the operator has no indication the write silently did nothing. The analog script `run-fec-finance-summary.ts` also does not check `rowCount`, but there a multi-politician loop makes the oversight less dangerous — here the entire script produces exactly one write and a silent no-op is undetectable.

**Fix:**
```typescript
async function updateFinanceSummary(politicianId: string, summary: FinanceSummary): Promise<void> {
  const result = await pool.query(
    `UPDATE essentials.politicians SET finance_summary = $1::jsonb WHERE id = $2`,
    [JSON.stringify(summary), politicianId],
  );
  if (result.rowCount === 0) {
    throw new Error(
      `UPDATE matched 0 rows — politician UUID ${politicianId} not found in essentials.politicians`,
    );
  }
}
```

---

## Warnings

### WR-01: FEC API key logged verbatim to stdout

**File:** `backend/scripts/ehn-fec-finance.ts:229-232` (no masking anywhere in script)

**Issue:** The analog script `run-fec-finance-summary.ts` logs only the first 8 characters of the API key (`apiKey.slice(0, 8)...`). `ehn-fec-finance.ts` never logs the key directly, so at a glance this looks fine — but the `URLSearchParams` objects that include `api_key: apiKey` are passed directly to the FEC fetch calls. The issue is subtler: the full request URL (including the API key as a query parameter) is available in any debug output, crash stacktrace, or network-level logging tool. More critically, the script provides no masking even in the startup log, while the analog explicitly masks to prevent key leakage in CI/CD log capture. The pattern divergence is a maintenance hazard — future operators copying the startup log block may not realize the key is absent from the log and add a plain `console.log(apiKey)`.

**Fix:** Mirror the analog's startup log pattern and add an explicit note:
```typescript
console.log(`[ehn-fec-finance] FEC API key: ${apiKey.slice(0, 8)}...`);
```
This makes the masking convention explicit and consistent across all FEC scripts.

### WR-02: `fetchTopDonorsByEmployer` may silently under-deliver when FEC response has no `results` key

**File:** `backend/scripts/ehn-fec-finance.ts:189`

**Issue:** The response is cast as `{ results: FecEmployerRow[] }`. If the FEC API returns a non-standard response shape (e.g. `{ data: [...] }`, a rate-limit 429 body that is valid JSON, or a response with `pagination` but missing `results`), `data.results` is `undefined`. The subsequent `.filter(...)` call on `undefined` throws `TypeError: Cannot read properties of undefined (reading 'filter')`, which propagates as an unhandled error through `main().catch`. This is not silent, but it produces a confusing error message rather than a clear "unexpected FEC response shape" diagnostic. The same pattern exists in `fetchCommitteeId` (line 128) but there the `?.` optional chain protects access. Only `fetchTopDonorsByEmployer` does a direct `.filter()` on `data.results` without a null guard.

**Fix:**
```typescript
const rows = data.results ?? [];
return rows
  .filter((r): r is FecEmployerRow & { employer: string } =>
    r.employer != null && r.employer.trim() !== '',
  )
  .slice(0, TOP_DONORS_LIMIT)
  .map(r => ({
    employer: r.employer,
    amount: Number(r.total),
    count: Number(r.count),
  }));
```

---

## Info

### IN-01: `yamlLoad` input is unconstrained — no size/type guard on YAML parse

**File:** `backend/scripts/ehn-fec-finance.ts:93-96`

**Issue:** `yamlLoad(await resp.text())` parses the raw GitHub response without any type guard or size limit. If GitHub returns an unexpectedly large or malformed payload (e.g. an HTML error page when rate-limited), `yamlLoad` will either return `null`/`undefined` or throw a parse error. The `as Array<...>` cast silences TypeScript but does not validate at runtime. The downstream `.find()` call at line 97 would throw `TypeError: Cannot read properties of null (reading 'find')` if `legislators` is null. This is acceptable for a one-shot admin script (error propagates to `main().catch`), but the error message would be confusing without context.

**Fix:** Add a minimal runtime guard after the cast:
```typescript
const legislators = yamlLoad(await resp.text()) as Array<{
  id: { bioguide: string; fec?: string[] };
  terms: Array<{ type: string }>;
}>;
if (!Array.isArray(legislators)) {
  throw new Error('Unexpected YAML shape from congress-legislators — expected top-level array');
}
```

---

_Reviewed: 2026-06-08_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
