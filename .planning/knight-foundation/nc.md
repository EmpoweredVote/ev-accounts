# North Carolina — slice 10 notes

Charlotte and Mecklenburg County. Stages 1 and 2 were complete before this slice opened: North
Carolina has place, `sldu` and `sldl` polygons, and the legislature is seated. **This slice is
stages 3, 4 and 5 only.**

Program tracker: [`PROGRAM.md`](./PROGRAM.md). Spec:
[`2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md).

---

# NC-3 — Charlotte and Mecklenburg County, RESEARCH 2026-09-17. NOTHING WRITTEN TO PRODUCTION.

## Measured starting position

**Charlotte and Mecklenburg County hold nothing.** No government row, no chamber, no office, on
either half. This is a seed, not a repair.

North Carolina's five existing government rows are the state (175 offices) and the two NC deep-seed
jurisdictions — Asheville (7), Durham (7), Buncombe County (10), Durham County (8). None of them is
Charlotte or Mecklenburg.

⚠ **The obvious name query is safe here, but only by luck.** `lower(name) like '%charlotte%'` over
`essentials.governments` returns **zero rows** nationally — there is no Charlotte, Vermont or
Charlotte, Michigan row to trip over, as `%Boulder%` and `%St. Paul%` did in slices 9 and 5. **Match
on `geo_id` anyway.** A later Charlotte elsewhere would silently turn this into the Boulder trap.

| Layer | State |
| --- | --- |
| `geofence_boundaries` G4110 `3712000` "Charlotte city" | ✅ present |
| `geofence_boundaries` G4020 `37119` "Mecklenburg County" | ✅ present |
| `districts` G4020 `37119` Mecklenburg County | ✅ present, **no office attached** |
| **`districts` row for the place `3712000`** | 🔴 **ABSENT — the city wave creates it** |
| NC legislature | ✅ 50 `sldu` + 120 `sldl` boundaries, seated |

⚠ **The place has a BOUNDARY and no DISTRICT row** — the same shape Boulder, Columbus and Macon
presented. A boundary alone is not reachable by address search.

🔴 **`37119` IS TWO DIFFERENT DISTRICTS.** The same `geo_id` string carries `G4020` (Mecklenburg
County) and `G5220` (**State House District 119**, which is Haywood/Swain, 300 miles west). The key
is **(mtfcc, geo_id)** and never `geo_id` alone — a join written on `geo_id` would hand a Mecklenburg
county office to a mountain House district, or the reverse.

### The end-to-end probe, before any writing

Charlotte-Mecklenburg Government Center, 600 E. 4th St. (−80.8390, 35.2226) returns **three**
answers today:

| Layer | Answer |
| --- | --- |
| `G5200` Congressional District 12 | Alma S. Adams |
| `G5210` State Senate District 41 | Caleb Theodros |
| `G5220` State House District 102 | Becky Carney |

No council member, no county commissioner. **The stage-3/4 target for this point is nine answers**
(3 above + Mayor + 4 at-large council + district council member... see the at-large question below).

⚠ **A THIRD AUTHORITY EXISTS AND MUST BE USED.** The Mecklenburg Board of Elections publishes its
own address lookup at `apps.meckboe.org/addressSearch_New.aspx`, linked from the city's own council
page. It is neither the city roster nor the GIS layer, so it is the MN-2 style independent check on
the finished probe.

## The city: Mayor + 11, four of them at-large

From the city's own page, quoted rather than inferred:

> "The mayor and 11 council members make up the Charlotte City Council."
> "Elections for the City Council are held every two years. A citywide vote determines the mayor and
> four at-large council members. Each Charlotte City Council district also elects one council
> member."

So **12 offices**: Mayor (citywide) + 4 At-Large (citywide) + 7 single-member districts. Two-year
terms. This is the Duluth shape — a directly elected mayor plus unnumbered at-large seats plus
districts — not Boulder's all-at-large shape and not Tallahassee's.

⚠ **THE AT-LARGE SEATS ARE UNNUMBERED.** The ballot elects four people to one at-large pool; there
is no "Seat 2". Fort Wayne (3), Duluth (4) and Gary (3) set the precedent for how these are written.

### 🔴 The roster page is stale in a way that matters, and the raw HTML says so

The council page lists all 12 people correctly. But **8 of the 12 member links point at
`charlottenc.prelive.opencities.com`** — the CMS *staging* host — and only Joi Mayo, JD Mazuera
Arias and Kimberly Owens link to `www.charlottenc.gov`. Those three are exactly the three members
who took office in December 2025. The pattern is a content migration that never re-pointed the
older bios, not a roster error, but it is a reminder that **this page is a rendering, not a record**.

### The record is a PDF, and it is the best source this slice has found

`mayor-council-history-1991-2027.pdf` (233,301 bytes, complete — `%PDF-1.7` … `%%EOF`, byte count
matches `content-length`) gives, for every two-year term since 1991: date elected, **date sworn in**,
term length, expiration, and a footnote for **every mid-term resignation and appointment**.

🔴 **IT IS 403 TO `curl` WITH A BROWSER USER-AGENT**, and `curl` happily wrote the 537-byte WAF error
page into a file named `.pdf`. Fetched in Playwright instead, via an in-page `fetch` on the
**`www.`** host — the bare `charlottenc.gov` host is a different origin and CORS blocks it.

### Occupancy, with continuity walked back term by term

**Every start below is the beginning of CONTINUOUS occupancy of THAT office**, per the CO-3 rule —
not the member's first-ever election, and not the current term's start.

| Seat | Holder | Continuous since | Why that date |
| --- | --- | --- | --- |
| Mayor | Rob Harrington (D) | **2026-07-01** | Appointed by Council 2026-06-22; Lyles resigned effective 2026-06-30 |
| At-Large | Dimple Ajmera (D) | 2017-12-04 | At-large since then; her Jan-2017 seat was **District 5**, a different office |
| At-Large | LaWana Mayfield (D) | 2022-09-06 | **Out of office entirely 2019–2022**; before that District 3 |
| At-Large | James Mitchell Jr. (D) | 2022-09-06 | 🔴 **Resigned the at-large seat effective 2021-01-11**; returned in 2022 |
| At-Large | Victoria Watlington (D) | 2023-12-04 | District 3 before that |
| District 1 | Danté Anderson (D) | 2022-09-06 | Egleston held D1 through 2021 |
| District 2 | Malcolm Graham (D) | 2019-12-02 | Harlow held D2 through 2019 |
| District 3 | Joi Mayo (D) | 2025-12-01 | New |
| District 4 | Reneé Perkins Johnson (D) | 2019-12-02 | Phipps held D4 through 2019 |
| District 5 | Juan Diego "JD" Mazuera Arias (D) | 2025-12-01 | New |
| District 6 | Kimberly Owens (R) | 2025-12-01 | New |
| District 7 | Ed Driggs (R) | 2013-12-02 | Cooksey held D7 through 2013 |

🔴🔴 **JAMES MITCHELL IS THE ENTRY THAT PROVES THE RULE.** He has been an at-large member on and off
since 2013. A roster read, or a "first elected" field, would have dated him to 2013 or 2015. He
**resigned effective 2021-01-11** and Gregory Phipps was appointed to the vacancy — so his current
occupancy begins in 2022, and only the term-by-term walk shows it.

🔴 **THE MAYOR TURNED OVER MID-TERM AND THE PRESS AND THE CITY DISAGREE ON THE TITLE.** Vi Lyles won
a fifth term in November 2025, announced her resignation on 2026-05-07 effective 2026-06-30, and the
Council elected Rob Harrington on 2026-06-22 from 114 applicants. Every news outlet calls him
**"interim mayor"**. The city's own page calls him **"Mayor Rob Harrington, the 60th mayor of
Charlotte"**, appointed by the Council, and the history PDF says he "was elected by City Council to
serve the remainder of her term". **The office is `Mayor`.** Under N.C.G.S. the appointee holds the
office for the unexpired term; "interim" is journalism, not the seat. This is the ballot-truth rule
from migration `1863` pointing the *other* way — there, a rotated designation was being written as
an office; here, a real officeholder is being described as a temp.

⚠ **ONE DATE IS STILL UNPROVEN.** Harrington's swearing-in of **2026-07-01** comes from news
coverage, not from the city. The history PDF footnote gives the Council vote date but not the
swearing-in. Either find it in the Council's own minutes or write **2026-07-01 at `day`** only if a
city source confirms it; otherwise `2026-07` at `month` precision. **Do not guess a day.**

### 🔴 A holdover question the schema will force an answer to

There was **no 2021 municipal election**. The 2019 term expired 2021-12-06; the delayed election ran
2022-07-26 and members were sworn 2022-09-06 — nine months later. The PDF's own footnote:

> "Municipal elections were delayed until July 2022 after the COVID-19 pandemic delayed US Census
> data needed to redraw City Council district maps."

Incumbents held over under North Carolina law. **Recommendation: treat occupancy as continuous
across that gap** — so Graham and Johnson carry 2019-12-02 and Driggs carries 2013-12-02, as tabled
above. The alternative (a closed term plus a new one) asserts a nine-month vacancy that did not
happen. **Decide this explicitly in the migration comment**, because it is invisible afterwards.

## The county: nine commissioners, and the Buncombe template does NOT transfer

> "The BOCC consists of nine commissioners - six representing districts and three elected at-large -
> that are elected in November of even-numbered years."

Six single-member districts + three at-large. **Current term sworn in Monday, 2024-12-02**, 6 p.m.,
in the same building as the city council.

| Seat | Holder | First elected (NOT a term start) |
| --- | --- | --- |
| At-Large | Leigh Altman (Vice Chair) | 2020 |
| At-Large | Arthur Griffin | 2022 |
| At-Large | Yvette Townsend-Ingram | 2024 |
| District 1 | Elaine Powell | 2018 |
| District 2 | Vilma D. Leake | 2008 |
| District 3 | George Dunlap | 2008 |
| District 4 | Mark Jerrell (Chair) | 2018 |
| District 5 | Laura Meier | 2020 |
| District 6 | Susan Rodriguez-McDowell | 2018 |

🔴🔴 **THE CHAIR IS ELECTED BY THE BOARD, NOT BY THE VOTERS — SO IT IS A DESIGNATION, NOT AN OFFICE.**
Buncombe County, already seated, carries a distinct `Chair, Board of Commissioners` office because
**Buncombe's chair is elected countywide**. Mecklenburg's is chosen by the nine members immediately
after the swearing-in. Writing a tenth "Chair" office here would invent a seat. This is the
"describe real powers, do not make municipalities uniform" rule, inside one state.

🔴 **"FIRST ELECTED IN YYYY" IS NOT A TERM START AND MAY NOT EVEN BE CONTINUOUS.** It is the county's
own biography field. Leake and Dunlap both read 2008. The Mitchell case above is exactly what that
field cannot show. **The BOCC publishes a `past-and-present-commissioners` page — walk it** the way
the city's PDF was walked, before dating anybody.

▶ **STILL UNMEASURED: the separately elected county officers.** Buncombe and Durham each carry an
`Elected Officials` chamber with **Sheriff, Register of Deeds and Clerk of Superior Court**. That is
the starting question for Mecklenburg, **not the answer** — confirm each from the county's own
pages, and confirm nothing else is separately elected. Sheriff and Register of Deeds are four-year
terms elected in the gubernatorial/presidential cycle, so their current holders were elected in
**November 2022** and the next election is **November 2026** — within weeks of this slice.

## Geometry: four competing city layers, one county layer

### City council districts — all three live layers agree on attributes

| Layer | Owner | Features |
| --- | --- | --- |
| `gis.charlottenc.gov/arcgis/rest/services/PLN/CouncilDistricts/MapServer/0` | **CharlotteNC (the city)** | 7 |
| `meckgis.mecklenburgcountync.gov/.../CharlotteCityCouncilDistricts/FeatureServer/0` | MecklenburgCoNC (county copy) | 7 |
| `services.arcgis.com/9Nl857LBlQVyzq54/.../CouncilDistricts/FeatureServer/0` | CharlotteNC (AGOL) | 7 |
| `SOTC_Charlotte_City_Council_Districts_2017` | forcharlotte_admin | 🔴 **2017 — superseded, do not use** |

All three live layers carry a `DistrictRep` field, and **all three name the current members,
including the three sworn in December 2025** (Mayo, Mazuera Arias, Owens). So all three are
attribute-fresh.

🔴🔴 **THAT PROVES NOTHING ABOUT THE GEOMETRY.** Duluth published two district layers that both
returned five features numbered 1–5 and differed by 8.68 sq mi. **The next step is a geometry
comparison, not a count** — and per the standing rule, two digitizations of one boundary need a
**tolerance after `ST_MakeValid`**, never `ST_Equals`. Precedent (Milledgeville) says the **city's
own layer supersedes the county's copy** when they differ; confirm rather than assume, and expect
the current plan to be the **2022 redistricting**, the one the delayed July 2022 election used.

⚠ A fourth copy exists under a private vendor's AGOL org (`precisionsafesidewalks.com`). Ignore it.

### County commissioner districts — one layer, 6 features

`meckgis.mecklenburgcountync.gov/.../MecklenburgCountyCommissionerDistricts/FeatureServer/0`, fields
`longname` / `shortname` / `cc_name` / `cc`, and its six `cc_name` values match the BOCC roster
exactly (Powell, Leake, Dunlap, Jerrell, Meier, Rodriguez-McDowell).

⚠ **Do the tiling check against the county polygon**, and expect the MN-4 answer: a single coverage
percentage is not a gate. Decompose any gap.

## Stage 5 — assets

🟢 **THE CITY PUBLISHES OFFICIAL HEADSHOTS AND OFFERS THEM FOR DOWNLOAD.** The mayor's page carries
"Download Mayor Harrington's Headshot (JPG, 247KB)" and a 1000×1000 portrait at
`.../images/city-council/council-home/mayor-rob-harrington.jpg`. An explicit download offer from the
body itself is the strongest licence signal available short of a written grant — the opposite of the
Minnesota House's published refusal. **Check every member page for the same offer before sourcing
anywhere else.**

▶ **Banner: not started.** Charlotte's skyline is the obvious composition and therefore the one to
check first against adjacency — confirm what the NC state banner uses before composing.

## ▶ Owed before NC-3 can be written

1. Harrington's swearing-in date from a **city** source, or month precision.
2. The BOCC `past-and-present-commissioners` walk, for nine continuity-proved start dates.
3. The separately elected Mecklenburg officers — which ones exist, and who holds them.
4. The council-district **geometry** comparison across the three live layers.
5. The commissioner-district tiling check.
6. A change-check on all 21 people: **has this person LEFT?**, against each body's own roster.
