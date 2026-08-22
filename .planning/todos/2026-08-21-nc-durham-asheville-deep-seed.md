# North Carolina deep seed — Durham, Asheville, their counties, and the legislature

**Created** 2026-08-21 · **Status** design approved, wave 1 not started
**Scope** NC General Assembly (170 seats) · Durham city + county · Asheville + Buncombe County ·
banners · headshots · stances · 2026 candidates

Geometry probe run 2026-08-21 before any design work. Every number below was **measured**, not
assumed; the probe was read-only and its script was thrown away. Re-verify anything you are about to
act on — but do not re-derive the four findings in "Probe evidence", they cost real effort.

---

## Why this document exists

The obvious plan — "seed NC like we seeded Colorado Springs" — is wrong in three places, and each
one is invisible until you look:

1. NC redrew maps for 2026, so TIGER 2024 **looks** stale and isn't (only Congress moved).
2. Durham's council has wards, so ward polygons **look** like districts and aren't.
3. Buncombe's commission districts **look** like a custom county layer and are actually the state
   House map, by statute.

Get any of the three wrong and the failure is silent — a voter is shown a wrong or missing
representative and nothing errors.

---

## Probe evidence (2026-08-21)

### 1. TIGER 2024 is the correct vintage for state legislative districts

The NCGA's own redistricting page is authoritative here; web summaries garbled it badly, claiming
the legislature redrew all three maps.

| Map | Plan | Enacted | In effect for 2026 |
|---|---|---|---|
| NC House | HB 898 / **SL 2023-149** | 2023-10-25 | **unchanged** |
| NC Senate | SB 758 / **SL 2023-146** | 2023-10-25 | **unchanged** |
| Congressional | SB 249 / SL 2025-95 | 2025-10-22 | redrawn — and already loaded |

Raw TIGER 2024 FIPS 37, read directly from the shapefiles:

```
sldl: 120 polygons | MTFCC G5220 | LSY 2024 | 120 distinct codes | ZZZ pseudo: 0
sldu:  50 polygons | MTFCC G5210 | LSY 2024 |  50 distinct codes | ZZZ pseudo: 0
place: 776 records | G4110 552 (incorporated) + G4210 224 (CDPs)
```

**120 polygons = 120 seats and 50 = 50** — NC is single-member in both chambers, so there is no
AZ/WA multi-member trap where polygon count ≠ seat count. Durham city is `3719000`, Asheville city
is `3702140`, both `G4110` / `FUNCSTAT A`.

### 2. Identity anchors agree across two independent sources

TIGER point-in-polygon vs. Buncombe County's own GIS (`gis.buncombecounty.org`, which publishes
sitting member names):

| Anchor | TIGER says | Independent source |
|---|---|---|
| Asheville — three separate points | HD-116 / SD-49 | Brian Turner / Julie Mayfield ✅ |
| Weaverville Town Hall | HD-115 | Lindsey Prather ✅ |
| Black Mountain Town Hall | HD-114 / SD-46 | J. Eric Ager / Warren Daniel ✅ |
| Durham City Hall | HD-30 / SD-22 | — |
| Durham County Courthouse | HD-31 / SD-22 | — |
| Legislative Building, Raleigh | HD-38 / SD-14 | — |

Anchor coordinates came from the Census geocoder, not from memory or from the polygons being tested.

### 3. 🔴 Buncombe's commission districts ARE the state House districts — verified, not assumed

A 2011 local bill took Buncombe from 5 commissioners to 7, made six of them elected **by district**,
and set the district lines equal to the three NC House districts, two commissioners each.
**Buncombe is the only one of NC's 100 counties with this arrangement.**

Rather than trust that, both layers were queried and compared:

| Commission district | `Shape.STArea()` | State House | `Shape.STArea()` | Pop |
|---|---|---|---|---|
| D1 — Horton, Whitesides | 652739949.8563602 | **HD-114** (Ager) | 652739949.8563602 | 91,120 |
| D2 — Wells, Moore | 909874574.490132 | **HD-115** (Prather) | 909874574.490132 | 88,875 |
| D3 — Sloan, Ball | 143308244.59990597 | **HD-116** (Turner) | 143308244.59990597 | 89,457 |

Byte-identical area, length and population. They are the same polygons.

⚠️ **This is a live coupling, not a coincidence.** A future NC House redraw silently moves Buncombe's
commission lines. Whatever we build must record that dependency, or the next redistricting quietly
corrupts county data that nobody thought was tied to the legislature.

### 4. 🔴 Durham's wards are a residency rule, not a constituency

Durham City Council is 7 seats: 3 ward + 3 at-large + mayor. **The ward members are elected
citywide** — every Durham voter votes on all seven. The ward only constrains where a candidate may
live.

