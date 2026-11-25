#!/usr/bin/env -S npx tsx
/**
 * load-indiana-city-council-boundaries.ts
 *
 * Loads city council district boundaries for a WAVE of Indiana cities from one config file, into:
 *
 *   essentials.geofence_boundaries   mtfcc='X0091', state='in',
 *                                    geo_id='<slug>-council-district-<n>'  (e.g. evansville-in-council-district-3)
 *
 * Writes ONLY to essentials.geofence_boundaries. The wave's structure migration creates the districts
 * and offices, and refuses to run if these boundaries are absent.
 *
 * WHY ONE X-CODE FOR MANY CITIES
 *   There is no central X-code registry; each loader takes the next free code. X0090 was the highest in
 *   production on 2026-11-24 and X0091 appeared on no branch. This loader reads ONE config, so it takes ONE
 *   code: X0091 = "Indiana city council districts (municipal waves)". The geo_id carries the city slug, so
 *   (geo_id, mtfcc) cannot collide across cities. LOCAL districts route through the X% catch-all, so no
 *   line in districtQueries.ts / geoIdGuard.ts is needed (backend/src/CLAUDE.md).
 *
 * CONFIG (data/seed-in-cities-wave-a/council-maps.json): an array of
 *   { slug, name, geoid, url, where?, district_field, expected, key_map?, source_note,
 *     max_uncovered_pct?, max_outside_pct?, bound_reason? }
 *   url          the ArcGIS layer (…/FeatureServer/N or …/MapServer/N). outSR=4326 is forced.
 *   key_map      optional { "<raw field value>": <district number> } when the field is not a plain number.
 *   keys         optional list of district numbers when a city does not number 1..N (Jasper: 2-6).
 *   key_regex    optional regex whose group 1 is the district number, for PRECINCT layers whose precinct
 *                name carries the council district (Hammond 'H3 07', Kokomo '305', Anderson 'ANDERSON 2-4').
 *                Every feature must match it or GATE 1 fails; precincts are dissolved by the key.
 *
 * GATES, per city, all printed for every row (not only failures):
 *   1  feature count == expected, and keys are exactly 1..expected, one feature per key (multi-part
 *      features for one key are dissolved, and that is printed).
 *   2  every geometry is a valid MultiPolygon after ST_MakeValid, and every district is at least 1% of the
 *      city's TIGER place polygon (a sliver is a wrong layer or a wrong projection).
 *   3  no pair of districts overlaps by more than 0.01 sq mi.
 *   CLIP: every district is intersected with the city's TIGER place polygon before writing (see the comment there).
 *   4  coverage against the TIGER place polygon is BOUNDED, not closed: city limits move faster than TIGER,
 *      so a few percent either way is normal. Defaults: uncovered <= 3% of the place, outside <= 3%. A city
 *      that needs a wider bound carries it in the config WITH a bound_reason.
 *   ⚠ None of these gates can tell a superseded map from the current one: two complete partitions of a
 *     city have the same union (CLAUDE.md, "A UNION OR COVERAGE GATE CANNOT SEE WHICH VERSION OF A MAP IT
 *     HAS"). Vintage is a per-city fact recorded in source_note from the layer's own metadata or the
 *     redistricting ordinance, and checked by hand.
 *
 * CONTROLS (watch each go red before trusting a green):
 *   --tamper=drop    drop one feature from the first city      -> GATE 1 must fail
 *   --tamper=shift   move one district of the first city 0.03° east -> GATE 3 or 4 must fail
 *
 * Usage:
 *   npx tsx scripts/load-indiana-city-council-boundaries.ts [--only slug,slug] [--tamper=drop|shift]   # dry run
 *   npx tsx scripts/load-indiana-city-council-boundaries.ts --commit [--only slug,slug]
 *   --config=data/seed-in-cities-wave-b/council-maps.json   use another wave's config
 */
