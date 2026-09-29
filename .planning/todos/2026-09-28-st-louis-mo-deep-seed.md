# St. Louis, Missouri deep seed

**Created** 2026-09-28 · **Status** wave 1 (geography) APPLIED · **Author namespace** `CC_`
**Scope** (decided by Cantrell, 2026-09-28) the Missouri General Assembly, the City of St. Louis,
and St. Louis County — offices, people and dated terms, plus headshots and one city banner.
**Out of scope** compass stances; the 88 municipalities inside St. Louis County; judicial seats;
school boards.

Every number below was measured on 2026-09-28 against prod, against raw TIGER 2024, and against
the sources named. The probes were read-only. Re-verify anything you are about to act on — but do
not re-derive the findings, they cost real effort.

---

## Why this document exists

St. Louis is not one jurisdiction and the obvious plan is wrong in four places. Each fails silently.

1. **The City of St. Louis is not in St. Louis County.** It seceded in 1876. They are two separate
   governments with two separate sets of elected officials, and an address is in exactly one of them.
2. 🔴 **`St. Louis County` ALREADY EXISTS IN PROD — IN MINNESOTA.** The Duluth slice seeded
   `27137` with a 7-member County Board. Missouri's `29189` also has a **7-member** council. A
   name-based match seats Missouri officials on Minnesota seats and nothing errors.
3. **The city is a county-equivalent, so the parent polygon is already loaded.** TIGER files it as
   both place `2965000` and county `29510`. Both exist; only the county one is in prod.
4. **Missouri's General Assembly is completely absent from prod**, so no St. Louis address can
   answer with a state representative or a state senator today.

---

## Probe evidence (2026-09-28)

### 1. What prod holds for Missouri

| Item | State |
|---|---|
| US House / US Senate | 8 + 2 offices, seeded |
| Statewide executives | 5 offices (Governor, Lt. Governor, SoS, Treasurer, Attorney General) |
| **Missouri General Assembly** (163 House, 34 Senate) | 🔴 **absent** — no chamber, no district, no office |
| Springfield / Greene County | seeded — 8 council, 1 citywide exec, 13 county, 7 school |
| `St. Louis city` district (`29510`, COUNTY) | row exists, **0 offices** |
| `St. Louis County` district (`29189`, COUNTY) | row exists, **0 offices** |
| `essentials.governments` for MO | `State of Missouri`, `City of Springfield`, `Greene County`, `Springfield R-XII` |

Boundary layers present for state `29`: `G4020` 115, `G4110` **1** (Springfield only), `G5200` 8,
`G5420` 1, `G6350` 1035. 🔴 **No `sldu`, no `sldl`.**

### 2. 🔴 The homonym is already in the database

```
St. Louis County  geo_id 27137  state mn  — 3 offices + 7 commissioner districts   (Duluth slice)
St. Louis County  geo_id 29189  state mo  — 0 offices
```

Identical `label`. Both counties have a **seven-member** elected legislature — Minnesota calls them
Commissioners, Missouri calls them Council members. 🔴 **Key every insert and every gate on
`(geo_id, district_type)`, never on the label.** The structure gate must assert that nothing landed
on `27137`. This is the Davidson County failure, live.

### 3. Geography — measured from raw TIGER 2024 FIPS 29

Read directly from the `.dbf` inside each zip:

| Layer | Records | MTFCC | LSY | Pseudo-districts |
|---|---|---|---|---|
| `sldl` | **163** | G5220 ×163 | 2024 ×163 | **0** |
| `sldu` | **34** | G5210 ×34 | 2024 ×34 | **0** |
| `place` | 1082 | G4110 948 / G4210 134 | — | — |

Missouri is **single-member in both chambers**, so polygon count equals seat count. Codes run
`001`–`163` and `001`–`034` with no gaps and no duplicates. The `place` file carries 938 active and
10 inactive incorporated municipalities (`G4110`); the 134 `G4210` CDPs are statistical and are
filtered out. `St. Louis city` is place `2965000`, ALAND 159,853,177 m² (61.72 sq mi).

### 4. Vintage — 8 of 8 anchors, three independent readings

A count can never date a map, and **Missouri House districts do not nest inside Senate districts**,
so Ohio's structural proof is unavailable here. The evidence is identity anchors instead, read three
ways: point-in-polygon against the raw TIGER 2024 shapefile, the Missouri House's own address
lookup, and the Census geocoder's `2026 State Legislative Districts` layer.

