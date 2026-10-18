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


---

## ✅ GAP-CLOSING ROUND — APPLIED 2026-10-17 (CC_0244, CC_0245)

Prompted by the operator asking whether the gaps could be researched deeper. They could. Two of
the five were closed, and **both had been written off for a bad reason**.

| | Before | After |
| --- | --- | --- |
| Atlanta starts undated | **10 of 17** | **1 of 17** |
| Probate Judge offices missing | **2** | **0** |
| Offices / seated, all three governments | 39 / 38 | **41 / 40** |
| Terms undated, all three governments | **27 of 38** | **20 of 40** |

⚠ The earlier write-up said "19 of 38 undated". That was wrong; the figure was **27 of 38**.

### 🔴🔴 GAP 1 — "the bios carry no date language" WAS A BROKEN DETECTOR, NEVER CONTROLLED

`CC_0239` asserts the member biographies carry no dates and that the year tokens on each page are
"budget and calendar links — not biography". Both claims came from a regex requiring the literal
phrase `elected in YYYY`.

Michael Julian Bond's page reads "elected to the Atlanta City Council **in 1993** ... and **in
2009** to the Post One, At-Large seat". `elected in \d{4}` does not match
`elected to the Atlanta City Council in 1993`. **The bios were in the server HTML the whole time.**

▶ The sweep *did* hit Hillis ("first elected ... in 2017"), and that one incidental hit is what
made the empty result look credible. **One lucky match is not a positive control** — it cannot
tell "the pattern works" from "the pattern is too narrow and got lucky once".

### 🟢🟢 GAP 2 — THE CERTIFIED CHAIN EXISTS; IT IS JUST NOT AT THE SECRETARY OF STATE

`CC_0239`'s claim that the SOS carries no Atlanta municipal election before 2025 is **true** and
was re-verified (2021 and 2013 return HTTP 204 for both counties; the statewide 2021 payload holds
one ballot item and no Atlanta contest). The error was treating the SOS as the only certified
source.

🟢 **Fulton County publishes its own certified-results archive back to 1979** — year-faceted,
official Election Summary and SOVC PDFs under
`fultoncountyga.gov/.../Registration-and-Elections/Search-Elections`. Fulton runs Atlanta's
municipal elections, so this is the authoritative return. It settled nine seats from the
2021-11-02 general, the 2021-11-30 runoff, the 2017-11 general and the 2017-12 runoff.

▶ **A city's election history lives with the COUNTY that runs its elections.** Check there before
concluding a chain does not exist.

### 🟢 GAP 3 — WHEN THE ELECTION RECORD IS SILENT ABOUT AN OFFICE, ASK THE OFFICE

The finding that no Probate Judge contest appears in any certified return 2020–2026 **stands** —
Georgia declares an unopposed nonpartisan candidate elected without a ballot. But "not on any
ballot" is not "cannot be sourced". Both courts publish their own judges:

| County | Probate Judge | Source |
| --- | --- | --- |
| Fulton | **Kenya M. Johnson**, Chief Judge | `fultonprobatega.org`, "Meet our Executive Team" |
| DeKalb | **Bedelia C. Hargrove**, Chief Probate Court Judge | `dekalbprobatega.com`, in her own first person |

⚠ Fulton also lists an **Associate** Judge (Marian Parker), filled by appointment. Only the
elected Chief Judge is seeded.

### What the nine newly dated Atlanta seats rest on

| Seat | Start | Evidence |
| --- | --- | --- |
| Post 1, M. J. Bond | 2010-01-01 `year` | elected 2009 to this seat (his page); `(I)` in 2021 |
| District 9, Hillis | 2018-01-01 `month` | won the certified 2017-12 runoff v Kwame Abernathy |
| District 10, Boone | 2018-01-01 `month` | won the certified 2017-11 general outright |
| Districts 1, 3, 4, 5, 12 | 2022-01-01 `month` | won the certified 2021-11-30 runoffs |
| District 6, Wan | 2022-01-01 `month` | 🔴 **a RETURN AFTER A GAP** — two terms 2010–2018, then lost the 2017 presidency runoff to Felicia Moore and left the council |
| District 8, Norwood | 2022-01-01 `month` | 🔴 **a RETURN AFTER A GAP, and to a different seat** — previously at-large |