import 'dotenv/config';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Pool } from 'pg';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const CONFIG_ARG = process.argv.slice(2).find((a) => a.startsWith('--config='))?.split('=')[1];
// Each wave keeps its own config; --config=<path relative to backend/> picks one (default: Wave A's).
const CONFIG = CONFIG_ARG ? path.resolve(__dirname, '..', CONFIG_ARG) : path.resolve(__dirname, '../data/seed-in-cities-wave-a/council-maps.json');
const MTFCC = 'X0091';
const STATE_CODE = 'in';
const SQM_PER_SQMI = 2589988.110336;
const MAX_PAIR_OVERLAP_SQ_MI = 0.01;
const MIN_DISTRICT_SHARE = 0.01;

const args = process.argv.slice(2);
const COMMIT = args.includes('--commit');
const ONLY = (args.find((a) => a.startsWith('--only='))?.split('=')[1] ?? args[args.indexOf('--only') + 1] ?? '')
  .split(',').filter((s) => s && !s.startsWith('--'));
const TAMPER = args.find((a) => a.startsWith('--tamper='))?.split('=')[1] ?? null;
if (COMMIT && TAMPER) { console.error('refusing --commit with --tamper'); process.exit(2); }

interface CityMap {
  slug: string; name: string; geoid: string; url: string; where?: string; layers?: { url: string; key: number }[];
  district_field: string; expected: number; key_map?: Record<string, number>; key_regex?: string; keys?: number[];
  source_note: string; max_uncovered_pct?: number; max_outside_pct?: number; bound_reason?: string;
}

class GateError extends Error {}
const fail = (m: string): never => { throw new GateError(m); };

async function fetchGeojson(c: CityMap): Promise<any[]> {
  const where = encodeURIComponent(c.where ?? '1=1');
  const url = `${c.url}/query?where=${where}&outFields=*&returnGeometry=true&outSR=4326&f=geojson`;
  const r = await fetch(url, { headers: { 'User-Agent': 'EmpoweredVote-civic-data/1.0' } });
  const text = await r.text();
  let j: any;
  try { j = JSON.parse(text); } catch { fail(`fetch: not JSON (HTTP ${r.status}, ${text.length} bytes): ${text.slice(0, 120)}`); }
  // ⚠ ArcGIS reports failures INSIDE a 200 body, so r.ok is not the test.
  if (j.error) fail(`fetch: service error payload ${JSON.stringify(j.error)}`);
  if (!Array.isArray(j.features)) fail(`fetch: no features array (HTTP ${r.status})`);
  if (j.features.length && j.features.every((f: any) => f.geometry)) return j.features;
  // ⚠ Some older MapServers answer f=geojson with attributes and NULL geometry (Greenwood, measured 2026-11-24).
  // Re-read as Esri JSON and convert: in Esri rings an outer ring is clockwise, a hole counter-clockwise, and a
  // hole belongs to the outer ring before it.
  console.log('    (geojson came back without geometry — re-reading as Esri JSON)');
  const r2 = await fetch(url.replace('f=geojson', 'f=json'), { headers: { 'User-Agent': 'EmpoweredVote-civic-data/1.0' } });
  const e = await r2.json();
  if (e.error || !Array.isArray(e.features)) fail(`fetch (esri json): ${JSON.stringify(e.error ?? 'no features')}`);
  const signed = (ring: number[][]) => ring.reduce((a, p, i) => { const q = ring[(i + 1) % ring.length]; return a + (q[0] - p[0]) * (q[1] + p[1]); }, 0);
  return e.features.map((f: any) => {
    const polys: number[][][][] = [];
    for (const ring of f.geometry?.rings ?? []) {
      if (signed(ring) > 0 || !polys.length) polys.push([ring]);   // clockwise (positive here) = outer
      else polys[polys.length - 1].push(ring);
    }
    return { properties: f.attributes, geometry: polys.length ? { type: 'MultiPolygon', coordinates: polys } : null };
  });
}

