# Tarrant County TX seed — roster collection (2026-08-08)

Scope agreed with operator: **Tarrant County + big-six cities**, depth = roster + geofence + browse
(no headshots/banners/stances this pass). **Collin County's empty shell folded in.**

⛔ **NOTHING SEEDED YET. No migration written.** This file is the verified-source record and the
staging point for the seed. **7 of 8 governments have a complete verified roster; Euless does not.**

---

## Which six — settled from Census, not from memory

TIGERweb 2020 Incorporated Places (layer 25) for all 1,223 TX places, prefiltered to a Tarrant
bounding box, then **each place's internal point reverse-geocoded to a county** via the keyless
Census geocoder. 45 candidates resolved.

| # | city | 2020 pop | place FIPS | county of internal point |
|---|---|---|---|---|
| 1 | Fort Worth | 918,915 | 4827000 | Tarrant 48439 |
| 2 | Arlington | 394,266 | 4804000 | Tarrant 48439 |
| 3 | Mansfield | 72,602 | 4846452 | Tarrant 48439 |
| 4 | North Richland Hills | 69,917 | 4852356 | Tarrant 48439 |
| 5 | Euless | 61,032 | 4824768 | Tarrant 48439 |
| 6 | Grapevine | 50,631 | 4830644 | Tarrant 48439 |

⚠ **Mansfield outranks North Richland Hills** (72,602 vs 69,917) — the reverse of the order I gave the
operator from memory. The *set* of six was right; the ranking was not.

🔴 **Two deliberate exclusions — the Frisco two-county trap.** Both genuinely have Tarrant territory
but their internal point is in another county:
- **Grand Prairie**, 196,100 (`4830464`) → **Dallas County**. By population it would rank #3 here.
- **Burleson**, 47,641 (`4811428`) → **Johnson County**.
⚠ **Mansfield straddles** into Johnson and Ellis; **Westlake** into Denton. Note when geofencing.

Next tier if widened: Bedford 49,928 · Haltom City 46,073 · Keller 45,776 · Hurst 40,413 ·
Southlake 31,265 · Colleyville 26,057 · Benbrook 24,520 · Saginaw 23,890 · Watauga 23,650.

---

## 🔴 Access findings — three separate traps, all hit in one night

**1. Akamai blocks Fort Worth, Arlington and Euless outright.** All three return **HTTP 403 with
~400-byte bodies** citing `errors.edgesuite.net`. Full browser headers (Accept, Accept-Language,
Sec-Fetch-*) did not help. Identical to `newtonma.gov`. **Never read this as "page absent".**

**2. A 200 is not the page you asked for.** `nrhtx.com/166/City-Council` returns **200 with 20 KB of
the Fire Department employment page**. The real council page is `/359/City-Council`. Likewise every
Legistar host probed (`fortworth`, `fortworthtexas`, `arlingtontx`, `arlington`) returns **200 with a
136-byte stub**. Check the body, never the status.

**3. Wayback rescued Newton but does NOT rescue this cluster — check capture vintage.**
Latest captures are Fort Worth **2025-02**, Arlington **2024-04**, Euless **2024-11**, and Texas holds
municipal elections every May. Ballotpedia confirms **Fort Worth's and Arlington's last council
elections were both 2026** — so every archived roster is at least one election stale. Seeding from
them would have reproduced the Beverly Hills failure (mig 1546) exactly.
⚠ Also: my first CDX sweep returned **0 captures for every path**, which looked like absence. A
control (`example.com`) proved the probe was fine — the real answer was that my *guessed paths were
wrong*, and Fort Worth's `/government/city-council` is archived only as a **404**. Always run the
control before believing an empty result.

✅ **What actually worked: official GIS feature services.** Both big cities publish council-district
layers carrying the sitting member as an attribute, on hosts that are *not* behind the city WAF.

---

## ✅ VERIFIED ROSTERS — 7 governments, 52 people

### Tarrant County Commissioners Court — 5
`https://www.tarrantcountytx.gov/en/commissioners-court.html` (200). Roster appears **twice** on the
page; both copies agree.
| seat | name |
|---|---|
| County Judge | Tim O'Hare |
| Commissioner, Precinct 1 | Roderick Miles Jr |
| Commissioner, Precinct 2 | Alisa Simmons |
| Commissioner, Precinct 3 | Matt Krause |
| Commissioner, Precinct 4 | Manny Ramirez |

### Collin County Commissioners Court — 5  (fills the existing 0-chamber shell, geo_id 48085)
`https://www.collincountytx.gov/government/commissioners-court/{county-judge,precinct-1..4}` (all 200).
| seat | name |
|---|---|
| County Judge | Chris Hill |
| Commissioner, Precinct 1 | Susan Fletcher |
| Commissioner, Precinct 2 | Cheryl Williams |
| Commissioner, Precinct 3 | Darrell Hale |
| Commissioner, Precinct 4 | Duncan Webb |

