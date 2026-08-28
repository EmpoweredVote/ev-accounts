# Knight Program — Florida Wave FL-3 (Bradenton + Manatee County) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Seat the City of Bradenton and Manatee County — **18 offices, 17 people, 1 flagged vacancy** — so that an address at Bradenton City Hall returns four answers: its ward council member, its county commissioner, its state representative and its state senator.

**Architecture:** Five stages, each independently verifiable. Two boundary loaders push locally-digitized polygons into `essentials.geofence_boundaries` under new private MTFCCs (`X0036` Bradenton wards, `X0037` Manatee commission districts) — scripts, not migrations, following `load-davidson-council-boundaries.ts`. A roster file reconciles 17 officeholders across three independent sources and reads nothing from the DB. A generator turns that file into three migrations: Bradenton structure, Bradenton occupancy, and Manatee (offices **and** people in one, per spec §3). Acceptance is the four-answer probe plus `check:reachability`, because every cheaper check passes vacuously when a term row is missing.

**Tech Stack:** TypeScript/Node 24, `tsx`, vitest, `psql` against the Supabase session pooler, PostGIS, ArcGIS FeatureServer REST.

**Spec:** `docs/superpowers/specs/2026-08-28-knight-cities-program-design.md`
**Slice notes:** `.planning/knight-foundation/fl.md`
**Tracker:** `.planning/knight-foundation/PROGRAM.md`
**Prior wave:** `docs/superpowers/plans/2026-08-28-knight-fl-waves-1-2.md` (FL-1, FL-2 — read its "Deviations found during execution" section first)

## Global Constraints

