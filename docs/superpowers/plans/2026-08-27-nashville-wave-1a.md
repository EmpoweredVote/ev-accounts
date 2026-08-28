# Nashville / Davidson Wave 1a Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Seat the 42 elected seats of the Metropolitan Government of Nashville and Davidson County — Mayor, Vice Mayor and the 40-member Metro Council — on a new 35-polygon council district layer, so that any address in Davidson County returns its Metro representatives.

**Architecture:** One bespoke ArcGIS loader writes 35 polygons into `essentials.geofence_boundaries` under a new synthetic mtfcc `X0035`. Two idempotent migrations follow: one creates the districts, government, chambers and offices; the other inserts the people and seats them through `essentials.seat_officeholder()`. Both migrations are emitted by a generator script from a hand-verified `ROSTERS.md`, exactly as NC wave 3 did.

**Tech Stack:** TypeScript (`tsx`) for the loader, Node ESM (`.mjs`) for the generator, PostgreSQL + PostGIS via `psql` against the Supabase session pooler, Express/TS backend gates run through `npm run check:*`.

**Spec:** `.planning/todos/2026-08-27-nashville-davidson-deep-seed.md`

## Global Constraints

- **Migration namespace is `CC_`** (Chris Cantrell). Next free slot is `CC_0004`. **Take the number LAST**: write the files as `CC_wip_*.sql`, and rename + apply + commit in one go.
- **`git fetch origin` before reading any migration max.** Verify with `npm run check:migrations --prefix backend`.
- **Every migration is idempotent** (`NOT EXISTS` guards or target-count top-ups) and ends with a `DO $$ … $$` post-verify gate that `RAISE EXCEPTION`s on a wrong count.
- **Dry-run against prod first** by wrapping the body `BEGIN; … ROLLBACK;` through `psql "$DATABASE_URL"`, and confirm the rollback reverted.
- **`ev_api` cannot create objects in `essentials`.** These migrations are DML only, so `psql` works. Do not reach for the Supabase MCP for the apply — it wraps each call in its own transaction, which destroys `BEGIN; … ROLLBACK;` semantics.
- **`outSR=4326` is load-bearing** on every ArcGIS fetch. The Nashville service's native SR is 3857.
- **Always pair `geo_id` with `district_type`** in a join. Never match a district on `label`.
- **No party affiliation** is recorded on a person or an office. Party lives on `races.primary_party`.
- **No `term_end` is written.** A future `term_end` makes seats silently self-vacate.
- **`essentials.politicians.alternate_names` is `NOT NULL DEFAULT '{}'`.** Emit an empty array, never NULL.
- **`office_current_holder` LEFT JOINs from `offices`**, so a vacancy is a NULL `politician_id`, not an absent row. Seated counts must use `count(och.politician_id)`, never `count(*)`.
- **`term_start` is the start of continuous occupancy by that person**, not the start of the current term. Re-election does not end an occupancy.
- **Do not invent a date.** `start_precision` is one of `day` / `month` / `year` / `unknown`, per source, per person.
- **cwd resets between Bash calls.** Prefix every command with `cd /c/EV-Accounts/backend &&` in the same compound command.

## Deviation from the spec, decided while planning

The spec's wave table put the ~10 countywide officer **offices** in wave 1a and their **people** in wave 1b. That is wrong: an office with no `office_terms` row is invisible, and it would push `essentials.offices_missing_terms` above its 699-unflagged baseline for the days between the two applies. **Wave 1a is therefore Metro-only** — 1 government, 2 chambers, 42 offices, 42 people. Wave 1b creates the `Countywide Elected Officials` chamber together with its offices and its people, in one migration, on or after 2026-09-01. Update the spec's wave table to match.

---

### Task 1: Verified roster

The migrations are generated from this file. Nothing downstream can be more correct than it is.

**Files:**
- Create: `backend/data/seed-nashville-davidson-2026/ROSTERS.md`

**Interfaces:**
- Produces: a markdown file with a `## Sources` table (S1, S2, …), a `## 🔴 Source defects found` section, a `## Charter rulings` section, and one `## Roster` table with these exact columns, which Task 3's generator parses:
  `ext_id | geo_id | district_type | office_title | full_name | first_name | last_name | middle_initial | name_suffix | aliases | term_start | start_precision | how_started | source`

- [ ] **Step 1: Pull both roster sources to disk**

```bash
cd /c/EV-Accounts/backend && mkdir -p data/seed-nashville-davidson-2026 && \
curl -sL -m 40 -o data/seed-nashville-davidson-2026/_council-page.html \
  "https://www.nashville.gov/departments/council/metro-council-members" && \
curl -s -m 60 -o data/seed-nashville-davidson-2026/_gis-council-districts.json \
  "https://maps.nashville.gov/arcgis/rest/services/Elections/PoliticalDistricts/MapServer/0/query?where=1%3D1&outFields=DISTRICT,DistrictName,Representative,FirstName,LastName,Website,Email,last_edited_date&returnGeometry=false&f=json" && \
ls -l data/seed-nashville-davidson-2026/
```

These two files are the evidence. They stay on disk, untracked, for the length of the wave.

- [ ] **Step 2: Diff the two sources and list every disagreement**

Read the council page as **UTF-8**. A Latin-1 read corrupts `Kyonzté Toombs` and `Deonté Harrell`.

```bash
cd /c/EV-Accounts/backend && PYTHONIOENCODING=utf-8 python -c "
import json, re, unicodedata
gis = json.load(open('data/seed-nashville-davidson-2026/_gis-council-districts.json', encoding='utf-8'))
g = {int(f['attributes']['DISTRICT']): (f['attributes'].get('Representative') or '').strip()
     for f in gis['features']}
html = open('data/seed-nashville-davidson-2026/_council-page.html', encoding='utf-8').read()
html = re.sub(r'(?is)<(script|style).*?</\1>', ' ', html)
text = re.sub(r'(?s)<[^>]+>', '\n', html)
text = [l.strip() for l in text.split('\n') if l.strip()]
page = {}
for i, line in enumerate(text):
    m = re.fullmatch(r'District (\d{1,2})', line)
    if m and i > 0:
        page[int(m.group(1))] = text[i-1]
print('GIS districts:', len(g), ' page districts:', len(page))
def norm(s): return unicodedata.normalize('NFD', s.lower()).encode('ascii','ignore').decode()
for d in sorted(set(g) | set(page)):
    a, b = g.get(d, '<missing>'), page.get(d, '<missing>')
    if norm(a) != norm(b):
        print(f'  D{d:>2}: GIS={a!r}  PAGE={b!r}')
"
```

Expected: both sources report 35 districts. Every disagreement printed is a name that a human must settle from the council member's own page. `D25` is known to differ inside the GIS layer itself (`Preptit` vs `Prepit`); the council page is authoritative and says **Preptit**.

- [ ] **Step 3: Check every seat for a change since the sources were last edited**

The GIS layer froze on 2023-09-22 and the council page was last updated 2025-10-07. Neither can report a change that happened after its own date, and a resignation is exactly what silently seats the wrong person.

For each of the 40 council seats plus Mayor and Vice Mayor, open the member's own page under `https://www.nashville.gov/departments/council/` and confirm the name matches. Where a seat changed hands, find the appointment or special election and record it, with `how_started = 'appointed'` where the Council filled the seat itself.

Record in `ROSTERS.md` under `## 🔴 Source defects found`: the count of seats checked, the count that changed, and the date of the check.

- [ ] **Step 4: Settle the Vice Mayor question from the Metro Charter**

This determines the chamber shape in Task 3 and cannot be guessed. Read Metropolitan Charter Article 3 (`https://library.municode.com/tn/metro_government_of_nashville_and_davidson_county`) and answer, in `## Charter rulings`, with the section number quoted:

1. **Is the Vice Mayor a member of the Metropolitan Council, or its presiding officer only?** This sets `chambers.official_count` to 41 or 40, and decides whether the Vice Mayor office sits in the Council chamber.
2. **On what condition does the Vice Mayor vote?** The answer becomes the `representation_note` text verbatim.
3. **When do Metro terms begin after an election?** The Council was elected in August and September 2023; the charter gives the day terms start. This is the default `term_start` for every member first seated in 2023.

If the charter is unreachable, stop and report. Do not seed a seat whose membership you cannot state.

- [ ] **Step 5: Resolve the two identity collisions found during planning**

Both were measured in prod on 2026-08-27 and both are recorded here so nobody re-derives them.

```bash
cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -c "
select p.external_id, p.full_name, p.is_incumbent,
       (select count(*) from essentials.office_current_holder och where och.politician_id = p.id) as seats
  from essentials.politicians p
 where p.external_id in (-470405, -5515005);"
```

Expected output: two rows, both `is_incumbent = true`, both with `seats = 0` for `-470405` and one seat for `-5515005`.

1. **`Robert Nash` `-5515005` is a Village Trustee in Wisconsin.** A different person from Council District 27. This is the Mike Lee case, live in this roster: a name-based insert guard would seat a Wisconsin trustee on a Nashville seat. Insert a new person on the Nashville band. Record the ruling.
2. **`Mike Cortese` `-470405` sits in the `-4704xx` band, which holds TN **congressional district 4** candidates** (`-470301..-470307` is CD-3, `-470401..-470410` is CD-4). Nashville is not in TN-04, so this is very likely a homonym of the Council District 4 member — but the district numbers matching is a coincidence trap, and "very likely" is not evidence. Establish it: compare the FEC candidate filing behind `-470405` against the council member's own page. Then either reuse that politician row and seat it, or insert a new one — and write which, and why, in `ROSTERS.md`.

