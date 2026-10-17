# Atlanta · Fulton County · DeKalb County — verified roster

Atlanta wave of the Knight Foundation cities program toolchain. **Atlanta is not one of the 26
Knight jurisdictions** — it reuses the Georgia slice's stages 1 and 2, which are already applied.

Spec: [`docs/superpowers/specs/2026-08-28-knight-cities-program-design.md`](../../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md) ·
Slice: [`.planning/knight-foundation/ga.md`](../../../.planning/knight-foundation/ga.md)

**39 offices · 38 people · 1 vacancy** — ✅ APPLIED 2026-10-17. — 17 city, 11 Fulton, 11 DeKalb. Three governments.

Measured against production 2026-10-17. Every source in the table below is on disk in
`_sources/`, untracked, fetched through `_fetch.sh`.

## Starting position, measured 2026-10-17

| What | Production holds |
| --- | --- |
| `geofence_boundaries` | Atlanta place `1304000`/`G4110` ✅ · Fulton `13121`/`G4020` ✅ · DeKalb `13089`/`G4020` ✅ |
| Georgia legislature | 180 House + 56 Senate, seated (GA-2, `CC_0025`/`CC_0026`) |
| `governments` | **no Atlanta row, no Fulton row, no DeKalb row** |
| `offices` for any of the three | **zero** |
| Any Atlanta/Fulton/DeKalb officeholder | **zero** (3 name hits are CAL-ACCESS committee rows, not people) |

Atlanta is greenfield, but stages 1 and 2 are already done for Georgia, so this is a stage 3 + 4 + 5
job only.

### 🔴 Atlanta spans TWO counties, and the split is measured, not assumed

PostGIS intersection of the Atlanta place polygon against the Georgia county layer:

| County | Area inside Atlanta | Share of Atlanta |
| --- | --- | --- |
| Fulton `13121` | 330.09 km² | **93.45%** |
| DeKalb `13089` | 23.14 km² | **6.55%** |

Both county waves are therefore in scope. A Fulton-only seed would answer **three of four** for every
address in the DeKalb strip, and **nothing would error** — the exact silent failure the spec's
four-answer probe exists to catch. Ruled in scope by the operator, 2026-10-17.

---

## Sources

| # | Body | Source | Endpoint | What it is |
| --- | --- | --- | --- | --- |
| A | city | Atlanta City Council, members index | `citycouncil.atlantaga.gov/council-members` | the body's own roster. District → name and Post → name, both present in the **server** HTML |
| B | city | Atlanta City Council, 16 member pages | `citycouncil.atlantaga.gov/council-members/<slug>` | per-seat change-check, and the name each member's own page uses |
| C | city | **Municipal Clerk, "2026 City of Atlanta Elected Officials"** (PDF) | `citycouncil.atlantaga.gov/council-divisions/municipal-clerk/2026-city-of-atlanta-elected-officials` | **the city's own record of who took office.** Served as `application/pdf` from an HTML-looking URL. Carries one typo — defect 4 |
| D | city | City of Atlanta, "Mayor Dickens' Inauguration" | `atlantaga.gov/government/mayor-s-office/meet-the-mayor/mayor-dickens-inauguration` | **the only dated oath in the wave.** States **2026-01-05** (second term) and **2022-01-03** (first term, 61st mayor) |
| E | city | City of Atlanta, Mayor's Office | `atlantaga.gov/government/mayor-s-office` | 🔴 stale — defect 2 |
| F | city + county | **Georgia SOS certified results**, Fulton | `results.sos.ga.gov/results/public/api/elections/fulton-county-ga/{id}/data` | 2025 municipal general, 2024/2022/2020 generals, 2026 primary + runoff |
| G | city + county | **Georgia SOS certified results**, DeKalb | `results.sos.ga.gov/results/public/api/elections/dekalb-county-ga/{id}/data` | same elections, DeKalb's half |
| H | — | Georgia SOS jurisdiction index | `results.sos.ga.gov/results/public/api/jurisdictions/Georgia` | 117 elections, 2012→2026. 🔴 the **per-county** index is dead — defect 1 |
| I | county | Fulton County, Board of Commissioners | `fultoncountyga.gov/Commissioners` | the county's own roster. **Omits District 4 and says nothing** — defect 5 |
| J | county | **Fulton County Registration & Elections, CALL FOR ELECTION** (PDF) | `fultoncountyga.gov/-/media/November-3-Election-notices/Call-for-Election--Comm-District-4--Nov-3-2026--3172926.pdf` | **the primary evidence that District 4 is vacant.** O.C.G.A. § 21-2-540, special election 2026-11-03, runoff 2026-12-01. Signed Nadine Williams, Director |
| K | county | Fulton County Registration & Elections | `fultoncountyga.gov/Inside-Fulton-County/Fulton-County-Departments/Registration-and-Elections` | the November 3 2026 notice index |
| L | county | DeKalb County, Board of Commissioners | `dekalbcountyga.gov/government/board-of-commissioners` | the county's own roster, 7 of 7 |
| M | county | DeKalb County, Super District 7 | `dekalbcountyga.gov/government/board-of-commissioners/districts/ladena-bolton` | confirms Bolton holds the seat |
| N | — | Council of Probate Court Judges of Georgia | `gaprobate.gov/judges-directory/` | 🔴 a facet list, not a directory. Did not resolve either county — open item 1 |

