# Colorado counties — Jefferson and Fremont (`CC_0280`, seeded 2026-10-20)

**Read this before calling anything in these two counties a defect.** Per-jurisdiction rulings
live here, not in the migration.

| County | district | offices | seated | not created |
| --- | --- | --- | --- | --- |
| Jefferson | `Jefferson County` · `08059` · `G4020` | 10 | 10 | — |
| Fremont | `Fremont County` · `08043` · `G4020` | 8 | 8 | Surveyor · District Attorney |

Both county districts and their polygons **already existed** — all 64 Colorado counties do. Only
offices and holders were missing, and until this seed every address in either county returned no
county government at all.

---

## 🔴 R1. Commissioners are elected AT LARGE, so they sit on the COUNTY district

Both counties say so in their own words. Jefferson's Leadership page: *"three commissioners
elected **at-large** to four-year staggered terms"*. Its Meet the Commissioners page: *"They are
elected at large to four year terms."* Fremont's three seats are the same.

**District 1 / 2 / 3 are RESIDENCY districts.** A commissioner must live in theirs; every voter in
the county votes in all three contests and is represented by all three.

▶ So all six Commissioner offices hang off the **county-wide** district, and an address anywhere
in either county returns **all three** commissioners. Verified end-to-end after applying: a point
at the Jeffco Courts & Administration Building returns all 10 Jefferson officials, and one at the
Fremont County Administration Building returns all 8.

### ⚠ This deliberately differs from El Paso County — and that is the open question

El Paso County (`08041`), the only other Colorado county we hold, puts each of its **five**
commissioners on its own sub-district (`mtfcc X0033`) with its own polygon, so an El Paso address
returns **one** commissioner.

Five commissioners is a different statutory class from three, and a large Colorado county may
genuinely use district-only voting — so the two shapes may both be right.

🔴 **OPEN QUESTION — do not "fix" either county until it is answered.** Is El Paso County
district-elected, or is its sub-district model wrong? One sentence from the El Paso County Clerk
settles it. Operator decision 2026-10-20: model these two counties on what their own charters and
websites say, and raise El Paso as a question rather than unifying the shapes by fiat. That is the
standing ruling on classification (Cantrell, 2026-09-05): *understand and describe the distinction,
do not make them uniform.*

---

## 🔴 R2. Two Fremont seats were deliberately NOT created

Fremont County lists both in its elected-officials menu. Neither holder could be sourced.

| Seat | Why not | What settles it |
| --- | --- | --- |
| **Surveyor** | The county's Surveyor page describes the duties and **names nobody**; `/contact/surveyor` 404s. | The Fremont County Clerk's certified list of county officers, or any county directory naming the surveyor. |
| **District Attorney, 11th Judicial District** | Unsettled recent history — Linda Stanley was disbarred and Jeff Lindsey was appointed Acting DA in November 2024 — and the district's own site (`da11.us`) is unreachable. | The 11th JD DA office's own site or the Colorado District Attorneys' Council roster. |

Operator decision 2026-10-20: **create neither.** An office with no holder is invisible to voters
anyway, and creating one would raise `offices_missing_terms` for no gain. A post-verify gate in
`CC_0280` fails if either is ever created without a holder by a careless re-run.

🟢 **Jefferson's Surveyor and District Attorney ARE seeded** — its Leadership page names Robert
Hennessy and Alexis King.

---

## R3. Treasurer and Public Trustee is ONE seat, in both counties

Jefferson: *"As of July 1, 2020 the Treasurer is now the Public Trustee"* — the Leadership page
lists Jerry DiTullio under both headings. Fremont: the Public Trustee page names Kathy Elliott,
the Treasurer. Matches El Paso's existing `Treasurer and Public Trustee` office, so the three
counties agree here and no distinction needs describing.

---

## R4. The District Attorney is a judicial-district seat on a county district

Jefferson's DA covers the **First Judicial District: Jefferson AND Gilpin counties**, and Gilpin
voters elect it too. It is attached to the Jefferson County district because that is where our
voters are, and `offices.description` says so. El Paso's DA carries the same shape for the Fourth
Judicial District (El Paso + Teller).

⚠ A Gilpin County address will not return this DA until Gilpin is seeded. That is a coverage gap,
not a defect in these rows.

---

## R5. Dates — what the counties state, and nothing more

🔴 `term_start` is the start of **continuous occupancy**, never the start of the current term. A
published "Current Term" is only the answer when it is the person's FIRST term.

