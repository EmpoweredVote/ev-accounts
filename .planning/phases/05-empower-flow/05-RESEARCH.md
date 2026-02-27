# Phase 5: Empower Flow - Research

**Researched:** 2026-02-27
**Domain:** Atomic tier transitions, preflight validation, slug reservation, consent auditing
**Confidence:** HIGH — all findings based on existing codebase + confirmed library types

---

## Summary

Phase 5 builds the empowerment and demotion lifecycle on top of RPC functions already
implemented in Phases 1 and 4. The two core RPC functions (`empower.execute_empowerment`
and `empower.execute_demotion`) are fully implemented and tested at the DB level; Phase 5
only needs to call them correctly from the Express layer. The majority of the work is:

1. A schema migration to add `candidate_role` to `connect.connected_profiles` (the
   role-scope field the preflight reads to determine which topics to check) and a
   `consent_records` table (or `consent_given_at` on `empowered_profiles`).
2. Two route files: `empower.ts` (preflight + confirm) and `demotion.ts` (demote + re-empower).
3. An `empowerService.ts` in `src/lib/` that handles slug reservation via the existing
   `cache` singleton, preflight logic, and wraps the RPC calls.
4. Migration of `GET /api/account/me` and `POST /api/empower/preflight` to surface
   demotion state (`empowerment_status`, `demoted_at`, `demotion_reason`).

The existing codebase provides all required patterns. No new dependencies are needed.

**Primary recommendation:** Use the existing `cache` singleton for slug reservation
(Redis with in-memory fallback — 1-hour TTL, `SET NX EX`). Store consent in a dedicated
`empower.consent_records` table — not inline on `empowered_profiles` — for auditability.

---

## Standard Stack

No new dependencies required. All needed libraries are already installed.

### Core (already installed)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `pg` | ^8.13.0 | Atomic pg transactions (BEGIN/COMMIT) | Required — Supabase JS cannot do transactions |
| `@supabase/supabase-js` | ^2.45.0 | `supabase.rpc()` for SECURITY DEFINER calls | Existing pattern |
| `@upstash/redis` | ^1.34.0 | Slug reservation (SET NX EX) | Existing cache infrastructure |
| `zod` | ^3.23.0 | Request body validation | Existing pattern |
| `express` | ^4.21.0 | Routing | Existing |

### No New Installations Required

The `cache` singleton in `src/lib/cache.ts` already supports the SET-with-TTL pattern
needed for slug reservation. The Upstash Redis `set` method accepts `{ nx: true, ex: number }`
options — confirmed in `@upstash/redis` type definitions at `zmscore-BjNXmrug.d.ts` line 291.

---

## Architecture Patterns

### Existing Project Structure (Phase 5 additions)
```
backend/src/
├── routes/
│   ├── empower.ts          # NEW — POST /api/empower/preflight + POST /api/empower/confirm
│   └── demotion.ts         # NEW — POST /api/empower/demote (admin/cron) + GET /api/empower/status
├── lib/
│   ├── empowerService.ts   # NEW — preflight logic, slug reservation, RPC wrappers
│   ├── cache.ts            # EXISTING — slug reservation uses this
│   ├── db.ts               # EXISTING — pg pool for atomic transactions
│   ├── supabase.ts         # EXISTING — supabaseAdmin.rpc() for SECURITY DEFINER calls
│   └── compassService.ts   # EXISTING — getCompassCompleteness() called by preflight
├── middleware/
│   ├── auth.ts             # EXISTING — requireAuth used by all empower routes
│   └── tierGuards.ts       # EXISTING — requireConnected used by preflight/confirm
supabase/migrations/
└── 20260227000018_empower_phase5.sql  # NEW — candidate_role, consent_records, demotion fields
```

### Pattern 1: Service Layer for supabaseAdmin Calls

The architecture test in `tests/integration/architecture.test.ts` enforces that
`supabaseAdmin` never appears in `src/routes/`. The test scans the `allowedFiles`
list — currently includes `lib/supabase.ts`, `lib/authService.ts`, `lib/inviteService.ts`,
`lib/enrollService.ts`. Phase 5 must add `lib/empowerService.ts` to that list.

The RPC calls (`execute_empowerment`, `execute_demotion`) must live in `empowerService.ts`,
not in the route file.

