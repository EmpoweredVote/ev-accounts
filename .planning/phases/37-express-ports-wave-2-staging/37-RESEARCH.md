# Phase 37: Express Ports Wave 2 — Staging - Research

**Researched:** 2026-03-20
**Domain:** Role-gated Express routes + staging review workflow + auto-promotion to production
**Confidence:** HIGH

---

## Summary

Phase 37 ports the Staging volunteer review workflow from the Go server to ev-accounts. This covers three entity types (politicians, stances, building photos) across six staging tables, with a full state machine (pending → approved/rejected), advisory locking, and auto-promotion to production on approval.

The implementation follows the Phase 36 pattern exactly: `stagingService.ts` in `src/lib/` + `staging.ts` in `src/routes/` + registration in `index.ts`. All staging queries must use `pool.query()` — the `staging` schema is not in PostgREST's exposed list. The critical new element is a `requireStagingReviewer` middleware that checks the `public.user_roles` table for either `staging_reviewer` or `admin` role before allowing access to any staging route.

Three significant findings from DB inspection require attention in the planning phase:

1. **`staging_reviewer` role does not exist yet** — it must be seeded via a migration before the middleware can work.
2. **Existing staging rows have statuses `pending`, `needs_review`, and `draft`** — the locked state machine uses `pending | approved | rejected`. A migration must handle the default change and existing-row cleanup.
3. **`display_name` is NOT in the Supabase JWT payload** — it lives in `public.users.display_name`. The "derive from JWT" requirement in CONTEXT.md must be implemented as a `pool.query()` lookup against `public.users` by `userId`.
4. **`essentials.politician_answers` does not exist** — the stance approval target table is `inform.politician_answers` (columns: `politician_id`, `topic_id`, `value`), not essentials.
5. **Building photo promotion**: `essentials.building_photos` exists with columns `place_geoid`, `url`, `source_url`, `license`, `attribution`, `wiki_title`, `fetched_at`. The staging `building_photos` table has the same core fields (`place_geoid`, `url`, `source_url`, `license`, `attribution`) — promotion can upsert from staging into essentials on `place_geoid`. The planner should decide whether to implement this or just mark `approved_at` as the CONTEXT.md allows.

**Primary recommendation:** Build one service file and one route file covering all three entity types. The route file is all-privileged (no public reads), so use `router.use(requireAuth as any, requireStagingReviewer as any)` at the top to gate every route without per-route repetition.

---

## Standard Stack

No new libraries needed. All tools already present.

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| `pg` (pool) | existing | All staging schema queries | `staging` not in PostgREST exposed list; pool.query() only |
| Express Router | existing | Route file structure | All 23 existing route files use this pattern |
| `zod` | existing | Request body validation | Used in admin.ts, meetings.ts, vq.ts |
| TypeScript | existing | Row type interfaces in service files | Established in meetingsService.ts, essentialsService.ts |

**Installation:** None required.

---

## Architecture Patterns

### Recommended File Structure

```
backend/src/
├── routes/
│   └── staging.ts           # /api/staging/* — all staging route handlers
└── lib/
    └── stagingService.ts    # pool.query() wrappers for all staging operations
```

Register in `backend/src/index.ts`:
```typescript
import stagingRouter from './routes/staging.js';
// ...
app.use('/api/staging', stagingRouter);
```

### Pattern 1: New Middleware — requireStagingReviewer

The `staging_reviewer` role must be seeded in a migration, then the middleware checks `public.user_roles` via an existing RPC or direct query.

The cleanest approach reuses the `get_user_roles` RPC already established in `roleService.ts`:

```typescript
// Source: backend/src/middleware/ (new file: requireStagingReviewer.ts)
// OR inline in requireAdmin.ts pattern
import { pool } from '../lib/db.js';
import type { Request, Response, NextFunction } from 'express';
import type { AuthenticatedRequest } from './auth.js';

export async function requireStagingReviewer(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authReq = req as AuthenticatedRequest;
  const userId = authReq.userId;

  // Check: is the user an admin OR holds staging_reviewer role?
  // admin_users check (same as requireAdmin)
  const adminResult = await pool.query<{ user_id: string }>(
    `SELECT user_id FROM public.admin_users WHERE user_id = $1 LIMIT 1`,
    [userId]
  );
  if (adminResult.rows.length > 0) { next(); return; }

  // staging_reviewer role check via user_roles + roles join
  const roleResult = await pool.query<{ slug: string }>(
    `SELECT r.slug
     FROM public.user_roles ur
     JOIN public.roles r ON r.id = ur.role_id
     WHERE ur.user_id = $1
       AND r.slug = 'staging_reviewer'
       AND ur.revoked_at IS NULL
     LIMIT 1`,
    [userId]
  );
  if (roleResult.rows.length > 0) { next(); return; }

  res.status(403).json({ error: 'Staging reviewer access required' });
}
```

**Note:** `supabaseAdmin` is intentionally NOT used for this query — the same rule applies as requireAdmin.ts: "src/middleware/ is excluded by architecture test." Direct pool.query() is fine here and avoids PostgREST schema scoping issues for `public` tables.

### Pattern 2: All-Privileged Route File (router.use at top)

```typescript
// Source: backend/src/routes/admin.ts (router.use pattern)
import { requireAuth } from '../middleware/auth.js';
import { requireStagingReviewer } from '../middleware/requireStagingReviewer.js';

const router = Router();

// Every staging route requires staging_reviewer or admin — no exceptions
router.use(requireAuth as any, requireStagingReviewer as any);
```

### Pattern 3: display_name Lookup (pool.query, NOT JWT)

`display_name` is in `public.users` table, NOT in the Supabase JWT payload. The CONTEXT.md phrase "derived from `req.user.display_name` (JWT)" is aspirational — in practice, derive it via DB lookup:

```typescript
// In stagingService.ts
async function getDisplayName(userId: string): Promise<string> {
  const { rows } = await pool.query<{ display_name: string | null }>(
    `SELECT display_name FROM public.users WHERE id = $1`,
    [userId]
  );
  return rows[0]?.display_name ?? userId; // fallback to userId if null
}
```

This lookup is needed for `added_by` on INSERT and `reviewer_name` on review log INSERT. Both fields are `text NOT NULL` in the DB.

### Pattern 4: State Machine — Status Transition Enforcement

Valid transitions (enforced in service layer, not DB constraints):
- `pending` → `approved` (triggers auto-promotion)
- `pending` → `rejected` (terminal)
- `approved` → (terminal — no further transitions)
- `rejected` → (terminal — no further transitions)

```typescript
// In stagingService.ts
const ALLOWED_REVIEW_ACTIONS = ['approved', 'rejected'] as const;

function assertTransitionAllowed(currentStatus: string, newStatus: string): void {
  if (currentStatus !== 'pending') {
    throw Object.assign(
      new Error(`Cannot review a record with status '${currentStatus}'`),
      { code: 'STATUS_TERMINAL', httpStatus: 422 }
    );
  }
  if (!ALLOWED_REVIEW_ACTIONS.includes(newStatus as any)) {
    throw Object.assign(
      new Error(`Invalid review action '${newStatus}'`),
      { code: 'INVALID_ACTION', httpStatus: 422 }
    );
  }
}
```

### Pattern 5: Advisory Locking (courtesy signal, not enforcement gate)

`locked_by` and `locked_at` are text/timestamptz columns on `staging.politicians` and `staging.stances`. Locking is a courtesy signal — review actions do NOT check locks.

```typescript
// POST /api/staging/politicians/:id/lock
// Returns 409 if already locked by someone else

async function acquireLock(
  table: 'politicians' | 'stances',
  id: string,
  reviewerName: string
): Promise<{ ok: true } | { ok: false; lockedBy: string; lockedAt: string }> {
  // Read current lock state
  const { rows } = await pool.query(
    `SELECT locked_by, locked_at FROM staging.${table} WHERE id = $1`,
    [id]
  );
  if (!rows[0]) throw Object.assign(new Error('Not found'), { code: 'NOT_FOUND', httpStatus: 404 });

  const { locked_by, locked_at } = rows[0];
  if (locked_by !== null) {
    return { ok: false, lockedBy: locked_by, lockedAt: locked_at };
  }

  await pool.query(
    `UPDATE staging.${table} SET locked_by = $1, locked_at = NOW() WHERE id = $2`,
    [reviewerName, id]
  );
  return { ok: true };
}
```

