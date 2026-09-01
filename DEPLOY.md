# Empowered Accounts — Deployment Runbook

## Overview

This runbook covers everything needed to bring up Empowered Accounts in a production or staging environment:

- Enabling required PostgreSQL extensions in Supabase
- Configuring PostgREST schema exposure for connect, empower, and inform schemas
- Applying backend migrations 026–036 to the production Supabase instance
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
| `DATABASE_URL` | Supabase (scoped role `ev_api`) | **Runtime uses the least-privilege `ev_api` role, NOT `postgres`** (see "Database role" below). Session pooler, port 5432. Format: `postgresql://ev_api.<ref>:<pwd>@<pooler-host>:5432/postgres`. Do NOT use the transaction pooler (port 6543) — multi-statement queries fail there. |
| `REDIS_URL` | Upstash Console | `rediss://...` (TLS URL) |
| `CORS_ORIGIN` | Set manually | Frontend origin, e.g. `https://empoweredvote.com` |
| `QUEST_SERVICE_KEY` | Shared secret | Used by Validation Quests service to authenticate against accounts API |
| `TRIVIA_SERVICE_KEY` | Shared secret | Used by CTC service to authenticate against accounts API |
| `ADMIN_SERVICE_KEY` | Shared secret | Used by admin UI to authenticate admin-only endpoints |
| `GOOGLE_MAPS_API_KEY` | Google Cloud Console | Required for geocoding (Phase 20). Server exits on startup if missing. |
| `GEMS_SERVICE_KEYS` | Shared secrets | Comma-separated `name:key` pairs for gem award service auth. Optional — absent means all `/award` requests get 401. |
| `WORKOS_CLIENT_ID` | WorkOS Dashboard → API Keys | Public client id (`client_01…`). Setting it makes the API accept WorkOS AuthKit tokens as a **second** issuer alongside Supabase. Absent = Supabase-only, i.e. pre-migration behavior. See "WorkOS AuthKit" below. |
| `WORKOS_API_KEY` | WorkOS Dashboard → API Keys | **Secret** (`sk_test_…` staging / `sk_live_…` production). Used by `POST /api/auth/workos/provision` and by WorkOS-first signup, both of which link accounts. Absent = those paths return 503; token verification never uses it. |
| `WORKOS_ISSUER`, `WORKOS_JWKS_URL` | Set manually | Optional overrides, only for a custom auth domain. Defaults derive from `WORKOS_CLIENT_ID`. |
| `AUTHKIT_PRIMARY` | Set manually | `'true'` moves NEW credential creation to WorkOS: `POST /api/auth/signup` creates the WorkOS user with the password and a passwordless Supabase shadow row. Default `'false'` = Supabase-path signup. Flip together with the frontends' `VITE_AUTHKIT_ONLY`. Also gates the headless-login endpoints: `'true'` routes `/api/auth/forgot-password` and `/api/auth/reset-password` to WorkOS instead of Supabase — see "Headless embedded login" below. |
| `COOKIE_DOMAIN` | Set manually | Domain for all three httpOnly auth cookies (`ev_session`, `ev_wos_session`, `ev_wos_pending`). Set to `.empowered.vote` in prod so the cookie is shared across subdomains — cross-app SSO (both the existing Supabase SSO and the headless-login WorkOS SSO) depends on this. Optional; absent = host-only cookie. |
| `UPSTASH_REDIS_REST_URL` / `UPSTASH_REDIS_REST_TOKEN` | Upstash dashboard | Shared store for **all** `express-rate-limit` limiters (auth, feedback, event-track, invite-send, coordinate-lookup) — see `backend/src/lib/rateLimitStore.ts`. **Load-bearing on a multi-instance service:** the default MemoryStore counts per Node process, so with N instances the caps are really cap × N and effectively never trip. With these set, the count is shared across instances and the caps are real. Also used by the FEC limiter, so they are already set in prod. Absent = per-instance fallback (warned at startup). |

