---
phase: 25-deployment-runbook-completion
plan: 01
subsystem: infra
tags: [postgres, migrations, deployment, runbook, supabase, postgrest]

# Dependency graph
requires:
  - phase: 17-live-alpha-deployment
    provides: initial DEPLOY.md and applyMigrations.ts covering 026-029
  - phase: 22-multi-currency-gem-system
    provides: migration 034 (gem idempotency, award_gems RPC)
  - phase: 23-central-profile-page-admin-tier-promotion
    provides: migration 035 (tier_promotion_log, promote_to_connected RPC)
  - phase: 24-public-auth-hub
    provides: migration 036 (access_requests, signup_with_invite RPC)
provides:
  - backend/migrations/ contains all 11 deployment-era migration files (026-036)
  - applyMigrations.ts covers full 026-036 apply sequence with pre/post verification
  - DEPLOY.md is a complete cold-start runbook for 026-036 with rollback and PostgREST config
affects: [future-deployments, alpha-launch, ops-runbook]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pre/post verify pattern in applyMigrations.ts: idempotent apply using schema/function existence checks"
    - "DEPLOY.md Step 1b pattern: PostgREST schema config via ALTER ROLE authenticator (not dashboard UI)"

key-files:
  created:
    - backend/migrations/034_gem_idempotency.sql
    - backend/migrations/035_tier_promotion.sql
    - backend/migrations/036_signup_with_invite.sql
  modified:
    - backend/scripts/applyMigrations.ts
    - DEPLOY.md

key-decisions:
  - "Migration files copied verbatim from supabase/migrations/ — no SQL modifications"
  - "PostgREST schema config documented in Step 1b as mandatory (dashboard UI insufficient)"
  - "GOOGLE_MAPS_API_KEY and GEMS_SERVICE_KEYS added to env vars table"

patterns-established:
  - "applyMigrations.ts pre-verify: query returns 0 rows = not yet applied, proceed; 1+ rows = skip"
  - "applyMigrations.ts post-verify: same query used to confirm application succeeded"

# Metrics
duration: 5min
completed: 2026-03-15
---

# Phase 25 Plan 01: Deployment Runbook Completion Summary

**applyMigrations.ts and DEPLOY.md extended from 026-029 to full 026-036 coverage with PostgREST schema config step and rollback SQL for all new migrations**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-15T07:31:37Z
- **Completed:** 2026-03-15T07:36:21Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Copied migrations 034-036 verbatim from supabase/migrations/ to backend/migrations/, completing the 026-036 set
- Extended applyMigrations.ts MIGRATIONS array and verify queries to cover all 11 deployment-era migrations (026-036)
- Updated DEPLOY.md with full 026-036 apply order, psql fallback, verification queries, rollback SQL for 030-036, PostgREST schema config step, and two new env vars

## Task Commits

Each task was committed atomically:

1. **Task 1: Copy migration files 034-036 and extend applyMigrations.ts** - `71ad1fa` (chore)
2. **Task 2: Update DEPLOY.md with full migration coverage and PostgREST step** - `af1ccb3` (docs)

## Files Created/Modified

- `backend/migrations/034_gem_idempotency.sql` - Gem idempotency migration (verbatim copy from supabase/migrations/)
- `backend/migrations/035_tier_promotion.sql` - Tier promotion log + promote_to_connected RPC migration (verbatim copy)
- `backend/migrations/036_signup_with_invite.sql` - access_requests table + signup_with_invite RPC migration (verbatim copy)
- `backend/scripts/applyMigrations.ts` - Extended MIGRATIONS array (4→11 entries) and PRE/POST verify queries for 030-036
- `DEPLOY.md` - Complete runbook update: apply order, psql fallback, verification queries, rollback for 030-036, Step 1b PostgREST config, GOOGLE_MAPS_API_KEY and GEMS_SERVICE_KEYS env vars

## Decisions Made

None - followed plan as specified. All changes were mechanical: copy verbatim SQL, extend arrays with defined entries, add specified documentation sections.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- DEPLOY.md is now a complete cold-start runbook for all v1.3 migrations
- applyMigrations.ts is safe to re-run against a production database that has any subset of 026-036 applied
- PostgREST schema config step is documented and must be executed before Alpha launch
- Phase 25 Plan 02 (if it exists) or Alpha launch can proceed

---
*Phase: 25-deployment-runbook-completion*
*Completed: 2026-03-15*