```typescript
// src/lib/empowerService.ts — CORRECT pattern
import { supabaseAdmin } from './supabase.js';

export async function callExecuteEmpowerment(
  userId: string,
  legalName: string,
  connectedProfileId: string
) {
  const { data, error } = await supabaseAdmin
    .schema('empower')
    .rpc('execute_empowerment', {
      p_user_id: userId,
      p_legal_name: legalName,
      p_connected_profile_id: connectedProfileId,
    });
  if (error) throw error;
  return data;
}
```

### Pattern 2: Slug Reservation via Cache (SET NX EX)

The `cache` singleton already supports TTL-based expiry. For slug reservation, the
`cache.set()` wrapper uses `redis.set(key, value, { ex: ttlSeconds })`. To implement
atomic "reserve if not taken" semantics, we must bypass the wrapper and use the raw
Upstash Redis `set` with `{ nx: true, ex: number }` — which the type system confirms
is supported.

The `cache` singleton wraps the raw client, so `empowerService.ts` should use
the raw `redis.set(...)` for reservation, or extend the `CacheClient` interface with
a `setNX` method. The simpler approach is to extend the `cache` singleton with a
`setIfAbsent` method:

```typescript
// Extend CacheClient interface in cache.ts:
interface CacheClient {
  get<T>(key: string): Promise<T | null>;
  set(key: string, value: unknown, ttlSeconds?: number): Promise<void>;
  del(key: string): Promise<void>;
  setIfAbsent(key: string, value: unknown, ttlSeconds: number): Promise<boolean>; // NEW
}

// Upstash Redis implementation:
async setIfAbsent(key: string, value: unknown, ttlSeconds: number): Promise<boolean> {
  const result = await redis.set(key, value, { nx: true, ex: ttlSeconds });
  return result === 'OK'; // Redis returns 'OK' on success, null if key exists
}

// InMemoryFallback implementation:
async setIfAbsent(key: string, value: unknown, ttlSeconds: number): Promise<boolean> {
  if (this.store.has(key)) {
    const entry = this.store.get(key)!;
    if (!entry.expiresAt || Date.now() <= entry.expiresAt) return false;
  }
  await this.set(key, value, ttlSeconds);
  return true;
}
```

**Slug reservation key format:** `slug_reservation:{userId}` — one reservation per user
at a time (preflight regeneration replaces the old key).

**TTL:** 3600 seconds (1 hour) — per locked decision.

**Why Redis over DB table:** The existing `cache` singleton is already wired up with
in-memory fallback, handles Upstash connection failures gracefully, and TTL-based
expiry is native to Redis. A DB table would require a background cleanup job.

### Pattern 3: All-Failures Preflight (collect, don't short-circuit)

Unlike middleware patterns that `return` on first failure, the preflight handler must
collect ALL failures into an array before returning:

```typescript
// src/routes/empower.ts
const failures: Array<{ code: string; message: string; [k: string]: unknown }> = [];

// Check 1: verified status
if (profile.verification_status !== 'verified') {
  failures.push({ code: 'NOT_VERIFIED', message: 'Your Connected account must be verified' });
}

// Check 2: calibration completeness (uses existing compassService.getCompassCompleteness)
const completeness = await getCompassCompleteness(userId, profile.candidate_role ?? undefined);
if (!completeness.complete) {
  failures.push({
    code: 'CALIBRATION_INCOMPLETE',
    message: `Calibrate ${completeness.required - completeness.answered} more topics`,
    threshold: completeness.required,
    current: completeness.answered,
  });
}

// Check 3: legal name
if (!profile.legal_name) {
  failures.push({ code: 'LEGAL_NAME_MISSING', message: 'Legal name is required' });
}

// Check 4: prior consent (for demoted users — consent is re-captured at confirm)
// NOTE: First-time empowerment consent is captured at POST /confirm, not preflight.
// Preflight only checks prior consent existence for demoted re-empowerment users.

if (failures.length > 0) {
  res.status(422).json({ eligible: false, failures });
  return;
}
```

### Pattern 4: Demoted User State

The `empowered_profiles` table has `is_active` (set to false on demotion). To surface
`empowerment_status: 'demoted'` and `demoted_at`, the `empowered_profiles` table needs
a `demoted_at TIMESTAMPTZ` column (set by the `execute_demotion` RPC update in Phase 5 migration).

The `GET /api/account/me` response currently returns `empowered_profile.is_active`. Phase 5
adds `empowerment_status` derived from that:

```typescript
// In GET /api/account/me (account.ts):
if (empowered) {
  meResponse.empowered_profile = {
    legal_name: empowered.legal_name,
    is_active: empowered.is_active,
    empowerment_status: empowered.is_active ? 'empowered' : 'demoted',
    demoted_at: empowered.demoted_at,          // NEW field
    candidate_page_slug: empowered.candidate_page_slug,
    empowered_at: empowered.empowered_at,
  };
}
```

### Pattern 5: RPC Call via supabaseAdmin.rpc()

The existing pattern for SECURITY DEFINER functions is `supabaseAdmin.schema('X').rpc(...)`.
The execute_empowerment function signature requires three parameters:

```sql
CREATE OR REPLACE FUNCTION empower.execute_empowerment(
  p_user_id              UUID,
  p_legal_name           TEXT,
  p_connected_profile_id UUID
)
RETURNS empower.empowered_profiles
```

The confirmed Phase 4 migration (migration 017) has already updated `execute_empowerment`
to include the compass visibility UPDATE. The Phase 5 migration needs to update it again
to add `consent_given_at` recording and `demoted_at` tracking to `execute_demotion`.

### Pattern 6: Re-empowerment — Slug Restoration

For demoted users, `empowered_profiles.candidate_page_slug` is never deleted (confirmed
by existing schema and RLS). The `execute_empowerment` RPC does an INSERT — it cannot
be called again for an already-empowered (even demoted) user without violating the
`UNIQUE(user_id)` constraint.

Phase 5 must update `execute_empowerment` to handle the re-empowerment case:

```sql
-- In empower.execute_empowerment update (Phase 5 migration):
-- Check if empowered_profiles row already exists (demoted user)
SELECT id, candidate_page_slug INTO v_existing_id, v_existing_slug
  FROM empower.empowered_profiles
  WHERE user_id = p_user_id;

IF v_existing_id IS NOT NULL THEN
  -- Re-empowerment: restore is_active, preserve original slug
  UPDATE empower.empowered_profiles
    SET is_active = true, empowered_at = now(), updated_at = now(), demoted_at = NULL
    WHERE user_id = p_user_id
    RETURNING * INTO v_result;
ELSE
  -- First empowerment: INSERT with new slug
  INSERT INTO empower.empowered_profiles (...) VALUES (...) RETURNING * INTO v_result;
END IF;
```

### Anti-Patterns to Avoid

- **Chained JS awaits for multi-table writes**: Never write `await insertProfile(); await updateCompass()`. Use the existing RPC functions which are atomic Postgres transactions.
- **supabaseAdmin in route files**: Always wrap in `lib/empowerService.ts`.
- **Short-circuit on first preflight failure**: Must collect ALL failures before returning.
- **Re-generating slug on confirm**: Slug is reserved at preflight, used at confirm. The confirm handler reads the slug from the reservation (Redis), not re-generates it.
- **Returning `legal_name` at root**: Must be nested in `empowered_profile` object per existing pattern.

---

## Schema Changes Required (Phase 5 Migration)

### New Migration: `20260227000018_empower_phase5.sql`