- [ ] **Step 6: Write `ROSTERS.md` and self-check it**

Follow `backend/data/seed-buncombe-asheville-2026/ROSTERS.md` for shape. `ext_id` assignments:

| Range | Seats |
|---|---|
| `-4730001 .. -4730035` | Council district seats, `ext_id = -4730000 - district_number` |
| `-4730036 .. -4730040` | The 5 at-large seats, in the order the council page lists them |
| `-4730041` | Mayor |
| `-4730042` | Vice Mayor |

`geo_id` is `nashville-tn-council-district-N` with `district_type = 'LOCAL'` for the 35, and `47037` with `district_type = 'COUNTY'` for the 7 countywide seats. `office_title` is `Council Member, District N`, `Council Member at-Large`, `Mayor`, `Vice Mayor`.

- [ ] **Step 7: Verify the roster file mechanically**

```bash
cd /c/EV-Accounts/backend && PYTHONIOENCODING=utf-8 python -c "
import re
rows=[l for l in open('data/seed-nashville-davidson-2026/ROSTERS.md',encoding='utf-8')
      if l.startswith('|') and re.match(r'^\|\s*-47300', l)]
cells=[[c.strip() for c in r.strip().strip('|').split('|')] for r in rows]
assert len(cells)==42, f'expected 42 roster rows, got {len(cells)}'
ids=[c[0] for c in cells]
assert len(set(ids))==42, 'duplicate ext_id'
assert all(c[11] in ('day','month','year','unknown') for c in cells), 'bad start_precision'
assert all(c[12] in ('elected','appointed') for c in cells), 'bad how_started'
assert all(c[13] for c in cells), 'a row has no source'
atlarge=[c for c in cells if c[3]=='Council Member at-Large']
assert len(atlarge)==5, f'expected 5 at-large rows, got {len(atlarge)}'
dist=[c for c in cells if c[3].startswith('Council Member, District')]
assert len(dist)==35, f'expected 35 district rows, got {len(dist)}'
assert len({c[3] for c in dist})==35, 'district titles are not distinct'
print('ROSTERS.md OK — 42 rows, 35 districts, 5 at-large, 2 countywide executives')
"
```

Expected: `ROSTERS.md OK — 42 rows, 35 districts, 5 at-large, 2 countywide executives`

- [ ] **Step 8: Commit**

```bash
cd /c/EV-Accounts && git add -- backend/data/seed-nashville-davidson-2026/ROSTERS.md && \
git commit -F- -- backend/data/seed-nashville-davidson-2026/ROSTERS.md <<'MSG'
data(nashville): verified roster for the 42 Metro seats

Two independent sources — the Metro GIS council layer and the council
roster page — reconciled seat by seat, plus a per-seat check for changes
since each source's own last-edited date.

Records two identity rulings measured in prod: Robert Nash -5515005 is a
Wisconsin village trustee, not District 27; and the disposition of
Mike Cortese -470405, which sits in the TN congressional district 4
candidate band.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
MSG
```

---

### Task 2: Council district boundary loader

**Files:**
- Create: `backend/scripts/load-davidson-council-boundaries.ts`

**Interfaces:**
- Consumes: nothing from earlier tasks. Reads `DATABASE_URL` and the existing TIGER county polygon `47037` / `G4020`.
- Produces: 35 rows in `essentials.geofence_boundaries` with `mtfcc = 'X0035'`, `state = 'tn'`, `geo_id = 'nashville-tn-council-district-1'..'-35'`. Task 3's migration refuses to run without them.

- [ ] **Step 1: Confirm the slot is still free and the county polygon is loaded**

```bash
cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -c "
select (select count(*) from essentials.geofence_boundaries where mtfcc = 'X0035') as x0035_rows,
       (select count(*) from essentials.geofence_boundaries where mtfcc like 'X%' and state = 'tn') as tn_x_rows,
       (select count(*) from essentials.geofence_boundaries where geo_id = '47037' and mtfcc = 'G4020') as county_polygon;"
```

Expected: `x0035_rows = 0`, `tn_x_rows = 0`, `county_polygon = 1`.

🔴 `tn_x_rows` matters: TIGER rows carry FIPS in `state` (`'47'`) but bespoke `X%` rows carry lowercase USPS (`'tn'`), so a probe that groups by `state = '47'` cannot see an existing bespoke TN layer. If either count is non-zero, stop — the slot is taken.

- [ ] **Step 2: Write the loader**

