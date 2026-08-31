# City of Miami + Miami-Dade County — reconciled roster, 2026-08-29

Wave **FL-6** of the Knight Foundation cities program.
Plan: [`2026-08-29-knight-fl-wave-6-miami-miami-dade.md`](../../../docs/superpowers/plans/2026-08-29-knight-fl-wave-6-miami-miami-dade.md)
Slice notes: [`fl.md`](../../../.planning/knight-foundation/fl.md)

**25 offices, 25 people, 0 vacancies** — 6 city and 19 county. This is the largest wave in the
Florida slice by a factor of two, and the only one with two governments over one anchor.

🔴 **Miami-Dade's Supervisor of Elections publishes a combined `elected-officials.pdf`, and it is the
only combined roster in this wave.** It is authoritative for **office titles and structure**. It is
**not** authoritative for occupancy: it is stamped *"As of June 4, 2026"* and still lists Daniel
Anthony Perez in HD-116. Every occupant below is confirmed against that office's own publisher.

⚠ **The SOE PDF carries NO municipal offices.** Miami's six come from `miami.gov`.

---

## 🔴🔴 READ THIS BEFORE YOU PARSE THE SOE PDF: `pdftotext -layout` MISASSIGNS EVERY ROW

The PDF must be extracted with **`pdftotext -table`**, never `-layout`.

Under `-layout` the *Elected Official* column is shifted relative to the *Office* column, so every
name lands on the wrong office. The shift is **not constant** — it is one row in the FEDERAL block
and two rows in the MIAMI-DADE COUNTY block, because a wrapped row absorbs a line.

Measured 2026-08-29, the same file read both ways:

| Office | `-layout` says | `-table` says (correct) |
| --- | --- | --- |
| Clerk of the Court and Comptroller | Rosanna "Rosie" Cordero-Stutz | **Juan Fernandez-Barquin** |
| Sheriff | Tomas Regalado | **Rosanna "Rosie" Cordero-Stutz** |
| Property Appraiser | Dariel Fernandez | **Tomas Regalado** |
| Mayor | Oliver Gilbert | **Daniella Levine Cava** |
| Commissioner, District 1 | Marleine Bastien | **Oliver Gilbert** |
| State House District 113 | Demi Busatta Cabrera | **Vacant** |
| State House District 116 | Kevin Chambliss | **Daniel Anthony Perez** |

🔴 **Nothing errors, and every wrong answer is a real person in a real office.** Cordero-Stutz *is* an
elected Miami-Dade officer; Oliver Gilbert *is* on this page. Only the pairing is wrong. This is the
Nashville certified-results defect in a new medium: a parser that silently mis-associates columns
produces a plausible, fully populated, entirely wrong roster.

⚠ **It would have moved the vacancy.** `-layout` puts *Vacant* on **HD-112**. The wave's acceptance
probe depends on **HD-113** being the vacant district. A session that read the PDF the obvious way
would have built the probe on the wrong seat and it would have passed.

⚠ The `pdftotext` on this machine is **Xpdf 4.00**, which has **no `-bbox`**. `-table` is the
available correct reader. Confirm the tool before trusting the text.

---

### City of Miami

| Seat | Slug | Name | external_id | term_start | precision | how_started | source |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Mayor | mia-mayor | Eileen Higgins | -1240081 | 2025-12-18 | day | elected | news-higgins-sworn-in-2025-12-18 |
| Commissioner, District 1 | mia-commissioner-1 | Miguel Angel Gabela | -1240082 | 2023-12-01 | month | elected | miami-city-officials + wlrn-2023-12-02 |
| Commissioner, District 2 | mia-commissioner-2 | Damian Pardo | -1240083 | 2023-12-01 | month | elected | miami-city-officials + wlrn-2023-12-02 |
| Commissioner, District 3 | mia-commissioner-3 | Rolando Escalona | -1240084 | 2025-12-17 | day | elected | news-escalona-runoff-2025-12-09 |
| Commissioner, District 4 | mia-commissioner-4 | Ralph "Rafael" Rosado | -1240085 | 2025-06-10 | day | elected | news-rosado-special-2025-06-03 |
| Commissioner, District 5 | mia-commissioner-5 | Christine King | -1240086 | 2021-11-10 | day | elected | news-king-sworn-in-2021-11-10 |

