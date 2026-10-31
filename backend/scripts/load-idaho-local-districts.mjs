/**
 * Loads the two Idaho local district layers that have no TIGER equivalent:
 *
 *   essentials.geofence_boundaries  geo_id='boise-id-council-district-1'..'-6',              mtfcc='X0083'
 *   essentials.geofence_boundaries  geo_id='ada-county-id-commissioner-district-1'..'-3',    mtfcc='X0084'
 *
 * Source GeoJSON is read from the wave directories, where it was pulled with outSR=4326 and is
 * kept as the evidence:
 *   backend/data/seed-boise-2026/boise_council_districts_LIVE.geojson
 *   backend/data/seed-ada-county-2026/ada_commissioner_districts.geojson
 *
 * ═══ 🔴 BOISE PUBLISHES TWO COUNCIL-DISTRICT LAYERS AND THE WRONG ONE IS EASIER TO FIND ═══
 *
 * An ArcGIS Hub search for "Boise city council district" returns `Boise_City_Council_Districts_2021`
 * FIRST. That is Boise's FIRST districting plan, used only for the 2021 election; the city redrew on
 * 2020 census data for 2023. The operative layer is `BoiseCityCouncilDistricts`, with no year suffix.
 *
 * 🔴 THE TWO CANNOT BE TOLD APART BY ANY CHEAP CHECK. Both have exactly 6 districts numbered 1..6.
 *    Their geodesic areas are 225.8 km² and 227.4 km² — both match Boise's ~87 sq mi. Both correctly
 *    exclude Garden City, Meridian and Eagle. Boise City Hall, Boise State and the airport resolve
 *    IDENTICALLY under both.
 *    They disagree about where people live: the North End moves 3→6, Bown Crossing 4→5 and
 *    Collister 3→6.
 *
 * ▶ The operative layer was established from the city rather than from a search: the
 *   `council-districts` page embeds Zone Lookup app `d9a911286a8641d589ab3336adff74e6`, whose web
 *   map `a70d79865ad64d6697e437c3f80f4304` has exactly one operational layer — this one. It also
 *   carries a `CouncilMember` attribute the city keeps current; the `_2021` layer carries no names.
 *
 * GATE 5 below re-reads that `CouncilMember` attribute and fails if it has moved. A changed name
 * means a seat turned over, and this script must not quietly load a new map under an old roster.
 * 🔴 It is a DETECTOR, not the occupancy source. Occupancy is CC_0312's and CC_0313's.
 *
 * Usage:
 *   node scripts/load-idaho-local-districts.mjs --dry-run
 *   node scripts/load-idaho-local-districts.mjs
 */
import fs from 'node:fs';
import path from 'node:path';
import pg from 'pg';

const ARGV = process.argv.slice(2);
const DRY = ARGV.includes('--dry-run');
const STATE_FIPS = '16';
const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1')), '..');

