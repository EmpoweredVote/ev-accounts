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

---

# NC-3 research, PART TWO — the six owed items, ALL CLOSED 2026-09-17. STILL NOTHING WRITTEN.

## 1. ✅ The mayor's start date, from a city source

`charlottenc.gov/City-News/Rob-Harrington-Sworn-In-as-Charlotte-Mayor`, **published 2026-07-01**:

> "Rob Harrington was officially sworn in as the 60th Mayor of the City of Charlotte during a
> ceremony held at the Charlotte-Mecklenburg Government Center **this morning**. … Harrington was
> appointed by Charlotte City Council to serve the remainder of Vi Lyles' term. Lyles … stepped down
> effective June 30. … Harrington will serve through December 2027."

**`term_start` = 2026-07-01, `day` precision.** No guess, and the earlier news-sourced date is now
confirmed by the city itself. The city again calls him **Mayor** and **the 60th mayor** — never
"interim", which is the press's word. The office is `Mayor`.

## 2. ✅ The BOCC continuity walk — and it caught an appointment the roster hides

`bocc.mecknc.gov/past-and-present-commissioners` publishes the full board for every term back to 1938,
with exact start and end dates. Walked term by term from 2004:

| Seat | Holder | Continuous since | Evidence |
| --- | --- | --- | --- |
| At-Large | Leigh Altman | **2020-12-08** | absent from the 2018 board |
| At-Large | Arthur Griffin | **2022-12-06** | absent from the 2020 board |
| At-Large | Yvette Townsend-Ingram | **2024-12-02** | new; replaced Patricia Cotham |
| District 1 | Elaine Powell | **2018-12-03** | Jim Puckett held D1 through 2018 |
| District 2 | Vilma D. Leake | **2008-12-01** | Norman A. Mitchell, Sr. held D2 through 2008 |
| District 3 | George Dunlap | 🔴 **2008-10-31** | see below |
| District 4 | Mark Jerrell | **2018-12-03** | Dumont Clarke held D4 through 2018 |
| District 5 | Laura J. Meier | **2020-12-08** | Susan B. Harden held D5 through 2020 |
| District 6 | Susan Rodriguez-McDowell | **2018-12-03** | Bill James held D6 through 2018 |

🔴🔴 **GEORGE DUNLAP DID NOT START WITH AN ELECTION.** The board's own 2006–2008 entry reads:

> "Valerie C. Woodard (D) District 3 (Deceased – Died 10-3-08) · George R. Dunlap (D) District 3
> (**Effective 10-30-08 Sworn-in 10-31-08**)"

He was **appointed to fill a vacancy caused by a death**, six weeks before the term that the BOCC's own
biography field — "First elected in 2008" — would imply. His continuous occupancy begins
**2008-10-31**, not 2008-12-01.

**This is the Charlotte Mitchell case mirrored.** There, "first elected" *overstated* tenure by hiding a
resignation; here it *understates* by hiding an appointment. **In both directions the biography field is
not a term start, and only the term-by-term walk gives one.**

## 3. ✅ What Mecklenburg elects separately — and a FOURTH officer the NC template does not carry

Each confirmed on the office's own site today, not from an aggregator:

| Office | Holder | Source |
| --- | --- | --- |
| Sheriff | **Garry L. McFadden**, "45th Sheriff" | `mecksheriff.com` |
| Register of Deeds | **The Honorable Fredrick Smith**, "first elected to office in 2016" | `deeds.mecknc.gov/Fredrick-Smith` |
| Clerk of Superior Court | **Elisa Chinn-Gary** | `mecklenburgcountycourt.org` |
| 🔴 District Attorney | **Merriweather**, "District Attorney in 2017" | `charmeckda.com` |

The first three are exactly the `Elected Officials` chamber Buncombe and Durham carry. **The District
Attorney is the one that does not fit.** `charmeckda.com` bills itself as "District Attorney's Office ·
**NC Prosecutorial District 26** · Mecklenburg County" — the district is coterminous with the county and
Mecklenburg's voters elect the post, so by geography it belongs; but it is a **state judicial-branch
officer**, not a county officer, and **neither Buncombe nor Durham carries one**.

▶ **DECISION OWED, and it is a PROGRAM question, not a Charlotte one.** Adding a DA here alone makes
Mecklenburg non-comparable with the two NC counties already seated; adding it everywhere is its own
wave. **Recommendation: follow the Buncombe/Durham template — three officers, no DA — and open the DA as
a separate question.** Do not resolve it by silently inheriting either answer.

⚠ **The officers' term starts are NOT yet dated.** Item 3 asked which offices exist and who holds them.
Smith's "first elected in 2016" plus North Carolina's statutory first-Monday-in-December start implies
2016-12-05, **but that is an inference and this file will not launder it into a source.** Date all of
them from the county's or the courts' own records at write time, or ship at `month`/`year` precision.

## 4. ✅ Council-district geometry — the three live layers are the SAME plan

Loaded all three into PostGIS, `ST_MakeValid`, and measured the symmetric difference per district:

| District | city layer (sq mi) | vs county copy | vs AGOL copy |
| --- | --- | --- | --- |
| 1 | 33.4573 | 0.0138 (0.041%) | 0.0138 (0.041%) |
| 2 | 49.3855 | 0.0313 (0.063%) | 0.0313 (0.063%) |
| 3 | 68.6680 | 0.0295 (0.043%) | 0.0295 (0.043%) |
| 4 | 43.9999 | 0.0304 (0.069%) | 0.0304 (0.069%) |
| 5 | 40.3303 | 0.0190 (0.047%) | 0.0622 (**0.154%**) |
| 6 | 38.1601 | 0.0106 (0.028%) | 0.0106 (0.028%) |
| 7 | 41.2582 | 0.0147 (0.036%) | 0.0147 (0.036%) |