```sql
-- 1. Add candidate_role to connected_profiles
--    The preflight reads this to determine which topics are required.
--    Values mirror inform.compass_topic_roles.role_scope.
ALTER TABLE connect.connected_profiles
  ADD COLUMN IF NOT EXISTS candidate_role TEXT
  CHECK (candidate_role IN ('city_council', 'state_legislature', 'us_congress', 'president'));

-- 2. Add demoted_at to empowered_profiles
--    Set by execute_demotion. NULL = never demoted. Used in /account/me response.
ALTER TABLE empower.empowered_profiles
  ADD COLUMN IF NOT EXISTS demoted_at TIMESTAMPTZ;

-- 3. Add demotion_reason to empowered_profiles
--    Stores which topics lapsed (JSON array of topic IDs). Used by preflight for
--    demoted users to surface what needs recalibrating.
ALTER TABLE empower.empowered_profiles
  ADD COLUMN IF NOT EXISTS demotion_reason JSONB;

-- 4. Create empower.consent_records table
--    Durable consent audit log. One record per consent event (initial + re-empower).
--    Never deleted. consent_version allows future consent form versioning.
CREATE TABLE IF NOT EXISTS empower.consent_records (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  consent_given_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  consent_version   TEXT        NOT NULL DEFAULT 'v1',
  consented_items   TEXT[]      NOT NULL,  -- ['legal_name_public', 'stances_public', 'platform_terms']
  ip_address        TEXT,                  -- optional audit metadata
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_consent_records_user_id ON empower.consent_records(user_id);

-- RLS: owner sees own consent records only
ALTER TABLE empower.consent_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY "consent_records: owner read own"
  ON empower.consent_records FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);
-- No INSERT policy — service layer only (pg pool)

-- 5. Update execute_demotion to record demoted_at and demotion_reason
CREATE OR REPLACE FUNCTION empower.execute_demotion(p_user_id UUID, p_demotion_reason JSONB DEFAULT NULL)
...

-- 6. Update execute_empowerment to handle re-empowerment (UPDATE instead of INSERT for existing rows)
CREATE OR REPLACE FUNCTION empower.execute_empowerment(...)
...
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Atomic slug INSERT + compass UPDATE | Custom JS transaction | Existing `execute_empowerment` RPC | Already atomic, already tested |
| Slug uniqueness collision | Custom retry loop in JS | UNIQUE constraint on `candidate_page_slug` + DB-level collision | DB handles this; RPC already generates UUID suffix |
| Calibration completeness check | New SQL query | `getCompassCompleteness(userId, roleScope)` in `compassService.ts` | Already exists, already handles role scoping |
| Slug TTL expiry | DB table + cron cleanup | `cache.setIfAbsent(key, value, 3600)` | Redis TTL is automatic |
| Tier check in route | Inline SQL in route handler | `requireConnected` middleware (already exists) | Architecture pattern established |

**Key insight:** The hardest part of this phase (atomic empowerment transaction) is already
done in Postgres. Phase 5 is orchestration, not implementation of the atomicity.

---

## Common Pitfalls

### Pitfall 1: Architecture Test Violation — supabaseAdmin in routes/empower.ts
**What goes wrong:** Developer puts `supabaseAdmin.rpc('execute_empowerment', ...)` directly
in `routes/empower.ts`. The architecture test fails because `supabaseAdmin` is banned from
`src/routes/`.
**Why it happens:** The RPC call feels like it belongs near the route logic.
**How to avoid:** All `supabaseAdmin` calls go in `lib/empowerService.ts`. Routes call
service functions. Add `lib/empowerService.ts` to the `allowedFiles` array in
`tests/integration/architecture.test.ts`.
**Warning signs:** Test output: `Architecture violation: the following route files reference supabaseAdmin`.

### Pitfall 2: execute_empowerment Called on Demoted User Hits UNIQUE Violation
**What goes wrong:** Re-empowerment path calls `execute_empowerment` which tries to INSERT
a new `empowered_profiles` row. The `UNIQUE(user_id)` constraint raises an exception.
**Why it happens:** The Phase 1 RPC was written for first-time empowerment only.
**How to avoid:** Phase 5 migration must replace `execute_empowerment` with a version that
detects an existing row (demoted user) and uses UPDATE instead of INSERT. The slug is
preserved (original slug, not new slug) for demoted re-empowerment.
**Warning signs:** Postgres error `duplicate key value violates unique constraint "empowered_profiles_user_id_key"`.

### Pitfall 3: Slug Reservation Race Condition (Two Users, Same Legal Name)
**What goes wrong:** Two users with `legal_name = "Jane Smith"` call preflight
simultaneously. Both get slug `jane-smith-a3b4` if the RPC generates the same suffix.
**Why it happens:** `md5(gen_random_uuid())` is random but the reservation check and
RPC call aren't atomic.
**How to avoid:** The DB-level `UNIQUE(candidate_page_slug)` constraint is the final
arbiter. The RPC will retry slug generation on `UNIQUE_VIOLATION`. However, the
reservation key is per-user (`slug_reservation:{userId}`), so two users get separate
reservations regardless. The uniqueness is enforced by the DB UNIQUE constraint at
confirm time, not by the Redis reservation. If the DB INSERT fails (slug collision
between two simultaneous confirms), the transaction rolls back and the frontend should
call preflight again (new suffix).
**Warning signs:** Both users attempting confirm — one gets 500 from DB UNIQUE violation.

**Recommendation:** Update `execute_empowerment` to retry slug generation in a loop
(up to 5 attempts) on `unique_violation`, rather than relying on application-layer retry.

```sql
-- In updated execute_empowerment:
FOR i IN 1..5 LOOP
  v_suffix := substring(md5(gen_random_uuid()::text) FROM 1 FOR 4);
  v_slug := rtrim(lower(regexp_replace(p_legal_name, '[^a-zA-Z0-9]+', '-', 'g')), '-') || '-' || v_suffix;
  BEGIN
    INSERT INTO empower.empowered_profiles (..., candidate_page_slug) VALUES (..., v_slug) RETURNING * INTO v_result;
    EXIT; -- success
  EXCEPTION WHEN unique_violation THEN
    IF i = 5 THEN RAISE; END IF;
    -- retry
  END;
