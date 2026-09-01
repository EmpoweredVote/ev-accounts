# Columbus + Muscogee County — verified roster (GA-4)

**Program tracker:** [`.planning/knight-foundation/PROGRAM.md`](../../../.planning/knight-foundation/PROGRAM.md) ·
**State notes:** [`.planning/knight-foundation/ga.md`](../../../.planning/knight-foundation/ga.md)

Measured 2026-09-01. **16 offices, 16 people, 0 vacancies** — 11 city, 5 county.
Columbus is the program's **first consolidated city-county**: ONE government, and stage 4 drops the
county commission because the Council already is it.

---

## Sources

| # | Body | Source | Endpoint | What it is |
| --- | --- | --- | --- | --- |
| A | city | **Columbus Consolidated Government charter** | `resources.columbusga.gov/mayor/pdfs/city_charter.pdf` | **the structural authority.** Sec. 3-100, 3-103, **4-201**, 6-101, Art. VIII |
| B | city | Columbus Council roster | `columbusga.gov/council/` + ten `/council/District-N` pages | the city's own roster, 10 members with districts |
| C | city + county | **Georgia Secretary of State, certified results** | `results.sos.ga.gov/results/public/api/elections/muscogee-county-ga/{id}/data` | certified. **Covers Columbus municipal contests ONLY from 2026** — see defect 1 |
| D | city | Columbus GIS `Elections/Districts` layer **10** "Council Districts" | `ccggisprod.columbusga.org/server/rest/services/Elections/Districts/MapServer/10` | current ROSTER, **superseded GEOMETRY** — see defect 2 |
| E | city | Columbus GIS `Elections/Districts` layer **3** "Council/School Board Districts" | `.../MapServer/3` | **operative GEOMETRY**, stale roster — see defect 2 |
| F | city | Columbus GIS `Elections/Districts` layer **8** "Elections Combinations" | `.../MapServer/8` | **the arbiter.** The precinct x district table the county builds ballots from |
| G | city | WTVM, 2026-05-26 and 2026-05-27 | `wtvm.com/2026/05/27/simi-barnes-sworn-columbus-city-council/` | Barnes' swearing-in, previewed and reported |
| H | city | WRBL / Courier News, July 2026 | `wrbl.com/news/georgia-news/cathy-cook-sworn-in-as-newest-columbus-city-councilor/` | Cook sworn in **2026-07-14** |
| I | city | Ledger-Enquirer / Yahoo, 2025 | "Longtime Columbus City Councilor Judy Thomas resigns" | the D9 vacancy and Anker's appointment, 6-3, over the Mayor's objection |
| J | county | Muscogee County Sheriff's Office | `columbusga.gov/sheriff/About-the-Office/Sheriff-Countryman` | the Sheriff's own office |

Payloads are on disk in this directory, untracked.

---

## 🔴 Source defects found

### 1. 🔴🔴 The SOS certified-results API covers Columbus municipal contests ONLY from 2026

GA-3's handoff said to try this API first, because it settled **all 18** Milledgeville seats. It works
for Muscogee — but it is **incomplete here, and silently so**.

| Election | Columbus municipal contests present? |
| --- | --- |
| 2018 General Primary (`2018GenPri`), 2018 General | **none** |
| 2020 General | **none** |
| 2022 General Primary, 2022 General | **none** |
| 2024 General Primary, 2024 General | **none** |
| **2026 General Primary (`GeneralPrimary51926`)** | **Mayor, Council 1/3/5/7/9, + 2 SPECIALS** |
| **2026 General Primary Runoff (`06162026GeneralPrimaryRunoff`)** | Mayor, Council 7, Council 9, Special Council 9 |

The charter (Sec. 6-101(3)) puts Mayor + Districts 1, 3, 5, 7 + Post 9 on the **2022** ballot and
Districts 2, 4, 6, 8 + Post 10 on the **2024** ballot. Both are absent from the portal. Every ballot
item in both 2022 payloads was listed by hand to be sure the contests were not merely named oddly.

⚠ **So the portal cannot seat the even-numbered districts at all.** A wave that inherited Baldwin's
experience would have concluded those five seats were vacant or non-existent. They are neither.
The **charter plus source B** carry them.

🟢 The jurisdiction endpoint `.../api/jurisdictions/muscogee-county-ga` lists **all 36 elections back
to 2012** with their `publicElectionId` slugs. Use it; do not guess slugs. A guessed slug returns
**HTTP 204**, which is indistinguishable from "this election had no such contest".

### 2. 🔴🔴🔴 TWO council-district layers. The one with the CURRENT ROSTER has the WRONG GEOMETRY.

