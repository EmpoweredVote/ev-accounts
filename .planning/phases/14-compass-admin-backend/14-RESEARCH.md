# Phase 14: Compass Admin Backend - Research

**Researched:** 2026-03-06
**Domain:** Express admin routes, Supabase admin client, PostgreSQL RPC functions (inform schema)
**Confidence:** HIGH — all findings come from direct codebase inspection

---

## Summary

Phase 14 adds compass admin endpoints (topics CRUD, stances update, politicians CRUD, categories CRUD, topic-category assignment) to the existing `admin.ts` route file and `adminService.ts` service file. The codebase has a mature admin route pattern from prior phases that must be followed exactly.

The most important pre-planning discovery is that several routes from the CONTEXT.md already exist in partially-complete form from Phase 7. The existing `POST /api/admin/compass/topics` and `PUT /api/admin/compass/topics/:id` are wired but incomplete — they lack stances array support (CADM-02) and use `PUT` method where CONTEXT specifies `PATCH`. All of the missing routes have clear analogues in the existing codebase to pattern-match against.

The admin action log infrastructure is fully implemented: `public.admin_audit_log` table exists (migration 024), `logAdminAction()` function is implemented in adminService.ts, and the pattern of calling it before every mutation response is established throughout admin.ts.

**Primary recommendation:** Audit the existing admin.ts section-by-section before writing new code. Several routes exist but need modification (method change, schema expansion). New routes follow the exact pattern of existing compass admin routes already in the file.

---

## Standard Stack

No new libraries are needed. Phase 14 is pure extension of existing infrastructure.

### Core (already installed)
| Library | Version | Purpose | Notes |
|---------|---------|---------|-------|
| `express` | 4.x | HTTP routing | Router already imported in admin.ts |
| `zod` | already installed | Request body validation | All existing admin routes use z.object() |
| `@supabase/supabase-js` | already installed | DB access via supabaseAdmin | Used via adminService.ts only |

### Pattern Libraries (already in use)
| Utility | Location | Purpose |
|---------|----------|---------|
| `supabaseAdmin` | `backend/src/lib/supabase.ts` | Service-role Supabase client for all admin writes |
| `adminRpc()` | `backend/src/lib/supabase.ts` | Wrapper for calling SECURITY DEFINER RPCs |
| `logAdminAction()` | `backend/src/lib/adminService.ts` | Audit every mutation |
| `requireAuth` + `requireAdmin` | `backend/src/middleware/` | Applied via `router.use()` — covers all routes automatically |

**Installation:** No new packages needed.

---

## What Already Exists (Critical Pre-Planning Audit)

### Existing admin.ts compass routes (Phase 7 stubs)

These routes exist in `backend/src/routes/admin.ts` and need modification, not creation:

| Route | Exists? | Status | What's Missing |
|-------|---------|--------|----------------|
| `POST /api/admin/compass/topics` | YES | Incomplete | No `stances` array in schema or service call; returns topic only (CADM-02 requires topic+stances) |
| `PUT /api/admin/compass/topics/:id` | YES | Method wrong | CONTEXT specifies `PATCH`; functionally complete otherwise |
| `PUT /api/admin/compass/stances/:id` | YES | Method wrong | CONTEXT specifies `PATCH`; functionally complete otherwise |
| `PUT /api/admin/compass/politicians/:id/answers` | YES | Complete | No changes needed |
| `POST /api/admin/compass/politicians/:id/context` | YES | Complete | No changes needed |
| `GET /api/admin/essentials/politicians` | YES | Path wrong | CONTEXT specifies `GET /api/admin/compass/politicians`; also needs `is_candidate` in response |

### Existing adminService.ts functions (Phase 7 stubs)