- **Migration namespace is `CC_`** (Chris Cantrell). Next free slots are `CC_0008`, `CC_0009`, `CC_0010`, measured 2026-08-28 with `check:migrations` green. **Take the numbers LAST**: write the files as `CC_wip_*.sql`, then rename + apply + commit in one go. Re-verify with `git fetch origin` and `npm run check:migrations --prefix backend` first.
- **Branch is `docs/knight-cities-program`**, which contains `origin/master` at `0a11aeb5` (verified 2026-08-28, after PRs #206, #210 and #211 merged). `git fetch origin` before reading any migration max.
- **Every migration is idempotent** (`NOT EXISTS` guards or `ON CONFLICT DO NOTHING`) and ends with a `DO $$ … $$` post-verify gate that `RAISE EXCEPTION`s on a wrong count.
- **Dry-run against prod first** by wrapping the body `BEGIN; … ROLLBACK;` through `psql "$DATABASE_URL"`, and confirm the rollback actually reverted.
- **`ev_api` cannot create objects in `essentials`.** These migrations are DML only, so `psql` works. Do **not** use the Supabase MCP for the apply — it wraps each call in its own transaction, which destroys `BEGIN; … ROLLBACK;` semantics.
- 🔴 **Always pair `geo_id` with `mtfcc` / `district_type` in a join. In Florida the collision includes the COUNTY layer.** `12081` is simultaneously Manatee County (`G4020`) and State House District 81 (`G5220`), and `12020` is both SD-20 (`G5210`) and HD-20 (`G5220`). A bare `d.geo_id = gp.geo_id` join at Bradenton City Hall returned **4 rows, 2 of them wrong people in other counties** — measured 2026-08-28, see "The collision is worse than fl.md records" below.
- **No party affiliation** on a person or an office. The Supervisor of Elections publishes `(R)` beside every name in this wave; **discard it**. Party lives on `races.primary_party`.
- **No `term_end` is written.** A future `term_end` makes a seat silently self-vacate. `office_terms` has `start_precision` but **no `end_precision`**, so a published expiry *year* cannot become a `term_end` without inventing a day.
- 🔴 **A published "Four-Year Term Expires" date is an EXPIRY, not an election date, and `term_start` is the start of continuous occupancy by that person** — not the start of the current term. Re-election does not end an occupancy. Reading an expiry as "elected four years earlier" was wrong for 5 of 17 people in the NC wave.
- **`essentials.politicians.alternate_names` is `NOT NULL DEFAULT '{}'`.** Emit an empty array, never NULL.
- **`office_current_holder` LEFT JOINs from `offices`**, so a vacancy is a NULL `politician_id`, not an absent row. Seated counts must use `count(och.politician_id)`, never `count(*)`.
- **Do not invent a date.** `start_precision` is one of `day` / `month` / `year` / `unknown`, per source, per person. If a start is genuinely unknown, write an open-ended term with `start_precision => 'unknown'`.
- **`districts.state` is lower case (`'fl'`); `governments.state` and `offices.representing_state` are UPPER case (`'FL'`).** Both conventions are live in prod. Always `lower(d.state)` when reading districts.
- **`outSR=4326` is load-bearing on every ArcGIS fetch.** Both services in this wave have a projected native SR — `BCC_DISTRICTS_LEGAL` is EPSG:3857, `WardsCityCouncil_CoB` returns 4326 only when asked. Dropping `outSR` writes projected metres into a geographic column; no row count and no `NOT NULL` catches it, and every address probe simply returns empty.
- **`cwd` resets between Bash calls.** Prefix every command with `cd /c/EV-Accounts/backend &&` in the same compound command.
- **A WAF or catch-all rejection can be HTTP 200.** Judge every Florida source by its content, never by its status code.

---

## Facts measured 2026-08-28 — do not re-derive these

Measured while planning, against production and against the publishers' own services. They are the
reason this plan can assert counts instead of discovering them.

### Pre-state: the probe scores 2 of 4 today

Bradenton City Hall is **101 Old Main Street**. ⚠ **The Census geocoder does not know "Old Main St"** —
it returns 0 matches. Old Main Street is the ceremonial name for **12th Street West**, and
`101 12TH ST W, BRADENTON, FL, 34205` geocodes to **`-82.5733305, 27.5000582`**. Use that point; the
address string in any probe must be the one that geocodes.

The correctly-guarded probe at that point returns exactly two rows today:

| district_type | label | geo_id | mtfcc | title | holder |
| --- | --- | --- | --- | --- | --- |
| STATE_LOWER | State House District 71 | `12071` | `G5220` | Representative | William Cloud "Will" Robinson, Jr. |
| STATE_UPPER | State Senate District 20 | `12020` | `G5210` | Senator | Jim Boyd |

Three candidate anchor points — city hall (`-82.5733305, 27.5000582`), the BOCC building at 1112
Manatee Ave W (`-82.5728299, 27.4954786`) and the TIGER place interior point
(`-82.5768045, 27.4897985`) — **all four answers agree across all three**: Ward 3, Commission District
3, HD-71, SD-20. The anchor is robust; HD-71/SD-20 also match the FL-1 vintage check in `fl.md`.

### 🔴 The collision is worse than `fl.md` records

`fl.md` documents the `sldl`↔`sldu` collision for districts 1–40. **The county layer collides too.**
Run without the MTFCC pairing, the same city-hall probe returns:

| label | matched via | why it is wrong |
| --- | --- | --- |
| State House District 71 | `12071` `G5220` | correct |
| State Senate District 20 | `12020` `G5210` | correct |
| State House District 20 | `12020` `G5210` | **wrong chamber** — Judson Sapp, HD-20, north Florida |
| State House District 81 | `12081` `G4020` | **wrong county entirely** — Yvette Benarroch, HD-81, Collier County, matched through the *Manatee County* polygon |

Manatee is `12081`, so this county is itself a victim. Update `fl.md` in Task 6.

### Bradenton — structure, confirmed

| Fact | Value | Source |
| --- | --- | --- |
| Legislative body | Mayor + **five-member** City Council, one per ward | `cityofbradenton.com/departments`: "The Legislative Branch of the City is comprised of the Mayor and his assistant, and the five-member City Council." |
| Wards | 5, numbered 1–5 | city nav + ward GIS layer + SOE roster, all three agree |
| Mayor's council vote | ex officio president of council, **votes only to break a tie** among the five ward members | city site; charter section to be cited in Task 3 |
| City Clerk | **appointed staff, not elected** — out of scope | SOE roster lists it without a term |
| City Hall | 101 Old Main Street (= 101 12th St W), Bradenton FL 34205 | SOE roster |

### Manatee County — structure, confirmed

| Fact | Value | Source |
| --- | --- | --- |
| Charter status | **NON-charter county** — a charter was still only being *explored* as of January 2026 | Your Observer, 2026-01-14; Manatee is not among Florida's ~20 charter counties |
| Consequence | The Fla. Const. art. VIII §1(d) template applies **unmodified**: Sheriff, Tax Collector, Property Appraiser, Supervisor of Elections, Clerk of the Circuit Court | `mymanatee.org`: "the Board of County Commissioners, together with Manatee County's **five** constitutional officers, comprise Manatee County Government" |
| Board | **7 members: districts 1–5 single-member, districts 6 and 7 at-large countywide** | `mymanatee.org`; the at-large seats' *numbers* come from the SOE only (the county page labels both rows just "At Large District") |
| Vacancy | **District 1 is vacant** | three independent confirmations, below |
| Officer election cycle | All five constitutional officers' terms expire **January 2029** — elected November 2024, next election 2028, so **none is on the 2026 ballot** | SOE "Offices Up For Election" lists no officer for 2026 |
| Commission election cycle | Expiries are in **November**, not January — a different convention from the officers in the same county | SOE roster |

### The rosters as published, 2026-08-28

**Bradenton** — six seats, all filled.

| Seat | Name | Published expiry | Note |
| --- | --- | --- | --- |
| Mayor | Gene Brown | January 2029 | |
| Ward 1 | Jayne Kocher | January 2029 | SOE misspells this "Kocker"; see defects |
| Ward 2 | Marianne Barnebey | January 2027 | |
| Ward 3 | Kemp Schuessler | January 2027 | **SOE marks "(Appointed)"** → `how_started => 'appointed'` |
| Ward 4 | Lisa Gonzalez Moore | January 2027 | |
| Ward 5 | Pam Coachman | January 2029 | |

**Manatee County** — twelve seats, eleven filled.

| Seat | Name | Published expiry |
| --- | --- | --- |
| Commissioner, District 1 | **VACANT** | (unexpired term to November 2028) |
| Commissioner, District 2 | Amanda Ballard | November 2026 |
| Commissioner, District 3 | Tal Siddique | November 2028 |
| Commissioner, District 4 | Mike Rahn | November 2026 |
| Commissioner, District 5 | Dr. Bob McCann | November 2028 |
| Commissioner, District 6 (At-Large) | Jason Bearden | November 2026 |
| Commissioner, District 7 (At-Large) | George Kruse | November 2028 |
| Sheriff | Charles R. "Rick" Wells | January 2029 |
| Tax Collector | Ken Burton, Jr. | January 2029 |
| Property Appraiser | Charles E. Hackney | January 2029 |
| Supervisor of Elections | Scott Farrington | January 2029 |
| Clerk of the Circuit Court and Comptroller | Angelina "Angel" Colonneso | January 2029 |

**18 offices, 17 people, 1 flagged vacancy.**

### 🔴 Source defects already found — resolve these, do not re-discover them

1. **The Supervisor of Elections' own two pages contradict each other on District 1.** Its
   "Elected Officials" page still lists **Carol Ann Felts, term expires November 2028**. Its
   "Offices Up For Election" page lists **"Board of County Commissioners: District 1 (2 year term)"**
   for 2026 — a two-year term exists only to fill an unexpired vacancy, so the same publisher
   corroborates the vacancy it elsewhere denies. The county's own commissioner page for Felts
   (`…/commissioners-detail/carol-ann-felts`) now has the **HTML `<title>` "Vacant"** and renders
   "The Honorable Vacant". Three confirmations; the elected-officials roster is simply stale.
   **The seat is vacant.**
2. **That county page is only half-updated**, which is the trap: the name is replaced with "Vacant"
   while the biography beneath it still reads "Elected November 2024; Third Vice Chair, 2025" with
   committee assignments through 2026. It publishes **no vacancy date**. So `offices.vacant_since`
   stays NULL unless Task 3 pins a date from a primary record — per CLAUDE.md, flag `is_vacant` and
   leave the span unwritten rather than guess.
3. **The SOE misspells Ward 1 as "Jayne Kocker".** The city's own page says **Kocher**, and the SOE's
   own email address in the same block is `jayne.kocher@bradentonfl.gov`. Two of three agree, and one
   of the two is inside the defective source. Use **Kocher**.
4. **The GIS attribute table carries stale names, and the geometry is still right.** Manatee's
   district layers carry a `COMMNAME` field; three of the four are one or two boards out of date
   (Van Ostenbridge, Satcher, Baugh, Turner all left office). This is the same lesson as
   Miami-Dade's stale `REPNAME` in `fl.md`. **Never read a roster out of a boundary layer.**
5. **The Census geocoder does not resolve "101 Old Main St."** Use "101 12th St W".

### Bradenton ward layer — the city's own service, verified

**`https://services6.arcgis.com/wl0q8tN2gn8MMx1p/arcgis/rest/services/WardsCityCouncil_CoB/FeatureServer/0`**
— owner `joel.carranza_CityofBradenton`, the city's own GIS account.

| Property | Value |
| --- | --- |
| Features | **5**, `WARD` field = `'1'`…`'5'` (text, not integer) |
| Geometry | MultiPolygon; parts per ward: W1 15, W2 10, W3 3, W4 **36**, W5 14 — annexation slivers, so a single-polygon assumption fails |
| Union area | **14.397 sq mi** |
| Sum of the layer's own `ACRES` | 9,213 ac = **14.4 sq mi** — self-consistent |

🔴 **The wards do not cover the TIGER place polygon, and that is CORRECT.** Measured against
`geo_id='1207950' mtfcc='G4110'`:

| Measure | sq mi |
| --- | --- |
| Ward union | 14.397 |
| TIGER place polygon | 17.505 |
| Place area in **no** ward | **3.211** |
| Ward area outside the place | 0.103 |

The 3.211 sq mi gap is **water**. TIGERweb's own attributes for place `1207950` are
`AREALAND = 37,152,499 m²` (**14.344 sq mi**) and `AREAWATER = 8,185,647 m²` (**3.160 sq mi**). The
ward union matches ALAND to within **0.37 %**, and the missing area matches AWATER to within 0.05 sq
mi. Bradenton sits on the Manatee River; the ward layer is land-only. **So the tiling gate must be
written against ALAND, not against the polygon's total area** — a total-area gate fails on a correct
layer, which is exactly the kind of red build that trains people to mute a gate.

### Manatee commission district layer — four services, one boundary

Manatee's ArcGIS org (`services1.arcgis.com/t03WDvnSR7gSDOB2`) publishes **four** services with
identical schemas that all plausibly claim to be the commission districts:

| Service | Layer | Native SR | `COMMNAME` vintage |
| --- | --- | --- | --- |
| **`BCC_DISTRICTS_LEGAL`** | 0 | 3857 | **current** (Ballard, Siddique, Rahn, McCann; D1 = Felts) |
| `CountyCommissionDistricts_CopyFeatures` | 0 | 3857 | stale (Van Ostenbridge, Baugh) |
| `BoCC_Districts` | 0 | 2237 | stale (Van Ostenbridge, Satcher, Turner) |
| `District_Boundaries` | **16** | 2237 | stale, identical to `BoCC_Districts` |

🔴 **All four are the SAME boundary.** Symmetric difference between `BCC_DISTRICTS_LEGAL` and
`BoCC_Districts`, reprojected to 4326 and measured geodesically:

| COMMDIST | legal sq mi | bocc sq mi | symdiff sq mi | symdiff % |
| --- | --- | --- | --- | --- |
| 1 | 586.09 | 586.09 | 0.000 | 0.00 |
| 2 | 35.93 | 35.93 | 0.000 | 0.00 |
| 3 | 216.99 | 216.99 | 0.000 | 0.00 |
| 4 | 41.33 | 41.33 | 0.000 | 0.00 |
| 5 | 83.69 | 83.69 | 0.000 | 0.00 |

**Use `BCC_DISTRICTS_LEGAL`** — current names, and "LEGAL" is the adopted-plan naming. The choice
cannot change an answer, which removes a whole risk class: the other three are free independent
controls, and Task 2 uses one as exactly that.

**The five districts tile the county exactly.** Against `geo_id='12081' mtfcc='G4020'`:

| Measure | sq mi |
| --- | --- |
| District union | 964.03 |
| County polygon | 964.03 |
| County in **no** district | **0.046** (0.005 %) |
| District outside county | 0.047 |

Both residuals are boundary-digitization noise. 🔴 **Use a tolerance, never `ST_Equals`** — two
digitizations of one boundary are never bit-identical. `0.25 sq mi` is a safe threshold: 5× the
measured residual and 250× smaller than the smallest district.

### The new private MTFCCs

`X0036` and `X0037` are both free — `X0035` (Nashville, 35 rows) is the current maximum in prod,
measured 2026-08-28. **There is no central X-code registry**; each wave hardcodes its code in its own
loader, so nothing else needs editing.

| Code | Layer | district_type | Rows |
| --- | --- | --- | --- |
| `X0036` | Bradenton City Council wards | `LOCAL` | 5 |
| `X0037` | Manatee County commission districts | `COUNTY` | 5 |

🔴 **No guard change is needed.** `MTFCC_DISTRICT_TYPE_GUARD` in `src/lib/geoIdGuard.ts:91` has a
catch-all — `gp.mtfcc LIKE 'X%' AND gp.mtfcc NOT IN ('X0001','X0002','X0003','X0004') AND
d.district_type IN ('LOCAL','COUNTY')` — which admits both. Verify this line still reads that way
before trusting it; do not edit it.

🔴 **No `geofence_child_county` refresh is needed either, and `fl.md`'s rule is over-broad.** That
matview maps only `G4110`, `G5400`, `G5410`, `G5420` children to counties
(`scripts/check-child-county-mapping.mjs:79`). FL-1 loaded `G4110` places, so it needed the refresh.
FL-3 loads only `X` codes, so it does not, and only `load-state-tiger-boundaries.ts` prints the
ACTION REQUIRED notice. Correct the blanket wording in `fl.md` in Task 6.

### Existing rows to REUSE, not recreate

| Row | Identity | Note |
| --- | --- | --- |
| Manatee County district | `essentials.districts`, `geo_id='12081'`, `mtfcc='G4020'`, `district_type='COUNTY'`, `ocd_id='ocd-division/country:us/state:fl/county:manatee'` | **already exists.** The 2 at-large commissioners and all 5 constitutional officers hang off it. Do not insert a second one. |
| Bradenton place polygon | `essentials.geofence_boundaries`, `geo_id='1207950'`, `mtfcc='G4110'`, covers city hall | loaded by FL-1 |
| Manatee county polygon | `essentials.geofence_boundaries`, `geo_id='12081'`, `mtfcc='G4020'`, covers city hall | pre-existing |
| FL government | `essentials.governments`, `'State of Florida'`, type `STATE` | the **only** FL government row; both new ones are new |

### Template rows, copied from the closest precedents

`governments` (Buncombe / Asheville shape):

| name | type | state | city | geo_id |
| --- | --- | --- | --- | --- |
| `City of Bradenton, Florida, US` | `City` | `FL` | `Bradenton` | `1207950` |
| `Manatee County, Florida, US` | `County` | `FL` | *(NULL)* | `12081` |

`chambers` — ⚠ **`chambers.slug` is a GENERATED column derived from `name_formal`; it cannot be
inserted, and a wrong `name_formal` silently yields a different slug.**

| government | name | name_formal | official_count |
| --- | --- | --- | --- |
| Bradenton | `City Council` | `Bradenton City Council` | 5 |
| Bradenton | `Office of the Mayor` | `Office of the Mayor of Bradenton` | 1 |
| Manatee | `Board of County Commissioners` | `Manatee County Board of County Commissioners` | 7 |
| Manatee | `Elected Officials` | `Manatee County Elected Officials` | 5 |

`districts` — synthetic districts carry **no `ocd_id` and no `government_id`** (matching X0032–X0035
and `Asheville Citywide`), `num_officials = 1` (Nashville's X0035 convention), `state = 'fl'`:

| label | district_type | geo_id | mtfcc |
| --- | --- | --- | --- |
| `Bradenton Citywide` | `LOCAL` | `1207950` | `G4110` |
| `Bradenton City Council Ward 1` … `Ward 5` | `LOCAL` | `bradenton-fl-council-ward-1` … `-5` | `X0036` |
| `Manatee County Commissioner District 1` … `District 5` | `COUNTY` | `manatee-fl-commissioner-district-1` … `-5` | `X0037` |

**Politician `external_id` band: `-(1240000 + n)`.** Measured empty 2026-08-28 —
`-1249999 … -1240000` holds **0** rows. FL House is `-(1220000 + n)` and Senate `-(1230000 + n)`, so
this continues the slice's own scheme without touching the 166 rows at `-1212802 … -1210101` that
ambushed FL-2. Assignments: Bradenton `n = 1…6`, Manatee commission `n = 11…17`, Manatee officers
`n = 21…25`. **`CC_0009` and `CC_0010` must each re-assert the band empty before inserting.**

### The reachability baseline has NO Florida buckets

`backend/data/address-reachability-baseline.json`, read 2026-08-28: `UNREACHABLE` 38,
`DEAD_GEOGRAPHY` 17, `BAD_GEOMETRY` 5 — and **not one `fl|` key in any of them.**

🔴 **So flagging District 1 `is_vacant` is load-bearing.** `DEAD_GEOGRAPHY` fires on
`reachable AND offices > 0 AND active_holders = 0 AND vacant_offices = 0`. An unflagged empty D1
office creates a **new `fl|COUNTY` bucket** and fails the gate. `essentials.offices_missing_terms`
counts only *unflagged* rows as drift, so the flag protects both gates at once — the same
double duty it did for FL-2's five legislative vacancies.

### Charter ruling: the Mayor of Bradenton is `voting_powers = 'full'`

The mayor is ex officio president of the council and may vote **only to break a tie**. Nashville's
Vice Mayor has a near-identical charter clause and `CC_0004` wrote that seat `non_voting` with the
tie-break in `representation_note`. **This wave rules the other way, deliberately:**

- Nashville's Vice Mayor exists *only* to preside over the council. That seat's body is the council,
  so "no vote in it" is the whole truth about the seat's power.
- Bradenton's Mayor is the **chief executive**, elected citywide on their own ballot line, and sits
  in its own `Office of the Mayor` chamber of one. The tie-break is a *council procedure*, not a
  limit on the mayoralty. Writing `non_voting` would tell a voter this executive has no vote, which
  is false.
- So: `voting_powers = 'full'`, and the tie-break rule goes in `offices.description`. **This also
  makes the record robust to the November 2026 ballot**, where an amendment would strip the mayor's
  ex officio presidency and the tie-breaking vote (reported by Pulse of Manatee — a local outlet, so
  treat it as a thing to watch, not as authority). Under this ruling that amendment changes no column.

⚠ The consequence, stated plainly because it cuts the other way: **both read paths hide
`representation_note` when `voting_powers = 'full'`**, so the tie-break rule will not render. That is
why it goes in `description`. If Chris rules for the Nashville treatment instead, the change is two
fields on one office row in `CC_0008` — `voting_powers => 'non_voting'` plus the note — and the
`offices_representation_note_required` CHECK then enforces the note automatically.

### Out of scope, deliberately

- **The Manatee County School Board** (5 elected members) and the 5 school-board-adjacent bodies.
  Spec §3 stage 4 is "commission layer + county officers"; school boards are a separate body and are
  not in the 18. Naming them here so a later reader knows they were considered, not missed.
- **Mosquito Control, Soil & Water Conservation, 7 fire districts and ~30 Community Development
  Districts.** All elected, all in Manatee, all out of scope for this program.
- **Bradenton's five neighbouring municipalities** (Bradenton Beach, Palmetto, Anna Maria, Holmes
  Beach, Longboat Key). ⚠ The SOE roster lists their seats as "Commissioner, Ward 1" — nearly
  identical to Bradenton's titles. **Scope every roster parse to the "City of Bradenton" heading**,
  or the wave silently seats Bradenton Beach's commissioners as Bradenton's.
- **Stage 5 assets** (headshots, banner). FL-7.

---

## Task 1: Bradenton ward boundaries — load 5 wards as `X0036`

**Files:**
- Create: `backend/scripts/load-bradenton-ward-boundaries.ts`
- Create: `backend/scripts/verify-bradenton-manatee-probes.sql` (grown across Tasks 1, 2 and 5)

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: 5 rows in `essentials.geofence_boundaries` with `mtfcc = 'X0036'`, `state = 'fl'`,
  `geo_id = 'bradenton-fl-council-ward-' || n` for `n` in 1..5. Task 4's structure migration joins
  on exactly those three values and must refuse to run if they are absent.

- [ ] **Step 1: Copy the Nashville loader as the starting point**

```bash
cd /c/EV-Accounts/backend && cp scripts/load-davidson-council-boundaries.ts scripts/load-bradenton-ward-boundaries.ts
```

Read `scripts/load-davidson-council-boundaries.ts` end to end before editing. It is 348 lines and
every gate in it exists because something once went wrong. Keep the structure: fetch → parse →
control points → negative control → tiling gate → `--dry-run` early exit → insert with
`ON CONFLICT (geo_id, mtfcc) DO NOTHING` → per-row `ST_IsValid` check with `ST_MakeValid` repair →
final count.

- [ ] **Step 2: Replace the header comment and the constants block**

```ts
/**
 * load-bradenton-ward-boundaries.ts
 *
 * Fetches the 5 City Council ward boundaries for Bradenton, FL and inserts them
 * into:
 *
 *   essentials.geofence_boundaries  geo_id='bradenton-fl-council-ward-1'..'-5',
 *                                   mtfcc='X0036', state='fl'
 *
 * Writes ONLY to essentials.geofence_boundaries. CC_0008 creates the district
 * rows, the government, the chambers and the offices; it refuses to run if these
 * 5 boundaries are absent.
 *
 * Wave FL-3 of the Knight Foundation cities program.
 * Spec:   docs/superpowers/specs/2026-08-28-knight-cities-program-design.md
 * Plan:   docs/superpowers/plans/2026-08-28-knight-fl-wave-3-bradenton-manatee.md
 * Slice:  .planning/knight-foundation/fl.md
 * Roster: data/seed-bradenton-manatee-2026/ROSTERS.md
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 THE TILING GATE IS AGAINST TIGER's ALAND, NOT AGAINST THE PLACE POLYGON.
 *
 * The ward layer is LAND ONLY. Measured 2026-08-28: the ward union is 14.397 sq
 * mi, the TIGER place polygon 1207950 is 17.505 sq mi, and 3.211 sq mi of the
 * place falls in no ward at all. That gap is the Manatee River, not unassigned
 * neighbourhoods -- TIGERweb's own attributes for 1207950 are
 * AREALAND 37,152,499 m2 (14.344 sq mi) and AREAWATER 8,185,647 m2 (3.160 sq mi).
 * The ward union matches ALAND to 0.37%.
 *
 * So a gate that demands the wards tile the place polygon FAILS ON A CORRECT
 * LAYER, and a red build on correct data is how a gate gets muted. This one
 * compares the ward union to ALAND instead, with a 3% tolerance.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 outSR=4326 IS LOAD-BEARING. Dropping it writes projected metres into a
 * geographic column. No row count and no NOT NULL catches it; the polygons just
 * sit in the wrong hemisphere and every address probe comes back empty.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * ⚠ WARD IS TEXT, AND WARD 4 HAS 36 PARTS. The WARD field is '1'..'5' as
 * strings, not integers -- a === 1 comparison silently matches nothing. And the
 * geometries are MultiPolygons following annexation slivers (W1 15 parts, W2 10,
 * W3 3, W4 36, W5 14), so any single-ring assumption drops most of the city.
 */

const WARDS_URL =
  'https://services6.arcgis.com/wl0q8tN2gn8MMx1p/arcgis/rest/services/' +
  'WardsCityCouncil_CoB/FeatureServer/0/query' +
  '?where=1%3D1&outFields=WARD' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

const MTFCC = 'X0036';
const STATE_CODE = 'fl';
const SOURCE = 'cityofbradenton-arcgis-WardsCityCouncil_CoB-0-2026-08-28';
const GEO_ID_PREFIX = 'bradenton-fl-council-ward-';
const PLACE_GEO_ID = '1207950';
/** TIGERweb 2024 AREALAND for place 1207950, in square metres. */
const PLACE_ALAND_SQM = 37_152_499;
const EXPECTED_COUNT = 5;
```

- [ ] **Step 3: Replace the control points**

```ts
/**
 * Control points, measured against this layer on 2026-08-28. City hall is the
 * anchor the whole wave is judged on, and all three of these agreed on all four
 * answers (Ward 3, Commission District 3, HD-71, SD-20).
 */
const CONTROL_POINTS: Array<{ name: string; lon: number; lat: number; ward: string }> = [
  { name: 'Bradenton City Hall (101 12th St W)', lon: -82.5733305, lat: 27.5000582, ward: '3' },
  { name: 'Manatee County BOCC building (1112 Manatee Ave W)', lon: -82.5728299, lat: 27.4954786, ward: '3' },
  { name: 'TIGER place 1207950 interior point', lon: -82.5768045, lat: 27.4897985, ward: '3' },
];

/**
 * 🔴 THE CONTROL OF THE CONTROL. Palmetto City Hall is across the Manatee River
 * in a different municipality. It must fall in NO Bradenton ward. Without a
 * negative control, a query that cannot fire at all still passes every positive
 * control, because "no features returned" and "wrong features returned" look the
 * same to an .includes() test.
 */
const NEGATIVE_CONTROL = { name: 'Palmetto City Hall', lon: -82.5723, lat: 27.5214 };
```

- [ ] **Step 4: Rewrite the tiling gate against ALAND**

Replace the Nashville tiling query (around line 234) with:

```ts
  const { rows: [tile] } = await pool.query(
    `WITH d AS (
       SELECT public.ST_MakeValid(public.ST_GeomFromGeoJSON($1::text)) AS g
     ), u AS (
       SELECT public.ST_UnaryUnion(g) AS g FROM d
     )
     SELECT public.ST_Area(u.g::geography)                                  AS union_sqm,
            $2::numeric                                                     AS aland_sqm,
            abs(public.ST_Area(u.g::geography) - $2::numeric)
              / $2::numeric * 100                                           AS pct_diff
       FROM u`,
    [JSON.stringify({ type: 'GeometryCollection', geometries: features.map((f) => f.geometry) }),
     PLACE_ALAND_SQM],
  );

  const pctDiff = Number(tile.pct_diff);
  console.log(
    `  Tiling gate: ward union ${(Number(tile.union_sqm) / 2_589_988.11).toFixed(3)} sq mi ` +
    `vs TIGER ALAND ${(PLACE_ALAND_SQM / 2_589_988.11).toFixed(3)} sq mi ` +
    `(${pctDiff.toFixed(2)}% apart)`,
  );
  if (pctDiff > 3) {
    console.error(
      `FAIL: ward union differs from TIGER ALAND by ${pctDiff.toFixed(2)}%, over the 3% tolerance.\n` +
      'Measured 0.37% on 2026-08-28. A jump here means the layer was re-digitized, the city ' +
      'annexed, or outSR was dropped. Do NOT widen this tolerance to get green.',
    );
    process.exit(1);
  }
```

- [ ] **Step 5: Dry-run it and read every gate line**

```bash
cd /c/EV-Accounts/backend && npx tsx scripts/load-bradenton-ward-boundaries.ts --dry-run
```

Expected, all on stdout, no writes:
- `Received 5 features`
- `Parsed wards 1..5, none missing, none duplicated`
- three control points each reporting ward `3`
- `Palmetto City Hall: in no ward (correct)`
- `Tiling gate: ward union 14.397 sq mi vs TIGER ALAND 14.344 sq mi (0.37% apart)`
- `DRY-RUN complete — all gates passed, no database writes made.`

If the tiling percentage is not ≈0.37, **stop and diagnose**; do not proceed and do not adjust the
tolerance.

- [ ] **Step 6: Load for real**

```bash
cd /c/EV-Accounts/backend && npx tsx scripts/load-bradenton-ward-boundaries.ts
```

Expected: `Inserted: 5`, `Already existed: 0`, `Repaired: 0`, `In DB now: 5 rows (0 invalid)`.

- [ ] **Step 7: Verify from the database side, independently of the loader**

```bash
cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -c "
SELECT geo_id, public.ST_GeometryType(geometry) AS gtype, public.ST_IsValid(geometry) AS valid,
       public.ST_Covers(geometry, public.ST_SetSRID(public.ST_MakePoint(-82.5733305,27.5000582),4326)) AS covers_city_hall
  FROM essentials.geofence_boundaries
 WHERE mtfcc = 'X0036' ORDER BY geo_id;"
```

Expected: 5 rows, all `valid = t`, and **exactly one** with `covers_city_hall = t` — ward 3.

- [ ] **Step 8: Commit**

```bash
cd /c/EV-Accounts && git add backend/scripts/load-bradenton-ward-boundaries.ts && git commit -F- -- backend/scripts/load-bradenton-ward-boundaries.ts <<'MSG'
feat(knight-fl): load Bradenton's 5 council wards as X0036

The city's own ArcGIS service. The tiling gate compares the ward union to
TIGER's AREALAND for place 1207950, not to the place polygon: the ward layer is
land-only, so 3.211 sq mi of the place (the Manatee River) falls in no ward and a
total-area gate would fail on correct data.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
MSG
```

⚠ **Commit with an explicit pathspec** (`-- <path>`), as above. Parallel sessions sweep each other's
staged files in both directions, and staging explicit paths is not enough on its own.

---

## Task 2: Manatee commission districts — load 5 districts as `X0037`

**Files:**
- Create: `backend/scripts/load-manatee-commission-boundaries.ts`

**Interfaces:**
- Consumes: nothing from Task 1 — the two loaders are independent and can run in either order.
- Produces: 5 rows in `essentials.geofence_boundaries` with `mtfcc = 'X0037'`, `state = 'fl'`,
  `geo_id = 'manatee-fl-commissioner-district-' || n` for `n` in 1..5. Task 4's Manatee migration
  joins on exactly those three values.

- [ ] **Step 1: Create the loader from the same Nashville base, with these constants**

```ts
/**
 * load-manatee-commission-boundaries.ts
 *
 * Fetches the 5 single-member County Commission district boundaries for Manatee
 * County, FL and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='manatee-fl-commissioner-district-1'..'-5',
 *                                   mtfcc='X0037', state='fl'
 *
 * The board has SEVEN members. Districts 6 and 7 are elected COUNTYWIDE and
 * therefore have no polygon of their own -- their offices hang off the existing
 * COUNTY district for TIGER county 12081. Loading 5 polygons for a 7-member
 * board is correct, not a shortfall.
 *
 * Wave FL-3 of the Knight Foundation cities program.
 * Plan: docs/superpowers/plans/2026-08-28-knight-fl-wave-3-bradenton-manatee.md
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 FOUR SERVICES CLAIM TO BE THIS LAYER. THEY ARE ALL THE SAME BOUNDARY.
 *
 * Manatee's org publishes BCC_DISTRICTS_LEGAL, BoCC_Districts,
 * CountyCommissionDistricts_CopyFeatures and District_Boundaries (layer 16),
 * with identical schemas and three different vintages of the COMMNAME field.
 * Measured 2026-08-28, reprojected to 4326: the symmetric difference between
 * LEGAL and BoCC_Districts is 0.000 sq mi for all five districts.
 *
 * So the choice cannot change an answer, and the other three become free
 * independent controls. This loader reads LEGAL (current names, adopted-plan
 * naming) and CROSS-CHECKS against BoCC_Districts, which is published in a
 * DIFFERENT spatial reference (2237, State Plane FL West feet, vs 3857) -- so the
 * cross-check also proves the reprojection.
 *
 * ⚠ NEVER READ A ROSTER OUT OF THIS LAYER. Three of the four services carry
 * COMMNAME values one or two boards out of date (Van Ostenbridge, Satcher,
 * Baugh, Turner all left office), and even LEGAL still names Carol Ann Felts in
 * District 1, which is VACANT. Same lesson as Miami-Dade's stale REPNAME.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 outSR=4326 IS LOAD-BEARING. This service's native SR is 3857.
 */

const LEGAL_URL =
  'https://services1.arcgis.com/t03WDvnSR7gSDOB2/arcgis/rest/services/' +
  'BCC_DISTRICTS_LEGAL/FeatureServer/0/query' +
  '?where=1%3D1&outFields=COMMDIST' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

/** Independent digitization, native SR 2237, used only as a cross-check. */
const CROSSCHECK_URL =
  'https://services1.arcgis.com/t03WDvnSR7gSDOB2/arcgis/rest/services/' +
  'BoCC_Districts/FeatureServer/0/query' +
  '?where=1%3D1&outFields=COMMDIST' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

const MTFCC = 'X0037';
const STATE_CODE = 'fl';
const SOURCE = 'manateegis-arcgis-BCC_DISTRICTS_LEGAL-0-2026-08-28';
const GEO_ID_PREFIX = 'manatee-fl-commissioner-district-';
const COUNTY_GEO_ID = '12081';
const EXPECTED_COUNT = 5;

/** Measured 2026-08-28. COMMDIST is an INTEGER in this service, unlike Bradenton's text WARD. */
const EXPECTED_SQ_MI: Record<number, number> = { 1: 586.09, 2: 35.93, 3: 216.99, 4: 41.33, 5: 83.69 };

const CONTROL_POINTS: Array<{ name: string; lon: number; lat: number; district: number }> = [
  { name: 'Bradenton City Hall (101 12th St W)', lon: -82.5733305, lat: 27.5000582, district: 3 },
  { name: 'Manatee County BOCC building (1112 Manatee Ave W)', lon: -82.5728299, lat: 27.4954786, district: 3 },
  { name: 'TIGER place 1207950 interior point', lon: -82.5768045, lat: 27.4897985, district: 3 },
];

/**
 * 🔴 THE CONTROL OF THE CONTROL. Sarasota City Hall is in Sarasota County,
 * immediately south of Manatee. It must fall in NO commission district.
 */
const NEGATIVE_CONTROL = { name: 'Sarasota City Hall', lon: -82.5387, lat: 27.3364 };
```

- [ ] **Step 2: Add the per-district area gate**

Areas are known to two decimals, so assert them. A re-digitization or a mid-decade redraw changes
them; a dropped `outSR` changes them by orders of magnitude.

```ts
  for (const f of features) {
    const dist = Number(f.properties.COMMDIST);
    const { rows: [a] } = await pool.query(
      `SELECT public.ST_Area(public.ST_MakeValid(public.ST_GeomFromGeoJSON($1::text))::geography)
              / 2589988.11 AS sq_mi`,
      [JSON.stringify(f.geometry)],
    );
    const got = Number(a.sq_mi);
    const want = EXPECTED_SQ_MI[dist];
    const pct = Math.abs(got - want) / want * 100;
    console.log(`  District ${dist}: ${got.toFixed(2)} sq mi (expected ${want.toFixed(2)}, ${pct.toFixed(2)}% apart)`);
    if (pct > 1) {
      console.error(
        `FAIL: district ${dist} is ${pct.toFixed(2)}% off its 2026-08-28 measurement.\n` +
        'Either the layer was re-digitized, the board redrew the districts, or outSR was dropped. ' +
        'Re-measure deliberately and update EXPECTED_SQ_MI in the same commit as an explanation.',
      );
      process.exit(1);
    }
  }
```

- [ ] **Step 3: Add the cross-check against the second service**

```ts
  console.log('\n  Cross-check against BoCC_Districts (independent digitization, native SR 2237):');
  const cross = await fetchGeoJson(CROSSCHECK_URL);
  const crossById = new Map<number, unknown>(
    cross.features.map((f: any) => [Number(f.properties.COMMDIST), f.geometry]),
  );
  for (const f of features) {
    const dist = Number(f.properties.COMMDIST);
    const other = crossById.get(dist);
    if (!other) {
      console.error(`FAIL: cross-check service has no district ${dist}.`);
      process.exit(1);
    }
    const { rows: [d] } = await pool.query(
      `SELECT public.ST_Area(public.ST_SymDifference(
                public.ST_MakeValid(public.ST_GeomFromGeoJSON($1::text)),
                public.ST_MakeValid(public.ST_GeomFromGeoJSON($2::text))
              )::geography) / 2589988.11 AS symdiff_sq_mi`,
      [JSON.stringify(f.geometry), JSON.stringify(other)],
    );
    const sym = Number(d.symdiff_sq_mi);
    console.log(`    District ${dist}: symmetric difference ${sym.toFixed(3)} sq mi`);
    // 🔴 A TOLERANCE, NOT ST_Equals. Two digitizations of one boundary are never
    // bit-identical. Measured 0.000 on 2026-08-28, so 0.25 is 250x smaller than
    // the smallest district and still generous.
    if (sym > 0.25) {
      console.error(
        `FAIL: the two services disagree on district ${dist} by ${sym.toFixed(3)} sq mi.\n` +
        'They agreed exactly on 2026-08-28. One of them has been updated. Settle which is the ' +
        'adopted plan from the county before loading either.',
      );
      process.exit(1);
    }
  }
```

- [ ] **Step 4: Add the tiling gate against TIGER county `12081`**

```ts
  const { rows: [tile] } = await pool.query(
    `WITH d AS (SELECT public.ST_MakeValid(public.ST_GeomFromGeoJSON($1::text)) AS g),
          u AS (SELECT public.ST_UnaryUnion(g) AS g FROM d),
          c AS (SELECT geometry AS g FROM essentials.geofence_boundaries
                 WHERE geo_id = $2 AND mtfcc = 'G4020')
     SELECT public.ST_Area(public.ST_Difference(c.g, u.g)::geography) / 2589988.11 AS county_uncovered_sq_mi,
            public.ST_Area(public.ST_Difference(u.g, c.g)::geography) / 2589988.11 AS overhang_sq_mi
       FROM u, c`,
    [JSON.stringify({ type: 'GeometryCollection', geometries: features.map((f) => f.geometry) }),
     COUNTY_GEO_ID],
  );
  const uncovered = Number(tile.county_uncovered_sq_mi);
  const overhang = Number(tile.overhang_sq_mi);
  console.log(
    `\n  Tiling gate vs TIGER county ${COUNTY_GEO_ID}: ` +
    `${uncovered.toFixed(3)} sq mi of county in no district, ${overhang.toFixed(3)} sq mi overhang`,
  );
  // Measured 0.046 / 0.047 on 2026-08-28 -- boundary digitization noise between
  // two agencies. 0.25 is a tolerance, not an equality test.
  if (uncovered > 0.25 || overhang > 0.25) {
    console.error(
      'FAIL: the 5 districts no longer tile Manatee County within 0.25 sq mi.\n' +
      'Measured 0.046 uncovered / 0.047 overhang on 2026-08-28. A real gap means addresses in it ' +
      'get NO county commissioner and nothing errors.',
    );
    process.exit(1);
  }
```

- [ ] **Step 5: Dry-run, read every line, then load**

```bash
cd /c/EV-Accounts/backend && npx tsx scripts/load-manatee-commission-boundaries.ts --dry-run
```

Expected: 5 features; per-district areas within 1 % of `586.09 / 35.93 / 216.99 / 41.33 / 83.69`;
three control points all reporting district 3; Sarasota City Hall in no district; five cross-check
symmetric differences of `0.000`; tiling `0.046 / 0.047`. Then:

```bash
cd /c/EV-Accounts/backend && npx tsx scripts/load-manatee-commission-boundaries.ts
```

Expected: `Inserted: 5`, `In DB now: 5 rows (0 invalid)`.

- [ ] **Step 6: Verify from the database side**

```bash
cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -c "
SELECT geo_id, public.ST_IsValid(geometry) AS valid,
       public.ST_Covers(geometry, public.ST_SetSRID(public.ST_MakePoint(-82.5733305,27.5000582),4326)) AS covers_city_hall
  FROM essentials.geofence_boundaries
 WHERE mtfcc = 'X0037' ORDER BY geo_id;"
```

Expected: 5 rows, all valid, exactly one covering city hall — district 3.

- [ ] **Step 7: Commit**

```bash
cd /c/EV-Accounts && git add backend/scripts/load-manatee-commission-boundaries.ts && git commit -F- -- backend/scripts/load-manatee-commission-boundaries.ts <<'MSG'
feat(knight-fl): load Manatee's 5 commission districts as X0037

Four of the county's services claim to be this layer; measured 2026-08-28 they
are the same boundary to 0.000 sq mi, so the loader reads BCC_DISTRICTS_LEGAL and
cross-checks against BoCC_Districts, which is published in a different spatial
reference and so also proves the reprojection.

Districts 6 and 7 are elected countywide and get no polygon: their offices hang
off the existing COUNTY district for TIGER county 12081.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
MSG
```

---

## Task 3: Reconcile the roster and write `ROSTERS.md`

**Files:**
- Create: `backend/data/seed-bradenton-manatee-2026/ROSTERS.md`
- Create (untracked evidence): `backend/data/seed-bradenton-manatee-2026/_*.html` — the raw source
  pulls, kept for the length of the wave

**Interfaces:**
- Consumes: nothing. **This task reads no database.** Nothing downstream can be more correct than
  this file.
- Produces: two markdown tables the Task 4 generator parses. Column headers are the contract:
  - City table: `| Seat | Slug | Name | external_id | term_start | precision | how_started | source |`
  - County table: `| Seat | Slug | Name | external_id | term_start | precision | how_started | source |`
  - `Slug` is the office key the generator matches on: `mayor`, `ward-1`…`ward-5`,
    `commissioner-1`…`commissioner-7`, `sheriff`, `tax-collector`, `property-appraiser`,
    `supervisor-of-elections`, `clerk-of-circuit-court`.
  - A vacant seat is written with `Name` = `VACANT` and empty `external_id` / `term_start` /
    `precision` / `how_started`.

- [ ] **Step 1: Pull the three source families to disk**

```bash
cd /c/EV-Accounts/backend && mkdir -p data/seed-bradenton-manatee-2026 && \
curl -sSL -A "Mozilla/5.0" -o data/seed-bradenton-manatee-2026/_soe-elected-officials.html "https://www.votemanatee.gov/elected-officials/" && \
curl -sSL -A "Mozilla/5.0" -o data/seed-bradenton-manatee-2026/_soe-offices-up.html "https://www.votemanatee.gov/offices-up-for-election/" && \
curl -sSL -A "Mozilla/5.0" -o data/seed-bradenton-manatee-2026/_city-council.html "https://cityofbradenton.com/council" && \
curl -sSL -A "Mozilla/5.0" -o data/seed-bradenton-manatee-2026/_county-bocc.html "https://www.mymanatee.org/government/government-information/board-of-county-commissioners" && \
ls -la data/seed-bradenton-manatee-2026/
```

Three independent publishers: the **Supervisor of Elections** (county-wide, covers both bodies), the
**City of Bradenton**, and **Manatee County**. Two per body, as spec §4 requires.

- [ ] **Step 2: Pull each officeholder's own page for the dates**

The rosters publish *expiry*, never a start. `term_start` is the start of **continuous occupancy by
that person**, so it must come from the person's own biography or from the swearing-in record. Pull
one page per person into the same directory. Known starting points:

- Bradenton's own news item **"Bradenton City Council Selects Leadership During Swearing-In
  Ceremony — January 6, 2025"** on `cityofbradenton.com` covers the Mayor, Ward 1 and Ward 5 (all
  three expire January 2029, so all three began that day). `day` precision.