| Person | Seat | Start | Precision | Why |
| --- | --- | --- | --- | --- |
| Rachel Zenzinger | Jeff Comm 1 | 2025 | year | "Term: 2025-2029", no second-term language |
| Andy Kerr | Jeff Comm 2 | **2021** | year | "Current Term: 2025-2029" **but** "elected to his second four-year term in November of 2024" |
| Lesley Dahlkemper | Jeff Comm 3 | **2019** | year | "Current Term: 2023-2027", "second… term in November 2022"; KUNC 2026-07-23 "her seven-year career as county commissioner" |
| Amanda Gonzalez | Jeff Clerk | 2023 | year | won the seat in 2022 (CPR 2025-01-06) |
| Jerry DiTullio | Jeff Treasurer | 2019 | year | "has served as Jefferson County Treasurer since 2019" |
| Kevin Grantham | Frem Comm 1 | **2019** | year | "in his second term" (Colorado Politics 2026-10-02); Senate President through 2018 |
| Debbie Bell | Frem Comm 2 | 2011-01 | month | "took office in January 2011" |
| Dwayne McFall | Frem Comm 3 | 2017 | year | "elected… in 2016 and 2020" ⇒ took office January 2017 |
| Justin D Grantham | Frem Clerk | 2019 | year | "has proudly served… since 2019" |

**The other nine carry `term_start` NULL with `start_precision = 'unknown'`** and
`how_started = 'unknown'`: no county page states when they took office, and CLAUDE.md is explicit
that an open-ended unknown beats a guess.

⚠ **Ballotpedia was NOT used to fill them.** Its "Amanda Gonzalez" page is a disambiguation, and a
third-party page reached by name match is exactly how the wrong person gets dated. If someone
wants these nine dated, the source is each office's own bio page or the Clerk's certified officer
list.

⚠ **`seat_officeholder` refuses a NULL `term_start`** — by design, so a year-only source is written
as Jan 1 + `'year'` rather than discarded. The nine undated seats therefore use the helper's own
INSERT verbatim. That is safe **only** because every office here is created by the same migration
and has no predecessor to close.

---

## R6. The roster was proved current, not assumed

🔴 A county bio page says who held a seat **when it was written**. Fremont's commissioner bios
looked stale — McFall's lists elections only through 2020, which would have ended in January 2025
— so the board was checked against a dated primary document instead:

> **Fremont County BOCC minutes, 22 September 2026** ("TWENTIETH MEETING"). Roll call: *Debbie
> Bell — Commissioner; Dwayne McFall — Commissioner; Kevin Grantham — Commissioner; Justin
> Grantham — Clerk and Recorder.*

All three commissioners and the clerk are sitting now. McFall's bio is **authoritative for when he
started and stale about his later elections** — the same source, two different reliabilities.

---

## R7. Three officeholders already existed and were SEATED, not created

`CC_0276` created them six migrations earlier as 2026 statewide candidates with no office, and its
header predicted this seed: *"if those counties are seeded later, THESE are the people to seat,
not rows to duplicate."*

| Person | `CC_0276` row | Now seated as | Identity document |
| --- | --- | --- | --- |
| Amanda Gonzalez | `7b61bc5e` | Jefferson Clerk and Recorder | CPR / Colorado Politics name the SoS nominee as the Jefferson County Clerk |
| Lesley Dahlkemper | `0a783864` | Jefferson Commissioner, District 3 | Weiser's running-mate announcement names "Jeffco Commissioner Lesley Dahlkemper" |
| Kevin Grantham | `bc6296a0` | Fremont Commissioner, District 1 | Colorado Politics names the Treasurer nominee as a sitting Fremont commissioner |

🔴 **`seat_officeholder` does not touch `is_incumbent`** — checked; it is not in the function body.
All three carried `is_incumbent = false` from `CC_0276`, which is correct for a candidate holding
nothing and **hides a seated person from the incumbents-only reads**. `CC_0280` flips them
explicitly and a post-verify gate asserts all 18 seated people are active incumbents.

---

## Sources

* Jefferson County Leadership — `jeffco.us/2078/Leadership` (read 2026-10-20)
* Jefferson commissioners — `jeffco.us/2075`, `/4876`, `/4228`, `/2099`
* Jefferson Treasurer — `jeffco.us/809/Treasurer`
* Fremont elected officials — `fremontcountyco.gov` (`/commissioners/meet-commissioners`,
  `/assessor/assessor`, `/coroner/coroner`, `/treasurer/fremont-county-treasurer`,
  `/treasurer/public-trustee`), `fremontcountyclerkco.gov`, `fremontsheriff.org`
* Fremont BOCC minutes 2026-09-22 —
  `fremontcountyco.gov/sites/default/files/commissioners/minutes/9-22-2026_BOCC_Final_Minutes__20_.pdf`
* KUNC 2026-07-23 (Dahlkemper) · CPR 2025-01-06 (Gonzalez) · Colorado Politics 2026-10-02 (Grantham)
