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

⚠ ~~`PROGRAM.md`'s `626` column for Kansas is COUNTY SUBDIVISIONS, not places.~~
🔴🔴 **THAT LINE IS WRONG AND WAS CORRECTED 2026-09-27.** `load-state-tiger-boundaries.ts` says
repeatedly that **`G4110` is INCORPORATED MUNICIPALITIES** — the elected governments this programme
seats — that **`G4210` is CDPs**, statistical and deliberately filtered out, and that **`G4040`** is
county subdivisions. So Kansas's **626 `G4110`** rows ARE its places and PROGRAM.md's column was
right all along; the **114 `G4210`** rows are CDPs.
▶ **The KS-1 conclusion is unaffected — Kansas owes no `place` load either way — but the LABEL
mattered: Wichita city is `2079000`, MTFCC `G4110`.** A stage-3 session hunting for it among the
114 `G4210` rows would have found nothing and concluded the city was missing.

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

## ▶▶ OPEN STAGE 3 HERE — prepared 2026-09-27, nothing started

**You are in worktree `C:/ev-accounts-ky`, branch `knight/ks-slice14`** (a Kentucky directory name
holding the Kansas branch). At preparation time: **12 ahead of master, 0 behind, working tree clean,
HEAD pushed.** 🔴 **This file is NOT on master** — a session in `C:/EV-Accounts` cannot read it.

**Done:** stage 1 (geography) and stage 2 (the legislature) are APPLIED and verified.
**Stage 3 is Wichita city council, and nothing about it has been measured.**

### First moves

1. 🔴 **`npm run steward --prefix backend -- who` FIRST, and again immediately before any write.**
   The lease lapsed silently between plan and apply during stage 2. `state:ks` was re-claimed
   2026-09-27 and runs to **2026-09-28 16:17Z** — it will likely need extending.
2. `git fetch origin` and check drift. The hot files are the generic TIGER loader and `PROGRAM.md`.
3. Read `PROGRAM.md`'s KS row for where the programme stands.

### What is already true, measured 2026-09-27

| Fact | Value |
| --- | --- |
| **Wichita city boundary** | **`2079000`, MTFCC `G4110`** (an incorporated municipality) |
| Wichita as a county subdivision | `2017379000`, `G4040` — a different row, do not confuse them |
| Sedgwick County | `20173` (`G4020`) |
| Kansas `LOCAL` / `LOCAL_EXEC` districts | **0** |
| Kansas local or county **offices** | **0** |
| `governments` rows for Wichita or Sedgwick | **0** — the government row must be created |
| Kansas custom (`X####`) boundaries | **0** — council-district geometry is NOT loaded |

▶ So stage 3 needs, in order: the **office inventory from the charter**, a `governments` row, council
**district geometry** (Wichita publishes its own; there is no TIGER layer for city council), then
structure and occupancy migrations on two fresh `CC_` slots.

### The rules most likely to bite here

- 🔴🔴 **READ THE CHARTER'S OWN SENTENCE — it is the office inventory.** KY-4 found spec §3.2 simply
  wrong for Lexington, and KY-3 found the city's own councilmembers page inventing a Vice Mayor
  office that does not exist. **Do not infer a council's shape from other cities.**
- 🔴 **A certified election result is not a fact about who holds the seat** — it paid twice in
  Fayette. Confirm every seat against a source independent of the result.
- 🔴 **The oath date must not be computed.** Three states have paid for that. Kansas's *legislature*
  publishes its oath in the Journal; a city will not, so expect to source arrivals individually.
- 🔴 **`politicians.is_incumbent` explicitly on every insert**, and remember stage 2 found **4 of 165
  already existed** — run the duplicate check with the guard's own predicate before writing.
- 🔴 **Wichita's banner collides with the Kansas state banner** (one of four such cities). Read
  `states/KS.jpg` in the 6:1 band before choosing anything. That is stage 5, not now.

## ▶ KS-3 OPENED 2026-09-27 — the office inventory and the roster are SOURCED. NOTHING WRITTEN.

Lease `state:ks` extended to **2026-09-28 04:33Z** before any work. Branch `knight/ks-slice14`,
**0 behind master**, 13 ahead. Baseline re-measured against production in this session and it
matches what stage 2 left: **0** `LOCAL`/`LOCAL_EXEC` districts, **0** local offices, **0**
`governments` rows for Wichita or Sedgwick, **0** `X####` boundaries. Kansas holds 176 offices —
125 `STATE_LOWER`, 40 `STATE_UPPER`, 5 `STATE_EXEC`, 4 `NATIONAL_LOWER`, 2 `NATIONAL_UPPER`.

