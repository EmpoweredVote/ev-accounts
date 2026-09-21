# congress.gov official-API tier for citation verification — design

Date: 2026-09-11
Task: `ev-cto/tasks/2026-09-11-congress-gov-api-tier.md`
Decision: 0003 (scraping toolchain) · watchlist #19 follow-up · rung 2 coverage-gap recovery, no vendor.

## Context

The stance/citation verifier fetches a cited page and checks, deterministically,
that the stored snippet appears on it (`researchVerifier.matchSnippet` +
`checkNameProximity`). The fetch ladder lives in
`backend/src/lib/verificationFetch.ts`:

1. robots gate → 2. tier 1 plain HTTP fetch → 3. tier 3 Wayback (`/available`
   then CDX).

`congress.gov` **403s a plain fetch**. The block is fingerprint-based (the honest
`EmpoweredVoteBot` UA and a spoofed browser UA both get the identical 403), and
spoofing is forbidden by decision 0003 rung 0. congress.gov is a top source:
~176 distinct URLs in the compass corpus (≈1.0%), 65 distinct in
`source_verifications`. The clean, no-vendor fix is the **official API**:
`https://api.congress.gov/v3/...` serves bill and member data as JSON with a free
api.data.gov key — no scraping, no browser.

This tier's *marginal* value is the congress.gov URLs that fail tier 1 **and**
that tier 3 (Wayback/CDX, shipped in PR #469) does not already recover. The
measurement (below) quantifies exactly that.

### API contract (verified 2026-09-11)

- Keyless request → `HTTP 403`, body `{"error":{"code":"API_KEY_MISSING", ...}}`.
- With a key, `GET /v3/bill/{congress}/{billType}/{number}?format=json` returns a
  `bill` object with `title`, `sponsors[]`, `latestAction`, `policyArea`, and
  **links to sub-resources** (`summaries`, `cosponsors`, `actions`,
  `textVersions`) as separate URLs. A rich "page text" therefore needs a small
  fan-out of sub-resource calls, not one call.

## Goal

When a citation URL is on congress.gov, verify it against the official API JSON
instead of scraping HTML. The adapter runs BEFORE the generic tiers for
congress.gov hosts and falls through to the existing ladder (robots → tier 1 →
Wayback) when the key is absent, the URL is out of scope, or the API has no
match. No regression to today's behavior in any of those cases.

## Real URL shapes (from the corpus, not the task's simplified examples)

Sampled from committed research CSVs. Three differences from the task's examples
drive the parser:

- **Congress is a slug**: `/bill/119th-congress/house-bill/1234` → parse `119`
  from `119th-congress` (leading integer).
- **Member has a name slug before the id**: `/member/ayanna-pressley/P000617`,
  sometimes with `?q=...`. The bioguideId is the **last path segment** matching
  `^[A-Z]\d{6}$`.
- **Sub-pages are common and map to sub-resources**: `/cosponsors` (~133),
  `/text` (~80), `/all-actions`, `/all-info`. The overview path (no suffix) is
  the most common.

Bill-type slug → API code map:

| URL slug                        | API code |
|---------------------------------|----------|
| `house-bill`                    | `hr`     |
| `senate-bill`                   | `s`      |
| `house-resolution`              | `hres`   |
| `senate-resolution`             | `sres`   |
| `house-joint-resolution`        | `hjres`  |
| `senate-joint-resolution`       | `sjres`  |
| `house-concurrent-resolution`   | `hconres`|
| `senate-concurrent-resolution`  | `sconres`|

**Out of scope → return `null` (fall through to ladder)**: `/event/...`,
`/congressional-record/...`, `/committee/...`, `/amendment/...`, `/nomination/...`,
and any URL that does not parse to a bill or member. Amendments have a different
endpoint and are rare in the corpus; a follow-up can add them if the re-measure
shows a residual.

## Design

### 1. New adapter — `backend/src/lib/adapters/congressAdapter.ts`

Export one function:

```ts
export async function fetchCongressPageText(
  url: string,
  deps?: { fetchImpl?: FetchLike; apiKey?: string },
): Promise<string | null>;
```

- Return `null` immediately when: host is not `congress.gov`/`www.congress.gov`;
  the path does not parse to a bill or member; or no key is available
  (`deps.apiKey ?? process.env.CONGRESS_GOV_API_KEY`). `null` = no-op → the
  ladder proceeds exactly as today.
- **Bill** → build ONE composite plain-text string, ordered so names sit next to
  the text they relate to (the matcher needs the politician name within 500 chars
  of the snippet match):
  1. `GET /v3/bill/{c}/{type}/{n}` → title, policyArea, sponsor name(s), latest
     action.
  2. `GET .../summaries` → CRS summary/summaries (`summaries[].text` is HTML →
     strip with the existing `htmlToText`).
  3. `GET .../cosponsors` → cosponsor names (covers `/cosponsors`-page snippets).
  4. `GET .../actions` → latest N actions text (covers `/all-actions` snippets).
  5. **Best-effort `/text`**: `GET .../text` → pick a text version's "Formatted
     Text"/HTML/XML URL, fetch it, strip to text, append. Any failure here is
     swallowed and the composite from 1–4 is used. This makes the re-measure fair
     for `/text` URLs without letting the text hop break the common path.

  One composite serves overview, `/cosponsors`, `/all-actions`, and `/all-info`
  snippets, so the adapter does not branch per sub-path — it always builds the
  richest text and lets the matcher find the snippet in it.
- **Member** → `GET /v3/member/{bioguideId}` → name + party + state + terms
  (chamber/dates). Name proximity is trivially satisfied.
- On any 404 / API error / empty result → `null` (fall through). A 403 with
  `API_KEY_MISSING` is treated as "no key" → `null`.

Testability: `fetchImpl` is a `fetch`-shaped seam (same pattern as
`WaybackDeps.fetchImpl`); unit tests inject a fake client keyed by URL and assert
the composite text, so no network and no real key are needed.

### 2. Rate limit — `backend/src/lib/adapters/apiDataGovRateLimiter.ts` (new)

Mirror `fecRateLimiter.ts` (per-UTC-minute budget, Redis `INCR`/`EXPIRE` with an
in-process fallback, bounded wait, honours an `AbortSignal`) in its **own key
space** `congress:ratelimit:*`, default ~15/min (~900/hr, 10% under the 1,000/hr
ceiling), env-tunable. `fecRateLimiter.ts` is **not** modified — it has a
documented 29-minute-stall incident and a careful contract; the congress path
takes zero blast radius on it. Volume here is low (≤ ~4 sub-calls × ~176 URLs,
verified sequentially by the verifier), so the in-process fallback is usually
sufficient; the gate is cheap insurance against a cron+manual overlap.

### 3. Env — `backend/src/lib/env.ts`

Add `CONGRESS_GOV_API_KEY: z.string().optional()` with a comment mirroring
`FEC_API_KEY` (free key from api.data.gov; lives in the Render dashboard, never in
git). Optional → the server still starts without it. The adapter reads
`process.env.CONGRESS_GOV_API_KEY` at call time so a Render env change takes
effect on redeploy without a code change and tests can set/clear it.

### 4. Wiring — `verificationFetch.ts`

- Add `congressAdapter?: (url: string) => Promise<string | null>` to
  `VerificationFetchDeps`, defaulting to `fetchCongressPageText`.
- In `session.fetch(url)`, call it FIRST, before the robots gate:

  ```ts
  try {
    const t = await congressAdapter(url);
    if (t && looksLikeRealPage(t)) return t;
  } catch { /* fall through to the generic ladder */ }
  ```

  The adapter hits `api.congress.gov` under our own key — an authorized official
  API, not a fetch of the live `congress.gov` site — so it correctly runs ahead
  of the robots gate. A thin or absent result falls through to today's ladder.

## Testing (completable now, no key, no network)

Unit tests for `congressAdapter` with a stubbed `fetchImpl`:

- A bill URL (each real shape: overview, `/cosponsors`, `/text`, slug congress
  `119th-congress`) yields composite text that contains the title, summary, and
  sponsor/cosponsor names, and a stored-style snippet verifies through
  `matchSnippet` + `checkNameProximity`.
- A member URL (name-slug + trailing bioguideId, with and without `?q=`) yields
  member text.
- 404 / API error → `null` (ladder fall-through).
- No key → `null` (no-op), asserted with `CONGRESS_GOV_API_KEY` unset.
- Out-of-scope URL (`/event/...`, non-congress host) → `null`.
- Best-effort `/text`: text-hop failure still returns the composite.

Wiring test in `verificationFetch.test.ts`: an injected `congressAdapter` result
is returned ahead of tier 1; a `null` result falls through to the stubbed ladder.

`npx tsc` passes; existing tests pass.

## Measurement (STOP-AND-ASK — needs the key; Chris runs it)

Acceptance requires re-measuring the STEP 1 sample: of congress.gov URLs that
fail tier 1 (403), how many the API newly verifies **beyond** what Wayback/CDX
already recovers. That needs (a) a live `CONGRESS_GOV_API_KEY` and (b) the prod
list of congress.gov URLs + their stored snippets from `source_verifications`.
Claude does not hold the key and must not handle it.

Deliverable: a measurement script (scratchpad or `backend/scripts/`, not shipped)
that, given the key, pulls congress.gov rows from `source_verifications`, runs the
real ladder with and without the adapter, and prints: tier-1 fails, of those how
many Wayback/CDX recovers, and how many the API newly verifies (the recovered
count). Chris runs it and records the count.

STOP-AND-ASK trigger: if the API's text coverage is too thin to match stored
snippets (e.g. snippets quote rendered page furniture the API structures
differently), report and decide whether the tier is worth keeping versus letting
CDX/Wayback cover congress.gov.

## Acceptance

- [ ] Unit test (stubbed client): a congress.gov bill URL yields verifiable text;
      a 404/no-match falls through; no key → no-op fall-through.
- [ ] `npx tsc` passes; existing tests pass.
- [ ] Re-measure the STEP 1 sample and record the recovered count (Chris, with
      the key).

## Out of scope (v1)

- Amendments, committee events, congressional-record, nominations, committee
  pages — return `null`, ladder covers them (or accepts the gap).
- First-class full-text retrieval with retries/format negotiation — `/text` is
  best-effort only.
- Refactoring `fecRateLimiter.ts` to share a client — deliberately untouched.
