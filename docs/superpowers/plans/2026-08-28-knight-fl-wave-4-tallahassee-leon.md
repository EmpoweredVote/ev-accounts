# Knight Program — Florida Wave FL-4 (Tallahassee + Leon County) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Seat the City of Tallahassee and Leon County — **18 offices, 18 people, 0 vacancies** — so that an address at Tallahassee City Hall returns its city commissioners, its county commissioner, its state representative and its state senator.

**Architecture:** Four stages. **Only ONE boundary layer is needed** (`X0038`, the five Leon commission districts) because Tallahassee's commission is entirely at-large and the TIGER place polygon FL-1 already loaded carries every city seat. A roster file reconciles 18 officeholders and reads nothing from the DB. The FL-3 generator is copied and re-pointed, emitting three migrations: city structure, city occupancy, and county offices-and-people in one. Acceptance is the four-answer probe plus `check:reachability`.

**Tech Stack:** TypeScript/Node 24, `tsx`, vitest, `psql` against the Supabase session pooler, PostGIS, ArcGIS MapServer REST, Playwright (Leon County's sites hard-403 `curl`).

**Spec:** `docs/superpowers/specs/2026-08-28-knight-cities-program-design.md`
**Slice notes:** `.planning/knight-foundation/fl.md`
**Tracker:** `.planning/knight-foundation/PROGRAM.md`
**Prior wave:** `docs/superpowers/plans/2026-08-28-knight-fl-wave-3-bradenton-manatee.md` — **read its "Deviations found during execution" section before Task 1.** Six items there are the reason this plan is shorter.

## Global Constraints

Everything in FL-3's Global Constraints still applies. These are the ones that changed or are new:

- **Migration namespace is `CC_`.** Next free slots are `CC_0011`, `CC_0012`, `CC_0013`, measured 2026-08-28 with `check:migrations` green. **Take the numbers LAST**: write as `CC_wip_*.sql`, rename + apply + commit in one go.
- **Next free private MTFCC is `X0038`.** FL-3 took `X0036` and `X0037`. There is no central registry; each loader hardcodes its own.
- **Branch is `docs/knight-cities-program`**, pushed and in sync at `0d0a2141` (2026-08-28).
- 🔴 **The `geo_id` collision reaches the COUNTY layer.** `12073` is Leon County (`G4020`) **and** State House District 73 (`G5220`) — the same trap that returned Collier County's representative for Bradenton. Pair `geo_id` with `mtfcc` **and** `district_type` in every join.
- 🔴 **`essentials.seat_officeholder()` refuses a NULL `term_start`.** Route dated rows through the helper; insert an undated row directly, guarded on the office having zero existing term rows. Copy the block from `CC_0009`.
- 🔴 **An `external_id` band guard must be an ALLOWLIST of the ids the wave owns, not a count** — a count is non-idempotent and weaker. Same for post-verify politician counts, or the county migration gains a hidden ordering dependency on the city one.
- 🔴 **To dry-run a migration: turn ITS OWN final `COMMIT` into `ROLLBACK` and leave its `BEGIN` alone.** `sed 's/^COMMIT;$/ROLLBACK;/' migrations/X.sql | psql "$DATABASE_URL"`. **Never strip `BEGIN;`/`COMMIT;` to concatenate two migrations** — in FL-3 that `sed` also matched the outer wrapper and committed `CC_0008` to prod in autocommit.
- 🔴 **Re-run every applied migration once. That is the idempotency test**, and in FL-3 it was the only thing that found two real bugs.
- **No party affiliation.** The Leon SOE prints `(DEM)` beside all six constitutional officers and `(Non-Partisan)` beside the thirteen commission and city seats. Discard all of it.
- **No `term_end`.** No `end_precision` exists.
- **`districts.state` is lower case (`'fl'`); `governments.state` and `offices.representing_state` are UPPER (`'FL'`).**
- **`outSR=4326` is load-bearing.** Both Leon services are natively EPSG:3857.
- 🔴 **`curl` gets a hard 403 from `leonvotes.gov` and `cms.leoncountyfl.gov`** — TLS-fingerprint blocking, not a User-Agent problem; a full browser header set does not help. **Use Playwright** (the Ph150 method). The ArcGIS endpoints on `intervector.leoncountyfl.gov` answer `curl` fine.
- **`cwd` resets between Bash calls.** Prefix every command with `cd /c/EV-Accounts/backend &&`.

---

## Facts measured 2026-08-28 — do not re-derive these

### 🔴 The open question from `fl.md` is ANSWERED: Tallahassee is entirely at-large

The Leon County Supervisor of Elections states it directly: *"City Commissioners and Mayor do not have
districts. Instead, all voters who live in Tallahassee can vote each of the City Commissioner
contests."* Five seats, four-year terms, staggered.

**So FL-4 needs NO city ward layer.** The TIGER place polygon `1270600` (`G4110`), loaded by FL-1,
carries all five seats. That is one whole loader this wave does not write.

🔴 **The Mayor is SEAT 4** — not a separate office outside the numbering. The city's own page title
reads "Mayor John E. Dailey - Seat 4". Seats are 1, 2, 3, 4 and 5; seat 4 *is* the mayoralty.

⚠ **Consequence for the probe: the city answer is FIVE people, not one.** Every Tallahassee address
returns all five commissioners. The four-answer probe's first slot is satisfied by "at least one city
commissioner", and the correct assertion is that **all five** are present. Bradenton's ward structure
made this a single row; Tallahassee's does not.

### 🔴 Leon is a CHARTER county with SIX constitutional officers — Manatee had five

The county's own page: *"since November 12, 2002, Leon County adheres to governance guided by a Home
Rule Charter."* Manatee is **non**-charter. This is exactly the variation `fl.md` warns about, and the
difference is a real seat:

| Office | Incumbent | Takes office |
| --- | --- | --- |
| Clerk of the Circuit Court and Comptroller | Gwen Marshall | 1st Tuesday after 1st Monday in January |
| Property Appraiser | Akin Akinyemi | 1st Tuesday after 1st Monday in January |
| Sheriff | Walt McNeil | 1st Tuesday after 1st Monday in January |
| **Superintendent of Schools** | **Rocky Hanna** | **2nd Tuesday after the General Election** |
| Supervisor of Elections | Mark S. Earley | 1st Tuesday after 1st Monday in January |
| Tax Collector | Doris Maloy | 1st Tuesday after 1st Monday in January |

**Leon elects its Superintendent of Schools; Manatee does not.** All six are next up in **2028**, so
none is on the 2026 ballot. Note the Superintendent's take-office rule differs from the other five's.

### The rosters as published, 2026-08-28

Source: the Leon County Supervisor of Elections' "Elected Officials" page, which covers **both** bodies
in one document — the same convenience Manatee's SOE offered.

**City of Tallahassee** — five seats, all at-large, all filled.

| Seat | Incumbent | Next election |
| --- | --- | --- |
| Seat 1 | Jacqueline "Jack" Porter | 2028 |
| Seat 2 | Curtis Richardson | 2028 |
| Seat 3 | Jeremy Matlow | 2026 |
| **Seat 4, Mayor** | **John Dailey** | 2026 |
| Seat 5 | Dianne Williams-Cox | 2026 |

⚠ **Seat 3 went to a manual recount in the 2026 primary.** The SOE's site banner, 2026-08-28: the
Canvassing Board completed a manual recount of the City Commission Seat 3 race on **August 24** and
certified the primary. The general election is still ahead, so Matlow holds the seat now — but this is
live churn, and Task 3 Step 4 must re-check it.

**Leon County Commission** — seven seats, all filled. Members take office on the **2nd Tuesday after
the General Election**.

| Office | Incumbent | Next election | Service since |
| --- | --- | --- | --- |
| At Large, Group 1 | Carolyn Cummings | 2028 | 2020 |
| At Large, Group 2 | Nick Maddox | 2026 | 2010 |
| District 1 | Bill Proctor | 2026 | **1996** |
| District 2 | Christian Caban | 2028 | 2022 |
| District 3 | Rick Minor | 2026 | 2018 |
| District 4 | Brian Welch | 2028 | 2020 |
| District 5 | David O'Keefe | 2026 | 2022 |

⚠ **The at-large seats are "At Large, Group 1" and "At Large, Group 2" — NOT "District 6" and
"District 7".** Manatee numbers its at-large seats 6 and 7. Two counties in one state, two conventions.
**Follow the publisher; do not normalise.**

**Total: 5 + 7 + 6 = 18 offices, 18 people, 0 vacancies.** Same size as FL-3, with no vacancy to flag —
so `is_vacant` is not load-bearing in this wave, and every one of the 18 offices must end with a term
row.

### `term_start` — Leon publishes what Bradenton would not

🔴 **The county's own "Leading the Way" history page publishes a service-year range per commissioner**
(`cms.leoncountyfl.gov/leadingtheway/County-Commissioners`), which is the source FL-3 lacked and had to
record three `unknown` precisions for. The **first** number is the service start; the second is the
current term's expiry. So all seven commissioners get at least **`year`** precision, and Task 3 should
try each commissioner's own detail page (`…/County-Commissioners/Details/<slug>`) for a better one.

**Already verified, so do not re-derive:**

- **Nick Maddox has held At Large Group 2 continuously since 2010** — he did not move from a district.
  That was the Nashville Porterfield/Henderson trap and it does **not** apply to him. Check the other
  six the same way.
- **John Dailey was elected Mayor in 2018**, from his own city page. He was previously Leon County
  Commission **District 3, 2006–2018**, which the county history page independently confirms. His
  occupancy of the **mayoralty** therefore starts in 2018, not 2006. `term_start` is per seat.
- **Akin Akinyemi, now Property Appraiser, was a county commissioner 2008–2012.** Same person, two
  offices, years apart. His Property Appraiser occupancy is a separate span.

⚠ **A "next election" year is not a start date and not an expiry-minus-four.** Four of seventeen people
in FL-3 broke that assumption; five of seventeen in NC. Take the start from the officeholder's own page.

### Geography — one layer to load, and two independent digitizations of it

| Service | Layer | Rows | Field | Native SR |
| --- | --- | --- | --- | --- |
| **`SOE_DistrictsCurrent_D_WM`** | **1** — "County Commission 2022" | 5 | `DISTRICT` (**text** `'1'`…`'5'`) | 3857 |
| `TLC_OverlayCommissionDistrictFeature_D_WM` | 0 — "Leon County Commission Districts" | 5 | `DISTRICT` (text) | 3857 |

Base: `https://intervector.leoncountyfl.gov/intervector/rest/services/MapServices`

🔴 **Use the SOE service as primary.** `fl.md` already trusts it: its layers **5 (FL House 2022)** and
**4 (FL Senate 2022)** are the services the FL-1 vintage check used for the Tallahassee anchor. The
county GIS overlay is the cross-check. Both returned **District 5** at city hall.

**Two free bonuses in the same service:**

- **Layer 6, "City Limits"** (1 row, `NAME = 'TALLAHASSEE'`) — an **independent** digitization of the
  city boundary, so the citywide district can be checked against TIGER place `1270600` rather than
  assumed. Bradenton had no such control.
- Layers 4 and 5 let the wave re-confirm HD-9 / SD-3 from the same source `fl.md` cited.

⚠ **`TOTALPOP20` is `0` on every row in both services.** It is a dead field; do not gate on it.

### 🔴 The anchor — Tallahassee City Hall

**300 South Adams Street, Tallahassee FL 32301.** Geocodes cleanly, unlike Bradenton's ceremonial
address: `300 S ADAMS ST, TALLAHASSEE, FL, 32301` → **`-84.2820030, 30.4395411`**.

| Answer | Value | Confirmed by |
| --- | --- | --- |
| County commissioner | **District 5** → David O'Keefe | both commission services agree |
| State representative | **HD-9** | SOE layer 5, and `fl.md`'s FL-1 vintage check |
| State senator | **SD-3** | SOE layer 4, and `fl.md`'s FL-1 vintage check |
| City commissioners | **all five** | at-large; inside SOE "City Limits" and TIGER place `1270600` |

### Prod state, measured 2026-08-28

| Thing | State |
| --- | --- |
| Leon County district (`12073`/`G4020`/`COUNTY`) | **exists** — reuse, do not create. The 2 at-large seats and all 6 officers hang off it. |
| Leon county polygon (`12073`/`G4020`) | exists |
| Tallahassee place polygon (`1270600`/`G4110`) | exists (FL-1) |
| Tallahassee district row | **absent** — this wave creates it |
| Governments for `12073` / `1270600` | **absent** — this wave creates both |
| `X0038` districts | 0 |
| Name collisions among all 18 people | **ZERO** — all are fresh inserts, nothing to reuse |

**`external_id` band: continue `-(1240000 + n)`.** FL-3 used `n = 1…6`, `11…17`, `21…25` (17 of 10,000).
FL-4 takes **city `n = 31…35`, commission `n = 41…47`, officers `n = 51…56`**. The band guard must
allowlist FL-4's own 18 ids only — FL-3's 17 are legitimately present and must not trip it.

### Template rows

`governments`:

| name | type | state | city | geo_id |
| --- | --- | --- | --- | --- |
| `City of Tallahassee, Florida, US` | `City` | `FL` | `Tallahassee` | `1270600` |
| `Leon County, Florida, US` | `County` | `FL` | *(NULL)* | `12073` |

`chambers` — ⚠ **`slug` is GENERATED from `name_formal` and cannot be inserted.**

| government | name | name_formal | official_count |
| --- | --- | --- | --- |
| Tallahassee | `City Commission` | `Tallahassee City Commission` | 5 |
| Leon | `Board of County Commissioners` | `Leon County Board of County Commissioners` | 7 |
| Leon | `Elected Officials` | `Leon County Elected Officials` | 6 |

⚠ **Tallahassee gets ONE chamber, not two.** Bradenton needed a separate `Office of the Mayor` because
its mayor sits outside the five-member council. Tallahassee's mayor **is** Seat 4 of the five-member
commission, so one chamber of 5 is the honest shape — and there is no tie-break ruling to make.

`districts`:

| label | district_type | geo_id | mtfcc | num_officials |
| --- | --- | --- | --- | --- |
| `Tallahassee Citywide` | `LOCAL` | `1270600` | `G4110` | 5 |
| `Leon County Commissioner District 1` … `District 5` | `COUNTY` | `leon-fl-commissioner-district-1` … `-5` | `X0038` | 1 |

⚠ **`num_officials = 5` on the citywide district**, because five seats really do share it. Bradenton's
citywide district carries one. Buncombe's `X0034` rows carry 2 for the same reason.

### Decisions this plan makes

1. **The elected Superintendent of Schools IS seated**, in the `Elected Officials` chamber. The SOE
   lists it under "Leon County Constitutional Offices"; it is elected countywide; excluding it would
   under-report Leon's government by a real seat. **The school BOARD stays out of scope**, consistent
   with FL-3 — a board is a separate legislative body, and spec §3 stage 4 is "commission layer +
   county officers".
2. **One chamber for Tallahassee**, per the note above.
3. **No `voting_powers` ruling is needed.** Tallahassee's mayor is one of five equal commissioners with
   a full vote. Bradenton's tie-break question does not arise. Confirm from the charter in Task 3
   anyway, and record the confirmation.

### Out of scope, considered

Leon County School Board; Leon Soil and Water Conservation District; Canopy, Capital Region,
Fallschase and Piney-Z Community Development Districts — all elected, all listed by the SOE, none a
county commission or constitutional officer.

---

## Task 1: Leon commission district boundaries — load 5 districts as `X0038`

**Files:**
- Create: `backend/scripts/load-leon-commission-boundaries.ts`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: 5 rows in `essentials.geofence_boundaries`, `mtfcc = 'X0038'`, `state = 'fl'`,
  `geo_id = 'leon-fl-commissioner-district-' || n` for `n` in 1..5. Task 4's county migration joins on
  exactly those three values.

- [ ] **Step 1: Copy the Manatee loader — it is the closest template**

```bash
cd /c/EV-Accounts/backend && cp scripts/load-manatee-commission-boundaries.ts scripts/load-leon-commission-boundaries.ts
```

Read it end to end first. Its shape is exactly right: a primary service, a cross-check against a second
independently-published digitization, per-district area gates, a negative control, and a tiling gate
against the TIGER county polygon. Keep all of it.

- [ ] **Step 2: Re-point the constants**

Two differences from Manatee to be careful about: these are **MapServer** endpoints, not FeatureServer,
and `DISTRICT` is **text**, not an integer.

```ts
const BASE =
  'https://intervector.leoncountyfl.gov/intervector/rest/services/MapServices';

/** The SOE's own layer. fl.md already trusts this service: its layers 5 and 4 are the FL House and
 *  Senate services the FL-1 vintage check used for the Tallahassee anchor. */
const PRIMARY_URL =
  `${BASE}/SOE_DistrictsCurrent_D_WM/MapServer/1/query` +
  '?where=1%3D1&outFields=DISTRICT' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

/** The county GIS overlay — a second digitization, used only as a cross-check. */
const CROSSCHECK_URL =
  `${BASE}/TLC_OverlayCommissionDistrictFeature_D_WM/MapServer/0/query` +
  '?where=1%3D1&outFields=DISTRICT' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

/** Layer 6 of the SOE service: an INDEPENDENT digitization of the city boundary, used to check
 *  TIGER place 1270600 rather than assume it. Bradenton had no such control. */
const CITY_LIMITS_URL =
  `${BASE}/SOE_DistrictsCurrent_D_WM/MapServer/6/query` +
  '?where=1%3D1&outFields=NAME' +
  '&returnGeometry=true&f=geojson&outSR=4326';

const MTFCC = 'X0038';
const STATE_CODE = 'fl';
const SOURCE = 'leoncountyfl-intervector-SOE_DistrictsCurrent-1-2026-08-28';
const GEO_ID_PREFIX = 'leon-fl-commissioner-district-';
const COUNTY_GEO_ID = '12073';
const PLACE_GEO_ID = '1270600';
const EXPECTED_COUNT = 5;
```

⚠ **`DISTRICT` is TEXT (`'1'`…`'5'`).** Parse it the way the Bradenton ward loader parses `WARD`
(`/^[1-5]$/` on a trimmed string), **not** the way the Manatee loader parses `COMMDIST`
(`Number.isInteger`). A `Number.isInteger('3')` test is `false` and would silently skip every district.

- [ ] **Step 3: Replace the control points**

```ts
const CONTROL_POINTS: Array<{ name: string; lon: number; lat: number; district: string }> = [
  { name: 'Tallahassee City Hall (300 S Adams St)', lon: -84.2820030, lat: 30.4395411, district: '5' },
];

/**
 * 🔴 THE CONTROL OF THE CONTROL. Thomasville, Georgia is ~35 miles north, across the state line.
 * It must fall in NO Leon County commission district. Without a negative control, a query that
 * cannot fire at all still passes every positive control.
 */
const NEGATIVE_CONTROL = { name: 'Thomasville GA (city hall)', lon: -83.9788, lat: 30.8366 };
```

⚠ **One positive control is thin.** Before trusting it, add two more by picking any two points from
different districts: query the primary service for each district's `centroid` via
`returnGeometry=false&returnCentroid=true`, then assert that each centroid falls in its own district.
Record the coordinates in the file as literals, the way Manatee's are, so the gate is reproducible.

- [ ] **Step 4: Set the per-district area expectations**

Do **not** copy Manatee's numbers. Measure Leon's once, print them, and paste them in:

```bash
cd /c/EV-Accounts/backend && npx tsx -e "
const B='https://intervector.leoncountyfl.gov/intervector/rest/services/MapServices';
const u=B+'/SOE_DistrictsCurrent_D_WM/MapServer/1/query?where=1%3D1&outFields=DISTRICT&returnGeometry=true&f=geojson&outSR=4326';
const r=await (await fetch(u)).json();
const {Pool}=await import('pg'); await import('dotenv/config');
const p=new Pool({connectionString:process.env.DATABASE_URL, ssl:{rejectUnauthorized:false}});
for (const f of r.features.sort((a,b)=>a.properties.DISTRICT.localeCompare(b.properties.DISTRICT))) {
  const {rows:[x]}=await p.query('SELECT public.ST_Area(public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON(\$1::text),4326))::geography)/2589988.11 AS sq_mi',[JSON.stringify(f.geometry)]);
  console.log(f.properties.DISTRICT, Number(x.sq_mi).toFixed(2));
}
await p.end();"
```

Paste the five values into `EXPECTED_SQ_MI` keyed by the **string** district, and keep the 1 %
tolerance.

- [ ] **Step 5: Add the city-limits control**

New gate, not present in the Manatee loader. It checks the polygon the **city** seats will hang off,
which no other gate in this wave touches:

```ts
  console.log('\n  City-limits control (SOE layer 6 vs TIGER place ' + PLACE_GEO_ID + '):');
  const cl = await (await fetch(CITY_LIMITS_URL)).json();
  if (cl?.features?.length !== 1) {
    console.error(`FAIL: expected 1 city-limits feature, got ${cl?.features?.length}`);
    await pool.end();
    process.exit(1);
  }
  const { rows: [c] } = await pool.query(
    `WITH soe AS (SELECT public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($1::text), 4326)) g),
          tig AS (SELECT geometry g FROM essentials.geofence_boundaries
                   WHERE geo_id = $2 AND mtfcc = 'G4110')
     SELECT (public.ST_Area(soe.g::geography) / $3)::numeric(12,3)  AS soe_sq_mi,
            (public.ST_Area(tig.g::geography) / $3)::numeric(12,3)  AS tiger_sq_mi,
            (public.ST_Area(public.ST_SymDifference(soe.g, tig.g)::geography) / $3)::numeric(12,3) AS symdiff_sq_mi,
            public.ST_Covers(tig.g, public.ST_SetSRID(public.ST_MakePoint($4, $5), 4326)) AS tiger_covers_city_hall
       FROM soe, tig`,
    [JSON.stringify(cl.features[0].geometry), PLACE_GEO_ID, SQ_M_PER_SQ_MI,
     CONTROL_POINTS[0].lon, CONTROL_POINTS[0].lat],
  );
  console.log(
    `    SOE ${c.soe_sq_mi} sq mi vs TIGER ${c.tiger_sq_mi} sq mi, symmetric difference ` +
    `${c.symdiff_sq_mi} sq mi; TIGER covers city hall: ${c.tiger_covers_city_hall}`,
  );
  if (c.tiger_covers_city_hall !== true) {
    console.error(
      `FAIL: TIGER place ${PLACE_GEO_ID} does not cover Tallahassee City Hall. The city seats would ` +
      `be unreachable from the anchor address.`,
    );
    await pool.end();
    process.exit(1);
  }
```

