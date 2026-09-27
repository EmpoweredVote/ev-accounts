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

## ✅✅ KS-3 APPLIED 2026-09-27 — WICHITA IS SEATED

`X0070` (6 council boundaries) + **`CC_0159`** (structure) + **`CC_0160`** (occupancy):
**7 offices — Mayor + 6 council districts — 7 seated, 0 vacant, 7 people created, 0 reused.**

### Measured from outside against a same-session baseline

| | baseline | after | delta |
| --- | --- | --- | --- |
| `politicians` | 89,344 | **89,351** | **+7 exact** |
| `office_terms` | 9,825 | **9,832** | **+7 exact** |
| `offices` | 9,889 → 9,896 (CC_0159) | 9,896 | +7 then unmoved |
| Wichita **seated** (`count(och.politician_id)`) | 0 | **7** | — |
| `offices_missing_terms` | 422 / 238 | **422 / 238** | **returned to baseline** |
| Kentucky control (sldu+sldl) | 138 | 138 | **unmoved** |
| Kansas legislature control | 165 | 165 | **unmoved** |

🟢 **`offices_missing_terms` went 422 → 429 → 422.** CC_0159 created seven office rows with no terms,
which is exactly what that view is for; CC_0160 seated them and it returned to the KS-2 baseline.
**The transient +7 is the view doing its job, not drift.**

### The seven, as production now holds them

| Office | Holder | Since | Prec. | How |
| --- | --- | --- | --- | --- |
| Mayor | Lily Wu | 2024-01-08 | day | elected |
| Council Member, District 1 | Joseph Shepard | 2026-01-12 | day | elected |
| Council Member, District 2 | Becky Tuttle | **2019-01-15** | day | **appointed** |
| Council Member, District 3 | Mike Hoheisel | 2022-01-10 | day | elected |
| Council Member, District 4 | Dalton Glasscock | 2024-01-08 | day | elected |
| Council Member, District 5 | J.V. Johnston | 2024-01-08 | day | elected |
| Council Member, District 6 | Maggie Ballard | 2022-01-10 | day | elected |

**7 of 7 at day precision. 0 year, 0 unknown, 0 computed.** Party is NULL on all seven — the council
is nonpartisan by charter and this repo is antipartisan by design.

### ✅ END TO END through the production API

`POST https://api.empowered.vote/api/essentials/coordinate-lookup` — the anonymous route a voter's
browser calls. ⚠ **It takes `lat`/`lng`, not `latitude`/`longitude`**; the wrong field names return
**HTTP 422 `INVALID_COORDINATES`**, and a reader who judged by "0 politicians returned" would have
concluded Wichita was unreachable.

| point | returned |
| --- | --- |
| Wichita City Hall | **Mayor Lily Wu · Council Member, District 6 Maggie Ballard** |
| Riverside | Mayor Lily Wu · **District 6** Maggie Ballard |
| South Wichita | Mayor Lily Wu · **District 4 Dalton Glasscock** |
| NEGATIVE: Nashville | its own District 19 member, no Wichita officials |

🟢 **South Wichita returning a DIFFERENT district is the part that matters** — it shows the geometry
discriminates rather than returning one district for every point.

### 🟢 A RESULT WAS DOUBTED AND THE SOURCE SETTLED IT

City Hall resolving to **District 6** looked wrong: the redistricting memo discusses downtown in the
context of District 1's growth. So the city's **live** ArcGIS layer was queried for that exact point
and it answers **`COUNCIL 6 | Maggie Ballard`** — one feature. Production agrees.
▶ The doubt was wrong, and chasing it **validated the load against the authority for a specific
point**, which is worth more than the assumption would have been.

### Per-district round trip, through the complete occupancy join

**6 of 6** council districts' interior points resolve to **themselves**, each returning its own
member, with no fan-out. The loader additionally proved, before committing, that each polygon
contains its own point (6/6), that each resolves to **exactly one** district, and that there are
**0 cross-district leaks** — the negative half, because a uniform pass from a probe nobody has
watched fail is not evidence.

### Coverage

place **169.548** sq mi · districts **172.035** sq mi · **99.526%** of the place covered · **3.290**
sq mi outside it. ⚠ The overhang is expected and is the annexation finding again: the council layer
is maintained on a different cadence from the TIGER place polygon.

### Gates

✅ `check:reachability` — `BAD_GEOMETRY` 4, `DEAD_GEOGRAPHY` 17, `UNREACHABLE` 7, **all at baseline**.
✅ `check:occupancy` — *"every politicians INSERT names is_incumbent"*.
✅ `check:migrations` — 4 added vs origin/master, tree scan clean.

### The migrations as written

Slots from the allocator, never counted: **`CC_0159`** and **`CC_0160`**, both reserved to
chris@empowered.vote before a line was written, each file named its slot immediately.

- **`CC_0159`** refuses to run unless the six `X0070` boundaries AND TIGER place `2079000` exist —
  an office on a district with no polygon is invisible to every address search and nothing errors.
  It also **asserts that no office is called Vice Mayor**, which is the trap this slice was most
  likely to fall into.
- **`CC_0160`** counts `och.politician_id`, never `count(*)` — `office_current_holder` LEFT JOINs
  from `offices`, so a vacancy is a NULL and `count(*)` would pass vacuously. It also asserts nobody
  holds two Wichita seats, which is what a Vice Mayor office would have produced.
- Both idempotent; both dry-run against production inside `BEGIN … ROLLBACK`, and **the rollback was
  confirmed to have reverted** before either was applied (0 governments / 0 districts / 0 offices,
  then 0 seated).

### 🔴 `X0070` was chosen by reading, not by counting

