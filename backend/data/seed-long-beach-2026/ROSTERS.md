# Long Beach — verified roster and boundary record (CA-1)

**Program tracker:** [`.planning/knight-foundation/PROGRAM.md`](../../../.planning/knight-foundation/PROGRAM.md)

Measured 2026-09-02. **13 offices, 13 people, 0 vacancies** — 9 council districts + 4 citywide
elected officials. Los Angeles County, Long Beach's parent county, is **already complete** and is
re-verified but not rewritten by this wave.

Long Beach is **not** a greenfield seed. Every office and every person already existed. This wave
fixes two defects in what was there:

1. 🔴 **All nine council districts shared the city's place polygon**, so every Long Beach address
   returned all nine councilmembers.
2. **All thirteen occupancy rows were undated**, written by the ADR 0002 phase-2 backfill from a
   vendor snapshot (`cicero`) with no term start and no change-check.

---

## Sources

| # | Body | Source | Endpoint | What it is |
| --- | --- | --- | --- | --- |
| A | city | **City Clerk, 2026 candidate information** | `longbeach.gov/globalassets/city-clerk/media-library/documents/elections/2026/2026-getting-started-candidate-information-06-02-2026_final` | **the structural authority for terms.** Names every 2026 incumbent and states the commencement date, citing Charter Sec. 1901 |
| B | city | Council roster | `longbeach.gov/council/` and the nine `/districtN/` pages | the city's own roster |
| C | city | **City Clerk, certified results** | `longbeach.gov/cityclerk/elections/past-election-results/` | certified cumulative reports, 1994 to 2026 |
| D | city | **Legistar office records** | `webapi.legistar.com/v1/longbeach/bodies/{1,29,30,31}/officeRecords` and `/persons/2449/officeRecords` | the city's own legislative system. **Day-precision start and end dates** |
| E | city | **City of Long Beach Council Districts** | `services6.arcgis.com/yCArG7wGXGyWLqav/.../City_of_Long_Beach_Council_Districts/FeatureServer/0` | the operative geometry. Also published by the `CRC.Admin` account — the Citizens Redistricting Commission |
| F | city | Business licences, daily update | `.../Business_Licenses_Public_View/FeatureServer/0` | **the control set.** 23,492 active licences carry a `COUNCIL_NUMBER` and a point |
| G | city | Development projects, public | `.../Development_Projects_(Public)/FeatureServer/0` | a second control set, 61 points, with a filing date per case |
| H | city | Council resolutions appointing McIntosh and Haubert | `.../elections/2026/appointment-of-dawn-mcintosh-to-the-office-of-city-attorney` and `...-doug-haubert-to-the-office-of-city-prosecutor` | why City Attorney and City Prosecutor are absent from the 2026 ballot |
| I | county | **LA County, Salary and Tenure Data, Elected Officials** | `file.lacounty.gov/SDSInter/lac/1044065_ElectedOfficialsSalaries.pdf` (REV. 08/07/26) | the county's own roster, with "First term began" per official |
| J | county | Census TIGERweb, Incorporated Places | `tigerweb.geo.census.gov/.../Places_CouSub_ConCity_SubMCD/MapServer/4` | land and water area for GEOID 0643000 |

Payloads are on disk in this directory, untracked.

---

## 🔴 Source defects found

### 1. 🔴🔴 The City Clerk's own elections FAQ states the WRONG election calendar and the WRONG term-commencement rule

`longbeach.gov/globalassets/city-clerk/media-library/documents/elections/faqs/general-questions-about-long-beach-city-elections/` says:

> Long Beach City Charter Section 1901 designates that the primary and general municipal elections
> ... shall be held ... on the second Tuesday in April and the first Tuesday after the first Monday
> in June, respectively, and **candidates elected to office shall assume such office on the third
> Tuesday in July**.

That was true through 2018. It is not true now. The **2026 candidate information** (source A), the
**2026 appointment resolutions** (source H) and **Legistar** (source D) all agree that terms now
commence on the **third Tuesday in December**, and that the elections are a June primary with a
November general.

> 🔴 **A stale page on the authoritative site is more dangerous than a missing one.** Read for the
> calendar alone, this FAQ would have dated every Long Beach term four to five months early, and it
> would have done so consistently enough to look right. The document that corrected it is the
> current cycle's own candidate packet.

