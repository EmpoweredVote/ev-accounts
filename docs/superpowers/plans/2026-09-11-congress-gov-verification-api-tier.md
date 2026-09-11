# congress.gov official-API verification tier — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When a citation URL is on congress.gov, verify it against the official `api.congress.gov` JSON (bill/member) instead of scraping the bot-blocked HTML, slotting a source-specific adapter ahead of the generic fetch ladder and falling through cleanly when there is no key or no match.

**Architecture:** A new `congressAdapter` parses a congress.gov URL into an API reference and builds one plain-text composite (title + CRS summaries + sponsor/cosponsor names + latest actions + best-effort bill text) that the existing deterministic snippet matcher (`researchVerifier`) consumes. `verificationFetch` calls it first in `session.fetch(url)`, before the robots gate; any `null` (not congress.gov, unparseable, no key, or no API match) falls through to today's ladder (tier 1 → Wayback) with no regression. A small api.data.gov rate limiter mirrors `fecRateLimiter` in its own key space; the FEC limiter is untouched.

**Tech Stack:** TypeScript (ESM, `moduleResolution: bundler`, `.js` import specifiers), Node 20 global `fetch`, Vitest, Zod (env), `@upstash/redis` (optional, with in-process fallback).

## Global Constraints

- No vendor, no headless browser, no UA spoofing — official government API only (decision 0003 rung 0/2). Copy exact values, do not reword existing constants.
- Adapter MUST be a no-op when `CONGRESS_GOV_API_KEY` is unset: return `null` → ladder proceeds exactly as today. The server must still start without the key (`z.string().optional()`).
- Do NOT modify `backend/src/lib/fecRateLimiter.ts` — it has a documented stall incident; the congress path takes zero blast radius on it.
- Import specifiers use the `.js` extension (e.g. `./verificationFetch.js`), matching the existing files.
- Reuse `htmlToText` exported from `verificationFetch.ts` for HTML stripping — do not write a second stripper.
- Run all commands from `backend/`. Test runner: `npx vitest run <path>`. Typecheck: `npx tsc --noEmit`.
- This is a shared checkout on branch `congress-gov/verification-api-tier`. Stage files by explicit path only — never `git add -A`/`.`/`-a`. Recheck `git branch --show-current` before each commit.

---

### Task 1: api.data.gov rate limiter (own key space)

**Files:**
- Create: `backend/src/lib/adapters/apiDataGovRateLimiter.ts`
- Test: `backend/src/lib/adapters/apiDataGovRateLimiter.test.ts`

**Interfaces:**
- Consumes: `@upstash/redis` (mocked in tests).
- Produces: `acquireApiDataGovSlot(service: string, signal?: AbortSignal): Promise<void>` — resolves when the current UTC-minute bucket for `${service}` is under budget; throws after a bounded wait or on abort.

- [ ] **Step 1: Write the failing test**

```ts
// backend/src/lib/adapters/apiDataGovRateLimiter.test.ts
import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';

const ORIGINAL_ENV = { ...process.env };

beforeEach(() => {
  vi.resetModules();
  // No UPSTASH_* env → module uses the in-process counter (single-instance path).
  delete process.env.UPSTASH_REDIS_REST_URL;
  delete process.env.UPSTASH_REDIS_REST_TOKEN;
  delete process.env.API_DATA_GOV_RATE_LIMIT_PER_MINUTE;
  delete process.env.API_DATA_GOV_RATE_LIMIT_MAX_WAIT_MS;
});

afterEach(() => {
  vi.useRealTimers();
  process.env = { ...ORIGINAL_ENV };
});

describe('acquireApiDataGovSlot', () => {
  it('resolves immediately while under the per-minute budget', async () => {
    process.env.API_DATA_GOV_RATE_LIMIT_PER_MINUTE = '3';
    const { acquireApiDataGovSlot } = await import('./apiDataGovRateLimiter.js');
    await expect(acquireApiDataGovSlot('congress')).resolves.toBeUndefined();
    await expect(acquireApiDataGovSlot('congress')).resolves.toBeUndefined();
    await expect(acquireApiDataGovSlot('congress')).resolves.toBeUndefined();
  });

  it('throws when aborted before a slot opens', async () => {
    process.env.API_DATA_GOV_RATE_LIMIT_PER_MINUTE = '1';
    const { acquireApiDataGovSlot } = await import('./apiDataGovRateLimiter.js');
    await acquireApiDataGovSlot('congress'); // consume the single slot this minute
    const ac = new AbortController();
    ac.abort();
    await expect(acquireApiDataGovSlot('congress', ac.signal)).rejects.toThrow(/aborted/i);
  });

  it('keeps separate budgets per service key space', async () => {
    process.env.API_DATA_GOV_RATE_LIMIT_PER_MINUTE = '1';
    const { acquireApiDataGovSlot } = await import('./apiDataGovRateLimiter.js');
    await acquireApiDataGovSlot('congress');
    // A different service has its own bucket, so this must still resolve.
    await expect(acquireApiDataGovSlot('other')).resolves.toBeUndefined();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && npx vitest run src/lib/adapters/apiDataGovRateLimiter.test.ts`
Expected: FAIL — `Cannot find module './apiDataGovRateLimiter.js'`.

- [ ] **Step 3: Write minimal implementation**