| Function | Exists? | Status |
|----------|---------|--------|
| `adminCreateTopic(data)` | YES | Incomplete — no stances support |
| `adminUpdateTopic(topicId, data)` | YES | Complete — uses `admin_update_topic` RPC |
| `adminUpdateStance(stanceId, data)` | YES | Complete — direct supabaseAdmin .from() update |
| `adminUpdatePoliticianAnswers(id, answers)` | YES | Complete — uses `admin_update_politician_answers` RPC |
| `adminSetPoliticianContext(id, topicId, data)` | YES | Complete — direct supabaseAdmin upsert |
| `adminListPoliticians()` | YES | Incomplete — missing `is_candidate` column (added in migration 026) |

### Missing routes (must be added fresh)

| Route | Requirement | Service Function Needed |
|-------|-------------|------------------------|
| `GET /api/admin/compass/topics` | CADM-01 | `adminListTopics()` — new |
| `POST /api/admin/compass/politicians` | CADM-03 | `adminCreatePolitician()` — new |
| `PATCH /api/admin/compass/politicians/:id` | CADM-04 | `adminUpdatePolitician()` — new |
| `GET /api/admin/compass/categories` | CADM-05 | `adminListCategories()` — new |
| `POST /api/admin/compass/categories` | CADM-06 | `adminCreateCategory()` — new |
| `PUT /api/admin/compass/topics/:id/categories` | CADM-07 | `adminAssignTopicCategories()` — new |

---

## inform Schema (Verified from Migrations 015, 026)

### compass_topics
```
id            UUID        PK, DEFAULT gen_random_uuid()
title         TEXT        NOT NULL
short_title   TEXT        nullable
question_text TEXT        NOT NULL
is_live       BOOLEAN     NOT NULL DEFAULT false
is_active     BOOLEAN     GENERATED ALWAYS AS (is_live) STORED  ← read-only, never write
version       INT         NOT NULL DEFAULT 1
went_live_at  TIMESTAMPTZ nullable (set by admin_update_topic RPC when is_live→true)
created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
```

**Critical:** `is_active` is a GENERATED column — never include it in INSERT or UPDATE payloads. The `admin_update_topic` RPC handles `went_live_at` automatically when `is_live` transitions to true.

### compass_stances
```
id       UUID PK
topic_id UUID NOT NULL FK→compass_topics.id ON DELETE CASCADE
value    INT  NOT NULL CHECK (value BETWEEN 1 AND 5)
text     TEXT NOT NULL
UNIQUE (topic_id, value)  ← enforces one stance per value per topic
```

When creating a topic with stances atomically: insert topic first, then insert all stances in the same function using the new topic's id.

### compass_categories
```
id         UUID        PK, DEFAULT gen_random_uuid()
title      TEXT        NOT NULL UNIQUE
created_at TIMESTAMPTZ NOT NULL DEFAULT now()
```

`title` has a UNIQUE constraint — duplicate category names will get a DB error. Must be caught and returned as 400.

### compass_topic_categories
```
topic_id    UUID NOT NULL FK→compass_topics.id    ON DELETE CASCADE
category_id UUID NOT NULL FK→compass_categories.id ON DELETE CASCADE
PRIMARY KEY (topic_id, category_id)
```

`PUT /api/admin/compass/topics/:id/categories` replaces all categories — use DELETE then INSERT pattern (or delete all + re-insert) within the service function.

### politicians (as of migration 026)
```
id               UUID        PK
first_name       TEXT        NOT NULL
last_name        TEXT        NOT NULL
preferred_name   TEXT        nullable
full_name        TEXT        nullable
office_title     TEXT        nullable
photo_origin_url TEXT        nullable
is_active        BOOLEAN     NOT NULL DEFAULT true
is_candidate     BOOLEAN     NOT NULL DEFAULT false  ← added in migration 026
created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
```

**Critical:** `is_candidate` exists in both the live schema (migration 026) and `database.types.ts` (inform.politicians.Row includes `is_candidate: boolean`). Create and update politician routes must include `is_candidate` in validation schemas.

