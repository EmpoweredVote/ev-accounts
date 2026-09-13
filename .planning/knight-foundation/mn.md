# MN — slice 5 (Duluth · Saint Paul)

Per-state notes for the Knight Foundation cities program. Siblings: [`fl.md`](./fl.md) ·
[`ga.md`](./ga.md) · [`ca.md`](./ca.md) · [`in.md`](./in.md). Tracker: [`PROGRAM.md`](./PROGRAM.md).

**Opened 2026-09-12.** Lease `state:mn` held by chris@empowered.vote on DESKTOP-G6KDNN2.

MN needs **stage 1 and stage 2 both** — it is the first slice since Georgia to owe full geography
*and* a full legislature. CA/CO/NC skip both; Indiana skipped stage 1 only.

---

## Baseline, measured against production 2026-09-12

Re-measure rather than trust this once any wave has applied.

### What exists

| Layer | Count | Note |
| --- | --- | --- |
| `districts` COUNTY | 87 | all 87 carry a `geo_id`; **St. Louis `27137`, Ramsey `27123`** — both parent counties are present |
| `districts` NATIONAL_LOWER | 8 | congressional |
| `districts` NATIONAL_UPPER | 1 | |
| `districts` STATE_EXEC | 4 | Governor, Lt. Governor, Attorney General, Secretary of State — all four seated |
| `geofence_boundaries` G4020 | 87 | counties |
| `geofence_boundaries` G5200 | 8 | congressional |
| `geofence_boundaries` G6350 | 880 | **ZCTAs, not counties.** See the trap below |
| `governments` "State of Minnesota" | **1** | ✅ not Indiana's 18 |

### What does not exist

- **No `STATE_UPPER` and no `STATE_LOWER` districts. No `G5210` or `G5220` geofence rows.**
- **No place polygons** for Duluth or Saint Paul, and no `G4110` rows for MN at all.
- **No state legislative offices or chambers.** Not one. The only MN offices in production are the
  four statewide executives plus the federal delegation.

So stage 1 is a clean load with nothing to repair, and stage 2 is a clean seed. Indiana's shape —
18 legacy seats on 18 pseudo-chambers needing a repair as much as a seed — **does not recur here**,
and that was verified, not assumed.

---

## 🔴 Traps found while opening the wave

### 1. `G6350` geo_ids look like another state's FIPS and are not

MN's 880 `G6350` rows carry geo_ids beginning `55…`, which reads as Wisconsin's FIPS. **They are ZIP
codes.** The pattern holds nationally: Alabama (FIPS `01`) files `35…`/`36…`, California (`06`) files
`90…`–`97…`, Florida (`12`) files `32…`–`34…`. `G6350` is a ZCTA layer and its ids are ZIPs.

⚠ **Do not "fix" these.** The first read of this table during the MN opening called it cross-state
contamination; grouping `left(geo_id,2)` against `state` across every state is what disproved it.

### 2. 🔴🔴 A "Saint Paul" already exists in production, and it is in TEXAS

`essentials.governments` holds **`City of Saint Paul, Texas, US`**. Any wave that attaches Minnesota's
capital to a government row found by `name ILIKE '%Saint Paul%'` seats the entire Saint Paul council
under a Texas city. **Match the government by its TIGER place `geo_id` `2758000`, never by name.**

This is the same class as GA-2's roster collisions, where `John Carson` was a Colorado senator and
`Kim Jackson` a Utah treasurer — but here it is a *place*, not a person.

### 3. 🔴 TIGER calls it `St. Paul`, and four other Minnesota cities contain that string

Searching TIGERweb for `Saint Paul` in Minnesota returns **zero rows**. The city's TIGER `BASENAME`
is **`St. Paul`**. Searching for `%St. Paul%` instead returns **five** cities:

| TIGER name | GEOID |
| --- | --- |
| **St. Paul city** | **2758000** ← the capital, the one this slice wants |
| North St. Paul city | 2747221 |
| South St. Paul city | 2761492 |
| West St. Paul city | 2769700 |
| St. Paul Park city | 2758018 |

