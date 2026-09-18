#!/usr/bin/env node
/**
 * verify-pa-tiger-vintage.mjs — Knight program, wave PA-1.
 *
 * Proves that the TIGER 2024 FIPS 42 legislative layers carry the 2022 LRC Final Plan,
 * against an authority that is not the Census Bureau.
 *
 * 🔴 WHY A COUNT CANNOT DO THIS. Pa. Const. Art. II §16 fixes the chambers at 203 and 50,
 * so every Pennsylvania plan ever drawn has exactly that shape. "203 polygons arrived" is
 * true of the 2012 map, the 2022 map and any future map. Minnesota's wave met the same
 * problem with 67/134 and settled it on ONE renumbered district; this settles it on all 253.
 *
 * THE TEST: each TIGER polygon is queried at its own internal point against PennDOT's
 * 'Pa House' and 'Pa Senatorial' layers, published through PASDA (Penn State). PennDOT is a
 * Commonwealth agency maintaining its own boundary set — a third authority, not a mirror of
 * TIGER, and refreshed monthly.
 *
 * THE CONTROL: the identical comparison is then run against the TIGER 2018 polygons, which
 * carry the 2012 plan. It MUST fail on the districts that were redrawn. A verifier that
 * cannot fail has proved nothing — MN-6 shipped a portrait check that reported 0 broken
 * while testing none of the rows in question, and the count was the tell.
 *
 * Usage:  node scripts/verify-pa-tiger-vintage.mjs [--workdir <dir>]
 * Exit:   0 agreement complete and the control failed as required; 1 otherwise.
 */
import https from 'https';
import fs from 'fs';
import os from 'os';
import path from 'path';
import AdmZip from 'adm-zip';
import * as shapefile from 'shapefile';

const argv = process.argv.slice(2);
const wdIdx = argv.indexOf('--workdir');
const WORKDIR = wdIdx >= 0 ? argv[wdIdx + 1] : fs.mkdtempSync(path.join(os.tmpdir(), 'pa-tiger-'));
fs.mkdirSync(WORKDIR, { recursive: true });

const PENNDOT = 'https://maps.pasda.psu.edu/arcgis/rest/services/pasda/PennDOT/MapServer';
const UA = { 'User-Agent': 'Mozilla/5.0 ev-accounts-knight' };
// PennDOT service layer id, TIGER layer, TIGER district-code field, seats fixed by Art. II §16
const PAIRS = [
  { penndot: 9, layer: 'sldl', codeField: 'SLDLST', expect: 203, label: 'House' },
  { penndot: 12, layer: 'sldu', codeField: 'SLDUST', expect: 50, label: 'Senate' },
];

function download(url, dest) {
  return new Promise((resolve, reject) => {
    https.get(url, { headers: UA }, (res) => {
      if (res.statusCode !== 200) return reject(new Error(`HTTP ${res.statusCode} for ${url}`));
      const declared = Number(res.headers['content-length'] || 0);
      const ws = fs.createWriteStream(dest);
      let got = 0;
      res.on('data', (c) => { got += c.length; });
      res.pipe(ws);
      // 🔴 A clean 200 can carry a truncated body. Compare what was promised with what arrived.
      ws.on('finish', () => (declared && declared !== got)
        ? reject(new Error(`TRUNCATED: content-length ${declared}, received ${got} — ${url}`))
        : resolve());
      ws.on('error', reject);
    }).on('error', reject);
  });
}

async function readVintage(vintage, layer, codeField) {
  const dir = path.join(WORKDIR, `${vintage}-${layer}`);
  if (!fs.existsSync(dir)) {
    const zip = path.join(WORKDIR, `${vintage}-${layer}.zip`);
    const url = `https://www2.census.gov/geo/tiger/TIGER${vintage}/${layer.toUpperCase()}/tl_${vintage}_42_${layer}.zip`;
    await download(url, zip);
    fs.mkdirSync(dir, { recursive: true });
    new AdmZip(zip).extractAllTo(dir, true);
  }
  const shp = fs.readdirSync(dir).find((f) => f.endsWith('.shp'));
  const dbf = fs.readdirSync(dir).find((f) => f.endsWith('.dbf'));
  const src = await shapefile.open(path.join(dir, shp), path.join(dir, dbf));
  const out = [];
  for (;;) {
    const r = await src.read();
    if (r.done) break;
    const p = r.value.properties;
    out.push({
      code: String(p[codeField] ?? p[`${codeField}10`]),
      lon: Number(p.INTPTLON ?? p.INTPTLON10),
      lat: Number(p.INTPTLAT ?? p.INTPTLAT10),
      lsy: p.LSY ?? p.LSY10 ?? '?',
    });
  }
  return out;
}