### Admin audit log (public.admin_audit_log)
```
id             UUID    PK
actor_id       UUID    NOT NULL FK→public.users.id
action         TEXT    NOT NULL
target_user_id UUID    nullable FK→public.users.id
details        JSONB   NOT NULL DEFAULT '{}'
target_id      UUID    nullable (legacy column from migration 003)
metadata       JSONB   nullable (legacy column from migration 003)
created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
```

`logAdminAction(actorId, action, targetUserId, details)` writes to this table. For compass entities, `targetUserId` is `null` (no user is the target — the entity ID goes in `details`). This is the established pattern in existing compass admin routes.

---

## RPC Functions (Verified from backend/migrations/)

### Already exist and working
| RPC Function | Schema | Purpose | Used By |
|---|---|---|---|
| `admin_update_topic` | public | Partial update with went_live_at logic | `adminUpdateTopic()` |
| `admin_list_politicians` | public | All politicians with answer_count | `adminListPoliticians()` |
| `admin_update_politician_answers` | public | Bulk upsert politician answers | `adminUpdatePoliticianAnswers()` |
| `admin_get_dashboard_stats` | public | Dashboard stats | existing |
| `admin_list_accounts` | public | Paginated accounts | existing |

### Must be created in a new migration (Phase 14)
| RPC Function | Purpose | Why RPC vs direct |
|---|---|---|
| `admin_create_topic_with_stances` | Atomic topic + stances create | Cannot be atomic with JS awaits; uses SECURITY DEFINER to bypass RLS |
| `admin_assign_topic_categories` | Replace all categories for a topic atomically | DELETE + INSERT must be atomic |

**Note on `admin_list_politicians`:** The existing RPC function was created in migration 025 but the `is_candidate` column was added later in migration 026. The RPC does `SELECT p.id, p.first_name, p.last_name, p.preferred_name, p.full_name, p.office_title, p.photo_origin_url, p.is_active, p.created_at` — it does NOT include `is_candidate`. The `adminListPoliticians()` function and `admin_list_politicians` RPC need to be updated to include this field.

### Functions where direct supabaseAdmin .from() is preferred
- `adminCreatePolitician()` — simple INSERT, no multi-table atomicity needed
- `adminUpdatePolitician()` — simple UPDATE .eq('id', id), no multi-table atomicity
- `adminListTopics()` — SELECT with LEFT JOIN stances, or two sequential fetches
- `adminListCategories()` — simple SELECT on inform.compass_categories
- `adminCreateCategory()` — simple INSERT on inform.compass_categories

---

## Architecture Patterns

### Admin Route Pattern (from existing admin.ts)

```typescript
// Source: backend/src/routes/admin.ts (established pattern)

// 1. Zod schema at top of section
const CreatePoliticianSchema = z.object({
  first_name: z.string().min(1),
  last_name: z.string().min(1),
  // ...
});

// 2. Route handler — try/catch, schema parse, service call, logAdminAction, respond
router.post('/compass/politicians', async (req, res) => {
  try {
    const parsed = CreatePoliticianSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid request body', details: parsed.error.flatten() });
      return;
    }
    const politician = await adminCreatePolitician(parsed.data);
    await logAdminAction(actorId(req), 'create_politician', null, {
      politician_id: (politician as Record<string, unknown>).id,
    });
    res.status(201).json(politician);
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});
```

**Key rules from established pattern:**
- Zod `safeParse()`, not `parse()` — avoid uncaught exceptions
- `logAdminAction` called before `res.json()`, after service call
- `actorId(req)` extracts userId from the JWT (helper already in admin.ts)
- 201 for creates, 200 for updates
- 404 for not-found: `if (e.code === 'NOT_FOUND') { res.status(404).json(...) }`
- `router.use(requireAuth as any, requireAdmin as any)` already applied — no per-route middleware

### Admin Service Pattern (from existing adminService.ts)