⚠ **`St. Paul Park` is `2758018` — it shares the capital's first five characters `27580`.** A prefix
match is not a match. Both name searches fail, in opposite directions: the spelled-out form finds
nothing, the abbreviated form finds five. **Pin the GEOID.**

Duluth has no such problem: `Duluth city` → **`2717000`**, confirmed identical on two independent
TIGERweb vintages (BAS 2026 layer 4 and Census 2020 layer 18).

### 4. 🔴 The TIGERweb layer number is not the one you would guess

`Places_CouSub_ConCity_SubMCD/MapServer/**0**` is **`Estates`** — a US Virgin Islands geography.
Querying it for Minnesota returns `{"count":0}`: a true answer to the wrong question, and
indistinguishable from "TIGERweb has no Minnesota places".

**Incorporated Places is layer 4** (BAS 2026), or 11 (ACS 2025), 18 (Census 2020), 25. The positive
control that exposed this was a bare count — `STATE='27'` on layer 4 returns **856** places.

▶ **Run a count control on any TIGERweb layer before trusting a zero from it.**

### 5. The Census ACS API now answers `200` with an HTML "Missing Key" page

`api.census.gov/data/2023/acs/acs5?...` without an API key returns **HTTP 200**, 8,531 bytes, and an
HTML error document — not JSON, and not an error status. `r.ok` is worthless here; only decoding the
body catches it. Use TIGERweb, which needs no key.

---

## The enacted plan — what stage 1 must prove it has

| | |
| --- | --- |
| Plan | **L2022** |
| Ordered by | Minnesota Supreme Court **Special Redistricting Panel**, *Wattson v. Simon* |
| Order date | **2022-02-15** |
| First effective election | **2022** |
| Senate districts | **67** → `G5210` → `STATE_UPPER` |
| House districts | **134** → `G5220` → `STATE_LOWER` |
| Publisher | `gis.lcc.mn.gov/redist2020/plans.php?plname=L2022&pltype=court` |

🔴 **MINNESOTA HOUSE DISTRICTS ARE NOT NUMBERED 1–134.** Each of the 67 Senate districts contains
exactly two House districts, labelled with the Senate district's number plus `A` or `B`: Senate
District 1 holds House Districts **`1A`** and **`1B`**, through to `67A`/`67B`.

The consequences are load-bearing and they run through every stage of this slice:

- A House district label is **not an integer**. Anything that casts, sorts or joins on a numeric
  district will break or silently mis-seat. Sorting `1A, 10A, 2A` lexically is wrong.
- The nesting is exact and therefore **gateable**: every House district must fall inside exactly one
  Senate district, and each Senate district must contain exactly two. That is a stronger structural
  check than any other state in the program has offered, and stage 1 should assert it.
- The A/B suffix is how a roster row is identified. Two legislators share the number `1`.

## The `is_vacant` / turnover note

Stage 2 seats **who holds the seat today**, not who won in November. The program's standing rule
applies with unusual force here: MN's general election is **2026-11-03**, seven weeks after this wave
opened, and all 134 House seats are on that ballot. A certified result is not a fact about who holds
the seat; only a **special**-election winner starts early.

▶ **Expect to re-run the change-check immediately before applying stage 2**, and expect the roster to
need a refresh if stage 2 slips past early November.

---

## Jurisdictions

| | Duluth | Saint Paul |
| --- | --- | --- |
| TIGER place | **`2717000`** | **`2758000`** |
| Parent county | St. Louis — `27137` ✅ present | Ramsey — `27123` ✅ present |
| Consolidated? | no | no |
| Council structure | not yet measured — stage 3 | not yet measured — stage 3 |
| County board | not yet measured — stage 4 | not yet measured — stage 4 |

Neither is a consolidated city-county, so §3.2 does not apply and stage 4 keeps both the county board
and the separately elected county officers.

---

