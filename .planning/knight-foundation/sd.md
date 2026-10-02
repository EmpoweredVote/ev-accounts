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
| 3 city waves | ✅ **APPLIED 2026-09-28 — 9 offices, 9 seated, 0 vacant, 7 terms DATED + 2 honestly unknown** (`X0072`, `CC_0165`/`CC_0166`) |
| 4 county waves | ✅ **APPLIED 2026-09-28 — 10 offices, 10 seated, 0 vacant, 8 terms DATED + 2 honestly unknown, NO GEOMETRY LOADED** (`CC_0167`/`CC_0168`) |
| 5 assets | ▶ **PART DONE.** ✅ **`cities/aberdeen.jpg` SHIPPED 2026-09-28**. 🟢 **THE LRC REPLIED 2026-09-29: permission rests with each member, not the Council.** `CC_0184` APPLIED — the 105 are marked *restricted* and the site now explains itself. ▶ Open: sweep for non-LRC sources; `photo_license` still `unknown` on all 105 |

### ▶ RESUMING THIS SLICE — read this before touching anything

**Stages 1-4 are APPLIED. SD-5 is part done. THE REPLY HAS ARRIVED — the wait is over.**

🔴🔴 **THE LRC LETTER WAS SENT 2026-09-28. DO NOT SEND IT AGAIN.** It went from
`chris@empowered.vote` to `LRC@sdlegislature.gov`. The text, **the reply**, and how to read it are
in [`letters/2026-09-28-sd-legislature-portrait-permission.md`](./letters/2026-09-28-sd-legislature-portrait-permission.md).

🟢 **THE COUNCIL REPLIED 2026-09-29, 10:59:** *"You will need to ask each legislator individually as
they are the ones who can grant permission for use."* **That is a routing, not a refusal** — read
the letter file before describing it as one, in a commit message or on the site.

⚠ **THIS SUPERSEDES THE LINE THAT STOOD HERE: "on a refusal the fallback is no portrait, never a
news or campaign photograph."** That sentence assumed the body we asked *held the right and said
no*. It said the opposite: it does not hold the right. So the standing programme rule applies
again unchanged — the 2026-07-08 ruling, which **approves campaign sites, official rosters and
candidate-submitted Ballotpedia/Citizens Count photos**, and still bars news photography, personal
social media and mugshots. Nothing about South Dakota narrows it.
🔴 **The one South Dakota exception**: a candidate source that turns out to BE the Legislature's
file is still barred. Measured — Spencer Gosch's Ballotpedia portrait is exactly that, re-cropped,
and it looks like a different picture at thumbnail size. **Compare every candidate image against
`lawmakerdocuments.blob.core.usgovcloudapi.net` before importing it.**

▶ **`photo_license` still stays `unknown` on all 105 for the LEGISLATURE'S portraits** — a routing
moves nothing. A portrait imported from an approved non-LRC source carries that source's own
licence note instead, exactly as every other slice does.