### Control runs

Both certified-results routes were tested against a **known-good** county before any absence was read
as a fact, per the standing rule that a uniform answer is a broken detector until a positive control
passes.

| Control | Result |
| --- | --- |
| `jurisdictions/baldwin-county-ga` — `ga.md` records this route as working | 🔴 **FAILED.** Returns `elections: []`, same as Fulton and DeKalb |
| `elections/baldwin-county-ga/MunicipalGeneralSpecialElectionPSC11042025/data` | 🟢 passes — 13,186 bytes |
| `elections/baldwin-county-ga/2024NovGen/data` — scanned for Probate / Coroner / Surveyor | 🟢 passes — returns **Surveyor** and **Coroner** |
| Fulton 2026 special-election slugs, all 204 | 🟢 controlled by `06162026GeneralPrimaryRunoff` returning **200** on the same route |

---

## 🔴 Source defects found

### 1. 🔴🔴 The SOS PER-COUNTY election index is dead, and it fails as an empty list

`/api/jurisdictions/fulton-county-ga` returns `"elections": []` with
`"redirectToShortName": "Georgia"`. So does DeKalb. So does **Baldwin**, which `ga.md` records as the
route that settled all 18 Milledgeville seats.

Read without a control, that is "this county has no elections" — a false and very plausible answer.
The control failing is what proves the route moved rather than the data vanishing.

▶ **Enumerate from `/api/jurisdictions/Georgia`** (117 elections, 2012→2026) and read `publicElectionId`.
The per-county **data** route is unaffected and still correct.

⚠ `ga.md` currently tells the next wave to use the dead route. **That line needs correcting.**

### 2. 🔴 The Mayor's own page is stale about the Mayor's own term

`atlantaga.gov/government/mayor-s-office` reads *"Elected in November 2021, Mayor Andre Dickens serves
as the Executive Officer of the City of Atlanta."* Dickens was re-elected on 2025-11-04 with **85.03%**
and sworn in again on 2026-01-05. The sentence was never updated.

The page is authoritative for **who** and worthless for **when** — a source is authoritative for one
field and stale for another, read it per field.

### 3. 🔴🔴 Fulton and DeKalb NAME THE SAME CONTEST DIFFERENTLY, and a name-merge fails silently

| Seat | Fulton calls it | DeKalb calls it |
| --- | --- | --- |
| District 1 | `Atlanta City Council D1` | `Atlanta City Council Member District 1` |
| Post 1 at-large | `Atlanta City Council P1 At Large` | `Atlanta City Council Member Post 1 At Large` |

Only `Atlanta Mayor` and `Atlanta City Council President` carry identical names in both returns, so a
naive merge appears to work on the two most prominent contests and silently drops the other fifteen.

🔴 **The consequence is a wrong answer, not a missing one.** Post 1 at-large:

| Read | Michael Julian Bond | Verdict |
| --- | --- | --- |
| DeKalb alone | 5,401 of 11,833 = **45.64%** | *"no majority → runoff"* |
| Fulton alone | 53,412 of 88,503 = **60.35%** | majority |
| **Merged** | **58,813 of 100,336 = 58.62%** | **majority, elected outright** |

Normalisation is in `_sources/`-adjacent `norm.js`; both spellings fold to one canonical contest name.

### 4. 🔴 The Clerk's official PDF misspells a sitting councilmember

Source C prints **"Andreal L. Boone"** for District 10. Her own member page (source B) is titled
**"Andrea L. Boone"**, and the certified 2025 ballot (source F) reads **"Andrea L. Boone (I)"**.

Two independent sources against the Clerk's one. **Settled: Andrea L. Boone.** The city's own
record is the defective source here, which is why a roster is never built from one document.

### 5. 🔴🔴 The council site's "Council President" link still carries the DEPARTED president's slug

```html
href=".../council-members/council-president-doug-shipman" title="Marci Collier Ov…"
```

The slug names Doug Shipman, president 2022–2026. The `title` attribute names Overstreet, who actually
holds it. `Shipman` appears **exactly once** in the whole page — in that href.

▶ **A URL slug is not evidence of who holds an office.** A departed official's URL can serve their
successor; assert that the page *names* the person.

### 6. 🔴🔴 A CERTIFIED RETURN ENUMERATES CONTESTS, NOT OFFICES

