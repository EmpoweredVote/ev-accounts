# Knight Program — Florida Wave FL-6 (Miami + Miami-Dade County) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Seat the City of Miami and Miami-Dade County — **25 offices, 25 people, 0 vacancies** — and close Florida's stages 3 and 4.

**Architecture:** Six stages, and **the largest wave in the slice by a factor of two**. Two governments, five chambers, **two** boundary loaders (`X0040` Miami-Dade's 13 commission districts, `X0041` Miami's 5), and **three** migrations: city structure, city occupancy, and county offices-and-people together. Acceptance needs **two anchors**, because one of them sits in a vacant state-house district and can never return a full answer set.

**Tech Stack:** TypeScript/Node 24, `tsx`, vitest, `psql` against the Supabase session pooler, PostGIS, ArcGIS FeatureServer REST.

**Spec:** `docs/superpowers/specs/2026-08-28-knight-cities-program-design.md`
**Slice notes:** `.planning/knight-foundation/fl.md` — read the **FL-5** section first; its toolchain lessons are the ones this wave inherits.
**Tracker:** `.planning/knight-foundation/PROGRAM.md`
**Prior waves:** FL-5 (`…-wave-5-palm-beach-county.md`) has **five** "Deviations found during execution" sections; FL-4 and FL-3 have one each. **Read FL-5's in full before Task 1** — the `splitName()` suffix bug, the psql `\echo` apostrophe trap, the generator-header drift and the "verify a rename by regenerating" rule all come from it and all apply here.

## Global Constraints

Everything in FL-3's, FL-4's and FL-5's Global Constraints still applies. These changed or are new:

- **Migration namespace is `CC_`. This wave takes THREE slots: `CC_0015`, `CC_0016`, `CC_0017`.** ⚠ **Verify from `origin/docs/knight-cities-program`, not from a local `ls`** — see the branch note below. **Take the numbers LAST**: write as `CC_wip_miami_structure.sql`, `CC_wip_miami_people.sql`, `CC_wip_miami_dade_county.sql`, then rename + apply + commit in one go.
- **Next free private MTFCCs are `X0040` and `X0041`.** This is the first wave to take **two**. Assign **`X0040` = Miami-Dade commission districts (13)** and **`X0041` = Miami city commission districts (5)**, in that order, so the county code sorts before the city's as in FL-3.
- 🔴 **THE BRANCH MOVED UNDER THIS PLAN.** FL-5 was completed and pushed on `docs/knight-cities-program` at `ec99f5d3`; the `C:/EV-Accounts` worktree was subsequently switched to `feat/compass-user-lenses`, and a second worktree exists at `C:/ev-accounts-coverage`. **Before Task 1: `git worktree list`, confirm which worktree is on `docs/knight-cities-program`, and `git fetch origin` there.** `CC_0006`…`CC_0014` are absent from any other branch's working tree, so a local `ls migrations/` on the wrong branch reports the next free slot as `CC_0006` — **wrong by nine**.
- 🔴 **`12086` IS MIAMI-DADE COUNTY (`G4020`), STATE HOUSE DISTRICT 86 (`G5220`) — AND ZIP CODE 12086 IN NEW YORK (`G6350`).** Fourth Florida county in four waves with a `geo_id` collision, and the first where one arm is **in another state**. Measured: **40 of Florida's 67 county `geo_id`s have a New York ZCTA twin** in `geofence_boundaries`. Manatee, Leon and Palm Beach happen not to, which is why no earlier wave met it. Pair `geo_id` with `mtfcc` **and** `district_type` everywhere — and note the failure mode differs: a ZCTA match returns a polygon 1,300 miles away, so `ST_Covers` yields **nothing** and the symptom is a silently empty result, not a wrong official.
- 🔴 **`essentials.seat_officeholder()` refuses a NULL `term_start`.** Keep the dated/undated split from `CC_0009`.
- 🔴 **THE BAND GUARD NEEDS A NEW SHAPE FOR THIS WAVE, BECAUSE ONE PERSON IS A REUSE.** See "Oliver Gilbert" below. The FL-5 guard asserts "nothing inside `[min..max]` of this wave's ids is owned by anything else". `-1212402` is outside the wave's sub-range, so including it in the owned list would stretch `max` across the whole congressional band and every FL local wave. **Split the guard**: an absence assertion over the wave's *new* contiguous sub-range, plus a **positive** assertion that each reused id is held by the expected person.
- 🔴 **`splitName()` STILL REQUIRES A COMMA BEFORE A SUFFIX in FL-3's and FL-4's generators.** FL-5 widened its own copy only. **This wave has three names that need the widened version** — `Oliver G. Gilbert, III` (comma, fine), `Juan Carlos "JC" Bermudez` (quoted nickname), and `Danielle Cohen Higgins` (**two-word surname**, which neither version handles). Copy FL-5's generator, not FL-4's, and see the naming decision below.
- 🔴 **To dry-run: turn each file's OWN final `COMMIT` into `ROLLBACK` and leave its `BEGIN` alone.** Never strip `BEGIN;`/`COMMIT;` to concatenate.
- 🔴 **Re-run every applied migration in the slice: `CC_0008` … `CC_0017`, all ten.** Not just the three new ones.
- 🔴 **GREP EVERY NEW PROBE FOR AN APOSTROPHE ON AN `\echo` LINE.** psql lexes quotes inside `\echo`, reports `unterminated quoted string`, swallows the following heading lines, and **continues** — so the probe still reports PASS while its headings are gone. Cost FL-5 three lines.
- **No party affiliation.** The Miami-Dade SOE's roster PDF carries none, but its filing report prints `(DEM)`/`(REP)`/`(NPA)`. Keep FL-5's widened guard.
- **No `term_end`.** No `end_precision` exists. ⚠ The SOE PDF publishes a `Current Term Ends` column; **it is not `term_end` and must not be written.**
- **`districts.state` is lower case (`'fl'`); `governments.state` and `offices.representing_state` are UPPER (`'FL'`); `geofence_boundaries.state` is `'fl'` for private `X` layers and the 2-digit FIPS for TIGER layers.**
- **`outSR=4326` is load-bearing.** Both new services answer in Web Mercator by default.
- **`cwd` resets between Bash calls.** Prefix every command with `cd <knight-worktree>/backend &&`.

---

## 🔴 Deviations found during execution — Task 1, 2026-08-29

`X0040` is **loaded**: 13 districts, all `ST_MultiPolygon`, all valid, all single-part, all SRID 4326,
areas matching the recorded literals to **0.00 %** on all thirteen. The loader re-runs as a clean
no-op. `check:migrations`, `check:occupancy` and `check:child-county` are all green;
`check:child-county` is unchanged at **7,245 children / 0 stale**, confirming again that an `X`-code
load needs no matview refresh. Every measured literal in the plan held exactly — tiling
0.0315 / 0.0320 / 0.0000, vintage symmetric differences 126.132 / 67.718 / 16.339. Three things are
worth recording.

1. 🔴🔴 **THE VINTAGE GATE HAD TO MOVE TO THE FRONT, AND THE REASON IS STRONGER THAN THE PLAN KNEW.**
   The plan placed the vintage gate at Step 5, after the control points and the area gate, and asked
   Step 6 to *"confirm the vintage message appears"*. Written in that order it **cannot** appear.
   Measured by pointing `PRIMARY_URL` at `CommissionDistrict2011`:
   - **ALL 17 CONTROL POINTS PASS ON THE WRONG MAP** — every one of the 13 interior points and both
     negative controls. The plan predicted this for District 1 only ("a spot check there would pass").
     It is true of **every** control point. The districts moved, but never far enough to carry an
     interior point out of its own district. **The point gates cannot discriminate between the
     vintages at all.**
   - The **area gate fires first**, on District 2 at 3.76 % — and its remedy text reads *"re-measure
     deliberately and update `EXPECTED_SQ_MI` in the same commit, with the reason."* 🔴 **An editor who
     follows that advice re-baselines the loader onto the 2011 map**, after which every gate agrees
     with the wrong apportionment. District 1 is 0.21 % apart, **inside** the 1 % tolerance, so it
     passes the area gate on the wrong map too.
   ▶ **So "which map is this?" must be answered before any gate whose failure message invites
   re-baselining.** The vintage gate is now **GATE 1**, ahead of the control points; the area gate is
   GATE 4 and the tiling gate GATE 5. Both gates carry cross-references saying so, and the vintage
   failure message now ends with an explicit *"DO NOT fix this by updating `EXPECTED_SQ_MI`"*.
   ⚠ **Generalise this, it is not about Miami-Dade:** a gate that says *"update the expectation"* must
   never be the first gate to fire, because the cheapest way to make it green is to accept the bad
   input. Order gates so the diagnostic one speaks before the re-baselining one.

2. ⚠ **Two of the three Step 6 proofs needed an earlier gate neutralised to reach their target, and
   that is a finding about the proofs, not a workaround.** Dropping `'13'` from `DISTRICTS` aborts at
   the **control-point** gate ("District 13 interior: expected D13, got none"), not at the tiling gate,
   so the proof also had to drop District 13's control point — and keep `EXPECTED_COUNT` at 13, since
   lowering it to 12 aborts at the fetch check instead. With both neutralised the tiling gate reports
   **24.3539 sq mi uncovered**, ~97× the tolerance, exactly as the plan predicted. The area proof
   needed nothing neutralised. ▶ **A gate proof that fires the wrong gate proves the wrong thing;
   state which earlier gate you disabled and why.**

3. ⚠ **The worktree is not a working environment on arrival, and Task 0 does not say so.** A fresh
   `git worktree` carries tracked files only, so `/c/ev-accounts-knight/backend` had **no `.env` and no
   `node_modules`**. `npx tsx` failed with `ERR_MODULE_NOT_FOUND: Cannot find package 'dotenv'` before
   any gate could run. Fixed with `npm ci` (393 packages, 9 s) and by exporting `DATABASE_URL` from the
   primary worktree's `.env` per command — `dotenv` does not override an already-set variable, so this
   is equivalent and copies no secret into a second tree. ▶ **Add to Task 0:** after picking the
   worktree, run `npm ci` and confirm `DATABASE_URL` resolves, before Task 1.

Two things the plan got exactly right and should be reused:

- **The two-digit key regex warning was necessary and correctly aimed.** `/^(1[0-3]|[1-9])$/` is in
  place with the comment explaining why `/^[1-9]$/` fails *silently* — it would drop districts 10–13
  and then report a count error that points at the count, not at the regex.
- **The `TBLCOMMISSIONDISTRICT` probe is worth its lines.** Verified live: 13 features, **every one
  `"geometry": null`**, and the payload still names `Jean Monestime` and `Sally A. Heyman`. It is the
  roster-in-a-boundary-layer failure mode and the named-like-the-primary trap in one object.

---

## 🔴 Deviations found during execution — Task 2, 2026-08-29

`X0041` is **loaded**: 5 districts, all `ST_MultiPolygon`, valid, single-part, SRID 4326, areas matching
the recorded literals to **0.01 % or better**. The loader re-runs as a clean no-op.
`check:migrations`, `check:occupancy` and `check:child-county` all green; `check:child-county`
unchanged at **7,245 / 0 stale**. Every literal the plan recorded held exactly — cross-check symmetric
differences 0.0096…0.0940, place `uncovered` 0.4428 / `overhang` 0.3056, and
**`place_covers_cityhall = true`**, the load-bearing one. Four things went differently.

1. 🔴🔴 **THE PLAN SAID MIAMI PUBLISHES TWO COMMISSION-DISTRICT LAYERS. IT PUBLISHES FOUR
   CANDIDATES, AND ONE OF THEM IS A 2017 PRE-LITIGATION VINTAGE WITH IDENTICAL FIELD NAMES.**
   Enumerated across all 185 services on the org, 2026-08-29:

   | Service | Edited | Keys | What it is |
   | --- | --- | --- | --- |
   | `Commission_Districts` | schema 2024-07-08, data 2025-12-17 | `COMDISTID` 1–5 | **PRIMARY** — the settlement map |
   | `Commission_Districts_New` | 2025-06-24 | `COMDISTID` 1–5 | **CROSS-CHECK** — same map, ⚠ *older* edit despite "_New" |
   | `Enriched Commission Districts` | **2017-07-19** | `COMDISTID` 1–5 | 🔴 **PRE-LITIGATION VINTAGE** |
   | `District_<32 hex>` | **2026-06-01** (newest) | `district` = neighbourhood name | 13 **NEIGHBOURHOODS**, not districts |

   🔴 **`Enriched Commission Districts` carries the same `COMDISTID` / `COMNAME` / `ADDRESS` fields,
   the same `esriGeometryPolygon` type and the same five keys as the primary. A loader pointed at it
   parses perfectly and errors on nothing.** It dates to **2017 — five years before the first of the
   two maps a federal court struck down.** Its `COMNAME` reads Wifredo (Willy) Gort, Ken Russell,
   Frank Carollo, Francis Suarez, Keon Hardemon.
   ▶ **So Task 2 needed a VINTAGE GATE too, which the plan did not specify** — the same gate class
   Task 1 introduced for Miami-Dade, and here the stakes are higher: loading a superseded Miami map
   does not publish stale lines, it publishes **a districting a federal judge held to be a racial
   gerrymander**. Measured symmetric difference, primary vs 2017: D1 0.5269, D2 1.5454, D3 1.6569,
   D4 1.7351, D5 0.7149. The gate checks **D4, D3 and D2** at 1.0 / 1.0 / 0.9 — ⚠ **not D1 or D5**,
   whose 0.53 and 0.71 are barely twice the cross-check tolerance and are weak evidence.
   ⚠ **`District_<hex>` is the quieter trap:** it holds the newest edit date on the server, so
   "take the most recently edited district layer" gets you Wynwood and Overtown. Its field is
   `district`, not `COMDISTID`, so a keyed loader returns nothing rather than something wrong — but
   the count is **13**, which is also Miami-Dade's commission-district count.

2. 🔴 **THE GATE ORDER FROM TASK 1 WAS APPLIED HERE, AND IT MATTERS MORE.** Both discriminating
   gates run before the area gate: **GATE 1 vintage** (this is not the 2017 map), **GATE 2
   cross-check** (an independent digitization agrees), then control points, then area, then the place
   gate. The area gate's failure text still says "update `EXPECTED_SQ_MI`", and it now carries a
   pointer saying gates 1 and 2 passed and must be re-enabled if they were disabled. Same rule as
   Task 1: **a gate that invites re-baselining must never be the first to fire.**

3. ⚠ **THE `ADDRESS` FABRICATION IS NINE YEARS OLD AND WAS INHERITED ACROSS BOTH STRUCK-DOWN MAPS.**
   The plan flagged it on the primary: D1 `3500 Pan American Drive`, D2 `3501`, D3 `3502`, D4 `3503`,
   D5 `3504` — City Hall's address incremented per district. **The 2017 layer carries the identical
   sequence.** So this is not a recent data-entry slip; it is a placeholder that has survived two
   redistrictings and two lawsuits. Neither `ADDRESS` nor `COMNAME` is requested.

4. ⚠ **A LIVE SERVICE FAILURE MID-RUN, AND THE LOADER DIED WITH AN UNREADABLE ERROR.** The place
   proof aborted on `SyntaxError: Unexpected token '<', "<!DOCTYPE "... is not valid JSON` — ArcGIS
   answered a throttled request with an HTML page. The message names neither the service nor the
   cause, and the run succeeded on a plain retry. `fetchDistricts()` now reads the body as text,
   `JSON.parse`s it in a `try`, and on failure prints **which layer** and **the first 200 characters**,
   with a line saying an HTML body normally means throttling and to retry before changing anything.
   ▶ **`load-miami-dade-commission-boundaries.ts` (Task 1) still has the unguarded `.json()` and
   should get the same treatment** — left alone here rather than re-touching a committed file.