```ts
// backend/src/lib/adapters/apiDataGovRateLimiter.ts
/**
 * apiDataGovRateLimiter — a shared per-UTC-minute pacing gate for outbound
 * api.data.gov requests, keyed by service so each API (e.g. 'congress') gets its
 * own budget. Mirrors fecRateLimiter.ts's design (Redis INCR/EXPIRE per-minute
 * bucket, in-process fallback, bounded wait, AbortSignal) in a separate key
 * space. fecRateLimiter.ts is deliberately left untouched.
 *
 * Volume on the congress verification path is low, so the in-process fallback is
 * usually sufficient; the Redis path only matters when multiple instances run.
 */
import { Redis } from '@upstash/redis';

let redisClient: Redis | null = null;
let redisInitAttempted = false;

function getRedisClient(): Redis | null {
  if (redisInitAttempted) return redisClient;
  redisInitAttempted = true;
  if (!process.env.UPSTASH_REDIS_REST_URL || !process.env.UPSTASH_REDIS_REST_TOKEN) {
    return null;
  }
  try {
    redisClient = Redis.fromEnv();
    return redisClient;
  } catch (err) {
    console.warn('[apiDataGovRateLimiter] Redis init failed — using in-process fallback:', err);
    return null;
  }
}

const inProcessCounters = new Map<string, number>();
const BUCKET_TTL_SECONDS = 90;

function inProcessIncr(key: string): number {
  const n = (inProcessCounters.get(key) ?? 0) + 1;
  inProcessCounters.set(key, n);
  setTimeout(() => inProcessCounters.delete(key), BUCKET_TTL_SECONDS * 1000);
  return n;
}

const DEFAULT_BUDGET_PER_MINUTE = 15; // ~900/hr, 10% under the ~1,000/hr api.data.gov ceiling
const DEFAULT_MAX_WAIT_MS = 120_000;
const POLL_INTERVAL_MS = 2000;
const REDIS_OP_TIMEOUT_MS = 5000;

function getBudgetPerMinute(): number {
  const parsed = parseInt(process.env.API_DATA_GOV_RATE_LIMIT_PER_MINUTE ?? '', 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : DEFAULT_BUDGET_PER_MINUTE;
}

function getMaxWaitMs(): number {
  const parsed = parseInt(process.env.API_DATA_GOV_RATE_LIMIT_MAX_WAIT_MS ?? '', 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : DEFAULT_MAX_WAIT_MS;
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function withTimeout<T>(work: Promise<T>, ms: number, label: string): Promise<T> {
  let timer: ReturnType<typeof setTimeout> | undefined;
  const bound = new Promise<never>((_, reject) => {
    timer = setTimeout(() => reject(new Error(label)), ms);
  });
  try {
    return await Promise.race([work, bound]);
  } finally {
    if (timer) clearTimeout(timer);
  }
}

/**
 * Resolve when the current UTC-minute bucket for `service` is under budget;
 * otherwise poll until a fresh bucket opens. Throws after getMaxWaitMs() (a
 * per-minute bucket always frees within ~60s, so passing the ceiling means
 * something waiting will not fix) or when `signal` aborts.
 */
export async function acquireApiDataGovSlot(service: string, signal?: AbortSignal): Promise<void> {
  const deadline = Date.now() + getMaxWaitMs();
  for (;;) {
    if (signal?.aborted) {
      throw new Error(`[apiDataGovRateLimiter] aborted while waiting for a ${service} slot`);
    }
    const bucket = new Date().toISOString().slice(0, 16); // YYYY-MM-DDTHH:MM
    const key = `${service}:ratelimit:${bucket}`;
    const redis = getRedisClient();

    let count: number;
    if (redis) {
      try {
        count = await withTimeout(redis.incr(key), REDIS_OP_TIMEOUT_MS, '[apiDataGovRateLimiter] Redis incr timed out');
        if (count === 1) {
          await withTimeout(redis.expire(key, BUCKET_TTL_SECONDS), REDIS_OP_TIMEOUT_MS, '[apiDataGovRateLimiter] Redis expire timed out');
        }
      } catch (err) {
        console.warn('[apiDataGovRateLimiter] Redis incr failed — degrading to in-process counter:', err);
        count = inProcessIncr(key);
      }
    } else {
      count = inProcessIncr(key);
    }

    if (count <= getBudgetPerMinute()) return;

    if (Date.now() >= deadline) {
      throw new Error(
        `[apiDataGovRateLimiter] gave up waiting for a ${service} slot after ${getMaxWaitMs()}ms ` +
        `(bucket ${key} at ${count}/${getBudgetPerMinute()})`,
      );
    }
    await sleep(POLL_INTERVAL_MS);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && npx vitest run src/lib/adapters/apiDataGovRateLimiter.test.ts`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
cd backend && git -C .. add backend/src/lib/adapters/apiDataGovRateLimiter.ts backend/src/lib/adapters/apiDataGovRateLimiter.test.ts
git -C .. commit -m "feat(verification): api.data.gov per-minute rate limiter (own key space)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 2: congress.gov URL parser (pure)

**Files:**
- Create: `backend/src/lib/adapters/congressAdapter.ts` (parser only in this task)
- Test: `backend/src/lib/adapters/congressAdapter.test.ts`

