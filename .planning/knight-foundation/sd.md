# SD — slice 15 (Aberdeen · Brown County)

Program tracker: [`PROGRAM.md`](./PROGRAM.md) · spec:
[`2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md)

**Opened 2026-09-28.** Lease `state:sd` held by chris@empowered.vote on DESKTOP-G6KDNN2, until
2026-09-29 07:08Z. Worktree `C:\ev-accounts-sd`, branch `knight/sd-slice15`, cut from
`origin/master` at `b200979f`.

| Stage | State |
| --- | --- |
| 1 geography | ✅ **APPLIED 2026-09-28 — 72 boundaries, 72 districts, 35 Senate + 37 House, 0 errors.** Only `sldu` + `sldl` were owed; vintage PROVED against the SD Legislature's own adopted-map layer |
| 2 legislature | ✅ **APPLIED 2026-09-28 — 105 offices, 105 seated, 0 vacant, EVERY TERM DATED TO THE DAY** (`CC_0163`/`CC_0164`) |
| 3 city waves | ▶ **OPEN, FROM ZERO.** Aberdeen holds no government row, no chamber and no office |
| 4 county waves | ▶ **OPEN, FROM ZERO.** Brown County holds no government row, no chamber and no office |
| 5 assets | — not started. No `aberdeen` banner key |

---

## ✅ MEASURED 2026-09-28 — THE HOUSE IS 37 POLYGONS FOR 70 SEATS, AND THE STRUCTURE IS PROVED

Measured from the TIGER files themselves by
[`backend/scripts/measure-sd-tiger-legislative.mjs`](../../backend/scripts/measure-sd-tiger-legislative.mjs).
The count is taken **twice by independent routes** — the `.dbf` header's own record count (bytes
4..7, read with no shapefile library) and the number of feature rows the reader yields — and a
**positive control runs first**: a bogus FIPS 99 must 404, or the counts prove nothing. It did.

| | polygons | seats |
| --- | --- | --- |
| Senate `sldu` | **35** | **35** |
| House `sldl` | **37** | **70** |

**TIGER 2024 FIPS 46, measured:**

- `sldl` **37 records**, MTFCC `G5220`, `FUNCSTAT N`, 0 `ZZZ`. Codes `001`-`025`, `027`,
  `029`-`035` — **33 whole districts** — plus **`26A`, `26B`, `28A`, `28B`**. `NAMELSAD` reads
  `State House District 26A`, and so on.
- `sldu` **35 records**, MTFCC `G5210`, 0 `ZZZ`, codes `001`-`035` **contiguous, no letters**.

🔴 **THERE IS NO `026` AND NO `028` POLYGON IN THE HOUSE FILE.** TIGER files those two districts
**only** as their subdistricts. The Senate keeps both **whole**. So the House code set is
deliberately **not contiguous**, and a gate asserting `001..035` contiguous **fails correctly** on
the House. Do not fill the gap.

▶ So the seat arithmetic is **33 × 2 + 4 × 1 = 70**, and the four subdistricts are exactly
26A/26B/28A/28B — **no others**. The claim carried into this slice is now proved against the file
rather than assumed, and 70 is *derived* here, not asserted.

🔴🔴 **70 WOULD HAVE BEEN THE SAME TOTAL ON A WRONG STRUCTURE** (a flat 35 × 2 is also 70), which is
why the polygon count and not the seat count was the measurement. Neither earlier gate carries over:

- **MI-4's "exactly one office per district"** is false here on all 33 whole districts.
- **ND's "48 polygons / 94 seats"** is the right *shape* with the wrong numbers. **SD's gate is:
  exactly two offices on each of the 33 whole districts, exactly one on each of 26A/26B/28A/28B,
  70 in total, and no office on any `026` or `028` district because no such district exists.**

⚠ **A South Dakota House district is NOT an integer**, exactly as ND-1 found with `4A`/`4B` — read
[`nd.md`](./nd.md) § "A NORTH DAKOTA HOUSE DISTRICT IS NOT AN INTEGER". Three traps, all measured:

- 🔴 **Never cast the code to a number, and never reuse a helper that validates it as numeric.**
  `normaliseCode` in `verify-ks-tiger-vintage.mjs` **throws** on `26A` by design.
- 🔴 **The padding rule differs inside one field.** Numeric codes are zero-padded to three
  (`004`); lettered ones are not (`26A`, never `026A`). `GEOID` is FIPS + code, so `46004` and
  `4626A` are both five characters.
- 🔴 **An ASCII sort misplaces the subdistricts** — `26A` sorts *after* `035` because `0` < `2`.
  Numerically they sit between `025` and `027`. Sort on a parsed (number, letter) pair.

### 🔴🔴 THE COUNT CANNOT DATE THE MAP, AND NEITHER CAN THE CODE SET

Measured across four vintages on 2026-09-28. **Every one is 37 records with the identical code
set** — including TIGER 2020, which carries the **superseded pre-2021 plan**:

| vintage | `sldl` records | `LSY` | code set |
| --- | --- | --- | --- |
| TIGER 2020 | 37 | 2018 | same 33 + 26A/26B/28A/28B |
| TIGER 2022 | 37 | 2022 | same |
| TIGER 2024 | 37 | 2024 | same |
| TIGER 2025 | 37 | 2024 | same |

South Dakota's subdistrict structure **survived the 2021 redistricting unchanged**, so a count
check, a letter check and a code-set check **all pass on a decade-old superseded map**. This
reproduces the Kansas and Kentucky findings inside South Dakota.

⚠ **`LSY` looks like a discriminator and is not** — it tracks the Census refresh, not the plan, the
same trap KS-1 documented.

---

## ✅ THE VINTAGE IS PROVED 2026-09-28 — TIGER 2024 CARRIES THE 2021 ADOPTED MAP

[`backend/scripts/verify-sd-tiger-vintage.mjs`](../../backend/scripts/verify-sd-tiger-vintage.mjs).

### 🟢 THE AUTHORITY IS THE LEGISLATURE'S OWN LAYER, AND IT PUBLISHES BOTH PLANS

`sdlegislature.gov`'s "Find My Legislators" viewer is an ArcGIS map whose district geometry is
served as plain GeoJSON from the Legislature's own host. Its redistricting page links the live
layer as **"2021 Adopted Map"** (`Legislators/Find?activeLayer=2021`), and the viewer loads **both**:

| | URL | features |
| --- | --- | --- |
| adopted | `https://sdlegislature.gov/redistrictingFeatureLayer.geojson` | **39** |
| superseded | `https://sdlegislature.gov/2010redistrictingFeatureLayer.geojson` | **39** |

**Publishing the superseded plan beside the live one is what makes this a real test.** The same
comparison runs against both, and only one may return zero. Kentucky had to settle for a
current-geometry service; South Dakota, like Kansas, hands over the artifact.

🔴 **The site is a JavaScript SPA, and a plain fetch of its HTML returns a "use a modern browser"
shell that reads like a real page.** The GeoJSON URLs were found by rendering the viewer in
Playwright and reading its network traffic — not by scraping HTML. A `WebFetch` of the
redistricting home page returned three links, all of them browser download pages.

### 🔴🔴 THE AUTHORITY LAYER HAS 39 FEATURES, AND THE OVERLAP IS THE POINT

Both files carry **1-35 plus 26A, 26B, 28A, 28B**. That is **one layer serving both chambers**: 26
and 28 are whole **Senate** districts that split into single-member **House** subdistricts, so
**26A and 26B lie INSIDE 26** and a naive point-in-polygon lookup returns two answers.

▶ So the comparison narrows the authority per chamber *before* locating anything:

| against | authority subset | size |
| --- | --- | --- |
| `sldu` (35) | 1-35, subdistricts **excluded** | **35** |
| `sldl` (37) | 1-35 minus 26 and 28, subdistricts **included** | **37** |

🟢 **Those two subsets come out at exactly 35 and 37** — an independent confirmation of the TIGER
counts, from a source that has never seen a TIGER file.

### The result

| TIGER vintage | vs adopted plan | vs 2010 plan | verdict |
| --- | --- | --- | --- |
| 2020 | 7 / 7 moved (80.0% / 81.1%) | **0 / 0 moved** | 🔴 carries the **superseded** plan |
| 2022 | **0 / 0 moved** | 7 / 7 moved | ✅ adopted |
| **2024** | **0 / 0 moved (100%)** | 7 / 7 moved (80.0% / 81.1%) | ✅ **adopted — this is the load vintage** |
| 2025 | **0 / 0 moved** | 7 / 7 moved | ✅ adopted |

*(Senate / House. "Moved" = the TIGER district's own internal point lands in a differently numbered
authority district.)*

⚠ **A THRESHOLD TEST PASSES THE SUPERSEDED MAP HERE, exactly as in ND and KS.** TIGER 2020 still
agrees with the adopted plan on **28 of 35 Senate and 30 of 37 House** districts — 80% and 81%.
**The discriminator is that the correct plan moves EXACTLY ZERO and the wrong one does not.**
Anyone relaxing `MOVED === 0` to "most districts agree" re-admits the 2010 plan.

The seven that moved are the same seven in both chambers, because SD's House districts are its
Senate districts (split only at 26 and 28):

| district (adopted) | was, under the 2010 plan | internal point |
| --- | --- | --- |
| 2 | 25 | 43.56556, -96.55920 |
| 8 | 22 | 44.23210, -97.24072 |
| 15 | 9 | 43.57064, -96.74050 |
| 20 | 8 | 43.94537, -98.25638 |
| 22 | 2 | 44.71227, -98.29160 |
| 25 | 8 | 43.87210, -96.75352 |
| 34 | 33 | 44.07340, -103.29828 |

### The controls, all of which fire

1. **A bogus FIPS 99 must fail to download.** It 404s.
2. **Each authority layer must locate its own features to themselves.** 0 conflicts on all four
   subsets. 🔴 **This control FAILED on its first construction and the failure was real, not
   cosmetic**: it probed with a *mean of the polygon's vertices*, which is **not** an interior
   point — district 25's vertex mean lands inside district 8. Replaced with a true
   point-on-surface (scan a horizontal line across the bounding box, take the midpoint of the
   widest interior span), which is inside by construction for any concave or multi-part shape.
3. **The wrong-plan comparison must return non-zero.** It returns 7 / 7.
4. **The script must REFUSE the superseded vintage.** Run at `VINTAGE=2020` it exits 1 with
   *"CARRIES THE SUPERSEDED 2010 PLAN — DO NOT LOAD IT"*.

🔴 **The verdict branch was also wrong once, and it is worth recording**: the first version
reported a matched *superseded* vintage as "control 3 did not fire", which is a **gate aborting
for the wrong reason**. Every branch now names the condition it actually found.

---

## ✅ SD-1 APPLIED 2026-09-28 — SOUTH DAKOTA HAS LEGISLATIVE GEOGRAPHY FOR THE FIRST TIME

**72 boundaries and 72 districts — 35 Senate + 37 House — 0 errors, 0 already existed, 0 skipped.**

| | baseline | after | delta |
| --- | --- | --- | --- |
| `districts` (all) | 10,455 | 10,527 | **+72 exact** |
| `geofence_boundaries` (all) | 72,636 | 72,708 | **+72 exact** |
| `districts` SD | 73 | **145** | +72 |
| `geofence_boundaries` FIPS 46 | 2,147 | **2,219** | +72 |
| `offices_missing_terms` | 422 / 238 unflagged | **422 / 238** | **unmoved** |

Both totals moved by exactly 72 and nothing else moved. Baseline measured in the same session,
minutes before the write.

**Geometry:** 35 `G5210` + 37 `G5220`, **all 72 valid**, SRID **4326**, 0 NULL, 35 and 37 distinct
`geo_id`, 35 and 37 distinct `ocd_id`.

🟢 **THE `08A` COLLAPSE DID NOT HAPPEN.** 37 House districts carry **37 distinct `ocd_id`s**, and 4
of the 37 `geo_id`s carry a letter. `ocdDistrictSuffix()` kept it; `parseInt` would have merged
26A with 26B and 28A with 28B into 35.

### End-to-end, measured against production after the apply

| probe | Senate | House | County |
| --- | --- | --- | --- |
| **Aberdeen City Hall** | District 3 | District 3 | **Brown County** `46013` |
| Brown County Courthouse | District 3 | District 3 | Brown County |
| House 26A internal point | **District 26** | **District 26A** (`geo_id` `4626A`) | Mellette |
| House 28B internal point | **District 28** | **District 28B** (`geo_id` `4628B`) | Harding |
| Rapid City City Hall | District 32 | District 32 | Pennington |

🟢 **The split chamber works end to end**: one point returns a *whole* Senate district and a
*lettered* House subdistrict, and the letter survived all the way into `geo_id`.

🔴 **THE COUNTY `geo_id` COLLISION IS NOW LIVE AND VISIBLE IN THIS TABLE.** Senate District 3 is
`46003` — and so is **Aurora County**. The probe above is only correct because it pairs `geo_id`
with `mtfcc`. Measured: 66 SD counties run `46003`..`46137` odd, **17 of them inside the Senate
range**, and **Brown County `46013` collides with Senate District 13**. The four subdistricts are
safe by construction — `4626A` ends in a letter and cannot collide with a numeric county GEOID.

🟢 **The probe was controlled.** Fargo ND, Sioux City IA and a mid-Atlantic point each return
**0** SD districts, so a match means something.

### Gates

`check:occupancy` green (3 files scanned, no writes to the dropped column).
`check:migrations` green (0 added, 2,172 slots across 392 refs, tree scan clean).
**No migration was needed** — the loader writes geometry directly.

### Every assertion was watched failing first

| control | fires |
| --- | --- |
| `SD_PREFLIGHT_CONTROL=count` | MTFCC assertion — "expected 34, got 35" |
| `SD_PREFLIGHT_CONTROL=anchor` | vintage assertion |
| `SD_PREFLIGHT_CONTROL=weak` | discrimination assertion — "only 0 of 6 anchors distinguish" |
| **`--vintage 2020`** (a real superseded map, no flag needed) | vintage assertion, naming the 2010 plan |

🔴🔴 **AND THE `anchor` CONTROL CAUGHT A REAL DEFECT IN MY OWN GATE — THE SAME ONE KANSAS'S FIRED
TWICE BEFORE IT WAS RIGHT.** The first diagnosis asked *"did every failure land on its prior value,
and was at least one failure discriminating?"*. Perturbing Aberdeen City Hall's expected code from
`3` to `999` satisfies both trivially — `999 !== 3` **makes it look discriminating** while it lands
on `3`, its prior — so a **corrupted anchor table was diagnosed as "THIS FILE IS THE SUPERSEDED
2010 PLAN"**. Wrong: the file was right and the table was wrong.

▶ **The correct test is a statement about the whole discriminating set**: this file is the 2010 plan
only if **every** anchor that distinguishes the plans failed onto its 2010 value. One failure out of
seven cannot be a different map, because six anchors still name the adopted one. Now:

- tamper → *"Only 1 of 8 discriminating anchors failed, so this is NOT simply the 2010 plan —
  suspect … an edited anchor table."*
- `--vintage 2020` → *"ALL 7 discriminating anchors failed onto their 2010 value — THIS FILE IS THE
  SUPERSEDED 2010 PLAN."*

### What the loader gained

`STATE_LAYER_ALLOWLIST.SD = ['sldu','sldl']` and a `fipsArg === '46'` pre-flight asserting: record
count, distinct OCD-ID suffixes, the exact subdistrict set, **the ABSENCE of whole `026`/`028`
House polygons**, the seat arithmetic `33×2 + 4 = 70`, and 15 anchors of which **at least 4 must
discriminate**.

🔴 **SD's anchors compare STRING codes, where Kansas's compare `parseInt`.** Kansas has no lettered
districts so its shortcut is safe there; here it would silently pass a House anchor that landed in
the wrong half of a split district. Every SD comparison runs through `ocdDistrictSuffix()`.

🔴 **Kansas's contiguity assertion is deliberately NOT copied.** South Dakota's House code set is
legitimately non-contiguous, so that check would fail correctly. The SD equivalent is the opposite
shape: `026` and `028` are asserted **absent**.

---

## ✅ SD-2 APPLIED 2026-09-28 — THE SOUTH DAKOTA LEGISLATURE IS SEATED

`CC_0163` (structure) + `CC_0164` (occupancy): **105 offices — 35 Senate + 70 House — 105 seated,
0 vacant, 104 people created + 1 more under a lifted namesake guard, 0 reused.**

| | baseline | after | delta |
| --- | --- | --- | --- |
| `politicians` | 89,361 | 89,466 | **+105 exact** |
| `office_terms` | 9,842 | 9,947 | **+105 exact** |
| SD chambers | 5 | **7** | +2 |
| SD legislative offices | 0 | **105** | +105 |
| `offices_missing_terms` | 422 / 238 | **422 / 238** | **unmoved** |

House 70 offices / 70 seated / **70 distinct people**; Senate 35 / 35 / **35 distinct people**.

### 🟢 EVERY ONE OF THE 105 TERMS IS DAY-PRECISION. NONE IS `unknown`.

That is unusual — ND-2 wrote 133 of 141 open-ended — and it is possible only because South
Dakota's Legislature publishes its own dated oath record and its Governor publishes his own dated
appointments.

| terms | date | `how_started` | source |
| --- | --- | --- | --- |
| 98 | 2025-01-14 | `elected` | first-day oath lists, Journal of the House (doc 274999, 68 names, oath by Justice Patricia J. DeVaney) and Journal of the Senate (doc 274997, 33 names, oath by Chief Justice Steven R. Jensen); **plus Rep. Peri Pourier**, whose oath the 2nd-day House journal records as taken *"at 1:15 p.m. on Tuesday, January 14, 2025"* |
| 2 | 2025-01-15 | `elected` | Sens. **Sydney Davis** and **Larry Zikmund**, excused on day one; the 2nd-day Senate journal (doc 274998) records their oath, administered by President Larry Rhoden |
| 5 | various | `appointed` | the Governor's own announcements — Kolbeck H-13 **2025-02-05**, Czmowski H-06 **2025-02-12**, Wipf S-22 **2025-07-10**, Fosness H-01 **2025-08-05**, Shubeck H-16 **2025-09-17** |

✅ **Every appointment date falls AFTER its predecessor's departure date** — checked, not assumed.
Venhuizen left 2025-01-29, Wheeler 2025-04-24, Reder 2025-05-01, Vasgaard 2025-08-27. Czmowski is
the fifth because District 6 was certified with only **one** representative on day one.

### 🔴 THE OATH LIST AND THE ROLL CALL ARE DIFFERENT EVENTS, AND CONFUSING THEM LOSES A MEMBER

Rep. **Keri K. Weems** appears in the first-day oath list **and** in the *"excused"* line of the
same day's roll call. Matching on the roll would have sent her for research she did not need. Only
Pourier, Davis and Zikmund are genuinely absent from an oath list. **Match on the oath list.**

### 🔴 A ROSTER LABEL SAYS HOW SOMEONE ARRIVED, NOT WHEN

`MemberTermName` carries "New Member" (40), "Incumbent" (53), "Governor's Appointment" (5) and
"Other House" (7). None is a date. **"Other House" means only that the member previously served in
the other chamber** — all 7 were elected to their current seat in November 2024 and took the
first-day oath with everyone else. Only the 5 appointments start on a different day.

### ⚠ A SEARCH SUMMARY CONTRADICTED THE PRIMARY DOCUMENT, AND THEN TURNED OUT RIGHT

A web search claimed Pourier was sworn at 1:15 p.m. on the first day. The **first-day journal
contradicts it** — she is absent from that day's oath list and excused from every roll. The claim
was true, but its evidence sits in the **second** day's journal. The date written to production
comes from that document. ▶ A summary is a lead; it is never the source, even when it is correct.

### 🔴 ONE NAME COLLIDES WITH A DIFFERENT PERSON

Production already held a **`Lauren Nelson`** (external_id -840005) — the **El Paso County
Commissioner for District 5, in COLORADO**, not South Dakota's senator for District 18. The row was
**not reused**; a new person was created with the duplicate-name guard lifted for that one
statement. Checked, not assumed — 2 of 4 name hits in the GA wave were a Colorado senator and a
Utah treasurer.

### 🔴 THE CONSTITUTION CANNOT VERIFY THE COUNTS, UNLIKE KANSAS

S.D. Const. art. III § 2 sets only **ranges** — the house *"not less than fifty nor more than
seventy-five"*, the senate *"not less than twenty-five nor more than thirty-five"*. 70 is merely
inside the range and 35 is the maximum permitted. Neither number is fixed by law; both come from
the apportionment act. ✅ **Three independent sources agree on 70/35 and on the structure**: TIGER
(37 + 35 polygons), the Legislature's own adopted-map GeoJSON (39 features = 35 + 4 subdistricts),
and the 101st-session member roster (70 representatives over 33 two-member districts plus
26A/26B/28A/28B, 35 senators). § 6 **does** fix the term at two years, both chambers.

### ⚠ THE PRIOR SESSION'S ROSTER IS CUMULATIVE AND WOULD HAVE SEATED 109 INTO 105

The 100th session (2025) list returns **109** — 105 seats plus the four members who left, each
carrying an `InactiveDate`. Because South Dakota's House is legitimately two-per-district, *"three
in a district"* would have survived a shape check that a single-member state would have caught at
once. The 101st-session roster returns exactly 105 with 0 `InactiveDate`.

### End-to-end, measured against production after the apply

| probe | answers |
| --- | --- |
| **Aberdeen City Hall** | **3** — Sen. **Carl Perry** (D3), Reps. **Al Novstrup** and **Brandei Schaefbauer** (D3) |
| House 26A internal point | **2** — Sen. **Tamara R. Grove** (D26 **whole**), Rep. **Eric Emery** (D26A **only**) |

🟢 The split chamber works end to end on occupancy as well as geography: a whole district
returns **two** representatives and a subdistrict returns **one**. All three Aberdeen names match
the Journal's own District 3 roll, read independently.

### Gates

Structure gate asserts: 1 host government, 2 chambers, 35 + 70 offices, **exactly 2 offices on each
of the 33 whole House districts and exactly 1 on each subdistrict**, the **ABSENCE** of any whole
`46026`/`46028` STATE_LOWER district, no COUNTY district holding a legislative office, 0 vacant, and
**exactly 2 distinct titles** (South Dakota ballots carry no seat number, so no `(Seat 1)` slip).

Occupancy gate asserts: 105 people in the reserved band, 105 terms, 35 + 70 seated **counting
`och.politician_id` rather than `*`**, **every term day-precision**, 100 `elected` + 5 `appointed`,
every person `is_incumbent`, **each whole House district holding two DISTINCT people**, and no
person holding two SD legislative seats.

`check:occupancy`, `check:migrations` and `check:reservations` all green. Dry-run was a real
`BEGIN … ROLLBACK` against production through `psql` as `ev_api`, and **the rollback was verified
to have reverted** before the apply.

🟢 The reserved `external_id` band `-2766000 .. -2765896` was **measured empty** first — ND-2's
first choice was already occupied.

▶ **Next: SD-3, Aberdeen — office inventory UNREAD.**

▶ **The program's four-answer probe will return FIVE answers in South Dakota** on a whole district
— council member, county commissioner, state senator, and **two** state representatives — and
**four** inside 26A/26B/28A/28B. Neither count is a defect. Aberdeen's own district must be
established before the probe is written, because which of the two shapes applies there decides what
the probe asserts.

---

## Baseline as measured when the slice opened, 2026-09-28 — before anything was written

Measured against production (`supabase-local` MCP) in this session. **Nothing has been written.**

### What already exists

| Thing | Count | Note |
| --- | --- | --- |
| `governments` for SD | **1** | `State of South Dakota`, `geo_id` **46**, id `29fbd5e8-ef43-456b-b89f-2d170062a3b8` |
| `chambers` under it | **5** | one per statewide executive |
| `offices` under it | **5** | Governor, Lieutenant Governor, Attorney General, Secretary of State, Treasurer — **all 5 seated, none vacant** |
| `districts` `STATE_EXEC` | 5 | the seats above |
| `districts` `COUNTY` | **66** | every SD county, including **Brown County `46013`** |
| `districts` `NATIONAL_UPPER` | 1 | |
| `districts` `NATIONAL_LOWER` | 1 | SD's at-large House seat |
| `geofence_boundaries` `G4110` place | **310** | includes **Aberdeen city `4600100`** |
| `geofence_boundaries` `G4020` county | **66** | |
| `geofence_boundaries` `G4040` cousub | **1219** | townships, loaded by `feat/ks-nd-sd-townships` (merged) |
| `geofence_boundaries` `G4210` CDP | 175 | statistical |
| `geofence_boundaries` `G6350` | 376 | ZCTAs |
| `geofence_boundaries` `G5200` | 1 | the at-large congressional district |
| `treasury` budgets | **18** City of Aberdeen (2016-2024) · **8** Brown County (2016-2024) · 48 State of South Dakota (2002-2025) | the only Aberdeen data that exists today |

### What does not exist

- 🔴 **No `sldu` and no `sldl` polygon for FIPS 46 — zero of each.** SD and MS are the last two
  states in the program's geofence table owing them, and they are the only rows that block address
  reachability.
- 🔴 **No legislative office. 0/70 House, 0/35 Senate.** There is no legislature government row, no
  House chamber and no Senate chamber.
- 🔴 **No Aberdeen government, chamber, office or `districts` row.** The city exists only as a TIGER
  polygon and a budget.
- 🔴 **No Brown County government, chamber or office.** The `districts` row exists and carries
  **0 offices**.
- **No `aberdeen` banner key**, and no SD portrait anywhere outside the 5 statewide executives.

### Program-wide baseline measured in the same session

`essentials.offices_missing_terms`: **422 total · 184 flagged `is_vacant` · 238 unflagged.**

⚠ The unflagged count is **238**, matching the 2026-09-24 baseline exactly; the total has fallen by
one (423 → 422). **238 unflagged is the number to hold.** Re-measure immediately before each write
— this figure has no standing value between sessions.

---

## Anchors — bind on these, never on a name

| Anchor | Key | Why it matters |
| --- | --- | --- |
| Aberdeen city | `place` / **`4600100`** | the stage-3 subject |
| Aberdeen city (MCD) | `cousub` / `4601300100` | 🔴 **a SECOND "Aberdeen city" polygon** |
| Aberdeen township | `cousub` / `4601300140` | 🔴 **a THIRD "Aberdeen"** |
| Brown County, SD | `county` / **`46013`**, district id `c1c642b8-3d72-45d3-807f-dce2e2857733` | the stage-4 subject |

🔴🔴 **"Aberdeen" RESOLVES THREE WAYS INSIDE SOUTH DAKOTA ALONE** — one incorporated place and two
county subdivisions, one of which carries the *same* name string, `Aberdeen city`. A match on name
returns all three. **Bind on (mtfcc, geo_id).**

🔴🔴 **"Brown County" RESOLVES NINE WAYS ACROSS THE DATABASE** — measured 2026-09-28, `districts`
holds a Brown County in **IL `17009`, IN `18013`, KS `20013`, MN `27015`, NE `31017`, OH `39015`,
SD `46013`, TX `48049` and WI `55009`**. Indiana's is filed as **nine separate rows**, one per
elected officer (`Brown County Sheriff`, `Brown County Auditor`, …), so a `LIKE 'Brown County%'`
match returns 17 rows for 9 counties. **Bind on (mtfcc, geo_id).** This is the same key rule as the
1,159 known `geo_id` collisions — see `src/lib/geoIdGuard.ts`.

⚠ `treasury.municipalities` already holds its **own** `Brown County` row scoped `SD`
(`e3fe197e-5d8b-41e1-a308-db939851bacd`). It is a different table with a different key and is not a
government row. It does not satisfy stage 4.

---

## Expected scope

| Stage | Expected | Confidence |
| --- | --- | --- |
| 1 geography | `sldu` **35** + `sldl` **37** = **72 polygons / 72 districts** | ✅ **MEASURED 2026-09-28** |
| 2 legislature | **105 offices** — 70 House + 35 Senate | ✅ seat total now **derived** (33x2 + 4) |
| 3 Aberdeen | unknown — the office inventory has not been read | **nothing read yet** |
| 4 Brown County | unknown — the office inventory has not been read | **nothing read yet** |
| 5 assets | portraits for everything seated, plus an `aberdeen` banner | |

⚠ **Aberdeen's and Brown County's office inventories are NOT yet known and must not be guessed.**
ND-3 found Grand Forks elects **nine** offices, not eight, because a Municipal Judge is elected and
named in one sentence on a court staff page; ND-4 found Grand Forks County elects **seven** and its
commission sits **at large with no districts**. Read the city's own code and the county's own
charter. Do not standardise the municipality — `backend/data/seed-<place>/ROSTERS.md` first.

---

## Next steps, in order

1. ✅ **SD-1 measurement — DONE 2026-09-28.** `sldl` **37**, `sldu` **35**, subdistricts
   `26A`/`26B`/`28A`/`28B`, no `026` or `028` polygon. Script
   `backend/scripts/measure-sd-tiger-legislative.mjs`, which asserts that shape and was watched
   failing on a tampered count **and** on a tampered subdistrict list.
2. ✅ **Prove the vintage — DONE 2026-09-28.** TIGER 2024 carries the **2021 Adopted Map**: 0 of 35
   Senate and 0 of 37 House districts moved against the SD Legislature's own layer, while the same
   test against its published **2010** layer moves 7 and 7. Script
   `backend/scripts/verify-sd-tiger-vintage.mjs`, which refuses TIGER 2020 by name.
3. ✅ **Add SD to `STATE_LAYER_ALLOWLIST` — DONE 2026-09-28**, with the measurement that justifies
   its numbers in the comment and a `fipsArg === '46'` pre-flight block. 🔴 **This is the program's
   hottest shared file** — merge `master` into this branch early and often, in this worktree.
4. ✅ **Dry-run, then apply SD-1 — DONE 2026-09-28.** Both tables moved by **exactly +72** and
   nothing else moved; `offices_missing_terms` unmoved at 422/238.
5. ▶ **SD-2 — NEXT**: read the legislature's own roster; establish the term-start dates from the body's own
   record, never computed. Then SD-3 and SD-4 on Aberdeen and Brown County.

---

## Debts and open questions this slice already owes

- ✅ ~~The House structure is unproved.~~ **CLOSED 2026-09-28 — 37 `sldl` polygons, 33 whole + four
  subdistricts `26A`/`26B`/`28A`/`28B`, and those are the only splits.**
- ✅ ~~The vintage is unproved.~~ **CLOSED 2026-09-28 — TIGER 2024 carries the 2021 Adopted Map,
  proved geometrically against the SD Legislature's own layer, with the superseded 2010 layer as
  the control that makes the test able to fail.**
- 🔴 **Aberdeen's office inventory is unread**, and so is Brown County's.
- ⚠ **Which legislative district Aberdeen sits in is unknown**, so the acceptance probe cannot be
  written yet — and whether it asserts four answers or five depends on it.
- ⚠ **No `SD` entry exists in the TIGER loader allowlist**, though line 742 already maps FIPS `46` to
  `sd`. The existing SD polygons came from earlier national loads, not from this script.
