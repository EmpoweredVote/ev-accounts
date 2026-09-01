# Knight Program — Georgia Wave GA-3 (Milledgeville + Baldwin County) Implementation Plan

**Status:** PLANNED, not applied. Written 2026-09-01.
**Spec:** [`2026-08-28-knight-cities-program-design.md`](../specs/2026-08-28-knight-cities-program-design.md) ·
**Tracker:** [`PROGRAM.md`](../../../.planning/knight-foundation/PROGRAM.md) ·
**State notes:** [`ga.md`](../../../.planning/knight-foundation/ga.md) ·
**Roster:** [`ROSTERS.md`](../../../backend/data/seed-milledgeville-2026/ROSTERS.md)

GA-3 is the small pilot of the Georgia slice, as Bradenton was for Florida: an ordinary city inside an
ordinary county. Columbus-Muscogee and Macon-Bibb follow, and both are **consolidated**, so this wave
sets the Georgia county-officer template while it is still cheap to get wrong.

**Deliverable: 18 offices, 18 people, 0 vacancies.** Seven city, eleven county. Two boundary loads
(`X0042`, `X0043`) and three migrations (`CC_0027`, `CC_0028`, `CC_0029`).

---

## Global constraints

Inherited from spec §4.1 and CLAUDE.md. The ones this wave actually trips over:

- **`cwd` resets between Bash calls.** Prefix every command with `cd /c/ev-accounts-knight/backend &&`.
  🔴 The knight worktree is **`C:/ev-accounts-knight`**, on branch `knight/ga-3-milledgeville`, cut
  fresh from `origin/master` at `d980e56b`. `C:/EV-Accounts` is a different branch. A bare
  `ls migrations/` on the wrong worktree is how FL-6 nearly took a slot nine numbers low.
- ⚠ **`backend/.env` does not exist in the knight worktree.** Read `DATABASE_URL` from
  `/c/EV-Accounts/backend/.env` in the same compound command. Do not copy the file.
- **Take the migration number LAST.** Write `CC_wip_*.sql`, then rename, apply and commit in one go.
- **Pair `geo_id` with `district_type` in every join.** In Georgia the collision is three-way, and
  Baldwin proves it: `13009` is Baldwin County **and** House District 9 **and** Senate District 9 —
  all three rows are in production right now.
- `outSR=4326` on every ArcGIS fetch. `politicians.alternate_names` is `NOT NULL DEFAULT '{}'`.
  No `term_end`. No party. Always `lower(d.state)`.
- DML only, so `psql` works and the `BEGIN … ROLLBACK` dry-run is real. **Do not use the Supabase MCP
  for the apply** — it wraps each call in its own transaction.

---

## Facts measured 2026-09-01 — do not re-derive these

### Pre-state: the probe scores 2 of 4 today

Milledgeville City Hall, 119 E Hancock St, geocoded by the Census to
`-83.226730175561, 33.081230307104`:

| Answer | Today | After GA-3 |
| --- | --- | --- |
| State representative | ✅ HD-149 **Floyd Griffin** | unchanged |
| State senator | ✅ SD-25 **Rick Williams** | unchanged |
| County commissioner | ❌ Baldwin County district exists, **zero offices, no holder** | ✅ Commissioner, District *n* |
| City council member | ❌ **no LOCAL district exists in Georgia at all** (0 rows) | ✅ Council Member, District *n* |

This confirms GA-1's Milledgeville anchor (HD-149 / SD-25) against production rather than against
TIGER, and it confirms the county district is present to hang offices on.

### Gate baselines to hold

| Gate | Value 2026-09-01 |
| --- | --- |
| `offices_missing_terms` | **821 total / 166 flagged / 655 unflagged** |
| GA `LOCAL` districts | **0** |
| `essentials.politicians` rows | 86,626 |
| Highest `CC_` across all 77 remote refs | **`CC_0026`** → next free is `CC_0027` |
| Highest private MTFCC, repo **and production** | **`X0041`** → next free is `X0042` |