**Interfaces:**
- Produces:
  - `type CongressRef = { kind: 'bill'; congress: number; billType: string; number: number } | { kind: 'member'; bioguideId: string }`
  - `function parseCongressUrl(url: string): CongressRef | null`
  - `billType` is the API code (`hr`, `s`, `hres`, `sres`, `hjres`, `sjres`, `hconres`, `sconres`).

- [ ] **Step 1: Write the failing test**

```ts
// backend/src/lib/adapters/congressAdapter.test.ts
import { describe, it, expect } from 'vitest';
import { parseCongressUrl } from './congressAdapter.js';

describe('parseCongressUrl', () => {
  it('parses a house-bill overview URL (congress is a slug)', () => {
    expect(parseCongressUrl('https://www.congress.gov/bill/119th-congress/house-bill/1234'))
      .toEqual({ kind: 'bill', congress: 119, billType: 'hr', number: 1234 });
  });

  it('ignores bill sub-paths (/cosponsors, /text, /all-actions)', () => {
    const base = { kind: 'bill', congress: 118, billType: 's', number: 42 };
    expect(parseCongressUrl('https://www.congress.gov/bill/118th-congress/senate-bill/42/cosponsors')).toEqual(base);
    expect(parseCongressUrl('https://www.congress.gov/bill/118th-congress/senate-bill/42/text')).toEqual(base);
    expect(parseCongressUrl('https://www.congress.gov/bill/118th-congress/senate-bill/42/all-actions')).toEqual(base);
  });

  it('maps every bill-type slug to its API code', () => {
    const t = (slug: string) => parseCongressUrl(`https://www.congress.gov/bill/119th-congress/${slug}/1`);
    expect(t('house-resolution')).toMatchObject({ billType: 'hres' });
    expect(t('senate-resolution')).toMatchObject({ billType: 'sres' });
    expect(t('house-joint-resolution')).toMatchObject({ billType: 'hjres' });
    expect(t('senate-joint-resolution')).toMatchObject({ billType: 'sjres' });
    expect(t('house-concurrent-resolution')).toMatchObject({ billType: 'hconres' });
    expect(t('senate-concurrent-resolution')).toMatchObject({ billType: 'sconres' });
  });

  it('parses a member URL with a name slug and trailing bioguideId', () => {
    expect(parseCongressUrl('https://www.congress.gov/member/ayanna-pressley/P000617'))
      .toEqual({ kind: 'member', bioguideId: 'P000617' });
  });

  it('parses a member URL that carries a query string', () => {
    expect(parseCongressUrl('https://www.congress.gov/member/linda-sanchez/S001156?q=%7B%22x%22%3A1%7D'))
      .toEqual({ kind: 'member', bioguideId: 'S001156' });
  });

  it('returns null for out-of-scope and non-congress URLs', () => {
    expect(parseCongressUrl('https://www.congress.gov/event/119th-congress/senate-event/LC73719/text')).toBeNull();
    expect(parseCongressUrl('https://www.congress.gov/congressional-record/119th-congress/x/1')).toBeNull();
    expect(parseCongressUrl('https://www.congress.gov/committee/house-committee/foo')).toBeNull();
    expect(parseCongressUrl('https://example.com/bill/119th-congress/house-bill/1')).toBeNull();
    expect(parseCongressUrl('not a url')).toBeNull();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && npx vitest run src/lib/adapters/congressAdapter.test.ts`
Expected: FAIL — `parseCongressUrl` is not exported / module has no such member.

- [ ] **Step 3: Write minimal implementation**

```ts
// backend/src/lib/adapters/congressAdapter.ts
/**
 * congressAdapter — source-specific verification tier for congress.gov.
 *
 * congress.gov 403s a plain fetch (fingerprint-based; spoofing is forbidden by
 * decision 0003 rung 0). Instead of scraping the HTML, this adapter parses a
 * congress.gov bill/member URL and rebuilds the human-visible text from the
 * official api.congress.gov JSON so the deterministic snippet matcher
 * (researchVerifier) can run. It returns null — a clean fall-through to the
 * generic ladder — for anything it does not handle (non-congress host,
 * unparseable path, missing key, or no API match).
 */

export type CongressRef =
  | { kind: 'bill'; congress: number; billType: string; number: number }
  | { kind: 'member'; bioguideId: string };

/** congress.gov bill-type URL slug → api.congress.gov bill-type code. */
const BILL_TYPE_MAP: Record<string, string> = {
  'house-bill': 'hr',
  'senate-bill': 's',
  'house-resolution': 'hres',
  'senate-resolution': 'sres',
  'house-joint-resolution': 'hjres',
  'senate-joint-resolution': 'sjres',
  'house-concurrent-resolution': 'hconres',
  'senate-concurrent-resolution': 'sconres',
};

const BIOGUIDE_RE = /^[A-Z]\d{6}$/;

/**
 * Parse a congress.gov URL into an API reference, or null when it is not a
 * bill/member page we can serve from the API. Bill sub-paths (/cosponsors,
 * /text, /all-actions, /all-info) resolve to the same bill ref — the adapter
 * builds one rich composite regardless of which sub-page was cited.
 */
export function parseCongressUrl(url: string): CongressRef | null {
  let u: URL;
  try {
    u = new URL(url);
  } catch {
    return null;
  }
  const host = u.hostname.toLowerCase();
  if (host !== 'congress.gov' && host !== 'www.congress.gov') return null;

  const seg = u.pathname.split('/').filter(Boolean);

  // /bill/<congress-slug>/<type-slug>/<number>[/<subpath>...]
  if (seg[0] === 'bill' && seg.length >= 4) {
    const congress = parseInt(seg[1], 10); // "119th-congress" → 119
    const billType = BILL_TYPE_MAP[seg[2]];
    const number = parseInt(seg[3], 10);
    if (Number.isFinite(congress) && billType && Number.isFinite(number)) {
      return { kind: 'bill', congress, billType, number };
    }
    return null;
  }

  // /member/<name-slug>/<bioguideId> or /member/<bioguideId>
  if (seg[0] === 'member' && seg.length >= 2) {
    const last = seg[seg.length - 1];
    if (BIOGUIDE_RE.test(last)) return { kind: 'member', bioguideId: last };
    return null;
  }

  return null; // /event, /congressional-record, /committee, /amendment, /nomination, …
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && npx vitest run src/lib/adapters/congressAdapter.test.ts`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git -C .. add backend/src/lib/adapters/congressAdapter.ts backend/src/lib/adapters/congressAdapter.test.ts
git -C .. commit -m "feat(verification): parse congress.gov bill/member URLs to API refs

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 3: build page text from the official API

**Files:**
- Modify: `backend/src/lib/adapters/congressAdapter.ts` (add the fetcher)
- Test: `backend/src/lib/adapters/congressAdapter.test.ts` (add fetcher cases)

**Interfaces:**
- Consumes: `parseCongressUrl` (Task 2); `acquireApiDataGovSlot` (Task 1); `htmlToText` from `../verificationFetch.js`.
- Produces:
  - `type FetchLike = (url: string, init?: RequestInit) => Promise<Response>`
  - `interface CongressDeps { fetchImpl?: FetchLike; apiKey?: string }`
  - `async function fetchCongressPageText(url: string, deps?: CongressDeps): Promise<string | null>`

- [ ] **Step 1: Write the failing test**

```ts
// append to backend/src/lib/adapters/congressAdapter.test.ts
import { fetchCongressPageText } from './congressAdapter.js';
import { matchSnippet, checkNameProximity } from '../researchVerifier.js';

/** Minimal Response-like fake for a JSON-or-text body. */
function fakeRes(body: unknown, ok = true): Response {
  return {
    ok,
    status: ok ? 200 : 404,
    json: async () => body,
    text: async () => (typeof body === 'string' ? body : JSON.stringify(body)),
  } as unknown as Response;
}

/** Route a fake api.congress.gov client by URL substring. Unlisted → 404. */
function routedFetch(routes: Array<[string, unknown]>): (url: string) => Promise<Response> {
  return async (url: string) => {
    for (const [needle, body] of routes) {
      if (url.includes(needle)) return fakeRes(body);
    }
    return fakeRes({ error: 'not found' }, false);
  };
}

describe('fetchCongressPageText', () => {
  const KEY = 'test-key';

  it('returns null when the URL is not a congress.gov bill/member', async () => {
    const r = await fetchCongressPageText('https://example.com/x', { apiKey: KEY, fetchImpl: routedFetch([]) });
    expect(r).toBeNull();
  });

  it('is a no-op (null) when no key is available', async () => {
    delete process.env.CONGRESS_GOV_API_KEY;
    const r = await fetchCongressPageText('https://www.congress.gov/bill/119th-congress/house-bill/1', {
      fetchImpl: routedFetch([['/bill/', { bill: { title: 'x' } }]]),
    });
    expect(r).toBeNull();
  });

  it('builds a composite that a stored bill snippet verifies against', async () => {
    const summary =
      'This bill directs the Secretary to establish a grant program that expands ' +
      'access to affordable childcare for working families across every state and ' +
      'territory, and authorizes appropriations for fiscal years 2025 through 2030.';
    const fetchImpl = routedFetch([
      ['/bill/119/hr/1234?', { bill: {
        title: 'Affordable Childcare for Working Families Act',
        policyArea: { name: 'Families' },
        sponsors: [{ fullName: 'Rep. Ayanna Pressley' }],
        latestAction: { text: 'Referred to the Committee on Education.' },
      } }],
      ['/bill/119/hr/1234/summaries', { summaries: [{ text: `<p>${summary}</p>` }] }],
      ['/bill/119/hr/1234/cosponsors', { cosponsors: [{ fullName: 'Rep. Katherine Clark' }] }],
      ['/bill/119/hr/1234/actions', { actions: [{ text: 'Introduced in House.' }] }],
      ['/bill/119/hr/1234/text', { textVersions: [] }],
    ]);

    const text = await fetchCongressPageText(
      'https://www.congress.gov/bill/119th-congress/house-bill/1234/cosponsors',
      { apiKey: KEY, fetchImpl },
    );
    expect(text).toBeTruthy();
    expect(text!).toContain('Affordable Childcare for Working Families Act');
    expect(text!).toContain('Pressley');

    // The stored snippet (>=25 words) must verify through the real matcher, and
    // the sponsor's name must sit within the proximity window of the match.
    const snippet = summary; // a research agent quoting the CRS summary verbatim
    const m = matchSnippet(snippet, text!);
    expect(m.verdict).toBe('verified');
    if (m.verdict === 'verified') {
      const prox = checkNameProximity({
        fullName: 'Ayanna Pressley', lastName: 'Pressley', pageText: text!,
        matchOffsetInNormalized: m.matchOffset,
      });
      expect(prox.verdict).toBe('verified');
    }
  });

  it('falls through (null) when the bill endpoint 404s', async () => {
    const r = await fetchCongressPageText('https://www.congress.gov/bill/119th-congress/house-bill/9', {
      apiKey: KEY, fetchImpl: routedFetch([]), // every route 404s
    });
    expect(r).toBeNull();
  });

  it('best-effort /text: a text-hop failure still returns the metadata composite', async () => {
    const fetchImpl = routedFetch([
      ['/bill/119/hr/5?', { bill: { title: 'Test Act of 2025 for the public record and general welfare', sponsors: [{ fullName: 'Rep. Seth Moulton' }] } }],
      // no /summaries, /cosponsors, /actions, /text routes → all 404 (swallowed)
    ]);
    const text = await fetchCongressPageText('https://www.congress.gov/bill/119th-congress/house-bill/5/text', { apiKey: KEY, fetchImpl });
    expect(text).toContain('Test Act of 2025');
  });

  it('builds member text from the member endpoint', async () => {
    const fetchImpl = routedFetch([
      ['/member/P000617', { member: {
        directOrderName: 'Ayanna Pressley',
        partyHistory: [{ partyName: 'Democratic' }],
        state: 'Massachusetts',
        terms: [{ chamber: 'House of Representatives' }],
      } }],
    ]);
    const text = await fetchCongressPageText('https://www.congress.gov/member/ayanna-pressley/P000617', { apiKey: KEY, fetchImpl });
    expect(text).toContain('Ayanna Pressley');
    expect(text).toContain('Massachusetts');
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && npx vitest run src/lib/adapters/congressAdapter.test.ts`
Expected: FAIL — `fetchCongressPageText` is not exported.

- [ ] **Step 3: Write minimal implementation**

Append to `backend/src/lib/adapters/congressAdapter.ts`:

```ts
import { htmlToText } from '../verificationFetch.js';
import { acquireApiDataGovSlot } from './apiDataGovRateLimiter.js';

export type FetchLike = (url: string, init?: RequestInit) => Promise<Response>;

export interface CongressDeps {
  fetchImpl?: FetchLike;
  apiKey?: string;
}

const API_BASE = 'https://api.congress.gov/v3';
/** How many of the newest actions to include (latest action is already shown). */
const MAX_ACTIONS = 15;

/**
 * GET a v3 JSON resource with the key + format appended. Acquires a rate-limit
 * slot first. Returns parsed JSON, or null on any non-2xx / error (best-effort:
 * a missing sub-resource must not fail the whole composite).
 */
async function getJson(path: string, apiKey: string, fetchImpl: FetchLike): Promise<any | null> {
  const sep = path.includes('?') ? '&' : '?';
  const url = `${API_BASE}${path}${sep}format=json&api_key=${encodeURIComponent(apiKey)}`;
  try {
    await acquireApiDataGovSlot('congress');
    const res = await fetchImpl(url);
    if (!res.ok) return null;
    return await res.json();
  } catch {
    return null;
  }
}

/** Fetch and strip a bill's newest text version (best-effort). */
async function fetchBillText(
  base: string, apiKey: string, fetchImpl: FetchLike,
): Promise<string | null> {
  const data = await getJson(`${base}/text`, apiKey, fetchImpl);
  const versions: any[] = data?.textVersions ?? [];
  // Prefer a "Formatted Text" (HTML) format; else the first format with a URL.
  let target: string | undefined;
  for (const v of versions) {
    const formats: any[] = v?.formats ?? [];
    const html = formats.find((f) => /formatted text/i.test(f?.type ?? '') && f?.url);
    if (html) { target = html.url; break; }
    if (!target && formats[0]?.url) target = formats[0].url;
  }
  if (!target) return null;
  try {
    await acquireApiDataGovSlot('congress');
    const res = await fetchImpl(target);
    if (!res.ok) return null;
    const body = await res.text();
    const text = htmlToText(body);
    return text || null;
  } catch {
    return null;
  }
}

async function buildBillText(
  ref: Extract<CongressRef, { kind: 'bill' }>, apiKey: string, fetchImpl: FetchLike,
): Promise<string | null> {
  const base = `/bill/${ref.congress}/${ref.billType}/${ref.number}`;
  const main = await getJson(base, apiKey, fetchImpl);
  const bill = main?.bill;
  if (!bill) return null; // no overview → nothing to verify against; fall through

  const parts: string[] = [];
  if (bill.title) parts.push(String(bill.title));
  if (bill.policyArea?.name) parts.push(`Policy area: ${bill.policyArea.name}`);
  const sponsors: any[] = bill.sponsors ?? [];
  if (sponsors.length) parts.push('Sponsor: ' + sponsors.map((s) => s.fullName).filter(Boolean).join(', '));
  if (bill.latestAction?.text) parts.push('Latest action: ' + bill.latestAction.text);

  const summaries = await getJson(`${base}/summaries`, apiKey, fetchImpl);
  for (const s of (summaries?.summaries ?? [])) {
    if (s?.text) parts.push(htmlToText(String(s.text)));
  }

  const cosponsors = await getJson(`${base}/cosponsors`, apiKey, fetchImpl);
  const coNames = (cosponsors?.cosponsors ?? []).map((c: any) => c.fullName).filter(Boolean);
  if (coNames.length) parts.push('Cosponsors: ' + coNames.join(', '));

  const actions = await getJson(`${base}/actions`, apiKey, fetchImpl);
  const actionTexts = (actions?.actions ?? []).slice(0, MAX_ACTIONS).map((a: any) => a.text).filter(Boolean);
  if (actionTexts.length) parts.push('Actions: ' + actionTexts.join(' '));

  const billText = await fetchBillText(base, apiKey, fetchImpl); // best-effort
  if (billText) parts.push(billText);

  const out = parts.join('\n\n').trim();
  return out || null;
}

async function buildMemberText(
  ref: Extract<CongressRef, { kind: 'member' }>, apiKey: string, fetchImpl: FetchLike,
): Promise<string | null> {
  const main = await getJson(`/member/${ref.bioguideId}`, apiKey, fetchImpl);
  const m = main?.member;
  if (!m) return null;
  const parts: string[] = [];
  const name = m.directOrderName ?? m.invertedOrderName ?? m.name;
  if (name) parts.push(String(name));
  const party = (m.partyHistory ?? []).map((p: any) => p.partyName).filter(Boolean).join(', ');
  if (party) parts.push(`Party: ${party}`);
  if (m.state) parts.push(`State: ${m.state}`);
  const chambers = (m.terms ?? []).map((t: any) => t.chamber).filter(Boolean);
  if (chambers.length) parts.push(`Chamber: ${[...new Set(chambers)].join(', ')}`);
  const out = parts.join('\n\n').trim();
  return out || null;
}

/**
 * Build plain-text for a congress.gov URL from the official API, or null when it
 * cannot (not a congress.gov bill/member, no key, or no API match). A null
 * result is the ladder's signal to fall through to the generic tiers.
 */
export async function fetchCongressPageText(url: string, deps: CongressDeps = {}): Promise<string | null> {
  const ref = parseCongressUrl(url);
  if (!ref) return null;
  const apiKey = deps.apiKey ?? process.env.CONGRESS_GOV_API_KEY;
  if (!apiKey) return null; // no-op: adapter degrades, URL falls through to the ladder
  const fetchImpl = deps.fetchImpl ?? fetch;
  return ref.kind === 'bill'
    ? buildBillText(ref, apiKey, fetchImpl)
    : buildMemberText(ref, apiKey, fetchImpl);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && npx vitest run src/lib/adapters/congressAdapter.test.ts`
Expected: PASS (all parser + fetcher cases).

- [ ] **Step 5: Commit**

```bash
git -C .. add backend/src/lib/adapters/congressAdapter.ts backend/src/lib/adapters/congressAdapter.test.ts
git -C .. commit -m "feat(verification): build congress.gov page text from the official API

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 4: env key + ladder wiring

**Files:**
- Modify: `backend/src/lib/env.ts` (add optional key)
- Modify: `backend/src/lib/verificationFetch.ts` (add `congressAdapter` dep; call first in `fetch`)
- Test: `backend/src/lib/verificationFetch.test.ts` (add wiring cases)

**Interfaces:**
- Consumes: `fetchCongressPageText` (Task 3).
- Produces: `VerificationFetchDeps.congressAdapter?: (url: string) => Promise<string | null>`.

- [ ] **Step 1: Write the failing test**

Add to `backend/src/lib/verificationFetch.test.ts` (inside a new `describe`):

```ts
describe('createVerificationFetchSession — congress.gov adapter tier', () => {
  const longPage = 'Affordable Childcare Act. ' + 'grant program expands access to affordable childcare for working families. '.repeat(20);

  it('returns the congress adapter result ahead of tier 1', async () => {
    let httpCalled = false;
    const session = createVerificationFetchSession({
      congressAdapter: async () => longPage,
      robotsAllows: async () => true,
      httpFetch: async () => { httpCalled = true; return 'tier1'; },
      wayback: async () => null,
    });
    const out = await session.fetch('https://www.congress.gov/bill/119th-congress/house-bill/1234');
    expect(out).toBe(longPage);
    expect(httpCalled).toBe(false);
  });

  it('falls through to the ladder when the adapter returns null', async () => {
    let httpCalled = false;
    const session = createVerificationFetchSession({
      congressAdapter: async () => null,
      robotsAllows: async () => true,
      httpFetch: async () => { httpCalled = true; return longPage; },
      wayback: async () => null,
    });
    const out = await session.fetch('https://www.congress.gov/bill/119th-congress/house-bill/1234');
    expect(out).toBe(longPage);
    expect(httpCalled).toBe(true);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && npx vitest run src/lib/verificationFetch.test.ts`
Expected: FAIL — `congressAdapter` is not a known dep (TS error) / adapter not invoked (httpCalled true in first test).

- [ ] **Step 3a: Add the env key**

In `backend/src/lib/env.ts`, immediately after the `FEC_API_KEY` line (line ~50):

```ts
  // CONGRESS_GOV_API_KEY: free api.data.gov key (register at https://api.congress.gov)
  // for the congress.gov official-API verification tier (congressAdapter). Optional —
  // absent = the adapter is a no-op and congress.gov URLs fall through to the fetch
  // ladder (tier 1 → Wayback), today's behavior. Lives in the Render dashboard, never in git.
  CONGRESS_GOV_API_KEY: z.string().optional(),
```

- [ ] **Step 3b: Wire the adapter into the ladder**

In `backend/src/lib/verificationFetch.ts`:

1. Add the import near the top (after the existing imports):

```ts
import { fetchCongressPageText } from './adapters/congressAdapter.js';
```

2. Add the dep to `VerificationFetchDeps` (alongside `robotsAllows`, `httpFetch`, `wayback`):

```ts
  /** Source-specific tier — congress.gov official API. Runs before the generic tiers. */
  congressAdapter?: (url: string) => Promise<string | null>;
```

3. In `createVerificationFetchSession`, resolve the default:

```ts
  const congressAdapter = deps.congressAdapter ?? fetchCongressPageText;
```

4. As the FIRST thing inside `async fetch(url)` (before the robots gate):

```ts
      // Source-specific tier — congress.gov official API (before the generic
      // tiers). It calls api.congress.gov under our own key: an authorized
      // official API, not a fetch of the live congress.gov site, so it precedes
      // the robots gate. A null result (not congress.gov, unparseable, no key, or
      // no API match) falls through to today's ladder unchanged.
      try {
        const t = await congressAdapter(url);
        if (t && looksLikeRealPage(t)) return t;
      } catch {
        /* fall through to the generic ladder */
      }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd backend && npx vitest run src/lib/verificationFetch.test.ts && npx tsc --noEmit`
Expected: PASS (new wiring tests + existing verificationFetch tests); typecheck clean.

- [ ] **Step 5: Commit**

```bash
git -C .. add backend/src/lib/env.ts backend/src/lib/verificationFetch.ts backend/src/lib/verificationFetch.test.ts
git -C .. commit -m "feat(verification): wire congress.gov API tier ahead of the fetch ladder

Adds optional CONGRESS_GOV_API_KEY (server still starts without it) and calls
fetchCongressPageText first in session.fetch; a null result falls through to
robots -> tier 1 -> Wayback with no regression.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 5: measurement script (re-measure the STEP 1 sample)

**Files:**
- Create: `backend/scripts/measure-congress-api-tier.ts`

**Interfaces:**
- Consumes: `createVerificationFetchSession`, `fetchViaHttp`, `fetchViaWayback` from `../src/lib/verificationFetch.js`; `fetchCongressPageText` from `../src/lib/adapters/congressAdapter.js`; `matchSnippet`, `checkNameProximity` from `../src/lib/researchVerifier.js`.
- Input: a JSON file of rows `{ url, snippet, full_name, last_name }`. Chris produces it from prod `source_verifications` (columns vary — the script does not guess the schema). `CONGRESS_GOV_API_KEY` in the environment.
- Output: printed counts — congress.gov rows, tier-1 fails, of those how many Wayback/CDX recovers, and how many the API tier NEWLY verifies (the recovered count). Plus `--dry` (parse-only, no key/network) for a runnable smoke check.

**Why an input file, not a built-in query:** the exact `source_verifications` column names are not known from the repo, and inventing SQL risks a wrong/misleading measurement. Feeding rows in keeps the measurement correct and lets Chris pick the query. The `--dry` mode still runs with zero setup so the script is verified before the keyed run.

- [ ] **Step 1: Write the script**

```ts
// backend/scripts/measure-congress-api-tier.ts
/**
 * measure-congress-api-tier — re-measure the STEP 1 sample for the congress.gov
 * official-API tier. Dev/ops tool (not part of the server bundle).
 *
 * Usage:
 *   # smoke test, no key, no network — reports URL parse coverage only:
 *   npx tsx scripts/measure-congress-api-tier.ts --dry rows.json
 *
 *   # full measurement (needs CONGRESS_GOV_API_KEY in the environment):
 *   CONGRESS_GOV_API_KEY=... npx tsx scripts/measure-congress-api-tier.ts rows.json
 *
 * rows.json: [{ "url": "...", "snippet": "...", "full_name": "...", "last_name": "..." }]
 * Produce it from prod source_verifications (congress.gov rows only) with whatever
 * query matches the live column names — this script intentionally does not guess them.
 */
import { readFileSync } from 'node:fs';
import {
  createVerificationFetchSession,
  fetchViaHttp,
  fetchViaWayback,
  looksLikeRealPage,
} from '../src/lib/verificationFetch.js';
import { fetchCongressPageText, parseCongressUrl } from '../src/lib/adapters/congressAdapter.js';
import { matchSnippet, checkNameProximity } from '../src/lib/researchVerifier.js';

interface Row { url: string; snippet: string; full_name: string; last_name: string }

function verifies(text: string, row: Row): boolean {
  const m = matchSnippet(row.snippet, text);
  if (m.verdict !== 'verified') return false;
  const p = checkNameProximity({
    fullName: row.full_name, lastName: row.last_name, pageText: text,
    matchOffsetInNormalized: m.matchOffset,
  });
  return p.verdict === 'verified';
}

async function main() {
  const args = process.argv.slice(2);
  const dry = args.includes('--dry');
  const file = args.find((a) => !a.startsWith('--'));
  if (!file) { console.error('usage: measure-congress-api-tier.ts [--dry] rows.json'); process.exit(2); }

  const rows: Row[] = JSON.parse(readFileSync(file, 'utf8'));
  const congress = rows.filter((r) => parseCongressUrl(r.url) !== null);
  console.log(`rows: ${rows.length} | congress.gov bill/member (parseable): ${congress.length}`);

  if (dry) {
    const unparsed = rows.filter((r) => /congress\.gov/i.test(r.url) && parseCongressUrl(r.url) === null);
    console.log(`congress.gov URLs the parser SKIPS (out of scope): ${unparsed.length}`);
    for (const r of unparsed.slice(0, 20)) console.log('  skip:', r.url);
    return;
  }

  if (!process.env.CONGRESS_GOV_API_KEY) { console.error('CONGRESS_GOV_API_KEY is not set'); process.exit(2); }

  // Ladder WITHOUT the adapter (tier 1 -> Wayback) — the current prod baseline.
  const baseline = createVerificationFetchSession({ congressAdapter: async () => null });

  let tier1Fail = 0, waybackRecovered = 0, apiNewlyVerified = 0;
  for (const row of congress) {
    // 1) tier 1 alone
    let tier1Text: string | null = null;
    try { tier1Text = await fetchViaHttp(row.url); } catch { /* 403/err */ }
    const tier1Ok = !!tier1Text && looksLikeRealPage(tier1Text) && verifies(tier1Text, row);
    if (tier1Ok) continue;
    tier1Fail++;

    // 2) Wayback/CDX (the current recovery path)
    let wb: string | null = null;
    try { wb = await fetchViaWayback(row.url); } catch { /* none */ }
    if (wb && looksLikeRealPage(wb) && verifies(wb, row)) { waybackRecovered++; continue; }

    // 3) the API tier — does it NEWLY verify what the baseline could not?
    let api: string | null = null;
    try { api = await fetchCongressPageText(row.url); } catch { /* none */ }
    if (api && verifies(api, row)) apiNewlyVerified++;
  }

  console.log('--- congress.gov API tier re-measure ---');
  console.log(`tier-1 fails:            ${tier1Fail}`);
  console.log(`Wayback/CDX recovered:   ${waybackRecovered}`);
  console.log(`API NEWLY verified:      ${apiNewlyVerified}   <-- recovered count`);
  await baseline.close();
}

main().catch((e) => { console.error(e); process.exit(1); });
```

- [ ] **Step 2: Run the dry smoke check**

Create a tiny fixture and run parse-only (no key, no network):

```bash
cd backend && cat > /tmp/congress-rows.json <<'JSON'
[
  {"url":"https://www.congress.gov/bill/119th-congress/house-bill/1234/cosponsors","snippet":"x","full_name":"A B","last_name":"B"},
  {"url":"https://www.congress.gov/event/119th-congress/senate-event/LC1/text","snippet":"x","full_name":"A B","last_name":"B"}
]
JSON
npx tsx scripts/measure-congress-api-tier.ts --dry /tmp/congress-rows.json
```

Expected: prints `congress.gov bill/member (parseable): 1` and lists the `/event/...` URL as skipped.

- [ ] **Step 3: Commit**

```bash
git -C .. add backend/scripts/measure-congress-api-tier.ts
git -C .. commit -m "chore(verification): re-measure script for the congress.gov API tier

Dev/ops tool: given a rows.json of {url,snippet,full_name,last_name} and
CONGRESS_GOV_API_KEY, reports how many tier-1-failing congress.gov URLs the API
tier newly verifies beyond Wayback/CDX. --dry runs parse-only, no key/network.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

- [ ] **Step 4: Full run (Chris, with the key) — records the acceptance count**

Not an automatable step. Chris exports congress.gov rows from prod `source_verifications` to `rows.json`, sets `CONGRESS_GOV_API_KEY`, and runs:

```bash
cd backend && CONGRESS_GOV_API_KEY=... npx tsx scripts/measure-congress-api-tier.ts rows.json
```

Record `API NEWLY verified` as the recovered count in the task file. If it is ~0 (API text too thin to match stored snippets), that is the STOP-AND-ASK trigger — report and decide whether to keep the tier or let CDX/Wayback cover congress.gov.

---

## Final verification (after Task 4; Task 5 script is standalone)

- [ ] `cd backend && npx vitest run src/lib/adapters/congressAdapter.test.ts src/lib/adapters/apiDataGovRateLimiter.test.ts src/lib/verificationFetch.test.ts` → all PASS.
- [ ] `cd backend && npx tsc --noEmit` → clean.
- [ ] `cd backend && npx vitest run` → full suite green (no regression).

## Self-review notes (spec coverage)

- STEP 1 (parse URL → API call): Task 2 (parser incl. congress slug, member trailing bioguideId, bill-type map) + Task 3 (bill/member → JSON → page text, best-effort /text). ✅
- STEP 2 (wire behind env key, no-op when unset, rate limit): Task 4 (env + wiring) + Task 1 (limiter). ✅
- ACCEPTANCE (unit test stubbed client; tsc + existing tests; re-measure): Task 3 tests + Task 4 final verification + Task 5 script. ✅
- Type consistency: `CongressRef`, `CongressDeps`, `FetchLike`, `fetchCongressPageText`, `parseCongressUrl`, `acquireApiDataGovSlot`, `VerificationFetchDeps.congressAdapter` used identically across Tasks 1–5. ✅
