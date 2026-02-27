# Phase 4: Compass Routes - Research

**Researched:** 2026-02-26
**Domain:** Inform schema design, compass calibration, politician comparison, RLS for multi-visibility data, UPSERT + change_history atomicity, compass_import_draft promotion
**Confidence:** HIGH — primary sources: existing codebase, official Supabase/PostgreSQL docs, design doc

---

## Summary

Phase 4 creates the `inform` schema from scratch, adds 9 tables, extends `connect.connected_profiles` with `completed_onboarding`, extends `connect.verification_sessions` indirectly (no changes needed), adds 2 auth extensions, 8 compass routes, 3 politician compare routes, and updates 3 existing RPC functions. It is the most schema-heavy phase so far.

Two critical schema discrepancies exist between sources and must be resolved in this phase. First: the `empowered-accounts-design.md` (the authoritative design document) specifies `inform.compass_topics` with `status TEXT CHECK (status IN ('live', 'iceboxed', 'retired'))` and a separate `inform.compass_topic_roles` join table — the Phase 4 input spec says `is_live BOOLEAN` and `level text[]`. The existing `connect.ts` compass-import code (Phase 3) already queries `inform.compass_topics WHERE is_active = true` with a `version` column that appears nowhere in any spec. Second: the design doc `compass_responses` uses `stance_value NUMERIC(3,1)` and `stance_type TEXT` while the Phase 4 input spec says `value INT (1-5)`. These discrepancies must be settled decisively in the migration — Phase 4's schema is the source of truth going forward.

The right approach for Phase 4 is: use the Phase 4 input spec schema as the implementation target (it reflects later decisions than the design doc), add a `version INT DEFAULT 1` column to `compass_topics` to satisfy the Phase 3 `compass-import` code that already references it, use `is_live BOOLEAN` plus a `compass_topic_roles` table (best of both specs), and use `value INT` for responses. All compass write routes use `pg pool` transactions for atomicity. Read routes use `createUserClient` (Supabase JS with RLS). Topics and stances are public-read (anon role). Responses are owner-only.

**Primary recommendation:** Use `pg pool` raw transactions for all compass writes (UPSERT + change_history in a single BEGIN/COMMIT). Use `createUserClient` for compass reads where RLS enforces visibility. Store `selected_topics` as a `JSONB` column on `connected_profiles` (not a separate table). Implement `compass_topic_roles` as a separate join table (not `level text[]`) to align with the design doc's intent while keeping `is_live` for the Phase 4 spec. Promote `compass_import_draft` to `compass_responses` at the start of the first authenticated `GET /compass/answers` call.

---

## Standard Stack

The Phase 4 standard stack is identical to prior phases — no new packages needed.

### Core (already installed)
| Library | Purpose | Usage in Phase 4 |
|---------|---------|-----------------|
| `pg` (pool) | Raw Postgres transactions | All compass write routes — UPSERT + change_history atomicity |
| `@supabase/supabase-js` | Supabase JS client | `createUserClient` for RLS-enforced reads |
| `zod` | Request validation | All route bodies (calibrate, batch-answers, selected-topics) |
| `express` 4.x | HTTP routing | New compass router |
| `jose` | JWT verification | Already used in middleware/auth.ts |

### No New Packages
Phase 4 introduces no new npm dependencies. All tools are established in Phases 1-3.

**Installation:** None required.

---

## Schema Design Recommendations

### The Discrepancy Problem (HIGH confidence — directly observed in codebase)

Three sources disagree on `inform.compass_topics`:

| Source | `is_live`/`status` | Role filtering | `value` type |
|--------|--------------------|----------------|-------------|
| design doc | `status TEXT CHECK('live','iceboxed','retired')` | `compass_topic_roles` join table | `NUMERIC(3,1)` |
| Phase 4 input spec | `is_live BOOLEAN` | `level text[]` column | `INT (1-5)` |
| Phase 3 connect.ts | queries `is_active = true` + `version INT` | (not referenced) | (not referenced) |

**Resolution — implement this exact schema:**

Use `is_live BOOLEAN` (Phase 4 spec) for simplicity, but add `compass_topic_roles` as a separate join table (design doc) rather than `level text[]`. Add `version INT NOT NULL DEFAULT 1` to satisfy Phase 3 `connect.ts` which already queries `compass_topics.version`. Use `value INT` (Phase 4 spec, not NUMERIC) for `compass_responses`.

The Phase 3 `connect.ts` file already deployed with `WHERE is_active = true` — the migration must either add `is_active` as an alias column or update Phase 3's query in the same migration. **Recommended: add `is_active` as a generated column** (`GENERATED ALWAYS AS (is_live) STORED`) to preserve backward compatibility with the Phase 3 code without a route change.

### inform Schema Tables (final decisions)