END LOOP;
```

### Pitfall 4: Consent Flag in Confirm Body — Missing Validation
**What goes wrong:** `POST /api/empower/confirm` body includes `{ consent: true }` but
the handler doesn't validate that all three consent items are checked. User can send
`{ consent: true }` without understanding what they agreed to.
**Why it happens:** Lazy validation.
**How to avoid:** Use structured Zod schema:

```typescript
const confirmBodySchema = z.object({
  consent: z.object({
    legal_name_public: z.literal(true),
    stances_public: z.literal(true),
    platform_terms: z.literal(true),
  }),
});
```
All three must be `true` (literal — not just truthy). Partial consent = 422.

### Pitfall 5: GET /api/account/me Response Missing empowerment_status for Demoted User
**What goes wrong:** Demoted user calls `/account/me`. Response shows `tier: 'connected'`
but no indication they were previously empowered. Frontend cannot offer tailored
re-empowerment CTA.
**Why it happens:** The existing `account.ts` only returns `empowered_profile` if the row
exists AND `is_active = true` (implied by RLS: owner sees own inactive rows, but the
existing query doesn't include the inactive row in the select).
**How to avoid:** The `GET /api/account/me` query uses `createUserClient` with RLS.
The RLS policy `"empowered_profiles: owner read own"` allows the owner to see their own
row regardless of `is_active`. Verify the SELECT query returns inactive rows for the
owner. Then derive `empowerment_status` from `is_active`:

```typescript
// account.ts — already selects from empowered_profiles for the owner.
// The existing SELECT returns the row even when is_active = false (owner policy covers it).
// Just add derived fields:
if (empowered) {
  meResponse.empowered_profile = {
    legal_name: empowered.legal_name,
    is_active: empowered.is_active,
    empowerment_status: empowered.is_active ? 'empowered' : 'demoted',
    demoted_at: empowered.demoted_at,
    candidate_page_slug: empowered.candidate_page_slug,
    empowered_at: empowered.empowered_at,
  };
}
```

### Pitfall 6: candidate_role NULL — Preflight Treats as "All Topics Required"
**What goes wrong:** User has no `candidate_role` set. `getCompassCompleteness(userId, undefined)`
checks ALL live topics. Some topics are only required for specific roles (e.g. US Congress
topics aren't required for city council candidates).
**Why it happens:** `candidate_role` is optional and may not be set when user first calls
preflight.
**How to avoid:** If `candidate_role` is NULL, the preflight should return a specific failure
code `ROLE_NOT_SET` so the frontend knows to prompt the user to set their role before
calling preflight.

```typescript
if (!profile.candidate_role) {
  failures.push({
    code: 'ROLE_NOT_SET',
    message: 'Select your candidate role before checking eligibility',
  });
}
// Only call getCompassCompleteness if role is set (otherwise threshold is undefined)
```

### Pitfall 7: comments in empower.ts Mentioning "supabaseAdmin"
**What goes wrong:** The architecture test uses `content.includes('supabaseAdmin')` —
a simple string search. A comment like `// uses supabaseAdmin internally` in `empower.ts`
triggers the test failure.
**Why it happens:** Developer adds explanatory comments.
**How to avoid:** Never put the string `supabaseAdmin` in any file under `src/routes/`,
not even in comments. This is documented in STATE.md decision [04-03].

---

## Code Examples

### Preflight Route Pattern

