# Compass Topic Journal — Phase 1 (accounts) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the accounts half of the per-topic journal — table, attribution resolver, admin write routes and public read routes — so entries can be written before Season 3 opens and Focused Communities can adopt the same API unchanged.

**Architecture:** One table in `inform`, read and written through `pool.query` raw SQL (the pattern `compassService.ts` already uses for `inform` tables that are not in the generated PostgREST types). A **pure** attribution resolver turns an author's tier plus a per-entry preference into a byline string; the service layer supplies the facts, so the rule itself is unit-testable with no database. Public reads and admin writes live in two route files, mirroring the existing `compass.ts` / `compassAdmin.ts` split and the dual-router mount at `/api/compass`.

**Tech Stack:** TypeScript (ESM, `.js` import specifiers), Express 4, `pg` via `lib/db.ts` `pool`, Zod for request validation, Vitest with `vi.hoisted` + `vi.mock('./db.js')` for service tests.

**Spec:** `docs/superpowers/specs/2026-10-13-compass-topic-journal-design.md`

## Global Constraints

- **Migration slot MUST be reserved through the allocator, never counted by hand.** `npm run steward --prefix backend -- slot CC --purpose "..."`. Hand-counting fails the `migration reservations` CI job even when the number is right.
- **`claimed_by` on the reservation must be the commit author's EMAIL** (`chris@empowered.vote`), not their name. A name fails the check with a message that reads like a double-claim.
- **Tier is the existence of a row, never a column.** Empowered = `empower.empowered_profiles` with `is_active = true`. There is no `tier` column anywhere.
- **Never store a rendered name.** The table stores `author_id` and an `attribution` preference. Display name, legal name and tier are all resolved at read time.
- **A Connected author's `real` preference clamps to their handle, always and everywhere.** Only an Empowered author's `real` renders a legal name.
- **Canonical handle is `public.users.display_name`** — 27/27 populated, universal coverage. Not `connect.connected_profiles.display_name`, which exists only for the 12 Connected accounts.
- **Use `pool.query`, not `supabaseAdmin`.** `tests/integration/architecture.test.ts` scans all of `backend/src` and fails any file using `supabaseAdmin` that is not in its `ALLOWED` list. Raw SQL avoids that list entirely; adding to it is not required by this plan and should not be done.
- **Not a forum.** No `parent_id`, no `reply_to`, no reactions, no notifications. Task 6 enforces this.
- **Public read routes use `optionalAuth`** and return identical data to every caller.
- Error bodies follow the existing shape: `{ code: 'INTERNAL_ERROR', message: '...' }`.

## Review Focus

1. **`display_name` NULL or whitespace-only** — a byline must fall back to the team byline, never render `null`, `undefined` or an empty string. Covered in Task 2.
2. **An author who was Empowered at publish time and has since demoted** — the resolver reads tier live, so their byline silently drops from legal name to handle. That is correct (the undertaking ended), and must be pinned so nobody "fixes" it later by denormalising the name into the row. Covered in Task 2.
3. **Draft entries reaching a public read** — the single worst failure here, because an unpublished diary entry is the team thinking out loud. Asserted on the SQL itself in Task 3, not only on a fixture.
4. **`answers_id` pointing at an entry on a different topic** — would splice two topics' threads together. Rejected at write time in Task 5.
5. **No open season and no draft season** — the `season_id` default has nothing to resolve to. The write must fail loudly rather than guess or insert a stale season. Covered in Task 5.

⚠ **There are zero active Empowered accounts in production today.** Every Empowered branch in the resolver is exercised *only* by its unit tests until someone empowers. Treat Task 2's tests as the specification of that behaviour, not as a safety net under working code.

---

## File Structure

| File | Responsibility |
|---|---|
| `backend/migrations/CC_02XX_compass_topic_journal.sql` | enums, table, constraints, indexes, RLS |
| `backend/src/lib/journalAttribution.ts` | **pure** — preference + author facts → byline string |
| `backend/src/lib/journalAttribution.test.ts` | the rule, including both clamps and every fallback |
| `backend/src/lib/compassJournalService.ts` | all SQL: reads, writes, author-fact resolution |
| `backend/src/lib/compassJournalService.test.ts` | query shape + mapping, `pool.query` mocked |
| `backend/src/routes/compassJournal.ts` | public reads, `optionalAuth` |
| `backend/src/routes/compassJournalAdmin.ts` | admin writes, `requireAuth` + `requireAdmin` |
| `backend/src/lib/compassJournalNoForum.test.ts` | the guard that keeps this from becoming a forum |
| `backend/src/index.ts` | mount both routers |

---

### Task 1: Migration — the table

**Files:**
- Create: `backend/migrations/CC_02XX_compass_topic_journal.sql` (XX from the allocator, step 1)

**Interfaces:**
- Consumes: nothing.
- Produces: `inform.compass_topic_journal` with columns `id, topic_id, season_id, kind, title, body, revision_id, answers_id, author_id, attribution, status, published_at, created_at, updated_at`; enums `inform.journal_kind ('watching','changed')`, `inform.journal_attribution ('none','handle','real')`, `inform.journal_status ('draft','published')`.

- [ ] **Step 1: Reserve the slot**

```bash
cd /c/ev-accounts-flagtext
# If DATABASE_URL is unset in this worktree, run the same function through the
# supabase-local MCP instead — it is the production database.
npm run steward --prefix backend -- slot CC --purpose "compass_topic_journal table"
```

Expected: prints a number, e.g. `CC_0236`. Use it for the filename. Confirm the reservation's `claimed_by` is `chris@empowered.vote`.

- [ ] **Step 2: Write the migration**

Create `backend/migrations/CC_02XX_compass_topic_journal.sql`:

