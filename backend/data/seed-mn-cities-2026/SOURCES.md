# MN-3 sources — Duluth and Saint Paul city councils

Wave: Knight slice 5, stage 3. Opened **2026-09-14**. Leases `place:2717000` and `place:2758000`
held by chris@empowered.vote on DESKTOP-G6KDNN2. Slice notes:
[`.planning/knight-foundation/mn.md`](../../../.planning/knight-foundation/mn.md).

**Status: boundary sources found and validated; office lists read from both charters; rosters
identified; migrations NOT yet written.**

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

## ▶ What MN-3 still owes

1. **A per-member change-check.** The roster above comes from two sources per city, but MN-2's
   finding was that a list page is not a change-check. Each of the 18 needs their own page read.
   🔴 **One lead is already open: Duluth's council was "accepting applications for the District 2
   seat" in July 2025**, so Diane Desotelle may have been **appointed** rather than elected, which
   changes `how_started`. Read it before writing the term.
2. **Term dates, per seat.** Saint Paul has real ones — the mayor from **2026-01-02** (`day`), and
   councilmembers elected in 2023 whose terms the 2024 charter amendment **extended through the
   end of 2028** when city elections moved to presidential years. Duluth's are staggered: the 2023
   election filled two at-large seats and districts 1, 3, 4 and 5; the 2025 election filled
   districts 2 and 4 and two at-large seats. Duluth's mayor is documented only to the month
   ("January 2024"), which `start_precision => 'month'` records honestly.
3. **A boundary loader run** for each city (an `X` slot), with the migrations' pre-flight failing
   hard if the polygons are absent.
4. **Structure and occupancy migrations**, two per city or two in total — slots to be reserved
   from the allocator.
5. **An address probe per city**, with a per-district control: Duluth City Hall and Saint Paul
   City Hall both already have geocoded points in
   [`../seed-mn-2026/anchors-L2022.json`](../seed-mn-2026/anchors-L2022.json).
