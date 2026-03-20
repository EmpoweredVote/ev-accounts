# Phase 34: Database Schema Migration - Research

**Researched:** 2026-03-19
**Domain:** PostgreSQL RLS policy authoring for Go-originated schemas in Supabase
**Confidence:** HIGH

---

## Summary

Phase 34's actual scope differs from the roadmap description. The PLATFORM-CONSOLIDATION.md describes moving tables from EV-Backend into ev-accounts, but reality is that all schemas (`essentials`, `meetings`, `staging`, `treasury`, `transparent_motivations`, `compass`) are already in the same Supabase project (`kxsdzaojfaibhuzmclfq`). Both the ev-accounts Express server and the Go backend point at this same database.

**What Phase 34 actually needs to do:** Enable RLS on 57 tables across 6 schemas that currently have `rowsecurity: false`. The Go backend never used RLS; these tables are completely unprotected at the database layer. RLS must be in place before any of these schemas are served by the ev-accounts API (Phase 36+).

The ev-accounts codebase has a rich migration history with established, consistent RLS patterns across 46 existing migrations. Phase 34 follows those exact patterns — no new techniques needed.

**Primary recommendation:** Write one migration file per schema (6 files total), following the `inform_rls_grants.sql` pattern exactly: enable RLS, add public-read or restricted-read policies, add GRANT USAGE + GRANT SELECT. Admin writes stay service-role-only (no INSERT/UPDATE/DELETE policies for non-service-role).

---

## Standard Stack

Phase 34 is pure SQL — no new libraries needed.

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| PostgreSQL RLS | Postgres 17 | Row-level access control | Native DB feature; established in all ev-accounts schemas |
| Supabase MCP | Production | Apply migrations | `mcp__supabase-local__apply_migration` hits production directly per reference doc |
| Supabase CLI | Existing | Migration file management | All 46 prior migrations use timestamped files in `supabase/migrations/` |

### Supporting
No additional dependencies. All patterns exist in the current migration set.

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Per-schema migration files | One monolithic migration | Single file is harder to review, harder to roll back one schema; per-schema is the ev-accounts pattern |
| `auth.jwt() ->> 'role'` for admin check | `public.users.is_admin` | Neither pattern appears in the existing RLS migrations — existing admin writes go through service role only (no INSERT/UPDATE/DELETE policies at all). Service role bypasses RLS entirely. |

**Installation:** No new packages.

---

## Architecture Patterns

### Existing RLS Pattern (HIGH confidence — verified in migrations 007–022, 031)

The ev-accounts codebase uses a **consistent 3-layer RLS pattern**:

1. `ALTER TABLE schema.table ENABLE ROW LEVEL SECURITY;`
2. `CREATE POLICY "name: description" ON schema.table FOR SELECT TO [roles] USING ([condition]);`
3. `GRANT USAGE ON SCHEMA schema TO anon, authenticated;` + `GRANT SELECT ON ALL TABLES IN SCHEMA schema TO anon, authenticated;`

**Admin write pattern:** There are NO `INSERT`/`UPDATE`/`DELETE` policies for non-service-role on any table in ev-accounts. All admin writes go through either:
- Service role (pg pool, bypasses RLS) — used for all non-public schema writes per the critical production pattern in MEMORY.md
- `SECURITY DEFINER` RPCs with `SET search_path = ''` — used for atomic multi-table operations

This means "admin write" for Phase 34 = **no INSERT/UPDATE/DELETE policy needed**. Service role already bypasses RLS entirely. Do not add admin write policies.

### Policy Naming Convention (HIGH confidence — observed across all migrations)

```
"tablename: description"
-- Examples from existing migrations:
"compass_categories: public read"
"connected_profiles: owner select"
"social_rel: participant read peers"
"district_boundaries_authenticated_read"
```

### Auth Check Patterns (HIGH confidence — verified in migrations 007–022)

```sql
-- Cached auth.uid() — ALWAYS use this form, never bare auth.uid()
(select auth.uid()) = user_id

-- Public read (no restriction)
USING (true)

-- Anon + authenticated public read
TO anon, authenticated
USING (true)

-- Authenticated-only read
TO authenticated
USING (true)
```