**Note:** `building_photos` has no `locked_by`/`locked_at` columns in the DB. Lock endpoints are only needed for politicians and stances.

### Pattern 6: Auto-Promotion on Approval

**Politicians → `essentials.politicians`:**

The `essentials.politicians` table has many more columns than `staging.politicians`. Promotion maps only the fields that exist in both:

| staging.politicians | essentials.politicians | Notes |
|---------------------|------------------------|-------|
| `external_id` (text) | `external_id` (bigint) | Type mismatch — try `CAST(external_id AS bigint)` or skip if non-numeric |
| `full_name` | `full_name` | Direct |
| `party` | `party` | Direct |
| `bio_text` | `bio_text` | Direct |
| `photo_url` | `photo_origin_url` | Name difference |
| `is_appointed` | `is_appointed` | Direct |
| `is_vacant` | `is_vacant` | Direct |
| `valid_from` | `valid_from` | Direct |
| `valid_to` | `valid_to` | Direct |
| `total_years_in_office` | `total_years_in_office` | bigint in both |

Key constraint: `essentials.politicians.is_active NOT NULL DEFAULT true` and `is_incumbent NOT NULL DEFAULT true` — these must be provided on INSERT.

Upsert key: `essentials.politicians` has no natural unique constraint from this inspection. The planner should verify whether upsert should be on `external_id` (nullable bigint) or treat every approval as an INSERT. If `external_id` is null in staging, insert as new.

**Stances → `inform.politician_answers`:**

`inform.politician_answers` columns: `politician_id` (uuid NOT NULL), `topic_id` (uuid NOT NULL), `value` (integer NOT NULL).

`staging.stances` has `topic_key` (text) and `topic_id` (uuid, nullable). Resolution logic:
1. If `topic_id` is non-null → use directly
2. If `topic_id` is null → query `inform.compass_topics` by... **there is no `topic_key` column on `inform.compass_topics`**. The compass_topics table has `id`, `title`, `short_title`, `question_text` — no `topic_key`. Resolution from `topic_key` to `topic_id` has no clear mapping path in the current schema.

**This is an open question the planner must address** — see Open Questions section.

`staging.stances` also has `politician_external_id` (text, not a UUID). To look up `inform.politician_answers.politician_id`, the promotion logic needs to resolve `politician_external_id` → `essentials.politicians.id` or else get the `politician_id` from a staging politicians record.

**Building Photos → `essentials.building_photos`:**

| staging.building_photos | essentials.building_photos | Notes |
|-------------------------|---------------------------|-------|
| `place_geoid` (text) | `place_geoid` (varchar, NOT NULL) | Upsert key |
| `url` (text) | `url` (text) | Direct |
| `source_url` (text) | `source_url` (text) | Direct |
| `license` (text) | `license` (text) | Direct |
| `attribution` (text) | `attribution` (text) | Direct |
| — | `wiki_title` | essentials-only, skip |
| — | `fetched_at` | essentials-only, skip |

Upsert on `place_geoid`. This is straightforward and can be implemented in this phase.

### Pattern 7: Merge Endpoint for Politicians

`POST /api/staging/politicians/:id/merge` with body `{ target_id: string }`:
1. Verify `id` is `pending` (merge is a special form of rejection)
2. Verify `target_id` exists in staging.politicians
3. UPDATE staging.politicians SET `merged_to_id = target_id`, `status = 'rejected'` WHERE id = id
4. Insert a `politician_review_logs` row with `action = 'merged'`
5. No auto-promotion (source is rejected, not approved)

### Anti-Patterns to Avoid

