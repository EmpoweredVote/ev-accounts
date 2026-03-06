# Phase 13: CompassV2 Backend Compatibility - Research

**Researched:** 2026-03-06
**Domain:** Express 4.x route handlers, Supabase PostgREST, PostgreSQL migrations, TypeScript strict
**Confidence:** HIGH — all findings verified directly from codebase source files

## Summary

Phase 13 adds three new API endpoints to close specific gaps discovered in the CompassV2 bundle. The research is entirely internal: there are no new third-party libraries, no ecosystem choices, and no architectural decisions left open. Every pattern needed already exists in the codebase — the work is applying those patterns correctly to new routes.

The three endpoints are: `DELETE /api/compass/answers/me` (soft-delete reset), `GET /api/essentials/politicians` (unauthenticated politician list with candidate grouping), and an expansion of `POST /api/connect/compass-import` (add `selected_topics` import support). A prerequisite migration must also repair the `inform` schema namespace and add the `is_candidate` column to `inform.politicians`.

**Primary recommendation:** Build each endpoint by directly mirroring the nearest existing analog in the codebase. No new libraries, no new patterns. The architecture test at `tests/integration/architecture.test.ts` enforces constraints that must not be broken — verify all new service files are added to its allowlist.

---

## Standard Stack

All libraries are already installed. Phase 13 adds no new dependencies.

### Core (already in project)
| Library | Purpose | How Used |
|---------|---------|----------|
| `express` 4.x | HTTP routing | `Router()`, middleware chain |
| `zod` | Request body validation | `z.object().safeParse()` pattern |
| `@supabase/supabase-js` | Database client | `supabaseAnon`, `createUserClient`, `adminRpc` |
| `jose` | JWT verification | Already in `middleware/auth.ts` |

### Client Selection Rules (architecture-enforced)
| Data access | Client | Why |
|-------------|--------|-----|
| Public reference reads (inform.politicians) | `supabaseAnon` | RLS allows anon SELECT on all 8 inform reference tables |
| User-owned reads (compass_responses) | `createUserClient(accessToken)` | RLS enforces owner-only SELECT |
| Admin writes / SECURITY DEFINER RPC | `adminRpc()` or `supabaseAdmin` in lib/ only | Bypasses RLS; banned from routes/ |
| `completed_onboarding` write | `supabaseAdmin` in lib/ | Not in column-level UPDATE GRANT for authenticated role (verified in `enrollService.ts`) |

**Installation:** No new packages needed.

---

## Architecture Patterns

### Verified Project Structure
```
backend/src/
├── routes/          # Express routers — NO supabaseAdmin (enforced by architecture test)
│   ├── compass.ts   # Existing — DELETE /answers/me goes here
│   ├── connect.ts   # Existing — modified compass-import goes here
│   └── essentials/  # New route file: GET /api/essentials/politicians
├── lib/
│   ├── compassService.ts    # Existing service — new reset function goes here
│   ├── connectService.ts    # Existing service — new import functions go here
│   ├── essentialsService.ts # NEW: politicians query function (supabaseAnon)
│   └── enrollService.ts     # Existing — completeOnboarding() pattern to reuse
├── middleware/
│   └── requireAdmin.ts      # Pattern for admin-only flag enforcement
└── types/
    └── database.types.ts    # Must be updated: add is_candidate to inform.politicians
```

### Pattern 1: Route Handler — Idempotent Soft Delete
The `DELETE /compass/answers/me` follows the pattern of existing write routes: validate auth via `requireAuth`, delegate DB work to a service function, return 200 for all success cases including already-empty state.

**Key constraint:** `compass_responses` has no DELETE RLS policy. All deletes must go through a SECURITY DEFINER RPC or raw pg pool (same pattern as upsert_compass_answer). The soft-delete (`deleted_at` column) requires an ALTER TABLE migration first.

Analog to study: `POST /compass/answers` → `adminRpc('upsert_compass_answer', ...)`.

