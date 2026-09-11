# Gary, Indiana — IN-4 roster

Wave **IN-4** of the Knight Foundation cities programme, slice 4, stage 3.
Parent county: **Lake** (stage 4, not this wave).

**Gary elects TWELVE offices. This wave seats SIX of them.** The six district council seats are
**deferred**, not forgotten — see *The district seats are deferred* below.

Slice notes: [`.planning/knight-foundation/in.md`](../../../.planning/knight-foundation/in.md).
Migrations: `CC_0092` (structure), `CC_0093` (occupancy) — both slots **reserved from the
allocator**, not counted.

## 🔴🔴 GARY IS NOT FORT WAYNE, AND THE DIFFERENCE IS AN ELECTED JUDGE

Fort Wayne Code § 31.01 ends at City Clerk, so Fort Wayne elects **11** offices. **Gary elects 12.**
The Lake County certified 2023 municipal results list, for Gary:

| Office | 2023 winner |
| --- | --- |
| Mayor | Eddie Melton (D) |
| **Judge of the City Court** | **Deidre L Monroe (D)** |
| City Clerk | Suzette Raggs (D) |
| City Council At Large ×3 | Darren L Washington, Ronald G Brewer Sr, Mark Spencer |
| City Council Districts 1–6 | one each |

Indiana second-class cities *may* have a city court under IC 36-4-9. **Fort Wayne does not; Gary
does.** Inheriting Fort Wayne's answer would have silently dropped an entire elected judgeship —
the DESCRIBE-REAL-POWERS rule, caught by reading the ballot rather than the neighbouring city.

## Sources

