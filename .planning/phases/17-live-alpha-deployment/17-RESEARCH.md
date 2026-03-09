# Phase 17: Live Alpha Deployment - Research

**Researched:** 2026-03-09
**Domain:** Database migration deployment, production environment verification, smoke testing
**Confidence:** HIGH (all findings from direct codebase inspection + Supabase CLI official docs)

---

## Summary

Phase 17 deploys the accumulated `backend/migrations/026–029` files to the production Supabase
instance and verifies the system is accessible to Alpha users. The work is operational, not
code-writing: apply SQL, verify state, document a runbook.

The most critical discovery is that this project runs **two parallel migration systems**:

1. **`backend/migrations/` (numbered, no timestamps)** — the actual production deployment path.
   Migrations 025–029 live here. These are applied manually using psql or a pg-pool script.
   This is what Phase 17 must apply.

2. **`supabase/migrations/` (timestamp-prefixed)** — the Supabase CLI local-dev path. Migrations
   here track local state. These are NOT what gets applied to production in this project's
   established pattern.

Migration 029's own comment confirms the production path: "Must be run against the live DB via
the admin apply-migration tooling (e.g., `node backend/scripts/applyMigration.js 029`)." That
script does not exist yet — Phase 17 must either create it or use `psql` directly.

The `backend/migrations/` files have no `BEGIN;`/`COMMIT;` wrapping. Each file is a plain SQL
script. Apply via `psql -f` or pipe through the pg pool.

The `supabase/migrations/` files (026–030) do have `BEGIN;`/`COMMIT;` and track the same
logical changes in a different numbering and wrapping convention for local dev parity. These two
systems must remain in sync conceptually but are applied through different paths.

**Primary recommendation:** Apply `backend/migrations/026–029` to production using `psql` with
the production `DATABASE_URL`. Create a one-off Node.js apply script that reads and executes the
SQL via the existing `pg` pool. Document the full runbook in `DEPLOY.md`.

---

## Standard Stack

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| `pg` (node-postgres) | ^8.13.0 | Direct DB connection for migration execution | Already in project; `ssl: { rejectUnauthorized: false }` configured for Supabase |
| Supabase CLI | 2.75.0 (installed) | `migration list --linked` to verify production state, `db push --dry-run` for preview | Already installed; project has `supabase/config.toml` |
| `psql` | system | Manual SQL execution against production DB | Most direct rollback tool; no abstraction layer |
| `supabase gen types typescript` | CLI | Regenerate `database.types.ts` after migrations applied | Required post-deploy step per v1.2 patterns |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| Supabase Dashboard SQL Editor | web | Apply individual migrations if psql unavailable | Fallback only — no version tracking |
| Supabase Dashboard Extensions | web | Enable PostGIS and pgcrypto | One-time setup; cannot be done in migrations easily |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manual psql apply | `supabase db push` | `db push` only knows about `supabase/migrations/` timestamps; it cannot apply `backend/migrations/` numbered files |
| psql directly | node script via pg pool | Node script integrates into existing codebase patterns but adds startup complexity; psql is simpler and sufficient |

---

## Architecture Patterns

### The Two Migration Systems

This project intentionally uses two systems:

```
backend/migrations/        ← production deployment path
  025_rpc_pool_migration.sql
  026_inform_schema_repair_and_candidates.sql
  027_rpc_reset_compass_answers.sql
  028_rpc_import_compass_calibrations.sql
  029_compass_admin_rpcs.sql

supabase/migrations/       ← Supabase CLI local dev path
  20260224000001_create_schemas.sql
  ...
  20260303000026_fix_users_public_security_invoker.sql    ← different content than backend/026
  20260303000027_rls_postgis_system_tables.sql
  20260303000028_grant_connected_profiles_selected_topics.sql
  20260304000029_phase9_xp_schema.sql
  20260304000030_phase9_xp_rpcs.sql                       ← not yet in backend/migrations/
```

The `supabase/migrations/` files 026–030 were created for v1.2 hardening (linter fixes, XP schema)
and ARE NOT the same content as `backend/migrations/026–029`. They track different concerns.

The `backend/migrations/` files 026–029 ARE the Phase 12–16 compass admin work that needs to go live.

### What Each backend/migration Does

**026** (`inform_schema_repair_and_candidates`):
- Idempotent full recreate of `inform` schema tables using `CREATE TABLE IF NOT EXISTS`
- Adds `deleted_at TIMESTAMPTZ` to `inform.compass_responses` (soft-delete support)
- Adds `is_candidate BOOLEAN DEFAULT false` to `inform.politicians`
- Adds `idx_compass_responses_user_active` partial index (WHERE deleted_at IS NULL)
- **Repair migration**: safe to re-run if inform schema already partially exists

