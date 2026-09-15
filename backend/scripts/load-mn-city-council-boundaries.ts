#!/usr/bin/env -S npx tsx
/**
 * load-mn-city-council-boundaries.ts
 *
 * Fetches the Duluth council-district and Saint Paul ward boundaries and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='duluth-mn-council-district-1'..'-5', mtfcc='X0052'
 *   essentials.geofence_boundaries  geo_id='saint-paul-mn-ward-1'..'-7',        mtfcc='X0053'
 *
 * Writes ONLY to essentials.geofence_boundaries. CC_0109 creates the districts and their offices
 * and REFUSES TO RUN if these twelve boundaries are absent -- an office on a district with no
 * polygon is unreachable by any address, and nothing errors.
 *
 * Wave MN-3 of the Knight Foundation cities program.
 * Sources: backend/data/seed-mn-cities-2026/SOURCES.md
 * Tracker: .planning/knight-foundation/PROGRAM.md
 *
 *   npx tsx scripts/load-mn-city-council-boundaries.ts --dry-run
 *   npx tsx scripts/load-mn-city-council-boundaries.ts
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 DULUTH PUBLISHES TWO COUNCIL-DISTRICT MAPS AND A COUNT CANNOT TELL THEM APART.
 * Both return exactly FIVE features numbered 1-5:
 *
 *   OLD  Precincts_Council_Boundaries_Duluth/MapServer/1   item modified 2021-01-08
 *   NEW  VotingDistricts/MapServer/16                      item modified 2023-03-09   <- used
 *
 * Duluth adopted a new map at the second reading of a redistricting ordinance on 2022-03-28. The
 * old service's PRECINCT layer carries columns literally called POP_2010 and Numb_12 whose
 * populations sum to 86,265 -- Duluth's 2010 census population exactly -- while its DISTRICT
 * layer's population totals 86,918, close enough to the 2020 figure (86,697) that a plausibility
 * check on the number alone passes it. ⚠ THE FIELD NAMES GAVE IT AWAY, NOT THE VALUES.
 *
 * The decisive measurement is coverage, asserted below as GATE 3: the old map leaves 8.68 sq mi
 * of Duluth in NO district (89.18% covered); the new map covers 99.98%.
 *
 * ⚠ TWO LAYERS INSIDE ONE SERVICE CAN BE FROM DIFFERENT MAPS. The old service's layer 0 holds 35
 * precincts while its own layer 1 was dissolved from 43. One service is not one vintage.
 *
 * ⚠ THE LAYER NUMBER IS NOT THE ONE YOU WOULD GUESS. VotingDistricts numbers its layers
 * 16, 0, 14, 2, 5, 3, 4, 1 -- the council districts are 16 and layer 0 is Polling Stations.
 *
 * 🟢 BOTH LAYERS CARRY A ROSTER FIELD AND BOTH ARE POPULATED, so Santa Clara's GATE 2 -- compare
 * the layer's own member names against the independently verified roster -- IS available here,
 * unlike Fort Wayne where FW_Council_Rep was empty in all six districts. GATE 2 below uses it.
 *
 * ⚠ NEVER READ A ROSTER OUT OF A BOUNDARY LAYER. The roster that reaches the database comes from
 * each city's council pages and its 18 individual member pages, per
 * data/mn-cities-roster.json. GATE 2 uses the layer's names only as a VINTAGE TEST: if the
 * polygons were the old map, the names attached to them would not be this council.
 */
import 'dotenv/config';
import { Pool } from 'pg';
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROSTER = path.join(HERE, '..', 'data', 'mn-cities-roster.json');
const DRY = process.argv.includes('--dry-run');

type City = {
  key: string;
  city: string;
  mtfcc: string;
  slug: (n: number) => string;
  label: (n: number) => string;
  placeGeoId: string;
  expected: number;
  url: string;
  numberField: string;
  nameField: string | null;
  /** Minimum share of the TIGER place polygon the union of these districts must cover. */
  minCoverPct: number;
};

