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

🔴 **The three open seats.** Senate 24 **Scott Hill** (replaced J.R. Claeys, who left for USDA;
delegate vote reported 2025-06-16) and Senate 25 **Silas Miller** (replaced Mary Ware) — the Senate
prints **no interim-oath section**, unlike the House, so its arrivals are not in the Journals at
all. House 121 **Mike Storm** (replaced John Resman) changed after the 2026 First Day, so it will be
in a later 2026 daily Journal. ▶ **Route: sweep the 2026 daily Journals for Storm; for the two
senators, ask the Senate Secretary's office or the Secretary of State for the commission date.**
⚠ `office_terms.start_precision` permits **`month`** — verified against the live CHECK — so a
June-2025 arrival that cannot be dated to the day is written `2025-06-01` / `month`, never guessed
to a day.

### What stage 2 still owes

1. ✅ **A term-start source — DONE.** The Journals give 162 of 165 to the day.
2. ▶ **The three open arrivals above** — House 121 Storm from the 2026 daily Journals; Senate 24
   Hill and Senate 25 Miller from the Senate Secretary or the Secretary of State.
3. ▶ **Duplicate-name checks** against existing `politicians` rows. 🔴 Expect real collisions:
   MN-2 already found *a Kansas Libertarian* colliding with a Minnesota legislator, so Kansas names
   are known to exist in this database under other people.
4. ▶ **The two migrations** — structure (chambers + 165 offices) and occupancy (politicians +
   `office_terms`). 🔴 **Slots NOT yet reserved; allocate them with `steward slot CC`, never count.**
   🔴 Every insert must set `politicians.is_incumbent` explicitly.

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