**027** (`rpc_reset_compass_answers`):
- `CREATE OR REPLACE FUNCTION public.reset_compass_answers(p_user_id UUID, p_full_reset BOOLEAN)`
- Soft-deletes all active compass_responses, clears selected_topic_ids, optionally resets onboarding
- SECURITY DEFINER, SET search_path = ''
- No explicit BEGIN/COMMIT — PL/pgSQL block is implicit transaction

**028** (`rpc_import_compass_calibrations`):
- `CREATE OR REPLACE FUNCTION public.import_compass_calibrations(p_user_id UUID, p_calibrations JSONB, p_set_onboarding_complete BOOLEAN)`
- Two-pass: validate all, then write all. Upserts with ON CONFLICT (user_id, topic_id).
- SECURITY DEFINER, SET search_path = ''

**029** (`compass_admin_rpcs`):
- `CREATE OR REPLACE FUNCTION public.admin_create_topic_with_stances(...)`
- `CREATE OR REPLACE FUNCTION public.admin_assign_topic_categories(...)`
- `CREATE OR REPLACE FUNCTION public.admin_list_politicians(...)` (updates version from 025 that omitted is_candidate)
- All SECURITY DEFINER, SET search_path = ''

### Dependency Order

Strict apply order: **026 → 027 → 028 → 029**

- 027 references `inform.compass_responses` (created/verified by 026)
- 028 references `inform.compass_topics` and `connect.connected_profiles` (026 verifies inform exists)
- 029 references `inform.politicians.is_candidate` (added in 026) via `admin_list_politicians`

### Extension Prerequisites

**PostGIS**: Required because migration `supabase/027` enables RLS on `public.spatial_ref_sys`,
which is only created when PostGIS is enabled. If PostGIS is not enabled on the production
Supabase instance, `supabase/027` will fail with "table does not exist."

**Note:** `backend/migrations/026–029` do NOT reference PostGIS or `spatial_ref_sys`. The
`supabase/migrations/027` that does reference PostGIS is the local-dev path. However, since
PostGIS will be needed for Phase 19 (location infrastructure) and enabling it installs
`spatial_ref_sys`, it is cleanest to enable PostGIS during Phase 17's environment setup.

**pgcrypto**: The `gen_random_uuid()` function used throughout the schema is built into
PostgreSQL 13+ core (`pgcrypto` not required for UUID generation). However, Phase 20 uses
pgcrypto via Supabase Vault for encrypted lat/lng. Enable it during Phase 17's setup as a
forward-compatibility step.

**How to enable extensions in Supabase production:**
```
Dashboard → Database → Extensions → search "postgis" → Enable
Dashboard → Database → Extensions → search "pgcrypto" → Enable
```
Alternatively via SQL (Supabase SQL Editor):
```sql
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
```

### Migration Execution Pattern

The project has `pg` pool configured at `backend/src/lib/db.ts`:
```typescript
// ssl: { rejectUnauthorized: false } — required for Supabase self-signed cert
// DATABASE_URL — direct connection (bypasses Supavisor)
// --dns-result-order=ipv4first — Render IPv4 requirement
```

A one-off apply script should:
1. Read the SQL file from `backend/migrations/`
2. Execute via `pool.query(sql)` — single query, no BEGIN/COMMIT needed for CREATE OR REPLACE
3. Log success/failure per file

Alternatively: `psql $DATABASE_URL -f backend/migrations/026_inform_schema_repair_and_candidates.sql`

### Smoke Test Endpoints

All route mounts from `backend/src/index.ts`:

| Priority | Endpoint | Auth | Smoke Test Action |
|----------|----------|------|-------------------|
| 1 | `GET /api/health` | none | 200 + `{ status: 'ok' }` |
| 2 | `POST /api/auth/signup` | none | 422 on bad body (no real signup needed) |
| 2 | `POST /api/auth/login` | none | 401 on wrong creds (proves Supabase auth reachable) |
| 3 | `GET /api/compass/topics` | none | 200 + array (proves inform schema accessible) |
| 4 | `GET /api/essentials/politicians` | none | 200 + array (proves is_candidate column present) |
| 5 | Admin UI loads | browser | No JS errors, login page renders |
| 5 | `GET /api/admin/me` | admin JWT | 200 (proves admin auth flow works) |

### Environment Variables

**Backend (Render service):**

