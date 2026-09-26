#!/usr/bin/env node
/**
 * verify-nd-tiger-vintage.mjs — Knight program, wave ND-1.
 *
 * Proves which redistricting plan the TIGER FIPS 38 legislative layers carry, against an
 * authority that is not the Census Bureau.
 *
 * THE AUTHORITY: the North Dakota GIS Hub publishes `NDGISHUB Legislative Districts`, whose
 * own abstract states it "Shows the 47 legislative districts revised as a result of the order
 * imposed by the United States District Court on January 8, 2024" — the remedial plan from
 * Turtle Mountain Band of Chippewa Indians v. Howe, in which the court held on 2023-11-17 that
 * the drawing of Districts 9 and 15 and Subdistricts 9A and 9B violated Section 2 of the VRA.
 * That is the state publishing its own districts, not a Census mirror. It answers a plain
 * request — no WAF, unlike Ohio's Secretary of State.
 *
 * 🟢 NORTH DAKOTA GIVES A STRUCTURAL DISCRIMINATOR MOST STATES DO NOT. The remedial plan
 * DISSOLVED subdistricts 9A/9B back into a whole District 9 while leaving 4A/4B in place, so
 * the House layer's own code set dates the map: 49 polygons with 04A/04B/09A/09B is HB 1504,
 * 48 polygons with 04A/04B only is the remedial plan. Measured 2026-09-25: TIGER 2022 and 2023
 * carry 49 (LSY 2022); TIGER 2024 and 2025 carry 48 (LSY 2024).
 * 🔴 BUT THE CODE SET IS NOT THE PROOF, AND MUST NOT BE MISTAKEN FOR ONE. The same order
 * redrew District 15, which kept its number. A code-set check is blind to every boundary change
 * that does not rename a district, so this script tests GEOMETRY: every TIGER polygon is
 * located at its own published internal point (INTPTLAT/INTPTLON) inside the authority plan,
 * and the district code must match.
 *
 * 🔴 THE SUPERSEDED PLAN IS PUBLISHED BESIDE THE CURRENT ONE, AND SORTS ABOVE IT ON ONE FIELD.
 * `NDGISHUB 2021 67th Assembly Legislative Districts` is HB 1504 — the map the court struck
 * down. Its catalogue `modified` is 2021-11-12, but its `issued` is 2025-03-24, three years
 * LATER than the current layer's 2022-01-21. Sorting these two by freshness on the wrong field
 * picks the dead map. Name the layer; never take the newest.
 *
 * 🔴 A NORTH DAKOTA HOUSE DISTRICT IS NOT AN INTEGER. Codes '04A' and '04B' exist in both the
 * TIGER layer and the authority ('4A'/'4B'). `parseInt('04A')` is 4 — the MN/MD A-B collapse,
 * which writes two districts onto one identity through a green gate. Normalisation here strips
 * leading zeros from the numeric prefix and KEEPS the letter; nothing is ever cast to a number.
 *
 * 🔴 THE SENATE HAS NO SEPARATE AUTHORITY GEOMETRY. North Dakota draws ONE set of districts;
 * the House subdivides District 4 into 4A/4B and the Senate does not. The authority layer is
 * therefore the House layer, and a Senate comparison maps authority 4A and 4B onto 4 before
 * matching. That is a deliberate, stated fold, not a fuzzy match.
 *
 * THE CONTROL: the identical comparison is re-run against TIGER 2022, which carries HB 1504 and
 * MUST disagree. A verifier that cannot fail has proved nothing.
 *
 * Usage:  node scripts/verify-nd-tiger-vintage.mjs [--workdir <dir>] [--ref-file <geojson>]
 * Exit:   0 agreement complete AND the control failed as required; 1 otherwise.
 */
import https from 'https';
import fs from 'fs';
import os from 'os';
import path from 'path';
import AdmZip from 'adm-zip';
import * as shapefile from 'shapefile';

const argv = process.argv.slice(2);
const argOf = (flag) => {
  const i = argv.indexOf(flag);
  return i >= 0 ? argv[i + 1] : undefined;
};
const WORKDIR = argOf('--workdir') ?? fs.mkdtempSync(path.join(os.tmpdir(), 'nd-tiger-'));
const REF_FILE = argOf('--ref-file');
fs.mkdirSync(WORKDIR, { recursive: true });

