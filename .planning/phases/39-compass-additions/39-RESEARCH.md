# Phase 39: Compass Additions - Research

**Researched:** 2026-03-20
**Domain:** Express/TypeScript backend — PostgreSQL schema migrations, compass API endpoints
**Confidence:** HIGH

## Summary

Phase 39 completes the compass backend contract by adding endpoints that currently only exist on the Go server. Research was conducted by reading existing codebase code directly — the stack and patterns are already established in this repo, so there are no new library choices to make.

The most important finding: **three of the six "admin" endpoints already exist** in `backend/src/routes/admin.ts` at `/api/admin/compass/*` paths. Phase 39 requires adding them at `/api/compass/*` paths (the CompassV2/Go-compatible URL style) — either by adding new routes to `compass.ts` or creating a compass-admin router mounted at `/api/compass`. The URL difference is the critical distinction.

A second key finding: **the value column migration for `inform.compass_responses` was already applied** in `backend/migrations/030_decimal_compass_values.sql` (part of the batch applied in `applyMigrations.ts`). The `inform.politician_answers.value` column was NOT included in migration 030 and still uses `INT`. Phase 39 must migrate `politician_answers.value` to `NUMERIC(3,1)` and update the `admin_update_politician_answers` RPC.

The verdicts table (`inform.compass_verdicts`) does not exist anywhere in the codebase. It is a net-new table requiring a new migration, new RPC for batch upsert, and new routes.

**Primary recommendation:** Add all new routes to `compass.ts` (the existing `/api/compass` router) — both public-facing new routes and admin-gated compass routes — to keep the URL contract CompassV2 expects. Admin gating uses inline `requireAdmin` middleware, matching the pattern used in `DELETE /answers/me?full=true` in the current compass.ts.

## Standard Stack

No new libraries required. Phase 39 uses only existing stack:

### Core (already installed)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Express 4.x | existing | Route handlers | Project standard |
| zod | existing | Request validation | Project standard |
| `pg` Pool | existing | All non-public schema writes | Required — PostgREST cannot write non-public schemas |
| `supabaseAnon` | existing | Public-read queries from `inform.*` | RLS enforced, PostgREST exposed |
| `adminRpc` | existing | SECURITY DEFINER RPC calls | Used for atomic multi-table writes |
| `requireAuth` | existing | Auth middleware | Standard for auth-required routes |
| `requireAdmin` | existing | Admin middleware | Inline use for admin-gated routes within compass.ts |

### No New Dependencies
All functionality can be implemented with the existing stack. No npm installs needed.

## Architecture Patterns

### What Already Exists vs. What Needs Building

**Already exists, no changes needed:**
- `GET /api/compass/politicians` — getCompassPoliticians (compassService.ts)
- `GET /api/compass/politicians/:id/answers` — getPoliticianAnswers (compassService.ts)
- `GET /api/compass/politicians/:id/:topicId/context` — getPoliticianContext (compassService.ts)
- `POST /api/admin/compass/topics` — adminCreateTopicWithStances (admin.ts + adminService.ts)
- `PATCH /api/admin/compass/topics/:id` — adminUpdateTopic (admin.ts + adminService.ts)
- `PATCH /api/admin/compass/stances/:id` — adminUpdateStance (admin.ts + adminService.ts)
- `PUT /api/admin/compass/topics/:id/categories` — adminAssignTopicCategories (admin.ts)
- `PUT /api/admin/compass/politicians/:id/answers` — adminUpdatePoliticianAnswers (admin.ts)
- `POST /api/admin/compass/politicians/:id/context` — adminSetPoliticianContext (admin.ts)
- `compass_responses.value` migration to NUMERIC(3,1) — done in migration 030
- `compass_change_history` column migrations — done in migration 030
- `upsert_compass_answer` RPC updated for NUMERIC — done in migration 030
- Zod validation for `value: z.number().multipleOf(0.5).min(0.5).max(5.5)` — already in compass.ts

