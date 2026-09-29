# St. Louis, Missouri — rosters and their sources

Harvested 2026-09-28. Spec: [`.planning/todos/2026-09-28-st-louis-mo-deep-seed.md`](../../../.planning/todos/2026-09-28-st-louis-mo-deep-seed.md).

🔴 **Read this before seeding anything.** Every trap below was measured, not assumed.

## Files

| File | Source | Rows |
|---|---|---|
| `mo-house-roster-2026-09-28.json` | `house.mo.gov/MemberDetails.aspx?district=NNN&year=2026&code=R`, all 163 fetched, 0 errors | 163 |
| `mo-senate-roster-2026-09-28.json` | `senate.mo.gov/senators/` member cards | 33 |

## What each source is good for, and what it is not

- **The House member grid and detail pages are authoritative for WHO HOLDS THE SEAT TODAY.** They
  are not authoritative for when the term began: they publish `Elected:` (an election year) and
  `Years Served:` (a count of years in the chamber). See the spec for the seven rows that prove
  neither can be turned into a date.
- 🔴 **`house.mo.gov/DistrictInfo.aspx` — the address lookup — is AUTHORITATIVE FOR GEOGRAPHY AND
  STALE FOR OCCUPANCY.** It returns **Ian Mackey** for HD-99, which the member grid reports as
  **Vacant**. Use it to date the map; never to name an officeholder.
- **The term-start document is the House Journal**, `documents.house.mo.gov/billtracking/bills251/jrnpdf/jrn001.pdf`,
  which states *"FIRST DAY, WEDNESDAY, JANUARY 8, 2025"* and lists every member who *"advanced to
  the bar and subscribed to the oath of office"*.

## Homonyms — three of them are live in prod right now

| Missouri member | A DIFFERENT person of the same name already holds a seat in |
|---|---|
| Chad Perkins (HD-40) | Maine |
| Michael Johnson (HD-23) | South Carolina |
| Mike Jones (HD-12) | Pennsylvania |

And inside Missouri's own chamber, the House Journal itself disambiguates `Brown 149`/`Brown 16`,
`Jones 12`/`Jones 88`, `Smith 46`/`Smith 68`/`Smith 74`, `Taylor 48`/`Taylor 84` — and lists
⚠ **`Sharp 37` and `Sharpe 4`**, two different people one letter apart.

## Vacancies — 9 seats. Do not seat anyone on these

House **29, 95, 99, 110, 114, 149, 159, 160** · Senate **10**.

Set `offices.is_vacant`. Per CLAUDE.md, do **not** write a vacancy span whose start date is unknown.

## City of St. Louis

🔴 **The city's own "All Elected Officials" page is incomplete** — Sheriff, Public Administrator,
Circuit Clerk and Assessor appear **zero** times on it, and the city does elect at least the first
two. Take the office list from the ballot, not from that page.

Sources used: `stlouis-mo.gov/government/elected-officials.cfm`,
`stlouis-mo.gov/government/departments/aldermen/representation/index.cfm`, and the Board of Election
Commissioners' certified results PDFs.

## St. Louis County

⚠ **`curl` gets HTTP 403 from `stlouiscountymo.gov` even with a browser user agent. Use Playwright.**

🔴 **The seven council district pages do not name their members** — contact details only. An email
prefix is not a name.

---

## Occupancy — ruled 2026-09-28 (Cantrell): floor at the current map

`office_terms` holds **occupancy**, not a term. The ruling is to model continuous occupancy of the
seat **as currently drawn**, floored at the first day of the **102nd General Assembly, 2023-01-04** —
the first day on which the 2022 plan had officeholders.

**Why the floor is there and not earlier.** Prod holds only 2022-plan polygons (wave 1 loaded TIGER
2024 `sldu`/`sldl`). HD-78 before January 2023 covered different ground. Reaching occupancy back to
2021 or 2019 would make `essentials.office_holders_as_of()` name the right person for **territory
that district did not cover**. The floor is where the geography stops being true.

**Why not the Kansas / South Dakota shape.** `CC_0157` (KS) and `CC_0164` (SD) both wrote the
*current term start* — 119 of 125 Kansas House members carry `2025-01-13`. That is cheaper and it is
the documented fallback in the spec, but Missouri's Journals hand over the deeper answer for the
cost of two PDFs per chamber, so the fallback is not needed here. **This slice deliberately differs
from KS and SD.** Say so in the migration comment.

