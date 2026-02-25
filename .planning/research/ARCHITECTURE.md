# Architecture Research

**Domain:** Tiered account system — Supabase + Express/TypeScript
**Researched:** 2026-02-24
**Confidence:** HIGH

---

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                             │
│  ┌──────────────┐  ┌──────────────────────────────────────┐    │
│  │  Admin Tool  │  │  Feature Repos (Framer/React clients) │    │
│  │  (internal)  │  │  Essentials, Compass, Connect, Empower│    │
│  └──────┬───────┘  └──────────────────┬───────────────────┘    │
└─────────┼────────────────────────────┼─────────────────────────┘
          │ HTTP /api/admin/*           │ HTTP /api/*
          │                            │
┌─────────┴────────────────────────────┴─────────────────────────┐
│                     EXPRESS API LAYER                           │
│  ┌────────────────────────────────────────────────────────┐    │
│  │                 Auth Middleware                         │    │
│  │   Supabase JWT validation → attach user + tier context  │    │
│  └──────────────────────┬─────────────────────────────────┘    │
│                         │                                       │
│  ┌──────────┐  ┌────────┴────────┐  ┌──────────────────────┐   │
│  │  /admin  │  │   /api/public   │  │   /api/auth          │   │
│  │  Router  │  │   Routers       │  │   Router             │   │
│  └──────┬───┘  └────────┬────────┘  └──────────┬───────────┘   │
│         │               │                      │               │
│  ┌──────┴───────────────┴──────────────────────┴───────────┐   │
│  │              Service Layer                               │   │
│  │  AuthService  AccountService  CompassService             │   │
│  │  EmpowerService  ConnectionService  CronService          │   │
│  └──────────────────────────┬──────────────────────────────┘   │
│                             │                                   │
│  ┌──────────────────────────┴──────────────────────────────┐   │
│  │         Supabase Client (service role key)               │   │
│  │              + Redis / In-memory cache                   │   │
│  └──────────────────────────┬──────────────────────────────┘   │
└─────────────────────────────┼───────────────────────────────────┘
                              │ Postgres
┌─────────────────────────────┴───────────────────────────────────┐
│                      SUPABASE (Database + Auth)                 │
│                                                                 │
│  auth.users           (Supabase-managed)                       │
│  public.users         (our extension of auth identity)         │
│  public.user_roles    (multi-role junction table)              │
│                                                                 │
│  connect schema:      connected_profiles, peer_connections,    │
│                       account_follows, gem_transactions,       │
│                       verification_sessions                    │
│                                                                 │
│  empower schema:      empowered_profiles                       │
│                                                                 │
│  inform schema:       compass_topics, compass_stances,         │
│                       compass_topic_roles, compass_responses,  │
│                       compass_change_history                   │
│                                                                 │
│  RLS policies enforce tier access at the database level        │
└─────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Implementation |
|-----------|----------------|----------------|
| Supabase Auth | JWT issuance, session management, password flows | Managed service — not custom |
| RLS Policies | Primary tier-gate enforcement at DB level | SQL policies per table per schema |
| Auth Middleware | JWT validation, tier context attachment to req object | Express middleware, service role client |
| Tier Guards | Route-level tier enforcement (second layer) | Express middleware factories |
| Service Layer | Business logic, transaction orchestration | TypeScript classes / modules |
| Supabase Client | DB queries, RPC calls, transactions | `@supabase/supabase-js` with service role |
| Redis Cache | Session tier info, rate-limit state | Upstash with in-memory fallback |
| Cron Jobs | Calibration lapse checks, demotion enforcement | In-process node-cron at startup |
| Admin Router | Internal management endpoints | Separate Express router, admin-only middleware |

---

## Recommended Project Structure

```
backend/src/
├── middleware/
│   ├── auth.ts             # JWT validation, user + tier context on req
│   ├── requireTier.ts      # Factory: requireTier('connected' | 'empowered')
│   ├── requireAdmin.ts     # Admin tool access gate
│   └── rateLimit.ts        # Redis-backed rate limiting with fallback
│
├── routes/
│   ├── auth.ts             # /api/auth/* — signup, login, logout
│   ├── account.ts          # /api/account/* — me, update
│   ├── connect.ts          # /api/connect/* — start, status, complete, import-compass
│   ├── compass.ts          # /api/compass/* — responses, progress, compare, topics
│   ├── empower.ts          # /api/empower/* — preflight, confirm, demote
│   ├── connections.ts      # /api/connections/* — peer requests, accept/decline/block
│   ├── follows.ts          # /api/follows/* — follow/unfollow/list
│   ├── candidates.ts       # /api/candidates/* — public candidate pages
│   ├── health.ts           # /api/health
│   └── admin/
│       ├── index.ts        # Admin router mount — /api/admin/*
│       ├── invites.ts      # Invite management
│       ├── accounts.ts     # Account review, standing
│       └── cohorts.ts      # Pilot cohort enrollment
│
├── services/
│   ├── account.service.ts       # User profile composition, tier checks
│   ├── auth.service.ts          # Auth flow helpers
│   ├── connect.service.ts       # Verification session, connected_profile creation
│   ├── compass.service.ts       # Compass queries, calibration completeness
│   ├── empower.service.ts       # Atomic empowerment/demotion transactions
│   ├── connection.service.ts    # Peer connections and follows
│   ├── gem.service.ts           # Gem ledger writes
│   └── cron/
│       ├── index.ts             # Register all cron jobs at startup
│       └── calibrationLapse.ts  # 30-day demotion enforcement
│
├── db/
│   ├── client.ts           # Supabase service role client singleton
│   └── transactions.ts     # PostgreSQL transaction helpers (rpc wrappers)
│
├── cache/
│   └── redis.ts            # Redis client with in-memory fallback
│
├── types/
│   ├── request.d.ts        # Extended Express Request with user + tier
│   └── domain.ts           # Shared domain types (TierLevel, etc.)
│
└── index.ts                # App entry: mount routers, start cron, listen
```

```
supabase/
├── migrations/
│   ├── 0001_create_schemas.sql
│   ├── 0002_public_users.sql
│   ├── 0003_connect_profiles.sql
│   ├── 0004_empower_profiles.sql
│   ├── 0005_inform_compass.sql
│   ├── 0006_connections_follows.sql
│   ├── 0007_roles_gems.sql
│   ├── 0008_verification_sessions.sql
│   ├── 0009_rls_public.sql
│   ├── 0010_rls_connect.sql
│   ├── 0011_rls_empower.sql
│   └── 0012_rls_inform.sql
└── config.toml
```

---

## Architectural Patterns

### Pattern 1: Additive Child Tables for Tier Detection

**What:** Tier is determined solely by the presence or absence of a child row. No status flags, no enum columns on a wide user record. The rule: `connected_profiles` row exists = Connected tier. `empowered_profiles` row with `is_active = true` exists = Empowered tier.

**When to use:** Always, for this system. Every tier check throughout the application is a join, not a column read.

**Trade-offs:**
- Eliminates invalid states (a flag can be set incorrectly; a row either exists or it does not)
- Clean atomicity: empowerment = row insert, demotion = `is_active = false`
- Slightly more expensive queries than reading one column, but negligible at pilot scale
- Schema extensions per tier are naturally scoped

**Example:**
```typescript
// types/domain.ts
export type TierLevel = 'inform' | 'connected' | 'empowered';

// services/account.service.ts
async function detectTier(userId: string): Promise<TierLevel> {
  const { data } = await supabase
    .from('empowered_profiles')
    .select('id, is_active')
    .eq('user_id', userId)
    .maybeSingle();

  if (data?.is_active) return 'empowered';

  const { data: connected } = await supabase
    .from('connected_profiles')
    .select('id')
    .eq('user_id', userId)
    .maybeSingle();

  return connected ? 'connected' : 'inform';
}
```

---

### Pattern 2: Layered Auth — RLS Primary, Middleware Secondary

**What:** Two enforcing layers, neither optional. RLS policies at the Supabase level enforce data-layer access regardless of how the API is called. Express middleware enforces tier requirements before any route handler runs. The service role key bypasses RLS intentionally — use it only on the server, never client-exposed.

**When to use:** All protected routes. The application layer check provides early response (returns 401/403 before hitting the DB). The RLS layer is the safety net if application logic has a bug.

**Trade-offs:**
- Defense in depth — a bug in one layer does not expose data
- RLS policies must be maintained alongside schema changes
- Service role queries are unrestricted; must be treated like raw SQL

**Example:**
```typescript
// middleware/auth.ts
export async function authenticate(req: Request, res: Response, next: NextFunction) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'No token provided' });

  const { data: { user }, error } = await supabase.auth.getUser(token);
  if (error || !user) return res.status(401).json({ error: 'Invalid token' });

  const tier = await detectTier(user.id);
  req.user = { id: user.id, tier };
  next();
}

// middleware/requireTier.ts
export function requireTier(minimumTier: TierLevel) {
  const tierRank: Record<TierLevel, number> = {
    inform: 0, connected: 1, empowered: 2
  };
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) return res.status(401).json({ error: 'Not authenticated' });
    if (tierRank[req.user.tier] < tierRank[minimumTier]) {
      return res.status(403).json({ error: `Requires ${minimumTier} account` });
    }
    next();
  };
}

// routes/empower.ts
router.post('/confirm',
  authenticate,
  requireTier('connected'),
  async (req, res) => { /* ... */ }
);
```

**RLS example — connect schema:**
```sql
-- Only the owning user can read their own connected_profile.
-- Other users get no rows.
CREATE POLICY "connected_profiles: owner read"
  ON connect.connected_profiles FOR SELECT
  USING (user_id = auth.uid());