The FAQ is also internally inconsistent — its heading says "first Tuesday in April", its body says
"second Tuesday in April". It remains the best available statement of the **pre-2020** rule, and it
is used here only for that: Uranga (2014), Haubert (2010) and Doud (2006).

### 2. 🔴 Legistar dates Haubert's occupancy from the ELECTION, not the swearing-in

Body 31 (City Prosecutor) holds:

| Person | start | end |
| --- | --- | --- |
| Thomas M. Reeves | 1998-07-21 | **2010-07-19** |
| Douglas P. Haubert | **2010-04-13** | 2022-12-19 |

2010-04-13 is the date of the Primary Nominating Election Haubert won. Taken literally, the two rows
assert that Reeves and Haubert both held the office for three months. Every other Legistar chain in
this dataset is gapless by one day (Burroughs ends 2006-06-30, Doud starts 2006-07-18; Parkin ends
2022-12-19, McIntosh starts 2022-12-20). **Haubert's occupancy is written here as 2010-07-20** — the
day after Reeves' record ends, the third Tuesday in July 2010, and the same date Legistar gives the
five councilmembers elected in that cycle.

### 3. Legistar's office records stop at 2024-12-17

No `officeRecords` row starts after 2024-12-17, so the December 2024 cohort is absent: Thrash-Ntuk
has a person record and no office record, and Allen, Saro and Supernaw have records that simply end
on that date. Occupancy for those three is unaffected — it is continuous from an earlier start — but
**Thrash-Ntuk's start date is not directly stated by any source.** It is taken as **2024-12-17**,
from Al Austin's District 8 record ending on that day, her outright win in the 2024-03-05 Primary
Nominating Election, and the third-Tuesday-in-December rule. All three agree.

### 4. The development-projects control set carries the district as of the FILING DATE

Source G disagrees with the boundary layer on 8 of its 61 points. Seven are cases filed before the
2021 redistricting took effect, and every one of them moves in the direction the new map moved:
downtown addresses stamped District 2 now sit in District 1. Split by era:

| Cases filed | n | agree | disagree |
| --- | --- | --- | --- |
| after 2022-12-20 | 25 | 24 | **1** |
| before 2022-12-20 | 36 | 29 | 7 |

The single post-map disagreement is `101 E PACIFIC COAST HWY`, stamped District 2, contained by
District 6, and **2,083 m from the nearest edge of District 2**. A boundary question cannot be two
kilometres wide; this is an error in the control record, not in the boundary.

⚠ **A district stamped on a record is a fact about when the record was written, not about where the
address is.** Source G's field is only usable once it is read together with `USER_Date_Filed`.

---

## Charter rulings

- **Nine single-member council districts, plus a citywide Mayor, City Attorney, City Auditor and
  City Prosecutor.** All four-year terms. Source E's own service description states it, source A
  lists the offices, and source B renders them under "Legislative Branch" and "City-Wide Elected
  Officials".
- **Odd districts, the Mayor and all three citywide officers share one cycle; even districts run two
  years later.** So 2026 covers Mayor, Districts 1/3/5/7/9, City Attorney, City Auditor and City
  Prosecutor, and 2024 covered Districts 2/4/6/8.
- **Terms commence on the third Tuesday in December.** For 2026 that is **2026-12-15** (source A,
  citing Charter Sec. 1901; source H recites the same rule).
- **Before the change, terms commenced on the third Tuesday in July.** Legistar confirms the
  turnover dates 2010-07-20, 2014-07-15, 2020-12-15, 2022-12-20 and 2024-12-17.
- **An unopposed citywide office is filled by Council appointment, not by an election.** LBMC
  1.15.150 lets the Council appoint the sole nominee and cancel the contest. That is why the 2026
  Primary Nominating Election contains no City Attorney and no City Prosecutor race, and it is not a
  gap in the results file.

---

## 🔴🔴 Change-check — has anyone LEFT, and has anyone new been SEATED?

The June 2, 2026 Primary Nominating Election has already been held and certified. **Nobody it
elected is in office yet.** Terms commence 2026-12-15. Today is 2026-09-02.