### Rate limiting

Auth and abuse limits use `express-rate-limit` with the Upstash-backed **shared store** above, keyed per limiter (namespaces `auth`, `feedback`, `track`, `invite`, `coord`). If Upstash is unset the limiters silently fall back to the per-instance MemoryStore, which does **not** enforce across Render's multiple instances — verify a 429 actually appears (e.g. >10 bad logins in 15 min from one IP) after any change to instance count or Redis config.

### Database role (`ev_api` vs `postgres`)

The backend API runtime (`backend/src/lib/db.ts` pool) connects as **`ev_api`** — a least-privilege
login role created by `backend/migrations/1386_ev_api_role.sql`. It is `BYPASSRLS` (trusted server
tier, matches `ctc_app`/`trivia_service`) with `statement_timeout=30s`, and holds only USAGE + DML on
the 11 schemas the API's `pool.query` surface uses (`essentials`, `transparent_motivations`, `connect`,
`inform`, `treasury`, `meetings`, `staging`, `empower`, plus a bounded set in `public`, read-only
`app_auth`, write-only `judicial`) + EXECUTE on ~10 in-band RPCs. It has **no** object ownership,
DDL, role management, or access to `vault`/`auth`/other apps' schemas.

- **Set the password out of band** (not in the repo): `ALTER ROLE ev_api PASSWORD '<strong>';`, then put
  the matching URL in the Render `DATABASE_URL`.
- **Migration & ingestion scripts still use `postgres`** (they need DDL / broad access). Pass a
  `postgres` connection string on the command line, e.g.
  `DATABASE_URL="postgresql://postgres.<ref>:<pwd>@db.<ref>.supabase.co:5432/postgres" npx tsx …`.
  This is independent of the Render env var.
- **Auth is unaffected** by the DB role — login/JWT/PostgREST go through the Supabase JS clients
  (`SUPABASE_*` keys), never `DATABASE_URL`.

### Admin UI (Vite static build)

| Variable | Source | Notes |
|---|---|---|
| `VITE_API_URL` | Set manually | Backend URL, e.g. `https://api.empoweredvote.com`. Must be set at build time, not runtime — Vite inlines `VITE_*` env vars during `npm run build`. Changing this value after the build requires a full rebuild and redeploy. |
| `VITE_WORKOS_CLIENT_ID` | WorkOS Dashboard → API Keys | Same public client id as the backend's `WORKOS_CLIENT_ID`. Presence renders the AuthKit sign-in button and enables the WorkOS session path. Build-time, like `VITE_API_URL` — changing it needs a full rebuild. Absent = the login page shows only the classic form. |
| `VITE_AUTHKIT_ONLY` | Set manually | `'true'` hides the classic email/password form on `/login`, leaving AuthKit as the only way in. Build-time. Gated on `VITE_WORKOS_CLIENT_ID` — if that is absent the classic form stays, so a misconfig can't lock everyone out. The break-glass route `/login/classic` always shows the form. Set on the login-hub, app, and validation-quests frontends together. |
| `VITE_EMBEDDED_AUTH` | Set manually | `'true'` renders our OWN embedded email/password + on-page verification-code form instead of the hosted AuthKit auto-forward. Requires `VITE_WORKOS_CLIENT_ID` — the flag has no effect without it. Build-time, like `VITE_AUTHKIT_ONLY`. Applies to the login-hub, app, and validation-quests frontends, but — unlike `VITE_AUTHKIT_ONLY` — is rolled out **one origin at a time**, not simultaneously. See "Headless embedded login" below. |
| `VITE_LOGIN_ORIGIN` | Set manually (optional) | Origin of the central login hub that the **app** build (`empowered-vote-app`) redirects sign-in to under `VITE_EMBEDDED_AUTH`. Build-time. Defaults to `https://login.empowered.vote`; set it only on a **staging** app build (e.g. the staging login hub) so cross-app SSO can be tested without bouncing to the production login. Leave unset in prod. |

