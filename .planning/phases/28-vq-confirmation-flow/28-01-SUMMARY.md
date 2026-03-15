---
phase: 28-vq-confirmation-flow
plan: 01
subsystem: api
tags: [postgres, rpc, security-definer, advisory-locks, idempotency, gems, verification-rating, vq]

# Dependency graph
requires:
  - phase: 27-verification-rating-schema
    provides: verification_rating and vq_hold_until columns on connected_profiles
  - phase: 22-multi-currency-gem-system
    provides: gem_transactions table, requireGemServiceKey middleware, adminRpc pattern
  - phase: 21-empowered-profiles-politician-schema
    provides: inform.politicians and inform.politician_answers tables

provides:
  - POST /api/vq/confirm-stance endpoint (service-key-authenticated)
  - connect.vq_confirmation_results table (idempotency result cache)
  - connect.confirm_vq_stance SECURITY DEFINER RPC (atomic VQ resolution)
  - backend/src/lib/vqService.ts (confirmVqStance service function)
  - backend/src/routes/vq.ts (Express router for /api/vq)

affects:
  - 29-vq-integration-smoke-test
  - any future phase that reads vq_confirmation_results or confirmation audit trail

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Atomic VQ confirmation: SECURITY DEFINER RPC handles gems + VR + stance upsert + result cache in one transaction"
    - "Advisory lock deadlock prevention: acquire pg_advisory_xact_lock on all affected users in sorted UUID order before any writes"
    - "Per-user idempotency sub-key: p_idempotency_key || ':' || uid::text prevents double-crediting when a user appears across multiple concurrent calls"
    - "Idempotency pre-check before locks: cached result returned immediately without acquiring any locks or doing any writes"

key-files:
  created:
    - supabase/migrations/20260315000038_phase28_vq_confirm_stance.sql
    - backend/src/lib/vqService.ts
    - backend/src/routes/vq.ts
  modified:
    - backend/src/index.ts
    - backend/src/types/database.types.ts

key-decisions:
  - "Advisory locks acquired on ALL users (correct + incorrect combined) in sorted UUID order before any writes — prevents deadlocks in concurrent calls"
  - "Per-user idempotency sub-key (main_key:uid) for gem_transactions — prevents double-crediting if a user appears in multiple concurrent confirmation calls"
  - "Idempotency pre-check happens before validation and before lock acquisition — cheapest possible path for replays"
  - "No nested SECURITY DEFINER calls — gem INSERT + balance UPDATE done inline rather than calling credit_gems RPC"

patterns-established:
  - "VQ service uses the same GEMS_SERVICE_KEYS / requireGemServiceKey auth model as the gems endpoint — VQ service key must include 'red' in permitted types"
  - "confirm_vq_stance RETURNS JSONB scalar — adminRpc returns data directly, not as an array row"

# Metrics
duration: 3min
completed: 2026-03-15
---

# Phase 28 Plan 01: VQ Confirmation Flow Summary

**Atomic POST /api/vq/confirm-stance endpoint backed by a SECURITY DEFINER RPC that awards Red Gems, adjusts verification ratings (+3/-10 with cap/floor), sets vq_hold_until on floor hit, upserts politician stances, and replays idempotently**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-15T21:39:11Z
- **Completed:** 2026-03-15T21:42:27Z
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Migration 038 delivers `connect.vq_confirmation_results` table and `connect.confirm_vq_stance` RPC with full atomic semantics
- Advisory lock pattern (sorted UUID order) prevents deadlocks in concurrent confirmation calls sharing users
- End-to-end Express route wired: `requireGemServiceKey` auth, Zod validation, `red` gem type check, error mapping, 200 JSON response

## Task Commits

1. **Task 1: Migration 038 — vq_confirmation_results table + confirm_vq_stance RPC** - `9b0f5c5` (feat)
2. **Task 2: VQ route, service file, and route registration** - `692d1d4` (feat)

**Plan metadata:** (docs commit below)

## Files Created/Modified

- `supabase/migrations/20260315000038_phase28_vq_confirm_stance.sql` — vq_confirmation_results table + confirm_vq_stance SECURITY DEFINER RPC
- `backend/src/lib/vqService.ts` — confirmVqStance() service wrapping the RPC via adminRpc, typed params/result interfaces, error code mapping
- `backend/src/routes/vq.ts` — POST /confirm-stance with requireGemServiceKey, Zod ConfirmStanceBodySchema, permittedGemTypes red check
- `backend/src/index.ts` — import vqRouter + app.use('/api/vq', vqRouter) after gemsRouter
- `backend/src/types/database.types.ts` — vq_confirmation_results table type + confirm_vq_stance function type in connect schema

## Decisions Made

- **Idempotency pre-check before locks:** The cached result lookup happens before validation and before any advisory lock acquisition — cheapest replay path, no contention on repeat calls.
- **No nested SECURITY DEFINER calls:** Gem ledger INSERT and balance UPDATE are done inline in confirm_vq_stance rather than calling the credit_gems RPC. Nested SECURITY DEFINER calls are unreliable in Postgres.
- **Per-user idempotency sub-key:** `p_idempotency_key || ':' || uid::text` for gem_transactions prevents double-crediting when a user appears in multiple concurrent VQ confirmation calls sharing the same parent key.
- **Advisory locks on combined + sorted user set:** All users (correct and incorrect) are combined, deduplicated, sorted, and locked before any writes. This ensures deadlock-free operation even when two concurrent calls have overlapping user sets.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. TypeScript compilation passed clean on first attempt (`npx tsc --noEmit` with no output).

## User Setup Required

None - no external service configuration required. The VQ service key must already be in `GEMS_SERVICE_KEYS` with `'red'` in its permitted types (configured in Phase 22).

## Next Phase Readiness

- POST /api/vq/confirm-stance is fully wired and compiled
- Migration 038 is ready to apply to live DB
- Phase 29 (VQ integration smoke test) can now verify the full flow end-to-end
- Blocker from STATE.md still applies: Chris needs to confirm VQ service key is set in Render env before smoke test

---
*Phase: 28-vq-confirmation-flow*
*Completed: 2026-03-15*