```typescript
// src/routes/empower.ts
// Source: derived from existing connect.ts pattern in this codebase

router.post('/preflight', requireAuth, requireConnected, async (req: Request, res: Response): Promise<void> => {
  const { userId } = req as AuthenticatedRequest;
  const client = await pool.connect();

  try {
    // Fetch connected_profiles (owner access — use createUserClient to respect RLS)
    // Can use pool directly since this is a trusted server-side preflight check
    const { rows: [profile] } = await client.query<{
      id: string;
      verification_status: string;
      legal_name: string | null;
      candidate_role: string | null;
    }>(
      `SELECT id, verification_status, legal_name, candidate_role
         FROM connect.connected_profiles
        WHERE user_id = $1`,
      [userId]
    );

    const failures: Array<Record<string, unknown>> = [];

    // Collect all failures (not short-circuit)
    if (profile.verification_status !== 'verified') {
      failures.push({ code: 'NOT_VERIFIED', message: 'Your Connected account must be verified' });
    }
    if (!profile.candidate_role) {
      failures.push({ code: 'ROLE_NOT_SET', message: 'Select your candidate role before checking eligibility' });
    }
    if (!profile.legal_name) {
      failures.push({ code: 'LEGAL_NAME_MISSING', message: 'Provide your legal name in your profile' });
    }

    // Only check calibration if role is known (otherwise threshold is meaningless)
    let completeness = null;
    if (profile.candidate_role) {
      completeness = await getCompassCompleteness(userId, profile.candidate_role);
      if (!completeness.complete) {
        failures.push({
          code: 'CALIBRATION_INCOMPLETE',
          message: `You need to calibrate ${completeness.required - completeness.answered} more topics`,
          threshold: completeness.required,
          current: completeness.answered,
        });
      }
    }

    // Surface demotion reason for demoted users
    let demotionContext = null;
    const { rows: [empowered] } = await client.query<{
      is_active: boolean;
      demotion_reason: unknown;
      demoted_at: string | null;
    }>(
      `SELECT is_active, demotion_reason, demoted_at
         FROM empower.empowered_profiles
        WHERE user_id = $1`,
      [userId]
    );
    if (empowered && !empowered.is_active) {
      demotionContext = {
        demoted_at: empowered.demoted_at,
        demotion_reason: empowered.demotion_reason,
      };
    }

    if (failures.length > 0) {
      res.status(422).json({ eligible: false, failures, demotion_context: demotionContext });
      return;
    }

    // Generate and reserve slug
    const slug = await reserveSlug(userId, profile.legal_name!);

    res.status(200).json({
      eligible: true,
      summary: {
        legal_name: profile.legal_name,
        compass_completeness: completeness,
        slug_preview: slug,
      },
      demotion_context: demotionContext,
    });
  } finally {
    client.release();
  }
});
```

### Slug Reservation in empowerService.ts

```typescript
// src/lib/empowerService.ts
// Source: cache singleton from src/lib/cache.ts + Upstash Redis SET NX EX pattern

const SLUG_TTL_SECONDS = 3600; // 1 hour per locked decision
const SLUG_KEY = (userId: string) => `slug_reservation:${userId}`;

export async function reserveSlug(userId: string, legalName: string): Promise<string> {
  // Generate slug: kebab-case + 4-char random suffix (mirrors existing RPC logic)
  const base = legalName.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
  const suffix = Math.random().toString(36).substring(2, 6);
  const slug = `${base}-${suffix}`;

  // Store reservation with 1-hour TTL (overwrites prior reservation for this user)
  await cache.set(SLUG_KEY(userId), slug, SLUG_TTL_SECONDS);
  return slug;
}

export async function getReservedSlug(userId: string): Promise<string | null> {
  return cache.get<string>(SLUG_KEY(userId));
}

export async function clearSlugReservation(userId: string): Promise<void> {
  await cache.del(SLUG_KEY(userId));
}
```

**Note:** The existing `cache.set` overwrites any existing value, which is the correct
behavior — calling preflight again regenerates the slug preview (per locked decision).
There is no need for SET NX here since we always want to overwrite with the latest preview.

### Confirm Route — Consent Capture and RPC Call

```typescript
// src/routes/empower.ts
const confirmBodySchema = z.object({
  consent: z.object({
    legal_name_public: z.literal(true),
    stances_public: z.literal(true),
    platform_terms: z.literal(true),
  }),
});

router.post('/confirm', requireAuth, requireConnected, async (req: Request, res: Response): Promise<void> => {
  const { userId, accessToken } = req as AuthenticatedRequest;

  const parsed = confirmBodySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({ code: 'CONSENT_REQUIRED', message: 'All three consent items must be explicitly agreed to' });
    return;
  }

  // Get reserved slug from cache
  const reservedSlug = await getReservedSlug(userId);
  if (!reservedSlug) {
    res.status(409).json({ code: 'PREFLIGHT_EXPIRED', message: 'Preflight reservation expired. Call /preflight again.' });
    return;
  }

  // Fetch connected_profile_id (needed for execute_empowerment)
  const client = await pool.connect();
  try {
    const { rows: [profile] } = await client.query<{ id: string; legal_name: string }>(
      'SELECT id, legal_name FROM connect.connected_profiles WHERE user_id = $1',
      [userId]
    );

    // Record consent (pg pool — service layer, no INSERT RLS policy needed)
    await client.query(
      `INSERT INTO empower.consent_records (user_id, consented_items)
       VALUES ($1, $2)`,
      [userId, ['legal_name_public', 'stances_public', 'platform_terms']]
    );

    // Call RPC — atomic empowerment (SECURITY DEFINER, runs in empowerService.ts)
    await callExecuteEmpowerment(userId, profile.legal_name, profile.id);

    // Clear slug reservation after successful empowerment
    await clearSlugReservation(userId);

    res.status(200).json({ empowered: true, candidate_page_slug: reservedSlug });
  } catch (err) {
    console.error('[POST /empower/confirm] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  } finally {
    client.release();
  }
});
```