🔴 `month`, not `day`: the certified return fixes the **election**, and Atlanta terms begin the
following January. The city's inauguration page dates the **mayor's** oaths (2022-01-03,
2026-01-05) but does not say councilmembers were sworn on those days, so no day is claimed.

### Still open after this round

| # | Item | Why |
| --- | --- | --- |
| 3 | Eshé Collins's start, Post 3 | **Window narrowed, not closed.** Absent from the 2021 Post 3 ballot (won by Keisha Sean Waites) and `(I)` in 2025, so between January 2022 and November 2025. Fulton's archive holds no Atlanta Post 3 special for 2022, 2023 or 2024, and neither does the SOS. |
| 4 | Fulton District 4 vacancy date | **Still open — the DATE is what is missing, and a third primary source did not supply it.** Chased 2026-10-17: the county's own consolidated sample ballot for 2026-11-03 prints the contest as *"For County Commissioner – District 4 (Unexpired Term **Mo Ivory, Resigned**)"*, and the qualified-candidates list shows all four candidates as `INCUMBENT: No`. That corroborates the predecessor and the reason on the county's own ballot, which is worth having, but neither document states **when** the seat fell vacant. BOC minutes remain the route. `is_vacant = true` with no span still stands. |
| 5 | DeKalb D3 / Super D7 oath dates | Not chased. Special-election winners seat on certification, not in January. |
| 8 | Fulton Surveyor freshness | Not chased. Still no source newer than the 2024 return. |
| 2 | Neither county elects a Coroner | **Still open, and the obvious route is a DEAD PAGE.** Chased 2026-10-17: web results quote `dekalbcountyga.gov/node/17055` saying DeKalb was *"the second county in the State of Georgia to abolish the office of the coroner"*, with Fulton first. 🔴 **That page now returns the 404 handler, and the live Medical Examiner page carries none of that history** — the search summary is quoting content the county has removed, so it must not be cited as a live source. Both counties do run a Medical Examiner's office (`fultoncountyga.gov/medicalexaminer`, `dekalbcountyga.gov/departments/public-safety/medical-examiner`), but ⚠ **an ME office does not by itself prove no elected coroner** — some Georgia counties have both. The Internet Archive was returning 503 when this was chased; retry the archived capture of node/17055, or go to the county code for the ordinance abolishing the office. |

---

## ✅ ATL-4 — HEADSHOTS APPLIED 2026-10-17 (CC_0246)

**34 of the 41 seats now carry a headshot.** 6 are deliberately blank and 1 is the Fulton D4
vacancy, which has no occupant to picture. Verified on the rendered page, not on the API:
`essentials.empowered.vote/politician/<id>` serves a 600×750 `<img alt="Andre Dickens portrait">`.

| Government | Seated | With headshot | Blank |
| --- | --- | --- | --- |
| City of Atlanta | 17 | **17** | 0 |
| Fulton County | 11 | **7** | 4 |
| DeKalb County | 12 | **10** | 2 |

Every image is an official government page, rendered to the house geometry (centre 4:5 crop,
Lanczos to 600×750, q90) and uploaded as `<politician_id>-headshot.jpg`. `CC_0246` writes **both**
`politician_images` (`type='default'`) **and** `politicians.photo_custom_url` — the grid reads
`images[]` first and the backend reads the scalar, so writing one alone is invisible on one side.

### 🔴🔴 A CIRCULAR-FRAMED SOURCE IS A DEFECT, AND NO EXISTING GATE SAW IT

Two sourced portraits — Fulton's Clerk and Fulton's Sheriff — were **discs on a flat matte**, not
rectangular photographs. Cropped to 4:5 they keep a wedge of that matte in all four corners. Every
check in the pipeline passed them: licence, resolution, no-monochrome, face-centre, and the source's
own alt text. **The operator caught them by eye on the contact sheet.**

▶ It is now a gate, in `framecheck.mjs`: corner flatness + corner agreement + matte mass + a radial
step. The discriminator is **corner agreement** — a disc on matte scores 0 (all four corners
identical); every real studio backdrop in the wave scored ≥ 24.