The `(select auth.uid())` subquery form is used consistently throughout to allow Postgres query plan caching (documented in migration 007 comments).

### Recommended Migration Structure

```
supabase/migrations/
  20260319000044_phase34_essentials_rls.sql
  20260319000045_phase34_meetings_rls.sql
  20260319000046_phase34_staging_rls.sql
  20260319000047_phase34_treasury_rls.sql
  20260319000048_phase34_transparent_motivations_rls.sql
  20260319000049_phase34_compass_rls.sql
```

One file per schema. Each file follows this structure:
1. Comment header (migration number, schema name, table list, policy design rationale)
2. `BEGIN;`
3. `ALTER TABLE ... ENABLE ROW LEVEL SECURITY;` for all tables in schema
4. `CREATE POLICY` statements
5. `GRANT USAGE ON SCHEMA ... TO anon, authenticated;`
6. `GRANT SELECT ON ALL TABLES IN SCHEMA ... TO anon, authenticated;`
7. `COMMIT;`

### Policy Categories by Schema

#### `essentials` — Public read, no user-linked data expected

Per PLATFORM-CONSOLIDATION.md: "Politicians, offices, districts, geofences, legislative data, images, contacts, endorsements, quotes." These are reference/public data. All 30 tables get:
```sql
-- Source: pattern from inform_rls_grants.sql (migration 016)
ALTER TABLE essentials.table ENABLE ROW LEVEL SECURITY;
CREATE POLICY "table: public read"
  ON essentials.table
  FOR SELECT
  TO anon, authenticated
  USING (true);
```

**Open question:** Some `essentials` tables might link users (e.g., if there are any `user_id` FK columns). This must be verified by querying `information_schema.columns` before writing policies. Tables with user FKs need owner-read, not public-read. This is the only unresolved question for essentials.

#### `meetings` — Public read

Per PLATFORM-CONSOLIDATION.md: "CouncilScribe (meetings, speakers, segments, summaries, votes)." This is public civic record data. All 7 tables get public read (`TO anon, authenticated`).

#### `staging` — Authenticated read only (reviewer workflow)

Per task description: "Authenticated read (reviewers), admin write." This is volunteer data entry with a review workflow — NOT public. Only authenticated users should read it. Anon gets no access.

```sql
ALTER TABLE staging.table ENABLE ROW LEVEL SECURITY;
CREATE POLICY "table: authenticated read"
  ON staging.table
  FOR SELECT
  TO authenticated
  USING (true);
```

**Design note:** The task description says "reviewers" for staging read. However, there is no existing reviewer-role RLS pattern in ev-accounts — all role-gated access currently goes through service role in route middleware. Adding reviewer-role gating at the RLS layer would require a new pattern not established in the codebase. Given Phase 37 (staging endpoints) will enforce reviewer gating in route middleware via service role, the RLS policy should be `TO authenticated` (deny anon, allow authenticated) — consistent with the route-layer enforcement pattern. This is the safe, consistent choice.

#### `treasury` — Public read

Per PLATFORM-CONSOLIDATION.md: "Municipal budget data (cities, budgets, categories, line items)." Public civic data. All 4 tables get public read.

#### `transparent_motivations` — Public read

Name and count (7 tables) suggest public civic transparency data. No Go backend documentation suggests private data. Public read.

**Confidence: MEDIUM** — No Go backend source reviewed. Based on naming convention and the civic-transparency product context. The planner should flag this for pre-migration verification.

#### `compass` (Go's schema, to be retired) — Public read, matching `inform` schema pattern

Per task description: "Public read, admin write (to be retired later)." The Go `compass` schema contains topics, stances, answers — same domain as `inform.compass_*` tables. The `inform` schema precedent is clear: reference tables get public read, user data tables (`answers`, `responses`) get owner-only select.

**Open question for compass:** Does Go's `compass` schema have a user-linked answers/responses table? If so, that table needs owner-only read, not public read. Must verify column structure before writing policies.

### Anti-Patterns to Avoid

