# PA — slice 6 (Philadelphia · State College)

Per-state notes for the Knight Foundation cities program. Siblings: [`fl.md`](./fl.md) ·
[`ga.md`](./ga.md) · [`ca.md`](./ca.md) · [`in.md`](./in.md) · [`mn.md`](./mn.md) ·
[`co.md`](./co.md) · [`nc.md`](./nc.md). Tracker: [`PROGRAM.md`](./PROGRAM.md).

**Opened 2026-09-18.** Lease `state:pa` held by chris@empowered.vote on DESKTOP-G6KDNN2.

PA needs **stage 1 and stage 2 both**, the same shape as Georgia and Minnesota. It is the largest
legislature the program will ever seat: **253 seats — 203 House + 50 Senate — more than any other
state left on the list**, and more than Minnesota (201), Georgia (236) or North Carolina (170).

---

## Baseline, measured against production 2026-09-18 (before anything was written)

Re-measure rather than trust this once any wave has applied.

### What exists

| Layer | Count | Note |
| --- | --- | --- |
| `districts` COUNTY | 67 | all 67 carry a `geo_id`. **Philadelphia `42101`** is present; **Centre `42027`**, State College's parent, is present |
| `districts` NATIONAL_LOWER | 17 | congressional |
| `districts` NATIONAL_UPPER | 1 | |
| `districts` STATE_EXEC | 4 | Governor, Lt. Governor, Attorney General, Treasurer — all four seated |
| `geofence_boundaries` G4020 | 67 | counties, imported 2026-07-10 |
| `geofence_boundaries` G5200 | 17 | congressional, imported 2026-04-02 |
| `geofence_boundaries` G6350 | 1,833 | ZCTAs — the MN trap: these ids are ZIP codes, not another state's FIPS |
| `geofence_boundaries` G4110 | 1,013 | **incorporated places — imported 2026-09-18, hours before this wave opened.** See trap 3 |
| `geofence_boundaries` G4210 | 989 | CDPs, same import |
| `geofence_boundaries` G4040 | 2,573 | county subdivisions, same import. PA is a strong-MCD state |
| `governments` "State of Pennsylvania" | **1** | ✅ not Indiana's 18 |

### What did not exist

- **No `STATE_UPPER` and no `STATE_LOWER` districts, and no `G5210`/`G5220` boundary rows.** Zero.
- **No state legislative offices and no legislative chambers.** PA held **23 offices in total**:
  17 US House, 2 US Senate, 4 statewide executives.
- **No government row for Philadelphia and none for State College.**
- **No `districts` row for either place**, though both have boundary geometry — the Columbus/Macon
  gap, and it is normal: `place` writes a boundary, never a district.

So stage 1 was a clean load and stage 2 is a clean seed. **Indiana's shape does not recur here, and
that was verified rather than assumed**: PA has exactly one government row, zero offices hanging off
a pseudo-chamber, and no discovery cohort (`data_source ILIKE '%discovery%'` returns nothing at all,
nationally).

---

## 🔴 Traps found while opening the wave

### 1. 🔴🔴 A COUNT CAN NEVER DATE A PENNSYLVANIA MAP