---

## WorkOS AuthKit (migration in progress — ADR 0002)

The API accepts **two** token issuers during the Supabase Auth → WorkOS migration.
`backend/src/lib/tokenIdentity.ts` is the single place that maps either token to an
internal user id: a Supabase token via `sub`, a WorkOS token via its `external_id`
claim (the original `auth.users` UUID, written at import/provision time). The WorkOS
`sub` (`user_01…`) is never used as a user id.

### Services that need the client id

Every service that verifies user JWTs itself needs `WORKOS_CLIENT_ID`; every frontend
that offers the sign-in button needs `VITE_WORKOS_CLIENT_ID`:

| Render service | Variable |
|---|---|
| `ev-accounts-api` | `WORKOS_CLIENT_ID` + `WORKOS_API_KEY` (provisioning) |
| `ev-accounts` (admin static — serves login./accounts.empowered.vote) | `VITE_WORKOS_CLIENT_ID` |
| `empowered-vote-app` (app.empowered.vote) | `VITE_WORKOS_CLIENT_ID` |
| `empowered-validation-quests` (backend) | `WORKOS_CLIENT_ID` |
| `validation-quests-frontend` | `VITE_WORKOS_CLIENT_ID` |
| `focused-communities` | `WORKOS_CLIENT_ID` |
| `civic-trivia-backend` | `WORKOS_CLIENT_ID` |
| `empowered-listening` | `WORKOS_CLIENT_ID` |

Not yet ported, so it rejects WorkOS tokens: `civic-spaces`.

### Dashboard settings are PER ENVIRONMENT

Staging and production are separate WorkOS environments and **share nothing**.
Standing up production means redoing every one of these:

- **JWT template** (Authentication → Sessions) must be
  `{"role": "authenticated", "external_id": {{user.external_id}}}`. The API rejects a
  WorkOS token without `role: "authenticated"`, and a token with no `external_id`
  resolves to no account.
- **Branding** (logo, colors, fonts).
- **Redirect URIs** — one per app origin, each ending in `/login`.
- **CORS allowed web origins** — the same origins, no path. Without these the hosted
  page still loads but the in-browser code exchange fails.
- **Login providers / self-serve sign-up** — on by default; social providers were
  switched off in staging on 2026-08-27, but **self-serve sign-up is still ON**.
  Under `VITE_AUTHKIT_ONLY`, AuthKit's hosted sign-up IS the Inform signup path, so
  you likely want it on; the invite-code Connected path stays on `/signup`, which
  posts to `POST /api/auth/signup`. Decide providers again for production.

### Break-glass classic login

`/login/classic` always renders the classic Supabase email/password form, even under
`VITE_AUTHKIT_ONLY`. It is unadvertised (no link points to it) and exists so an
operator can still reach the Supabase path during an AuthKit outage. **It is slated
for removal once Supabase Auth sign-ins are disabled** — at that point the classic
form authenticates against nothing and the route should be deleted.
- **Users** — a fresh import: `backend/scripts/workos-export-users.ts` then
  `workos-import-users.ts` (the import refuses a non-`sk_test_` key unless given
  `--allow-live`).

### Headless embedded login (`VITE_EMBEDDED_AUTH`)

Design: [`docs/HEADLESS-LOGIN-DESIGN.md`](docs/HEADLESS-LOGIN-DESIGN.md). Task plan:
[`docs/superpowers/plans/2026-08-28-headless-workos-login.md`](docs/superpowers/plans/2026-08-28-headless-workos-login.md).

`VITE_EMBEDDED_AUTH='true'` swaps the hosted-page auto-forward for our own embedded
email/password form plus an on-page 6-digit verification-code step, served from
`login.empowered.vote` (the admin build). It requires `VITE_WORKOS_CLIENT_ID` to already
be set. Turning it on **supersedes** the hosted AuthKit auto-forward; `/login/classic`
stays the break-glass classic-Supabase form regardless of this flag.

