# OH — slice 8 (Akron · Summit County)

Program tracker: [`PROGRAM.md`](./PROGRAM.md) · spec:
[`2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md)

**Opened 2026-09-23.** Lease `state:oh` held by chris@empowered.vote on DESKTOP-G6KDNN2.
Worktree `C:\ev-accounts-oh`, branch `knight/oh-slice8`.

| Stage | State |
| --- | --- |
| 1 geography | 🟡 **MEASURED AND VINTAGE-EVIDENCED, NOT LOADED.** Only `sldu` + `sldl` are owed — `place` already exists |
| 2 legislature | — 132 offices owed (99 House + 33 Senate), none exist |
| 3 city waves | — Akron: Mayor + 13 council (10 ward + 3 at-large) |
| 4 county waves | — Summit: Executive + 11 council (8 district + 3 at-large) + 5 row officers |
| 5 assets | — 1 banner (`akron`), ~163 portraits |

🔴 **NOTHING HAS BEEN WRITTEN TO PRODUCTION.** Everything below is a measurement.

---

## Baseline, measured against production 2026-09-23 (before anything was written)

Re-measure rather than trust this once any wave has applied.

### What already exists

| Layer | Count | Note |
| --- | --- | --- |
| `districts` COUNTY | 88 | all 88 carry a `geo_id`; **Summit `39153`** is present, with `ocd_id`, **no `government_id`, no offices** |
| `districts` NATIONAL_LOWER | 15 | congressional |
| `districts` NATIONAL_UPPER | 1 | |
| `districts` STATE_EXEC | 5 | Governor, Lt. Governor, Attorney General, Secretary of State, Treasurer — all five seated |
| `geofence_boundaries` G4020 | 88 | counties, imported 2026-07-10 |
| `geofence_boundaries` G4110 | **925** | **incorporated places — imported 2026-09-18.** **Akron city `3901000` is present with geometry, 62.2741 sq mi** |
| `geofence_boundaries` G4040 | 1,590 | county subdivisions (Ohio townships), same import |
| `geofence_boundaries` G4210 | 340 | CDPs, same import |
| `geofence_boundaries` G5200 | 15 | congressional, TIGER 2024, imported 2026-04-02 |
| `geofence_boundaries` G5200V26 | 15 | **the 2025 congressional remap**, source `oh_orc_2025`, imported 2026-07-22 |
| `governments` "State of Ohio" | **1** | ✅ not Indiana's 18. `geo_id` `39`, type `STATE` |
| `chambers` under it | 5 | all statewide executives; **no legislative chamber** |

🟢 **OHIO IS THE FIRST KNIGHT SLICE THAT DOES NOT OWE A `place` LOAD.** Every earlier slice loaded
`place` as part of stage 1. Ohio's 925 G4110 records landed on **2026-09-18**, the same national
import that gave Pennsylvania its places hours before PA-1 opened. **Stage 1 here is `sldu` + `sldl`
and nothing else** — which also means the usual "did the place load work?" gate has nothing to
watch, so the stage-1 acceptance test has to be the legislative layers' own.

### What does not exist

- **No `STATE_UPPER` and no `STATE_LOWER` districts, and no `G5210`/`G5220` boundary rows.** Zero.
- **No state legislative offices.** Ohio holds **23 offices in total**: 15 U.S. House, 3 U.S. Senate,
  5 statewide executives.
  - ⚠ The third "U.S. Senate" office is **`Candidate for U.S. Senate — Ohio`, holding Sherrod
    Brown**. It is a candidate office, not a seat. The two real senators are Jon Husted and Bernie
    Moreno. Do not count 3 senators; do not delete the candidate row.
- **No government row for Akron and none for Summit County**, and no `districts` row for Akron —
  normal, because a `place` load writes a boundary and never a district.
- **No Ohio-shaped Indiana defect**: `chambers` matching `%discovery%` or `%unknown%` returns **0**
  nationally, and exactly one Ohio district carries a `government_id` (the NATIONAL_UPPER row).

---

## 🔴 Traps found while opening the slice

### 1. 🔴🔴 THE PROGRAM'S STANDING `offices_missing_terms` ASSERTION IS DEAD — THE BASELINE MOVED 823 → 427 IN TWO DAYS

Every wave from MN-2 to SC-4 closed by asserting `offices_missing_terms` **"unmoved at 823/655"**.
Measured today:

| | total | flagged `is_vacant` | unflagged |
| --- | --- | --- | --- |
| SC-4, 2026-09-20 | 824 | 169 | **655** |
| **OH, 2026-09-23** | **427** | **189** | **238** |

The view definition is unchanged (offices with no `office_terms` row at all), so this is data, not a
definition change. **It is a backfill, not a deletion, and that was established rather than assumed**:
`office_terms.created_at` shows **235 terms written 2026-09-22 and 627 on 2026-09-23**, and their
`source` strings name **`CA_0136`–`CA_0150`, an LA County school-board wave** — Chris Andrews'
namespace, a concurrent session, still running.

▶ **Any OH migration must assert against a baseline measured in the same session, immediately before
the write.** A gate carrying the constant 655 would now fail green-to-red for a reason that has
nothing to do with Ohio. This is the general form of the rule the program already knows: scope a gate
to what the migration creates, never to a number somebody else can move.

⚠ Four terms carry `created_at` of **2026-09-24** while today is 2026-09-23 — the column is UTC and
the clock is local. Harmless; do not read it as a future write.

### 2. 🔴🔴 OHIO'S OWN STATE GIS SERVICE PUBLISHES THE 2012–2022 MAP, AND IT IS UNREACHABLE ANYWAY

The obvious authority — the one a search puts first — is
`geo.oit.ohio.gov/arcgis/rest/services/OhioHouseSenateDistricts/MapServer`, and its layer 1 is titled
**"Ohio House Districts (2012- 2022)"**. That is the *superseded* map, named in a way that invites a
session to load it: this is Horry County's `CurrentCouncilDistricts` trap and Duluth's two council
maps, one tier up. **A layer's title is not its vintage.**

It is also **dead**: `curl` to that host fails to connect on **both 443 and 80** after ~21 s, twice.
Recording the negative with its exact test, per the program's rule that a negative result is only
ever true of the place you looked.

- `ohiosos.gov` answers WebFetch with **HTTP 403** — the documented "fetch it in Playwright" shape,
  not an absence. The Secretary of State's legal description of the adopted plan is at
  `https://www.ohiosos.gov/globalassets/elections/maps/2023-09-29_ohiohousesenatelegaldescription.pdf`
  and the adopted-map page at `sos.state.oh.us/SOS/reshape/GADistricts/adoptedMap.aspx` is where the
  state publishes its own shapefile and block-assignment file. **Neither has been fetched yet.**
- `ohiohouse.gov/members/district/<n>` and `ohiosenate.gov/senators/district/<n>` both **404**. The
  member pages are name-keyed (`ohiohouse.gov/members/veronica-r-sims`), so a district-number URL
  template will fail silently across all 99.

### 3. 🟢 THE VINTAGE EVIDENCE IS STRONG, AND OHIO GIVES A STRUCTURAL PROOF NO OTHER SLICE HAS HAD

**The operative map is the plan the Ohio Redistricting Commission adopted 2023-09-29**, unanimously
and with bipartisan support, upheld by the Ohio Supreme Court in November 2023, and therefore
governing **from the 2024 election through 2030**. So TIGER 2024 is the right vintage on its face.

Measured directly from the `.dbf` inside the raw Census zips (TIGER 2024 FIPS 39, downloaded
2026-09-23, HTTP 200, 1,202,114 and 2,034,425 bytes):

| | rows | MTFCC | LSY | non-numeric codes |
| --- | --- | --- | --- | --- |
| `tl_2024_39_sldu` | **33** | G5210 | 2024 | **none** — no `ZZZ` pseudo-district |
| `tl_2024_39_sldl` | **99** | G5220 | 2024 | **none** |

Ohio is **single-member in both chambers**, so polygon count equals seat count — unlike AZ/WA and
unlike ND/SD later in this program. `skipDistrictCodes` removes nothing here.

🟢 **AND THE NESTING PROVES THE PAIR.** Ohio Const. Art. XI requires each Senate district to be three
whole, contiguous House districts. Tested by taking each of the 99 House districts' own TIGER
interior point (`INTPTLAT`/`INTPTLON`) and locating it among the 33 Senate polygons:

- **99 of 99 House interior points fell in exactly one Senate district. Zero ambiguous, zero
  unmatched.**
- **All 33 Senate districts hold exactly 3 House districts.** The distribution is `{3: 33}`.

This is worth more than a count. A count can never date a map — Ohio's chambers have been 99 and 33
for decades. But a **2022 SLDL paired with a 2023 SLDU would not nest**, so the two files are proved
to be the same plan as each other, and the Commission's plan is the only one in force for 2024–2030.

⚠ **The detector was controlled.** Detroit and Pittsburgh both return **no** Senate and **no** House
district; five Ohio anchors each return exactly one of each.

### 4. 🔴 THE CONVENIENT SENATE↔HOUSE NUMBERING RULE IS FALSE, ON ALL 33

It is natural to assume Senate district *N* holds House districts *3N−2, 3N−1, 3N* — Ohio has
numbered them that way in past decades, and it would make the nesting derivable by arithmetic instead
of by geometry. **Measured: it fails for every one of the 33.** Senate 1 holds House **81, 82, 83**;
Senate 15 holds House **1, 2, 3**; Senate 28 holds House **32, 33, 34**.

▶ **The nesting is geometric and must be read from the polygons.** Anything that derives a senator
from a representative's district number will be wrong 33 times out of 33 and will look tidy doing it.

### 5. 🔴 `geo_id` COLLIDES WITH THE COUNTY LAYER INSIDE OHIO, AND WITH MISSISSIPPI ACROSS IT

TIGER writes the legislative `GEOID` as state FIPS + district code: Senate 31 is `39031`, House 71 is
`39071`. Ohio's 88 counties occupy `39001`–`39175`. So **every Senate `geo_id` and most House
`geo_id`s collide with an Ohio county's**. The key is **(mtfcc, geo_id)**, never `geo_id` alone —
`src/lib/geoIdGuard.ts` guards the production path, ad-hoc SQL does not.

🔴 **And there is already a live cross-state collision on Summit County's own id.** In
`geofence_boundaries`, `geo_id = '39153'` returns **two** rows:

| mtfcc | geo_id | name | state |
| --- | --- | --- | --- |
| G4020 | 39153 | Summit County | **39** |
| G6350 | 39153 | 39153 | **28** |

The second is a **Mississippi ZCTA** — ZIP 39153 is in Mississippi, and `geofence_boundaries.state`
holds 2-digit FIPS, so `28` is MS. ⚠ **Mississippi is slice 16 (Biloxi)**, so this one is live for a
future wave too. A Summit County query keyed on `geo_id` alone silently picks up a Mississippi ZIP.

### 6. 🔴🔴 SUMMIT COUNTY BREAKS THE SPEC'S "COUNTY OFFICER TEMPLATE IS STATE-SCOPED" ASSUMPTION

The program decomposes 26 cities into 16 state slices precisely because four things reuse across a
state, one of them **the county officer template, because state law defines it**. Ohio has 88
counties; 86 are statutory (3 Commissioners, Auditor, Treasurer, Recorder, Clerk of Courts, Coroner,
Engineer, Prosecutor, Sheriff). **Summit is not one of them.** It is one of only two Ohio charter
counties, and its charter replaces that list:

- a **County Executive** (there are no Commissioners),
- an **eleven-member County Council** — **8 by district, 3 at-large** (enlarged to 11 by the voters
  in 1988),
- and **five** row officers: **Clerk of Courts, Engineer, Fiscal Officer, Prosecutor, Sheriff**.

▶ **There is no Auditor, Treasurer or Recorder to seat** — the charter merged all three into the
**Fiscal Officer** — and no elected Coroner; Summit uses an appointed Medical Examiner. **An Ohio
statutory template applied here would invent four offices that do not exist and miss two that do.**
This is the repo's standing rule with a charter behind it: describe real powers, do not make
jurisdictions uniform. ⚠ It also means **slice 8's stage 4 buys nothing reusable for a later Ohio
county**, which is the opposite of what the spec's state-slice argument predicts. Say so in the
stage-4 plan so the reviewer is not surprised.

### 7. ⚠ BOTH LOCAL DISTRICT LAYERS ARE UNPROVEN, AND ONE IS PUBLISHED AS A PDF

- **Summit County Council districts:** the Council's own page offers a **"District Map (PDF)"**. That
  is the Lake County shape — PDF-only publication, the wave deferred seven seats over it. The county
  runs a GIS department; **ask it before concluding there is no layer**, and remember that IN-8's
  boundary was public all along in a *different* ArcGIS organisation from the one IN-6 swept.
- **Akron's 10 wards:** no layer measured yet. Akron's place polygon exists (62.2741 sq mi), so a
  ward layer can at least be closure-tested against it.
- ⚠ Neither layer's vintage has been asked about at all. Akron redistricted its wards after the 2020
  census; the date is not yet established.

---

## Expected scope

| Stage | Offices | Notes |
| --- | --- | --- |
| 2 legislature | **132** | 99 House + 33 Senate, single-member both chambers |
| 3 Akron | **14** | Mayor + 3 at-large + 10 ward. Mayor **Shammas Malik**, sworn in 2024-01-01 |
| 4 Summit County | **17** | Executive + 11 Council + 5 row officers |
| **total** | **163** | plus 1 banner key `akron` and ~163 portraits at stage 5 |

⚠ These are **sizes, not rosters.** Nobody has been change-checked. Municipal court judges are out of
scope, with the judges wave, as in every earlier slice.

🔴 **Akron's four-answer probe currently scores 0 of 4** — no council member, no county council
member, no state representative, no state senator. Measured today: Akron holds no office of any kind.
Stage 2 must precede stage 3, or the probe can never score better than 2 of 4.

**Anchors for that probe, measured from raw TIGER 2024 and controlled:**

| anchor | Senate | House |
| --- | --- | --- |
| Akron City Hall, 166 S High St | **28** | **33** |
| Summit County Courthouse, 209 S High St | 28 | 33 |
| University of Akron, Buchtel Ave | 28 | 33 |
| Kenmore, west Akron | 28 | **32** |
| Cuyahoga Falls City Hall | **27** | **31** |
| CONTROL — Detroit, MI | none | none |
| CONTROL — Pittsburgh, PA | none | none |

🟢 **One identity anchor already agrees with an independent source**: House District 33 is
**Veronica Sims (D–Akron), serving since 2024** — the district TIGER puts Akron City Hall in, held by
an Akron member seated under the 2023 plan. That is one anchor, not a proof; OH-1 owes the rest.

---

## Next steps, in order

1. **Prove the vintage against Ohio's own authority, not the Census's `LSY` field.** Fetch the SOS
   adopted-map shapefile (`sos.state.oh.us/SOS/reshape/GADistricts/adoptedMap.aspx`) **in Playwright**
   — `ohiosos.gov` 403s a plain fetch — and compare it against TIGER at each TIGER polygon's own
   interior point, the way GA-1 closed its vintage check. If the shapefile cannot be had, fall back to
   identity anchors against the legislature's address lookup, and record which was used.
2. **Add `OH` to `STATE_LAYER_ALLOWLIST`** in `backend/scripts/load-state-tiger-boundaries.ts` as
   `new Set(['sldu', 'sldl'])` — **not** `place`, which is already loaded and must not be disturbed —
   with the measurement above written into the comment beside it, and an OH pre-flight block asserting
   **33** and **99**, the single-member equality, and the 3-into-1 nesting.
3. **Run OH-1**: 132 boundaries, 132 districts, 0 errors. Loader re-run must be clean.
4. **OH-2**: seat the General Assembly. Reconcile the roster from the chambers' own member lists and
   Open States, then **change-check all 132 member pages individually** — MN-2 found a member listed
   three months after he resigned, with no vacancy marker anywhere.
5. **OH-3 Akron**, then **OH-4 Summit**, then **OH-5 assets**.

🔴 **Before any migration: `npm run steward --prefix backend -- slot CC --purpose "..."`.** No slot is
reserved for this slice yet, because nothing is written. Stage 1 needs none — the TIGER loader writes
boundaries and districts directly, as in SC-1 and PA-1.