**The worst disagreement is 0.154% of one district.** This is digitisation noise across three copies of
one plan — not Duluth, where two layers differed by 8.68 sq mi. ✅ **Use the city's own layer**
(`gis.charlottenc.gov/.../PLN/CouncilDistricts/MapServer/0`), per the Milledgeville precedent that a
city's own layer supersedes the county's copy. ✅ **The 7 districts do not overlap each other** — no pair
shares more than 1,000 m².

### The place-coverage gap is 1,820 slivers, and that is the right answer

The 7 districts cover **99.8423%** of TIGER place `3712000`: **0.4945 sq mi of the place uncovered** and
**2.1651 sq mi of districts outside the place**. Per MN-4 a single percentage is not a gate, so the gap
was decomposed:

- The uncovered area is **1,820 separate pieces**.
- The **largest is 0.02798 sq mi** (72,479 m²), with a thinness (area ÷ perimeter²) of **0.00278**
  against **0.0796** for a circle — about **29× thinner than compact**.
- The five largest all score 0.0009–0.0055. **Every one is a long thin edge artefact.**

So this is two digitisations of one city limit — the city's own, which tracks annexations, against
TIGER's vintage — exactly the case the standing rule says needs a **tolerance, not `ST_Equals`**. It is
not a hole where residents sit unrepresented. ▶ The real test is still the address probe with a
per-district control, at write time.

## 5. ✅ Commissioner districts tile the county

The 6 districts cover **99.9966%** of Mecklenburg `37119`: 0.0188 sq mi uncovered, 0.0190 sq mi outside.
**No two overlap.** ✅ **Per-district control: 6 of 6** — an interior point of each district is covered by
exactly one district, never zero and never two.

## 6. ✅ Change-check on all 21, with controls that fired

**All 12 council members and all 9 commissioners**: the page returns 200, **names the member it should**,
and carries no resignation, vacancy, "former", "no longer" or expired-term wording. Nobody has left.

The uniform zero-flag answer was not trusted on its own:

- **Control A — the regex.** Run against `"…Bokhari resigned effective April 20, 2025, creating a
  District 6 vacancy. Term Expires January 2026."` it returns `resigned`, `vacancy`, `Term Expires`. The
  detector works.
- **Control B — people who actually left.** `Vi Lyles` → **404**. `Edwin Peacock` → **404**. Patricia
  Cotham on the county site → **404**. Departed officials are removed, so a 200 carries information.

### 🔴🔴 AND CONTROL B CAUGHT SOMETHING: A DEPARTED MEMBER'S URL CAN SERVE HIS SUCCESSOR

`/City-Council/Tariq-Bokhari` — who resigned on 2025-04-20 — returns **HTTP 200**. It is not a stale
page. It serves **Kimberly Owens'** page: same `<title>`, same `rel=canonical`
(`…/City-Council/Kimberly-Owens`), byte-identical at 286,684 bytes, and the text names Owens and never
names Bokhari. **The city recycles the District 6 slug to whoever holds the seat.**

**A change-check that asks "does this person's page still resolve?" would report Bokhari as sitting.**
The check must assert that the page **names the person**, which is why `names_self` is in the sweep and
why this was caught rather than shipped. Same family as the Duluth `with-seal` filter and the
`%Boulder%` match: **the request succeeded, so the failure is silent.**

## ▶ What is genuinely left before the migrations

