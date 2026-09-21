#!/usr/bin/env node
/**
 * verify-sc-tiger-vintage.mjs — Knight program, wave SC-1.
 *
 * Proves which redistricting plan the TIGER FIPS 45 legislative layers carry, against an
 * authority that is not the Census Bureau.
 *
 * 🔴 WHY A COUNT CANNOT DO THIS, AND WHY SOUTH CAROLINA IS WORSE THAN PENNSYLVANIA.
 * S.C. Const. Art. III §§ 1–6 fixes the chambers at 124 and 46, so every South Carolina plan
 * ever drawn has exactly that shape — the PA problem. On top of that, South Carolina redrew
 * its House TWICE in one year: Act 118 (2022-01-27) and then Act 226 (2022-06-17), the
 * remedial plan the Revenue and Fiscal Affairs Office marks "effective for the 2024
 * election". So a 124-polygon file is consistent with THREE different House maps, and the
 * two recent ones are five months apart. The Senate was drawn once, by Act 118.
 *
 * THE TEST: each TIGER polygon is queried at its own internal point against the State of
 * South Carolina's own ArcGIS server, gis.state.sc.us, whose House_Districts and
 * Senate_Districts layers are maintained by the Revenue and Fiscal Affairs Office — the
 * agency that draws the state's jurisdictional maps. It is a state authority, not a Census
 * mirror.
 *
 * THE CONTROLS: the identical comparison is re-run against older TIGER vintages, which MUST
 * disagree.
 *   · House, TIGER 2022 — Act 118, superseded five months later by Act 226. This is the
 *     control that matters: it is the one wrong map a count, a shape check and even a 2012
 *     comparison would all wave through.
 *   · House and Senate, TIGER 2018 — the 2012 plan.
 * A verifier that cannot fail has proved nothing. MN-6 shipped a portrait check that
 * reported 0 broken while testing none of the rows in question, and the count was the tell.
 *
 * Usage:  node scripts/verify-sc-tiger-vintage.mjs [--workdir <dir>]
 * Exit:   0 agreement complete and every control failed as required; 1 otherwise.
 */
import https from 'https';
import fs from 'fs';
import os from 'os';
import path from 'path';
import AdmZip from 'adm-zip';
import * as shapefile from 'shapefile';

const argv = process.argv.slice(2);
const wdIdx = argv.indexOf('--workdir');
const WORKDIR = wdIdx >= 0 ? argv[wdIdx + 1] : fs.mkdtempSync(path.join(os.tmpdir(), 'sc-tiger-'));
fs.mkdirSync(WORKDIR, { recursive: true });

const RFA = 'https://gis.state.sc.us/arcgis/rest/services/Boundaries_Districts';
const UA = { 'User-Agent': 'Mozilla/5.0 ev-accounts-knight' };

// RFA service, TIGER layer, TIGER district-code field, seats fixed by Art. III, control vintages.
const PAIRS = [
  {
    service: 'House_Districts',
    layer: 'sldl',
    codeField: 'SLDLST',
    expect: 124,
    label: 'House',
    // 2022 is Act 118, superseded by Act 226; 2018 is the 2012 plan.
    controls: ['2022', '2018'],
  },
  {
    service: 'Senate_Districts',
    layer: 'sldu',
    codeField: 'SLDUST',
    expect: 46,
    label: 'Senate',
    // The Senate was drawn once this cycle, so 2022 is expected to AGREE and is not a
    // control. Only the 2012 plan can be relied on to differ.
    controls: ['2018'],
  },
];

function download(url, dest) {
  return new Promise((resolve, reject) => {
    https
      .get(url, { headers: UA }, (res) => {
        if (res.statusCode !== 200) return reject(new Error(`HTTP ${res.statusCode} for ${url}`));
        const declared = Number(res.headers['content-length'] || 0);
        const ws = fs.createWriteStream(dest);
        let got = 0;
        res.on('data', (c) => {
          got += c.length;
        });
        res.pipe(ws);
        // 🔴 A clean 200 can carry a truncated body. Compare what was promised with what arrived.
        ws.on('finish', () =>
          declared && declared !== got
            ? reject(new Error(`TRUNCATED: content-length ${declared}, received ${got} — ${url}`))
            : resolve(),
        );
        ws.on('error', reject);
      })
      .on('error', reject);
  });
}