- **DO NOT use `supabaseAdmin.schema('staging')` or PostgREST for staging** — `staging` is not in the exposed schema list. Runtime failure guaranteed.
- **DO NOT trust `added_by` or `reviewer_name` from request body** — always overwrite with server-derived display_name from `public.users`.
- **DO NOT block review actions on lock state** — locks are courtesy signals; approve/reject must always proceed regardless of `locked_by`.
- **DO NOT use nested SECURITY DEFINER calls for auto-promotion** — inline the essentials upsert directly in the service function (v1.4 pattern).
- **DO NOT spread DB rows into responses** — map to explicit camelCase objects.
- **DO NOT use `supabaseAdmin` in route files** — architecture test enforces this.

---

## Schema Inventory

### `staging.politicians`
| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| `id` | uuid | NO | gen_random_uuid() |
| `external_id` | text | YES | — |
| `full_name` | text | NO | — |
| `party` | text | YES | — |
| `office` | text | YES | — |
| `office_level` | text | YES | — |
| `state` | text | YES | — |
| `district` | text | YES | — |
| `status` | text | YES | 'draft' |
| `added_by` | text | NO | — |
| `reviewed_by` | text | YES | — |
| `merged_to_id` | uuid | YES | — |
| `bio_text` | text | YES | — |
| `photo_url` | text | YES | — |
| `contacts` | jsonb | YES | '[]' |
| `degrees` | jsonb | YES | '[]' |
| `experiences` | jsonb | YES | '[]' |
| `review_count` | bigint | YES | 0 |
| `last_reviewed_at` | timestamptz | YES | — |
| `locked_by` | text | YES | — |
| `locked_at` | timestamptz | YES | — |
| `approved_at` | timestamptz | YES | — |
| `urls` | jsonb | YES | '[]' |
| `web_form_url` | text | YES | — |
| `images` | jsonb | YES | '[]' |
| `addresses` | jsonb | YES | '[]' |
| `valid_from` | text | YES | — |
| `valid_to` | text | YES | — |
| `total_years_in_office` | bigint | YES | — |
| `office_description` | text | YES | — |
| `office_seats` | bigint | YES | — |
| `partisan_type` | text | YES | — |
| `salary` | text | YES | — |
| `normalized_position_name` | text | YES | — |
| `district_type` | text | YES | — |
| `district_ocd_id` | text | YES | — |
| `district_geo_id` | text | YES | — |
| `chamber_name` | text | YES | — |
| `term_limit` | text | YES | — |
| `term_length` | text | YES | — |
| `election_frequency` | text | YES | — |
| `is_appointed` | boolean | YES | — |
| `is_vacant` | boolean | YES | — |
| `created_at` | timestamptz | YES | — |
| `updated_at` | timestamptz | YES | — |

### `staging.politician_review_logs`
| Column | Type | Nullable |
|--------|------|----------|
| `id` | uuid | NO |
| `politician_id` | uuid | NO |
| `reviewer_name` | text | NO |
| `action` | text | NO |
| `comment` | text | YES |
| `created_at` | timestamptz | YES |

### `staging.stances`
| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| `id` | uuid | NO | gen_random_uuid() |
| `context_key` | text | NO | — |
| `politician_external_id` | text | YES | — |
| `politician_name` | text | NO | — |
| `topic_key` | text | NO | — |
| `topic_id` | uuid | YES | — |
| `value` | bigint | NO | — |
| `reasoning` | text | YES | — |
| `sources` | ARRAY | YES | — |
| `status` | text | YES | 'draft' |
| `added_by` | text | NO | — |
| `review_count` | bigint | YES | 0 |
| `reviewed_by` | ARRAY | YES | — |
| `last_reviewed_at` | timestamptz | YES | — |
| `locked_by` | text | YES | — |
| `locked_at` | timestamptz | YES | — |
| `approved_to_answer_id` | text | YES | — |
| `approved_at` | timestamptz | YES | — |
| `created_at` | timestamptz | YES | — |
| `updated_at` | timestamptz | YES | — |

