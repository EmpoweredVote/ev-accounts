# Data Coverage Tracker

Per-jurisdiction view of how complete EV's data is, **plus** the jurisdiction-specific
research rules the `research-stances` skill must obey. One YAML file per state
(`ut.yaml`, `in.yaml`, …). This file is the **version-controlled source of truth**.

## Who reads it

| Consumer | Reads | Purpose |
|----------|-------|---------|
| Admin page `/admin/coverage` | whole file | visual, at-a-glance completeness dashboard |
| `research-stances` skill (STEP 0.5) | `rules.skip_topics` | auto-exclude inapplicable topics + warn |
| `scripts/coverage-sync.ts` | `locations[]` | refresh the **auto** columns from the live DB |
| `src/lib/coverageService.ts` | whole file | serve `GET /api/admin/coverage` (recomputes auto cols live) |

## Schema

```yaml
state: UT                       # 2-letter code (matches essentials.districts.state, case-insensitive)
state_name: Utah
synced_at: 2026-05-30           # stamped by coverage-sync.ts on its last run

rules:
  skip_topics:                  # MACHINE-READ by research-stances
    - topic_key: rent-regulation
      reason: "…why this topic is inapplicable here…"
      source:  "https://…"      # statute / authority (optional but encouraged)
      applies_to: [state, county, local, school]   # office levels the rule covers
  notes:                        # free-text, human-only
    - "…"

locations:
  - ocd_id: ocd-division/country:us/state:ut/place:salt_lake_city
    name: Salt Lake City
    level: local                # state | county | local | school
    status: active              # active | in_progress | deferred
    expected_seats: 7           # full-roster target; null = unknown (see "complete" below)
    # ── manual columns (hand-edited) ──
    geofenced: true
    donors: none                # none | partial | full
    candidates: none            # none | partial | full
    treasury: none              # none | partial | full
    # ── auto columns (written by coverage-sync, recomputed live by the API) ──
    populated: true             # has ≥1 active politician
    headshots: none             # none | partial | full  (photos / total)
    stances: { researched: 0, total: 7 }   # researched = last_stances_researched_at IS NOT NULL
    last_researched: null       # YYYY-MM-DD | null  (max last_stances_researched_at)
```

### Field ownership

- **manual** — `geofenced`, `donors`, `candidates`, `status`, plus all of `rules`.
  Edit by hand; the sync script never touches these.
- **auto** — `populated`, `headshots`, `stances`, `last_researched`, `treasury`, `synced_at`.
  Overwritten by `coverage-sync.ts` from the live database.

### Treasury (auto)

`treasury` is matched to `treasury.municipalities` by an **exact TIGER `geo_id` join** —
`treasury.municipalities.geo_id` (migration 194) ↔ the coverage location's district `geo_id`
(`resolveLocationGeoIds()` resolves it via `essentials.districts`). Rows whose treasury `geo_id` is
still NULL fall back to the legacy **name + state** slug. `full` = budgets loaded, `partial` =
municipality exists but no budgets, `none` = no match. Read-only against the treasury schema — it
never writes treasury data.

> `treasury.municipalities.geo_id` must be populated on import (handled by `resolveTreasuryGeoId()` in
> the budget importers; backfill existing rows with `scripts/backfill-treasury-geo-id.ts`). See the
> root `CLAUDE.md` → "Treasury ↔ TIGER geofence link".

The API also returns `treasury_orphans`: budget-bearing municipalities with **no matching coverage
row** (money data but no officials tracked — e.g. TX has 14 cities with budgets but no local rosters
yet).

### Granularity

