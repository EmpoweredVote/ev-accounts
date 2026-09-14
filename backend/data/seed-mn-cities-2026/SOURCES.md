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

## ▶ Still owed

1. Boundary loader runs for both cities (`X` slots), with a migration pre-flight that fails hard if
   the polygons are absent.
2. Structure and occupancy migrations — slots to be reserved from the allocator.
3. An address probe per city with a per-district control. Both city halls already have geocoded
   points in [`../seed-mn-2026/anchors-L2022.json`](../seed-mn-2026/anchors-L2022.json).
