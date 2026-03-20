# Phase 36: Express Ports Wave 1 — Treasury and Meetings - Research

**Researched:** 2026-03-19
**Domain:** Express route + service layer construction against non-public Postgres schemas
**Confidence:** HIGH

---

## Summary

Phase 36 builds two families of Express routes — `/api/treasury/...` and `/api/meetings/...` — reading from Supabase schemas that were migrated and RLS-protected in Phase 34. Both schemas are currently empty (0 rows) but structurally complete and grant-ready. This is a **greenfield build from schema**, not a port — Go routes are dormant with no active consumers and carry no binding contract.

The implementation pattern is fully established in the existing codebase. The correct model is: route file (`src/routes/`) → service file (`src/lib/`) → `pool.query()`. Treasury and meetings schemas are not in PostgREST's exposed schema list, so `supabaseAdmin.schema('treasury')` or `supabaseAdmin.schema('meetings')` would fail at runtime — every query must go through `pool.query()` directly. This is the same constraint confirmed for the `essentials` schema in Phase 35.

Authentication follows the established pattern: public (no middleware) for all reads, `requireAuth + requireAdmin` for all admin writes on both schemas. The meetings schema also has user-action routes (if RSVP / agenda items are needed in this phase) that require `requireAuth + requireConnected`. However, since both schemas are empty and no frontend consumers exist, the CONTEXT.md decisions scope the user-action routes as optional — they depend on the data model having first-class RSVP and agenda-item tables, which are NOT present in the current meetings schema (Phase 34 found no user-linked tables in meetings at all). RSVP and agenda functionality would require new tables; those are out of scope.

**Primary recommendation:** Build treasury and meetings as pure public-read + admin-write services using the `essentialsPoliticians` / `adminService` pattern exactly: `pool.query()` in service files, no supabaseAdmin in route files, camelCase response objects built from explicit field whitelists.

---

## Standard Stack

No new libraries needed. All tools already present in the codebase.

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| `pg` (pool) | existing | All non-public schema queries | Only client that can query treasury/meetings schemas reliably |
| Express Router | existing | Route file structure | All 22 existing route files use this pattern |
| `zod` | existing | Request body validation on admin write routes | Used in admin.ts, vq.ts, connect.ts |
| TypeScript | existing | Type-safe row types in service files | All service files define typed row interfaces |

### No New Libraries
Treasury and meetings routes follow the exact same pattern as `essentialsPoliticians.ts` + `adminService.ts`. No new dependencies are needed.

**Installation:** None required.

---

## Architecture Patterns

### Recommended File Structure

```
backend/src/
├── routes/
│   ├── treasury.ts         # /api/treasury/* route handlers
│   └── meetings.ts         # /api/meetings/* route handlers
└── lib/
    ├── treasuryService.ts  # pool.query() wrappers for treasury schema
    └── meetingsService.ts  # pool.query() wrappers for meetings schema
```

Register in `backend/src/index.ts`:
```typescript
import treasuryRouter from './routes/treasury.js';
import meetingsRouter from './routes/meetings.js';
// ...
app.use('/api/treasury', treasuryRouter);
app.use('/api/meetings', meetingsRouter);
```

### Pattern 1: Public Read Route (from essentialsPoliticians.ts)

```typescript
// Source: backend/src/routes/essentialsPoliticians.ts
import { Router } from 'express';
import { optionalAuth } from '../middleware/auth.js';
import { getCities } from '../lib/treasuryService.js';
import type { Request, Response } from 'express';

const router = Router();

router.get('/cities', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const data = await getCities();
    res.status(200).json(data);
  } catch (err) {
    console.error('[GET /treasury/cities] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});
```

### Pattern 2: Admin Write Route (from admin.ts + adminService.ts)

```typescript
// Source: backend/src/routes/admin.ts (router.use pattern)
import { requireAuth } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';

// Option A: Apply to all routes via router.use (admin-only route file)
router.use(requireAuth as any, requireAdmin as any);

// Option B: Per-route (mixed auth levels in same file)
router.post('/meetings', requireAuth, requireAdmin, async (req, res) => { ... });
```

For treasury (all writes are admin) and meetings management writes (admin), the `router.use(requireAuth, requireAdmin)` pattern is cleaner. For meetings user actions (RSVP, agenda), per-route middleware is needed since reads are public. However, **RSVP and agenda-item tables do not exist in the current meetings schema** — no user-action routes should be built in this phase.

