# Knight Program — Florida Wave FL-5 (Palm Beach County) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Seat Palm Beach County — **12 offices, 12 people, 0 vacancies** — so that an address at the county Governmental Center returns its county commissioner, its state representative and its state senator, and every Palm Beach address also returns the five county constitutional officers.

**Architecture:** Four stages, and the smallest wave of the Florida slice. **There is no city half**, so this is a stage-4 wave on its own: one boundary loader (`X0039`, the seven commission districts), one roster file, and — per spec §3 — **ONE migration**, `CC_0014`, carrying offices and people together. The five constitutional officers hang off the county district that already exists for TIGER county `12099`. Acceptance is a **three**-answer probe, because the city slot is legitimately absent.

**Tech Stack:** TypeScript/Node 24, `tsx`, vitest, `psql` against the Supabase session pooler, PostGIS, ArcGIS FeatureServer REST.

**Spec:** `docs/superpowers/specs/2026-08-28-knight-cities-program-design.md`
**Slice notes:** `.planning/knight-foundation/fl.md` — read its **"▶️ FL-5 — Palm Beach County: what is already measured"** block first.
**Tracker:** `.planning/knight-foundation/PROGRAM.md`
**Prior waves:** `docs/superpowers/plans/2026-08-28-knight-fl-wave-4-tallahassee-leon.md` and
`docs/superpowers/plans/2026-08-28-knight-fl-wave-3-bradenton-manatee.md` — **read both "Deviations found during execution" sections before Task 1.** Between them they carry the four wrong versions of the `external_id` band guard, the `seat_officeholder()` NULL refusal, the dry-run recipe, and the rejected-PDF-parser lesson.

## Global Constraints

Everything in FL-3's and FL-4's Global Constraints still applies. These are the ones that changed or are new:

- **Migration namespace is `CC_`. This wave takes exactly ONE slot: `CC_0014`.** Measured 2026-08-28 with `check:migrations` green; `CC_0015` stays free. **Take the number LAST**: write as `CC_wip_palm_beach_county.sql`, then rename + apply + commit in one go.
- **Next free private MTFCC is `X0039`.** FL-3 took `X0036`/`X0037`, FL-4 took `X0038`. There is no central registry; each loader hardcodes its own.
- **No matview refresh is needed.** `check:child-county` maps only `G4110`, `G5400`, `G5410` and `G5420` children to counties. This wave loads only an `X` code, exactly like FL-3 and FL-4. Verify `check:child-county` green afterwards anyway.
- 🔴 **`12099` is Palm Beach County (`G4020`) AND State House District 99 (`G5220`).** Third instance in three waves, after `12081`/HD-81 and `12073`/HD-73. Pair `geo_id` with `mtfcc` **and** `district_type` in every join — **including throwaway diagnostic queries**, which is where this one was first hit while prepping `fl.md`.
- 🔴 **`essentials.seat_officeholder()` refuses a NULL `term_start`.** This wave has **no undated people**, so the direct-insert path is not exercised — but leave the block in the generator rather than deleting it, so FL-6 inherits it.
- 🔴 **An `external_id` band guard must be an ALLOWLIST scoped to THIS WAVE'S OWN contiguous sub-range**, not a count and not the whole band. `-(1240000 + n)` is the **shared Florida LOCAL band**: FL-3 and FL-4 legitimately own `-1240056 … -1240001` and must keep re-running clean. This is the fourth version of this guard; do not invent a fifth.
- 🔴 **To dry-run: turn the migration's OWN final `COMMIT` into `ROLLBACK` and leave its `BEGIN` alone.** `sed 's/^COMMIT;$/ROLLBACK;/' migrations/X.sql | psql "$DATABASE_URL"`. **Never strip `BEGIN;`/`COMMIT;`** — in FL-3 that `sed` also matched the outer wrapper and committed `CC_0008` to prod in autocommit.
- 🔴 **Re-run every applied migration in the slice, not just the new one.** That means all seven of `CC_0008` … `CC_0014`. Re-running only the new file is what let FL-3's band-guard defect survive for a day.
- **No party affiliation.** Discard it wherever it appears. The party guard regex must cover `(R)`, `(D)`, `(DEM)`, `(REP)`, `(NPA)`, `(I)` — FL-3's `\((R|D|NPA|I)\)` missed `(DEM)`, and Palm Beach's election-night feed prints `- REP` / `- DEM` suffixes on contest names.
- **No `term_end`.** No `end_precision` exists.
- **`districts.state` is lower case (`'fl'`); `governments.state` and `offices.representing_state` are
  UPPER (`'FL'`).** 🔴 **CORRECTED DURING TASK 1: `geofence_boundaries.state` is the 2-digit FIPS
  `'12'` for TIGER layers, but every PRIVATE `X`-code layer in this slice carries `'fl'`** — measured,
  `X0036`/`X0037`/`X0038` are all `'fl'`. Nothing joins on it for `X` codes
  (`check-address-reachability.mjs` joins `geo_id` only), so **follow the slice: `X0039` is `'fl'`.**
- **`outSR=4326` is load-bearing, and this service is a THIRD projection family.** Palm Beach publishes in **NAD83(HARN) StatePlane Florida East FIPS 0901, US survey feet** — not Manatee's EPSG:2237 and not Leon's EPSG:3857. Dropping `outSR` writes projected feet into a geographic column; nothing errors and every address probe simply comes back empty.
- **`curl` works for almost everything here.** Only `mypalmbeachclerk.com` returns a hard 403 (a full browser header set does not help). Leon needed Playwright for six hosts; Palm Beach needs it for one. Use Playwright for the Clerk only.
- **`cwd` resets between Bash calls.** Prefix every command with `cd /c/EV-Accounts/backend &&`.

---

## 🔴 Deviations found during execution — Task 1, 2026-08-28

`X0039` is **loaded**: 7 districts, all valid, all SRID 4326, anchor resolves to District 7, loader
re-runs as a clean no-op. `check:migrations`, `check:child-county` and `check:occupancy` all green;
`check:child-county` unchanged at 7,245 children / 0 stale, confirming that an `X`-code load needs no
matview refresh. Every measured literal in "Facts measured" held exactly. Four things are worth
recording.

1. 🔴 **THE PLAN HAD THE WRONG `geofence_boundaries.state` VALUE.** Global Constraints said `'12'`,
   the 2-digit FIPS, which is correct for TIGER layers — county `12099`/`G4020` is `'12'`. But every
   **private `X`-code** layer in this slice was written `'fl'`: `X0036`, `X0037` and `X0038` all are.
   `X0039` follows the slice. Nothing joins on the column for `X` codes, so this changed no behaviour,
   but a plan that contradicts three applied precedents is a plan that gets followed once and then
   argued with. Corrected in place.

2. 🔴 **THE GATE-5 FAILURE MODE DEPENDS ON WHETHER THE MISSING DISTRICT IS COASTAL, AND THE PLAN
   PREDICTED ONLY HALF OF IT.** The plan said dropping a district would make the tiling gate report
   **2 large gap parts**. Dropping **District 7** — which is coastal — does **not**: its area merges
   into the ocean gap and the count stays at **1**. What caught it was the **area band**: the gap grew
   to 208.1345 sq mi, outside the 150…160 window. Dropping **District 6**, which is landlocked, does
   produce 2 parts and 1,749.72 sq mi uncovered.
   **So the two assertions catch different failures and neither is redundant.** Had the gate carried
   only the part count — the assertion the plan called "load-bearing" — a missing coastal district
   would have passed. Both proofs are now in the plan's Step 6.

3. ⚠ **The stored geometry type is `ST_MultiPolygon`, not `ST_Polygon`.** All seven fetch as
   single-ring `Polygon`, but the insert wraps them in `ST_Multi()`, as Leon's loader does — and
   `X0036`/`X0037`/`X0038` are all `ST_MultiPolygon` in prod. Step 7's expectation was wrong and would
   have read as a failure. Corrected in place.

4. ⚠ **Gate 6 measures 0.2187 sq mi where planning measured 0.2359.** Both are far inside the 1.0
   tolerance. The difference is real and expected: planning compared the *whole* `ST_Difference` against
   the blank row, while the loader compares the *dumped biggest part* after `ST_MakeValid`, which drops
   the 0.0019-and-below noise slivers. The loader's number is the tighter one.

One thing the plan under-promised: **all seven polygons landed `ST_IsValid` with one part each and
needed no `ST_MakeValid`**, and the per-district areas matched the recorded literals to **0.00 %** on
all seven — tighter than Leon's cross-check and far tighter than Bradenton, where four of five wards
needed repair.

---

## Facts measured 2026-08-28 — do not re-derive these

### 🔴 There is no city half, and that changes the shape of the wave

Palm Beach County is the one Knight jurisdiction in Florida with no municipal wave. Consequences, each of which removes something FL-3 and FL-4 needed:

- **ONE migration, not three.** FL-3 and FL-4 each emitted city structure + city occupancy + county. FL-5 emits only the county file, which already carries offices and people together. `CC_0014` is the whole wave.
- **No `governments` row of type `City`, no city chamber, no city district, no place polygon to hang anything off.** TIGER place `1276600` (West Palm Beach) and `1254025` (Palm Beach town) exist in `geofence_boundaries` from FL-1 and stay unused.
- 🔴 **The acceptance probe has THREE required answers, not four**: county commissioner, state representative, state senator. **The city slot is legitimately absent — record that in the probe file itself**, so a later reader does not read a missing fourth answer as a failure. This is the same care FL-2 needed for Miami's vacant HD-113.
- **The anchor sits inside West Palm Beach place `1276600`**, and West Palm Beach is *not* seated. A reader who probes that address and sees no municipal official is seeing the truth: this program does not cover the City of West Palm Beach.

### 🔴 Palm Beach is a charter county, and its own page lists SEVEN "constitutional officers" — two of which this wave does not seat

Home rule charter effective **1985**. The county's own *Overview of County Government* page lists, verbatim:

> "Clerk​ of the Circuit Court & Comptroller​, Property Appraiser, Public Defender, Sheriff, State Attorney, Supervisor of Elections, Tax Collector"

🔴 **The State Attorney and the Public Defender are NOT county officers. They are officers of the 15th Judicial Circuit** (Fla. Const. art. V §§17–18), and this wave excludes them. The reason the publisher lists them at all is a coincidence of geography: **the 15th Judicial Circuit is coterminous with Palm Beach County**, so a Palm Beach voter does elect both. Leon County's 2nd Circuit spans **six** counties, which is exactly why Leon's Supervisor of Elections did not list them and FL-4 never faced the question.

Seating them on the `12099` `G4020` district would assert that the circuit equals the county. That is true today, and it is a fact about *circuit* boundaries, not county boundaries — a redraw of the circuits would silently make the record wrong, and nothing would error. It would also make Florida internally inconsistent, because Leon's voters elect a State Attorney too and FL-4 seated neither.

▶ **Program-level open work, not FL-5 work:** circuit-level elected offices (State Attorney, Public Defender) are a real, unmodelled class of countywide-elected official. A `JUDICIAL` scale already exists in the compass. Record this in `fl.md` and leave it.

**So Palm Beach's `Elected Officials` chamber is `official_count = 5`** — the same five as Manatee, and one fewer than Leon. **There is no elected Superintendent of Schools**: the Palm Beach County School District superintendent is appointed by the School Board. Three counties, three answers — Manatee 5, Leon 6, Palm Beach 5. **Never inherit the officer template.**

