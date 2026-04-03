---
phase: 52-role-schema-rpc-migration
plan: 01
subsystem: database
tags: [postgres, supabase, rpc, roles, migrations]
requires:
  - phase: phase-51
    provides: XP source provisioning (prereq for v1.9)
provides:
  - scope columns on public.user_roles (feature_scope, jurisdiction_geoid, resource_id)
  - role_audit_log table with 4 indexes
  - grant_role/revoke_role/get_user_roles RPCs with scope support and SET search_path = ''
  - FEATURE_SCOPES TypeScript constant and FeatureScope type
  - roleService.ts getUserRoles return type with scope fields
affects: [53-role-service-layer, 54-admin-role-management, 55-compass-jurisdiction-roles]
tech-stack:
  added: []
  patterns: [NULLS NOT DISTINCT for nullable unique index, IS NOT DISTINCT FROM for NULL-safe WHERE, DROP FUNCTION before CREATE OR REPLACE when changing param signature]
key-files:
  created: [backend/migrations/047_role_scope_migration.sql, backend/src/lib/roles.ts]
  modified: [backend/src/lib/roleService.ts]
key-decisions:
  - "NULLS NOT DISTINCT on unique index — PG 15+ feature, correct for nullable scope columns (jurisdiction_geoid/resource_id)"
  - "IS NOT DISTINCT FROM in revoke_role WHERE clause — NULL-safe equality for nullable scope params"
  - "All 5 role slugs seeded as required_tier=connected"
  - "DROP old 2-param overloads explicitly — CREATE OR REPLACE cannot change param signature in Postgres"
patterns-established:
  - "Scope columns: feature_scope NOT NULL DEFAULT platform, jurisdiction_geoid/resource_id nullable"
  - "DROP FUNCTION IF EXISTS old_signature before CREATE OR REPLACE when adding optional params"
duration: 5min
completed: 2026-04-02
---

# Phase 52-01: Role Schema + RPC Migration Summary

**Scoped role infrastructure applied to production: scope columns on user_roles, role_audit_log, three RPCs upgraded to support platform/jurisdiction/resource scoping with SET search_path = '', and five role slugs seeded.**

## What Was Built

Migration 047 establishes the schema foundation for all v1.9 role management phases. The core change is that role grants now carry three scope fields — `feature_scope` (NOT NULL, default `platform`), `jurisdiction_geoid` (nullable), and `resource_id` (nullable) — enabling grants like "compass_stance_editor for jurisdiction 06037" distinct from a platform-wide editor grant.

### Task 1: Migration file + TypeScript artifacts
- `backend/migrations/047_role_scope_migration.sql` (166 lines): full migration with 7 sections
- `backend/src/lib/roles.ts`: `FEATURE_SCOPES` constant + `FeatureScope` type — single source of truth synced to DB CHECK constraint
- `backend/src/lib/roleService.ts`: `getUserRoles` return type extended with `feature_scope`, `jurisdiction_geoid`, `resource_id`

### Task 2: Applied to production (kxsdzaojfaibhuzmclfq)
- All verification queries passed
- Backward-compat smoke test passed (2-arg call raises ROLE_NOT_FOUND as expected)
- Scoped grant smoke test passed (TIER_INELIGIBLE for null-UUID user as expected)

## Verification Results

| Check | Result |
|---|---|
| feature_scope column NOT NULL, DEFAULT platform | Pass |
| jurisdiction_geoid nullable | Pass |
| resource_id nullable | Pass |
| idx_user_roles_scope_active_unique present | Pass |
| idx_user_roles_active_unique dropped | Pass |
| role_audit_log table with 12 columns | Pass |
| role_audit_log 4 indexes present | Pass |
| 5 role slugs seeded | Pass |
| Backward compat smoke test (2-arg call) | Pass |
| Scoped call smoke test | Pass |
| TypeScript noEmit | Pass |

## Decisions Made

| Decision | Rationale |
|---|---|
| NULLS NOT DISTINCT on unique index | PG 15+ feature — correct handling for nullable scope columns; two NULL jurisdiction_geoIds are treated as equal for uniqueness purposes |
| IS NOT DISTINCT FROM in revoke_role WHERE | NULL-safe equality; `ur.jurisdiction_geoid = NULL` would never match, dropping rows on scope-specific revocation |
| All 5 slugs as required_tier=connected | Standard entry tier for Alpha; empowered tier reserved for future elevated roles |
| DROP old overloads before CREATE OR REPLACE | Postgres cannot change a function's param count via CREATE OR REPLACE — it creates a new overload; old unsecured 2-param versions must be dropped explicitly |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Old 2-param grant_role/revoke_role overloads not replaced**

- **Found during:** Task 2 verification
- **Issue:** `CREATE OR REPLACE FUNCTION` with new param signature creates a new overload rather than replacing the old one. Post-migration, `public.grant_role(uuid, text)` (old, no search_path) and `public.grant_role(uuid, text, text, text, text)` (new) coexisted. 2-arg calls raised "function is not unique" ambiguity error.
- **Fix:** Added `DROP FUNCTION IF EXISTS public.grant_role(uuid, text)` and `DROP FUNCTION IF EXISTS public.revoke_role(uuid, text)` before the CREATE OR REPLACE blocks in the migration file. Applied the drops to production via a one-shot script.
- **Files modified:** `backend/migrations/047_role_scope_migration.sql`
- **Commits:** 979353c

## Next Phase Readiness

Phase 52 Plan 01 is the hard gate for all v1.9 phases. The following are now unblocked:

- **Phase 53** (role service layer): `getUserRoles` return type updated; scope fields available in TypeScript
- **Phase 54** (admin role management): `grant_role` accepts scope params; `role_audit_log` table exists for audit writes
- **Phase 55** (compass jurisdiction roles): jurisdiction-scoped grants fully supported by DB schema and RPCs