### City of Fort Worth — 11
Mayor from Ballotpedia (`Fort_Worth,_Texas`, 200); districts from the **City's own GIS**:
`mapit.fortworthtexas.gov/ags/rest/services/CIVIC/OpenData_Boundaries/MapServer/2` (200).
| seat | name |
|---|---|
| Mayor | Mattie Parker |
| District 2 | Carlos Flores |
| District 3 | Michael D. Crain |
| District 4 | Charles Lauersdorf |
| District 5 | Deborah Peoples |
| District 6 | Mia Hall |
| District 7 | Macy Hill |
| District 8 | Chris Nettles |
| District 9 | Elizabeth M. Beck |
| District 10 | Chris Jamieson |
| District 11 | Jeanette Martinez |

✅ Strong currency signal: four district records carry a `DATESTAMP` of **2026-08-05**, three days
before this pass. Cross-check holds: 10 districts + mayor = **11**, exactly Ballotpedia's seat count.
⚠ **Districts run 2–11 — there is no District 1.** Ten districts plus the mayor still reconciles to
11 seats, so the likeliest reading is that the mayor occupies the "1" slot. **Confirm before seeding**;
do not invent a District 1 office.

### City of Arlington — 9
`services.arcgis.com/jXi5GuMZwfCYtZP9/.../CouncilDistricts_2025/FeatureServer/0` (200) + Ballotpedia
for the mayor. Districts 1–5 single-member; 6–8 at-large.
| seat | name | first elected | term expires |
|---|---|---|---|
| Mayor | Jim Ross | (Jun 2021) | — |
| District 1 | Mauricio Galante | May 2024 | May 2027 |
| District 2 | Raul H. Gonzalez (Deputy Mayor Pro Tem) | Nov 2020 | May 2027 |
| District 3 | Nikkie Hunter | Jun 2021 | **May 2026** ⚠ |
| District 4 | Tom Ware | **May 2026** | May 2029 |
| District 5 | Brittney Garcia-Dumas | **May 2026** | May 2029 |
| District 6 (At-Large) | Long Pham | Jun 2022 | May 2027 |
| District 7 (At-Large) | Bowie Hogg | May 2022 | May 2027 |
| District 8 (At-Large) | Dr. Jason Shelton | May 2019 | **May 2026** ⚠ |

🔴 **Arlington publishes TWO council layers and they DISAGREE.** The older `CouncilBoundaries` still
shows **Andrew Piel** (D4) and **Rebecca Boxall** (D5) — the members Ware and Garcia-Dumas replaced.
`CouncilDistricts_2025` is the live one, settled by its `FirstElected: May 2026` on exactly those two
seats. **Had I taken the first layer I found, I would have seeded two wrong people.**
⚠ **D3 and D8 are NOT cleared.** Both show `TermExpires: May 2026`, already past, with no refresh —
so either they were re-elected and the field is stale, or they have been replaced. Ballotpedia has no
`Municipal_elections_in_Arlington,_Texas_(2026)` page (404). **Verify these two before seeding.**

### City of Mansfield — 7
`https://www.mansfieldtexas.gov/382/City-Council` (200). Council-Manager; **all seven elected at
large** to three-year terms — Mansfield has no districts, the "Places" are ballot positions only.
| seat | name |
|---|---|
| Mayor (Place 1) | Michael Evans |
| Place 2 | Tamera Bounds |
| Place 3 | Brent Newsom |
| Place 4 | Juan Fresquez |
| Place 5 | Todd Simmons |
| Place 6 (Mayor Pro Tem) | Todd Tonore |
| Place 7 | Dr. Jim Vaszauskas |

🔴 **Mansfield's CivicPlus slugs are stale — never read a name off an href.** `/423/Casey-Lewis`
renders as **Juan Fresquez**; `/430/Todd-Tenore` is **Todd Tonore** (the slug also misspells him);
`/418/David-Cook` is the *former* mayor, who has since moved to the Texas House, while the sitting
mayor is Michael Evans. Two different names even share the id `/421/`. **Take names from the rendered
body in document order.**

### City of North Richland Hills — 8
`https://www.nrhtx.com/359/City-Council` (200). Mayor + **seven** places, all at-large, three-year
terms. Corroborated by the page's own photo caption naming all eight.
| seat | name |
|---|---|
| Mayor | Jack McCarty |
| Place 1 | Cecille Delaney |
| Place 2 | Brianne Goetz |
| Place 3 | Danny Roberts |
| Place 4 | Matt Blake |
| Place 5 | Billy Parks |
| Place 6 | Russ Mitchell |
| Place 7 (Mayor Pro Tem) | Kelvin Deupree |

