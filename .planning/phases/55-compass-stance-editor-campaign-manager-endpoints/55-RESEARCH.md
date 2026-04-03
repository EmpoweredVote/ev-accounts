# Phase 55: Compass Stance Editor + Campaign Manager Endpoints - Research

**Researched:** 2026-04-03
**Domain:** Express 4.x role-gated API routes, pg pool transactions, audit log writes
**Confidence:** HIGH

## Summary

This phase adds three new API surfaces: two stance-write routes (`PUT /api/compass/stances/:politicianId/:topicId` single-topic and `PUT /api/compass/stances/:politicianId/bulk`) and one contributor-scoped politician list (`GET /api/compass/contributors/politicians`). All work is on the Express backend only — no UI, no frontend changes.

All required infrastructure is already in place: `requireRole` middleware (Phase 53), `writeRoleAuditLog` helper in `adminService.ts` (Phase 54), `pool` pg client for non-public schema writes, and `getCachedUserRoles` for jurisdiction extraction. The main schema work is adding `home_jurisdiction_geoid` to `inform.politicians` (new column, simple migration) and adding an `id` UUID PK column to `public.user_roles` so that `role_grant_id` can be referenced in audit log entries.

The bulk write transaction pattern is already established in `vqService.ts`: `pool.connect()` → `BEGIN` → writes → `COMMIT`, with `ROLLBACK` in catch and `client.release()` in finally. The stance editor routes follow this pattern for the bulk endpoint; the single-topic endpoint can use a simple `pool.query()`.

**Primary recommendation:** Three plans — Plan 01: migration (add `home_jurisdiction_geoid` to `inform.politicians` + add `id` to `public.user_roles` + update `get_user_roles` RPC to return it), Plan 02: stance write routes + jurisdiction middleware + audit log, Plan 03: contributor politicians list endpoint.

## Standard Stack

No new libraries. All tools are already in the project.

### Core (already in place)
| Tool | Version | Purpose | Notes |
|------|---------|---------|-------|
| `express` | 4.x | HTTP routing | All new routes in Express router |
| `pg` (pool) | existing | Bulk transactions + non-public schema writes | `pool.connect()` pattern from `vqService.ts` |
| `zod` | existing | Request body validation | All route schemas already use zod |
| `requireRole` | Phase 53 | Role-gated middleware | Already in `middleware/requireRole.ts` |
| `getCachedUserRoles` | Phase 52/53 | Fetch user's grants + jurisdiction | Returns `jurisdiction_geoid`, `resource_id` |
| `writeRoleAuditLog` | Phase 54 | Audit log writes | In `adminService.ts`, writes to `role_audit_log` |
| `pool` | Phase 35+ | Direct postgres | `lib/db.ts`, used for all non-public schema writes |

**No new npm installs required.**

## Architecture Patterns

### Recommended File Structure
```
backend/src/
├── routes/
│   ├── compass.ts          # UNTOUCHED — existing public compass routes (GET /politicians unmodified)
│   └── stances.ts          # NEW — PUT /stances/:politicianId/:topicId and /bulk
                             #       GET /contributors/politicians (contributor-scoped)
├── lib/
│   └── stanceService.ts    # NEW — writeSingleStance(), writeBulkStances(), getContributorPoliticians()
backend/migrations/
└── 049_phase55_politician_home_jurisdiction.sql  # ADD home_jurisdiction_geoid + user_roles id
```

Mount in `index.ts`:
```typescript
import stancesRouter from './routes/stances.js';
app.use('/api/compass', stancesRouter);
```

The `/api/compass` prefix is already shared between `compassRouter` and `compassAdminRouter` — a third mount is fine because there are no URL+method collisions (new routes: `PUT /stances/*`, `GET /contributors/politicians`).

### Pattern 1: requireRole middleware + manual jurisdiction enforcement

**What:** `requireRole` only checks that the user HOLDS the role (with optional scope). For Phase 55, the scope check against the politician's `home_jurisdiction_geoid` cannot be done at middleware layer because the politician's jurisdiction must be fetched from the DB. The pattern is:

1. `requireRole('compass_stance_editor')` at middleware layer — confirms role exists, returns 403 if not
2. In the handler body, fetch grants via `getCachedUserRoles(userId)` to get the active grant's `jurisdiction_geoid`
3. Fetch `politician.home_jurisdiction_geoid` from `inform.politicians`
4. Enforce exact string equality between grant `jurisdiction_geoid` and politician `home_jurisdiction_geoid`

```typescript
// Source: backend/src/middleware/requireRole.ts + backend/src/lib/roleService.ts

// Step 1 - middleware
router.put(
  '/stances/:politicianId/:topicId',
  requireAuth,
  requireRole(['compass_stance_editor', 'campaign_manager']),
  async (req, res) => {
    const authReq = req as AuthenticatedRequest;
    const grants = await getCachedUserRoles(authReq.userId);
    // Step 2 - jurisdiction enforcement in handler
    // ...
  }
);
```

**Why not middleware-layer:** The politician's `home_jurisdiction_geoid` is not available in the request params (only the politician UUID is). Fetching it in custom middleware would couple the middleware to the politician table, violating separation of concerns.

### Pattern 2: Jurisdiction enforcement for compass_stance_editor

```typescript
// Source: codebase pattern — pool.query() for inform schema reads

// Fetch politician's home jurisdiction
const { rows } = await pool.query<{ home_jurisdiction_geoid: string | null }>(
  'SELECT home_jurisdiction_geoid FROM inform.politicians WHERE id = $1 AND is_active = true',
  [politicianId]
);
if (rows.length === 0) {
  return res.status(404).json({ code: 'POLITICIAN_NOT_FOUND', message: 'Politician not found' });
}

const politicianGeoId = rows[0].home_jurisdiction_geoid;

// Find the compass_stance_editor grant
const editorGrant = grants.find(g => g.slug === 'compass_stance_editor');
const grantGeoId = editorGrant?.jurisdiction_geoid ?? null;

// NULL jurisdiction: fail-open for Alpha — write proceeds with console.warn
// TODO: fail-closed once Alpha cities are seeded
if (politicianGeoId !== null && grantGeoId !== null && grantGeoId !== politicianGeoId) {
  return res.status(403).json({ code: 'JURISDICTION_MISMATCH',
    message: 'Your jurisdiction does not cover this politician' });
}
if (politicianGeoId === null || grantGeoId === null) {
  console.warn('[stances] NULL jurisdiction — fail-open (Alpha). TODO: fail-closed after city seed');
}
```

### Pattern 3: campaign_manager resource boundary enforcement

```typescript
// campaign_manager: resource_id in grant must match politicianId in URL
const managerGrant = grants.find(g => g.slug === 'campaign_manager');
if (managerGrant && managerGrant.resource_id !== null && managerGrant.resource_id !== politicianId) {
  return res.status(403).json({ code: 'RESOURCE_BOUNDARY',
    message: 'Campaign manager access limited to assigned politician' });
}
```

**Important:** Both roles share the same write route. Check BOTH roles — a user could hold either. The role-check middleware accepts an array: `requireRole(['compass_stance_editor', 'campaign_manager'])`. In the handler, determine which grant applies and enforce the appropriate boundary.

### Pattern 4: Single-topic stance write (pool.query, no explicit transaction needed)

The single-topic write is a single upsert. No transaction needed — single statements in Postgres are implicitly atomic.