✅ **The `aberdeen` banner is DONE** — `cities/aberdeen.jpg`, Main Street to the Brown County
Courthouse, public domain, essentials [#169](https://github.com/EmpoweredVote/essentials/pull/169).
It needed no permission, so it did not wait on the LRC.

🟢 **Aberdeen now scores the full stack.** One point at the Brown County Courthouse returns
**seventeen** officials — 10 county, 3 city, 3 legislative and the at-large U.S. Representative.

⚠ **THE WORKTREE IS SET UP UNUSUALLY AND A FRESH SESSION WILL TRIP ON IT.**
`C:\ev-accounts-sd\backend\node_modules` is a **directory junction** to the main checkout's, and
`backend/.env` is a **hard link** to it — the repo's `.env` is read-blocked here, so it could not be
copied. Both are gitignored. If `npx tsx` or a `.mjs` script dies with `ERR_MODULE_NOT_FOUND`, the
junction is missing; recreate with:

```
cmd //c "mklink /J C:\ev-accounts-sd\backend\node_modules C:\EV-Accounts\backend\node_modules"
cmd //c "mklink /H C:\ev-accounts-sd\backend\.env C:\EV-Accounts\backend\.env"
```

🟢 **Migrations are applied with `psql`, not the MCP** — dry-run by concatenating the pair with
`COMMIT` replaced by `ROLLBACK`, then **verify the rollback reverted** before the real apply:

```
cd /c/ev-accounts-sd/backend && (set -a; . ./.env; set +a; \
  "/c/Program Files/PostgreSQL/18/bin/psql" "$DATABASE_URL" -v ON_ERROR_STOP=1 -f <file>)
```

⚠ `state:sd` lease runs to **2026-09-29 07:08Z** — extend it before a long session.
⚠ Slots used so far: `CC_0163`-`CC_0166`. Allocate new ones; never count.

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

---

## ▶ SD-3 MEASURED 2026-09-28 — NOTHING WRITTEN TO PRODUCTION

### 🟢 THE INVENTORY IS THE CHARTER'S OWN SENTENCE, AND IT IS NINE

**Aberdeen Home Rule Charter** (adopted Nov 2004, amended Nov 2020), § 2.02(a):
*"There shall be a city council composed of the mayor and eight members; the council members shall
be elected by the voters of the city according to districts established in §6.03 and the mayor
shall be elected as provided in §2.03."*
§ 6.03(a): *"There shall be four (4) city council districts."*

✅ **A scan of the whole charter for "shall be elected" returns those two offices and nothing
else.** No elected municipal judge — the ND-3 trap at Grand Forks — no elected finance officer, no
elected clerk. **9 elected offices: 1 Mayor citywide + 8 council, TWO per district over FOUR
districts.**

🔴 **SO ABERDEEN IS A SECOND MULTI-MEMBER BODY IN THE SAME SLICE.** The council is two per
district exactly as the SD House is, and the same gate shape applies: two offices on each of the
four districts, eight in total, and a duplicate sweep keyed on (district, chamber) reports all four.

🔴 **THE DISTRICTS ARE NAMED, NOT NUMBERED** — Northwest, Northeast, Southeast, Southwest.
Nothing here may be cast to an integer.

### 🟢 FIVE-YEAR TERMS, AND THE CHARTER FIXES THE START DAY

§ 2.02(c): council members *"shall be elected for five-year terms. The terms of council members
shall begin on the **first day of July** after their election, unless it is a special election,
then the first day of an official's term would begin on the first day of the month following the
special election **or immediately if it is to fill a vacancy**."* § 2.03(a) gives the mayor the same
five-year term.

⚠ **FIVE YEARS IS UNUSUAL AND IT IS NOT A TYPO** — the city's Elections page says the same in its
own words: *"The offices of mayor and City Council members are five-year terms on a staggered
basis."* Do not "correct" it to three or four.

🔴 **THE CHARTER'S OWN EXCEPTION IS WHAT MAKES DERIVING A DATE UNSAFE.** A member appointed to a
vacancy takes office **immediately**, not on 1 July, and inherits the unexpired term — so
"term-end year minus five" would produce a WRONG start for them, and the published term-end year
cannot tell an appointee from an elected member.

### The roster, confirmed by the council's own dated roll call

| Member | District | Term ends |
| --- | --- | --- |
| Rob Ronayne | Northeast | 2028 |
| Erin Fouberg | Northeast | 2027 |
| David Novstrup | Southeast | 2027 |
| Chad Nilson | Southeast | 2030 |
| Charlotte Liebelt | Northwest | 2027 |
| Rich Ward | Northwest | 2029 |
| Alan Johnson | Southwest | 2028 |
| Talmage Ekanger | Southwest | 2030 |
| **Travis Schaunaman** | **Mayor** (citywide) | 2029 |

✅ **All nine are named in the roll call of the City Council minutes for 2026-07-06** — a dated,
independent confirmation that the council page is CURRENT and not stale. That mattered: no member
carries a 2031 term end, so a June 2026 election could have seated one. **No council seat was up in
June 2026**, and the July 2026 minutes record no oath.

✅ The 2025 result is the city's own: **Talmage Ekanger** (SW, 226 to 172) and **Chad Nilson** (SE,
**124 to 123**, a one-vote margin), elected 2025-06-03, canvassed 2025-06-06 — and 🔴 **a canvass is
not a fact about who holds the seat**; the charter's 1 July is.

### 🟢 THE GEOMETRY EXISTS AND IS THE CITY'S OWN

`https://services5.arcgis.com/H3Xuuu0h4PaTeWwU/arcgis/rest/services/New_Final_Districts/FeatureServer/1`
— reached by rendering the city's ArcGIS Experience app (linked from `aberdeengis.com`) and reading
its network traffic, then confirmed through the AGOL item search. **This is NOT the PDF-only dead
end Gary hit.**

⚠ **THE ITEM IS NAMED "New Final Districts", WHICH READS LIKE A DRAFT — THE SERVICE ITSELF IS
NOT.** Its layer name is **`City Council Districts (2021 Finalized)`**, and it holds exactly **4
polygons**:

| District | Population |
| --- | --- |
| Northwest | 6,981 |
| Northeast | 7,220 |
| Southeast | 7,146 |
| Southwest | 7,148 |

🟢 **Those four populations sum to 28,495, which is Aberdeen's population** — an arithmetic check
the layer passes against a number that came from somewhere else entirely. The layer sits in the same
ArcGIS org as the city's imagery, roads, addresses and jurisdictions.

⚠ `spatialReference` is **4269 (NAD83)**, not 4326. The load must set SRID explicitly.
⚠ The city also publishes a council-district **PDF**; it is not the route and must not become one.

### ✅ THE ARRIVALS ARE DATED FROM THE COUNCIL'S OWN MINUTES (2026-09-28)

Ruling: dig the minutes rather than derive. **It was the right call — derivation would have been
wrong by 25 days on one member and wrong in kind on two others.**

