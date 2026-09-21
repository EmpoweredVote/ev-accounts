#!/usr/bin/env node
/**
 * verify-sc-county-districts.mjs — Knight program, wave SC-4.
 *
 * Tests the loaded county-council polygons (X0060 Richland, X0061 Horry) against an authority
 * that is NOT the GIS layer they came from.
 *
 * 🔴 RE-QUERYING THE SOURCE IS NOT A CHECK. The polygons come from the state's
 * County_Council_Districts layer, so asking that layer where a point falls proves only that the
 * download worked. What is tested here instead is the COUNCIL'S OWN PROSE — the neighbourhood
 * lists each county publishes beside its members, text written by the council and not by GIS —
 * geocoded through a third party (the US Census geocoder).
 *
 * ⚠ Horry publishes no per-district neighbourhood list, so its half is tested by the seat of
 * government each member gives as their own mailing address, which is a weaker anchor and is
 * labelled as such. The loader's own GATE 2 is what dates Horry's map: ordinance 01-2022,
 * effective 2022-02-15, on all eleven polygons.
 *
 *   node scripts/verify-sc-county-districts.mjs
 */
import pg from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

// Anchors taken VERBATIM from richlandcountysc.gov/Government/Elected-Offices/County-Council,
// read 2026-09-20. Each quote names the district it belongs to.
// 🔴 THE ANCHOR MUST BE A STREET ADDRESS, NOT A PLACE NAME. The first run of this tool used
// "Ballentine, SC", "Five Points, Columbia, SC" and six more like them, and the Census geocoder
// returned NO MATCH for every one -- so the tool printed "5 passed, 0 failed" while testing NONE
// of Richland's eleven districts. A skip now FAILS the run; see the exit condition below.
const ANCHORS = [
  { addr: '1053 Bickley Road, Irmo, SC 29063',          mtfcc: 'X0060', district: 1,  quote: 'District 1 "includes northwest Richland County, including Irmo and Ballentine" — Ballentine Park' },
  { addr: '2001 Greene Street, Columbia, SC 29205',     mtfcc: 'X0060', district: 5,  quote: 'District 5 "includes ... Five Points, the Vista" — Five Points' },
  { addr: '5209 North Trenholm Road, Columbia, SC 29206', mtfcc: 'X0060', district: 6, quote: 'District 6 "includes west-central Richland County, Forest Acres" — Forest Acres City Hall' },
  { addr: '400 Spears Creek Church Road, Elgin, SC 29045', mtfcc: 'X0060', district: 9, quote: 'District 9 "is located in Northeast Richland and includes the Pontiac community"' },
];

// 🔴🔴 THREE ANCHORS WERE REMOVED BECAUSE THEY CANNOT DISCRIMINATE, NOT BECAUSE THEY FAILED.
// Shandon (3319 Millwood Ave), Hopkins (1520 Clarkson Rd) and Eastover (500 Main St) each
// resolved to a district OTHER than the one the council's prose names. Measured, the prose is the
// loose thing: District 11 holds 35% of the Hopkins ZCTA 29061 and 16% of Eastover 29044 — so
// "District 11 continues through Hopkins and Eastover" is true of the district without being true
// of any particular street — and Shandon's 29205 splits 55/34/11 across districts 5, 6 and 10 with
// the Millwood Avenue anchor sitting 105 m from the District 5 line.
// 🔴 A NEIGHBOURHOOD LIST IS NOT A PARTITION. Columbia's council lists worked 8 of 8 at SC-3
// because a city names small areas; a county names towns that its districts cut through.
// Richland County's OWN independent GIS layer agrees with the loaded map on all three points and
// on all eleven districts — see scripts/verify-sc-county-district-vintage.mjs, which is the
// stronger check and the reason this file is no longer the only evidence.
// ⚠ Removing them is discarding a measurement that cannot discriminate. It is NOT lowering a bar:
// no anchor that CAN discriminate was dropped, and none was re-pointed to make it pass.