### 🟢 THE OFFICE INVENTORY IS SEVEN, AND THE CODE SAYS IT TWICE IN TWO UNRELATED PLACES

**`Sec. 2.04.005(a)`**, verbatim: *"All references to the 'city council,' 'council,' or 'members of
the council,' shall be deemed to be to the entire governing body and members thereof consisting of
**six council members and the mayor**."*

The second statement is in a section about licence appeals and has nothing to do with defining the
council — which is what makes it a real check rather than a restatement. **`Sec. 2.04.130`-series**:
*"The panel of three City Council members shall be chosen on a rotating basis by **District Numbers
1—6 with the Mayor being number 7**."*

▶ **7 offices: Mayor (at-large) + Council Member, Districts 1–6.** `Sec. 2.04.005(c)` corroborates
arithmetically — a majority *"shall mean four members"*, which is a majority of seven.

### 🔴🔴 THERE IS A VICE MAYOR, AND IT IS NOT AN OFFICE — KY-3's TRAP, REFUTED BY THE RECORD

Lexington's own councilmembers page invented a Vice Mayor office that did not exist (KY-3). Wichita
**does** have a Vice Mayor, which makes the trap sharper here, not weaker.

`Sec. 2.04.010`: the vice mayor is *"chosen by a majority written vote of the council **from among
its membership**"* for *"a term of one year"*. The city council's own minutes state it directly —
Mayor Wu, 2026-01-13: *"**By ordinance, this position is for a term of one year, and it's rotated
among the six council members.**"* Dalton Glasscock holds it for 2026 **and holds District 4**; J.V.
Johnston held it for 2025 **and holds District 5**.

▶ **The Vice Mayor is an internal annual rotation among the six, not a seat.** Writing it as an
office would seat one person twice and trip the duplicate-seat gate — or, worse, not trip anything.
⚠ The city's own District 4 page says Glasscock *"was selected by the City Council to serve as Vice
Mayor in 2026"*, which is exactly the sentence that misled KY-3. **Read the ordinance, not the bio.**

### The roster — district-keyed, and confirmed by three independent sources

🔴 **District-keyed, never name-keyed** — and this slice has a live reason. The minutes carry
**Brandon Johnson** (District 1, outgoing) and **J.V. Johnston** (District 5, sitting) in the same
document, and the January 12 minutes misspell the former as *"Council Member Brandon **Johnston**"*
in the very paragraph that also calls him Johnson. That is the KS-2 *"Susan/Suzanne Wikle"* finding
reproduced in a city record: **the official minutes misname a member, and a name-keyed read would
see one departure and one arrival that never happened.**

| District | Member | City page | Jan 13 2026 minutes | GIS `MEMBER` |
| --- | --- | --- | --- | --- |
| Mayor | Lily Wu | ✅ | ✅ | — (at-large, no polygon) |
| 1 | Joseph Shepard | ✅ | ✅ | ✅ |
| 2 | Becky Pattison Tuttle | ✅ | ✅ | ✅ |
| 3 | Mike Hoheisel | ✅ | ✅ | ✅ |
| 4 | Dalton Glasscock | ✅ | ✅ | ✅ |
| 5 | J.V. Johnston | ✅ | ✅ | ✅ |
| 6 | Maggie Ballard | ✅ | ✅ | ✅ |

The minutes of **2026-01-13** open: *"The City Council met in regular session with Lily Wu, JV
Johnston, Joseph Shepard, Becky Tuttle, Mike Hoheisel, Dalton Glasscock, and Maggie Ballard."*
**Seven named, present, in the city's own record.**

🟢 **And each member page NAMES ITS OWN DISTRICT**, so the page-id → district map is read, never
inferred: `651`→D1, `670`→D2, `695`→D3, `708`→D4, `751`→D5, `762`→D6, `785`→Mayor. The GIS layer's
`HYPERLINK` field points at those same seven page ids, which is a third agreement on the mapping.

### 🔴🔴 THE CITY'S OWN BIOS ARE STALE FOR THE THREE SEATS THAT WERE UP IN NOVEMBER 2025