Two things the plan got right and should be reused:

- **Hialeah is the correct negative control and it earns its place.** A large incorporated city
  *inside* Miami-Dade that is not Miami. It returns zero city districts. The failure it guards against
  — a city layer that has quietly become a county layer — would otherwise hand a Hialeah resident a
  commissioner they cannot vote for.
- **Gating against TIGER place `1245000`, not the county, with `ST_Covers` on the anchor.** Miami is
  ~56 sq mi inside a ~2,389 sq mi county; a county-tiling gate would assert nothing. Dropping D2
  (26.299 sq mi) drives `uncovered` to **26.5575** against the 1.0 tolerance — ~26× — so the gate
  cannot be confused for slack.

⚠ **The D2 proof needed two control points neutralised** (City Hall and "District 2 interior", both of
which expect D2), for the reason Task 1 recorded: the control-point gate fires first otherwise. With
City Hall removed, `CONTROL_POINTS[0]` became the MDC Government Center, so the *anchor* sub-assertion
in that proof tested a different point than in the real run. Stated here because a proof that quietly
re-aims an assertion proves less than it appears to.

---

## 🔴 Deviations found during execution — Task 3, 2026-08-29

`ROSTERS.md` is written: **6 city + 19 county offices, 25 people, 0 vacancies**, 25 distinct
`external_id`s, **24 inside `-1240109 … -1240081`** and exactly one equal to **`-1212402`**. Every
mechanical assertion in Step 7 passes; precision is **day 23 / month 2 / year 0 / unknown 0**; no
party marking; no `Superintendent of Schools`, `State Attorney` or `Public Defender` in any row. The
`how_started` and `start_precision` values were checked against the live CHECK constraints
(`elected|appointed|succeeded|redistricted|unknown` and `day|month|year|unknown`). Six things went
differently, and three of them were the plan being wrong.

1. 🔴🔴 **`pdftotext -layout` MISASSIGNS EVERY ROW OF THE SOE PDF, AND IT WOULD HAVE MOVED THE
   VACANCY.** The plan said to "read the SOE PDF pages 1–3" and did not say how. Read with `-layout`
   — the obvious choice, and the one every earlier wave's habits point at — the *Elected Official*
   column is offset from the *Office* column, so **every name lands on the wrong office**. The offset
   is **not constant**: one row in the FEDERAL block, two in the MIAMI-DADE COUNTY block, because a
   wrapped row absorbs a line. `-table` is correct.

   | Office | `-layout` says | `-table` says (correct) |
   | --- | --- | --- |
   | Clerk of the Court and Comptroller | Rosanna "Rosie" Cordero-Stutz | **Juan Fernandez-Barquin** |
   | Sheriff | Tomas Regalado | **Rosanna "Rosie" Cordero-Stutz** |
   | Mayor | Oliver Gilbert | **Daniella Levine Cava** |
   | Commissioner, District 1 | Marleine Bastien | **Oliver Gilbert** |
   | **State House District 113** | Demi Busatta Cabrera | **Vacant** |

   🔴 **Nothing errors, and every wrong answer is a real person in a real office** — Cordero-Stutz is
   an elected Miami-Dade officer, Oliver Gilbert is on the page. Only the pairing is wrong. This is the
   Nashville certified-results defect in a new medium.
   🔴 **`-layout` puts *Vacant* on HD-112.** The wave's acceptance probe depends on **HD-113**. A
   session that read the PDF the obvious way would have built probe A on the wrong seat **and it would
   have passed.** ▶ The finding is recorded at the top of `ROSTERS.md`, not buried, for that reason.
   ⚠ The `pdftotext` here is **Xpdf 4.00**, which has **no `-bbox`** (the usual coordinate escape
   hatch). `-table` is the available correct reader. **Confirm the tool before trusting the text.**

2. 🔴🔴 **`term_start` IS THE START OF CONTINUOUS OCCUPANCY, AND THE PLAN'S STEP 3 READS AS THOUGH IT
   IS THE CURRENT TERM.** The plan asked for "the date the Commission appointed her", "the remaining
   eleven commissioners … come from each district's own page", and gave the officers as a single
   settled date — none of which distinguishes *this term* from *this tenure*. FL-5's committed roster
   settles it: Ric L. Bradshaw is **2005-01-04** and Anne M. Gannon **2007-01-01**, both re-elected
   many times since, and FL-5's own deviations corrected Maria Sachs from her re-election year to her
   first. Consequences, all of which a current-term reading would have got wrong:
   - **Christine King is `2021-11-10`, not 2025**, though she was re-elected 2025-11-04 with 84.4%.
   - **Six county seats read 2020** though their holders were re-elected in 2024.
   - **Two rows read `appointed` despite having been elected since** — see 3.

3. 🔴🔴 **THE PLAN PREDICTED TWO APPOINTMENTS. THERE ARE FOUR, AND ONE IS BY THE GOVERNOR.** The plan
   named D5 (Lopez) and D6 (Milian Orbis) — the two the SOE marks `Appointed` with a blank term end.
   But under continuous occupancy two more spans *began* with an appointment and the SOE hides them,
   because both holders have since won ordinary four-year terms and so display like any elected member:
   - **D8 Danielle Cohen Higgins — appointed 2020-12-07**, 10–1, to serve the last two years of
     Daniella Levine Cava's term when Levine Cava became Mayor. Elected 2022-08-23.
   - **D11 Roberto J. Gonzalez — appointed 2022-11-23 by Gov. Ron DeSantis**, not by the Commission,
     after Commissioner Joe Martinez was suspended on felony charges. Elected to a full term in 2024.
   🔴 **"Appointed" does not imply the same appointing authority.** Three of the four are Commission
   votes; one is a gubernatorial appointment under the Governor's power to fill county-office
   vacancies. `ROSTERS.md` records who appointed, per row.
   ▶ The `how_started` histogram is therefore **elected 21 / appointed 4**, not 23/2.

4. 🔴 **THE TAKE-OFFICE RULE WAS DERIVABLE FROM A PRIMARY SOURCE, AND IT IS CORROBORATED IN BOTH
   DIRECTIONS — so the county rows carry DAY precision where FL-5's carried month.** The county's own
   candidate qualifying handbooks quote the Charter directly: *"The term for Board of County
   Commissioners shall commence on the second Tuesday next succeeding the date of the General Election
   in November (November 17, 2020)"* (**Art. 3 §3.01(A)**), and the Mayor's handbook carries the same
   sentence at **§3.01(D)**. That yields 2020-11-17 / 2022-11-22 / 2024-11-19.
   **Forwards** it reproduces the SOE PDF's own *Current Term Ends* exactly — 11/17/2026 for the 2022
   cohort, 11/21/2028 for the 2024 cohort. **Backwards** it matches independently published
   assumed-office dates for Gilbert, Regalado, McGhee (2020-11-17) and Steinberg (2022-11-22).
   ⚠ **A derived day with two independent confirmations is not an invented date** — but the derivation
   is stated in `ROSTERS.md` so a reader can reject it.
   ⚠ **Miami city has NO uniform rule**, and that is itself the finding: its six were sworn on four
   dates spanning seven months. **Do not derive a Miami date from a cycle.**

5. ⚠ **THE PLAN'S "READ THE BIOS BY EYE" WARNING WAS NECESSARY, AND THE TRAP HERE IS A DIFFERENT ONE
   FROM PALM BEACH'S.** Palm Beach's bios appended a predecessor's biography. Miami-Dade's instead
   give the **election** date and call it election — *"elected … on August 23, 2022"* for both Bermudez
   (D12) and Anthony Rodriguez (D10). **August 23 2022 is the primary**, which Miami-Dade's nonpartisan
   commission races end outright when someone clears 50%. Read as a start date it is three months
   early. Only **2 of 13** county bios carry any date at all, and the county Mayor's page says
   *"re-elected in **August** 2024"* — the same trap on the wave's largest seat.

6. ⚠ **THE DEDUP SWEEP'S ONE EXTRA HIT WAS INVISIBLE IN THE OBVIOUS SUMMARY.** All 25 names were
   matched against `essentials.politicians` on NFD-normalised first+last. Two rows returned: Gilbert,
   and — for **René Garcia** — `GARCIA FOR ARVIN CITY COUNCIL, RENE`, FEC ALLCAPS committee junk from
   **Arvin, California**. Not a reuse. 🔴 It has a **NULL `external_id`**, so a `string_agg` of
   `external_id || full_name` rendered NULL and the row read as "(none)" beside a count of 1. **Count
   the rows; do not read the aggregate.**
   ⚠ `essentials.politicians.external_id` is **`bigint`**, not text — a `coalesce(external_id,'(NULL)')`
   fails outright with `invalid input syntax for type bigint`.

Two things the plan got exactly right and should be reused:

- **Every URL in Step 1 answered `curl`, including `www.miami.gov`**, which the plan correctly warned
  returns 403 to WebFetch. ⚠ The reverse also held: the county's own D6 appointment release
  (`/district06/releases/2025-05-06-com-orbis-appointment.asp`) **404s to both** `curl` and WebFetch
  while still being indexed — its dated URL slug is now the only trace, and the date was confirmed
  from reporting instead.
- **The four in-wave surname pairs are real**, and the plan was right to call them out. The subtle one
  is **`Fernandez` / `Fernandez-Barquin`** — a strict **prefix**, not an equality, so
  `full_name ILIKE '%Fernandez%'` returns both, and both are constitutional officers of the same
  county so no state or body filter separates them.

⚠ **One Step 7 assertion could not be interpreted: "`n = 93` absent".** Nothing in the wave has 93
rows, no `external_id` is 93, and no slug carries it. It is asserted nowhere. ▶ **Task 4 should either
define it or drop it from the plan.**

⚠ **The Clerk's title is published three ways** — `Clerk of the Circuit Court and Comptroller` (SOE),
`Clerk of the Court and Comptroller` (county page **and** his own site), `Miami-Dade Clerk of the
Courts` (his own site, informal). Chosen: **`Clerk of the Court and Comptroller`**, the officeholder's
own formal name. It differs from Palm Beach's `Clerk of the Circuit Court & Comptroller` — **do not
inherit a title across counties.**

---

## 🔴 Deviations found during execution — Task 4, 2026-08-29

`scripts/gen-miami-dade-migrations.mjs` and its test are written; **26 tests pass**; the three
migrations generate at **333 / 309 / 954 lines**. `tsc` clean, `check:migrations` and
`check:occupancy` green. All three headers cite **FL-6's** plan, roster and generator — the FL-4
header defect does not recur. **40 district `geo_id` predicates, 0 unpaired.** 1 BEGIN / 1 COMMIT per
file. Zero party markings in any data row. Five things went differently.

1. 🔴 **THE PLAN'S BAND GUARD ASSUMED A LAYOUT THE ROSTER DOES NOT HAVE.** Its draft test asserted
   `expect(ids).not.toContain(-1240093)` — "`-1240093` is Gilbert's slot in the sub-range and is
   deliberately left unused". The roster committed in Task 3 assigns `-1240093` to **Keon Hardemon
   (D3)**: it does not reserve a gap where District 1's id would have fallen, it simply skips the
   reused person and continues. Reserving a gap is cosmetic; the invariant that matters is
   **"exactly one id outside the new sub-range, and it is the declared reuse"**, which is what the
   test now asserts. ▶ The plan's specific number was an assumption about a layout it never
   specified — **do not reintroduce it.**

2. 🔴 **THE GATES ASSERT FOUR APPOINTMENTS, NOT THE PLAN'S TWO**, following Task 3. The plan's Step 5
   table says `how_started = 'appointed'` → 2 and its draft test asserted exactly
   `['mdc-commissioner-5','mdc-commissioner-6']`. Both are now 4 and
   `['mdc-commissioner-11','mdc-commissioner-5','mdc-commissioner-6','mdc-commissioner-8']`. The
   emitted gate asserts the count **and** the four titles, because a count alone passes if an elected
   member is mislabelled.

3. 🔴 **FL-4 HAS NO `'ward'` BRANCH TO BRING BACK — TALLAHASSEE IS ENTIRELY AT-LARGE.** The plan's
   Step 1 says to restore "the `'citywide'` / `'ward'` branches of `districtRef()`" from FL-4 and
   rename `'ward'` to `'commdist_city'`. FL-4's `districtRef()` has only `citywide`, `countywide` and
   `commdist`; `'ward'` is **FL-3's** (Bradenton, X0036). `'commdist_city'` was written fresh.
   ▶ And the city half is a genuinely new shape, not a rename: **Tallahassee's five seats share ONE
   citywide district and one chamber; Miami's five are single-member and the Mayor is a SEPARATE
   executive.** So Miami's citywide district carries `num_officials = 1` where Tallahassee's carries
   5, and the gate asserts **exactly 1 office on the citywide district** where FL-4's asserts 5.
   Copying FL-4's assertion would have passed only if a commissioner were wrongly mapped citywide.

4. ⚠ **THE PLAN'S SEAT MAP USES `mdc-clerk`; THE ROSTER USES `mdc-clerk-of-court`.** The generator
   consumes `ROSTERS.md`, so the roster's slug wins — a mismatch is refused outright as
   `unrecognised slug`. Related: the emitted title is **`Clerk of the Court and Comptroller`**, the
   form the officeholder's own site uses, and the test asserts the SOE's
   `Clerk of the Circuit Court and Comptroller` and Palm Beach's
   `Clerk of the Circuit Court & Comptroller` are both **absent**.

5. ⚠ **`ROSTERS.md` BOLDS THE REUSED ID (`**-1212402**`) AND THE PARSER HAD TO LEARN TO STRIP IT.**
   The emphasis is deliberate — it makes the one anomalous id visible to a human reader — but
   `Number('**-1212402**')` is `NaN`, which would have silently failed the range checks rather than
   erroring. `parseTable()` now strips asterisks, and the fixture carries the bolded form so the
   stripping is exercised.

Two smaller notes:

- ⚠ **Gilbert's `alternate_names` are deliberately NOT written.** ROSTERS.md records the county's
  published `Oliver G. Gilbert, III`, but writing it means UPDATEing a row another wave owns. The
  `ALIASES` map has no entry for `mdc-commissioner-1` and a test pins that it stays empty.