```typescript
// Source: codebase pattern from adminService.ts (pool.query for non-public schema writes)

// Read current value for audit log (old_value)
const { rows: existing } = await pool.query<{ value: string; write_in_text: string | null }>(
  'SELECT value, write_in_text FROM inform.politician_answers WHERE politician_id = $1 AND topic_id = $2',
  [politicianId, topicId]
);
const oldValue = existing[0]?.value ?? null;
const oldWriteInText = existing[0]?.write_in_text ?? null;

// Upsert stance
await pool.query(
  `INSERT INTO inform.politician_answers (politician_id, topic_id, value, write_in_text)
   VALUES ($1, $2, $3, $4)
   ON CONFLICT (politician_id, topic_id)
   DO UPDATE SET value = EXCLUDED.value, write_in_text = EXCLUDED.write_in_text`,
  [politicianId, topicId, value, write_in_text ?? null]
);

// Write audit log
// NOTE: politician_answers has (politician_id, topic_id) composite PK — no separate row id
```

**Note on `write_in_text` column:** The current `inform.politician_answers` schema has `politician_id`, `topic_id`, and `value` only (confirmed in migration 026, decimal in 038). The `write_in_text` column does NOT currently exist. It must be added in the Phase 55 migration.

### Pattern 5: Bulk stance write (pg pool transaction)

Established pattern from `vqService.ts` lines 154-233:

```typescript
// Source: backend/src/lib/vqService.ts — adjustVerificationRating()

const client = await pool.connect();
try {
  await client.query('BEGIN');

  for (const stance of stances) {
    // validate topic exists and is live
    const { rows: topic } = await client.query(
      'SELECT id FROM inform.compass_topics WHERE id = $1 AND is_live = true',
      [stance.topic_id]
    );
    if (topic.length === 0) {
      await client.query('ROLLBACK');
      return res.status(422).json({
        code: 'INVALID_TOPIC',
        message: `Topic ${stance.topic_id} not found or not live`
      });
    }

    // upsert
    await client.query(
      `INSERT INTO inform.politician_answers (politician_id, topic_id, value, write_in_text)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value, write_in_text = EXCLUDED.write_in_text`,
      [politicianId, stance.topic_id, stance.value, stance.write_in_text ?? null]
    );
  }

  await client.query('COMMIT');
} catch (err) {
  await client.query('ROLLBACK');
  throw err;
} finally {
  client.release();
}
```

**Two-pass validation requirement (per CONTEXT.md):** Validate ALL topics before any writes. Use two explicit loops:
1. Fetch all topic rows and validate existence + liveness
2. Only if all valid, execute all upserts within the transaction

This avoids partial writes followed by rollback, and returns a clean validation error before touching the DB.

### Pattern 6: Audit log write for stance_write action

The existing `writeRoleAuditLog` signature (from `adminService.ts`) takes `action: 'granted' | 'revoked'`. Phase 55 adds `'stance_write'` — the function signature must be extended to accept this new action type. The `fields_changed` column in `role_audit_log` is `text[]` in the schema (migration 047), but CONTEXT.md specifies storing `{ topic_id, old_value, new_value, write_in_text_changed: boolean }` — this is an object, not a string array. Use the `snapshot_after` JSONB column for this structured data instead, or cast to JSON string and store in `fields_changed` as a single element. Recommendation: use `snapshot_after` (JSONB) for structured audit data.

**For bulk writes:** One audit log row per topic changed (per CONTEXT.md), not one row for the entire batch. Loop through stances and write one `role_audit_log` row per stance after commit.

**`role_grant_id` requirement:** CONTEXT.md requires including `role_grant_id` in the audit log to link the write to the specific grant. The `role_audit_log` table has no `role_grant_id` column currently, and `user_roles` has no standalone `id` column (only composite key). This requires:
- Add `id UUID DEFAULT gen_random_uuid()` to `public.user_roles` in the Phase 55 migration
- Update `get_user_roles` RPC to return `ur.id AS grant_id`
- Update `UserRoleGrant` TypeScript interface to include `grant_id: string`
- Add `role_grant_id uuid` column to `public.role_audit_log`
- Pass `grant_id` from the active grant into the audit log write

### Pattern 7: Contributor politicians list

