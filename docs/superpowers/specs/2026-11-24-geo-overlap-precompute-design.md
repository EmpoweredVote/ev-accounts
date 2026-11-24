# Geo-overlap pairs: a durable, version-invalidated store

**Date:** 2026-11-24
**Status:** design, awaiting approval
**Origin:** Civic Spaces report *"Geo-overlap cache expires hourly on static geometry"*
**Step 1 (merged):** PR #1605, squashed `371e79c895` — branch 1's missing MTFCC filter.

---

## Intent, and the why

`resolveOverlappingGeoPairs` (`backend/src/lib/essentialsBrowseService.ts`) answers "which
district polygons overlap this area". Its answer is a **pure function of
`essentials.geofence_boundaries` geometry**, which changes a handful of times a year when a
migration ingests boundaries. It is cached in Redis under `overlap:v2:${seeds…}` with
`OVERLAP_CACHE_TTL_SECONDS = 3600`.

Nothing warms that key and nothing invalidates it. **The one-hour expiry is therefore the only
thing that ever refreshes it**, which means the TTL is doing two jobs at once — cache lifetime
*and* correctness — and the cache throws away, every hour, an answer that can only ever be
recomputed to the same value.

At current traffic a one-hour TTL almost never helps a real person. In a 39-hour window of
production logs, only 9 of the 100 most recent calls to this path came from a real browser; the
rest were CI and diagnostics keeping keys warm for themselves. **Real arrivals are sparse and
land on cold keys.** A Civic Spaces member's app boot measured **7,199 ms** on this one call.

This matters to Civic Spaces specifically because it asks for **state** areas by design: the
State tab asks directly, and `electionAreaFor` falls back to the member's state for the Federal,
Unified and Volunteer tabs. There is no client-side mitigation — the expensive shape is the one
the product needs.

## Goals

1. An area is computed **once per boundary version**, not once an hour.
2. Invalidation becomes an **event**, not a timer — so the TTL stops carrying correctness.
3. The 7-second case (state seeds) is warm before a member ever asks.
4. The answer does not change. Not by a row, for any seed.

## Non-goals

- Precomputing all ~30,000 possible seeds. Nothing measured says the 29,947 non-state seeds need
  it; counties run 0.5–1.4 s and cities about 0.5 s.
- Making branch 3 itself cheaper. Simplifying or subdividing the geometry changes what the
  predicate means, and the original report is explicit that this query was already tuned once
  and deserves a profile rather than a guess.
- Touching the address (point-in-polygon) path. That is `ST_Covers` and is unaffected.

## Anti-goals — what would make this a failure even if it worked

- 🔴 **A stale answer that nobody can see.** Today's failure is slow. The failure this design
  risks is *wrong*: a boundary ingest lands, the stored pairs do not refresh, and a voter is
  shown a district that no longer contains them. **Silent staleness is worse than the 7 seconds
  we are fixing**, so invalidation must not depend on anyone remembering to do it.
- 🔴 **Two mechanisms that must be kept in sync by hand.** That was the report's own objection
  to its fix 2, and it stands.
- A deploy that stampedes the cold path it exists to shrink.

## Constraints

- **`essentials` RLS is the only belt.** `ALTER DEFAULT PRIVILEGES` there already grants `anon`
  and `authenticated` SELECT and `ev_api` `arwd` on every new table *before any migration says a
  word*. A new table is readable by `anon` from the moment it exists unless the same file enables
  RLS and adds policies, and nothing errors if it does not (CLAUDE.md; measured on prod by
  `CC_0457`).
- Production authenticates as **`ev_api`**, which is not the table owner, so policies must admit
  it for both read and write.
- `ev_api` cannot run DDL. The table, trigger and policies go through the owner connection
  (the Supabase MCP), as `CC_0472` did.
- Redis is Upstash over HTTP (`@upstash/redis`), reached through `backend/src/lib/cache.ts`.
- One migration per file; the slot is **allocated** by the steward, never counted.

## Approaches considered

| | What it is | Trade-off |
|---|---|---|
| **A — materialize every seed** | The report's fix 1. A row per (seed, pair) for all ~30,000 seeds. | Tidiest end state: reads are an index lookup and the cold path disappears everywhere. But the build is ~30,000 runs of a 0.5–7 s query — about eight hours — and it re-runs on **every** boundary ingest, to precompute millions of pairs for areas nobody browses. |
| **B — materialize the 53 states only** | Keep Redis for everything else. | Three minutes to build and it covers the measured pain. But two mechanisms stay in play and the TTL keeps carrying correctness for 29,947 other seeds. |
| **C — durable store, version-invalidated** ⬅ **chosen** | Same shape as today's cache, but the answer survives and invalidation is a geometry version rather than a clock. Warm the 53 states so first-ask is never the 7-second case. | Fixes the actual defect — a timer standing in for invalidation — with no multi-hour build. The cold path still exists the first time an area is asked for at a new boundary version, which the state warm-up covers where it hurts. |
| D — attack branch 3's geometry | Subdivide the state outlines so `ST_Intersects` stops testing a 12,103-vertex polygon. | Dropped: changes what the predicate means, on a query already tuned once. |

