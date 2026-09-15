# MN-3 sources — Duluth and Saint Paul city councils

Wave: Knight slice 5, stage 3. Opened **2026-09-14**. Leases `place:2717000` and `place:2758000`
held by chris@empowered.vote on DESKTOP-G6KDNN2. Slice notes:
[`.planning/knight-foundation/mn.md`](../../../.planning/knight-foundation/mn.md).

**Status: boundary sources validated, office lists read from both charters, and the
**change-check is done** — all 18 members, each with a dated term start. Migrations NOT yet
written.**

---

## Baseline, measured against production 2026-09-14

| | Duluth | Saint Paul |
| --- | --- | --- |
| `governments` row | **none** | **none** |
| `districts` rows | **none** | **none** |
| `offices` / people | **none** | **none** |
| `geofence_boundaries` place polygon | ✅ `2717000`, 80.168 sq mi | ✅ `2758000`, 56.104 sq mi |

Both place polygons were loaded by MN-1 (`census_tiger_2024`, `G4110`). Every MN local politician
count in production is **0**, so both cities are a clean seed with nothing to repair.

### 🔴🔴 THE SAINT PAUL IN PRODUCTION IS IN TEXAS, AND IT IS STILL THE ONLY ONE

`essentials.governments` holds exactly one row matching `%Saint Paul%`:
**`City of Saint Paul, Texas, US`**, `geo_id` `4864220`, state TX. Re-measured today, still true.
**Match the government by TIGER place `geo_id` `2758000`, never by name.** TIGER also calls the
Minnesota city `St. Paul`, and `%St. Paul%` matches five Minnesota cities.

---

## What each city actually elects — read from the charter, not assumed

### Duluth — **10 elected offices**: Mayor + 5 district councilors + 4 at-large councilors

Duluth City Charter, **Chapter II "ELECTIVE OFFICERS"**, contains only §2–§5, and §2 reads:

> "The council shall have nine members, four elected from the city at large and five from
> geographical districts. The city is hereby divided into five council districts numbered from one
> to five consecutively."
>
> "The terms of office of the mayor and councilors shall be for four years and until their
> successors are elected and qualified."

🔴 **THE CHAPTER ENDS WITHOUT NAMING ANOTHER ELECTED OFFICER.** The clerk appears in the charter
only as "secretary of the council"; the chief administrative officer is appointed by and
responsible to the mayor (§2, §3). Chapter VI §38 names the elective titles once more, and only
twice: *"except for party designation for offices of mayor and councilor."* **Duluth elects a mayor
and nine councilors and nothing else** — the Fort Wayne rule, that eleven offices is what the code
says and not what cities "usually" have.

🔴 **A DULUTH COUNCIL DISTRICT MEANS LESS THAN IT LOOKS.** §2 continues:

> "The council districts are established herein solely for the purposes of electing district
> councilors. The administration of the city shall never be divided, nor any facility ever
> provided, nor any appropriation ever made upon a council district basis."

Elections are **non-partisan** (§38).

### Saint Paul — **8 elected offices**: Mayor + 7 ward councilmembers

Saint Paul City Charter: a mayor elected at large and **seven councilmembers, each elected from a
council ward**, each for a **four-year** term. There are no at-large council seats. The charter's
trailing "and such judges and other officials as are provided by statute" refers to judicial
offices elected under **state** law, not city offices, and is not modelled here.

---

## Boundary sources

| City | Service | Layer | Features | Publisher |
| --- | --- | --- | --- | --- |
| **Duluth** | `utility.arcgis.com/usrsvcs/servers/48a6121974c84a63bc18be012b1fa10a/rest/services/VotingDistricts/VotingDistricts/MapServer` | **16 — "Districts and City Councilors"** | 5 | City of Duluth GIS Office |
| **Saint Paul** | `services1.arcgis.com/9meaaHE3uiba0zr8/arcgis/rest/services/Council_Ward_/FeatureServer` | **0 — "Council Ward"** | 7 | City of Saint Paul (`CityofSaintPaul`) |

Both layers carry the **sitting member's name** as an attribute, so each is simultaneously a
boundary source and a roster source.

### 🔴🔴 DULUTH PUBLISHES TWO COUNCIL-DISTRICT MAPS AND A COUNT CANNOT TELL THEM APART

