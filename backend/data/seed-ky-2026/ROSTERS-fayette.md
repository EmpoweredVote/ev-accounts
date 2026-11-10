# ROSTERS — Fayette County officers (KY-4)

Read 2026-09-26. **Nothing in this file has been written to production.** Every row below is the
result of reading a source's own bytes; no name, date or count in this file came from a search-engine
summary or from `WebFetch`'s summarizer, which was caught fabricating four names in this wave (see
`.planning/knight-foundation/ky.md`).

Jurisdiction: Fayette County, Kentucky — FIPS `21067`, coterminous with TIGER place `2146027`
(measured exactly coterminous in KY-3: both 285.567 sq mi, zero difference either way).

---

## 1. The office inventory, and what establishes it

The inventory is the **charter's own sentences** (Article 11, saved verbatim at
`charter-article-11.txt`), checked against the county's **own certified election results**. It is not
inferred from the word "consolidated", and it is not taken from candidate filings.

🔴 **Lexington-Fayette does NOT drop its county commission.** Charter 11.02 keeps the Fiscal Court —
the County Judge plus three Commissioners — and charter 11.01 keeps the County Judge. Spec §3.2's
rule for a consolidated city-county does not hold here.

🔴 **Fayette elects BOTH commissioners AND magistrates.** They are not alternative forms of one body
here: the Fiscal Court is the commissioner form (charter 11.02), and the Justices of the
Peace/Magistrates survive separately under charter 11.07 with, in practice, only the power to
solemnise marriages. The county's own certified 2022 general results list all nine district seats —
`COMMISSIONER - DIST 1/2/3`, `MAGISTRATE - DIST 1/2/3`, `CONSTABLE - DIST 1/2/3`.

### 🟢 The vote totals discriminate at-large from district, and they disagree with the label