- **Ward 3, Kemp Schuessler, is APPOINTED** — the SOE marks it. Find the council resolution or
  minutes that made the appointment. If only a month is published, `start_precision => 'month'`.
- **George Kruse (District 7, at-large) has served since before his current term.** His expiry is
  November 2028 but occupancy began earlier. Read his commissioner page; do not derive a start from
  the expiry.
- The five constitutional officers all expire January 2029, but several have served multiple terms —
  **Ken Burton, Jr. and Charles E. Hackney in particular are long-serving.** Each officer's own
  office website carries a biography. `year` precision is honest where only a year is published.

- [ ] **Step 3: Diff the sources and record every disagreement**

Four disagreements are already known and are listed in this plan's "Source defects" section:
District 1's status, the half-updated Felts page, "Kocker"/"Kocher", and the stale GIS `COMMNAME`
fields. **Re-check each one against the live source** — a defect can be fixed between planning and
execution — then look for new ones.

⚠ **Scope the roster parse to the "City of Bradenton" heading.** The SOE page lists Bradenton
**Beach**, Palmetto, Anna Maria, Holmes Beach and Longboat Key immediately after, and their seats are
titled "Commissioner, Ward 1" — close enough to Bradenton's to be seated by mistake.

- [ ] **Step 4: Check every seat for a change since the sources were last edited**

