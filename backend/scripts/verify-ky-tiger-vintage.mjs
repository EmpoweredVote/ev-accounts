#!/usr/bin/env node
/**
 * verify-ky-tiger-vintage.mjs — Knight program, wave KY-1.
 *
 * Proves which redistricting plan the TIGER FIPS 21 legislative layers carry, against an
 * authority that is not the Census Bureau.
 *
 * THE AUTHORITY: the Kentucky Legislative Research Commission — the legislature's own agency,
 * which draws these districts — publishes them at
 * kygisserver.ky.gov/.../Ky_Legislative_Districts_WGS84WM/MapServer, layer 0 House and layer 1
 * Senate. The service's own `copyrightText` is "Legislative Research Commission". That is the
 * body publishing its own districts, not a Census mirror. It answers a plain HTTPS request: no
 * WAF, no Playwright, unlike Ohio's Secretary of State.
 *
 * 🔴🔴 KENTUCKY GIVES NO STRUCTURAL DISCRIMINATOR AT ALL, AND THAT IS THE POINT OF THIS FILE.
 * North Dakota could be dated by its own code set — 49 House polygons is HB 1504, 48 is the
 * remedial plan. Kentucky is 38 Senate and 100 House in TIGER 2022, 2023, 2024 AND 2025, with
 * no 'ZZZ', no '000', no letter suffixes, and codes contiguous 001..038 and 001..100 in every
 * one. Measured 2026-09-26 by parsing the .dbf inside each zip directly. A count check, a code-set
 * check and a contiguity check ALL pass every vintage. Nothing about the file dates the map.
 *
 * ⚠ AND THE ONE FIELD THAT LOOKS LIKE A DISCRIMINATOR IS MISLEADING. LSY (legislative session
 * year) reads 2022 in TIGER 2022/2023 and 2024 in TIGER 2024/2025. That is a Census bookkeeping
 * refresh, NOT a new plan:
 *   - ALAND changes by at most 0.0049% (Senate) and 0.0306% (House), median ~0.0000% — noise
 *     from routine re-digitization of the underlying county and water lines.
 *   - Every TIGER 2024 internal point falls inside the SAME TIGER 2022 district: 38/38 and
 *     100/100, 0 moved, 0 not found.
 * 🔴 THAT UNIFORM ANSWER WAS CONTROLLED BEFORE IT WAS BELIEVED. The identical comparison run
 * over North Dakota — a state known to have been redistricted between those vintages — reports
 * Senate 015->009 and House 015->09B, 009->09A, reproducing exactly the two districts the
 * Turtle Mountain remedial order moved. The method can see a real plan change. It sees none here.
 *
 * WHY THERE IS ONLY ONE PLAN. Kentucky's 2022 maps are HB 2 (state House, enacted over veto
 * 2022-01-20) and SB 2 (state Senate, law without signature 2022-01-21). Graham v. Adams
 * challenged HB 2 and the congressional SB 3; the Kentucky Supreme Court held on 2023-12-14 that
 * partisan-gerrymandering claims ARE justiciable under the Kentucky Constitution but upheld both
 * plans. No remedial map was ever ordered, and SB 2 was never challenged. So both legislative
 * maps have stood unchanged since 2022 and govern the 2026 election.
 * ▶ THIS IS WHY TIGER 2022 AGREEING IS A PASS, NOT A FAILURE. In North Dakota the old vintage
 * MUST disagree. In Kentucky it MUST agree, and this script asserts that direction explicitly —
 * an expectation that is only meaningful because it is stated in advance.
 *
 * 🔴 A KENTUCKY DISTRICT CODE IS NOT AN INTEGER ON THE AUTHORITY SIDE. The LRC serves
 * District = 'H001'/'S001' (letter-prefixed) alongside DistrictID = '001'. `parseInt('H001')` is
 * NaN, not 1 — the same class of defect as North Dakota's '04A' and Minnesota's '08A', where a
 * numeric cast silently collapses or drops a district. This script matches on DistrictID and
 * never casts a code to a number.
 *
 * 🔴 THE geo_id COLLISION LANDS ON THIS SLICE'S OWN COUNTY. Loaded geo_ids run 21001..21038
 * (sldu) and 21001..21100 (sldl), while Kentucky's 120 counties are 21001..21239 odd. 19 counties
 * collide with the Senate range and 50 with the House range — and '21067' is Fayette County AND
 * House District 67, the county this whole slice is about. Grand Forks escaped the same collision
 * only by luck of odd numbering. Every join must pair geo_id with mtfcc/district_type.
 *
 * THE CONTROL: the identical comparison is re-run with the House points against the SENATE
 * authority layer, which must disagree. A verifier that cannot fail has proved nothing. Measured
 * 2026-09-26: 3 of 100 agree, and those three are numeric coincidences, not geography.
 *
 * Usage:  node scripts/verify-ky-tiger-vintage.mjs [--vintage 2024] [--workdir <dir>]
 * Exit:   0 proof complete AND the control failed as required; 1 otherwise.
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
const VINTAGE = argOf('--vintage') ?? '2024';
const PRIOR_VINTAGE = '2022';
const WORKDIR = argOf('--workdir') ?? fs.mkdtempSync(path.join(os.tmpdir(), 'ky-tiger-'));
fs.mkdirSync(WORKDIR, { recursive: true });

const AUTHORITY_BASE =
  'https://kygisserver.ky.gov/arcgis/rest/services/WGS84WM_Services/' +
  'Ky_Legislative_Districts_WGS84WM/MapServer';
/** layer 0 = House, layer 1 = Senate. outSR=4326 is load-bearing on every ArcGIS fetch. */
const AUTHORITY_LAYER = { sldl: 0, sldu: 1 };
const EXPECTED = { sldu: 38, sldl: 100 };
const CHAMBER = { sldu: 'Senate', sldl: 'House' };

