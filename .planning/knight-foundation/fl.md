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
| FL-4 | Tallahassee + Leon County | — |
| FL-5 | Palm Beach County (county only) | — |
| FL-6 | Miami + Miami-Dade County | — |
| FL-7 | Florida assets (headshots + 3 banners) | — |

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
  confirmed per county from that county's charter, never inherited from the state. **Manatee is
  ANSWERED (FL-3): it is a NON-charter county, so the state template applies unmodified.** Leon, Palm
  Beach and Miami-Dade are still to be checked separately — Miami-Dade in particular IS a charter
  county.
- 🔴 **Florida county officers run on the PRESIDENTIAL cycle; county commissioners do not.** All five
  Manatee officers' terms expire **January 2029** — elected November 2024, next election 2028 — and
  none was on the 2026 ballot even though 2026 is a gubernatorial year. Commission terms expire in
  **November** of even years. Two different conventions inside one county. Check this per county
  rather than inheriting it.
- **Miami-Dade County and the City of Miami are separate governments.** Miami-Dade is not a
  consolidated city-county. Do not conflate them.
- Miami-Dade's elected **Sheriff** was restored by constitutional amendment and filled recently.
  Confirm the office is elected before seeding it.
- **Tallahassee's city commission may be entirely at-large.** If it is, no ward layer is needed and the
  citywide `place` polygon (`1270600`) carries every seat.
- **Palm Beach County has no city half**, and `buildingImages.js` is keyed by city, so its banner needs
  a decision at FL-5 — a county key, or the Florida state banner as a fallback.
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

## Applied migrations

| Slot | File | Applied |
| --- | --- | --- |
| `CC_0006` | `CC_0006_fl_legislature_structure.sql` | 2026-08-28 |
| `CC_0007` | `CC_0007_fl_legislature_incumbents.sql` | 2026-08-28 |
| `CC_0008` | `CC_0008_bradenton_structure.sql` | 2026-08-28 |
| `CC_0009` | `CC_0009_bradenton_people.sql` | 2026-08-28 |
| `CC_0010` | `CC_0010_manatee_county.sql` | 2026-08-28 |

Next free slot: **`CC_0011`**. Next free private MTFCC: **`X0038`**.