`X0001`..`X0069` were in use; `X0070` was the next free. ⚠ **Nothing allocates custom MTFCC codes** —
the steward allocates migration slots only — so a concurrent slice could take the same code and no
mechanism would notice. Recorded as a gap, not a problem hit.

## What the slice still owes

1. ✅ Stage 1 geography · ✅ Stage 2 legislature · ✅ **Stage 3 Wichita** — all applied.
2. ▶ **Stage 4: Sedgwick County officers.** 🟢 Its geometry was found early and is recorded above:
   `Map/Op_Election_Dynamic_SP/MapServer` **layer 1 `BOCC`** on the county's own server.
3. ▶ **Stage 5: assets** — 7 Wichita portraits plus the legislature's 165, and a `wichita` banner.
   🔴 **Wichita's banner collides with the Kansas state banner** — read `states/KS.jpg` in the 6:1
   band first.

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

## ▶ KS-4 OPENED 2026-09-27 — the office inventory and all ten term starts are SOURCED. NOTHING WRITTEN.

`state:ks` extended to 2026-09-28 20:14Z at session start, re-read before this work. Branch 0 behind
`origin/master`, 19 ahead.

### 🔴🔴 THE HANDOFF NOTE POINTED AT THE WRONG LAYER, AND A THIRD SOURCE IS THE SAME DATA

The note carried forward from KS-3 read *"`Map/Op_Election_Dynamic_SP` layer 1 `BOCC` on
`gismaps.sedgwickcounty.org`"*. **Layer 1 of that service is `Election Dropboxes`, a POINT layer.**
Two servers were conflated: the `layer 1 BOCC` recorded at line 958 is the **City of Wichita's**
`COWGIS/Districts` MapServer, not the county's.

| Server / service | Layer | Name | Features |
| --- | --- | --- | --- |
| `gismaps.wichita.gov` `COWGIS/Districts` | 1 | `BOCC` | 5 |
| `gismaps.sedgwickcounty.org` `Map/Op_ElectionBOCC_Dynamic_SP` | 0 | County Commission Districts | 5 |
| `gismaps.sedgwickcounty.org` `Map/Op_Election_Dynamic_SP` | 6 | County Commission | 5 |

🔴 **All three are ONE digitization republished.** `Shape.STArea()` agrees across all three to
**1 part in 10^8** per district (D3 reads `12,724,603,279.496069` / `.496069` / `.496056`). The
city's copy is therefore **not** an independent control for vintage — it is the KS-3 "two hub
entries, one layer" trap one level up, and this time across two different organisations, which is
what made it look independent.

⚠ The county's whole `Hosted` folder is WAF-restricted (Playwright included), but the **`Map` folder
is not** — every query above is a plain `curl`.

### 🟢 THE INVENTORY IS TEN SEATS, AND ONLY THE STATUTE COULD HAVE GIVEN IT

**`KSA 19-101a(a)(6)`: a county "shall be subject to all acts of the legislature concerning
elections … and the election of county officers."** A Kansas county **cannot** add or remove an
elected county office by home rule. So the statute is not merely the best source for the inventory —
it is the only one that can be complete, and the county cannot contradict it.

| Office | Seats | Statute | Term | Term commences |
| --- | --- | --- | --- | --- |
| County Commissioner, districts 1–5 | 5 | `19-202` | 4y, staggered | 2nd Monday of January (`19-202(d)`) |
| County Clerk | 1 | `19-301` | 4y | 2nd Monday of January (`25-313(a)`) |
| County Treasurer | 1 | `19-501` | 4y | 🔴 **2nd Tuesday of OCTOBER** (`19-501`) |
| Register of Deeds | 1 | `19-1201` | 4y | 2nd Monday of January (`25-313(a)`) |
| Sheriff | 1 | `19-801a` | 4y | 2nd Monday of January (`25-313(a)`) |
| District Attorney, 18th Judicial District | 1 | `22a-101` | 4y | 2nd Monday of January (`22a-101(a)`) |

🟢 **`KSA 4-219`: "The county of Sedgwick shall constitute the 18th judicial district."** And
**`22a-101(b)` ABOLISHED the office of county attorney** in judicial districts 3, 10, 18 and 29.
Sedgwick has a **District Attorney and no County Attorney** — a seat a county-website inventory
would have mislabelled. `22a-101(a)` also declares the DA "in no event … an officer of any county",
which is why the DA belongs in its own chamber rather than under *Countywide Elected Officials*.

Excluded, each with the statute that excludes it — **not** by reading the org chart:

| Not a seat | Why |
| --- | --- |
| County Attorney | **abolished** in the 18th (`22a-101(b)`) |
| County Appraiser | appointed by the board (`19-430`) |
| County Surveyor | `19-1401` **repealed**; `19-1401a` makes it appointed |
| District Coroner | appointed by the board from medical-society nominees (`22a-226`) |
| County Auditor | appointed by the district court, and only in counties of 40,000–60,000 (`19-601`) |
| Election Commissioner | appointed by the **Secretary of State** in counties over 125,000 (`19-3419`) |

### 🔴🔴 THE COUNTY'S OWN "ELECTED AND APPOINTED OFFICIALS" PAGE CANNOT SETTLE THIS, AND SAYS SO

`/government/elected-and-appointed-officials/` lists **Appraiser · Clerk · District Attorney ·
Election Commissioner · Register of Deeds · Sheriff · Treasurer** — seven, in one list, with
**nothing marking which are elected**. Two of the seven are appointed. The title is honest; the list
is not usable as an inventory.

The election office's register is wider still. `/ElectedOffice/Officials/` is a **CSV of everything
on a Sedgwick ballot**: 744 rows including **Court of Appeals Judge (14)** and **State Treasurer**,
which are statewide offices, and **Township Clerk (26) / Township Treasurer (25)**, which are a
different layer of government. ⚠ It also carries officials' **home addresses, personal e-mail and
phone numbers** — use it for name/office/district/year only, and do not commit the raw file.

