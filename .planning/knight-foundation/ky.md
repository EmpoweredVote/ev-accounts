# KY — slice 13 (Lexington · Fayette County)

Program tracker: [`PROGRAM.md`](./PROGRAM.md) · spec:
[`2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md)

**Opened 2026-09-26.** Lease `state:ky` held by chris@empowered.vote on DESKTOP-G6KDNN2.
Worktree `C:\ev-accounts-ky`, branch `knight/ky-slice13`.

| Stage | State |
| --- | --- |
| 1 geography | ✅ **APPLIED 2026-09-26 — 138 boundaries, 138 districts, 0 errors.** Only `sldu` + `sldl` were owed; `place` already existed |
| 2 legislature | ✅ **APPLIED 2026-09-26 — 138 offices, 138 seated, 0 vacant** (`CC_0150`/`CC_0151`). Lexington scores **2 of 4** |
| 3 city waves | — Lexington-Fayette Urban County Council, unmeasured |
| 4 county waves | — Fayette County officers. Consolidated, so the commission drops and the officers stay |
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