function keyOf(c: CityMap, props: Record<string, unknown>): number | null {
  const raw = props[c.district_field];
  if (raw == null) return null;
  const s = String(raw).trim();
  if (c.key_map) return c.key_map[s] ?? null;
  if (c.key_regex) { const m = s.match(new RegExp(c.key_regex)); return m ? Number(m[1]) : null; }
  const m = s.match(/(\d+)\s*$/);
  return m ? Number(m[1]) : null;
}

async function main() {
  const all: CityMap[] = JSON.parse(fs.readFileSync(CONFIG, 'utf8'));
  const cities = ONLY.length ? all.filter((c) => ONLY.includes(c.slug)) : all;
  if (!cities.length) { console.error('no cities selected'); process.exit(2); }
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const client = await pool.connect();
  const q = async (sql: string, p: unknown[] = []) => (await client.query(sql, p)).rows;
  console.log(`Indiana city council districts -> ${MTFCC} · ${cities.length} cit${cities.length === 1 ? 'y' : 'ies'}` +
              `${COMMIT ? '' : '  (DRY RUN)'}${TAMPER ? `  TAMPER=${TAMPER}` : ''}`);
  const results: { slug: string; ok: boolean; msg: string }[] = [];
  let first = true;

  for (const c of cities) {
    console.log(`\n━━ ${c.name} (${c.slug}, place ${c.geoid}) · expect ${c.expected} · ${c.url}`);
    try {
      // A city may publish one layer per district (Terre Haute): `layers: [{url, key}]` — the key is the
      // district number the LAYER is named for, and the gate still requires one geometry per key.
      let feats: any[] = [];
      if (c.layers) {
        for (const l of c.layers) {
          const fs_ = await fetchGeojson({ ...c, url: l.url });
          for (const f of fs_) feats.push({ ...f, properties: { ...(f.properties ?? {}), [c.district_field]: String(l.key) } });
        }
      } else feats = await fetchGeojson(c);
      if (TAMPER === 'drop' && first) { feats = feats.slice(1); console.log('  ⚠ TAMPER drop: removed one feature'); }

      // GATE 1 — keys
      const byKey = new Map<number, any[]>();
      for (const f of feats) {
        const k = keyOf(c, f.properties ?? {});
        console.log(`    feature ${c.district_field}=${JSON.stringify(f.properties?.[c.district_field])} -> key ${k}`);
        if (k == null) fail(`GATE 1: a feature has no usable ${c.district_field}`);
        if (!f.geometry) fail(`GATE 1: district ${k} has no geometry`);
        byKey.set(k, [...(byKey.get(k) ?? []), f.geometry]);
      }
      const keys = [...byKey.keys()].sort((a, b) => a - b);
      const want = c.keys ?? Array.from({ length: c.expected }, (_, i) => i + 1);
      if (want.length !== c.expected) fail(`GATE 1: config keys ${JSON.stringify(c.keys)} do not number ${c.expected}`);
      if (JSON.stringify(keys) !== JSON.stringify(want)) fail(`GATE 1: keys ${JSON.stringify(keys)}, expected ${JSON.stringify(want)}`);
      for (const [k, g] of byKey) if (g.length > 1) console.log(`    D${k}: ${g.length} parts dissolved into one`);
      console.log(`  ✓ GATE 1  ${feats.length} feature(s), keys ${JSON.stringify(want)}`);

      await q('DROP TABLE IF EXISTS ccb_load; DROP TABLE IF EXISTS ccb_geom');
      await q('CREATE TEMP TABLE ccb_load(district int, gj text)');
      for (const [k, gs] of byKey) for (const g of gs) await q('INSERT INTO ccb_load VALUES ($1,$2)', [k, JSON.stringify(g)]);
      await q(`CREATE TEMP TABLE ccb_geom AS
               SELECT district,
                      ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_Union(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(gj),4326)))),3)) AS geom
               FROM ccb_load GROUP BY district`);
      if (TAMPER === 'shift' && first) {
        await q('UPDATE ccb_geom SET geom = ST_Translate(geom, 0.03, 0) WHERE district = 1');
        console.log('  ⚠ TAMPER shift: moved district 1 0.03° east');
      }

      // CLIP — trim every district to the city's TIGER place polygon, the same polygon that carries the Mayor,
      // the clerk and the at-large seats. Council maps are drawn from whole precincts, and a precinct can reach
      // past the city line; unclipped, a resident outside the city would be shown a council member. Measured
      // before the clip and printed, so a map that sits far outside the city still fails GATE 4 below on the
      // RAW numbers (a wrong layer must not be laundered into a plausible one by the clip).
      const [raw] = await q(`SELECT ST_Area(ST_Difference(u.g,p.geometry)::geography)/$1 AS outs
                             FROM essentials.geofence_boundaries p, (SELECT ST_Union(geom) g FROM ccb_geom) u
                             WHERE p.geo_id=$2 AND p.mtfcc='G4110'`, [SQM_PER_SQMI, c.geoid]);
      const rawOutside = Number(raw?.outs ?? 0);
      await q(`UPDATE ccb_geom c SET geom = ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_Intersection(c.geom, p.geometry)),3))
               FROM essentials.geofence_boundaries p WHERE p.geo_id=$1 AND p.mtfcc='G4110'`, [c.geoid]);
      console.log(`    clipped to place ${c.geoid}: ${rawOutside.toFixed(4)} sq mi outside the city removed`);

      // GATE 2 — validity and size
      const [place] = await q(`SELECT ST_Area(geometry::geography)/$1 AS sq_mi FROM essentials.geofence_boundaries
                               WHERE geo_id=$2 AND mtfcc='G4110'`, [SQM_PER_SQMI, c.geoid]);
      if (!place) fail(`GATE 2: TIGER place ${c.geoid}/G4110 is not in production`);
      const placeSq = Number(place.sq_mi);
      const areas = await q(`SELECT district, ST_Area(geom::geography)/$1 AS sq_mi, ST_GeometryType(geom) AS t,
                                    ST_IsValid(geom) AS v FROM ccb_geom ORDER BY district`, [SQM_PER_SQMI]);
      for (const a of areas) {
        const share = Number(a.sq_mi) / placeSq;
        console.log(`    D${a.district} ${Number(a.sq_mi).toFixed(4)} sq mi (${(share * 100).toFixed(1)}% of place) ${a.t} valid=${a.v}`);
        if (a.t !== 'ST_MultiPolygon' || !a.v) fail(`GATE 2: D${a.district} is ${a.t}, valid=${a.v}`);
        if (share < MIN_DISTRICT_SHARE) fail(`GATE 2: D${a.district} is ${(share * 100).toFixed(2)}% of the place — a sliver (wrong layer or projection?)`);
      }
      console.log(`  ✓ GATE 2  all valid MultiPolygons, none under ${MIN_DISTRICT_SHARE * 100}% of the place (${placeSq.toFixed(2)} sq mi)`);

      // GATE 3 — overlaps
      const laps = await q(`SELECT a.district a, b.district b, ST_Area(ST_Intersection(a.geom,b.geom)::geography)/$1 sq
                            FROM ccb_geom a JOIN ccb_geom b ON a.district<b.district AND ST_Intersects(a.geom,b.geom)`, [SQM_PER_SQMI]);
      const bad = laps.filter((l: any) => Number(l.sq) > MAX_PAIR_OVERLAP_SQ_MI);
      console.log(`    ${laps.length} touching pair(s); largest overlap ${Math.max(0, ...laps.map((l: any) => Number(l.sq))).toFixed(4)} sq mi`);
      if (bad.length) fail(`GATE 3: ${bad.map((l: any) => `D${l.a}/D${l.b} ${Number(l.sq).toFixed(4)}`).join(', ')} sq mi overlap`);
      console.log(`  ✓ GATE 3  no pair overlaps more than ${MAX_PAIR_OVERLAP_SQ_MI} sq mi`);

      // GATE 4 — coverage bound
      const [cov] = await q(`SELECT ST_Area(ST_Difference(p.geometry,u.g)::geography)/$1 AS unc,
                                    ST_Area(ST_Difference(u.g,p.geometry)::geography)/$1 AS outs,
                                    ST_Area(u.g::geography)/$1 AS uni
                             FROM essentials.geofence_boundaries p, (SELECT ST_Union(geom) g FROM ccb_geom) u
                             WHERE p.geo_id=$2 AND p.mtfcc='G4110'`, [SQM_PER_SQMI, c.geoid]);
      const uncPct = Number(cov.unc) / placeSq * 100, outPct = rawOutside / placeSq * 100;
      if (Number(cov.outs) > 0.0001) fail(`GATE 4: ${Number(cov.outs).toFixed(4)} sq mi still outside the place after the clip`);
      const maxU = c.max_uncovered_pct ?? 3, maxO = c.max_outside_pct ?? 5;
      console.log(`    place ${placeSq.toFixed(4)} · union ${Number(cov.uni).toFixed(4)} · uncovered ${Number(cov.unc).toFixed(4)} (${uncPct.toFixed(2)}%)` +
                  ` · outside before clip ${rawOutside.toFixed(4)} (${outPct.toFixed(2)}%)` + (c.bound_reason ? ` · bound: ${c.bound_reason}` : ''));
      if (uncPct > maxU) fail(`GATE 4: ${uncPct.toFixed(2)}% of the place has no district (bound ${maxU}%)`);
      if (outPct > maxO) fail(`GATE 4: before the clip, districts reached ${outPct.toFixed(2)}% of the place's area outside it (bound ${maxO}%) — wrong layer, wrong projection, or a city that needs a bound_reason`);
      console.log(`  ✓ GATE 4  coverage within bounds (uncovered ≤ ${maxU}%, outside ≤ ${maxO}%)`);

      if (COMMIT) {
        const res = await q(
          `INSERT INTO essentials.geofence_boundaries (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
           SELECT $1 || '-council-district-' || district,
                  'ocd-division/country:us/state:in/place:' || $2 || '/council_district:' || district,
                  $3 || ' City Council District ' || district, $4, $5, geom, $6, now()
           FROM ccb_geom
           ON CONFLICT (geo_id, mtfcc) DO NOTHING RETURNING geo_id`,
          [c.slug, c.name.toLowerCase().replace(/[ -]/g, '_'), c.name, STATE_CODE, MTFCC,
           `${c.url} · ${c.source_note} · loaded ${new Date().toISOString().slice(0, 10)} (Indiana cities Wave A)`]);
        const [n] = await q(`SELECT count(*) n FROM essentials.geofence_boundaries WHERE mtfcc=$1 AND geo_id LIKE $2`,
                            [MTFCC, `${c.slug}-council-district-%`]);
        if (Number(n.n) !== c.expected) fail(`post-write: ${n.n} rows for ${c.slug}, expected ${c.expected}`);
        console.log(`  ✓ wrote ${res.length} new row(s); ${n.n} present`);
      }
      results.push({ slug: c.slug, ok: true, msg: 'PASS' });
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      console.log(`  ✗ ${msg}`);
      results.push({ slug: c.slug, ok: false, msg });
      if (!(e instanceof GateError)) console.log('    (not a gate failure — an exception)');
    }
    first = false;
  }
  client.release();
  await pool.end();
  console.log('\nSummary');
  for (const r of results) console.log(`  ${r.ok ? 'PASS' : 'FAIL'}  ${r.slug.padEnd(20)} ${r.ok ? '' : r.msg}`);
  process.exit(results.every((r) => r.ok) ? 0 : 1);
}
main();
