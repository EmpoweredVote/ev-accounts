#!/usr/bin/env node
/**
 * verify-jackson-wards-against-minutes.mjs — Jackson, MS deep seed.
 *
 * ANSWERS THE QUESTION THE CROSS-PLAN CHECK CANNOT: is the ward NUMBERING right in the world, not
 * merely consistent between two of the city's own GIS layers?
 *
 * 🔴 WHY THIS EXISTS. scripts/verify-jackson-ward-numbering.mjs proves that new Ward N occupies the
 * same ground as old Ward N, 7 of 7. That rules out a permutation introduced BY THE 2024 REDRAW.
 * It cannot rule out a labelling that was already wrong in both layers — A COUNT CAN BE RIGHT AND
 * MEAN SOMETHING ELSE. Only a source outside the GIS can settle that.
 *
 * THE SOURCE. The City Council's own minutes state, for every code-enforcement case it votes on,
 * the property's street address AND its ward, in one sentence:
 *
 *   "...for Case #CE-25-619 located at 1237 Grand Ave. parcel #132-8 in Ward 5 of the City of
 *    Jackson..."
 *
 * That is an official act of the city, published as a PDF, produced by a department that is not the
 * GIS office and does not read the feature service. Each such sentence is one anchor.
 *
 * THE METHOD. Harvest (address, ward) pairs from the minutes, geocode each address with the Census
 * geocoder (keyless, and NOT the city's own service, so it cannot inherit the city's labelling),
 * and ask PostGIS which ward polygon contains the point.
 *
 * ⚠ PERFECTION IS NOT EXPECTED. A geocoder puts a point on a street centreline or a parcel
 * centroid, and a ward boundary often RUNS DOWN a street, so an address on a boundary street can
 * land either side. The signal is the overall agreement rate and, above all, that no ward is
 * SYSTEMATICALLY read as another — a permutation shows up as a block, not as scatter.
 *
 * CONTROLS:
 *   --control=shuffle  rotates the ward labels on the polygons; agreement must collapse.
 *   The geocoder is proved live by requiring a minimum match rate before any verdict is given.
 *
 *   node scripts/verify-jackson-wards-against-minutes.mjs --minutes <dir of minutes PDFs>
 */
import * as fs from 'fs';
import * as path from 'path';
import { execFileSync } from 'child_process';
import pg from 'pg';

const argv = process.argv.slice(2);
const arg = (k) => {
  const hit = argv.find((a) => a.startsWith(`--${k}=`));
  if (hit) return hit.slice(k.length + 3);
  const i = argv.indexOf(`--${k}`);
  return i >= 0 ? argv[i + 1] : undefined;
};
const DIR = arg('minutes');
const SHUFFLE = arg('control') === 'shuffle';
const LIMIT = Number(arg('limit') || 60);
if (!DIR) {
  console.error('usage: verify-jackson-wards-against-minutes.mjs --minutes <dir of minutes PDFs>');
  process.exit(2);
}

// "located at 1237 Grand Ave. parcel #132-8 in Ward 5 of the City of Jackson"
const RE = /located at\s+([0-9][^,;]{4,60}?)\s+parcel\s*#[^ ]{1,20}\s+in\s+Ward\s+(\d)\b/gi;

const pdfs = fs.readdirSync(DIR).filter((f) => f.toLowerCase().endsWith('.pdf'));
if (!pdfs.length) {
  console.error(`🔴 no PDFs in ${DIR}`);
  process.exit(1);
}

const pairs = new Map(); // address -> ward
for (const f of pdfs) {
  let text = '';
  try {
    text = execFileSync('pdftotext', ['-layout', path.join(DIR, f), '-'], { maxBuffer: 1 << 28 }).toString('utf8');
  } catch (e) {
    console.error(`  ! ${f}: pdftotext failed (${e.message.slice(0, 60)})`);
    continue;
  }
  const flat = text.replace(/\s+/g, ' ');
  let m;
  let n = 0;
  RE.lastIndex = 0;
  while ((m = RE.exec(flat))) {
    const addr = m[1].replace(/\s+/g, ' ').trim().replace(/\.$/, '');
    const ward = Number(m[2]);
    n++;
    if (!pairs.has(addr)) pairs.set(addr, ward);
    else if (pairs.get(addr) !== ward) pairs.set(addr, 0); // the city itself disagrees — drop it
  }
  console.log(`  ${f}: ${n} ward statements`);
}