-- Empower reads require active empowered_profile
CREATE POLICY "compass_responses: owner or public empowered read"
  ON inform.compass_responses FOR SELECT
  USING (
    user_id = auth.uid()
    OR visibility = 'public'
    OR (
      visibility = 'friends'
      AND EXISTS (
        SELECT 1 FROM connect.peer_connections pc
        WHERE pc.status = 'accepted'
          AND (
            (pc.requester_id = auth.uid() AND pc.addressee_id = compass_responses.user_id)
            OR (pc.addressee_id = auth.uid() AND pc.requester_id = compass_responses.user_id)
          )
      )
    )
  );

-- tolerance_rating is never exposed via RLS to anyone but the owner
-- Enforced by returning it only in internal server queries using service role,
-- never in the anon-key-accessible query path
```

---

### Pattern 3: Atomic Transactions via Postgres RPC Functions

**What:** Multi-table operations that must succeed or roll back entirely are implemented as PostgreSQL functions called via Supabase RPC, not as sequential Express service calls. The function body runs in a transaction; any exception triggers a full rollback. This is the correct pattern for the empowerment and demotion flows.

**When to use:** Any operation touching more than one table where partial completion is an invalid state. In this system: empowerment, demotion, and calibration-lapse demotion.

**Trade-offs:**
- True atomicity — guaranteed by Postgres, not by application-layer optimism
- Logic lives in the database, which can feel opaque if not well-documented
- SQL functions must be versioned through migrations like all other schema changes
- Simpler than distributed sagas; appropriate for a monolithic Supabase project
- Supabase RPC calls return errors cleanly — handle them as you would any query error

**Migration — empowerment function:**
```sql
-- supabase/migrations/0013_empower_transaction.sql

