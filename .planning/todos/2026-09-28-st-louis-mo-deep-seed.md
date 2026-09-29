# St. Louis, Missouri deep seed

**Created** 2026-09-28 · **Status** waves 1 (geography), 2 (General Assembly) and 3 (City of St. Louis) APPLIED · **Author namespace** `CC_`
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

## ✅ Wave 2 — the General Assembly, APPLIED 2026-09-28

`CC_0176_mo_legislature_structure.sql` and `CC_0177_mo_legislature_incumbents.sql`, both slots
reserved from the allocator, applied back to back against production. Both post-verify gates
passed. Dry-run first (`BEGIN; … ROLLBACK;`), and the rollback was **confirmed to have reverted**
before the real apply: 0 offices, 0 people in the band, 0 chambers, Brattin back to `is_incumbent`
false, the Minnesota row intact.

### Measured in production after the apply — not read from the gates

| Check | Result |
|---|---|
| MO legislative offices | **197** (163 House + 34 Senate) |
| `office_terms` rows | **188** |
| Seated (counting `och.politician_id`, never `count(*)`) | **155 House + 33 Senate** |
| `offices.is_vacant` | **9** — House 29/95/99/110/114/149/159/160, Senate 10 |
| `offices_missing_terms` unflagged | **238** — exactly the baseline, unmoved |
| Offices of a Missouri chamber outside MO | **0** |
| Rick Brattin rows / stances | **1 / 10** — reused, `is_incumbent` now true |

### The address probe, live against production

| Point | House | Senate |
|---|---|---|
| 1200 Market St, St. Louis City Hall | HD-78 Marty Joe Murray (2025-01-08) | SD-5 Steven Roberts (2023-01-04) |
| 41 S Central Ave, Clayton | HD-99 **(VACANT)** | SD-4 Karla May (2023-01-04) |
| 414 E 12th St, Kansas City | HD-23 Michael Johnson (2023-01-04) | SD-7 Patty Lewis (2025-01-08) |
| **CONTROL: Chicago** | — | — |

🟢 HD-99 renders as a vacancy rather than a wrong person, and the Chicago control returns nothing,
so a blank is a real answer. 🟢 Kansas City's HD-23 returns the **Missouri** Michael Johnson, not
South Carolina's.

So St. Louis City Hall now scores **3 of 4**: US House, state representative and state senator.
The fourth — the alderman — arrives with the city wave.

### 🔴🔴 THE DUPLICATE-NAME GUARD KEYS ON `(first_name, last_name)`, NOT `full_name`

A `full_name` sweep is **not** the guard's test and found only 4 of 6 collisions.
`essentials.politician_name_duplicate_guard()` compares
`lower(btrim(first_name))` **and** `lower(btrim(last_name))` over **active** rows only. So
`David Tyson Smith` and `David Smith` collide, and so do `Brian Williams` and `Brian H Williams` —
different full names, same `(first, last)`. **The guard threw during the dry run**, which is the
only reason they were caught. `occupancy-scripts/gen_guardcheck.py` now applies the guard's own
predicate to all 188; run it before regenerating `CC_0177`.

Five of the six are different people, each holding a seat in another state **right now**, and
nobody holds two at once. Verified after the apply that each namesake still holds their own seat:

| Missouri seat | The other person of that name holds |
|---|---|
| HD-12 Mike Jones | `pa` State House District 93 |
| HD-23 Michael Johnson | `sc` State Senate District 16 |
| HD-40 Chad Perkins | `me` State House District 31 |
| HD-46 David Tyson Smith | `fl` State House District 38 |
| SD-14 Brian Williams | `IN` Morgan County Superior Court Judge — Court 2 |

### 🟢 The sixth was the SAME person, and his row was REUSED

**Rick Brattin (SD-31)** already existed — `e9ec322c-e997-486d-8202-48423671c800`,
`external_id -290502` — holding no office but carrying a `race_candidates` row for U.S.
Representative District 5 and **ten researched compass stances**, whose reasoning names him as
*"chairman of the Senate Education Committee"*. `senate.mo.gov` confirms SD-31's Brattin chairs
Education. A second row would have **stranded those ten stances** and shown the seated senator an
empty compass. His `is_incumbent` was flipped false → true: false was correct for a candidate
record and wrong once he is seated.

🟢 **The reuse sweep ran three ways and the third found a real match, so it was not blind.** It
returned **Denny Hoskins** — SD-21's senator in the 102nd, now **Missouri Secretary of State**,
already seated with 14 stances. He is a *predecessor* here and never a holder, so no action. He is
the positive control.


---

