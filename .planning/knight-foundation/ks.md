# KS — slice 14 (Wichita · Sedgwick County)

Opened 2026-09-26. **Nothing has been written to production.** This file records the baseline as
measured when the slice opened, and the two mistakes that measurement corrected.

Lease: `state:ks`, claimed 2026-09-26, expires **2026-09-28 06:08Z**. Branch: `knight/ks-slice14`.

## 🔴🔴 THE FIRST MEASUREMENT OF THIS SLICE WAS WRONG, AND THE LOADER'S OWN COMMENT CAUGHT IT

A first pass counted `essentials.districts` for Kansas and concluded **"zero places"**, which would
have put a 600-row `place` load into stage 1 that Kansas does not need.

`scripts/load-state-tiger-boundaries.ts` says, in the ND block, that North Dakota

> *"owes no `place` load — one of six such states (**KS** KY MI MS ND SD)"*

▶ **That contradiction was the tell.** Re-measured against `essentials.geofence_boundaries`,
Kansas holds **114 `G4210` place rows**. The first query was counting the wrong table: places have
boundary rows and **no `districts` rows**, so a districts-only count reports zero and looks
authoritative.

🔴 **AND THE TWO TABLES KEY DIFFERENTLY.** `districts.state` holds a **USPS** code (`ks`);
`geofence_boundaries.state` holds a **2-digit FIPS** code (`20`). A query written for one and
pointed at the other returns an empty set rather than an error.
▶ **Measure geometry in `geofence_boundaries` keyed by FIPS. Measure offices and districts in
`districts` keyed by USPS.** Never infer one from the other.

⚠ **`PROGRAM.md`'s `626` column for Kansas is COUNTY SUBDIVISIONS, not places.** Reading it as a
place count is what made the first pass plausible.

## Baseline as measured when the slice opened, 2026-09-26

### Geometry — `essentials.geofence_boundaries`, `state = '20'`

| MTFCC | Kind | Rows |
| --- | --- | --- |
| `G4040` | cousub / MCD | 1,391 |
| `G6350` | (unclassified in this query) | 704 |
| `G4110` | county subdivision | 626 |
| `G4210` | **place** | **114** |
| `G4020` | county | 105 |
| `G5200` | congressional | 4 |
| **`G5210`** | **sldu (state senate)** | **0** |
| **`G5220`** | **sldl (state house)** | **0** |

🟢 **The two zeros were CONTROLLED before they were believed.** The same query shape over states
known to hold legislative geometry returns Kentucky **38/100**, Michigan **38/110**, North Dakota
**47/48**. The detector can see geometry where it exists; Kansas genuinely has none.

### Districts and offices — `essentials.districts`, `state = 'ks'`

| Kind | Rows |
| --- | --- |
| county (`G4020`) | 105 |
| congressional (`G5200`) | 4 |
| statewide, **no MTFCC** | 6 |
| **place / sldu / sldl** | **0** |

⚠ **The six MTFCC-less rows are not an anomaly** — they are the statewide entities: US Senate
(2 offices) and five state executives (Governor, Lt Governor, Attorney General, Secretary of State,
Treasurer). A statewide district legitimately carries no MTFCC and `geo_id = '20'`.

**Kansas holds ZERO state legislative offices.** `PROGRAM.md` records `0/125` House and `0/40`
Senate.

## What KS-1 owes

**`sldu` + `sldl` only** — the same shape as OH, PA, SC, MI, ND and KY. No `place` load, no
`county` load, no `cd` load; all three are already in production.

```ts
KS: new Set(['sldu', 'sldl']),
```

Expected: **40 Senate + 125 House = 165 boundaries and 165 districts.** Stage 2 then owes 165
offices.

## ✅ KS-1 step 1 — the map vintage is PROVEN, 2026-09-26

**TIGER FIPS 20 carries Substitute for Senate Bill 563 — the Senate map "Liberty 3" and the House
map "Free State 3F" — in every vintage 2022 through 2025. 40 Senate + 125 House.**
Tool: `backend/scripts/verify-ks-tiger-vintage.mjs`, which needs no database. It carries the proof
and both controls, and `--self-test` makes the proof gate fail on demand.

🟢 **THE AUTHORITY IS THE ENACTED PLAN FILE ITSELF, WHICH IS STRONGER THAN ANY EARLIER SLICE HAD.**
The Kansas Legislative Research Department — the Legislature's own agency — publishes the passed
shapefiles at `klrd.gov/wp-content/uploads/2023/11/{Liberty_3,Freestate-3F}.zip`. Those two names
are not labels this repo chose: they are the names the Kansas Supreme Court uses for the two maps
it reviewed. Kentucky had to settle for the LRC's *current-geometry* map service; Kansas publishes
the artifact that was voted on. Both answer a plain HTTPS request — no WAF, unlike Ohio.
⚠ `kslegislature.gov/li/redistricting/` is a **404**. Go to KLRD, not to the Legislature's site.

### 🔴🔴 The finding that must survive this slice: A THRESHOLD TEST PASSES KANSAS'S OLD MAP

The 2012 court-drawn plan (*Essex v. Kobach*), carried by TIGER 2020, still agrees with the 2022
enacted plan on **35 of 40 Senate (87.5%)** and **112 of 125 House (89.6%)**.

▶ **So the discriminator is NOT the agreement rate — it is that the correct plan moves EXACTLY
ZERO districts and the wrong one does not.** Anyone who relaxes `moved === 0` to "≥90% agree"
re-admits a decade-old superseded map. This reproduces ND's 92% finding *inside Kansas*, against
the real prior plan rather than a stale vintage. It is control 2 in the tool, and it is the reason
the tool asserts a count and not a percentage.

### What else the proof established

- 🔴 **Kansas gives NO structural discriminator — the Kentucky shape exactly.** TIGER 2022, 2023,
  2024 and 2025 are all 40 and 125, MTFCC `G5210`/`G5220`, codes contiguous `001..040` and
  `001..125`, zero letters, zero zeros. A count check, a code-set check and a contiguity check all
  pass every vintage. Nothing about the file dates the map; the evidence had to be geometric.