```typescript
// GET /api/compass/contributors/politicians
// Source: existing getCachedUserRoles pattern

router.get('/contributors/politicians', requireAuth, requireRole(['compass_stance_editor', 'campaign_manager']),
  async (req, res) => {
    const authReq = req as AuthenticatedRequest;
    const grants = await getCachedUserRoles(authReq.userId);

    // campaign_manager: return exactly the assigned politician
    const managerGrant = grants.find(g => g.slug === 'campaign_manager');
    if (managerGrant?.resource_id) {
      const { rows } = await pool.query(
        'SELECT id, first_name, last_name, preferred_name, full_name, is_active ' +
        'FROM inform.politicians WHERE id = $1 AND is_active = true',
        [managerGrant.resource_id]
      );
      return res.json(rows); // [] if politician deactivated or resource_id wrong
    }

    // compass_stance_editor: return all politicians matching jurisdiction
    const editorGrant = grants.find(g => g.slug === 'compass_stance_editor');
    if (!editorGrant) return res.json([]);

    if (editorGrant.jurisdiction_geoid === null) {
      // NULL jurisdiction: return all active politicians (fail-open for Alpha)
      console.warn('[contributors/politicians] NULL jurisdiction — returning all politicians (Alpha)');
      const { rows } = await pool.query('SELECT id, first_name, last_name, preferred_name, full_name FROM inform.politicians WHERE is_active = true');
      return res.json(rows);
    }

    const { rows } = await pool.query(
      'SELECT id, first_name, last_name, preferred_name, full_name FROM inform.politicians WHERE home_jurisdiction_geoid = $1 AND is_active = true',
      [editorGrant.jurisdiction_geoid]
    );
    return res.json(rows);
  }
);
```

### Pattern 8: writeRoleAuditLog extension for stance_write

Current signature:
```typescript
// Source: backend/src/lib/adminService.ts line 304
export async function writeRoleAuditLog(
  actorId: string,
  targetUserId: string,
  action: 'granted' | 'revoked',
  roleSlug: string,
  featureScope: string,
  jurisdictionGeoid: string | null,
  resourceId: string | null
): Promise<void>
```

Phase 55 needs to extend this (or create a new `writeStanceAuditLog` function) to support:
- `action: 'stance_write'`
- `role_grant_id: string | null` — the `id` from the `user_roles` row that authorized the write
- `snapshot_after: { topic_id, old_value, new_value, write_in_text_changed }` — structured change data

Recommendation: create a separate `writeStanceAuditLog` function in `adminService.ts` (or `stanceService.ts`) rather than extending the existing function with too many optional params.

### Anti-Patterns to Avoid

- **Nesting requireRole logic inside compassRouter or compassAdminRouter:** New routes live in a new `stances.ts` router to avoid bloating existing files. The compassAdminRouter is already gated by `requireAdmin` — stance editor routes are NOT admin-only, so they must NOT be added to compassAdminRouter.
- **Using supabaseAnon or supabaseAdmin for inform schema writes:** All `inform.politician_answers` writes must use `pool.query()` — PostgREST writes to non-public schemas fail at runtime (established pattern, MEMORY.md).
- **Using adminRpc for stance writes:** Stance writes do not need a SECURITY DEFINER RPC — the handler runs server-side with service-role-equivalent access via pool. No RPC needed; use direct `pool.query()`.
- **One audit log row for the whole bulk batch:** CONTEXT.md explicitly requires one row per topic changed.
- **Route URL collision with existing GET /compass/politicians:** The new endpoint is `GET /compass/contributors/politicians` — NOT `GET /compass/politicians`. The existing public endpoint is untouched.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Role presence check | Custom JWT inspection | `requireRole(['compass_stance_editor', 'campaign_manager'])` | Already handles caching, 401/403 |
| Grant jurisdiction lookup | Re-query the DB | `getCachedUserRoles(userId)` returns `jurisdiction_geoid` | Already cached in Redis with 90s TTL |
| Bulk transaction | Sequential awaits | `pool.connect()` + `BEGIN/COMMIT/ROLLBACK` | Exact pattern in vqService.ts |
| Audit log write | Custom INSERT | `writeRoleAuditLog` (extended) or new `writeStanceAuditLog` | Existing helper, consistent audit shape |
| Topic existence check | Trust caller | Explicit `SELECT FROM inform.compass_topics WHERE id = $1 AND is_live = true` | Prevents stances on non-live topics |