### Pattern 3: pool.query() Service Function (from essentialsService.ts + adminService.ts)

```typescript
// Source: backend/src/lib/essentialsService.ts
import { pool } from './db.js';

export interface CityRecord {
  id: string;
  name: string;
  state: string;
  population: number | null;
  createdAt: string | null;
}

export async function getCities(): Promise<CityRecord[]> {
  // Uses pool.query() — treasury schema is not exposed via PostgREST.
  const { rows } = await pool.query<{
    id: string;
    name: string;
    state: string;
    population: number | null;
    created_at: string | null;
  }>(`SELECT id, name, state, population, created_at FROM treasury.cities ORDER BY state, name`);

  return rows.map(row => ({
    id: row.id,
    name: row.name,
    state: row.state,
    population: row.population,
    createdAt: row.created_at,
  }));
}
```

**Critical discipline:** DB rows are NEVER spread into responses. Build an explicit camelCase object from each row. This is enforced in essentialsService.ts and must be followed here.

### Pattern 4: Admin Write with pool.query() (from adminService.ts)

```typescript
// Source: backend/src/lib/adminService.ts (adminCreatePolitician, adminSetPoliticianContext)
export async function createMeeting(data: {
  city: string;
  state: string;
  date: string;
  meetingType?: string;
}): Promise<MeetingRecord> {
  const { rows } = await pool.query<{ id: string; city: string; ... }>(
    `INSERT INTO meetings.meetings (city, state, date, meeting_type)
     VALUES ($1, $2, $3, $4)
     RETURNING *`,
    [data.city, data.state, data.date, data.meetingType ?? 'Regular Session']
  );
  if (rows.length === 0) throw new Error('Insert failed');
  return mapMeetingRow(rows[0]);
}
```

### Pattern 5: 404 handling for single-resource routes

```typescript
// Source: backend/src/routes/candidates.ts
const result = await getMeetingById(id);
if (result === null) {
  res.status(404).json({ code: 'NOT_FOUND', message: 'Meeting not found' });
  return;
}
res.status(200).json(result);
```

Service functions return `null` (not throw) for not-found cases. Route handler checks for null and returns 404.

### Pattern 6: Zod validation for admin writes

```typescript
// Source: backend/src/routes/admin.ts, vq.ts
import { z } from 'zod';

const CreateMeetingSchema = z.object({
  city: z.string().min(1),
  state: z.string().length(2),
  date: z.string().datetime(),
  meetingType: z.string().optional(),
  videoUrl: z.string().url().optional(),
});

router.post('/', requireAuth, requireAdmin, async (req, res) => {
  const parsed = CreateMeetingSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({ code: 'VALIDATION_ERROR', issues: parsed.error.issues });
    return;
  }
  // ...
});
```

### Anti-Patterns to Avoid

- **DO NOT use `supabaseAdmin.schema('treasury')` or `.schema('meetings')`** — these schemas are not in PostgREST's exposed list; queries will fail at runtime with "schema not found" or empty results.
- **DO NOT spread DB rows into responses** — build explicit camelCase objects from every row.
- **DO NOT reference `supabaseAdmin` directly in route files** — architecture test enforces this; only service files in `src/lib/` may use it (and for treasury/meetings, pool.query() is used instead anyway).
- **DO NOT omit `optionalAuth` on public reads** — consistent with the rest of the codebase; allows future authenticated behavior without a breaking change.
- **DO NOT build RSVP or agenda-item routes** — no corresponding tables exist in the meetings schema (see schema inventory below). Those would require new table migrations first.

---

## Treasury Schema: Complete Table Inventory

### `treasury.cities`
| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `id` | uuid | NO | gen_random_uuid() | PK |
| `name` | text | NO | — | City name |
| `state` | text | NO | — | 2-char state code |
| `population` | bigint | YES | — | |
| `created_at` | timestamptz | YES | — | |
| `updated_at` | timestamptz | YES | — | |

**FK:** none (root table, referenced by `budgets.city_id`)

### `treasury.budgets`
| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `id` | uuid | NO | gen_random_uuid() | PK |
| `city_id` | uuid | NO | — | FK → cities.id |
| `fiscal_year` | bigint | NO | — | e.g. 2024 |
| `dataset_type` | text | NO | 'operating' | 'operating', 'capital', etc. |
| `total_budget` | numeric | NO | — | Total budget amount |
| `data_source` | text | YES | — | Source URL or description |
| `hierarchy` | ARRAY | YES | — | Postgres array (text[]) |
| `generated_at` | timestamptz | YES | — | When data was generated |
| `created_at` | timestamptz | YES | — | |
| `updated_at` | timestamptz | YES | — | |

