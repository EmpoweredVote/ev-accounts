---
phase: 14-compass-admin-backend
plan: 01
subsystem: database
tags: [postgres, rpc, security-definer, inform-schema, compass, admin]

# Dependency graph
requires:
  - phase: 13-compassv2-backend-compatibility
    provides: inform schema with is_candidate column (migration 026) and compass_topic_categories join table
  - phase: 4-compass-routes
    provides: inform.compass_topics, compass_stances, compass_topic_categories base schema

provides:
  - admin_create_topic_with_stances RPC: atomic two-pass topic+stance creation
  - admin_assign_topic_categories RPC: atomic replace-all category assignment
  - admin_list_politicians RPC: full politician listing including is_candidate
affects:
  - 14-02: adminService.ts calls all three RPCs via supabaseAdmin.rpc()
  - 14-03: admin route handlers (POST /compass/topics, PUT /compass/topics/:id/categories, GET /compass/politicians)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Two-pass validation pattern (validate all inputs before any writes) — established in migration 028, applied again here
    - SET search_path = '' on SECURITY DEFINER — prevents search_path injection, all table refs fully-qualified

key-files:
  created:
    - backend/migrations/029_compass_admin_rpcs.sql
  modified: []

key-decisions:
  - "is_active excluded from compass_topics INSERT — GENERATED ALWAYS AS (is_live) STORED column; inserting it would cause DB error"
  - "Two-pass design in admin_create_topic_with_stances — full validation loop runs before any writes, matching pattern from migration 028"
  - "admin_list_politicians uses CREATE OR REPLACE — adds is_candidate to result set; migration 025 had no admin_list_politicians, this is a fresh install on all DBs"

patterns-established:
  - "Two-pass RPC pattern: Pass 1 = full validation loop (no writes), Pass 2 = write loop (runs only after Pass 1 completes)"
  - "GENERATED ALWAYS AS columns must be excluded from INSERT statements — is_active on compass_topics is the canonical example"

# Metrics
duration: 2min
completed: 2026-03-07
---

# Phase 14 Plan 01: Migration 029 Compass Admin RPCs Summary

**Three SECURITY DEFINER RPCs for atomic compass admin operations: topic+stance creation with two-pass validation, atomic category replace-all, and politician listing with is_candidate**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-07T00:28:42Z
- **Completed:** 2026-03-07T00:30:02Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Created `admin_create_topic_with_stances`: validates all stances before any INSERT — malformed stance rolls back entire operation including topic row
- Created `admin_assign_topic_categories`: atomic DELETE + INSERT replaces category assignments in a single transaction
- Created `admin_list_politicians`: surfaces `is_candidate` (added in migration 026) which was absent from any prior version of this RPC

## Task Commits

Each task was committed atomically:

1. **Task 1: Write migration 029 with three RPC functions** - `44f2b05` (feat)

**Plan metadata:** (pending docs commit)

## Files Created/Modified

- `backend/migrations/029_compass_admin_rpcs.sql` — three CREATE OR REPLACE functions with SECURITY DEFINER, SET search_path = '', and GRANT EXECUTE on service_role + authenticated

## Decisions Made

- `is_active` excluded from `INSERT INTO inform.compass_topics` — the column is `GENERATED ALWAYS AS (is_live) STORED`; inserting it causes a Postgres error
- Two-pass design matches migration 028 pattern: validation loop completes entirely before any write loop begins
- `admin_list_politicians` noted in header comment that migration 025 did not contain this function — it is a fresh install on all databases

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Migration 029 is ready to be applied against the live DB via the admin apply-migration tooling
- Plan 14-02 (adminService.ts) can now implement `createTopicWithStances`, `assignTopicCategories`, and `listPoliticians` using `supabaseAdmin.rpc()` calls to these three functions
- No blockers for Wave 2

---
*Phase: 14-compass-admin-backend*
*Completed: 2026-03-07*