const LAYERS = [
  {
    key: 'boise',
    mtfcc: 'X0083',
    expected: 6,
    file: 'data/seed-boise-2026/boise_council_districts_LIVE.geojson',
    numField: 'DistrictID',
    nameField: 'CouncilMember',
    slug: (n) => `boise-id-council-district-${n}`,
    label: (n) => `Boise City Council District ${n}`,
    source:
      'City of Boise GIS, services1.arcgis.com/WHM6qC35aMtyAAlN BoiseCityCouncilDistricts/FeatureServer/0 ' +
      '— the layer behind the city’s own published Zone Lookup app, i.e. the OPERATIVE districting ' +
      'map (the 2023 redraw on 2020 census data), not the superseded Boise_City_Council_Districts_2021 ' +
      'layer that an ArcGIS Hub search returns first. Retrieved 2026-10-30 by ' +
      'scripts/load-idaho-local-districts.mjs (CC_0312).',
    // Expected holder per district, read from the layer on 2026-10-30 and checked against the
    // city’s six per-district pages and Ballotpedia.
    members: {
      1: 'Luci Willits',
      2: 'Colin Nash',
      3: 'Kathy Corless',
      4: 'Jordan Morales',
      5: 'Meredith Stead',
      6: 'Jimmy Hallyburton',
    },
    // The last entry is the negative control: a separate incorporated city enclaved by Boise.
    probes: [
      { name: 'Boise City Hall', lon: -116.2019, lat: 43.6154, expect: 5 },
      { name: 'Boise State University', lon: -116.2006, lat: 43.6032, expect: 5 },
      { name: 'Boise Airport', lon: -116.2228, lat: 43.5644, expect: 4 },
      { name: 'Garden City Hall (separate city)', lon: -116.2798, lat: 43.6594, expect: null },
      { name: 'Meridian City Hall (separate city)', lon: -116.3929, lat: 43.6101, expect: null },
    ],
  },
  {
    key: 'ada',
    mtfcc: 'X0084',
    expected: 3,
    file: 'data/seed-ada-county-2026/ada_commissioner_districts.geojson',
    numField: 'district',
    nameField: 'commissioner',
    slug: (n) => `ada-county-id-commissioner-district-${n}`,
    label: (n) => `Ada County Commissioner District ${n}`,
    source:
      'Ada County GIS, services2.arcgis.com/dgGjZc6xAH5m5JyP Commissioner_District/FeatureServer/0. ' +
      'Retrieved 2026-10-30 by scripts/load-idaho-local-districts.mjs (CC_0313).',
    members: { 1: 'Ryan Davidson', 2: 'Rod Beck', 3: 'Tom Dayley' },
    probes: [
      { name: 'Boise City Hall', lon: -116.2019, lat: 43.6154, expect: null, anyOf: [1, 2, 3] },
      { name: 'Meridian City Hall', lon: -116.3929, lat: 43.6101, expect: null, anyOf: [1, 2, 3] },
      { name: 'Caldwell City Hall (Canyon County)', lon: -116.6929, lat: 43.6677, expect: null },
    ],
  },
];

const fail = (msg) => {
  console.error(`\n❌ ${msg}\n`);
  process.exit(1);
};

// ── Point-in-polygon, used for the probe gates before anything is written ────
const ringHas = (x, y, r) => {
  let inside = false;
  for (let i = 0, j = r.length - 1; i < r.length; j = i++) {
    const [xi, yi] = r[i];
    const [xj, yj] = r[j];
    if ((yi > y) !== (yj > y) && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) inside = !inside;
  }
  return inside;
};
const polyHas = (x, y, p) => {
  if (!ringHas(x, y, p[0])) return false;
  for (let k = 1; k < p.length; k++) if (ringHas(x, y, p[k])) return false;
  return true;
};
const covers = (x, y, g) =>
  g.type === 'Polygon' ? polyHas(x, y, g.coordinates) : g.coordinates.some((p) => polyHas(x, y, p));

const prepared = [];