- 🔴 **THE GATE'S POSITIVE CONTROL IS TWO FIXTURES ON DISK, NOT TWO ROWS OF THE LIVE SET.** The first
  version named the two live rows. Fixing those rows removed them, and the next run reported
  **"FRAMED: none"** while proving nothing — a control that the work itself deletes. A fixture cannot
  leave the set. There is a **negative** control too (a known rectangular portrait), because a gate
  that says YES to everything would otherwise read as passing.

### What the two became

- **Sheriff Pat Labat** — re-sourced from the Sheriff's Office (`fcsoga.org/our-sheriff/`) at
  **1000×1250, already exactly 4:5**, so the crop discards nothing. His uniform nameplate reads
  LABAT in frame, which is identity evidence inside the image itself.
- **Ché Alexander, Clerk of Superior Court** — ⚠ **left blank.** The clerk site serves only the disc
  on green matte. The county's other asset is a **1920×350 banner**, and because her head nearly
  fills its height, every 4:5 cut from it clips her hair. Three crop anchors were swept and all three
  failed. A blank beats a clipped frame.

### ⚠ Four Fulton commissioners enlarge 3.75×

Pitts, Thorne, Arrington and Abdur-Rahman publish **nothing larger than a 200×200 grid thumbnail**.
Per-district pages (`/commissioners/district-N`) all return 404, and the Sitecore `?mw=1600&mh=1600`
render returns the same 200×200 — the uploads really are that small. Ellis, Barrett and Labat *did*
grow under `?mw=`, to 417–418, so the query-string trick works where a larger original exists; it
just does not here. **Re-source these four when Fulton republishes.**

🟢 Two sources were upgraded by probing past the served derivative: DeKalb's Tax Commissioner from
900×900 to **2065×2065** (WordPress original), and the three Sitecore images above. DeKalb's Drupal
originals are *not* bigger — `/styles/default/public/` and the unstyled path are both 277×353.

### Still owed on ATL-4

| Item | State |
| --- | --- |
| 4 Fulton re-sources | When Fulton publishes anything larger than 200×200. |
| 6 blank seats | Listed in `CC_0246`'s header comment. Do not fill any of them with a placeholder. |

## ✅ ATL-4 — BANNER DONE 2026-10-17 (essentials PR #205)

🔴 **The banner was not a simple add: Georgia's STATE banner WAS Atlanta.** `states/GA.jpg` is
"Midtown Atlanta skyline". Read in the 6:1 band the browser cuts (rows 128–411 of 540) it keeps the
towers, the treeline and the whole downtown front — so the state really shows the city. That is the
**Michigan case**, not the Charlotte escape hatch, and it was measured, not assumed.

| key | what |
| --- | --- |
| `cities/atlanta.jpg` | the Midtown skyline, one tier down — a **byte copy**, sha256 verified |
| `states/GA-v2.jpg` | Providence Canyon, Stewart County · anonymouse1 · CC BY-SA 3.0 |

🟢 **The byte copy is the point.** `states/GA.jpg` was already exactly 1700×540, so nothing was
re-rendered and no crop drifted. Michigan had to re-render only because its state asset was off-spec
at 1700×422, and that re-render cost eleven candidate frames. **When the state asset is on spec,
copying it is both cheaper and strictly more faithful** — the composition already approved is the
composition that ships.

⚠ **`states/GA.jpg` must keep serving its old bytes**, because `cities/atlanta.jpg` is now exactly
those bytes. The state is versioned to `-v2` rather than overwritten, as `STATE_PANORAMA_FILES`
requires.

Five candidates were rendered by the repo's own `certify_banner.py` — not a second crop
implementation — so the approved frames are the shipping frames. The shipping file re-measures at
lum 96.5 / spread 45.4, identical to the certified candidate. **The four refusals transfer:**

- **Cloudland Canyon** — band luminance 56.5, `[dark]`. It had the **best** source ratio of the five
  (3.39:1) and still failed. 🔴 **Ratio is not the test.**
- **Tallulah Gorge** — the band is a concrete dam, not the gorge, and the source has no vertical
  slack, so no anchor reframes it.
- **Sapelo Island** — channel spread **7.0** against 24–61. Grey water, grey mud, grey birds: a
  colour photograph of a colourless scene. The Milledgeville greyscale defect again.