| 2026 contest | Result (source C) | Seated when |
| --- | --- | --- |
| Mayor | Rex Richardson, 57.37% — **Elected** | 2026-12-15, re-elected |
| City Auditor | Laura Doud, 70.53% — **Elected** | 2026-12-15, re-elected |
| Council District 1 | Mary L. Zendejas, 50.21% — **Elected** | 2026-12-15, re-elected |
| Council District 3 | Kristina Duggan, 63.98% — **Elected** | 2026-12-15, re-elected |
| Council District 5 | Megan Kerr, 53.96% — **Elected** | 2026-12-15, re-elected |
| **Council District 7** | **Vivian Malauulu, 74.12% — Elected** | **2026-12-15, REPLACING Roberto Uranga** |
| Council District 9 | Joni Ricks-Oddie, 67.97% — **Elected** | 2026-12-15, re-elected |
| City Attorney | Dawn McIntosh, sole nominee — **appointed** (source H) | 2026-12-15, re-appointed |
| City Prosecutor | Douglas P. Haubert, sole nominee — **appointed** (source H) | 2026-12-15, re-appointed |

> 🔴 **ONE SEAT TURNS OVER ON 2026-12-15.** Roberto Uranga is term-limited — source A prints
> "*Not eligible to run for an additional term due to term limits*" against District 7 — and Vivian
> Malauulu won it outright in June. **Uranga holds the seat until 2026-12-15 and Malauulu holds it
> after.** Writing Malauulu now would be the Columbus error in a new dress: a certified result is not
> a fact about who holds the seat.

No other change was found. Sources B and E and the site navigation on every longbeach.gov page carry
the same 13 names, and no councilmember or citywide officer has an end date before 2026-12-15 in
Legistar.

---

## Roster

`term_start` is the start of **continuous occupancy of that office by that person**, not the start of
the current term. Every date is day-precision and comes from source D unless noted.

| # | Office | Chamber | Person | term_start | prec | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Mayor | Mayor of Long Beach | Rex Richardson | 2022-12-20 | day | Legistar body "Mayor's Office": 2022-12-20 to 2026-12-15 |
| 2 | City Attorney | City Attorney of Long Beach | Dawn McIntosh | 2022-12-20 | day | Legistar body 29; Parkin ends 2022-12-19 |
| 3 | City Auditor | City Auditor of Long Beach | Laura Doud | 2006-07-18 | day | Legistar body 30; Burroughs ends 2006-06-30; won the 2006-04-11 PNE outright (source C) |
| 4 | City Prosecutor | City Prosecutor of Long Beach | Doug Haubert | 2010-07-20 | day | **derived — see source defect 2.** Reeves ends 2010-07-19; won the 2010-04-13 PNE |
| 5 | Councilmember, District 1 | City Council | Mary Zendejas | 2019-12-03 | day | Legistar; won the 2019-11-05 special (source C) |
| 6 | Councilmember, District 2 | City Council | Cindy Allen | 2020-12-15 | day | Legistar; won the 2020-11-03 runoff |
| 7 | Councilmember, District 3 | City Council | Kristina Duggan | 2022-12-20 | day | Legistar; won the 2022-11-08 runoff |
| 8 | Councilmember, District 4 | City Council | Daryl Supernaw | 2015-04-27 | day | Legistar; won the 2015-04-14 special |
| 9 | Councilmember, District 5 | City Council | Megan Kerr | 2022-12-20 | day | Legistar; won the 2022-11-08 runoff |
| 10 | Councilmember, District 6 | City Council | Suely Saro | 2020-12-15 | day | Legistar; her own page says "since December 2020" |
| 11 | Councilmember, District 7 | City Council | Roberto Uranga | 2014-07-15 | day | Legistar; won the 2014-04-08 PNE outright |
| 12 | Councilmember, District 8 | City Council | Tunua Thrash-Ntuk | 2024-12-17 | day | **derived — see source defect 3.** Austin's record ends 2024-12-17; won the 2024-03-05 PNE outright |
| 13 | Councilmember, District 9 | City Council | Joni Ricks-Oddie | 2022-12-20 | day | Legistar; won the 2022-11-08 runoff |

Row 1: Richardson's **Mayor** occupancy begins 2022-12-20. He held District 9 from 2014-07-15 to
2022, but that is a different seat, and `term_start` is per office.