const AUTHORITY_URL =
  'https://services1.arcgis.com/GOcSXpzwBHyk2nog/arcgis/rest/services/' +
  'NDGISHUB_Legislative_Districts/FeatureServer/0/query' +
  '?where=1%3D1&outFields=DISTRICT&outSR=4326&f=geojson';

/** The authority is the HOUSE plan: 47 districts, District 4 split into 4A/4B. */
const AUTHORITY_EXPECT = 48;

const PAIRS = [
  { layer: 'sldl', codeField: 'SLDLST', expect: 48, label: 'House', foldSubdistricts: false },
  { layer: 'sldu', codeField: 'SLDUST', expect: 47, label: 'Senate', foldSubdistricts: true },
];

const CANDIDATE_VINTAGE = '2024';
const CONTROL_VINTAGE = '2022';

function download(url, dest) {
  return new Promise((resolve, reject) => {
    const req = https.get(url, { headers: { 'User-Agent': 'ev-accounts/nd-slice12' } }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        res.resume();
        return download(res.headers.location, dest).then(resolve, reject);
      }
      if (res.statusCode !== 200) {
        res.resume();
        return reject(new Error(`${url} -> HTTP ${res.statusCode}`));
      }
      const out = fs.createWriteStream(dest);
      res.pipe(out);
      out.on('finish', () => out.close(() => resolve(dest)));
    });
    req.on('error', reject);
  });
}

function extract(zipPath, outDir) {
  fs.mkdirSync(outDir, { recursive: true });
  new AdmZip(zipPath).extractAllTo(outDir, true);
  const shp = fs.readdirSync(outDir).find((f) => f.toLowerCase().endsWith('.shp'));
  if (!shp) throw new Error(`no .shp inside ${zipPath}`);
  return path.join(outDir, shp);
}

async function readFeatures(shpPath) {
  const feats = [];
  const src = await shapefile.open(shpPath, shpPath.replace(/\.shp$/i, '.dbf'));
  for (let r = await src.read(); !r.done; r = await src.read()) feats.push(r.value);
  return feats;
}

/** Ray casting over a GeoJSON Polygon/MultiPolygon. */
function contains(geom, x, y) {
  const polys = geom.type === 'Polygon' ? [geom.coordinates] : geom.coordinates;
  for (const poly of polys) {
    let inside = false;
    for (const ring of poly) {
      for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
        const [xi, yi] = ring[i];
        const [xj, yj] = ring[j];
        if ((yi > y) !== (yj > y) && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) inside = !inside;
      }
    }
    if (inside) return true;
  }
  return false;
}

/**
 * '04A' -> '4A', '004' -> '4', '4B' -> '4B', '15' -> '15'.
 * 🔴 Never parseInt: 'parseInt("04A")' is 4, which collapses 4A and 4B onto District 4.
 */
function normCode(raw) {
  const s = String(raw).trim().toUpperCase();
  const m = /^(\d+)([A-Z]?)$/.exec(s);
  if (!m) throw new Error(`unrecognised district code: ${JSON.stringify(raw)}`);
  return String(Number(m[1])) + m[2];
}

/** The Senate does not subdivide: authority 4A and 4B are both Senate district 4. */
const foldToSenate = (code) => code.replace(/^(\d+)[A-Z]$/, '$1');

async function authorityFeatures() {
  const dest = REF_FILE ?? path.join(WORKDIR, 'nd_authority_ld.geojson');
  if (!fs.existsSync(dest)) await download(AUTHORITY_URL, dest);
  const raw = JSON.parse(fs.readFileSync(dest, 'utf8'));
  if (raw.exceededTransferLimit) {
    throw new Error('authority query was truncated (exceededTransferLimit) — page it before trusting it');
  }
  const feats = raw.features ?? [];
  if (feats.length !== AUTHORITY_EXPECT) {
    throw new Error(
      `authority plan holds ${feats.length} districts, expected ${AUTHORITY_EXPECT}. ` +
      `Did the layer change, or is this the superseded 2021 67th Assembly layer?`,
    );
  }
  return feats.map((f) => ({ geometry: f.geometry, code: normCode(f.properties.DISTRICT) }));
}