```sql
-- inform.compass_categories
CREATE TABLE inform.compass_categories (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title      TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- inform.compass_topics
CREATE TABLE inform.compass_topics (
  id          UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  title       TEXT    NOT NULL,
  short_title TEXT,
  question_text TEXT  NOT NULL,
  is_live     BOOLEAN NOT NULL DEFAULT false,
  is_active   BOOLEAN GENERATED ALWAYS AS (is_live) STORED,  -- backward compat with Phase 3
  version     INT     NOT NULL DEFAULT 1,                    -- backward compat with Phase 3 compass-import
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- inform.compass_topic_categories (m2m)
CREATE TABLE inform.compass_topic_categories (
  topic_id    UUID NOT NULL REFERENCES inform.compass_topics(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES inform.compass_categories(id) ON DELETE CASCADE,
  PRIMARY KEY (topic_id, category_id)
);

-- inform.compass_topic_roles (role-based eligibility — replaces level text[])
-- role_scope values: 'city_council' | 'state_legislature' | 'us_congress' | 'president'
-- is_required: true = counts toward completeness threshold for this role
CREATE TABLE inform.compass_topic_roles (
  topic_id    UUID    NOT NULL REFERENCES inform.compass_topics(id) ON DELETE CASCADE,
  role_scope  TEXT    NOT NULL,
  is_required BOOLEAN NOT NULL DEFAULT true,
  PRIMARY KEY (topic_id, role_scope)
);

-- inform.compass_stances (5 per topic, value 1-5)
CREATE TABLE inform.compass_stances (
  id         UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_id   UUID    NOT NULL REFERENCES inform.compass_topics(id) ON DELETE CASCADE,
  value      INT     NOT NULL CHECK (value BETWEEN 1 AND 5),
  text       TEXT    NOT NULL,
  UNIQUE (topic_id, value)
);

-- inform.compass_responses (per-user calibration)
CREATE TABLE inform.compass_responses (
  user_id       UUID    NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  topic_id      UUID    NOT NULL REFERENCES inform.compass_topics(id) ON DELETE CASCADE,
  value         INT     NOT NULL CHECK (value BETWEEN 1 AND 5),
  write_in_text TEXT,
  visibility    TEXT    NOT NULL DEFAULT 'private'
    CHECK (visibility IN ('private', 'friends', 'public')),
  inverted      BOOLEAN NOT NULL DEFAULT false,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, topic_id)   -- composite PK; also serves as the UNIQUE constraint
);

-- inform.compass_change_history (append-only audit log)
CREATE TABLE inform.compass_change_history (
  id         UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID    NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  topic_id   UUID    NOT NULL REFERENCES inform.compass_topics(id) ON DELETE CASCADE,
  old_value  INT,                   -- NULL on first calibration
  new_value  INT     NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
  -- NO updated_at — append-only, never touched after insert
);

-- inform.politicians
CREATE TABLE inform.politicians (
  id               UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name       TEXT    NOT NULL,
  last_name        TEXT    NOT NULL,
  preferred_name   TEXT,
  full_name        TEXT,
  office_title     TEXT,
  photo_origin_url TEXT,
  is_active        BOOLEAN NOT NULL DEFAULT true,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- inform.politician_answers
CREATE TABLE inform.politician_answers (
  politician_id UUID NOT NULL REFERENCES inform.politicians(id) ON DELETE CASCADE,
  topic_id      UUID NOT NULL REFERENCES inform.compass_topics(id) ON DELETE CASCADE,
  value         INT  NOT NULL CHECK (value BETWEEN 1 AND 5),
  PRIMARY KEY (politician_id, topic_id)
);

-- inform.politician_context
CREATE TABLE inform.politician_context (
  politician_id UUID    NOT NULL REFERENCES inform.politicians(id) ON DELETE CASCADE,
  topic_id      UUID    NOT NULL REFERENCES inform.compass_topics(id) ON DELETE CASCADE,
  reasoning     TEXT    NOT NULL,
  sources       TEXT[]  NOT NULL DEFAULT '{}',
  PRIMARY KEY (politician_id, topic_id)
);
```

### ALTER: connect.connected_profiles

```sql
ALTER TABLE connect.connected_profiles
  ADD COLUMN IF NOT EXISTS completed_onboarding BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE connect.connected_profiles
  ADD COLUMN IF NOT EXISTS selected_topic_ids   JSONB NOT NULL DEFAULT '[]';
```

`selected_topic_ids` stores a JSON array of UUIDs: `["uuid1", "uuid2", ...]`. 3-8 items.

---

## Architecture Patterns

### Recommended Route File Organization

Use two route files — split by read/write concern and authorization level:

```
backend/src/routes/
├── auth.ts              (existing — add /complete-onboarding)
├── account.ts           (existing — add completed_onboarding to /me response)
├── connect.ts           (existing — no changes in Phase 4)
├── compass.ts           (NEW — all compass + politician routes)
├── health.ts            (existing)
└── invites.ts           (existing)
```

A single `compass.ts` is appropriate. The routes are thematically unified and the file will be ~400-500 lines — manageable. Splitting into `compassRead.ts` and `compassWrite.ts` adds file-management overhead with no architectural benefit at this scale.

### Recommended Project Structure (Phase 4 additions)

```
backend/src/
├── routes/
│   └── compass.ts           # All compass routes
├── lib/
│   └── compassService.ts    # Business logic: import promotion, completeness calc
└── (no new middleware needed)
```

### Pattern 1: Compass Write — pg Pool Transaction (UPSERT + change_history)

**What:** POST /compass/answers must atomically UPSERT a response AND append to change_history. These are two table writes that must succeed or fail together.
**When to use:** All calibration writes (POST /compass/answers).
**Source:** Project established pattern — pg pool BEGIN/COMMIT used in connect.ts /complete.