### The Board of County Commissioners — seven single-member districts, no at-large seats

The county's own page: *"Palm Beach County is governed by the seven-member Board of County Commissioners (BCC). One commissioner residing in each of seven districts shall be elected by the qualified electors residing within that district."*

**All seven are district seats.** This is the third convention in three counties:

| County | Commission shape |
| --- | --- |
| Manatee | 5 single-member + 2 at-large, called "District 6" and "District 7" |
| Leon | 5 single-member + 2 at-large, called "At Large, Group 1" and "At Large, Group 2" |
| **Palm Beach** | **7 single-member, no at-large seat at all** |

🔴 **So all seven commission offices hang off `X0039` polygons, and the pre-existing county district `12099`/`G4020` carries ONLY the five constitutional officers.** Leon's county district carries 8 (2 at-large + 6 officers) and Manatee's carries 7 (2 + 5). Palm Beach's carries **5**. A gate copied from FL-4 that asserts "at-large seats on the county district" has nothing to assert here and must be replaced, not loosened.

🔴 **Mayor and Vice Mayor are commission-elected ROLES, not offices.** The county page: *"The BCC elects a mayor to preside over commission meetings and serve as the ceremonial head… A vice mayor is also selected to assume these duties in the absence of the mayor."* They rotate annually — Commissioner Marino's own bio says she *"served as Mayor of Palm Beach County from November 2024 to November 2025"*, and Sara Baxter (D6) holds it now with Marci Woodward (D4) as Vice Mayor. **Same ruling as Bradenton's Vice Mayor and Asheville's, opposite of Nashville's Vice Mayor.** No `Office of the Mayor` chamber, no `voting_powers` ruling, no eighth title.

Term limits: **two consecutive four-year terms** for commissioners; **none** for the constitutional officers. Take-office rule: commissioners are *"sworn into office two weeks after being elected in the November general election"* — the same instant as Leon's "2nd Tuesday after the General Election", stated differently.

### The rosters as published, 2026-08-28

🔴 **Palm Beach has no single "Elected Officials" page.** Manatee's and Leon's Supervisors of Elections each published one document covering both bodies. Palm Beach's does not — `votepalmbeach.gov` offers only Candidates / Elections / Records, and there is no roster anywhere on it. **The roster must be assembled from each office's own site.** Budget for that in Task 2; it is the single biggest cost difference from FL-4.

**Board of County Commissioners** — seven seats, all filled, no vacancy.

| Seat | Incumbent | `term_start` | Precision | Source |
| --- | --- | --- | --- | --- |
| District 1 | Maria G. Marino | `2020-11-01` | month | own bio: "Elected to the Palm Beach County Commission in 2020 and again in 2024" |
| District 2 | Gregg K. Weiss | `2018-11-01` | month | own bio: "elected to the District 2 seat … in November 2018 and was reelected in 2022" |
| District 3 | Joel G. Flores | `2024-11-01` | month | ⚠ **NOT in his bio** — see below |
| District 4 | Marci Woodward | `2022-11-01` | month | own bio: "elected in November 2022 … and currently serves as Vice Mayor" |
| District 5 | Maria Sachs | `2022-11-01` | month | ⚠ **NOT in her bio** — see below |
| District 6 | Sara Baxter | `2022-11-01` | month | ⚠ **NOT in her bio** — see below |
| District 7 | Bobby Powell Jr. | `2024-11-01` | month | own bio: "In November 2024, Bobby Powell Jr. was elected to the Palm Beach County Board of County Commissioners" |

**Elected Officials** — five seats, all filled, no vacancy.

| Office | Incumbent | `term_start` | Precision | `how_started` | Source |
| --- | --- | --- | --- | --- | --- |
| Clerk of the Circuit Court & Comptroller | **Shannon Ramsey-Chessman** | `2026-08-18` | **day** | **appointed** | the Clerk's own site: "Shannon Ramsey-Chessman Named Clerk Ad Interim" — see below |
| Property Appraiser | Dorothy Jacks | `2017-01-01` | month | elected | own bio: "elected as Palm Beach County's Property Appraiser in 2016" |
| Sheriff | Ric Bradshaw | `2005-01-04` | **day** | elected | own bio: "On January 4, 2005, Sheriff Bradshaw was sworn in as Sheriff of Palm Beach County" |
| Supervisor of Elections | Wendy Sartory Link | `2019-01-01` | year | **appointed** | own page: "First appointed in 2019, elected in 2020, and re-elected in 2024" |
| Tax Collector | Anne M. Gannon | `2007-01-01` | month | elected | own bio: "Elected in 2006" — ⚠ see the contradiction below |

**Total: 7 + 5 = 12 offices, 12 people, 0 vacancies.**

**Date precision: day 2, month 9, year 1, unknown 0.** 🔴 **This would be the first Florida wave with ZERO unknown-precision starts** — FL-3 had 3 of 17, FL-4 had 9 of 18. Do not let that slip into a guess: if Task 2 cannot source a date, `unknown` remains the honest answer. Three of the twelve are one confirmation away and this plan expects them found.

The commission's take-office rule turns each November year into a derivable day, written down here **as corroboration only, not as the value to insert**: 2018-11-20, 2020-11-17, 2022-11-22, 2024-11-19. **Insert `month` precision (`YYYY-11-01`), matching Leon.** The county does not publish a per-person swearing-in date; a mis-stated rule would produce a confidently wrong day, and `month` is what the evidence actually supports.
▶ Follow-up, shared with FL-4: the BCC's January organisational minutes would date all seven precisely.

### 🔴 Three of seven commissioner bios do not date their own incumbent — because the page still carries the PREDECESSOR'S bio

This is the FL-4 rejected-parser lesson in a new form, and it is worse, because the failure is silent and *plausible*.

`discover.pbc.gov/countycommissioners/<district>/Pages/Biography.aspx` concatenates the sitting commissioner's biography with the previous commissioner's, **unlabelled and unseparated**. Measured:

| Page | Incumbent text | Stale text that follows it |
| --- | --- | --- |
| District 6 | Sara Baxter — no election date given anywhere | *"Palm Beach County Commissioner Melissa McKinlay was first elected in 2014."* McKinlay left in 2022. |
| District 7 | *"In November 2024, Bobby Powell Jr. was elected…"* | *"Mack Bernard was elected in November 2016 to the Palm Beach County Commission, District 7."* |

🔴 **A regex for "elected in `<year>`" over District 7's page returns 2016 — Mack Bernard's date, not Bobby Powell's.** It is the right shape, on the right page, under the right district heading, and it is wrong by eight years. District 3's page gives Joel Flores no commission date at all, only *"He served as the Mayor of the City of Greenacres from 2017 to 2024."*

**Task 2 must read these pages by eye, not by regex**, and must source Flores, Sachs and Baxter from somewhere else — the Supervisor of Elections' certified-results index, or the county's own press release for each swearing-in.

⚠ Two more small traps on the same site: the district URL casing is inconsistent (`district1`, `district2`, `district3`, `district4`, **`District5`** with a capital D, `district6`, `district7`), and every page's extracted text begins with the full site navigation, which contains the literal strings "District 1" … "District 7" and will match a naive district-scoping regex.

### 🔴🔴 Bobby Powell Jr. and Mack Bernard TRADED SEATS, and one of them is already in prod

- **Mack Bernard** was the District 7 commissioner. He is now **State Senator, SD-24** — seated by FL-2 as `external_id = -1230024`, and he is **already in `essentials.politicians`**.
- **Bobby Powell Jr.** was the SD-24 state senator. He is now the **District 7 commissioner**, and he is **not** in prod. Fresh insert.

🔴 **A "reuse the existing person if the name matches" step reading `County_Commission_Districts`' `NAME` field would seat the sitting state senator on the county commission**, because that layer's roster still says `MACK BERNARD` for District 7. Nothing would error: `office_terms` would accept it, and Bernard would appear holding two offices.

**Name-collision check, measured 2026-08-28 against all twelve names:** exactly one hit, and it is Mack Bernard — who is not on this roster. **All twelve people in this wave are fresh inserts.** The only other matches were FEC ALLCAPS committee junk (`MC CAMMACK FOR SAN BERNARDINO…`), which the dedupe rules already exclude.

### 🔴 The Clerk's seat — the one modelling decision in this wave

Public record, and it is ten days old:

- **Joseph Abruzzo**, elected Clerk from 2021-01-05, **resigned in June 2025** and is now the appointed County Administrator.
- **Michael A. "Mike" Caruso** was **appointed** Clerk by the Governor and sworn in **2025-08-19**.
- **2026-08-18: the Governor suspended Caruso.** He was **suspended, not removed** — under Fla. Const. art. IV §7 the Senate ultimately removes or reinstates.
- **The same day, Chief Judge Glenn Kelley of the 15th Judicial Circuit appointed the office's chief deputy clerk, Shannon Ramsey-Chessman, as "Clerk Ad Interim", effective 2026-08-18.** Her own office publishes her under that title.

**This plan seats Shannon Ramsey-Chessman**, `term_start = 2026-08-18`, `start_precision = 'day'`, `how_started = 'appointed'`.

The reasoning, because a later reader will need it:

- The voter-facing question the record answers is *"who is my Clerk?"*. Someone is doing the job, by court order, and her own office says so. Displaying a suspended officer who cannot act would be a false statement about a real person.
- `is_vacant` is **wrong** here. A vacancy means nobody holds the seat; this seat is held.
- **Caruso's own closed term is deliberately NOT written**, though every date for it is known. FL-2 wrote no predecessor terms for any of its five legislative vacancies and FL-3 wrote none for Carol Ann Felts; writing one here would leave Florida internally inconsistent. It also has no honest enum value: `how_ended` offers `removed`, and he was not removed.
  ▶ **Adds to the existing open item:** write predecessor terms for all Florida vacancies and interruptions together. The evidence for Caruso and Abruzzo goes in `ROSTERS.md`.
- `offices.description` on this one office records the chain in plain words: the elected officer was suspended by the Governor on 2026-08-18 and remains suspended rather than removed; the chief judge appointed the chief deputy clerk as Clerk Ad Interim under administrative order effective the same day. Keep it factual and brief — do not restate the criminal allegations in the repo.

⚠ **The rejected alternative, recorded so it is not re-litigated:** flag the office `is_vacant = true, vacant_since = 2026-08-18` and write no term. That matches FL-3's Felts handling and one same-day news framing ("the office remains vacant"). It was rejected because Felts had died and nobody was performing the office, whereas here a named person is, and `is_vacant` would tell a Palm Beach voter there is no Clerk.

🔴 **This seat is live. Task 2 Step 4 must re-check it immediately before applying** — the Senate can act, the Governor can appoint over the interim appointment, or Caruso can be reinstated. Switching to the vacancy treatment must be a one-row change in `ROSTERS.md`, with no generator edit.

⚠ **Two of the five officers were appointed, not elected** (Link 2019, Ramsey-Chessman 2026). This is the first Florida wave to write `how_started = 'appointed'`. The value is valid — the CHECK admits `elected | appointed | succeeded | redistricted | unknown`, and prod holds 79 `appointed` rows against 769 `elected`.

