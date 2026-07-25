# Bend, OR deep seed — roster + ballot research (compiled 2026-07-24)

All rosters verified against official `.gov` / district sources. Secondary sources used only
where noted (position-number mapping, election results).

## 1. City of Bend — `City of Bend, Oregon, US`, place FIPS `4105800`
6 councilors + directly-elected Mayor, **all at-large** (no wards), 4-year staggered terms.
Source: https://bendoregon.gov/city-council/ and https://bendoregon.gov/city-council/elections/
("The Bend City Council is comprised of six council members and a Mayor… All positions are
elected at-large and are not tied to any specific geographic areas.")

| Pos | Name | Role | Term | Email | Phone |
|-----|------|------|------|-------|-------|
| 1 | Megan Norris | Councilor | Jan 2025 – Jan 2029 | mnorris@bendoregon.gov | 541-647-8413 |
| 2 | Gina Franzosa | Councilor | Jan 2025 – Jan 2029 | gfranzosa@bendoregon.gov | 541-749-7319 |
| 3 | Megan Perkins | Councilor, **Mayor Pro Tem** | Jan 2025 – Jan 2029 | mperkins@bendoregon.gov | 541-749-7619 |
| 4 | Steve Platt | Councilor | Jan 2025 – Jan 2029 | splatt@bendoregon.gov | 541-749-0336 |
| 5 | Ariel Méndez | Councilor | Jan 2023 – Jan 2027 | amendez@bendoregon.gov | 541-408-1518 |
| 6 | Mike Riley | Councilor | Jan 2023 – Jan 2027 | mriley@bendoregon.gov | 541-749-0638 |
| 7 | Melanie Kebler | **Mayor** | Jan 2023 – Jan 2027 | mkebler@bendoregon.gov | 541-749-0917 |

Position→person mapping for seats 1–4 is not printed on the current city site. Corroborated by
two independent sources: KTVZ "Meet your 2025 Bend City Council members" (2025-01-08) and the
Nov 2024 results (Norris P1 def. Jonathan A. Curtis 73.0%; Franzosa P2 unopposed; Platt P4
58.3% over Wamboldt/Campbell). Seats 5/6/7 are confirmed directly by the city elections page.

Bio pages (official portraits live here): `https://bendoregon.gov/city-council/<first-last>/`
e.g. `.../megan-perkins/` → `/wp-content/uploads/2025/12/megan-perkins-medium.jpeg`.

Compensation (for `offices.salary`): councilors $30,000/yr stipend; Mayor $50,000/yr.

## 2. Deschutes County — `Deschutes County, Oregon, US`, FIPS `41017`
Board of County Commissioners = 3 members, **elected at large**, 4-year terms. All county
offices are **nonpartisan** (May majority-or-runoff). Chair rotates.
Source: https://www.deschutescounty.gov/275/Board-of-County-Commissioners

| Pos | Name | Role | Term expires |
|-----|------|------|--------------|
| 1 | Anthony (Tony) DeBone | Vice Chair | January 2027 |
| 2 | Phil Chang | **Chair** | January 2029 |
| 3 | Patti Adair | Commissioner | January 2027 |

Voters approved expansion to **5 commissioners effective with the 2026 election** (new
Positions 4 and 5; the two new seats get initial 2-year terms).

Elected countywide row officers:

| Office | Holder | Basis | Term expires |
|--------|--------|-------|--------------|
| Clerk | Steve Dennison | appointed 2021-08-01, elected Nov 2022 | January 2027 |
| Assessor | Scot Langton | in office since 2001; **retiring**, not seeking re-election | January 2027 |
| Treasurer | Bill Kuhn | elected Nov 2022 | January 2027 |
| Sheriff | Ty Rupert | **appointed interim** 2025-07-29, effective Aug 1 2025 | January 2027 |

- Treasurer name confirmed on the county's own "Investment Portfolio May 2026" PDF
  (`DocumentCenter/View/7122`) signature line: "Bill Kuhn, Treasurer". Treasury page states the
  function "is managed by the elected County Treasurer".
- Sheriff: Kent van der Kamp (elected Nov 2024) resigned effective 2025-07-31 after a
  dishonesty investigation; DPSST moved to revoke his certification. Capt. Ty Rupert was
  appointed interim to serve Aug 1 2025 → Jan 2027. **Seed Rupert with `is_appointed = true`.**
- District Attorney is a **state** office in Oregon (files with SOS) → out of county scope.

## 3. Bend-La Pine Schools — `Bend-La Pine Administrative School District 1`
Census/TIGER unified school district GEOID **`4101980`** (MTFCC G5420), confirmed via TIGERweb
School/MapServer layer 0. 7 directors, 4-year terms, elected district-wide but each must reside
in a zone. Elections are May of **odd** years → **no 2026 race**.
Source: https://www.blschools.org/board-and-policy/school-board (Meet the Board Members panel)

| Zone | Name | Role |
|------|------|------|
| 1 | Jenn Lynch | Director |
| 2 | Marcus LeGrand | Director |
| 3 | Cameron Fischer | **Vice Chair** |
| 4 | Shirley Olson | Director |
| 5 | Amy Tatom | **Chair** |
| 6 | Ross Tomlin | Director |
| 7 | Kina Chadwick | Director |

## 4. Bend Park & Recreation District (BPRD)
Five-member elected Board of Directors, 4-year terms, ORS ch. 198 & 266. Special-district
elections are May of **odd** years; terms run to June 30. → **no 2026 race**.
Source: https://www.bendparksandrec.org/about/board-of-directors/

| Name | Role | Term through |
|------|------|--------------|
| Cary Schneider | **Chair** | 2029-06-30 |
| Deb Schoen | **Vice-Chair** | 2029-06-30 |
| Nathan Hovekamp | Director & Legislative Liaison | 2029-06-30 |
| Jodie Schiffman | Director (appointed Jan 2023) | 2027-06-30 |
| Donna Owens | Director (appointed Jan 2023) | 2027-06-30 |

CAVEATS: (a) the page's per-member "Contact:" blurbs carry stale role labels (Schneider is
labeled Vice-Chair and Owens Chair in the contact block while the headings say Schneider=Chair,
Schoen=Vice-Chair) — **the headings are used**; (b) BPRD board seats are numbered 1–5 on the
ballot but the site does not publish the number→member mapping, so offices are titled
"Director" with Chair/Vice-Chair annotations rather than "Position N"; (c) the Schiffman photo's
`alt` text reads "Jodie Barram" — do not trust alt text for the correct-person guard.

