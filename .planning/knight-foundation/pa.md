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

# PA-3 — stage 3 APPLIED 2026-09-18. 26 offices, 26 seated, 0 vacancies.

`X0058` (10 council-district polygons), `CC_0121` structure, `CC_0122` occupancy.

| | Philadelphia | State College |
| --- | --- | --- |
| Government | `City of Philadelphia, Pennsylvania, US`, keyed on TIGER place **4260000** | `Borough of State College, Pennsylvania, US`, place **4273808** |
| Chambers | Philadelphia City Council (17) · Office of the Mayor | State College Borough Council (7) · Office of the Mayor |
| Offices | **18** — Mayor + 10 district + **7 unnumbered at-large** | **8** — Mayor + **7 at-large**, no ward layer |
| Districts | 10 on `X0058` + 1 citywide `G4110` | 1 citywide `G4110` |

**The two are not made uniform.** Philadelphia's ten districts tile the city (142.434 sq mi of
district against a 142.422 sq mi place, 99.968% covered); State College's charter says plainly
*"there is a seven-member Council, elected at large"*, so **no ward layer exists and none was
invented** — the Tallahassee and Boulder shape.

▶ **Philadelphia's row officers are NOT in this wave.** District Attorney, City Controller,
Sheriff, Register of Wills and the three City Commissioners are the county officers a consolidated
city keeps, and they belong to stage 4. Its elected **judges** belong to the judges wave, as North
Carolina's do.

### Measured from outside, after the apply

- `politicians` **87,468 → 87,494**, exactly +26. All 26 new; no reuse was available.
- **26 offices, 26 seated** counting `och.politician_id`. **`offices_missing_terms` unmoved at
  823 / 655.**
- **Idempotent**: re-running both writes `INSERT 0 0` to every `essentials.*` table.
- **Per-district control: 10 of 10** council polygons return exactly one district office and
  exactly one holder; the citywide district carries exactly 8 (Mayor + 7 at-large), all seated.

### 🔴🔴 FIVE COUNCIL-DISTRICT LAYERS, TEN FEATURES EACH, AND A CITY-WIDE PROBE CANNOT SEPARATE THEM

Philadelphia publishes `Council_Districts_1990`, `_2000`, `_2016`, `_2024` and
`council_districts_2024_2`. **Every one has ten features numbered 1-10.** Duluth's trap, one city
larger.

The first attempt to settle it probed the **54 Free Library branches** — the city publishes their
addresses *and* their coordinates — against the city's own address service. All 54 agreed with the
2024 layer. ⚠ **And all 54 agreed with the superseded 2016 layer too**, though **0 of 10** districts
are byte-identical between the two plans. The maps differ; they do not differ where a library sits.

What settles it is the population the 2022 remap actually moved. The city's address service returns
**both** `council_district_2016` and `council_district_2024` for any address, so the changed rows can
be *found* rather than guessed: sampling the city's own 954,000-row address-point layer, **6 of 150**
probes changed district, and on exactly those the loaded layer scores **6/6** and the 2016 layer
**0/6**. `scripts/verify-phl-council-districts.mjs` carries the whole test, and **fails** if the
changed set is empty.

⚠ `council_districts_2024_2` is a copy — identical feature count and identical total area. Not
loaded, and not evidence.

### 🔴🔴 THE ROSTER PAGE PUBLISHES THE PAST IN THE SAME FORMAT AS THE PRESENT

`phlcouncil.com/council-members/` carries a **`Past Council Members`** section rendering former
members exactly like sitting ones: `Councilmember Jannie Blackwell | District 3` (left 2020),
`Council President Darrell L. Clarke | District 5` (left 2024), and seven former at-large members
including Helen Gym. A sweep of the whole page reads **14 district members and 0 at-large**, and
nothing about those rows looks wrong.

▶ The archive heading is **load-bearing**: the parser cuts at it and **throws** if it is ever
missing, rather than guessing where the past begins. The self-test plants a past member and requires
it to be excluded.

### 🔴 THREE DETECTORS WERE BROKEN AND EACH WAS CAUGHT BY ITS OWN COUNT

1. **16 of 17 members change-checked.** The member-page matcher dropped `Brian J. O'Neill`, whose
   page is `/brianoneill/`: it treated every one-letter token as an initial, and the particle in
   `O'Neill` is one letter once the apostrophe is stripped. **An initial is a token written `J.`,
   not merely a short one.** An unmatched member is now a finding, not a silent skip.