Staged rollout, one origin at a time — bake each before flipping the next:

| Order | Origin | Service |
|---|---|---|
| 1 | `login.empowered.vote` | `ev-accounts` (admin static) — the form itself lives here |
| 2 | `app.empowered.vote` | `empowered-vote-app` — redirects its sign-in to `login.empowered.vote` instead of rendering its own form |
| 3 | validation-quests | `validation-quests-frontend` (separate repo) — same one-line redirect change |

⚠ Flipping `VITE_EMBEDDED_AUTH=true` on any production frontend is **STOP-AND-ASK** —
present staging results (see "Open items" below) before flipping it, and keep the hosted
redirect + `/login/classic` as fallbacks through the bake.

#### New/changed `/api/auth/*` endpoints (ev-accounts-api)

| Endpoint | Behavior |
|---|---|
| `POST /api/auth/workos/authenticate` | **New.** Headless WorkOS password grant, run server-side (needs `client_secret` = `WORKOS_API_KEY`). On success, sets the `ev_wos_session` httpOnly cookie and returns `{ access_token }`. On a pending state (`email_verification_required`, `mfa_required`) sets the `ev_wos_pending` httpOnly cookie and returns `{ status }` for the UI to resolve on the next call. Wrong email and wrong password both return 401 `INVALID_CREDENTIALS` (OWASP — no enumeration). Rate-limited by `authLimiter` (10 / 15 min per IP). |
| `POST /api/auth/workos/verify-email` | **New.** Second leg of the on-page signup-verification flow: reads the `ev_wos_pending` cookie, exchanges the emailed code via WorkOS's email-verification-code grant, clears the pending cookie, sets `ev_wos_session`, returns `{ access_token }`. Rate-limited by `authLimiter`. |
| `GET /api/auth/session` | **Changed.** Now checks the `ev_wos_session` cookie first — if present, refreshes through WorkOS (`grant_type=refresh_token`), rotates the cookie, and returns `{ access_token }`. Falls back to the existing Supabase `ev_session` path only when `ev_wos_session` is absent. Which cookie exists is the sole discriminator between the two issuers. |
| `POST /api/auth/logout` | **Changed.** Now clears `ev_wos_session` and `ev_wos_pending`, in addition to `ev_session`, unconditionally before the auth check. |
| `POST /api/auth/forgot-password` | **Changed.** Under `AUTHKIT_PRIMARY='true'`, sends WorkOS's `password_reset` email instead of Supabase's. Still always returns 200 (OWASP — no enumeration). |
| `POST /api/auth/reset-password` | **Changed.** Under `AUTHKIT_PRIMARY='true'`, confirms the reset against WorkOS (`password_reset/confirm`) instead of verifying a Supabase recovery `token_hash`. A WorkOS reset revokes all of that user's active WorkOS sessions. |

#### New cookies (httpOnly, domain = `COOKIE_DOMAIN`)

| Cookie | Lifetime | Set by | Purpose |
|---|---|---|---|
| `ev_wos_session` | 30 days | `/workos/authenticate`, `/workos/verify-email`, `GET /session` (rotated on each refresh) | WorkOS refresh token — the session itself, for headless-login users. Never touches browser JS storage. |
| `ev_wos_pending` | 15 minutes | `/workos/authenticate` (only on a pending status) | WorkOS pending-authentication token, single-use, consumed only by `/workos/verify-email`. |

Cross-app SSO for WorkOS users (Task 11) depends on **`COOKIE_DOMAIN=.empowered.vote`**
in prod (see the Backend env var table above) — the same requirement the existing
Supabase `ev_session` cookie already has.

#### Cross-app token handoff (feature apps: compass, VQ, essentials, …)