The service publishes both `[10] Council Districts` and `[3] Council/School Board Districts`. Both
return exactly 8 polygons. They are **different maps**, not two digitisations of one:

| District | layer 3 sq mi | layer 10 sq mi | symmetric difference |
| --- | --- | --- | --- |
| 1 | 9.3133 | 9.7065 | 0.394 |
| 2 | 41.9732 | 41.1184 | 1.587 |
| 3 | 7.8994 | 8.4781 | 0.894 |
| 4 | 9.9978 | 9.8638 | 0.136 |
| 5 | 9.4093 | 10.0783 | 2.493 |
| 6 | 47.2617 | 45.6025 | 1.747 |
| 7 | 12.0524 | 12.8354 | 1.358 |
| **8** | 8.3326 | 8.8785 | **3.639 — 41% of the district** |

**The arbiter is source F**, the county's own `Elections Combinations` layer: the precinct x district
table it builds ballots from. Dissolved by `COUNCIL_SCHOOL` and compared district by district:

| | vs layer 3 | vs layer 10 |
| --- | --- | --- |
| symmetric difference, **all 8 districts** | **0.000 sq mi** | 0.136 – 3.639 sq mi |

**Layer 3 is the operative map.** Layer 10 is not, on any district.

But layer 3's roster attribute names **`BYRON HICKEY`** in District 1 — the *appointed* predecessor,
gone since May 2026 — while layer 10 names **`SIMI BARNES`**, who actually holds the seat.

> 🔴🔴 **THE LAYER WITH THE FRESH ROSTER HAS THE SUPERSEDED GEOMETRY, AND THE LAYER WITH THE
> OPERATIVE GEOMETRY HAS THE STALE ROSTER. They point in OPPOSITE directions.** Taking either layer
> for both answers gets one of them wrong. Layer 10 is the trap: it is named more precisely, it is
> listed second, and its roster is right — and every one of its boundaries is wrong.
>
> GA-3 learned that geometry vintage and attribute vintage are different questions about one row.
> Here they do not merely differ, they **invert**. Geometry comes from F-validated **layer 3**;
> the roster comes from **B and C**, never from a GIS attribute.

⚠ Layer 3's *school board* names (`REPNAME2`) include **Mark Cantrell** and **Margot Schley**, who
won in **2026** — so within one row set, the school-board field is fresh while the council field is
stale. Freshness is not a property of a layer, nor even of a row. Read it per field.

### 3. 🔴 The eight districts deliberately do NOT tile the county, and that is correct

Columbus city (`1319000`) and Muscogee County (`13215`) are the same 221.011 sq mi ground. The eight
council districts cover **146.24**, leaving **74.79 sq mi — 33.8% of the county — in no district.**

That is not a defect and not a hole in the map:

- The gap is **one contiguous piece** (74.458 sq mi) plus 52 slivers of <= 0.002 sq mi, which are
  digitisation noise between two layers of one service.
- Source F carries **5 rows reading `Precinct N/A; ... Council & School Board N/A`**, totalling
  **74.767 sq mi**. Their symmetric difference against the council-district gap is **0.770 sq mi**.
- So **the county itself records that ground as belonging to no precinct and no council district.**
  It is the Fort Benning military reservation. State House and Senate districts do cover it.

▶ This is FL-5's "155.54 sq mi of `12099` is the Atlantic" in a new dress — but here the excluded
ground is **land**, and the authority is not geography, it is **the county's own ballot-building
record**. The tiling gate must therefore assert *this structure*, not full coverage: 8 districts, no
overlaps, and a gap that equals the `N/A` combination area within tolerance.

### 4. 🔴 `gis.columbus.gov` is COLUMBUS, OHIO

A search for Columbus council-district geometry surfaces
`gis.columbus.gov/arcgis/rest/services/Applications/Redistricting/MapServer` — a different city in a
different state, with a plausible service name and a live Redistricting layer. Georgia's is
`ccggisprod.columbusga.org`. The FEC-homonym class, in GIS clothing.

---

## Charter rulings

### R1 — Council is 8 districts + 2 at-large, and Posts 9 and 10 are NOT geographic

Sec. 3-100(2): *"The council shall consist of ten (10) members."* Sec. 3-100(3): after the 1994 and
1996 elections *"the council shall have eight (8) district councilors and two (2) councilors at
large"*, the at-large members being **Post 9** and **Post 10**.

Both GIS layers return **8** polygons, not 10 — an independent confirmation that Posts 9 and 10 have
no geometry. ⚠ The city's own roster page numbers all ten as "District N" with no at-large label, so
**the page alone would have produced two districts that do not exist.** The SOS ballot names the seat
`Council - District 9 - At Large`, which is the tell.