⚠ **Report the symmetric difference; do NOT gate hard on it yet.** Two agencies' city boundaries differ
by annexation timing, and Bradenton's equivalent gap was 18 % of the polygon and entirely legitimate
(water). Read the printed number, then decide a threshold and write it in with the measured value
beside it — the same discipline as the ward `AREALAND` gate. **The load-bearing assertion is
`tiger_covers_city_hall`.**

- [ ] **Step 6: Dry-run, prove two gates can fail, then load**

```bash
cd /c/EV-Accounts/backend && npx tsx scripts/load-leon-commission-boundaries.ts --dry-run
```

Then prove the gates are real, as FL-3 did:

```bash
cd /c/EV-Accounts/backend && cp scripts/load-leon-commission-boundaries.ts /tmp/leon.bak && \
sed -i "s|lon: -83.9788, lat: 30.8366 };|lon: -84.2820030, lat: 30.4395411 };|" scripts/load-leon-commission-boundaries.ts && \
npx tsx scripts/load-leon-commission-boundaries.ts --dry-run 2>&1 | grep -E 'FAIL|ERROR' | head -3 ; \
cp /tmp/leon.bak scripts/load-leon-commission-boundaries.ts
```

Expected: `FAIL  Thomasville GA (city hall): expected no district, got D5` and a refusal to write.
Then narrow the cross-check URL to `where=DISTRICT%3D%271%27` and confirm it reports
`the cross-check service has no district 2`. Revert both. Then:

```bash
cd /c/EV-Accounts/backend && npx tsx scripts/load-leon-commission-boundaries.ts
```

- [ ] **Step 7: Verify the loaded geometry from the DATABASE, not from the fetch**

🔴 **Every gate above runs on the pre-repair GeoJSON.** Four of five Bradenton wards needed
`ST_MakeValid`, so the stored geometry must be re-checked:

```bash
cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -c "
SELECT geo_id, public.ST_IsValid(geometry) AS valid,
       round((public.ST_Area(geometry::geography)/2589988.11)::numeric,2) AS sq_mi,
       public.ST_Covers(geometry, public.ST_SetSRID(public.ST_MakePoint(-84.2820030,30.4395411),4326)) AS covers_city_hall
  FROM essentials.geofence_boundaries WHERE mtfcc='X0038' ORDER BY geo_id;"
```

Expected: 5 rows, all `valid = t`, **exactly one** with `covers_city_hall = t` (district 5), and the
five areas matching Step 4's measurement.

- [ ] **Step 8: Commit**

```bash
cd /c/EV-Accounts && git add backend/scripts/load-leon-commission-boundaries.ts && git commit -F- -- backend/scripts/load-leon-commission-boundaries.ts <<'MSG'
feat(knight-fl): load Leon's 5 commission districts as X0038

Primary is the Supervisor of Elections' own layer, which fl.md already trusts:
layers 5 and 4 of the same service are the FL House and Senate services the FL-1
vintage check used. Cross-checked against the county GIS overlay, and the
service's City Limits layer gives an independent check on TIGER place 1270600 —
a control Bradenton did not have.

DISTRICT is TEXT here, not an integer as in Manatee's service, so the parser
follows the Bradenton ward loader instead.

Tallahassee needs no ward layer: its commission is entirely at-large.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
MSG
```