- ⚠ **`LSY` is the misleading field again**, as in KY and MI. It reads 2022 in TIGER 2022/2023 and
  2024 in TIGER 2024/2025, which reads like a new plan. It is Census bookkeeping: statewide `ALAND`
  moves 211,753,641,384 → 211,754,288,230 across all four vintages — **0.0003%** — and every
  internal point stays put.
- 🔴 **A KANSAS DISTRICT CODE IS PADDED ON ONE SIDE AND NOT THE OTHER.** The authority serves
  `DISTRICT = '39'` unpadded; TIGER serves `SLDUST/SLDLST = '039'` zero-padded to three. **A raw
  string compare agrees on nothing and looks exactly like a wrong vintage.** Both sides are checked
  numeric before normalising; a non-numeric code is refused, never cast — the family of defect that
  `04A` (ND), `08A` (MN) and `H001` (KY) are.
- 🟢 **Both chambers are single-member** (`MEMBERS = 1` on all 165 authority polygons), so polygon
  count IS seat count — unlike ND and SD.
- 🔴 **`geo_id` collides with counties, as in PA, SC, OH, ND and KY.** Measured against production:
  105 Kansas counties, `20001..20209`, all odd — **20 collide with the Senate range, 63 with the
  House range.** 🟢 **Sedgwick County escapes at `20173`**, above both ranges; Fayette County did
  not, at `21067`. That is luck of the numbering, not a property of the loader.

### Corrections this step made to the lines that used to sit here

- 🔴 **"The Senate map is SB 563 and the House map HB 2736" was WRONG.** **Both** legislative maps
  live in **one bill, Substitute for SB 563.** There is no HB 2736 House map. SB 563 was introduced
  2022-03-14 carrying maps for both chambers; the House amended it on 2022-03-21 to its own
  preferred House map — which is why the Free State 3F file carries an internal date of 2022-03-21.
- 🔴 **The congressional plan is "Ad Astra 2", not "Ardanna 2"** (KLRD publishes it as
  `M3_AdAstra_2.zip`). The bill number for it is **not** established here — do not write one down
  from memory.
- ✅ **"Whether either legislative map was challenged is not established here" — now established.**
  Kansas Constitution art. 10, § 1(b) makes Supreme Court review **AUTOMATIC AND MANDATORY**: the
  Attorney General *must* petition within 15 days of publication. **This distinguishes Kansas from
  every other slice in this programme, where review happens only if somebody sues.** AG Schmidt
  petitioned 2022-04-25; the court announced 2022-05-18 and filed its opinion 2022-06-21 (No.
  125,083), upholding Sub. SB 563 in full and **ordering no remedial map**. The one intervenor,
  Senator Thomas Holland, contested the procedure and the boundaries of Senate Districts 3 and 9,
  and lost. **One plan has governed since 2022 and governs the 2026 election.**
- ✅ **MI-1's "two chambers on different plans" risk does not apply**, and not because the terms
  were checked — because both maps are in one bill and both agree in every TIGER vintage. The
  four-year Senate term is **not** verified here and nothing now depends on it.
- ▶ **TIGER 2022 agreeing is a PASS here, not a failure** — the Kentucky direction, the opposite of
  North Dakota. The tool states that expectation in advance and asserts it, because an expectation
  formed after the measurement is not evidence.

⚠ **The 2025 congressional remap push is NOT a legislative-map event and must not be read as one.**
Kansas Republicans tried to force a November 2025 special session to redraw the four US House
districts; House leadership ended the push on **2025-11-05** without a session, so **no map of any
kind was enacted** and the congressional rows already in production are not stale from it.
Art. 10, § 1(a) puts the next legislative reapportionment in **2032**.

⚠ **The competing 2022 legislative plans are published as PDF only** — Liberty 2, Freestate 3,
Freestate 3C, Free State 1 and 5. No shapefile, so the MI-style "control against the real competing
plan" is not available here. The 2012 plan is the closest real-plan control there is, and it works.

## ✅ KS-1 step 2 — the loader knows about Kansas, 2026-09-26

`KS: new Set(['sldu', 'sldl'])` is in `STATE_LAYER_ALLOWLIST`, with the slice's findings written
into the block above it. The pre-flight gate for `fipsArg === '20'` is a sibling of Kentucky's.
**Dry-run passes 40 and 125. Nothing has been written.**

```
[sldu] KS MTFCC pre-flight assertion PASSED: 40 records (expected 40), 40 distinct OCD-ID
       suffixes, codes contiguous 001..040, 6/6 enacted-plan anchors agree (3 distinguish 2012).
[sldl] KS MTFCC pre-flight assertion PASSED: 125 records (expected 125), 125 distinct OCD-ID
       suffixes, codes contiguous 001..125, 7/7 enacted-plan anchors agree (2 distinguish 2012).
```

🟢 **The two counts are THE LAW here, not a measurement** — the only slice in this programme where
that is true. *"Kansas has 40 senatorial districts and 125 representative districts. Kan. Const.
art. 2, § 2; K.S.A. 4-101"* (No. 125,083, slip op. at 2). They were measured against TIGER as well,
and agree.

### 🔴🔴 MOST CIVIC ANCHORS IN KANSAS CANNOT DATE THE MAP — MEASURED, NOT ASSUMED

Six ordinary civic points — two in Wichita, the Capitol, the Wyandotte courthouse, Overland Park
and Garden City — resolve **identically under the 2012 and 2022 plans in 11 of their 12
chamber/point pairs.** Only the Capitol moves (Senate 18 → 19).

▶ **An anchor set chosen for being recognisable is a WEAK vintage test here.** So the last two
anchors in each chamber are chosen for the opposite reason: they sit where the plans actually
disagree (Sedgwick SD-27→26, Jefferson SD-2→18, Johnson HD-39→117, Chase HD-68→13). Their expected
values come from KLRD's enacted plan file; their counties were read from production, not inferred
from a name.

🟢 **And the gate now asserts its own discriminating power.** `KS_MIN_DISCRIMINATING = 2` fails the
load if too few anchors distinguish the two plans. That is what stops a later editor from tidying
the odd-looking last two anchors into recognisable landmarks and silently leaving Kansas with a gate
that agrees with the 2012 map.

### 🔴🔴 The gate fired for the WRONG REASON, and two fixes both looked sufficient