⚠ **One source contradiction to resolve, not to guess at.** Anne Gannon's page says *"Elected in 2006"* and also *"currently serving her sixth term"*; four-year terms from 2006 give five terms by 2026, not six. `fl.md` separately records, from Manatee, that **Florida county officers run on the presidential cycle**. The 2026 Palm Beach primary carried **no** constitutional-officer contest — measured from the county's own election-night feed, which listed only BCC Districts 2 and 6, two school-board seats and three special districts — and that confirms the presidential cycle for Palm Beach too. So "elected in 2006" is either a special election or a page error. **Write `2007-01-01` `month` only if Task 2 corroborates the start; otherwise write `unknown` rather than reconcile the arithmetic yourself.**

### ⚠ Four of the seven commission seats are on the November 2026 ballot

Measured from the county's own election-night feed for the 2026 primary: Districts **2** and **6** had contested primaries, and District 2's is a **Universal Primary Contest**, meaning that seat was decided in August. Districts 4 and 5 are also up (elected 2022) but drew no contested primary. **Gregg Weiss is term-limited** — 2018 plus 2022 is his two consecutive terms.

This wave seats the **current** holders, which is correct. But the roster's shelf life is about ten weeks. ▶ Record in `fl.md` that Palm Beach needs a re-check after the November 2026 general, before FL-7 assets.

### Geography — three services, and the primary is the only one that is both current and correct

Base org: `https://services1.arcgis.com/ZWOoUZbtaYePLlPw/arcgis/rest/services`

| Service / layer | Rows | District field | `NAME` roster | Verdict |
| --- | --- | --- | --- | --- |
| **`Commissioner_Districts/FeatureServer/0`** (`ENG.COMM_DIST_PY`) | **7** | `DISTRICT` **SmallInteger** | **current** | ✅ **PRIMARY** — the layer behind the county's open-data "County Commission Districts" entry |
| `County_Commission_Districts/FeatureServer/0` | 7 | `DISTRICT` SmallInteger | **STALE** — names Dave Kerner (D3, left 2022) and Mack Bernard (D7) | ⚠ near-copy, not an independent digitization |
| `CountyCommission_2022/FeatureServer/0`, layer named **`CountyCommission_2026`** | **8** | `CC` **text** | `Name` = "District 1"… | ✅ **CROSS-CHECK** — genuinely independent |

🔴 **The service named `CountyCommission_2022` contains a layer named `CountyCommission_2026`.** The service name and the layer name disagree about vintage. Neither is authority for which map is operative; the geometry cross-check is. **Do not pick a service by its name.**

⚠ The county also runs `https://gis.pbcgov.org/arcgis/rest/services`, whose `PBCADM` and `CORE` folders are **empty to anonymous callers** and whose `ADM` folder answers `499 Token Required`. Do not spend time there; the AGOL org above is the public route.

**Measured, all three reprojected to 4326 — symmetric difference per district, sq mi:**

| District | vs `County_Commission_Districts` | vs `CountyCommission_2026` |
| --- | --- | --- |
| 1 | 0.0000 | 0.4900 |
| 2 | **0.0249** | 0.0538 |
| 3 | 0.0000 | 0.0181 |
| 4 | 0.0000 | 0.1683 |
| 5 | 0.0000 | 0.0540 |
| 6 | 0.0000 | 0.7313 |
| 7 | **0.0249** | 0.0744 |

`County_Commission_Districts` is the same digitization as the primary on five of seven and differs by 0.0249 sq mi on the shared D2/D7 line — a stale copy with a slightly older boundary, **not** a control. `CountyCommission_2026` differs on all seven by a total of 1.59 sq mi against 2,227.67 — **0.07 %**, which is what two genuine digitizations of one boundary look like. 🔴 **Use a tolerance, never `ST_Equals`.**

🔴 **`CountyCommission_2026` returns EIGHT rows, and the eighth is BLANK** (`CC = ' '`, `Name = ' '`). It is **155.6952 sq mi at `-80.0091, 26.6456`** — the Atlantic Ocean. A cross-check keyed on `CC` must skip it explicitly; a row-count gate of 7 against that service fails on correct data.

### 🔴 The seven districts do NOT tile the TIGER county — 155.54 sq mi is the ocean

Measured against `geofence_boundaries` `12099`/`G4020`:

| Quantity | Value |
| --- | --- |
| Sum of the 7 district areas | 2,227.681 sq mi |
| Union of the 7 | 2,227.669 sq mi (self-overlap **0.012**) |
| TIGER county `12099` | 2,383.201 sq mi |
| **Uncovered** | **155.5381 sq mi** |
| Overhang (union outside the county) | **0.0060 sq mi** |

🔴 **A tiling gate copied from FL-4 fails here, on a correct layer** — exactly the Bradenton lesson, at county scale and 600× larger. Leon's five districts left 0.0040 sq mi uncovered; Palm Beach's seven leave 155.54.

**The uncovered area is one coherent part**, 155.5209 sq mi with an interior point at `-80.0090, 26.6436` — offshore, east of West Palm Beach. Everything else uncovered is digitization noise: the next-largest part is **0.0019 sq mi**. TIGER's county polygon runs out to the state's Atlantic limit; the commission districts stop at the shoreline. **Lake Okeechobee's Palm Beach share is inside District 6** and is not part of the gap.

🔴 **`CountyCommission_2026`'s blank row confirms this independently**: the gap and that blank polygon have a symmetric difference of **0.2359 sq mi**, 0.15 % of either. Two publishers, two digitizations, the same offshore polygon — one leaves it out of the districts, the other carries it as unassigned. So the loader gates on **structure**, not on a fudged tolerance:

1. overhang ≤ **0.05** sq mi (measured 0.0060) — the districts never leave the county;
2. self-overlap ≤ **0.05** sq mi (measured 0.012);
3. the uncovered area decomposes into **exactly one part above 0.05 sq mi**, and that part's interior point lies east of `lon = -80.05` (measured: one part, 155.5209 sq mi, at `-80.0090`);
4. that part matches the cross-check service's blank row to ≤ **1.0** sq mi (measured 0.2359).

Gate 3 is the load-bearing one: it says *"the only thing missing is the sea"* instead of *"155 sq mi of slop is acceptable"*. A district quietly dropped from the service would add a second large part and fail it.

**Per-district areas and control points, all measured; every point verified to fall inside exactly one district:**

| District | sq mi | Control point (lon, lat) |
| --- | --- | --- |
| 1 | 304.108 | -80.249834, 26.835495 |
| 2 | 84.413 | -80.150363, 26.669630 |
| 3 | 36.644 | -80.116475, 26.624964 |
| 4 | 65.772 | -80.109651, 26.458135 |
| 5 | 89.944 | -80.175017, 26.441057 |
| 6 | 1594.186 | -80.529972, 26.646274 |
| 7 | 52.612 | -80.039961, 26.623871 |

⚠ **District 6 is 1,594 sq mi — 72 % of the county** (the western Glades and the Lake Okeechobee shore); District 3 is 36.6. A percentage tolerance is fine; an absolute one is not.

**Negative controls, both measured at 0 hits against all seven districts:** Fort Lauderdale `-80.1373, 26.1224` (Broward, immediately south) and the city of Okeechobee `-80.4550, 27.4467` (Okeechobee County, north-west across the lake). Two directions, both across a real county line.

**All seven polygons are `ST_IsValid`, single-part, single-ring — no `ST_MakeValid` needed.** Same as Leon, unlike Bradenton where four of five needed repair. Re-check from the **database** after insert anyway; that discipline is right even when it has nothing to catch.

⚠ **`Shape__Area` is in the service's own US survey feet and is NOT the value to gate on.** District 6 stretches far west of StatePlane Florida East's zone of best fit. Compute areas from the reprojected 4326 geometry via `::geography`, which is what the table above is.

⚠ **`DISTRICT` is a SmallInteger here.** Manatee's was an integer, Leon's was **text**, and FL-4's loader parses with a regex on a trimmed string — which still works on `String(7)`. Keep the string-regex parse; do not reintroduce `Number.isInteger()`.

### 🔴 The anchor — Palm Beach County Governmental Center

**301 North Olive Avenue, West Palm Beach FL 33401.** Geocodes cleanly, exactly one Census match:
`301 N OLIVE AVE, WEST PALM BEACH, FL, 33401` → **`-80.051906016174, 26.71529321541`**.

| Answer | Value | Holder |
| --- | --- | --- |
| County commissioner | **District 7** | Bobby Powell Jr. |
| State representative | **HD-87** | Emily Gregory (seated by FL-2) |
| State senator | **SD-24** | Mack Bernard (seated by FL-2) |
| ~~City~~ | **legitimately absent** | West Palm Beach is not in scope |

Plus, from every Palm Beach address, the five constitutional officers on the countywide district. **The probe returns more rows than the three required answers, and that is correct.** Assert the three **by name**, the way FL-4's probe 1a does, so the count never has to be interpreted.

⚠ **A pleasing cross-check, and a warning.** HD-87 is the seat **Mike Caruso resigned** in August 2025 to become Clerk; Emily Gregory holds it now. Two of this wave's facts are linked by one person's move, and prod already carries the post-special-election answer. It also means HD-87 changed recently — if FL-2's row ever looks wrong, this is why.

### 🔴 The collision demo at this anchor is the richest in the slice — THREE wrong rows

An unpaired `geo_id` join at the Governmental Center returns six district rows, of which three are correct:

| label | matched through | why it is wrong |
| --- | --- | --- |
| Palm Beach County | `12099` `G4020` | correct |
| State House District 87 | `12087` `G5220` | correct — Emily Gregory |
| State Senate District 24 | `12024` `G5210` | correct — Mack Bernard |
| **Monroe County** | `12087` `G5220` | HD-87's `sldl` polygon → a **county** in the Florida Keys, ~200 miles away |
| **State House District 24** | `12024` `G5210` | SD-24's `sldu` polygon → an `sldl` **district** — Ryan Chamberlin, north-central Florida |
| **State House District 99** | `12099` `G4020` | **Palm Beach County's own polygon** → Daryl Campbell, Broward County |

All three failure directions in one query: `sldl` polygon → county district, `sldu` polygon → `sldl` district, and county polygon → `sldl` district. Nothing errors. **Keep this inline in the probe file as its own numbered probe**, the way FL-3 and FL-4 do, so the failure stays visible rather than remembered.

### Prod state, measured 2026-08-28

| Thing | State |
| --- | --- |
| Palm Beach County district (`12099`/`G4020`/`COUNTY`, label `Palm Beach County`) | **exists** — reuse, do not create. `num_officials` is NULL, as it is on Leon's and Manatee's; **leave it NULL.** |
| County polygon (`12099`/`G4020`) | exists, 2,383.201 sq mi |
| West Palm Beach place `1276600`, Palm Beach town `1254025` | exist (FL-1), unused by this wave |
| Offices on the county district | **ZERO** — greenfield |
| `governments` row for `12099` | **absent** — this wave creates it |
| `X0039` boundaries | 0 |
| Name collisions among the 12 | **ZERO** (one near-hit: Mack Bernard, who is not on this roster) |
| `external_id` band `-(1240000 + n)` | 35 rows used, occupying `-1240056 … -1240001` |
| `offices_missing_terms` | 820 total / 165 flagged / **655 unflagged** against a 699 threshold |
| Next free migration slot | `CC_0014` |
| Next free private MTFCC | `X0039` |

**`external_id`: continue `-(1240000 + n)`, taking `n = 61…67` for the commission and `n = 71…75` for the officers** — the contiguous sub-range `-1240075 … -1240061`, leaving a deliberate gap above FL-4's `n = 56`. The band guard allowlists exactly those 12 ids and must not trip on FL-3's or FL-4's 35.

### Template rows

`governments`:

| name | type | state | city | geo_id |
| --- | --- | --- | --- | --- |
| `Palm Beach County, Florida, US` | `County` | `FL` | *(NULL)* | `12099` |

`chambers` — ⚠ **`slug` is GENERATED from `name_formal` and cannot be inserted.**

| government | name | name_formal | official_count |
| --- | --- | --- | --- |
| Palm Beach | `Board of County Commissioners` | `Palm Beach County Board of County Commissioners` | 7 |
| Palm Beach | `Elected Officials` | `Palm Beach County Elected Officials` | 5 |

`districts`:

| label | district_type | geo_id | mtfcc | num_officials |
| --- | --- | --- | --- | --- |
| `Palm Beach County Commissioner District 1` … `District 7` | `COUNTY` | `palm-beach-fl-commissioner-district-1` … `-7` | `X0039` | 1 |

`offices` — titles follow Leon's seated convention exactly, which is the house style:

| chamber | titles |
| --- | --- |
| Board of County Commissioners | `Commissioner, District 1` … `Commissioner, District 7` |
| Elected Officials | `Clerk of the Circuit Court & Comptroller`, `Property Appraiser`, `Sheriff`, `Supervisor of Elections`, `Tax Collector` |

⚠ **Leon's Clerk is titled `Clerk of the Circuit Court and Comptroller` — spelled out — and Palm Beach's own office brands itself with an ampersand.** Follow the publisher, per the rule that gave Manatee "District 6" and Leon "At Large, Group 1". Nothing joins on `title`, so the divergence costs nothing; **record it in `fl.md` so a later reader does not file it as drift.**

All twelve offices are `voting_powers = 'full'`, `representing_state = 'FL'`.

### Decisions this plan makes

1. **State Attorney and Public Defender are NOT seated**, though the county lists them among its constitutional officers, because they are 15th Judicial Circuit offices that only look countywide. Recorded as program-level open work.
2. **No elected Superintendent of Schools** — Palm Beach's is appointed by the School Board. `official_count = 5`, not Leon's 6.
3. **Mayor and Vice Mayor are annual commission-elected roles, not offices.** No third chamber, no `voting_powers` ruling.
4. **The Clerk's seat is held, by Shannon Ramsey-Chessman from 2026-08-18, `appointed`** — not flagged vacant, and no predecessor term is written. Full reasoning above.
5. **Commissioner `term_start` is `month` precision at `YYYY-11-01`**, matching Leon, even though the take-office rule makes a day derivable.
6. **The tiling gate asserts structure, not slack**: overhang, self-overlap, and "exactly one uncovered part, and it is offshore".

### Out of scope, considered

Palm Beach County School Board (7 elected, by district); State Attorney and Public Defender of the 15th Judicial Circuit; the Soil and Water Conservation District; the Greater Boca Raton Beach and Park District, Jupiter Inlet District and Indian Trail Improvement District (all elected, all on the county's own 2026 ballot, none a county commission or constitutional officer); every municipality in the county, West Palm Beach included.

---
## Task 1: Palm Beach commission district boundaries — load 7 districts as `X0039`

**Files:**
- Create: `backend/scripts/load-palm-beach-commission-boundaries.ts`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: 7 rows in `essentials.geofence_boundaries`, `mtfcc = 'X0039'`, `state = 'fl'`,
  `geo_id = 'palm-beach-fl-commissioner-district-' || n` for `n` in 1..7. Task 3's migration joins on
  exactly those three values and refuses to run if they are absent.

- [ ] **Step 1: Copy the Leon loader — it is the closest template**

```bash
cd /c/EV-Accounts/backend && cp scripts/load-leon-commission-boundaries.ts scripts/load-palm-beach-commission-boundaries.ts
```

Read it end to end first. Keep its shape: a primary service, a cross-check against a second
independently-published digitization, per-district area gates, control points, a negative control, and
a tiling gate. **Drop its city-limits control** — that was Leon's free bonus and Palm Beach has no city
half. **Replace its tiling gate**, per Step 5.

- [ ] **Step 2: Re-point the constants**

```ts
const ORG = 'https://services1.arcgis.com/ZWOoUZbtaYePLlPw/arcgis/rest/services';

/** The layer behind the county's own open-data "County Commission Districts" entry. */
const PRIMARY_URL =
  `${ORG}/Commissioner_Districts/FeatureServer/0/query` +
  '?where=1%3D1&outFields=DISTRICT' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

/**
 * Independent digitization. THE SERVICE IS NAMED 2022 AND ITS LAYER IS NAMED 2026.
 * Neither name is authority for the vintage; the geometry comparison is.
 * IT RETURNS EIGHT ROWS. The eighth has CC = ' ' and is the Atlantic Ocean.
 */
const CROSSCHECK_URL =
  `${ORG}/CountyCommission_2022/FeatureServer/0/query` +
  '?where=1%3D1&outFields=CC' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

const MTFCC = 'X0039';
const STATE_FIPS = '12';
const SOURCE = 'pbcgov-agol-Commissioner_Districts-0-2026-08-28';
const GEO_ID_PREFIX = 'palm-beach-fl-commissioner-district-';
const COUNTY_GEO_ID = '12099';
const EXPECTED_COUNT = 7;
const DISTRICTS = ['1', '2', '3', '4', '5', '6', '7'] as const;
```

🔴 **Do NOT use `County_Commission_Districts`** (the near-identical third service). Its `NAME` field
still reads `DAVE KERNER` for District 3 and `MACK BERNARD` for District 7, and its geometry is a
slightly older copy of the primary rather than an independent digitization. It is a decoy, not a
control.

⚠ **The primary carries a `NAME` field too, and today it happens to be current.** That is luck, not a
reason to read it. `fl.md`'s rule stands: **never read a roster out of a boundary layer.** The loader
must not request `NAME` at all — Task 2 gets the roster from the publishers.

- [ ] **Step 3: Parse the district key as a trimmed string, and skip the blank cross-check row**

`DISTRICT` is a **SmallInteger** on the primary and `CC` is **text** on the cross-check. The Leon
loader's trimmed-string regex handles both; keep it, and add the blank skip:

```ts
function districtKey(props: Record<string, unknown>, field: string): string | null {
  const raw = String(props[field] ?? '').trim();
  if (raw === '') return null;            // CountyCommission_2026's 8th row: the Atlantic
  return /^[1-7]$/.test(raw) ? raw : null;
}
```

Count the skipped rows and log them. **Expect exactly 0 skipped on the primary and exactly 1 on the
cross-check.** A different number on either side means the service changed shape; abort rather than
proceed.

- [ ] **Step 4: Set the per-district area expectations and the control points**

```ts
/** Measured 2026-08-28 from the reprojected 4326 geometry via ::geography. */
const EXPECTED_SQ_MI: Record<string, number> = {
  '1':  304.108,
  '2':   84.413,
  '3':   36.644,
  '4':   65.772,
  '5':   89.944,
  '6': 1594.186,   // the western Glades — 72% of the county
  '7':   52.612,
};

/** Every point verified 2026-08-28 to fall inside exactly one district. */
const CONTROL_POINTS = [
  { name: 'District 1 interior', lon: -80.249834, lat: 26.835495, district: '1' },
  { name: 'District 2 interior', lon: -80.150363, lat: 26.669630, district: '2' },
  { name: 'District 3 interior', lon: -80.116475, lat: 26.624964, district: '3' },
  { name: 'District 4 interior', lon: -80.109651, lat: 26.458135, district: '4' },
  { name: 'District 5 interior', lon: -80.175017, lat: 26.441057, district: '5' },
  { name: 'District 6 interior', lon: -80.529972, lat: 26.646274, district: '6' },
  { name: 'District 7 interior', lon: -80.039961, lat: 26.623871, district: '7' },
  { name: 'PBC Governmental Center', lon: -80.051906016174, lat: 26.71529321541, district: '7' },
];

/** Two directions, both across a real county line. Both measured at 0 hits. */
const NEGATIVE_CONTROLS = [
  { name: 'Fort Lauderdale, Broward County', lon: -80.1373, lat: 26.1224 },
  { name: 'City of Okeechobee, Okeechobee County', lon: -80.4550, lat: 27.4467 },
];

const AREA_TOLERANCE_PCT = 1;
const CROSSCHECK_TOLERANCE_SQ_MI = 1.0;   // measured max 0.7313 on District 6
```

⚠ **A percentage tolerance, not an absolute one.** District 6 is 1,594 sq mi and District 3 is 36.6;
1 % of the first is 43× 1 % of the second.

⚠ **`Shape__Area` is US survey feet in a StatePlane zone District 6 falls well outside.** Never gate
on it. Measure from the stored 4326 geometry with `::geography`.

- [ ] **Step 5: Replace the tiling gate — the districts stop at the shoreline**

The Leon gate ("uncovered ≤ 0.25 sq mi against the TIGER county") **fails here on correct data**:
155.5381 sq mi of TIGER county `12099` is Atlantic Ocean that no commission district claims. Widening
the tolerance to 156 would accept a whole missing district. Gate on structure instead:

```sql
WITH u   AS (SELECT ST_Union(geometry) AS g FROM essentials.geofence_boundaries
              WHERE mtfcc = $1 AND state = $2),
     c   AS (SELECT geometry AS g FROM essentials.geofence_boundaries
              WHERE geo_id = $3 AND mtfcc = 'G4020'),
     gap AS (SELECT (ST_Dump(ST_Difference(c.g, u.g))).geom AS g FROM c, u),
     big AS (SELECT g, ST_Area(g::geography)/2589988.110336 AS sq_mi FROM gap
              WHERE ST_Area(g::geography)/2589988.110336 > 0.05)
SELECT
  (SELECT round((ST_Area(ST_Difference(u.g, c.g)::geography)/2589988.110336)::numeric, 4) FROM c, u)
    AS overhang_sq_mi,
  (SELECT round(((SUM(ST_Area(geometry::geography)) - ST_Area(ST_Union(geometry)::geography))
                 /2589988.110336)::numeric, 4)
     FROM essentials.geofence_boundaries WHERE mtfcc = $1 AND state = $2)
    AS self_overlap_sq_mi,
  (SELECT count(*) FROM big)                                              AS big_gap_parts,
  (SELECT round(sq_mi::numeric, 4) FROM big ORDER BY sq_mi DESC LIMIT 1)  AS biggest_gap_sq_mi,
  (SELECT round(ST_X(ST_PointOnSurface(g))::numeric, 4) FROM big ORDER BY sq_mi DESC LIMIT 1)
    AS biggest_gap_lon;
```

Assert all five, and fail the loader on any one:

| Assertion | Threshold | Measured 2026-08-28 |
| --- | --- | --- |
| `overhang_sq_mi` | ≤ 0.05 | 0.0060 |
| `self_overlap_sq_mi` | ≤ 0.05 | 0.012 |
| `big_gap_parts` | **= 1** | 1 |
| `biggest_gap_lon` | **> -80.05** (offshore) | -80.0090 |
| `biggest_gap_sq_mi` | 150 … 160 | 155.5209 |

Then the assertion that makes the gap *explained* rather than tolerated — compare it against the
cross-check service's blank row:

```
symdiff( biggest gap part , CountyCommission_2026 row where CC is blank )  <=  1.0 sq mi
```

Measured **0.2359**. Print the failure message in full when it trips:

> `The 7 districts leave <N> large uncovered parts, not 1. The one legitimate gap is the Atlantic`
> `Ocean east of lon -80.05 (155.52 sq mi, independently carried as the blank CC row of`
> `CountyCommission_2026). A second large part means a district is missing from the service — do NOT`
> `widen this tolerance.`

- [ ] **Step 6: Dry-run, prove two gates can fail, then load**

```bash
cd /c/EV-Accounts/backend && npx tsx scripts/load-palm-beach-commission-boundaries.ts --dry-run
```

Then **prove the gates are live**, the way FL-3 and FL-4 did — a gate never seen to fail is not known
to work:

1. Temporarily set `EXPECTED_SQ_MI['6']` to `1500` and confirm the area gate fails District 6 with a
   percentage in the message. Revert.
2. Temporarily drop a district from `DISTRICTS` and confirm the tiling gate refuses to write.
   🔴 **WHICH assertion fires depends on whether the district is COASTAL — proved during Task 1.**
   Removing **District 7** (coastal) merges its area into the ocean gap, so the part count stays at
   **1** and the **area band** catches it (208.13 sq mi, outside 150…160). Removing **District 6**
   (inland) produces a genuine second part and the **part-count** assertion catches it (2 parts,
   1,749.72 sq mi uncovered). **Test one of each; both assertions are load-bearing and neither
   alone is sufficient.** Revert. (Do this on a throwaway copy under `scripts/_gateproof-*.ts`
   rather than editing the real loader, and delete the copies afterwards.)

Then load for real:

```bash
cd /c/EV-Accounts/backend && npx tsx scripts/load-palm-beach-commission-boundaries.ts
```

- [ ] **Step 7: Verify the loaded geometry from the DATABASE, not from the fetch**

Every gate in Step 5 runs against what was fetched. Re-read what was **stored**:

```bash
cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -At -F ' | ' -c "
SELECT geo_id,
       ST_GeometryType(geometry), ST_IsValid(geometry), ST_NumGeometries(geometry),
       ST_SRID(geometry),
       round((ST_Area(geometry::geography)/2589988.110336)::numeric, 3) AS sq_mi
  FROM essentials.geofence_boundaries
 WHERE mtfcc = 'X0039' ORDER BY geo_id;"
```

Expect 7 rows, every one **`ST_MultiPolygon`** (🔴 **corrected during Task 1** — the insert wraps the
geometry in `ST_Multi()`, as Leon's loader does; `X0036`/`X0037`/`X0038` are all `ST_MultiPolygon`
too), `t`, `1` part, **`4326`**, with areas matching the Step 4 table to
three decimals. 🔴 **`ST_SRID = 4326` is the check that catches a dropped `outSR`** — projected US
survey feet would store without error and every probe would come back empty.

- [ ] **Step 8: Commit**

```bash
cd /c/EV-Accounts && git add backend/scripts/load-palm-beach-commission-boundaries.ts && git commit -F .git/COMMIT_FL5_T1 -- backend/scripts/load-palm-beach-commission-boundaries.ts
```

Commit message:

```
feat(knight-fl): load Palm Beach's 7 commission districts as X0039

All seven seats are single-member — Palm Beach has no at-large commissioner, so
the countywide district carries only the five constitutional officers. Manatee
and Leon both have 5 + 2.

The districts do NOT tile the TIGER county: 155.54 sq mi of 12099 is Atlantic
Ocean that no district claims. The gate asserts structure — exactly one large
uncovered part, offshore, matching the blank row that CountyCommission_2026
carries for the same water — rather than a tolerance wide enough to hide a
missing district.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
```

---
## Task 2: Reconcile the roster and write `ROSTERS.md`

**Files:**
- Create: `backend/data/seed-palm-beach-2026/ROSTERS.md`
- Create: `backend/data/seed-palm-beach-2026/_bcc-d1.html` … `_bcc-d7.html`, `_off-clerk.html`,
  `_off-pao.html`, `_off-sheriff.html`, `_off-soe.html`, `_off-tax.html` (working copies, **not**
  committed)

**Interfaces:**
- Consumes: nothing from Task 1.
- Produces: `ROSTERS.md` in **exactly the format `parseRosters` already reads** — one markdown table
  under the heading `### Palm Beach County`, with the columns
  `Seat | Slug | Name | external_id | term_start | precision | how_started | source`, followed by a
  `<!-- COUNTS: ... -->` comment. **FL-4's file has two tables (`### City of Tallahassee` and
  `### Leon County`); FL-5 has one, because there is no city half.** Task 3 changes the parser to
  match; do not invent a third format.