- **DO NOT add INSERT/UPDATE/DELETE policies for authenticated or anon roles.** All writes in ev-accounts go through service role. Adding write policies would break the service-role-only write architecture.
- **DO NOT use bare `auth.uid()`** — always wrap in `(select auth.uid())` for plan caching.
- **DO NOT skip GRANT USAGE on schema** — without it, even RLS-permitted rows return "permission denied for schema."
- **DO NOT write a single monolithic migration** — one schema per file for reviewability and rollback granularity.
- **DO NOT apply `transparent_motivations` or `compass` policies without first verifying column structures** — if there are user-linked rows, those tables need owner-read policies, not public-read.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Admin write gating | INSERT/UPDATE/DELETE RLS policies | Service role bypasses RLS | Established pattern across all 46 migrations; adding write policies creates inconsistency and potential conflicts |
| Reviewer-role gating | Custom role claim in USING clause | `TO authenticated` + route middleware | No reviewer-role RLS pattern exists in ev-accounts; route-layer enforcement is where role checks live |
| Migration idempotency guards | `DO $$ IF NOT EXISTS $$` blocks | Simple `ALTER TABLE` + `CREATE POLICY` | Migration files are tracked by Supabase CLI and never run twice; idempotency guards add noise (only needed for DDL that's re-run outside migrations, like the location migration's `CREATE TABLE IF NOT EXISTS`) |

**Key insight:** The service role bypasses RLS completely. "Admin write" in ev-accounts means "write goes through pool.query() as service role." This has been the architecture since v1.0. Phase 34 does not need to invent admin write policies — only read policies need to be defined.

---

## Common Pitfalls

### Pitfall 1: Missing GRANT USAGE

**What goes wrong:** Tables have RLS enabled and correct policies, but all queries return "permission denied for schema."
**Why it happens:** PostgreSQL requires `GRANT USAGE ON SCHEMA` before any role can access objects in a custom schema. Supabase pre-grants this only for `public`; all custom schemas need explicit grants.
**How to avoid:** Every migration file that enables RLS on a new schema MUST include `GRANT USAGE ON SCHEMA schema TO anon, authenticated;`.
**Warning signs:** "permission denied for schema" in Supabase logs when querying tables that have correct RLS policies.

### Pitfall 2: GRANT SELECT on ALL TABLES at schema level — tables added later don't inherit

**What goes wrong:** `GRANT SELECT ON ALL TABLES IN SCHEMA essentials TO anon, authenticated` grants SELECT on tables that exist at migration time. Tables added to the schema later do not automatically get the grant.
**Why it happens:** PostgreSQL GRANT SELECT on ALL TABLES is a one-time snapshot, not a standing permission.
**How to avoid:** For schemas that will have tables added in future phases, use `ALTER DEFAULT PRIVILEGES IN SCHEMA essentials GRANT SELECT ON TABLES TO anon, authenticated;` in addition to the GRANT ALL TABLES statement.
**Warning signs:** New tables added to a schema are inaccessible via PostgREST despite having RLS policies.

### Pitfall 3: User-linked tables silently exposed

**What goes wrong:** A table in `essentials` or `compass` has a `user_id` column referencing `auth.users`, but gets a public-read policy (`USING (true)`). All users' data is exposed to everyone.
**Why it happens:** Assuming all tables in a reference schema are pure reference data without verifying column structure.
**How to avoid:** Before writing policies, run `SELECT table_name, column_name FROM information_schema.columns WHERE table_schema = 'essentials' AND column_name = 'user_id';` against production. Any table with a `user_id` column gets owner-read, not public-read.
**Warning signs:** User data appears in responses not scoped to the authenticated user.

### Pitfall 4: `compass` schema tables shadow `inform` schema queries

**What goes wrong:** Both `compass.*` and `inform.*` exist with similar table names. If `search_path` includes both schemas, queries may accidentally hit the wrong table.
**Why it happens:** The Go backend's `compass` schema and ev-accounts' `inform` schema cover the same domain.
**How to avoid:** All ev-accounts service code uses fully qualified schema references (`inform.compass_topics`, not just `compass_topics`). The `compass` schema gets RLS enabled but no ev-accounts routes should query it directly — it stays as legacy until retired in Phase 35+.
**Warning signs:** Compass endpoint returns different data than expected; check which schema the query is hitting.