- ⚠ **Two Step 7 greps are false-positive generators and both fired.** The party-leakage regex
  `\((R|D|...)\)` matches the **charter citations** `s. 3.01(A)` and `s. 3.01(D)`; the stale-wave
  regex matches deliberate comparisons ("Tallahassee's equivalent expects 5", "Palm Beach's expects
  5, Leon's 8, Manatee's 7"). ▶ **Run the party check against DATA ROWS, not the whole file**, and
  check the header's `Plan:`/`Roster:`/`Generated by:` lines rather than any mention of an earlier
  city. A third: the plan's pairing check must be scoped to **district** aliases — a bare
  `[a-z]+\.geo_id` flags all 30 `g.geo_id` government lookups, which are correctly paired with
  `g.type` because **governments have no `mtfcc` column**.

⚠ **The `n = 93` assertion from Task 3 remains uninterpretable** and is not implemented. Nothing in
the wave has 93 rows and no id is 93. ▶ Drop it from the plan or define it.

⚠ **The three `CC_wip_*.sql` files are NOT committed.** Only the generator and its test are. The
number is taken last (CLAUDE.md), so Task 5 renames, regenerates to verify byte-for-byte, applies and
commits the numbered files.

---

## Facts measured 2026-08-28/29 — do not re-derive these

### The shape of the wave

| | Offices | People | Chambers | Districts created |
| --- | --- | --- | --- | --- |
| **City of Miami** — City Commission | 5 | 5 | 1 | 5 × `X0041` |
| **City of Miami** — Office of the Mayor | 1 | 1 | 1 | 1 citywide (`1245000` `G4110`) |
| **Miami-Dade** — Board of County Commissioners | 13 | 13 | 1 | 13 × `X0040` |
| **Miami-Dade** — Office of the Mayor | 1 | 1 | 1 | *(reuses the county district)* |
| **Miami-Dade** — Elected Officials | 5 | 5 | 1 | *(reuses the county district)* |
| **Total** | **25** | **25** | **5** | **18 new + 1 citywide** |

**Miami and Miami-Dade are separate governments.** Miami-Dade is **not** a consolidated city-county — unlike Nashville/Davidson, and unlike the Georgia slice's Columbus/Muscogee and Macon-Bibb. Two `governments` rows, two `geo_id`s, no shared chamber.

**Miami's shape is Bradenton's, not Tallahassee's.** The Mayor is elected **citywide and separately from the Commission** — Miami's charter calls this the *"mayor-city commissioner plan"*, with a commission of five *"elected from districts"*. So Miami needs **two** chambers, a citywide district for the Mayor and five district polygons — exactly the pattern `CC_0008` built for Bradenton, and the opposite of Tallahassee's single at-large chamber.

**Miami-Dade's shape is Bradenton's too, plus an officer chamber.** Its Mayor is a **separate countywide office with veto power over Commission items**, not a commission member. So the pre-existing county district `12086`/`G4020` carries **6** offices: the Mayor plus the five constitutional officers. Compare Leon 8, Manatee 7, Palm Beach 5 — **a fourth count in four counties.**

### 🔴🔴 The reuse: Oliver Gilbert is ALREADY IN PROD, and this is the slice's first

**`Oliver Gilbert`, `external_id = -1212402`**, is in `essentials.politicians` with **no office**, seeded by the FL 2026 US House wave. His race row: `U.S. Representative District 24`, `Congressional District 24`, `geo_id 1224`, `mtfcc G5200`, `is_incumbent = false`.

**He is the same person as Miami-Dade Commissioner District 1.** Oliver Gilbert III — former Mayor of Miami Gardens, sitting Commissioner for District 1 — **won the Democratic primary for FL-24 on 2026-08-18**, endorsed by the retiring Frederica S. Wilson, and faces Republican T.E. Brown in November.

🔴 **So FL-6 must REUSE `-1212402` for the District 1 commissioner office and insert no new politician row for him.** FL-2, FL-3, FL-4 and FL-5 were all fresh inserts — 215 people, zero reuses. This is the first, and getting it wrong produces **two Oliver Gilbert rows**, one a candidate and one a commissioner, with nothing erroring.

⚠ Note the row's `is_incumbent = true` while its **race** row reads `is_incumbent = false`. Both are correct: he is a sitting officeholder, and a non-incumbent for the seat he is contesting. **Do not "fix" either.**

▶ **Live churn:** if Gilbert wins in November he resigns District 1, which under Miami-Dade's practice below becomes another Commission-appointed vacancy. **Re-check on the day of apply.**

### 🔴 Four repeated surnames inside the wave's own roster

Measured across all 25 names against the FL local, legislature and congressional bands — and against each other:

| Surname | Two different people in THIS wave |
| --- | --- |
| **Higgins** | **Eileen Higgins** (Mayor of Miami) and **Danielle Cohen Higgins** (Commissioner, District 8) |
| **Regalado** | **Tomas Regalado** (Property Appraiser) and **Raquel A. Regalado** (Commissioner, District 7) |
| **Garcia** | **Alina Garcia** (Supervisor of Elections) and **Rene Garcia** (Commissioner, District 13) |
| **Fernandez** | **Dariel Fernandez** (Tax Collector) and **Juan Fernandez-Barquin** (Clerk) |

And against prod, four more near-misses that are **genuinely different people**: `Ileana Garcia` (SD-36, `-1230036`), `Ana Maria Rodriguez` (SD-40, `-1230040`), `Karen Gonzalez Pittman` (HD-65), `Lisa Gonzalez Moore` (Bradenton Ward 4, `-1240005`), plus congressional candidates `Patricia Gonzalez` and `Eliott Rodriguez`.

🔴 **So name-based matching is unsafe WITHIN this wave, not only against prod.** Every identity decision keys on `external_id`. The one reuse is justified by a verified biography, not by a name match.

### 🔴🔴 Two anchors, because one of them cannot return four answers

| | Miami City Hall | Miami-Dade Government Center |
| --- | --- | --- |
| Address | 3500 Pan American Dr, Miami FL 33133 | 111 NW 1st St, Miami FL 33128 |
| Geocode (1 match each) | `-80.234992579394, 25.728661855119` | `-80.196332709513, 25.775078850443` |
| City commissioner | **District 2** — Damian Pardo | **District 5** — Christine King |
| County commissioner | **District 7** — Raquel A. Regalado | **District 5** — Vicki L. Lopez *(appointed)* |
| State senator | **SD-38** — Alexis Calatayud | **SD-36** — Ileana Garcia |
| State representative | **HD-113 — VACANT** | **HD-109** — Ashley Viola Gantt |
| Answers returned | **3 of 4** | **4 of 4** |

🔴 **Miami City Hall sits inside HD-113, which is vacant** — Vicki Lopez resigned it in November 2025 and the SOE confirms, as of its 2026-06-04 roster, that the seat is `Vacant` and **on the November 2026 ballot rather than a special election**. Re-verified in prod: `is_vacant = true`, `vacant_since = 2025-11-19`, no holder.

**Use BOTH anchors, and say why in the probe file.** City Hall is the honest anchor for a city wave and the one a later reader will reach for; the Government Center proves the four-answer path works. FL-2 warned that Miami could only ever return three answers — **this makes that warning testable instead of remembered**, which is what FL-5's "assert the absence" lesson asks for.

⚠ **Do NOT choose the Government Center alone to make the numbers look better.** The vacancy is the truth about Miami City Hall's address, and hiding it behind a second address would be the same defect as a tolerance wide enough to hide a missing district.

### 🔴🔴 The chain reaction: one person's move created the vacancy this wave must explain

| Step | What |
| --- | --- |
| 1 | **Eileen Higgins** was Miami-Dade Commissioner for **District 5**. |
| 2 | She vacated it to run for **Mayor of Miami**, and **won the 9 December 2025 runoff** with 59% against former city manager Emilio Gonzalez — the first Democrat elected Miami mayor since 1997 and the first woman. |
| 3 | The **Commission appointed Vicki L. Lopez** to the vacant District 5 seat, on a **7–5 vote**. |
| 4 | Lopez's appointment vacated **HD-113**, which is still vacant and is Miami City Hall's state-house district. |

All three offices are in or adjacent to this wave's scope. **Miami's Mayor, Miami-Dade's District 5 and the empty HD-113 slot in probe A are the same event seen three times.**

🔴 **A Miami-Dade Commission vacancy is filled by the COMMISSION'S OWN VOTE**, not by gubernatorial appointment. Palm Beach's and Manatee's vacancies run through Fla. Const. art. IV §1(f) — the Governor. **Never inherit the vacancy mechanism either.** ▶ Task 3 must cite the Miami-Dade charter section; the 7–5 vote is the empirical proof, not the authority.

### 🔴 Two appointed commissioners, not one

The SOE's own roster marks **both** District 5 and District 6 as `Appointed`, with a blank `Current Term Ends`:

- **District 5 — Vicki L. Lopez**, appointed by the Commission (above).
- **District 6 — Natalie Milian Orbis**, also `Appointed`.

Both are on the **2026** ballot. So this wave writes **`how_started = 'appointed'` twice**, as FL-5 did — but for commissioners rather than officers, and by a different mechanism. ▶ Task 3 must establish each appointment's date and the seat each succeeded.

### The rosters as published

🔴 **Miami-Dade's Supervisor of Elections DOES publish the combined roster Palm Beach lacked** —
`https://www.miamidade.gov/elections/library/reports/elected-officials.pdf`, *"Elected Officials Information, As of June 4, 2026"*, 7 pages, `curl`-reachable. It covers federal, state, the county legislative delegation, Miami-Dade County, the School Board, Soil & Water and the Community Councils.

⚠ **It stops at the county line: there are NO municipal offices in it.** Miami's city roster must come from `miami.gov`.
⚠ **Its as-of date is load-bearing.** It still lists Daniel Anthony Perez in HD-116, which prod records as vacant since 2026-08-22. **Authoritative for titles and structure; three months stale for fast-churning occupancy.**

**City of Miami** — from `miami.gov/Government/City-Officials`, 6 seats, all filled:

| Seat | Incumbent |
| --- | --- |
| Mayor | **Eileen Higgins** |
| District 1 Commissioner | Miguel Angel Gabela |
| District 2 Commissioner | Damian Pardo |
| District 3 Commissioner | Rolando Escalona |
| District 4 Commissioner | Ralph "Rafael" Rosado |
| District 5 Commissioner | Christine King |

**Miami-Dade County** — from the SOE roster PDF, 19 seats, all filled:

| Office (as the SOE prints it) | Incumbent | Note |
| --- | --- | --- |
| Mayor | Daniella Levine Cava | ballot 2028 |
| Board of County Commissioners District 01 | Oliver Gilbert | 🔴 **REUSE `-1212402`** |
| District 02 | Marleine Bastien | |
| District 03 | Keon Hardemon | |
| District 04 | Micky Steinberg | |
| District 05 | Vicki L. Lopez | **Appointed** |
| District 06 | Natalie Milian Orbis | **Appointed** |
| District 07 | Raquel A. Regalado | |
| District 08 | Danielle Cohen Higgins | two-word surname |
| District 09 | Kionne L. McGhee | Vice Chairman |
| District 10 | Anthony Rodriguez | **Chairman** |
| District 11 | Roberto J. Gonzalez | |
| District 12 | Juan Carlos "JC" Bermudez | quoted nickname |
| District 13 | Rene Garcia | |
| Clerk of the Circuit Court and Comptroller | Juan Fernandez-Barquin | ⚠ title varies — see below |
| Sheriff | Rosanna "Rosie" Cordero-Stutz | |
| Property Appraiser | Tomas Regalado | |
| Tax Collector | Dariel Fernandez | |
| Supervisor of Elections | Alina Garcia | |

⚠ **The county's commission page prints `Oliver G. Gilbert, III` and `René Garcia`; the SOE PDF prints `Oliver Gilbert` and `Rene Garcia`.** Two publishers, two forms, including a dropped accent. ▶ Task 3 decides per person and records the alternate.

### 🔴 All five constitutional officers took office on the SAME DAY, and it is published

**2025-01-07.** Amendment 10 to the Florida Constitution, adopted **2018-11-06**, forced Miami-Dade to make five offices independently elected; the county's own page states *"since Jan. 7, 2025, there are five constitutional offices operating in our County, all of which run independently from Miami-Dade County government"* and *"In Nov. 2024, County residents elected the new constitutional officers, which assumed their role on Jan. 7, 2025."*

🔴 **So all five get `term_start = 2025-01-07` at `day` precision** — a single published date for five people, which no earlier Florida wave had. Rosie Cordero-Stutz was sworn in at the Miami-Dade College School of Justice that day; Dariel Fernandez and Juan Fernandez-Barquin assumed their roles the same day.

⚠ **"First elected" is true of some of these offices and not others.** Sheriff, Tax Collector and Supervisor of Elections were **created as elected offices** by Amendment 10 — Cordero-Stutz is the first elected Sheriff in decades and the first woman. Property Appraiser and Clerk were **already** elected offices; their holders succeeded elected predecessors. **The `term_start` is the same either way; do not write "first" into any field.**

### ⚠ THREE published titles for one office, from three arms of the same county

| Source | Title |
| --- | --- |
| SOE roster PDF | `Clerk of the Circuit Court and Comptroller` |
| County "Constitutional Offices" page | `Clerk of the Court and Comptroller` |
| The Clerk's own site (`miamidadeclerk.gov`) | `Clerk of the Court and Comptroller` |

"Follow the publisher" is ambiguous when publishers disagree. **Decision: prefer the OFFICE'S OWN site** → `Clerk of the Court and Comptroller`. That makes **four** variants across four counties — Leon `Clerk of the Circuit Court and Comptroller`, Palm Beach `Clerk of the Circuit Court & Comptroller`, Manatee's own form, and Miami-Dade's. Nothing joins on `title`; **record the rule so the next wave does not re-litigate it.**

### 🔴🔴 The State Attorney and Public Defender question, answered the other way round

FL-5 ruled that the State Attorney and Public Defender are **circuit** offices, not county offices, and excluded them — over the objection of Palm Beach's own page, which lists them among its seven "constitutional officers".

**Miami-Dade's publishers agree with FL-5.** The county's Constitutional Offices page lists **five** and neither of those two. And the SOE roster PDF lists **`State Attorney — Katherine Fernandez Rundle`** and **`Public Defender — Carlos J. Martinez`** under its **`STATE`** heading, alongside the Governor and the Attorney General — not under `MIAMI-DADE COUNTY`.

🔴 **The 11th Judicial Circuit is coterminous with Miami-Dade County, exactly as the 15th is with Palm Beach.** Same law, same geography, **opposite publisher behaviour**. That is the strongest available evidence that FL-5's ruling was right and that Palm Beach's page was simply wrong. **Not seated here either.** ▶ The program-level open item stands.

### 🔴🔴 Vintage: Miami-Dade publishes FOUR polygon vintages and a geometry-less lookalike

Org: `https://services.arcgis.com/8Pc9XBTAsYuxx9Ny/arcgis/rest/services`

| Service | Rows | Geometry | `COMMNAME` roster | Verdict |
| --- | --- | --- | --- | --- |
| **`CommissionDistrict_gdb/0`** | 13 | polygon | **CURRENT** — matches the county page, Vicki L. Lopez included | ✅ **PRIMARY** |
| `CommissionDistrict2011/0` | 13 | polygon, **same schema** | **STALE** — Jean Monestime (left 2020), Sally A. Heyman (left 2022) | 🔴 **DECOY** |
| `CommissionDistrict2001_gdb`, `CommissionDistrict1992_gdb` | 13 | polygon | — | historical |
| `TBLCOMMISSIONDISTRICT/0` | 13 | **NONE — it is a TABLE** | STALE, same as 2011 | 🔴 **DECOY** |

🔴 **`CommissionDistrict2011` has the same field names, the same geometry type and the same row count as the current layer.** A loader pointed at it returns 13 valid polygons with plausible district numbers and plausible names, and nothing errors.

🔴🔴 **AND A SPOT CHECK ON DISTRICT 1 WOULD NOT CATCH IT.** Measured symmetric difference, current vs 2011:

| D | sq mi | D | sq mi | D | sq mi |
| --- | --- | --- | --- | --- | --- |
| 1 | **0.136** | 6 | 10.205 | 11 | 12.070 |
| 2 | 1.325 | 7 | 16.339 | 12 | 6.291 |
| 3 | 0.805 | 8 | **67.718** | 13 | 3.347 |
| 4 | 5.385 | 9 | **126.132** | | |
| 5 | 7.816 | 10 | 2.541 | | |

**District 1 moved by 0.136 sq mi and District 9 by 126.** So the vintage check must use a district that actually moved — **9, 8 or 7** — and the loader's per-district area gate must carry all thirteen literals, because any single-district check picked at random has a real chance of passing on the wrong map.

⚠ `TBLCOMMISSIONDISTRICT` is named like the primary and returns 13 rows with `DISTRICT` and `NAME` — and **no geometry at all**. A cross-check pointed at it silently compares against nothing.

### 🔴🔴 Vintage: Miami's own city map was struck down TWICE by a federal court

The city's commission map has three vintages within four years, and **two of them are unconstitutional**:

| When | What |
| --- | --- |
| 2022 | The Commission adopts a redistricting map. Sued by the ACLU of Florida and voting-rights groups. |
| 2023 | The Commission adopts a revised map after the suit is filed. |
| **April 2024** | **U.S. District Judge K. Michael Moore holds BOTH the 2022 and the 2023 maps unconstitutionally racially gerrymandered.** The court adopts the plaintiffs' remedial map, "P4"; the 11th Circuit pauses it as too close to an election. |
| **May 2024** | **Settlement.** The Commission approves, 4–1, a **new map drawn by the plaintiffs and the ACLU**, aligned to natural boundaries — the Miami River, railroad tracks, major roadways — and reconnecting split neighbourhoods. |

**That settlement map governs the 2026 elections**, and it is the map the November 2025 city election was run on.

⚠ **FL-1 recorded that "only the congressional map was litigated after 2022." That is true of the STATE maps and false of Miami's CITY map.** Correct the note in `fl.md`.

**Both published city layers are the settlement map**, and that is measured rather than assumed:

| Service (org `services1.arcgis.com/CvuPhqcTQpZPT9qY`) | Rows | Fields | Edited |
| --- | --- | --- | --- |
| **`Commission_Districts/0`** | 5 | `COMDISTID`, `COMNAME`, `ADDRESS`, `PHONE`, `EMAIL`, `WEBSITE` | schema **2024-07-08**, data **2025-12-17** |
| `Commission_Districts_New/0` | 5 | `COMDISTID`, `Agency`, `CommDist` | all **2025-06-24** |

Per-district symmetric difference: **0.0096 … 0.0940 sq mi**; union symdiff **0.0134 sq mi** on a 56 sq mi city. **Two digitizations of one map**, so `Commission_Districts` is the primary and `_New` is a genuine independent cross-check.

⚠ **The service named `_New` holds the OLDER data edit.** Its schema date is 2025-06-24; the primary's data was refreshed 2025-12-17, right after the December runoff, when the roster changed. **Third wave running in which a service's name is not authority for its vintage** — after Palm Beach's `CountyCommission_2022` containing layer `CountyCommission_2026`.
⚠ **`Commission_Districts.ADDRESS` IS FABRICATED**: District 1 reads `3500 Pan American Drive`, D2 `3501`, D3 `3502`, D4 `3503`, D5 `3504` — Miami City Hall's address incremented per district. **Never read it.** The real anchor address is 3500 for all of them.

### 🔴 Miami-Dade's districts tile the county EXACTLY — the opposite of Palm Beach

| Quantity | Miami-Dade (13) | Palm Beach (7), for contrast |
| --- | --- | --- |
| Union of districts | **2,389.322** sq mi | 2,227.669 sq mi |
| TIGER county polygon | **2,389.321** sq mi | 2,383.201 sq mi |
| **Uncovered** | **0.0315** sq mi | **155.5381** sq mi |
| Overhang | 0.0320 sq mi | 0.0060 sq mi |
| Self-overlap | **0.0000** sq mi | 0.012 sq mi |

🔴 **So FL-5's structural gate FAILS HERE, on correct data.** That gate requires *exactly one* uncovered part above 0.05 sq mi, offshore, in a 150–160 sq mi band. Miami-Dade leaves **no** such gap: its districts cover Biscayne Bay and the offshore water that Palm Beach's stop short of.

**Use a Leon-style tight tolerance instead** — uncovered, overhang and self-overlap each ≤ **0.25** sq mi, which is 8× the worst measured value and 97× smaller than the smallest district (13, at 24.323 sq mi).

⚠ **Two adjacent counties, opposite conventions, and neither gate is portable.** Record it: **measure the tiling before choosing the gate, every time.**

**Miami city vs TIGER place `1245000`:** union 55.936 against 56.073 sq mi — **uncovered 0.4428, overhang 0.3056** (0.79% and 0.55%). Two agencies' city boundaries, so a real agreement rather than an identity. Gate at **1.0 sq mi**, and keep the load-bearing assertion that TIGER covers City Hall.

### Per-district measurements

**Miami-Dade — `X0040`.** All 13 `ST_IsValid`, single-part. Every interior point verified to fall inside exactly one district.

| D | sq mi | interior point (lon, lat) | D | sq mi | interior point |
| --- | --- | --- | --- | --- | --- |
| 1 | 33.372 | -80.254245, 25.934698 | 8 | 188.016 | -80.229851, 25.564458 |
| 2 | 28.911 | -80.234222, 25.865057 | 9 | **1111.772** | -80.511737, 25.401600 |
| 3 | 26.175 | -80.200758, 25.831319 | 10 | 30.111 | -80.359198, 25.733445 |
| 4 | 61.584 | -80.116251, 25.880842 | 11 | 213.728 | -80.651537, 25.685401 |
| 5 | 50.141 | -80.100963, 25.797388 | 12 | 469.889 | -80.598434, 25.870111 |
| 6 | 35.926 | -80.297781, 25.772683 | 13 | 24.323 | -80.308131, 25.898553 |
| 7 | 115.374 | -80.206602, 25.690727 | | | |

⚠ **District 9 is 1,111 sq mi and District 13 is 24.3 — a 46× range.** Percentage tolerance only.

**Miami city — `X0041`.** All 5 `ST_IsValid`, single-part.

| D | sq mi | interior point (lon, lat) |
| --- | --- | --- |
| 1 | 7.252 | -80.235383, 25.793254 |
| 2 | 26.299 | -80.172787, 25.771206 |
| 3 | 4.377 | -80.211016, 25.763328 |
| 4 | 7.486 | -80.242542, 25.755484 |
| 5 | 10.523 | -80.201079, 25.812268 |

**Negative and mixed controls, all measured:**

| Point | Miami-Dade hits | Miami city hits | Purpose |
| --- | --- | --- | --- |
| Fort Lauderdale, Broward — `-80.1373, 26.1224` | **0** | **0** | across the north county line |
| Key West, Monroe — `-81.7800, 24.5551` | **0** | **0** | across the south-west county line |
| **Hialeah — `-80.2781, 25.8576`** | **1** | **0** | 🔴 **inside the county, NOT in Miami** |

Hialeah is the control this wave most needs: a large incorporated city inside Miami-Dade that is **not** the City of Miami. It proves the city layer excludes other municipalities rather than covering the county.

### Prod state, measured 2026-08-28/29

| Thing | State |
| --- | --- |
| Miami-Dade County district (`12086`/`G4020`/`COUNTY`) | **exists** — reuse. `num_officials` NULL; leave it. Will carry the Mayor + 5 officers = 6 offices. |
| Miami-Dade county polygon (`12086`/`G4020`) | exists, 2,389.321 sq mi |
| Miami place polygon (`1245000`/`G4110`) | exists (FL-1), 56.073 sq mi |
| Miami district row | **absent** — this wave creates `Miami Citywide` |
| Offices on the Miami-Dade county district | **ZERO** — greenfield |
| `governments` rows for `12086` / `1245000` | **both absent** |
| `X0040`, `X0041` boundaries | 0 and 0 |
| Politician reuses required | **ONE** — `Oliver Gilbert`, `-1212402` |
| Other name collisions among the 25 | **ZERO** — 8 near-misses, all verified distinct people |
| `12086` `G6350` ZCTA twin | **present**, `state = '36'` (New York) |
| `offices_missing_terms` | 820 / 165 / **655** unflagged, threshold 699 |
| HD-113 (`12113`/`G5220`) | **vacant since 2025-11-19**, no holder, on the Nov 2026 ballot |
| Next free migration slots | `CC_0015`, `CC_0016`, `CC_0017` |
| Next free private MTFCCs | `X0040`, `X0041` |

**`external_id`: continue `-(1240000 + n)`.** Miami: Mayor `n = 81`, commissioners `n = 82…86`. Miami-Dade: Mayor `n = 91`, commissioners `n = 92…104`, officers `n = 105…109`.
🔴 **District 1's slot `n = 93` is DELIBERATELY LEFT UNUSED** — Oliver Gilbert reuses `-1212402`. Record the gap so a later reader does not read it as an off-by-one. The wave's **new** sub-range is `-1240109 … -1240081`, 28 slots for 24 new people.
**FL-3/4/5 own `-1240075 … -1240001`** and must keep re-running clean.

### Template rows

`governments`:

| name | type | state | city | geo_id |
| --- | --- | --- | --- | --- |
| `City of Miami, Florida, US` | `City` | `FL` | `Miami` | `1245000` |
| `Miami-Dade County, Florida, US` | `County` | `FL` | *(NULL)* | `12086` |

`chambers` — ⚠ **`slug` is GENERATED from `name_formal` and cannot be inserted.**

| government | name | name_formal | official_count |
| --- | --- | --- | --- |
| Miami | `City Commission` | `Miami City Commission` | 5 |
| Miami | `Office of the Mayor` | `Office of the Mayor of Miami` | 1 |
| Miami-Dade | `Board of County Commissioners` | `Miami-Dade County Board of County Commissioners` | 13 |
| Miami-Dade | `Office of the Mayor` | `Office of the Mayor of Miami-Dade County` | 1 |
| Miami-Dade | `Elected Officials` | `Miami-Dade County Elected Officials` | 5 |

⚠ **Two chambers named `Office of the Mayor` in one wave, in two governments.** `slug` is generated from `name_formal`, which differs, so they cannot collide — but every chamber lookup must pair `name` with `government_id`, never `name` alone.

`districts`:

| label | district_type | geo_id | mtfcc | num_officials |
| --- | --- | --- | --- | --- |
| `Miami Citywide` | `LOCAL` | `1245000` | `G4110` | *(NULL — matches Bradenton)* |
| `Miami City Commission District 1…5` | `LOCAL` | `miami-fl-commission-district-1…5` | `X0041` | 1 |
| `Miami-Dade County Commissioner District 1…13` | `COUNTY` | `miami-dade-fl-commissioner-district-1…13` | `X0040` | 1 |

`offices`, all `voting_powers = 'full'`, `representing_state = 'FL'`:

| chamber | titles |
| --- | --- |
| Miami City Commission | `Commissioner, District 1` … `District 5` |
| Miami Office of the Mayor | `Mayor` |
| Miami-Dade BOCC | `Commissioner, District 1` … `District 13` |
| Miami-Dade Office of the Mayor | `Mayor` |
| Miami-Dade Elected Officials | `Clerk of the Court and Comptroller`, `Property Appraiser`, `Sheriff`, `Supervisor of Elections`, `Tax Collector` |

⚠ **`Commissioner, District 1` exists TWICE** — once in Miami's commission on `X0041`, once in Miami-Dade's on `X0040`. The office uniqueness key is `(chamber_id, district_id, title)`, so they cannot collide, but **no gate may count offices by title alone across both governments.**
⚠ **`Mayor` also exists twice.** Same rule.
⚠ Miami's own page prints `District 1 Commissioner`; this plan writes `Commissioner, District 1` to match Leon, Manatee and Palm Beach. **That is a deliberate normalisation of word order, not of content** — and it is the one place this plan overrides "follow the publisher", because four other Florida bodies already use the comma form. Record it.

### Decisions this plan makes

1. **Miami and Miami-Dade are two governments, five chambers, three migrations.** No consolidation.
2. **Both Mayors are separate offices in their own chamber** — Miami's by charter ("mayor-city commissioner plan"), Miami-Dade's by its veto power. Bradenton's shape, twice.
3. **Oliver Gilbert is REUSED at `-1212402`**, and `n = 93` is left unused. The band guard splits into an absence assertion plus a positive one.
4. **State Attorney and Public Defender are NOT seated**, confirmed this time by the county's own publishers.
5. **The Clerk's title comes from the office's own site** — `Clerk of the Court and Comptroller`.
6. **`Commissioner, District N` word order is normalised** across both governments.
7. **The tiling gate is Leon-style tight (≤ 0.25 sq mi) for the county and 1.0 sq mi for the city** — FL-5's structural gate is not portable here.
8. **Two anchors**, and probe A asserts that its state-representative slot is **empty**.
9. **Chairman, Vice Chairman and any Miami Chair are ROLES, not offices.** Miami-Dade's are elected by the commissioners for **two-year** terms — longer than Palm Beach's annual mayoralty, same ruling.

### Out of scope, considered

- **State Attorney and Public Defender of the 11th Judicial Circuit** — see above.
- **Miami-Dade County School Board, 9 members by district** (`District 01`…`09` in the SOE roster). Out, as Manatee's, Leon's and Palm Beach's were. **No elected Superintendent** — Miami-Dade's is appointed by the School Board.
- 🔴 **Miami-Dade's COMMUNITY COUNCILS** — an elected body no earlier Florida county had. The SOE roster lists ~60 seats across Community Council Areas 02–16, by subarea plus at-large plus a Commission appointee per area, **and roughly a dozen are `Vacant`**. Out of scope: they are neither a county commission nor a constitutional officer, and spec §3 stage 4 is "commission layer + county officers". ▶ Record them in `fl.md` — they are the largest single block of unmodelled elected local offices found anywhere in the program so far.
- **South Dade Soil & Water Conservation District** (5 groups), and every municipality in Miami-Dade other than Miami — **Hialeah, Miami Beach, Coral Gables and 30-odd others.**
- ⚠ **Miami's Mayor has proposed expanding the Commission from five to nine members.** A proposal, not law. **Seat five.**
---

## Task 0: Establish the worktree and the slot numbers

**Files:** none — this task only measures.

🔴 **This task exists because the branch moved under the plan.** Skipping it is how a wave takes `CC_0006` when the real next free slot is `CC_0015`.

- [x] **Step 1: Find the worktree that is on the knight branch**

```bash
cd /c/EV-Accounts && git worktree list && git fetch origin
```

Measured 2026-08-29: `C:/EV-Accounts` was on `feat/compass-user-lenses` and `C:/ev-accounts-coverage` on `fix/ut-county-coverage-seats`. **Neither was on `docs/knight-cities-program`**, which sits at `ec99f5d3` locally and on the remote.

Pick one, in this order of preference:

1. A worktree already on `docs/knight-cities-program`.
2. **A new worktree for it** — non-destructive, and the repo already runs three:
   `git worktree add /c/ev-accounts-knight docs/knight-cities-program`
3. Switching an existing worktree — **only if its tracked tree is clean AND you know no other session is using it.** `git status --short --untracked-files=no` must be empty.

⚠ **Do not `git checkout` over another session's branch on a hunch.** Two sessions have already swept each other's staged files in this repo.

- [x] **Step 2: Confirm the slots from the branch, not from a bare `ls`**

```bash
cd <knight-worktree>/backend && npm run check:migrations && \
ls migrations/ | grep -oE '^CC_[0-9]{4}' | sort -u | tail -3 && \
psql "$DATABASE_URL" -At -c "SELECT max(mtfcc) FROM essentials.geofence_boundaries WHERE mtfcc LIKE 'X%';"
```

Expect the highest `CC_` slot to be **`CC_0014`** and the highest `X` code **`X0039`**. If `ls` reports `CC_0005`, you are on the wrong branch — go back to Step 1. `check:migrations` must be green.

---

## Task 1: Miami-Dade commission district boundaries — load 13 districts as `X0040`

**Files:**
- Create: `backend/scripts/load-miami-dade-commission-boundaries.ts`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: 13 rows in `essentials.geofence_boundaries`, `mtfcc = 'X0040'`, `state = 'fl'`,
  `geo_id = 'miami-dade-fl-commissioner-district-' || n` for `n` in 1..13, all SRID 4326.

- [x] **Step 1: Copy FL-5's loader — NOT FL-4's**

```bash
cd <knight-worktree>/backend && cp scripts/load-palm-beach-commission-boundaries.ts scripts/load-miami-dade-commission-boundaries.ts
```

FL-5's is the one with the `ST_SRID` post-insert check and the blank-row skip. **Read it end to end**, then make the changes below. 🔴 **Its structural tiling gate is the one thing you must REPLACE, not re-point** — see Step 4.

- [x] **Step 2: Re-point the constants, and pick the primary deliberately**

```ts
const ORG = 'https://services.arcgis.com/8Pc9XBTAsYuxx9Ny/arcgis/rest/services';

/** PRIMARY. 13 polygons, ID SmallInteger, COMMNAME current as of 2026-08-29. */
const PRIMARY_URL =
  `${ORG}/CommissionDistrict_gdb/FeatureServer/0/query` +
  '?where=1%3D1&outFields=ID' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

/**
 * 🔴 THERE IS NO INDEPENDENT CROSS-CHECK FOR THIS LAYER, AND THAT IS A FINDING.
 *
 * The other three published polygon services are HISTORICAL VINTAGES --
 * CommissionDistrict2011, CommissionDistrict2001_gdb, CommissionDistrict1992_gdb --
 * and TBLCOMMISSIONDISTRICT is a TABLE with no geometry at all. So unlike Palm
 * Beach (two digitizations of one map) and Miami city (likewise), Miami-Dade
 * publishes exactly ONE current digitization.
 *
 * The 2011 layer is therefore used as a NEGATIVE control -- it must DIFFER -- not
 * as a cross-check that must agree. See Step 5.
 */
const VINTAGE_2011_URL =
  `${ORG}/CommissionDistrict2011/FeatureServer/0/query` +
  '?where=1%3D1&outFields=ID' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

const MTFCC = 'X0040';
const STATE_CODE = 'fl';
const SOURCE = 'miamidade-agol-CommissionDistrict_gdb-0-2026-08-29';
const GEO_ID_PREFIX = 'miami-dade-fl-commissioner-district-';
const COUNTY_GEO_ID = '12086';
const EXPECTED_COUNT = 13;
const DISTRICTS = ['1','2','3','4','5','6','7','8','9','10','11','12','13'] as const;
```

⚠ **The district-key regex must accept TWO digits.** FL-5's is `/^[1-7]$/`; here it is `/^(1[0-3]|[1-9])$/`. A `/^[1-9]$/` copy would silently skip districts 10–13 and then report "expected 13, got 9".

🔴 **Do not read `COMMNAME`.** It is current today, and `CommissionDistrict2011` and `TBLCOMMISSIONDISTRICT` both prove the failure mode from the same publisher — they still name Jean Monestime and Sally A. Heyman. Request `ID` only.

- [x] **Step 3: Set the per-district area expectations and control points**

```ts
/** Measured 2026-08-29 from the reprojected 4326 geometry via ::geography. */
const EXPECTED_SQ_MI: Record<string, number> = {
  '1': 33.372, '2': 28.911, '3': 26.175, '4': 61.584, '5': 50.141,
  '6': 35.926, '7': 115.374, '8': 188.016, '9': 1111.772, '10': 30.111,
  '11': 213.728, '12': 469.889, '13': 24.323,
};

/** Every point verified 2026-08-29 to fall inside exactly one district. */
const CONTROL_POINTS = [
  { name: 'MDC Government Center (111 NW 1st St)', lon: -80.196332709513, lat: 25.775078850443, district: '5' },
  { name: 'Miami City Hall (3500 Pan American Dr)', lon: -80.234992579394, lat: 25.728661855119, district: '7' },
  { name: 'District 1 interior',  lon: -80.254245, lat: 25.934698, district: '1' },
  { name: 'District 2 interior',  lon: -80.234222, lat: 25.865057, district: '2' },
  { name: 'District 3 interior',  lon: -80.200758, lat: 25.831319, district: '3' },
  { name: 'District 4 interior',  lon: -80.116251, lat: 25.880842, district: '4' },
  { name: 'District 5 interior',  lon: -80.100963, lat: 25.797388, district: '5' },
  { name: 'District 6 interior',  lon: -80.297781, lat: 25.772683, district: '6' },
  { name: 'District 7 interior',  lon: -80.206602, lat: 25.690727, district: '7' },
  { name: 'District 8 interior',  lon: -80.229851, lat: 25.564458, district: '8' },
  { name: 'District 9 interior',  lon: -80.511737, lat: 25.401600, district: '9' },
  { name: 'District 10 interior', lon: -80.359198, lat: 25.733445, district: '10' },
  { name: 'District 11 interior', lon: -80.651537, lat: 25.685401, district: '11' },
  { name: 'District 12 interior', lon: -80.598434, lat: 25.870111, district: '12' },
  { name: 'District 13 interior', lon: -80.308131, lat: 25.898553, district: '13' },
];

const NEGATIVE_CONTROLS = [
  { name: 'Fort Lauderdale, Broward County', lon: -80.1373, lat: 26.1224 },
  { name: 'Key West, Monroe County',         lon: -81.7800, lat: 24.5551 },
];

const AREA_TOLERANCE_PCT = 1;   // measured differences were 0.00%
const TILING_TOLERANCE_SQ_MI = 0.25;
```

⚠ **Percentage tolerance only.** District 9 is 1,111.772 sq mi and District 13 is 24.323 — a 46× range, wider than Palm Beach's 43×.

- [x] **Step 4: REPLACE FL-5's structural gate with a tight tiling gate**

FL-5's gate demands *exactly one* uncovered part above 0.05 sq mi, offshore, sized 150–160 sq mi. **Miami-Dade has no such gap and would fail it.** Measured 2026-08-29: uncovered **0.0315**, overhang **0.0320**, self-overlap **0.0000** against TIGER `12086`, whose area the union matches to **0.001 sq mi**.

Use the Leon-shaped gate — three quantities, one tolerance:

```sql
WITH d AS (SELECT public.ST_Multi(public.ST_MakeValid(
             public.ST_SetSRID(public.ST_GeomFromGeoJSON(gj), 4326))) g
             FROM unnest($1::text[]) AS gj),
     u AS (SELECT public.ST_UnaryUnion(public.ST_Collect(g)) g FROM d),
     c AS (SELECT geometry g FROM essentials.geofence_boundaries
            WHERE geo_id = $2 AND mtfcc = 'G4020')
SELECT (public.ST_Area(public.ST_Difference(c.g, u.g)::geography) / $3)::numeric(12,4) AS county_uncovered,
       (public.ST_Area(public.ST_Difference(u.g, c.g)::geography) / $3)::numeric(12,4) AS overhang,
       (SELECT coalesce(sum(public.ST_Area(public.ST_Intersection(x.g, y.g)::geography) / $3), 0)::numeric(12,4)
          FROM d x JOIN d y ON public.ST_AsBinary(x.g) < public.ST_AsBinary(y.g)
         WHERE public.ST_Intersects(x.g, y.g)) AS self_overlap
  FROM u, c
```

Fail if any exceeds `TILING_TOLERANCE_SQ_MI`. Put the reason in the message:

> `The 13 districts do not tile Miami-Dade County within 0.25 sq mi. Measured 2026-08-29:`
> `0.0315 uncovered / 0.0320 overhang / 0.0000 self-overlap. NOTE: Palm Beach's districts`
> `stop at the shoreline and leave 155 sq mi of Atlantic uncovered; Miami-Dade's cover the`
> `bay and the offshore. DO NOT import FL-5's structural gate here, and do not widen this`
> `one -- the smallest district is 24.3 sq mi.`

🔴 **`c` must pair `geo_id` with `mtfcc`.** `12086` also matches a **New York ZIP code** in this table.

- [x] **Step 5: Add the vintage gate — the 2011 layer must DIFFER, on a district that moved**

🔴 **CORRECTED IN PLACE 2026-08-29: THIS GATE RUNS *FIRST*, NOT FIFTH.** Written in the order below it
can never speak — all 17 control points pass on the 2011 map, and the area gate fires first with a
message that invites re-baselining onto it. It is GATE 1 in the loader, ahead of the control points.
See the Task 1 deviations section.

This is the gate no earlier wave needed, and Miami-Dade is the reason.

```ts
/**
 * 🔴 THE VINTAGE GATE. CommissionDistrict2011 has the SAME field names, the SAME
 * geometry type and the SAME row count as the primary. A loader pointed at it
 * returns 13 valid polygons with plausible numbers and nothing errors.
 *
 * Measured symmetric difference, primary vs 2011, per district:
 *   D1 0.136   D2 1.325   D3 0.805   D4 5.385   D5 7.816
 *   D6 10.205  D7 16.339  D8 67.718  D9 126.132 D10 2.541
 *   D11 12.070 D12 6.291  D13 3.347
 *
 * 🔴 DISTRICT 1 MOVED BY 0.136 sq mi. A spot check there would PASS on the wrong
 * map. The gate therefore checks the districts that actually moved.
 */
const VINTAGE_MUST_DIFFER: Array<{ district: string; minSqMi: number }> = [
  { district: '9', minSqMi: 100 },   // measured 126.132
  { district: '8', minSqMi: 50 },    // measured  67.718
  { district: '7', minSqMi: 10 },    // measured  16.339
];
```

Assert, for each: `symdiff(primary[d], vintage2011[d]) >= minSqMi`. If any comes back **small**, the primary URL is pointing at a historical vintage — abort with:

> `District <d> is only <x> sq mi different from the 2011 map, expected at least <min>.`
> `PRIMARY_URL is probably pointing at a historical vintage. The current plan is the 2022`
> `apportionment; CommissionDistrict2011/2001_gdb/1992_gdb are all still published.`

⚠ **Also assert `TBLCOMMISSIONDISTRICT` is not usable as geometry**, once, as a documented probe: fetch it and confirm every feature has **no** geometry. It is named like the primary and returns 13 rows; a future editor will reach for it.

- [x] **Step 6: Dry-run, prove three gates can fail, then load**

```bash
cd <knight-worktree>/backend && npx tsx scripts/load-miami-dade-commission-boundaries.ts --dry-run
```

Then prove the gates on **throwaway copies** under `scripts/_gateproof-*.ts`, deleting them afterwards — the FL-5 method:

1. Set `EXPECTED_SQ_MI['9']` to `1000` → the area gate must fail District 9 with a percentage.
2. Point `PRIMARY_URL` at `CommissionDistrict2011` → **the vintage gate must fail**, and the area gate should fail too. Confirm the *vintage* message appears; that is the one a future editor needs.
3. Drop `'13'` from `DISTRICTS` → the tiling gate must fail on `county_uncovered` (District 13 is 24.323 sq mi, ~97× the tolerance).

Then load:

```bash
cd <knight-worktree>/backend && npx tsx scripts/load-miami-dade-commission-boundaries.ts
```

- [x] **Step 7: Verify from the DATABASE**

```bash
cd <knight-worktree>/backend && psql "$DATABASE_URL" -At -F ' | ' -c "
SELECT geo_id, ST_GeometryType(geometry), ST_IsValid(geometry), ST_NumGeometries(geometry),
       ST_SRID(geometry), round((ST_Area(geometry::geography)/2589988.110336)::numeric,3)
  FROM essentials.geofence_boundaries WHERE mtfcc = 'X0040' ORDER BY length(geo_id), geo_id;"
```

Expect 13 rows, all `ST_MultiPolygon` (the insert wraps in `ST_Multi`, as every FL loader does), `t`, `1` part, **`4326`**, areas matching Step 3 to three decimals.

⚠ **`ORDER BY length(geo_id), geo_id`** — a plain lexical sort puts district 10 before district 2.

- [x] **Step 8: Commit**

Commit message:

```
feat(knight-fl): load Miami-Dade's 13 commission districts as X0040

Thirteen single-member districts, all valid, single-part, SRID 4326, areas
matching the 2026-08-29 measurement to 0.00%.

The districts tile TIGER county 12086 almost exactly -- 0.0315 sq mi uncovered,
0.0320 overhang, 0.0000 self-overlap -- which is the OPPOSITE of Palm Beach,
whose districts stop at the shoreline and leave 155 sq mi of Atlantic uncovered.
FL-5's structural gate would fail here on correct data, so this uses a Leon-style
tight tolerance instead. Two adjacent counties, two conventions, neither gate
portable: measure the tiling before choosing the gate.

New gate class: A VINTAGE GATE. Miami-Dade publishes four polygon vintages
(current, 2011, 2001, 1992) plus TBLCOMMISSIONDISTRICT, which is named like the
primary and has no geometry at all. The 2011 layer has the same field names, the
same geometry type and the same row count as the current one, so a loader pointed
at it returns 13 plausible polygons with no error. The gate asserts the 2011 map
MUST DIFFER, and checks districts 9, 8 and 7 -- because district 1 moved by only
0.136 sq mi and a spot check there would pass on the wrong map.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
```

---

## Task 2: Miami city commission district boundaries — load 5 districts as `X0041`

**Files:**
- Create: `backend/scripts/load-miami-city-commission-boundaries.ts`

**Interfaces:**
- Produces: 5 rows, `mtfcc = 'X0041'`, `state = 'fl'`,
  `geo_id = 'miami-fl-commission-district-' || n` for `n` in 1..5.

- [x] **Step 1: Copy Task 1's loader and re-point it**

🔴 **CORRECTED IN PLACE 2026-08-29: FOUR SERVICES ON THIS ORG LOOK LIKE COMMISSION DISTRICTS, NOT TWO.**
`Enriched Commission Districts` is a **2017 pre-litigation vintage with identical field names** and
needs a VINTAGE GATE, run FIRST; `District_<32 hex>` is 13 neighbourhood polygons carrying the newest
edit date on the server. See the Task 2 deviations section.

```ts
const ORG = 'https://services1.arcgis.com/CvuPhqcTQpZPT9qY/arcgis/rest/services';

/** PRIMARY. Schema last edited 2024-07-08, right after the May 2024 settlement;
 *  data last edited 2025-12-17, right after the December runoff. */
const PRIMARY_URL =
  `${ORG}/Commission_Districts/FeatureServer/0/query` +
  '?where=1%3D1&outFields=COMDISTID' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

/** CROSS-CHECK: an independent digitization of the SAME settlement map.
 *  ⚠ Named "_New" but its data edit is OLDER (2025-06-24). The name is not the
 *  vintage -- third wave running. */
const CROSSCHECK_URL =
  `${ORG}/Commission_Districts_New/FeatureServer/0/query` +
  '?where=1%3D1&outFields=COMDISTID' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

const MTFCC = 'X0041';
const SOURCE = 'miamigis-agol-Commission_Districts-0-2026-08-29';
const GEO_ID_PREFIX = 'miami-fl-commission-district-';
const PLACE_GEO_ID = '1245000';
const EXPECTED_COUNT = 5;
const DISTRICTS = ['1','2','3','4','5'] as const;

const EXPECTED_SQ_MI: Record<string, number> = {
  '1': 7.252, '2': 26.299, '3': 4.377, '4': 7.486, '5': 10.523,
};

const CONTROL_POINTS = [
  { name: 'Miami City Hall (3500 Pan American Dr)', lon: -80.234992579394, lat: 25.728661855119, district: '2' },
  { name: 'MDC Government Center (111 NW 1st St)',  lon: -80.196332709513, lat: 25.775078850443, district: '5' },
  { name: 'District 1 interior', lon: -80.235383, lat: 25.793254, district: '1' },
  { name: 'District 2 interior', lon: -80.172787, lat: 25.771206, district: '2' },
  { name: 'District 3 interior', lon: -80.211016, lat: 25.763328, district: '3' },
  { name: 'District 4 interior', lon: -80.242542, lat: 25.755484, district: '4' },
  { name: 'District 5 interior', lon: -80.201079, lat: 25.812268, district: '5' },
];

/** 🔴 HIALEAH IS THE CONTROL THIS WAVE MOST NEEDS: a large incorporated city
 *  INSIDE Miami-Dade that is NOT the City of Miami. Measured 0 city hits. */
const NEGATIVE_CONTROLS = [
  { name: 'Hialeah (in Miami-Dade, NOT in Miami)', lon: -80.2781, lat: 25.8576 },
  { name: 'Fort Lauderdale, Broward County',       lon: -80.1373, lat: 26.1224 },
];

const AREA_TOLERANCE_PCT = 1;
const CROSSCHECK_TOLERANCE_SQ_MI = 0.25;  // measured max 0.0940
const PLACE_TOLERANCE_SQ_MI = 1.0;        // measured 0.4428 / 0.3056
```

🔴 **Do NOT read `COMNAME`, and do NOT read `ADDRESS` for anything.** `ADDRESS` is **fabricated** — District 1 says `3500 Pan American Drive`, D2 `3501`, D3 `3502`, D4 `3503`, D5 `3504`, which is City Hall's address incremented per district. Request `COMDISTID` only.

- [x] **Step 2: Gate against the TIGER place polygon, not the county**

Measured 2026-08-29: union 55.936 vs TIGER `1245000`'s 56.073 sq mi — **uncovered 0.4428, overhang 0.3056**. Two agencies' city boundaries differ by annexation timing, so:

| Assertion | Threshold | Measured |
| --- | --- | --- |
| uncovered vs place | ≤ 1.0 sq mi | 0.4428 |
| overhang vs place | ≤ 1.0 sq mi | 0.3056 |
| self-overlap | ≤ 0.25 sq mi | *(measure it; expect ~0)* |
| cross-check symdiff, per district | ≤ 0.25 sq mi | 0.0096 … 0.0940 |

🔴 **The load-bearing assertion is that TIGER place `1245000` COVERS Miami City Hall** — `CC_0015` hangs the Mayor off that polygon, and if it does not cover the anchor the Mayor is unreachable from the wave's own probe address.

⚠ **Do NOT gate the city districts against the county polygon.** Miami is ~56 sq mi inside a 2,389 sq mi county; a county-tiling gate would be meaningless.

- [x] **Step 3: Record the litigation history in the file header**

The loader's header must carry this, because the map's provenance is the least obvious thing about it:

```
🔴 MIAMI'S CITY COMMISSION MAP WAS STRUCK DOWN TWICE BY A FEDERAL COURT.
   2022 map: adopted, sued (ACLU of Florida).
   2023 map: adopted after the suit, ALSO held unconstitutional.
   April 2024: Judge K. Michael Moore holds BOTH racially gerrymandered.
   May 2024: settlement -- the Commission adopts, 4-1, a map drawn by the
   plaintiffs, aligned to the Miami River, railroads and major roadways.
   That settlement map governs 2026 and is what both published layers contain
   (measured: they agree to 0.0134 sq mi on the union).
⚠ fl.md's FL-1 note that "only the congressional map was litigated after 2022"
   is true of the STATE maps and FALSE of Miami's city map.
```

- [x] **Step 4: Dry-run, prove two gates, load, verify from the database, commit**

Same discipline as Task 1. Prove (a) the area gate by perturbing `EXPECTED_SQ_MI['2']`, and (b) **the place gate by dropping `'2'` from `DISTRICTS`** — District 2 is 26.299 sq mi, so `uncovered` should jump to ~26 against a 1.0 tolerance.

Verify: 5 rows, `ST_MultiPolygon`, valid, 1 part, SRID 4326, areas to three decimals.

Commit message:

```
feat(knight-fl): load Miami's 5 city commission districts as X0041

The settlement map, and its provenance is the point: Miami's 2022 and 2023
commission maps were BOTH held unconstitutionally racially gerrymandered by a
federal judge in April 2024, and the map in force is the one the Commission
adopted 4-1 in a May 2024 settlement, drawn by the plaintiffs and aligned to the
Miami River, railroads and major roads.

Both published layers are that map -- they agree to 0.0134 sq mi on the union, so
Commission_Districts is the primary and Commission_Districts_New is a genuine
independent cross-check. ⚠ The one named "_New" holds the OLDER data edit.

The layer's ADDRESS field is fabricated: City Hall's address incremented per
district. Not read. Neither is COMNAME.

Hialeah is the load-bearing control -- a large incorporated city inside
Miami-Dade that is not Miami, and it returns zero city districts.

fl.md's FL-1 note that only the congressional map was litigated after 2022 is
true of the state maps and false of Miami's city map. Corrected at Task 6.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
```

---

## Task 3: Reconcile both rosters and write `ROSTERS.md`

**Files:**
- Create: `backend/data/seed-miami-dade-2026/ROSTERS.md`
- Create (untracked working copies): `_soe-elected-officials.pdf`, `_mia-officials.html`,
  `_mdc-commission.html`, `_mdc-mayor.html`, `_mdc-constitutional-offices.html`,
  `_off-clerk.html`, `_off-pa.html`, `_off-soe.html`, `_off-sheriff.html`, `_off-tax.html`

**Interfaces:**
- Produces `ROSTERS.md` with **TWO** tables, in `parseRosters`' existing column order
  `Seat | Slug | Name | external_id | term_start | precision | how_started | source`:
  `### City of Miami` (6 rows) and `### Miami-Dade County` (19 rows), plus
  `<!-- COUNTS: city_offices=6 city_people=6 county_offices=19 county_people=19 vacancies=0 -->`.
  **This is FL-4's two-table shape, not FL-5's one-table shape.**

- [x] **Step 1: Pull the sources — the SOE PDF first**

```bash
cd <knight-worktree>/backend && mkdir -p data/seed-miami-dade-2026 && D=data/seed-miami-dade-2026 && \
curl -s -m 60 -L "https://www.miamidade.gov/elections/library/reports/elected-officials.pdf" -o "$D/_soe-elected-officials.pdf" && \
curl -s -m 30 -L "https://www.miami.gov/Government/City-Officials" -o "$D/_mia-officials.html" && \
curl -s -m 30 -L "https://www.miamidade.gov/global/government/commission/home.page" -o "$D/_mdc-commission.html" && \
curl -s -m 30 -L "https://www.miamidade.gov/global/government/mayor/home.page" -o "$D/_mdc-mayor.html" && \
curl -s -m 30 -L "https://www.miamidade.gov/global/management/constitutional-offices.page" -o "$D/_mdc-constitutional-offices.html" && \
curl -s -m 30 -L "https://www.miamidadeclerk.gov/" -o "$D/_off-clerk.html" && \
curl -s -m 30 -L "https://www.miamidadepa.gov/" -o "$D/_off-pa.html" && \
curl -s -m 30 -L "https://www.miamidade.gov/elections/home.asp" -o "$D/_off-soe.html" && \
ls -la "$D"
```

**Every one of these answers `curl`.** ⚠ `www.miami.gov/...` returns **403 to WebFetch but 200 to `curl`** — the opposite of Palm Beach's Clerk. Do not conclude a host is blocked from one tool's failure.
⚠ The Sheriff's and Tax Collector's own domains did not resolve on 2026-08-29 (`miamidadesheriff.gov` 404, `miamidadetaxcollector.gov` DNS failure). **The correct domains are `mdcsheriff.gov` / `mdctaxcollector.gov`** — confirm, or take those two from the SOE PDF plus the county page.

- [x] **Step 2: Read the SOE PDF pages 1–3 and take the structure from it**

🔴🔴 **CORRECTED IN PLACE 2026-08-29: EXTRACT WITH `pdftotext -table`, NEVER `-layout`.** Under
`-layout` the name column is offset from the office column by a varying number of rows and EVERY row
is misassigned — plausibly, with real people in real offices. It puts *Vacant* on **HD-112**, and the
acceptance probe depends on **HD-113**. See the Task 3 deviations section.
⚠ The `pdftotext` on this machine is Xpdf 4.00, which has no `-bbox`. Confirm the tool before
trusting the text.

Pages 2–3 carry all 19 Miami-Dade seats. It is the only combined roster in the wave and it is authoritative for **office titles and structure**.

⚠ **It is dated "As of June 4, 2026" and it is stale for fast-churning occupancy** — it still lists Daniel Anthony Perez in HD-116, which prod records vacant since 2026-08-22. **Use it for structure; confirm every occupant against that office's own publisher.**
⚠ **It has NO municipal offices.** Miami's six come from `miami.gov`.

- [x] **Step 3: Establish `term_start` per person**

**The five officers are settled and identical:** `2025-01-07`, **`day`** precision, `how_started = 'elected'` — the day Amendment 10's five independent offices began. Cite the county's Constitutional Offices page.

**The two appointed commissioners need dates and predecessors:**

| Seat | Person | What to find |
| --- | --- | --- |
| District 5 | Vicki L. Lopez | The date the **Commission** appointed her (7–5 vote) after Eileen Higgins resigned to run for Miami mayor. `how_started = 'appointed'`. |
| District 6 | Natalie Milian Orbis | The date **and the seat she succeeded**. The SOE marks her `Appointed` with a blank term end; the predecessor is not named there. |

**The remaining eleven commissioners and both Mayors** come from each district's own page under
`miamidade.gov/global/government/commission/district<NN>/home.page` (zero-padded, `district01`…`district13`) and the Mayor's page.

🔴 **Read those pages BY EYE.** Palm Beach's district bios appended the predecessor's biography unlabelled, and a regex for `elected in (\d{4})` returned the wrong person by eight years on two of seven pages. **Assume the same shape until proved otherwise.**

**Miami's six** come from `miami.gov`. ⚠ Miami's terms are four years with a **two-term lifetime limit** since a November 2024 charter amendment, and its elections run in **odd** years — the mayoral race was **2025-11-04** with a **2025-12-09 runoff**, which Eileen Higgins won 59–41. ⚠ **The Commission voted to postpone the November 2025 election to 2026 and the election happened anyway**; do not take the postponement vote as the outcome.

⚠ **Take-office rules** must be established per body, as in every earlier wave — Miami-Dade's SOE publishes `Current Term Ends` values of `11/21/2028` (Mayor, commissioners) and `01/02/2029` (officers), which imply the two rules. **`Current Term Ends` is NOT `term_end` and must not be written.**

If a date cannot be sourced, write **`unknown`** precision. FL-5 reached zero unknowns; **that is not a target.**

- [x] **Step 4: Decide the name forms, and record every alternate**

This wave has more naming decisions than any earlier one.

| Slug | `full_name` | `alternate_names` | Why |
| --- | --- | --- | --- |
| `mdc-commissioner-1` | **`Oliver G. Gilbert, III`** | `Oliver Gilbert` | The county page carries the middle initial and suffix; the SOE PDF and **the existing prod row `-1212402`** do not. ⚠ **The prod row's `full_name` is `Oliver Gilbert`** — see Step 5. |
| `mdc-commissioner-13` | **`René Garcia`** | `Rene Garcia` | County page has the accent, SOE PDF does not. **NFD-strip before comparing.** |
| `mdc-commissioner-12` | `Juan Carlos "JC" Bermudez` | `Juan Carlos Bermudez`, `JC Bermudez` | quoted nickname |
| `mdc-commissioner-8` | `Danielle Cohen Higgins` | `Danielle Higgins` | 🔴 **two-word surname — see the warning below** |
| `mdc-sheriff` | `Rosanna "Rosie" Cordero-Stutz` | `Rosie Cordero-Stutz`, `Rosanna Cordero-Stutz` | quoted nickname **and** a hyphenated surname |
| `mia-commissioner-4` | `Ralph "Rafael" Rosado` | `Ralph Rosado`, `Rafael Rosado` | quoted nickname |
| `mia-commissioner-1` | `Miguel Angel Gabela` | `Miguel Gabela` | two given names |
| `mdc-mayor` | `Daniella Levine Cava` | `Daniella Cava` | 🔴 **two-word surname** |
| `mdc-property-appraiser` | `Tomas Regalado` | — | his own site drops the accent |

🔴🔴 **`splitName()` CANNOT HANDLE A TWO-WORD SURNAME, AND THIS WAVE HAS TWO.** On `Danielle Cohen Higgins` it yields `first = Danielle`, `last = Higgins`, `middle = Cohen` → `middleInitial = ''` (because "Cohen" is not a single initial), silently discarding "Cohen". On `Daniella Levine Cava` it yields `first = Daniella`, `last = Cava`, dropping "Levine".

**Decision: `full_name` carries the published form and is what a voter sees, so it is always correct. `first_name`/`last_name` are derived and will be wrong for these two.** Add an explicit `SURNAME_OVERRIDES` map in the generator rather than widening the heuristic:

```js
/** 🔴 Two-word surnames. splitName() takes the LAST token; these need two.
 *  An override is honest; a cleverer heuristic would break "Juan Carlos" next. */
const SURNAME_OVERRIDES = {
  'mdc-commissioner-8': { firstName: 'Danielle', lastName: 'Cohen Higgins' },
  'mdc-mayor':          { firstName: 'Daniella', lastName: 'Levine Cava' },
};
```

⚠ **And widen the suffix regex**, which FL-3's and FL-4's generators still get wrong — copy FL-5's `/,?\s+(Jr\.?|Sr\.?|II|III|IV)\s*$/i`.

- [x] **Step 5: Record the ONE reuse, explicitly and with its evidence**

`ROSTERS.md` must carry a dedicated section. The `external_id` column for `mdc-commissioner-1` is **`-1212402`**, not a `-12400xx` value, and that is the whole point.

Evidence to state: the prod row is `Oliver Gilbert`, `-1212402`, no office, race row `U.S. Representative District 24` / `Congressional District 24` / `geo_id 1224` / `mtfcc G5200`, `is_incumbent = false`. The person is Oliver Gilbert III, former Mayor of Miami Gardens, sitting Commissioner for District 1, **who won the FL-24 Democratic primary on 2026-08-18** and faces Republican T.E. Brown in November.

⚠ **Do not change that row's `full_name`, `is_incumbent` or `data_source`.** The wave adds an `office_terms` row and nothing else. If the published form should be `Oliver G. Gilbert, III`, put it in `alternate_names` — **renaming a row another wave owns is out of scope.**
▶ **If he wins in November he resigns District 1.** Note it as live churn.

- [x] **Step 6: Re-check every seat, then write the file**

Two live situations plus the standing one:

1. **Miami-Dade District 1** — see above.
2. **Districts 5 and 6 are both appointed and both on the 2026 ballot.**
3. **HD-113 stays vacant** through November 2026 per the SOE. Confirm before the apply; probe A depends on it.

Then write the two tables, the counts comment, and prose sections for: the reuse; the four in-wave surname pairs; the Higgins → Lopez → HD-113 chain; the two appointments; the three published Clerk titles and the rule chosen; the excluded offices including the ~60 Community Council seats; and the take-office rules per body.

- [x] **Step 7: Validate mechanically, then commit only `ROSTERS.md`**

Assert: 6 + 19 rows; 25 distinct `external_id`s; **24 inside `-1240109 … -1240081` and exactly one equal to `-1212402`**; `n = 93` absent; every precision in `day|month|year|unknown`; every `how_started` in the CHECK's set; no party marking; no `Superintendent of Schools`, `State Attorney` or `Public Defender`.

```bash
cd <knight-worktree>/backend && git add data/seed-miami-dade-2026/ROSTERS.md && git status --short data/seed-miami-dade-2026/
```

Only `ROSTERS.md` may be staged. 🔴 **The `_*` working copies stay untracked and stay on disk** — they are inputs for Task 4.
---

## Task 4: Generator — three migrations, and a band guard that survives a reuse

**Files:**
- Create: `backend/scripts/gen-miami-dade-migrations.mjs`
- Create: `backend/scripts/gen-miami-dade-migrations.test.ts`
- Create (generated): `CC_wip_miami_structure.sql`, `CC_wip_miami_people.sql`, `CC_wip_miami_dade_county.sql`

**Interfaces:**
- Consumes `ROSTERS.md`; the 13 `X0040` and 5 `X0041` boundaries.
- Produces `parseRosters(md)` → `{ city: Seat[], county: Seat[], counts: { cityOffices, cityPeople, countyOffices, countyPeople, vacancies } }` — **FL-4's two-table shape**, and three migration files.

🔴 **Copy FL-5's generator for its fixes, but restore FL-4's two-table structure.** FL-5 deleted `renderCityStructure`/`renderCityPeople` because Palm Beach had no city half; Miami does. FL-4 has the city renderers but the **narrow suffix regex**, the **unparameterised header** and the **older band guard**. Take FL-5 and re-add the city half from FL-4.

- [x] **Step 1: Copy, then re-add the city half**

```bash
cd <knight-worktree>/backend && cp scripts/gen-palm-beach-migrations.mjs scripts/gen-miami-dade-migrations.mjs && cp scripts/gen-palm-beach-migrations.test.ts scripts/gen-miami-dade-migrations.test.ts
```

From `scripts/gen-tallahassee-leon-migrations.mjs`, bring back `renderCityStructure()` and `renderCityPeople()` and the `'citywide'` / `'ward'` branches of `districtRef()`. **Rename `'ward'` to `'commdist_city'`** — Miami's are commission districts, not wards, and `X0041` is a different code from Bradenton's `X0036`.

- [x] **Step 2: Identity constants**

```js
const WAVE = 'FL-6';
const PLAN = 'docs/superpowers/plans/2026-08-29-knight-fl-wave-6-miami-miami-dade.md';
const ROSTER_REL = 'data/seed-miami-dade-2026/ROSTERS.md';
const GENERATOR = 'scripts/gen-miami-dade-migrations.mjs';

const CITY_MTFCC   = 'X0041';
const COUNTY_MTFCC = 'X0040';
const PLACE_GEO_ID  = '1245000';   // TIGER place, Miami city (G4110). Loaded by FL-1.
const COUNTY_GEO_ID = '12086';     // TIGER county, Miami-Dade (G4020). Pre-existing.
const CITY_DIST_PREFIX   = 'miami-fl-commission-district-';
const COUNTY_DIST_PREFIX = 'miami-dade-fl-commissioner-district-';
const CITY_GOV   = 'City of Miami, Florida, US';
const COUNTY_GOV = 'Miami-Dade County, Florida, US';

const N_CITY_DISTRICTS = 5, N_COUNTY_DISTRICTS = 13, N_OFFICERS = 5;

/** This wave's own contiguous sub-range of NEW ids. Excludes the reuse. */
const OWNED_LO = -1240109;
const OWNED_HI = -1240081;

/**
 * 🔴 THE REUSE. Oliver Gilbert III already exists as a 2026 US House candidate
 * for FL-24. Same person as the District 1 commissioner; verified biography, not
 * a name match. He gets an office_terms row and NO new politician row.
 * ⚠ -1240093 (his slot in the sub-range) is deliberately left unused.
 */
const REUSED_IDS = {
  '-1212402': { slug: 'mdc-commissioner-1', expectFullName: 'Oliver Gilbert' },
};
```

⚠ **The header template must be parameterised from these constants.** FL-4 hardcoded FL-3's strings and shipped three migrations to prod citing the wrong plan and roster; FL-5 fixed it and parameterised its own. **Do not regress it.**

- [x] **Step 3: Split the band guard — an absence assertion plus a positive one**

🔴 **FL-5's guard cannot express this wave.** It asserts "nothing inside `[min..max]` of this wave's ids is owned by anything else". Adding `-1212402` to the owned list stretches `max` from `-1240081` to `-1212402`, sweeping in the whole congressional band and every FL local wave — the guard would refuse on legitimate rows. This is the **fifth** shape of this guard; the previous four are recorded in `CC_0014`.

Emit **two** blocks:

```sql
-- (a) ABSENCE, over this wave's NEW sub-range only.
DO $$
DECLARE v_n int; v_foreign text;
BEGIN
  SELECT count(*), string_agg(external_id::text, ', ' ORDER BY external_id)
    INTO v_n, v_foreign
    FROM essentials.politicians
   WHERE external_id BETWEEN -1240109 AND -1240081
     AND external_id NOT IN (<this wave's NEW ids>);
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'miami-dade: % row(s) inside the new id range -1240109..-1240081 are owned by something else (%)', v_n, v_foreign;
  END IF;
END $$;

-- (b) PRESENCE, for each reused id. The opposite assertion, and it must be
--     positive: the row MUST exist and MUST be the expected person.
DO $$
DECLARE v_name text;
BEGIN
  SELECT full_name INTO v_name FROM essentials.politicians WHERE external_id = -1212402;
  IF v_name IS NULL THEN
    RAISE EXCEPTION 'miami-dade: reused id -1212402 does not exist. It should hold Oliver Gilbert, seeded by the FL 2026 US House wave. Do NOT insert a new row for him -- establish what happened to that one first.';
  END IF;
  IF normalize(lower(v_name), NFD) <> normalize(lower('Oliver Gilbert'), NFD) THEN
    RAISE EXCEPTION 'miami-dade: reused id -1212402 holds "%", expected "Oliver Gilbert". Refusing to seat a stranger on Miami-Dade District 1.', v_name;
  END IF;
END $$;
```

⚠ **`unaccent` is NOT on prod** — use `normalize(lower(x), NFD)`, as the memory note and `CC_0013` both do.
⚠ The politician-insert block must **skip** reused ids so `ON CONFLICT DO NOTHING` is not relied on to protect the existing row. Filter them out of the temp seed table's insert, but **keep them in the occupancy loop** — the office term is exactly what the wave adds.

- [x] **Step 4: The seat maps**

```js
const CITY_SEATS = {
  'mia-mayor':          { title: 'Mayor', chamber: 'Office of the Mayor', on: 'citywide' },
  'mia-commissioner-1': { title: 'Commissioner, District 1', chamber: 'City Commission', on: 'commdist_city', n: 1 },
  // ... 2 through 5
};

const COUNTY_SEATS = {
  'mdc-mayor':           { title: 'Mayor', chamber: 'Office of the Mayor', on: 'countywide' },
  'mdc-commissioner-1':  { title: 'Commissioner, District 1', chamber: 'Board of County Commissioners', on: 'commdist', n: 1 },
  // ... 2 through 13
  'mdc-clerk':               { title: 'Clerk of the Court and Comptroller', chamber: 'Elected Officials', on: 'countywide' },
  'mdc-property-appraiser':  { title: 'Property Appraiser',      chamber: 'Elected Officials', on: 'countywide' },
  'mdc-sheriff':             { title: 'Sheriff',                 chamber: 'Elected Officials', on: 'countywide' },
  'mdc-supervisor-of-elections': { title: 'Supervisor of Elections', chamber: 'Elected Officials', on: 'countywide' },
  'mdc-tax-collector':       { title: 'Tax Collector',           chamber: 'Elected Officials', on: 'countywide' },
};

const FORBIDDEN_TITLES = ['Superintendent of Schools', 'State Attorney', 'Public Defender'];
```

🔴 **Every chamber lookup must pair `name` with `government_id`.** `Office of the Mayor` exists in **both** governments, and `Mayor` and `Commissioner, District 1` … `District 5` are each duplicated across them. `slug` is generated from `name_formal`, which differs, so the rows cannot collide — but a lookup on `c.name` alone will match two chambers and the office insert will fan out.

- [x] **Step 5: The counts the gates assert**

| Assertion | Miami (`CC_0015`/`CC_0016`) | Miami-Dade (`CC_0017`) |
| --- | --- | --- |
| governments created | 1 | 1 |
| chambers | **2** (5 and 1) | **3** (13, 1, 5) |
| new districts | 1 citywide + **5** `X0041` | **13** `X0040` |
| offices on the citywide/countywide district | **1** (the Mayor) | **6** (Mayor + 5 officers) |
| offices on `X` districts | 5, one each | 13, one each |
| total offices | **6** | **19** |
| people / terms | 6 | 19 |
| new politician rows | 6 | **18** — 🔴 not 19 |
| `how_started = 'appointed'` | 0 | **2** |
| `day`-precision terms | *(from the roster)* | **≥ 5** — the officers |
| offices with no term and no vacancy flag | 0 | 0 |
| `is_vacant` | 0 | 0 |

🔴 **Assert `2025-01-07` explicitly for all five officers**, by title. Five people sharing one published date is a strong invariant and a cheap gate:

```sql
SELECT count(*) INTO v_n FROM essentials.office_terms t
  JOIN essentials.offices o ON o.id = t.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
 WHERE c.government_id = v_gov AND c.name = 'Elected Officials'
   AND t.term_start = DATE '2025-01-07' AND t.start_precision = 'day';
IF v_n <> 5 THEN RAISE EXCEPTION 'miami-dade: expected 5 officers seated on 2025-01-07 (Amendment 10), got %', v_n; END IF;
```

🔴 **Assert the reuse landed as a TERM and not as a new person:**

```sql
-- Oliver Gilbert must hold District 1, and there must be exactly ONE of him.
SELECT count(*) INTO v_n FROM essentials.politicians
 WHERE normalize(lower(full_name), NFD) = normalize(lower('Oliver Gilbert'), NFD);
IF v_n <> 1 THEN RAISE EXCEPTION 'miami-dade: % politician row(s) named Oliver Gilbert, expected exactly 1 -- a duplicate means the reuse failed', v_n; END IF;
```

⚠ **And assert the three forbidden titles match zero offices in BOTH governments** — the generator descends from Leon's, where `Superintendent of Schools` is a live entry.

- [x] **Step 6: Update the test fixture and add the cases this wave introduces**

Keep FL-5's cases that still apply. The fixture needs **both** tables at full size (6 + 19), because the shape assertions are unconditional. Add:

```ts
it('returns both city and county, unlike FL-5', () => {
  const r = parseRosters(FIXTURE);
  expect(r.city).toHaveLength(6);
  expect(r.county).toHaveLength(19);
});

// 🔴 The reuse: one id outside the sub-range, and n=93 unused.
it('accepts exactly one reused external_id outside the new sub-range', () => {
  const ids = parseRosters(FIXTURE).county.map((s: any) => Number(s.externalId));
  const outside = ids.filter((n) => !(n >= -1240109 && n <= -1240081));
  expect(outside).toEqual([-1212402]);
  expect(ids).not.toContain(-1240093);
});

// 🔴 Two-word surnames: the override must win over splitName().
it('overrides the surname for Cohen Higgins and Levine Cava', () => {
  const byslug = Object.fromEntries(parseRosters(FIXTURE).county.map((s: any) => [s.slug, s]));
  expect(byslug['mdc-commissioner-8'].lastName).toBe('Cohen Higgins');
  expect(byslug['mdc-mayor'].lastName).toBe('Levine Cava');
});

// 🔴 All five officers share one published date.
it('gives all five officers 2025-01-07 at day precision', () => {
  const off = parseRosters(FIXTURE).county.filter((s: any) => s.chamber === 'Elected Officials');
  expect(off).toHaveLength(5);
  expect(off.every((s: any) => s.termStart === '2025-01-07' && s.precision === 'day')).toBe(true);
});

// 🔴 Two appointed commissioners, and the right two.
it('marks districts 5 and 6 appointed and nobody else', () => {
  const { county } = parseRosters(FIXTURE);
  const appointed = county.filter((s: any) => s.howStarted === 'appointed').map((s: any) => s.slug).sort();
  expect(appointed).toEqual(['mdc-commissioner-5', 'mdc-commissioner-6']);
});

// ⚠ Same title in two governments must not be treated as a duplicate.
it('allows Mayor and Commissioner, District 1 in both governments', () => {
  const r = parseRosters(FIXTURE);
  expect(r.city.some((s: any) => s.title === 'Mayor')).toBe(true);
  expect(r.county.some((s: any) => s.title === 'Mayor')).toBe(true);
  expect(r.city.filter((s: any) => s.title === 'Commissioner, District 1')).toHaveLength(1);
  expect(r.county.filter((s: any) => s.title === 'Commissioner, District 1')).toHaveLength(1);
});

it('refuses a reused id whose slug is not a known reuse', () => {
  const bad = FIXTURE.replace('-1240082', '-1212410');   // a different congressional candidate
  expect(() => parseRosters(bad)).toThrow(/not a declared reuse|outside/);
});
```

- [x] **Step 7: Run the tests, generate, and grep the SQL**

```bash
cd <knight-worktree>/backend && npx vitest run scripts/gen-miami-dade-migrations.test.ts && node scripts/gen-miami-dade-migrations.mjs && ls -la migrations/CC_wip_*.sql
```

Then, for each of the three files:

```bash
cd <knight-worktree>/backend && for f in migrations/CC_wip_miami_structure.sql migrations/CC_wip_miami_people.sql migrations/CC_wip_miami_dade_county.sql; do
  echo "=== $f"
  echo -n "  party leakage: "        ; (grep -cE '\((R|D|I|DEM|REP|NPA|WRI)\)' "$f" || true)
  echo -n "  BEGIN/COMMIT: "         ; echo "$(grep -c '^BEGIN;$' "$f") / $(grep -c '^COMMIT;$' "$f")"
  echo -n "  chamber lookup w/o gov: "; (grep -c "c.name = 'Office of the Mayor'" "$f" || true)
  echo -n "  unpaired district geo:  "; (grep -cE "\b(d|dd)\.geo_id = " "$f" || true)
  echo "  FL-3/4/5 strings: $(grep -cE 'wave FL-[345]\.|bradenton|tallahassee|palm.beach|gen-(bradenton|tallahassee|palm)' "$f")"
done
```

Expect **1 / 1** BEGIN/COMMIT per file, **0** party leakage, **0** stale-wave strings, and every `d.geo_id` predicate paired with `mtfcc` within three lines — re-use FL-5's python pairing check.

🔴 **Also assert `-1212402` appears in `CC_wip_miami_dade_county.sql` and that no `INSERT INTO essentials.politicians` names it.**

---

## Task 5: Dry-run, apply, gate, probe, commit

**Files:**
- Rename to `CC_0015_miami_structure.sql`, `CC_0016_miami_people.sql`, `CC_0017_miami_dade_county.sql`
- Create: `backend/scripts/verify-miami-dade-probes.sql`

- [ ] **Step 1: Write the two-anchor probe**

Copy `scripts/verify-palm-beach-probes.sql`. **Two anchors, and the first one cannot return four answers.**

```sql
-- 🔴 TWO ANCHORS, AND PROBE A RETURNS THREE OF FOUR ANSWERS BY DESIGN.
--
-- Miami City Hall sits inside STATE HOUSE DISTRICT 113, which is VACANT: Vicki
-- Lopez resigned it in November 2025 to take a Miami-Dade Commission seat, and
-- the Supervisor of Elections confirms the seat is filled at the NOVEMBER 2026
-- general rather than by special election. FL-2 predicted this exactly.
--
-- Probe B, at the county Governmental Center, returns all four. Both are here
-- because the vacancy is the truth about City Hall's address, and a single
-- convenient anchor would hide it.
```

Probe A — Miami City Hall, `-80.234992579394, 25.728661855119`:

| n | answer | dt | geo | mtfcc | want |
| --- | --- | --- | --- | --- | --- |
| 1 | city commissioner (District 2) | `LOCAL` | `miami-fl-commission-district-2` | `X0041` | 1 |
| 2 | city mayor (citywide) | `LOCAL` | `1245000` | `G4110` | 1 |
| 3 | county commissioner (District 7) | `COUNTY` | `miami-dade-fl-commissioner-district-7` | `X0040` | 1 |
| 4 | county mayor + 5 officers | `COUNTY` | `12086` | `G4020` | **6** |
| 5 | state senator (SD-38) | `STATE_UPPER` | `12038` | `G5210` | 1 |
| 6 | **state representative — HD-113 is VACANT** | `STATE_LOWER` | `12113` | `G5220` | **0** |

Probe B — Government Center, `-80.196332709513, 25.775078850443`:

| n | answer | dt | geo | mtfcc | want |
| --- | --- | --- | --- | --- | --- |
| 1 | city commissioner (District 5) | `LOCAL` | `miami-fl-commission-district-5` | `X0041` | 1 |
| 2 | county commissioner (District 5, appointed) | `COUNTY` | `miami-dade-fl-commissioner-district-5` | `X0040` | 1 |
| 3 | state senator (SD-36) | `STATE_UPPER` | `12036` | `G5210` | 1 |
| 4 | **state representative (HD-109) — the four-answer control** | `STATE_LOWER` | `12109` | `G5220` | **1** |

⚠ **Confirm all four state `geo_id`s with a query**, as FL-4's plan required and FL-5 confirmed:

```bash
cd <knight-worktree>/backend && psql "$DATABASE_URL" -At -F ' | ' -c "
SELECT d.district_type, d.label, d.geo_id, d.mtfcc, o.is_vacant FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id = d.id
 WHERE lower(d.state)='fl' AND d.label IN ('State House District 113','State House District 109',
   'State Senate District 38','State Senate District 36');"
```

Keep the unpaired-join collision probe, and **add the ZCTA arm**: at these anchors `12086` matches a New York ZIP-code polygon as well as the county and HD-86. Assert it returns **no** Florida district, so the demonstration shows both failure shapes — a wrong official *and* a silent miss.

Also carry forward: per-body seat counts (Miami 5/5 + 1/1; Miami-Dade 13/13 + 1/1 + 5/5, 0 vacant); the zero-offices-without-a-term check; the Hialeah mixed control (county yes, city no); Fort Lauderdale and Key West negatives; and a rulings block asserting the five officers' shared `2025-01-07`, the two appointments by title, the three forbidden titles at zero, and **exactly one politician row named Oliver Gilbert**.

- [ ] **Step 2: Run the probe BEFORE applying**

Expected pre-state: probe A answers 5 present (SD-38) and 6 already at 0; probe B answers 3 and 4 present. All city and county answers at 0.

- [ ] **Step 3: Dry-run each file separately**

```bash
cd <knight-worktree>/backend && for f in CC_wip_miami_structure CC_wip_miami_people CC_wip_miami_dade_county; do
  echo "=== DRY RUN $f ==="
  sed 's/^COMMIT;$/ROLLBACK;/' "migrations/$f.sql" | psql "$DATABASE_URL" -v ON_ERROR_STOP=1 2>&1 | tail -8
done
```

⚠ **`CC_wip_miami_people` will fail on its own against untouched prod** — its offices do not exist yet. That is correct; apply the structure first, then dry-run the people half. **Do NOT concatenate the files.** FL-3 did and committed `CC_0008` to prod in autocommit.

- [ ] **Step 4: Confirm each rollback reverted**

```bash
cd <knight-worktree>/backend && psql "$DATABASE_URL" -At -F ' | ' -c "
SELECT (SELECT count(*) FROM essentials.governments WHERE geo_id IN ('1245000','12086')),
       (SELECT count(*) FROM essentials.districts WHERE mtfcc IN ('X0040','X0041')),
       (SELECT count(*) FROM essentials.geofence_boundaries WHERE mtfcc IN ('X0040','X0041')),
       (SELECT count(*) FROM essentials.politicians WHERE external_id BETWEEN -1240109 AND -1240081),
       (SELECT count(*) FROM essentials.office_terms t JOIN essentials.politicians p ON p.id=t.politician_id WHERE p.external_id=-1212402);"
```

Expected **`0 | 0 | 18 | 0 | 0`**. The 18 boundaries come from Tasks 1–2; the district rows come from the migrations. **The last column is the reuse check: Gilbert must have no term row yet.**

- [ ] **Step 5: Take the numbers last, then apply in order**

```bash
cd <knight-worktree> && git fetch origin && cd backend && npm run check:migrations && \
git mv migrations/CC_wip_miami_structure.sql   migrations/CC_0015_miami_structure.sql && \
git mv migrations/CC_wip_miami_people.sql      migrations/CC_0016_miami_people.sql && \
git mv migrations/CC_wip_miami_dade_county.sql migrations/CC_0017_miami_dade_county.sql && \
sed -i 's/CC_wip_miami_structure/CC_0015_miami_structure/g; s/CC_wip_miami_people/CC_0016_miami_people/g; s/CC_wip_miami_dade_county/CC_0017_miami_dade_county/g' \
  migrations/CC_001[567]_*.sql scripts/gen-miami-dade-migrations.mjs && \
npm run check:migrations && (grep -rn 'CC_wip' migrations/ scripts/gen-miami-dade-migrations.mjs || echo 'no CC_wip references left')
```

🔴 **Then verify the rename by REGENERATING and diffing** — FL-5's rule, and the FL-4 header defect is why:

```bash
cd <knight-worktree>/backend && for f in CC_0015_miami_structure CC_0016_miami_people CC_0017_miami_dade_county; do cp "migrations/$f.sql" "/tmp/$f.before"; done && \
node scripts/gen-miami-dade-migrations.mjs && \
for f in CC_0015_miami_structure CC_0016_miami_people CC_0017_miami_dade_county; do diff "/tmp/$f.before" "migrations/$f.sql" && echo "$f reproduces byte-for-byte"; done
```

Then apply, stopping on the first failure:

```bash
cd <knight-worktree>/backend && for f in CC_0015_miami_structure CC_0016_miami_people CC_0017_miami_dade_county; do
  echo "=== APPLY $f ==="
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "migrations/$f.sql" || { echo "STOPPED at $f"; break; }
done
```

- [ ] **Step 6: Re-run ALL TEN Florida local migrations**

```bash
cd <knight-worktree>/backend && for f in CC_0008_bradenton_structure CC_0009_bradenton_people CC_0010_manatee_county CC_0011_tallahassee_structure CC_0012_tallahassee_people CC_0013_leon_county CC_0014_palm_beach_county CC_0015_miami_structure CC_0016_miami_people CC_0017_miami_dade_county; do
  echo "=== RE-RUN $f ==="
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "migrations/$f.sql" 2>&1 | grep -E 'INSERT 0 [1-9]|UPDATE [1-9]|NOTICE|ERROR|COMMIT' | sed 's/^psql:[^ ]* //'
done
```

🔴 **All ten.** Every file must reach `COMMIT` with its post-verify `NOTICE` and no `ERROR`; the only permitted `INSERT 0 N` with N > 0 is into a **temp** seed table, and every occupancy loop must report `seated 0 / 0 blank`. This is the step that caught FL-3's latent band-guard defect, and this wave changes the guard's shape — so it is the step most likely to find something.

- [ ] **Step 7: The acceptance probe**

Expected: **probe A** — city D2 (Pardo), city Mayor (Higgins), county D7 (Regalado), 6 countywide, SD-38 (Calatayud), and **HD-113 at 0, PASS**. **Probe B** — city D5 (King), county D5 (Lopez), SD-36 (Garcia), HD-109 (Gantt), **all four present**.

- [ ] **Step 8: Every gate**

```bash
cd <knight-worktree>/backend && npx tsc --noEmit && npm run check:occupancy && npm run check:migrations && npm run check:child-county && npm run check:reachability
```

`check:reachability` must report **no new bucket**. 🔴 **This wave adds 25 offices and Miami is the largest city in the program so far** — if any office lacks a term row it fires `DEAD_GEOGRAPHY` on a new `fl|LOCAL` or `fl|COUNTY` bucket. **No `geofence_child_county` refresh is needed** — only `X` codes are loaded — but confirm `check:child-county` green.

- [ ] **Step 9: Measure the drift**

FL-5 left `offices_missing_terms` at **820 / 165 / 655**. FL-6 adds no vacancy and no unflagged row, so expect **820 / 165 / 655 unchanged**.

Also measure the slice total:

```bash
cd <knight-worktree>/backend && psql "$DATABASE_URL" -At -F ' | ' -c "
SELECT g.name, count(o.id), count(och.politician_id), count(*) FILTER (WHERE o.is_vacant)
  FROM essentials.governments g JOIN essentials.chambers c ON c.government_id=g.id
  JOIN essentials.offices o ON o.chamber_id=c.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id=o.id
 WHERE g.state='FL' GROUP BY g.name ORDER BY g.name;"
```

Expect **7 governments**: the state (164/159/5), Bradenton 6/6, Manatee 12/11/1, Tallahassee 5/5, Leon 13/13, Palm Beach 12/12, **Miami 6/6, Miami-Dade 19/19** — 73 local/county offices, 72 seated, 1 vacant.

- [ ] **Step 10: Commit**

Commit message opens with the counts, then leads on the reuse and the two anchors — those are the two things a later reader most needs.

---

## Task 6: Update the ledger, and close Florida's stages 3 and 4

**Files:**
- Modify: `.planning/knight-foundation/fl.md`, `.planning/knight-foundation/PROGRAM.md`
- Modify: this plan — add "Deviations found during execution" per task, as FL-5 did five times

- [ ] **Step 1: `fl.md`**

- Wave table: FL-6 `✅ applied — CC_0015, CC_0016, CC_0017`. Next free `CC_0018`, `X0042`.
- Add `## FL-6 — Miami and Miami-Dade County (applied …)` with the counts, the band ranges, the `X` allocations, both anchors and the date-precision histogram.
- 🔴 **Correct the FL-1 note**: "only the congressional map was litigated after 2022" is true of the **state** maps and **false** of Miami's city map, which was struck down twice and replaced by a May 2024 settlement map.
- Record, in this order: the **reuse** and the fifth band-guard shape; **two anchors** and why; **four vintages plus a geometry-less lookalike**, and that District 1 moved only 0.136 sq mi so a spot check would pass on the wrong map; **Miami-Dade tiles the county exactly, the opposite of Palm Beach** — measure before choosing the gate; **`12086` collides with a New York ZIP code, and 40 of 67 FL counties do**; **the SOE roster PDF** and that it stops at the county line and carries an as-of date; **two appointed commissioners and a Commission-appointed vacancy mechanism**; the **Higgins → Lopez → HD-113 chain**; **four in-wave surname pairs and two two-word surnames**; **four Clerk titles across four counties** and the office's-own-site rule; **State Attorney/Public Defender confirmed excluded by Miami-Dade's own publishers**; and **~60 Community Council seats** as the largest unmodelled block found so far.
- Update "Sources for FL-3 onward": **all four Florida jurisdictions are now ANSWERED.**

- [ ] **Step 2: `PROGRAM.md`**

- 🔴 **Slice status: FL stages 3 and 4 both go to `✅`** — all four Florida jurisdictions are in. This is the first slice to close either stage. Rewrite the narrative paragraph accordingly, keeping the note that Palm Beach has no city half.
- Jurisdiction detail: Miami and Bradenton rows get their seated counts, like Tallahassee's and Palm Beach's.
- Local/county seats: add Miami 6/6 and Miami-Dade 19/19; restate the Florida total.
- Migration ledger: three rows; next free `CC_0018`; MTFCC next free `X0042`.
- Session log: one row, and **`Next action: FL-7 — Florida assets. 72 people, 0 headshots, and three banners: Bradenton, Tallahassee and Miami, plus Palm Beach County's own COUNTY key whose name and composition are still unchosen. 🔴 Miami's banner CANNOT be a downtown skyline — the Florida state banner is "Miami Late Afternoon Skyline". ▶ Also re-check the six Florida vacancies (5 legislative + Manatee D1) and write their predecessor terms together; and re-check Palm Beach D2/D4/D6 and Miami-Dade D1/D5/D6 after the November 2026 general.`**

- [ ] **Step 3: Commit and push**

```bash
cd <knight-worktree> && git fetch origin && git rev-list --left-right --count origin/docs/knight-cities-program...HEAD && git push origin docs/knight-cities-program
```

⚠ **Check both directions before pushing**, and never `--force` past a non-fast-forward.

---

## Plan self-review

**Spec coverage.** §3 stage 3 (city) → Tasks 2, 3, 4, 5 for Miami's 6 offices. §3 stage 4 (county: commission layer + county officers, offices and people in one migration) → Tasks 1, 3, 4, 5 for Miami-Dade's 19. §3's "county offices and people together" is honoured by `CC_0017`; the city split into `CC_0015`/`CC_0016` follows FL-3's and FL-4's reason — a re-seat must never re-run office creation. §8.1 (banner composition conflict for Miami) is **explicitly out of scope and deferred to FL-7**, with the constraint restated in Task 6's handoff so it cannot be lost. §2's honesty rules drive the `unknown`-over-inference instruction in Task 3 Step 3, the probe-A zero assertion, and the refusal to rename the reused row.

**Placeholder scan.** Task 4 Step 4's seat maps use `// ... 2 through 5` and `// ... 2 through 13` for mechanical repetition of a fully specified pattern — every field is shown for the first entry and the titles are enumerated in the Template rows table. Task 3 Step 3 leaves per-person dates to be sourced, which is the point of the task, and names the source per group. Everything else is a measured literal: 18 district areas, 20 control points, 13 vintage symdiffs, both anchor geocodes, 6 tiling quantities. No "add appropriate error handling", no "similar to Task N", no undefined function.

**Type and name consistency.** `parseRosters` returns `{ city, county, counts }` with five count keys in Task 4's Interfaces, and Task 3 Step 7 emits exactly that shape. The 25 slugs in Task 3's naming table and Task 4's seat maps agree, `mdc-`/`mia-` prefixed to keep the two governments' `Commissioner, District 1` apart. `X0040` = county and `X0041` = city consistently in Tasks 1, 2, 4, 5. `-1240109 … -1240081`, the unused `-1240093` and the reused `-1212402` are identical everywhere. `12086`, `1245000`, both prefixes and all four state `geo_id`s (`12038`, `12113`, `12036`, `12109`) match between the Facts section and Task 5.

**Gaps found and closed while reviewing.** Four. (1) Task 5 Step 4's rollback check originally counted only politicians and districts; it now also asserts **Gilbert has no term row yet**, which is the only way to see a partially-applied reuse. (2) The Task 4 grep list originally checked for unpaired `geo_id` but not for **`c.name` lookups without `government_id`** — the specific failure that two `Office of the Mayor` chambers make possible. (3) Task 1's vintage gate first checked District 1, which moved by 0.136 sq mi and **would have passed on the 2011 map**; it now checks 9, 8 and 7. (4) Task 0 did not exist in the first draft — the branch discovery came out of executing FL-5, and without it a local `ls` reports the next free slot as `CC_0006`, wrong by nine.
