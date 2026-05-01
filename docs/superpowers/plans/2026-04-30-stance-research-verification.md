# Stance Research Verification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an automated verification gate between stance research and DB push so hallucinated quotes and irrelevant-article citations are caught before they reach the production tables.

**Architecture:** Three-stage pipeline. (1) The `politician-stance-researcher` agent now emits two CSVs — `stances.csv` (one row per politician+topic) and `evidence.csv` (one row per snippet) — and must capture verbatim snippets for every source. (2) A new deterministic Node verifier (`researchVerifier.ts`) fetches each cited URL, normalizes whitespace/quotes/dashes/case, string-matches the snippet against the page, and confirms the politician's name appears within 500 characters. No LLM in the verification loop. (3) Rows clearing a minimum-source threshold (default 2) push to existing answer/context tables plus a new `politician_context_evidence` table. Rows below threshold get one bounded re-research attempt; if still short, they go to a new `stance_research_review` table.

**Tech Stack:** TypeScript (ev-accounts backend), Vitest, csv-parse, Playwright (existing `fetchPageContent`), Supabase Postgres.

**Reference spec:** `docs/superpowers/specs/2026-04-30-stance-research-verification-design.md`

---

## File Structure

**Created:**
- `ev-accounts/backend/migrations/087_stance_research_verification.sql` — new tables
- `ev-accounts/backend/src/lib/researchVerifier.ts` — deterministic verifier (pure-ish; takes parsed input, calls fetch, returns partitions)
- `ev-accounts/backend/src/lib/researchVerifier.test.ts` — Vitest unit tests
- `ev-accounts/backend/src/lib/__fixtures__/researchVerifier/` — frozen HTML snapshots
- `ev-accounts/backend/src/lib/researchEvidenceService.ts` — DB persistence (evidence + review queue)
- `ev-accounts/backend/src/lib/stanceResearchCsv.ts` — parses + writes the two-CSV format
- `.claude/skills/research-stances/README.md` — durable architecture/decisions doc

**Modified:**
- `.claude/agents/politician-stance-researcher.md` (and `ev-accounts/.claude/agents/politician-stance-researcher.md` mirror) — new CSV format, snippet rule, re-research mode
- `.claude/skills/research-stances/SKILL.md` — STEP 2.5 (verify), updated STEP 3, STEP 4 (evidence persist), STEP 5 (review queue)

**Deferred (separate follow-up work, not in this plan):**
- `/verify-sources` upgrade to prefer stored snippets over LLM page judgment. The current `/verify-sources` references `sourceVerificationService.ts` that lives only in an unmerged worktree; until that lands on main, we cannot edit it cleanly. Note this in the README as a follow-up.

---

## Task 1: Migration — new tables

**Files:**
- Create: `ev-accounts/backend/migrations/087_stance_research_verification.sql`

- [ ] **Step 1: Write the migration SQL**

```sql
-- 087_stance_research_verification.sql
-- New tables for the snippet-based stance research verification pipeline.
-- See docs/superpowers/specs/2026-04-30-stance-research-verification-design.md

BEGIN;

-- Persisted snippets for every successfully-verified (politician, topic, source).
-- Replaced wholesale on re-research/upsert (delete by composite key, then insert).
CREATE TABLE IF NOT EXISTS inform.politician_context_evidence (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  politician_id uuid NOT NULL REFERENCES essentials.politicians(id) ON DELETE CASCADE,
  topic_id uuid NOT NULL REFERENCES inform.compass_topics(id) ON DELETE CASCADE,
  source_url text NOT NULL,
  snippet text NOT NULL,
  snippet_index int NOT NULL,
  verified_at timestamptz NOT NULL DEFAULT now(),
  batch_id text,
  FOREIGN KEY (politician_id, topic_id)
    REFERENCES inform.politician_context(politician_id, topic_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_pce_politician_topic
  ON inform.politician_context_evidence (politician_id, topic_id);
CREATE INDEX IF NOT EXISTS idx_pce_source_url
  ON inform.politician_context_evidence (source_url);

-- Review queue for rows that fail verification after a single re-research attempt.
-- evidence jsonb captures every snippet's verdict and failure reason.
CREATE TABLE IF NOT EXISTS inform.stance_research_review (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id text NOT NULL,
  politician_id uuid REFERENCES essentials.politicians(id),
  full_name_raw text NOT NULL,
  topic_id uuid REFERENCES inform.compass_topics(id),
  topic_key text NOT NULL,
  proposed_value smallint,
  proposed_reasoning text,
  evidence jsonb NOT NULL,
  verified_source_count int NOT NULL,
  threshold int NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  re_research_attempted boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  resolved_at timestamptz,
  resolved_by uuid,
  notes text,
  CONSTRAINT srr_status_check CHECK (status IN
    ('pending','resolved','rejected','superseded','unresolved_politician'))
);

CREATE INDEX IF NOT EXISTS idx_srr_status_batch
  ON inform.stance_research_review (status, batch_id);
CREATE INDEX IF NOT EXISTS idx_srr_politician_topic
  ON inform.stance_research_review (politician_id, topic_id);

-- Idempotent upsert key for re-runs of the same batch.
CREATE UNIQUE INDEX IF NOT EXISTS uq_srr_batch_pol_topic
  ON inform.stance_research_review (batch_id, COALESCE(politician_id::text, full_name_raw), topic_key);

COMMIT;
```

- [ ] **Step 2: Apply migration to dev DB**

Run from `ev-accounts/backend`:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && \
  psql "$DATABASE_URL" -f migrations/087_stance_research_verification.sql
```

Expected: `BEGIN`, `CREATE TABLE`, `CREATE INDEX` lines, `COMMIT`. No errors.

- [ ] **Step 3: Verify tables exist**

```bash
cd ev-accounts/backend && set -a && source .env && set +a && \
  psql "$DATABASE_URL" -c "\d inform.politician_context_evidence" \
                       -c "\d inform.stance_research_review"
```

Expected: both tables print their schemas. Confirm `evidence` is `jsonb`, `status` has the CHECK, indexes exist.

- [ ] **Step 4: Commit**

```bash
git add ev-accounts/backend/migrations/087_stance_research_verification.sql
git commit -m "feat(stance-research): migration for evidence + review queue tables"
```

---

## Task 2: Verifier — text normalization

**Files:**
- Create: `ev-accounts/backend/src/lib/researchVerifier.ts`
- Create: `ev-accounts/backend/src/lib/researchVerifier.test.ts`

- [ ] **Step 1: Write the failing test for normalization**

Create `ev-accounts/backend/src/lib/researchVerifier.test.ts`:

```typescript
import { describe, it, expect } from 'vitest';
import { normalizeText } from './researchVerifier.js';