**FK:** `city_id` → `treasury.cities.id`

### `treasury.budget_categories`
| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `id` | uuid | NO | gen_random_uuid() | PK |
| `budget_id` | uuid | NO | — | FK → budgets.id |
| `parent_id` | uuid | YES | — | FK → budget_categories.id (self-referential) |
| `name` | text | NO | — | Category name |
| `amount` | numeric | NO | — | Dollar amount |
| `percentage` | numeric | YES | — | Percentage of total |
| `color` | text | YES | — | UI display color |
| `description` | text | YES | — | |
| `why_matters` | text | YES | — | Human-readable context |
| `historical_change` | numeric | YES | — | YoY change |
| `item_count` | bigint | YES | 0 | Line item count |
| `sort_order` | bigint | YES | 0 | Display ordering |
| `depth` | bigint | YES | 0 | Tree depth (0=top-level) |
| `link_key` | text | YES | — | Cross-reference key |

**FK:** `budget_id` → `treasury.budgets.id`, `parent_id` → `treasury.budget_categories.id` (self-ref)

### `treasury.budget_line_items`
| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `id` | uuid | NO | gen_random_uuid() | PK |
| `category_id` | uuid | NO | — | FK → budget_categories.id |
| `description` | text | NO | — | Item description |
| `approved_amount` | numeric | YES | — | Approved budget |
| `actual_amount` | numeric | YES | — | Actual spend |
| `base_pay` | numeric | YES | — | Personnel base pay |
| `benefits` | numeric | YES | — | Personnel benefits |
| `overtime` | numeric | YES | — | Personnel overtime |
| `other` | numeric | YES | — | Other costs |
| `start_date` | text | YES | — | text (not date) |
| `vendor` | text | YES | — | Vendor name |
| `date` | text | YES | — | text (not date) |
| `payment_method` | text | YES | — | |
| `invoice_number` | text | YES | — | |
| `fund` | text | YES | — | Fund code/name |
| `expense_category` | text | YES | — | Category label |

**FK:** `category_id` → `treasury.budget_categories.id`

**Relationship summary:**
```
cities (1) → budgets (many) → budget_categories (tree, many) → budget_line_items (many)
```
The `budget_categories` table is self-referential via `parent_id` — hierarchical tree structure.

---

## Meetings Schema: Complete Table Inventory

### `meetings.meetings`
| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `id` | uuid | NO | gen_random_uuid() | PK |
| `city` | text | NO | — | City name |
| `state` | text | NO | — | 2-char state code |
| `date` | timestamptz | NO | — | Meeting datetime |
| `meeting_type` | text | NO | 'Regular Session' | e.g. 'Regular Session', 'Special Session' |
| `duration_seconds` | numeric | YES | — | |
| `video_url` | text | YES | — | YouTube/stream URL |
| `audio_source` | text | YES | — | Audio source identifier |
| `status` | text | NO | 'processing' | 'processing', 'complete', etc. |
| `segment_count` | bigint | YES | — | Denormalized count |
| `speaker_count` | bigint | YES | — | Denormalized count |
| `created_at` | timestamptz | YES | — | |
| `updated_at` | timestamptz | YES | — | |

### `meetings.speakers`
| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `id` | uuid | NO | gen_random_uuid() | PK |
| `meeting_id` | uuid | NO | — | FK → meetings.id |
| `label` | text | NO | — | Speaker label (e.g. "SPEAKER_00") |
| `display_name` | text | YES | — | Human-readable name |
| `confidence` | numeric | YES | — | Speaker ID confidence (0–1) |
| `id_method` | text | YES | — | Identification method used |
| `politician_id` | uuid | YES | — | FK → (no FK constraint to essentials) |
| `created_at` | timestamptz | YES | — | |

**Note:** `politician_id` has no FK constraint to any politician table. It likely stores essentials.politicians UUIDs but the constraint was not created in Go's schema.

### `meetings.segments`
| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `id` | uuid | NO | gen_random_uuid() | PK |
| `meeting_id` | uuid | NO | — | FK → meetings.id |
| `speaker_id` | uuid | NO | — | FK → speakers.id |
| `segment_index` | bigint | NO | — | Ordering within meeting |
| `start_time` | numeric | NO | — | Seconds from start |
| `end_time` | numeric | NO | — | Seconds from start |
| `text` | text | NO | — | Transcript text |