**Needs building — new routes in compass.ts:**
1. `POST /api/compass/compare` — new, no existing implementation
2. `GET /api/compass/verdicts` — new, table doesn't exist yet
3. `POST /api/compass/verdicts` — new, table doesn't exist yet
4. `POST /api/compass/topics/create` — already in admin, needs to mirror at this URL with admin gate
5. `PATCH /api/compass/topics/update` — already in admin, needs to mirror at this URL with admin gate
6. `DELETE /api/compass/topics/delete/:id` — new behavior (blocked if responses exist)
7. `PATCH /api/compass/topics/categories/update` — already in admin, needs to mirror at this URL with admin gate
8. `PATCH /api/compass/stances/update` — already in admin, needs to mirror at this URL with admin gate
9. `POST /api/compass/politicians/context` — already in admin, needs to mirror at this URL with admin gate
10. `PUT /api/compass/politicians/:id/answers` — already in admin, but needs full-replacement behavior
11. `POST /api/compass/politicians/:id/answers/batch` — new (non-admin batch fetch by topic_ids)

**Needs building — new migration:**
1. `inform.politician_answers.value` column type: INT → NUMERIC(3,1)
2. `admin_update_politician_answers` RPC: update `::int` cast to `::numeric`, add full-replacement behavior
3. `inform.compass_verdicts` table (new) + RLS policy
4. `compass_responses_value_half_step` constraint enhancement (CONTEXT wants `value * 2 = ROUND(value * 2)` — migration 030 only added range check, not half-step enforcement)

### Route Handler Pattern in compass.ts

The existing compass.ts uses `requireAdmin` conditionally (see `DELETE /answers/me?full=true`). For admin-only compass routes, use the pattern of calling `requireAdmin` inline, not as router middleware. This avoids splitting routes between admin.ts and compass.ts while keeping the correct URL structure.

```typescript
// Source: /c/EV-Accounts/backend/src/routes/compass.ts lines 110-138
// Pattern: inline requireAdmin check for admin-gated route within compass.ts
router.delete('/answers/me', requireAuth, async (req, res) => {
  const authReq = req as AuthenticatedRequest;
  const fullReset = req.query.full === 'true';
  if (fullReset) {
    await new Promise<void>((resolve, reject) => {
      requireAdmin(req, res, (err?: unknown) => {
        if (err) reject(err); else resolve();
      });
    }).catch(() => {});
    if (res.headersSent) return;
  }
  // ... continue
});
```

Alternatively: mount a dedicated `compassAdmin` router at `/api/compass` that has `router.use(requireAuth, requireAdmin)` and put all admin-gated compass routes there. This is cleaner because the existing compass.ts already has many routes and admin routes with guards will clutter it further.

**Recommendation (Claude's discretion):** Create a new file `backend/src/routes/compassAdmin.ts` with `router.use(requireAuth, requireAdmin)` at the top, and mount it at `/api/compass` in index.ts alongside the existing compassRouter. Express will try both routers for `/api/compass/*` paths.

### Pool Query Pattern

All writes to non-public schemas use `pool.query()`:

```typescript
// Source: /c/EV-Accounts/backend/src/lib/compassService.ts lines 280-288
// Pattern: pool.query for non-public schema writes
const { rows } = await pool.query<{ id: string }>(
  `UPDATE connect.connected_profiles
   SET selected_topic_ids = $2::jsonb, updated_at = now()
   WHERE user_id = $1
   RETURNING id`,
  [userId, JSON.stringify(topicIds)]
);
```

For verdicts UPSERT (new table in `inform` schema), use `pool.query()` — NOT supabaseAdmin PostgREST.

For compare endpoint (read-only joins across `inform.compass_responses` and `inform.politician_answers`), use `pool.query()` since these are non-public schemas. Do NOT use `supabaseAnon.schema('inform')` for the user's responses (that would leak other users' data if RLS is misconfigured). Using `pool.query()` with `WHERE user_id = $1` is the correct pattern.

### SECURITY DEFINER Pattern for Batch Verdicts

The batch verdicts POST must be atomic (all verdicts in one session committed or none). Use a SECURITY DEFINER RPC via `adminRpc()`:

```sql
-- Pattern from upsert_compass_answer in migration 030
CREATE OR REPLACE FUNCTION public.upsert_compass_verdicts(
  p_user_id UUID,
  p_verdicts JSONB  -- [{quote_id, supported, rank, session_size}]
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- INSERT ... ON CONFLICT (user_id, quote_id) DO UPDATE
  -- Loop over p_verdicts array
END;
$$;
```

### Compare Endpoint — Proximity Scoring

The comparison calculation runs entirely in application code (TypeScript), not SQL. Fetch user answers and politician answers in parallel, then compute in-memory:

```typescript
// Proximity formula from CONTEXT.md:
// score_per_topic = 1 - (|user_value - politician_value| / 5)
// alignment_score = average(score_per_topic) * 100
// Topic scope: only topics where BOTH user AND politician have an answer
```

For multiple politician IDs, fetch all politician answers in parallel (Promise.all), not sequentially. User answers fetched once and reused across all politicians.

### Full-Replacement Politician Answers Pattern

The existing `admin_update_politician_answers` RPC only upserts (no deletes). Phase 39 needs DELETE WHERE politician_id = X AND topic_id NOT IN (new_topic_ids), then upsert. The cleanest approach is a new migration that replaces the RPC body with DELETE + INSERT IN TRANSACTION:

```sql
-- New version of admin_update_politician_answers for full replacement
CREATE OR REPLACE FUNCTION public.admin_update_politician_answers(
  p_politician_id uuid,
  p_answers jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_answer jsonb;
  v_topic_ids uuid[];
BEGIN
  -- Collect all submitted topic IDs
  SELECT array_agg((elem->>'topic_id')::uuid)
  INTO v_topic_ids
  FROM jsonb_array_elements(p_answers) AS elem;

  -- Delete answers not in the new payload (full replacement)
  DELETE FROM inform.politician_answers
  WHERE politician_id = p_politician_id
    AND (v_topic_ids IS NULL OR topic_id != ALL(v_topic_ids));

  -- Upsert submitted answers
  FOR v_answer IN SELECT * FROM jsonb_array_elements(p_answers)
  LOOP
    INSERT INTO inform.politician_answers (politician_id, topic_id, value)
    VALUES (
      p_politician_id,
      (v_answer->>'topic_id')::uuid,
      (v_answer->>'value')::numeric
    )
    ON CONFLICT (politician_id, topic_id) DO UPDATE
      SET value = EXCLUDED.value;
  END LOOP;
END;
$$;
```

### Migration Numbering Convention

Backend migrations in `backend/migrations/` use sequential numbering: `025_`, `026_`, etc. Phase 39 migration should be `038_compass_additions.sql`. The apply script at `backend/scripts/applyMigrations.ts` must be updated to include this new migration.

The existing `supabase/migrations/` uses timestamp-based numbering for Supabase CLI. Phase 39 database changes (new table, column type change) should ALSO be added as a supabase migration for the Supabase CLI shadow database, using a timestamp like `20260320000051_phase39_compass_additions.sql`.

**Important:** Both migration systems need to be kept in sync. The backend migration runs on prod via the apply script; the supabase migration is for the Supabase CLI (`supabase db diff`, `supabase db reset`).

### Recommended Project Structure Changes

```
backend/
├── src/routes/
│   ├── compass.ts           # Existing — add compare, verdicts, batch answers
│   └── compassAdmin.ts      # NEW — admin-gated compass routes at /api/compass/*
├── src/lib/
│   └── compassService.ts    # Existing — add compareWithPoliticians, verdicts funcs
└── migrations/
    └── 038_compass_additions.sql  # NEW — politician_answers migration + verdicts table

supabase/migrations/
└── 20260320000051_phase39_compass_additions.sql  # NEW — same DDL for Supabase CLI
```

### Anti-Patterns to Avoid