- **Chesser Prairie (Okefenokee)** — the alternate, not refused. Brightest band and highest spread;
  marked down only on adjacency, being close to the Columbus mill row in composition.

Providence Canyon carries **no architecture**, which is what separates it from every Georgia city
banner — Columbus, Macon and Milledgeville are all built subjects.

🔴 **On merge, check the deploy actually fired.** Essentials deploys from Render
(`essentials-frontend`), and auto-deploy can silently not fire — no failed build, no build at all.
Confirm the SHA in `list_deploys`. The two assets are already uploaded and served; only the registry
ships with the PR.

🔴 **The January 2027 re-seat is already owed.** Fulton Chair, D1, D3, D5 and the D4 special are on the
2026-11-03 ballot; DeKalb D2, D3 and D7 likewise. Mo Ivory is the Democratic nominee for Fulton Chair
against Robb Pitts' seat. Those seats change hands in January 2027 and this wave's rows must be closed
and re-seated then — not overwritten.

---

## 🟢 COUNTY-RETURN ROUND — 2026-10-18 (CC_0248; CC_0249 reserved, deliberately unwritten)

Prompted by the operator asking to finish the full seed. **13 of the 20 undated occupancies are
now dated**, open items 2, 3 and 5 are **closed**, item 4 is **narrowed to a five-day window**, and
item 8 is **re-checked**.

| | Before | After |
| --- | --- | --- |
| Terms undated, all three governments | **20 of 40** | **7 of 40** |
| Open items 2, 3, 5 | open | **closed** |
| Item 4, Fulton D4 vacancy | press date only, no primary source | **bracketed 2026-03-05 … 2026-03-09 by the county's own record** |
| Headshot blanks | 6 | **5 sourced** (Hargrove found and rendered; upload pending) |

### 🔴🔴 THE BLANK ROWS WERE RIGHT, AND THE REASON IS A SCHEMA FACT NOBODY HAD WRITTEN DOWN

`term_start` is the start of **continuous occupancy of the seat**, not the start of the current
statutory term. Measured on production before anything was written:

```
same (office_id, politician_id) holding more than one office_terms row = 0
   across 10,556 terms on 10,173 offices
```

**A re-election never opens a new row.** So an `(I)` incumbency marker can never date an occupancy
— it says only "already held it". Every row `CC_0241`/`CC_0243` left blank carried `(I)` in 2024,
and the three county rows they *did* date (Fulton Surveyor, DeKalb CEO, DeKalb District 4) are
exactly the three carrying **no** `(I)`. That was not an oversight; it was the honesty rule working.
What changed in this round is the **source**, not the standard.

▶ **Dating a 2024-re-elected incumbent as 2025-01-01 would have written 10 false start dates.**

### 🔴🔴 THE SECRETARY OF STATE HAS NO COUNTY OFFICES BEFORE 2024 — A SIXTH SOURCE DEFECT

GAP 2 found that Atlanta's municipal chain lives at the county. The same is true of the **county's
own** offices:

| SOS per-county payload | County offices present? |
| --- | --- |
| 2016, 2018, 2020, 2022 | 🔴 **none** — federal and state contests only |
| 2024 | 🟢 Clerk, Sheriff, Tax Commissioner, Surveyor, Solicitor, three commission seats |

Fulton 2022 returns **49 contests and not one county office**; Fulton 2024 returns 50 including all
of the above. **Same parser both times — that is the differential control.** Contest counts were
confirmed non-zero for every file (Fulton 2016=48, 2018=57; DeKalb 2016=34, 2018=43), so the
absence belongs to the payload, not to the reader.

### 🟢 Three reusable routes, all keyless

| Route | Endpoint | Reach |
| --- | --- | --- |
| **DeKalb's own archive** | `dekalbcountyga.gov/departments/voter-registration-and-elections/election-results` | per-year ZIPs of official results, **2003–2025** |
| **Fulton's own archive** | `POST www.fultoncountyga.gov/api/feature/documents?…&PageFilter={9C10885F-6095-4865-8CE1-CA4C298BCF0A}&startingPath=60650BA70450420CA705EF6A3D2BC555` | **460 certified reports, 1969–2025**. 🔴 Thin after 2022 (2023:2, 2024:2, 2025:2) and holds **no November 2022 general** |
| **Legistar, no key** | `webapi.legistar.com/v1/{fulton,dekalbcountyga,atlantaga}` | agendas, minutes, matters. Fulton's client slug is `fulton` — one body, id 138 |

