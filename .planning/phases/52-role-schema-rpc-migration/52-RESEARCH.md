# Phase 52: Role Schema + RPC Migration - Research

**Researched:** 2026-04-02
**Domain:** PostgreSQL schema migration, SECURITY DEFINER RPCs, TypeScript const types
**Confidence:** HIGH

## Summary

Phase 52 is a pure database and TypeScript-constant phase. The work is contained: alter `public.user_roles` to add three scope columns, create `public.role_audit_log`, replace a unique index, rewrite three RPCs with scope parameters (backward-compat defaults), seed five role slugs, and export `FEATURE_SCOPES` from `backend/src/lib/roles.ts`.

The three RPCs (`grant_role`, `revoke_role`, `get_user_roles`) already exist in the DB via `migration 025`. Phase 52 replaces them with `CREATE OR REPLACE FUNCTION` — not net-new functions. The critical constraint is that existing `roleService.ts` call sites must continue to work unmodified because scope params use `DEFAULT` values. The only TypeScript change in this phase is updating the return type of `getUserRoles` to include the three new scope fields.

The primary technical discretion item — how to handle nullable columns in the unique index — is resolved by using `NULLS NOT DISTINCT` (available since PostgreSQL 15, which Supabase runs). This is cleaner than COALESCE sentinel-value approaches and does not require partial index tricks.

**Primary recommendation:** Use a single `CREATE UNIQUE INDEX ... NULLS NOT DISTINCT` on `(user_id, role_id, feature_scope, jurisdiction_geoid, resource_id) WHERE revoked_at IS NULL` to replace the existing index cleanly.

## Standard Stack

No new libraries. This phase uses the existing project stack only.

### Core (already in place)
| Tool | Version | Purpose | Why Used |
|------|---------|---------|----------|
| PostgreSQL | 15+ (Supabase) | DB engine | Project standard |
| `pg` (Pool) | existing | Migrations applied via direct connection | Required for multi-statement migrations |
| `tsx` / `npx tsx` | existing | Run migration scripts | Project standard |
| TypeScript strict | existing | `FEATURE_SCOPES` constant typing | Project standard |

### Supporting
| Tool | Purpose |
|------|---------|
| Supabase MCP (`execute_sql`) | Verify schema state post-migration |
| `information_schema` / `pg_proc` | Pre/post migration verification queries |

**No new npm installs required.**

## Architecture Patterns

### Project Migration Pattern
```
backend/migrations/047_role_scope_migration.sql   ← new file (next sequential number)
backend/src/lib/roles.ts                          ← new file (FEATURE_SCOPES export)
backend/src/lib/roleService.ts                    ← minor edit (return type only)
```

The migration script is executed via `DATABASE_URL` direct connection (port 5432, not pooler). This is the established pattern for all migrations 026+. The script is idempotent via `IF NOT EXISTS` / `IF EXISTS` guards and `CREATE OR REPLACE FUNCTION`.

### Pattern 1: ALTER TABLE + Backfill + NOT NULL

The established pattern for adding a NOT NULL column to an existing table with rows:

```sql
-- Step 1: add the column as nullable first
ALTER TABLE public.user_roles
  ADD COLUMN IF NOT EXISTS feature_scope TEXT;

-- Step 2: backfill existing rows
UPDATE public.user_roles
  SET feature_scope = 'platform'
  WHERE feature_scope IS NULL;

-- Step 3: apply NOT NULL constraint + default
ALTER TABLE public.user_roles
  ALTER COLUMN feature_scope SET NOT NULL,
  ALTER COLUMN feature_scope SET DEFAULT 'platform';
```

Doing it in a single `ADD COLUMN ... NOT NULL DEFAULT 'platform'` would also work in PostgreSQL (the DB sets the default before applying NOT NULL), but the explicit UPDATE pattern is safer for documentation clarity and matches the project's audit-friendly style.