```
NODE_ENV=production
PORT=3000
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=<anon-key>
SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
DATABASE_URL=postgresql://postgres.<project-ref>:<password>@aws-0-<region>.pooler.supabase.com:6543/postgres
REDIS_URL=https://<upstash-endpoint>.upstash.io
CORS_ORIGIN=https://<admin-ui-domain>,https://<framer-domain>
QUEST_SERVICE_KEY=<secret>
TRIVIA_SERVICE_KEY=<secret>
ADMIN_SERVICE_KEY=<secret>
```

Note: `SUPABASE_JWT_SECRET` is optional in env schema (used for local JWT verification bypass).
In production, JWT verification goes through Supabase Auth API.

**Admin UI (Vite static build):**

```
VITE_API_URL=https://<backend-api-domain>
```

Only one env var needed. The admin `vite.config.ts` shows a dev proxy to `localhost:3000`;
in production, `VITE_API_URL` is set at build time and baked into the static bundle.

### Admin UI Build/Deploy Process

```bash
# In admin/ directory
npm run build      # tsc && vite build → outputs to admin/dist/
```

The `admin/dist/` static files must be served. Options:
- Render Static Site (point to `admin/dist/`)
- Netlify/Vercel deploy from `admin/dist/`
- Serve via the Express backend (add static middleware — not currently configured)

No `VITE_API_URL` in `.env.example` for admin — the planner should note this needs documenting.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Migration state tracking | Custom tracking table | `supabase migration list --linked` | Already exists in Supabase CLI; shows LOCAL vs REMOTE diff |
| Rollback scripts | Automatic rollback tooling | Manual `psql` with pre-verified rollback SQL | PostgreSQL DDL in transactions rolls back on error; SECURITY DEFINER functions can be re-run with CREATE OR REPLACE |
| Type regeneration | Manual type sync | `supabase gen types typescript --project-id <ref>` | CLI generates complete `database.types.ts` from live schema |

**Key insight:** The migration files are largely `CREATE OR REPLACE` (functions) and
`ADD COLUMN IF NOT EXISTS` / `CREATE TABLE IF NOT EXISTS` (schema). These are **idempotent** and
safe to re-run on failure. True rollback is only needed for the `ADD COLUMN` in migration 026.

---

## Common Pitfalls

### Pitfall 1: Applying backend/migrations vs supabase/migrations

**What goes wrong:** Using `supabase db push` to apply the backend/migrations. These are different
files with different numbering. `supabase db push` only sees `supabase/migrations/` and would
apply the timestamp-prefixed files, not `backend/migrations/026–029`.

**Why it happens:** Two systems exist in the same repo with no clear sign labeling which is
"production."

**How to avoid:** Apply `backend/migrations/026–029` via `psql -f` or a pg-pool script.
Use `supabase db push` only for local dev state management.

**Warning signs:** If after applying you see `admin_list_politicians` function present but
`inform.politicians.is_candidate` column is missing, the wrong files were applied.

### Pitfall 2: Applying 026–029 Out of Order

**What goes wrong:** 029's `admin_list_politicians` function queries `inform.politicians.is_candidate`
(added in 026). If 029 is applied before 026, the RPC compiles fine (SQL functions are compiled at
call time in Postgres), but will fail at runtime with "column does not exist."

**Why it happens:** CREATE OR REPLACE doesn't validate referenced columns at definition time.

**How to avoid:** Apply strictly in order: 026 → 027 → 028 → 029. Verify after each file.

**Warning signs:** `admin_list_politicians()` returns error at runtime despite RPC existing.

### Pitfall 3: PostGIS Not Enabled Before local supabase/migrations/027

**What goes wrong:** `supabase/migrations/20260303000027_rls_postgis_system_tables.sql` does
`ALTER TABLE public.spatial_ref_sys ENABLE ROW LEVEL SECURITY`. If PostGIS is not enabled,
`spatial_ref_sys` doesn't exist and the migration fails.

**Why it happens:** PostGIS creates `spatial_ref_sys` when enabled. If enabled after migrations run,
the table exists but the RLS was never applied.

**How to avoid:** Enable PostGIS in the production dashboard BEFORE running `supabase db push`
if that path is ever used. For Phase 17's path (backend/migrations), this is not immediately
relevant but should be documented for future use.

### Pitfall 4: DATABASE_URL Must Be Direct Connection, Not Pooler URL

**What goes wrong:** Using Supabase's pooler URL (port 6543) instead of direct connection (port 5432)
for migrations. Transaction pooler mode doesn't support `BEGIN;`/`COMMIT;` across multiple
statements properly.

**Why it happens:** Supabase dashboard shows pooler URLs prominently. Direct connection URL is
less prominent.

