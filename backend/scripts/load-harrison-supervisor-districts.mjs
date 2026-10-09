#!/usr/bin/env node
/**
 * load-harrison-supervisor-districts.mjs — Knight program, wave MS-4.
 *
 * Builds Harrison County's five Supervisor District polygons and inserts them into
 *
 *   essentials.geofence_boundaries  geo_id='harrison-ms-supervisor-district-1' … '-5', mtfcc='X0074'
 *
 * Writes ONLY to essentials.geofence_boundaries. The structure migration creates the districts and
 * their offices and REFUSES TO RUN if these five boundaries are absent — an office on a district
 * with no polygon is unreachable by any address, and NOTHING ERRORS.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────
 * 🟢🟢 ONE GEOMETRY CARRIES TWENTY OFFICES, AND THAT IS MEASURED, NOT ASSUMED.
 *
 * Harrison County elects FOUR different office sets from five districts each: Supervisors,
 * Justice Court Judges, Constables and Election Commissioners. Statute allows them to differ —
 * Miss. Code § 9-11-2 lets the board draw the justice court districts — so "they are all the
 * beats" is exactly the kind of convenient assumption this programme refuses.
 *
 * ▶ THEY WERE PROVED IDENTICAL FROM THE SECRETARY OF STATE'S OWN CERTIFIED RESULTS, PRECINCT BY
 * PRECINCT. In the 2023 Official Recapitulation for Harrison County, the precincts that cast votes
 * in Supervisor District N are exactly the precincts that cast votes in Justice Court Judge
 * District N and in Constable District N. And the county totals track each other district for
 * district — Supervisor 4,728 / 7,761 / 9,146 / 5,676 / 7,814 against Constable 4,754 / 7,842 /
 * 9,159 / 5,745 / 7,792 and Justice Court 4,859 / 7,890 / 9,296 — which is one electorate counted
 * three times, not three electorates that happen to be close.
 *
 * ── WHERE THE GEOMETRY COMES FROM ────────────────────────────────────────────────────────────
 * `services1.arcgis.com/HMvCOUg20YqJBIY9/.../SupervisorDistricts/FeatureServer/0`, the county's own
 * AGOL org (harcogis), item last edited 2025-10-08.
 * ⚠ The county ALSO publishes the same subject at `geo.co.harrison.ms.us/server/rest/services/AGO/
 * HarrisonCounty_SupervisorDistrict/FeatureServer`, whose item was last edited 2022-01-14. That
 * host sits behind the same Cloudflare challenge as the county's web pages and answers a bare
 * fetch with HTML, so it cannot be read from Node at all. The AGOL copy is both readable and
 * newer, and the anchors below are what actually decide it.
 *
 * 🔴🔴 THE COUNTY'S OWN BOARD PAGE STILL DESCRIBES THE 2010-CENSUS REDISTRICTING. A page's prose
 * cannot date a plan any more than a layer's name can (MS-3's `Wards2022`). What settles it is that
 * the layer agrees with the districts the 2023 election was actually RUN under, at every anchor.
 *
 * 🔴🔴 `DIST_ID` IS NOT THE DISTRICT NUMBER. `District` IS.
 * The layer carries both, and DIST_ID is a PERMUTATION of 1–5 that is wrong for four of the five:
 *     District 1 → DIST_ID 1      District 2 → DIST_ID 5      District 3 → DIST_ID 4
 *     District 4 → DIST_ID 3      District 5 → DIST_ID 2
 * A join on DIST_ID would silently swap Districts 2 and 5 and Districts 3 and 4 — sending voters in
 * four of five districts to the wrong supervisor, the wrong judge, the wrong constable and the
 * wrong election commissioner at once. This is MS-3's Biloxi `Id` trap in the very next wave, and
 * worse: there, the bad field repeated and so looked broken; here it is a clean permutation of
 * exactly the right values and looks perfect. Control 3 asserts the permutation still exists.
 *
 * 🟢 AND THE LAYER NAMES ITS OWN SUPERVISORS. `DIST_NAME` carries the officeholder, which lets the
 * Secretary of State's certified 2023 winners be checked straight against the geometry's own
 * attributes — a cross-source agreement that costs nothing and would catch a swapped file.
 *
 * ⚠ THE POLLING-PLACE LAYER HAS THREE RECORDS AT LATITUDE 0, LONGITUDE 0 — null island — in its
 * LAT and LON ATTRIBUTES, while its GEOMETRY is correct for all 49. Biloxi #8 is one of them. A
 * test built on the attributes would put three anchors in the Gulf of Guinea, match no district,
 * and read as a broken boundary file. This loader uses the geometry and never the attributes.
 *
 * Controls, all of which must fire before any row is written:
 *   1. a bogus layer id must fail to return features;
 *   2. `District` must be exactly {1,2,3,4,5};
 *   3. `DIST_ID` must STILL disagree with `District` for four of five, so nobody "simplifies" to it;
 *   4. `DIST_NAME` must match the Secretary of State's certified 2023 winners;
 *   5. every extra ring must be a hole, not a part;
 *   6. the 18 precincts whose district the CERTIFIED RESULTS state must fall in that district;
 *   7. all 49 polling places must fall in the district their own layer names;
 *   8. Biloxi City Hall must fall in EXACTLY ONE district, and two out-of-county points in NONE.
 *
 * Usage:
 *   node scripts/load-harrison-supervisor-districts.mjs --dry-run
 *   node scripts/load-harrison-supervisor-districts.mjs
 *   node scripts/load-harrison-supervisor-districts.mjs --dry-run --control=<n>
 */