⚠ **Four notations for one contest**, across years and counties — `County Commission District 5`,
`CC D5`, `CC D5- D`, `County Comm 5` — and the `(Vote for 1)` heading format disappears before 2020.
A heading regex written against one year silently returns nothing on another. **Scan by name as
well as by heading.** This cost two false "not present" readings in this round.

### What the 13 newly dated seats rest on

| Seat | Start | Evidence |
| --- | --- | --- |
| Atlanta Post 3, Collins | 2024-12 `month` | won the certified **2024-12-03** runoff; the 2024-11-05 special gave no majority and she polled **second**, 24.47% |
| Fulton Sheriff, Labat | 2021-01 `month` | certified Fulton 2020 general, **no `(I)`**; `(I)` by 2024 |
| Fulton D2, Ellis | 2015-01 `month` | certified Fulton 2014 SOVC, no `(I)`; then `(I)` in 2016, 2020 and 2024 |
| Fulton D5, Arrington | 2015-01 `month` | certified Fulton 2014 SOVC, no `(I)`; `(I)` in the certified 2022 primary |
| Fulton D6, Abdur-Rahman | 2021-01 `month` | certified Fulton 2020 general, no `(I)` |
| Fulton D1, Thorne · D3, Barrett | 2023-01 `month` | certified 2022-05-24 primary, no `(I)`, beside `Robb Pitts (I)` |
| DeKalb D1, Patrick | 2021-01 `month` | certified DeKalb 2020 general — the `(I)` sits on **Nancy Jester**, whom he beat |
| DeKalb D2, Spears | 2023-01 `month` | certified DeKalb 2022 general, no `(I)` |
| DeKalb D3, Massiah | 2024-12 `month` | certified **2024-12-03** runoff, 75.99% |
| DeKalb D5, Davis Johnson | **2015-07** `month` | certified **2015-07-14 special runoff**, 53.12% |
| DeKalb Super D6, Terry | 2021-01 `month` | certified DeKalb 2020 general, no `(I)` |
| DeKalb Super D7, Bolton | 2024-12 `month` | certified **2024-12-03** runoff, 70.32% |

🔴 **`month`, never `day`.** A certified return fixes the **election**. No document in this wave
states an oath day for any of the 13, and neither county's Legistar holds a matter containing
"Oath" — controlled against `substringof('Resolution')`, which does return rows.

🔴 **Three of the 13 are seated on CERTIFICATION, not the following January** — Massiah and Bolton
in December 2024, as `CC_0243` had already warned, and Davis Johnson in **July 2015**.

🔴 **A DOCUMENT TITLED FOR THE RIGHT SEAT CAN DATE THE WRONG PERSON.** *October 2019 Special Runoff
… Fulton County Commissioner District 6* reads exactly like Abdur-Rahman's start. It was won by
**J. Carn**, 62.79%; she won the seat a year later. Read the winner, never the title.

🔴 **`CC_0248` STRIPS THE `| unverified <slot>` TAG** from all 13. Per `CA_0171`,
`office_holders_as_of(date)` **skips** tagged terms. A term that gains a start must lose the tag or
it stays invisible to "who represented me in 2019" for ever.

⚠ **`seat_officeholder()` IS THE WRONG TOOL FOR DATING AN EXISTING TENURE.** Read its body: when the
same person already holds the seat it returns the existing row **untouched**. It seats people; it
does not refine a date. Dating an existing open term is a plain guarded `UPDATE`. **There is no
helper for this**, and the two-step rule in `CLAUDE.md` does not cover it.

### ✅ Item 2 — NEITHER COUNTY ELECTS A CORONER. Closed on documents, not on the dead page.

The route this file recommended — an archived capture of `dekalbcountyga.gov/node/17055` — is not
needed and was not used.

| | Coroner on the certified ballot? |
| --- | --- |
| Fulton, every return held: 2014, 2016, 2017, 2020, 2022, 2024 | **no** |
| DeKalb, every return held: 2012, 2014, 2015, 2016, 2020, 2022, 2024 | **no** |
| 🟢 **Baldwin County 2024 — positive control, identical method** | **yes — Coroner, John Gonzalez** |