- **Using supabaseAnon for user-scoped reads in compare:** Must use `pool.query()` with explicit `WHERE user_id = $1` — supabaseAnon has no auth context.
- **Using supabaseAdmin PostgREST for inform schema writes:** Will fail. Use `pool.query()` for all verdicts writes.
- **UPSERT-only for PUT politician answers:** CONTEXT requires full replacement (delete + insert). The existing RPC only upserts — must be replaced.
- **Nesting SECURITY DEFINER calls:** Do NOT call `upsert_compass_answer` inside `upsert_compass_verdicts`. Each RPC does its own inline work.
- **Separate awaits for batch verdicts:** Must be a single atomic transaction — use a SECURITY DEFINER RPC, not a loop of `await pool.query()` calls.
- **Treating `compass_stances.value` as needing migration:** CONTEXT explicitly says stances stay as INT 1-5. Do not touch the stances table.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Atomic batch verdicts upsert | Loop of individual awaits | SECURITY DEFINER RPC | Partial failure leaves DB inconsistent |
| Full-replacement politician answers | Application-level delete-then-loop | Postgres transaction in SECURITY DEFINER RPC | Atomicity guarantee |
| Half-step validation | Custom JS check | Zod `z.number().multipleOf(0.5).min(0.5).max(5.5)` | Already in codebase, works correctly |
| Topic delete guard (responses exist check) | Application code pre-check | Inline `pool.query COUNT` check before DELETE, return 422 | Simple, already the project pattern |
| Admin auth for compass admin routes | Per-route auth logic | `requireAdmin` middleware (already imported in compass.ts) | Consistent with project patterns |

**Key insight:** All the hard problems in this phase (atomicity, validation, admin gating) already have established solutions in the codebase. No new patterns needed.

## Common Pitfalls

### Pitfall 1: URL Collision Between Admin Routes

**What goes wrong:** `/api/compass/topics` (existing public GET) and `/api/compass/topics/create` (new admin POST) — Express route matching. If the admin router registers `router.post('/topics/create', ...)` and the public router has `router.get('/topics', ...)`, no collision. But `/api/compass/politicians/:id/answers` (existing GET) collides with `/api/compass/politicians/:id/answers` (new PUT for full replacement), and `/api/compass/politicians/:id/answers/batch` (new POST) must be registered BEFORE `/api/compass/politicians/:id/answers` to avoid path capture.

**How to avoid:** In `compassAdmin.ts`, register more specific paths before less specific ones. `politicians/:id/answers/batch` before `politicians/:id/answers`. Use separate HTTP verbs where possible (existing GET stays, new PUT is the full-replace).

**Warning signs:** Routes that silently return 404 or fall through to wrong handler.

### Pitfall 2: politician_answers.value Column Still INT

**What goes wrong:** The Zod schema accepts NUMERIC for `PUT /api/compass/politicians/:id/answers`, but the existing `admin_update_politician_answers` RPC casts `::int`. If a half-step value (e.g., 2.5) is submitted, the RPC silently truncates it to 2. Or the Postgres INT column rejects the NUMERIC cast with a constraint violation.

**How to avoid:** The migration for phase 39 MUST alter `inform.politician_answers.value` from INT to NUMERIC(3,1) and update the RPC's cast from `::int` to `::numeric`. Add both in `038_compass_additions.sql`.

**Warning signs:** PUT /politicians/:id/answers with value=2.5 returns 200 but stores value=2.

### Pitfall 3: Verdicts Table FK to essentials.quotes

**What goes wrong:** `inform.compass_verdicts.quote_id` FK references `essentials.quotes(id)`. The `essentials` schema is not in the PostgREST exposed schema list. The FK constraint itself works at the Postgres level — it's only *PostgREST access* that fails. The FK is safe to create. But any application-level query to `essentials.quotes` must use `pool.query()`.

**How to avoid:** Use `pool.query()` for any query involving `essentials.quotes`. The RLS migration (phase 34) already has `quotes: public read` policy but that only affects PostgREST SELECT, which won't be used here.

**Warning signs:** Error message containing "schema not exposed" when trying to use supabase client for essentials schema.

### Pitfall 4: Compare Endpoint — Topic Scope

**What goes wrong:** Including topics where only the user has answered but the politician has not (or vice versa) skews alignment scores toward 0 because the missing value defaults to null/0 in application code.

**How to avoid:** Filter to ONLY topics present in BOTH `compass_responses` for the user AND `politician_answers` for the politician. Use a JS Map/Set intersection — fetch both arrays, then filter to matching topic_ids.

**Warning signs:** Politicians with few answers showing very low alignment scores even when their actual answers match the user's.