**Important:** The slug used at confirm is the one from the Redis reservation (not
re-generated). However, the actual slug stored in `empowered_profiles` is the one
generated by the RPC function at INSERT time (the RPC generates its own suffix).
This creates a discrepancy — the reserved slug and the actual stored slug may differ
if the RPC generates a different suffix.

**Resolution:** The RPC function generates its own slug internally. Phase 5 should
update `execute_empowerment` to accept a `p_reserved_slug TEXT` parameter, using it
instead of generating a new one. This ensures the preflight preview matches the confirmed
slug.

```sql
-- Updated execute_empowerment signature:
CREATE OR REPLACE FUNCTION empower.execute_empowerment(
  p_user_id              UUID,
  p_legal_name           TEXT,
  p_connected_profile_id UUID,
  p_reserved_slug        TEXT  -- NEW: pass the preflight-reserved slug
)
RETURNS empower.empowered_profiles
...
-- Use p_reserved_slug instead of generating v_slug
-- Retry with new suffix on unique_violation (slug already taken by another user)
```

### Demotion Route Pattern

```typescript
// src/routes/demotion.ts (or combined in empower.ts)

router.post('/demote', requireAuth, requireEmpowered, async (req: Request, res: Response): Promise<void> => {
  const { userId } = req as AuthenticatedRequest;

  try {
    // callExecuteDemotion is in empowerService.ts (wraps supabaseAdmin.rpc)
    await callExecuteDemotion(userId, /* demotion_reason */ null);
    res.status(200).json({ demoted: true });
  } catch (err) {
    console.error('[POST /empower/demote] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});
```

---

## Discretionary Decisions (Claude's Recommendations)

These were explicitly left to Claude's discretion in CONTEXT.md.

### 1. Consent Capture: Flag in Confirm Body (Recommended)

**Recommendation:** Consent captured as structured object in `POST /api/empower/confirm`
body. No separate endpoint.

**Rationale:** A separate `/consent` endpoint creates a two-step confirm flow where the
frontend could call confirm without consent, or consent without confirming. Having consent
in the confirm body makes them atomic from the API perspective — you cannot confirm without
attaching consent. The Zod schema with `z.literal(true)` on each item ensures explicit
agreement to each of the three consent items.

### 2. Consent Storage: Dedicated `empower.consent_records` Table (Recommended)

**Recommendation:** Create `empower.consent_records` table (not inline on `empowered_profiles`).

**Rationale:** The locked decision says "durable record with timestamp required." A dedicated
table supports: (a) multiple consent events per user (re-empowerment creates a new consent
record), (b) versioning via `consent_version`, (c) storing individual consented items as
an array, (d) optional IP address for audit. If consent were inline on `empowered_profiles`,
re-empowerment would overwrite the original consent timestamp. The audit trail requires
that every consent event is preserved.

### 3. Demotion Reason Field Names

**Recommendation:**
```typescript
{
  code: 'CALIBRATION_INCOMPLETE',         // Not CALIBRATION_THRESHOLD_NOT_MET
  message: '...',
  threshold: number,
  current: number,
}
// For demotion reason stored in DB:
demotion_reason: {
  lapsed_topic_ids: string[],             // Array of topic UUIDs that lapsed
  lapsed_at: string,                      // ISO timestamp
  triggered_by: 'cron' | 'admin',
}
```

**Rationale:** `CALIBRATION_INCOMPLETE` is shorter and matches the EMPR-01 requirement
wording. Frontend can display `lapsed_topic_ids` directly to fetch topic titles for
the user-facing message.

