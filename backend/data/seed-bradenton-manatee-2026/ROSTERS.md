# Bradenton and Manatee County — verified roster, 2026-08-28

Wave FL-3 of the Knight Foundation cities program.

**Spec:** `docs/superpowers/specs/2026-08-28-knight-cities-program-design.md`
**Plan:** `docs/superpowers/plans/2026-08-28-knight-fl-wave-3-bradenton-manatee.md`
**Slice notes:** `.planning/knight-foundation/fl.md`

**18 offices, 17 people, 1 vacancy.** Bradenton: Mayor + 5 wards, all filled. Manatee County:
7 commissioners (1 vacant) + 5 constitutional officers.

The raw source pulls sit beside this file as untracked `_*.html`. They are the evidence; do not delete
them while this wave is open.

---

## Sources

| # | Source | Authoritative for | Pulled |
| --- | --- | --- | --- |
| S1 | `votemanatee.gov/elected-officials/` — Supervisor of Elections | the seat list for **both** bodies, and every published term expiry | 2026-08-28 |
| S2 | `votemanatee.gov/offices-up-for-election/` — Supervisor of Elections | the 2026 ballot, which independently proves the District 1 vacancy | 2026-08-28 |
| S3 | `cityofbradenton.com/council` + `/brown` `/kocher` `/barnebey` `/schuessler` `/moore` `/coachman` | Bradenton's seat list, name spellings, and three start dates | 2026-08-28 |
| S4 | `cityofbradenton.com` news, "Council Selects Leadership During Swearing-In Ceremony — January 6, 2025" | that Kocher and Coachman were **re-elected**, and that Vice Mayor is a council-elected role | 2026-08-28 |
| S5 | `mymanatee.org/…/board-of-county-commissioners` + 6 `commissioners-detail/*` pages | the board's composition, and four commissioners' service start months | 2026-08-28 |
| S6 | `manateesheriff.com`, `taxcollector.com`, `manateepao.gov`, `manateeclerk.com`, `votemanatee.gov/meet-the-supervisor-of-elections/` | each constitutional officer's own start date | 2026-08-28 |
| S7 | `mymanatee.org` news, "Manatee County Mourns the Passing of District 1 Commissioner Carol Ann Felts", published **2026-02-24** | the vacancy date | 2026-08-28 |
| S8 | `yourobserver.com/news/2024/nov/19/manatee-commissioners-sworn-in/` | the **2024-11-19** BOCC swearing-in date | 2026-08-28 |
| S9 | TIGERweb `Places_CouSub_ConCity_SubMCD/MapServer/4`, place `1207950` | `AREALAND` / `AREAWATER`, used by the ward tiling gate | 2026-08-28 |

Two independent publishers cover each body: the Supervisor of Elections plus the City of Bradenton
for the city, and the Supervisor of Elections plus Manatee County for the county.

---

## 🔴 Source defects found

**D1 — The Supervisor of Elections' two pages contradict each other on Commission District 1, and
the roster page is the wrong one.**
S1 still lists **Carol Ann Felts, District 1, term expires November 2028**. S2, published by the same
office, lists **"Board of County Commissioners: District 1 (2 year term)"** on the 2026 ballot — and a
two-year term exists only to fill an unexpired vacancy. The county's own commissioner page for Felts
has the HTML `<title>` "Vacant" and renders "The Honorable Vacant". **The seat is vacant.** S1 is
stale.

**D2 — The vacancy is a DEATH, not a resignation, and the plan guessed wrong about the date being
unpublished.** S7, the county's own announcement dated **2026-02-24**: "Manatee County Government is
saddened to announce the sudden passing of District 1 Commissioner Carol Ann Felts." Governor
DeSantis then issued **Executive Order 26-76** declaring the vacancy, and as of May 2026 had left the
seat empty rather than appointing a successor — which is why it reaches the 2026 ballot as a two-year
term. So `offices.vacant_since` **is** knowable: `2026-02-24`. The plan's fallback ("leave
`vacant_since` NULL") is not needed.

**D3 — The county's page for Felts is half-updated, and that is the trap.** The name is replaced with
"Vacant" while the biography beneath it still reads "Elected November 2024; Third Vice Chair, 2025"
with committee assignments running through 2026. Read as a roster it reports a sitting commissioner.

**D4 — The Supervisor of Elections misspells Ward 1 as "Jayne Kocker".** S3 says **Kocher**, and the
`mailto:` in S1's own Ward 1 block is `jayne.kocher@bradentonfl.gov`. Two of three agree, and one of
those two is inside the defective source. **Kocher.**

**D5 — Three of the four Manatee GIS services carry stale `COMMNAME` rosters, and even the current
one is wrong.** `BoCC_Districts` and `District_Boundaries` name Van Ostenbridge, Satcher and Turner;
`CountyCommissionDistricts_CopyFeatures` names Van Ostenbridge and Baugh; `BCC_DISTRICTS_LEGAL` names
Felts in District 1. All four are geometrically identical to 0.000 sq mi. **Never read a roster out
of a boundary layer** — the same lesson as Miami-Dade's stale `REPNAME` in `fl.md`.