⚠ Nothing voter-facing changes either way today: no file in `backend/src` selects `och.term_start`
(checked with a positive control on `och.politician_id`). The API's `term_start` field comes from the
deprecated `politicians.valid_from`. What this ruling buys is a correct `office_holders_as_of()`.

### The evidence: the Secretary of State's certification, printed in each Journal

Each first-day Journal prints the Secretary of State's list of members **keyed by district number**,
under §115.525 RSMo, on the day the oath was administered. **Keying on the district number means no
name matching**, which is what makes the homonym traps above harmless.

| Chamber | 102nd GA | 103rd GA |
|---|---|---|
| House | `documents.house.mo.gov/billtracking/bills231/jrnpdf/jrn001.pdf` — *FIRST DAY, WEDNESDAY, JANUARY 4, 2023* | `…/bills251/jrnpdf/jrn001.pdf` — *FIRST DAY, WEDNESDAY, JANUARY 8, 2025* |
| Senate | `senate.mo.gov/23info/Journals/RDay0101041-87.pdf` — *FIRST DAY - WEDNESDAY, JANUARY 4, 2023* | `senate.mo.gov/25info/Journals/RDay0101081-80.pdf` — *FIRST DAY - WEDNESDAY, JANUARY 8, 2025* |

🟢 **The Senate Journal prints TWO district-keyed lists, each tagged with the election that seated
it** — "Elected November 8, 2022" (even districts) and "Elected November 5, 2024" (odd). That is
exactly what a 4-year staggered chamber needs, and it removes any need to reason about the stagger.

⚠ The Senate journal archive is **not** at a guessed path — three patterns returned 404. The list is
an ASP.NET form; `https://www.senate.mo.gov/journallist/?SelectedYear=2023` returns it.

### Parsed result — `mo-occupancy-2026-09-28.json`, one row per seat with its own `basis`

| Chamber | 2023-01-04 | 2025-01-08 | vacant | total |
|---|---|---|---|---|
| House | 100 | 55 | 8 | 163 |
| Senate | 23 | 10 | 1 | 34 |
| | **123** | **65** | **9** | **197** |

188 seated. The 155 seated House members agree with the member grid's independent 105 R + 50 D.

Scripts in `occupancy-scripts/`. `control.py` is the matcher's tamper control — it asserts
`Mark Sharp` ≠ `Greg Sharpe`, `Richard Brown` ≠ `Donnie Brown`, `John Simmons` ≠ `Kyle Marquart`
**and** `Ken Jamison` = `Kenneth Jamison`, `Dean Van Schoiack` = `Dean VanSchoiack`. Run it before
trusting a re-parse; a matcher that only ever says "same" proves nothing.

### The traps this pass actually hit

- 🔴 **`Vacant` is not the roster's string — it is `District Vacant`.** The first join silently
  classified all 8 vacancies as mid-term arrivals. Match on `/vacan/i`.
- 🔴 **HD-2 is a SURNAME CHANGE, not a change of person.** The 102nd Journal certifies
  **Mazzie Boyd**; the 103rd certifies **Mazzie Christensen**; `elected` is 2022 for both. A name
  match alone writes 2025-01-08 and understates her occupancy by two years. Resolved from
  `house.mo.gov/MemberDetails.aspx?district=002&year=2023`, which names Christensen at the 2023 seat.
  - 🟢 **That page needed its own control**, because a departed official's URL can serve their
    successor. `?district=109&year=2023` returns **Kyle Marquart** and `&year=2025` returns
    **John Simmons**, so the `year` parameter is honoured and the read is real.
- ⚠ **HD-109 is the case arithmetic cannot solve** — *Elected 2024, 6 years served*. The Journals
  date it exactly: Simmons held HD-109 in 2019 and 2021, **lost it to Kyle Marquart in 2023**, and
  returned in 2025. His current occupancy starts 2025-01-08.
- ⚠ Two Senate rows read as mid-term arrivals and were neither: `Cindy O&#x27;Laughlin` (an
  undecoded HTML entity in the harvest) and `Stephen`/`Steven Webber`. **Unescape before matching.**
- ⚠ pypdf splits the ordinal `1st` across two lines (`'1'` then `'st Jeff Farnan'`), and renders
  apostrophes as a replacement character, which dropped **HD-1 and HD-95** from the first parse.
- 🟢 **SD-10's vacancy has the Senate's own notice**, not just an absent card: the index carries
  `Senators/VacantSenator?district=10` and the text *"Vacant District 10"*.