```typescript
// Source: backend/src/routes/compass.ts line 330–367
router.post('/answers', requireAuth, async (req: Request, res: Response): Promise<void> => {
  // ... validation ...
  const { data, error } = await adminRpc('upsert_compass_answer', { p_user_id: authReq.userId, ... });
  if (error) { /* map error codes → HTTP status */ throw ... }
  res.status(200).json(data);
});
```

**For the `?full=true` admin gate:** The existing `requireAdmin` middleware checks `public.admin_users`. For this endpoint, admin check happens inside the handler (not as router middleware) because regular users can also call DELETE without the flag. Check: if `req.query.full === 'true'` then verify admin status via a guard function in the service layer before proceeding.

### Pattern 2: Unauthenticated Route — Public Read
The `GET /api/essentials/politicians` uses `optionalAuth` (consistent with `/compass/politicians`) and calls `supabaseAnon` for the query. The new route mounts under `/api/essentials/politicians` — a new route file `essentialsPoliticians.ts` alongside the existing `essentialsCandidates.ts`.

```typescript
// Source: backend/src/routes/compass.ts line 248–256
router.get('/politicians', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const data = await getCompassPoliticians();
    res.status(200).json(data);
  } catch (err) {
    console.error('[GET /compass/politicians] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});
```

**Response grouping happens in the service layer, not in the route handler.** The service fetches politicians and groups by `office_title` in JavaScript — one query, then reduce into `{ office_title, incumbent, candidates[] }`.

### Pattern 3: Upsert with Merge Semantics
The updated `POST /api/connect/compass-import` must accept a `selected_topics` array alongside `calibrations`. The merge behavior (upsert by topic_id, leave untouched topics alone) matches the existing `upsert_compass_answer` RPC approach — the actual write to `inform.compass_responses` must go through a SECURITY DEFINER RPC to satisfy the no-RLS-write-policy constraint on that table.

### Pattern 4: completeOnboarding is already implemented
`enrollService.completeOnboarding(userId)` already exists and handles the `completed_onboarding` flag. It uses `supabaseAdmin` (correctly, since `completed_onboarding` is not in the column-level UPDATE GRANT for authenticated). The compass-import endpoint should call this function directly when the `selected_topics` threshold is met.

```typescript
// Source: backend/src/lib/enrollService.ts line 74–100
export async function completeOnboarding(userId: string): Promise<'ok' | 'already_complete' | 'not_connected'> {
  // uses supabaseAdmin — completed_onboarding not in column-level UPDATE GRANT
}
```

### Pattern 5: Admin check without router.use(requireAdmin)
For the `?full=true` flag on `DELETE /compass/answers/me`, the admin check is conditional inside the handler. Pattern from `requireAdmin.ts`:

```typescript
// Source: backend/src/middleware/requireAdmin.ts line 17–35
const { data, error } = await supabaseAdmin
  .from('admin_users')
  .select('user_id')
  .eq('user_id', authReq.userId)
  .maybeSingle();
if (error || !data) { res.status(403).json({ error: 'Admin access required' }); return; }
```

This call must live in a service function (e.g., `compassService.isAdmin(userId)`), NOT inline in the route — the architecture test bans `supabaseAdmin` from `routes/`.

### Anti-Patterns to Avoid