**How to avoid:** Use `postgresql://postgres.<ref>:<pwd>@db.<ref>.supabase.co:5432/postgres`
(port 5432, `db.` subdomain). The `backend/migrations/` files don't use explicit transactions
but it's a good practice to use the direct URL for migration work.

**Warning signs:** psql connects but DDL errors occur; CREATE TABLE fails silently.

### Pitfall 5: Admin UI VITE_API_URL Not Set at Build Time

**What goes wrong:** Admin UI builds without `VITE_API_URL` set, so `API_BASE` falls back to
relative path. Deployed to a static host, API calls fail.

**Why it happens:** Vite bakes env vars into the bundle at build time. Missing var = empty string.

**How to avoid:** Confirm `VITE_API_URL=https://<backend>` is set in the build environment
before running `npm run build` in the `admin/` directory.

**Warning signs:** Admin login page loads but POST to `/api/auth/login` gets 404 (hitting static host
instead of Express backend).

### Pitfall 6: No apply-migration Script Exists

**What goes wrong:** Migration 029's comment says "run via `node backend/scripts/applyMigration.js 029`"
but no such script exists in the codebase.

**Why it happens:** The script was referenced in the comment as an aspirational pattern but never built.

**How to avoid:** Either create the script as part of Phase 17, or use `psql -f` directly. Do not
reference a non-existent script in the runbook without creating it first.

---

## Code Examples

### Verify Production Migration State

```bash
# Source: Supabase CLI docs (supabase migration list --linked)
supabase link --project-ref <ref>
supabase migration list --linked
# Shows LOCAL column (supabase/migrations/) vs REMOTE column
# Note: backend/migrations/ state is NOT tracked here — must verify via psql
```

### Check Which backend/migrations Were Applied (via psql)

```sql
-- Source: Direct codebase inspection — no existing tracking table exists.
-- Verify by checking for objects created by each migration.

-- 026: Check is_candidate column
SELECT column_name FROM information_schema.columns
WHERE table_schema = 'inform' AND table_name = 'politicians'
  AND column_name = 'is_candidate';

-- 026: Check deleted_at column
SELECT column_name FROM information_schema.columns
WHERE table_schema = 'inform' AND table_name = 'compass_responses'
  AND column_name = 'deleted_at';

-- 027: Check reset_compass_answers RPC
SELECT proname FROM pg_proc WHERE proname = 'reset_compass_answers';

-- 028: Check import_compass_calibrations RPC
SELECT proname FROM pg_proc WHERE proname = 'import_compass_calibrations';

-- 029: Check admin_create_topic_with_stances RPC
SELECT proname FROM pg_proc WHERE proname = 'admin_create_topic_with_stances';
```

### Apply a Migration via psql

```bash
# Source: PostgreSQL docs + project DATABASE_URL pattern
psql "$DATABASE_URL" -f backend/migrations/026_inform_schema_repair_and_candidates.sql
psql "$DATABASE_URL" -f backend/migrations/027_rpc_reset_compass_answers.sql
psql "$DATABASE_URL" -f backend/migrations/028_rpc_import_compass_calibrations.sql
psql "$DATABASE_URL" -f backend/migrations/029_compass_admin_rpcs.sql
```

### Regenerate database.types.ts After Apply

```bash
# Source: Supabase CLI docs
supabase gen types typescript --project-id <ref> \
  --schema public,connect,empower,inform \
  > backend/src/types/database.types.ts
```

### Smoke Test: Compass Topics Returns Data

```bash
# Source: Route inspection (GET /api/compass/topics is public — no auth needed)
curl https://<api-domain>/api/compass/topics
# Expected: 200 + JSON array of topics
# Failure mode: 500 if inform.compass_topics doesn't exist
```

### Smoke Test: Essentials Politicians Returns Data

