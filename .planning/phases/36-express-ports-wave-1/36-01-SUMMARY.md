---
plan: 36-01
status: complete
date: 2026-03-20
subsystem: treasury
tags: [express, treasury, pool.query, public-read, admin-write, zod]
depends_on: []
provides: [GET /api/treasury/cities, GET /api/treasury/cities/:id, GET /api/treasury/cities/:cityId/budgets, GET /api/treasury/budgets/:id, GET /api/treasury/budgets/:id/line-items, POST /api/treasury/cities, POST /api/treasury/budgets, POST /api/treasury/budgets/:id/categories, POST /api/treasury/budgets/:id/line-items]
affects: [36-02, 43-integration-docs]
tech-stack.added: []
tech-stack.patterns: [pool.query-only for non-public schemas, explicit-camelCase-mappers, zod-route-validation]
key-files.created: [backend/src/lib/treasuryService.ts, backend/src/routes/treasury.ts]
key-files.modified: [backend/src/index.ts]
decisions: [pool.query-for-treasury, no-postgrest-for-treasury, req-params-as-string-cast]
duration: ~20 minutes
completed: 2026-03-20
---

# Phase 36 Plan 01: Treasury Service + Routes — Summary

## One-liner

Treasury service layer and Express routes using pool.query() for CONS-08 compliance, with 5 public reads and 4 admin writes.

## What Was Built

Created the full treasury API surface in ev-accounts Express:

- `treasuryService.ts` — 9 pool.query() functions wrapping treasury schema tables. Includes explicit TypeScript interfaces, row-type helpers for pg driver string coercions, camelCase mappers, and Number() calls on all bigint/numeric columns.
- `treasury.ts` route file — 5 unauthenticated public read routes + 4 admin write routes guarded by requireAuth + requireAdmin. Zod validation on all write bodies, UUID regex validation on all route params.
- `index.ts` — treasury router registered at `app.use('/api/treasury', treasuryRouter)`.

The treasury schema is NOT in the PostgREST exposed schema list, so ALL access uses pool.query() directly. The Go server is no longer needed for treasury data (CONS-08 fulfilled).

## Deliverables

- `backend/src/lib/treasuryService.ts` — getCities, getCityById, getBudgetsByCityId, getBudgetById, getLineItemsByBudgetId, createCity, createBudget, createBudgetCategory, createBudgetLineItem — all using pool.query()
- `backend/src/routes/treasury.ts` — 9 route handlers with proper auth, validation, and error codes
- `backend/src/index.ts` — updated with treasury route registration

## Commits

| Task | Commit | Files |
|------|--------|-------|
| Task 1: Treasury service layer | c9d57d7 | backend/src/lib/treasuryService.ts |
| Task 2: Treasury routes + index.ts | 4c30b78 | backend/src/routes/treasury.ts, backend/src/index.ts |

## Verification

TypeScript (`npx tsc --noEmit`): zero errors after both tasks.

curl tests (live server on port 3001):
- `GET /api/treasury/cities` → `[]` HTTP 200 (treasury schema has 0 rows — expected per project state)
- `GET /api/treasury/cities/00000000-0000-0000-0000-000000000000` → `{"code":"NOT_FOUND","message":"City not found"}` HTTP 404
- `POST /api/treasury/cities` (no auth) → `{"error":"Missing authorization header"}` HTTP 401

All success criteria met.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] TypeScript strict typing on req.params**

- **Found during:** Task 2 — `npx tsc --noEmit` after writing treasury.ts
- **Issue:** Express `req.params.id` types as `string | string[]` in strict TypeScript; UUID_REGEX.test() requires `string`. Same issue for `req.query.fiscal_year` (typed as `string | string[] | ParsedQs | ParsedQs[]`).
- **Fix:** Added `as string` cast: `const id = req.params.id as string` and `const fiscalYearRaw = req.query.fiscal_year as string | undefined`.
- **Files modified:** backend/src/routes/treasury.ts
- **Commit:** 4c30b78 (included inline, not separate commit)

**2. [Rule 3 - Blocking] Missing GOOGLE_MAPS_API_KEY in .env**

- **Found during:** Task 2 curl verification — server refused to start, exiting with env validation error
- **Issue:** `GOOGLE_MAPS_API_KEY` is required by env.ts but was not in the local .env file; server process.exit(1) on startup, blocking curl tests
- **Fix:** Added `GOOGLE_MAPS_API_KEY=placeholder-for-local-dev` to backend/.env so server can start locally
- **Files modified:** backend/.env (not committed — .env is gitignored)
- **Note:** Production Render environment already has the real key set; this only affects local dev

## Notes

- Treasury schema currently has 0 rows in production (confirmed in Phase 34 baseline: "meetings and treasury are empty schemas"). All reads return empty arrays — this is correct and expected. The data import pipeline is out of scope.
- The POST /budgets/:id/line-items route uses the route `:id` param directly as the `categoryId` parameter in `createBudgetLineItem()`, matching the plan spec. In practice, callers constructing line items should use category-level IDs.
- Phase 36 Plan 02 (Meetings routes) is now unblocked.
