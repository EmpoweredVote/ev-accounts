#!/usr/bin/env -S npx tsx
/**
 * load-charlotte-mecklenburg-boundaries.ts
 *
 * Fetches the Charlotte council-district and Mecklenburg commissioner-district boundaries and
 * inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='charlotte-nc-council-district-1'..'-7',   mtfcc='X0056'
 *   essentials.geofence_boundaries  geo_id='mecklenburg-nc-commissioner-district-1'..'-6', mtfcc='X0057'
 *
 * Writes ONLY to essentials.geofence_boundaries. CC_0117 creates the districts and their offices
 * and REFUSES TO RUN if these thirteen boundaries are absent -- an office on a district with no
 * polygon is unreachable by any address, and nothing errors.
 *
 * Wave NC-3 of the Knight Foundation cities program.
 * Sources: backend/data/seed-charlotte-2026/SOURCES.md
 * Tracker: .planning/knight-foundation/PROGRAM.md · notes: .planning/knight-foundation/nc.md
 *
 *   npx tsx scripts/load-charlotte-mecklenburg-boundaries.ts --control
 *   npx tsx scripts/load-charlotte-mecklenburg-boundaries.ts --dry-run
 *   npx tsx scripts/load-charlotte-mecklenburg-boundaries.ts
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴 CHARLOTTE PUBLISHES ITS COUNCIL DISTRICTS FOUR TIMES AND ONE COPY IS FROM 2017.
 *
 *   CITY    gis.charlottenc.gov/.../PLN/CouncilDistricts/MapServer/0          <- used
 *   COUNTY  meckgis.../CharlotteCityCouncilDistricts/FeatureServer/0          county's copy
 *   AGOL    services.arcgis.com/9Nl857LBlQVyzq54/.../CouncilDistricts/...     city's AGOL copy
 *   OLD     services4.arcgis.com/.../SOTC_Charlotte_City_Council_Districts_2017  🔴 SUPERSEDED
 *
 * The three live copies were compared polygon by polygon in PostGIS: the worst symmetric
 * difference is 0.154% of one district (District 5, city against AGOL), and the rest sit between
 * 0.028% and 0.069%. They are three copies of ONE plan and the differences are digitisation
 * noise. The CITY's own layer is used, per the Milledgeville precedent that a city's layer
 * supersedes the county's copy of it.
 *
 * ⚠ ALL THREE LIVE LAYERS CARRY A `DistrictRep` FIELD AND ALL THREE NAME THE CURRENT COUNCIL,
 * including the three members sworn in December 2025. That makes GATE 2 -- compare the layer's
 * own names against the independently verified roster -- available here, and it is the ONLY test
 * that catches a superseded map: a stale layer returns seven features numbered 1-7 as well, so a
 * feature count passes it.
 *
 * ⚠ THE 2017 LAYER CANNOT BE FETCHED -- it answers 499 "Token Required" -- so the vintage control
 * does not use it. It relabels the live layer with the REAL 2023-2025 council instead, which is
 * what a map of that vintage would carry. Three district seats turned over in December 2025, so
 * the gate must refuse on exactly those three. A control that depends on a third party staying
 * public can start passing for the wrong reason the day that service changes.
 *
 * ⚠ NEVER READ A ROSTER OUT OF A BOUNDARY LAYER. The roster that reaches the database comes from
 * the council's own pages, the Clerk's 1991-2027 history PDF and each body's member pages, per
 * data/charlotte-mecklenburg-roster.json. GATE 2 uses the layer's names only as a VINTAGE TEST.
 *
 * 🟢 THE COUNCIL DISTRICTS DO NOT TILE THE CITY, AND THAT IS CORRECT. They cover 99.8423% of TIGER
 * place 3712000. The shortfall decomposes into 1,820 separate pieces whose largest is 0.028 sq mi
 * with a thinness (area / perimeter^2) of 0.00278 against 0.0796 for a circle -- every one is an
 * edge sliver between two digitisations of one city limit, the city's own (which tracks
 * annexations) against TIGER's vintage. GATE 3 therefore asserts 99.8%, NOT a tiling.
 *
 * 🟢 THE COMMISSIONER DISTRICTS DO TILE THE COUNTY: 99.9966% of 37119, 0.0188 sq mi uncovered.
 * The two bodies get DIFFERENT coverage thresholds because they have different relationships to
 * their parent polygon. They are not made uniform.
 */