```typescript
// Source: backend/src/lib/adminService.ts (established pattern)

// Direct supabaseAdmin for simple operations
export async function adminCreatePolitician(data: {
  first_name: string;
  last_name: string;
  // ...
}): Promise<Record<string, unknown>> {
  const { data: row, error } = await supabaseAdmin
    .schema('inform')
    .from('politicians')
    .insert({ ...data })
    .select()
    .single();

  if (error) throw new Error(error.message);
  return row as Record<string, unknown>;
}

// adminRpc() for complex operations that need atomicity or COALESCE logic
export async function adminUpdateTopic(topicId: string, data: {...}): Promise<Record<string, unknown>> {
  const { data: result, error } = await adminRpc('admin_update_topic', {
    p_topic_id: topicId,
    p_title: data.title ?? null,
    // ...
  });
  if (error) {
    if (error.message === 'NOT_FOUND') throw Object.assign(new Error('...'), { code: 'NOT_FOUND' });
    throw new Error(error.message);
  }
  return result as Record<string, unknown>;
}
```

### Atomic Topic Create with Stances Pattern

The existing `adminCreateTopic()` only creates the topic. CADM-02 requires that stances be created atomically with the topic. This requires a new RPC function:

```sql
-- New: admin_create_topic_with_stances
-- Two-pass design: validate all stances first, then insert topic + stances
CREATE OR REPLACE FUNCTION public.admin_create_topic_with_stances(
  p_title text,
  p_short_title text DEFAULT NULL,
  p_question_text text,
  p_is_live boolean DEFAULT false,
  p_stances jsonb DEFAULT '[]'::jsonb  -- array of {value: int, text: text}
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_topic inform.compass_topics;
  v_stance jsonb;
  v_stance_value int;
  v_stances_out jsonb;
BEGIN
  -- Pass 1: validate all stances before any write
  FOR v_stance IN SELECT * FROM jsonb_array_elements(p_stances) LOOP
    v_stance_value := (v_stance->>'value')::int;
    IF v_stance_value NOT BETWEEN 1 AND 5 THEN
      RAISE EXCEPTION 'INVALID_STANCE_VALUE: value must be 1-5, got %', v_stance_value;
    END IF;
    IF (v_stance->>'text') IS NULL OR trim(v_stance->>'text') = '' THEN
      RAISE EXCEPTION 'INVALID_STANCE_TEXT: text is required for value %', v_stance_value;
    END IF;
  END LOOP;

  -- Pass 2: insert topic
  INSERT INTO inform.compass_topics (title, short_title, question_text, is_live, went_live_at)
  VALUES (
    p_title, p_short_title, p_question_text, p_is_live,
    CASE WHEN p_is_live THEN now() ELSE NULL END
  )
  RETURNING * INTO v_topic;

  -- Pass 2: insert stances
  FOR v_stance IN SELECT * FROM jsonb_array_elements(p_stances) LOOP
    INSERT INTO inform.compass_stances (topic_id, value, text)
    VALUES (v_topic.id, (v_stance->>'value')::int, v_stance->>'text');
  END LOOP;

  -- Return topic + stances array
  SELECT jsonb_build_object(
    'topic', row_to_json(v_topic),
    'stances', COALESCE(
      (SELECT jsonb_agg(row_to_json(s)) FROM inform.compass_stances s WHERE s.topic_id = v_topic.id),
      '[]'::jsonb
    )
  ) INTO v_stances_out;

  RETURN v_stances_out;
END;
$$;
```

### Category Assignment Pattern (Replace-All)

```sql
-- New: admin_assign_topic_categories
-- Atomically replaces all category assignments for a topic
CREATE OR REPLACE FUNCTION public.admin_assign_topic_categories(
  p_topic_id uuid,
  p_category_ids jsonb  -- array of UUID strings
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- Verify topic exists
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = p_topic_id) THEN
    RAISE EXCEPTION 'NOT_FOUND';
  END IF;

  -- Replace all categories atomically
  DELETE FROM inform.compass_topic_categories WHERE topic_id = p_topic_id;

  INSERT INTO inform.compass_topic_categories (topic_id, category_id)
  SELECT p_topic_id, (cat_id)::uuid
  FROM jsonb_array_elements_text(p_category_ids) AS cat_id;
END;
$$;
```