Both return **exactly five features numbered 1–5**:

| | Service | Item modified |
| --- | --- | --- |
| OLD | `Precincts_Council_Boundaries_Duluth/MapServer/**1**` | 2021-01-08 |
| NEW | `VotingDistricts/MapServer/**16**` | 2023-03-09 |

Duluth adopted a new map at the second reading of a redistricting ordinance on **2022-03-28**, so
one of these is superseded. Four measurements settle it, and **the population attribute does not**:

1. **The field NAMES give the old one away, not the values.** The old service's precinct layer
   carries columns literally called **`POP_2010`** and **`Numb_12`**, and those populations sum to
   **86,265 — Duluth's 2010 census population exactly**. The old district layer's `Sum_POPULA`
   values total 86,918, which is close enough to Duluth's 2020 population (86,697) that a
   plausibility check on the number alone would have passed it.
2. **The two maps are structurally different, not re-digitised.** Per-district symmetric
   difference after `ST_MakeValid`: 5.08, 1.48, **8.69**, 2.01 and 5.17 sq mi. District 3 goes
   from 5.25 to 13.07 sq mi — it more than doubles.
3. 🔴 **THE OLD MAP LEAVES 8.68 SQ MI OF DULUTH IN NO DISTRICT AT ALL** — it covers **89.176%**
   of the TIGER place polygon. The new map covers **99.984%**, leaving 0.0127 sq mi. Seeding the
   old one would make roughly one Duluth address in nine return no councilor, **and nothing would
   error.**
4. The old set has **five self-overlapping district pairs** (slivers, 0.0003 sq mi); the new set
   has **none**.

The new layer also names the **current** councilors, matching the council's own web page, and is
the layer behind the city's own *"Voting Districts Duluth 2022"* web map.

⚠ **TWO LAYERS INSIDE ONE SERVICE CAN BE FROM DIFFERENT MAPS.** The old service's layer 0 holds
**35** precincts while its own layer 1 was dissolved from **43** (`Cnt_Cncl_D` sums to 43). One
service is not one vintage.

⚠ **THE LAYER NUMBER IS AGAIN NOT THE ONE YOU WOULD GUESS.** `VotingDistricts` numbers its layers
16, 0, 14, 2, 5, 3, 4, 1 — the council districts are **16**, and layer 0 is `Polling Stations`.

### 🟢 The two cities' districts have OPPOSITE shapes against their place polygon

| | Union | TIGER place | Place not covered | Outside the place |
| --- | --- | --- | --- | --- |
| Duluth (5 districts) | 91.312 sq mi | 80.168 | **0.0127** (99.984% covered) | **11.157** |
| Saint Paul (7 wards) | 56.112 sq mi | 56.104 | **0.0000** (100.000% covered) | **0.008** |

**Saint Paul's seven wards tile the city exactly.** Duluth's five districts **overhang it by 11.16
sq mi**, of which only **0.045 sq mi** touches any other incorporated place (Hermantown 0.038,
Rice Lake 0.005, Proctor 0.002) — the rest is Lake Superior, the St. Louis Bay and unincorporated
township. Full coverage is the right gate; an exact tiling is not, and neither is a union that
matches the place area.

Measured by [`compare-duluth-vintages.mjs`](./compare-duluth-vintages.mjs) and
[`measure-place-coverage.mjs`](./measure-place-coverage.mjs), both read-only (`BEGIN … ROLLBACK`).

---

## Rosters as at 2026-09-14

Each city's GIS layer and its own council page agree, name for name.

### Duluth — 9 councilors + mayor

| Seat | Member |
| --- | --- |
| Mayor | **Roger J. Reinert** (40th mayor; "his term began in January 2024") |
| District 1 | Wendy Durrwachter |
| District 2 | Diane Desotelle |
| District 3 | Roz Randorf |
| District 4 | David Clanaugh |
| District 5 | Janet Kennedy (vice president) |
| At Large | Arik Forsman |
| At Large | Jordon Johnson |
| At Large | Lynn Marie Nephew (president) |
| At Large | Terese Tomanek |

### Saint Paul — 7 councilmembers + mayor