async function readVintage(vintage, layer, codeField) {
  const dir = path.join(WORKDIR, `${vintage}-${layer}`);
  if (!fs.existsSync(dir)) {
    const zip = path.join(WORKDIR, `${vintage}-${layer}.zip`);
    const url = `https://www2.census.gov/geo/tiger/TIGER${vintage}/${layer.toUpperCase()}/tl_${vintage}_45_${layer}.zip`;
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

async function askRfa(service, lon, lat, tries = 4) {
  const geometry = encodeURIComponent(
    JSON.stringify({ x: lon, y: lat, spatialReference: { wkid: 4326 } }),
  );
  const url =
    `${RFA}/${service}/FeatureServer/0/query?geometry=${geometry}&geometryType=esriGeometryPoint` +
    `&inSR=4326&spatialRel=esriSpatialRelIntersects&outFields=District_Num&returnGeometry=false&f=json`;
  for (let i = 0; i < tries; i++) {
    try {
      const r = await fetch(url, { headers: UA });
      const t = await r.text();
      // A WAF rejection can be HTTP 200 carrying HTML. Judge the body, never r.ok.
      if (!t.trim().startsWith('{')) throw new Error(`not JSON (HTTP ${r.status})`);
      const j = JSON.parse(t);
      if (j.error) throw new Error(JSON.stringify(j.error).slice(0, 120));
      return j.features.map((f) => String(Number(f.attributes.District_Num)));
    } catch (e) {
      if (i === tries - 1) throw e;
      await new Promise((res) => setTimeout(res, 500 * (i + 1)));
    }
  }
}

async function sweep(feats, service) {
  let agree = 0;
  const differ = [];
  const CONC = 6;
  for (let i = 0; i < feats.length; i += CONC) {
    const batch = feats.slice(i, i + CONC);
    const res = await Promise.all(batch.map((f) => askRfa(service, f.lon, f.lat)));
    res.forEach((got, k) => {
      const mine = String(Number(batch[k].code)); // TIGER pads: '072' is district 72
      if (got.length === 1 && got[0] === mine) agree++;
      else differ.push(`TIGER ${batch[k].code} -> RFA [${got.join('|') || 'none'}]`);
    });
  }
  return { agree, differ, tested: feats.length };
}

let failed = false;

for (const { service, layer, codeField, expect, label, controls } of PAIRS) {
  const meta = await (await fetch(`${RFA}/${service}/FeatureServer/0?f=json`, { headers: UA })).json();
  const countUrl = `${RFA}/${service}/FeatureServer/0/query?where=1%3D1&returnCountOnly=true&f=json`;
  const { count } = await (await fetch(countUrl, { headers: UA })).json();
  console.log(`\n=== ${label} — TIGER 2024 vs SC RFA "${meta.name}" (${count} features) ===`);
  if (count !== expect) {
    console.log(`  🔴 RFA holds ${count} ${label} districts, expected ${expect}`);
    failed = true;
  }

  const now = await readVintage('2024', layer, codeField);
  if (now.length !== expect) {
    console.log(`  🔴 TIGER 2024 holds ${now.length} polygons, expected ${expect}`);
    failed = true;
  }
  const r = await sweep(now, service);
  const lsy = [...new Set(now.map((f) => f.lsy))].join(',');
  console.log(`  TIGER 2024 (LSY ${lsy}): ${r.agree}/${r.tested} agree · ${r.differ.length} differ`);
  if (r.differ.length) {
    console.log('    ' + r.differ.slice(0, 10).join('\n    '));
    failed = true;
  }

  for (const vintage of controls) {
    const old = await readVintage(vintage, layer, codeField);
    const c = await sweep(old, service);
    const changed = c.tested - c.agree;
    const what = vintage === '2022' ? 'Act 118, superseded by Act 226' : 'the 2012 plan';
    console.log(
      `  CONTROL — TIGER ${vintage} (${what}): ${c.agree}/${c.tested} agree · ${changed} differ`,
    );
    if (changed === 0) {
      console.log(`    🔴 THE CONTROL DID NOT FAIL. TIGER ${vintage} and the map RFA publishes today`);
      console.log('       cannot agree everywhere; a sweep that passes on both is not reading what');
      console.log('       it claims to read.');
      failed = true;
    } else {
      console.log(
        `    ✅ the control failed as required on ${changed} district(s) — the sweep tells the maps apart`,
      );
      // Name them. "3 differ" is a number; the districts are the evidence, and for the
      // Act 118 control they are the whole reason this wave cannot trust a count.
      console.log('       ' + c.differ.slice(0, 25).join('\n       '));
    }
  }
}

console.log(
  failed
    ? '\nFAIL'
    : '\nOK — TIGER 2024 FIPS 45 carries the map South Carolina publishes today, on every district.',
);
process.exit(failed ? 1 : 0);