for (const L of LAYERS) {
  const abs = path.join(ROOT, L.file);
  if (!fs.existsSync(abs)) fail(`${L.key}: source GeoJSON missing at ${abs}`);
  const fc = JSON.parse(fs.readFileSync(abs, 'utf8'));
  if (fc.type !== 'FeatureCollection') fail(`${L.key}: ${L.file} is not a FeatureCollection`);

  // GATE 1 — exact feature count.
  if (fc.features.length !== L.expected) {
    fail(`${L.key}: expected ${L.expected} features, found ${fc.features.length}`);
  }

  // GATE 2 — district numbers are exactly 1..expected, each with geometry.
  const byNum = new Map();
  for (const f of fc.features) {
    const raw = f.properties?.[L.numField];
    const n = Number(raw);
    if (!Number.isInteger(n) || n < 1 || n > L.expected) {
      fail(`${L.key}: feature carries ${L.numField}=${JSON.stringify(raw)}, outside 1..${L.expected}`);
    }
    if (byNum.has(n)) fail(`${L.key}: district ${n} appears twice`);
    if (!f.geometry) fail(`${L.key}: district ${n} has no geometry`);
    byNum.set(n, f);
  }
  for (let n = 1; n <= L.expected; n++) if (!byNum.has(n)) fail(`${L.key}: district ${n} is missing`);

  // GATE 3 — CRS is WGS84. outSR=4326 is load-bearing on every ArcGIS fetch in this repo.
  const crs = fc.crs?.properties?.name ?? '';
  if (!/4326|CRS84/i.test(crs)) fail(`${L.key}: CRS is ${JSON.stringify(crs)}, expected EPSG:4326`);

  // GATE 4 — probes. Each point must land in exactly the expected district, and a point that
  // should land NOWHERE must land nowhere. The negative control is what distinguishes
  // "the test ran and passed" from "the test matched everything".
  for (const p of L.probes) {
    const hits = [...byNum.entries()].filter(([, f]) => covers(p.lon, p.lat, f.geometry)).map(([n]) => n);
    if (p.anyOf) {
      if (hits.length !== 1 || !p.anyOf.includes(hits[0])) {
        fail(`${L.key}: probe "${p.name}" matched ${JSON.stringify(hits)}, expected exactly one of ${JSON.stringify(p.anyOf)}`);
      }
    } else if (p.expect === null) {
      if (hits.length !== 0) fail(`${L.key}: NEGATIVE CONTROL "${p.name}" matched ${JSON.stringify(hits)} — expected none`);
    } else if (hits.length !== 1 || hits[0] !== p.expect) {
      fail(`${L.key}: probe "${p.name}" matched ${JSON.stringify(hits)}, expected exactly [${p.expect}]`);
    }
  }

  // GATE 5 — the layer's own officeholder attribute must still read as the roster expects.
  // A changed name means a seat turned over; this script must not load a new map under an old
  // roster, nor an old map under a new one.
  for (const [n, f] of byNum) {
    const got = String(f.properties?.[L.nameField] ?? '').trim();
    const want = L.members[n];
    if (got && got !== want) {
      fail(`${L.key}: district ${n} names "${got}" but the verified roster says "${want}" — a seat has turned over, or this is the wrong layer. Re-read ROSTERS.md before loading.`);
    }
  }

  for (const [n, f] of byNum) {
    prepared.push({ mtfcc: L.mtfcc, geo_id: L.slug(n), name: L.label(n), source: L.source, geom: f.geometry });
  }
  console.log(`  ${L.key}: ${L.expected} districts, all gates passed (${L.probes.length} probes, ${L.probes.filter((p) => p.expect === null && !p.anyOf).length} negative control(s)).`);
}

if (DRY) {
  console.table(prepared.map((r) => ({ mtfcc: r.mtfcc, geo_id: r.geo_id, name: r.name, geom: r.geom.type })));
  console.log('\n--dry-run: nothing written.');
  process.exit(0);
}

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const { rows } = await pool.query(
  `WITH d AS (
     SELECT x.geo_id, x.name, x.mtfcc, x.source,
            ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(x.geom), 4326)), 3)) AS geom
       FROM jsonb_to_recordset($1::jsonb)
            AS x(geo_id text, name text, mtfcc text, source text, geom jsonb)),
   ins AS (
     INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source, imported_at)
     SELECT d.geo_id, d.name, $2, d.mtfcc, d.geom, d.source, now() FROM d
     ON CONFLICT (geo_id, mtfcc) DO NOTHING
     RETURNING 1)
   SELECT count(*)::int AS written FROM ins`,
  [JSON.stringify(prepared), STATE_FIPS],
);
console.log(`\n✅ wrote ${rows[0].written} polygon(s) (X0083 Boise council, X0084 Ada County commissioner)`);
await pool.end();