A source cannot report a change that postdates it, and a resignation is exactly what silently seats
the wrong person. This wave already contains proof: the SOE's own roster names a commissioner who has
left. For each of the 17 people, search for news since 2026-06-01. Specifically:

- Whether the **District 1** vacancy has since been filled. In Florida a county commission vacancy is
  filled by **gubernatorial appointment** (Fla. Const. art. IV §1(f)), not by the special election
  that fills a *legislative* vacancy — so unlike FL-2's five seats, this one can be filled at any
  moment and without an election. If an appointee is now in place, seat them with
  `how_started => 'appointed'` and drop the vacancy flag.
- Whether a **vacancy date** for District 1 is published anywhere. If yes, set
  `offices.vacant_since`. If no, leave it NULL — CLAUDE.md: do not write a vacancy span whose start
  date you do not know.

- [ ] **Step 5: Write `ROSTERS.md`**

Four required sections, matching `data/seed-fl-legislature-2026/ROSTERS.md`:

1. `## Sources` — a table of every URL, what it is authoritative for, and when it was pulled.
2. `## 🔴 Source defects found` — the four above plus anything new, each with which source won and why.
3. `## Charter rulings` — at minimum: (a) the Mayor's `voting_powers = 'full'` ruling and its
   reasoning, with the Bradenton charter section cited from Municode; (b) Manatee is **non-charter**,
   so the five constitutional officers are the state template unmodified; (c) the City Clerk is
   appointed staff and out of scope; (d) the school board and special districts are out of scope.