- **Using supabaseAdmin in routes/:** The architecture test reads all `.ts` files in `routes/` and fails if `supabaseAdmin` appears. New route files will be scanned automatically.
- **Adding supabaseAdmin to a new lib/ file without updating the architecture test:** The test has an explicit allowlist (`allowedFiles` array). Any new service file that uses `supabaseAdmin` must be added to that array or the test fails.
- **Writing to compass_responses via createUserClient:** There are no INSERT/UPDATE/DELETE RLS policies on `inform.compass_responses`. Writes through `createUserClient` will fail silently (0 rows affected, no error) or error with a PostgREST policy violation. All writes must use SECURITY DEFINER RPC via `adminRpc()`.
- **Writing to inform_selected_topics directly:** There is no `inform_selected_topics` table — selected topic IDs live in `connect.connected_profiles.selected_topic_ids` (JSONB column). The existing `saveSelectedTopics()` in `compassService.ts` is the right write path.
- **Assuming `deleted_at` column exists on compass_responses:** It does not. The soft-delete migration must be written and applied before the reset endpoint can work.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Admin status check | Inline supabaseAdmin in route handler | Service function in lib/ that uses supabaseAdmin | Architecture test bans supabaseAdmin in routes/ |
| `completed_onboarding` flag set | New update query | `enrollService.completeOnboarding(userId)` | Already implemented, handles idempotency and all edge cases |
| Save selected topics | New JSONB update | `compassService.saveSelectedTopics(accessToken, userId, topicIds)` | Already implemented with RLS-enforced write path |
| Validate topic IDs | Custom query | `compassService.validateTopicIds(topicIds)` | Already implemented |
| Topic version validation | New query | `connectService.validateCompassVersions(calibrations)` | Already implemented |
| Politician read (public) | supabaseAdmin | `supabaseAnon` + `GRANT SELECT` already in migration 016 | RLS policy "politicians: public read" covers anon role |

**Key insight:** Phase 13's service-layer functions are building on an already complete foundation. The primary work is: (a) new migration for schema changes, (b) new SECURITY DEFINER RPC for the soft-delete transaction, (c) thin service functions wrapping those, and (d) route handlers following the established patterns.

---

## Common Pitfalls

### Pitfall 1: Architecture Test Allowlist Not Updated
**What goes wrong:** A new service file (e.g., `essentialsService.ts` or `compassResetService.ts`) that uses `supabaseAdmin` causes the architecture test to fail because it is not in the `allowedFiles` array.
**Why it happens:** The architecture test at `tests/integration/architecture.test.ts` line 49–88 has a hardcoded list of files permitted to use `supabaseAdmin`.
**How to avoid:** Add any new lib/ file that uses `supabaseAdmin` to the `allowedFiles` array in the architecture test before running the suite.
**Warning signs:** Architecture test failure mentioning "supabaseAdmin found in unexpected files."

### Pitfall 2: Soft-Delete Column Missing from types
**What goes wrong:** TypeScript compile fails when referencing `deleted_at` on `compass_responses` because the column is not in `database.types.ts`.
**Why it happens:** `database.types.ts` is not auto-generated from the live DB (the inform schema was manually appended). The new `deleted_at` column added by migration must also be manually added to the types.
**How to avoid:** After writing the migration, update `database.types.ts` to add `deleted_at: string | null` to the `inform.compass_responses` Row/Insert/Update types.

### Pitfall 3: Writing to compass_responses Without RPC
**What goes wrong:** A soft-delete update via `createUserClient` or `supabaseAnon` silently writes 0 rows because there is no UPDATE RLS policy on `inform.compass_responses`.
**Why it happens:** Migration 016 explicitly states: "No INSERT/UPDATE/DELETE policies on compass_responses or compass_change_history — all writes via pg pool / SECURITY DEFINER."
**How to avoid:** All writes to `compass_responses` (including soft-delete updates) must go through a SECURITY DEFINER RPC. Create a new RPC `reset_compass_answers(p_user_id UUID)` in the migration.

### Pitfall 4: Grouping Response Shape Built in the DB Layer
**What goes wrong:** Attempting to do `GROUP BY office_title` in a PostgREST query — PostgREST does not support GROUP BY in `.select()` calls; you'd need a view or RPC.
**How to avoid:** Fetch the flat list from `supabaseAnon`, then group in JavaScript using `Array.reduce()`. This is intentional and correct here since the data set is small (handful of politicians).

### Pitfall 5: is_candidate Column Missing from database.types.ts
**What goes wrong:** TypeScript errors when querying `is_candidate` from `inform.politicians` because the column doesn't exist in the type definitions yet.
**Why it happens:** Same as Pitfall 2 — types are manually maintained for the inform namespace.
**How to avoid:** Add `is_candidate: boolean` to the `politicians` Row/Insert/Update type definitions immediately after writing the migration.