### `staging.review_logs` (for stances)
| Column | Type | Nullable |
|--------|------|----------|
| `id` | uuid | NO |
| `stance_id` | uuid | NO |
| `reviewer_name` | text | NO |
| `action` | text | NO |
| `previous_value` | bigint | YES |
| `new_value` | bigint | YES |
| `comment` | text | YES |
| `created_at` | timestamptz | YES |

### `staging.building_photos`
| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| `id` | uuid | NO | gen_random_uuid() |
| `place_geoid` | text | NO | — |
| `place_name` | text | NO | — |
| `state` | text | YES | — |
| `url` | text | NO | — |
| `source_url` | text | YES | — |
| `license` | text | NO | — |
| `attribution` | text | NO | — |
| `status` | text | YES | 'draft' |
| `added_by` | text | NO | — |
| `review_count` | bigint | YES | 0 |
| `reviewed_by` | ARRAY | YES | — |
| `last_reviewed_at` | timestamptz | YES | — |
| `approved_at` | timestamptz | YES | — |
| `created_at` | timestamptz | YES | — |
| `updated_at` | timestamptz | YES | — |

**Note:** `building_photos` has NO `locked_by`/`locked_at` columns. Lock endpoints not applicable.

### `staging.building_photo_review_logs`
| Column | Type | Nullable |
|--------|------|----------|
| `id` | uuid | NO |
| `building_photo_id` | uuid | NO |
| `reviewer_name` | text | NO |
| `action` | text | NO |
| `comment` | text | YES |
| `created_at` | timestamptz | YES |

---

## Required Migrations

Two migrations are needed before service/route code can work correctly.

### Migration A: Seed `staging_reviewer` role

```sql
INSERT INTO public.roles (name, slug, is_active, required_tier)
VALUES ('Staging Reviewer', 'staging_reviewer', true, 'connected')
ON CONFLICT (slug) DO NOTHING;
```

**Note:** The `required_tier` for `staging_reviewer` needs a planner decision. Setting `'connected'` matches the minimum tier that can hold roles (per roleService.ts comment: "Only Connected+ users can hold roles"). The planner may decide on `'empowered'` instead.

### Migration B: Normalize status defaults and existing rows

The current default on all three staging tables is `'draft'`. Existing rows have statuses `pending`, `needs_review`, and `draft`. The locked state machine is `pending | approved | rejected`.

Options:
1. **Migrate existing rows**: UPDATE rows with status `'needs_review'` → `'pending'`, `'draft'` → `'pending'`. Change defaults to `'pending'`. Add CHECK constraint.
2. **Accept mixed statuses**: Only enforce the state machine at the API layer (no DB constraint), and treat any non-`pending` status as effectively terminal for review purposes. The service layer's `assertTransitionAllowed` handles this.

**Recommendation:** Option 2 is safer. The existing `draft` and `needs_review` rows are legacy Go-server data. The service layer rejecting transitions from non-`pending` statuses is sufficient. Do NOT add a CHECK constraint without auditing all existing rows. New INSERT via the Express API should default to `'pending'`.

The migration should:
1. Set `DEFAULT 'pending'` on `staging.politicians.status`, `staging.stances.status`, `staging.building_photos.status`
2. No row updates (legacy statuses are tolerated)
3. No CHECK constraint (avoids breaking existing rows)

---

## Proposed Route Inventory (~15 routes)

All routes require `requireAuth + requireStagingReviewer`. No public or unauthenticated access.

### Politicians (~7 routes)
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/staging/politicians` | List politicians (with `?status=` filter) |
| GET | `/api/staging/politicians/:id` | Single politician |
| POST | `/api/staging/politicians` | Submit new politician |
| PATCH | `/api/staging/politicians/:id` | Update politician (pending only) |
| POST | `/api/staging/politicians/:id/review` | Approve or reject (body: `{ action, comment? }`) |
| POST | `/api/staging/politicians/:id/lock` | Acquire lock |
| DELETE | `/api/staging/politicians/:id/lock` | Release lock |
| POST | `/api/staging/politicians/:id/merge` | Merge into another politician (sets merged_to_id, rejects source) |

### Stances (~6 routes)
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/staging/stances` | List stances (with `?status=` filter) |
| GET | `/api/staging/stances/:id` | Single stance |
| POST | `/api/staging/stances` | Submit new stance |
| PATCH | `/api/staging/stances/:id` | Update stance (pending only) |
| POST | `/api/staging/stances/:id/review` | Approve or reject |
| POST | `/api/staging/stances/:id/lock` | Acquire lock |
| DELETE | `/api/staging/stances/:id/lock` | Release lock |