| Member | District | Start | Precision | Evidence |
| --- | --- | --- | --- | --- |
| Erin Fouberg | NE | **2022-07-05** | day | *"Finance Officer Jordan McQuillen administered the oath of office to new City Council Members Erin Fouberg, Charlotte Liebelt, and David Novstrup."* |
| Charlotte Liebelt | NW | **2022-07-05** | day | same minute |
| David Novstrup | SE | **2022-07-05** | day | same minute |
| Travis Schaunaman | **Mayor** | **2019-07-01** | day | *"administered the oath of office to Travis Schaunaman, Mayor of the City of Aberdeen, SD"* — his 2024-07-01 oath is a **re-election** |
| Rich Ward | NW | **2024-07-01** | day | *"administered the oath of office to Mayor Travis Schaunaman and new City Council Member Rich Ward"* |
| **Talmage Ekanger** | SW | **2025-06-06** | day | *"Finance Officer McQuillen administered the Oath of Office to Talmage Ekanger"*, special meeting |
| Chad Nilson | SE | **2025-07-01** | day | charter § 2.02(c); no oath recorded; absent 06-23, present 07-07 |
| Rob Ronayne | NE | **NULL** | **unknown** | continuous since **at least 2016-06-27**, the earliest minute the archive holds |
| Alan Johnson | SW | **NULL** | **unknown** | continuous since **at least 2016-06-27** |

### 🔴🔴 TWO MEMBERS OF THE SAME ELECTION STARTED 25 DAYS APART, AND THE CHARTER RULE ONLY FITS ONE

Ekanger and Nilson both won on **2025-06-03**. Deriving "1 July after the election" would have given
both **2025-07-01**. It is right for Nilson and **wrong for Ekanger**:

- **Ekanger's seat was already VACANT.** Justin Reinbold is gone from the roll by 2025-06-02, so the
  SW seat had no occupant. At the canvass meeting on **2025-06-06** the council resolved that he
  *"begin discharging the duties of the office as soon as he has qualified"*, the Finance Officer
  administered the oath **at that meeting**, and *"Mayor Schaunaman thereafter invited Council
  Member Ekanger to join the meeting"* — he then moved the adjournment. He is at the roll call on
  2025-06-16 and 2025-06-23, both **before** 1 July.
- **Nilson's seat was NOT vacant.** Tiffany Langer served the SE seat to the end of her term and is
  at the roll call through 2025-06-23. And 🔴 **the SE race went to a RECOUNT** — Nilson won
  **124 to 123** — with Resolution 25-06-02R *"declaring results of SE District election following
  recount board determination"* adopted 2025-06-16. He first appears at the roll call on 2025-07-07.

▶ **The charter's own exception is the discriminator, and only the minutes expose which side a
member falls on.** A published term-end year cannot: both men read "Term Ends 2030".

### 🔴 A RE-ELECTION DOES NOT RESTART AN OCCUPANCY, AND THE MAYOR IS THE PROOF

Schaunaman was sworn on **2019-07-01** and sworn **again** on 2024-07-01. The second is a
re-election of a continuously serving mayor, so the occupancy starts in **2019**, not 2024. Taking
the most recent oath would have shortened his tenure by five years. The same reasoning is why
Ronayne and Johnson cannot be dated from their current term: both read "Term Ends 2028", both were
re-elected in 2023, and both were already at the roll call in **June 2016**.

### ⚠ TWO ARRIVALS ARE OLDER THAN THE CITY'S OWN ARCHIVE

Aberdeen's Agenda Center offers **2015 onward**, and holds no 2015 council minutes — the earliest
usable roll call is **2016-06-27**. **Rob Ronayne and Alan Johnson are both present in it**, so the
city's own published record cannot date their arrival. Their terms are written **open-ended at
`start_precision => 'unknown'`**, which is what the schema is for; writing 2016-06-27 at day
precision would assert a start that is merely the edge of the archive. ▶ Their continuity since at
least 2016-06-27 is recorded here and in the migration comment, because it is a real fact even
though it is not a start date.

### ▶ What SD-3 still owes

---

## ✅ SD-3 APPLIED 2026-09-28 — ABERDEEN IS SEATED

`X0072` (4 council polygons) + `CC_0165` (structure) + `CC_0166` (occupancy): **9 offices, 9 seated,
0 vacant, 9 people created, 0 reused.**

| | delta |
| --- | --- |
| `politicians` | **+9 exact** |
| `office_terms` | **+9 exact** |
| `offices` | **+9 exact** |
| `districts` | **+5** (4 council + 1 citywide) |
| `offices_missing_terms` | **unmoved at 422 / 238** |

**7 terms day-precision, 2 honestly `unknown`.** No name collided — none of the nine exists
elsewhere in production.

### 🟢 ABERDEEN CITY HALL NOW RETURNS SIX OFFICIALS

| Office | Holder | Term start |
| --- | --- | --- |
| Council Member, Northwest District | Charlotte Liebelt | 2022-07-05 |
| Council Member, Northwest District | Rich Ward | 2024-07-01 |
| Mayor | Travis Schaunaman | 2019-07-01 |
| State Representative, District 3 | Al Novstrup | 2025-01-14 |
| State Representative, District 3 | Brandei Schaefbauer | 2025-01-14 |
| State Senator, District 3 | Carl Perry | 2025-01-14 |