One row per **tracked** jurisdiction (one we've started). Add a row when work begins. Do **not**
hand-enumerate every municipality — the full universe (and what's left) is computed automatically
(see below). The `state`-level row is the roll-up (it matches the entire `state:ut` OCD subtree).

### Universe — progress toward the whole state

```yaml
universe:
  state_fips: "49"          # FIPS code (matches geofence_boundaries.state); enables the geofence diff
  tribes:                   # static list — no tribal geofences/rosters loaded yet
    - Navajo Nation
    - ...
```

The admin API computes, per category, **how many of the entire state's jurisdictions have
politicians yet** and which remain — so you can see "10 / 255 cities populated". Totals come from
TIGER geofences in `essentials.geofence_boundaries` (counties `G4020`, cities/towns `G4110`, school
districts `G5420`); "populated" is derived by diffing those against `districts.ocd_id`. Tribes have no
geofences yet, so they're a static list here (all counted as not-yet-started). This block is **not**
touched by `coverage-sync.ts` — the universe is always computed live.

### "Complete" definition (full roster)

A jurisdiction is **complete** when its active politician count ≥ `expected_seats`. The statewide
progress bars count *complete* jurisdictions (green) vs *in progress* (started but under-rostered,
amber) vs *not started* (no politicians). `expected_seats` is manual:
- **Counties** — authoritative, from `ut_county_rosters.json` (commissioners/council seats +
  at-large officers). This is why Washington & Weber show 9/10 (a missing officer).
- **Cities & school districts** — seeded at the currently-loaded roster size as a baseline; verify
  against official council/board sizes and adjust. `null` means "unknown" → never counted complete.

### "Calibrated" definition

A politician is *calibrated* when `essentials.politicians.last_stances_researched_at IS NOT NULL`.
A location's `stances` is `researched / total` over its active politicians. The 180-day freshness
window only drives a "stale" badge on the admin page and a re-research hint in the skill — it does
**not** change the fraction.

## How a location maps to politicians

`essentials.politicians → offices.district_id → districts.ocd_id`, matched as a subtree:

```sql
WHERE d.ocd_id = $ocd OR d.ocd_id LIKE $ocd || '/%'
```

So a `place:salt_lake_city` row also counts its `…/ward:N` districts, and the `state:ut` row counts
everything. OCD `place:` and `county:` are siblings under `state:`, so a county row counts county
officials only — its cities are their own rows (no double-counting except at the state roll-up).

## Refreshing

After any data load (`load-ut-*.ts`, stance research, etc.):

```bash
cd ev-accounts/backend
npx tsx scripts/coverage-sync.ts --state ut --dry-run   # preview the diff
npx tsx scripts/coverage-sync.ts --state ut             # write auto cols back into ut.yaml
git add data/coverage/ut.yaml && git commit -m "chore(coverage): refresh UT auto columns"
```

The admin page recomputes auto columns live on each request, so it is always fresh; the committed
snapshot exists for git history and for the skill's offline read.

## Row types (`match`)

A location row matches politicians one of three ways:

| `match` | meaning | used for |
|---------|---------|----------|
| `subtree` (default) | `ocd_id` = X or under `X/` | a specific county / city / school district |
| `exact` | `ocd_id` = X exactly | statewide offices at the bare state OCD (Gov / U.S. Senate) |
| `kind` | all districts of `ocd_kind` under the state | **chamber aggregates** (U.S. House `cd`, State Senate `sldu`, State House `sldl`) |

Chamber rows carry `ocd_kind` and `match: kind`, share the state-prefix `ocd_id`, and use
`level: federal` (U.S. House) or `level: state` (legislature). Their `expected_seats` is the real
TIGER seat count, so e.g. "State House 150/150" is meaningful.

## Adding a new state — use the generator

```bash
cd ev-accounts/backend
npx tsx scripts/coverage-init.ts --state ca            # dry run — prints the YAML
npx tsx scripts/coverage-init.ts --state ca --write    # writes data/coverage/ca.yaml
```

`coverage-init.ts` derives everything from the live DB: chamber-aggregate rows (real seat counts
from TIGER geofences), a statewide-offices row where present, and one local row per county / city /
school district that has politicians. It leaves `rules.skip_topics` and `universe.tribes` empty and
seeds local `expected_seats` at the **loaded-roster baseline** (verify against official sizes).
Then edit by hand as needed and refresh auto columns with `coverage-sync.ts --state ca`. The admin
page picks the new state up via the `?state=` selector — no code changes required.

Universe categories with no TIGER geofences for the state are omitted; if more jurisdictions are
populated than the geofence universe contains (incomplete geofences, e.g. IN counties), that card is
flagged "universe size unknown" instead of showing a wrong fraction.