2. **Departure language fired on 17 of 17 pages** — every one on the same words, because the site
   navigation carries `Vacant Property Review Committee`. **A uniform answer is a broken detector.**
   With that one committee excluded by name the count falls to **4**, all read and cleared, and two
   of them turned out to be the arrival evidence used below.
3. **The borough parser was off by one.** State College writes `Members Ezra Nanes , Mayor Evan
   Myers, Council President …` — each person's title *follows* them — so a naive split produced the
   mayor `Members Ezra Nanes` and the council president `Mayor Evan Myers`. Two voter-facing names
   with a heading welded to the front, both of which would have looked like ordinary data. The
   self-test now pins the exact strings.

### 🔴 THE BOROUGH PUBLISHES NO PER-MEMBER PAGE, SO THE CHANGE-CHECK HAD TO BE A DIFFERENT INSTRUMENT

MN-2's rule is that a roster list page is not a change-check; the member's own page is. **State
College has no member pages at all** — the run reports `0/0 tested` and says so loudly, because a
0/0 is not a pass. What was used instead:

- **Centre County's certified 2025 municipal result** — the only election since: the three seats up
  were won by the three sitting incumbents (Balachandran, Hayes, Krishnankutty), unopposed.
- **A targeted search for a mid-term change**, which found one: 🔴 **Josh Portney resigned in
  January 2026** and council **appointed Susan Venegoni on Monday 2026-02-09** to serve the
  remainder of his term to 2027-12-31. She is on the roster page with nothing to mark her as an
  appointee. ▶ **The roster page was right and silent; the change was only visible from outside.**

### Terms: four documented arrivals, twenty-two honest blanks

| Person | Start | Precision | How | Why |
| --- | --- | --- | --- | --- |
| Cherelle L. Parker | 2024-01-01 | day | elected | took the oath privately on Monday 2024-01-01; the public inauguration on 01-02 is a ceremony |
| Michael Driscoll | 2022-06-10 | day | elected | his own page: *"was sworn in as a member of Philadelphia City Council on June 10, 2022"* after a May 2022 special |
| Anthony Phillips | 2022-01-01 | year | elected | a 2022 special to complete Parker's term; the page gives the year and no date |
| Susan Venegoni | 2026-02-01 | month | appointed | appointed 2026-02-09; her oath is reported only as *"as early as Tuesday"*, so the day is not known |

**The other 22 are open-ended at `unknown`.** Writing 2024-01-01 for everyone elected in 2023 would
be positively wrong for the incumbents among them, whose occupancy is continuous from an earlier
swearing-in, and for the two who arrived at 2022 specials. ▶ **Owed, if it is ever wanted:** a day
for Venegoni from the borough's minutes, and per-member oath dates from each body's own record.

### Gates, each watched failing first

| Control | Planted defect | Gate that fired |
| --- | --- | --- |
| 1 | the `X0058` polygons deleted | `expected 10 X0058 council-district boundaries, found 0` |
| 2 | a district's **polygon** deleted, the district kept | `1 office(s) sit on a district with no polygon` |
| 3 | one district seat retitled at-large, total still 18 | `expected 7 Philadelphia at-large offices` |
| 4 | `pa3_terms` emptied | `expected 26 terms, got 0` |
| 5 | one person seated in two seats | `1 person(s) hold two city seats` |

⚠ **Controls 2 and 3 first fired on the WRONG GATE** — adding an office tripped the district-count
and office-count gates before reaching the gate under test. They were rebuilt to hold every earlier
count constant, so each now proves the gate it names. The boundary loader's three gates were watched
failing the same way, including GATE 2 fed the 2016 map and refusing it.

### ✅ End to end, on live production

| Address | Answers |
| --- | --- |
| Philadelphia City Hall | Mayor **Cherelle L. Parker**, **District 5 Jeffery Young, Jr.**, and all 7 at-large |
| 6301 Ridge Ave | **District 4 Curtis Jones, Jr.** — a different district from the same city |
| State College Municipal Building | Mayor **Ezra Nanes** and all 7 council members |
| Columbus, Ohio *(negative control)* | no Pennsylvania city seat at all |

`check:reachability` **nothing regressed**, two buckets below baseline.

---