```sql
-- CC_02XX — inform.compass_topic_journal: the per-topic designer diary.
--
-- Applies with `DATABASE_URL` (`ev_api`). DDL.
-- Design: docs/superpowers/specs/2026-10-13-compass-topic-journal-design.md
--
-- 🔴 THIS IS NOT A FORUM AND MUST NOT BECOME ONE. The Compass PUBLISHES these
-- entries; Focused Communities will HOST the conversation about them, in its own
-- tables, keyed to these ids. A parent_id or reply_to column here is what losing
-- that decision looks like, and compassJournalNoForum.test.ts fails if one appears.
--
-- 🔴 NO RENDERED NAME IS STORED. The row holds author_id and a PREFERENCE. What a
-- reader sees is resolved at read time from the author's tier, because a Connected
-- author's default is privacy to the world and an Empowered author's is
-- transparency — and either can change after an entry is published.

BEGIN;

CREATE TYPE inform.journal_kind        AS ENUM ('watching', 'changed');
CREATE TYPE inform.journal_attribution AS ENUM ('none', 'handle', 'real');
CREATE TYPE inform.journal_status      AS ENUM ('draft', 'published');

CREATE TABLE inform.compass_topic_journal (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_id      uuid NOT NULL REFERENCES inform.compass_topics(id) ON DELETE CASCADE,
  -- NOT NULL: between seasons this is the season being PREPARED. Season 3 exists
  -- as 'draft' today, so there is always a row to point at.
  season_id     uuid NOT NULL REFERENCES inform.seasons(id),
  kind          inform.journal_kind NOT NULL,

  title         text,
  body          text NOT NULL,

  -- NULL on every 'watching' entry by definition; set when the predicted edit ships.
  revision_id   uuid REFERENCES inform.compass_topic_revisions(id),
  -- The 'watching' entry this one settles. ONE hop only — a chain is a thread.
  answers_id    uuid REFERENCES inform.compass_topic_journal(id),

  author_id     uuid NOT NULL REFERENCES auth.users(id),
  attribution   inform.journal_attribution NOT NULL DEFAULT 'handle',

  status        inform.journal_status NOT NULL DEFAULT 'draft',
  published_at  timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT watching_has_no_revision
    CHECK (kind <> 'watching' OR revision_id IS NULL),
  -- Readers filter on status; this stops the two disagreeing.
  CONSTRAINT published_has_a_timestamp
    CHECK (status <> 'published' OR published_at IS NOT NULL),
  CONSTRAINT body_is_not_blank
    CHECK (btrim(body) <> ''),
  CONSTRAINT answers_is_not_self
    CHECK (answers_id IS NULL OR answers_id <> id)
);

COMMENT ON TABLE inform.compass_topic_journal IS
  'Per-topic public designer diary. NOT a forum: no replies, ever — Focused '
  'Communities hosts discussion in its own tables keyed to these ids.';

-- The only read the public API performs.
CREATE INDEX compass_topic_journal_topic_published_idx
  ON inform.compass_topic_journal (topic_id, published_at DESC)
  WHERE status = 'published';
CREATE INDEX compass_topic_journal_season_idx
  ON inform.compass_topic_journal (season_id);
CREATE INDEX compass_topic_journal_revision_idx
  ON inform.compass_topic_journal (revision_id)
  WHERE revision_id IS NOT NULL;

-- RLS on with NO policy: every read and write goes through the API, as with
-- compass_topic_revisions. This exists so a future accidental grant cannot
-- expose drafts.
ALTER TABLE inform.compass_topic_journal ENABLE ROW LEVEL SECURITY;

COMMIT;
```

- [ ] **Step 3: Apply it and verify the constraints actually bite**

Apply through the supabase-local MCP (`apply_migration`), then run:

```sql
-- must FAIL: watching entries carry no revision
INSERT INTO inform.compass_topic_journal (topic_id, season_id, kind, body, revision_id, author_id)
SELECT p.id, s.id, 'watching', 'probe',
       (SELECT id FROM inform.compass_topic_revisions LIMIT 1),
       (SELECT id FROM auth.users LIMIT 1)
  FROM inform.compass_topics_promoted p, inform.seasons s
 WHERE s.status = 'open' LIMIT 1;
```

Expected: `ERROR: new row ... violates check constraint "watching_has_no_revision"`.

```sql
-- must FAIL: a published row needs a timestamp
INSERT INTO inform.compass_topic_journal (topic_id, season_id, kind, body, author_id, status)
SELECT p.id, s.id, 'changed', 'probe', (SELECT id FROM auth.users LIMIT 1), 'published'
  FROM inform.compass_topics_promoted p, inform.seasons s
 WHERE s.status = 'open' LIMIT 1;
```

Expected: `ERROR: ... violates check constraint "published_has_a_timestamp"`.

A constraint that is never seen to fail has not been tested.

- [ ] **Step 4: Commit**

```bash
git add backend/migrations/CC_02XX_compass_topic_journal.sql
git commit -m "feat(compass): inform.compass_topic_journal table"
```

---

### Task 2: The attribution resolver (pure)

**Files:**
- Create: `backend/src/lib/journalAttribution.ts`
- Test: `backend/src/lib/journalAttribution.test.ts`

**Interfaces:**
- Consumes: nothing — no imports, no database.
- Produces:
  - `type JournalAttribution = 'none' | 'handle' | 'real'`
  - `interface JournalAuthor { displayName: string | null; legalName: string | null; isEmpowered: boolean }`
  - `const TEAM_BYLINE = 'The EmpoweredVote team'`
  - `function resolveByline(attribution: JournalAttribution, author: JournalAuthor): string`

- [ ] **Step 1: Write the failing tests**

