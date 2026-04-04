---
phase: 56-essentials-data-editor-endpoint
plan: 01
subsystem: api
tags: [essentials, roles, rbac, postgresql, pool, audit-log, zod]

# Dependency graph
requires:
  - phase: 55-compass-stance-editor-campaign-manager-endpoints
    provides: stanceService.ts with getPoliticianJurisdiction, getMatchingGrant, writeStanceAuditLog, UserRoleGrant type
  - phase: 53-role-service-middleware
    provides: getCachedUserRoles, requireRole middleware, UserRoleGrant type
  - phase: 52-role-schema-rpc-migration
    provides: role_audit_log table, user_roles.id column, essentials_data_editor role slug

provides:
  - "getEditorMatchingGrant: pure function in stanceService.ts — fail-CLOSED jurisdiction matching for essentials_data_editor"
  - "writeEssentialsAuditLog: bio_edit audit log helper for open transactions"
  - "EssentialsAuditParams interface exported from stanceService.ts"
  - "PATCH /api/essentials/politicians/:id endpoint with restricted field enforcement and no-op detection"
  - "Dual-router mount in index.ts: essentialsEditorRouter before essentialsPoliticiansRouter"

affects:
  - 56-02 (test coverage for getEditorMatchingGrant)
  - any future essentials write endpoints

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "fail-CLOSED jurisdiction matching: NULL politician geoid returns 403 (contrast with compass_stance_editor fail-open)"
    - "No-op detection before transaction: compare provided fields against current DB values, skip audit log if unchanged"
    - "Dynamic UPDATE: only SET columns that actually changed using parameterized clause builder"
    - "API/DB field name separation: bio->bio_text, photo_origin_url->photo_custom_url writes; bio+photo_url in response"
    - "RESTRICTED_FIELDS pre-validation: check before zod parse to return specific offending field list"

key-files:
  created:
    - backend/src/routes/essentialsEditor.ts
  modified:
    - backend/src/lib/stanceService.ts
    - backend/src/index.ts

key-decisions:
  - "fail-CLOSED on NULL politician geoid for essentials_data_editor (unlike compass_stance_editor fail-open for Alpha)"
  - "writeEssentialsAuditLog is a separate function from writeStanceAuditLog — audit shape differs (field diffs vs topic value changes)"
  - "actor_id = target_user_id in bio_edit audit rows (editor is the actor, no separate target user)"
  - "No-op returns 200 with current values — no audit log write to prevent audit spam"
  - "Restricted field 422 check happens before zod parse to return specific offending field names"

patterns-established:
  - "Dual-router pattern at same path prefix: PATCH router before GET router in index.ts"
  - "Dynamic SET clause building with parameterized index tracking (paramIdx)"
  - "API field name mapping documented in file header comment for maintainability"

# Metrics
duration: 3min
completed: 2026-04-04
---

# Phase 56 Plan 01: Essentials Data Editor Endpoint Summary

**PATCH /api/essentials/politicians/:id for essentials_data_editor with fail-CLOSED jurisdiction matching, no-op detection, and bio_edit audit log**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-04T02:20:49Z
- **Completed:** 2026-04-04T02:23:20Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `getEditorMatchingGrant` pure function to stanceService.ts — fail-CLOSED on NULL politician geoid (unlike compass_stance_editor which fails open for Alpha)
- Added `writeEssentialsAuditLog` helper to stanceService.ts — `bio_edit` action, `politician` target_type, actor=target pattern
- Created `essentialsEditor.ts` with PATCH `/:id` route: restricted field 422 enforcement, jurisdiction 403, no-op 200 skip, atomic UPDATE + audit in transaction
- Mounted essentialsEditorRouter before essentialsPoliticiansRouter in index.ts (dual-router pattern)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add getEditorMatchingGrant and writeEssentialsAuditLog to stanceService** - `ba6859d` (feat)
2. **Task 2: Create essentialsEditor route and mount in index.ts** - `498762a` (feat)

## Files Created/Modified

- `backend/src/lib/stanceService.ts` — Added `EssentialsAuditParams` interface, `getEditorMatchingGrant` (fail-CLOSED pure function), `writeEssentialsAuditLog` (bio_edit INSERT helper)
- `backend/src/routes/essentialsEditor.ts` — New file: PATCH `/:id` route with RESTRICTED_FIELDS check, zod validation, getEditorMatchingGrant, no-op detection, dynamic UPDATE, writeEssentialsAuditLog
- `backend/src/index.ts` — Import and dual-router mount of essentialsEditorRouter before essentialsPoliticiansRouter

## Decisions Made

- **fail-CLOSED jurisdiction**: When `politicianGeoid === null` (politician has no home jurisdiction assigned), `getEditorMatchingGrant` continues to the next grant rather than returning it. This is the opposite of `getMatchingGrant`'s fail-open for `compass_stance_editor`. Rationale: bio edits are more sensitive than stance edits; unassigned jurisdiction should not grant write access.
- **Separate audit function**: `writeEssentialsAuditLog` is a new function rather than reusing `writeStanceAuditLog`. Rationale: the audit shape is fundamentally different — arbitrary field diffs (`changes` map) vs topic value changes (specific numeric fields).
- **actor_id = target_user_id**: In bio_edit audit rows, the editor IS the actor with no separate target user. The `target_user_id` column still receives `actorId` to keep the schema constraint satisfied.
- **No-op skips audit log**: When all provided fields match current DB values, return 200 with current record without entering a transaction. Rationale: prevents audit log pollution from idempotent client retries.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `getEditorMatchingGrant` is ready for unit test coverage (Plan 56-02)
- PATCH endpoint is live and accepts `essentials_data_editor` role grants
- Field mapping documented: bio->bio_text, photo_origin_url->photo_custom_url, response uses bio+photo_url

---
*Phase: 56-essentials-data-editor-endpoint*
*Completed: 2026-04-04*
