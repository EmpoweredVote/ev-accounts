---
phase: 12-alpha-hardening
plan: 01
subsystem: database
tags: [supabase, typescript, types, xp, inform, candidateService, empowered_profiles]

# Dependency graph
requires:
  - phase: 09-xp-and-levels
    provides: award_xp RPC, xp_transactions table, total_xp/current_level columns
  - phase: 11-candidates-and-essentials
    provides: candidateService.ts, empower.empowered_profiles queries

provides:
  - Fresh database.types.ts from live Supabase gen types + inform schema section
  - Zero (supabaseAdmin as any) casts in xpService.ts
  - TypeScript strict-mode compilation passing in both backend/ and admin/
  - candidateService.ts corrected to only select columns that exist in live DB

affects:
  - 12-alpha-hardening/12-02 and beyond (clean type baseline for all subsequent plans)
  - future inform schema migration (column additions to empowered_profiles, inform namespace creation)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "supabase gen types --linked as canonical type source (never hand-edit generated section)"
    - "inform schema types maintained manually until DB namespace created and exposed via PostgREST"

key-files:
  created: []
  modified:
    - backend/src/types/database.types.ts
    - backend/src/lib/xpService.ts
    - backend/src/routes/account.ts
    - backend/src/lib/candidateService.ts

key-decisions:
  - "inform schema appended manually to generated types: migration 015 exists but inform namespace not created in live DB; schema section preserved from prior committed types to keep existing service files compiling"
  - "candidateService.ts columns stripped: representing_city, district_type, chamber_name etc. exist in old manually-maintained types but not in live empowered_profiles; removed until migration adds those columns"
  - "getCandidatesByZip now returns all active candidates (not filtered by zip) since representing_zip column does not exist yet in live DB"

patterns-established:
  - "After any DB migration that adds tables/columns: run supabase gen types --linked and update inform section manually until PostgREST exposes inform schema"

# Metrics
duration: 45min
completed: 2026-03-06
---

# Phase 12 Plan 01: Type Regeneration and any-Cast Removal Summary

**Regenerated database.types.ts from live Supabase (xp_transactions, total_xp, award_xp/calculate_level RPCs), removed both (supabaseAdmin as any) casts in xpService.ts, and fixed candidateService.ts to only select columns that actually exist in the live empowered_profiles schema.**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-03-06T13:55:00Z
- **Completed:** 2026-03-06T14:40:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- `database.types.ts` regenerated from live Supabase schema — xp_transactions table, total_xp/current_level on connected_profiles, award_xp and calculate_level RPCs all now in types
- Both `(supabaseAdmin as any)` workarounds removed from `xpService.ts`; xp_transactions and total_xp queries are now fully typed
- inform schema appended to generated types (matching migration 015 definition) so that compassService, candidateService, connectService, adminService, and compass routes all compile clean
- candidateService.ts fixed to stop selecting non-existent empowered_profiles columns (representing_city, chamber_name etc.)
- `tsc --noEmit` exits 0 in both backend/ and admin/

## Task Commits

1. **Task 1: Regenerate database.types.ts and remove stale any-casts** - `c18b6f5` (feat)
2. **Task 2: Verify TypeScript compiles clean** - verified in Task 1 commit (no separate code changes)

## Files Created/Modified

- `backend/src/types/database.types.ts` - Regenerated from live schema; inform schema section appended manually
- `backend/src/lib/xpService.ts` - Removed two (supabaseAdmin as any) casts; direct typed calls to xp_transactions and connected_profiles.total_xp
- `backend/src/routes/account.ts` - Updated stale NOTE comment (xp/total_xp column explanation)
- `backend/src/lib/candidateService.ts` - Removed non-existent column selects from empowered_profiles queries; updated CandidateProfile and EssentialsCandidate interfaces

## Decisions Made

**inform schema in types:** The `inform` PostgreSQL namespace does not exist in the live database. Migration 015 (`20260226000015_inform_schema.sql`) creates `inform.compass_topics` etc. but the migration ran without first creating the schema namespace — the `CREATE TABLE IF NOT EXISTS inform.*` statements silently no-oped. The migration version was recorded as applied. The prior committed types had a hand-written `inform` section that kept all `schema('inform')` calls compiling. Regenerating types without it caused 50+ TypeScript errors across compassService, candidateService, connectService, adminService, and compass routes. Decision: preserve the inform section exactly as defined by migration 015, appended after the generated `empower` section.