import pg from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

const DRY_RUN = process.argv.includes('--dry-run');
const CONTROL = (process.argv.find((a) => a.startsWith('--control=')) || '').split('=')[1] || '';

const LAYER =
  'https://services1.arcgis.com/HMvCOUg20YqJBIY9/arcgis/rest/services/SupervisorDistricts/FeatureServer/0';
const POLLS =
  'https://services1.arcgis.com/HMvCOUg20YqJBIY9/arcgis/rest/services/Polling_Places/FeatureServer/0';
const MTFCC = 'X0074';
const STATE_FIPS = '28';
const SOURCE =
  'Harrison County, Mississippi GIS, feature service "SupervisorDistricts" layer 0, ' +
  'services1.arcgis.com/HMvCOUg20YqJBIY9/.../SupervisorDistricts/FeatureServer/0 (county AGOL org ' +
  'harcogis, last edited 2025-10-08); agrees with the Mississippi Secretary of State\'s Official ' +
  'Recapitulation for the 2023 General Election in Harrison County at all 18 precincts whose ' +
  'supervisor district that document states, and with the county\'s own polling-place layer at all ' +
  '49 polling places; read 2026-09-28 (MS-4)';

const EXPECTED_DISTRICTS = [1, 2, 3, 4, 5];

/** The Secretary of State's certified 2023 winners, one per district. Not from this layer. */
const CERTIFIED_SUPERVISORS = {
  1: 'Dan Cuevas',
  2: 'Rebecca Powers',
  3: 'Marlin Ladner',
  4: 'Kent Jones',
  5: 'Nathan Barrett',
};

/** DIST_ID as measured 2026-09-28 — kept so control 3 can assert the field is still unusable. */
const KNOWN_DIST_ID = { 1: '1', 2: '5', 3: '4', 4: '3', 5: '2' };

/**
 * Precinct → supervisor district, read from the SOS Official Recapitulation (2023 General,
 * Harrison County, pages 27 and 31): the precincts that cast votes in each Supervisor contest.
 * NOTHING here comes from the county's GIS.
 */
const CERTIFIED_PRECINCTS = {
  'ADVANCE': 2, 'BAY CENTRAL': 5, 'BAYOU VIEW': 2, 'BILOXI #11': 5, 'BILOXI #8': 1,
  'BILOXI 10': 1, 'BILOXI CENTRAL': 1, 'COUNTY FARM/GULF HAVEN': 3, 'DELISLE': 3,
  'E ORANGE GROVE': 2, 'E PASS CHRISTIAN': 3, 'WEST LIZANA': 3, 'WEST LONG BEACH': 3,
  'WEST MISSISSIPPI CITY': 2, 'WEST NORTH GPT': 4, 'WEST ORANGE GROVE': 2, 'WESTSIDE': 3,
  'WHITE PLAINS': 1,
};

