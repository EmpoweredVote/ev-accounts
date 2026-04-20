# Source URL Verification — Plan A (Backend + Skill)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the data model, backfill, admin API endpoints, and `verify-sources` Claude Code skill so source URLs on compass stances and read-rank quotes can be tracked, auto-verified, and queued for human review.

**Architecture:** New `public.source_verifications` table tracks per-URL status. Backfill script seeds existing rows. Three admin endpoints (`list`, `approve`, `unfixable`) power review workflow. A project-scoped Claude Code skill at `.claude/skills/verify-sources/SKILL.md` processes unverified rows using `WebFetch` and `WebSearch`, writing status + LLM notes back to Supabase. Human review via Supabase table editor (stopgap for v1; Plan B builds the SPA UI).

**Tech Stack:** PostgreSQL (Supabase), Node 20 + TypeScript + Express (ev-accounts backend), Vitest, Zod, existing `requireAuth`/`requireAdmin` middleware, Claude Code skill format.

## Data Model Reference

- **Compass stances:** `inform.politician_context` keyed by `(politician_id uuid, topic_id uuid)` with `sources text[]` and `reasoning text`.
- **Read-rank quotes:** `essentials.quotes` with `id uuid PK`, `source_url text` (nullable), `quote_text text`, `politician_id uuid`, `topic_key text`.

The verification table uses separate columns (`politician_id`, `topic_id`, `quote_id`) rather than a generic `entity_id` to preserve real FK integrity and make queries readable.

## File Structure

**New files:**
- `ev-accounts/backend/migrations/070_source_verifications.sql` — table + indexes
- `ev-accounts/backend/scripts/backfillSourceVerifications.ts` — one-time seed script
- `ev-accounts/backend/src/lib/sourceVerificationService.ts` — service layer (CRUD + domain trust)
- `ev-accounts/backend/src/routes/sourceVerifications.ts` — admin routes
- `ev-accounts/tests/integration/source-verifications.test.ts` — 401 enforcement + zod validation tests
- `.claude/skills/verify-sources/SKILL.md` — skill definition

**Modified files:**
- `ev-accounts/backend/src/index.ts` — wire new router at `/api/admin/source-verifications`

---

### Task 1: Migration — create `source_verifications` table

**Files:**
- Create: `ev-accounts/backend/migrations/070_source_verifications.sql`

- [ ] **Step 1: Write migration SQL**

```sql
-- 070_source_verifications.sql
-- Per-URL verification tracking for compass stance sources and read-rank quote sources.
-- Shared audit trail table; feeds both the verify-sources skill and the admin review UI.

CREATE TABLE IF NOT EXISTS public.source_verifications (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type      text NOT NULL CHECK (entity_type IN ('compass_stance', 'readrank_quote')),

  -- Entity references (nullable; populated based on entity_type)
  politician_id    uuid NOT NULL,
  topic_id         uuid NULL,            -- compass only
  quote_id         uuid NULL,            -- readrank only
  url_index        int  NOT NULL DEFAULT 0, -- position in sources[] array; 0 for readrank

  url              text NOT NULL,

  status           text NOT NULL DEFAULT 'unverified'
                     CHECK (status IN ('unverified','verified','needs_review')),
  verified_at      timestamptz NULL,
  verified_by      text NULL,            -- 'auto' or a user uuid as text
  notes            text NULL,
  replacement_url  text NULL,
  original_url     text NULL,
  http_status      int  NULL,
  unfixable        boolean NOT NULL DEFAULT false,

  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),

  -- Integrity: ensure the right foreign-key column is populated for each type
  CONSTRAINT source_verifications_entity_shape CHECK (
    (entity_type = 'compass_stance' AND topic_id IS NOT NULL AND quote_id IS NULL)
    OR
    (entity_type = 'readrank_quote' AND quote_id IS NOT NULL AND topic_id IS NULL)
  )
);

-- One verification row per (entity, url position).
-- For compass: (politician_id, topic_id, url_index) uniquely identifies a source slot.
-- For readrank: (quote_id, url_index) — url_index is always 0 but included for uniformity.
CREATE UNIQUE INDEX IF NOT EXISTS source_verifications_compass_uniq
  ON public.source_verifications (politician_id, topic_id, url_index)
  WHERE entity_type = 'compass_stance';

CREATE UNIQUE INDEX IF NOT EXISTS source_verifications_readrank_uniq
  ON public.source_verifications (quote_id, url_index)
  WHERE entity_type = 'readrank_quote';

CREATE INDEX IF NOT EXISTS source_verifications_status_idx
  ON public.source_verifications (status, created_at);

CREATE INDEX IF NOT EXISTS source_verifications_url_idx
  ON public.source_verifications (url);

-- updated_at trigger
CREATE OR REPLACE FUNCTION public.touch_source_verifications_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_touch_source_verifications ON public.source_verifications;
CREATE TRIGGER trg_touch_source_verifications
  BEFORE UPDATE ON public.source_verifications
  FOR EACH ROW
  EXECUTE FUNCTION public.touch_source_verifications_updated_at();
```