**candidateService column removal:** The old committed types included `representing_city`, `representing_state`, `representing_zip`, `district_type`, `district_id`, `government_name`, `chamber_name`, `chamber_name_formal` on `empower.empowered_profiles`. The live database does not have these columns — they were in the stale hand-written types but were never migrated. The generated types exposed this discrepancy. Decision: remove these column selects from getCandidateBySlug and getCandidatesByZip; update CandidateProfile/EssentialsCandidate interfaces to drop the fields. getCandidatesByZip ZIP-based filtering is non-functional until the migration adds representing_zip.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] inform schema not in live DB — manual append to generated types**

- **Found during:** Task 2 (tsc --noEmit after type regeneration)
- **Issue:** The `inform` PostgreSQL namespace does not exist in the live database despite migration 015 being recorded as applied. `supabase gen types --linked` correctly omitted it. This caused 50+ TypeScript errors across files that call `.schema('inform')`.
- **Fix:** Appended the `inform` schema section from the prior committed types (matches migration 015 definition exactly) to the generated file. Added a comment block marking it as manually maintained pending DB namespace creation.
- **Files modified:** `backend/src/types/database.types.ts`
- **Verification:** `grep "compass_topics" backend/src/types/database.types.ts` returns matches; `tsc --noEmit` exits 0
- **Committed in:** `c18b6f5`

**2. [Rule 1 - Bug] candidateService.ts selecting non-existent empowered_profiles columns**

- **Found during:** Task 2 (tsc --noEmit after type regeneration)
- **Issue:** `getCandidateBySlug` and `getCandidatesByZip` selected `representing_city`, `chamber_name`, `district_type`, etc. from `empower.empowered_profiles`. These columns exist in the old hand-written types but not in the live DB. The generated types expose this as `SelectQueryError<"column 'representing_city' does not exist">`.
- **Fix:** Removed the non-existent column selects; updated `CandidateProfile` and `EssentialsCandidate` interfaces to drop those fields. Updated `getCandidatesByZip` to not filter by `representing_zip` (column doesn't exist); now returns all active candidates.
- **Files modified:** `backend/src/lib/candidateService.ts`
- **Verification:** `tsc --noEmit` exits 0 with no errors on candidateService.ts
- **Committed in:** `c18b6f5`

---

**Total deviations:** 2 auto-fixed (both Rule 1 — bugs exposed by accurate type regeneration)
**Impact on plan:** Both fixes were necessary to reach a compiling codebase. The inform schema fix preserves all existing service code without changes to those files. The candidateService fix corrects a runtime bug where queries would have failed on columns that don't exist.

## Issues Encountered

**inform namespace not created in live DB:** Migration 015 runs `CREATE TABLE IF NOT EXISTS inform.compass_topics (...)`. The `IF NOT EXISTS` clause means the statement silently no-ops if the schema doesn't exist (rather than raising an error), so the migration was marked as applied even though no tables were created. The `inform` namespace is absent from the live database. This means all Phase 4 compass routes are non-functional in production — they query tables that don't exist.

**PostgREST schema exposure discrepancy:** The Supabase Management API reports the PostgREST config includes `inform` in its schema list (so `supabase config push` says "up to date"), but the running PostgREST instance only exposes `public, graphql_public, validation_quests, connect`. This discrepancy suggests either a cached config state or a separate PostgREST restart not being triggered. Not a blocker for type generation (which uses direct DB connection), but means `Accept-Profile: inform` HTTP requests fail with PGRST106.

**empowered_profiles schema gap:** The planned Phase 5 empowerment columns (`representing_city`, `district_type`, etc.) were hand-written into the prior types but never migrated to the live DB. The candidate page feature is partially non-functional as a result.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Type baseline is clean: `tsc --noEmit` exits 0 in backend/ and admin/
- XP service (xpService.ts) is now fully typed with no workarounds
- Inform schema requires a repair migration: `CREATE SCHEMA IF NOT EXISTS inform;` followed by re-running migration 015 tables. This is a prerequisite before compass routes work in production.
- empowered_profiles missing columns require a future migration adding representing_city, district_type, chamber_name etc. before candidateService can return full candidate profiles.

---
*Phase: 12-alpha-hardening*
*Completed: 2026-03-06*
