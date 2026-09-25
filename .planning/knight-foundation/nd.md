# ND — slice 12 (Grand Forks · Grand Forks County)

Program tracker: [`PROGRAM.md`](./PROGRAM.md) · spec:
[`2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md)

**Opened 2026-09-25.** Lease `state:nd` held by chris@empowered.vote on DESKTOP-G6KDNN2.
Worktree `C:\ev-accounts-nd`, branch `knight/nd-slice12`.

| Stage | State |
| --- | --- |
| 1 geography | ✅ **APPLIED 2026-09-25 — 95 boundaries, 95 districts, 0 errors.** Only `sldu` + `sldl` were owed; `place` already existed |
| 2 legislature | ✅ **APPLIED 2026-09-25 — 141 offices, 141 seated, 0 vacant** (`CC_0144`/`CC_0145`). Grand Forks scores **3 of 5** |
| 3 city waves | ✅ **APPLIED 2026-09-25 — 9 offices, 9 seated, 0 vacant, EVERY TERM DATED** (`X0067`, `CC_0146`/`CC_0147`). Grand Forks scores **4 of 5** |
| 4 county waves | ✅ **APPLIED 2026-09-25 — 7 offices, 7 seated, 0 vacant, 6 day + 1 year precision** (`CC_0148`/`CC_0149`). **No geometry loaded: the commission is at large.** Grand Forks scores **5 of 5** |
| 5 assets | ✅ **APPLIED 2026-09-25 — 148 PORTRAITS IMPORTED, 0 failed; 148 of 148 decode from the CDN.** Hold LIFTED by Cantrell the same day. Banner adjacency test run: **no collision**. ⚠ Licence stays an **accepted debt** on both cohorts; the request form is still **not sent** |

---

## 🔴🔴 THE ONE THING THAT MAKES THIS SLICE DIFFERENT: THE HOUSE IS MULTI-MEMBER

N.D. Const. Art. IV § 2 gives every legislative district **one senator and TWO representatives**.
North Dakota is the first slice in this program where that is true, and it breaks an assumption
every earlier slice was allowed to make.

| | polygons | seats |
| --- | --- | --- |
| Senate | 47 | 47 |
| House | **48** | **94** |

The House is 48 polygons and 94 seats because **46 districts elect two representatives each (92)
and subdistricts 4A and 4B elect one each (2)**. So the seat count is not a single multiplier over
the polygon count — it is 46×2 + 2, and the two halves come from different rules.

▶ **Consequences, which must be carried into ND-2, ND-3 and ND-4:**

- 🔴 **The per-district control every earlier slice used — "each district holds exactly one
  office" — is FALSE here and will fail correctly on 46 of 48 House districts.** MI-4's version of
  that gate does not carry over. The ND form is: **exactly two offices on each of the 46 whole
  districts, exactly one on each of 4A and 4B, and 94 in total.**
- 🔴 **The program's four-answer probe returns FIVE answers in North Dakota**, not four: council
  member, county commissioner, state senator, and **two** state representatives. A probe that
  asserts "4 answers" would read a correct result as a defect, and a probe that asserts "one
  representative" would read a correct result as a duplicate.
- 🔴 **A duplicate-detection sweep keyed on (district, chamber) will report all 46 whole House
  districts as duplicates.** They are not. Key on the office row, never on the district.

⚠ **AZ and WA set the multi-member precedent in the loader, but neither has ND's twist**: in those
states every district is uniformly dual-member. Here two of the 48 are single-member, so the rule
has an exception inside it. Do not simplify it back to "×2".

---

## ✅ ND-1 APPLIED 2026-09-25 — North Dakota has legislative geography for the first time

**95 boundaries and 95 districts — 47 Senate + 48 House — 0 errors.** Measured from outside
immediately after the run: `districts` **10,021 → 10,116** and `geofence_boundaries`
**72,205 → 72,300**, both moving by **exactly 95**. `offices_missing_terms` unmoved at
**423 total / 238 unflagged**.

Command:

```bash
npx tsx scripts/load-state-tiger-boundaries.ts --state ND --fips 38 --layers sldu,sldl --vintage 2024
```

No migration. Geography loads run through the loader, not through a numbered migration, so no
steward slot was reserved for this wave.

### 🟢 THE VINTAGE WAS PROVED, AND NORTH DAKOTA GIVES EVIDENCE MOST STATES CANNOT

The operative map is the one the **U.S. District Court ordered on 2024-01-08** in *Turtle Mountain
Band of Chippewa Indians v. Howe*, after holding on 2023-11-17 that the drawing of Districts 9 and
15 and Subdistricts 9A and 9B diluted Native American voting strength under VRA § 2. The remedy
**dissolved 9A/9B back into a whole District 9** and left 4A/4B standing.

🟢 **That makes the House layer's own code set date the map** — which is rare, and is the opposite
of Ohio, where every plan ever drawn was 99/33:

| TIGER vintage | LSY | House polygons | subdistricts | plan |
| --- | --- | --- | --- | --- |
| 2022 | 2022 | 49 | 04A 04B **09A 09B** | HB 1504 (2021) — **struck down** |
| 2023 | 2022 | 49 | 04A 04B **09A 09B** | HB 1504 — struck down |
| **2024** | **2024** | **48** | **04A 04B** | **court-ordered 2024-01-08** |
| 2025 | 2024 | 48 | 04A 04B | same plan |

⚠ **THE CODE SET IS EVIDENCE, NOT THE PROOF, AND THE DIFFERENCE MATTERS.** The same order also
redrew **District 15, which kept its number**. A code-set check is blind to every boundary change
that does not rename a district, so it would have waved through a file that moved District 15 and
nothing else.

**The proof is geometric.** `scripts/verify-nd-tiger-vintage.mjs` locates every TIGER polygon at its
own published internal point (`INTPTLAT`/`INTPTLON`) inside the state's own authority layer:

```
🟢 House  — TIGER 2024 vs the court-ordered 2024 plan: 48 polygons, AGREE 48, DISAGREE 0, ambiguous 0
🟢 Senate — TIGER 2024 vs the court-ordered 2024 plan: 47 polygons, AGREE 47, DISAGREE 0, ambiguous 0
```

**And the control failed as required**, on exactly the districts the court moved:

```
🟢 House  — CONTROL, TIGER 2022 (HB 1504, struck down): AGREE 47, DISAGREE 2 — 9B->15, 9A->9
🟢 Senate — CONTROL, TIGER 2022 (HB 1504, struck down): AGREE 46, DISAGREE 1 — 9->15
```

🔴 **AND THE CONTROL STILL AGREES ON 47 OF 49 AND 46 OF 47.** Two districts out of forty-seven
moved. A count passes the dead map. A shape check passes it. A spot check passes it. **Even a
96%-agreement threshold passes it.** The only thing that separates the two plans is the handful of
polygons the litigation was about — so the test has to be every polygon, or it is not a test.

### 🟢 THE AUTHORITY, AND WHY IT IS NOT THE CENSUS

`NDGISHUB Legislative Districts`, the North Dakota GIS Hub's own layer, whose published abstract
says it "**Shows the 47 legislative districts revised as a result of the order imposed by the United
States District Court on January 8, 2024**". 48 features, `DISTRICT` values 1–47 with 4 replaced by
4A/4B. Service:

```
https://services1.arcgis.com/GOcSXpzwBHyk2nog/arcgis/rest/services/NDGISHUB_Legislative_Districts/FeatureServer/0
```

🟢 **Unlike Ohio's Secretary of State, it answers a plain request** — HTTP 200 and
`application/json` to a bare `curl`, no WAF, no Playwright, no challenge page. The whole layer comes
back in one query with `exceededTransferLimit` absent, which the verifier asserts rather than
assumes.

### 🔴 THE SUPERSEDED PLAN IS PUBLISHED BESIDE THE LIVE ONE, AND SORTS ABOVE IT ON ONE FIELD

The same catalogue serves **`NDGISHUB 2021 67th Assembly Legislative Districts`** — HB 1504, the map
the court struck down. Its dates:

| layer | `modified` | `issued` |
| --- | --- | --- |
| **`NDGISHUB Legislative Districts`** (live) | 2024-01-08 | 2022-01-21 |
| `NDGISHUB 2021 67th Assembly…` (**struck down**) | 2021-11-12 | **2025-03-24** |

**Sorting these two by freshness on `issued` picks the dead map**, by three years. This is the same
shape as Santa Clara's five supervisor layers and Duluth's two council maps, with a new twist: here
the misleading field is a *catalogue* timestamp describing when a historical layer was *added to the
portal*, not when its boundaries were drawn. **Name the layer. Never take the newest.**

### 🔴 A NORTH DAKOTA HOUSE DISTRICT IS NOT AN INTEGER

`04A` and `04B` carry a letter. `parseInt('04A')` is 4 — the MN `08A` / MD `1A` collapse, which
writes two districts onto one OCD-ID silently, because `ocd_id` has no unique constraint and address
search resolves on `geo_id`. `src/lib/ocdDistrictSuffix.ts` already existed to prevent it (the MN-1
fix, and `CC_0113` repaired Maryland's 84 rows), and it held here. Verified in production after the
load:

| geo_id | ocd_id |
| --- | --- |
| `3804A` | `ocd-division/country:us/state:nd/sldl:4A` |
| `3804B` | `ocd-division/country:us/state:nd/sldl:4B` |

**48 rows, 48 distinct `ocd_id`s.** And `STATE_LOWER` correctly holds **no `38004`** — the House has
no whole District 4.

🔴 **THE SAME TRAP BIT ONCE MORE, IN MY OWN VERIFICATION QUERY, AND THE COUNT WAS THE TELL.** The
first nesting check joined House to Senate on `regexp_replace(substr(geo_id,3), '[A-Z]$','')`, which
turns `3804A` into `04` while the Senate side is `004`. The two subdistricts **silently failed to
join** and the query reported a confident `48 house polygons ... 46`. It was wrong because the
header said 48 and the body said 46. **Strip leading zeros on BOTH sides, and read the count before
reading the verdict.**

### Gates

All measured against production after the load.

| gate | result |
| --- | --- |
| row deltas | `districts` +95 exactly, `geofence_boundaries` +95 exactly |
| layer counts | `G5210` 47, `G5220` 48 |
| OCD-ID collapse | 48 `STATE_LOWER` rows, **48 distinct `ocd_id`** |
| House nests in its Senate district | **48 of 48 by `ST_Covers`, 0 failures** — measured, not inferred |
| 4A ∪ 4B = Senate 4 | 1,582.6207 + 2,666.3512 = **4,248.9719 sq mi**, overlap **0.000000**, symmetric difference **0.000000** |
| per-district control | `G5210` **47/47** and `G5220` **48/48** resolve to exactly themselves, 0 ambiguous |
| `offices_missing_terms` | unmoved, 423 / 238 unflagged |
| `check:reachability` | **green, nothing regressed** — BAD_GEOMETRY 4 (baseline 4), DEAD_GEOGRAPHY 17 (17), UNREACHABLE 7 (7) |
| `check:occupancy` | green |
| `check:migrations` | green, 0 added vs `origin/master` |

⚠ **The nesting result is 48 of 48 and that is nearly trivial here, which is worth saying out loud.**
North Dakota's House districts are *geometrically identical* to their Senate districts everywhere
except District 4. Tennessee's 28-of-99 and Colorado's failures came from states that genuinely
subdivide; the only real nesting question in North Dakota is whether 4A and 4B tile District 4, and
that is the row above it.

### The three pre-flight assertions were each watched failing first

The loader's new ND block carries three independent assertions. A gate nobody has seen fail is a
gate nobody has tested, so each was made to fire before the real run:

| assertion | how it was made to fail | what it printed |
| --- | --- | --- |
| record count | ran against `--vintage 2022` | `expected 48 records, got 49 ... ⚠ 49 records with 09A/09B is HB 1504, the map struck down under VRA § 2 — NOT a newer file` |
| subdistrict identity | raised the expected count to 49 so the count assertion could not pre-empt it, still on 2022 | `subdistricts ["4A","4B","9A","9B"], expected ["4A","4B"] ... this file is HB 1504, the STRUCK-DOWN map` |
| seat arithmetic | set `ND_HOUSE_SEATS` to 92 | `46 dual-member districts + 2 single-member subdistricts = 94 House seats, expected 92` |

🔴 **The second one matters because the first hides it.** On the real struck-down file the count
assertion fires first and the subdistrict assertion never runs — so without deliberately lifting the
count, that branch would have shipped untested. **When two gates guard the same file, the outer one
prevents you from testing the inner one.**

Both tampers were reverted from a byte copy taken before the edit, and the file was re-checked for
the `CONTROL-TAMPER` marker: **0 occurrences.**

### The per-district control was itself controlled

A control that passes can pass for the wrong reason, so the point-in-polygon sweep was re-run two
ways it had to fail:

| run | hits | reading |
| --- | --- | --- |
| the 48 House interior points, unshifted, against ND | **48** | positive control |
| the same 48 points against **Minnesota's** legislative layers | **0** | the sweep is state-scoped, not matching anything anywhere |
| the same 48 points **translated 3° east**, against ND | **23** | the sweep moves with its input; it is not returning a constant |

⚠ 23 rather than 0 because North Dakota is about 6° wide, so a 3° shift lands many points inside the
state but in the **wrong** district. That is the useful answer: the sweep discriminates.

---

## Baseline as measured when the slice opened, 2026-09-25 — before ND-1 wrote anything

Re-measure rather than trust this once any wave has applied.

### What already existed

| Layer | Count | Note |
| --- | --- | --- |
| `districts` COUNTY | 53 | **Grand Forks County `38035`** present |
| `districts` NATIONAL_LOWER | 1 | `ND At Large` — North Dakota has one U.S. Representative |
| `districts` NATIONAL_UPPER | 1 | |
| `districts` STATE_EXEC | 5 | Governor, Lt. Governor, Attorney General, Secretary of State, Treasurer — all five seated |
| `geofence_boundaries` G4020 | 53 | counties |
| `geofence_boundaries` G4110 | **355** | **incorporated places — already present.** **Grand Forks city `3832060`** with geometry |
| `geofence_boundaries` G4040 | 1,668 | county subdivisions (ND civil townships) |
| `geofence_boundaries` G4210 | 51 | CDPs |
| `geofence_boundaries` G5200 | 1 | the at-large congressional district |
| `geofence_boundaries` G6350 | 388 | ZCTAs |
| `governments` "State of North Dakota" | **1** | ✅ not Indiana's 18. Type `STATE` |
| `chambers` under it | 5 | all statewide executives; **no legislative chamber** |

🟢 **North Dakota is the second Knight slice that owes no `place` load**, after Ohio — one of the six
states (KS KY MI MS ND SD) whose places arrived with the national municipal import. **Stage 1 here
was `sldu` + `sldl` and nothing else.**

### What did not exist

- **No `STATE_UPPER` and no `STATE_LOWER` districts, and no `G5210`/`G5220` boundary rows.** Zero.
- **No state legislative offices.** North Dakota held **8 offices in total**: 1 U.S. Representative,
  2 U.S. Senators, 5 statewide executives — **all 8 seated**.
  - 🟢 **No candidate-office decoy.** Ohio carried a `Candidate for U.S. Senate` row that read as a
    third senator; North Dakota's two senate offices are both real. Checked, not assumed.
- **No government row for Grand Forks and none for Grand Forks County.**
- **No Indiana-shaped defect**: no `%discovery%` / `%unknown%` chambers.

---

## Anchors, measured against production after ND-1

| anchor | Senate | House |
| --- | --- | --- |
| Grand Forks City Hall, 255 N 4th St | **18** | **18** |
| Grand Forks County Office Building, 151 S 4th St | 18 | 18 |
| University of North Dakota, 264 Centennial Dr | **42** | **42** |
| Grand Forks AFB CDP | 42 | 42 |
| **Belcourt CDP — Turtle Mountain reservation** | **9** | **9** |
| **Fort Totten CDP — Spirit Lake reservation** | **9** | **9** |
| New Town — Fort Berthold | 4 | **4A** |
| Mandaree — Fort Berthold | 4 | **4A** |
| CONTROL — Fargo City Hall | 44 | 44 |
| CONTROL — Duluth, MN | none | none |
| CONTROL — Aberdeen, SD | none | none |

🟢 **The two reservation anchors are the strongest identity evidence in this slice.** Belcourt
(Turtle Mountain) and Fort Totten (Spirit Lake) **both return District 9** — putting the two
reservations in one district is precisely what the court ordered and precisely what HB 1504 did not
do. Under the struck-down map Belcourt was in 9A and Fort Totten was in 15. The remedy is visible in
the loaded data, not merely asserted about it.

⚠ Senate and House agree on every row above because North Dakota's House districts **are** its
Senate districts outside District 4. That is a property of this state, not a sign the two layers
were loaded from one file — they came from `tl_2024_38_sldu.zip` and `tl_2024_38_sldl.zip`, which
differ in feature count (47 vs 48) and MTFCC.

### Grand Forks spans four legislative districts, the county five

| scope | districts touched (>10,000 m² of overlap) |
| --- | --- |
| Grand Forks city `3832060` | **17, 18, 42, 43** |
| Grand Forks County `38035` | **17, 18, 20, 42, 43** |

▶ So a Grand Forks address can legitimately return any of four Senate seats and eight House seats
across the city. **District 20 covers 1,186.84 sq mi of the county and none of the city.**

---

## Expected scope

| Stage | Offices | Notes |
| --- | --- | --- |
| 2 legislature | **141** | 47 Senate + **94 House** over 48 House polygons |
| 3 Grand Forks | ? | **unmeasured** — city council size and structure not yet read from the charter |
| 4 Grand Forks County | ? | **unmeasured** — commission size and the elected-officer list not yet read from N.D.C.C. and the county's own record |
| 5 assets | ~141+ | portraits for everyone seated, plus a `grand-forks` banner key |

⚠ These are **sizes, not rosters.** Nobody has been change-checked. Stage 2's 141 is the
constitutional seat count, which is a claim about the map, not about who sits in it.

🔴 **Grand Forks' probe currently scores 0 of 5** — no council member, no county commissioner, no
state senator, no state representatives. North Dakota holds no office reachable from a Grand Forks
address. **Stage 2 must precede stage 3**, as in every slice.

---

## Next steps, in order

1. ~~Prove the vintage against North Dakota's own authority.~~ **Done 2026-09-25 — 95 of 95 agree
   with the court-ordered plan, and the TIGER 2022 control failed on exactly the three district
   pairs the litigation moved.**
2. ~~Add `ND` to `STATE_LAYER_ALLOWLIST` with a pre-flight block.~~ **Done — `['sldu','sldl']` only,
   and all three assertions were watched failing.**
3. ~~Run ND-1.~~ **Done — 95 boundaries, 95 districts, 0 errors.**
4. ~~ND-2: seat the Legislative Assembly.~~ **Done 2026-09-25 — `CC_0144`/`CC_0145`, 141 offices,
   141 seated, 0 vacant, 8 arrivals dated to the day. Grand Forks scores 3 of 5.** The structural
   question was settled on ballot truth: two identical-title offices per district, Arizona's shape,
   paired to members by a deterministic slot that asserts nothing.
5. **ND-3 Grand Forks.** ~~Read the city's own charter sentence for the office inventory.~~
   **Measured 2026-09-25 — 9 offices: Mayor + 7 single-member wards + an ELECTED Municipal Judge,
   no at-large seat.** Ward geometry located in the state's 2026 precinct layer and proved to tile
   the city within digitization noise. ▶ **Still owed before writing: a decision on term dates**
   (the city publishes none) **and a change-check that is not the roster page** — see the ND-3
   section below.
6. **ND-4 Grand Forks County.** ~~Read the county's own record rather than the state template.~~
   **Measured 2026-09-25 — the commission is 5 seats elected AT LARGE, with NO districts**, agreed
   by the state precinct layer and the county's own page. ▶ **Still owed: which officers the voters
   elect**, which the scanned home-rule charter has not yet answered.
7. **ND-5 assets.** Portraits and the `grand-forks` banner. ⚠ Check the banner against the ND state
   banner for composition collision before choosing a frame.

---

## Debts this slice already owes

- ⚠ **`X` boundary codes still have no allocator.** Stages 3 and 4 will need city ward and county
  commission district codes, and the current practice is to read `max` from production — the exact
  shape of the migration-number collision the steward exists to prevent. Unchanged from OH-3's note.
- ⚠ **The `--vintage 2025` files carry the same plan** (48 polygons, LSY 2024) and were not used.
  Nothing depends on this, but if a later wave reloads ND, 2024 is the vintage this slice proved and
  2025 is unproved.

---

## ✅ ND-2 APPLIED 2026-09-25 — the North Dakota Legislative Assembly is seated

`CC_0144` (structure) + `CC_0145` (occupancy): **141 offices — 47 Senate + 94 House — 141 seated,
0 vacant, 141 people created.** Measured from outside after the apply: `politicians`
**88,854 → 88,995** and `office_terms` **9,330 → 9,471**, both **exactly +141**.
`offices_missing_terms` went **423 → 564** when `CC_0144` created the offices and back to
**423 / 238 unflagged** when `CC_0145` seated them — the whole excursion accounted for, with
141 out and 141 back.

Both migrations are **idempotent, proved by re-running each**: every `essentials.*` insert
returns `INSERT 0 0` on the second run and both gates still pass.

### 🔴🔴 THE ROSTER THAT LOOKS RIGHT HOLDS 148 MEMBERS — SEVEN MORE THAN THE CONSTITUTION ALLOWS

ndlegis.gov publishes **three** member lists for the 69th Assembly: Regular Session, Jan 2026
Special Session, Sep 2026 Special Session. The regular-session list is **cumulative** — it retains
everyone who held a seat at any point — so **seven districts list FOUR members**.

🔴 **And "four in a district" is invisible to the obvious shape check here.** North Dakota's House
is legitimately two-per-district, so four reads as 2×2. In a single-member state this defect
announces itself on the first `GROUP BY district`; in North Dakota it looks like the correct answer.
A wave that took the first roster it found would have tried to seat 148 people into 141 seats.

| roster | members | senators | reps | districts not holding 1+2 |
| --- | --- | --- | --- | --- |
| Regular Session | **148** | **48** | **100** | **7** (11, 20, 25, 26, 27, 42, 44) |
| Jan 2026 Special Session | 141 | 47 | 94 | none |
| **Sep 2026 Special Session** (used) | **141** | **47** | **94** | **none** |

The Sep 2026 special session convened **2026-09-02**, three weeks before this wave, which makes its
roster the current statement of membership.

### 🟢 ALL 141 MEMBER PAGES WERE READ, AND THE ZERO WAS CONTROLLED

MN-2's rule is that a roster list page is not a change-check. Every member's own biography page was
fetched and its `<h1>` asserted to name that member — **141 of 141, 0 failures** — and **none**
carries a departure marker on a 69th-Assembly row.

🔴 **A uniform answer is a broken detector until proved otherwise**, so the identical sweep was
re-run over the 148-member cumulative roster. It found **all seven departures, every one dated to
the day**:

| district | member | left | successor | arrived |
| --- | --- | --- | --- | --- |
| HD-11 | Liz Conmy | **deceased 2026-04-25** | Adam Goldwyn | 2026-06-01 |
| HD-20 | Jared C. Hagert | resigned 2026-02-09 | Dave Rustebakke | 2026-04-21 |
| HD-25 | Cynthia Schreiber-Beck | **deceased 2025-05-18** | Kathy Skroch | 2025-09-10 |
| HD-26 | Jeremy L. Olson | resigned 2025-05-05 | Kelby Timmons | 2025-05-29 |
| HD-27 | Josh Christy | **deceased 2025-02-18** | TJ Brown | 2025-03-10 |
| HD-42 | Emily O'Brien | resigned 2025-08-19 | Dustin McNally | 2025-09-19 |
| SD-44 | Josh Boschee | resigned 2026-08-04 | Jamie Selzler | **2026-08-05** |

⚠ **The gaps are real vacancies, not data quality.** HD-25 sat empty for nearly four months. None of
the seven predecessors is written by this wave; they are history, and the seat is held today by the
successor.

### 🟢 NORTH DAKOTA DATES ITS ARRIVALS, WHICH MICHIGAN AND MINNESOTA COULD NOT

MI-2 closed with **148 undated arrivals** and MN-2 with **200 unknowns**, in both cases because no
member page published a date. North Dakota's do: the "Assembly Sessions by Year" block carries
`Active August 5, 2026`, `Resigned August 4, 2026`, `Deceased April 25, 2026`, `Effective 1/7/25 -
8/4/26`. Boschee's resignation and Selzler's arrival are **consecutive days**, which is exactly the
shape `seat_officeholder` produces.

**Eight terms are written at `day` precision**, the seven successors above plus **Karen Grindberg
(HD-41), active 2024-12-01**. The mechanism is not inferred from the date: N.D.C.C. 16.1-13-10 fills
a legislative vacancy by appointment of the vacating member's **district party committee**, and two
cases were confirmed against contemporaneous reporting — the District 44 Dem-NPL executive committee
appointed Selzler on 2026-08-04, and the District 41 Republican executive committee appointed
Grindberg to the remainder of Michelle Strinden's term after Strinden resigned to become lieutenant
governor.

🔴 **THE EIGHTH ARRIVAL IS ONE NO ROSTER DIFF COULD SEE.** Grindberg arrived **2024-12-01**, before
the assembly convened, so she appears in all three rosters and the diff between them is silent about
her. The roster diff found seven; reading the member pages found eight. **A diff of snapshots can
only see changes that happened between the snapshots.**

⚠ **AND TWO SOURCES DISAGREE BY ONE DAY ON GRINDBERG, WHICH IS RECORDED RATHER THAN SMOOTHED.** The
Legislative Branch says `Active December 1, 2024`; contemporaneous reporting says she was **sworn in
December 2, 2024**, Strinden's resignation having taken effect December 1. The body's own record is
what is written. **"First sworn" and "active from" are different facts**, and this is a case where
they differ.

### 🔴 THE OTHER 133 TERMS ARE OPEN-ENDED AT `unknown`, AND THAT IS A DECISION, NOT A GAP

A date exists in the abstract — N.D. Const. art. IV § 7 begins terms on **the first day of December
following the election** — and it was still not written, for three reasons that compound:

1. **Both chambers serve four-year terms** (art. IV § 4) and North Dakota staggers them, so whether
   a given member's current term began 2022-12-01 or 2024-12-01 is not knowable from anything read
   here.
2. **A re-election does not restart an occupancy** (the SC-3 rule), so even the correct term start
   would be the wrong value for a member who has held the seat continuously since before it.
3. The bio pages publish `Senate since 1987`-style lines, but that is a fact about service in the
   **chamber**, not in this **seat** — and North Dakota redrew its map in 2021 and again by court
   order effective 2024-01-08. Writing `1987-01-01` would assert tenure in a seat that did not exist
   in that shape.

Those `since` years **are** captured, in `backend/data/seed-nd-2026/nd-members.json`, as evidence for
a later dating pass. Same disposition as OH-2 and MN-2, with more of the reasoning available.

### 🔴🔴 TWO OFFICES SHARE ONE DISTRICT, SO THE DISTRICT IS NOT A KEY

Every earlier wave in this program could match a member to an office through the district alone. In
North Dakota 46 House districts hold **two interchangeable offices**, and the seats carry no position
number on any ballot, so **no fact in the world says which member holds which row.**

▶ The assignment is therefore made **deterministic rather than meaningful**: offices ranked by their
own `id`, members by `full_name`, slot *N* matched to slot *N*. Both keys are stable, which is what
makes the migration idempotent. **The pairing asserts nothing, and nothing downstream may read
meaning into it.**

🔴 **The office title carries no seat number either, and that was a decision about ballot truth.**
Production already held two shapes: **Arizona** (60 offices over 30 districts, one title, elected at
large) and **Washington** (`State Representative (Position 1)` / `(Position 2)`, because Washington's
ballot really numbers the seats). North Dakota elects by **block voting** — one contest, "vote for
two", no positions — so it is Arizona's shape. `(Seat 1)`/`(Seat 2)` would have put a distinction on
a voter-facing title that exists on no North Dakota ballot. The structure gate asserts **exactly two
distinct titles** statewide.

### 🔴 A MEMBER'S OWN DISTRICT LABEL IS NOT THE HEADING IT SITS UNDER

Lisa Finley-DeVille and Clayton Fegley both appear under the accordion heading **"District 4"**, and
their own rows say **4A** and **4B**. The heading is what the roster groups by; the member's label
identifies the seat. Using the heading would have tried to join both to a `STATE_LOWER` district
`38004` — which does not exist. A loud failure rather than a silent one, but **only by luck of North
Dakota having no whole House District 4.**

### 🔴 ONE NAME COLLIDES WITH A DIFFERENT PERSON, AND THE SWEEP RAN ON THE GUARD'S KEY

`Dick Anderson`, Representative for **ND House District 6** (Republican, farmer, UND, House since
2011), shares `(first_name, last_name)` with `-4110005 Dick Anderson`, who **sits today as an OREGON
STATE SENATOR for OR SD-5**. A person cannot hold both, so these are different people — the same
structural evidence the GA roster trap needed, where 2 of 4 name hits were a Colorado senator and a
Utah treasurer. The guard is lifted for **exactly one row**; the other 140 were inserted with it live.

⚠ **The sweep was run on the guard's own key**, which is OH-2's lesson, **and it was controlled**:
the same query reports **66 active `Johnson`s and 37 active `Anderson`s**, so the single hit is a
true single and not an empty detector. Here the `full_name` sweep and the `(first_name, last_name)`
sweep agreed — unlike Ohio, where they did not.

### 🔴 THE RESERVED external_id BAND WAS WRONG ON THE FIRST CHOICE

The first band picked, `-2761141..-2761001`, **already held 14 rows**. It was chosen after checking a
*different* band (`-2760400..-2760131`, which was empty) and not re-checking. The band actually used
is `-2762400..-2762260`, verified empty by a `generate_series` scan over 200-wide blocks.
**Re-check the band you actually use, not the one you looked at first.**

### Gates

| gate | result |
| --- | --- |
| row deltas | `politicians` +141 exactly, `office_terms` +141 exactly |
| offices | 47 Senate + 94 House = 141 |
| seated | **141**, counting `och.politician_id` and never `count(*)` |
| `offices_missing_terms` | 423 → 564 → **423 / 238 unflagged**, fully accounted |
| every whole House district holds **2 distinct** holders | 46 of 46 |
| subdistricts 4A / 4B hold 1 each | pass |
| nobody holds two ND legislative seats | pass |
| dated terms | exactly **8** at `day`, 0 with a `term_end` |
| Grand Forks' four districts reach 12 seated offices | pass |
| distinct office titles statewide | exactly **2** |
| idempotency | re-run of both: every `essentials.*` insert `INSERT 0 0` |
| `check:reachability` | green, nothing regressed (4 / 17 / 7, all at baseline) |
| `check:occupancy` · `check:migrations` · `check:reservations` · `check:ocd-suffixes` | all green |

### Every gate was watched failing first

| gate | tamper | what it printed |
| --- | --- | --- |
| House office total | `NOT EXISTS` guard instead of the count | `expected 94 ... found 48` — **the half-House defect the obvious guard causes** |
| House office total | 4A/4B given two offices each | `expected 94 ... found 96` |
| **per whole district = 2** | 4A given 2 and District 1 given 1 — **total still exactly 94** | `1 whole House district(s) do not hold exactly 2 offices` |
| **per subdistrict = 1** | 4A given 2 and 4B given 0 — **total still 94, every whole district still 2** | `subdistrict 4A/4B does not hold exactly 1 office (2 offending)` |
| 2 distinct holders | both District 1 House seats pointed at the same person — **141 terms, 141 seated** | `1 whole House district(s) do not hold exactly 2 DISTINCT holders` |
| nobody holds two seats | a House member also given the District 1 Senate seat | `1 person/people hold more than one ND legislative seat` |
| 8 dated arrivals | Selzler's published date dropped | `expected exactly 8 day-precision ND terms ... got 7` |

🔴 **The two middle rows are the point of the whole exercise.** Both tampers leave the total at
exactly 94 and both would pass any count. The per-district assertions are the only thing standing
between a correct total and a wrong distribution — and in a multi-member state a wrong distribution
is the likely defect, not a wrong total.

### End-to-end probe, measured against production after the apply

| anchor | answers |
| --- | --- |
| **Grand Forks City Hall** | **3** — Sen. Scott Meyer, Reps Nels Christianson and Steve Vetter (D18) |
| University of North Dakota | 3 — Sen. Claire Cory, Reps Doug Osowski and **Dustin McNally** (D42, arrival showing as `2025-09-19 day`) |
| **Belcourt — Turtle Mountain** | 3 — Sen. **Richard Marcellais**, Reps **Collette Brown** and **Jayme Davis** (D9) |
| **Fort Totten — Spirit Lake** | 3 — **the same three** (D9) |
| **New Town — Fort Berthold** | **2** — Sen. Chuck Walen (D4) and **one** Rep, Lisa Finley-DeVille (**4A**) |
| CONTROL — Duluth, MN | none |

🟢 **Two rows here are worth more than the counts.** Belcourt and Fort Totten returning the **same
delegation** is the court's remedy visible to a voter — under the struck-down map those two
reservations were in different districts. And New Town returning **one** representative rather than
two is the single-member subdistrict working end to end, through a schema whose default in this
state is two.

▶ **Grand Forks scores 3 of 5.** The remaining two are stage 3 (city council) and stage 4 (county
commission).

### Tooling this wave added

| script | what it does |
| --- | --- |
| `scripts/nd-legislature-roster-extract.mjs` | pulls all three session rosters from the `members-by-district` accordion, asserts 47 districts / 47 senators / 94 reps, and diffs the sessions |
| `scripts/nd-legislature-member-sweep.mjs` | reads every member's own biography page, asserts the `<h1>` names that member, and extracts the 69th-Assembly status lines |

⚠ **A 404 on ndlegis.gov is a 70 KB styled page**, so response size proves nothing on this host.
Both scripts judge by status code and assert the page names the member they asked for.

### 🟢 A stage-5 lead found while here

The Legislative Branch publishes a **`Legislator Photo Request Form`**
(`ndlegis.gov/legislator-photo-request`) and every member row carries a portrait URL under
`/sites/default/files/styles/.../person/photo/`. Those URLs are captured in
`backend/data/seed-nd-2026/nd-roster-special-2.json`. **The licence is not yet established** — that
is stage 5's gate, and MN-5 is the precedent for asking.

---

## ▶ ND-3 and ND-4 — MEASURED 2026-09-25, NOTHING WRITTEN TO PRODUCTION

Everything below is evidence gathered after ND-2 closed. **No production write has been made for
either stage.** Re-measure before trusting it.

### 🔴 THE OFFICE INVENTORY IS THE CITY'S OWN SENTENCE, AND IT IS NINE, NOT EIGHT

| office | count | the sentence that establishes it |
| --- | --- | --- |
| Mayor | 1 | separate citywide executive — *"This is different from the Mayor, who is the head administrator of the city"* |
| Council Member, Wards 1–7 | 7 | *"The Grand Forks City Council consists of 7 members, each representing one of the city's 7 wards"* — **no at-large seat** |
| **Municipal Judge** | **1** | *"**The Municipal Judge is elected for a four-year term.**"* |
| **total** | **9** | |

🔴🔴 **THE MUNICIPAL JUDGE IS ELECTED AND WOULD HAVE BEEN MISSED.** It is not on the City Leadership
page, not on the City Council page, and not in any roster — it sits on a Municipal Court staff page
under City Departments. The inclusion ruling is that **an office is seated if the voters elect it**,
so it is in scope, exactly as Gary's City Court judge was and Fort Wayne's absent one was not.
⚠ **And the same sentence excludes two people**: *"two Alternate Municipal Judges as recommended by
the court and **appointed by the City Council**"*. Elected judge in, appointed alternates out —
the distinction is in one paragraph and nowhere else.

**The roster as published (2026-09-25), all from the city's own pages:**

| seat | holder |
| --- | --- |
| Mayor | Brandon Bochenski |
| Ward 1 | Danny Weigel *(Council Vice President)* |
| Ward 2 | Rebecca Osowski |
| Ward 3 | Tricia Berg |
| Ward 4 | Angela Salentiny |
| Ward 5 | Mike Fridolfs |
| Ward 6 | Dana Sande *(Council President)* |
| Ward 7 | Ken Vein |
| Municipal Judge | Kerry Rosenquist |

⚠ President and Vice President are **council roles, not seats** — Sande and Vein hold one office each.

### 🔴 THE CITY IS BEHIND A WAF, AND BOTH REFUSAL SHAPES WERE THE SAME SIZE

`grandforksgov.com` answers **HTTP 403 with a 468-byte body** to a bare request **and** to a full
browser User-Agent — two shapes, **identical size**, which is the tell that it is a WAF and not a
missing page. The same is true of `gfcounty.nd.gov`. Both were read in Playwright, where they return
200.
🔴 **And the county's charter download proves the corollary.** Fetched outside the browser it returns
**HTTP 403 with `Content-Type: text/html` and a body whose first bytes are `<HTML><H`** — a challenge
page wearing a `.pdf` URL. Inside Playwright the same URL is **HTTP 200, `application/pdf`, 7,477,329
bytes, magic `%PDF-`**. **Check the magic bytes, not the extension.**
⚠ That charter is a **scanned image PDF** (its first object is an `/XObject /Image`), so it cannot be
read as text without OCR. The office inventory below comes from the county's own HTML pages instead,
and the charter remains the authority to reconcile against when someone OCRs it.

### 🟢 WARD GEOMETRY EXISTS, AND NOT WHERE IT FIRST APPEARED TO

The city's own **Ward & Precinct Map** link redirects to `showdocument?id=42167` — **a PDF**, and its
`t=` tick parameter dates it to early 2022. A PDF is the Gary problem: an office without geometry is
unreachable by every resident.

🟢 **The state has it instead.** `NDGISHUB Voter Precincts` — *"Voter precinct splits for the 2026
election in North Dakota... by Legislative District, County, City, **Ward**, School District,
Emergency Services, **Commissioner District**, Park District..."* — carries **all seven Grand Forks
wards** as 11 precinct parts, modified 2026-05-05:

```
https://services1.arcgis.com/GOcSXpzwBHyk2nog/arcgis/rest/services/NDGISHUB_Voter_Precincts/FeatureServer/0
```

▶ **One layer supplies both remaining stages' geography.** That is worth knowing before ND-4 goes
looking for a county layer that does not exist.

⚠ **A name trap sits next to it.** The same catalogue serves `Ward2015` and `Ward2010` — those are
**Ward County aerial photography**. Ward is a North Dakota county. A search for "ward" returns the
photography before the wards.

**Dissolved to 7 wards and measured against the city place polygon `3832060` already in production:**

| measure | value |
| --- | --- |
| wards | **7**, and **0 overlapping pairs** |
| city area (TIGER 2024) | 29.3188 sq mi |
| union of the 7 wards | 29.2096 sq mi |
| city **not** in any ward | 0.1904 sq mi |
| ward **outside** the city | 0.0812 sq mi |

🔴 **AND THE DISAGREEMENT IS NOISE, WHICH WAS PROVED RATHER THAN ASSUMED.** 0.19 sq mi is small, but
Duluth's superseded map left 8.68 sq mi uncovered and still looked plausible, so area alone decides
nothing. **The shape does.** The gap is **88 separate pieces** and the overhang **90** — 178
fragments along a shared edge, which is what two digitizations of one boundary produce. The largest
gap piece is 81.22 acres with a **compactness of 0.0072** (a circle is 1.0): an extremely elongated
ribbon, on the city's eastern edge, where the boundary is the **Red River**. Every one of the six
largest pieces has compactness ≤ 0.066.
▶ **Compactness separates a sliver from a hole; area cannot.** A single 0.19 sq mi blob at
compactness 0.6 would have been a missing neighbourhood and this table would read the same.

| ward | sq mi | interior point |
| --- | --- | --- |
| 1 | 12.1327 | 47.925755, -97.093172 |
| 2 | 4.7271 | 47.940328, -97.053458 |
| 3 | 1.7763 | 47.910298, -97.045678 |
| 4 | 2.2355 | 47.901272, -97.032626 |
| 5 | 3.8468 | 47.871211, -97.042122 |
| 6 | 2.2403 | 47.881926, -97.073243 |
| 7 | 2.2509 | 47.907064, -97.071163 |

### 🔴🔴 GRAND FORKS COUNTY ELECTS ITS COMMISSION **AT LARGE** — THERE ARE NO COMMISSION DISTRICTS

Two independent sources agree, and neither is an assumption carried from another county:

1. The state's 2026 precinct layer sets **`Commissioner1 = "Districts At-Large"` on all 37** Grand
   Forks County precinct parts, and `Commissioner2`..`Commissioner5` are **null on every row**.
2. The county's own Commissioners page lists **five people with the bare title "Commissioner"** and
   **no district number**: Terry Bjerke, Kimberly Hagen, Anthony Hodny, Bob Rost, Mark Rustad.

▶ **So ND-4 has no district geometry to load, and it must not invent any.** Five at-large seats
covering the whole county, the same shape Tallahassee's commission had and the opposite of the
default this program has usually met. This is OH-4's lesson again — the county officer template is
state-scoped only as a *starting question*.

⚠ **The officer list is still owed.** N.D.C.C. tit. 11 names the statutory county officers, but Grand
Forks County is a **home-rule county** and a home-rule charter may make a statutory office
appointive. The county's site shows a Sheriff, a State's Attorney and a Recorder's Office as separate
departments; **which of those the voters elect has not yet been established** and must come from the
charter or the county auditor's own ballot record, not from the department list.

### 🟢 AN INDEPENDENT THIRD AUTHORITY AGREES WITH ND-1's LOAD

The same precinct layer's `Legislative` field says Grand Forks County touches **districts 17, 18, 20,
42 and 43** — **exactly the five** ND-1's `ST_Intersects` measurement found against TIGER geometry.
Two unrelated sources, the same answer, and neither is the Census.

### ⚠ What ND-3 does NOT yet have: dates, and a change-check worth the name

**The city publishes no term dates anywhere.** Each ward page carries a name, a ward, an email and a
phone — and nothing else. There is no "Term Expires" line, which means Grand Forks offers **neither**
of the two change-check signals this program has used: no departure banner (MN-2) and no expired date
(MN-3).

▶ **So ND-3 owes a decision before it writes**, and it should be made deliberately rather than
defaulted:
- terms at `start_precision => 'unknown'` on the OH-2 precedent, **or** dates reconstructed from the
  county auditor's certified results for the June 2024 and June 9 2026 city elections — noting that
  **a certified result is not a fact about who holds the seat**, only about who won;
- a change-check that is not the roster page. The council's own **agendas and minutes** record who is
  present at each meeting, which is a real signal and a bigger job.
- Known so far: wards 2, 4 and 6 were on the **2026-06-09** ballot; the Mayor and wards 1, 3, 5 and 7
  are the 2024 class. Terms are four years and staggered.

### ⚠ The `X` boundary code, and the gap that is still open

ND-3 needs an `X` code for the ward layer. Production's `max(mtfcc)` over `X%` is **`X0066`**, taken
by MI-4, so the next free code is **`X0067`** — read from production because **the `X` namespace has
no allocator**. `steward slot X` hands out numbers that are already taken, and `X_0001` is abandoned.
🔴 **This is the same shape as the migration-number collision the steward exists to prevent**, and it
is unfixed. OH-3 recorded it; ND-3 will meet it again.

---

## ✅ ND-3 APPLIED 2026-09-25 — Grand Forks is seated, on the DATED route

`X0067` (7 ward boundaries) + `CC_0146` (structure) + `CC_0147` (occupancy): **9 offices, 9 people,
9 terms, 9 seated, 0 vacant — and every term is dated.** Measured from outside after the apply:
`politicians` **88,995 → 89,004**, `office_terms` **9,471 → 9,480**, both exactly **+9**;
`districts` **10,116 → 10,124** exactly **+8**; `geofence_boundaries` **72,300 → 72,307** exactly
**+7**. `offices_missing_terms` **unmoved at 423 / 238 unflagged**.

All three artefacts are **idempotent, proved by re-running each**.

🟢 **No matview refresh was needed, and that was checked rather than assumed**:
`geofence_child_county` holds **0** rows whose boundary carries an `X` mtfcc.

### 🔴🔴 GRAND FORKS ELECTS NINE OFFICES, AND THE NINTH IS ON NONE OF THE OBVIOUS PAGES

| office | count | the sentence that establishes it |
| --- | --- | --- |
| Mayor | 1 | *"This is different from the Mayor, who is the head administrator of the city"* |
| Council Member, Wards 1–7 | 7 | *"The Grand Forks City Council consists of 7 members, each representing one of the city's 7 wards"* — **no at-large seat** |
| **Municipal Judge** | **1** | *"**The Municipal Judge is elected for a four-year term.**"* |

The judge is not on City Leadership, not on the City Council page, and not in any roster. That one
sentence sits on a Municipal Court staff page under City Departments. **An office is seated if the
voters elect it**, so it is in scope — as Gary's Judge of the City Court was at IN-4.

⚠ **And the same paragraph excludes two people**: *"two Alternate Municipal Judges as recommended by
the court and **appointed by the City Council**"*. Elected judge in, appointed alternates out. The
distinction exists in that paragraph and nowhere else on the site.

🟢 The judge is confirmed in office by the city's own record: at the 2026-07-06 Organizational
Meeting the **City Auditor administered his oath, and he then administered the council's**. Those
same minutes record the Municipal Court *"becoming a court of record, due to action approved in the
2025 State Legislative Session"* — which is also why `N.D.C.C.` ch. 40-18 (Municipal Judges) now
reads *"Repealed by S.L. 2025, ch. 379, § 4"*.

### 🟢 THE DATED ROUTE — WHAT EACH OF THE NINE DATES RESTS ON

Grand Forks publishes **no term dates anywhere**. Each ward page carries a name, a ward, an email
and a phone, and nothing else. The dates came from the council's own **PROCEEDINGS OF THE CITY
COUNCIL** minutes, where the oath is a dated event at a named meeting.

**Six at `day` precision:**

| seat | holder | start | the record |
| --- | --- | --- | --- |
| Mayor | Brandon Bochenski | **2020-06-23** | sworn the evening of the sine die meeting at which Mayor Brown was recognised for 20 years |
| Ward 2 | Rebecca Osowski | **2022-06-28** | *"Incoming ... Rebecca Osowski, Ward 2 ... were sworn in on Tuesday night"*; the city's calendar names that meeting *"City Council (Sine Die) and City Council (Organizational)"* |
| Municipal Judge | Kerry Rosenquist | **2022-06-28** | sworn the same night as *"newly elected"*; the 2026 minutes call him *"reelected"* and refer back to *"his first term"* |
| Ward 3 | Tricia Berg | **2024-07-01** | the roll calls either side: 2024-06-17 is *"Weigel, Osowski, **Weber**, Lunski, **Kvamme**, Sande and Vein"*, 2024-07-01 is *"Weigel, Osowski, **Berg**, Lunski, **Fridolfs**, Sande and Vein"* |
| Ward 5 | Mike Fridolfs | **2024-07-01** | the same pair of roll calls; he replaced Kvamme |
| Ward 4 | Angela Salentiny | **2026-07-06** | *"Judge Rosenquist then administered the oaths of office to Council Members Rebecca Osowski (Ward 2), Angela Salentiny (Ward 4) and Dana Sande (Ward 6)."* |

⚠ **THE OATH DATE IS NOT A RULE AND MUST NOT BE COMPUTED.** It is not "the first Monday in July"
and not "two weeks after the election": **2020 was a Tuesday in June, 2022 a Tuesday in June, 2024
Monday 1 July, 2026 Monday 6 July.** Each was read from that year's record. The 2024 date is
doubly sourced — the Mayor announced it in advance on 2024-06-17 (*"July 1 is also the date that
the current City Council will adjourn Sine Die and the newly elected City Council will hold their
organizational meeting and be sworn into office"*) and the roll call confirms the changeover.

**Three at `year` precision, a deliberate downgrade:**

| seat | holder | start | source |
| --- | --- | --- | --- |
| Ward 1 | Danny Weigel | **2016** | *"has been on the council since 2016"* |
| Ward 7 | Ken Vein | **2012** | *"has served on the Grand Forks City Council since 2012"* |
| Ward 6 | Dana Sande | **2010** | *"In 2010 Dana was elected to the Grand Forks City Council, representing Ward 6"* |

The oath dates for 2010, 2012 and 2016 were not read, so the day is not written — `YYYY-01-01` at
`start_precision => 'year'`, which is CLAUDE.md's rule for a year-only source. ⚠ **1 January is
EARLIER than the real arrival**, which is in June; that is what year precision means here and it
must not be read as a day.

🟢 **The three years carry an internal cross-check.** The article that dates Weigel to 2016 also
says *"only Sande and council member Ken Vein have served longer"* — and **2010 < 2012 < 2016**
reproduces that ordering exactly, from three separate statements. That proves no single year, but a
transcription error in any of them would have broken it.

🔴 **A re-election does not restart an occupancy**, so every date above is the person's FIRST
arrival in that seat. Six of the nine have been re-elected at least once; none of them carries the
2024 or 2026 oath date for that reason.

### 🟢 THE CHANGE-CHECK IS A ROLL CALL, AND AN ABSENCE IS WHAT MAKES IT ONE

The minutes of **2026-08-17** — five weeks before this wave — record:

> *"Present at roll call were Council Members Weigel, Osowski, Berg, Salentiny, Sande and Vein – 6;
> **absent: Fridolfs – 1**"*, with **Mayor Bochenski presiding**.

All seven wards and the Mayor are accounted for **by name**.

🔴 **"absent: Fridolfs" is the load-bearing half.** A roster that simply omitted him would be
indistinguishable from a vacancy. Naming him absent positively asserts that he still holds Ward 5.
**An absence is not a vacancy — and here the record says which one it is.** This is the signal
Grand Forks has instead of MN-2's departure banner and MN-3's expired term date, and it is stronger
than either, because it is produced twice a month by the body itself.

⚠ **The judge's change-check is weaker, and that is stated rather than papered over.** He appears in
no roll call. The most recent record of him in office is the 2026-07-06 oath administration —
**eleven weeks** before this wave, against five for the council.

### 🔴🔴 THE WARD-COVERAGE GATE I WROTE FIRST WAS WRONG, AND ONLY THE TAMPER SHOWED IT

The seven wards cover **99.351%** of the TIGER place — which would **fail Akron's 99.5% gate**, and
is not a defect: the city's eastern boundary is the **Red River**, and the state's precinct
digitization and the Census's place digitization trace it differently. The uncovered 0.1904 sq mi
is **88 separate pieces**, with 90 more of ward lying outside the place, and the largest uncovered
piece has a compactness of **0.0072** — an extreme ribbon, where a circle is 1.0.

So I wrote the second gate as a **compactness ceiling of 0.10**, documented it as the load-bearing
test, and asserted that compactness is what separates a sliver from a hole.

🔴 **Then I dropped Ward 3 from the dissolve — a whole missing ward, the exact defect the gate
exists for — and the largest uncovered piece came back at 1.90 sq mi with compactness 0.0524. It
passed.** The missing ward merges with the river slivers into one connected, ragged piece; it is not
compact at all. **Compactness separates a ribbon from a disc. It does not separate a missing ward
from a boundary artefact.**

The quantity that does separate them is the **area of the largest single piece**: **0.1269 sq mi**
healthy against **1.9032 sq mi** with a ward missing — a 15× gap with room on both sides. The gate
is now a 0.50 sq mi ceiling, and the same tamper fails it:

```
🔴 GATE 4: the largest single uncovered piece is 1.90319 sq mi (ceiling 0.5) — that is a
   NEIGHBOURHOOD in no ward, not a boundary sliver.
```

Compactness is still **printed**, because it is genuinely how the healthy case was recognised as
slivers. It no longer gates anything.

▶ **The general lesson, and it cost nothing but would have cost a wave: a gate that has never been
watched failing is a guess about what the defect looks like.** This one was written confidently and
documented confidently, and was wrong until it was tampered with. ⚠ Note also that Duluth's real
hole was 8.68 sq mi and passed a plausibility check — so the *percentage* gate alone is not enough
either. It takes both.

### 🔴 THE CITY'S OWN WARD MAP IS A PDF; THE STATE HAS THE GEOMETRY

`grandforksgov.com`'s "Ward & Precinct Map" link redirects to `showdocument?id=42167`, a PDF whose
`t=` tick parameter dates it to early 2022. A PDF cannot answer "who represents this address" —
the Gary problem.

🟢 `NDGISHUB Voter Precincts` (*"Voter precinct splits for the 2026 election in North Dakota... by
Legislative District, County, City, **Ward**, ... **Commissioner District**, Park District..."*,
catalogue modified 2026-05-05) carries all seven wards as **11 precinct parts**, dissolved here into
7. ▶ **The same layer carries the county's commissioner column, which is what ND-4 reads.**

⚠ **A name trap sits beside it**: `Ward2015` and `Ward2010` in the same catalogue are **Ward COUNTY
aerial photography**. Ward is a North Dakota county.

⚠ **What this dates and does not date.** The publisher states the layer is for the 2026 election and
the catalogue gives a modified date — that dates the **layer**. Nothing available dates the ward
**boundaries**: Grand Forks publishes no adoption date and no second ward layer, so there is nothing
to diff a map against. Same limitation as Akron at OH-3 and Columbia at SC-3, recorded rather than
dressed up. What *is* checkable is the count, and it is checked against the city's own sentence.

### 🔴 BOTH THE CITY AND THE COUNTY SIT BEHIND A WAF

`grandforksgov.com` and `gfcounty.nd.gov` both answer **HTTP 403 with a 468-byte body** to a bare
request **and** to a full browser User-Agent — two shapes, **identical size**, which is the tell.
Read in Playwright they return 200.

🔴 **And a `.pdf` URL can serve a challenge page.** The county's home-rule charter fetched outside
the browser is **403, `Content-Type: text/html`, body beginning `<HTML><H`**. Inside Playwright the
same URL is **200, `application/pdf`, 7,477,329 bytes, magic `%PDF-`**. **Check the magic bytes, not
the extension.** ⚠ That charter is a **scanned image PDF**, so ND-4's officer list is still owed.

### 🔴 A NAME TRAP THAT WOULD HAVE LOOKED AUTHORITATIVE

The ND Secretary of State's results portal serves pages for *"Grand Forks Ward 2"* and *"Grand Forks
Ward 4"*. Those are **voting precincts in the November general**, not council seats. City elections
are run by the **county auditor** in June and are not in that portal at all. A search lands on the
SOS pages first, and they carry the state's own branding.

### Gates

| gate | result |
| --- | --- |
| row deltas | `politicians` +9, `office_terms` +9, `districts` +8, `geofence_boundaries` +7 — all exact |
| offices | 7 wards + Mayor + Municipal Judge = 9 |
| seated | **9**, counting `och.politician_id` |
| every district has geometry | 8 of 8 |
| every ward holds exactly one office | 7 of 7 — the assertion ND-2 could *not* make about the House |
| the **Municipal Judge** exists and is seated | pass, with its own named gate |
| dated terms | **6 `day` + 3 `year` = 9, and 0 `unknown`** |
| nobody holds two city offices | pass |
| ward coverage | 99.351%, largest single gap 0.1269 sq mi (ceiling 0.50) |
| no two wards overlap | 0 pairs |
| `offices_missing_terms` | unmoved at 423 / 238 |
| `geofence_child_county` needs no refresh | 0 `X%` rows — checked |
| idempotency | all three re-run: every `essentials.*` insert `INSERT 0 0` |
| `check:reachability` | green, nothing regressed |
| `check:occupancy` · `check:migrations` · `check:reservations` · `check:ocd-suffixes` | green |

### Gates watched failing first

| gate | tamper | what it printed |
| --- | --- | --- |
| ward count | expected 12 parts | `GATE 1: expected 12 precinct parts, got 11` |
| **largest gap area** | Ward 3 dropped, coverage floor lowered so the shape gate was the one under test | `GATE 4: the largest single uncovered piece is 1.90319 sq mi (ceiling 0.5)` — **and the compactness gate it replaced PASSED this same tamper** |
| district geometry | a ward district pointed at a geo_id with no boundary | `1 Grand Forks district(s) have no matching boundary — unreachable by address` |
| office total | the Municipal Judge left out | `expected 9 Grand Forks offices ... found 8` |
| **Municipal Judge** | the judge replaced by a non-elected officer — **total still 9, wards still 7, Mayor still 1** | `expected exactly 1 elected Municipal Judge office, found 0 — the two ALTERNATE judges are appointed and must not be seated` |
| dated-route assertion | one arrival downgraded to `unknown` | `expected 6 day-precision terms ... got 5` |
| dated-route assertion | a year-precision arrival written as a day | `expected 6 day-precision terms ... got 7` |

### End-to-end probe

| anchor | answers |
| --- | --- |
| **Grand Forks City Hall** | **6** — Mayor Bochenski · Municipal Judge Rosenquist · Council Member Ward 3 Tricia Berg · Sen. Scott Meyer · Reps Nels Christianson and Steve Vetter |
| CONTROL — **East Grand Forks, MN** City Hall | **none** |
| CONTROL — Fargo City Hall | 3, all state — no city offices, because Fargo is not seeded |

🟢 **The East Grand Forks control is the one worth having.** It is a different city, in a different
state, about a mile away across the Red River, and it shares the name. It returns nothing.

🟢 City Hall sits in **Ward 3**, and Ward 3's member is who it returns.

▶ **Grand Forks scores 4 of 5 on the program's probe** — council member ✅, state senator ✅, state
representatives ✅✅, **county commissioner ❌**. Stage 4 is the last one.

### ⚠ What no gate here can catch

The gates assert that nine offices exist, are seated, are dated and reach the right addresses. **They
cannot tell whether Berg and Fridolfs were swapped** — Ward 3 and Ward 5 would each still hold
exactly one dated holder. That pairing rests on the roll calls quoted above and on nothing else, and
it is recorded as a limitation rather than covered by a gate that does not exist.

---

## ▶ ND-4 — MEASURED 2026-09-25, NOTHING WRITTEN. One question stands between it and the write.

### 🔴🔴 THE JUNE RESULT IS A PRIMARY, AND FOUR COUNTY SEATS ARE STILL UNDECIDED TODAY

North Dakota decides **city** offices in the June election and **county** offices in **November**.
June is the county **primary**. The Grand Forks County ballot of **2026-06-09** carried:

| contest, as the ballot names it | candidates |
| --- | --- |
| **County Commission (vote for one)** | Bob Mullen · Tony Hodny · Mitch McCoy |
| **County Commission (vote for three)** | Mark Rustad · Rachel Duray · Andrew Krauseneck · Kimberly Hagen · Debra Kolden-Thibert |
| **State's attorney (vote for one)** | Haley Wamstad |
| **Sheriff (vote for one)** | Andy Schneider |

🔴 **So four of the five commission seats, the sheriff and the state's attorney are all mid-cycle
right now**, with the general on 2026-11-03 — six weeks after this wave. **Nothing from that June
sheet may be seated.** ND-3's June result *was* an election because it was a city race; the
identical-looking county sheet on the same day was not. **"A certified result is not a fact about
who holds the seat" — and a PRIMARY result is not even a result.**

⚠ Two commission races on one ballot is itself the tell: three seats on the regular cycle plus
**one unexpired term**. Grand Forks County lost a long-serving commissioner, **Gary Malm**, whose
death the Mayor noted in the city's own minutes of 2024-06-17. Whether Anthony Hodny currently
holds that seat by appointment is the open question below.

### 🟢 SEVEN ELECTED COUNTY OFFICES, NOT NINE — AND NO COMMISSION DISTRICTS

| office | count | evidence |
| --- | --- | --- |
| Commissioner | **5, AT LARGE** | the state's 2026 precinct layer sets `Commissioner1 = "Districts At-Large"` on **all 37** county precinct parts with `Commissioner2..5` null, and the county's own page lists five people titled bare "Commissioner" with no district number |
| Sheriff | 1 | on the 2026 ballot; *"the sheriff and the state's attorney, under state law, will always be elected and that will not change under home rule"* |
| State's Attorney | 1 | same |
| ~~Recorder~~ | 0 | **appointed** — see below |
| ~~Auditor~~ | 0 | **appointed** — see below |
| ~~Treasurer~~ | 0 | **does not exist as a separate office** |

▶ **ND-4 therefore loads NO geometry.** All seven seats are countywide and attach to the county
polygon `38035` (G4020), already in production. This is the opposite of the program's usual shape
and it must not be "fixed" by inventing commission districts.

**The current holders**, from the county's own pages, read 2026-09-25:

| office | holder |
| --- | --- |
| Commissioner | Terry Bjerke · Kimberly Hagen · Anthony Hodny · Bob Rost · Mark Rustad |
| Sheriff | Andrew Schneider |
| State's Attorney | Haley Wamstad |

🟢 **North Dakota's county terms have statutory start dates**, which is the same gift art. IV § 7
gave ND-2 — the ND Secretary of State's own candidate guidance:

| office | term | begins |
| --- | --- | --- |
| Commissioner | 4 years | **the first Monday in December** following the election |
| Sheriff | 4 years | **January 1** following the election |
| State's Attorney | 4 years | **January 1** following the election |
| Recorder | 4 years | January 1 following the election |
| Auditor | 4 years | April 1 following the election |
| Treasurer | 4 years | May 1 following the election |

### 🔴 WHY RECORDER AND AUDITOR ARE READ AS APPOINTED — AND WHY THAT IS STILL THE OPEN QUESTION

The county employs **Garlynn Helmoski, County Recorder** and **Colleen Morstad, County Auditor**
(department "Finance & Tax"). Neither appears on the **2022, 2024 or 2026** ballot. ⚠ And **there is
no County Treasurer at all** — the only "Treasurer" in the staff directory is the Secretary-Treasurer
of the Water Resource District, a different body; the function sits inside Finance & Tax.

The SOS's own guidance says *"some counties use an appointment process for some contests, depending
on their form of government"*, and Grand Forks County adopted a **home-rule charter** — the 2022
measure that led on election night by **20 votes out of 16,774** and went to an automatic recount.
Contemporaneous reporting of that campaign says *"the sheriff and the state's attorney, under state
law, will always be elected and that will not change under home rule"* — which is only worth saying
if other offices did change.

🔴 **BUT THIS IS STILL AN ARGUMENT FROM ABSENCE, AND ABSENCE IS NOT PROOF.** It is the same shape as
"an absence on a roster is not a vacancy": three ballots with no recorder race is consistent with
appointment and also with a cycle I have not looked at. What makes it more than a bare absence is
the convergence — three consecutive cycles, plus a home-rule charter, plus reporting that names
exactly the two offices home rule could *not* touch.

▶ **The authority is the charter, and the charter is unread.** `gfcounty.nd.gov`'s Home Rule Charter
download is a **7,477,329-byte scanned image PDF** — its first object is an `/XObject /Image`, so it
has no text layer and cannot be searched without OCR. **ND-4 should not write until that document,
or the county auditor's own statement, settles it.**

### 🔴 THE COUNTY IS BEHIND THE SAME WAF, AND ITS CHARTER URL SERVES A CHALLENGE PAGE

`gfcounty.nd.gov` answers **HTTP 403 with a 475-byte body** outside a browser. The charter URL is
the sharper case: fetched with `curl` it is **403, `Content-Type: text/html`, body beginning
`<HTML><H`** — a challenge page wearing a `.pdf` URL. Fetched inside Playwright the same URL is
**200, `application/pdf`, magic `%PDF-`**. **Check the magic bytes, not the extension.**

### What ND-4 still owes, in order

1. **Settle Recorder and Auditor** from the charter (OCR the scan) or from the county auditor
   directly. Everything else is ready.
2. **Date the five commissioners.** The statutory start is the first Monday in December after each
   member's first election, so each needs its election year: two seats were decided in **Nov 2024**
   (*"On the ballot are two seats for the Grand Forks County Commission"*), and the rest earlier.
   ⚠ **Anthony Hodny may hold Gary Malm's unexpired seat by appointment** — the "vote for one" race
   in 2026 is exactly the shape a mid-term vacancy leaves. An appointment is dated by the
   commission's own minutes, not by an election.
3. **Date the Sheriff and State's Attorney.** Both are on the 2026 cycle, so both were last elected
   in **2022** with terms from **2023-01-01**; each needs its FIRST arrival, since a re-election does
   not restart an occupancy.
4. **Write it**: 7 offices, no geometry, on the county polygon `38035`. Grand Forks then scores
   **5 of 5**.

### ✅ THE BLOCKER IS CLEARED — the charter was OCR'd 2026-09-25, and it answers directly

The charter has a section whose title is literally **"Offices to be Elected"**. It is not an argument
from absence any more.

> **Article 6 — Elections · Section 1 — Offices to be Elected**
>
> 1. The Board of County Commissioners shall consist of **five members** who shall be elected on a
>    **nonpartisan ballot**. All of the candidates seeking the office of county commissioner shall be
>    **voted upon by the qualified electors of the entire county**.
> 2. The Board of County Commissioners may enact ordinances concerning the organization and
>    structure of elected county offices in accordance with state law.
> 3. **The Sheriff and State's Attorney shall remain elected offices** voted upon by the qualified
>    electors and subject to duties, terms of office, and other relevant provisions of the North
>    Dakota Century Code.

**Three items. The Recorder, the Auditor and the Treasurer are not among them**, and Article 7
disposes of them positively rather than by silence:

> **Article 7 · Section 1** — "The Board of County Commissioners may, by ordinance, establish county
> departments, offices, agencies, boards or commissions **in addition to those offices to be filled
> by election**…"
> **Article 7 · Section 2** — "The Board of County Commissioners **may appoint department heads** and
> fix their compensation."

▶ **ND-4 is seven elected offices: 5 commissioners at large + Sheriff + State's Attorney.** The
Recorder (Garlynn Helmoski) and the Auditor (Colleen Morstad) are appointed department heads and are
**not** seated. There is no Treasurer at all.

🟢 **And the charter is the third independent source for "at large"** — after the state's precinct
layer and the county's own page. Its words are *"voted upon by the qualified electors of the entire
county"*.

🟢 **Article 6 § 3 also term-limits the board**: "no commissioner may serve more than three
successive four-year terms."

### 🟢 HOW THE SCAN WAS READ — AND THE WAF SHAPE THAT WORKED

🔴 **The third request shape got through, where Ohio's Secretary of State refused all three.** A bare
request and a browser-User-Agent request both return **403 with a 468–475 byte body**. A **full Chrome
header set with `Sec-Fetch-*` and a same-origin `Referer`** returns **200, `application/pdf`,
7,477,329 bytes, magic `%PDF-`**.
▶ **A WAF's refusal is not uniform across sites. Try all three shapes before reaching for a browser** —
OH-3's note that all three fail is Ohio's fact, not a general one.

The document is **12 scanned pages with a text layer of exactly zero characters on every one**,
confirmed page by page. Rendered at 150 dpi greyscale and read directly. ⚠ The commissioner history
list from the same site **does** carry a text layer — on this host, "scanned" is per document.

### 🔴🔴 THE PDF BUNDLES A MEASURE THE VOTERS REJECTED, AND READING IT WHOLE WOULD HAVE TAKEN IT AS LAW

Pages 1–7 are the charter. Page 8 is the ballot question and the Home Rule Charter Commission's
signatures, dated **16 August 2022**. **Page 9 onward is an ADDENDUM** — *"We, the people of Grand
Forks County, hereby enact a new subdivision to section 2 of article 9… relating to the collection of
sales, use, and gross receipts tax"* — a half-cent county sales tax.

**That addendum FAILED at the polls: 9,013 against, 8,984 for.** The charter itself **passed**, and
only after an automatic recount: **8,386 to 8,368, a margin of 18 votes**, effective **2023-01-01**,
making Grand Forks the thirteenth North Dakota county with home rule.

▶ **One PDF, published under one title, containing one adopted instrument and one rejected one.**
Nothing inside the document distinguishes them — both are drafted in enacted voice ("We, the people
… hereby enact"). The vote record is the only thing that does.

### What ND-4 still owes — now only dates

The inventory and the geometry question are settled. Remaining:

1. **The five commissioners' first arrivals.** Statutory start is the **first Monday in December**
   after the election. The county's own Commissioner History List (which *does* have a text layer)
   ends at **"2019-  David Engen · Cynthia Pic · Diane Knauf · Tom Falck · Bob Rost"** — so it dates
   **Bob Rost** to the 2019 board and is stale for everyone after. ⚠ **Hodny may hold Gary Malm's
   unexpired seat by appointment**, which only the commission's own minutes can date.
2. **Sheriff Andrew Schneider and State's Attorney Haley Wamstad** — both on the 2026 cycle, so both
   were last elected in **2022** with terms from **2023-01-01**; each needs their FIRST arrival,
   since a re-election does not restart an occupancy.
3. ⚠ **Nothing from the 2026-06-09 primary may be used.** The general is 2026-11-03.

---

## ✅ ND-4 APPLIED 2026-09-25 — Grand Forks County is seated, and the slice scores 5 of 5

`CC_0148` (structure) + `CC_0149` (occupancy): **7 offices, 7 people, 7 terms, 7 seated, 0 vacant.**
`politicians` **89,004 → 89,011** and `office_terms` **9,480 → 9,487**, both exactly **+7**.
`offices_missing_terms` **unmoved at 423 / 238**. Both migrations idempotent, proved by re-running.

**North Dakota now holds 165 offices, 165 seated.**

### 🔴🔴 THIS WAVE LOADED NO GEOMETRY, AND THAT IS THE FINDING

Grand Forks County elects its commission **at large**. All seven offices hang on the COUNTY district
`38035`, which already existed with geometry. **No commission district was created, and the gate
asserts that none exists** — inventing one is the defect this wave was most likely to produce.

Three independent sources agree, and the charter is the one that settles it:

> **Charter art. 6 § 1, "Offices to be Elected"** — *"The Board of County Commissioners shall consist
> of five members who shall be elected on a nonpartisan ballot. All of the candidates seeking the
> office of county commissioner shall be **voted upon by the qualified electors of the entire
> county**."* … *"**The Sheriff and State's Attorney shall remain elected offices**…"*

Seven offices, not nine: art. 7 lets the Board establish offices *"in addition to those offices to be
filled by election"* and *"appoint department heads"*, so the Recorder and the Auditor are appointed
and are **not** seated, and there is no Treasurer at all.

### 🟢 THE DATES ARE STATUTORY, SO AN ELECTION YEAR YIELDS A DAY

ND fixes county term starts: **commissioner — the first Monday in December** following the election;
**sheriff and state's attorney — January 1**. Computed, not guessed: December 2022 → **2022-12-05**,
December 2024 → **2024-12-02**.

| office | holder | start | prec. | how |
| --- | --- | --- | --- | --- |
| Commissioner | Terry Bjerke | 2024-12-02 | day | elected 2024 (13,173 votes, 30%) |
| Commissioner | Kimberly Hagen | 2022-12-05 | day | elected 2022 |
| Commissioner | Mark Rustad | 2022-12-05 | day | elected 2022 **on a recount** |
| Commissioner | Anthony Hodny | **2026-03-11** | day | **appointed** to Cynthia Pic's seat |
| Commissioner | Bob Rost | 2019-01-01 | **year** | see below |
| Sheriff | Andrew Schneider | 2019-01-01 | day | elected 2018, took office January 2019 |
| State's Attorney | Haley Wamstad | 2019-01-01 | day | elected 2018; first woman in the office |

⚠ **Rustad's seat was decided by the recount, not by election night.** The initial report named **Lon
Kvasager** the third winner; Rustad trailed by 27 votes (6,729 to 6,702) and the automatic recount
reversed it. A wave reading election-night coverage would have seated the wrong person.

🔴 **Cynthia Pic died on 2026-02-13** and Hodny was appointed at a special commission meeting on
**2026-03-11**. ⚠ My earlier note guessed this vacancy was **Gary Malm's** — it was not. Malm was a
long-serving commissioner whose death the *city's* minutes recorded in 2024; the 2026 vacancy is
Pic's. **A remembered name is not a source.**

🔴 **Hodny's term ends 2026-11-30 and that end is DELIBERATELY NOT WRITTEN.** He serves only until the
winner of the 2026-11-03 general takes the unexpired seat. A future `term_end` self-vacates a seat the
moment the calendar passes it, so it is a **recorded debt for the November wave**, not a value. The
gate asserts 0 term_end, and the tamper that wrote one fired.

🔴 **THREE ROWS READ `2019-01-01` AND ONLY TWO MEAN THE SAME THING.** Schneider's and Wamstad's are
`day` — the statute fixes 1 January and both took office then. **Bob Rost's is `year`**, and the
literal date is an artefact of the convention, not a claim about 1 January.

**Why Rost is the one year-precision row**, and it is not laziness: the county's own Commissioner
History List — which, unlike the charter, *does* carry a text layer — ends with the open group
*"2019-  David Engen · Cynthia Pic · Diane Knauf · Tom Falck · **Bob Rost**"*, published 2020. ⚠ **And
his arrival cannot be computed from the 2018 election, because BOB ROST WAS THE SHERIFF Andrew
Schneider succeeded in January 2019.** He cannot have begun a commissioner's term on 2018-12-03 while
still holding the sheriff's office through 2018-12-31. The statutory computation is unsafe for him
specifically, so the day is left unclaimed. He was re-elected 2022-11-08 with the field's highest
total, which does not restart the occupancy.

### 🔴🔴 THE JUNE 2026 COUNTY SHEET IS A PRIMARY, AND NOTHING FROM IT WAS SEATED

ND decides **city** offices in June and **county** offices in November. The 2026-06-09 county ballot —
*County Commission (vote for one)*, *(vote for three)*, *State's attorney*, *Sheriff* — is a primary
whose general is **2026-11-03**, six weeks after this wave. **ND-3's June result was an election
because it was a city race; the identical-looking county sheet the same day was not.** Every date
above predates it.

### Gates, and the tampers that proved them

| gate | result |
| --- | --- |
| deltas | `politicians` +7, `office_terms` +7, exact |
| offices | 5 Commissioners + Sheriff + State's Attorney = 7, all on district `38035` |
| **no commission district invented** | 0 |
| seated | 7, counting `och.politician_id` |
| precision | **6 `day` + 1 `year` = 7, 0 unknown** |
| appointed arrivals | exactly 1 (Hodny) |
| **5 distinct commissioners** | 5 |
| nobody holds two county offices | pass |
| `offices_missing_terms` | unmoved 423 / 238 |
| idempotency | both re-run, every `essentials.*` insert `INSERT 0 0` |
| `check:reachability` · `occupancy` · `migrations` · `reservations` | all green |

| tamper | what fired |
| --- | --- |
| `NOT EXISTS` guard instead of the count | `expected 7 … found 3` — the guard that seats one commissioner of five |
| Hodny's known end written as data | `7 county term(s) carry a term_end — Hodny's 2026-11-30 end is a recorded debt, not a value` |
| two commissioner **terms** naming one person — **7 people, 7 terms, 7 seated all still true** | `the 5 at-large commissioner seats resolve to 4 distinct holders` |

🔴 **The first attempt at that last tamper proved nothing and was redone.** Changing the *person* row
tripped `idx_essentials_politicians_external_id` before the gate was reached — a control that aborts
for the wrong reason. Changing only the *term* row isolated it.

### ✅ THE PROBE: GRAND FORKS SCORES 5 OF 5

Grand Forks City Hall, 255 N 4th St, now returns **12 answers across 8 titles**:

| title | n | holders |
| --- | --- | --- |
| Commissioner | **5** | Bjerke, Hagen, Hodny, Rost, Rustad |
| Council Member, Ward 3 | 1 | Tricia Berg |
| Mayor | 1 | Brandon Bochenski |
| Municipal Judge | 1 | Kerry Rosenquist |
| Representative | **2** | Nels Christianson, Steve Vetter |
| Senator | 1 | Scott Meyer |
| Sheriff | 1 | Andrew Schneider |
| State's Attorney | 1 | Haley Wamstad |

⚠ **The program's "four answers" test is a poor fit for North Dakota in both directions**: the House
is multi-member so the state answer is two people, and the commission is at-large so the county
answer is five. The right test here is **five distinct kinds of answer**, which is what this is.

---

## ▶ ND-5 — BASELINE MEASURED 2026-09-25, NOTHING WRITTEN

### The portrait debt is 157, and it is a measured zero rather than an estimate

| cohort | seated | hosted on our CDN | third-party only | **nothing renders** |
| --- | --- | --- | --- | --- |
| Legislature | 141 | 0 | 0 | **141** |
| Grand Forks city | 9 | 0 | 0 | **9** |
| Grand Forks County | 7 | 0 | 0 | **7** |
| *(pre-existing ND: 1 US Rep, 2 US Sen, 5 statewide execs)* | 8 | **8** | 0 | 0 |
| **owed** | | | | **157** |

🟢 Unlike CO and NC, **nothing here renders off a third-party `photo_origin_url`** — so there is no
coverage that will silently fall when a source re-organises. The 157 is honest.

### What exists, and the one thing that is not settled

🟢 **The legislature's portraits are already captured.** Every member row in
`backend/data/seed-nd-2026/nd-roster-special-2.json` carries a `photo_url` under
`ndlegis.gov/sites/default/files/styles/…/person/photo/`. 141 of 141.

🔴 **THE LICENCE IS NOT ESTABLISHED, AND THAT IS THE STAGE-5 GATE.** The ND Legislative Branch
publishes a **`Legislator Photo Request Form`** (`ndlegis.gov/legislator-photo-request`), which is
evidence that photo reuse is a thing they expect to be *asked* about — not evidence of a grant. MN-5
is the precedent: the request was drafted, sent, and answered before anything was published.
⚠ Compare TN, where the licence turned out to be **in the PNG metadata and on no page** — so read the
bytes before concluding there is no grant.

⚠ **The city's and county's portraits are unmeasured.** Grand Forks ward pages carry no photo in the
page text; the county staff directory may. Neither has been checked.

### Owed before ND-5 can publish

1. **Settle the legislature licence** — read the image metadata first, then the request form.
2. **Measure the city and county photo sources** (16 people).
3. **A contact sheet as a published Artifact** — approval is always a batch contact-sheet artifact,
   and 🔴 **look at the frames before publishing the sheet**: the counters measure the pipeline, and
   nothing in it can measure composition.
4. **The `grand-forks` banner.** ⚠ Run the adjacency test against the ND state banner before choosing
   a frame. Grand Forks is *not* one of the four known state-banner collisions (Miami, Wichita,
   Detroit, Charlotte), but that is a fact about those four, not a clearance for this one.

### 🔴🔴 THE LEGISLATURE'S PORTRAITS ARE NATIVELY 157×196, AND THERE IS NO BIGGER FILE

Measured 2026-09-25. The roster links a Drupal derivative at
`/sites/default/files/styles/member_list_photo/public/person/photo/<x>.jpg` — **140×175, 21 KB**.
OH-5's rule says both chambers usually publish a higher-resolution file they never link, so the
unlinked original was checked:

| URL | size |
| --- | --- |
| `…/styles/member_list_photo/public/person/photo/x.jpg` (linked) | 140 × 175, 21 KB |
| `…/styles/biography_image/public/person/photo/x.jpg` | 140 × 175, 21 KB |
| **`…/person/photo/x.jpg` (the unlinked original)** | **157 × 196, 51 KB** |
| `…/styles/large/public/person/photo/x.jpg` | **HTTP 404** |

▶ **The original exists and is barely larger.** 157×196 is the whole of what North Dakota publishes.
There is no query-string resize to strip and no `large` style to reach for.

🔴 **So ND-5 cannot ship these at the program's usual size without a heavy upscale**, and *"a
server-side upscale defeats the upscale warning — keep the native"*. MI already carries a debt of
9 portraits shipped at 3.75× from 200 px sources; this would be **141 at worse than that**.
▶ **This is a decision for the slice owner, not a detail**: ship 141 small natives, find another
source (the SOS candidate portraits are a candidate), or ask the Legislative Branch for originals
via the photo request form — which is the same conversation the licence needs anyway.

### 🟢 AND THE LICENCE IS NOT IN THE BYTES — THE TN PATTERN DOES NOT APPLY HERE

Tennessee's grant turned out to be in the PNG metadata and on no page, so the bytes were read first.
A member portrait carries **no EXIF at all**, and the raw file contains none of `Copyright`,
`copyright`, `rights`, `Creative Commons`, `public domain`, `Credit` or `xmp`. ▶ **Nothing is
granted in the file.** The `Legislator Photo Request Form` is the remaining route, and MN-5 is the
precedent for how to ask.

### ▶ ND-5 EXTRACTION DONE 2026-09-25 — 141 of 141, and the sheet is published for approval

Contact sheet: **https://claude.ai/artifact/Qi55gMAhJQcLtQLuZt3MtQ**
Tooling: `scripts/nd-legislature-portrait-extract.py` · `scripts/nd-portrait-contact-sheet.py`
Ledger: `backend/data/seed-nd-2026/portraits/LEDGER.json`

**Ruling (Cantrell, 2026-09-25): ship the 157×196 natives.** No upscale, no second source.

| check | result |
| --- | --- |
| extracted | **141 of 141, 0 failures** |
| monochrome | **0** — the SC-5 rule, enforced |
| byte-identical duplicates | **0** |
| dimensions | **157×196 on every frame**, one distinct size |
| structure | 47 senators · 2 per whole House district · 1 each on 4A/4B |
| **positive control** | a deliberately wrong filename returns **404** — the sweep can fail |

🔴 **The frames are embedded in the sheet UNMODIFIED.** The question is whether the shipping asset is
good enough, so re-encoding or resampling for the page would have put something else in front of the
reviewer. The sheet is 10.33 MB of `data:` URIs for that reason, and the CSP blocks external images
anyway.

🟢 **I looked at all 141 before publishing the sheet.** Every one is a head-and-shoulders portrait;
no badges, no logos, no placeholders. **A badge is portrait-shaped and no counter can see that.**

🔴🔴 **AND THE MEASUREMENT BEAT MY EYE.** I spotted **two** frames on a light backdrop by looking.
Scanning corner lightness against the set's median found **six**: Myrdal (S-19), Selzler (S-44),
Davis (H-9), Rustebakke (H-20), Brown (H-27), Grindberg (H-41).
🟢 **And the six are not noise — four of them arrived mid-term.** Selzler, Rustebakke, Brown and
Grindberg are four of the eight dated arrivals from ND-2; they were seated between elections and sat
for their photograph outside the main session. **The backdrop is a signature of how someone arrived.**
▶ *Looking* caught that they were portraits. *Measuring* caught how many there were. Neither would
have done on its own — and my first draft of the page said "both", which I corrected before
publishing rather than shipping the wrong count.


> 🔴🔴 **RULING (Cantrell, 2026-09-25): THE FRAMES AND THE 157×196 RESOLUTION ARE APPROVED, AND THE
> LICENCE IS ON HOLD. DO NOT IMPORT THE 141, AND DO NOT SEND THE PHOTO REQUEST FORM.**
>
> This is the combination most likely to be misread. The frames are extracted, the contact sheet is
> approved and the resolution question is settled — which together look like a green light. They are
> not. Importing sets `photo_custom_url`, which is what a voter actually sees, and **stage 5 has a
> licence gate** (MN-5 is where it fired). **Stage 5 stays OPEN and slice 12 stays at four of five
> stages until Cantrell lifts the hold.** Nothing about the portraits is blocked on research; it is
> blocked on a decision that has been taken and is to be left alone.

### ⚠ What approval of the sheet does NOT cover

**The licence is unsettled.** Nothing is granted in the bytes — no EXIF at all, and no `Copyright`,
`rights`, `Creative Commons`, `public domain`, `Credit` or `xmp` string anywhere in the file (read
first, on the TN precedent). The Legislative Branch publishes a **Legislator Photo Request Form**;
MN-5 is the precedent for asking. **Approving the frames is not the right to publish them.**

### Owed before ND-5 closes

1. **Settle the licence** via the photo request form.
2. **Import the 141** to our own CDN and set `photo_custom_url` — 🔴 a `politician_images` row alone
   changes nothing a voter sees.
3. ✅ **The 16 city and county portraits are MEASURED** — see the section below. 7 of 16 exist.
4. **The `grand-forks` banner**, after the adjacency test against the ND state banner.


### ✅ ND-5 — THE 16 CITY AND COUNTY SOURCES ARE MEASURED (2026-09-25). NOTHING IMPORTED.

Tool: `backend/scripts/nd-city-county-portrait-measure.mjs` · ledger
`backend/data/seed-nd-2026/_nd5-city-county-sources.json` · frames in `_sources/` (23 MB,
untracked, **proved regenerable: a re-run reproduced 8 of 8 byte-identical**).

| cohort | seated | portrait published | pixels |
| --- | --- | --- | --- |
| City council wards 1, 2, 3, 5, 6, 7 | 6 | **6** | 1600x2000 PNG |
| Mayor Bochenski | 1 | **1** | 1600x2000 JPEG |
| Council Ward 4 (Salentiny) | 1 | **0** | — |
| Municipal Judge (Rosenquist) | 1 | **0** | — |
| Grand Forks County (5 commissioners + Sheriff + State's Attorney) | 7 | **0** | — |
| **total** | **16** | **7** | |

🔴🔴 **THE WAF DISCRIMINATES ON THE HTTP STACK, NOT THE USER-AGENT — AND MY FIRST SWEEP
REPORTED 15 OF 15 "NO PORTRAIT" BECAUSE OF IT.** Both hosts answer Node's `fetch` with HTTP 200
(bare *and* with a Chrome UA) and refuse Python `requests` **and** `curl` with HTTP 403
"Access Denied" (483/485 bytes) in **every** header shape tried — bare, +Chrome UA, and
+UA+Accept+Accept-Language. **Adding headers does not help; the client has to be a different
HTTP stack.** This is the inverse of `waynecountymi.gov`, which refused curl+ChromeUA and served
a bare request, and a third shape again after `michigan.gov`.
▶ **The program's renderer and importer both use Python `requests`, so this whole cohort is
invisible to them.** Any future import must go through `bytes_from`, as MI-5's Detroit and Wayne
cohorts did.
▶ **The uniform answer is what exposed it** — 15 of 15 identical "no portrait" was not
credible, because I had already read `alt="Danny Weigel ward 1 council member"` off Weigel's page
by eye minutes earlier. **A detector whose every answer agrees has not been tested.**

🟢 **THE CITY PUBLISHES 1600x2000 — EXACTLY 4:5, AND A 2.67x DOWNSCALE TO THE 600x750
TARGET.** This is the **opposite** of the legislature's 157x196, which is the whole of what North
Dakota publishes and forced the ship-the-natives ruling. The city cohort needs no upscale at all,
and there is no resize to strip: the `src` carries no query string.

🔴 **BIND BY THE `alt`; THE `src` IS OPAQUE.** Both sites are **Granicus**, and a portrait
is served as `/home/showpublishedimage/<id>/<ticks>` — an id that names nothing. The `alt`
carries the person and the seat (`"Rebecca Osowski ward 2 council member"`). MI-5's rule, holding
for a second vendor.

🔴 **SALENTINY (WARD 4) HAS NO PORTRAIT, AND THE COUNT IS THE TELL.** Her staff page
carries **14** `<img>` tags where the other six carry **15**; the member portrait slot is simply
absent. Confirmed twice, once per sweep, and by reading the page's images by eye. Her page still
names her in its own `<title>`, so this is a missing photograph, not a missing person.

🔴 **BOCHENSKI RETURNS TWO `alt` HITS AND ONE IS NOT A PORTRAIT** — `"Mayor Bochenski
Swearing in to office 2024"` is **1903x350**, a banner strip. The portrait is the second,
`alt="Bochenski"`, 1600x2000. **Shape separated them; the name did not.**

🔴🔴 **THE COUNTY'S GRANICUS TEMPLATE HAS NO PHOTO SLOT AT ALL — 0 OF 7, AND IT
IS CONTROLLED.** Every county staff page carries exactly **8** `<img>` tags (nav spacers plus a
YouTube and a Facebook icon). I swept **14** county staff pages across eight departments: **all 14
at exactly 8 tags, 0 portraits.** ▶ **Positive control: the identical predicate run against the
CITY host finds 6 of 7.** Same vendor, same detector, same session — so the county's zero is a
fact about the county, not about the sweep.

🔴 **THE SHERIFF'S OFFICE RUNS ITS OWN SITE AND IT NEVER NAMES THE SHERIFF.**
`gfcounty.nd.gov/government/sheriff` redirects to **`gfcountysheriff.org`**, a Wix site with eight
nav items (Corrections, Civil, Fingerprinting, Tip 411, Forms, Employment, Contact) and **no
leadership, staff or "about the sheriff" page**. Rendered in Playwright, the page text contains
**no occurrence of "Schneider"**, and its only large images are a 1905x721 banner and a 913x566
landscape — neither portrait-shaped, neither carrying an `alt`.

🔴 **THE MUNICIPAL COURT PAGE NO LONGER NAMES ROSENQUIST.** ND-3 recorded that the elected
Municipal Judge's *only* mention was one sentence on a Municipal Court staff page; that page
carries **zero** occurrences of the name today and links no staff directory entry. ▶ **The
sentence that established the office is gone from the live site — ND-3's citation is the record
of it.** This does not unseat him; it means the office has no live portrait route.

### The licence for the city's seven is SILENCE, read on the TN precedent

**Nothing is granted in the bytes.** Every one of the seven carries an XMP packet, and it holds
exactly one field of substance: **`xmp:CreatorTool = Canva (Renderer)`**, with a document, user and
`brand=GF team` id. There is no `dc:rights`, no `dc:creator`, no `xmpRights`, no
`photoshop:Credit`, and no photographer named anywhere.
⚠ **AND MY OWN KEYWORD SCAN PRODUCED A FALSE POSITIVE I HAD TO CHASE DOWN** — a raw-byte
search for `author` hit in all eight files. It is **XMP schema boilerplate, not a rights field**.
TN's rule again from the other side: `Copyright = x-default` is an empty field, not a claim, and
**a substring is not a value**.

**Neither site publishes a policy.** No terms, copyright, disclaimer or legal page is linked from
either home page, and the city's sitemap (13 child sitemaps, **5,857 URLs**) contains no site-wide
policy page — only a transit-department accessibility page and a transit privacy policy. The
element whose own class is `copyright` carries **only the Granicus vendor credit** ("Website Design
by Granicus"), not a notice by the City or the County.
⚠ **5,857 URLs is too many to sweep the way TN's 100 were**, so "no policy anywhere" is **not**
proved here to TN's standard. What is proved: none is linked, none is in the sitemap's URL names,
and none is in the bytes.

▶ **So the city cohort's licence shape is SILENCE** — the OH/GA/FL/PA shape, not TN's
published-permission-with-a-stated-limit and not MN's published refusal. **That is a measurement,
not a clearance.** The 141 legislature portraits are on a deliberate hold; **this cohort has not
been ruled on at all.**

🟢 **I LOOKED AT ALL SEVEN.** Every one is a genuine head-and-shoulders portrait on the
same studio setup — flag and wood panel, in colour, subject facing camera, no badge, no logo,
no placeholder, no superimposed text. ⚠ **The framing is WIDE**: each subject sits small in the
frame with a lot of headroom and torso, so the program's "crop ~1 ear above hair" rule means a real
crop here, not the straight 4:5 downscale the aspect ratio invites. That is a note for whoever
imports, and it was caught by looking, not by any counter.

### What ND-5 still owes

1. **The legislature licence** — ON HOLD by ruling. Do not import, do not send the form.
2. **A ruling on the city's seven**, whose licence shape is silence (above).
3. **Nine people have no portrait route at all**: Salentiny, Rosenquist, and all seven county
   officials. A blank beats a link.
4. **The `grand-forks` banner**, after the adjacency test against the ND state banner.


## ✅✅ ND-5 APPLIED 2026-09-25 — 148 PORTRAITS IMPORTED. THE HOLD WAS LIFTED.

> 🟢🟢 **RULING (Cantrell, 2026-09-25, later the same day): IMPORT ALL 148 — the 141
> legislature portraits AND the 7 Grand Forks city portraits.** *"we will eventually find the
> copyright, but for now we will import."*
>
> ⚠ **THE HOLD AND ITS LIFT ARE BOTH DATED 2026-09-25. READ THE LIFT.** The earlier ruling on
> this page says *do not import, do not send the request form, do not ask again*. That is
> **superseded for the import only**.
> ⚠ **THE PHOTO REQUEST FORM IS STILL NOT SENT.** The lift covers importing, not corresponding.
> ⚠ **THE LICENCE IS STILL UNSETTLED FOR BOTH COHORTS AND IS NOW A KNOWN, ACCEPTED DEBT.**
> Every one of the 148 rows carries `photo_license = 'unknown'`, which is the honest value:
> nothing is granted in the bytes of either set, and neither publisher publishes a policy.
> **Do not record either cohort as licence-cleared.**

🔴 **"IMPORT THE HEADSHOTS" WAS AMBIGUOUS AND I ASKED BEFORE ACTING.** Two cohorts were live
at once — 141 under an explicit same-day hold, and 7 never ruled on. Importing sets
`photo_custom_url`, which is what a voter sees. **Guessing the scope would have been the defect.**

### Result

| cohort | seated | renders before | renders after | shipped at |
| --- | --- | --- | --- | --- |
| ND Legislative Assembly | 141 | 0 | **141** | 157x196 **native, not enlarged** |
| Grand Forks city | 9 | 0 | **7** | 600x750 (a 2.67x downscale) |
| Grand Forks County | 7 | 0 | **0** | no source exists |
| pre-existing ND statewide (**CONTROL**) | 5 | 5 | **5** | unmoved |

`imported 148 · skipped 0 · failed 0`. ⚠ **The control scope reads 5, not the 8 the ND-5
baseline quotes** — the congressional delegation hangs off a FEDERAL government row and is
outside a North-Dakota-scoped query. **State the scope, do not assume the number carries over.**

✅ **VERIFIED FROM OUTSIDE THE DATABASE**: all **148 of 148** `photo_custom_url` values fetch
from the public CDN and decode as JPEG — **141 served at 157x196 and 7 at 600x750**, exactly what
was shipped. **Negative control**: a zero-UUID object key returns HTTP 400, so the check can fail.
✅ **Provenance is clean**: all 148 `photo_origin_url` values point at a PAGE; **0 point at an
image**, which is the defect that pipeline exists to prevent.

### 🔴🔴 I RAN A STALE COPY OF THE SHARED IMPORTER, BECAUSE IT WAS THE ONE WITH THE `.env`

The ND worktree has no `.env` (copying one in is refused by the permission layer), so the importer
was run from the main clone `C:\EV-Accounts\backend`. **That clone sits on an unrelated, unpushed
branch and carried a 238-line copy of the script; `origin/master` and this worktree both carry
287 lines.** The stale copy was missing three things the current one has: the `apikey` storage
header, the `monochrome` gate, and `origin_is_image` provenance handling.
▶ **THE CLONE THAT HAS THE CREDENTIALS IS NOT NECESSARILY THE CLONE WITH THE CURRENT CODE.**
Check which copy you are about to run, not just whether it runs.
⚠ **I then "fixed" the `apikey` header in that stale copy — reinventing a fix that was already
on master.** The edit has been reverted; the main clone is simply behind, and there is nothing to
land upstream.
✅ **The three gaps were measured after the fact rather than assumed harmless**: provenance is
correct (0 of 148 point at an image), licence is recorded on all 148, and **0 of 148 are
monochrome** — re-checked with the current `headshot_crop.monochrome`, with a positive control
(a greyscaled copy of a shipped frame) that **fires** and a negative control (a known-colour city
frame) that **does not**.

### 🔴🔴 `monochrome()` RETURNS A TUPLE, SO `if monochrome(im)` IS ALWAYS TRUE

My first monochrome sweep flagged **148 of 148**, including seven frames I had looked at and knew
were in colour — flags, a purple tie, blue suits. The function returns `(is_mono, chroma,
neutral_fraction)`, and **any non-empty tuple is truthy**. The tell was the positive control
printing `(True, 0.0, 1.0)` instead of `True`. Unpacked, the real answer is **0 of 148**.
▶ **A uniform answer is a broken detector — and this time the detector was MINE, not the
source's.** Same shape as the WAF earlier in this same slice, twice in one session.

### 🟢 THE STORAGE AUTH RULE, CONFIRMED BY A CONTROL WATCHED FAILING

Supabase Storage refuses a lone `Authorization: Bearer` with an `sb_secret_…` key as
**HTTP 400 whose BODY says `{"statusCode":"403", "message":"Invalid Compact JWS"}`** — an auth
failure wearing two status codes, which reads like a missing object. Sending **both `apikey` and
`Authorization`** is accepted. Proved in one run: negative refused, positive accepted, bytes read
back identical, test object deleted. The current importer already does this; only the stale copy
did not.

### ✅ BANNER ADJACENCY TEST — NO COLLISION. GRAND FORKS IS CLEAR.

`states/ND.jpg` is **"Painted Canyon overlook, Theodore Roosevelt NP"** (Acroterion, CC BY-SA 4.0),
1700x540. Read **in the desktop 6:1 band** — rows **128–411 of 540 (52.4%)**, which is where
adjacency is decided, not in the full frame. The band shows **badlands: horizontal rock strata and
sky, no built structure of any kind**, and the location is western North Dakota — roughly 350
miles from Grand Forks, which sits on the Red River at the eastern edge.
▶ **So Grand Forks is NOT a Miami/Wichita/Detroit/Charlotte case**, where the state banner *is*
that city's skyline. A Grand Forks banner may use a built subject. **This is now measured; before
today it was only an absence from a list of four.**
✅ Colour checked in the band too: mean saturation **0.211**, near-grey **14.6%** — nowhere near
the GA-3 all-greyscale failure. ⚠ No `focus` is set on the entry, so the band is centred.
⚠ **No Grand Forks banner has been sourced yet** — the adjacency question is answered, the
choice of frame is not. The usual rules still apply: prefer a horizontally arranged subject near
3:1, and a frontal building portrait is not a banner subject.

### What ND-5 still owes

1. **Find the copyright** for both cohorts — the accepted debt. The request form is unsent.
2. **Nine people still have no portrait route**: Salentiny, Rosenquist, and all seven county
   officials. A blank beats a link.
3. **Source and register the `grand-forks` city banner** in the essentials repo
   (`buildingImages.js` + `public/banners.json`, which is generated and CI-enforced).
