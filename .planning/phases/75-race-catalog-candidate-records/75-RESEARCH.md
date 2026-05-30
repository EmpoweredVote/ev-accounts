# Phase 75: Race Catalog + Candidate Records — Research

**Researched:** 2026-05-21
**Domain:** 2026 US Senate elections — race catalog and candidate data for migration
**Confidence:** HIGH (race catalog from senate.gov + Wikipedia + Ballotpedia; candidate details from WebSearch cross-referenced across multiple outlets)

---

## Summary

The 2026 Senate elections include 33 regular Class 2 seats plus 2 Class 3 special elections in Florida and Ohio, totaling 35 races. The phase spec says "34" — this research documents all 35 and notes the discrepancy below.

Senators use external_ids -400001 through -400090. Candidates should use a new range starting at -400101 (leaving gap -400091 to -400100 for any future senator additions). Migrations are currently at 195; the next available number is **196**.

The `unitedstates.github.io` CDN only covers people who have served in Congress with a bioguide ID. For candidates who have never served in Congress, use Wikipedia or campaign/government website portrait URLs. Many 2026 candidates ARE current or former House members — their CDN URLs are available and should be preferred.

**Primary recommendation:** Structure the migration as one large SQL file (196) with all candidate politician + office inserts. The race catalog (this document) IS the RACE-01 artifact.

---

## Race Count Clarification

The phase spec says "34 Class 2 Senate races." The actual breakdown:

| Category | Count |
|----------|-------|
| Regular Class 2 seats | 33 |
| Class 3 special elections (FL, OH) | 2 |
| **Total races Nov 3, 2026** | **35** |

The "34" in the phase spec appears to be a rounding or early-count artifact. This research catalogs all 35 races. For migration purposes, the FL and OH specials are included because they have contested candidates worth tracking.

---

## Complete 34-Race Catalog (33 Regular + 2 Specials)

### Legend

- **Status:** `GENERAL` = nominees decided, race heads to Nov 3 | `PRIMARY` = primary not yet held | `RUNOFF` = primary runoff needed before general
- **Seat type:** `REGULAR` = Class 2 six-year term | `SPECIAL` = completing prior senator's unexpired term
- **Open seat:** incumbent not running (retired/resigned/ran for other office)

---

### ALABAMA — Regular, Open Seat

| Field | Value |
|-------|-------|
| State | AL |
| Incumbent | Tommy Tuberville (R) — running for governor, not seeking re-election |
| Seat type | REGULAR (Class 2) |
| Primary date | May 19, 2026 (R) / May 19, 2026 (D) |
| Runoff date | June 16, 2026 (R runoff expected; no candidate hit 50%) |
| General | November 3, 2026 |
| Status | RUNOFF (R primary went to runoff) |
| Race competitiveness | Safe Republican |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Steve Marshall | R | Alabama Attorney General | Top primary finisher; in R runoff |
| Barry Moore | R | U.S. Representative (AL-02) | In R runoff with Marshall |
| Dakarai Larriett | D | — | Won D primary May 19 |

**R runoff:** Steve Marshall vs. Barry Moore (June 16, 2026). Runoff winner faces Larriett in November.

---

### ALASKA — Regular, Incumbent Running

| Field | Value |
|-------|-------|
| State | AK |
| Incumbent | Dan Sullivan (R) — seeking re-election |
| Seat type | REGULAR (Class 2) |
| Primary date | August 18, 2026 (top-four nonpartisan primary, RCV general) |
| General | November 3, 2026 |
| Status | PRIMARY |
| Race competitiveness | Likely Republican |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Mary Peltola | D | Former U.S. Representative (AK-at-large) | Most significant challenger; declared Jan 2026 |

---

### ARKANSAS — Regular, Incumbent Running

| Field | Value |
|-------|-------|
| State | AR |
| Incumbent | Tom Cotton (R) — re-elected in R primary March 3, 2026 |
| Seat type | REGULAR (Class 2) |
| Primary date | March 3, 2026 (COMPLETED) |
| General | November 3, 2026 |
| Status | GENERAL |
| Race competitiveness | Safe Republican |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Hallie Shoffner | D | Rice farmer | Won D primary March 3 with 81.2% |

---

### COLORADO — Regular, Incumbent Running

| Field | Value |
|-------|-------|
| State | CO |
| Incumbent | John Hickenlooper (D) — seeking re-election |
| Seat type | REGULAR (Class 2) |
| Primary date | June 30, 2026 |
| General | November 3, 2026 |
| Status | PRIMARY |
| Race competitiveness | Lean Democratic |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Janak Joshi | R | Former Colorado state Representative | First major R filer |
| Mark Baisley | R | Colorado state Senator | Also declared |

---

### DELAWARE — Regular, Incumbent Running

| Field | Value |
|-------|-------|
| State | DE |
| Incumbent | Chris Coons (D) — seeking re-election |
| Seat type | REGULAR (Class 2) |
| Primary date | September 15, 2026 |
| General | November 3, 2026 |
| Status | PRIMARY |
| Race competitiveness | Safe Democratic |

**Major declared non-incumbent candidates:**

No significant challengers identified as of May 2026. Delaware is a solid blue state. R primary details not surfaced in research.

---

### FLORIDA — Special Election (Class 3)