🔴 **The control is decisive because Baldwin's coroner ran UNOPPOSED** (one ballot option) and still
appeared. Coroner is a **partisan** county office, so the GAP 3 exception that hid both Probate
Judges — Georgia declares an *unopposed nonpartisan* candidate elected **without a ballot** — does
not apply here. An unopposed coroner *does* appear on the certified ballot. Twelve years of absence
therefore means the office is not elected in either county. Both run a Medical Examiner instead.

### 🟢 Item 4 — the vacancy is bracketed by Fulton's own legislative record

The press date (2026-03-06) now has primary-source corroboration, from `webapi.legistar.com/v1/fulton`:

| Date | Record |
| --- | --- |
| **2026-03-04** | Ivory still serving — sponsors a proclamation dated March 4 2026; her resolution **26-0124** is voted on |
| **2026-03-09** | matter **26-0182** introduced: qualifying fees for "District 4 **to be filled in the 2026 Special Election**" |
| 2026-03-13 | matter **26-0173** "Discussion: District 4 Vacancy (Arrington)", heard 03-18, where Ivory's board seats are redistributed |

⇒ the seat fell vacant between **2026-03-05 and 2026-03-09**. Still no document stating the day, so
`is_vacant = true` with **no span still stands**, per the `CLAUDE.md` rule against writing a span
whose start you do not know. The month is now certain if a span is ever wanted.

### ✅ Item 8 — re-checked 2026-10-18, and the silence now has a reason

Fulton's Surveyor is **not on the 2026 ballot** — zero Surveyor contests in the certified 2026-05-19
primary and 2026-06-16 runoff — because the seat runs 2025–2028, and **Fulton's Legistar holds no
Surveyor vacancy matter**. The 2024 certified result (Quinn, unopposed, 436,159 votes, no `(I)`, so
his first win) remains the freshest evidence, and the change-check is now **evidenced** rather than
merely absent. ⚠ Fulton's 2020 return shows the Surveyor contest with **no candidate and 0 votes**,
so the seat was unfilled immediately before him.

### ⚠ `framecheck.mjs` DOES NOT EXIST IN THIS REPOSITORY

The ATL-4 section above states the circular-source gate "is now a gate, in `framecheck.mjs`", with
two on-disk fixtures as its positive control. **No such file is tracked on any ref** — `git log
--all --diff-filter=A -- "*framecheck*"` returns nothing, and the only occurrence of the string in
the repo is that sentence. The gate was never committed, so it protects nobody. Its checks were
re-implemented ad hoc for this round and ought to be committed properly.

🔴 **The re-implementation failed its own first run, for a reason worth recording.** `sharp`'s
`.stats()` **ignores a preceding `.extract()`** and returns whole-image statistics. All four corners
came back byte-identical — which reads exactly like the disc-on-matte defect the gate hunts for. It
was a **broken detector**, caught only because a uniform answer is not trusted without a control.
Extract to a raw buffer first. With planted controls (a synthetic disc scores **0.0** and correctly
fails; a gradient scores **185.4** and correctly passes) the real portrait scores **151.1** and
passes.

### Still open after the county-return round

| # | Item | Why |
| --- | --- | --- |
| 1 | **7 undated occupancies** | Each blocker is named in `CC_0248`'s footer. In short: Pitts needs a Fulton **countywide** Nov-2017 or Nov-2018 return, and the archive slices its 2017 documents **by city**; Alexander arrived mid-term by **appointment** (Fulton's 2020 clerk was Cathelene "Tina" Robinson); Ferdinand dates to the 1990s; DeBerry was already `(I)` in **2012**; Maddox was already `(I)` in 2020 and DeKalb's only 2020 special is the **US House D5** one; both Probate Judges appear in **no** certified return. |
| 2 | Fulton **D1 and D3** rest on a certified **primary**, not a general | Neither the SOS nor Fulton's archive holds the **November 2022** general. The first-win year is evidenced; the general itself is not. |
| 3 | **Hargrove headshot — rendered and verified, NOT UPLOADED** | Source: `dekalbprobatega.com/wp-content/uploads/2020/07/Bedelia-2.jpg`, **800×800**, a real rectangular studio portrait sitting beside her own first-person text ("I am Bedelia C Hargrove, the Chief Probate Court Judge in DeKalb County"). Rendered to house geometry (centre 4:5, Lanczos, 600×750, q90) and passed corner-agreement (151.1) and colour (34.5) checks. **The storage upload could not be performed** — the credential is not reachable from that session. `CC_0249` is reserved and deliberately **left unwritten**: a `politician_images` row pointing at an absent asset publishes a broken image. |
| 4 | 4 Fulton re-sources · the other 5 blanks | Reasons sharpened: Ferdinand's department page serves only a **1920×350 hero of a sign**, not a portrait; Fulton Probate renders its content in **JS** with no portrait in the server HTML; DeKalb's Clerk has no reachable standalone site. |
| 5 | **January 2027 re-seat** | Unchanged, and now 16 days from the election. |

