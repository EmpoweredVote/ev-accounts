#!/usr/bin/env node
/**
 * verify-oh-tiger-vintage.mjs — Knight program, wave OH-1.
 *
 * Proves which redistricting plan the TIGER FIPS 39 legislative layers carry, against an
 * authority that is not the Census Bureau.
 *
 * 🔴 WHY A COUNT CANNOT DO THIS. Ohio has had 99 House and 33 Senate districts for decades,
 * so every Ohio plan ever drawn has exactly the shape TIGER 2024 has. The 2021, 2022 and
 * 2023 plans are all 99/33. A count, a shape check and a "no ZZZ pseudo-district" check
 * would wave all three through.
 *
 * THE AUTHORITY: the Ohio Secretary of State publishes the adopted plan's own shapefiles at
 * ohiosos.gov/elections/district-maps, named `2024-2032-hd-shapefile.zip` and
 * `2024-2032-sd-shapefile.zip`. Their members are named
 * "Corrected Sept 29 2023 Unified Bipartisan Redistricting Plan HD SHP" — the Ohio
 * Redistricting Commission's map, adopted 2023-09-26 and corrected 2023-09-29, upheld by the
 * Ohio Supreme Court in November 2023, governing from the 2024 election through 2030. That is
 * the state drawing its own districts, not a Census mirror.
 *
 * 🔴 THE SECRETARY OF STATE IS BEHIND A WAF AND THIS SCRIPT CANNOT FETCH THROUGH IT.
 * Measured 2026-09-23: `ohiosos.gov` answers **HTTP 403 with a ~1.25 MB HTML challenge page**
 * to a bare request, to a browser User-Agent alone, and to a full Chrome header set with a
 * same-origin Referer — the three shapes that work elsewhere in this repo. Both asset URLs
 * returned a challenge page of **identical size**, which is the tell: a uniform answer is a
 * broken detector, not a finding. A real browser gets HTTP 200 and `application/zip`.
 * ▶ So the two zips must be fetched in Playwright and handed to this script with `--sos-dir`.
 * The script refuses to guess: if they are absent it prints the exact retrieval steps and
 * exits 1 rather than falling back to a Census-only check, which would prove nothing.
 *
 * 🔴 AND OHIO'S OWN GIS SERVICE IS THE TRAP, NOT THE ANSWER. The service a search puts first,
 * geo.oit.ohio.gov/arcgis/rest/services/OhioHouseSenateDistricts/MapServer, has a layer 1
 * titled "Ohio House Districts (2012- 2022)" — the SUPERSEDED map, named so that it invites
 * exactly this use. It also failed to connect on both 443 and 80 when measured. A layer's
 * title is not its vintage.
 *
 * THE TEST: every TIGER polygon is located at its own published internal point
 * (INTPTLAT/INTPTLON) inside the SOS plan, and the district number must match.
 *
 * THE CONTROL: the identical comparison is re-run against TIGER 2022, which carries the
 * superseded plan and MUST disagree. A verifier that cannot fail has proved nothing.
 * Measured 2026-09-23: 2022 disagrees on 4 of 33 Senate and 18 of 99 House — and note that
 * 29 of 33 and 81 of 99 still AGREE, which is precisely why the wrong map survives a count.
 * Among the disagreements, Senate 27 and 28 swap, and Akron sits in one of them.
 *
 * Usage:  node scripts/verify-oh-tiger-vintage.mjs --sos-dir <dir> [--workdir <dir>]
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
const SOS_DIR = argOf('--sos-dir');
const WORKDIR = argOf('--workdir') ?? fs.mkdtempSync(path.join(os.tmpdir(), 'oh-tiger-'));
fs.mkdirSync(WORKDIR, { recursive: true });

const SOS_FILES = {
  sldu: '2024-2032-sd-shapefile.zip',
  sldl: '2024-2032-hd-shapefile.zip',
};

const PAIRS = [
  { layer: 'sldu', codeField: 'SLDUST', expect: 33, label: 'Senate', control: '2022' },
  { layer: 'sldl', codeField: 'SLDLST', expect: 99, label: 'House', control: '2022' },
];

function howToGetTheZips() {
  console.error(
    '\n🔴 The Ohio Secretary of State shapefiles were not supplied, and this script cannot\n' +
    '   fetch them: ohiosos.gov answers 403 with an HTML challenge page to every non-browser\n' +
    '   request shape (bare, UA-only, and full Chrome headers with Referer).\n\n' +
    '   Fetch them once in Playwright, then re-run with --sos-dir:\n\n' +
    '     1. Navigate to https://www.ohiosos.gov/elections/district-maps\n' +
    '     2. In the page context, fetch each asset and save the bytes:\n' +
    '          https://www.ohiosos.gov/assets/2024-2032-sd-shapefile.zip\n' +
    '          https://www.ohiosos.gov/assets/2024-2032-hd-shapefile.zip\n' +
    '     3. Confirm each is a real archive (magic bytes PK\\x03\\x04, ~1.0 MB and ~1.8 MB)\n' +
    '        and NOT the challenge page — the two challenge pages are the SAME SIZE.\n' +
    '     4. node scripts/verify-oh-tiger-vintage.mjs --sos-dir <dir>\n'
  );
}

function download(url, dest) {
  return new Promise((resolve, reject) => {
    const req = https.get(url, { headers: { 'User-Agent': 'Mozilla/5.0 ev-accounts-knight' } }, (res) => {
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

const pad3 = (v) => String(parseInt(String(v), 10)).padStart(3, '0');

async function tigerFeatures(year, layer) {
  const url = `https://www2.census.gov/geo/tiger/TIGER${year}/${layer.toUpperCase()}/tl_${year}_39_${layer}.zip`;
  const zip = path.join(WORKDIR, `tl_${year}_39_${layer}.zip`);
  if (!fs.existsSync(zip)) await download(url, zip);
  return readFeatures(extract(zip, path.join(WORKDIR, `tl_${year}_39_${layer}`)));
}

/** Locate every TIGER polygon's own internal point inside the reference plan. */
function compare(tiger, reference, codeField) {
  let agree = 0;
  const disagree = [];
  let ambiguous = 0;
  for (const f of tiger) {
    const p = f.properties;
    const x = parseFloat(p.INTPTLON);
    const y = parseFloat(p.INTPTLAT);
    const mine = pad3(p[codeField]);
    const hits = reference
      .filter((r) => contains(r.geometry, x, y))
      .map((r) => pad3(r.properties.DISTRICT));
    if (hits.length !== 1) { ambiguous++; continue; }
    if (hits[0] === mine) agree++;
    else disagree.push(`${mine}->${hits[0]}`);
  }
  return { agree, disagree, ambiguous, total: tiger.length };
}