The `anchor` tamper perturbs **Wichita City Hall** — an anchor that does *not* distinguish the
plans. The error message diagnosed it as **"this file is the OLD MAP — check `--vintage`"**.

- Attempt 1 — *"every failure landed on its prior value"*: **vacuously true** for a
  non-discriminating anchor, whose prior *is* its expected.
- Attempt 2 — *"…and some failure has expected ≠ prior"*: the tamper sets expected to `999`, which
  satisfies exactly that. Still wrong.
- ✅ The honest test is **not about values — it is about WHICH anchors failed.** An old file makes
  *every* discriminating anchor fail, each landing on its 2012 value. A tampered expectation makes
  *one arbitrary* anchor fail while the discriminating ones still pass.

▶ **A gate that aborts for the wrong reason sends the next reader to check `--vintage` when the
fault is in the source file.** Knight has hit "a gate can abort for the wrong reason" before; this
is that rule inside the error *message* rather than the error *condition*.

### Controls — every assertion watched failing

| Control | Fires | Result |
| --- | --- | --- |
| `KS_PREFLIGHT_CONTROL=count` | MTFCC count | ✅ `expected 39, got 40`, exit 1 |
| `KS_PREFLIGHT_CONTROL=anchor` | vintage | ✅ exit 1 — **and no false "old map" claim** after the fix |
| `KS_PREFLIGHT_CONTROL=weak` | discrimination | ✅ `only 0 of 3 anchors distinguish…`, exit 1 |
| `--vintage 2020` (**no flag needed**) | vintage | ✅ both chambers, **named as the old map** |

🟢 **`--vintage 2020` IS THE CONTROL KENTUCKY COULD NOT HAVE.** Kentucky's 2022 file carries the
*same* plan, so KY-1 had to synthesise its control. Kansas has a real older map to be wrong about,
so the loader can be pointed at it and must abort. Senate failed on all three discriminating
anchors (Capitol 18≠19, Sedgwick 27≠26, Jefferson 2≠18); House on both (Johnson 39≠117, Chase
68≠13).

✅ `npx tsc --noEmit` clean · `npm run lint` 0 errors · `npm run check:ocd-loader` green.

## ✅ KS-1 APPLIED 2026-09-27 — KANSAS HAS LEGISLATIVE GEOGRAPHY

**165 boundaries + 165 districts — 40 Senate + 125 House. 0 already existed, 0 errors.** No
migration; this is a loader run. Kansas still holds **zero** state legislative offices — that is
stage 2.

### The baseline was taken through BOTH connections first, and they agreed

Measured 2026-09-27 06:51–06:52Z, before any write: `DATABASE_URL` as **`ev_api`** (the role the
loader writes as, over the IPv4 pooler) and MCP as **`postgres`**. Every figure identical.

| | baseline | after | delta |
| --- | --- | --- | --- |
| KS `G5210` boundaries / districts | 0 / 0 | **40 / 40** | +40 |
| KS `G5220` boundaries / districts | 0 / 0 | **125 / 125** | +125 |
| `geofence_boundaries` total | 72,460 | **72,625** | **+165 exact** |
| `districts` total | 10,278 | **10,443** | **+165 exact** |
| KY control (sldu+sldl) | 138 / 138 | 138 / 138 | **unmoved** |
| `offices_missing_terms` | 422 / 238 | 422 / 238 | **unmoved** |

### Content, not just counts

- `G5210`: 40 rows, 40 distinct `geo_id`, 40 distinct `ocd_id`, numbers **contiguous 1..40**,
  `district_type = STATE_UPPER`, sample `ocd-division/country:us/state:ks/sldu:1`.
- `G5220`: 125 rows, contiguous **1..125**, `STATE_LOWER`, `…/state:ks/sldl:1`.
- **0 null/invalid/empty geometries.**
- ✅ **What was already in production is untouched**: 105 counties, 105 county boundaries, 4
  congressional districts, 114 places.

### 🟢 The predicted `geo_id` collision landed exactly as measured, and nothing was overwritten

**83 `geo_id`s are now shared across MTFCCs in Kansas — which is the 20 Senate-range plus 63
House-range county collisions, exactly as predicted before the load.** Duplicate
`(mtfcc, geo_id)` pairs: **0**. The compound key held; no county row was displaced.

### Idempotent, proved by re-running

Second run: **0 inserted (boundaries), 0 inserted (districts), 165 already existed, 0 errors**, and
every total re-measured **unchanged** afterwards. A re-run that reported zero while quietly
updating a row would have shown up in that second measurement.

### Spatial probe — the loaded geometry resolves, and the discriminating anchor holds in prod

| point | Senate | House |
| --- | --- | --- |
| Wichita City Hall | `20029` | `20103` |
| Sedgwick County Courthouse | `20029` | `20103` |
| Kansas State Capitol, Topeka | **`20019`** | `20057` |
| NEGATIVE: Nashville TN | — | — |
| NEGATIVE: Lexington KY | — | — |

Every Kansas point hits **exactly one** Senate and **exactly one** House district — no overlap, no
gap. Both negative controls return zero. 🟢 **Topeka is the discriminating anchor: the 2012 plan
would read `20018`.** The vintage proof therefore holds against what is actually in production, not
only against the file that was downloaded.

### ⚠ `check:reachability` is green, and its green says NOTHING about Kansas

Nothing regressed — `BAD_GEOMETRY` 4, `DEAD_GEOGRAPHY` 17, `UNREACHABLE` 7, all at baseline.

🔴 **But all three baselined checks require an ACTIVE HOLDER or OFFICES**, and Kansas has neither
yet. 165 office-less districts cannot raise `DEAD_GEOGRAPHY`, which is defined as *"a polygon and
offices, but no active holder"*. ▶ **So this run is invisible to the gate, and its pass is not
evidence that the load is good.** The evidence is the measurement above. Kansas becomes visible to
`check:reachability` only when stage 2 seats the offices — and that is when a regression here would
mean something.

## ✅ KS-1 step 4 — end to end through the production API, 2026-09-27

Probed `POST https://api.empowered.vote/api/essentials/coordinate-lookup` — the anonymous,
unauthenticated route a voter's browser actually calls. Not a hand-rolled `ST_Contains`.