⚠ Thrash-Ntuk **lost** the District 8 runoff in 2020 (43.23% to Al Austin) and won the seat in 2024.
Her occupancy is **not** continuous from 2020. A roster read without the certified results would have
got this wrong in the safe-looking direction.

---

## Geometry

### The layer

`City_of_Long_Beach_Council_Districts/FeatureServer/0`, nine polygons, `lastEditDate` 2025-04-24.
Loaded with `outSR=4326` into `essentials.geofence_boundaries` under **MTFCC `X0046`** and geo_ids
`long-beach-ca-council-district-1` through `-9`.

| District | sq mi | parts | valid | layer's REPRESENTATIVE |
| --- | --- | --- | --- | --- |
| 1 | 5.0029 | 1 | yes | MARY ZENDEJAS |
| 2 | 2.2316 | 1 | yes | CINDY ALLEN |
| 3 | 6.5953 | 1 | yes | KRISTINA DUGGAN |
| 4 | 9.7810 | 1 | yes | DARYL SUPERNAW |
| 5 | 10.2519 | 1 | yes | MEGAN KERR |
| 6 | 2.5619 | 1 | yes | SUELY SARO |
| 7 | 7.9146 | 1 | yes | ROBERTO URANGA |
| 8 | 4.3517 | 1 | yes | TUNUA THRASH-NTUK |
| 9 | 4.3702 | 1 | yes | JONI RICKS-ODDIE |

No two districts overlap by more than 0.0004 sq mi. The REPRESENTATIVE column matches the roster
above on all nine, which is what tells us the layer is maintained — but the roster loaded into the
database comes from sources B, C and D, never from a boundary layer.

### 🔴 There is no second layer, so GA-4's arbitration is not available here

GA-4 arbitrated two competing council-district layers against the county's ballot-building table.
**Neither half of that is available for Long Beach**, and both absences were measured, not assumed:

- **One layer, not two.** Three ArcGIS searches over the whole public catalogue return exactly one
  authoritative service. The only other item carrying the same title, owned by `CRC.Admin` — the
  Citizens Redistricting Commission — resolves to the **same FeatureServer URL**. The rest are
  student copies in CSULB accounts.
- **The county publishes no district attributes.** LA County's `Registrar Recorder Precincts`
  (layer 34) declares `DST_CITY` and `DIV_CITY` — the fields that would carry the council district —
  and **every row returns NULL for both**. `Registrar Recorder Election Precincts` (layer 37) carries
  real precinct IDs and no district fields at all. The City Clerk's Statement of Votes, which maps
  precincts to contests, is a **scanned** PDF with no text layer.

So the vintage test used here is a **control set**, not an arbiter, and this is said plainly because
the two are not equivalent.

### The control test

**2,700 active business-licence locations — 300 per district, from source F — tested against the
loaded polygons:**

| Claimed district | n | contained by that district | outside every district | contained by another |
| --- | --- | --- | --- | --- |
| 1 | 300 | **300** | 0 | 0 |
| 2 | 300 | **300** | 0 | 0 |
| 3 | 300 | **300** | 0 | 0 |
| 4 | 300 | **300** | 0 | 0 |
| 5 | 300 | **300** | 0 | 0 |
| 6 | 300 | **300** | 0 | 0 |
| 7 | 300 | **300** | 0 | 0 |
| 8 | 300 | **300** | 0 | 0 |
| 9 | 300 | **300** | 0 | 0 |

**2,700 of 2,700, every district, zero outside.** Source G independently agrees on 24 of its 25
post-redistricting cases (see source defect 4).

⚠ **This is a control, not an arbitration.** Both `COUNCIL_NUMBER` and
`USER_Council_District___Display` are plausibly derived by the city from this same boundary layer.
What the test proves is that the layer is the map the city's own operational systems route work by,
across every district and including District 4, which source G does not cover at all. It does not
prove the boundaries against an outside authority, because no outside authority publishes them.

### Land coverage

| Measure | sq mi |
| --- | --- |
| TIGER place 0643000, total | 77.8502 |
| TIGER place 0643000, **land** (source J) | **50.67** |
| TIGER place 0643000, water (source J) | 27.18 |
| Union of the nine districts | **53.0611** |
| District area falling outside the place polygon | 0.0430 |
| Place area covered by no district | 24.8321 |