### City of Grapevine — 7
`https://www.grapevinetexas.gov/847/City-Council` (200). Mayor + six at-large Places, three-year terms.
| seat | name |
|---|---|
| Mayor | William D. Tate |
| Place 1 (Mayor Pro Tem) | Paul Slechta |
| Place 2 | Sharron Rogers |
| Place 3 | Leon Leal |
| Place 4 | Sean Shope |
| Place 5 | Chris Coy |
| Place 6 | Duff O'Dell |

---

## ◐ City of Euless — 4 of 7 seats sourced from official canvassed results

✅ **The Tarrant County elections route worked** — that host is not Akamai-blocked. Cumulative reports
live at `/content/dam/main/elections/<yr>/<code>/reports/cumulative.pdf`; extracted with `pdftotext`.

| seat | name | source |
|---|---|---|
| Place 1 | **Tim Stinneford** | May 3 2025, unopposed, 1,723 (100%) — *Official Results* |
| Place 3 | **Eddie Price** | May 3 2025, 1,400 (65.00%) def. Lee Ann Folau 754 (35.00%) — *Official* |
| Place 5 | **Annabel Jones Eads** ⚠ | Jun 15 2024 runoff, 376 (51.09%) def. Joseph A. Robinson 360 (48.91%) |
| Place 6 | **Tika Paudel** | May 4 2024, unopposed, 1,145 (100%) — *Official Results* |

⚠ **Place 5 is NOT cleared.** It went to a runoff (the May 2024 first round was a 4-way: Eads 44.01%,
Robinson 34.30%, Duru 12.67%, Handley 9.02% — no majority). **Both** June-2024 runoff reports Tarrant
publishes (`cumulative.pdf` and `precinct.pdf`) are stamped **"Unofficial Results"**, and one shows
*Precincts Reporting 0 of 54*. On a **16-vote margin** that is not good enough — every other Euless
figure above comes from a report stamped *Official Results*. Confirm before seeding Place 5.

🔴 **A `-layout` extraction gave me Place 3 BACKWARDS.** `pdftotext -layout` placed "Lee Ann Folau" on
the 1,400-vote row; the raw (non-layout) extraction shows the candidate order is Folau **then** Price,
making **Price** the 65% winner. Reading the layout version would have seeded the losing candidate.
**Cross-check every multi-candidate race with a non-layout extraction.**

### ⛔ Mayor, Place 2, Place 4 — not obtainable from results at all
Verified across all three official cumulative reports: **May 2024 carried only Places 5 and 6, May
2025 only Places 1 and 3, and May 2026 carried no Euless council race whatsoever** (Euless ran
propositions A–T, a full charter rewrite, and nothing else). These three seats appear in **no**
election Tarrant County has published.
🔑 That is the signature of **unopposed candidates whose election was cancelled** — under Texas
Election Code an unopposed candidate is declared elected and never appears in results. Same
"unopposed vanishing" pattern already in the election-resolve playbook. **Absence here is evidence
about the ballot, not about the officeholder.**

### Routes now exhausted for those three seats
- Live `eulesstx.gov` — Akamai 403 on every path.
- Wayback per-seat pages (`/city-hall/euless-city-council/{mayor,place-1..6}`) — captures are actually
  **recent (2025-10 to 2026-04)**, better than I first reported; my earlier "Nov 2024" reading came
  from a `collapse=urlkey` sweep that returns the *first* capture, not the latest. But the site is
  **JavaScript-rendered**: 97 KB of HTML that is entirely navigation, officeholder never in the markup.
  **No Wayback capture of this site will ever carry a name.**
- `/community/history/leaders-past-and-present/list-of-council-members` — same JS shell.
- Ballotpedia `Euless,_Texas` — 200 and 123 KB but **no officeholder infobox**; below their threshold.
- ArcGIS — no Euless council layer exists.
▶ **Remaining ideas**: Euless council **agenda/minutes PDFs** (usually list members present, often on
a separate document host), the **May 2026 charter-election order** (signed by the mayor), or NCTCOG's
member-government directory.

---

## Seeding plan — ready once Euless Mayor/P2/P4 + P5, and Arlington D3/D8, are cleared

1. `essentials.governments`: **Tarrant County** (new, `48439`) + 6 LOCAL city rows with place FIPS as
   `geo_id`. **Collin County already exists** (`48085`) — add chambers to it, do not insert.
2. One chamber per government (Commissioners Court / City Council) → offices → `office_terms`.
   ⚠ Occupancy is a **two-gate** check (`term_end` + `is_incumbent`) and the daterange is inclusive —
   re-read the office_terms notes before writing.
3. Geofences from TIGER (county 48439; places as listed above).
4. `essentials/src/lib/coverage.js` — new chips in the existing Texas block, **`hasContext` omitted**
   (no stances this pass; the flag must stay DB-honest).
5. VERIFY: a real Fort Worth street address resolves to Mayor Parker **and** the correct district
   councilor; a Tarrant address returns the right precinct commissioner.