const CITIES: City[] = [
  {
    key: 'duluth',
    city: 'Duluth',
    mtfcc: 'X0052',
    slug: (n) => `duluth-mn-council-district-${n}`,
    label: (n) => `Duluth City Council District ${n}`,
    placeGeoId: '2717000',
    expected: 5,
    url:
      'https://utility.arcgis.com/usrsvcs/servers/48a6121974c84a63bc18be012b1fa10a/rest/services/' +
      'VotingDistricts/VotingDistricts/MapServer/16/query' +
      '?where=1%3D1&outFields=CouncilDist,Councilor&returnGeometry=true&outSR=4326&f=geojson',
    numberField: 'CouncilDist',
    nameField: 'Councilor',
    // Duluth's districts OVERHANG the place polygon by 11.16 sq mi of Lake Superior and
    // unincorporated township. Coverage of the city is what matters, not the union area.
    minCoverPct: 99.9,
  },
  {
    key: 'saint-paul',
    city: 'Saint Paul',
    mtfcc: 'X0053',
    slug: (n) => `saint-paul-mn-ward-${n}`,
    label: (n) => `Saint Paul City Council Ward ${n}`,
    placeGeoId: '2758000',
    expected: 7,
    url:
      'https://services1.arcgis.com/9meaaHE3uiba0zr8/arcgis/rest/services/Council_Ward_/FeatureServer/0/query' +
      '?where=1%3D1&outFields=district,name,ward&returnGeometry=true&outSR=4326&f=geojson',
    numberField: 'district',
    nameField: 'name',
    minCoverPct: 99.9,
  },
];

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0 Safari/537.36';
const SOURCE_NOTE: Record<string, string> = {
  duluth:
    'City of Duluth GIS Office, VotingDistricts/MapServer/16 "Districts and City Councilors", read 2026-09-14 (MN-3, X0052)',
  'saint-paul':
    'City of Saint Paul, Council_Ward_/FeatureServer/0 "Council Ward", read 2026-09-14 (MN-3, X0053)',
};

function fail(msg: string): never {
  console.error(`\n✗ ${msg}`);
  process.exit(1);
}