### Pattern 2: Unique Index with Nullable Columns — NULLS NOT DISTINCT

This is the "Claude's Discretion" item. The current index is:
```sql
idx_user_roles_active_unique ON public.user_roles (user_id, role_id) WHERE revoked_at IS NULL
```

After adding scope columns (`feature_scope NOT NULL`, `jurisdiction_geoid TEXT`, `resource_id TEXT`), the new index must prevent duplicate active grants for the same (user, role, scope). Two of the three scope columns are nullable.

**Recommended approach: `NULLS NOT DISTINCT`**

```sql
DROP INDEX IF EXISTS idx_user_roles_active_unique;

CREATE UNIQUE INDEX idx_user_roles_scope_active_unique
  ON public.user_roles (user_id, role_id, feature_scope, jurisdiction_geoid, resource_id)
  NULLS NOT DISTINCT
  WHERE revoked_at IS NULL;
```

`NULLS NOT DISTINCT` (PostgreSQL 15+) treats NULL as equal to NULL in the uniqueness check. This is exactly what we want: `(user_id, role_id, 'platform', NULL, NULL)` should conflict with another `(user_id, role_id, 'platform', NULL, NULL)`. Without `NULLS NOT DISTINCT`, two rows with NULL jurisdiction would not conflict — which would be wrong.

**Why not COALESCE:** Using `COALESCE(jurisdiction_geoid, '')` requires embedding a sentinel in the index expression and training all future developers on that pattern. It's error-prone. `NULLS NOT DISTINCT` is the correct PostgreSQL 15 solution.

**Why not two partial indexes:** Would require one index for `WHERE jurisdiction_geoid IS NULL AND resource_id IS NULL` and additional indexes for each combination. Fragile and hard to maintain.

### Pattern 3: SECURITY DEFINER Function Structure

Established project convention (from migrations 027, 029, 034, 035, 036, 046):

```sql
CREATE OR REPLACE FUNCTION public.grant_role(
  p_user_id         uuid,
  p_role_slug       text,
  p_feature_scope   text DEFAULT 'platform',
  p_jurisdiction_geoid text DEFAULT NULL,
  p_resource_id     text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  ...
BEGIN
  ...
  -- All table references fully qualified: public.user_roles, connect.connected_profiles, etc.
END;
$$;
```

Key rules from project codebase:
- `SET search_path = ''` goes between `SECURITY DEFINER` and `AS $$` (not inside the function body)
- All table references must be schema-qualified: `public.user_roles`, `public.roles`, `connect.connected_profiles`, `empower.empowered_profiles`
- `extensions.pgcrypto` stays as `extensions.*`, `public.ST_*` for PostGIS — but this RPC doesn't touch either

### Pattern 4: `revoke_role` Scope-Aware WHERE Clause

The current `revoke_role` matches on `user_id + slug + revoked_at IS NULL`. With scope, it must also match on all three scope columns. The WHERE clause must handle nullable columns correctly:

```sql
UPDATE public.user_roles ur
SET revoked_at = now()
FROM public.roles r
WHERE ur.role_id = r.id
  AND ur.user_id = p_user_id
  AND r.slug = p_role_slug
  AND ur.revoked_at IS NULL
  AND ur.feature_scope = p_feature_scope
  AND (ur.jurisdiction_geoid IS NOT DISTINCT FROM p_jurisdiction_geoid)
  AND (ur.resource_id IS NOT DISTINCT FROM p_resource_id);
```

`IS NOT DISTINCT FROM` handles NULL = NULL as true, which is required for nullable scope columns. Using `=` would fail to match rows where both sides are NULL.

### Pattern 5: `FEATURE_SCOPES` TypeScript Constant

The decision: `const` array vs `readonly` tuple. Recommendation: use `as const` on an array literal, which produces a `readonly` tuple automatically.