Create `backend/src/lib/journalAttribution.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import {
  resolveByline, TEAM_BYLINE,
  type JournalAuthor, type JournalAttribution,
} from './journalAttribution.js';

const connected = (over: Partial<JournalAuthor> = {}): JournalAuthor =>
  ({ displayName: 'riverkeeper', legalName: 'Dana Reyes', isEmpowered: false, ...over });
const empowered = (over: Partial<JournalAuthor> = {}): JournalAuthor =>
  ({ displayName: 'riverkeeper', legalName: 'Dana Reyes', isEmpowered: true, ...over });

describe('resolveByline — the author tier sets the ceiling', () => {
  it('renders the handle for a Connected author who asked for one', () => {
    expect(resolveByline('handle', connected())).toBe('riverkeeper');
  });

  // 🔴 THE RULE THE WHOLE DESIGN RESTS ON. A Connected account's default is
  // privacy to the world. If their legal name rendered here while Focused
  // Communities rendered their handle, the two surfaces together would
  // de-anonymise them — on entries about abortion and the 2020 election.
  it('CLAMPS a Connected author who asked for their real name', () => {
    expect(resolveByline('real', connected())).toBe('riverkeeper');
  });

  // An Empowered account has already published the link between its name and
  // its activity — anyone may view its public compass. Nothing is left to leak,
  // so the preference is honoured.
  it('renders the legal name for an Empowered author who asked for it', () => {
    expect(resolveByline('real', empowered())).toBe('Dana Reyes');
  });

  it('still renders the handle for an Empowered author who asked for one', () => {
    expect(resolveByline('handle', empowered())).toBe('riverkeeper');
  });

  it('renders the team byline when attribution is none, at either tier', () => {
    expect(resolveByline('none', connected())).toBe(TEAM_BYLINE);
    expect(resolveByline('none', empowered())).toBe(TEAM_BYLINE);
  });
});

describe('resolveByline — fallbacks never leak a blank or a null', () => {
  it('falls back to the team byline when the handle is missing', () => {
    expect(resolveByline('handle', connected({ displayName: null }))).toBe(TEAM_BYLINE);
  });

  it('treats a whitespace-only handle as missing', () => {
    expect(resolveByline('handle', connected({ displayName: '   ' }))).toBe(TEAM_BYLINE);
  });

  // legal_name is populated on only 9 of the 12 Connected profiles, so an
  // Empowered author with no legal name on file is reachable, not theoretical.
  it('falls back to the handle when an Empowered author has no legal name', () => {
    expect(resolveByline('real', empowered({ legalName: null }))).toBe('riverkeeper');
  });

  it('falls back to the team byline when an Empowered author has neither', () => {
    expect(resolveByline('real', empowered({ legalName: '', displayName: null })))
      .toBe(TEAM_BYLINE);
  });

  it('never returns an empty string', () => {
    const all: JournalAttribution[] = ['none', 'handle', 'real'];
    for (const a of all) {
      for (const isEmpowered of [true, false]) {
        const out = resolveByline(a, { displayName: null, legalName: null, isEmpowered });
        expect(out.length).toBeGreaterThan(0);
      }
    }
  });
});

// ⚠ PIN THIS, OR SOMEONE WILL "FIX" IT. Tier is read live, so an author who
// demotes after publishing drops from legal name to handle on entries already
// out. That is correct — the undertaking ended — and the alternative is
// denormalising a legal name into the row, which the design forbids.
describe('resolveByline is a function of CURRENT tier, not of publish time', () => {
  it('the same row renders differently once its author demotes', () => {
    const row = { attribution: 'real' as const, displayName: 'riverkeeper', legalName: 'Dana Reyes' };
    expect(resolveByline(row.attribution, { ...row, isEmpowered: true })).toBe('Dana Reyes');
    expect(resolveByline(row.attribution, { ...row, isEmpowered: false })).toBe('riverkeeper');
  });
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd backend && npx vitest run src/lib/journalAttribution.test.ts`
Expected: FAIL — `Failed to resolve import "./journalAttribution.js"`.

- [ ] **Step 3: Write the implementation**

Create `backend/src/lib/journalAttribution.ts`:

```ts
/**
 * Who a journal entry is signed by.
 *
 * 🔴 THE AUTHOR'S TIER SETS THE CEILING; THE ROW ONLY EXPRESSES A PREFERENCE.
 * A Connected account's default is privacy to the world, so its `real`
 * preference is clamped to the handle — always, everywhere, not pending any
 * decision. An Empowered account has traded privacy for transparency and has
 * already published the link between its name and its activity, so there is
 * nothing left to leak and the preference is honoured.
 *
 * ⚠ PURE ON PURPOSE. No database, no imports. The service supplies the facts so
 * the RULE can be tested exhaustively without fixtures — and so a future reader
 * can see the whole policy in twenty lines.
 *
 * ⚠ Zero accounts are Empowered in production today. The Empowered branches
 * here are specified by their tests and by nothing else.
 */

export type JournalAttribution = 'none' | 'handle' | 'real';

export interface JournalAuthor {
  /** public.users.display_name — universal coverage, 27/27 populated. */
  displayName: string | null;
  /** connect.connected_profiles.legal_name — 9 of 12 populated, so often absent. */
  legalName: string | null;
  /** empower.empowered_profiles row exists AND is_active. Never a column. */
  isEmpowered: boolean;
}

export const TEAM_BYLINE = 'The EmpoweredVote team';

/** Trimmed, or null — an empty string is not a name. */
const name = (v: string | null): string | null => {
  const t = typeof v === 'string' ? v.trim() : '';
  return t.length > 0 ? t : null;
};

export function resolveByline(
  attribution: JournalAttribution,
  author: JournalAuthor,
): string {
  const handle = name(author.displayName);

  if (attribution === 'none') return TEAM_BYLINE;
  if (attribution === 'handle') return handle ?? TEAM_BYLINE;

  // 'real' — honoured only for an Empowered author.
  if (!author.isEmpowered) return handle ?? TEAM_BYLINE;
  return name(author.legalName) ?? handle ?? TEAM_BYLINE;
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd backend && npx vitest run src/lib/journalAttribution.test.ts`
Expected: PASS, 11 tests.

- [ ] **Step 5: Commit**

```bash
git add backend/src/lib/journalAttribution.ts backend/src/lib/journalAttribution.test.ts
git commit -m "feat(compass): journal byline resolver, clamped by author tier"
```

---

### Task 3: Service reads

**Files:**
- Create: `backend/src/lib/compassJournalService.ts`
- Test: `backend/src/lib/compassJournalService.test.ts`

**Interfaces:**
- Consumes: `resolveByline`, `TEAM_BYLINE`, `JournalAttribution` from Task 2; `pool` from `./db.js`.
- Produces:
  - `interface JournalEntry { id, topicId, kind, title, body, season: { number, name }, revisionId, answersId, author: { label }, publishedAt }`
  - `async function listTopicJournal(topicId: string): Promise<JournalEntry[]>`
  - `async function listSeasonJournal(seasonNumber: number): Promise<JournalEntry[]>`

- [ ] **Step 1: Write the failing tests**

Create `backend/src/lib/compassJournalService.test.ts`:

```ts
import { describe, it, expect, vi, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));

import { listTopicJournal, listSeasonJournal } from './compassJournalService.js';

beforeEach(() => mockQuery.mockReset());

const row = (over = {}) => ({
  id: 'j1', topic_id: 't1', kind: 'changed', title: 'Why Childcare split',
  body: 'We saw 85 officials...', season_number: 2, season_name: 'Season 2',
  revision_id: 'r9', answers_id: 'j0', published_at: '2026-10-13T00:00:00Z',
  attribution: 'handle', display_name: 'riverkeeper', legal_name: 'Dana Reyes',
  is_empowered: false, ...over,
});

const sql = () => mockQuery.mock.calls[0][0] as string;

describe('listTopicJournal', () => {
  // 🔴 THE WORST FAILURE AVAILABLE HERE. A draft is the team thinking out loud.
  // Asserted on the QUERY, because a fixture that happens to contain no drafts
  // passes against a filter that was deleted.
  it('filters to published in SQL, not in the mapping', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await listTopicJournal('t1');
    expect(sql()).toMatch(/status\s*=\s*'published'/);
  });

  it('returns newest first', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await listTopicJournal('t1');
    expect(sql()).toMatch(/ORDER BY[\s\S]*published_at DESC/);
  });

  // Tier is a row's existence. A query reading a `tier` column would compile,
  // return undefined, and silently clamp every Empowered author to a handle.
  it('derives tier from an empowered_profiles row, never a column', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await listTopicJournal('t1');
    const q = sql();
    expect(q).toContain('empower.empowered_profiles');
    expect(q).toMatch(/is_active/);
    expect(q).not.toMatch(/\btier\b/);
  });

  it('ships a resolved byline and never the raw identity fields', async () => {
    mockQuery.mockResolvedValue({ rows: [row()] });
    const [entry] = await listTopicJournal('t1');

    expect(entry.author).toEqual({ label: 'riverkeeper' });
    expect(JSON.stringify(entry)).not.toContain('Dana Reyes');
    expect(JSON.stringify(entry)).not.toContain('attribution');
  });

  it('clamps a Connected author who asked for their real name', async () => {
    mockQuery.mockResolvedValue({ rows: [row({ attribution: 'real', is_empowered: false })] });
    expect((await listTopicJournal('t1'))[0].author.label).toBe('riverkeeper');
  });

  it('honours an Empowered author who asked for their real name', async () => {
    mockQuery.mockResolvedValue({ rows: [row({ attribution: 'real', is_empowered: true })] });
    expect((await listTopicJournal('t1'))[0].author.label).toBe('Dana Reyes');
  });

  it('maps the season into a nested object', async () => {
    mockQuery.mockResolvedValue({ rows: [row()] });
    expect((await listTopicJournal('t1'))[0].season).toEqual({ number: 2, name: 'Season 2' });
  });

  it('passes the topic id as a parameter, never interpolated', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await listTopicJournal("t1'; DROP TABLE x;--");
    expect(sql()).not.toContain('DROP TABLE');
    expect(mockQuery.mock.calls[0][1]).toEqual(["t1'; DROP TABLE x;--"]);
  });
});

describe('listSeasonJournal', () => {
  it('filters to published and to the season number given', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await listSeasonJournal(3);
    expect(sql()).toMatch(/status\s*=\s*'published'/);
    expect(mockQuery.mock.calls[0][1]).toEqual([3]);
  });
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd backend && npx vitest run src/lib/compassJournalService.test.ts`
Expected: FAIL — cannot resolve `./compassJournalService.js`.

- [ ] **Step 3: Write the implementation**

Create `backend/src/lib/compassJournalService.ts`:

```ts
import { pool } from './db.js';
import { resolveByline, type JournalAttribution } from './journalAttribution.js';

export interface JournalEntry {
  id: string;
  topicId: string;
  kind: 'watching' | 'changed';
  title: string | null;
  body: string;
  season: { number: number; name: string };
  revisionId: string | null;
  answersId: string | null;
  author: { label: string };
  publishedAt: string;
}

interface JournalRow {
  id: string;
  topic_id: string;
  kind: 'watching' | 'changed';
  title: string | null;
  body: string;
  season_number: number;
  season_name: string;
  revision_id: string | null;
  answers_id: string | null;
  published_at: string;
  attribution: JournalAttribution;
  display_name: string | null;
  legal_name: string | null;
  is_empowered: boolean;
}

/**
 * The SELECT every public read shares.
 *
 * 🔴 `status = 'published'` IS NOT OPTIONAL AND IS NOT THE CALLER'S JOB. A draft
 * entry is the team thinking out loud about a question it has not changed yet.
 *
 * 🔴 TIER COMES FROM A ROW'S EXISTENCE. `empower.empowered_profiles` with
 * is_active — there is no tier column in this database, and a query that
 * invented one would return undefined and quietly clamp every Empowered author.
 *
 * The handle comes from public.users (universal coverage) and the legal name
 * from connect.connected_profiles (present on 9 of 12 rows, hence the fallback
 * chain in resolveByline).
 */
const SELECT = `
  SELECT j.id::text, j.topic_id::text, j.kind, j.title, j.body,
         s.number AS season_number, s.name AS season_name,
         j.revision_id::text, j.answers_id::text,
         j.published_at, j.attribution,
         u.display_name,
         cp.legal_name,
         (ep.user_id IS NOT NULL AND ep.is_active) AS is_empowered
    FROM inform.compass_topic_journal j
    JOIN inform.seasons s ON s.id = j.season_id
    LEFT JOIN public.users u  ON u.id  = j.author_id
    LEFT JOIN connect.connected_profiles cp ON cp.user_id = j.author_id
    LEFT JOIN empower.empowered_profiles ep ON ep.user_id = j.author_id
   WHERE j.status = 'published'`;

const toEntry = (r: JournalRow): JournalEntry => ({
  id: r.id,
  topicId: r.topic_id,
  kind: r.kind,
  title: r.title,
  body: r.body,
  season: { number: r.season_number, name: r.season_name },
  revisionId: r.revision_id,
  answersId: r.answers_id,
  // Resolved here and nowhere else. The identity fields never leave this file.
  author: {
    label: resolveByline(r.attribution, {
      displayName: r.display_name,
      legalName: r.legal_name,
      isEmpowered: Boolean(r.is_empowered),
    }),
  },
  publishedAt: r.published_at,
});

export async function listTopicJournal(topicId: string): Promise<JournalEntry[]> {
  const { rows } = await pool.query<JournalRow>(
    `${SELECT} AND j.topic_id = $1 ORDER BY j.published_at DESC`,
    [topicId],
  );
  return rows.map(toEntry);
}

export async function listSeasonJournal(seasonNumber: number): Promise<JournalEntry[]> {
  const { rows } = await pool.query<JournalRow>(
    `${SELECT} AND s.number = $1 ORDER BY j.published_at DESC`,
    [seasonNumber],
  );
  return rows.map(toEntry);
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd backend && npx vitest run src/lib/compassJournalService.test.ts`
Expected: PASS, 9 tests.

- [ ] **Step 5: Commit**

```bash
git add backend/src/lib/compassJournalService.ts backend/src/lib/compassJournalService.test.ts
git commit -m "feat(compass): journal reads, published only, byline resolved server-side"
```