### ✅ ALL TEN TERM STARTS SOURCED — nine from a record, one from the day's own press release

| Seat | Holder | Continuous since | Prec. | How they arrived | The record |
| --- | --- | --- | --- | --- | --- |
| Commissioner D1 | Pete Meitzner | **2019-01-14** | day | elected 2018 | canvass + `19-202(d)`; county bio says "January 2019" |
| Commissioner D2 | Jeff Blubaugh | **2025-01-13** | day | elected 2024 | 2024 official canvass; register 2024-08 → 2025-02 |
| Commissioner D3 | Stephanie Wise | **2025-01-13** | day | elected 2024 | 2024 official canvass; register 2024-08 → 2025-02 |
| Commissioner D4 | Ryan Baty | **2023-01-09** | day | elected 2022 | 2022 canvass + CSV totals; register 2022-11 → 2023-03 |
| Commissioner D5 | Jim Howell | **2015-01-12** | day | elected **2014** | 2014 canvass; page named Skelton 2014-07-01 |
| County Clerk | Kelly Arnold | **2009-01-12** | day | elected **2008** | 🟢 BOCC minutes — see below |
| County Treasurer | Brandi Baily | 🔴 **2021-10-12** | day | elected 2020 | `19-501` + measured, see below |
| Register of Deeds | Tonya Buckingham | 🔴 **2016-01-29** | day | 🔴 **appointed** | county press release of that day |
| Sheriff | Jeff Easter | **2013-01-14** | day | elected 2012 | 2012 canvass; Hinshaw on page 2012-11-27, Easter 2013-01-27 |
| District Attorney | Marc Bennett | **2013-01-14** | day | elected 2012 | 2012 canvass; Foulston on page 2013-01-04, Bennett 2013-04-03 |

**10 of 10 at day precision. 0 year, 0 unknown.** Party is recorded by the county on every row and
is **discarded** — this repo is antipartisan by design.

🟢 Every date's weekday was checked against the rule that produced it: the seven January dates are
all Mondays, `2021-10-12` is a Tuesday, `2016-01-29` is a Friday (the press release says "today" and
KMUW said "Friday"), and `2016-01-10` is a Sunday (the release says "Sunday morning"). Four of those
are controls that could have failed.

### 🔴🔴 "LAST ELECTED" IS NOT "CONTINUOUS SINCE", AND THE COUNTY'S OWN REGISTER ONLY HAS THE FORMER

`/ElectedOffice/Officials/` carries an `ElectionYear` column. For Meitzner it reads **2022**; he has
held D1 since **January 2019**. For Howell it reads **2022**; he has held D5 since **January 2015**.
For Arnold it reads **2024**; he has been clerk since **January 2009**. ▶ The column is *the election
that seated the current term*, and reading it as a start date would be wrong for 3 of 10 by between
3 and 15 years. This is the roster-label rule again, from the opposite direction.

The walk-back used the county's **own** canvasses: `/elections/election-results/<year>-general/`
serves full result tables for **2000, 2004, 2008, 2012, 2014, 2016, 2018** (the `-general-election`
suffix used for 2020/2024 404s for those years — two URL patterns, and only trying both found them).

### 🔴🔴 THE COUNTY TREASURER TAKES OFFICE IN **OCTOBER OF THE YEAR AFTER** THE ELECTION

`KSA 19-501`: elected at the general election "every four (4) years … for a term of four (4) years,
**commencing on the second Tuesday in October following the election**". `25-313(a)` sets the second
Monday of January for everyone else *"except as otherwise provided by law"* — and this is that
exception. Brandi Baily won in **November 2020**; her term began **2021-10-12**, eleven months later.

🟢 **Measured, not assumed.** The county's own `/treasurer/` page in the Wayback Machine:

| Capture | Page says |
| --- | --- |
| 2021-01-29 | `alt="County Treasurer Linda Kizzire"` … Linda Kizzire |
| 2021-08-01 | Linda Kizzire |
| **2021-10-09** | **Linda Kizzire** — three days before the statutory date |
| **2021-12-03** | **Brandi Baily** — "Brandi Baily, Sedgwick County Treasurer" |

▶ A January assumption would have put Baily's start **21 months early** and asserted that Kizzire
left office when she had not. The 2021-01-29 capture is the control that kills it.

⚠ **An AI-generated summary site (`citizenportal.ai`) reports a January 2025 ceremony at which the
treasurer was "sworn in for another term".** That article calls Blubaugh "**Jeff Lubas**" and Baily
"**Brandy Bailey**" — it cannot spell either name and is not a source. A ceremonial oath in January
would not move a statutory October term anyway, and the 2021 measurement stands on its own.

### 🔴🔴 THE REGISTER OF DEEDS WAS **APPOINTED**, A YEAR BEFORE THE ELECTION THE REGISTER CREDITS

The register says Buckingham, ElectionYear 2016. The county's `/deeds/` page says otherwise:

| Capture | Page says |
| --- | --- |
| 2015-12-06 | "Bill Meek Register of Deeds" |
| **2016-02-04** | "Tonya Buckingham Register of Deeds" |

**Bill Meek died in office on Sunday 2016-01-10**, aged 71 (BOCC press release, relayed by KSN).
`KSA 19-1203` fills the vacancy "in the manner provided by law for filling vacancies in the office of
member of the house of representatives" → `25-3903` → **party convention, then appointment by the
Governor**. The chain, from the county's own release of **2016-01-29**:

- **2016-01-10** Meek dies (Sunday — the release says "Sunday morning, January 10th" ✓)
- week of Jan 18–22 the **Sedgwick County Republican precinct committee** elects Buckingham
- **2016-01-22** the election is **approved by Governor Brownback**
- **2016-01-29** *"The new Sedgwick County Register of Deeds will take the oath of office at 4 p.m.
  today at 525 N. Main, Suite 227."* (Friday ✓)