async function main() {
  if (!SOS_DIR) { howToGetTheZips(); process.exit(1); }

  let ok = true;
  for (const { layer, codeField, expect, label, control } of PAIRS) {
    const sosZip = path.join(SOS_DIR, SOS_FILES[layer]);
    if (!fs.existsSync(sosZip)) {
      console.error(`🔴 missing ${sosZip}`);
      howToGetTheZips();
      process.exit(1);
    }
    const head = Buffer.alloc(4);
    const fd = fs.openSync(sosZip, 'r');
    fs.readSync(fd, head, 0, 4, 0);
    fs.closeSync(fd);
    if (head.toString('latin1') !== 'PK\u0003\u0004') {
      console.error(`🔴 ${sosZip} is not a zip — this is the WAF challenge page, not the data.`);
      howToGetTheZips();
      process.exit(1);
    }

    const ref = await readFeatures(extract(sosZip, path.join(WORKDIR, `sos_${layer}`)));
    if (ref.length !== expect) {
      console.error(`🔴 ${label}: SOS plan holds ${ref.length} districts, expected ${expect}. Stop.`);
      ok = false;
      continue;
    }

    const cand = await tigerFeatures('2024', layer);
    const r = compare(cand, ref, codeField);
    const pass = r.agree === expect && r.disagree.length === 0 && r.ambiguous === 0;
    console.log(
      `${pass ? '🟢' : '🔴'} ${label} — TIGER 2024 vs SOS corrected 2023 plan: ` +
      `${r.total} polygons, AGREE ${r.agree}, DISAGREE ${r.disagree.length}, ambiguous ${r.ambiguous}`
    );
    if (r.disagree.length) console.log(`   disagreements (tiger->sos): ${r.disagree.join(', ')}`);
    if (!pass) ok = false;

    const ctrlFeats = await tigerFeatures(control, layer);
    const c = compare(ctrlFeats, ref, codeField);
    const ctrlFailedAsRequired = c.disagree.length > 0;
    console.log(
      `${ctrlFailedAsRequired ? '🟢' : '🔴'} ${label} — CONTROL, TIGER ${control} (superseded plan): ` +
      `AGREE ${c.agree}, DISAGREE ${c.disagree.length}` +
      (ctrlFailedAsRequired ? ' — disagrees as required' : ' — DID NOT FAIL, the test proves nothing')
    );
    if (c.disagree.length) console.log(`   control disagreements (tiger->sos): ${c.disagree.join(', ')}`);
    // 🔴 Note how many the control still AGREES on: that is the number a count would miss.
    console.log(`   ⚠ the control still agrees on ${c.agree} of ${c.total} — a count cannot date this map.`);
    if (!ctrlFailedAsRequired) ok = false;
  }

  console.log(ok
    ? '\n🟢 VINTAGE PROVED: TIGER 2024 FIPS 39 is the Corrected Sept 29 2023 Unified Bipartisan Redistricting Plan.'
    : '\n🔴 VINTAGE NOT PROVED — do not load.');
  process.exit(ok ? 0 : 1);
}

main().catch((e) => { console.error(e); process.exit(1); });