```typescript
// Source: established pattern from backend/src/routes/connect.ts
const client = await pool.connect();
try {
  await client.query('BEGIN');

  // Step 1: Read existing response for change_history old_value
  const { rows: existing } = await client.query<{ value: number }>(
    'SELECT value FROM inform.compass_responses WHERE user_id = $1 AND topic_id = $2',
    [userId, topicId]
  );
  const oldValue = existing[0]?.value ?? null;

  // Step 2: UPSERT the response
  await client.query(
    `INSERT INTO inform.compass_responses (user_id, topic_id, value, write_in_text, inverted, updated_at)
     VALUES ($1, $2, $3, $4, $5, now())
     ON CONFLICT (user_id, topic_id) DO UPDATE
       SET value         = EXCLUDED.value,
           write_in_text = EXCLUDED.write_in_text,
           inverted      = EXCLUDED.inverted,
           updated_at    = now()`,
    [userId, topicId, value, writeInText ?? null, inverted ?? false]
  );

  // Step 3: Append to change_history (always — even first calibration)
  await client.query(
    `INSERT INTO inform.compass_change_history (user_id, topic_id, old_value, new_value)
     VALUES ($1, $2, $3, $4)`,
    [userId, topicId, oldValue, value]
  );

  await client.query('COMMIT');
} catch (err) {
  await client.query('ROLLBACK');
  throw err;
} finally {
  client.release();
}
```

### Pattern 2: Compass Read — createUserClient (RLS enforced)

**What:** GET routes for topics, categories, own answers, politician data use Supabase JS client with user JWT so RLS applies.
**When to use:** All compass read routes.

```typescript
// Source: established pattern from backend/src/routes/account.ts
const db = createUserClient(authReq.accessToken);

// Topics are public-read (anon policy) — user client also works
const { data: topics, error } = await db
  .schema('inform')
  .from('compass_topics')
  .select('id, title, short_title, question_text, is_live, compass_stances(*), compass_topic_categories(category_id, compass_categories(id, title))')
  .eq('is_live', true);

// Responses are owner-only (RLS enforces user_id = auth.uid())
const { data: responses, error } = await db
  .schema('inform')
  .from('compass_responses')
  .select('topic_id, value, write_in_text, inverted, visibility');
```

**Note:** For `GET /compass/topics` and `GET /compass/categories`, the route should use `optionalAuth` middleware (not `requireAuth`) so unauthenticated users can load topic data for guest compass usage. The `createUserClient` pattern still works when auth is present; for unauthenticated requests, use `supabaseAdmin` with a read-only safe query (topics/categories have no sensitive data — anon SELECT is safe here).

### Pattern 3: Completeness Check — Role Filtering via compass_topic_roles

**What:** GET /compass/progress must return a completeness score filtered by the user's role scope.
**When to use:** COMP-03 endpoint, also consumed by Phase 5 empower preflight.

```typescript
// Source: derived from design doc compass_topic_roles + project COMP-03 requirement

async function getCompassCompleteness(userId: string, roleScope?: string): Promise<{
  required: number;
  answered: number;
  percent: number;
  complete: boolean;
}> {
  const client = await pool.connect();
  try {
    let requiredTopicsQuery: string;
    let params: unknown[];

    if (roleScope) {
      // Role-filtered: only topics required for this role_scope
      requiredTopicsQuery = `
        SELECT ct.id
        FROM inform.compass_topics ct
        JOIN inform.compass_topic_roles ctr ON ctr.topic_id = ct.id
        WHERE ct.is_live = true
          AND ctr.role_scope = $1
          AND ctr.is_required = true
      `;
      params = [roleScope];
    } else {
      // Default: all live topics (for Connected users with no role yet)
      requiredTopicsQuery = `
        SELECT id FROM inform.compass_topics WHERE is_live = true
      `;
      params = [];
    }

    const { rows: requiredTopics } = await client.query<{ id: string }>(
      requiredTopicsQuery, params
    );
    const requiredIds = requiredTopics.map(r => r.id);

    if (requiredIds.length === 0) {
      return { required: 0, answered: 0, percent: 100, complete: true };
    }

    const { rows: answered } = await client.query<{ count: string }>(
      `SELECT COUNT(*) FROM inform.compass_responses
       WHERE user_id = $1 AND topic_id = ANY($2::uuid[])`,
      [userId, requiredIds]
    );

    const answeredCount = parseInt(answered[0]?.count ?? '0', 10);
    const requiredCount = requiredIds.length;
    return {
      required: requiredCount,
      answered: answeredCount,
      percent: Math.round((answeredCount / requiredCount) * 100),
      complete: answeredCount >= requiredCount,
    };
  } finally {
    client.release();
  }
}
```

The caller determines `roleScope` by checking if the user has an `empowered_profiles` row (or is in the empowerment preflight) and what role they intend. For Phase 4, expose `roleScope` as an optional query param: `GET /compass/progress?role=city_council`.

### Pattern 4: compass_import_draft Promotion

**What:** Phase 3 stored calibrations as JSONB in `verification_sessions.compass_import_draft`. Shape: `[{topic_id, topic_version, stance_id, inverted}]`. Phase 4 must convert `stance_id → value` (INT 1-5) and write to `compass_responses`.

**When:** Promote on the first authenticated `GET /compass/answers` call — lazy promotion.

**Conversion logic:**
1. Check if `verification_sessions.compass_import_draft` is non-null for this user
2. For each calibration in the draft, look up the `stance_id` in `inform.compass_stances` to get `value` (INT 1-5)
3. UPSERT into `compass_responses` and append to `compass_change_history` in a single pg transaction
4. Clear `compass_import_draft` (set to NULL) on the verification_session after successful promotion
5. If `stance_id` lookup fails (topic removed or changed), skip that calibration silently — it was already version-validated in Phase 3