import 'dotenv/config';
import { Pool } from 'pg';
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROSTER = path.join(HERE, '..', 'data', 'charlotte-mecklenburg-roster.json');
const DRY = process.argv.includes('--dry-run');
const CONTROL = process.argv.includes('--control');

const UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0 Safari/537.36';

type Body = {
  key: string;
  label: string;
  mtfcc: string;
  slug: (n: number) => string;
  name: (n: number) => string;
  /** The polygon these districts sit inside, and the share of it they must cover. */
  parentGeoId: string;
  parentMtfcc: string;
  minCoverPct: number;
  expected: number;
  url: string;
  numberField: string;
  nameField: string;
  rosterBody: string;
  source: string;
};

const BODIES: Body[] = [
  {
    key: 'charlotte-council',
    label: 'Charlotte City Council',
    mtfcc: 'X0056',
    slug: (n) => `charlotte-nc-council-district-${n}`,
    name: (n) => `Charlotte City Council District ${n}`,
    parentGeoId: '3712000',
    parentMtfcc: 'G4110',
    // 99.8423% measured. The shortfall is 1,820 edge slivers, not a hole. See the header.
    minCoverPct: 99.8,
    expected: 7,
    url:
      'https://gis.charlottenc.gov/arcgis/rest/services/PLN/CouncilDistricts/MapServer/0/query' +
      '?where=1%3D1&outFields=District,DistrictRep&returnGeometry=true&outSR=4326&f=geojson',
    numberField: 'District',
    nameField: 'DistrictRep',
    rosterBody: 'charlotte-council',
    source:
      'City of Charlotte GIS, PLN/CouncilDistricts/MapServer/0 "Council Districts", read 2026-09-17 (NC-3, X0056)',
  },
  {
    key: 'mecklenburg-bocc',
    label: 'Mecklenburg Board of County Commissioners',
    mtfcc: 'X0057',
    slug: (n) => `mecklenburg-nc-commissioner-district-${n}`,
    name: (n) => `Mecklenburg County Commissioner District ${n}`,
    parentGeoId: '37119',
    parentMtfcc: 'G4020',
    // 99.9966% measured -- these DO tile the county.
    minCoverPct: 99.99,
    expected: 6,
    url:
      'https://meckgis.mecklenburgcountync.gov/server/rest/services/MecklenburgCountyCommissionerDistricts/FeatureServer/0/query' +
      '?where=1%3D1&outFields=cc,cc_name&returnGeometry=true&outSR=4326&f=geojson',
    numberField: 'cc',
    nameField: 'cc_name',
    rosterBody: 'mecklenburg-bocc',
    source:
      'Mecklenburg County GIS, MecklenburgCountyCommissionerDistricts/FeatureServer/0, read 2026-09-17 (NC-3, X0057)',
  },
];

/**
 * 🔴 A GATE THAT HAS NEVER BEEN SEEN TO FAIL IS NOT A GATE. --control runs each one against a
 * deliberately wrong input and requires it to refuse. The sharpest is the SUPERSEDED VINTAGE
 * control, which feeds GATE 2 a layer carrying the 2023-2025 council: seven features numbered
 * 1-7, exactly like the live one, so GATE 1 passes it and only the roster comparison refuses.
 * Measured 2026-09-17: all five controls refused.
 */
// Kept for the record: Charlotte's own superseded 2017 layer, which answers 499 "Token Required".
const OLD_CHARLOTTE_URL_UNUSED =
  'https://services4.arcgis.com/PQL6eetRH2nby3Hn/arcgis/rest/services/' +
  'SOTC_Charlotte_City_Council_Districts_2017/FeatureServer/0/query' +
  '?where=1%3D1&outFields=*&returnGeometry=false&f=geojson';