---

### Task 4: Public read routes

**Files:**
- Create: `backend/src/routes/compassJournal.ts`
- Modify: `backend/src/index.ts` (mount)
- Test: `backend/src/routes/compassJournal.test.ts`

**Interfaces:**
- Consumes: `listTopicJournal`, `listSeasonJournal` from Task 3.
- Produces: `GET /api/compass/topics/:topicId/journal`, `GET /api/compass/journal?season=N`.

- [ ] **Step 1: Write the failing tests**

Create `backend/src/routes/compassJournal.test.ts`:

```ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

const { mockTopic, mockSeason } = vi.hoisted(() => ({
  mockTopic: vi.fn(), mockSeason: vi.fn(),
}));
vi.mock('../lib/compassJournalService.js', () => ({
  listTopicJournal: mockTopic, listSeasonJournal: mockSeason,
}));
vi.mock('../middleware/auth.js', () => ({
  optionalAuth: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

import journalRouter from './compassJournal.js';

const app = express();
app.use('/api/compass', journalRouter);

beforeEach(() => { mockTopic.mockReset(); mockSeason.mockReset(); });

describe('GET /compass/topics/:topicId/journal', () => {
  it('returns the entries for that topic', async () => {
    mockTopic.mockResolvedValue([{ id: 'j1', topicId: 't1' }]);
    const res = await request(app).get('/api/compass/topics/t1/journal');
    expect(res.status).toBe(200);
    expect(res.body).toEqual([{ id: 'j1', topicId: 't1' }]);
    expect(mockTopic).toHaveBeenCalledWith('t1');
  });

  it('answers 200 with an empty array for a topic with no entries', async () => {
    mockTopic.mockResolvedValue([]);
    const res = await request(app).get('/api/compass/topics/t-none/journal');
    expect(res.status).toBe(200);
    expect(res.body).toEqual([]);
  });

  it('answers 500 with the house error shape when the service throws', async () => {
    mockTopic.mockRejectedValue(new Error('boom'));
    const res = await request(app).get('/api/compass/topics/t1/journal');
    expect(res.status).toBe(500);
    expect(res.body.code).toBe('INTERNAL_ERROR');
  });
});

describe('GET /compass/journal', () => {
  it('passes the season number through as a number', async () => {
    mockSeason.mockResolvedValue([]);
    const res = await request(app).get('/api/compass/journal?season=3');
    expect(res.status).toBe(200);
    expect(mockSeason).toHaveBeenCalledWith(3);
  });

  it('rejects a non-numeric season with 400 rather than querying', async () => {
    const res = await request(app).get('/api/compass/journal?season=three');
    expect(res.status).toBe(400);
    expect(mockSeason).not.toHaveBeenCalled();
  });

  it('requires the season parameter', async () => {
    const res = await request(app).get('/api/compass/journal');
    expect(res.status).toBe(400);
    expect(mockSeason).not.toHaveBeenCalled();
  });
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd backend && npx vitest run src/routes/compassJournal.test.ts`
Expected: FAIL — cannot resolve `./compassJournal.js`.

- [ ] **Step 3: Write the implementation**

Create `backend/src/routes/compassJournal.ts`:

```ts
/**
 * compassJournal — the public, reader-facing diary.
 *
 * Mounted on the /api/compass prefix alongside compassRouter.
 *
 * Public and unauthenticated by design, the same reasoning compassRevisions
 * gives for its history route: /api/compass/topics is already served
 * anonymously, so gating the transparency surface behind a login hides it from
 * most of the audience it exists for.
 *
 * ⚠ Focused Communities will call these same two routes when it wakes. Nothing
 * here may become Compass-specific.
 */
import { Router, type Request, type Response } from 'express';
import { optionalAuth } from '../middleware/auth.js';
import { listTopicJournal, listSeasonJournal } from '../lib/compassJournalService.js';

const router = Router();

router.get(
  '/topics/:topicId/journal',
  optionalAuth,
  async (req: Request, res: Response): Promise<void> => {
    try {
      res.status(200).json(await listTopicJournal(req.params.topicId));
    } catch (err) {
      console.error('[GET /compass/topics/:topicId/journal] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  },
);

router.get('/journal', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const season = Number(req.query.season);
  if (!Number.isInteger(season)) {
    res.status(400).json({ code: 'BAD_REQUEST', message: 'season must be an integer' });
    return;
  }
  try {
    res.status(200).json(await listSeasonJournal(season));
  } catch (err) {
    console.error('[GET /compass/journal] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
```

- [ ] **Step 4: Mount it**

In `backend/src/index.ts`, beside the existing compass mounts (near line 146-152):

```ts
import compassJournalRouter from './routes/compassJournal.js';
// ...
// Shares the /api/compass prefix, same dual-router pattern as compassAdminRouter.
app.use('/api/compass', compassJournalRouter);
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `cd backend && npx vitest run src/routes/compassJournal.test.ts`
Expected: PASS, 6 tests.

- [ ] **Step 6: Commit**

```bash
git add backend/src/routes/compassJournal.ts backend/src/routes/compassJournal.test.ts backend/src/index.ts
git commit -m "feat(compass): public journal read routes"
```

---

### Task 5: Admin write routes

**Files:**
- Create: `backend/src/routes/compassJournalAdmin.ts`
- Modify: `backend/src/lib/compassJournalService.ts` (append write functions)
- Modify: `backend/src/index.ts` (mount)
- Test: `backend/src/routes/compassJournalAdmin.test.ts`

**Interfaces:**
- Consumes: `pool` from `./db.js`.
- Produces, on `compassJournalService.ts`:
  - `createEntry(input: { topicId, kind, title, body, revisionId, answersId, attribution, seasonId }, authorId: string): Promise<{ id: string }>`
  - `updateEntry(id: string, patch: { title?, body?, attribution? }): Promise<boolean>`
  - `publishEntry(id: string): Promise<boolean>`
  - `deleteDraft(id: string): Promise<boolean>`
  - `resolveDefaultSeasonId(): Promise<string>`
- Routes: `POST /api/admin/compass/topics/:topicId/journal`, `PATCH|DELETE /api/admin/compass/journal/:id`, `POST /api/admin/compass/journal/:id/publish`.

- [ ] **Step 1: Write the failing tests**

Create `backend/src/routes/compassJournalAdmin.test.ts`:

```ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