The districts cover 53.06 sq mi against 50.67 sq mi of land, so **every acre of land is inside a
district**, and the layer additionally takes in about 2.4 sq mi of harbour. The uncovered 24.83 sq mi
is a **single contiguous piece** whose representative point is at 33.72570, -118.18346 — in the outer
harbour, south of the shoreline — and it fits inside the 27.18 sq mi of water TIGER records. No
business-licence location among the 2,700 falls in it.

---

## The defect this wave fixes

Before, the nine district rows all carried `geo_id = '0643000'`, the TIGER place polygon. The spatial
probe that `check:reachability` runs — `ST_PointOnSurface` of the polygon, through the real
address-search join — returned this for a Long Beach point:

```
District 1  Councilmember  Mary Zendejas
District 2  Councilmember  Cindy Allen
District 3  Councilmember  Kristina Duggan
District 4  Councilmember  Daryl Supernaw
District 5  Councilmember  Megan Kerr
District 6  Councilmember  Suely Saro
District 7  Councilmember  Roberto Uranga
District 8  Councilmember  Tunua Thrash-Ntuk
District 9  Councilmember  Joni Ricks-Oddie
Long Beach Mayor / City Attorney / City Auditor / City Prosecutor
District 4  Supervisor     Janice Hahn
```

**Nine councilmembers for one address.** San José, the other half of this slice, already returns
exactly one — its ten districts have carried real polygons since the 2022 map was loaded.

⚠ `check-address-reachability.mjs` **deliberately does not** flag this. Its header records that "two
districts share a geo_id" was measured and rejected as an invariant, because roughly 700 rows match
it legitimately — and it names Long Beach's own 0643000 as the example. The condition is real and the
guard is right to ignore it; it needed a per-jurisdiction probe to surface.

---

## Los Angeles County — re-verified, not rewritten

Migration 1635 already seated all eight LA County elected officials with dated terms and repaired the
duplicate district rows. Source I, revised **2026-08-07**, agrees row for row:

| Office | Person | First term began | In the database |
| --- | --- | --- | --- |
| Supervisor, District 1 | Hilda L. Solis | December 2014 | 2014-12-01, month |
| Supervisor, District 2 | Holly J. Mitchell | December 2020 | 2020-12-01, month |
| Supervisor, District 3 | Lindsey P. Horvath | December 2022 | 2022-12-01, month |
| Supervisor, District 4 | Janice Hahn | December 2016 | 2016-12-01, month |
| Supervisor, District 5 | Kathryn Barger | December 2016 | 2016-12-01, month |
| Assessor | Jeffrey Prang | December 2014 | 2014-12-01, month |
| District Attorney | Nathan Hochman | December 2024 | 2024-12-01, month |
| Sheriff | Robert G. Luna | December 2022 | 2022-12-01, month |

Districts 1 and 3, the Sheriff and the Assessor are on the 2026 ballot, and Solis reaches her term
limit in 2026. **All four turn over on the same December 2026 boundary as Long Beach's District 7,
and none of them turns over now.** No LA County vacancy was found for August 2026, the window source
I cannot cover.

> ⚠ **The three countywide officers were nearly missed.** They sit on a district row whose `state` is
> lowercase `ca`, while the five supervisorial rows carry uppercase `CA`. A first pass filtering
> `d.state = 'CA'` reported LA County as having no Assessor, no District Attorney and no Sheriff. The
> rule in CLAUDE.md — **always `lower(d.state)`** — is not stylistic.

---

## What this wave does NOT do

- **San José and Santa Clara County are wave CA-2.** San José's eleven seats carry the same undated
  backfill occupancy and need the same change-check; Santa Clara County has its three countywide
  officers and **no Board of Supervisors at all** — five seats and five polygons still to seat.
- **No headshots.** All 13 Long Beach officials and all 8 LA County officials already have one. Santa
  Clara County's three officers have none; that is CA-2 and CA-3.
- **No banner.** `long beach` is already a live `CURATED_LOCAL` key. It predates the program's
  certification standard and is re-certified in CA-3, not here.
