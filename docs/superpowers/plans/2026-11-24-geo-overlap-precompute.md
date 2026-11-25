# Geo-overlap precompute — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `resolveOverlappingGeoPairs` compute an area once per boundary version and per resolver-code version, instead of once an hour, and warm the 53 state seeds so a Civic Spaces member never pays the cold 7-second call.

**Architecture:** A durable per-seed store (`essentials.geo_overlap_pairs`) keyed on `(seed_geo_id, seed_mtfcc, geofence_version, query_fingerprint)`. `geofence_version` is a one-row bigint bumped by a trigger on `essentials.geofence_boundaries` that fires only on real change and at most once per transaction. `query_fingerprint` is a hash of the resolver's own SQL text, which carries all four code-side constants that change the answer. Redis stays in front, with both values in its key. A warming job stores the 53 `G4000` seeds and sweeps superseded rows; it is importable, so the TIGER loader and a migration post-verify can call it directly.

**Tech Stack:** TypeScript (strict, ESM), Express, node-postgres through `backend/src/lib/db.ts`, Upstash Redis over HTTP through `backend/src/lib/cache.ts`, PostGIS on Supabase Postgres 17, Vitest.

**Spec:** [`docs/superpowers/specs/2026-11-24-geo-overlap-precompute-design.md`](../specs/2026-11-24-geo-overlap-precompute-design.md) — read it before Task 1, including both 🔴🔴 "CORRECTED AFTER THE BUILDER CHECK" blocks and § "What the builder check changed".