### Pitfall 5: Half-Step Constraint Discrepancy

**What goes wrong:** CONTEXT.md specifies `value * 2 = ROUND(value * 2) AND value >= 0.5 AND value <= 5.5` to enforce only 0.5 increments. Migration 030 only applied `value >= 0.5 AND value <= 5.5` (range check only, not step check). This means values like 1.3 would be accepted by the DB constraint but rejected by Zod's `multipleOf(0.5)`. The Zod validation in the route layer already enforces this correctly (multipleOf(0.5)), but the DB doesn't enforce it independently.

**How to avoid:** For `politician_answers.value`, when adding the new CHECK constraint, use the full half-step check: `value >= 0.5 AND value <= 5.5 AND value * 2 = ROUND(value * 2)`. For `compass_responses`, you can optionally replace the existing constraint with the stricter version in phase 39, but it's not strictly necessary since Zod already validates.

**Warning signs:** Direct DB inserts bypassing the API accepting invalid values like 1.3.

### Pitfall 6: Apply Script Not Updated

**What goes wrong:** New migration file `038_compass_additions.sql` added to `backend/migrations/` but not added to `applyMigrations.ts`. The migration never runs on prod.

**How to avoid:** Always update `backend/scripts/applyMigrations.ts` when adding a new backend migration file. Add both the migration entry and the verification query.

## Code Examples

### Compare Endpoint — Application-Level Scoring

```typescript
// Source: CONTEXT.md (proximity formula specification)
// Pattern: fetch in parallel, score in application code

async function compareWithPoliticians(
  userId: string,
  politicianIds: string[]
): Promise<CompareResult[]> {
  // Fetch user answers (non-public schema — pool.query)
  const { rows: userAnswers } = await pool.query<{ topic_id: string; value: string }>(
    `SELECT topic_id, value FROM inform.compass_responses
     WHERE user_id = $1 AND deleted_at IS NULL`,
    [userId]
  );
  const userMap = new Map(userAnswers.map(r => [r.topic_id, parseFloat(r.value)]));

  // Fetch all politician answers in parallel
  const politicianResults = await Promise.all(
    politicianIds.map(async (pid) => {
      const { rows } = await pool.query<{ topic_id: string; value: string; full_name: string | null }>(
        `SELECT pa.topic_id, pa.value::text, ep.full_name
         FROM inform.politician_answers pa
         JOIN essentials.politicians ep ON ep.id = pa.politician_id
         WHERE pa.politician_id = $1`,
        [pid]
      );
      return { id: pid, rows };
    })
  );

  // Score each politician
  return politicianResults.map(({ id, rows }) => {
    const sharedTopics = rows.filter(r => userMap.has(r.topic_id));
    const topics = sharedTopics.map(r => {
      const userValue = userMap.get(r.topic_id)!;
      const politicianValue = parseFloat(r.value);
      return { topic_id: r.topic_id, user_value: userValue, politician_value: politicianValue };
    });
    const alignmentScore = topics.length === 0
      ? 0
      : Math.round(
          topics.reduce((sum, t) => sum + (1 - Math.abs(t.user_value - t.politician_value) / 5), 0)
          / topics.length
          * 100
        );
    return {
      id,
      name: rows[0]?.full_name ?? null,
      alignment_score: alignmentScore,
      topics,
    };
  });
}
```

### Verdicts Table Migration

```sql
-- Pattern: SECURITY DEFINER + SET search_path = '' (project standard)
-- Source: backend/migrations/030_decimal_compass_values.sql

CREATE TABLE IF NOT EXISTS inform.compass_verdicts (
  user_id      UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  quote_id     UUID        NOT NULL REFERENCES essentials.quotes(id) ON DELETE CASCADE,
  supported    BOOLEAN     NOT NULL,
  rank         INTEGER,    -- NULL if not supported; position among liked quotes in session
  session_size INTEGER     NOT NULL,  -- total quotes in the ranking session
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, quote_id)
);

CREATE INDEX idx_compass_verdicts_user ON inform.compass_verdicts(user_id);
CREATE INDEX idx_compass_verdicts_quote ON inform.compass_verdicts(quote_id);

-- RLS: owner-read only
ALTER TABLE inform.compass_verdicts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "verdicts: owner read"
  ON inform.compass_verdicts
  FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));
-- No INSERT/UPDATE/DELETE RLS — all writes via service role (pool.query/RPC)
GRANT SELECT ON inform.compass_verdicts TO authenticated;
```