| Address | TIGER 2024 | house.mo.gov lookup | Census 2026 |
|---|---|---|---|
| 1200 Market St, St. Louis (City Hall) | HD-78 / SD-5 | HD-78 Marty Murray / Steven Roberts | HD-78 / SD-5 |
| 41 S Central Ave, Clayton (County Govt Center) | HD-99 / SD-4 | HD-99 / Karla May | HD-99 / SD-4 |
| 414 E 12th St, Kansas City (City Hall) | HD-23 / SD-7 | HD-23 Michael Johnson / Patty Lewis | HD-23 / SD-7 |
| 840 Boonville Ave, Springfield (City Hall) | HD-132 / SD-30 | HD-132 Jeremy Dean / Lincoln Hough | HD-132 / SD-30 |
| 201 W Capitol Ave, Jefferson City | HD-60 / SD-6 | HD-60 Dave Griffith / Mike Bernskoetter | — |
| **CONTROL: 100 W Randolph St, Chicago** | **NO MATCH** | **no result** | — |

No polygon overlap at any anchor. The Chicago control proves the lookup can return nothing, so a
blank is a real answer rather than a broken query.

🔴 **A HAND-TYPED ANCHOR COORDINATE MANUFACTURES A FALSE DISAGREEMENT.** Kansas City City Hall
first read HD-**24** from TIGER against HD-**23** from both other sources. The cause was my own
coordinate, ~30 m off and across the district line. The geocoded point
(`-94.57832, 39.09981`) reads HD-23 in all three. **Geocode every anchor; do not type one.**

### 5. The legislature's rosters, and the vacancies

- **House** — `https://house.mo.gov/MemberGridCluster.aspx?filter=compact&year=2026&code=R`
  returns the full 163-row table to `curl`, server-rendered. Parsed: 163 rows, 163 distinct
  districts, no gaps, no duplicates. **105 R, 50 D, and 8 rows whose name is literally `Vacant`.**
- 🔴 **Eight House seats are vacant: HD-29, 95, 99, 110, 114, 149, 159, 160.** They need
  `offices.is_vacant` set, not a seated politician. The vacancy date must come from a document that
  states it — a resignation letter or the Governor's writ of special election — not from the roster's
  silence.
- **Senate** — `https://www.senate.mo.gov/senators/` renders 33 member cards. **SD-10 has no card**,
  so 33 of 34 are filled and **SD-10 is vacant**. Confirm that from the Senate's own vacancy notice
  before writing it.
- ⚠ **The House address lookup is authoritative for GEOGRAPHY and STALE for OCCUPANCY.** It returns
  **Ian Mackey** for HD-99, which the 2026 member grid reports as **Vacant**. Use the lookup to date
  the map; use the roster for who holds the seat. A source can be authoritative for one field and
  stale for another.

### 6. ⚠ A congressional finding, outside this scope

Prod holds MO congressional as plain `census_tiger_2024`, `2901`–`2908`, with no vintage tag. The
Census geocoder's `120th Congressional Districts` layer puts **414 E 12th St, Kansas City in
CD-4**. Missouri redistricted congressionally mid-decade in 2025. **This slice does not touch the
congressional layer**, but prod's map may be the superseded one. Recorded here so it is not lost;
it belongs with `2026-08-19-congressional-map-vintage-collision.md`.

---

## ✅ Wave 1 — geography, APPLIED 2026-09-28

`MO: new Set(['sldu','sldl'])` added to `backend/scripts/load-state-tiger-boundaries.ts`, with a
pre-flight block. `place` and `county` are deliberately **not** run: prod already holds all 115
Missouri county polygons, and the City of St. Louis is an independent city whose county-equivalent
polygon `29510` **is** the city's territory. Loading `place` would add a second, coextensive
`St. Louis city` row (`2965000`) for the same ground.

```
npx tsx --env-file=.env scripts/load-state-tiger-boundaries.ts --state MO --fips 29 --layers sldu,sldl
  sldu: 34 boundaries, 34 districts, 0 errors
  sldl: 163 boundaries, 163 districts, 0 errors
```

Measured after the load — `G4020` 115, `G4110` 1, `G5200` 8, **`G5210` 34**, **`G5220` 163**,
`G5420` 1, `G6350` 1035.

### 🔴 The geo_id collision is live, and the load proves it

`(geo_id, district_type)` is the key. Three different districts now share `29005`:

```
COUNTY       29005  Atchison County
STATE_LOWER  29005  State House District 5
STATE_UPPER  29005  State Senate District 5
COUNTY       29099  Jefferson County
STATE_LOWER  29099  State House District 99      <- the Clayton seat this slice needs
```

### End-to-end verification in prod (PostGIS, not the loader's own count)

| Point | House | Senate | County | legislative hits |
|---|---|---|---|---|
| St. Louis City Hall | HD-78 | SD-5 | St. Louis city | 2 |
| Clayton, County Govt Center | HD-99 | SD-4 | St. Louis County | 2 |
| Kansas City City Hall | HD-23 | SD-7 | Jackson County | 2 |
| Springfield City Hall | HD-132 | SD-30 | Greene County | 2 |
| **CONTROL: Chicago** | — | — | — | **0** |