### Building Photos (~4 routes)
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/staging/photos` | List photos (with `?status=` filter) |
| GET | `/api/staging/photos/:id` | Single photo |
| POST | `/api/staging/photos` | Submit new photo |
| POST | `/api/staging/photos/:id/review` | Approve or reject |

**Route ordering note (established in Phase 36):** Subpath routes (`:id/review`, `:id/lock`) MUST be defined BEFORE `/:id` in the router to prevent Express routing conflicts. Concrete routes before parametric.

**Total: ~18 routes** (slightly over the "~15" estimate in requirements — review/lock subpath routes add up).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Role check query | Custom auth wrapper | Direct pool.query() in requireStagingReviewer.ts | get_user_roles RPC returns JSON; direct SQL join is simpler |
| Status transition validation | DB CHECK constraint | Service-layer assertion function | Existing rows have non-standard statuses; DB constraint would block |
| display_name resolution | Trust request body | pool.query on public.users | CONTEXT.md requirement — never trust client for authorship fields |
| Lock expiry | Auto-expiry cron | Explicit reviewer release only | Decided in CONTEXT.md; no-expiry is intentional |
| JSONB field validation | Server-side schema parse | Pass-through after JSON parse | contacts, degrees, experiences, urls, images, addresses — trust reviewer |

**Key insight:** The staging workflow is data-entry tooling for trusted reviewers. Strict validation is intentionally light on JSONB fields (reviewers are privileged) but strict on authorship fields (never trust client).

---

## Common Pitfalls

### Pitfall 1: staging schema not in PostgREST exposed list

**What goes wrong:** `supabaseAdmin.schema('staging').from('politicians').select()` returns empty or throws "schema not found."
**Why it happens:** PostgREST exposed schemas: `public, connect, empower, inform, graphql_public, validation_quests`. `staging` is absent.
**How to avoid:** All staging queries via `pool.query()`. Comment every service function: `// Uses pool.query() — staging not exposed via PostgREST.`
**Warning signs:** Queries return empty arrays; no error thrown.

### Pitfall 2: `added_by` / `reviewer_name` from request body

**What goes wrong:** A malicious reviewer sets `added_by: 'admin'` in the POST body, bypassing authorship attribution.
**Why it happens:** Forgetting to strip/override authorship fields before INSERT.
**How to avoid:** Always derive `added_by` from `getDisplayName(req.userId)` in the service function. Zod schema should NOT include `added_by` or `reviewer_name` — strip them at parse time.
**Warning signs:** `added_by` in DB doesn't match the authenticated user's display name.

### Pitfall 3: display_name lookup returns null

**What goes wrong:** `public.users.display_name` is nullable. If null, the NOT NULL constraint on `staging.politicians.added_by` causes an INSERT error.
**Why it happens:** Some users may not have set a display name (Inform tier users have no display_name_draft).
**How to avoid:** Use fallback: `display_name ?? userId` (UUID as last resort). This preserves NOT NULL and provides traceability.
**Warning signs:** INSERT fails with "null value in column 'added_by' violates not-null constraint."

### Pitfall 4: Lock acquire race condition

**What goes wrong:** Two reviewers check `locked_by IS NULL` simultaneously, both see no lock, both INSERT a lock. Both get 200 OK.
**Why it happens:** Non-atomic read-then-write.
**How to avoid:** Use a single atomic UPDATE with RETURNING:
```sql
UPDATE staging.politicians
SET locked_by = $1, locked_at = NOW()
WHERE id = $2 AND locked_by IS NULL
RETURNING id;
```
If no rows returned, someone else acquired the lock first — then fetch current lock holder for 409 response.
**Warning signs:** Two reviewers both think they hold the lock simultaneously.