`Release - New Sedgwick County Register of Deeds 012916.pdf`, Sedgwick County Communications.
▶ **Three different dates, and only one is the term start.** This is the Tuttle trap from KS-3: the
most quotable date (the Governor's approval, or the precinct vote) is not the day she took office.
⚠ The release is same-day but still forward-looking by hours. It is corroborated by KMUW
(2016-01-26, *"will be sworn in on Friday afternoon"*) and by the page reading Buckingham on
2016-02-04. Recorded at day precision on that basis.

⚠ Her own county bio says only *"Before her election to office, Tonya Buckingham was the Chief Deputy
… for over 10 years"* — it frames her arrival as an election and names no date. A per-person label
again describing how someone arrived, incompletely.

### 🟢 THE COUNTY CLERK'S START CAME FROM THE MINUTES THE CLERK SIGNS

Arnold's window from web captures was wide — Brace on 2008-06-13, Arnold on 2009-02-01 — and did not
exclude an early appointment. **BOCC minutes closed it, because the County Clerk signs them:**

- `reg-1-7.pdf` (**2009-01-07**): *"Mr. Don Brace, County Clerk"* present; the board marks *"the
  retirement of Don Brace after serving eight years as the County Clerk"*.
- `reg-1-14.pdf` (**2009-01-14**): signed **"Kelly B. Arnold, County Clerk"**.

Second Monday of January 2009 = **2009-01-12**, exactly between the two. Brace **served his full term
and retired at its end** — so Arnold arrived by election, not appointment.
▶ **Reusable instrument: the BOCC minutes name every commissioner present and are signed by the
clerk.** `/clerk/meeting-minutes/<year>-meeting-minutes/` covers **1996 → Aug 2010** as PDFs;
everything after that is in **Legistar** (`sedgwickcounty.legistar.com`).

⚠ **Legistar's `events` endpoint is broken for this client** — every call returns HTTP 400
*"'Agenda Draft Status' … is not setup in settings"*. `/v1/sedgwickcounty/bodies` (BOCC is
`BodyId 138`) and `/v1/sedgwickcounty/matters` both work. So matters are searchable and meetings are
not; **no oath appears in matters** (`substringof('OATH',MatterTitle)` returns 0).

### ✅ No early appointment for any of the other eight

Each handover was tested by reading the **predecessor** off the county's own page, not by assuming
the loser left on time:

| Handover | Predecessor last seen | Successor first seen | Statutory date in window |
| --- | --- | --- | --- |
| Sheriff Hinshaw → Easter | 2012-11-27 | 2013-01-27 | 2013-01-14 ✓ |
| DA Foulston → Bennett | 2013-01-04 | 2013-04-03 | 2013-01-14 ✓ |
| Clerk Brace → Arnold | 2009-01-07 (minutes) | 2009-01-14 (minutes) | 2009-01-12 ✓ |
| D5 Skelton → Howell | 2014-07-01 | 2015-03-16 | 2015-01-12 ✓ |
| D4 Cruse → Baty | 2022-11-30 | 2023-03-27 | 2023-01-09 ✓ |
| D2 Lopez → Blubaugh | 2024-08-03 | 2025-02-14 | 2025-01-13 ✓ |
| D3 Dennis → Wise | 2024-08-03 | 2025-02-14 | 2025-01-13 ✓ |

🟢 **D5 has an independent negative control.** Howell's window (Jul 2014 → Mar 2015) is wide, but
`KSA 19-205` makes a person holding **any state office ineligible** for county commissioner, and
kslegislature.gov has him as **Representative, District 81** for the 2013–14 biennium, which ran to
the second Monday of January 2015. He **could not lawfully** have been seated earlier.

Ten archive captures of the register between **2019-09** and **2026-04** show no other break in any
of the ten seats.

### 🟢 The 2022 canvass PDF's column alignment was PROVED, not read off

`after-canvass-official-no-wi.pdf` is an Electionware summary whose layout prints the vote totals
**above** the candidate names, so a reader must decide which number belongs to whom — and getting it
backwards elects the loser. The county's own `official-2022-general-election_export.csv` carries a
**`COUNTY TOTALS`** row, and it matches the PDF **name-for-name and vote-for-vote**:
Meitzner 18,772 / Grant 16,761 · Baty 14,025 / Cruse 12,525 · Howell 14,540 / McIntosh 10,983.
⚠ **First attempt summed every CSV row and got ~2× every figure** — because `COUNTY TOTALS` is a row
*inside* the file. A naive sum double-counts the whole election.

### The staggering, measured rather than assumed

**D1, D4, D5 are midterm seats** (2014, 2018, 2022, next 2026); **D2, D3 are presidential-year
seats** (2016, 2020, 2024). Three and two — which is how `19-202(c)`'s *"no more than a simple
majority … at any general election"* is satisfied. The four countywide offices and the DA all run in
presidential years (2012, 2016, 2020, 2024).

### ▶ Structure decision, made and not deferred

Modelled on **Los Angeles County**, which production already holds as government `Los Angeles County,
California, US` (`type=County`, `geo_id=06037`) with chambers *County Board of Supervisors* (5),
*Countywide Elected Officials* (3) and *Superior Court* (473).

- government **`Sedgwick County, Kansas, US`**, `type=County`, `state=KS`, `geo_id=20173` — **there is
  none today**; production has the district row for `20173` and 0 governments.
- chamber **Board of County Commissioners** → 5 district offices
- chamber **Countywide Elected Officials** → Clerk, Treasurer, Register of Deeds, Sheriff
- chamber **Eighteenth Judicial District** → the DA now. 🔴 `22a-101(a)` says the DA is **not** a
  county officer, so it does not belong in *Countywide Elected Officials*; a separate chamber also
  gives the judges a home if stage 4b is taken.

### ▶ SCOPE FORK, NOT YET DECIDED: 31 elected judicial seats

The 18th Judicial District **elects** its judges — they are on the county's elected-officials
register, so the district never adopted the nonpartisan/retention method of `20-2901`.

🔴 **`KSA 4-219` says "There shall be 24 district judges in such district." The register lists 30,
in divisions 1–30, contiguous and all filled**, plus **1 District Magistrate Judge** (position 1).
The statute was last amended in **1987**. ▶ **The statute is authoritative for WHICH offices exist
and stale for HOW MANY** — the same "authoritative for one field, stale for another" that the Knight
waves keep paying for. Do not seat 24.

Cohorts from the register: 9 divisions last elected 2022, 21 in 2024.
⚠ Each of the 31 needs its own continuous-since date, and Kansas fills judicial vacancies by
gubernatorial appointment mid-term, so that is a **bigger research job than all ten county officers
together**. Recommended as a separate stage 4b, after 4a is applied.

### What KS-4 owes next

1. ▶ **The five commissioner-district polygons**, `outSR=4326`, and a **vintage proof**. 🔴 The three
   published copies are one digitization, so the city layer is **not** the control — a KS-3-style
   population-deviation test against the county's adopted redistricting plan is the route.
2. ▶ A duplicate-name check with the guard's own predicate (`is_active` + the
   `lower(btrim(first_name))`/`lower(btrim(last_name))` **pair**). ⚠ **`Jeff Easter`, `Kelly Arnold`,
   `Marc Bennett`, `Ryan Baty` and `Jim Howell` are ordinary names and must be checked, not assumed
   new.** ⚠ `Jeff Blubaugh` and `Pete Meitzner` are **former Wichita council members** and Wichita is
   already seated by `CC_0159`/`CC_0160` — they may already exist as people.