Exactly two legislative hits per Missouri point — no overlap, no gap — and the control returns
nothing, so a blank is a real answer.

### The gate was watched failing, four ways

| Control | Result |
|---|---|
| `MO_PREFLIGHT_CONTROL=count` | `[MO MTFCC assertion] expected 33 records, got 34` |
| `MO_PREFLIGHT_CONTROL=anchor` | `[MO vintage assertion] 1 of 6 anchors disagree` |
| `MO_PREFLIGHT_CONTROL=weak` | `[MO anchor discrimination assertion] only 0 of 1 … expected at least 4` |
| **`--vintage 2020`** (no flag) | `ALL 5 discriminating anchors failed onto their 2011 value — THIS FILE IS THE SUPERSEDED 2011 PLAN` |

The last one is the load-bearing control: the counts are identical across vintages, so it tests
**only** the geometry, which is the thing in doubt.

🔴 **The gate caught a real defect on its very first run.** The anchor table was written with
zero-padded TIGER codes (`'004'`), but `ocdDistrictSuffix()` strips leading zeros, so the value
compared is `'4'`. All six anchors failed at once and the gate correctly reported *"an edited
anchor table"* rather than a wrong map. The diagnosis now names that case explicitly.

---

## Wave 2 — the General Assembly: measured, NOT written

197 offices owed: 163 House + 34 Senate, all single-member. Nothing is written yet.

### The rosters are harvested and complete

All 163 House member pages fetched 2026-09-28, **0 errors**
(`house.mo.gov/MemberDetails.aspx?district=NNN&year=2026&code=R`). Each publishes `Elected:`,
`Years Served:`, `Hometown:` and `Counties:`. The **8 pages carrying no `Elected` value are exactly
the 8 vacant seats**, which confirms the vacancy list from a second field.

### 🔴 `Elected` is not a term start and `Years Served` is not a tenure — measured, both fail

| `Elected` × `Years Served` | Count | What it means |
|---|---|---|
| 2024 × 2 | 54 | ordinary — seated at the 103rd GA |
| 2022 × 4 · 2020 × 6 · 2018 × 8 | 93 | ordinary |
| **2019 × 7 · 2021 × 6** | **4** | 🔴 **special elections** — an odd election year |
| **2018 × 9** | **2** | 🔴 odd count against an even year — McGaugh (HD-7), Knight (HD-142) |
| **2016 × 6** | **1** | 🔴🔴 **Mark Matthiesen, HD-107 — served, LEFT, returned** |
| **2024 × 6** | **1** | 🔴🔴 **John Simmons, HD-109 — 6 years served, newly elected** |

The last two are decisive. `Elected 2016` with only 6 years served, and `Elected 2024` with 6 years
served, are both gaps in service. **Neither field can be turned into a date by arithmetic**, and
`Years Served` counts years in the *chamber*, not in the *district* — a member who moved districts
after the 2022 remap carries chamber-years that overstate their occupancy of the seat they hold.

### The term-start document exists, and it states the date

`documents.house.mo.gov/billtracking/bills251/jrnpdf/jrn001.pdf` — *Journal of the House, One
Hundred Third General Assembly, First Regular Session*, whose first line reads **"FIRST DAY,
WEDNESDAY, JANUARY 8, 2025"**. Page 6 records: *"The following Representatives advanced to the bar
and subscribed to the oath of office, which was administered by the Honorable Mary R. Russell,
Chief Justice of the Supreme Court of Missouri"*, followed by every member by name.

So **2025-01-08 at day precision, sourced to a document that states it** — not computed from
Mo. Const. Art. III §20a, which the program's rules forbid. Earlier General Assemblies have their
own first-day journals; a member seated at a special election has their own oath recorded on its own
journal day, and those four must be read individually.

🟢 **The Journal disambiguates homonyms itself, by district**: `Brown 149` / `Brown 16`,
`Jones 12` / `Jones 88`, `Smith 46` / `Smith 68` / `Smith 74`, `Taylor 48` / `Taylor 84`.
⚠ And it lists **`Sharp 37` and `Sharpe 4`** — two different people whose surnames differ by one
letter. Any fuzzy or normalised name match merges them.

### 🔴 Three live cross-state homonyms, measured against prod

| Missouri member | Already in prod holding a seat in |
|---|---|
| **Chad Perkins** (HD-40) | **Maine** |
| **Michael Johnson** (HD-23, Kansas City) | **South Carolina** |
| **Mike Jones** (HD-12) | **Pennsylvania** |

No Missouri legislator exists in prod under any of these names, so every one of the three is a
different person. A name-based insert guard seats a Missourian on a Maine, South Carolina or
Pennsylvania seat and nothing errors. This is the Robert Nash failure, live again.

### Senate

33 of 34 filled; **SD-10 has no member card** and is vacant. Confirm from the Senate's own vacancy
notice before writing it. The Senate's member pages have not yet been harvested.