## Common Pitfalls

### Pitfall 1: inform.politician_answers write via supabaseAdmin/supabaseAnon

**What goes wrong:** `supabaseAdmin.schema('inform').from('politician_answers').upsert(...)` fails silently or errors at runtime.

**Why it happens:** `inform` schema is not in the PostgREST exposed schema list. Confirmed pattern: all non-public schema writes must use `pool.query()`.

**How to avoid:** Use `pool.query()` for all `inform.politician_answers` reads and writes.

**Warning signs:** 500 error or silent no-op when calling PostgREST on non-public schema.

### Pitfall 2: Missing write_in_text column on inform.politician_answers

**What goes wrong:** `INSERT INTO inform.politician_answers ... write_in_text` fails with "column does not exist".

**Why it happens:** The current `inform.politician_answers` schema (migrations 026 + 038) has only `politician_id`, `topic_id`, `value`. The `write_in_text` column does not exist yet.

**How to avoid:** The Phase 55 migration must add `write_in_text TEXT` to `inform.politician_answers` before the routes are deployed.

**Warning signs:** Runtime DB error when trying to insert with `write_in_text` value.

### Pitfall 3: role_grant_id not in user_roles

**What goes wrong:** Cannot include `role_grant_id` in audit log entries because `public.user_roles` has no `id` column — only a composite key `(user_id, role_id, feature_scope, jurisdiction_geoid, resource_id)`.

**Why it happens:** The table was designed with a composite uniqueness constraint, not a surrogate key. The `get_user_roles` RPC only returns `role_id`, `slug`, `name`, `granted_at`, `feature_scope`, `jurisdiction_geoid`, `resource_id`.

**How to avoid:** The Phase 55 migration must:
1. `ALTER TABLE public.user_roles ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid()`
2. Backfill existing rows: `UPDATE public.user_roles SET id = gen_random_uuid() WHERE id IS NULL`
3. `ALTER TABLE public.user_roles ALTER COLUMN id SET NOT NULL`
4. `ALTER TABLE public.role_audit_log ADD COLUMN IF NOT EXISTS role_grant_id UUID`
5. Update `get_user_roles` RPC to return `ur.id AS grant_id`
6. Update `UserRoleGrant` TypeScript interface to include `grant_id: string`

**Warning signs:** TypeScript type error when trying to access `grant.grant_id` — field doesn't exist on `UserRoleGrant`.

### Pitfall 4: Middleware requireRole check passes but handler-level boundary fails silently

**What goes wrong:** The `requireRole(['compass_stance_editor', 'campaign_manager'])` middleware passes if the user holds EITHER role. A campaign_manager can then proceed to the stance editor handler path unless the handler explicitly re-derives which role is applicable.

**Why it happens:** `requireRole` with an array does OR logic — either role passes the middleware. The per-role boundary (jurisdiction for editor, resource_id for manager) is handler responsibility.

**How to avoid:** In the handler, always derive the active role:
```typescript
const isCampaignManager = grants.some(g => g.slug === 'campaign_manager');
const isStanceEditor = grants.some(g => g.slug === 'compass_stance_editor');
```
Apply the appropriate boundary check based on which role is present. If both roles are present (should not happen in practice — CIVIC-04 conflict rules), apply the more restrictive check.

**Warning signs:** A campaign_manager can write stances for politicians not in their `resource_id` assignment.

### Pitfall 5: GET /compass/contributors/politicians conflicts with GET /compass/politicians

**What goes wrong:** Adding `GET /compass/contributors/politicians` to a router mounted at `/api/compass` could conflict with the existing `GET /compass/politicians` route in compassRouter if path specificity is wrong.

**Why it happens:** Express route matching is order-dependent. If `stancesRouter` is mounted before `compassRouter`, the `/contributors/politicians` path would never conflict. But mounting order and path specificity matter.