```typescript
/**
 * load-davidson-council-boundaries.ts
 *
 * Fetches the 35 Metropolitan Council district boundaries for Nashville /
 * Davidson County (TN) and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='nashville-tn-council-district-1'..'-35',
 *                                   mtfcc='X0035', state='tn'
 *
 * Writes ONLY to essentials.geofence_boundaries. The structural migration
 * creates the district rows, the government, the chambers and the offices.
 *
 * Wave 1a of the Nashville deep-seed program.
 * Spec: .planning/todos/2026-08-27-nashville-davidson-deep-seed.md
 * Plan: docs/superpowers/plans/2026-08-27-nashville-wave-1a.md
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 WHY THE COUNTY POLYGON, AND NOT THE TIGER PLACE, IS THE PARENT.
 *
 * TIGER files Nashville as place 4752006, "Nashville-Davidson metropolitan
 * government (balance)". The word balance is doing real work: it EXCLUDES the
 * six satellite cities — Belle Meade, Berry Hill, Forest Hills, Goodlettsville,
 * Oak Hill and Ridgetop. Those residents elect the Metro Council anyway.
 *
 * Measured 2026-08-27 against this very layer: Belle Meade City Hall falls in
 * council district 23, Goodlettsville City Hall in 10, Berry Hill in 26,
 * Forest Hills in 34, Oak Hill in 25, Ridgetop in 10. Hanging Metro seats off
 * the place polygon would return NO representative for any of them, and nothing
 * would error. So the countywide seats hang off TIGER county 47037, and the
 * tiling gate below asserts these 35 polygons cover that county exactly once.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 outSR=4326 IS LOAD-BEARING. The service's native spatial reference is
 * EPSG:3857 (web mercator). Dropping outSR writes projected metres into a
 * geographic column. No row count and no NOT NULL would catch it; the polygons
 * would simply sit in the wrong hemisphere and every address probe would come
 * back empty.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * ⚠ ON THE CONTROL POINTS. Buncombe's loader could check its polygons against an
 * INDEPENDENT layer already in the database (TIGER sldl), because a statute ties
 * the two together. Nashville has no such twin: no other council-district
 * digitization is loaded. So the control points below are SELF-CONSISTENCY
 * checks — each point must fall in exactly one district, and in the district
 * this same layer reported on 2026-08-27. They would not catch a wholesale
 * re-digitization of the layer.
 *
 * The independent gates are the two that follow them: the districts must tile
 * TIGER county 47037 (a different agency's digitization of a different
 * boundary), and a point outside Davidson County must fall in NO district.
 */

import { Pool } from 'pg';

const COUNCIL_URL =
  'https://maps.nashville.gov/arcgis/rest/services/' +
  'Elections/PoliticalDistricts/MapServer/0/query' +
  '?where=1%3D1&outFields=DISTRICT%2CDistrictName' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

const MTFCC = 'X0035';
const STATE_CODE = 'tn';
const SOURCE = 'nashvillegov-arcgis-Elections-PoliticalDistricts-0-2026-08-27';
const GEO_ID_PREFIX = 'nashville-tn-council-district-';
const COUNTY_GEO_ID = '47037';
const EXPECTED_COUNT = 35;

/**
 * Self-consistency controls, measured against this layer on 2026-08-27. Five of
 * the six are satellite-city halls: they are the cases that would break if
 * anyone swapped this layer for the TIGER place polygon.
 */
const CONTROL_POINTS: Array<{ name: string; lon: number; lat: number; district: number }> = [
  { name: 'Metro Courthouse',       lon: -86.7761, lat: 36.1665, district: 19 },
  { name: 'Belle Meade City Hall',  lon: -86.8583, lat: 36.1006, district: 23 },
  { name: 'Goodlettsville City Hall', lon: -86.7133, lat: 36.3231, district: 10 },
  { name: 'Berry Hill City Hall',   lon: -86.7657, lat: 36.1183, district: 26 },
  { name: 'Forest Hills',           lon: -86.8419, lat: 36.0705, district: 34 },
  { name: 'Oak Hill',               lon: -86.7856, lat: 36.0663, district: 25 },
];

/**
 * 🔴 THE CONTROL OF THE CONTROL. Brentwood is in Williamson County, immediately
 * south of Davidson. It must fall in NO council district. Without this, a query
 * that cannot fire at all still passes every positive control by returning
 * "expected 1, got 1" for points it never actually tested.
 */
const NEGATIVE_CONTROL = { name: 'Brentwood, Williamson County', lon: -86.7828, lat: 35.9739 };

/**
 * Tiling tolerance against TIGER county 47037. Davidson County is ~1362 km2 and
 * the smallest council district is roughly 1/35th of it, so a tolerance of
 * 6 km2 stays two orders of magnitude below "one district missing" while
 * absorbing edge-digitizing differences between Metro GIS and TIGER. Measure the
 * actual numbers on the first dry run and tighten this constant to fit them, the
 * way Buncombe's 6.0 was chosen from a measured 3.004.
 */
const COUNTY_FIT_TOLERANCE_SQ_KM = 6.0;

const DRY_RUN = process.argv.includes('--dry-run');

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

type Feature = { properties: Record<string, unknown>; geometry: any | null };

/** Ray-cast point-in-polygon over a GeoJSON Polygon/MultiPolygon, holes honoured. */
function pointInGeometry(geom: any, lon: number, lat: number): boolean {
  const polys: number[][][][] = geom.type === 'Polygon' ? [geom.coordinates] : geom.coordinates;
  for (const poly of polys) {
    let inOuter = false;
    let inHole = false;
    poly.forEach((ring, idx) => {
      let hit = false;
      for (let a = 0, b = ring.length - 1; a < ring.length; b = a++) {
        const [xi, yi] = ring[a];
        const [xj, yj] = ring[b];
        if ((yi > lat) !== (yj > lat) && lon < ((xj - xi) * (lat - yi)) / (yj - yi) + xi) hit = !hit;
      }
      if (idx === 0) inOuter = hit;
      else if (hit) inHole = true;
    });
    if (inOuter && !inHole) return true;
  }
  return false;
}

async function main() {
  console.log('[load-davidson-council-boundaries] Fetching Metro Council districts');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes (every gate below still runs for real)');

  const response = (await (await fetch(COUNCIL_URL)).json()) as { features?: Feature[] };
  if (!response?.features?.length) {
    console.error('ERROR: No features returned from the Nashville MapServer. Check the URL.');
    process.exit(1);
  }
  console.log(`  Received ${response.features.length} features`);

  const distMap = new Map<number, { geoId: string; name: string; geomStr: string; geom: any }>();
  for (const feature of response.features) {
    const raw = String(feature.properties['DISTRICT'] ?? '');
    const dist = parseInt(raw.replace(/\D+/g, ''), 10);
    if (isNaN(dist) || dist < 1 || dist > EXPECTED_COUNT) {
      console.warn(`  WARNING: DISTRICT '${raw}' out of range — skipping`);
      continue;
    }
    if (!feature.geometry) {
      console.warn(`  WARNING: district ${dist} has no geometry — skipping`);
      continue;
    }
    if (distMap.has(dist)) {
      console.error(`ERROR: district ${dist} appeared twice. Aborting rather than guessing.`);
      process.exit(1);
    }
    distMap.set(dist, {
      geoId: `${GEO_ID_PREFIX}${dist}`,
      name: `Nashville Metro Council District ${dist}`,
      geomStr: JSON.stringify(feature.geometry),
      geom: feature.geometry,
    });
  }

  if (distMap.size !== EXPECTED_COUNT) {
    console.error(`ERROR: expected ${EXPECTED_COUNT} districts, got ${distMap.size}. Aborting.`);
    process.exit(1);
  }
  const sorted = [...distMap.entries()].sort((a, b) => a[0] - b[0]);
  const missing = Array.from({ length: EXPECTED_COUNT }, (_, i) => i + 1).filter((n) => !distMap.has(n));
  if (missing.length) {
    console.error(`ERROR: districts ${missing.join(', ')} are absent. Aborting.`);
    process.exit(1);
  }
  console.log(`  Parsed districts 1..${EXPECTED_COUNT}, none missing, none duplicated`);

  // ─── Gate 1: self-consistency controls ─────────────────────────────────────
  console.log('\n  Control points (self-consistency; five are satellite-city halls):');
  let controlFailures = 0;
  for (const cp of CONTROL_POINTS) {
    const found = sorted.filter(([, v]) => pointInGeometry(v.geom, cp.lon, cp.lat)).map(([d]) => d);
    const ok = found.length === 1 && found[0] === cp.district;
    if (!ok) controlFailures++;
    console.log(
      `    ${ok ? 'PASS' : 'FAIL'}  ${cp.name}: expected D${cp.district}, got ${found.length ? found.map((d) => 'D' + d).join('+') : 'none'}`,
    );
  }

  // ─── Gate 2: the control of the control ────────────────────────────────────
  const outside = sorted.filter(([, v]) => pointInGeometry(v.geom, NEGATIVE_CONTROL.lon, NEGATIVE_CONTROL.lat));
  const negOk = outside.length === 0;
  if (!negOk) controlFailures++;
  console.log(
    `    ${negOk ? 'PASS' : 'FAIL'}  ${NEGATIVE_CONTROL.name}: expected no district, got ${outside.length ? outside.map(([d]) => 'D' + d).join('+') : 'none'}`,
  );
  if (controlFailures > 0) {
    console.error(`\nERROR: ${controlFailures} control(s) failed. Refusing to write.`);
    await pool.end();
    process.exit(1);
  }

  // ─── Gate 3: the districts must tile Davidson County, once ─────────────────
  const tileRes = await pool.query(
    `WITH d AS (
       SELECT public.ST_Multi(public.ST_SetSRID(public.ST_GeomFromGeoJSON(gj), 4326)) g
         FROM unnest($1::text[]) AS gj
     ), u AS (SELECT public.ST_Union(g) g FROM d),
        c AS (SELECT geometry g FROM essentials.geofence_boundaries
               WHERE geo_id = $2 AND mtfcc = 'G4020')
     SELECT (public.ST_Area(public.ST_Difference(u.g, c.g)::geography) / 1e6)::numeric(10,3) AS outside_county,
            (public.ST_Area(public.ST_Difference(c.g, u.g)::geography) / 1e6)::numeric(10,3) AS county_uncovered,
            (SELECT coalesce(sum(public.ST_Area(public.ST_Intersection(x.g, y.g)::geography) / 1e6), 0)::numeric(10,3)
               FROM d x JOIN d y ON public.ST_AsBinary(x.g) < public.ST_AsBinary(y.g)
              WHERE public.ST_Intersects(x.g, y.g)) AS self_overlap
       FROM u, c`,
    [sorted.map(([, v]) => v.geomStr), COUNTY_GEO_ID],
  );
  if (!tileRes.rows.length) {
    console.error(`ERROR: TIGER county polygon ${COUNTY_GEO_ID}/G4020 is not loaded. Refusing to write.`);
    await pool.end();
    process.exit(1);
  }
  const t = tileRes.rows[0] as Record<string, string>;
  console.log(
    `\n  Tiling vs TIGER county ${COUNTY_GEO_ID}: outside ${t.outside_county} km2, ` +
      `uncovered ${t.county_uncovered} km2, self-overlap ${t.self_overlap} km2 ` +
      `(tolerance ${COUNTY_FIT_TOLERANCE_SQ_KM})`,
  );
  if (
    Number(t.outside_county) > COUNTY_FIT_TOLERANCE_SQ_KM ||
    Number(t.county_uncovered) > COUNTY_FIT_TOLERANCE_SQ_KM ||
    Number(t.self_overlap) > COUNTY_FIT_TOLERANCE_SQ_KM
  ) {
    console.error(
      `ERROR: the council districts do not tile Davidson County within ` +
        `${COUNTY_FIT_TOLERANCE_SQ_KM} km2. Uncovered county means residents with no council ` +
        `member; overlap means two. Investigate before trusting this load.`,
    );
    await pool.end();
    process.exit(1);
  }

  if (DRY_RUN) {
    console.log('\nDRY-RUN complete — all gates passed, no database writes made.');
    await pool.end();
    process.exit(0);
  }

  // ─── Write ─────────────────────────────────────────────────────────────────
  let inserted = 0;
  let alreadyExists = 0;
  let repaired = 0;
  for (const [dist, { geoId, name, geomStr }] of sorted) {
    const result = await pool.query(
      `INSERT INTO essentials.geofence_boundaries
         (id, geo_id, mtfcc, state, name, geometry, source)
       VALUES (gen_random_uuid(), $1, '${MTFCC}', '${STATE_CODE}', $2,
         public.ST_Multi(public.ST_SetSRID(public.ST_GeomFromGeoJSON($3), 4326)), $4)
       ON CONFLICT (geo_id, mtfcc) DO NOTHING
       RETURNING public.ST_GeometryType(geometry) AS gtype, public.ST_IsValid(geometry) AS valid`,
      [geoId, name, geomStr, SOURCE],
    );

    if ((result.rowCount ?? 0) === 0) {
      alreadyExists++;
      console.log(`  District ${dist} (${geoId}): skipped (already exists)`);
      continue;
    }

    const row = result.rows[0] as { gtype: string; valid: boolean };
    if (row.valid !== true) {
      console.error(`  District ${dist} (${geoId}): ST_IsValid=false — applying ST_MakeValid`);
      await pool.query(
        `UPDATE essentials.geofence_boundaries
           SET geometry = public.ST_Multi(public.ST_MakeValid(
             public.ST_SetSRID(public.ST_GeomFromGeoJSON($2), 4326)))
         WHERE geo_id = $1 AND mtfcc = '${MTFCC}'`,
        [geoId, geomStr],
      );
      const recheck = await pool.query(
        `SELECT public.ST_IsValid(geometry) AS valid
           FROM essentials.geofence_boundaries WHERE geo_id = $1 AND mtfcc = '${MTFCC}'`,
        [geoId],
      );
      if ((recheck.rows[0] as { valid: boolean })?.valid !== true) {
        console.error(`  ERROR: District ${dist} still invalid after ST_MakeValid. Aborting.`);
        await pool.end();
        process.exit(1);
      }
      repaired++;
    } else {
      console.log(`  District ${dist} (${geoId}): inserted (${row.gtype}, valid)`);
    }
    inserted++;
  }

  console.log(`\n=== Summary ===`);
  console.log(`  Inserted:        ${inserted}`);
  console.log(`  Already existed: ${alreadyExists}`);
  console.log(`  Repaired:        ${repaired}`);

  const check = await pool.query(
    `SELECT COUNT(*)::int AS n,
            COUNT(*) FILTER (WHERE NOT public.ST_IsValid(geometry))::int AS invalid
       FROM essentials.geofence_boundaries WHERE mtfcc = '${MTFCC}'`,
  );
  const { n, invalid } = check.rows[0] as { n: number; invalid: number };
  console.log(`  In DB now:       ${n} rows (${invalid} invalid)`);

  await pool.end();
  if (n !== EXPECTED_COUNT || invalid !== 0) {
    console.error(`ERROR: expected ${EXPECTED_COUNT} valid rows, got ${n} with ${invalid} invalid.`);
    process.exit(1);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
```