Neither Fulton nor DeKalb shows a **Probate Judge** contest in **any** return from 2020 through 2026 —
2020, 2022, 2024 and 2026 generals and primaries, 16 payloads. Both counties plainly operate a Probate
Court.

The Baldwin control passes on the same scan (it returns Surveyor and Coroner), so the detector is
sound and the absence is real. The cause is Georgia's nonpartisan election law: **an unopposed
candidate is declared elected and never appears on a ballot.**

🔴 **So a county's elected offices CANNOT be enumerated from certified results.** Results prove who won
a contest. They are silent about every office nobody contested. A roster built from returns alone
omits exactly the seats that are never challenged — which are disproportionately the long-held ones.

Neither county elects a **Coroner**: both operate a medical examiner system. ⚠ This is inferred from
the same absence and is **open item 2** until a county source states it.

### 7. 🔴 The certified route runs out for Atlanta's own history

| Election | Fulton | DeKalb |
| --- | --- | --- |
| 2025-11-04 municipal general | 🟢 200 | 🟢 200 |
| 2025-12-02 municipal runoff | **204** | **204** |
| 2021-11-02 municipal general | **204** | **204** |
| 2013-11-05 | **204** | **204** |

The `December2nd2025Runoffs` payload exists statewide but holds **one** contest — a State House
District 106 runoff. Atlanta's municipal runoff is not in the portal at all.

So the **D7 and D11 runoff winners cannot be sourced from certified results**, and no Atlanta
occupancy start before 2025 can be derived from them either. Source C settles who holds the seats;
the start dates fall back to the honesty rule below.

---

## Charter and scope rulings

### R1 — 🔴 The 9 elected Municipal Court judges are EXCLUDED (operator, 2026-10-17)

Atlanta elects 9 Municipal Court judges citywide. They are on the 2025 certified ballot as
`Atlanta Municipal Court Judge (Baker)`, `(Bey)`, `(Gaines)`, `(Gundy)`, `(Hand Seitz)`, `(Jackson)`,
`(Mann)`, `(Portis)`, `(Ward)`, and all nine are named in source C.

Excluded on two independent grounds:

1. **Judicial branch.** The program excluded Georgia's Chief Magistrate on Ga. Const. Art. VI and
   Florida's county judges on the same reasoning. A city court is not a different question.
2. 🔴 **The only seat designation any source publishes is the sitting judge's own surname.** Seeding
   that repeats the open LASC defect — 364 seats named after the judge occupying them. **A seat must
   outlive its holder.** Were these ever brought into scope, the charter's own seat designations are
   the prerequisite, not the ballot's.

### R2 — School boards are EXCLUDED, per spec §11 (operator, 2026-10-17)

Atlanta Board of Education (9 seats, named in source C) and both County Boards of Education are out.
Every one of the 16 slices excluded school boards; Atlanta does not become the exception quietly.

### R3 — Prosecutors are EXCLUDED, inheriting the FL-5 rule

Fulton elects a **Solicitor General** and the **District Attorney, Atlanta Judicial Circuit**; DeKalb
elects a **Solicitor General** and the **District Attorney, Stone Mountain Judicial Circuit**. All four
are on the 2024 certified ballot.

The Georgia county-officer template excludes prosecutors (`ga.md`, ruled 2026-09-01, Cantrell).

⚠ **One leg of that exclusion does NOT apply here and is recorded rather than dropped.** Baldwin's DA
was excluded partly for sitting on a **multi-county** circuit. Atlanta Judicial Circuit is Fulton alone
and Stone Mountain Judicial Circuit is DeKalb alone — both are county-coterminous, so the geography
objection is absent. They stay out on the prosecutor rule only. The next Georgia wave with a
single-county circuit will raise this again.

### R4 — Fulton elects a Surveyor; DeKalb does not

Fulton's **Surveyor** is on the 2024 certified ballot (Fred Quinn, Jr., unopposed) — as Baldwin's was.
No Surveyor contest appears in any DeKalb return. Per `ga.md`, Coroner and Surveyor are seated only
where the county **genuinely elects them countywide**, never inherited from another county's template.

### R5 — DeKalb's elected CEO has no analogue in the corpus

DeKalb elects a **Chief Executive Officer** countywide — the only Georgia county that does. It is a
county-wide elected executive, not a commission chair, and the Board of Commissioners has 7 members
with no at-large chair. Fulton's structure is the opposite: an at-large **Chairperson** who sits on
the board, and no CEO.

🔴 **Do not standardise these two.** They are different offices with different powers.

### R6 — DeKalb's 7 seats are 5 districts plus 2 SUPER districts

Districts 1–5 are single-member. **Super District 6** and **Super District 7** each overlay roughly
half the county, so every DeKalb address has **two** commissioners. Fulton has no such overlay.

