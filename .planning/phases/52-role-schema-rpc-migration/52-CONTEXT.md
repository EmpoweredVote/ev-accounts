# Phase 52: Role Schema + RPC Migration - Context

**Gathered:** 2026-04-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Add scope columns to `public.user_roles`, create `public.role_audit_log`, replace the unique index with a scope-aware one, update the three SECURITY DEFINER RPCs (`grant_role`, `revoke_role`, `get_user_roles`) to handle scope, seed 5 role slugs in `public.roles`, and create the `FEATURE_SCOPES` constant in `backend/src/lib/roles.ts`.

`roleService.ts` TS call sites are NOT updated in this phase — that belongs to Phase 53's service layer work. This phase closes the DB gap only.

</domain>

<decisions>
## Implementation Decisions

### RPC scope params — optional with defaults

- `grant_role`, `revoke_role`, and `get_user_roles` accept new scope params as **optional** with defaults
- `p_feature_scope text DEFAULT 'platform'`, `p_jurisdiction_geoid text DEFAULT NULL`, `p_resource_id text DEFAULT NULL`
- Existing `roleService.ts` calls (`grant_role(p_user_id, p_role_slug)`) continue to work unmodified — no TS changes in Phase 52
- Phase 53 upgrades the TS service layer to pass scope values when it builds the full service layer

### Migration default for existing rows

- Existing `user_roles` rows get `feature_scope = 'platform'` via `ALTER TABLE ... SET DEFAULT` or explicit `UPDATE` before adding the NOT NULL constraint
- `'platform'` is the canonical value for platform-wide (non-jurisdiction, non-resource) grants
- This same value is used as the RPC `DEFAULT` for backward-compat calls

### `get_user_roles` return shape — extended now

- Updated to return full scope shape: `{ role_id, slug, name, granted_at, feature_scope, jurisdiction_geoid, resource_id }`
- RPC is being rewritten anyway — adding scope fields costs nothing and avoids a Phase 53 function-only migration
- The TS return type in `roleService.ts` will be updated to match (the only TS change in this phase)

### `FEATURE_SCOPES` single source of truth — hardcoded migration

- `backend/src/lib/roles.ts` exports a `FEATURE_SCOPES` const array (the canonical definition)
- Migration SQL hardcodes the same values in the `CHECK` constraint — no build-time coupling
- Adding a new scope in the future = edit TS constant + write a new migration. Discipline via code review, not automation.

### Claude's Discretion

- Unique index design for nullable scope columns (partial indexes, functional index, or COALESCE approach — researcher/planner to decide)
- Exact `role_audit_log` index names and column ordering
- Whether `FEATURE_SCOPES` is a `const` array or a `readonly` tuple
- `SET search_path = ''` placement and function body structure

</decisions>

<specifics>
## Specific Ideas

- The three RPCs already exist in `backend/migrations/025_rpc_pool_migration.sql` — Phase 52 replaces them with `CREATE OR REPLACE FUNCTION`, not net-new functions
- Current INSERT in `grant_role`: `INSERT INTO public.user_roles (user_id, role_id)` — must be updated to include `feature_scope` (and optionally scope columns) now that the column is NOT NULL
- Current unique index is `idx_user_roles_active_unique` on `(user_id, role_id) WHERE revoked_at IS NULL` — must be replaced with a scope-inclusive version

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 52-role-schema-rpc-migration*
*Context gathered: 2026-04-02*