### `meetings.meeting_summaries`
| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `id` | uuid | NO | gen_random_uuid() | PK |
| `meeting_id` | uuid | NO | — | FK → meetings.id |
| `summary_type` | text | NO | 'full' | 'full', 'section', etc. |
| `model` | text | YES | — | LLM model used |
| `created_at` | timestamptz | YES | — | |

### `meetings.summary_sections`
| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `id` | uuid | NO | gen_random_uuid() | PK |
| `summary_id` | uuid | NO | — | FK → meeting_summaries.id |
| `section_type` | text | NO | — | Section type identifier |
| `title` | text | NO | — | Section title |
| `content` | text | NO | — | Section text content |
| `start_time` | numeric | YES | — | Timestamp reference |
| `end_time` | numeric | YES | — | Timestamp reference |
| `sort_order` | bigint | YES | 0 | Display ordering |

### `meetings.votes`
| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `id` | uuid | NO | gen_random_uuid() | PK |
| `meeting_id` | uuid | NO | — | FK → meetings.id |
| `resolution` | text | YES | — | Resolution/motion text |
| `description` | text | YES | — | Description |
| `result` | text | NO | — | 'passed', 'failed', 'withdrawn', etc. |
| `vote_type` | text | YES | — | Type of vote |
| `timestamp` | numeric | YES | — | Seconds from meeting start |
| `created_at` | timestamptz | YES | — | |

### `meetings.vote_records`
| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `id` | uuid | NO | gen_random_uuid() | PK |
| `vote_id` | uuid | NO | — | FK → votes.id |
| `speaker_id` | uuid | NO | — | FK → speakers.id |
| `position` | text | NO | — | 'yes', 'no', 'abstain', 'absent' |

**Relationship summary:**
```
meetings (1) → speakers (many)
meetings (1) → segments (many) — each segment belongs to one speaker
meetings (1) → votes (many) → vote_records (many) — each record is one speaker's vote
meetings (1) → meeting_summaries (many) → summary_sections (many)
```

**Critical finding:** No user-linked tables in meetings schema. No RSVP table. No agenda_items table. The schema is purely AI-generated civic record data (CouncilScribe pipeline). User-action routes (RSVP, agenda items) referenced in CONTEXT.md are **not implementable from the current schema** — they would require new table migrations. This phase implements read + admin write routes only.

---

## Proposed Route Inventories

### Treasury Routes (~5 routes, all public read + admin writes)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/treasury/cities` | public | List all cities with budget data |
| GET | `/api/treasury/cities/:id` | public | Single city by ID |
| GET | `/api/treasury/cities/:id/budgets` | public | All budgets for a city (with ?fiscal_year= filter) |
| GET | `/api/treasury/budgets/:id` | public | Single budget with nested categories |
| GET | `/api/treasury/budgets/:id/line-items` | public | All line items for a budget (flattened across categories) |
| POST | `/api/treasury/cities` | requireAdmin | Create city |
| POST | `/api/treasury/budgets` | requireAdmin | Create budget for a city |
| POST | `/api/treasury/budgets/:id/categories` | requireAdmin | Add category to budget |
| POST | `/api/treasury/budgets/:id/line-items` | requireAdmin | Add line item to budget category |

**Note on CONS-08 scope:** CONS-08 says "~5 routes, read-only public data." The admin writes above exceed that scope. Recommendation: implement the 5 core read routes now; admin writes can be added when there's a frontend that needs them (data is currently empty — no import pipeline exists in this repo). Planner should decide whether to include admin write routes in this phase.

**Priority reads (5 routes):**
1. `GET /api/treasury/cities` — list all cities
2. `GET /api/treasury/cities/:id` — single city
3. `GET /api/treasury/cities/:cityId/budgets` — budgets for a city
4. `GET /api/treasury/budgets/:id` — single budget with categories (the primary data product)
5. `GET /api/treasury/budgets/:id/line-items` — line items for browsing