### 4. Slug Reservation Storage: Redis via Existing `cache` Singleton (Recommended)

**Rationale:** No new infrastructure. The `cache` singleton already has in-memory
fallback, handles connection failures, and TTL is native to Redis. The reservation
is just `cache.set(key, slug, 3600)` — one line of code.

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| `supabase.rpc()` returns partial state on error | SECURITY DEFINER + `RAISE` causes full Postgres rollback | Phase 5 can trust RPC = atomic or exception |
| Slug generation with app-level collision check | DB UNIQUE constraint + loop in RPC | DB is the arbiter, not the app |
| `@supabase/auth-helpers-*` | `@supabase/ssr` | This project already uses the correct current library |
| Per-request supabase client for all operations | Dual client (supabaseAdmin for writes, createUserClient for reads) | Architecture test enforces this |

**Deprecated/outdated:**
- Phase 1 `execute_empowerment` (migration 010): Phase 4 already replaced it (migration 017). Phase 5 replaces it again with re-empowerment support and `p_reserved_slug` parameter.
- Phase 1 `execute_demotion` (migration 010): Phase 4 replaced it (migration 017). Phase 5 replaces it again with `p_demotion_reason JSONB` parameter and `demoted_at` tracking.

---

## Open Questions

1. **execute_empowerment slug parameter vs. DB-generated slug**
   - What we know: The RPC currently generates its own slug internally. The preflight
     reservation generates a preview slug in the app layer.
   - What's unclear: Should the RPC accept the reserved slug as a parameter, or should
     the app discard the preview and use whatever the RPC generates?
   - Recommendation: Pass the reserved slug to the RPC as `p_reserved_slug`. The RPC
     uses it as the first attempt and falls back to a new random suffix on unique_violation.
     This guarantees the preflight preview equals the confirmed slug (the locked decision
     says "guaranteed to be the same slug used at confirm").

2. **Route naming: /api/empower/ or /api/empowerment/**
   - What we know: CONTEXT.md says `POST /api/empower/preflight`. Roadmap says "empower routes".
   - Recommendation: Use `/api/empower/` prefix (matches CONTEXT.md).

3. **Who calls execute_demotion in Phase 5**
   - What we know: Phase 5 requirement includes demotion flow. The cron job (Phase 7) also
     calls it.
   - What's unclear: Does Phase 5 expose a `POST /api/empower/demote` for admin use, or
     is demotion only triggered by the cron in Phase 7?
   - Recommendation: Phase 5 implements the route + service layer. Admin access control
     (requireAdmin middleware) is Phase 7. For Phase 5, `requireEmpowered` is sufficient
     (user can self-demote, or admin can call with elevated access in Phase 7).

---

## Sources

### Primary (HIGH confidence)
- Existing codebase: `/c/EV-Accounts/supabase/migrations/20260224000010_rpc_functions.sql` — Phase 1 RPC signatures
- Existing codebase: `/c/EV-Accounts/supabase/migrations/20260226000017_rpc_updates_phase4.sql` — Phase 4 RPC updates (current state)
- Existing codebase: `/c/EV-Accounts/backend/src/lib/cache.ts` — cache singleton implementation
- Existing codebase: `/c/EV-Accounts/backend/node_modules/@upstash/redis/zmscore-BjNXmrug.d.ts` lines 291, 1535 — `SetCommandOptions` with `nx: true` support confirmed
- Existing codebase: `/c/EV-Accounts/tests/integration/architecture.test.ts` — `allowedFiles` list for supabaseAdmin
- Existing codebase: `/c/EV-Accounts/supabase/migrations/20260224000009_rls_empower.sql` — RLS: owner reads own inactive empowered_profiles row

### Secondary (MEDIUM confidence)
- Existing codebase: STATE.md `[04-03]` decision — comments in route files must not mention supabaseAdmin string (architecture test string match)
- CONTEXT.md (locked decisions): slug reserved at preflight, 1-hour TTL, original slug restored on re-empower, all failures at once

### Tertiary (LOW confidence)
- None — all findings based on direct code inspection

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; all confirmed from package.json and node_modules type defs
- Architecture patterns: HIGH — all derived from existing codebase patterns
- Pitfalls: HIGH — most derived from existing architecture tests and schema constraints
- Slug reservation recommendation: HIGH — Upstash Redis SET NX EX confirmed in type definitions

**Research date:** 2026-02-27
**Valid until:** 2026-03-28 (30 days — stable stack)