# PA-4 — stage 4 APPLIED 2026-09-18. 20 offices, 20 seated, 0 vacancies.

`CC_0123` structure, `CC_0124` occupancy. **No boundary load and no new district** — both countywide
polygons were already in production.

| | Philadelphia | Centre County |
| --- | --- | --- |
| Government | the **existing city row** — city and county are one | **new**: `Centre County, Pennsylvania, US`, `42027` |
| Chambers | +1 `City and County Elected Officials` | `Board of County Commissioners` + `County Elected Officials` |
| Offices | **7 row offices** | **13** — 3 commissioners + 10 officers |
| District | countywide `42101` / G4020 | countywide `42027` / G4020 |

### 🔴 NEITHER HALF MATCHES A TEMPLATE, AND THEY DO NOT MATCH EACH OTHER

**Philadelphia has no county commission, because the City Council is it.** What a consolidated city
keeps is the separately elected row offices: **District Attorney** (Larry Krasner), **City
Controller** (Christy Brady), **Sheriff** (Rochelle Bilal), **Register of Wills** (John P. Sabatina)
and **three City Commissioners** (Omar Sabir, Lisa M. Deeley, Seth Bluestein). They hang on the same
government row PA-3 created — Columbus and Macon-Bibb again, and no second government is invented
for a county that is the city.

**Centre County is an ordinary county and still matches no template**, which is MN-4's rule proved a
third time. Read off the county's own index:

- a **Controller**, not three Auditors — Pennsylvania counties elect one or the other;
- a combined **Prothonotary and Clerk of Courts**, and a combined **Register of Wills and Clerk of
  the Orphans' Court** — two offices where a template would write four;
- 🔴 **TWO JURY COMMISSIONERS.** Act 2013-11 let Pennsylvania counties abolish the office and many
  did. **Centre did not**, and nothing but the county's own page would have said so. The post-verify
  gate asserts the count, so a later "tidy" against a state-wide assumption fails loudly.

### 🔴 ELECTED JUDGES ARE IN SCOPE AND ARE STILL NOT HERE

Centre County's page also lists Court of Common Pleas judges and **six Magisterial District Judges**;
Philadelphia elects its judiciary too. Under the NC-3 inclusion ruling they belong in the data.
Deferring them to the **judges wave** that North Carolina already owes is a scheduling decision,
recorded — not a ruling that they do not count.

### Measured from outside, after the apply

- `politicians` **87,494 → 87,514**, exactly +20. Pennsylvania offices **283 → 303**.
- **20 seated** counting `och.politician_id`. `offices_missing_terms` **unmoved at 823 / 655**.
- **Pennsylvania still has exactly 67 county districts** — the gate asserts it, because this wave
  should create none.
- **Idempotent**: re-running writes `INSERT 0 0` to every `essentials.*` table.

Pennsylvania now stands at four governments:

| Government | Chambers | Offices | Seated |
| --- | --- | --- | --- |
| State of Pennsylvania | 6 | 257 | 257 |
| City of Philadelphia | 3 | 25 | 25 |
| Centre County | 2 | 13 | 13 |
| Borough of State College | 2 | 8 | 8 |

### 🟢 THE DUPLICATE-NAME GUARD STAYED ARMED FOR ALL 20, AND THAT WAS MEASURED

The exact `(first_name, last_name)` pair matched **nothing**. The surname-only pass over every
production row with a Pennsylvania connection returned four — Hope P. Miller against **Brett R.
Miller** and **Nick Miller**, Shelley Thompson against **Glenn Thompson**, Joseph L. Davidson against
**Nathan Davidson** — and all four are different people. Unlike PA-2 and PA-3, nothing needed the
guard lifted. ▶ The pass is still worth running when it finds nothing: that *is* the result.

### Terms

**All 20 are open-ended at `unknown`.** Neither publisher gives an arrival date: the Centre County
index is a list of names, and the Philadelphia row offices publish biographies with no swearing-in
date — both were searched before this was written, not assumed. ▶ Owed if wanted: the terms are four
years and each county's election record would date them.

### Gates, each watched failing first

| Control | Planted defect | Gate that fired |
| --- | --- | --- |
| 1 | one Jury Commissioner retitled, officer total held at 10 | `expected 2 Centre County jury commissioners` |
| 2 | a 68th Pennsylvania county district inserted | `Pennsylvania should still have 67 county districts` |
| 3 | `pa4_terms` emptied | `expected 20 terms, got 0` |
| 4 | two terms pointed at one person | `1 person(s) hold more than one seat` |