From the county's **own certified November 2022 general results**
(`fayette-2022-general-results.html`, Wayback capture 2022-11-10 of the clerk's results page):

| Race | Winner | Votes |
| --- | --- | --- |
| `COMMISSIONER - DIST 1` | Brian Miller | **66,529** |
| `COMMISSIONER - DIST 2` | Alayne White | **66,114** |
| `COMMISSIONER - DIST 3` | David Lowe **(W)** | **503** |
| `MAGISTRATE - DIST 1` | Rosalind Bryant | 18,904 |
| `MAGISTRATE - DIST 2` | Lisa Moore Fath | 21,740 |
| `MAGISTRATE - DIST 3` | George Biggerstaff | 22,851 |
| `CONSTABLE - DIST 1` | Andrea Welker | 18,950 |
| `CONSTABLE - DIST 2` | Jim McKenzie | 23,292 |
| `CONSTABLE - DIST 3` | Edward "Eddie" Sparks | 22,684 |
| `CO. JUDGE/EXEC` (countywide) | Mary Diane McCord Hanna | 57,252 of 102,742 cast |

**Commissioners poll at countywide scale (66k). Magistrates and constables poll at one-third scale
(19k–23k).** So the commissioners are elected **at-large**, exactly as charter 11.02 says, and
`DIST 1/2/3` on the commissioner line is a **seat number, not a geography**. The magistrate and
constable districts are real, and they are the same three districts.

⚠ **I got this wrong once before checking it.** An earlier reading of the 2026 primary PDF put the
commissioner races at district scale. `pdftotext -layout` had **interleaved the columns** of that
report, so the numbers I compared were not the numbers on those lines. The 2022 file parses cleanly
and carries explicit `TOTAL` rows. ▶ **A total you did not see labelled `TOTAL` is not a total.**

🔴 **David Lowe won a countywide seat as a WRITE-IN with 503 votes**, marked `(W)`. His predecessor,
Chrysanthia Carr-Seals, did not run again. A turnout-based sanity check on that seat would flag it as
broken data; it is correct.

### 🔴 There is no elected Jailer, and the charter says so in its own editor's note

> *"Sections 11.05 and 11.07 — The sheriff and jailer were merged effective January 3, 1994, by
> 1990 Ky. Acts Ch. 138."*

Ky. Const. § 105 permits the merger and requires that **the office of Sheriff be the one retained**.
KRS 67A.028 then let the urban-county government create a **correctional services division** holding
every jail duty of both offices; that division is Chapter 24 of the code and its staff are classified
civil service. **No Jailer filed in Fayette in 2026**, which agrees. Do not create the office.

---

## 2. The roster — 18 seats

`arrival` is what a source **states**. Where the only available date is the constitutional default —
Ky. Const. § 99's "first Monday in January after their election" — it is marked **computed** and is
written at **year** precision, never day. KY-2 and KY-3 each proved a computed arrival wrong in this
very slice.

| # | Office | Seat | Holder | Arrival | Precision | How | Source for the arrival |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | County Judge/Executive | countywide | Mary Diane McCord Hanna | 2023 | year | elected | certified 2022 result + WKYT 2025-06-05; day is **computed** |
| 2 | Fiscal Court Commissioner | at-large 1 | Brian Miller | 2023 | year | elected | certified 2022 result; day is **computed** |
| 3 | Fiscal Court Commissioner | at-large 2 | Alayne White | 2023 | year | elected | certified 2022 result; day is **computed** |
| 4 | Fiscal Court Commissioner | at-large 3 | David Lowe | 2023 | year | elected (write-in) | certified 2022 result; day is **computed** |
| 5 | County Clerk | countywide | Susan Lamb | **2023-02-01** | day | **appointed** | Ballotpedia officeholder table; her office's own succession list reads `2023-Present` |
| 6 | County Attorney | countywide | Angela C. Evans | **2022-09-30** | day | **appointed** | WKYT 2022-09-30 raw: *"He is stepping down Friday. Evans was sworn in at 3 Friday afternoon."* |
| 7 | Sheriff | countywide | Kathy H. Witt | 1999 | year | elected | Ballotpedia raw: *"assumed office in 1999"*; her office's own site confirms she holds it |
| 8 | Property Valuation Administrator | countywide | David O'Neill | **2009-02-11** | day | **appointed** | 🟢 his own office: *"has proudly served … since February 11, 2009, when he was appointed by Governor Steve Beshear"* |
| 9 | Coroner | countywide | Gary W. Ginn | 2003 | year | elected | Ballotpedia raw *"assumed office in 2003"*; LFUCG's own Coroner's Office page names him |
| 10 | County Surveyor | countywide | Gary D. Roland | 2019 | year | elected | Ballotpedia raw; certified 2018-cycle seat, re-filed 2026 |
| 11 | Magistrate | District 1 | Rosalind A. Bryant | 2023 | year | elected | certified 2022 result; GIS `MAGREP` agrees; day is **computed** |
| 12 | Magistrate | District 2 | Lisa Moore Fath | 2023 | year | elected | certified 2022 result; GIS `MAGREP` agrees; day is **computed** |
| 13 | Magistrate | District 3 | Chrysanthia Carr-Seals | **UNKNOWN** | **unknown** | **appointed** | see the change-check below — open-ended term, no invented date |
| 14 | Constable | District 1 | Andrea Welker | 2023 | year | elected | certified 2022 result; day is **computed** |
| 15 | Constable | District 2 | Jim McKenzie | 2023 | year | elected | certified 2022 result; day is **computed** |
| 16 | Constable | District 3 | Edward "Eddie" Sparks | 2015 | year | elected | Ballotpedia raw — **predates** the 2022 win, so 2023 would be wrong |
| 17 | Circuit Court Clerk | countywide | Vincent Riggs | 2013 | year | elected | Ballotpedia raw *"assumed office in 2013"*; kycourts.gov names him as the sitting clerk |
| 18 | Commonwealth's Attorney | countywide | Kimberly Baird | **2022-10-01** | day | **appointed** | Ballotpedia raw *"assumed office on October 1, 2022"*; won the 2024 general, term to 2031-01-06 |

**Totals: 4 day · 13 year · 1 unknown · 0 invented · 5 appointed.**

⚠ **Three of the eighteen do not start when their current term did** — Witt (1999), Ginn (2003),
Riggs (2013), Sparks (2015), O'Neill (2009). `office_terms` carries **continuous occupancy**, so a
re-election must never overwrite the earlier start. This is the KY-2/KY-3 gap-case trap, and here it
applies to five of eighteen rows.

---

## 3. The change-check — what it caught

Every seat was checked for a departure, not just read off a list. It paid twice.

### 🔴 MAGISTRATE DISTRICT 3 CHANGED HANDS AND NO ROSTER SAYS WHEN

- The certified **2022** result: **George Biggerstaff** won District 3 with 22,851 votes.
- Ballotpedia raw: Biggerstaff *"assumed office on January 2, 2023. He left office on **August 26,
  2023**."*
- The city's **own GIS** layer `Magisterial_District` carries `MAGREP = "Chrysanthia Carr-Seals (D)"`
  for district 3 — and `Rosalind A. Bryant (D)` / `Lisa Moore Fath (R)` for 1 and 2, which match the
  certified result exactly.
- Ballotpedia: *"Carr-Seals was appointed to serve as the District 3 Magistrate"* — **with no date.**

▶ So the seat is hers, the arrival is **undated**, and it is written as an **open-ended term with
`start_precision => 'unknown'`**. Do not compute one.

⚠ **Do not confuse this with the Governor's board appointment.** A Beshear press release reappoints a
"Chrysanthia Carr-Seals, pastor at St. Paul United Methodist Church" to a **state board** for a term
expiring 2027-01-17. Same person, different body, unrelated date. It is not evidence about the
magistrate seat.

### 🔴 THE COUNTY CLERK WHO WON IN 2022 IS NOT THE COUNTY CLERK

**Don Blevins Jr. won the November 2022 general with 69,903 votes (67%)** and is not in office.
**Susan Lamb** was appointed **2023-02-01** and then won the **November 2023 special election**.
Her office's own succession list reads `Susan Lamb 2023-Present · Donald W. Blevins Jr. 2009-2023`.

▶ **A certified result is not a fact about who holds the seat** — the program's own rule, paid for
again. Seating the 2022 winners wholesale would have put the wrong person in the Clerk's office.

### 🟢 Carr-Seals held a *different* Fayette seat first

Ballotpedia raw: she was **Fayette County Commission District 3 from 2019, and left it 2023-01-02**,
not seeking re-election — which is the seat **David Lowe** then won as a write-in. One person, two
different county offices, four years apart. A name-keyed roster diff reads that as a contradiction.

### Seats where the check found no change

Judge/Executive, all three Commissioners, County Attorney, Sheriff, PVA, Coroner, Surveyor,
Constables 1–3, Circuit Court Clerk, Commonwealth's Attorney — each confirmed still sitting by a
source independent of the 2022 result (own office site, LFUCG department page, kycourts.gov, the GIS
`MAGREP` field, or a 2026 re-filing).
▶ **The pass finding nothing on those thirteen is the result, not a skipped step.**

---

## 4. Geography this wave needs

| Seats | District | Exists? |
| --- | --- | --- |
| 12 countywide seats (1–10 minus magistrates/constables, plus 17, 18) | Fayette County `21067` / `G4020` | 🟢 **already in production** — `afabc7f3-1b98-4ded-a2c1-df3f8e2b41dd` |
| 3 magistrates + 3 constables | Magisterial Districts 1–3 | 🔴 **NOT in production — a boundary load is owed** |

🟢 The source exists and is the city's own:
`services1.arcgis.com/Mg7DLdfYcSWIaDnu/ArcGIS/rest/services/Magisterial_District/FeatureServer/0`
— *"Boundaries representing the magisterial districts of Lexington-Fayette County, Kentucky."*
**3 features**, fields `MAGISTERIAL` (1, 2, 3) and `MAGREP`. Spatial reference `wkid 102679`
(`latestWkid 2246`, KY State Plane North, feet) — **`outSR=4326` is load-bearing**, as it was in KY-1.

⚠ **Its `MAGREP` attribute is a roster riding on geometry, and KY-2 caught exactly this layer family
carrying a stale one.** Here it is the geometry that is wanted and the roster that is corroboration —
and it happens to be *fresher* than the certified result, not staler. Prove the geometry
independently; never inherit trust across fields.

⚠ **The magistrate and constable districts must be one set of polygons, used twice.** They are the
same Justice's Districts under Ky. Const. § 99 — one Justice of the Peace and one Constable each —
and the vote totals agree (D1 18,904/18,950 · D2 21,740/23,292 · D3 22,851/22,684).

⚠ **KY-3 recorded "four council-district layers". The catalogue actually carries six** —
`Council_District`, `_1972`, `_1982`, `_1992`, `_2002`, `_2012`. The trap it documented is real and
slightly larger than recorded. This does not change KY-3's result, which proved the live layer by
area.

---

## 5. Still open before any SQL is written

1. **Scope: magistrates and constables.** The voters elect them, which is this program's inclusion
   test. Their real powers are narrow — Vote Local Lexington states that in Fayette *"the main role of
   the Magistrate is to conduct marriages"*. If they are seated, each needs a
   `representation_note` that says what the office actually does, per the describe-real-powers rule.
2. **Scope: Soil and Water Conservation District Supervisor** (3 on the 2026 ballot). Elected, but a
   special district rather than a city or county office, and unprecedented in this program.
3. **Elected judges** — Circuit, Family and District judges of the 22nd Judicial Circuit — stay
   deferred to the judges wave, as PA-4 recorded. That is scheduling, not exclusion.
4. Confirm the **22nd Judicial Circuit is Fayette County exactly** before seating the Commonwealth's
   Attorney countywide.
5. Decide the **title** rendered for the three Fiscal Court seats. The charter, the county's own
   press coverage and two of three 2026 ballot labels all say **Commissioner**; the third 2026 ballot
   label says Magistrate and is the odd one out. Recommend `Fiscal Court Commissioner, At-Large N`.
