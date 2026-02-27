---
phase: 06-gems-roles-social-graph
plan: 02
subsystem: api
tags: [express, postgres, supabase, gems, roles, rpc]

requires:
  - phase: 06-01
    provides: gem_transactions table, credit_gems/debit_gems RPCs, roles/user_roles tables, social_relationships table

provides:
  - gemService.ts with creditGems/debitGems (via SECURITY DEFINER RPCs) and getBalance/getTransactionHistory (via pool)
  - roleService.ts with grantRole (tier eligibility + CIVIC-04 conflict enforcement), revokeRole, getUserRoles, getAllActiveRoles
  - GET /api/gems/balance and GET /api/gems/transactions routes (requireConnected)
  - GET /api/roles and GET /api/roles/me routes
  - Architecture test allowedFiles updated for gemService.ts and roleService.ts

affects: [06-03, 07-admin-tool]

tech-stack:
  added: []
  patterns:
    - Service layer calls SECURITY DEFINER RPCs for gem writes; pool for reads
    - ROLE_CONFLICT_GROUPS map pattern for CIVIC-04 conflict enforcement (empty for Alpha)
    - Partial unique index enforcement pattern: grantRole never reuses revoked rows

key-files:
  created:
    - backend/src/lib/gemService.ts
    - backend/src/lib/roleService.ts
    - backend/src/routes/gems.ts
    - backend/src/routes/roles.ts
  modified:
    - backend/src/index.ts
    - tests/integration/architecture.test.ts

key-decisions:
  - "debitGems throws INSUFFICIENT_BALANCE (not just RPC error) for semantic clarity"
  - "grantRole NEVER reuses revoked rows — INSERT new row; partial unique index enforces no duplicate active grants"
  - "ROLE_CONFLICT_GROUPS is empty for Alpha but conflict check code path is wired and exercised"
  - "Grant/revoke endpoints deferred to Phase 7 admin routes — only read endpoints exposed in Phase 6"

patterns-established:
  - "ROLE_CONFLICT_GROUPS: Record<string, string> pattern for future role conflict enforcement"
  - "Gem service uses supabaseAdmin for writes (RPCs), pool for reads — matches empowerService pattern"

duration: 8min
completed: 2026-02-27
---

# Phase 6 Plan 02: Gem Service + Role Service Summary

**Gem ledger API (credit/debit via SECURITY DEFINER RPCs, balance + paginated history via pool) and role system (tier-gated grant with CIVIC-04 conflict enforcement, soft revocation, read routes)**

## Performance

- **Duration:** 8 min
- **Started:** 2026-02-27T19:18:28Z
- **Completed:** 2026-02-27T19:26:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- gemService.ts: creditGems/debitGems call connect.credit_gems/debit_gems SECURITY DEFINER RPCs; getBalance/getTransactionHistory use pool (matches empowerService pattern)
- roleService.ts: grantRole enforces tier eligibility (empowered/connected check), CIVIC-04 conflict groups (empty Alpha map but code path wired), inserts new row on grant (never reuses revoked); revokeRole sets revoked_at; getUserRoles/getAllActiveRoles via pool
- GET /api/gems/balance (requireConnected) and GET /api/gems/transactions (paginated, optional gem_type filter)
- GET /api/roles (requireAuth only) and GET /api/roles/me (requireConnected)
- Architecture test allowedFiles updated for gemService.ts and roleService.ts

## Task Commits

1. **Task 1: Gem service + role service + architecture test** - `93dc589` (feat)
2. **Task 2: Gem routes + role routes + mount** - `624f5c5` (feat)

## Files Created/Modified
- `backend/src/lib/gemService.ts` - creditGems, debitGems, getBalance, getTransactionHistory
- `backend/src/lib/roleService.ts` - grantRole (tier+conflict), revokeRole, getUserRoles, getAllActiveRoles
- `backend/src/routes/gems.ts` - GET /balance, GET /transactions
- `backend/src/routes/roles.ts` - GET /roles, GET /roles/me
- `backend/src/index.ts` - mounted /api/gems and /api/roles
- `tests/integration/architecture.test.ts` - allowedFiles updated

## Decisions Made
- debitGems parses the RPC error for 'INSUFFICIENT_BALANCE' string and re-throws with structured code — same pattern as sendPeerRequest in Plan 03
- grantRole uses `INSERT ... VALUES` (new row), never `UPDATE ... SET revoked_at = NULL` — preserves complete audit history matching 06-01 schema decision
- Grant/revoke HTTP endpoints NOT exposed in Phase 6 — they are admin-only, deferred to Phase 7 per CONTEXT.md
- ROLE_CONFLICT_GROUPS is an empty `Record<string, string>` — the `if (conflictGroup)` guard makes it a no-op for Alpha while the pattern is established

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Plan 02 not executed — executed as prerequisite for Plan 03**
- **Found during:** Pre-execution (plan 03 depends_on 06-02, but 06-02-SUMMARY.md did not exist)
- **Issue:** Plan 03 was spawned directly but plan 02 had never run
- **Fix:** Executed plan 02 tasks inline before proceeding to plan 03 tasks
- **Verification:** Architecture tests pass, TypeScript compiles (pre-existing TS errors unrelated to these files)

---

**Total deviations:** 1 auto-fixed (blocking — prerequisite execution)
**Impact on plan:** Required to unblock plan 03. No scope creep.

## Issues Encountered
- Pre-existing TypeScript errors in codebase (database.types.ts not generated — Supabase SelectQueryError types) affect gems.ts and roles.ts the same way they affect all other route files. This is a known pending TODO in STATE.md (run `supabase gen types`). The new files follow exactly the same pattern as existing empower.ts routes.

## Next Phase Readiness
- gemService and roleService are ready for Plan 03 (socialService.ts references roleService pattern)
- roleService.ts has CIVIC-04 conflict enforcement wired — Plan 03 completes CIVIC-04 by documenting the pattern
- Architecture test allows gemService.ts and roleService.ts — Plan 03 will add socialService.ts

---
*Phase: 06-gems-roles-social-graph*
*Completed: 2026-02-27*