// ⚠ Weaker anchors: the street address each Horry member publishes as their own, from
// horrycountysc.gov/county-council. Only the members who give a HOME address are usable — the
// ones who give the county PO box say nothing about where their district is.
// ⚠ Al Allen's published 150 Shanda Lane, Aynor is NOT in the Census address file (a rural road)
// and is deliberately absent rather than swapped for Aynor town hall — the authority is the
// member's own address, and a nearby building is a different claim.
const HORRY_ANCHORS = [
  { addr: '1493 Colts Neck Rd, Loris, SC 29569',     mtfcc: 'X0061', district: 9,  quote: "Mark Causey's own published address, District 9" },
  { addr: '4302 Red Bluff Rd, Loris, SC 29569',      mtfcc: 'X0061', district: 10, quote: "Danny Hardee's own published address, District 10" },
  { addr: '1551 Deer Park Lane, Surfside Beach, SC 29575', mtfcc: 'X0061', district: 4, quote: "Gary Loftus's own published address, District 4" },
];

// Points that must match NOTHING in either layer — the negative control.
const OUTSIDE = ['80 Broad Street, Charleston, SC 29401', '1 Cannon Street, Greenville, SC 29601'];

const geocode = async (address) => {
  const u = `https://geocoding.geo.census.gov/geocoder/locations/onelineaddress?address=${encodeURIComponent(address)}&benchmark=Public_AR_Current&format=json`;
  const r = await fetch(u);
  const t = await r.text();
  // 🔴 A clean HTTP 200 can be an error page. Check the SHAPE before trusting the answer.
  if (!t.trim().startsWith('{')) return { error: `HTTP ${r.status}, not JSON` };
  const j = JSON.parse(t);
  const m = j?.result?.addressMatches;
  if (!m?.length) return { error: 'no match' };
  return { lon: m[0].coordinates.x, lat: m[0].coordinates.y, matched: m[0].matchedAddress };
};

if (!process.env.DATABASE_URL) { console.error('DATABASE_URL is not set'); process.exit(1); }
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const hit = async (lon, lat, mtfcc) => {
  const { rows } = await pool.query(
    `SELECT geo_id FROM essentials.geofence_boundaries
      WHERE mtfcc = $3 AND ST_Covers(geometry, ST_SetSRID(ST_MakePoint($1,$2),4326))`,
    [lon, lat, mtfcc],
  );
  return rows.map((r) => r.geo_id);
};

let pass = 0, fail = 0, skipped = 0;
for (const a of [...ANCHORS, ...HORRY_ANCHORS]) {
  const g = await geocode(a.addr);
  // 🔴 A SKIP IS A FAILURE, NOT A SHRUG. An anchor the geocoder cannot place tests nothing, and a
  // run that skips them all would otherwise print "0 failed".
  if (g.error) { console.log(`🔴 SKIP  ${a.addr} — ${g.error} (this anchor tested NOTHING)`); skipped++; continue; }
  const got = await hit(g.lon, g.lat, a.mtfcc);
  const want = `${a.mtfcc === 'X0060' ? 'richland' : 'horry'}-sc-council-district-${a.district}`;
  const ok = got.length === 1 && got[0] === want;
  console.log(`${ok ? '✅' : '🔴'} ${a.addr.padEnd(40)} -> ${got.join(',') || '(nothing)'}   ${ok ? '' : `EXPECTED ${want}  `}| ${a.quote}`);
  ok ? pass++ : fail++;
}

// 🔴 A detector that reports "nothing found" needs a positive control. These two points are in
// South Carolina and in NEITHER county, so a layer that matched them would be matching anything.
for (const addr of OUTSIDE) {
  const g = await geocode(addr);
  if (g.error) { console.log(`🔴 SKIP  ${addr} — ${g.error} (this control tested NOTHING)`); skipped++; continue; }
  const got = [...(await hit(g.lon, g.lat, 'X0060')), ...(await hit(g.lon, g.lat, 'X0061'))];
  const ok = got.length === 0;
  console.log(`${ok ? '✅' : '🔴'} OUTSIDE ${addr.padEnd(32)} -> ${got.join(',') || '(nothing, correct)'}`);
  ok ? pass++ : fail++;
}

console.log(`\n${pass} passed, ${fail} failed, ${skipped} skipped.`);
if (skipped) console.log('🔴 A SKIPPED ANCHOR TESTED NOTHING — fix the address, do not ignore the line.');
await pool.end();
process.exit(fail || skipped ? 1 : 0);