**D6 — The Census geocoder does not resolve city hall's published address.** "101 Old Main Street"
returns 0 matches. The city's own footer explains why: city hall is "At the corner of Old Main Street
(**12th St. W.**) and Barcarrota Boulevard". `101 12TH ST W, BRADENTON, FL, 34205` geocodes to
`-82.5733305, 27.5000582`.

**D7 — Two published expiry dates are NOT election dates, and three people prove it.** Mayor Brown's
term expires January 2029 but he "has served as Mayor since **January 2021**" (S3). Kocher and
Coachman also expire January 2029 and were **re-elected** in November 2024 (S4). Kruse expires
November 2028 but has been a member since **2020** (S5). Deriving `term_start` from an expiry would
have been wrong for at least four of seventeen people.

**D8 — Hackney's own biography is stale in its arithmetic.** It says he was elected in 1992 and has
served "over 26 years". From 1993 that is 33 years. The election year is still usable; the tenure
sentence is not.

---

## Charter rulings

**R1 — Manatee County is a NON-CHARTER county**, so Fla. Const. art. VIII §1(d) applies unmodified
and the five constitutional officers are Sheriff, Tax Collector, Property Appraiser, Supervisor of
Elections and Clerk of the Circuit Court. The county's own page agrees: "the Board of County
Commissioners, together with Manatee County's **five** constitutional officers, comprise Manatee
County Government." A charter was still only being explored as of January 2026. **Nothing about this
template may be inherited by Leon, Palm Beach or Miami-Dade — each is confirmed separately.**

**R2 — The Mayor of Bradenton is `voting_powers = 'full'`.** The mayor is ex officio president of
the council and votes only to break a tie among the five ward members. Nashville's Vice Mayor has a
near-identical clause and `CC_0004` wrote that seat `non_voting`. This wave rules the other way,
deliberately: Nashville's Vice Mayor exists *only* to preside over the council, so "no vote in it" is
the whole truth about that seat. Bradenton's Mayor is the **chief executive**, elected citywide on
their own ballot line, sitting in an `Office of the Mayor` chamber of one. The tie-break is a council
procedure, not a limit on the mayoralty, and writing `non_voting` would tell a voter this executive
has no vote. The rule is carried in `offices.description`, because both read paths hide
`representation_note` when `voting_powers = 'full'`.
This ruling also makes the record robust to the November 2026 ballot, where an amendment would strip
the mayor's ex officio presidency and the tie-breaking vote: under this ruling that amendment changes
no column.

**R3 — Vice Mayor and Second Vice Mayor are ROLES, not offices.** S4: "the Council elected Councilman
Josh Cramer as Vice Mayor and Councilwoman Lisa Gonzalez Moore as Second Vice Mayor." They are chosen
by the council annually and rotate — the council page currently shows Kocher as Vice Mayor. Same
disposition as Asheville's Vice Mayor (`CA_0009`), and the opposite of Nashville's, where the Vice
Mayor is separately elected countywide. **No office rows.**

**R4 — Bradenton's City Clerk is appointed staff and out of scope.** S1 lists Tamara Melton as City
Clerk with no term. Not an elected office.

**R5 — Out of scope, considered and excluded:** the Manatee County School Board (5 elected), Mosquito
Control (3), Manatee River Soil & Water Conservation (5), seven fire districts, and roughly thirty
Community Development Districts. All elected; none is a county commission or a constitutional officer,
so none is in spec §3 stage 4. Also out of scope: Bradenton **Beach**, Palmetto, Anna Maria, Holmes
Beach and Longboat Key. ⚠ Their seats appear in S1 immediately after Bradenton's and are titled
"Commissioner, Ward N" — near-identical to Bradenton's. Every parse of S1 must be scoped to the
"City of Bradenton" heading.

---

## How `term_start` was derived

`term_start` is the start of **continuous occupancy by that person**, never the start of the current
term, and no `term_end` is written. `office_terms` has no `end_precision`, so a published expiry year
cannot become a `term_end` without inventing a day.

- **`day`** — a source publishes the actual date: Schuessler (2025-07-23), Barnebey (2020-06-24),
  Wells (2017-01-03), Siddique and McCann (2024-11-19).
- **`month`** — a source publishes month and year: Brown ("since January 2021"), Ballard, Rahn and
  Bearden ("Elected November 2022"), Kruse ("Elected November 2020"). Also Farrington, where the
  source publishes the election year (2024) and Florida seats county officers on the first Tuesday
  after the first Monday in January following, so January 2025 is statutory rather than guessed.
- **`year`** — Burton and Hackney. Both sources publish only an **election** year, 1992, so occupancy
  began in January 1993. The month is statutory as above, but over thirty-three years and many
  re-elections the risk of an unpublished mid-term origin is higher, so the conservative precision is
  kept.