⚠ **Control 1 first aborted for the wrong reason**: it picked its victim with `min(o2.id)`, and
`min()` has no `uuid` overload, so the run died before reaching any gate. Rewritten as
`ORDER BY o2.id LIMIT 1`.

🔴🔴 **AND THEN THREE CONTROLS "TERMINATED" AGAINST A DATABASE THEY NEVER REACHED.** The shell's
working directory resets between commands, so a later `. ./.env` ran in a directory with no `.env`,
`DATABASE_URL` silently became empty, and `psql` sat waiting on a local server that does not exist
until the timeout killed it. **A timeout looks exactly like a slow query, and an empty connection
string looks exactly like a hung database** — the tell was that `echo "${DATABASE_URL:+yes}"`
printed nothing. All three were re-run from the right directory and fired correctly. ▶ **Source the
environment in the same command that uses it.**

### ✅ End to end, on live production

| Address | Answers |
| --- | --- |
| Philadelphia City Hall | all **7 row officers** — 3 City Commissioners, Sheriff, Register of Wills, City Controller, District Attorney |
| State College Municipal Building | all **13 Centre County** offices, including both Jury Commissioners |
| Bellefonte — in Centre County, outside the borough | the **13 county offices and no borough council seat**, which is the correct shrink |
| Pittsburgh — neither county | **none of either** |

⚠ A first read of that Bellefonte row said it also returned a Philadelphia office. It did not: the
**test's own regex** matched `Register of Wills` inside Centre County's *"Register of Wills and Clerk
of the Orphans' Court"*. The exact-title count is 0. A substring match across two jurisdictions
invents a leak that is not there — the `bail`/`BAILEY` trap wearing a different hat.

`check:reachability` **nothing regressed**, two buckets below baseline.

---

# ▶ RESUME PA-5 HERE (written 2026-09-18, before clearing context)

Stages 1-4 are applied, merged and verified. **Stage 5 is open and nothing has been written to
production for it.** No image has been imported, no banner registered.

## The licence position — settled, do not re-litigate

Measured before any image was fetched, and ruled on by Cantrell 2026-09-18: **the refusal applies
where it is published.**

| Publisher | Seats | Position |
| --- | --- | --- |
| `palegis.us` (House + Senate) | **253** | **No use policy.** The only copyright page is a DMCA complaint procedure. The FL/GA/CO position — ship. |
| `phlcouncil.com` | 17 | no terms — ship |
| `phillysheriff.com` | 1 | no site terms — ship |
| `centrecountypa.gov` · `statecollegepa.us` | 21 | bare "All rights reserved" — ship |
| `phila.gov`, `phillyda.org`, `vote.phila.gov`, `controller.phila.gov` | **7** | 🔴 *"any modification whatsoever … strictly prohibited without the prior written permission of the City"* — **licence debt, request owed** |

The seven are Mayor, Register of Wills, District Attorney, City Controller and three City
Commissioners. MN-5's route applies: record the debt, send the request, ship the rest.

## PA-5a — the legislature. Candidate list BUILT, nothing imported.

`py scripts/build-pa-legislature-candidates.py` → `.tmp-pa-candidates.json` (untracked, rebuildable
in ~6 minutes).

- **252 of 253 have a candidate.** The gap is **Brandon Dukes (HD-12)** — sworn in 2026-09-08, and
  the chamber has not generated his `/300/` or `/original/` buckets yet. HTTP 404 on both. A dated,
  re-checkable blank; his 200×280 list card would need a 3× upscale and this pipeline refuses that.
- **Identity proved, not assumed**: every `/original/` compared against the member's own `/300/` as
  a downscaled mean absolute difference. **Median 1.96, worst 13.17 (Doug Mastriano)**, reject
  threshold 18. The five widest pairs — Mastriano, Catherine I Wallen, Jason Ortitay, Ann Flood,
  Marla Brown — are the only places a mis-keyed bucket could hide and should be eyeballed on the
  sheet.

### 🟢 THE ORIGINAL IS 7.5× LARGER THAN ANYTHING THE SITE LINKS