3. ▶ Two fresh `CC_` slots from the allocator — structure and occupancy. **Not yet reserved.**
4. ▶ `offices.representation_note` is not required here: all ten are `residency` basis with `full`
   voting powers.

### Sources captured to disk, `backend/data/seed-ks-2026/`

| File | What it is |
| --- | --- |
| `statutes/ksa-*.html` | the statutes above, fetched individually — ⚠ **the revisor 403s a directory listing but serves section pages**, and the chapter index lives at `/statutes/ksa_ch<N>.html` |
| `ksa-ch{4,19,22a,25}-index.html` | chapter indexes, used to enumerate articles rather than guess section numbers |
| `_sgco-{2000,2004,2008,2012,2014,2016,2018}-general.html` | the county's own result tables |
| `sedgwick-{2020,2022,2024}-general-official.pdf` + `.txt` | official canvasses |
| `_sgco-2022-official.csv` | the 2022 precinct export, used **only** as the alignment control |
| `_sgco-elected-2*.csv` | 10 Wayback captures of the election office's register, 2019-09 → 2026-04 |
| `sedgwick-release-new-rod-20160129.pdf` | 🟢 the county press release naming the oath hour |
| `bocc-minutes-2009-01-{07,14}.pdf` + `.txt` | Brace present, then Arnold's signature |
| `_bocc-{sgco-dedicated,sgco-election6,wichita1}.json` | the three BOCC layers, for the identity test |
| `_tr-2021*.html`, `_rod-2015*.html`, `_rod-2016*.html`, `_clerk-2009.html` | the transition captures |

## ✅✅ KS-4 APPLIED 2026-09-27 — SEDGWICK COUNTY IS SEATED

`X0071` (5 commission boundaries) + **`CC_0161`** (structure) + **`CC_0162`** (occupancy):
**10 offices — 5 commissioners + Clerk, Treasurer, Register of Deeds, Sheriff, District Attorney —
10 seated, 0 vacant, 10 people created, 0 reused.**

### Measured from outside against a same-session baseline

| | baseline | after | delta |
| --- | --- | --- | --- |
| `politicians` | 89,351 | **89,361** | **+10 exact** |
| `office_terms` | 9,832 | **9,842** | **+10 exact** |
| `offices` | 9,896 | **9,906** | **+10 exact** |
| `governments` | 609 | **610** | **+1** |
| `chambers` | 1,330 | **1,333** | **+3** |
| `districts` | 10,450 | **10,455** | **+5** |
| `X0071` boundaries | 0 | **5** | — |
| Sedgwick **seated** (`count(och.politician_id)`) | 0 | **10** | — |
| `offices_missing_terms` | 422 / 238 | **422 / 238** | **unmoved** |
| Wichita control | 7 | 7 | **unmoved** |
| Kansas legislature control | 165 | 165 | **unmoved** |
| Kentucky control (sldu+sldl) | 138 | 138 | **unmoved** |

🟢 **`offices_missing_terms` never moved at all**, unlike KS-3's 422 → 429 → 422. CC_0161 and
CC_0162 were applied back to back with no measurement between them, so the view was never observed
holding the ten term-less offices. Both readings are correct; this one simply has no transient.

⚠ **THE KANSAS LEGISLATURE CONTROL WAS BROKEN ON ITS FIRST READING AND RETURNED 0.** The government
is named **`State of Kansas`** with chambers `Kansas House of Representatives` and `Kansas Senate` —
not anything matching `%Kansas%Legislature%`, which is what the first query asked for. A control
that reads 0 because its predicate matches nothing is indistinguishable from a control that reads 0
because the data is gone. It was fixed and read **165** before and after.

### ✅ Idempotent, proved by re-running all three