const h = vi.hoisted(() => ({
  create: vi.fn(), update: vi.fn(), publish: vi.fn(), del: vi.fn(), season: vi.fn(),
}));
vi.mock('../lib/compassJournalService.js', () => ({
  createEntry: h.create, updateEntry: h.update, publishEntry: h.publish,
  deleteDraft: h.del, resolveDefaultSeasonId: h.season,
}));
vi.mock('../middleware/auth.js', () => ({
  requireAuth: (req: any, _res: unknown, next: () => void) => { req.userId = 'u-admin'; next(); },
}));
vi.mock('../middleware/requireAdmin.js', () => ({
  requireAdmin: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

import adminRouter from './compassJournalAdmin.js';

const app = express();
app.use(express.json());
app.use('/api/admin/compass', adminRouter);

beforeEach(() => {
  Object.values(h).forEach((m) => m.mockReset());
  h.season.mockResolvedValue('s-open');
});

describe('POST /topics/:topicId/journal', () => {
  it('creates a draft and takes the author from the session, not the body', async () => {
    h.create.mockResolvedValue({ id: 'j1' });
    const res = await request(app)
      .post('/api/admin/compass/topics/t1/journal')
      .send({ kind: 'watching', body: 'We are watching childcare.', authorId: 'u-someone-else' });

    expect(res.status).toBe(201);
    expect(h.create).toHaveBeenCalledWith(expect.anything(), 'u-admin');
    expect(h.create.mock.calls[0][0]).not.toHaveProperty('authorId');
  });

  it('rejects a watching entry that carries a revision', async () => {
    const res = await request(app)
      .post('/api/admin/compass/topics/t1/journal')
      .send({ kind: 'watching', body: 'x', revisionId: 'r1' });

    expect(res.status).toBe(422);
    expect(h.create).not.toHaveBeenCalled();
  });

  it('rejects a blank body', async () => {
    const res = await request(app)
      .post('/api/admin/compass/topics/t1/journal')
      .send({ kind: 'changed', body: '   ' });
    expect(res.status).toBe(400);
  });

  it('defaults the season when none is given', async () => {
    h.create.mockResolvedValue({ id: 'j1' });
    await request(app).post('/api/admin/compass/topics/t1/journal')
      .send({ kind: 'changed', body: 'shipped' });
    expect(h.create.mock.calls[0][0].seasonId).toBe('s-open');
  });

  // 🔴 A write that guesses a season is worse than one that fails. There is no
  // correct fallback: stamping a closed season backdates the entry.
  it('fails loudly when no open or draft season exists', async () => {
    h.season.mockRejectedValue(new Error('NO_SEASON'));
    const res = await request(app).post('/api/admin/compass/topics/t1/journal')
      .send({ kind: 'changed', body: 'shipped' });
    expect(res.status).toBe(409);
    expect(h.create).not.toHaveBeenCalled();
  });
});

describe('POST /journal/:id/publish', () => {
  it('publishes and answers 200', async () => {
    h.publish.mockResolvedValue(true);
    expect((await request(app).post('/api/admin/compass/journal/j1/publish')).status).toBe(200);
  });

  it('answers 404 for an unknown id', async () => {
    h.publish.mockResolvedValue(false);
    expect((await request(app).post('/api/admin/compass/journal/nope/publish')).status).toBe(404);
  });
});

describe('DELETE /journal/:id', () => {
  it('answers 409 when the entry is published, because published entries are edited', async () => {
    h.del.mockResolvedValue(false);
    const res = await request(app).delete('/api/admin/compass/journal/j1');
    expect([404, 409]).toContain(res.status);
  });
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd backend && npx vitest run src/routes/compassJournalAdmin.test.ts`
Expected: FAIL — cannot resolve `./compassJournalAdmin.js`.

- [ ] **Step 3: Write the failing service tests for the two write-side rules**

Append to `backend/src/lib/compassJournalService.test.ts` (created in Task 3 — its
`vi.mock('./db.js')` covers writes as well as reads):

```ts
import { createEntry, resolveDefaultSeasonId } from './compassJournalService.js';

describe('resolveDefaultSeasonId', () => {
  it('prefers the open season over the draft one', async () => {
    mockQuery.mockResolvedValue({ rows: [{ id: 's-open' }] });
    expect(await resolveDefaultSeasonId()).toBe('s-open');
    expect(mockQuery.mock.calls[0][0]).toMatch(/status IN \('open', 'draft'\)/);
  });

  // 🔴 There is no correct fallback. Stamping a CLOSED season backdates the
  // entry into a season it was not written for, and nothing downstream could
  // tell. Failing is the only honest option.
  it('THROWS rather than stamping a closed season', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await expect(resolveDefaultSeasonId()).rejects.toThrow(/NO_SEASON/);
  });
});

describe('createEntry — answers_id may not cross topics', () => {
  // Without this the two topics' threads splice together and a reader following
  // the link lands on a different question. A CHECK cannot express it: the rule
  // spans two rows.
  it('rejects answering an entry that belongs to another topic', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ topic_id: 't-OTHER' }] });
    await expect(createEntry({
      topicId: 't1', seasonId: 's1', kind: 'changed', title: null, body: 'x',
      revisionId: null, answersId: 'j-elsewhere', attribution: 'handle',
    }, 'u1')).rejects.toThrow(/ANSWERS_WRONG_TOPIC/);
    // and it never reached the INSERT
    expect(mockQuery).toHaveBeenCalledTimes(1);
  });

  it('rejects answering an entry that does not exist', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await expect(createEntry({
      topicId: 't1', seasonId: 's1', kind: 'changed', title: null, body: 'x',
      revisionId: null, answersId: 'j-ghost', attribution: 'handle',
    }, 'u1')).rejects.toThrow(/ANSWERS_WRONG_TOPIC/);
  });

  it('inserts with the author id passed separately from the input', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ id: 'j-new' }] });
    const out = await createEntry({
      topicId: 't1', seasonId: 's1', kind: 'changed', title: null, body: 'x',
      revisionId: null, answersId: null, attribution: 'handle',
    }, 'u-admin');
    expect(out).toEqual({ id: 'j-new' });
    expect(mockQuery.mock.calls[0][1]).toContain('u-admin');
  });
});
```

Run: `cd backend && npx vitest run src/lib/compassJournalService.test.ts`
Expected: FAIL — `createEntry` and `resolveDefaultSeasonId` are not exported yet.

- [ ] **Step 4: Append the write functions to the service**

Append to `backend/src/lib/compassJournalService.ts`:

```ts
export interface CreateEntryInput {
  topicId: string;
  seasonId: string;
  kind: 'watching' | 'changed';
  title: string | null;
  body: string;
  revisionId: string | null;
  answersId: string | null;
  attribution: JournalAttribution;
}