🔴 **Palm Beach publishes no combined elected-officials page.** Manatee's and Leon's Supervisors of
Elections each gave one document; Palm Beach's gives none. Twelve people, up to eleven publishers.

- [ ] **Step 1: Pull the sources**

```bash
cd /c/EV-Accounts/backend && mkdir -p data/seed-palm-beach-2026 && \
for d in district1 district2 district3 district4 District5 district6 district7; do
  curl -s -m 30 "https://discover.pbc.gov/countycommissioners/$d/Pages/Biography.aspx" \
    -o "data/seed-palm-beach-2026/_bcc-${d}.html"
done && \
curl -s -m 30 "https://discover.pbc.gov/countycommissioners/Pages/default.aspx" -o data/seed-palm-beach-2026/_bcc-index.html && \
curl -s -m 30 -L "https://pbcpao.gov/dorothy-bio.htm"                    -o data/seed-palm-beach-2026/_off-pao.html && \
curl -s -m 30 -L "https://www.pbso.org/sheriff-ric-bradshaw"             -o data/seed-palm-beach-2026/_off-sheriff.html && \
curl -s -m 30 -L "https://www.pbctax.gov/about-us/"                      -o data/seed-palm-beach-2026/_off-tax.html && \
curl -s -m 30 -L "https://www.votepalmbeach.gov/275/Meet-Your-Supervisor" -o data/seed-palm-beach-2026/_off-soe.html
```

⚠ **`District5` has a capital D**; the other six are lower case. The loop above already accounts for it.

🔴 **`mypalmbeachclerk.com` returns a hard 403 to `curl`, and a full browser header set does not
help.** Use Playwright for that one host — the Ph150 method:

```
mcp__playwright__browser_navigate  https://www.mypalmbeachclerk.com/about-us/about-clerk-ad-interim-shannon-ramsey-chessman
mcp__playwright__browser_navigate  https://www.mypalmbeachclerk.com/Home/Components/News/News/858/16
```

Every other Palm Beach host answers `curl` normally. Leon needed Playwright for six hosts; this needs
it for one.

- [ ] **Step 2: Read the seven commissioner bios BY EYE, not by regex**

🔴 **Each bio page concatenates the incumbent's biography with the predecessor's, unlabelled.**
Measured: District 7's page contains both *"In November 2024, Bobby Powell Jr. was elected…"* and
*"Mack Bernard was elected in November 2016 to the Palm Beach County Commission, District 7."*
District 6's contains Sara Baxter's bio followed by *"Palm Beach County Commissioner Melissa McKinlay
was first elected in 2014."*

A regex for `elected in (\d{4})` returns **2016** for District 7 and **2014** for District 6. Both are
plausible, both are wrong, and nothing errors. **Read each page and attribute each sentence to a named
person before you use its date.**

Expected outcome of this step:

| District | Date found in the bio? |
| --- | --- |
| 1 Marino | ✅ "Elected … in 2020 and again in 2024" |
| 2 Weiss | ✅ "elected … in November 2018 and was reelected in 2022" |
| 3 Flores | ❌ only "Mayor of the City of Greenacres from 2017 to 2024" |
| 4 Woodward | ✅ "elected in November 2022" |
| 5 Sachs | ❌ prior offices only (FL House 86th 2006–2010; FL Senate 30th 2010–2012; FL Senate 34th) |
| 6 Baxter | ❌ no date; McKinlay's stale bio follows |
| 7 Powell | ✅ "In November 2024, Bobby Powell Jr. was elected…" |

- [ ] **Step 3: Source the three missing commission dates elsewhere**

Flores, Sachs and Baxter. In order of preference:

1. **The Supervisor of Elections' certified-results index** for the general elections of 2022 and 2024.
   ⚠ **FL-4 rejected a certified-results PDF *parser* — not the PDFs.** The race headers extract
   reliably; a parser slicing the candidate blocks came out shifted by one race and reported the wrong
   winner. Read the winner off the page yourself; do not write a slicing parser.
2. The county's own press release or BCC organisational-meeting minutes for each swearing-in.
3. The commissioner's own campaign or district newsletter archive.

Expected values, to be **confirmed and not assumed**: Flores `2024-11-01`, Sachs `2022-11-01`,
Baxter `2022-11-01`, all `month`.

⚠ **Check each of the seven for a seat change the way FL-4 checked Nick Maddox.** Two are known
already: **Maria Sachs held three different state legislative seats before this one**, and **Joel
Flores was Mayor of Greenacres until 2024** — a different office in a different government. A prior
office is not a longer tenure in this one.

🔴 **Bobby Powell Jr. and Mack Bernard traded seats. Bernard is ALREADY in prod** as
`external_id = -1230024`, State Senator SD-24, seated by FL-2. **Powell is not in prod.** Do not let a
name-match step reach for Bernard because the stale `County_Commission_Districts` layer still lists him
for District 7.

- [ ] **Step 4: Re-check every seat for a change since these sources were edited**

Two live situations, both of which must be re-confirmed on the day the migration is applied:

1. 🔴 **The Clerk.** As of 2026-08-28: Michael A. Caruso, appointed 2025-08-19, was **suspended by the
   Governor on 2026-08-18** (suspended, not removed); Chief Judge Glenn Kelley appointed chief deputy
   clerk **Shannon Ramsey-Chessman** as **Clerk Ad Interim**, effective **2026-08-18**. Confirm from the
   Clerk's own site that she still holds it and that no gubernatorial appointment has superseded the
   administrative order. **If the situation has changed, the fix is one row in `ROSTERS.md` — never a
   generator edit.**
2. ⚠ **Four commission seats are on the November 2026 ballot** — Districts 2, 4, 5 and 6 — and
   **Gregg Weiss (D2) is term-limited**, with District 2's August primary a Universal Primary Contest,
   which decides the seat outright. None of them changes before November, but confirm no resignation
   has intervened.

Also re-confirm the five officers are the five current holders. `mypalmbeachclerk.com` aside, all
answer `curl`.

- [ ] **Step 5: Resolve the Gannon contradiction, or write `unknown`**

Her page says *"Elected in 2006"* **and** *"currently serving her sixth term"*. Four-year terms from
2006 give five terms by 2026. Palm Beach's constitutional officers are on the **presidential** cycle —
confirmed by the 2026 primary carrying no constitutional-officer contest — so an even-numbered
gubernatorial-year start needs explaining.

Find the explanation (a special election, or a page error) or **write `unknown` precision**. 🔴 **Do
not reconcile the arithmetic yourself and write a date you inferred.** `unknown` is correct; a derived
date is a claim about a real person.

- [ ] **Step 6: Write `ROSTERS.md`**

**One** table, in the column order `parseRosters` already reads, plus a prose section per finding.
`external_id` is `-(1240000 + n)`, `n = 61…67` for the commission in district order and `n = 71…75`
for the officers in the alphabetical order of their titles.