Durham publishes a "City Council Wards" ArcGIS layer. **Loading it as districts would be wrong**: it
would show a voter one ward member when they in fact elect all seven, understating their
representation by four seats and doing so silently.

This is a third case alongside ADR 0003's `residency` / `membership` split:

| Case | Constituency | Address-selectable? | Example |
|---|---|---|---|
| `residency` | people in a polygon | yes | NC HD-116 |
| `membership` | people in a polity | no — additional and explained | Maine tribal seats |
| **citywide-with-residency-district** | **everyone in the city** | **yes, at the city polygon** | **Durham wards** |

It does not need a new ADR — it resolves cleanly to "the office hangs off the city place polygon" —
but the ward layer's existence is a trap worth naming, because the obvious move is to load it.

### 5. Local structures, confirmed

| Body | Seats | Method | Geometry needed |
|---|---|---|---|
| Asheville City Council | mayor + 6 | **all at-large**, nonpartisan, staggered; 3 seats every 2 yrs | Asheville place polygon only |
| Durham City Council | mayor + 3 ward + 3 at-large | **all elected citywide** | Durham place polygon only |
| Durham County BOCC | 5 | **all at-large countywide** | existing `37063` polygon |
| Buncombe County Commission | chair + 3×2 | chair countywide, **six by district** | 3 districts = HD-114/115/116 |

Three of the four bodies need **no new district geometry at all**. This is the opposite of the
Indiana failure mode that was the main risk going in.

### 6. `G5200V26` does not fire in Durham or Asheville — but it does fire in NC

NC (`nc_ncga_2025`) is one of the 9 states in the open
[`G5200V26` vintage collision](./2026-08-19-congressional-map-vintage-collision.md), where one
address can return two US Representatives.

Measured at both layers: Durham `3704`/`3704`, Asheville `3711`/`3711`, Charlotte `3712`/`3712`,
Raleigh `3702`/`3702`, Black Mountain `3711`/`3711` — **all agree, so all collapse to one row.**

That todo warns that a sample landing on unchanged ground reports "fine", so the detector was given a
positive control. NC's 2025 redraw only moved CD-1/CD-3 (17,191 km² and 4,142 km² of swap). A point
inside the swap zone:

```
-76.331218, 35.388363  →  G5200 census_tiger_2024 = 3703 (CD-3)
                          G5200V26 nc_ncga_2025   = 3701 (CD-1)
```

**Two representatives, one address — the Austin defect reproducing in NC.** Add this coordinate to
the collision todo as NC's known-positive control.

Consequence for this program: **the acceptance probes for Durham and Asheville are clean and this bug
cannot block wave 2 or 3.** It is not caused by, and will not be fixed by, this work.

---

## Waves

Sequenced so that the thing most likely to be wrong is proven earliest, and so that nothing depends
on a wave that hasn't landed. Each wave is independently shippable and independently verifiable.

### Wave 1 — NC General Assembly (170 seats)

The largest wave and the prerequisite for wave 3, because Buncombe's commission districts are the
House districts.

* Add `NC` to `STATE_LAYER_ALLOWLIST` in `scripts/load-state-tiger-boundaries.ts` as
  `NC: new Set(['sldu', 'sldl', 'place'])`, matching the VA/NV/AZ/MD/OR shape. The allowlist is
  deliberately a code change — it forces review of which layers are safe for a state.
  `county` is **excluded**: all 100 NC counties already exist with `geo_id`, and re-running the
  layer risks disturbing rows that offices will hang off in waves 2 and 3.
  **Wave 1 declares `place` in the allowlist but only *runs* `--layers sldu,sldl`.** Waves 2 and 3
  run `place` separately, so a city-loading mistake cannot force a re-run of 170 seats.
* Pre-flight assertion block in house style asserting **`sldl: 120`, `sldu: 50`**, aborting before
  any DB write on a mismatch.
* Two chambers on the **existing** `State of North Carolina` government
  (`3a09655d-0d33-45c5-a33a-7a863bd653a1`): `North Carolina House of Representatives`
  (`official_count` 120) and `North Carolina Senate` (50).
  🔴 **One chamber per chamber, not one per district.** Indiana has 100+ chamber rows named
  `Indiana House of Representatives - District 45`, each with its own `government_id` and
  `official_count = 0`. Follow Colorado and Massachusetts, not Indiana.
* 170 offices, then 170 politicians and 170 `office_terms` rows via `seat_officeholder`.
* `external_id` band `-(3710000+n)` Senate / `-(3720000+n)` House, mirroring WA's
  `5310000/5320000` and CO's `810000/820000`. **Verified free 2026-08-21: 0 rows in
  `-3729999..-3710001`.**