- [ ] **Step 2: Apply migration to dev Supabase project**

The project uses a dev Supabase project (`EV-Backend-Dev`, id `mzuppdqbibqjedmesbmp`). Apply the migration via the existing pattern:

```bash
cd ev-accounts/backend
npx tsx scripts/applyMigrations.ts --file migrations/070_source_verifications.sql --project dev
```

Expected: migration completes, `source_verifications` table exists.

If `applyMigrations.ts` does not accept these flags, inspect it and adapt — the goal is to run the SQL against dev. Do NOT apply to production yet.

- [ ] **Step 3: Verify table shape**

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const { rows } = await pool.query(\`
  SELECT column_name, data_type, is_nullable
  FROM information_schema.columns
  WHERE table_schema='public' AND table_name='source_verifications'
  ORDER BY ordinal_position;
\`);
console.table(rows);
await pool.end();
"
```

Expected: 14 columns present, including `entity_type`, `politician_id`, `topic_id`, `quote_id`, `url`, `status`, `url_index`.

- [ ] **Step 4: Commit**

```bash
git add ev-accounts/backend/migrations/070_source_verifications.sql
git commit -m "feat(source-verif): add source_verifications table (migration 070)"
```

---

### Task 2: Service layer — types and read helpers

**Files:**
- Create: `ev-accounts/backend/src/lib/sourceVerificationService.ts`

- [ ] **Step 1: Write types + list helper**

```typescript
// ev-accounts/backend/src/lib/sourceVerificationService.ts
/**
 * sourceVerificationService — CRUD for public.source_verifications.
 * Shared by the verify-sources skill (via pool queries) and the admin routes.
 */

import { pool } from './db.js';

export type SourceVerificationStatus = 'unverified' | 'verified' | 'needs_review';
export type SourceVerificationEntityType = 'compass_stance' | 'readrank_quote';

export interface SourceVerification {
  id: string;
  entity_type: SourceVerificationEntityType;
  politician_id: string;
  topic_id: string | null;
  quote_id: string | null;
  url_index: number;
  url: string;
  status: SourceVerificationStatus;
  verified_at: string | null;
  verified_by: string | null;
  notes: string | null;
  replacement_url: string | null;
  original_url: string | null;
  http_status: number | null;
  unfixable: boolean;
  created_at: string;
  updated_at: string;
}

export interface ListParams {
  status?: SourceVerificationStatus;
  entity_type?: SourceVerificationEntityType;
  limit?: number;
  offset?: number;
  include_unfixable?: boolean;
}

export async function listSourceVerifications(
  params: ListParams
): Promise<{ rows: SourceVerification[]; total: number }> {
  const status = params.status ?? null;
  const entity_type = params.entity_type ?? null;
  const limit = Math.min(params.limit ?? 50, 200);
  const offset = params.offset ?? 0;
  const include_unfixable = params.include_unfixable ?? false;

  const { rows } = await pool.query<SourceVerification>(
    `
    SELECT * FROM public.source_verifications
    WHERE ($1::text IS NULL OR status = $1)
      AND ($2::text IS NULL OR entity_type = $2)
      AND ($3::boolean OR unfixable = false)
    ORDER BY created_at ASC
    LIMIT $4 OFFSET $5
    `,
    [status, entity_type, include_unfixable, limit, offset]
  );

  const { rows: countRows } = await pool.query<{ count: string }>(
    `
    SELECT COUNT(*)::text AS count FROM public.source_verifications
    WHERE ($1::text IS NULL OR status = $1)
      AND ($2::text IS NULL OR entity_type = $2)
      AND ($3::boolean OR unfixable = false)
    `,
    [status, entity_type, include_unfixable]
  );

  return { rows, total: parseInt(countRows[0]?.count ?? '0', 10) };
}

export async function getSourceVerification(id: string): Promise<SourceVerification | null> {
  const { rows } = await pool.query<SourceVerification>(
    'SELECT * FROM public.source_verifications WHERE id = $1',
    [id]
  );
  return rows[0] ?? null;
}
```

- [ ] **Step 2: Add update helpers**

Append to the same file:

```typescript
export interface SkillUpdate {
  status: SourceVerificationStatus;
  notes?: string | null;
  http_status?: number | null;
  replacement_url?: string | null;
  verified_by?: string; // defaults to 'auto'
}

/**
 * Called by the verify-sources skill. Never mutates the underlying compass/readrank
 * source URL — only updates verification status. URL replacement requires human
 * approval via approveSourceVerification().
 */
export async function applySkillResult(
  id: string,
  update: SkillUpdate
): Promise<SourceVerification> {
  const { rows } = await pool.query<SourceVerification>(
    `
    UPDATE public.source_verifications
    SET status = $2,
        notes = $3,
        http_status = $4,
        replacement_url = $5,
        verified_by = COALESCE($6, 'auto'),
        verified_at = CASE WHEN $2 = 'unverified' THEN NULL ELSE now() END
    WHERE id = $1
    RETURNING *
    `,
    [
      id,
      update.status,
      update.notes ?? null,
      update.http_status ?? null,
      update.replacement_url ?? null,
      update.verified_by ?? 'auto',
    ]
  );
  if (!rows[0]) throw new Error(`source_verification ${id} not found`);
  return rows[0];
}

/**
 * Approve current URL (no replacement) or approve a replacement URL.
 * If a new URL is supplied AND differs from current, swap it into the underlying
 * compass sources[] array or essentials.quotes.source_url, preserving original_url.
 */
export async function approveSourceVerification(
  id: string,
  actorUserId: string,
  newUrl?: string
): Promise<SourceVerification> {
  const existing = await getSourceVerification(id);
  if (!existing) throw new Error(`source_verification ${id} not found`);

  const shouldReplace = !!newUrl && newUrl !== existing.url;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    if (shouldReplace) {
      if (existing.entity_type === 'compass_stance') {
        // Replace sources[url_index] in inform.politician_context
        await client.query(
          `
          UPDATE inform.politician_context
          SET sources[$3::int + 1] = $4
          WHERE politician_id = $1 AND topic_id = $2
          `,
          [existing.politician_id, existing.topic_id, existing.url_index, newUrl]
        );
      } else {
        // readrank_quote — single source_url column
        await client.query(
          `UPDATE essentials.quotes SET source_url = $2 WHERE id = $1`,
          [existing.quote_id, newUrl]
        );
      }
    }

    const { rows } = await client.query<SourceVerification>(
      `
      UPDATE public.source_verifications
      SET status = 'verified',
          verified_at = now(),
          verified_by = $2,
          url = COALESCE($3, url),
          original_url = CASE WHEN $3 IS NOT NULL AND $3 <> url THEN url ELSE original_url END,
          replacement_url = NULL,
          unfixable = false
      WHERE id = $1
      RETURNING *
      `,
      [id, actorUserId, shouldReplace ? newUrl : null]
    );

    await client.query('COMMIT');
    return rows[0]!;
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

export async function markUnfixable(
  id: string,
  actorUserId: string,
  note?: string
): Promise<SourceVerification> {
  const { rows } = await pool.query<SourceVerification>(
    `
    UPDATE public.source_verifications
    SET unfixable = true,
        verified_by = $2,
        notes = COALESCE($3, notes)
    WHERE id = $1
    RETURNING *
    `,
    [id, actorUserId, note ?? null]
  );
  if (!rows[0]) throw new Error(`source_verification ${id} not found`);
  return rows[0];
}

/**
 * Trusted-domain guardrail for the skill. Returns true if at least one URL
 * from the same host has already reached status='verified'.
 */
export async function isDomainTrusted(url: string): Promise<boolean> {
  let host: string;
  try {
    host = new URL(url).host.toLowerCase();
  } catch {
    return false;
  }
  const { rows } = await pool.query<{ count: string }>(
    `
    SELECT COUNT(*)::text AS count
    FROM public.source_verifications
    WHERE status = 'verified'
      AND lower(split_part(regexp_replace(url, '^https?://', ''), '/', 1)) = $1
    LIMIT 1
    `,
    [host]
  );
  return parseInt(rows[0]?.count ?? '0', 10) > 0;
}
```

- [ ] **Step 3: Typecheck**

```bash
cd ev-accounts/backend && npm run typecheck
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add ev-accounts/backend/src/lib/sourceVerificationService.ts
git commit -m "feat(source-verif): add sourceVerificationService (CRUD + domain trust)"
```

---

### Task 3: Admin routes

**Files:**
- Create: `ev-accounts/backend/src/routes/sourceVerifications.ts`
- Modify: `ev-accounts/backend/src/index.ts`

- [ ] **Step 1: Write route file**

```typescript
// ev-accounts/backend/src/routes/sourceVerifications.ts
/**
 * /api/admin/source-verifications/* — admin-only verification queue routes.
 *
 * Pattern (matches admin.ts):
 *   router.use(requireAuth, requireAdmin) applies both globally.
 *   Every mutation calls logAdminAction() before returning 200.
 */

import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import { logAdminAction } from '../lib/adminService.js';
import {
  listSourceVerifications,
  approveSourceVerification,
  markUnfixable,
} from '../lib/sourceVerificationService.js';

const router = Router();
router.use(requireAuth, requireAdmin);

// GET /api/admin/source-verifications
const listQuerySchema = z.object({
  status: z.enum(['unverified', 'verified', 'needs_review']).optional(),
  entity_type: z.enum(['compass_stance', 'readrank_quote']).optional(),
  limit: z.coerce.number().int().min(1).max(200).optional(),
  offset: z.coerce.number().int().min(0).optional(),
  include_unfixable: z.coerce.boolean().optional(),
});

router.get('/', async (req: Request, res: Response): Promise<void> => {
  const parsed = listQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.issues });
    return;
  }
  const result = await listSourceVerifications(parsed.data);
  res.json(result);
});

// POST /api/admin/source-verifications/:id/approve
const approveBodySchema = z.object({
  url: z.string().url().optional(),
});

router.post('/:id/approve', async (req: Request, res: Response): Promise<void> => {
  const authReq = req as AuthenticatedRequest;
  const parsed = approveBodySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.issues });
    return;
  }
  const { id } = req.params;
  if (!id) { res.status(400).json({ error: 'id required' }); return; }

  try {
    const updated = await approveSourceVerification(id, authReq.user.id, parsed.data.url);
    await logAdminAction(
      authReq.user.id,
      'source_verification.approve',
      null,
      { verification_id: id, new_url: parsed.data.url ?? null }
    );
    res.json(updated);
  } catch (e) {
    const msg = e instanceof Error ? e.message : 'internal error';
    res.status(msg.includes('not found') ? 404 : 500).json({ error: msg });
  }
});

// POST /api/admin/source-verifications/:id/unfixable
const unfixableBodySchema = z.object({
  note: z.string().max(1000).optional(),
});

router.post('/:id/unfixable', async (req: Request, res: Response): Promise<void> => {
  const authReq = req as AuthenticatedRequest;
  const parsed = unfixableBodySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.issues });
    return;
  }
  const { id } = req.params;
  if (!id) { res.status(400).json({ error: 'id required' }); return; }

  try {
    const updated = await markUnfixable(id, authReq.user.id, parsed.data.note);
    await logAdminAction(
      authReq.user.id,
      'source_verification.unfixable',
      null,
      { verification_id: id, note: parsed.data.note ?? null }
    );
    res.json(updated);
  } catch (e) {
    const msg = e instanceof Error ? e.message : 'internal error';
    res.status(msg.includes('not found') ? 404 : 500).json({ error: msg });
  }
});

export default router;
```

- [ ] **Step 2: Wire into index.ts**

Find the line in `ev-accounts/backend/src/index.ts` where the admin router is mounted (search for `/api/admin`). Add next to it:

```typescript
import sourceVerificationsRouter from './routes/sourceVerifications.js';
// ... near other app.use('/api/admin/...') lines:
app.use('/api/admin/source-verifications', sourceVerificationsRouter);
```

Verify you found the right spot by running:

```bash
grep -n "app.use('/api/admin" ev-accounts/backend/src/index.ts
```

Place the new `app.use` line adjacent to existing `/api/admin/...` mounts.

- [ ] **Step 3: Typecheck**

```bash
cd ev-accounts/backend && npm run typecheck
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add ev-accounts/backend/src/routes/sourceVerifications.ts ev-accounts/backend/src/index.ts
git commit -m "feat(source-verif): add admin routes (list/approve/unfixable)"
```

---

### Task 4: Route auth tests

**Files:**
- Create: `ev-accounts/tests/integration/source-verifications.test.ts`

- [ ] **Step 1: Write failing test**

```typescript
// ev-accounts/tests/integration/source-verifications.test.ts
import { describe, it, expect, beforeAll } from 'vitest';
import request from 'supertest';
import type { Express } from 'express';

process.env['NODE_ENV'] = 'test';
process.env['SUPABASE_URL'] = 'https://test.supabase.co';
process.env['SUPABASE_ANON_KEY'] = 'test-anon-key';
process.env['SUPABASE_SERVICE_ROLE_KEY'] = 'test-service-role-key';
process.env['DATABASE_URL'] = 'postgresql://postgres:password@localhost:5432/postgres';

let app: Express;

beforeAll(async () => {
  const mod = await import('../../backend/src/index.js');
  app = mod.app;
});

describe('Admin source-verifications routes — 401 enforcement', () => {
  it('GET /api/admin/source-verifications requires auth', async () => {
    const res = await request(app).get('/api/admin/source-verifications');
    expect(res.status).toBe(401);
  });

  it('POST /api/admin/source-verifications/:id/approve requires auth', async () => {
    const res = await request(app)
      .post('/api/admin/source-verifications/00000000-0000-0000-0000-000000000000/approve')
      .send({});
    expect(res.status).toBe(401);
  });

  it('POST /api/admin/source-verifications/:id/unfixable requires auth', async () => {
    const res = await request(app)
      .post('/api/admin/source-verifications/00000000-0000-0000-0000-000000000000/unfixable')
      .send({});
    expect(res.status).toBe(401);
  });
});
```

- [ ] **Step 2: Run tests**

```bash
cd ev-accounts && npx vitest run tests/integration/source-verifications.test.ts
```

Expected: 3 tests PASS. (If routes aren't wired, they'll fail with 404 — fix Task 3 wiring.)

- [ ] **Step 3: Commit**

```bash
git add ev-accounts/tests/integration/source-verifications.test.ts
git commit -m "test(source-verif): add route auth enforcement tests"
```

---

### Task 5: Backfill script

**Files:**
- Create: `ev-accounts/backend/scripts/backfillSourceVerifications.ts`

- [ ] **Step 1: Write script**

```typescript
// ev-accounts/backend/scripts/backfillSourceVerifications.ts
/**
 * Seed public.source_verifications from existing data.
 *
 * Walks every compass stance (inform.politician_context rows with non-empty sources[])
 * and every read-rank quote (essentials.quotes with non-null source_url), inserting
 * one verification row per URL with status='unverified'.
 *
 * Idempotent: uses ON CONFLICT DO NOTHING on the unique partial indexes.
 *
 * Usage:
 *   npx tsx scripts/backfillSourceVerifications.ts --dry-run
 *   npx tsx scripts/backfillSourceVerifications.ts
 */

import { pool } from '../src/lib/db.js';

const dryRun = process.argv.includes('--dry-run');

async function main() {
  console.log(`[backfill] mode: ${dryRun ? 'DRY-RUN' : 'WRITE'}`);

  // ---- Compass stances ----
  const { rows: compassRows } = await pool.query<{
    politician_id: string;
    topic_id: string;
    sources: string[] | null;
  }>(
    `SELECT politician_id, topic_id, sources
     FROM inform.politician_context
     WHERE sources IS NOT NULL AND array_length(sources, 1) > 0`
  );
  console.log(`[backfill] compass rows: ${compassRows.length}`);

  let compassInserted = 0;
  let compassSkipped = 0;
  for (const r of compassRows) {
    for (let i = 0; i < (r.sources ?? []).length; i++) {
      const url = (r.sources ?? [])[i];
      if (!url || url.trim() === '') { compassSkipped++; continue; }
      if (dryRun) { compassInserted++; continue; }
      await pool.query(
        `
        INSERT INTO public.source_verifications
          (entity_type, politician_id, topic_id, url_index, url, status)
        VALUES ('compass_stance', $1, $2, $3, $4, 'unverified')
        ON CONFLICT DO NOTHING
        `,
        [r.politician_id, r.topic_id, i, url.trim()]
      );
      compassInserted++;
    }
  }

  // ---- Read-rank quotes ----
  const { rows: quoteRows } = await pool.query<{
    id: string;
    politician_id: string;
    source_url: string | null;
  }>(
    `SELECT id, politician_id, source_url
     FROM essentials.quotes
     WHERE source_url IS NOT NULL AND source_url <> ''`
  );
  console.log(`[backfill] readrank rows: ${quoteRows.length}`);

  let quoteInserted = 0;
  for (const q of quoteRows) {
    if (dryRun) { quoteInserted++; continue; }
    await pool.query(
      `
      INSERT INTO public.source_verifications
        (entity_type, politician_id, quote_id, url_index, url, status)
      VALUES ('readrank_quote', $1, $2, 0, $3, 'unverified')
      ON CONFLICT DO NOTHING
      `,
      [q.politician_id, q.id, q.source_url!.trim()]
    );
    quoteInserted++;
  }

  console.log(`[backfill] done.`);
  console.log(`  compass: ${compassInserted} urls queued, ${compassSkipped} empty skipped`);
  console.log(`  readrank: ${quoteInserted} urls queued`);

  await pool.end();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
```

- [ ] **Step 2: Dry-run**

```bash
cd ev-accounts/backend && set -a && source .env && set +a && npx tsx scripts/backfillSourceVerifications.ts --dry-run
```

Expected: prints counts, writes nothing. Verify counts look reasonable (hundreds expected per user).

- [ ] **Step 3: Real run (dev database only for now)**

```bash
cd ev-accounts/backend && set -a && source .env && set +a && npx tsx scripts/backfillSourceVerifications.ts
```

Expected: same counts, rows now exist.

- [ ] **Step 4: Verify counts**

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const { rows } = await pool.query(\`
  SELECT entity_type, status, count(*)::int
  FROM public.source_verifications
  GROUP BY 1,2 ORDER BY 1,2
\`);
console.table(rows);
await pool.end();
"
```

Expected: all rows have status='unverified'; counts match dry-run output.

- [ ] **Step 5: Commit**

```bash
git add ev-accounts/backend/scripts/backfillSourceVerifications.ts
git commit -m "feat(source-verif): add backfill script for existing sources"
```

---

### Task 6: `verify-sources` skill

**Files:**
- Create: `.claude/skills/verify-sources/SKILL.md`

- [ ] **Step 1: Write skill file**

```markdown
---
name: verify-sources
description: "Verify source URLs attached to compass stances and read-rank quotes. Fetches each URL, checks whether the page supports the blurb/quote, and flags ambiguous or broken sources for human review. Triggers on: 'verify sources', 'check source urls', 'audit sources', 'source verification'."
argument-hint: "[--limit N] [--type compass|readrank|all] [--dry-run]"
---

# /verify-sources — Source URL Verification

You are running the **verify-sources** skill. You will process a batch of source URLs that have not yet been verified, classify each one, and write results back to Supabase.

---

## STEP 0 — Parse `$ARGUMENTS`

Defaults:
- `--limit 20`
- `--type all` (compass + readrank)
- `--dry-run` false

Accept these flags in any order. Ignore unknown flags with a warning.

## STEP 1 — Pull unverified rows

Run this inside `ev-accounts/backend` (env needs to be loaded):

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const LIMIT = <LIMIT>;
const TYPE = '<TYPE>'; // 'compass_stance' | 'readrank_quote' | null
const { rows } = await pool.query(\`
  SELECT sv.id, sv.entity_type, sv.politician_id, sv.topic_id, sv.quote_id,
         sv.url_index, sv.url,
         p.full_name AS politician_name,
         ct.short_title AS topic_title,
         pc.reasoning AS compass_reasoning,
         q.quote_text AS quote_text
  FROM public.source_verifications sv
  LEFT JOIN essentials.politicians p ON p.id = sv.politician_id
  LEFT JOIN inform.compass_topics ct ON ct.id = sv.topic_id
  LEFT JOIN inform.politician_context pc
    ON pc.politician_id = sv.politician_id AND pc.topic_id = sv.topic_id
  LEFT JOIN essentials.quotes q ON q.id = sv.quote_id
  WHERE sv.status = 'unverified'
    AND (\$1::text IS NULL OR sv.entity_type = \$1)
  ORDER BY sv.created_at ASC
  LIMIT \$2
\`, [TYPE === 'all' ? null : TYPE, LIMIT]);
console.log(JSON.stringify(rows, null, 2));
await pool.end();
"
```

Replace `<LIMIT>` and `<TYPE>` with parsed values. If the query returns zero rows, print "Nothing to verify." and exit.

## STEP 2 — For each row, classify

Process sequentially. For each row:

### 2a. Fetch the URL

Use `WebFetch` with the row's `url` and a prompt like:
> "Return (1) the page's HTTP status (if inferable), (2) the main title, (3) a summary of what the page says, and (4) whether the page contains any verbatim quote from [politician_name] or any clear statement of their position on [topic_title / quote_text]."

If `WebFetch` returns an error (DNS failure, 4xx, 5xx, timeout, blocked): treat as **broken**. Go to 2c.

### 2b. URL loaded — check content

Judge whether the page content clearly supports the blurb:
- **For compass**: Does the page contain a direct statement that supports `compass_reasoning`? The blurb must be traceable to the page, not paraphrased to the point of being speculative.
- **For readrank**: Does the page contain the verbatim `quote_text` (or near-verbatim with trivial whitespace/punctuation differences)?

Then check:
- **Is the domain reputable?** News orgs (nytimes.com, apnews.com, local newspapers), .gov, official campaign sites, verified social profiles (Twitter/X verified, Instagram verified), C-SPAN, Congress.gov. Blogs, Reddit, unverified social, aggregators, Wikipedia quoting other sources → NOT reputable.
- **Is the domain trusted** (has at least one other URL from the same host already `verified`)? Query:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { isDomainTrusted } from './src/lib/sourceVerificationService.js';
console.log(await isDomainTrusted('<URL>'));
process.exit(0);
"
```

**Auto-verify ONLY IF all three hold:**
1. Content clearly supports blurb
2. Domain is reputable
3. Domain is trusted (seen verified before)

Otherwise → `needs_review` with a one-line reason in `notes`.

### 2c. URL broken — look for replacement

Use `WebSearch` with a query like:
> `<politician_name> "<short phrase from blurb>" site:*.gov OR site:*.org`

Then a second, less-restrictive query if nothing good:
> `<politician_name> <blurb keywords>`

For the top 3-5 results, read each briefly with `WebFetch` and check: does any result contain verbatim support + come from a reputable domain?

**Never auto-apply a replacement.** If you find a strong candidate, record it in `replacement_url` with status `needs_review` and a note like "broken; replacement candidate found at <domain>". If nothing good is found, status `needs_review` with note "broken; no replacement found".

### 2d. Write back

If `--dry-run`, print the decision and continue. Otherwise:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { applySkillResult } from './src/lib/sourceVerificationService.js';
await applySkillResult('<ID>', {
  status: '<STATUS>',
  notes: '<NOTES>',
  http_status: <HTTP_STATUS_OR_null>,
  replacement_url: <REPLACEMENT_OR_null>,
});
process.exit(0);
"
```

Escape single quotes in notes. On exception, catch it, log the error, and continue to the next row (don't crash the run).

## STEP 3 — Summary

At the end, print a table:

```
verified:     N
needs_review: N  (of which M have a replacement candidate)
errors:       N
```

Followed by a list of `needs_review` rows with format:
`- <entity_type> / <politician_name> / <topic_title or quote_text>: <one-line reason>`

## Rules — do not violate

1. Never auto-apply a replacement URL. Replacements always require human approval.
2. Never mark a first-seen domain as `verified` — route to `needs_review` with note "first-seen domain".
3. Never crash the run on a single row error. Log, set status to `needs_review` with note `skill error: <msg>`, continue.
4. Never process rows with status ≠ `unverified`.
5. Sequential processing only. Do not parallelize.
```

Replace `<LIMIT>`, `<TYPE>`, `<URL>`, `<ID>`, `<STATUS>`, `<NOTES>`, `<HTTP_STATUS_OR_null>`, `<REPLACEMENT_OR_null>` at skill-execution time with literal values.

- [ ] **Step 2: Manually validate the skill with a tiny dry-run**

After the backfill has populated rows, invoke the skill in Claude Code:

```
/verify-sources --limit 3 --dry-run
```

Expected: skill pulls 3 rows, fetches them, prints classification decisions, writes nothing. Spot-check: does each decision look reasonable?

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/verify-sources/SKILL.md
git commit -m "feat(source-verif): add verify-sources Claude Code skill"
```

---

### Task 7: Small live run + sanity check

- [ ] **Step 1: Run for real on a small batch**

```
/verify-sources --limit 5
```

- [ ] **Step 2: Inspect results in Supabase**

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const { rows } = await pool.query(\`
  SELECT id, entity_type, url, status, http_status, notes, replacement_url
  FROM public.source_verifications
  WHERE status <> 'unverified'
  ORDER BY updated_at DESC LIMIT 10
\`);
console.table(rows);
await pool.end();
"
```

Expected: 5 rows with status=`verified` or `needs_review`, each with a sensible note. Zero rows with auto-applied replacement URLs.

- [ ] **Step 3: If anything looks wrong, iterate on the skill prompt**

If decisions look wrong (too aggressive auto-verify, bad replacement suggestions, etc.): manually flip the affected rows back to `unverified`, edit the skill file, re-run. Commit skill tweaks as `fix(source-verif): tune skill prompt — <reason>`.

---

## Summary of what's shippable after Plan A

- Backend: migration, service, admin endpoints.
- Data: verification table backfilled from existing sources.
- Skill: `/verify-sources` works inside Claude Code, no API key needed.
- Human review: use Supabase table editor against `public.source_verifications where status='needs_review'` as a stopgap. Plan B replaces this with a proper SPA UI.

## Known deferrals (Plan B scope)

- Admin SPA review page with keyboard shortcuts and per-row focus view.
- In-app diff view of old vs. replacement URLs.
- Bulk operations.
- Ingest-time trigger that auto-inserts `source_verifications` rows for new compass/readrank sources (v1 only does backfill; new sources added after backfill won't be tracked until the next manual backfill run OR Plan B wires service-layer writes).