### Architecture Test — Required Update

`tests/integration/architecture.test.ts` has a hardcoded allowlist of files that may reference `supabaseAdmin`. Adding adminService.ts functions that call supabaseAdmin is fine — it's already in the allowlist. No test changes needed.

However, any new service file added in Phase 14 would need to be added to the allowlist. The existing pattern is to put all admin data access in `adminService.ts` — do not create a separate `compassAdminService.ts`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Atomic topic+stances create | JS await chain (insert topic, then insert stances) | `admin_create_topic_with_stances` RPC | If stances insert fails after topic inserted, topic exists with no stances — orphaned data |
| Category replace | Loop through JS awaits | `admin_assign_topic_categories` RPC | DELETE + INSERT must be atomic — partial failure leaves topic in inconsistent state |
| Admin access check | Per-route admin check | `router.use(requireAuth as any, requireAdmin as any)` | Already applied globally in admin.ts — all routes in the router are protected |
| is_live transition logic | JS conditional + direct update | `admin_update_topic` RPC | went_live_at must be set atomically with is_live=true; RPC already handles this correctly |
| Upsert politician answers | Individual inserts | `admin_update_politician_answers` RPC | Already exists, handles ON CONFLICT correctly |

---

## Response Contracts (Locked from CONTEXT.md)

| Endpoint | Returns |
|----------|---------|
| `POST /api/admin/compass/topics` | Full topic object + stances array: `{ id, title, short_title, question_text, is_live, version, went_live_at, created_at, updated_at, stances: [{id, value, text}] }` |
| `GET /api/admin/compass/topics` | Topic metadata only (no stances): `{ topics: [{id, title, short_title, is_live, created_at, updated_at}] }` |
| `PATCH /api/admin/compass/topics/:id` | Updated topic record (no stances) |
| `PATCH /api/admin/compass/stances/:id` | Updated stance record |
| `POST /api/admin/compass/politicians` | Full politician record |
| `PATCH /api/admin/compass/politicians/:id` | Updated politician record |
| `GET /api/admin/compass/categories` | `{ categories: [{id, title, created_at}] }` |
| `POST /api/admin/compass/categories` | Created category record |
| `PUT /api/admin/compass/topics/:id/categories` | `{ ok: true }` (consistent with other replace operations) |
| `PUT /api/admin/compass/politicians/:id/answers` | `{ ok: true }` (existing pattern — no change) |

HTTP status: 201 creates, 200 updates, 400 validation, 404 not found — consistent with all existing admin routes.

Error shape: `{ error: 'message string' }` or `{ error: 'message', details: parsed.error.flatten() }` for Zod failures. This is the established pattern throughout admin.ts.

---

## Common Pitfalls

### Pitfall 1: Writing is_active in INSERT/UPDATE
**What goes wrong:** Attempting to set `is_active` on compass_topics fails at the DB level — it's a GENERATED ALWAYS AS column.
**Why it happens:** `is_active` appears in the column list but is computed from `is_live`.
**How to avoid:** Never include `is_active` in INSERT or UPDATE payloads for compass_topics. Set `is_live` only.
**Warning signs:** Supabase error mentioning "cannot insert into column of generated expression".

### Pitfall 2: Using wrong migration location
**What goes wrong:** New SQL goes into `supabase/migrations/` instead of `backend/migrations/`
**Why it happens:** There are two migration directories. `supabase/migrations/` has numbered Supabase CLI migrations. `backend/migrations/` has separate numbered migrations (025–028) for RPCs applied directly via adminRpc calls.
**How to avoid:** New Phase 14 RPCs follow the `backend/migrations/` pattern as `029_compass_admin_rpcs.sql`. Check that the `admin_list_politicians` RPC update (to include `is_candidate`) is also in this file.
**Warning signs:** RPC function not found at runtime.