`/resources/images/members/200/<id>.jpg` is what the list serves (200×280), `/300/` is what the
member's own page serves (420 tall), and **`/original/` returns 1500×2100 and is linked from
nowhere**. Probing bucket names found it. The production crop is 600×750: the linked file needs a
3× upscale, the original a 0.4× downscale. ▶ **Probe for an unlinked original in every slice.**

### 🔴 A PORTRAIT SERVED AS `.jpg`, WITH `content-type: image/jpeg`, THAT IS A PNG

Senator **Michele Brooks'** original is 2.4 MB of PNG bytes at a `.jpg` path. The magic-number check
was right about the bytes and wrong about the decision — it threw a good portrait away. Both formats
are accepted now, written as `bytes([0x89, 0x50, 0x4E, 0x47])` rather than an escape sequence,
because two patch attempts mangled the escaped form. **The magic number is the truth; what you do
about it is accept the format you found.**

## ✅ PA-5a APPLIED 2026-09-19 — THE GENERAL ASSEMBLY HAS PORTRAITS, 252 OF 253

**Cantrell approved the whole sheet, 2026-09-19**, against the proof sheet published at
`https://claude.ai/code/artifact/e8bac4c3-0c22-456b-a849-e81eeb80d220` — 252 frames, each the real
600x750 production crop. **No frame was excluded.** The 35 amber-ringed frames (source too small to
reach 600x750 without enlargement) were approved as rendered.

**Imported the same day, against live production:**

```
py scripts/import-headshot-candidates.py --json .tmp-pa-candidates.json --dry-run
imported 251 · skipped 1 · failed 0          # re-run before the write, and it reproduced exactly

py scripts/import-headshot-candidates.py --json .tmp-pa-candidates.json
imported 251 · skipped 1 · failed 0
```

That accounts for all 253 seats: **251 imported**, **1 skipped** because Chris Rabb already carried
an image row — he is the politician PA-2 REUSED rather than duplicated, and his row already pointed
at our own CDN — and **1 with no candidate**, Brandon Dukes. Sources ran from 1029x1500 to
3694x5541; every one downscaled.

Measured in the database afterwards, over the 253 candidate ids: **252 carry `photo_custom_url`,
all 252 on our CDN, 252 carry a `type='default'` image row.** The single outlier is Brandon Dukes,
who has neither — the documented, dated blank.

### Verified from outside, with the count asserted

`scripts/verify-imported-headshots.py` was written for this and is wave-scoped on purpose. It
resolves each candidate id against the read path the browser actually gets
(`COALESCE(photo_custom_url, photo_origin_url)`), re-fetches the bytes from the CDN and **fully
decodes** them — `Image.load()`, not `open()`, because a clean HTTP 200 can carry a truncated body
that only a full decode catches.

```
control (bogus CDN key): failed as required -- HTTP 400

tested 252 rows -- decoded 252, broken 0
sizes: 600x750 x217, 548x685 x15, 428x535 x5, 500x625 x4, 511x639 x2, 225x281 x2,
       375x469 x2, 200x250 x1, 357x446 x1, 547x684 x1, 429x536 x1, 556x695 x1
no photo at all (1): Brandon Dukes

count check: tested 252 == expected 252
```

**217 at the full 600x750 and 35 at native cropped size — and 35 is exactly the amber-ringed count
the operator approved.** The two numbers were derived independently, which is why they are worth
printing together.

🔴 **`--expect` IS THE POINT OF THAT SCRIPT, NOT AN EXTRA.** MN-6 shipped a verifier that
printed *108 rows, 0 broken, control failed as required* while testing **none** of the 133 rows just
written. A control proves a verifier CAN fail; it never proves the verifier read the right rows.
**The count is the tell.** The guard was watched firing before it was trusted — a 3-row subset
against `--expect 252` exits 3 and says so.

⚠ `.tmp-pa-candidates.json` is untracked and rebuildable in ~6 minutes with
`py scripts/build-pa-legislature-candidates.py`. It is still on disk in `C:/ev-accounts-pa/backend`,
alongside the `.tmp-headshot-cache` the sheet and the import shared.

🟢 **THE .env DOES NOT TRAVEL WITH A WORKTREE.** The import died on `KeyError: 'DATABASE_URL'`
before it wrote anything: `load_dotenv()` reads `backend/.env`, and a `git worktree add` copies no
untracked file. Copy it in before the first run — and read that error as what it is, a missing
file, not a bad credential.

