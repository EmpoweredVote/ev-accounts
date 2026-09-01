# Knight Foundation Cities — live program tracker

**Spec:** [`docs/superpowers/specs/2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md)

**Update this file at the end of every session.** It is the only place that knows where the program
stands. `MEMORY.md` holds one pointer to it and nothing else.

Per-state notes: [`fl.md`](./fl.md) · [`ga.md`](./ga.md).

Stage legend, from spec §3:
`1` geography (TIGER place + sldu + sldl) · `2` legislature · `3` city waves · `4` county waves ·
`5` assets (headshots + banner).
Status: `—` not started · `WIP` in progress · `✅` done and gated · `n/a` not required.

---

## Slice status

| # | State | Jurisdictions | 1 geo | 2 legis | 3 city | 4 county | 5 assets |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | FL | Bradenton, Miami, Palm Beach County, Tallahassee | ✅ | ✅ | ✅ | ✅ | ✅ |
| 2 | GA | Columbus, Macon, Milledgeville | ✅ | ✅ | WIP | WIP | — |
| 3 | CA | Long Beach, San José | ✅ | ✅ | — | — | — |
| 4 | IN | Fort Wayne, Gary | ✅ | — | — | — | — |
| 5 | MN | Duluth, Saint Paul | — | — | — | — | — |
| 6 | PA | Philadelphia, State College | — | — | — | — | — |
| 7 | SC | Columbia, Myrtle Beach | — | — | — | — | — |
| 8 | OH | Akron | — | — | — | — | — |
| 9 | CO | Boulder | ✅ | ✅ | — | — | — |
| 10 | NC | Charlotte | ✅ | ✅ | — | — | — |
| 11 | MI | Detroit | — | — | — | — | — |
| 12 | ND | Grand Forks | — | — | — | — | — |
| 13 | KY | Lexington | — | — | — | — | — |
| 14 | KS | Wichita | — | — | — | — | — |
| 15 | SD | Aberdeen | — | — | — | — | — |
| 16 | MS | Biloxi | — | — | — | — | — |

Order of execution is slice 1 → 16 as numbered (spec §3.1: grouped by state, largest group first).

🔴 **FL STAGES 3 AND 4 ARE BOTH CLOSED (2026-08-30) — the first slice in the program to close
either.** All four Florida jurisdictions are seated and gated: **Bradenton/Manatee, Tallahassee/Leon,
Palm Beach County and Miami/Miami-Dade**. **73 local and county offices, 72 filled, 1 vacant**
(Manatee District 1), across seven governments plus the state's 164.

⚠ **Palm Beach County has no city half**, so stage 3 had nothing to do for it — the stage closed with
three city governments, not four. 🔴🔴 **STAGE 5 CLOSED 2026-08-30 — FLORIDA IS THE FIRST SLICE IN THE PROGRAM TO FINISH ALL FIVE
STAGES.** 72 of 72 local and county officials carry a headshot, and five banner keys are live.

## Jurisdiction detail

| Jurisdiction | State | Parent county | Note |
| --- | --- | --- | --- |
| Bradenton | FL | Manatee | ✅ **SEATED 2026-08-28 (`CC_0008`/`CC_0009`): 6/6**, and **Manatee County 12/11, 1 vacant** (`CC_0010`). Smallest FL jurisdiction — the FL pipeline pilot |
| Miami | FL | Miami-Dade | ✅ **SEATED 2026-08-30 (`CC_0015`/`CC_0016`): 6/6**, and **Miami-Dade County 19/19** (`CC_0017`). **Not** consolidated — two governments, and both name a chamber `Office of the Mayor`. Mayor is a citywide executive, NOT a commissioner; 5 single-member districts. 🔴 Banner cannot be a downtown skyline (the FL state banner is "Miami Late Afternoon Skyline") |
| Palm Beach County | FL | — | ✅ **SEATED 2026-08-28 (`CC_0014`): 12/12.** County only, no city half — 7 single-member commission seats, **no at-large**, 5 officers. **Banner: own COUNTY key, decided 2026-08-28** (spec §8.3 resolved); key name and composition still to choose at FL-7 |
| Tallahassee | FL | Leon | ✅ **SEATED 2026-08-28 (`CC_0011`/`CC_0012`): 5/5.** Commission is **entirely at-large**, Mayor is Seat 4 — verified, so no ward layer was needed |
| Columbus | GA | Muscogee | **consolidated city-county** |
| Macon | GA | Bibb | **consolidated city-county** (Macon-Bibb) |
| Milledgeville | GA | Baldwin | 📋 **GA-3 PLANNED 2026-09-01, not applied**: 7 city + 11 county = 18 offices, 18 people, 0 vacancies. Ordinary city (20.420 sq mi) in an ordinary county (268.276). Council is 6 single-member districts + at-large Mayor, **not staggered**. Baldwin is **5 single-member commission seats, NO at-large**, Chair elected by the Board. 🔴 The city's own `City Council Districts (2025)` layer supersedes the county's copy — only District 4 reveals it |
| Long Beach | CA | Los Angeles | 4 citywide execs already seated; all 9 council districts absent |
| San José | CA | Santa Clara | Mayor already seated; all 10 council districts absent |
| Fort Wayne | IN | Allen | IN legislature is 12/100 + 6/50 — polygons already loaded |
| Gary | IN | Lake | |
| Duluth | MN | St. Louis | |
| Saint Paul | MN | Ramsey | |
| Philadelphia | PA | — | **consolidated city-county**, coterminous |
| State College | PA | Centre | borough, not a city |
| Columbia | SC | Richland | |
| Myrtle Beach | SC | Horry | |
| Akron | OH | Summit | |
| Boulder | CO | Boulder | CO legislature complete; cheapest slice |
| Charlotte | NC | Mecklenburg | NC legislature complete |
| Detroit | MI | Wayne | banner conflicts with the MI state banner |
| Grand Forks | ND | Grand Forks | ND House is multi-member — 2 per district |
| Lexington | KY | Fayette | **consolidated city-county** |
| Wichita | KS | Sedgwick | banner conflicts with the KS state banner |
| Aberdeen | SD | Brown | SD House is multi-member, with 26A/26B and 28A/28B subdistricts |
| Biloxi | MS | Harrison | |

For the four **consolidated city-counties** — Columbus, Macon, Philadelphia, Lexington — stage 4 drops
the county commission (the city council already is it) but **keeps the separately elected county
officers**. Stage 4 is never skipped entirely. See spec §3.2.

## Baselines measured 2026-08-28

Re-measure rather than trust these once any wave has applied.

### Legislature seats owed

| State | House have/expect | Senate have/expect |
| --- | --- | --- |
| CA | 80/80 | 40/40 |
| CO | 65/65 | 35/35 |
| NC | 120/120 | 50/50 |
| IN | 12/100 | 6/50 |
| FL | **120/120** | **40/40** |
| GA | **180/180** | **55/56** |
| KS | 0/125 | 0/40 |
| KY | 0/100 | 0/38 |
| MI | 0/110 | 0/38 |
| MN | 0/134 | 0/67 |
| MS | 0/122 | 0/52 |
| ND | 0/94 | 0/47 |
| OH | 0/99 | 0/33 |
| PA | 0/203 | 0/50 |
| SC | 0/124 | 0/46 |
| SD | 0/70 | 0/35 |

Total owed: **2,155**, of which **395 are now seated** (FL complete; GA 235 of 236, SD-12 vacant). Remaining: **1,760**.

### Geofence polygons present

| State | sldl | sldu | place | county |
| --- | --- | --- | --- | --- |
| CA | 80 | 40 | 482 | 58 |
| CO | 65 | 35 | 272 | 64 |
| IN | 100 | 50 | 566 | 92 |
| NC | 120 | 50 | 552 | 100 |
| FL | **120** | **40** | **411** | 67 |
| GA | **180** | **56** | **537** | 159 |
| KS | 0 | 0 | 0 | 105 |
| KY | 0 | 0 | 0 | 120 |
| MI | 0 | 0 | 0 | 83 |
| MN | 0 | 0 | 0 | 87 |
| MS | 0 | 0 | 0 | 82 |
| ND | 0 | 0 | 0 | 53 |
| OH | 0 | 0 | 0 | 88 |
| PA | 0 | 0 | 0 | 67 |
| SC | 0 | 0 | 0 | 46 |
| SD | 0 | 0 | 0 | 66 |

Every state except CA, CO, IN, NC, FL and GA needs a `place` + `sldu` + `sldl` load before any seat
in it is reachable by address. **Ten remain.**

### Local and county seats present

| Jurisdiction | Offices | Seated | With headshot |
| --- | --- | --- | --- |
| Long Beach city | 4 | 4 | 4 |
| Long Beach county (LA) | 3 | 3 | 3 |
| San José city | 1 | 1 | 1 |
| San José county (Santa Clara) | 3 | 3 | 0 |
| **Bradenton city** | **6** | **6** | **6** |
| **Manatee County** | **12** | **11** | **11** |
| **Tallahassee city** | **5** | **5** | **5** |
| **Leon County** | **13** | **13** | **13** |
| **Palm Beach County** | **12** | **12** | **12** |
| **Miami city** | **6** | **6** | **6** |
| **Miami-Dade County** | **19** | **19** | **19** |
| every other jurisdiction | 0 | 0 | 0 |

Bradenton and Manatee measured 2026-08-28 after FL-3. Manatee's twelfth office is Commission
District 1, flagged vacant since 2026-02-24 — the incumbent died and the Governor left the seat empty,
so it is on the 2026 ballot for a two-year unexpired term. **17 people, 0 headshots: that is the whole
of FL-3's stage-5 debt so far.**

Re-measured 2026-08-30 after FL-6, which closed stages 3 and 4. **Florida now holds 73 local and
county offices across SEVEN governments, 72 seated, 1 vacant** — plus 164 legislative offices. Palm
Beach has **no city half**, so it is a county row with no municipal partner. **All 72 now carry a headshot (FL-7, 2026-08-30) — the slice's stage-5 debt is CLEARED.**

Miami-Dade is the largest single jurisdiction in the program so far at 19 offices — 13 single-member
commission districts, a countywide Mayor who is not a Board member, and 5 constitutional officers.
⚠ Its **~60 Community Council seats are deliberately unmodelled**, and are the largest single block of
elected local offices found anywhere in the program.

### Banners present

`long beach`, `san jose`, and — from FL-7 — `miami`, `tallahassee`, `bradenton` plus the program's
first COUNTY key, `12099` Palm Beach. **20 cities still missing.**

🔴 **Miami's §8.1 conflict was resolved by MOVING the state banner, not by finding a different city
photograph.** Florida's state banner WAS Miami's skyline; it is now `cities/miami.jpg`, and the state
took `states/FL-v2.jpg` (Rookery Bay). ▶ **The same move is available to Wichita, Detroit and
Charlotte** — the remaining three with the same conflict. Any replacement state banner must be
VERSIONED, never an overwrite: the CDN does not reliably purge.

## Migration ledger

| Slice | Wave | Migration slots | Applied |
| --- | --- | --- | --- |
| FL | FL-2 structure | `CC_0006_fl_legislature_structure.sql` | 2026-08-28 |
| FL | FL-2 occupancy | `CC_0007_fl_legislature_incumbents.sql` | 2026-08-28 |
| FL | FL-3 city structure | `CC_0008_bradenton_structure.sql` | 2026-08-28 |
| FL | FL-3 city occupancy | `CC_0009_bradenton_people.sql` | 2026-08-28 |
| FL | FL-3 county (offices + people) | `CC_0010_manatee_county.sql` | 2026-08-28 |
| FL | FL-4 city structure | `CC_0011_tallahassee_structure.sql` | 2026-08-28 |
| FL | FL-4 city occupancy | `CC_0012_tallahassee_people.sql` | 2026-08-28 |
| FL | FL-4 county (offices + people) | `CC_0013_leon_county.sql` | 2026-08-28 |
| FL | FL-5 county (offices + people) | `CC_0014_palm_beach_county.sql` | 2026-08-28 |
| FL | FL-6 city structure | `CC_0015_miami_structure.sql` | 2026-08-30 |
| FL | FL-6 city occupancy | `CC_0016_miami_people.sql` | 2026-08-30 |
| FL | FL-6 county (offices + people) | `CC_0017_miami_dade_county.sql` | 2026-08-30 |
| GA | GA-2 structure | `CC_0025_ga_legislature_structure.sql` | 2026-09-01 |
| GA | GA-2 occupancy | `CC_0026_ga_legislature_incumbents.sql` | 2026-09-01 |
| — | — | next free is **`CC_0027`** | — |

🔴🔴 **THIS NUMBER GOES STALE BETWEEN WAVES, AND IT HAS DONE SO TWICE.** On 2026-08-31 it jumped from `CC_0018` to `CC_0025` without a single Knight wave running. `CC_0018`–`CC_0024` were taken on **master**, by the headshot render sweep and by Lawrence County, while this branch sat unmerged. A Georgia wave that trusted the old line would have collided on its first migration; GA-2 then consumed `CC_0025` and `CC_0026` the same day, so the line was stale again within hours. **Re-count against `origin/master` at the start of every wave, not against this file** — this file records what the last wave took, which is not the same question. The `X` sequence was checked at the same time and is unchanged: `X0042` is still free.

Private MTFCC allocations, which are a second sequence to take numbers from: `X0036` Bradenton wards,
`X0037` Manatee commission districts, `X0038` Leon commission districts, `X0039` Palm Beach commission districts, `X0040` Miami-Dade commission districts, `X0041` Miami city commission districts. **Next free is `X0042`** — GA-3 plans to take `X0042` (Milledgeville council) and `X0043` (Baldwin commission). There is no central registry — each
wave hardcodes its code in its own loader, so this table is the only place they are listed together.

Append a row per applied migration. Namespace is `CC_` (Cantrell). Take the number last.

## Session log

| Date | Session did | Next action |
| --- | --- | --- |
| 2026-08-28 | Program brainstormed and spec written. Production measured: 2,155 legislative seats owed, 12 states with no `place`/`sldu`/`sldl` polygons, 24 of 26 jurisdictions with zero local seats, 24 banners missing. | (done) |
| 2026-08-28 | **FL-1 + FL-2 APPLIED.** Loaded 120 `sldl` + 40 `sldu` + 411 `place` polygons for FIPS 12; vintage confirmed against the enacted plans `H000H8013`/`S027S8058` (6 of 6 anchors). Seated the Florida Legislature: **160 offices, 155 people, 5 vacancies** (the plan had assumed 160/160). `CC_0006` + `CC_0007`. All gates green, no new reachability bucket, zero missing-terms drift. | Write the FL-3 plan: Bradenton + Manatee County. |
| 2026-08-28 | **FL-3 PLANNED, not applied.** Wrote [`2026-08-28-knight-fl-wave-3-bradenton-manatee.md`](../../docs/superpowers/plans/2026-08-28-knight-fl-wave-3-bradenton-manatee.md): 18 offices, 17 people, 1 vacancy. Measured while planning — the `geo_id` collision includes the COUNTY layer (`12081` is Manatee County **and** HD-81); Bradenton's ward layer is land-only, so the tiling gate goes against TIGER `AREALAND`, not the place polygon; Manatee's four district services are the same boundary to 0.000 sq mi; Commission District 1 is vacant and the Supervisor of Elections' own two pages disagree about it; Manatee is a **non-charter** county. | Execute FL-3 Task 1 (load `X0036` Bradenton wards). |
| 2026-08-28 | **FL-3 APPLIED.** Loaded `X0036` (5 Bradenton wards) and `X0037` (5 Manatee commission districts), then seated **18 offices, 17 people, 1 vacancy** — `CC_0008`, `CC_0009`, `CC_0010`. The four-answer probe at Bradenton City Hall returns Ward 3, Commission District 3, HD-71 and SD-20. All gates green, no new reachability bucket, `offices_missing_terms` unflagged unchanged at 655 of a 699 threshold. Four corrections went into `fl.md`: the `geo_id` collision reaches the **county** layer (`12081` is Manatee County *and* HD-81); the child-county matview rule was too broad; `seat_officeholder()` refuses a NULL `term_start`; and an `external_id` band guard must be an **allowlist**, not a count, or the migration is not idempotent. | Write the FL-4 plan: Tallahassee + Leon County. Verify first whether Tallahassee's city commission is entirely at-large. |
| 2026-08-28 | **FL-4 PLANNED, not applied.** Wrote [`2026-08-28-knight-fl-wave-4-tallahassee-leon.md`](../../docs/superpowers/plans/2026-08-28-knight-fl-wave-4-tallahassee-leon.md): 18 offices, 18 people, **0 vacancies**. Measured while planning — **Tallahassee's commission is entirely at-large** (the Mayor is Seat 4), which answers `fl.md`'s open question and means FL-4 needs only ONE boundary layer; **Leon is a CHARTER county and elects SIX constitutional officers** including the Superintendent of Schools, against Manatee's five; the two counties also name their at-large seats differently. Anchor is Tallahassee City Hall → Commission D5, HD-9, SD-3, and the SOE service `fl.md` already trusts carries both the commission-district layer and an independent City Limits layer. Zero name collisions among all 18. | Execute FL-4 Task 1 (load `X0038` Leon commission districts). |
| 2026-08-28 | **FL-4 APPLIED.** Loaded `X0038` (5 Leon commission districts) and seated **18 offices, 18 people, 0 vacancies** — `CC_0011`, `CC_0012`, `CC_0013`. All four required answers PASS at Tallahassee City Hall (5 city commissioners, County D5, HD-9, SD-3); gates green; `offices_missing_terms` unchanged at 820/165/655. **Tallahassee's commission is entirely at-large** (Mayor = Seat 4), so the wave needed only ONE boundary loader and the probe asserts a count per answer. **Leon is a CHARTER county electing SIX constitutional officers** including the Superintendent of Schools, against Manatee's five. ⚠ Also fixed a latent defect FL-4 would have triggered: FL-3's band guard claimed the whole shared `-(1240000+n)` band, so FL-4's rows would have broken FL-3's re-run — both now scope to their own sub-range, and all six migrations re-run clean. | Write the FL-5 plan: Palm Beach County, county only. Its banner key is still undecided (spec §8.3). |
| 2026-08-28 | **Session close.** FL-1 → FL-4 all applied and gated; all six FL-3/FL-4 migrations verified idempotent; branch pushed and in sync. **Decision (Cantrell): Palm Beach County gets its own COUNTY banner key**, not the Florida state banner — the state banner is a Miami skyline and would collide with Miami's at FL-6. Spec §8.3 resolved. `fl.md` now carries an **"FL-5 — what is already measured"** block: Palm Beach is FIPS `12099` (⚠ collides with HD-99), its county district and polygon already exist, it has **zero** offices, and the `external_id` band is 35/10,000 used so FL-5 should start at `n = 61`. | **Write the FL-5 plan: Palm Beach County, county only.** Read `fl.md`'s FL-5 block first — it lists the five things that still must be measured, including the probe anchor, which is a real open question because there is no city hall and the probe drops to THREE answers. |
| 2026-08-28 | **FL-5 PLANNED, not applied.** Wrote [`2026-08-28-knight-fl-wave-5-palm-beach-county.md`](../../docs/superpowers/plans/2026-08-28-knight-fl-wave-5-palm-beach-county.md): **12 offices, 12 people, 0 vacancies, ONE migration (`CC_0014`)** — no city half, so no city government, chamber or district, and the acceptance probe drops to **three** required answers with the city slot legitimately absent. Measured while planning — Palm Beach is a **charter** county electing **FIVE** officers against Leon's chartered **six**, so **charter status predicts nothing**; its own page lists the **State Attorney and Public Defender** as constitutional officers, but those are 15th Judicial Circuit offices that look countywide only because the circuit is coterminous with the county — not seated, and recorded as program-level open work; the commission is **7 single-member seats with no at-large seat at all**, a third convention in three counties; the seven districts **do not tile the TIGER county** because 155.54 sq mi of `12099` is the Atlantic, which the cross-check service carries as an unassigned blank row; **three of seven bio pages append the predecessor's biography unlabelled**, so a regex returns Mack Bernard's 2016 for Bobby Powell's seat; **Powell and Bernard traded seats** and Bernard is already in prod from FL-2; and **the Clerk was suspended on 2026-08-18** with a Clerk Ad Interim now holding the office. Zero name collisions among the twelve. | Execute FL-5 Task 1 (load `X0039`, the 7 Palm Beach commission districts). ⚠ Re-check the Clerk's seat and all four November-2026 commission seats on the day of apply. **(⚠ THAT COUNT WAS WRONG — it is THREE: Districts 2, 4, 6. See the next row and `fl.md`.)** |
| 2026-08-28 | **FL-5 APPLIED.** Loaded `X0039` (7 Palm Beach commission districts) and seated **12 offices, 12 people, 0 vacancies** — `CC_0014`, one migration, because Palm Beach has no city half. All five probe assertions PASS at the county Governmental Center (Commission D7, HD-87, SD-24, all 5 officers, **and the city slot asserted at ZERO**); all seven FL local migrations re-run clean; gates green; `offices_missing_terms` unchanged at 820/165/655. 🔴🔴 **CHARTER STATUS PREDICTS NOTHING** — Manatee non-charter 5 officers, Leon charter **6**, Palm Beach charter **5**; and Palm Beach is **7 single-member seats with NO at-large commissioner**, a third convention in three counties. 🔴🔴 **STATE ATTORNEY AND PUBLIC DEFENDER ARE 15th-CIRCUIT OFFICES**, listed by the county only because that circuit is coterminous with it — not seated, and now program-level open work. 🔴 The 7 districts **do not tile** TIGER `12099`: 155.54 sq mi is the Atlantic, which the cross-check service carries as an unassigned blank row, so the gate asserts structure rather than a tolerance that could hide a missing district. 🔴 **Three of seven bio pages append the predecessor's biography unlabelled**; a regex returns Mack Bernard's 2016 for Bobby Powell's seat. 🔴 **Powell and Bernard traded seats** and Bernard was already in prod. 🔴 The **Clerk was suspended 2026-08-18** and a Clerk Ad Interim is seated. Also fixed FL-4's headers, which cited FL-3 throughout, and found that `splitName()` required a comma before a suffix. | **Write the FL-6 plan: Miami + Miami-Dade County.** Read `fl.md`'s FL-5 section first. 🔴 **FIND THE SOE CANDIDATE FILING REPORT FIRST** — Miami-Dade runs the same VoterFocus platform, and for Palm Beach it settled the seat stagger, the officer cycle, three commission dates and every ballot name; it is NOT on the SOE's own site. 🔴 Miami-Dade is a **CHARTER county — read its officer set from its charter, inherit nothing**. 🔴 Miami and Miami-Dade are **separate governments**. 🔴 **MIAMI HAS NO STATE REPRESENTATIVE while HD-113 is vacant**, so its probe can return only three of four answers — that is the truth, not a defect. 🔴 Miami's banner cannot be a downtown skyline. ⚠ **Widen `splitName()` before a suffixed name appears.** |
| 2026-08-29 | **FL-6 PLANNED, not applied.** Wrote [`2026-08-29-knight-fl-wave-6-miami-miami-dade.md`](../../docs/superpowers/plans/2026-08-29-knight-fl-wave-6-miami-miami-dade.md): **25 offices, 25 people, 0 vacancies** — the largest wave in the slice. Two governments, five chambers, **two** boundary loaders (`X0040` Miami-Dade's 13 districts, `X0041` Miami's 5) and **three** migrations (`CC_0015`–`CC_0017`). Measured while planning — 🔴🔴 **THE SLICE'S FIRST REUSE: `Oliver Gilbert` is ALREADY in prod as `-1212402`**, a 2026 US House candidate for FL-24, and is the same person as Miami-Dade Commissioner D1; he gets an `office_terms` row and no new politician row, `n = 93` stays unused, and **the band guard needs a FIFTH shape** — absence over the new sub-range plus a POSITIVE assertion per reused id. 🔴🔴 **TWO ANCHORS**: Miami City Hall sits in **vacant HD-113** and returns 3 of 4 answers, so the Government Center is a second anchor returning 4 of 4, and probe A asserts the HD-113 slot is **exactly zero**. 🔴 One person's move made that vacancy — Higgins vacated MDC D5 → won the Miami mayoralty (Dec 2025 runoff) → the **Commission** appointed Vicki Lopez to D5 → vacating HD-113; and a Miami-Dade commission vacancy is filled by the **Commission's own vote**, not the Governor. 🔴 **NEW GATE CLASS — VINTAGE**: Miami-Dade publishes **four** polygon vintages plus `TBLCOMMISSIONDISTRICT`, which is named like the primary and has **no geometry**; the 2011 layer has identical fields, geometry type and row count, and **District 1 moved only 0.136 sq mi** (D9 moved 126), so a spot check there would pass on the wrong map. 🔴 **Miami-Dade tiles its county EXACTLY (0.03 sq mi uncovered) — the opposite of Palm Beach's 155.54**, so FL-5's structural gate fails here on correct data: **measure the tiling before choosing the gate.** 🔴 **`12086` collides with ZIP code 12086 in NEW YORK, and 40 of Florida's 67 county `geo_id`s have a NY ZCTA twin.** 🔴 **Miami's city map was struck down TWICE by a federal court**; the May 2024 settlement map governs — which corrects `fl.md`'s FL-1 note that only the congressional map was litigated. Plus: the Miami-Dade SOE **does** publish the combined roster PDF Palm Beach lacked, but it stops at the county line and carries an as-of date; **two appointed commissioners** (D5, D6); all five constitutional officers share one published start, **2025-01-07** (Amendment 10); **four repeated surnames inside the wave** and **two two-word surnames** `splitName()` cannot parse; a **fourth** Clerk title across four counties; **State Attorney and Public Defender confirmed excluded by Miami-Dade's own publishers**, vindicating FL-5's ruling against Palm Beach's page; and **~60 Community Council seats**, the largest unmodelled block of elected local offices found in the program. | Execute FL-6 **Task 0 first** — 🔴 the knight branch was checked out in NO worktree when this plan was written (`C:/EV-Accounts` had moved to `feat/compass-user-lenses`), and a bare `ls migrations/` on the wrong branch reports the next free slot as `CC_0006`, **wrong by nine**. A dedicated worktree now exists at **`C:/ev-accounts-knight`**. Then Task 1 (load `X0040`). |
| 2026-08-30 | **FL-6 APPLIED — STAGES 3 AND 4 CLOSED.** Loaded nothing new; seated **25 offices, 25 people, 0 vacancies** across TWO governments — `CC_0015`, `CC_0016`, `CC_0017`. Miami 6/6 and Miami-Dade 19/19. **Florida is the first slice to close either stage: 73 local/county offices, 72 seated, 1 vacant, seven governments.** All ELEVEN probe assertions PASS across both anchors; all ten FL local migrations re-run clean; gates green; no new reachability bucket (5/17/38); `offices_missing_terms` unchanged at 820/165/655. 🔴🔴 **THE SLICE'S FIRST REUSE**: `Oliver Gilbert` `-1212402` was already in prod as an FL-24 candidate and is Miami-Dade D1 — 19 terms from 18 new politician rows, asserted as exactly one row named Oliver Gilbert. ⚠ The plan's band guard was wrong: the roster reserves no gap at `-1240093` (that is Keon Hardemon), it simply skips the reused person. The invariant is **"exactly one id outside the new sub-range, and it is the declared reuse"**. 🔴🔴 **FOUR APPOINTMENTS, NOT THE PLANNED TWO** — D5, D6, D8, D11 — because **a roster's "Appointed" flag describes the CURRENT term, not how the occupancy began**; D8 and D11 have been elected since, so the SOE hides them. And **the appointing authority differs**: three Commission votes, one by Gov. DeSantis. The gate asserts the count AND the four titles. 🔴 **HD-113 IS VACANT AT MIAMI CITY HALL**, so probe A asserts a state-house answer **at exactly zero** — the only assertion in the slice that passes by being empty — and the Government Center is a second anchor returning 4 of 4. ⚠ **One probe ruling read 33 BEFORE the apply** and had to be scoped per wave: Leon and Manatee seat legitimate at-large commissioners countywide. **Running the probe before applying is what caught it.** ⚠ **The city occupancy half cannot be dry-run alone** — its offices do not exist yet; it was proven by running structure+people as ONE transaction ending in ROLLBACK, with the stream asserted to hold zero COMMIT. Miami-Dade elects **FIVE** officers, so **charter status predicted nothing in four counties out of four**. | **FL-7 — Florida assets. 72 people, 0 headshots, and three banners: Bradenton, Tallahassee and Miami, plus Palm Beach County's own COUNTY key whose name and composition are still unchosen.** 🔴 **Miami's banner CANNOT be a downtown skyline — the Florida state banner is "Miami Late Afternoon Skyline".** ▶ Also re-check the six Florida vacancies (5 legislative + Manatee D1) and write their predecessor terms together; and re-check Palm Beach D2/D4/D6 and Miami-Dade D5/D6/D8/D11 after the November 2026 general. 🔴 If Oliver Gilbert wins FL-24 he resigns Miami-Dade D1, which becomes another Commission-appointed vacancy. |
| 2026-08-30 | **FL-7 APPLIED — FLORIDA IS COMPLETE, THE FIRST SLICE TO CLOSE ALL FIVE STAGES.** Five banners live and **72 of 72** local/county officials carry a headshot (the wave began at 1). 🔴🔴 **THE MIAMI SKYLINE MOVED DOWN A TIER**: Florida's state banner WAS Miami's skyline, which is also the only thing Miami's own banner could be, so the photograph became `cities/miami.jpg` and the state took **Rookery Bay, Ten Thousand Islands** as `states/FL-v2.jpg` — **versioned, never an overwrite**, because the CDN does not reliably purge and this one renders for every Florida address. ▶ The same move is available to Wichita, Detroit and Charlotte. 🔴🔴 **THE BANNER LOOKUP ITSELF WAS WRONG** — `CURATED_LOCAL` matches by SUBSTRING, so a `miami` key hands Miami's banner to seven separate cities including Miami Beach, and `palm beach` matches West Palm Beach while matching NOTHING for Boca Raton. Fixed with opt-in `match:'exact'` and a county tier keyed by GEOID (essentials #108). ⚠ **The first certification was rejected because I cropped sources straight to 6:1** — production composes a **1700x540** asset and the browser then shows the middle **52.5%**, so skipping the composition stage rendered the Capitol as the middle of a tall building. **Compose the asset, then preview both boxes.** 🔴 **THREE HEADSHOT PIPELINE DEFECTS, each of which shipped silently**: the importer **refused every WEBP** (nine officials would have vanished after being approved), the renderer turned **transparent pixels BLACK** while the importer flattened to white (a proof sheet that differs from the import is worse than none), and the importer **refetched live** rather than shipping the approved bytes. The crop now lives once in `scripts/headshot_crop.py`. Also: `COHORTS` was hardcoded to Colorado Springs, so the wave rendered 68 faces, filtered every one out, and cheerfully reported success over a 7 KB page. 🔴 **`miami.gov` 403s every non-browser client** — the durable fix was not the Wayback Machine (which 503s) but an institution re-hosting the same official portrait: Christine King's is on her FIU fellowship profile under the identical filename. | **Slice 2 — GA: Columbus, Macon, Milledgeville.** 🔴 Columbus/Muscogee and Macon-Bibb are CONSOLIDATED city-counties, so stage 4 differs from every Florida county (spec §3.2). ▶ Carry forward: re-check the six Florida vacancies and their predecessor terms; re-check Palm Beach D2/D4/D6 and Miami-Dade D5/D6/D8/D11 after the November 2026 general; and if Oliver Gilbert wins FL-24 he resigns Miami-Dade D1. |
| 2026-08-31 | **No wave. Branch maintenance.** Rebased 42 commits onto master (the branch was **92 behind**; zero files were touched on both sides, so the replay was clean and every branch-only file is byte-identical to before). Corrected the stale next-free slot in this file and in `fl.md`. 🔴🔴 **`CC_0006`–`CC_0017` ARE APPLIED TO PRODUCTION BUT STILL LIVE ONLY ON THIS BRANCH** — PR #212 has never been merged, and that is what let master claim seven slots out from under the ledger. | **Slice 2 — GA: Columbus, Macon, Milledgeville.** Unchanged. Re-count the free slot against `origin/master` first. |
| 2026-08-31 | **GA-1 MEASURED, NOT LOADED.** Opened the slice and wrote [`ga.md`](./ga.md). Georgia is greenfield below the congressional layer: **no `place`, no `sldu`, no `sldl`**, and Baldwin/Bibb/Muscogee carry ZERO offices. Raw TIGER 2024 FIPS 13 measured from the `.dbf`: **180 `sldl` + 56 `sldu`, `LSY=2024`, 0 `ZZZ`**, and 675 place records of which **537 are `G4110`**. 🔴🔴 **THE `geo_id` COLLISION IS THREE-WAY** — all 56 `sldu` ids collide with `sldl`, and **89 of 159 county ids** fall inside the `sldl` range, so `13009` is Baldwin County AND HD-9. 🔴 **CONSOLIDATION MEASURED, NOT ASSUMED**: Columbus and Macon-Bibb place polygons equal their whole counties to 0.000 sq mi, and neither Payne City nor Bibb City survives in TIGER — no Nashville-style balance gap. 🔴 **TIGER MODELS GEORGIA'S CONSOLIDATED GOVERNMENTS TWO WAYS**: Augusta-Richmond and Athens-Clarke are `FUNCSTAT='F'` BALANCE records (they still contain satellite towns); Macon-Bibb is `'A'`. 🔴 TIGER calls it **`Macon-Bibb County`, not `Macon city`**. 🔴 **`Macon County` `13193` IS NOT MACON'S COUNTY** — Bibb `13021` is. ⏸ **STOPPED BEFORE LOADING ON PURPOSE**: Georgia's 2021 maps were STRUCK DOWN and the operative maps are the **2023 remedial plans**, so the vintage check matters more here than in Florida, and it is not closed. | **Close the vintage check, then load.** TIGER's own answers at the three interior points are Columbus HD-137/SD-15, Macon-Bibb HD-145/SD-26, Milledgeville HD-149/SD-25 — confirm all three independently via `legis.ga.gov/find-my-legislator` or the Reapportionment Office's plan geometry. ⚠ The `Georgia_Senate_District` service that a search surfaces is a COUNTY's copy of the **2022** map. Then add `GA` to `STATE_LAYER_ALLOWLIST` (`sldu`, `sldl`, `place`), load, and refresh `geofence_child_county` CONCURRENTLY. |
| 2026-08-31 | **GA-1 VINTAGE CHECK CLOSED.** TIGER 2024 FIPS 13 **is** Georgia's 2023 remedial plan, proven geometrically: the General Assembly's own "Current Georgia House (2023)" / "Current Georgia Senate (2023)" GeoJSON was compared against **every** TIGER polygon at that polygon's own interior point — **180/180 House and 56/56 Senate agree, 0 differ, 0 unmatched.** 🔴🔴 **TEST EVERY DISTRICT WHEN THE WHOLE MAP IS AVAILABLE — THREE ANCHORS CAN PASS ON THE WRONG MAP**, because a remap leaves many districts untouched; the full comparison cost the same as three. 🔴 **THE STATE'S MAP ENDPOINTS 401 curl AND an in-page `fetch()`** (bearer token from `/api/authentication/token`); the way through is to let the page load them and read the bodies from the browser's network log. ⚠ The `Georgia_Senate_District` service a search surfaces is a COUNTY's copy of the **2022** map — not used. 🟢 **THE SAME PAYLOAD IS A GA-2 ROSTER**: 236 of 236 districts carry a member name, a stable member id and a portrait URL, with `DateVacated` null on every one — ONE source, and a no-vacancy payload is what a stale payload also looks like. | **Load GA-1.** Add `GA` to `STATE_LAYER_ALLOWLIST` (`sldu`, `sldl`, `place`) and `STATE_CITY_ASSERTIONS` (`Columbus city`, `Macon-Bibb County`, `Milledgeville city`), load 180 + 56 + 537, refresh `geofence_child_county` CONCURRENTLY via the Supabase MCP, then verify by `geo_id`. Then GA-2, with a SECOND roster source. |
| 2026-08-31 | **GA-1 APPLIED — stage 1 closed for Georgia.** Added `GA` to the TIGER loader (allowlist, city assertions, and its own MTFCC pre-flight block, each carrying the measurement that justifies its numbers), then loaded **773 boundaries / 236 districts: 56 `sldu` + 180 `sldl` + 537 `place`, 138 CDPs skipped, 0 errors.** All gates passed on the dry run before any write. Verified after: `STATE_LOWER` 180 and `STATE_UPPER` 56 all carrying a `geo_id`; the three Knight places present by EXACT `geo_id`; legislative ranges 13001–13056 / 13001–13180 intact; `check:child-county` **stale 0** after the CONCURRENT refresh through the Supabase MCP. 🟢 **THE THREE-WAY `geo_id` COLLISION DOES NOT BITE WHEN THE JOIN PAIRS `geo_id` WITH `district_type`** — each of the three anchors resolves through our own polygons to EXACTLY TWO answers, and they are the state's answers (Columbus HD-137/SD-15, Macon-Bibb HD-145/SD-26, Milledgeville HD-149/SD-25). | **GA-2: the legislature, 180 + 56.** The state's own map payload is roster source #1 (name, stable member id, portrait per district, `DateVacated` null on all 236) — **find a SECOND source before writing anything**, and re-check every seat for a change since that payload was last edited. |
| 2026-09-01 | **GA-2 APPLIED — the Georgia legislature is seated.** `CC_0025` (2 chambers + 236 offices) and `CC_0026` (233 new people + 2 reused, 235 terms). Verified: House 180/180, Senate 56/55, `offices_missing_terms` 821/166 with the **unflagged count unchanged at 655**, and the acceptance probe returns a real representative AND senator at all three Knight cities. 🔴🔴 **THE CHANGE-CHECK FOUND A STALE SEAT: SD-12 IS VACANT AND legis.ga.gov IS FIVE MONTHS WRONG ABOUT IT** — Freddie Powell Sims resigned 2026-03-23 (three outlets name the date) and the chamber's roster still lists her with no `dateVacated`; Open States carries 55 senators and no D12. Seating from the roster alone would have reproduced the TX SD-22 Birdwell failure. `senate.ga.gov` now REDIRECTS to legis.ga.gov, so there is no second chamber roster to arbitrate with. ⚠ **THE DETECTOR WAS BROKEN FIRST AND SAID SO BY BEING UNIFORM** (wrong CSV column → empty third-party side → all 236 flagged); it now asserts a positive control. 🔴 **FOUR ROSTER NAMES ALREADY EXISTED IN PROD AND ONLY TWO WERE THE SAME PERSON** — `John Carson` is a COLORADO senator and `Kim Jackson` a UTAH treasurer. 🔴 **GEORGIA PUBLISHES NO SERVICE-START**, so all 235 terms are open-ended at `'unknown'`; and it publishes STRUCTURED NAME PARTS, so `splitName()` is never involved. | **GA-3: Milledgeville** — the small pilot, as Bradenton was for Florida. Then Columbus/Muscogee and Macon-Bibb, both CONSOLIDATED: stage 4 drops the county commission and keeps the separately elected county officers, confirmed from each charter. |
| 2026-09-01 | **GA-3 PLANNED, not applied.** Wrote [`2026-09-01-knight-ga-wave-3-milledgeville-baldwin.md`](../../docs/superpowers/plans/2026-09-01-knight-ga-wave-3-milledgeville-baldwin.md) and `seed-milledgeville-2026/ROSTERS.md`: **18 offices, 18 people, 0 vacancies** — 7 city, 11 county, two boundary loads (`X0042`, `X0043`) and three migrations (`CC_0027`–`CC_0029`). Measured while planning — 🟢🟢 **THE SECRETARY OF STATE PUBLISHES CERTIFIED *MUNICIPAL* RESULTS AND THEY SETTLED EVERY SEAT**: `results.sos.ga.gov/results/public/api/elections/baldwin-county-ga/{id}/data` carries the Nov 4 2025 municipal general as well as the 2024 general — nothing in Florida used this route, and a county with no contest returns **HTTP 204**, which is how the absence of a D2 runoff was proven. 🔴🔴 **THE OBVIOUS COUNCIL-DISTRICT SERVICE IS THE SUPERSEDED ONE AND ONLY ONE DISTRICT SAYS SO** — the city's own `City Council Districts (2025)` layer is a post-2020 plan; the county's `ElectionGeography` copy is 2021–2022; tested at all six interior points, **five agree and District 4 does not**, while the symmetric difference is non-zero on every district (D1 alone is 0.99 of ~20.4 sq mi). Three spot checks would have passed on the wrong map — GA-1's ruling repeating at city scale. 🔴🔴 **A LAYER TITLED "(2025)" CAN STILL CARRY A PRE-2025 ROSTER** — that same layer's `CouncilMem` field names the three predecessors; geometry vintage and attribute vintage are different questions about the same row. 🔴 **`EditDate` IS PER ROW AND IS THE TELL**: the county layer is right on all 5 commissioners (edited 2026-04-21) and wrong on 3 of 6 city seats (2021–2022), while still naming Joe Biden as President and carrying two contradictory US House rows. 🔴 **THE GMA DIRECTORY ACCUMULATES** — 9 councilmembers for a 6-seat council, with no `dateVacated` to separate them; usable only as a superset check. 🔴 **BALDWIN IS A FOURTH COUNTY CONVENTION IN FIVE COUNTIES**: 5 single-member seats, NO at-large, Chair elected by the Board (a parenthetical, not an office). ⚠ **THE PUBLISHED CHARTER IS CODIFIED THROUGH JANUARY 2014** and still says "MAYOR AND ALDERMEN", so the mayor's council vote is genuinely unestablished (R1 takes Bradenton's R2 and writes no unsourced note) and D2's exactly-50.0% win with no runoff is unexplained — plurality is the likely answer, unconfirmed. Municode's API 401s curl AND an in-page `fetch()`. **Cantrell ruled the Georgia county-officer template**: the four constitutional officers plus Coroner and Surveyor; Solicitor General excluded as a prosecutor, Chief Magistrate as judicial branch, the Ocmulgee Circuit DA and its five judges as MULTI-COUNTY. Zero reuses — all 18 are new rows, proven with a positive control after the collision check returned a suspicious uniform zero. Pre-state probe scores **2 of 4**; baselines `offices_missing_terms` **821/166/655**, GA `LOCAL` districts **0**, band `-1331999…-1331000` empty. | **Execute GA-3 Task 1** (load `X0042`, the 6 Milledgeville council districts, from the CITY's layer — not the county's). Then Task 2 (`X0043`). ⚠ Re-count `CC_0027` and `X0042` against every remote ref first. |