### Batch Verdicts RPC

```sql
-- Pattern: single atomic RPC for batch upsert
-- Source: admin_create_topic_with_stances two-pass pattern from migration 029

CREATE OR REPLACE FUNCTION public.upsert_compass_verdicts(
  p_user_id  UUID,
  p_verdicts JSONB  -- [{quote_id, supported, rank, session_size}]
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  elem jsonb;
BEGIN
  FOR elem IN SELECT * FROM jsonb_array_elements(p_verdicts)
  LOOP
    INSERT INTO inform.compass_verdicts (user_id, quote_id, supported, rank, session_size, updated_at)
    VALUES (
      p_user_id,
      (elem->>'quote_id')::uuid,
      (elem->>'supported')::boolean,
      NULLIF(elem->>'rank', 'null')::integer,
      (elem->>'session_size')::integer,
      now()
    )
    ON CONFLICT (user_id, quote_id) DO UPDATE
      SET supported    = EXCLUDED.supported,
          rank         = EXCLUDED.rank,
          session_size = EXCLUDED.session_size,
          updated_at   = now();
  END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION public.upsert_compass_verdicts(uuid, jsonb) TO service_role;
```

### Topic Delete with Response Guard

```typescript
// Pattern: 422 if responses exist, 204 if deleted
// Source: project standard for 422 validation errors

router.delete('/topics/delete/:id', requireAuth, async (req, res) => {
  // requireAdmin inline check...
  const topicId = req.params.id;
  if (!UUID_REGEX.test(topicId)) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid topic ID format' });
    return;
  }
  const { rows: [{ count }] } = await pool.query<{ count: string }>(
    `SELECT COUNT(*)::text AS count FROM inform.compass_responses WHERE topic_id = $1`,
    [topicId]
  );
  if (parseInt(count, 10) > 0) {
    res.status(422).json({
      code: 'TOPIC_HAS_RESPONSES',
      message: 'Cannot delete topic with existing responses. Set is_live=false to archive.',
    });
    return;
  }
  await pool.query(`DELETE FROM inform.compass_topics WHERE id = $1`, [topicId]);
  res.status(204).send();
});
```

### Admin Route Gating in compass.ts / compassAdmin.ts