Posts 9 and 10 hang on the **citywide** district, like Tallahassee's at-large commission.

### R2 — The Mayor is `non_voting` with a required note

Sec. **4-201** lists the Mayor's powers (🔴 **corrected 2026-09-01 — this said 4-102, which is
“General provisions concerning departments” and says nothing about the Mayor; the note is voter-facing,
so the wrong number would have shipped**): *"To preside at all meetings of the Council and to have a voice
in its proceedings"* and *"To have the right to vote only in the case of a tie, and for such purpose
only to be deemed [a member]"*.

Quorum is **six of the ten Council members** (Sec. 3-103(3)), which counts the Mayor out of the body.
So the Mayor presides, speaks, and votes only to break ties. That is the **Nashville Vice Mayor**
ruling exactly: `voting_powers = 'non_voting'` plus a `representation_note` stating the tie-breaking
vote. The note is required by CHECK and both read paths must render it.

### R3 — Mayor Pro Tem is a parenthetical, not an office

Sec. 3-103(1): the Council *"shall elect by six (6) votes one (1) of its members as mayor pro tem to
serve until the next organizational meeting."* Elected by the body from its own membership, annually.
**Baldwin R2 and the Lawrence County ruling: a rotating role is a parenthetical on the seat title,
never its own office.** The post-verify gate refuses any office titled with it.

### R4 — FIVE county officers. ⏸ TWO MORE ARE A DECISION FOR CANTRELL.

Charter **Article VIII, Chapter 1 "County Officers and Agencies"** preserves exactly four offices
through consolidation: **Sec. 8-100 Sheriff, 8-101 Judge of Probate Court, 8-102 Tax Commissioner,
8-103 Coroner.** The **Clerk of Superior Court** is not in Article VIII because it does not need to
be — it is a county officer named in **Ga. Const. Art. IX, Sec. I, Par. III**, attached to a state
court, and consolidation cannot reach it. It appears on the certified 2024 ballot.

**Seated (5):** Sheriff · Clerk of Superior Court · Judge of Probate Court · Tax Commissioner · Coroner

**Excluded, each for a stated reason:**

| Excluded | Why |
| --- | --- |
| Solicitor General | a prosecutor — the FL-5 rule against Palm Beach's State Attorney, and Baldwin's |
| District Attorney, Chattahoochee Judicial Circuit | **MULTI-COUNTY** circuit — the FL-5 ruling exactly |
| Pine Mountain Soil and Water Conservation District Supervisor | spec §11 |
| Muscogee County School Board | spec §11 |
| Clerk of Council | appointed by the Council, Sec. 3-103(1) — not elected |
| Marshal, Surveyor | **Muscogee elects neither.** Absent from every certified ballot examined |

✅ **RULED 2026-09-01 (Cantrell): EXCLUDE BOTH.** Muscogee elects **Municipal Court Clerk** (Reginald
Thompson) and **Municipal Court Judge** (Steven D. Smith) countywide, both on the certified 2024
ballot. Neither is seated.

The line is the constitution's, not ours. Baldwin excluded the Chief Magistrate as judicial-branch
under **Ga. Const. Art. VI**, and a municipal court is an Art. VI court. The Clerk of Superior Court is
seated *because* **Art. IX, Sec. I, Par. III** names it a county officer; the Municipal Court Clerk is
not in that list. Seating the clerk of a court whose judge is excluded would also be incoherent.

⚠ The argument the other way was real and was heard: both are offices Muscogee voters genuinely elect
countywide. It is recorded here rather than dropped, because the next consolidated city-county will
raise it again — Macon-Bibb at GA-5, then Philadelphia and Lexington.

**The wave is 16 offices.** The identity sub-range stays `-1331020 .. -1331035`.

---

## The roster

### City — Columbus Consolidated Government (11)

| Seat | Holder | how_started | term_start | precision | Source |
| --- | --- | --- | --- | --- | --- |
| Mayor | B.H. "Skip" Henderson III | elected | — | `unknown` | B |
| Council, District 1 | Simi Barnes | `elected` (**special**) | **2026-05-26** | **`day`** | C, G |
| Council, District 2 | Glenn Davis | elected | — | `unknown` | B, D |
| Council, District 3 | Bruce Huff | elected | — | `unknown` | B, D, E |
| Council, District 4 | Toyia Tucker | elected | — | `unknown` | B, D, E |
| Council, District 5 | Charmaine Crabb | elected | — | `unknown` | B, C, D, E |
| Council, District 6 | Gary Allen | elected | — | `unknown` | B, D, E |
| Council, District 7 | JoAnne Cogle | elected | — | `unknown` | B, D, E |
| Council, District 8 | Walker Garrett | elected | — | `unknown` | B, D, E |
| Council, Post 9 (At Large) | Cathy Cook | `elected` (**special**) | **2026-07-14** | **`day`** | C, H |
| Council, Post 10 (At Large) | Travis L. Chambers | elected | — | `unknown` | B |