### Pitfall 5: Staging policies too permissive

**What goes wrong:** Staging gets `TO anon, authenticated` (public read) instead of `TO authenticated` (auth required).
**Why it happens:** Copy-paste from public-read schemas without adjusting for staging's restricted nature.
**How to avoid:** Staging policies use `TO authenticated` only — no `anon` role. Anonymous users have no business reading volunteer staging data.
**Warning signs:** `curl -s /api/staging/...` without auth headers returns 200 instead of 401.

---

## Code Examples

Verified patterns from existing migrations:

### Standard Public Read (reference data)

```sql
-- Source: migration 016 (inform_rls_grants.sql)
BEGIN;

ALTER TABLE essentials.governments    ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.politicians    ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.districts      ENABLE ROW LEVEL SECURITY;
-- ... all tables in schema

CREATE POLICY "governments: public read"
  ON essentials.governments
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- ... repeat for each table

GRANT USAGE ON SCHEMA essentials TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA essentials TO anon, authenticated;

COMMIT;
```

### Authenticated-Only Read (staging)

```sql
-- Source: pattern from migration 022 (social_relationships)
BEGIN;

ALTER TABLE staging.entries     ENABLE ROW LEVEL SECURITY;
ALTER TABLE staging.reviews     ENABLE ROW LEVEL SECURITY;
-- ... all staging tables

CREATE POLICY "entries: authenticated read"
  ON staging.entries
  FOR SELECT
  TO authenticated
  USING (true);

-- ... repeat for each table

GRANT USAGE ON SCHEMA staging TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA staging TO authenticated;

COMMIT;
```

### Owner-Only Read (user-linked tables, if any found)

```sql
-- Source: migration 007 (rls_public.sql), migration 008 (rls_connect.sql)
CREATE POLICY "user_answers: owner select"
  ON compass.user_answers
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id);
```

### Verification Query (post-migration check)

```sql
-- Source: Phase 34 success criteria from roadmap
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE schemaname IN ('essentials','meetings','staging','treasury','transparent_motivations','compass')
ORDER BY schemaname, tablename;
-- Expected: rowsecurity = true for every row

SELECT schemaname, tablename, policyname, roles, cmd
FROM pg_policies
WHERE schemaname IN ('essentials','meetings','staging','treasury','transparent_motivations','compass')
ORDER BY schemaname, tablename;
-- Expected: at least one policy per table
```

### Pre-Migration User-ID Check

