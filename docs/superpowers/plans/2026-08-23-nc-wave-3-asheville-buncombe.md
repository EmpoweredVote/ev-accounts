# NC Wave 3 — Asheville City + Buncombe County Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Seat Asheville's 7 city and Buncombe County's 10 elected officials on address-reachable geometry, and give Asheville a banner, so an Asheville address returns its full local government.

**Architecture:** Three new county-commission polygons load from Buncombe's own GIS into `geofence_boundaries` under synthetic `mtfcc='X0034'`; then two migrations — structure (`CA_0009`: 1 `LOCAL` + 3 `COUNTY` districts + 17 offices) and occupancy (`CA_0010`: 17 politicians + 17 terms). Asheville's city polygon and Buncombe's county polygon are **already loaded**; neither is re-fetched. The banner is a separate PR in the `essentials` repo.

**Tech Stack:** TypeScript/Node 24, `tsx`, vitest, `psql` against the Supabase session pooler, PostGIS, ArcGIS REST (GeoJSON).

**Spec:** [`.planning/todos/2026-08-21-nc-durham-asheville-deep-seed.md`](../../../.planning/todos/2026-08-21-nc-durham-asheville-deep-seed.md) (wave 3)

**Scope decided 2026-08-23:** seats + Asheville banner. Headshots and stances defer to a combined wave 2b covering Durham and Asheville together. Buncombe's 10 = chair + 6 district commissioners + Sheriff + Register of Deeds + Clerk of Superior Court — **parity with Durham's 8**, so a Buncombe address does not return fewer county officials than a Durham one. Same exclusions as wave 2: judges are `JUDICIAL` with their own scale, and the District Attorney is elected by prosecutorial district, which needs its own geography check first.

## Global Constraints