`load-sedgwick-bocc-boundaries.mjs`, `CC_0161` and `CC_0162` were each run a second time. Every
count above is unchanged; both post-verify blocks raised their `OK` notice again.

### The ten, as production now holds them

| Chamber | Office | Holder | Since | Prec. | How |
| --- | --- | --- | --- | --- | --- |
| Board of County Commissioners | District 1 | Pete Meitzner | 2019-01-14 | day | elected 2018 |
| Board of County Commissioners | District 2 | Jeff Blubaugh | 2025-01-13 | day | elected 2024 |
| Board of County Commissioners | District 3 | Stephanie Wise | 2025-01-13 | day | elected 2024 |
| Board of County Commissioners | District 4 | Ryan Baty | 2023-01-09 | day | elected 2022 |
| Board of County Commissioners | District 5 | Jim Howell | 2015-01-12 | day | elected 2014 |
| Countywide Elected Officials | County Clerk | Kelly Arnold | 2009-01-12 | day | elected 2008 |
| Countywide Elected Officials | County Treasurer | Brandi Baily | **2021-10-12** | day | elected 2020 |
| Countywide Elected Officials | Register of Deeds | Tonya Buckingham | **2016-01-29** | day | **appointed** |
| Countywide Elected Officials | Sheriff | Jeff Easter | 2013-01-14 | day | elected 2012 |
| Eighteenth Judicial District | District Attorney, 18th Judicial District | Marc Bennett | 2013-01-14 | day | elected 2012 |

**10 of 10 at day precision. 0 year, 0 unknown, 0 computed from a calendar alone.** Party is NULL on
all ten — the county records every one of them as a Republican, and this repo is antipartisan by
design.

### ✅ END TO END through the production API

`POST https://api.empowered.vote/api/essentials/coordinate-lookup`, the anonymous route a voter's
browser calls. ⚠ It takes `lat`/`lng`, not `latitude`/`longitude`.

| point | Sedgwick offices returned |
| --- | --- |
| District 1 interior point | **Commissioner D1 Pete Meitzner** + Clerk, Treasurer, Register of Deeds, Sheriff, DA |
| District 2 interior point | **Commissioner D2 Jeff Blubaugh** + the same five |
| District 3 interior point | **Commissioner D3 Stephanie Wise** + the same five |
| District 4 interior point | **Commissioner D4 Ryan Baty** + the same five |
| District 5 interior point (Derby) | **Commissioner D5 Jim Howell** + the same five |
| NEGATIVE: Nashville | 0 |
| NEGATIVE: **Butler County**, immediately east | **0** |

🟢 **5 of 5 districts return their OWN commissioner and nobody else's**, and the five countywide
seats are constant across all five points — which is the shape a county layer should have and a
copied polygon would not.
🟢 **The Butler County negative is the one that matters.** Nashville proves only that Tennessee is
far away. A point in the adjoining county, 20 miles from the district-3 probe, returning **no**
Sedgwick official proves the county boundary is being respected.

### 🟢 A RESULT WAS DOUBTED AND THE SOURCE SETTLED IT — AGAIN

The district-1 probe also returned **"Representative Steve Brunk"**, and Brunk left the Kansas House
in 2017, so it looked like a stale row from a neighbouring slice. `office_terms` gave `term_start
2025-06-24`, sourced by `CC_0157` to the Legislature's own CSV. kslegislature.gov's member page for
the 2025-26 biennium reads **"House — District 85, Sedgwick County · Steve Brunk"**. ▶ He returned;
KS-2's data is right and the doubt was wrong. Chasing it validated a neighbouring slice against the
authority, which is worth more than the assumption would have been.

### ✅ ELEVEN GATES WATCHED FAILING, EACH FOR ITS OWN REASON

A tamper harness ran every assertion against production inside `BEGIN … ROLLBACK`, and **an
untampered run first, as a positive control, to prove the harness can execute the SQL at all** —
without it, "everything errored" could mean the harness was simply broken.

| Gate | Tamper | It said |
| --- | --- | --- |
| CC_0161 boundary guard | delete the `X0071` rows | *expected 5 X0071 commission boundaries, found 0* |
| CC_0161 slug assertion | edit one `name_formal` | *2 of 3 chamber slugs match* |
| CC_0161 appointed-office trap | rename Sheriff → County Appraiser | *an appointed or abolished office was created* |
| CC_0161 abolished-office trap | rename the DA → County Attorney | *an appointed or abolished office was created* |
| CC_0161 no-polygon guard | move D3 to a bogus mtfcc | *1 office(s) sit on a district with no matching boundary* |
| CC_0162 office-count guard | run without CC_0161 | *found 0. Apply CC_0161 first* |
| CC_0162 treasurer-October | set the treasurer to 2021-01-11 | *term starts 2021-01-11, not in October* |
| CC_0162 is_incumbent | clear one `is_incumbent` | *1 … would be hidden from address search* |
| CC_0162 two-seats | give Howell the Sheriff term as well | *1 person(s) hold more than one Sedgwick County seat* |
| CC_0162 day-precision | set one term to `year` | *1 term(s) are not day precision* |
| CC_0162 party | set a party on Baty | *1 official(s) carry a party* |

🔴🔴 **THE APPOINTED-OFFICE TRAP FAILED FOR THE WRONG REASON ON THE FIRST ATTEMPT AND THAT LOOKED
LIKE A PASS.** The tamper *added* a `County Appraiser` office, the migration aborted — but on the
**office-count** assertion (`expected 10 … found 11`), which runs earlier. The abort was real and
the trap was still completely unexercised. It only fires when the count is right, so the tamper was
changed to **rename** an existing office instead. ▶ **"The gate aborted" is not "the gate I am
testing aborted" — read the message, not the exit code.**