```typescript
// backend/src/lib/roles.ts

/**
 * FEATURE_SCOPES — canonical list of role scope values.
 *
 * This is the single source of truth. The DB CHECK constraint in migration 047
 * hardcodes the same values. Adding a new scope = edit this array + write a new
 * migration with an updated CHECK constraint. Code review enforces the coupling.
 */
export const FEATURE_SCOPES = [
  'platform',
  'jurisdiction',
  'resource',
] as const;

export type FeatureScope = typeof FEATURE_SCOPES[number];
// → 'platform' | 'jurisdiction' | 'resource'
```

Using `as const` on the array gives TypeScript a `readonly ['platform', 'jurisdiction', 'resource']` tuple. `typeof FEATURE_SCOPES[number]` derives the union type. This is the standard pattern for deriving Zod enums from a const array:

```typescript
import { z } from 'zod';
export const featureScopeSchema = z.enum(FEATURE_SCOPES);
```

### Pattern 6: `role_audit_log` Table Structure

Following established audit log patterns in the codebase (`connect.tier_promotion_log` from migration 035):

```sql
CREATE TABLE IF NOT EXISTS public.role_audit_log (
  id                   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id             UUID        NOT NULL REFERENCES public.users(id),
  target_user_id       UUID        NOT NULL REFERENCES public.users(id),
  feature_scope        TEXT,
  jurisdiction_geoid   TEXT,
  resource_id          TEXT,
  action               TEXT        NOT NULL,
  target_type          TEXT        NOT NULL,
  target_id            TEXT        NOT NULL,
  fields_changed       TEXT[],
  snapshot_after       JSONB,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

Index strategy (covering the four required indexes):
```sql
CREATE INDEX IF NOT EXISTS idx_role_audit_log_actor_id       ON public.role_audit_log(actor_id);
CREATE INDEX IF NOT EXISTS idx_role_audit_log_target_user_id ON public.role_audit_log(target_user_id);
CREATE INDEX IF NOT EXISTS idx_role_audit_log_feature_scope  ON public.role_audit_log(feature_scope);
CREATE INDEX IF NOT EXISTS idx_role_audit_log_created_at     ON public.role_audit_log(created_at DESC);
```

Note: ROLE-02 specifies indexes on `actor_id`, `feature_scope`, `created_at`. The success criteria also mentions `target_user_id`. Include all four.

`created_at DESC` ordering on the index matches the primary query pattern (recent first).

### Pattern 7: Role Seeding

The five role slugs are seeded via `INSERT ... ON CONFLICT DO NOTHING`:

```sql
INSERT INTO public.roles (name, slug, required_tier, is_active)
VALUES
  ('Compass Stance Editor',  'compass_stance_editor',  'connected', true),
  ('Campaign Manager',       'campaign_manager',        'connected', true),
  ('CTC Content Editor',     'ctc_content_editor',      'connected', true),
  ('Essentials Data Editor', 'essentials_data_editor',  'connected', true),
  ('Volunteer',              'volunteer',               'connected', true)
