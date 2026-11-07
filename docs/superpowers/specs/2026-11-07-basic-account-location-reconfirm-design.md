# Basic accounts re-enter their address after a boundary change

**Status:** proposed 2026-11-07, awaiting approval · **Owner:** Chris Andrews (`CA_` namespace)
**Follows:** `2026-11-07-basic-account-address-districts-only-design.md` (CA_0368, PR #1341), whose
"Known costs" names this gap.

## Problem

A basic (Inform) account's districts live in `inform.account_jurisdictions`. We keep no address
and no point for it, so nothing can re-resolve them. When a district map is reloaded, the row can
quietly point at the wrong districts. Connected accounts do not have this problem: the weekly
`districtStalenessService` re-resolves them from their encrypted point.

The only fix for a basic row is to ask the person to type the address again. The question is how
to know **whom** to ask — narrowly enough that one city's ward reload does not nag the country.

## What exists today (measured 2026-11-07, prod)

- `essentials.geofence_boundaries` (75,063 rows) has an `imported_at` column (`timestamp`, no time
  zone). 74,687 rows carry one; the oldest is 2026-02-11, the newest 2026-10-31. 486 rows were
  written in the last 30 days (200 places, 206 state legislative, the rest local).
- 🔴 **`imported_at` cannot be the signal.** It records when a row was first inserted, and only
  sometimes after that:
  - `load-state-tiger-boundaries.ts` inserts with `ON CONFLICT (geo_id, mtfcc) DO NOTHING`, so a
    re-run never touches an existing row.
  - **32 writers change `geometry` in place without touching `imported_at`** (city ward loaders
    such as `load-seattle-council-boundaries.ts`, `load-davidson-council-boundaries.ts`, and
    migrations such as `350_school_geofence_geometry.sql`, `CC_0319`, `CA_0317`). Only one bumps it.
  - A **deleted** boundary leaves no row at all, so nothing dated records that it left. A new map
    vintage often arrives as delete-old-geo_ids, insert-new-ones.
- There is **no trigger** on `geofence_boundaries` and no load log or vintage table.
- `inform.account_jurisdictions` holds **1 row** (the test account). Each row stores
  `county_geo_id`, `city_geo_id` and `state_geo_id`, and `resolved_at` (`timestamptz`). Re-entering
  the address (`basicJurisdictionService`) already resets `resolved_at = now()`.
- The districts a basic row can hold come from these layers (the two resolvers in CA_0368):
  `G5200`, `G5200V26`, `G5210`, `G5220`, `G4020`, `G5400`/`G5410`/`G5420`, every `X…` custom layer,
  and `G4040`/`G4110`/`G4120`.

## Recommendation

### 1. Record every boundary change, whoever makes it — one trigger, one log table

New table `essentials.boundary_changes`:

| column | meaning |
|---|---|
| `id bigint identity` | |
| `changed_at timestamptz default now()` | when the change happened |
| `kind text` | `insert` · `update` · `delete` |
| `geo_id`, `mtfcc`, `state` | which boundary (state = 2-digit FIPS, as on the source table) |
| `extent geometry(Polygon, 4326)` | the bounding box of the shape — the **old** shape for a delete, the union of old and new boxes for an update |

An `AFTER INSERT OR UPDATE OF geometry OR DELETE` row trigger on `geofence_boundaries` writes one
log row, **only for the layers above**, and for an update only when the shape really changed
(`ST_AsBinary(old) IS DISTINCT FROM ST_AsBinary(new)`; PostGIS `=` compares boxes, not shapes).

Why a trigger and not a change to the loaders: there are well over 32 writers, migrations among
them, and the next one will not know about this rule. A trigger cannot be skipped by a writer who
has not read this document. Bounding boxes keep the log small (a few hundred rows a month at
today's rate) and work for deletes, where the shape is gone.

**Escape hatch for repairs that do not move a line** (an SRID fix, `ST_MakeValid`): the trigger
skips logging when the writer sets `SET LOCAL ev.boundary_change_silent = 'on'` in its
transaction. Opt-in, per transaction, and visible in the migration file. Without it, a repair
re-asks the people in that area, which is the safe failure.

### 2. A basic row needs confirmation when a change touched its county after it was resolved

```
needs_confirmation(row) :=
  EXISTS a boundary_changes c
   WHERE c.changed_at > row.resolved_at
     AND c.extent intersects the row's county shape          -- G4020 polygon for county_geo_id
  OR (row has no county) AND c.state = row.state_geo_id      -- fallback, coarser
  OR one of the row's stored geo_ids no longer exists in geofence_boundaries
```

Per state and per area, as asked: a Seattle ward reload asks King County's basic accounts only;
a national congressional reload asks everyone, which is correct. The county is the right net
because every layer a basic row holds either sits inside one county or crosses it, and the row
always stores its county. It over-asks a little (a change elsewhere in the county may not reach
this person). It never under-asks for a shape change, a new layer, or a deleted boundary.

The last clause catches a boundary deleted **before** this log existed.

Computed **at read time** in one SQL function, `inform.basic_location_needs_confirmation(user_id)`.
No stored flag: a cached "stale" column would itself go stale, the same trap `CLAUDE.md` warns
about for "current". The query is indexed (`boundary_changes (state, changed_at)` plus a GiST index
on `extent`) and runs only for a basic account with a row.

### 3. Tell the account — API and accounts app

- **API.** `GET /api/account/me` and `GET /api/account/me/jurisdiction` gain a top-level
  `location_needs_confirmation: boolean`. Always `false` for a Connected account (the weekly job
  covers it) and for an account with no address. 🔴 Top level, **not inside `jurisdiction`**: that
  object feeds Validation Quests' quest filtering and is kept byte-identical.
- **Accounts app** (`app/`):
  - `DashboardPage` and `ProfilePage`: when the flag is true, the location card shows a notice —
    "District maps in your area were updated after you added your address. Re-enter it to keep
    your representatives and elections correct." — with a button to `/settings/location`.
  - `UpdateLocationPage`: the same sentence above the form.
  - Saving the address resets `resolved_at`, so the notice disappears on the next load. No other
    action clears it.
- **Civic Spaces: no change now.** It shows a basic account its own **place** (city), keyed on
  `city_geoid`. A city boundary change is the rarest kind, and the accounts app notice reaches the
  same person. Civic Spaces can read the same flag later if wanted; it is a separate repo and an
  admin merge.
- **Essentials** (the representatives page): out of scope here; it can read the same flag later.

### 4. Meanwhile, keep showing the stored districts

Keep them, with the notice. Do not hide them.

- A reload rarely moves a given person: most changes are elsewhere in the county. Hiding would
  blank the representatives page for many people whose districts are still right.
- Hiding gives a person nothing to act on. The notice tells them exactly what to do.
- The notice is honest: it says the maps changed, not that their districts are wrong.

## Not doing

- **No stored point, ever**, for a basic row — the decision in CA_0368 stands. This design needs
  none.
- **No email or push.** The notice shows where the districts are shown. An email would need a
  separate decision about contacting basic accounts.
- **No back-fill of the log.** It starts empty; today's single basic row was resolved after every
  existing load (newest `imported_at` 2026-10-31, row resolved 2026-11-07).

## Build plan (after approval)

1. **Migration** (`CA_` slot from the steward): table, grants (`ev_api`, `service_role`; RLS on,
   no policy; nothing for `anon`/`authenticated`), trigger function, trigger, indexes, the read
   function. Post-verify gate, run inside the migration's own transaction:
   - an update that changes a shape writes exactly one log row; one that changes only `name` writes
     none; the silent setting writes none; a delete writes one with the old box; a layer outside
     the list writes none — each on a scratch row, then rolled back to a savepoint;
   - the test basic row reads `false` now; after a logged change inside its county it reads
     `true`; after one in another state it reads `false`.
   Dry-run against prod in `BEGIN … ROLLBACK` with `dry-run-migration.mjs`, and watch a planted
   fault (trigger disabled) fail the gate first.
2. **Backend:** call the function from `accountMeService` and the `/me/jurisdiction` route; unit
   tests for both tiers and the no-address case.
3. **App:** the notice on the three pages, with a test that it shows only when the flag is true.
4. Apply the migration and merge only on Chris Andrews' yes.