| Seat | Member |
| --- | --- |
| Mayor | **Kaohly Her** (56th mayor) |
| Ward 1 | Anika Bowie |
| Ward 2 | Rebecca Noecker (president) |
| Ward 3 | Saura Jost |
| Ward 4 | Molly Coleman |
| Ward 5 | HwaJeong Kim |
| Ward 6 | Nelsie Yang (vice president) |
| Ward 7 | Cheniqua Johnson |

### 🟢 MN-2's stale-tab finding resolves here

The Minnesota House's own Leadership tab still lists **Kaohly Vang Her for HD-64A**. She left that
seat because she **defeated the incumbent Melvin Carter on 2025-11-04 and was sworn in as Mayor of
Saint Paul on 2026-01-02** — the city's first woman, first Asian American and first Hmong American
mayor. Meg Luger-Nikolai took 64A at the special election. One person explains both waves.

⚠ She does **not** exist in production under any spelling — checked `%kaohly%` and
`first_name LIKE 'kaohly%'`. MN-2 correctly never created her, because she had already left 64A
when its roster was built.

### 🟢 None of the 18 names collides with an active politician row

Zero exact `(first_name, last_name)` matches across all 18, so
`essentials.politician_name_duplicate_guard` blocks nothing and there is nobody to reuse. A
surname-only sweep returns 130 rows and is **noise** — 27 Johnsons alone, in 14 states.

---

---

# The change-check — done 2026-09-14

All **18** member pages fetched and read: 18/18 HTTP 200, **18/18 name the person the roster says
holds the seat**. Roster written to
[`backend/data/mn-cities-roster.json`](../mn-cities-roster.json) with a dated
`term_start` for every one of the 18 — **no seat is written open-ended**, unlike MN-2.

## 🔴🔴 THE WORD SCANNER WAS BLIND TO THE ONLY REAL DEFECT

[`sweep-member-pages.mjs`](./sweep-member-pages.mjs) looks for
*words* — resigned, vacant, appointed, sworn in, stepping down, interim — because that is what
caught Joe Schomacker in MN-2. It ran clean: **one hit across 18 pages**, and that one was a
biographical line about Nelsie Yang's first term in 2020.

**It was still blind.** Duluth's real defect is a **date in the past**:

> Terese Tomanek — **Term Expires: January 5, 2026**

read on **2026-09-14**, eight months later. Nothing on the page is *worded* as a problem. No
scanner looking for language can see it.

▶ **A CITY COUNCIL'S CHANGE-CHECK SIGNAL IS AN EXPIRED DATE, NOT A BANNER.** The state legislature
publishes a resignation notice; a city publishes a term-expiry field and lets it rot.
[`read-duluth-terms.mjs`](./read-duluth-terms.mjs) extracts it
and compares it to today.

⚠ **The scanner's six positive controls all fired** — resignation, vacancy, appointment, successor,
stepping down and interim, each planted into a copy of a real page. It was working correctly and
was still the wrong instrument. **A control proves a detector is not broken. It cannot prove the
detector is looking at the right thing.**

## 🔴 FOUR IDENTICAL EXPIRED DATES ARE A UNIFORM ANSWER, AND THEY WERE WRONG

All **four** Duluth at-large pages state the same expired date, `2026-01-05`. The distribution is
what gave it away — Duluth staggers its council, so its expiries must **not** be uniform:

| Expiry stated | Seats |
| --- | --- |
| 2026-01-05 | **4** — every at-large seat 🔴 |
| 2028-01-03 | 3 — districts 1, 3, 5 |
| 2030-01-07 | 2 — districts 2, 4 |

Settled against the election record, and the pages are **stale, not the roster**:

- **November 2023** elected **two** at-large — Arik Forsman and Lynn Marie Nephew. Terms to 2028.
- **November 2025** elected **two** at-large — Terese Tomanek (re-elected, 10,504 votes) and
  Jordon Johnson (newcomer, 8,515). Terms to 2030.

Jordon Johnson's page states an expiry that **predates his own term**. The four names are right —
the GIS layer and the council index agree — and all four dates are wrong.

## 🟢 THE DISTRICT PAGES ARE MAINTAINED, AND THEY PROVE THE TERM BOUNDARY