```typescript
// Source: derived from Phase 3 connect.ts compass-import implementation + Phase 4 schema
async function promoteCompassImportDraft(userId: string): Promise<void> {
  const client = await pool.connect();
  try {
    // 1. Read draft
    const { rows } = await client.query<{ compass_import_draft: unknown }>(
      `SELECT compass_import_draft FROM connect.verification_sessions WHERE user_id = $1`,
      [userId]
    );
    const draft = rows[0]?.compass_import_draft;
    if (!draft || !Array.isArray(draft) || draft.length === 0) return;

    await client.query('BEGIN');

    for (const cal of draft) {
      // 2. Resolve stance_id → value
      const { rows: stanceRows } = await client.query<{ value: number }>(
        `SELECT value FROM inform.compass_stances WHERE id = $1 AND topic_id = $2`,
        [cal.stance_id, cal.topic_id]
      );
      if (stanceRows.length === 0) continue; // stance gone; skip

      const value = stanceRows[0]!.value;

      // 3. UPSERT response (don't overwrite if user already calibrated this topic)
      await client.query(
        `INSERT INTO inform.compass_responses (user_id, topic_id, value, inverted)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (user_id, topic_id) DO NOTHING`,
        [userId, cal.topic_id, value, cal.inverted ?? false]
      );

      // 4. Append to change_history for the imported calibrations
      await client.query(
        `INSERT INTO inform.compass_change_history (user_id, topic_id, old_value, new_value)
         VALUES ($1, $2, NULL, $3)`,
        [userId, cal.topic_id, value]
      );
    }

    // 5. Clear the draft
    await client.query(
      `UPDATE connect.verification_sessions SET compass_import_draft = NULL, updated_at = now() WHERE user_id = $1`,
      [userId]
    );

    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('[promoteCompassImportDraft] error:', err);
    // Non-fatal: if promotion fails, user's manually entered calibrations still work.
    // The draft will be retried on next GET /compass/answers call.
  } finally {
    client.release();
  }
}
```

**Key decision: ON CONFLICT DO NOTHING for imports.** If a user calibrated a topic manually after Connect (unlikely but possible), don't overwrite their answer with the imported draft.

### Pattern 5: selected_topics — JSONB Column on connected_profiles

**What:** Store user's selected compass topic IDs (3-8 UUIDs) as a JSONB column on `connect.connected_profiles`.

**Why JSONB on connected_profiles (not a separate table):**
- Simple, low-cardinality data (max 8 UUIDs) — no querying/indexing of individual elements needed
- No JOIN required — fetched alongside profile data
- Topic reordering is trivial (client sends full array, server stores it)
- A separate table would be appropriate only if topics needed per-item metadata

**Column:** `selected_topic_ids JSONB NOT NULL DEFAULT '[]'`

```typescript
// PUT /compass/selected-topics — store via pg pool (simple single-table update)
const PutSelectedTopicsSchema = z.object({
  topic_ids: z.array(z.string().uuid()).min(3).max(8),
});

// Write: use pg pool directly (single-table update, no transaction complexity needed)
await pool.query(
  `UPDATE connect.connected_profiles SET selected_topic_ids = $1, updated_at = now() WHERE user_id = $2`,
  [JSON.stringify(validatedTopicIds), userId]
);

// Read via createUserClient — RLS ensures owner-only
const { data: profile } = await db
  .schema('connect')
  .from('connected_profiles')
  .select('selected_topic_ids')
  .eq('user_id', userId)
  .single();
```

### Pattern 6: RPC Updates — execute_empowerment and execute_demotion

**What:** Phase 4 migration adds the compass visibility lines to both RPC functions (promised in migration 010 comments).

**How:** Use `CREATE OR REPLACE FUNCTION` in a new migration (015). The function signatures are unchanged; only the body gains the UPDATE statements.

```sql
-- In migration 015: Phase 4 compass schema

-- UPDATE execute_empowerment to make compass public on empowerment
CREATE OR REPLACE FUNCTION empower.execute_empowerment(
  p_user_id              UUID,
  p_legal_name           TEXT,
  p_connected_profile_id UUID
)
RETURNS empower.empowered_profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_slug   TEXT;
  v_suffix TEXT;
  v_result empower.empowered_profiles;
BEGIN
  v_suffix := substring(md5(gen_random_uuid()::text) FROM 1 FOR 4);
  v_slug := rtrim(
    lower(regexp_replace(p_legal_name, '[^a-zA-Z0-9]+', '-', 'g')),
    '-'
  ) || '-' || v_suffix;

  INSERT INTO empower.empowered_profiles (
    user_id, connected_profile_id, legal_name, candidate_page_slug, empowered_at
  ) VALUES (
    p_user_id, p_connected_profile_id, p_legal_name, v_slug, now()
  )
  RETURNING * INTO v_result;

  -- Phase 4 addition: make all compass responses public on empowerment
  UPDATE inform.compass_responses
    SET visibility = 'public', updated_at = now()
    WHERE user_id = p_user_id;

  RETURN v_result;
EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$$;

-- UPDATE execute_demotion to make compass private on demotion
CREATE OR REPLACE FUNCTION empower.execute_demotion(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE empower.empowered_profiles
    SET is_active = false, updated_at = now()
    WHERE user_id = p_user_id AND is_active = true;

  -- Phase 4 addition: make all compass responses private on demotion
  UPDATE inform.compass_responses
    SET visibility = 'private', updated_at = now()
    WHERE user_id = p_user_id;

EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$$;

-- UPDATE get_calibration_lapsed_users with real query (Phase 4 replaces stub)
-- Returns Empowered users who have live topics without a compass response
-- (Phase 7 cron job wires this to daily execution — this just provides the query)
CREATE OR REPLACE FUNCTION public.get_calibration_lapsed_users()
RETURNS TABLE (user_id UUID)
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT DISTINCT ep.user_id
  FROM empower.empowered_profiles ep
  WHERE ep.is_active = true
  AND EXISTS (
    SELECT 1
    FROM inform.compass_topics ct
    WHERE ct.is_live = true
    AND NOT EXISTS (
      SELECT 1 FROM inform.compass_responses cr
      WHERE cr.user_id = ep.user_id AND cr.topic_id = ct.id
    )
  );
$$;
```