- [ ] **Step 3: Prove the negative control can fail**

A gate nobody has seen fail is not a gate. Temporarily change `NEGATIVE_CONTROL` to the Metro Courthouse point (`lon: -86.7761, lat: 36.1665`) and run the dry run.

```bash
cd /c/EV-Accounts/backend && npx tsx scripts/load-davidson-council-boundaries.ts --dry-run
```

Expected: `FAIL  Brentwood…: expected no district, got D19`, then `ERROR: 1 control(s) failed. Refusing to write.`, exit code 1.

Then restore the real Brentwood coordinates.

- [ ] **Step 4: Run the real dry run**

```bash
cd /c/EV-Accounts/backend && npx tsx scripts/load-davidson-council-boundaries.ts --dry-run
```

Expected: `Parsed districts 1..35`, all seven controls `PASS`, a tiling line, and `DRY-RUN complete`. **Read the three tiling numbers and tighten `COUNTY_FIT_TOLERANCE_SQ_KM` to fit them** — record the measured values in the constant's comment, replacing the guidance text.

- [ ] **Step 5: Load for real**

```bash
cd /c/EV-Accounts/backend && npx tsx scripts/load-davidson-council-boundaries.ts && \
psql "$DATABASE_URL" -c "
select count(*) as rows,
       count(*) filter (where not public.ST_IsValid(geometry)) as invalid,
       count(distinct geo_id) as distinct_geo_ids
  from essentials.geofence_boundaries where mtfcc = 'X0035';"
```

Expected: `rows = 35`, `invalid = 0`, `distinct_geo_ids = 35`.

- [ ] **Step 6: Commit**

```bash
cd /c/EV-Accounts && git add -- backend/scripts/load-davidson-council-boundaries.ts && \
git commit -F- -- backend/scripts/load-davidson-council-boundaries.ts <<'MSG'
feat(nashville): load the 35 Metro Council district boundaries (X0035)

Nashville has no independent second digitization of its council districts,
so the control points are self-consistency checks. The gates that are
genuinely independent are the tiling test against TIGER county 47037 and
the Brentwood negative control, which was proved able to fail.

Five of the six control points are satellite-city halls — the cases that
break if anyone swaps this layer for the TIGER place polygon 4752006,
which is the metropolitan government BALANCE and excludes them.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
MSG
```

---

### Task 3: Generator and structure migration

**Files:**
- Create: `backend/scripts/gen-nashville-migrations.mjs`
- Create: `backend/migrations/CC_wip_nashville_structure.sql` (generated; renamed in Task 5)

**Interfaces:**
- Consumes: `data/seed-nashville-davidson-2026/ROSTERS.md` from Task 1, and the 35 `X0035` boundaries from Task 2.
- Produces: 35 `LOCAL` districts, 1 government, 2 chambers and 42 offices. Task 4's migration joins to those offices by `(geo_id, district_type, title)` and a `row_number()` rank.

- [ ] **Step 1: Write the post-verify gate first, and watch it fail**

The gate is the test. Run its body against prod before the migration exists.

```bash
cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -c "
select (select count(*) from essentials.districts where mtfcc = 'X0035') as districts,
       (select count(*) from essentials.governments where geo_id = '47037') as governments,
       (select count(*) from essentials.offices o
          join essentials.districts d on d.id = o.district_id
         where d.mtfcc = 'X0035') as district_offices,
       (select count(*) from essentials.offices o
          join essentials.districts d on d.id = o.district_id
         where d.geo_id = '47037' and d.district_type = 'COUNTY') as countywide_offices;"
```

Expected now: `0, 0, 0, 0`. Expected after Task 3: `35, 1, 35, 7`.

- [ ] **Step 2: Write the generator**

```javascript
#!/usr/bin/env node
/**
 * gen-nashville-migrations.mjs
 *
 * Emits the two Nashville wave 1a migrations from the verified roster:
 *   migrations/CC_wip_nashville_structure.sql    (districts, government, chambers, offices)
 *   migrations/CC_wip_nashville_metro_people.sql (politicians + terms)
 *
 * Roster: data/seed-nashville-davidson-2026/ROSTERS.md
 * Plan:   docs/superpowers/plans/2026-08-27-nashville-wave-1a.md
 *
 * The migration numbers are deliberately NOT chosen here. The files are written
 * as CC_wip_* and renamed at apply time — see the plan's Task 5.
 */
import { readFileSync, writeFileSync } from 'node:fs';

const ROSTER = 'data/seed-nashville-davidson-2026/ROSTERS.md';
const COUNTY_GEO_ID = '47037';
const MTFCC = 'X0035';
const N_DISTRICTS = 35;
const N_AT_LARGE = 5;

/** SQL single-quote escape. */
const q = (s) => (s === null || s === undefined || s === '' ? 'NULL' : `'${String(s).replace(/'/g, "''")}'`);
/** text[] literal, never NULL — alternate_names is NOT NULL DEFAULT '{}'. */
const arr = (s) =>
  !s || s === '-' ? `ARRAY[]::text[]` : `ARRAY[${s.split(';').map((x) => q(x.trim())).join(', ')}]::text[]`;

function readRoster() {
  const rows = readFileSync(ROSTER, 'utf8')
    .split('\n')
    .filter((l) => /^\|\s*-47300/.test(l))
    .map((l) => l.trim().replace(/^\|/, '').replace(/\|$/, '').split('|').map((c) => c.trim()));
  const cols = [
    'ext_id', 'geo_id', 'district_type', 'office_title', 'full_name', 'first_name', 'last_name',
    'middle_initial', 'name_suffix', 'aliases', 'term_start', 'start_precision', 'how_started', 'source',
  ];
  const out = rows.map((r) => Object.fromEntries(cols.map((c, i) => [c, r[i]])));
  if (out.length !== 42) throw new Error(`roster: expected 42 rows, got ${out.length}`);
  return out;
}

/**
 * 🔴 THE COUNCIL CHAMBER SPANS 36 DISTRICTS. Every top-up counts within
 * (chamber_id, district_id), never chamber_id alone. A chamber-scoped count sees
 * the first district's seat, computes 40 - 1 = 39, and can land all 39 on one
 * district while still reporting the right total. That is the CA_0006 bug, and
 * this chamber is exactly the shape it warned about.
 */