| | Source | What it is | Read |
| --- | --- | --- | --- |
| **A** | [`garycommoncouncil.gov/council-members/`](https://garycommoncouncil.gov/council-members/) | The Council's own current roster | 2026-09-10 |
| **B** | [Lake County 2023 municipal election results](https://lakecountyin.gov/departments/voters/election-results-c/2023MunicipalElectionResults/) | The county's certified precinct summaries — **what Gary elects**, and who won in 2023 | 2026-09-10 |
| **C** | NWI Times / Chicago Crusader / Capital B Gary | The caucus events that changed four seats since 2023 | 2026-09-10 |

⚠ **Ballotpedia is NOT a source here.** It covers Fort Wayne richly — every councilmember has a
tenure field, because Fort Wayne is a top-100 city. For Gary, **ten of twelve officials return
HTTP 404**. The same source was decisive one wave ago and is empty in this one.

⚠ **`garycommoncouncil.org` (the `.org`) also exists and is stale.** A search snippet from it named
**Tai A. Adkins** as Council President; Adkins left the council in 2025. The `.gov` is current.

## 🔴 Source defects and traps

- **Municode returns HTTP 403 to WebFetch**, and in Playwright its body text is dominated by a
  language-selector widget, so `innerText` returns a list of 200 languages rather than the code.
- The Council's own member pages are **prose biographies with no tenure data** — "Since 2000, I have
  built a successful career in county government" is a career note, not a term start.
- A Lake County precinct summary extraction misread the **Mayor** line as *"Gary Suzette Raggs"*.
  Raggs is the **City Clerk**; the Mayor is Eddie Melton. Cross-read the office labels; do not
  trust a single automated extraction of a results table.

## 🔴🔴 THE DISTRICT SEATS ARE DEFERRED, AND THE REASON IS A STALE MAP THAT LOOKS PERFECT

Gary **missed its statutory redistricting deadline of 2022-12-31**, was sued in federal court by
voting-rights advocate Barbara Bolling-Williams — the suit measured total district deviation at
about **24%** — and under a settlement the Common Council **adopted a new map on 2023-02-10**, used
from the 2023 primary onward.

So the current districts date from **February 2023**. What is actually published:

| Candidate source | What it is | Verdict |
| --- | --- | --- |
| [`github.com/cityofgary/administrative-boundaries`](https://github.com/cityofgary/administrative-boundaries) | The City of Gary's own repo. Six districts, EPSG 4326 GeoJSON, correctly named `FIRST DISTRICT` … `SIXTH DISTRICT`, from the Gary Sanitary District GIS Department | 🔴 **REJECTED — one commit, 2014-07-21; repo not pushed since 2014-08-13.** It predates the 2020 census *and* the settlement map by nine years |
| City of Gary live GIS (`GaryINsight`, 15 items, updated 2026-09) | Municipal boundary, neighbourhoods, zoning, flood plain, roads, water, parcels | ❌ **no council-districts layer at all** |
| Lake County `city-council-district-maps` | Gary's six districts, updated 2026-06-10 | ❌ **PDF and JPG only — no shapefile, no GeoJSON** |
| ArcGIS Online | searched for Lake County precincts and Gary districts | ❌ nothing; the `CityCouncilDistricts` hits are Bloomington and Monroe County |

**The 2014 layer is the trap, and it is a good one**: city-published, correct format, correct
projection, correct district names, six features. Only its commit date gives it away. This is the
CA-2 failure in another dress — the most convenient, correctly-named layer is the wrong map.

### Why the six district offices are not created empty

Creating them without geometry would make six offices that **no address can ever reach**, and
nothing would error. That is precisely the defect this slice measured at **671 offices** in
`indiana_discovery`. IN-3's structure gate already refuses a Fort Wayne district with no boundary;
IN-4 applies the same rule to itself.

▶ **Next action for the district seats:** Lake County's GIS page offers *"Request GIS Map or Data"*.
The 2023 settlement map exists as a county-administered map — request it, or obtain the exhibit
filed with the settlement. Do **not** georeference the PDFs.

## Change-check — four of twelve seats have changed since 2023

| Seat | 2023 winner | Now | What happened |
| --- | --- | --- | --- |
| At Large | **Mark Spencer** | Kenneth Whisenton | Spencer won **Indiana Senate District 3** and was sworn in **2024-11-19**, vacating the at-large seat. Whisenton won the caucus, reported **2024-12-04**, beating Tolliver 20–19 |
| At Large | **Ronald G Brewer Sr** | *(chain below)* | Left; Marian Ivey took an at-large seat |
| District 4 | **Tai Adkins** | Marian Ivey | Adkins left to become **Calumet Township trustee**. Ivey, then at-large, won the D4 caucus **2025-02-19** on the Lake County Democratic chairman's tie-breaking vote |
| At Large | *(Ivey's seat)* | **Myles Tolliver** | Won the at-large caucus on Friday **2025-03-21**, filling the seat Ivey vacated on moving to D4 |

🔴 **MARK SPENCER IS THE SAME MAN THIS SLICE ALREADY SEATED IN SD-3** (`CC_0089`, reusing an
`indiana_discovery` row). A wave that read Gary's 2023 results as current would have seated him on
**two** live offices at once, in two different waves, three days apart.

## The six seated by this wave

| Office | Holder | `term_start` | Precision | Source for the date |
| --- | --- | --- | --- | --- |
| Mayor | Eddie Melton | 2024-01-01 | `day` | Assumed office 2024-01-01; his first term as mayor, having previously held SD-3 |
| City Clerk | Suzette Raggs | — | `unknown` | Elected 2023; **no first-taking-office date published**, and she may be a returning incumbent |
| Judge of the City Court | Deidre L Monroe | — | `unknown` | Elected 2023 unopposed; no first-taking-office date published |
| Council, At Large | Darren Washington | — | `unknown` | Long-serving; no tenure source covers Gary |
| Council, At Large | Kenneth Whisenton | 2024-12-01 | `month` | Caucus victory reported 2024-12-04; **the swearing-in day is not published** |
| Council, At Large | Myles Tolliver | 2025-03-01 | `month` | Caucus held Friday 2025-03-21; the swearing-in day is not published |

🔴 **Three of six are `unknown`, and that is the honest answer, not a gap in the work.** Gary's
council publishes prose bios; Ballotpedia does not cover Gary; and the 2023 result gives a **term**,
which — as IN-3 established — is not an occupancy start for anyone re-elected. GA-2 wrote all 235 of
Georgia's legislative terms `unknown` for the same reason.

⚠ **The two `month` rows are dated from the CAUCUS, not the swearing-in.** A caucus win and taking
office are different events, usually days apart, so the day is not asserted.

## Structure

One government, **four** chambers, one district, six offices in this wave.

| Chamber | `official_count` | Offices now | Offices deferred |
| --- | --- | --- | --- |
| Gary Common Council | **9** | 3 at-large | **6 district** |
| Office of the Mayor | 1 | Mayor | — |
| Office of the City Clerk | 1 | City Clerk | — |
| Gary City Court | 1 | Judge of the City Court | — |

🔴 **`official_count` on the Council stays 9**, not 3. It records the body's real size; the three
seated offices are what exists today. A count of 3 would assert Gary has a three-member council.

The single district row is `LOCAL` on TIGER place **`1827000`**, labelled **Gary Citywide** — the
Columbus/Bradenton convention, and the same shape Fort Wayne's citywide row takes.

---

# IN-8 — the six district seats, seated 2026-09-11

**Gary is complete: 12 offices, 12 people, 0 vacancies.** `CC_0096` structure, `CC_0097` occupancy,
boundaries on `X0050` by `scripts/load-gary-council-boundaries.ts`.

| District | Member | `term_start` | Precision | Source for the date |
| --- | --- | --- | --- | --- |
| 1 | Lori Latham | — | `unknown` | nothing covering Gary publishes a tenure start |
| 2 | Dwayne Halliburton | — | `unknown` | as above |
| 3 | Mary Brown | — | `unknown` | as above |
| 4 | Marian Ivey | 2025-02-01 | `month` | won the D4 caucus 2025-02-19 on the county chairman's tie-break; swearing-in day not published |
| 5 | Linda Barnes-Caldwell (Council President) | — | `unknown` | as above |
| 6 | Dwight A Williams | — | `unknown` | as above |

Roster source: `garycommoncouncil.gov/council-members/`, which pairs each member with their district
in its own text. **Change-check re-run live on the day of apply**: all six still named, all six on
the same district, no unexplained name on the page.

## 🔴🔴 THE BOUNDARY THAT IN-4 AND IN-6 COULD NOT FIND WAS PUBLIC

IN-4 deferred these seats and IN-6 recorded that Lake County's open-data org (`lakecountyod`, 174
layers) holds no electoral layer. Both were true of what they searched. The precinct layer is
public in a **different ArcGIS organisation** — the Lake County **Surveyor's** hub — linked from
the county's own *"Request GIS Map or Data"* button.

▶ **A NEGATIVE RESULT IS ONLY EVER TRUE OF THE PLACE YOU LOOKED.**

The six districts are a **dissolve** of that precinct layer on the leading digit of `P26`
(`G1 03` … `G6 18`). 47 precincts; each district dissolves to ONE connected valid polygon; zero
pairwise overlap; union 57.22 sq mi against Gary's 49.75 land + 7.47 water.

⚠ **Two wrong maps were rejected first** — the City's own 2014 GeoJSON repo, and Census
`tl_2020_18_vtd20`, which carries all 52 Gary precincts under the same naming scheme and dissolves
into a map that looks right. Three precincts separate the vintages, and the loader's GATE 2 asserts
all three: **`G4 01`, `G5 22`, `G5 28`** are in this layer and on the Board of Elections' own
2024-03-01 map, and in none of TIGER's corresponding districts.