/**
 * 🔴 ONE alias, written out rather than inferred. A rule like "expand a leading E to EAST" also
 * turns EAST into EASTAST and WHITE into WESTHITE — measured, not imagined, while writing this.
 * Do not replace this table with a clever regex.
 */
const PRECINCT_ALIASES = { 'EORANGEGROVE': 'EASTORANGEGROVE' };
const normName = (s) => {
  const k = String(s).toUpperCase().replace(/[^A-Z0-9/]/g, '');
  return PRECINCT_ALIASES[k] || k;
};

const PROBES = [
  { label: 'Biloxi City Hall', lat: 30.395195772412, lon: -88.887065616037, want: 1 },
  { label: 'CONTROL: Mobile, Alabama', lat: 30.6954, lon: -88.0399, want: 0 },
  { label: 'CONTROL: Hattiesburg, Forrest County MS', lat: 31.3271, lon: -89.2903, want: 0 },
];

const slug = (d) => `harrison-ms-supervisor-district-${d}`;

async function fetchGeoJson(url, outFields) {
  const q = `${url}/query?where=1%3D1&outFields=${encodeURIComponent(outFields)}&returnGeometry=true&outSR=4326&f=geojson`;
  const res = await fetch(q, { headers: { 'User-Agent': 'ev-accounts/ms-slice16' } });
  if (!res.ok) throw new Error(`HTTP ${res.status} for ${q}`);
  const j = await res.json();
  if (!j || j.type !== 'FeatureCollection' || !Array.isArray(j.features) || j.features.length === 0) {
    throw new Error(`no FeatureCollection returned from ${q}`);
  }
  return j;
}

// ── ring geometry helpers — identical maths to MS-3's Biloxi loader, deliberately ────────────
const signedArea = (r) => {
  let s = 0;
  for (let i = 0, n = r.length; i < n; i++) {
    const [x1, y1] = r[i];
    const [x2, y2] = r[(i + 1) % n];
    s += x1 * y2 - x2 * y1;
  }
  return s / 2;
};
const ringHas = ([x, y], r) => {
  let inside = false;
  for (let i = 0, k = r.length - 1; i < r.length; k = i++) {
    const [xi, yi] = r[i];
    const [xj, yj] = r[k];
    if (yi > y !== yj > y && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) inside = !inside;
  }
  return inside;
};
const polyHas = (p, rings) => {
  if (!ringHas(p, rings[0])) return false;
  for (let k = 1; k < rings.length; k++) if (ringHas(p, rings[k])) return false;
  return true;
};
const featureHas = (p, geom) => {
  if (geom.type === 'Polygon') return polyHas(p, geom.coordinates);
  if (geom.type === 'MultiPolygon') return geom.coordinates.some((rings) => polyHas(p, rings));
  throw new Error(`unsupported geometry type ${geom.type}`);
};
const bboxOf = (r) =>
  r.reduce((b, [x, y]) => [Math.min(b[0], x), Math.min(b[1], y), Math.max(b[2], x), Math.max(b[3], y)],
    [Infinity, Infinity, -Infinity, -Infinity]);
const bboxInside = (a, b) => a[0] >= b[0] && a[1] >= b[1] && a[2] <= b[2] && a[3] <= b[3];

/**
 * MS-3's finding, applied again: an ArcGIS `f=geojson` export may put a hole in its own top-level
 * part rather than in an inner ring, and then PostGIS reads it as territory. A part counts as a
 * hole only when the nesting test and the winding test agree.
 */