## ✅ Wave 3 — the City of St. Louis, APPLIED 2026-09-28

Two geography loads and two migrations, all applied. `CC_0178` (structure) and `CC_0179`
(occupancy), both gates passed, dry-run first with the rollback confirmed to have reverted.

| Piece | Result |
|---|---|
| `scripts/load-stlouis-ward-boundaries.mjs` | **14** ward polygons, `mtfcc X0075`, from the city's own GIS |
| `scripts/load-stlouis-place-boundary.mjs` | **1** row, place `2965000`/`G4110` (TIGERweb) |
| `CC_0178` | 1 government, 6 chambers, 16 districts, **23 offices** |
| `CC_0179` | **22 people, 22 terms**; the Sheriff seat created **unseated** |

Measured in production after the apply: 23 offices, 22 seated, 0 vacancy flags, **0 districts
without a polygon**, 0 offices on county `29510`.

### The address probe, live — and why the ward geography was worth loading

| Point | Ward alderman | Citywide |
|---|---|---|
| 1200 Market St (City Hall) | **Ward 14 Rasheen Aldridge** | President Megan Green · Mayor Cara Spencer |
| Missouri Botanical Garden | **Ward 5 Matt Devoti** | President Megan Green · Mayor Cara Spencer |
| **CONTROL: Clayton** | — | — |

Two city addresses, two different aldermen. Under the Springfield model both would have returned
all fourteen.

### 🔴 The office list came from certified ballots, and it corrects this spec

Eight certified Board of Election Commissioners summaries were read — Nov 2020, Apr 2021, Nov 2022,
Apr 2023, Nov 2024, Apr 2025, Apr 2026, Aug 2026. **23 elected offices**, each appearing on at
least one:

| Office | Ballots | Seats |
|---|---|---|
| Mayor · Comptroller | Apr 2021, Apr 2025 | 2 |
| President of the Board of Aldermen | Nov 2022 (special), Apr 2023 | 1 |
| Alderman | Apr 2023 (all 14), Apr 2025 (7 odd wards) | 14 |
| Sheriff · Treasurer | Nov 2020, Nov 2024 | 2 |
| Circuit Attorney | Nov 2024 | 1 |
| Collector of Revenue · License Collector · Recorder of Deeds | Nov 2022, Aug 2026 | 3 |

**This spec guessed the 23rd seat was the Public Administrator. The ballots say it is the SHERIFF.**

🔴 **Public Administrator, Circuit Clerk, Assessor and Coroner are NOT seated, and that is a
MEASURED ABSENCE.** A 4-year county-tier office must appear in one of the two November cohorts
(2020/2024 or 2022/2026); none of the four appears in **either**. Sean Rapp does hold the Public
Administrator's office and has his own department page — nothing found elects it.

### 🔴 The Sheriff is created unseated and unflagged (ruling 2026-09-28, Cantrell)

Alfred Montgomery won the seat in Nov 2024 with **85.90%**. The Missouri Attorney General's own
statement says a judge ordered him *"immediately and completely removed from the position of
Sheriff"*; that order was later halted, a new-trial motion was denied in April 2026, an interim
runs the office, and **the city publishes no sheriff anywhere** — not on the roster page, and not
in the Sheriff's Office leadership block (controlled: the Public Administrator's block does name
Sean Rapp).

So the office exists and is evidenced, and any occupancy claim would be a claim about contested
facts concerning a named person. It carries no term row and no `is_vacant` flag.
🔴 **`offices_missing_terms` unflagged therefore moves 238 → 239. That is this wave's doing and is
NOT drift. Read CLAUDE.md's baseline as 239 from here.**

### Two dating rules, and every row says which

