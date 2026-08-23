# Asheville + Buncombe County — verified roster, 17 seats

NC deep-seed program, **wave 3**.
Spec: [`.planning/todos/2026-08-21-nc-durham-asheville-deep-seed.md`](../../../.planning/todos/2026-08-21-nc-durham-asheville-deep-seed.md)
Plan: [`docs/superpowers/plans/2026-08-23-nc-wave-3-asheville-buncombe.md`](../../../docs/superpowers/plans/2026-08-23-nc-wave-3-asheville-buncombe.md)

Compiled **2026-08-23**. Consumed by `scripts/gen-buncombe-asheville-migrations.mjs` → `CA_0009` / `CA_0010`.

**17 seats:** 7 City of Asheville (all at-large) + 10 Buncombe County (chair + 6 district
commissioners + 3 countywide row offices).

**No party affiliation is recorded here or in the migrations.** The sources below all publish party;
it is deliberately dropped. Party lives on `races.primary_party` — which ballot a voter requests —
never on an officeholder.

---

## Sources

| # | Source | Retrieved | What it establishes |
|---|---|---|---|
| S1 | `https://media.buncombenc.gov/common/election/elected-officials.pdf` — Buncombe County **Election Services**, "WHO IS MY REPRESENATIVE?" | 2026-08-23 | **The authoritative roster.** Every Buncombe and Asheville seat, officeholder, and *term-expiry* year. The county's own elected-officials listing. |
| S2 | `https://www.ashevillenc.gov/government/meet-city-council/` — City of Asheville, "Meet City Council" (page states "last updated or reviewed on April 29, 2026") | 2026-08-23 | Asheville's 7 seats, roles, and **service-start** month for each council member. |
| S3 | `https://www.buncombenc.gov/705/County-Commissioners` (via `buncombecounty.org/705`) | 2026-08-23 | Live commission roster with district assignment per member. Independent corroboration of S1. |
| S4 | `https://gis.buncombecounty.org/arcgis/rest/services/bcmap_VotingDistricts3/MapServer/7` — attributes `DISTRICT`, `Commission`, `Commissi_1` | 2026-08-23 | Third independent confirmation of the six district commissioners and their districts, carried on the boundary layer itself. |
| S5 | `https://www.buncombenc.gov/568/Sheriffs-Office` | 2026-08-23 | Sheriff's full name (`Quentin E. Miller`) and "since taking office in 2018". |
| S6 | Press, Whitesides' 2016 appointment — The Urban News ("Buncombe County Democrats Appoint First African American Commissioner", 2016), WLOS ("Whitesides sworn-in as county commissioner") | 2026-08-23 | Whitesides was **appointed** in Dec 2016 to the District 1 seat vacated when Brownie Newman became Chair; elected 2018. |
| S7 | Press, Ball's 2025 appointment — WLOS, BPR (2024-12-23), Mountain Xpress, Buncombe Dems (CEC) | 2026-08-23 | Ball was chosen by the county Democratic Party 2024-12-18 and **appointed/sworn 2025-01-07** to fill Amanda Edwards' District 3 seat. |
| S8 | Press, Christy's 2023 appointment — Mountain Xpress ("Jean Marie Christy to be appointed Clerk of Superior Court") | 2026-08-23 | Christy was **appointed in 2023** on Steven Cogburn's retirement, by Senior Resident Superior Court Judge Alan Thornburg; then elected in the Nov 2024 special election. |
| S9 | Wikipedia + City of Asheville member page, Manheimer | 2026-08-23 | Manheimer became **Mayor** 2013-12-10; her 2009 date is council service. |

---

## 🔴 Source defects found

**1. S1's year in parentheses is TERM EXPIRY, not a start date — and reading it as "elected four
years earlier" is wrong for 5 of 17 people.** This is wave 2's trap (`term_start` is the day this
person began holding **this seat**; continuous service through a re-election is ONE term row) and it
bites harder here because Buncombe fills vacancies by appointment often:

| Person | Naive read from S1 | Actual | Why it matters |
|---|---|---|---|
| Al Whitesides | elected 2022 | **appointed 2016-12** | understates tenure by 6 years, wrong `how_started` |
| Terri Wells | elected 2024 | **elected 2020-12** | understates tenure by 4 years |
| Parker Sloan | elected 2024 | **elected 2020-12** | understates tenure by 4 years |
| Drew Ball | elected 2022 | **appointed 2025-01** | credits him with *Edwards'* 2022 election; overstates tenure by 2 years |
| Jean Marie Christy | elected 2022 | **appointed 2023** | credits her with *Cogburn's* election |

**2. S2's "Term:" string is service on the BODY, not tenure in the SEAT.** The Mayor row reads
"December 2009 – December 2026". December 2009 is when Manheimer joined **council**; she became
**Mayor on 2013-12-10** (S9). Using S2 verbatim would assert she has been Mayor four years longer
than she has.

**3. S2 lists "Vice Mayor" as though it were a distinct post. It is not a seat.** Asheville seats a
mayor plus 6 council members, all elected at-large; the vice mayoralty is assigned by the body.
S. Antanette Mosley is recorded here as one of the **six council members**. Creating a seventh
"Vice Mayor" office would invent a seat that does not exist. (Contrast Buncombe's Chair — see below.)

**4. A search engine asserted "Jean Marie Christy (D) was elected Clerk of Court in 2026".** She did
file for the November 2026 election, which has not happened — today is 2026-08-23. Christy *is*
nonetheless the sitting Clerk, because she was appointed in 2023 and elected in the 2024 **special**
election; S1's `(2026)` is her term expiry. **The summary reached a true conclusion by false
reasoning**, and the same phrasing about a genuinely non-incumbent candidate would have seated
someone who holds no office. Never accept a search summary as a roster source.

**5. `essentials.politicians` contains FEC ALLCAPS committee junk that matches on surname.** A
surname sweep for these 17 returned rows like `HOLSTEGE FOR ASSEMBLY 2022; CHRISTY` and
`SMITH FOR ASSEMBLY 2016; CHRISTY` — committee names, not people, with NULL `external_id`. Also three
real but distinct people: `Chaney Mosley` (-470609), `George Whitesides` (-100017), `Steve Christy`
(-4007004). **All separable by first name**, which is exactly why the identity rule is first+last
plus an explicit `external_id`, never surname.

**6. The county changed domains mid-program.** `buncombecounty.org` now redirects to
`buncombenc.gov`, and a `countycenter/news-detail.aspx?id=...` URL 404s on both. Cite `buncombenc.gov`.

---

## 🔴 The chair rule INVERTS between Durham (wave 2) and Buncombe (wave 3)

Wave 2 correctly refused to create a "Chair" office for Durham, whose 5 commissioners are all
at-large and whose chairmanship rotates by board vote.

**Buncombe is the opposite.** A 2011 local act seats **7** commissioners: the **chair elected
countywide** plus **six by district, two per district**. Amanda Edwards ran for Chair as its own
ballot line — S1 lists it as a separate office with its own term expiry, and her move from a District
3 seat to Chair is what created the vacancy Drew Ball was appointed to fill (S7). Chair is therefore
a real office here.

**Do not carry wave 2's rule across.** And do not carry this one back into Asheville, where Vice
Mayor genuinely is only a role.

---

## City of Asheville — 7 seats

All seven elected **at-large, citywide**, nonpartisan, staggered 4-year terms (3–4 seats every 2
years). No wards, no districts — confirmed by S1 and S2, which closes the spec's open question about
whether a district plan had been reinstated for 2026. Offices hang off the Asheville city place
polygon, `geo_id 3702140` / `mtfcc G4110`.

| # | `external_id` | `full_name` | first / last | Office title | `term_start` | `start_precision` | `how_started` | Source |
|---|---|---|---|---|---|---|---|---|
| 1 | `-3740001` | Esther E. Manheimer | Esther / Manheimer | Mayor | `2013-12-10` | `day` | `elected` | S1, S2, S9 |
| 2 | `-3740002` | S. Antanette Mosley | Antanette / Mosley | Council Member | `2020-09-01` | `month` | `appointed` | S1, S2 |
| 3 | `-3740003` | Sheneika Smith | Sheneika / Smith | Council Member | `2017-12-01` | `month` | `elected` | S1, S2 |
| 4 | `-3740004` | Kim Roney | Kim / Roney | Council Member | `2020-12-01` | `month` | `elected` | S1, S2 |
| 5 | `-3740005` | Sage Turner | Sage / Turner | Council Member | `2020-12-01` | `month` | `elected` | S1, S2 |
| 6 | `-3740006` | Maggie Ullman | Maggie / Ullman | Council Member | `2022-12-01` | `month` | `elected` | S1, S2 |
| 7 | `-3740007` | Bo Hess | Bo / Hess | Council Member | `2024-12-01` | `month` | `elected` | S1, S2 |

Notes:

- **Mosley's start is an appointment.** September 2020 is mid-term; she filled a vacancy. `how_started`
  must be set explicitly — do not let `seat_officeholder`'s `p_how_started` default of `'elected'`
  fall through.
- **`month` precision is honest, not lazy.** S2 publishes month and year only ("December 2020"). The
  day is not stated, so `term_start` is the first of the month with `start_precision => 'month'`.
  Manheimer alone gets `day`, because S9 states 2013-12-10.
- **Bo Hess** is the name his own city government publishes (S2). S1 renders him **"Roberto (Bo)
  Hess"**. `full_name` follows S2 as the more voter-recognisable form; the fuller form is recorded
  here so a future name match can reconcile either.

---

## Buncombe County — 10 seats

Four offices hang off the **existing** county polygon `geo_id 37021` / `mtfcc G4020` /
`district_type COUNTY` — 🔴 that pairing is mandatory, because `geo_id 37021` alone also matches
`STATE_UPPER` Senate District 21 and `STATE_LOWER` House District 21.

Six hang off the three commission districts loaded as `mtfcc X0034`.

| # | `external_id` | `full_name` | first / last | Office title | District | `term_start` | `start_precision` | `how_started` | Source |
|---|---|---|---|---|---|---|---|---|---|
| 8 | `-3740008` | Amanda Edwards | Amanda / Edwards | Chair, Board of Commissioners | countywide `37021` | `2024-12-01` | `month` | `elected` | S1, S3 |
| 9 | `-3740009` | Al Whitesides | Al / Whitesides | Commissioner, District 1 | `…-district-1` | `2016-12-01` | `month` | `appointed` | S1, S3, S4, S6 |
| 10 | `-3740010` | Jennifer Horton | Jennifer / Horton | Commissioner, District 1 | `…-district-1` | `2024-12-01` | `month` | `elected` | S1, S3, S4 |
| 11 | `-3740011` | Martin Moore | Martin / Moore | Commissioner, District 2 | `…-district-2` | `2022-12-01` | `month` | `elected` | S1, S3, S4 |
| 12 | `-3740012` | Terri Wells | Terri / Wells | Commissioner, District 2 | `…-district-2` | `2020-12-01` | `month` | `elected` | S1, S3, S4 |
| 13 | `-3740013` | Parker Sloan | Parker / Sloan | Commissioner, District 3 | `…-district-3` | `2020-12-01` | `month` | `elected` | S1, S3, S4 |
| 14 | `-3740014` | Drew Ball | Drew / Ball | Commissioner, District 3 | `…-district-3` | `2025-01-01` | `month` | `appointed` | S1, S3, S4, S7 |
| 15 | `-3740015` | Quentin E. Miller | Quentin / Miller | Sheriff | countywide `37021` | `2018-01-01` | `year` | `elected` | S1, S5 |
| 16 | `-3740016` | Drew Reisinger | Drew / Reisinger | Register of Deeds | countywide `37021` | `2012-01-01` | `year` | `elected` | S1 |
| 17 | `-3740017` | Jean Marie Christy | Jean / Christy | Clerk of Superior Court | countywide `37021` | `2023-01-01` | `year` | `appointed` | S1, S8 |

Notes:

- **Two appointments, both mid-term, both must set `how_started` explicitly:** Whitesides (2016, filled
  Newman's seat on Newman becoming Chair) and Ball (2025, filled Edwards' seat on Edwards becoming
  Chair). Christy is a third (2023, on Cogburn's retirement). The same vacancy mechanism has now run
  three times on this board — assume it will recur.
- **Ball's day is documented but not from a primary source.** S7's outlets agree he was sworn
  **2025-01-07**; the county's own news release for it 404s on both domains. Recorded at `month`
  precision rather than claiming a `day` we could not verify officially. Upgrade to
  `2025-01-07` / `day` if the county record is recovered.
- **`year` precision for the three row officers** is what the sources support: S5 says "since taking
  office in 2018" for Miller, and Reisinger's and Christy's years are established without a month.
  `term_start` is written as `YYYY-01-01` with `start_precision => 'year'` — the January date carries
  no claim, the precision flag is what is load-bearing.
- 🔴 **Martin Moore won the March 2026 Democratic primary for District Attorney of the 40th
  Prosecutorial District.** He is still the sitting District 2 commissioner today — S1, S3 and S4 all
  list him, all read 2026-08-23 — so seating him is correct. But **expect this seat to vacate around
  January 2027**, which is a `vacate_office` / `seat_officeholder` follow-up, not something wave 3
  should pre-empt by leaving the seat empty.
- **Al Whitesides** and **Drew Ball** appear under those names in S1, S3 and S4; their county email
  local-parts are `alfred.whitesides@` and `daryl.ball@`, so their legal names are very likely Alfred
  and Daryl. `full_name` follows the published form. Recorded here so a future match on legal name
  reconciles rather than creating duplicates.

---

## Deliberately excluded

| Body / office | Why |
|---|---|
| **District Attorney, 40th Prosecutorial District** (Todd Williams) | Elected by **prosecutorial district**, not by county. Needs its own geography before it can be seated honestly — same call wave 2 made for Durham. |
| **Superior Court Judges, District 40** (2) and **District Court Judges, District 40** (7) | `JUDICIAL` district type with its own compass scale, and judicial districts are not the county polygon. |
| **Buncombe County School Board** (7: at-large + districts 1–6) | `SCHOOL` / `SCHOOL_BOARD` type on school-district geometry, which is not loaded for NC. A real future wave — S1 lists all 7 with term expiries. |
| **Asheville City Schools Board of Education** (7) | Same reason; a separate school administrative unit from the county's. |
| **Soil and Water Conservation District supervisors** (3 elected + 2 appointed) | Elected countywide but a distinct special-purpose district; no precedent in this repo yet. S1 lists them. |
| **Other Buncombe municipalities** — Biltmore Forest, Black Mountain, Montreat, Weaverville, Woodfin, Woodfin Water & Sewer | Out of wave 3's scope. **All of their place polygons are already loaded** (wave 2's `place` load covered all 552 NC `G4110` records), so each is a cheap future wave. S1 lists every seat. |

---

## Identity check — run before `CA_0010`

Measured **2026-08-23**: all 17 names, lowercased, matched against `essentials.politicians` →
**0 rows**. No wave-3 person exists in prod under any of these names, so all 17 are genuine inserts
guarded on the `external_id` band `-3740001 .. -3740017` (band `-3749999..-3740000` verified free,
0 rows).

Re-run before applying `CA_0010`, because prod moves:

```sql
SELECT p.full_name, p.external_id, coalesce(d.state,'-') AS st, coalesce(d.label,'(no office)') AS office
FROM essentials.politicians p
LEFT JOIN essentials.office_current_holder och ON och.politician_id = p.id
LEFT JOIN essentials.offices o ON o.id = och.office_id
LEFT JOIN essentials.districts d ON d.id = o.district_id
WHERE lower(p.full_name) IN (
  'esther e. manheimer','s. antanette mosley','sheneika smith','kim roney','sage turner',
  'maggie ullman','bo hess','amanda edwards','al whitesides','jennifer horton','martin moore',
  'terri wells','parker sloan','drew ball','quentin e. miller','drew reisinger','jean marie christy'
);
```

Any hit whose district `state` is not `nc` is a homonym to document, **never a row to reuse** — that
is the Mike Lee failure from wave 2, where a bare-name guard would have seated a sitting US Senator
on the Durham County Commission.
