# North Carolina deep seed — Durham, Asheville, their counties, and the legislature

**Created** 2026-08-21 · **Status** waves 1–3 applied to prod (2026-08-22/23); wave 2b (Durham +
Asheville banners/headshots/stances) and wave 4 (2026 candidates) not started. Next slot `CA_0011`.
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

### Wave 1 — NC General Assembly (170 seats) — ✅ DONE 2026-08-22

Applied as **`CA_0004`** (2 chambers + 170 offices) and **`CA_0005`** (170 politicians + 170 terms),
on top of a TIGER `sldu,sldl` load. Verified in prod: 120 House / 50 Senate, 170 seated,
`offices_missing_terms` unflagged still **655** (zero drift), reachability at or below baseline
(`DEAD_GEOGRAPHY` improved 18 → 17), 1185 tests green.

End-to-end probe returns exactly one House and one Senate member per address:

| Anchor | House | Senate |
|---|---|---|
| Asheville | HD-116 Brian Turner | SD-49 Julie Mayfield |
| Black Mountain | HD-114 Eric Ager | SD-46 Warren Daniel |
| Durham City Hall | HD-30 Marcia Morey | SD-22 Sophia Chitlik |
| Raleigh (Leg. Bldg) | HD-38 Abe Jones | SD-14 Dan Blue |

The Buncombe rows match the county's own GIS roster exactly — the same oracle used to validate the
commission-district coupling, so **wave 3 can now derive Buncombe's 3 commission districts from
`sldl` 114/115/116.**

🔴 **Two things wave 1 learned that waves 2–3 must not relearn:**

1. **The dry-run recipe below was WRONG as originally written, and it cost a real un-rehearsed
   apply.** See "Dry-running a migration in this repo".
2. **All 8 contested legislative districts seat the SUCCESSOR** (HD-40 Rubin, HD-47 John L. Lowery,
   HD-60 Cook, HD-90 Kiger, HD-119 Ferguson, SD-18 Fatmi, SD-23 Garson, SD-34 Measmer). The chamber's
   own roster lists departed members alongside successors, and in HD-40 and HD-119 the **departed**
   member carries no annotation at all — filtering on "Resigned" seats two people in one seat.

The original plan follows, for reference.

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

### Wave 2 — Durham city + Durham County — ✅ DONE 2026-08-22

Applied as **`CA_0006`** (1 LOCAL district `Durham Citywide`, geo_id `3719000` + 15 offices) and
**`CA_0007`** (15 politicians + 15 terms). End-to-end probe: a Durham City Hall address returns
**8 county + 7 city + HD-30 + SD-22**.

* `place` layer, **G4110-only**. The 224 `G4210` CDPs in the NC file are not governments; loading
  them invents 224 fake municipalities.
* Durham city `LOCAL` district on `geo_id 3719000`; 7 offices, all on the city polygon.
* Durham County's **8 offices** onto the **existing** `37063` county district: the 5 at-large
  Commissioners plus Sheriff, Register of Deeds and Clerk of Superior Court.
* Banner, headshots, stances (local scale, 22 topics).

### Wave 3 — Asheville + Buncombe County — ✅ DONE 2026-08-23

Applied as **`CA_0009`** (1 `LOCAL` district `Asheville Citywide` on `3702140`, 3 `COUNTY` districts
on new synthetic **`mtfcc X0034`**, 2 governments, 3 chambers, 17 offices) and **`CA_0010`**
(17 politicians + 17 terms). **Next free slot: `CA_0011`.** Both idempotent, re-run clean.

Geometry loaded by `scripts/load-buncombe-commissioner-boundaries.ts`; standing assertions in
`scripts/verify-buncombe-commission-coupling.sql` and `scripts/verify-wave3-address-probes.sql`.
`place` was **not** re-run, as required — Asheville's polygon was already present.

