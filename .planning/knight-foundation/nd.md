# ND — slice 12 (Grand Forks · Grand Forks County)

Program tracker: [`PROGRAM.md`](./PROGRAM.md) · spec:
[`2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md)

**Opened 2026-09-25.** Lease `state:nd` held by chris@empowered.vote on DESKTOP-G6KDNN2.
Worktree `C:\ev-accounts-nd`, branch `knight/nd-slice12`.

| Stage | State |
| --- | --- |
| 1 geography | ✅ **APPLIED 2026-09-25 — 95 boundaries, 95 districts, 0 errors.** Only `sldu` + `sldl` were owed; `place` already existed |
| 2 legislature | ✅ **APPLIED 2026-09-25 — 141 offices, 141 seated, 0 vacant** (`CC_0144`/`CC_0145`). Grand Forks scores **3 of 5** |
| 3 city waves | — Grand Forks, unmeasured |
| 4 county waves | — Grand Forks County, unmeasured |
| 5 assets | — portraits + the `grand-forks` banner |

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
5. **ND-3 Grand Forks.** Read the city's own charter sentence for the office inventory. Grand Forks
   is a **home-rule city with a council**; the ward count and whether any seat is at-large must come
   from the charter, never from the map.
6. **ND-4 Grand Forks County.** The ND county-officer template is state law (N.D.C.C. tit. 11) and
   is reusable across the state — but which officers this county still elects separately is read
   from the county's own record, as Summit County proved when it broke the spec's assumption.
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
