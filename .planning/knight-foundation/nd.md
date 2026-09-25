# ND — slice 12 (Grand Forks · Grand Forks County)

Program tracker: [`PROGRAM.md`](./PROGRAM.md) · spec:
[`2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md)

**Opened 2026-09-25.** Lease `state:nd` held by chris@empowered.vote on DESKTOP-G6KDNN2.
Worktree `C:\ev-accounts-nd`, branch `knight/nd-slice12`.

| Stage | State |
| --- | --- |
| 1 geography | ✅ **APPLIED 2026-09-25 — 95 boundaries, 95 districts, 0 errors.** Only `sldu` + `sldl` were owed; `place` already existed |
| 2 legislature | — **141 offices owed: 47 Senate + 94 House.** Nothing measured yet |
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
4. **ND-2: seat the Legislative Assembly.** 141 offices. Owed before anything else:
   - the roster from the Legislative Assembly's own member pages, **change-checked per member**,
     not from a roster index page (MN-2's rule, and SC's one layer down);
   - a decision on how two representatives share one district row — **this is the slice's new
     structural question and it has no precedent in the program**;
   - the duplicate-name guard, with the expectation that it will fire: North Dakota is small and
     the corpus is national.
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