🔴 **The unflagged 655 is the load-bearing number.** GA-3 writes a term for every office it creates,
so all three counts must be **unchanged** afterwards — this wave creates no vacancy.

### `external_id` band

`-1331999 … -1331000` is **completely empty** in production (`0` rows). GA-2 consumed
`-1330256 … -1330001` (233 rows). GA-3 takes:

| Range | Who |
| --- | --- |
| `-1331001` … `-1331007` | the 7 city officials |
| `-1331008` … `-1331018` | the 11 county officials |

⚠ **Scope the band guard to this sub-range only.** FL-4 broke FL-3's re-run by claiming the whole
shared band; each wave asserts absence over *its own* sub-range. Here the guard is simple, because
GA-3 has **zero reuses** — the invariant is "18 rows in `-1331018 … -1331001`, and none outside it".

### Structure, confirmed against the certified ballot

**Milledgeville — 7 offices.** Source A: "Six Council members are elected to represent their district
while the Mayor is elected at-large, by all voters of the City for a four year term." Source D
independently lists seven ballot lines: `Mayor - Milledgeville` and `City Council - District 1..6`.
🔴 **All seven were on the same November 2025 ballot — the council is NOT staggered.**

**Baldwin County — 11 offices.** Five single-member commission districts and **no at-large seat**;
the Chair is elected by the Board. That is a **fourth county convention in five counties**: Manatee
5+2 at-large, Leon 5+2 at-large, Palm Beach 7 single-member, Miami-Dade 13 + a separate Mayor, Baldwin
5 with an internal chair. Plus six officers, per ruling R3 in `ROSTERS.md`.

⚠ **Consolidation is not in play here** — Milledgeville is an ordinary city (20.420 sq mi) inside
Baldwin County (268.276 sq mi). The Columbus and Macon waves are the consolidated ones.

### 🔴🔴 The obvious council-district service is the SUPERSEDED one

Baldwin County publishes city council districts inside its `ElectionGeography` layer. Milledgeville
publishes its **own** layer, `City_Council_Districts__2025__WFL1/FeatureServer/0`, titled
**"City Council Districts (2025)"** and carrying `Pop`, `DX_DEV` and `Pop_DVP` — it is a post-2020
redistricting plan, and the county's copy is not. Compared district by district, each at its own
interior point:

| City D | County copy contains that point | City sq mi | County sq mi | Symmetric difference |
| --- | --- | --- | --- | --- |
| 1 | 1 | 7.407 | 7.362 | **0.99** |
| 2 | 2 | 5.330 | 4.967 | 0.37 |
| 3 | 3 | 2.809 | 2.817 | 0.09 |
| **4** | **1** ❌ | 0.923 | 0.738 | 0.71 |
| 5 | 5 | 1.213 | 1.248 | 0.49 |
| 6 | 6 | 2.829 | 3.290 | 0.58 |

**Only District 4 fails the point test.** Three spot checks on D2, D3 and D5 would all have passed on
the wrong map. This is GA-1's ruling repeating at city scale: **when the whole map is published, test
every district — a remap leaves most of them alone.** Total city area is ~20.4 sq mi, so D1's 0.99
sq mi disagreement is 13% of that district.

**▶ Load the city's own layer. Do not load the county's copy.**

### Both layers tile their TIGER parent

| Layer | n | Union | TIGER parent | Uncovered | Beyond |
| --- | --- | --- | --- | --- | --- |
| Baldwin commission (county service) | 5 | 268.274 | `13009` **268.276** | 0.016 | 0.014 |
| Milledgeville council (county copy) | 6 | 20.422 | `1351492` **20.420** | 0.023 | 0.025 |