function fail(msg: string): never {
  console.error(`\n✗ ${msg}`);
  process.exit(1);
}

const normName = (s: unknown) =>
  String(s ?? '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/^(council ?member|commissioner|dr\.?|mr\.?|ms\.?)\s+/, '')
    .replace(/[^a-z ]/g, '')
    .replace(/\s+/g, ' ')
    .trim();

/** Surname only -- the layers write "JD Mazuera Arias" where the roster writes the same, but
 *  "Renee Johnson" against "Reneé Johnson" and "Dante" against "Danté". Compare on the last
 *  token, accent-stripped, so a real mismatch still fails and a spelling variant does not. */
const surname = (s: unknown) => normName(s).split(' ').slice(-1)[0];

async function getJson(url: string): Promise<any> {
  const r = await fetch(url, { headers: { 'User-Agent': UA } });
  const body = await r.text();
  // 🔴 A CLEAN HTTP 200 CAN CARRY AN ERROR DOCUMENT. Decode, never trust r.ok.
  let gj: any;
  try {
    gj = JSON.parse(body);
  } catch {
    fail(`${url}\n  returned ${r.status} and ${body.length} bytes that are not JSON`);
  }
  if (gj.error) fail(`${url}\n  returned an ArcGIS error: ${JSON.stringify(gj.error).slice(0, 200)}`);
  if (!Array.isArray(gj.features)) fail(`${url}\n  returned no feature array`);
  return gj;
}

function rosterNameFor(body: string, ordinal: number): string {
  const roster = JSON.parse(fs.readFileSync(ROSTER, 'utf8')).roster as Array<Record<string, any>>;
  const hit = roster.find(
    (r) => r.body === body && r.seat === 'district' && Number(r.ordinal) === Number(ordinal),
  );
  if (!hit) fail(`roster has no ${body} district ${ordinal}`);
  return hit.full_name;
}

async function controls() {
  const say = (name: string, refused: boolean, detail: string) =>
    console.log(`  ${refused ? 'OK  ' : 'FAIL'} ${name.padEnd(46)} ${detail}`);
  console.log('-- GATE CONTROLS (each input is wrong; each gate must refuse) ------------------');
  let allRefused = true;
  const record = (ok: boolean) => {
    if (!ok) allRefused = false;
  };

  const clt = BODIES[0];
  const live = await getJson(clt.url);

  // 1. GATE 1 -- a district removed.
  const short = live.features.slice(1);
  const r1 = short.length !== clt.expected;
  record(r1);
  say('GATE 1  a district removed', r1, `${short.length} features against an expected ${clt.expected}`);

  // 2. GATE 2 -- a councilmember renamed.
  const renamed = JSON.parse(JSON.stringify(live));
  renamed.features[0].properties[clt.nameField] = 'Zzz Control';
  const want = rosterNameFor(clt.rosterBody, Number(renamed.features[0].properties[clt.numberField]));
  const r2 = surname('Zzz Control') !== surname(want);
  record(r2);
  say('GATE 2  a councilmember renamed', r2, `layer "Zzz Control" vs roster "${want}"`);

  // 3. GATE 2 -- one name on every district, so the field discriminates nothing. Run the REAL
  //    per-district comparison over a layer whose every name has been overwritten with one value.
  const uniform = JSON.parse(JSON.stringify(live));
  for (const f of uniform.features) f.properties[clt.nameField] = 'Same Person';
  const uniformMatches = uniform.features.filter(
    (f: any) => surname(f.properties[clt.nameField]) ===
                surname(rosterNameFor(clt.rosterBody, Number(f.properties[clt.numberField]))),
  ).length;
  const r3 = uniformMatches < clt.expected;
  record(r3);
  say('GATE 2  one name on every district', r3, `${uniformMatches} of ${clt.expected} districts would match`);

  // 4. 🔴 GATE 2 -- A SUPERSEDED VINTAGE. This is the failure the loader exists to prevent, and a
  //    feature count cannot see it: a stale map returns seven districts numbered 1-7 too.
  //
  //    ⚠ The obvious input -- Charlotte's own SOTC_..._2017 layer -- answers 499 "Token Required",
  //    so it cannot be fetched. It is also the wrong shape of control: one that depends on a third
  //    party staying public can start passing for the wrong reason the day that service changes.
  //    Instead the live layer is relabelled with the REAL 2023-2025 council, which is what a map
  //    of that vintage would carry. Three of the seven district seats turned over at the December
  //    2025 swearing-in, so a correct gate must refuse on exactly those three.
  const PRIOR_COUNCIL: Record<number, string> = {
    1: 'Danté Anderson', 2: 'Malcolm Graham', 3: 'Tiawana Brown', 4: 'Reneé Perkins Johnson',
    5: 'Marjorie Molina', 6: 'Tariq Bokhari', 7: 'Ed Driggs',
  };
  const stale = JSON.parse(JSON.stringify(live));
  for (const f of stale.features) {
    f.properties[clt.nameField] = PRIOR_COUNCIL[Number(f.properties[clt.numberField])];
  }
  const staleMatches = stale.features.filter(
    (f: any) => surname(f.properties[clt.nameField]) ===
                surname(rosterNameFor(clt.rosterBody, Number(f.properties[clt.numberField]))),
  ).length;
  const r4 = stale.features.length === clt.expected && staleMatches < clt.expected;
  record(r4);
  say(
    'GATE 2  a SUPERSEDED vintage (2023-2025 council)',
    r4,
    `${stale.features.length} features (GATE 1 would PASS it); ${staleMatches} of ${clt.expected} names match, so ${clt.expected - staleMatches} seat(s) expose it`,
  );

  // 5. GATE 3 -- coverage, against a deliberately holed union.
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  try {
    const holed = JSON.parse(JSON.stringify(live));
    holed.features = holed.features.slice(0, -1); // drop District 7 entirely
    const { rows } = await pool.query(
      `WITH u AS (SELECT ST_Union(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(g),4326))) g
                    FROM unnest($1::text[]) AS t(g)),
            pl AS (SELECT ST_MakeValid(geometry) g FROM essentials.geofence_boundaries
                    WHERE geo_id=$2 AND mtfcc=$3)
       SELECT 100*ST_Area(ST_Intersection(pl.g,u.g)::geography)/ST_Area(pl.g::geography) AS pct
         FROM u, pl`,
      [holed.features.map((f: any) => JSON.stringify(f.geometry)), clt.parentGeoId, clt.parentMtfcc],
    );
    const pct = Number(rows[0].pct);
    const r5 = pct < clt.minCoverPct;
    record(r5);
    say('GATE 3  a district dropped from the union', r5, `${pct.toFixed(4)}% against a floor of ${clt.minCoverPct}%`);
  } finally {
    await pool.end();
  }

  console.log(
    allRefused
      ? '\n✓ every gate refused its wrong input\n'
      : '\n✗ AT LEAST ONE GATE ACCEPTED A WRONG INPUT -- do not trust this loader\n',
  );
  if (!allRefused) process.exit(1);
}

async function main() {
  if (CONTROL) return controls();

  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  try {
    let written = 0;
    for (const b of BODIES) {
      console.log(`\n── ${b.label} (${b.mtfcc}) ───────────────────────────────`);
      const gj = await getJson(b.url);

      // GATE 1 -- the count.
      if (gj.features.length !== b.expected) {
        fail(`GATE 1: ${b.label} returned ${gj.features.length} features, expected ${b.expected}`);
      }
      const numbers = gj.features.map((f: any) => Number(f.properties[b.numberField])).sort((x, y) => x - y);
      const wanted = Array.from({ length: b.expected }, (_, i) => i + 1);
      if (JSON.stringify(numbers) !== JSON.stringify(wanted)) {
        fail(`GATE 1: ${b.label} districts are ${numbers.join(',')}, expected ${wanted.join(',')}`);
      }
      console.log(`  GATE 1  ✓ ${b.expected} features, numbered ${wanted.join(',')}`);

      // GATE 2 -- the layer's own names must be THIS body, not a superseded one.
      let matched = 0;
      for (const f of gj.features) {
        const n = Number(f.properties[b.numberField]);
        const layerName = f.properties[b.nameField];
        const rosterName = rosterNameFor(b.rosterBody, n);
        if (surname(layerName) === surname(rosterName)) matched++;
        else console.log(`  GATE 2  ⚠ district ${n}: layer "${layerName}" vs roster "${rosterName}"`);
      }
      if (matched !== b.expected) {
        fail(`GATE 2: ${b.label} -- only ${matched} of ${b.expected} layer names match the roster. ` +
             `This is the signature of a SUPERSEDED map.`);
      }
      console.log(`  GATE 2  ✓ all ${b.expected} layer names match the independently sourced roster`);

      // GATE 3 -- coverage of the parent polygon, and GATE 4 -- no mutual overlap.
      const geoms = gj.features.map((f: any) => JSON.stringify(f.geometry));
      const { rows: cov } = await pool.query(
        `WITH u AS (SELECT ST_Union(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(g),4326))) g
                      FROM unnest($1::text[]) AS t(g)),
              pa AS (SELECT ST_MakeValid(geometry) g FROM essentials.geofence_boundaries
                      WHERE geo_id=$2 AND mtfcc=$3)
         SELECT 100*ST_Area(ST_Intersection(pa.g,u.g)::geography)/ST_Area(pa.g::geography) AS pct,
                ST_Area(ST_Difference(pa.g,u.g)::geography)/2589988.110336 AS uncovered_sqmi
           FROM u, pa`,
        [geoms, b.parentGeoId, b.parentMtfcc],
      );
      if (!cov.length || cov[0].pct === null) fail(`GATE 3: parent polygon ${b.parentMtfcc}/${b.parentGeoId} not found`);
      const pct = Number(cov[0].pct);
      if (pct < b.minCoverPct) {
        fail(`GATE 3: ${b.label} covers only ${pct.toFixed(4)}% of ${b.parentGeoId}, floor is ${b.minCoverPct}%`);
      }
      console.log(`  GATE 3  ✓ covers ${pct.toFixed(4)}% of ${b.parentMtfcc}/${b.parentGeoId} ` +
                  `(${Number(cov[0].uncovered_sqmi).toFixed(4)} sq mi uncovered, floor ${b.minCoverPct}%)`);

      const { rows: ov } = await pool.query(
        `WITH g AS (SELECT row_number() OVER () i,
                           ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(x),4326)) geom
                      FROM unnest($1::text[]) AS t(x))
         SELECT count(*)::int n FROM g a JOIN g b2 ON a.i < b2.i
          WHERE ST_Intersects(a.geom,b2.geom)
            AND ST_Area(ST_Intersection(a.geom,b2.geom)::geography) > 1000`,
        [geoms],
      );
      if (ov[0].n !== 0) fail(`GATE 4: ${b.label} has ${ov[0].n} overlapping district pair(s)`);
      console.log('  GATE 4  ✓ no two districts overlap');

      if (DRY) {
        console.log(`  DRY RUN -- ${b.expected} boundaries NOT written`);
        continue;
      }

      for (const f of gj.features) {
        const n = Number(f.properties[b.numberField]);
        const res = await pool.query(
          // Explicit casts: $1 and $2 appear in both the SELECT list and the NOT EXISTS guard, and
          // Postgres refuses to deduce one type for a parameter used in two positions.
          `INSERT INTO essentials.geofence_boundaries (geo_id, mtfcc, name, state, geometry, source)
           SELECT $1::text, $2::text, $3::text, '37', ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON($4::text),4326)), $5::text
            WHERE NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries
                               WHERE geo_id = $1::text AND mtfcc = $2::text)`,
          [b.slug(n), b.mtfcc, b.name(n), JSON.stringify(f.geometry), b.source],
        );
        written += res.rowCount ?? 0;
      }
      console.log(`  wrote ${b.expected} boundaries (idempotent; re-running inserts 0)`);
    }
    console.log(`\n✓ ${DRY ? 'dry run complete' : `${written} boundary row(s) written`}`);
  } finally {
    await pool.end();
  }
}

main().catch((e) => fail(String(e)));
