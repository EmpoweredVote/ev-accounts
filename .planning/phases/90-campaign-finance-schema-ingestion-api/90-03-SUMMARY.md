---
phase: 90-campaign-finance-schema-ingestion-api
plan: "03"
subsystem: essentials-service
tags:
  - api-surface
  - essentials-service
  - backward-compatible
  - campaign-finance
  - fina-03
dependency_graph:
  requires:
    - essentials.politicians.finance_summary (JSONB column — Plan 01)
    - essentials.politicians.finance_summary populated (FEC ingestion — Plan 02)
  provides:
    - GET /api/essentials/politicians response includes finance_summary field
    - GET /api/essentials/politicians/:id response includes finance_summary field
    - FinanceSummary TypeScript interface (exported from essentialsService.ts)
  affects:
    - Any consumer of PoliticianFlatRecord or PoliticianDetail TypeScript types
tech_stack:
  added: []
  patterns:
    - Additive interface extension (required field, null for non-federal)
    - JSONB returned as parsed object by pg driver (Pitfall 6: object by default)
    - Rule 1 auto-fix: PoliticianFlatRecord interface propagated to all 5 mappers
key_files:
  created: []
  modified:
    - backend/src/lib/essentialsService.ts
    - backend/src/lib/essentialsBrowseService.ts
decisions:
  - "finance_summary is a required field (not optional ?) in both interfaces — null is the valid empty value for non-federal politicians"
  - "pg driver returns JSONB as parsed JS object by default (Pitfall 6 did not manifest — no JSON.parse wrapper needed)"
  - "Rule 1: essentialsBrowseService.ts also returns PoliticianFlatRecord[]; its two mappers needed finance_summary: null to satisfy the interface"
  - "finance_summary: null hardcoded in browse/jurisdiction/local-officials mappers — these endpoints serve non-federal politicians and the SELECT clauses do not include p.finance_summary"
metrics:
  duration: "~30 minutes"
  completed: "2026-06-04"
  tasks_completed: 2
  files_created: 0
  files_modified: 2
---

# Phase 90 Plan 03: API Surface — finance_summary on essentials/politicians endpoints

**One-liner:** Extended `essentialsService.ts` with `FinanceSummary` interface + 7 targeted edits (2 interface declarations, 2 SELECT additions, 2 mapper projections, 1 new type) to surface the pre-computed FEC JSONB column on both `/api/essentials/politicians` endpoints; all 5 Wave-0 vitest tests flipped RED to GREEN.

---

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Extend essentialsService to surface finance_summary (7 hunks + Rule 1 fix) | 0dd4086 | backend/src/lib/essentialsService.ts, backend/src/lib/essentialsBrowseService.ts |
| 2 | Live API smoke test + pg JSONB shape verification | (no code change — runtime verification) | — |

---

## Task 1: Edit Hunks Applied to essentialsService.ts

**Hunk 1 — FinanceSummary interface (new, exported, inserted before PoliticianFlatRecord):**
```typescript
export interface FinanceSummary {
  total_raised: number;
  top_donors: Array<{ employer: string; amount: number; count: number }>;
  cycle: string;
  source: 'FEC';
}
```

**Hunk 2 — PoliticianFlatRecord interface:**
Added `finance_summary: FinanceSummary | null;` after existing `images:` field (last field in interface).

**Hunk 3 — PoliticianDetail interface:**
Added `finance_summary: FinanceSummary | null;` after `next_general_date:` field (last field in interface).

**Hunk 4 — getPoliticiansFlatList SELECT clause:**
Added `p.finance_summary,` on a new line after `p.urls, p.email_addresses, p.bio_text, p.slug, p.is_incumbent,`.

**Hunk 5 — getPoliticianById baseQuery SELECT clause:**
Added `p.finance_summary` inline with `p.notes,` (`p.is_active, p.office_id, p.notes, p.finance_summary,`).

**Hunk 6 — getPoliticiansFlatList row mapper:**
Added `finance_summary: row.finance_summary ?? null,` after `images: [],`.

**Hunk 7 — getPoliticianById return object:**
Added `finance_summary: row.finance_summary ?? null,` after `next_general_date: row.next_general_date ?? '',`.

---

## Task 1: Vitest Output — 5 passed | 0 failed (Wave-0 GREEN)

```
 RUN  v2.1.9

 ✓ test/essentialsService-finance-summary.test.ts (5 tests) 4ms

 Test Files  1 passed (1)
       Tests  5 passed (5)
   Start at  11:08:01
   Duration  489ms (transform 28ms, setup 0ms, collect 31ms, tests 4ms, environment 0ms, prepare 173ms)
```

All 5 Wave-0 source-scan tests: RED -> GREEN.

---

## Task 1: TypeScript Check

`npx tsc --noEmit` reports zero errors related to `essentialsService.ts` or `finance_summary`.

Pre-existing unrelated errors (not introduced by this plan):
- `src/lib/coverageService.ts(21,18): error TS7016` — js-yaml missing type declarations (pre-existing)
- `src/lib/stanceResearchCsv.ts(12,27): error TS2307` — csv-stringify type declarations (pre-existing)

