---
phase: 13
plan: "13-02"
name: "Delete Answers Me Endpoint"
subsystem: compass
tags: [compass, reset, soft-delete, rpc, typescript-types]
one-liner: "DELETE /api/compass/answers/me endpoint via reset_compass_answers SECURITY DEFINER RPC with atomic soft-delete and optional admin full-reset flag"

dependency-graph:
  requires:
    - "13-01: schema migrations adding deleted_at to compass_responses, is_candidate to politicians, and reset_compass_answers RPC"
  provides:
    - "resetCompassAnswers() service function"
    - "DELETE /api/compass/answers/me route (requireAuth, conditional requireAdmin for ?full=true)"
    - "database.types.ts updated with deleted_at on compass_responses, is_candidate on politicians"
  affects:
    - "13-03: essentials endpoints may reference politicians with is_candidate field"
    - "13-04: import flow re-activates soft-deleted responses (deleted_at = NULL)"

tech-stack:
  added: []
  patterns:
    - "Conditional middleware invocation — requireAdmin called programmatically when ?full=true query param present"
    - "Thin service function delegating full atomicity to SECURITY DEFINER RPC"

key-files:
  created: []
  modified:
    - "backend/src/lib/compassService.ts"
    - "backend/src/routes/compass.ts"
    - "backend/src/types/database.types.ts"

decisions:
  - id: "conditional-admin-middleware"
    choice: "Invoke requireAdmin programmatically via Promise wrapper for conditional ?full=true check"
    rationale: "The admin check only applies when ?full=true is passed; standard middleware chaining would require separate route or always-admin enforcement. Promise wrapper with res.headersSent guard handles the async middleware cleanly."
    alternatives: ["Separate admin route for full reset", "Always require admin for all resets"]

metrics:
  duration: "4 minutes"
  tasks-completed: 3
  tests-passing: 90
  completed: "2026-03-06"
---

# Phase 13 Plan 02: Delete Answers Me Endpoint Summary

## What Was Built

Implemented the `DELETE /api/compass/answers/me` endpoint that allows authenticated users to soft-delete all their compass calibration responses and clear their `selected_topic_ids` in a single atomic operation. The endpoint delegates to the `reset_compass_answers` SECURITY DEFINER RPC created in Plan 13-01.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Add resetCompassAnswers to compassService.ts | 9084db4 | backend/src/lib/compassService.ts |
| 2 | Add DELETE /answers/me route to compass.ts | 2419890 | backend/src/routes/compass.ts |
| 3 | Update database.types.ts with new fields | b2384d2 | backend/src/types/database.types.ts |

## Decisions Made

### Conditional Admin Middleware Invocation

The `?full=true` flag triggers an additional `requireAdmin` check, but only when that query param is present. Rather than registering a separate admin-only route, the handler invokes `requireAdmin` programmatically via a `Promise` wrapper. After the promise resolves (or rejects if the middleware sends a 403), `res.headersSent` guards early return. This keeps the route unified while enforcing tier-specific access.

### Route Placement

`DELETE /answers/me` is placed before `GET /answers` in Express registration order. While Express differentiates HTTP methods and there is no actual routing conflict, the placement matches plan specification and follows the file's convention of grouping answer-related routes together (batch, me, GET).

### Service Function Design

`resetCompassAnswers()` is intentionally thin — it calls `adminRpc('reset_compass_answers', ...)` and throws on error. All multi-table atomic logic (soft-deleting compass_responses, clearing selected_topic_ids, optionally resetting completed_onboarding) lives in the SECURITY DEFINER RPC.

## Verification Results

- `tsc --noEmit`: exits 0, no errors
- `npm test`: 90/90 tests passing, 12 test files
- `supabaseAdmin` absent from `compass.ts` (architecture constraint: passes)
- `resetCompassAnswers` exported from `compassService.ts`
- `deleted_at` appears in compass_responses Row/Insert/Update (3 occurrences)
- `is_candidate` appears in politicians Row/Insert/Update (3 occurrences)

## Deviations from Plan

None — plan executed exactly as written.

## Next Plan Readiness

Plan 13-03 (essentials endpoints / politicians grouping) and 13-04 (importCompassCalibrations) can proceed. The `is_candidate` field is now typed in `database.types.ts` for use in filtering politicians vs. general inform figures. The reset endpoint is available for CompassV2 to call when users choose to recalibrate from scratch.