```markdown
### Palm Beach County

| Seat | Slug | Name | external_id | term_start | precision | how_started | source |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Commissioner, District 1 | commissioner-1 | Maria G. Marino | -1240061 | 2020-11-01 | month | elected | pbcgov-d1-bio |
| Commissioner, District 2 | commissioner-2 | Gregg K. Weiss | -1240062 | 2018-11-01 | month | elected | pbcgov-d2-bio |
| Commissioner, District 3 | commissioner-3 | Joel G. Flores | -1240063 | 2024-11-01 | month | elected | <filled by Step 3> |
| Commissioner, District 4 | commissioner-4 | Marci Woodward | -1240064 | 2022-11-01 | month | elected | pbcgov-d4-bio |
| Commissioner, District 5 | commissioner-5 | Maria Sachs | -1240065 | 2022-11-01 | month | elected | <filled by Step 3> |
| Commissioner, District 6 | commissioner-6 | Sara Baxter | -1240066 | 2022-11-01 | month | elected | <filled by Step 3> |
| Commissioner, District 7 | commissioner-7 | Bobby Powell Jr. | -1240067 | 2024-11-01 | month | elected | pbcgov-d7-bio |
| Clerk of the Circuit Court & Comptroller | clerk-of-circuit-court | Shannon Ramsey-Chessman | -1240071 | 2026-08-18 | day | appointed | pbcclerk-ad-interim-announcement |
| Property Appraiser | property-appraiser | Dorothy Jacks | -1240072 | 2017-01-01 | month | elected | pbcpao-dorothy-bio |
| Sheriff | sheriff | Ric Bradshaw | -1240073 | 2005-01-04 | day | elected | pbso-sheriff-bio |
| Supervisor of Elections | supervisor-of-elections | Wendy Sartory Link | -1240074 | 2019-01-01 | year | appointed | votepalmbeach-meet-your-supervisor |
| Tax Collector | tax-collector | Anne M. Gannon | -1240075 | 2007-01-01 | month | elected | pbctax-about-us |

<!-- COUNTS: county_offices=12 county_people=12 vacancies=0 -->
```

⚠ **The slugs must match `COUNTY_SEATS` in the generator exactly.** Seven of the twelve
(`commissioner-1` … `-5`, `sheriff`, `tax-collector`, `property-appraiser`,
`supervisor-of-elections`, `clerk-of-circuit-court`) are already FL-4 slugs and keep their meaning;
`commissioner-6` and `commissioner-7` are **new and mean district seats here**, where Leon's
equivalents were `at-large-group-1` and `at-large-group-2`. Task 3 Step 2 rewrites that map.

⚠ **`alternate_names`:** check each of the twelve for a published nickname or honorific, the way FL-4
caught "Jack" Porter and Manatee caught "Rick" Wells. `Bobby Powell Jr.` is a likely candidate
(`Bobby Powell`, `Robert Powell`), as is `Ric Bradshaw` (`Richard Bradshaw`). Take the form the
publisher uses as `full_name`, and put the other in `ALIASES`.

Then the prose the tables cannot carry, one short section each:

- **The Clerk's chain** — Abruzzo elected 2021-01-05, resigned June 2025 to become County
  Administrator; Caruso appointed and sworn 2025-08-19; suspended by the Governor 2026-08-18, suspended
  and **not** removed; Ramsey-Chessman appointed Clerk Ad Interim by administrative order of the chief
  judge of the 15th Judicial Circuit, effective the same day. State the facts and the dates; do not
  restate the criminal allegations. **Note that no predecessor term is written for Caruso or Abruzzo**,
  and add both to the standing "write predecessor terms for all Florida vacancies together" item.
- **Powell / Bernard** — the seat swap, and that Bernard is already `-1230024`.
- **The stale bio pages** — District 6 and District 7, with the exact stale sentence quoted, so a later
  reader can see the trap rather than be told about it.
- **The Gannon contradiction** and how Step 5 resolved it.
- **The excluded offices** — State Attorney and Public Defender (15th Judicial Circuit, coterminous
  with the county), the School Board, the special districts.
- **The four seats on the November 2026 ballot**, and that Weiss is term-limited.

- [ ] **Step 7: Assert the counts in the file, then check them mechanically**

The machine-read counts are the `<!-- COUNTS: county_offices=12 county_people=12 vacancies=0 -->`
comment in Step 6. Add a human-facing block below it too, because the comment cannot carry a
histogram:

```markdown
## Counts

- Board of County Commissioners: 7 offices, 7 people, 0 vacant
- Elected Officials: 5 offices, 5 people, 0 vacant
- Total: 12 offices, 12 people, 0 vacant
- external_id range used: -1240075 .. -1240061 (68..70 deliberately unused)
- Date precision: day 2, month 9, year 1, unknown 0
```

⚠ If Step 3 or Step 5 could not source a date, **update the precision histogram** rather than leaving
the aspiration in place. The histogram is a measurement, not a target.

```bash
cd /c/EV-Accounts/backend && grep -c '^| ' data/seed-palm-beach-2026/ROSTERS.md
```

- [ ] **Step 8: Commit the roster, not the raw HTML**

```bash
cd /c/EV-Accounts && printf 'ROSTERS.md\n!_*\n' >/dev/null; git add backend/data/seed-palm-beach-2026/ROSTERS.md && git status --short backend/data/seed-palm-beach-2026/
```

Only `ROSTERS.md` may be staged. The `_*.html` working copies stay untracked, as FL-3's and FL-4's did.
🔴 **Untracked is not junk** — leave them in place for the executor of Task 3.

Commit message:

```
docs(knight-fl): reconciled roster for Palm Beach County

12 seats, 12 people, no vacancies: seven single-member commission districts and
five constitutional officers. Palm Beach has no at-large commissioner and no
elected Superintendent of Schools — Manatee has 5+2 and 5 officers, Leon 5+2 and
six. Three counties, three templates.

Two of the five officers were appointed rather than elected. The Clerk's seat
turned over twice in fourteen months and is held by a Clerk Ad Interim appointed
by the chief judge; the reasoning for seating her rather than flagging the office
vacant is in ROSTERS.md and in the plan.

Three of the seven commissioner bio pages carry the predecessor's biography
appended to the incumbent's, unlabelled — a regex for "elected in <year>" returns
Mack Bernard's 2016 for Bobby Powell's District 7 seat.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
```

---
## Task 3: Generator — copy FL-4's and delete its city half

**Files:**
- Create: `backend/scripts/gen-palm-beach-migrations.mjs`
- Create: `backend/scripts/gen-palm-beach-migrations.test.ts`
- Create (generated): `backend/migrations/CC_wip_palm_beach_county.sql`

**Interfaces:**
- Consumes: `backend/data/seed-palm-beach-2026/ROSTERS.md` from Task 2; the seven `X0039` boundaries
  from Task 1.
- Produces: `parseRosters(md)` returning `{ county: Seat[], counts: { countyOffices, countyPeople,
  vacancies } }` — **no `city` key**, unlike FL-4's. And **one** migration file.

🔴 **FL-4's generator emits three migrations. FL-5 emits ONE.** `renderCityStructure` and
`renderCityPeople` are deleted outright, not left dormant — a dead code path that nothing runs is a
trap for FL-6, which does have a city half and should copy from FL-4, not from here.

- [ ] **Step 1: Copy both files**

```bash
cd /c/EV-Accounts/backend && cp scripts/gen-tallahassee-leon-migrations.mjs scripts/gen-palm-beach-migrations.mjs && cp scripts/gen-tallahassee-leon-migrations.test.ts scripts/gen-palm-beach-migrations.test.ts
```

Read `gen-tallahassee-leon-migrations.mjs` end to end before editing. The parts that matter are
`COUNTY_SEATS`, `occupancySql()` (which carries the band guard), and `renderCounty()` (offices and
people in one file).

- [ ] **Step 2: Change the identity constants and rewrite the seat map**

```js
const ROSTER      = join(HERE, '..', 'data', 'seed-palm-beach-2026', 'ROSTERS.md');
const COUNTY_MTFCC     = 'X0039';
const COUNTY_GEO_ID    = '12099';   // TIGER county, Palm Beach County (G4020). Pre-existing.
const COUNTY_DIST_PREFIX = 'palm-beach-fl-commissioner-district-';
const COUNTY_GOV       = 'Palm Beach County, Florida, US';

/**
 * 🔴 THIS WAVE'S OWN CONTIGUOUS SUB-RANGE of the SHARED Florida LOCAL band.
 *    FL-3 owns -1240025..-1240001 and FL-4 owns -1240056..-1240031; both must keep
 *    re-running clean, so the guard allowlists ONLY the ids below.
 */
const OWNED_LO = -1240075;
const OWNED_HI = -1240061;
```

Rewrite `COUNTY_SEATS` — **all seven commission seats are `commdist`, none is `countywide`**:

```js
const COUNTY_SEATS = {
  // 🔴 SEVEN SINGLE-MEMBER DISTRICTS AND NO AT-LARGE SEAT. Manatee and Leon each
  //    have 5 + 2. Palm Beach's countywide district therefore carries ONLY the
  //    five constitutional officers, not 7 or 8 offices.
  'commissioner-1': { title: 'Commissioner, District 1', chamber: 'Board of County Commissioners', on: 'commdist', n: 1 },
  'commissioner-2': { title: 'Commissioner, District 2', chamber: 'Board of County Commissioners', on: 'commdist', n: 2 },
  'commissioner-3': { title: 'Commissioner, District 3', chamber: 'Board of County Commissioners', on: 'commdist', n: 3 },
  'commissioner-4': { title: 'Commissioner, District 4', chamber: 'Board of County Commissioners', on: 'commdist', n: 4 },
  'commissioner-5': { title: 'Commissioner, District 5', chamber: 'Board of County Commissioners', on: 'commdist', n: 5 },
  'commissioner-6': { title: 'Commissioner, District 6', chamber: 'Board of County Commissioners', on: 'commdist', n: 6 },
  'commissioner-7': { title: 'Commissioner, District 7', chamber: 'Board of County Commissioners', on: 'commdist', n: 7 },

  // 🔴 FIVE OFFICERS, NOT LEON'S SIX. Palm Beach is a charter county and still has
  //    no elected Superintendent of Schools — its school superintendent is
  //    APPOINTED by the School Board. Charter status does not predict the set.
  // 🔴 STATE ATTORNEY AND PUBLIC DEFENDER ARE DELIBERATELY ABSENT. The county's own
  //    page lists them among its constitutional officers, but they are 15th
  //    Judicial Circuit offices. The circuit is coterminous with the county, which
  //    is the only reason they look countywide. See the plan.
  'sheriff':                 { title: 'Sheriff', chamber: 'Elected Officials', on: 'countywide' },
  'tax-collector':           { title: 'Tax Collector', chamber: 'Elected Officials', on: 'countywide' },
  'property-appraiser':      { title: 'Property Appraiser', chamber: 'Elected Officials', on: 'countywide' },
  'supervisor-of-elections': { title: 'Supervisor of Elections', chamber: 'Elected Officials', on: 'countywide' },
  // ⚠ AMPERSAND, not "and". Leon's is spelled out; Palm Beach's office brands
  //   itself with "&". Follow the publisher — nothing joins on title.
  'clerk-of-circuit-court':  { title: 'Clerk of the Circuit Court & Comptroller', chamber: 'Elected Officials', on: 'countywide' },
};
```

Add the one office description this wave needs:

```js
/**
 * 🔴 THE ONLY offices.description IN THIS WAVE, and it exists because the seat's
 *    occupancy needs explaining rather than because the seat has unusual powers.
 */
const DESCRIPTIONS = {
  'clerk-of-circuit-court':
    'The elected Clerk, Michael A. Caruso (appointed 2025-08-19), was suspended by the Governor on ' +
    '2026-08-18. He is suspended, not removed. On the same day the Chief Judge of the 15th Judicial ' +
    'Circuit appointed the Chief Deputy Clerk as Clerk Ad Interim by administrative order, and she ' +
    'holds the office now.',
};
```

⚠ **`voting_powers` stays `'full'` for all twelve**, so `representation_note` must stay NULL — both
read paths hide it when `voting_powers = 'full'`. That is exactly why the text above goes in
`description`, the same ruling FL-3 made for Bradenton's mayor.

- [ ] **Step 3: Delete the city half**

Remove `CITY_SEATS`, `renderCityStructure()`, `renderCityPeople()`, `PLACE_GEO_ID`, `CITY_GOV`, and the
`'citywide'` and `'ward'` branches of `districtRef()`/`districtLookupSql()`. In `parseRosters`, drop the
`### City of …` table and the `city_offices` / `city_people` count keys. `main()` writes one file:

```js
writeFileSync(join(MIGRATIONS, 'CC_wip_palm_beach_county.sql'),
              renderCounty(county, counts).replace(/\n{3,}/g, '\n\n'));
```

- [ ] **Step 4: Change the counts the gates assert**

Inside `renderCounty()`'s post-verify `DO $$ … $$` block:

| Assertion | FL-4 (Leon) | **FL-5 (Palm Beach)** |
| --- | --- | --- |
| `governments` created | 1 | 1 |
| `chambers` | 2 (7 + 6) | 2 — **7 and 5** |
| new `COUNTY` districts on `X0039` | 5 | **7** |
| offices on the countywide `G4020` district | 8 | **5** |
| offices on `X` districts | 5 | **7** |
| total offices | 13 | **12** |
| total people | 13 | **12** |
| `office_terms` rows written | 13 | **12** |
| offices with no term and no vacancy flag | 0 | **0** |
| `how_started = 'appointed'` | 0 | **2** |

🔴 **Assert the five officers BY TITLE, not only by count.** A count of 5 is reachable by duplicating
one officer, which is the same reason FL-4 asserted the Superintendent by name. Add the mirror
assertion too: **`Superintendent of Schools`, `State Attorney` and `Public Defender` must each match
ZERO offices** in this government. A negative assertion is what stops a later copy-paste from FL-4
quietly reintroducing Leon's sixth officer.

🔴 **Assert that the countywide district carries exactly 5 offices**, not "at least 5". If a
commission seat were accidentally mapped `countywide` it would still total 12 and would still pass a
total-only gate — and every Palm Beach address would then return that commissioner.

- [ ] **Step 5: Keep the band guard as an allowlist of THIS wave's own ids**

Do not touch the shape of `occupancySql()`'s guard; only the bounds change to `OWNED_LO`/`OWNED_HI`.
The guard asserts, before inserting anything:

> no row outside this migration's own id list occupies any `external_id` in `[-1240075, -1240061]`

**Not** "the band holds N rows" (non-idempotent — a re-run counts its own), **not** "the whole band
holds nothing this wave owns" (FL-3's and FL-4's 35 legitimate rows would trip it). Four versions of
this guard have been wrong; this is the one that works.

- [ ] **Step 6: Update the test fixture and add three new cases**

Rewrite `FIXTURE` to one `### Palm Beach County` table with a handful of rows, and replace the
city-specific cases. Keep FL-4's "carries how_started and precision through" and "keeps an
unknown-precision row" cases. Add:

```ts
// 🔴 Palm Beach has no at-large commissioner. Every commission seat must hang off
//    an X0039 district; only the five officers may be countywide.
it('puts all seven commission seats on commdist and only the officers countywide', () => {
  const { county } = parseRosters(FIXTURE);
  const comm = county.filter((s: any) => s.chamber === 'Board of County Commissioners');
  expect(comm).toHaveLength(7);
  expect(comm.every((s: any) => s.on === 'commdist')).toBe(true);
  const off = county.filter((s: any) => s.chamber === 'Elected Officials');
  expect(off).toHaveLength(5);
  expect(off.every((s: any) => s.on === 'countywide')).toBe(true);
});

// 🔴 Leon's sixth officer must not survive a copy-paste.
it('has no Superintendent of Schools, State Attorney or Public Defender', () => {
  const titles = parseRosters(FIXTURE).county.map((s: any) => s.title);
  for (const t of ['Superintendent of Schools', 'State Attorney', 'Public Defender']) {
    expect(titles).not.toContain(t);
  }
});

// 🔴 First Florida wave to write an appointment. FL-2/3/4 were all 'elected'.
it('carries how_started = appointed through for the two appointed officers', () => {
  const { county } = parseRosters(FIXTURE);
  const appointed = county.filter((s: any) => s.howStarted === 'appointed').map((s: any) => s.slug);
  expect(appointed.sort()).toEqual(['clerk-of-circuit-court', 'supervisor-of-elections']);
});
```

- [ ] **Step 7: Run the tests, generate, and run the safety greps**

```bash
cd /c/EV-Accounts/backend && npx vitest run scripts/gen-palm-beach-migrations.test.ts && node scripts/gen-palm-beach-migrations.mjs && ls -la migrations/CC_wip_palm_beach_county.sql
```

Then grep the generated SQL for the five failure modes this slice has actually hit:

```bash
cd /c/EV-Accounts/backend && f=migrations/CC_wip_palm_beach_county.sql && \
echo "--- party leakage (must be empty):"       && (grep -nE '\((R|D|I|DEM|REP|NPA)\)' "$f" || echo OK) && \
echo "--- unpaired geo_id join (must be empty):" && (grep -n "geo_id = '12099'" "$f" | grep -v mtfcc || echo OK) && \
echo "--- slug insert (must be empty):"          && (grep -n 'INSERT INTO essentials.chambers' -A6 "$f" | grep -w slug || echo OK) && \
echo "--- band bounds (must be -1240075/-1240061):" && grep -nE '\-12400(75|61)' "$f" | head -4 && \
echo "--- COMMIT count (must be exactly 1):"     && grep -c '^COMMIT;$' "$f"
```

- [ ] **Step 8: Commit the generator and test**

```bash
cd /c/EV-Accounts && git add backend/scripts/gen-palm-beach-migrations.mjs backend/scripts/gen-palm-beach-migrations.test.ts && git status --short backend/scripts/
```

Commit message:

```
feat(knight-fl): generator for the Palm Beach County migration

One migration, not three — Palm Beach has no city half, so the city structure and
city occupancy renderers are deleted rather than left dormant. FL-6 has a city
half and should copy FL-4's generator, not this one.

All seven commission seats are commdist; only the five constitutional officers are
countywide. The post-verify asserts that split explicitly, because a commission
seat mis-mapped to the countywide district still totals twelve.

Negative assertions added for Superintendent of Schools, State Attorney and Public
Defender so a copy-paste from Leon cannot reintroduce a sixth officer.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
```

---

## Task 4: Dry-run, apply, gate, probe, commit

**Files:**
- Rename to `backend/migrations/CC_0014_palm_beach_county.sql`
- Create: `backend/scripts/verify-palm-beach-probes.sql`

- [ ] **Step 1: Write the probe**

Copy `scripts/verify-tallahassee-leon-probes.sql`. Change the anchor to
`-80.051906016174, 26.71529321541`, the government `geo_id` to `12099`, and the `X` code to `X0039`.
**Delete the city probe entirely and say why in a comment**, so the missing fourth answer reads as
designed rather than dropped:

```sql
-- 🔴 THREE REQUIRED ANSWERS, NOT FOUR, AND THAT IS CORRECT.
--    Palm Beach County has no city half in this program. The anchor sits inside
--    TIGER place 1276600 (West Palm Beach), which is deliberately NOT seated, so a
--    municipal official is legitimately absent from every answer set below. Do not
--    read the missing fourth row as a failure — compare with FL-2's note that Miami
--    has no state representative while HD-113 is vacant.
required(n, what, dt, geo, mt, expect_rows) AS (VALUES
  (1, 'county commissioner',      'COUNTY',      'palm-beach-fl-commissioner-district-7', 'X0039', 1),
  (2, 'state representative',     'STATE_LOWER', '12087',                                 'G5220', 1),
  (3, 'state senator',            'STATE_UPPER', '12024',                                 'G5210', 1)
)
```

Add a fourth, non-anchor-specific assertion, because the officers are what most of the county gets:

```sql
-- Every Palm Beach address elects all five constitutional officers countywide.
(4, 'constitutional officers', 'COUNTY', '12099', 'G4020', 5)
```

⚠ **Confirm the two state `geo_id`s with a query rather than trusting the padding** — FL-4's plan gave
this instruction and it was the right one to write:

```bash
cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -At -F ' | ' -c "
SELECT d.district_type, d.label, d.geo_id, d.mtfcc FROM essentials.districts d
 WHERE lower(d.state)='fl' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
   AND d.label IN ('State House District 87','State Senate District 24');"
```

🔴 **Keep the unpaired-join collision probe, and update its expected output** — it is richer here than
in FL-3 or FL-4. At this anchor it returns **three** wrong rows: Monroe County via HD-87's `sldl`
polygon, State House District 24 via SD-24's `sldu` polygon, and State House District 99 via Palm
Beach County's **own** `G4020` polygon. All three failure directions in one query.

- [ ] **Step 2: Run the probe BEFORE applying**

```bash
cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -f scripts/verify-palm-beach-probes.sql
```

Expected pre-state: answers 2 and 3 `PRESENT` (HD-87 and SD-24, seated by FL-2); answers 1 and 4 at
**0**. If it differs, the DB moved and the counts in this plan need re-measuring.

- [ ] **Step 3: Dry-run, its own COMMIT turned into ROLLBACK**

```bash
cd /c/EV-Accounts/backend && sed 's/^COMMIT;$/ROLLBACK;/' migrations/CC_wip_palm_beach_county.sql | psql "$DATABASE_URL" -v ON_ERROR_STOP=1 2>&1 | tail -20
```

🔴 **Leave the `BEGIN;` alone.** In FL-3 a `sed` meant for the inner transactions also matched the
outer wrapper and `CC_0008` ran in autocommit against prod.

⚠ **Unlike FL-4, this wave has only one file, so there is no "the second one fails on its own"
caveat.** It must dry-run clean on the first attempt, given Task 1's boundaries are loaded.

- [ ] **Step 4: Confirm the rollback reverted**

```bash
cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -At -F ' | ' -c "
SELECT (SELECT count(*) FROM essentials.governments WHERE geo_id = '12099'),
       (SELECT count(*) FROM essentials.districts   WHERE mtfcc  = 'X0039'),
       (SELECT count(*) FROM essentials.geofence_boundaries WHERE mtfcc = 'X0039'),
       (SELECT count(*) FROM essentials.politicians WHERE external_id BETWEEN -1240075 AND -1240061);"
```

Expected **`0 | 0 | 7 | 0`**. The `X0039` **boundaries** come from Task 1 and stay at 7; the `X0039`
**district rows** are created by this migration and must read 0 until it applies.

- [ ] **Step 5: Take the number last, then apply**

```bash
cd /c/EV-Accounts && git fetch origin && cd backend && npm run check:migrations && \
git mv migrations/CC_wip_palm_beach_county.sql migrations/CC_0014_palm_beach_county.sql && \
sed -i 's/CC_wip_palm_beach_county/CC_0014_palm_beach_county/g' \
  migrations/CC_0014_palm_beach_county.sql scripts/gen-palm-beach-migrations.mjs && \
npm run check:migrations && \
(grep -rn 'CC_wip' migrations/ scripts/gen-palm-beach-migrations.mjs || echo 'no CC_wip references left')
```