Both are Miami-Dade's "tiles exactly", not Palm Beach's 155.54 sq mi Atlantic hole, so the tiling gate
can be a **tolerance**, not a structural assertion. ⚠ Tiling proves the districts partition the right
*parent*; it does **not** date the internal lines. That is what the district-by-district comparison
above is for, and it is why the city layer wins.

⚠ The county commission layer has **one** publisher. The county's dedicated "County Commissioner
Districts" app resolves to the same `ElectionGeography_CommissionerDistrictsView` — a view over the
same rows. Its commissioner attributes were edited **2026-04-21** and are correct 5 of 5 against the
certified 2024 results, and the geometry tiles Baldwin to 0.006%. Accept it, and record that it rests
on a single source.

### Source defects and charter rulings

All five defects and all four rulings are written up in
[`ROSTERS.md`](../../../backend/data/seed-milledgeville-2026/ROSTERS.md). **Read that file before
executing.** The ones that change what the migrations write:

- **R1** Mayor is `voting_powers 'full'` in an `Office of the Mayor` chamber of one, per Bradenton R2.
  ⚠ The mayor's council vote is genuinely unestablished — the only published charter is codified
  through **January 2014** and still says "MAYOR AND ALDERMEN". `'full'` needs no
  `representation_note`, so nothing unsourced reaches a voter-facing field.
- **R2** Chair, Vice Chair and Mayor Pro-Tem are **parentheticals on the seat title**, never offices.
- **R3** Eleven county offices. Solicitor General, Chief Magistrate, the Ocmulgee Circuit DA and its
  five Superior Court judges, the school board and the soil-and-water supervisor are all excluded,
  each for a stated reason.
- **R4** All 18 terms open-ended at `start_precision 'unknown'`, as GA-2. **No date is invented.**

### Zero reuses

All 18 tested first+last against 86,626 production rows: **zero matches**, with a positive control
(`Floyd Griffin`) returning exactly 1 to prove the detector works. So 18 new politician rows and 18
terms — no `office_terms`-only path, unlike FL-6's Oliver Gilbert.

### Out of scope, deliberately