| | Wichita City Hall | NEGATIVE: Nashville |
| --- | --- | --- |
| politicians returned | **42** | 48 |
| `STATE_EXEC` | 5 (Gov, Lt Gov, AG, SoS, Treasurer) | 1 |
| `NATIONAL_UPPER` / `NATIONAL_LOWER` | 2 / 1 | 2 / 1 |
| **`STATE_UPPER` / `STATE_LOWER`** | **0 / 0** | 1 / 1 |
| `jurisdictionGeoIds.state_senate` | **null** | `47021` |
| `locality.county_name` | **"Sedgwick County"** | "Davidson County" |

### 🔴 `state_senate` comes back NULL for Wichita, and that is CORRECT — it is not a load fault

The polygons are in production and resolve to `20029` / `20103` in SQL. The API still reports null,
because `jurisdictionGeoIds` is built by `pickJurisdictionFromDistrictRows` from the rows of
`buildDistrictQuery`, and that query's `DISTRICT_JOINS` opens with

```sql
JOIN essentials.offices o ON o.district_id = d.id   -- INNER
```

▶ **A district with no offices produces no row, so it cannot appear in `jurisdictionGeoIds`.**
Kansas has zero legislative offices, so null is the only correct answer today. This was read from
the source, not inferred from the symptom.

🟢 **And the negative control is what makes that null meaningful**: Nashville populates the very
same fields (`47021` / `47051`). The field is not broken — Kansas simply has nothing to put in it
yet. ⚠ Note the contrast inside one response: `locality.county_name` **does** say "Sedgwick
County", because that comes off the geofence name rather than the office-joined path. **Geometry is
being read; occupancy is what is missing.**

### The per-district control the reachability gate cannot run

`check:reachability`'s `ST_COVERS_ROUNDTRIP` samples `ORDER BY d.id LIMIT 500` over a **uuid**, and
its sample CTE requires `EXISTS (offices + current holder + active politician)`. Kansas satisfies
neither, so **all 165 districts are excluded from it**. So the roundtrip was run here directly,
over every one, using the real `MTFCC_DISTRICT_TYPE_GUARD` clauses (`G5210→STATE_UPPER`,
`G5220→STATE_LOWER`; the guard's catch-all cannot fire for these two, as both MTFCCs sit in
`FALLBACK_EXCLUDED_MTFCCS`).

| | probed | resolved itself | exactly one match | cross-state leaks |
| --- | --- | --- | --- | --- |
| `STATE_UPPER` | 40 | **40** | 40 | 0 |
| `STATE_LOWER` | 125 | **125** | 125 | 0 |

🟢 **And the probe was proved able to FAIL.** Re-run giving each district its *neighbour's* point,
`wrongly_resolved_itself` is **0 of 165** and `correctly_failed` is **165 of 165**. A uniform
"165/165 pass" from a detector nobody has watched fail is not evidence; this one has been watched.

### 🟢 The 83 `geo_id` collisions do not fan out through the guard

Run over every Kansas district type with the real guard clauses: each type admits **exactly one**
MTFCC and there are **zero** `geo_id` mismatches — COUNTY→`G4020` (105), NATIONAL_LOWER→`G5200`
(4), STATE_LOWER→`G5220` (125), STATE_UPPER→`G5210` (40). A county sharing `20029` with a Senate
district cannot be reached from that Senate district's geometry.

## ▶ KS-2 stage 2 — the roster is verified, 2026-09-27. NOTHING WRITTEN.

Tool: `backend/scripts/build-ks-legislature-roster.mjs`, `--self-test` runs 6 controls.
**165/165 member pages name the member the roster names, at the seat it gives.** Zero departure
markers. No migration yet, no `politicians` row written.

### The source is better than any earlier slice's

The Legislature publishes a **first-party CSV** at `…/house/representatives/csv/` and
`…/senate/senators/csv/` — 125 and 40 rows with `District`, `Fullname`, `Party` and `County` as
real columns. No scraping heuristics, no name splitting. House 88 R / 37 D; Senate 31 R / 9 D.
All 125 and all 40 districts present, **no gaps and no duplicates**, so the roster itself reports
no vacancy.

🟢 **And kslegislature.gov does NOT soft-404**, unlike `legislature.ky.gov`. Bogus slugs return a
real HTTP 404 (~43.6 KB against ~46.6 KB for a real page). A missing member is detectable here.

### 🔴🔴 The CSV's departure columns are DEAD, and only a positive control established it

`Enddate` and `Endnote` are empty for all 125 House rows. That alone proves nothing — an empty
column is a uniform answer. So the same columns were read from the **completed 2023-24 biennium**,
where departures certainly happened: **also 0 of 125.**

▶ **The columns are never populated, so "no rows carry `Enddate`" must never be read as "no
vacancies".** This is MN-2's *a roster list page is not a change-check*, reproduced inside a CSV.
The 165-page sweep is what actually answers the question.

⚠ **And the departure detector keeps a blind spot no control can close.** It is proven to fire on
the language a departure would use (three planted phrases, all caught, on a page otherwise silent).
It is **not** proven that Kansas ever publishes such language. KY-2 had the same shape and said so.

### 🔴 The roster list is paginated at 20, and `per_page` makes it WORSE