⚠ This means the per-district positive control for DeKalb must assert **two** holders at an interior
point, not one. The standard "exactly one holder" control would fail on correct data.

---

## The roster

### City of Atlanta (17 offices, 17 people, 0 vacancies)

All 17 confirmed by A + C. Vote shares are the **merged** Fulton + DeKalb certified totals
(2025-11-04, certified 2025-11-21).

| Seat | Person | 2025 result | Start of continuous occupancy | Precision |
| --- | --- | --- | --- | --- |
| Mayor | **Andre Dickens** | 85.03% | **2022-01-03** (source D, first oath) | `day` |
| Council President | **Marci Collier Overstreet** | 51.51% over Rohit Malhotra | **2026-01-05** (source D, new to this office) | `day` |
| Post 1 At Large | **Michael Julian Bond** | 58.62% | open — see note | `unknown` |
| Post 2 At Large | **Matt Westmoreland** | unopposed | **2018-01-01** ("since first taking office in January 2018", source B) | `month` |
| Post 3 At Large | **Eshé Collins** | unopposed | open | `unknown` |
| District 1 | **Jason H. Winston** | unopposed | **2022-01-01** ("since 2022", source B) | `year` |
| District 2 | **Kelsea Bond** | 63.97% | **2026-01-05** (new; "elected in November 2025", source B) | `day` |
| District 3 | **Byron D. Amos** | 59.44% | open | `unknown` |
| District 4 | **Jason Dozier** | 68.76% | open | `unknown` |
| District 5 | **Liliana Bakhtiari** | unopposed | open | `unknown` |
| District 6 | **Alex Wan** | unopposed | open | `unknown` |
| District 7 | **Thomas Worthy** | 27.13% → **runoff 2025-12-02** | **2026-01-05** ("first term", source B) | `day` |
| District 8 | **Mary B. Norwood** | unopposed | open — see note | `unknown` |
| District 9 | **Dustin Hillis** | 58.59% | open — "first elected 2017, third term" (source B) | `unknown` |
| District 10 | **Andrea L. Boone** | unopposed | open — "second term" (source B) | `unknown` |
| District 11 | **Wayne Martin** | 33.18% → **runoff 2025-12-02** | **2026-01-05** (new) | `day` |
| District 12 | **Antonio Lewis** | 57.95% | open | `unknown` |

#### 🔴 Why eleven starts are `unknown` rather than guessed

`term_start` is the start of **continuous occupancy by that person**, not the start of the current
term. Re-election does not restart it. Establishing it needs a dated oath or an explicit
"since YYYY" from the officeholder's own source, and for ten of these neither exists:

- The SOS portal carries **no Atlanta municipal election before 2025** (defect 7), so there is no
  certified chain to walk back.
- The member bios mostly carry no date language at all. The year tokens that *do* appear on every
  page (2020, 2022, 2026, 2027) are page furniture — budget and calendar links — not biography.
  Reading them as term dates is precisely the trap.

Per the honesty rule in `CLAUDE.md`, these are written as **open-ended terms with
`start_precision => 'unknown'`** — what the phase-2 backfill did — and not as a guess. The seat is
correct, the holder is correct, and the start is openly unknown.

⚠ **Two of these need a GAP check before any later pass dates them**, because a return after a gap
*does* restart occupancy while a re-election does not:

- **Mary B. Norwood** served at-large before leaving the council, then returned in District 8.
- **Michael Julian Bond** served at-large in the 1990s, left, and returned later.

Dating either from their first-ever service would be wrong by a decade.

#### 🔴 D7 and D11 are seated on the CITY's record, not on a certified result

Both fell to the 2025-12-02 runoff and that runoff **is not in the SOS portal** (defect 7). Source C,
the Municipal Clerk's own "2026 City of Atlanta Elected Officials", is the authority that Worthy and
Martin took office. Source A and source B agree. The certified runoff return is **open item 3**.

### Fulton County (11 offices, 10 people, 1 vacancy)

| Seat | Person | Evidence | Start |
| --- | --- | --- | --- |
| Commission Chairperson | **Robb Pitts** | I, F (2026 primary `(I)`) | open, `unknown` |
| Commission District 1 | **Bridget Thorne** | I, F (2026 primary `(I)`) | open, `unknown` |
| Commission District 2 | **Bob Ellis** | F 2024 `(I)` 54.54% | open, `unknown` |
| Commission District 3 | **Dana Barrett** | I | open, `unknown` |
| **Commission District 4** | 🔴 **VACANT** | **J** — Call for Election, special 2026-11-03 | see below |
| Commission District 5 | **Marvin S. Arrington, Jr.** | I | open, `unknown` |
| Commission District 6 | **Khadijah Abdur-Rahman** | F 2024 `(I)`, unopposed | open, `unknown` |
| Sheriff | **Patrick "Pat" Labat** | F 2024 `(I)`, unopposed | open, `unknown` |
| Clerk of Superior Court | **Che' Alexander** | F 2024 `(I)`, unopposed | open, `unknown` |
| Tax Commissioner | **Arthur E. Ferdinand** | F 2024 `(I)`, unopposed | open, `unknown` |
| Surveyor | **Fred Quinn, Jr.** | F 2024, unopposed, **not** marked `(I)` | **2025-01-01**, `year` |

