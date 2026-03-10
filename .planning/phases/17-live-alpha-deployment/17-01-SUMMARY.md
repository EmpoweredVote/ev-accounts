---
phase: 17-live-alpha-deployment
plan: 01
subsystem: infra
tags: [postgres, pg, migrations, supabase, deploy, render, dotenv]

requires:
  - phase: 16-compass-admin
    provides: "Migrations 026-029 (inform schema repair, candidates, admin RPCs) exist in backend/migrations/"

provides:
  - Migration apply script (backend/scripts/applyMigrations.ts) — idempotent, pre/post verified, exits 1 on failure
  - Deployment runbook (DEPLOY.md) — six-step cold-start reference covering extensions, migrations, backend, admin UI, smoke tests, housekeeping
  - Rollback SQL for all four migrations documented

affects:
  - 17-02-live-alpha-deployment (smoke test plan references DEPLOY.md and applyMigrations.ts)
  - 18-compass-api-compat (depends on 026-029 being applied to production)
  - 19-location-infrastructure (PostGIS/pgcrypto extension steps documented in DEPLOY.md)

tech-stack:
  added: []
  patterns:
    - "Migration apply script uses pg.Pool with direct DATABASE_URL, pre-verify (skip if applied) and post-verify (exit 1 if failed)"
    - "DEPLOY.md is the single canonical reference — no other file needed for a cold-start deploy"

key-files:
  created:
    - backend/scripts/applyMigrations.ts
    - DEPLOY.md
  modified: []

key-decisions:
  - "Direct connection only for migrations: DATABASE_URL must use db.<ref>.supabase.co:5432, never the pooler (pooler.supabase.com:6543) — multi-statement SQL fails on pooler"
  - "Idempotent pre-verify pattern: script checks if migration is already applied before executing, safe to re-run"
  - "PostGIS and pgcrypto enabled in Step 1 even though not needed until Phase 19 — avoids a second deploy window"

patterns-established:
  - "Migration scripts: pre-verify (0 rows = not applied, skip if 1 row), apply, post-verify (1 row = success, exit 1 if 0 rows)"
  - "pool.end() in finally block — always releases connection regardless of error path"

duration: 12min
completed: 2026-03-09
---

# Phase 17 Plan 01: Migration Apply Script and Deployment Runbook Summary

**pg.Pool-based migration apply script with idempotent pre/post verification for migrations 026-029, plus a six-step cold-start deployment runbook covering extensions, apply commands, rollback SQL, and TypeScript type regeneration**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-03-10T02:20:00Z
- **Completed:** 2026-03-10T02:32:06Z
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Migration apply script connects via DATABASE_URL (direct connection only), checks pre-state before each migration, applies in order 026-029, post-verifies success, exits 1 on any failure
- Deployment runbook covers every step from zero to live Alpha: extension enablement, migration apply (script + psql fallback), backend deploy, admin UI build, smoke tests, TypeScript type regeneration
- Rollback SQL documented for all four migrations with explicit warning that 026 column drops are irreversible

## Task Commits

1. **Task 1: Migration apply script** - `dabfca9` (feat)
2. **Task 2: Deployment runbook** - `cebee29` (docs)

## Files Created/Modified

- `backend/scripts/applyMigrations.ts` — Standalone tsx script: loads .env, reads DATABASE_URL, applies 026-029 in order with pre/post verification, exits 1 on failure
- `DEPLOY.md` — Six-step deployment runbook with environment variables table, extension enablement SQL, migration apply commands, post-verification queries, rollback SQL, and common pitfalls

## Decisions Made

- **Direct connection only:** The `DATABASE_URL` must use `db.<ref>.supabase.co:5432`. The pooler (`pooler.supabase.com:6543`) does not support multi-statement transactions and migration files will fail on it. This is called out in both the script header and DEPLOY.md Step 2.
- **Idempotent script design:** Pre-verify queries check if the migration artifact already exists (column or function). If it does, the migration is skipped with a `SKIP — already applied` log. Safe to re-run on a database that already has some migrations applied.
- **PostGIS/pgcrypto in Step 1 now:** Both extensions are documented as enabled at deploy time even though Phase 19 needs them. Avoids a separate deploy window when Phase 19 ships.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

**Migration execution requires manual action.** The script and runbook are the tooling — the actual `DATABASE_URL` and Supabase credentials must be supplied by the operator. See `DEPLOY.md` for the full checklist.

## Next Phase Readiness

- `DEPLOY.md` and `backend/scripts/applyMigrations.ts` are ready — migrations 026-029 can be applied to production at any time using the documented commands
- Phase 17 Plan 02 (smoke tests) references `backend/scripts/smokeTest.ts` — that file still needs to be created
- Before announcing Alpha access: run smoke tests per DEPLOY.md Step 5

---
*Phase: 17-live-alpha-deployment*
*Completed: 2026-03-09*
