---
phase: 05-empower-flow
plan: 01
subsystem: database
tags: [postgres, supabase, rls, rpc, migrations, plpgsql]

requires:
  - phase: 04-compass-routes
    provides: inform.compass_responses table and execute_empowerment/execute_demotion RPC stubs from migration 017

provides:
  - Phase 5 schema foundation: candidate_role column, demoted_at/demotion_reason columns, consent_records table
  - Updated execute_empowerment RPC: p_reserved_slug param, re-empowerment UPDATE path, 5-attempt slug retry loop
  - Updated execute_demotion RPC: p_demotion_reason JSONB param, sets demoted_at timestamp
  - GET and PATCH /account/me: empowerment_status field and demoted_at in response for demoted users
  - Architecture test pre-approval of lib/empowerService.ts for supabaseAdmin usage

affects:
  - 05-02 (empower routes — empowerService.ts, preflight, confirm, demotion endpoints)
  - 07-admin-tool (admin demotion trigger writes p_demotion_reason)
  - 08-public-candidate (candidate_page_slug reads, slug preserved through demotion/re-empower)

tech-stack:
  added: []
  patterns:
    - Re-empowerment via UPDATE preserving original slug (not INSERT + new slug)
    - LOOP/EXIT WHEN with v_attempts counter for unique_violation retry in PL/pgSQL
    - Conditional field inclusion via spread + undefined check for optional response fields
    - empowerment_status derived from is_active boolean — separate from tier derivation

key-files:
  created:
    - supabase/migrations/20260227000018_empower_phase5.sql
    - .planning/phases/05-empower-flow/05-01-SUMMARY.md
  modified:
    - tests/integration/architecture.test.ts
    - backend/src/routes/account.ts

key-decisions:
  - "demoted_at preserved on record even after re-empowerment — cleared to NULL on re-empower to reflect current state, original demotion visible in consent_records audit trail"
  - "empowerment_status field omitted entirely (not set to null) when no empowered_profiles row exists — callers should check field presence"
  - "Re-empowerment path clears demoted_at = NULL and demotion_reason = NULL — record reflects current state, not history"
  - "slug retry loop checks v_attempts >= 5 (not > 5) — errors after exactly 5 failed attempts, per plan spec"

patterns-established:
  - "Re-empowerment UPDATE path in execute_empowerment: SELECT INTO v_existing first, branch on FOUND"
  - "Tier derivation: (empowered && empowered.is_active) ? 'empowered' : connected ? 'connected' : 'inform' — demoted users return 'connected'"

duration: 4min
completed: 2026-02-27
---

# Phase 5 Plan 01: Schema Migration and Demotion State Summary

**Phase 5 schema foundation: consent_records table, demoted_at/demotion_reason columns, candidate_role column, and updated RPCs with re-empowerment path and slug retry loop**

## Performance

- **Duration:** 4 min
- **Started:** 2026-02-27T15:52:07Z
- **Completed:** 2026-02-27T15:56:12Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Created migration 018 with 5 sections: candidate_role column, demoted_at/demotion_reason columns, empower.consent_records table (with RLS), updated execute_empowerment RPC (p_reserved_slug, re-empowerment UPDATE path, 5-attempt retry loop), and updated execute_demotion RPC (p_demotion_reason JSONB, demoted_at timestamp)
- Pre-approved lib/empowerService.ts in the architecture test allowedFiles so Plan 02 can use supabaseAdmin without violations
- Updated GET /account/me and PATCH /account/me: tier derivation now checks is_active (demoted users get tier:'connected'), empowerment_status field added ('empowered'|'demoted' — omitted when no empowered_profiles row), demoted_at included in empowered_profile response

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Phase 5 schema migration** - `d08566d` (feat)
2. **Task 2: Update architecture test and GET /account/me for demotion state** - `880ceb9` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `supabase/migrations/20260227000018_empower_phase5.sql` - Phase 5 schema changes: 5 sections covering 2 column ALTERs, 1 new table, and 2 updated RPC functions
- `tests/integration/architecture.test.ts` - Added lib/empowerService.ts to allowedFiles list
- `backend/src/routes/account.ts` - Updated GET /me and PATCH /me with demotion state fields and corrected tier derivation

## Decisions Made

- **demoted_at cleared on re-empowerment**: The re-empowerment UPDATE sets `demoted_at = NULL` and `demotion_reason = NULL`. The record reflects current state (active). Demotion history is not tracked on this row — consent_records serves as the audit trail.
- **empowerment_status omitted when absent**: Uses spread + undefined check pattern (`...(empowerment_status !== undefined && { empowerment_status })`) so the field is absent (not null) for users without an empowered_profiles row.
- **Re-empowerment checks `is_active = false`**: The SELECT INTO v_existing uses `WHERE is_active = false` — if the row doesn't exist at all, FOUND is false and fresh empowerment path runs.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

- **vitest not in root node_modules**: `npx vitest run` fails from the root directory because vitest is installed only in `backend/node_modules`. Fixed by running `npm test` from `backend/` directory, which uses the vitest script defined in backend/package.json. Architecture test passed: 2/2 tests.
- **Pre-existing TypeScript errors**: `npx tsc --noEmit` shows `SelectQueryError<"Invalid Relationships cannot infer result type">` errors across all route files. These are pre-existing — the database.types.ts file needs to be regenerated via `supabase gen types` after Phase 4 migrations are applied (documented in STATE.md Pending Todos). My changes to account.ts introduce no new error patterns; `demoted_at` follows the same type-unsafe pattern as all other Supabase query fields.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Schema foundation complete for Plan 02 (empower routes: preflight, confirm, demotion endpoints)
- empowerService.ts can be created in backend/src/lib/ and use supabaseAdmin without architecture test violations
- execute_empowerment accepts p_reserved_slug — Plan 02 slug reservation (Redis) can pass the reserved slug at confirm time
- execute_demotion accepts p_demotion_reason — Plan 02 demotion endpoint can pass structured reason JSONB
- GET /account/me returns full demotion state — frontend can surface tailored re-empowerment UI without additional API calls

---
*Phase: 05-empower-flow*
*Completed: 2026-02-27*