#### 🔴 District 4 — vacant, and how the county's own roster hides it

Fulton's commissioners page (source I) lists **six** people and simply has no District 4 entry. It
carries **no vacancy notice**. Silence is not a negative, and a roster built from that page alone
would have created 6 commission seats instead of 7 — the seventh would then be an office with no
term row, invisible, with nothing erroring.

What actually happened, on primary evidence:

- **Mo Ivory** won District 4 unopposed in 2024 (74,873 votes, source F).
- Her District 4 term runs to 2028. The Chair term begins January 2027. The terms **overlap**, so
  Georgia's resign-to-run rule required her to resign before qualifying for Chair.
- Source **J**, the county's official **Call for Election** under O.C.G.A. § 21-2-540, signed by the
  Director of Registration & Elections, calls a **special election for Fulton County Commission
  District 4 on 2026-11-03**, runoff 2026-12-01. A special election is called to fill a vacancy.
- She then beat the sitting Chairman **65.96% to 34.04%** in the 2026-06-16 Democratic runoff (source F).

🔴 **The resignation DATE is not sourced.** Press reports 2026-03-06; the notice filename encodes a
2026-03-17 notice date, which is consistent but is not a statement of the vacancy date.

Per `CLAUDE.md` — *"do not write a vacancy span whose start date you don't know — set
`offices.is_vacant` and leave the span unwritten"* — District 4 is written as an office with
`is_vacant = true` and **no `office_terms` row**. This is **open item 4**.

### DeKalb County (11 offices, 11 people, 0 vacancies)

| Seat | Person | Evidence | Start |
| --- | --- | --- | --- |
| Chief Executive Officer | **Lorraine Cochran Johnson** | G 2024, unopposed, **not** `(I)` | **2025-01-01**, `year` |
| Commission District 1 | **Robert Patrick** | G 2024 `(I)`, unopposed | open, `unknown` |
| Commission District 2 | **Michelle Long Spears** | L, G (2026 primary `(I)`) | open, `unknown` |
| Commission District 3 | **Nicole Massiah** | G 2024 **special**, 42.26% → runoff; 2026 primary `(I)` | see note |
| Commission District 4 | **Chakira Johnson** | G 2024, unopposed, **not** `(I)` | **2025-01-01**, `year` |
| Commission District 5 | **Mereda Davis Johnson** | G 2024 `(I)`, unopposed | open, `unknown` |
| **Super** District 6 | **Edward "Ted" Terry** | G 2024 `(I)`, unopposed | open, `unknown` |
| **Super** District 7 | **LaDena Bolton** | G 2024 **special** → runoff; 2026 primary `(I)` 55.99% | see note |
| Sheriff | **Melody M. Maddox** | G 2024 `(I)` + her office's own site, apply day | open, `unknown` |
| Clerk of Superior Court | **Debra DeBerry** | G 2024 `(I)` + "Meet The Clerk", apply day | open, `unknown` |
| Tax Commissioner | 🔴 **Nicole M. Golden** | **her office's own site, apply day** — see below | **2025-12-31**, `day` |

#### 🔴🔴 THE APPLY-DAY CHECK CAUGHT A DEPARTURE — AND IT IS GA-3's CORONER, EXACTLY

This wave was built seating **Irvin J. Johnson** as DeKalb Tax Commissioner. He won the office
**unopposed** on the 2024 certified general, carrying the SOS's own `(I)` incumbency marker, and
the county's site linked to his office. Three sources, all agreeing.

🔴 **All three predated the change.** The Tax Commissioner's own website states:

> "Nicole M. Golden was sworn in as DeKalb County Tax Commissioner on **December 31, 2025**."

Irvin J. Johnson appears **nowhere** on that site. `ga.md` records that GA-3 put a retired coroner
into production because every source agreed and all of them were stale. This is the same failure,
caught one step earlier — and the **only** thing that caught it was asking again on apply day.

▶ **ASK ON APPLY DAY.** It is cheap, and it is the only check that sees a departure.

⚠ The find also produced a **better** date than the one it replaced: a stated oath, so `day`
precision, where the row it replaced would have been `unknown`.

Because one of eight officers was wrong, **all** of them were then re-checked against their own
offices' sites on 2026-10-17:

| Officer | Re-confirmed on | |
| --- | --- | --- |
| Fulton Sheriff, Patrick "Pat" Labat | the county's own Sheriff page | 🟢 |
| Fulton Clerk, Che' Alexander | `fultonclerk.org` | 🟢 |
| Fulton Tax Commissioner, Arthur E. Ferdinand | `fultoncountytaxes.org`, carrying 2026 deadlines | 🟢 |
| Fulton's 6 commissioners | the county roster, District 4 still absent | 🟢 |
| DeKalb CEO, Lorraine Cochran-**Johnson** | the county's CEO page | 🟢 |
| DeKalb Sheriff, Melody M. Maddox | `dekalbsheriff.org` | 🟢 |
| DeKalb Clerk, Debra DeBerry | `dksuperiorclerk.com`, "Meet The Clerk" | 🟢 |
| DeKalb Tax Commissioner | 🔴 **CHANGED** — Golden, not Johnson | |
| **Fulton Surveyor, Fred Quinn, Jr.** | ⚠ **nothing since the 2024 return** | ⚠ |

⚠ **The Surveyor is the one row in the wave with no post-2024 confirmation.** Fulton publishes no
Surveyor page; the office is real and on the 2024 certified ballot, but nothing newer names its
holder. (`ga.md` records Ballotpedia as a dead route for Georgia county officers.) Seeded on the
certified result, and recorded here as the weakest row in the wave — **open item 8**.

#### ⚠ The CEO's name is hyphenated and the certified ballot is not

The 2024 SOS return reads "Lorraine Cochran Johnson". Her own county page reads
"Cochran-**Johnson**" throughout. Settled against the officeholder's own office, as GA-5 settled
its spellings; the ballot form is kept as an `alternate_names` entry.

🟢 That page also corroborates the Super District 7 chain independently: "Prior to her election as
CEO, Cochran-Johnson served as DeKalb County Commissioner for **Super District 7 from 2018 to
2024**" — which is the seat Adams led and Bolton won.

#### 🟢 Super District 7 — the first round INVERTED, and the incumbency marker caught it

The 2024 certified **special** for Super District 7 was led by **Jacqueline Adams** on 45.98% — no
majority, so it went to a runoff. Seating the leader of the first round would have installed the
wrong person.

The county's roster (L, M) names **LaDena Bolton**. The arbiter is the 2026 primary return (G), where
she appears as **`LaDena Bolton (I)`** and beats Adams **55.99% to 31.58%**. The `(I)` marker is the
county-independent confirmation that she, not Adams, holds the seat.

District 3 ran the same shape: Massiah led the 2024 special on 42.26%, won the runoff, and appears in
the 2026 primary as `Nicole Massiah (I)`.

🔴 **Both were SPECIAL elections for unexpired terms, and a special winner is seated on
certification, not the following January.** Columbus proved this twice (`ga.md`, GA-4). So
2025-01-01 is **wrong** for these two, and their oath dates are **open item 5**. Written `unknown`
until sourced.

---

## The change-check — "has this person LEFT?"

Per spec §4 step 3. A source cannot report a change that postdates it, and a resignation is exactly
what silently seats the wrong person. This wave already found one: Fulton District 4.

| Body | Freshest evidence | Date |
| --- | --- | --- |
| Atlanta, all 17 | Municipal Clerk's 2026 elected-officials record (C) | 2026 term |
| Fulton commission | 2026 primary + runoff returns naming 4 of 7 as candidates (F) | 2026-06-16 |
| Fulton D4 | Call for Election (J) | 2026-11-03 election |
| DeKalb commission | 2026 primary returns marking D2/D3/D7 `(I)` (G) | 2026-05-19 |
| Fulton/DeKalb constitutional officers | 2024 certified returns only | **2024-11-05 — the stalest cohort** |

🔴 **The county constitutional officers are the weakest cohort in the wave**, exactly as Baldwin's
coroner was. Six people — Labat, Alexander, Ferdinand, Quinn, Maddox, DeBerry, I. Johnson — rest on a
2024 certified result and a county web page. `ga.md` records that GA-3 put a **retired** coroner into
production because every source agreed and all of them predated the retirement. Each of these needs a
freshness check on apply day, not just a source check.

---

## Open items