### Miami-Dade County

| Seat | Slug | Name | external_id | term_start | precision | how_started | source |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Mayor | mdc-mayor | Daniella Levine Cava | -1240091 | 2020-11-17 | day | elected | mdc-mayor-bio + mdc-qualifying-county-mayor |
| Commissioner, District 1 | mdc-commissioner-1 | Oliver Gilbert | **-1212402** | 2020-11-17 | day | elected | mdc-d01-about + mdc-qualifying-commissioner |
| Commissioner, District 2 | mdc-commissioner-2 | Marleine Bastien | -1240092 | 2022-11-22 | day | elected | mdc-d02-about |
| Commissioner, District 3 | mdc-commissioner-3 | Keon Hardemon | -1240093 | 2020-11-17 | day | elected | mdc-soe-elected-officials + mdc-qualifying-commissioner |
| Commissioner, District 4 | mdc-commissioner-4 | Micky Steinberg | -1240094 | 2022-11-22 | day | elected | mdc-d04-about |
| Commissioner, District 5 | mdc-commissioner-5 | Vicki L. Lopez | -1240095 | 2025-11-19 | day | appointed | mdc-d05-about |
| Commissioner, District 6 | mdc-commissioner-6 | Natalie Milian Orbis | -1240096 | 2025-05-06 | day | appointed | mdc-d06-release-2025-05-06 |
| Commissioner, District 7 | mdc-commissioner-7 | Raquel A. Regalado | -1240097 | 2020-11-17 | day | elected | mdc-d07-about + mdc-qualifying-commissioner |
| Commissioner, District 8 | mdc-commissioner-8 | Danielle Cohen Higgins | -1240098 | 2020-12-07 | day | appointed | news-cohen-higgins-appointed-2020-12-07 |
| Commissioner, District 9 | mdc-commissioner-9 | Kionne L. McGhee | -1240099 | 2020-11-17 | day | elected | mdc-d09-about + mdc-qualifying-commissioner |
| Commissioner, District 10 | mdc-commissioner-10 | Anthony Rodriguez | -1240100 | 2022-11-22 | day | elected | mdc-d10-about |
| Commissioner, District 11 | mdc-commissioner-11 | Roberto J. Gonzalez | -1240101 | 2022-11-23 | day | appointed | flgov-appointment-2022 |
| Commissioner, District 12 | mdc-commissioner-12 | Juan Carlos "JC" Bermudez | -1240102 | 2022-11-22 | day | elected | mdc-d12-about |
| Commissioner, District 13 | mdc-commissioner-13 | René Garcia | -1240103 | 2020-11-17 | day | elected | mdc-d13-about + mdc-qualifying-commissioner |
| Clerk of the Court and Comptroller | mdc-clerk-of-court | Juan Fernandez-Barquin | -1240105 | 2025-01-07 | day | elected | mdc-constitutional-offices |
| Sheriff | mdc-sheriff | Rosanna "Rosie" Cordero-Stutz | -1240106 | 2025-01-07 | day | elected | mdc-constitutional-offices |
| Property Appraiser | mdc-property-appraiser | Tomas Regalado | -1240107 | 2025-01-07 | day | elected | mdc-constitutional-offices |
| Tax Collector | mdc-tax-collector | Dariel Fernandez | -1240108 | 2025-01-07 | day | elected | mdc-constitutional-offices |
| Supervisor of Elections | mdc-supervisor-of-elections | Alina Garcia | -1240109 | 2025-01-07 | day | elected | mdc-constitutional-offices |

<!-- COUNTS: city_offices=6 city_people=6 county_offices=19 county_people=19 vacancies=0 -->

## Counts

- City of Miami Commission: 6 offices (Mayor + 5 single-member districts), 6 people, 0 vacant
- Miami-Dade Board of County Commissioners: 14 offices (Mayor + 13 single-member districts), 14 people, 0 vacant
- Miami-Dade Elected Officials: 5 offices, 5 people, 0 vacant
- **Precision:** day 23, month 2, year 0, unknown 0
- **How started:** elected 21, **appointed 4**