**How to avoid:** Mount `stancesRouter` AFTER `compassRouter` in `index.ts` (same pattern as `compassAdminRouter`). The `contributors/politicians` path will never shadow `/politicians` because it's a distinct string. Test explicitly.

**Warning signs:** `GET /compass/politicians` returns 404 or 403 after mounting the new router.

### Pitfall 6: Two-pass validation omitted on bulk write

**What goes wrong:** Partial writes — some topics write before an invalid topic causes rollback. Client receives 422 but some data was temporarily written (then rolled back). If audit log writes happen inside the transaction (before COMMIT), they also roll back correctly, but if they happen outside, orphan audit rows appear.

**Why it happens:** Single-pass validation writes as it validates — a failure mid-loop triggers ROLLBACK but only after partial writes.

**How to avoid:** Two-pass pattern: collect all `topic_id` values, validate ALL in a single `IN ($1, $2, ...)` query, return 422 if any are invalid. Only then enter the write loop.

### Pitfall 7: NULL jurisdiction fail-open not logged

**What goes wrong:** NULL jurisdiction silently allows writes to any politician, with no trace of the fallback.

**Why it happens:** The fail-open is intentional for Alpha but must be auditable.

**How to avoid:** `console.warn` with request context (userId, politicianId) every time the NULL fallback path is taken. Add a `// TODO: fail-closed` comment at that branch.

## Code Examples

### Migration: add home_jurisdiction_geoid + user_roles id + role_audit_log role_grant_id + write_in_text

```sql
-- Source: based on migration 047 patterns
BEGIN;

-- Add home_jurisdiction_geoid to inform.politicians
ALTER TABLE inform.politicians
  ADD COLUMN IF NOT EXISTS home_jurisdiction_geoid TEXT;

-- Add write_in_text to inform.politician_answers
ALTER TABLE inform.politician_answers
  ADD COLUMN IF NOT EXISTS write_in_text TEXT;

-- Add surrogate id to public.user_roles (for role_grant_id traceability)
ALTER TABLE public.user_roles
  ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid();
UPDATE public.user_roles SET id = gen_random_uuid() WHERE id IS NULL;
ALTER TABLE public.user_roles ALTER COLUMN id SET NOT NULL;

-- Add role_grant_id to role_audit_log
ALTER TABLE public.role_audit_log
  ADD COLUMN IF NOT EXISTS role_grant_id UUID;

-- Update get_user_roles RPC to return grant id
-- (DROP required because return type changes)
DROP FUNCTION IF EXISTS public.get_user_roles(uuid);
CREATE OR REPLACE FUNCTION public.get_user_roles(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE v_result jsonb;
BEGIN
  SELECT jsonb_agg(row_to_json(t))
  INTO v_result
  FROM (
    SELECT ur.id AS grant_id, ur.role_id, r.slug, r.name, ur.granted_at,
           ur.feature_scope, ur.jurisdiction_geoid, ur.resource_id
    FROM public.user_roles ur
    JOIN public.roles r ON r.id = ur.role_id
    WHERE ur.user_id = p_user_id AND ur.revoked_at IS NULL
    ORDER BY ur.granted_at DESC
  ) t;
  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

COMMIT;
```

### UserRoleGrant interface update

```typescript
// Source: backend/src/lib/roleService.ts — extend with grant_id
export interface UserRoleGrant {
  grant_id: string;         // NEW — id from public.user_roles row
  role_id: string;
  slug: string;
  name: string;
  granted_at: string;
  feature_scope: string;
  jurisdiction_geoid: string | null;
  resource_id: string | null;
}
```

### Bulk write transaction with two-pass validation