function structureSql(roster) {
  const viceMayorNote = roster.find((r) => r.office_title === 'Vice Mayor')?.source ?? '';
  const p = [];
  p.push(`-- CC_wip_nashville_structure.sql
-- Nashville deep-seed program, WAVE 1a (structure). Companion: the people migration.
--
-- Creates the geography-and-seats half of the Metropolitan Government of
-- Nashville and Davidson County:
--   * 35 LOCAL districts -- Metro Council districts, mtfcc X0035
--   * 1 government, 2 chambers
--   * 42 offices -- 35 district council + 5 at-large + Mayor + Vice Mayor
--
-- Spec: .planning/todos/2026-08-27-nashville-davidson-deep-seed.md
-- Plan: docs/superpowers/plans/2026-08-27-nashville-wave-1a.md
-- Roster: data/seed-nashville-davidson-2026/ROSTERS.md
-- Generated by: scripts/gen-nashville-migrations.mjs
--
-- ---------------------------------------------------------------------------
-- 🔴 NASHVILLE IS A CONSOLIDATED CITY-COUNTY. There is no county commission.
-- The 40-member Metro Council is both the city and the county legislature, so
-- ONE government row covers both, and its geo_id is the COUNTY polygon 47037 --
-- not TIGER place 4752006, which is the metropolitan government BALANCE and
-- excludes six satellite cities whose residents elect this same council.
--
-- ---------------------------------------------------------------------------
-- 🔴 THE MULTI-SEAT TOP-UP IS SCOPED TO (chamber_id, district_id).
-- The Metropolitan Council chamber spans 36 districts: 35 council districts
-- plus the county polygon that carries the 5 at-large seats. A chamber-scoped
-- count is the CA_0006 bug and would land seats on the wrong districts while
-- reporting the right total. The post-verify gate counts PER DISTRICT for the
-- same reason.
--
-- IDEMPOTENT: every insert is NOT EXISTS-guarded or a target-count top-up.

BEGIN;

-- --- 0. Precondition: the council boundaries must already be loaded ---------
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries WHERE mtfcc = '${MTFCC}';
  IF v_n <> ${N_DISTRICTS} THEN
    RAISE EXCEPTION 'nashville structure: expected ${N_DISTRICTS} ${MTFCC} boundaries, found % -- run scripts/load-davidson-council-boundaries.ts first', v_n;
  END IF;
END $$;

-- --- 1. Districts -----------------------------------------------------------
-- num_officials = 1: each council district elects one member. The 5 at-large
-- seats hang off the EXISTING county district ${COUNTY_GEO_ID}, which is not created here.`);

  for (let d = 1; d <= N_DISTRICTS; d++) {
    const geoId = `nashville-tn-council-district-${d}`;
    p.push(`
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT ${q(geoId)}, ${q(`Nashville Metro Council District ${d}`)}, 'LOCAL', 'tn', '${MTFCC}', 1
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts WHERE geo_id = ${q(geoId)} AND mtfcc = '${MTFCC}'
);`);
  }

  p.push(`

-- --- 2. Government ----------------------------------------------------------
-- ONE row, because the city and the county are one government. type 'City' with
-- city 'Nashville' is the primary label; the name carries both halves. Nothing
-- in the read path branches on governments.type (verified 2026-08-27).

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'Metropolitan Government of Nashville and Davidson County, Tennessee, US', 'City', 'TN', 'Nashville', ${q(COUNTY_GEO_ID)}
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE geo_id = ${q(COUNTY_GEO_ID)} AND type = 'City'
);

-- --- 3. Chambers ------------------------------------------------------------
-- official_count is taken from the Metro Charter ruling recorded in ROSTERS.md.

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT g.id, 'Metropolitan Council', 'Metropolitan Council of Nashville and Davidson County', ${N_DISTRICTS + N_AT_LARGE}, 'full'
FROM essentials.governments g
WHERE g.geo_id = ${q(COUNTY_GEO_ID)} AND g.type = 'City'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
    WHERE c.government_id = g.id AND c.name = 'Metropolitan Council'
  );

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT g.id, 'Office of the Mayor', 'Office of the Mayor of Nashville and Davidson County', 1, 'full'
FROM essentials.governments g
WHERE g.geo_id = ${q(COUNTY_GEO_ID)} AND g.type = 'City'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
    WHERE c.government_id = g.id AND c.name = 'Office of the Mayor'
  );

-- --- 4a. The 35 district council seats --------------------------------------
-- Each title is distinct because Nashville numbers districts on the ballot, so
-- a NOT EXISTS-on-title guard is correct here and cannot collapse rows.`);

  for (let d = 1; d <= N_DISTRICTS; d++) {
    const geoId = `nashville-tn-council-district-${d}`;
    p.push(`
INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, representing_city)
SELECT c.id, d.id, ${q(`Council Member, District ${d}`)}, 'TN', 'Nashville'
FROM essentials.chambers c
JOIN essentials.governments g ON g.id = c.government_id
CROSS JOIN LATERAL (
  SELECT dd.id FROM essentials.districts dd
  WHERE dd.geo_id = ${q(geoId)} AND dd.mtfcc = '${MTFCC}' AND dd.district_type = 'LOCAL'
) d
WHERE g.geo_id = ${q(COUNTY_GEO_ID)} AND g.type = 'City' AND c.name = 'Metropolitan Council'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = ${q(`Council Member, District ${d}`)}
  );`);
  }

  p.push(`

-- --- 4b. The 5 at-large seats, IDENTICAL titles -----------------------------
-- Nashville does not number the at-large seats; the top five vote-getters win.
-- So the five offices are genuinely interchangeable and share one title. Guarded
-- by a target-count top-up, because NOT EXISTS-on-title would collapse five rows
-- to one on a re-run.
--
-- 🔴 The count is scoped to (chamber_id, district_id). This chamber spans 36
-- districts, so a chamber-scoped count here is the CA_0006 bug outright.

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, representing_city)
SELECT c.id, d.id, 'Council Member at-Large', 'TN', 'Nashville'
FROM essentials.chambers c
JOIN essentials.governments g ON g.id = c.government_id
CROSS JOIN LATERAL (
  SELECT dd.id FROM essentials.districts dd
  WHERE dd.geo_id = ${q(COUNTY_GEO_ID)} AND dd.district_type = 'COUNTY' AND lower(dd.state) = 'tn'
) d
CROSS JOIN LATERAL (
  SELECT generate_series(1, ${N_AT_LARGE} - (
    SELECT count(*) FROM essentials.offices o
    WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = 'Council Member at-Large'
  )) AS n
) gs
WHERE g.geo_id = ${q(COUNTY_GEO_ID)} AND g.type = 'City' AND c.name = 'Metropolitan Council';

-- --- 4c. Vice Mayor ---------------------------------------------------------
-- 🔴 A SEPARATELY ELECTED OFFICE, NOT A BOARD ROLE. Asheville's Vice Mayor is a
-- role held by a sitting council member, and CA_0009 correctly refused to create
-- a seat for it. Nashville's Vice Mayor is elected countywide on their own
-- ballot line and presides over the Council.
--
-- voting_powers is 'full' because the vote is real, merely conditional: the Vice
-- Mayor votes to break a tie. No voting_powers value states that, so the
-- condition is carried in representation_note, in voter-facing language. Today
-- both read paths gate the note on voting_powers <> 'full' and would not render
-- it; wave 1c removes that gate.

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, representing_city, voting_powers, representation_note)
SELECT c.id, d.id, 'Vice Mayor', 'TN', 'Nashville', 'full', ${q(viceMayorNote)}
FROM essentials.chambers c
JOIN essentials.governments g ON g.id = c.government_id
CROSS JOIN LATERAL (
  SELECT dd.id FROM essentials.districts dd
  WHERE dd.geo_id = ${q(COUNTY_GEO_ID)} AND dd.district_type = 'COUNTY' AND lower(dd.state) = 'tn'
) d
WHERE g.geo_id = ${q(COUNTY_GEO_ID)} AND g.type = 'City' AND c.name = 'Metropolitan Council'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id AND o.title = 'Vice Mayor'
  );

-- --- 4d. Mayor --------------------------------------------------------------

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, representing_city)
SELECT c.id, d.id, 'Mayor', 'TN', 'Nashville'
FROM essentials.chambers c
JOIN essentials.governments g ON g.id = c.government_id
CROSS JOIN LATERAL (
  SELECT dd.id FROM essentials.districts dd
  WHERE dd.geo_id = ${q(COUNTY_GEO_ID)} AND dd.district_type = 'COUNTY' AND lower(dd.state) = 'tn'
) d
WHERE g.geo_id = ${q(COUNTY_GEO_ID)} AND g.type = 'City' AND c.name = 'Office of the Mayor'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id AND o.title = 'Mayor'
  );

-- --- 5. Post-verify gate ----------------------------------------------------
DO $$
DECLARE v_n int; v_d int; v_nogeom int; v_note int; v_city int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.districts WHERE mtfcc = '${MTFCC}';
  IF v_n <> ${N_DISTRICTS} THEN RAISE EXCEPTION 'nashville structure: expected ${N_DISTRICTS} ${MTFCC} districts, got %', v_n; END IF;

  -- 🔴 PER-DISTRICT, not 35 in total. A total-only assertion is exactly what a
  -- chamber-scoped top-up satisfies while stacking seats on one district.
  FOR v_d IN 1..${N_DISTRICTS} LOOP
    SELECT count(*) INTO v_n FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.geo_id = 'nashville-tn-council-district-' || v_d AND d.mtfcc = '${MTFCC}';
    IF v_n <> 1 THEN RAISE EXCEPTION 'nashville structure: council district % carries % offices, expected exactly 1', v_d, v_n; END IF;
  END LOOP;

  -- The county polygon carries the 5 at-large seats + Vice Mayor + Mayor.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = ${q(COUNTY_GEO_ID)} AND d.district_type = 'COUNTY';
  IF v_n <> ${N_AT_LARGE + 2} THEN RAISE EXCEPTION 'nashville structure: expected ${N_AT_LARGE + 2} offices on the Davidson county polygon, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = ${q(COUNTY_GEO_ID)} AND d.district_type = 'COUNTY' AND o.title = 'Council Member at-Large';
  IF v_n <> ${N_AT_LARGE} THEN RAISE EXCEPTION 'nashville structure: expected ${N_AT_LARGE} at-large offices, got %', v_n; END IF;

  -- 🔴 The Davidson County label exists in TWO states. Assert nothing landed on
  -- the North Carolina row, which a label-based join would have hit.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '37057' AND d.district_type = 'COUNTY';
  IF v_n <> 0 THEN RAISE EXCEPTION 'nashville structure: % office(s) landed on Davidson County, NORTH CAROLINA', v_n; END IF;

  -- The Vice Mayor note is required, and it is the whole point of the seat.
  SELECT count(*) INTO v_note FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = ${q(COUNTY_GEO_ID)} AND o.title = 'Vice Mayor'
     AND o.representation_note IS NOT NULL AND length(trim(o.representation_note)) > 40;
  IF v_note <> 1 THEN RAISE EXCEPTION 'nashville structure: the Vice Mayor office has no substantive representation_note'; END IF;

  -- Every Metro seat must carry the city, or the Nashville banner never resolves
  -- from data.
  SELECT count(*) INTO v_city FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE (d.mtfcc = '${MTFCC}' OR (d.geo_id = ${q(COUNTY_GEO_ID)} AND d.district_type = 'COUNTY'))
     AND (o.representing_city IS DISTINCT FROM 'Nashville' OR o.representing_state IS DISTINCT FROM 'TN');
  IF v_city <> 0 THEN RAISE EXCEPTION 'nashville structure: % Metro office(s) missing representing_city/state', v_city; END IF;

  -- No office may sit on a district with no geometry: unreachable by address,
  -- and nothing else would say so.
  SELECT count(*) INTO v_nogeom FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.mtfcc = '${MTFCC}'
     AND NOT EXISTS (
       SELECT 1 FROM essentials.geofence_boundaries b
        WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc
     );
  IF v_nogeom <> 0 THEN RAISE EXCEPTION 'nashville structure: % office(s) sit on a district with no matching boundary', v_nogeom; END IF;

  RAISE NOTICE 'nashville structure OK -- 42 offices across 35 council districts and the Davidson county polygon.';
END $$;

COMMIT;
`);
  return p.join('');
}

