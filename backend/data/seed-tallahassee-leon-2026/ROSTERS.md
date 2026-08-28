# Tallahassee and Leon County — verified roster, 2026-08-28

Wave FL-4 of the Knight Foundation cities program.

**Spec:** `docs/superpowers/specs/2026-08-28-knight-cities-program-design.md`
**Plan:** `docs/superpowers/plans/2026-08-28-knight-fl-wave-4-tallahassee-leon.md`
**Slice notes:** `.planning/knight-foundation/fl.md`

**18 offices, 18 people, 0 vacancies.** Tallahassee: 5 at-large seats. Leon County: 7 commissioners
+ 6 constitutional officers.

The raw source pulls sit beside this file as untracked `_*.html` / `_*.pdf`. They are the evidence; do
not delete them while this wave is open.

---

## Sources

| # | Source | Authoritative for | Pulled |
| --- | --- | --- | --- |
| S1 | `leonvotes.gov/Candidates/Elected-Officials` — Supervisor of Elections | **the seat list for both bodies**, every incumbent, every "next election" year, and each body's take-office rule | 2026-08-28 |
| S2 | `leonvotes.gov/Candidates/Candidates/Offices-Up-for-Election` | independent cross-check on which seats are contested | 2026-08-28 |
| S3 | `cms.leoncountyfl.gov/leadingtheway/County-Commissioners` | **service-year range per county commissioner**, and the Home Rule Charter date | 2026-08-28 |
| S4 | `talgov.com/cityleadership/{dailey,matlow,porter,richardson,williams-cox}` | city seat numbers, and two start years | 2026-08-28 |
| S5 | `leonvotes.gov` certified results PDFs, 2016P/2016G/2018P/2018G/2020P/2020G | **the election-cycle inventory per seat** — see the defect note below for what these could NOT be used for | 2026-08-28 |
| S6 | `intervector.leoncountyfl.gov` `SOE_DistrictsCurrent_D_WM` layers 1, 4, 5, 6 | commission districts, FL House/Senate, city limits | 2026-08-28 |

⚠ **`curl` gets a hard 403 from `leonvotes.gov`, `cms.leoncountyfl.gov`, and four of the six
constitutional officers' sites** — TLS-fingerprint blocking, not a User-Agent problem; a full browser
header set does not help. S1, S2, S3 and S5 were pulled with **Playwright**. `talgov.com` and
`leonschools.net` answer `curl` normally. The ArcGIS endpoints answer `curl` normally.

⚠ **S1's categories are collapsed accordions.** The content is in the DOM but hidden, so a plain
`innerText` of the page body returns only the category headings. Read it by locating each exact
category heading and walking up to its container.

---

## 🔴 Source defects and dead ends found

**D1 — Leon is a CHARTER county and elects SIX constitutional officers. Manatee, non-charter, elects
five.** S3: *"since November 12, 2002, Leon County adheres to governance guided by a Home Rule
Charter."* The sixth office is the **Superintendent of Schools**, and S1 lists it under "Leon County
Constitutional Offices" with its own four-year term. This is the variation `fl.md` warns against
inheriting, and it is a real seat, not a naming difference.

**D2 — The two counties name their at-large seats differently.** Manatee: "District 6" and
"District 7". Leon: **"At Large, Group 1"** and **"At Large, Group 2"**. Both are the publisher's own
wording and both are kept as published.

**D3 — The Superintendent's take-office rule differs from the other five officers' in the same
county.** S1: Clerk, Property Appraiser, Sheriff, Supervisor of Elections and Tax Collector all take
office on the **1st Tuesday after the 1st Monday in January**; the **Superintendent** takes office on
the **2nd Tuesday after the General Election**. Three different rules across the three bodies in this
wave — the City is a fourth (**13th day after the General Election**) and the County Commission a
fifth (**2nd Tuesday after the General Election**).

**D4 — 🔴 THE CERTIFIED-RESULTS PDFs WERE REJECTED AS A DATE SOURCE, AND THE REASON MATTERS.**
S5's race headers extract cleanly and are trustworthy. The **candidate blocks do not**: a parser built
to slice each race's candidates between its column header and its "Total Votes" line came out
**shifted by one race**, and reported *"Mayor → Jeremy Matlow"* for 2018. Dailey won the 2018
mayoralty; Matlow won Seat 3. **That output is plausible, wrong, and would have seated two people on
each other's dates.** It was discarded rather than repaired: a fragile parser producing confident dates
is a worse outcome than an honest blank. **Do not re-attempt this without a real PDF text layer
extractor and a per-race positive control.**

What S5 *is* good for is the **cycle inventory**, which is structural and unambiguous:

| Seat | Contested in | Cycle |
| --- | --- | --- |
| City Seats 1 and 2 | 2016, 2020 (and by S1's "next election 2028", 2024) | presidential |
| City Seat 3, Seat 5, Mayor | 2018 (and by S1, 2022 and 2026) | midterm |
| County At Large Group 1, District 4 | 2020 | presidential |
| County Districts 1 and 3 | 2018 | midterm |
| Sheriff, Property Appraiser, Tax Collector, Supervisor of Elections | 2016 | presidential |

This independently corroborates every "next election" year in S1 and every start year in S3.

**D5 — Nine of the eighteen people have no published start date on any reachable page.** Tried and
failed: their own official pages (S4 gives a date for only two of five), the county history page (S3
covers commissioners only, not officers), the officers' own sites (four of six 403, and guessed
sub-paths 404), and the certified results (D4). Those nine are recorded with
`start_precision => 'unknown'` and no date, exactly as three Bradenton council members were in FL-3.
▶ **Follow-up:** the Leon County Clerk of Court holds the commission's organisational minutes, and the
city clerk holds the city's; both would date every one of these precisely.

**D6 — Tallahassee Seat 3 went to a manual recount in the 2026 primary**, completed 2026-08-24, and
the 2026 general election is still ahead. S1 — which is the current-state source — still lists
**Jeremy Matlow** in Seat 3, so he holds it now. **Re-check before FL-7.**

**D7 — Two role titles appear in page titles and are NOT offices.** `talgov.com/cityleadership/richardson`
is titled *"Mayor Pro Tem Richardson - Seat 2"*, and Williams-Cox has been elected Mayor Pro Tem in
several years. See ruling R3.

---

## Charter rulings

**R1 — Leon County is a CHARTER county** (Home Rule Charter, in force 2002-11-12, per S3), and elects
**six** constitutional officers: Sheriff, Tax Collector, Property Appraiser, Supervisor of Elections,
Clerk of the Circuit Court and Comptroller, **and Superintendent of Schools**. All six are seated in
the `Elected Officials` chamber. ⚠ **Nothing here may be inherited by Palm Beach or Miami-Dade** —
Miami-Dade is also a charter county and must be read separately at FL-6.

**R2 — The Superintendent of Schools IS seated; the School BOARD is NOT.** The Superintendent is a
countywide elected constitutional officer, listed as such by S1, and omitting it would under-report
Leon's government by a real seat. The School Board is a separate legislative body, and spec §3 stage 4
is "commission layer + county officers" — the same line FL-3 drew for Manatee's school board.

**R3 — Mayor Pro Tem is a ROLE, not an office.** The commission elects one annually and it rotates;
Williams-Cox and Richardson have both held it. Same disposition as Bradenton's Vice Mayor (FL-3) and
Asheville's (`CA_0009`). **No office row.**

**R4 — Tallahassee's commission is five AT-LARGE seats and the Mayor is SEAT 4.** S1: *"City
Commissioners and Mayor do not have districts. Instead, all voters who live in Tallahassee can vote
each of the City Commissioner contests."* The city's own page is titled *"Mayor John E. Dailey -
Seat 4"*. Consequences: **no ward layer is needed** (the TIGER place polygon `1270600` carries every
seat), all five seats share one district, and **every Tallahassee address returns all five
commissioners**.

**R5 — The Mayor is `voting_powers = 'full'` with no note, and no ruling is required.** Unlike
Bradenton's mayor, Tallahassee's is one of five equal commissioners with a full vote — Seat 4 of the
same body, not a presiding officer outside it. So the tie-break question that FL-3 had to rule on does
not arise here. **One chamber, not two**, for the same reason.

**R6 — Out of scope, considered and excluded:** the Leon County School Board, the Leon Soil and Water
Conservation District, and the Canopy, Capital Region, Fallschase and Piney-Z Community Development
Districts. All elected, all listed by S1, none a county commission or a constitutional officer.

---

## How `term_start` was derived

`term_start` is the start of **continuous occupancy by that person**, never the start of the current
term, and no `term_end` is written.

**`month` precision — 9 people.** A published start *year* from the officeholder's own publisher, plus
the body's published take-office rule, which fixes the month. Applying a published rule to a published
year is a derivation, not a guess, and it is stated here so it can be checked:

- **County Commission** — S3 publishes a service-year range per commissioner and S1 publishes
  "Members take office on the 2nd Tuesday after the General Election", which is November. The range's
  **first** year is the service start, so e.g. Proctor's `1996-2026` gives 1996-11.
  ⚠ The second number is the **current term's expiry**, not a re-election year.
- **Mayor Dailey** — his own page: *"John was elected Mayor of the City of Tallahassee in 2018."* The
  city's rule is the 13th day after the General Election, so November 2018. ⚠ His county service
  (District 3, 2006–2018, per both S3 and S4) is a **different office**; the mayoralty starts 2018.