async function tigerFeatures(year, layer) {
  const url = `https://www2.census.gov/geo/tiger/TIGER${year}/${layer.toUpperCase()}/tl_${year}_38_${layer}.zip`;
  const zip = path.join(WORKDIR, `tl_${year}_38_${layer}.zip`);
  if (!fs.existsSync(zip)) await download(url, zip);
  return readFeatures(extract(zip, path.join(WORKDIR, `tl_${year}_38_${layer}`)));
}

/** Locate every TIGER polygon's own internal point inside the reference plan. */
function compare(tiger, reference, codeField, fold) {
  let agree = 0;
  const disagree = [];
  let ambiguous = 0;
  for (const f of tiger) {
    const p = f.properties;
    const x = parseFloat(p.INTPTLON);
    const y = parseFloat(p.INTPTLAT);
    const mine = fold ? foldToSenate(normCode(p[codeField])) : normCode(p[codeField]);
    const hits = [
      ...new Set(
        reference
          .filter((r) => contains(r.geometry, x, y))
          .map((r) => (fold ? foldToSenate(r.code) : r.code)),
      ),
    ];
    if (hits.length !== 1) {
      ambiguous++;
      continue;
    }
    if (hits[0] === mine) agree++;
    else disagree.push(`${mine}->${hits[0]}`);
  }
  return { agree, disagree, ambiguous, total: tiger.length };
}

async function main() {
  const ref = await authorityFeatures();
  console.log(
    `authority: NDGISHUB Legislative Districts — ${ref.length} polygons, ` +
    `codes ${ref.map((r) => r.code).sort().join(' ')}`,
  );

  let ok = true;
  for (const { layer, codeField, expect, label, foldSubdistricts } of PAIRS) {
    const cand = await tigerFeatures(CANDIDATE_VINTAGE, layer);
    if (cand.length !== expect) {
      console.error(`🔴 ${label}: TIGER ${CANDIDATE_VINTAGE} holds ${cand.length} polygons, expected ${expect}. Stop.`);
      ok = false;
      continue;
    }
    const r = compare(cand, ref, codeField, foldSubdistricts);
    const pass = r.agree === expect && r.disagree.length === 0 && r.ambiguous === 0;
    console.log(
      `${pass ? '🟢' : '🔴'} ${label} — TIGER ${CANDIDATE_VINTAGE} vs the court-ordered 2024 plan: ` +
      `${r.total} polygons, AGREE ${r.agree}, DISAGREE ${r.disagree.length}, ambiguous ${r.ambiguous}`,
    );
    if (r.disagree.length) console.log(`   disagreements (tiger->authority): ${r.disagree.join(', ')}`);
    if (!pass) ok = false;

    const ctrlFeats = await tigerFeatures(CONTROL_VINTAGE, layer);
    const c = compare(ctrlFeats, ref, codeField, foldSubdistricts);
    const ctrlFailedAsRequired = c.disagree.length > 0 || c.ambiguous > 0;
    console.log(
      `${ctrlFailedAsRequired ? '🟢' : '🔴'} ${label} — CONTROL, TIGER ${CONTROL_VINTAGE} (HB 1504, struck down): ` +
      `${c.total} polygons, AGREE ${c.agree}, DISAGREE ${c.disagree.length}, ambiguous ${c.ambiguous}` +
      (ctrlFailedAsRequired ? ' — disagrees as required' : ' — DID NOT FAIL, the test proves nothing'),
    );
    if (c.disagree.length) console.log(`   control disagreements (tiger->authority): ${c.disagree.join(', ')}`);
    // 🔴 How many the control still AGREES on is the number a count would have missed.
    console.log(`   ⚠ the control still agrees on ${c.agree} of ${c.total} — a count cannot date this map.`);
    if (!ctrlFailedAsRequired) ok = false;
  }

  console.log(
    ok
      ? '\n🟢 VINTAGE PROVED: TIGER 2024 FIPS 38 is the plan ordered by the U.S. District Court on 2024-01-08.'
      : '\n🔴 VINTAGE NOT PROVED — do not load.',
  );
  process.exit(ok ? 0 : 1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