⚠ **Six, not four** — two multi-member bodies stack at the same address. Only the county
commission is missing, which is SD-4.

⚠ **`David Novstrup` (council, Southeast) and `Al Novstrup` (State Representative, District 3) are
DIFFERENT PEOPLE**, both of Aberdeen, both seated by this slice. The full names differ so nothing
collided, but a surname match across the two waves would merge them.

### 🔴 ONE POLYGON ARRIVED INVALID, AND THE REPAIR IS GATED RATHER THAN TRUSTED

The city's **Northwest** district has a **ring self-intersection** at
`(-98.5069610644335, 45.4842403902356)` — a zero-area digitising spike. The loader repairs it with
`ST_MakeValid` and **asserts what the repair did**: measured 2026-09-28, it keeps a single Polygon,
takes 316 points to 319, and moves the area by **0.000000 m² of 11,515,275.41**. A repair that moved
more than 1 m² would abort. ▶ **A repair that is not measured is an edit.**

⚠ **A zero rowcount has two causes and they are not the same fact** — already-present, or
rejected-by-the-area-guard. An earlier version counted both as "already existed", which would have
hidden a repair that redrew a district. The loader now asks which.

### 🔴 THE EXTRA RINGS ARE HOLES, NOT PARTS

Northwest returns five rings, Northeast three, Southwest two. In GeoJSON that means one exterior and
N holes — but ArcGIS also emits **multi-part** shapes as multiple rings, and reading a part as a
hole would cut real territory out of a district **with nothing erroring**. Measured: every ring 0 is
clockwise with a large area (the ESRI exterior convention), and every later ring is
counter-clockwise, tiny, and has its first vertex **inside** ring 0. They are genuine in-holdings.
The loader asserts that shape rather than assuming it.

### Gates and controls

The loader carries five controls — a bogus layer id, the district name set, the population identity
(**28,495, a number from outside the layer**), the ring orientation test, and probes requiring City
Hall in exactly one district and two out-of-state points in none. The population and name gates were
each **watched failing** on a tampered copy.

The structure migration **refuses to run if the four polygons are absent**, and its gate asserts
that **every Aberdeen office sits on a district that has geometry** — the one failure mode CI cannot
catch. The occupancy gate asserts 7 day-precision + 2 unknown explicitly, so a later edit cannot
quietly convert an unknown into a guess.

Dry-run was a real `BEGIN … ROLLBACK` through `psql` as `ev_api`, **verified to have reverted**.
`check:occupancy`, `check:migrations` and `check:reservations` all green.

▶ **SD-4 is applied — see below.**

▶ **The program's four-answer probe returns SEVENTEEN answers at the Brown County Courthouse**
— 10 county, 3 Aberdeen, 3 legislative and the at-large U.S. Representative. On a whole
legislative district the *state* part is council member, county commissioner, state senator and
**two** state representatives; inside 26A/26B/28A/28B it is four. Neither count is a defect.

---

## ✅ SD-4 APPLIED 2026-09-28 — BROWN COUNTY IS SEATED, AND IT LOADED NO GEOMETRY

`CC_0167` (structure) + `CC_0168` (occupancy): **10 offices, 10 seated, 0 vacant, 10 people
created, 0 reused.** Baseline measured in the same session, minutes before the write.

| | baseline | after | delta |
| --- | --- | --- | --- |
| `politicians` | 89,475 | 89,485 | **+10 exact** |
| `office_terms` | 9,956 | 9,966 | **+10 exact** |
| `offices` | 10,020 | 10,030 | **+10 exact** |
| `chambers` | 1,337 | 1,339 | +2 |
| `governments` | 611 | 612 | +1 |
| **`districts`** | 10,532 | **10,532** | **UNMOVED — and that is the finding** |
| `offices_missing_terms` | 422 / 184 / 238 | **422 / 184 / 238** | **unmoved** |

**8 terms day-precision, 2 honestly `unknown`.** No name collided — the only surname matches in
production are Bill Sutton (KS), Ed Sutton (SC), Michael Van Meter, Stacy Wiese and Ty Winter, five
different people. Checked, not assumed.

### 🔴🔴 THE COMMISSION IS ELECTED AT LARGE, SO THIS WAVE CREATED NO DISTRICT

All ten offices hang on the county district that already existed (`COUNTY` / **`G4020`** /
**`46013`**, government_id was NULL and offices 0). `districts` did not move by a single row. This
is the opposite of the program's usual shape and it must not be "fixed" later by inventing five
commissioner districts — **the structure gate fails if any row matching
`Brown County Commission District%` ever appears.**

🔴 **THE STATUTE CANNOT SETTLE THIS, AND THAT IS THE TRAP.** SDCL 7-8-2 reads *"The nomination and
election of county commissioners shall be by a vote of the voters of the district of which such
candidate is a resident voter"*, which sounds decisive and is not: **SDCL 7-8-10** lets the board,
at each decennial revision, *"choose to have commissioners elected at large"*, or from single-member,
multi-member or hybrid districts. Only the county's own record says which. Four sources say at large:

1. 🟢 **the county's own sample ballot** for the 4 June 2024 primary — *"For County Commissioner At
   Large — You may vote for up to two or leave it blank"* — and the **same** contest with the
   **same** three candidates appears on the ballots of legislative districts **01, 03 and 23**, so
   every voter in the county votes on every seat;
2. the Secretary of State's candidate lists name the contest **"County Commissioner At Large"** in
   2016, 2018, 2020, 2022 and 2024 — five consecutive cycles;
3. the SOS result pages name it **"County Commissioner At Large - Brown"**;
4. the county's own Commission page has listed five members with **no district** since at least
   2014-05-27.

⚠ **A WEB SEARCH SUMMARY SAID "AT LARGE" TOO — AND IT WAS A LEAD, NOT THE SOURCE.** The same
summary also asserted a 2026 incumbent list. The ballot is what settled it.

⚠ **ONE STATUTORY LOOSE END, RECORDED RATHER THAN HIDDEN.** SDCL 7-8-1 says a commissioner of an
*"odd-numbered or unnumbered district"* runs in the **gubernatorial** year. Brown County's seats are
unnumbered, yet two of five are filled in presidential years (Sutton, Dinger — 2024) and three in
gubernatorial years (Wiese, Gage, Dennert — 2022). The staggering is real and the county states it;
it survived the move to at-large election, which SDCL 7-8-8 and 7-8-11 expressly provide for.
**The ballot is the fact; the parity rule is not.**

### 🟢 THE INVENTORY IS TEN, AND THE STATE'S OWN AUDITOR PRINTS IT

| source | what it gives |
| --- | --- |
| **SDCL 7-7-1.1 + 7-8-1** | sheriff, auditor, register of deeds (1974 + 4k); treasurer, state's attorney, coroner (1976 + 4k); a board of 3-7 commissioners |
| **the county's own June-2024 sample ballot** | the commissioner contest, named and at large |
| 🟢 **SD Department of Legislative Audit** | a **"COUNTY OFFICIALS"** page in every Brown County audit report — as of 31 December **2021, 2023 and 2024** it lists exactly 5 commissioners + Auditor + Treasurer + State's Attorney + Register of Deeds + Sheriff, and nothing else |

▶ **The DLA report is the find worth carrying to every other county slice.** It is a state agency's
dated list of a county's elected officers, published as page 1 of an audit the county puts on its
own website. It is the cheapest complete inventory in the program so far, and it is a *third*
independent voice, not a restatement of the county's page.