const anchors = [...pairs.entries()].filter(([, w]) => w >= 1 && w <= 7).slice(0, LIMIT);
console.log(`\nharvested ${pairs.size} distinct addresses; using ${anchors.length}`);
if (anchors.length < 10) {
  console.error('🔴 fewer than 10 anchors — this is a blind detector, not a clean result');
  process.exit(1);
}

async function geocode(addr) {
  const u =
    'https://geocoding.geo.census.gov/geocoder/locations/onelineaddress?address=' +
    encodeURIComponent(`${addr}, Jackson, MS`) +
    '&benchmark=Public_AR_Current&format=json';
  const r = await fetch(u);
  const t = await r.text();
  let j;
  try { j = JSON.parse(t); } catch { return null; }
  const m = j.result && j.result.addressMatches && j.result.addressMatches[0];
  return m ? { lon: m.coordinates.x, lat: m.coordinates.y } : null;
}

const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
await client.connect();

// Build the ward lookup. Under --control=shuffle the labels are rotated, which is the Harrison
// County DIST_ID defect: a clean permutation of exactly the right seven values.
const { rows: wardRows } = await client.query(
  `SELECT geo_id FROM essentials.geofence_boundaries WHERE mtfcc='X0085' ORDER BY geo_id`,
);
const order = wardRows.map((r) => Number(r.geo_id.replace(/\D+/g, '')));
const relabel = new Map(order.map((w, i) => [w, SHUFFLE ? order[(i + 1) % order.length] : w]));
if (SHUFFLE) console.log(`🔬 CONTROL shuffle: labels rotated -> ${[...relabel.values()].join(',')}`);

const tally = {};
let matched = 0;
let unmatched = 0;
let outside = 0;
for (const [addr, want] of anchors) {
  const pt = await geocode(addr);
  if (!pt) { unmatched++; continue; }
  matched++;
  const { rows } = await client.query(
    `SELECT geo_id FROM essentials.geofence_boundaries
      WHERE mtfcc='X0085'
        AND public.ST_Contains(geometry, public.ST_SetSRID(public.ST_MakePoint($1,$2),4326))`,
    [pt.lon, pt.lat],
  );
  if (!rows.length) { outside++; continue; }
  const got = relabel.get(Number(rows[0].geo_id.replace(/\D+/g, '')));
  if (!tally[want]) tally[want] = {};
  tally[want][got] = (tally[want][got] || 0) + 1;
}
await client.end();

// 🔴 THE GEOCODER MUST BE PROVED LIVE. If almost nothing matched, a high agreement rate on the
// remainder means nothing.
console.log(`\ngeocoded ${matched}/${anchors.length}; ${unmatched} no match; ${outside} outside every ward`);
if (matched < 10) {
  console.error('🔴 the geocoder matched fewer than 10 addresses — detector blind, no verdict');
  process.exit(1);
}

console.log('\n            ward the polygon says');
console.log('minutes   ' + Array.from({ length: 7 }, (_, i) => String(i + 1).padStart(5)).join(''));
let agree = 0;
let total = 0;
for (let w = 1; w <= 7; w++) {
  const row = tally[w] || {};
  const sum = Object.values(row).reduce((a, b) => a + b, 0);
  const hit = row[w] || 0;
  agree += hit;
  total += sum;
  const cells = Array.from({ length: 7 }, (_, i) => String(row[i + 1] || 0).padStart(5)).join('');
  const best = Object.entries(row).sort((a, b) => b[1] - a[1])[0];
  const flag = sum && best && Number(best[0]) !== w ? `  🔴 reads as Ward ${best[0]}` : '';
  console.log(`Ward ${w}   ${cells}   ${sum ? `${((hit / sum) * 100).toFixed(0)}%` : '  —'}${flag}`);
}
console.log(`\nAGREEMENT: ${agree}/${total} = ${total ? ((agree / total) * 100).toFixed(1) : 'n/a'}%`);
console.log(
  SHUFFLE
    ? '🔬 SHUFFLE control — a high number here would mean the test cannot discriminate.'
    : 'A permutation would show as a BLOCK off the diagonal, not as scatter along it.',
);