```typescript
// Source: pattern from backend/src/lib/vqService.ts adjustVerificationRating()
export async function writeBulkStances(
  politicianId: string,
  stances: Array<{ topic_id: string; value: number; write_in_text?: string }>
): Promise<Array<{ topic_id: string; old_value: number | null; new_value: number }>> {
  // Pass 1: validate ALL topics before any writes
  const topicIds = stances.map(s => s.topic_id);
  const placeholders = topicIds.map((_, i) => `$${i + 1}`).join(', ');
  const { rows: validTopics } = await pool.query(
    `SELECT id FROM inform.compass_topics WHERE id IN (${placeholders}) AND is_live = true`,
    topicIds
  );
  const validSet = new Set(validTopics.map(r => r.id));
  const invalid = topicIds.filter(id => !validSet.has(id));
  if (invalid.length > 0) {
    throw Object.assign(new Error('Invalid topic IDs'), { code: 'INVALID_TOPICS', invalid });
  }

  // Pass 2: fetch old values for audit log
  const { rows: oldRows } = await pool.query(
    `SELECT topic_id, value, write_in_text FROM inform.politician_answers
     WHERE politician_id = $1 AND topic_id = ANY($2::uuid[])`,
    [politicianId, topicIds]
  );
  const oldMap = new Map(oldRows.map(r => [r.topic_id, { value: r.value, write_in_text: r.write_in_text }]));

  // Pass 3: write in transaction
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    for (const stance of stances) {
      await client.query(
        `INSERT INTO inform.politician_answers (politician_id, topic_id, value, write_in_text)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (politician_id, topic_id)
         DO UPDATE SET value = EXCLUDED.value, write_in_text = EXCLUDED.write_in_text`,
        [politicianId, stance.topic_id, stance.value, stance.write_in_text ?? null]
      );
    }
    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }

  // Return change info for per-topic audit log rows (written after commit)
  return stances.map(s => ({
    topic_id: s.topic_id,
    old_value: oldMap.get(s.topic_id)?.value ?? null,
    new_value: s.value,
    write_in_text_changed: (oldMap.get(s.topic_id)?.write_in_text ?? null) !== (s.write_in_text ?? null),
  }));
}
```

### Stance audit log write (per-topic)

```typescript
// New function in stanceService.ts or adminService.ts
export async function writeStanceAuditLog(
  actorId: string,
  targetUserId: string,
  grantId: string,
  politicianId: string,
  topicId: string,
  oldValue: number | null,
  newValue: number,
  writeInTextChanged: boolean,
  featureScope: string,
  jurisdictionGeoid: string | null,
  resourceId: string | null
): Promise<void> {
  await pool.query(
    `INSERT INTO public.role_audit_log
       (actor_id, target_user_id, action, role_grant_id, feature_scope,
        jurisdiction_geoid, resource_id, target_type, target_id, snapshot_after)
     VALUES ($1, $2, 'stance_write', $3, $4, $5, $6, 'politician_answer', $7, $8)`,
    [
      actorId,
      targetUserId,
      grantId,
      featureScope,
      jurisdictionGeoid,
      resourceId,
      topicId,
      JSON.stringify({ topic_id: topicId, politician_id: politicianId, old_value: oldValue, new_value: newValue, write_in_text_changed: writeInTextChanged }),
    ]
  );
}
```

### Route registration in index.ts

