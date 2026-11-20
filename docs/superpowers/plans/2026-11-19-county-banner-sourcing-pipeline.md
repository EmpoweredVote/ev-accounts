# County Banner Sourcing Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Given a state, produce a per-county set of banner candidates that have passed the polygon, resolution and licence gates, rendered as full uncropped source frames and ranked, ready for the operator's review surface.

**Architecture:** Four stages — sweep, locate, filter, render — each a pure module with a thin CLI wrapper, chained by JSON on disk so any stage can be rerun without repeating the one before it. Node and TypeScript under `backend/scripts/county-banners/`, tested with the repo's existing vitest. The existing Python scripts (`sweep-commons-banner-candidates.py`, `geocheck-commons-candidates.py`) are the **reference for the rules**, not a dependency: their category-traversal depth, their 50-title coordinate batching and their rule that uncoordinated files are kept separately rather than discarded all carry forward as comments. Rewritten in Node because the repo's test harness (`npm run test:unit` covers `scripts`) cannot see Python, and because `python` is not on PATH on the operator's machine — only the `py` launcher is.

**Tech Stack:** TypeScript, Node 24, vitest 5, `pg` (already a dependency), `@napi-rs/canvas` (**must be added — it is currently undeclared and present only transitively**).

**Spec:** `docs/superpowers/specs/2026-11-19-county-banner-sourcing-design.md`

**This is plan 1 of 4.** It produces the input to plan 2 (review surface), which produces the input to plan 3 (delivery) and plan 4 (map tier). It is independently useful: its output is a reviewable candidate set for a state, which is what the Nebraska run proved out.

## Global Constraints

- The shipped asset is **1700 × 540** (3.148:1). Desktop renders a **6:1** band — **52.5%** of asset height, rows 128–412. Mobile renders **13:4** — **96.9%** of the asset.
- **Minimum source size: 1700px on the long edge.** Anything smaller cannot be built without upscaling.
- **A file with no readable author or licence is not a candidate.** Filtered before the operator sees it, never after. Essentials' own rule: *"a banner we cannot credit is a banner we cannot show."*
- 🔴 **The User-Agent is a generic client name and contains no personal contact details.** Many existing scripts in `backend/scripts/` put a named individual's email address in their User-Agent and send it to Wikimedia on every request; do not copy that pattern. Wikimedia 429s a fully anonymous UA, so name the client and its purpose without naming a person. If a host ever demands a real contact address, ask the operator which to use rather than reading one from the repo.
- **County membership is `ST_Contains` against `essentials.geofence_boundaries` where `mtfcc = 'G4020'`.** Geometry only. Category names are recall, never evidence.
- **`geo_id` is not unique — the key is `(mtfcc, geo_id)`.** Every county query carries the `mtfcc` filter.
- **Never create a table or view in `public`.** This plan creates no tables; plan 2 does.
- **A detector that reports "nothing found" is untrusted until a control has been watched failing.**
- Cap the operator's view at **five options per county**, by a written ranking, with a way to request the next five.

## Review Focus

Five conditions the spec implies that no stage's happy path exercises. Each has a test in the task that owns the code.

1. **A county whose polygon is missing or invalid** returns zero candidates and looks exactly like a county with no photographs. It must fail loudly and name the county, not report an empty set. (Task 3)
2. **Commons answers 429 or serves a WAF challenge with HTTP 200.** Both must back off and retry, and a challenge body must never be parsed as "no files". (Task 1)
3. **A licence field that is absent is not a licence that is free.** Absent, unreadable and non-free are three outcomes and only one of them is "drop quietly". (Task 4)
4. **A file carries coordinates that fall in no county in the state** — a bad geotag, or a photo genuinely elsewhere. It is dropped, counted and reported, never silently lost. (Task 3)
5. **A county that produced zero candidates must be distinguishable from a county that was never swept.** Otherwise a crashed run reads as genuine absence, which is exactly how 20 Nebraska counties could have been mislabelled. (Task 7)