**Chosen: C**, picked by the operator 2026-11-24.

## What step 1 already measured, and what it leaves for this

Per branch, against production, with state seeds:

| branch | California | Texas |
|---|---|---|
| 1 — point-in-area *(fixed in #1605)* | 2,595 ms | 3,433 ms |
| 2 — containing districts | 10 ms | — |
| 3 — interior overlap, `ST_Intersection` | **2,930 ms** | 1,001 ms |

🔴 **The number that shapes this design: California stays ≈3.3 s even fully warm, under both the
old and the new shape.** Its branch 3 runs `ST_Intersection` against a **12,103-vertex** state
outline and is **CPU-bound**; step 1's filter cannot reach it. Smaller states fall to ≈0.6 s warm.
So the residual cost is branch 3 on large-perimeter states — exactly the 53 seeds this design
warms.

⚠ **Cold cost does not track seed vertex count.** Texas has fewer vertices than Maryland (1,826
against 2,848) and takes twice as long, because it has 254 counties. It tracks the **candidate
population inside the state**. That is why the warm set is "all 53 states" rather than "the
geometrically complex ones".

## The design

### 1. The store

```
essentials.geo_overlap_pairs
  seed_geo_id        text        not null
  seed_mtfcc         text        not null
  geofence_version   bigint      not null
  pairs              jsonb       not null   -- [{geo_id, mtfcc}, …], the resolver's own shape
  pair_count         int         not null   -- denormalised for cheap assertions and gates
  computed_at        timestamptz not null default now()
  primary key (seed_geo_id, seed_mtfcc, geofence_version)
```

**Keyed on a single seed, deliberately.** The resolver unnests its seeds and unions per seed, so
a multi-seed result is exactly the union of the single-seed results. A per-seed row therefore
composes for the multi-seed caller (`getOverlappingGeoIdsForGovernments`) and gives far better
reuse than today's key, which is the **sorted seed set** and so misses whenever the set differs
by one member.

✅ **MEASURED AGAINST PRODUCTION 2026-11-24, after this document was first written.** It was
recorded here as read-off-the-SQL-but-untested and is now tested, in both shapes that could break
it:

| seeds | single-seed results | two-seed call | verdict |
|---|---|---|---|
| CT `09`/G4000 + RI `44`/G4000 — **disjoint neighbours** | 14 + 7 | 21 | 🟢 equal |
| CT `09`/G4000 + `09190`/G4020 — **one seed NESTED in the other's own result set** | 14 + 2 | 14 | 🟢 equal |

The nested pair is the one that matters: `09190` is a member of `09`'s result, so if a seed's
presence in another seed's output changed anything, it would change here. It does not.
⚠ **The first run of this test reported 🔴 DOES NOT COMPOSE and that was my own pipeline** — the
id files had no trailing newline, so `cat` welded two entries into `09190|G402044001|G4020`. The
re-run carries a positive control (a union with one row removed must read as different), which
passed before the verdict was believed. ▶ *Before reporting a mismatch between two readings, ask
what your own pipeline does to the field.*

⚠ Still untested: a seed set of more than two, and seeds drawn from different layers at scale.
Neither is likely to behave differently given the UNION's structure, but the plan should assert
composition once more over the real `getOverlappingGeoIdsForGovernments` input.

`pairs` is `jsonb` rather than a row per pair: the resolver's consumers want the whole list at
once, the lists are small (852–4,918 for a state), and one row per seed makes the version
predicate a primary-key lookup instead of a filtered scan.

### 2. The version, maintained by the database

```
essentials.geofence_version  — one row, one bigint
```

bumped by an `AFTER INSERT OR UPDATE OR DELETE … FOR EACH STATEMENT` trigger on
`essentials.geofence_boundaries`, **with transition tables and a once-per-transaction guard**.

🔴 **A trigger rather than a convention is the whole point.** The report's fix 2 was rejected
because "two things must stay in sync, and a missed bust is a silent correctness bug rather than
a slow page". A trigger removes the thing that could be missed: a migration cannot ingest
boundaries *and* forget to invalidate, because the database does it.

🔴🔴 **CORRECTED AFTER THE BUILDER CHECK — "statement-level, so a bulk ingest bumps once" WAS
FALSE, AND IT WAS FALSE IN THE DIRECTION THAT HURTS.** Verified in this repo:
`backend/scripts/load-state-tiger-boundaries.ts` inserts **one row per statement** — a single
`INSERT … VALUES ($1…)` per polygon, with `ON CONFLICT (geo_id, mtfcc) DO NOTHING`. So a naive
statement-level trigger would:

- fire **70,000 times** for one ingest, each taking the same row lock on a one-row table —
  serialising the load and bloating that table; and
- fire on statements that changed **zero** rows, because a Postgres statement trigger fires
  regardless. **Re-running a loader that conflicts on everything — a no-op — would discard every
  stored answer, the 53 warm states included, for no geometry change at all.**

▶ **The trigger therefore bumps only on real change, and at most once per transaction:**

- `REFERENCING NEW TABLE AS changed` (and `OLD TABLE` on delete), and the function returns early
  unless the transition table has a row. That kills the zero-row case.
- The version row carries `last_bump_txid bigint`; the function returns early when it already
  equals `txid_current()`. A 70,000-statement transaction bumps **once**.

⚠ This makes the trigger's correctness depend on ingests running **inside a transaction**. If a
loader autocommits per row, the txid guard cannot coalesce and the version moves 70,000 times —
still *correct*, just slow and bloaty. The plan must check the loader's transaction shape, not
assume it.

⚠ `imported_at` was considered as the version and rejected: **389 rows carry NULL** and it has
1,580 distinct values, so it is a per-row ingest stamp, not a global one — and `max(imported_at)`
cannot see a DELETE at all.

A read is `WHERE seed_geo_id = $1 AND seed_mtfcc = $2 AND geofence_version = (SELECT v FROM
essentials.geofence_version)` — a primary-key lookup plus a one-row scan. Rows at superseded
versions are dead weight, swept by the warming job (below).

### 3. The read path

`resolveOverlappingGeoPairs` becomes:

1. Read the store for each seed at the current version. Hit → use it.
2. Miss → run the existing UNION for the missing seeds only, and upsert each seed's result.
3. Return the union.

**Redis stays in front.** It is still the right thing for an in-flight burst, and removing it
would make every request pay a database round trip.

🔴🔴 **CORRECTED AFTER THE BUILDER CHECK — TWO THINGS THE ORIGINAL §3 GOT WRONG, BOTH ADMITTING
THE ANTI-GOAL.**

**(a) The answer is NOT a pure function of geometry. It depends on code too.** Four things that
live in TypeScript and change at deploy, not at ingest, change the result: `UNRESOLVABLE_PAIR_MTFCCS`
(which `geoIdGuard.test.ts` *forces* to change whenever the guard gains a type), branch 3's
`('G5200','G5210','G5220','G4020','G5400','G5410','G5420')`, branch 2's `('G4110','G4120')`
exclusion, and `MIN_OVERLAP_FRACTION = 0.03`. **Today the one-hour TTL quietly heals this** —
change a filter, ship, and within an hour everything is recomputed. A store keyed on geometry
alone **never heals**, which is the stated anti-goal arriving through a door this design did not
check.

▶ **The key gains a `query_fingerprint`:** a hash of the resolver's SQL text together with those
four constants, computed at startup. A read requires the fingerprint to match as well as the
version.

**(b) Redis was not version-aware, so up to an hour of staleness survived an ingest anyway** —
a warm `overlap:v2` entry keeps serving the pre-ingest answer until its TTL expires, so goal 2
was met only below the cache. ▶ **The Redis key now carries the version and the fingerprint
too.**

🔴 **This reverses the original §3 prohibition, and the reason it was wrong is worth keeping.**
That rule came from step 1, where the result was *provably identical*, so bumping the key would
have thrown away warm entries for nothing. Here the opposite holds: when the fingerprint moves,
**the answer genuinely is different**, so recomputing is correct rather than waste. A rule
carried across from a case where the results matched, into one where they do not, is how the
anti-goal gets in.

⚠ **The cost of this, stated plainly: when the fingerprint changes, every stored answer goes
cold at once.** That is rare — only a real change to the query or its constants — and the 53
state seeds are covered by the warming job, which must therefore run on deploy as well as on
ingest. The remaining seeds are the cheap ones (counties 0.5–1.4 s, cities ≈0.5 s). **This is the
trade the design accepts: a rare, bounded, correct stampede over a permanent, silent, invisible
wrong answer.**

✅ **RATIFIED BY THE OPERATOR, 2026-11-24.** This was put to them as the one call in this document
they might want differently, with the alternative stated plainly — let a code change *not*
invalidate, and accept that a filter change reaches only the areas nobody has cached. They kept
it. 🔴 **Settled. Do not re-open it in the plan.**

### 4. Warming the 53

A job that, for every `G4000` polygon, computes and stores the pairs at the current version, then
deletes rows at superseded versions. Runs after a boundary ingest and on a schedule as a backstop.

⚠ **Render cron jobs are configured in `ev-infra`'s `render.yaml`, not in this repo** — a schedule
added here would never run, and a setting changed in the Render dashboard is undone on the next
sync. The job ships here; its schedule is a PR to `EmpoweredVote/ev-infra`.

### 5. The migration

One file, through the owner connection. It must, in the same file: create both tables in
`essentials`, create the trigger, **`ENABLE ROW LEVEL SECURITY` on both**, and add policies —
SELECT for `anon` and `authenticated` (this is derived public geography and the browse endpoints
are unauthenticated), and read/write for `ev_api`. 🔴 Without the RLS lines the tables are
readable by `anon` the moment they exist and **nothing errors**.

## How it will be verified

- **The answer does not change.** For a sample spanning all five seedable layers, the set of
  `essentials.districts` rows surviving `MTFCC_DISTRICT_TYPE_GUARD` must be byte-identical
  store-backed versus computed. Step 1's harness does exactly this and is reusable.
- 🔴 **With a positive control that is watched failing first.** Step 1's control took three
  attempts: dropping `G4020` changed nothing because branch 3 backfills it, and `G4040` changed
  nothing because California's county subdivisions match no district. **A control aimed at a
  value another path also supplies tests nothing.** Here the control is to corrupt one stored
  `pairs` row and watch the comparison go red.
- **The trigger fires.** Insert, update and delete a geofence row in a rolled-back transaction
  and assert the version moves each time — then assert a *bulk* statement bumps it **once**.
- **Staleness is unreachable.** Bump the version and assert the next read recomputes rather than
  serving the old row. This is the anti-goal, so it gets its own test.
- **Measured, not asserted.** Re-time a state seed end-to-end after the warm-up, and re-run the
  two endpoints the report names. ⚠ **At equal cache warmth** — step 1's first reading was 33×
  and wrong, because it compared a trimmed warm run against an untrimmed cold one.

## What the builder check changed — the remaining five calls

A reviewer read this document cold and returned seven questions. Two are folded into §2 and §3
above and are the substantive changes. The other five are settled here; **all of these are my
calls, not the operator's**, and each is cheap to reverse.

1. **An unknown seed is not stored.** `/by-area` and `/elections-by-area` take `geo_id` and
   `mtfcc` straight from an unauthenticated body, validated only as non-empty strings
   (`essentialsBrowse.ts:84-92`). Under the original design a miss *writes a row*, which makes
   the primary key of a permanent `essentials` table **caller-controlled free text that anyone
   can add to at will**. ▶ The read path checks the seed exists in `geofence_boundaries` before
   upserting. A seed that does not exist yields zero pairs anyway, so storing it buys nothing.
2. **The warming job ships as a callable module, not only a cron entrypoint.** Neither a
   migration nor a loader script can invoke a Render cron job, so "runs after a boundary ingest"
   had no mechanism behind it and the 53 states would have been cold for up to a whole schedule
   interval — *precisely the 7-second case this work exists to remove*. ▶ It is importable and
   called from the loader and from a migration's post-verify; the cron is the backstop. It also
   runs on deploy, because of the fingerprint in §3.
3. **The verification sample is named explicitly: `G4000`, `G4020`, `G4110`, `G4040`, `G5200`,
   `X0001`.** "All five seedable layers" was ambiguous and the nearest constant,
   `AREA_SEED_MTFCCS` (`essentialsBrowseService.ts:139`), contains **neither `G4000`** — the
   state seeds this design warms — **nor `G5200`**, which `getPoliticiansByArea` passes on the
   split-district path. A sample taken from that constant would have missed both seeds the work
   is about. ▶ Step 1's lesson, repeating: a control aimed at the wrong type tests nothing.
4. **There is an env flag to stop reading from the store** while leaving the service up, planned
   in rather than retrofitted. The named failure mode is a wrong answer nobody can see; the
   operator needs a way to turn it off without a migration. Its name goes into the `ev-infra`
   record with `sync: false`.
5. **The composition property is confirmed, not open.** The reviewer reached the same conclusion
   independently by reading the SQL, and §1 now carries the measurement.

## Open, and left to the builder

- Whether ZIP (`G6350`) browse reaches this resolver. It changes the seed universe but not this
  design, because C stores on demand.
- Sweep policy for superseded rows: the warming job deletes them, but a seed that is never asked
  again keeps one dead row per version. At 30,000 seeds and a few ingests a year this is
  negligible; revisit if it is not.
- The exact warming schedule, which is an `ev-infra` PR and not a decision here.