🔴 **The plan predicted TWO appointments. There are FOUR.** See "The four appointments" below.

---

## The one reuse — `mdc-commissioner-1` is `-1212402`, not a `-12400xx` value

`Oliver Gilbert` already exists in prod and **must be reused, not re-created**.

Measured 2026-08-29:

- `essentials.politicians` `7a20e912-27ff-45bd-9543-fd0dc9c46639`, `external_id = -1212402`,
  `full_name = 'Oliver Gilbert'`, **no `office_id`**, **no `data_source`**.
- One `race_candidates` row: office **`U.S. Representative`**, district **`Congressional District 24`**,
  `geo_id = 1224`, `mtfcc = G5200`, `district_type = NATIONAL_LOWER`, **`is_incumbent = false`**.

The person is Oliver Gilbert III — former Mayor of Miami Gardens, sitting Commissioner for
Miami-Dade District 1 — who **won the FL-24 Democratic primary on 2026-08-18** and faces Republican
T.E. Brown in November. The congressional row is a *candidacy*; the wave adds his *occupancy*.

⚠ **Do not change that row's `full_name`, `is_incumbent` or `data_source`.** The wave adds an
`office_terms` row and nothing else. The `Name` column above therefore reads **`Oliver Gilbert`**, the
prod form — **not** the county's published `Oliver G. Gilbert, III`, which goes in `alternate_names`.
Renaming a row another wave owns is out of scope.

▶ **Live churn: if he wins in November he resigns District 1.** The seat would then be vacant or
filled by appointment before this data is a year old.

### The dedup sweep found exactly one more candidate, and it is junk

All 25 names were checked against `essentials.politicians` with NFD-normalised first+last matching.
Two rows came back. One is Gilbert. The other matched **René Garcia**:

> `GARCIA FOR ARVIN CITY COUNCIL, RENE` — `external_id` **NULL**, no office, no data source.

That is **FEC ALLCAPS committee junk from Arvin, California**, not Miami-Dade's René Garcia.
**Not a reuse.** ⚠ It surfaced only because its `external_id` is NULL: a `string_agg` of
`external_id || full_name` renders NULL and the row reads as "0 matches" in a careless summary. **Count
the rows, do not read the aggregate.**

⚠ `essentials.politicians.external_id` is **`bigint`**, not text. Casting matters in every probe.

---

## `external_id` assignment

24 new ids, all inside **`-1240109 … -1240081`**, plus the single reuse `-1212402`. Verified free
2026-08-29: `SELECT count(*) … BETWEEN -1240109 AND -1240081` returned **0**.