---

## Task 2: Reconcile the roster and write `ROSTERS.md`

**Files:**
- Create: `backend/data/seed-tallahassee-leon-2026/ROSTERS.md`
- Modify: `backend/.gitignore` — add `data/seed-tallahassee-leon-2026/_*.html`
- Create (untracked evidence): `backend/data/seed-tallahassee-leon-2026/_*.html`

**Interfaces:**
- Consumes: nothing. **Reads no database.**
- Produces the same eight-column contract the FL-3 generator already parses, so `parseRosters` needs no
  change:
  `| Seat | Slug | Name | external_id | term_start | precision | how_started | source |`
  Slugs: `seat-1`, `seat-2`, `seat-3`, `seat-4-mayor`, `seat-5`; `commissioner-1`…`commissioner-5`,
  `at-large-group-1`, `at-large-group-2`; `sheriff`, `tax-collector`, `property-appraiser`,
  `supervisor-of-elections`, `clerk-of-circuit-court`, `superintendent-of-schools`.
  Plus the trailing `<!-- COUNTS: … -->` line.

- [ ] **Step 1: Pull the sources with Playwright, not curl**

`curl` gets a hard 403 from both Leon domains. Use the Playwright MCP: navigate, then
`browser_evaluate` returning `document.body.innerText`, and write the text to disk. Pull:

- `https://www.leonvotes.gov/Candidates/Elected-Officials` — **the key source**, both bodies in one
  page. ⚠ Its categories are **collapsed accordions**; the content is in the DOM but hidden. Read it
  by locating the exact category headings and walking up to the container, as in
  `_soe-elected-officials` — a plain `innerText` of the page body returns only the headings.
- `https://www.leonvotes.gov/Candidates/Candidates/Offices-Up-for-Election` — the independent
  cross-check on which seats are contested, which is what exposed Manatee's stale roster.
