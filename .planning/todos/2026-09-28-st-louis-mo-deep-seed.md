# St. Louis, Missouri deep seed

**Created** 2026-09-28 · **Status** waves 1 (geography), 2 (General Assembly), 3 (City of St. Louis) and **4 (St. Louis County)** APPLIED · **Author namespace** `CC_`
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

## ✅ WAVE 4 HANDOFF — St. Louis County (COMPLETED 2026-09-29; kept for its rules)

🟢 **Wave 4 is APPLIED.** This handoff is kept because its rules held, and the section below it
records what was settled. The applied record is at the end of this file.

Read this file's wave 3 section first, then `backend/data/seed-st-louis-mo-2026/ROSTERS.md`, then
CLAUDE.md's occupancy section.

🟢 **UPDATE 2026-09-29 — THE OFFICE LIST IS SETTLED.** "What IS established for St. Louis County"
below has been rewritten and is no longer thin: **10 elected seats**, agreed by the charter's own
negative enumeration and by both certified November cohorts, with every current holder confirmed
against the county's own pages. Read that section, not the three warnings below, wherever the two
disagree — **two of the three have been disproved** and say so in place.

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
   ✅ Re-verified 2026-09-29: `curl` with a full Chrome UA gets **HTTP 403, 5,786 bytes**; Playwright
   renders the page.
   🟢 **DISPROVED — the charter is NOT Yudu-only.** It is on **Municode as searchable text**
   (`library.municode.com/mo/st._louis_county/codes/code_of_ordinances?nodeId=STLOCOCH2020`),
   together with the whole Revised Code, codified through February 2026. The Yudu reader is one
   publication of it, not the only one. ⚠ Municode's `api.municode.com/CodesContent` endpoint
   returns **401** to `curl` — read the page in Playwright.

🔴 **AND THERE IS A FOURTH, WHICH COST THIS WAVE A WRONG WINNER: A CERTIFIED CSV CAN ARRIVE
   TRUNCATED UNDER A CLEAN HTTP 200.** Three of five files did. The short `el241105` named the
   **runner-up** in County Council District 6 at a believable 53/47 margin, and nothing errored.
   See the settled section below, and `county-results/FETCH.md`.

### 🔴 The rules waves 2 and 3 paid for, that apply here unchanged

- 🔴🔴 **A ROSTER PAGE IS NOT THE OFFICE LIST — THE BALLOT IS.** Proven twice now. The city's own
  "All Elected Officials" page omitted the **Sheriff** entirely. Take the office list from certified
  results. ✅ Held again here: the charter and the ballots agree on 10 seats.
  🟢 **PARTLY DISPROVED — the council DOES name its members.** The seven **district** pages carry a
  phone number, an address and an email only, and an email prefix is not a name. But the council's
  **landing page** (`…/county-council/`) names all seven, with Chair and Vice Chair. That page is
  what caught the truncated CSV, so the rule cuts both ways: **a roster page is not the office list,
  and a certified tally is not self-verifying either. Read both.**
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
- 🔴 **OCCUPANCY IS FLOORED AT THE MAP CHANGE, NOT THE TERM** (ruling 2026-09-28).
  ✅ **ANSWERED 2026-09-29: they were redrawn, by the 2021 commission (charter § 2.035, every tenth
  year), and the two cohorts floor at DIFFERENT dates** — districts 1/3/5/7 at their January 2023
  term start, districts 2/4/6 at their January **2025** one, because 2/4/6 were last elected on the
  old map in Nov 2020. Full reasoning in the settled section below.
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


### ✅ What IS established for St. Louis County — SETTLED 2026-09-29

🔴 **The block that stood here has been REPLACED.** It was measured on 2026-09-28 and labelled
"thin"; three of its claims are now disproved, and they are called out below so a later session
does not re-derive them from the old wording. Nothing below is a guess — each row names its source.

#### The elected-office list: **10 seats**, agreed by two independent sources