function reassemble(geom, district) {
  const parts = geom.type === 'MultiPolygon' ? geom.coordinates : [geom.coordinates];
  const outer = parts.map((rings) => rings[0]);
  const inner = parts.map((rings) => rings.slice(1));
  const boxes = outer.map(bboxOf);
  const areas = outer.map(signedArea);

  const parentOf = outer.map(() => -1);
  for (let i = 0; i < outer.length; i++) {
    for (let k = 0; k < outer.length; k++) {
      if (i === k || !bboxInside(boxes[i], boxes[k])) continue;
      if (outer[i].every((pt) => ringHas(pt, outer[k]))) {
        if (parentOf[i] !== -1) {
          throw new Error(`🔴 district ${district}: part ${i} is nested inside two parts — deeper than one level`);
        }
        parentOf[i] = k;
      }
    }
  }
  const majority = Math.sign(areas.reduce((a, v) => a + Math.sign(v), 0)) || -1;
  for (let i = 0; i < outer.length; i++) {
    const nested = parentOf[i] !== -1;
    if (nested && Math.sign(areas[i]) === Math.sign(areas[parentOf[i]])) {
      throw new Error(
        `🔴 district ${district}: part ${i} is nested inside part ${parentOf[i]} but wound the SAME way — ` +
        `an island inside a lake, which this loader would drop. Re-measure.`,
      );
    }
    if (!nested && Math.sign(areas[i]) !== majority) {
      throw new Error(
        `🔴 district ${district}: part ${i} is wound against the other parts but nested in none — ` +
        `the winding convention has changed; re-measure before writing.`,
      );
    }
  }

  const coords = [];
  let holes = 0;
  for (let i = 0; i < outer.length; i++) {
    if (parentOf[i] !== -1) continue;
    const mine = [];
    for (let h = 0; h < outer.length; h++) if (parentOf[h] === i) { mine.push(outer[h]); holes++; }
    coords.push([outer[i], ...inner[i], ...mine]);
    holes += inner[i].length;
  }
  return { geometry: { type: 'MultiPolygon', coordinates: coords }, parts: coords.length, holes };
}

const districtOf = (f) => Number(f.properties.District);