const roster = readRoster();
writeFileSync('migrations/CC_wip_nashville_structure.sql', structureSql(roster));
console.log('wrote migrations/CC_wip_nashville_structure.sql');
```

- [ ] **Step 3: Generate and dry-run against prod**

```bash
cd /c/EV-Accounts/backend && node scripts/gen-nashville-migrations.mjs && \
{ echo 'BEGIN;'; sed -e '/^BEGIN;$/d' -e '/^COMMIT;$/d' migrations/CC_wip_nashville_structure.sql; echo 'ROLLBACK;'; } \
  | psql "$DATABASE_URL" -v ON_ERROR_STOP=1
```

Expected: `NOTICE: nashville structure OK -- 42 offices across 35 council districts and the Davidson county polygon.` then `ROLLBACK`.

- [ ] **Step 4: Confirm the rollback actually reverted**

```bash
cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -c "
select (select count(*) from essentials.districts where mtfcc = 'X0035') as districts,
       (select count(*) from essentials.governments where geo_id = '47037') as governments;"
```

Expected: `0, 0`. If either is non-zero the dry run committed — stop and investigate before doing anything else.

---

### Task 4: People migration

**Files:**
- Modify: `backend/scripts/gen-nashville-migrations.mjs`
- Create: `backend/migrations/CC_wip_nashville_metro_people.sql` (generated; renamed in Task 5)

**Interfaces:**
- Consumes: the 42 offices created by Task 3, joined by `(geo_id, district_type, title)` with a `row_number()` rank for the 5 identically-titled at-large seats.
- Produces: 42 rows in `essentials.politicians` on the `-4730001..-4730042` band, and 42 `office_terms` rows written through `essentials.seat_officeholder(office_id, politician_id, term_start, source, how_started, start_precision)`.

- [ ] **Step 1: Append the people generator to `gen-nashville-migrations.mjs`**

Add this function and call it, immediately before the existing `console.log`:

```javascript
/**
 * 🔴 ONE GROUP REPEATS A (geo_id, district_type, office_title) TRIPLE: the five
 * 'Council Member at-Large' seats on the county polygon. A title join cannot
 * resolve one person to one office row inside that group, so the pairing is a
 * deterministic row_number() bijection -- offices ORDER BY o.id (stable once the
 * structure migration creates them), roster ORDER BY ext_id (fixed by
 * ROSTERS.md). The structure gate asserts exactly 5 offices in the group and the
 * payload guard below asserts exactly 5 roster rows, so both sides yield 1..5
 * with no gaps: a bijection, and idempotent on re-run.
 *
 * 🔴 Silent about OUT-OF-BAND deletion, exactly as CA_0007/CA_0010 are. If an
 * at-large office row is deleted outside these migrations and the structure
 * top-up regenerates it, the replacement gets a new UUID that may sort to a
 * different rank. The five seats are interchangeable so no voter-facing label
 * goes wrong -- but seat_officeholder() would then close and reopen terms
 * against the wrong predecessor, fabricating a term_end on a real record.
 */