```typescript
// Source: backend/src/routes/admin.ts lines 59-61
// Pattern: router-level middleware for admin gating on a dedicated router

// compassAdmin.ts
const router = Router();
router.use(requireAuth as any, requireAdmin as any);  // All routes are admin-only

router.post('/topics/create', async (req, res) => { /* ... */ });
router.patch('/topics/update', async (req, res) => { /* ... */ });
// etc.

// index.ts — mount at same prefix as compassRouter
app.use('/api/compass', compassRouter);   // existing
app.use('/api/compass', compassAdminRouter);  // new — admin routes at /api/compass/*
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `compass_responses.value INT` | `NUMERIC(3,1)` | Migration 030 (already applied) | Write-in half-step values accepted |
| `upsert_compass_answer` with INT cast | NUMERIC cast | Migration 030 (already applied) | No change needed |
| `politician_answers.value INT` | `NUMERIC(3,1)` needed | Phase 39 (not yet applied) | Required to accept half-step politician stances |
| Admin compass routes only at `/api/admin/compass/*` | Also at `/api/compass/*` | Phase 39 | CompassV2 Go-compatible URL parity |
| No compare endpoint | `POST /api/compass/compare` | Phase 39 | CompassV2 comparison feature |
| No verdicts | `inform.compass_verdicts` + CRUD | Phase 39 | Read & Rank feature |

**Deprecated/outdated:**
- `admin_update_politician_answers` upsert-only behavior: replaced with full-replacement behavior in phase 39 migration
- `inform.politicians` table: dropped in migration 035 (phase 35). All politician FK references now point to `essentials.politicians`.

## Open Questions

1. **Does `?politician_id=` filter on GET /api/compass/verdicts require a join to essentials.quotes?**
   - What we know: `compass_verdicts.quote_id` FKs to `essentials.quotes`. The `essentials.quotes` table presumably has a `politician_id` column (CompassV2 uses it to filter verdicts by politician on the profile page).
   - What's unclear: The `essentials.quotes` schema is not defined in any migration we could inspect (it was created by the Go server's database). The column name for the politician FK in that table is unknown.
   - Recommendation: Before implementing the `?politician_id=` filter, query `information_schema.columns WHERE table_schema='essentials' AND table_name='quotes'` in production to confirm column names. The pool.query JOIN will be: `JOIN essentials.quotes q ON q.id = cv.quote_id WHERE q.{politician_column} = $1`.

2. **Should the half-step constraint on `compass_responses.value` be tightened?**
   - What we know: Migration 030 added only range check (`>= 0.5 AND <= 5.5`). CONTEXT says the constraint should also enforce half-steps (`value * 2 = ROUND(value * 2)`). Zod in the route already enforces this.
   - What's unclear: Whether adding a stricter constraint in phase 39 could break any existing data.
   - Recommendation: Existing valid values (1.0–5.0 as integers) all satisfy the half-step constraint. Safe to add. Include in the phase 39 migration as `DROP CONSTRAINT IF EXISTS compass_responses_value_check; ADD CONSTRAINT ... CHECK (value >= 0.5 AND value <= 5.5 AND (value * 2) = ROUND(value * 2))`.

3. **Admin endpoints at `/api/compass/*` vs `/api/admin/compass/*` — does CompassV2 actually call both paths?**
   - What we know: PLATFORM-CONSOLIDATION.md shows the Go server's URLs (e.g., `/api/compass/topics/create`) which CompassV2 currently calls. The accounts server also has `/api/admin/compass/topics`.
   - What's unclear: Whether CompassV2 will be updated to use only one set of URLs or needs both to work during transition.
   - Recommendation: Implement the Go-compatible URLs (`/api/compass/topics/create` etc.) in phase 39. The existing `/api/admin/compass/topics` routes can remain as-is — no removal needed, just addition of new paths.

## Sources

### Primary (HIGH confidence)
- `/c/EV-Accounts/backend/src/routes/compass.ts` — full review of existing routes and patterns
- `/c/EV-Accounts/backend/src/lib/compassService.ts` — full review of existing service functions
- `/c/EV-Accounts/backend/src/routes/admin.ts` — review of existing admin compass routes (lines 563-931)
- `/c/EV-Accounts/backend/src/lib/adminService.ts` — review of admin service functions (lines 280-600)
- `/c/EV-Accounts/backend/migrations/025_rpc_pool_migration.sql` — RPC definitions including `admin_update_politician_answers`
- `/c/EV-Accounts/backend/migrations/029_compass_admin_rpcs.sql` — `admin_create_topic_with_stances`, `admin_assign_topic_categories`
- `/c/EV-Accounts/backend/migrations/030_decimal_compass_values.sql` — confirms compass_responses already migrated
- `/c/EV-Accounts/supabase/migrations/20260226000015_inform_schema.sql` — confirms politician_answers.value still INT
- `/c/EV-Accounts/supabase/migrations/20260319000044_phase34_essentials_rls.sql` — confirms essentials.quotes table exists
- `/c/EV-Accounts/.planning/phases/39-compass-additions/39-CONTEXT.md` — all implementation decisions
- `/c/EV-Accounts/PLATFORM-CONSOLIDATION.md` — confirms Go server URL patterns CompassV2 expects

### Secondary (MEDIUM confidence)
- `/c/EV-Accounts/backend/src/index.ts` — confirms `/api/compass` and `/api/admin` mount points

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new libraries, codebase is the source
- Architecture: HIGH — existing patterns are clear and directly applicable
- Pitfalls: HIGH — discovered from reading actual code (migration gaps, existing RPC behavior)
- Open questions: MEDIUM — essentials.quotes schema requires DB inspection to confirm

**Research date:** 2026-03-20
**Valid until:** Stable — no external dependencies, only internal codebase
