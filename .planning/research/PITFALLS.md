# PITFALLS — Tiered Account System on Supabase + Express

**Research type:** Project Research — Pitfalls dimension
**Project:** empowered-accounts (Empowered Vote)
**Date:** 2026-02-24 (original) / 2026-03-09 (extended: location infrastructure)
**Researcher:** gsd-project-researcher agent

---

## Purpose

This document captures the critical mistakes developers make when building tiered account systems on Supabase + Express, with specific focus on the civic platform context of Empowered Vote — where data leaks expose civic identity, partial state is a platform integrity failure, and invite chain abuse undermines social accountability.

Each pitfall includes: what goes wrong, warning signs, prevention strategy, and which development phase should address it.

---

## Pitfall Index

**Original (v1.0–v1.2 context):**

1. [RLS Policy Gaps — The anon key / service role boundary](#1-rls-policy-gaps--the-anon-key--service-role-boundary)
2. [RLS on JOIN and View Queries — Indirect data exposure](#2-rls-on-join-and-view-queries--indirect-data-exposure)
3. [Atomic Transactions in Supabase — Partial state writes](#3-atomic-transactions-in-supabase--partial-state-writes)
4. [Invite System Abuse Vectors](#4-invite-system-abuse-vectors)
5. [Cron Job Reliability on Render Free Tier](#5-cron-job-reliability-on-render-free-tier)
6. [Anonymous Compass Import Conflicts on Topic Version Change](#6-anonymous-compass-import-conflicts-on-topic-version-change)
7. [Schema Migration Mistakes with Additive Child Tables](#7-schema-migration-mistakes-with-additive-child-tables)
8. [Session and Token Edge Cases](#8-session-and-token-edge-cases)
9. [Admin Tool Security Mistakes](#9-admin-tool-security-mistakes)
10. [RLS Testing — Verifying your policies actually work](#10-rls-testing--verifying-your-policies-actually-work)

**Location Infrastructure (v1.3 context):**

11. [Vault Key Loss — Encrypted location data permanently unreadable](#11-vault-key-loss--encrypted-location-data-permanently-unreadable)
12. [pgsodium Deprecation — Wrong encryption primitive at the start](#12-pgsodium-deprecation--wrong-encryption-primitive-at-the-start)
13. [Raw pgcrypto Encrypt Functions — No integrity, no IV management](#13-raw-pgcrypto-encrypt-functions--no-integrity-no-iv-management)
14. [Statement Logging Leaks Cleartext Coordinates Into Supabase Logs](#14-statement-logging-leaks-cleartext-coordinates-into-supabase-logs)
15. [SRID 0 Geometry — ST_Contains silently returns false for all points](#15-srid-0-geometry--st_contains-silently-returns-false-for-all-points)
16. [ST_Contains Boundary Exclusion — Points on district edges return false](#16-st_contains-boundary-exclusion--points-on-district-edges-return-false)
17. [TIGER/Line SRID 4269 vs Input SRID 4326 — Boundary query uses wrong CRS](#17-tigerline-srid-4269-vs-input-srid-4326--boundary-query-uses-wrong-crs)
18. [Stale TIGER/Line Boundaries After Indiana Redistricting](#18-stale-tigerline-boundaries-after-indiana-redistricting)
19. [bytea Column Type Mangling via supabase-js](#19-bytea-column-type-mangling-via-supabase-js)
20. [RLS on Encrypted Columns — Raw bytea still readable if RLS is wrong](#20-rls-on-encrypted-columns--raw-bytea-still-readable-if-rls-is-wrong)
21. [Partial Location State During Connect Flow](#21-partial-location-state-during-connect-flow)
22. [Location Consent Revocation — Downstream features hold stale jurisdiction](#22-location-consent-revocation--downstream-features-hold-stale-jurisdiction)
23. [Geocoding Coordinates Outside Indiana Boundaries](#23-geocoding-coordinates-outside-indiana-boundaries)
24. [ST_MakePoint Argument Order — Longitude before latitude](#24-st_makepoint-argument-order--longitude-before-latitude)
25. [PostGIS Not Installed or Wrong Schema on Supabase](#25-postgis-not-installed-or-wrong-schema-on-supabase)

---

## 1. RLS Policy Gaps — The anon key / service role boundary

### What Goes Wrong

The most dangerous architectural misunderstanding in Supabase is believing that RLS protects all access. It does not protect service role access. When your Express backend uses the service role key, **RLS is completely bypassed** — intentionally and by design. This is correct for trusted server-side operations, but becomes catastrophic when:

- A route that should use scoped user context uses the service role client instead
- The service role client is used to "simplify" a complex RLS query, but the simplified version is later called from a path that shouldn't have full access
- The anon key is used client-side but a developer assumes the backend will "also check" — it won't if the backend uses service role
- Error handling falls through to a service role path that returns unscoped data

For Empowered Vote specifically: `tolerance_rating` and `legal_name` are the highest-risk fields. If any Express route queries these using the service role client without explicit column filtering, those fields can leak into responses that downstream code serializes to JSON — even if the frontend doesn't display them.

### Warning Signs

- Express backend has a single Supabase client instance initialized with the service role key, shared across all routes
- No consistent pattern distinguishing "service role for trusted writes" vs "user-scoped client for reads"
- Routes that return user profile data are not explicitly selecting column lists (using `select('*')`)
- `console.log(user)` or debug logging of full row objects anywhere near auth or profile handlers
- No column-level tests asserting that `tolerance_rating` and `legal_name` are absent from API responses

### Prevention Strategy

**Architectural rule:** Use two Supabase client instances in Express:
1. `supabaseAdmin` — service role key, used only for trusted writes (creating accounts, escalating tier, invalidating tokens). Never used for reads that return data to users.
2. `supabaseUserScoped` — created per-request using `createClient()` with the user's JWT set via `supabase.auth.setSession()` or by passing the JWT in the Authorization header. RLS is active.

```javascript
// Per-request scoped client pattern
function getScopedClient(req) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  const client = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: `Bearer ${token}` } }
  });
  return client;
}
```

**Column allowlists:** Never use `select('*')` on tables containing sensitive fields. Always enumerate columns explicitly. Create a shared constant:

```javascript
const SAFE_PROFILE_COLUMNS = 'id, username, tier, empowered_at, created_at';
// tolerance_rating and legal_name are NEVER in this list
```

**Phase:** Foundation (before any routes are written). Retrofitting this pattern is dangerous — you may miss routes.

---

## 2. RLS on JOIN and View Queries — Indirect data exposure

### What Goes Wrong

RLS policies apply per-table. When you JOIN tables or create database Views, RLS applies to each table individually at query time — but the **view** can expose data that bypasses intended restrictions if the view is defined with `SECURITY DEFINER` rather than `SECURITY INVOKER`.

`SECURITY DEFINER` views run as the view's creator (typically the postgres superuser), which **bypasses RLS on the underlying tables**. This is the default for many Supabase-created views and a frequent source of invisible data leaks.

Additional JOIN trap: if Table A has RLS allowing the current user to see a row, and that row has a foreign key to Table B (e.g., `inviter_id` → `users.id`), a JOIN to Table B will expose whatever columns of the inviter's row RLS allows the current user to see on Table B — which may be more than intended if Table B's RLS policy is overly permissive.

For Empowered Vote: an invite chain view that JOINs `users` to show inviter usernames could inadvertently expose `tolerance_rating` if Table B's RLS policy is `FOR SELECT USING (true)` (fully public).

### Warning Signs

- Any database View created via Supabase Studio rather than a migration — Studio defaults to `SECURITY DEFINER`
- Views that JOIN `users` or `profiles` tables and return more than a username/display alias
- RLS policy on a table using `USING (true)` — fully public read — on a table that contains any sensitive field
- No explicit column list in View definitions (`SELECT *` in a View)

### Prevention Strategy

- Always create views via migrations, not Studio, so you control `SECURITY INVOKER` explicitly
- Audit every view: `SELECT schemaname, viewname, definition FROM pg_views WHERE schemaname = 'public';`
- For invite chain displays, create a **purpose-built read-only view** that selects only `id` and `username` from the users table, with `SECURITY INVOKER`, and grant SELECT only on that view — not the underlying table
- Run this query to find SECURITY DEFINER functions/views that touch sensitive tables:

```sql
SELECT p.proname, p.prosecdef
FROM pg_proc p
WHERE p.prosecdef = true AND p.pronamespace = 'public'::regnamespace;
```

**Phase:** Foundation + any time a new view or function is added to migrations.

---

## 3. Atomic Transactions in Supabase — Partial state writes

### What Goes Wrong

Supabase's JavaScript client does not expose `BEGIN`/`COMMIT` directly. Developers commonly address multi-step writes by chaining `.from().insert()` calls — which are not atomic. If step 2 fails, step 1 has already committed.

For Empowered Vote, "empowering" a user involves at minimum: updating the user's tier, recording the empowerment event, crediting the inviter, and potentially updating quota counts. Any failure between these steps leaves the system in partial state — a user who is "partially empowered" is a platform integrity violation, not just a bug.

The specific failure modes:

1. **Network interruption** between Supabase write calls — first write commits, subsequent writes never arrive
2. **Application exception** in Express route handler — `try/catch` around the outer call doesn't undo committed writes
3. **Race condition** — two requests arrive simultaneously (duplicate invite redemptions), both pass validation, both write

### Prevention Strategy

**The correct pattern: PostgreSQL functions (RPC) with explicit transaction control.**

Wrap all multi-step writes in a PostgreSQL function called via `supabase.rpc()`. The function runs inside a single transaction — if any step raises an exception, the entire transaction rolls back.

```sql
CREATE OR REPLACE FUNCTION empower_user(
  p_user_id UUID,
  p_inviter_id UUID,
  p_invite_token TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- All of these run in one transaction; any RAISE rolls back all

  -- 1. Mark invite as used (with FOR UPDATE to prevent race)
  UPDATE invites
  SET used_at = NOW(), used_by = p_user_id
  WHERE token = p_invite_token AND used_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invite_already_used';
  END IF;

  -- 2. Upgrade user tier
  UPDATE user_profiles
  SET tier = 'empowered', empowered_at = NOW()
  WHERE id = p_user_id;

  -- 3. Record empowerment event
  INSERT INTO empowerment_events (user_id, inviter_id, invite_token, created_at)
  VALUES (p_user_id, p_inviter_id, p_invite_token, NOW());

  -- 4. Decrement inviter quota
  UPDATE user_profiles
  SET remaining_invites = remaining_invites - 1
  WHERE id = p_inviter_id AND remaining_invites > 0;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'inviter_quota_exceeded';
  END IF;
END;
$$;
```

Called from Express as:
```javascript
const { error } = await supabaseAdmin.rpc('empower_user', {
  p_user_id: userId,
  p_inviter_id: inviterId,
  p_invite_token: token
});
if (error) throw error;
```

**FOR UPDATE on invite rows** is the critical race condition prevention — it locks the row during the transaction so a concurrent request cannot also claim the same invite.

**Idempotency keys:** For operations triggered by external events (webhook, job), store an idempotency key in the database before processing, checked at transaction start.

**Phase:** Foundation — establish the RPC pattern before implementing any multi-step business logic. Do not allow chained `.from()` calls for state-changing operations.

---

## 4. Invite System Abuse Vectors

### What Goes Wrong

Invite systems are social accountability mechanisms. When they can be gamed, the social graph loses integrity. Common abuse vectors:

**1. Token enumeration**
If invite tokens are short, numeric, or predictable (e.g., sequential UUIDs from a seeded generator), attackers enumerate valid tokens. A valid token can be redeemed by anyone who finds it before the intended recipient.

**2. Replay attacks after "use"**
If the "mark invite used" and "upgrade user" steps are not atomic (see Pitfall 3), a race condition allows a token to be redeemed twice — two users empowered for one invite.

**3. Self-invitation loops**
A user creates a new account and invites themselves. Without checking that `inviter_id != invited_user_id` and that the new account's email/device fingerprint doesn't match the inviter, a single person can expand their tier through sock puppets.

**4. Quota bypass through timing**
If quota is checked in application code before the DB write (read-then-write without locking), two concurrent requests both pass the quota check and both write — doubling the impact of one invite allocation.

**5. Invite hoarding and resale**
Users accumulate unused invites (e.g., through referral bonuses) and sell access. This is harder to prevent technically but invite expiration and per-period rate limits reduce the incentive.

**6. Account deletion and re-registration**
User gets empowered, deletes account, re-registers with same invite token (if not properly invalidated). Token must be invalidated by token string, not by user_id.

**7. Email aliasing**
`user+1@gmail.com`, `user+2@gmail.com` all deliver to `user@gmail.com`. If uniqueness is enforced on raw email string rather than normalized email, one person can receive multiple invites.

### Warning Signs

- Invite tokens shorter than 32 characters of cryptographic randomness
- Quota check in Express middleware before DB write (not inside DB transaction)
- No `used_at` timestamp — relying on a boolean `is_used` flag that doesn't record when
- No email normalization (stripping `+` aliases and normalizing domain case) before uniqueness check
- No invite expiration — tokens valid indefinitely
- No rate limit on invite send endpoint

### Prevention Strategy

- **Token generation:** Use `crypto.randomBytes(32).toString('hex')` — 64-character hex token. Never sequential, never UUID without additional entropy.
- **Atomic claim (see Pitfall 3):** `UPDATE invites SET used_at = NOW() WHERE token = $1 AND used_at IS NULL` inside the RPC function. Check `NOT FOUND`.
- **Email normalization:** Before inserting any email, normalize: lowercase, strip `+tag` suffix (for Gmail/Google Workspace), strip dots from Gmail local part. Store normalized form for uniqueness check, store original for display.
- **Self-invitation guard:** DB constraint or RPC check: `inviter_id != invited_user_id`. Also check: does the new account's verified email domain match the inviter's? Flag for review.
- **Invite expiration:** `expires_at` column, set to `NOW() + interval '30 days'` at creation. RPC checks `expires_at > NOW()`.
- **Rate limits on invite send:** Express rate limiter middleware (e.g., `express-rate-limit`) keyed on `user_id`, not IP. Limit to N invites sent per 24h window regardless of quota balance.
- **Audit log:** Every invite creation, redemption attempt (success and failure), and quota change is logged with timestamp and actor. This is the social accountability record.

**Phase:** Invite system design (before first invite is ever created in any environment). Abuse vectors are easiest to close before the data model is locked.

---

## 5. Cron Job Reliability on Render Free Tier

### What Goes Wrong

Render free tier instances spin down after 15 minutes of inactivity. When the cron job trigger arrives (e.g., a scheduled request or internal timer), the instance may be:
- **Cold starting** — the process isn't running yet, the HTTP request times out before the job executes
- **Mid-restart** — a deploy or crash caused a restart at the exact moment the job was scheduled
- **Silently skipped** — the timer fires inside the process, but the process was restarted and the timer state was lost

For Empowered Vote, the calibration lapse cron job is specifically at risk. If it fails silently, users retain "Empowered" status past their calibration window, which is a platform integrity violation. Worse: because the job runs on a schedule, a silent failure may not be detected for the full interval (e.g., 24 hours).

Additional risk: **double-execution**. If a deploy occurs while a job is running, both the old and new instance may execute the job during the overlap window — causing double-lapses or double-notifications.

### Warning Signs

- Cron job is implemented as `setInterval()` or `node-cron` inside the Express process — process restart = timer lost
- No database record of "last successful run" for each job
- No alerting on job execution failure
- Render free tier with no paid dyno or external scheduler
- Job execution is not idempotent — running it twice in a row produces incorrect results

### Prevention Strategy

**Move the schedule trigger outside the process.** Options:

1. **Render Cron Jobs** (paid feature, but cheap) — Render makes an HTTP POST to your Express endpoint on schedule. Your endpoint executes the job. The trigger survives process restarts.
2. **External scheduler (e.g., Upstash QStash, Zeplo, GitHub Actions scheduled workflow)** — makes an authenticated HTTP request to your Express endpoint. Completely decoupled from your process lifecycle.
3. **Supabase pg_cron extension** — run the calibration lapse logic as a SQL function triggered by pg_cron inside the database. No Express process involvement. Most reliable for DB-only operations.

**Job idempotency pattern:**

```sql
-- calibration_lapse_runs table
CREATE TABLE calibration_lapse_runs (
  run_date DATE PRIMARY KEY,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  lapsed_count INTEGER
);

-- At job start (inside RPC):
INSERT INTO calibration_lapse_runs (run_date, started_at)
VALUES (CURRENT_DATE, NOW())
ON CONFLICT (run_date) DO NOTHING;

-- Only proceed if insert succeeded (this process "owns" today's run)
IF NOT FOUND THEN RETURN; END IF;
```

**Alerting:** After each scheduled job trigger, if `completed_at` is not set within N minutes, send an alert (Supabase webhook → notification service, or a simple monitoring ping).

**Cold start mitigation:** If staying on Render free tier, use an external uptime monitor (e.g., UptimeRobot free tier) to ping the service every 5 minutes — keeping it warm. This is not reliable for production but acceptable for early development.

**Phase:** Infrastructure setup, before calibration lapse logic is written. The scheduler architecture decision affects the cron implementation design.

---

## 6. Anonymous Compass Import Conflicts on Topic Version Change

### What Goes Wrong

When a user completes the Political Compass assessment anonymously and later creates/links an account, their anonymous responses are imported into their profile. The conflict scenario:

1. User completed compass in anonymous session with **topic version V1**
2. Topic version is updated to **V2** (questions changed, scale changed, or topic removed)
3. User registers and attempts to import — their V1 responses don't map to current topics
4. Import code assumes current topic IDs, writes stale responses, or silently drops responses

Worse case: the import code joins anonymous responses to current topics on `topic_id`, and a topic_id that existed in V1 now points to a **completely different question** in V2. The user's response is imported but represents a different question — silently corrupting their political profile.

For Empowered Vote: a corrupted compass profile affects how users are displayed to others and how the platform interprets their political positions. This is a civic accuracy problem.

**Version skew window:** the gap between when a user starts an anonymous session and when they register can be days or weeks — long enough for topic versions to change.

### Warning Signs

- Anonymous session responses stored with `topic_id` only, no `topic_version` snapshot
- Import code does `WHERE anonymous_responses.topic_id = current_topics.id` without version check
- No `version` column on the `topics` table
- Topic updates are done as `UPDATE topics SET ...` (in-place mutation) rather than versioned inserts
- No detection of "imported responses span multiple topic versions"

### Prevention Strategy

**Snapshot the topic version at response time:**

```sql
-- anonymous_responses table
ALTER TABLE anonymous_responses ADD COLUMN topic_version INTEGER NOT NULL;
ALTER TABLE anonymous_responses ADD COLUMN topic_snapshot JSONB;
-- Store {id, text, scale_min, scale_max} at time of response
```

**Version topics immutably:** Never update a topic in-place. Instead, deprecate and create:

```sql
-- topics table
CREATE TABLE topics (
  id UUID PRIMARY KEY,
  version INTEGER NOT NULL,
  parent_id UUID REFERENCES topics(id), -- links new version to old
  question_text TEXT NOT NULL,
  deprecated_at TIMESTAMPTZ
);
```

**Import logic:** At import time, check if the anonymous response's `topic_version` matches the current active version. If not:
- If the topic has a migration path (`parent_id` chain), apply it
- If no migration path, flag the response as "legacy — not imported" and show the user a message
- Never silently import a response to a mismatched topic

**Test case to write:** Create an anonymous session, change topic versions, then import — assert that the correct behavior (migration or graceful skip) occurs.

**Phase:** Data model design. The `topic_version` column must be in the schema before any anonymous responses are ever recorded. This cannot be retrofitted without data quality questions about existing anonymous sessions.

---

## 7. Schema Migration Mistakes with Additive Child Tables

### What Goes Wrong

Additive child table architectures (where new tiers add new tables rather than columns to existing tables) have a specific set of migration failure modes:

**1. FK constraint before parent row exists**
Migration adds a child table with a foreign key to a parent table that may not have rows yet — but the migration also tries to backfill the child table. If the backfill runs before parent rows are created in that environment (e.g., staging has no data), the migration appears to succeed but leaves orphaned expectations.

**2. Missing indexes on FK columns**
Every foreign key column should have an index. In PostgreSQL, FK constraints do not automatically create indexes (unlike primary keys). Queries that join child to parent on the FK column do full table scans. On a civic platform with a growing user base, this becomes a serious performance issue — but it only manifests at scale, after it's hard to change.

**3. Migration ordering in CI/CD**
If migrations are numbered and two developers create migration files in the same number range (e.g., both create `0042_*.sql`), one silently overwrites the other in CI. This is a lost migration — the table is never created in production.

**4. Non-atomic migration files**
A migration file that does two things (CREATE TABLE + INSERT seed data) where the INSERT fails in one environment (due to a constraint difference or missing reference data). The CREATE TABLE committed, the INSERT rolled back — but Supabase migration tracking marks the migration as "failed" and won't re-run it. The table exists but is unseeded.

**5. Column default value changes on populated tables**
Adding `NOT NULL` columns without a `DEFAULT` clause to tables that already have rows fails immediately. In development (empty tables), this is invisible — the migration runs fine. In production (populated tables), the migration fails and blocks deployment.

**6. Rollback safety**
Most `ALTER TABLE` operations in PostgreSQL cannot be simply "rolled back" with a down migration if they were already committed. Dropping a column that was added, then re-adding it, loses data. Teams that treat down migrations as reliable rollback mechanisms get burned in production.

### Warning Signs

- Migration files without explicit `BEGIN`/`COMMIT` wrapping (relying on auto-commit behavior)
- FK columns with no corresponding `CREATE INDEX`
- No migration file naming convention that prevents collision (e.g., timestamp-prefixed rather than sequential numbered)
- `NOT NULL` columns added without `DEFAULT` values in the same migration
- Migration files that mix DDL and DML (table creation + data insertion)

### Prevention Strategy

**Migration file structure:**

```sql
-- ALWAYS wrap in transaction for atomicity
BEGIN;

-- DDL: structure changes
CREATE TABLE empowered_profiles (
  id UUID PRIMARY KEY REFERENCES user_profiles(id) ON DELETE CASCADE,
  legal_name TEXT NOT NULL,
  verified_at TIMESTAMPTZ,
  tolerance_rating NUMERIC(3,2)
);

-- Index every FK column explicitly
CREATE INDEX idx_empowered_profiles_id ON empowered_profiles(id);

-- Any DML (seed data) goes LAST, after all DDL
-- INSERT seed data here if needed

COMMIT;
```

**Naming convention:** Use timestamp prefixes: `20260224_001_create_empowered_profiles.sql`. Timestamps from two different developers on the same day get a sequence suffix — collision is visible.

**NOT NULL columns:** Always provide a DEFAULT in the migration, even if you intend to remove the default later:

```sql
-- Add with default (safe on populated table)
ALTER TABLE user_profiles ADD COLUMN calibration_due_at TIMESTAMPTZ DEFAULT NOW();
-- Then remove the default if desired (no data impact)
ALTER TABLE user_profiles ALTER COLUMN calibration_due_at DROP DEFAULT;
```

**Rollback strategy:** For the child table architecture, rollbacks should be planned as "forward fixes" (a new migration that undoes the previous one), not down migrations. Document this explicitly in migration headers.

**Sensitive column placement:** `tolerance_rating` and `legal_name` must live in a child table (`empowered_profiles`) that is only accessible to service role, not in `user_profiles` which is readable by scoped user clients. The FK relationship enforces this separation structurally — a user client querying `user_profiles` cannot accidentally get these fields unless they JOIN to `empowered_profiles`, which RLS should block.

**Phase:** Every migration, from the first. Retroactively fixing migration hygiene after tables have data is painful and risky.

---

## 8. Session and Token Edge Cases

### What Goes Wrong

Supabase Auth JWTs have a default 1-hour expiry with refresh token rotation. Edge cases that bite Express backends:

**1. Token used after Supabase session invalidation**
When you call `supabase.auth.admin.deleteUser()` or revoke a session server-side, existing JWTs may still be valid for up to 1 hour (until they expire). A user whose account is suspended continues to make valid authenticated requests during this window.

**2. Tier stored in JWT claims vs. database**
If you store user tier in JWT custom claims (via a Supabase Auth hook), those claims are stale until the user's token refreshes. A user who is downgraded from Empowered to Basic continues to have the Empowered claim in their JWT until refresh. Authorization decisions made from the JWT claim rather than the database are stale.

**3. Refresh token rotation race condition**
If a user makes two concurrent requests (common with frontend React apps making parallel API calls), both may attempt to refresh the same refresh token. The first refresh invalidates the token; the second refresh fails and the user is logged out unexpectedly.

**4. Service role key exposure**
The service role key in Express `.env` bypasses all RLS. If it's ever logged (e.g., in request logs that include all env vars), committed to source control, or returned in an error response, any actor with it has unrestricted database access.

**5. JWT verification in Express without audience/issuer check**
Using a JWT library that only verifies the signature (not `iss` or `aud` claims) means a JWT from a different Supabase project (or a hand-crafted token with the same signing key) would pass verification.

### Warning Signs

- Authorization checks in Express read tier from `req.user.tier` (from JWT) rather than querying the database
- No short-circuit for suspended/deleted users that checks database state on each request (or on sensitive routes)
- `.env` file committed to git history (check with `git log --all --full-history -- .env`)
- JWT verification code uses only `jwt.verify(token, secret)` without options for `audience` or `issuer`

### Prevention Strategy

- **Tier from database, not JWT:** On any route that makes a tier-sensitive decision, query `user_profiles` for the current tier. Cache it in the request object after first fetch, not across requests.
- **Suspension short-circuit:** Add Express middleware that checks `user_profiles.is_suspended` (or equivalent) on each authenticated request — not just tier. This is the only way to enforce immediate account suspension within the JWT window.
- **Refresh token concurrency:** Implement a per-user mutex in Express (using a simple in-memory map with `async-mutex` or Redis lock) around token refresh operations. Or instruct the frontend to serialize refresh calls.
- **Service role key hygiene:** Service role key only in `.env`, in `.gitignore`, never logged, never in error responses. Add a startup check: `if (process.env.SUPABASE_SERVICE_ROLE_KEY) { validateKeyFormat(); }` — fail fast if misconfigured.
- **JWT verification options:**

```javascript
const decoded = jwt.verify(token, SUPABASE_JWT_SECRET, {
  issuer: `https://${SUPABASE_PROJECT_REF}.supabase.co/auth/v1`,
  audience: 'authenticated'
});
```

**Phase:** Foundation. JWT verification options and the "tier from database" rule must be established before any route is protected.

---

## 9. Admin Tool Security Mistakes

### What Goes Wrong

Admin tools that use the service role key are the highest-privilege surface in the system. Common mistakes:

**1. Admin endpoints without authentication**
An Express route like `/admin/suspend-user` protected only by "this is an internal URL" or an IP allowlist — neither is reliable.

**2. Admin endpoints authenticated but not authorized**
The admin endpoint validates that the request has a valid JWT, but doesn't verify that the JWT belongs to an admin user. Any authenticated user who discovers the endpoint can call it.

**3. Admin actions without audit log**
Tier changes, suspensions, empowerment grants, and invite quota adjustments made through admin tools leave no record of who took the action and when.

**4. Admin tool using anon key**
If an admin interface (e.g., an internal dashboard) is built to use the anon key with RLS, and an admin role is granted too broadly in RLS policies, regular users may be able to escalate to admin-accessible data by manipulating requests.

**5. Bulk operations without dry-run**
Admin tools that can affect many rows (e.g., "lapse all users past calibration date") run immediately without confirmation or preview — one mistake lapses thousands of users incorrectly.

### Warning Signs

- Admin routes in the same Express router as user routes, only distinguished by a URL prefix
- No `role: 'admin'` check against the database after JWT verification
- No `admin_audit_log` table
- Admin actions that touch multiple users do not return a count before executing

### Prevention Strategy

- **Separate admin router with dedicated middleware:**

```javascript
// adminAuth middleware
async function adminAuth(req, res, next) {
  const user = await verifyJWT(req); // standard JWT check
  const { data: profile } = await supabaseAdmin
    .from('user_profiles')
    .select('role')
    .eq('id', user.id)
    .single();

  if (profile?.role !== 'admin') return res.status(403).json({ error: 'Forbidden' });
  req.adminUser = user;
  next();
}
```

- **Audit log on every admin action:**

```javascript
await supabaseAdmin.from('admin_audit_log').insert({
  actor_id: req.adminUser.id,
  action: 'suspend_user',
  target_id: userId,
  metadata: { reason },
  created_at: new Date()
});
```

- **Dry-run pattern for bulk operations:** Every bulk admin endpoint accepts a `?dryRun=true` parameter that returns what would be affected without committing. Force operators to see the count before executing.

**Phase:** Admin tools (likely a later phase), but the `admin_audit_log` table and `adminAuth` middleware should be scaffolded in Foundation — even if admin routes don't exist yet.

---

## 10. RLS Testing — Verifying Your Policies Actually Work

### What Goes Wrong

The most common RLS pitfall is not a specific policy mistake — it's never verifying that your policies work at all. Teams write RLS policies, they look correct in the dashboard, and they're never tested end-to-end. The policies may have typos in column names, incorrect operator precedence, or reference `auth.uid()` when the request is coming through service role (where `auth.uid()` is NULL).

For Empowered Vote, the platform principle is "RLS is primary defense, application is secondary." An untested RLS policy is no defense at all.

### Prevention Strategy

**Test RLS directly in PostgreSQL, impersonating users:**

```sql
-- Test that user B cannot see user A's sensitive data
SET LOCAL role TO authenticated;
SET LOCAL "request.jwt.claims" TO '{"sub": "user-b-uuid", "role": "authenticated"}';

SELECT tolerance_rating FROM empowered_profiles WHERE id = 'user-a-uuid';
-- Should return 0 rows

-- Test that user A can see their own data
SET LOCAL "request.jwt.claims" TO '{"sub": "user-a-uuid", "role": "authenticated"}';
SELECT tolerance_rating FROM empowered_profiles WHERE id = 'user-a-uuid';
-- Should return 1 row
```

These tests can be written as `pgTAP` tests in a `tests/rls/` directory and run against a local Supabase dev environment.

**Integration tests from the application layer:**

Write Express integration tests (e.g., with `supertest`) that:
1. Create two test users (User A and User B) with known IDs
2. Authenticate as User A, make a GET request to a profile endpoint for User B
3. Assert that `tolerance_rating` and `legal_name` are absent from the response body
4. Assert HTTP 200 is returned (not 403 — RLS returning 0 rows is different from a 403)

The "RLS returns 0 rows, not 403" behavior is important: your application code must handle the case where a query returns no rows not because of a bug but because RLS filtered the result. Don't treat "0 rows" as an error that falls back to a less-secure path.

**Mandatory RLS policy checklist per table:**

For each table containing sensitive data, verify:
- [ ] `FOR SELECT` policy exists and uses `auth.uid()` correctly
- [ ] No `FOR SELECT USING (true)` (fully public) on any table with sensitive columns
- [ ] `FOR UPDATE` and `FOR DELETE` policies exist and are not accidentally permissive
- [ ] Service role bypass is intentional (document why in a comment on the policy)
- [ ] Policy tested via SQL SET LOCAL impersonation AND via application-layer integration test

**Phase:** Every migration that introduces a new table with sensitive data must include a corresponding RLS policy test. This is a development practice, not a one-time task.

---

---

# Location Infrastructure Pitfalls (v1.3)

**Context:** These pitfalls apply specifically to the encrypted lat/lng storage + PostGIS jurisdiction resolution feature being built in v1.3. Architecture decisions already made: lat/lng stored as `bytea` (Vault-encrypted), all reads/writes via `SECURITY DEFINER` RPCs with `SET search_path = ''`, `resolve_user_jurisdiction` RPC decrypts → `ST_Contains` → returns jurisdiction struct, TIGER/Line Indiana boundaries in `inform.district_boundaries`.

---

## 11. Vault Key Loss — Encrypted location data permanently unreadable

### What Goes Wrong

Supabase Vault encrypts data using a root key stored in Supabase's backend systems, separate from the database. If the Vault key becomes inaccessible — Supabase project deletion, catastrophic infrastructure failure, or key management error — all data encrypted with that key becomes permanently unreadable. There is no cryptographic recovery path. No key means no decrypt, ever.

Concretely for this feature: if `location_encrypted` bytea columns on `connected_profiles` use a Vault-managed key and that key is lost, every user's location is permanently gone. The rows still exist with ciphertext, but decryption is impossible.

Supabase documentation explicitly notes that "Supabase generates and preserves your project's root key behind the scenes" but does not document what happens to user data if a project is deleted or the key is rotated incorrectly. This is the most catastrophic failure mode and the documentation gap is real.

### Warning Signs

- No documented procedure for what happens to encrypted data if the Supabase project is deleted
- No separate backup of the key ID or any key metadata
- Encrypted columns added to tables without a documented key recovery process
- Location data encrypted with the same key as unrelated application secrets in the Vault (one key for everything = one failure point for everything)

### Prevention Strategy

**Use a dedicated Vault key for location data** — not the same key used for other application secrets. Isolation means a key management mistake in one domain doesn't affect another.

```sql
-- Create a named key specifically for location data
SELECT vault.create_secret('location-encryption-key-v1', 'location_key');
-- Store the returned key_id in application config as LOCATION_VAULT_KEY_ID
```

**Document the key ID in your `.env.example` and deployment runbook.** The key ID is not sensitive — only the key itself is secret and Supabase holds it. But you need the ID to reference the key in RPCs, and if you lose the ID you cannot construct the decryption call.

**Design for key rotation before you need it.** The column schema should include a `key_version` field alongside `location_encrypted`:

```sql
ALTER TABLE connect.connected_profiles
  ADD COLUMN location_encrypted BYTEA,
  ADD COLUMN location_key_version INTEGER DEFAULT 1,
  ADD COLUMN location_nonce BYTEA;
```

When Supabase rotates the underlying key or you introduce key v2, the `location_key_version` field tells the decrypt RPC which key to use. Re-encrypt rows incrementally (background job) rather than all at once.

**Communicate the limitation to product.** Location data encrypted with Vault is "best effort durable" — if Supabase loses the key, the data is gone. If location history is required for legal compliance or data portability, a separate plaintext export capability (under strict access controls) may be required. This is a product decision, not just a technical one.

**Phase:** Location schema phase, before any migration is written. Key naming, versioning column, and documented recovery procedure must exist before the first encrypted row is stored.

---

## 12. pgsodium Deprecation — Wrong encryption primitive at the start

### What Goes Wrong

Supabase explicitly states that pgsodium is "pending deprecation" and that they "do not recommend any new usage of pgsodium." Specifically, **Transparent Column Encryption (TCE)** and **Server Key Management** from pgsodium are flagged as having "high level of operational complexity and misconfiguration risk" and should not be used on the Supabase platform.

If the location encryption implementation uses pgsodium's TCE approach (e.g., `SECURITY LABEL FOR pgsodium ON COLUMN ... IS '...'`), that code will need to be migrated away from pgsodium as Supabase deprecates it. This creates a future forced migration while live encrypted data exists — exactly the worst time to change encryption implementations.

The Vault extension's API will remain stable through the pgsodium deprecation (Supabase will swap internals), so **Vault is the correct primitive to build on**, not raw pgsodium calls.

### Warning Signs

- Any migration or RPC using `SECURITY LABEL FOR pgsodium ON COLUMN`
- Direct calls to `pgsodium.crypto_secretbox()` or `pgsodium.crypto_secretbox_open()` in encryption RPCs
- Code that references `pgsodium.crypto_aead_det_encrypt()` or similar pgsodium-specific functions directly

### Prevention Strategy

**Build on Vault, not pgsodium directly.** The encrypt/decrypt RPC should use `vault.create_secret()` and reference secrets by key ID, not by calling pgsodium functions directly. Vault's API is the stable interface Supabase commits to maintaining.

If the architecture requires storing encrypted `bytea` directly in a column (rather than in the Vault secrets table), use `pgcrypto`'s PGP functions (not raw encrypt) or implement at the application layer before the RPC is called — not via pgsodium TCE.

**Phase:** Architecture decision point before writing the first encryption migration. Once an encryption mechanism is in place with live data, changing it requires a re-encryption migration, which is operationally complex.

---

## 13. Raw pgcrypto Encrypt Functions — No integrity, no IV management

### What Goes Wrong

PostgreSQL's `pgcrypto` extension provides raw encryption functions (`encrypt()`, `decrypt()`, `encrypt_iv()`, `decrypt_iv()`). The official PostgreSQL documentation explicitly warns against using them:

> "The raw encryption functions have major problems: they use the user key directly as the cipher key, don't provide any integrity checking for encrypted data, and expect that users manage all encryption parameters themselves, even IV."

For IV specifically: if `encrypt()` is called without the `_iv` variant, **the IV defaults to all zeros**. An all-zeros IV with the same key means the same plaintext always produces the same ciphertext — an attacker who obtains two ciphertexts can determine if two users have the same location without decrypting either. For a civic platform where location privacy is the entire point, this is a fundamental failure.

Even with `encrypt_iv()`, if the developer generates the IV once and reuses it (e.g., storing a static nonce in a constant), the same vulnerability applies.

**There is no integrity check** in raw pgcrypto encryption. An attacker who can write to the database can modify the ciphertext, and the decrypt call will silently succeed, returning garbage coordinates. The `resolve_user_jurisdiction` RPC would then run `ST_Contains` on invalid coordinates and potentially return a wrong jurisdiction — or crash silently.

### Warning Signs

- Any RPC using `pgcrypto.encrypt()` or `pgcrypto.decrypt()` (raw, not PGP)
- A stored `nonce` column that never changes between rows — same IV for all users
- No authentication tag or HMAC alongside the ciphertext to verify integrity before decrypt
- `encrypt_iv()` called with a hardcoded or static IV value

### Prevention Strategy

**Use Vault's managed encryption instead of raw pgcrypto.** Vault uses authenticated encryption (AEAD) internally, which provides both confidentiality and integrity. You cannot "decrypt" tampered ciphertext without an error — the integrity check fails first.

If a custom bytea encryption approach is required (because you need to store ciphertext directly in a column rather than the Vault secrets table), use **pgcrypto's PGP functions** (`pgp_sym_encrypt` / `pgp_sym_decrypt`) rather than raw `encrypt`/`decrypt`. PGP functions handle IV generation internally and include integrity verification.

**Nonce/IV generation per-row, not per-schema:** If any nonce-based approach is used, generate a fresh nonce for every encrypt call using `gen_random_bytes(24)` and store it in a companion `location_nonce BYTEA` column. The nonce is not secret and can be stored in plaintext.

```sql
-- Correct pattern: fresh nonce per row, stored alongside ciphertext
UPDATE connect.connected_profiles
SET
  location_encrypted = pgp_sym_encrypt(
    lat_lng_json::text,
    vault_key_value,
    'cipher-algo=aes256'
  ),
  location_updated_at = NOW()
WHERE user_id = p_user_id;
```

**Phase:** Encryption RPC implementation. Must be reviewed before the first migration creates the encrypted column.

---

## 14. Statement Logging Leaks Cleartext Coordinates Into Supabase Logs

### What Goes Wrong

Supabase logs SQL statement text by default. When an RPC that accepts plaintext coordinates (e.g., `store_user_location(p_lat FLOAT, p_lng FLOAT, ...)`) is called, the plaintext coordinate values appear in the Supabase statement log — even though the coordinates are encrypted in the database immediately afterward.

The log entry looks like:
```
STATEMENT: SELECT store_user_location(39.165325, -86.526386, 'v1')
```

This means the exact coordinates of every user who stores their location are stored in plaintext in Supabase's logging infrastructure, defeating the entire purpose of encryption.

Supabase explicitly warns about this in the context of Vault secrets: "When you insert secrets into the vault table with an INSERT statement, those statements get logged by default into the Supabase logs. Since this would mean your secrets are stored unencrypted in the logs, you should turn off statement logging."

Note: Supabase does not support configuring `pgaudit.log_parameter` precisely because it would log secrets from encrypted columns — they've blocked that specific pgaudit configuration to prevent this problem. But the statement logging issue with RPC parameters remains.

### Warning Signs

- `store_user_location` or any equivalent RPC accepts lat/lng as float parameters (plaintext in call)
- Supabase statement logging not explicitly reviewed before location feature ships
- No documentation of what is logged and what is not in the deployment runbook

### Prevention Strategy

**Encrypt coordinates server-side before the RPC call, not inside the RPC.** If encryption happens in the Express layer (using the Vault API to encrypt a JSON string containing lat/lng before sending to the DB), then the RPC call's parameters contain only ciphertext — which is meaningless in logs.

Alternatively: if encryption must happen inside the RPC, **pass the address string** (not raw coordinates) to the DB and have the RPC encrypt the result immediately without logging intermediate values. However, the address string is itself sensitive.

**The cleanest approach for this architecture:** Geocode server-side in Express (address → lat/lng), call `vault.create_secret()` to encrypt the coordinate pair as a JSON string via the Vault HTTP API from the Express service, store only the vault secret ID in the database column (not the ciphertext directly). The secret ID is meaningless in logs.

**Practical mitigation if direct bytea storage is required:** Disable statement logging for the location-related RPCs using `SET log_statement = 'none'` within the function body (requires superuser-equivalent permissions on Supabase, which may not be available — verify before planning on this approach).

**Phase:** Location schema design, before any RPC interface is defined. The logging behavior affects how the RPC contract must be structured.

---

## 15. SRID 0 Geometry — ST_Contains silently returns false for all points

### What Goes Wrong

PostGIS's `ST_MakePoint(lng, lat)` constructs a geometry with **SRID 0** by default — meaning "undefined coordinate system." If TIGER/Line district boundaries are loaded with SRID 4269 or 4326, and the user's point is constructed without explicitly setting the SRID, PostGIS 3.x throws an error on mismatched SRIDs:

```
ERROR: Operation on mixed SRID geometries (Point, 0) != (Polygon, 4326)
```

Earlier behavior (pre-3.x) would silently return false. Either way the query produces wrong results: either an error that crashes the RPC, or a false return that tells every user they are in no district.

The issue is subtle because the math is correct — the coordinates are right, just the metadata (SRID) is missing. Everything appears to work in development if boundaries were accidentally loaded as SRID 0 too (both sides unspecified, PostGIS compares 0 == 0 and proceeds with possibly wrong geometry).

### Warning Signs

- `ST_MakePoint(lng, lat)` used in the `resolve_user_jurisdiction` RPC without wrapping in `ST_SetSRID(..., 4326)`
- `ST_GeomFromText('POINT(...)', 4326)` used inconsistently (sometimes with SRID arg, sometimes without)
- TIGER/Line boundaries loaded via `shp2pgsql` without the `-s 4269` flag
- No test that verifies a known Monroe County address returns the correct district from the loaded boundaries
- `SELECT ST_SRID(geom) FROM inform.district_boundaries LIMIT 1` returns 0

### Prevention Strategy

**Always explicit SRID on point construction.** The `resolve_user_jurisdiction` RPC must construct the point as:

```sql
ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)
```

Never `ST_MakePoint(p_lng, p_lat)` alone — that produces SRID 0.

**Load TIGER/Line boundaries with explicit SRID.** When running `shp2pgsql`, always specify the source SRID:

```bash
shp2pgsql -s 4269 tl_2023_18_sldu.shp inform.district_boundaries | psql ...
```

TIGER/Line data is in NAD83 (SRID 4269). For Indiana, NAD83 and WGS84 (4326) are practically identical (sub-meter difference), so storing boundaries as 4326 is acceptable — but the import must use `-s 4269:4326` to reproject during import if you want to unify all geometry under one SRID.

**Write a smoke test migration.** After loading Indiana boundaries, add a verification query to the deployment runbook:

```sql
-- Verify Monroe County courthouse is in Indiana District 61 (expected result)
SELECT district_name
FROM inform.district_boundaries
WHERE ST_Contains(
  geom,
  ST_SetSRID(ST_MakePoint(-86.5264, 39.1653), 4326)
);
-- Should return at least one row
```

**Phase:** Boundary data loading migration and RPC implementation. Test before any user-facing endpoint is built on top of it.

---

## 16. ST_Contains Boundary Exclusion — Points on district edges return false

### What Goes Wrong

`ST_Contains` has a specific mathematical behavior with boundary points: **a polygon does not contain points on its own boundary**. The PostGIS documentation states: "polygons and lines do not contain lines and points lying fully in their boundary."

For a civic platform, this means: a user whose geocoded address happens to fall exactly on a district boundary line (e.g., they live on a street that forms the border between two districts) will receive `false` from `ST_Contains` for both neighboring districts. `resolve_user_jurisdiction` returns null for a valid Indiana address.

In practice this is rare — geocoded coordinates are rarely exact boundary vertices — but it is real, especially for addresses on major roads that form county or district boundaries, or when the geocoder snaps coordinates to a road centerline that coincides with a boundary.

The correct alternative is `ST_Covers`, which uses the definition "no point of B lies outside A" and correctly returns true for boundary points.

### Warning Signs

- `resolve_user_jurisdiction` returns null for some valid Indiana addresses in testing
- Testing only with addresses clearly in the interior of districts, not addresses on boundaries
- No handling in the RPC for the case where `ST_Contains` returns zero matching districts for a valid coordinate

### Prevention Strategy

**Use `ST_Covers` instead of `ST_Contains` for point-in-polygon jurisdiction lookup:**

```sql
-- In resolve_user_jurisdiction RPC:
SELECT district_type, district_name, district_id
FROM inform.district_boundaries
WHERE ST_Covers(geom, ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326));
```

`ST_Covers` is slightly more expensive than `ST_Contains` but the difference is negligible for the GIST spatial index-assisted queries this RPC will use.

**Add graceful handling for no-match.** Even with `ST_Covers`, some edge cases return zero districts (unincorporated areas, boundary precision gaps between loaded shapefiles). The RPC should return a partial jurisdiction struct with `null` for unknown fields rather than throwing an error — and the Express handler should return a structured response indicating "location stored, jurisdiction resolution pending manual review" rather than a 500.

**Phase:** RPC implementation. Simple one-word change from `ST_Contains` to `ST_Covers`. Establish as project standard now so it's not missed.

---

## 17. TIGER/Line SRID 4269 vs Input SRID 4326 — Boundary query uses wrong CRS

### What Goes Wrong

TIGER/Line shapefiles are published in **NAD83 (SRID 4269)**, not WGS84 (SRID 4326). If district boundaries are loaded into PostGIS with their native SRID 4269 and the incoming user point is constructed as SRID 4326, PostGIS 3.x raises an error on mismatched SRIDs. If somehow the comparison proceeds with mismatched CRS, coordinate system differences cause spatial queries to produce incorrect results.

In Indiana specifically, the practical difference between NAD83 and WGS84 is sub-meter (roughly 1 meter at most) — small enough that for district-level jurisdiction resolution (districts are miles wide), the CRS difference does not affect correctness of results. But PostGIS still treats them as different SRIDs and will error unless handled.

### Warning Signs

- `SELECT ST_SRID(geom) FROM inform.district_boundaries LIMIT 1` returns 4269 while point construction uses 4326
- `shp2pgsql` command used without `-s 4269:4326` (reproject on import) or an explicit `ST_Transform` call in the RPC
- No documented SRID strategy in the boundary loading migration comments

### Prevention Strategy

**Establish a single SRID for all spatial data in this system: 4326.** Reproject at import time using `shp2pgsql`'s `-s from:to` syntax:

```bash
# Reproject from NAD83 to WGS84 during import
shp2pgsql -s 4269:4326 tl_2023_18_sldu.shp inform.district_boundaries_sldu | psql ...
```

After import, verify:
```sql
SELECT ST_SRID(geom) FROM inform.district_boundaries LIMIT 1;
-- Should return 4326
```

**Alternative:** Load with native SRID 4269 and use `ST_Transform` in the RPC to convert the input point:

```sql
-- In RPC: transform input point to match boundary SRID
WHERE ST_Covers(
  geom,
  ST_Transform(ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326), 4269)
)
```

This approach is correct but adds complexity. Reprojecting on import is simpler.

**Phase:** Boundary data loading migration. Document the chosen SRID strategy in a comment in the migration file so future boundary updates follow the same approach.

---

## 18. Stale TIGER/Line Boundaries After Indiana Redistricting

### What Goes Wrong

Indiana redistricted in 2021 (effective 2022 election). TIGER/Line shapefiles are released annually by the Census Bureau, and the 2021 redistricting is reflected in 2022+ shapefiles. If older shapefiles (pre-2022) are used, some district boundaries will be wrong.

More critically: Indiana attempted a mid-decade redistricting in late 2025. The state House approved new congressional maps (HB 1032) in October 2025; the state Senate rejected them in December 2025. The current maps remain the 2021-drawn districts. However, **future redistricting is possible**, and any loaded TIGER/Line boundaries will become stale if new maps are enacted.

For a civic platform that tells users which district they're in, returning an incorrect district is a trust-destroying error — particularly for Empowered users who represent constituents.

### Warning Signs

- TIGER/Line shapefiles used without a year documented in the migration file name or comment
- No `boundary_vintage` column on `inform.district_boundaries` to track which year's data is loaded
- No documented process for updating boundaries when redistricting occurs
- Using pre-2022 shapefiles (which reflect pre-redistricting Indiana districts)

### Prevention Strategy

**Document the vintage in the migration.** Name the migration explicitly: `030_load_indiana_boundaries_tiger2023.sql`. Add a comment at the top: `-- Source: TIGER/Line 2023, retrieved YYYY-MM-DD from census.gov/geo/maps-data/data/tiger-line.html`.

**Add a `boundary_vintage` column to `inform.district_boundaries`:**

```sql
ALTER TABLE inform.district_boundaries ADD COLUMN boundary_vintage INTEGER NOT NULL DEFAULT 2023;
```

This allows querying which year's data is in use and simplifies partial updates.

**Use 2023 or newer TIGER/Line files for the initial load.** As of this writing (March 2026), TIGER/Line 2023 data reflects the 2022 redistricting. 2024 shapefiles may also be available from the Census Bureau.

**Plan for future boundary updates.** When redistricting occurs, the update path is: load new shapefiles into a staging table, validate against known test coordinates, swap the production table in a migration. Because boundaries are loaded data (not user-generated), this is a data migration, not a schema migration — it can be done without downtime.

**Phase:** Boundary data loading migration. Vintage documentation is a 30-second addition with long-term operational value.

---

## 19. bytea Column Type Mangling via supabase-js

### What Goes Wrong

The Supabase JavaScript client does not automatically handle binary serialization for `bytea` columns. When you pass data intended for a `bytea` column:

- A `Uint8Array` passed directly gets converted to its string representation (`[1,2,3]`), storing the ASCII codes of those characters — completely wrong
- PostgreSQL returns bytea columns in hex format (`\xdeadbeef`), not as a Buffer or Uint8Array

In the location infrastructure context: if any code path reads the `location_encrypted bytea` column via supabase-js rather than through an RPC, TypeScript will type the value as `string` (it receives `\x...` hex). If code then tries to pass that string directly back to a decrypt function expecting binary, the decrypt call receives wrong input and either crashes or returns garbage.

The TypeScript generated types (`database.types.ts`) will type `bytea` columns as `string`, not `Buffer` — which is technically accurate (it's a hex string) but easy to misuse.

### Warning Signs

- Any code that reads `location_encrypted` directly via `.from('connected_profiles').select('location_encrypted')` rather than through the `resolve_user_jurisdiction` RPC
- TypeScript showing `location_encrypted: string` in generated types and that value being passed without transformation to any decrypt call
- Tests that write fake bytea data as a JavaScript string without hex encoding
- `console.log(locationEncrypted)` showing `\x...` strings without explanation in code comments

### Prevention Strategy

**Enforce RPC-only access to encrypted columns.** The `location_encrypted` column should never be read directly via supabase-js. Add this as an architecture test analogous to the existing `supabaseAdmin` banned-from-routes test:

```typescript
// architecture test
it('no direct reads of location_encrypted column', () => {
  // grep source for .select() calls containing 'location_encrypted'
  // all access must go through RPC
});
```

**If bytea data must round-trip through the application layer** (e.g., for testing or migration utilities), use hex encoding explicitly:

```typescript
// Writing bytea to Supabase from Node.js
const hexEncoded = '\\x' + Buffer.from(binaryData).toString('hex');
await supabase.from('table').insert({ encrypted_col: hexEncoded });

// Reading bytea from Supabase in Node.js
const hexString: string = row.encrypted_col; // type: string, value: "\xdeadbeef"
const buffer = Buffer.from(hexString.slice(2), 'hex');
```

**Phase:** Location RPC implementation. The architecture test should be written before the RPC, so the prohibition is established before any shortcut is tempting.

---

## 20. RLS on Encrypted Columns — Raw bytea still readable if RLS is wrong

### What Goes Wrong

Encrypting a column does not substitute for RLS. If the RLS policy on `connect.connected_profiles` allows any authenticated user to read all rows (e.g., `FOR SELECT USING (true)`), then any user can read every other user's `location_encrypted bytea` value. The data is encrypted, so they cannot decrypt it without the Vault key — but they can exfiltrate the ciphertext for offline attacks, and for sophisticated adversaries this is a meaningful attack surface.

More subtly: PostgreSQL RLS evaluates conditions against column values, but for `bytea` columns there is nothing special about how the condition is applied. A policy like `USING (user_id = auth.uid())` works correctly — it filters rows by the `user_id` column (plaintext), not by the encrypted column. RLS works correctly with bytea; the risk is simply that RLS might be too permissive, not that it fails to evaluate.

The second risk: the `decrypt` step in the `SECURITY DEFINER` RPC runs outside the caller's RLS context (that's the point of SECURITY DEFINER). If the RPC does not explicitly verify that the requesting user owns the record before decrypting, any authenticated user could call `resolve_user_jurisdiction(target_user_id)` and receive the jurisdiction result derived from another user's encrypted location.

### Warning Signs

- `connected_profiles` RLS policy is `FOR SELECT USING (true)` or otherwise non-restrictive
- `resolve_user_jurisdiction` RPC does not include an ownership check (`WHERE user_id = auth.uid()`) before decrypting
- SECURITY DEFINER RPCs that accept a `user_id` parameter without verifying `p_user_id = auth.uid()`
- `SET search_path = ''` missing from the RPC (opens schema injection vector — established project standard from Phase 13)

### Prevention Strategy

**RLS on `connected_profiles` must use ownership restriction:**

```sql
CREATE POLICY "users can read own profile"
ON connect.connected_profiles
FOR SELECT
USING (user_id = auth.uid());
```

This prevents direct column reads by non-owners regardless of encryption status.

**Ownership check inside every SECURITY DEFINER location RPC:**

```sql
CREATE OR REPLACE FUNCTION connect.resolve_user_jurisdiction(p_user_id UUID)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller UUID := auth.uid();
BEGIN
  -- Verify caller owns this profile (or is service role with uid = null)
  IF v_caller IS NOT NULL AND v_caller != p_user_id THEN
    RAISE EXCEPTION 'permission_denied';
  END IF;
  -- ... decrypt and resolve
END;
$$;
```

**`SET search_path = ''` on all location RPCs** — already the established project standard from Phase 13. Non-negotiable.

**Phase:** Location RPC implementation. The ownership check is a one-liner but must be present before any location RPC goes to production.

---

## 21. Partial Location State During Connect Flow

### What Goes Wrong

The location capture flow has multiple steps: user provides address → server geocodes address → server encrypts coordinates → server stores to database → server resolves jurisdiction and caches. If any step fails after a preceding step has succeeded, the user is left in a partial state:

- **Geocoding fails** (network error, invalid address, ambiguous result): no coordinates, no stored location, clean — user should retry with a better address
- **Geocoding succeeds, encryption/storage fails**: coordinates were derived but not stored — clean, can retry
- **Storage succeeds, jurisdiction resolution fails**: location is stored and encrypted correctly, but the jurisdiction endpoint will fail or return null — the user has consented to location but gets no feature benefit
- **Storage succeeds, `location_consent` flag not updated**: location is stored but the `GET /api/account/me/jurisdiction` endpoint checks `location_consent` and returns 403 — user is confused

The worst partial state is: `location_encrypted` set, `location_consent = false`. The data exists but the flag says it doesn't. Or: `location_consent = true`, `location_encrypted = null`. The flag says data exists but nothing is there to decrypt.

### Warning Signs

- `location_consent` flag and `location_encrypted` column updated in separate non-atomic operations
- No handling in the `GET /api/account/me/jurisdiction` route for the case where `location_consent = true` but `location_encrypted = null`
- No error response distinction between "geocoding failed" (user should retry) vs "storage failed" (system error, retry automatically)
- Geocoding and storage in separate try/catch blocks with different error handling paths

### Prevention Strategy

**Atomic update: consent flag + encrypted location in a single RPC:**

```sql
CREATE OR REPLACE FUNCTION connect.store_user_location(
  p_user_id UUID,
  p_location_encrypted BYTEA,
  p_location_nonce BYTEA,
  p_key_version INTEGER
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE connect.connected_profiles
  SET
    location_encrypted = p_location_encrypted,
    location_nonce = p_location_nonce,
    location_key_version = p_key_version,
    location_consent = true,
    location_updated_at = NOW()
  WHERE user_id = p_user_id;
END;
$$;
```

Both fields change in one statement — no partial state possible.

**Geocoding must succeed before the RPC is called.** The Express handler structure:

```
1. Geocode address (external service call) → if fails, return 422 with specific error
2. Encrypt coordinates (Vault call) → if fails, return 500, nothing stored
3. Call store_user_location RPC → if fails, return 500, nothing stored
4. Return success (consent + location now consistent)
```

Steps 1 and 2 fail cleanly (nothing in DB yet). Step 3 is the single write point. This ensures the DB is never in partial state.

**`GET /api/account/me/jurisdiction` must handle all states gracefully:**

| State | Response |
|-------|----------|
| `location_consent = false` | 403 or empty jurisdiction |
| `location_consent = true`, `location_encrypted = null` | 500 with internal error (data inconsistency — log for investigation) |
| `location_consent = true`, decrypt succeeds, no district found | 200 with `{ jurisdiction: null, reason: 'no_district_match' }` |
| `location_consent = true`, decrypt + ST_Covers succeeds | 200 with full jurisdiction struct |

**Phase:** Location Connect flow implementation. The atomic RPC structure must be designed before the Express handler is written.

---

## 22. Location Consent Revocation — Downstream features hold stale jurisdiction

### What Goes Wrong

A user revokes location consent after their jurisdiction has been resolved and used by downstream features. For example: a user's district was resolved as "Indiana House District 61," that fact was used to populate their profile, filter relevant Symposium content, or pre-fill a district field on an Empowered profile. If the user later revokes consent and deletes their location, those downstream usages hold a stale reference.

The revocation path for `location_consent = false` needs to:
1. Set `location_consent = false`
2. Clear `location_encrypted` and `location_nonce`
3. Handle what happens to data derived from that location in other tables

For Empowered profiles specifically: `district_id`, `district_label`, and related fields on `empower.empowered_profiles` may have been populated from the resolved jurisdiction. These are the user's own public civic record — should they be cleared on location revocation? This is a product decision with platform integrity implications.

The pitfall is not implementing consent revocation atomically, or not having a policy for what happens to derived data.

### Warning Signs

- No `DELETE /api/account/me/location` endpoint (no revocation path exists at all)
- Location consent revocation clears `connected_profiles` columns but leaves `district_id` on `empowered_profiles` populated
- No documented policy on derived data retention after consent revocation
- Downstream features cache jurisdiction results independently without checking current consent state

### Prevention Strategy

**Implement revocation atomically via RPC:**

```sql
CREATE OR REPLACE FUNCTION connect.revoke_user_location(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE connect.connected_profiles
  SET
    location_encrypted = NULL,
    location_nonce = NULL,
    location_key_version = NULL,
    location_consent = false,
    location_updated_at = NOW()
  WHERE user_id = p_user_id;
END;
$$;
```

**Define the derived data policy before implementing location storage.** Options:
- **Strict:** Revocation clears all derived fields (district_id, district_label on empowered_profiles). User must re-provide location to re-populate.
- **Retain-last:** Derived fields remain populated until the user explicitly clears them. Revocation only prevents future reads and updates.

This is a product decision for the phase that designs the Empowered profile fields. Document the chosen policy in the migration comment for the `location_consent` column.

**`GET /api/account/me/jurisdiction` must re-check consent on every request** — never cache the consent state across requests. Redis caching of jurisdiction results should include `location_consent` as part of the cache key invalidation condition.

**Phase:** Location Connect flow implementation for the revocation endpoint. Derived data policy: Empowered profile schema phase.

---

## 23. Geocoding Coordinates Outside Indiana Boundaries

### What Goes Wrong

A user provides a valid address that geocodes correctly but resolves to coordinates outside Indiana — for example, a P.O. box in another state, a business address in a border city, or a malformed address that the geocoder interprets as a different location. The coordinates are valid and non-null, encryption succeeds, but `ST_Covers` finds no matching Indiana district boundary.

More concerning: Indiana has border cities where the ZIP code spans state lines (e.g., areas near Cincinnati or Louisville). A user who genuinely lives near the Indiana border might provide a legitimate address that geocodes to the Kentucky side of the line.

In these cases, `resolve_user_jurisdiction` returns null or an empty result — which is technically correct (no district found) but the user experience is confusing ("I live in Indiana, why can't you find my district?").

### Warning Signs

- No validation in the Express handler that geocoded coordinates fall within a rough Indiana bounding box before storing
- `resolve_user_jurisdiction` RPC that returns empty result is treated as an error (500) rather than a valid no-match case
- No user-facing message distinguishing "address not found" from "address found but outside Indiana coverage area"

### Prevention Strategy

**Pre-validate coordinates against Indiana's bounding box before encrypting and storing.** Indiana's approximate bounding box:

```typescript
const INDIANA_BOUNDS = {
  minLat: 37.77,
  maxLat: 41.78,
  minLng: -88.10,
  maxLng: -84.78
};

function isWithinIndianaBounds(lat: number, lng: number): boolean {
  return lat >= INDIANA_BOUNDS.minLat && lat <= INDIANA_BOUNDS.maxLat
    && lng >= INDIANA_BOUNDS.minLng && lng <= INDIANA_BOUNDS.maxLng;
}
```

This is a loose check (bounding box, not actual state boundary), so it's not a substitute for `ST_Covers` — but it catches gross misgeocodes before they reach the DB.

**Return a structured error from the jurisdiction endpoint, not null:**

```typescript
// Not: return null
// Yes: return { jurisdiction: null, reason: 'coordinates_outside_coverage' }
```

**Phase:** Location Express handler implementation. The bounding box check is a 10-line addition before the encrypt/store call.

---

## 24. ST_MakePoint Argument Order — Longitude before latitude

### What Goes Wrong

`ST_MakePoint` takes arguments in `(X, Y)` order — and in geographic coordinates, **X is longitude, Y is latitude**. This is the opposite of the common human mental model ("lat/lng" where latitude is listed first).

A developer writing the `resolve_user_jurisdiction` RPC who passes `(lat, lng)` instead of `(lng, lat)` creates a point in the wrong hemisphere. For Indiana coordinates (lat ~40°N, lng ~-86°E), swapping the arguments produces a point at approximately (40°E, -86°N) — in the Caspian Sea region. `ST_Covers` returns false for all districts, `resolve_user_jurisdiction` always returns null. No error is raised because the geometry is valid — just wrong.

This is one of the most common GIS mistakes and is entirely silent.

### Warning Signs

- `ST_MakePoint(p_lat, p_lng)` anywhere in the RPC code (lat first = wrong)
- A known-good Indiana coordinate (e.g., the Monroe County Courthouse at lat=39.165, lng=-86.527) returning no jurisdiction match
- Variable names `lat` and `lng` used inconsistently with `ST_MakePoint` argument order in the same function

### Prevention Strategy

**Make the argument order unmissable in RPC parameter names and comments:**

```sql
-- p_lng is X (longitude, ~-86 for Indiana), p_lat is Y (latitude, ~40 for Indiana)
-- ST_MakePoint takes (X=lng, Y=lat) — longitude FIRST
CREATE OR REPLACE FUNCTION connect.resolve_user_jurisdiction(
  p_user_id UUID,
  p_lat FLOAT8,  -- Y coordinate, ~39-42 for Indiana
  p_lng FLOAT8   -- X coordinate, ~-85 to -88 for Indiana
)
...
  ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)  -- lng first: X, then Y
```

**Write the smoke test with a known coordinate as part of boundary loading.** The Monroe County Courthouse (39.165325, -86.526386) is a reliable test point. If `resolve_user_jurisdiction(null, 39.165325, -86.526386)` returns no district, the argument order is wrong.

**Phase:** RPC implementation. Write the test before the RPC goes to production.

---

## 25. PostGIS Not Installed or Wrong Schema on Supabase

### What Goes Wrong

PostGIS must be explicitly enabled on the Supabase project before any spatial queries or migrations run. If the extension is not enabled, every migration containing `geometry` column types or `ST_*` function calls will fail. Because Supabase migrations run sequentially, a failed spatial migration blocks all subsequent migrations.

Additionally, as of PostGIS 2.3+, the extension is **not relocatable** — it cannot be moved from the schema it was installed in. On Supabase, PostGIS installs into the `extensions` schema by default. If a migration assumes PostGIS functions are in `public`, function calls will fail with "function not found" unless the function is schema-qualified or `extensions` is in the `search_path`.

For SECURITY DEFINER functions with `SET search_path = ''` (the project standard), the `search_path` is empty — so any `ST_Contains()` call inside such an RPC must be fully qualified as `extensions.ST_Contains()` (or whatever schema PostGIS installed into on the project).

### Warning Signs

- Migrations using `geometry` type or `ST_*` functions failing with "type does not exist" or "function not found"
- `ST_Contains()` called without schema prefix inside a `SECURITY DEFINER` function that has `SET search_path = ''`
- No explicit PostGIS enable step in the deployment runbook
- `SELECT extschema FROM pg_extension WHERE extname = 'postgis'` not run before writing any spatial query

### Prevention Strategy

**Enable PostGIS explicitly in the earliest spatial migration:**

```sql
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;
```

**Verify the installed schema before writing any RPC:**

```sql
SELECT extschema FROM pg_extension WHERE extname = 'postgis';
-- Returns: extensions (typically)
```

**In all SECURITY DEFINER RPCs with `SET search_path = ''`, fully qualify PostGIS functions:**

```sql
-- Wrong (breaks with SET search_path = ''):
WHERE ST_Covers(geom, ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326))

-- Correct:
WHERE extensions.ST_Covers(geom, extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326))
```

This aligns with the existing project standard (`SET search_path = ''` requires fully qualified table refs as of Phase 13).

**Add PostGIS enable to the deployment runbook** as a manual pre-migration step for the live environment, with a verification query:

```sql
SELECT PostGIS_Version();
-- If this errors, PostGIS is not enabled
```

**Phase:** First spatial migration. The schema-qualification requirement for `SET search_path = ''` RPCs must be established before any spatial RPC is written.

---

## Summary Table

**Original Pitfalls:**

| Pitfall | Severity for EV | Phase to Address |
|---|---|---|
| RLS anon/service role boundary | Critical — direct data leak | Foundation |
| RLS on JOINs and Views | Critical — indirect leak of `tolerance_rating` | Foundation + ongoing |
| Atomic transaction failures | High — partial empowerment state | Foundation (before any business logic) |
| Invite system abuse | High — social graph integrity | Invite system design |
| Cron job reliability | Medium-High — calibration integrity | Infrastructure setup |
| Anonymous compass import conflicts | Medium — civic accuracy corruption | Data model design |
| Schema migration mistakes | Medium-High — data loss, production failures | Every migration |
| Session/token edge cases | High — stale auth state, key exposure | Foundation |
| Admin tool security | High — privilege escalation | Admin tools phase, audit log in Foundation |
| RLS not tested | Critical — all RLS policies may be ineffective | Foundation + ongoing |

**Location Infrastructure Pitfalls (v1.3):**

| Pitfall | Severity for EV | Phase to Address |
|---|---|---|
| Vault key loss — data permanently unreadable | Critical — all user locations unrecoverable | Location schema (before first migration) |
| pgsodium deprecation — wrong primitive | High — forced migration while live data exists | Architecture decision, before schema |
| Raw pgcrypto — no integrity, bad IV defaults | Critical — silent ciphertext corruption, IV reuse | Encryption RPC implementation |
| Statement logging leaks cleartext coordinates | High — defeats entire purpose of encryption | Location schema design, before RPC interface |
| SRID 0 geometry — ST_Contains always false | High — all jurisdiction queries return null | Boundary loading + RPC implementation |
| ST_Contains boundary exclusion | Low-Medium — rare edge case, wrong null result | RPC implementation (use ST_Covers instead) |
| TIGER/Line SRID 4269 vs 4326 mismatch | Medium — PostGIS error or wrong CRS math | Boundary loading migration |
| Stale TIGER/Line after redistricting | Medium — wrong district for some users | Boundary loading migration |
| bytea type mangling via supabase-js | Medium — silent data corruption if used directly | RPC implementation + architecture test |
| RLS too permissive on encrypted columns | High — ciphertext exfiltration + no ownership check in RPC | Location RPC implementation |
| Partial location state during Connect flow | High — consent flag and encrypted data disagree | Location Connect flow implementation |
| Location consent revocation — stale derived data | Medium — product decision gap | Location flow + Empowered profile schema |
| Geocoding outside Indiana boundaries | Low — confusing UX, not a data integrity risk | Location Express handler |
| ST_MakePoint argument order (lng first) | Critical — silent wrong-hemisphere coordinates | RPC implementation (write smoke test first) |
| PostGIS not enabled / wrong schema | High — blocks all spatial migrations | First spatial migration + deployment runbook |

---

## Cross-Cutting Rules for Empowered Vote

These rules apply across all pitfalls and should be standing platform constraints:

1. **`tolerance_rating` and `legal_name` are never selected except by service role for specific admin operations.** No user-scoped query, no view, no JOIN ever returns these columns.

2. **Multi-step state changes are always atomic PostgreSQL functions (RPC), never chained JS awaits.**

3. **RLS is tested before any table goes to production.** The pgTAP or SQL SET LOCAL test is the migration acceptance gate.

4. **Every admin action is logged.** No exceptions. `admin_audit_log` is append-only, no DELETE policy.

5. **The service role key is never used for reads that return data to users.** Service role = trusted writes only.

6. **Tier decisions are always made from the database, never from JWT claims alone.**

7. **All SECURITY DEFINER RPCs use `SET search_path = ''` with fully qualified table and function references** — including `extensions.ST_Covers()`, `extensions.ST_MakePoint()`, etc. for PostGIS functions.

8. **`ST_Covers` not `ST_Contains` for all point-in-polygon jurisdiction queries.** Points on district boundaries must match.

9. **`ST_MakePoint(lng, lat)` — longitude (X) first, always.** Comment this in every RPC that constructs a point.

10. **`location_encrypted` column is never read directly via supabase-js.** All location access goes through RPCs.

---

*Sources: Supabase documentation (RLS, Auth, Vault, pgsodium deprecation notice, pg_cron), PostgreSQL documentation (pgcrypto warnings, row security, SECURITY DEFINER), PostGIS documentation (ST_Contains, ST_Covers, ST_MakePoint, SRID handling, projection workshop), TIGER/Line technical documentation (coordinate system NAD83/SRID 4269), Indiana redistricting history (Ballotpedia, IGA), supabase-js bytea discussion #2441, Supabase encryption best practices discussion #9868.*