### Pitfall 6: Compass Import — No Session Required for Post-Connect Users
**What goes wrong:** The current `POST /api/connect/compass-import` requires a verification session (`getVerificationSessionId` returns null → 404). Post-Connect users have no session, so they cannot use this endpoint to import calibrations.
**Why it happens:** The existing endpoint was designed for the pre-Connect flow only (Phase 3). Phase 13 extends it for post-Connect use too.
**How to avoid:** The expanded endpoint must check: if the user already has a `connected_profiles` row, bypass the session requirement and write directly to `inform.compass_responses` via the RPC. Only require a session if the user is pre-Connect.

### Pitfall 7: selected_topics Stored in connected_profiles, Not a Separate Table
**What goes wrong:** Code attempts to insert rows into a non-existent `inform_selected_topics` table.
**Why it happens:** The CONTEXT.md mentions `inform_selected_topics` in the phase description but the actual column is `connect.connected_profiles.selected_topic_ids` (JSONB).
**How to avoid:** Use `compassService.saveSelectedTopics()` for all selected topic writes. Verify column name in `database.types.ts` → `connected_profiles.Row.selected_topic_ids: Json`.

### Pitfall 8: The inform Schema Repair Migration is a Prerequisite
**What goes wrong:** All inform schema queries fail in production because `CREATE SCHEMA IF NOT EXISTS inform;` never ran (migration 015 applied but schema creation failed silently).
**Why it happens:** Documented open blocker in STATE.md.
**How to avoid:** Phase 13's first migration must be the repair: `CREATE SCHEMA IF NOT EXISTS inform;` followed by `CREATE TABLE IF NOT EXISTS ...` for all 10 inform tables (idempotent). Only then can subsequent migrations add new columns safely.

---

## Code Examples

Verified patterns from codebase source files:

### Soft-Delete via RPC (pattern from upsert_compass_answer)
```typescript
// Source: backend/src/routes/compass.ts line 346–359
const { data, error } = await adminRpc('upsert_compass_answer', {
  p_user_id: authReq.userId,
  p_topic_id: topic_id,
  p_value: value,
  p_write_in_text: write_in_text ?? null,
  p_inverted: inverted,
});
if (error) {
  if (error.message === 'TOPIC_NOT_FOUND') {
    res.status(404).json({ code: 'TOPIC_NOT_FOUND', message: 'Topic not found or not live' });
    return;
  }
  throw new Error(error.message);
}
res.status(200).json(data);
```

### Unauthenticated Public Read (supabaseAnon pattern)
```typescript
// Source: backend/src/lib/compassService.ts line 168–179
export async function getCompassPoliticians() {
  const { data, error } = await supabaseAnon
    .schema('inform')
    .from('politicians')
    .select('id,first_name,last_name,preferred_name,full_name,office_title,photo_origin_url,is_active')
    .eq('is_active', true)
    .order('last_name', { ascending: true })
    .order('first_name', { ascending: true });
  if (error) throw error;
  return data ?? [];
}
```

### completeOnboarding (supabaseAdmin in lib/ only)
```typescript
// Source: backend/src/lib/enrollService.ts line 74–100
export async function completeOnboarding(userId: string): Promise<'ok' | 'already_complete' | 'not_connected'> {
  const { data: updatedRows, error: updateError } = await supabaseAdmin
    .schema('connect')
    .from('connected_profiles')
    .update({ completed_onboarding: true, updated_at: new Date().toISOString() })
    .eq('user_id', userId)
    .eq('completed_onboarding', false)
    .select('id');
  // ... handles 'already_complete' and 'not_connected' cases
}
```

### Error Shape (consistent across all routes)
```typescript
// Source: backend/src/routes/compass.ts (multiple locations)
res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
res.status(422).json({ code: 'VALIDATION_ERROR', message: firstIssue?.message ?? 'Invalid request body' });
res.status(404).json({ code: 'NOT_FOUND', message: '...' });
res.status(403).json({ code: 'FORBIDDEN', message: '...' });
```