### ⚠ A possible over-precision in the existing data, not fixed here

Four Atlanta seats carry **`2026-01-05` at `day` precision** — D2 Bond, D7 Worthy, D11 Martin and
Council President Overstreet. The `CC_0244` note in this file states that the inauguration page
dates **only the Mayor's** oath and that *"no day is claimed"* for councilmembers. Either those four
rows are over-precise or that note is wrong. **Not changed here** — it needs the inauguration page
read again, and this round did not do it.

### 🔴🔴 THE CERTIFIED-RETURN ROUTE IS EXHAUSTED. ALL 7 REMAINING ARRIVED OFF-BALLOT.

Chased 2026-10-18 after the 13 were written. Every one of the seven was attempted, and they fail
for **one structural reason, not seven incidental ones**: a certified return can only date someone
who *won an election for that seat*. These seven did not.

| Seat | What the record actually shows |
| --- | --- |
| DeKalb Sheriff, **Maddox** | ⚠ **Correcting `CC_0248`'s first footer**: there WAS a 2020 Sheriff special — "Sheriff (Special From March)", voted **2020-05-19**, runoff **2020-08-11**. She carries **`(I)` in BOTH**, so it does not date her either. **Appointed** before March 2020. |
| Fulton Clerk, **Alexander** | Fulton's certified 2020 general shows a different clerk, **Cathelene "Tina" Robinson (I)**. The Clerk is not on the 2022 ballot. **Appointed** mid-term. |
| DeKalb Clerk, **DeBerry** | Already **`DEBRA DEBERRY (I)(D)`** in DeKalb's certified **2012** general. **Appointed** in or before 2012. |
| Fulton Probate, **Kenya M. Johnson** | In **no** certified return — the GAP 3 nonpartisan-unopposed rule. |
| DeKalb Probate, **Hargrove** | Same. |
| Fulton Chair, **Pitts** | `(I)` in the certified 2022 primary. Needs a **countywide** Nov-2017 or Nov-2018 return (see the two archive defects below). |
| Fulton Tax, **Ferdinand** | `(I)` continuously from 1996 onward; took office in the 1990s (see below). |

▶ **What would actually close these is APPOINTMENT records** — a Governor's executive order or a
court order — not another election archive. That is a different source class and a different pass.
Neither county's Legistar holds them: searches for DeBerry, Maddox, Ferdinand and Alexander return
only incidental matches in public-comment and proclamation boilerplate.

### 🔴 TWO MORE DEFECTS IN FULTON'S OWN ARCHIVE

Both found while chasing Ferdinand, and both will bite the next person who goes back before ~2005:

1. **The pre-2000 generals are IMAGE SCANS with no text layer.** `November-1996-General-Election.pdf`
   is 920 KB over 11 pages and `pdftotext` extracts **11 characters**. `November-1998-Fulton-General.pdf`
   extracts **10**. They are readable only by eye or by OCR, and no OCR is installed here.
2. 🔴🔴 **A FILENAME IN THE ARCHIVE CAN DESCRIBE THE WRONG ELECTION.**
   `Nov_07_2000_General.pdf` has a perfectly good text layer — of the **November 5, 2013 General
   Municipal and Special Election** (Kasim Reed (I) for Mayor). The name says 2000; the content is
   2013. **Read the header date inside every document from this archive before trusting it**, which
   is also the only reason this was caught rather than written up as a 2000 result.