---

## Task 2: Smoke Test Outputs (verbatim)

**Smoke test 1 (LIST OK):**
```
LIST OK: 191 politicians have finance_summary; sample keys: cycle,source,top_donors,total_raised
```

**Smoke test 2 (DETAIL OK — Jon Ossoff, id=6160a29a-d896-4061-801a-e5c3d9f06c99):**
```
DETAIL OK: total_raised=$81146109.47, 10 donors, cycle=2026, source=FEC
```

**Smoke test 3 (NULL OK — William Ellis, LOCAL district):**
```
NULL OK for non-federal (William Ellis, LOCAL)
```

---

## Task 2: Pitfall 6 Outcome

**JSONB returned as parsed JS object by default.** The pg driver for this project returns JSONB columns as parsed JavaScript objects, not strings. `typeof finance_summary === 'object'` for all populated rows. No `JSON.parse()` wrapper was needed in the row mappers.

---

## Backward Compatibility Confirmation

- No existing field in `PoliticianFlatRecord` was removed or had its type changed.
- No existing field in `PoliticianDetail` was removed or had its type changed.
- The only diff to both interfaces is the addition of `finance_summary: FinanceSummary | null;` at the end.
- All 191 politicians with `finance_summary` data return the field as an object; all non-federal politicians return `null`.
- Smoke test 3 confirms non-federal politician returns `finance_summary: null`, not a missing field.

---

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Three other PoliticianFlatRecord mappers in essentialsService.ts missing finance_summary**
- **Found during:** Task 1 TypeScript check
- **Issue:** `getRepresentativesByAddress`, `getRepresentativesByJurisdiction`, and `getLocalOfficialsByUserId` all return `PoliticianFlatRecord[]` but their row mappers did not include the new required `finance_summary` field. TypeScript reported 3 errors in `essentialsService.ts`.
- **Fix:** Added `finance_summary: row.finance_summary ?? null` to each of those three mappers. These functions serve address-lookup and geo-based queries; the JSONB column is not in their SELECT clauses, so `row.finance_summary` is `undefined` and the `?? null` coercion is correct.
- **Files modified:** `backend/src/lib/essentialsService.ts`
- **Commit:** `0dd4086` (same commit as Task 1)

**2. [Rule 1 - Bug] essentialsBrowseService.ts two mappers missing finance_summary**
- **Found during:** Task 1 TypeScript check
- **Issue:** `essentialsBrowseService.ts` exports two functions (`getPoliticiansByGeography`, `getPoliticiansByGovernmentId`) that return `PoliticianFlatRecord[]`. Both mappers did not include `finance_summary`. TypeScript reported 2 errors.
- **Fix:** Added `finance_summary: null` (literal null, not `row.finance_summary`) to both mappers. These functions serve browse/filter queries for state and local officials — none of them are federal politicians, so `null` is the correct and permanent value.
- **Files modified:** `backend/src/lib/essentialsBrowseService.ts`
- **Commit:** `0dd4086` (same commit as Task 1)

---

## Threat Surface Scan

No new network endpoints introduced. No auth paths modified. The `finance_summary` field is read from the pre-computed JSONB column — no new joins to `transparent_motivations.contributions` (verified: `grep` returns 0 occurrences).

T-90-09 (Pitfall 6): JSONB returned as object by default — no wrapping needed. Verified in smoke tests.
T-90-10 (backward compat): Smoke test 3 confirms non-federal returns `finance_summary: null`. No shape regression.
T-90-11 (campaign finance public data): Confirmed — `/api/essentials/politicians` uses `optionalAuth`; public reads are intentional.
T-90-12 (no real-time join): Confirmed — grep returns 0 occurrences of `transparent_motivations.contributions` in essentialsService.ts.

No new threat flags.

---

## Phase 90 Completion Statement

Phase 90 is complete. All three requirements are delivered:

- **FINA-01** (Plan 01): `finance_summary` JSONB column added to `essentials.politicians` via migration 268.
- **FINA-02** (Plan 02): FEC ingestion script populated 201 federal politicians (100% of 100 senators); data verified with spot-check queries.
- **FINA-03** (Plan 03): Both `/api/essentials/politicians` endpoints now include `finance_summary` in response objects; Wave-0 tests GREEN; TypeScript clean; live smoke tests passed.

---

## Self-Check: PASSED

| Item | Status |
|------|--------|
| backend/src/lib/essentialsService.ts | FOUND (modified) |
| backend/src/lib/essentialsBrowseService.ts | FOUND (modified) |
| 90-03-SUMMARY.md | FOUND |
| Commit 0dd4086 (Task 1) | FOUND |
| 5 vitest tests GREEN | PASSED |
| TSC clean (essentialsService errors = 0) | PASSED |
| LIST OK smoke test | PASSED |
| DETAIL OK smoke test | PASSED |
| NULL OK smoke test | PASSED |
| No transparent_motivations.contributions reference | PASSED |