/**
 * The season an entry belongs to when the caller did not name one: the open
 * season, or the one being prepared when none is open.
 *
 * 🔴 THROWS RATHER THAN GUESSING. A closed season is never the answer — stamping
 * one backdates the entry into a season it was not written for, and nothing
 * downstream could tell.
 */
export async function resolveDefaultSeasonId(): Promise<string> {
  const { rows } = await pool.query<{ id: string }>(
    `SELECT id::text FROM inform.seasons
      WHERE status IN ('open', 'draft')
      ORDER BY CASE status WHEN 'open' THEN 0 ELSE 1 END, number DESC
      LIMIT 1`,
  );
  if (rows.length === 0) {
    throw new Error('NO_SEASON: no open or draft season to attach a journal entry to');
  }
  return rows[0].id;
}

/**
 * ⚠ `answers_id` MUST POINT AT AN ENTRY ON THE SAME TOPIC. Without this the two
 * topics' threads splice together and a reader following the link lands on a
 * different question. The CHECK constraint cannot express it (it spans rows), so
 * it lives here, in the one place entries are created.
 */
export async function createEntry(
  input: CreateEntryInput,
  authorId: string,
): Promise<{ id: string }> {
  if (input.answersId) {
    const { rows } = await pool.query<{ topic_id: string }>(
      `SELECT topic_id::text FROM inform.compass_topic_journal WHERE id = $1`,
      [input.answersId],
    );
    if (rows.length === 0 || rows[0].topic_id !== input.topicId) {
      throw new Error('ANSWERS_WRONG_TOPIC: an entry may only answer one on the same topic');
    }
  }

  const { rows } = await pool.query<{ id: string }>(
    `INSERT INTO inform.compass_topic_journal
       (topic_id, season_id, kind, title, body, revision_id, answers_id, author_id, attribution)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
     RETURNING id::text`,
    [input.topicId, input.seasonId, input.kind, input.title, input.body,
     input.revisionId, input.answersId, authorId, input.attribution],
  );
  return { id: rows[0].id };
}

export async function updateEntry(
  id: string,
  patch: { title?: string | null; body?: string; attribution?: JournalAttribution },
): Promise<boolean> {
  const { rowCount } = await pool.query(
    `UPDATE inform.compass_topic_journal
        SET title       = COALESCE($2, title),
            body        = COALESCE($3, body),
            attribution = COALESCE($4, attribution),
            updated_at  = now()
      WHERE id = $1`,
    [id, patch.title ?? null, patch.body ?? null, patch.attribution ?? null],
  );
  return (rowCount ?? 0) > 0;
}

/** Idempotent: re-publishing an already-published entry does not move its date. */
export async function publishEntry(id: string): Promise<boolean> {
  const { rowCount } = await pool.query(
    `UPDATE inform.compass_topic_journal
        SET status = 'published',
            published_at = COALESCE(published_at, now()),
            updated_at = now()
      WHERE id = $1`,
    [id],
  );
  return (rowCount ?? 0) > 0;
}

/** Drafts only. A published entry is corrected, not withdrawn. */
export async function deleteDraft(id: string): Promise<boolean> {
  const { rowCount } = await pool.query(
    `DELETE FROM inform.compass_topic_journal WHERE id = $1 AND status = 'draft'`,
    [id],
  );
  return (rowCount ?? 0) > 0;
}
```

- [ ] **Step 5: Write the admin router**

Create `backend/src/routes/compassJournalAdmin.ts`:

```ts
/**
 * compassJournalAdmin — authoring the diary.
 *
 * Mounted at /api/admin/compass. requireAuth + requireAdmin, the gate every
 * /api/admin/compass/* route already uses.
 *
 * 🔴 author_id COMES FROM THE SESSION AND IS NEVER ACCEPTED FROM THE BODY. The
 * byline is derived from it, so a body-supplied author would let one admin sign
 * an entry in another's name.
 */
import { Router, type Request, type Response } from 'express';
import { z } from 'zod';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import {
  createEntry, updateEntry, publishEntry, deleteDraft, resolveDefaultSeasonId,
} from '../lib/compassJournalService.js';

const router = Router();
router.use(requireAuth as never, requireAdmin as never);

const CreateBody = z.object({
  kind: z.enum(['watching', 'changed']),
  title: z.string().trim().min(1).max(200).nullish(),
  body: z.string().trim().min(1),
  revisionId: z.string().uuid().nullish(),
  answersId: z.string().uuid().nullish(),
  attribution: z.enum(['none', 'handle', 'real']).default('handle'),
  seasonId: z.string().uuid().nullish(),
});