### Meetings Routes (~8 routes, public read + admin writes)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/meetings` | public | List meetings (with ?city=&state=&status= filters) |
| GET | `/api/meetings/:id` | public | Single meeting with speakers + vote summary |
| GET | `/api/meetings/:id/transcript` | public | Full transcript (segments ordered by index) |
| GET | `/api/meetings/:id/summary` | public | Meeting summary + sections |
| GET | `/api/meetings/:id/votes` | public | All votes in meeting with vote records |
| POST | `/api/meetings` | requireAdmin | Create meeting |
| PATCH | `/api/meetings/:id` | requireAdmin | Update meeting (status, video_url, etc.) |
| DELETE | `/api/meetings/:id` | requireAdmin | Delete meeting |

**Note on user-action routes:** The CONTEXT.md mentions "RSVP, agenda items" as `requireAuth + requireConnected` routes. The current meetings schema has NO tables for RSVP or agenda items. Those routes cannot be built. The 8 routes above match CONS-09's "~8 routes, public read + admin write" scope without user-action routes.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Schema queries | Custom Supabase client wrapper | `pool.query()` directly | Established pattern; PostgREST doesn't expose these schemas |
| camelCase conversion | Generic transform utility | Explicit field mapping in service | Prevents accidental field exposure; each service defines its own whitelist |
| Request validation | Manual type checks | `zod` schemas | Already installed; consistent with admin.ts, vq.ts patterns |
| Error response format | Custom error class | Inline `res.status(N).json({code, message})` | Matches all existing routes exactly |
| Pagination | Custom cursor logic | Simple `LIMIT`/`OFFSET` with `?page=` | All existing list routes use this approach (see adminService.ts `listAccounts`) |

**Key insight:** This is a pattern-following phase, not an innovation phase. Every design decision has a precedent in the existing codebase. Follow the essentialsPoliticians + adminService pattern exactly.

---

## Common Pitfalls

### Pitfall 1: Using supabaseAdmin.schema() for treasury/meetings

**What goes wrong:** Queries return empty results or throw "schema not found" errors, silently breaking the routes.
**Why it happens:** Developers new to the codebase assume supabaseAdmin works for all schemas. PostgREST's exposed schemas list is `public, connect, empower, inform, graphql_public, validation_quests` — treasury and meetings are absent.
**How to avoid:** Use `pool.query()` in every service function. Add a comment: `// Uses pool.query() — treasury/meetings not exposed via PostgREST.`
**Warning signs:** Queries return `[]` or `null` despite data existing in the DB; no SQL error thrown.

### Pitfall 2: Spreading DB rows into responses

**What goes wrong:** snake_case field names leak into API responses (inconsistent with all other ev-accounts routes), and internal fields may be accidentally exposed.
**Why it happens:** `...row` is tempting for speed.
**How to avoid:** Map each DB row to an explicit TypeScript interface with camelCase keys. This is the documented pattern in essentialsService.ts: "All response objects are built from EXPLICIT field whitelists."
**Warning signs:** API responses have `created_at` instead of `createdAt`, or `meeting_type` instead of `meetingType`.

### Pitfall 3: Forgetting to register routes in index.ts

**What goes wrong:** Routes exist as files but return 404 — the router was never mounted.
**Why it happens:** Route files must both be created AND imported+mounted in `backend/src/index.ts`.
**How to avoid:** Always update `index.ts` as part of the same task that creates the route file. Verify with curl smoke test.
**Warning signs:** `curl /api/treasury/cities` returns 404.

### Pitfall 4: Budget categories are a tree, not a flat list

**What goes wrong:** Fetching all categories for a budget returns a flat array when the frontend expects a hierarchical structure (or vice versa).
**Why it happens:** `budget_categories` has a self-referential `parent_id` FK, making it a tree. `depth` (0 = top-level) and `sort_order` columns are provided for client-side rendering.
**How to avoid:** Return the flat array sorted by `depth, sort_order` and let the client reconstruct the tree. Document this in the route comment. The `depth` and `sort_order` columns make client-side tree reconstruction easy without a recursive CTE.
**Warning signs:** Frontend shows all categories at the same level, or categories appear in wrong order.

### Pitfall 5: meetings.segments can be large

**What goes wrong:** `GET /api/meetings/:id/transcript` returns a payload that's 50–500KB for a typical 2-hour meeting at ~1 segment per second. This blocks the response for seconds.
**Why it happens:** Full transcript = all segments = potentially thousands of rows.
**How to avoid:** Paginate transcript segments by default (`?page=` / limit 200). Or treat transcript as a separate endpoint that clients load lazily. The `segment_index` column enables deterministic ordering and offset-based pagination.
**Warning signs:** Transcript endpoint times out or returns very large JSON payloads.