- **The 14 aldermen carry TRUE OCCUPANCY**, floored at the 14-ward board's first day —
  **2023-04-18**, dated from the Board's own 2023-2024 session meeting record. The Board went from
  28 wards to 14 at the April 2023 election, so occupancy of a ward *as currently drawn* cannot
  begin earlier. Twelve wards at 2023-04-18; Ward 5 at 2025-04-15; Ward 8 at the **2025-07-01
  special for the unexpired term** (Jami Cox Antwi, 1,072 votes / 54.95%, after Cara Spencer left
  Ward 8 for the Mayor's office).
- **The citywide officers carry what their own pages state, where they state it.** The Mayor's page:
  *"sworn in as Mayor of St. Louis on April 15th, 2025."* The Treasurer's page: *"appointed in April
  of 2021 as the successor for Mayor, Tishaura O. Jones."* The other six carry a **month-precision
  current-term start**, because no city page states a take-office date — and the `source` says so.
  ⚠ Gabriel Gore's row **understates** his occupancy: an earlier appointment as Circuit Attorney is
  known and undated by anything read here.

### 🔴 Four traps this pass hit

- **The contests are ABBREVIATED** — `PRES OF BOA`, `COL OF REVENUE`, `REC OF DEEDS` — and pypdf
  **injects spaces mid-word** (`US SENA TOR`, `EDUCA TION`). A search for full office names returns
  **false absences**; the list came from reading every contest heading instead. My own survey also
  dropped `MAYOR` because it required six characters.
- 🔴 **PRESENCE IN A RESULTS PDF IS NOT EVIDENCE OF WINNING.** Donna Baringer appears in four
  November ballots as a **state representative**; Cara Spencer appears in April 2021 because she
  **lost** the mayoral race.
- 🔴 **`stlelections.com` IS A PARKED DOMAIN**, serving HTTP 200 and *"This website is for sale!"*.
  It is not the election authority; that is a department of the city site.
- 🔴 **THREE PUBLISHERS STILL CARRY THE SUPERSEDED 28-WARD MAP**: the city's own Planning
  department ("Census Data by Ward", wards 1–28), the charter PDF, and the **national Open Civic
  Data registry** (`place:st_louis/ward:1 … ward:28`). Only the GIS layer, the Board's
  representation page, the April 2023 ballot and the Board's session roster agree on 14.

### ⚠ Recorded for the county wave, deliberately NOT fixed here

Production's `St. Louis city` COUNTY row (`29510`) carries
`ocd-division/country:us/state:mo/county:st_louis` — which the OCD registry assigns to **St. Louis
County** (`place-29189`) — and `29189` carries it too. Two governments, different ground, one
`ocd_id`, and `ocd_id` rolls up. The city's own identifier is
`ocd-division/country:us/state:mo/place:st_louis` (`place-2965000`). **Wave 3 seats nothing on
`29510`, so this is not needed for wave 3 to be correct.** It belongs to the county wave.


---

## What is still unmeasured

Nothing below has been probed. Do not plan against guesses.

- **St. Louis County** — the charter's list of elected offices, and the 7 council districts'
  geography and membership.
- Headshot sources and their licences; the banner.

### ~~What IS established for the City of St. Louis~~ — SUPERSEDED by wave 3

🔴 **The city block that stood here has been REMOVED because wave 3 disproved two of its claims.**
It said the city's roster page "lists 23 people" (it lists **22**) and it treated the **Public
Administrator** as the missing elected office (the missing one is the **Sheriff**; nothing on either
November cohort elects the Public Administrator). Read the wave 3 section above instead — a stale
claim left beside its correction is how this spec misled a session once already.

---

## ▶ WAVE 4 HANDOFF — St. Louis County (the next session starts here)

Read this file's wave 3 section first, then `backend/data/seed-st-louis-mo-2026/ROSTERS.md`, then
CLAUDE.md's occupancy section. Everything in "What IS established for St. Louis County" below was
measured on 2026-09-28 and is thin — re-verify before acting on it.

### Environment

Worktree `C:\ev-accounts-mo`, branch `seed/mo-stlouis`, PR **#840**. Steward claim `state:mo` —
**check it is still live and extend it**; it has been renewed twice already. Migration slots are
allocated, never counted: `npm run steward --prefix backend -- slot CC`.
⚠ `CC_0180` is **abandoned** (reserved in error by a stray CLI call). Do not reuse it.

### 🔴🔴 THE THREE THINGS THAT WILL BITE THIS WAVE

1. **`St. Louis County` EXISTS TWICE IN PRODUCTION AND BOTH HAVE SEVEN-MEMBER BOARDS.**
   `27137` is **MINNESOTA's** (Duluth slice, 3 offices + 7 commissioner districts); `29189` is
   Missouri's, currently 0 offices. Identical `label`. **Key every insert and every gate on
   `(geo_id, district_type)`, never on the label**, and assert as an ABSENCE that `27137` gained
   nothing. Waves 2 and 3 both carry that gate — copy it.

2. **THE `ocd_id` COLLISION IS THIS WAVE'S TO FIX.** Production's `St. Louis city` COUNTY row
   (`29510`) **and** `St. Louis County` (`29189`) both carry
   `ocd-division/country:us/state:mo/county:st_louis`. The Open Civic Data registry assigns that id
   to the **COUNTY** (`place-29189`); the city's own is
   `ocd-division/country:us/state:mo/place:st_louis` (`place-2965000`). Two governments on different
   ground sharing one identifier, and **`ocd_id` ROLLS UP**. Wave 3 seats nothing on `29510` so it
   did not need to fix this; wave 4 seats the county, so it does. **Fix `29510`, not `29189`** —
   29189's id is the correct one.

3. **THE COUNTY SITE 403s EVERY `curl`, INCLUDING WITH A BROWSER UA. Playwright gets through.**
   And the county charter is published only through a **Yudu web reader**
   (`content.yudu.com/web/44p6g/0A44qnp/StLouisCountyCharter/index.html`), not as a PDF.

### 🔴 The rules waves 2 and 3 paid for, that apply here unchanged

- 🔴🔴 **A ROSTER PAGE IS NOT THE OFFICE LIST — THE BALLOT IS.** Proven twice now. The city's own
  "All Elected Officials" page omitted the **Sheriff** entirely. The county's council pages are
  worse: **they do not name their members at all**, only a phone number, an address and an email.
  **An email prefix is not a name.** Take the office list and the members from certified results.
  - ⚠ **The county has its OWN election authority**, separate from the city's Board of Election
    Commissioners whose archive wave 3 used. Find it; do not assume the city's results cover the
    county.
- 🔴 **A CERTIFIED SUMMARY LIES THREE WAYS** (all measured in wave 3):
  **contests are ABBREVIATED** (`PRES OF BOA`, `COL OF REVENUE`, `REC OF DEEDS`) so a full-name
  search returns **false absences** — read every contest heading instead; **pypdf injects spaces
  mid-word** (`US SENA TOR`, `EDUCA TION`) so flatten whitespace before matching; and
  **PRESENCE IS NOT A WIN** — Donna Baringer appears in four November ballots as a *state
  representative*, Cara Spencer appears in April 2021 because she **lost**.
- 🔴 **THE DUPLICATE-NAME GUARD KEYS ON `(first_name, last_name)`, NOT `full_name`.** A full_name
  sweep found only 4 of 6 collisions in wave 2. Use
  `backend/data/seed-st-louis-mo-2026/occupancy-scripts/gen_guardcheck.py`, which applies the
  guard's own predicate. **A hit has two opposite right answers — read what the existing row IS**:
  five were other states' officeholders, the sixth was the Missourian himself carrying 10 stances.
- 🔴 **A detector reporting "nothing found" needs a positive control**, and **a control can pass for
  the wrong reason**. In wave 3 two gate controls were **shadowed** by earlier gates and had to be
  reordered. Watch each gate fail on ITS OWN gate.
- 🔴 **OCCUPANCY IS FLOORED AT THE MAP CHANGE, NOT THE TERM** (ruling 2026-09-28). **Establish
  whether the 7 council districts were redrawn**, and when they first had officeholders — that date
  is the floor, exactly as 2023-01-04 was for the General Assembly and 2023-04-18 for the wards.
- 🔴 **A TERM START COMES FROM A DOCUMENT THAT STATES IT**, never a statute or a computed day. In
  wave 3 the Mayor's and the Treasurer's own pages stated theirs; six others did not and carry
  month precision with the `source` saying so. That is acceptable — a guess is not.
- 🔴 **`is_incumbent` EXPLICITLY ON EVERY INSERT**; it defaults to false and an omission hides the
  person from address search.

### Reachability — checked in wave 3, reusable here

`districtQueries.GEOFENCE_DISTRICT_JOIN` and `geoIdGuard.MTFCC_DISTRICT_TYPE_GUARD` both carry an
X catch-all: `mtfcc LIKE 'X%' AND mtfcc NOT IN (X0001..X0004) AND district_type IN
('LOCAL','COUNTY',…)`. So **a synthetic `X00NN` mtfcc reaches `LOCAL` and `COUNTY` with no code
change** — which is how the 14 city wards work (`X0075`; the next free code is **X0076**).
**`G4020` maps only to `COUNTY`/`JUDICIAL`** (LOCAL_EXEC is PR-scoped), so a `LOCAL_EXEC` seat on
the county polygon would be **unreachable by any address and nothing would error**. That is exactly
why wave 3 loaded place `2965000`.
🔴 **The structure migration must REFUSE TO RUN if its geography is absent** — `CC_0178` does this;
copy the pre-flight block.

### The baseline moved

**`essentials.offices_missing_terms` unflagged is now 239, not 238.** Wave 3 created the Sheriff
seat unseated by ruling. Treat **above 239** as new drift.

### What wave 5 owes after this

Headshots and their licences, and the city banner. 🔴 **`photo_custom_url` is what renders** — a
`politician_images` row changes nothing a voter sees. A blank beats a wrong face.


### What IS established for St. Louis County (measured 2026-09-28, thin — re-verify)


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
