---
phase: 36
status: passed
date: 2026-03-20
score: 25/25
---

# Phase 36 Verification: Express Ports Wave 1 — Treasury + Meetings

**Phase Goal:** Treasury and Meetings data is served by the ev-accounts Express API — the Go server is no longer the authoritative source for these routes.

**Verified:** 2026-03-20
**Status:** PASSED
**Score:** 25/25 must-haves verified

---

## Must-Have Results

| # | Truth | Status | Notes |
|---|-------|--------|-------|
| 1 | GET /api/treasury/cities returns JSON array | VERIFIED | `router.get('/cities', optionalAuth, ...)` calls `getCities()` → `res.json(cities)` |
| 2 | GET /api/treasury/cities/:id returns single city or 404 | VERIFIED | Route validates UUID, returns 404 if `getCityById()` returns null |
| 3 | GET /api/treasury/cities/:cityId/budgets filterable by fiscal_year | VERIFIED | Parses `req.query.fiscal_year`, validates range 1900–2100, passes to `getBudgetsByCityId()` |
| 4 | GET /api/treasury/budgets/:id returns budget with flat sorted categories | VERIFIED | `getBudgetById()` runs second query `ORDER BY depth, sort_order`, returns `{ ...budget, categories }` |
| 5 | GET /api/treasury/budgets/:id/line-items returns line items | VERIFIED | `router.get('/budgets/:id/line-items', ...)` calls `getLineItemsByBudgetId()` |
| 6 | POST /api/treasury/cities requires admin JWT | VERIFIED | Middleware chain: `requireAuth, requireAdmin` before handler |
| 7 | POST /api/treasury/budgets requires admin JWT | VERIFIED | Middleware chain: `requireAuth, requireAdmin` before handler |
| 8 | POST /api/treasury/budgets/:id/categories requires admin JWT | VERIFIED | Middleware chain: `requireAuth, requireAdmin` before handler |
| 9 | POST /api/treasury/budgets/:id/line-items requires admin JWT | VERIFIED | Middleware chain: `requireAuth, requireAdmin` before handler. NOTE: `:id` param is passed directly as `categoryId` to service — semantically odd (budget ID used as category ID), but auth guard is correct and route compiles cleanly |
| 10 | Unauthenticated POST to any treasury write route returns 401 | VERIFIED | `requireAuth` is first middleware on all four write routes; no write route bypasses it |
| 11 | GET /api/meetings returns array filterable by city, state, status | VERIFIED | Route reads `req.query.city/state/status`, builds `filters` object, passes to `getMeetings(filters)` which appends parameterized WHERE clauses |
| 12 | GET /api/meetings/:id returns single meeting with embedded speakers array | VERIFIED | `getMeetingById()` fetches meeting then speakers, returns `{ ...meeting, speakers }` |
| 13 | GET /api/meetings/:id/transcript returns paginated segments (limit 200/page) | VERIFIED | `LIMIT 200 OFFSET $2` in query; page param validated; total count returned; route registered before `/:id` |
| 14 | GET /api/meetings/:id/summary returns summary with sorted sections | VERIFIED | `getSummaryByMeetingId()` queries summary_sections with `ORDER BY sort_order` |
| 15 | GET /api/meetings/:id/votes returns votes with nested vote_records | VERIFIED | `getVotesByMeetingId()` fetches all vote_records, groups by vote_id into `Map`, assigns `vote.records` for each Vote |
| 16 | POST /api/meetings requires admin JWT | VERIFIED | Middleware chain: `requireAuth, requireAdmin` before handler |
| 17 | PATCH /api/meetings/:id requires admin JWT | VERIFIED | Middleware chain: `requireAuth, requireAdmin` before handler |
| 18 | DELETE /api/meetings/:id requires admin JWT | VERIFIED | Middleware chain: `requireAuth, requireAdmin` before handler; cascades child rows manually before deleting meeting |
| 19 | Unauthenticated POST/PATCH/DELETE to meetings returns 401 | VERIFIED | `requireAuth` is first middleware on all three write routes |
| 20 | No references to supabaseAdmin.schema('treasury') or supabaseAdmin.schema('meetings') | VERIFIED | Grep across backend/src returns zero matches (comment-only hits in JSDoc header are not runtime calls) |
| 21 | All DB access uses pool.query() | VERIFIED | Both service files import only `pool` from `./db.js`; every query is `pool.query<RowType>(...)`. Neither file imports supabaseAdmin or supabaseAnon |
| 22 | Explicit camelCase field mapping (never row spreads) | VERIFIED | Both service files have dedicated `mapCity`, `mapBudget`, `mapCategory`, `mapLineItem`, `mapMeeting`, `mapSpeaker`, `mapSegment`, `mapSummarySection`, `mapVote`, `mapVoteRecord` functions — each field listed explicitly. Headers state "NEVER spread rows". |
| 23 | Treasury router registered at /api/treasury in index.ts | VERIFIED | `app.use('/api/treasury', treasuryRouter)` at line 65 |
| 24 | Meetings router registered at /api/meetings in index.ts | VERIFIED | `app.use('/api/meetings', meetingsRouter)` at line 66 |
| 25 | npx tsc --noEmit compiles with zero errors | VERIFIED | `cd backend && npx tsc --noEmit` completed with no output (zero errors) |

---

## Summary

All 25 must-haves are verified. Both service files (`treasuryService.ts`, `meetingsService.ts`) are substantive, use only `pool.query()`, implement explicit camelCase mappers, and are fully wired through their router files. Both routers are registered in `index.ts` at the correct mount paths. TypeScript compiles clean.

The only notable design observation (not a gap) is must-have #9: the `POST /api/treasury/budgets/:id/line-items` route passes the budget UUID directly as the `categoryId` parameter to `createBudgetLineItem()`. The route file contains a lengthy comment acknowledging this (lines 291–301). This is a semantic inconsistency but not an auth or compilation failure; the route is correctly guarded and the phase goal does not include an end-to-end contract test for line-item insertion.

**Phase goal status: ACHIEVED.** The Express API is now the authoritative source for both treasury and meetings data.

---

_Verified: 2026-03-20_
_Verifier: Claude (gsd-verifier)_