| # | Item | Why it is open |
| --- | --- | --- |
| 1 | **Probate Judge, Fulton and DeKalb** | Both counties have a Probate Court. Neither judge appears in any certified return 2020–2026 (defect 6) and `gaprobate.gov` served a facet list, not a directory. **NOT seeded** — an office with no term row is invisible, so the office is not created either. Owed. |
| 2 | Neither county elects a **Coroner** | Inferred from absence plus a passing control. Needs a county source stating the medical-examiner system before it is recorded as settled. |
| 3 | Certified **2025-12-02 runoff** return for Atlanta D7 and D11 | Not in the SOS portal. Seats rest on source C. |
| 4 | Fulton **District 4 vacancy date** | Press says 2026-03-06; no primary source. Written `is_vacant` with no span. |
| 5 | DeKalb **D3 and D7 oath dates** | Special-election winners are seated on certification, not in January. |
| 6 | **Ten Atlanta start dates** | No certified chain before 2025; bios carry no date language. Written `unknown`. |
| 8 | **Fulton Surveyor, Fred Quinn, Jr.** | The only row in the wave with no post-2024 confirmation. Fulton publishes no Surveyor page. Seeded on the 2024 certified result; re-check when a source appears. |
| 7 | **District polygon layers** | ✅ sourced and cross-county coverage proved — see "Geography". **One structural item remains:** the duplicate District 12 row must be resolved (dissolve vs defect) before any load. |

---

## Geography — the district layers

| Layer | Endpoint | Features | Role |
| --- | --- | --- | --- |
| **Fulton Elections, `VotingDistrictsMapViewerAGOL` [8] City Council Districts** | `services1.arcgis.com/AQDHTHDrZzfsFsB5/.../VotingDistrictsMapViewerAGOL/FeatureServer/8` | **13 rows for Atlanta**, 48 all cities | 🟢 **the arbiter** — the layer the county builds ballots from |
| Fulton Elections, same service **[2] Commission Districts** | `.../FeatureServer/2` | 6 | 🟢 arbiter for Fulton's commission |
| Fulton GIS `Commission_Districts_2023` | `.../Commission_Districts_2023/FeatureServer/0` | 6 | same geometry, same stale roster field |
| Fulton GIS `Political_CommissionDistricts_2013` | `.../Political_CommissionDistricts_2013/FeatureServer/0` | — | 🔴 **superseded** — the 2013 map |
| **DeKalb `Adopted_Commissioner_District`** | `services2.arcgis.com/IxVN2oUE9EYLSnPE/.../FeatureServer/0` | **5** | adopted single-member map |
| **DeKalb `Adopted_Super_Commissioner_District`** | `.../Adopted_Super_Commissioner_District/FeatureServer/0` | **2** | adopted super-district overlay |

⚠ DeKalb publishes **`Plan_1`, `Plan_2`, `Plan_3` and four `Proposed_*`** commissioner layers beside
these. Those are redistricting options, not the adopted map. `Adopted_*` is the pair to load, and the
name is the only thing distinguishing them — exactly the Columbus shape.

### 🟢 DeKalb's super-district overlay is PROVED by population, not assumed

| Layer | Districts | Population each |
| --- | --- | --- |
| `Adopted_Commissioner_District` | 1, 2, 3, 4, 5 | 152,106 – 154,029 |
| `Adopted_Super_Commissioner_District` | 6, 7 | **381,445 and 382,937** |

The supers are each about **2.5×** a single district and together cover the county twice. So every
DeKalb address has **two** commissioners, and R6's warning about the positive control is measured
rather than inferred.

### 🔴🔴 THE BALLOT LAYER IS THE GEOMETRY ARBITER AND IS NOT A ROSTER — AND ITS STALENESS HAS TWO VINTAGES

Fulton Elections layer [8] carries an `Officers` field. Checked against the settled roster:

| District | `Officers` field | Actually holds | |
| --- | --- | --- | --- |
| 2 | Amir R. Farokhi | **Kelsea Bond** | 🔴 stale |
| 7 | **Howard Shook** | **Thomas Worthy** | 🔴 stale, and *older* |
| 11 | Marci Collier Overstreet | **Wayne Martin** | 🔴 stale |
| 1, 3, 4, 5, 6, 8, 9, 10, 12 | — | — | 🟢 correct |

**Fresh on 9 of 12, stale on 3** — the most dangerous ratio, because the layer reads as maintained.

🔴 **The two stale vintages are the real finding.** D11 names Overstreet, who held District 11 until
January 2026 — so that field was written after 2022. D7 names **Howard Shook**, who left in January
2022 — so that field is at least four years older. **One layer, one roster column, two vintages.**

`ga.md` records that freshness is a property of a field, not of a row. Atlanta adds a layer to that:
freshness is a property of a field **in a row**. Use layer [8] for geometry and **never** for occupancy.
Fulton's commission layers repeat it — both name **Natalie Hall** in District 4, who lost in 2024 and
whose successor has since resigned, leaving the seat vacant.

### 🔴 Thirteen rows for twelve districts — District 12 is MULTI-PART

Layer [8] returns **13** Atlanta rows: District 12 appears **twice**. Measured rather than guessed:

| OBJECTID | Rings | Vertices | Relative area | `Officers` |
| --- | --- | --- | --- | --- |
| 2 | 1 | **1,014** | 4.3593e-3 deg² | Antonio Lewis |
| 35 | 1 | **27** | 8.7897e-5 deg² — **~2% of the main body** | Antonio Lewis |

