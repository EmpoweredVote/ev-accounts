# Colorado — slice 9 notes

Boulder. Stages 1 and 2 were already complete before this slice opened: Colorado has place, `sldu`
and `sldl` polygons, and the legislature is seated 65/65 + 35/35 with four statewide executives.
**This slice is stages 3, 4 and 5 only.**

Program tracker: [`PROGRAM.md`](./PROGRAM.md). Spec:
[`2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md).

---

# CO-3 — Boulder city and Boulder County, RESEARCH 2026-09-16. NOTHING WRITTEN TO PRODUCTION.

## Measured starting position

**Boulder, Colorado holds nothing.** Not a partial seed, not a stale one — zero offices, zero
governments, in either the city or the county.

🔴 **AND THE OBVIOUS QUERY SAYS OTHERWISE.** `WHERE g.name ILIKE '%Boulder%'` returns exactly one
government and it is **Boulder City, NEVADA** — a real city of 15,000 outside Las Vegas, already
seated with 5 council offices. A sweep that reads that row as "Boulder exists" seeds nothing and
reports success. This is the `%St. Paul%` trap from MN-1 in a second dress: **match on `geo_id`,
never on a name.**

| Layer | State |
| --- | --- |
| `geofence_boundaries` G4110 `0807850` "Boulder city" | ✅ present |
| `geofence_boundaries` G4020 `08013` "Boulder County" | ✅ present |
| `districts` G4020 `08013` Boulder County | ✅ present |
| **`districts` row for the place `0807850`** | 🔴 **ABSENT — the city wave creates it** |
| Colorado legislature | ✅ 65/65 House, 35/35 Senate, 4 statewide |

⚠ **The place has a BOUNDARY and no DISTRICT row**, which is exactly what GA-1 left for Columbus and
Macon and what GA-5 had to create. A boundary alone is not reachable by address search.

⚠ **`08013` IS THREE DIFFERENT DISTRICTS.** The same `geo_id` string carries `G4020` (Boulder
County), `G5210` (State Senate 13) and `G5220` (State House 13). Nothing is wrong — it is why the key
is **(mtfcc, geo_id)** and never `geo_id` alone. A join written on `geo_id` would hand a county
office to a Senate district.

## The city: nine at-large seats, one of them a directly elected mayor

Established from the city's own FAQ, not inferred from the roster page:

> "The City Council consists of nine members, including a mayor and mayor pro tem."
> "No, all City Council members are elected at-large."
> "In order to transition to even-year elections, in the 2023 election the term length for both the
> Mayor and City Council members elected will be three years."
> "Starting in 2026, the City of Boulder will transition to even-year elections for all municipal
> candidate races."

So: **no district layer is needed for Boulder** — the Tallahassee shape, not the Colorado Springs
shape. Colorado Springs, seated in an earlier wave, is 6 districts + 3 at-large + a Mayor; **the
state does not impose a council shape and neither does the programme.**

The mayor has been **directly elected since 2023** (Measure 2E, 2020, ranked-choice). That is a
distinct office from the council seats, as in Miami and Duluth, not a designation rotated among
members — which is the opposite of the Sahuarita/South Tucson ballot-truth case decided in `1863`.

### 🔴🔴 THE CITY'S OWN COUNCIL PAGE LISTS EIGHT OF THE NINE

`bouldercolorado.gov/government/city-council` lists Adams, Benjamin, Brockett, Kaplan, Marquis,
Schuchard, Speer and Winer. **Mark Wallach is absent**, and he is not a departure: he took the
**highest vote total in the 2025 election** and was sworn in with the rest on 2025-12-04.

**The roster page is the thing under test, not the authority.** MN-2 established that a chamber's
list page is not a change-check; this is the same failure in the other direction — a list page that
omits a sitting member rather than keeping a departed one. Both are caught the same way: reconcile
the list against the election that produced it.

### ✅ The 2025 election, from the county's own tabulation

Boulder County, 2025 Coordinated Election, "City of Boulder Council Candidates — Vote for no more
than Four", 13 candidates:

| Votes | Candidate | |
| ---: | --- | --- |
| 20,276 | Matt Benjamin | ✅ elected |
| 17,476 | Mark Wallach | ✅ elected |
| 16,165 | Nicole Speer | ✅ elected |
| 15,867 | Rob Kaplan | ✅ elected |
| 14,781 | Jennifer Robins | |
| 14,222 | Lauren Folkerts | incumbent, defeated |
| 5,275 | Adam Gianola | |
| 5,085 | Rachel Rose Isaacson | |
| 2,957 | Montserrat Palacios | |
| 2,853 | Maxwell Lord | |
| 2,707 | Aaron Stone | |
| 1,929 | Luke Arrington | |
| 1,499 | Rob Smoke | |

🔴 **THE RESULTS LISTING IS NOT ORDERED BY VOTES, AND THE FIRST NAME IS NOT A WINNER'S.** The page
lists Speer first and **Wallach ninth**, and Wallach outpolled Speer by 1,311. Reading listing order
would have seated Palacios and Smoke — 2,957 and 1,499 votes — over Benjamin and Wallach. **Sort on
votes and print the totals beside every claim** (the Clarity rule from CA-2, on a different vendor).

🔴 **THERE WAS NO BOULDER MAYORAL CONTEST IN 2025.** The only mayoral race in the county's 2025
results is **Longmont's**. The mayor's seat was not up; Brockett holds it from 2023 under the
three-year transition term.

🔴 **A FILE NAMED "CANVASS" WAS A SLIDE DECK.**
`assets.bouldercounty.gov/…/2025-Boulder-County-Coordinated-Canvass.pdf` is a **training
presentation on the risk-limiting audit**, not an abstract of votes — agenda, RLA responsibilities,
audit board duties. It downloads clean, it is the right county and the right election, and it
answers nothing. **A filename is not a document.** The votes are in the results archive at
`electionresults.bouldercounty.gov/Home/IndexCategory/49.html`.

### ▶ Open, and needed before any occupancy row is written

1. **A term start per member**, sourced. The 2025 cohort was sworn in **2025-12-04**; that date needs
   the city's own record (council minutes or the clerk), not a news report.
2. **Tara Winer's continuous occupancy.** The city page gives her term as 2023–2026; the press
   describes her as "elected in 2021". If she has served continuously since a 2021 swearing-in, the
   term row starts **in 2021** — the San José/Candelas ruling — and the 2023 re-election is not a new
   occupancy. The 2021 and 2023 canvasses settle it.
3. **The 2023 cohort's swearing-in date**, same standard.
4. **Whether `how_started` is `elected` for all nine.** No appointment is known, but "no appointment
   is known" is not a check — the city's vacancy record is.

## The county: three commissioners and SEVEN officers

From the county's own Elected Officials page:

| Office | Holder |
| --- | --- |
| Commissioner, District 1 | Claire Levy |
| Commissioner, District 2 | Marta Loachamin |
| Commissioner, District 3 | Ashley Stolzmann |
| Assessor | Cynthia Braddock |
| Clerk & Recorder | Molly Fitzpatrick |
| Coroner | Jeff Martin |
| District Attorney | Michael Dougherty |
| Sheriff | Curtis Johnson |
| **Surveyor** | **Lee Stadele** |
| Treasurer | Paul Weissmann |

🔴 **BOULDER ELECTS A SURVEYOR AND EL PASO COUNTY DOES NOT SHOW ONE.** The seated El Paso County
template is 5 commissioners + Assessor, Clerk and Recorder, Coroner, District Attorney, Sheriff,
Treasurer and Public Trustee — **no Surveyor row at all**. Colo. Const. art. XIV §8 names the
surveyor among the county officers, so the difference is a fact about each county's practice, not
about the state. **This is the MN-4 rule again: two counties in one state do not elect the same
offices, and neither matches the general rule.** Read Boulder's own page; do not inherit El Paso's
chamber list.

⚠ **THE COMMISSIONERS ARE DISTRICTED BUT NOT DISTRICT-ELECTED — CHECK BEFORE MODELLING.** Colorado
commissioner districts are residency districts, and whether the vote is county-wide or by district
differs by county and has changed recently in several. `representation_basis` and the district
wiring both depend on the answer, so it is sourced before the structure migration, never assumed.

⚠ **THE DISTRICT ATTORNEY IS THE 20th JUDICIAL DISTRICT.** For Boulder that district is the county
alone, so the office sits cleanly under the county — unlike El Paso's DA, whose 4th Judicial District
also covers Teller County. Confirm the 20th's composition before seating Dougherty under Boulder
County only.

▶ **Term starts are owed for all ten**, and Colorado county officers took office in January following
a November election — 2022 winners from January 2023, 2024 winners from January 2025. **The November
2026 election is six weeks away and changes nothing about who holds these seats today**: a Colorado
county officer elected in 2026 takes office in January 2027. That is the certified-result rule from
the Knight programme — a certified result is not a fact about who holds the seat.

## ✅ APPLIED 2026-09-16 — `CC_0114` structure, `CC_0115` occupancy. 19 offices, 19 seated, 0 vacancies.

| Body | Offices | Seated |
| --- | --- | --- |
| Boulder City Council | 9 | 9 |
| Boulder County Board of County Commissioners | 3 | 3 |
| Boulder County Elected Officials | 7 | 7 |

✅ **Idempotent, proved by re-running both** — every `essentials.*` write came back `INSERT 0 0` and
both gates stayed green. ✅ **Dry-run first as one transaction, and the rollback was verified** to
have left no government, no district and no person behind.

✅ **BOTH GATES WERE WATCHED FAILING FIRST**, on the unapplied database: *"expected 2 governments,
got 0"* and *"expected 19 people in the reserved band, got 0"*. ⚠ **And the control harness lied
before the gates did** — a loop over both control files printed nothing at all, which reads exactly
like two silent gates. The cause was shell path escaping in the loop, not the gates; running each
file directly is what showed it. **A detector that reports nothing is a claim about the detector
until you run it by hand.**

### ✅ The probe: four kinds of answer from one address

**Boulder City Hall returns 22 answers** — 9 city, 10 county, 2 state legislative — and all four
kinds the programme defines "done" by: a council member, a county commissioner, a state
representative (Junie Joseph) and a state senator (Judy Amabile).

🔴 **"EXACTLY ONE COUNCILLOR" IS THE WRONG ASSERTION HERE, AND IT IS THE RIGHT ONE ELSEWHERE.**
Boulder elects every seat at large, so every Boulder address is represented by **all nine** council
seats and **all three** commissioners. MN-4 asserted exactly one commissioner per point and was
correct; asserting that here would fail on correct data. **The assertion follows the electorate, not
the habit.**

✅ **The controls discriminate, and they sit outside the thing being tested.** Longmont — inside
Boulder County, outside the city — returns **0 city, 10 county** and a *different* legislative pair
(Karen McCormick, Katie Wallace). Denver returns **neither** city nor county, and a third pair again.
A control that returned the same legislators would have proved only that the query runs.

## ▶ Next

1. **Stage 5 for Boulder**: 19 portraits and one banner.
   🔴 Two Colorado compositions are already spoken for — `states/CO.jpg` is a **Denver skyline** and
   `cities/colorado-springs.jpg` is **Garden of the Gods**, chosen in that wave *because* the state
   banner is a skyline. The Flatirons are the obvious answer and must be tested against both: an
   elevated rock formation against a city is not the same composition as Garden of the Gods, but the
   two need seeing side by side before either is certified.
   ⚠ And read Boulder's chamber-photo question the way MN-5 forced: **before building any roster
   portrait script, read the publisher's photo policy.**
2. **CO-4**: nothing. Boulder is Colorado's only Knight city, so this slice closes at stage 5.
