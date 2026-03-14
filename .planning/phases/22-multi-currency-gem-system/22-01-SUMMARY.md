---
phase: 22-multi-currency-gem-system
plan: 01
subsystem: api
tags: [postgres, rpc, express, zod, idempotency, gems, service-key-auth]

# Dependency graph
requires:
  - phase: 22-research
    provides: gem column names (gem_balance_yellow/blue/red), award_xp mirror pattern
  - phase: 09-xp-ledger
    provides: award_xp RPC pattern (advisory lock, idempotency, RETURNS TABLE)
  - phase: 06-gem-ledger
    provides: credit_gems RPC pattern (EXECUTE format for dynamic balance column)

provides:
  - Migration 034: idempotency_key column on gem_transactions with partial unique index
  - connect.award_gems RPC: idempotent gem award with advisory lock and RETURNS TABLE
  - gemServiceKeyAuth.ts: Bearer token middleware with per-key gem_type permissions
  - POST /api/gems/award: HTTP gem award endpoint for external services (CTC, VQ)
  - awardGems() in gemService.ts: service helper calling award_gems RPC
  - GEMS_SERVICE_KEYS env var: JSON map of service keys to permitted gem types

affects:
  - 22-02 (future plans: blue/red gem award routes, CTC integration)
  - CTC repo: can switch from direct RPC calls to POST /api/gems/award

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Bearer service key auth (separate from X-Service-Key header pattern in serviceKeyAuth.ts)
    - Per-key resource type permissions (permittedGemTypes array on request)
    - GEMS_SERVICE_KEYS JSON env var validated at module load time; process.exit(1) on malformed
    - RETURNS TABLE RPC pattern for idempotent write operations (mirrors award_xp)

key-files:
  created:
    - supabase/migrations/20260314000034_phase22_gems_idempotency.sql
    - backend/src/middleware/gemServiceKeyAuth.ts
  modified:
    - backend/src/lib/env.ts
    - backend/src/lib/gemService.ts
    - backend/src/routes/gems.ts
    - backend/src/types/database.types.ts

key-decisions:
  - "Bearer Authorization header for gem service keys (not X-Service-Key) — different auth model enabling standard JWT clients to also call endpoint structure"
  - "GEMS_SERVICE_KEYS optional at startup — absent = empty map = all /award requests get 401 (no crash)"
  - "p_transaction_type TEXT DEFAULT 'service_award' — gem_transactions.transaction_type is NOT NULL; default makes parameter backward-compatible"
  - "Partial unique index on idempotency_key (WHERE NOT NULL) — correct Postgres pattern for nullable dedup column"

patterns-established:
  - "GemServiceKeyRequest extends Request with permittedGemTypes — parallel to ServiceKeyRequest with permittedSources"
  - "adminRpc('award_gems', params, 'connect') — service helpers use adminRpc for SECURITY DEFINER RPCs, not supabaseAdmin.schema().rpc() directly"

# Metrics
duration: 18min
completed: 2026-03-14
---

# Phase 22 Plan 01: Idempotent Gem Award Pipeline Summary

**Migration 034 + award_gems RPC with idempotency/advisory lock + Bearer service key middleware + POST /api/gems/award endpoint enabling CTC and future services to award yellow/blue/red gems via HTTP with per-key type permissions**

## Performance

- **Duration:** 18 min
- **Started:** 2026-03-14T22:17:55Z
- **Completed:** 2026-03-14T22:35:55Z
- **Tasks:** 2
- **Files modified:** 6 (1 created migration, 1 new middleware, 4 updated backend files)

## Accomplishments
- Migration 034: `idempotency_key TEXT` column + partial unique index on `connect.gem_transactions`; `connect.award_gems` RPC with advisory lock, idempotency pre-check, dynamic `gem_balance_<type>` column update, and RETURNS TABLE with `is_duplicate` flag
- `gemServiceKeyAuth.ts`: Bearer token middleware parsing `GEMS_SERVICE_KEYS` JSON at module load; `process.exit(1)` on malformed JSON or invalid gem types; per-key `permittedGemTypes` attached to request
- `POST /api/gems/award`: Zod body validation, per-key gem type enforcement returning 422 `FORBIDDEN_GEM_TYPE`, idempotency returns 200 with `is_duplicate: true`, structured `{ gem_type, amount, new_balance, is_duplicate }` response

## Task Commits

Each task was committed atomically:

1. **Task 1: Migration 034 — idempotency_key column + award_gems RPC** - `48fb48d` (feat)
2. **Task 2: Service key middleware + gemService.awardGems() + POST /award route + env/types** - `5dcad3e` (feat)

**Plan metadata:** _(docs commit follows)_

## Files Created/Modified
- `supabase/migrations/20260314000034_phase22_gems_idempotency.sql` - idempotency_key column, partial unique index, award_gems RPC
- `backend/src/middleware/gemServiceKeyAuth.ts` - Bearer service key auth with permittedGemTypes
- `backend/src/lib/env.ts` - GEMS_SERVICE_KEYS optional env var added
- `backend/src/lib/gemService.ts` - adminRpc import added; AwardGemsParams/Result interfaces + awardGems() function
- `backend/src/routes/gems.ts` - POST /award route with requireGemServiceKey middleware
- `backend/src/types/database.types.ts` - idempotency_key in gem_transactions; award_gems function type

## Decisions Made

- **Bearer Authorization header vs X-Service-Key**: New gem service keys use `Authorization: Bearer` instead of `X-Service-Key`. Different auth model: external services (CTC) expect standard Bearer token semantics; also allows a regular user JWT to naturally fail (it won't be in the key map) returning 401.
- **GEMS_SERVICE_KEYS optional at startup**: Absent = empty map = all `/award` requests get 401. This allows the server to start cleanly in environments without gem service integration configured.
- **`p_transaction_type` with DEFAULT 'service_award'**: `gem_transactions.transaction_type` is NOT NULL. The DEFAULT makes the parameter backward-compatible for callers that don't specify it, while remaining explicit in the INSERT.
- **Partial unique index on `idempotency_key`**: `WHERE idempotency_key IS NOT NULL` — correct Postgres pattern for a nullable dedup column. Standard UNIQUE constraints treat NULLs as distinct (so wouldn't cause conflicts), but the partial index makes dedup intent explicit.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

**Environment variable required for gem award endpoint to be active:**

Add to `.env`:
```
GEMS_SERVICE_KEYS={"your-ctc-service-key": ["yellow"]}
```

- Key: opaque secret shared with external service (e.g., CTC)
- Value: array of gem types the key is permitted to award
- If absent: endpoint exists but returns 401 for all requests (safe default)

## Next Phase Readiness

- Migration 034 is ready to apply to live DB (adds column + index + RPC, non-breaking)
- POST /api/gems/award is complete; CTC can switch from direct `connect.credit_gems` RPC calls to this HTTP endpoint
- `GEMS_SERVICE_KEYS` env var must be set in production with CTC's service key before enabling
- Phase 22-02 can build on this foundation for additional gem award features or admin tooling

---
*Phase: 22-multi-currency-gem-system*
*Completed: 2026-03-14*