Then apply:

```bash
cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f migrations/CC_0014_palm_beach_county.sql
```

- [ ] **Step 6: Re-run ALL SEVEN Florida local migrations — the idempotency test**

```bash
cd /c/EV-Accounts/backend && for f in CC_0008_bradenton_structure CC_0009_bradenton_people CC_0010_manatee_county CC_0011_tallahassee_structure CC_0012_tallahassee_people CC_0013_leon_county CC_0014_palm_beach_county; do
  echo "=== RE-RUN $f (must be a clean no-op) ==="
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "migrations/$f.sql" 2>&1 | grep -E 'INSERT 0 [1-9]|UPDATE [1-9]|NOTICE|ERROR|COMMIT' | sed 's/^psql:[^ ]* //'
done
```

🔴 **All seven, not just the new one.** FL-5's twelve rows land in the same shared band as FL-3's and
FL-4's thirty-five; if `CC_0014`'s guard were scoped to the whole band, or if theirs were, one of the
six older files would start refusing to re-run. **That is exactly the defect FL-4 found, and it was
found only by re-running everything.** Every file must reach `COMMIT` with its post-verify `NOTICE`
and no `ERROR`; the only permitted `INSERT 0 N` with N > 0 is into a **temp** seed table.

- [ ] **Step 7: The acceptance probe**

```bash
cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -f scripts/verify-palm-beach-probes.sql
```

Expected: all three required answers `PRESENT` — Commission **District 7** → Bobby Powell Jr., **HD-87**
→ Emily Gregory, **SD-24** → Mack Bernard — plus **5** constitutional officers on the countywide
district. Per-body counts: `Board of County Commissioners` 7/7, `Elected Officials` 5/5. Zero offices
with no term row and no vacancy flag. The city slot is absent, by design.

**Negative control:** a point in Broward County — Fort Lauderdale, `-80.1373, 26.1224` — must return
**no** Palm Beach commissioner and **no** Palm Beach officer. FL-4 used Bradfordville for the same
purpose.

- [ ] **Step 8: Every gate**

```bash
cd /c/EV-Accounts/backend && npx tsc --noEmit && npm run check:occupancy && npm run check:migrations && npm run check:child-county && npm run check:reachability
```

`check:reachability` must report **no new bucket**. There is no `fl|COUNTY` bucket in the baseline, and
this wave has **no vacancy**, so all twelve offices must carry a term row — a single missing one fires
`DEAD_GEOGRAPHY` and fails the gate.

**No `geofence_child_county` refresh is needed** — this wave loads only an `X` code, like FL-3 and
FL-4. Confirm `check:child-county` green anyway.

- [ ] **Step 9: Measure the drift**

```bash
cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -At -F ' | ' -c "
SELECT count(*), count(*) FILTER (WHERE is_vacant), count(*) FILTER (WHERE NOT is_vacant)
  FROM essentials.offices_missing_terms;"
```

FL-4 left this at **820 / 165 / 655** against a 699 unflagged threshold. FL-5 adds no vacancy and no
unflagged row, so expect **820 / 165 / 655 unchanged**. Any rise in the unflagged count means an office
was created without a term and without a flag — the one failure mode CI cannot catch.

- [ ] **Step 10: Commit**

```bash
cd /c/EV-Accounts && git add backend/migrations/CC_0014_palm_beach_county.sql backend/scripts/verify-palm-beach-probes.sql backend/scripts/gen-palm-beach-migrations.mjs && git status --short backend/
```

Commit message:

```
feat(knight-fl): seat Palm Beach County — 12 offices, 12 people (CC_0014)

APPLIED. One government, two chambers, seven new COUNTY districts on X0039, and
twelve offices: all seven commission seats on their own district, all five
constitutional officers on the pre-existing countywide district. No vacancies.

The probe at the county Governmental Center returns Commission District 7, HD-87
and SD-24, plus the five officers. There is no city answer and that is correct —
Palm Beach County has no city half in this program.

Two officers are seated with how_started = 'appointed', the first in the Florida
slice: the Supervisor of Elections (2019) and the Clerk Ad Interim (2026-08-18,
after the elected Clerk was suspended — suspended, not removed).

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
```

---

## Task 5: Update the ledger

**Files:**
- Modify: `.planning/knight-foundation/fl.md`, `.planning/knight-foundation/PROGRAM.md`
- Modify: this plan — add a "Deviations found during execution" section, as FL-2, FL-3 and FL-4 did

- [ ] **Step 1: `fl.md`**

- Wave table: FL-5 `✅ applied — CC_0014`. Next free `CC_0015`, `X0040`.
- **Replace the "▶️ FL-5 — what is already measured" block** with a `## FL-5 — Palm Beach County
  (applied …)` section. Its five open questions are now answered; leaving the block would make a
  reader re-measure.
- Record, in this order of importance:
  1. 🔴 **Three counties, three officer templates and three commission shapes.** Manatee non-charter,
     5 officers, 5+2 commission. Leon charter, **6** officers (elected Superintendent), 5+2. Palm Beach
     charter, **5** officers (no elected Superintendent), **7+0**. **Charter status predicts nothing.**
  2. 🔴 **State Attorney and Public Defender are circuit offices, not county offices** — Palm Beach's
     own page lists them because the 15th Circuit is coterminous with the county, and Leon's 2nd Circuit
     spans six. Recorded as program-level open work, with the `JUDICIAL` scale noted.
  3. 🔴 **The districts do not tile the TIGER county: 155.54 sq mi is the Atlantic**, and the
     cross-check service carries the same water as a blank row. The gate asserts structure, not slack.
  4. 🔴 **Bio pages that append the predecessor's biography, unlabelled** — District 7 yields Mack
     Bernard's 2016, District 6 yields Melissa McKinlay's 2014. A new shape of the FL-4 parser lesson.
  5. 🔴 **Powell and Bernard traded seats**, and Bernard was already in prod from FL-2.
  6. 🔴 **The Clerk's seat and the suspension**, with the seating decision and the rejected alternative.
  7. **First Florida wave with two `appointed` starts and zero `unknown` precisions.**
  8. **A third projection family** (StatePlane FL East, US survey feet) and a service whose name and
     layer name disagree about vintage.
  9. ⚠ **Only one host 403s `curl`** here, against Leon's six.
  10. ⚠ **The Clerk title uses `&` where Leon's uses `and`** — publisher, not drift.
  11. ⚠ **Four commission seats are on the November 2026 ballot; Weiss is term-limited.** Re-check
      Palm Beach after the general, before FL-7.
- Add Caruso and Abruzzo to the standing **"write predecessor terms for all Florida vacancies
  together"** item, alongside Felts and FL-2's five.
- Update the "Sources for FL-3 onward" block: Palm Beach is now **ANSWERED**; Miami-Dade remains.

- [ ] **Step 2: `PROGRAM.md`**

- Slice status: FL stage 4 stays `WIP` — Miami-Dade remains. Stage 3 also stays `WIP` — Miami remains.
- Jurisdiction detail: Palm Beach County row — its banner key is decided but unnamed; that is FL-7.
- Local/county seats table: add Palm Beach County 12/12.
- Migration ledger: one row, `FL-5 county (offices + people) | CC_0014_palm_beach_county.sql`. Next free
  `CC_0015`; MTFCC next free `X0040`.
- Session log: one row, and `Next action: write the FL-6 plan — Miami + Miami-Dade County. Miami-Dade is
  a CHARTER county and the officer template must be read from its charter, not inherited; Miami and
  Miami-Dade are separate governments; Miami's banner cannot be a downtown skyline; and MIAMI HAS NO
  STATE REPRESENTATIVE while HD-113 is vacant, so its probe can return only three answers.`

- [ ] **Step 3: Commit**

```bash
cd /c/EV-Accounts && git add .planning/knight-foundation/fl.md .planning/knight-foundation/PROGRAM.md docs/superpowers/plans/2026-08-28-knight-fl-wave-5-palm-beach-county.md && git status --short .planning/ docs/
```

Commit message:

```
docs(knight): record FL-5 in the ledger, with the plan's own errors

Three Florida counties now, three officer templates and three commission shapes.
Charter status predicts neither: Leon is chartered and elects six officers, Palm
Beach is chartered and elects five. Palm Beach is also the first with no at-large
commissioner at all.

State Attorney and Public Defender are circuit offices that only look countywide
because the 15th Circuit is coterminous with Palm Beach. Not seated; recorded as
program-level open work.

The seven districts leave 155.54 sq mi of the TIGER county uncovered — the
Atlantic. The cross-check service carries the same water as an unassigned blank
row, so the gate can assert "the only thing missing is the sea" instead of a
tolerance wide enough to hide a missing district.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
```

---

## Plan self-review

**Spec coverage.** §3 stage 4 (county wave: commission layer + county officers, offices and people in
one migration) → Tasks 1–4, and the single-migration shape is stated rather than inherited. §3 stage 3
(city) is **legitimately `n/a` for this jurisdiction** — Palm Beach County has no city half, and every
consequence of that is enumerated rather than silently skipped: no city government, no city chamber, a
three-answer probe, and a comment in the probe file saying so. §8.3 (banner) was resolved by decision
on 2026-08-28 — Palm Beach gets its own county key — and **naming the key and choosing the composition
is FL-7 work, not this plan's**. §2's honesty rules drive the `unknown`-over-inference instructions in
Task 2 Steps 3 and 5 and the Clerk decision.

**Placeholder scan.** Three `<filled by Step 3>` markers appear in the Task 2 roster table. They are
deliberate and bounded: Step 3 names the three people, the three expected values, and the three sources
to try in order, and Step 7 forces the precision histogram to be re-measured rather than left as an
aspiration. Every other value in the plan is a measured literal. No "add appropriate error handling",
no "similar to Task N", no undefined function referenced.

**Type and name consistency.** `parseRosters` returns `{ county, counts }` in Task 3's Interfaces, and
Task 2 Step 6 emits exactly the `### Palm Beach County` heading and the eight-column table that shape
requires — with an explicit note that FL-4's file has two tables and this one has one. The twelve slugs
in Task 2's table match `COUNTY_SEATS` in Task 3 Step 2 one for one, including the two that change
meaning (`commissioner-6`/`-7` are district seats here, at-large seats in Leon). `X0039`, `12099`,
`palm-beach-fl-commissioner-district-`, `-1240075 … -1240061` and `CC_0014` are identical everywhere
they appear. `geofence_boundaries.state` is `'12'` in Task 1 and `districts.state` is `'fl'` in Task 3,
which is the split CLAUDE.md and the Global Constraints both call out.

**Gaps found and closed while reviewing.** Three. (1) The Task 4 probe originally had three required
answers and no assertion on the five officers, which are what the other 1.5 million residents of the
county actually get — a fourth, non-anchor-specific assertion was added. (2) Task 3's post-verify
counted twelve offices in total but did not constrain the 7/5 split, so a commission seat mis-mapped to
the countywide district would have passed and appeared for every address in the county; the split is
now asserted exactly. (3) The negative assertions on `Superintendent of Schools`, `State Attorney` and
`Public Defender` were added after noticing that Task 3 Step 1 begins by copying Leon's generator,
where the Superintendent is a live entry.