4. `## Roster` — the two tables in the exact column contract from **Interfaces** above.

- [ ] **Step 6: Assert the counts inside the file itself**

End `ROSTERS.md` with a line the generator reads and re-asserts:

```markdown
<!-- COUNTS: city_offices=6 city_people=6 county_offices=12 county_people=11 vacancies=1 -->
```

If Step 4 found District 1 filled, this line becomes `county_people=12 vacancies=0` and every count
downstream changes with it. **The generator must fail if the tables disagree with this line** — that
is what stopped FL-2's 160-vs-155 error from reaching prod as a silent `ON CONFLICT DO NOTHING`.

- [ ] **Step 7: Commit the roster (not the raw HTML)**

```bash
cd /c/EV-Accounts && git add backend/data/seed-bradenton-manatee-2026/ROSTERS.md && git commit -F- -- backend/data/seed-bradenton-manatee-2026/ROSTERS.md <<'MSG'
docs(knight-fl): reconciled roster for Bradenton and Manatee County

18 offices, 17 people, 1 vacancy. The Supervisor of Elections' two pages
contradict each other on Commission District 1: the roster still names Carol Ann
Felts, while its own 2026 ballot lists District 1 for a two-year term, which only
exists to fill an unexpired vacancy. The county's own page for her now titles
itself "Vacant". The seat is vacant.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
MSG
```

⚠ **The `_*.html` pulls stay untracked but must NOT be deleted** while the wave is open — they are
the evidence. `git grep` a filename before deleting anything untracked in `backend/data/`.

---

## Task 4: Generator — emit three migrations

**Files:**
- Create: `backend/scripts/gen-bradenton-manatee-migrations.mjs`
- Create: `backend/scripts/gen-bradenton-manatee-migrations.test.ts`
- Create (output, `_wip_` until Task 5): `backend/migrations/CC_wip_bradenton_structure.sql`,
  `backend/migrations/CC_wip_bradenton_people.sql`, `backend/migrations/CC_wip_manatee_county.sql`

**Interfaces:**
- Consumes: `data/seed-bradenton-manatee-2026/ROSTERS.md` — the two tables and the `COUNTS:` comment
  from Task 3; the `geo_id`/`mtfcc` pairs produced by Tasks 1 and 2.
- Produces three migration files. The generator itself exports, for the test:
  - `parseRosters(markdown: string) -> { city: Seat[], county: Seat[], counts: Counts }`
  - `Seat = { seat, slug, name, externalId, termStart, precision, howStarted, source }`
  - `Counts = { cityOffices, cityPeople, countyOffices, countyPeople, vacancies }`
  - `renderStructure(seats) -> string`, `renderCityPeople(seats) -> string`,
    `renderCounty(seats) -> string`

Model it on `scripts/gen-nashville-migrations.mjs` (663 lines) — same shape, same post-verify style.