```typescript
// Source: backend/src/index.ts — follow dual-router pattern for /api/compass
import stancesRouter from './routes/stances.js';
// ... after compassAdminRouter mount:
app.use('/api/compass', stancesRouter);
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| No role-gated writes | `requireRole` middleware available | Phase 53 | Can now gate routes cleanly |
| `admin_update_politician_answers` RPC (admin-only) | New contributor-scoped routes | Phase 55 | Non-admin contributors can write stances |
| `role_audit_log` only tracks grant/revoke | Extended with `stance_write` action | Phase 55 | Full audit trail for contributor writes |
| No `home_jurisdiction_geoid` on politicians | New column added | Phase 55 | Enables contributor jurisdiction enforcement |

**Deprecated/outdated:**
- Do NOT use `admin_update_politician_answers` RPC for Phase 55 writes — it's an admin operation that does full replacement. Phase 55 does targeted upserts.

## Open Questions

1. **Does `inform.politician_answers` need a `write_in_text` column added to the DB?**
   - What we know: Current schema (migration 026 + 038) has `politician_id, topic_id, value` only. No `write_in_text` column.
   - What's unclear: Is `write_in_text` for politicians already stored elsewhere? Checked code — only `write_in_text` on `compass_responses` (user answers), not `politician_answers`.
   - Recommendation: Add `write_in_text TEXT` to `inform.politician_answers` in the Phase 55 migration. This is required for the route contract to work.

2. **Does user_roles have an id column already in production?**
   - What we know: No `id` column appears in any migration or `get_user_roles` RPC return shape. The table uses composite uniqueness constraint.
   - What's unclear: The Supabase project may have schema state not captured in migrations (schema was created before migration 025).
   - Recommendation: Run `SELECT column_name FROM information_schema.columns WHERE table_name = 'user_roles' AND table_schema = 'public'` against prod before writing the migration. If the column already exists, the `ADD COLUMN IF NOT EXISTS` is a no-op.

3. **Which role wins if a user holds both `compass_stance_editor` AND `campaign_manager`?**
   - What we know: CIVIC-04 conflict groups are empty for Alpha, so both roles can theoretically coexist.
   - What's unclear: No conflict group defined between these two roles yet.
   - Recommendation: In the handler, prefer `campaign_manager` boundary if both grants exist (more restrictive). Add a `console.warn` log when both are present.

4. **What value range should be accepted for stance writes?**
   - What we know: `inform.politician_answers.value` is `NUMERIC(3,1)` with constraint `>= 0.5 AND <= 5.5 AND (value * 2) = ROUND(value * 2)` (migration 038). This is half-step values: 0.5, 1.0, 1.5 ... 5.5.
   - Recommendation: Zod schema: `z.number().multipleOf(0.5).min(0.5).max(5.5)` — same as compass_responses user answer validation.

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection:
  - `backend/src/middleware/requireRole.ts` — full implementation confirmed
  - `backend/src/lib/roleService.ts` — `UserRoleGrant` interface, `getCachedUserRoles`, `checkRole` confirmed
  - `backend/src/lib/adminService.ts` lines 299-327 — `writeRoleAuditLog` signature confirmed
  - `backend/src/lib/vqService.ts` lines 154-233 — pg pool transaction pattern confirmed
  - `backend/src/lib/compassService.ts` — `getCompassPoliticians` (pool.query for inform schema), `getPoliticianAnswers` (supabaseAnon)
  - `backend/src/routes/compass.ts` — `GET /politicians` confirmed, untouched by Phase 55
  - `backend/src/routes/admin.ts` — `writeRoleAuditLog` calls with `'granted'`/`'revoked'` action values
  - `backend/src/routes/contributor.ts` — `getCachedUserRoles` usage pattern
  - `backend/src/index.ts` — router mounting order confirmed
  - `backend/migrations/047_role_scope_migration.sql` — `role_audit_log` schema, `user_roles` columns, `get_user_roles` RPC return shape
  - `backend/migrations/038_compass_additions.sql` — `politician_answers.value` as NUMERIC(3,1) with half-step constraint
  - `backend/migrations/026_inform_schema_repair_and_candidates.sql` — `inform.politicians` base schema (no `home_jurisdiction_geoid` or `write_in_text`)
  - `backend/migrations/033_politician_schema.sql` — 9 additional columns on `inform.politicians` (no `home_jurisdiction_geoid`)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries confirmed via direct code inspection, no new installs
- Architecture: HIGH — all patterns verified against actual codebase; transaction pattern from vqService.ts
- Pitfalls: HIGH — all identified from actual schema gaps and existing code patterns
- Migration requirements: HIGH — confirmed absence of `home_jurisdiction_geoid`, `write_in_text`, `user_roles.id`, and `role_grant_id` column

**Research date:** 2026-04-03
**Valid until:** 2026-05-03 (stable codebase, no fast-moving dependencies)