---

### Task 1: Commons client

**Files:**
- Create: `backend/scripts/county-banners/types.ts`
- Create: `backend/scripts/county-banners/commonsClient.ts`
- Test: `backend/scripts/county-banners/commonsClient.test.ts`
- Modify: `backend/package.json` (add `@napi-rs/canvas` to dependencies)

**Interfaces:**
- Produces: `type CandidateFile = { title: string; url: string; width: number; height: number; licence: string | null; author: string | null; date: string | null; sourceCategory: string; lat: number | null; lon: number | null }`
- Produces: `type CountyCandidates = { geoid: string; name: string; swept: boolean; candidates: CandidateFile[]; rejected: Record<string, number> }`
- Produces: `commonsApi(params: Record<string, string | number>): Promise<unknown>` — retries with backoff, throws `CommonsBlockedError` on a challenge body.
- Produces: `const USER_AGENT: string`

- [ ] **Step 1: Write the failing tests**

```ts
describe('commonsApi', () => {
  it('retries on 429 and succeeds', async () => { /* fetch stub: 429, 429, 200 → resolves, 3 calls */ });
  it('throws CommonsBlockedError when a 200 body is a WAF challenge, not JSON', async () => {
    // stub returns status 200 with an HTML body
    await expect(commonsApi({ action: 'query' })).rejects.toBeInstanceOf(CommonsBlockedError);
  });
  it('gives up after 4 attempts and throws, never returning an empty result', async () => { /* 4x 503 → rejects */ });
});
describe('USER_AGENT', () => {
  it('names a client and a purpose', () => { expect(USER_AGENT).toMatch(/EmpoweredVote/); });
  it('carries no personal contact details', () => { expect(USER_AGENT).not.toMatch(/@/); });
});
```

- [ ] **Step 2: Run the tests and watch them fail**

Run: `npm run test:unit --prefix backend -- county-banners/commonsClient`
Expected: FAIL — module not found.

- [ ] **Step 3: Implement `commonsClient.ts` and `types.ts`**

`commonsApi` uses `fetch` against `https://commons.wikimedia.org/w/api.php` with `format=json&formatversion=2`, four attempts, backoff `2s × attempt`. 🔴 A 200 whose body does not parse as JSON is a challenge, not an empty result — throw, never return `{}`. Carry the rule in a comment: *a WAF rejection can be HTTP 200, so never judge a fetch by `r.ok`.*

- [ ] **Step 4: Run the tests and watch them pass**

Run: `npm run test:unit --prefix backend -- county-banners/commonsClient`
Expected: PASS.

- [ ] **Step 5: Add `@napi-rs/canvas` to `backend/package.json` dependencies and verify a clean install resolves it**

Run: `npm ls @napi-rs/canvas --prefix backend`
Expected: it appears as a direct dependency, not `(empty)` or deduped-transitive only.

- [ ] **Step 6: Commit**

```bash
git add backend/scripts/county-banners/types.ts backend/scripts/county-banners/commonsClient.ts backend/scripts/county-banners/commonsClient.test.ts backend/package.json backend/package-lock.json
git commit -m "feat(county-banners): Commons client with backoff, challenge detection and a generic UA" -- backend/scripts/county-banners backend/package.json backend/package-lock.json
```

---

### Task 2: Category sweep

**Files:**
- Create: `backend/scripts/county-banners/sweep.ts`
- Test: `backend/scripts/county-banners/sweep.test.ts`

**Interfaces:**
- Consumes: `commonsApi`, `CandidateFile` from Task 1.
- Produces: `sweepCategories(roots: string[], depth?: number): Promise<CandidateFile[]>` — default `depth = 1`.
- Produces: `countyCategoryRoots(countyName: string, stateName: string, seatName: string | null): string[]`

- [ ] **Step 1: Write the failing tests**