District 3's page still reads *"elected … in November 2021 and was officially sworn in on January
10, 2022"*; District 6's reads *"elected … in November 2021 and sworn in on January 10, 2022"*.
Both were on the ballot again in **November 2025** and both were re-sworn in January 2026.

▶ **A source can be AUTHORITATIVE FOR ONE FIELD AND STALE FOR ANOTHER** — the bios are right about
the arrival and silent about the re-election. The Knight rule *"a roster's per-person label says how
someone ARRIVED, not what they are now"* is what caught this.

### ✅ THE OATH DATE IS READ, NOT COMPUTED — and the two candidate dates are both real meetings

`Sec. 2.04.010` says the swearing-in is at *"a special meeting called on the **second Monday in
January** of each even-numbered year"*. The second Monday in January 2026 is **January 12**. 🔴 **That
agreement is a coincidence this slice refused to rely on** — three states have paid for a computed
oath date, and Wichita held council meetings on **January 6, January 12, January 13 AND January 14,
2026**, so the calendar alone picks the wrong one as easily as the right one.

**The record settles it.** `CITY COUNCIL PROCEEDINGS, January 12, 2026 — Wichita, Kansas, Monday,
06:00 PM, OPENING OF SPECIAL MEETING`, City Clerk Shinita Rice:

> **IV) Oath of Office Administered by Judge Jones for Newly Elected Council Members**
> 1.) Oath of Office for District I Council Member Joseph Shepard
> 2.) Oath of Office for District III Council Member Mike Hoheisel
> 3.) Oath of Office for District VI Council Member Maggie Ballard

⚠ **The January 13 meeting is a different oath** — the Vice Mayor's. Its agenda item reads
*"Selection of the Vice Mayor and Oath of Office"*. **Two oaths two days apart, and only one of them
seats anybody.**

### 🔴🔴 IT IS A RE-SWEARING FOR TWO OF THE THREE, AND THE MAYOR SAYS SO IN THE SAME MINUTES

> *"Congratulations to our **re-sworn-in** council members, Hoheisel and Ballard and **new** council
> member, Shepard."* — Mayor Wu, closing the January 12 special meeting

▶ **`office_terms` carries CONTINUOUS occupancy, so a re-election must never overwrite the earlier
start** — the CO-3 rule, paid for again in KY-3 (five of eighteen) and NC. So `2026-01-12` is the
start of the 2026-30 *term* for Hoheisel and Ballard, and it is **their term start only for
Shepard**. Hoheisel's and Ballard's rows must reach back to their 2022 arrival.

⚠ **This is the opposite disposition from what stage 2 wrote**, and the difference is real rather
than an inconsistency: KS-2's 157 legislators were all sworn on one day into a two-year term, and no
evidence distinguished a continuing member's earlier arrival. Here the distinction is **stated in
the record**, so it must be honoured.

### Where each of the 7 stands — 1 of 7 dated, 6 OPEN

| Seat | Member | Continuous since | Status |
| --- | --- | --- | --- |
| D1 | Joseph Shepard | **2026-01-12** · `day` | ✅ **SOURCED** — sworn at the special meeting; predecessor Brandon Johnson left after 8 years |
| D3 | Mike Hoheisel | `2022-01-10`? | ▶ bio only — **needs the January 2022 record**; 2022-01-10 is also a second Monday, so the bio may itself be a computed date |
| D6 | Maggie Ballard | `2022-01-10`? | ▶ same |
| D2 | Becky Pattison Tuttle | **appointed 2019** | ▶ page says *"appointed (2019) and twice elected (2019 and 2023)"* — continuous occupancy runs from the **appointment**; no date yet |
| D4 | Dalton Glasscock | Jan 2024? | ▶ elected **2023-11-07** (page); needs the January 2024 swearing-in record |
| D5 | J.V. Johnston | Jan 2024? | ▶ elected 2023; same |
| Mayor | Lily Wu | Jan 2024? | ▶ page says *"sworn in as Wichita's 103rd mayor in January 2024"* — **month only**; needs the record |

▶ **Route for all six: the Agenda Center holds minutes back through the earlier cycles** —
`https://www.wichita.gov/AgendaCenter/ViewFile/Minutes/_MMDDYYYY-<id>`. The January 2024 and January
2022 special meetings are the equivalents of the January 12, 2026 one read above.

### ✅ The council-district geometry exists, is the city's own, and has NO superseded sibling