### Pitfall 3: Forgetting logAdminAction on every mutation
**What goes wrong:** A mutation route returns success without calling `logAdminAction()` — violates ADMN-05.
**Why it happens:** Easy to skip when adding a new route quickly.
**How to avoid:** Every `router.post()`, `router.patch()`, `router.put()`, `router.delete()` in admin.ts must call `await logAdminAction(actorId(req), 'action_name', null, { ...snapshot })` before the final `res.json()`.
**Warning signs:** Review checklist — count mutation routes vs logAdminAction calls in admin.ts.

### Pitfall 4: Creating a new service file instead of extending adminService.ts
**What goes wrong:** A new `compassAdminService.ts` containing `supabaseAdmin` fails the architecture test.
**Why it happens:** `architecture.test.ts` has a hardcoded allowlist of files permitted to reference `supabaseAdmin`. New files are not in the allowlist.
**How to avoid:** All compass admin functions go in `adminService.ts` — it's already in the allowlist and is the established home for all admin data access.
**Warning signs:** `vitest` failing the "supabaseAdmin exists only in expected files" test.

### Pitfall 5: Returning stances from GET /admin/compass/topics
**What goes wrong:** Loading all topics with all their stances in the list view is a heavy query and contradicts the CONTEXT decision.
**Why it happens:** Tempting to return everything in one shot.
**How to avoid:** `GET /api/admin/compass/topics` returns topic metadata only (id, title, short_title, is_live, created_at, updated_at). Stances are loaded on detail view by a separate endpoint not implemented in Phase 14.
**Warning signs:** Response shape includes nested stances array on the list endpoint.

### Pitfall 6: Method mismatch with CONTEXT decisions
**What goes wrong:** Implementing `PUT /api/admin/compass/topics/:id` and `PUT /api/admin/compass/stances/:id` instead of `PATCH`.
**Why it happens:** The Phase 7 stubs used PUT; CONTEXT.md specifies PATCH for Phase 14.
**How to avoid:** Change `router.put('/compass/topics/:id', ...)` to `router.patch('/compass/topics/:id', ...)` and similarly for stances. The existing `router.put('/compass/politicians/:id/answers', ...)` stays as PUT (CONTEXT specifies PUT for that route).
**Warning signs:** Phase 15 UI calling PATCH and getting 404 (Express method mismatch).

### Pitfall 7: Duplicate category title not handled as 400
**What goes wrong:** `POST /api/admin/compass/categories` with a duplicate title returns 500 from an unhandled DB unique constraint violation.
**Why it happens:** `compass_categories.title` has a UNIQUE constraint; Supabase error code `23505` is returned but not caught.
**How to avoid:** In `adminCreateCategory()`, check for `error.code === '23505'` and throw with `code: 'DUPLICATE_TITLE'` so the route returns 400 instead of 500.

### Pitfall 8: admin_list_politicians missing is_candidate
**What goes wrong:** The existing `admin_list_politicians` RPC was created in migration 025 before `is_candidate` was added in migration 026. It selects explicit columns and omits `is_candidate`.
**Why it happens:** Column was added to the table after the RPC was written.
**How to avoid:** Update `admin_list_politicians` with `CREATE OR REPLACE` to add `p.is_candidate` to the SELECT list. Include in the Phase 14 migration as `029_compass_admin_rpcs.sql`.

---

## Code Examples

### Existing logAdminAction usage (established pattern)
```typescript
// Source: backend/src/routes/admin.ts lines 448-455
await logAdminAction(actorId(req), 'create_compass_topic', null, {
  topic_id: (topic as Record<string, unknown>).id,
  title: parsed.data.title,
});
res.status(201).json(topic);
```

### Existing 404 handling (established pattern)
```typescript
// Source: backend/src/routes/admin.ts lines 479-484
} catch (err) {
  const e = err as { code?: string };
  if (e.code === 'NOT_FOUND') {
    res.status(404).json({ error: 'Topic not found' });
    return;
  }
  res.status(500).json({ error: 'Internal server error' });
}
```