---

## ✅ Applied 2026-09-28 — `CC_0176` + `CC_0177`

197 offices, 188 terms, 9 vacancies. Measured in production after the apply: `offices_missing_terms`
unflagged returned to **238**, exactly its baseline. Full record in the spec's wave 2 section.

### 🔴🔴 The one rule this wave paid for

**`essentials.politician_name_duplicate_guard()` KEYS ON `(first_name, last_name)`, NOT
`full_name`.** It compares `lower(btrim(first_name))` **and** `lower(btrim(last_name))`, over
**active** rows only. A `full_name` sweep is a *different, weaker* test: it found 4 of 6 collisions
here and missed `David Tyson Smith` vs Florida's `David Smith`, and `Brian Williams` vs Indiana's
`Brian H Williams`. Both have different full names and the same `(first, last)`.

**The guard threw during the dry run, which is the only reason they were caught.** Use
`occupancy-scripts/gen_guardcheck.py`, which applies the guard's own predicate, before generating
any seating migration.

### 🟢 And the direction that is NOT a namesake

**Rick Brattin (SD-31) already existed and his row was REUSED, not duplicated** — it carries ten
researched compass stances that a second row would have stranded, leaving the seated senator an
empty compass. A name collision has two opposite right answers, and the test is the same either
way: read what the existing row *is*. Five of six were other states' officeholders; the sixth was
the Missourian himself.

---

## ✅ Wave 3 applied 2026-09-28 — the City of St. Louis

23 offices, 22 seated, 14 ward polygons. Full record in the spec's wave 3 section.

### 🔴🔴 THE CITY'S ROSTER PAGE IS NOT THE OFFICE LIST — THE BALLOT IS

`stlouis-mo.gov/government/elected-officials.cfm` names **22** of the city's **23** elected
officials. The strings `Sheriff`, `Public Administrator`, `Circuit Clerk`, `Assessor` and `Coroner`
appear **zero** times on it. The missing seat is the **Sheriff** — this spec had guessed Public
Administrator.

Eight certified Board of Election Commissioners summaries (Nov 2020 → Aug 2026) establish the list.
**Public Administrator, Circuit Clerk, Assessor and Coroner appear on NEITHER November cohort**, so
nothing elects them, and that absence is measured rather than assumed.

### 🔴 Reading a certified summary: three ways it lies

1. **The contests are ABBREVIATED** — `PRES OF BOA`, `COL OF REVENUE`, `REC OF DEEDS`. Searching
   for the full office name returns a **false absence**. Read every contest heading instead.
2. **pypdf injects spaces mid-word** — `US SENA TOR`, `EDUCA TION`, `KELL Y BRONIEC`. Flatten
   whitespace before matching, and control the flattened search in both directions.
3. **PRESENCE IS NOT A WIN.** Donna Baringer appears in four November ballots as a *state
   representative*; Cara Spencer appears in April 2021 because she **lost** the mayoral race.

### 🔴 `stlelections.com` IS A PARKED DOMAIN

HTTP 200, 3,103 bytes, *"This website is for sale!"*. The election authority is a department of the
city site: `stlouis-mo.gov/government/departments/board-election-commissioners/`.

### 🔴 THREE PUBLISHERS STILL CARRY THE SUPERSEDED 28-WARD MAP

The Board went 28 → 14 wards at the April 2023 election. Still publishing 28 as of 2026-09-28:
the city's own **Planning department** ("Census Data by Ward"), the **charter PDF**, and the
**national Open Civic Data registry** (`place:st_louis/ward:1 … ward:28`). Only the GIS layer, the
Board's representation page, the April 2023 ballot and the Board's session roster agree on 14.

### Useful endpoints

- Board of Aldermen roster **by legislative session**: POST `sessionID=N` to
  `…/aldermen/representation/index.cfm` (202 = 2026-2027, 199 = 2023-2024, the first 14-ward one).
- Full Board **meeting dates** per session: POST `sessionYear=N` to
  `…/aldermen/aldermanic-legislative-session.cfm`. ⚠ **It is a POST and the field is `sessionYear`**
  — a GET, or the name `sessionID`, silently returns the CURRENT session. Always read back the
  `selected` option to confirm which session you actually got.
- Ward polygons: `maps8.stlouis-mo.gov/arcgis/rest/services/STLOUIS/BOUNDARIES/MapServer/4`.