⚠ **Two tamper cases were rewritten for a related reason.** Re-running a whole migration after a
tamper lets its own idempotent write UNDO the tamper, so the post-verify passes and the control
looks broken. The harness runs the tamper and then **only the final post-verify `DO` block**.

### The migrations as written

Slots from the allocator, never counted: **`CC_0161`** and **`CC_0162`**, both reserved to
chris@empowered.vote before a line was written, each file named its slot immediately.

- **`CC_0161`** refuses to run unless the five `X0071` boundaries, the TIGER county boundary
  `20173`/`G4020` AND exactly one county district row to reuse all exist. It asserts the chamber
  split 5/4/1, that no office title matches appraiser, coroner, surveyor, auditor, election
  commissioner, county manager or **county attorney**, and that all three generated slugs are what
  a reader would cite.
- ⚠ **`chambers.slug` is a GENERATED column** (from `name_formal`) and the first draft tried to
  insert it — `cannot insert a non-DEFAULT value into column "slug"`. Caught by the dry-run.
- ⚠ **The county district row `20173` was REUSED, not duplicated.** KS-1's geography load had left
  it with no `government_id` and no offices; CC_0161 attaches it. A second row on the same geometry
  would have split the county's seats across two districts.
- **`CC_0162`** counts `och.politician_id`, never `count(*)` — `office_current_holder` LEFT JOINs
  from `offices`, so a vacancy is a NULL and `count(*)` would pass vacuously. It asserts the
  treasurer's term starts **in October**, so that a later "correction" to January fails loudly.
- Both dry-run against production inside `BEGIN … ROLLBACK`, and **the rollback was confirmed to
  have reverted** — 0 governments, 0 offices, `politicians` and `office_terms` back to baseline, and
  the county district's `government_id` back to NULL — before either was applied.

### Gates

✅ `check:reachability` — `BAD_GEOMETRY` 4, `DEAD_GEOGRAPHY` 17, `UNREACHABLE` 7, **all at baseline**.
✅ `check:occupancy` — *"every politicians INSERT names is_incumbent"*, 13 files scanned.
✅ `check:migrations` — 6 added vs origin/master, 2,168 slots across 380 refs, tree scan clean.

### ⚠ Two operational notes this stage paid for

- 🔴 **`psql` STOPPED CONNECTING MID-SESSION WHILE NODE'S `pg` CLIENT KEPT WORKING.** After seven
  rapid psql invocations for the tamper suite, every further `psql` hung until timeout — including
  `select 1` — while `pg` over the same `DATABASE_URL` answered instantly. Killing the stray psql
  processes did not help. ▶ **Do not read "the database is down" from one client.** The MCP
  connection and node both confirmed production was idle and healthy. The tamper suite and the
  apply were done through node instead.
- ⚠ **`steward extend --label` renews the lease but does NOT change the label.** The board still
  reads "KS-2 apply" for a lease now covering KS-4. Harmless here; misleading to the next reader.

### 🔴 `X0071` was chosen by reading, not by counting

`X0001`..`X0070` were in use, `X0070` being KS-3's Wichita council districts. ⚠ **Nothing allocates
custom MTFCC codes** — the steward allocates migration slots only — so a concurrent slice could take
the same code and no mechanism would notice. Recorded as a gap again, not a problem hit.

### What the slice still owes

1. ✅ Stage 1 geography · ✅ Stage 2 legislature · ✅ Stage 3 Wichita · ✅ **Stage 4a Sedgwick County**.
2. ▶ **Stage 4b, NOT YET DECIDED: 31 elected judicial seats** — 30 district judge divisions and 1
   district magistrate judge, all elected countywide in the 18th. The chamber for them already
   exists. 🔴 `KSA 4-219` says 24 judges and the register shows 30 — **the statute is stale on the
   count**. Each needs its own continuous-since date, and Kansas fills judicial vacancies by
   gubernatorial appointment mid-term, so this is a bigger research job than all ten county officers
   together.
3. ▶ **Stage 5 assets** — 10 Sedgwick portraits, 7 Wichita portraits, the legislature's 165, and a
   `wichita` banner. 🔴 **Wichita's banner collides with the Kansas state banner** — read
   `states/KS.jpg` in the 6:1 band first.

## ✅ KS-5a APPLIED 2026-09-27 — THE KANSAS LEGISLATURE IS 165 OF 165 RENDERABLE

164 portraits imported, 0 skipped, 0 failed. Kansas legislature goes **1 → 165 renderable**
(Patrick Schmidt already had one from a stance wave).

| | baseline | after |
| --- | --- | --- |
| `politician_images` | 9,178 | **9,342** (+164 exact) |
| `politicians.photo_custom_url` | 8,910 | **9,074** (+164 exact) |
| KS House renderable | 0 | **125 / 125** |
| KS Senate renderable | 1 | **40 / 40** |
| Ohio legislature control | 130 | 130 **unmoved** |

🔴 **THE BASELINE ZERO WAS PROVED BEFORE IT WAS BELIEVED.** 182 seated Kansas officials read
1 renderable, which is the shape of a broken detector. The identical predicate returned
**MN 133/133 and 67/67, NC 120/120 and 50/50, OH 98/98 and 32/32** — so the zero is real.

### ✅ Verified from outside, and the count is the tell

`verify-imported-headshots.py --expect 164`: **164 decoded, 0 broken**, negative control (a CDN key
for a random UUID) **failed as required — HTTP 400**, and `tested 164 == expected 164`. Sizes
`205x256 ×161` and `202x252 ×3`. That `--expect` assertion is MN-6's lesson: a verifier can print
"0 broken, control failed as required" while testing none of the rows just written.

### 🟢 THE PORTRAITS ARE NOT ENLARGED, AND THAT IS THE REPO'S RULE NOT A COMPROMISE