`https://gismaps.wichita.gov/ageweb/rest/services/COWGIS/Districts/MapServer/3` — *Council
Districts*, polygon, **6 features**, `COUNCIL` contiguous **1..6**, no gaps, no duplicates,
`exceededTransferLimit` absent.

- 🟢 **The Lexington four-layer trap does not apply.** The whole `Districts` MapServer was
  enumerated: 23 layers, and **exactly one** is council districts. There is no `Council_District_2012`
  sibling to be confused with — and equally, **no sibling to use as the vintage control**.
- 🔴 **Native SR is `102100`/`3857` (Web Mercator), so `outSR=4326` is load-bearing**, exactly as in
  KY-1 and KY-3.
- ⚠ **The `MEMBER` attribute matches the roster 6 of 6 and is CURRENT** (it reads Shepard, not the
  departed Brandon Johnson), which proves the layer is maintained. 🔴 **It is NOT a vintage proof** —
  KY-2 found a state GIS layer carrying a stale roster beside correct geometry. Recorded as
  corroboration only.
- ⚠ **Two hub catalogue entries — *Wichita Council Districts* and *Wichita Council Districts -
  Census* — resolve to the SAME layer URL.** A count cannot tell them apart because there is nothing
  to tell apart. Do not read the second as a separate map.
- 🟢 **Layer 1 of the same MapServer is `BOCC`** — the Sedgwick County commission districts. That is
  stage 4's geometry, found early and recorded here.

▶ **The vintage is NOT yet proved, and there is no in-org prior map to test against.** Wichita
redistricted after the 2020 census. Candidate controls: Sedgwick County GIS publishes its own Wichita
council-district maps (an **independent digitization — needs a tolerance**, never a byte compare), and
the redistricting ordinance itself. **Do not load until a discriminating control exists.**

### What KS-3 owes next

1. ▶ **The six remaining term starts**, each from a January swearing-in record, never computed.
2. ▶ **A vintage proof for the six polygons**, with a control that can fail.
3. ▶ A `governments` row for Wichita — there is none.
4. ▶ The duplicate-name check with the guard's **own** predicate (`is_active` + the
   `lower(btrim(first_name))`/`lower(btrim(last_name))` **pair**, from ONE source). Stage 2 found
   4 of 165 already present; ⚠ **`Joseph Shepard`, `Mike Hoheisel` and `Maggie Ballard` are ordinary
   names and must be checked, not assumed new.**
5. ▶ Two fresh `CC_` slots from the allocator — structure and occupancy. **Not yet reserved.**

### Sources captured to disk, `backend/data/seed-ks-2026/`

| File | What it is |
| --- | --- |
| `wichita-city-council-page.html` | `wichita.gov/599/City-Council` — *"seven-member Council … four-year terms … staggered"*, *"Six Council members are elected by district, and the Mayor is elected at-large"* |
| `wichita-member-{651,670,695,708,751,762,785}.html` | the seven member pages, each naming its own district |
| `wichita-council-minutes-2026-01-12.pdf` | **the swearing-in special meeting** — 15 pages |
| `wichita-council-minutes-2026-01-13.pdf` | Vice Mayor selection + the seven-member attendance line |
| `sedgwick-2025-general-election-night.pdf` | Sedgwick County election-night results, Nov 2025 ⚠ **unofficial — a certified result is not a fact about who holds the seat, and this is not even certified** |
| `_council-attrs.json`, `_council-layer3.json`, `_districts-mapserver.json` | the GIS layer, its metadata and the full 23-layer enumeration |


## ✅ KS-3 — ALL SEVEN TERM STARTS SOURCED TO THE DAY, 2026-09-27. NOTHING WRITTEN.

`state:ks` live to 2026-09-28 04:33Z, re-read before this work. Branch merged up from master
(was 17 behind, now 0 behind / 15 ahead; the merge was clean and done in this worktree).

**7 of 7 to the day. Zero computed, zero guessed, zero at `year` or `unknown` precision.**