router.post('/topics/:topicId/journal', async (req: Request, res: Response): Promise<void> => {
  const parsed = CreateBody.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ code: 'BAD_REQUEST', message: parsed.error.issues[0].message });
    return;
  }
  const b = parsed.data;

  // Mirrors the watching_has_no_revision CHECK, so the caller gets 422 and a
  // sentence rather than a Postgres constraint name.
  if (b.kind === 'watching' && b.revisionId) {
    res.status(422).json({
      code: 'WATCHING_HAS_NO_REVISION',
      message: 'A watching entry describes a change that has not happened yet.',
    });
    return;
  }

  try {
    const seasonId = b.seasonId ?? (await resolveDefaultSeasonId());
    const out = await createEntry({
      topicId: req.params.topicId,
      seasonId,
      kind: b.kind,
      title: b.title ?? null,
      body: b.body,
      revisionId: b.revisionId ?? null,
      answersId: b.answersId ?? null,
      attribution: b.attribution,
    }, (req as AuthenticatedRequest).userId);
    res.status(201).json(out);
  } catch (err) {
    const msg = err instanceof Error ? err.message : '';
    if (msg.startsWith('NO_SEASON') || msg.startsWith('ANSWERS_WRONG_TOPIC')) {
      res.status(409).json({ code: msg.split(':')[0], message: msg });
      return;
    }
    console.error('[POST /admin/compass/topics/:topicId/journal] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

const PatchBody = z.object({
  title: z.string().trim().min(1).max(200).nullish(),
  body: z.string().trim().min(1).optional(),
  attribution: z.enum(['none', 'handle', 'real']).optional(),
});

router.patch('/journal/:id', async (req: Request, res: Response): Promise<void> => {
  const parsed = PatchBody.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ code: 'BAD_REQUEST', message: parsed.error.issues[0].message });
    return;
  }
  try {
    const ok = await updateEntry(req.params.id, parsed.data);
    res.status(ok ? 200 : 404).json(ok ? { ok: true } : { code: 'NOT_FOUND', message: 'No such entry' });
  } catch (err) {
    console.error('[PATCH /admin/compass/journal/:id] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

router.post('/journal/:id/publish', async (req: Request, res: Response): Promise<void> => {
  try {
    const ok = await publishEntry(req.params.id);
    res.status(ok ? 200 : 404).json(ok ? { ok: true } : { code: 'NOT_FOUND', message: 'No such entry' });
  } catch (err) {
    console.error('[POST /admin/compass/journal/:id/publish] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

router.delete('/journal/:id', async (req: Request, res: Response): Promise<void> => {
  try {
    const ok = await deleteDraft(req.params.id);
    res.status(ok ? 200 : 409).json(ok ? { ok: true } : {
      code: 'NOT_A_DRAFT',
      message: 'Only a draft can be deleted. A published entry is corrected in place.',
    });
  } catch (err) {
    console.error('[DELETE /admin/compass/journal/:id] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
```

- [ ] **Step 6: Mount it**

In `backend/src/index.ts`, beside the other admin mounts:

```ts
import compassJournalAdminRouter from './routes/compassJournalAdmin.js';
// ...
app.use('/api/admin/compass', compassJournalAdminRouter);
```

- [ ] **Step 7: Run the tests to verify they pass**

Run: `cd backend && npx vitest run src/routes/compassJournalAdmin.test.ts src/lib/compassJournalService.test.ts`
Expected: PASS — 8 route tests and 14 service tests (9 from Task 3, 5 added in Step 3).

- [ ] **Step 8: Commit**

```bash
git add backend/src/routes/compassJournalAdmin.ts backend/src/routes/compassJournalAdmin.test.ts \
        backend/src/lib/compassJournalService.ts backend/src/lib/compassJournalService.test.ts \
        backend/src/index.ts
git commit -m "feat(compass): admin journal write routes"
```

---

### Task 6: The no-forum guard

**Files:**
- Create: `backend/src/lib/compassJournalNoForum.test.ts`

**Interfaces:**
- Consumes: the migration file from Task 1 and the service from Tasks 3 and 5, read as text.
- Produces: nothing — a static guard.

- [ ] **Step 1: Write the test**

Create `backend/src/lib/compassJournalNoForum.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const ROOT = new URL('../../', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');
const MIGRATIONS = join(ROOT, 'migrations');

const journalMigration = (): string => {
  const f = readdirSync(MIGRATIONS).find((n) => n.includes('compass_topic_journal'));
  if (!f) throw new Error('no compass_topic_journal migration found');
  return readFileSync(join(MIGRATIONS, f), 'utf8');
};

/**
 * 🔴 THE DECISION THIS PROTECTS, IN FULL, BECAUSE THE FAILURE MESSAGE IS THE
 * ONLY PLACE THE NEXT PERSON WILL READ IT.
 *
 * The Compass PUBLISHES journal entries. Focused Communities HOSTS the
 * conversation about them, in FC's own tables, keyed to these ids. FC is a
 * separate product with moderation, tier gating and pseudonymity rules that
 * this table has none of.
 *
 * Adding replies here is always one small column, and it always arrives with a
 * good reason. That is what losing the decision looks like. If replies are
 * genuinely needed before FC ships, that is a product decision to take
 * deliberately — delete this test in the same commit, and say why.
 */
describe('the journal is not a forum', () => {
  const FORBIDDEN = [
    'parent_id', 'reply_to', 'reply_id', 'in_reply_to',
    'thread_id', 'reaction', 'upvote', 'vote_count', 'comment_count',
  ];

  it('the table has no reply or reaction column', () => {
    const sql = journalMigration().toLowerCase();
    const found = FORBIDDEN.filter((c) => sql.includes(c));
    expect(found, `forbidden column(s) in the journal table: ${found.join(', ')}. ` +
      'The Compass publishes; Focused Communities hosts the conversation. See the ' +
      'header of this test before adding one.').toEqual([]);
  });

  // answers_id is the one self-reference, and it exists so a 'changed' entry can
  // point at the 'watching' entry it settles. Following it more than one hop is a
  // thread by another name.
  it('answers_id is followed at most one hop', () => {
    const svc = readFileSync(join(ROOT, 'src/lib/compassJournalService.ts'), 'utf8');
    expect(svc).not.toMatch(/WITH RECURSIVE/i);
    expect(svc.match(/answers_id/g)?.length ?? 0).toBeLessThanOrEqual(4);
  });

  it('the table still carries its own warning', () => {
    expect(journalMigration()).toMatch(/NOT A FORUM/i);
  });
});
```

- [ ] **Step 2: Run it to verify it passes against the real files**

Run: `cd backend && npx vitest run src/lib/compassJournalNoForum.test.ts`
Expected: PASS, 3 tests.

- [ ] **Step 3: Verify the guard actually bites**

Temporarily add `parent_id uuid,` to the table in the migration file, re-run the test.
Expected: FAIL, naming `parent_id`. **Remove the column again** and re-run; expected PASS.

A guard never seen to fail is not a guard.

- [ ] **Step 4: Full suite, typecheck and lint**

```bash
cd backend
npx tsc --noEmit
npm run test:unit
npm run lint
```

Expected: `tsc` clean. `test:unit` passes with 42 new tests (11 + 14 + 6 + 8 + 3); the pre-existing
`verificationFetch.charset` failure is unrelated and also fails on a clean
`origin/master` checkout — confirm it is the only failure.

- [ ] **Step 5: Commit**

```bash
git add backend/src/lib/compassJournalNoForum.test.ts
git commit -m "test(compass): guard that the journal never becomes a forum"
```

---

## Done when

- `inform.compass_topic_journal` exists in production with all four CHECK constraints verified to fire.
- `GET /api/compass/topics/:topicId/journal` returns `[]` for every topic (no entries written yet) and a resolved `author.label` once one is.
- A Connected author's `real` preference renders their handle; an Empowered author's renders their legal name. Both asserted by unit test, neither yet observable in production, because no account is Empowered.
- The no-forum guard has been seen to fail and then pass.
- Phase 2 (the Compass ⓘ and thread view) is a separate plan.