- [ ] **Step 1: Write the failing parser test**

```ts
// backend/scripts/gen-bradenton-manatee-migrations.test.ts
import { describe, expect, it } from 'vitest';
import { parseRosters } from './gen-bradenton-manatee-migrations.mjs';

const FIXTURE = `
## Roster

### City of Bradenton

| Seat | Slug | Name | external_id | term_start | precision | how_started | source |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Mayor | mayor | Gene Brown | -1240001 | 2025-01-06 | day | elected | cityofbradenton-swearing-in-2025-01-06 |
| Ward 3 | ward-3 | Kemp Schuessler | -1240004 | 2024-03-01 | month | appointed | bradenton-council-minutes |

### Manatee County

| Seat | Slug | Name | external_id | term_start | precision | how_started | source |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Commissioner, District 1 | commissioner-1 | VACANT | | | | | votemanatee-offices-up-2026 |
| Sheriff | sheriff | Charles R. "Rick" Wells | -1240021 | 2025-01-07 | day | elected | votemanatee-elected-officials |

<!-- COUNTS: city_offices=2 city_people=2 county_offices=2 county_people=1 vacancies=1 -->
`;

describe('parseRosters', () => {
  it('reads both tables and the declared counts', () => {
    const r = parseRosters(FIXTURE);
    expect(r.city).toHaveLength(2);
    expect(r.county).toHaveLength(2);
    expect(r.counts).toEqual({
      cityOffices: 2, cityPeople: 2, countyOffices: 2, countyPeople: 1, vacancies: 1,
    });
  });

  it('carries how_started through instead of defaulting it', () => {
    const r = parseRosters(FIXTURE);
    expect(r.city.find((s) => s.slug === 'ward-3')?.howStarted).toBe('appointed');
    expect(r.city.find((s) => s.slug === 'ward-3')?.precision).toBe('month');
  });

  it('models a vacancy as a named absence, not a missing row', () => {
    const r = parseRosters(FIXTURE);
    const d1 = r.county.find((s) => s.slug === 'commissioner-1');
    expect(d1).toBeDefined();
    expect(d1?.name).toBe('VACANT');
    expect(d1?.termStart).toBe('');
  });

  it('keeps a double quote inside a name intact', () => {
    const r = parseRosters(FIXTURE);
    expect(r.county.find((s) => s.slug === 'sheriff')?.name).toBe('Charles R. "Rick" Wells');
  });

  it('refuses a file whose tables disagree with its COUNTS line', () => {
    const bad = FIXTURE.replace('city_people=2', 'city_people=6');
    expect(() => parseRosters(bad)).toThrow(/COUNTS/);
  });
});
```

- [ ] **Step 2: Run it and watch it fail**

```bash
cd /c/EV-Accounts/backend && npx vitest run scripts/gen-bradenton-manatee-migrations.test.ts
```

Expected: FAIL — `Failed to resolve import "./gen-bradenton-manatee-migrations.mjs"`.

- [ ] **Step 3: Write the parser**

```js
// backend/scripts/gen-bradenton-manatee-migrations.mjs
const CITY_SLUGS = ['mayor', 'ward-1', 'ward-2', 'ward-3', 'ward-4', 'ward-5'];
const COUNTY_SLUGS = [
  'commissioner-1', 'commissioner-2', 'commissioner-3', 'commissioner-4', 'commissioner-5',
  'commissioner-6', 'commissioner-7',
  'sheriff', 'tax-collector', 'property-appraiser', 'supervisor-of-elections',
  'clerk-of-circuit-court',
];

function parseTable(md, heading) {
  const start = md.indexOf(`### ${heading}`);
  if (start < 0) throw new Error(`ROSTERS.md has no "### ${heading}" section`);
  const rest = md.slice(start);
  const rows = [];
  for (const line of rest.split('\n').slice(1)) {
    if (line.startsWith('###') || line.startsWith('<!--')) break;
    if (!line.trim().startsWith('|')) continue;
    const cells = line.split('|').slice(1, -1).map((c) => c.trim());
    if (cells.length !== 8) continue;
    if (cells[0] === 'Seat' || /^-+$/.test(cells[0])) continue;
    const [seat, slug, name, externalId, termStart, precision, howStarted, source] = cells;
    rows.push({ seat, slug, name, externalId, termStart, precision, howStarted, source });
  }
  return rows;
}

export function parseRosters(md) {
  const city = parseTable(md, 'City of Bradenton');
  const county = parseTable(md, 'Manatee County');

  const m = md.match(/<!--\s*COUNTS:\s*city_offices=(\d+)\s+city_people=(\d+)\s+county_offices=(\d+)\s+county_people=(\d+)\s+vacancies=(\d+)\s*-->/);
  if (!m) throw new Error('ROSTERS.md is missing its COUNTS comment');
  const counts = {
    cityOffices: Number(m[1]), cityPeople: Number(m[2]),
    countyOffices: Number(m[3]), countyPeople: Number(m[4]), vacancies: Number(m[5]),
  };

  // 🔴 THIS IS THE FL-2 GUARD. That wave assumed 160 people for 160 offices and
  // found 155. Nothing downstream errored, because ON CONFLICT DO NOTHING
  // absorbs a missing person silently. So the file must state its own counts and
  // the tables must agree with them, here, before any SQL is emitted.
  const seated = (rows) => rows.filter((r) => r.name && r.name !== 'VACANT').length;
  const vacant = (rows) => rows.filter((r) => r.name === 'VACANT').length;
  const problems = [];
  if (city.length !== counts.cityOffices) problems.push(`city table has ${city.length} rows, COUNTS says ${counts.cityOffices}`);
  if (seated(city) !== counts.cityPeople) problems.push(`city table has ${seated(city)} people, COUNTS says ${counts.cityPeople}`);
  if (county.length !== counts.countyOffices) problems.push(`county table has ${county.length} rows, COUNTS says ${counts.countyOffices}`);
  if (seated(county) !== counts.countyPeople) problems.push(`county table has ${seated(county)} people, COUNTS says ${counts.countyPeople}`);
  if (vacant(city) + vacant(county) !== counts.vacancies) problems.push(`tables mark ${vacant(city) + vacant(county)} vacancies, COUNTS says ${counts.vacancies}`);
  if (problems.length) throw new Error(`ROSTERS.md COUNTS disagree with its tables:\n  - ${problems.join('\n  - ')}`);

  return { city, county, counts };
}
```

- [ ] **Step 4: Run the test until green**

```bash
cd /c/EV-Accounts/backend && npx vitest run scripts/gen-bradenton-manatee-migrations.test.ts
```

Expected: 5 passed.

- [ ] **Step 5: Write `renderStructure` — `CC_wip_bradenton_structure.sql`**

Emit, in this order, every statement idempotent:

1. **A pre-flight refusal.** The migration must not create offices whose district has no polygon:

```sql
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM essentials.geofence_boundaries WHERE mtfcc = 'X0036';
  IF n <> 5 THEN
    RAISE EXCEPTION 'X0036 has % rows, expected 5. Run scripts/load-bradenton-ward-boundaries.ts first.', n;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = '1207950' AND mtfcc = 'G4110') THEN
    RAISE EXCEPTION 'TIGER place 1207950 (G4110) is missing. FL-1 must be applied first.';
  END IF;
END $$;
```

2. **6 districts** — `Bradenton Citywide` (`LOCAL`, `1207950`, `G4110`) and the five wards (`LOCAL`,
   `bradenton-fl-council-ward-N`, `X0036`, `num_officials = 1`), each guarded by
   `NOT EXISTS (… WHERE geo_id = … AND mtfcc = … AND district_type = …)`. **`state = 'fl'`, lower
   case.** No `ocd_id`, no `government_id`.
3. **1 government** — `City of Bradenton, Florida, US` / `City` / `FL` / `Bradenton` / `1207950`.
4. **2 chambers** — `City Council` (`Bradenton City Council`, 5) and `Office of the Mayor`
   (`Office of the Mayor of Bradenton`, 1). ⚠ Never insert `slug`; it is generated from
   `name_formal`.
5. **6 offices**, each `NOT EXISTS`-guarded on `(chamber_id, district_id, title)`:
   - `Mayor` → Office of the Mayor chamber, `Bradenton Citywide` district, `voting_powers = 'full'`,
     and `description` carrying the tie-break rule. Use the charter's own words as quoted in
     `ROSTERS.md`, e.g. *"Ex officio president of the City Council; votes only to break a tie among
     the five ward council members (Bradenton City Charter §…)."*
   - `Council Member, Ward 1` … `Ward 5` → City Council chamber, the matching ward district,
     `voting_powers = 'full'`.
   - `representing_state = 'FL'` (**upper**), `representing_city = 'Bradenton'` on all six.
6. **A post-verify gate** asserting exactly: 6 districts, 1 government, 2 chambers with
   `official_count` 5 and 1, **6 offices, one per district, with the Mayor on the citywide district
   and exactly one Council Member per ward.** Count **per district**, not just the total — a
   total-only assertion is precisely what the `CA_0006` multi-seat bug satisfied while landing seats
   on the wrong districts.

- [ ] **Step 6: Write `renderCityPeople` — `CC_wip_bradenton_people.sql`**

1. **Re-assert the `external_id` band empty**, then insert 6 `politicians` rows with
   `alternate_names => '{}'`, `is_active => true`, and `external_id` from the roster. The FL-2
   lesson: `ON CONFLICT DO NOTHING` on a *taken* band leaves seats held by whoever already owned the
   ids, silently.

```sql
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM essentials.politicians WHERE external_id BETWEEN -1249999 AND -1240000;
  IF n <> 0 THEN
    RAISE EXCEPTION 'external_id band -1249999..-1240000 is not empty (% rows). Measured empty 2026-08-28; pick another band rather than colliding.', n;
  END IF;