Feature apps that take a **bearer token** (not the cookie) redirect the user to
`accounts.empowered.vote/login?redirect=<app-url>` and expect to come back with the
token in the URL **hash** (`<app-url>#access_token=…`) — see CompassV2's
`src/lib/auth.js`. The login hub (`admin/src/pages/Login.tsx`) fulfills this:

- If the user **already has a session**, it hands the token back immediately (no form),
  reusing the session App bootstrap restored — it does **not** make its own
  `/api/auth/session` call, which would race the cookie rotation. A logged-in user who
  lands on `/login` with no `?redirect=` is sent to `/profile` instead of re-seeing the form.
- After a fresh login (embedded, classic, or the `?code=` return leg), `finishLogin`
  appends `#access_token=` to a `?redirect=` target.

**CompassV2 needs no change** — it already reads `#access_token`. **Validation-quests
still needs a small change in its own repo**: its WorkOS return leg uses the hosted
AuthKit SDK `?code=` callback, which the embedded hub does not produce; point its
sign-in at `accounts.empowered.vote/login?redirect=…` and read `#access_token` (or adopt
the shared-cookie `/api/auth/session`) instead. Until then VQ keeps using the hosted flow.

#### Open items — confirm on staging before prod

These are **not yet confirmed**. They are human-gated verification, not something to
attempt from this doc-only pass:

- **Exact WorkOS pending/error body field names.** `backend/src/lib/workosAuthService.ts`
  reads the discriminator defensively (`code`, falling back to `error`) so a field-name
  surprise degrades to a logged `WORKOS_ERROR` rather than a wrong success — but the real
  staging shapes for a verified login, an unverified login, and a wrong password are
  still unconfirmed. Adjust the matcher (and its unit test) if a name differs.