## Next steps, in order

1. ~~Render and publish the contact sheet.~~ **Done 2026-09-19, approved whole.**
2. ~~Import.~~ **Done 2026-09-19: 251 written, 252 of 253 now renderable.**
3. ~~Verify from outside.~~ **Done: 252 decoded, 0 broken, count asserted, control failed first.**
4. **The four remaining debts**, which are four different problems and should not be summed:
   - 7 Philadelphia seats — **licence**; the request is **drafted** at
     [`backend/data/seed-pa-headshots-2026/PHILADELPHIA-PERMISSION-REQUEST.md`](../../backend/data/seed-pa-headshots-2026/PHILADELPHIA-PERMISSION-REQUEST.md)
     and is **not sent**. It names the seven holders, quotes the clause re-read live on 2026-09-19,
     and routes to the City Law Department (1515 Arch St., 17th Floor — the office that would give
     "the prior written permission of the City"). ⚠ **No email address is recorded, because none
     was verified** — confirm it by telephone before sending. `controller.phila.gov` repeats the
     clause verbatim and `phillyda.org` / `vote.phila.gov` link the same page, so **one grant covers
     all seven.**
   - 13 Centre County — **no portrait published at all** on the elected-officials index.
   - 8 State College — **no portrait published**.
   - 17 Philadelphia Council — **no systematic headshot**; member pages carry event photos
     (the one checked was a 600×448 landscape from 2017). Boulder's lesson applies: check whether
     the asset exists somewhere the card does not link before calling it missing.
   ⚠ **And one seat that is neither a debt nor done**: the **Philadelphia Sheriff**, whose site
   `phillysheriff.com` publishes no terms and was ruled shippable. It was not in the PA-5a candidate
   list, which covered the legislature only. It is one portrait, and it is owed.
5. **PA-5b, the banners** — ✅ **SHIPPED 2026-09-19. Both uploaded, registered and verified;
   essentials PR #154.** Cantrell picked both recommendations from the sheet
   <https://claude.ai/artifact/67inZT6bhztedGSkjW8ujm> (six proposals, seven refusals, every frame
   cut to the 6:1 desktop band).
   - `cities/philadelphia.jpg` — **skyline from the south-west**, Mefman00 / mods by Maps and stuff
     (Brian W. Schaller), **CC0**.
   - `cities/state-college.jpg` — **Penn State Campus toward Mount Nittany**, Goonsnick, CC BY-SA 4.0.
   - Both processed files were **pixel-identical to the certified render** (mean abs diff 0.000),
     because `certify_banner.py` imports `process_banner.py`'s crop. sha256 matched on **both** the
     plain and a cache-busted URL; a missing-key control returned HTTP 400 and did not decode. New
     keys, so no `-v2`. `banners.json`: 242 assets, 239 credited, 0 unparsed, 0 unmatched.
   - 🔴 **`upload_banner.py` WAS MISSING THE `apikey` HEADER** and would have failed with
     HTTP 400 `Invalid Compact JWS` — which reads as a bad credential, not a missing header. Fixed
     in the same PR. The rule was already in memory from 2026-09-09; the script had never caught up.
   - 🔴 **A CONTROL THAT PASSES CAN PASS FOR THE WRONG REASON, AND IT DID HERE.** The first
     `match:'exact'` test read `.src` off `getBuildingImages()`, which returns
     `{ Local, State, Federal }`. Every case came back `null`, so the two *null-expecting*
     assertions passed while the positive ones failed. **The tell was the case that should not have
     been null.** The committed tests carry a control so they can fail.
   - ✅ **`states/PA.jpg` was read in the band FIRST, and it is PITTSBURGH** — Cbaile19, CC0,
     elevated and distant, full tower crowns over pale sky with hills behind. So there is **no
     state/city subject collision for Philadelphia**, and the adjacency question is the composition
     only. Unlike `states/NC.jpg`, this banner *does* show the subject its credit names.
   - Philadelphia shortlist: **skyline from the south-west** (Mefman00 / Brian W. Schaller, **CC0**,
     5472x1824 — only 86 rows of slack, so the crop is fixed and already lands) · **City Hall from
     Broad Street** (Anntom4, CC BY-SA 4.0, vertical anchor 0.30 from a five-step sweep) · **City
     Hall façade** (Nate Lee, CC BY-SA 4.0).
   - State College shortlist: **College Avenue toward Mount Nittany** (Goonsnick, CC BY-SA 4.0) ·
     **HUB Lawn and the Nittany ridge** (JohnDziak, CC BY-SA 4.0) · **downtown rooftops**
     (Goonsnick, CC BY 4.0).
   - 🔴 **THE PEOPLE TEST DECIDED THE BEST-LOOKING PHILADELPHIA FRAME.** Chestnut Street at
     Independence Hall carries foreground figures at roughly **200 px** in the 1700x540 asset — far
     past Durham's 67 px bound, and the frame was otherwise the strongest civic composition found.
   - ⚠ **A NARROWER CROP MADE CITY HALL WORSE, NOT BETTER.** The source is 1.76:1 with 1,372 rows
     of slack, so the anchor *is* the lever here; crop widths of 3400/4000/4600 all pushed the
     building into the centre under more sky. **The `states/CA.jpg` rule is for sources NARROWER
     than 3.148:1 — do not reach for it when the slack is already large.**
   - ⚠ A keyword search for "Old Main Penn State" returned **Minnesota State Mankato's** Old Main
     at the top. The `--categories-of` method caught it. **Verify a name collision is the same
     place.**
   - On a pick: `process_banner.py` at the sheet's own numbers → `upload_banner.py` → register in
     `src/lib/buildingImages.js` with `match:'exact'` (run the matcher, do not reason about it) →
     `node scripts/gen-banners-json.mjs` and commit `public/banners.json`, which is CI-enforced.
     Both keys are **new**, so neither needs a `-v2`.
   - Work in progress lives in the essentials worktree `C:/essentials-pa`, branch
     `feat/banners-pa`, as untracked `.tmp-*` files.