## 🔴🔴 MN-1 IS BLOCKED AT TASK 4: the loader collapses A/B districts in `ocd_id`

Found 2026-09-12 during the Task 3 dry run. **The dry run itself passed** — 67 and 134 records, both
pre-flight assertions green, no DB writes — and the defect is invisible in its output.

`load-state-tiger-boundaries.ts` derives `ocd_id` for both SLD layers with:

```ts
case 'sldu':
case 'sldl': {
  const dn = parseInt(districtNum ?? '0', 10);
  ocd_id = buildOcdId(abbrevUpper, layerDef.ocdKey, String(dn));
```

`parseInt('08A', 10)` is **8**. The letter is dropped, so `08A` and `08B` both become
`ocd-division/country:us/state:mn/sldl:8`.

**Measured against the real TIGER file: 134 House districts collapse to 67 distinct `ocd_id`s. All
67 pairs collide.** `geo_id` is unaffected — 134 of 134 stay distinct, because `geoIdSource` is the
raw `GEOID` (`2708A`), which keeps the letter.

### Why nothing would have caught it

- **`ocd_id` carries no unique constraint.** `essentials.districts` has unique indexes on `id` and
  `external_id` only. The duplicates would be written **silently**.
- **The wave's own acceptance test would pass.** Address search uses `geo_id`, never `ocd_id`
  (`ocd_id` ROLLS UP, `geo_id` LOOKS UP), so `check:reachability` and every anchor would be green.
- The pre-flight assertions count records. They cannot see a field derived per row.

### It is already in production, for Maryland

| State | `sldl` rows | distinct `ocd_id` | rows sharing one | `geo_id` ending in a letter |
| --- | --- | --- | --- | --- |
| **MD** | 71 | 47 | **24** | 42 |

Maryland's delegate districts are `1A`, `1B`, `1C`, `2A`… — the same shape, already loaded, already
collapsed. MD is currently the **only** affected state. Minnesota would add **67** more, tripling it.

▶ **North Dakota (slice 12) and South Dakota (slice 15) both hit this too** — PROGRAM.md already
records SD's `26A`/`26B`/`28A`/`28B` subdistricts. This is not a Minnesota problem.

### What it actually breaks

`ocd_id` keys the coverage map's aggregation in `src/lib/coverageMapService.ts`
(`stats.get(ocd_id)`, `map.set(loc.ocd_id, …)`). Two districts sharing one `ocd_id` have their
coverage stats merged into a single bucket — Minnesota would render as **67** House districts rather
than 134, each conflating a pair. Address search is unaffected.

### The fix, and why it is safe

Strip leading zeros exactly as now, but keep any alpha suffix:

```ts
const m = /^0*(\d+)([A-Za-z]*)$/.exec(districtNum ?? '0');
const suffix = m ? m[1] + m[2].toUpperCase() : String(parseInt(districtNum ?? '0', 10));
ocd_id = buildOcdId(abbrevUpper, layerDef.ocdKey, suffix);
```

Byte-equivalent for every purely numeric code — `'043'` → `43`, `'008'` → `8` — so the 19 states
already loaded through this path are unchanged. Only codes carrying a letter change.

⚠ **Repairing Maryland's 24 existing rows is a separate migration**, not part of MN-1. Writing MN
correctly does not fix MD, and MD's wrong `ocd_id`s are already embedded in whatever has read them.

## Open questions, carried into MN-1

1. **Does TIGER's `sldu`/`sldl` for MN carry L2022?** A record count of 67/134 proves nothing about
   *which* map it is — the FL-1 lesson. Anchors must come from the enacted plan, independently.
2. **Which service does the state's own "Who Represents Me" tool query?** `gis.lcc.mn.gov/iMaps/districts/`
   exposes no documented REST endpoint. GA-5's route — read the iframe on the jurisdiction's own page
   and find what it actually calls — is the precedent.
3. **Do Duluth and Saint Paul publish council-district layers?** Unmeasured; stage 3's problem.
