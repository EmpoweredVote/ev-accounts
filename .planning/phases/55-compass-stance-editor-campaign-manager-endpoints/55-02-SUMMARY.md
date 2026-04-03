---
phase: 55-compass-stance-editor-campaign-manager-endpoints
plan: 02
subsystem: api
tags: [express, typescript, postgres, zod, role-based-access, audit-log, transactions]

# Dependency graph
requires:
  - phase: 55-01
    provides: stanceService.ts (getPoliticianJurisdiction, getMatchingGrant, writeStanceAuditLog), UserRoleGrant.id, migration 049
  - phase: 53-01
    provides: requireRole middleware, getCachedUserRoles
  - phase: 52-01
    provides: user_roles scope columns, role_audit_log table
provides:
  - PUT /api/compass/stances/:politicianId/:topicId — single stance write with jurisdiction enforcement
  - PUT /api/compass/stances/:politicianId/bulk — all-or-nothing batch write (any invalid topic = ROLLBACK)
  - backend/src/routes/compassContributor.ts (371 lines)
affects:
  - 55-03 (campaign manager endpoints will follow same pattern)
  - any frontend that needs to write politician stances

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "requireRole OR array — pass ['role_a', 'role_b'] for OR gate; fine-grained per-politician check happens inside handler via getMatchingGrant"
    - "Bulk write skips unchanged stances — compare value + write_in_text, only write+audit rows that actually changed"
    - "Politician existence check before getPoliticianJurisdiction — null from service is ambiguous; existence query disambiguates"

key-files:
  created:
    - backend/src/routes/compassContributor.ts
  modified:
    - backend/src/index.ts

key-decisions:
  - "compassContributorRouter mounted before compassRouter at /api/compass — /stances/* paths don't conflict with /topics, /answers, /politicians"
  - "Existence check (SELECT id FROM essentials.politicians) separate from getPoliticianJurisdiction — service returns null for both 'not found' and 'no geoid assigned'; disambiguation required for correct 404 vs fail-open behavior"
  - "Bulk route skips truly-unchanged stances (value AND write_in_text both unchanged) — updated count in response reflects actual writes, not input array length"

patterns-established:
  - "requireRole(['compass_stance_editor','campaign_manager']) — OR gate at middleware; getMatchingGrant in handler body for fine-grained politician-level check"
  - "Transaction pattern: pool.connect → BEGIN → work → COMMIT in try; ROLLBACK in catch; client.release() in finally (matches vqService.ts)"
  - "roleGrantId = matchingGrant.id (user_roles row UUID) — NOT matchingGrant.role_id (roles definition UUID)"

# Metrics
duration: 4min
completed: 2026-04-03
---

# Phase 55 Plan 02: Compass Stance Editor Routes Summary

**PUT /stances/:id/:topicId (single) and PUT /stances/:id/bulk (batch) with jurisdiction + resource enforcement, atomic transactions, and per-write audit log entries**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-04-03T19:47:20Z
- **Completed:** 2026-04-03T19:51:22Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- `compassContributor.ts` (371 lines): both PUT routes with requireAuth + requireRole OR gate + handler-body getMatchingGrant fine-grained check
- Atomic transactions matching vqService.ts exactly: pool.connect, BEGIN, COMMIT, ROLLBACK, finally release
- Every stance write produces a role_audit_log row with roleGrantId = matchingGrant.id (user_roles row UUID), fields_changed text[], snapshot_after jsonb
- Bulk route validates all topic IDs in one query before any writes; rolls back entire batch on any invalid topic
- Bulk route skips unchanged stances (no unnecessary audit noise), returns `{ politician_id, updated: N }` count of actual writes
- Mount in index.ts before compassRouter at line 79 — no path conflicts

## Task Commits

Each task was committed atomically:

1. **Task 1: Create compassContributor.ts with stance write routes** - `d354848` (feat)
2. **Task 2: Mount route, build, and integration verification** - `7b7227b` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `backend/src/routes/compassContributor.ts` — Both PUT stance write routes with full middleware stack, Zod validation, transaction pattern, jurisdiction/resource enforcement, audit logging
- `backend/src/index.ts` — Import + mount of compassContributorRouter before compassRouter at /api/compass

## Decisions Made

- **Existence check before jurisdiction lookup:** `getPoliticianJurisdiction` returns null for both "row not found" and "geoid not assigned." An explicit `SELECT id` query first distinguishes 404 from fail-open — avoids silently granting access to nonexistent politicians.
- **Bulk route: skip-unchanged optimization:** Only rows where value OR write_in_text changed are upserted and audited. The `updated` field in the response is honest about what actually changed, not just the input array length.
- **Router mount order:** compassContributorRouter at /api/compass before compassRouter. The `/stances/` prefix is completely absent from compassRouter's routes — no collision risk.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] TypeScript strict: req.params values typed as `string | string[]`**

- **Found during:** Task 1 (tsc --noEmit)
- **Issue:** Express 4.x with TypeScript strict types `req.params` values as `string | string[]`. `politicianId` and `topicId` destructured directly caused 8 type errors.
- **Fix:** Cast params with `req.params['politicianId'] as string` (the actual runtime value is always a string for named params; the union type is a TS typing artifact).
- **Files modified:** backend/src/routes/compassContributor.ts
- **Verification:** `npx tsc --noEmit` exits 0
- **Committed in:** d354848 (Task 1 commit)

**2. [Rule 1 - Bug] Dead empty `if` block with comment after early refactor**

- **Found during:** Task 1 code review before commit
- **Issue:** Initial draft had an empty `if (politicianGeoid === undefined) { /* comment */ }` block left from an intermediate design pass — dead code that would confuse readers.
- **Fix:** Removed the empty block; consolidated comment explaining the existence-check rationale inline above the `SELECT id` query.
- **Files modified:** backend/src/routes/compassContributor.ts
- **Verification:** File review + tsc clean
- **Committed in:** d354848 (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs)
**Impact on plan:** Both fixes essential for correctness. No scope creep.

## Issues Encountered

None beyond the two auto-fixed TypeScript issues above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- PUT /api/compass/stances/:politicianId/:topicId and :politicianId/bulk fully implemented and compiled
- Jurisdiction enforcement: compass_stance_editor with NULL politician geoid = fail-open + console.warn; non-null geoid = exact match; campaign_manager = exact resource_id match
- Audit trail: every write produces role_audit_log row with role_grant_id pointing to user_roles row UUID
- Phase 55 Plan 03 (campaign manager read endpoints / GET /contributor/politicians) can proceed immediately — stanceService.getContributorPoliticians is already implemented
- Manual smoke test requires granting a test user `compass_stance_editor` or `campaign_manager` role in production then hitting the PUT endpoints with a valid JWT

---
*Phase: 55-compass-stance-editor-campaign-manager-endpoints*
*Completed: 2026-04-03*