```ts
it('walks one level of subcategories by default', /* root + 2 subcats → files from all three */);
it('de-duplicates a file that appears in two categories', /* same title twice → one record, first category recorded */);
it('records licence, author, width and height on every file', /* asserts the four fields present */);
it('continues past a category that errors and reports it', /* one subcat throws → other files still returned */);
it('includes the county seat among the roots', () => {
  expect(countyCategoryRoots('Dawson County', 'Nebraska', 'Lexington'))
    .toEqual(expect.arrayContaining([expect.stringContaining('Lexington')]));
});
```

- [ ] **Step 2: Run the tests and watch them fail**

Run: `npm run test:unit --prefix backend -- county-banners/sweep`
Expected: FAIL.

- [ ] **Step 3: Implement `sweep.ts`**

Traversal mirrors the Python original: `list=categorymembers` with `cmtype=subcat` to collect categories, then `generator=categorymembers` with `prop=imageinfo` for files, paging on `continue`. 🔴 Carry its comment forward — *sweep categories and their subcategories, not keyword search; recall matters more than precision.* `countyCategoryRoots` includes the county, the state-qualified county, and the county seat, because the subject rule admits the seat (spec, *Subject rule*).

- [ ] **Step 4: Run the tests and watch them pass**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(county-banners): category sweep with seat roots and per-category error isolation" -- backend/scripts/county-banners
```

---

### Task 3: Locate — coordinates and the polygon test

**Files:**
- Create: `backend/scripts/county-banners/locate.ts`
- Test: `backend/scripts/county-banners/locate.test.ts`

**Interfaces:**
- Consumes: `CandidateFile`, `commonsApi`.
- Produces: `attachCoordinates(files: CandidateFile[]): Promise<CandidateFile[]>` — batches titles 50 at a time.
- Produces: `assignToCounties(files: CandidateFile[], stateFips: string, db: Pool): Promise<{ located: Map<string, CandidateFile[]>; unlocated: CandidateFile[]; outside: CandidateFile[] }>`
- Produces: `class MissingPolygonError extends Error` — carries the offending geoid.

- [ ] **Step 1: Write the failing tests**

```ts
it('batches coordinate lookups 50 titles at a time', /* 120 files → 3 calls */);
it('keeps files with no coordinates as `unlocated`, never discarding them', /* spec: absence of a coordinate is not evidence the photo is elsewhere */);
it('assigns a file to the county whose polygon contains it', /* stub db → located map keyed by geoid */);
it('returns a coordinate inside no county as `outside`, counted, not dropped silently', /* 1 file → outside.length === 1 */);
it('throws MissingPolygonError naming the county when its polygon is absent', async () => {
  await expect(assignToCounties(files, '31', dbWithNoPolygons))
    .rejects.toThrow(/31047/);   // Review Focus 1: zero candidates must not look like no photographs
});
it('filters on (mtfcc, geo_id), not geo_id alone', /* asserts the SQL text carries mtfcc = 'G4020' */);
```

- [ ] **Step 2: Run the tests and watch them fail**

- [ ] **Step 3: Implement `locate.ts`**

The polygon query, one round trip per state rather than per file:

```sql
SELECT g.geo_id, f.title
  FROM unnest($1::text[], $2::float8[], $3::float8[]) AS f(title, lat, lon)
  JOIN essentials.geofence_boundaries g
    ON g.mtfcc = 'G4020'
   AND g.state = $4
   AND ST_Contains(g.geometry, ST_SetSRID(ST_MakePoint(f.lon, f.lat), 4326))
```

🔴 Before assigning anything, count the state's `G4020` polygons and throw `MissingPolygonError` if any county in the requested set has none. A detector that reports "nothing found" is untrusted. `state` is 2-digit FIPS in this table, not USPS.

- [ ] **Step 4: Run the tests and watch them pass**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(county-banners): polygon assignment, with unlocated and outside kept and counted" -- backend/scripts/county-banners
```

---

### Task 4: Filter — resolution, licence, attribution

**Files:**
- Create: `backend/scripts/county-banners/filter.ts`
- Test: `backend/scripts/county-banners/filter.test.ts`