🔴 **THE CORONER IS NOT SEATED, AND IT IS PROVED POSITIVELY.** Brown County Commission
**RESOLUTION #08-24**, adopted **2024-01-16**, *"does hereby adopt the option to appoint the Brown
County Coroner in lieu of an election pursuant to SDCL 7-7-1.4"* and appoints the **Sheriff** to
serve as coroner. SDCL 7-7-1.4 requires that election *"not later than the April first preceding
the election for coroner"*; the coroner's cycle year is 2024 and the resolution predates it. Brian
Koens was later sworn as Coroner on **2024-12-31** (*"Auditor Heupel swore Brian Koens in as Brown
County Coroner"*). ▶ **This is ND-4's shape without ND-4's argument from absence** — a named
instrument, not three empty ballots.

🔴 **THE DIRECTOR OF EQUALIZATION IS NOT SEATED EITHER** — SDCL 10-3-3: *"The county director of
equalization shall be appointed by the board of county commissioners."* The county's department
list shows Equalization beside the six elected offices with nothing marking which is which. That is
the Sedgwick County trap of `CC_0161`, and the statute is what separates them.

### ⚠ THE CHARTER QUESTION, STATED HONESTLY RATHER THAN CLAIMED

SDCL 7-7-1.1 opens *"Unless otherwise provided by county charter"*. Brown County's published
ordinance code is **20 titles and contains no charter**, and the office set observed is exactly the
statutory default with the one statutory opt-out exercised by a resolution citing the statute by
number. **SDCL 6-12-11** makes the Secretary of State the keeper of adopted charters — that
registry is **not published online and was not read**.

▶ So the negative is **not proved directly**. What makes the inventory safe anyway is that a
charter, if one exists, **has not changed the office set**, because the set matches the statute it
would have had to override. ND-4 had to OCR a scanned charter to reach the same certainty; here the
convergence carries it, and the gap is recorded rather than papered over.

### 🔴🔴 AN ELECTION YEAR IS NOT AN ARRIVAL — IT WOULD HAVE BEEN WRONG FOR SIX OF TEN

| holder | office | start | prec. | how | the dated evidence |
| --- | --- | --- | --- | --- | --- |
| **Mike Gage** | Commissioner | **2021-12-14** | day | appointed | *"SWEARING IN CEREMONY: Mike Gage was sworn in by County Auditor, Cathy McNickle as Brown County Commissioner"* — filling the seat of *"former Commissioner Kippley who resigned December 7, 2021"*. **Elected eleven months later.** |
| **Drew Dennert** | Commissioner | **2023-01-03** | day | elected | *"Drew Dennert, Mike Gage and Doug Fjeldheim were sworn in as Brown County Commissioners"* — the statutory first Tuesday |
| **Kyler Dinger** | Commissioner | **2025-01-07** | day | elected | *"Auditor Heupel Administered the Oaths of Office to Commissioners Sutton and Dinger"* — the statutory first Tuesday |
| **Mike Wiese** | Commissioner | **2019-01-01** | day | elected | elected 2018 (6,819, third of six for three seats). 🔴 **A FRESH occupancy: he sat through 2014, is ABSENT from the county's page 2015-01-21 to 2018-07-01, and returns 2019-01-01.** |
| **Duane Sutton** | Commissioner | **NULL** | **unknown** | — | on the board, already as **Chair**, in the earliest archived copy of the county's own page, **2014-05-27** |
| **Lynn Heupel** | Auditor | **2022-09-06** | day | appointed | *"Lynn Heupel was named as Interim Auditor for 2 years. She will have to run in the 2024 election"* (2022-08-09) + the same meeting's HR line *"effective September 6, 2022"* |
| **Patty VanMeter** | Treasurer | **NULL** | **unknown** | — | Treasurer in the earliest archived copy showing her, **2020-02-26**; Sheila Enderson still held it 2019-07-16 |
| **Mariann Malsom** | Register of Deeds | **2023-01-02** | day | elected | elected 2022; first Monday in January, SDCL 7-7-1. ⚠ **No oath is recorded for her** |
| **Dave Lunzman** | Sheriff | **2023-01-02** | day | elected | elected 2022; first Monday. ⚠ **His oath is 2023-01-03** — see below |
| **Karly Winter** | State's Attorney | **2023-07-10** | day | appointed | *"Hiring of Karly Winter as Brown County States Attorney … effective July 10, 2023"*, after *"resignation of Ernest Thompson … effective May 12, 2023"* and Mark Anderson as temporary interim |

▶ **Taking the most recent election would have been wrong for six of the ten.** Taking the *first*
election in the SOS candidate lists would still have been wrong for four, **because an appointment
leaves no candidate row at all**.

### 🔴🔴 THE ELECTION RESULTS ARE NOT AN INVENTORY OF WHO WAS ELECTED

South Dakota lets a county auditor leave an uncontested office off the ballot entirely, so an
unopposed winner appears in **no result at all**. Measured: the SOS's Brown County return for the
**November 2024 general carries NO county contest whatsoever** — no commissioner, no treasurer, no
auditor, no state's attorney — **yet five people took those offices from that election**. Doug
Fjeldheim is the same shape in 2022: on the candidate list, **absent from the result**, and sworn
in on 2023-01-03.

▶ **The CANDIDATE LIST holds them; the RESULT does not.** Reading the results as the roster of
winners is a silent under-count, and it is the opposite of ND-4's lesson (*a certified result is
not a fact about who holds the seat*) — here the result does not even exist.

### 🔴 THREE DIFFERENT STATUTORY START DAYS IN ONE COUNTY

| | day | statute |
| --- | --- | --- |
| County Commissioner | **first TUESDAY** of January | SDCL 7-8-1 |
| Treasurer · Register of Deeds · Sheriff · State's Attorney | **first MONDAY** in January | SDCL 7-7-1 |
| **County Auditor** | **first MONDAY OF MARCH** | SDCL 7-7-1 |

Making these uniform would be wrong three ways. **The rule applied here is one rule**: an *elected*
arrival takes the statutory term commencement — a date the statute states, not one this wave
computes — and an *appointed* arrival takes the date the county's own minutes give it.

🟢 **AND THE DERIVATION IS CONTROLLED.** The two recorded commissioner oaths — **2023-01-03**
(Dennert) and **2025-01-07** (Dinger) — both land **exactly** on the statutory first Tuesday.
⚠ **The same control also shows the oath and the term start are different events**: Sheriff
Lunzman's term began the first **Monday**, 2023-01-02, but he was sworn on 2023-01-03, because
Brown County swears its countywide officers at the commission's **reorganization** meeting, which
falls on the commission's Tuesday. Wiese's re-election oath is later still — **2023-01-17**, a
fortnight after that term began. ▶ That is why the term start comes from the statute and the
ceremony dates live in the `source` strings.

### 🟢 THE AUDITOR IS OFF-CYCLE, AND THE MINUTES SAY WHY IN ONE SENTENCE

SDCL 7-7-1.1 puts the auditor in the 1974 + 4k class — **2022, 2026**. Brown County's auditor ran in
**2024**. That looked like a contradiction for hours; the county's own minute resolves it:
*"Lynn Heupel was named as **Interim Auditor for 2 years**. She will have to run in the **2024
election**."* A vacancy appointment runs to the next general election, so the seat moved off the
statutory class. ▶ **An office appearing in the wrong cycle year is a VACANCY signature, not a data
error.**