### County officers — Muscogee County (5)

| Seat | Holder | how_started | term_start | precision | Source |
| --- | --- | --- | --- | --- | --- |
| Sheriff | Greg Countryman, Sr. | elected | — | `unknown` | C, J |
| Clerk of Superior Court | Danielle F. Forte | elected | — | `unknown` | C |
| Judge of Probate Court | Marc D'Antonio | elected | — | `unknown` | C |
| Tax Commissioner | David Britt | elected | **2025-01-01** | **`month`** | C + press |
| Coroner | Buddy Bryan | elected | — | `unknown` | C |

🔴 **Columbus publishes no service-start**, exactly as the General Assembly does not (GA-2). The ten
councilor pages carry name, phone, email and address, and one bio; not one carries an election year.
So `term_start` is open-ended at `'unknown'` for everyone whose occupancy predates 2026 — the NC and
GA-2 pattern. **Do not derive a start from the charter's January commencement**: that is the start of
the current TERM, and re-election does not end an occupancy.

The three exceptions are sourced, not inferred:
- **Barnes 2026-05-26** — WTVM previewed the swearing-in on 05-26 and reported it on 05-27 as having
  happened "Tuesday". 2026-05-19 was a Tuesday; one week later is 2026-05-26.
- **Cook 2026-07-14** — stated as a date in the report, not computed.
- **Britt 2025-01-01, `month` precision** — he was unopposed in 2024 to succeed Lula Huff, who did not
  seek re-election, and took office when her term expired at the end of 2024. The **month** is
  sourced; the day is not, so precision is `month`, not `day`.

---

## 🔴 The two 2026 special elections, and why five seats did NOT change hands

This is the trap this wave turned on. **Columbus elected a new Mayor and five councilors in 2026, and
four of those six people do not hold the office yet.**

Sec. 3-100(2): terms commence *"within seven (7) days following the first Monday in January next
following their election"*, except that **"a councilor selected to fill a vacancy shall serve only for
the remainder of the unexpired term."**

So the May/June 2026 winners of the **regular** contests take office in **January 2027**. The winners
of the two **special** contests took office **immediately**, because they fill unexpired terms.

| Contest | Winner | Certified | Seated |
| --- | --- | --- | --- |
| Mayor (regular) | Isaiah Hugley, Sr. — 51.57% runoff | 2026-06-16 | **January 2027** — *not seated* |
| Council D3 (regular) | Sherrie Aaron — 56.23% outright | 2026-05-19 | **January 2027** — *not seated* |
| Council D5 (regular) | Charmaine Crabb — 55.33%, incumbent | 2026-05-19 | continues, already seated |
| Council D7 (regular) | Rebecca "Becca" Zajac — 57.75% runoff | 2026-06-16 | **January 2027** — *not seated* |
| Council D1 (regular) | Simi Barnes — 60.00% outright | 2026-05-19 | January 2027 |
| **Council D1 (SPECIAL)** | **Simi Barnes — 59.84% outright** | 2026-05-19 | **2026-05-26 — SEATED** |
| Council D9 (regular) | Cathy Cook — 59.90% runoff | 2026-06-16 | January 2027 |
| **Council D9 (SPECIAL)** | **Cathy Cook — 60.22% runoff** | 2026-06-16 | **2026-07-14 — SEATED** |

> 🔴🔴 **SEATING THE 2026 WINNERS WOULD HAVE PUT FOUR PEOPLE IN OFFICES THEY DO NOT HOLD** — a new
> Mayor four months early, and replacements for Huff (D3) and Cogle (D7) who are still sitting. The
> certified result is a fact about an election, **not** a fact about who holds the seat today.
> The discriminator is the *special* contest: only its winner starts early.

The two vacancies, from source I:
- **D9** — Judy Thomas, the at-large councilor since 2010, resigned for health reasons. The Council
  appointed **John Anker** 6-3 over Mayor Henderson's objection that the public could not nominate.
  Anker then lost both 2026 contests to Cathy Cook.
- **D1** — Jerry "Pops" Barnes' seat; **Byron Hickey** was appointed and did not run for a full term.
  **Simi Barnes is his daughter**, and now holds the seat her father held for nearly twenty years.