The geometries are **not** identical, so this is not a duplicated row. It is one district held by one
person, stored as two single-part polygons: a main body plus a small **detached exclave**.

✅ **Dissolve on `DistrNum` into a MULTIPOLYGON.** The result is 12 districts, one of which has two parts.

🔴 **A pre-flight asserting "12 polygons for 12 seats" FAILS on this layer as published**, and would
fail on correct data. Assert **12 districts after dissolve**, never 12 rows. This is the ND/SD
multi-member lesson in a different dress: row count and seat count are separate questions, and here
they differ for a third reason again — geometry, not representation.

### 🟢 Coverage across the county line is PROVED, with a control

Layer [8] is a **Fulton** county product, so the risk was that it clips at the county line and leaves
Atlanta's 6.55% DeKalb strip with no council district — answering in Fulton and going silent in
DeKalb, three of four answers, nothing erroring.

Tested end-to-end, not by inspection. Interior points were taken with `ST_PointOnSurface` on the
Atlanta∩county intersections — **not** a mean of vertices, which need not lie inside the polygon:

| Probe | Point | Layer [8] returns |
| --- | --- | --- |
| **control** — Atlanta ∩ Fulton | `-84.432142, 33.767421` | 🟢 **Atlanta District 3** |
| **test** — Atlanta ∩ DeKalb | `-84.320066, 33.750834` | 🟢 **Atlanta District 5** |

The control fires, so a hit is meaningful. **Fulton's layer carries the whole city, both counties.**

🟢 Corroborated independently by the certified return: District 5 cast **10,327 votes in DeKalb**
against **3,082 in Fulton** — D5 is majority-DeKalb, which only makes sense if the district genuinely
crosses the line. Two unrelated sources agree.

---

## ✅ APPLIED TO PRODUCTION 2026-10-17

| Artifact | What it wrote |
| --- | --- |
| `scripts/load-atlanta-council-districts.mjs` | **12** boundaries, `X0077` |
| `scripts/load-fulton-commission-districts.mjs` | **6** boundaries, `X0078` |
| `scripts/load-dekalb-commission-districts.mjs` | **5** + **2** boundaries, `X0079` / `X0080` |
| `CC_0238_atlanta_structure.sql` | 1 government, 3 chambers, 13 districts, 17 offices |
| `CC_0239_atlanta_incumbents.sql` | 17 people, 17 terms |
| `CC_0240_fulton_county_structure.sql` | 1 government, 2 chambers, 6 districts, 11 offices |
| `CC_0241_fulton_county_incumbents.sql` | 10 people, 10 terms |
| `CC_0242_dekalb_county_structure.sql` | 1 government, 3 chambers, 7 districts, 11 offices |
| `CC_0243_dekalb_county_incumbents.sql` | 11 people, 11 terms |

Measured in production after the apply:

| Government | Offices | Seated | Vacant |
| --- | --- | --- | --- |
| City of Atlanta | 17 | **17** | 0 |
| Fulton County | 11 | **10** | 1 |
| DeKalb County | 11 | **11** | 0 |

25 boundaries · 38 people · `offices_missing_terms` 432 → **433**, exactly the Fulton District 4
vacancy · `office_holders_as_of(2015-06-01)` returns **0** for all three governments, so the
`| unverified` tags bite in production and no undated term leaks into history.

`verify-atlanta-probes.sql` passes against production. `check:reachability` reports
**"nothing regressed"**, all three categories at baseline.

### 🔴 THE APPLY NEEDS `--single-transaction`, AND THE FIRST ATTEMPT PROVED IT

Every migration here builds `CREATE TEMP TABLE … ON COMMIT DROP`. Run through `psql` **without**
an explicit transaction, each statement autocommits, so the temp table is dropped the moment it
is created and the next statement fails with `relation "atl_districts" does not exist`.

⚠ **It is a PARTIAL apply, not a clean failure.** CC_0238's government row and its three chambers
committed before the error; the districts and offices did not. Nothing was corrupted — every
insert in these files is guarded by `NOT EXISTS`, so the corrected re-run skipped what existed
and completed — but a migration that half-applies is worth knowing about in advance.

▶ **Apply with `psql --single-transaction -v ON_ERROR_STOP=1 -f <file>`**, one file at a time.

### Still owed

| Wave | Content |
| --- | --- |
| ATL-4 | Assets — 38 headshots, 1 Atlanta banner. **Not started.** |

🔴 **The January 2027 re-seat is already owed.** Fulton Chair, D1, D3, D5 and the D4 special are on the
2026-11-03 ballot; DeKalb D2, D3 and D7 likewise. Mo Ivory is the Democratic nominee for Fulton Chair
against Robb Pitts' seat. Those seats change hands in January 2027 and this wave's rows must be closed
and re-seated then — not overwritten.