### Existing supabaseAdmin .schema('inform') pattern
```typescript
// Source: backend/src/lib/adminService.ts lines 270-284
const { data: row, error } = await supabaseAdmin
  .schema('inform')
  .from('compass_topics')
  .insert({
    title,
    short_title: short_title ?? null,
    question_text,
    is_live,
    went_live_at: is_live ? new Date().toISOString() : null,
  })
  .select()
  .single();
```

### Existing adminRpc usage for NOT_FOUND handling
```typescript
// Source: backend/src/lib/adminService.ts lines 302-318
const { data: result, error } = await adminRpc('admin_update_topic', {
  p_topic_id: topicId,
  p_title: data.title ?? null,
  p_short_title: data.short_title ?? null,
  p_question_text: data.question_text ?? null,
  p_is_live: data.is_live ?? null,
});

if (error) {
  if (error.message === 'NOT_FOUND') {
    throw Object.assign(new Error('Topic not found'), { code: 'NOT_FOUND' });
  }
  throw new Error(error.message);
}
```

---

## Test Pattern for Phase 14

No live-DB tests exist for admin routes. All existing tests are CI-safe (auth enforcement + architecture enforcement).

Phase 14 tests should follow the established CI-safe pattern:

```typescript
// Pattern: test 401 (no auth) and 403 (auth but no admin) for all new routes
describe('Admin compass routes — auth/admin enforcement (CI-safe)', () => {
  it('GET /api/admin/compass/topics returns 401 without auth', async () => {
    const res = await request(app).get('/api/admin/compass/topics');
    expect(res.status).toBe(401);
  });
  // Note: testing 403 (auth but not admin) requires a valid JWT, which means
  // a live Supabase instance. The standard CI pattern only tests 401.
});

// Pattern: architecture test for new service functions
describe('Admin compass routes — architecture enforcement (CI-safe)', () => {
  it('admin.ts does not reference supabaseAdmin', () => {
    const content = fs.readFileSync(path.resolve(BACKEND_SRC, 'routes/admin.ts'), 'utf-8');
    expect(content).not.toContain('supabaseAdmin');
  });
});
```

The 403 guard (requireAdmin) is tested at the middleware layer, not per-route. The auth enforcement tests (401 without header) are the CI-safe assertions for every new route.

---

## Complete Route Manifest (for Phase 15 reference)

This is the full set of admin compass endpoints after Phase 14 completes:

| Method | Path | Status Code | Body | Returns |
|--------|------|-------------|------|---------|
| GET | `/api/admin/compass/topics` | 200 | — | `{ topics: [{id, title, short_title, is_live, created_at, updated_at}] }` |
| POST | `/api/admin/compass/topics` | 201 | `{title, short_title?, question_text, is_live?, stances?: [{value, text}]}` | `{topic: {...}, stances: [{id, value, text}]}` |
| PATCH | `/api/admin/compass/topics/:id` | 200 | `{title?, short_title?, question_text?, is_live?}` | updated topic record |
| PATCH | `/api/admin/compass/stances/:id` | 200 | `{text?, value?}` | updated stance record |
| GET | `/api/admin/compass/categories` | 200 | — | `{ categories: [{id, title, created_at}] }` |
| POST | `/api/admin/compass/categories` | 201 | `{title}` | created category record |
| PUT | `/api/admin/compass/topics/:id/categories` | 200 | `{category_ids: string[]}` | `{ ok: true }` |
| GET | `/api/admin/compass/politicians` | 200 | — | `{ politicians: [{id, first_name, last_name, ..., is_candidate, answer_count}] }` |
| POST | `/api/admin/compass/politicians` | 201 | `{first_name, last_name, preferred_name?, full_name?, office_title?, photo_origin_url?, is_candidate?}` | created politician record |
| PATCH | `/api/admin/compass/politicians/:id` | 200 | `{first_name?, last_name?, preferred_name?, full_name?, office_title?, photo_origin_url?, is_active?, is_candidate?}` | updated politician record |
| PUT | `/api/admin/compass/politicians/:id/answers` | 200 | `{answers: [{topic_id, value}]}` | `{ ok: true }` |
| POST | `/api/admin/compass/politicians/:id/context` | 200 | `{topic_id, reasoning, sources?: string[]}` | upserted context record |