const normName = (s: unknown) =>
  String(s ?? '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/^councilmember\s+/, '')
    .replace(/[^a-z ]/g, '')
    .replace(/\s+/g, ' ')
    .trim();

/**
 * 🔴 A GATE THAT HAS NEVER BEEN SEEN TO FAIL IS NOT A GATE. --control runs each one against a
 * deliberately wrong input and requires it to refuse. The most important is GATE 3 against
 * Duluth's SUPERSEDED 2012 map, which is the exact mistake this loader exists to prevent.
 */
const OLD_DULUTH_URL =
  'https://utility.arcgis.com/usrsvcs/servers/0f2b2e8a51814f26b0c7626f31915537/rest/services/' +
  'GeneralUse/Precincts_Council_Boundaries_Duluth/MapServer/1/query' +
  '?where=1%3D1&outFields=Cncl_Dist&returnGeometry=true&outSR=4326&f=geojson';

async function controls() {
  const roster = JSON.parse(fs.readFileSync(ROSTER, 'utf8')).roster as Array<Record<string, any>>;
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const q = async (sql: string, params: unknown[] = []) => (await pool.query(sql, params)).rows;
  const duluth = CITIES[0];

  const say = (name: string, refused: boolean, detail: string) =>
    console.log(`  ${refused ? 'OK  ' : 'FAIL'} ${name.padEnd(42)} ${detail}`);

  console.log('-- GATE CONTROLS (each input is wrong; each gate must refuse) ------------------');

  // 1. GATE 1 -- a district removed.
  const live = await (await fetch(duluth.url, { headers: { 'User-Agent': UA } })).json();
  const short = live.features.slice(1);
  say('GATE 1  a district removed', short.length !== duluth.expected,
      `${short.length} features against an expected ${duluth.expected}`);

  // 2. GATE 2 -- a councilor renamed.
  const renamed = JSON.parse(JSON.stringify(live));
  renamed.features[0].properties.Councilor = 'Zzz Control';
  const want = roster.find((x) => x.city === 'Duluth' && x.district_number === Number(renamed.features[0].properties.CouncilDist));
  say('GATE 2  a councilor renamed', normName('Zzz Control') !== normName(want!.full_name),
      `layer "Zzz Control" vs roster "${want!.full_name}"`);

  // 3. GATE 2 -- the field holds one value everywhere, so it discriminates nothing.
  const uniform = JSON.parse(JSON.stringify(live));
  for (const f of uniform.features) f.properties.Councilor = 'Same Person';
  const distinct = new Set(uniform.features.map((f: any) => normName(f.properties.Councilor))).size;
  say('GATE 2  one name on every district', distinct !== duluth.expected, `${distinct} distinct value(s)`);

  // 4. GATE 2 -- the OLD service, whose layer has no councilor field at all.
  const oldResp = await fetch(OLD_DULUTH_URL, { headers: { 'User-Agent': UA } });
  const oldGj: any = JSON.parse(await oldResp.text());
  const oldNames = oldGj.features.map((f: any) => String(f.properties.Councilor ?? ''));
  say('GATE 2  the SUPERSEDED 2012 service', oldNames.every((n: string) => !n.trim()),
      `its layer carries no Councilor field: ${oldGj.features.length} empty`);

  // 5. GATE 3 -- the SUPERSEDED map's coverage of Duluth. THE ONE THAT MATTERS.
  await q('BEGIN');
  await q(`SET LOCAL statement_timeout = '180s'`);
  await q(`CREATE TEMP TABLE ctl_geom(num int, geom geometry) ON COMMIT DROP`);
  for (const f of oldGj.features) {
    await q(`INSERT INTO ctl_geom(num, geom) VALUES ($1, ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON($2), 4326)))`,
      [Number(f.properties.Cncl_Dist), JSON.stringify(f.geometry)]);
  }
  const [cov] = await q(
    `WITH u AS (SELECT ST_Union(geom) g FROM ctl_geom),
          p AS (SELECT ST_MakeValid(geometry) g FROM essentials.geofence_boundaries WHERE geo_id=$1 AND mtfcc='G4110')
     SELECT round((100*ST_Area(ST_Intersection(p.g,u.g)::geography)/ST_Area(p.g::geography))::numeric,3) AS pct,
            round((ST_Area(ST_Difference(p.g,u.g)::geography)/2589988.11)::numeric,4) AS uncovered_sq_mi
       FROM u, p`, [duluth.placeGeoId]);
  say('GATE 3  the SUPERSEDED 2012 map', Number(cov.pct) < duluth.minCoverPct,
      `covers ${cov.pct}% (threshold ${duluth.minCoverPct}%), leaving ${cov.uncovered_sq_mi} sq mi with no councilor`);

  // 6. GATE 4 -- the SUPERSEDED map's self-overlaps, which the current one does not have.
  const [ov] = await q(
    `SELECT count(*) AS pairs, round((COALESCE(sum(ST_Area(ST_Intersection(a.geom,b.geom)::geography)),0)/2589988.11)::numeric,5) AS sq_mi
       FROM ctl_geom a JOIN ctl_geom b ON b.num > a.num AND ST_Overlaps(a.geom,b.geom)`);
  console.log(`  note  the superseded map also self-overlaps on ${ov.pairs} pair(s), ${ov.sq_mi} sq mi`);
  await q('ROLLBACK');

  // 7. The positive half: the CURRENT map must PASS the gate the old one fails.
  await q('BEGIN');
  await q(`SET LOCAL statement_timeout = '180s'`);
  await q(`CREATE TEMP TABLE ctl_new(num int, geom geometry) ON COMMIT DROP`);
  for (const f of live.features) {
    await q(`INSERT INTO ctl_new(num, geom) VALUES ($1, ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON($2), 4326)))`,
      [Number(f.properties.CouncilDist), JSON.stringify(f.geometry)]);
  }
  const [covNew] = await q(
    `WITH u AS (SELECT ST_Union(geom) g FROM ctl_new),
          p AS (SELECT ST_MakeValid(geometry) g FROM essentials.geofence_boundaries WHERE geo_id=$1 AND mtfcc='G4110')
     SELECT round((100*ST_Area(ST_Intersection(p.g,u.g)::geography)/ST_Area(p.g::geography))::numeric,3) AS pct FROM u, p`,
    [duluth.placeGeoId]);
  console.log(`  OK   GATE 3  the CURRENT map passes                covers ${covNew.pct}%`);
  await q('ROLLBACK');

  await pool.end();
}

async function main() {
  const roster = JSON.parse(fs.readFileSync(ROSTER, 'utf8')).roster as Array<Record<string, any>>;
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const q = async (sql: string, params: unknown[] = []) => (await pool.query(sql, params)).rows;

  for (const c of CITIES) {
    console.log(`\n=== ${c.city} (${c.mtfcc}) ===`);

    // ── Fetch. 🔴 A CLEAN HTTP 200 CAN CARRY A TRUNCATED OR ERROR BODY; only a full decode
    //    catches it, so the JSON is parsed before anything is believed about the response.
    const r = await fetch(c.url, { headers: { 'User-Agent': UA } });
    const raw = await r.text();
    if (r.status !== 200) fail(`${c.city}: HTTP ${r.status} from the district service`);
    let gj: any;
    try {
      gj = JSON.parse(raw);
    } catch {
      fail(`${c.city}: HTTP 200 but the body is not JSON (${raw.length} bytes). ${raw.slice(0, 160)}`);
    }
    if (gj.error) fail(`${c.city}: service returned an error object: ${JSON.stringify(gj.error).slice(0, 200)}`);
    const feats: any[] = gj.features ?? [];

    // ── GATE 1: exactly the expected number of districts, numbered 1..N with no gaps.
    if (feats.length !== c.expected) fail(`${c.city} GATE 1: ${feats.length} features, expected ${c.expected}`);
    const nums = feats.map((f) => Number(f.properties[c.numberField]));
    if (nums.some((n) => !Number.isInteger(n))) fail(`${c.city} GATE 1: a district number is not an integer: ${nums}`);
    const wanted = Array.from({ length: c.expected }, (_, i) => i + 1);
    const missing = wanted.filter((n) => !nums.includes(n));
    if (missing.length) fail(`${c.city} GATE 1: districts ${missing.join(', ')} are missing`);
    if (new Set(nums).size !== c.expected) fail(`${c.city} GATE 1: duplicate district numbers in ${nums}`);
    console.log(`  GATE 1 ✓ ${c.expected} districts, numbered ${wanted.join(', ')}`);

    // ── GATE 2: the VINTAGE test. The layer's own member names must be this council.
    //    ⚠ This is not a roster read. It asks whether the POLYGONS belong to the map these
    //    people were elected under; had the old Duluth map been fetched, its councilor names
    //    would be the previous council's.
    if (c.nameField) {
      const byNum = new Map<number, string>();
      for (const f of feats) byNum.set(Number(f.properties[c.numberField]), String(f.properties[c.nameField] ?? ''));
      const empties = [...byNum.entries()].filter(([, v]) => !v.trim());
      if (empties.length) {
        fail(
          `${c.city} GATE 2: the layer's ${c.nameField} field is EMPTY for district(s) ` +
            `${empties.map(([k]) => k).join(', ')}. Fort Wayne's FW_Council_Rep was empty too, and a field ` +
            `that looks like a source and holds nothing invites the sentence "the city confirms the roster". ` +
            `It does not. Decide what this means before loading.`,
        );
      }
      let agreed = 0;
      for (const [n, layerName] of byNum) {
        const want = roster.find((x) => x.city === c.city && x.district_number === n);
        if (!want) fail(`${c.city} GATE 2: roster has no district ${n}`);
        if (normName(layerName) !== normName(want.full_name)) {
          fail(
            `${c.city} GATE 2: district ${n} -- layer says "${layerName}", roster says "${want.full_name}". ` +
              `Either the polygons are the wrong vintage or the roster is stale. Settle it before loading.`,
          );
        }
        agreed++;
      }
      // A field returning ONE value everywhere would agree with anything.
      const distinct = new Set([...byNum.values()].map(normName)).size;
      if (distinct !== c.expected) {
        fail(`${c.city} GATE 2: the ${c.nameField} field holds ${distinct} distinct value(s) across ${c.expected} districts -- it does not discriminate`);
      }
      console.log(`  GATE 2 ✓ ${agreed}/${c.expected} district names match the verified roster, all ${distinct} distinct`);
    }

    if (DRY) {
      console.log(`  --dry-run: ${feats.length} feature(s) parsed, no write`);
      continue;
    }

    // ── Write.
    await q('BEGIN');
    await q(`SET LOCAL statement_timeout = '180s'`);
    await q(`CREATE TEMP TABLE mn_geom(geo_id text, name text, num int, geom geometry) ON COMMIT DROP`);
    for (const f of feats) {
      const n = Number(f.properties[c.numberField]);
      await q(
        `INSERT INTO mn_geom(geo_id, name, num, geom)
         VALUES ($1, $2, $3, ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON($4), 4326)))`,
        [c.slug(n), c.label(n), n, JSON.stringify(f.geometry)],
      );
    }

    // ── GATE 3: the districts must COVER the city. This is the measurement that separates
    //    Duluth's two maps -- the superseded one leaves 8.68 sq mi in no district at all.
    //    ⚠ The opposite direction is NOT a gate: Duluth's districts legitimately overhang the
    //    place polygon by 11 sq mi of lake, and Fort Wayne's legitimately fell short of its own.
    const [cov] = await q(
      `WITH u AS (SELECT ST_Union(geom) g FROM mn_geom),
            p AS (SELECT ST_MakeValid(geometry) g FROM essentials.geofence_boundaries WHERE geo_id=$1 AND mtfcc='G4110')
       SELECT round((100*ST_Area(ST_Intersection(p.g,u.g)::geography)/ST_Area(p.g::geography))::numeric,3) AS pct,
              round((ST_Area(ST_Difference(p.g,u.g)::geography)/2589988.11)::numeric,4) AS uncovered_sq_mi,
              round((ST_Area(ST_Difference(u.g,p.g)::geography)/2589988.11)::numeric,3) AS outside_sq_mi
         FROM u, p`,
      [c.placeGeoId],
    );
    if (!cov) fail(`${c.city} GATE 3: TIGER place ${c.placeGeoId}/G4110 is missing`);
    console.log(`  GATE 3   covers ${cov.pct}% of the place, ${cov.uncovered_sq_mi} sq mi uncovered, ${cov.outside_sq_mi} sq mi outside`);
    if (Number(cov.pct) < c.minCoverPct) {
      await q('ROLLBACK');
      fail(
        `${c.city} GATE 3: the districts cover only ${cov.pct}% of the city, below ${c.minCoverPct}%. ` +
          `Duluth's superseded 2012 map scores 89.176% here. An address in the uncovered ${cov.uncovered_sq_mi} sq mi ` +
          `would return no councilor and nothing would error.`,
      );
    }

    // ── GATE 4: the districts must not overlap each other.
    const [ov] = await q(
      `SELECT count(*) AS pairs,
              round((COALESCE(sum(ST_Area(ST_Intersection(a.geom,b.geom)::geography)),0)/2589988.11)::numeric,4) AS sq_mi
         FROM mn_geom a JOIN mn_geom b ON b.num > a.num AND ST_Overlaps(a.geom,b.geom)`,
    );
    if (Number(ov.sq_mi) > 0.001) {
      await q('ROLLBACK');
      fail(`${c.city} GATE 4: ${ov.pairs} overlapping district pair(s) covering ${ov.sq_mi} sq mi`);
    }
    console.log(`  GATE 4 ✓ ${ov.pairs} overlapping pair(s), ${ov.sq_mi} sq mi`);

    const inserted = await q(
      `INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source, imported_at)
       SELECT geo_id, name, '27', $1, geom, $2, now() FROM mn_geom
       ON CONFLICT (geo_id, mtfcc) DO NOTHING
       RETURNING geo_id`,
      [c.mtfcc, SOURCE_NOTE[c.key]],
    );
    console.log(`  inserted ${inserted.length} boundary row(s)`);

    const [after] = await q(`SELECT count(*) AS n FROM essentials.geofence_boundaries WHERE mtfcc=$1`, [c.mtfcc]);
    if (Number(after.n) !== c.expected) {
      await q('ROLLBACK');
      fail(`${c.city} post-write: ${c.mtfcc} holds ${after.n} rows, expected ${c.expected}`);
    }
    await q('COMMIT');
    console.log(`  ✓ ${c.mtfcc} holds ${after.n} boundaries`);
  }

  await pool.end();
  console.log(DRY ? '\n--dry-run complete, nothing written.' : '\nDone.');
}

const entry = process.argv.includes('--control') ? controls : main;
entry().catch((e) => fail(e instanceof Error ? e.message : String(e)));