ON CONFLICT (slug) DO NOTHING;
```

The `ON CONFLICT (slug) DO NOTHING` pattern assumes a unique constraint on `slug` in `public.roles` — verify this exists in the DB before running. If the constraint is only via the partial unique index (not a declared UNIQUE constraint on the column), use `ON CONFLICT DO NOTHING` without the column specifier, or wrap in a DO block.

### Anti-Patterns to Avoid

- **Do not use `=` to compare nullable scope columns in WHERE clauses** — use `IS NOT DISTINCT FROM`. This is the correct SQL operator for NULL-safe equality.
- **Do not add `SET search_path = ''` inside the `AS $$ ... $$` block** — it goes in the function header between `SECURITY DEFINER` and `AS $$`. Placing it inside the body has no effect.
- **Do not omit the schema prefix on table references** inside SECURITY DEFINER functions with `SET search_path = ''` — the empty search path means unqualified names fail to resolve.
- **Do not use `supabaseAdmin.schema('public').from().update()`** for the migration — use `pool.query()` with the direct connection string (port 5432).
- **Do not wrap the migration in `BEGIN; ... COMMIT;`** unless the migration runner handles it — the `pool.query()` approach in this codebase runs the full SQL as-is. Check whether the migration SQL itself should include transaction control. Looking at migration 035 — it starts with `BEGIN;`. Check if 046 does too.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| NULL-safe unique enforcement | Sentinel COALESCE values | `NULLS NOT DISTINCT` (PG 15+) | Cleaner, standard, no sentinel magic |
| NULL-safe equality in WHERE | `= NULL` (wrong) | `IS NOT DISTINCT FROM` | `= NULL` always returns NULL (not true) |
| TypeScript union from array | Manual string union type | `typeof FEATURE_SCOPES[number]` | Stays in sync automatically |
| Zod enum from const | Manual z.enum(['a','b','c']) | `z.enum(FEATURE_SCOPES)` | Single source of truth |

**Key insight:** The nullable scope columns create two NULL-handling traps that trip developers: (1) the unique index allows multiple NULLs by default — fix with `NULLS NOT DISTINCT`, and (2) WHERE clauses using `=` against nullable columns silently fail to match NULL rows — fix with `IS NOT DISTINCT FROM`.

## Common Pitfalls

### Pitfall 1: Missing `SET search_path = ''` on Replaced RPCs

**What goes wrong:** Migration 025 created `grant_role`, `revoke_role`, `get_user_roles` without `SET search_path = ''`. The `CREATE OR REPLACE` in Phase 52 must add it. If omitted, the functions remain vulnerable to search_path injection, and future security audits will flag them.

**Why it happens:** `CREATE OR REPLACE` merges the new definition; it doesn't inherit properties from the old version. The new function signature must declare `SET search_path = ''` explicitly.

**How to avoid:** Always include `SET search_path = ''` in the function header for every SECURITY DEFINER function. This is the project convention established in migrations 027+.

### Pitfall 2: `grant_role` INSERT Missing `feature_scope`

**What goes wrong:** The current INSERT is `INSERT INTO public.user_roles (user_id, role_id) VALUES (...)`. After adding `feature_scope TEXT NOT NULL`, this INSERT will fail with a NOT NULL constraint violation at runtime.

**Why it happens:** The column is NOT NULL and has no server-side default at the row level (the DEFAULT is defined for DDL purposes during backfill, but the INSERT must explicitly provide a value).

**How to avoid:** The new INSERT must be `INSERT INTO public.user_roles (user_id, role_id, feature_scope, jurisdiction_geoid, resource_id) VALUES (p_user_id, v_role_id, p_feature_scope, p_jurisdiction_geoid, p_resource_id)`.

### Pitfall 3: `revoke_role` Not Scoped — Revokes Wrong Grant

**What goes wrong:** Without scope filtering, `revoke_role('user-id', 'compass_stance_editor')` revokes the first active grant it finds regardless of scope. A user could hold the same role in different jurisdictions, and an unscoped revoke would affect the wrong one.

**Why it happens:** The current implementation does a blind UPDATE on (user_id, role_slug, revoked_at IS NULL). With scope columns, this must be narrowed.

**How to avoid:** Add `AND ur.feature_scope = p_feature_scope AND (ur.jurisdiction_geoid IS NOT DISTINCT FROM p_jurisdiction_geoid) AND (ur.resource_id IS NOT DISTINCT FROM p_resource_id)` to the WHERE clause.

### Pitfall 4: Index Replacement Order — Runtime Error Window

**What goes wrong:** If you `DROP INDEX` before the `CREATE UNIQUE INDEX`, there is a window where duplicate inserts could succeed (the partial unique enforcement is gone).

**Why it happens:** Standard index replacement. In high-concurrency environments this matters.

**How to avoid:** In a migration script run via `pool.query()`, the entire SQL runs sequentially in the same transaction (if wrapped in `BEGIN/COMMIT`). Create the new index first with `IF NOT EXISTS`, then drop the old one. Or use a transaction to make the drop+create atomic.

### Pitfall 5: `ON CONFLICT (slug)` — Requires Declared UNIQUE Constraint

**What goes wrong:** `INSERT INTO public.roles ... ON CONFLICT (slug) DO NOTHING` requires that `slug` has a declared UNIQUE constraint (not just a unique index). If the uniqueness is enforced only via a partial index or unnamed index, the `ON CONFLICT` target specification fails.

**Why it happens:** PostgreSQL requires the conflict target in `ON CONFLICT (col)` to match a unique constraint or unique index exactly. A partial index won't match unless the `ON CONFLICT` clause also specifies the WHERE predicate.

**How to avoid:** Use `INSERT INTO public.roles ... ON CONFLICT DO NOTHING` (omit the column target) if you're uncertain whether a declared UNIQUE constraint on `slug` exists. Or verify via `information_schema.table_constraints`.

### Pitfall 6: Migration Number Collision

**What goes wrong:** The last migration is 046. Phase 52 needs to write migration 047. If another developer has already used 047 for something else, there's a collision.

**Why it happens:** Sequential migration naming without a registry.

**How to avoid:** Check `ls backend/migrations/` before picking the number. As of research date, 047 is available.

## Code Examples

### grant_role — Full Updated Signature
```sql
-- Source: Derived from migration 025 pattern + project conventions from 027-046
CREATE OR REPLACE FUNCTION public.grant_role(
  p_user_id             uuid,
  p_role_slug           text,
  p_feature_scope       text DEFAULT 'platform',
  p_jurisdiction_geoid  text DEFAULT NULL,
  p_resource_id         text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_role_id             uuid;
  v_role_required_tier  text;
  v_role_is_active      bool;
BEGIN
  -- 1. Fetch role by slug
  SELECT id, required_tier, is_active
  INTO v_role_id, v_role_required_tier, v_role_is_active
  FROM public.roles
  WHERE slug = p_role_slug;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ROLE_NOT_FOUND';
  END IF;

  IF NOT v_role_is_active THEN
    RAISE EXCEPTION 'ROLE_INACTIVE';
  END IF;

  -- 2. Tier eligibility (unchanged from migration 025)
  IF v_role_required_tier = 'empowered' THEN
    IF NOT EXISTS (
      SELECT 1 FROM empower.empowered_profiles
      WHERE user_id = p_user_id AND is_active = true
    ) THEN
      RAISE EXCEPTION 'TIER_INELIGIBLE';
    END IF;
  ELSIF v_role_required_tier = 'connected' THEN
    IF NOT EXISTS (
      SELECT 1 FROM connect.connected_profiles
      WHERE user_id = p_user_id AND verification_status = 'verified'
    ) THEN
      RAISE EXCEPTION 'TIER_INELIGIBLE';
    END IF;
  END IF;

  -- 3. CIVIC-04 conflict check (empty for Alpha)

  -- 4. INSERT with scope columns
  BEGIN
    INSERT INTO public.user_roles (user_id, role_id, feature_scope, jurisdiction_geoid, resource_id)
    VALUES (p_user_id, v_role_id, p_feature_scope, p_jurisdiction_geoid, p_resource_id);
  EXCEPTION WHEN unique_violation THEN
    RAISE EXCEPTION 'ROLE_ALREADY_GRANTED';
  END;
END;
$$;
```

### revoke_role — Scope-Aware WHERE
```sql
-- Source: Derived from migration 025 + IS NOT DISTINCT FROM pattern for nullable cols
CREATE OR REPLACE FUNCTION public.revoke_role(
  p_user_id             uuid,
  p_role_slug           text,
  p_feature_scope       text DEFAULT 'platform',
  p_jurisdiction_geoid  text DEFAULT NULL,
  p_resource_id         text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE public.user_roles ur
  SET revoked_at = now()
  FROM public.roles r
  WHERE ur.role_id = r.id
    AND ur.user_id = p_user_id
    AND r.slug = p_role_slug
    AND ur.revoked_at IS NULL
    AND ur.feature_scope = p_feature_scope
    AND (ur.jurisdiction_geoid IS NOT DISTINCT FROM p_jurisdiction_geoid)
    AND (ur.resource_id IS NOT DISTINCT FROM p_resource_id);
END;
$$;
```

### get_user_roles — Extended Return Shape
```sql
-- Source: Derived from migration 025 + extended SELECT list per CONTEXT.md decision
CREATE OR REPLACE FUNCTION public.get_user_roles(
  p_user_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_result jsonb;
BEGIN
  SELECT jsonb_agg(row_to_json(t))
  INTO v_result
  FROM (
    SELECT
      ur.role_id,
      r.slug,
      r.name,
      ur.granted_at,
      ur.feature_scope,
      ur.jurisdiction_geoid,
      ur.resource_id
    FROM public.user_roles ur
    JOIN public.roles r ON r.id = ur.role_id
    WHERE ur.user_id = p_user_id AND ur.revoked_at IS NULL
    ORDER BY ur.granted_at DESC
  ) t;

  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;
```

### Unique Index Replacement
```sql
-- Source: PostgreSQL 15 docs — NULLS NOT DISTINCT (https://www.postgresql.org/docs/current/indexes-unique.html)
-- Step 1: create new index
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_roles_scope_active_unique
  ON public.user_roles (user_id, role_id, feature_scope, jurisdiction_geoid, resource_id)
  NULLS NOT DISTINCT
  WHERE revoked_at IS NULL;

-- Step 2: drop old index
DROP INDEX IF EXISTS idx_user_roles_active_unique;
```

### TypeScript FEATURE_SCOPES
```typescript
// backend/src/lib/roles.ts
// Source: TypeScript handbook — const assertions

/**
 * FEATURE_SCOPES — canonical list of role scope values.
 *
 * The DB CHECK constraint in migration 047 hardcodes the same values.
 * Adding a new scope: edit this array + write a migration with updated CHECK.
 * Code review enforces the coupling.
 */
export const FEATURE_SCOPES = [
  'platform',
  'jurisdiction',
  'resource',
] as const;

export type FeatureScope = typeof FEATURE_SCOPES[number];
// Produces: 'platform' | 'jurisdiction' | 'resource'
```

### roleService.ts Return Type Update (only TS change in Phase 52)
```typescript
// backend/src/lib/roleService.ts — getUserRoles return type change only
export async function getUserRoles(
  userId: string
): Promise<Array<{
  role_id: string;
  slug: string;
  name: string;
  granted_at: string;
  feature_scope: string;
  jurisdiction_geoid: string | null;
  resource_id: string | null;
}>> {
  // ... implementation unchanged
}
```

### CHECK Constraint for feature_scope column
```sql
ALTER TABLE public.user_roles
  ADD CONSTRAINT user_roles_feature_scope_check
  CHECK (feature_scope IN ('platform', 'jurisdiction', 'resource'));
```

Note: Add this constraint AFTER setting `feature_scope = 'platform'` on existing rows and AFTER adding the NOT NULL constraint. The CHECK constraint must be added to the column definition or as a separate ALTER TABLE.

## State of the Art

| Old Approach | Current Approach | Notes |
|--------------|-----------------|-------|
| COALESCE sentinel in unique index | `NULLS NOT DISTINCT` (PG 15+) | Cleaner, no sentinel magic |
| `= NULL` in WHERE clause | `IS NOT DISTINCT FROM` | NULL-safe equality |
| `SET search_path` inside function body | `SET search_path = ''` in header | Correct placement per PG docs |
| RPCs without search_path (migration 025) | All new RPCs include it | Migration 025 omitted it; 027+ added it |

## Open Questions

1. **Does `public.roles` have a declared UNIQUE constraint on `slug` (not just an index)?**
   - What we know: There is a unique index enforcing slug uniqueness (implied by the partial unique index pattern and no conflicts in existing data).
   - What's unclear: Whether it's a formal `CONSTRAINT ... UNIQUE` or just a `CREATE UNIQUE INDEX`. This affects which `ON CONFLICT` syntax to use for seeding.
   - Recommendation: Use `ON CONFLICT DO NOTHING` (without column target) as the safe default. If the planner wants the column-specific form, verify via `SELECT constraint_name FROM information_schema.table_constraints WHERE table_name='roles' AND constraint_type='UNIQUE'` before planning.

2. **Does the migration file need `BEGIN; ... COMMIT;` wrapping?**
   - What we know: Migration 035 starts with `BEGIN;`. Migration 046 does not (it uses `CREATE OR REPLACE FUNCTION` only — inherently idempotent DDL).
   - What's unclear: Whether the `pool.query()` migration runner in `applyMigrations.ts` auto-wraps in a transaction.
   - Recommendation: Include `BEGIN; ... COMMIT;` in the migration file since the migration modifies table structure (DDL) and data (UPDATE for backfill). Postgres DDL is transactional, so if the backfill or index creation fails, the whole migration rolls back cleanly. Match the migration 035 pattern.

3. **What `required_tier` value to seed for the five new roles?**
   - What we know: The success criteria doesn't specify tier. The staging route uses `volunteer`, and the roles are for feature-specific editors.
   - What's unclear: Whether all five should be `'connected'`, `'empowered'`, or mixed.
   - Recommendation: Default to `'connected'` for all five. This is the minimum privileged tier that can hold roles (per `roleService.ts` comment: "Only Connected+ users can hold roles"). Phase 53 can update specific roles to `'empowered'` if needed.

## Sources

### Primary (HIGH confidence)
- Codebase read: `backend/migrations/025_rpc_pool_migration.sql` — current `grant_role`, `revoke_role`, `get_user_roles` implementation
- Codebase read: `backend/src/lib/roleService.ts` — existing TS call sites and return types
- Codebase read: `backend/migrations/029_compass_admin_rpcs.sql` — `SET search_path = ''` placement pattern
- Codebase read: `backend/migrations/035_tier_promotion.sql` — audit log table pattern (`connect.tier_promotion_log`)
- Codebase read: `backend/src/lib/supabase.ts` — `adminRpc` function signature
- PostgreSQL 18 official docs: https://www.postgresql.org/docs/current/indexes-unique.html — `NULLS NOT DISTINCT`

### Secondary (MEDIUM confidence)
- WebSearch + pganalyze blog: `NULLS NOT DISTINCT` introduced in PostgreSQL 15 — confirmed by multiple sources including pg 15 release notes reference
- Supabase uses PostgreSQL 15+ — confirmed by Supabase docs (new projects on PG 15, 17, or OrioleDB-17)

### Tertiary (LOW confidence)
- Specific `required_tier` values for the five seeded roles — not specified in requirements; recommendation based on project conventions

## Metadata

**Confidence breakdown:**
- Schema migration pattern: HIGH — read directly from existing migrations 025, 029, 035
- NULLS NOT DISTINCT approach: HIGH — verified against official PostgreSQL docs and confirmed PG 15+ availability on Supabase
- IS NOT DISTINCT FROM for nullable equality: HIGH — standard SQL, project would break without it
- FEATURE_SCOPES const pattern: HIGH — standard TypeScript `as const` pattern
- role_audit_log structure: HIGH — matches ROLE-02 requirements exactly; index names are Claude's discretion
- Seeded role `required_tier` values: LOW — not specified in requirements, inferred from project patterns

**Research date:** 2026-04-02
**Valid until:** 2026-05-02 (stable PostgreSQL patterns; no fast-moving dependencies)
