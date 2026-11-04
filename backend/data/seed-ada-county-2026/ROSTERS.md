# Ada County, Idaho — verified roster, 9 elected seats

**Wave:** Idaho deep seed, 2026-10-30. **Migration:** `CC_0313` (+ `CC_0314` portraits).
**Keys:** `geo_id 16001`, `mtfcc G4020`. The county polygon was already in production from the
national TIGER load; this wave adds the government, the three commissioner districts and the offices.

🔴 **EVERY SEAT IN THIS FILE WAS ON THE 2026-11-03 BALLOT, AND THE WINNERS SEAT 2027-01-11.**
Idaho Code **59-404**: the oath of county elective officers is taken "**on the second Monday of
January succeeding each general election**" — 2027-01-11. This roster is correct today with a known
expiry. See ▶ Open items.

## Sources

| # | Source | What it is | Pulled | File |
| --- | --- | --- | --- | --- |
| 1 | `adacounty.id.gov/commissioners/` | Board of Commissioners, all three | 2026-10-30 | `ada_commissioners.html` |
| 2 | `adacounty.id.gov/{sheriff,clerk,treasurer,assessor,coroner,prosecutor}/` | Each office's own site | 2026-10-30 | `ada_<office>.html` |
| 3 | `adacounty.id.gov/assessor/about-us/meet-the-assessor/` | Assessor's name | 2026-10-30 | `ada_assessor_meet.html` |
| 4 | `services2.arcgis.com/dgGjZc6xAH5m5JyP/.../Commissioner_District/FeatureServer/0` | Commissioner district geometry, published by AdaCountyGIS, **carries the commissioner's name** | 2026-10-30 | `ada_commissioner_districts.geojson` |
| 5 | `en.wikipedia.org/wiki/Ada_County_Board_of_Commissioners` | Independent confirmation of the three district assignments | 2026-10-30 | `wiki_bocc.html` |
| 6 | Ballotpedia person pages | Assumed-office dates | 2026-10-30 | `bp_*.html`, `bp2_*.html` |
| 7 | `legislature.idaho.gov/statutesrules/idstat/Title59/T59CH4/SECT59-404/` | Oath/seating date, primary text | 2026-10-30 | `ic_59_404.html` |
| 8 | `legislature.idaho.gov/statutesrules/idconst/ArtXVIII/Sect6/` | Which county officers are elected | 2026-10-30 | `const18_6.html` |
| 9 | `legislature.idaho.gov/statutesrules/idstat/Title31/T31CH7/SECT31-703/` | Commissioner term rotation | 2026-10-30 | `ic_31_703.html` |

## Charter rulings

Idaho Const. **Art. XVIII §6**, read directly, settles which offices exist: the legislature shall
provide for the biennial election of **county commissioners**, and for the election every four years
of a **sheriff**, a **county assessor**, a **county coroner** and a **county treasurer** (ex officio
public administrator). "**No other county offices shall be established.**" The **clerk of the
district court** is ex officio **auditor and recorder**. The **prosecuting attorney** is elected
under Title 31. That is **nine** elected offices in Ada County, and the roster below is complete.

**Idaho Code 31-703** sets the commissioner rotation: at each biennial election one commissioner is
elected to a two-year term and one to a four-year term, the four-year term rotating through
districts 1 → 2 → 3. So **two of three commission seats are on every even-year ballot** — the board
is never fully insulated from an election.

## 🔴 Source defects found

1. 🔴 **THE COMMISSIONERS' CSS CLASS IS A PHOTO POSITION, NOT A DISTRICT NUMBER.** In the
   `bocc-nameplates` block the wrapper classes run `d3`, `d2`, `d1` against districts **1, 2, 3** —
   they index left-to-right across the group photograph. A parser keying on the class name swaps
   Davidson and Dayley. ▶ The district is carried correctly in three other places on the same page
   and server: the link slug (`ryan-davidson-district-1`), the visible text, and the GIS layer's
   `district` field.