const fetchBuffer = (url) =>
  new Promise((resolve, reject) => {
    const chunks = [];
    const go = (u, depth = 0) => {
      if (depth > 5) return reject(new Error(`too many redirects: ${url}`));
      https
        .get(u, { headers: { 'User-Agent': 'ev-accounts-knight/1.0' } }, (res) => {
          if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
            res.resume();
            return go(new URL(res.headers.location, u).toString(), depth + 1);
          }
          if (res.statusCode !== 200) {
            res.resume();
            return reject(new Error(`HTTP ${res.statusCode} for ${u}`));
          }
          res.on('data', (d) => chunks.push(d));
          res.on('end', () => resolve(Buffer.concat(chunks)));
        })
        .on('error', reject);
    };
    go(url);
  });

/** Ray casting. Holes are respected: a point inside an inner ring is outside the polygon. */
const ringHas = (pt, ring) => {
  let inside = false;
  for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    const [xi, yi] = ring[i];
    const [xj, yj] = ring[j];
    if ((yi > pt[1]) !== (yj > pt[1]) && pt[0] < ((xj - xi) * (pt[1] - yi)) / (yj - yi) + xi) {
      inside = !inside;
    }
  }
  return inside;
};
const polyHas = (pt, poly) => {
  if (!ringHas(pt, poly[0])) return false;
  for (let k = 1; k < poly.length; k++) if (ringHas(pt, poly[k])) return false;
  return true;
};
const geomHas = (pt, geom) => {
  if (!geom) return false;
  if (geom.type === 'Polygon') return polyHas(pt, geom.coordinates);
  if (geom.type === 'MultiPolygon') return geom.coordinates.some((p) => polyHas(pt, p));
  return false;
};

/** TIGER internal points. INTPTLAT/INTPTLON carry a leading '+' that parseFloat tolerates only
 *  after it is stripped on some platforms — strip it explicitly rather than rely on that. */
async function readTiger(vintage, layer) {
  const base = `tl_${vintage}_21_${layer}`;
  const zipPath = path.join(WORKDIR, `${base}.zip`);
  if (!fs.existsSync(zipPath)) {
    const url =
      `https://www2.census.gov/geo/tiger/TIGER${vintage}/${layer.toUpperCase()}/${base}.zip`;
    fs.writeFileSync(zipPath, await fetchBuffer(url));
  }
  const zip = new AdmZip(zipPath);
  for (const ext of ['.shp', '.dbf', '.shx']) {
    const entry = zip.getEntry(base + ext);
    if (!entry) throw new Error(`${base}${ext} missing from ${base}.zip`);
    fs.writeFileSync(path.join(WORKDIR, base + ext), entry.getData());
  }
  const field = layer === 'sldu' ? 'SLDUST' : 'SLDLST';
  const src = await shapefile.open(
    path.join(WORKDIR, base + '.shp'),
    path.join(WORKDIR, base + '.dbf'),
  );
  const rows = [];
  for (;;) {
    const r = await src.read();
    if (r.done) break;
    const p = r.value.properties;
    rows.push({
      code: String(p[field]),
      lsy: String(p.LSY ?? ''),
      mtfcc: String(p.MTFCC ?? ''),
      aland: Number(p.ALAND),
      lat: parseFloat(String(p.INTPTLAT).replace('+', '')),
      lon: parseFloat(String(p.INTPTLON).replace('+', '')),
      geom: r.value.geometry,
    });
  }
  return rows;
}

async function readAuthority(layer) {
  const id = AUTHORITY_LAYER[layer];
  const url =
    `${AUTHORITY_BASE}/${id}/query?where=1%3D1&outFields=District,DistrictID` +
    `&outSR=4326&returnGeometry=true&f=geojson`;
  const body = JSON.parse((await fetchBuffer(url)).toString('utf8'));
  if (body.error) throw new Error(`authority error: ${JSON.stringify(body.error)}`);
  // 🔴 A TRUNCATED ANSWER IS A CLEAN HTTP 200. Refuse a paged response rather than compare
  // against a partial plan.
  if (body.exceededTransferLimit) {
    throw new Error(`authority layer ${id} paged the response — refusing a partial plan`);
  }
  return (body.features ?? []).map((f) => ({
    code: String(f.properties.DistrictID),
    label: String(f.properties.District),
    geom: f.geometry,
  }));
}