FL-5 ended at **`-1240075`** (Palm Beach's 12 people, `-1240061 … -1240075`, itself gapped by body).
`-1240076 … -1240080` are free and deliberately left free, continuing the slice's gap-between-bodies
convention:

| Block | Range | Body |
| --- | --- | --- |
| City | `-1240081 … -1240086` | Miami Mayor + 5 commissioners |
| County | `-1240091 … -1240103` | Mayor + 12 commissioners (D1 reuses `-1212402`) |
| Officers | `-1240105 … -1240109` | the five Amendment 10 offices |

---

## Take-office rules — established per body, and they are NOT the same

**Three different rules apply to the 25 seats.** None was assumed; each is cited.

**1. Miami-Dade Mayor and Commissioners — the second Tuesday after the November general.**

From the county's own candidate qualifying handbooks, quoting the Charter:

> *"The term for Board of County Commissioners shall commence on the second Tuesday next succeeding
> the date of the General Election in November (November 17, 2020)."*
> — Miami-Dade County Charter, **Article 3, Section 3.01(A)**

> *"The term for Mayor shall commence on the second Tuesday next succeeding the date …"*
> — Miami-Dade County Charter, **Article 3, Section 3.01(D)**

Which gives, for the cycles in this wave:

| General election | Term commences |
| --- | --- |
| 2020-11-03 | **2020-11-17** (the handbook states this date itself) |
| 2022-11-08 | **2022-11-22** |
| 2024-11-05 | **2024-11-19** |

🔴 **The rule is corroborated in both directions.** Forwards: it reproduces the SOE PDF's own
*Current Term Ends* values exactly — **11/17/2026** for the 2022 cohort and **11/21/2028** for the
2024 cohort. Backwards: it matches independently published assumed-office dates for Gilbert and
Regalado (2020-11-17), McGhee (2020-11-17) and Steinberg (2022-11-22). **A derived day with two
independent confirmations is not an invented date.**

⚠ **`Current Term Ends` is NOT `term_end` and is not written by this wave.**

**2. The five constitutional officers — 2025-01-07.**

> *"In Nov. 2024, County residents elected the new constitutional officers, which assumed their role
> on **Jan. 7, 2025**."* — Miami-Dade *Constitutional Offices* page

Amendment 10 (adopted 2018-11-06) required charter counties to create or re-establish the five
independent offices. Jan 7 2025 is the first Tuesday after the first Monday in January, and the SOE's
*Current Term Ends* of **01/02/2029** is the same rule four years on. All five share the date.

⚠ **The Property Appraiser is the odd one.** Miami-Dade had an elected Property Appraiser *before*
Amendment 10 — it was simply not independent of the County. Tomas Regalado's occupancy still begins
2025-01-07: he was elected in Nov 2024 and took office with the other four.

**3. City of Miami — there is NO uniform rule, and that is the finding.**

Miami's six were each sworn in shortly after their own election or runoff was resolved, on four
different dates spanning seven months: **2021-11-10**, **2023-12** , **2025-06-10**, **2025-12-17**,
**2025-12-18**. Miami's elections run in **odd** years; terms are four years with a **two-term
lifetime limit** since a November 2024 charter amendment.

⚠ **Do not derive a Miami date from a cycle.** Each row above is sourced to its own swearing-in.

---

## `term_start` is the start of CONTINUOUS OCCUPANCY, not the current term

This follows FL-5, whose committed roster records Ric L. Bradshaw at **2005-01-04** and Anne M. Gannon
at **2007-01-01** — both re-elected many times since — and whose execution notes corrected Maria
Sachs from her re-election year to her **first** election.

Consequences visible in the tables above:

- **Christine King is `2021-11-10`, not 2025.** She was re-elected 2025-11-04 with 84.4% to a second
  and final term. The span did not break.
- **Six county seats read 2020** although their holders were re-elected in 2024.
- **Danielle Cohen Higgins reads `2020-12-07` and `appointed`**, although she has since been elected
  (2022-08-23). The span began with the appointment.
- **Roberto J. Gonzalez reads `2022-11-23` and `appointed`**, although he won a full term in 2024.

⚠ This is why `how_started` for D8 and D11 is `appointed` even though the SOE PDF shows them with
ordinary four-year terms and term-end dates. **The SOE describes the CURRENT TERM; `office_terms`
describes the SPAN.**

---

## The four appointments — the plan predicted two

| Seat | Person | Date | Replaced | Evidence |
| --- | --- | --- | --- | --- |
| County D5 | Vicki L. Lopez | **2025-11-19** | Eileen Higgins | County D5 page: *"appointed … and sworn in on November 19, 2025"* |
| County D6 | Natalie Milian Orbis | **2025-05-06** | Kevin Marino Cabrera | Appointed and sworn the same day; Cabrera left to be U.S. Ambassador to Panama |
| County D8 | Danielle Cohen Higgins | **2020-12-07** | Daniella Levine Cava | Appointed 10–1 to serve the last two years of Levine Cava's term; elected 2022-08-23 |
| County D11 | Roberto J. Gonzalez | **2022-11-23** | Joe Martinez (suspended) | Appointed by **Gov. Ron DeSantis**, not by the Commission; elected to a full term 2024 |

🔴 **D11 is appointed by the GOVERNOR, not the Commission.** Florida's Governor fills county-office
vacancies; Martinez was suspended after felony charges. Every other appointment here is a Commission
vote. **"Appointed" does not imply the same appointing authority — record who appointed.**

⚠ **The D5 appointment vote and the swearing-in are different days.** The Commission voted **7–5 on
2025-11-18**; Lopez was **sworn in 2025-11-19**, which is the date recorded, because occupancy begins
at the oath. Reporting gives the 18th; the county's own page gives the 19th. **The officeholder's own
publisher wins.**

---

## The Higgins → Lopez → HD-113 chain

One resignation moved three seats, and it is why the acceptance probe can never return a full answer
set at the anchor:

1. **Eileen Higgins** held **Miami-Dade County Commission District 5**, first elected 2018. She
   resigned to run for Mayor of Miami and served until **2025-11-05**.
2. She won the mayoral runoff on **2025-12-09** (59–41) and was sworn in as **Mayor of Miami** on
   **2025-12-18** — the city's first female Mayor and its first Democratic one in nearly 30 years.
3. The Commission appointed **Vicki L. Lopez** to the vacant county D5 seat (7–5, 2025-11-18; sworn
   2025-11-19).
4. Lopez was the sitting **State Representative for HD-113**. Leaving it **vacated HD-113**, which the
   SOE still records as **Vacant** through November 2026.

⚠ **So the anchor sits in a vacant state-house district.** Probe A cannot return a state
representative, and that is correct data, not a failure. Confirm HD-113 is still vacant before the
apply.

---

## The four in-wave surname pairs

Four surnames appear on **two different people in this one wave**. Any dedup or name-match step that
does not carry the office will collide them.

| Surname | Person A | Person B | Note |
| --- | --- | --- | --- |
| **Higgins** | Eileen Higgins — *Mayor of Miami* | Danielle Cohen Higgins — *County D8* | Unrelated. And Eileen Higgins previously held **county D5**, so both have county histories. |
| **Regalado** | Raquel A. Regalado — *County D7* | Tomas Regalado — *Property Appraiser* | **Daughter and father.** Tomas Regalado is also a former Mayor of Miami. |
| **Garcia** | René Garcia — *County D13* | Alina Garcia — *Supervisor of Elections* | Unrelated. René carries an accent; Alina does not. |
| **Fernandez** | Dariel Fernandez — *Tax Collector* | Juan Fernandez-Barquin — *Clerk* | 🔴 **A PREFIX, not an equality.** `full_name ILIKE '%Fernandez%'` matches both. |

🔴 **The Fernandez pair is the dangerous one.** The other three are equal-surname collisions that an
exact match catches. `Fernandez` is a strict prefix of `Fernandez-Barquin`, so a substring or
`LIKE '%…%'` match silently returns two rows where the author expected one — and both are
constitutional officers of the same county, so neither is filtered out by state or body.

⚠ **`Keon Hardemon` is a cross-layer collision too.** He is County D3 today, and the *2011* Miami-Dade
boundary layer and the geometry-less `TBLCOMMISSIONDISTRICT` still name him as a **City of Miami**
commissioner. Read rosters from rosters, never from a boundary layer.

---

## Name forms and alternates

`full_name` carries the published form and is what a voter sees.

| Slug | `full_name` | `alternate_names` | Why |
| --- | --- | --- | --- |
| `mdc-commissioner-1` | `Oliver Gilbert` | `Oliver G. Gilbert, III` | 🔴 Prod owns this row — see "The one reuse". The county publishes the longer form; it goes in alternates. |
| `mdc-commissioner-13` | `René Garcia` | `Rene Garcia` | County page has the accent, SOE PDF does not. **NFD-strip before comparing.** |
| `mdc-commissioner-12` | `Juan Carlos "JC" Bermudez` | `Juan Carlos Bermudez`, `JC Bermudez` | Quoted nickname |
| `mdc-commissioner-8` | `Danielle Cohen Higgins` | `Danielle Higgins` | 🔴 Two-word surname |
| `mdc-mayor` | `Daniella Levine Cava` | `Daniella Cava` | 🔴 Two-word surname |
| `mdc-sheriff` | `Rosanna "Rosie" Cordero-Stutz` | `Rosie Cordero-Stutz`, `Rosanna Cordero-Stutz` | Quoted nickname **and** hyphenated surname |
| `mdc-property-appraiser` | `Tomas Regalado` | — | His own site drops the accent |
| `mia-commissioner-4` | `Ralph "Rafael" Rosado` | `Ralph Rosado`, `Rafael Rosado` | Quoted nickname |
| `mia-commissioner-1` | `Miguel Angel Gabela` | `Miguel Gabela` | Two given names |

🔴🔴 **`splitName()` cannot handle a two-word surname, and this wave has two.** On
`Danielle Cohen Higgins` it yields `first = Danielle`, `last = Higgins`, `middle = Cohen` →
`middleInitial = ''` (because "Cohen" is not a single initial), silently discarding "Cohen". On
`Daniella Levine Cava` it yields `first = Daniella`, `last = Cava`, dropping "Levine".

`full_name` is always correct; `first_name` / `last_name` are derived and will be wrong for these two.
Task 4 must carry an explicit override map rather than widen the heuristic — a cleverer heuristic
would break `Juan Carlos` next.

⚠ **Widen the suffix regex** to FL-5's `/,?\s+(Jr\.?|Sr\.?|II|III|IV)\s*$/i`. This wave has a suffix
with **no comma before it in one form and a comma in another**: `Oliver G. Gilbert, III` (county) and
`Steve Gallon, III` (SOE, school board — excluded, but the same file). FL-3's and FL-4's
comma-required regex would put `III` in `last_name`.

---

## Offices deliberately excluded

The SOE PDF lists far more than this wave seats. Excluded, with the reason:

| Excluded | Count | Why |
| --- | --- | --- |
| **Community Council members** | **60 elected** | 10 councils × 6 elected members each (plus 1 BCC-appointed per council). Zoning and land-use bodies for the unincorporated area only. |
| School Board members | 9 | A separate district government, not the county |
| South Dade Soil & Water Conservation District | 4 | A separate special district |
| State Attorney, Public Defender | 2 | 🔴 **Officers of the 11th Judicial Circuit, not county officers** — the same class FL-5 excluded for Palm Beach's 15th Circuit. Program-level open work. |
| State Senate / State House delegation | 20 | State offices; already seated by the FL legislature wave |
| Federal | 7 | Out of scope |
| City Manager, City Clerk, City Attorney (Miami) | 3 | **Appointed, not elected.** `miami.gov` lists them alongside the six; they are not offices here. |

🔴 **The Clerk's title is published three ways. The officeholder's own publisher wins.**

| Source | Form |
| --- | --- |
| SOE `elected-officials.pdf` | `Clerk of the Circuit Court and Comptroller` |
| County *Constitutional Offices* page | `Clerk of the Court and Comptroller` |
| **`miamidadeclerk.gov` (his own site)** | **`Clerk of the Court and Comptroller`** ✅ chosen |

⚠ The same site also uses `Miami-Dade Clerk of the Courts` informally. The chosen title is the one the
office uses of itself in its formal name, and it differs from Palm Beach's
`Clerk of the Circuit Court & Comptroller` — **do not inherit a title across counties.**

---

## Live churn to re-check before the apply

1. **County D1 — Oliver Gilbert** won the FL-24 Democratic primary 2026-08-18. If he wins in
   November he resigns District 1.
2. **County D5 and D6 are both appointed and both on the 2026 ballot.**
3. ⚠ **Several 2026 Miami-Dade commission candidates won UNOPPOSED at the close of qualifying**,
   including Natalie Milian Orbis. Florida removes unopposed races from the ballot entirely, so they
   never appear in a results feed — **FL-5's exact finding, recurring.** It does **not** change
   occupancy: under Charter §3.01(A) their new term still commences **2026-11-17**, so every
   `term_start` above stands.
4. **HD-113 remains vacant** through November 2026 per the SOE. Probe A depends on it.
5. The SOE PDF is stamped **2026-06-04** and is already stale on HD-116. Re-pull before the apply and
   diff, but confirm occupancy against each office's own publisher regardless.