2. 🔴 **THREE BALLOTPEDIA PAGES ARE SOFT-404s SERVED AS HTTP 200.** `/Rod_Beck`, `/Matt_Clifford` and
   `/Richard_Riffle` all returned **200** with a 100–300 KB body reading "Oops! The page you're
   looking for does not exist." The real pages are at **`/Matthew_Clifford`** and **`/Rich_Riffle`**
   — name variants. `/Municipal_elections_in_Ada_County,_Idaho_(2020)` is a 333 KB soft-404 too.
   ▶ A status check is not an existence check. Grep the body for the "does not exist" string.
3. ⚠ **`adacounty.id.gov/` itself returns 403 while its sub-paths return 200.** One denial is not a
   blocked path; every office page fetched cleanly.
4. ⚠ **The county publishes election results only as Tableau dashboards**, so the canvass is not
   machine-readable. This is why one date below is `unknown` rather than guessed.

## Identity rulings

- **The district→commissioner mapping is confirmed five ways**: the county page's link slugs, its
  visible text, the county GIS layer's own `commissioner` attribute, Wikipedia, and the individual
  commissioner bio pages. Only the CSS class disagrees, and it is not a district field.
- 🔴 **Rod Beck's `term_start` is written as `unknown`, deliberately.** No source I could retrieve
  states when he took office. Search results assert he was first elected in November 2020 — which
  would put him at 2021-01-11 alongside Davidson, who won the same election — but a search-result
  summary is a lead, not a source, the county's canvass is locked inside Tableau, Ballotpedia has no
  page for him, and the KTVB report of that election returns **403**. CLAUDE.md is explicit: *if the
  start is genuinely unknown, write an open-ended term with `start_precision => 'unknown'` — not a
  guess.* ▶ Cheap to tighten later from the 2020 certified canvass.
- **Sheriff Clifford's occupancy runs from his 2021 appointment**, not from an election. He was
  appointed 2021-07-02 after Sheriff Bartlett resigned, then won a 2022 special election and a full
  term in 2024. `term_start` is the start of continuous occupancy, so it is 2021-07-02.

## Roster

| Office | District | Name | term_start | precision | Note |
| --- | --- | --- | --- | --- | --- |
| Commissioner | 1 | Ryan Davidson | 2021-01-11 | day | Elected Nov 2020, re-elected Nov 2024 |
| Commissioner | 2 | Rod Beck | — | **unknown** | Board Chair. Open-ended term — see identity rulings |
| Commissioner | 3 | Tom Dayley | 2023-01-09 | day | |
| Sheriff | countywide | Matt Clifford | 2021-07-02 | day | Appointed 2021; elected 2022 and 2024 |
| Clerk of the District Court (ex officio Auditor and Recorder) | countywide | Trent Tripple | 2023-01-09 | day | |
| Treasurer (ex officio Public Administrator) | countywide | Elizabeth Mahn | 2019-01-01 | **year** | Source gives the year only |
| Assessor | countywide | Rebecca W. Arnold | 2023-01-09 | day | |
| Coroner | countywide | Richard D. Riffle | 2023-01-09 | day | |
| Prosecuting Attorney | countywide | Jan M. Bennetts | 2014-01-01 | **year** | Source gives the year only |

## Counts, for the payload guard

| Measure | Value |
| --- | --- |
| Commissioner districts (geometry) | 3 |
| Offices | 9 |
| Seated | 9 |
| `start_precision = day` | 6 |
| `start_precision = year` | 2 |
| `start_precision = unknown` | 1 |

## ▶ Open items

- 🔴 **2027-01-11 — RE-SEAT THE WHOLE SLATE** elected on 2026-11-03, per Idaho Code 59-404. Use
  `essentials.seat_officeholder`; it closes the predecessor's term.
- ▶ **Tighten Rod Beck's `term_start`** from the 2020 certified canvass when a machine-readable copy
  is available. Do not replace `unknown` with an inferred date.
- ▶ Tighten Mahn (2019) and Bennetts (2014) from year to day precision from the same source.