**Interfaces:**
- Consumes: `CandidateFile`.
- Produces: `filterCandidates(files: CandidateFile[]): { kept: CandidateFile[]; rejected: Record<'too_small' | 'licence_absent' | 'licence_non_free' | 'author_absent', number> }`
- Produces: `const MIN_LONG_EDGE = 1700`
- Produces: `const FREE_LICENCE = /^(cc0|cc[ _-]by|public domain|pd-)/i`

- [ ] **Step 1: Write the failing tests**

```ts
it('rejects a source under 1700px on the long edge', /* 1699 → too_small; 1700 → kept */);
it('counts an absent licence separately from a non-free one', () => {
  const r = filterCandidates([fileWith({ licence: null }), fileWith({ licence: 'All rights reserved' })]).rejected;
  expect(r.licence_absent).toBe(1);
  expect(r.licence_non_free).toBe(1);   // Review Focus 3: absent is not free
});
it('rejects a file with no author even when the licence is free', /* author: null, licence: 'CC BY 4.0' → author_absent */);
it('keeps a CC0 file with an author', /* kept.length === 1 */);
it('reports every rejection reason with a count, so a county that filtered to zero can say why', /* sums to input length */);
```

- [ ] **Step 2: Run the tests and watch them fail**

- [ ] **Step 3: Implement `filter.ts`**

Order the gates cheapest first: size, then licence, then author. Each rejection increments its own counter — the counts are what tell the operator whether a county has no photographs or merely no *usable* ones.

- [ ] **Step 4: Run the tests and watch them pass**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(county-banners): resolution, licence and attribution gates with per-reason counts" -- backend/scripts/county-banners
```

---

### Task 5: Rank

**Files:**
- Create: `backend/scripts/county-banners/rank.ts`
- Test: `backend/scripts/county-banners/rank.test.ts`

**Interfaces:**
- Consumes: `CandidateFile`.
- Produces: `rankCandidates(files: CandidateFile[]): CandidateFile[]`
- Produces: `const PAGE_SIZE = 5`

- [ ] **Step 1: Write the failing tests**

```ts
it('prefers a source with more vertical slack than a 3.148:1 crop needs', /* the slack is the crop lever */);
it('prefers a larger source at equal shape', /* 3000px before 1800px */);
it('is a total order with no ties, so the ranking is reproducible', /* two runs, same order */);
it('does not rank by category name', /* spec: categories are recall, not evidence */);
```

- [ ] **Step 2: Run the tests and watch them fail**

- [ ] **Step 3: Implement `rank.ts`**

🔴 The ranking is the component the spec measured wrong **47%** of the time, so it is written down and testable rather than implicit. Rank on measurable properties only — aspect slack against 3.148:1, then long edge, then title as a stable tiebreak. It narrows; it does not choose.

- [ ] **Step 4: Run the tests and watch them pass**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(county-banners): explicit, reproducible candidate ranking" -- backend/scripts/county-banners
```

---

### Task 6: Render full source frames

**Files:**
- Create: `backend/scripts/county-banners/render.ts`
- Test: `backend/scripts/county-banners/render.test.ts`

**Interfaces:**
- Consumes: `CandidateFile`, `@napi-rs/canvas` from Task 1.
- Produces: `renderSourceFrame(buf: Buffer, outPath: string): Promise<{ width: number; height: number; srcRatio: number }>`
- Produces: `const MAX_EDGE = 1100`

- [ ] **Step 1: Write the failing tests**

```ts
it('keeps the whole frame — it never crops', () => {
  const r = renderSourceFrame(tallImage(2000, 3000), out);
  expect(r.srcRatio).toBeCloseTo(2000 / 3000, 3);   // the vertical slack IS the lever
});
it('downscales the long edge to 1100 and leaves a smaller image alone', /* 3000→1100; 800→800 */);
it('reports srcRatio so a source with no slack can be identified', /* 3.148 → srcRatio 3.148 */);
```