```bash
# Source: essentialsPoliticians.ts — GET / is optionalAuth
curl https://<api-domain>/api/essentials/politicians
# Expected: 200 + object keyed by office_title
# Failure mode: 500 if is_candidate column missing (026 not applied)
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Direct pg pool queries in admin routes | SECURITY DEFINER RPCs | Migration 025 | Admin mutations now atomic, RLS bypassed correctly |
| `users_public` view ran as view owner (RLS bypass) | `users_public_data` backing table + security_invoker view | `supabase/026` (local), pending prod | Closes Supabase linter security warning |
| No XP system | `total_xp` + `current_level` columns + `xp_transactions` ledger | `supabase/029–030` (local), pending prod | Phase 10 XP API requires this |

**Note:** The `supabase/migrations/026–030` files (which include XP schema, users_public fix, etc.)
have been applied to local dev but NOT to production. Phase 17's scope is only `backend/migrations/026–029`.
The `supabase/migrations/026–030` content represents additional work that has NOT been mapped to
production migration files yet — this gap should be tracked but is out of Phase 17's scope per requirements.

Wait — re-examining: the requirements say "Migrations 026–029 applied to production Supabase instance."
The project context says "Migrations 026–029 not applied to live DB." This refers to `backend/migrations/026–029`.
The `supabase/migrations/` timestamp files are a separate matter.

---

## Open Questions

1. **Which domain are the production DATABASE_URL and env vars stored?**
   - What we know: `.env.example` shows the pattern. The actual production values are in the Render
     service environment variables panel.
   - What's unclear: Whether the DATABASE_URL uses the direct connection (port 5432) or Supavisor
     pooler (port 6543). The pool config says "bypasses Supavisor" but the env var itself may
     still point to the pooler URL.
   - Recommendation: Verify in Render dashboard. Use Supabase Dashboard > Database > Connection String >
     "Direct connection" tab (port 5432) for migration scripts.

2. **Are `supabase/migrations/026–030` (XP schema, users_public fix, etc.) already applied to production?**
   - What we know: v1.2 audit notes "Migrations 026-029 live in backend/migrations/ and must be applied
     manually." The `supabase/migrations/` 026–030 are the local-dev counterparts.
   - What's unclear: Whether the Supabase CLI migration history table in production tracks any
     of the timestamp-prefixed migrations (001–025) that were applied during v1.0 standup.
   - Recommendation: Run `supabase migration list --linked` as the first step to see what the
     Supabase CLI thinks has been applied.

3. **Where is the admin UI deployed? What is its domain?**
   - What we know: Admin UI uses `VITE_API_URL` at build time. Vite config has `server.proxy`
     to `localhost:3000` for dev.
   - What's unclear: Production hosting location (Render Static Site? Netlify? local only?).
   - Recommendation: The runbook must specify admin UI deployment target and confirm
     `VITE_API_URL` is set correctly in the build environment.

4. **Does a `backend/scripts/applyMigration.js` script need to be created?**
   - What we know: Migration 029 comments reference it but it doesn't exist.
   - What's unclear: Whether the planner should create the script or use `psql -f` directly.
   - Recommendation: Use `psql -f` for Phase 17 (simpler, no abstraction needed).
     Document creating the script as a deferred improvement.

---

## Sources

### Primary (HIGH confidence)

- Direct codebase inspection: `backend/migrations/026–029` — full content read, dependency order determined
- Direct codebase inspection: `supabase/migrations/` — timestamp-prefixed files, parallel system confirmed
- Direct codebase inspection: `backend/src/lib/db.ts` — pg pool config, SSL and IPv4 requirements
- Direct codebase inspection: `backend/src/lib/env.ts` — all required env vars enumerated
- Direct codebase inspection: `backend/src/index.ts` — all route mounts, smoke test targets identified
- Direct codebase inspection: `backend/.env.example` — env var template
- Direct codebase inspection: `.planning/milestones/v1.2-MILESTONE-AUDIT.md` — confirms backend/migrations is production path
- Supabase CLI docs (WebFetch): `supabase db push --dry-run`, `supabase migration list --linked`
- Supabase docs (WebFetch): Extension enablement via Dashboard SQL Editor or Extensions panel

### Secondary (MEDIUM confidence)

- Supabase docs (WebFetch): `gen_random_uuid()` available without pgcrypto in PostgreSQL 13+
  (Supabase uses PostgreSQL 17 per `supabase/config.toml` `major_version = 17`)
- WebFetch: PostGIS and pgcrypto are pre-installed Supabase extensions (not need to download)

---

## Metadata

**Confidence breakdown:**
- Migration content (026–029): HIGH — files read directly
- Migration dependency order: HIGH — inter-file references verified
- Two-system architecture: HIGH — confirmed in v1.2 audit notes and migration comments
- Extension prerequisites (PostGIS/pgcrypto): HIGH — Supabase docs confirm pre-installed, dashboard enable
- Env var requirements: HIGH — env.ts schema read directly
- Smoke test endpoints: HIGH — index.ts route mounts read directly
- Admin UI build process: HIGH — package.json and vite.config read directly
- Apply script gap: HIGH — filesystem confirmed script doesn't exist

**Research date:** 2026-03-09
**Valid until:** 2026-04-09 (infrastructure/deployment patterns stable; Supabase CLI version relevant)