### Wave 2 — Durham city + Durham County

* `place` layer, **G4110-only**. The 224 `G4210` CDPs in the NC file are not governments; loading
  them invents 224 fake municipalities.
* Durham city `LOCAL` district on `geo_id 3719000`; 7 offices, all on the city polygon.
* Durham County's 5 at-large commissioners onto the **existing** `37063` county district.
* Banner, headshots, stances (local scale, 22 topics).

### Wave 3 — Asheville + Buncombe County

* Asheville city `LOCAL` district on `geo_id 3702140`; 7 offices, all at-large on the city polygon.
* Buncombe: at-large chair on the existing `37021` county district; six district commissioners on
  three districts derived from wave 1's `sldl` 114/115/116.
* Cross-check against `gis.buncombecounty.org` layer 7 before trusting the derivation, and record
  the statutory coupling on the district rows.

### Wave 4 — 2026 candidates

Last, because races hang off `office_id` and the offices must exist first. An
`NC 2026 Statewide General` election already exists with 15 races / 44 candidates; extend rather
than create a parallel election.

---

## Standing rules this program must not break

* **Migrations are `CA_NNNN_*.sql`.** Next free slot is **`CA_0004`** (`CA_0001`–`CA_0003` exist;
  `check:migrations` green 2026-08-21). Unlike the shared sequence, the `CA_` namespace does **not**
  require taking the number last — Chris counts within his own namespace and never reads the shared
  max. Cite slots in full (`CA_0004`, never "migration 4").
* **An office with no `office_terms` row is invisible and nothing errors.** Watch
  `essentials.offices_missing_terms`; unflagged baseline is 699 and it read **655** on 2026-08-21.
* Seating is a deliberate two-step — close the predecessor, then insert. Use `seat_officeholder` /
  `vacate_office`, don't hand-roll.
* **Don't invent dates.** Year-only sources get `start_precision => 'year'`; genuinely unknown starts
  get `'unknown'`, not a guess.
* Party lives on `races.primary_party`, never on `race_candidates`.
* **The state stance scale is 28 topics, not 26** — `inform.compass_topic_roles` where
  `role_scope='state'`, measured 2026-08-21. Local is 22. The 26 figure in project memory is stale;
  re-verify topic UUIDs against prod before any stance push regardless.
* Chairs are five distinct stances, not a polarity rating. A blank spoke is correct; a guessed chair
  is a false statement about a real person. Run
  `node scripts/audit-chair-evidence.mjs --check <rollback.json>` before committing any chair.
* Deleting from `inform.politician_answers` obliges a `-- @context-decision:` line in the same
  migration.
* 🔴 **Check the NC state banner's subject before picking city banners.** It is currently a
  **Charlotte** skyline. Durham and Asheville don't collide with it — but nothing Charlotte-flavored
  may be chosen for either, and if the state banner is ever re-pointed at Durham or Asheville the
  collision becomes real. Banners live in the **essentials** repo (`src/lib/buildingImages.js`), not
  `treasury.municipalities`. Version the filename; overwriting does not purge the CDN.
* Headshots: press / official / public-domain only, never social media. Approval is a **batch contact
  sheet**, never one dialog per person. The gate is the upscale factor, not a pixel floor.

## Acceptance — end-to-end, per wave

The only reliable detector is an address probe, because every other check passes vacuously when a
term row is missing.

| Wave | Probe | Expected |
|---|---|---|
| 1 | Durham City Hall `-78.8997, 35.9961` | HD-30 + SD-22 present |
| 1 | Asheville `-82.5554, 35.5967` | HD-116 + SD-49 present |
| 2 | Durham City Hall | + 7 city + 5 county officials |
| 3 | Asheville | + 7 city + chair + 2 D3 commissioners |
| 3 | Black Mountain `-82.3200, 35.6197` | HD-114, and **D1** commissioners — not D3 |

Negative control for wave 3: an Asheville address must **not** return District 1 or 2 commissioners.
A uniform answer is a broken detector until a negative control fails as expected.

`npm run check:occupancy`, `check:migrations`, `check:reachability` and the stance-source gate all
green before each wave merges.

## Open questions

* Durham County's 5 commissioners are at-large today; confirm no district plan is pending for 2026
  before wave 2.
* Asheville reverted to at-large by charter change; confirm no district plan has been reinstated for
  the 2026 cycle beyond the March primary already observed.
* Wave 4 needs a decision on whether NC candidate coverage follows the 2026 congressional map
  (`G5200V26`) or the sitting-member map — this is the unresolved product call in the collision todo,
  not something wave 4 can settle on its own.