- `https://cms.leoncountyfl.gov/leadingtheway/County-Commissioners` — service-year ranges per
  commissioner.
- `https://cms.leoncountyfl.gov/leadingtheway/County-Commissioners/Details/<slug>` for each of the
  seven — for a better-than-year start date.
- `https://www.talgov.com/cityleadership/dailey`, `/matlow`, `/porter`, `/richardson`,
  `/williams-cox` — the city bios. These answer `curl` too.
- Each constitutional officer's own site, from the SOE's `Website` column: `cvweb.leonclerk.com`,
  `leonpa.gov`, `leoncountyso.com`, `leonschools.net`, `leonvotes.gov`, `leontaxcollector.net`.

- [ ] **Step 2: Establish `term_start` per person, and check for a seat change**

The rule and its traps are in "Facts measured" above. Concretely:

- Take the **first** year of the county history page's range as the service start, then try to improve
  it from the commissioner's own detail page.
- 🔴 **For every commissioner, ask whether they moved between seats.** Occupancy of the *current* seat
  starts when they took *that* seat. Maddox is already verified (At Large Group 2 since 2010, no move)
  — verify the other six.
- **Dailey's mayoralty starts 2018**, not 2006; his county service was a different office.
- **Akinyemi's Property Appraiser span is separate** from his 2008–2012 county commission service.
- **Bill Proctor has served since 1996** — the longest tenure in this wave by two decades. Expect his
  own page to date it precisely; if it gives only the year, `year` precision is correct.
- The take-office rules differ by body and are useful for turning an election date into a start date:
  city **13th day after** the general election; commission **2nd Tuesday after**; five officers **1st
  Tuesday after the 1st Monday in January**; **Superintendent 2nd Tuesday after** the general election.
  Applying a published rule to a published election date is a derivation, not a guess — **state the
  derivation in `ROSTERS.md`** and set precision to what is actually known.
- If a start is genuinely unpublished, use `unknown` precision and no date. Three of six Bradenton
  council members ended there and that was the honest answer.

- [ ] **Step 3: Check every seat for a change since the sources were edited**

- 🔴 **Tallahassee Seat 3 had a manual recount in the 2026 primary, completed 2026-08-24.** Confirm
  Matlow still holds the seat and that nothing has changed since.
- Check all 18 for a resignation, death or appointment since 2026-06-01. FL-3's District 1 was a death
  the SOE roster had not caught.
- Re-read the SOE's two pages against each other. In Manatee they contradicted each other on a vacancy.

- [ ] **Step 4: Write `ROSTERS.md`**

Four sections, matching `data/seed-bradenton-manatee-2026/ROSTERS.md`: `## Sources`,
`## 🔴 Source defects found`, `## Charter rulings`, `## Roster`. The charter rulings must record, at
minimum:

- **Leon is a CHARTER county** (Home Rule Charter, 2002-11-12) and elects **six** constitutional
  officers, including the **Superintendent of Schools** — cite the charter article, not just the SOE
  page.
- **Tallahassee's commission is five at-large seats and the Mayor is Seat 4**; confirm from the city
  charter and record whether the mayor has any procedural power the schema should carry. The expected
  answer is no: one of five equal votes, so `voting_powers = 'full'` with no note. **If the charter says
  otherwise, that is a ruling to make explicitly**, the way Bradenton's was.
- Which bodies are out of scope, and why.

- [ ] **Step 5: Assert the counts in the file**

```markdown
<!-- COUNTS: city_offices=5 city_people=5 county_offices=13 county_people=13 vacancies=0 -->
```

If Step 3 found any change, every number downstream changes with it — that is the guard working.

- [ ] **Step 6: Commit the roster, not the raw HTML**

```bash
cd /c/EV-Accounts/backend && printf 'data/seed-tallahassee-leon-2026/_*.html\n' >> .gitignore
cd /c/EV-Accounts && git add backend/.gitignore backend/data/seed-tallahassee-leon-2026/ROSTERS.md && git commit -F- -- backend/.gitignore backend/data/seed-tallahassee-leon-2026/ROSTERS.md <<'MSG'
docs(knight-fl): reconciled roster for Tallahassee and Leon County

18 offices, 18 people, no vacancies. Leon is a CHARTER county and elects SIX
constitutional officers including the Superintendent of Schools; Manatee, which is
non-charter, elects five. That is the variation fl.md warns against inheriting.

Tallahassee's commission is five at-large seats with the Mayor as Seat 4, so this
wave needs no city ward layer and every Tallahassee address returns all five
commissioners.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
MSG
```

---

## Task 3: Generator — copy FL-3's and re-point it

**Files:**
- Create: `backend/scripts/gen-tallahassee-leon-migrations.mjs`
- Create: `backend/scripts/gen-tallahassee-leon-migrations.test.ts`
- Create (output): `backend/migrations/CC_wip_tallahassee_structure.sql`,
  `CC_wip_tallahassee_people.sql`, `CC_wip_leon_county.sql`

**Interfaces:**
- Consumes: `data/seed-tallahassee-leon-2026/ROSTERS.md`; the `X0038` boundaries from Task 1.
- Produces the same exports as FL-3's generator — `parseRosters`, `renderCityStructure`,
  `renderCityPeople`, `renderCounty` — so the test file is a copy with new fixtures.

- [ ] **Step 1: Copy both files**

```bash
cd /c/EV-Accounts/backend && \
cp scripts/gen-bradenton-manatee-migrations.mjs scripts/gen-tallahassee-leon-migrations.mjs && \
cp scripts/gen-bradenton-manatee-migrations.test.ts scripts/gen-tallahassee-leon-migrations.test.ts
```

Everything structural carries over unchanged: the `COUNTS` guard, the slug allowlist refusal, the
precision/`how_started` validation, the "no `term_start` without `unknown` precision" rule, the party
marking refusal, the duplicate-id check, the two-path occupancy block, the allowlist band guard, and
the per-district post-verify gates. **Do not re-derive any of it.**

- [ ] **Step 2: Change the identity constants**

```js
const ROSTER = join(HERE, '..', 'data', 'seed-tallahassee-leon-2026', 'ROSTERS.md');
const COUNTY_MTFCC = 'X0038';
const PLACE_GEO_ID = '1270600';   // TIGER place, Tallahassee city (G4110). Loaded by FL-1.
const COUNTY_GEO_ID = '12073';    // TIGER county, Leon County (G4020). Pre-existing.
const COUNTY_DIST_PREFIX = 'leon-fl-commissioner-district-';
const CITY_GOV = 'City of Tallahassee, Florida, US';
const COUNTY_GOV = 'Leon County, Florida, US';
```

**Delete `CITY_MTFCC` and `CITY_WARD_PREFIX` entirely** — there is no city ward layer. Delete the
`MAYOR_DESCRIPTION` constant, the `D1_VACANT_SINCE`/`D1_VACANCY_SOURCE` constants, and the whole
"flag District 1 vacant" section of `renderCounty`: **this wave has no vacancy**.

- [ ] **Step 3: Rewrite the two seat maps**

