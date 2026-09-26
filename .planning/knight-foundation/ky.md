# KY — slice 13 (Lexington · Fayette County)

Program tracker: [`PROGRAM.md`](./PROGRAM.md) · spec:
[`2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md)

**Opened 2026-09-26.** Lease `state:ky` held by chris@empowered.vote on DESKTOP-G6KDNN2.
Worktree `C:\ev-accounts-ky`, branch `knight/ky-slice13`.

| Stage | State |
| --- | --- |
| 1 geography | ✅ **APPLIED 2026-09-26 — 138 boundaries, 138 districts, 0 errors.** Only `sldu` + `sldl` were owed; `place` already existed |
| 2 legislature | ✅ **APPLIED 2026-09-26 — 138 offices, 138 seated, 0 vacant** (`CC_0150`/`CC_0151`). Lexington scores **2 of 4** |
| 3 city waves | ✅ **APPLIED 2026-09-26 — 16 offices, 16 seated, 0 vacant, EVERY TERM DATED** (`X0068`, `CC_0152`/`CC_0153`). Lexington scores **3 of 5** |
| 4 county waves | ✅ **APPLIED 2026-09-26 — 18 offices, 18 seated, 0 vacant** (`X0069`, `CC_0154`/`CC_0155`). 🔴 The commission did **NOT** drop: Fayette keeps a Fiscal Court. Lexington scores **4 of 5** |
| 5 assets | — portraits for everyone seated in the slice, plus one `lexington` banner |

---

## 🔴🔴 THE ONE THING THAT MAKES THIS SLICE DIFFERENT: NOTHING IN THE FILE DATES THE MAP

North Dakota could be dated by its own code set — 49 House polygons is HB 1504, 48 is the remedial
plan. Michigan could refuse an older vintage because an older plan exists. **Kentucky offers neither.**

Measured 2026-09-26 by parsing the `.dbf` inside each TIGER zip directly:

| vintage | `sldu` | `sldl` | `LSY` | `ZZZ` | `000` | codes |
| --- | --- | --- | --- | --- | --- | --- |
| TIGER 2022 | 38 | 100 | 2022 | 0 | 0 | contiguous `001..038` / `001..100` |
| TIGER 2023 | 38 | 100 | 2022 | 0 | 0 | contiguous |
| TIGER 2024 | 38 | 100 | **2024** | 0 | 0 | contiguous |
| TIGER 2025 | 38 | 100 | **2024** | 0 | 0 | contiguous |

**A count check, a code-set check and a contiguity check all pass every vintage.** Both chambers
are single-member, so polygon count *is* seat count — unlike ND and SD. There are no subdistricts
and no letter codes anywhere in the Kentucky file.

▶ **So the vintage evidence in this slice is GEOMETRIC, and nothing else.** That is the whole
reason `scripts/verify-ky-tiger-vintage.mjs` exists and why the loader's pre-flight carries anchors
rather than leaning on its count.

### ⚠ The one field that looks like a discriminator is misleading

`LSY` (legislative session year) moves 2022 → 2024 between TIGER 2023 and TIGER 2024. That reads
like a new plan. It is a Census bookkeeping refresh:

- `ALAND` changes by at most **0.0049%** (Senate) and **0.0306%** (House), median ~0.0000% — noise
  from routine re-digitization of the underlying county and water lines.
- Every TIGER 2024 internal point falls inside the **same** TIGER 2022 district: **38/38 and
  100/100**, 0 moved, 0 not found.

🔴 **THAT UNIFORM ANSWER WAS CONTROLLED BEFORE IT WAS BELIEVED.** A uniform answer is a broken
detector until a positive control passes. The identical comparison run over **North Dakota** — a
state known to have been redistricted between those vintages — reports Senate `015->009` and House
`015->09B`, `009->09A`, reproducing exactly the two districts the *Turtle Mountain* remedial order
moved. The method can see a real plan change. It sees none in Kentucky.

## 🟢 THE AUTHORITY, AND WHY IT IS NOT THE CENSUS

The **Kentucky Legislative Research Commission** — the legislature's own agency, which draws these
districts — publishes them itself:

```
https://kygisserver.ky.gov/arcgis/rest/services/WGS84WM_Services/
  Ky_Legislative_Districts_WGS84WM/MapServer      layer 0 = House, layer 1 = Senate
```

The service's own `copyrightText` is `Legislative Research Commission`. It answers a plain HTTPS
request — no WAF, no Playwright, unlike Ohio's Secretary of State. `outSR=4326` is load-bearing.

Result, measured 2026-09-26: **TIGER 2024 agrees 100/100 (House) and 38/38 (Senate).**

**The control failed as required**: House points against the **Senate** layer agree only **3 of
100**, and those three are numeric coincidence, not geography.

### ▶ TIGER 2022 agreeing is a PASS here, not a failure — the opposite of North Dakota

Kentucky's legislative maps are:

- **HB 2 (2022)** — state House, enacted over the governor's veto **2022-01-20**.
- **SB 2 (2022)** — state Senate, became law without signature **2022-01-21**.
- (SB 3 drew the *congressional* map. It is not a legislative plan and is not loaded here.)

*Graham v. Adams* (Ky., rendered **2023-12-14**) held that partisan-gerrymandering claims **are**
justiciable under the Kentucky Constitution, but **upheld** the plans and ordered **no remedial
map**. SB 2 was never challenged. One plan has governed since 2022 and governs the 2026 election.

So the verifier asserts that TIGER 2022 **must also agree**, and fails if it does not. That
expectation is only meaningful because it is stated in advance: if it ever disagrees, Kentucky was
redistricted after all and this file's premise is wrong.

## 🔴🔴 THE `geo_id` COLLISION LANDS ON THIS SLICE'S OWN COUNTY

Loaded ids run `21001..21038` (`sldu`) and `21001..21100` (`sldl`). Kentucky's **120 counties** are
`21001..21239` odd. So **19 counties collide with the Senate range and 50 with the House range** —
and the worst one is ours. Measured in production after the load:

| `geo_id` | rows | what |
| --- | --- | --- |
| `21001` | **3** | Adair County · State Senate District 1 · State House District 1 |
| `21067` | **2** | **Fayette County** · **State House District 67** |

Grand Forks escaped the identical collision only by luck of odd numbering. Lexington does not.
**Every join must pair `geo_id` with `mtfcc`/`district_type`** — see `src/lib/geoIdGuard.ts`.

### 🔴 A Kentucky district code is not an integer on the authority side

The LRC serves `District = 'H001'` / `'S001'` beside `DistrictID = '001'`. **`parseInt('H001')` is
`NaN`, not 1** — the same family as ND's `04A` and MN's `08A`, where a numeric cast silently
collapses or drops a district. Match on `DistrictID`; never cast a code to a number.

### ⚠ And a name search finds the wrong Fayette

`%fayette%` also matches **`LaFayette city` (`2143444`)**. Match on `geo_id`, never on name — the
same shape as Saint Paul in MN-1.

## ✅ KY-1 APPLIED 2026-09-26

**138 boundaries and 138 districts — 38 Senate + 100 House — 0 errors.** No migration: a pure
geography load writes no offices, so this is the OH-1/MI-1 shape and no slot was taken.

### Measured from outside, against a same-session baseline

Taken through the same connection the loader writes with, as `ev_api`:

| Measure | Before | After | Delta |
| --- | --- | --- | --- |
| `districts` | 10,124 | 10,262 | **+138** exact |
| `geofence_boundaries` | 72,307 | 72,445 | **+138** exact |
| KY `G5210` | 0 | 38 | |
| KY `G5220` | 0 | 100 | |
| `offices_missing_terms` | 422 / 238 unflagged | 422 / 238 | **unmoved** |

⚠ **`offices_missing_terms` read 422, not the 423 recorded at ND-4.** It drifts. Measure it in the
session that writes; never read it off a tracker.

**Idempotent, proved by re-running**: 0 inserted / 138 already existed, and both totals unmoved at
10,262 / 72,445.

### Gates, each watched failing first

| Gate | Tamper | Fired |
| --- | --- | --- |
| Verifier count | Senate 38 → 37 | 🔴 `expected 37 TIGER records, got 38` |
| Verifier control | House compared to the **House** layer | 🔴 `THE CONTROL DID NOT FAIL` |
| Loader count | `KY_PREFLIGHT_CONTROL=count` | 🔴 `[KY MTFCC assertion] expected 37, got 38` |
| Loader vintage | `KY_PREFLIGHT_CONTROL=anchor` | 🔴 `[KY vintage assertion] … resolved to 77, expected 999` |

Each failed for **its own** reason, not by aborting early. A control that aborts for the wrong
reason proves nothing.

⚠ **Kentucky has no `--vintage 2022` control, and that absence is the finding, not an oversight.**
Michigan can refuse an older file because an older plan exists. Kentucky's 2022 file carries the
*same* plan, so loading it is correct — the vintage control had to be **constructed** from the
authority rather than borrowed from an earlier map.

### End-to-end in production, with controls

| Point | House | Senate |
| --- | --- | --- |
| Lexington-Fayette Government Center | **77** | **13** |
| Kentucky State Capitol, Frankfort | 57 | 20 |
| Louisville Metro Hall | 43 | 33 |
| Paducah City Hall | 1 | 2 |

- **Negative control**: Nashville, TN returns **0** Kentucky districts.
- **Per-district control**: all 138 resolve to exactly one — **38/38 and 100/100, 0 anomalies**.
- `check:reachability`: nothing regressed, all three buckets at baseline
  (`BAD_GEOMETRY` 4, `DEAD_GEOGRAPHY` 17, `UNREACHABLE` 7).

## Baseline as measured when the slice opened, 2026-09-26

### What already existed

| Layer | Rows | Note |
| --- | --- | --- |
| `G4020` counties | 120 | all of Kentucky |
| `G4110` places | 419 | incl. **Lexington-Fayette urban county `2146027`** |
| `G4210` CDPs | 136 | statistical, not loaded by this program |
| `G5200` congressional | 6 | |

One government row: **`State of Kentucky`**, carrying 5 statewide executives — Governor,
Lieutenant Governor, Attorney General, Secretary of State, Treasurer — **all 5 seated**. No
candidate-office decoy of the kind Ohio carried.

### What did not exist

- **Zero `G5210`/`G5220` rows.** KY-1 closed this.
- **Zero state legislative offices.** Stage 2 owes **138**.
- **No Lexington government row.** Stage 3 creates it.

## 🟢 The authority also carries a roster and a portrait route

The LRC layer serves, alongside the geometry:

`District` · `DistrictID` · `District_Title` · `Party` · `Legislator` · `Full_Name` · `Counties` ·
`LRC_URL` · `PIC_URL`

All 100 House and 38 Senate rows carry a `Full_Name`. That is a stage-2 roster and a stage-5
portrait route from one fetch.

🔴 **Treat it as ONE source needing a second, never as settled.** MN-2's rule stands: a roster list
is not a change-check, and `house.mn.gov` listed a member three months after he resigned. Every
member page must still be read individually, and a departure dated from the member's own page.

⚠ **`Party` is not written.** Party is antipartisan in this schema: it lives on
`races.primary_party`, never on a person or an office.

## Expected scope

| Stage | Owed | Basis |
| --- | --- | --- |
| 2 legislature | **138 offices** — 100 House + 38 Senate | Ky. Const. § 33; both chambers single-member |
| 3 Lexington | unmeasured | Urban County Council, from the charter |
| 4 Fayette County | unmeasured | consolidated — commission drops, separately elected officers stay |
| 5 assets | 138 + city + county portraits, plus a `lexington` banner | |

**Fayette County is split across 9 House and 7 Senate districts** (LRC `Counties` field): House
`039,045,073,075,076,077,079,088,093`; Senate `012,013,017,022,027,028,034`. A Lexington address
must therefore return exactly one of each, not nine and seven.

## Next steps, in order

1. **Stage 2.** Pull the LRC roster plus a second independent source, diff them, list every
   disagreement, and read all 138 member pages for a departure. Write `ROSTERS.md`.
2. Generate structure and occupancy migrations from that file. Take the slot from the allocator
   (`steward slot CC`) — **never count**.
3. Dry-run against production with `BEGIN; … ROLLBACK;` through `psql`, and confirm the rollback
   reverted.
4. Then stage 3 (Lexington), stage 4 (Fayette officers), stage 5 (assets).

## Debts this slice already owes

- Nothing yet. Stage 1 closed clean with no accepted debt.

---

## ✅ KY-2 APPLIED 2026-09-26 — the Kentucky General Assembly is seated

`CC_0150` (structure) + `CC_0151` (occupancy): **138 offices — 100 House + 38 Senate — 138 seated,
0 vacant, 138 people created, 0 reused.**

### Measured from outside, against a same-session baseline

| Measure | Before | After | Delta |
| --- | --- | --- | --- |
| `politicians` | 89,011 | 89,149 | **+138** exact |
| `offices` | 9,552 | 9,690 | **+138** exact |
| `office_terms` | 9,488 | 9,626 | **+138** exact |
| `chambers` | 1,322 | 1,324 | **+2** |
| `offices_missing_terms` | 422 / 238 unflagged | 422 / 238 | **unmoved** |

House **100/100** and Senate **38/38** seated, counting `och.politician_id` — never rows, because
`office_current_holder` LEFT JOINs from `offices` and a vacancy is a NULL `politician_id`.

**Idempotent, proved by re-running both**: every `essentials.*` write `INSERT 0 0`, counts identical
at 89,149 / 9,690 / 9,626 / 1,324.

### 🔴🔴 The GIS layer carries a stale roster, and KY-1 used that layer as its geometry authority

`Ky_Legislative_Districts_WGS84WM` serves `Legislator`/`Full_Name` beside the polygons. KY-1 proved
its **geometry** 138/138. Its **roster** is stale: Senate District 37 still reads `Yates, David`,
while the chamber's own list and the member's own profile both read **Gary Clemons**.

David Yates resigned **2025-10-08** to become Jefferson County Clerk; Clemons won the **2025-12-16**
special election and took office **2026-01-06**. That row is now live at day precision.

▶ **A SOURCE CAN BE AUTHORITATIVE FOR ONE FIELD AND STALE FOR ANOTHER.** Proving a layer's geometry
says nothing about the attributes riding along with it. Never inherit trust across fields.

### 🔴 In Kentucky a departed legislator has no page, so a list diff is the only change-check

The profile URL is keyed to the **seat** (`DistrictNumber` only), not the person, so a successor
replaces the predecessor and a departure marker can never appear. A sweep of all 138 pages will
always return 138 sitting members reading `- Present`.

The departure detector was controlled by tampering — it fires on all 138 — so it is not dead code,
but **no real page on this host can trigger it**. The cross-source diff caught SD-37; nothing else
would have.

🔴 **`legislature.ky.gov` SOFT-404s**: `DistrictNumber` 139, 200, 0 and `abc` all return HTTP 200 at
~61.7 KB against 68–69.5 KB for a real page. **Status is not a validity signal**; the sweep is safe
only because it asserts a parsed name and title.

🔴 **The Senate is offset by +100 in the profile URL** (Senate 1 = `DistrictNumber=101`, Senate 38 =
`138`), confirmed empirically at both edges. A naive `DistrictNumber=<district>` silently fetches a
**House** member for every Senate seat, so the sweep asserts the returned title against the chamber
it asked for.

### 🔴 One member has held one seat under three published names

House District 81, from the archived LRC rosters: `Frazier, Deanna` (2019–2021) →
`Frazier Gordon, Deanna` (2021–2025) → `Gordon, Deanna` (2025– ).

A name-keyed diff reads that as two departures and two arrivals. Only the seat-keyed timeline shows
one continuous tenure. **Matching Kentucky legislators by name across time is unsafe.**

### 🔴🔴 "First elected" is not a term start, and Kentucky proves it four separate ways

Ky. Const. § 30 makes a term begin on 1 January of the year succeeding the election, and an earlier
draft of this wave used that as a blanket day for 126 seats. **It was wrong.**

| Failure | Count | Example |
| --- | --- | --- |
| `Service` is chamber-scoped; gaps and chamber switches | 13 | `House 1994 - 22, House 2025 - Present` — off by 31 years |
| Changed district number in the 2022 remap | 3 | D90→D14, D88→D43, D82→D49 |
| Arrived mid-term by special election | 9 | Clemons, Griffee, Berg, … |
| Caught only by replaying 45 archived rosters | 8 | Heavrin D18 and Banta D63 both read 2019, both first appear in **December** 2019 |

⚠ **And that detector has blind spots**: 40 members predate snapshot coverage, and Griffee — a
confirmed March 2024 arrival — is **not** flagged, because no 2024 snapshot precedes him.

⚠ **The segment scan was a broken detector first.** It required a four-digit end year, so
`House 1994 - 22` never matched and all 138 members scored as one segment. A uniform answer was
reported before it was controlled.

▶ **So a DAY is claimed only where the arrival was individually sourced: 7 day · 131 year · 0
unknown · 0 invented.** Year precision under-claims rather than over-claims. Compare North Dakota at
87 of 94 unknown and Ohio at 130 of 130 unknown.

⚠ **The gap between a special election and the oath is NOT a rule** — measured at 6, 7, 7 and 20
days. ND-3's finding reproduced. Two January 2014 arrivals (Miles H7, Thomas S13) stay at `year`
because sources disagree across Jan 2 / Jan 4 / Jan 7 and 🔴 **Kentucky publishes no House or Senate
Journal online** to settle it.

### Namesakes — four, every one a different person

| Member | Seat | The existing row is |
| --- | --- | --- |
| Brandon Smith | Senate 30 | a Longview, **Texas** city council candidate |
| Daniel Elliott | House 54 | the **Indiana** State Treasurer (source `cicero`) |
| Matthew Lehman | House 67 | an **Indiana** discovery-cohort row, `is_active=false` |
| William Lawrence | House 70 | a **Michigan** U.S. House District 7 candidate |

The duplicate-name guard is lifted for those four rows only, never for the migration. ⚠ The
collision query itself fanned out on Daniel Elliott — a live instance of the politician-rooted
`office_current_holder` join hazard CLAUDE.md documents.

`external_id` block `-2763000..-2762601` was measured **empty** before use; the nearest occupied id
below it is `-2770001`.

### Gates, each watched failing for its own reason

| Gate | Tamper | Fired |
| --- | --- | --- |
| Structure count | expected 100 → 99 | `expected 100 House offices, got 188` |
| **`geo_id` collision** | drop `district_type` from the office join | **`69 legislative office(s) landed on a non-legislative district`** |
| Occupancy day count | 7 → 6 | `expected 7 day-precision terms` |
| Occupancy seated | 138 → 137 | `expected 138 seated` |
| Roster departure check | invert the `- Present` test | fires on all 138 |

🔴 **The collision tamper first tripped the COUNT gate at 188 offices, not the collision gate.** A
control that aborts for the wrong reason proves nothing, so the count gate was relaxed to let
execution reach the collision gate — which then reported **69**, exactly the 50 House-range plus 19
Senate-range county collisions measured before the wave.

### Dry run and verification

Both migrations were dry-run against production in one transaction ending in `ROLLBACK`, and **the
rollback was confirmed to have reverted** — all four counts back to 89,011 / 9,552 / 9,488 / 1,322,
with zero Kentucky chambers or people surviving.

- ✅ **End-to-end**: all four anchors return **2 of 4** answers. Lexington-Fayette Government Center
  returns **George Brown Jr.** (House 77) and **Reginald L. Thomas** (Senate 13). The Nashville
  negative control returns **0**.
- ✅ `check:reachability` — nothing regressed, all three buckets at baseline.
- ✅ `check:occupancy`, `check:migrations`, `check:reservations` — all green.

▶ **Next: stage 3, the Lexington-Fayette Urban County Council**, unmeasured. Fayette County is split
across **9 House and 7 Senate districts**, so a Lexington address must return exactly one of each.

---

## ✅ KY-3 APPLIED 2026-09-26 — Lexington-Fayette is seated, and every term carries a date

`X0068` (12 council-district boundaries) + `CC_0152` (structure) + `CC_0153` (occupancy):
**16 offices — Mayor + 3 at-large + 12 district — 16 seated, 0 vacant, 16 people created, 0 reused.**

### Measured from outside, against a same-session baseline

| Measure | Before | After | Delta |
| --- | --- | --- | --- |
| `politicians` | 89,149 | 89,165 | **+16** exact |
| `offices` | 9,690 | 9,706 | **+16** exact |
| `office_terms` | 9,626 | 9,642 | **+16** exact |
| `districts` | 10,262 | 10,275 | **+13** exact |
| `geofence_boundaries` | 72,445 | 72,457 | **+12** exact |
| `governments` | 607 | 608 | +1 |
| `chambers` | 1,324 | 1,326 | +2 |
| `offices_missing_terms` | 422 / 238 | 422 / 238 | **unmoved** |

Council **15/15** and Mayor **1/1** seated, counting `och.politician_id`. **Idempotent, proved by
re-running all three**: `inserted 0 boundary row(s)`, every `essentials.*` write `INSERT 0 0`,
counts identical.

### 🔴🔴 The city's own Councilmembers page produces a wrong inventory if read literally

Its prose describes the Council as *"The vice mayor / Two at-large councilmembers / 12 district
councilmembers."* Read as written, that creates a separately elected **Vice Mayor** office.

There is none. The city's Government page states it plainly — *"There are 12 district council
members and three at-large council members"* — and the roster lists Dan Wu as *"Council At-Large and
Vice Mayor"*. Voters elect **three at-large members**; the top vote-getter takes the title.

▶ By the inclusion ruling — an office is seated if the **voters** elect it — **Vice Mayor is a
title, not an office.** `CC_0152` carries a named gate that refuses any office whose title contains
"vice mayor", and it was watched failing.

### 🔴🔴 The oath date is not a rule, and Kentucky proved it again

Whitney Elliott Baxter assumed office **2021-01-04** (a Monday) and Lisa Higgins-Hord's appointment
runs through **2027-01-04** (a Monday). That invites *"the first Monday in January"*.

The city's own record says the 2025-26 district members took the oath on **Sunday, January 12,
2025**, at the Lexington Senior Center, administered by Fayette District Judge Denotra Gunther.

**Computing the first Monday would have written 2025-01-06 for five members — wrong by six days.**
This is ND-3's finding, reproduced in a second state.

⚠ **That ceremony re-swore all twelve district members, incumbents included**, so `2025-01-12` is the
start of the 2025-26 *term*, not of continuous occupancy. It is used only for the five the archived
timeline shows **arriving** then — absent 2024-12-22, present 2025-01-17. `office_terms` carries
continuous occupancy (North Carolina's rows reach back to 1999-01-01), so an incumbent's re-swearing
must never overwrite an earlier start.

### Term dates: 7 day · 9 year · 0 unknown · 0 invented · 2 appointed

| Seat | Member | Start | Precision | How |
| --- | --- | --- | --- | --- |
| D1, D4, D7, D8, D12 | Morton, Curtis, Hale, Beasley, Boone | `2025-01-12` | day | elected |
| D3 | Tom Eblen | `2026-02-03` | day | **appointed** |
| D6 | Lisa Higgins-Hord | `2025-08-22` | day | **appointed** |
| D2 / D10 / AL Wu / AL Brown | Lynch, Sevigny, Wu, Brown | `2023-01-01` | year | elected |
| D5 / D9 | Sheehan, Baxter | `2021-01-01` | year | elected |
| D11 / AL Ellinger / Mayor | Reynolds, Ellinger, Gorton | `2019-01-01` | year | elected |

🟢 **Both appointed arrivals are dated from the city's own publications** — the only thing that dates
an appointed arrival. Higgins-Hord was named and sworn the same day, 2025-08-22, after Denise Gray
resigned effective 2025-07-31; Eblen's member page states *"appointed by Mayor Linda Gorton on
Feb. 3, 2026"*, filling Hannah LeGris' unexpired term.

⚠ **Two gap cases, the KY-2 trap again**: **Chuck Ellinger II** served at-large 2003–2014 and
returned in 2019; **James Brown** moved from a district seat to at-large in 2022. Neither's first
year on the Council starts the seat he holds now.

### 🔴 Four council-district layers, all with 12 features

Lexington publishes `Council_District`, `Council_District_2012`, `Council_District_2002` and
`Council_District_1972` in one ArcGIS organisation. **All four carry exactly 12 features** — the
Duluth trap, where a count cannot separate the live map from a superseded one.

⚠ **The obvious test is too weak.** Locating each 2012 centroid inside the current layer agrees
**11 of 12** — 92%, which is the level North Dakota proved a struck-down map can pass.

🟢 **The area test discriminates**: all **12** districts differ from the 2012 map by **1.0%–44.9%**
while the **total is preserved to 0.03%** — the signature of a redistricting, which a stale copy
cannot produce. That test is built into the loader and re-runs on every load; pointing it at the
live layer as its own control aborts with `0 of 12 differ`.

Corroboration only: the three superseded layers carry an explicit year in their name, the live one's
`modified` is 2025-12-16 against 2024-09-13, and its `REP` attribute matches the roster 12/12.
⚠ **The `REP` match is not a vintage proof** — KY-2 found the state's GIS layer carrying a stale
roster beside correct geometry. Attributes and geometry are independent.

### 🟢 The place polygon is exactly coterminous with the county, and that was measured

TIGER place `2146027` and county `21067` are **both 285.567 sq mi**, with **zero** difference in
either direction and **100.000%** coverage — consolidation is real in the geometry, not inferred
from the word. The control discriminates: Duluth's place covers **1.169%** of St. Louis County.

The 12 council districts cover **99.968%** of the place, 0.016 sq mi falling outside it — two
digitizations of one boundary, which needs a tolerance rather than an equality test.

### 🔴 The roster parser control earned its keep twice

The first parser returned **zero seats from both archived snapshots**. Controlled against the live
page rather than believed, it exposed two separate faults: a regex referencing a capture group that
did not exist, and — once fixed — **14 of 15**, silently dropping **District 2, Shayla Lynch, J.D.**,
whose name contains a comma. Only keying on the `href` reached 15/15.

⚠ The archived roster is not in anchors at all but inside an **escaped JSON menu blob**, and one
snapshot returned **undecoded gzip**. Both score as zero to a naive parser.

⚠ The credential `J.D.` is not part of the name and is not written.

### Gates, each watched failing for its own reason

| Gate | Tamper | Fired |
| --- | --- | --- |
| Boundary vintage | point the comparison at the live layer | `0 of 12 districts differ` — aborts before any write |
| Structure: geometry present | `X0068` → `X9999` | `X0068 holds 0 boundaries, expected 12` |
| Structure: at-large count | relabel one at-large seat | `expected 3 at-large offices, got 2` |
| **Structure: Vice Mayor** | create a `Vice Mayor` title | **`a Vice Mayor OFFICE exists`** |
| Occupancy: seated | 16 → 15 | `expected 16 seated` |
| Occupancy: appointed | 2 → 1 | `expected 2 appointed arrivals` |

🔴 **The Vice Mayor tamper first tripped the at-large COUNT gate**, not the Vice Mayor gate — the
same ordering problem KY-2's collision gate had. The count gate was relaxed to let execution reach
it, and it then fired with its own message.

### Verification

Dry-run against production in one transaction ending in `ROLLBACK`, and **the rollback was confirmed
to have reverted** — all six counts back to baseline with zero Lexington rows surviving.

✅ **END-TO-END at Lexington-Fayette Government Center — seven answers**: state representative
**George Brown Jr.** (House 77), state senator **Reginald L. Thomas** (Senate 13), **three**
at-large council members, **Council District 3 Tom Eblen**, and **Mayor Linda Gorton**. The
program's usual four-answer probe returns seven here because Lexington seats three at-large members
and a mayor, and the county commissioner answer is absent **by design** — the government is
consolidated, so the Council *is* the county body.

✅ `check:reachability` nothing regressed, all three buckets at baseline.
✅ `check:occupancy`, `check:migrations`, `check:reservations` all green.

▶ **Next: stage 4, the Fayette County officers.** KRS 67A does not set an urban-county council's
structure, but it **does** require the government to retain the county offices named in the Kentucky
Constitution — so stage 4 is not empty despite consolidation. The commission drops; the separately
elected officers stay, confirmed from the charter in that wave and never inherited.

---

## ▶ KY-4 IN PROGRESS — research only, NOTHING WRITTEN TO PRODUCTION (2026-09-26)

**Stage 4 opened 2026-09-26.** No migration slot taken yet, no SQL written, no production row changed.
Lease `state:ky` live to 2026-09-27 21:04Z.

### 🔴🔴 THE SPEC'S PREMISE FOR A CONSOLIDATED CITY IS WRONG HERE: FAYETTE STILL HAS A FISCAL COURT

Spec §3.2 says stage 4 for a consolidated city-county "drops the **county commission** — because the city
council already is it — and keeps the county officers". Philadelphia, Columbus-Muscogee and Macon-Bibb all
behaved that way. **Lexington-Fayette does not.**

The charter's own Article 11 — [`backend/data/seed-ky-2026/charter-article-11.txt`](../../backend/data/seed-ky-2026/charter-article-11.txt),
read from Municode 2026-09-26 — **preserves both the County Judge and the Fiscal Court**:

> **11.02 Fiscal Court.** Nothing in this Charter shall be construed to alter or affect the election or term
> of members of the County Fiscal Court. Composition — The County Fiscal Court shall be composed of the
> Judge of the County Court and three (3) Commissioners to be elected from the Urban County at-large …

It is vestigial but real: it keeps the school ad valorem levy, the county road-aid advisory power under
KRS 179.415, and one seat on the County Budget Commission. **Read the charter, not the pattern — "consolidated"
is not a template.**

### 🔴🔴 A CANDIDATE FILING IS NOT EVIDENCE THAT AN OFFICE EXISTS

The Secretary of State's county filings database (`web.sos.ky.gov/CandidateFilings/countyfilings.aspx`,
county id **34**) returns, for Fayette in 2026, filings for **County Commissioner (3)** *and*
**Magistrate / Justice of the Peace (5)**. In Kentucky a county's fiscal court is composed of commissioners
**or** magistrates — never both — so the database plainly **does not validate that the office exists in the
county it is filed in**. It is a record of what someone handed the clerk.

⚠ Read alone it would have created a magistrate layer that does not exist, beside a commission that does.

### ⚠ THE OFFICIAL BALLOT CARRIES THE SAME CONTRADICTION, AND IT IS NOT YET RESOLVED

`Official-Cumulative-Report-P26.pdf` — the Fayette County Clerk's **own official** cumulative report for the
2026 primary, saved to the seed directory — heads its races `OFFICIAL BALLOT FOR FAYETTE COUNTY` and
contains:

| Race on the 2026 primary ballot |
| --- |
| `COUNTY JUDGE/EXECUTIVE` |
| `COUNTY COMMISSIONER District 1` |
| `COUNTY COMMISSIONER District 2` |
| **`MAGISTRATE District 3`** |
| `CONSTABLE District 1` · `CONSTABLE District 3` |

So the third fiscal-court seat is labelled **Magistrate** while the first two are labelled **Commissioner**,
and the charter says all three are **at-large**. Three descriptions, three different structures.
🔴 **Do not seat the third member until the county's own record says what that seat is called.**

### The occupancy that two independent sources agree on

| Seat | Holder | Sources |
| --- | --- | --- |
| County Judge/Executive | **Mary Diane (McCord) Hanna** | WKYT 2025-06-05; Wikipedia fiscal-courts list; her own 2026 re-filing |
| Fiscal Court Commissioner 1 | **Brian Miller** | WKYT 2025-06-05; Wikipedia |
| Fiscal Court Commissioner 2 | **Alayne White** | WKYT 2025-06-05; Wikipedia |
| Fiscal Court Commissioner 3 | **David Lowe** | WKYT 2025-06-05; Wikipedia |

Both sources read *elected 2022*, which under Ky. Const. § 99 puts the term start at the **first Monday in
January after the election — 2023-01-02**. ⚠ That is a *computed* date, and KY-2 and KY-3 each proved a
computed arrival wrong. It must be checked against the county's own record before it is written at day
precision; year precision is the honest fallback.

### 🔴🔴 `WebFetch` FABRICATED FOUR NAMES AND THREE DISTRICT LABELS

Asked for the Fayette row of the Wikipedia fiscal-courts list, `WebFetch` returned
*"District A: Noah Karsten Grimes · District B: Mark S. Lynch · District C: Kathleen Parks"*.
**The raw bytes of that same page say `Commissioner 1 Brian Miller · 2 Alayne White · 3 David Lowe`.**
Every name and every district label in the summary was invented, and it was formatted as a quotation.

▶ **In this program `WebFetch` may be used to LOCATE a page. It must never be the source of a NAME, a DATE
or a COUNT.** Fetch the bytes and parse them. This is the broken-detector family, except the wrong answer
arrives wearing a citation.

### The statutory frame, read from the primary sources (PDFs in the seed directory)

- **Ky. Const. § 99** — every four years from 1998 each county elects a *Judge of the County Court, County
  Court Clerk, County Attorney, Sheriff, Jailer, Coroner, Surveyor and Assessor*, and per Justice's District
  one *Justice of the Peace* and one *Constable*. Terms start the **first Monday in January** after the
  election. So the 2022 winners began **2023-01-02** and the next election is **November 2026**.
- **Ky. Const. § 97** — *Circuit Court Clerk* and *Commonwealth's Attorney* every six years from 2000 →
  elected **2024**, term from **2025-01-06**. ▶ This is why no Circuit Court Clerk appears in the 2026
  filings: the absence is the cycle, not a missing office.
- **Ky. Const. § 104** — the General Assembly may abolish the *Assessor*; the elected successor is the
  **Property Valuation Administrator** (KRS 132.370).
- **Ky. Const. § 105** — the General Assembly may consolidate *Jailer* into *Sheriff*; where it does, **the
  office of Sheriff is retained** and the Sheriff performs the Jailer's duties.
- 🟢 **FAYETTE HAS NO ELECTED JAILER, AND THE CHARTER SAYS SO IN ITS OWN EDITOR'S NOTE**: *"Sections 11.05
  and 11.07 — The sheriff and jailer were merged effective January 3, 1994, by 1990 Ky. Acts Ch. 138."*
  KRS 67A.028 then let the urban-county government stand up a **correctional services division** holding all
  of the sheriff's and jailer's jail duties — Chapter 24 of the code — whose staff are classified civil
  service, **not** elected. No Jailer filed in Fayette in 2026, which agrees.

### Office inventory as it stands — ▶ NOT YET FINAL

| # | Office | Seats | Status |
| --- | --- | --- | --- |
| 1 | County Judge/Executive | 1 | charter 11.01 + editor's note; on the 2026 ballot |
| 2 | Fiscal Court Commissioner | 3 | charter 11.02; **third seat's title unresolved** |
| 3 | County Clerk | 1 | charter 11.03 |
| 4 | County Attorney | 1 | charter 11.04 |
| 5 | Sheriff | 1 | charter 11.05 |
| 6 | Property Valuation Administrator | 1 | charter 11.06 |
| 7 | Coroner | 1 | charter 11.07; Gary Ginn filed 2026 |
| 8 | Surveyor | 1 | charter 11.07; Gary Roland filed 2026 — **incumbency unverified** |
| 9 | Constable | 3 | charter 11.07; districts 1, 2, 3 all filed 2026 |
| 10 | Circuit Court Clerk | 1 | charter 11.07; § 97 cycle, elected 2024 |
| 11 | Commonwealth's Attorney | 1 | charter 11.07; § 97 cycle — **confirm the 22nd Judicial Circuit is Fayette County exactly** |
| — | Jailer | **0** | merged into Sheriff 1994-01-03 |
| — | Justice of the Peace | ? | named in charter 11.07, but the fiscal court is commissioners |

**Open scope question for Cantrell:** the 2026 ballot also carries **Soil and Water Conservation District
Supervisor** (3 filed). The voters elect it, which is the inclusion test, but it is a special district
rather than a city or county office and no earlier slice in this program has seated one.
⚠ **Elected judges stay deferred to the judges wave**, as PA-4 recorded — that is scheduling, not exclusion.

### Sources pulled to disk this session (untracked, under `backend/data/seed-ky-2026/`)

`charter-article-11.txt` · `fayette-official-cumulative-P26.pdf` · `kyconst-sec097/099/100/104.pdf` ·
`krs-67a-020/028/030/060.pdf` · `krs-67a-index.html` · `sos-countyfilings-34.html` ·
`wiki-ky-fiscal-courts.html` · `lex-county-state-services.html` · `fayette-judge-exec-site.html`

### 🔴 Publisher and fetch traps this stage has already hit

- **amlegal no longer publishes Lexington-Fayette at all.** Every search engine still points the charter at
  `codelibrary.amlegal.com/codes/lexingtonfayettecoky/...`, which **403s** a `fetch` and a bare `curl` and
  **404s** in a real browser. amlegal's own Kentucky region index lists Louisville-Jefferson County and
  **not** Lexington. The live code is Municode's **`lexington-fayette_urban`** client, which is what
  `lexingtonky.gov` itself links to.
- ⚠ **`library.municode.com/ky/lexington-fayette_county` is an EMPTY CLIENT SHELL** that returns a clean 200
  and renders a "Publications" heading with nothing under it. A second Municode client for the same city,
  also still indexed. **Two live-looking publishers, one real one.**
- **Municode's `/api/codesToc` returns 401 to `curl` and 401 to `fetch` inside the page.** Drive the UI.
- **`vrsws.sos.ky.gov` 403s `curl` behind an "Acceptable Use Policy" page.** Playwright reaches it.
- ⚠ **The two Secretary of State systems disagree on Fayette's county id — filings uses `34`, election-night
  reporting uses `36`.** Neither is the FIPS (`067`). Assert the county name printed in the result.
- ⚠ **`apps.legislature.ky.gov/Law/Constitution/…?rsn=N` — `rsn` IS A ROW NUMBER, NOT A SECTION NUMBER.**
  `rsn=99` returns **Section 91** and `rsn=114` returns **Section 105**; the offset is not constant, because
  headings occupy rows too. Every section cited above was confirmed by reading its own printed title.
- ⚠ **`fayettecountyjudgeexecutive.com` is a PARKED DOMAIN** — HTTP 200, **114 bytes**, a script redirect to
  `/lander`. It is the email domain on the judge/executive's own candidate filing, and it publishes nothing.

### ▶ Next steps for KY-4, in order

1. **Resolve the third fiscal-court seat** (Commissioner or Magistrate) and how the three are elected —
   at-large per the charter, or by district per the ballot. From the county's own record, not a secondary
   source.
2. **Verify every current holder individually and date each arrival.** Sheriff, County Clerk, County
   Attorney and PVA each publish their own site (`fayettesheriff.com`, `fayettekyclerk.gov`,
   `fayettecountyattorney.com`, `fayettepva.com`), all four linked by `lexingtonky.gov` itself. Coroner,
   Surveyor, Constables and Circuit Court Clerk have no obvious publisher yet.
3. **Decide the Soil and Water question** and record the ruling.
4. Write `ROSTERS-fayette.md`, then take the slots (`steward slot CC`) and write structure + occupancy —
   **offices and people in ONE wave**, per spec §3 stage 4.
5. Dry-run `BEGIN; … ROLLBACK;`, confirm the rollback reverted, then apply, measure from outside against a
   same-session baseline, and re-probe end to end.

### ✅ KY-4 RESEARCH CLOSED 2026-09-26 — 18 seats rostered, still nothing written to production

Full roster, every source and every change-check:
[`backend/data/seed-ky-2026/ROSTERS-fayette.md`](../../backend/data/seed-ky-2026/ROSTERS-fayette.md).

**Correction to the block above.** It said the vote totals showed the three fiscal-court seats were
elected **by district**. They are not — they are **at-large**, as charter 11.02 says. That reading
came from the 2026 primary PDF, whose columns `pdftotext -layout` had **interleaved**, so the numbers
compared were not on the lines they appeared to be on. The county's certified **2022 general**
results parse cleanly and carry explicit `TOTAL` rows: commissioners **66,529 / 66,114 / 503**
(countywide scale, against a 102,742-vote countywide judge/executive race) while magistrates and
constables run **18,904–23,292** (one-third scale). `DIST 1/2/3` on the commissioner line is a **seat
number, not a geography**. ▶ **A total you did not see labelled `TOTAL` is not a total.**

That also answers the "third seat" question the block above left open: all three commissioner seats
are at-large, and the lone `MAGISTRATE District 3` label on the 2026 primary report is not a third
commissioner at all — Fayette elects **commissioners and magistrates both**, nine district-and-
at-large seats in total, and the county's own 2022 certified results list all nine.

### What the change-check caught — it paid twice

- 🔴 **The county clerk who won in 2022 does not hold the office.** Don Blevins Jr. won with 69,903
  votes (67%); **Susan Lamb** was appointed **2023-02-01** and then won the **November 2023 special
  election**. Her office publishes its own succession list — `Susan Lamb 2023-Present · Donald W.
  Blevins Jr. 2009-2023`. Seating the 2022 winners wholesale would have seated the wrong person.
- 🔴 **Magistrate District 3 changed hands and nothing dates it.** George Biggerstaff won it in 2022,
  assumed **2023-01-02** and **left office 2023-08-26**; the city's own GIS layer carries
  `MAGREP = "Chrysanthia Carr-Seals (D)"`. No source anywhere gives her arrival date, so that row
  gets an **open-ended term at `start_precision => 'unknown'`**. ⚠ A Beshear press release
  reappointing the same person to a **state board** through 2027-01-17 is a different body and is
  not evidence about this seat.
- 🟢 Thirteen seats were confirmed unchanged by a source independent of the 2022 result. **That is
  the result, not a skipped step.**

### The arrival dates, and the five that predate the current term

**4 day · 13 year · 1 unknown · 0 invented · 5 appointed.** Only four arrivals are claimed at day
precision, and every one of them is a **first-party or contemporaneous** statement:

| Seat | Holder | Arrival | Source |
| --- | --- | --- | --- |
| PVA | David O'Neill | **2009-02-11** | 🟢 his own office — *"since February 11, 2009, when he was appointed by Governor Steve Beshear"* |
| County Attorney | Angela C. Evans | **2022-09-30** | WKYT the same day — *"He is stepping down Friday. Evans was sworn in at 3 Friday afternoon."* |
| Commonwealth's Attorney | Kimberly Baird | **2022-10-01** | Ballotpedia raw, a specific non-default date |
| County Clerk | Susan Lamb | **2023-02-01** | Ballotpedia raw, a specific non-default date |

🔴 **Everyone who simply took office on the constitutional default gets YEAR precision, not day.**
Ky. Const. § 99 fixes "the first Monday in January after their election" — 2023-01-02 — and
Ballotpedia prints exactly that for nine of these seats. **That is a computed date wearing a
citation.** KY-2 and KY-3 each proved a computed arrival wrong inside this slice; the rule holds.

⚠ **Five of eighteen do not start when their current term did** — Witt 1999, Ginn 2003, O'Neill 2009,
Riggs 2013, Sparks 2015. `office_terms` carries continuous occupancy, so a re-election must never
overwrite the earlier start. The KY-2/KY-3 gap-case trap, at 28% of the wave.

### 🟢 The magisterial geography exists, and it is the city's own

`services1.arcgis.com/Mg7DLdfYcSWIaDnu/…/Magisterial_District/FeatureServer/0` — *"Boundaries
representing the magisterial districts of Lexington-Fayette County, Kentucky"* — **3 features**,
`MAGISTERIAL` 1/2/3 and `MAGREP`. `wkid 102679` / `latestWkid 2246`, KY State Plane North in feet, so
**`outSR=4326` is load-bearing** exactly as in KY-1.

⚠ **One set of polygons is used twice**: Ky. Const. § 99 elects one Justice of the Peace **and** one
Constable per Justice's District, and the vote totals pair up district by district
(D1 18,904/18,950 · D2 21,740/23,292 · D3 22,851/22,684).

⚠ **KY-3 recorded "four council-district layers"; the catalogue carries six** — `Council_District`
plus `_1972`, `_1982`, `_1992`, `_2002`, `_2012`. The trap KY-3 documented is real and slightly
larger than it recorded. It does not change KY-3's result, which proved the live layer by area.

### What KY-4 will write, once the scope question is answered

| Layer | Rows |
| --- | --- |
| Government | **none new** — the existing `Lexington-Fayette Urban County Government, Kentucky, US` row, as Philadelphia did in PA-4 |
| Chambers | `Fayette County Fiscal Court` + `Fayette County Elected Officials` (and a magistrate/constable chamber if those are in scope) |
| Districts | 12 seats on the **existing** countywide `21067`/`G4020` row; **3 new** magisterial districts if magistrates and constables are in scope |
| Boundaries | **3** magisterial polygons, if in scope |
| Offices + people | **18**, or **12** if magistrates and constables are excluded |

▶ **Nothing has been written. No migration slot has been taken.** The next act is the scope ruling,
then `steward slot CC` for the structure and occupancy pair.

---

## ✅ KY-4 APPLIED 2026-09-26 — Fayette County is seated, 18 offices, 18 seated, 0 vacant

`X0069` (3 magisterial boundaries) + `CC_0154` (structure) + `CC_0155` (occupancy):
**18 offices — 4 Fiscal Court + 14 county elected officials — 18 seated, 0 vacant, 18 people created,
0 reused.** No new government row: these hang on the Lexington-Fayette row KY-3 created, which is
Philadelphia's shape in PA-4.

### Measured from outside, against a same-session baseline

| Measure | Before | After | Delta |
| --- | --- | --- | --- |
| `politicians` | 89,165 | 89,183 | **+18** exact |
| `offices` | 9,706 | 9,724 | **+18** exact |
| `office_terms` | 9,642 | 9,660 | **+18** exact |
| `districts` | 10,275 | 10,278 | **+3** exact |
| `geofence_boundaries` | 72,457 | 72,460 | **+3** exact |
| `governments` | 608 | 608 | **0** — deliberately |
| `chambers` | 1,326 | 1,328 | +2 |
| `offices_missing_terms` | 422 / 238 unflagged | 422 / 238 | **unmoved** |

Fiscal Court **4/4** and Elected Officials **14/14** seated, counting `och.politician_id` — never
rows, because `office_current_holder` LEFT JOINs from `offices`.

**Idempotent, proved by re-running all three**: `inserted 0 boundary row(s)`, every `essentials.*`
write `INSERT 0 0`, and all six counts identical afterwards.

### The wave in one table

| Chamber | Offices | Geography |
| --- | --- | --- |
| `Fayette County Fiscal Court` | County Judge/Executive + 3 Fiscal Court Commissioners | countywide `21067`/`G4020` |
| `Fayette County Elected Officials` | Clerk · County Attorney · Sheriff · PVA · Coroner · Surveyor · Circuit Court Clerk · Commonwealth's Attorney | countywide `21067`/`G4020` |
| `Fayette County Elected Officials` | 3 Magistrates + 3 Constables | 3 new magisterial districts, `X0069` |

**Term dates: 4 day · 13 year · 1 unknown · 0 invented · 5 appointed.**

### 🔴🔴 THE SPEC WAS WRONG FOR THIS JURISDICTION, AND THE CHARTER IS WHAT SAID SO

Spec §3.2 rules that a consolidated city-county's stage 4 **drops the county commission** because the
council already is it. True in Philadelphia, Columbus-Muscogee and Macon-Bibb. **False in Lexington.**
Charter 11.01 keeps the County Judge and 11.02 keeps the Fiscal Court — *"composed of the Judge of the
County Court and three (3) Commissioners to be elected from the Urban County at-large"* — with the
school ad valorem levy, the county road-aid advisory power and a County Budget Commission seat.

▶ **`READ THE CHARTER, NOT THE PATTERN.` "Consolidated" is a description, not a template**, and this
is the fourth consolidated jurisdiction in the program and the first to keep its commission.

### 🔴🔴 AND FAYETTE ELECTS COMMISSIONERS *AND* MAGISTRATES — NINE SEATS WHERE A TEMPLATE EXPECTS THREE

They are not alternative forms of one body here. The Fiscal Court is the **commissioner** form; the
Justices of the Peace survive **separately** under charter 11.07 and do not sit on it. The county's
own certified November 2022 general results list `COMMISSIONER 1/2/3`, `MAGISTRATE 1/2/3` **and**
`CONSTABLE 1/2/3`. Vote Local Lexington states what the magistrate actually does in Fayette:
*"the main role of the Magistrate is to conduct marriages."* Each office carries a `description`
saying so — **describe the real powers; do not make jurisdictions uniform.**

### 🟢 THE VOTE TOTALS DISCRIMINATED AT-LARGE FROM DISTRICT, AND OVERRULED THE BALLOT LABEL

The certified 2022 return gives the commissioners **66,529 / 66,114 / 503** against a
**102,742**-vote countywide judge/executive race, while magistrates and constables poll
**18,904–23,292** — one third. So the commissioners are elected **at-large**, exactly as charter
11.02 says, and `District 1/2/3` on a commissioner ballot line is a **seat number, not a geography**.
All three hang on the countywide polygon; the title still reads *District N* because that is what
the county prints, and `offices.description` carries the truth.

🔴 **I READ THIS WRONG FIRST.** An earlier pass used the 2026 **primary** report and concluded the
commissioners were district-elected. `pdftotext -layout` had **interleaved that report's columns**,
so the numbers compared were not on the lines they appeared on. The 2022 file parses cleanly and
carries explicit `TOTAL` rows. ▶ **A total you did not see labelled `TOTAL` is not a total.**

### 🔴 David Lowe holds a countywide seat on 503 WRITE-IN votes

Marked `(W)` on the county's own return, against 66,529 and 66,114 for the other two commissioners.
**A turnout-based sanity check would flag that row as corrupt. It is correct.** Recorded because the
next person to write a plausibility gate over `office_terms` will meet it.

### 🔴🔴 A CERTIFIED RESULT IS NOT A FACT ABOUT WHO HOLDS THE SEAT — IT PAID TWICE HERE

- **County Clerk.** Don Blevins Jr. won November 2022 with 69,903 votes (67%) and does **not** hold
  the office. **Susan Lamb** was appointed **2023-02-01** and then won the **November 2023 special**.
  Her own office publishes the succession list: `Susan Lamb 2023-Present · Donald W. Blevins Jr.
  2009-2023`. Seating the 2022 winners wholesale would have put the wrong person in the office that
  **runs Fayette County's elections**.
- **Magistrate District 3.** George Biggerstaff won it in 2022, assumed **2023-01-02** and **left
  office 2023-08-26**. The city's own GIS layer names **Chrysanthia Carr-Seals**; districts 1 and 2
  match the certified result exactly.

🟢 **Thirteen seats were confirmed unchanged by a source independent of the 2022 result. That is the
result, not a skipped step.**

### 🔴 ONE ARRIVAL IS UNDATABLE, AND IT IS WRITTEN THAT WAY

No publisher anywhere gives a day, a month or even a stated year for Carr-Seals' appointment. Her row
is an **open-ended term with `start_precision = 'unknown'` and a NULL `term_start`**. *"The day after
Biggerstaff left"* is not a source. A named gate asserts that row stays NULL, and it was watched
firing when a computed date was substituted.
⚠ A Governor's press release reappointing the same person to a **state board** through 2027-01-17 is
a different body and is not evidence about this seat.

### 🔴🔴 "FIRST MONDAY IN JANUARY" IS A COMPUTED DATE WEARING A CITATION

Ky. Const. § 99 fixes a county officer's term start at the first Monday in January after the
election — **2023-01-02** for the 2022 winners — and a secondary source prints exactly that for
**nine of these eighteen**. It is not an observation. Every such row is written at **year**
precision. Only four arrivals are claimed at day precision and each is first-party or
contemporaneous: O'Neill **2009-02-11** (his own office, *"appointed by Governor Steve Beshear"*),
Evans **2022-09-30** (WKYT the same day, *"sworn in at 3 Friday afternoon"*), Baird **2022-10-01**,
Lamb **2023-02-01**. ▶ Year precision under-claims rather than over-claims. This is KY-2's and
KY-3's finding, holding for a third time in one slice.

⚠ **Five of eighteen do not start when their current term did** — Witt 1999, Ginn 2003, O'Neill 2009,
Riggs 2013, Sparks 2015. `office_terms` carries continuous occupancy, so a re-election must never
overwrite the earlier start. The gap-case trap at **28%** of the wave.

### 🔴🔴 `WebFetch` FABRICATED FOUR NAMES AND THREE DISTRICT LABELS, FORMATTED AS A QUOTATION

Asked for the Fayette row of the Wikipedia fiscal-courts list, it returned *"District A: Noah Karsten
Grimes · District B: Mark S. Lynch · District C: Kathleen Parks"*. **The raw bytes of that same page
read `Commissioner 1 Brian Miller · 2 Alayne White · 3 David Lowe`** — which is also what WKYT says.
Every name and every district label was invented.

▶ **In this program `WebFetch` may LOCATE a page. It must never be the source of a NAME, a DATE or a
COUNT.** Fetch the bytes and parse them. It is the broken-detector family, except the wrong answer
arrives wearing a citation, so nothing about it looks wrong.

### 🟢 THE MAGISTERIAL GEOGRAPHY, AND THE VINTAGE TEST THAT COULD NOT BE RUN

`Magisterial_District` (`services1.arcgis.com/Mg7DLdfYcSWIaDnu`, owner **`gis_lfucg`**) — 3 features,
`MAGISTERIAL` 1/2/3. `wkid 102679`, KY State Plane North in **feet**, so `outSR=4326` is load-bearing
exactly as in KY-1. **One set of polygons carries six offices**, because Ky. Const. § 99 elects one
Justice of the Peace *and* one Constable per Justice's District — and the certified vote totals pair
up district by district (D1 18,904/18,950 · D2 21,740/23,292 · D3 22,851/22,684).

🔴 **KY-3's area-versus-prior-vintage test cannot be run here, and that absence is the finding.**
Lexington publishes **six** council-district layers, so KY-3 could prove the live one by area against
`_2012`. The catalogue carries exactly **one** magisterial layer. Vintage therefore rests on: the
city's own GIS account as publisher, item created **2020-12-18** (post-census), `lastEditDate`
**2025-04-24**, and — as corroboration only — a `MAGREP` attribute naming a person who took the seat
after 2023-08-26. ⚠ **KY-2 found this same GIS family carrying a stale roster beside correct
geometry. Attributes and geometry are independent; neither vouches for the other.**

What **is** proved, by measurement: the three districts **tile the county** — 285.571 sq mi against
the place's 285.567, **99.991% covered**, 0.028 sq mi outside — and are **exactly disjoint**, largest
pairwise overlap **0.000000 sq mi**. ▶ Tiling is a **completeness** test, not a vintage test: a
superseded map of the same county would tile it too, and it is reported as such.

⚠ **KY-3 recorded "four council-district layers"; the catalogue carries six** (`_1982` and `_1992`
as well). The trap it documented is real and slightly larger than recorded. KY-3's result stands.

### Gates, each watched failing for its own reason

| Gate | Tamper | Fired |
| --- | --- | --- |
| Loader: feature count | expect 4 features | `[magisterial count assertion] … 3 features, expected 4` |
| Loader: tiling | demand 150% place coverage | `[magisterial tiling assertion] … cover only 99.991%` |
| Loader: disjointness | tolerance below the measurement | `[magisterial disjointness assertion] … above the -1 sq mi tolerance` |
| **`CC_0154` Jailer** | create a `Jailer` office | **`a JAILER office exists … Fayette elects no jailer`** |
| **`CC_0154` `geo_id` collision** | point the Sheriff at `21067`/`G5220` | **`1 Fayette office(s) landed on a district that is neither the county nor a magisterial district`** |
| `CC_0155` undated arrival | give Carr-Seals a computed date | `expected exactly 1 unknown-precision term … got 0` |
| `CC_0155` duplicate name | *(not a tamper — it fired for real)* | `DUPLICATE_POLITICIAN_NAME … Brian Miller` |

🔴 **THE DISJOINTNESS CONTROL DID NOT FIRE THE FIRST TIME, AND THE CONTROL WAS THE THING AT FAULT.**
Set to a tolerance of `0`, it passed: the districts overlap by **exactly** 0.000000 sq mi, and
`0 > 0` is false. A tamper that cannot trip a strict comparison proves nothing about the gate behind
it. Re-armed at `-1`, the true measurement trips it and the gate's own message is exercised.
▶ **Watch the control fail. A control that passes may be passing for the wrong reason.**

🔴 **The Jailer and the undated-arrival controls each tripped an earlier COUNT gate first**, so each
count gate was relaxed to let execution reach the gate under test — the ordering problem KY-2's
collision gate and KY-3's Vice Mayor gate both had. A control that aborts for the wrong reason proves
nothing.

### 🟢 The duplicate-name guard fired for real, and both collisions were read before it was lifted

It stopped the wave on **Brian Miller**. Both namesakes were opened and identified before the guard
was touched, because the guard's own warning is right — *a sitting officeholder running for a
different seat is the normal case, not a different person*:

| Name | Existing row | Verdict |
| --- | --- | --- |
| Brian Miller | `-300285`, a 2026 candidate for **U.S. House, MONTANA district 2** | different person |
| David Lowe | `-100591`, a sitting **TEXAS House district 91** member | different person |

The insert is **split** so the guard stays armed for the other 16. The sixteen zeros were
**CONTROLLED** against two names known to exist (Steven Rudy from KY-2, Linda Gorton from KY-3, each
returning 1), so they are real answers and not a broken query.

### Dry run and verification

Both migrations were dry-run against production in **one transaction ending in `ROLLBACK`**, and the
rollback was **confirmed to have reverted** — all five counts back to 89,165 / 9,706 / 9,642 /
10,275 / 1,326, with zero Fayette chambers and zero Fayette people surviving.

✅ **END-TO-END on live production.** Every Fayette point returns **14** Fayette County offices: the
**12 countywide** seats plus **exactly one** magistrate and **exactly one** constable — not three of
each. The three magisterial districts discriminate:

| Point | Magistrate | Constable |
| --- | --- | --- |
| Lexington-Fayette Government Center | Rosalind A. Bryant (D1) | Andrea Welker (D1) |
| inside magisterial district 2 | Lisa Moore Fath (D2) | Jim McKenzie (D2) |
| inside magisterial district 3 | Chrysanthia Carr-Seals (D3) | Edward Sparks (D3) |

- **Negative controls**: Frankfort, KY returns **0** Fayette offices; Nashville, TN returns **0**.
- ⚠ A first pass reported Frankfort returning 1. **The probe was wrong, not the data** — it counted
  district rows rather than offices, so a Franklin County polygon with no Fayette office scored 1.
  Counting `o.id` gives 0.
- ✅ `check:reachability` — nothing regressed, all three buckets at baseline
  (`BAD_GEOMETRY` 4, `DEAD_GEOGRAPHY` 17, `UNREACHABLE` 7).
- ✅ `check:occupancy`, `check:migrations`, `check:reservations` — all green.

### Debts and deferrals this wave records

- ⏸ **Soil and Water Conservation District Supervisor** (3 on the 2026 Fayette ballot) is **not
  seated**. The voters elect it, which is this program's inclusion test, but it is a special district
  rather than a city or county office and no slice in thirteen has seated one. Ruled out of KY-4 by
  Cantrell 2026-09-26; it is a **program-wide** question, not a Kentucky one.
- ⏸ **Elected judges** — Circuit, Family and District judges of the 22nd Judicial Circuit — stay
  deferred to the judges wave, as PA-4 recorded. Scheduling, not exclusion.
- ⚠ **Carr-Seals' arrival date is owed** if it can ever be sourced; the row is honest as it stands.
- ⚠ **`CC_0152`'s post-verify gate is now stale on replay.** This wave took Kentucky's `LOCAL`
  district count from 13 to 16, so re-running `CC_0152` would raise `expected 13 Kentucky LOCAL
  districts`. Migrations here are applied once and never replayed, so nothing is broken — recorded so
  the discrepancy is not read as drift.

▶ **Lexington scores 4 of 5. Next: stage 5, assets** — portraits for everyone seated in the slice
(138 legislators + 16 city + 18 county = **172 people**) plus one `lexington` banner.