**Branch / worktree:** `feat/geo-overlap-precompute` in `C:\ev-accounts-seating`. Step 1 is already merged (PR #1605, `371e79c895`); this is step 2.

---

## Global Constraints

- **The migration slot is already allocated: `CC_0511`.** Reserved 2026-11-24 for "geo_overlap_pairs + geofence_version: durable, version-invalidated overlap store with a change-only bump trigger and RLS". Do not count, do not re-allocate, do not renumber. One migration, one file.
- **`essentials` RLS is the only belt.** `ALTER DEFAULT PRIVILEGES` in that schema already grants `anon` and `authenticated` SELECT and `ev_api` `arwd` on every new table before any migration says a word. A new table there is `anon`-readable from the moment it exists unless the same file enables RLS, and nothing errors if it does not.
- **`ev_api` cannot run DDL.** The migration goes through the owner connection (the Supabase MCP, project `kxsdzaojfaibhuzmclfq`, which **is production**), as `CC_0468` and `CC_0472` did. Production authenticates as `ev_api`, which carries `rolbypassrls = true`.
- **Never raise a baseline to clear a red.** If an existing gate goes red, the branch is late or wrong — not the baseline.
- **`EXPLAIN` (never `ANALYZE`) before any new filtered read against a production table.** Postgres 17 cannot skip into the middle of a composite index; `essentials.geofence_boundaries`' key is `(geo_id, mtfcc)`, so a filter on `mtfcc` alone does not lead it.
- **Run a positive control on any detector that reports "nothing found", and watch it fail first.** Assert the tamper is PRESENT before believing a red, and print the row count the detector actually examined — a control proves a verifier *can* fail, not that it read the right rows.
- **Commit after every task** (crash resilience, not hygiene). Commit with an explicit pathspec: `git commit -F msg -- <paths>`.
- **The answer does not change.** Not by a row, for any seed. Everything else here is subordinate to that.
- **Execute natively. Do not fan out subagents** beyond a single reviewer at a time.

## Review Focus

Five things the design implies that no happy path exercises. Each has its test named in the task that owns the code.

1. **The `geofence_version` row is missing, or the tables do not exist yet** — a deploy that lands before the migration is applied, or a half-applied migration. The read path must fall back to computing and must not 500. *(Task 4, `falls back to computing when the version row cannot be read`.)*
2. **A seed that exists in no `geofence_boundaries` row.** `/by-area` and `/elections-by-area` take `geo_id` and `mtfcc` from an unauthenticated body, validated only as non-empty strings (`essentialsBrowse.ts:84-92`). It must resolve to zero pairs and write **no** row — otherwise the primary key of a permanent `essentials` table is caller-controlled free text anyone can add to at will. *(Task 4, `does not store a seed that is not in geofence_boundaries`.)*
3. **Two processes computing the same seed at once.** The warming job and a live request will collide on `(seed, version, fingerprint)`. The write must be an upsert, not a unique violation surfaced as a 500. *(Task 3, `writeStoredPairs is idempotent for the same key`.)*
4. **The version moves while a compute is in flight.** The row must carry the version read **before** the compute, so a row written against half-ingested geometry is born superseded and unreadable. Writing the post-compute version publishes a wrong answer at the current version — the named anti-goal. *(Task 4, `stores the version read before the compute, not after`.)*
5. **Redis holds a value of the old shape, or a truncated one.** `cache.get` is typed `<T>` and validates nothing. A `v2`-era entry must not reach a caller as pairs. *(Task 4, `ignores a cached value that is not an array of pairs`.)*

---

## File structure

| File | Responsibility |
|---|---|
| `backend/migrations/CC_0511_geo_overlap_pairs.sql` *(create)* | Both tables, the bump trigger, RLS, a post-verify block. |
| `backend/src/lib/geoOverlapStore.ts` *(create)* | Everything that touches the two new tables, plus `fingerprintOf`. Knows nothing about the resolver's SQL — it is *passed* a fingerprint. That is what keeps the dependency one-way and avoids an import cycle. |
| `backend/src/lib/geoOverlapStore.test.ts` *(create)* | Unit tests for the above against a mocked pool. |
| `backend/src/lib/geoOverlapWarm.ts` *(create)* | `warmGeoOverlapPairs()` — importable by the loader, a migration post-verify, the job registry and boot. |
| `backend/src/lib/geoOverlapWarm.test.ts` *(create)* | Unit tests for the warm/sweep ordering. |
| `backend/src/lib/essentialsBrowseService.ts` *(modify, 161-254)* | Hoist the overlap SQL to a module constant, export its fingerprint, route `resolveOverlappingGeoPairs` through the store. The SQL text **stays in this file**. |
| `backend/src/lib/essentialsBrowseService.test.ts` *(modify)* | Its ordered `mockResolvedValueOnce` chains break the moment the resolver issues extra queries; re-based in Task 4. |
| `backend/src/lib/env.ts` *(modify)* | `GEO_OVERLAP_STORE_ENABLED`, `GEO_OVERLAP_WARM_ON_BOOT`. |
| `backend/src/jobs/registry.ts` *(modify)* | `geo-overlap-warm` entry. |
| `backend/src/index.ts` *(modify, ~349-352)* | Non-fatal post-listen warm, behind the flag. |
| `backend/scripts/load-state-tiger-boundaries.ts` *(modify, end of run)* | Call the warm module once the load finishes. 🔴 Hot file — merge `origin/master` first. |
| `backend/scripts/check-geo-overlap-store.mjs` *(create)* | The answer-does-not-change harness and its positive control. |
| `docs/JOB-API-SPLIT.md` *(modify)* | One row for the new job, matching that table's columns. |

---

### Task 1: The query becomes a hoisted constant with a fingerprint

The four things that change the answer and live in TypeScript — `UNRESOLVABLE_PAIR_MTFCCS`, branch 3's seven-MTFCC list, branch 2's `('G4110','G4120')` exclusion, and `MIN_OVERLAP_FRACTION` — are **all already interpolated into, or written literally inside, the resolver's SQL string**. Hashing the finished SQL therefore covers all four with no separately maintained list of hash inputs to fall out of step. That is the point of this task, and the first test is what pins it.

**Files:**
- Modify: `backend/src/lib/essentialsBrowseService.ts:161-254`
- Create: `backend/src/lib/geoOverlapStore.ts`
- Create: `backend/src/lib/geoOverlapStore.test.ts`

**Interfaces:**
- Produces: `fingerprintOf(sql: string): string` in `geoOverlapStore.ts` — lowercase hex, the first 16 characters of a SHA-256, via `node:crypto`.
- Produces: `OVERLAP_QUERY_SQL: string` and `OVERLAP_QUERY_FINGERPRINT: string`, both exported from `essentialsBrowseService.ts`. `OVERLAP_QUERY_SQL` is today's `intersectionQuery` template moved to module scope, byte-for-byte unchanged apart from leaving the function.

- [ ] **Step 1: Write the failing tests** in `backend/src/lib/geoOverlapStore.test.ts`

```ts
const squash = (s: string) => s.replace(/\s/g, '');

describe('OVERLAP_QUERY_FINGERPRINT', () => {
  it('hashes a text that contains all four answer-changing constants', () => {
    const sql = squash(OVERLAP_QUERY_SQL);
    expect(sql).toContain(squash(UNRESOLVABLE_PAIR_MTFCC_SQL_LIST));
    expect(sql).toContain('0.03');
    expect(sql).toContain(squash("'G4110', 'G4120'"));
    expect(sql).toContain(squash("'G5200', 'G5210', 'G5220', 'G4020', 'G5400', 'G5410', 'G5420'"));
  });

  it('changes when any one of them changes', () => {
    const base = fingerprintOf(OVERLAP_QUERY_SQL);
    expect(fingerprintOf(OVERLAP_QUERY_SQL.replace('0.03', '0.04'))).not.toBe(base);
    expect(fingerprintOf(OVERLAP_QUERY_SQL.replace("'G6350'", "'G6351'"))).not.toBe(base);
    expect(fingerprintOf(OVERLAP_QUERY_SQL.replace("'G4110'", "'G4115'"))).not.toBe(base);
  });

  it('is 16 lowercase hex characters', () => {
    expect(OVERLAP_QUERY_FINGERPRINT).toMatch(/^[0-9a-f]{16}$/);
  });
});
```

⚠ The exact spacing inside the two literal MTFCC lists is whatever `essentialsBrowseService.ts` has today — read it, do not retype it. `squash` exists so the assertion survives reformatting; a test that fails on a space is a test nobody keeps.

- [ ] **Step 2: Run them and watch them fail**

Run: `cd backend && npx vitest run src/lib/geoOverlapStore.test.ts`
Expected: FAIL — `geoOverlapStore.ts` does not exist.

- [ ] **Step 3: Create `geoOverlapStore.ts` with `fingerprintOf` only**

Nothing else goes in this file yet. Task 3 adds the database functions.

- [ ] **Step 4: Hoist the SQL in `essentialsBrowseService.ts`**

Move the `intersectionQuery` template literal out of `resolveOverlappingGeoPairs` to module scope as `export const OVERLAP_QUERY_SQL`, and add `export const OVERLAP_QUERY_FINGERPRINT = fingerprintOf(OVERLAP_QUERY_SQL);`. The function body now passes `OVERLAP_QUERY_SQL` to `pool.query`.

🔴 **Do not move the SQL to another file.** `browseResolution.test.ts:23-38` and `geoIdGuard.test.ts`'s `UNRESOLVABLE_PAIR_MTFCC_SQL_LIST` occurrence count both read `essentialsBrowseService.ts` **as text**. Moving the SQL leaves those source-pattern guards green while the property they guard is somewhere else — a guard that cannot see its subject.

- [ ] **Step 5: Run the new tests and the existing guards together**

Run: `cd backend && npx vitest run src/lib/geoOverlapStore.test.ts src/lib/browseResolution.test.ts src/lib/geoIdGuard.test.ts`
Expected: PASS, all three files.

- [ ] **Step 6: Commit**

```bash
git commit -F msg -- backend/src/lib/geoOverlapStore.ts backend/src/lib/geoOverlapStore.test.ts backend/src/lib/essentialsBrowseService.ts
```

---

### Task 2: `CC_0511` — the two tables, the trigger, and RLS

**Files:**
- Create: `backend/migrations/CC_0511_geo_overlap_pairs.sql`

**Interfaces:**
- Produces: `essentials.geo_overlap_pairs(seed_geo_id text not null, seed_mtfcc text not null, geofence_version bigint not null, query_fingerprint text not null, pairs jsonb not null, pair_count int not null, computed_at timestamptz not null default now())`, primary key `(seed_geo_id, seed_mtfcc, geofence_version, query_fingerprint)`.
- Produces: `essentials.geofence_version(version bigint not null, last_bump_txid bigint, bumped_at timestamptz)` — exactly one row, seeded `version = 1`, with a constraint that keeps it at one row.
- Produces: `essentials.bump_geofence_version()` and three statement triggers on `essentials.geofence_boundaries`.

- [ ] **Step 1: Write the migration file**

One transaction, additive, idempotent. Model it on `backend/migrations/CC_0468_compass_user_lens_history.sql` — read that file first for the house idioms: `CREATE OR REPLACE TRIGGER` (Postgres 14+, so no `DROP` window), `SECURITY DEFINER` with `SET search_path TO ''` and every reference schema-qualified, the no-hand-written-`GRANT` rule, and the verification block that checks the schema default actually fired.

The header must carry, in the file itself: the design and plan paths, why `pairs` is `jsonb` rather than a row per pair (consumers want the whole list, the lists are 852–4,918 for a state, and one row per seed makes the version predicate a primary-key lookup instead of a filtered scan), and both corrections below with the measurement behind each.

The trigger function body, which the signature does not determine:

```sql
CREATE OR REPLACE FUNCTION essentials.bump_geofence_version()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $function$
DECLARE v_changed boolean;
BEGIN
  -- 1. A statement that changed nothing must bump nothing. A Postgres statement
  --    trigger fires regardless of how many rows the statement touched, so
  --    without this a re-run of a loader that ON CONFLICT DO NOTHINGs on every
  --    row -- a no-op -- would discard every stored answer, the 53 warm states
  --    included, for no geometry change at all.
  IF TG_OP = 'DELETE' THEN
    SELECT EXISTS (SELECT 1 FROM removed) INTO v_changed;
  ELSE
    SELECT EXISTS (SELECT 1 FROM changed) INTO v_changed;
  END IF;
  IF NOT v_changed THEN RETURN NULL; END IF;

  -- 2. At most one bump per transaction.
  UPDATE essentials.geofence_version
     SET version = version + 1, last_bump_txid = txid_current(), bumped_at = now()
   WHERE last_bump_txid IS DISTINCT FROM txid_current();
  RETURN NULL;
END;
$function$;
```

Three triggers, each `FOR EACH STATEMENT`: `AFTER INSERT … REFERENCING NEW TABLE AS changed`, `AFTER UPDATE … REFERENCING NEW TABLE AS changed`, `AFTER DELETE … REFERENCING OLD TABLE AS removed`.

🔴🔴 **Record this in the header, because it is measured and it contradicts the obvious reading of "statement-level".** `backend/scripts/load-state-tiger-boundaries.ts:1330` and `backend/scripts/1642-import-core.mts:145` insert **one row per statement** (`INSERT … VALUES ($1…) ON CONFLICT (geo_id, mtfcc) DO NOTHING`), and **neither script opens a transaction** — verified on this branch 2026-11-24, zero `BEGIN` in either file. So the txid guard cannot coalesce a TIGER load: the version moves once per *changed* row. That is still correct — a reader at a superseded version misses and recomputes — and the transition-table guard still kills the dangerous case, which is the no-op re-run. Step 5 measures what it costs. **The remedy if it is too dear is to wrap the loader's row loop in a transaction, not to add a bypass the loader must remember to use** — a bypass is the "two mechanisms kept in sync by hand" the design rejects.

⚠ `imported_at` was considered as the version and rejected: 389 rows carry NULL, it holds 1,580 distinct values, so it is a per-row ingest stamp rather than a global one, and `max(imported_at)` cannot see a DELETE at all.

RLS: `ENABLE ROW LEVEL SECURITY` on **both** tables in this same file, then the policies the design names — SELECT for `anon` and `authenticated`, read and write for `ev_api`. Without those lines the tables are `anon`-readable the moment they exist and nothing errors.

⚠ **One deviation is available to the reviewer and is not taken here.** The house precedent (`CC_0468`) is RLS-on with *no* policies, because the backend reads through its own pool as `ev_api`, which bypasses RLS — so the `anon` policy admits a read nothing in this product performs. The design chose to admit `anon` explicitly, on the grounds that this is derived public geography; this file does that. It is one `DROP POLICY` to reverse. Either way, do not write a `GRANT` by hand: that would work and would also hide a broken schema default, so the verification block checks the default fired instead.

- [ ] **Step 2: Dry-run it**

Run: `node backend/scripts/dry-run-migration.mjs backend/migrations/CC_0511_geo_overlap_pairs.sql`
Expected: `DRY RUN OK`.
⚠ **An empty or truncated file also reports `DRY RUN OK`** — an empty migration passes every gate it does not contain. Before believing it: `grep -c "bump_geofence_version" backend/migrations/CC_0511_geo_overlap_pairs.sql` must print 3 or more.

- [ ] **Step 3: Apply it through the owner connection**

Apply via the Supabase MCP (`apply_migration`). `ev_api` cannot run DDL. This is production.

- [ ] **Step 4: Post-verify the trigger, in a rolled-back transaction**

Inside `BEGIN; … ROLLBACK;` against production, using a throwaway `geo_id` that collides with nothing:
- read `version`; INSERT one geofence row; read again → moved by **exactly 1**;
- UPDATE that row's `name`; read again → moved by **1**;
- DELETE it; read again → moved by **1**;
- one statement inserting **5 rows** → version moves by **exactly 1**, not 5;
- a statement that changes **zero** rows (an `INSERT … ON CONFLICT DO NOTHING` where every row conflicts, and an `UPDATE … WHERE false`) → version **does not move**.

🔴 **Print the version after every step, not just the verdict.** A predicate of several conditions fails for exactly one reason and nothing prints it; a step that passes silently leaves the verdict readable while the evidence for it is not.

- [ ] **Step 5: Measure the trigger's cost on a bulk-load shape**

In a rolled-back transaction, time 5,000 single-row inserts into `essentials.geofence_boundaries` with the triggers live, and the same 5,000 with the triggers disabled, so the overhead is a difference and not an absolute. **Budget: under 90 seconds of added time extrapolated to 70,000 rows** — one state's TIGER load. Record the per-row overhead and the extrapolation in the migration header. If it blows the budget, stop and raise it: the remedy is a transaction around the loader's row loop, which is a change to the repo's hottest file and deserves its own decision.

- [ ] **Step 6: Confirm the RLS state the schema's defaults produced**

Read `pg_class.relrowsecurity` and `information_schema.role_table_grants` for both new tables and print both. Expected: RLS **on** for both, and `ev_api` holding `arwd` **with no GRANT statement in the file**. Then run `npm run check:rls-coverage --prefix backend` — it is the live tripwire for exactly this drift and must stay green.

- [ ] **Step 7: Commit**

```bash
git commit -F msg -- backend/migrations/CC_0511_geo_overlap_pairs.sql
```

---

### Task 3: The store module

**Files:**
- Modify: `backend/src/lib/geoOverlapStore.ts`
- Modify: `backend/src/lib/geoOverlapStore.test.ts`
- Modify: `backend/src/lib/env.ts`

**Interfaces:**
- Consumes: `fingerprintOf` (Task 1), `pool` from `./db.js`, `GeoPair` from `./geoIdGuard.js`, the tables from Task 2.
- Produces, all exported from `geoOverlapStore.ts`:
  - `seedKey(p: GeoPair): string` — `` `${p.geo_id}::${p.mtfcc}` ``. Every `Map` in this feature keys on it.
  - `readGeofenceVersion(): Promise<string | null>` — the bigint **as a string**. `node-postgres` returns bigint as text; keep it text end to end and never parse it to a `number`. `null` when the row or the table is absent, or the query throws.
  - `readStoredPairs(seeds: GeoPair[], version: string, fingerprint: string): Promise<Map<string, GeoPair[]>>` — only seeds that hit. A miss is an **absent key**, which is not the same as an empty array; a seed can legitimately have zero pairs.
  - `writeStoredPairs(entries: Array<{ seed: GeoPair; pairs: GeoPair[] }>, version: string, fingerprint: string): Promise<void>` — one `INSERT … ON CONFLICT (seed_geo_id, seed_mtfcc, geofence_version, query_fingerprint) DO UPDATE`, setting `pairs`, `pair_count` and `computed_at`.
  - `filterSeedsPresent(seeds: GeoPair[]): Promise<GeoPair[]>` — the subset that exists in `essentials.geofence_boundaries`, looked up by primary key.
  - `sweepSupersededPairs(version: string, fingerprint: string): Promise<number>` — deletes every row at another version **or** another fingerprint; returns the row count.
  - `OVERLAP_STORE_ENABLED: boolean` — false only when `GEO_OVERLAP_STORE_ENABLED` is `0` or `false`.

- [ ] **Step 1: Write the failing tests**, mocking `./db.js` the way `essentialsBrowseService.test.ts:9` does

```ts
it('readGeofenceVersion returns the bigint as a string, never a number')      // '9007199254740993' survives intact
it('readGeofenceVersion returns null when the query throws')                  // Review Focus 1
it('readStoredPairs omits a seed that missed and keeps one that returned []') // absent key ≠ empty array
it('readStoredPairs binds BOTH the version and the fingerprint')
it('writeStoredPairs is idempotent for the same key')                         // Review Focus 3
it('writeStoredPairs writes pair_count equal to pairs.length')
it('writeStoredPairs issues no query for an empty entries array')
it('filterSeedsPresent returns only the seeds the query matched')
it('sweepSupersededPairs deletes on a version OR a fingerprint mismatch')
it('OVERLAP_STORE_ENABLED is false for "0" and "false", true otherwise')
```

⚠ **A mocked pool cannot see the SQL, so guard the TEXT** wherever the property lives in SQL rather than in TypeScript: assert the captured query string contains `ON CONFLICT` and `DO UPDATE`, and that the sweep's `WHERE` names both `geofence_version` and `query_fingerprint`. Asserting only on the mock's return value tests the mock.

- [ ] **Step 2: Run them and watch them fail**

Run: `cd backend && npx vitest run src/lib/geoOverlapStore.test.ts`
Expected: FAIL — each new export is undefined.

- [ ] **Step 3: Implement the seven new exports** (`fingerprintOf` already exists from Task 1)

- [ ] **Step 4: Run the tests**

Run: `cd backend && npx vitest run src/lib/geoOverlapStore.test.ts`
Expected: PASS.

- [ ] **Step 5: Add the two env flags**

In `backend/src/lib/env.ts`: `GEO_OVERLAP_STORE_ENABLED: z.string().optional()` and `GEO_OVERLAP_WARM_ON_BOOT: z.string().optional()`, each with a comment in the house style saying what **absent** means — store on, boot warm off. The kill switch exists because the design's named failure mode is a wrong answer nobody can see: the operator needs a way to stop reading the store without a migration and without taking the service down. Both names go into the `ev-infra` record with `sync: false` (Task 7), not set here.

- [ ] **Step 6: Commit**

```bash
git commit -F msg -- backend/src/lib/geoOverlapStore.ts backend/src/lib/geoOverlapStore.test.ts backend/src/lib/env.ts
```

---

### Task 4: The read path

**Files:**
- Modify: `backend/src/lib/essentialsBrowseService.ts:161-254`
- Modify: `backend/src/lib/essentialsBrowseService.test.ts`

**Interfaces:**
- Consumes: everything Task 3 produces, plus `OVERLAP_QUERY_SQL` and `OVERLAP_QUERY_FINGERPRINT` from Task 1.
- Produces: `resolveOverlappingGeoPairs(seeds: GeoPair[]): Promise<GeoPair[]>` — signature unchanged. Every caller is untouched.

The order inside the function, which is load-bearing:

1. `version = await readGeofenceVersion()`. **Read it first.** Everything downstream is tagged with this value.
2. Redis: key `` `overlap:v3:${version ?? 'none'}:${OVERLAP_QUERY_FINGERPRINT}:${sortedSeeds}` ``. A hit is returned only if it is an array of `{geo_id, mtfcc}`; anything else is a miss.
3. If `version` is null, or `OVERLAP_STORE_ENABLED` is false → compute, write Redis, return. No store read, no store write.
4. `readStoredPairs(seeds, version, OVERLAP_QUERY_FINGERPRINT)`. Seeds that hit contribute their stored pairs.
5. Missing seeds → run `OVERLAP_QUERY_SQL`, **once per missing seed**.
6. `filterSeedsPresent(missing)` → upsert one row per surviving seed, carrying that seed's own pairs, **at the version read in step 1**.
7. Return the deduplicated union of stored and computed pairs; write Redis.

🔴 **Step 6 writes the step-1 version, never a freshly read one.** If an ingest lands mid-compute the version has already moved, so the row is born superseded — unreadable, which is the safe direction. Writing the *current* version would publish an answer computed against half-ingested geometry at a version readers trust.

🔴 **Step 5 computes per missing seed** so each row holds that seed's own pairs. The design's measurement (§1) is that single-seed results **compose by union**; it is not that a multi-seed result can be split apart afterwards.

⚠ **The Redis key changes shape, and that is deliberate.** Step 1's `overlap:v2` prohibition came from a case where the result was *provably identical*, so bumping would have thrown warm entries away for nothing. Here the opposite holds: when the version or the fingerprint moves, the answer genuinely is different. Carrying that rule across is how the anti-goal gets in.

- [ ] **Step 1: Write the failing tests** in `backend/src/lib/essentialsBrowseService.test.ts`

```ts
it('returns stored pairs without running the intersection query on a full hit')
it('computes only the seeds that missed, and unions the two')
it('stores the version read before the compute, not after')        // Review Focus 4: version reads '7' then '9'; the upsert binds '7'
it('does not store a seed that is not in geofence_boundaries')     // Review Focus 2: filterSeedsPresent returns [] → no INSERT issued
it('falls back to computing when the version row cannot be read')  // Review Focus 1: one compute, no store query, no throw
it('does not read or write the store when GEO_OVERLAP_STORE_ENABLED=0')
it('ignores a cached value that is not an array of pairs')         // Review Focus 5: cache.get resolves {"old":"shape"} → recompute
it('puts the version and the fingerprint in the Redis key')
```

⚠ **The existing tests in this file will break, and that is expected, not a regression.** `getCongressionalOverlapNote`'s cases drive `pool.query` with ordered `mockResolvedValueOnce` chains (`essentialsBrowseService.test.ts:29-60` and following), and the resolver now issues a version read and a store read before the intersection query. **Re-base each chain to the new call order rather than loosening the mocks into order-independence** — the order is exactly what step 1 of the sequence above pins, and a mock that stops caring stops testing it.

- [ ] **Step 2: Run them and watch them fail**

Run: `cd backend && npx vitest run src/lib/essentialsBrowseService.test.ts`
Expected: FAIL — the new tests fail outright and the existing chains fail on call-order drift.

- [ ] **Step 3: Implement the seven-step order in `resolveOverlappingGeoPairs`**

Re-comment `OVERLAP_CACHE_TTL_SECONDS` where it is declared (`essentialsBrowseService.ts:27`): it is now a **memory bound only**, because correctness has moved into the key. Leave the value at 3600, and say in the comment that the TTL no longer carries correctness so nobody re-derives the old reasoning from the old number.

- [ ] **Step 4: Run the whole browse suite**

Run: `cd backend && npx vitest run src/lib/essentialsBrowseService.test.ts src/lib/browseResolution.test.ts src/lib/geoIdGuard.test.ts src/lib/geoOverlapStore.test.ts`
Expected: PASS.

- [ ] **Step 5: Typecheck**

Run: `cd backend && npm run typecheck`
Expected: exit 0.

- [ ] **Step 6: Commit**

```bash
git commit -F msg -- backend/src/lib/essentialsBrowseService.ts backend/src/lib/essentialsBrowseService.test.ts
```

---

### Task 5: The warming job

**Files:**
- Create: `backend/src/lib/geoOverlapWarm.ts`
- Create: `backend/src/lib/geoOverlapWarm.test.ts`
- Modify: `backend/src/jobs/registry.ts`
- Modify: `backend/src/index.ts` (after `app.listen`, ~349-352)
- Modify: `backend/scripts/load-state-tiger-boundaries.ts`

**Interfaces:**
- Consumes: Task 3's store functions and Task 4's `resolveOverlappingGeoPairs`.
- Produces: `warmGeoOverlapPairs(opts?: { seedMtfcc?: string; dryRun?: boolean }): Promise<{ version: string | null; fingerprint: string; computed: number; alreadyCurrent: number; swept: number }>`. `seedMtfcc` defaults to `'G4000'`.
- Produces: the job name `geo-overlap-warm` in `JOBS` (`backend/src/jobs/registry.ts`).

What it does: read the version; list the seeds of `seedMtfcc`; skip those already stored at this `(version, fingerprint)`; compute and store the rest; **then** sweep superseded rows; log one line carrying all five numbers.

🔴 **Sweep last.** Sweeping first leaves a window with no warm state at all — the 7-second case this work exists to remove, manufactured by the job that exists to prevent it.

🟢 **It must be a near no-op when everything is current**, because `GEO_OVERLAP_WARM_ON_BOOT` means every API instance runs it on every deploy. A rare, bounded, correct stampede is the trade the design accepts; an unbounded one on every restart is not.

- [ ] **Step 1: Write the failing tests** in `backend/src/lib/geoOverlapWarm.test.ts`

```ts
it('computes nothing and still sweeps when every seed is already stored at this version')  // computed === 0
it('sweeps AFTER the last store write')                      // assert call order on the mocked pool
it('returns version:null and computes nothing when the version cannot be read')
it('warms G4000 by default')                                 // the seed-listing query binds 'G4000'
it('dryRun computes and reports but issues no write or delete')
```

- [ ] **Step 2: Run them and watch them fail**

Run: `cd backend && npx vitest run src/lib/geoOverlapWarm.test.ts`
Expected: FAIL — module not found.

- [ ] **Step 3: `EXPLAIN` the seed listing before implementing it**

`essentials.geofence_boundaries`' key is `(geo_id, mtfcc)`, so `WHERE mtfcc = 'G4000'` does not lead the index. Run `EXPLAIN` (**never `ANALYZE`**) on `SELECT geo_id, mtfcc FROM essentials.geofence_boundaries WHERE mtfcc = 'G4000'` against production and record the plan and its estimated cost in the module's header comment. Select `geo_id, mtfcc` only — never `geometry`, which would detoast every polygon in the table.

- [ ] **Step 4: Implement `warmGeoOverlapPairs`**

- [ ] **Step 5: Run the tests**

Run: `cd backend && npx vitest run src/lib/geoOverlapWarm.test.ts`
Expected: PASS.

- [ ] **Step 6: Wire the three callers**

- `backend/src/jobs/registry.ts` — `'geo-overlap-warm': () => warmGeoOverlapPairs(),` with a comment in the style of its neighbours: what it does, why it exists, and what proof-of-run looks like in the logs.
- `backend/src/index.ts` — immediately after `app.listen`'s callback and **outside** the `role === 'api'` branch so both roles get it, guarded by `GEO_OVERLAP_WARM_ON_BOOT`: `void warmGeoOverlapPairs().catch((e) => console.warn('[startup] geo-overlap warm failed — continuing anyway:', e));`. 🔴 Fire-and-forget and non-fatal, exactly like the `reapStaleIngestionRuns` call beside it. Four deploys have gone out green and failed to start; a warm-up must not be the fifth.
- `backend/scripts/load-state-tiger-boundaries.ts` — call it once after the load finishes, logging its counts. This is what gives "runs after a boundary ingest" a mechanism: neither a migration nor a loader script can invoke a Render cron job, so without this the 53 states would sit cold for up to a whole schedule interval.

⚠ **The design also names "a migration's post-verify" as a caller. Nothing to wire here, deliberately.** `CC_0511` creates the tables before the read path exists, so it has no module to call. The obligation lands on the *next* migration that ingests boundaries; record it as one line in `backend/migrations/CLAUDE.md` so the next author finds it, rather than as dead code here.

🔴 **Merge `origin/master` into this branch, in this worktree, before touching the loader.** It is the repo's hottest file — every state's geography load edits it — and a conflicting branch does not get better by waiting: PR #797 sat 64 commits behind with two conflicting files for two days and nothing said so. ▶ **Run the tests after a merge git calls clean.** A duplicated import or `vi.mock` is not a text conflict, so neither the merge nor the drift report can see it, and the later copy silently wins.

- [ ] **Step 7: Prove the server still boots**

Run: `cd backend && npm run build && DATABASE_URL=postgresql://nobody@127.0.0.1:1/nope GEO_OVERLAP_WARM_ON_BOOT=1 node dist/index.js`
Expected: the process reaches `[server] listening on port …` and logs the warm failure as a warning. Green CI is not "the server boots" — boot the built artifact against a dead `DATABASE_URL` and watch it come up.

- [ ] **Step 8: Commit**

```bash
git commit -F msg -- backend/src/lib/geoOverlapWarm.ts backend/src/lib/geoOverlapWarm.test.ts backend/src/jobs/registry.ts backend/src/index.ts backend/scripts/load-state-tiger-boundaries.ts
```

---

### Task 6: The answer does not change — harness and positive control

**Files:**
- Create: `backend/scripts/check-geo-overlap-store.mjs`
- Modify: `backend/package.json` — `check:geo-overlap-store` and `check:geo-overlap-store:selftest`

**Interfaces:**
- Consumes: both tables, the read path from Task 4, and `MTFCC_DISTRICT_TYPE_GUARD` **extracted from `geoIdGuard.ts` as text, never retyped**.

**The sample is named explicitly: one real seed from each of `G4000`, `G4020`, `G4110`, `G4040`, `G5200`, `X0001`**, plus California's `G4000` row (the 12,103-vertex case) and Texas's (the 254-county case). "All five seedable layers" is ambiguous, and the nearest constant — `AREA_SEED_MTFCCS` at `essentialsBrowseService.ts:139` — contains **neither `G4000`**, the seeds this work warms, **nor `G5200`**, which `getPoliticiansByArea` passes on the split-district path. A sample taken from that constant would have missed both seeds the work is about.

For each seed the script compares, between the store-backed path and a direct compute:
- the pair set, and
- the set of `essentials.districts` rows surviving `MTFCC_DISTRICT_TYPE_GUARD`.

- [ ] **Step 1: Write the script, printing every seed it scanned**

🔴 **Print each seed's counts whether it passed or failed, and the total number of seeds examined.** A passing row that produces no numbers leaves the verdict readable while the evidence for it is not, and costs a re-implementation the next time somebody asks why it passed.
🔴 **Print any district label at full width.** Never `.slice()` a label into a report column: `"Congressional District "` is exactly 23 characters, and truncation manufactures findings shaped precisely like duplicates. Read the stable key — `ocd_id` — beside it.

- [ ] **Step 2: Write the positive control as `--selftest`, and watch it go red before trusting it**

Inside `BEGIN; … ROLLBACK;`: corrupt one stored `pairs` row — remove a single element — then run the comparison and require it to report **red**, naming that seed.

🔴 **Assert the tamper is PRESENT before believing the red.** Re-read the row and confirm `pair_count` no longer equals `jsonb_array_length(pairs)`. A tamper that did not apply is a control that proved nothing, and it looks exactly like a pass.
⚠ **A control proves the verifier CAN fail; it does not prove it read the right rows.** The selftest must also print how many seeds and how many district rows the comparison examined, and must exit non-zero if either count is zero. Step 1's control took three attempts — dropping `G4020` changed nothing because branch 3 backfills it, and `G4040` changed nothing because California's county subdivisions match no district at all.

- [ ] **Step 3: Run the selftest**

Run: `npm run check:geo-overlap-store:selftest --prefix backend`
Expected: tamper confirmed present → comparison RED on exactly the tampered seed → transaction rolled back → exit 0, meaning "the detector works".

- [ ] **Step 4: Run the real check against production**

Run: `npm run check:geo-overlap-store --prefix backend`
Expected: every seed identical, with the per-seed counts printed. Paste the output into the PR body.

- [ ] **Step 5: Prove staleness is unreachable**

In a rolled-back transaction: store a seed's pairs, bump `geofence_version` by touching a geofence row, then read that seed again and assert it **recomputed** rather than serving the stored row. This is the design's named anti-goal, so it gets its own test rather than riding along inside another one.

- [ ] **Step 6: Assert composition once more, over the real multi-seed input**

Take an actual `getOverlappingGeoIdsForGovernments` seed set of **more than two seeds drawn from more than one layer**, and assert the union of the per-seed stored results equals the single multi-seed computed result. The design measured two-seed cases, including a nested one, and left this open. Carry a positive control: a union with one row removed must read as different — and watch for the pipeline hazard that bit the design's own first run, where files without a trailing newline welded two ids into one.

- [ ] **Step 7: Commit**

```bash
git commit -F msg -- backend/scripts/check-geo-overlap-store.mjs backend/package.json
```

---

### Task 7: Measure it, and hand off the parts that live elsewhere

**Files:**
- Modify: `docs/JOB-API-SPLIT.md`
- Modify: `docs/superpowers/specs/2026-11-24-geo-overlap-precompute-design.md` — § "Open, and left to the builder" gets the answers this work produced.

- [ ] **Step 1: Warm the 53 states against production**

Run: `cd backend && npx tsx -e "import('./src/lib/geoOverlapWarm.js').then(m => m.warmGeoOverlapPairs()).then(r => console.log(r))"`
Expected: `computed: 53` on the first run, `computed: 0` on an immediate second run. Record both wall-clock times.
⚠ **A green run can be a no-op.** Read what it says it did, not just its exit code — that is why the second run's `computed: 0` is part of the expectation rather than a nicety.

- [ ] **Step 2: Re-time the two endpoints the Civic Spaces report named, at equal cache warmth**

⚠ **At equal warmth on both sides.** Step 1's first reading was 33× and wrong, because it compared a trimmed warm run against an untrimmed cold one. Report cold-vs-cold and warm-vs-warm as separate numbers.
🔴 **State the California figure plainly: it stays ≈3.3 s on a miss even after this work**, because branch 3 runs `ST_Intersection` against a 12,103-vertex outline and is CPU-bound. What this work removes is the miss, not the cost of a miss. A report that implies otherwise will be read as a regression the first time somebody sees a cold California.

- [ ] **Step 3: Check what the new queries cost the database**

Read `extensions.pg_stat_statements` for them (`shared_blks_read`, `temp_blks_written`), as the house rule requires after adding anything that reads the database. Record the numbers in the PR body.

- [ ] **Step 4: Add the job's row to `docs/JOB-API-SPLIT.md`**

Match the existing table's columns — trigger, schedule, weight, proof-of-run. Weight: light (53 seeds, a no-op when current; reads no big table).

- [ ] **Step 5: Answer the design's open questions in the design file**

- Whether ZIP (`G6350`) browse reaches this resolver — check, and record the answer either way.
- Sweep policy for superseded rows — record the row count the first sweep actually deleted, so "negligible" is a measurement rather than an expectation.
- The loader's transaction shape (Task 2) and the measured trigger overhead (Task 2 step 5).

- [ ] **Step 6: Write the `ev-infra` handoff into the PR body**

🔴 **Render settings are not in this repo.** The PR body must state, for `EmpoweredVote/ev-infra`'s `render.yaml`:
- a new cron service running `node dist/jobs/run.js geo-overlap-warm` — the schedule is the operator's call, hourly or daily;
- `GEO_OVERLAP_STORE_ENABLED` and `GEO_OVERLAP_WARM_ON_BOOT` added by **name only**, with `sync: false`; values are set in the Render dashboard.

A schedule added in this repo would never run, and a setting changed in the Render dashboard is undone on the next sync.

- [ ] **Step 7: Full suite, then commit**

Run: `cd backend && npm test`
⚠ **This worktree has no `.env`, so about 13 integration files skip and the suite looks cleaner than it is.** The real pre-existing count is **33 failures across 13 files**, not 6. Diff the failing **file list** against the base commit, never the count.

```bash
git commit -F msg -- docs/JOB-API-SPLIT.md docs/superpowers/specs/2026-11-24-geo-overlap-precompute-design.md
```
