#!/usr/bin/env node
/**
 * verify-marin-corte-madera-routing.mjs — prove CC_0392/CC_0393 on PRODUCTION with real
 * addresses, not row counts. A roster can be complete and every district polygon present while
 * no actual address reaches the right official.
 *
 *   node scripts/verify-marin-corte-madera-routing.mjs
 *
 * Addresses are geocoded by the Census (geocoding.geo.census.gov, no API key — api.census.gov
 * now requires one, this host does not), then matched against what is actually in
 * geofence_boundaries, and the holder is read through essentials.office_current_holder — the
 * view the app reads — rather than off office_terms.
 *
 * 🔑 TWO DELIBERATE CONTROLS:
 *   - Mill Valley City Hall is at 26 CORTE MADERA AVENUE, in Mill Valley, NOT in the Town of
 *     Corte Madera. Anything matching on a street or postal name seats the wrong council.
 *   - Point Reyes Station and Novato are outside Corte Madera entirely: they must return a
 *     supervisor and NO council member.
 */
import pg from 'pg';

const CASES = [
  { label: 'Corte Madera Town Hall',   address: '300 Tamalpais Drive, Corte Madera, CA 94925',  expectTown: true },
  { label: 'Marin County Civic Center', address: '3501 Civic Center Drive, San Rafael, CA 94903', expectTown: false },
  { label: 'Novato City Hall',         address: '901 Sherman Avenue, Novato, CA 94945',          expectTown: false },
  { label: 'Mill Valley City Hall',    address: '26 Corte Madera Avenue, Mill Valley, CA 94941', expectTown: false },
  { label: 'Point Reyes Station PO',   address: '11260 State Route 1, Point Reyes Station, CA 94956', expectTown: false },
];

async function geocode(address) {
  const url =
    'https://geocoding.geo.census.gov/geocoder/locations/onelineaddress?benchmark=Public_AR_Current' +
    `&format=json&address=${encodeURIComponent(address)}`;
  const res = await fetch(url, { signal: AbortSignal.timeout(30_000) });
  if (!res.ok) throw new Error(`census geocoder HTTP ${res.status}`);
  const j = await res.json();
  const m = j?.result?.addressMatches?.[0];
  if (!m) return null;
  return { lon: Number(m.coordinates.x), lat: Number(m.coordinates.y), matched: m.matchedAddress };
}

const c = new pg.Client({ connectionString: process.env.DATABASE_URL });
await c.connect();
await c.query("SET statement_timeout = '300s'");

let failures = 0;
for (const t of CASES) {
  const g = await geocode(t.address);
  if (!g) {
    console.log(`\n${t.label}\n  ❌ the Census geocoder did not match "${t.address}" — not a routing failure, a geocode failure`);
    failures += 1;
    continue;
  }

  const { rows } = await c.query(
    `WITH pt AS (SELECT ST_SetSRID(ST_MakePoint($1::float8, $2::float8), 4326) AS g)
     SELECT b.geo_id, b.mtfcc, b.name AS boundary,
            o.title, p.full_name
       FROM essentials.geofence_boundaries b
       CROSS JOIN pt
       LEFT JOIN essentials.districts d ON d.geo_id = b.geo_id AND d.mtfcc = b.mtfcc
       LEFT JOIN essentials.offices o ON o.district_id = d.id
       LEFT JOIN essentials.office_current_holder h ON h.office_id = o.id
       LEFT JOIN essentials.politicians p ON p.id = h.politician_id
      WHERE b.mtfcc IN ('X0088', 'G4110')
        AND (b.mtfcc = 'X0088' OR b.geo_id = '0616462')
        AND ST_Contains(b.geometry, pt.g)
      ORDER BY b.mtfcc, o.title, p.full_name`,
    [g.lon, g.lat],
  );

  const supervisor = rows.find((r) => r.mtfcc === 'X0088' && r.full_name);
  const council = rows.filter((r) => r.mtfcc === 'G4110' && r.full_name);
  const inTown = rows.some((r) => r.geo_id === '0616462');

  console.log(`\n${t.label}  (${g.matched})`);
  console.log(`  supervisor : ${supervisor ? `${supervisor.full_name} — ${supervisor.title}` : 'NONE'}`);
  console.log(`  council    : ${council.length ? `${council.length} member(s): ${council.map((r) => r.full_name).join(', ')}` : 'none'}`);

  if (!supervisor) {
    console.log('  ❌ every Marin address must reach exactly one supervisor');
    failures += 1;
  }
  if (inTown !== t.expectTown) {
    console.log(`  ❌ expected ${t.expectTown ? 'INSIDE' : 'OUTSIDE'} the Town of Corte Madera, got the opposite`);
    failures += 1;
  }
  if (t.expectTown && council.length !== 5) {
    console.log(`  ❌ expected all 5 at-large councilmembers, got ${council.length}`);
    failures += 1;
  }
  if (!t.expectTown && council.length !== 0) {
    console.log(`  ❌ expected NO councilmember outside the town, got ${council.length}`);
    failures += 1;
  }
}

console.log(failures === 0 ? '\n✅ routing verified on production.' : `\n❌ ${failures} routing failure(s).`);
await c.end();
process.exit(failures === 0 ? 0 : 1);