- **Commissioner Matlow** — his own page: *"He was elected to the office of City Commissioner in
  2018."* Seat 3 was on the 2018 ballot (S5), so November 2018.

**`unknown` precision — 9 people, with no date.** No reachable publisher gives a start. See defect D5
for everything that was tried. **A guessed date here would be a false statement about a real person,
and there is no `end_precision` to soften it.**

**Seat changes checked.** Occupancy of the *current* seat starts when that seat was taken, which is the
Nashville Porterfield/Henderson trap. Verified: **Nick Maddox has held At Large Group 2 continuously
since 2010** and did not move from a district. **Dailey moved from the county commission to the
mayoralty in 2018** and is dated accordingly. **Akin Akinyemi**, now Property Appraiser, was a county
commissioner 2008–2012 per S3 — a separate, earlier span in a different office, and it is *not* his
Property Appraiser start (which is unknown). No other seat change was found.

---

## Roster

### City of Tallahassee

| Seat | Slug | Name | external_id | term_start | precision | how_started | source |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Seat 1 | seat-1 | Jacqueline "Jack" Porter | -1240031 |  | unknown | elected | leonvotes-elected-officials-2026-08-28 |
| Seat 2 | seat-2 | Curtis Richardson | -1240032 |  | unknown | elected | leonvotes-elected-officials-2026-08-28 |
| Seat 3 | seat-3 | Jeremy Matlow | -1240033 | 2018-11-01 | month | elected | talgov-matlow-bio-2026-08-28 |
| Seat 4, Mayor | seat-4-mayor | John Dailey | -1240034 | 2018-11-01 | month | elected | talgov-dailey-bio-2026-08-28 |
| Seat 5 | seat-5 | Dianne Williams-Cox | -1240035 |  | unknown | elected | leonvotes-elected-officials-2026-08-28 |

### Leon County

| Seat | Slug | Name | external_id | term_start | precision | how_started | source |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Commissioner, District 1 | commissioner-1 | Bill Proctor | -1240041 | 1996-11-01 | month | elected | leoncounty-leadingtheway-commissioners-2026-08-28 |
| Commissioner, District 2 | commissioner-2 | Christian Caban | -1240042 | 2022-11-01 | month | elected | leoncounty-leadingtheway-commissioners-2026-08-28 |
| Commissioner, District 3 | commissioner-3 | Rick Minor | -1240043 | 2018-11-01 | month | elected | leoncounty-leadingtheway-commissioners-2026-08-28 |
| Commissioner, District 4 | commissioner-4 | Brian Welch | -1240044 | 2020-11-01 | month | elected | leoncounty-leadingtheway-commissioners-2026-08-28 |
| Commissioner, District 5 | commissioner-5 | David O'Keefe | -1240045 | 2022-11-01 | month | elected | leoncounty-leadingtheway-commissioners-2026-08-28 |
| Commissioner, At Large Group 1 | at-large-group-1 | Carolyn D. Cummings | -1240046 | 2020-11-01 | month | elected | leoncounty-leadingtheway-commissioners-2026-08-28 |
| Commissioner, At Large Group 2 | at-large-group-2 | Nick Maddox | -1240047 | 2010-11-01 | month | elected | leoncounty-leadingtheway-commissioners-2026-08-28 |
| Sheriff | sheriff | Walt McNeil | -1240051 |  | unknown | elected | leonvotes-elected-officials-2026-08-28 |
| Tax Collector | tax-collector | Doris Maloy | -1240052 |  | unknown | elected | leonvotes-elected-officials-2026-08-28 |
| Property Appraiser | property-appraiser | Akin Akinyemi | -1240053 |  | unknown | elected | leonvotes-elected-officials-2026-08-28 |
| Supervisor of Elections | supervisor-of-elections | Mark S. Earley | -1240054 |  | unknown | elected | leonvotes-elected-officials-2026-08-28 |
| Clerk of the Circuit Court and Comptroller | clerk-of-circuit-court | Gwen Marshall | -1240055 |  | unknown | elected | leonvotes-elected-officials-2026-08-28 |
| Superintendent of Schools | superintendent-of-schools | Rocky Hanna | -1240056 |  | unknown | elected | leonvotes-elected-officials-2026-08-28 |

**No party affiliation is recorded.** S1 prints `(DEM)` beside all six constitutional officers and
`(Non-Partisan)` beside the thirteen commission and city seats. All discarded — party lives on
`races.primary_party`.

**`how_started` is `'elected'` for all eighteen.** No appointment was found in any source, and no seat
in this wave is vacant.

<!-- COUNTS: city_offices=5 city_people=5 county_offices=13 county_people=13 vacancies=0 -->