- [ ] **Step 2: Run the tests and watch them fail**

- [ ] **Step 3: Implement `render.ts`**

🔴 No crop at any point. The spec's step 3: *a pre-cropped file throws away the vertical slack, and that slack is the lever* — the review surface sets both the vertical anchor and the focus inside this frame, so a cropped render silently removes both controls.

- [ ] **Step 4: Run the tests and watch them pass**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(county-banners): full uncropped source frame rendering" -- backend/scripts/county-banners
```

---

### Task 7: CLI and a one-state run

**Files:**
- Create: `backend/scripts/county-banners/build-state-candidates.ts`
- Test: `backend/scripts/county-banners/build-state-candidates.test.ts`
- Modify: `backend/package.json` (add `banners:candidates` script)

**Interfaces:**
- Consumes: every module above.
- Produces: `buildStateCandidates(stateUsps: string, outDir: string, db: Pool): Promise<CountyCandidates[]>`
- Produces: a JSON file per state — the input plan 2's review surface reads.

- [ ] **Step 1: Write the failing tests**

```ts
it('emits a row for every county in the state, including those with no candidates', async () => {
  // Review Focus 5 — the distinguishing test
  const rows = await buildStateCandidates('NE', dir, stubDb);
  expect(rows).toHaveLength(93);
  expect(rows.find(r => r.geoid === '31047')!.swept).toBe(true);
});
it('marks a county that was never swept as swept:false, distinct from zero candidates', /* crashed sweep → swept false, candidates [] */);
it('caps candidates at five per county and keeps the rest retrievable', /* 12 in → 5 shown, 12 stored */);
it('carries the rejection counts onto the county row', /* rejected.too_small === 3 */);
it('is resumable — a second run skips counties already written', /* second run makes no Commons calls */);
```

- [ ] **Step 2: Run the tests and watch them fail**

- [ ] **Step 3: Implement `build-state-candidates.ts`**

Chain the stages, writing each county's row as it completes so a crash loses one county rather than a state. 🔴 `swept: false` is the default and is only set true once a county's sweep returns — Review Focus 5 is that a crashed run must not read as genuine absence.

- [ ] **Step 4: Run the tests and watch them pass**

- [ ] **Step 5: Plant a positive control before trusting the run**

Point the polygon query at a state with no `G4020` rows and confirm it **throws** `MissingPolygonError` rather than reporting zero candidates. Watch it fail, then restore and watch it pass. 🔴 A uniform answer is a broken detector until a control has been watched failing.

Expected: first run throws and names a geoid; second run completes.

- [ ] **Step 6: Run it for one real state and read what it says it did**

Run: `npm run banners:candidates --prefix backend -- NE`
Expected: 93 county rows; every row carries `swept: true`; the totals for located / unlocated / outside / rejected sum to the files swept. ⚠ A green run can be a no-op — read the counts, not the exit code.

- [ ] **Step 7: Commit**

```bash
git commit -m "feat(county-banners): state CLI, resumable, with a watched polygon control" -- backend/scripts/county-banners backend/package.json
```

---

## Self-review notes

- **Spec coverage.** Steps 1–3 of the spec's method map to Tasks 2, 3–4 and 6. The ranking cap and the 1700px and licence gates from *Calls made during review* map to Tasks 5 and 4. Steps 4–7 of the method (the review surface, delivery, the map tier) are **out of scope by design** and belong to plans 2–4.
- **Not covered here, deliberately:** the review table and its migration (plan 2 — it needs a steward slot, `npm run steward --prefix backend -- slot CC --purpose "..."`, asked for at execution time, never counted); `CURATED_COUNTY` delivery and the Civic Spaces `focus` change (plan 3); map rendering (plan 4).
- **Round-2 sourcing** (non-Commons sources with no coordinates) is not in this plan. The spec's proposed caption rule applies there, and `locate.ts` already keeps `unlocated` separately so those files survive to be handled rather than being thrown away now.