### Pitfall 5: Review action on terminal status

**What goes wrong:** Re-approving an already-approved politician triggers a second promotion INSERT into essentials, potentially creating duplicate records.
**Why it happens:** Missing status check before review action.
**How to avoid:** Service function checks `current.status !== 'pending'` before proceeding. Return `{ code: 'STATUS_TERMINAL' }` 422.
**Warning signs:** Duplicate rows appear in essentials.politicians.

### Pitfall 6: topic_key has no lookup target in inform schema

**What goes wrong:** Stance approval tries to resolve `topic_key` → `inform.compass_topics` but `compass_topics` has no `topic_key` column (only `id`, `title`, `short_title`, `question_text`).
**Why it happens:** `topic_key` was a Go-era text identifier that doesn't map 1:1 to compass topic titles/IDs.
**How to avoid:** If `topic_id` is already set on the stance, use it directly. If `topic_id` is null and `topic_key` cannot be resolved, either: (a) skip inform.politician_answers promotion and log a warning, or (b) require `topic_id` to be non-null for stance approval (add validation check). Planner must decide.
**Warning signs:** Stance approval succeeds in DB but no `inform.politician_answers` row is created.

### Pitfall 7: Express route ordering — subpath before /:id

**What goes wrong:** `GET /api/staging/politicians/review` is matched by `/:id` handler (treating "review" as an ID string), failing UUID validation or returning 404.
**Why it happens:** Express matches routes in registration order. `:id` captures all single-segment paths.
**How to avoid:** Always register `/:id/review`, `/:id/lock` BEFORE `/:id`. Established pattern from Phase 36 (meetings.ts).
**Warning signs:** `POST /api/staging/politicians/:id/review` returns 422 "Invalid UUID format" because "review" fails UUID regex.

### Pitfall 8: bigint columns return as strings from pg driver

**What goes wrong:** `review_count` appears as `"5"` (string) in API response instead of `5` (number).
**Why it happens:** The `pg` Node.js driver serializes PostgreSQL `bigint` as JavaScript string by default.
**How to avoid:** Always call `Number(row.review_count)` in row mapper. Pattern established in meetingsService.ts.
**Warning signs:** Frontend receives `"0"` instead of `0` for review_count.

---

## Migration Checklist

Before writing service/route code, these migrations must be applied:

1. **Seed `staging_reviewer` role** in `public.roles` (planner decides `required_tier`)
2. **Change status column defaults** from `'draft'` to `'pending'` on all three staging tables
3. Optional: UPDATE legacy rows `needs_review` → `pending`, `draft` → `pending` (if desired for consistency; not strictly required)

---

## Open Questions

1. **topic_key → topic_id resolution for stance approval**
   - What we know: `staging.stances.topic_key` is a text field. `inform.compass_topics` has no `topic_key` column — it has `id`, `title`, `short_title`, `question_text`.
   - What's unclear: Is `topic_key` intended to match `short_title`? Or is it a legacy key that only the Go server could resolve?
   - Recommendation: Require `topic_id` to be non-null for stance approval (enforce at service layer). If `topic_id` is null, return a 422 with `{ code: 'TOPIC_UNRESOLVED', message: 'topic_id must be set before approval' }`. The reviewer can supply `topic_id` via a PATCH before approving.

2. **Politician `external_id` type mismatch: staging (text) vs essentials (bigint)**
   - What we know: `staging.politicians.external_id` is `text`. `essentials.politicians.external_id` is `bigint`.
   - What's unclear: Are staging external_ids always numeric strings? Or can they be non-numeric legacy IDs?
   - Recommendation: Use `TRY_CAST` in the promotion SQL: `NULLIF(REGEXP_REPLACE(external_id, '[^0-9]', '', 'g'), '')::bigint` or simply skip `external_id` on essentials upsert if staging value is non-numeric. Log a warning.

