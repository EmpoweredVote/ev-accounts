# California — slice 3 notes

| Wave | Scope | Status |
| --- | --- | --- |
| CA-1 | **Long Beach + LA County** | ✅ **APPLIED 2026-09-02** — `X0046`, `CC_0053`/`CC_0054`, **13 seats** (4 citywide + 9 council), 13/13 dated, 13/13 headshots |
| CA-2 | **San José + Santa Clara County** | ✅ **ALL FIVE STAGES 2026-09-03** — `X0047`, `CC_0056` (supervisors 5/5), `CC_0059` (11/11 San José dates), stage 5 **8/8 headshots**. Santa Clara County is **8/8 seated, 8/8 dated, 8/8 portraits** |

California is the cheapest slice on paper — stages 1 and 2 are skipped, because all 80 `sldl`, 40
`sldu`, 482 `place` and 58 `county` polygons are loaded and both chambers are complete at 80/80 and
40/40. What it is not is empty. **Stage 1 was never the blocker here — occupancy was.**

Research records: [`backend/data/seed-long-beach-2026/ROSTERS.md`](../../backend/data/seed-long-beach-2026/ROSTERS.md) (CA-1)
· [`backend/data/seed-santa-clara-2026/ROSTERS.md`](../../backend/data/seed-santa-clara-2026/ROSTERS.md) (CA-2).