**Note:** `get_calibration_lapsed_users` is updated in Phase 4 to provide a real query, but it is not yet wired to a scheduled job. The Phase 7 cron job will call it.

### Pattern 7: Guest Access for Topics/Categories

**What:** `GET /compass/topics` and `GET /compass/categories` should work for unauthenticated users (CompassV2 supports guest usage per the API contract).

**How:** Use `optionalAuth` middleware on these two routes. When the user is not authenticated, use `supabaseAdmin` for the read (topics/categories contain no sensitive data — they are public reference data). When authenticated, use `createUserClient`.

```typescript
// optionalAuth middleware (already exists from prior work — if not, add to middleware/)
router.get('/topics', optionalAuth, async (req, res) => {
  const authReq = req as Partial<AuthenticatedRequest>;
  const db = authReq.accessToken
    ? createUserClient(authReq.accessToken)
    : supabaseAdmin;  // Safe: topics/categories are pure reference data, no PII

  const { data, error } = await db
    .schema('inform')
    .from('compass_topics')
    .select('...')
    .eq('is_live', true);
  // ...
});
```

**IMPORTANT CONSTRAINT:** `supabaseAdmin` is banned from `src/routes/` by the architecture test. Using `supabaseAdmin` here for unauthenticated topic reads would violate that test. Two options:

1. **Use `optionalAuth` + pg pool for unauthenticated reads** — pg pool is already allowed in routes. Add an anon-accessible SELECT via pool for the unauthenticated path.
2. **Relax the architecture test** to permit `supabaseAdmin` in compass.ts for reference data only (creates precedent).
3. **Use `requireAuth` on topics/categories** — simpler but breaks guest compass support.

**Recommendation: Option 1 (pg pool for unauthenticated reads).** The architecture test ban on `supabaseAdmin` in routes is a hard constraint — do not relax it. Use pg pool queries directly for topics/categories when no auth token is present. This is consistent with how connect.ts handles reads. The `optionalAuth` middleware is either already implemented or needs to be added in Phase 4.

Check if `optionalAuth` exists:

```typescript
// middleware/auth.ts — check if optionalAuth is exported
// If not, add:
export async function optionalAuth(
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    next(); // no token — continue as unauthenticated
    return;
  }
  // Reuse requireAuth logic but call next() on failure instead of 401
  // ... (same JWKS verification, attach userId + accessToken if valid)
  next();
}
```

### Anti-Patterns to Avoid

- **Do NOT use `supabaseAdmin` in compass.ts routes** — architecture test bans this. Use `createUserClient` or `pg pool`.
- **Do NOT chain JS awaits for UPSERT + change_history** — use a single BEGIN/COMMIT pg transaction.
- **Do NOT store `selected_topic_ids` in a separate table** — JSONB column on `connected_profiles` is sufficient and simpler.
- **Do NOT use `level text[]` column on compass_topics** — use the `compass_topic_roles` join table for role filtering (queryable, extensible, consistent with design doc intent).
- **Do NOT return `tolerance_rating` in any compass compare response** — even `GET /compass/politicians/:id/answers` must not pull from connected_profiles.
- **Do NOT overwrite existing calibrations during compass_import_draft promotion** — use `ON CONFLICT DO NOTHING`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| UPSERT atomicity | Separate SELECT + conditional INSERT/UPDATE | `INSERT ... ON CONFLICT DO UPDATE` inside pg pool BEGIN/COMMIT | Race condition: two concurrent requests can both see "no row" and both INSERT |
| Role completeness math | Application-layer filter loops | SQL `COUNT` + `ANY($2::uuid[])` | Single DB round-trip, correct under concurrent writes |
| Topic-to-category nesting | Multiple queries + JS merge | Supabase `.select('*, categories(*)`)` nested select | One query, relational, no N+1 |
| Change history deduplication | Check "did value actually change" before appending | Just always append — never deduplicate | Change history is audit log; even same-value re-submission is a user action |
| Import draft promotion scheduling | Cron job or background worker | Lazy promotion on first GET /compass/answers | Zero infrastructure overhead; draft size is tiny; latency is acceptable |

**Key insight:** The compass calibration system looks like simple CRUD but has three atomicity traps: (1) UPSERT vs separate insert/update, (2) change_history must be in the same transaction as the response write, (3) import promotion must be transactional or you get partial imports. All three require pg pool transactions, not the Supabase JS client.

---

## RLS Strategy for inform Schema (HIGH confidence)

### Topics, Categories, Stances, Politician Data — Public Read

These are reference data with no PII. Grant SELECT to both `anon` and `authenticated` roles with no row filtering.

```sql
-- inform.compass_topics: public read
ALTER TABLE inform.compass_topics ENABLE ROW LEVEL SECURITY;
CREATE POLICY "topics: public read" ON inform.compass_topics
  FOR SELECT TO anon, authenticated USING (true);

-- inform.compass_categories: public read
ALTER TABLE inform.compass_categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "categories: public read" ON inform.compass_categories
  FOR SELECT TO anon, authenticated USING (true);

-- inform.compass_stances: public read
ALTER TABLE inform.compass_stances ENABLE ROW LEVEL SECURITY;
CREATE POLICY "stances: public read" ON inform.compass_stances
  FOR SELECT TO anon, authenticated USING (true);