| Seat | Member | Continuous since | Prec. | How | The record |
| --- | --- | --- | --- | --- | --- |
| Mayor | Lily Wu | **2024-01-08** | day | elected | Jan 8 2024 minutes, §VI, oath by **Judge Roush** |
| D1 | Joseph Shepard | **2026-01-12** | day | elected | Jan 12 2026 special, §IV, oath by **Judge Jones** |
| D2 | Becky Tuttle | **2019-01-15** | day | **appointed** | motion of Jan 8 2019 + oath Jan 15 2019, **Judge Jones** |
| D3 | Mike Hoheisel | **2022-01-10** | day | elected | Jan 10 2022 special, oath by **Judge Jennifer Jones** |
| D4 | Dalton Glasscock | **2024-01-08** | day | elected | Jan 8 2024 minutes, §VII.2, oath by **Judge Kehr** |
| D5 | J.V. Johnston | **2024-01-08** | day | elected | Jan 8 2024 minutes, §VII.3, oath by **Judge Kehr** |
| D6 | Maggie Ballard | **2022-01-10** | day | elected | Jan 10 2022 special, oath by **Judge Jennifer Jones** |

### 🔴🔴 THE MOST WIDELY PUBLISHED DATE FOR TUTTLE IS THE VOTE, NOT THE TERM — WRONG BY A WEEK

Every secondary source says Becky Tuttle was *"appointed January 8, 2019"*. **January 8 is the day
the Council voted.** The motion in the minutes of that meeting says what the term actually is, in
its own words:

> *"Mayor Longwell moved to pursuant to Section 2.04.040 of the City Code, moves that the City
> Council appoint Becky Tuttle to serve as the District II Council Member to fill the unexpired term
> of Council Member Pete Meitzner, **for a term commencing January 15, 2019** and ending January 13,
> 2020. Motion carried 6 to 0, (Abstained: Meitzner)."*

🟢 **And the two dates are independently confirmed to be different things.** The minutes of
**January 15, 2019** record: *"Oath of Office administered to Council Member Becky Tuttle by Judge
Jones. Judge Jones administered the oath of office to **new** District II Council Member Becky
Tuttle."* She also appears in that meeting's attendance line and not the previous one.

▶ **The commencement the motion names and the oath fall on the same day, and it is not the day of
the vote.** This is the Knight rule *"a certified result is not a fact about who holds the seat"* in
its appointment form: **a selection vote is not a term start either.** Taking the reported date
would have put her in the seat a week early.

⚠ Meitzner left because he won a Sedgwick County Commission seat — the vacancy has a cause on the
record, which is why `how_started = appointed` is safe to assert.

### 🟢 The re-swearings were identified from the record, never inferred

Three of the seven have been sworn more than once, and `office_terms` carries **continuous**
occupancy, so none of those later oaths is a term start:

- **Tuttle** — Jan 8 2024: *"this is the **third** time she has been sworn in"* (appointed 2019,
  elected 2019, elected 2023). Mayor Whipple, same meeting: *"**welcome back** Council Member
  Tuttle"*, against *"two **new** Council Members … JV Johnston and Dalton Glasscock"*.
- **Hoheisel and Ballard** — Jan 12 2026: *"our **re-sworn-in** council members, Hoheisel and Ballard
  and **new** council member, Shepard"*.
- ⚠ The Jan 10 2022 list marks the distinction in the document itself: *"Brandon Johnson, District I
  **(Incumbent)**"* against Hoheisel and Ballard with no such tag.

🔴 **So the city labels incumbency inconsistently across the three ceremonies** — a parenthetical in
2022, a sentence from the chair in 2024, and an adjective in 2026. **There is no field to read; it
has to be read as prose, per ceremony.**

### ⚠ Two documents disagree with themselves, and neither affects a date

Recorded so the next reader does not treat them as findings:
- The **Jan 10 2022** minutes head *"Monday, 06:00 A.M."* and then say the meeting was *"called to
  order at 6:06 **p.m.**"*.
- The **Jan 8 2024** minutes open *"met in **regular** session"* and close *"The City Council
  **Special** Meeting adjourned at 7:22 p.m."*
Both carry one unambiguous date, which is the field this slice needs.

### 🔴 The 2019 minutes are a `.docx`, and the Agenda Center does not reach them

The Agenda Center search covers 2022 onward; a 2019 query returns **empty**, and that emptiness is
trustworthy only because the *same* query shape returned rows for 2022 and 2024 minutes before it was
believed. Older minutes live in the **Archive Center** (`Archive.aspx?AMID=101`, 385 documents,
2019-2026) and are served as **Microsoft Word documents**, not PDFs — `ViewFile/Item/<ADID>` returns
`application/vnd.openxmlformats-officedocument.wordprocessingml.document`. A reader expecting a PDF
gets a file it cannot parse and no error.

## ✅ KS-3 duplicate-name check — 0 of 7 collide. All seven are NEW inserts.