```js
const CITY_SEATS = {
  'seat-1':       { title: 'City Commissioner, Seat 1', chamber: 'City Commission', on: 'citywide' },
  'seat-2':       { title: 'City Commissioner, Seat 2', chamber: 'City Commission', on: 'citywide' },
  'seat-3':       { title: 'City Commissioner, Seat 3', chamber: 'City Commission', on: 'citywide' },
  'seat-4-mayor': { title: 'Mayor (Seat 4)',            chamber: 'City Commission', on: 'citywide' },
  'seat-5':       { title: 'City Commissioner, Seat 5', chamber: 'City Commission', on: 'citywide' },
};

const COUNTY_SEATS = {
  'commissioner-1': { title: 'Commissioner, District 1', chamber: 'Board of County Commissioners', on: 'commdist', n: 1 },
  'commissioner-2': { title: 'Commissioner, District 2', chamber: 'Board of County Commissioners', on: 'commdist', n: 2 },
  'commissioner-3': { title: 'Commissioner, District 3', chamber: 'Board of County Commissioners', on: 'commdist', n: 3 },
  'commissioner-4': { title: 'Commissioner, District 4', chamber: 'Board of County Commissioners', on: 'commdist', n: 4 },
  'commissioner-5': { title: 'Commissioner, District 5', chamber: 'Board of County Commissioners', on: 'commdist', n: 5 },
  // ⚠ "At Large, Group N" is Leon's OWN naming. Manatee numbers its at-large seats District 6 and 7.
  //    Two counties in one state, two conventions. Follow the publisher.
  'at-large-group-1': { title: 'Commissioner, At Large Group 1', chamber: 'Board of County Commissioners', on: 'countywide' },
  'at-large-group-2': { title: 'Commissioner, At Large Group 2', chamber: 'Board of County Commissioners', on: 'countywide' },
  'sheriff':                   { title: 'Sheriff', chamber: 'Elected Officials', on: 'countywide' },
  'tax-collector':             { title: 'Tax Collector', chamber: 'Elected Officials', on: 'countywide' },
  'property-appraiser':        { title: 'Property Appraiser', chamber: 'Elected Officials', on: 'countywide' },
  'supervisor-of-elections':   { title: 'Supervisor of Elections', chamber: 'Elected Officials', on: 'countywide' },
  'clerk-of-circuit-court':    { title: 'Clerk of the Circuit Court and Comptroller', chamber: 'Elected Officials', on: 'countywide' },
  // 🔴 Leon is a CHARTER county and elects this; Manatee does not have the office.
  'superintendent-of-schools': { title: 'Superintendent of Schools', chamber: 'Elected Officials', on: 'countywide' },
};
```

In `districtRef`, **delete the `'ward'` case** and leave `'citywide'`, `'countywide'` and `'commdist'`.

- [ ] **Step 4: Change the chambers and the counts the gates assert**

In `renderCityStructure`: emit **one** chamber, `City Commission` / `Tallahassee City Commission` /
`official_count = 5`, and set the citywide district's `num_officials` to **5**. Delete the
`Office of the Mayor` insert. In the post-verify gate, replace the per-ward loop with:

```sql
  -- 🔴 ALL FIVE SEATS SHARE THE CITYWIDE DISTRICT, because Tallahassee's commission is entirely
  -- at-large. So the per-district assertion here is "exactly 5 on one district", which is the
  -- OPPOSITE shape from Bradenton's "exactly 1 per ward" -- and the reason num_officials is 5.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND d.geo_id = '1270600' AND d.mtfcc = 'G4110'
     AND d.district_type = 'LOCAL';
  IF v_n <> 5 THEN RAISE EXCEPTION 'tallahassee structure: expected 5 offices on the citywide district, got %', v_n; END IF;

  -- And all five titles must be distinct, or two seats collapsed into one.
  SELECT count(DISTINCT o.title) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov;
  IF v_n <> 5 THEN RAISE EXCEPTION 'tallahassee structure: expected 5 distinct seat titles, got %', v_n; END IF;
```

Delete the Mayor `voting_powers`/`description` assertion — there is no such ruling here.