CREATE OR REPLACE FUNCTION empower.execute_empowerment(
  p_user_id        UUID,
  p_legal_name     TEXT,
  p_profile_id     UUID  -- connected_profiles.id
)
RETURNS empower.empowered_profiles
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_slug TEXT;
  v_result empower.empowered_profiles;
BEGIN
  -- Generate slug from legal name (simple version — extend as needed)
  v_slug := lower(regexp_replace(p_legal_name, '[^a-zA-Z0-9]', '-', 'g'))
             || '-' || substr(gen_random_uuid()::text, 1, 8);

  -- Step 1: Insert empowered profile
  INSERT INTO empower.empowered_profiles (
    user_id, connected_profile_id, legal_name, candidate_page_slug
  ) VALUES (
    p_user_id, p_profile_id, p_legal_name, v_slug
  )
  RETURNING * INTO v_result;

  -- Step 2: Batch all compass responses to public
  UPDATE inform.compass_responses
    SET visibility = 'public', updated_at = now()
    WHERE user_id = p_user_id;

  RETURN v_result;

  -- Any exception here rolls back both operations
EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$$;
```

**Migration — demotion function:**
```sql
-- supabase/migrations/0014_demote_transaction.sql

CREATE OR REPLACE FUNCTION empower.execute_demotion(
  p_user_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE empower.empowered_profiles
    SET is_active = false, updated_at = now()
    WHERE user_id = p_user_id AND is_active = true;

  UPDATE inform.compass_responses
    SET visibility = 'private', updated_at = now()
    WHERE user_id = p_user_id;

EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$$;
```

**Express service call:**
```typescript
// services/empower.service.ts
export async function executeEmpowerment(
  userId: string,
  legalName: string,
  connectedProfileId: string
): Promise<{ success: boolean; error?: string }> {
  const { data, error } = await supabase.rpc('execute_empowerment', {
    p_user_id: userId,
    p_legal_name: legalName,
    p_profile_id: connectedProfileId,
  });

  if (error) {
    // Postgres rolled back — no partial state exists
    console.error('Empowerment transaction failed:', error.message);
    return { success: false, error: error.message };
  }

  return { success: true };
}

export async function executeDemotion(
  userId: string
): Promise<{ success: boolean; error?: string }> {
  const { error } = await supabase.rpc('execute_demotion', {
    p_user_id: userId,
  });

  if (error) {
    return { success: false, error: error.message };
  }

  return { success: true };
}
```

---

### Pattern 4: Admin vs. Public API Separation

**What:** Admin endpoints live under `/api/admin/*` behind a separate middleware chain. Public API endpoints under `/api/*` are tier-gated by user tier. The two routers never share middleware — admin auth is validated differently (internal token or elevated Supabase role check), and admin routes have no RLS dependency since they use the service role exclusively.

**When to use:** Any endpoint that must not be accessible to regular users. Invite management, account review, manual verification approval, cohort enrollment, invite chain visibility.

**Trade-offs:**
- Clear separation prevents accidental admin endpoint exposure
- Admin tool can evolve independently without affecting public API
- Both live in the same Express app and the same Supabase project — no separate deployment needed at pilot scale

**Example:**
```typescript
// routes/admin/index.ts
import { Router } from 'express';
import { requireAdmin } from '../../middleware/requireAdmin';
import invitesRouter from './invites';
import accountsRouter from './accounts';
import cohortsRouter from './cohorts';

const adminRouter = Router();

// All admin routes require admin check first
adminRouter.use(requireAdmin);
adminRouter.use('/invites', invitesRouter);
adminRouter.use('/accounts', accountsRouter);
adminRouter.use('/cohorts', cohortsRouter);

export default adminRouter;

// middleware/requireAdmin.ts
export async function requireAdmin(req: Request, res: Response, next: NextFunction) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'No token' });

  // Check admin flag in public.users or a separate admin_users table
  const { data: { user }, error } = await supabase.auth.getUser(token);
  if (error || !user) return res.status(401).json({ error: 'Invalid token' });

  const { data: adminRecord } = await supabase
    .from('admin_users')
    .select('id')
    .eq('user_id', user.id)
    .maybeSingle();

  if (!adminRecord) return res.status(403).json({ error: 'Admin access required' });

  req.user = { id: user.id, tier: 'empowered', isAdmin: true };
  next();
}

// index.ts (app mount)
app.use('/api/admin', adminRouter);
app.use('/api/auth', authRouter);
app.use('/api/account', authenticate, accountRouter);
app.use('/api/connect', authenticate, connectRouter);
app.use('/api/compass', authenticate, compassRouter);
app.use('/api/empower', authenticate, requireTier('connected'), empowerRouter);
```

---

### Pattern 5: Scheduled Job Pattern for Demotion Enforcement

**What:** An in-process cron job (node-cron) runs at server startup. It queries all active Empowered Accounts with uncalibrated new topics past the 30-day window and calls `executeDemotion` for each. The job is idempotent — running it twice produces the same result. Notifications (25-day warning, demotion confirmation) are sent through a notification service, not in the same cron tick.

**When to use:** Calibration lapse enforcement. Also the pattern for any periodic enforcement that must happen even if no user initiates an action.

**Trade-offs:**
- In-process cron is simple and avoids external job infrastructure at pilot scale
- Not horizontally scalable without a distributed lock (not needed for pilot)
- If the server restarts, in-flight cron window may be missed — acceptable at pilot scale; add Redis-based distributed lock if this becomes a concern
- Cron failures must not crash the server — wrap in try/catch and log

**Example:**
```typescript
// services/cron/calibrationLapse.ts
import cron from 'node-cron';
import { supabase } from '../../db/client';
import { executeDemotion } from '../empower.service';

export function startCalibrationLapseCron() {
  // Runs daily at 2am UTC
  cron.schedule('0 2 * * *', async () => {
    console.log('[cron] calibrationLapse: starting run');
    try {
      await checkAndDemoteLapsedAccounts();
    } catch (err) {
      // Never crash the server
      console.error('[cron] calibrationLapse: uncaught error', err);
    }
  });
}

async function checkAndDemoteLapsedAccounts() {
  // Find Empowered Accounts with topics that went live > 30 days ago
  // and have no compass_response for that topic
  const { data: lapsed, error } = await supabase.rpc('get_calibration_lapsed_users');
  if (error) throw error;

  for (const { user_id } of lapsed ?? []) {
    const result = await executeDemotion(user_id);
    if (result.success) {
      // Queue notification (separate service call)
      await notifyDemotion(user_id);
    } else {
      console.error(`[cron] Failed to demote user ${user_id}:`, result.error);
    }
  }
}

// services/cron/index.ts
import { startCalibrationLapseCron } from './calibrationLapse';

export function startAllCronJobs() {
  startCalibrationLapseCron();
}

// index.ts (server entry)
import { startAllCronJobs } from './services/cron';
startAllCronJobs();
```

**Supporting SQL function (migration):**
```sql
-- supabase/migrations/0015_get_calibration_lapsed_users.sql

CREATE OR REPLACE FUNCTION get_calibration_lapsed_users()
RETURNS TABLE (user_id UUID)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT DISTINCT ep.user_id
  FROM empower.empowered_profiles ep
  WHERE ep.is_active = true
    AND EXISTS (
      SELECT 1
      FROM inform.compass_topics ct
      WHERE ct.status = 'live'
        AND ct.created_at < now() - INTERVAL '30 days'
        AND NOT EXISTS (
          SELECT 1
          FROM inform.compass_responses cr
          WHERE cr.user_id = ep.user_id
            AND cr.topic_id = ct.id
        )
    );
$$;
```

---

### Pattern 6: Additive Migration Strategy

**What:** Every schema change is an additive migration file. Migrations are numbered sequentially and never modified after merging. New columns always have defaults or are nullable. No destructive changes (DROP COLUMN) without a multi-step migration (add new → backfill → remove old). All migrations run via `supabase db push` — no manual production changes.

**When to use:** Every schema change without exception.

**Trade-offs:**
- Guarantees reproducible schema across environments
- Additive-only constraint limits refactoring speed, but prevents data loss
- RLS policies are schema changes and must be in migrations
- Column removals require explicit planning (3-step pattern)

**Migration conventions for this project:**
```
0001_create_schemas.sql          -- CREATE SCHEMA public, connect, empower, inform
0002_public_users.sql            -- public.users table
0003_connect_profiles.sql        -- connect.connected_profiles
0004_empower_profiles.sql        -- empower.empowered_profiles
0005_inform_compass_topics.sql   -- inform.compass_topics, compass_stances, compass_topic_roles
0006_inform_compass_responses.sql -- inform.compass_responses, compass_change_history
0007_connections_follows.sql     -- connect.peer_connections, connect.account_follows
0008_roles.sql                   -- public.role_type enum, public.user_roles
0009_gems.sql                    -- connect.gem_transactions
0010_verification_sessions.sql   -- connect.verification_sessions
0011_invites.sql                 -- public.invite_codes (alpha enrollment)
0012_rls_public.sql              -- RLS policies for public schema
0013_rls_connect.sql             -- RLS policies for connect schema
0014_rls_empower.sql             -- RLS policies for empower schema
0015_rls_inform.sql              -- RLS policies for inform schema
0016_empower_transaction.sql     -- execute_empowerment() RPC function
0017_demote_transaction.sql      -- execute_demotion() RPC function
0018_calibration_lapsed.sql      -- get_calibration_lapsed_users() RPC function
```

**Adding a column later (additive):**
```sql
-- 0025_add_account_standing.sql
ALTER TABLE connect.connected_profiles
  ADD COLUMN account_standing TEXT NOT NULL DEFAULT 'active'
  CHECK (account_standing IN ('active', 'suspended', 'quarantined'));
```

---

## Data Flow

### Empowerment Flow

```
POST /api/empower/confirm
    |
    v
authenticate middleware
  - validates JWT, attaches req.user with tier
    |
    v
requireTier('connected') middleware
  - 403 if not at least Connected tier
    |
    v
Route handler
  - reads req.body: { legalName }
    |
    v
empower.service: preflightCheck(userId)
  - verifies connected_profile.verification_status = 'verified'
  - verifies all live topics have compass_responses
  - returns { ready: true } or { ready: false, missing: [...] }
    |
    v (if ready)
empower.service: executeEmpowerment(userId, legalName, profileId)
  - supabase.rpc('execute_empowerment', { ... })
  - Postgres function runs:
      BEGIN (implicit in function)
        INSERT empowered_profiles
        UPDATE compass_responses SET visibility = 'public'
      COMMIT (on success) | ROLLBACK (on any exception)
    |
    v (on success)
Route handler returns 200 with empowered profile data
    |
    v (on error — DB rolled back, no partial state)
Route handler returns 500 with error message
```

### Calibration Lapse Flow

```
[Daily cron — 2am UTC]
    |
    v
calibrationLapse.ts: checkAndDemoteLapsedAccounts()
    |
    v
supabase.rpc('get_calibration_lapsed_users')
  - Returns user_ids of active Empowered Accounts
    with topics live > 30 days and no response filed
    |
    v (for each lapsed user)
empower.service: executeDemotion(userId)
  - supabase.rpc('execute_demotion', { p_user_id })
  - Postgres function:
      UPDATE empowered_profiles SET is_active = false
      UPDATE compass_responses SET visibility = 'private'
    |
    v
notifyDemotion(userId)
  - [notification mechanism TBD — email, in-app]
```

### Tier-Gated Request Flow

```
Incoming request
    |
    v
authenticate middleware
  - Validates Supabase JWT
  - Calls detectTier(userId) [may use Redis cache]
  - Attaches req.user = { id, tier }
    |
    v
requireTier(minimumTier) middleware
  - Compares tier rank
  - 403 if insufficient
    |
    v
Route handler
  - Business logic with req.user.id guaranteed to be authenticated
  - Service calls use service role key (bypasses RLS intentionally)
  - Service role queries apply field-level filtering for sensitive fields:
      tolerance_rating: never included in response serialization
      legal_name: only included for Empowered profile owner
      verification_method: never included in any response
    |
    v
Response
```

### Compass Visibility Flow

```
GET /api/compass/compare/:userId
    |
    v
authenticate (req.user = caller)
    |
    v
compass.service.getVisibleResponses(targetUserId, callerId)
    |
    v
Strategy — determined by caller's relationship to target:
  - Same user → return all (private + friends + public)
  - Peer connection (accepted) → return friends + public
  - No connection → return public only
  - Empowered target → public stances always visible to all
    |
    v
compass_responses query with visibility filter
  + inverted flag applied in serialization layer (never ignored)
```

---

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 0–500 users (Alpha pilot) | Current design as-is. In-process cron is fine. Redis optional. Single Supabase project. |
| 500–10k users | Add Redis caching for detectTier() (hot path on every request). Monitor RLS policy execution plans. |
| 10k–100k users | Evaluate moving cron to a dedicated Render job if in-process scheduling conflicts with web server memory. Consider read replicas for compass compare queries. |
| 100k+ users | Schema-level read replica for inform (public reads). Separate Supabase project consideration. Distributed lock for cron jobs. |

### Scaling Priorities

1. **First bottleneck:** `detectTier()` called on every authenticated request. Cache tier lookups in Redis keyed by `userId` with a short TTL (30–60 seconds). Invalidate on empowerment and demotion.
2. **Second bottleneck:** Compass compare queries with visibility join logic. Add composite index on `(user_id, visibility)` on `compass_responses` and `(requester_id, addressee_id, status)` on `peer_connections`.
3. **Third bottleneck:** Calibration lapse cron scanning all Empowered Accounts daily. Introduce a `calibration_lapse_candidates` materialized view refreshed when new topics go live, so the cron has a pre-filtered table to scan.

---

## Anti-Patterns

### Anti-Pattern 1: Status Flags for Tier

**What people do:** Add a `tier` enum column to `public.users`. Set it to `'inform'`, `'connected'`, or `'empowered'`.

**Why it's wrong:** A flag can be set to any value at any time, including invalid combinations (empowered without a connected_profile row). Application bugs can create impossible states. Rollback of a failed empowerment transaction must reset the flag manually — this is exactly the kind of step that gets missed.

**Do this instead:** Tier is determined by row existence. Run a join. The database enforces the constraint structurally, not through a value check.

---

### Anti-Pattern 2: Sequential DB Calls for Atomic Operations

**What people do:** In the Express service layer, run `INSERT INTO empowered_profiles` then `UPDATE compass_responses SET visibility = 'public'` as two separate `await` calls.

**Why it's wrong:** If the process crashes, a network error occurs, or the second query fails after the first succeeds, the system is in a partial state: an empowered_profiles row exists but compass visibility is still private (or vice versa). This is an invalid state with no clean recovery path.

**Do this instead:** Use a Postgres function called via Supabase RPC. The function runs in a single transaction. Any failure rolls back both operations. The application receives a clear error and knows no partial state was written.

---

### Anti-Pattern 3: Exposing Sensitive Fields via Query Star

**What people do:** `SELECT * FROM connect.connected_profiles WHERE user_id = $1` and return the result directly in the API response.

**Why it's wrong:** `tolerance_rating`, `verification_method`, and internal fields get returned to clients. RLS may allow the row read (the owner has read access) but not every field should be serialized to the response.

**Do this instead:** Always project specific columns in queries. Create explicit response serialization functions that whitelist fields by context (own profile, public view, admin view). Never return `*` in a query that feeds an API response.

```typescript
// Correct: field-level projection
const { data } = await supabase
  .from('connected_profiles')
  .select('id, user_id, display_name, verification_status, xp, gem_balance, veracity_rating, created_at')
  .eq('user_id', userId)
  .maybeSingle();
// tolerance_rating is NOT in the select — never returned to clients
```

---

### Anti-Pattern 4: Admin Routes on the Public Router

**What people do:** Add admin functionality as a flag check inside a public route handler: `if (user.isAdmin) { doAdminThing(); }`.

**Why it's wrong:** Admin logic mixed into public routes is easy to accidentally expose, hard to audit, and creates implicit coupling between public and admin behavior.

**Do this instead:** Separate Express router at `/api/admin/*` with its own middleware chain. Admin middleware is entirely separate from the public `authenticate` + `requireTier` chain. Clear boundary, independently auditable.

---

### Anti-Pattern 5: Cron Job That Can Crash the Server

**What people do:** Run the cron callback without try/catch. An unhandled exception from a DB query propagates up and crashes Node.

**Why it's wrong:** A demotion job failure should produce a log entry, not take down the API server.

**Do this instead:** Every cron callback is wrapped in a top-level try/catch. Errors are logged with enough context to debug. The cron continues scheduling future runs regardless of whether the previous run threw.

---

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Supabase Auth | JWT issued by Supabase; validated in Express via `supabase.auth.getUser(token)` | Use service role client for validation; anon key never server-side |
| Supabase DB | `@supabase/supabase-js` with service role key; RPC for transactions | All queries server-side only |
| Upstash Redis | `ioredis` or `@upstash/redis`; wrapped with in-memory Map fallback | Redis down must never crash the API |
| UptimeRobot | Pings `GET /api/health` every 5 minutes | Prevents Render cold starts on free tier |
| Notification service | TBD — email (Resend/SendGrid) or in-app; called from cron and route handlers | Decouple from transaction path — notify after commit |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Public API ↔ Admin Tool | Same Express app, separate routers | Admin tool is an internal React app calling `/api/admin/*` |
| Express ↔ Supabase | Service role client, RPC for transactions | Never expose service role key to client |
| Express ↔ Redis | Cache client singleton with fallback | Cache tier lookups and rate-limit state |
| Cron ↔ Service layer | Direct TypeScript function calls | Cron calls the same `executeDemotion` used by the route handler |
| Feature repos ↔ This API | HTTP REST calls to `/api/*` | Feature repos (Compass, Connect, etc.) are consumers; they hold no account logic |

---

## Suggested Build Order

### What Must Exist Before What

```
1. Supabase schema + migrations (foundation — nothing else can be built without it)
   └── Schema creation, public.users, connected_profiles, empowered_profiles
   └── Compass tables (inform schema)
   └── Connections, follows, roles, gems, verification sessions
   └── Invite codes (alpha enrollment)
   └── RLS policies (all schemas)
   └── Transaction RPC functions (empowerment, demotion, calibration lapse query)

2. Supabase client + auth middleware (gateway — all routes depend on this)
   └── db/client.ts — service role singleton
   └── middleware/auth.ts — JWT validation + tier detection
   └── cache/redis.ts — Redis with fallback
   └── GET /api/health

3. Auth routes (prerequisite for any user-facing flow)
   └── POST /api/auth/signup
   └── POST /api/auth/login
   └── POST /api/auth/logout

4. Account routes (required before tier-specific flows can be tested)
   └── GET /api/account/me
   └── PATCH /api/account/me

5. Connect flow (required before Empower flow — Empowered requires Connected)
   └── POST /api/connect/start
   └── GET /api/connect/status
   └── POST /api/connect/complete
   └── POST /api/connect/import-compass

6. Compass routes (required before Empower preflight can check calibration)
   └── GET /api/compass/topics
   └── PUT /api/compass/:topicId
   └── GET /api/compass/progress
   └── GET /api/compass (own responses)
   └── GET /api/compass/compare/:userId

7. Empower flow (requires Connect flow + Compass routes to be complete)
   └── POST /api/empower/preflight
   └── POST /api/empower/confirm
   └── POST /api/empower/demote

8. Social graph routes (can be built in parallel with Empower flow)
   └── Connections (request, accept/decline/block, list)
   └── Follows (follow, unfollow, list)

9. Calibration lapse cron (requires Empower flow to be complete + demotion RPC)
   └── services/cron/calibrationLapse.ts
   └── services/cron/index.ts registered at startup

10. Admin tool routes (can begin once account + connect + empower flows exist)
    └── /api/admin/invites
    └── /api/admin/accounts
    └── /api/admin/cohorts

11. Public candidate pages (last — requires Empower flow + real data)
    └── GET /api/candidates/:slug
```

---

## Sources

- Supabase RLS documentation: https://supabase.com/docs/guides/auth/row-level-security
- Supabase RPC / Postgres functions: https://supabase.com/docs/guides/database/functions
- `node-cron` documentation: https://www.npmjs.com/package/node-cron
- Express middleware composition patterns: https://expressjs.com/en/guide/using-middleware.html
- Postgres transaction isolation: https://www.postgresql.org/docs/current/transaction-iso.html
- Design context: `C:/EV-Accounts/empowered-accounts-design.md`
- Platform primer: `C:/EV-Accounts/empowered-vote-primer.md`
- Project requirements: `C:/EV-Accounts/.planning/PROJECT.md`

---
*Architecture research for: tiered account system — Supabase + Express/TypeScript*
*Researched: 2026-02-24*