**Note:** `GET /api/admin/essentials/politicians` (existing path from Phase 7) should be retained for backward compatibility or aliased to the new path. Phase 15 will be told which path to use.

---

## Migration Plan for Phase 14

New migration file: `backend/migrations/029_compass_admin_rpcs.sql`

Contains:
1. `CREATE OR REPLACE FUNCTION public.admin_create_topic_with_stances(...)` — new
2. `CREATE OR REPLACE FUNCTION public.admin_assign_topic_categories(...)` — new
3. `CREATE OR REPLACE FUNCTION public.admin_list_politicians()` — replace existing to include `is_candidate` and use `p.is_active` filters correctly
4. Grants: `GRANT EXECUTE ON FUNCTION ... TO service_role, authenticated`

**Do not** modify `supabase/migrations/` for Phase 14 changes. The `backend/migrations/` pattern is for runtime-applied RPCs.

---

## Open Questions

1. **GET /api/admin/essentials/politicians path collision**
   - What we know: `GET /api/admin/essentials/politicians` currently exists in admin.ts at line 579. CONTEXT specifies the new list endpoint as `GET /api/admin/compass/politicians`.
   - What's unclear: Whether the old path should be removed, kept, or aliased. The index.ts also mounts `essentialsPoliticiansRouter` at `/api/essentials/politicians` (public route) — separate concern.
   - Recommendation: Add the new `/compass/politicians` route and keep the old `/essentials/politicians` route unchanged. Phase 15 UI will be told to call the `/compass/politicians` path.

2. **Stance validation count during topic create**
   - What we know: `compass_stances` has UNIQUE(topic_id, value) and value CHECK (1-5). A topic can have 0-5 stances.
   - What's unclear: Should the RPC enforce that at most 5 stances (one per value 1-5) are provided, or let the UNIQUE constraint handle it?
   - Recommendation: UNIQUE constraint handles duplicates naturally (will raise exception). Validate value range (1-5) in Pass 1 of the two-pass RPC. Do not enforce minimum stances count at create time — topics may start with no stances.

---

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection: `backend/src/routes/admin.ts` — existing compass admin routes verified
- Direct codebase inspection: `backend/src/lib/adminService.ts` — existing service functions verified
- Direct codebase inspection: `backend/migrations/025_rpc_pool_migration.sql` — RPC function definitions verified
- Direct codebase inspection: `supabase/migrations/20260226000015_inform_schema.sql` — inform schema tables and constraints verified
- Direct codebase inspection: `backend/migrations/026_inform_schema_repair_and_candidates.sql` — is_candidate column addition verified
- Direct codebase inspection: `supabase/migrations/20260227000024_phase7_admin_schema.sql` — admin_audit_log structure verified
- Direct codebase inspection: `backend/src/types/database.types.ts` — TypeScript types verified (inform schema, admin_audit_log, RPC function signatures)
- Direct codebase inspection: `tests/integration/architecture.test.ts` — architecture enforcement rules verified
- Direct codebase inspection: `backend/src/middleware/requireAdmin.ts` — admin middleware behavior verified

### Secondary (MEDIUM confidence)
None — all findings are from codebase inspection.

### Tertiary (LOW confidence)
None.

---

## Metadata

**Confidence breakdown:**
- Existing route inventory: HIGH — read admin.ts directly
- Schema column definitions: HIGH — read migrations and database.types.ts directly
- RPC function existence: HIGH — read backend/migrations/025 and 026 directly
- Missing is_candidate in admin_list_politicians RPC: HIGH — confirmed by reading both the RPC source and the schema
- Test patterns: HIGH — read existing test files directly

**Research date:** 2026-03-06
**Valid until:** 2026-04-06 (stable backend, no external dependencies)