### Architecture Test Allowlist (must be updated for new service files)
```typescript
// Source: tests/integration/architecture.test.ts line 51–66
const allowedFiles = [
  path.join(BACKEND_SRC, 'lib/supabase.ts'),
  path.join(BACKEND_SRC, 'lib/authService.ts'),
  path.join(BACKEND_SRC, 'lib/inviteService.ts'),
  path.join(BACKEND_SRC, 'lib/enrollService.ts'),
  path.join(BACKEND_SRC, 'lib/empowerService.ts'),
  path.join(BACKEND_SRC, 'lib/gemService.ts'),
  path.join(BACKEND_SRC, 'lib/roleService.ts'),
  path.join(BACKEND_SRC, 'lib/socialService.ts'),
  path.join(BACKEND_SRC, 'lib/adminService.ts'),
  path.join(BACKEND_SRC, 'lib/candidateService.ts'),
  path.join(BACKEND_SRC, 'lib/xpService.ts'),
  path.join(BACKEND_SRC, 'lib/cronService.ts'),
  path.join(BACKEND_SRC, 'middleware/auth.ts'),
  path.join(BACKEND_SRC, 'middleware/tierGuards.ts'),
  path.join(BACKEND_SRC, 'middleware/requireVerified.ts'),
  path.join(BACKEND_SRC, 'middleware/requireAdmin.ts'),
];
// Add any new lib/*.ts that uses supabaseAdmin to this array
```

---

## Migration Plan (required before routes work)

Three migrations are needed, in order:

### Migration 031: Repair inform schema + add soft-delete + add is_candidate
```sql
-- Must run first — repairs the open blocker
CREATE SCHEMA IF NOT EXISTS inform;

-- Idempotent table creation (all 10 tables from migration 015)
-- Uses CREATE TABLE IF NOT EXISTS throughout

-- New columns for Phase 13:
ALTER TABLE inform.compass_responses
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

ALTER TABLE inform.politicians
  ADD COLUMN IF NOT EXISTS is_candidate BOOLEAN NOT NULL DEFAULT false;

-- Index on non-deleted responses (primary access pattern after reset feature)
CREATE INDEX IF NOT EXISTS idx_compass_responses_user_active
  ON inform.compass_responses(user_id)
  WHERE deleted_at IS NULL;
```

### Migration 032: SECURITY DEFINER RPC for compass reset
```sql
CREATE OR REPLACE FUNCTION public.reset_compass_answers(
  p_user_id UUID,
  p_full_reset BOOLEAN DEFAULT false
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- Soft-delete all compass_responses for the user
  UPDATE inform.compass_responses
    SET deleted_at = now()
    WHERE user_id = p_user_id
      AND deleted_at IS NULL;

  -- Clear selected_topic_ids in connected_profiles
  UPDATE connect.connected_profiles
    SET selected_topic_ids = '[]'::jsonb,
        updated_at = now()
    WHERE user_id = p_user_id;

  -- Full reset: also clear completed_onboarding (admin-only, enforced at app layer)
  IF p_full_reset THEN
    UPDATE connect.connected_profiles
      SET completed_onboarding = false,
          updated_at = now()
      WHERE user_id = p_user_id;
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$$;
```

### Migration 033: SECURITY DEFINER RPC for bulk compass import
```sql
-- New RPC: import_compass_calibrations(p_user_id, p_calibrations JSONB)
-- Iterates calibrations, upserts each via ON CONFLICT (user_id, topic_id) DO UPDATE
-- Called by the expanded compass-import endpoint for post-Connect users
```

---

## Type Updates Required

After migrations, `database.types.ts` must be updated manually (inform namespace is not auto-generated):

1. `inform.compass_responses.Row` — add `deleted_at: string | null`
2. `inform.compass_responses.Insert` — add `deleted_at?: string | null`
3. `inform.compass_responses.Update` — add `deleted_at?: string | null`
4. `inform.politicians.Row` — add `is_candidate: boolean`
5. `inform.politicians.Insert` — add `is_candidate?: boolean`
6. `inform.politicians.Update` — add `is_candidate?: boolean`

---

## Route Registration

New route file `backend/src/routes/essentialsPoliticians.ts` must be registered in `backend/src/index.ts`:

```typescript
// Source: backend/src/index.ts line 54
app.use('/api/essentials/candidates', essentialsCandidatesRouter);
// Add below:
app.use('/api/essentials/politicians', essentialsPoliticiansRouter);
```

---

## Open Questions

1. **Atomic import RPC vs. N individual upserts**
   - What we know: the existing `upsert_compass_answer` RPC handles one row. Bulk import needs to handle potentially dozens of rows atomically.
   - What's unclear: whether to call `upsert_compass_answer` N times in sequence (simpler, but not a single atomic transaction) or write a new `import_compass_calibrations` RPC that loops internally.
   - Recommendation: write a new bulk RPC to guarantee the all-or-nothing requirement from the CONTEXT decisions ("if any row fails validation, reject the entire import").

2. **Admin check for ?full=true — which service file?**
   - What we know: `requireAdmin` middleware uses `supabaseAdmin` and is in `middleware/`. A conditional admin check inside the compass reset handler must use a function from `lib/`, not inline code.
   - What's unclear: whether to add an `isAdmin(userId)` helper to an existing lib file or create a new one.
   - Recommendation: add `isAdmin(userId)` to `adminService.ts` — it already uses `supabaseAdmin` and is already in the allowlist.

3. **informSelectedTopics column update grant**
   - What we know: `connect.connected_profiles.selected_topic_ids` can be updated by `compassService.saveSelectedTopics()` via `createUserClient`. Migration 028 grants `UPDATE (selected_topic_ids)` to `authenticated` role.
   - What's unclear: whether the reset (clearing to `[]`) can also use `createUserClient` or must use the SECURITY DEFINER RPC.
   - Recommendation: include selected_topic_ids clear inside the `reset_compass_answers` SECURITY DEFINER RPC for atomicity (already in the migration plan above).

---

## Sources

### Primary (HIGH confidence — verified from codebase)
- `backend/src/routes/compass.ts` — existing route patterns, error shapes, auth middleware usage
- `backend/src/routes/connect.ts` — existing compass-import endpoint to be extended
- `backend/src/lib/compassService.ts` — service functions, supabaseAnon pattern for inform reads
- `backend/src/lib/connectService.ts` — existing service patterns for connect schema
- `backend/src/lib/enrollService.ts` — `completeOnboarding()` implementation (supabaseAdmin in lib/)
- `backend/src/lib/supabase.ts` — client definitions: supabaseAdmin, supabaseAnon, createUserClient, adminRpc
- `backend/src/middleware/auth.ts` — requireAuth, optionalAuth middleware
- `backend/src/middleware/requireAdmin.ts` — admin check pattern
- `tests/integration/architecture.test.ts` — enforced dual-client constraint and allowlist
- `tests/integration/compass.test.ts` — CI-safe test patterns for new endpoints to follow
- `supabase/migrations/20260226000015_inform_schema.sql` — inform.politicians column definitions
- `supabase/migrations/20260226000016_inform_rls_grants.sql` — RLS policies: politicians public read, compass_responses owner-only
- `supabase/migrations/20260226000017_rpc_updates_phase4.sql` — SECURITY DEFINER RPC pattern
- `supabase/migrations/20260303000028_grant_connected_profiles_selected_topics.sql` — column-level GRANT pattern
- `backend/src/types/database.types.ts` — current type definitions for inform and connect schemas
- `.planning/STATE.md` — open blocker: inform schema missing from live DB

### No external sources consulted
All research findings come directly from the codebase. No WebSearch or external documentation was needed — the patterns are fully established internally.

---

## Metadata

**Confidence breakdown:**
- Migration plan: HIGH — derived from existing migrations and schema state
- Route patterns: HIGH — verified against implemented routes
- Architecture constraints: HIGH — verified against enforced test suite
- Type update requirements: HIGH — cross-checked with database.types.ts
- RPC design: MEDIUM — structure is clear, exact SQL needs authoring

**Research date:** 2026-03-06
**Valid until:** Stable — this codebase changes only with new phases