1. **Date the county officers** (item 3's caveat) — or ship them at `month`/`year` precision.
2. **The District Attorney decision** — a program-level call, recommended above.
3. The **holdover decision** for 2021-12-06 → 2022-09-06 (recommended: continuous), stated explicitly in
   the migration comment.

---

# NC-3 — THE INCLUSION RULING (Cantrell, 2026-09-17) and what it changed

> **"If you vote on the DA, they should be included, otherwise they should be omitted."**

**The electorate decides inclusion.** An office is seated if the voters of that jurisdiction elect it,
and omitted if they do not. This settles the District Attorney — Mecklenburg's voters elect it — and it
is the same principle as CO-3's *the assertion follows the electorate*, applied to which offices exist
rather than to how many answers a probe should return.

⚠ **It reaches further than the DA, so the ballot was enumerated rather than guessed.** From the
Mecklenburg Board of Elections' own `2026-offices-ballot-and-filing-fees`, county voters elect: County
Commissioner (3 at-large + 6 district), Clerk of Superior Court, Sheriff, **District Attorney**, **Soil
& Water Conservation District Supervisor**, **District Court Judge** and **Superior Court Judge**
(sub-districts 26-C, 26-F, 26-H). Register of Deeds is elected too, on the presidential cycle.

## Scope decided with the ruling (Cantrell, 2026-09-17)

- **NC-3 seats the DA and the elected Soil & Water supervisors.** Both are countywide, so they need no
  new geometry — they hang off the county polygon exactly as the Sheriff does.
- **Judges become their own wave, covering every NC county.** Three measured reasons: Superior Court
  sits in **sub-county districts whose geometry production does not have** (an office without geometry
  is unreachable — the Gary precedent, where the gate asserted the seats' *absence*); the **bench size
  must come from G.S. 7A-41**, not a ballot page, since 9 District Court seats being *up* in 2026 means
  the bench is larger; and the **Board of Elections and the statute disagree on the Superior Court
  sub-district labels** (26-C/26-F/26-H against 26A/26B/26C), which must be resolved before anything is
  written.
- 🔴 **BUNCOMBE AND DURHAM NOW CARRY A MEASURED DEBT.** Both are already seated with three officers and
  no DA, no Soil & Water and no judges, and their voters elect all of them. **Production holds no
  district attorney, no judge and no soil-and-water office anywhere in North Carolina** — measured, not
  assumed. Decision: **record the debt now, close it in the judges wave**, so all NC counties get one
  consistent treatment in one pass.

## 🔴🔴 THE SOIL AND WATER BOARD IS 5 PEOPLE AND ONLY 3 ARE ELECTED

The district's own page, quoted:

> "Each soil and water conservation district is administered by a five person board of supervisors.
> **Three of these supervisors are elected** at the same time as the regular election of county
> officers. This election is nonpartisan and is conducted by the respective county board of elections.
> **Two supervisors are appointed** by the North Carolina Soil and Water Conservation Commission…
> All five supervisors serve four year terms of office."

Under the ruling the two appointed supervisors are **omitted**: **Daniel Austin** (appointed 2023-07-19)
and **Eliseo Pascual** (appointed 2025-05-27). This is the ruling doing real work — it removes two
sitting members of a real board, because nobody votes for them.

🔴🔴 **AND THE PAGE'S PER-PERSON LABEL DESCRIBES HOW SOMEONE ARRIVED, NOT WHAT THEY ARE NOW.**
**Nancy Carter** reads "appointed to the Board in January, 2012, **elected in 2014**". Taking that first
word as her status would omit her — and would leave **two** elected supervisors against a statutory
**three**. **The count is the check**: the statute says 3, so any reading that yields 2 is wrong. Same
family as the `is_vacant` trap — a field that looks like a status is a history.

| Supervisor | Elected? | Continuous since | Precision | Source wording |
| --- | --- | --- | --- | --- |
| Barbara Bleiweis (Chair) | ✅ elected | 2017 | `year` | "served on the Board since 2017 and is in her second term as an elected Supervisor" |
| Nancy Carter (Vice-Chair) | ✅ elected | 2012-01 | `month` | "appointed to the Board in January, 2012, elected in 2014" |
| Mitchell Mullen | ✅ elected | **2024-12-04** | `day` | "will serve a four-year term effective December 4, 2024" |
| Daniel Austin | ❌ appointed | — | — | **OMITTED** — "appointed … July 19, 2023" |
| Eliseo Pascual | ❌ appointed | — | — | **OMITTED** — "appointed … May 27, 2025" |

⚠ Their own page spells him "Mitchel" once and "Mitchell" twice. Use **Mitchell Mullen**.

## The county's separately elected officers, dated to the precision each source supports

| Office | Holder | Continuous since | Precision | Source |
| --- | --- | --- | --- | --- |
| Sheriff | Garry L. McFadden | 2018 | `year` | `mecksheriff.com` — "45th Sheriff"; first elected 2018 |
| Register of Deeds | Fredrick Smith | 2016 | `year` | "Fred was first elected to office in 2016" |
| Clerk of Superior Court | Elisa Chinn-Gary | 2014 | `year` | first elected November 2014; sworn for a second term 2018-12-03 |
| **District Attorney** | **Spencer B. Merriweather III** | **2017-11-27** | `day` | `charmeckda.com/about-the-da` — "sworn into office on November 27, 2017, and he was subsequently elected in 2018" |

🔴 **THREE OF THE FOUR SHIP AT `year` PRECISION ON PURPOSE.** North Carolina seats county officers on
the first Monday in December, and the BOCC's own page gives that exact date for every term — so
2018-12-03, 2016-12-05 and 2014-12-01 are all *available as an inference*. **They are not written as
facts.** The rule is "don't invent dates": the sources say a year, so the rows say a year. Day
precision is a five-minute lookup in the county's or the courts' own records if it is ever wanted.

## The shape NC-3 will write

| Government | Chamber | Offices |
| --- | --- | --- |
| City of Charlotte | City Council | **12** — Mayor + 4 at-large + 7 districts |
| Mecklenburg County | Board of County Commissioners | **9** — 3 at-large + 6 districts |
| Mecklenburg County | Elected Officials | **4** — Sheriff, Register of Deeds, Clerk of Superior Court, District Attorney |
| Mecklenburg County | Soil and Water Conservation District | **3** — elected supervisors only |

**28 offices, 28 people, 0 vacancies.**

⚠ **Two modelling decisions, stated rather than inherited.** The **District Attorney** goes in
`Elected Officials` beside the Clerk of Superior Court, because both are judicial-branch officers whom
county voters elect, and the Clerk is already there in Buncombe and Durham. The **Soil and Water**
supervisors get their **own chamber** rather than being folded into `Elected Officials`, because the
district is legally "a governmental subdivision of the state of North Carolina, and a public body,
corporate and politic" — not part of county government — and the chamber name is where that fact can
live. Both hang off the county polygon `(G4020, 37119)`.

---

# NC-3 — APPLIED 2026-09-17. 28 offices, 28 people, 0 vacancies. Stage 3 AND stage 4 closed.

`CC_0117` (structure) + `CC_0118` (occupancy), preceded by
`scripts/load-charlotte-mecklenburg-boundaries.ts` (X0056, X0057). Charlotte and Mecklenburg County
went from **nothing** to fully seated and reachable by address.

| Government | Chamber | Offices | Seated |
| --- | --- | --- | --- |
| City of Charlotte | Charlotte City Council | 11 | 11 |
| City of Charlotte | Office of the Mayor | 1 | 1 |
| Mecklenburg County | Board of County Commissioners | 9 | 9 |
| Mecklenburg County | Elected Officials | 4 | 4 |
| Mecklenburg County | Soil and Water Conservation District | 3 | 3 |

## ✅ The probe: 3 answers → 20

Charlotte-Mecklenburg Government Center, 600 E. 4th St. returned **three** answers before this wave
and returns **twenty** after — 17 of them from NC-3, plus the three federal and state seats that were
already there. **Exactly one council district (Danté Anderson) and exactly one commissioner district
(Mark Jerrell)**, which is the assertion that matters; the other 15 are citywide or countywide seats
and every address in the jurisdiction is meant to get all of them.

✅ **PER-DISTRICT CONTROL: 13 of 13.** An interior point of every council and commissioner district
resolves to exactly one office and to the holder the roster names — never zero, never two. Accents
render (`Danté Anderson`, `Reneé Johnson`).

✅ **NEGATIVE CONTROLS, and the answer shrinks correctly as you leave each jurisdiction:**

| Anchor | council dist | citywide | comm dist | countywide | NC-3 answers |
| --- | --- | --- | --- | --- | --- |
| Charlotte City Hall | 1 | 5 | 1 | 10 | **17** |
| Huntersville — in the county, outside the city | 0 | 0 | 1 | 10 | **11** |
| Gastonia — outside the county | 0 | 0 | 0 | 0 | **0** |

⚠ **The Gastonia row was non-zero on the first attempt and the data was fine.** A `LEFT JOIN` that
keeps office-less rows counted Gaston County's own boundary as an answer. **The probe was wrong, not
the seed** — which is why the corrected query counts `office_id`, and why the saved probe file
carries that warning.

## ✅ 🔴 A THIRD AUTHORITY AGREES, AND IT IS NEITHER OF OUR SOURCES

The Mecklenburg Board of Elections runs its own address lookup at `apps.meckboe.org`, which is
neither the GIS layers this wave loaded nor the rosters it seated. For **600 E 4TH ST 28202** it
returns:

> CONGRESSIONAL DISTRICT 12 · NC SENATE DISTRICT 41 · NC HOUSE DISTRICT 102 · JUDICIAL DISTRICT 26 ·
> SUPERIOR COURT DISTRICT 26E · **BOARD OF COMMISSIONERS DISTRICT 4** · SCHOOL BOARD DIST 2 ·
> CHARLOTTE · **CITY COUNCIL DISTRICT 1**

**Every district assignment matches.** This is the MN-2 shape of evidence: a body that had no part in
producing our answer produced the same one.

✅ `check:reachability` — **nothing regressed**, every bucket at or below baseline
(`BAD_GEOMETRY` 4 of 5, `DEAD_GEOGRAPHY` 17 of 17, `UNREACHABLE` 37 of 38).

## 🔴 Two things that output says about the JUDGES wave

1. **"SUPERIOR COURT DISTRICT 26E" is a THIRD labelling.** The Board of Elections' ballot page says
   26-C / 26-F / 26-H; the statute search returned 26A / 26B / 26C; the address lookup says 26E.
   Three sources, three vocabularies, for the same sub-county judicial geography. **Resolve this from
   G.S. 7A-41 before writing a single judicial office.**
2. **"SCHOOL BOARD DIST 2" is another elected body the inclusion ruling reaches.** Charlotte-
   Mecklenburg Schools' board is elected by these voters and production carries no school board
   office for it. Add it to the same debt as the DA/Soil-and-Water backfill for Buncombe and Durham.

## Gates, and the two that refused their author

**Loader:** four gates pass on live data (count and numbering, roster-vs-layer names, coverage,
mutual overlap) and **all five controls refuse a wrong input**.

🔴 **The sharpest control had to be rebuilt.** The obvious input — Charlotte's own superseded
`SOTC_..._2017` layer — answers **499 "Token Required"** and cannot be fetched. It was also the wrong
*shape* of control: one that depends on a third party staying public can start passing for the wrong
reason the day that service changes. The replacement relabels the live layer with the **real
2023-2025 council**. It returns seven features numbered 1-7, so the count gate passes it, and exactly
**3 of 7 seats expose it** — the three that turned over in December 2025.

🔴 **THE PRECISION GATE REFUSED ITS OWN AUTHOR.** `CC_0118` was written asserting 24 day-precision
terms. The dry run failed: `expected 24 day-precision terms, got 23`. Barbara Bleiweis ships at
`year` and had been counted as a day. The gate now asserts **all three buckets — 23 day, 4 year,
1 month** — rather than one. A gate that checks a single bucket can be satisfied by a compensating
error in another.

## Applied counts, measured from outside

- `governments` +2, `chambers` +5, `districts` +14 (13 new district rows plus the Charlotte citywide
  row; the Mecklenburg county row was **reused**, not duplicated)
- `geofence_boundaries` +13 (X0056 ×7, X0057 ×6)
- `politicians` +28, `office_terms` +28, **28 seated counting `och.politician_id`**
- Buncombe (10) and Durham (8) office counts **unmoved**, asserted by the gate
- State House District 119 still holds **exactly 1** office, asserted by the gate — it shares the
  geo_id `37119` with Mecklenburg County and only the MTFCC separates them

## ▶ What NC-3 still owes

1. **Stage 5: headshots and a banner.** Not started. The city publishes official headshots with an
   explicit download link, which is the strongest licence signal short of a written grant — check
   every member page for it before sourcing anywhere else. Charlotte's skyline is the obvious banner
   and therefore the first thing to test against adjacency.
2. **Day precision for four county officers**, if it is ever wanted — a lookup in the county's and
   the courts' own records.
3. The **judges wave**, carrying the Buncombe/Durham DA and Soil-and-Water backfill, the school
   board question, and the 26-C/26A/26E labelling conflict.

---

# ▶ RESUME STAGE 5 HERE (written 2026-09-17, before clearing context)

Stages 3 and 4 are applied and merged-pending. **Stage 5 — headshots and a banner — has not started.**

| | |
| --- | --- |
| Worktree | `/c/ev-accounts-nc-3` (branch `data/nc-3-charlotte-mecklenburg`) |
| PR | **#534**, open against master |
| Leases | `place:3712000` and `county:37119`, both to 2026-09-18 18:00Z — **`extend` them, don't re-take** |
| Roster | `backend/data/charlotte-mecklenburg-roster.json` — all 28 with seats, dates and sources |
| Probe | `backend/scripts/verify-charlotte-mecklenburg-probes.sql` |

⚠ `npm install` has already been run in that worktree's `backend`. A different worktree will need it
again before any `tsx` script runs.

## The 28 who need portraits

12 Charlotte (Mayor + 4 at-large + 7 district) and 16 Mecklenburg (9 commissioners + Sheriff,
Register of Deeds, Clerk of Superior Court, District Attorney + 3 soil-and-water supervisors). **All
28 are new rows with no `photo_custom_url`** — the wave is a clean import, not a repair.

## The sourcing lead, and why it is strong

🟢 **The city publishes official headshots and OFFERS THEM FOR DOWNLOAD.** The mayor's page carries
"Download Mayor Harrington's Headshot (JPG, 247KB)" beside a 1000×1000 portrait at
`www.charlottenc.gov/files/sharedassets/city/v/2/city-government/leadership/images/city-council/council-home/mayor-rob-harrington.jpg`.
An explicit download offer from the body itself is the strongest licence signal short of a written
grant. ▶ **Check every one of the 12 council pages for the same offer before sourcing anywhere else.**

🔴 **`charlottenc.gov` is 403 TO `curl` EVEN WITH A BROWSER USER-AGENT.** Fetch in Playwright, using
an in-page `fetch` on the **`www.`** host — the bare `charlottenc.gov` host is a different origin and
CORS blocks it. This is how the council history PDF was retrieved.
⚠ **8 of the 12 council member links point at `charlottenc.prelive.opencities.com`**, the CMS staging
host. Rewrite them to `www.charlottenc.gov` on the same path.
🔴 **A departed member's URL can serve their successor** — `/City-Council/Tariq-Bokhari` returns 200
and is byte-identical to Kimberly Owens' page. Assert the page NAMES the person before taking an
image from it.

The county side is unmeasured: `bocc.mecknc.gov` member pages, `mecksheriff.com`,
`deeds.mecknc.gov`, `mecklenburgcountycourt.org`, `charmeckda.com`, `conserve.mecknc.gov/Board`.

## The pipeline (do not re-invent it)

1. Build a candidates JSON — the shape is in `backend/data/seed-mn-headshots-2026/candidates-house.json`.
2. `py scripts/render-headshot-contact-sheet.py --json <file> --title "..." --out <file>.html`
   (add `--embed-width 300` only if the artifact would exceed 16 MB; 28 faces will not).
3. **Publish the sheet as an Artifact and get batch approval. Never one dialog per person.**
4. `py scripts/import-headshot-candidates.py --json <file>` — it writes the object, the
   `politician_images` row, `photo_custom_url` and `photo_origin_url`. **No migration is needed.**
5. Verify from OUTSIDE: re-fetch every stored URL from the CDN and **decode** it, with a bogus bucket
   key alongside that must fail.

## The banner

Not started. Charlotte's skyline is the obvious composition and therefore the first thing to test for
**adjacency** — read what the North Carolina state banner uses before composing, and check the
Asheville and Durham keys, since both are already in the essentials repo. Banners live in the
**essentials** repo (`buildingImages.js`), not in this one.

---

# NC-3 STAGE 5a — HEADSHOTS APPLIED 2026-09-17. 27 of 28, verified from the CDN.

Approved on one contact sheet (`https://claude.ai/code/artifact/968660c0-6cb2-47d3-ba5e-c75ad4905f25`),
imported with `scripts/import-headshot-candidates.py`. **No migration** — the pipeline writes the
storage object, the `politician_images` row, `photo_custom_url` and `photo_origin_url` directly.

| Cohort | Seats | Portraits | Source |
| --- | --- | --- | --- |
| Charlotte — Mayor and City Council | 12 | **12** | `charlottenc.gov`, 1000×1000 originals |
| Mecklenburg — Board of County Commissioners | 9 | **9** | `bocc.mecknc.gov` / `mecknc.widen.net` DAM, 1400–1640 × 2048 |
| Mecklenburg — Elected Officials | 4 | **3** | `mecksheriff.com`, `deeds.mecknc.gov`, `charmeckda.com` |
| Mecklenburg — Soil and Water | 3 | **3** | Ballotpedia, candidate-submitted |

The record of what was approved is `backend/data/seed-charlotte-2026/headshot-candidates.json`; the
outside-in verifier is `backend/scripts/verify-charlotte-mecklenburg-photos.mjs`.

## ✅ Verified from OUTSIDE, with both controls

`verify-charlotte-mecklenburg-photos.mjs` reads `photo_custom_url` — the field the render path
coalesces first, not the `politician_images` row — then re-fetches each object from the CDN and
**decodes** it.

- **27 decode**, 24 at 600×750 and 3 at native size (Merriweather 387×484, Bleiweis 495×619,
  Carter 240×300). Nothing was enlarged.
- **Negative control:** a bogus bucket key is refused (HTTP 400). It was also proved against a
  **94 KB HTML 200** — `bocc.mecknc.gov`'s own home page does not decode, and a real 109 KB portrait
  does. A control that only ever sees an 88-byte error body has not shown that the decoder reads
  magic numbers.
- **Count control:** the run asserts it read **28 seats and tested 27 objects**. This is the MN-6
  lesson — a verifier can report "0 broken" while testing none of the rows just written, so the
  count is the tell.
- **End to end:** `GET /api/essentials/address-search?address=600 E 4th St, Charlotte, NC 28202` on
  live prod returns 61 politicians, **17 of them NC-3 seats, 16 carrying our CDN portrait** and one
  deliberately blank. That is the whole point of the wave: a voter at City Hall now sees faces.

## 🔴 The sourcing lead was real, but only the MAYOR carries the download offer

The resume note said to check all 12 council pages for the mayor's explicit
"Download … Headshot (JPG, 247KB)" link. **Measured: 1 of 12 has it.** The other 11 pages offer only
a district-map PDF. The 11 are still official `.gov` portraits and ship as press use — but the
"explicit download offer" is a property of the mayor's page alone, not of the city's CMS.

🟢 **`charlottenc.gov` is NOT 403 to `node` fetch.** The resume note said to use Playwright. All 12
pages and all 12 image assets returned 200 to a plain `fetch` with a browser UA, byte-count-matching
what Playwright saw. **`mecksheriff.com` IS 403** — that one needed Playwright, and its bytes were
written straight into `.tmp-headshot-cache` under `sha1(url)`, which the importer reads before it
ever tries the network. **Pre-seeding that cache is the supported way past a WAF**, and it also
guarantees the bytes that shipped are the bytes that were approved.

✅ **The prelive trap and the departed-member trap were both closed by reading all 12 pages.** Eight
roster links point at `charlottenc.prelive.opencities.com`; rewritten to `www.charlottenc.gov` on the
same path, all 200. Every page's own `<title>` and `<h1>` names the person whose portrait it carries.
Four pages use a fuller name form than the roster — `James "Smuggie" Mitchell Jr.`,
`Dr. Victoria Watlington`, `Reneé Perkins Johnson`, `Ed Driggs` — which is the name check passing,
not failing.

## 🔴 THE POSITIONAL-FILENAME RULE FIRED ONCE, AND A SECOND AUTHORITY SETTLED IT

The Sheriff's only in-house portrait is `Sheriff1024.jpg` — the filename names the **office**, and the
page carries no alt text. That is the off-by-one class exactly. It was resolved by comparing it with
Ballotpedia's McFadden photo, whose alt text **names him**: same man. Both were then shown to the
operator with the frame flagged `VERIFY FACE`.

⚠ **The county's group photos are not a fallback.** `Executive-Staff.png` is a single flat 1919×1439
image of the whole command staff, and the BOCC home page serves `-hor` crops at 328×184 — landscape,
useless for a 4:5 portrait. The per-member pages carry the real portraits; the index page does not.

## 🔴 Elisa Chinn-Gary ships BLANK, and that is the correct answer

The Clerk of Superior Court has **no usable portrait at any acceptable source**:
`nccourts.gov/judicial-directory/elisa-chinn-gary` carries no image, Ballotpedia holds only its
silhouette placeholder, and the only photographs found are on Facebook and LinkedIn, which this
programme does not use. A blank keeps her in the headshot backlog, where she belongs; a link would
have counted as coverage.

⚠ **`mecklenburgcountycourt.org` is NOT the Clerk's office.** It ranks well and looks official, and
its page set is a jail roster, court dockets and an FAQ — a third-party records site. No image was
taken from it. The Clerk's authority is `nccourts.gov`.

## The three Soil and Water portraits are a different class, and were approved as such

Ballotpedia candidate-submitted snapshots, not studio portraits: Bleiweis at an event with a
stranger's shoulder at the frame edge, Carter outdoors, Mullen a soft indoor photo. Each Ballotpedia
page names **Mecklenburg** and the **Soil and Water** board, so the identification is sound, and the
operator approved them on the sheet after the quality was stated. Carter's source is 240×320, so the
2.50× upscale was refused and she ships at native size.

## ▶ Stage 5b — THE BANNER, and the constraint nobody has hit before

🔴🔴 **NORTH CAROLINA'S STATE BANNER *IS* THE CHARLOTTE UPTOWN SKYLINE** (`states/NC.jpg`, Bruce
Emmerling, CC BY-SA 4.0). Charlotte is the first city in this programme that is **already the subject
of its own state's panorama** while needing a city banner of its own. Two precedents point opposite
ways and both shipped:

- **Austin → TX:** the state took a different subject (the Chisos Mountains) and the skyline moved
  down to `cities/austin.jpg` byte-for-byte.
- **Nevada:** the state kept the Las Vegas Strip and the city banner is deliberately the Welcome sign
  — one city twice on one page, accepted.

Measured while establishing this, and it changes the adjacency answer:

- `states/NC.jpg` is 1700×540, mean luminance 127.0, not greyscale (channel spread 25.8).
- **In the 6:1 desktop band (rows 128–411) the tower CROWNS ARE CUT OFF.** The band shows a parking
  deck, mid-rise offices and trees at close, ground-level range. The state banner does **not**
  display a recognisable Charlotte skyline where a desktop visitor looks.
- So an **elevated or distant Charlotte frame with the crowns visible** is compositionally different
  from the state band — and also different from Asheville (elevated, mountains dominate) and from
  Durham (wide low-rise with foliage). **Charlotte needs the FOURTH distinct NC composition**; the
  first three are spent.

Facts already established for whichever route is chosen:

- `cities/charlotte.jpg` **does not exist** (HTTP 400). A new key needs no `-v2`; the stale-CDN rule
  applies to overwrites. `states/NC-v2.jpg` does not exist either.
- Charlotte's **12 city offices carry `representing_city = 'Charlotte'`**, so a city banner surfaces
  from an ordinary address search. Mecklenburg's 16 county offices leave it NULL, so a county banner
  would resolve only from `browse_label` — the same shape as Buncombe and Durham.
- Banners live in `C:\Transparent Motivations\essentials`, branch `main`, registry
  `src/lib/buildingImages.js`. **Certify in the 6:1 band, never the full frame.** Real licensed
  photos only — the `banner-design` skill is the wrong tool (D-09).

---

# NC-3 STAGE 5b — BANNER SHIPPED 2026-09-17. `cities/charlotte.jpg`, essentials PR #152.

Certification sheet: `https://claude.ai/code/artifact/4616a8ba-f3a3-493b-8143-5b6272ed326b`

| | |
| --- | --- |
| Photograph | Charlotte Skyline (Panoramio), 10 April 2014 07:39 |
| Author / licence | James Willamor · CC BY-SA 3.0 Unported, read off the Commons File page |
| Source | 3881×1338 (2.90:1) |
| Crop | centre 3000×953 at the bottom edge → LANCZOS to 1700×540, a **0.57× downscale** |
| Candidates | **27** rendered at 1700×540 and read in the 6:1 band |

## 🔴🔴 THE RULING: NEVADA, NOT AUSTIN

North Carolina's state panorama **is** the Charlotte uptown skyline, so Charlotte was the first city
in the programme already serving as its own state's subject. Cantrell chose to **leave
`states/NC.jpg` untouched** and give the city a different composition — the Nevada resolution (state
keeps the Strip, city is the Welcome sign), not the Austin one (state gets a new subject, skyline
moves down to the city).

What made that defensible is a **measurement, not a preference**: in the 6:1 desktop band the state
asset **cuts the tower crowns off**, so a desktop visitor sees a parking deck, mid-rise offices and
trees at close ground level — never a recognisable Charlotte skyline. The shipped frame is distant
and elevated with the Bank of America crown and the Duke Energy wedge whole.

🔴 **CHARLOTTE NEEDED THE FOURTH DISTINCT NC COMPOSITION.** Durham's own note warned that a third
city has fewer framings left than the second; a fourth has fewer still.

| | |
| --- | --- |
| NC state banner | Charlotte uptown → close, ground-level, buildings fill frame |
| Asheville | Beaucatcher Mountain → elevated, mountains dominate |
| Durham | Corcoran Street → wide low-rise with sky and foliage |
| **Charlotte** | **distant elevated skyline, crowns whole** |

## 🔴 Three findings that transfer to the next banner

1. **THE ANCHOR COULD NOT FIX THE FRAME; A NARROWER CROP COULD** — the `states/CA.jpg` correction
   meeting a new case. The source is 2.90:1, **narrower** than the 3.148:1 asset, so a full-width
   crop leaves only **105 rows** of vertical slack: sliding the anchor 0.55 → 1.0 moved the band
   about **19 rendered pixels** while the skyline stayed marooned under two-thirds of empty sky.
   Cropping to 3000px wide raises the slack to 385 rows and is still a downscale.
   **Check the SOURCE ASPECT before assuming an anchor can help.**
2. **TEST COLOUR — it fired for real.** "2010 Charlotte Skyline" measures **channel spread 4.7 of
   255**, i.e. greyscale, against the winner's 56.4. Separately the **CC0** candidate — the most
   permissive licence found — was refused because a highway overpass and a lamp standard cross the
   band and the crowns are cut at every anchor. **The best licence is not the best frame.**
3. 🔴 **FINDING THE CORPUS WAS MOST OF THE WORK, and the Bend lesson repeated exactly.** Seven
   guessed Commons category names returned **0 files**, and a depth-3 recursive walk of the
   `Category:Charlotte, North Carolina` tree drifted into **US-74 highway photography** and surfaced
   no skyline at all. The real category is **`Category:Charlotte skylines` (plural)**, and it was
   found by asking the **one known-good file which categories it belongs to**. ▶ Do that first.

## Verified, not assumed

- **Bytes:** sha256 of the served object is identical to the local file on **both** the plain and a
  cache-busted URL, decoding as 1700×540 JPEG; a key that cannot exist returns HTTP 400 as a control.
  A **new key needs no `-v2`** — the stale-CDN rule applies to overwrites.
- **`match:'exact'` is load-bearing and was PROVED by running `getBuildingImages()`**, not assumed:
  `'charlottesville'.includes('charlotte')` is true, and the matcher treats a missing caller state as
  match-allowed. Charlotte/NC and Charlotte with **no state** both resolve to `cities/charlotte.jpg`;
  **Charlottesville and Port Charlotte resolve to null either way**; an unregistered city returns
  null, which is the control showing the check can fail.
- **People test:** passes because there are no people — at 2× zoom the lower band holds buildings and
  one tree.

⚠ **The one weakness is AGE, and it is recorded rather than hidden.** April 2014: a construction
crane stands in the right third and towers finished since are absent. The standing alternative is
**Wesley Heights connector, February 2024** (City Dweller 2, CC BY-SA 4.0), refused on clutter —
parked cars, utility poles, bare winter trees, a crane across the lower band. Start there if this key
is ever revisited for currency.

## ▶ What NC-3 still owes after stage 5

1. **Day precision for four county officers**, if it is ever wanted.
2. The **judges wave**, carrying the Buncombe/Durham DA and Soil-and-Water backfill, the
   Charlotte-Mecklenburg **school board** question, and the 26-C / 26A / 26E labelling conflict.
3. **Elisa Chinn-Gary's portrait** — she stays on the headshot backlog until an acceptable source
   exists.

---

# ✅ NC-5 APPLIED 2026-09-24 — the legislature is 170 of 170, and NC is the first state in the program where every seated legislator renders from an object we own

**169 imported across two passes, 0 skipped, 0 failed.** North Carolina goes from **1** portrait on
our own CDN to **170**, and from **163** rendering off a third party to **zero**.

| | before | after |
| --- | --- | --- |
| renders from an object we own | 1 | **170** |
| falls back to a third-party `photo_origin_url` | 163 | **0** |
| renders nothing at all | 6 | **0** |

✅ All 170 objects fetched back and confirmed **real JPEGs** (42–145 KB) with a nonexistent-key
control that failed as required, and `photo_origin_url` points at the member's own biography page for
**170 of 170**.

## 🟢 THE LICENCE IS AN EXPLICIT PUBLIC-DOMAIN GRANT, PUBLISHED BY THE CHAMBER ITSELF

`ncleg.gov/Disclaimer`, under **"Use of Photographs and Graphics"**:

> "Photos of House and Senate Members on the individual NCGA Website member webpages are **not
> published on the NCGA Website until we receive copyright release from the photographer** so these
> specific photos are **considered in the public domain** once they are published on the NCGA
> Website."

That is an **affirmative grant**, and the strongest the program has found. It is stronger than Ohio
(which publishes no photo policy at all, so OH-5 shipped on `press_use`) and it is the opposite of
the Minnesota House, whose **published refusal** had to be superseded by a personal grant. It applies
precisely to the member-page photos, which is what all 170 of these are.
▶ **Read the disclaimer, not just the footer.** Every footer on that site says nothing useful;
the grant is three clicks away under a heading about photographs.

## 🔴🔴 THIS WAS A RE-POINTING JOB, NOT A MIRRORING JOB — AND PROFILING IS WHAT SHOWED THAT

The brief was "mirror NC's 163 third-party portraits". Profiling first — the WA rule, where 176 rows
turned out to be 22 distinct URLs — changed what the job was:

| host | rows |
| --- | --- |
| `www.ncleg.gov` | **134** |
| `s3.amazonaws.com` | 12 |
| `storage.googleapis.com` | 5 |
| Squarespace / Wix | 4 |
| eight singletons: campaign sites, a news site, a university, a law firm, a vendor CDN, **a Google Images thumbnail** | 8 |

🟢 **ALL 29 OFF-SITE ROWS HAD AN OFFICIAL NCGA PORTRAIT ALREADY PUBLISHED — 29 of 29.** Rather
than mirror a 200x300 campaign thumbnail, or a Google image-search result, each was matched to its
member id on the NCGA roster and re-pointed. **27 went from a tiny off-site file to 1200x1800**;
Jonah Garson went from Squarespace to 4327x4443.
▶ **Before mirroring a third-party portrait, check whether the body publishes one.** The answer
here was yes for every single one, and mirroring would have locked in 29 bad frames and a licence
question that did not need to exist.

## 🟢 THE LINKED IMAGE IS `/Low`. THERE IS A `/High`, AND NOTHING LINKS IT

Stored URLs were `…/Members/MemberImage/H/744/Low` — **386x540**. The same path serves
**`/High` at 1200x1800**. Same shape as MN-6's unlinked 1050x1350 JPEG and OH-5's unlinked `large`;
the third time in one session.
⚠ **AN INVALID SIZE NAME IS NOT AN ERROR.** `/Medium`, `/Full`, `/Original` and `/Large` all
return **HTTP 200 with a 4,798-byte non-image**. Only `/Low` and `/High` are real, and a checker that
trusts a 200 would have mirrored a placeholder 134 times.
⚠ One exception: **Harry Warren's `/High` is SMALLER than his `/Low`** (393x448 against 386x540) —
a tighter crop, not a bigger file. His `/Low` was kept.

## 🔴🔴 THE CROP WAS WRONG ON ALL 163 AND EVERY COUNTER SAID IT WAS FINE

The first proof sheet reported `rendered 163 · missing 0 · flagged 2`, no monochrome — and **every
face had the top of its head cut off.** NCGA portraits are 1200x1800 and frame the head high;
`crop_4x5` at the default `anchor_y=0.5` takes a centre band of 1500 rows, **removing 150 from the
top**, straight through the crown. `anchor_y=0` fixes it.
▶ **Those counters measure the PIPELINE, and the pipeline worked perfectly. Nothing in it can
measure COMPOSITION — so look at the frames before publishing the sheet.** Caught by Cantrell, not
by me. See [[feedback_look_at_the_proof_sheet_you_publish]].

## The six who rendered nothing — and three that needed a hand-crop

All six had an NCGA public-domain portrait too, so the state could close rather than stop at 164.
Three of their sources are **not headshots**, and needed per-person `zoom`/`anchor` overrides:

| | source | crop | why |
| --- | --- | --- | --- |
| Anna Ferguson | 5464x8192 | `zoom 2.4, y 0.12` | seated full-length |
| John L. Lowery | 3759x3507 | `zoom 1.9, y 0.22` | full body outdoors |
| Dan Kiger | 1024x768 | `zoom 2.0, x 0.42, y 0.65` | landscape half-body |

⚠ **RAISING A SUBJECT AND ENLARGING THE FACE ARE THE SAME LEVER HERE, NOT TWO.** My first two
passes sat all three too low; the operator rejected both. Once the zoom window is in play the ratio
crop takes its **full height**, so vertical placement is governed entirely by `anchor_y` — and the
only way to make a face *bigger* is to zoom in, which is what costs the pixels. Kiger was judged
**side by side against Phil Rubin as a reference face**, which is what finally settled it:
`z1.5 y0.70` kept the most pixels and still read low and small; `z2.0 y0.65` matches the row at
**307x384, a 1.95x enlargement** — accepted deliberately, because the alternative is one portrait
that reads differently in every grid. He is the only one of the 170 whose source is not a studio
headshot.

## 🔴 A SECOND DEFECT IN THE SHARED IMPORTER: PROVENANCE WAS LEFT POINTING AT THE IMAGE

After the first 163 landed, `photo_origin_url` held the member's biography page for only **29**. The
importer rewrites provenance when the old value is NULL **or matches a file-extension regex** — and
`/Members/MemberImage/H/744/High` **has no extension**, so 134 rows kept the IMAGE url as their
"provenance". That is exactly the defect the field exists to prevent: a dead image link then counts
as coverage under `HAS_RENDERABLE_PHOTO_SQL`.
⚠ **AND THE OBVIOUS FIX IS ALSO WRONG.** Matching the candidate's own `url` never fires when a
wave *upgrades* the source — NC imported `/High` while the stored value was `/Low`. It matched **1
row of 134**. The pattern has now been wrong twice, so the caller states it per row with
`"origin_is_image": true` rather than the importer guessing.
The 134 were repaired against `/Members/MemberImage/`, which is unambiguously an image path on that
host and can never be a biography page. ⚠ One row needed its own fix: **Caleb Theodros's
provenance was a Google Images thumbnail URL** — no extension, no `MemberImage` path, so neither
rule caught it.

**Proof sheets:** the 163 — https://claude.ai/artifact/QAZThoisV2axxHqU8GuA7D ·
the last six — https://claude.ai/artifact/YFPCPwwrNGaLp29GKh9wcE

## What NC still owes

Nothing on the legislature. The local and county rows are separate: Charlotte is 12/12/12 and
Mecklenburg 16/16/**15** — **Elisa Chinn-Gary** remains the one Mecklenburg officer on the headshot
backlog, unchanged by this wave.