-- inform.compass_topic_categories: public read
ALTER TABLE inform.compass_topic_categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "topic_categories: public read" ON inform.compass_topic_categories
  FOR SELECT TO anon, authenticated USING (true);

-- inform.compass_topic_roles: public read (role scope data is not sensitive)
ALTER TABLE inform.compass_topic_roles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "topic_roles: public read" ON inform.compass_topic_roles
  FOR SELECT TO anon, authenticated USING (true);

-- inform.politicians: public read
ALTER TABLE inform.politicians ENABLE ROW LEVEL SECURITY;
CREATE POLICY "politicians: public read" ON inform.politicians
  FOR SELECT TO anon, authenticated USING (true);

-- inform.politician_answers: public read
ALTER TABLE inform.politician_answers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "politician_answers: public read" ON inform.politician_answers
  FOR SELECT TO anon, authenticated USING (true);

-- inform.politician_context: public read
ALTER TABLE inform.politician_context ENABLE ROW LEVEL SECURITY;
CREATE POLICY "politician_context: public read" ON inform.politician_context
  FOR SELECT TO anon, authenticated USING (true);
```

### compass_responses — Owner-Only SELECT, No Direct INSERT/UPDATE

All writes go through pg pool (service layer). RLS on the table has no INSERT/UPDATE policies — the service layer uses `pool` (which connects as the postgres superuser via `DATABASE_URL`) and bypasses RLS by design. SELECT is owner-only.

```sql
ALTER TABLE inform.compass_responses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "responses: owner can read own"
  ON inform.compass_responses FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

-- No INSERT/UPDATE/DELETE policies — all writes go through pg pool
-- (same pattern as invite_codes and invite_chains in Phase 3)
```

### compass_change_history — Owner-Only SELECT, No Direct INSERT

```sql
ALTER TABLE inform.compass_change_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "change_history: owner can read own"
  ON inform.compass_change_history FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

-- No INSERT policy — append-only via pg pool service layer
```

### GRANT statements required

```sql
GRANT USAGE ON SCHEMA inform TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA inform TO anon, authenticated;
-- After CREATE TABLE statements — or use explicit table grants
```

---

## Index Strategy (MEDIUM confidence — standard B-tree/partial patterns)

```sql
-- compass_topics
CREATE INDEX idx_compass_topics_is_live ON inform.compass_topics(is_live) WHERE is_live = true;

-- compass_topic_roles (for completeness queries filtering by role_scope)
CREATE INDEX idx_compass_topic_roles_scope ON inform.compass_topic_roles(role_scope);