### Pitfall 6: speakers.politician_id has no FK constraint

**What goes wrong:** Code tries to JOIN meetings.speakers to essentials.politicians on politician_id and gets FK constraint errors or silent null joins for unrecognized IDs.
**Why it happens:** The Go schema stored politician UUIDs but never formalized the FK. The constraint does not exist.
**How to avoid:** Do a LEFT JOIN, not INNER JOIN. Accept that politician_id can be null or a stale UUID. Do not add an FK constraint without a data audit first.
**Warning signs:** Speaker records with non-null politician_id failing to join to politicians.

---

## Code Examples

### pool.query() read with explicit field mapping

```typescript
// Source: backend/src/lib/essentialsService.ts (pattern)
import { pool } from './db.js';

export interface CityRecord {
  id: string;
  name: string;
  state: string;
  population: number | null;
  createdAt: string | null;
}

export async function getCities(): Promise<CityRecord[]> {
  // Uses pool.query() — treasury schema is not exposed via PostgREST.
  const { rows } = await pool.query<{
    id: string;
    name: string;
    state: string;
    population: bigint | null;
    created_at: string | null;
  }>(`SELECT id, name, state, population, created_at FROM treasury.cities ORDER BY state, name`);

  return rows.map(row => ({
    id: row.id,
    name: row.name,
    state: row.state,
    population: row.population !== null ? Number(row.population) : null,
    createdAt: row.created_at,
  }));
}
```

**Note on bigint:** `pg` returns `bigint` columns as JavaScript strings by default. Cast to `Number()` explicitly when mapping rows if the value fits in a JS number (bigint populations/counts will).

### pool.query() write (admin INSERT)

```typescript
// Source: backend/src/lib/adminService.ts (adminCreatePolitician pattern)
export async function createCity(data: {
  name: string;
  state: string;
  population?: number;
}): Promise<CityRecord> {
  const { rows } = await pool.query<{
    id: string; name: string; state: string;
    population: bigint | null; created_at: string | null;
  }>(
    `INSERT INTO treasury.cities (name, state, population)
     VALUES ($1, $2, $3)
     RETURNING id, name, state, population, created_at`,
    [data.name, data.state, data.population ?? null]
  );
  if (rows.length === 0) throw new Error('Insert returned no rows');
  const row = rows[0];
  return {
    id: row.id,
    name: row.name,
    state: row.state,
    population: row.population !== null ? Number(row.population) : null,
    createdAt: row.created_at,
  };
}
```

### Route with requireAuth + requireAdmin (non-router.use pattern)

```typescript
// Source: backend/src/routes/connect.ts (requireAuth + requireConnected per-route)
import { requireAuth } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';

// For a file with mixed public reads + admin writes:
router.post('/', requireAuth, requireAdmin, async (req, res) => {
  // ...
});

// For a file where ALL routes are admin (use router.use):
// Source: backend/src/routes/admin.ts
router.use(requireAuth as any, requireAdmin as any);
```

### Registering routes in index.ts

```typescript
// Source: backend/src/index.ts (existing pattern)
import treasuryRouter from './routes/treasury.js';
import meetingsRouter from './routes/meetings.js';
// ...
app.use('/api/treasury', treasuryRouter);
app.use('/api/meetings', meetingsRouter);
```

### Parameterized query with UUID validation