/** Locate every point in `points` inside `polys` and report agreement on the district code. */
function compare(points, polys, label) {
  let agree = 0;
  const moved = [];
  let notFound = 0;
  for (const d of points) {
    const pt = [d.lon, d.lat];
    const hit = polys.filter((o) => geomHas(pt, o.geom)).map((o) => o.code);
    if (hit.length === 0) {
      notFound++;
      continue;
    }
    if (hit.includes(d.code)) agree++;
    else moved.push(`${d.code}->${hit.join('/')}`);
  }
  const line =
    `  ${label}: agree=${agree}/${points.length} moved=${moved.length} notFound=${notFound}`;
  console.log(line);
  if (moved.length) {
    console.log(`      ${moved.slice(0, 12).join('  ')}${moved.length > 12 ? ' …' : ''}`);
  }
  return { agree, moved: moved.length, notFound, total: points.length };
}

(async () => {
  let ok = true;
  console.log(`KY-1 TIGER vintage proof — workdir ${WORKDIR}`);
  console.log(`Authority: Kentucky Legislative Research Commission (${AUTHORITY_BASE})\n`);

  const authority = {};
  const current = {};
  const prior = {};

  for (const layer of ['sldu', 'sldl']) {
    authority[layer] = await readAuthority(layer);
    current[layer] = await readTiger(VINTAGE, layer);
    prior[layer] = await readTiger(PRIOR_VINTAGE, layer);

    const a = authority[layer];
    const t = current[layer];
    const codes = t.map((r) => r.code).sort();
    const contiguous =
      new Set(codes).size === EXPECTED[layer] &&
      codes.every((c, i) => c === String(i + 1).padStart(3, '0'));

    console.log(`${CHAMBER[layer]} (${layer}):`);
    console.log(
      `  TIGER ${VINTAGE}: n=${t.length} LSY=${[...new Set(t.map((r) => r.lsy))].join(',')} ` +
        `MTFCC=${[...new Set(t.map((r) => r.mtfcc))].join(',')} contiguous001..=${contiguous}`,
    );
    console.log(`  authority: n=${a.length} (sample ${a.slice(0, 3).map((x) => x.label).join(',')})`);

    if (t.length !== EXPECTED[layer]) {
      console.log(`  🔴 expected ${EXPECTED[layer]} TIGER records, got ${t.length}`);
      ok = false;
    }
    if (a.length !== EXPECTED[layer]) {
      console.log(`  🔴 expected ${EXPECTED[layer]} authority features, got ${a.length}`);
      ok = false;
    }
    if (!contiguous) {
      console.log(`  🔴 TIGER codes are not contiguous 001..${EXPECTED[layer]}`);
      ok = false;
    }
  }

  console.log(`\n— PROOF: TIGER ${VINTAGE} located inside the LRC plan —`);
  const proof = {};
  for (const layer of ['sldl', 'sldu']) {
    proof[layer] = compare(
      current[layer],
      authority[layer],
      `${CHAMBER[layer].padEnd(6)} TIGER${VINTAGE} -> LRC ${CHAMBER[layer]}`,
    );
    if (proof[layer].agree !== proof[layer].total) ok = false;
  }

  console.log(
    `\n— TIGER ${PRIOR_VINTAGE} MUST ALSO AGREE: Kentucky has one plan since 2022 (HB 2 / SB 2),` +
      `\n  upheld in Graham v. Adams 2023-12-14 with no remedial map ordered. —`,
  );
  for (const layer of ['sldl', 'sldu']) {
    const r = compare(
      prior[layer],
      authority[layer],
      `${CHAMBER[layer].padEnd(6)} TIGER${PRIOR_VINTAGE} -> LRC ${CHAMBER[layer]}`,
    );
    if (r.agree !== r.total) {
      console.log(
        `  🔴 TIGER ${PRIOR_VINTAGE} DISAGREES. That would mean Kentucky was redistricted after ` +
          `all, and this file's premise is wrong. Stop and find the instrument before loading.`,
      );
      ok = false;
    }
  }

  console.log('\n— CONTROL: House points against the SENATE layer. MUST disagree. —');
  const control = compare(current.sldl, authority.sldu, 'House  TIGER -> LRC Senate');
  const controlFailedAsRequired = control.agree < control.total * 0.5;
  if (!controlFailedAsRequired) {
    console.log(
      '  🔴 THE CONTROL DID NOT FAIL. The comparison is not discriminating, so the agreement ' +
        'above proves nothing. Fix the verifier before trusting any result.',
    );
    ok = false;
  } else {
    console.log(
      `  control failed as required (${control.agree}/${control.total} agree — numeric ` +
        'coincidence, not geography)',
    );
  }

  console.log(`\nVERDICT: ${ok ? 'PASS' : 'FAIL'}`);
  process.exit(ok ? 0 : 1);
})().catch((e) => {
  console.error(`\n🔴 ${e.message}`);
  process.exit(1);
});
