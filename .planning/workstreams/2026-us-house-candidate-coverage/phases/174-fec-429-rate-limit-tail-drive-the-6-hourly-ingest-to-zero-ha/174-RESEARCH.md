# Phase 174: FEC 429 Rate-Limit Tail — Research

**Researched:** 2026-07-23
**Domain:** Node/TypeScript HTTP client hardening — rate-limit-aware retry + shared distributed rate limiting against a fixed-ceiling third-party API (FEC/api.data.gov), backed by the existing Upstash Redis HTTP client.
**Confidence:** HIGH (grounded directly in the target repo's code + official api.data.gov/FEC developer docs fetched live)

## Summary

The per-request exponential backoff shipped in `d505c9ad` (verified: daily FEC failures 3,410→101) fixed the *reactive* problem (a single request retries after a 429) but not the *pacing* problem (the batch as a whole has no notion of the shared ceiling). Three composable, low-risk fixes close the residual ~15/12h tail: (a) cache `resolveCommitteeIds` results (committee IDs are near-static) to cut request volume roughly in half; (b) make the two retry loops read the *real* rate-limit signal FEC actually sends — which, per the official api.data.gov developer manual (fetched live), is `X-RateLimit-Limit` / `X-RateLimit-Remaining` on every response, **not** `Retry-After` or `X-RateLimit-Reset` (neither header is documented anywhere in api.data.gov's or FEC's own docs) — so FEC-02 should be read as "parse `Retry-After` defensively if present, and proactively throttle from `X-RateLimit-Remaining`," not "wait for a reset timestamp that doesn't exist"; (c) add one shared Redis-backed limiter that every outbound FEC HTTP request acquires from, budgeted safely under the 1,000/hr key ceiling.

A critical scope-correction: the phase description says there are "two FEC request sites," but the codebase actually has **three** — `fecAdapter.ts`'s `resolveCommitteeIds` and `fetchWithRetry` (the two named), plus `fecResearch.ts`'s `runFecAutoMatch` (admin-triggered candidate auto-match, hits `https://api.open.fec.gov/v1/candidates/` directly with its own bare `fetch()`, no backoff, no lock, no limiter). This route is not on the 6h cron, but it shares the same `FEC_API_KEY` and can run concurrently with the cron (unlike the batch entry points, it never acquires `FEC_LOCK_KEY`). FEC-03's "every outbound FEC HTTP request acquires from a single shared rate limiter" is only true if the limiter is called from a location all three sites reach — recommend a standalone `fecRateLimiter.ts` module imported by both files, not something folded into `campaignFinanceScheduler.ts` (which never sees the admin auto-match calls).

FEC requests inside the cron are confirmed **sequential**, not concurrent (`runAdapterForAll('fec')` loops with `await` + a 3s inter-source sleep; no `Promise.all`) — so the limiter does not need to arbitrate bursty concurrent callers within one cron run, only pace across the whole run and coordinate with the other two call sites. Zero new database schema or migrations are needed; the codebase's existing `cache.ts` (Redis via `@upstash/redis` + in-memory fallback) is the correct reuse target for the committee-ID cache, and a small hand-rolled Redis fixed-window counter (mirroring the existing `acquireLock`/`renewLock` pattern in `campaignFinanceScheduler.ts`) is the correct reuse target for the rate limiter — no new npm dependency is required for either.

**Primary recommendation:** Cache committee IDs in the existing `cache` singleton (`backend/src/lib/cache.ts`) with a 30-day TTL; add proactive `X-RateLimit-Remaining` reading (with defensive `Retry-After` parsing as a bonus, since it costs nothing to check) to both `resolveCommitteeIds` and `fetchWithRetry`; add one new `backend/src/lib/fecRateLimiter.ts` module exposing an `acquireFecSlot()` function built on a Redis fixed-window (per-minute) counter with in-process fallback, budgeted at ~900/hr (≈15/min), called from all three FEC HTTP call sites (`fecAdapter.ts` ×2, `fecResearch.ts` ×1) before every outbound fetch.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FEC-01 | Cache `resolveCommitteeIds` results (durable store, bounded TTL) so a warm run issues roughly half the FEC requests, with a correctness path for cache miss/expiry | Pattern 1 (reuse `cache.ts`, 30-day TTL, `fec:committee-ids:<candidateId>` key); Pitfall 3 (never cache empty results) |
| FEC-02 | Both FEC request paths honor server `Retry-After`/`X-RateLimit-Reset` on 429, backing off by the server-provided interval instead of blind exponential | Pattern 2 + Pitfall 1 — corrects the premise: only `X-RateLimit-Limit`/`X-RateLimit-Remaining` are documented (fetched live from api.data.gov's developer manual); `Retry-After` should be parsed defensively, `X-RateLimit-Remaining` should drive proactive throttling; no `X-RateLimit-Reset` exists to honor |
| FEC-03 | Every outbound FEC HTTP request acquires from a single shared rate limiter (Redis token-bucket, degrading to in-process), budgeted under the ~1,000/hr ceiling | Pattern 3 (`fecRateLimiter.ts`, per-minute fixed-window, ~900/hr budget); Summary + Architecture Diagram (identifies the THIRD call site in `fecResearch.ts` that must also acquire the same limiter for this requirement to be true) |
| FEC-04 | Post-deploy, a full 6h `fec-ingest` cycle completes with zero `status='failed'` 429 rows; budget/cadence + FEC-key-upgrade decisions documented | Validation Architecture (exact verification SQL, grounded in `runIngestion.ts`'s error-write path); Open Question 2 (upgrade-request lever, cadence decision framing) |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Committee-ID cache (read/write) | API/Backend (Node process) | Database/Storage (Redis via Upstash HTTP) | Pure backend cross-cutting concern; storage is Redis, not Postgres — matches existing `cache.ts` pattern, no schema change |
| Retry-After / X-RateLimit-Remaining parsing | API/Backend | — | Lives entirely inside the two existing HTTP client functions in `fecAdapter.ts` |
| Shared rate limiter (token/window accounting) | API/Backend | Database/Storage (Redis) | Cross-process coordination requires a shared store; Redis is already the org's cross-instance coordination primitive (see `FEC_LOCK_KEY`) |
| Cron pacing / cadence decision | API/Backend (cron registration) | — | `node-cron` registration in `campaignFinanceCron.ts`; no client/browser tier involved anywhere in this phase |
| Verification query (zero-429 outcome) | Database/Storage | API/Backend | Read-only query against `transparent_motivations.ingestion_runs`; no new surfacing/UI |

This phase touches **only** the API/Backend and Database/Storage tiers (a cron worker inside the single Render backend dyno + Postgres/Redis). There is no browser, SSR, or CDN tier involvement — confirming the "pure-backend, no schema, no data" framing in the phase description is architecturally accurate.

## Package Legitimacy Audit

**No new package is required for the prescribed (Core) approach** — `@upstash/redis` (already a direct dependency, `^1.34.0` declared / `1.36.2` installed / `1.38.0` latest on npm) exposes `.incr()`, `.expire()`, `.get()`, `.set()`, `.eval()` on the installed client, which is sufficient to hand-roll both the committee-ID cache (already wrapped by `cache.ts`) and the rate limiter (fixed-window counter), matching the codebase's existing style of hand-rolling Redis primitives directly (see `acquireLock`/`renewLock` in `campaignFinanceScheduler.ts`, which use raw `redis.set(key, '1', { nx: true, ex: ttl })` rather than any vendor lock library).

One alternative package was evaluated in case the planner prefers an off-the-shelf sliding-window limiter instead of hand-rolling:

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `@upstash/ratelimit` | npm | 2.0.8 published 2026-01-12 (long-lived package, 748 published versions total) | 1,838,380/week `[VERIFIED: npm registry]` | github.com/upstash/ratelimit (maintainers' npm profiles are `@upstash.com` addresses — same vendor as the already-trusted `@upstash/redis`) `[ASSUMED — repo URL not returned by the automated legitimacy check, confirmed manually via `npm view` maintainer list, not an official-docs source]` | **SUS** (automated gate signal: `no-repository` — a likely false positive given the maintainer/download evidence, but the protocol requires respecting the verdict) | **NOT included in the Core recommendation.** Listed only as an "Alternatives Considered" option. If the planner chooses it anyway, a `checkpoint:human-verify` task MUST precede its install per the SUS disposition rule. |

**Packages removed due to [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** `@upstash/ratelimit` (optional alternative only, not required by the Core recommendation — see disposition above).

*The package name `@upstash/ratelimit` was surfaced from training knowledge, not from an official-docs lookup — tagged `[ASSUMED]` per the provenance rule regardless of its confirmed registry existence and download count.*

## Standard Stack

### Core (no new dependencies)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@upstash/redis` | `^1.34.0` declared, `1.36.2` installed `[VERIFIED: npm registry / already a project dependency]` | Committee-ID cache backing store (via `cache.ts`) + rate-limiter counter store | Already the project's sole Redis client (HTTP-based, matches Render's serverless-friendly deployment — no persistent TCP connection pool to manage); reusing it needs zero new infra or credentials |
| `backend/src/lib/cache.ts` (existing module) | n/a (in-repo) | Generic `get`/`set`/`del` cache with automatic Redis→in-memory degrade | This is the established project pattern for exactly this kind of "cache an external API's answer with a TTL" problem (see `geocodingService.ts`, `candidateService.ts`, `roleService.ts` all reusing it) `[VERIFIED: codebase grep]` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `node-cron` | `^4.2.1` (existing dep) | Unchanged — still drives the 6-hourly `fec-ingest` job | No change needed for FEC-01..03; only touched if FEC-04's cadence decision changes `campaignFinanceCron.ts:27` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hand-rolled Redis fixed-window counter (`INCR`+`EXPIRE`) | `@upstash/ratelimit`'s `Ratelimit.slidingWindow()` | Sliding-window is smoother than fixed-window (avoids the "burst at window boundary" edge case) and is battle-tested, but adds a new dependency flagged `[SUS]` by the package-legitimacy gate (see audit above) and does not ship a built-in in-process degrade path — you'd still hand-write the Redis-absent fallback yourself, which is most of the value of hand-rolling in the first place. Not recommended as the Core choice; acceptable as an operator-approved substitution. |
| Redis-backed committee-ID cache (`cache.ts`) | A new `transparent_motivations.fec_committee_cache` DB table (mirrors the existing `fec_ingest_window_progress` table pattern in `fecAdapter.ts`) | A DB table survives an Upstash outage/eviction and is trivially queryable for ops debugging, at the cost of a new migration (this phase is scoped "no schema, no data" per the phase description — Redis avoids that entirely). If the team later observes committee-ID cache misses correlating with an Upstash incident, promoting to a DB table is a reasonable follow-up, not a Phase-174 requirement. |

**Installation:** None — no `npm install` needed for the Core recommendation.

**Version verification:** `@upstash/redis@1.36.2` is installed (`package.json` declares `^1.34.0`); latest on npm is `1.38.0` `[VERIFIED: npm view @upstash/redis version, run 2026-07-23]`. No upgrade is required for this phase — `.incr()`/`.expire()`/`.eval()` are present on the installed version (confirmed via the shipped `.d.ts` type exports).

## Architecture Patterns

### System Architecture Diagram

```
node-cron "0 */6 * * *"  (campaignFinanceCron.ts)
        │
        ▼
runFecScheduledJob()  ──► acquireLock(FEC_LOCK_KEY) ──► [locked?] ──no──► skip, return
        │ yes
        ▼
runAdapterForAll('fec')  — loops SEQUENTIALLY over ~1k confirmed politician_sources
        │  (await + 3s inter-source sleep; no Promise.all)
        ▼
  for each source ──► createFecAdapter(cycle).fetchStream(ps, onBatch)
        │
        ▼
  streamAllPages(candidateId, cycle, onBatch, psId)
        │
        ├──► resolveCommitteeIds(candidateId, apiKey)      [FEC call site #1]
        │        │
        │        ├─(NEW)─► committee-ID cache lookup (cache.ts, key `fec:committee-ids:${candidateId}`)
        │        │            │
        │        │            ├─ HIT  ──► return cached committee IDs, NO FEC request
        │        │            └─ MISS ──► (NEW) acquireFecSlot() ──► fetch (candidates/search)
        │        │                              │                        │
        │        │                              │                   429? read X-RateLimit-Remaining/
        │        │                              │                   Retry-After, back off, retry
        │        │                              └──────────────────► cache.set(TTL 30d) on success
        │        ▼
        └──► streamAllPagesForCommittee(committeeId, ...)
                 │
                 ▼
         streamPagesForWindow(...)  — one call per Schedule A page
                 │
                 ▼
         fetchWithRetry(url)      [FEC call site #2]
                 │
                 ├─(NEW)─► acquireFecSlot()  — blocks/sleeps until a slot is free
                 ▼
              fetch(url)
                 │
            429? read X-RateLimit-Remaining/Retry-After, back off, retry (existing loop, backoff source corrected)
                 ▼
         onBatch(page.results) ──► normalize ──► upsert (existing, unchanged)

────────────────────────────────────────────────────────────────────────────
SEPARATE, UNLOCKED call sites — must ALSO acquire the same shared limiter:

POST /admin/ingest/fec  (campaignFinanceAdmin.ts) ──► createFecAdapter(cycle) ──► same
  two call sites above — NO FEC_LOCK_KEY acquired here today; can run concurrently
  with the 6h cron.

POST /admin/backfill/fec ──► runFecBackfill() ──► acquireLock(FEC_LOCK_KEY) (WITH heartbeat/
  renewLock) ──► same two call sites — DOES coordinate with the cron via the lock.

runFecAutoMatch() (fecResearch.ts, admin-triggered, NOT cron-scheduled)  [FEC call site #3]
  ──► bare fetch(`${FEC_CANDIDATES_URL}?...`) — NO backoff, NO lock, NO limiter today.
  (NEW) must also call acquireFecSlot() before its fetch for FEC-03's "every outbound
  FEC HTTP request" claim to be true.
────────────────────────────────────────────────────────────────────────────

Shared rate limiter store: Redis key `fec:ratelimit:<UTC-minute-bucket>`
  (or hourly, see Pitfall below) — INCR + conditional EXPIRE, budget ~15/min (~900/hr),
  degrading to an in-process Map counter (single-instance only) when
  UPSTASH_REDIS_REST_URL/TOKEN are absent — mirrors cache.ts's InMemoryFallback
  and campaignFinanceScheduler.ts's inProcessLocks Map exactly.
```

### Recommended Project Structure
```
backend/src/lib/
├── adapters/fecAdapter.ts       # MODIFIED: resolveCommitteeIds + fetchWithRetry gain
│                                 #   cache lookup + limiter acquire + header-aware backoff
├── fecResearch.ts                # MODIFIED: candidate-search fetch() gains limiter acquire
├── cache.ts                      # UNCHANGED — reused as-is for the committee-ID cache
├── fecRateLimiter.ts              # NEW — acquireFecSlot(), shared Redis fixed-window
│                                 #   counter + in-process fallback (mirrors campaignFinance
│                                 #   Scheduler.ts's getRedisClient()/inProcessLocks pattern)
└── campaignFinanceScheduler.ts   # UNCHANGED (sequential loop already confirmed; the
                                  #   existing 3s inter-source sleep and 5s per-page sleep
                                  #   can stay as defense-in-depth margin alongside the limiter)
```

### Pattern 1: Reuse `cache.ts` for committee-ID caching (FEC-01)
**What:** Wrap `resolveCommitteeIds` with a Redis-cached lookup before making the FEC HTTP call.
**When to use:** Any external-API lookup whose result changes rarely (committee IDs almost never change once a candidate has a filed committee) and where a stale cache is harmless for up to the TTL window.
**Example:**
```typescript
// Source: pattern generalized from geocodingService.ts's existing cache.ts usage
// (backend/src/lib/geocodingService.ts:84 + :142), applied to fecAdapter.ts.
import { cache } from '../cache.js';

const COMMITTEE_CACHE_TTL_SECONDS = 60 * 60 * 24 * 30; // 30 days — committee IDs rarely change

async function resolveCommitteeIds(candidateId: string, apiKey: string, maxRetries = 5): Promise<string[]> {
  const cacheKey = `fec:committee-ids:${candidateId}`;
  const cached = await cache.get<string[]>(cacheKey);
  if (cached !== null) {
    return cached; // cache hit — zero FEC requests for this candidate this run
  }

  // ... existing fetch + backoff logic, unchanged, ending in:
  const committees = data.results.flatMap((c) => c.principal_committees.map((p) => p.committee_id));
  if (committees.length > 0) {
    // Only cache non-empty results — a genuinely new/unmatched candidate should be
    // re-checked on the NEXT run rather than cached as "no committee" for 30 days.
    await cache.set(cacheKey, committees, COMMITTEE_CACHE_TTL_SECONDS);
  }
  return committees;
}
```
**Correctness path for cache miss/expiry:** A miss (first run for a candidate, or TTL expiry) falls through to the existing live FEC lookup unchanged, then populates the cache on success. An empty result is deliberately NOT cached (see comment above) — this is the one design decision the planner must make explicit as a task: caching a `[]` (no committees found) result for 30 days would silently suppress finance ingestion for any newly-filing candidate until the cache naturally expires.

### Pattern 2: Read the *real* server signal, not the assumed one (FEC-02)
**What:** On every response (200 or 429), read `X-RateLimit-Remaining` (and `X-RateLimit-Limit`) — these ARE documented and present. Additionally parse `Retry-After` defensively on 429 even though it is not documented for api.data.gov/FEC, since checking costs nothing and some API-Umbrella deployments do add it.
**When to use:** Both `resolveCommitteeIds` and `fetchWithRetry`'s 429 branches, and ideally after every successful response too (proactive throttling beats reactive backoff).
**Example:**
```typescript
// Source: header names verified via api.data.gov's official developer manual
// (https://api.data.gov/docs/developer-manual/, fetched live 2026-07-23) and
// corroborated by the NREL/api-umbrella project docs (the open-source middleware
// api.data.gov and FEC's own API Umbrella deployment are both built on) —
// see Sources section for citations.
function parseRetryAfterMs(response: Response): number | null {
  const retryAfter = response.headers.get('retry-after'); // not documented for FEC, but free to check
  if (!retryAfter) return null;
  const asSeconds = Number(retryAfter);
  if (!Number.isNaN(asSeconds)) return asSeconds * 1000;
  const asDate = Date.parse(retryAfter);
  return Number.isNaN(asDate) ? null : Math.max(0, asDate - Date.now());
}

function readRemaining(response: Response): number | null {
  const remaining = response.headers.get('x-ratelimit-remaining'); // documented, always present
  return remaining !== null ? Number(remaining) : null;
}

// In the 429 branch:
if (response.status === 429) {
  const serverDelay = parseRetryAfterMs(response);
  const delay = serverDelay ?? delayMs; // fall back to existing exponential value if absent
  await sleep(delay);
  delayMs = Math.min(delayMs * 2, 120_000);
  continue;
}
```
**Important correction to the phase description:** `X-RateLimit-Reset` is NOT documented anywhere in api.data.gov's developer manual or the FEC-specific docs found this session — only `X-RateLimit-Limit` and `X-RateLimit-Remaining` are confirmed. The rate-limit "reset" behavior is a **rolling hourly window** that "automatically lifts by waiting an hour," not a fixed reset timestamp — so there is no reset-time header to honor even in principle. FEC-02 should be implemented as: (1) defensive `Retry-After` parse (cheap, harmless if absent), (2) `X-RateLimit-Remaining` read on every response as an input to the shared limiter (Pattern 3) so throttling happens *before* a 429, not just after.

### Pattern 3: Shared Redis fixed-window rate limiter, mirroring the existing lock pattern (FEC-03)
**What:** One small module, `fecRateLimiter.ts`, exposing `acquireFecSlot(): Promise<void>` that blocks (sleeps and re-checks) until a slot is available under the per-minute budget, backed by Redis `INCR`+`EXPIRE`, with an in-process `Map`-based fallback when Redis env vars are absent.
**When to use:** Called immediately before every outbound `fetch()` to `api.open.fec.gov` — in `fecAdapter.ts`'s two functions AND `fecResearch.ts`'s candidate-search function.
**Example:**
```typescript
// Source: pattern directly mirrors the existing acquireLock()/renewLock() design in
// backend/src/lib/campaignFinanceScheduler.ts:67-171 (lazy Redis client init,
// in-process Map fallback, non-fatal degrade-on-error) — same house style, new key space.
import { Redis } from '@upstash/redis';

let redisClient: Redis | null = null;
let redisInitAttempted = false;
function getRedisClient(): Redis | null {
  if (redisInitAttempted) return redisClient;
  redisInitAttempted = true;
  if (!process.env.UPSTASH_REDIS_REST_URL || !process.env.UPSTASH_REDIS_REST_TOKEN) return null;
  try { redisClient = Redis.fromEnv(); return redisClient; } catch { return null; }
}

// Per-MINUTE bucket (not per-hour) — see Common Pitfalls for why granularity matters.
const BUDGET_PER_MINUTE = parseInt(process.env.FEC_RATE_LIMIT_PER_MINUTE ?? '15', 10); // ~900/hr, 10% margin
const inProcessCounters = new Map<string, number>();

export async function acquireFecSlot(): Promise<void> {
  for (;;) {
    const bucket = new Date().toISOString().slice(0, 16); // YYYY-MM-DDTHH:MM
    const key = `fec:ratelimit:${bucket}`;
    const redis = getRedisClient();
    let count: number;
    if (redis) {
      try {
        count = await redis.incr(key);
        if (count === 1) await redis.expire(key, 90); // TTL slightly > bucket width
      } catch {
        count = inProcessIncr(key); // degrade on transient Redis error, not just absence
      }
    } else {
      count = inProcessIncr(key);
    }
    if (count <= BUDGET_PER_MINUTE) return; // slot acquired
    await sleep(2000); // short poll-back, re-check next tick (never a >60s stall)
  }
}

function inProcessIncr(key: string): number {
  const n = (inProcessCounters.get(key) ?? 0) + 1;
  inProcessCounters.set(key, n);
  setTimeout(() => inProcessCounters.delete(key), 90_000);
  return n;
}
```
**Degrade path:** Identical philosophy to `cache.ts`'s `InMemoryFallback` and `campaignFinanceScheduler.ts`'s `inProcessLocks` — Redis absent or erroring degrades to single-instance-only in-process counting rather than failing the ingest. Since Render currently runs campaign-finance ingestion on a single dyno (per the cron audit), the in-process fallback is not a meaningfully weaker guarantee today — it becomes weaker only if/when the AWS Lambda/SQS path (cron-audit item 2, separately tracked) goes live with multiple concurrent workers.

### Anti-Patterns to Avoid
- **Hourly-bucket-only limiter:** A single `INCR`-per-hour counter with budget 900 lets the first ~900 requests fire in the first few minutes of the hour, then stalls everything for the remainder — a "burst then stall" pattern that is worse UX for a long-running cron than smooth pacing, and risks the per-page/per-committee `AbortSignal.timeout(60_000)` firing while requests queue. Use a smaller bucket (per-minute, shown above) so pacing is smooth across the whole run.
- **Rate-limiting only the two named `fecAdapter.ts` sites:** As documented above, `fecResearch.ts`'s admin-triggered auto-match hits the same key with zero coordination today. If it fires during a 6h cron run, its unthrottled requests count against the same 1,000/hr ceiling and can reintroduce the residual tail even after FEC-01/02/03 ship for the two named sites. The limiter must be a shared module both files import.
- **Caching an empty committee-ID result:** As noted in Pattern 1, caching `[]` for 30 days would silently stop finance data collection for any candidate whose FEC filing lands between runs.
- **Relying on `X-RateLimit-Reset`:** This header is not documented for api.data.gov or FEC — code that waits for it will simply never see it and must have a correct fallback (existing fixed exponential backoff), not an infinite wait.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Redis client abstraction (get/set/expire over HTTP) | A custom fetch-based Upstash REST wrapper | `@upstash/redis` (already installed) | Already vetted, already the sole Redis client in this codebase; a hand-rolled HTTP wrapper would duplicate auth/retry/serialization logic for no benefit |
| TTL-based cache with degrade-on-Redis-absence | A bespoke cache class in `fecAdapter.ts` | The existing `cache.ts` singleton | This exact problem (cache external-API result, degrade gracefully) is already solved once in this codebase and reused six times (`authService`, `candidateService`, `empowerService`, `essentialsBrowseService`, `geocodingService`, `roleService`); a seventh bespoke cache implementation would be pure duplication |

**Key insight:** Nothing in this phase requires new infrastructure or a new distributed-systems primitive — every piece (TTL cache, distributed counter with in-process fallback) already has a proven, in-repo precedent using the same Redis client. The work is composing those two proven patterns into two new small surfaces (a cache key + a limiter module), not inventing anything.

## Common Pitfalls

### Pitfall 1: Assuming `Retry-After`/`X-RateLimit-Reset` exist because the phase description names them
**What goes wrong:** Code written to "honor `Retry-After`/`X-RateLimit-Reset`" as the primary signal will find both usually absent (only `X-RateLimit-Limit`/`X-RateLimit-Remaining` are documented) and silently fall through to whatever "no header" branch was written — if that branch isn't the existing correct exponential backoff, retries could misbehave (e.g., wait 0ms, or throw).
**Why it happens:** Those are the two most common rate-limit headers across the industry generally, but api.data.gov (and by extension every FEC endpoint proxied through it) documents only the `X-RateLimit-Limit`/`X-RateLimit-Remaining` pair.
**How to avoid:** Implement `Retry-After` parsing as a defensive bonus (cheap, harmless if absent) but make `X-RateLimit-Remaining` — read on *every* response, not just 429s — the actual proactive throttling signal, feeding the shared limiter. Keep the existing fixed exponential backoff as the true fallback for the 429 case with no `Retry-After`.
**Warning signs:** Code review that finds `response.headers.get('x-ratelimit-reset')` anywhere — that header does not exist for this API.

### Pitfall 2: Rate-limiting only inside `fecAdapter.ts` and missing `fecResearch.ts`
**What goes wrong:** FEC-04's "zero 429 rows" verification could still occasionally show a failure attributable to a manually-triggered `/admin/ingest/fec/auto-match`-style run colliding with the cron, since that code path shares the FEC key but neither the lock nor (pre-fix) the limiter.
**Why it happens:** The phase description's grounding section names only two call sites; the third was found by grepping the codebase, not by re-reading the phase brief.
**How to avoid:** Grep `api.open.fec.gov` and `FEC_API_KEY` across `backend/src` before finalizing the task list, confirm the limiter is imported everywhere a raw `fetch()` targets that host.
**Warning signs:** `grep -rn "api.open.fec.gov" backend/src` returning more than the two files the plan touches.

### Pitfall 3: Caching a negative committee-ID lookup
**What goes wrong:** A brand-new candidate with no filed committee yet gets `[]` cached for 30 days; once they DO file, their finance data silently doesn't ingest until the cache naturally expires — with no error, no log noise, nothing to alert on.
**Why it happens:** The natural, simplest cache-everything implementation doesn't distinguish "confirmed no committee" from "not yet checked."
**How to avoid:** Only cache non-empty results (shown in Pattern 1); let empty results re-check every run (a `resolveCommitteeIds` call for a candidate with zero committees is already cheap — it fails fast at the FEC API, no Schedule A pagination follows it).
**Warning signs:** `finance_summary`/contribution counts staying at zero for a specific newly-seeded candidate for multiple weeks despite a confirmed FEC filing existing.

### Pitfall 4: Hourly-granularity limiter causing a thundering-herd-then-stall pattern
**What goes wrong:** Documented in Anti-Patterns above — worth restating as a pitfall because it is the most likely mistake for someone implementing FEC-03 literally from "budget under 1,000/hr" without considering bucket granularity.
**How to avoid:** Use per-minute (or smaller) buckets.

## Code Examples

Verified patterns from the actual target files (not hypothetical):

### Existing per-request backoff (unchanged skeleton, header-reading added — `fecAdapter.ts:475`)
```typescript
// Source: backend/src/lib/adapters/fecAdapter.ts (read this session, lines 475-524)
async function fetchWithRetry(url: string, maxRetries = 5): Promise<FecScheduleAResponse> {
  let delayMs = 2000;
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    await acquireFecSlot(); // NEW — shared limiter gate, before every attempt including retries
    let response: Response;
    try {
      response = await fetch(url, { signal: AbortSignal.timeout(60_000) });
    } catch (err) {
      // ... existing abort/timeout-as-throttle handling, unchanged
    }
    if (response.status === 429) {
      const serverDelay = parseRetryAfterMs(response); // NEW
      if (attempt === maxRetries) throw new Error(`FEC API rate limited (429) after ${maxRetries} retries`);
      await sleep(serverDelay ?? delayMs);
      delayMs = Math.min(delayMs * 2, 120_000);
      continue;
    }
    // ... existing 504/502/503 too-large handling, unchanged
    const data = await response.json() as FecScheduleAResponse;
    return data;
  }
  throw new Error('FEC API fetchWithRetry: unexpected loop exit');
}
```

### Existing test-mocking convention this phase's tests must follow
```typescript
// Source: backend/src/lib/discoveryCron.test.ts (read this session, lines 1-53) —
// the direct sibling precedent from Phase 173 (the immediate predecessor phase).
import { vi, describe, it, expect, beforeEach } from 'vitest';

vi.mock('./env.js', () => ({ env: { FEC_API_KEY: 'test-fec-key' } }));
vi.mock('./db.js', () => ({ pool: { query: vi.fn() } })); // avoids env.ts's startup process.exit(1)

const redisIncrMock = vi.hoisted(() => vi.fn());
const redisExpireMock = vi.hoisted(() => vi.fn());
vi.mock('@upstash/redis', () => ({
  Redis: { fromEnv: () => ({ incr: redisIncrMock, expire: redisExpireMock, get: vi.fn(), set: vi.fn() }) },
}));

beforeEach(() => {
  redisIncrMock.mockReset();
  redisExpireMock.mockReset();
  vi.stubGlobal('fetch', vi.fn()); // no established fetch-mock convention exists in this repo yet —
  // vi.stubGlobal is the standard vitest idiom and should be introduced here.
});
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Bare `fetch()`, throw on first 429 | Per-request exponential backoff (2s→120s, 5 retries) + 60s abort-as-throttle | `d505c9ad`, deployed 2026-07-23 | Daily FEC failures 3,410→101; residual ~15/12h tail is what THIS phase addresses |
| No committee-ID cache | (this phase) Redis-cached committee IDs, 30-day TTL | Phase 174 (proposed) | ~halves FEC request volume per 6h run |
| No shared pacing across sources | (this phase) Redis fixed-window limiter, ~900/hr budget | Phase 174 (proposed) | Aggregate request rate provably stays under the 1,000/hr ceiling regardless of source count |

**Deprecated/outdated:** The phase description's assumption that FEC/api.data.gov signals reset time via `X-RateLimit-Reset` — not documented; see Pitfall 1.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `@upstash/ratelimit` is a legitimate, actively-maintained Upstash package (despite the automated legitimacy gate's `SUS`/`no-repository` signal) | Package Legitimacy Audit | Low — it is explicitly NOT part of the Core recommendation; only relevant if the planner/operator chooses it over the hand-rolled limiter, in which case a `checkpoint:human-verify` task is already mandated |
| A2 | api.data.gov's rolling-hourly-window behavior ("block lifted by waiting an hour") applies identically to FEC's specific deployment of API Umbrella, not just the generic api.data.gov docs | Server-Signaled Backoff / Pitfall 1 | Medium — if FEC's deployment differs (e.g., a fixed reset time instead of rolling), the "wait an hour" assumption in any fallback logic could be wrong; the existing fixed-exponential-backoff fallback (max 120s per retry, 5 retries ≈ under 4 min total) is unaffected either way since it never assumes a specific reset time |
| A3 | FEC requests inside `runAdapterForAll('fec')` are correctly characterized as strictly sequential with no concurrency, based on reading the current loop body (no `Promise.all`) | System Architecture Diagram, Summary | Low — directly read from source this session; would only be wrong if a future refactor (unrelated to this phase) introduces concurrency without updating this research |

**If confirmation is needed before locking design:** A2 is the one item worth a quick operator gut-check during discuss-phase or plan-check — it does not block implementation since the fallback path is unaffected, but it affects how confidently FEC-04's "documented lever" writeup can describe FEC's exact reset semantics.

## Open Questions (RESOLVED — deferred to 174-04 decision doc)

> Both items below are operator-facing decisions, not unresolved research blockers. Plan 174-04 Task 2 evaluates and records them in `174-FEC04-DECISION.md` (per FEC-04's "evaluated and documented" clause). Not blocking execution.

1. **Should the rate-limit budget be configurable via env var, and what's the right default?**
   - What we know: FEC ceiling is 1,000/hr per key (confirmed: DEMO_KEY=40/hr, registered key=1,000/hr, upgraded key=7,200/hr via `APIinfo@fec.gov` request) `[CITED: api.data.gov developer manual + multiple corroborating FEC API guides]`.
   - What's unclear: Whether other processes besides the three identified call sites (e.g., any local dev/backfill scripts run by operators outside the deployed app) also consume the same key concurrently, which would eat into the safety margin.
   - Recommendation: Default budget ~900/hr (10% margin) via an env var (e.g. `FEC_RATE_LIMIT_PER_MINUTE`, default `15`), so the operator can tune it after observing real `X-RateLimit-Remaining` values in production logs without a code change.

2. **Cadence decision (6h vs daily) and FEC-key-upgrade request — operator decisions, not code**
   - What we know: FEC-04 explicitly requires these be "evaluated and documented," not necessarily changed. Upgrading the key is a one-line email to `APIinfo@fec.gov` requesting 7,200/hr (120/min) `[CITED: multiple FEC API integration guides corroborating the same figure]` — cheap, no code risk, and independently makes the entire pacing problem far less tight (7,200/hr ceiling vs current ~1k-source run) regardless of what the code-side fixes achieve.
   - What's unclear: Whether the FEC team's upgrade process has a turnaround time or approval bar that makes it impractical to depend on for closing FEC-04 promptly.
   - Recommendation: File the upgrade request in parallel with shipping the code fixes (a1-c above) — it's a documented lever, not a blocker; FEC-04 can close on the code fixes alone (zero 429s) with the upgrade request noted as "requested, pending" if the email hasn't been answered by verification time.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `@upstash/redis` (npm package, already installed) | Committee-ID cache + rate limiter | ✓ | 1.36.2 installed (`^1.34.0` declared, `1.38.0` latest) `[VERIFIED: npm view]` | n/a — already present |
| Upstash Redis instance (`UPSTASH_REDIS_REST_URL`/`TOKEN` env vars) | Cross-instance limiter coordination + durable committee-ID cache | Unknown in this research session (env vars not inspected — sandboxed `.env` read was denied) | — | Both `cache.ts` and the proposed `fecRateLimiter.ts` already degrade to in-process fallback if absent — no blocker either way |
| `FEC_API_KEY` env var | All FEC HTTP requests | Unknown in this research session (same reason) | — | None — `env.ts` marks it optional; if absent, `resolveCommitteeIds`/`fetchWithRetry` already warn and proceed with an empty key string (pre-existing behavior, unchanged by this phase) |

**Missing dependencies with no fallback:** None identified — every dependency this phase touches already has a graceful-degrade path in the existing codebase.
**Missing dependencies with fallback:** Upstash Redis presence/absence (see above) — does not block this phase's implementation or its tests (which mock Redis entirely).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Vitest 2.1 (`vitest.config.ts`, `environment: 'node'`, `pool: 'forks'`) `[VERIFIED: backend/vitest.config.ts + backend/package.json]` |
| Config file | `backend/vitest.config.ts` |
| Quick run command | `npm run test:unit -- src/lib/adapters/fecAdapter.test.ts src/lib/fecRateLimiter.test.ts src/lib/fecResearch.test.ts` (run from `backend/`) |
| Full suite command | `npm run test:unit` (= `vitest run src`, from `backend/`) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FEC-01 | Committee-ID cache hit skips the FEC HTTP call entirely; cache miss falls through and populates the cache; empty result is NOT cached | unit | `npx vitest run src/lib/adapters/fecAdapter.test.ts -t "committee"` | ❌ Wave 0 — new file |
| FEC-02 | `Retry-After` parsed correctly (seconds and HTTP-date forms); absent-header falls back to existing exponential delay; `X-RateLimit-Remaining` read and exposed | unit | `npx vitest run src/lib/adapters/fecAdapter.test.ts -t "retry-after\|rate-limit-remaining"` | ❌ Wave 0 — new file |
| FEC-03 | `acquireFecSlot()` blocks once the per-minute budget is exceeded and releases on the next bucket; degrades to in-process counting when Redis mock throws/absent; called from all three FEC HTTP call sites | unit | `npx vitest run src/lib/fecRateLimiter.test.ts` + `npx vitest run src/lib/fecResearch.test.ts -t "rate limit"` | ❌ Wave 0 — both new/modified |
| FEC-04 | Zero `status='failed'` FEC rows with 429/rate-limit text in `notes` over a full post-deploy 6h window | manual-only (read-only prod query, run by operator after deploy, per the existing cron-audit item-0 verification precedent) | `SELECT COUNT(*) FROM transparent_motivations.ingestion_runs WHERE adapter_name='fec' AND status='failed' AND started_at >= <deploy_time> AND (notes ILIKE '%429%' OR notes ILIKE '%rate limit%');` (run via Supabase MCP `execute_sql` against prod, matching cron-audit item-0's own verification method) | N/A — verification query, not a test file |

Query justification: `runIngestion.ts` (read this session, lines 181-198) writes the caught error's `.message` verbatim into `ingestion_runs.notes` on any failure; the two FEC throw sites format their exhausted-retry errors as `` `FEC candidate lookup rate limited (429) after ${maxRetries} retries for ${candidateId}` `` and `` `FEC API rate limited (429) after ${maxRetries} retries` `` — both are caught by the `ILIKE '%429%'` / `%rate limit%` pattern.

### Sampling Rate
- **Per task commit:** `npx vitest run <the one file just touched>` (fast, <5s per the existing suite's typical per-file runtime)
- **Per wave merge:** `npm run test:unit` (full backend suite; note the STATE.md-documented caveat that 21 pre-existing unrelated failures exist in the sandbox due to no live DB/env vars — these are NOT this phase's responsibility, do not attempt to fix them)
- **Phase gate:** Full suite green (modulo the 21 known pre-existing failures) before `/gsd-verify-work`; FEC-04's manual read-only query run separately, ≥ 6 hours after the deploy that ships FEC-01..03

### Wave 0 Gaps
- [ ] `backend/src/lib/fecRateLimiter.test.ts` — new file, covers FEC-03's core counter logic (mock `@upstash/redis`, no live Redis)
- [ ] `backend/src/lib/adapters/fecAdapter.test.ts` — new file (none exists today), covers FEC-01 (cache hit/miss/empty-result) and FEC-02 (header parsing) using `vi.mock('../db.js', ...)` (avoids `env.ts` startup validation, per the established `judicialCalAccessIngest.test.ts` precedent) and `vi.stubGlobal('fetch', vi.fn())` for the two HTTP call sites
- [ ] Extend `backend/src/lib/fecResearch.ts`'s test coverage (no test file exists today either) to confirm its candidate-search fetch also calls `acquireFecSlot()`
- [ ] Framework install: none — Vitest is already configured and used project-wide; no new test tooling needed

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | This phase touches no user-facing auth surface — it is a server-to-server API client hardening change |
| V3 Session Management | No | N/A |
| V4 Access Control | No | The one access-control-adjacent observation (the `/admin/ingest/fec` route not sharing `FEC_LOCK_KEY`) is an operational-coordination gap, not an authz gap — the route already requires `requireAuth` + `requireAdmin` `[VERIFIED: campaignFinanceAdmin.ts]` |
| V5 Input Validation | Yes | `Retry-After` header parsing must handle both the numeric-seconds and HTTP-date forms defensively (never trust the value blindly — clamp to a sane max, e.g. `Math.min(parsed, 120_000)`, mirroring the existing `Math.min(delayMs * 2, 120_000)` cap) so a malformed or adversarial header value from a compromised/misbehaving upstream cannot induce an unbounded sleep |
| V6 Cryptography | No | No cryptographic material introduced |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed/huge `Retry-After` header value causing an effectively-infinite sleep (denial of service against the ingest job itself) | Denial of Service | Clamp any server-provided delay to the existing 120s exponential-backoff ceiling before sleeping — never sleep on an unclamped server-supplied value |
| A cache-poisoning-adjacent risk: caching a wrong/empty committee-ID result and suppressing legitimate finance data collection | Tampering (of internal cache state, not by an external attacker — a correctness bug, not a security vuln per se) | Only cache non-empty results (Pitfall 3); this is a data-integrity control, not a traditional ASVS security control, but worth the same rigor given `essentials`/`transparent_motivations` data-quality standards elsewhere in this codebase |

## Sources

### Primary (HIGH confidence)
- `backend/src/lib/adapters/fecAdapter.ts` (full file read this session) — the two existing FEC request sites, current backoff implementation
- `backend/src/lib/campaignFinanceScheduler.ts` (full file read this session) — confirmed sequential (non-concurrent) source loop, existing lock pattern, existing 3s inter-source sleep
- `backend/src/cron/campaignFinanceCron.ts` (full file read this session) — cron registration
- `backend/src/lib/cache.ts` (full file read this session) — existing cache pattern to reuse
- `backend/src/lib/adapters/runIngestion.ts` (full file read this session) — exact `ingestion_runs` write path, confirms FEC-04's verification query design
- `backend/src/lib/fecResearch.ts`, `backend/src/routes/campaignFinanceAdmin.ts`, `backend/src/lib/fecBackfill.ts` (grepped/read this session) — discovered the third FEC call site and the unlocked admin single-source route
- `backend/src/lib/discoveryCron.test.ts`, `backend/src/lib/judicial/judicialCalAccessIngest.test.ts` (read this session) — established test-mocking conventions (`vi.mock('./db.js', ...)`, `vi.mock('./env.js', ...)`, `vi.hoisted`)
- https://api.data.gov/docs/developer-manual/ — fetched live this session; confirmed `X-RateLimit-Limit`/`X-RateLimit-Remaining` headers, 1,000/hr default, rolling-hourly-window block behavior, no `Retry-After`/`X-RateLimit-Reset` documented
- `npm view @upstash/redis version` / `npm view @upstash/ratelimit` (run this session) — version and registry-legitimacy verification

### Secondary (MEDIUM confidence)
- WebSearch: api.data.gov general rate-limit documentation summary (corroborates the directly-fetched developer-manual page)
- WebSearch: FEC-specific rate limits — DEMO_KEY 40/hr, registered key 1,000/hr, upgrade to 7,200/hr via `APIinfo@fec.gov` (multiple independent third-party FEC API integration guides agree; matches the pre-existing `FEC_API_KEY` comment already in `backend/src/lib/env.ts`)
- WebSearch: NREL/api-umbrella project docs — corroborates the `X-RateLimit-Limit`/`X-RateLimit-Remaining`-only header set, since api.data.gov and FEC's own API Umbrella deployment share this open-source middleware

### Tertiary (LOW confidence)
- WebSearch result claiming "effective rate limit on the OpenFEC API is 100 calls per hour" — contradicted by three independent, more specific sources (the directly-fetched api.data.gov manual, the DEMO_KEY/registered-key breakdown, and this codebase's own pre-existing `env.ts` comment) all agreeing on 1,000/hr for a registered key; disregarded as likely a stale/miscontextualized figure
- `@upstash/ratelimit` as an alternative dependency — training-data recall, not an official-docs lookup; tagged `[ASSUMED]` throughout despite registry/download verification (see Package Legitimacy Audit)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — reuses two already-proven in-repo patterns (`cache.ts`, the existing lock's Redis-init style); no new dependency in the Core recommendation
- Architecture: HIGH — grounded in direct reads of all four named files plus the two additional call sites found by grep; the sequential-vs-concurrent question was directly answered from source, not assumed
- Pitfalls: HIGH for the header-name correction (directly fetched official docs); MEDIUM for the exact FEC-vs-generic-api.data.gov reset-window semantics (see Assumption A2)

**Research date:** 2026-07-23
**Valid until:** 30 days (stable domain — FEC's rate-limit policy and this codebase's Redis/cache conventions change infrequently; re-verify the api.data.gov header documentation if this phase's execution slips past ~2026-08-22, since gov API docs do occasionally get restructured)