- **`cwd` resets between Bash calls.** Prefix every command `cd /c/EV-Accounts/backend &&` in the *same* compound command. A bare `psql "$DATABASE_URL"` with an unsourced `.env` **hangs waiting on stdin** rather than failing — that happened while writing this plan.
- **Branch: `feat/nc-wave3-asheville`, cut from `origin/master`.** Unlike wave 2, this **does** branch from master: waves 1 and 2 merged on 2026-08-23 as `7b0332c5` (PR #136) and `d6d22bf4` (PR #137). `git fetch origin` first — master moves under you.
- **Migration slots: `CA_0009`** (structure) and **`CA_0010`** (occupancy). `CA_0001`–`CA_0008` exist. Cite slots in full — never "migration 9".
- 🔴 **Dry-running a migration here — the naive recipe SILENTLY APPLIES.** Most migrations self-wrap in `BEGIN;`/`COMMIT;`, so `BEGIN; \i file; ROLLBACK;` lets the file's own `COMMIT` close the outer transaction. This cost a real un-rehearsed apply on `CA_0004`. Instead:

  ```bash
  grep -vE '^(BEGIN|COMMIT);$' migrations/CA_000N_x.sql > body.sql
  # BEGIN; \i C:/abs/windows/path/body.sql ; <count queries>; ROLLBACK;
  # psql's \i needs a WINDOWS path — a /c/... path fails "No such file or directory".
  ```

  Then **prove reversion with a separate query afterwards.** The tell for a failed rehearsal is `WARNING: there is no transaction in progress`.
- **Every migration is idempotent** and ends with a `DO $$ ... $$` post-verify gate that `RAISE EXCEPTION`s on a wrong count.
- **Never cache "current".** Occupancy is `essentials.office_terms`, read via `essentials.office_current_holder`. Use `seat_officeholder` / `vacate_office`; don't hand-roll the two-step.
- **Don't invent dates.** `start_precision` accepts `'day' | 'month' | 'year' | 'unknown'` (verified against the CHECK on 2026-08-23) — Asheville's sources are month-level, so `'month'` is the honest value, not a fabricated day. `how_started` accepts `'elected' | 'appointed' | 'succeeded' | 'redistricted' | 'unknown'`.
- **No party affiliation on any officeholder.** Party lives on `races.primary_party`.
- **Commit with a pathspec** — `git commit -F msg -- <path>`. Parallel sessions sweep each other's staged files, both ways.
- 🔴 **Do NOT re-run the `place` layer.** Wave 2's load wrote 552 `G4110` / 0 `G4210` records for **all of NC**, not just Durham. Asheville city `geo_id='3702140'` (`name='Asheville city'`, `state='37'`) is already in `essentials.geofence_boundaries` — verified 2026-08-23. Re-running is wasted work and an unnecessary prod write.
- 🔴 **`geo_id` is not unique across layers — every district join pairs it with `mtfcc` or `district_type`.** Measured in prod 2026-08-23, `geo_id='37021'` returns **three** rows: `COUNTY|G4020|Buncombe County`, `STATE_UPPER|G5210|State Senate District 21`, `STATE_LOWER|G5220|State House District 21`. A bare lookup attaches Buncombe's county offices to a state legislative district while an "offices created" count still looks right.

### 🔴 Two structural rules that differ from wave 2 — read before writing any office row

**1. In Buncombe, "Chair" IS a separate elected office. In Durham it was not.** Durham's chairmanship rotates by board vote among 5 at-large seats, so wave 2 correctly refused to create a sixth "Chair" seat. Buncombe is the opposite: a 2011 local act seats **7** commissioners — the chair elected **countywide** plus **six by district, two per district**. Amanda Edwards is Chair as an office she ran for, not a role the board assigned her. Create it as an office titled `Chair, Board of Commissioners` on the county polygon. **Do not apply wave 2's "chair is not an office" rule here.**

**2. "Vice Mayor" in Asheville IS a board role, not an office — wave 2's rule DOES apply.** Asheville seats a mayor plus 6 council members, all at-large; the vice mayoralty is assigned. S. Antanette Mosley is one of the **six council members**. Creating a seventh "Vice Mayor" seat would invent a seat that does not exist.

### 🔴 The identity rule for this wave

**Do NOT guard politician inserts on `full_name` alone.** Wave 2's Mike Lee collision — three distinct people sharing a name, where a bare name guard silently seated a sitting US Senator on a county commission — applies here unchanged.

1. **Every wave-3 politician gets an explicit `external_id`** in the band `-(3740000 + n)`. **Verified free 2026-08-23: 0 rows in `-3749999..-3740000`.** Guard inserts on `external_id` (`ON CONFLICT (external_id) DO NOTHING` against the unique index from migration 191), never on name.
2. **Cross-state homonym assertion** in the gate: no politician seated on an Asheville or Buncombe office may simultaneously hold an office whose district `state` is not `nc`.
3. **Measured 2026-08-23: none of the 16 known names exists in prod** (all 7 Asheville seats and all 7 commissioners, checked lowercased against `essentials.politicians`). The three row officers are unnamed at plan time and **must be re-checked in Task 2 once named** — that is where a collision would now hide.

---

### Task 1: Load Buncombe's 3 commission districts (`X0034`)

Delivers the only new geometry in this wave. Writes **only** to `essentials.geofence_boundaries`; the `districts` rows are created by `CA_0009`.

**Files:**
- Create: `backend/scripts/load-buncombe-commissioner-boundaries.ts`
- Create: `backend/scripts/verify-buncombe-commission-coupling.sql`

**Interfaces:**
- Consumes: nothing from earlier tasks. Depends on wave 1's already-loaded `G5220` NC House polygons as its verification oracle.
- Produces: 3 rows in `essentials.geofence_boundaries` with `mtfcc='X0034'`, `state='nc'`, `geo_id='buncombe-nc-commissioner-district-1'|'-2'|'-3'`. `CA_0009` joins on `(geo_id, mtfcc)`.

**Model on `backend/scripts/load-elpaso-commissioner-boundaries.ts`** — same constant block, same insert, same control-point and county-fit checks. Constants for this wave:

```typescript
const BC_DISTRICT_URL =
  'https://gis.buncombecounty.org/arcgis/rest/services/' +
  'bcmap_VotingDistricts3/MapServer/7/query' +
  '?where=1%3D1&outFields=DISTRICT%2CPL20AA_TOT' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';
const MTFCC          = 'X0034';
const STATE_CODE     = 'nc';
const SOURCE         = 'buncombegov-arcgis-bcmap_VotingDistricts3-7-2026-08-23';
const GEO_ID_PREFIX  = 'buncombe-nc-commissioner-district-';
const COUNTY_GEO_ID  = '37021';
const EXPECTED_COUNT = 3;
```

That URL was exercised on 2026-08-23: HTTP 200, a `FeatureCollection` of exactly 3 `Polygon` features with WGS84 coordinates and `DISTRICT` values `'1'`, `'2'`, `'3'`. **`outSR=4326` is load-bearing** — the layer's native units are state-plane feet (hence the area figures below), and omitting it writes projected coordinates into a geographic column, which no post-verify count would catch.

The insert is El Paso's verbatim, with this wave's `MTFCC`/`STATE_CODE`:

```sql
INSERT INTO essentials.geofence_boundaries
  (id, geo_id, mtfcc, state, name, geometry, source)
VALUES (gen_random_uuid(), $1, 'X0034', 'nc', $2,
  public.ST_Multi(public.ST_SetSRID(public.ST_GeomFromGeoJSON($3), 4326)), $4)
ON CONFLICT (geo_id, mtfcc) DO NOTHING
RETURNING public.ST_GeometryType(geometry) AS gtype, public.ST_IsValid(geometry) AS valid
```

🔴 **`X0034` is the correct slot.** Measured 2026-08-23: `X0033` (El Paso) is the highest `X0%` mtfcc in `essentials.districts`. Do not reuse `X0033`.

**Layer choice — unusually, there is no trap here, and that is a measured finding, not an assumption.** Buncombe publishes three commissioner-district layers: `bcmap_VotingDistricts3/7` ("County Commissioner Districts"), `bcmap_VotingDistricts3/14` (`Bun.DBO.Cty_Commish_Dist`), and `ElectionPrecinct/1` ("County Commissioners"). Measured 2026-08-23, **all three are byte-identical** — same `Shape.STArea()`, `Shape.STLength()` and `PL20AA_TOT` on all 3 features. None publishes a `lastEditDate`, so El Paso's edit-date discrimination is unavailable and also unnecessary. Layer 7 is chosen as the plainly-named one; **for this county that is safe, and the assertion in Step 1 is what makes it safe** rather than the name.

- [ ] **Step 1: Write the failing coupling assertion first**

🔴 **CORRECTED DURING EXECUTION 2026-08-23 — this gate is a TOLERANCE test, not `ST_Equals`.** The first draft of this plan specified `ST_Equals`, reasoning from the spec's "byte-identical" finding. That finding is real but is a comparison between two layers of **Buncombe's own GIS**. Our House polygons are **TIGER 2024 `sldl`** — an independent digitization of the same legal boundary. Measured:

| comparison | `ST_Equals` | IoU | symmetric difference |
|---|---|---|---|
| comm D1 vs TIGER `37114` | **false** | 99.681 % | 2.09 km² |
| comm D2 vs TIGER `37115` | **false** | 99.883 % | 1.07 km² |
| comm D3 vs TIGER `37116` | **false** | 99.969 % | 0.04 km² |

An `ST_Equals` gate fails permanently on correct data. The hazard is not the red build — it is that the obvious fix for a permanently-red gate is to delete it, losing the only check on the coupling.

**The tolerance has measured discriminating power**, so it is not a rubber stamp. Every wrong pairing was measured too:

|  | TIGER `37114` | TIGER `37115` | TIGER `37116` |
|---|---|---|---|
| comm D1 | **99.681 %** | 0.002 % | 0.002 % |
| comm D2 | 0.000 % | **99.883 %** | 0.001 % |
| comm D3 | 0.001 % | 0.002 % | **99.969 %** |

Correct pairings cluster at ~99.7–100 %, wrong ones at ~0 %; any threshold from 1 % to 99 % separates them. **99.0 %** is chosen for 0.68 pp of headroom below the worst correct pairing, while a genuine redraw moves whole precincts and cannot hide under it.

Create `backend/scripts/verify-buncombe-commission-coupling.sql`. It asserts the loaded commission polygons still agree with the NC House polygons they are statutorily tied to, distinguishes a **missing** row from a **decoupled** one (before the loader runs, all three are absent, which is not a decoupling), and refuses to pass vacuously if fewer than 3 comparisons actually ran:

```sql
-- verify-buncombe-commission-coupling.sql
--
-- A 2011 local act sets Buncombe County's 3 commission districts EQUAL to NC
-- House districts 114/115/116, two commissioners each. Buncombe is the only one
-- of NC's 100 counties with this arrangement.
--
-- 🔴 THIS IS A LIVE COUPLING, NOT A HISTORICAL NOTE. A future NC House redraw
-- silently moves Buncombe's commission lines. Nothing in the schema expresses
-- the dependency -- `essentials.districts` has no note column -- so this script
-- IS the record. Run it after any NC `sldl` reload, and after any migration that
-- touches the X0034 rows.
--
-- Loaded by: backend/scripts/load-buncombe-commissioner-boundaries.ts
-- Consumed by: CA_0009 (structure), CA_0010 (occupancy) -- wave 3 of the NC
--              deep-seed program, .planning/todos/2026-08-21-nc-durham-asheville-deep-seed.md
--
-- ─────────────────────────────────────────────────────────────────────────────
-- 🔴 WHY THIS IS A TOLERANCE TEST AND NOT `ST_Equals`. READ BEFORE TIGHTENING IT.
--
-- The spec records Buncombe's commission districts as BYTE-IDENTICAL to the
-- state House districts -- same `Shape.STArea()`, `Shape.STLength()` and
-- population. That is true, and it is a comparison between two layers of
-- BUNCOMBE'S OWN GIS (`bcmap_VotingDistricts3/7` vs `/5`).
--
-- Our House polygons are not Buncombe's. They are TIGER 2024 `sldl`. TIGER and
-- the county are two independent digitizations of one legal boundary, so they
-- are NOT geometrically equal. Measured 2026-08-23:
--
--   commission D1 vs TIGER 37114:  ST_Equals FALSE, IoU 99.681%, symdiff 2.09 km2
--   commission D2 vs TIGER 37115:  ST_Equals FALSE, IoU 99.883%, symdiff 1.07 km2
--   commission D3 vs TIGER 37116:  ST_Equals FALSE, IoU 99.969%, symdiff 0.04 km2
--
-- An `ST_Equals` gate therefore FAILS PERMANENTLY on correct data. The danger is
-- not the red build -- it is that the obvious way to "fix" a permanently red gate
-- is to delete it, which discards the only check on the coupling.
--
-- The tolerance has real discriminating power; it is not a rubber stamp.
-- Every WRONG pairing was measured too, and they are not close:
--
--            TIGER 37114   TIGER 37115   TIGER 37116
--   comm D1      99.681%        0.002%        0.002%
--   comm D2       0.000%       99.883%        0.001%
--   comm D3       0.001%        0.002%       99.969%
--
-- Correct pairings cluster at ~99.7-100%, wrong ones at ~0%. Any threshold from
-- 1% to 99% separates them perfectly. 99.0% is chosen because it leaves 0.68
-- percentage points of headroom below the worst correct pairing (D1) for a TIGER
-- vintage change, while a genuine redraw -- which moves whole precincts, tens of
-- km2 -- cannot hide underneath it.

\set MIN_IOU_PCT 99.0

DO $$
DECLARE
  pair    RECORD;
  v_iou   numeric;
  min_iou numeric := 99.0;   -- keep in sync with \set MIN_IOU_PCT above
  n_bad   int := 0;
  n_seen  int := 0;
BEGIN
  FOR pair IN
    SELECT * FROM (VALUES
      ('buncombe-nc-commissioner-district-1', '37114'),
      ('buncombe-nc-commissioner-district-2', '37115'),
      ('buncombe-nc-commissioner-district-3', '37116')
    ) AS t(comm_geo_id, hd_geo_id)
  LOOP
    -- Pair geo_id with mtfcc on BOTH sides. geo_id is not unique across layers:
    -- '37021' alone returns Buncombe County, NC Senate 21 AND NC House 21.
    SELECT 100.0 * public.ST_Area(public.ST_Intersection(c.geometry, h.geometry)::geography)
                 / public.ST_Area(public.ST_Union(c.geometry, h.geometry)::geography)
      INTO v_iou
      FROM essentials.geofence_boundaries c
      JOIN essentials.geofence_boundaries h
        ON h.geo_id = pair.hd_geo_id AND h.mtfcc = 'G5220' AND h.state = '37'
     WHERE c.geo_id = pair.comm_geo_id AND c.mtfcc = 'X0034';

    IF v_iou IS NULL THEN
      -- Either side absent. Distinguish this from a geometry mismatch: before the
      -- loader runs, ALL THREE are absent, and that is not a decoupling.
      n_bad := n_bad + 1;
      RAISE WARNING 'MISSING: % or NC House % not present -- has the loader run?',
        pair.comm_geo_id, pair.hd_geo_id;
    ELSE
      n_seen := n_seen + 1;
      IF v_iou < min_iou THEN
        n_bad := n_bad + 1;
        RAISE WARNING 'DECOUPLED: % vs NC House % agree only %%% (need >= %%%)',
          pair.comm_geo_id, pair.hd_geo_id, round(v_iou, 3), min_iou;
      ELSE
        RAISE NOTICE '  ok: % vs NC House % agree %%%',
          pair.comm_geo_id, pair.hd_geo_id, round(v_iou, 3);
      END IF;
    END IF;
  END LOOP;

  IF n_bad > 0 THEN
    RAISE EXCEPTION 'Buncombe commission coupling broken for % of 3 districts', n_bad;
  END IF;
  IF n_seen <> 3 THEN
    -- Belt and braces: a vacuous pass is the failure mode this whole program
    -- guards against. Three comparisons must actually have been made.
    RAISE EXCEPTION 'Buncombe coupling check was vacuous: % of 3 comparisons ran', n_seen;
  END IF;
  RAISE NOTICE 'Buncombe coupling OK - all 3 commission districts match their NC House twin.';
END $$;
```

- [ ] **Step 2: Run it and watch it FAIL**

Run: `cd /c/EV-Accounts/backend && set -a && . ./.env && set +a && psql "$DATABASE_URL" -f scripts/verify-buncombe-commission-coupling.sql`

Expected: **FAILS** — `Buncombe commission coupling broken for 3 of 3 districts`, because nothing is loaded yet. This is the red half; it proves the assertion can fail before it is trusted to pass.

- [ ] **Step 3: Write the loader, and give it the coupling check as a load gate**

Beyond El Paso's control-point and county-fit checks, the loader must **refuse to write** unless each fetched polygon agrees with its NC House twin at **IoU >= 99.0 %** (see Step 1 for why this is a tolerance and not equality). It runs that comparison against the database *before* inserting, so `--dry-run` exercises the real gate. Attribute values expected from the county's own service, measured 2026-08-23 (`Shape.STArea()` in native state-plane units):

| Fetched `DISTRICT` | `geo_id` written | `PL20AA_TOT` | `Shape.STArea()` | must equal NC House |
|---|---|---|---|---|
| `1` | `buncombe-nc-commissioner-district-1` | 91,120 | 652739949.8563602 | `37114` |
| `2` | `buncombe-nc-commissioner-district-2` | 88,875 | 909874574.490132 | `37115` |
| `3` | `buncombe-nc-commissioner-district-3` | 89,457 | 143308244.59990597 | `37116` |

Control points, measured against the loaded `G5220` polygons on 2026-08-23:

```typescript
const CONTROL_POINTS = [
  { name: 'Asheville City Hall', lon: -82.5554, lat: 35.5967, district: 3 },
  { name: 'Black Mountain',      lon: -82.3200, lat: 35.6197, district: 1 },
];
```

- [ ] **Step 4: Dry-run**

Run: `cd /c/EV-Accounts/backend && npx tsx scripts/load-buncombe-commissioner-boundaries.ts --dry-run`

Expected: 3 features fetched, both control points resolving to the districts above, county-fit within tolerance, **no DB writes**.

- [ ] **Step 5: Load for real**

Run: `cd /c/EV-Accounts/backend && npx tsx scripts/load-buncombe-commissioner-boundaries.ts`

- [ ] **Step 6: Re-run the coupling assertion — now it must PASS**

Expected: `Buncombe coupling OK - all 3 commission districts match their NC House twin.` plus a per-district `ok: ... agree 99.xxx%` line. A pass here is the whole justification for treating a county body's districts as the state House's boundary.

- [ ] **Step 7: Check the child→county matview**

Run: `cd /c/EV-Accounts/backend && npm run check:child-county`

These 3 polygons nest inside a county, so they are child boundaries. If it reports stale, refresh as `postgres` (matview ownership — **not** `ev_api`) and re-check:

```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY essentials.geofence_child_county;
```

CI enforces `stale 0` on every push to master, so this cannot be deferred.

- [ ] **Step 8: Re-run the loader to prove idempotency** — second run must report all 3 skipped (`already exists`) and write nothing.

- [ ] **Step 9: Commit**

```bash
git commit -F msg -- backend/scripts/load-buncombe-commissioner-boundaries.ts backend/scripts/verify-buncombe-commission-coupling.sql
```

---

### Task 2: Verified roster — 17 seats, per-person sources

**Files:**
- Create: `backend/data/seed-buncombe-asheville-2026/ROSTERS.md`

Model on `backend/data/seed-durham-2026/ROSTERS.md`: numbered source table, an explicit **"Source defects found"** section, then a row per seat. **No database writes to produce this file.**

**Interfaces:**
- Consumes: nothing.
- Produces: for each of 17 seats — `body`, `office_title`, `full_name`, name parts, `assumed_office` (ISO), `precision` (`day`/`month`/`year`/`unknown`), `how_started` (`elected`/`appointed`/`succeeded`/`unknown`), `external_id`, `district` (for the 6 commissioners), and the source ID establishing each. Task 3 reads these.

**Known starting facts** — fetched from each government's own site on 2026-08-23. **Re-verify; do not re-derive.**

City of Asheville — 7 seats, **all elected at-large**, nonpartisan, staggered 4-year terms (3 seats every 2 years). Source: `ashevillenc.gov/government/meet-city-council/`, page "last updated or reviewed on April 29, 2026".

| Seat | Member | Page's "Term" string |
|---|---|---|
| Mayor | Esther E. Manheimer | December 2009 – December 2026 |
| Council Member | S. Antanette Mosley | September 2020 – December 2026 |
| Council Member | Kim Roney | December 2020 – December 2028 |
| Council Member | Sheneika Smith | December 2017 – December 2026 |
| Council Member | Sage Turner | December 2020 – December 2028 |
| Council Member | Maggie Ullman | December 2022 – December 2026 |
| Council Member | Bo Hess | December 2024 – December 2028 |

🔴 **The page's "Term" start is service on the BODY, not tenure in THIS SEAT.** `term_start` means the day this person began holding **this office**. Manheimer's string reads "December 2009" — that is when she joined **council**; she became **Mayor in December 2013**. Writing 2009 would assert she has been Mayor for four years longer than she has. Establish the mayoral start date from the city's own record and use that. Check every other member for the same defect before trusting their string, and record what you found in "Source defects found".

🔴 **Mosley's "September 2020" is mid-term** — an appointment to a vacancy, not an election. Confirm and set `how_started='appointed'`. Wave 2 hit this twice (Chelsea Cook, Javiera Caballero); do not let a `p_how_started` default of `'elected'` fall through.

🔴 **Vice Mayor is not a seat.** Mosley is one of the six council members (see Global Constraints). The roster has exactly 7 Asheville rows.

Buncombe County — 10 seats. Commission source: `buncombecounty.org/705/County-Commissioners`, **corroborated independently** by the `DISTRICT`/`Commission`/`Commissi_1` attributes on GIS layer 7. Both read 2026-08-23 and they agree on all six district members.

| Seat | Member | Elected by |
|---|---|---|
| Chair, Board of Commissioners | Amanda Edwards | countywide |
| Commissioner, District 1 | Al Whitesides | District 1 (= NC House 114) |
| Commissioner, District 1 | Jennifer Horton | District 1 |
| Commissioner, District 2 | Terri Wells | District 2 (= NC House 115) |
| Commissioner, District 2 | Martin Moore | District 2 |
| Commissioner, District 3 | Parker Sloan | District 3 (= NC House 116) |
| Commissioner, District 3 | Drew Ball | District 3 |
| Sheriff | *to establish* | countywide |
| Register of Deeds | *to establish* | countywide |
| Clerk of Superior Court | *to establish* | countywide |

- [ ] **Step 1: Establish the three row officers.** `buncombecounty.org/663/Sheriff`, `/457/Register-of-Deeds` and `/176/Clerk-of-Superior-Court` were checked on 2026-08-23 and are **service pages that do not name the incumbent** — do not cite them as roster sources. Use the county's elected-officials listing and the NC State Board of Elections results, two sources, not one secondary aggregator.
- [ ] **Step 2: Establish an assumed-office date for all 17**, with precision. Prefer the swearing-in date (`'day'`); month-level sources get `'month'`; year-only gets `'year'`; genuinely unknown gets NULL with `'unknown'` — **never a guess**.
- [ ] **Step 3: Re-run the homonym check, now including the three row officers.** The 16 known names returned 0 rows on 2026-08-23; the newly-named three are where a collision can still hide.

```sql
SELECT p.full_name, p.external_id, coalesce(d.state,'-') AS st, coalesce(d.label,'(no office)') AS office
FROM essentials.politicians p
LEFT JOIN essentials.office_current_holder och ON och.politician_id = p.id
LEFT JOIN essentials.offices o ON o.id = och.office_id
LEFT JOIN essentials.districts d ON d.id = o.district_id
WHERE lower(p.full_name) IN ( /* the 17 names, lowercased */ );
```

Any hit outside `nc` is a homonym to document with its `external_id`, **never** a row to reuse.
- [ ] **Step 4: Record the Buncombe-chair-is-an-office contrast** explicitly in the roster, so a reader coming straight from wave 2's Durham roster cannot apply the wrong rule.
- [ ] **Step 5: Commit** the roster file.

---

### Task 3: Generate `CA_0009` and `CA_0010`

**Files:**
- Create: `backend/scripts/gen-buncombe-asheville-migrations.mjs`
- Output: `migrations/_wip_wave3_structure.sql`, `migrations/_wip_wave3_incumbents.sql`

**Interfaces:**
- Consumes: `data/seed-buncombe-asheville-2026/ROSTERS.md` (or a JSON the same task emits from it).
- Produces: two `_wip_` SQL files. Tasks 4 and 5 rename them into `CA_0009` / `CA_0010`.

**Structure migration (`CA_0009`) must:**

- Insert **one** `LOCAL` district: `geo_id '3702140'`, `mtfcc 'G4110'`, `state 'nc'`, label **`Asheville Citywide`**. Follow the **`Durham Citywide`** precedent from `CA_0006` (7 offices on one citywide polygon), which in turn followed Bainbridge Island — **not** Austin's genuinely district-elected shape.
- Insert **three** `COUNTY` districts for the commission, joined on `(geo_id, mtfcc)`:

  | `geo_id` | `mtfcc` | `district_type` | `label` | `num_officials` |
  |---|---|---|---|---|
  | `buncombe-nc-commissioner-district-1` | `X0034` | `COUNTY` | `Buncombe County Commissioner District 1` | 2 |
  | `buncombe-nc-commissioner-district-2` | `X0034` | `COUNTY` | `Buncombe County Commissioner District 2` | 2 |
  | `buncombe-nc-commissioner-district-3` | `X0034` | `COUNTY` | `Buncombe County Commissioner District 3` | 2 |

  `district_type='COUNTY'` matches the Kitsap (`X0027`) and Washco precedents and is semantically right for county offices. It was verified harmless on both read paths that branch on `district_type`: `campaignFinanceSearchService.ts:103` puts `LOCAL` and `COUNTY` in the same tier, and `inform.compass_lenses` auto-applies the `local` lens to `{LOCAL,LOCAL_EXEC,COUNTY,SCHOOL}` — so Buncombe commissioners get the 22-topic local scale either way.
- Insert **17 offices**:
  - 7 on the Asheville `LOCAL` district — `Mayor` ×1, `Council Member` ×6.
  - 4 on the **existing** Buncombe county district — `Chair, Board of Commissioners` ×1, `Sheriff`, `Register of Deeds`, `Clerk of Superior Court`. `NOT EXISTS`-guarded; **do not create the county district.** It exists and carries **0 offices** today (measured 2026-08-23).

    🔴 The county join is mandatory-paired, because `geo_id='37021'` matches three rows across layers:

    ```sql
    JOIN essentials.districts d
      ON d.geo_id = '37021' AND d.district_type = 'COUNTY' AND lower(d.state) = 'nc'
    ```
  - 6 on the three `X0034` districts — `Commissioner, District N` ×2 per district.

- 🔴 **Scope the multi-seat top-up guard to `(chamber_id, district_id)`, not `chamber_id` alone.** This is the one real code change from wave 2's generator. `CA_0006` scoped its `NOT EXISTS` to `chamber_id` alone and said so in its own comments — correct for Durham, whose 3 at-large seats share one district. Buncombe breaks it: **6 commissioners across 3 districts in one chamber.** Under a `chamber_id`-only existing-count subquery, the first district's 2 seats satisfy the count and the other 4 offices are never created — and a "6 offices" assertion written the same wrong way would pass. Required shape:

  ```sql
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices o
     WHERE o.chamber_id = c.id
       AND o.district_id = v.district_id      -- ← the fix; district_id, not chamber alone
       AND o.title = v.title
  )
  ```

- 🔴 Set `representation_note` on the **6 district commissioner offices**, recording the statutory coupling in voter-facing terms — that this district's boundaries are, by a 2011 local act, identical to the NC House district. `representation_note` on a `voting_powers='full'` seat is permitted (the CHECK requires it only when powers are not full) and there are existing precedents. Do **not** set `representation_basis` to anything but `residency`: these are ordinary address-selectable seats.
- End with a post-verify gate asserting: 1 new `LOCAL` district; 3 new `COUNTY`/`X0034` districts; 7 offices on `3702140`; **4** on the `COUNTY` row for `37021`; **exactly 2** on each of the three `X0034` districts (**per district, not 6 in total** — a total-only count is exactly what the `chamber_id` bug defeats); 6 offices carrying a non-null `representation_note`; and **0** offices on a district lacking geometry.

  🔴 **Plus the assertions that catch the collision.** After `CA_0009` runs, the two state legislative districts sharing `geo_id='37021'` must be untouched:

  ```sql
  SELECT count(*) INTO n_hd21 FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '37021' AND d.district_type = 'STATE_LOWER';
  IF n_hd21 <> 1 THEN RAISE EXCEPTION
    'CA_0009: NC House District 21 carries % offices, expected 1 — county offices cross-wired onto the house district', n_hd21; END IF;

  SELECT count(*) INTO n_sd21 FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '37021' AND d.district_type = 'STATE_UPPER';
  IF n_sd21 <> 1 THEN RAISE EXCEPTION
    'CA_0009: NC Senate District 21 carries % offices, expected 1 — county offices cross-wired onto the senate district', n_sd21; END IF;
  ```

  Counting offices on the county row alone would not notice offices landing on either legislative district; only these assertions do.

**Incumbents migration (`CA_0010`) must:** insert 17 politicians guarded on `external_id`, seat each via `seat_officeholder` (passing `how_started` and `start_precision` explicitly — do **not** let `p_how_started` fall through to its `'elected'` default for appointees), and gate on: 17 seated, the appointed count matching the roster, each `X0034` district holding exactly 2 seated commissioners, and the cross-state homonym assertion.

- [ ] **Step 1: Write the generator**, modelled on `scripts/gen-durham-migrations.mjs`.
- [ ] **Step 2: Generate, then READ the emitted SQL.** Check that `Esther E. Manheimer`, `S. Antanette Mosley` and any apostrophes or non-ASCII survive verbatim, and that the file is UTF-8 **without BOM** — a mojibaked name is voter-facing.
- [ ] **Step 3: Verify the district-scoped guard by inspection** — confirm each of the 6 commissioner inserts carries `o.district_id = ...` in its `NOT EXISTS`, and that the post-verify counts per district rather than in total.
- [ ] **Step 4:** `cd /c/EV-Accounts/backend && npm run check:occupancy` — catches any write to the dropped `offices.politician_id`.
- [ ] **Step 5: Commit** the generator.

---

### Task 4: Apply `CA_0009` (structure)

- [ ] **Step 1:** `cd /c/EV-Accounts/backend && git fetch origin && npm run check:migrations`; confirm `CA_0009` is still free.
- [ ] **Step 2:** Rename `_wip_wave3_structure.sql` → `CA_0009_asheville_buncombe_structure.sql`; update self-references and the forward-reference to `CA_0010`.
- [ ] **Step 3: Rehearse using the CORRECTED recipe** from Global Constraints — strip `BEGIN;`/`COMMIT;` into a body copy, wrap that, run the count queries, `ROLLBACK`.
- [ ] **Step 4: Prove reversion** with a separate query — expect 0 `Asheville Citywide` districts, 0 `X0034` districts, 0 offices on `3702140`, and Buncombe's county row back to **0** offices. **A printed `ROLLBACK` is not proof; the absence of `WARNING: there is no transaction in progress` is what distinguishes a rehearsal from an apply.**
- [ ] **Step 5: Apply for real.**
- [ ] **Step 6: Re-run to prove idempotency** — second run must be a no-op.
- [ ] **Step 7: Commit.**

---

### Task 5: Apply `CA_0010` (incumbents)

- [ ] **Step 1:** Re-verify the `external_id` band `-3749999..-3740000` is still 0 rows.
- [ ] **Step 2:** Rename into `CA_0010_asheville_buncombe_incumbents.sql`; rehearse with the corrected recipe; prove reversion.
- [ ] **Step 3: Apply for real.**
- [ ] **Step 4: Verify the homonym guard actually held:**

```sql
SELECT p.full_name, p.external_id, d2.state AS other_state, d2.label AS other_office
FROM essentials.politicians p
JOIN essentials.office_current_holder och ON och.politician_id = p.id
JOIN essentials.offices o ON o.id = och.office_id
JOIN essentials.districts d ON d.id = o.district_id
 AND (   (d.geo_id = '3702140' AND d.mtfcc = 'G4110')
      OR (d.geo_id = '37021'   AND d.district_type = 'COUNTY')
      OR (d.mtfcc  = 'X0034') )
JOIN essentials.office_current_holder och2 ON och2.politician_id = p.id
JOIN essentials.offices o2 ON o2.id = och2.office_id
JOIN essentials.districts d2 ON d2.id = o2.district_id AND lower(d2.state) <> 'nc';
```

Expected: **0 rows.** Any row means a wave-3 seat resolved to an out-of-state politician — the Mike Lee failure. Stop and fix before proceeding.
- [ ] **Step 5: Confirm every new office got a term.** `npm run check:occupancy`, and confirm `offices_missing_terms` unflagged is **still 655** (the value measured 2026-08-23, unchanged by wave 2). 17 new offices must all have terms; a rise means silent invisibility, which nothing else errors on.
- [ ] **Step 6: Commit.**

---

### Task 6: End-to-end acceptance

The only reliable detector is an address probe — every other check passes vacuously when a term row is missing.

- [ ] **Step 1: Probe Asheville City Hall** (`-82.5554, 35.5967`). Expected: **7** Asheville city officials + Buncombe's **Chair** + Sheriff + Register of Deeds + Clerk of Superior Court + **District 3's two commissioners (Parker Sloan, Drew Ball)** + wave 1's HD-116 (Brian Turner) and SD-49 (Julie Mayfield).
- [ ] **Step 2: The negative control — this is the one that proves the districts are real.** The same Asheville probe must return **zero** District 1 and District 2 commissioners. Measured 2026-08-23 against the loaded `G5220` polygons, Asheville City Hall falls in HD-116, so D3 is the only correct commission answer. Whitesides, Horton, Wells or Moore appearing means the commission polygons are wrong or the join fans out.
- [ ] **Step 3: Probe Black Mountain** (`-82.3200, 35.6197`). Expected: HD-114 and **District 1's** commissioners (Al Whitesides, Jennifer Horton) — **not** District 3. Measured 2026-08-23: this point is in HD-114, and in `place` polygon `3706140 Black Mountain town`, **not** Asheville — so it must return the Buncombe county officials and **zero Asheville city officials**. That makes it a negative control for the city layer and a positive control for the county layer in one probe.
- [ ] **Step 4: Control-of-the-control.** A uniform answer is a broken detector. Confirm the same query shape that returned zero D1/D2 members at Asheville City Hall *does* return them at Black Mountain — proving the query can fire, and that Step 2's zero is a fact about geography rather than a broken join.
- [ ] **Step 5: Re-run the coupling assertion** — `psql "$DATABASE_URL" -f scripts/verify-buncombe-commission-coupling.sql` must still pass after both migrations.
- [ ] **Step 6: Gate suite** — `check:migrations`, `check:occupancy`, `check:child-county` (**must be `stale 0`**), `check:reachability`, `check:answer-delete-guards`, `node scripts/check-cal-access-predicate.mjs`, `npm run typecheck`, `npm test`.

  ⚠️ **Four CI jobs run only on `pull_request`/`push`, and four only when the event is neither** — a `workflow_dispatch` run is **not** full coverage. Measured 2026-08-23: dispatch skips `migration numbering`, `answer-delete context guards`, `cal-access predicate tripwire` and `office occupancy`. Run those four locally, as listed above.
- [ ] **Step 7: Update the spec** — mark wave 3 done in `.planning/todos/2026-08-21-nc-durham-asheville-deep-seed.md`, record `CA_0009`/`CA_0010` and `X0034`, note that the next free slot is `CA_0011`, and close the spec's open question about Asheville's at-large structure with what Task 2 found.
- [ ] **Step 8: Commit and open the PR** against `master`.

---

### Task 7: Asheville banner

**Files:**
- Modify: `src/lib/buildingImages.js` **in the `essentials` repo** (`C:\Transparent Motivations\essentials`) — a separate repo and a separate PR.

🔴 **Banners live in the essentials frontend, not in `treasury.municipalities`, which is dead.** Do not add a row there.

- [ ] **Step 1: Check the NC state banner's subject first.** It is currently a **Charlotte** skyline. Nothing Charlotte-flavored may be chosen for Asheville, and the check has to happen before selection rather than after.
- [ ] **Step 2: Select an Asheville image** — press, official or public-domain only, never social media. The credit line is the licence test.
- [ ] **Step 3: Version the filename.** Overwriting does **not** purge the CDN, so a reused filename serves the old image indefinitely.
- [ ] **Step 4: Certify against the 6:1 desktop band** — measure the safe zone at real aspect in the production render, don't eyeball the asset.
- [ ] **Step 5: Show the production render for approval** — real CSS at real aspect, with the rejected options and the live baseline beside it.
- [ ] **Step 6: Commit and open the essentials PR.**

---

## Self-Review

**Spec coverage.** Every wave-3 spec bullet maps to a task: Asheville `LOCAL` district on `3702140` with 7 at-large offices → Tasks 3–4; at-large chair on the existing `37021` → Tasks 3–4; six district commissioners on three districts derived from wave 1's `sldl` 114/115/116 → Tasks 1, 3, 4; "cross-check against `gis.buncombecounty.org` layer 7 before trusting the derivation" → Task 1 Steps 1–3 and 6, where it is a load gate rather than a manual check; "record the statutory coupling on the district rows" → `representation_note` in Task 3 plus the standing assertion script from Task 1, since `essentials.districts` has no note column; "must NOT re-run `place`" → Global Constraints; banner → Task 7. The spec's acceptance table rows for wave 3 are Task 6 Steps 1–3, with its stated negative control as Step 2 and a control-of-the-control added as Step 4.

**Deliberately out of scope.** Headshots and stances — the scope call recorded in the header. Wave 4 (2026 candidates) is unaffected; it still needs the congressional-map decision that the collision todo owns.

**Placeholder scan.** Three roster entries are marked *to establish* (Sheriff, Register of Deeds, Clerk of Superior Court) — that is Task 2 Step 1's explicit job, and it names where to look **and** records that the three obvious county URLs were already checked and do not carry incumbent names, so nobody re-walks that path. Manheimer's mayoral start date is likewise an explicit Task 2 job rather than a blank, and the plan states why the source's own number is wrong.

**Type consistency.** `mtfcc='X0034'` is fixed in Task 1's constants, asserted as the next free slot, and used identically in Tasks 3, 5 and 6. The `geo_id` slugs `buncombe-nc-commissioner-district-1..3` are byte-identical across Task 1's insert, the coupling script, Task 3's district table and Task 5's homonym query. The `external_id` band `-(3740000+n)` is declared in the identity rule, re-verified in Task 5 Step 1, and used as the insert guard. `'3702140'` always pairs with `mtfcc='G4110'` and `'37021'` always with `district_type='COUNTY'`.

**The known gaps.** Three of 17 officeholders are unnamed at plan time, so their homonym risk is unmeasured until Task 2 Step 3 — the plan says so rather than implying the 0-row result covers all 17. If any assumed-office date proves genuinely unavailable, the honest record is NULL with `'unknown'` — not a guess, and not a dropped seat.
