---
phase: 109-la-county-finance
reviewed: 2026-06-08T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - backend/scripts/seed-la-city-confirmed.ts
  - backend/scripts/seed-la-county-city-netfile.ts
  - backend/scripts/verify-la-county-109.sql
  - backend/scripts/write-la-city-finance-summary.ts
  - backend/scripts/write-la-county-city-finance-summary.ts
findings:
  critical: 2
  warning: 3
  info: 1
  total: 6
status: issues_found
---

# Phase 109: Code Review Report

**Reviewed:** 2026-06-08
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Five scripts covering LA County finance data ingestion for Phase 109 (LAFI-01 and LAFI-02). Two critical bugs found:

1. `write-la-county-city-finance-summary.ts` uses the wrong join path to aggregate Netfile contributions — it routes through `committees` but the Netfile adapter writes `committee_id = null` on every contribution row. The aggregation will always return zero, silently producing no `finance_summary` rows for any Netfile official.

2. `verify-la-county-109.sql` assertion 8's city name list uses bare short-form names (e.g., `'City of Long Beach'`), which do not match the `essentials.governments.name` values used in the seed script for 16 of the 26 cities (those stored with `, California, US` suffix). The verification query will return zero rows for those cities, making LAFI-02 coverage appear empty when data was actually seeded.

---

## Critical Issues

### CR-01: `write-la-county-city-finance-summary.ts` — Aggregation joins through `committees` but Netfile stores `committee_id = null`

**File:** `backend/scripts/write-la-county-city-finance-summary.ts:85-89`

**Issue:** `buildFinanceSummaryFromNetfile` aggregates contributions via:
```sql
JOIN transparent_motivations.committees cm ON cm.id = c.committee_id
JOIN transparent_motivations.politician_sources ps ON ps.id = cm.politician_source_id
```
The Netfile adapter (`netfileAdapter.ts:302`) explicitly sets `committee_id: null` on every contribution row and writes `politician_source_id` directly on `contributions`. The two-hop join `contributions → committees → politician_sources` will match zero rows because `c.committee_id IS NULL` for all Netfile data. The function will always return `null`, leaving every official's `finance_summary` as `NULL`, with no error or warning emitted. This silently nullifies all of LAFI-02.

The correct pattern is already present in `write-la-city-finance-summary.ts` (which handles Socrata the same way), confirmed in the comment at line 18 of that file: *"join on `politician_source_id`, NOT via the committees table."*

**Fix:**
```typescript
// Replace the committees-based join in buildFinanceSummaryFromNetfile:
const result = await pool.query<{
  total_raised: string;
  total_spent: string;
  contribution_count: string;
}>(
  `SELECT
     COALESCE(SUM(CASE WHEN c.amount > 0 THEN c.amount ELSE 0 END), 0) AS total_raised,
     COALESCE(ABS(SUM(CASE WHEN c.amount < 0 THEN c.amount ELSE 0 END)), 0) AS total_spent,
     COUNT(*) FILTER (WHERE c.amount > 0) AS contribution_count
   FROM transparent_motivations.contributions c
   JOIN transparent_motivations.politician_sources ps ON ps.id = c.politician_source_id
   WHERE ps.essentials_politician_id = $1
     AND ps.source_system = 'la_county_netfile'
     AND ps.research_status = 'confirmed'`,
  [politicianId]
);
```

---

### CR-02: `verify-la-county-109.sql` — Assertion 8 city name list mismatches `essentials.governments.name` for 16 of 26 cities

**File:** `backend/scripts/verify-la-county-109.sql:165-193`

**Issue:** The `g.name IN (...)` predicate in Assertion 8 uses short-form names (e.g., `'City of Long Beach'`), but 16 of the 26 non-LA-City municipalities in `seed-la-county-city-netfile.ts` are recorded in `essentials.governments` with a `, California, US` suffix (e.g., `'City of Long Beach, California, US'`). The mismatch was explicitly documented in the seeder's `CITIES` array comment: *"Cities with ', California, US' suffix in essentials.governments.name"*.

At query time, those 16 cities will return no rows in Assertion 8 — they will appear as missing data, making the Phase 109 coverage gate misleadingly report gaps where Netfile data was actually seeded. This also means the phase gate could be satisfied by a reviewer who mistakes the empty rows for expected no-data gaps.

**Fix:** Align the city name list in Assertion 8 with the actual values in `essentials.governments.name`. The 16 affected cities need the `, California, US` suffix:

```sql
g.name IN (
    'City of Los Angeles',
    'City of Long Beach, California, US',
    'City of Glendale, California, US',
    'City of Burbank, California, US',
    'City of Downey, California, US',
    'City of El Monte, California, US',
    'City of Inglewood, California, US',
    'City of Lancaster, California, US',
    'City of Norwalk, California, US',
    'City of Palmdale, California, US',
    'City of Pasadena, California, US',
    'City of Pomona, California, US',
    'City of Santa Clarita, California, US',
    'City of Torrance, California, US',
    'City of West Covina, California, US',
    'City of Beverly Hills, California, US',
    'City of Santa Monica, California, US',
    'City of South Gate',
    'City of Compton',
    'City of Carson',
    'City of Hawthorne',
    'City of Whittier',
    'City of Alhambra',
    'City of Gardena',
    'City of Culver City',
    'City of West Hollywood',
    'City of El Segundo'
)
```