End-to-end probes: Asheville City Hall returns **16** (7 city + chair + 3 row offices + District 3's
two commissioners + HD-116 + SD-49 + US Rep); Black Mountain returns **9** (4 countywide + District
1's two + HD-114 + SD-46 + US Rep) and **zero** Asheville city officials. All four negative controls
hold, each with a control-of-the-control. `offices_missing_terms` unflagged still **655**.

Scope was seats + banner; headshots and stances defer to a combined wave 2b covering **Durham and
Asheville together**.

**Open question closed:** Asheville has *not* reinstated a district plan. Both the city's own council
page and Buncombe Election Services list mayor + 6, all at-large, with no district labels.

#### 🔴 Three corrections this wave produced, for whoever does wave 4 or the next county

1. **The coupling gate must be a TOLERANCE test, not `ST_Equals`.** The byte-identical finding above
   is real but compares two layers of **Buncombe's own** GIS. Our House polygons are **TIGER 2024**,
   an independent digitization: `ST_Equals` is **false** for all three, at IoU 99.681 / 99.883 /
   99.969 % (symmetric differences 2.09 / 1.07 / 0.04 km²). An equality gate fails permanently on
   correct data, and the obvious fix for a permanently-red gate is to delete it. The threshold is
   99.0 %, chosen against the measured off-diagonal — every wrong pairing sits at 0.000–0.002 %.
   **The coupling survived the 2023 NC House redraw**, which is direct evidence it is a live
   statutory link the county maintains, not a 2011 coincidence.
2. **`check:child-county` does not track `X*` boundaries and never did.** It defines children as
   `mtfcc IN ('G4110','G5420','G5400','G5410')`. `X0033`, `X0027` and every other `X%` mtfcc have
   **0** rows in `essentials.geofence_child_county`. A green `stale 0` after loading `X0034` says
   nothing about those rows — do not read it as evidence the load worked.
3. **Buncombe's published year is TERM EXPIRY**, and reading it as "elected four years earlier" is
   wrong for **5 of 17** people, because this board fills vacancies by appointment repeatedly
   (Whitesides 2016, Ball 2025, Christy 2023 — three separate vacancies). See the wave-3
   `ROSTERS.md` "Source defects found".

### Wave 4 — 2026 candidates

Last, because races hang off `office_id` and the offices must exist first. An
`NC 2026 Statewide General` election already exists with 15 races / 44 candidates; extend rather
than create a parallel election.

---

## Standing rules this program must not break

* 🔴 **Dry-running a migration here — the naive recipe DOES NOT WORK and silently APPLIES.**
  **1497 of 1764 migrations self-wrap in `BEGIN;` … `COMMIT;`**, including the CO (1843/1844) and WA
  (1742) siblings this generator family is modelled on. So this, which looks right, is not:

  ```bash
  BEGIN;
  \i migrations/CA_0004_whatever.sql   # ← its own COMMIT closes YOUR transaction
  ROLLBACK;                            # ← "WARNING: there is no transaction in progress"
  ```

  The inner `COMMIT` wins and the rehearsal is a real apply. **This happened on 2026-08-22 with
  `CA_0004`.** CLAUDE.md says to wrap *the body* — that word is load-bearing. Strip the file's own
  transaction control first, then wrap what remains:

  ```bash
  grep -vE '^(BEGIN|COMMIT);$' migrations/CA_0005_whatever.sql > body.sql
  # then:  BEGIN; \i C:/abs/windows/path/body.sql ; <count queries>; ROLLBACK;
  # psql's \i needs a WINDOWS path — a /c/... path fails with "No such file or directory".
  ```

  Then **prove reversion with a separate query afterwards.** A printed `ROLLBACK` is not proof; the
  presence or absence of the WARNING is what distinguishes a rehearsal from an apply.

* **Migrations are `CA_NNNN_*.sql`.** Next free slot is **`CA_0011`** (`CA_0001`–`CA_0010` exist;
  `check:migrations` green 2026-08-21). Unlike the shared sequence, the `CA_` namespace does **not**
  require taking the number last — Chris counts within his own namespace and never reads the shared
  max. Cite slots in full (`CA_0006`, never "migration 6").
* **An office with no `office_terms` row is invisible and nothing errors.** Watch
  `essentials.offices_missing_terms`; unflagged baseline is 699 and it read **655** on 2026-08-21.
* Seating is a deliberate two-step — close the predecessor, then insert. Use `seat_officeholder` /
  `vacate_office`, don't hand-roll.
* **Don't invent dates.** Year-only sources get `start_precision => 'year'`; genuinely unknown starts
  get `'unknown'`, not a guess.
* Party lives on `races.primary_party`, never on `race_candidates`.
* 🔴 **`geo_id` is not unique across layers — always pair it with `mtfcc` in a join.** TIGER's GEOID
  is `STATEFP || district`, so NC districts 1–50 will carry the same `geo_id` in both chambers
  (`37040` is both HD-40 and SD-40). This is the known ~1,159-row collision class that
  `src/lib/geoIdGuard.ts` disambiguates (`G5220→STATE_LOWER`, `G5210→STATE_UPPER`); ad-hoc SQL is
  **not** guarded. Measured on already-loaded Colorado: a Denver point joined on `geo_id` alone
  returns **five** rows — both chambers of HD-6 and SD-31 *plus* `COUNTY|Denver County`, because
  `08031` is also Denver's county FIPS. The correct answer is two. Nothing errors when this is wrong.
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
| 2 | Durham City Hall | + 7 city + 8 county officials |
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
