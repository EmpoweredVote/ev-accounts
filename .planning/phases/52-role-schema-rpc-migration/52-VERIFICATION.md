---
phase: 52-role-schema-rpc-migration
verified: 2026-04-02T00:00:00Z
status: passed
score: 5/5 must-haves verified
---

# Phase 52 Verification

**Phase Goal:** `public.user_roles` carries full scope context and the three SQL functions that `roleService.ts` already calls (`grant_role`, `revoke_role`, `get_user_roles`) exist in the database — closing a pre-existing gap that causes a runtime error on any role operation today.

**Verified:** 2026-04-02
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Result: PASSED

## Must-Have Checks

| # | Check | Status | Notes |
|---|-------|--------|-------|
| 1 | `user_roles` scope columns + scope-inclusive index | ✓ | `feature_scope TEXT NOT NULL DEFAULT 'platform'`, `jurisdiction_geoid TEXT` nullable, `resource_id TEXT` nullable all present. `idx_user_roles_scope_active_unique` exists with `NULLS NOT DISTINCT`. Old `idx_user_roles_active_unique` is absent (dropped). |
| 2 | `role_audit_log` table + 4 indexes | ✓ | All 12 columns present including `actor_id`, `target_user_id`, `feature_scope`, `jurisdiction_geoid`, `resource_id`, `action`, `snapshot_after` (jsonb), `created_at`. Four non-PK indexes confirmed: `idx_role_audit_log_actor_id`, `idx_role_audit_log_target_user_id`, `idx_role_audit_log_feature_scope`, `idx_role_audit_log_created_at`. |
| 3 | `grant_role`, `revoke_role`, `get_user_roles` RPCs with `SET search_path = ''` | ✓ | All three functions exist with `proconfig = {"search_path=\"\""}`. Only the 5-param overloads of `grant_role` and `revoke_role` exist — old 2-param overloads were dropped. No ambiguity. |
| 4 | 5 role slugs seeded in `public.roles` | ✓ | `compass_stance_editor`, `campaign_manager`, `ctc_content_editor`, `essentials_data_editor`, `volunteer` all present with `required_tier = connected` and `is_active = true`. |
| 5 | `FEATURE_SCOPES` exported from `backend/src/lib/roles.ts` | ✓ | `export const FEATURE_SCOPES = ['platform', 'jurisdiction', 'resource'] as const` and `export type FeatureScope = typeof FEATURE_SCOPES[number]` both present. Comment documents the three-way sync requirement. |

## Score: 5/5 must-haves verified

---

## Observable Truth Verification

### Truth 1 — `user_roles` carries full scope context
VERIFIED. Three scope columns exist on `public.user_roles` in production:
- `feature_scope`: `TEXT NOT NULL DEFAULT 'platform'` with a `CHECK` constraint limiting values to `('platform', 'jurisdiction', 'resource')`
- `jurisdiction_geoid`: `TEXT`, nullable
- `resource_id`: `TEXT`, nullable

The old non-scope unique index (`idx_user_roles_active_unique`) is gone. The replacement (`idx_user_roles_scope_active_unique`) covers all five scope-defining columns with `NULLS NOT DISTINCT`, making jurisdiction/resource-scoped grants properly unique without treating NULLs as distinct.

### Truth 2 — Audit infrastructure exists for Phase 54
VERIFIED. `public.role_audit_log` exists with all 12 specified columns. The four required indexes are present. The table is ready to receive writes from the Phase 54 admin role management layer.

### Truth 3 — The three RPCs that `roleService.ts` calls are live and safe
VERIFIED. All three functions exist in production (`public` namespace). Each has `search_path = ''` set as a GUC-level configuration (confirmed via `pg_proc.proconfig`), meaning fully-qualified table references are enforced at the Postgres level — not just as a SQL comment. No old 2-param overloads exist that would create signature ambiguity.

### Truth 4 — Role slugs are seeded for downstream use
VERIFIED. All five slugs are active with `required_tier = connected`. Phase 53 (role service layer) and Phase 54 (admin UI) can reference these slugs immediately.

### Truth 5 — No three-way drift possible between TS, Zod, and DB
VERIFIED. `FEATURE_SCOPES` in `backend/src/lib/roles.ts` is the single source. The file comment explicitly documents that a new scope requires both editing the constant AND writing a migration to ALTER the CHECK constraint. `roleService.ts` return type for `getUserRoles` already includes `feature_scope`, `jurisdiction_geoid`, `resource_id`.

---

## Anti-Pattern Check

No stubs, TODOs, or placeholder patterns found in any of the three files touched by this phase:
- `backend/migrations/047_role_scope_migration.sql`: 209 lines, complete migration with 7 sections, COMMIT included
- `backend/src/lib/roles.ts`: 10 lines, pure constant + type export, no stubs
- `backend/src/lib/roleService.ts`: 149 lines, all three RPC callers have real implementations

---

## Phase Goal: Achieved

The pre-existing runtime gap is closed. Before this phase, calling `supabase.rpc('grant_role', ...)` would fail because the function did not exist in the DB. Now all three functions exist, are scope-aware, and are safe (`SET search_path = ''`). The schema is wired to support the v1.9 role management phases (53, 54, 55).

---

_Verified: 2026-04-02_
_Verifier: Claude (gsd-verifier)_