3. **Politician upsert key in essentials**
   - What we know: `essentials.politicians` has no unique constraint visible from information_schema. The primary key is `id` (uuid).
   - What's unclear: Should promotion upsert on `external_id` (if set) or always INSERT as new?
   - Recommendation: If `staging.politician.external_id` maps to a known `essentials.politicians.external_id`, upsert. Otherwise INSERT new. If the essentials politician already exists (found by external_id), UPDATE in place. If `external_id` is null in staging, always INSERT new.

4. **`staging_reviewer` required_tier**
   - What we know: `required_tier` on existing active roles: `maven = empowered`, `candidate = null`, `contributor = null`.
   - What's unclear: Should staging reviewers need to be Empowered tier or just Connected?
   - Recommendation: `required_tier = 'connected'` (same as minimum role-holding tier). Staging is a privileged workflow but doesn't necessarily require full Empowered verification.

5. **Building photo promotion: implement or just mark approved_at?**
   - What we know: `essentials.building_photos` exists and has matching core fields. Upsert on `place_geoid` is feasible.
   - What's unclear: Is the promotion into essentials wanted now, or is `approved_at` marking sufficient?
   - Recommendation: Implement the upsert (it's 5 fields, trivial). This completes the workflow cleanly and makes `essentials.building_photos` useful.

6. **review_count increment: every action or only approve/reject?**
   - CONTEXT.md marks this as "Claude's Discretion."
   - Recommendation: Increment only on `approved` and `rejected` actions (the terminal transitions). Acquiring/releasing a lock or updating the record should not increment review_count.

---

## Sources

### Primary (HIGH confidence)
- Production DB via `mcp__supabase-local__execute_sql` — exact column definitions for all 6 staging tables, essentials.politicians, essentials.building_photos, inform.politician_answers, inform.compass_topics
- `backend/src/lib/meetingsService.ts` — canonical pool.query() service pattern (Phase 36)
- `backend/src/routes/meetings.ts` — canonical route pattern with subpath ordering, UUID validation, Zod (Phase 36)
- `backend/src/routes/admin.ts` — `router.use(requireAuth, requireAdmin)` pattern
- `backend/src/middleware/requireAdmin.ts` — middleware implementation pattern
- `backend/src/middleware/auth.ts` — AuthenticatedRequest interface, requireAuth
- `backend/src/lib/roleService.ts` — get_user_roles RPC, user_roles/roles join pattern
- `backend/src/lib/supabase.ts` — pool.query() vs supabaseAdmin distinction
- `backend/src/index.ts` — route registration pattern
- Production DB: `auth.users` row — confirmed display_name NOT in JWT payload (only in public.users)
- Production DB: `public.roles` rows — confirmed `staging_reviewer` does not exist yet
- Production DB: staging rows sample — confirmed existing statuses: `pending`, `needs_review`, `draft`
- `supabase/migrations/20260319000049_phase34_staging_rls.sql` — RLS policies, confirmed NO INSERT/UPDATE/DELETE policies (all writes via service role / pool)

### Secondary (MEDIUM confidence)
- `.planning/phases/37-express-ports-wave-2-staging/37-CONTEXT.md` — locked decisions
- `.planning/phases/36-express-ports-wave-1/36-RESEARCH.md` — established pool.query() + service + route pattern documentation

### Tertiary (LOW confidence)
- None — all findings from direct codebase and DB inspection.

---

## Metadata

**Confidence breakdown:**
- Staging schema (columns, types, existing data): HIGH — queried production DB directly
- essentials promotion targets (columns, feasibility): HIGH — queried production DB directly
- pool.query() / middleware patterns: HIGH — verified in Phase 36 shipped code
- Route structure / ordering: HIGH — verified in meetings.ts
- display_name from JWT: HIGH (confirmed NOT in JWT — DB lookup required)
- topic_key resolution: LOW — no clear resolution path found; open question for planner
- Politician upsert key: MEDIUM — no visible unique constraint on essentials.politicians external_id; needs planner decision

**Research date:** 2026-03-20
**Valid until:** 2026-04-19 (stable domain — schema doesn't change post Phase 34)