In `renderCounty`: `Elected Officials` has `official_count = 6`, and the countywide-district office
count is **8** (2 at-large + 6 officers), not 7. The occupancy gate asserts **13 seated, 0 vacant**,
and one seated commissioner per district for **all five** districts (Manatee's loop skipped District 1).

- [ ] **Step 5: Update the test fixture and add one new case**

Rewrite `FIXTURE` in the test with Tallahassee/Leon slugs and a `COUNTS` line matching it. Every
existing test carries over. Add one that pins this wave's distinguishing shape:

```ts
  it('puts all five city seats on the citywide district', () => {
    const r = parseRosters(FIXTURE);
    expect(r.city.every((s: any) => s.on === 'citywide')).toBe(true);
    expect(new Set(r.city.map((s: any) => s.title)).size).toBe(r.city.length);
  });

  it('accepts a county table with no vacancy', () => {
    const r = parseRosters(FIXTURE);
    expect(r.county.some((s: any) => s.isVacant)).toBe(false);
    expect(r.counts.vacancies).toBe(0);
  });
```

- [ ] **Step 6: Run the tests, generate, and run the four safety greps**

```bash
cd /c/EV-Accounts/backend && npx vitest run scripts/gen-tallahassee-leon-migrations.test.ts && \
node scripts/gen-tallahassee-leon-migrations.mjs && \
echo '--- party words (expect only the comment that forbids them) ---' && grep -niE "\((R|D|DEM|REP)\)|republican|democrat" migrations/CC_wip_tallahassee_*.sql migrations/CC_wip_leon_county.sql ; \
echo '--- term_end (expect only comments) ---' && grep -n 'term_end' migrations/CC_wip_*.sql ; \
echo '--- ward leftovers (expect none) ---' && grep -niE 'ward|X0036|X0037|bradenton|manatee' migrations/CC_wip_tallahassee_*.sql migrations/CC_wip_leon_county.sql ; \
echo '--- every districts lookup pairs geo_id+mtfcc+district_type ---' && grep -c "district_type = '" migrations/CC_wip_leon_county.sql
```

⚠ The **ward leftovers** grep is the one that matters most in a copied generator: a stray `X0036`
or `bradenton-fl-council-ward-` reference would resolve to a real Bradenton district and hang a
Tallahassee office off it. It must return nothing.

- [ ] **Step 7: Commit the generator and test**

```bash
cd /c/EV-Accounts && git add backend/scripts/gen-tallahassee-leon-migrations.mjs backend/scripts/gen-tallahassee-leon-migrations.test.ts && git commit -F- -- backend/scripts/gen-tallahassee-leon-migrations.mjs backend/scripts/gen-tallahassee-leon-migrations.test.ts <<'MSG'
feat(knight-fl): generator for the Tallahassee and Leon migrations

Copied from the Bradenton/Manatee generator and re-pointed. The structural
guards carry over unchanged: the COUNTS assertion, the slug allowlist, the
allowlist band guard, and the two-path occupancy block.

Two shape changes. Tallahassee's commission is entirely at-large, so all five
seats share the citywide district and the post-verify asserts "5 on one district"
rather than "1 per ward". Leon elects six constitutional officers, not five,
because it is a charter county — the Superintendent of Schools is elected here.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
MSG
```

---

## Task 4: Dry-run, apply, gate, probe, commit

**Files:**
- Rename to `CC_0011_tallahassee_structure.sql`, `CC_0012_tallahassee_people.sql`,
  `CC_0013_leon_county.sql`
- Create: `backend/scripts/verify-tallahassee-leon-probes.sql`

- [ ] **Step 1: Write the probe**

Copy `scripts/verify-bradenton-manatee-probes.sql` and change the anchor to
`-84.2820030, 30.4395411`, the government `geo_id`s to `1270600` and `12073`, and the `X` codes to
`X0038`. Keep probe 2 (the unpaired-join collision demonstration) — **`12073` is Leon County *and*
HD-73**, so it demonstrates here too. Change the required-answers block to:

```sql
required(n, what, dt, geo, mt, expect_rows) AS (VALUES
  (1, 'city commissioners (all 5, at-large)', 'LOCAL',  '1270600',                        'G4110', 5),
  (2, 'county commissioner',                  'COUNTY', 'leon-fl-commissioner-district-5','X0038', 1),
  (3, 'state representative',                 'STATE_LOWER', '12009',                     'G5220', 1),
  (4, 'state senator',                        'STATE_UPPER', '12003',                     'G5210', 1)
)
```

⚠ **Verify those two state `geo_id`s before trusting them.** HD-9 and SD-3 are the districts, but
Florida's `sldl`/`sldu` GEOIDs are `12` + a zero-padded district number, so HD-9 should be `12009` and
SD-3 `12003`. **Confirm with a query rather than assuming the padding**, then fix the literals:

```bash
cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -At -F ' | ' -c "
SELECT d.district_type, d.label, d.geo_id, d.mtfcc FROM essentials.districts d
 WHERE lower(d.state)='fl' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
   AND d.label IN ('State House District 9','State Senate District 3');"
```

The assertion must compare a **count per required answer**, not mere presence, so that "all five city
commissioners" cannot pass with four.

- [ ] **Step 2: Run the probe BEFORE applying**

```bash
cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -f scripts/verify-tallahassee-leon-probes.sql
```

Expected pre-state: the two state rows only — HD-9 and SD-3 — and 0 city, 0 county. If it differs, the
DB moved and the counts here need re-measuring.

- [ ] **Step 3: Dry-run each file separately, its own COMMIT turned into ROLLBACK**

```bash
cd /c/EV-Accounts/backend && for f in CC_wip_tallahassee_structure CC_wip_tallahassee_people CC_wip_leon_county; do
  echo "=== DRY RUN $f ==="
  sed 's/^COMMIT;$/ROLLBACK;/' "migrations/$f.sql" | psql "$DATABASE_URL" -v ON_ERROR_STOP=1 2>&1 | tail -8
done
```

⚠ **`CC_wip_tallahassee_people` will fail on its own against untouched prod**, because its offices do
not exist yet. That is correct. Apply the structure first (Step 5), then dry-run the people half.
**Do not concatenate them to get around this** — that is the FL-3 autocommit incident.

- [ ] **Step 4: Confirm each rollback reverted**

```bash
cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -At -F ' | ' -c "
SELECT (SELECT count(*) FROM essentials.governments WHERE geo_id IN ('1270600','12073')),
       (SELECT count(*) FROM essentials.districts WHERE mtfcc='X0038'),
       (SELECT count(*) FROM essentials.politicians WHERE external_id BETWEEN -1240060 AND -1240030);"
```

Expected `0 | 5 | 0` — the `X0038` **boundaries** are loaded by Task 1 but the `X0038` **district rows**
are created by `CC_0013`, so this counts districts and must read 0 until then.

- [ ] **Step 5: Take the numbers last, then apply in order**

```bash
cd /c/EV-Accounts && git fetch origin && cd backend && npm run check:migrations && \
git mv migrations/CC_wip_tallahassee_structure.sql migrations/CC_0011_tallahassee_structure.sql && \
git mv migrations/CC_wip_tallahassee_people.sql    migrations/CC_0012_tallahassee_people.sql && \
git mv migrations/CC_wip_leon_county.sql           migrations/CC_0013_leon_county.sql && \
sed -i 's/CC_wip_tallahassee_structure/CC_0011_tallahassee_structure/g; s/CC_wip_tallahassee_people/CC_0012_tallahassee_people/g; s/CC_wip_leon_county/CC_0013_leon_county/g' \
  migrations/CC_0011_tallahassee_structure.sql migrations/CC_0012_tallahassee_people.sql migrations/CC_0013_leon_county.sql \
  scripts/gen-tallahassee-leon-migrations.mjs && \
npm run check:migrations && (grep -rn 'CC_wip' migrations/ scripts/gen-tallahassee-leon-migrations.mjs || echo 'no CC_wip references left')
```

Then apply, stopping on the first failure:

```bash
cd /c/EV-Accounts/backend && for f in CC_0011_tallahassee_structure CC_0012_tallahassee_people CC_0013_leon_county; do
  echo "=== APPLY $f ==="
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "migrations/$f.sql" || { echo "STOPPED at $f"; break; }
done
```

- [ ] **Step 6: Re-run all three — the idempotency test**

```bash
cd /c/EV-Accounts/backend && for f in CC_0011_tallahassee_structure CC_0012_tallahassee_people CC_0013_leon_county; do
  echo "=== RE-RUN $f (must be a clean no-op) ==="
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "migrations/$f.sql" 2>&1 | grep -E 'INSERT 0 [1-9]|UPDATE [1-9]|NOTICE|ERROR|COMMIT' | sed 's/^psql:[^ ]* //'
done
```

Every file must reach `COMMIT` with its post-verify `NOTICE` and **no** `ERROR`. The only permitted
`INSERT 0 N` with N > 0 is into the **temp** seed tables. This step found two real bugs in FL-3; do not
skip it.

- [ ] **Step 7: The acceptance probe**

```bash
cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -f scripts/verify-tallahassee-leon-probes.sql
```

Expected: all four required answers `PRESENT`, with **5** city commissioners, District 5 →
David O'Keefe, HD-9 and SD-3. Per-body counts: Tallahassee `City Commission` 5/5; Leon
`Board of County Commissioners` 7/7; Leon `Elected Officials` 6/6. Zero offices with no term row and no
vacancy flag.

- [ ] **Step 8: Every gate**

```bash
cd /c/EV-Accounts/backend && npx tsc --noEmit && npm run check:occupancy && npm run check:migrations && npm run check:child-county && npm run check:reachability
```

`check:reachability` must report **no new bucket**. There is **no `fl|LOCAL` or `fl|COUNTY` bucket in
the baseline**, and this wave has no vacancy, so every one of the 18 offices must carry a term row —
a single missing one fires `DEAD_GEOGRAPHY` and fails.

**No `geofence_child_county` refresh is needed** — this wave loads only an `X` code. That correction is
in `fl.md`.

- [ ] **Step 9: Measure the drift**

```bash
cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -At -F ' | ' -c "
SELECT count(*), count(*) FILTER (WHERE is_vacant), count(*) FILTER (WHERE NOT is_vacant)
  FROM essentials.offices_missing_terms;"
```

FL-3 left this at **820 / 165 / 655**. FL-4 adds **no** vacancy and **no** unflagged row, so expect
**820 / 165 / 655 unchanged**. Any rise in the unflagged count means an office was created without a
term and without a flag.

- [ ] **Step 10: Commit**

```bash
cd /c/EV-Accounts && git add backend/migrations/CC_0011_tallahassee_structure.sql backend/migrations/CC_0012_tallahassee_people.sql backend/migrations/CC_0013_leon_county.sql backend/scripts/verify-tallahassee-leon-probes.sql backend/scripts/gen-tallahassee-leon-migrations.mjs && git commit -F- -- backend/migrations/CC_0011_tallahassee_structure.sql backend/migrations/CC_0012_tallahassee_people.sql backend/migrations/CC_0013_leon_county.sql backend/scripts/verify-tallahassee-leon-probes.sql backend/scripts/gen-tallahassee-leon-migrations.mjs <<'MSG'
feat(knight-fl): seat Tallahassee and Leon County — 18 offices, 18 people (CC_0011..CC_0013)

APPLIED. Tallahassee: 1 government, 1 chamber, 1 citywide district, 5 at-large
offices, 5 people. Leon: 1 government, 2 chambers, 5 new COUNTY districts (the
countywide district already existed and carries 8 of the 13 offices), 13 offices,
13 people, no vacancies.

The probe at Tallahassee City Hall returns all five city commissioners, county
Commissioner District 5, HD-9 and SD-3.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
MSG
```

---

## Task 5: Update the ledger

**Files:**
- Modify: `.planning/knight-foundation/PROGRAM.md`, `.planning/knight-foundation/fl.md`
- Modify: this plan — add a "Deviations found during execution" section, as FL-2 and FL-3 did

- [ ] **Step 1: `fl.md`**

- Wave table: FL-4 `✅ applied — CC_0011, CC_0012, CC_0013`. Next free `CC_0014`, `X0039`.
- **Answer the Tallahassee open question in "Sources for FL-4 onward"**: the commission is entirely
  at-large, so no ward layer was needed. Strike the "may be entirely at-large — verify" line.
- Add a `## FL-4 — Tallahassee and Leon County` section with: the seat/people table; the `-(1240000+n)`
  ranges used; the `X0038` allocation; the anchor and its four answers; the two commission services and
  their agreement; the city-limits control result; and the date-precision histogram.
- 🔴 **Record the charter contrast prominently**: Manatee non-charter → 5 officers; **Leon charter →
  6 officers, including an elected Superintendent of Schools**. This is the strongest evidence yet for
  "never inherit the officer template", and Miami-Dade (FL-6) is also a charter county.
- 🔴 **Record the at-large naming contrast**: Manatee "District 6/7", Leon "At Large, Group 1/2".
- Note the take-office rules per body, since they convert an election date into a start date.

- [ ] **Step 2: `PROGRAM.md`**

- Keep FL stages 3 and 4 at `WIP` — Miami and Palm Beach remain.
- Local/county seats table: add Tallahassee city (5/5) and Leon County (13/13).
- Migration ledger: three rows, next free `CC_0014`; MTFCC next free `X0039`.
- Session log: one row, and `Next action: write the FL-5 plan (Palm Beach County — county only, and
  its banner key is still undecided per spec §8.3)`.

- [ ] **Step 3: Commit**

```bash
cd /c/EV-Accounts && git add .planning/knight-foundation/PROGRAM.md .planning/knight-foundation/fl.md docs/superpowers/plans/2026-08-28-knight-fl-wave-4-tallahassee-leon.md && git commit -F- -- .planning/knight-foundation/PROGRAM.md .planning/knight-foundation/fl.md docs/superpowers/plans/2026-08-28-knight-fl-wave-4-tallahassee-leon.md <<'MSG'
docs(knight): record FL-4 in the ledger, with the plan's own errors

Leon is a charter county and elects six constitutional officers including the
Superintendent of Schools; Manatee, non-charter, elects five. Two counties in one
state also name their at-large seats differently — District 6/7 against At Large
Group 1/2. Never inherit either convention.

Tallahassee's commission is entirely at-large, which answers the open question
fl.md carried since FL-1 and meant this wave needed only one boundary layer.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
MSG
```

---

## Plan self-review

**Spec coverage.** §3 stage 3 (city) → Tasks 2, 3, 4; **the council-district layer is legitimately
absent** because Tallahassee is entirely at-large, and that is stated rather than skipped. §3 stage 4
(county, offices **and** people in ONE migration) → Tasks 1, 2, 3, 4. §4 wave anatomy: sources to disk
(T2.1), diff and settle (T2.3), check for post-source change (T2.3), `ROSTERS.md` with its four
sections (T2.4), generate with a script (T3), dry-run with rollback (T4.3–4), number last (T4.5).
§4.1 constraints → Global Constraints, updated with FL-3's six deviations. §5 gates → T4.8, all four
plus `tsc`. §5 definition of done → T4.1, T4.7. §6 ledger → T5. §7/§8 assets are FL-7.

**Placeholder scan.** No `TBD`. Three steps deliberately require a measurement before a literal is
written — the per-district areas (T1.4), the two extra control points (T1.3) and the city-limits
threshold (T1.5) — and each says exactly how to measure it and what to do with the result. That is
the opposite of a placeholder: it refuses to copy Manatee's numbers into Leon's gates. The
`12009`/`12003` GEOIDs in T4.1 come with the query that confirms them rather than an assumption about
zero-padding.

**Type consistency.** `parseRosters` / `renderCityStructure` / `renderCityPeople` / `renderCounty` keep
FL-3's names and signatures, so the copied test file needs only new fixtures. The eight roster columns
are unchanged, which is why the parser needs no edit. Slugs in the `ROSTERS.md` contract (T2 Interfaces)
match `CITY_SEATS`/`COUNTY_SEATS` keys (T3 Step 3) exactly, including `seat-4-mayor` and
`at-large-group-1/2`. `geo_id` prefix `leon-fl-commissioner-district-` is identical in T1 (producer),
T3 (consumer) and T4's probe.

**Three risks this plan cannot close.**

1. **Tallahassee Seat 3 was in a manual recount days before this plan was written**, and the general
   election is ahead. T2.3 checks it; the `COUNTS` guard forces every downstream number to move with it.
2. **The Superintendent-of-Schools decision is mine, not measured.** It is defensible and stated with
   reasoning, but it is the one place where a reviewer might rule differently — and if they do, it is
   one row in `COUNTY_SEATS`, one `official_count`, and three assertion numbers.
3. **Only one positive control point exists for the commission layer** until T1.3's extra two are
   measured. One control plus one negative control is thinner than Manatee's three, which is why
   T1.3 requires adding them rather than treating the single anchor as sufficient.