Run with the guard's **own** predicate — `is_active`, and `lower(btrim(first_name))` **and**
`lower(btrim(last_name))`, the **pair**. 🔴 The pair came from **ONE source**, the Jan 13 2026
attendance line, never mixed with the member pages or the GIS layer.

**All seven return 0 active matches**, and `J.V. Johnston` was checked **both ways** — `JV` and
`J.V.` — because the guard lowercases and trims but does **not** strip punctuation, and the city's
own sources disagree on it (the minutes write `JV Johnston`, the page and the GIS `MEMBER` field
write `J.V. Johnston`).

🟢 **A uniform zero is a broken detector until a control passes, so the predicate was proved able to
find people first:** `Daniel Elliott` → **2** active rows (the namesake KY-2 recorded), `Patrick
Schmidt` → 1, `Ty Masterson` → 1, and an impossible name → 0.

▶ **This is the opposite of KS-2**, where 4 of 165 already existed and needed the UPDATE path. The
Wichita occupancy migration is **7 inserts, 0 reuses** — and `politicians.is_incumbent` must still be
set explicitly to `true` on every one of them.

## What KS-3 still owes

1. ✅ **Seven term starts — DONE**, all to the day.
2. ▶ **A vintage proof for the six council polygons**, with a control that can fail. There is no
   in-org prior map, so the control has to come from outside the city's own service.
3. ▶ A `governments` row for Wichita — there is none.
4. ✅ **Duplicate-name check — DONE.** 0 collisions; 7 inserts.
5. ▶ Two `CC_` slots from the allocator — structure and occupancy. **Not yet reserved.**

### Sources added to `backend/data/seed-ks-2026/`

| File | What it is |
| --- | --- |
| `wichita-council-minutes-2024-01-08.pdf` | Mayor Wu, Tuttle (3rd), Glasscock, Johnston — 11 pages |
| `wichita-council-minutes-2022-01-10.pdf` | Johnson (incumbent), Hoheisel, Ballard — 5 pages |
| `wichita-council-minutes-2019-01-08.docx` | the appointment motion naming the Jan 15 commencement |
| `wichita-council-minutes-2019-01-15.docx` | Tuttle's oath, and her first attendance line |

## ▶ KS-3 vintage — MEASURED, NOT PROVED. STILL NOT LOADED, 2026-09-27.

The six polygons are **not loaded** and should not be until the last item below is settled.

### 🔴🔴 THE COUNTY IS NOT AN INDEPENDENT CHECK, AND ONLY MEASURING SHOWED THAT

Sedgwick County runs Wichita's elections and publishes its own council-district layer:
`gismaps.sedgwickcounty.org/arcgis/rest/services/Map/Op_Election_Dynamic_SP/MapServer/5` — **6 rows
with `CityCD = 'WI'`, `CouDistNo` 1..6**, and a `CouRepNM` naming the same six members. It reads
exactly like the independent digitization this slice wanted.

**It is the same geometry.** Measured after reprojecting both to 4326:

| | city layer | county layer |
| --- | --- | --- |
| per-district area agreement | — | **0.0000% on all six**, to 9 decimal places |
| vertices, districts 1-6 | 2143 · 6027 · 4597 · 5561 · 3735 · 2653 | **identical, all six** |
| coordinate bytes | — | differ (reprojection noise only) |

▶ **24,716 vertices matching one for one is not what two digitizations do.** The county layer is the
same source geometry, reprojected from Kansas State Plane South (`3420`) instead of Web Mercator
(`3857`). ⚠ **"Two sources agree" would have been a false claim, and the count-and-name match alone
would have supported it.** It is corroboration that the city's published boundary is the one the
ballot-issuing system holds — nothing more.
🔴 Native SR is `3420` on the county side and `3857` on the city side, so **`outSR=4326` is
load-bearing on both**.

### 🟢 The area metric discriminates, and that was measured before anything was concluded from it

| test | result |
| --- | --- |
| same district, two layers | **0.0000%** |
| smallest gap between two DIFFERENT districts (1 vs 5) | **0.083%** |
| largest gap (3 vs 4) | 57.4% |

**The nearest pair is ~570,000× the same-district disagreement.** An agreement this tight cannot be
an artifact of a metric too blunt to tell districts apart.