END $$;
```

   ⚠ **`CC_0010` runs after this and shares the band.** Its own assertion must therefore expect
   **6**, not 0 — the number this migration inserted. Generate that number from the roster, do not
   hardcode it.

2. **6 `essentials.seat_officeholder(...)` calls**, resolving `office_id` by
   `(chamber, district geo_id + mtfcc + district_type, title)` — **never by `full_name`, never by
   `label`** — and `politician_id` by `external_id`. Pass `p_how_started` and `p_start_precision`
   from the roster per person: Ward 3 is `'appointed'`, and the precisions differ per person.
3. **A post-verify gate**: 6 offices in this government, `count(och.politician_id) = 6`,
   0 `is_vacant`, 0 rows in `essentials.offices_missing_terms` for these six, and **one row asserting
   the appointment survived** — `how_started = 'appointed'` for Ward 3. A generator that quietly
   defaults `how_started` to `'elected'` passes every count-based gate.

- [ ] **Step 7: Write `renderCounty` — `CC_wip_manatee_county.sql`, offices AND people in ONE migration**

Spec §3: shipping county offices and county people separately would push
`essentials.offices_missing_terms` above its 699-unflagged baseline for the days between the two
applies. One migration.

1. **Pre-flight refusal**: `X0037` has 5 rows; the `COUNTY` district `12081`/`G4020` **already
   exists** — assert its presence, do not create it.
2. **5 districts** — `Manatee County Commissioner District 1` … `5` (`COUNTY`,
   `manatee-fl-commissioner-district-N`, `X0037`, `num_officials = 1`, `state = 'fl'`).
3. **1 government** — `Manatee County, Florida, US` / `County` / `FL` / NULL city / `12081`.
4. **2 chambers** — `Board of County Commissioners` (`Manatee County Board of County
   Commissioners`, 7) and `Elected Officials` (`Manatee County Elected Officials`, 5).
5. **12 offices**:
   - `Commissioner, District 1` … `District 5` → BOCC chamber, the matching `X0037` district.
   - `Commissioner, District 6 (At-Large)` and `Commissioner, District 7 (At-Large)` → BOCC chamber,
     the **existing** `12081` `COUNTY` district.
   - `Sheriff`, `Tax Collector`, `Property Appraiser`, `Supervisor of Elections`,
     `Clerk of the Circuit Court and Comptroller` → Elected Officials chamber, the existing `12081`
     district.
   - `representing_state = 'FL'`, `representing_city` NULL.
6. 🔴 **Flag District 1 vacant** — `is_vacant = true`, and `vacant_since` only if `ROSTERS.md`
   publishes a date. This is the load-bearing line: the reachability baseline has **no `fl|` bucket
   at all**, so an unflagged empty office creates a new `fl|COUNTY` `DEAD_GEOGRAPHY` bucket and
   fails CI; and `offices_missing_terms` counts only unflagged rows as drift.
7. **Band assertion expecting the 6 rows `CC_0009` inserted**, then 11 `politicians` and 11
   `seat_officeholder` calls.
8. **Post-verify gate**: 12 offices, `count(och.politician_id) = 11`, exactly **1** `is_vacant` and
   it is District 1, **7 offices in the BOCC chamber** (5 on `X0037` districts + 2 on `12081`) and
   **5 in Elected Officials** — counted per district, and per chamber.

- [ ] **Step 8: Generate and eyeball all three files**

```bash
cd /c/EV-Accounts/backend && node scripts/gen-bradenton-manatee-migrations.mjs && \
wc -l migrations/CC_wip_bradenton_structure.sql migrations/CC_wip_bradenton_people.sql migrations/CC_wip_manatee_county.sql && \
grep -c 'RAISE EXCEPTION' migrations/CC_wip_*.sql
```

Every file must contain at least one `RAISE EXCEPTION` in a pre-flight and one in a post-verify gate.

- [ ] **Step 9: Grep for the two mistakes a generator makes silently**

```bash
cd /c/EV-Accounts/backend && \
echo '--- any bare geo_id join, unpaired with mtfcc/district_type? (expect none) ---' && \
grep -n "geo_id = '" migrations/CC_wip_*.sql | grep -v "mtfcc" | grep -v "^.*--" ; \
echo '--- any party word leaking in? (expect none) ---' && \
grep -niE "\((R|D)\)|republican|democrat|party" migrations/CC_wip_*.sql ; \
echo '--- any term_end being written? (expect none) ---' && \
grep -n 'term_end' migrations/CC_wip_*.sql
```

All three greps must come back empty. The first is the Florida collision; the second is the `(R)` the
SOE prints beside every name in this wave; the third self-vacates seats.

- [ ] **Step 10: Commit the generator and the test**

```bash
cd /c/EV-Accounts && git add backend/scripts/gen-bradenton-manatee-migrations.mjs backend/scripts/gen-bradenton-manatee-migrations.test.ts && git commit -F- -- backend/scripts/gen-bradenton-manatee-migrations.mjs backend/scripts/gen-bradenton-manatee-migrations.test.ts <<'MSG'
feat(knight-fl): generator for the Bradenton and Manatee migrations

Three migrations: city structure, city occupancy, and county offices-and-people
in one (spec section 3). The parser refuses a ROSTERS.md whose tables disagree
with its own declared COUNTS line -- the guard FL-2 lacked when it assumed 160
people for 160 offices and found 155.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
MSG
```

---

## Task 5: Dry-run, apply, gate, probe, commit

**Files:**
- Rename: `backend/migrations/CC_wip_bradenton_structure.sql` → `CC_0008_bradenton_structure.sql`
- Rename: `backend/migrations/CC_wip_bradenton_people.sql` → `CC_0009_bradenton_people.sql`
- Rename: `backend/migrations/CC_wip_manatee_county.sql` → `CC_0010_manatee_county.sql`
- Create: `backend/scripts/verify-bradenton-manatee-probes.sql`
- Modify: `backend/data/address-reachability-baseline.json` — **only if** the gate reports a
  legitimate new bucket, and then in the same commit with an explanation

**Interfaces:**
- Consumes: the three `CC_wip_*.sql` files from Task 4.
- Produces: prod state where the four-answer probe returns four rows.

- [ ] **Step 1: Write the four-answer probe**

```sql
-- backend/scripts/verify-bradenton-manatee-probes.sql
-- FL-3 acceptance probe. Read-only. Run before AND after the applies.
--
-- 🔴 THE MTFCC PAIRING IN THE JOIN IS LOAD-BEARING, AND FLORIDA IS WHY.
-- 12081 is both Manatee County (G4020) and State House District 81 (G5220);
-- 12020 is both SD-20 (G5210) and HD-20 (G5220). Run unpaired, this probe
-- returned 4 rows at city hall on 2026-08-28, two of them officials from other
-- counties, and nothing errored.
\pset pager off

\echo == Four answers at Bradenton City Hall, 101 12th St W (101 Old Main St) ==
\echo == Expected AFTER FL-3: Ward 3 council member, Commissioner District 3, HD-71, SD-20 ==
WITH pt AS (SELECT public.ST_SetSRID(public.ST_MakePoint(-82.5733305, 27.5000582), 4326) AS g)
SELECT d.district_type, d.label, d.geo_id, gp.mtfcc, o.title,
       coalesce(p.full_name,
                CASE WHEN o.is_vacant THEN '(flagged vacant)' ELSE '(NO TERM ROW — INVISIBLE)' END) AS holder
  FROM pt
  JOIN essentials.geofence_boundaries gp ON public.ST_Covers(gp.geometry, pt.g)
  JOIN essentials.districts d ON d.geo_id = gp.geo_id
  JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.politicians p ON p.id = och.politician_id
 WHERE lower(d.state) = 'fl'
   AND d.representation_basis = 'residency'
   AND (
     (gp.mtfcc = 'G5220' AND d.district_type = 'STATE_LOWER')
     OR (gp.mtfcc = 'G5210' AND d.district_type = 'STATE_UPPER')
     OR (gp.mtfcc = 'G4020' AND d.district_type = 'COUNTY')
     OR (gp.mtfcc IN ('G4110','G4120') AND d.district_type IN ('LOCAL','LOCAL_EXEC'))
     OR (gp.mtfcc LIKE 'X%' AND d.district_type IN ('LOCAL','COUNTY'))
   )
 ORDER BY d.district_type, o.title;

\echo == Seat and occupancy counts, per body ==
SELECT g.name AS government, c.name AS chamber,
       count(o.id) AS offices,
       count(och.politician_id) AS seated,
       count(*) FILTER (WHERE o.is_vacant) AS flagged_vacant
  FROM essentials.governments g
  JOIN essentials.chambers c ON c.government_id = g.id
  JOIN essentials.offices o ON o.chamber_id = c.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
 WHERE g.geo_id IN ('1207950','12081')
 GROUP BY g.name, c.name ORDER BY g.name, c.name;

\echo == Any FL office with no term row and no vacancy flag? (must be 0 rows) ==
SELECT o.id, d.label, o.title
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  LEFT JOIN essentials.office_terms t ON t.office_id = o.id
 WHERE lower(d.state) = 'fl' AND d.district_type IN ('LOCAL','COUNTY')
   AND t.id IS NULL AND o.is_vacant = false;
```

- [ ] **Step 2: Run the probe BEFORE applying, to record the pre-state**

```bash
cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -f scripts/verify-bradenton-manatee-probes.sql
```

Expected pre-state: **2 rows** — HD-71 Will Robinson, SD-20 Jim Boyd. Zero governments. If this does
not match, the database moved since 2026-08-28 and the plan's counts need re-measuring first.

- [ ] **Step 3: Dry-run each migration against prod, in order**

```bash
cd /c/EV-Accounts/backend && for f in CC_wip_bradenton_structure CC_wip_bradenton_people CC_wip_manatee_county; do
  echo "=== DRY RUN $f ==="
  { echo 'BEGIN;'; cat "migrations/$f.sql"; echo 'ROLLBACK;'; } | psql "$DATABASE_URL" -v ON_ERROR_STOP=1
done
```

⚠ **The three are not independent.** `CC_wip_bradenton_people` needs the offices from
`CC_wip_bradenton_structure`, so dry-running it alone against untouched prod **will fail** — that is
correct behaviour, not a bug. Dry-run the pair in one transaction to exercise them together:

```bash
cd /c/EV-Accounts/backend && { echo 'BEGIN;'; cat migrations/CC_wip_bradenton_structure.sql migrations/CC_wip_bradenton_people.sql; echo 'ROLLBACK;'; } | psql "$DATABASE_URL" -v ON_ERROR_STOP=1
```

- [ ] **Step 4: Confirm the rollback actually reverted**

```bash
cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -At -c "
SELECT (SELECT count(*) FROM essentials.governments WHERE geo_id IN ('1207950','12081')) AS govs,
       (SELECT count(*) FROM essentials.districts WHERE mtfcc IN ('X0036','X0037')) AS synth_districts,
       (SELECT count(*) FROM essentials.politicians WHERE external_id BETWEEN -1249999 AND -1240000) AS people;"
