// Post-load verification: do REAL Reno / Washoe addresses resolve to the right seats?
// Addresses are geocoded by the Census geocoder, never typed in as coordinates.
import pg from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

const UA = { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/131.0' };

const ADDRESSES = [
  // Reno City Hall — must be in Reno, in exactly one ward, and in Washoe County.
  { label: 'Reno City Hall', q: '1 E 1st St, Reno, NV 89501', expectReno: true },
  // Washoe County Administration Complex — in Reno, so also in a ward.
  { label: 'Washoe County Admin', q: '1001 E 9th St, Reno, NV 89512', expectReno: true },
  // NW Reno — the Washoe County Northwest Reno Library, a real public building, chosen so the
  // probe is an address that exists rather than one typed to look plausible.
  { label: 'NW Reno Library', q: '2325 Robb Dr, Reno, NV 89523', expectReno: true },
  // 🔴 A "RENO, NV" MAILING ADDRESS IS NOT THE CITY OF RENO. The South Valleys Library posts as
  // "Reno, NV 89511" but stands in UNINCORPORATED Washoe County, outside the city limits. It is
  // kept as a control precisely because it looks like a Reno address: it must return a county
  // commissioner and NO ward. Anything that infers city membership from the postal city — a
  // coverage claim, a browse list, a banner key — gets this wrong.
  { label: 'South Valleys Library (Reno mail, NOT in the city)', q: '15650A Wedge Pkwy, Reno, NV 89511', expectReno: false },
  // NEGATIVE CONTROLS — inside Washoe County but NOT inside the City of Reno.
  // Sparks is a separate incorporated city; Incline Village is unincorporated Tahoe.
  { label: 'Sparks City Hall (NOT Reno)', q: '431 Prater Way, Sparks, NV 89431', expectReno: false },
  { label: 'Incline Village (NOT Reno)', q: '865 Tahoe Blvd, Incline Village, NV 89451', expectReno: false },
];

const geocode = async (q) => {
  const url =
    'https://geocoding.geo.census.gov/geocoder/locations/onelineaddress' +
    `?address=${encodeURIComponent(q)}&benchmark=Public_AR_Current&format=json`;
  const j = JSON.parse(await (await fetch(url, { headers: UA })).text());
  const m = j?.result?.addressMatches?.[0];
  return m ? { lon: m.coordinates.x, lat: m.coordinates.y, matched: m.matchedAddress } : null;
};

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, max: 2 });
const q = async (s, p = []) => (await pool.query(s, p)).rows;

let failures = 0;
for (const a of ADDRESSES) {
  const g = await geocode(a.q);
  if (!g) {
    console.log(`❌ ${a.label}: the Census geocoder did not match "${a.q}" — cannot verify`);
    failures++;
    continue;
  }
  const [r] = await q(
    `WITH pt AS (SELECT ST_SetSRID(ST_MakePoint($1,$2),4326) g)
     SELECT (SELECT string_agg(b.name,', ') FROM essentials.geofence_boundaries b, pt
              WHERE b.mtfcc='X0086' AND ST_Contains(b.geometry, pt.g))              AS ward,
            (SELECT string_agg(b.name,', ') FROM essentials.geofence_boundaries b, pt
              WHERE b.mtfcc='X0087' AND ST_Contains(b.geometry, pt.g))              AS commission,
            (SELECT count(*) FROM essentials.geofence_boundaries b, pt
              WHERE b.geo_id='3260600' AND b.mtfcc='G4110' AND ST_Contains(b.geometry, pt.g))::int AS in_reno,
            (SELECT count(*) FROM essentials.geofence_boundaries b, pt
              WHERE b.geo_id='32031' AND b.mtfcc='G4020' AND ST_Contains(b.geometry, pt.g))::int AS in_washoe`,
    [g.lon, g.lat],
  );

  // What a voter would actually be shown: the offices hanging on those districts.
  const seats = await q(
    `WITH pt AS (SELECT ST_SetSRID(ST_MakePoint($1,$2),4326) g)
     SELECT gov.name AS government, o.title
       FROM essentials.geofence_boundaries b
       CROSS JOIN pt
       JOIN essentials.districts d ON d.geo_id=b.geo_id AND d.mtfcc=b.mtfcc
       JOIN essentials.offices o ON o.district_id=d.id
       JOIN essentials.chambers c ON c.id=o.chamber_id
       JOIN essentials.governments gov ON gov.id=c.government_id
      WHERE b.mtfcc IN ('X0086','X0087')
        AND ST_Contains(b.geometry, pt.g)
      ORDER BY gov.name, o.title`,
    [g.lon, g.lat],
  );

  const ok =
    (a.expectReno ? r.in_reno === 1 && r.ward !== null : r.in_reno === 0 && r.ward === null) &&
    r.in_washoe === 1 &&
    r.commission !== null;

  console.log(`${ok ? '✅' : '❌'} ${a.label}`);
  console.log(`     ${g.matched}`);
  console.log(`     in Reno: ${r.in_reno}   in Washoe: ${r.in_washoe}`);
  console.log(`     ward: ${r.ward ?? '(none)'}`);
  console.log(`     commission: ${r.commission ?? '(none)'}`);
  console.log(`     seats a voter here would see: ${seats.length ? seats.map((s) => s.title).join(' · ') : '(none)'}`);
  if (!ok) failures++;
}

console.log(failures === 0 ? '\nALL ROUTING CHECKS PASSED' : `\n${failures} ROUTING CHECK(S) FAILED`);
await pool.end();
process.exit(failures === 0 ? 0 : 1);