## 5. November 3, 2026 general election — a Bend voter's ballot
City filing: opened Jun 3; **closes Aug 18 (elected incumbents) / Aug 25 (all others);
withdrawal deadline Aug 28**. Field below is as of 2026-07-24 and is **NOT final**.

### City of Bend (nonpartisan, at-large) — https://bendoregon.gov/city-council/elections/
| Race | Filed candidates (status: Qualified / Approved to Circulate) |
|------|--------------|
| Councilor Position 5 | Ariel Méndez (incumbent) |
| Councilor Position 6 | Bobbi Cummiskey; Elana Reinholtz; Dan Sorrells — **incumbent Mike Riley has NOT filed** |
| Mayor (Position 7) | Melanie Kebler (incumbent); Ron (Rondo) Boozell |

SEL-101 filing PDFs: `bendoregon.gov/wp-content/uploads/2026/06/{Mendez,Cummisky,Reinholtz,Sorrells,Kebler}_SEL-101_Redacted*.pdf`, `.../2026/07/Ron-Boozell_SEL-101.pdf`.

### Deschutes County (nonpartisan) — https://www.deschutescounty.gov/1593/November-3-2026-General-Election
| Race | Candidates |
|------|-----------|
| Commissioner Position 3 (4-yr) | Lauren Connally; Amy Sabbadini — **open seat**, Adair not seeking |
| Commissioner Position 5 (new, 2-yr) | Rob Imhoff; Morgan Schmidt |
| County Clerk (4-yr) | Jonathan Curtis; Steve Dennison (incumbent) |
| County Sheriff (4-yr) | James (Mac) McLaughlin; Ty Rupert (appointed incumbent) |
| County Treasurer (4-yr) | Robert Tintle (unopposed; incumbent Kuhn not running) |

Decided in the May 19 2026 primary (majority winners, sworn in Jan 2027 — **not** Nov races):
Commissioner Position 1 → **Jamie Collins** (55%, def. DeBone 38%, Brooke West 7%);
Commissioner Position 4 (new, 2-yr) → Rick Russell vs Chet Wamboldt; Assessor → Zachary J
Hastings vs Tana West. Clerk/Sheriff/Treasurer moved to the general because fewer than three
candidates filed.

### State / federal (races already exist in `essentials.races`)
| Race | Candidates | DB status |
|------|-----------|-----------|
| OR State House District 53 (N/NE/NW Bend, Redmond, Sisters) | Emerson Levy (D, inc); Michael Summers (R) | race row exists, **0 candidates → fill** |
| OR State House District 54 (downtown/S/SE/SW Bend) | Jason Kropf (D, inc) — unopposed | race row exists, **0 candidates → fill** |
| U.S. House OR-05 | Janelle Bynum (D, inc); Patti Adair (R) | already seeded ✅ |
| U.S. Senate Oregon | Jeff Merkley (D, inc); David Brock Smith (R) | already seeded ✅ |
| Governor of Oregon | Tina Kotek (D, inc); Christine Drazan (R) | already seeded ✅ |

**DATA DEFECT FOUND (pre-existing, not Bend-specific):** `essentials.races` contains a
2026-11-03 row for **all 30** OR State Senate districts, but Oregon elects only half its Senate
each cycle. SD 27 (Bend) was last elected Nov 2024 — Anthony Broadman's term runs to Jan 2029,
so **SD 27 is not on the 2026 ballot**. Do NOT seed SD-27 candidates. Logged as a follow-up.

## 6. Geography already present in the DB (no TIGER import needed)
- `geofence_boundaries` `4105800` (G4110, "Bend city") ✅ exists
- `geofence_boundaries` `41017` (G4020, "Deschutes County") ✅ exists
- `districts` row for Deschutes County exists (`fcd18e4b-2ed0-43c2-93e6-535671c4ef56`,
  COUNTY/G4020) with `government_id = NULL` and 0 offices → attach the new government to it
- **No** district row at `4105800` → create LOCAL + LOCAL_EXEC districts (Tigard pattern)
- **Missing:** G5420 boundary for `4101980` (Bend-La Pine) and any BPRD boundary

TRAP: `geo_id` `41017` is also used by OR "State House District 17" (G5220) and "State Senate
District 17" (G5210) district rows, and `41027` collides with Hood River County. Every district
lookup here must be scoped by `mtfcc` + `district_type`, never `geo_id` alone.

Bend spans **HD 53** (north/NE/NW) and **HD 54** (downtown/S/SE/SW); all of it is in **SD 27**
and **OR-05** (verified with ST_Covers against five Bend sample points).