- **The password-reset email link target — RESOLVED in code.** WorkOS's server-side
  `password_reset` create does not auto-send an email and returns the raw
  `password_reset_token`; `sendWorkosPasswordReset` ignores WorkOS's hosted
  `password_reset_url` and emails **our own** link to
  `login.empowered.vote/reset-password?token_hash=…` (via `emailService.sendEmail`,
  no custom-domain add-on needed). Verify live in checklist step B6 — exercise
  `/api/auth/forgot-password` on a deployed build and confirm the email you receive links
  to our domain. (Note: the `workos-headless-smoke.mjs` script calls WorkOS directly, so
  its Case 4 still prints WorkOS's hosted URL — that field is deliberately unused.)
- **`COOKIE_DOMAIN` is `.empowered.vote` on the `ev-accounts-api` Render service in
  prod.** Check the Render env; do not change it without approval.
- **Staging cross-app login origin.** `app/src/pages/LoginPage.tsx`'s `LOGIN_ORIGIN`
  defaults to prod (`https://login.empowered.vote`) but now reads `VITE_LOGIN_ORIGIN`
  (build-time). To test cross-app SSO on staging, set `VITE_LOGIN_ORIGIN` on the staging
  app build to the staging login hub; otherwise a staging app bounces to the PRODUCTION
  login page. Leave it unset in prod.

See [`docs/HEADLESS-LOGIN-STAGING-CHECKLIST.md`](docs/HEADLESS-LOGIN-STAGING-CHECKLIST.md)
for the full pre-flight + per-origin acceptance checklist that closes these items.

### Monitoring failed logins at cutover

No app-level instrumentation is required — Render's own request logs carry the status
code, and a 401 on the login path is tagged `level=warning`. Via the Render MCP:

```
list_logs  resource=[<ev-accounts-api service id>]  type=[request]
           path=["/api/auth/login"]  statusCode=["401"]  startTime=<RFC3339>
```

⚠ **Baseline as of 2026-08-27 is ~0 human failures per week** — an 8-day window held
3 successful logins and 1 failure, and that failure was a smoke test
(`userAgent="node"`). At this volume "failed-login rate returns to baseline" is a weak
gate: one confused tester doubles it. Read the raw entries, not a rate.

---

## Step 1: Enable PostgreSQL Extensions

One-time setup. Run in Supabase Dashboard → SQL Editor:

```sql
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
```

PostGIS is required for Phase 19 (location infrastructure — district boundary lookups). pgcrypto is required for Phase 19 (encrypted coordinate storage via Supabase Vault). Enable both now to avoid a second deploy window when Phase 19 ships.

---

## Step 1b: PostgREST Schema Configuration

Supabase PostgREST must be configured to expose the connect, empower, and inform schemas.
The dashboard UI setting is NOT sufficient — PostgREST does not pick it up reliably.
Run this in Supabase Dashboard → SQL Editor:

```sql
ALTER ROLE authenticator SET pgrst.db_schemas TO 'public, connect, empower, inform';
NOTIFY pgrst, 'reload config';
```

This is required for any RPC or table in the connect/empower/inform schemas to be callable
via the Supabase JS client. Without it, calls to connect.award_gems, connect.promote_to_connected,
etc. will return 404.

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
026 → 027 → 028 → 029 → 030 → 031 → 032 → 033 → 034 → 035 → 036
```

Do not skip or reorder. Later migrations depend on columns and functions created by earlier ones.

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
psql "$DATABASE_URL" -f backend/migrations/030_decimal_compass_values.sql
psql "$DATABASE_URL" -f backend/migrations/031_location_schema.sql
psql "$DATABASE_URL" -f backend/migrations/032_location_rpcs.sql
psql "$DATABASE_URL" -f backend/migrations/033_politician_schema.sql
psql "$DATABASE_URL" -f backend/migrations/034_gem_idempotency.sql
psql "$DATABASE_URL" -f backend/migrations/035_tier_promotion.sql
psql "$DATABASE_URL" -f backend/migrations/036_signup_with_invite.sql
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

-- 030: migrate_guest_compass_state RPC exists
SELECT proname FROM pg_proc WHERE proname = 'migrate_guest_compass_state';
-- Expected: 1 row

-- 031: encrypted_lat column on connected_profiles
SELECT column_name FROM information_schema.columns
WHERE table_schema = 'connect' AND table_name = 'connected_profiles'
  AND column_name = 'encrypted_lat';
-- Expected: 1 row

-- 032: upsert_user_location RPC exists
SELECT proname FROM pg_proc WHERE proname = 'upsert_user_location';
-- Expected: 1 row

-- 033: district_type column on politicians
SELECT column_name FROM information_schema.columns
WHERE table_schema = 'inform' AND table_name = 'politicians'
  AND column_name = 'district_type';
-- Expected: 1 row

-- 034: award_gems RPC exists
SELECT proname FROM pg_proc WHERE proname = 'award_gems';
-- Expected: 1 row

-- 035: promote_to_connected RPC exists
SELECT proname FROM pg_proc WHERE proname = 'promote_to_connected';
-- Expected: 1 row

-- 036: signup_with_invite RPC exists
SELECT proname FROM pg_proc WHERE proname = 'signup_with_invite';
-- Expected: 1 row
```

All queries must return exactly 1 row before proceeding.

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
git commit -m "chore: regenerate database types after migrations 026-036"
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

### 030 rollback

```sql
DROP FUNCTION IF EXISTS inform.migrate_guest_compass_state(UUID, JSONB, INT[]);
DROP FUNCTION IF EXISTS inform.upsert_compass_answer(UUID, INT, NUMERIC, TEXT, TEXT);
-- Note: column type change (INT -> NUMERIC) is NOT easily reversible; leave columns as NUMERIC.
```

### 031 rollback

```sql
DROP TABLE IF EXISTS inform.district_boundaries;
ALTER TABLE connect.connected_profiles DROP COLUMN IF EXISTS encrypted_lat;
ALTER TABLE connect.connected_profiles DROP COLUMN IF EXISTS encrypted_lng;
ALTER TABLE connect.connected_profiles DROP COLUMN IF EXISTS location_consent;
ALTER TABLE connect.connected_profiles DROP COLUMN IF EXISTS location_set_at;
```

### 032 rollback

```sql
DROP FUNCTION IF EXISTS connect.upsert_user_location(UUID, FLOAT8, FLOAT8);
DROP FUNCTION IF EXISTS connect.resolve_user_jurisdiction(UUID);
```

### 033 rollback

```sql
DROP FUNCTION IF EXISTS public.admin_list_politicians(BOOLEAN, INT, INT);
ALTER TABLE inform.politicians DROP COLUMN IF EXISTS representing_city;
ALTER TABLE inform.politicians DROP COLUMN IF EXISTS representing_state;
ALTER TABLE inform.politicians DROP COLUMN IF EXISTS district_type;
ALTER TABLE inform.politicians DROP COLUMN IF EXISTS district_label;
ALTER TABLE inform.politicians DROP COLUMN IF EXISTS district_id;
ALTER TABLE inform.politicians DROP COLUMN IF EXISTS chamber_name;
ALTER TABLE inform.politicians DROP COLUMN IF EXISTS chamber_name_formal;
ALTER TABLE inform.politicians DROP COLUMN IF EXISTS government_name;
ALTER TABLE inform.politicians DROP COLUMN IF EXISTS is_vacant;
```

### 034 rollback

```sql
DROP FUNCTION IF EXISTS connect.award_gems(UUID, TEXT, INTEGER, TEXT, TEXT, UUID);
DROP INDEX IF EXISTS connect.idx_gem_transactions_idempotency_key;
ALTER TABLE connect.gem_transactions DROP COLUMN IF EXISTS idempotency_key;
```

### 035 rollback

```sql
DROP FUNCTION IF EXISTS connect.promote_to_connected(UUID, TEXT, UUID, TEXT);
ALTER TABLE empower.empowered_profiles DROP COLUMN IF EXISTS politician_id;
DROP TABLE IF EXISTS connect.tier_promotion_log;
```

### 036 rollback

```sql
DROP FUNCTION IF EXISTS connect.signup_with_invite(UUID, TEXT, TEXT);
DROP TABLE IF EXISTS public.access_requests;
```

Roll back in reverse order: 036, 035, 034, 033, 032, 031, 030, 029, 028, 027, 026.

---

## Common Pitfalls

1. **Wrong migrations folder.** Do NOT apply files from `supabase/migrations/`. Only apply `backend/migrations/026` through `036`. The `supabase/migrations/` folder contains older schema baseline files that are already applied.

2. **Wrong apply order.** Always apply 026 → 027 → ... → 036 in sequence. Later migrations reference columns and functions created by earlier ones.

3. **Pooler URL instead of direct connection.** The pooler (`pooler.supabase.com`, port 6543) does not support multi-statement transactions. Migration files contain multiple DDL statements that must run in a single connection. Always use the direct URL (`db.<ref>.supabase.co`, port 5432).

4. **VITE_API_URL set after build.** Vite inlines env vars at build time. Setting `VITE_API_URL` in Render after a build has no effect on the already-compiled assets. The variable must be present before the build starts. A wrong URL requires a full rebuild.

5. **Wrong script filename.** The migration script is `backend/scripts/applyMigrations.ts` (TypeScript, plural). There is no `applyMigration.js`. Use `npx tsx backend/scripts/applyMigrations.ts` or the `psql -f` fallback.

6. **Forgetting to regenerate types.** After running migrations, always regenerate `backend/src/types/database.types.ts` and commit it. Missing this step causes type drift between local dev and production.

7. **PostgREST schema config not applied.** Supabase dashboard UI changes to exposed schemas are not reliably picked up by PostgREST. Always run the `ALTER ROLE authenticator SET pgrst.db_schemas` command in Step 1b. Without it, calls to connect/empower/inform RPCs return 404.