-- compass_responses (primary lookup: user's answers)
CREATE INDEX idx_compass_responses_user_id ON inform.compass_responses(user_id);
-- Note: (user_id, topic_id) is the composite PRIMARY KEY — already indexed

-- compass_change_history (history lookup per user)
CREATE INDEX idx_compass_change_history_user ON inform.compass_change_history(user_id);
CREATE INDEX idx_compass_change_history_topic ON inform.compass_change_history(user_id, topic_id);

-- politicians (active filter)
CREATE INDEX idx_politicians_is_active ON inform.politicians(is_active) WHERE is_active = true;

-- politician_answers (lookup by politician)
CREATE INDEX idx_politician_answers_politician ON inform.politician_answers(politician_id);
```

---

## Common Pitfalls

### Pitfall 1: Architecture Test — supabaseAdmin in Routes
**What goes wrong:** Using `supabaseAdmin` in `compass.ts` for the unauthenticated topics route. The architecture test in `backend/src/__tests__/architecture.test.ts` scans `src/routes/` and fails if it finds `supabaseAdmin` imports.
**Why it happens:** The natural instinct for a public-read route is to use the admin client to bypass RLS. But the ban applies to the entire routes directory.
**How to avoid:** Use `pg pool` queries for unauthenticated reads. Topics/categories/politicians are simple reference data — a raw `SELECT` via pool is appropriate.
**Warning signs:** TypeScript compiles but integration test fails with "supabaseAdmin must not be used in route handlers".

### Pitfall 2: UPSERT Without BEGIN/COMMIT Loses change_history
**What goes wrong:** Doing `INSERT ... ON CONFLICT DO UPDATE` for the response, then a separate `INSERT INTO compass_change_history` in a second pool query call. If the server crashes between the two, change_history is missing for that calibration.
**Why it happens:** The UPSERT looks atomic but the subsequent change_history INSERT is not in the same transaction.
**How to avoid:** Always `BEGIN` → UPSERT → change_history INSERT → `COMMIT` as a single pg transaction.
**Warning signs:** `compass_responses` has more rows than `compass_change_history` for a given user/topic.

### Pitfall 3: compass_import_draft Schema Mismatch
**What goes wrong:** Phase 3 stores `{topic_id, topic_version, stance_id, inverted}`. Phase 4 `compass_responses` uses `value INT` not `stance_id`. Copying the import directly without `stance_id → value` conversion produces a type error or incorrect data.
**Why it happens:** The draft format was designed for client-side storage (stance_id from localStorage) but the DB schema uses integer values.
**How to avoid:** The promotion function must JOIN `inform.compass_stances ON id = stance_id` to resolve `value`. If the stance no longer exists, skip the calibration (don't error).
**Warning signs:** Promotion function completes successfully but compass_responses has no rows.

### Pitfall 4: is_active Column Alias (Phase 3 Compatibility)
**What goes wrong:** Phase 3 `connect.ts` already queries `inform.compass_topics WHERE is_active = true`. If Phase 4 creates the table with only `is_live` and no `is_active`, the Phase 3 compass-import validation query breaks at runtime.
**Why it happens:** The column was referenced in Phase 3 without the table existing yet — it was aspirational.
**How to avoid:** Add `is_active BOOLEAN GENERATED ALWAYS AS (is_live) STORED` to the compass_topics table. This is a computed column that mirrors `is_live`, satisfying the Phase 3 reference without any code changes.
**Warning signs:** `POST /connect/compass-import` returns 500 after Phase 4 migration runs.

### Pitfall 5: No GRANT on inform Schema
**What goes wrong:** Tables created but `authenticated` and `anon` roles have no USAGE on the `inform` schema. All queries return "permission denied for schema inform" even though RLS policies exist.
**Why it happens:** Supabase schema permissions require explicit `GRANT USAGE ON SCHEMA` and `GRANT SELECT ON TABLE`. Creating tables doesn't automatically grant access.
**How to avoid:** Include `GRANT USAGE ON SCHEMA inform TO anon, authenticated;` and per-table grants at the end of the migration. Check the prior migration pattern in `20260224000011_grant_schema_permissions.sql` and `20260224000012_grant_anon_connect.sql`.
**Warning signs:** RLS policies exist but every authenticated query returns empty results or 403.

### Pitfall 6: get_calibration_lapsed_users Returning Wrong Results
**What goes wrong:** The Phase 4 version of `get_calibration_lapsed_users` returns all Empowered users who haven't answered every live topic — but Phase 7 needs only users who missed *newly added* topics within the 30-day window. The Phase 4 version is a simplified "anyone missing any topic" query.
**Why it happens:** The full lapse logic (join to compass_change_history timestamps, 30-day window) requires the calibration run timestamp table that Phase 7 creates.
**How to avoid:** The Phase 4 implementation is intentionally simplified — document this clearly in the function body comment. Phase 7 replaces it with the full timestamp-aware query.
**Warning signs:** Phase 7 cron demotes users who were already calibrated before their new topics were added.

### Pitfall 7: selected_topic_ids Validation
**What goes wrong:** Storing topic UUIDs in `selected_topic_ids` JSONB without verifying the UUIDs actually exist in `inform.compass_topics`. A client could submit stale/fake UUIDs.
**Why it happens:** JSONB has no FK constraint mechanism.
**How to avoid:** In the `PUT /compass/selected-topics` handler, validate that all submitted `topic_ids` exist in `inform.compass_topics WHERE is_live = true` before storing. Simple COUNT check via pg pool.
**Warning signs:** Frontend shows "topic not found" errors when rendering selected topics.

---

## Route Details and Key Questions Answered

### Question 1: selected_topics Storage
**Answer:** JSONB column `selected_topic_ids` on `connect.connected_profiles`. Validated (topic IDs must exist and be live) before storage. Read via `createUserClient` (RLS owner-only). Written via `pg pool` (simple single-table UPDATE).

### Question 2: level field design for COMP-03
**Answer:** Implement as `compass_topic_roles` join table with columns `(topic_id, role_scope, is_required)`. `role_scope` values: `'city_council' | 'state_legislature' | 'us_congress' | 'president'`. For COMP-03, the progress endpoint accepts an optional `?role=city_council` query param. When no role is provided, completeness is calculated against all live topics. Phase 5 empower preflight supplies the role based on user's intent (from empower request body).

### Question 3: UPSERT pattern for compass_responses
**Answer:** `INSERT ... ON CONFLICT (user_id, topic_id) DO UPDATE SET ...` inside a pg pool `BEGIN/COMMIT` transaction that also inserts the `compass_change_history` row. Single transaction — no separate paths for INSERT vs UPDATE.

### Question 4: compass_import_draft promotion
**Answer:** Lazy promotion on first `GET /compass/answers` call. Check if `verification_sessions.compass_import_draft` is non-null, convert `stance_id → value` via JOIN to `compass_stances`, UPSERT with `ON CONFLICT DO NOTHING`, clear draft. Non-fatal on error (user can still calibrate manually).

### Question 5: Public/unauthenticated access
**Answer:** Yes, `GET /compass/topics` and `GET /compass/categories` must work unauthenticated. Use `optionalAuth` middleware. For unauthenticated requests, use `pg pool` direct query (not `supabaseAdmin` — banned in routes). For authenticated requests, use `createUserClient`.

### Question 6: Plan breakdown
**Recommendation: 3 plans**

Given the scope (schema migration + RPC updates + auth extensions + 8+ routes):

- **04-01-PLAN.md** — inform schema migration + RPC updates + auth extensions
  - Migration 015: all 9 inform tables + indexes + RLS + grants + is_active generated column
  - ALTER connect.connected_profiles: add `completed_onboarding`, `selected_topic_ids`
  - CREATE OR REPLACE: execute_empowerment, execute_demotion, get_calibration_lapsed_users
  - POST /auth/complete-onboarding route
  - GET /auth/me extension (add `completed_onboarding` field)

- **04-02-PLAN.md** — Compass read routes + optionalAuth middleware
  - optionalAuth middleware (if not already present)
  - GET /compass/topics (with stances + categories, public access)
  - GET /compass/categories (with nested topics, public access)
  - GET /compass/answers (own answers; triggers import promotion on first call)
  - POST /compass/answers/batch (batch fetch answers for specific topic IDs)
  - GET /compass/selected-topics
  - GET /compass/progress (COMP-03 with role filtering)
  - GET /compass/politicians (list active politicians)
  - GET /compass/politicians/:id/answers
  - GET /compass/politicians/:id/:topicId/context
  - index.ts registration: `app.use('/api/compass', compassRouter)`

- **04-03-PLAN.md** — Compass write routes + compassService + integration tests
  - POST /compass/answers (UPSERT + change_history atomicity)
  - PUT /compass/selected-topics
  - compassService.ts: `promoteCompassImportDraft()`, `getCompassCompleteness()`
  - Integration tests: 401-only + architecture enforcement tests

Rationale for 3 plans (not 2): The migration is large enough to deserve its own plan — it touches 9 new tables, 2 ALTER statements, and 3 RPC replacements. Combining it with routes produces a plan that's too large to execute safely. The read/write route split (plans 2 and 3) follows the project's established pattern of separating schema work from route work.

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|-----------------|--------|
| `status TEXT CHECK('live','iceboxed','retired')` (design doc) | `is_live BOOLEAN` (Phase 4 spec) | Simpler queries; iceboxed/retired distinction deferred |
| `stance_value NUMERIC(3,1)` (design doc) | `value INT (1-5)` (Phase 4 spec) | Integer is cleaner for 1-5 scale; no half-steps needed in v1 |
| `compass_topic_roles` join table (design doc) | `level text[]` column (Phase 4 spec) | Use join table — it's queryable and extensible |
| RPC stubs with empty bodies (Phase 1) | Full RPC implementations (Phase 4) | Atomic visibility updates on empower/demote now work |

**Deprecated/outdated:**
- Phase 3 `connect.ts` references `inform.compass_topics.is_active` and `.version` — resolved via generated column + `version INT DEFAULT 1` in Phase 4 migration. No route code change needed.

---

## Open Questions

1. **Does `optionalAuth` middleware already exist?**
   - What we know: `requireAuth` exists in `middleware/auth.ts`. Phase 3 did not need unauthenticated routes.
   - What's unclear: Whether `optionalAuth` was added but not documented.
   - Recommendation: Check `middleware/auth.ts` at plan time. If absent, add it in Plan 04-02.

2. **Supabase type generation after Phase 4**
   - What we know: `backend/src/types/database.types.ts` is regenerated via `supabase gen types` after migrations.
   - What's unclear: Whether the type file will correctly model the `selected_topic_ids JSONB` column and the generated `is_active` column.
   - Recommendation: After migration, regenerate types and verify that `compass_responses` PK shape (composite) is correctly typed.

3. **`get_calibration_lapsed_users` Phase 4 vs Phase 7 scope**
   - What we know: Phase 7 needs timestamp-aware lapse logic (30-day window from topic go-live date). Phase 4's version has no timestamp awareness.
   - What's unclear: Does the Phase 7 cron need the timestamp added to compass_topics in Phase 4, or can it add it in Phase 7?
   - Recommendation: Add `went_live_at TIMESTAMPTZ` to `inform.compass_topics` in Phase 4. Null for topics created before tracking. Phase 7 uses this column for the 30-day window query. This avoids an ALTER TABLE migration during Phase 7 on a potentially data-populated table.

4. **compass_responses PRIMARY KEY vs UNIQUE constraint**
   - What we know: Design doc uses `UNIQUE (user_id, topic_id)` with a separate UUID primary key. Phase 4 spec says `UNIQUE(user_id, topic_id)`.
   - What's unclear: Whether the Phase 5 empower RPC needs to reference compass_responses by ID.
   - Recommendation: Use composite PRIMARY KEY `(user_id, topic_id)` — no separate UUID PK needed. The UPSERT ON CONFLICT references the composite PK. If Phase 5 RPC needs row-level references, the composite key is sufficient.

---

## Sources

### Primary (HIGH confidence)
- `C:\EV-Accounts\backend\src\routes\connect.ts` — Phase 3 compass-import implementation; reveals `is_active` + `version` references
- `C:\EV-Accounts\backend\src\routes\account.ts` — `createUserClient` pattern; whitelist response building
- `C:\EV-Accounts\supabase\migrations\20260224000010_rpc_functions.sql` — Phase 1 RPC stub bodies + comments on what Phase 4 must add
- `C:\EV-Accounts\supabase\migrations\20260225000014_phase3_invite_connect_schema.sql` — RLS pattern for non-public schemas; grant patterns
- `C:\EV-Accounts\empowered-accounts-design.md` — original compass schema (design doc baseline)
- `C:\EV-Accounts\.planning\STATE.md` — Phase 3 decisions (pg pool pattern, privacy enforcement)
- Supabase official docs: upsert with onConflict — verified UPSERT API shape
- Supabase official docs: RLS for anon role — verified `TO anon USING (true)` pattern

### Secondary (MEDIUM confidence)
- Supabase official docs: index strategies — verified B-tree, partial index patterns
- Project SUMMARY.md research — established pitfall patterns (RLS gaps, atomicity, service role hygiene)

### Tertiary (LOW confidence)
- Phase 4 input spec schema decisions (is_live, level, value INT) — these are locked decisions per the phase context; not independently verified against Supabase changelog

---

## Metadata

**Confidence breakdown:**
- Schema design: HIGH — grounded in existing codebase + design doc + phase spec; discrepancies identified and resolved
- RLS strategy: HIGH — verified against official docs + prior migration patterns
- UPSERT + atomicity: HIGH — pg pool BEGIN/COMMIT is established project pattern
- Import promotion: HIGH — derived from Phase 3 actual implementation + Phase 4 spec
- Index strategy: MEDIUM — standard Postgres patterns, not benchmarked against actual query load
- Plan breakdown: MEDIUM — based on project velocity (~20 min/plan) and scope estimate

**Research date:** 2026-02-26
**Valid until:** 2026-03-28 (30 days — stable domain, no fast-moving dependencies)