### ⚠ THE COUNTY'S OWN PAGES WERE STALE BY MONTHS

The archived **State's Attorney** page still named **Ernest Thompson on 2023-09-28** — ten weeks
after Karly Winter took the office and four months after Thompson's resignation took effect.
Trusting it would have placed her arrival *after* September 2023 instead of 10 July. **A source can
be authoritative for one field and stale for another**; the HR record inside the minutes is what
dates it.

### 🔴 THREE DETECTOR FAILURES, ALL CAUGHT, ALL WORTH CARRYING

1. 🔴🔴 **A CONTROL PROVES THE SCAN READS THE ROWS — IT CANNOT PROVE THE PREDICATE IS RIGHT.**
   Grepping 186 archived minutes for **`oath`** returned **zero**, and a positive control confirmed
   the scan was not blind (78 of 81 files contained `commission`). The scan was fine; **the word was
   wrong.** Brown County files the event as **`SWEARING IN CEREMONY`**. Searching for that returned
   Gage, Dennert, Lunzman, Dinger and Koens. ▶ *A clean zero from a working detector is still a
   statement about the query, not about the world.*
2. 🔴 **A SURNAME IS NOT A PERSON.** Name scans returned *"Violet Dinger Estate"*, *"Gage Hansen"*,
   *"Sutton Stearns"*, *"Karly Allison"*, *"Andrea Heupel"* and *"Matthew Heupel"* — claim lists and
   4-H premium rolls. Every date above comes from a line that names the **office**.
3. 🔴 **A LIST UNDER A HEADING IS NOT THE HEADING'S MEMBERSHIP.** Parsing the archived Commission
   page produced **six** commissioners for 2014-2019. The sixth was **"Gary Vetter — Commission
   Assistant"**, staff. **SDCL 7-8-3 (3, 5 or 7 only) is what caught it** — the statute as an
   arithmetic control on a scrape.

### ⚠ TWO ARCHIVES LIE ABOUT THEIR OWN DEPTH

- 🔴 **`sdpublicnotices.com` SILENTLY CLAMPS THE DATE RANGE.** A search from 2005-01-01 returned two
  pages of results and reported **"Published Date From: 7/30/2026"** — the site holds ~60 days and
  substituted its own range without erroring. The results looked like an answer and matched nothing
  asked for.
- 🔴🔴 **A PDF OF EXACTLY 1,048,576 BYTES IS A TRUNCATION, NOT A DOCUMENT.** **40** of the archived
  Brown County minute volumes came back at exactly 2²⁰ bytes with no `%%EOF`. The Wayback capture
  itself is partial: the 2019 volume's `x-archive-orig-etag` gives the original as **45 MB**, and
  the replay serves 1 MiB. `pdftotext` reports *"damaged — attempting to reconstruct"* and yields
  **0 pages**, but a partly-truncated scan would have yielded its first pages **without complaining**.
  ▶ **Check the byte count against a power of two, and check for `%%EOF`.** That is why Sutton's and
  VanMeter's arrivals stay `unknown`: the bound volumes that hold them survive only as a first
  megabyte.

### Where the dated record actually lives

| source | covers |
| --- | --- |
| live site `brown.sd.us/commission-meetings` | **2024-01-02 →** (146 meetings, 159 PDFs, all with a text layer) |
| Wayback of the old site's weekly minutes | **2020-02-18 → 2023-10-31** |
| Wayback of the county's department pages | **2014-05-27 → 2026-08-14**, ~2 snapshots a year |
| SD DLA audit reports on the county's own site | officials as of 31 Dec **2021, 2023, 2024** |
| SD SOS candidate lists (CSV) | **2016, 2018, 2020, 2022, 2024** primary + general |
| SD SOS result pages (`eid` 178/291/422/471/684) | 2016-2024; **older `eid`s 302-redirect** |

⚠ **The gap is 2023-11 and 2023-12** — after the old site's archive stops and before the new one
starts. Nothing needed for SD-4 fell in it.

### Gates and controls

Structure gate asserts: 1 government, 2 chambers, 10 offices, **exactly 5 at-large commissioner
offices and 5 countywide**, **0 invented commission districts**, every office on **exactly one**
district, that district carrying geometry, 0 vacant, **6 distinct titles** (the five commissioner
rows share one **by design**), and **no Coroner or Director of Equalization office**.

Occupancy gate asserts: 10 people in the reserved band, 10 terms, 5 + 5 seated **counting
`och.politician_id` rather than `*`**, **8 day-precision + 2 unknown explicitly**, every
unknown-precision term carrying a **NULL** `term_start`, 5 `elected` + 3 `appointed`, every person
`is_incumbent`, and no person holding two offices anywhere.

🟢 **The end-to-end probe is controlled by the collision itself.** A point at the Brown County
Courthouse returns **17** officials. Points in **Brown County, Wisconsin** and **Brown County,
Kansas** each land inside a county row named *"Brown County"* and return **0** South Dakota
offices — as do Rapid City and Fargo. ▶ The name collision is the control, pointed the right way.