Every stated district expiry is a **first Monday in January**: 2028-01-03, 2030-01-07. So is
2026-01-05. The charter uses the same boundary in ch. II s 4, where an appointee serves *"until the
first Monday in January after the next municipal election, when the office shall be filled by
election for the unexpired term."* That gives Duluth a `day`-precision `term_start` — **2024-01-01**
for the 2023 winners and **2026-01-05** for the 2025 winners — derived from the city's own
published dates plus the charter's four-year term, not invented.

## 🔴 THREE SEATS TURNED OVER MID-TERM, AND EACH NEEDED READING

| Seat | What happened |
| --- | --- |
| **Duluth District 2** | Mike Mayou resigned end of June 2025 — he moved out of the district and could not find a house inside it. **Deborah DeLuca** was appointed interim by unanimous council vote. **Diane Desotelle** won the November general with **80%**. The interim holder is not modelled; this wave seats who holds the seat today. |
| **Duluth District 4** | Appeared in **both** the 2023 and 2025 election listings, which read as a contradiction until it was read: Renee Van Nett left, **Tara Swenson** won a special election to the unexpired **partial** term, and **David Clanaugh** beat Swenson in November 2025, 53% to 46%. |
| **Saint Paul Ward 4** | Council President **Mitra Jalali** announced her resignation in January 2025 citing health, effective **2025-03-08**. **Molly Coleman** won the special election of **2025-08-12** with 52.36% and was sworn in **2025-08-27**. |

⚠ **SAINT PAUL'S COUNCIL INDEX IS WRONG FOR WARD 4.** It states flatly that *"Councilmembers were
elected to a 4-year term in 2023"*. Coleman was elected in **2025**, at a special election, and
took office in August. One sentence covering seven seats is right for six of them — which is the
MN-2 lesson in a second dress.

## 🔴 A 404 BODY IS STILL A FULL PAGE, AND A SURNAME TEST PASSES ON IT

Saint Paul's ward URLs are **not uniform**: wards 1–6 are `/ward-N`, but ward 7 is
`/ward-7-cheniqua-johnson`. The guessed `/ward-7` returns **HTTP 404 with a 110 KB body** that
mentions "Johnson" twice — so the identity check passed it on a surname match. The sweep now
**checks status before content**, on the principle that a clean-looking body proves nothing about
whether the request succeeded.

⚠ A slug that embeds the member's name **breaks when the member changes**, and Saint Paul already
demonstrates it: the old ward-4 sub-pages still sit under `/ward-4-councilmember-mitra-jalali/`
six months after she left. These URLs are re-derived from the council index, never remembered.

## Term starts, all 18, all dated

| | Seats | `term_start` | Why |
| --- | --- | --- | --- |
| Duluth, elected Nov 2023 | 6 | **2024-01-01** | first Monday in January |
| Duluth, elected Nov 2025 | 4 | **2026-01-05** | first Monday in January |
| Saint Paul council, elected Nov 2023 | 6 | **2024-01-09** | sworn in at the Ordway Center |
| Saint Paul Ward 4 | 1 | **2025-08-27** | sworn in after the 2025-08-12 special |
| Saint Paul Mayor | 1 | **2026-01-02** | sworn in as 56th mayor |

**No `term_end` is written** — a future `term_end` makes a seat silently self-vacate. The stated
expiries are recorded in the roster as `page_states_term_expires` for the audit trail and are not
loaded.

## ⚠ Duluth's four at-large offices will be indistinguishable by title

The charter creates **four seats elected from the city at large** in one citywide race — they are
not numbered, and numbering them would describe a power Duluth does not have. All four offices
therefore carry the identical title `Councilor, At Large`, which is Fort Wayne's situation exactly.
The occupancy migration needs an **INTERNAL** discriminator in `description`, labelled as such, so
seating is deterministic without asserting a seat name that no ballot carries.

---

# The migrations — APPLIED 2026-09-15

| | |
| --- | --- |
| Boundaries | [`scripts/load-mn-city-council-boundaries.ts`](../../scripts/load-mn-city-council-boundaries.ts) — **X0052** (5 Duluth districts), **X0053** (7 Saint Paul wards) |
| Structure | **`CC_0109`** — 2 governments, 4 chambers, 14 districts, **18 offices** |
| Occupancy | **`CC_0110`** — **18 people, 18 dated terms, 0 vacancies** |

