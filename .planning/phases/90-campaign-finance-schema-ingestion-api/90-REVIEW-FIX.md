---
phase: 90-campaign-finance-schema-ingestion-api
fixed_at: 2026-06-04T19:06:47Z
review_path: .planning/phases/90-campaign-finance-schema-ingestion-api/90-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 90: Code Review Fix Report

**Fixed at:** 2026-06-04T19:06:47Z
**Source review:** .planning/phases/90-campaign-finance-schema-ingestion-api/90-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6 (2 Critical, 4 Warning; Info findings excluded by fix_scope)
- Fixed: 6
- Skipped: 0

## Fixed Issues

### CR-01: `finance_summary` missing from SELECT in `getRepresentativesByAddress`, `getRepresentativesByJurisdiction`, `getLocalOfficialsByUserId`

**Files modified:** `backend/src/lib/essentialsService.ts`
**Commit:** 082a7b0
**Applied fix:** Added `p.finance_summary,` to four SQL SELECT column lists: `districtQueryText` and `statewideQueryText` in `getRepresentativesByAddress` (after `p.is_incumbent`), and the `SELECT_FIELDS` constant in both `getRepresentativesByJurisdiction` and `getLocalOfficialsByUserId`. The row mappers already referenced `row.finance_summary` but the column was never fetched, so all four paths silently returned `null` after ingestion.

---

### CR-02: `essentialsBrowseService` hard-codes `finance_summary: null` in both browse functions

**Files modified:** `backend/src/lib/essentialsBrowseService.ts`
**Commit:** fbda190
**Applied fix:** Added `p.finance_summary,` to all 6 SELECT clauses in `essentialsBrowseService.ts` (main and statewide queries in `getPoliticiansByArea`; main, statewide, congressional-intersection, and city-district queries in `getPoliticiansByGovernmentList`). Changed both hardcoded `finance_summary: null` mapper values to `(row.finance_summary as FinanceSummary | null) ?? null`. Added `FinanceSummary` to the import from `essentialsService.js`.

---

### WR-01: Deduplication key in `getRepresentativesByJurisdiction` collapses all vacant/null-ID offices to one key

**Files modified:** `backend/src/lib/essentialsService.ts`
**Commit:** f5db141
**Applied fix:** Replaced `const key = (row.id as string) ?? String(row.external_id)` with a composite fallback: when `row.id` is null, uses `` `vacant-${row.geo_id ?? ''}-${row.district_id ?? ''}` `` instead of `"null"`. Prevents all vacant offices with no ID and no external_id from collapsing to the same dedup key and being silently dropped.

---

### WR-02: Fatal error handler in ingestion script uses fire-and-forget `pool.end()` before `process.exit`

**Files modified:** `backend/scripts/run-fec-finance-summary.ts`
**Commit:** 44fb967
**Applied fix:** Changed `main().catch(err => { void pool.end(); process.exit(1); })` to `main().catch(async (err) => { try { await pool.end(); } catch { /* ignore */ } process.exit(1); })`. The `await` ensures the pg pool has a chance to drain before the process terminates, preventing mid-commit aborts on fatal errors.

---

### WR-03: `vacant_since` type mismatch in `getPoliticiansByGovernmentList` violates `PoliticianFlatRecord` contract

**Files modified:** `backend/src/lib/essentialsBrowseService.ts`
**Commit:** fbda190
**Applied fix:** Changed `vacant_since: row.vacant_since as string ?? ''` to `vacant_since: (row.vacant_since as string | null) ?? null` in the `getPoliticiansByGovernmentList` row mapper, matching the `PoliticianFlatRecord` interface declaration and all other mappers in `essentialsService.ts`.

---

### WR-04: Test regex for `PoliticianFlatRecord` can bleed into adjacent interface body on formatting change

**Files modified:** `backend/test/essentialsService-finance-summary.test.ts`
**Commit:** d42b507
**Applied fix:** Added `\n\}` as the first lookahead alternative in the `PoliticianFlatRecord` interface body regex: changed `(?=\nexport |\nfunction |\nconst |\nclass )` to `(?=\n\}|\nexport |\nfunction |\nconst |\nclass )`. The capture now terminates at the closing brace regardless of what follows, preventing false positives from adjacent interface bodies.

---

_Fixed: 2026-06-04T19:06:47Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