### Vacancies to write, not seat

House **HD-29, 95, 99, 110, 114, 149, 159, 160** and Senate **SD-10**. Nine seats. Per CLAUDE.md a
vacancy span whose start date is unknown must **not** be written — set `offices.is_vacant` and leave
the span unwritten until the resignation letter or the Governor's writ of special election gives a
date.

### ⚠ A general election falls between measurement and January

Polling is **2026-11-03**, five weeks after this was measured, and the 104th General Assembly
convenes in January 2027. Everyone seated here is correct **today** and many change then. SD-4 is
already known to change: Karla May is term-limited and Gina Mitten won the August primary. Seed
current occupancy; do not seed the winners of an election that has not happened.

---

## What is still unmeasured

Nothing below has been probed. Do not plan against guesses.

- **City of St. Louis** — ward geography (the 14 ward polygons), and term starts for all 23 seats.
- **St. Louis County** — the charter's list of elected offices, and the 7 council districts'
  geography and membership.
- Headshot sources and their licences; the banner.

### What IS established for the City of St. Louis

- **14 wards**, `Ward 01`–`Ward 14`, from the city's own representation page. Reduced from 28; the
  charter PDF on the city site still describes the 28-ward, odd/even-year stagger, so **it is not
  safe to read term cycles from that PDF.**
- **Board of Aldermen (15 seats):** President **Megan Green** (citywide), plus Ward 01 Anne
  Schweitzer · 02 Thomas Oldenburg · 03 Shane Cohn · 04 Bret Narayan · 05 Matt Devoti ·
  06 Daniela Velazquez · 07 Alisha Sonnier · 08 Jami Cox Antwi · 09 Michael Browning ·
  10 Shameem Clark Hubbard · 11 Laura Keys · 12 Sharon Tyus · 13 Pamela Boyd · 14 Rasheen Aldridge.
- **Citywide:** Mayor **Cara Spencer**, Comptroller **Donna M.C. Baringer**.
- **County-tier, because the city is a county-equivalent:** Recorder of Deeds **Michael Butler**,
  Collector of Revenue **Gregory F.X. Daly**, Circuit Attorney **Gabriel Gore**, Treasurer
  **Adam L. Layne**, License Collector **Mavis Thompson**, Public Administrator **Sean Rapp**.
- 🔴 **THE CITY'S OWN "ALL ELECTED OFFICIALS" PAGE IS INCOMPLETE.** It lists 23 people and does not
  mention **Sheriff**, **Public Administrator**, **Circuit Clerk** or **Assessor** anywhere — the
  strings appear zero times. The Public Administrator nevertheless has his own city department page
  naming Sean Rapp, and the charter's Scheme of Separation, §5, provides for the election of a
  **sheriff, coroner and public administrator for the city**. So the roster page under-reports the
  city's own elected offices. Establish the full list from the ballot, not from that page.
- The 2026 certified results confirm the method: the **August 2026 primary** carried Collector of
  Revenue, License Collector and Recorder of Deeds, and the **April 2026 municipal** election
  carried nothing but Proposition E. The Assessor is appointed in the City of St. Louis; confirm
  before excluding it.
- The city contains House districts **76, 77, 78, 79, 80, 81, 82, 84** and Senate districts **4 and
  5**, read off the 2026 primary ballot's own contest list. Verify by intersecting the polygons.

### What IS established for St. Louis County

- **7 single-member council districts.** The county's own page: *"The council shall consist of seven
  members, each of whom shall be a qualified voter and resident in their respective district."*
- **County Executive Sam Page.**
- Departments that exist: County Assessor, County Auditor, County Clerk, County Prosecutor,
  Collector of Revenue and Recorder of Deeds (the last two under Revenue). **Which of these are
  ELECTED is a charter question and is NOT yet established** — St. Louis County is a charter county
  and a charter county may appoint offices that are elected elsewhere in Missouri. Do not copy the
  City's list across.
- 🔴 **The council's seven district pages do NOT name their members.** Each carries a phone number,
  an address and an email only. The District 1 email is `rdays@stlouiscountymo.gov`. **An email
  prefix is not a name** — take the members from certified results or council journals.
- ⚠ **The county site 403s every `curl`, including with a browser UA. Playwright gets through.**
- The county charter is published only through a Yudu web reader
  (`content.yudu.com/web/44p6g/0A44qnp/StLouisCountyCharter/index.html`), not as a PDF.

---

## Coordination

- Steward claim `state:mo` taken 2026-09-28, label
  "MO slice - St. Louis city + county + General Assembly deep seed".
- Worktree `C:\ev-accounts-mo`, branch `seed/mo-stlouis`, from `origin/master` at `0f9700c3`.
- Migration slots are **allocated, never counted**: `npm run steward --prefix backend -- slot CC`.
