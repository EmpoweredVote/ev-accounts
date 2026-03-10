---
phase: 17-live-alpha-deployment
plan: 03
subsystem: infra
tags: [deployment, production, human-verified, smoke-test, supabase, migrations]

requires:
  - phase: 17-live-alpha-deployment/17-01
    provides: applyMigrations.ts and DEPLOY.md runbook
  - phase: 17-live-alpha-deployment/17-02
    provides: smokeTest.ts production go/no-go gate

provides:
  - Human-confirmed production deployment — migrations 026-029 applied, smoke test passed, admin UI verified

key-decisions:
  - "Migrations applied manually via Supabase SQL Editor (chunked) — applyMigrations.ts script failed due to DNS resolution issue with direct connection from Windows/MINGW64"
  - "Migration 026 required chunked execution — Supabase SQL Editor only ran CREATE SCHEMA, not table creation; tables created in two separate chunks"
  - "Migration 029 required individual function execution — SQL Editor silently dropped multi-function scripts; each function run separately"
  - "Migration 016 (inform RLS + grants) was re-applied after table creation — policies had been recorded as applied but never executed since inform tables didn't exist at the time"
  - "PostgREST schema config set via ALTER ROLE authenticator SET pgrst.db_schemas — dashboard UI change was not being picked up by PostgREST; direct DB config was required"
  - "admin_list_politicians() dropped and recreated — existing function had incompatible return type (missing is_candidate column added in 026)"

duration: ~90min (human-interactive)
completed: 2026-03-10
---

# Phase 17 Plan 03: Production Execution Checkpoints Summary

**Human-confirmed production deployment: migrations 026-029 applied to production Supabase, smoke test passes (4/4 automated checks), admin UI loads without JS errors.**

## Performance

- **Duration:** ~90 min (interactive)
- **Tasks:** 3/3 checkpoints confirmed
- **Files modified:** 0 (production DB operations only)

## Accomplishments

- Migrations 026-029 applied to production Supabase (`kxsdzaojfaibhuzmclfq`)
- All four migration artifacts verified: `is_candidate` column + 3 RPCs (reset_compass_answers, import_compass_calibrations, admin_create_topic_with_stances)
- Smoke test: `SMOKE TEST PASSED` — 4/4 automated checks pass against `https://ev-accounts-api.onrender.com`
- Admin UI: loads at `https://accounts.empowered.vote/` with no JS errors; login and dashboard functional

## Checkpoint Results

1. **Migrations applied** ✓ — All four migrations confirmed via verification query (found=1 for all)
2. **Smoke test passed** ✓ — `Results: 4/4 passed (1 skipped) — SMOKE TEST PASSED`
3. **Admin UI verified** ✓ — Loads without JS errors, login and dashboard functional

## Issues Encountered

**Issue 1: Direct DB connection DNS failure**
`applyMigrations.ts` could not resolve `db.kxsdzaojfaibhuzmclfq.supabase.co` from Windows/MINGW64. Workaround: applied all migrations manually via Supabase SQL Editor.

**Issue 2: Migration 026 partial execution in SQL Editor**
SQL Editor only executed `CREATE SCHEMA IF NOT EXISTS inform` and stopped. Tables were created in two chunks manually.

**Issue 3: Migration 029 silent drop in SQL Editor**
Multi-function script appeared to succeed but created no functions. Each function (`admin_create_topic_with_stances`, `admin_assign_topic_categories`, `admin_list_politicians`) required a separate SQL Editor execution.

**Issue 4: admin_list_politicians return type conflict**
Existing function from migration 025 had incompatible return type (no `is_candidate`). Required `DROP FUNCTION IF EXISTS public.admin_list_politicians()` before recreation.

**Issue 5: Migration 016 RLS/grants not applied**
inform schema tables created by 026 had no RLS policies or grants. Migration 016 had been recorded as applied but its SQL never executed (tables didn't exist at the time). Re-applied RLS enable + policies + grants manually.

**Issue 6: PostgREST schema config stale**
`inform` schema exposed in Supabase dashboard but PostgREST still rejected requests with PGRST106. Dashboard change, project restart, and `NOTIFY pgrst, 'reload schema'` all failed to update PostgREST. Fixed by: `ALTER ROLE authenticator SET pgrst.db_schemas TO 'public,connect,empower,inform,graphql_public,validation_quests'; NOTIFY pgrst, 'reload schema';`

## Deployment Notes for Future Reference

- **Windows DNS**: The direct Supabase connection string (`db.<ref>.supabase.co:5432`) may not resolve from Windows/MINGW64. Use Supabase SQL Editor as fallback for migration application.
- **SQL Editor chunking**: For migrations with multiple DDL statements, run in logical chunks (schema creation, table creation, indexes, grants separately).
- **PostgREST schema exposure**: Do not rely on the Supabase dashboard UI alone. If schemas are not picked up after save + project restart, use `ALTER ROLE authenticator SET pgrst.db_schemas` directly.
- **Migration 016 dependency**: If inform tables are created outside of the normal migration flow, migration 016 (RLS + grants) must be manually re-applied.

---
*Phase: 17-live-alpha-deployment*
*Completed: 2026-03-10*