⚠ Neither current holder was appointed. **Both `how_started` values are `'elected'`** — 🔴 **corrected
2026-09-01: `'special election'` is NOT a legal value.** `essentials.office_terms` carries
`CHECK how_started IN ('elected','appointed','succeeded','redistricted','unknown')`. A special election is
an election; the *special* fact lives in the `source` string and the migration header. And
Anker and Hickey are predecessors we do not seat.

---

## Identity band

GA-3 used **`-1331001 .. -1331018`** exactly (verified in production, 18 rows). ⚠ **`-1331019` is now
taken by Steve Chapple**, Baldwin's new Coroner — see the GA-3 correction below. GA-4 therefore takes
**`-1331020 .. -1331035`** for 16 people, widening to `-1331037` if ruling R4 admits the two
municipal-court offices.

⚠ Per the FL-4 correction, the band guard must claim **only this wave's sub-range**, never the whole
shared band, or GA-4's rows break GA-3's re-run.

**Zero name collisions.** All 16 first+last pairs were checked against production. The near misses are
all different people: `David Cook` (TX), `Gary Davis`, `Gary Garrett` (UT), `David Smith` (FL),
`Gregory Smith` (OR), `David K. Thompson` (WI), `Glenn Thompson` (PA). **No `Glenn Davis`, no
`Cathy Cook`, no `David Britt` exists in production.** GA-2's lesson held: a name-based guard would
have seated a Texan and a Utahn in Georgia.

---

## 🔴🔴 A GA-3 CORRECTION FOUND BY THIS SESSION: Baldwin's Coroner retired in May

`CC_0029` seated **John Gonzalez** as Baldwin County Coroner from the Secretary of State's certified
2024 return. That return is correct and remains correct — he won that election. **He then retired
mid-term, on 2026-05-01**, and a certified result cannot report a change that postdates it.

> *"Gonzalez officially retired as coroner on May 1."*
> *"Chapple took the oath of office as the new county coroner during a special swearing-in ceremony
> Thursday morning at the county courthouse."*
> — The Union-Recorder, 2026-05-14

**Steve Chapple** holds the seat. Baldwin County's own staff directory has already dropped Gonzalez.

⚠ **This is the GA-2 SD-12 failure, and it reached production.** GA-3's change-check was run against
the *sources* rather than against the *seats*: every source agreed, and all of them predated the
retirement. A change-check has to ask "has this person left?", not "do my sources agree?".

⚠ **It was found by the headshot pass, not by a gate.** The Coroner is one of the four Baldwin
officials still owed a headshot; searching for his portrait surfaced the retirement notice. **A body's
roster is a redundancy check on occupancy** — the third time that has paid.

🟢 **A full re-check of all 18 GA-3 seats was then run against live sources, and the Coroner is the
only one.** Seven Milledgeville seats all present on the city site; five commissioners, Sheriff, Clerk,
Probate Judge, Tax Commissioner and Surveyor all present in the county directory.

✅ **`CC_0030_baldwin_coroner_succession.sql` APPLIED 2026-09-01.** The number was taken last and
re-counted against **all 84 remote refs** (`CC_0029` was the max). Dry-run first (`BEGIN … ROLLBACK`,
zero `COMMIT` in the sent stream, rollback confirmed to have reverted), then applied.

Verified in production: the Coroner seat is held by **Steve Chapple** `-1331019`; Gonzalez's term
carries `term_end 2026-05-01` and `how_ended 'retired'`; Chapple's is open-ended from `2026-05-02` at
`month` precision with `how_started 'unknown'`. The migration **re-runs clean** — the second pass
inserts 0, skips `seat_officeholder()`, and still passes its post-verify. `offices_missing_terms` is
**unchanged at 821 / 166 / 655**.

| What it writes | Value | Precision | Why |
| --- | --- | --- | --- |
| Gonzalez `term_end` | **2026-05-01** | `day` | stated outright by the source |
| Chapple `term_start` | 2026-05-02 | **`month`** | "Thursday morning" is not a date. The day is a placeholder the precision disclaims, chosen so the helper closes Gonzalez on exactly 2026-05-01 |
| Chapple `how_started` | **`unknown`** | — | the mechanism is never stated. The nearby "appointed the new coroner" sentence is about **Gonzalez** succeeding Wayne Brooks, not Chapple |
| Gonzalez `how_ended` | `retired` | — | "decided recently to retire from office" |

⚠ The inferred swearing-in date (2026-05-07 — the article ran Thursday 2026-05-14 and says "last
Thursday") is recorded **in the migration header as prose, never as data**.
