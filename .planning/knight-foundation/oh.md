# OH — slice 8 (Akron · Summit County)

Program tracker: [`PROGRAM.md`](./PROGRAM.md) · spec:
[`2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md)

**Opened 2026-09-23.** Lease `state:oh` held by chris@empowered.vote on DESKTOP-G6KDNN2.
Worktree `C:\ev-accounts-oh`, branch `knight/oh-slice8`.

| Stage | State |
| --- | --- |
| 1 geography | ✅ **APPLIED 2026-09-23 — 132 boundaries, 132 districts, 0 errors.** Only `sldu` + `sldl` were owed; `place` already existed |
| 2 legislature | ✅ **APPLIED 2026-09-23 — 132 offices, 130 seated, 2 vacant** (`CC_0131`/`CC_0132`) |
| 3 city waves | ✅ **APPLIED 2026-09-23 — Akron 14 offices, 14 seated, 0 vacancies** (`X0063`, `CC_0133`/`CC_0134`) |
| 4 county waves | ✅ **APPLIED 2026-09-24 — Summit 17 offices, 17 seated, 0 vacancies** (`X0064`, `CC_0136`/`CC_0137`). **Akron scores 4 of 4.** |
| 5 assets | ✅ **APPLIED 2026-09-24 — 161 of 161 portraits, and the `akron` banner.** Ohio goes 0 → 161 renderable |

---

## ✅ OH-1 APPLIED 2026-09-23 — Ohio has legislative geography for the first time

**132 boundaries and 132 districts — 99 House + 33 Senate — 0 errors.** `districts` 9,584 → 9,716
and `geofence_boundaries` 71,768 → 71,900, both **exactly +132** against a baseline measured in the
same session, minutes before the write. No migration: the TIGER loader writes boundaries and
districts directly, as in SC-1 and PA-1.

Verified from outside, with the counts asserted: 33 `G5210` + 99 `G5220`, **all 132 carrying
geometry, all `ST_IsValid`, one geometry type per layer, SRID 4326**; `geo_id` contiguous over
`39001`–`39033` and `39001`–`39099`; **33 and 99 distinct `ocd_id`s**, so the MN `08A` / MD `1A`
suffix collapse did not occur. `districts.state` was written lowercase `oh`, matching the 88 counties
already there. Loader re-run: **0 inserted, 132 already existed** — idempotent.

🟢 **AKRON CITY HALL NOW RESOLVES THROUGH PRODUCTION GEOMETRY**, and it returns what the raw files
predicted: **Summit County, Akron city, State Senate District 28, State House District 33.** A
Detroit control returns **zero** Ohio legislative boundaries.

🟢 **OHIO'S PLACE LOAD WAS NOT DISTURBED** — `G4110` for FIPS 39 measured **925 before and 925
after**, asserted rather than assumed, because this is the first slice whose stage 1 ran alongside an
existing `place` layer it must not touch.

### 🔴 THE VINTAGE WAS PROVED AGAINST THE STATE, AND THE CONTROL FAILED AS REQUIRED

New tool, carrying both halves: **`backend/scripts/verify-oh-tiger-vintage.mjs`**.

The authority is the **Secretary of State's own shapefiles**, `2024-2032-sd-shapefile.zip` and
`2024-2032-hd-shapefile.zip`, whose members are named **"Corrected Sept 29 2023 Unified Bipartisan
Redistricting Plan SD/HD SHP"**. ⚠ That filename corrected a date this file had wrong when the slice
opened: the Commission **adopted on 2023-09-26** and **corrected on 2023-09-29**; the map PDFs are
titled `adopted2023-09-26` and the shapefiles and legal description carry the 29th.

Every one of the 132 TIGER polygons was located at its own published internal point inside that plan:

| | TIGER 2024 vs the SOS plan | **CONTROL** — TIGER 2022, the superseded plan |
| --- | --- | --- |
| Senate | **33 agree, 0 differ, 0 ambiguous** | 29 agree, **4 differ** |
| House | **99 agree, 0 differ, 0 ambiguous** | 81 agree, **18 differ** |

🔴 **THE CONTROL'S AGREEMENTS ARE THE POINT, NOT ITS DISAGREEMENTS.** The superseded map still
matches on **29 of 33 and 81 of 99**. Most Ohio districts did not move, so a count, a shape check, a
"no `ZZZ`" check and even a handful of spot checks would all have waved the wrong plan through.
⚠ **And among the four Senate disagreements, 27 and 28 SWAP** — `027->028` and `028->027`. Akron
sits in one of them. **The wrong vintage would have put this slice's own city in the wrong Senate
district, and nothing about the result would have looked wrong.**

🟢 **Two independent implementations agree.** The measurement was first made in a throwaway Python
reader of the raw `.shp`/`.dbf`, then reproduced by the tracked Node verifier using `shapefile` and
`AdmZip`: identical numbers, 33/33, 99/99, 4 and 18.

### 🔴 THE SECRETARY OF STATE IS BEHIND A WAF, AND THE TWO REFUSALS WERE THE SAME SIZE

`ohiosos.gov` returns **HTTP 403 with a ~1.25 MB HTML challenge page** to a bare request, to a
browser User-Agent alone, **and** to a full Chrome header set with a same-origin `Referer` — all
three shapes this repo relies on elsewhere. ⚠ **Both asset URLs returned a challenge of identical
size (926,353 and 926,356 bytes), which is the tell: a uniform answer is a broken detector.** A real
browser gets HTTP 200 and `application/zip`.

▶ So the zips were fetched **in Playwright**, in the page context, and decoded locally; magic bytes
`PK\x03\x04` and sizes 1,075,314 and 1,844,420 were confirmed before use. The verifier takes them via
`--sos-dir`, checks the magic bytes itself, and **refuses to run without them** rather than falling
back to a Census-only check that would prove nothing. Its refusal message carries the retrieval steps.

### ✅ The pre-flight was watched failing before it was trusted

`EXPECTED_OH_MTFCC.sldu` was temporarily set to 34. The run aborted with
`MtfccAssertionError: expected 34 records, got 33 … Aborting before any DB write`, and the edit was
reverted and re-confirmed. The block also asserts the distinct `ocd_id` suffix count, and the
Ohio-specific arithmetic precondition **99 = 3 × 33**.

### 🟢 A LOADER WARNING THAT DOES NOT APPLY — AND IT WAS CHECKED, NOT ASSUMED

The loader ends every run with **"⚠ ACTION REQUIRED: refresh the persisted child→county mapping"**
and says `check:child-county` will FAIL until it is refreshed. It did **not** fail: `stale 0`.
⚠ A check that passes immediately after a load is exactly the shape of a vacuous pass, so the reason
was established: the matview holds **0 rows for `G5210`/`G5220` out of 13,734** — it tracks places
and county subdivisions, not legislative layers. ▶ **A legislative-only load needs no matview
refresh**, and the warning is generic. Do not skip it after a `place` load.

### Gates

`check:occupancy` OK · `check:migrations` OK (0 added vs `origin/master`) · `check:reservations` OK
(no migrations added) · `check:child-county` **stale 0** · `check:reachability` **nothing regressed,
UNREACHABLE 9 against a baseline of 24**.

▶ **Next: OH-2 — seat the General Assembly, 132 offices.**

---

## ✅ OH-2 APPLIED 2026-09-23 — the Ohio General Assembly is seated

`CC_0131` (structure) + `CC_0132` (occupancy), both slots reserved from the allocator:
**132 offices — 99 House + 33 Senate — 130 seated, 2 vacant, 130 people created, 0 reused.**
`politicians` +130, `offices` +132, `office_terms` +130, each **exact** against a baseline measured
minutes earlier. `offices_missing_terms` 427 → **429**, and the **unflagged count is unmoved at
238** — both new rows landed in the flagged half, which is what the two vacancies are supposed to do.

🟢 **AKRON NOW ANSWERS 2 OF 4.** Akron City Hall returns **Veronica R. Sims (HD-33)** and
**Casey Weinstein (SD-28)**, alongside the U.S. Representative it already had. The council member
and the county council member are OH-3 and OH-4.
⚠ **Controlled against a second city**: Cleveland returns **Terrence Upchurch (HD-20)** and
**Nickie J. Antonio (SD-23)** — different people, so the probe is reading geography and not
returning one answer everywhere. Per-district control: **99 of 99 and 33 of 33** districts resolve
to exactly one member at their own interior point. **0 Ohio counties** picked up a legislative
office. Both migrations re-run: every write into `essentials` inserted 0.

### 🔴🔴 TWO SEATS ARE VACANT AND THE TWO SOURCES DISAGREE IN OPPOSITE DIRECTIONS

| | chambers' own directory | Open States |
| --- | --- | --- |
| HD-66 | **Vacant** | Sharon Ray, sitting ❌ |
| SD-13 | **Vacant** | absent ✅ |

- **HD-66** — Sharon Ray resigned **effective 2026-09-14 at 11:59 pm** to become Medina County
  Recorder, sworn in 2026-09-15; the House's own press release of 2026-09-14 gives the time, so the
  first vacant day is **2026-09-15** and `vacant_since` says so. **Open States still lists her as
  the sitting member** and shows 99 of 99 House seats filled — nine days stale.
  ▶ **This is MN-2's trap with the roles swapped.** There the chamber's own roster was stale and the
  aggregator was right. Neither is reliably the fresher source; only comparing them shows which.
- **SD-13** — Nathan Manning took the bench of the Ninth District Court of Appeals on **2026-08-03**
  and cannot hold both offices. 🔴 **`vacant_since` is deliberately NULL**: no source publishes the
  resignation's effective date, reporting says only "late July or early August", and 2026-08-03 is an
  **upper bound on the vacancy's start, not the date it began**. The flag is a fact; the date is not.
  Dating it is a debt.

Neither carries an `office_terms` row at all — there is no predecessor term to close, because these
offices were created by this wave. That is the SC-4 treatment of its vacant Richland seat.

### 🔴🔴 THE VACANCY WAS NEARLY LOST TO MY OWN PARSER, AND THE COUNT HID IT

The first House parse returned **98 districts with 67 missing** — close enough to 99 to look like a
rounding problem. It was not. The vacant tile carries **no headshot**, so a single regex sweeping
`class → href → name → district → headshot` ran straight through the vacant block and stole the
*next* member's image, emitting one row that read "District 66, Vacant" and dropping HD-67 entirely.
▶ **A per-record regex that spans a block boundary will silently merge two records, and the symptom
is an off-by-one count.** The fix was to split on the container's opening tag and parse each block in
isolation; that returns 99 of 99 with exactly one vacancy.

### 🔴🔴 THE DATABASE'S OWN GUARD FOUND A NAME COLLISION THAT BOTH MY DETECTORS MISSED

Two checks were run before the dry run and both cleared:

1. **exact `full_name`** — 0 of 130 matched. ⚠ A uniform answer, so it was not trusted.
2. **loose (first token, last token)** — found **one** candidate, Ohio HD-92's Mark Johnson against
   a Minnesota state senator. Controlled: the same key returns 230 rows for the first name "John".

The dry run then **aborted** on `DUPLICATE_POLITICIAN_NAME` for **Tom Young** (HD-37). The existing
row is **"Tom Young, Jr."**, a **South Carolina state senator** seated by `CC_0126` — and *both* my
checks missed it, because its `full_name` is not "Tom Young" and its **last token is "Jr."**. The
trigger keys on **`(first_name, last_name)`**, which is the correct key.

▶ **WHEN A CONSTRAINT CATCHES SOMETHING YOUR OWN CHECK DID NOT, ADOPT THE CONSTRAINT'S KEY AND
RE-RUN THE WHOLE SWEEP — never just unblock the row it named.** Re-run on `(first_name, last_name)`
with a control (65 active rows share `last_name` 'Smith'), the sweep returns **exactly two**:

| Ohio member | existing row | who that is |
| --- | --- | --- |
| HD-37 Tom Young | `-2745147` Tom Young, Jr. | **sitting SC state senator**, SD-24 |
| HD-92 Mark Johnson | `-2732133` Mark T. Johnson | **sitting MN state senator** |

Both are different people, and the evidence is structural rather than a judgement about names: a
person cannot simultaneously hold a Senate seat in another state and a seat in the Ohio House. The
guard was lifted with `SET LOCAL` for **those two statements only** and switched back off; the other
**128 rows were inserted with the guard live**. This is the GA roster trap, where 2 of 4 name hits
were a Colorado senator and a Utah treasurer.

### 🔴 EVERY TERM IS OPEN-ENDED AT `unknown`, AND NOTHING WAS GUESSED

A date probe over a member page found **no "assumed office", no "term", and no arrival sentence of
any kind** — the only date on the page tested was an unrelated news item. Ohio Const. art. II § 2
does fix commencement at "the first day of January next after their election", but that governs a
member who **arrived at a general election** and says nothing about those who arrive by caucus
appointment mid-term. ▶ **Writing 2025-01-01 for all 130 would be the San José D8/D10 error at
scale: a rule true of most rows, applied to rows it does not govern.** This is the GA-2 / IN-2 /
MN-2 / PA-2 pattern. `seat_officeholder()` is not used — it refuses a NULL `term_start` by design.
**Dating these 130 arrivals is a recorded debt.**

### 🔴 TWO SOURCE-ACCESS TRAPS

- **`ohiosenate.gov/senators/directory` returns HTTP 200 and renders the word "ERROR"** with a
  "© null" footer. `curl` reports 200 and 6,687 bytes, which reads as a thin page rather than a
  failure. The real list is **`ohiosenate.gov/members/directory`**. A clean 200 can carry an error page.
- **The member-page sweep was rate-limited at HTTP 429.** Run with 8 workers, **79 of 130 pages came
  back 429** — which a less careful pass would have recorded as 79 roster failures, or worse, as 79
  members who "could not be confirmed". Re-run serially with backoff, **all 130 answered**.
- ⚠ `legislature.ohio.gov` fails TLS verification for `curl` (unable to get local issuer
  certificate) on both directory URLs. Not used; recorded so the next session does not re-discover it.

### The change-check, and its control

All **130** individual member pages were fetched and each one names **its own member's surname and
its own district number**; none contains the word "Vacant". ✅ The detector was controlled on a live
page: correct surname ✓, wrong surname ✗, correct district ✓, wrong district ✗.

### Gates

Six post-verify gates were **watched failing** before the apply — House office count, HD-66's
vacancy date, the vacancy total, the people-in-band count, the Akron assertion, and the
no-dated-term rule. ⚠ The last one never reached my gate: the schema's own
`office_terms_how_started_ch` CHECK refused it first, which is the stronger result.
Dry run of both migrations as **one transaction ending in ROLLBACK**, then production re-measured
untouched. `check:occupancy`, `check:migrations`, `check:reservations`, `check:child-county` green;
`check:reachability` nothing regressed, UNREACHABLE **9** against baseline 24.

▶ **Next: OH-3 — Akron, 14 offices.**

---

## ✅ OH-3 APPLIED 2026-09-23 — Akron is seated, and stage 3 closes

`X0063` (10 ward polygons), `CC_0133` structure, `CC_0134` occupancy: **14 offices, 14 people,
0 vacancies** — 10 ward + 3 at-large council + the Mayor, across **1 government and 2 chambers**.
`politicians` +14, `offices` +14, `office_terms` +14, `districts` +11, each exact.
`offices_missing_terms` **unmoved at 429/238** — Akron added no unseated office. Both migrations
and the loader re-run clean.

🟢 **AKRON CITY HALL NOW ANSWERS 3 OF 4** — Ward 3 (Margo Sommerville), the three at-large members,
the Mayor, the state representative, the state senator and the U.S. Representative: **8 rows**. The
county council member is the last one, and it is OH-4.
⚠ **Controlled against a neighbouring city**: a Cuyahoga Falls address returns **0 Akron city
offices** and 3 answers in total. Akron's citywide seats do not leak past the city line — the Long
Beach failure inverted, and the thing an at-large seat on a citywide polygon most easily gets wrong.
Per-ward control: **10 of 10** wards resolve to exactly one member at their own interior point.

### 🟢 THE WARD LAYER CARRIES ITS OWN CROSS-CHECK, WHICH IS BETTER THAN A DATE

`City of Akron Wards` (owner **AkronGIS**, the city's own org) publishes ten polygons **and a
`COUNCILPERSON` field**. All ten names match the council's own members page exactly — two different
city departments naming the same ten people. Akron publishes no adoption date and no second ward
layer, so as at Columbia there is nothing to diff a map against; what replaces it here is a second
publisher. The loader's **GATE 2 enforces the agreement and was watched failing** on a planted wrong
name.

⚠ **THE LAYER IS CURRENT ON NAMES AND STALE ON TITLES.** Its `TITLE` field calls Ward 6 "President
Pro Tem"; the council's page says Ward 6 is **Vice-President** and Ward 9 is President Pro-Tem.
Leadership titles are not stored on offices here, so nothing downstream is affected — but **a source
can be fresh in one column and stale in another, and "the names matched" does not license trusting
the rest of the row.**

### 🔴🔴 BOTH OBVIOUS SEARCH ROUTES WERE TRAPS

- **`data-akron.opendata.arcgis.com` is a FEDERATED catalogue.** Its "Ward Boundaries" hits resolve
  to **East Renfrewshire Council, Scotland**, and others to Sherwood, Milton (Ontario) and Elyria.
  This is IN-6's Lake County trap exactly: for a generically named thing, an aggregated source is a
  **jurisdiction**-collision risk, not merely a staleness risk.
- **A web summary asserted "Akron has 8 wards."** It has **ten** — per the city's own government
  page and the council's members page. ▶ **A count from a summary is not a count from the body.**
- `gis.akronohio.gov` does not resolve.

### 🟢 CLOSURE IS A PROPERTY OF THIS CITY, AND IT WAS DEMANDED RATHER THAN BOUNDED

Akron's ten wards **partition** the city, unlike Fort Wayne's six districts which correctly leave
1.13 sq mi uncovered because Fort Wayne elects at-large seats over the rest. Measured: wards union
**62.2749 sq mi** against the TIGER place's **62.2741**, **99.971% of the city covered**, 0.0181
sq mi uncovered and 0.0189 sq mi of ward area outside. 🔴 The gate threshold is **99.5%, not 100%**:
these are **two digitizations of one boundary**, so a sliver difference is expected and is not a
defect — demanding 100% was tested and fails on correct data. Zero pairwise overlap; all ten single
connected polygons; one invalid as published and repaired on write.

### 🔴 THE OFFICE INVENTORY IS THE CITY'S OWN SENTENCE

akronohio.gov: *"A Mayor, three At-Large Council persons, and Ward City Council are elected by City
residents every four years. The City's Council is comprised of 10 Ward Representatives, and 3
At-Large members."* **Fourteen elected offices and no more.** ⚠ Akron elects **no City Clerk** —
unlike Fort Wayne and Gary, where the Clerk is elected and was seated, so the Indiana template does
not carry over. Municipal court judges and the Clerk of Courts stay with the judges wave.

### 🔴🔴 A BLANKET TERM DATE WAS TESTED AND IS FALSE — TWO SEATS PROVE IT

Akron elects the Mayor and all 13 council members to four-year terms at one November election, so
"everyone started 2024-01-01" looks safe. It is wrong for at least two of the thirteen:

- **Ward 1** — Nancy Holland resigned effective **4pm on 2024-01-05**, five days into the term.
  Samuel DeShazior was appointed to hold it, and the seat was then filled **for the remainder of the
  unexpired term at the 2025 general election**. **Fran Wilson**, the current member, therefore
  arrived in neither January 2024 nor by that appointment.
- **Ward 8** — James Hardy resigned effective **2024-07-01**; **Bruce Bolden** was appointed in July
  2024.

▶ **The point is not that the dates are unknown. It is that two seats disprove the blanket rule, so
applying it to the other eleven would assert something already shown to fail.** All 13 council terms
are therefore open-ended at `unknown`. This is the San José D8/D10 lesson with the counter-example
found **before** the write instead of after it.

🟢 **The Mayor IS dated, because the city publishes the date**: *"Mayor Malik was sworn in as Akron's
63rd Mayor on Jan. 1, 2024."* — 2024-01-01, `day`, `how_started` elected.

### ⚠ The change-check is weaker here than at OH-2, and that is stated rather than papered over

Akron publishes **no per-member pages**, so the page-by-page sweep used on all 130 legislators is not
available. Two independent city publishers agreeing on the ten ward members replaces it. **On the
three at-large seats only one publisher exists**, and the Mayor rests on the Mayor's Office page.
That is a real asymmetry in the evidence and is recorded as one.

### Gates

Name collisions were checked on **the guard's own key**, `(first_name, last_name)` — the lesson OH-2
paid for: **0 of 14**, against a control of 198 active `John` rows. No override was needed.
Six post-verify gates were **watched failing**, and ⚠ the sixth — loosening the at-large ordinal
join, which would seat one person three times — was refused by the **database's own
`office_terms_no_overlap` exclusion constraint** before reaching my gate. Three loader gates were
watched failing too. Dry run of both migrations as **one transaction ending in ROLLBACK**.
`check:occupancy`, `check:migrations`, `check:reservations`, `check:child-county` green;
`check:reachability` nothing regressed, UNREACHABLE **9** against baseline 24.

### ⚠ `X` boundary codes have no allocator, and that is a gap

`X0063` was chosen by reading `max(mtfcc)` in production — **the exact procedure CLAUDE.md calls
"the bug" for migration numbers.** The steward tracks `shared`, `CA` and `CC` and **not** `X`.
It is a narrower risk than the 1681 collision, because an `X` code is only taken when a loader
writes to production, so the maximum is observable rather than sitting undeclared on somebody's
branch — but two loaders running at once would still collide. ▶ **Worth adding `X` to the
allocator.** Noted here rather than fixed, because it is outside this wave.

▶ **Next: OH-4 — Summit County, 17 offices.**

---

## ✅ OH-4 APPLIED 2026-09-24 — Summit County is seated, stage 4 closes, and Akron scores 4 of 4

`X0064` (8 council-district polygons), `CC_0136` structure, `CC_0137` occupancy: **17 offices, 17
people, 0 vacancies** — 8 district council + 3 at-large council + County Executive + 5 elected
officers, across 1 government and 3 chambers. `politicians` +17, `offices` +17, `office_terms` +17,
`districts` **+8** (the countywide row already existed and was reused). `offices_missing_terms`
**unmoved at 429/238**. Loader and both migrations re-run clean.

🟢 **AKRON CITY HALL NOW RETURNS 18 ROWS AND SCORES 4 OF 4** — Ward 3 (Sommerville), **county
council District 4 (Jeff Wilhite)**, HD-33 (Sims) and SD-28 (Weinstein), plus the Mayor, Akron's
three at-large, Summit's three at-large, the County Executive, all five county officers and the
U.S. Representative. ⚠ A Cleveland control returns **0 Summit offices**. Per-district control 8/8.

### 🔴🔴 THE COUNTY PUBLISHES TWO COUNCIL MAPS THAT DISAGREE ABOUT AKRON, AND NEITHER NAME NOR CLOSURE COULD SETTLE IT

Both live in the county's own `Summit_Admin` ArcGIS org:

| | features | key field | last edited |
| --- | --- | --- | --- |
| `Summit_County_Council_2025`, layer **"Plan A4"** | **11** (8 districts + 3 at-large with NULL geometry) | `PA4` | 2026-03-02 |
| `County_Council_2023` | 8 | **`Dist2013`** | 2025-02-06 |

They are not two renderings of one map: per-district symmetric difference runs **5% to 209%** of
district area. **Akron City Hall is District 5 on the 2023 layer and District 4 on Plan A4** — so
the choice decides which real person is shown as the county council member for this slice's own city.

🔴 **A NAME CANNOT ARBITRATE.** "County_Council_2023" sounds current and carries a field named for
**2013**; "Plan A4" is a districting-commission plan label, and SC-4 learned that such an org also
publishes drafts and staff plans that were never adopted.
🔴 **NEITHER CAN CLOSURE.** Both tile the county — **99.937%** and **99.996%**. That is CA-2's rule
exactly: closure is a property of the *reference*, never an arbitration between vintages.

### 🟢 WHAT DID SETTLE IT, in order of weight

1. **The arbiter — the members' own words.** Each council member's page names the communities they
   represent. Tested at each place's TIGER interior point: **Plan A4 agrees on 17 of 18, the 2023
   layer on 15 of 18.** Plan A4 wins Cuyahoga Falls (Schmidt, D2), Boston Heights and Munroe Falls
   (Licate, D3). This is now **GATE 5** in the loader, so it is re-runnable.
2. **The body's own lookup app.** The council's "Find Your Council Member" page redirects to an
   ArcGIS app whose webmap has exactly **one** operational layer: Plan A4. A second council lookup
   app uses the same webmap. CA-2 named this as one of the real legs, and it is.
3. **The council's own PDF** is `district-map-february-2025.pdf`; the Plan A4 layer was created
   **2025-02-18**, the same month.
4. Plan A4 carries all **eleven** members with current leadership roles; the 2023 layer carries
   eight and a stale email domain.

### 🔴 THE ONE PIECE OF EVIDENCE POINTING THE OTHER WAY IS RECORDED, NOT BURIED

**Jeff Wilhite's own council page says his District 4 covers Bath Township**, and Plan A4 puts Bath
in District 5. The 2023 layer puts it in District 4, matching his page. That is the single miss out
of eighteen, against three other members' pages that contradict the 2023 map in return. The reading
is that his bio was not updated when the boundaries moved — mixed staleness across bios is exactly
what a boundary change looks like. ▶ **If a later session finds an instrument that overturns this,
District 4 vs District 5 for Akron is the first thing to re-check.**

⚠ **And the Bath test itself needed scoping: Ohio has THREE townships named "Bath".** A join on
name alone returned all three, two of them outside Summit, and scored them as failures for both
maps. Summit's is `geo_id 3915304248`. The Lake County jurisdiction-collision trap, inside my own
query this time.

### 🔴🔴 THE CHARTER, CONFIRMED BY THE OFFICE THAT PROVES IT

Summit elects a **County Executive** and **no commissioners**, an **11-member Council** (8 district
+ 3 at-large, enlarged by the voters in 1988), and **five** row officers. 🟢 The Fiscal Officer's own
site states the merge in its own words — she "manages the county divisions of **Auditor, Recorder,
and Treasurer**" — so the three statutory offices Ohio's other 86 counties elect are one office here,
and there is no elected Coroner either. **An Ohio statutory template would have invented four offices
and missed two.** `CC_0136` carries a gate that refuses any of the abolished titles.

⚠ **So stage 4 here buys nothing reusable for a later Ohio county** — the opposite of what the
program spec's state-slice argument predicts. Only Cuyahoga shares this shape.

### 🔴 SOURCE-ACCESS NOTES

- **`engineer.summitoh.net` and `clerkofcourts.summitoh.net` do not resolve.** The working hosts are
  `summitengineer.net` and `clerkweb.summitoh.net`. ▶ A guessed subdomain is not an absence.
- `boe.ohio.gov` — the Board of Elections, which would have been an independent authority on the
  districts — **403s behind the same Secretary of State WAF and serves a maintenance page**, 1.28 MB
  of it, with a clean-looking body.
- The **Census API answered HTTP 200 with an HTML "Missing Key" page**, so the charter's own
  population-equality test could not be run. The documented trap, met head on.
- `summitmaps.summitoh.net` (which hosts a layer literally titled "County Council Districts (2016)")
  returns **503**.

### Terms: two dated, fifteen not

🟢 Only two arrivals are published by the office that holds them: **Fiscal Officer Kristen M.
Scalise "since May 2011"** → 2011-05-01 at `month` (the day is not published), and **Prosecutor
Elliot Kolkovich "sworn into office on February 21, 2024"** → 2024-02-21 at `day`. ⚠ Both carry
`how_started = 'unknown'`: a February start is mid-term and the page does not say whether by
appointment or election. **The date is sourced; the mechanism is not, and only the sourced half is
written.**

🔴 **The Clerk of Courts is a live instance of the case OH-3 proved.** Tavia Galonski was
**appointed in January 2024** to a seat she then **won in November 2024** — so neither a January
commencement nor her election year describes when she took the office. It is the San José Candelas
case exactly. Her appointment date is not published, so nothing is written.

### Gates

Name collisions checked on the guard's own key — **0 of 17** against a 198-row control. Six
post-verify gates **watched failing**, including the named Akron assertions in both halves; ⚠ the
at-large ordinal control was refused by the **`office_terms_no_overlap` exclusion constraint** before
reaching my gate, and the planted Auditor was caught by the officer-count gate *before* the charter
gate — the charter gate is a second line, not the only one. Five loader gates watched failing.

🔴🔴 **AND MY FIRST CONTROL HARNESS LIED ABOUT ALL THREE LOADER GATES.** It reported "DID NOT FIRE"
for GATE 1, GATE 2 and GATE 5. Run directly, every one of them fired. The harness piped the script's
output through `grep | head -1` inside a command substitution, and the script's own crash-on-exit
left the substitution empty. ▶ **Three gates reporting "did not fire" is a uniform answer, and a
uniform answer is a broken detector — including when the detector is the control harness itself.**
Re-run writing to a file first, all three fired.

Dry run of both migrations as **one transaction ending in ROLLBACK**. `check:occupancy`,
`check:migrations`, `check:reservations`, `check:child-county` green; `check:reachability` nothing
regressed, UNREACHABLE **9** against baseline 24.

▶ **Next: OH-5 — assets. One banner key `akron`, and ~163 portraits.**

---

## Baseline as measured when the slice opened, 2026-09-23 — before OH-1 wrote anything

Re-measure rather than trust this once any wave has applied.

### What already exists

| Layer | Count | Note |
| --- | --- | --- |
| `districts` COUNTY | 88 | all 88 carry a `geo_id`; **Summit `39153`** is present, with `ocd_id`, **no `government_id`, no offices** |
| `districts` NATIONAL_LOWER | 15 | congressional |
| `districts` NATIONAL_UPPER | 1 | |
| `districts` STATE_EXEC | 5 | Governor, Lt. Governor, Attorney General, Secretary of State, Treasurer — all five seated |
| `geofence_boundaries` G4020 | 88 | counties, imported 2026-07-10 |
| `geofence_boundaries` G4110 | **925** | **incorporated places — imported 2026-09-18.** **Akron city `3901000` is present with geometry, 62.2741 sq mi** |
| `geofence_boundaries` G4040 | 1,590 | county subdivisions (Ohio townships), same import |
| `geofence_boundaries` G4210 | 340 | CDPs, same import |
| `geofence_boundaries` G5200 | 15 | congressional, TIGER 2024, imported 2026-04-02 |
| `geofence_boundaries` G5200V26 | 15 | **the 2025 congressional remap**, source `oh_orc_2025`, imported 2026-07-22 |
| `governments` "State of Ohio" | **1** | ✅ not Indiana's 18. `geo_id` `39`, type `STATE` |
| `chambers` under it | 5 | all statewide executives; **no legislative chamber** |

🟢 **OHIO IS THE FIRST KNIGHT SLICE THAT DOES NOT OWE A `place` LOAD.** Every earlier slice loaded
`place` as part of stage 1. Ohio's 925 G4110 records landed on **2026-09-18**, the same national
import that gave Pennsylvania its places hours before PA-1 opened. **Stage 1 here is `sldu` + `sldl`
and nothing else** — which also means the usual "did the place load work?" gate has nothing to
watch, so the stage-1 acceptance test has to be the legislative layers' own.

### What does not exist

- **No `STATE_UPPER` and no `STATE_LOWER` districts, and no `G5210`/`G5220` boundary rows.** Zero.
- **No state legislative offices.** Ohio holds **23 offices in total**: 15 U.S. House, 3 U.S. Senate,
  5 statewide executives.
  - ⚠ The third "U.S. Senate" office is **`Candidate for U.S. Senate — Ohio`, holding Sherrod
    Brown**. It is a candidate office, not a seat. The two real senators are Jon Husted and Bernie
    Moreno. Do not count 3 senators; do not delete the candidate row.
- **No government row for Akron and none for Summit County**, and no `districts` row for Akron —
  normal, because a `place` load writes a boundary and never a district.
- **No Ohio-shaped Indiana defect**: `chambers` matching `%discovery%` or `%unknown%` returns **0**
  nationally, and exactly one Ohio district carries a `government_id` (the NATIONAL_UPPER row).

---

## 🔴 Traps found while opening the slice

### 1. 🔴🔴 THE PROGRAM'S STANDING `offices_missing_terms` ASSERTION IS DEAD — THE BASELINE MOVED 823 → 427 IN TWO DAYS

Every wave from MN-2 to SC-4 closed by asserting `offices_missing_terms` **"unmoved at 823/655"**.
Measured today:

| | total | flagged `is_vacant` | unflagged |
| --- | --- | --- | --- |
| SC-4, 2026-09-20 | 824 | 169 | **655** |
| **OH, 2026-09-23** | **427** | **189** | **238** |

The view definition is unchanged (offices with no `office_terms` row at all), so this is data, not a
definition change. **It is a backfill, not a deletion, and that was established rather than assumed**:
`office_terms.created_at` shows **235 terms written 2026-09-22 and 627 on 2026-09-23**, and their
`source` strings name **`CA_0136`–`CA_0150`, an LA County school-board wave** — Chris Andrews'
namespace, a concurrent session, still running.

▶ **Any OH migration must assert against a baseline measured in the same session, immediately before
the write.** A gate carrying the constant 655 would now fail green-to-red for a reason that has
nothing to do with Ohio. This is the general form of the rule the program already knows: scope a gate
to what the migration creates, never to a number somebody else can move.

⚠ Four terms carry `created_at` of **2026-09-24** while today is 2026-09-23 — the column is UTC and
the clock is local. Harmless; do not read it as a future write.

### 2. 🔴🔴 OHIO'S OWN STATE GIS SERVICE PUBLISHES THE 2012–2022 MAP, AND IT IS UNREACHABLE ANYWAY

The obvious authority — the one a search puts first — is
`geo.oit.ohio.gov/arcgis/rest/services/OhioHouseSenateDistricts/MapServer`, and its layer 1 is titled
**"Ohio House Districts (2012- 2022)"**. That is the *superseded* map, named in a way that invites a
session to load it: this is Horry County's `CurrentCouncilDistricts` trap and Duluth's two council
maps, one tier up. **A layer's title is not its vintage.**

It is also **dead**: `curl` to that host fails to connect on **both 443 and 80** after ~21 s, twice.
Recording the negative with its exact test, per the program's rule that a negative result is only
ever true of the place you looked.

- `ohiosos.gov` answers WebFetch with **HTTP 403** — the documented "fetch it in Playwright" shape,
  not an absence. The Secretary of State's legal description of the adopted plan is at
  `https://www.ohiosos.gov/globalassets/elections/maps/2023-09-29_ohiohousesenatelegaldescription.pdf`
  and the adopted-map page at `sos.state.oh.us/SOS/reshape/GADistricts/adoptedMap.aspx` is where the
  state publishes its own shapefile and block-assignment file. **Neither has been fetched yet.**
- `ohiohouse.gov/members/district/<n>` and `ohiosenate.gov/senators/district/<n>` both **404**. The
  member pages are name-keyed (`ohiohouse.gov/members/veronica-r-sims`), so a district-number URL
  template will fail silently across all 99.

### 3. 🟢 THE VINTAGE EVIDENCE IS STRONG, AND OHIO GIVES A STRUCTURAL PROOF NO OTHER SLICE HAS HAD

**The operative map is the plan the Ohio Redistricting Commission adopted 2023-09-29**, unanimously
and with bipartisan support, upheld by the Ohio Supreme Court in November 2023, and therefore
governing **from the 2024 election through 2030**. So TIGER 2024 is the right vintage on its face.

Measured directly from the `.dbf` inside the raw Census zips (TIGER 2024 FIPS 39, downloaded
2026-09-23, HTTP 200, 1,202,114 and 2,034,425 bytes):

| | rows | MTFCC | LSY | non-numeric codes |
| --- | --- | --- | --- | --- |
| `tl_2024_39_sldu` | **33** | G5210 | 2024 | **none** — no `ZZZ` pseudo-district |
| `tl_2024_39_sldl` | **99** | G5220 | 2024 | **none** |

Ohio is **single-member in both chambers**, so polygon count equals seat count — unlike AZ/WA and
unlike ND/SD later in this program. `skipDistrictCodes` removes nothing here.

🟢 **AND THE NESTING PROVES THE PAIR.** Ohio Const. Art. XI requires each Senate district to be three
whole, contiguous House districts. Tested by taking each of the 99 House districts' own TIGER
interior point (`INTPTLAT`/`INTPTLON`) and locating it among the 33 Senate polygons:

- **99 of 99 House interior points fell in exactly one Senate district. Zero ambiguous, zero
  unmatched.**
- **All 33 Senate districts hold exactly 3 House districts.** The distribution is `{3: 33}`.

This is worth more than a count. A count can never date a map — Ohio's chambers have been 99 and 33
for decades. But a **2022 SLDL paired with a 2023 SLDU would not nest**, so the two files are proved
to be the same plan as each other, and the Commission's plan is the only one in force for 2024–2030.

⚠ **The detector was controlled.** Detroit and Pittsburgh both return **no** Senate and **no** House
district; five Ohio anchors each return exactly one of each.

### 4. 🔴 THE CONVENIENT SENATE↔HOUSE NUMBERING RULE IS FALSE, ON ALL 33

It is natural to assume Senate district *N* holds House districts *3N−2, 3N−1, 3N* — Ohio has
numbered them that way in past decades, and it would make the nesting derivable by arithmetic instead
of by geometry. **Measured: it fails for every one of the 33.** Senate 1 holds House **81, 82, 83**;
Senate 15 holds House **1, 2, 3**; Senate 28 holds House **32, 33, 34**.

▶ **The nesting is geometric and must be read from the polygons.** Anything that derives a senator
from a representative's district number will be wrong 33 times out of 33 and will look tidy doing it.

### 5. 🔴 `geo_id` COLLIDES WITH THE COUNTY LAYER INSIDE OHIO, AND WITH MISSISSIPPI ACROSS IT

TIGER writes the legislative `GEOID` as state FIPS + district code: Senate 31 is `39031`, House 71 is
`39071`. Ohio's 88 counties occupy `39001`–`39175`. So **every Senate `geo_id` and most House
`geo_id`s collide with an Ohio county's**. The key is **(mtfcc, geo_id)**, never `geo_id` alone —
`src/lib/geoIdGuard.ts` guards the production path, ad-hoc SQL does not.

🔴 **And there is already a live cross-state collision on Summit County's own id.** In
`geofence_boundaries`, `geo_id = '39153'` returns **two** rows:

| mtfcc | geo_id | name | state |
| --- | --- | --- | --- |
| G4020 | 39153 | Summit County | **39** |
| G6350 | 39153 | 39153 | **28** |

The second is a **Mississippi ZCTA** — ZIP 39153 is in Mississippi, and `geofence_boundaries.state`
holds 2-digit FIPS, so `28` is MS. ⚠ **Mississippi is slice 16 (Biloxi)**, so this one is live for a
future wave too. A Summit County query keyed on `geo_id` alone silently picks up a Mississippi ZIP.

### 6. 🔴🔴 SUMMIT COUNTY BREAKS THE SPEC'S "COUNTY OFFICER TEMPLATE IS STATE-SCOPED" ASSUMPTION

The program decomposes 26 cities into 16 state slices precisely because four things reuse across a
state, one of them **the county officer template, because state law defines it**. Ohio has 88
counties; 86 are statutory (3 Commissioners, Auditor, Treasurer, Recorder, Clerk of Courts, Coroner,
Engineer, Prosecutor, Sheriff). **Summit is not one of them.** It is one of only two Ohio charter
counties, and its charter replaces that list:

- a **County Executive** (there are no Commissioners),
- an **eleven-member County Council** — **8 by district, 3 at-large** (enlarged to 11 by the voters
  in 1988),
- and **five** row officers: **Clerk of Courts, Engineer, Fiscal Officer, Prosecutor, Sheriff**.

▶ **There is no Auditor, Treasurer or Recorder to seat** — the charter merged all three into the
**Fiscal Officer** — and no elected Coroner; Summit uses an appointed Medical Examiner. **An Ohio
statutory template applied here would invent four offices that do not exist and miss two that do.**
This is the repo's standing rule with a charter behind it: describe real powers, do not make
jurisdictions uniform. ⚠ It also means **slice 8's stage 4 buys nothing reusable for a later Ohio
county**, which is the opposite of what the spec's state-slice argument predicts. Say so in the
stage-4 plan so the reviewer is not surprised.

### 7. ⚠ BOTH LOCAL DISTRICT LAYERS ARE UNPROVEN, AND ONE IS PUBLISHED AS A PDF

- **Summit County Council districts:** the Council's own page offers a **"District Map (PDF)"**. That
  is the Lake County shape — PDF-only publication, the wave deferred seven seats over it. The county
  runs a GIS department; **ask it before concluding there is no layer**, and remember that IN-8's
  boundary was public all along in a *different* ArcGIS organisation from the one IN-6 swept.
- **Akron's 10 wards:** no layer measured yet. Akron's place polygon exists (62.2741 sq mi), so a
  ward layer can at least be closure-tested against it.
- ⚠ Neither layer's vintage has been asked about at all. Akron redistricted its wards after the 2020
  census; the date is not yet established.

---

## Expected scope

| Stage | Offices | Notes |
| --- | --- | --- |
| 2 legislature | **132** | 99 House + 33 Senate, single-member both chambers |
| 3 Akron | **14** | Mayor + 3 at-large + 10 ward. Mayor **Shammas Malik**, sworn in 2024-01-01 |
| 4 Summit County | **17** | Executive + 11 Council + 5 row officers |
| **total** | **163** | plus 1 banner key `akron` and ~163 portraits at stage 5 |

⚠ These are **sizes, not rosters.** Nobody has been change-checked. Municipal court judges are out of
scope, with the judges wave, as in every earlier slice.

🔴 **Akron's four-answer probe currently scores 0 of 4** — no council member, no county council
member, no state representative, no state senator. Measured today: Akron holds no office of any kind.
Stage 2 must precede stage 3, or the probe can never score better than 2 of 4.

**Anchors for that probe, measured from raw TIGER 2024 and controlled:**

| anchor | Senate | House |
| --- | --- | --- |
| Akron City Hall, 166 S High St | **28** | **33** |
| Summit County Courthouse, 209 S High St | 28 | 33 |
| University of Akron, Buchtel Ave | 28 | 33 |
| Kenmore, west Akron | 28 | **32** |
| Cuyahoga Falls City Hall | **27** | **31** |
| CONTROL — Detroit, MI | none | none |
| CONTROL — Pittsburgh, PA | none | none |

🟢 **One identity anchor already agrees with an independent source**: House District 33 is
**Veronica Sims (D–Akron), serving since 2024** — the district TIGER puts Akron City Hall in, held by
an Akron member seated under the 2023 plan. That is one anchor, not a proof; OH-1 owes the rest.

---

## Next steps, in order

1. ~~Prove the vintage against Ohio's own authority.~~ **Done 2026-09-23 — 132 of 132 agree with the
   Secretary of State's own plan, and the TIGER 2022 control failed as required.** The adopted-map
   page at `sos.state.oh.us` does not resolve; the live links are on
   `ohiosos.gov/elections/district-maps`.
2. ~~Add `OH` to `STATE_LAYER_ALLOWLIST` with a pre-flight block.~~ **Done — `['sldu','sldl']` only,
   and the assertion was watched failing at 34.**
3. ~~Run OH-1.~~ **Done — 132 boundaries, 132 districts, 0 errors; re-run clean.**
4. ~~OH-2: seat the General Assembly.~~ **Done — `CC_0131`/`CC_0132`, 132 offices, 130 seated,
   2 vacant. Akron scores 2 of 4.**
5. ~~OH-3 Akron.~~ **Done — `X0063`, `CC_0133`/`CC_0134`, 14 offices, 14 seated. Akron scores
   3 of 4.**
6. ~~OH-4 Summit County.~~ **Done — `X0064`, `CC_0136`/`CC_0137`, 17 offices, 17 seated.
   Akron scores 4 of 4.**
7. ~~OH-5 assets.~~ **Done — 161 of 161 portraits and the `akron` banner. The slice closes.**

---

## ✅ OH-5 APPLIED 2026-09-24 — 161 of 161 portraits, and Akron's banner

**Ohio goes 0 → 161 renderable**, all on our own CDN, all carrying a `politician_images` row. The
baseline was re-measured in this session and again minutes before the write, and it agreed with the
handoff at **161 seated / 0 renderable / 161 owed**.

| chamber | owed | imported | source |
| --- | --- | --- | --- |
| Ohio House of Representatives | 98 | **98** | `ohiohouse.gov`, unlinked `large` 1280x1759 |
| Ohio Senate | 32 | **32** | `ohiosenate.gov`, unlinked `large` 1280x1600 |
| Akron City Council | 13 | **13** | `akroncitycouncil.org` Drupal originals |
| Summit County Council | 11 | **11** | `council.summitoh.net` `/image/original/` |
| Elected Officials (Summit) | 5 | **5** | five separate publishers |
| Office of the County Executive | 1 | **1** | `co.summitoh.net` |
| Office of the Mayor | 1 | **1** | `akronohio.gov` |
| **total** | **161** | **161** | 0 skipped, 0 failed |

🟢 **Zero renderable was a TRUE zero, and it was proved rather than assumed.** A uniform
answer is a broken detector, so the same query was read for rows it must NOT return zero for:
Ohio's Governor, Attorney General, Secretary of State and Treasurer each came back **1**, and
Summit County **Utah** came back **5 of 5**. ⚠ That Utah county is a live name collision with
this slice's own subject — the scope keys on `governments.id`, never on a name LIKE.

✅ **Every stored object was verified as a real JPEG at its public URL — 161 of 161, 30 KB
to 178 KB — with a nonexistent-key control that correctly failed.** The importer's summary says
what it *did*; this says what is *there*.

### 🔴🔴 THE SHARED IMPORTER WAS BROKEN FOR EVERY WAVE ON THIS MACHINE, AND THE ERROR NAMED THE WRONG THING

The first run failed **all 161 uploads**:

```
HTTP 400 {"statusCode":"403","error":"Unauthorized","message":"Invalid Compact JWS","code":"AccessDenied"}
```

**Supabase now issues secret keys as `sb_secret_...` rather than the legacy `service_role` JWT**,
and Storage parses a lone `Authorization: Bearer` token as a compact JWS — so a valid key is
refused as a malformed token. ▶ **The `apikey` header is accepted for BOTH key formats**, proved
by probing the three header combinations against a throwaway object: Bearer alone 400, `apikey`
alone 200, both 200. Fixed to send both in `import-headshot-candidates.py` and
`mirror-photo-origin-to-storage.py` — the only other script with that call shape — so it
works whichever key an `.env` carries and needs no migration.

🔴 **AN AUTH FAILURE WEARING TWO STATUS CODES AT ONCE READS LIKE A BROKEN OBJECT.** The
transport says 400, the body says 403, and the message names JWS parsing rather than the credential.
The standing rule that *a missing object in OUR bucket is HTTP 400* points straight past it.

🟢 **THE ESSENTIALS REPO ALREADY KNEW.** `scripts/banners/upload_banner.py` carries the
comment *"BOTH Authorization AND apikey"*. The lesson was learned in one repo and never crossed into
the other. ▶ **When a fix concerns a shared external service, grep the sibling repos for the
same call shape.**

🟢 **NOTHING WAS WRITTEN BY THE FAILED RUN, AND THAT WAS MEASURED RATHER THAN READ OFF THE
SOURCE.** The importer `continue`s before any database write; production was re-measured afterwards
and still showed 0 renderable / 0 image rows. The fix was then proved on **one** person end to end
— object present, real JPEG, `photo_custom_url` pointing at our CDN, `photo_origin_url` holding
the source PAGE — before the remaining 160 ran.

### 🔴🔴 A BARE NUMERIC FILENAME NAMES NO PERSON — AND THE BINDING WAS THE MEMBER'S OWN URL

The Ohio House serves portraits at `/assets/people/headshots/<size>/<numeric id>.jpg`. A number is
the positional-filename class: the roster tile alone cannot prove the face belongs to the member
captioned under it. But each member also has a **name-keyed page**, `ohiohouse.gov/members/<slug>`,
whose own asset paths carry the same numeric id. **90 of 98 bound, and — the number that matters
— ZERO MISMATCHES.** The other 8 pages carry no asset path at all, so the check is *silent* on
them rather than contradicting; those 8 went to the proof sheet flagged "verify face".

🔴🔴 **THE FIRST RUN OF THAT CHECK RETURNED A UNIFORM "NOT FOUND" FOR ALL 98, AND
THE DETECTOR WAS THE BUG.** It searched for the headshot path on the member page; the member page
does not serve the headshot, it serves a *banner* under `/assets/people/<id>/`. The id was there the
whole time. ▶ **The uniform answer was treated as a broken detector and it was one.** The
corrected check ships with a negative control: a planted id `9999999` is correctly not found.

### The roster parser was watched failing before it was trusted

Both chamber directories are parsed by **splitting on the container tag and reading each block in
isolation** — the fix for OH-2's off-by-one, where one regex crossed a block boundary and stole
the next member's image. Two defects were planted and the parser was watched catching both: a
stripped headshot (reported as a real member with no photo) and a destroyed container tag (reported
as a lost block). ⚠ **The first attempt at the second defect used a GUESSED marker string that
never matched, so the control "passed" while planting nothing** — the marker is now read out of
the live file.

Counts that agree from two directions: **99 House tiles / 98 portraits / HD-66 placeholder** and
**33 Senate tiles / 32 portraits / SD-13 placeholder**, matching the database's own 98 and 32 and
both recorded vacancies. **130 of 130 legislators matched by district with all 130 names agreeing
independently**; **31 of 31 local officials matched by full name**, nothing unmatched in either
direction.

### 🟢 BOTH CHAMBERS PUBLISH A HIGHER-RESOLUTION FILE THEY NEVER LINK

The directory tiles use a 640px `medium`. A `large` exists at the same path — **1280x1759**
(House) and **1280x1600** (Senate) — and a ~3200px original of about 10 MB. `large` was taken:
it clears 600x750 without upscaling and does not cost a gigabyte of downloads. Same shape as MN-6's
unlinked 1050x1350 JPEG.

⚠ **THE BUCKET NAME IS PER-SITE AND IS NOT GUESSABLE.** Three portraits first failed as
`cannot identify image file`, which reads like a dead link. All three were a **wrong bucket name**,
not an absent file: `co.summitoh.net` wanted `col9`, `summitengineer.net` ignores the bucket
entirely and serves one size at every name, and the Mayor's file sits at the **site root**, not
under the page that references it.

### Licence

Neither chamber publishes a photo policy. Both footers carry only *"(c) 2026 ... All Rights
Reserved"* and the linked Disclaimer is liability text that never mentions images. This is the
**GA/FL/PA shape** — no published refusal to supersede — not the **MN shape**, where a
policy forbidding cropping and re-hosting required a grant. Operator ruling 2026-09-24: **import as
`press_use` now**. ⚠ **Absence of a policy is still not a licence**, and a blanket site
copyright notice is not a photo policy either; what makes this defensible is that no restriction was
published, and it is recorded here so a later session does not read it as a grant.

Upscales, all shown on the proof sheet and all stored at native size rather than enlarged
(`--max-upscale 1.0`): **John N. Schmidt 400x500**, and **Brandon Ford**, **Donnie Kammer** and
**B. Alan Brubaker** at 480x600. No monochrome anywhere in the 161.

**Proof sheet:** https://claude.ai/artifact/5nqDBw52LQGCoNPuyne2sn

---

## ✅ The `akron` banner — and a new shape of the adjacency problem

**`cities/akron.jpg`** — *Main Street Akron*, 24 September 2024, **Dillguy9, CC0**, 4032x2266,
processed to 1700x540 at `vertical_anchor 0.44` and registered with **`focus: '50% 100%'`**.
Certification sheet: https://claude.ai/artifact/KNVLvfB5XAdAqzYP6NjrmV

🔴🔴 **THE OHIO STATE BANNER IS A CITY SKYLINE — CINCINNATI FROM DEVOU PARK
— AND THAT IS A NEW SHAPE OF THE ADJACENCY RULE.** Miami, Wichita, Detroit and Charlotte
collide because the state banner is *that* city's skyline, so a name check catches them. Here the
city is different, a name check passes, **and the frame still collides**: read in the 6:1 band,
`states/OH.jpg` is a horizontal bar of towers at mid-distance under a big sky, which is what *any*
Akron skyline would also be. ▶ **Run the adjacency test against the BAND and against
COMPOSITION, never against the subject line.** Eight candidates were refused on it, with reasons, on
the certification sheet — including Lock 15 on the Ohio & Erie Canal, which is the right idea
for Akron and at 6:1 is white water and rock. **A correct subject is not a correct frame.**

🟢 **OPERATOR DIRECTION SEPARATED THE ASSET FROM THE DESKTOP CROP** (2026-09-24): *"keep the
full asset and crop from the top (keeping the bottom) for the desktop band."* The approved
centre-band crop (`vertical_anchor 0.75`) was a good desktop frame and a poor asset — it threw
away the tower tops that mobile shows 96.9% of. The asset is now built at **0.44**, holding the
towers *and* reaching down to the marquee, and the desktop band is aimed at the bottom. Same lesson
as Columbia and Myrtle Beach, reached from the other direction.
⚠ **The focus is not a guess.** `50% 100%` puts asset rows 257..540 on the same source rows the
approved 0.75 band occupied, and it was verified by rendering the retargeted band beside the
approved one.

✅ **People test passes**: no pedestrians in frame. The only human figures are a promotional LED
board and a printed historical mural — published graphics on a wall, not identifiable
bystanders.
✅ **A new key needs no `-v2`**: both `cities/akron.jpg` and `cities/akron-v2.jpg` returned HTTP
400 `NoSuchKey` before the upload, so the stale-CDN rule, which applies to overwrites, does not bite.
✅ `banners:check` green, **242/245 credited**; the full essentials suite **468 tests across 20
files, all passing**.

⚠ **The essentials checkout at `C:\Transparent Motivations\essentials` was sitting on a merged
`feat/banners-sc`, 3 behind `origin/main`.** It was left alone. This work is on
`knight/oh-banner-akron` in a worktree at `C:\essentials-oh-banner`.

### Debts this slice already owes

- **130 undated arrivals.** Every General Assembly term is open-ended at `unknown`. Neither chamber
  publishes a service-start date; dating them needs the chambers' journals, as SC-2 did.
- **SD-13's vacancy has no start date.** Flagged, undated, and deliberately so.
- **HD-66 and SD-13 will both be filled by caucus appointment.** When that happens the successor is
  seated from the appointment date — do not let the vacancy flag go stale.