Source portraits are **202x302 – 205x300**, a 2.93–2.98× upscale to the 600x750 target.
`import-headshot-candidates.py` defaults `--max-upscale 1.0` — *"NEVER ENLARGE, AND NEVER SKIP FOR
BEING SMALL"* — so each ships at its own cropped size. Enlarging would bake in interpolation and
produce a file that looks full-resolution while carrying no more detail.

⚠ **A LARGER FILE IS NOT A LARGER IMAGE.** `?width=1200` on a portrait returns **14,585 bytes
against 7,991 — and the identical 205x300 pixels.** The host alternates between two JPEG encodings
of one image and ignores the parameter; `_large` and `.png` are hard 404s. SC-5's rule that the
resize can hide in the query string was tested here and **does not hold**, so the first reading
("a larger file exists") was wrong and measuring the pixels is what showed it.

### 🔴🔴 THE IDENTITY CHECK THAT SHIPPED FIRST COULD NOT FAIL

The first manifest set `name = alt` and then "checked" `alt != name`. **A check whose two sides come
from one value is not a check**, and it passed 165/165 while proving nothing.

Two more things were wrong with it, both found by looking rather than by the check:

- 🔴 **THE ROSTER PAGE'S `alt` IS A SURNAME** — `alt="Rep. Alcala"`. It cannot separate two members
  of one surname, and this chamber has **two Carpenters**. The MEMBER's own page carries the full
  name (`alt="Steve Brunk"`); they are different documents and only one is usable.
- 🔴 **THE ROSTER PAGE INTERLEAVES A CARD GRID AND A TABLE**, so a member's link and a *different*
  member's `<img>` sit adjacent in the markup. Splitting on the link and taking the next image is
  the off-by-one this programme keeps paying for. It came out right for all 165 — verified, 0 of 165
  mismatched — but the design was unsound.

▶ **So the binding moved to each member's own page, and the join key is the DISTRICT.**
`bind-ks-portraits.py` accepts a portrait only when the hero image on that member's page points at
that member's own slug, then joins on district — an integer, unique within a chamber, identical on
both sides. **A name join would have been the weakest link available**: KS-2 recorded three Mike
Thompsons, two seated in this legislature at once, one published as both "Mike" and "Michael".

**Three independent documents then have to agree on every row**: the member page's full-name `alt`,
the Legislature's first-party roster CSV, and production's `politicians.full_name` seated by
`CC_0157` months earlier. **165/165 agreed; 0 mismatches.**

### ⚠ One row matched on a preferred name, and it is recorded rather than waved through

District 26's CSV reads `Firstname 'Charles'`, `Preffname 'Chip'`, `Fullname 'Chip VanHouden'`, and
the page alt says "Chip VanHouden" — so a strict given-name check rejected a real person. The fix
reads the column **the Legislature itself publishes for this**, and stores
`given_name_matched_on` per row so the widening is visible: **164 matched on `Firstname`, exactly
1 on `Preffname`.** Production stores the same split, checked directly.
▶ Widening a rule to make a row pass is only legitimate when the source has a field that says so.

### 🔴 The `&quot;` trap is live in this chamber

`Lewis &quot;Bill&quot; Bloom` arrives entity-encoded. Compared raw it fails against every real
name; written through to a voter-facing field it is mojibake. KS-2 recorded eight such names.
The binder unescapes before comparing and asserts no entity survives into any alt.

### ⚠ The placeholder is directly fetchable

Every member page carries `onerror="this.src='/static/li_pics/fallback.8b887e28e491.jpg'"`. A
missing portrait 404s honestly at the member path — but the placeholder is a real URL, so a
pipeline that followed the fallback would import a **silhouette under a real name**. Every download
is hashed against the placeholder's own bytes (`sha1 402c6d284aa1`). **0 placeholders found.**

### 🔴 The amber ring on the contact sheet carried no signal, and that was stated

`render-headshot-contact-sheet.py` flags `positional OR upscale > 1.0`. All 164 are under 600x750,
so **164 of 164 were flagged** — a size flag, not a "check this face" flag. **None was positional.**
A flag that fires on everything discriminates nothing, and saying so is part of asking for approval
honestly. Sheet: `https://claude.ai/artifact/JhtixFEw9GGfi2zXKuNPc4`.

### ⚠ Licence `press_use`, and the nearby restriction that does NOT apply

**The Kansas Legislature publishes no photo policy and no copyright notice** — checked at `/li/`,
on member pages, and in the footer. Its only policy link is the state portal's.

🔴 **`portal.kansas.gov` DOES carry a restriction, and it is scoped to a different site.** Its Terms
of Use say downloading grants "only a limited, nonexclusive license for use solely by you for your
own personal use, **and not for republication, distribution … or preparation of derivative works**"
— and define "the Site" as **"the Kansas.gov website"**, run by Tyler Kansas / INK. It is not
asserted over kslegislature.gov.
▶ **Absence of a policy is not a licence**, but this is the Georgia/Florida footing from MN-5, not
the Minnesota House's published refusal. Recorded in full so the next reader need not re-derive it.

### Tooling added

| Script | What it does |
| --- | --- |
| `build-ks-portrait-manifest.mjs` | pages the roster at the site's own `per_page=20`, stops at a KNOWN TOTAL, and **aborts if a page adds nothing** — KS-2 proved this paginator clamps rather than ending |
| `measure-ks-portraits.py` | decodes every file with PIL and writes real sizes, upscale and a monochrome test. A hand-rolled JPEG SOF walker returned null on some files, and **a null size reported as "no upscale" is worse than no number** |
| `bind-ks-portraits.py` | binds photo → district → name across two documents; `--self-test` fires all eight assertions |
| `ks-portrait-candidates.mjs` | adds production as the third document and refuses on any name disagreement |