---

## Warnings

### WR-01: `verify-la-county-109.sql` assertions 2 and 5 overcount politicians with multiple confirmed sources

**File:** `backend/scripts/verify-la-county-109.sql:44-52` and `94-101`

**Issue:** Assertions 2 and 5 join `essentials.politicians` to `transparent_motivations.politician_sources` without `DISTINCT`. Adrin Nazarian has 2 confirmed `la_socrata` cmt_ids (`1453755` and `1468093`). The JOIN produces 2 rows for him, so `COUNT(*) AS officials_with_confirmed_source` reports 19 instead of 18. The `officials_null_summary` threshold check (`<= 3`) could pass even with one more null than expected. The same issue applies to any other politician with multiple confirmed source rows.

**Fix:**
```sql
-- Assertion 2:
SELECT
  COUNT(DISTINCT p.id) AS officials_with_confirmed_source,
  COUNT(DISTINCT p.id) FILTER (WHERE p.finance_summary IS NOT NULL) AS officials_with_summary,
  COUNT(DISTINCT p.id) - COUNT(DISTINCT p.id) FILTER (WHERE p.finance_summary IS NOT NULL) AS officials_null_summary
FROM essentials.politicians p
JOIN transparent_motivations.politician_sources ps
  ON ps.essentials_politician_id = p.id
WHERE ps.source_system = 'la_socrata'
  AND ps.research_status = 'confirmed';

-- Same pattern for Assertion 5 (la_county_netfile).
```

---

### WR-02: `seed-la-county-city-netfile.ts` — `resolveFilerId` third-try fallback uses OR-logic (`some`) on a single-word query, producing false-positive matches

**File:** `backend/scripts/seed-la-county-city-netfile.ts:192-198`

**Issue:** The third-try fallback filters `queryWords` to words longer than 3 characters, then returns the first committee where `queryWords.some(w => nameLower.includes(w))`. When the search query is a full name like `"Maria Garcia"`, `queryWords` becomes `["maria", "garcia"]`. The `some()` (OR) check returns the first committee containing either "maria" OR "garcia" — which could match completely unrelated committees (e.g., "Garcia for Glendale City Council 2014" when seeding an official in Long Beach). The first two tries use stricter matching; the third try is a reliability regression. If a false positive is returned, the wrong `filerId` gets seeded into `politician_sources`, causing the Netfile adapter to ingest another person's contributions under the target official.

**Fix:** Either remove the third try entirely (return `null` and log clearly), or change `some` to `every`:
```typescript
// Third try: require ALL query words to appear (consistent with second-try AND logic)
match = committees.find((c) => {
  const nameLower = c.name.toLowerCase();
  return queryWords.every((w) => nameLower.includes(w));
});
```

---

### WR-03: `seed-la-city-confirmed.ts` — `db.ts` pool opened by `runAdapterForAll` is never closed

**File:** `backend/scripts/seed-la-city-confirmed.ts:611-631`

**Issue:** `runAdapterForAll('la_socrata')` is imported from `campaignFinanceScheduler.ts`, which imports `pool` from `src/lib/db.ts`. That pool is a separate instance from the script-local `pool` defined at line 44. Only the script-local pool is closed in both the success and error exit paths (lines 625, 630). The `db.ts` pool is left open. Since the script calls `process.exit(0)` immediately after, the Node process terminates anyway — but the idle connections are abruptly torn down rather than cleanly returned to the pool, which can produce `ECONNRESET` errors in Supabase connection logs.

**Fix:**
```typescript
import { pool as dbPool } from '../src/lib/db.js';

main()
  .then(async () => {
    await pool.end();
    await dbPool.end();
    process.exit(0);
  })
  .catch(async err => {
    console.error('[seed-la-city-confirmed] Fatal error:', err);
    await pool.end();
    await dbPool.end();
    process.exit(1);
  });
```

---

## Info

### IN-01: `write-la-county-city-finance-summary.ts` — Errors not tracked with detail, only counted

**File:** `backend/scripts/write-la-county-city-finance-summary.ts:163-167`

**Issue:** Unlike `write-la-city-finance-summary.ts` (which builds an `errorDetails` array and prints each failed politician name + error message), the county version only increments `errors` and prints to stderr inline. After a run with errors, there is no end-of-run summary listing which politicians failed. This makes post-run triage harder.

**Fix:** Mirror the `errorDetails` pattern from `write-la-city-finance-summary.ts`:
```typescript
const errorDetails: Array<{ name: string; error: string }> = [];
// ...in catch block:
errorDetails.push({ name: p.full_name, error: errMsg });
// ...in summary section:
if (errorDetails.length > 0) {
  console.log('\n  Errored politicians:');
  for (const e of errorDetails) console.log(`    - ${e.name}: ${e.error}`);
}
```

---

_Reviewed: 2026-06-08_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