⚠ A centroid test was run as well and **5 of 6** county centroids land in the same-numbered city
district. District 3's area-weighted centroid falls **outside** its own polygon — the district is
concave. **That is a property of the shape, not a mismatch**, and it is why KY-3's rule that a
centroid test is too weak applies here twice over.

### 🔴🔴 A COUNCIL BOUNDARY IS NOT FIXED BETWEEN REDISTRICTINGS — IT MOVES WITH ANNEXATION

The Wayback Machine holds **four** captures of this exact endpoint, all in 2026 (May 9, May 21,
Jun 7, Aug 29). Comparing the May 9 capture with today:

| dist | 2026-05-09 | today | diff |
| --- | --- | --- | --- |
| 1 | 0.004891011 | 0.004913107 | 0.4508% |
| 2 | 0.006795108 | 0.006829638 | 0.5069% |
| 3 | 0.004587684 | 0.004590026 | 0.0510% |
| 4 | 0.008280954 | 0.008280859 | 0.0012% |
| 5 | 0.004905295 | 0.004909048 | 0.0765% |
| 6 | 0.006482672 | 0.006495928 | 0.2043% |
| **TOTAL** | 0.035942725 | 0.036018606 | **+0.211%** |

▶ **The total GREW.** A redistricting redistributes area and preserves the total — Lexington's did,
to 0.03%. This is the opposite signature: the city annexed land. **So the layer is actively
maintained, and the metric detects real change down to 0.0012%.**

🔴 **This reframes what a vintage proof can even mean here.** "Does this byte-match Map B as adopted
in 2022" is the WRONG question — Map B as adopted no longer equals the operative boundary, because
Wichita has annexed since. The right question is **"is this the boundary in force"**, and the
annexation drift is evidence that the layer tracks it rather than being a frozen copy.

### The documented map history

Not geometry, but it bounds the problem. The Commission of Electors (appointed July 2022) recommended
**Map A** and **Map B**; the Council approved **Map B on 2022-11-01 by 4-3**, effective
**2023-01-01**. DABs 1/3/5 preferred Map A, DABs 2/4/6 Map B. The city's own interoffice memo of
2022-09-19 records Map B as *"this map (which was 2H) … the first map that did not split any new
neighborhood associations. It has a total deviation with all six districts and 3.55%."* Kansas's next
council reapportionment follows the 2030 census, so **no redistricting has intervened since**.

### 🔴 WHAT IS NOT PROVED, AND WHY IT CANNOT BE FROM PUBLISHED SOURCES

**There is no reachable prior geometry, so there is no control that can FAIL on vintage.** Every
avenue was tried and each is recorded so nobody repeats it:

| Route | Result |
| --- | --- |
| A superseded sibling layer on the city server | **None.** All 23 layers of `COWGIS/Districts` enumerated; exactly one is council districts. No Lexington-style `_2012` twin — and therefore no twin to test against either |
| Other city ArcGIS folders | Enumerated `COWGIS`, `OpenData`, `MISC`, `CSEAM`, root. **No redistricting or historical service** |
| Wayback, pre-2023 capture of the layer | **None.** 4 captures, all 2026 |
| `wichita.gov/998` Redistricting Dashboard, `/997` Map B page | **Both hard 404** (~96 KB styled error pages) |
| County `Hosted/Redistricting_2022`, `2020_Redistricting_Webmap`, `Op_Census_Blocks_2020_SP`, `Op_2020_precinct__population_Sp` | **The whole `Hosted` folder is access-restricted** — `Request Rejected`, and ⚠ **Playwright gets the same rejection**, so it is a real restriction and not a UA/TLS block |
| City data hub search | Returns only the one live layer under two titles, both resolving to the same URL |

⚠ **And one of those rejections was served as a clean HTTP 200** with a `Request Rejected` body, which
is the standing rule about WAFs reproduced on a second vendor.

### ▶ The one test that would settle it, and what it needs

**Population deviation.** Map B's stated total deviation is **3.55%** across the six districts on
2020 census counts. The pre-2023 map was drawn on 2010 data and was out of balance by 2022 — that is
*why* it was replaced. So: assign 2020 census block population to the six current polygons, total the
deviation, and require ≈3.55%.

🟢 **That is falsifiable and discriminating** — the superseded map cannot produce Map B's deviation.
⚠ The county's population layers are restricted, so the blocks and P.L. 94-171 counts must come from
**the Census Bureau directly**, and the point-in-polygon has to be written (no geometry library is
available in this environment).