```typescript
// Source: backend/src/routes/candidates.ts (UUID_REGEX pattern)
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

router.get('/:id', optionalAuth, async (req, res) => {
  const { id } = req.params;
  if (!UUID_REGEX.test(id)) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid ID format' });
    return;
  }
  const result = await getMeetingById(id);
  if (result === null) {
    res.status(404).json({ code: 'NOT_FOUND', message: 'Meeting not found' });
    return;
  }
  res.status(200).json(result);
});
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| supabaseAdmin.schema() for all schemas | pool.query() for non-public schemas | Phase 35 (confirmed) | Eliminates silent PostgREST failures for non-exposed schemas |
| Go server as source of truth for treasury/meetings | Supabase schema as source of truth | Phase 36 (this phase) | Response shapes designed from DB columns, not legacy API |
| Spreading DB rows in responses | Explicit field whitelists | v1.0 (established) | Security + consistency |

**Deprecated/outdated:**
- `supabaseAdmin.schema('treasury' | 'meetings').from().select()` — DO NOT use; runtime failure guaranteed.
- Go server treasury/meetings routes — dormant, no consumers, not authoritative.

---

## Open Questions

1. **Admin write routes: in scope for CONS-08/09 or deferred?**
   - What we know: CONS-08 says "~5 routes, read-only public data." CONS-09 says "~8 routes, public read + admin write."
   - What's unclear: Whether admin writes are wanted now (data is empty, no import pipeline) or deferred until a data import story exists.
   - Recommendation: Build all read routes. Build admin write routes for meetings (CONS-09 explicitly says "admin write"). For treasury writes — since CONS-08 says "read-only" — skip admin writes unless planner overrides.

2. **bigint → number conversion in pg driver**
   - What we know: The `pg` Node.js driver returns `bigint` (PostgreSQL) as JavaScript strings by default. Several columns in treasury (`fiscal_year`, `population`, `item_count`, `sort_order`, `depth`, `segment_count`) are `bigint`.
   - What's unclear: Whether the project has `pg.types.setTypeParser` configured globally to auto-convert bigints.
   - Recommendation: Check `backend/src/lib/db.ts` (currently only has Pool config, no type parser override). Explicitly call `Number(row.column)` in row mapping for known-safe bigint columns.

3. **Budget nested response shape**
   - What we know: `GET /treasury/budgets/:id` must return a useful shape. The categories are a tree (depth + parent_id). Line items belong to categories.
   - What's unclear: Should `GET /budgets/:id` inline the categories tree? Or keep categories as a separate endpoint?
   - Recommendation: Return budget metadata + flat sorted categories list in one response (avoids N+1); keep line items as a separate endpoint (can be large). Categories array sorted by `depth ASC, sort_order ASC`.

4. **Meeting transcript pagination**
   - What we know: Segments can be numerous for a long meeting. No existing route in ev-accounts does offset pagination on large text datasets.
   - What's unclear: Whether a 2-hour meeting has 100 or 7200 segments (depends on segmentation granularity).
   - Recommendation: Implement limit/offset pagination on the transcript endpoint from day one. Default limit 200, max 500.

---

## Sources

### Primary (HIGH confidence)
- Production DB via `npx supabase db query --linked` — exact column definitions and FK constraints for both schemas
- `backend/src/lib/essentialsService.ts` — canonical pool.query() service pattern
- `backend/src/lib/adminService.ts` — canonical pool.query() write pattern
- `backend/src/routes/essentialsPoliticians.ts` — canonical public-read route pattern
- `backend/src/routes/admin.ts` — canonical admin-write route pattern (router.use + per-route)
- `backend/src/routes/candidates.ts` — UUID validation + 404 pattern
- `backend/src/middleware/auth.ts` — requireAuth, optionalAuth implementations
- `backend/src/middleware/requireAdmin.ts` — requireAdmin implementation
- `backend/src/middleware/tierGuards.ts` — requireConnected implementation
- `backend/src/index.ts` — route registration pattern
- `.planning/phases/34-database-schema-migration/34-01-SUMMARY.md` — table inventory + row counts
- `supabase/migrations/20260319000045_phase34_meetings_rls.sql` — RLS confirmation for meetings
- `supabase/migrations/20260319000046_phase34_treasury_rls.sql` — RLS confirmation for treasury

### Secondary (MEDIUM confidence)
- `.planning/STATE.md` — pool.query() mandate for non-public schemas; exposed schema list confirmation
- `.planning/phases/36-express-ports-wave-1/36-CONTEXT.md` — locked decisions (auth model, route prefixes, camelCase convention)

### Tertiary (LOW confidence)
- None — all findings verified from codebase inspection or production DB query.

---

## Metadata

**Confidence breakdown:**
- Treasury schema (columns, FKs, semantics): HIGH — queried production DB directly
- Meetings schema (columns, FKs, semantics): HIGH — queried production DB directly
- pool.query() pattern: HIGH — verified in essentialsService.ts, adminService.ts (post Phase 35)
- Route registration pattern: HIGH — verified in index.ts
- Middleware usage: HIGH — verified in auth.ts, requireAdmin.ts, tierGuards.ts, existing routes
- Admin write route scope for CONS-08: MEDIUM — CONS-08 says "read-only" but admin writes are structurally straightforward; planner should decide

**Research date:** 2026-03-19
**Valid until:** 2026-04-18 (stable domain — schema doesn't change, patterns established)