function peopleSql(roster) {
  const values = roster
    .map(
      (r) =>
        `  (${q(r.geo_id)}, ${q(r.district_type)}, ${q(r.office_title)}, ${r.ext_id}, ${q(r.full_name)}, ` +
        `${q(r.first_name)}, ${q(r.last_name)}, ${q(r.middle_initial)}, ${q(r.name_suffix)}, ${arr(r.aliases)}, ` +
        `${q(r.term_start)}::date, ${q(r.start_precision)}, ${q(r.how_started)}, ${q(r.source)})`,
    )
    .join(',\n');
  const appointed = roster.filter((r) => r.how_started === 'appointed').length;

  return `-- CC_wip_nashville_metro_people.sql
-- Nashville deep-seed program, WAVE 1a (people). Companion: the structure migration.
--
-- Inserts 42 politicians and seats each one via essentials.seat_officeholder().
--
-- Roster: data/seed-nashville-davidson-2026/ROSTERS.md
-- Generated by: scripts/gen-nashville-migrations.mjs
--
-- ---------------------------------------------------------------------------
-- 🔴 IDENTITY IS KEYED ON external_id, BAND -4730001..-4730042, NEVER ON NAME.
-- Two collisions were measured in prod on 2026-08-27 and both are real:
--
--   Robert Nash    -5515005  a Village Trustee in WISCONSIN, not District 27.
--   Mike Cortese   -470405   sits in the TN CONGRESSIONAL DISTRICT 4 candidate
--                            band (-470401..-470410). Nashville is not in TN-04,
--                            and the matching district numbers are a coincidence.
--
-- A name-based insert guard would have inserted nothing for Nash, passed a 1:1
-- assertion, and seated a Wisconsin village trustee on a Nashville council seat.
-- That is wave 2's Mike Lee failure, reproduced exactly. See ROSTERS.md for the
-- ruling recorded on each.
--
-- ---------------------------------------------------------------------------
-- term_start is the day this person began holding THIS seat, continuously.
-- Re-election does not end an occupancy, so a member returned in 2023 who first
-- took the seat in 2019 carries the 2019 date. start_precision is per-source and
-- is NOT uniform. No term_end is written: a future term_end would make all 42
-- seats silently self-vacate.

BEGIN;

CREATE TEMP TABLE nash_seed (
  geo_id          text,
  district_type   text,
  office_title    text,
  ext_id          bigint,
  full_name       text,
  first_name      text,
  last_name       text,
  middle_initial  text,
  name_suffix     text,
  aliases         text[],
  term_start      date,
  start_precision text,
  how_started     text,
  source          text
) ON COMMIT DROP;

INSERT INTO nash_seed VALUES
${values};

-- --- Payload guard ----------------------------------------------------------
DO $$
DECLARE v_n int; v_dup int; v_grp int;
BEGIN
  SELECT count(*) INTO v_n FROM nash_seed;
  IF v_n <> 42 THEN RAISE EXCEPTION 'seed payload: expected 42 rows, got %', v_n; END IF;

  SELECT count(*) INTO v_dup FROM (SELECT ext_id FROM nash_seed GROUP BY ext_id HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'seed payload: % duplicate external_id(s)', v_dup; END IF;

  SELECT count(*) INTO v_grp FROM nash_seed
   WHERE geo_id = '${COUNTY_GEO_ID}' AND district_type = 'COUNTY' AND office_title = 'Council Member at-Large';
  IF v_grp <> ${N_AT_LARGE} THEN RAISE EXCEPTION 'seed payload: expected ${N_AT_LARGE} at-large rows, got %', v_grp; END IF;

  SELECT count(*) INTO v_grp FROM nash_seed WHERE office_title LIKE 'Council Member, District %';
  IF v_grp <> ${N_DISTRICTS} THEN RAISE EXCEPTION 'seed payload: expected ${N_DISTRICTS} district rows, got %', v_grp; END IF;

  -- Every OTHER triple must be unique -- the genuinely single-seat titles.
  SELECT count(*) INTO v_dup FROM (
    SELECT geo_id, district_type, office_title FROM nash_seed
    WHERE office_title <> 'Council Member at-Large'
    GROUP BY geo_id, district_type, office_title HAVING count(*) > 1
  ) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'seed payload: % unexpected duplicate single-seat key(s)', v_dup; END IF;
END $$;

-- --- Politicians ------------------------------------------------------------

INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, middle_initial, name_suffix,
   alternate_names, is_incumbent, is_active, data_source)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.middle_initial, s.name_suffix,
       s.aliases, true, true, s.source
FROM nash_seed s
ON CONFLICT (external_id) DO NOTHING;

-- --- Occupancy, via the helper ----------------------------------------------

DO $$
DECLARE
  r record;
  v_seated int := 0;
BEGIN
  FOR r IN
    WITH office_rank AS (
      SELECT o.id AS office_id, d.geo_id, d.district_type, o.title,
             row_number() OVER (
               PARTITION BY d.geo_id, d.district_type, o.title ORDER BY o.id
             ) AS rn
      FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
      WHERE d.mtfcc = '${MTFCC}'
         OR (d.geo_id = '${COUNTY_GEO_ID}' AND d.district_type = 'COUNTY')
    ),
    seed_rank AS (
      SELECT s.*,
             row_number() OVER (
               PARTITION BY s.geo_id, s.district_type, s.office_title ORDER BY s.ext_id
             ) AS rn
      FROM nash_seed s
    )
    SELECT sr.term_start, sr.start_precision, sr.how_started, sr.source,
           orr.office_id, p.id AS politician_id
    FROM seed_rank sr
    JOIN office_rank orr
      ON orr.geo_id = sr.geo_id
     AND orr.district_type = sr.district_type
     AND orr.title = sr.office_title
     AND orr.rn = sr.rn
    JOIN essentials.politicians p ON p.external_id = sr.ext_id
    WHERE NOT EXISTS (
      SELECT 1 FROM essentials.office_terms t
      WHERE t.office_id = orr.office_id AND t.politician_id = p.id
    )
  LOOP
    PERFORM essentials.seat_officeholder(
      r.office_id, r.politician_id, r.term_start,
      r.source,
      r.how_started,
      r.start_precision
    );
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'seated % Nashville Metro official(s)', v_seated;
END $$;

-- --- Post-verify gate -------------------------------------------------------
DO $$
DECLARE v_pol int; v_seated int; v_appointed int; v_homonym int; v_n int; v_d int;
BEGIN
  SELECT count(*) INTO v_pol
  FROM essentials.politicians WHERE external_id BETWEEN -4730042 AND -4730001;
  IF v_pol <> 42 THEN RAISE EXCEPTION 'nashville people: officials inserted: expected 42, got %', v_pol; END IF;

  -- count(och.politician_id), NOT count(*): office_current_holder LEFT JOINs
  -- from offices, so a vacancy is a NULL politician_id, never an absent row.
  -- count(*) would pass vacuously with every seat empty.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE d.mtfcc = '${MTFCC}'
      OR (d.geo_id = '${COUNTY_GEO_ID}' AND d.district_type = 'COUNTY');
  IF v_seated <> 42 THEN RAISE EXCEPTION 'nashville people: expected 42 seated officials, found %', v_seated; END IF;

  -- Per district, for the same reason the structure gate counts per district.
  FOR v_d IN 1..${N_DISTRICTS} LOOP
    SELECT count(och.politician_id) INTO v_n
      FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
     WHERE d.geo_id = 'nashville-tn-council-district-' || v_d AND d.mtfcc = '${MTFCC}';
    IF v_n <> 1 THEN RAISE EXCEPTION 'nashville people: council district % has % seated member(s), expected 1', v_d, v_n; END IF;
  END LOOP;

  SELECT count(*) INTO v_appointed
    FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE p.external_id BETWEEN -4730042 AND -4730001 AND t.how_started = 'appointed';
  IF v_appointed <> ${appointed} THEN RAISE EXCEPTION 'nashville people: expected ${appointed} appointed term(s), found %', v_appointed; END IF;

  -- 🔴 Cross-state homonym assertion: no Nashville seat may resolve to someone
  -- who also holds an office outside Tennessee. This is the Mike Lee guard, and
  -- Robert Nash is the live case it exists for.
  SELECT count(*) INTO v_homonym
  FROM essentials.politicians p
  JOIN essentials.office_current_holder och ON och.politician_id = p.id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
   AND (d.mtfcc = '${MTFCC}' OR (d.geo_id = '${COUNTY_GEO_ID}' AND d.district_type = 'COUNTY'))
  JOIN essentials.office_current_holder och2 ON och2.politician_id = p.id
  JOIN essentials.offices o2 ON o2.id = och2.office_id
  JOIN essentials.districts d2 ON d2.id = o2.district_id AND lower(d2.state) <> 'tn';
  IF v_homonym <> 0 THEN RAISE EXCEPTION
    'nashville people: % seat(s) resolved to an out-of-state politician -- the Mike Lee failure', v_homonym; END IF;

  RAISE NOTICE 'nashville people OK -- 42 officials seated, ${appointed} by appointment, 0 homonyms.';
END $$;

COMMIT;
`;
}
```

Then change the tail of the file to:

```javascript
const roster = readRoster();
writeFileSync('migrations/CC_wip_nashville_structure.sql', structureSql(roster));
writeFileSync('migrations/CC_wip_nashville_metro_people.sql', peopleSql(roster));
console.log('wrote migrations/CC_wip_nashville_structure.sql and migrations/CC_wip_nashville_metro_people.sql');
```

- [ ] **Step 2: Generate, then dry-run BOTH migrations in one transaction**

The people migration cannot run against prod alone, because its offices do not exist yet. Run the pair.

```bash
cd /c/EV-Accounts/backend && node scripts/gen-nashville-migrations.mjs && \
{ echo 'BEGIN;'; \
  sed -e '/^BEGIN;$/d' -e '/^COMMIT;$/d' migrations/CC_wip_nashville_structure.sql; \
  sed -e '/^BEGIN;$/d' -e '/^COMMIT;$/d' migrations/CC_wip_nashville_metro_people.sql; \
  echo 'ROLLBACK;'; } | psql "$DATABASE_URL" -v ON_ERROR_STOP=1
```

Expected, in order:

```
NOTICE:  nashville structure OK -- 42 offices across 35 council districts and the Davidson county polygon.
NOTICE:  seated 42 Nashville Metro official(s)
NOTICE:  nashville people OK -- 42 officials seated, N by appointment, 0 homonyms.
ROLLBACK
```

⚠ `ON COMMIT DROP` on the temp table is harmless under `ROLLBACK`, which drops it too.

- [ ] **Step 3: Confirm the rollback reverted**

```bash
cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -c "
select (select count(*) from essentials.districts where mtfcc = 'X0035') as districts,
       (select count(*) from essentials.politicians where external_id between -4730042 and -4730001) as people;"
```

Expected: `0, 0`.

- [ ] **Step 4: Prove the homonym guard can fail**

The Mike Lee guard is the most important assertion in this migration and it has never been seen to fire. Temporarily add a row to `nash_seed` that reuses the Wisconsin `Robert Nash` politician — set District 27's `ext_id` to `-5515005` in `ROSTERS.md`, regenerate, and re-run the paired dry run.

Expected: `ERROR: nashville people: 1 seat(s) resolved to an out-of-state politician -- the Mike Lee failure`, and the whole transaction aborts.

Then restore `ROSTERS.md`, regenerate, and re-run Step 2 to confirm it is green again.

---

### Task 5: Take the numbers, apply, commit

**Files:**
- Rename: `backend/migrations/CC_wip_nashville_structure.sql` → `CC_000N_nashville_structure.sql`
- Rename: `backend/migrations/CC_wip_nashville_metro_people.sql` → `CC_000N+1_nashville_metro_people.sql`
- Modify: `backend/scripts/gen-nashville-migrations.mjs` (the header comments and the `writeFileSync` paths)

- [ ] **Step 1: Fetch, then read the real next free slot**

```bash
cd /c/EV-Accounts && git fetch origin && cd backend && \
npm run check:migrations --prefix . -- --list-duplicates && \
ls migrations/ | grep '^CC_' | sort
```

Expected: the checker passes, and the listing shows the highest `CC_` slot in use. The next two free slots are that number plus one and plus two — expected `CC_0004` and `CC_0005`, but **use what the command prints**, not what this plan predicts. Another session may have taken them.

- [ ] **Step 2: Rename and update every embedded reference**

```bash
cd /c/EV-Accounts/backend && N1=CC_0004 && N2=CC_0005 && \
git mv migrations/CC_wip_nashville_structure.sql "migrations/${N1}_nashville_structure.sql" && \
git mv migrations/CC_wip_nashville_metro_people.sql "migrations/${N2}_nashville_metro_people.sql" && \
sed -i "s/CC_wip_nashville_structure/${N1}_nashville_structure/g; s/CC_wip_nashville_metro_people/${N2}_nashville_metro_people/g" \
  "migrations/${N1}_nashville_structure.sql" "migrations/${N2}_nashville_metro_people.sql" scripts/gen-nashville-migrations.mjs && \
grep -rn "CC_wip" migrations/ scripts/gen-nashville-migrations.mjs || echo "no CC_wip references remain"
```

Replace `CC_0004` / `CC_0005` with whatever Step 1 printed. Expected final line: `no CC_wip references remain`.

- [ ] **Step 3: Re-run the numbering check**

```bash
cd /c/EV-Accounts/backend && npm run check:migrations --prefix .
```

Expected: pass. A failure here means the slot was claimed on another ref — go back to Step 1.

- [ ] **Step 4: Apply both migrations to prod, in order**

```bash
cd /c/EV-Accounts/backend && \
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f migrations/CC_0004_nashville_structure.sql && \
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f migrations/CC_0005_nashville_metro_people.sql
```

Expected: the same three NOTICE lines as the dry run, each followed by `COMMIT`.

- [ ] **Step 5: Re-run both migrations to prove idempotency**

```bash
cd /c/EV-Accounts/backend && \
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f migrations/CC_0004_nashville_structure.sql && \
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f migrations/CC_0005_nashville_metro_people.sql
```

Expected: identical NOTICE output, and `seated 0 Nashville Metro official(s)` the second time. Any count changing on a second run is a defect — stop and fix it.

- [ ] **Step 6: Commit**

```bash
cd /c/EV-Accounts && git add -- backend/migrations/CC_0004_nashville_structure.sql backend/migrations/CC_0005_nashville_metro_people.sql backend/scripts/gen-nashville-migrations.mjs && \
git commit -F- -- backend/migrations/CC_0004_nashville_structure.sql backend/migrations/CC_0005_nashville_metro_people.sql backend/scripts/gen-nashville-migrations.mjs <<'MSG'
feat(nashville): seat the 42 Metro Nashville / Davidson County offices