describe('normalizeText', () => {
  it('collapses whitespace to single spaces', () => {
    expect(normalizeText('a  b\nc\t\td')).toBe('a b c d');
  });

  it('lowercases', () => {
    expect(normalizeText('Hello WORLD')).toBe('hello world');
  });

  it('normalizes curly quotes to straight quotes', () => {
    expect(normalizeText('“hello” ‘world’')).toBe('"hello" \'world\'');
  });

  it('normalizes em and en dashes to hyphens', () => {
    expect(normalizeText('a—b–c')).toBe('a-b-c');
  });

  it('decodes common HTML entities', () => {
    expect(normalizeText('a &amp; b &nbsp; c &quot;d&quot;')).toBe('a & b c "d"');
  });

  it('trims leading and trailing whitespace', () => {
    expect(normalizeText('   hi   ')).toBe('hi');
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd ev-accounts/backend && npx vitest run src/lib/researchVerifier.test.ts
```

Expected: FAIL — `Cannot find module './researchVerifier.js'`.

- [ ] **Step 3: Implement normalizeText**

Create `ev-accounts/backend/src/lib/researchVerifier.ts`:

```typescript
/**
 * researchVerifier — deterministic verification of stance-research evidence.
 *
 * Pipeline: parsed CSVs → fetch each source URL → for each snippet, check it
 * appears verbatim on the page (after normalization) and the politician's
 * name appears within 500 characters of the match. No LLM involved.
 *
 * See docs/superpowers/specs/2026-04-30-stance-research-verification-design.md
 */

const HTML_ENTITIES: Record<string, string> = {
  '&amp;': '&',
  '&lt;': '<',
  '&gt;': '>',
  '&quot;': '"',
  '&apos;': "'",
  '&nbsp;': ' ',
  '&#39;': "'",
};

export function normalizeText(input: string): string {
  let out = input;
  // HTML entities first (before quote normalization, since &quot; → ")
  for (const [entity, replacement] of Object.entries(HTML_ENTITIES)) {
    out = out.split(entity).join(replacement);
  }
  // Curly quotes → straight quotes
  out = out
    .replace(/[“”]/g, '"')
    .replace(/[‘’]/g, "'");
  // Em / en dashes → hyphen
  out = out.replace(/[—–]/g, '-');
  // Lowercase
  out = out.toLowerCase();
  // Collapse all whitespace runs to single space
  out = out.replace(/\s+/g, ' ');
  // Trim
  return out.trim();
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd ev-accounts/backend && npx vitest run src/lib/researchVerifier.test.ts
```

Expected: PASS — 6 tests passing.

- [ ] **Step 5: Commit**

```bash
git add ev-accounts/backend/src/lib/researchVerifier.ts \
        ev-accounts/backend/src/lib/researchVerifier.test.ts
git commit -m "feat(stance-research): text normalization for verifier"
```

---

## Task 3: Verifier — snippet match

**Files:**
- Modify: `ev-accounts/backend/src/lib/researchVerifier.ts`
- Modify: `ev-accounts/backend/src/lib/researchVerifier.test.ts`

- [ ] **Step 1: Write the failing tests for snippet matching**

Append to `researchVerifier.test.ts`:

```typescript
import { matchSnippet, MIN_SNIPPET_WORDS } from './researchVerifier.js';

describe('matchSnippet', () => {
  const longSnippet = 'The senator strongly supports a public option for healthcare and has cosponsored multiple bills since 2021 to expand Medicare access for older Americans without raising taxes on the middle class.';

  it('returns verified for a verbatim match', () => {
    const page = `Some article text. ${longSnippet} More article text.`;
    expect(matchSnippet(longSnippet, page)).toEqual({ verdict: 'verified' });
  });

  it('returns verified despite whitespace differences', () => {
    const page = `prefix ${longSnippet.replace(/ /g, '\n  ')} suffix`;
    expect(matchSnippet(longSnippet, page)).toEqual({ verdict: 'verified' });
  });

  it('returns verified despite curly quote differences', () => {
    const snippetCurly = longSnippet.replace('public option', '“public option”');
    const pageStraight = `prefix ${longSnippet.replace('public option', '"public option"')} suffix`;
    expect(matchSnippet(snippetCurly, pageStraight)).toEqual({ verdict: 'verified' });
  });

  it('returns snippet_not_found when text is absent', () => {
    expect(matchSnippet(longSnippet, 'totally unrelated content here that is also long enough to look like a real article')).toEqual({
      verdict: 'snippet_not_found',
    });
  });

  it('returns snippet_too_short for fewer than 25 words', () => {
    expect(matchSnippet('only a few words here', 'irrelevant')).toEqual({
      verdict: 'snippet_too_short',
    });
    expect(MIN_SNIPPET_WORDS).toBe(25);
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd ev-accounts/backend && npx vitest run src/lib/researchVerifier.test.ts
```

Expected: FAIL — `matchSnippet is not a function` (or similar).

- [ ] **Step 3: Implement matchSnippet**

Append to `researchVerifier.ts`:

```typescript
export const MIN_SNIPPET_WORDS = 25;

export type SnippetVerdict =
  | { verdict: 'verified'; matchOffset: number }
  | { verdict: 'snippet_not_found' }
  | { verdict: 'snippet_too_short' }
  | { verdict: 'name_not_present' }
  | { verdict: 'url_broken'; reason: string };

export function matchSnippet(
  snippet: string,
  pageText: string,
): SnippetVerdict {
  const wordCount = snippet.trim().split(/\s+/).filter(Boolean).length;
  if (wordCount < MIN_SNIPPET_WORDS) {
    return { verdict: 'snippet_too_short' };
  }
  const normalizedSnippet = normalizeText(snippet);
  const normalizedPage = normalizeText(pageText);
  const offset = normalizedPage.indexOf(normalizedSnippet);
  if (offset === -1) {
    return { verdict: 'snippet_not_found' };
  }
  return { verdict: 'verified', matchOffset: offset };
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd ev-accounts/backend && npx vitest run src/lib/researchVerifier.test.ts
```

Expected: PASS — all tests passing (normalization + snippet match).

- [ ] **Step 5: Commit**

```bash
git add ev-accounts/backend/src/lib/researchVerifier.ts \
        ev-accounts/backend/src/lib/researchVerifier.test.ts
git commit -m "feat(stance-research): snippet match with min-length gate"
```

---

## Task 4: Verifier — name proximity check

**Files:**
- Modify: `ev-accounts/backend/src/lib/researchVerifier.ts`
- Modify: `ev-accounts/backend/src/lib/researchVerifier.test.ts`

- [ ] **Step 1: Write the failing tests**

Append to `researchVerifier.test.ts`:

```typescript
import { checkNameProximity, NAME_PROXIMITY_CHARS } from './researchVerifier.js';

describe('checkNameProximity', () => {
  const fullName = 'Brad Sherman';
  const lastName = 'Sherman';
  const longSnippet = 'The senator strongly supports a public option for healthcare and has cosponsored multiple bills since 2021 to expand Medicare access for older Americans without raising taxes on the middle class.';

  it('verified when full name appears within snippet', () => {
    const page = `prefix Brad Sherman: ${longSnippet} suffix`;
    expect(NAME_PROXIMITY_CHARS).toBe(500);
    const v = checkNameProximity({
      fullName,
      lastName,
      pageText: page,
      matchOffsetInNormalized: normalizeText(page).indexOf(normalizeText(longSnippet)),
    });
    expect(v).toEqual({ verdict: 'verified', matchOffset: expect.any(Number) });
  });

  it('verified when last name appears within 500 chars before the snippet', () => {
    const filler = 'x'.repeat(200);
    const page = `Sherman said in a statement, ${filler}. Background: ${longSnippet}`;
    const v = checkNameProximity({
      fullName,
      lastName,
      pageText: page,
      matchOffsetInNormalized: normalizeText(page).indexOf(normalizeText(longSnippet)),
    });
    expect(v.verdict).toBe('verified');
  });

  it('name_not_present when last name is too far from snippet', () => {
    const filler = 'x'.repeat(2000);
    const page = `Sherman said something. ${filler}. Now an unrelated paragraph: ${longSnippet}`;
    const v = checkNameProximity({
      fullName,
      lastName,
      pageText: page,
      matchOffsetInNormalized: normalizeText(page).indexOf(normalizeText(longSnippet)),
    });
    expect(v.verdict).toBe('name_not_present');
  });

  it('name_not_present when name is absent from page entirely', () => {
    const page = `prefix ${longSnippet} suffix`;
    const v = checkNameProximity({
      fullName,
      lastName,
      pageText: page,
      matchOffsetInNormalized: normalizeText(page).indexOf(normalizeText(longSnippet)),
    });
    expect(v.verdict).toBe('name_not_present');
  });

  it('common last name "Smith" requires title qualifier within proximity', () => {
    const filler = 'x'.repeat(100);
    const noTitle = `Smith was at the meeting. ${filler}. Then: ${longSnippet}`;
    const withTitle = `Sen. Smith was at the meeting. ${filler}. Then: ${longSnippet}`;
    expect(checkNameProximity({
      fullName: 'Jane Smith',
      lastName: 'Smith',
      pageText: noTitle,
      matchOffsetInNormalized: normalizeText(noTitle).indexOf(normalizeText(longSnippet)),
    }).verdict).toBe('name_not_present');
    expect(checkNameProximity({
      fullName: 'Jane Smith',
      lastName: 'Smith',
      pageText: withTitle,
      matchOffsetInNormalized: normalizeText(withTitle).indexOf(normalizeText(longSnippet)),
    }).verdict).toBe('verified');
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd ev-accounts/backend && npx vitest run src/lib/researchVerifier.test.ts
```

Expected: FAIL — `checkNameProximity is not a function`.

- [ ] **Step 3: Implement checkNameProximity**

Append to `researchVerifier.ts`:

```typescript
export const NAME_PROXIMITY_CHARS = 500;

// Last names common enough that a bare match is too coincidence-prone — require
// a title qualifier (Sen./Rep./Mayor/Gov./Pres./Councilor/etc.) nearby.
const COMMON_LAST_NAMES = new Set([
  'smith', 'johnson', 'williams', 'brown', 'jones', 'garcia', 'miller',
  'davis', 'rodriguez', 'martinez', 'hernandez', 'lopez', 'gonzalez',
  'wilson', 'anderson', 'thomas', 'taylor', 'moore', 'jackson', 'martin',
  'lee', 'thompson', 'white', 'harris', 'clark', 'lewis', 'robinson',
  'walker', 'young', 'allen', 'king', 'wright', 'scott', 'green', 'baker',
  'adams', 'nelson', 'hill', 'campbell', 'mitchell', 'roberts', 'carter',
  'phillips', 'evans', 'turner', 'parker', 'edwards', 'collins',
]);

const TITLE_PATTERN = /\b(sen|sen\.|senator|rep|rep\.|representative|gov|gov\.|governor|pres|pres\.|president|mayor|councilor|councilman|councilwoman|councilmember|delegate|asm|asm\.|assemblymember|judge|justice|chief|sheriff|hon|hon\.|honorable)\b/;

export function checkNameProximity(args: {
  fullName: string;
  lastName: string;
  pageText: string;
  matchOffsetInNormalized: number;
}): SnippetVerdict {
  const { fullName, lastName, pageText, matchOffsetInNormalized } = args;
  if (matchOffsetInNormalized < 0) {
    return { verdict: 'snippet_not_found' };
  }
  const normalizedPage = normalizeText(pageText);
  const fullNameLower = normalizeText(fullName);
  const lastNameLower = normalizeText(lastName);

  // Window: 500 chars before snippet start to 500 chars after snippet start.
  // (We use snippet START + window — a snippet itself can be long, and any
  // mention near its leading edge is "associated with" the passage.)
  const windowStart = Math.max(0, matchOffsetInNormalized - NAME_PROXIMITY_CHARS);
  const windowEnd = Math.min(
    normalizedPage.length,
    matchOffsetInNormalized + NAME_PROXIMITY_CHARS,
  );
  const window = normalizedPage.slice(windowStart, windowEnd);

  // Full name in window → verified.
  if (window.includes(fullNameLower)) {
    return { verdict: 'verified', matchOffset: matchOffsetInNormalized };
  }

  // Last name in window?
  if (window.includes(lastNameLower)) {
    const isCommon = COMMON_LAST_NAMES.has(lastNameLower);
    if (!isCommon) {
      return { verdict: 'verified', matchOffset: matchOffsetInNormalized };
    }
    // Common last name — require title qualifier nearby.
    // Find each occurrence of the last name in the window and check for a
    // title within 30 chars before it.
    let idx = window.indexOf(lastNameLower);
    while (idx !== -1) {
      const lookbehind = window.slice(Math.max(0, idx - 30), idx);
      if (TITLE_PATTERN.test(lookbehind)) {
        return { verdict: 'verified', matchOffset: matchOffsetInNormalized };
      }
      idx = window.indexOf(lastNameLower, idx + 1);
    }
  }

  return { verdict: 'name_not_present' };
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd ev-accounts/backend && npx vitest run src/lib/researchVerifier.test.ts
```

Expected: PASS — name proximity tests pass alongside earlier tests.

- [ ] **Step 5: Commit**

```bash
git add ev-accounts/backend/src/lib/researchVerifier.ts \
        ev-accounts/backend/src/lib/researchVerifier.test.ts
git commit -m "feat(stance-research): name proximity check with common-name handling"
```

---

## Task 5: Verifier — page fetcher with caching and error mapping

**Files:**
- Modify: `ev-accounts/backend/src/lib/researchVerifier.ts`
- Modify: `ev-accounts/backend/src/lib/researchVerifier.test.ts`

- [ ] **Step 1: Write the failing tests**

Append to `researchVerifier.test.ts`:

```typescript
import { createPageFetcher, type PageFetcher } from './researchVerifier.js';

describe('createPageFetcher', () => {
  it('caches results per URL within a batch', async () => {
    let calls = 0;
    const fakeFetch = async (url: string) => {
      calls++;
      return `content for ${url}`;
    };
    const fetcher = createPageFetcher(fakeFetch);
    expect(await fetcher('https://a.example')).toEqual({ ok: true, text: 'content for https://a.example' });
    expect(await fetcher('https://a.example')).toEqual({ ok: true, text: 'content for https://a.example' });
    expect(await fetcher('https://b.example')).toEqual({ ok: true, text: 'content for https://b.example' });
    expect(calls).toBe(2);
  });

  it('maps thrown errors to url_broken with a reason', async () => {
    const fakeFetch = async () => { throw new Error('ENOTFOUND'); };
    const fetcher = createPageFetcher(fakeFetch);
    const result = await fetcher('https://broken.example');
    expect(result).toEqual({ ok: false, reason: 'ENOTFOUND' });
  });

  it('caches failures too, to avoid hammering broken URLs', async () => {
    let calls = 0;
    const fakeFetch = async () => { calls++; throw new Error('boom'); };
    const fetcher = createPageFetcher(fakeFetch);
    await fetcher('https://x.example');
    await fetcher('https://x.example');
    expect(calls).toBe(1);
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd ev-accounts/backend && npx vitest run src/lib/researchVerifier.test.ts
```

Expected: FAIL — `createPageFetcher is not a function`.

- [ ] **Step 3: Implement createPageFetcher**

Append to `researchVerifier.ts`:

```typescript
export type PageFetchResult =
  | { ok: true; text: string }
  | { ok: false; reason: string };

export type PageFetcher = (url: string) => Promise<PageFetchResult>;

/**
 * createPageFetcher — wraps an underlying fetch fn with per-URL caching for
 * the lifetime of one verifier batch. Failures are cached too so we don't
 * retry obviously-broken URLs across multiple snippets in the same batch.
 */
export function createPageFetcher(
  rawFetch: (url: string) => Promise<string>,
): PageFetcher {
  const cache = new Map<string, PageFetchResult>();
  return async (url: string) => {
    const cached = cache.get(url);
    if (cached) return cached;
    let result: PageFetchResult;
    try {
      const text = await rawFetch(url);
      result = { ok: true, text };
    } catch (err: any) {
      result = { ok: false, reason: err?.message ?? String(err) };
    }
    cache.set(url, result);
    return result;
  };
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd ev-accounts/backend && npx vitest run src/lib/researchVerifier.test.ts
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add ev-accounts/backend/src/lib/researchVerifier.ts \
        ev-accounts/backend/src/lib/researchVerifier.test.ts
git commit -m "feat(stance-research): page fetcher with caching and error mapping"
```

---

## Task 6: Verifier — top-level verify function

**Files:**
- Modify: `ev-accounts/backend/src/lib/researchVerifier.ts`
- Modify: `ev-accounts/backend/src/lib/researchVerifier.test.ts`

- [ ] **Step 1: Write the failing tests**

Append to `researchVerifier.test.ts`:

```typescript
import { verifyEvidence, type StanceRow, type EvidenceRow, type VerifiedRow } from './researchVerifier.js';

describe('verifyEvidence', () => {
  const longSnippet = 'The senator strongly supports a public option for healthcare and has cosponsored multiple bills since 2021 to expand Medicare access for older Americans without raising taxes on the middle class.';

  const stanceRows: StanceRow[] = [
    { full_name: 'Brad Sherman', topic_key: 'healthcare', value: 2, reasoning: 'public option', external_id: '' },
  ];

  it('partitions verified rows into pushable bucket', async () => {
    const evidenceRows: EvidenceRow[] = [
      { full_name: 'Brad Sherman', topic_key: 'healthcare', source_url: 'https://a.example', snippet: longSnippet, snippet_index: 0 },
      { full_name: 'Brad Sherman', topic_key: 'healthcare', source_url: 'https://b.example', snippet: longSnippet, snippet_index: 0 },
    ];
    const fetcher: PageFetcher = async (url) => ({
      ok: true,
      text: `prefix Brad Sherman: ${longSnippet} suffix from ${url}`,
    });
    const result = await verifyEvidence({
      stanceRows,
      evidenceRows,
      fetcher,
      threshold: 2,
      politicianNames: { 'Brad Sherman': { fullName: 'Brad Sherman', lastName: 'Sherman' } },
    });
    expect(result.pushable).toHaveLength(1);
    expect(result.pushable[0].verifiedSources).toHaveLength(2);
    expect(result.needsReResearch).toHaveLength(0);
    expect(result.reviewQueue).toHaveLength(0);
  });

  it('routes below-threshold rows to needsReResearch', async () => {
    const evidenceRows: EvidenceRow[] = [
      { full_name: 'Brad Sherman', topic_key: 'healthcare', source_url: 'https://a.example', snippet: longSnippet, snippet_index: 0 },
    ];
    const fetcher: PageFetcher = async () => ({ ok: true, text: `Brad Sherman: ${longSnippet}` });
    const result = await verifyEvidence({
      stanceRows,
      evidenceRows,
      fetcher,
      threshold: 2,
      politicianNames: { 'Brad Sherman': { fullName: 'Brad Sherman', lastName: 'Sherman' } },
    });
    expect(result.needsReResearch).toHaveLength(1);
    expect(result.needsReResearch[0].verifiedSources).toHaveLength(1);
    expect(result.pushable).toHaveLength(0);
  });

  it('drops a source whose snippets all fail and counts remaining sources', async () => {
    const evidenceRows: EvidenceRow[] = [
      { full_name: 'Brad Sherman', topic_key: 'healthcare', source_url: 'https://good.example', snippet: longSnippet, snippet_index: 0 },
      { full_name: 'Brad Sherman', topic_key: 'healthcare', source_url: 'https://bad.example', snippet: longSnippet, snippet_index: 0 },
    ];
    const fetcher: PageFetcher = async (url) => {
      if (url === 'https://bad.example') return { ok: true, text: 'unrelated content not containing the snippet at all' };
      return { ok: true, text: `Brad Sherman: ${longSnippet}` };
    };
    const result = await verifyEvidence({
      stanceRows,
      evidenceRows,
      fetcher,
      threshold: 2,
      politicianNames: { 'Brad Sherman': { fullName: 'Brad Sherman', lastName: 'Sherman' } },
    });
    expect(result.needsReResearch).toHaveLength(1);
    expect(result.needsReResearch[0].verifiedSources).toHaveLength(1);
    expect(result.needsReResearch[0].failedSources).toHaveLength(1);
    expect(result.needsReResearch[0].failedSources[0].url).toBe('https://bad.example');
  });

  it('keeps source verified if at least one of its snippets verifies', async () => {
    const otherLongSnippet = 'Completely different paragraph that nonetheless has at least twenty five words in it so the minimum length check passes for this snippet here.';
    const evidenceRows: EvidenceRow[] = [
      { full_name: 'Brad Sherman', topic_key: 'healthcare', source_url: 'https://a.example', snippet: otherLongSnippet, snippet_index: 0 },
      { full_name: 'Brad Sherman', topic_key: 'healthcare', source_url: 'https://a.example', snippet: longSnippet, snippet_index: 1 },
    ];
    const fetcher: PageFetcher = async () => ({ ok: true, text: `Brad Sherman said: ${longSnippet}` });
    const result = await verifyEvidence({
      stanceRows,
      evidenceRows,
      fetcher,
      threshold: 1,
      politicianNames: { 'Brad Sherman': { fullName: 'Brad Sherman', lastName: 'Sherman' } },
    });
    expect(result.pushable).toHaveLength(1);
    expect(result.pushable[0].verifiedSources).toHaveLength(1);
  });

  it('routes stance rows with zero evidence rows directly to review queue', async () => {
    const fetcher: PageFetcher = async () => { throw new Error('should not be called'); };
    const result = await verifyEvidence({
      stanceRows,
      evidenceRows: [],
      fetcher,
      threshold: 2,
      politicianNames: { 'Brad Sherman': { fullName: 'Brad Sherman', lastName: 'Sherman' } },
    });
    expect(result.needsReResearch).toHaveLength(1);
    expect(result.needsReResearch[0].verifiedSources).toHaveLength(0);
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd ev-accounts/backend && npx vitest run src/lib/researchVerifier.test.ts
```

Expected: FAIL — `verifyEvidence is not a function`.

- [ ] **Step 3: Implement verifyEvidence**

Append to `researchVerifier.ts`:

```typescript
export interface StanceRow {
  full_name: string;
  external_id: string;
  topic_key: string;
  value: number | null;
  reasoning: string;
}

export interface EvidenceRow {
  full_name: string;
  topic_key: string;
  source_url: string;
  snippet: string;
  snippet_index: number;
}

export interface VerifiedSnippet {
  snippet: string;
  snippet_index: number;
  verdict: SnippetVerdict;
}

export interface VerifiedSource {
  url: string;
  snippets: VerifiedSnippet[];
}

export interface VerifiedRow {
  stance: StanceRow;
  verifiedSources: VerifiedSource[];
  failedSources: VerifiedSource[];
}

export interface VerifyResult {
  pushable: VerifiedRow[];
  needsReResearch: VerifiedRow[];
  reviewQueue: VerifiedRow[]; // populated by orchestrator after re-research; verifyEvidence itself only returns pushable + needsReResearch
}

export interface PoliticianNames {
  [fullName: string]: { fullName: string; lastName: string };
}

function rowKey(fullName: string, topicKey: string): string {
  return `${fullName} ${topicKey}`;
}

export async function verifyEvidence(args: {
  stanceRows: StanceRow[];
  evidenceRows: EvidenceRow[];
  fetcher: PageFetcher;
  threshold: number;
  politicianNames: PoliticianNames;
}): Promise<VerifyResult> {
  const { stanceRows, evidenceRows, fetcher, threshold, politicianNames } = args;

  // Group evidence by (fullName, topicKey, sourceUrl)
  const grouped = new Map<string, Map<string, EvidenceRow[]>>();
  for (const ev of evidenceRows) {
    const key = rowKey(ev.full_name, ev.topic_key);
    if (!grouped.has(key)) grouped.set(key, new Map());
    const bySource = grouped.get(key)!;
    if (!bySource.has(ev.source_url)) bySource.set(ev.source_url, []);
    bySource.get(ev.source_url)!.push(ev);
  }

  const pushable: VerifiedRow[] = [];
  const needsReResearch: VerifiedRow[] = [];

  for (const stance of stanceRows) {
    const key = rowKey(stance.full_name, stance.topic_key);
    const bySource = grouped.get(key) ?? new Map<string, EvidenceRow[]>();
    const names = politicianNames[stance.full_name];
    if (!names) {
      needsReResearch.push({ stance, verifiedSources: [], failedSources: [] });
      continue;
    }

    const verifiedSources: VerifiedSource[] = [];
    const failedSources: VerifiedSource[] = [];

    for (const [url, snippets] of bySource.entries()) {
      const fetched = await fetcher(url);
      const judged: VerifiedSnippet[] = [];
      if (!fetched.ok) {
        for (const ev of snippets) {
          judged.push({
            snippet: ev.snippet,
            snippet_index: ev.snippet_index,
            verdict: { verdict: 'url_broken', reason: fetched.reason },
          });
        }
      } else {
        for (const ev of snippets) {
          const matchVerdict = matchSnippet(ev.snippet, fetched.text);
          if (matchVerdict.verdict !== 'verified') {
            judged.push({ snippet: ev.snippet, snippet_index: ev.snippet_index, verdict: matchVerdict });
            continue;
          }
          const proxVerdict = checkNameProximity({
            fullName: names.fullName,
            lastName: names.lastName,
            pageText: fetched.text,
            matchOffsetInNormalized: matchVerdict.matchOffset,
          });
          judged.push({ snippet: ev.snippet, snippet_index: ev.snippet_index, verdict: proxVerdict });
        }
      }
      const anyVerified = judged.some((s) => s.verdict.verdict === 'verified');
      if (anyVerified) verifiedSources.push({ url, snippets: judged });
      else failedSources.push({ url, snippets: judged });
    }

    const row: VerifiedRow = { stance, verifiedSources, failedSources };
    if (verifiedSources.length >= threshold) pushable.push(row);
    else needsReResearch.push(row);
  }

  return { pushable, needsReResearch, reviewQueue: [] };
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd ev-accounts/backend && npx vitest run src/lib/researchVerifier.test.ts
```

Expected: PASS — all five `verifyEvidence` tests pass alongside earlier tests.

- [ ] **Step 5: Commit**

```bash
git add ev-accounts/backend/src/lib/researchVerifier.ts \
        ev-accounts/backend/src/lib/researchVerifier.test.ts
git commit -m "feat(stance-research): top-level verifyEvidence with threshold partitioning"
```

---

## Task 7: CSV parsing and writing helpers

**Files:**
- Create: `ev-accounts/backend/src/lib/stanceResearchCsv.ts`
- Create: `ev-accounts/backend/src/lib/stanceResearchCsv.test.ts`

- [ ] **Step 1: Write the failing tests**

Create `ev-accounts/backend/src/lib/stanceResearchCsv.test.ts`:

```typescript
import { describe, it, expect } from 'vitest';
import { parseStancesCsv, parseEvidenceCsv, writeStancesCsv, writeEvidenceCsv } from './stanceResearchCsv.js';

describe('parseStancesCsv', () => {
  it('parses header + rows, coerces value to number, leaves null when blank', () => {
    const csv = `full_name,external_id,topic_key,value,reasoning
"Brad Sherman",,healthcare,2,"Cosponsored public option bill"
"Maxine Waters",,abortion,,"Insufficient recent record"
`;
    const rows = parseStancesCsv(csv);
    expect(rows).toEqual([
      { full_name: 'Brad Sherman', external_id: '', topic_key: 'healthcare', value: 2, reasoning: 'Cosponsored public option bill' },
      { full_name: 'Maxine Waters', external_id: '', topic_key: 'abortion', value: null, reasoning: 'Insufficient recent record' },
    ]);
  });
});

describe('parseEvidenceCsv', () => {
  it('parses header + rows with snippet_index as integer', () => {
    const csv = `full_name,topic_key,source_url,snippet,snippet_index
"Brad Sherman",healthcare,https://a.example,"Some long snippet text here",0
"Brad Sherman",healthcare,https://a.example,"Another snippet from same source",1
`;
    const rows = parseEvidenceCsv(csv);
    expect(rows).toHaveLength(2);
    expect(rows[0].snippet_index).toBe(0);
    expect(rows[1].snippet_index).toBe(1);
    expect(rows[0].source_url).toBe('https://a.example');
  });
});

describe('writeStancesCsv', () => {
  it('produces a parseable CSV with quoted fields', () => {
    const csv = writeStancesCsv([
      { full_name: 'Brad, Sherman', external_id: '', topic_key: 'healthcare', value: 2, reasoning: 'has "quotes" inside' },
    ]);
    const reparsed = parseStancesCsv(csv);
    expect(reparsed[0].full_name).toBe('Brad, Sherman');
    expect(reparsed[0].reasoning).toBe('has "quotes" inside');
  });
});

describe('writeEvidenceCsv', () => {
  it('round-trips through parseEvidenceCsv', () => {
    const csv = writeEvidenceCsv([
      { full_name: 'X', topic_key: 't', source_url: 'https://u', snippet: 'a, b, c', snippet_index: 0 },
    ]);
    expect(parseEvidenceCsv(csv)[0].snippet).toBe('a, b, c');
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd ev-accounts/backend && npx vitest run src/lib/stanceResearchCsv.test.ts
```

Expected: FAIL — `Cannot find module './stanceResearchCsv.js'`.

- [ ] **Step 3: Implement stanceResearchCsv.ts**

Create `ev-accounts/backend/src/lib/stanceResearchCsv.ts`:

```typescript
/**
 * stanceResearchCsv — parse and write the two-CSV format produced by the
 * politician-stance-researcher agent.
 *
 *   stances.csv:  full_name, external_id, topic_key, value, reasoning
 *   evidence.csv: full_name, topic_key, source_url, snippet, snippet_index
 *
 * Joined on (full_name, topic_key).
 */

import { parse } from 'csv-parse/sync';
import { stringify } from 'csv-stringify/sync';
import type { StanceRow, EvidenceRow } from './researchVerifier.js';

export function parseStancesCsv(text: string): StanceRow[] {
  const rows = parse(text, { columns: true, skip_empty_lines: true, relax_column_count: true }) as Record<string, string>[];
  return rows.map((r) => ({
    full_name: r.full_name ?? '',
    external_id: r.external_id ?? '',
    topic_key: r.topic_key ?? '',
    value: r.value && r.value.trim() !== '' ? Number(r.value) : null,
    reasoning: r.reasoning ?? '',
  }));
}

export function parseEvidenceCsv(text: string): EvidenceRow[] {
  const rows = parse(text, { columns: true, skip_empty_lines: true, relax_column_count: true }) as Record<string, string>[];
  return rows.map((r) => ({
    full_name: r.full_name ?? '',
    topic_key: r.topic_key ?? '',
    source_url: r.source_url ?? '',
    snippet: r.snippet ?? '',
    snippet_index: Number(r.snippet_index ?? 0),
  }));
}

export function writeStancesCsv(rows: StanceRow[]): string {
  return stringify(rows, {
    header: true,
    columns: ['full_name', 'external_id', 'topic_key', 'value', 'reasoning'],
  });
}

export function writeEvidenceCsv(rows: EvidenceRow[]): string {
  return stringify(rows, {
    header: true,
    columns: ['full_name', 'topic_key', 'source_url', 'snippet', 'snippet_index'],
  });
}
```

- [ ] **Step 4: Verify csv-stringify is installed**

```bash
cd ev-accounts/backend && npm ls csv-stringify
```

If missing, install it:

```bash
cd ev-accounts/backend && npm install csv-stringify
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
cd ev-accounts/backend && npx vitest run src/lib/stanceResearchCsv.test.ts
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add ev-accounts/backend/src/lib/stanceResearchCsv.ts \
        ev-accounts/backend/src/lib/stanceResearchCsv.test.ts \
        ev-accounts/backend/package.json ev-accounts/backend/package-lock.json
git commit -m "feat(stance-research): two-CSV parse/write helpers"
```

---

## Task 8: DB persistence — evidence and review queue

**Files:**
- Create: `ev-accounts/backend/src/lib/researchEvidenceService.ts`
- Create: `ev-accounts/backend/src/lib/researchEvidenceService.test.ts`

- [ ] **Step 1: Write the failing tests**

Create `ev-accounts/backend/src/lib/researchEvidenceService.test.ts`:

```typescript
import { describe, it, expect } from 'vitest';
import { buildEvidenceRowsForInsert, buildReviewRowForInsert } from './researchEvidenceService.js';
import type { VerifiedRow } from './researchVerifier.js';

const exampleRow: VerifiedRow = {
  stance: { full_name: 'Brad Sherman', external_id: '', topic_key: 'healthcare', value: 2, reasoning: 'public option' },
  verifiedSources: [
    {
      url: 'https://a.example',
      snippets: [
        { snippet: 'snippet text one', snippet_index: 0, verdict: { verdict: 'verified', matchOffset: 100 } },
        { snippet: 'snippet text two', snippet_index: 1, verdict: { verdict: 'snippet_not_found' } },
      ],
    },
  ],
  failedSources: [],
};

describe('buildEvidenceRowsForInsert', () => {
  it('flattens verified-only snippets per source for DB insert', () => {
    const rows = buildEvidenceRowsForInsert({
      row: exampleRow,
      politicianId: '11111111-1111-1111-1111-111111111111',
      topicId: '22222222-2222-2222-2222-222222222222',
      batchId: '2026-04-30-test',
    });
    expect(rows).toEqual([
      {
        politician_id: '11111111-1111-1111-1111-111111111111',
        topic_id: '22222222-2222-2222-2222-222222222222',
        source_url: 'https://a.example',
        snippet: 'snippet text one',
        snippet_index: 0,
        batch_id: '2026-04-30-test',
      },
    ]);
  });
});

describe('buildReviewRowForInsert', () => {
  it('captures every snippet verdict in the evidence jsonb', () => {
    const review = buildReviewRowForInsert({
      row: exampleRow,
      politicianId: '11111111-1111-1111-1111-111111111111',
      topicId: '22222222-2222-2222-2222-222222222222',
      batchId: '2026-04-30-test',
      threshold: 2,
      reResearchAttempted: true,
    });
    expect(review.batch_id).toBe('2026-04-30-test');
    expect(review.politician_id).toBe('11111111-1111-1111-1111-111111111111');
    expect(review.topic_key).toBe('healthcare');
    expect(review.proposed_value).toBe(2);
    expect(review.threshold).toBe(2);
    expect(review.re_research_attempted).toBe(true);
    expect(review.verified_source_count).toBe(1);
    const ev = review.evidence as any[];
    expect(ev[0].url).toBe('https://a.example');
    expect(ev[0].snippets).toHaveLength(2);
    expect(ev[0].snippets[1].verdict).toBe('snippet_not_found');
  });

  it('uses unresolved_politician status when politicianId is null', () => {
    const review = buildReviewRowForInsert({
      row: exampleRow,
      politicianId: null,
      topicId: null,
      batchId: 'b',
      threshold: 2,
      reResearchAttempted: false,
    });
    expect(review.status).toBe('unresolved_politician');
    expect(review.full_name_raw).toBe('Brad Sherman');
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd ev-accounts/backend && npx vitest run src/lib/researchEvidenceService.test.ts
```

Expected: FAIL — `Cannot find module`.

- [ ] **Step 3: Implement researchEvidenceService.ts**

Create `ev-accounts/backend/src/lib/researchEvidenceService.ts`:

```typescript
/**
 * researchEvidenceService — pure helpers that shape VerifiedRow objects into
 * rows ready for `inform.politician_context_evidence` and
 * `inform.stance_research_review`. The actual SQL execution lives in the
 * skill orchestrator; this module is unit-testable on its own.
 */

import { pool } from './db.js';
import type { VerifiedRow } from './researchVerifier.js';

export interface EvidenceInsertRow {
  politician_id: string;
  topic_id: string;
  source_url: string;
  snippet: string;
  snippet_index: number;
  batch_id: string;
}

export interface ReviewInsertRow {
  batch_id: string;
  politician_id: string | null;
  full_name_raw: string;
  topic_id: string | null;
  topic_key: string;
  proposed_value: number | null;
  proposed_reasoning: string;
  evidence: unknown;
  verified_source_count: number;
  threshold: number;
  status: 'pending' | 'unresolved_politician';
  re_research_attempted: boolean;
}

export function buildEvidenceRowsForInsert(args: {
  row: VerifiedRow;
  politicianId: string;
  topicId: string;
  batchId: string;
}): EvidenceInsertRow[] {
  const out: EvidenceInsertRow[] = [];
  for (const src of args.row.verifiedSources) {
    for (const snip of src.snippets) {
      if (snip.verdict.verdict === 'verified') {
        out.push({
          politician_id: args.politicianId,
          topic_id: args.topicId,
          source_url: src.url,
          snippet: snip.snippet,
          snippet_index: snip.snippet_index,
          batch_id: args.batchId,
        });
      }
    }
  }
  return out;
}

function snippetsForJsonb(verifiedSources: VerifiedRow['verifiedSources'], failedSources: VerifiedRow['failedSources']) {
  const all = [...verifiedSources, ...failedSources];
  return all.map((s) => ({
    url: s.url,
    snippets: s.snippets.map((snip) => ({
      snippet_index: snip.snippet_index,
      snippet: snip.snippet,
      verdict: snip.verdict.verdict,
      reason: snip.verdict.verdict === 'url_broken' ? snip.verdict.reason : undefined,
    })),
  }));
}

export function buildReviewRowForInsert(args: {
  row: VerifiedRow;
  politicianId: string | null;
  topicId: string | null;
  batchId: string;
  threshold: number;
  reResearchAttempted: boolean;
}): ReviewInsertRow {
  return {
    batch_id: args.batchId,
    politician_id: args.politicianId,
    full_name_raw: args.row.stance.full_name,
    topic_id: args.topicId,
    topic_key: args.row.stance.topic_key,
    proposed_value: args.row.stance.value,
    proposed_reasoning: args.row.stance.reasoning,
    evidence: snippetsForJsonb(args.row.verifiedSources, args.row.failedSources),
    verified_source_count: args.row.verifiedSources.length,
    threshold: args.threshold,
    status: args.politicianId === null ? 'unresolved_politician' : 'pending',
    re_research_attempted: args.reResearchAttempted,
  };
}

/**
 * Replace evidence for a (politician, topic) and insert fresh snippets.
 * Idempotent across re-runs of the same batch.
 */
export async function replaceEvidence(rows: EvidenceInsertRow[]): Promise<void> {
  if (rows.length === 0) return;
  const { politician_id, topic_id } = rows[0];
  await pool.query(
    `DELETE FROM inform.politician_context_evidence WHERE politician_id=$1 AND topic_id=$2`,
    [politician_id, topic_id],
  );
  for (const r of rows) {
    await pool.query(
      `INSERT INTO inform.politician_context_evidence
        (politician_id, topic_id, source_url, snippet, snippet_index, batch_id)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [r.politician_id, r.topic_id, r.source_url, r.snippet, r.snippet_index, r.batch_id],
    );
  }
}

/**
 * Idempotent upsert into the review queue keyed on (batch_id, politician_id-or-name, topic_key).
 */
export async function upsertReviewRow(row: ReviewInsertRow): Promise<void> {
  await pool.query(
    `INSERT INTO inform.stance_research_review
       (batch_id, politician_id, full_name_raw, topic_id, topic_key,
        proposed_value, proposed_reasoning, evidence,
        verified_source_count, threshold, status, re_research_attempted)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8::jsonb, $9, $10, $11, $12)
     ON CONFLICT (batch_id, COALESCE(politician_id::text, full_name_raw), topic_key)
     DO UPDATE SET
       proposed_value = EXCLUDED.proposed_value,
       proposed_reasoning = EXCLUDED.proposed_reasoning,
       evidence = EXCLUDED.evidence,
       verified_source_count = EXCLUDED.verified_source_count,
       threshold = EXCLUDED.threshold,
       status = EXCLUDED.status,
       re_research_attempted = EXCLUDED.re_research_attempted`,
    [
      row.batch_id, row.politician_id, row.full_name_raw, row.topic_id, row.topic_key,
      row.proposed_value, row.proposed_reasoning, JSON.stringify(row.evidence),
      row.verified_source_count, row.threshold, row.status, row.re_research_attempted,
    ],
  );
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd ev-accounts/backend && npx vitest run src/lib/researchEvidenceService.test.ts
```

Expected: PASS — both `buildEvidenceRowsForInsert` and `buildReviewRowForInsert` tests pass. The DB-touching functions (`replaceEvidence`, `upsertReviewRow`) are not unit-tested here; they get exercised by the integration smoke test in Task 13.

- [ ] **Step 5: Commit**

```bash
git add ev-accounts/backend/src/lib/researchEvidenceService.ts \
        ev-accounts/backend/src/lib/researchEvidenceService.test.ts
git commit -m "feat(stance-research): evidence + review-queue persistence helpers"
```

---

## Task 9: Update agent prompt — emit two CSVs and require snippets

**Files:**
- Modify: `.claude/agents/politician-stance-researcher.md`
- Modify: `ev-accounts/.claude/agents/politician-stance-researcher.md` (mirror)

- [ ] **Step 1: Replace the OUTPUT FORMAT section**

In `.claude/agents/politician-stance-researcher.md`, find the heading `## OUTPUT FORMAT` and replace its body (lines 227–242 in the existing file) with:

```markdown
## OUTPUT FORMAT

Every dispatch produces TWO CSV files. They join on `(full_name, topic_key)`.

### stances.csv — one row per (politician, topic)

```
full_name,external_id,topic_key,value,reasoning
```

- `full_name`: politician's full name
- `external_id`: leave blank
- `topic_key`: exact key from the list above
- `value`: integer 1–5, or blank when evidence is insufficient
- `reasoning`: 1–3 sentences (wrap in double quotes if it contains commas)

No source columns in this file.

### evidence.csv — one row per snippet

```
full_name,topic_key,source_url,snippet,snippet_index
```

- `full_name`, `topic_key`: must match a row in stances.csv (this is the join)
- `source_url`: real, fetchable URL
- `snippet`: a verbatim passage from the page that contains or surrounds a clear statement of the politician's position. 25–300 words. Wrap in double quotes; escape internal quotes by doubling them (`""`).
- `snippet_index`: 0-based; if you cite multiple passages from the same source, increment the index per snippet from that source

### THE SNIPPET RULE — read this twice

**No snippet → no source.** If you cannot capture an exact passage from the cited page that mentions the politician's position on the topic, you do not have that source. Do not list a URL in evidence.csv without at least one snippet from it. The downstream verifier fetches each URL and string-matches your snippet against the page; an invented snippet or one that is not actually on the page will be dropped automatically.

Multiple snippets per source are allowed and encouraged when a politician is referenced in multiple paragraphs of the same article. The verifier counts a source as verified if at least one of its snippets verifies.

A row in stances.csv with zero corresponding evidence rows will be quarantined for human review. If you cannot ground a stance in real snippets from real sources, prefer to leave `value` blank in stances.csv and explain the gap in `reasoning`.
```

- [ ] **Step 2: Replace the FILE OUTPUT section**

Find `## FILE OUTPUT` and replace with:

```markdown
## FILE OUTPUT

When your dispatch prompt includes `--output-dir <path>`, write:
- `<path>/stances.csv`
- `<path>/evidence.csv`

Use the Write tool. Always include header rows. If the files already exist (multi-batch dispatch into the same directory), append rows without repeating the header.

When no `--output-dir` is specified, return both CSVs in your response text as two fenced code blocks labeled `stances.csv` and `evidence.csv`.
```

- [ ] **Step 3: Add the re-research mode section**

After the existing `## REWRITE RE-EVALUATION MODE` section (or before `## UPDATE YOUR AGENT MEMORY`), insert:

```markdown
## RE-RESEARCH MODE

When the dispatch prompt explicitly says "You are running in RE-RESEARCH MODE", a previous research pass produced sources that failed automated verification. You are doing a targeted second pass on a single (politician, topic) pair.

### Your input in this mode

The dispatch prompt will contain:
- The politician name and topic_key
- A list of `--exclude-urls` — URLs whose snippets failed verification on the first pass. Do not cite these URLs again unless you can capture a different, verifiable snippet from them.
- A short failure summary so you understand what went wrong (e.g., "snippet not found on page", "politician name not near the snippet").

### Your task

Find at least 2 NEW sources (different URLs, or the same URLs with verifiably different passages). Capture real verbatim snippets that mention the politician by name and contain the position you're scoring. Write the result to the same `<output-dir>` as the primary research, with the same two-CSV format.

### What to skip

- Do NOT re-research other topics for the same politician.
- Do NOT cite URLs from `--exclude-urls` with snippets the previous pass already captured. (Different snippets from the same URL are fine, if they verify.)
- If you cannot find any verifiable sources after a focused second pass, leave `value` blank in stances.csv and explain why in `reasoning`. Better to skip than to invent.
```

- [ ] **Step 4: Mirror to ev-accounts/.claude/agents/**

```bash
cp .claude/agents/politician-stance-researcher.md \
   ev-accounts/.claude/agents/politician-stance-researcher.md
```

- [ ] **Step 5: Commit**

```bash
git add .claude/agents/politician-stance-researcher.md \
        ev-accounts/.claude/agents/politician-stance-researcher.md
git commit -m "feat(stance-research): agent emits two CSVs with mandatory snippets + re-research mode"
```

---

## Task 10: Skill orchestrator — verification step

**Files:**
- Modify: `.claude/skills/research-stances/SKILL.md`

- [ ] **Step 1: Replace STEP 2 onwards with verification-aware flow**

In `.claude/skills/research-stances/SKILL.md`, find `## STEP 2 — Collect and Merge Results` and replace from there through the end of `## STEP 4 — Push to Database` (i.e., the entire normal-mode flow; rewrite mode below stays untouched until Task 11) with:

```markdown
## STEP 2 — Collect and merge CSVs

Each dispatched agent writes into a per-batch directory under `ev-accounts/backend/data/stance-research/<BATCH_ID>/`. The agent produces two files there: `stances.csv` and `evidence.csv`. Multiple agents writing to the same directory append to the same files (header dedup is the agent's responsibility).

After all agents complete:

1. Confirm both files exist: `stances.csv` (one row per politician+topic) and `evidence.csv` (one row per snippet).
2. If only one file exists or either is empty, treat as a partial failure: prompt the user before proceeding.
3. Count rows: stance-row count vs (politician × topic) expected; evidence-row count gives a rough hallucination-check signal (zero evidence = empty research).

## STEP 2.5 — Verify evidence

Run the deterministic verifier over the two CSVs before any DB push or human approval. The verifier fetches every cited URL, checks each snippet appears verbatim on the page, and confirms the politician's name appears within 500 characters of the match. No LLM is involved.

Run from `ev-accounts/backend`:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && npx tsx -e "
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { parseStancesCsv, parseEvidenceCsv } from './src/lib/stanceResearchCsv.js';
import { verifyEvidence, createPageFetcher } from './src/lib/researchVerifier.js';
import { fetchPageContent } from './src/lib/fetchPageContent.js';
import { pool } from './src/lib/db.js';

const BATCH_DIR = process.argv[2];
const THRESHOLD = Number(process.argv[3] ?? 2);
const stances = parseStancesCsv(readFileSync(join(BATCH_DIR, 'stances.csv'), 'utf8'));
const evidence = parseEvidenceCsv(readFileSync(join(BATCH_DIR, 'evidence.csv'), 'utf8'));

const fullNames = Array.from(new Set(stances.map((s) => s.full_name)));
const { rows: pols } = await pool.query(
  \`SELECT full_name FROM essentials.politicians WHERE full_name = ANY(\$1)\`,
  [fullNames],
);
const polNames: Record<string, { fullName: string; lastName: string }> = {};
for (const p of pols) {
  const parts = p.full_name.trim().split(/\s+/);
  polNames[p.full_name] = { fullName: p.full_name, lastName: parts[parts.length - 1] };
}
// For names that didn't resolve in DB, still seed a name record from the CSV
// so the verifier doesn't drop them as 'unresolved'; the orchestrator will
// quarantine these rows separately.
for (const name of fullNames) {
  if (!polNames[name]) {
    const parts = name.trim().split(/\s+/);
    polNames[name] = { fullName: name, lastName: parts[parts.length - 1] };
  }
}

const fetcher = createPageFetcher(fetchPageContent);
const result = await verifyEvidence({ stanceRows: stances, evidenceRows: evidence, fetcher, threshold: THRESHOLD, politicianNames: polNames });
writeFileSync(join(BATCH_DIR, 'verify-pass1.json'), JSON.stringify(result, null, 2));
console.log(JSON.stringify({
  pushable: result.pushable.length,
  needsReResearch: result.needsReResearch.length,
}));
await pool.end();
" -- "ev-accounts/backend/data/stance-research/<BATCH_ID>" 2
```

Replace `<BATCH_ID>` with the actual batch directory name. Read `verify-pass1.json` to inspect verdicts. The verifier writes its full output (verdicts per snippet) to that file as the primary audit artifact.

## STEP 2.6 — Bounded re-research

For each row in `needsReResearch`, dispatch ONE additional `politician-stance-researcher` agent in RE-RESEARCH MODE for that single (politician, topic) pair. Pass the failed URLs from `verify-pass1.json` as `--exclude-urls`.

Cap: one re-research per row per batch. Even if it returns nothing, do not retry.

After re-research completes:
1. Re-parse the now-larger `stances.csv` and `evidence.csv` (agents append).
2. Run the verifier again, scoped only to rows that were re-researched (filter the stance set by names+topics in `needsReResearch`). Write the result to `verify-pass2.json`.
3. Merge: rows that pass on either pass go to `pushable`; rows still below threshold go to the `reviewQueue`.

## STEP 3 — Approval summary

Show the user:

```
## Research Results: <BATCH_ID>

Auto-verified:        N rows
Verified after re-research: N rows
Sent to review queue: N rows  (insufficient verified sources after one re-research attempt)

[Stance Overview table for the pushable rows — politician, topic, value, reasoning preview, # verified sources]

CSVs at: ev-accounts/backend/data/stance-research/<BATCH_ID>/
Verifier output: verify-pass1.json, verify-pass2.json
```

Then ask:
> "Review the verified stances above. The N review-queue rows will be written to `inform.stance_research_review` for later inspection regardless. You can:
> 1. Approve all — push verified rows to the production tables
> 2. Reject specific rows — name the (politician, topic) pairs to drop
> 3. Edit values — name rows to overwrite (e.g., 'change Sherman/healthcare to 3')
> 4. Skip DB push — keep CSVs and verify outputs only
>
> What would you like to do?"

## STEP 4 — Push verified rows to production

For each approved row in `pushable`:

### 4a. Resolve politician_id and topic_id

```bash
cd ev-accounts/backend && set -a && source .env && set +a && npx tsx -e "
import { pool } from './src/lib/db.js';
const { rows } = await pool.query(\`
  SELECT p.id AS politician_id, p.full_name,
         t.id AS topic_id, t.topic_key
  FROM essentials.politicians p
  CROSS JOIN inform.compass_topics t
  WHERE p.full_name = ANY(\$1)
    AND t.topic_key = ANY(\$2)
    AND t.is_live = true
\`, [process.argv[2].split('|'), process.argv[3].split('|')]);
console.log(JSON.stringify(rows, null, 2));
await pool.end();
" -- "Name1|Name2" "healthcare|abortion"
```

If a politician name doesn't resolve, that row goes to the review queue with status `unresolved_politician` (handled in STEP 5).

### 4b. Atomic per-row upsert: answers + context + evidence

For each resolved row, run inside one statement block per row:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && npx tsx -e "
import { pool } from './src/lib/db.js';
import { replaceEvidence, buildEvidenceRowsForInsert } from './src/lib/researchEvidenceService.js';
const PUSHABLE = JSON.parse(process.argv[2]); // [{ politician_id, topic_id, value, reasoning, batch_id, verifiedSources }]
for (const r of PUSHABLE) {
  await pool.query('BEGIN');
  try {
    await pool.query(\`INSERT INTO inform.politician_answers (politician_id, topic_id, value)
                      VALUES (\$1,\$2,\$3)
                      ON CONFLICT (politician_id, topic_id)
                      DO UPDATE SET value = EXCLUDED.value\`,
      [r.politician_id, r.topic_id, r.value]);
    const sources = r.verifiedSources.map((s) => s.url);
    await pool.query(\`INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
                      VALUES (\$1,\$2,\$3,\$4)
                      ON CONFLICT (politician_id, topic_id)
                      DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources\`,
      [r.politician_id, r.topic_id, r.reasoning, sources]);
    const evRows = buildEvidenceRowsForInsert({
      row: { stance: r, verifiedSources: r.verifiedSources, failedSources: [] },
      politicianId: r.politician_id, topicId: r.topic_id, batchId: r.batch_id,
    });
    await replaceEvidence(evRows);
    await pool.query('COMMIT');
  } catch (e) {
    await pool.query('ROLLBACK');
    console.error('row failed:', r.full_name, r.topic_key, e);
  }
}
await pool.end();
" '<JSON_PUSHABLE_ARRAY>'
```

If a row fails mid-transaction (constraint violation, etc.), it rolls back and gets logged but does not block other rows. Failed rows should be added to the review queue manually — the orchestrator can re-emit them in the STEP 5 batch.

## STEP 5 — Persist review queue

For every row in `reviewQueue` PLUS any rows that failed in STEP 4b:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && npx tsx -e "
import { upsertReviewRow, buildReviewRowForInsert } from './src/lib/researchEvidenceService.js';
import { pool } from './src/lib/db.js';
const REVIEW = JSON.parse(process.argv[2]); // [{ row, politicianId|null, topicId|null, batchId, threshold, reResearchAttempted }]
for (const item of REVIEW) {
  const r = buildReviewRowForInsert(item);
  await upsertReviewRow(r);
}
console.log('review rows upserted:', REVIEW.length);
await pool.end();
" '<JSON_REVIEW_ARRAY>'
```

## STEP 6 — Report results

Print a final summary:

```
Pushed [N] verified stances to production tables.
Wrote [N] evidence snippets to inform.politician_context_evidence.
Quarantined [N] rows in inform.stance_research_review (status='pending').
Quarantined [N] rows with status='unresolved_politician' (politician not found in DB).

Verifier outputs preserved at:
  ev-accounts/backend/data/stance-research/<BATCH_ID>/verify-pass1.json
  ev-accounts/backend/data/stance-research/<BATCH_ID>/verify-pass2.json (if re-research ran)

CSVs preserved at:
  ev-accounts/backend/data/stance-research/<BATCH_ID>/stances.csv
  ev-accounts/backend/data/stance-research/<BATCH_ID>/evidence.csv

Review the queue: SELECT * FROM inform.stance_research_review WHERE batch_id = '<BATCH_ID>' AND status='pending' ORDER BY topic_key;
```
```

- [ ] **Step 2: Update STEP 0 to allocate a batch directory**

In the existing `## STEP 0 — Parse Input` section, update the dispatch confirmation prompt to mention the new `<BATCH_ID>` directory layout. Find the "Confirm before proceeding" block and replace it with:

```markdown
**Confirm before proceeding.** Show the user:
- List of politicians to research
- Topics in scope (all or filtered)
- Estimated scope (e.g., "3 politicians x 21 topics = up to 63 stance assessments")
- Batch directory: `ev-accounts/backend/data/stance-research/<BATCH_ID>/` where `<BATCH_ID>` is `YYYY-MM-DD-<short-name>`. The agent will write `stances.csv` and `evidence.csv` here.
```

- [ ] **Step 3: Update STEP 1 dispatch prompt template**

In `## STEP 1 — Dispatch Research Agents`, replace `--output-file [ABSOLUTE_PATH]/.../[BATCH_NAME].csv` with:

```
--output-dir [ABSOLUTE_PATH]/ev-accounts/backend/data/stance-research/<BATCH_ID>
```

And add to the "Important" list at the bottom of the dispatch prompt template:

```
- Every source URL listed in evidence.csv MUST have at least one verbatim snippet (25–300 words) that mentions the politician's position. The downstream verifier fetches each URL and string-matches your snippet — invented snippets or off-topic snippets will be dropped automatically.
- Multiple snippets from the same source are encouraged. Use snippet_index to order them.
- Skip any topic where you cannot ground the stance in real snippets from real sources. Do not invent.
```

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/research-stances/SKILL.md
git commit -m "feat(stance-research): skill orchestrator runs verifier before DB push"
```

---

## Task 11: Skill orchestrator — rewrite mode verification

**Files:**
- Modify: `.claude/skills/research-stances/SKILL.md`

- [ ] **Step 1: Add verification step inside rewrite mode**

In `.claude/skills/research-stances/SKILL.md`, find `## STEP 2 (rewrite mode) — Collect results (same as normal mode)` and replace it with:

```markdown
## STEP 2 (rewrite mode) — Collect and verify

Same merge as normal mode (per-batch directory with stances.csv and evidence.csv). Then run the verifier (STEP 2.5 from normal mode) over the merged CSVs. Use threshold=2.

Rows with `value=null` (insufficient evidence in the new framing) bypass verification and go straight to auto-rejection in STEP 4. Rows with a value but failing verification are also rejected — they cannot be auto-approved without grounded evidence.

Verifier output: `verify-pass1.json` in the batch directory. Re-research is OPTIONAL in rewrite mode — the operator can choose to re-dispatch failed rows or auto-reject them. Default behavior: skip re-research, send failed rows to the existing rejection path.
```

- [ ] **Step 2: Update STEP 4 (rewrite mode) — apply script**

Find `### 4a. Parse CSV batches and apply in one script` and update the script header so it consumes the verifier output instead of all CSV rows. Insert this block immediately after the existing `const allRows: Row[] = [];` aggregation loop:

```typescript
// New: filter to verified rows only. Failed rows fall through to auto-reject below.
const verifyResult = JSON.parse(readFileSync(join(CSV_DIR, 'verify-pass1.json'), 'utf8')) as {
  pushable: Array<{ stance: Row; verifiedSources: { url: string }[] }>;
  needsReResearch: Array<{ stance: Row }>;
};
const verifiedRows = new Set(
  verifyResult.pushable.map((p) => `${p.stance.full_name} ${p.stance.topic_key}`),
);
```

Then in the per-row loop, change the `isNull` branch so it triggers for both null values AND non-verified rows:

```typescript
const rowKey = `${r.full_name} ${r.topic_key}`;
const isNull = !r.value || r.value.trim() === '' || r.value === 'null';
const isUnverified = !verifiedRows.has(rowKey);

if (isNull || isUnverified) {
  const reason = isNull
    ? `Insufficient evidence under new scale: ${r.reasoning || 'agent returned null'}`
    : `Failed automated verification: snippets or sources did not pass`;
  try {
    await pool.query(
      `SELECT inform.admin_reject_stance_proposal($1::uuid, $2::uuid, $3::uuid, $4::text)`,
      [REWRITE_ID, r.politician_id, ACTOR_ID, reason],
    );
    rejected++;
    console.log(`REJECT ${r.full_name} (${isNull ? 'null' : 'unverified'})`);
  } catch (e: any) {
    errors.push(`REJECT ${r.full_name}: ${e.message}`);
  }
  continue;
}
```

The rest of the loop (upsert + approve for verified rows) stays as-is, but should now use `verifyResult.pushable[i].verifiedSources.map(s => s.url)` for the sources array instead of pulling from the CSV's `source_url_*` columns (which no longer exist in the new format).

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/research-stances/SKILL.md
git commit -m "feat(stance-research): rewrite mode rejects unverified proposals"
```

---

## Task 12: Skill README

**Files:**
- Create: `.claude/skills/research-stances/README.md`

- [ ] **Step 1: Write the README**

Create `.claude/skills/research-stances/README.md`:

```markdown
# /research-stances — Architecture Notes

This README is the durable, code-adjacent description of how the stance-research pipeline works and why. The point-in-time design spec lives at `docs/superpowers/specs/2026-04-30-stance-research-verification-design.md`; this document supersedes it for ongoing maintenance.

## Pipeline overview

Three stages between operator intent and production data:

1. **Research with evidence capture** — the `politician-stance-researcher` agent emits two CSVs: `stances.csv` (one row per politician+topic) and `evidence.csv` (one row per snippet). The agent must capture at least one verbatim snippet (25–300 words) for every source URL it cites. No snippet means no source.
2. **Deterministic verification** — `researchVerifier.ts` fetches each cited URL via Playwright, normalizes whitespace/quotes/dashes/case, string-matches the snippet against the page, and confirms the politician's name appears within 500 characters of the match. No LLM in the loop.
3. **Gated DB push + review queue** — rows with at least N verified sources (default N=2) push to `inform.politician_answers`, `inform.politician_context`, and the new `inform.politician_context_evidence`. Rows below threshold get one bounded re-research attempt; if still short, they go to `inform.stance_research_review`.

## The snippet rule

The single most load-bearing invariant in this system: **every cited URL has at least one verbatim snippet attached, and the verifier mechanically checks the snippet appears on the page.**

This catches the two most common hallucination modes:
- *Fake quotes* — the snippet won't be on the page, period.
- *Real-but-irrelevant articles* — the snippet may be on the page but the politician's name won't be within 500 characters of it (the article mentioned the politician once in a different paragraph).

Snippets that pass verification persist to `inform.politician_context_evidence` for two reasons: an admin UI can later show "here's the exact passage that justified this stance," and the post-hoc `/verify-sources` audit becomes cheaper because it can string-match the stored snippet rather than re-judging the page with an LLM.

## Verification rules

- **Verbatim string match** after normalization (whitespace collapsed, quotes/dashes normalized, lowercased, common HTML entities decoded).
- **Minimum snippet length 25 words.** Shorter snippets are too coincidence-prone — a 5-word phrase will match many irrelevant pages by chance.
- **Maximum snippet length 300 words at persistence.** The full snippet is verified, but storage is capped (the verifier audit log keeps the original).
- **Name proximity 500 characters.** Last name within 500 chars of the snippet match, OR full name in the snippet itself, counts as verified.
- **Common last names require a title qualifier.** A bare "Smith" within 500 chars is not enough; "Sen. Smith", "Mayor Smith", etc. is.
- **Paywalled / 4xx / 5xx / timeout pages** are treated as `url_broken`. Conservative — we cannot verify, so we do not credit the source.

## Failure handling

- **Per-source dropping:** if a row has 3 sources and only 2 verify, the row is fine (assuming threshold ≤ 2); the unverified source is dropped silently.
- **Below-threshold re-research:** the orchestrator dispatches ONE additional agent for that single (politician, topic), with the failed URLs as `--exclude-urls`. One attempt only — never two.
- **Still below threshold after re-research:** the row goes to `inform.stance_research_review` with status `pending` and the full audit trail in the `evidence` jsonb column.
- **Politician name doesn't resolve in `essentials.politicians`:** still goes to the review queue but with status `unresolved_politician`. The CSV row is preserved in `full_name_raw`.
- **Idempotency on re-runs:** all upserts keyed on stable identifiers; the same `batch_id` re-running is safe.

## Why no LLM in the verifier

Two reasons: cost and determinism. The verifier runs over every (URL, snippet) pair on every batch, so any per-call LLM cost compounds. More importantly, an LLM-based "does this page support this stance" check is a fuzzier specification than "does this exact passage appear on this page" — the latter has a deterministic correct answer that humans can audit by eye in the CSV.

A future LLM-based snippet→reasoning relevance check (does the captured snippet actually support the stated reasoning?) is reserved as a follow-up, to be added if review-queue patterns show snippets verifying but reasoning still off-target. As of writing, the snippet visible alongside the reasoning in one row of the review surfaces is fast enough for a human reviewer to do this check by eye.

## Domain reputation

Out of scope for the pre-push verifier. The existing `/verify-sources` skill handles post-hoc reputation/trust auditing and is the right place to add it.

## Tables and ownership

- `inform.politician_answers` — existing. (Politician, topic) → numeric value. Pre-push verifier writes here.
- `inform.politician_context` — existing. (Politician, topic) → reasoning + source URL list. Pre-push verifier writes here.
- `inform.politician_context_evidence` — NEW. (Politician, topic, source_url, snippet) one row per verified snippet. Wholesale-replaced on re-research.
- `inform.stance_research_review` — NEW. Review queue for rows that didn't clear the threshold. `evidence` jsonb captures every snippet's verdict.

## Configuration

- **Threshold:** default 2 verified sources per row. Configurable via the verifier call site in the skill orchestrator (STEP 2.5). Lowering it speeds throughput at the cost of weaker grounding.
- **Name proximity window:** 500 chars. Compiled constant `NAME_PROXIMITY_CHARS` in `researchVerifier.ts`.
- **Min snippet words:** 25. Compiled constant `MIN_SNIPPET_WORDS` in `researchVerifier.ts`.

## Follow-ups (not in this implementation)

- Upgrade `/verify-sources` to prefer stored `politician_context_evidence.snippet` over LLM page judgment. Blocked by `sourceVerificationService.ts` currently living only in the `source-verification` worktree; landing that branch unblocks the upgrade.
- Admin UI for the review queue. Schema is built for it.
- LLM-based snippet→reasoning relevance check (option B from the original brainstorm). Add only if review-queue patterns show it's needed.
- Domain reputation as a pre-push gate (currently post-hoc only).
- Read-rank quote verification using the same machinery (different table shape; future work).
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/research-stances/README.md
git commit -m "docs(stance-research): architecture and decisions README"
```

---

## Task 13: Integration smoke test

**Files:**
- Manual operation only (no new code).

This task validates the full pipeline end-to-end against real data. It is run once after all preceding tasks are complete and is not part of CI.

- [ ] **Step 1: Pick a low-stakes target politician**

Choose one politician with a small but non-trivial public footprint (e.g., a Bloomington City Council member with documented votes). Pick 2–3 topics where you expect to find sources and 1 topic where you expect insufficient evidence (to exercise the review-queue path).

- [ ] **Step 2: Run the skill in normal mode**

```
/research-stances "Politician Name" --topics topic1,topic2,topic3,topic4
```

- [ ] **Step 3: Manually inspect outputs in the batch directory**

```bash
ls ev-accounts/backend/data/stance-research/<BATCH_ID>/
# Expect: stances.csv, evidence.csv, verify-pass1.json, possibly verify-pass2.json
```

For each row in `stances.csv`, eyeball the corresponding rows in `evidence.csv`. Each cited URL should have at least one snippet that quotes from or summarizes the politician's position.

- [ ] **Step 4: Verify production tables**

```bash
cd ev-accounts/backend && set -a && source .env && set +a && \
  psql "$DATABASE_URL" \
    -c "SELECT topic_id, value FROM inform.politician_answers WHERE politician_id IN (SELECT id FROM essentials.politicians WHERE full_name = 'Politician Name');" \
    -c "SELECT topic_id, source_url, LEFT(snippet, 80) FROM inform.politician_context_evidence WHERE politician_id IN (SELECT id FROM essentials.politicians WHERE full_name = 'Politician Name');" \
    -c "SELECT topic_key, status, verified_source_count FROM inform.stance_research_review WHERE full_name_raw = 'Politician Name';"
```

For each row in `politician_context_evidence`, the snippet text should be findable verbatim on the cited page. Open one or two URLs and confirm by eye.

- [ ] **Step 5: Test the old-prompt fallback path**

Confirm the migration is graceful when the agent emits the OLD format (just `stances.csv` with `source_url_*` columns) — the verifier should drop everything to the review queue with reason `no_snippets_provided` rather than crashing. Simulate by manually creating a `stances.csv` with no `evidence.csv` and running STEP 2.5 directly.

```bash
cd ev-accounts/backend/data/stance-research && mkdir -p smoke-test-fallback && \
  echo 'full_name,external_id,topic_key,value,reasoning
"Test Person",,healthcare,2,"some reasoning"' > smoke-test-fallback/stances.csv && \
  echo 'full_name,topic_key,source_url,snippet,snippet_index' > smoke-test-fallback/evidence.csv
# Then run STEP 2.5 verifier against smoke-test-fallback/ — expect 1 row in needsReResearch with verifiedSources=[]
```

- [ ] **Step 6: Cleanup**

If you used a real politician for the smoke test and want to remove the test data:

```sql
DELETE FROM inform.politician_context_evidence WHERE batch_id = '<BATCH_ID>';
DELETE FROM inform.stance_research_review WHERE batch_id = '<BATCH_ID>';
-- Optionally roll back politician_answers / politician_context if this was a test run.
```

- [ ] **Step 7: Document any anomalies**

If the smoke test surfaced issues (verifier false-rejecting real snippets due to whitespace edge cases, agent not producing evidence.csv reliably, etc.), open issues or fix-up tasks before treating the implementation as complete.

---

## Self-Review

**Spec coverage:**

- ✅ Stage 1 (research with evidence capture) — Tasks 9
- ✅ Stage 2 (deterministic verification, no LLM) — Tasks 2–6
- ✅ Stage 2.5 (bounded re-research, one attempt) — Task 10 STEP 2.6
- ✅ Stage 3 (gated DB push + review queue) — Tasks 8, 10 STEP 4–5
- ✅ Two-CSV format — Task 7, agent prompt change in Task 9
- ✅ `inform.politician_context_evidence` table — Task 1
- ✅ `inform.stance_research_review` table — Task 1
- ✅ Snippet match (verbatim, normalized) — Tasks 2–3
- ✅ Name proximity 500-char rule — Task 4
- ✅ Common last name title qualifier — Task 4
- ✅ URL fetch caching + error mapping — Task 5
- ✅ Threshold partitioning — Task 6
- ✅ `inform.politician_context_evidence` write on success — Tasks 8, 10
- ✅ `inform.stance_research_review` write on failure — Tasks 8, 10
- ✅ Rewrite mode verification — Task 11
- ✅ Idempotency on re-runs — migration uniqueness + Task 8 upsert
- ✅ Edge cases (paywalled, timeout, common names, null values, unresolved politicians) — Tasks 4, 5, 8, 10
- ✅ README — Task 12
- ✅ Smoke test — Task 13
- ⏭ `/verify-sources` upgrade — explicitly deferred (out of scope, depends on unmerged worktree); flagged in README follow-ups

**Type consistency check:**
- `StanceRow`, `EvidenceRow`, `VerifiedRow`, `VerifiedSource`, `VerifiedSnippet`, `SnippetVerdict`, `PageFetcher` — all defined once in `researchVerifier.ts` (Tasks 3, 5, 6) and consumed consistently in `researchEvidenceService.ts` (Task 8) and `stanceResearchCsv.ts` (Task 7).
- `verifyEvidence` returns `{ pushable, needsReResearch, reviewQueue }`; orchestrator (Task 10) populates `reviewQueue` after re-research, consistent with the verifier comment in Task 6.
- `MIN_SNIPPET_WORDS` (25) and `NAME_PROXIMITY_CHARS` (500) — constants defined and asserted in tests.
- DB function names (`replaceEvidence`, `upsertReviewRow`) — consistent across Task 8 definition and Task 10 use.

**Placeholder scan:** No "TBD", no "implement appropriate error handling", no "similar to Task N", no naked test stubs. All code blocks contain runnable code; all commands have expected outcomes.