```sql
-- Run this before writing policies to catch user-linked tables
SELECT table_schema, table_name, column_name
FROM information_schema.columns
WHERE table_schema IN ('essentials','meetings','staging','treasury','transparent_motivations','compass')
  AND column_name ILIKE '%user_id%'
ORDER BY table_schema, table_name;
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| No RLS (Go backend) | RLS on every table | Phase 34 | Security baseline for all migrated schemas |
| Bare `auth.uid()` | `(select auth.uid())` subquery | Migration 007 (v1.0) | Query plan caching; consistent across all 46 migrations |
| Manual schema writes | Service role via pool.query() | v1.3 production patch | PostgREST cannot write to non-public schemas reliably |

**Deprecated/outdated:**
- `supabaseAdmin.schema('...').from().update/insert()` via PostgREST for non-public schemas: NEVER use for writes (established critical production pattern, MEMORY.md)
- `auth.jwt() ->> 'role'` for admin checks: not used in any existing RLS policy; role-gating in ev-accounts is done at route middleware layer, not RLS layer

---

## Open Questions

1. **Do any `essentials` tables have `user_id` columns?**
   - What we know: PLATFORM-CONSOLIDATION.md lists essentials as "Politicians, offices, districts, geofences, legislative data, images, contacts, endorsements, quotes" — all sounds like reference data
   - What's unclear: No Go backend schema DDL available to confirm; cannot rule out user-linked tables without querying `information_schema.columns` against production
   - Recommendation: Planner should include a task to run the pre-migration user-ID check SQL (see Code Examples section) and branch the policy type based on results BEFORE writing RLS migrations

2. **Does Go's `compass` schema have user-linked answer/response tables?**
   - What we know: PLATFORM-CONSOLIDATION.md says Go compass has "Topics, stances, answers, contexts, verdicts, user_compasses" — "user_compasses" and "answers" likely have user FKs
   - What's unclear: Exact column structure; Go schema DDL not in this repo
   - Recommendation: Treat `compass` tables named `*_answers`, `*_responses`, `user_compasses`, or `verdicts` as owner-only read until column structure is verified

3. **Exact table names for all 6 schemas**
   - What we know: Row counts from task prompt (essentials: 30 tables, meetings: 7, staging: 6, treasury: 4, transparent_motivations: 7, compass: 8 = 62 tables, not 57 — discrepancy vs "57 tables across 5 schemas" in task prompt)
   - What's unclear: Whether the count in the task prompt (57) or the per-schema breakdown (62 tables) is accurate; exact table names in each schema
   - Recommendation: Planner should include a task to enumerate all tables via `SELECT schemaname, tablename FROM pg_tables WHERE schemaname IN (...) ORDER BY schemaname, tablename;` and use that list as the definitive source for migration authoring

4. **`transparent_motivations` access model**
   - What we know: Schema name strongly implies public civic transparency data; 7 tables
   - What's unclear: Could contain user-submitted motivations (user-linked) or just reference data; no Go backend docs in this repo
   - Recommendation: Default to `TO authenticated USING (true)` (authenticated-only, not anon) until verified; more conservative than public-read, less conservative than owner-only

5. **CONS-02 scope: does Phase 34 include row count verification?**
   - What we know: CONS-02 says "All 52 EV-Backend tables imported with data verified (row counts match source)." The task prompt says the schemas are ALREADY in the same project.
   - What's unclear: Whether the data migration (pg_dump/restore) has already happened or still needs to happen; whether row count verification is in scope for Phase 34
   - Recommendation: Planner should clarify with user: "Are the schemas already present with data, or do we need to run pg_dump/restore first?" This is the single most important pre-flight question for Phase 34.

---

## Sources

### Primary (HIGH confidence)
- `supabase/migrations/20260226000016_inform_rls_grants.sql` — canonical public-read + owner-read pattern with GRANT structure
- `supabase/migrations/20260224000007_rls_public.sql` — owner-only pattern for sensitive tables
- `supabase/migrations/20260224000008_rls_connect.sql` — participant-read patterns, no write policies
- `supabase/migrations/20260227000022_phase6_rls_and_grants.sql` — authenticated-only read (social_relationships)
- `supabase/migrations/20260310000031_location_schema.sql` — `CREATE POLICY IF NOT EXISTS` idempotency pattern for policies in DO blocks
- `supabase/migrations/20260224000011_grant_schema_permissions.sql` — GRANT USAGE + selective GRANT SELECT pattern

### Secondary (MEDIUM confidence)
- `PLATFORM-CONSOLIDATION.md` — schema inventory (6 schemas, table counts, schema purposes)
- `.planning/REQUIREMENTS.md` — CONS-01 through CONS-04 requirement definitions
- `.planning/ROADMAP.md` — Phase 34 success criteria (RLS verification query)
- `.planning/STATE.md` — open blocker: "EV-Backend Go source access — confirm Go repo access and connection string before starting Phase 34"

### Tertiary (LOW confidence)
- Task prompt description of schemas (transparent_motivations access model, exact table counts) — not independently verified against production DB

---

## Metadata

**Confidence breakdown:**
- RLS policy patterns: HIGH — verified across 46 migrations, extremely consistent
- Schema GRANT patterns: HIGH — verified in multiple migrations
- Admin write approach (service role only): HIGH — both code and MEMORY.md confirm
- essentials/meetings/treasury table structures: MEDIUM — schema purposes clear, exact columns unverified
- staging access model (authenticated-only): MEDIUM — inferred from workflow description
- transparent_motivations access model: LOW — inferred from naming only
- compass user-linked tables: MEDIUM — "user_compasses" and "answers" names strongly suggest user FKs

**Research date:** 2026-03-19
**Valid until:** 2026-04-18 (stable domain — RLS patterns don't change frequently)