`?per_page=200` returns **ten** slugs — fewer than the default twenty. The only reliable path is
`?page=N` until the stated total is reached, and the page states its own total ("Showing 1–20 of
125 representatives"). The tool pages to the expected count and fails if it cannot reach it.

### 🔴🔴 THE BLOCKER: the `Terms` block cannot date Kansas occupancy, and the markup is innocent

Every member page carries a Terms card of (chamber, span) rows. For most it reads cleanly —
`House 2013–Present`. For nine of 165 it does not, and **the raw HTML was read to confirm the
parser is not at fault**:

| seat | published Terms |
| --- | --- |
| House 81 Blake Carpenter | `2015–2022` · **`2022–Present`** · `2023–2024` · `2025–2026` |
| House 100 Daniel Hawkins | **`2013–Present`** · `2023–2024` · `2025–2026` |
| House 45 Mike Amyx | **`2019–Present`** · `2025–2026` |
| House 8 Chris Croft | **`2019–Present`** · `2023–2024` · `2025–2026` |
| House 108 Brandon Woodard | **`2019–Present`** · `2025–2026` |
| House 86 · House 70 · Senate 13 · Senate 10 | **no Terms rows at all** |

A span saying "Present" cannot coexist with a later span that has ended. ▶ **So the span ending in
"Present" does not reliably give an arrival year, and this tool reports the block rather than
converting it into a `term_start`.** KY-2's rule holds and is sharpened: *a published service
string is chamber-scoped **and may not be self-consistent**.*

🔴 **And "first elected" is not available either.** The CSV's `Firstterm` column is populated for
only **24 of 125** House and **3 of 40** Senate rows, and its latest value anywhere is **2015** —
both sparse and stale. Reported, never used.

⚠ **Even where the block IS coherent it answers the wrong question.** It gives service in the
*chamber*, not occupancy of the *district* — and Kansas redistricted in 2022, so a continuous
member may have changed district number. 23 members are chamber switchers and 15 carry same-chamber
gaps; both are the KY-2 trap.

### ✅ TERM STARTS ARE SOURCED — 162 of 165 to the DAY, 2026-09-27

🟢🟢 **THE JOURNALS ARE THE SOURCE, AND THEY ARE BETTER THAN ANYTHING AN EARLIER SLICE HAD.** The
Kansas Legislature publishes every daily Journal as a PDF. The **first day of each session** carries
the whole answer.

**`Journal of the House`, FIRST DAY, Monday, January 13, 2025** contains, verbatim:

> *"I, SCOTT SCHWAB, Secretary of State, do hereby certify that the following persons were elected
> members of the House of Representatives … for a two-year term beginning on the second Monday of
> January, A.D. 2025. … Done at the city of Topeka this 2nd day of December, A.D. 2024."*

then the oath — *"administered to them by Chief Justice Marla Luckert"* — and **the full sworn list,
districts 1 through 125**. The Senate's First Day does the same for all 40, administered by Justice
**Dan Biles**, with the jurat *"before me this 13th day of January, 2025."*

▶ **So the canvass and the oath are in ONE document.** No separate Secretary of State source was
needed. **`term_start = 2025-01-13`, precision `day`, for the 157 members still in the seat they
were sworn into — and the date is STATED, not computed.** The "second Monday" wording appears in
the certification, but the date is taken from the Journal's own header and jurat, which is why this
does not repeat the computed-oath-date failure of three earlier states.

🟢 **AND THE INTERIM APPOINTMENTS ARE IN THE JOURNAL TOO.** The 2026 First Day (January 12, 2026)
opens with `OATHS OF OFFICE` — *"The following members were sworn in during the interim"* — each one
certified, dated, and naming the predecessor and the officer who administered it:

| Seat | Arrival | Sworn | Replaced | Administered by |
| --- | --- | --- | --- | --- |
| House 85 | Steven Brunk | **2025-06-24** | Patrick Penn (resigned) | Asst. SoS Jennifer Cook |
| House 70 | Gregory Wilson | **2025-07-30** | Scott Hill (resigned) | Judge Heidi L. Anderson |
| House 33 | Carolyn Caiharr | **2025-09-05** | Michael Thompson (resigned) | Asst. SoS Jennifer Cook |
| House 5 | Courtney Sappington | **2025-10-13** | Carrie Barth (resigned) | Asst. SoS Jennifer Cook |
| House 86 | Abi Boatman | **2026-01-12** | Silas Miller (resigned) | Chief Justice Eric Rosen |

⚠ In every one the appointment date and the oath date coincide. **That is not a rule** — ND-3 proved
the gap varies — and it is not relied on: the Journal states both.

### 🔴 Three traps this pass caught

1. 🔴🔴 **THE OFFICIAL JOURNAL MISNAMES A SITTING MEMBER.** The sworn list reads **"Susan Wikle"**
   for House 10. Her slug is `rep_wikle_suzanne_1`, her page and `<title>` say **Suzanne Wikle**, her
   addresses are `Suzanne.Wikle@house.ks.gov` and `Suzanne4ks@gmail.com`, and her Terms read
   `House 2025–Present`. It is a typo in the primary record. ▶ **A name-keyed diff would have read
   it as a departure AND an arrival.** This is KY-2's *matching legislators by name across time is
   unsafe*, now proven against the official Journal itself — which is why the diff is
   **district-keyed**, with a person-level check on every surname match.
2. 🔴 **THE SENATE'S 2026 OATH IS "CEREMONIAL" AND DATES NOTHING.** Its First Day records Chief
   Justice Eric Rosen administering *"the **ceremonial** Oath of Office, for Senators Scott Hill and
   Silas Miller"* — both of whom had already been serving. Taking 2026-01-12 as their arrival would
   repeat KY-3's re-swearing trap exactly.
3. 🔴 **A SCHEDULED SWEARING IS NOT AN OCCURRED ONE.** The only date found for Senate 24 is a report
   published 2025-06-24 saying Hill *"will be sworn in … this Thursday, June 26"* — prospective, and
   from a broadcaster, not a record. It is a lead, not a source.

### Where each of the 165 stands

| | count | `start_precision` | source |
| --- | --- | --- | --- |
| Sworn 2025-01-13 and still seated | **157** | `day` | House & Senate Journals, First Day 2025 |
| Interim appointees | **5** | `day` | House Journal, First Day 2026, `OATHS OF OFFICE` |
| **Still open** | **3** | — | see below |

### ✅ THE 2026 JOURNAL SWEEP — House 121 is dated, and the Senate gap is now a FINDING

Swept **all 54 House journal days** of the 2026 session (Jan 12 – Apr 10) and **all 54 Senate days**.

🟢 **House 121 — Mike Storm, sworn 2026-03-16.** The `OATH OF OFFICE` record reads: *"I JENNIFER
COOK, Assistant Secretary of State, hereby certify that Mike Storm was appointed by the Governor,
March 16th, 2026, to fill the vacancy created by the **death of Rep. John Resman**, State
Representative for the 121st Legislative District"*, with the jurat *"before me this 16th day of
March, 2026"*, closing *"The House is now organized with 125 members."*
⚠ **The first vacancy in this slice caused by a death rather than a resignation** — and Resman still
appears in a later journal (Mar 23) being replaced on a conference committee, so a name search alone
would misdate this.

🔴 **THE SENATE PUBLISHES NO INTERIM-OATH RECORD AT ALL, AND THAT IS NOW CONTROLLED, NOT ASSUMED.**
Across all 54 Senate journal days the phrase *"appointed by the Governor"* appears on exactly three
— **and all three are bill text**, statutory language about boards and commissions. The one
`OATH OF OFFICE` heading outside the First Day is likewise bill text, about irrigation-district
directors. ▶ The identical method found **five real records in the House**, so this is the Senate
not publishing them, not the method failing.

🔴 **So Senate 24 Scott Hill and Senate 25 Silas Miller cannot be dated from the Journals.** Hill
replaced J.R. Claeys, who left for the USDA (delegate vote reported 2025-06-16, with a broadcaster
saying he *"will be sworn in"* on 2025-06-26 — prospective, and not a record). Miller replaced Mary
Ware. ▶ **Route: the Senate Secretary's office or the Secretary of State's commission record.**
⚠ `office_terms.start_precision` permits **`month`** — verified against the live CHECK — so a
June-2025 arrival that cannot be dated to the day is written `2025-06-01` / `month`, never guessed.

### 🔴🔴 Two tooling traps this sweep paid for

1. **THE JOURNALS PAGINATOR CLAMPS INSTEAD OF ENDING.** Page 11 is the last page of 2026 House
   journals; pages 12 through 20 all return **the same five rows**. A "page until empty" loop never
   terminates and double-counts. The `?per_page=200` oddity on the roster is the same family. ▶ Page
   to a **known total**, then stop — and de-duplicate on the PDF timestamp.
2. 🔴🔴 **A `\\` WRITTEN THROUGH A HEREDOC ARRIVED AS `\`, AND SILENTLY BROKE A DETECTOR.**
   `new RegExp('Brunk[\\s\\S]{0,400}?appointed by the Governor')` reached disk as `[\s\S]`, which
   JavaScript parses as the character class **`[sS]`** — a pattern that compiles, runs, and matches
   nothing. The sweep reported a clean `0/5` on records that were sitting in the file on one line,
   four characters apart. ▶ **Use literal `/…/` regex syntax in scripts written this way**, never a
   string-constructed one. **The positive control is the only reason this was caught** — it asserted
   that five known House oath records must be found, and they were not.

### ✅ THE TWO SENATE COMMISSIONS — chased, and they settle at `month`, 2026-09-27

Every online avenue was tried and each is recorded here so nobody repeats it:

| Source | Result |
| --- | --- |
| All 54 Senate journal days, 2026 session | **No interim-oath record exists** — controlled, see above |
| Governor's press releases (`governor.ks.gov`, site-restricted search) | **Nothing** for either name |
| Member pages, roster CSV | No dates (`Firstterm` sparse and stale, `Enddate` dead) |
| Contemporaneous local reporting | Gives the **convention** date, not the oath |

🔴 **AND ONE QUOTE SETTLES IT.** The Abilene Reflector-Chronicle, reporting Hill's selection:

> *"As of **June 18**, Hill does **not know the specific date and place of his swear-in**. He
> anticipates though it will be next week."*

▶ **The appointee himself did not know his own swearing-in date two days after the convention.** So
the "will be sworn in Thursday, June 26" figure circulating elsewhere is an **anticipation**, and no
contemporaneous source fixes the day. That is not a gap in the search; it is the state of the record.

**Both are therefore written at `month` precision — which is what that value exists for:**

| Seat | Written | Evidence |
| --- | --- | --- |
| Senate 24 **Scott Hill** | `2025-06-01` · `month` | Republican precinct convention **2025-06-16** (two independent reports agree); Claeys resigned for a USDA post, and Kansas law makes the precincts convene **within 21 days** of a resignation |
| Senate 25 **Silas Miller** | `2025-12-01` · `month` | Sedgwick County Democratic Party precinct election **2025-12-04** (Kansas Reflector, read directly); Ware announced her resignation **Nov 13** |

⚠ **Residual risk, stated rather than hidden:** if Hill's oath slipped into July, `month` June is
wrong. "Next week" from June 18 falls inside June, and the Senate was not in session so no floor
ceremony was needed — but this is an inference about a range, not a sourced day.
⚠ **A tertiary aggregator gives Miller "December 22, 2025".** It is not used: it is neither
first-party nor contemporaneous, and this programme's standard is that a DAY is claimed only where
individually sourced.

▶ **The day-precision record exists — it is simply not published.** Route if it is ever wanted: the
Secretary of the Senate, or the Secretary of State, who holds the commission itself.

### Final term-start position — 163 of 165 to the day, 165 of 165 dated

| | count | `start_precision` | source |
| --- | --- | --- | --- |
| Sworn 2025-01-13, still seated | **157** | `day` | House & Senate Journals, First Day 2025 |
| House interim appointees | **5** | `day` | House Journal, First Day 2026 |
| House 121 Mike Storm | **1** | `day` | House Journal, 2026-03-16 |
| Senate 24 Scott Hill | **1** | `month` | convention 2025-06-16; **no day-precision source exists** |
| Senate 25 Silas Miller | **1** | `month` | precinct election 2025-12-04; same |

## ✅ KS-2 duplicate-name checks — 2026-09-27. NOTHING WRITTEN.

Run against production with **exactly the guard's own predicate**, read from
`essentials.politician_name_duplicate_guard()`: `is_active`, and
`lower(btrim(first_name))` **and** `lower(btrim(last_name))` — **the PAIR**, not the full name.
🔴 **The pair came from ONE source** — the first-party CSV's `Firstname`/`Lastname` columns — never
mixed with the member page's display name or the Journal's sworn list. That is MN-2's rule: *a field
pair a constraint reads must come from one source.*

🟢 **Both controls behaved before the result was read:** the predicate finds `Daniel Elliott`
(2 active rows, the namesake KY-2 recorded) and returns nothing for a name that cannot exist.

### 6 of 165 collide with an active row, and they split two ways

**SAME PERSON — 4. Do NOT insert. Point at the existing row.** All four are sitting Kansas senators
running for higher office in 2026, which the guard's own message calls *"the normal case, not a
different person"*:

| Seat | Existing row is | Race |
| --- | --- | --- |
| Senate 7 Ethan Corson | same person | Governor of Kansas (D) |
| Senate 8 Cindy Holscher | same person | Governor of Kansas (D) |
| Senate 16 Ty Masterson | same person | Governor of Kansas (R) |
| Senate 19 Patrick Schmidt | same person | U.S. Senate, Kansas (D) |

**DIFFERENT PERSON — 2. Lift the guard for these two rows only, never for the migration.**

| Seat | Existing row is |
| --- | --- |
| House 120 Adam Smith (R, Wallace County) | **Adam Smith, U.S. Representative, WASHINGTON District 9** |
| Senate 10 Mike Thompson (R, Johnson County) | **Mike Thompson, U.S. Representative, CALIFORNIA District 4** |

### 🔴🔴 THERE ARE THREE MIKE THOMPSONS, AND TWO OF THEM SAT IN THIS LEGISLATURE AT ONCE

1. **Mike Thompson**, U.S. Representative, California 4 — already in the database.
2. **Mike Thompson**, Kansas **Senate District 10** — sworn 2025-01-13, still serving.
3. **Michael Thompson**, Kansas **House District 33** — sworn 2025-01-13, resigned, replaced by
   Carolyn Caiharr on 2025-09-05.

▶ **Two Kansans of that name were sworn into different chambers on the same day**, which is proof on
its face that they are different people. Only the senator remains, so the current roster holds one.
⚠ And the House one is published as *"Mike Thompson"* in the sworn list but *"Michael Thompson"* in
the 2026 resignation record — **so the guard's exact-pair test would not even have matched him.**

### Inside the roster

- **0** exact `(first, last)` pairs duplicated among the 165 — no two sitting members share a name.
- **4 surnames held by two sitting members**: Carpenter (House 81 Blake / House 75 Will), Ruiz
  (House 31 Louis / House 23 Susan), Smith (House 120 Adam / House 3 Chuck), Williams (House 30
  Laura / House 77 Kristey). ⚠ Not duplicates — and the reason every check in this slice is
  **district-keyed**.

### ▶ This changes the occupancy migration

**It creates 161 people, not 165.** The other four already exist, carry `is_incumbent = false` and
hold no office, so they are **UPDATE + a new `office_terms` row**, not an INSERT — and
`is_incumbent` must be set to `true` on them explicitly, the same rule that applies to an insert.

## ✅ KS-2 APPLIED 2026-09-27 — THE KANSAS LEGISLATURE IS SEATED

`CC_0156` (structure) + `CC_0157` (occupancy): **165 offices — 125 House + 40 Senate — 165 seated,
0 vacant, 161 people created, 4 reused.**

🔴 **THE LEASE HAD LAPSED 1h 25m BEFORE THE FIRST WRITE, AND ONLY `who` SAID SO.** `state:ks` was
extended to 14:52Z and the apply began at 16:17Z. Nothing warned at write time — the row simply
stops matching, exactly as CLAUDE.md says. It was re-claimed before anything was written (the
lapsed holder was this same author and machine, so no work was displaced). ▶ **Re-read `who`
immediately before a write, not only at session start.**

### Measured from outside, against a same-session baseline through BOTH connections

`DATABASE_URL` as `ev_api` and MCP as `postgres` agreed on every figure before the write.

| | baseline | after | delta |
| --- | --- | --- | --- |
| `politicians` | 89,183 | **89,344** | **+161 exact** |
| `offices` | 9,724 | **9,889** | **+165 exact** |
| `office_terms` | 9,660 | **9,825** | **+165 exact** |
| Kansas chambers | 0 | **2** | — |
| Kansas offices | 0 | **125 House + 40 Senate** | — |
| **seated** (`count(och.politician_id)`) | 0 | **165** | — |
| the 4 reused rows reading `is_incumbent` | 0 | **4** | — |
| `offices_missing_terms` | 422 / 238 | **422 / 238** | **unmoved** |
| Kentucky control | 138 | 138 | **unmoved** |

### ✅ Idempotent, proved by re-running BOTH

Every real write returned `INSERT 0 0` — chambers, offices, politicians, namesakes and both
`office_terms` paths — and the guarded `UPDATE` returned `UPDATE 0`. The only non-zero lines are
temp-table fills. Totals re-measured afterwards were unchanged.

### ✅ END TO END: the API now returns Kansas legislators where it returned none

| point | `state_senate` | `state_house` | returned |
| --- | --- | --- | --- |
| Wichita City Hall | **`20029`** (was `null`) | **`20103`** (was `null`) | Sen. Oletha Faust Goudeau · Rep. Angela Martinez |
| Kansas State Capitol, Topeka | **`20019`** | **`20057`** | Sen. Patrick Schmidt · Rep. John Alcala |
| NEGATIVE: Nashville | `47021` | `47051` | its own two, unchanged |

🟢 **Three independent confirmations in that table.**
1. **Senate 29 and House 103 are the districts the Kansas Supreme Court discussed BY NUMBER** in its
   VRA analysis of Sedgwick County — and the pre-flight anchors predicted exactly `20029`/`20103`
   for this point before anything was loaded.
2. **Topeka returns Senate 19, the discriminating anchor.** Under the 2012 plan it would read
   `20018`. The vintage proof holds all the way through to the rendered answer.
3. **Patrick Schmidt is one of the four REUSED rows** — the person who already existed as a U.S.
   Senate candidate. He renders as the sitting senator, so the UPDATE path is proved end to end,
   not just the INSERT path.

### ✅ Reachability — and a per-district control, because the gate's green is not enough

`check:reachability` green: `BAD_GEOMETRY` 4, `DEAD_GEOGRAPHY` 17, `UNREACHABLE` 7, all at baseline.
⚠ **Its `ST_COVERS_ROUNDTRIP` samples `ORDER BY d.id LIMIT 500` over a uuid, so a pass does not mean
these 165 were swept.** So the full roundtrip — including the occupancy joins and the whole reps
filter — was run over **every** Kansas district:

**`STATE_LOWER` 125/125 · `STATE_UPPER` 40/40 resolve through the complete address join.**

## The migrations as written and dry-run

Slots came from the allocator, never counted: **`CC_0156`** (structure) and **`CC_0157`**
(occupancy), both reserved to chris@empowered.vote before a line was written, and each file named
its slot immediately.

| | `CC_0156` structure | `CC_0157` occupancy |
| --- | --- | --- |
| creates | 2 chambers + **165 offices** (125 Representative, 40 Senator) | **161 people**, reuses **4**, writes **165 terms** |
| `staggered_term` | **false for BOTH** — a Kansas fact, not a copy of Kentucky's shape | — |
| precision | — | **163 `day` · 2 `month` · 0 year · 0 unknown** |
| `how_started` | — | 157 `elected` · 8 `appointed` |

🟢 **`staggered_term = false` for the Senate is sourced**: all 40 were elected in November 2024 and
all 40 took the oath together — *"The roll was called from the certified list of members-elect, with
forty members-elect present"*. Kansas does not stagger its Senate; Kentucky does, and copying
Kentucky's row would have been wrong.

### ✅ Dry-run against production, ending in ROLLBACK — and the rollback was confirmed

Both migrations ran in **one transaction** via `psql` (the only real dry-run — `ev_api` cannot do
DDL). Inside the transaction:

| | baseline | inside the transaction | delta |
| --- | --- | --- | --- |
| `politicians` | 89,183 | 89,344 | **+161 exact** |
| `offices` | 9,724 | 9,889 | **+165 exact** |
| `office_terms` | 9,660 | 9,825 | **+165 exact** |
| the 4 reused rows reading `is_incumbent` | 0 | **4** | — |

Both gates printed their OK notice. **After `ROLLBACK`, every one of those eight figures returned to
the baseline exactly** — the rollback was verified to have reverted, not assumed.

### ✅ SIX GATES WATCHED FAILING, EACH FOR ITS OWN REASON

| Tamper | Gate that fired |
| --- | --- |
| one office removed | `expected 125 House offices` |
| an office placed on a **COUNTY** district | `1 legislative office(s) landed on a non-legislative district` |
| one term deleted | `expected 165 terms` |
| a reused row left `is_incumbent = false` | `1 seated Kansas legislator(s) are not is_incumbent/is_active` |
| one person seated in two districts | `1 person(s) hold more than one Kansas legislative seat` |
| a term rewritten as `year` | `1 year and 0 unknown precision term(s)` |

🔴 **TWO TAMPERS FIRST TRIPPED AN EARLIER GATE, WHICH IS THE KNOWN ORDERING PROBLEM.** Adding an
office also raises the Senate **count**, and rewriting any row as `year` necessarily drops an earlier
**precision count** — so in those two runs the blocking gate was relaxed (Senate 40→41, day 163→162)
**for that run only**, to reach the gate actually under test. KY-2, KY-3 and KY-4 each hit this.

🟢 **The occupancy gate counts `och.politician_id`, never `count(*)`** — `office_current_holder`
LEFT JOINs from `offices`, so a vacancy is a NULL `politician_id` and `count(*)` would pass
vacuously. That trap is documented in the gate itself.

### Checks

✅ `check:migrations` — 2 added, tree scan clean · ✅ `check:reservations` — each in a slot **its own
author** reserved · ✅ `check:occupancy` — *"every politicians INSERT names is_incumbent"*.

🟢 **Applied 2026-09-27 — see the section above for what production measured afterwards.**

### What stage 2 still owes

1. ✅ **A term-start source — DONE.** The Journals give 162 of 165 to the day.
2. ✅ **Every arrival is dated** — 163 to the day, 2 at `month`. Nothing is open here.
3. ✅ **Duplicate-name checks — DONE.** 6 collisions: 4 the same person, 2 genuinely different.
4. ✅ **The two migrations are WRITTEN and DRY-RUN** — `CC_0156` + `CC_0157`, six gates watched
   failing, rollback confirmed reverted, three CI checks green.
5. ✅ **APPLIED 2026-09-27** — measured from outside through both connections, idempotent on
   re-run, probed end to end, and 165/165 resolve through the full address join.
6. ▶ **NEXT: stage 3 — Wichita city council.** Unmeasured.

## Expected scope for the slice

| Stage | Owed | Basis |
| --- | --- | --- |
| 1 geography | **165** — 40 sldu + 125 sldl | measured above; place/county/cd already present |
| 2 legislature | **165 offices** — 125 House + 40 Senate | Kansas holds zero today |
| 3 Wichita | unmeasured | city council, from the charter |
| 4 Sedgwick County | unmeasured | Kansas county officers, from state law |
| 5 assets | 165 + city + county portraits, plus a `wichita` banner | |

🔴 **WICHITA'S BANNER COLLIDES WITH THE KANSAS STATE BANNER** — one of four such cities in the
programme (with Miami, Detroit and Charlotte). ▶ **Read `states/KS.jpg` in the 6:1 band before
choosing anything**; Charlotte and Lexington both turned on whether the state banner actually shows
the subject its credit names.

## Next steps, in order

1. ✅ **DONE 2026-09-26 — the map vintage is proven**, against KLRD's own enacted plan files, with
   two controls that fail as required and a `--self-test` that makes the proof gate itself fail.
   Nothing has been written to production.
2. ✅ **DONE 2026-09-26 — the allowlist entry and the pre-flight block are in**, with every
   assertion watched failing first. Still nothing written to production. See below.
3. ✅ **APPLIED 2026-09-27 — 165 boundaries and 165 districts are in production.** Measured from
   outside against a same-session baseline taken through both connections, and idempotent on
   re-run. See below.
4. ✅ **DONE 2026-09-27 — probed end to end through the PRODUCTION API**, with a negative control
   outside Kansas and a per-district control over all 165. See below.
5. ▶ **STAGE 2 IN PROGRESS.** 165 offices, 125 House + 40 Senate. Kansas holds zero today.
   **The roster is built and verified; TERM STARTS ARE NOT ESTABLISHED and that is the blocker.**
   See below.

## Debts this slice already owes

- Nothing to production. Nothing has been written.
- ⚠ **This file lived only on `knight/ks-slice14` for its first day.** A session starting in the
  `master` checkout read `MEMORY.md`, found PROGRAM.md's KS row still blank, and found no `ks.md`
  at all. The branch is pushed, so nothing was lost — but **the handoff chain only works from the
  slice's own worktree.** `C:/ev-accounts-ky` holds this branch despite the Kentucky name.
