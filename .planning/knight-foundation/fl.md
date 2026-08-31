# Florida — slice notes

**Spec:** [`docs/superpowers/specs/2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md)
**Plan (FL-1, FL-2):** [`docs/superpowers/plans/2026-08-28-knight-fl-waves-1-2.md`](../../docs/superpowers/plans/2026-08-28-knight-fl-waves-1-2.md)
**Roster evidence:** `backend/data/seed-fl-legislature-2026/ROSTERS.md`

Jurisdictions: **Bradenton** (Manatee), **Miami** (Miami-Dade), **Palm Beach County**, **Tallahassee** (Leon).

---

## Status

| Wave | Content | Status |
| --- | --- | --- |
| FL-1 | TIGER `place` + `sldu` + `sldl`, FIPS 12 | ✅ applied 2026-08-28 |
| FL-2 | Florida Legislature | ✅ applied 2026-08-28 — `CC_0006`, `CC_0007` |
| FL-3 | Bradenton + Manatee County | ✅ applied 2026-08-28 — `CC_0008`, `CC_0009`, `CC_0010` |
| FL-4 | Tallahassee + Leon County | ✅ applied 2026-08-28 — `CC_0011`, `CC_0012`, `CC_0013` |
| FL-5 | Palm Beach County (county only) | ✅ applied 2026-08-28 — `CC_0014` |
| FL-6 | Miami + Miami-Dade County | ✅ applied 2026-08-30 — `CC_0015`, `CC_0016`, `CC_0017` |
| FL-7 | Florida assets (5 banners + 72 headshots) | ✅ applied 2026-08-30 |

🔴🔴 **THE SLICE IS COMPLETE — ALL FIVE STAGES CLOSED (FL-7, 2026-08-30).** Florida is the first
state slice in the program to finish. **72 of 72** local and county officials carry a headshot, and
all five banner keys are live.

🔴 **STAGES 3 AND 4 ARE BOTH CLOSED.** All four Florida jurisdictions are seated: Bradenton,
Tallahassee and Miami as cities, Manatee, Leon, Palm Beach and Miami-Dade as counties. Florida is the
first slice in the program to close either stage. **73 local and county offices, 72 filled, 1 vacant**
(Manatee District 1), across seven governments plus the state.

## Geography loaded (FL-1)

Counts measured against the raw TIGER 2024 FIPS 12 `.dbf` before loading, then verified after.

| Layer | mtfcc | Loaded | Note |
| --- | --- | --- | --- |
| `sldl` | `G5220` | 120 | 0 `ZZZ` pseudo-districts, `LSY = 2024` |
| `sldu` | `G5210` | 40 | 0 `ZZZ` pseudo-districts, `LSY = 2024` |
| `place` | `G4110` | 411 | 956 raw records; the other 545 are `G4210` CDPs, skipped |

Florida is **single-member in both chambers**, so polygon count equals seat count.

`county` (`G4020`, 67 rows) was already present and is deliberately excluded from the allowlist.
`cousub` is deliberately excluded — Florida is not a strong-MCD state, so its county subdivisions are
statistical. **Do not add FL to `COUSUB_FUNCSTAT_STATES`.**

`essentials.geofence_child_county` was refreshed `CONCURRENTLY` after each load. The loader prints an
ACTION REQUIRED notice for this and the FL-1 plan had omitted it; `check:child-county` runs in CI on
every push and fails without it. The refresh needs the `postgres` role — `ev_api` is not the owner —
so it goes through the Supabase MCP.

⚠ **CORRECTED 2026-08-28: "every future slice must refresh the matview" was too broad.** The matview
maps only `G4110`, `G5400`, `G5410` and `G5420` children to counties
(`scripts/check-child-county-mapping.mjs`), and only `load-state-tiger-boundaries.ts` prints the
notice. FL-1 loaded `G4110` places, so it needed the refresh. **FL-3 loaded only `X` codes, so it did
not** — `check:child-county` was verified green after FL-3 with no refresh (7,245 children, 0 stale).
The rule is: refresh after loading a `place` or school-district layer, not after every load.

## 🔴 Identity anchors — the vintage check

Resolved 2026-08-28 against the **enacted plans themselves**, independent of TIGER, and all three
matched after the load.

| Point | Coordinates (lon, lat) | House | Senate |
| --- | --- | --- | --- |
| Tallahassee | -84.2522719, 30.4535287 | HD-9 | SD-3 |
| Bradenton | -82.5768045, 27.4897985 | HD-71 | SD-20 |
| Miami | -80.2086152, 25.7751630 | HD-113 | SD-36 |

Sources, in order of authority:

- **House plan `H000H8013`** — `https://services.arcgis.com/ptvDyBs1KkcwzQNJ/arcgis/rest/services/Florida_House_2022_H000H8013/FeatureServer/2`
- **Senate plan `S027S8058`** — `https://services.arcgis.com/ptvDyBs1KkcwzQNJ/arcgis/rest/services/Florida_Senate_2022_S027S8058/FeatureServer/1`
- Tallahassee also confirmed by **Leon County Supervisor of Elections** (`intervector.leoncountyfl.gov`, layers 5 and 4): District 9 / District 3.
- Miami also confirmed by **Miami-Dade County** `MD_KnowWhereToVote` (`gisweb.miamidade.gov`, layers 7 and 6): 113 / 36.

⚠ **Bradenton has ONE source only.** Manatee County publishes no legislative-district service —
searched ArcGIS Online 2026-08-28, 128 results, none legislative. If the Bradenton anchor is ever the
only one that disagrees, suspect the anchor before suspecting the load.

The plan numbers also confirm the vintage: the operative maps are the **2022 apportionment**, and
Florida redistricts decennially, so the next legislative remap is 2032. Only the congressional map was
litigated after 2022.

🔴 **CORRECTED 2026-08-29 while planning FL-6: that last sentence is true of the STATE maps and
FALSE of a CITY map.** **Miami's own commission map was struck down TWICE by a federal court** — Judge
K. Michael Moore held both the 2022 and the 2023 maps unconstitutionally racially gerrymandered in
April 2024, and the map in force is the one the Commission adopted 4–1 in a **May 2024 settlement**,
drawn by the plaintiffs and the ACLU of Florida. **A local map can be litigated even when the state
maps are not; check per jurisdiction.**

## Target-city place GEOIDs (for FL-3 onward)

| Place | GEOID | Interior point (lon, lat) |
| --- | --- | --- |
| Bradenton city | `1207950` | -82.5768045, 27.4897985 |
| Tallahassee city | `1270600` | -84.2522719, 30.4535287 |
| Miami city | `1245000` | -80.2086152, 25.7751630 |
| West Palm Beach city | `1276600` | -80.1270377, 26.7451143 |
| Palm Beach town | `1254025` | -80.0418628, 26.6948430 |

⚠ **`STATE_CITY_ASSERTIONS` is a SUBSTRING match and is weak for Florida.** `'Miami city'` is
satisfied by `'West Miami city'`, which Florida also contains, so a run missing the real Miami record
would still pass that gate. The load-bearing check is the exact-`geo_id` query at the bottom of
`scripts/verify-fl-tiger-import.sql`.

## 🔴 The `geo_id` collision is TOTAL for districts 1–40 — AND REACHES THE COUNTY LAYER

Florida's `sldl` and `sldu` GEOIDs **both start at `12001`**, so `12040` is both HD-40 and SD-40.
Every join must pair `geo_id` with `mtfcc` or `district_type`. This is not theoretical here: SD-3,
SD-20 and SD-39 are all inside the colliding range, so two of the three anchors and one of the five
vacancies would resolve to the wrong chamber without the pairing.

🔴 **CORRECTED 2026-08-28 during FL-3: the `county` layer collides as well.** This note previously
said only `sldl` against `sldu`. County FIPS are 5 digits and so are `sldl` GEOIDs, so **`12081` is
both Manatee County (`G4020`) and State House District 81 (`G5220`)**. Measured at Bradenton City Hall
with the pairing dropped, the probe returned **four rows, two of them officials in other counties**:

| label | matched through | who |
| --- | --- | --- |
| State House District 71 | `12071` `G5220` | correct — Will Robinson |
| State Senate District 20 | `12020` `G5210` | correct — Jim Boyd |
| State House District 20 | `12020` `G5210` | **wrong chamber** — Judson Sapp, north Florida |
| State House District 81 | `12081` `G4020` | **wrong county** — Yvette Benarroch, Collier County |

Nothing errored. `scripts/verify-bradenton-manatee-probes.sql` keeps this demonstration inline, as its
probe 2, so the failure stays visible rather than remembered.

## Legislature seated (FL-2)

| | Offices | People | Vacant |
| --- | --- | --- | --- |
| House | 120 | 116 | 4 |
| Senate | 40 | 39 | 1 |
| **Total** | **160** | **155** | **5** |

`external_id` bands: **House `-(1220000 + n)`, Senate `-(1230000 + n)`.**

🔴 **The obvious band was TAKEN.** The NC/CO scheme `-(1210000 + n)` collides with 166 existing rows
at `-1212802 … -1210101` — the 2026 US House candidates from `seed-fl-2026-house/`, keyed
`-12<district><candidate>`. `ON CONFLICT DO NOTHING` would have absorbed the collision silently and
left seats held by whoever already owned those ids. Both bands actually used were measured empty and
are re-asserted by `CC_0007` before it inserts anything.

Date precision: **day 39, year 116, unknown 0.** `how_started` is `'elected'` for all 155 — Florida
fills legislative vacancies by **special election**, not appointment (Fla. Const. art. III, s. 15(d);
ch. 100, F.S.).

## 🔴 The five vacancies

| Seat | Vacant since | Predecessor's last day |
| --- | --- | --- |
| HD-55 | 2026-08-06 | Kevin M. Steele, 2026-08-05 |
| HD-78 | 2026-05-21 | Jenna Persons-Mulicka, 2026-05-20 |
| HD-113 | 2025-11-19 | Vicki L. Lopez, 2025-11-18 |
| HD-116 | 2026-08-22 | Daniel Perez, 2026-08-21 |
| SD-39 | **not published** | not published |

Each has an office with `is_vacant = true`, zero `office_terms` rows and a NULL holder. **Flagging is
load-bearing twice over:**

1. `check-address-reachability.mjs` classifies `DEAD_GEOGRAPHY` as
   `reachable AND offices > 0 AND active_holders = 0 AND vacant_offices = 0`. An unflagged empty
   office fires a **new `fl|STATE_LOWER` bucket** and fails the gate.
2. `essentials.offices_missing_terms` counts only **unflagged** rows as drift. This wave moved it
   814 → 819 total and 159 → 164 flagged, with **unflagged unchanged at 655** against a 699 threshold.

**MIAMI HAS NO STATE REPRESENTATIVE RIGHT NOW.** The city-hall anchor sits in HD-113, so the
four-answer probe for Miami can only ever return three answers until the special election is held.
This is the truth, not a defect — but FL-6 must not be judged as failing because of it.

▶ **Re-check all five before FL-7.** Three of the four House vacancies opened within four months of
2026-08-28, so special elections are pending. Miami-Dade's own GIS still lists "Vicki Lopez" as HD-113's
`REPNAME`, which is a reminder that a county name field can be stale even when its geometry is right.

## Sources for FL-3 onward, not yet gathered

- **Florida's constitutional county officers** are Sheriff, Tax Collector, Property Appraiser,
  Supervisor of Elections and Clerk of the Circuit Court. **Charter counties vary**, so the template is
  confirmed per county from that county's charter, never inherited from the state. 🔴🔴 **AND CHARTER
  STATUS DOES NOT PREDICT THE SET — measured across three counties: Manatee non-charter 5, Leon charter
  **6**, Palm Beach charter **5**. Only Miami-Dade (FL-6) is left to read.** **Manatee is
  ANSWERED (FL-3): it is a NON-charter county, so the state template applies unmodified.**
  ✅ **ALL FOUR ARE NOW ANSWERED (FL-6, 2026-08-30). Miami-Dade is a charter county and elects
  FIVE** — the state template, not Leon's six. Final measured spread: Manatee non-charter **5**, Leon
  charter **6**, Palm Beach charter **5**, Miami-Dade charter **5**. 🔴 **Charter status predicted
  nothing in four counties out of four.** The one that differs is the non-obvious one: Leon, and it
  differs by electing a Superintendent of Schools.
- 🔴 **Florida county officers run on the PRESIDENTIAL cycle; county commissioners do not.** All five
  Manatee officers' terms expire **January 2029** — elected November 2024, next election 2028 — and
  none was on the 2026 ballot even though 2026 is a gubernatorial year. Commission terms expire in
  **November** of even years. Two different conventions inside one county. Check this per county
  rather than inheriting it.
- **Miami-Dade County and the City of Miami are separate governments.** Miami-Dade is not a
  consolidated city-county. Do not conflate them.
- Miami-Dade's elected **Sheriff** was restored by constitutional amendment and filled recently.
  Confirm the office is elected before seeding it. ✅ **ANSWERED (FL-6): it is elected.** Amendment 10,
  adopted 2018-11-06, forced five independently elected offices; Rosanna "Rosie" Cordero-Stutz took
  office **2025-01-07** with the other four.
- ✅ **ANSWERED 2026-08-28 while planning FL-4: Tallahassee's city commission IS entirely at-large.**
  The Leon SOE states it directly — "City Commissioners and Mayor do not have districts." Five seats,
  and **the Mayor is SEAT 4**, inside the numbering rather than beside it. So **no ward layer is
  needed**: the citywide `place` polygon `1270600` carries all five seats, and every Tallahassee
  address returns all five commissioners. FL-4 plan:
  [`2026-08-28-knight-fl-wave-4-tallahassee-leon.md`](../../docs/superpowers/plans/2026-08-28-knight-fl-wave-4-tallahassee-leon.md).
- 🔴🔴 **LEON IS A CHARTER COUNTY AND ELECTS *SIX* CONSTITUTIONAL OFFICERS — MANATEE, NON-CHARTER,
  ELECTS FIVE.** Leon has a Home Rule Charter since 2002-11-12 and elects a **Superintendent of
  Schools** on top of the five-office state template. This is the strongest evidence yet for the rule
  above: **never inherit the officer template.** Miami-Dade (FL-6) is also a charter county.
- 🔴 **THE TWO COUNTIES ALSO NAME THEIR AT-LARGE SEATS DIFFERENTLY.** Manatee: "District 6" and
  "District 7". Leon: "At Large, Group 1" and "At Large, Group 2". Follow the publisher; do not
  normalise.
- ✅ **DECIDED 2026-08-28 (Cantrell): Palm Beach County gets its OWN COUNTY KEY in
  `buildingImages.js`.** It has no city half, and `buildingImages.js` is keyed by city, so the
  alternative was to fall back to the Florida state banner. That was rejected: the state banner IS a
  Miami skyline ("Miami Late Afternoon Skyline"), so reusing it here would **also collide with Miami's
  own banner at FL-6**, where the adjacency rule already forbids another downtown skyline. Resolves
  spec §8.3. ⚠ The key name and the composition are still to be chosen, at FL-7.
- **Miami's banner cannot be a downtown skyline.** The Florida STATE banner already is one
  ("Miami Late Afternoon Skyline"), and the adjacency rule forbids repeating a composition.

## FL-3 — Bradenton and Manatee County (applied 2026-08-28)

| | Offices | People | Vacant |
| --- | --- | --- | --- |
| Bradenton — City Council | 5 | 5 | 0 |
| Bradenton — Office of the Mayor | 1 | 1 | 0 |
| Manatee — Board of County Commissioners | 7 | 6 | **1** |
| Manatee — Elected Officials | 5 | 5 | 0 |
| **Total** | **18** | **17** | **1** |

`external_id` band: **`-(1240000 + n)`**, measured empty before use. Bradenton `n = 1…6`, Manatee
commission `n = 11…17`, Manatee officers `n = 21…25`. **17 of 10,000 slots used, and this is the FL
LOCAL band — later Florida jurisdictions continue in it.** The legislature bands are `-(1220000 + n)`
House and `-(1230000 + n)` Senate.

Date precision, per person, from the publisher: **day 5, month 6, year 2, unknown 3**.

### Private MTFCC allocations

| Code | Layer | district_type | Rows | Loader |
| --- | --- | --- | --- | --- |
| `X0036` | Bradenton City Council wards | `LOCAL` | 5 | `scripts/load-bradenton-ward-boundaries.ts` |
| `X0037` | Manatee County commission districts | `COUNTY` | 5 | `scripts/load-manatee-commission-boundaries.ts` |

**Next free is `X0038`.** No guard change was needed: `MTFCC_DISTRICT_TYPE_GUARD` in
`src/lib/geoIdGuard.ts` has an `X%` catch-all admitting `LOCAL` and `COUNTY`. There is no central
X-code registry — each wave hardcodes its code in its own loader.

### The acceptance probe

`scripts/verify-bradenton-manatee-probes.sql`. Anchor is **Bradenton City Hall,
`-82.5733305, 27.5000582`**.

⚠ **The published address does not geocode.** "101 Old Main Street" returns 0 Census matches; the
city's own footer explains that city hall sits "At the corner of Old Main Street (**12th St. W.**) and
Barcarrota Boulevard". Use `101 12TH ST W, BRADENTON, FL 34205`.

The four required answers are **Ward 3 · Commission District 3 · HD-71 · SD-20**. ⚠ The probe returns
**12** rows, not 4, and that is correct: a city-hall address also legitimately elects the Mayor
citywide, both at-large commissioners and all five constitutional officers. Probe 1a asserts the four
by name, so the count never has to be interpreted.

### 🔴 Geography findings

- **Bradenton's ward layer is LAND ONLY.** The ward union is 14.397 sq mi; TIGER place `1207950` is
  17.505 sq mi; **3.211 sq mi of the place falls in no ward** — that is the Manatee River. TIGERweb's
  own attributes are `AREALAND` 37,152,499 m² (14.344 sq mi) and `AREAWATER` 8,185,647 m² (3.160 sq
  mi), so the ward union matches ALAND to **0.364 %**. 🔴 **A tiling gate against the place polygon
  fails on a correct layer** — gate against `AREALAND` instead.
- **Four of the five ward polygons fail `ST_IsValid`** and needed `ST_MakeValid`; only Ward 3 landed
  clean, and Ward 4 has 36 parts. 🔴 **Every gate in a loader runs on the PRE-repair GeoJSON**, so the
  repair's output must be re-checked from the **database**. Verified: stored areas match the layer's
  own `ACRES` field to three decimals, the union is unchanged, and the anchor still resolves to exactly
  one ward.
- **Manatee publishes FOUR services that all claim to be the commission districts, and they are the
  same boundary to 0.000 sq mi**: `BCC_DISTRICTS_LEGAL` and `CountyCommissionDistricts_CopyFeatures`
  in EPSG:3857, `BoCC_Districts` and `District_Boundaries` (layer **16**, not 0) in EPSG:2237. Use
  `BCC_DISTRICTS_LEGAL`; the loader cross-checks against `BoCC_Districts`, whose different projection
  makes the cross-check also prove the reprojection.
- **The five commission districts tile the county exactly** — 964.03 against 964.03 sq mi, 0.046 sq mi
  uncovered, 0.047 sq mi overhang, 0.0000 self-overlap. 🔴 **Use a tolerance, never `ST_Equals`.**
- ⚠ **Three of the four services carry stale `COMMNAME` rosters, and even `LEGAL` still names the
  deceased District 1 incumbent.** Never read a roster out of a boundary layer.

### 🔴 The District 1 vacancy, and how a county vacancy differs from a legislative one

Commissioner **Carol Ann Felts died 2026-02-24** — the county's own announcement, published that day.
Governor DeSantis declared the vacancy by **Executive Order 26-76** and then **left the seat empty**,
which is why it reaches the 2026 ballot as a **two-year unexpired term**.

🔴 **A county commission vacancy is filled by GUBERNATORIAL APPOINTMENT** (Fla. Const. art. IV §1(f)),
**not** by the special election Florida uses for a **legislative** vacancy (art. III §15(d)). FL-2's
five vacancies and this one are different mechanisms, so an appointee can appear here at any moment,
with no election.

`offices.vacant_since = 2026-02-24` is written. **Felts' own closed term is deliberately NOT written**,
though every date for it is known — sworn in **2024-11-19**, died **2026-02-24**, so
`how_ended => 'died'`. FL-2 wrote no predecessor terms for any of its five legislative vacancies, and
doing it for one county seat would leave Florida internally inconsistent.
▶ **Open work: write predecessor terms for all six Florida vacancies together.** The evidence for
Felts is in `ROSTERS.md`.

### 🔴 Source defects — the Supervisor of Elections contradicts itself

Its **Elected Officials** page still lists Felts, term expiring November 2028. Its own **Offices Up
For Election** page lists District 1 for a **two-year term**, which exists only to fill an unexpired
vacancy. Same publisher, opposite answers, and the ballot page is the correct one. It also misspells
Ward 1 as "Kocker" while its own `mailto:` in the same block reads `jayne.kocher@`. Eight defects in
total — the full list is in `ROSTERS.md`.

🔴 **A published expiry is not an election date, and four of seventeen people proved it.** Mayor Brown
expires January 2029 but has served since **January 2021**; Kocher and Coachman expire January 2029
and were **re-elected** in November 2024; Kruse expires November 2028 but has served since **2020**.

### 🔴 Charter rulings that later Florida waves should read first

- **The Bradenton Mayor is `voting_powers = 'full'`**, with the tie-break rule in
  `offices.description`. The mayor is ex officio council president and votes only to break a tie — the
  same charter shape as Nashville §3.03, which `CC_0004` wrote `non_voting`. This wave ruled the other
  way: Nashville's Vice Mayor exists *only* to preside, so "no vote in it" is the whole truth about
  that seat, whereas Bradenton's Mayor is the chief executive in a chamber of one. The text goes in
  `description` because **both read paths hide `representation_note` when `voting_powers = 'full'`**.
  This also makes the record robust to the November 2026 charter amendment, which would strip the ex
  officio presidency and the tie-break: under this ruling it changes no column.
- **Vice Mayor and Second Vice Mayor are council-elected ANNUAL ROLES, not offices** — chosen at the
  organisational meeting, and they rotate. Same as Asheville, opposite of Nashville.
- **Bradenton's City Clerk is appointed staff.** Not an office.
- **Out of scope, considered and excluded:** the Manatee County School Board (5 elected), Mosquito
  Control, Soil & Water Conservation, 7 fire districts, roughly 30 Community Development Districts.
- ⚠ **The Supervisor of Elections lists Bradenton BEACH, Palmetto, Anna Maria, Holmes Beach and
  Longboat Key immediately after Bradenton, and titles their seats "Commissioner, Ward N"** — near
  identical to Bradenton's. Scope every roster parse to the "City of Bradenton" heading.

### 🔴 Toolchain lessons, all learned by something failing

- **`essentials.seat_officeholder()` REFUSES a NULL `term_start`** outright. But prod holds **81,676**
  `unknown`-precision `office_terms` rows with a NULL start, written by the ADR 0002 phase-2 backfill
  by direct insert. So "open-ended term" in CLAUDE.md means `term_end IS NULL`, **not** an unbounded
  start. `CC_0009` routes dated rows through the helper and inserts undated rows directly, **guarded on
  the office having zero existing terms** — which is exactly what makes skipping the two-step safe,
  since with no predecessor there is nothing to close.
- **An `external_id` band guard must be an ALLOWLIST, not a count.** A count of "rows in the band
  before this migration runs" makes the migration **non-idempotent** — a re-run counts its own rows and
  refuses — and it is also **weaker**, because a foreign row that happens to make the count match
  passes. Both bugs were live in `CC_0009` and `CC_0010`. The same mistake in the post-verify counts
  gave `CC_0010` a hidden **ordering dependency** on `CC_0009`.
- **Re-run every applied migration once, as the idempotency test.** It is the only thing that found the
  two bugs above.
- ⚠ **Do not strip `BEGIN;`/`COMMIT;` to build a combined dry run.** A `sed` meant for the inner
  transactions also matched the outer wrapper, so `CC_0008`'s statements ran in **autocommit and
  committed to prod**, and its `ON COMMIT DROP` temp table vanished between statements. To dry-run one
  file, turn **its own** final `COMMIT` into `ROLLBACK` and leave its `BEGIN` alone.

## FL-4 — Tallahassee and Leon County (applied 2026-08-28)

| | Offices | People | Vacant |
| --- | --- | --- | --- |
| Tallahassee — City Commission | 5 | 5 | 0 |
| Leon — Board of County Commissioners | 7 | 7 | 0 |
| Leon — Elected Officials | **6** | 6 | 0 |
| **Total** | **18** | **18** | **0** |

`external_id`: city `n = 31…35`, commission `n = 41…47`, officers `n = 51…56`, all in the shared
`-(1240000 + n)` Florida LOCAL band. **35 of 10,000 slots used across FL-3 and FL-4.**

Date precision: **month 9, unknown 9.** No appointments; no vacancies.

`X0038` = the 5 Leon commission districts. **Next free is `X0039`.**

### 🔴 Tallahassee is entirely at-large — the open question, answered

The Leon SOE: *"City Commissioners and Mayor do not have districts."* Five seats, and **the Mayor is
SEAT 4** inside that numbering. Consequences, all of which invert an FL-3 assumption:

- **No city ward layer was needed** — one loader for the whole wave, not two.
- **All five seats share the ONE citywide district** (`1270600` `G4110`, `num_officials = 5`), and the
  structure gate asserts "**5 offices on one district, 5 distinct titles**" — the opposite shape from
  Bradenton's "1 per ward".
- **ONE chamber**, not two. Bradenton needed a separate `Office of the Mayor`; Tallahassee's mayor is
  Seat 4 of the same body.
- **No `voting_powers` ruling arises.** Tallahassee's mayor has a full, equal vote.
- ⚠ **The probe's city answer is FIVE rows, not one.** The probe therefore asserts a **count per
  required answer**; "at least one city commissioner" would pass with four of five missing.

### 🔴 Leon is a CHARTER county with SIX constitutional officers

Home Rule Charter in force since **2002-11-12**. The sixth office is the **Superintendent of
Schools** — Manatee, non-charter, has five and no such office. So Leon's `Elected Officials` chamber
is `official_count = 6` and its countywide district carries **8** offices (2 at-large + 6 officers),
not 7. The gate asserts the Superintendent **by name**, because a count of 6 can be reached by
duplicating another officer. **The school BOARD remains out of scope**, as Manatee's did.

⚠ **The two counties also name their at-large seats differently:** Manatee "District 6 / District 7",
Leon "**At Large, Group 1 / Group 2**". Both kept as published.

⚠ **This wave spans FIVE take-office rules across three bodies:** city 13th day after the general;
county commission and Superintendent 2nd Tuesday after the general; the other five officers 1st
Tuesday after the 1st Monday in January.

### The acceptance probe

`scripts/verify-tallahassee-leon-probes.sql`. Anchor **Tallahassee City Hall, 300 S Adams St,
`-84.2820030, 30.4395411`** — which geocodes cleanly, unlike Bradenton's ceremonial address.

Four required answers, all PASS: **5 city commissioners · County District 5 (O'Keefe) · HD-9 (Tant) ·
SD-3 (Simon)**. Negative control: Bradfordville, inside Leon County but outside the city, returns
County District 4 and **no** city seat.

🔴 **The collision demo is richer here than in FL-3 — THREE wrong rows, one of them in the REVERSE
direction.** At this anchor an unpaired `geo_id` join returns:

| label | matched through | why wrong |
| --- | --- | --- |
| State House District 3 | `12003` `G5210` | SD-3's polygon → HD-3 (Nathan Boyles) |
| State House District 73 | `12073` `G4020` | **Leon County's polygon** → HD-73 (Fiona McFarland) |
| State Senate District 9 | `12009` `G5220` | **HD-9's `sldl` polygon → an `sldu` DISTRICT** (Stan McClain) |

The third is the direction `fl.md` did not previously record: not only does an `sldu` polygon match an
`sldl` district, the reverse happens too. **Pair `geo_id` with `mtfcc` AND `district_type`, always.**

### Geography findings

- **Two independent digitizations of the commission districts agree to 0.0000 sq mi** on all five: the
  SOE's `SOE_DistrictsCurrent_D_WM` layer 1 and the county GIS `TLC_OverlayCommissionDistrictFeature`
  layer 0. The SOE service is the primary — `fl.md` already trusts it, because **layers 5 and 4 of the
  same service are the FL House and Senate services the FL-1 vintage check used**.
- **The five districts tile TIGER county `12073` to 0.0040 sq mi uncovered / 0.0006 overhang / 0.0000
  self-overlap** — tighter than Manatee's.
- **The SOE's layer 6 "City Limits" agrees with TIGER place `1270600` to 0.42 %** (105.456 vs 105.477
  sq mi). This is an **independent control on the polygon all five city seats hang off**, which
  Bradenton had no equivalent for. The load-bearing assertion is that TIGER covers city hall.
- **All five polygons landed `ST_IsValid` with no repair** — unlike Bradenton, where four of five
  needed `ST_MakeValid`.
- ⚠ **`DISTRICT` is TEXT here (`'1'`…`'5'`), not the integer Manatee's service returns.** Proved by
  substituting `Number.isInteger()`: it skips all five districts with a warning per row, then reports
  "expected 5, got 0". ⚠ **`TOTALPOP20` is `0` on every row in both services** — a dead field.
- Six positive controls, not one: city hall plus each district's centroid, every centroid verified to
  fall inside its own district before being written down as a literal.

### 🔴 Nine of eighteen have `start_precision = 'unknown'`, and one source was rejected

**Dated (month precision, 9):** the seven commissioners, from the county's own published service-year
ranges plus the commission's take-office rule; and Mayor Dailey and Commissioner Matlow, from their own
city pages (both November 2018).
⚠ **Dailey's earlier service was on the LEON COUNTY COMMISSION, District 3, 2006–2018** — a different
office, so the mayoralty starts 2018. **Akin Akinyemi**, now Property Appraiser, was a commissioner
2008–2012: another separate span. **Nick Maddox has held At Large Group 2 continuously since 2010** and
did not move from a district.

**Undated (9):** Porter, Richardson and Williams-Cox on the city side; all six constitutional officers.
No reachable publisher gives a start.

🔴 **THE CERTIFIED-RESULTS PDFs WERE REJECTED AS A DATE SOURCE, AND THE REASON IS THE LESSON.** The
SOE publishes official certified results as PDFs, reachable by fetching from inside the browser
context. Their **race headers extract reliably** and gave a trustworthy election-cycle inventory
(city Seats 1–2 presidential, Seats 3/5 + Mayor midterm). But a parser slicing each race's **candidate
block** came out **shifted by one race** and reported *"Mayor → Jeremy Matlow"* for 2018 — Dailey won
the mayoralty, Matlow won Seat 3. **Plausible, wrong, and it would have seated two people on each
other's dates.** It was discarded rather than repaired. ▶ Follow-up: the city and county clerks' January
organisational minutes would date all nine precisely.

### 🔴 Toolchain lessons

- **`curl` gets a HARD 403 from `leonvotes.gov`, `cms.leoncountyfl.gov` and four of six officer sites**
  — TLS-fingerprint blocking; a full browser header set does not help. **Use Playwright.** The ArcGIS
  endpoints and `talgov.com` answer `curl` normally. A PDF behind the block can be fetched with an
  in-page `fetch()` and base64'd out.
- ⚠ **The SOE's Elected Officials page hides its content in COLLAPSED ACCORDIONS.** A plain
  `innerText` of the body returns only the category headings. Locate each heading element and walk up
  to its container.
- 🔴 **AN `external_id` BAND GUARD MUST BE SCOPED TO THE WAVE'S OWN SUB-RANGE, not the whole band.**
  Four versions of this guard were wrong: (1) "the band holds exactly N rows" — not idempotent, a
  re-run counts its own rows; (2) the same count in the post-verify — created a false ordering
  dependency between the two halves; (3) "the whole band holds nothing this wave owns" — correct within
  one wave, but `-(1240000 + n)` is **shared across Florida waves**, so FL-4 saw FL-3's seventeen
  legitimate rows as foreign, **and would have broken FL-3's own re-run**; (4) the fix — assert that
  nothing inside `[min..max]` of *this wave's* ids is owned by anything else. `CC_0009` and `CC_0010`
  were edited in place to match, which changed no data.
- 🔴 **RE-RUN EVERY APPLIED MIGRATION IN THE SLICE, NOT JUST THE NEW ONES.** Re-running all six FL-3
  and FL-4 migrations is what proved (3) above was a live defect rather than a theoretical one.
- **The party guard had to be widened.** FL-3 tested `\((R|D|NPA|I)\)`, which does **not** match
  `(DEM)` — and `(DEM)` is exactly what the Leon SOE prints beside all six constitutional officers.

## FL-5 — Palm Beach County (applied 2026-08-28)

**Plan:** [`2026-08-28-knight-fl-wave-5-palm-beach-county.md`](../../docs/superpowers/plans/2026-08-28-knight-fl-wave-5-palm-beach-county.md)
— read its FOUR "Deviations found during execution" sections; they carry more than this summary.

| | Offices | People | Vacant |
| --- | --- | --- | --- |
| Palm Beach — Board of County Commissioners | **7** | 7 | 0 |
| Palm Beach — Elected Officials | **5** | 5 | 0 |
| **Total** | **12** | **12** | **0** |

`external_id`: commission `n = 61…67`, officers `n = 71…75`, in the shared `-(1240000 + n)` Florida
LOCAL band — the contiguous sub-range `-1240075 … -1240061`, with 68…70 deliberately unused.
**47 of 10,000 slots used across FL-3, FL-4 and FL-5.**

Date precision: **day 2, month 9, year 1, unknown 0.** `how_started`: **elected 10, appointed 2.**

`X0039` = the 7 Palm Beach commission districts. **Next free is `X0040`.**

**County only — no city half.** One boundary loader, one roster, **ONE migration**. No `City`
government, no city chamber, no city district; TIGER place `1276600` (West Palm Beach) stays unused.

### 🔴🔴 THREE COUNTIES, THREE OFFICER TEMPLATES AND THREE COMMISSION SHAPES — CHARTER STATUS PREDICTS NOTHING

| County | Charter | Officers | Commission |
| --- | --- | --- | --- |
| Manatee | **non**-charter | **5** | 5 single-member + 2 at-large ("District 6" / "District 7") |
| Leon | charter (2002-11-12) | **6** — incl. elected Superintendent of Schools | 5 single-member + 2 at-large ("At Large, Group 1" / "Group 2") |
| **Palm Beach** | **charter (1985)** | **5** — **no** elected Superintendent | **7 single-member, NO at-large seat at all** |

Leon is chartered and elects six; Palm Beach is chartered and elects five. **The charter does not
predict the officer set.** Palm Beach's school superintendent is **appointed by the School Board**.

🔴 **Consequence for the data shape: Palm Beach's countywide district carries FIVE offices** — the
officers, and nothing else. Leon's carries 8 (2 at-large + 6 officers), Manatee's 7 (2 + 5). A gate
copied from either that expects at-large seats on the countywide district has nothing to assert here.
`CC_0014` therefore asserts the **7/5 split three ways**: per chamber, exactly 5 on the countywide
district, and directly that **zero** commissioner offices sit on it. A commissioner mis-mapped
countywide still totals 12 and would appear for **every** address in the county.

🔴 **Mayor and Vice Mayor are annual commission-elected ROLES, not offices** — Sara Baxter (D6) is
Mayor and Marci Woodward (D4) Vice Mayor as of 2026-08-28. Same ruling as Bradenton's and Asheville's
Vice Mayor, opposite of Nashville's.

### 🔴🔴 STATE ATTORNEY AND PUBLIC DEFENDER ARE CIRCUIT OFFICES, NOT COUNTY OFFICES

Palm Beach's own *Overview of County Government* lists **seven** "constitutional officers", including
the **State Attorney** and the **Public Defender**. Both are officers of the **15th Judicial Circuit**
(Fla. Const. art. V §§17–18). They look countywide only because **that circuit is coterminous with
Palm Beach County** — Leon's 2nd Circuit spans **six** counties, which is exactly why FL-4 never met
the question and why Leon's SOE did not list them.

**Not seated.** Doing so would assert that the circuit equals the county — true today, but a fact about
*circuit* boundaries, so a redraw would silently make the record wrong with nothing erroring. It would
also leave Florida internally inconsistent, because Leon's voters elect a State Attorney too.
`CC_0014` asserts **zero** offices titled `Superintendent of Schools`, `State Attorney` or
`Public Defender` — a negative assertion, because the generator was copied from Leon's where the
Superintendent is a live entry.

▶ **PROGRAM-LEVEL OPEN WORK:** circuit-elected offices are a real unmodelled class of
countywide-elected official, and a `JUDICIAL` compass scale already exists. Every Florida county has a
State Attorney and a Public Defender; none is seated anywhere.

### 🔴 The seven seats stagger ODD / EVEN, and the SOE filing report is what proves it

| Districts | Elected in | Next |
| --- | --- | --- |
| **1, 3, 5, 7** | presidential years — 2020, 2024 | 2028 |
| **2, 4, 6** | gubernatorial years — 2018, 2022, 2026 | 2030 |

**All five constitutional officers are on the PRESIDENTIAL cycle** — on the 2024 ballot, next up 2028.
The Manatee-derived rule above holds for Palm Beach too. Confirmed across three cycles of the
Supervisor of Elections' own candidate filing report:

| Cycle | County offices with filings |
| --- | --- |
| 2022 (gub) | BCC 2, 4, 6 — no officers |
| 2024 (pres) | BCC 1, 3, 5, 7 **and all five officers** |
| 2026 (gub) | BCC 2, 4, 6 — no officers |

🔴🔴 **THE FILING REPORT IS NOT ON `votepalmbeach.gov`, AND IT IS THE MOST USEFUL SINGLE SOURCE IN THE
WAVE.** It is an iframe at `voterfocus.com/CampaignFinance/candidate_pr.php?c=palmbeach&el=<n>`,
reachable only by reading the `Announced-Candidates` page's DOM for its `src` — that page renders no
candidate data itself, and the iframe URL **302s if fetched directly with `curl`**. Cycle is the `el`
parameter: **`9` = 2022, `11` = 2024, `12` = 2026, `13` = 2028.**
It resolved the stagger, the officer cycle, three of the seven commission dates, and every officer's
**ballot name** (`Ric L. Bradshaw`, `Anne M. Gannon`, `Sara Marie Baxter`).
▶ **FIND THIS FIRST IN ANY LATER FLORIDA COUNTY WAVE.** Miami-Dade's SOE runs the same VoterFocus
platform.

⚠ **A results feed cannot answer "which offices are up".** Florida removes **unopposed** races from the
ballot entirely, so an unopposed officer appears in no results feed whatever the cycle — Jacks and
Gannon were both unopposed in 2024. The plan reached a true conclusion from that broken premise; the
filing report is the right instrument.

### 🔴🔴 THREE OF SEVEN COMMISSIONER BIO PAGES APPEND THE PREDECESSOR'S BIOGRAPHY, UNLABELLED

`discover.pbc.gov/countycommissioners/<district>/Pages/Biography.aspx` concatenates the sitting
commissioner's biography with the previous one's — no heading, no separator, no name change to warn you.

| Page | Stale text that follows the incumbent's bio |
| --- | --- |
| District 7 | *"Mack Bernard was elected in November 2016 to the Palm Beach County Commission, District 7."* |
| District 6 | *"Palm Beach County Commissioner Melissa McKinlay was first elected in 2014."* |

🔴 **A regex for "elected in `<year>`" returns 2016 for District 7 and 2014 for District 6** — right
shape, right page, right district heading, wrong by eight years each. District 3 gives Joel Flores no
commission date at all. **Read these by eye.** This is the FL-4 rejected-parser lesson in a new form,
and worse: the FL-4 failure was a parser someone wrote, this one is the publisher's own page.

⚠ Two smaller traps on the same site: the district URL casing is inconsistent (`district1` …
**`District5`** with a capital D … `district7`), and every page's extracted text opens with site
navigation containing the literal strings "District 1" through "District 7".

⚠ **A page's own revision stamp can be worth more than its prose.** District 5's page is stamped
`*Revised 11/2020`, which is what exposed the plan's wrong start year for Maria Sachs — she was elected
**2020**, not 2022.

### 🔴🔴 BOBBY POWELL JR. AND MACK BERNARD TRADED SEATS, AND BERNARD WAS ALREADY IN PROD

- **Mack Bernard** was the District 7 commissioner (elected Nov 2016). He is now **State Senator,
  SD-24** — seated by FL-2 as `external_id = -1230024`.
- **Bobby Powell Jr.** was the SD-24 senator. He is now the **District 7 commissioner**, a fresh insert.

🔴 **The stale `County_Commission_Districts` GIS layer STILL NAMES `MACK BERNARD` for District 7.** A
name-based reuse step reading that layer would have seated a sitting state senator on the county
commission, and `office_terms` would have accepted it. **Never read a roster out of a boundary layer.**
Name check across all twelve: Bernard was the **only** near-collision, and he is not on this roster.

### 🔴 The Clerk's seat — three holders in fourteen months, and the one modelling decision

| When | What |
| --- | --- |
| 2021-01-05 | **Joseph Abruzzo** takes office as elected Clerk; re-elected Nov 2024. |
| 2025-06 | Abruzzo **resigns**, becomes the appointed County Administrator. |
| 2025-08-19 | **Michael A. Caruso** appointed Clerk by the Governor, sworn in; he resigned his Florida House seat (**HD-87**) to take it. |
| **2026-08-18** | The Governor **suspends** Caruso — **suspended, not removed** (Fla. Const. art. IV §7: the Senate removes or reinstates). |
| **2026-08-18** | **Chief Judge Glenn Kelley (15th Judicial Circuit)** appoints the Chief Deputy Clerk, **Shannon Ramsey-Chessman**, as **Clerk Ad Interim**, effective the same day. |

**DECISION: she is seated** — `2026-08-18`, `day`, `appointed`. The office is **NOT** flagged vacant.
Someone is holding it by court order and her own office publishes her as its holder; a vacancy flag
would tell a Palm Beach voter there is no Clerk. `offices.description` carries the chain in plain words.
⚠ **Rejected alternative, recorded so it is not re-litigated:** `is_vacant = true,
vacant_since = 2026-08-18`. That matches FL-3's Felts handling, but Felts had died and nobody was
performing the office.
⚠ **Caruso's and Abruzzo's own closed terms are deliberately NOT written** — consistent with FL-2's five
vacancies and FL-3's Felts, and `how_ended` has no value for "suspended".
🔴 **Re-check this seat before any later Palm Beach work.**

⚠ **HD-87 is the seat Caruso vacated**, and it is one of this wave's three probe answers. Emily Gregory
holds it now, post-special-election, and FL-2's row is current.

### 🔴 Two appointments — a first for the Florida slice

FL-2, FL-3 and FL-4 wrote `how_started = 'elected'` for all 190 people between them.

- **Wendy Sartory Link**, Supervisor of Elections: *"First appointed in 2019, elected in 2020, and
  re-elected in 2024."* Her continuous occupancy starts with the **2019 appointment** →
  `2019-01-01`, **`year`** precision. No month is published; do not derive one from the news cycle.
- **Shannon Ramsey-Chessman**, Clerk Ad Interim: `2026-08-18`, `day`.

⚠ **A gubernatorial appointment is the NORMAL mechanism for a Palm Beach county vacancy** (art. IV
§1(f)), and District 3 is the worked example Manatee lacked: **Mike Barnett was appointed to District 3
in 2023** after Dave Kerner resigned to lead the FL Department of Highway Safety and Motor Vehicles,
then **lost the 2024 election** to Joel Flores. Manatee's Governor left its vacancy empty; Palm Beach's
filled it. **Same mechanism, opposite choice.**

### 🔴 The seven districts do NOT tile the TIGER county — 155.54 sq mi is the Atlantic

| Quantity | Value |
| --- | --- |
| Union of the 7 districts | 2,227.669 sq mi (self-overlap 0.012) |
| TIGER county `12099` | 2,383.201 sq mi |
| **Uncovered** | **155.5381 sq mi** |
| Overhang | 0.0060 sq mi |

The Leon gate ("uncovered ≤ 0.25 sq mi") **fails here on a correct layer** — the Bradenton land-only
lesson at county scale and 600× larger. The uncovered area is **one coherent offshore part**,
155.5209 sq mi with an interior point at `-80.0090, 26.6436`; the next-largest is **0.0019 sq mi**.
TIGER's county polygon runs to the state's Atlantic limit; the districts stop at the shoreline.
**Lake Okeechobee's Palm Beach share IS inside District 6** and is not part of the gap.

🔴 **THE CROSS-CHECK SERVICE CARRIES THE SAME WATER AS AN UNASSIGNED BLANK ROW**, matching the gap to
**0.2187 sq mi**. So the gate asserts **structure, not slack**: overhang ≤ 0.05, self-overlap ≤ 0.05,
**exactly one** uncovered part above 0.05 sq mi, that part east of `lon -80.05`, its area in 150…160,
and it matches the blank row. **Never widen this into a 156 sq mi tolerance** — the smallest district
is 36.6 sq mi, so a flat tolerance that size would silently accept a whole missing district.

🔴🔴 **WHICH HALF OF THAT GATE FIRES DEPENDS ON WHETHER THE MISSING DISTRICT IS COASTAL — PROVED BY
BREAKING IT BOTH WAYS.** Removing **District 7** (coastal) merges its area into the ocean gap, so the
part count stays at **1** and only the **area band** catches it (208.13 sq mi). Removing **District 6**
(landlocked) produces a genuine **second part** (2 parts, 1,749.72 sq mi). **Neither assertion alone is
sufficient**, and the plan had called the part count the load-bearing one.

### Geography — three services, and only one is both current and independent

Base: `https://services1.arcgis.com/ZWOoUZbtaYePLlPw/arcgis/rest/services`

| Service / layer | Rows | Field | Verdict |
| --- | --- | --- | --- |
| **`Commissioner_Districts/0`** (`ENG.COMM_DIST_PY`) | 7 | `DISTRICT` **SmallInteger** | ✅ **PRIMARY** — behind the county's open-data entry |
| `CountyCommission_2022/0`, layer named **`CountyCommission_2026`** | **8** | `CC` **text** | ✅ **CROSS-CHECK** — genuinely independent, 0.018…0.731 sq mi per district |
| `County_Commission_Districts/0` | 7 | `DISTRICT` | ⚠ **DECOY** — near-copy of the primary, and a **four-year-stale** `NAME` roster |

🔴 **The cross-check service is NAMED 2022 and its LAYER is named `CountyCommission_2026`.** Neither
name is authority for the vintage; the geometry comparison is. **Do not pick a service by its name.**
🔴 **It returns EIGHT rows and the eighth is BLANK** (`CC = ' '`) — the Atlantic. A row-count gate of 7
against it fails on correct data. The loader turns that blank row into the control that *explains* the
uncovered area.
⚠ `County_Commission_Districts` still reads `DAVE KERNER` for D3 (left 2022) and `MACK BERNARD` for D7.

⚠ **A THIRD PROJECTION FAMILY**: NAD83(HARN) StatePlane Florida East FIPS 0901, **US survey feet** —
not Manatee's EPSG:2237, not Leon's EPSG:3857. `outSR=4326` is load-bearing, and the post-insert check
reads **`ST_SRID` from the database** because projected feet store without error and every probe then
comes back empty.
⚠ **`Shape__Area` is NOT the value to gate on** — District 6 stretches far west of that zone's best fit.
⚠ **All seven polygons landed `ST_IsValid`, single-part, no `ST_MakeValid`.** Areas matched the recorded
literals to **0.00 %**.
⚠ `X0039` is written `state = 'fl'`, matching `X0036`/`X0037`/`X0038`. **`geofence_boundaries.state` is
2-digit FIPS for TIGER layers and the lower-case code for the private `X` layers** — an inconsistency in
prod, not a choice this wave made.

### The acceptance probe

`scripts/verify-palm-beach-probes.sql`. Anchor **Palm Beach County Governmental Center, 301 N Olive
Ave**, `-80.051906016174, 26.71529321541` — one clean Census match.

🔴 **THREE required answers, not four, and the absence is ASSERTED rather than commented.** All PASS:
**Commission District 7 (Bobby Powell Jr.) · HD-87 (Emily Gregory) · SD-24 (Mack Bernard)**, plus a
fourth assertion that all **5** constitutional officers answer countywide, and a fifth that the West
Palm Beach place polygon returns **exactly 0** seats. That fifth one matters: a comment cannot notice if
West Palm Beach is ever seated by another wave.

Controls: **Fort Lauderdale** (Broward, south) returns nothing; **Belle Glade** (40 miles west, inside
the county) returns District 6 and the five officers and **no** District 7. FL-4 had only a negative
control; a negative control alone cannot distinguish "correctly excluded" from "the query cannot fire".

🔴 **THE COLLISION DEMO IS THE RICHEST IN THE SLICE — THREE WRONG ROWS, ONE IN EACH DIRECTION:**

| label | matched through | why wrong |
| --- | --- | --- |
| **Monroe County** | `12087` `G5220` | HD-87's `sldl` polygon → a **county** in the Florida Keys, ~200 miles away |
| **State House District 24** | `12024` `G5210` | SD-24's `sldu` polygon → an `sldl` **district** (Ryan Chamberlin, north-central FL) |
| **State House District 99** | `12099` `G4020` | **Palm Beach County's own polygon** → HD-99 (Daryl Campbell, Broward) |

### 🔴 Toolchain lessons

- **Only ONE host 403s `curl`**: `mypalmbeachclerk.com`, and a full browser header set does not help.
  **Leon needed Playwright for six hosts.** Everything else on Palm Beach answers `curl` normally.
- 🔴 **APOSTROPHES INSIDE A psql `\echo` BREAK THE SCRIPT.** Three heading lines carried them and each
  produced `error: unterminated quoted string`, swallowing the following heading lines. **psql continues
  past it**, so the probe still ran and still reported PASS — the damage is to the headings that explain
  what the numbers mean. FL-3's and FL-4's probes happened to have none. ▶ **Grep any new probe for an
  apostrophe on an `\echo` line before running it.**
- 🔴🔴 **FL-4's `HEADER` TEMPLATE WAS NEVER RE-POINTED WHEN IT COPIED FL-3'S GENERATOR**, so `CC_0011`,
  `CC_0012` and `CC_0013` were **applied to prod** citing "wave FL-3", FL-3's plan, FL-3's roster,
  FL-3's generator name, and a collision example measured at Bradenton City Hall. **Fixed 2026-08-28 by
  REGENERATING**, which proved the generator still reproduces the applied SQL: 24 changed lines per
  file, every one a comment, **zero non-comment lines**, and all three re-run clean. FL-5's header
  interpolates `WAVE`/`PLAN`/`ROSTER_REL`/`GENERATOR` constants. ▶ **Every future wave: verify the
  header after copying a generator, and verify a rename by REGENERATING rather than trusting `sed`.**
- 🔴 **`splitName()` REQUIRED A COMMA BEFORE A SUFFIX.** FL-3's and FL-4's regex matches
  `Charles R. "Rick" Wells, Jr.` and **not** `Bobby Powell Jr.` Left alone it would have written
  `last_name = 'Jr.'` with "Powell" discarded as a middle name — a politician row whose surname is a
  suffix, inserted with no error. Widened in FL-5's generator only.
  ⚠ **FL-4's and FL-3's generators still carry the narrow version.** Harmless for their applied data,
  but **FL-6 must widen it** before a suffixed name appears.
- **The party guard needed widening AGAIN.** FL-3 tested `(R|D|NPA|I)`; FL-4 added `DEM`. Palm Beach's
  filing report also prints **`(WRI)`** and its results feed suffixes contest names **`- REP`** /
  **`- DEM`**.
- **One migration has no ordering caveat.** FL-4's plan had to warn that its people-half would fail
  alone against untouched prod, and warn against concatenating files to get around it — which is how
  FL-3 committed `CC_0008` in autocommit.

### Verification, 2026-08-28

All seven Florida local migrations (`CC_0008` … `CC_0014`) **re-run as clean no-ops**, so the shared
`-(1240000 + n)` band guard holds in both directions. `tsc`, `check:occupancy`, `check:migrations`,
`check:child-county` green; `check:child-county` unchanged at **7,245 children / 0 stale**, confirming
that an `X`-code load needs no matview refresh. `check:reachability` reports **no new bucket**
(BAD_GEOMETRY 5, DEAD_GEOGRAPHY 17, UNREACHABLE 38 — all at baseline).
**`offices_missing_terms` unchanged at 820 / 165 / 655** against a 699 unflagged threshold.

### ▶ Open, carried forward

- ⚠ **THREE commission seats are on the November 2026 ballot — Districts 2, 4 and 6.** **Gregg K. Weiss
  (D2) is term-limited** and is not among the filings; no Republican qualified for D2, so its August
  Democratic primary was a **Universal Primary Contest** and **that seat changes hands in November**.
  Woodward (D4) and Baxter (D6) are both qualified for re-election. ▶ **Re-check Palm Beach after the
  general, before FL-7 assets.**
- ▶ **The Clerk's seat is live** — re-check before any later Palm Beach work.
- ▶ **12 people, 0 headshots.** Palm Beach's stage-5 debt.
- ▶ **Palm Beach's banner key is decided but unnamed** — its own COUNTY key, not the Florida state
  banner (which is a Miami skyline and would collide with Miami's at FL-6). Naming it and choosing the
  composition is FL-7.

## FL-6 — Miami and Miami-Dade County (applied 2026-08-30)

Plan: [`2026-08-29-knight-fl-wave-6-miami-miami-dade.md`](../../docs/superpowers/plans/2026-08-29-knight-fl-wave-6-miami-miami-dade.md).
Roster evidence: `backend/data/seed-miami-dade-2026/ROSTERS.md`.
**The largest wave in the slice by a factor of two**, and the one that closes stages 3 and 4.

| | Offices | Seated | Chambers | Districts created |
| --- | --- | --- | --- | --- |
| **City of Miami** — City Commission | 5 | 5 | 1 | 5 × `X0041` |
| **City of Miami** — Office of the Mayor | 1 | 1 | 1 | 1 citywide (`1245000` `G4110`) |
| **Miami-Dade** — Board of County Commissioners | 13 | 13 | 1 | 13 × `X0040` |
| **Miami-Dade** — Office of the Mayor | 1 | 1 | 1 | *(reuses `12086`)* |
| **Miami-Dade** — Elected Officials | 5 | 5 | 1 | *(reuses `12086`)* |
| **Total** | **25** | **25** | **5** | **18 new + 1 citywide** |

**0 vacancies.** `external_id` band **`-1240109` … `-1240081`, 24 new rows** — 25 people, because one
is reused. Date precision: **23 `day`, 2 `month`, 0 `year`, 0 `unknown`.** `how_started`:
**21 `elected`, 4 `appointed`.**

**Two governments, not one.** Miami-Dade is **not** a consolidated city-county — unlike
Nashville/Davidson. Both governments name a chamber `Office of the Mayor`, and both use the office
titles `Mayor` and `Commissioner, District 1`…`District 5`. 🔴 **Every chamber lookup must be scoped
by `government_id` and every district lookup must pair `geo_id` with `mtfcc` AND `district_type`**, or
the insert fans out silently.

### 🔴🔴 The first REUSE in the slice — 215 people over four waves, then one

**`Oliver Gilbert`, `external_id -1212402`**, was already in prod with no office, seeded by the FL 2026
US House wave: he won the Democratic primary for FL-24 on 2026-08-18 while sitting as Miami-Dade
Commissioner for District 1. FL-6 therefore writes **19 county terms from 18 new politician rows**.

🔴 **Getting this wrong produces two Oliver Gilbert rows — one a candidate, one a commissioner — and
nothing errors.** The gate asserts that exactly one politician row is named Oliver Gilbert and that
`-1212402` holds Commission District 1.

⚠ His politician row reads `is_incumbent = true` while his **race** row reads `is_incumbent = false`.
Both are correct: a sitting officeholder, and a non-incumbent for the seat he is contesting. **Do not
"fix" either.**

⚠ **The band guard's shape changed, and the plan's version was wrong.** Its draft asserted that
`-1240093` was "Gilbert's slot, deliberately left unused". The roster does not reserve a gap — it skips
the reused person and continues, so `-1240093` is Keon Hardemon. The invariant that matters is
**"exactly one id outside the new sub-range, and it is the declared reuse"**. Reserving a cosmetic gap
is not the check.

### 🔴🔴 Two anchors, because one of them cannot return four answers

| | Miami City Hall | Miami-Dade Government Center |
| --- | --- | --- |
| Geocode | `-80.234992579394, 25.728661855119` | `-80.196332709513, 25.775078850443` |
| City commissioner | **D2** — Damian Pardo | **D5** — Christine King |
| County commissioner | **D7** — Raquel A. Regalado | **D5** — Vicki L. Lopez *(appointed)* |
| Countywide | Mayor + 5 officers = **6** | Mayor + 5 officers = **6** |
| State senator | **SD-38** — Alexis Calatayud | **SD-36** — Ileana Garcia |
| State representative | **HD-113 — VACANT** | **HD-109** — Ashley Viola Gantt |
| Answers | **3 of 4** | **4 of 4** |

🔴 **HD-113 returns ZERO officials at Miami City Hall, and the probe asserts it AT ZERO.** It is the
only assertion in the slice whose PASS condition is an empty result. Vicki Lopez resigned the seat in
November 2025 and the SOE confirms it is filled at the **November 2026 general**, not by special
election. FL-2 predicted this; asserting it makes the warning testable instead of remembered.

⚠ **Do NOT drop City Hall and keep only the Government Center to make the numbers look better.** The
vacancy is the truth about City Hall's address.

### 🔴🔴 The chain reaction: one person's move explains three offices in this wave

| Step | What |
| --- | --- |
| 1 | **Eileen Higgins** held Miami-Dade Commission **District 5**. |
| 2 | She vacated it to run for **Mayor of Miami** and won the **2025-12-09** runoff with 59% — the first Democrat elected Miami mayor since 1997, and the first woman. |
| 3 | The **Commission appointed Vicki L. Lopez** to District 5, on a **7–5 vote**. |
| 4 | That vacated **HD-113**, which is Miami City Hall's state-house district and is still empty. |

🔴 **A Miami-Dade Commission vacancy is filled by the COMMISSION'S OWN VOTE.** Palm Beach's and
Manatee's run through Fla. Const. art. IV §1(f) — the Governor. **Never inherit the vacancy
mechanism.**

### 🔴🔴 FOUR appointments, not the two the plan predicted — and not one appointing authority

The SOE roster marks **two** commissioners `Appointed` with a blank term end: D5 Lopez and D6 Natalie
Milian Orbis. **Two more spans began with an appointment and the SOE hides them, because both holders
have been elected since:**

| Seat | Who | When | By whom |
| --- | --- | --- | --- |
| D5 | Vicki L. Lopez | 2025-11-19 | Commission, 7–5 |
| D6 | Natalie Milian Orbis | 2025-05-06 | Commission |
| **D8** | **Danielle Cohen Higgins** | **2020-12-07** | **Commission, 10–1** |
| **D11** | **Roberto J. Gonzalez** | **2022-11-23** | **Gov. Ron DeSantis** |

🔴 **"Appointed" does not imply the same appointing authority.** Three are Commission votes; one is a
gubernatorial appointment. `ROSTERS.md` records who appointed, per row.
🔴 **A roster's "Appointed" flag describes the CURRENT term, not how the occupancy began.** Reading it
as the latter under-counts by half.
▶ The gate asserts the **count AND the four titles**, because a count alone passes if an elected
member is mislabelled.

### 🔴🔴 `12086` collides with a NEW YORK ZIP CODE — a second failure shape

`12086` is Miami-Dade County (`G4020`), **State House District 86** (`G5220`) **and ZIP code 12086 in
New York** (`G6350`). Fourth Florida county in four waves with a `geo_id` collision, after
12081/HD-81, 12073/HD-73 and 12099/HD-99 — and the first where one arm is **in another state**.
Measured: **40 of Florida's 67 county `geo_id`s have a New York ZCTA twin** in `geofence_boundaries`.

🔴 **The two failure shapes are different and the probe demonstrates both.** A `G5220`/`G4020` twin
returns a **WRONG OFFICIAL**; the ZCTA polygon is 1,300 miles away, so `ST_Covers` yields **nothing**
and the county vanishes **SILENTLY**. Unpaired, Miami City Hall returns three wrong rows: Santa Rosa
County via the HD-113 polygon, HD-38 via the SD-38 polygon, and HD-86 via the county polygon.

### 🔴🔴 Miami-Dade publishes FOUR polygon vintages and a geometry-less lookalike

| Service | Rows | Geometry | Verdict |
| --- | --- | --- | --- |
| `CommissionDistrict_gdb/0` | 13 | polygon | ✅ **PRIMARY** — matches the county page |
| `CommissionDistrict2011/0` | 13 | polygon, **same schema** | 🔴 **DECOY** — Monestime, Heyman, both long gone |
| `CommissionDistrict2001_gdb`, `…1992_gdb` | 13 | polygon | historical |
| `TBLCOMMISSIONDISTRICT/0` | 13 | **NONE — a table** | 🔴 **DECOY**, and a cross-check against it compares with nothing |

🔴🔴 **A SPOT CHECK ON DISTRICT 1 WOULD PASS ON THE WRONG MAP.** Symmetric difference, current vs
2011: **District 1 moved 0.136 sq mi; District 9 moved 126.1.** So a vintage gate must use a district
that actually moved — 9, 8 or 7 — and carry all thirteen literals. **Any single district picked at
random has a real chance of passing on a stale map.**

⚠ **A service's name is not authority for its vintage — third wave running.** Miami's
`Commission_Districts_New` holds the OLDER data edit (2025-06-24) than the primary (2025-12-17,
refreshed right after the December runoff). Compare Palm Beach's `CountyCommission_2022` containing
layer `CountyCommission_2026`.
⚠ **`Commission_Districts.ADDRESS` IS FABRICATED** — D1 `3500 Pan American Drive`, D2 `3501`, D3
`3502`, D4 `3503`, D5 `3504`, City Hall's address incremented per district. **Never read it.**

### 🔴 Miami-Dade's districts tile the county EXACTLY — the opposite of Palm Beach

| Quantity | Miami-Dade (13) | Palm Beach (7) |
| --- | --- | --- |
| Uncovered | **0.0315** sq mi | **155.5381** sq mi |
| Overhang | 0.0320 sq mi | 0.0060 sq mi |
| Self-overlap | **0.0000** sq mi | 0.012 sq mi |

🔴 **FL-5's structural gate FAILS HERE ON CORRECT DATA.** It requires exactly one uncovered part above
0.05 sq mi, offshore, in a 150–160 sq mi band. Miami-Dade leaves no such gap: its districts cover
Biscayne Bay and the offshore water Palm Beach's stop short of. A Leon-style tight tolerance was used
instead — uncovered, overhang and self-overlap each ≤ **0.25** sq mi.

🔴 **Two adjacent counties, opposite conventions, and neither gate is portable. MEASURE THE TILING
BEFORE CHOOSING THE GATE, EVERY TIME.**

⚠ District 9 is **1,111 sq mi** and District 13 is **24.3** — a **46× range**. Percentage tolerance
only.

### The acceptance probe

`backend/scripts/verify-miami-dade-probes.sql`. Eleven assertions across the two anchors, all PASS,
plus the collision demonstration, the ZCTA arm, per-body seat counts, per-district office counts, the
zero-offices-without-a-term check, a rulings block and three controls.

**Hialeah — `-80.2781, 25.8576` — is the load-bearing control**: a large incorporated city inside
Miami-Dade that is **not** the City of Miami. It must return **7 county offices and ZERO city ones**.
It is the only check that would catch a city layer that has quietly become a county layer. Fort
Lauderdale (Broward) and Key West (Monroe) return 0 and 0.

⚠ **One ruling had to be SCOPED after it read 33 before the apply.** "Commissioner offices on the
countywide district" is only zero *for this wave*: Leon and Manatee each seat two at-large
commissioners countywide and Tallahassee five citywide, all correct. **An unscoped ruling counts other
waves' legitimate rows and reads as a failure.** Run the probe BEFORE applying — that is what caught it.

### 🔴 Publisher disagreements, and the rules chosen

- **THREE published titles for one office, from three arms of the same county.** SOE roster
  `Clerk of the Circuit Court and Comptroller`; county Constitutional Offices page and the Clerk's own
  site `Clerk of the Court and Comptroller`. **Decision: prefer the OFFICE'S OWN site.** That makes
  **four variants across four counties**. Nothing joins on `title`; the rule is recorded so the next
  wave does not re-litigate it.
- **All five constitutional officers share `term_start = 2025-01-07`**, at `day` precision — a single
  published date for five people, which no earlier Florida wave had. Amendment 10 (adopted
  2018-11-06) forced the five independently elected offices. ⚠ **"First elected" is true of some and
  not others** — Sheriff, Tax Collector and Supervisor of Elections were created as elected offices;
  Property Appraiser and Clerk already existed. **Do not write "first" into any field.**
- **The commission page prints `Oliver G. Gilbert, III` and `René Garcia`; the SOE PDF prints
  `Oliver Gilbert` and `Rene Garcia`** — two publishers, two forms, including a dropped accent. Decided
  per person, alternates recorded as aliases.
- 🔴 **FOUR REPEATED SURNAMES INSIDE THE WAVE'S OWN ROSTER**: Higgins (Eileen, Mayor of Miami / Danielle
  Cohen Higgins, D8), Regalado (Tomas, Property Appraiser / Raquel A., D7), Garcia (Alina, Supervisor
  of Elections / Rene, D13), Fernandez (Dariel, Tax Collector / Juan Fernandez-Barquin, Clerk). Two are
  two-word surnames. **Name matching is unsafe WITHIN this wave, not only against prod.** Every
  identity decision keys on `external_id`; the one reuse is justified by a verified biography, never by
  a name match.

### 🔴 The SOE roster PDF — authoritative for structure, stale for occupancy

`https://www.miamidade.gov/elections/library/reports/elected-officials.pdf`, *"Elected Officials
Information, As of June 4, 2026"*, 7 pages, `curl`-reachable.

⚠ **It stops at the county line — there are NO municipal offices in it.** Miami's city roster comes
from `miami.gov`.
⚠ **Its as-of date is load-bearing.** It still lists Daniel Anthony Perez in HD-116, which prod records
as vacant since 2026-08-22. **Authoritative for titles and structure; three months stale for
fast-churning occupancy.**
⚠ **`pdftotext` here is Xpdf 4.00, not Poppler — there is no `-bbox`. Use `-table`;** `-layout`
misassigns every row of this PDF.

### 🔴 State Attorney and Public Defender — FL-5's ruling confirmed, the other way round

FL-5 excluded them as **circuit** offices over the objection of Palm Beach's own page, which lists them
among its "constitutional officers". **Miami-Dade's publishers agree with FL-5**: the Constitutional
Offices page lists five and neither of these, and the SOE PDF files `State Attorney — Katherine
Fernandez Rundle` and `Public Defender — Carlos J. Martinez` under its **`STATE`** heading, beside the
Governor.

🔴 **The 11th Judicial Circuit is coterminous with Miami-Dade exactly as the 15th is with Palm Beach —
same law, same geography, opposite publisher behaviour.** That is the strongest available evidence
that FL-5 was right and Palm Beach's page was simply wrong. **Not seated here either.**

### ▶ Out of scope, and the largest unmodelled block in the program

🔴 **Miami-Dade's COMMUNITY COUNCILS** — an elected body no earlier Florida county had. The SOE roster
lists **~60 seats** across Community Council Areas 02–16, by subarea plus at-large plus a Commission
appointee per area, and **roughly a dozen are `Vacant`**. Excluded because they are neither a county
commission nor a constitutional officer, and spec §3 stage 4 is "commission layer + county officers".
**They are the largest single block of unmodelled elected local offices found anywhere in the program
so far.**

Also excluded: the School Board, Soil & Water, and every municipality in Miami-Dade other than Miami —
Hialeah, Miami Beach, Coral Gables and 30-odd others.

### Verification, 2026-08-30

- **All ten Florida local migrations re-run clean**: every one reaches `COMMIT` with its post-verify
  `NOTICE`, no `ERROR`, every occupancy loop reports `seated 0`, and the only non-zero `INSERT`s are
  into temp seed tables.
- **The rename was verified by regenerating and diffing all three files byte-for-byte** — FL-5's rule.
- `tsc`, `check:occupancy`, `check:migrations`, `check:child-county` all green.
- **`check:reachability` adds no new bucket** — 5 `BAD_GEOMETRY` / 17 `DEAD_GEOGRAPHY` /
  38 `UNREACHABLE`, all at baseline.
- **`offices_missing_terms` unchanged at 820 / 165 / 655.** The wave adds no vacancy and no unflagged
  row.
- ⚠ **The people half cannot be dry-run alone** — its offices do not exist until the structure half is
  applied. It was proven by running structure and people as ONE transaction ending in `ROLLBACK`, with
  the stream asserted to hold zero `COMMIT` first. **Do not simply concatenate the files**; that is
  what committed FL-3's `CC_0008` to prod in autocommit.

### ▶ Open, carried forward

- **Re-check the six Florida vacancies** — five legislative plus Manatee D1 — and write their
  predecessor terms together.
- **Re-check Palm Beach D2/D4/D6 and Miami-Dade D5/D6/D8/D11 after the November 2026 general.**
- 🔴 **If Oliver Gilbert wins FL-24 in November he resigns District 1**, which becomes another
  Commission-appointed vacancy.

## FL-7 — Florida assets (applied 2026-08-30)

Plan: [`2026-08-30-knight-fl-wave-7-florida-assets.md`](../../docs/superpowers/plans/2026-08-30-knight-fl-wave-7-florida-assets.md).
**No migration.** Banners live in the essentials repo and Supabase Storage; headshots go in through
`politician_images` via `scripts/import-headshot-candidates.py`.

### 🔴🔴 The Miami skyline moved DOWN a tier, and that dissolved the adjacency conflict

Florida's STATE banner was a Miami downtown skyline — which is also the only thing Miami's own banner
could honestly be, and spec §8.1 forbids a city repeating its state's composition. Rather than work
around it, the photograph became `cities/miami.jpg` and the state took a new frame:
**Rookery Bay, Ten Thousand Islands** (`states/FL-v2.jpg`).

🔴 **Versioned, never an overwrite.** `STATE_PANORAMA_FILES` exists because overwriting a storage
path does not reliably purge the CDN — measured on TX 2026-08-18, where the old Austin skyline still
served seconds after upload. The state banner renders for EVERY Florida address, so a stale cache
would have been state-wide.

⚠ Miami was recomposed from the **12869×3169 Commons original**, not from the shipped state asset:
that one is **1700×419, off the documented 1700×540 spec**, and reusing it would have carried the
defect down a tier.

| Key | Subject | Licence |
| --- | --- | --- |
| `cities/miami.jpg` | Miami Late Afternoon Skyline | CC BY 4.0 |
| `cities/tallahassee.jpg` | Old Capitol, east front | CC BY-SA 4.0 |
| `cities/bradenton.jpg` | De Soto National Memorial | CC BY-SA 3.0 |
| `counties/palm-beach-fl.jpg` | Whitehall, the Flagler Museum | CC BY-SA 3.0 (levelled −1.0°) |
| `states/FL-v2.jpg` | Rookery Bay, Ten Thousand Islands | CC BY-SA 4.0 |

### 🔴🔴 The banner LOOKUP was wrong, and Florida is the first slice to expose it

`CURATED_LOCAL` matched city keys by **substring**. A `miami` key hands Miami's banner to **Miami
Beach, Miami Gardens, Miami Lakes, Miami Shores, Miami Springs, North Miami and West Miami** — seven
separate cities we do not seat — and `bradenton` takes **Bradenton Beach**. Long Beach and San José
never hit it because their names have no local siblings.

Fixed with two additive changes (essentials PR #108): **`match: 'exact'` opt-in per variant**, so
every existing key keeps substring behaviour untouched, and a **`CURATED_COUNTY` tier keyed by county
GEOID**. A county cannot be keyed by city label at all: `palm beach` matches West Palm Beach and
Royal Palm Beach while matching **nothing** for Boca Raton or Jupiter, which are equally in the
county. The API already returned `county: {geoid, name}` — only the hook dropped it.

⚠ **The certification is a TWO-STAGE crop and the first attempt skipped stage one.** Production
composes a **1700×540** asset, and the browser then crops THAT, centred: desktop 6:1 shows **52.5%**
of its height, mobile 13:4 shows **96.9%**. Cropping a source straight to 6:1 takes ~17% of a 4:3
photo's height, so the Capitol arrived as the middle of a tall building and the whole first set was
rejected. **Compose the asset first, then preview both boxes.**

### 🔴 Headshots: 72 of 72, and three pipeline defects found on the way

Every one of the seven governments is at 100%. The wave began at 1 of 72.

Three defects in the shared scripts, each of which would have shipped silently:

1. 🔴🔴 **THE IMPORTER REFUSED EVERY WEBP.** Its check whitelisted JPEG and PNG magic numbers, so
   **nine officials rendered on the proof sheet and would have vanished at import** — seven Leon
   County kiosk portraits plus two campaign cutouts. Both scripts now test **decodability**, which
   enforces "never trust the extension, never trust HTTP status" more strictly than an allowlist.
2. 🔴 **THE RENDERER TURNED TRANSPARENT PIXELS BLACK** (bare `convert("RGB")`), while the importer
   flattened onto white. A PNG cutout reached the operator as a black frame with no face. **A proof
   sheet that differs from the import is worse than no proof sheet.** The crop now lives once, in
   `scripts/headshot_crop.py`, imported by both.
3. 🔴 **THE IMPORTER REFETCHED LIVE**, so it could ship different bytes than were approved. Both
   scripts now share an on-disk cache and read it first.

⚠ `COHORTS` was **hardcoded to Colorado Springs**, so the Florida wave rendered 68 faces, filtered
every one out, and printed "rendered 68" over a 7 KB page with zero images. Cohorts now come from the
data.

⚠ **Nine of the 71 needed a per-person `crop` override** — someone standing beside a banner, inside a
photo mat, or with their head at the top edge. The default centre crop decapitates them.

🔴 **`miami.gov` 403s every non-browser client**, so its portraits are not directly fetchable. The
durable answer was NOT the Wayback Machine (which then 503s under repeated fetches): **Christine
King's official portrait is re-hosted on her FIU fellowship profile at `sipa.fiu.edu`, under the same
filename**, and Rosado came from Ballotpedia's original. ▶ **When a city blocks fetching, look for an
institution that re-hosts the same official portrait.**

## Applied migrations

| Slot | File | Applied |
| --- | --- | --- |
| `CC_0006` | `CC_0006_fl_legislature_structure.sql` | 2026-08-28 |
| `CC_0007` | `CC_0007_fl_legislature_incumbents.sql` | 2026-08-28 |
| `CC_0008` | `CC_0008_bradenton_structure.sql` | 2026-08-28 |
| `CC_0009` | `CC_0009_bradenton_people.sql` | 2026-08-28 |
| `CC_0010` | `CC_0010_manatee_county.sql` | 2026-08-28 |
| `CC_0011` | `CC_0011_tallahassee_structure.sql` | 2026-08-28 |
| `CC_0012` | `CC_0012_tallahassee_people.sql` | 2026-08-28 |
| `CC_0013` | `CC_0013_leon_county.sql` | 2026-08-28 |
| `CC_0014` | `CC_0014_palm_beach_county.sql` | 2026-08-28 |
| `CC_0015` | `CC_0015_miami_structure.sql` | 2026-08-30 |
| `CC_0016` | `CC_0016_miami_people.sql` | 2026-08-30 |
| `CC_0017` | `CC_0017_miami_dade_county.sql` | 2026-08-30 |

Next free slot: **`CC_0018`**. Next free private MTFCC: **`X0042`** — `X0040` is Miami-Dade's 13
commission districts and `X0041` is Miami's 5.

⚠ `CC_0009` and `CC_0010` were **edited after being applied**, on 2026-08-28, to scope their
`external_id` band guard to their own sub-range. No data changed — only a pre-flight guard. Without it,
FL-4's eighteen rows in the same shared band would have made both FL-3 migrations refuse to re-run.
See the FL-4 toolchain note below.

⚠ `CC_0011`, `CC_0012` and `CC_0013` were also **edited after being applied**, on 2026-08-28, to
re-point their headers: FL-4 copied FL-3's generator and never changed the `HEADER` template, so all
three cited "wave FL-3", FL-3's plan, FL-3's roster and FL-3's generator name. **Comment-only — the
three files were REGENERATED rather than hand-edited, and the diff is 24 lines each, every one a
comment, with zero non-comment lines changed.** All three re-run clean. See the FL-5 toolchain note.
