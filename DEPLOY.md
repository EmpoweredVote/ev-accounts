# Empowered Accounts — Deployment Runbook

## Overview

This runbook covers everything needed to bring up Empowered Accounts in a production or staging environment:

- Enabling required PostgreSQL extensions in Supabase
- Applying backend migrations 026–029 to the production Supabase instance
- Verifying the deployment with post-apply queries
- Deploying the backend API to Render and building the admin UI
- Running smoke tests before opening Alpha access
- Post-deployment housekeeping (TypeScript types regeneration)

Use this document for cold-starts, migration deploys, and rollback reference.

---

## Prerequisites

- Access to Supabase Dashboard for the production project
- Render dashboard access (backend service + admin UI static site)
- Direct Postgres connection string (port 5432, `db.<ref>.supabase.co`) — NOT the pooler URL (port 6543, `pooler.supabase.com`)
- All environment variables listed in the section below
- Node.js 20+ installed locally (for running migration scripts)

---

## Environment Variables

### Backend (Render service)

| Variable | Source | Notes |
|---|---|---|
| `NODE_ENV` | Set manually | `production` |
| `PORT` | Set manually | `3000` (Render default) |
| `SUPABASE_URL` | Supabase Dashboard → Project Settings → API | `https://<ref>.supabase.co` |
| `SUPABASE_ANON_KEY` | Supabase Dashboard → Project Settings → API | Public anon key |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase Dashboard → Project Settings → API | Service role key — keep secret |
| `DATABASE_URL` | Supabase Dashboard → Project Settings → Database | Direct connection only. Format: `postgresql://postgres.<ref>:<pwd>@db.<ref>.supabase.co:5432/postgres`. Do NOT use the pooler URL (`pooler.supabase.com`, port 6543). Multi-statement migrations fail on the pooler. |
| `REDIS_URL` | Upstash Console | `rediss://...` (TLS URL) |
| `CORS_ORIGIN` | Set manually | Frontend origin, e.g. `https://empoweredvote.com` |
| `QUEST_SERVICE_KEY` | Shared secret | Used by Validation Quests service to authenticate against accounts API |
| `TRIVIA_SERVICE_KEY` | Shared secret | Used by CTC service to authenticate against accounts API |
| `ADMIN_SERVICE_KEY` | Shared secret | Used by admin UI to authenticate admin-only endpoints |

### Admin UI (Vite static build)

| Variable | Source | Notes |
|---|---|---|
| `VITE_API_URL` | Set manually | Backend URL, e.g. `https://api.empoweredvote.com`. Must be set at build time, not runtime — Vite inlines `VITE_*` env vars during `npm run build`. Changing this value after the build requires a full rebuild and redeploy. |

---

## Step 1: Enable PostgreSQL Extensions

One-time setup. Run in Supabase Dashboard → SQL Editor:

```sql
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
```

PostGIS is required for Phase 19 (location infrastructure — district boundary lookups). pgcrypto is required for Phase 19 (encrypted coordinate storage via Supabase Vault). Enable both now to avoid a second deploy window when Phase 19 ships.

---

## Step 2: Apply Migrations

### Important: Use direct connection only

`DATABASE_URL` must use the direct connection format:

```
postgresql://postgres.<ref>:<pwd>@db.<ref>.supabase.co:5432/postgres
```

Port 5432, `db.<ref>.supabase.co` subdomain. NOT the pooler (`pooler.supabase.com`, port 6543). Multi-statement SQL files — which include `CREATE OR REPLACE FUNCTION`, `DO $$ ... $$`, and multiple DDL statements — fail on the pooler because the pooler does not support multi-statement transactions.

### Apply order (strictly sequential)

```
026 → 027 → 028 → 029
```

Do not skip or reorder. Migration 029 references `inform.politicians.is_candidate` which is added by 026.

### Using the apply script (recommended)

From the repo root:

```bash
DATABASE_URL="postgresql://postgres.<ref>:<pwd>@db.<ref>.supabase.co:5432/postgres" \
  npx tsx backend/scripts/applyMigrations.ts
```

The script:
- Checks if each migration is already applied before executing (safe to re-run)
- Applies migrations in order
- Runs post-verification queries after each migration
- Exits 1 on any failure with a descriptive message
- Logs `[026] SKIP — already applied`, `[026] OK`, or `[026] FAIL` per migration

### Manual apply (fallback)

If `tsx` is not available or you prefer direct SQL execution:

```bash
psql "$DATABASE_URL" -f backend/migrations/026_inform_schema_repair_and_candidates.sql
psql "$DATABASE_URL" -f backend/migrations/027_rpc_reset_compass_answers.sql
psql "$DATABASE_URL" -f backend/migrations/028_rpc_import_compass_calibrations.sql
psql "$DATABASE_URL" -f backend/migrations/029_compass_admin_rpcs.sql
```

### Post-apply verification queries

Run in Supabase Dashboard → SQL Editor to confirm each migration applied correctly:

```sql
-- 026: is_candidate column added to inform.politicians
SELECT column_name FROM information_schema.columns
WHERE table_schema = 'inform' AND table_name = 'politicians'
  AND column_name = 'is_candidate';
-- Expected: 1 row

-- 026: deleted_at column added to inform.compass_responses
SELECT column_name FROM information_schema.columns
WHERE table_schema = 'inform' AND table_name = 'compass_responses'
  AND column_name = 'deleted_at';
-- Expected: 1 row

-- 027: reset_compass_answers RPC exists
SELECT proname FROM pg_proc WHERE proname = 'reset_compass_answers';
-- Expected: 1 row

-- 028: import_compass_calibrations RPC exists
SELECT proname FROM pg_proc WHERE proname = 'import_compass_calibrations';
-- Expected: 1 row

-- 029: admin_create_topic_with_stances RPC exists
SELECT proname FROM pg_proc WHERE proname = 'admin_create_topic_with_stances';
-- Expected: 1 row
```

All five queries must return exactly 1 row before proceeding.

---

## Step 3: Deploy Backend

Render auto-deploys from the `master` branch on every push. To trigger a manual deploy:

1. Go to Render Dashboard → your backend service
2. Click "Manual Deploy" → "Deploy latest commit"

Verify the backend is running:

```
GET https://<backend-domain>/api/health
```

Expected response: `{ "status": "ok" }`

Wait for this to return 200 before proceeding to Step 4.

---

## Step 4: Build and Deploy Admin UI

`VITE_API_URL` must be set in the Render Static Site environment variables BEFORE triggering the build. Render injects Vite env vars at build time — not at runtime. If the variable is missing or wrong, the built assets will point to the wrong API URL and a full rebuild is required.

```bash
cd admin && npm run build
# Outputs compiled assets to admin/dist/
```

Deploy: Render Static Site auto-deploys from the `master` branch. The build command in Render settings should be `cd admin && npm run build` with publish directory `admin/dist`.

---

## Step 5: Run Smoke Tests

After deploying, run the automated smoke test suite to verify all critical endpoints are reachable:

```bash
SMOKE_TEST_URL=https://<backend-domain> npx tsx backend/scripts/smokeTest.ts
```

See `backend/scripts/smokeTest.ts` for the full test list. All checks must pass before announcing Alpha access to any users.

---

## Step 6: Post-Deployment Housekeeping

After migrations are applied to production, regenerate the TypeScript database types so local development stays in sync with the production schema:

```bash
supabase gen types typescript --project-id <ref> --schema public,connect,empower,inform \
  > backend/src/types/database.types.ts
```

Commit the regenerated file:

```bash
git add backend/src/types/database.types.ts
git commit -m "chore: regenerate database types after migrations 026-029"
```

Omitting this step leaves local type definitions out of sync with the production schema, which causes type errors in subsequent development.

---

## Rollback

### When to roll back

Roll back a migration only if the post-apply verification fails OR if the deployment causes production errors. Rollback is destructive for 026 (column drops) — only proceed if no user data has been written to those columns.

### 026 rollback

```sql
ALTER TABLE inform.politicians DROP COLUMN IF EXISTS is_candidate;
ALTER TABLE inform.compass_responses DROP COLUMN IF EXISTS deleted_at;
DROP INDEX IF EXISTS inform.idx_compass_responses_user_active;
```

WARNING: `DROP COLUMN` is irreversible. Only run this if no `is_candidate` or `deleted_at` data has been written to production.

### 027 rollback

```sql
DROP FUNCTION IF EXISTS public.reset_compass_answers(UUID, BOOLEAN);
```

### 028 rollback

```sql
DROP FUNCTION IF EXISTS public.import_compass_calibrations(UUID, JSONB, BOOLEAN);
```

### 029 rollback

```sql
DROP FUNCTION IF EXISTS public.admin_create_topic_with_stances(TEXT, TEXT, TEXT[], INT[], BOOLEAN);
DROP FUNCTION IF EXISTS public.admin_assign_topic_categories(INT, INT[]);
DROP FUNCTION IF EXISTS public.admin_list_politicians(BOOLEAN, INT, INT);
```

Roll back in reverse order: 029, then 028, then 027, then 026.

---

## Common Pitfalls

1. **Wrong migrations folder.** Do NOT apply files from `supabase/migrations/`. Only apply `backend/migrations/026`, `027`, `028`, `029`. The `supabase/migrations/` folder contains older schema baseline files that are already applied.

2. **Wrong apply order.** Always apply 026 → 027 → 028 → 029 in sequence. Migration 029 contains references to `inform.politicians.is_candidate` which is added by 026. Applying 029 before 026 will fail.

3. **Pooler URL instead of direct connection.** The pooler (`pooler.supabase.com`, port 6543) does not support multi-statement transactions. Migration files contain multiple DDL statements that must run in a single connection. Always use the direct URL (`db.<ref>.supabase.co`, port 5432).

4. **VITE_API_URL set after build.** Vite inlines env vars at build time. Setting `VITE_API_URL` in Render after a build has no effect on the already-compiled assets. The variable must be present before the build starts. A wrong URL requires a full rebuild.

5. **Wrong script filename.** The migration script is `backend/scripts/applyMigrations.ts` (TypeScript, plural). There is no `applyMigration.js`. Use `npx tsx backend/scripts/applyMigrations.ts` or the `psql -f` fallback.

6. **Forgetting to regenerate types.** After running migrations, always regenerate `backend/src/types/database.types.ts` and commit it. Missing this step causes type drift between local dev and production.