async function askPennDot(layerId, lon, lat, tries = 4) {
  const url = `${PENNDOT}/${layerId}/query?geometry=${lon}%2C${lat}&geometryType=esriGeometryPoint`
    + `&inSR=4326&spatialRel=esriSpatialRelIntersects&outFields=LEG_DISTRI&returnGeometry=false&f=json`;
  for (let i = 0; i < tries; i++) {
    try {
      const r = await fetch(url, { headers: UA });
      const t = await r.text();
      // A WAF rejection can be HTTP 200 carrying HTML. Judge the body, never r.ok.
      if (!t.trim().startsWith('{')) throw new Error(`not JSON (HTTP ${r.status})`);
      const j = JSON.parse(t);
      if (j.error) throw new Error(JSON.stringify(j.error).slice(0, 120));
      return j.features.map((f) => String(f.attributes.LEG_DISTRI).trim());
    } catch (e) {
      if (i === tries - 1) throw e;
      await new Promise((res) => setTimeout(res, 500 * (i + 1)));
    }
  }
}

async function sweep(feats, layerId) {
  let agree = 0;
  const differ = [];
  const CONC = 6;
  for (let i = 0; i < feats.length; i += CONC) {
    const batch = feats.slice(i, i + CONC);
    const res = await Promise.all(batch.map((f) => askPennDot(layerId, f.lon, f.lat)));
    res.forEach((got, k) => {
      const mine = String(Number(batch[k].code)); // TIGER pads: '007' is district 7
      if (got.length === 1 && got[0] === mine) agree++;
      else differ.push(`TIGER ${batch[k].code} -> PennDOT [${got.join('|') || 'none'}]`);
    });
  }
  return { agree, differ, tested: feats.length };
}

let failed = false;

for (const { penndot, layer, codeField, expect, label } of PAIRS) {
  const meta = await (await fetch(`${PENNDOT}/${penndot}?f=json`, { headers: UA })).json();
  const countUrl = `${PENNDOT}/${penndot}/query?where=1%3D1&returnCountOnly=true&f=json`;
  const { count } = await (await fetch(countUrl, { headers: UA })).json();
  console.log(`\n=== ${label} — TIGER 2024 vs PennDOT "${meta.name}" (${count} features) ===`);
  if (count !== expect) {
    console.log(`  🔴 PennDOT holds ${count} ${label} districts, expected ${expect}`);
    failed = true;
  }

  const now = await readVintage('2024', layer, codeField);
  if (now.length !== expect) {
    console.log(`  🔴 TIGER 2024 holds ${now.length} polygons, expected ${expect}`);
    failed = true;
  }
  const r = await sweep(now, penndot);
  const lsy = [...new Set(now.map((f) => f.lsy))].join(',');
  console.log(`  TIGER 2024 (LSY ${lsy}): ${r.agree}/${r.tested} agree · ${r.differ.length} differ`);
  if (r.differ.length) {
    console.log('    ' + r.differ.slice(0, 10).join('\n    '));
    failed = true;
  }

  const old = await readVintage('2018', layer, codeField);
  const c = await sweep(old, penndot);
  const changed = c.tested - c.agree;
  console.log(`  CONTROL — TIGER 2018 (the 2012 plan): ${c.agree}/${c.tested} agree · ${changed} differ`);
  if (changed === 0) {
    console.log(`    🔴 THE CONTROL DID NOT FAIL. The 2012 and 2022 ${label} maps cannot agree everywhere;`);
    console.log('       a sweep that passes on both is not reading what it claims to read.');
    failed = true;
  } else {
    console.log(`    ✅ the control failed as required on ${changed} district(s) — the sweep tells the maps apart`);
  }
}

console.log(failed ? '\nFAIL' : '\nOK — TIGER 2024 FIPS 42 carries the 2022 LRC Final Plan, on every district.');
process.exit(failed ? 1 : 0);