**Program tracker:** [`PROGRAM.md`](./PROGRAM.md) · **Spec:**
[`docs/superpowers/specs/2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md)

---

## 🔴🔴 A TRACKER BASELINE CAN BE WRONG IN BOTH DIRECTIONS, AND CALIFORNIA PROVED BOTH

- **CA-1:** the tracker said Long Beach's nine council districts were "absent". **They existed** —
  all nine sharing the TIGER place polygon `0643000`, so every address in the city returned **all
  nine councilmembers**. The fix was a repair, not a seed.
- **CA-2:** the research record's own measured table was right about what production held, but two
  of its *structural claims* did not survive re-measurement (below).

▶ **Re-measure the baseline at the start of every wave.** It has paid three times now.

The spec's §2.3 and the tracker's jurisdiction table both said:

| Jurisdiction | Tracker said | Production actually held, measured 2026-09-02 |
| --- | --- | --- |
| Long Beach | "4 citywide execs already seated; **all 9 council districts absent**" | 13 offices, 13 seated, 13 with a headshot |
| San José | "**Mayor only**; all 10 council districts absent" | 11 offices, 11 seated, 11 with a headshot |
| Los Angeles County | "3 offices, 3 seated" | **8** offices, 8 seated, 8 with a headshot |
| Santa Clara County | "3 offices, 3 seated, 0 headshots" | 3 offices, 3 seated, 0 headshots — correct |

**Re-measure before trusting a baseline.** A stale tracker line reads exactly like a finding, and a
wave that had believed this one would have created nine duplicate Long Beach council districts on top
of nine that already existed — the 1495/1496/1498 duplicate-office family, in a new city.

⚠ The Los Angeles County line was wrong for a specific, repeatable reason. See the `lower(d.state)`
note below.

---

# CA-1 — Long Beach + Los Angeles County (applied 2026-09-02)

## 🔴 `lower(d.state)` is not stylistic, and Los Angeles County is where it bites

`essentials.districts.state` is mixed case in California. Los Angeles County's **five supervisorial**
district rows carry uppercase `CA`; the **one countywide** row that holds the Assessor, District
Attorney and Sheriff carries lowercase `ca` — a leftover from migration 1635, which consolidated
three duplicate county rows and took the canonical shape from the 57 non-duplicated peers.

A first pass filtering `d.state = 'CA'` therefore reported that Los Angeles County has **no Assessor,
no District Attorney and no Sheriff**. All three exist and are correctly seated. The rule in
CLAUDE.md is load-bearing:

```sql
WHERE lower(d.state) = 'ca'
```

## Jurisdiction status

### Long Beach — ✅ CA-1 APPLIED 2026-09-02 (`CC_0053`, `CC_0054`, `X0046`)

**13 offices, 13 people, 0 vacancies.** Nine single-member council districts plus a citywide Mayor,
City Attorney, City Auditor and City Prosecutor, all four-year terms.

Two defects fixed:

1. 🔴🔴 **All nine council district rows shared the city place polygon `0643000`**, so one Long Beach
   address returned **all nine councilmembers**. Repointed onto per-district `X0046` polygons.
2. **All thirteen occupancy rows were undated** — ADR 0002 phase-2 backfill from a `cicero` vendor
   snapshot, never change-checked. Now day-precision from the city's own Legistar.

### Los Angeles County — ✅ already complete, re-verified 2026-09-02, not rewritten

All 8 elected officials (5 supervisors + Assessor, DA, Sheriff) were seated with dated terms by
migration 1635, and the county's own *Salary and Tenure Data* sheet (REV. 08/07/26) agrees row for
row. Nothing was written. Districts 1 and 3, the Sheriff and the Assessor are on the 2026 ballot and
all take office in December 2026; Hilda Solis reaches her term limit.

## 🔴 GA-4's two-layer arbitration is UNAVAILABLE in Los Angeles County, and that was measured

GA-4 established the strongest available vintage test: arbitrate two competing council-district
layers against the county's own **ballot-building** table. Neither half exists here.

- **One layer, not two.** Three ArcGIS catalogue searches return exactly one authoritative Long Beach
  service. The only other item carrying the same title is owned by `CRC.Admin` — the Citizens
  Redistricting Commission — and resolves to the **same FeatureServer URL**. The remainder are
  student copies in CSULB accounts. The GA-4 inversion (fresh roster on superseded geometry) cannot
  occur, because there is nothing to invert against.
- **The county publishes no district attributes.** `LACounty_Dynamic/Political_Boundaries/MapServer`:
  - layer **34** `Registrar Recorder Precincts` declares `DST_CITY` and `DIV_CITY` — precisely the
    ballot-building fields GA-4 arbitrated on — and **every row returns NULL for both**;
  - layer **37** `Registrar Recorder Election Precincts` carries real precinct IDs (2,853 of them)
    and **no district fields at all**;
  - the City Clerk's Statement of Votes, which maps precincts to contests, is a **scanned** PDF with
    no text layer.

**Expect the same in San José.** Check Santa Clara County's equivalent before planning CA-2's
geometry arbitration, and plan for a control set instead if it is also blank.

### What replaced it — and the difference is stated, not blurred

**2,700 active business-licence locations, 300 per district**, from the city's own daily-updated
register, each tested for containment by the loaded polygon: **2,700 of 2,700, all nine districts,
zero outside any district.**

⚠ That is a **control**, not an **arbitration**. The register's `COUNCIL_NUMBER` is plausibly derived
by the city from this same boundary layer. What it proves is that the layer is the map the city's own
operational systems route work by, across every district. It does not prove the boundaries against an
outside authority, because no outside authority publishes them. Say which one you have.

### 🔴 A district stamped on a record is a fact about WHEN THE RECORD WAS WRITTEN

The second control set — the city's development-projects layer, which carries a filing date per case
— disagreed on 8 of its 61 points. Split by era it stops being a disagreement:

| Cases filed | n | agree | disagree |
| --- | --- | --- | --- |
| after 2022-12-20 (the 2021 map took effect) | 25 | 24 | 1 |
| before | 36 | 29 | 7 |

Every one of the seven pre-map disagreements moves the way the 2021 redistricting moved — downtown
addresses stamped District 2 now sit in District 1. The single post-map outlier sits **2,083 m** from
the district it claims, and a boundary question cannot be two kilometres wide.

## 🔴 The uncovered ground is water, and the loader checks it rather than assuming it

| Measure | sq mi |
| --- | --- |
| TIGER place `0643000` total | 77.85 |
| ...of which **land** (TIGERweb) | **50.67** |
| ...of which water | 27.18 |
| Union of the nine council districts | **53.06** |
| Place area covered by no district | 24.83 |

A 24.83 sq mi hole would be alarming if it were land. It is a single contiguous piece whose
representative point sits in the outer harbour, and the districts cover 53.06 against 50.67 of land —
every acre, plus about 2.4 sq mi of harbour. The loader's gate is `union >= land area`, not a
judgement about the shape of the number.

⚠ Long Beach and San José are both coastal, and San José's ten districts union to 180.7 against a
181.06 sq mi place polygon. Do the same land/water split before reading any gap as a defect.

## 🔴🔴 California cities set their own election calendars, and the authoritative page can be STALE

Long Beach's own City Clerk still publishes an elections FAQ quoting the **pre-2020** Charter
Sec. 1901: April primary, June general, and *"candidates elected to office shall assume such office on
the third Tuesday in July."* That has not been true since 2018. The current rule — a June primary, a
November general and terms commencing on the **third Tuesday in DECEMBER** — is stated by the 2026
candidate packet, by the two 2026 Council resolutions appointing unopposed officers, and by Legistar's
own turnover dates.

> **A stale page on the authoritative site is more dangerous than a missing one.** Read for the
> calendar alone it would have dated every Long Beach term four to five months early, consistently
> enough to look right.

Take the calendar from **the current cycle's candidate packet**, never from a general FAQ.

## 🟢 Legistar is the best occupancy source found in this slice

`webapi.legistar.com/v1/longbeach/...` — no key, no WAF — publishes **day-precision** office records
with start and end dates per person per body:

```
/v1/longbeach/bodies                    list the bodies
/v1/longbeach/bodies/{id}/officeRecords  City Council = 1, City Attorney = 29, Auditor = 30, Prosecutor = 31
/v1/longbeach/persons/{id}/officeRecords the Mayor sits in his own body, reachable only this way
```

Its chains are gapless by one day, which is what makes it checkable: Burroughs ends 2006-06-30 and
Doud starts 2006-07-18; Parkin ends 2022-12-19 and McIntosh starts 2022-12-20.

**Check whether San José publishes Legistar too before hand-assembling its dates.**

Two failure modes found, both of which a single-source read would have swallowed:

- 🔴 **It dates one occupancy from the ELECTION, not the swearing-in.** Doug Haubert starts
  2010-04-13, the date of the primary he won, while his predecessor's record runs to 2010-07-19.
  Taken literally, both men held the office for three months.
- 🔴 **It stops.** No `officeRecords` row starts after **2024-12-17**, so the entire December 2024
  cohort is absent — Tunua Thrash-Ntuk has a person record and no office record.

Both were resolved from the predecessor's end date plus the charter rule plus the certified result,
and both are labelled `derived:` in the row's own `source` column.

## 🔴🔴 The change-check found a scheduled turnover, and refused to write it

Long Beach's Primary Nominating Election was held 2026-06-02 and is certified. It decided **seven of
the thirteen seats outright**. **None of those winners is in office**, because terms commence
2026-12-15.

> **DISTRICT 7 HANDS OVER TO VIVIAN MALAUULU ON 2026-12-15.** Roberto Uranga is term-limited — the
> candidate packet prints *"Not eligible to run for an additional term due to term limits"* against
> his name — and Malauulu won outright with 74.12%. She is **not** in the database. A certified result
> is not a fact about who holds the seat.

⚠ Also note **what a missing contest can mean**. City Attorney and City Prosecutor do not appear in
the 2026 results file at all. That is not a gap: LBMC 1.15.150 lets the Council **appoint** a sole
nominee and cancel the contest, and both resolutions are on file. A cancelled election looks exactly
like a missing result unless you go looking.

⚠ And **losing then winning is not continuous occupancy.** Tunua Thrash-Ntuk lost District 8 in 2020
(43.23% to Al Austin) and won it in 2024. Her occupancy starts 2024-12-17. A roster read without the
certified results would have got this wrong in the safe-looking direction.

---

# CA-2 — San José + Santa Clara County (applied 2026-09-03)

### Starting position, measured against production 2026-09-03

| Body | Offices | Seated | Dated terms | Headshots |
| --- | --- | --- | --- | --- |
| San José city | 11 | 11 | **0 — all `unknown`** | 11 |
| Santa Clara County officers | 3 | 3 | 3 | **0** |
| Santa Clara Board of Supervisors | **0** | — | — | — |

🟢 **A GOVERNMENT THE RESEARCH RECORD DID NOT MENTION ALSO EXISTS: `San Jose Unified School
District`** (`0634590`), 5 Board of Education seats, 5 seated, 0 dated, 0 headshots. **Out of Knight
scope** (city + county + legislature), recorded so it is not mistaken for a gap later.

### ✅ Task 1 — `X0047`, the five supervisorial districts (applied 2026-09-03)

`scripts/load-santa-clara-supervisor-boundaries.ts`, six gates, all passing.

🔴🔴 **THE COUNTY PUBLISHES FIVE COMPETING SUPERVISOR LAYERS AND THE GA-4 INVERSION IS LIVE IN BOTH
DIRECTIONS.** The trap is the county **Planning** layer: the most recent edit date in the county's
entire GIS estate, the correct five names, and boundaries **identical to the superseded 2011 map**.

🟢 **THE ARBITER IS THE BODY'S OWN RESIDENT-FACING LOOKUP.** Re-verified 2026-09-03 by walking the
Board's "Find My Supervisor" app → webmap → layer:

```
appid 5a47e27abd29447d8b6420fded6091af   ("Find My Supervisor", modified 2026-03-27)
  -> webmap a51f16fac6304375bbe95813670ae6d9  (modified 2025-09-02)
    -> ONE operational layer:
       services2.arcgis.com/tcv2cMrq63AgvbHF/.../Supervisorial_Districts_2021_web_app_test/FeatureServer/0
```

### 🔴 CORRECTION 1 — THE COUNTY-CLOSURE TEST DOES NOT DISCRIMINATE BETWEEN LAYERS

The research record read *"G's union closes on the TIGER county polygon to 0.0002 sq mi"* against
H's *"spills 0.87 outside and leaves 3.75 uncovered"*, and offered that as structural corroboration.
**Measured against production's own `06085`/`G4020`, every layer closes the same way:**

| Layer | Union | Outside the county | County uncovered |
| --- | --- | --- | --- |
| **E** — the arbiter's layer | 1304.9346 | **4.6262** | **3.7478** |
| F — "2021 Final Plan" | 1304.9346 | **4.6262** | **3.7478** |
| I — the **superseded 2011 map** | 1304.9332 | **4.6249** | **3.7477** |

⚠ **The 2011 map "closes" as well as the current one.** So closure is a property of the
**REFERENCE** — the county's digitisation against TIGER's — and **cannot tell a current map from a
stale one.** The record's 0.0002 figure was measured against some other county boundary.
🔴 **Two digitisations of one boundary need a TOLERANCE, not equality** — and a tolerance test is not
an arbitration.

🟢 **WHAT DOES HOLD, re-measured 2026-09-03:** E is geometrically **identical to F** (symmetric
difference **0.0000** on all five districts) and differs from the 2011 map by
**244.9 · 10.1 · 145.9 · 6.4 · 119.4** — matching the record's own figures. The arbitration stands
on three legs: the arbiter app, the 2011 delta, and the address probe. **Closure was never one.**

▶ So `GATE 6` keeps closure only as a **sanity bound** and says so in terms, and **`GATE 5` does the
real work**: every district must differ from its nearest 2011 polygon by ≥ 5.0 sq mi. The smallest
real margin is D4 at 6.35; **a load of the trap layer would score ~0 and fail.**

⚠ **F AND I CARRY NO DISTRICT ATTRIBUTE AT ALL** — only `OBJECTID`. There is no key to join on, so
comparisons against them must pair each district with the polygon it **overlaps most**. A join
attempt returns nothing and looks like a clean result.

### 🔴 CORRECTION 2 — LAYER E'S PORTRAIT URLS ARE 175x175 THUMBNAILS

The record found `picture` URLs on layer E and called them *"a headshot source ... ⚠ TEST them and
MEASURE THE PIXELS"*. Tested 2026-09-03: **all five are 175x175**, a **4.29x** upscale to reach
600x750. Five byte-distinct real portraits, all far below the bar.

▶ **The instruction was right and the source is unusable.** Stage 5 must come from the supervisors'
own district sites (`d1..d5.santaclaracounty.gov`, whose URLs layer E also supplies).

### ✅ Tasks 2–3 — `CC_0056`, structure and occupancy (applied 2026-09-03)

1 chamber, **5 districts, 5 offices, 5 people, 5 dated terms, 0 vacancies.**

🔴 **`district_type` IS `'COUNTY'`, FOLLOWING RACINE COUNTY, WISCONSIN (`X-RC-SUP`)** — the analogue
already in production: a county board with single-member supervisorial districts, written `COUNTY`
with `ocd_id '.../county:racine/council_district:N'`.
⚠ **NOT `'LOCAL'`.** That is what `X0045` (Macon-Bibb) and `X0021` use, and Macon-Bibb only because
it is a **consolidated city-county**. Santa Clara is **not** consolidated — San José is a separate
government with its own eleven seats. `LOCAL` would put county supervisors in the same tier as city
councillors over the same ground.
🟢 Confirmed the read path admits it: `GEOFENCE_DISTRICT_JOIN`'s catch-all takes `'X%'` with
`district_type IN ('LOCAL','COUNTY','JUDICIAL')`.

#### 🔴 THE DAY RULE IS PUBLISHED; THE YEAR IS NOT ALWAYS SOURCED

The Registrar states on **every** county office page, verbatim: **"Term Begins: First Monday after
January 1 at Noon"**, and **"4 Years with a 3-Term Limit"** for supervisors. That is an instrument
stating the commencement rule *in terms*, so **the day is sound wherever the year is sourced.**

| D | Person | Written | Prec | Why |
| --- | --- | --- | --- | --- |
| 1 | Sylvia Arenas | 2023-01-01 | **year** | election year is cycle arithmetic, not a source |
| 2 | Betty Duong | 2025-01-06 | day | directly sourced — succeeded Chavez, who ended that day |
| 3 | Otto Lee | 2021-01-04 | day | directly sourced — "assumed office January 4, 2021" |
| 4 | Susan Ellenberg | 2019-01-01 | **year** | same as D1, and flagged weakest by the research pass |
| 5 | Margaret Abe-Koga | 2025-01-06 | day | directly sourced — succeeded Simitian |

⚠ **ARENAS AND ELLENBERG WERE CHASED BEFORE BEING DOWNGRADED, and the negative result is the
point.** The Registrar's office pages publish **no assumed-office date**;
`d4.santaclaracounty.gov` carries **no tenure prose** on its home page or its Bio page; no certified
2018 Statement of Vote could be reached. The record said *"confirm against the Registrar's 2018
certified results before writing, or drop her to `year`"* — it could not be confirmed, so she is
dropped. **Writing 2019-01-07 would assert a day derived from a year nobody published.**

#### ⚠ FORTY-ODD CAL-ACCESS COMMITTEE ROWS LOOK LIKE THESE PEOPLE AND ARE NOT THEM

`ARENAS FOR SUPERVISOR 2022; SYLVIA`, `ELLENBERG OFFICEHOLDER ACCOUNT; 2018 SUPERVISOR`,
`DUONG AND ABE-KOGA FOR SUPERVISOR 2024, SPONSORED BY …` — campaign-committee names ingested as
politicians. All `is_active = false`, no photos, no compass answers, and their offices carry **NULL
titles**. **None is reused as the officeholder and none is touched: a committee is not a person.**
Verified 2026-09-03 that **no person-shaped row existed** for any of the five before this wave.

🔴 **THE `external_id` BAND WAS MEASURED, NOT ASSUMED.** The county's three officers hold
**`-6085001..-6085003`** (county FIPS), and the rest of `-6085xxx` was empty. The supervisors take
**`-6085011..-6085015`**, a deliberate gap so the two blocks stay legible. ⚠ My first proposal was
`-106xxxx` on the state-FIPS pattern GA-5 used — also free, and **wrong for this county**, which had
already set its own convention. **Read the neighbours before choosing a band.**

### ✅ Verified end-to-end — the four-answer probe passes

San José City Hall (37.3375, −121.8853), using **production's own join semantics**:

| Seat | Holder |
| --- | --- |
| Council Member, District 3 | Anthony Tordillos |
| Mayor | Matt Mahan |
| **Supervisor, District 2** | **Betty Duong** ← this wave |
| Assembly Member, AD-25 | Ash Kalra |
| Senator, SD-15 | Dave Cortese |
| U.S. Representative, CD-18 | Zoe Lofgren |
| Assessor / Sheriff / District Attorney | Fligor / Jonsen / Rosen |

### 🔴🔴 A LATENT DEFECT FOUND ON THE WAY, AND MY OWN PROBE IS WHAT EXPOSED IT

**California's 120 state legislative `districts` rows carry their MTFCC INVERTED.**

| Table | `G5210` | `G5220` |
| --- | --- | --- |
| `geofence_boundaries` (correct, TIGER) | 40 rows, "State Senate District N" (`sldu`) | 80 rows, "Assembly District N" (`sldl`) |
| `essentials.districts` | **80 `STATE_LOWER`** (Assembly) | **40 `STATE_UPPER`** (Senate) |

Because both `geo_id` ranges start at `06001`, **a join pairing `geo_id` + `mtfcc` silently returns
the other chamber's district.** My first City Hall probe did exactly that and returned
**Anamarie Avila Farias (AD-15, Contra Costa)** and **Sasha Renée Pérez (SD-25, Los Angeles)** —
two real legislators from the wrong ends of the state, with no error.

🟢 **PRODUCTION IS NOT AFFECTED, AND THAT IS WHY.** `GEOFENCE_DISTRICT_JOIN` in
`backend/src/lib/districtQueries.ts` joins on `geo_id` and then maps the **BOUNDARY's** mtfcc to the
**DISTRICT's TYPE** — `gb.mtfcc = 'G5210' AND d.district_type = 'STATE_UPPER'` — and **never reads
`districts.mtfcc`**. San José's own `LOCAL` district rows have `d.mtfcc` **NULL** entirely, which
confirms the column is not load-bearing for resolution.

▶ **So this is a latent data inconsistency, not a live outage** — but it is a loaded gun for any
future ad-hoc query, and the repo's own convention is to pair `geo_id` with `mtfcc`. **Its own
migration, its own verification. Not folded into a seed wave.**

### ✅ Task 4 — `CC_0059`, all eleven San José occupancies dated (applied 2026-09-03)

**11 of 11 at `day` precision, 2019-01-01 .. 2025-08-12, no `term_end`.**

#### 🔴 CORRECTION 3 — I WAS WRONG ABOUT THE COMMENCEMENT RULE, AND THE CHARTER SETTLES IT

The CA-2 build notes above recorded that "San José has no fixed January commencement", on the
strength of the Registrar's page: *"The jurisdiction will hold a meeting following the completion
of the canvass of votes to swear-in new members … (Elections Code § 10263(b))"*. **That is
county-wide boilerplate describing the ceremony.** The instrument is the **City Charter**:

> **SECTION 1600.** "Each member's term shall commence on the **first day of January next
> following**, and end on the last day of December in the fourth calendar year succeeding, the
> date of the member's election"

> **SECTION 500** (Mayor). "for a term of four (4) years **from and after the first day of January
> following the year of the election**" — and, in terms, *"the term for the office of Mayor
> **beginning on January 1, 2023**"*.

🟢 **BOTH RULES ARE TRUE, FOR DIFFERENT CASES.** The charter's 1 January governs a **REGULAR**
election; the Registrar's swearing-in-after-canvass governs a **SPECIAL** one. That is exactly why
District 3 is dated in August and everyone else in January. ▶ **When a general rule and a specific
instrument disagree, they are usually answering different questions — find the case each governs.**

⚠ The research record's "1 January" came from **two Legistar turnovers that happened to land
there**. Right answer, wrong reasoning: **a pattern is not an instrument.** Section 1600 is quoted
inside `CC_0059` so nobody re-derives it.

#### The eleven, and where each date comes from

| Seat | Person | Start | How | Basis |
| --- | --- | --- | --- | --- |
| Mayor | Matt Mahan | 2023-01-01 | elected | Nov-2022 general, 51.21% over Chávez; charter §500 names the date |
| D1 | Rosemary Kamei | 2023-01-01 | elected | **June-2022 primary, 65.69% OUTRIGHT** |
| D2 | Pamela Campos | 2025-01-01 | elected | Nov-2024, 54.03% |
| D3 | Anthony Tordillos | **2025-08-12** | elected | special runoff 2025-06-24 (64.36%), certified 07-28, **oath 08-12** |
| D4 | David Cohen | 2021-01-01 | elected | Legistar + Nov-2020 general, 51.33% |
| D5 | Peter Ortiz | 2023-01-01 | elected | Nov-2022 general, 54.82% |
| D6 | Michael Mulcahy | 2025-01-01 | elected | Nov-2024, 51.30% |
| D7 | Bien Doan | 2023-01-01 | elected | Nov-2022 general, 53.79% |
| D8 | Domingo Candelas | **2023-01-30** | **appointed** | appointed to Arenas's vacancy, then won Nov-2024 |
| D9 | Pam Foley | 2019-01-01 | elected | Legistar; re-elected unopposed June-2022 |
| D10 | George Casey | 2025-01-01 | elected | Nov-2024, 57.80%, **beating the appointed incumbent** |

#### 🔴🔴 TWO SEATS ARE NOT ON THE FOUR-YEAR RHYTHM, AND D8 vs D10 IS THE LESSON

**D8 Candelas was APPOINTED into a vacancy** — Sylvia Arenas left for the county Board, Candelas
assumed office **2023-01-30**, served as interim member, then won the 2024 general outright.
Continuous occupancy runs from the **appointment**. His election year alone gives 2025-01-01 —
**two years late.**

⚠ **D10 IS THE NEAR MISS THAT CAME OUT CLEAN.** District 10 fell vacant *the same way* when Mahan
became Mayor, and **Arjun Batra was appointed from the same day, 2023-01-30** — but Batra **LOST**
to Casey in 2024, so Casey is a fresh occupancy at 2025-01-01. ▶ **The two seats are structurally
identical and resolve differently purely on who won. Ask per seat; never generalise a vacancy.**

⚠ **THE RESEARCH RECORD GUESSED THE WRONG SPECIAL ELECTION.** It said the "December 30, 2025
Special Runoff" was "almost certainly D3". It was the **county ASSESSOR runoff** (Fligor 65.16%
over Kumar) — which is also the corroboration for Fligor's *Partial/Unexpired Term* label. D3 was
decided on **2025-06-24**.

#### 🔴 A SAN JOSÉ SEAT CAN BE DECIDED IN THE JUNE PRIMARY

Charter **§1600(7)** elects nobody without a majority, so a primary majority **ends the contest**.
**Districts 1 and 9 are absent from the November 2022 ballot entirely.** Reading only the general
election silently loses those two seats.

#### 🔴 THE CLARITY FEED'S CANDIDATE ARRAY IS NOT ORDERED BY VOTES

`CH` is the candidate list and `V` is a **flat parallel array** of totals (`PCT` gives percentages).
My first pass read the **first-listed** name as the winner and would have made **Cindy Chávez
mayor** and **Nora Campos the District 5 member** — both wrong, both plausible enough to ship.
▶ Sort on the votes, and **print the totals beside every claim** so it stays checkable.
🟢 Clarity needs a version token: `/{eid}/current_ver.txt` → `/{eid}/{ver}/json/en/summary.json`.

#### ⚠ LEGISTAR IS PARTIAL, SO ABSENCE FROM IT PROVES NOTHING

**26 office records for 19 people across 2007–2021** — far too few to cover ten seats for fourteen
years. The research record leaned on "not one current member appears" as a negative result; it is
not one. **Only its positive records are usable** (Cohen 2021-01-01, Foley 2019-01-01, and Mahan's
2021 record, which is his **District 10 council seat — a different office from Mayor**).

#### ⚠ BALLOTPEDIA AGREED ON TEN OF ELEVEN, AND THE ELEVENTH IS INSTRUCTIVE

Used **only as a redundancy check** on dates already derived from certified results plus the
charter — never as the source. It disagrees on **Foley**, printing *"Tenure 2018"*. **2018 is her
ELECTION year, not her commencement**; the charter and the city's own Legistar record both say
2019-01-01. ▶ **"A published term year is EXPIRY" with the sign flipped — a published tenure year
is not a commencement either.**

#### ⚠ `CC_0057` AND `CC_0058` WERE TAKEN WHILE THIS WAS BEING WRITTEN

The re-count immediately before the rename found **`CC_0057` already MERGED TO MASTER**
(`politician_answer_blank_value`) and **`CC_0058`** claimed on a pushed branch. This wave is
**`CC_0059`**. 🔴 **Re-counting immediately before the rename is what caught it** — the file had
already been renamed to `CC_0057` at that point.

### ✅ Task 5 — stage 5, 8 of 8 portraits (applied 2026-09-03)

All eight from **one official source**, the county's own Elected Officials page, at **816x544**
(1.38x upscale, so they ship at their **native 435x544** 4:5 crop — the importer's ceiling, not a
defect). Verified back from the CDN: **8 render, 0 broken, 0 blank**, against a positive control
that had to fail and did.

🔴 **FOUR SOURCES WERE EXHAUSTED BEFORE SETTLING FOR 816x544**, and the negative results are the
record: the Drupal **originals 404** (the `styles/<name>/` strip that works elsewhere does not
here), **every other image style 404s** (the CDN serves only pre-generated derivatives — no
on-demand generation, so a `card_vertical_600x800` that exists for the DA's site cannot be
requested for these), the **individual office sites carry banners and candids**, and **layer E's
`picture` field is 175x175**.

#### 🔴🔴 ALT TEXT IS A SIGNAL, NOT A VERDICT — AND IT WAS WRONG IN BOTH DIRECTIONS

| The county's alt text | What the crop actually shows |
| --- | --- |
| Otto Lee: *"in front of a parking lot next to flowers"* | ✅ a **good** environmental portrait, facing camera, well framed |
| Betty Duong: *"Supervisor Better Duong"* (sounds neutral) | ⚠ a **podium candid** — microphone, looking aside, another person behind |

▶ **Only looking settles it.** Four are clean headshots (Arenas, Otto Lee, Fligor, Jonsen) and four
are candids (Duong, Abe-Koga, Ellenberg, Rosen). Ellenberg's file is literally named
`committee.jpeg` and names nobody — a meeting shot with another person's arm in frame; Rosen's is
mid-speech with a hand raised.

⚠ **RULING (Cantrell, 2026-09-03): import all eight.** My read was to ship the four clean ones and
leave the candids clean-null; the operator's call was that official, correctly-identified county
photos clear the bar even when they are candids. **Recorded because it sets the precedent** — a
candid from the body's own roster page is acceptable where a *blank* was the alternative. It does
**not** loosen the rule that made Leon Jones a tightened crop (an advocacy prop) or the four
Baldwin officials a blank (no photo at all).

⚠ **A TIGHTENED CROP WAS NOT AVAILABLE HERE.** Leon Jones was rescued by zooming a 1707x2560
source. These are already 816x544, so zooming past the distraction would push a face that is
*still looking away* to 2x+ upscale. The rescue move is a function of source pixels.

### ▶ What remains for CA-2

**Nothing. CA-2 is complete across all five stages.** A `san jose` banner already existed.

⚠ **FIVE OF THE COUNTY'S EIGHT SEATS TURN OVER IN JANUARY 2027** — D1 (Arenas), D4 (Ellenberg), the
Assessor, the Sheriff and the District Attorney are all on the 2026 ballot. **No 2026 winner is
written.** A certified result is not a fact about who holds a seat; Columbus taught that, where 4 of
6 winners were not yet seated. `CC_0056`'s post-verify pins the roster, so it will **fail loudly**
if re-run after the turnover — which is the intended behaviour.

⚠ **THE REGISTRAR NAMES TWO BOARD PRESIDENTS** — Lee (D3) and Ellenberg (D4) both carry the label,
so one page is stale. Still true 2026-09-03. Deliberately not modelled: **a rotating role is a
parenthetical on a seat title, never its own office.**

---

## Allocations taken by this slice

| Sequence | Taken | For |
| --- | --- | --- |
| `CC_` | `CC_0053`, `CC_0054` | Long Beach geometry repair, Long Beach occupancy dates |
| `CC_` | `CC_0056`, `CC_0059` | Santa Clara supervisors structure+occupancy, San José occupancy dates |
| `X` (private MTFCC) | `X0046` | Long Beach council districts |
| `X` (private MTFCC) | `X0047` | Santa Clara supervisorial districts |

🔴 The `CC_` ceiling was **`CC_0052`** measured across **138 refs** on 2026-09-02 — five slots above
what `MEMORY.md` and the GA-5 handoff recorded, and GA-5 itself had already had to renumber
`CC_0045`/`CC_0046` to `CC_0049`–`CC_0051` after a master collision. **Sweep every remote ref, and
re-count immediately before the rename.** CA-2 then found `CC_0057`/`CC_0058` taken while it was
being written and landed on `CC_0059`.

---

## Banners

`long beach` and `san jose` are both already live `CURATED_LOCAL` keys in the **essentials** repo
(`src/lib/buildingImages.js`), scoped `CA`:

- `long beach` — Long Beach from Queensway Bay | Christophe.Finot | CC BY-SA 2.5
- `san jose` — Downtown San Jose skyline panorama | XAtsukex | CC BY 3.0

Both **predate the program's certification standard** (compose 1700x540 first, then preview both
boxes). CA-3 re-certifies them rather than replacing them, and checks §8.1 adjacency against
`states/california.jpg`, which has not been examined.

⚠ Neither Los Angeles County nor Santa Clara County has its own county-tier key, and on the Florida
precedent it should not get one: Manatee, Leon and Miami-Dade never did. Palm Beach County got a key
because it has **no city half**. Both California counties have one.