Georgia Military College Board of Trustees (six districts on the same 2025 municipal ballot — a state
junior college's board, not a city office), the Baldwin County school board and the Piedmont Soil and
Water District supervisor (spec §11), and every Ocmulgee Judicial Circuit office (multi-county).

---

## Task 1 — load the 6 Milledgeville council districts as `X0042`

Source: `https://services1.arcgis.com/Ug5xGQbHsD8zuZzM/arcgis/rest/services/City_Council_Districts__2025__WFL1/FeatureServer/0`,
already saved to `backend/data/seed-milledgeville-2026/_mv-council-districts-2025.geojson` (6 features,
`outSR=4326`). District number is `DIST_ID` (integer 1–6); `DIST_NAME` and `District` both read `D<n>`.

1. Write the loader following `X0041` (Miami city commission districts) as the closest precedent.
2. ⚠ **CORRECTED 2026-09-01 against precedent.** `geo_id` is a **slug**, not a numeric scheme:
   `milledgeville-ga-council-district-1` … `-6`, as `bradenton-fl-council-ward-1` and
   `miami-fl-commission-district-1`. A slug is also immune to Georgia's three-way numeric collision
   outright, which a `1351492<n>` scheme only dodges by luck. `state = 'ga'`, not FIPS `'13'`.
3. ⚠ **CORRECTED: the loader writes ONLY `essentials.geofence_boundaries`.** `CC_0027` creates the
   `districts` rows — including a `Milledgeville Citywide` `LOCAL` district on TIGER `1351492`/`G4110`
   for the Mayor, which needs no new boundary because GA-1 already loaded that polygon.
4. Gates, all asserted **before any write**, discriminating ones first (the FL-6 ordering rule — a
   gate whose failure message invites re-baselining must never fire first):
   - **GATE 1, vintage.** The county's `ElectionGeography` copy is the **negative control** and MUST
     DIFFER: at least one interior point must disagree, and per-district symmetric difference must
     exceed a floor. Measured: D4's point lands in the county copy's D1; symdiff 0.09–0.99 sq mi.
   - **GATE 2, plan integrity.** `White + Black + Other = Pop` in every district, and every
     `|Pop_DVP| <= 10%`. Measured: exact in all six, worst deviation +7.54%.
   - **GATE 3**, control points: each district's own interior point, plus City Hall.
   - **GATE 4**, negative controls: a point in Baldwin County outside the city, and a point in another
     Georgia city, must fall in **no** district.
   - **GATE 5**, per-district area against the 2026-09-01 measurement.
   - **GATE 6**, union vs TIGER place `1351492` (20.420 sq mi) within tolerance — **not** against the
     county, since the city is 20 sq mi inside a 268 sq mi county.
5. ⚠ **`REFRESH MATERIALIZED VIEW CONCURRENTLY geofence_child_county` is NOT required** — per the FL
   correction, the refresh is needed only when a load writes `place` (`G4110`). This writes `X0042`.
   Confirm with `npm run check:child-county` afterwards regardless.

⚠ **The plan's population universe is 14,796, which is 86.7% of Milledgeville's 17,070 in the 2020
census.** The 2,274 gap is unexplained; the likeliest cause is an excluded institutional group-quarters
population (the city hosts Central State Hospital), and District 4 is 97.2% voting-age, which is the
signature of the Georgia College campus. **Not confirmed, and deliberately NOT gated on** — the gate
asserts internal balance and consistency, which are properties the layer asserts about itself. The
geometry's vintage is established by GATE 1 and GATE 6 independently of any population figure.

## Task 2 — load the 5 Baldwin commission districts as `X0043`

Source: `ElectionGeography_dashboard_.../FeatureServer/2`, filtered
`electedoffice = 'County Commissioner'`, already saved in `_bc-districts.geojson`. District number is
`districtid` (string `'1'`–`'5'`).

Same shape as Task 1. `geo_id` scheme: `13009<n>`. Pre-flight: exactly 5 features, `districtid` exactly
{1..5}, union within **0.5%** of `13009`'s 268.276 sq mi, no existing `X0043`.

⚠ Take the geometry from the **dashboard** service, not the `CommissionerDistrictsView` — they are the
same rows, and the dashboard one is what was measured above.

## Task 3 — generator emits three migrations

Write `scripts/gen-ga3-milledgeville-migrations.mjs`, reading a committed
`backend/data/ga3-milledgeville-roster.json` built from `ROSTERS.md`. Structure first, occupancy
second, so a re-seat never re-runs office creation. The county half is **one** migration, per spec §3.

| Slot | Half | Contents |
| --- | --- | --- |
| `CC_0027` | city structure | 1 government, **2 chambers** (`City Council`, `Office of the Mayor`), **7 offices** |
| `CC_0028` | city occupancy | **7 politicians, 7 terms**, all open-ended `'unknown'` |
| `CC_0029` | county | 1 government, **2 chambers** (`Board of Commissioners`, county officers), **11 offices + 11 politicians + 11 terms** |

Follow `CC_0008`/`CC_0009`/`CC_0010` (Bradenton + Manatee) — the closest structural precedent — not
the Miami ones. Every migration idempotent, ending in a `DO $$ … $$` post-verify gate that
`RAISE EXCEPTION`s on a wrong count. `chambers.slug` is GENERATED and cannot be inserted.

🔴 **TWO CORRECTIONS FOUND WHILE EXECUTING TASK 3, both from reading `CC_0010` rather than assuming
the city pattern generalised:**

1. **`district_type` DIFFERS BY TIER.** City districts are **`'LOCAL'`** (Bradenton `CC_0008`);
   county districts are **`'COUNTY'`** (Manatee `CC_0010`). The first draft of the generator wrote
   `'LOCAL'` for both. It is now a per-tier field in the roster JSON, and only one hardcoded
   `'LOCAL'` survives in the generator — inside a comment.
2. **THE WIDE DISTRICT IS CREATED FOR THE CITY AND ONLY *ASSERTED* FOR THE COUNTY.** GA-1 loaded the
   TIGER place **boundary** `1351492`/`G4110` but created no place **district**, so the citywide
   district must be inserted — as Bradenton inserted `Bradenton Citywide`. But the TIGER county load
   already created `13009`/`G4020` as a `COUNTY` district, verified in production. `CC_0010` asserts
   it in the pre-flight and inserts nothing. Creating it again would put a second district row over
   the same ground. The county pre-flight now **fails hard** if that row is absent, because the six
   county officers have nowhere to sit without it.

Titles: `Mayor`; `Council Member, District 1..6`; `Commissioner, District 1..5`; then `Sheriff`,
`Clerk of Superior Court`, `Probate Judge`, `Tax Commissioner`, `Coroner`, `Surveyor`.
⚠ Per R2, **no Chairman, Vice Chairman or Mayor Pro-Tem office**. If the chair is to be visible at all
it is a parenthetical inside the District 2 title, decided at write time — Lawrence County's form.

## Task 4 — dry-run, apply, gate, probe, commit

1. ⚠ **The city occupancy half cannot be dry-run alone** — its offices do not exist yet. Run
   `CC_0027` + `CC_0028` as **ONE transaction ending in ROLLBACK**, and assert the statement stream
   holds exactly one `BEGIN`, one `ROLLBACK` and **zero `COMMIT`** before sending it. FL-6's method.
2. Confirm the rollback actually reverted: production must still read **0** GA `LOCAL` districts and
   **0** rows in `-1331018 … -1331001`.
3. `git fetch origin`, re-count the free slot **against every remote ref**, rename the `CC_wip_*`
   files, apply through `psql "$DATABASE_URL"`.
4. Gates: `npm run check:migrations`, `check:occupancy`, `check:answer-delete-guards`,
   `check:child-county`, `check:reachability`.
5. **Acceptance probe at Milledgeville City Hall — four answers, all four required.** Add a
   `place:milledgeville` probe to the reachability gate. Assert a count per answer, scoped to this
   wave: 1 council member, 1 county commissioner, 1 representative, 1 senator.
   ⚠ FL-6's lesson — **run the probe BEFORE the apply too.** It is what caught the at-large ruling
   that had been read against the wrong county.
6. Re-run all three migrations to prove idempotence, then confirm
   `offices_missing_terms` is **unchanged at 821 / 166 / 655**.

## Task 5 — update the ledger

`PROGRAM.md` (slice table, migration ledger, session log, the local-seats and banner tables), `ga.md`
(GA-3 section and the "where this stopped" block), and the `X` sequence to `X0044`.

---

## Plan self-review

**What this plan does not know.** The mayor's council vote (defect 4), and why District 2 was seated
on exactly 50.0% with no runoff (defect 5). Both trace to the same root: Milledgeville's published
charter is twelve years stale. Neither blocks the wave — R1 writes no unsourced prose, and D2's
occupancy is certified by the state and confirmed by the city — but both are recorded rather than
resolved by assumption, and both should be re-checked if a current charter surfaces during GA-4/GA-5.

**The single largest risk was the polygon source, and it is closed.** Had this wave taken the county's
copy of the council districts — the one the city's own website links to — District 4's residents would
have been handed District 1's council member, silently, with every cheaper gate passing. It was caught
only by comparing all six districts rather than three.

**The second risk is that the county commission layer has one publisher.** Its attributes are fresh
(2026-04-21) and agree with the certified count 5 of 5, and its geometry tiles Baldwin to 0.006%. That
is good evidence but it is not two independent maps. Recorded, accepted, and worth a second look if
Georgia's Reapportionment Office turns out to publish certified local plans in a fetchable form —
which would also settle Columbus and Macon.