## Baseline to re-measure, not trust

Pennsylvania held **4 renderable portraits of 303 seats** when stage 5 opened: the four statewide
executives, plus Chris Rabb — the row PA-2 **reused** instead of duplicating, which is exactly the
portrait a duplicate would have lost.

**After PA-5a, measured 2026-09-19 over every seat whose district is in PA**, counting a portrait
as renderable exactly the way the read path does
(`COALESCE(photo_custom_url, photo_origin_url, '') LIKE 'http%'`):

| Body | Renderable / seats |
| --- | --- |
| Pennsylvania House of Representatives | **202 / 203** |
| Pennsylvania Senate | **50 / 50** |
| U.S. House (PA districts) | 17 / 17 |
| U.S. Senate (PA) | 2 / 2 |
| Statewide executives | 4 / 4 |
| Philadelphia City Council | 0 / 17 |
| Philadelphia city and county row offices + Mayor | 0 / 8 |
| Centre County (commissioners + officers) | 0 / 13 |
| State College Borough (council + Mayor) | 0 / 8 |
| **Total** | **275 / 322** |

⚠ **The seat total moved, 303 → 322, and nothing was seated in between.** The earlier figure
counted PA offices; this one counts seats reached through
`offices → office_current_holder → districts` with `lower(d.state) = 'pa'`, which also picks up the
federal delegation. **Two different predicates, two honest numbers** — which is why the predicate
is written down beside each.

---

## ▶ What Pennsylvania still owes

1. **Stage 5, part-done.** ✅ **PA-5a is applied** — the legislature's 253 portraits, which per the
   GA-6 rule count inside stage 5 and not beside it, are 252 in. ▶ **Still owed: PA-5b (the two
   banners), the Philadelphia Sheriff's one shippable portrait, and the four debts** — 7 licence,
   13 Centre County, 8 State College, 17 Philadelphia Council.
2. **The judges wave** — Philadelphia's judiciary and Centre County's six Magisterial District
   Judges, alongside North Carolina's.
3. **Day precision** for the 42 Pennsylvania terms written at `unknown`, if it is ever wanted.

### What stage 4 was told to expect, before it ran

Philadelphia keeps its separately elected county officers even though the Council is the commission
(spec §3.2): **District Attorney, City Controller, Sheriff, Register of Wills and three City
Commissioners** — seven seats, each to be confirmed from the charter rather than inherited from
another consolidated city. Centre County, State College's parent, is a second and ordinary county
board to read from its own page. Philadelphia's elected judges remain with the **judges wave**.

### What stage 3 was told to expect, before it ran

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