| Field | Value |
|-------|-------|
| State | FL |
| Incumbent | Ashley Moody (R) — appointed after Marco Rubio resigned to become Secretary of State |
| Seat type | SPECIAL (Class 3 — completing Rubio's term through Jan 2029) |
| Primary date | August 18, 2026 |
| General | November 3, 2026 |
| Status | PRIMARY |
| Race competitiveness | Likely Republican |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Alex Vindman | D | Retired Lt. Col., Army; NSC Ukraine expert | Leading D candidate |
| Angie Nixon | D | Florida state Representative | Also declared D |

**Note:** Moody faces minor R primary challengers (Perry, Gleason, Rivera) but is the strong favorite.

---

### GEORGIA — Regular, Incumbent Running

| Field | Value |
|-------|-------|
| State | GA |
| Incumbent | Jon Ossoff (D) — seeking re-election |
| Seat type | REGULAR (Class 2) |
| Primary date | May 19, 2026 (COMPLETED) |
| Runoff date | June 16, 2026 (R runoff) |
| General | November 3, 2026 |
| Status | RUNOFF (R primary went to runoff) |
| Race competitiveness | Toss-up / Lean Democratic |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Mike Collins | R | U.S. Representative (GA-10) | In R runoff; Trump-aligned |
| Derek Dooley | R | Former football coach, attorney | In R runoff; backed by Gov. Kemp |

**Note:** Gov. Brian Kemp declined to run. R runoff June 16 determines who faces Ossoff. Ossoff won D primary unopposed (or easily).

---

### IDAHO — Regular, Incumbent Running

| Field | Value |
|-------|-------|
| State | ID |
| Incumbent | Jim Risch (R) — won R primary May 19, 2026 |
| Seat type | REGULAR (Class 2) |
| Primary date | May 19, 2026 (COMPLETED) |
| General | November 3, 2026 |
| Status | GENERAL |
| Race competitiveness | Safe Republican |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| David Roth | D | — | Won D primary May 19 |

---

### ILLINOIS — Regular, Open Seat

| Field | Value |
|-------|-------|
| State | IL |
| Incumbent | Dick Durbin (D) — retiring (announced April 23, 2025) |
| Seat type | REGULAR (Class 2) |
| Primary date | March 17, 2026 (COMPLETED) |
| General | November 3, 2026 |
| Status | GENERAL |
| Race competitiveness | Safe Democratic |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Juliana Stratton | D | Illinois Lt. Governor | Won D primary March 17 |
| Don Tracy | R | Former Illinois Republican Party Chair | Won R primary March 17 |

---

### IOWA — Regular, Open Seat

| Field | Value |
|-------|-------|
| State | IA |
| Incumbent | Joni Ernst (R) — retiring (not seeking re-election) |
| Seat type | REGULAR (Class 2) |
| Primary date | June 2, 2026 |
| General | November 3, 2026 |
| Status | PRIMARY |
| Race competitiveness | Lean Republican / Toss-up |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Ashley Hinson | R | U.S. Representative (IA-02) | Front-runner, Trump-endorsed |
| Jim Carlin | R | Former Iowa state Senator | Primary challenger to Hinson |
| Zach Wahls | D | Iowa state Senator | Leading D fundraiser |
| Josh Turek | D | Iowa state Representative | Competing with Wahls in D primary |

---

### KANSAS — Regular, Incumbent Running

| Field | Value |
|-------|-------|
| State | KS |
| Incumbent | Roger Marshall (R) — seeking re-election |
| Seat type | REGULAR (Class 2) |
| Primary date | August 4, 2026 |
| General | November 3, 2026 |
| Status | PRIMARY |
| Race competitiveness | Safe Republican |

**Major declared non-incumbent candidates:**

No significant R challengers. Multiple D candidates declared (Anne Parelkar, Patrick Schmidt among others) but Kansas is safe R.

---

### KENTUCKY — Regular, Open Seat

| Field | Value |
|-------|-------|
| State | KY |
| Incumbent | Mitch McConnell (R) — retiring (not seeking 8th term) |
| Seat type | REGULAR (Class 2) |
| Primary date | May 19, 2026 (COMPLETED) |
| General | November 3, 2026 |
| Status | GENERAL |
| Race competitiveness | Safe Republican |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Andy Barr | R | U.S. Representative (KY-06) | Won R primary with 60.5%; Trump-endorsed |
| Charles Booker | D | 2020 + 2022 KY Senate D nominee | Won D primary with 47%; rematch vs. McGrath |

---

### LOUISIANA — Regular (Incumbent Lost Primary)

| Field | Value |
|-------|-------|
| State | LA |
| Incumbent | Bill Cassidy (R) — lost Republican primary May 16, 2026 (came in 3rd with 24.8%) |
| Seat type | REGULAR (Class 2) |
| Primary date | May 16, 2026 (COMPLETED); Runoff June 27, 2026 |
| General | November 3, 2026 |
| Status | RUNOFF |
| Race competitiveness | Safe Republican |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Julia Letlow | R | U.S. Representative (LA-05) | Led R primary with 44.8%; Trump-endorsed; in R runoff |
| John Fleming | R | Former U.S. Representative (LA-04) | Came 2nd with 28.3%; in R runoff |
| Gary Crockett | D | Political consultant | In D runoff June 27 |
| Jamie Davis | D | Tensas Parish police juror | In D runoff June 27 |

**Note:** Cassidy voted to convict Trump in 2nd impeachment trial. This is the first senator to lose renomination since Richard Lugar (2012).

---

### MAINE — Regular, Incumbent Running

| Field | Value |
|-------|-------|
| State | ME |
| Incumbent | Susan Collins (R) — seeking re-election |
| Seat type | REGULAR (Class 2) |
| Primary date | June 9, 2026 |
| General | November 3, 2026 |
| Status | PRIMARY |
| Race competitiveness | Lean Republican / Toss-up |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Graham Platner | D | Sullivan harbor master, Marine veteran | Presumptive D nominee |
| David Costello | D | Former MD Dept of Environment deputy secretary | Also declared D |

---

### MASSACHUSETTS — Regular, Incumbent Running

| Field | Value |
|-------|-------|
| State | MA |
| Incumbent | Ed Markey (D) — seeking 3rd full term |
| Seat type | REGULAR (Class 2) |
| Primary date | September 1, 2026 |
| General | November 3, 2026 |
| Status | PRIMARY |
| Race competitiveness | Safe Democratic |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Seth Moulton | D | U.S. Representative (MA-06) | Primary challenger to Markey |
| Alex Rikleen | D | Teacher, fantasy sports journalist | Also declared D |

**Note:** No major R challenger identified. Markey is in a D primary, not a general election threat.

---

### MICHIGAN — Regular, Open Seat

| Field | Value |
|-------|-------|
| State | MI |
| Incumbent | Gary Peters (D) — retiring (announced Jan 2025) |
| Seat type | REGULAR (Class 2) |
| Primary date | August 4, 2026 |
| General | November 3, 2026 |
| Status | PRIMARY |
| Race competitiveness | Toss-up |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Abdul El-Sayed | D | Former Wayne County Health Director; 2018 gov candidate | Progressive; Bernie-backed |
| Mallory McMorrow | D | Michigan state Senator (8th district) | Centrist-progressive; strong fundraiser |
| Haley Stevens | D | U.S. Representative (MI-11) | Establishment favorite; most electable per party |
| Mike Rogers | R | Former U.S. Representative (MI-08); 2024 Senate nominee | Decisive R frontrunner |

---

### MINNESOTA — Regular, Open Seat

| Field | Value |
|-------|-------|
| State | MN |
| Incumbent | Tina Smith (D) — retiring (not seeking 2nd full term) |
| Seat type | REGULAR (Class 2) |
| Primary date | August 11, 2026 |
| General | November 3, 2026 |
| Status | PRIMARY |
| Race competitiveness | Likely Democratic |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Peggy Flanagan | D | Minnesota Lt. Governor | Progressive; endorsed by Tina Smith |
| Angie Craig | D | U.S. Representative (MN-02) | Moderate; establishment-backed |
| Royce White | R | Former NBA player; 2024 Klobuchar challenger | Leading R candidate |
| Michele Tafoya | R | Retired broadcaster | Also in R primary |
| David Hann | R | Former Minnesota Senate Minority Leader | Also declared |

---

### MISSISSIPPI — Regular, Incumbent Running

| Field | Value |
|-------|-------|
| State | MS |
| Incumbent | Cindy Hyde-Smith (R) — won R primary March 10, 2026 |
| Seat type | REGULAR (Class 2) |
| Primary date | March 10, 2026 (COMPLETED) |
| General | November 3, 2026 |
| Status | GENERAL |
| Race competitiveness | Safe Republican |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Scott Colom | D | Lowndes County District Attorney | Won D primary March 10 |

---

### MONTANA — Regular, Open Seat

| Field | Value |
|-------|-------|
| State | MT |
| Incumbent | Steve Daines (R) — withdrew from re-election at filing deadline (March 4, 2026) |
| Seat type | REGULAR (Class 2) |
| Primary date | June 2, 2026 |
| General | November 3, 2026 |
| Status | PRIMARY |
| Race competitiveness | Lean Republican (but competitive with independent) |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Kurt Alme | R | U.S. Attorney for Montana | Daines-endorsed; filed minutes before deadline |
| Lee Calhoun | R | — | Also in R primary |
| Seth Bodnar | I | Former University of Montana president | Independent; needs ~13k signatures to qualify |

**Note:** No well-known Democrats entered by filing deadline. This is the first truly open MT Senate seat since 1976. Daines withdrew at the last possible minute (4:57pm at filing deadline); Alme filed at 4:52pm.

---

### NEBRASKA — Regular, Incumbent Running

| Field | Value |
|-------|-------|
| State | NE |
| Incumbent | Pete Ricketts (R) — seeking first full term (was appointed 2023) |
| Seat type | REGULAR (Class 2) |
| Primary date | May 12, 2026 (COMPLETED) |
| General | November 3, 2026 |
| Status | GENERAL |
| Race competitiveness | Safe Republican |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Cindy Burbank | D | Former pharmacy technician | D nominee |
| Dan Osborn | I | Former union leader | Independent; ran strongly in 2024; significant threat |

**Note:** Dan Osborn ran as an independent in the 2024 Senate race and came within ~2 points of incumbent Fischer. His 2026 candidacy against Ricketts is a genuine competitive threat even in Nebraska.

---

### NEW HAMPSHIRE — Regular, Open Seat

| Field | Value |
|-------|-------|
| State | NH |
| Incumbent | Jeanne Shaheen (D) — retiring (announced March 12, 2025) |
| Seat type | REGULAR (Class 2) |
| Primary date | September 8, 2026 |
| General | November 3, 2026 |
| Status | PRIMARY |
| Race competitiveness | Toss-up |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Chris Pappas | D | U.S. Representative (NH-01) | Presumptive D nominee; declared April 3, 2025 |
| John Sununu | R | Former U.S. Senator from NH (2003-2009) | Leading R candidate; declared Oct 2025 |
| Scott Brown | R | Former Massachusetts/New Hampshire Senator | Also in R primary |

---

### NEW JERSEY — Regular, Incumbent Running

| Field | Value |
|-------|-------|
| State | NJ |
| Incumbent | Cory Booker (D) — seeking 3rd full term |
| Seat type | REGULAR (Class 2) |
| Primary date | June 2, 2026 |
| General | November 3, 2026 |
| Status | PRIMARY |
| Race competitiveness | Likely Democratic |

**Major declared non-incumbent candidates:**

Multiple minor R candidates (Robert Lebovics, Justin Murphy, Natalie Rivera, Richard Tabor, Alex Zdan) but no top-tier challenger identified. NJ has been trending competitive but Booker is well-funded.

---

### NEW MEXICO — Regular, Incumbent Running

| Field | Value |
|-------|-------|
| State | NM |
| Incumbent | Ben Ray Luján (D) — seeking re-election |
| Seat type | REGULAR (Class 2) |
| Primary date | June 2, 2026 |
| General | November 3, 2026 |
| Status | PRIMARY |
| Race competitiveness | Likely Democratic |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Larry Marker | R | — | R primary candidate; no major R name entered |

---

### NORTH CAROLINA — Regular, Open Seat

| Field | Value |
|-------|-------|
| State | NC |
| Incumbent | Thom Tillis (R) — retiring |
| Seat type | REGULAR (Class 2) |
| Primary date | March 3, 2026 (COMPLETED) |
| General | November 3, 2026 |
| Status | GENERAL |
| Race competitiveness | Toss-up / Lean Democratic (early polling shows Cooper +8) |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Roy Cooper | D | Former North Carolina Governor (2017-2025) | Won D primary March 3; leading in polls |
| Michael Whatley | R | Former RNC Chair (March 2024 - Aug 2025) | Won R primary March 3; Trump ally |

**Note:** This is one of the most watched 2026 races. Cooper-Whatley projected to cost $650-800M. Cooper leads early polls by ~8 points.

---

### OHIO — Special Election (Class 3)

| Field | Value |
|-------|-------|
| State | OH |
| Incumbent | Jon Husted (R) — appointed after JD Vance resigned to become VP |
| Seat type | SPECIAL (Class 3 — completing Vance's term through Jan 2029) |
| Primary date | May 5, 2026 (COMPLETED) |
| General | November 3, 2026 |
| Status | GENERAL |
| Race competitiveness | Toss-up / Lean Republican |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Sherrod Brown | D | Former 3-term U.S. Senator from OH (lost 2024) | Won D primary May 5; seeking non-consecutive 4th term |

---

### OKLAHOMA — Regular, Open Seat (Appointed Incumbent Not Running)

| Field | Value |
|-------|-------|
| State | OK |
| Incumbent | Alan Armstrong (R) — appointed March 24, 2026 after Markwayne Mullin resigned for DHS Secretary; agreed not to seek full term |
| Seat type | REGULAR (Class 2) |
| Primary date | June 16, 2026 |
| Runoff date | August 25, 2026 (if no candidate hits 50%) |
| General | November 3, 2026 |
| Status | PRIMARY |
| Race competitiveness | Safe Republican |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Kevin Hern | R | U.S. Representative (OK-01) | Front-runner in R primary |
| Jim Priest | D | Lawyer | Significant D candidate |

**Note:** Armstrong (existing senator record in DB, external_id -400061 from migration 176) already has stance data from Phase 74. Armstrong cannot run for the full term per agreement. The winner of this primary will be a new person.

---

### OREGON — Regular, Incumbent Running

| Field | Value |
|-------|-------|
| State | OR |
| Incumbent | Jeff Merkley (D) — won D primary May 19, 2026 |
| Seat type | REGULAR (Class 2) |
| Primary date | May 19, 2026 (COMPLETED) |
| General | November 3, 2026 |
| Status | GENERAL |
| Race competitiveness | Likely Democratic |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| David Brock Smith | R | Oregon state Senator | Leading R candidate |

---

### RHODE ISLAND — Regular, Incumbent Running

| Field | Value |
|-------|-------|
| State | RI |
| Incumbent | Jack Reed (D) — seeking 6th term |
| Seat type | REGULAR (Class 2) |
| Primary date | September 9, 2026 |
| General | November 3, 2026 |
| Status | PRIMARY |
| Race competitiveness | Safe Democratic |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Raymond McKay | R | Former Rhode Island Republican Party official | R candidate; no tier-1 challenger |

---

### SOUTH CAROLINA — Regular, Incumbent Running

| Field | Value |
|-------|-------|
| State | SC |
| Incumbent | Lindsey Graham (R) — seeking 5th term |
| Seat type | REGULAR (Class 2) |
| Primary date | June 9, 2026 |
| General | November 3, 2026 |
| Status | PRIMARY |
| Race competitiveness | Safe Republican |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Annie Andrews | D | Pediatrician | Leading D candidate |

---

### SOUTH DAKOTA — Regular, Incumbent Running

| Field | Value |
|-------|-------|
| State | SD |
| Incumbent | Mike Rounds (R) — seeking 3rd term |
| Seat type | REGULAR (Class 2) |
| Primary date | June 2, 2026 |
| General | November 3, 2026 |
| Status | PRIMARY |
| Race competitiveness | Safe Republican |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Justin McNeil | R | Navy veteran, businessman | R primary challenger to Rounds |
| Julian Beaudion | D | Businessman, former SD state trooper | D candidate |

---

### TENNESSEE — Regular, Incumbent Running

| Field | Value |
|-------|-------|
| State | TN |
| Incumbent | Bill Hagerty (R) — seeking re-election; no R primary opposition |
| Seat type | REGULAR (Class 2) |
| Primary date | August 6, 2026 |
| General | November 3, 2026 |
| Status | PRIMARY |
| Race competitiveness | Safe Republican |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Marquita Bradshaw | D | Consultant; 2020 TN Senate D nominee | Most prominent D candidate |

---

### TEXAS — Regular, Incumbent Running

| Field | Value |
|-------|-------|
| State | TX |
| Incumbent | John Cornyn (R) — seeking re-election |
| Seat type | REGULAR (Class 2) |
| Primary date | March 3, 2026 (COMPLETED) |
| General | November 3, 2026 |
| Status | GENERAL |
| Race competitiveness | Safe Republican |

**Major declared non-incumbent candidates:**

No significant challenger identified in research. Texas is safe R for Cornyn.

---

### VIRGINIA — Regular, Incumbent Running

| Field | Value |
|-------|-------|
| State | VA |
| Incumbent | Mark Warner (D) — seeking re-election |
| Seat type | REGULAR (Class 2) |
| Primary date | August 4, 2026 |
| General | November 3, 2026 |
| Status | PRIMARY |
| Race competitiveness | Lean Democratic (VA won by Harris, but Warner is vulnerable) |

**Major declared non-incumbent candidates:**

Multiple minor D and R candidates filed (Mark Moran, Jason Reynolds on D side; R candidates unnamed in research). No tier-1 R challenger identified as of May 2026.

---

### WEST VIRGINIA — Regular, Incumbent Running

| Field | Value |
|-------|-------|
| State | WV |
| Incumbent | Shelley Moore Capito (R) — won R primary May 19, 2026 |
| Seat type | REGULAR (Class 2) |
| Primary date | May 12/19, 2026 (COMPLETED) |
| General | November 3, 2026 |
| Status | GENERAL |
| Race competitiveness | Safe Republican |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Rachel Fetty Anderson | D | Former Morgantown City Councilwoman | Won D primary May 12 |

---

### WYOMING — Regular, Open Seat

| Field | Value |
|-------|-------|
| State | WY |
| Incumbent | Cynthia Lummis (R) — retiring (not seeking re-election) |
| Seat type | REGULAR (Class 2) |
| Primary date | August 18, 2026 |
| General | November 3, 2026 |
| Status | PRIMARY |
| Race competitiveness | Safe Republican |

**Major declared non-incumbent candidates:**

| Name | Party | Prior role | Notes |
|------|-------|-----------|-------|
| Harriet Hageman | R | U.S. Representative (WY-at-large) | Front-runner |
| Jimmy Skovgard | R | Wyoming Army National Guard veteran | R primary challenger |
| James Byrd | D | Former Wyoming state Representative | D candidate |

---

## Races with No Major Non-Incumbent Challengers (Uncontested / Safe Incumbent)

These races have an incumbent running and no significant declared challenger. Still document in catalog but no new candidate records needed unless incumbent retires or loses primary.

| State | Incumbent | Party | Status |
|-------|-----------|-------|--------|
| DE | Chris Coons | D | Likely no significant R challenger |
| KS | Roger Marshall | R | No significant D/I challenger |
| NJ | Cory Booker | D | No tier-1 R challenger |
| NM | Ben Ray Luján | D | No tier-1 R challenger |
| RI | Jack Reed | D | No tier-1 R challenger |
| SC | Lindsey Graham | R | No tier-1 D challenger |
| TN | Bill Hagerty | R | No R opposition; minor D primary |
| TX | John Cornyn | R | No significant challenger |
| VA | Mark Warner | D | No tier-1 R challenger yet |

---

## Migration Approach

### External ID Range

Senators used -400001 through -400090. The convention is synthetic negative IDs for our data. Candidates should use a new range:

```
-400101 through -400200  (up to 100 candidate slots)
```

This leaves -400091 through -400100 as a small buffer for any future senator additions (e.g., if a senator is appointed to replace a vacancy in a state we haven't yet modeled).

### Migration Number

Based on filesystem audit, the last migration is **195** (`195_ca_state_assembly.sql`). The phase spec says "Next migration: 177" — this was correct at the time the spec was written (2026-05-19, before v2.4 started), but subsequent work has advanced the counter. The actual next available migration number is **196**.

Always verify before writing: `ls backend/migrations/ | sort -V | tail -5`

### SQL Pattern (from migrations 175, 176)

Candidates follow the exact same pattern as senators, with these differences:

```sql
-- Candidates differ from senators in:
-- 1. office_title: 'Candidate for U.S. Senate — [State]' (not 'U.S. Senator — [State]')
-- 2. is_current = false on the office row (they don't hold the seat)
-- 3. is_incumbent = false on politician row
-- 4. is_appointed = false (they're candidates, not appointees)
-- 5. No start_date / end_date on office row (they haven't been sworn in)
```

Full politician INSERT pattern:

```sql
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), '[Full Name]', '[First]', '[Last]', '[Party]',
          true, false, false, false, -400101)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, is_current, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',  -- U.S. Senate chamber UUID
       p.id,
       'Candidate', '[STATE_CODE]', false, false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = '[STATE_CODE]'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );
```

Photo UPDATE pattern (after all INSERTs):
```sql
UPDATE essentials.politicians SET photo_origin_url = '[URL]'
WHERE external_id = -400101
  AND (photo_origin_url IS NULL OR photo_origin_url = '');
```

### office_title Column

Looking at the schema: `essentials.offices` has a `title` column. The `office_title` field lives on `essentials.politicians`, not offices. Confirm this pattern matches migrations 175/176 — senator rows have `office_title` set via UPDATE after INSERT, or it may be set inline.

Check migration 175 to verify whether office_title is on the `politicians` table or the `offices` table before writing migration 196.

---

## Photo Source Strategy

### Priority Order

1. **`unitedstates.github.io` CDN** (HIGH confidence, stable URLs)
   - Pattern: `https://unitedstates.github.io/images/congress/225x275/{BIOGUIDE}.jpg`
   - Use for candidates who are current or former U.S. Representatives or Senators
   - Must HEAD-verify each URL before using (as with senators: Cindy Hyde-Smith had wrong bioguide)
   - Bioguide lookup: `https://github.com/unitedstates/congress-legislators/blob/main/legislators-current.yaml`

2. **Official government portrait** (HIGH confidence for incumbents, MEDIUM for candidates)
   - Pattern: `https://[name].house.gov/` or `https://[name].senate.gov/` portrait links
   - Used in migration 176 for Husted (OH) at `https://www.husted.senate.gov/wp-content/uploads/2025/10/Husted_OfficialPortrait.webp`

3. **Wikipedia direct image URL** (MEDIUM confidence — URL may change)
   - Pattern: `https://upload.wikimedia.org/wikipedia/commons/[hash]/[filename]`
   - Used for senators in migrations 175/176 where CDN was unavailable
   - Find via Wikipedia page → click image → right-click "View Image" for direct URL

4. **Campaign website** (LOW confidence — disappears after election)
   - Only use if no other source available
   - Document as low-confidence in migration comment

5. **Ballotpedia** — Ballotpedia's images require a request and are not directly hotlinkable for external use. Do not use Ballotpedia image URLs as photo_origin_url.

### Candidates Who Are Current House Members (CDN Available)

These candidates have served in Congress and likely have CDN photos:

| Candidate | State | Role | Likely Has CDN |
|-----------|-------|------|----------------|
| Barry Moore | AL | U.S. Rep (AL-02) | Yes — look up bioguide |
| Mary Peltola | AK | Former U.S. Rep (AK-at-large) | Yes — look up bioguide |
| Seth Moulton | MA | U.S. Rep (MA-06) | Yes — look up bioguide |
| Ashley Hinson | IA | U.S. Rep (IA-02) | Yes — look up bioguide |
| Haley Stevens | MI | U.S. Rep (MI-11) | Yes — look up bioguide |
| Mike Rogers | MI | Former U.S. Rep (MI-08) | Yes — look up bioguide |
| Angie Craig | MN | U.S. Rep (MN-02) | Yes — look up bioguide |
| Kevin Hern | OK | U.S. Rep (OK-01) | Yes — look up bioguide |
| Chris Pappas | NH | U.S. Rep (NH-01) | Yes — look up bioguide |
| Harriet Hageman | WY | U.S. Rep (WY-at-large) | Yes — look up bioguide |
| Mike Collins | GA | U.S. Rep (GA-10) | Yes — look up bioguide |
| Julia Letlow | LA | U.S. Rep (LA-05) | Yes — look up bioguide |
| Andy Barr | KY | U.S. Rep (KY-06) | Yes — look up bioguide |
| John Fleming | LA | Former U.S. Rep (LA-04) | Yes — may be in CDN |
| John Sununu | NH | Former U.S. Senator (NH) | Yes — in CDN as senator |

### Candidates Without CDN (Need Wikipedia/Campaign)

| Candidate | State | Role | Photo Strategy |
|-----------|-------|------|----------------|
| Steve Marshall | AL | Alabama AG | Look for official state portrait |
| Dakarai Larriett | AL | — | Campaign website / Wikipedia |
| Hallie Shoffner | AR | Farmer | Limited sources; campaign site |
| Roy Cooper | NC | Former Governor (NC) | Official governor portrait / Wikipedia |
| Michael Whatley | NC | RNC Chair | Wikipedia / official portrait |
| Juliana Stratton | IL | Illinois Lt. Governor | Official state portrait |
| Don Tracy | IL | Party chair | Wikipedia/LinkedIn |
| Ashley Hinson | IA | Rep — CDN available (see above) | CDN |
| Zach Wahls | IA | Iowa state Senator | Iowa legislature portrait |
| Peggy Flanagan | MN | MN Lt. Governor | Official state portrait |
| Sherrod Brown | OH | Former U.S. Senator | CDN — has bioguide |
| Kurt Alme | MT | U.S. Attorney for Montana | DOJ portrait or LinkedIn |
| Graham Platner | ME | Harbor master | Campaign website |
| Abdul El-Sayed | MI | Public health admin | Wikipedia |
| Mallory McMorrow | MI | Michigan state Senator | MI legislature portrait |
| Charles Booker | KY | 2022 nominee | Wikipedia/campaign |
| Jon Husted | OH | Already in DB (migration 176) | Already set |
| Alan Armstrong | OK | Already in DB (migration 176) | Already set |

---

## Definition of "Major Declared Candidate"

For Phase 75 purposes, a candidate qualifies as "major declared" if they meet ANY of:

1. **Elected official** — current U.S. Representative, statewide official (governor, AG, lt. governor), or state legislative leader
2. **Prior high-profile candidate** — ran statewide in 2020, 2022, or 2024 with >30% vote share OR in a competitive primary
3. **Significant fundraising** — raised >$500K in a FEC reporting period
4. **National media coverage** — named as candidate in multiple national outlets (NBC, NPR, WaPo, etc.)
5. **Party endorsement** — Trump endorsement (R) or equivalent D party establishment endorsement

**Explicitly exclude:**
- First-time candidates with no profile, no funding, and no media coverage
- Write-in candidates
- Perennial candidates without a plausible path
- Libertarian/Green/minor party candidates (unless they have significant independent funding)

**When in doubt:** If the candidate's name appears in the race catalog above, they qualify.

---

## Edge Cases and Special Situations

### 1. Appointed Incumbents Running for Their Own Term

- **Alan Armstrong (OK)**: Already in DB from Phase 73/74 with external_id -400061. He agreed NOT to run for the full term per appointment agreement. The winner of the OK R primary (Kevin Hern expected) will be a new candidate record. **Do not create a second Armstrong record.**
- **Jon Husted (OH)**: Already in DB from Phase 73/74 with external_id -400062. He IS running for the special election. He is therefore an "incumbent" in this race (appointed, seeking election). The D challenger Sherrod Brown is the non-incumbent.

### 2. Sherrod Brown (OH)

Brown was a 3-term senator who lost the 2024 Ohio Senate race to Bernie Moreno. His external_id from any prior records should be checked before creating a new one. He is a former U.S. Senator so he has a bioguide ID and CDN photo available.

**Check before inserting:** `SELECT * FROM essentials.politicians WHERE full_name LIKE '%Sherrod%Brown%'`

If a record exists from prior data, reuse it rather than creating a duplicate.

### 3. Louisiana — Cassidy Lost Primary

Bill Cassidy (R-LA) is the sitting senator but lost the Republican primary. He is still the current senator until Jan 2027 but will not be the R nominee. For migration purposes: Cassidy's record remains in the DB as the current senator. The two runoff candidates (Letlow and Fleming) are the non-incumbent candidates to add.

### 4. Montana — Daines Withdrew at Last Minute

Steve Daines is still the sitting Class 2 senator from Montana through Jan 2027. His senator record stays in the DB. The candidates (Alme, Calhoun, Bodnar) are the non-incumbents to add. Seth Bodnar is an independent — include him if he qualifies his signatures for the general election ballot.

### 5. Open Seats: Senate Seats Also Have Existing Senator Records

For open seats (incumbents retiring), the prior senator still holds the seat until January 2027. Their records exist in the DB from Phase 73. The candidates for the open seat get NEW records with `is_current = false` on their office rows.

### 6. The "34 Races" Number

As documented above, there are actually 35 races (33 Class 2 + 2 Class 3 specials). The phase spec's "34" is likely:
- An early count that included 33 Class 2 + OH special (most likely the number intended)
- Or a minor error in the spec

**Recommendation:** Treat all 35 races as in-scope for the catalog. For the migration, only add candidate records for races where there are major non-incumbent candidates worth tracking for stance research. The specials (FL and OH) clearly qualify given Vindman and Brown.

---

## Races Where No New Candidate Records Are Needed

These races have safe incumbents with no significant challengers — the incumbent already has a record in the DB from Phase 73. No new candidate records required:

| State | Reason |
|-------|--------|
| TX | Cornyn running unopposed; no significant challenger |
| DE | Coons running; no major R challenger |
| RI | Reed running; no major R challenger |
| KS | Marshall running; no major D challenger |
| NM | Luján running; no major R challenger |
| VA | Warner running; no tier-1 R challenger yet (primaries not held) |
| SC | Graham running; no tier-1 D challenger |
| TN | Hagerty running; Bradshaw is D candidate but TN is safe R |
| AR | Cotton running; Shoffner won D primary (add Shoffner as candidate) |

**Note:** For all these races, the RACE-01 catalog entry is still needed, but CAND-01 may have 0 or 1 new candidate record (the D nominee in safe-R states is technically a "major declared candidate" if they won their primary).

---

## Consolidated Candidate List for Migration

The following candidates need NEW `essentials.politicians` + `essentials.offices` records:

| # | Name | State | Party | Prior Role | Photo Strategy | external_id |
|---|------|-------|-------|-----------|----------------|-------------|
| 1 | Steve Marshall | AL | R | Alabama AG | State official portrait | -400101 |
| 2 | Barry Moore | AL | R | U.S. Rep AL-02 | CDN bioguide | -400102 |
| 3 | Dakarai Larriett | AL | D | — | Wikipedia/campaign | -400103 |
| 4 | Mary Peltola | AK | D | Former U.S. Rep AK | CDN bioguide | -400104 |
| 5 | Hallie Shoffner | AR | D | Rice farmer | Campaign site | -400105 |
| 6 | Janak Joshi | CO | R | Former CO state Rep | Wikipedia/LinkedIn | -400106 |
| 7 | Alex Vindman | FL | D | Retired Lt. Col., Army | Wikipedia | -400107 |
| 8 | Angie Nixon | FL | D | Florida state Rep | FL legislature portrait | -400108 |
| 9 | Mike Collins | GA | R | U.S. Rep GA-10 | CDN bioguide | -400109 |
| 10 | Derek Dooley | GA | R | Football coach, attorney | Wikipedia | -400110 |
| 11 | David Roth | ID | D | — | Wikipedia/campaign | -400111 |
| 12 | Juliana Stratton | IL | D | Illinois Lt. Governor | Official state portrait | -400112 |
| 13 | Don Tracy | IL | R | Former IL GOP Chair | Wikipedia | -400113 |
| 14 | Ashley Hinson | IA | R | U.S. Rep IA-02 | CDN bioguide | -400114 |
| 15 | Zach Wahls | IA | D | Iowa state Senator | IA legislature portrait | -400115 |
| 16 | Charles Booker | KY | D | 2022 KY Senate D nominee | Wikipedia/campaign | -400116 |
| 17 | Andy Barr | KY | R | U.S. Rep KY-06 | CDN bioguide | -400117 |
| 18 | Julia Letlow | LA | R | U.S. Rep LA-05 | CDN bioguide | -400118 |
| 19 | John Fleming | LA | R | Former U.S. Rep LA-04 | CDN bioguide | -400119 |
| 20 | Graham Platner | ME | D | Harbor master | Campaign website | -400120 |
| 21 | Seth Moulton | MA | D | U.S. Rep MA-06 | CDN bioguide | -400121 |
| 22 | Abdul El-Sayed | MI | D | Public health admin | Wikipedia | -400122 |
| 23 | Mallory McMorrow | MI | D | Michigan state Senator | MI legislature portrait | -400123 |
| 24 | Haley Stevens | MI | D | U.S. Rep MI-11 | CDN bioguide | -400124 |
| 25 | Mike Rogers | MI | R | Former U.S. Rep MI-08 | CDN bioguide | -400125 |
| 26 | Peggy Flanagan | MN | D | MN Lt. Governor | Official state portrait | -400126 |
| 27 | Angie Craig | MN | D | U.S. Rep MN-02 | CDN bioguide | -400127 |
| 28 | Royce White | MN | R | Former NBA player | Wikipedia | -400128 |
| 29 | Scott Colom | MS | D | Lowndes Co. DA | Wikipedia/campaign | -400129 |
| 30 | Kurt Alme | MT | R | U.S. Attorney (MT) | DOJ/USDOJ portrait | -400130 |
| 31 | Seth Bodnar | MT | I | Former Univ. of Montana president | Wikipedia | -400131 |
| 32 | Dan Osborn | NE | I | Former union leader | Wikipedia/campaign | -400132 |
| 33 | Chris Pappas | NH | D | U.S. Rep NH-01 | CDN bioguide | -400133 |
| 34 | John Sununu | NH | R | Former U.S. Senator (NH) | CDN bioguide (former senator) | -400134 |
| 35 | Roy Cooper | NC | D | Former NC Governor | Wikipedia/official | -400135 |
| 36 | Michael Whatley | NC | R | Former RNC Chair | Wikipedia | -400136 |
| 37 | Sherrod Brown | OH | D | Former U.S. Senator (OH) | CDN bioguide — CHECK FOR EXISTING RECORD FIRST | -400137 |
| 38 | Kevin Hern | OK | R | U.S. Rep OK-01 | CDN bioguide | -400138 |
| 39 | David Brock Smith | OR | R | Oregon state Senator | OR legislature portrait | -400139 |
| 40 | Annie Andrews | SC | D | Pediatrician | Wikipedia/campaign | -400140 |
| 41 | Rachel Fetty Anderson | WV | D | Morgantown City Councilwoman | Wikipedia/campaign | -400141 |
| 42 | Harriet Hageman | WY | R | U.S. Rep WY-at-large | CDN bioguide | -400142 |
| 43 | James Byrd | WY | D | Former WY state Rep | Wikipedia/campaign | -400143 |

**Secondary candidates (lower priority, include if time/resources allow):**
- AL: Jim Carlin (R, IA primary challenger to Hinson) — not in above list, IA not AL; Carlin is in IA
- CO: Mark Baisley (R) — Colorado state Senator
- FL: Neelam Taneja Perry, Chris Gleason (minor R challengers to Moody)
- MN: Michele Tafoya (R), David Hann (R)
- NH: Scott Brown (R) — former senator, has CDN photo

**Total primary candidates: 43 (external_ids -400101 through -400143)**

---

## Architecture Patterns

### Migration Structure

Two options for plan structure:

**Option A: Single plan (recommended for 1-2 plans expected)**
- Plan 01: Migration 196 — all 43 candidate politician + office rows + photo UPDATEs
- All candidates inserted idempotently (ON CONFLICT DO NOTHING)
- Photo UPDATEs guarded with IS NULL OR = ''

**Option B: Two plans**
- Plan 01: Migration 196 — Part 1 (AL-MN, candidates 1-28)
- Plan 02: Migration 197 — Part 2 (MS-WY, candidates 29-43) + all photo UPDATEs

Given ~43 candidates, a single migration is manageable. Recommend Option A.

### Key SQL Invariants (from prior migrations)

1. Chamber UUID for U.S. Senate: `'7cbe07bc-84b8-433b-952b-540e7de18a92'`
2. NATIONAL_UPPER district join: `WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = '[STATE]'`
3. office_title for candidates: `'Candidate for U.S. Senate — [STATE_FULL_NAME]'` — must match phase spec pattern
4. `ON CONFLICT (external_id) DO NOTHING` on all politician INSERTs
5. `NOT EXISTS (SELECT 1 FROM essentials.offices WHERE district_id = d.id AND politician_id = p.id)` guard on office INSERTs
6. `AND (photo_origin_url IS NULL OR photo_origin_url = '')` on all photo UPDATEs

### office_title Verification

The `office_title` field — verify it is on `essentials.politicians` (not `essentials.offices`). Based on migration 175 patterns, politicians have `office_title` as a separate UPDATE step, or it may be a generated/computed column. The success criteria query uses `WHERE office_title LIKE 'Candidate for U.S. Senate%'` which implies it's on `essentials.politicians`.

---

## Common Pitfalls

### Pitfall 1: Duplicate Records for Sherrod Brown

Brown served as a senator and lost his 2024 re-election. If he was ever entered into `essentials.politicians` for any prior reason, creating a second record will cause confusion. Always run `SELECT * FROM essentials.politicians WHERE full_name ILIKE '%sherrod%brown%'` before inserting.

**How to avoid:** Add a pre-check comment in migration 196 to query for Brown before his INSERT block.

### Pitfall 2: Wrong Chamber UUID

The chamber UUID `7cbe07bc-84b8-433b-952b-540e7de18a92` must be correct. Verify by checking an existing senator's office row before writing migration.

### Pitfall 3: Jon Husted and Alan Armstrong Already in DB

Both are in the DB from migration 176 as senator/appointee records. Do NOT create new records for them. For OH, Sherrod Brown is the non-incumbent to add. For OK, Kevin Hern (and potentially Jim Priest) are the non-incumbents.

### Pitfall 4: CDN Photo Verification

Bioguide IDs must be HEAD-verified before committing to migration SQL. H001102 for Hyde-Smith returned 404 — correct was H001079. Pattern: curl HEAD check each CDN URL before writing.

### Pitfall 5: office_title State Name Format

Use full state name, not abbreviation: "Candidate for U.S. Senate — Georgia" not "Candidate for U.S. Senate — GA". Verify by checking how sitting senator office_title was stored (may be on `essentials.politicians.office_title` or derived from `essentials.offices.title` + `representing_state`).

### Pitfall 6: Migration Number Drift

The phase spec says "Next migration: 177" but the actual filesystem shows 195 as the last. Always run `ls backend/migrations/ | sort -V | tail -5` before writing a new migration file to get the current actual number.

### Pitfall 7: Runoff vs. Nominated

As of May 21, 2026 (today):
- AL R: Marshall vs. Moore runoff June 16 — nominee NOT yet determined
- GA R: Collins vs. Dooley runoff June 16 — nominee NOT yet determined
- LA R: Letlow vs. Fleming runoff June 27 — nominee NOT yet determined
- LA D: Crockett vs. Davis runoff June 27 — nominee NOT yet determined

For the migration, include BOTH runoff candidates for each of these states. We want records for all major declared candidates regardless of whether they've clinched the nomination yet. The `is_current = false` flag is correct for all of them.

---

## State of the Art

| Pattern | Senators (Phase 73) | Candidates (Phase 75) |
|---------|--------------------|-----------------------|
| external_id range | -400001 to -400090 | -400101 to -400200 |
| is_current | true | false |
| is_incumbent | true | false |
| is_appointed | false (or true for Husted/Armstrong) | false |
| office_title | 'U.S. Senator — [State]' | 'Candidate for U.S. Senate — [State]' |
| photo source | GitHub CDN primary | GitHub CDN (if former/current House member) else Wikipedia |
| office.title | 'Senator' | 'Candidate' |

---

## Sources

### Primary (HIGH confidence)

- [U.S. Senate Class II official list](https://www.senate.gov/senators/Class_II.htm) — authoritative list of all 33 Class 2 seats
- Wikipedia 2026 United States Senate elections — comprehensive race-by-race data with primary results
- NBC News primary results pages — confirmed primary winners for AR, IL, KY, LA, MS, NC, OR, WV (all completed May 2026)
- NCSL 2026 primary calendar — authoritative primary dates by state

### Secondary (MEDIUM confidence)

- Ballotpedia individual state Senate race pages — candidate lists, primary structures
- Roll Call 2026 primary calendar — cross-checked against NCSL

### Tertiary (LOW confidence — for candidate-level details)

- WebSearch results for individual races — cross-referenced across multiple outlets but not directly verified against FEC filings

---

## Metadata

**Confidence breakdown:**
- Race catalog (states, incumbents, primary dates, status): HIGH — senate.gov + Wikipedia + NCSL
- Candidate lists for competitive races: HIGH — multiple outlets converge (NC, MI, GA, IA all confirmed)
- Candidate lists for safe seats: MEDIUM — less coverage; minor D candidates in safe-R states may be incomplete
- Photo strategy: HIGH — based on existing project patterns from migrations 175/176
- External ID range: HIGH — derived from migration audit
- Migration number (196): HIGH — verified against filesystem

**Research date:** 2026-05-21
**Valid until:** 2026-09-15 (general election candidate set solidifies after September primaries close; primaries are still ongoing as of research date)