```

Expected: `0|0|0`. **Do not trust a rollback you have not checked.**

- [ ] **Step 5: Take the migration numbers, last**

```bash
cd /c/EV-Accounts && git fetch origin && cd backend && npm run check:migrations && \
ls migrations/ | grep '^CC_' | tail -5
```

`check:migrations` must be green and the highest `CC_` slot must still be `CC_0007`. Then rename, and
**fix the cross-references inside the files in the same move** — the header comments and any
`source` string that names its own slot:

```bash
cd /c/EV-Accounts/backend && \
git mv migrations/CC_wip_bradenton_structure.sql migrations/CC_0008_bradenton_structure.sql && \
git mv migrations/CC_wip_bradenton_people.sql   migrations/CC_0009_bradenton_people.sql && \
git mv migrations/CC_wip_manatee_county.sql     migrations/CC_0010_manatee_county.sql && \
sed -i 's/CC_wip_bradenton_structure/CC_0008_bradenton_structure/g; s/CC_wip_bradenton_people/CC_0009_bradenton_people/g; s/CC_wip_manatee_county/CC_0010_manatee_county/g' \
  migrations/CC_0008_bradenton_structure.sql migrations/CC_0009_bradenton_people.sql migrations/CC_0010_manatee_county.sql \
  scripts/gen-bradenton-manatee-migrations.mjs && \
npm run check:migrations && grep -rn 'CC_wip' migrations/ scripts/gen-bradenton-manatee-migrations.mjs || echo 'no CC_wip references left'
```

- [ ] **Step 6: Apply, in order, for real**

```bash
cd /c/EV-Accounts/backend && for f in CC_0008_bradenton_structure CC_0009_bradenton_people CC_0010_manatee_county; do
  echo "=== APPLY $f ==="
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "migrations/$f.sql" || { echo "STOPPED at $f"; break; }
done
```

Each must end with its post-verify `DO` block passing silently. **If one fails, stop.** Applies are
ad hoc and there is no runner; a partial apply is a real state that must be diagnosed, not retried.

- [ ] **Step 7: Run the acceptance probe — four answers**

```bash
cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -f scripts/verify-bradenton-manatee-probes.sql
```

Expected: **4 rows**.

| district_type | label | title | holder |
| --- | --- | --- | --- |
| COUNTY | Manatee County Commissioner District 3 | Commissioner, District 3 | Tal Siddique |
| LOCAL | Bradenton City Council Ward 3 | Council Member, Ward 3 | Kemp Schuessler |
| STATE_LOWER | State House District 71 | Representative | William Cloud "Will" Robinson, Jr. |
| STATE_UPPER | State Senate District 20 | Senator | Jim Boyd |

Counts: Bradenton `City Council` 5/5, `Office of the Mayor` 1/1; Manatee `Board of County
Commissioners` 7 offices / 6 seated / 1 flagged vacant, `Elected Officials` 5/5. Third query: **0
rows**.

⚠ **The Bradenton answer is an appointed member.** Ward 3's holder was appointed, not elected. Four
answers is still four answers.

- [ ] **Step 8: Run every gate**

```bash
cd /c/EV-Accounts/backend && npm run check:occupancy && npm run check:migrations && npm run check:child-county && npm run check:reachability
```

- `check:reachability` must report **no new bucket**. The `fl|COUNTY` and `fl|LOCAL` buckets do not
  exist in the baseline, so a single unflagged empty office fails it. If it does fire, the fix is
  almost certainly a missing `is_vacant` flag on District 1 — **not** a baseline edit.
- `check:child-county` should be unaffected: the matview maps only `G4110`/`G54xx` children, and this
  wave loaded only `X` codes. No refresh is needed. If it fails anyway, that assumption was wrong —
  refresh via the Supabase MCP, since it needs the `postgres` role.

- [ ] **Step 9: Measure the occupancy-drift numbers and record them**

```bash
cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -At -F ' | ' -c "
SELECT count(*) AS total,
       count(*) FILTER (WHERE is_vacant) AS flagged,
       count(*) FILTER (WHERE NOT is_vacant) AS unflagged
  FROM essentials.offices_missing_terms;"
```

FL-2 left this at 819 total / 164 flagged / **655 unflagged** against a 699 threshold. FL-3 adds
**one** flagged row (Manatee District 1) and **no** unflagged rows. Expected: 820 / 165 / 655.
An unflagged number above 655 means an office was created without a term and without a flag — the one
failure mode CI cannot catch.

- [ ] **Step 10: Commit the migrations and the probe**

```bash
cd /c/EV-Accounts && git add backend/migrations/CC_0008_bradenton_structure.sql backend/migrations/CC_0009_bradenton_people.sql backend/migrations/CC_0010_manatee_county.sql backend/scripts/verify-bradenton-manatee-probes.sql && git commit -F- -- backend/migrations/CC_0008_bradenton_structure.sql backend/migrations/CC_0009_bradenton_people.sql backend/migrations/CC_0010_manatee_county.sql backend/scripts/verify-bradenton-manatee-probes.sql <<'MSG'
feat(knight-fl): seat Bradenton and Manatee County — 18 offices, 17 people (CC_0008..CC_0010)

Bradenton: 1 government, 2 chambers, 6 districts, 6 offices, 6 people.
Manatee: 1 government, 2 chambers, 5 new COUNTY districts (the countywide
district already existed), 12 offices, 11 people, and Commission District 1
flagged vacant — the reachability baseline has no fl| bucket at all, so an
unflagged empty office would fail CI.

The four-answer probe at Bradenton City Hall now returns Ward 3, Commission
District 3, HD-71 and SD-20. The join pairs geo_id with mtfcc throughout: 12081
is both Manatee County and HD-81, and unpaired the same probe returned two
officials from other counties.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
MSG
```

---

## Task 6: Update the ledger

**Files:**
- Modify: `.planning/knight-foundation/PROGRAM.md`
- Modify: `.planning/knight-foundation/fl.md`

**Interfaces:**
- Consumes: the measured results of Task 5.
- Produces: the only durable record of where the program stands. `MEMORY.md` holds one pointer to it.

- [ ] **Step 1: Update `PROGRAM.md`**

- Slice 1 (FL): stage `3 city` → `WIP` (Bradenton done, three jurisdictions to go). Stage `4 county`
  → `WIP` (Manatee done). Neither is `✅` until all four FL jurisdictions are seated.
- Migration ledger: three rows for `CC_0008`, `CC_0009`, `CC_0010`, and **next free is `CC_0011`**.
- "Local and county seats present": replace the `every other jurisdiction | 0 | 0 | 0` line with
  measured rows for Bradenton city (6/6/0) and Manatee County (12/11/0).
- Session log: one row — what was applied, and `Next action: write the FL-4 plan (Tallahassee + Leon
  County)`.

- [ ] **Step 2: Update `fl.md`**

Five things, and three of them are corrections to what is already written there:

1. Wave table: FL-3 `✅ applied 2026-08-28 — CC_0008, CC_0009, CC_0010`. Next free slot `CC_0011`.
2. 🔴 **Correct the collision section.** It currently says the collision is `sldl`↔`sldu` for
   districts 1–40. **The county layer collides too**: `12081` is Manatee County *and* HD-81. Give the
   measured four-row unpaired probe result, because it is the cheapest possible demonstration.
3. 🔴 **Correct the matview rule.** "Every future slice must refresh the matview after a boundary
   load" is over-broad. `geofence_child_county` maps only `G4110`, `G5400`, `G5410`, `G5420`
   children, so a wave that loads only `X` codes does not need it — and only
   `load-state-tiger-boundaries.ts` prints the ACTION REQUIRED notice.
4. Add a `## FL-3 — Bradenton and Manatee` section carrying: the X-code allocation (`X0036` wards,
   `X0037` commission districts) and that `X0038` is next; the `-(1240000 + n)` band and how much of
   it is now used; the four-answer probe point and its expected answers; the ward-layer-is-land-only
   finding with the ALAND numbers; the four-identical-services finding; **Manatee is non-charter, so
   the five constitutional officers are the state template unmodified**; and the Mayor's
   `voting_powers = 'full'` charter ruling with its reasoning.
5. In "Sources for FL-3 onward", strike the Manatee line — it is answered — and leave Leon, Palm
   Beach and Miami-Dade open. **Add** that Florida county-officer terms run on the presidential
   cycle (all five Manatee officers expire January 2029, none on the 2026 ballot), which is a
   template Leon, Palm Beach and Miami-Dade will each need checking against, not inheriting.

- [ ] **Step 3: Commit**

```bash
cd /c/EV-Accounts && git add .planning/knight-foundation/PROGRAM.md .planning/knight-foundation/fl.md && git commit -F- -- .planning/knight-foundation/PROGRAM.md .planning/knight-foundation/fl.md <<'MSG'
docs(knight): record FL-3 in the ledger, and correct two FL-wide notes

The geo_id collision is not confined to sldl/sldu: 12081 is both Manatee County
and HD-81, so the county layer collides too. And the "always refresh the
child-county matview" rule is over-broad — it maps only place and school-district
children, so a wave loading only X codes does not need it.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
MSG
```

---

## Plan self-review

**Spec coverage.** §3 stage 3 (city: council-district layer + structure + occupancy) → Tasks 1, 4, 5.
§3 stage 4 (county: commission layer + officers, offices **and** people in ONE migration) → Tasks 2,
4, 5. §3.2 (consolidated city-counties keep county officers) → not applicable; Bradenton and Manatee
are separate governments, stated in Task 4. §4 wave anatomy, all seven steps: pull sources (T3.1),
diff and settle (T3.3), check for post-source change (T3.4), write `ROSTERS.md` with the four
required sections (T3.5), generate with a script (T4), dry-run with rollback (T5.3–4), take the
number last (T5.5). §4.1 standing constraints → Global Constraints, with the `G4020` collision added.
§5 gates → T5.8, all four. §5 definition of done (four answers, one probe) → T5.1, T5.7. §6 ledger →
T6. §7 headshots and §8 banners are stage 5 (FL-7), out of scope and named as such.

**Placeholder scan.** No `TBD`, no "add error handling", no "similar to Task N". Every code step
carries the actual code. The one genuinely open item — the Bradenton charter *section number* for the
mayor's tie-break — is an input the plan tells Task 3 to fetch from Municode and quote, not a gap in
the plan: the ruling itself is decided, with reasoning and with the one-line alternative if Chris
rules the other way.

**Type consistency.** `parseRosters` / `renderStructure` / `renderCityPeople` / `renderCounty` are
named identically in the Interfaces block, the test and the implementation. `Seat` field names
(`seat`, `slug`, `name`, `externalId`, `termStart`, `precision`, `howStarted`, `source`) match the
eight markdown columns in the same order, in Task 3's contract and Task 4's parser. `Counts` keys
match the `COUNTS:` comment's five fields. `geo_id` prefixes are written identically in Tasks 1/2
(producer) and Task 4 (consumer): `bradenton-fl-council-ward-` and
`manatee-fl-commissioner-district-`. MTFCCs are `X0036` city / `X0037` county throughout.

**One risk this plan cannot close.** Task 3 Step 4 asks whether District 1 has been filled by
gubernatorial appointment. If it has, the counts change from 17 people / 1 vacancy to 18 / 0, and
Task 4's `COUNTS` guard is what forces every downstream assertion to change with it rather than
drifting. That is the guard working, not the plan failing — but the executor must expect it.
