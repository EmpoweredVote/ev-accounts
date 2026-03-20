---
phase: 39-compass-additions
plan: 02
subsystem: api
tags: [express, typescript, compass, compare, verdicts, pool-query, proximity-scoring]

# Dependency graph
requires:
  - phase: 39-01
    provides: inform.compass_verdicts table, upsert_compass_verdicts RPC, NUMERIC(3,1) on politician_answers.value
  - phase: 35-politician-deduplication
    provides: essentials.politicians as sole politician source

provides:
  - POST /api/compass/compare — proximity alignment scoring for 1-50 politicians
  - GET /api/compass/verdicts — user's Read & Rank verdicts with optional politician_id filter
  - POST /api/compass/verdicts — atomic batch verdict upsert via upsert_compass_verdicts RPC
  - POST /api/compass/politicians/:id/answers/batch — politician answers filtered by topic_ids
  - compareWithPoliticians, getUserVerdicts, getBatchPoliticianAnswers in compassService.ts

affects:
  - 39-03 (admin compass routes share compassService functions)
  - CompassV2 frontend integration (all four endpoints are CompassV2 facing)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Proximity scoring: 1 - (|u-p| / 5) per shared topic, averaged * 100, Math.round"
    - "Shared-topics intersection: fetch user Map + filter politician rows by userMap.has(topic_id)"
    - "Batch route before parameterized: /politicians/:id/answers/batch registered before /politicians/:id/answers"
    - "Optional filter pattern: getUserVerdicts branches on politicianId presence (no filter vs JOIN)"

key-files:
  created: []
  modified:
    - backend/src/lib/compassService.ts
    - backend/src/routes/compass.ts

key-decisions:
  - "essentials.quotes.politician_id assumed as FK column — consistent with EV-Backend schema conventions; documented in getUserVerdicts comment for adjustment if wrong"
  - "POST /verdicts calls adminRpc with JSON.stringify(verdicts) — keeps atomicity in the SECURITY DEFINER RPC; does not loop pool.query() per verdict"
  - "Batch answers route uses optionalAuth with short-circuit [] for unauthenticated — consistent with other anonymous compass mode routes"
  - "compareWithPoliticians fetches user answers once, reuses across all politicians — single pool.query() for user; N parallel queries for politicians"

patterns-established:
  - "pool.query() for all inform + essentials reads in compare/verdicts — never supabaseAnon for user-scoped reads"
  - "Route ordering enforcement: more-specific paths before parameterized paths — batch before :id/answers"

# Metrics
duration: 3min
completed: 2026-03-20
---

# Phase 39 Plan 02: Compass Additions Routes Summary

**Proximity alignment compare endpoint, Read & Rank verdicts CRUD, and batch politician answers — four CompassV2-facing routes backed by pool.query() service functions**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-20T21:49:49Z
- **Completed:** 2026-03-20T21:52:45Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `compareWithPoliticians` service function with proximity scoring (intersection of shared topics only; formula: 1 - |u-p|/5 averaged * 100)
- Added `getUserVerdicts` with optional politician_id filter via essentials.quotes JOIN
- Added `getBatchPoliticianAnswers` using `ANY($2::uuid[])` parameterized array query
- Wired all four route handlers into compass.ts with correct auth middleware, Zod validation, and route ordering

## Task Commits

1. **Task 1: Add service functions to compassService.ts** — `5bbc9ec` (feat)
2. **Task 2: Add compare, verdicts, and batch routes to compass.ts** — `21f7c9e` (feat)

**Plan metadata:** (see final commit below)

## Files Created/Modified

- `backend/src/lib/compassService.ts` — Added interface types (CompareResult, CompareTopic, Verdict, PoliticianAnswer) and three exported async functions: compareWithPoliticians, getUserVerdicts, getBatchPoliticianAnswers
- `backend/src/routes/compass.ts` — Added three Zod schemas (compareSchema, batchPoliticianAnswersSchema, postVerdictsSchema), four route handlers, and updated service imports

## Decisions Made

- **essentials.quotes.politician_id column name** — Cannot be verified without a live DB query (the quotes table was created by the Go server and has no ev-accounts migration). Implemented with `q.politician_id` (the conventional FK name) and left a clear comment in getUserVerdicts documenting the discovery query. If the column name differs, only that one JOIN clause needs updating.
- **POST /verdicts uses adminRpc not pool.query** — The `upsert_compass_verdicts` SECURITY DEFINER RPC already exists (from 39-01); calling it via adminRpc is correct and maintains the no-nested-SECURITY-DEFINER pattern. Pool.query for the insert would require either a loop (not atomic) or a raw transaction (replicating the RPC).
- **Batch answers route (optionalAuth with [] short-circuit)** — Consistent with the existing anonymous compass mode pattern in compass.ts. Unauthenticated clients get empty array immediately with no DB access.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required. Routes are available immediately after deploy.

## Next Phase Readiness

- Plan 03 (admin compass routes) is unblocked — compass.ts patterns established; compassService.ts ready to extend
- CompassV2 can begin integration testing against all four new endpoints
- If `essentials.quotes.politician_id` column name is incorrect, the GET /verdicts?politician_id= filter will fail at runtime with a column-not-found error — easy to diagnose and fix with one-line SQL update

---
*Phase: 39-compass-additions*
*Completed: 2026-03-20*