- **`unknown`** — Kocher, Moore and Coachman. **No publisher gives a start date.** S4 proves Kocher
  and Coachman were re-elected in November 2024, so occupancy began at or before January 2021, but
  "re-elected" does not prove which term was the first. The Supervisor of Elections' results archive
  is behind a JavaScript file-manager and exposes only 2004–2007 statically. Per CLAUDE.md these get
  an open-ended term with `start_precision => 'unknown'` rather than a guess. **A too-late
  `term_start` is a false statement about history, and there is no `end_precision` to soften it.**
  ▶ Follow-up: pin these three from the city clerk's January 2021 and January 2023 organisational
  minutes.

## 🔴 What was deliberately NOT written

**Carol Ann Felts' closed term is not written, though every date for it is now known** — sworn in
2024-11-19 (S8), died 2026-02-24 (S7), so `how_ended => 'died'`. Writing it would make District 1
answer "who represented me in 2025" correctly, which is exactly what ADR 0002 exists for.

It is excluded for consistency: **FL-2 wrote no predecessor terms for any of its five legislative
vacancies**, and `fl.md` records their last days as notes only. Doing it for one county seat in one
wave would leave Florida internally inconsistent. Adding predecessor history for all six Florida
vacancies is coherent work, and it should be done deliberately, together. The evidence is captured
here so that it can be.

`offices.vacant_since = 2026-02-24` **is** written — that is a fact about the office, not a span
about a person.

---

## Roster

### City of Bradenton

| Seat | Slug | Name | external_id | term_start | precision | how_started | source |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Mayor | mayor | Gene Brown | -1240001 | 2021-01-01 | month | elected | cityofbradenton-brown-bio-2026-08-28 |
| Ward 1 | ward-1 | Jayne Kocher | -1240002 |  | unknown | elected | cityofbradenton-council-2026-08-28 |
| Ward 2 | ward-2 | Marianne Barnebey | -1240003 | 2020-06-24 | day | appointed | cityofbradenton-barnebey-bio-2026-08-28 |
| Ward 3 | ward-3 | Kemp Schuessler | -1240004 | 2025-07-23 | day | appointed | cityofbradenton-schuessler-bio-2026-08-28 |
| Ward 4 | ward-4 | Lisa Gonzalez Moore | -1240005 |  | unknown | elected | cityofbradenton-council-2026-08-28 |
| Ward 5 | ward-5 | Pam Coachman | -1240006 |  | unknown | elected | cityofbradenton-council-2026-08-28 |

### Manatee County

| Seat | Slug | Name | external_id | term_start | precision | how_started | source |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Commissioner, District 1 | commissioner-1 | VACANT |  |  |  |  | mymanatee-d1-vacant-2026-02-24 |
| Commissioner, District 2 | commissioner-2 | Amanda Ballard | -1240011 | 2022-11-01 | month | elected | mymanatee-ballard-bio-2026-08-28 |
| Commissioner, District 3 | commissioner-3 | Tal Siddique | -1240012 | 2024-11-19 | day | elected | manatee-bocc-swearing-in-2024-11-19 |
| Commissioner, District 4 | commissioner-4 | Mike Rahn | -1240013 | 2022-11-01 | month | elected | mymanatee-rahn-bio-2026-08-28 |
| Commissioner, District 5 | commissioner-5 | Dr. Bob McCann | -1240014 | 2024-11-19 | day | elected | manatee-bocc-swearing-in-2024-11-19 |
| Commissioner, District 6 (At-Large) | commissioner-6 | Jason Bearden | -1240015 | 2022-11-01 | month | elected | mymanatee-bearden-bio-2026-08-28 |
| Commissioner, District 7 (At-Large) | commissioner-7 | George Kruse | -1240016 | 2020-11-01 | month | elected | mymanatee-kruse-bio-2026-08-28 |
| Sheriff | sheriff | Charles R. "Rick" Wells | -1240021 | 2017-01-03 | day | elected | manateesheriff-wells-bio-2026-08-28 |
| Tax Collector | tax-collector | Ken Burton, Jr. | -1240022 | 1993-01-01 | year | elected | manatee-taxcollector-about-2026-08-28 |
| Property Appraiser | property-appraiser | Charles E. Hackney | -1240023 | 1993-01-01 | year | elected | manateepao-hackney-bio-2026-08-28 |
| Supervisor of Elections | supervisor-of-elections | Scott Farrington | -1240024 | 2025-01-01 | month | elected | votemanatee-farrington-bio-2026-08-28 |
| Clerk of the Circuit Court and Comptroller | clerk-of-circuit-court | Angelina "Angel" Colonneso | -1240025 | 2015-09-01 | month | appointed | manateeclerk-full-circle-blog-2026-08-28 |

**Colonneso's `appointed`** is not a slip. Her office's own account: her predecessor R.B. "Chips"
Shore died on 2015-07-29, she was named interim clerk that afternoon, and she was "officially sworn in
as Manatee County's first female clerk of the circuit court in **September 2015** after spending two
months serving as the interim clerk". She then "began her new four-year term in January 2017" after
winning election. Continuous occupancy of the office starts at the September 2015 swearing-in; the two
interim months were an acting capacity, not the office.

**No party affiliation is recorded.** S1 prints `(R)` beside all seventeen names. Discarded — party
lives on `races.primary_party`.

<!-- COUNTS: city_offices=6 city_people=6 county_offices=12 county_people=11 vacancies=1 -->
