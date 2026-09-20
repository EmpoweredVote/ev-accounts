# SC — slice 7 (Columbia · Myrtle Beach)

Program tracker: [`PROGRAM.md`](./PROGRAM.md) · spec:
[`2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md)

| Stage | State |
| --- | --- |
| 1 geography | ✅ applied 2026-09-20 |
| 2 legislature | — owes 170 offices |
| 3 city waves | — Columbia, Myrtle Beach |
| 4 county waves | — Richland, Horry |
| 5 assets | — |

---

## Baseline, measured against production 2026-09-20 (before anything was written)

Re-measure rather than trust this once any wave has applied.

### What exists

| Layer | Count | Note |
| --- | --- | --- |
| `districts` COUNTY | 46 | all 46 carry a `geo_id`. **Richland `45079`** (Columbia) and **Horry `45051`** (Myrtle Beach) are both present |
| `districts` NATIONAL_LOWER | 7 | congressional |
| `districts` NATIONAL_UPPER | 1 | |
| `districts` STATE_EXEC | 5 | Governor, Lt. Governor, Attorney General, Secretary of State, Treasurer — all five seated |
| `geofence_boundaries` G4020 | 46 | counties, imported 2026-07-10 |
| `geofence_boundaries` G5200 | 7 | congressional, imported 2026-04-02 |
| `geofence_boundaries` G6350 | 424 | ZCTAs |
| `geofence_boundaries` G4110 | 271 | **incorporated places — imported 2026-09-19, the day before this wave opened.** Columbia city `4516000` and Myrtle Beach city `4549075` both present with geometry |
| `geofence_boundaries` G4210 | 204 | CDPs, same import |
| `governments` "State of South Carolina" | **1** | ✅ not Indiana's 18 |
| `chambers` | 5 | all statewide executives; **no legislative chamber** |

### What did not exist

- **No `STATE_UPPER` and no `STATE_LOWER` districts, and no `G5210`/`G5220` boundary rows.** Zero.
- **No state legislative offices.** SC held **15 offices in total**: 7 US House, 2 US Senate, 5
  statewide executives, plus one `Candidate for U.S. Senate — South Carolina` office.
- **No government row for Columbia and none for Myrtle Beach**, and no `districts` row for either
  place — normal, because `place` writes a boundary and never a district.
- **No county subdivisions** (`G4040`). South Carolina is not an MCD state in the way Pennsylvania is.

Indiana's shape does not recur here, and that was verified rather than assumed: one government row,
zero offices on a pseudo-chamber, and `data_source ILIKE '%discovery%'` returns nothing at all,
nationally.

---

## 🔴 Traps found while opening the wave

### 1. 🔴🔴 SOUTH CAROLINA REDREW ITS HOUSE TWICE IN ONE YEAR, AND ONLY THREE POINTS SEPARATE THE TWO MAPS

S.C. Const. Art. III fixes the chambers at 124 and 46, so — exactly as in Pennsylvania — a count can
never date the map. South Carolina then adds a second layer that Pennsylvania does not have:

| Plan | Signed | Status |
| --- | --- | --- |
| 2012 plan | | superseded |
| **Act 118** | 2022-01-27 | House **superseded five months later**; Senate still current |
| **Act 226** | 2022-06-17 | the remedial House plan, "effective for the 2024 election" (RFA) |

So a 124-polygon file is consistent with **three** House maps, two of them five months apart.

**The proof is on all 170 polygons.** Each TIGER 2024 polygon was tested at its own internal point
against the **State of South Carolina's own ArcGIS server**, `gis.state.sc.us`
(`Boundaries_Districts/House_Districts` and `/Senate_Districts`), maintained by the Revenue and
Fiscal Affairs Office — the agency that draws these maps, not a Census mirror:
**124/124 and 46/46 agree, 0 differ, 0 errors.** TIGER's own `LSY` field reads 2024 on every record.

⚠ **And the sweep was then made to fail, twice.**

| Control | Result |
| --- | --- |
| TIGER 2022 — **Act 118**, the superseded House map | **3** districts differ: `HD 52 ↔ 70` swap at their internal points, and `95 → 90` |
| TIGER 2018 — the 2012 plan | **21** House and **6** Senate districts differ |

🔴 **The Act 118 control is the one that matters.** Only three internal points move between the
superseded House map and the live one. A count, a shape check, a plausibility check on population,
and even a comparison against the 2012 plan would all wave the wrong map through. Tool:
[`backend/scripts/verify-sc-tiger-vintage.mjs`](../../backend/scripts/verify-sc-tiger-vintage.mjs),
which carries every half — the 2024 sweep and both controls — and names the districts each control
moves rather than reporting a number.

### 2. 🔴 THE `geo_id` COLLISION IS WITH COUNTIES, AND THIS SLICE'S OWN TWO COUNTIES ARE IN IT

SC legislative GEOIDs run `45001..45124` (House) and `45001..45046` (Senate). SC's 46 counties are
`45001..45091`, odd numbers only. Measured 2026-09-20:

- **all 46 county geo_ids are also a House district geo_id**,
- **23 are also a Senate district**,
- **all 46 Senate ids are also House ids**.

🔴 **`45079` is Richland County AND House District 79** — Richland is Columbia's parent county.
**`45051` is Horry County AND House District 51** — Horry is Myrtle Beach's. Both of this slice's
county waves sit inside the collision. The key is `(mtfcc, geo_id)`, never `geo_id` alone.
`essentials.districts` is safe by construction — `insertDistrictIfMissing` dedupes on
`(geo_id, district_type)` — and it is ad-hoc SQL that will get this wrong. Congressional is
unaffected (4-character ids, `4501..4507`).

### 3. ⚠ THE PLACE LAYER ARRIVED ONE DAY EARLIER, FROM A DIFFERENT WAVE

SC's `G4110` (271) and `G4210` (204) were imported on **2026-09-19** by the municipal wave, not by
this program — the same thing that happened to Pennsylvania one day before PA-1. So **stage 1 here
owed legislative geography only**, and `place` is excluded from SC's allowlist entry with the reason
written next to it. The lesson is the tracker's own: **measure the layer before loading it.**

### 4. 🔴 SIX PLACES ARE NAMED "COLUMBIA CITY", AND TWO SC CITIES CONTAIN "MYRTLE BEACH"

Measured nationally in `geofence_boundaries`:

| Name | Where |
| --- | --- |
| Columbia city | KY `2116750` · MS `2815340` · **SC `4516000`** · SD `4613420` · TN `4716540` |
| Columbia City | IN `1814716` |
| Myrtle Beach city | **SC `4549075`** |
| North Myrtle Beach city | SC `4551280` |

Within SC, `%columbia%` also returns **West Columbia**. This is Minnesota's `St. Paul` trap with a
wider blast radius: a name match can hit five other states. **Match on `geo_id`.** No government row
currently exists for either target, and the only near-miss row nationally is `District of Columbia`.

### 5. ⚠ `check:child-county` CANNOT SEE THIS LOAD, AND THAT WAS READ IN THE SOURCE

The loader prints an ACTION REQUIRED banner asking for a matview refresh after any boundary insert.
It does not apply here: `scripts/check-child-county-mapping.mjs` defines a child as
`mtfcc IN ('G4110','G5420','G5400','G5410')`, so **`G5210` and `G5220` are not children** and this
wave's 170 rows cannot appear in the stale count. Checked in the check's own source, not inferred
from MN-1 or PA-1. The job's pre-existing red is recorded in [`pa.md`](./pa.md) and is not this
wave's.

---

# SC-1 — stage 1 APPLIED 2026-09-20. 170 boundaries, 170 districts, 0 errors.

`scripts/load-state-tiger-boundaries.ts --state SC --fips 45 --layers sldu,sldl`. No migration: this
loader writes `geofence_boundaries` and `districts` directly, the path MN-1 and PA-1 used.

### What was written

| | Boundaries | Districts |
| --- | --- | --- |
| `G5210` / STATE_UPPER | 46 | 46 |
| `G5220` / STATE_LOWER | 124 | 124 |

### Measured from outside, after the apply

- `districts` total **8,989 → 9,159** and `geofence_boundaries` total **71,130 → 71,300** — both moved
  by exactly **170**. Nothing else moved.
- **`offices_missing_terms` unmoved at 823 / 655 unflagged.** Stage 1 creates no office, so this is
  the number that must not move, and it did not.
- **170 distinct `ocd_id`s for 170 rows** (`…/state:sc/sldl:1` … `sldl:124`, `sldu:1` … `sldu:46`).
  The MN `08A` / MD `1A` collapse cannot arise in a state whose codes are plain digits, and the
  loader asserts the distinct count rather than reasoning about it.
- All 170 geometries **valid**, SRID **4326**, and every one a simple polygon — **0 multipolygon**.
- **Idempotent, proved by re-running**: the second run reports `Inserted 0 / Already existed 170`.

### Gates

- **Both pre-flight gates were watched failing first.** The count gate was tampered to expect 45
  Senate districts and aborted at `expected 45, got 46`, before any DB write. The OCD-ID gate was
  tampered to collapse every suffix to one and aborted at `46 records collapsed to 1 distinct`.
  Both were then restored and the real dry-run passed: `46 records (expected 46), 46 distinct
  OCD-ID suffixes` and `124 / 124`.
  - ⚠ **The first attempt at the OCD tamper silently did nothing AND deleted a guard.** A
    line-numbered edit landed on the `skipDistrictCodes` line instead of the `add` line, so the run
    went green with 46 distinct suffixes and the skip rule gone. The green was the tell — a control
    that is supposed to fail and does not has not proved the gate works, it has proved the tamper
    missed. **Read back what a control actually planted.** Same shape as MN-3's two controls that
    aborted for the wrong reason.
- **Per-district control: 46/46 and 124/124 resolve to exactly one district** of their own type by
  `ST_Covers` on `ST_PointOnSurface`, 0 failures.
- **Negative control:** Charlotte NC city hall matches **0** of the 170 SC polygons.
- **Six anchors probed against the rows actually in production**, each geocoded by the Census
  geocoder and answered by both production and the state's own layer:

| Anchor | SD | HD | Agrees with SC RFA |
| --- | --- | --- | --- |
| Columbia City Hall | 26 | 74 | ✅ |
| SC State House | 26 | 72 | ✅ |
| Myrtle Beach City Hall | 33 | 107 | ✅ |
| Charleston City Hall | 43 | 110 | ✅ |
| Greenville City Hall | 7 | 23 | ✅ |
| Rock Hill City Hall | 17 | 49 | ✅ |

- `check:reachability` **nothing regressed, two buckets below baseline**: `BAD_GEOMETRY` 4 of 5,
  `UNREACHABLE` 37 of 38, `DEAD_GEOGRAPHY` 17 of 17.

### 🟢 A third authority for stage 2 already exists, and it is the state's own

`gis.state.sc.us` carries the member on the district: `House_Districts` exposes `District_Num`,
`District`, `Rep_Aff` (name and party) and `URL`; `Senate_Districts` exposes `District_Num`,
`Senator` and `URL`, each `URL` pointing at that member's own `scstatehouse.gov` page.

⚠ Use it as the **third authority, not the primary**. It is a GIS attribute table, exactly the kind
of source that can be stale on a resignation. MN-2's rule stands: **a roster list page is not a
change-check; a member's own page is.** The `URL` field is what makes the per-member sweep cheap.

The same server also publishes `County_Council_Districts` and `Municipalities`, which stages 3 and 4
will need for Richland, Horry, Columbia and Myrtle Beach.

▶ **Stage 2 owes 170 offices — SC currently has ZERO state legislative offices and no legislative
chamber.**

---

# SC-2 — stage 2 APPLIED 2026-09-20. 170 offices, 170 seated, 0 vacancies.

`CC_0125` (structure) + `CC_0126` (occupancy), both slots **reserved from the allocator**. Generated
by `scripts/gen-sc-legislature-migrations.mjs` from `data/sc-legislature-roster.json`, so 170 seats
are never hand-typed. Roster and evidence:
[`backend/data/seed-sc-legislature-2026/ROSTERS.md`](../../backend/data/seed-sc-legislature-2026/ROSTERS.md).

| | |
| --- | --- |
| Offices | **170** — 124 Representatives + 46 Senators, 2 chambers, one government row |
| People | **169 created** (band `-2745200 .. -2745001`) + **1 reused** |
| Terms | **170**, all open-ended; **17 at `day` precision, 153 at `unknown`** |
| Vacancies | **0** — neither chamber has one today |

### Measured from outside, after the apply

- `politicians` **87,514 → 87,683**, exactly +169, and all 169 are inside the band.
- **170 offices, 170 seated** counting `och.politician_id` — never `count(*)`, because
  `office_current_holder` LEFT JOINs from `offices` and an unseated office is a NULL, not an absence.
- **`offices_missing_terms` unmoved at 823 / 655 unflagged.** Every office created here got a term.
- Chambers under *State of South Carolina*: 5 → **7**, the two new ones carrying `official_count`
  124 / 46 and `term_length` 2 / 4 (S.C. Const. Art. III).
- **0 terms carry a `term_end`.**
- **Idempotent, proved by re-running both**: every `essentials.*` write returns `INSERT 0 0` and both
  gates stay green.
- **Nobody seated here holds a second seat anywhere in the country** — checked nationally, not just
  inside South Carolina.

### 🔴🔴 THE DUPLICATE-NAME COLLISION WAS INSIDE THE WAVE, NOT AGAINST PRODUCTION

Two sitting South Carolina legislators are both `(first_name, last_name) = (Luke, Rankin)`:

| Seat | Member | Born | County | Member code |
| --- | --- | --- | --- | --- |
| HD-14 | Luke S. Rankin | 1997-08-16, Greenville | Laurens | `1510227092` |
| SD-33 | Luke A. Rankin, chairman of Senate Judiciary | 1962-04-09, Horry | Horry | `1511363455` |

Different births, different parents, different counties, different chambers, different codes — and
the production guard keys on the pair, so **the House row made the Senate row a duplicate of a
person who did not exist when the wave began.**

🔴 **A PRE-FLIGHT THAT COMPARES THE ROSTER ONLY AGAINST PRODUCTION CANNOT SEE THIS.** The two-pass
name search run before generation — exact pair, then surname-with-a-state-connection, the PA-2
procedure — returned two hits (Wes Climer, reused; John King of California, a different person) and
was blind to the collision *inside its own input*. The dry-run found it. The generator now asserts
that the armed set does not collide with itself and fails at generation time with both seats named.

### 🔴🔴 THE ELECTION DATE IS NOT THE TERM START, AND THE GAP REACHED SEVEN MONTHS

Eighteen member pages carry a line like *"Elected in Special Election June 3, 2025, to fulfill the
unexpired term of …"*. That is the **election**. HD-50's oath was administered on **2026-01-13**,
seven months later, because the House was not sitting in between — a member-elect is not a member.

**17 terms are dated from the OATH**, read out of each chamber's own journal by
[`backend/scripts/find-sc-oath-dates.mjs`](../../backend/scripts/find-sc-oath-dates.mjs). Three
detector defects were found and each was caught by its own count, not by inspection:

| Defect | What it did | What exposed it |
| --- | --- | --- |
| `[^.]` in the name window | "Keishan **M.** Scott" never matched — a middle initial contains a period | three names without an initial matched, so it read as a partial success |
| one chamber's wording | the House writes *"Member-elect from District No. N … oath of office was administered"*; the Senate writes *"Senator X presented himself at the Bar…"* | SD-12 returned a confident NOT FOUND across every probed day |
| `Senator SURNAME` | the journal prints a compound surname in full — *"Senator BRIGHT MATTHEWS"* | SD-45 read as NOT FOUND across **84** journal days |

⚠ **SD-26 is left UNDATED on purpose.** Russell Ott's page carries an arrival line — *"Elected in
Special Election October 29, 2013"* — but that dates a **House** seat he held ten years before
entering the Senate. Running the search against the journal of the chamber he sits in **today**
returns nothing for him, which is how the line was rejected instead of imported. **An arrival line
on a member page can belong to the other chamber.**

### 🔴🔴 THE MEMBER'S OWN PAGE IS NOT A CHANGE-CHECK EITHER — SD-15

All **170** member pages were read: every one names the member the list assigned to that district
(170/170) and states that district (170/170), 0 errors. It was still not enough.

**Wes Climer (SD-15) signed an irrevocable resignation effective 2026-11-03**, under S.C. Code
§ 8-1-145, so that his successor is elected at the November general election rather than at a
separate special election. His own page, his chamber's list, Open States and the state's GIS layer
all show him with no qualification — and all four are **correct**: he holds the seat until that
date, and he is written as its holder.

| Instrument | What it could see |
| --- | --- |
| roster list, member page, Open States, RFA | Climer, SD-15 — true today, and silent about November |
| the Senate Journal (273 sitting days swept) | **nothing** — his letter post-dates the last day it covers |
| `scvotes.gov` | **Senate District 15 Special Election — primary 2026-09-01, election 2026-11-03** |

▶ **No `term_end` is written** — a future `term_end` makes a seat silently self-vacate. **The debt:
on 2026-11-03, SD-15's term must be closed and its successor seated.** This is the Long Beach
District 7 shape.

⚠ **A journal sweep answers "who has left", never "who is leaving".**
[`backend/scripts/sweep-sc-journal-departures.mjs`](../../backend/scripts/sweep-sc-journal-departures.mjs)
read every sitting day of the 126th General Assembly — 257 departure sentences, all read — and
reports no unfilled seat. It could not have found SD-15.

### 🔴 The third authority is stale on 7 of 170 — in TWO DIFFERENT FIELDS

The RFA layer carries both a member label and that member's page URL. Three rows are stale in both
(HD-21, HD-98, SD-12 — all seats that changed hands and are now correctly seated here). **Four rows
carry the CURRENT member's name beside a STALE URL**: HD-88, HD-50, HD-113, and HD-97, whose URL
points at District **96**'s member. A check reading only the name would report 3; a check reading
only the URL would report 7 and call four of them turnovers. **Freshness is a property of a FIELD.**

### Gates, each watched failing first

| Control | Planted defect | Gate that fired |
| --- | --- | --- |
| 1 | occupancy applied without the structure | `expected 170 South Carolina legislative offices, got 0` |
| 2 | `sc_terms` emptied before the insert | `expected 170 terms, got 0` |
| 3 | a `Representative` office planted on **Richland COUNTY** `45079` | `1 COUNTY district(s) picked up a legislative office — a geo_id-only join` |
| 4 | HD-2's seat pointed at HD-1's person | `1 person(s) hold more than one South Carolina legislative seat` |
| 5 | HD-50's oath date removed | `expected 17 dated term(s), got 16` |
| 6 | SD-15 seated by a different existing row | `SD-15 is not held by the existing Wes Climer row (got 0)` |

Every control **aborted for its own reason**, and each ran against production inside a transaction
ending in `ROLLBACK`. Both migrations were then dry-run as **ONE transaction ending in ROLLBACK**,
and **the rollback was confirmed to have reverted**: 0 SC legislative offices, 0 people in the band,
`offices_missing_terms` unchanged, before anything was applied.

### ✅ End to end, on live production

`GET /api/essentials/address-search` after the apply:

| Address | State House | State Senate |
| --- | --- | --- |
| Columbia City Hall | **J. Todd Rutherford**, HD-74 | **Russell L. Ott**, SD-26 |
| SC State House | **Seth Rose**, HD-72 | **Russell L. Ott**, SD-26 |
| Myrtle Beach City Hall | **T. Case Brittain, Jr.**, HD-107 | **Luke A. Rankin**, SD-33 |
| Charlotte, NC *(negative control)* | Becky Carney, NC HD-102 | Caleb Theodros, NC SD-41 — **no SC seat** |

Every answer matches the state's own RFA layer at the same point, and Myrtle Beach returns the
**Senate** Luke Rankin, not the House one. ⚠ The first run of this probe reported **0 answers for
every address including the negative control** — a uniform answer, and the payload key was wrong.
The negative control is what made that visible.

**Per-district control: 46/46 and 124/124 polygons return exactly one office AND exactly one
holder**, 0 failures. `check:reachability` nothing regressed, two buckets below baseline;
`check:occupancy`, `check:migrations` and `check:reservations` green.

▶ **Next: stage 3 — Columbia and Myrtle Beach city councils, both unmeasured.** The state's own
`Municipalities` and `County_Council_Districts` layers are already located for stages 3 and 4.

---

# SC-3 — stage 3 APPLIED 2026-09-20. 14 offices, 14 seated, 0 vacancies.

`X0059` (4 Columbia council-district polygons), `CC_0127` structure, `CC_0128` occupancy. Roster and
evidence: [`backend/data/seed-sc-cities-2026/ROSTERS.md`](../../backend/data/seed-sc-cities-2026/ROSTERS.md).

| | |
| --- | --- |
| Offices | **14** — Columbia 7, Myrtle Beach 7, in 4 chambers under 2 new city governments |
| People | **14 created** (band `-2745400 .. -2745301`), 0 reused |
| Terms | **14**, all open-ended; **3 at `day`, 5 at `month`, 6 at `unknown`** |
| Vacancies | **0** |

Production held **nothing** for either city beforehand: one South Carolina government row (the
state), no city government, no local district, no city office.

### 🔴 The two councils are not made uniform

| | Columbia | Myrtle Beach |
| --- | --- | --- |
| Council | "the Mayor, Council District members (4), and At-Large Council members (2)" — seven, **counting the mayor** | a mayor and **six** councilmembers |
| Method | 4 single-member districts + 2 **unnumbered** at-large | **all six at large** (MASC states it in one word) |
| Geometry | 4 polygons loaded as `X0059` | **none, and none invented** — Tallahassee, State College and Boulder again |

`official_count` carries each city's own number (7 and 7), not a house convention.

### 🔴🔴 MYRTLE BEACH PUBLISHES TWO COUNCIL PAGES AND ONLY ONE IS MAINTAINED

`/government/mayor___city_council/` is current. `/government/mayor_and_city_concil/` still names
**Mayor Brenda Bethune** and **Councilman Gregg Smith**, whose terms ended in January 2026. Both
return **HTTP 200** with a complete roster, and the stale one still carries **five of the seven**
current members — so a name check against it passes for five people out of seven.

Two things separate them: the stale page's *"term expires January 2026"* — **Duluth's rule, that a
council's change-check signal is an expired date** — and the fact that the **Municipal Association
of South Carolina**, which maintains neither page, agrees with the other one. ⚠ The *misspelled*
path is the stale one, but the misspelling is not the tell: the city's own council history still
lives under that same path. `verify-sc-cities-roster.mjs` asserts the stale page is **still stale**,
so the day that changes is noticed rather than assumed.

### 🔴🔴 A RE-ELECTION DOES NOT RESTART AN OCCUPANCY — FIVE SEATS WOULD HAVE BEEN WRONG

Columbia's mayor and its District 1 and District 4 members were sworn in on **2026-01-05**, and
Myrtle Beach's Lowder and Hatley on **2026-01-13**. Every one of those is a **re-election**. Writing
the swearing-in would have restarted occupancies that never stopped: **Lowder has served since
January 2010 and Hatley since January 2018.**

🔴 **And the opposite case is in the same wave.** Myrtle Beach's **Philip N. Render** served January
2004 → December 2023, was **out for the 2024-2025 term**, and returned on 2026-01-13. "First
elected" would overstate his current occupancy by **22 years**. Both gates are asserted by name in
`CC_0128`.

⚠ **Myrtle Beach's "Who Served When" history is one term behind** — its last block is
January 2024-December 2027 and it does not list the January 2026 arrivals. It is an excellent source
for *when somebody started* and a poor one for *who is serving now*. Columbia has no equivalent at
all: it publishes election YEARS, which is why six of its seven seats are `unknown`.

### The district layer, and what was NOT proved

Columbia's `CouncilDistrict` publishes **four polygons and one attribute**, `LABEL`. No adoption
date, no plan name, and **no second boundary set to diff against** — the Philadelphia method is
unavailable here.

What was checked instead: the council's **own neighbourhood lists**, text published by the council
rather than by GIS, geocoded through a third party — **8 of 8 anchors** fall in the district the
page assigns them to, and **two points outside Columbia match nothing**. The districts do not
overlap, cover **99.955%** of the city, and extend **2.500 sq mi** beyond the TIGER place polygon
(annexation lag). One polygon is **invalid as published** and is repaired on write.

⚠ **That proves agreement with the council's description today; it does not date the map, and
nothing available here can.** Recorded as a limitation, not dressed up.

### Gates, each watched failing first

| Control | Planted defect | What fired |
| --- | --- | --- |
| 1 | occupancy applied without the structure | `expected 14 city offices, got 0` |
| 2 | one of the four council polygons deleted | `expected 4 X0059 council-district boundaries, found 3` |
| 3 | an at-large office **moved** onto Richland County `45079` | `1 county/legislative district(s) picked up a city office` |
| 4 | Render dated from his 2004 first arrival | `Render is not seated from 2026-01-13` |
| 5 | Lowder dated from the 2026 swearing-in | `Lowder is not seated from January 2010` |
| 6 | a second holder on one at-large office | `office_terms_no_overlap` — **the database's own exclusion constraint, not the gate** |

🔴 **Control 3 first aborted for the WRONG REASON.** It began by *inserting* an extra office, and
the per-city count gate caught that first — the defect was caught, but not by the gate under test.
Moving an existing office instead keeps both counts at 7, so only the collision gate can fire.
🟢 **Control 6 is recorded as it happened**: the gate is never reached, because `office_terms`
refuses the overlapping row itself. That is the stronger answer, and it is left standing rather than
engineered around.

The loader's own three gates were watched failing too — a tampered feature count (`expected 5, got
4`) and the coverage gate pointed at the wrong city's polygon (`0.000% of Columbia`). ⚠ Its overlap
gate first reported **4 overlapping pairs where there are none** — a bad `RIGHT JOIN` counting rows
rather than pairs. A gate that fires on a healthy layer is as broken as one that never fires.

Both migrations were dry-run against production as **one transaction ending in ROLLBACK**, and the
rollback was confirmed to have reverted. Both are idempotent, proved by re-running; the boundary
loader too (`inserted 0`).

### ✅ End to end, on live production

| Address | City-level answers |
| --- | --- |
| Columbia City Hall | **4** — Mayor Rickenmann, **District 2 McDowell**, and both at-large (Bailey, Johnson) |
| Myrtle Beach City Hall | **7** — Mayor Kruea and all six at-large members |
| Charleston City Hall *(negative control)* | **0** city-level answers |

Columbia City Hall resolving to **District 2** matches the council page's own assignment of the
downtown neighbourhoods. **Per-district control: 4/4 polygons return exactly one office and exactly
one holder.** `check:reachability` nothing regressed, two buckets below baseline;
`check:occupancy`, `check:migrations` and `check:reservations` green.

▶ **Next: stage 4 — Richland and Horry county councils**, plus each county's separately elected
officers. The state's own `County_Council_Districts` layer is already located.