**Cheaper alternative:** ask City of Wichita GIS or the County Clerk for the pre-2023 council-district
layer. One email replaces the whole build, and a real prior map is a stronger control than a derived
statistic.

### Where the six polygons stand

| Fact | Status |
| --- | --- |
| 6 features, `COUNCIL` contiguous 1..6, no gaps, no duplicates, no paging | ✅ measured |
| The ballot-issuing system holds the same geometry | ✅ measured, vertex for vertex |
| The layer is live-maintained and tracks annexation | ✅ measured across 4 captures |
| The metric can detect change and can tell districts apart | ✅ measured |
| **The geometry descends from Map B and not its predecessor** | 🔴 **NOT PROVED — no control can fail** |

▶ ~~Do not load until that last line is closed.~~ **CLOSED 2026-09-27 — see below.**

## ✅ KS-3 VINTAGE — PROVED BY POPULATION DEVIATION, 2026-09-27. STILL NOT LOADED.

Tool: `backend/scripts/verify-wichita-council-vintage.mjs`. Needs no database. `--self-test` runs
three controls and every one must fail.

**The six polygons are balanced on 2020 census counts to a total deviation of 2.40%**, inside the
five percent the Commission of Electors was appointed to work to, and **they account for Wichita
city's 2020 population to 0.08%**.

| | measured |
| --- | --- |
| Sedgwick County 2020 blocks (TIGERweb layer 10) | **12,158**, no paging |
| assigned to a district | **7,384** · outside the city 4,774 · **in two districts 0** |
| population assigned | **397,864** against the city's **397,532** — **+332, 0.08%** |
| per-district deviation | −1.60 · +0.67 · −0.22 · +0.34 · +0.03 · +0.79 |
| **total deviation** | **2.40%** |

▶ **A map drawn on 2010 counts cannot be balanced on 2020 counts** — that imbalance is *why*
Wichita redistricted. 2.40% is a post-2020 map.

### 🟢 Three controls, each watched failing

| Control | Result |
| --- | --- |
| `strips` — the same blocks cut into six equal-width longitude bands | **236.34%** deviation — ✅ fails |
| `target` — tighten the ceiling onto a value the real map cannot meet | ✅ fails |
| `blocks` — drop every block in district 1, simulating a broken point-in-polygon | **120.56%**, *and* the population control fires at −64,915 (16.33%) — ✅ fails on two gates |

🔴 **`strips` is the one that matters.** A different partition of the same city into six parts gives
**236%**, about 98× the measured figure. **Tight balance is a property of THIS map, not of any
six-way split**, so the 2.40% is not an artifact of the method.

### 🔴 WHAT THIS DOES NOT PROVE, STATED RATHER THAN GLOSSED

- ⚠ **It cannot distinguish Map A from Map B.** Both were drawn to the same ≤5% standard on 2020
  data. It separates a **post-2020 map from the superseded pre-2023 one**, which is the failure mode
  that matters — Map A was never adopted, so it is never what the city publishes.
- ⚠ **The measured 2.40% does not reproduce the 3.55% attributed to Map B**, and the residual is
  explained but not eliminated: whole-block assignment by internal point, against a boundary that has
  annexed land since adoption. 🔴 **And the 3.55% itself is weak evidence** — it comes from a
  transcribed DAB discussion whose sentence is garbled (*"It has a total deviation with all six
  districts and 3.55%"*), not from a formal apportionment report.
- ▶ **So the gate asserts the Commission's five percent, not 3.55%.** An earlier version of the tool
  failed unless the figure landed within ±1.5pp of 3.55%; that window was chosen by the author, it
  happened to pass, and it claimed more than the evidence carries. It was replaced.

### ⚠ Two traps this test paid for

1. 🔴 **`api.census.gov` answers a keyless request with HTTP 200, `text/html`, and a page titled
   "Missing Key".** Judging by status would have read it as data. Population comes from **TIGERweb's
   own `POP100`**, never from the Data API.
2. 🔴 **TIGERweb layer 28 is Census Designated Places and returns a CLEAN EMPTY RESULT for Wichita**,
   which is an incorporated place. **Layer 26** is the right one and gives `GEOID 2079000`,
   `POP100 397,532`. This is the documented TIGERweb wrong-layer trap, hit and caught.

▶ **The six polygons may now be loaded.** They still need `governments` + structure + occupancy and
two `CC_` slots.

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
