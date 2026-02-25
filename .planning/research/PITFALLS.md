# PITFALLS — Tiered Account System on Supabase + Express

**Research type:** Project Research — Pitfalls dimension
**Project:** empowered-accounts (Empowered Vote)
**Date:** 2026-02-24
**Researcher:** gsd-project-researcher agent

---

## Purpose

This document captures the critical mistakes developers make when building tiered account systems on Supabase + Express, with specific focus on the civic platform context of Empowered Vote — where data leaks expose civic identity, partial state is a platform integrity failure, and invite chain abuse undermines social accountability.

Each pitfall includes: what goes wrong, warning signs, prevention strategy, and which development phase should address it.

---

## Pitfall Index

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

## Summary Table

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

---

## Cross-Cutting Rules for Empowered Vote

These rules apply across all pitfalls and should be standing platform constraints:

1. **`tolerance_rating` and `legal_name` are never selected except by service role for specific admin operations.** No user-scoped query, no view, no JOIN ever returns these columns.

2. **Multi-step state changes are always atomic PostgreSQL functions (RPC), never chained JS awaits.**

3. **RLS is tested before any table goes to production.** The pgTAP or SQL SET LOCAL test is the migration acceptance gate.

4. **Every admin action is logged.** No exceptions. `admin_audit_log` is append-only, no DELETE policy.

5. **The service role key is never used for reads that return data to users.** Service role = trusted writes only.

6. **Tier decisions are always made from the database, never from JWT claims alone.**

---

*Sources: Supabase documentation (RLS, Auth, pg_cron), PostgreSQL documentation (row security, transaction control, SECURITY DEFINER), common patterns from tiered auth system post-mortems, Render platform documentation (cold starts, cron scheduling), civic platform threat modeling considerations.*