Both migration slots were **reserved from the allocator**. Both `X` codes were checked free in
production *and* by grepping **every** git ref, since an `X` code is not a steward slot.

## 🟢 Every term is dated, which is unusual for this program

MN-2 wrote all 200 legislative terms open-ended at `unknown` because neither chamber publishes a
date. Both cities do:

| `term_start` | Seats | Source |
| --- | --- | --- |
| 2024-01-01 | 6 | Duluth, elected Nov 2023 — first Monday in January |
| 2026-01-05 | 4 | Duluth, elected Nov 2025 — first Monday in January |
| 2024-01-09 | 6 | Saint Paul council, sworn in at the Ordway Center |
| 2025-08-27 | 1 | Saint Paul Ward 4, after the 2025-08-12 special |
| 2026-01-02 | 1 | Saint Paul Mayor, sworn in as the 56th mayor |

**No `term_end` is written.** A future `term_end` self-vacates a seat. The gate asserts **0 undated
and 0 ended** — the opposite of MN-2's, which asserted 200 undated.

## ✅ Dry run — the WHOLE chain in one transaction, and the rollback was verified

CC_0109's pre-flight refuses to run without the twelve boundaries, so the migrations cannot be
dry-run alone — and loading them for real first would be a production write. **A dry run that
requires a production write is not a dry run.** [`build-dryrun.mjs`](./build-dryrun.mjs) emits the
boundary inserts the loader would make, with the same `source` string the pre-flight inspects,
inside the same transaction that is then rolled back.

```
INSERT 0 12 (boundaries) · INSERT 0 2 (governments) · INSERT 0 4 (chambers)
INSERT 0 14 (districts)  · INSERT 0 18 (offices)
NOTICE:  MN-3 structure OK: 2 governments, 4 chambers, 12 council districts, 18 offices (Duluth at-large 4 distinct)
INSERT 0 18 (people)     · INSERT 0 18 (terms)
NOTICE:  MN-3 occupancy OK: 18 people, 18 offices, 18 seated (10 Duluth + 8 Saint Paul), 18 terms, 0 undated, 0 ended, 4 distinct at-large
ROLLBACK
```

Production was re-measured afterwards and is **untouched**: 0 X0052/X0053 boundaries, 0 city
governments, 0 people in the band — and the **Texas** Saint Paul row still intact at 1.

## 🔴 Every gate was watched failing first — sixteen of them

**The loader**, against deliberately wrong inputs
(`load-mn-city-council-boundaries.ts --control`):

| Control | Result |
| --- | --- |
| GATE 1 a district removed | refused — 4 features against 5 |
| GATE 2 a councilor renamed | refused — layer "Zzz Control" vs roster "Wendy Durrwachter" |
| GATE 2 one name on every district | refused — 1 distinct value, so it discriminates nothing |
| GATE 2 the **superseded** 2012 service | refused — its layer carries no `Councilor` field at all |
| GATE 3 the **superseded** 2012 map | refused — covers **89.176%**, leaving **8.6776 sq mi** with no councilor |
| GATE 3 the **current** map | **passes** — 99.984% |

**The migrations**, against eight planted defects ([`gate-controls.sh`](./gate-controls.sh),
[`plant-controls.py`](./plant-controls.py)):

| Control | Reported |
| --- | --- |
| no boundaries loaded — *today's production state* | `X0052 holds 0 Duluth council boundaries, expected 5` |
| boundaries from the superseded map | `it may be the superseded 2012 map` |
| one Duluth district missing | `X0052 holds 4 Duluth council boundaries, expected 5` |
| at-large ordinals not distinct | `Duluth at-large is 4 office(s) with 1 distinct description(s)` |
| Saint Paul given an at-large seat | `its charter creates none` |
| a term with no start date | `1 term(s) carry no term_start; both cities publish one` |
| a term given a `term_end` | `18 term(s) carry a term_end; a future term_end self-vacates the seat` |
| two at-large seats, one person | `Duluth at-large seats hold 3 distinct people, expected 4` |

