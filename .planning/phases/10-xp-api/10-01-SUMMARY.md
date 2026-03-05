---
phase: 10-xp-api
plan: "01"
name: XP Award Endpoint
subsystem: xp-api
completed: "2026-03-05"
duration: "6m"
tags: [xp, service-key, middleware, rpc, idempotency]

dependency-graph:
  requires: [09-02]
  provides: [POST /api/xp/award, requireServiceKey middleware, xpService module]
  affects: [10-02]

tech-stack:
  added: []
  patterns: [service-key-auth, per-key-source-authorization, rpc-service-layer]

key-files:
  created:
    - backend/src/middleware/serviceKeyAuth.ts
    - backend/src/lib/xpService.ts
    - backend/src/routes/xp.ts
  modified:
    - backend/src/lib/env.ts
    - backend/src/index.ts
    - backend/.env.example
    - tests/integration/architecture.test.ts

decisions:
  - Service keys optional in env (not required): avoids breaking existing tests that don't set them
  - SERVICE_KEY_MAP built at module load time: single evaluation at startup, not per-request
  - Per-key source authorization returns 422 (not 401): valid key, wrong scope is a usage error
  - awardXp maps RPC RETURNS TABLE row[0] to AwardXpResult interface with renamed fields
---

# Phase 10 Plan 01: XP Award Endpoint Summary

**One-liner:** Service-key auth middleware + xpService RPC wrapper + POST /api/xp/award with per-key source authorization and idempotency enforcement.

## Deliverables

- `serviceKeyAuth.ts` — `requireServiceKey` middleware reads `X-Service-Key` header, looks up in module-level `SERVICE_KEY_MAP` built from env vars at startup, attaches `permittedSources` array to request, returns 401 for missing/unrecognized keys
- `xpService.ts` — `awardXp` function wraps `award_xp` RPC via `adminRpc`, maps `NOT_CONNECTED` and `INVALID_AMOUNT` error messages to typed error codes, remaps `RETURNS TABLE` row fields to `AwardXpResult` shape
- `routes/xp.ts` — `POST /award` route with Zod body validation (`user_id`, `source` enum, `amount`, `idempotency_key`, optional `metadata`), per-key source authorization check, xpService delegation, error code mapping
- `env.ts` updated with `QUEST_SERVICE_KEY`, `TRIVIA_SERVICE_KEY`, `ADMIN_SERVICE_KEY` (all optional)
- Route registered at `/api/xp` in `index.ts`
- `lib/xpService.ts` added to architecture test allowlist

## Key Decisions

- **Service keys optional in Zod schema**: Making them required would break all existing integration tests at import time — those tests set test env vars but not service keys. An undefined key simply doesn't appear in `SERVICE_KEY_MAP`, so requests without a valid key receive 401 naturally. No need for test-environment special-casing.
- **`SERVICE_KEY_MAP` built at module load**: Evaluated once at startup rather than per-request. Env vars are static after process launch, so per-request lookup would be wasteful. This also means a key change requires a server restart, which is acceptable for secrets rotation.
- **Per-key source authorization is 422, not 403**: A valid key presenting an unauthorized source is a caller usage error — the request is malformed for that key's scope. 422 (Unprocessable Entity) signals this to the calling service more accurately than 403.
- **`XP_SOURCES` as const array satisfies both Zod enum and TypeScript type**: `z.enum(XP_SOURCES)` creates the validation schema; `typeof XP_SOURCES[number]` creates the `XpSource` type. Single source of truth for the allowed set.
- **Row mapping in xpService**: The `award_xp` RPC returns `id` (not `transaction_id`) and `current_level` (not `level`). The service layer remaps to the public `AwardXpResult` interface, keeping the DB column names internal.

## Deviations from Plan

None — plan executed exactly as written.

## Test Results

```
Test Files: 10 passed (10)
Tests: 72 passed | 100 skipped (172)
Duration: 15.28s
```

Skips are network-dependent tests (Supabase, Redis) that require real credentials. All CI-safe tests pass.

Specific verifications:
- `npx tsc --noEmit` — no TypeScript errors (both tasks)
- `architecture.test.ts` — 2/2 tests pass (xpService in allowlist, no supabaseAdmin in routes)
- `env-validation.test.ts` — 3/3 tests pass (service keys remain optional)
- `health.test.ts` — 3/3 tests pass (no service key env vars required at startup)
- `grep "supabaseAdmin" backend/src/routes/xp.ts` — returns empty (architecture constraint maintained)

## Commit Log

| Hash | Description |
|------|-------------|
| 7cd4a47 | feat(10-01): create service-key middleware, env config, and xpService module |
| a006c9e | feat(10-01): create POST /api/xp/award route and register in app |