🔴 **The `geo_id` collision is visible in the probe's own output**: State House District 3 and State
Senate District 3 both carry `geo_id` **`46003`**, while Brown County is **`46013`** — and Senate
District 13 *is* `46013`. Only `(mtfcc, geo_id)` separates them, and every lookup in both migrations
carries it.

`check:occupancy` green (10 files scanned). `check:migrations` green (6 added, 2,176 slots across
393 refs). `check:reservations` green. Dry-run was a real `BEGIN … ROLLBACK` through `psql` as
`ev_api`, and **the rollback was verified to have reverted** — all three totals returned to
89,475 / 9,956 / 10,020 before the apply.

🟢 The reserved `external_id` band **-2765886 .. -2765877** was measured empty first, continuing the
slice's own sequence (SD-2 took -2766000..-2765896, SD-3 -2765895..-2765887).

### ▶ What SD-4 leaves behind

- ⚠ **Duane Sutton's and Patty VanMeter's arrivals are open.** Both are `unknown` with NULL
  `term_start`. Either could be closed by a source that reaches before **2014-05-27** (Sutton) or
  into **2019-07..2020-02** (VanMeter) — the county's bound minute volumes, if a complete copy can
  be got from the county rather than from a truncated capture.
- ⚠ **The Secretary of State's home-rule charter registry is unread** (SDCL 6-12-11). It is the one
  document that would settle the charter question positively rather than by convergence.

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
| 3 Aberdeen | **9 offices** — 1 Mayor + 8 council, two per district over four NAMED districts | ✅ **APPLIED 2026-09-28** |
| 4 Brown County | **10 offices** — 5 commissioners AT LARGE + Auditor, Treasurer, Register of Deeds, Sheriff, State's Attorney | ✅ **APPLIED 2026-09-28** |
| 5 assets | portraits for everything seated, plus an `aberdeen` banner | |

✅ **Both inventories were read, not guessed.** Aberdeen's came from its Home Rule Charter ss 2.02,
2.03 and 6.03; Brown County's from SDCL 7-7-1.1 and 7-8-1, the county's own sample ballot, and the
SD Department of Legislative Audit's "COUNTY OFFICIALS" page in three consecutive audit reports.
⚠ **Neither matched a template.** Aberdeen has no elected municipal judge (the ND-3 trap) and Brown
County elects no coroner and no director of equalization, each excluded by a named instrument.

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
5. ✅ **SD-2 — DONE 2026-09-28.** 105 offices, 105 seated, every term day-precision (`CC_0163`/`CC_0164`).
6. ✅ **SD-3 — DONE 2026-09-28.** Aberdeen: 9 offices, 7 dated + 2 unknown (`X0072`, `CC_0165`/`CC_0166`).
7. ✅ **SD-4 — DONE 2026-09-28.** Brown County: 10 offices, 8 dated + 2 unknown, **no geometry loaded**
   (`CC_0167`/`CC_0168`).
8. ▶ **SD-5 — NEXT, AND IT IS A LICENCE QUESTION BEFORE IT IS A TECHNICAL ONE.** Send the drafted
   letter to `LRC@sdlegislature.gov`. **Import nothing until there is an answer** — South Dakota
   states "Use by Permission Only" up front. There is also no `aberdeen` banner key.

---

## Debts and open questions this slice already owes

- ✅ ~~The House structure is unproved.~~ **CLOSED 2026-09-28 — 37 `sldl` polygons, 33 whole + four
  subdistricts `26A`/`26B`/`28A`/`28B`, and those are the only splits.**
- ✅ ~~The vintage is unproved.~~ **CLOSED 2026-09-28 — TIGER 2024 carries the 2021 Adopted Map,
  proved geometrically against the SD Legislature's own layer, with the superseded 2010 layer as
  the control that makes the test able to fail.**
- ✅ ~~Aberdeen's and Brown County's office inventories are unread.~~ **CLOSED 2026-09-28 — 9 and 10,
  each from the body's own instrument.**
- ✅ ~~Which legislative district Aberdeen sits in is unknown.~~ **CLOSED — District 3, a WHOLE
  district, so the probe asserts the five-answer shape. Measured: the courthouse returns 17
  officials in total.**
- ⚠ **Duane Sutton's and Patty VanMeter's arrival dates are still open** — both written `unknown`
  with a NULL `term_start`. The bound county minute volumes that would close them survive on the
  Wayback Machine only as a truncated first megabyte of a 45 MB scan; a complete copy would have to
  come from the county.
- ⚠ **The Secretary of State's home-rule charter registry (SDCL 6-12-11) is unread.** It is the one
  document that would settle Brown County's charter question positively rather than by convergence.
- ⚠ **No `SD` entry exists in the TIGER loader allowlist**, though line 742 already maps FIPS `46` to
  `sd`. The existing SD polygons came from earlier national loads, not from this script.