🔴 **TWO CONTROLS PLANTED SOMETHING OTHER THAN WHAT THEY CLAIMED, AND BOTH LOOKED LIKE PASSES.**
A greedy regex deleted **three** Duluth boundary inserts instead of one, and the gate correctly
reported 2 — the gate was right and the *control* was lying. And the "two seats, one person"
control first duplicated a **person** row, so the unique index on `external_id` aborted the run
before the gate was ever reached. ▶ **A control that aborts for the wrong reason proves nothing.**
Every control now asserts what it planted before the file is written.

## ✅ Gates green

`check:migrations` (4 added vs `origin/master`, 1907 slots across 151 refs) · `check:reservations`
(all four in slots their own author reserved) · `check:occupancy` (9 files scanned).

## ▶ Still owed

1. **Run the loader, then apply `CC_0109` and `CC_0110`.**
2. An address probe per city with a per-district control — Duluth City Hall and Saint Paul City
   Hall both have geocoded points in [`../seed-mn-2026/anchors-L2022.json`](../seed-mn-2026/anchors-L2022.json).
   Expect **eight** answers at Saint Paul City Hall: ward, mayor, SD-65, HD-65B, and the federal rows.
3. `check:reachability` after the apply.

---

# ✅ MN-3 APPLIED 2026-09-15 — DULUTH AND SAINT PAUL ARE SEATED

Loader, then `CC_0109`, then `CC_0110`. All three exit 0, all gates green on the way in.

Measured from OUTSIDE the migrations, before and after:

| | Before | After |
| --- | --- | --- |
| `X0052`/`X0053` boundaries | 0 | **12** |
| City governments | 0 | **2** |
| MN `LOCAL` districts | 0 | **14** |
| City offices | 0 | **18** |
| **Seated** (`count(och.politician_id)`) | 0 | **18** |
| People in the reserved band | 0 | **18** |
| `politicians` total | 87,124 | **87,142** — +18 exactly |
| `offices_missing_terms` | 823 / 655 unflagged | **823 / 655 — unmoved** |
| Texas Saint Paul row | 1 | **1, intact** |

`offices_missing_terms` did not move at all, because all 18 new offices got a term on the same day.

## ✅ The address probe

**Duluth City Hall → 9 answers**: Council District 3 (Roz Randorf), all four at-large councilors,
Mayor Reinert, CD-8 Pete Stauber, HD-8A Pete Johnson, SD-8 Jennifer A. McEwen.

**Saint Paul City Hall → 5 answers**: Ward 2 (Rebecca Noecker), Mayor **Kaohly Her**, CD-4 Betty
McCollum, HD-65B María Isa Pérez-Vega, SD-65 Sandra L. Pappas.

🟢 The two waves now stack at one point: a Saint Paul address returns its ward, its mayor, and the
legislators MN-2 seated — and the mayor it returns is the person whose departure from HD-64A the
Minnesota House's own Leadership tab still has not noticed.

### Per-district control — green is not a claim about districts unless you count them

All **12** council districts probed at their **own** interior point: each returns exactly one
office, exactly one holder, sits inside exactly one district, and the holder is the person the
roster names. **12 of 12, 0 failures.**

| Control | Result |
| --- | --- |
| a point in Lake Superior, 20 km offshore | 0 council answers |
| Minneapolis City Hall | 0 council answers |
| twelve districts, twelve holders | 12 distinct names — the detector discriminates |
| a wrong expectation | reported as a mismatch |

## ✅ Idempotent, proved by re-running the whole chain

The loader and both migrations were run a second time: `inserted 0 boundary row(s)` twice, every
`essentials.*` write `INSERT 0 0`, both gates passing unchanged.

## ✅ Gates after the apply

`check:reachability` — **nothing regressed**, and two buckets stay below baseline (`BAD_GEOMETRY`
4 of 5, `UNREACHABLE` 37 of 38). `check:migrations`, `check:reservations`, `check:occupancy` green.

🟢 **NO MATVIEW REFRESH WAS NEEDED, AND THAT WAS CHECKED RATHER THAN ASSUMED.**
`geofence_child_county` is defined over `G4110` and does not mention any `X00` code, so the twelve
new council boundaries are not children of it. MN-1's note — G4110 is a child, G5210/G5220 are not
— extends to X0052/X0053.

## ▶ Next

Stage 4: the St. Louis and Ramsey county boards. Ramsey's `OpenData/OpenData` MapServer layer 2 is
`Commissioner Districts`, found during MN-1 and noted then for exactly this.