async function run() {
  // ── CONTROL 1: a bogus layer must fail. ────────────────────────────────────
  let control = false;
  try {
    await fetchGeoJson(LAYER.replace(/\/0$/, '/999'), 'District');
  } catch {
    control = true;
    console.log('control 1 OK — bogus layer id returned no features');
  }
  if (!control) throw new Error('🔴 CONTROL 1 DID NOT FIRE — a bogus layer returned features. Nothing below proves anything.');

  const fc = await fetchGeoJson(LAYER, 'District,DIST_ID,DIST_NAME');
  console.log(`fetched ${fc.features.length} districts from ${LAYER}`);

  if (CONTROL === '2') fc.features.pop();
  if (CONTROL === '3') for (const f of fc.features) f.properties.DIST_ID = f.properties.District;
  if (CONTROL === '4') fc.features.find((f) => districtOf(f) === 3).properties.DIST_NAME = 'Someone Else';
  if (CONTROL === '6') {
    // 🔴 Swap two districts' GEOMETRY. Relabelling would trip control 2 first and leave the anchor
    // tests unproven — MS-3's shadowing finding, which by now is the expectation, not a surprise.
    const a = fc.features.find((f) => districtOf(f) === 2);
    const b = fc.features.find((f) => districtOf(f) === 5);
    [a.geometry, b.geometry] = [b.geometry, a.geometry];
  }

  // ── CONTROL 2: the district set, read from `District`. ─────────────────────
  const ds = fc.features.map(districtOf).sort((a, b) => a - b);
  if (JSON.stringify(ds) !== JSON.stringify(EXPECTED_DISTRICTS)) {
    throw new Error(`🔴 District values ${JSON.stringify(ds)}, expected ${JSON.stringify(EXPECTED_DISTRICTS)}`);
  }
  console.log(`control 2 OK — District is exactly ${ds.join(', ')}`);

  // ── CONTROL 3: DIST_ID must still be the wrong field. ──────────────────────
  const wrong = fc.features.filter((f) => String(f.properties.DIST_ID) !== String(districtOf(f))).length;
  const asMeasured = fc.features.every((f) => String(f.properties.DIST_ID) === KNOWN_DIST_ID[districtOf(f)]);
  if (wrong !== 4 || !asMeasured) {
    throw new Error(
      `🔴 DIST_ID no longer matches the permutation measured 2026-09-28 (${wrong} of 5 disagree with District). ` +
      `This loader keys on District BECAUSE DIST_ID is a permutation that is wrong for four of five. ` +
      `If the source has been repaired, re-read it and re-choose the key rather than inheriting this one.`,
    );
  }
  console.log('control 3 OK — DIST_ID still disagrees with District for 4 of 5, so it is not the key');

  // ── CONTROL 4: the layer's own names against the certified 2023 winners. ───
  for (const f of fc.features) {
    const d = districtOf(f);
    const got = String(f.properties.DIST_NAME || '').trim();
    if (got !== CERTIFIED_SUPERVISORS[d]) {
      throw new Error(
        `🔴 district ${d}: layer names "${got}", the Secretary of State's certified 2023 winner is ` +
        `"${CERTIFIED_SUPERVISORS[d]}"`,
      );
    }
  }
  console.log('control 4 OK — all 5 DIST_NAME values match the certified 2023 winners');

  // ── CONTROL 5: re-assemble parts and holes. ────────────────────────────────
  let totalParts = 0;
  let totalHoles = 0;
  for (const f of fc.features) {
    const r = reassemble(f.geometry, districtOf(f));
    f.geometry = r.geometry;
    totalParts += r.parts;
    totalHoles += r.holes;
  }
  console.log(`control 5 OK — ${totalParts} parts and ${totalHoles} hole(s); nesting and winding agree`);

  // ── the polling places, used by controls 6 and 7. ──────────────────────────
  const pp = await fetchGeoJson(POLLS, 'NAME,District,LAT,LON');
  // 🔴 Controls 7 and 7a are perturbed on the POLLING layer, not the district geometry. A geometry
  // change trips control 6 first — the certified anchors run earlier and share the same polygons —
  // so a geometry tamper can never prove either of these. Touch the attribute instead.
  if (CONTROL === '7') {
    const g13 = pp.features.find((f) => normName(f.properties.NAME) === normName('GULFPORT # 13'));
    g13.properties.District = g13.properties.District === '1' ? '2' : '1';
  }
  if (CONTROL === '7a') {
    pp.features.find((f) => normName(f.properties.NAME) === normName('SAUCIER')).properties.District = ' ';
  }
  const zeroAttr = pp.features.filter((f) => Number(f.properties.LAT) === 0 || Number(f.properties.LON) === 0).length;
  const noGeom = pp.features.filter((f) => !f.geometry || !Array.isArray(f.geometry.coordinates)).length;
  if (noGeom !== 0) throw new Error(`🔴 ${noGeom} polling place(s) carry no geometry; the anchors cannot be built`);
  console.log(`fetched ${pp.features.length} polling places — ${zeroAttr} of them carry LAT/LON 0,0 in their ATTRIBUTES; geometry is used instead`);
  if (zeroAttr === 0) {
    throw new Error(
      '🔴 the null-island records are gone. This loader deliberately ignores LAT/LON because three ' +
      'of 49 read 0,0 on 2026-09-28. Re-read the source and re-decide before trusting the attributes.',
    );
  }

  const byName = new Map();
  for (const f of pp.features) byName.set(normName(f.properties.NAME), f);

  const districtAt = (lon, lat) => fc.features.filter((f) => featureHas([lon, lat], f.geometry)).map(districtOf);

  // ── CONTROL 6: the Secretary of State's certified precinct→district mapping. ─
  let cert = 0;
  for (const [precinct, want] of Object.entries(CERTIFIED_PRECINCTS)) {
    const f = byName.get(normName(precinct));
    if (!f) throw new Error(`🔴 certified precinct "${precinct}" has no polling place in the county layer`);
    const [lon, lat] = f.geometry.coordinates;
    const hits = districtAt(lon, lat);
    if (hits.length !== 1 || hits[0] !== want) {
      throw new Error(
        `🔴 certified precinct "${precinct}": the Secretary of State's 2023 recapitulation puts it in ` +
        `Supervisor District ${want}; this geometry says ${JSON.stringify(hits)}`,
      );
    }
    cert++;
  }
  console.log(`control 6 OK — all ${cert} precincts land in the district the CERTIFIED 2023 RESULTS put them in`);

  // ── CONTROL 7: every polling place against the county's own District field. ─
  // 🔴 ONE RECORD DOES NOT STATE A DISTRICT, AND IT IS SPLIT OUT RATHER THAN SWEPT UP.
  // "EAST ORANGE GROVE" carries District = " " (a single space) AND LAT/LON 0,0 — the one record
  // in 49 that is defective twice over. The honest move is to name it, assert that it is still the
  // ONLY one, and require that the certified results cover it — not to widen the filter until it
  // falls out quietly. It IS covered: the Secretary of State's recapitulation puts E Orange Grove
  // in Supervisor District 2, and control 6 has already tested that point.
  const unstated = pp.features.filter((f) => !/^[1-5]$/.test(String(f.properties.District).trim()));
  if (unstated.length !== 1 || normName(unstated[0].properties.NAME) !== normName('EAST ORANGE GROVE')) {
    throw new Error(
      `🔴 ${unstated.length} polling place(s) state no district ` +
      `(${unstated.map((f) => `"${f.properties.NAME}"`).join(', ')}); measured 2026-09-28 there was exactly one, ` +
      `EAST ORANGE GROVE. Re-read the source and re-decide which anchors cover the gap.`,
    );
  }
  if (!(normName('E ORANGE GROVE') in
        Object.fromEntries(Object.keys(CERTIFIED_PRECINCTS).map((k) => [normName(k), true])))) {
    throw new Error('🔴 the one district-less polling place is not covered by a certified anchor');
  }
  console.log(`control 7a OK — exactly 1 polling place states no district (EAST ORANGE GROVE), and a certified anchor covers it`);

  let agree = 0;
  for (const f of pp.features) {
    const raw = String(f.properties.District).trim();
    if (!/^[1-5]$/.test(raw)) continue;
    const want = Number(raw);
    const [lon, lat] = f.geometry.coordinates;
    const hits = districtAt(lon, lat);
    if (hits.length !== 1 || hits[0] !== want) {
      throw new Error(
        `🔴 polling place "${f.properties.NAME}": layer says District ${want}, geometry says ${JSON.stringify(hits)}`,
      );
    }
    agree++;
  }
  if (agree !== pp.features.length - 1) {
    throw new Error(`🔴 control 7 checked ${agree} polling places, expected ${pp.features.length - 1}`);
  }
  console.log(`control 7 OK — all ${agree} polling places that state a district fall in it`);

  // ── CONTROL 8: the probes. ─────────────────────────────────────────────────
  for (const p of PROBES) {
    const hits = districtAt(p.lon, p.lat);
    if (hits.length !== p.want) {
      throw new Error(`🔴 ${p.label}: matched ${hits.length} district(s) ${JSON.stringify(hits)}, expected ${p.want}`);
    }
    console.log(`control 8 OK — ${p.label}: ${hits.length ? `district ${hits[0]}` : 'no district'}`);
  }

  if (DRY_RUN) {
    console.log('\n[dry-run] all controls passed — would write:');
    for (const f of fc.features.slice().sort((a, b) => districtOf(a) - districtOf(b))) {
      console.log(`  ${MTFCC}  ${slug(districtOf(f))}  "Harrison County Supervisor District ${districtOf(f)}"  (${f.properties.DIST_NAME})`);
    }
    console.log('[dry-run] no DB writes made.');
    return;
  }

  const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
  await client.connect();
  try {
    const { rows: pre } = await client.query(
      `SELECT count(*)::int AS n,
              count(*) FILTER (WHERE geo_id LIKE 'harrison-ms-supervisor-district-%')::int AS ours
         FROM essentials.geofence_boundaries WHERE mtfcc = $1`,
      [MTFCC],
    );
    if (pre[0].n !== pre[0].ours) {
      throw new Error(
        `🔴 ${MTFCC} already holds ${pre[0].n} rows of which only ${pre[0].ours} are Harrison County's — ` +
        `somebody else took this code. Re-read max(mtfcc) and pick the next one.`,
      );
    }

    await client.query('BEGIN');
    let inserted = 0;
    let existed = 0;
    for (const f of fc.features) {
      const d = districtOf(f);
      const r = await client.query(
        // Same shape as SD-3 and MS-3: explicit casts, ST_MakeValid GATED rather than trusted.
        `WITH src AS (
           SELECT public.ST_SetSRID(public.ST_GeomFromGeoJSON($4::text), 4326) AS raw),
         fixed AS (
           SELECT raw, public.ST_MakeValid(raw) AS geom FROM src)
         INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source)
         SELECT $1::text, $2::text, $6::text, $3::text, f.geom, $5::text
         FROM fixed f
         WHERE NOT EXISTS (
           SELECT 1 FROM essentials.geofence_boundaries
            WHERE geo_id = $1::text AND mtfcc = $3::text)
           AND public.ST_GeometryType(f.geom) IN ('ST_Polygon', 'ST_MultiPolygon')
           AND abs(public.ST_Area(f.raw::geography) - public.ST_Area(f.geom::geography)) < 1.0
         RETURNING id`,
        [slug(d), `Harrison County Supervisor District ${d}`, MTFCC, JSON.stringify(f.geometry), SOURCE, STATE_FIPS],
      );
      if (r.rowCount) { inserted++; continue; }
      const { rows: chk } = await client.query(
        `SELECT count(*)::int AS n FROM essentials.geofence_boundaries
          WHERE geo_id = $1::text AND mtfcc = $2::text`,
        [slug(d), MTFCC],
      );
      if (chk[0].n > 0) existed++;
      else {
        throw new Error(
          `🔴 district ${d}: not inserted and not present — ST_MakeValid changed the area by more than 1 m2, ` +
          `or returned something other than a polygon. Refusing to write.`,
        );
      }
    }

    const { rows } = await client.query(
      `SELECT count(*)::int AS n,
              count(*) FILTER (WHERE public.ST_IsValid(geometry))::int AS valid,
              count(DISTINCT public.ST_SRID(geometry))::int AS srids,
              count(DISTINCT geo_id)::int AS distinct_geo_ids
         FROM essentials.geofence_boundaries WHERE mtfcc = $1`,
      [MTFCC],
    );
    const g = rows[0];
    if (g.n !== 5 || g.valid !== 5 || g.srids !== 1 || g.distinct_geo_ids !== 5) {
      throw new Error(
        `🔴 post-write gate: ${g.n} rows, ${g.valid} valid, ${g.srids} distinct SRIDs, ` +
        `${g.distinct_geo_ids} distinct geo_ids — expected 5/5/1/5`,
      );
    }

    // 🔴 POST-WRITE RE-CHECK IN POSTGIS, on the certified anchors — the ones that come from outside
    // the county's GIS entirely. Control 6 judged the bytes in memory; this asks the stored rows.
    for (const [precinct, want] of Object.entries(CERTIFIED_PRECINCTS)) {
      const f = byName.get(normName(precinct));
      const [lon, lat] = f.geometry.coordinates;
      const { rows: hit } = await client.query(
        `SELECT geo_id FROM essentials.geofence_boundaries
          WHERE mtfcc = $1
            AND public.ST_Contains(geometry, public.ST_SetSRID(public.ST_MakePoint($2, $3), 4326))`,
        [MTFCC, lon, lat],
      );
      if (hit.length !== 1 || hit[0].geo_id !== slug(want)) {
        throw new Error(
          `🔴 post-write certified anchor "${precinct}": PostGIS returned ` +
          `${JSON.stringify(hit.map((h) => h.geo_id))}, expected exactly ${slug(want)}`,
        );
      }
    }
    console.log(`post-write OK — all ${Object.keys(CERTIFIED_PRECINCTS).length} certified anchors re-checked in PostGIS`);

    await client.query('COMMIT');
    console.log(`\n✅ inserted ${inserted}, already existed ${existed}; ${MTFCC} now holds 5 valid polygons in one SRID.`);
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    await client.end();
  }
}

run().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