Pa. Const. Art. II §16 **fixes** the chambers at 203 and 50. Every plan ever drawn for this state has
exactly that shape, so "203 polygons arrived, as expected" is equally true of the 2012 map, the 2022
map and whatever is drawn in 2032. Minnesota met the weaker form of this (67/134 is also the 2012
plan's shape) and settled it on **one** renumbered district.

**PA-1 settled it on all 253.** Every TIGER 2024 polygon was tested at its own internal point against
**PennDOT's own `Pa House 2026_07` and `Pa Senatorial 2026_07` layers** (PASDA, Penn State — a
Commonwealth agency's boundary set, not a Census mirror): **203/203 and 50/50 agree, 0 differ, 0
errors.**

⚠ **And the sweep was then made to fail.** Run against the TIGER 2018 polygons — the 2012 plan — the
identical comparison differs on **44 House and 5 Senate districts**. A verifier that cannot fail has
proved nothing; MN-6 shipped one that reported "0 broken" while testing none of the rows in question.
The tool is [`backend/scripts/verify-pa-tiger-vintage.mjs`](../../backend/scripts/verify-pa-tiger-vintage.mjs)
and it carries both halves.

Three anchors move between the vintages, and all three resolve to the 2024 file:

| Anchor | 2012 plan | 2022 plan (loaded) | PennDOT |
| --- | --- | --- | --- |
| State College Municipal Building | SD-34 | **SD-25** | 25 |
| Allentown City Hall | SD-16 | **SD-14** | 14 |
| Erie City Hall | HD-2 | **HD-1** | 1 |
| Philadelphia City Hall | HD-182 / SD-1 | unchanged | 182 / 1 |
| Pittsburgh City-County Building | HD-19 / SD-42 | unchanged | 19 / 42 |
| PA State Capitol | HD-103 / SD-15 | unchanged | 103 / 15 |

### 2. 🔴🔴 THE geo_id COLLISION IS THE WORST IN THE PROGRAM, AND IT IS WITH COUNTIES

PA's legislative GEOIDs run `42001..42203` (House) and `42001..42050` (Senate). PA's 67 counties are
`42001..42133`, odd numbers only. Measured 2026-09-18:

- **all 67 county geo_ids are also a House district geo_id**,
- **25 are also a Senate district**,
- **all 50 Senate ids are also House ids**.

**`42101` is Philadelphia County AND State House District 101.** That is 142 new string collisions
from one load. NC-3 met a single instance of this (`37119` is Mecklenburg County and HD-119) and
treated it as an incident; in Pennsylvania it is the rule. **The key is `(mtfcc, geo_id)`, never
`geo_id` alone.** Congressional is unaffected — those ids are four characters (`4201..4217`).

`essentials.districts` is safe by construction here: `insertDistrictIfMissing` dedupes on
`(geo_id, district_type)`, and COUNTY / STATE_LOWER / STATE_UPPER are three different types. It is
**ad-hoc SQL that will get this wrong**, exactly as `geoIdGuard.ts` warns.

### 3. ⚠ THE PLACE LAYER ARRIVED HOURS EARLIER, FROM A DIFFERENT WAVE

`scripts/load-municipal-boundaries.sh` (PR #541, Civic Spaces, not this program) loaded PA's G4040,
G4110 and G4210 on **2026-09-18**, the same day this slice opened. Philadelphia city `4260000` and
State College borough `4273808` were therefore already present with geometry when PA-1 started.

▶ **Stage 1 here owes legislative geography only.** `place` is deliberately excluded from PA's
allowlist entry, with the reason written next to it. The general lesson is the tracker's own:
**measure the layer before loading it** — MN-1 loaded 855 places because MN genuinely had none.

### 4. ⚠ `check:child-county` IS RED, AND PA-1 DID NOT DO IT

The check reports **2,471 stale children**. That number is exactly **MI 533 + PA 1,013 + OH 925** —
the three states the municipal wave loaded today — and the check's own definition of a child is
`mtfcc IN ('G4110','G5420','G5400','G5410')`. **`G5210` and `G5220` are not children**, so this
wave's 253 rows cannot appear in it, which is why no matview refresh was needed after the legislative
load. That was checked in the check's source, not assumed from MN-1's note.

▶ The refresh belongs to the wave that caused it. It needs matview ownership, so it runs as
`postgres`, not `ev_api`.

### 5. Philadelphia is coterminous with its county, to three decimal places

`4260000` measures **142.422 sq mi** and `42101` measures **142.422 sq mi** — the place record IS the
county. So the Georgia rule applies unchanged: **key the government on the TIGER place `4260000`**,
the way Columbus (`1319000`) and Macon-Bibb (`1349008`) were keyed, and Nashville's reason for keying
on the county does not arise. State College is an ordinary borough: **4.578 sq mi** inside Centre
County (1,111.620 sq mi).

Stage 4 for Philadelphia therefore drops the county commission and **keeps the separately elected
county officers** (spec §3.2) — the row officers still have to be read off the charter, never
inherited from another consolidated city.

### 6. 🟢 PennDOT's layer carries member names and party — a third authority for stage 2

`Pa House 2026_07` exposes `H_LASTNAME`, `H_FIRSTNAM`, `HOME_COUNT`, `PARTY`, `URL`; the Senate layer
the same with `S_` prefixes. That is a **Commonwealth-maintained roster keyed to the district**, and
it is neither chamber's own roster nor Open States.

⚠ Use it as the **third authority**, not the primary. It is a GIS attribute table refreshed monthly,
so it is exactly the kind of source that can be a month stale on a resignation — and MN-2's rule
stands: **a roster list page is not a change-check; a member's own page is.**

### 7. ⚠ Two TIGER 2018 polygons do not contain their own internal point

In the 2018 file, the interior point published for House districts `021` and `133` falls inside a
neighbour (`020` and `183`). The 2024 file is clean — **253 of 253 polygons contain their own
internal point** — and the 2018 file is only ever used here as a control. Recorded so that a later
reader does not mistake it for a defect in the loader or in the point-in-polygon code.

---

# PA-1 — stage 1 APPLIED 2026-09-18. 253 boundaries, 253 districts, 0 errors.

`scripts/load-state-tiger-boundaries.ts --state PA --fips 42 --layers sldu,sldl`. No migration:
this loader writes `geofence_boundaries` and `districts` directly, the same path MN-1 used.

### What was written

| | Boundaries | Districts |
| --- | --- | --- |
| `G5210` / STATE_UPPER | 50 | 50 |
| `G5220` / STATE_LOWER | 203 | 203 |

### Measured from outside, after the apply

- `districts` total **8,724 → 8,977**, `geofence_boundaries` total **62,807 → 63,060** — both moved
  by exactly 253. Nothing else moved.
- **`offices_missing_terms` unmoved at 823 / 655 unflagged.** Stage 1 creates no office, so this is
  the number that should not move, and it did not.
- **253 distinct `ocd_id`s for 253 rows** (`…/state:pa/sldl:1` … `sldl:203`, `sldu:1` … `sldu:50`).
  The MN `08A` / MD `1A` collapse cannot occur in a state whose codes are plain digits, and the
  loader now asserts the distinct count rather than reasoning about it.
- All 253 geometries **valid**, SRID **4326**; 8 multipolygon, 245 polygon.
- **Idempotent, proved by re-running**: second run reports `Inserted 0 / Already existed 253`.

### Gates

- **Both pre-flight gates were watched failing first.** The count gate was tampered to expect 49
  Senate districts and aborted before any DB write; the OCD-ID gate was tampered to collapse the
  suffixes and aborted at 10 distinct instead of 50. Both were then restored and the real dry-run
  passed: `50 records (expected 50), 50 distinct OCD-ID suffixes` and `203 / 203`.
- **Per-district control: 50/50 and 203/203 resolve to exactly one district** by `ST_Covers` on
  `ST_PointOnSurface`, 0 failures.
- **Negative control:** a point in Columbus, Ohio matches **0** of the 253 PA polygons, and returns
  nothing from PennDOT either.
- **Six anchors probed against the rows actually in production** — Philadelphia, State College,
  Pittsburgh, Harrisburg, Erie, Allentown — all six agree with PennDOT on both chambers.
- `check:reachability` **nothing regressed, two buckets below baseline**: `BAD_GEOMETRY` 4 of 5,
  `UNREACHABLE` 37 of 38, `DEAD_GEOGRAPHY` 17 of 17.
- `check:child-county` is red for the reason in trap 4, which this wave did not cause and cannot fix
  as `ev_api`.

---

# PA-2 — stage 2 APPLIED 2026-09-18. 253 offices, 253 seated, 0 vacancies.

`CC_0119` (structure) + `CC_0120` (occupancy), both slots reserved from the allocator. Generated by
`scripts/gen-pa-legislature-migrations.mjs` from `data/pa-legislature-roster.json`, so 253 seats are
never hand-typed.

| | |
| --- | --- |
| Offices | **253** — 203 Representatives + 50 Senators, 2 chambers, one government row |
| People | **252 created** (band `-2742260 .. -2742001`) + **1 reused** |
| Terms | **253**, all open-ended; **252 at `unknown` precision, 1 at `day`** |
| Vacancies | **0** — neither chamber has one today |

### Measured from outside, after the apply

- `politicians` **87,216 → 87,468**, exactly +252.
- **253 offices, 253 seated** counting `och.politician_id` — never `count(*)`, because
  `office_current_holder` LEFT JOINs from `offices` and an unseated office is a NULL, not an absence.
- **`offices_missing_terms` unmoved at 823 / 655 unflagged.** Every office created here got a term.
- Chambers under *State of Pennsylvania*: 4 → **6** (the four statewide executives, plus the two
  created here).
- **Idempotent, proved by re-running both**: every `essentials.*` write returns `INSERT 0 0` and both
  gates stay green.
- **No PA legislator holds a second seat anywhere in the country** — checked nationally, not just
  inside Pennsylvania.

### 🔴🔴 THE ONE SEAT THAT HAD TURNED OVER WAS FOUND BY THE SOURCE THAT DISAGREED

PennDOT named **Stephenie Scialabba** for HD-12. The chambers' own list and Open States both named
**Brandon Dukes**. Reading it out: Scialabba resigned in March 2026, Dukes won the **2026-08-18
special election** and was **sworn in on 2026-09-08** — ten days before this wave ran.

▶ **His term is dated from the SWEARING-IN**, at `day` precision, `how_started = 'elected'`. Not the
election date, and not "first elected". It is the only dated term in the wave and the gate asserts
both the count and that it is HD-12's.

⚠ **PennDOT's `GIS_UPDATE` is NULL on every feature**, so the layer cannot even be asked how fresh it
is. Freshness is a property of a FIELD, and this field does not exist. Use it as the third authority
— never as the tiebreaker.

### 🔴🔴 THE (first_name, last_name) GUARD MISSED A REAL DUPLICATE, AND A SURNAME PASS CAUGHT IT

Matching the roster on the exact pair found **two** existing rows. A second pass on **surname alone**,
restricted to rows with any Pennsylvania connection, found **three more** — and one of them is the
same person:

| Seat | Roster | Existing row | Verdict |
| --- | --- | --- | --- |
| HD-200 | Christopher M. Rabb | **Chris Rabb**, candidate in the PA-3 congressional race, with a photo | **SAME PERSON — row reused** |
| HD-74 | Dan K. Williams | Dan Williams, candidate for **U.S. House, FLORIDA 11** | different person |
| HD-202 | Jared G. Solomon | Jared Solomon, **Delegate, MARYLAND district 18** | different person |
| HD-131 | Milou Mackenzie | Ryan Mackenzie | different person |
| HD-141 | Tina M. Davis | Austin Davis | different person |
| HD-185 | Regina G. Young | Marty Young | different person |
| SD-50 | Michele Brooks | Bob Brooks | different person |

**Christopher/Chris defeats a pair guard exactly the way MN-2's Steven/Steve did.** A punctuation-blind
pass over the same population found nothing further. The duplicate-name guard was lifted for **two
rows**, not for the migration: the other 250 were inserted with it armed.

⚠ **The reused row is still named `Chris Rabb` and the chamber renders him `Christopher M. Rabb`.**
The name was NOT changed — it is a voter-facing field on a row already displayed as a candidate, and a
rename is its own decision. Recorded here rather than done quietly.

### Gates, each watched failing first

| Control | Planted defect | Gate that fired |
| --- | --- | --- |
| 1 | occupancy applied without the structure | `expected 253 Pennsylvania legislative offices, got 0` |
| 2 | `pa_terms` emptied before the insert | `expected 253 terms, got 0` |
| 3 | a `Representative` office planted on **Philadelphia COUNTY** | `1 COUNTY district(s) picked up a legislative office — a geo_id-only join` |
| 4 | HD-1's member also seated in HD-2 | `1 person(s) hold more than one Pennsylvania legislative seat` |
| 5 | HD-12's date removed | `expected 1 dated term(s), got 0` |

⚠ **Control 2 first aborted for the WRONG REASON** — a `sed` edit produced a SQL syntax error, and the
gate was never reached. A control that aborts for the wrong reason proves nothing (MN-3's rule). It was
rebuilt to change exactly one line, `DELETE FROM pa_terms;`, and the `INSERT 0 0` in the log is the
evidence the plant took.

Both migrations were dry-run as **ONE transaction ending in ROLLBACK**, and **the rollback was
confirmed to have reverted**: 0 PA legislative offices, 0 people in the band, `offices_missing_terms`
unchanged, before anything was applied.

### ✅ End to end, on live production

`GET /api/essentials/address-search` after the apply:

| Address | State House | State Senate |
| --- | --- | --- |
| Philadelphia City Hall | **Ben Waxman**, HD-182 | **Nikil Saval**, SD-1 |
| State College Municipal Building | **Scott Conklin**, HD-77 | **Cris Dush**, SD-25 |
| Cranberry Township | **Brandon Dukes**, HD-12 | Elder A. Vogel, SD-47 |
| Columbus, Ohio *(negative control)* | none | none |

SD-25 is the seat that **dates the map** — under the 2012 plan State College was SD-34 — so the
end-to-end answer confirms PA-1's vintage proof from the voter's side.

**Per-district control: 50/50 and 203/203 polygons return exactly one office and exactly one
holder**, 0 failures. `check:reachability` nothing regressed, two buckets below baseline;
`check:occupancy` and `check:migrations` green.

### The change-check, and what it could and could not see

All **253 member pages** were read. Every one **names the member the list assigned to that district**
— 203/203 and 50/50, 0 errors. The identity check was proved able to fail on the exact seat that had
turned over: Dukes' page names Dukes and does **not** name Scialabba.

Departure-word scanning returned **two** hits, both read and cleared: Senator Boscola's *"vacant steel
land"* and Senator Argall's *"vacant junior high school"*. ⚠ MN-3's harder lesson still stands — a word
scanner cannot see an expiry date it was never told to look for. Here there is nothing to look for:
**neither chamber publishes term dates at all**, which is also why 252 terms are `unknown`.

---

## ▶ Next: stage 3 — Philadelphia and State College

### What stage 2 was told to watch for, before it ran

(Kept as written. Every item below was met or measured.)

What is already known, and what must still be established:

1. **The roster.** Two independent sources, as always — the chambers' own member pages
   (`legis.state.pa.us`) are primary; PennDOT's layer (trap 6) and Open States are cross-checks.
   Open States is a **detector, not an oracle**.
2. **Vacancies are found on the member's own page, not on the roster index.** MN-2 paid for this:
   a chamber listed a member three months after he resigned, and neither chamber published a vacancy
   marker anywhere else. PA holds special elections for legislative vacancies, so the seat may be
   filled mid-term and the term start is the **swearing-in**, not the election.
3. **"First elected" is not a term start** — it fails in both directions, and the body's own
   term-by-term record is what settles it.
4. **Name collisions must be checked against active rows before any insert**, keying on the
   `full_name`/`first_name` PAIR from ONE source. MN-2 found five, three of them different people.
5. **HTML entities.** MN-2 found eight encoded names; a raw capture writes mojibake into a
   voter-facing field.
6. Migration slots are **allocated, never counted**: `npm run steward --prefix backend -- slot CC`.