CC_0004 creates 35 council districts on X0035, one government, two
chambers and 42 offices. CC_0005 inserts the 42 people and seats them.
Both applied to prod and re-run clean.

The council chamber spans 36 districts, so every top-up and every gate
counts per (chamber_id, district_id). A chamber-scoped count is the
CA_0006 bug, and this chamber is the shape it warned about.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
MSG
```

---

### Task 6: End-to-end verification

The migration gates prove the rows exist. They do not prove a resident can find these people. That is a different question, and it is the one that matters.

**Files:**
- Create: `backend/scripts/verify-nashville-wave1a-probes.sql`

- [ ] **Step 1: Write the probe script**

```sql
-- verify-nashville-wave1a-probes.sql
-- Nashville wave 1a acceptance. Run after CC_0004 + CC_0005.
--
-- Every positive probe is paired with a control that proves the query can fail.
-- A query that cannot fire returns zero rows and satisfies a "found nothing
-- wrong" reading of every negative assertion.
--
--   psql "$DATABASE_URL" -f scripts/verify-nashville-wave1a-probes.sql

\echo '--- 1. Metro Courthouse: one council district plus every countywide seat ---'
-- A point resolves ONE council district plus every countywide seat: 1 + 5
-- at-large + Vice Mayor + Mayor = 8 Metro officials.
SELECT count(och.politician_id) AS metro_officials
  FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
 WHERE (d.mtfcc = 'X0035' OR (d.geo_id = '47037' AND d.district_type = 'COUNTY'))
   AND EXISTS (
     SELECT 1 FROM essentials.geofence_boundaries b
      WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc
        AND public.ST_Covers(b.geometry, public.ST_SetSRID(public.ST_MakePoint(-86.7761, 36.1665), 4326))
   );
\echo 'EXPECT: 8'

\echo '--- 2. Belle Meade City Hall: the satellite-city test, expect the same 8 ---'
SELECT count(och.politician_id) AS metro_officials
  FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
 WHERE (d.mtfcc = 'X0035' OR (d.geo_id = '47037' AND d.district_type = 'COUNTY'))
   AND EXISTS (
     SELECT 1 FROM essentials.geofence_boundaries b
      WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc
        AND public.ST_Covers(b.geometry, public.ST_SetSRID(public.ST_MakePoint(-86.8583, 36.1006), 4326))
   );
\echo 'EXPECT: 8  -- if this is 7 the county polygon is missing; if 0 the place polygon was used'

\echo '--- 3. Belle Meade resolves council district 23 specifically ---'
SELECT d.geo_id, o.title, p.full_name
  FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id = d.id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  JOIN essentials.politicians p ON p.id = och.politician_id
  JOIN essentials.geofence_boundaries b ON b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc
 WHERE d.mtfcc = 'X0035'
   AND public.ST_Covers(b.geometry, public.ST_SetSRID(public.ST_MakePoint(-86.8583, 36.1006), 4326));
\echo 'EXPECT: exactly one row, nashville-tn-council-district-23'

\echo '--- 4. CONTROL OF THE CONTROL: Brentwood, Williamson County, expect ZERO ---'
SELECT count(*) AS metro_seats_outside_davidson
  FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id = d.id
  JOIN essentials.geofence_boundaries b ON b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc
 WHERE d.mtfcc = 'X0035'
   AND public.ST_Covers(b.geometry, public.ST_SetSRID(public.ST_MakePoint(-86.7828, 35.9739), 4326));
\echo 'EXPECT: 0  -- probes 1-3 are only meaningful because this one is 0'

\echo '--- 5. Every council district resolves exactly one seated member ---'
SELECT count(*) AS districts_not_returning_exactly_one
  FROM essentials.districts d
 WHERE d.mtfcc = 'X0035'
   AND (SELECT count(och.politician_id)
          FROM essentials.offices o
          LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
         WHERE o.district_id = d.id) <> 1;
\echo 'EXPECT: 0'

\echo '--- 6. The Vice Mayor note is present and substantive ---'
SELECT o.title, o.voting_powers, length(o.representation_note) AS note_len
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE d.geo_id = '47037' AND d.district_type = 'COUNTY' AND o.title = 'Vice Mayor';
\echo 'EXPECT: one row, voting_powers full, note_len > 40'

\echo '--- 7. Nothing landed on Davidson County, NORTH CAROLINA ---'
SELECT count(*) AS nc_davidson_offices
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE d.geo_id = '37057' AND d.district_type = 'COUNTY';
\echo 'EXPECT: 0'

\echo '--- 8. offices_missing_terms did not grow ---'
SELECT count(*) AS unflagged_missing_terms
  FROM essentials.offices_missing_terms
 WHERE is_vacant IS NOT TRUE;
\echo 'EXPECT: <= 699  -- the migration-1464 baseline'
```

- [ ] **Step 2: Run it**

```bash
cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -f scripts/verify-nashville-wave1a-probes.sql
```

Compare each result against its `EXPECT` line. Probe 4 must be `0` before probes 1 to 3 mean anything.

- [ ] **Step 3: Run the repository gates**

```bash
cd /c/EV-Accounts/backend && npm run check:occupancy --prefix . && npm run check:migrations --prefix . && \
npm run check:reachability --prefix .
```

Expected: all three pass. `check:reachability` is the one that matters most here — it takes `ST_PointOnSurface` of each new district's own polygon and runs the real address-search join, so it exercises the guard, the geometry, the occupancy and the reps filters together. `ST_COVERS_ROUNDTRIP` and `REPS_FILTER_HIDDEN` are zero-tolerance and the 35 new districts are in scope from their first run.

- [ ] **Step 4: Commit and open the pull request**

```bash
cd /c/EV-Accounts && git add -- backend/scripts/verify-nashville-wave1a-probes.sql && \
git commit -F- -- backend/scripts/verify-nashville-wave1a-probes.sql <<'MSG'
test(nashville): wave 1a address probes, with the control of the control

Belle Meade City Hall is the load-bearing probe: it is inside a satellite
city that the TIGER place polygon 4752006 excludes, and it must still
return the full Metro slate. Brentwood must return zero, which is what
makes the other three probes mean anything.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
MSG
git push -u origin feat/nashville-davidson-deep-seed
gh pr create --base master --title "feat(nashville): wave 1a — seat the 42 Metro Nashville / Davidson seats" --body "$(cat <<'BODY'
Wave 1a of the Nashville / Davidson deep seed. Spec: `.planning/todos/2026-08-27-nashville-davidson-deep-seed.md`.

- `X0035` — 35 Metro Council district polygons from Metro's own GIS
- `CC_0004` — 35 districts, 1 government, 2 chambers, 42 offices
- `CC_0005` — 42 politicians, 42 terms, all open-ended
- Both applied to prod and re-run clean

Nashville is a consolidated city-county, so one government covers both tiers and its `geo_id` is the **county** polygon `47037`. The TIGER place `4752006` is the metropolitan government *balance* and excludes six satellite cities whose residents elect this same council — `verify-nashville-wave1a-probes.sql` probes Belle Meade City Hall for exactly that reason, with Brentwood as the control that proves the probe can fail.

Countywide officers are wave 1b, deliberately: they took office 2026-09-01.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
BODY
)"
```

- [ ] **Step 5: Run the four PR-gated CI jobs**

A `workflow_dispatch` run covers only half the jobs. These four are gated on `pull_request || push` and must be seen green:
`migration numbering`, `answer-delete context guards`, `cal-access predicate tripwire`, `office occupancy`.

Since the PR targets `master`, opening it triggers them. Confirm with:

```bash
cd /c/EV-Accounts && gh pr checks --watch
```

Expected: all checks pass. If the PR was opened against a non-`master` base at any point, retargeting it does **not** trigger CI — close and reopen the PR instead.

---

## Self-review

**Spec coverage.** Spec §Geography → Task 2. §Government and chambers → Task 3. §Offices → Task 3, including the `(chamber_id, district_id)` scoping and `representing_city`. §Vice Mayor → Task 1 Step 4 (charter ruling), Task 3 Step 2 (the office and its note). §Identity → Task 1 Step 5 and Task 4's guard, with both measured collisions named. §Terms → Task 1 Step 6 and Task 4. §Verification → Task 6. §Waves → Task 5.

**Not covered here, by design:** wave 1b (county officers), 1c (the read-path change that makes the Vice Mayor note render), 1d (headshots), 1e (banner). The Vice Mayor note is written to the database by this wave but stays invisible until 1c ships. That is stated in the migration's own comment so nobody reads the blank render as a data defect.

**Open item carried into execution:** `COUNTY_FIT_TOLERANCE_SQ_KM` is set to a defensible 6.0 but is not yet measured. Task 2 Step 4 requires tightening it to the observed values before the real load. This is the one constant in the plan whose value is provisional, and it is flagged in the code comment as well as here.