**Source 1 — the charter, § 6.010, verbatim.** It is a *negative* enumeration, so it is exhaustive:

> "There shall be **no elective county officers other than county executive, council members,
> prosecuting attorney and assessor.** Elective officers shall be nominated and elected in the
> manner provided in the election laws for the nomination and election of state and county
> officers."

🟢 **The charter is on MUNICODE as searchable text** —
[`library.municode.com/mo/st._louis_county/codes/code_of_ordinances?nodeId=STLOCOCH2020`](https://library.municode.com/mo/st._louis_county/codes/code_of_ordinances?nodeId=STLOCOCH2020),
titled `ST. LOUIS COUNTY CHARTER 2020`, *"Adopted By Voters August 4, 2020"*, codified through
Ordinance 29,532 of 2026-02-17. **The Yudu web reader is not the only publication, and this spec
said it was.** Municode also carries the whole Revised Code, so use it for any later ordinance
question. ⚠ Its `api.municode.com/CodesContent` endpoint returns **401** to `curl`; read the page
in Playwright and pull `innerText`.

**Source 2 — certified results, read from the county's OWN election authority.** Both four-year
cohorts, enumerated contest by contest rather than searched by name.

| Office | Seats | Charter cycle | Cohort | District |
|---|---|---|---|---|
| County Executive | 1 | § 3.010 — 1982 + 4n | Nov 2022 → Nov 2026 | countywide |
| Prosecuting Attorney | 1 | § 5.040 — 1982 + 4n | Nov 2022 → Nov 2026 | countywide |
| County Assessor | 1 | § 6.050 — 2014 + 4n | Nov 2022 → Nov 2026 | countywide |
| County Council 1, 3, 5, 7 | 4 | § 2.040 — odd districts, 1982 + 4n | Nov 2022 → Nov 2026 | single-member |
| County Council 2, 4, 6 | 3 | § 2.040 — even districts, 1980 + 4n | Nov 2024 → Nov 2028 | single-member |

#### 🔴 The measured absences — and why the City's list must NOT be copied across

Each office below is **appointed by the charter**, and each returns **zero** hits in all four
complete certified files (Nov 2020, Nov 2022, Nov 2024, Aug 2026):

| Office | Charter | Appointed by |
|---|---|---|
| County Auditor | § 2.200 | the council |
| County Clerk | § 2.240 | the administrative director |
| Treasurer | § 4.060 | the director of administration |
| Collector · Recorder of Deeds | § 4.350 | the director of revenue |
| Circuit Clerk | § 4.450 | the director of judicial administration |
| County Counselor | § 5.020 | the county executive |
| Public Administrator | § 6.020 | a majority of the circuit judges, council confirming |
| **Sheriff** | — | no such office. § 4.270 gives a board of police commissioners |
| **Coroner** | — | no such office. § 4.150 gives a chief medical examiner |

🔴🔴 **THE CITY ELECTS SEVEN OFFICES THE COUNTY DOES NOT.** Wave 3 seated a Sheriff, a Treasurer,
a Collector of Revenue, a Recorder of Deeds, a License Collector, a Circuit Attorney and a
Comptroller for the City. **The County elects none of them.** The two lists share only the word
"county". Copying wave 3's list across would invent eight offices.

**The absence test had three working controls.** `TREASURER` returns 4,942 hits in Nov 2020 and
3,860 in Nov 2024 (`STATE TREASURER`) and 0 in Nov 2022 and Aug 2026. `COUNTY ASSESSOR` returns 0
in Nov 2020 and Nov 2024 and thousands in Nov 2022 and Aug 2026 — exactly what § 6.050's 2014 + 4n
cycle predicts. So the matcher reads this corpus and a zero is a real answer.

#### 🔴🔴 A TRUNCATED CSV RETURNED A PLAUSIBLE WRONG WINNER UNDER A CLEAN HTTP 200

This is the rule this wave paid for. `curl` wrote a **short body and exited 0** for three of five
files:

| File | Written | Actual |
|---|---|---|
| `el241105` Nov 2024 general | 6,127,301 | **9,364,370** |
| `el240806` Aug 2024 primary | 5,449,212 | **14,766,495** |
| `el220802` Aug 2022 primary | 6,675,537 | **6,929,384** |

A truncated precinct file is not a smaller answer — it is a **different** one. The partial
`el241105` held only part of County Council District 6, so aggregating it named **Kevin Schartner**
the winner at **53.13%**. The complete file names **G. Michael Archer** at **52.50%**. The
runner-up. At a believable margin. Correctly formatted. Nothing errored.

🔴 **It was caught only by cross-checking the tally against the body's own roster page.** A
certified tally verifies nothing about itself. Truncation also hid **six contests** from the Nov
2024 enumeration (83 → 89), so the office list itself was at risk.

Guards now in place, and each was **watched failing first**:
`backend/data/seed-st-louis-mo-2026/county-results/derive_roster.py` asserts every file's exact
byte count before it reads a vote; `fetch.sh` loops on `Content-Length` until each file matches.
Truncate a file and the gate refuses; run `fetch.sh` and it repairs; the gate then passes. Full
record in that directory's `FETCH.md`.

⚠ **The URL pattern `eResults/el<YYMMDD>/CSV.csv` does not hold before about 2021.** Nov 2020 is
`el201103/112020Detailed.csv`, and `el201103/CSV.csv` is a 404. Take the href from the archive page.

#### The seats and who holds them — 2026-09-29

The middle column is what the certified result says. The right column is what the county publishes
**today**. They are different questions.

| Seat | Certified winner | Holds it now |
|---|---|---|
| County Executive | Sam Page (D) 51.56%, Nov 2022 | **Sam Page** |
| Prosecuting Attorney | Wesley Bell (D) 70.69%, Nov 2022 | 🔴 **Melissa Price Smith** |
| County Assessor | Jake Zimmerman (D) 57.35%, Nov 2022 | **Jake Zimmerman** |
| Council 1 | Rita Heard Days (D), unopposed, Nov 2022 | **Rita Heard Days** — Chair |
| Council 2 | Gretchen Bangert (D) 67.13%, Nov 2024 | **Gretchen Bangert** |
| Council 3 | Dennis Hancock (R) 51.22%, Nov 2022 | **Dennis Hancock** |
| Council 4 | Shalonda Webb (D) 80.29%, Nov 2024 | **Shalonda D. Webb** |
| Council 5 | Lisa D. Clancy (D) 63.78%, Nov 2022 | **Lisa D. Clancy** |
| Council 6 | G. Michael Archer (R) 52.50%, Nov 2024 | **Michael Archer** |
| Council 7 | Mark A. Harder (R) 58.40%, Nov 2022 | **Mark Harder** — Vice Chair |

🔴 **THE PROSECUTING ATTORNEY IS NOT WESLEY BELL.** Bell won in Nov 2022 and then won a US House
seat. § 5.050 fills the vacancy by county executive appointment with council confirmation. The
office's own site names **Prosecutor Melissa Price Smith**
(`stlcopa.stlouiscountymo.gov`), and she won the Aug 2026 Democratic primary with 74.10%. **Her
term start needs the appointment or confirmation document — it is not in any certified result.**

🔴 **THE COUNCIL LANDING PAGE NAMES ALL SEVEN MEMBERS**, with Chair and Vice Chair —
`stlouiscountymo.gov/st-louis-county-government/county-council/`. This spec said the council "does
not name their members at all". That is true of the seven **district** pages, and false of the
landing page. 🟢 That page is the cross-check that caught the truncation.

⚠ The roster comparison in `derive_roster.py` keys on the **surname only**. It is a reporting
cross-check, not a guard: a surname match can be coincidence, and a surname change (wave 2's
Mazzie Boyd → Christensen) would read as a mismatch. Read the row, do not trust the flag.

#### Geography — three layers, and two of them are the same map

All three are on the county's own ArcGIS org `w657bnjzrjguNyOy`
(`services2.arcgis.com/w657bnjzrjguNyOy/arcgis/rest/services/<name>/FeatureServer/0`), each with
exactly 7 features keyed `DISTRICT` 1–7:

| Layer | Internal name |
|---|---|
| `Council_District_Plan_2022` | `stlco_sde_dw.SDEDBO.Council_District_Plan_2022` |
| `Council_Districts_WFL1` — titled "St. Louis County Council District Boundaries" | **`Council_Districts_2023`** |
| `County_Council_Districts_2019` | the superseded map |

🟢 **`Council_District_Plan_2022` and `Council_Districts_WFL1` are the SAME MAP.** Grid-sampled at
160 × 160 over the county bbox: **11,527 of 11,527** interior points assign to the same district,
0 different, 0 one-sided. Two digitisations of one plan, not two plans.

🟢 **The 2019 layer is the control, and it DISAGREES** — 217 points differ (1.88%), plus 23 and 42
one-sided. So the comparator detects a real difference and was not blind.
`county-results/cmp_maps.py` is the script; it needs no geometry library.

▶ **Load `Council_Districts_WFL1`.** Same geometry as the 2022 plan, and it additionally carries a
`Hyperlink` field holding each district's own page URL — usable for `offices.url`. Neither layer
names a member.

#### 🔴 The occupancy floor — RULED 2026-09-29 (Cantrell)

Charter § 2.035 orders reapportionment within thirty days before June 1 **each tenth year**, so the
current map comes from the **2021** commission. The two cohorts therefore floor at different dates:

- **Districts 1, 3, 5, 7** were first elected on the current map in **Nov 2022**. Floor at their
  January 2023 term start.
- **Districts 2, 4, 6** were last elected on the **old** map in Nov 2020 and first elected on the
  current map in **Nov 2024**. Floor at their **January 2025** term start.

The ruling: occupancy of the seat **as currently drawn** begins at the first term begun under the
current map. This is the same rule as 2023-01-04 for the General Assembly and 2023-04-18 for the
city wards. Flooring all seven at 2023 would claim the even-district members represented ground
they did not represent in 2023 and 2024.

The three countywide offices carry no map question. They floor at their own term start.

#### 🔴 Term-start dates are NOT available from the charter

§§ 2.040, 3.010, 5.040 and 6.050 all say the officer takes office **"on the first Tuesday of
January following the election"**. That is a **computed statutory day**, which CLAUDE.md forbids as
a term start. Do not compute 2023-01-03 or 2025-01-07 from it.

▶ **Get the date from a document that states it.** § 2.050 requires the council to meet in the
first regular meeting of every calendar year and select a chair. The county runs agendas and
**journals** through iCompass — `stlouisco.civicweb.net/Portal/MeetingTypeList.aspx`. That is this
wave's analogue of the House and Senate Journals wave 2 used. If a journal does not state an oath
date, fall back to **month precision** and say so in `source`, exactly as wave 3 did for six city
officers.

#### Still open when this section was written

- The council journals, for each of the ten term starts.
- Melissa Price Smith's appointment and confirmation date.
- Whether the 2021 reapportionment commission's filing with the county clerk states an effective
  date (charter § 2.035 requires the filing). It would confirm the floor rather than change it.

---

## ✅ Wave 4 — St. Louis County, APPLIED 2026-09-29

One geography load and two migrations, all applied to production. `CC_0181` (structure) and
`CC_0182` (occupancy), both gates passed, dry-run first with the rollback **confirmed to have
reverted** before each real apply.

| Piece | Result |
|---|---|
| `scripts/load-stlouis-county-council-boundaries.mjs` | **7** council polygons, `mtfcc X0076`, from the county's own ArcGIS org |
| `CC_0181` | 1 government, 4 chambers, 7 districts, **10 offices**, and the `29510` `ocd_id` repaired |
| `CC_0182` | **10 people, 10 terms**; all 10 seats filled |

### Measured in production after the apply — not read from the gates

| Check | Result |
|---|---|
| St. Louis County MO offices | **10** |
| Seated (counting `och.politician_id`, never `count(*)`) | **10** |
| Council districts with no polygon | **0** |
| `offices_missing_terms` unflagged | **239** — exactly the baseline, unmoved |
| 🔴 St. Louis County **MINNESOTA** offices | **10** — unchanged |
| 🔴 Offices on the Minnesota district `27137` | **3** — unchanged |
| `29510` `ocd_id` | `…/county:st_louis_city` (repaired) |
| `29189` `ocd_id` | `…/county:st_louis` (untouched, as intended) |
| `npm run check:occupancy` | passes |
| `check:migrations` · `check:reservations` · `steward sync` | all clean |

### The address probe, live against production

| Point | County seats returned |
|---|---|
| 41 S Central Ave, Clayton (County Government Center) | **District 5 Lisa D. Clancy** (2023-01-10) · Sam Page · **Melissa Price Smith** (2025-01-03) · Jake Zimmerman |
| 10405 St Charles Rock Rd, St Ann (north county) | **District 2 Gretchen Bangert** (2025-01-07) · the same three countywide |
| 🔴 **CITY CONTROL:** 1200 Market St (City Hall) | **none** — Ward 14 Aldridge and the citywide officers only |
| 🔴 **CITY CONTROL:** 5005 Chippewa St, St Louis | **none** — Ward 5 Devoti and the citywide officers only |
| **CONTROL:** Chicago | **none** |

🟢 Two county addresses return two different council members, so the ward-style failure (every
address answering with all seven) did not happen. 🟢 **Both city addresses return ZERO county
rows**, which is this wave's central confusion controlled end to end: the City of St. Louis is not
in St. Louis County. 🟢 The two cohort floors show through — Clayton reads 2023-01-10, St Ann reads
2025-01-07.

### The geography gate was watched failing, six ways

The count cannot date this map: 7 is 7 under the superseded 2019 plan too. So vintage is
**geometric, and asserted in both directions**.

| Control | Result |
|---|---|
| `--control=count` | `GATE 1: expected 7 features, got 6` |
| `--control=agree` | `GATE 2: the layer DISAGREES with Council_District_Plan_2022 by up to 12.1460%` |
| `--control=vintage` | `GATE 3: NO district differs from County_Council_Districts_2019 by more than 2%` |
| `--control=overlap` | `GATE 4: 1 pair(s) of council districts overlap` |
| `--control=probe` | `GATE 5: 41 S Central Ave, Clayton … falls in 0 council district(s)` |
| `--control=tile` | `GATE 6: the seven districts cover only 85.014% of the county` |

🟢 **Each control passed every earlier gate and failed only its own.** None was shadowed — the
defect wave 3 had to reorder around. Gates 2 and 3 deliberately read the **untampered** fetch,
because they are claims about the published layers rather than about the row list; without that,
`overlap`/`probe`/`tile` would have tripped GATE 2 first.

Measured on the real run: **0.0000%** symmetric difference against the 2022 plan, **12.1460%**
against the 2019 map with six of seven districts moved, and **99.940%** of the county covered.

### 🔴🔴 THE RULE THIS WAVE PAID FOR: A TRUNCATED CSV NAMED THE RUNNER-UP

`curl` wrote a short body and **exited 0** for three of five certified files — `el241105` got
6,127,301 of 9,364,370 bytes, `el240806` 5,449,212 of 14,766,495, `el220802` 6,675,537 of
6,929,384. A truncated precinct file is not a smaller answer, it is a **different** one: the
partial Nov 2024 file held only part of County Council District 6, so aggregating it named
**Kevin Schartner** the winner at **53.13%**. The complete file names **G. Michael Archer** at
**52.50%**. The runner-up, at a believable margin, correctly formatted, nothing erroring.

It also hid **six contests** from that election's enumeration (83 → 89), so the office list itself
was at risk.

🔴 **It was caught only by cross-checking the tally against the council's own roster page.** A
certified tally verifies nothing about itself. `county-results/fetch.sh` now loops on
`Content-Length` until each file is byte-exact and `derive_roster.py` refuses to read a vote until
every byte count matches; truncate a file and the gate refuses, run `fetch.sh` and it repairs, and
the gate then passes. Full record in `county-results/FETCH.md`.

### What this wave decided, and what it left understated

- **The two council cohorts floor at different dates** (ruling 2026-09-29, Cantrell): districts
  1/3/5/7 at **2023-01-10**, districts 2/4/6 at **2025-01-07**, because 2/4/6 were last elected on
  the old map in Nov 2020. ⚠ **Shalonda Webb's row understates her on purpose** — she has held
  District 4 since 2021 and chaired the council in 2023-2024, but District 4 was redrawn under her.
- **Dates come from the Journal of the County Council**, never from the charter's computed "first
  Tuesday of January". ⚠ 2023-01-10 is the first date a document places the 2022 cohort in the
  seat; the charter's computed day was 2023-01-03 and there was **no council meeting on it**. Every
  such `source` string says so.
- ⚠ **Sam Page and Jake Zimmerman are understated, by decision** (Cantrell, 2026-09-29). Page has
  been County Executive since 2019 and Zimmerman Assessor since 2011. A countywide seat has no map
  floor, so their occupancy could reach further back, but no document for the earlier dates was
  read and the operator ruled not to chase them. Both rows say so.
- 🔴 **The Prosecuting Attorney is not the certified winner.** Wesley Bell won Nov 2022 with 70.69%
  and then won a US House seat. Melissa Price Smith holds it, `how_started => 'appointed'`,
  2025-01-03 from her own office's page.

## ✅ Wave 5a — headshots, APPLIED 2026-09-29

**32 of 32 seated officials now carry a photo** (22 city, 10 county). All approved from one contact
sheet, uploaded to Supabase Storage at 600×750, and verified end to end: every seat an address
returns reports a CDN photo. Evidence and scripts in `backend/data/seed-st-louis-mo-2026/headshots/`.

| Piece | Result |
|---|---|
| Sources | all official `.gov` pages, licence `press_use` throughout |
| Uploaded | 32 to `politician_photos/<politician_id>-headshot.jpg` |
| Written | `photo_custom_url` + `photo_origin_url` + a `politician_images` row each |
| Gate | 32 CDN `photo_custom_url` + 32 image rows, asserted in SQL |

### 🔴 THE SKILL'S IMPORT STEP DOES NOT MAKE A PHOTO RENDER

`find-headshots` writes `politician_images` and sets `photo_origin_url` to the SOURCE PAGE. Neither
is what a voter sees on the address path: `districtQueries` reads
`COALESCE(p.photo_custom_url, p.photo_origin_url, '')` and **never consults `politician_images`**
(only `compassService` does). So the skill alone yields an invisible import, and setting
`photo_origin_url` to a page URL makes that column a broken image wherever `photo_custom_url` is
empty. This wave wrote **all three**, matching the Detroit/Wayne County convention.
⚠ Measured 2026-09-29: **86 active politicians already render a page URL as their photo** —
`photo_custom_url` empty and `photo_origin_url` pointing at HTML. Pre-existing, not this wave's, and
worth its own pass.

### 🔴 Two detector failures this pass caught

- **The county's `_portrait` variant is an UPSCALE, not a larger original.** It returns 800×1200 for
  *every* asset id — including "Change of Mailing Address" and "Appointments" — which is the tell.
  Measured against the 300×300 original it is **softer**: edge energy 640 against 1377. The originals
  were used. 🔴 **A uniform answer is a broken detector; dimensions are not evidence of detail.**
- **The county council's binding is the weakest kind.** Filenames are bare UUIDs and `alt` text is
  **positional** (`alt="District 1"` names the seat, not the person), so only card text ties a face
  to a name. All seven were flagged for a face check on the contact sheet and approved by eye.
  🟢 By contrast the city's aldermen bind on each profile page's own `<title>`, verified 14 of 14 —
  the profile ids are opaque (`id=1543`), so order proves nothing.

### ⚠ Every source is small, and that was a ruling

Sources run **150×225 to 422×591**; 20 of 32 need more than a 2.2× upscale to reach the house
600×750, and Jake Zimmerman's 150×225 is 4.0×. Ruled 2026-09-29 (Cantrell): **upscale anyway**, so
the cards stay uniform with every other city. These are the only photos the city and county publish.

### 🔴 The county's images are WAF-blocked to every local client

`stlouiscountymo.gov` 403s `curl` for the image FILES as well as the pages — bare, browser-UA,
full browser headers and Referer all refused. It is a TLS-fingerprint block, so **Playwright is the
only way to fetch them**. The working method: `browser_evaluate` fetches the image, renders the
production crop to an `OffscreenCanvas`, and returns base64 — deliberately large enough that the
tool result overflows to a file on disk, which keeps the pixels out of the session transcript.
⚠ An in-page `fetch` is same-origin only: Melissa Price Smith is on `stlcopa.stlouiscountymo.gov`
and failed on CORS until the browser was navigated to that host first.

---

### ⏳ What wave 5b still owes — THE BANNER

**St. Louis has no banner**, and neither does St. Louis County. Checked 2026-09-29:
`buildingImages.js` holds no `st louis` / `saint louis` key. This is the only thing standing between
the two governments and a landing-page chip — their `geo_id` was set by `CC_0183`, so the DATA is
ready and the chip is a one-line addition to `coverage.js` once a banner is certified.

Read the banner-system memory first. The rules that matter:
- Registry `src/lib/buildingImages.js` in the **essentials** repo, state-scoped (`{ state: 'MO', src }`).
  ⚠ `Springfield` and `Saint Paul` already prove the state scope is load-bearing.
- Asset: Supabase Storage `politician_photos/cities/<slug>.jpg`, **1700×540 (3.148:1)**, JPEG q90 progressive.
- 🔴 **AI image generation is excluded by design (D-09)** — real licensed photos only
  (CC0 / CC BY / CC BY-SA / PD), Wikimedia Commons preferred. The `banner-design` skill is the WRONG tool.
- 🔴 **Certify in the 6:1 DESKTOP BAND, but look at the whole asset too.** Mobile keeps ~96.9%,
  desktop ~52.4%. A subject in the upper third survives mobile and vanishes on desktop — that is the
  Bend, OR failure.
- 🔴 **Read the MISSOURI state banner in the band first** — adjacency is composition, and the two
  render on the same page.
- `public/banners.json` is GENERATED and CI-enforced: run `npm run banners:json` after editing the registry.
  ⚠ Its `--check` currently reports "stale" on a clean `main` because of CRLF; that is pre-existing.

⚠ **The essentials repo had UNCOMMITTED work on `main` on 2026-09-29** — the whole coverage pass plus
a 112-line `Landing.jsx` rewrite. The KS/KY chips were added to that working tree and deliberately
NOT committed. Check with whoever owns that session before committing anything there.

## Coordination

- Steward claim `state:mo` taken 2026-09-28, label
  "MO slice - St. Louis city + county + General Assembly deep seed".
- Worktree `C:\ev-accounts-mo`, branch `seed/mo-stlouis`, from `origin/master` at `0f9700c3`.
- Migration slots are **allocated, never counted**: `npm run steward --prefix backend -- slot CC`.
