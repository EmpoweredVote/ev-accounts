#!/usr/bin/env node
/**
 * verify-ks-tiger-vintage.mjs — Knight program, wave KS-1.
 *
 * Proves which redistricting plan the TIGER FIPS 20 legislative layers carry, against an
 * authority that is not the Census Bureau.
 *
 * THE AUTHORITY IS THE ENACTED PLAN FILE ITSELF, WHICH IS STRONGER THAN ANY OTHER SLICE HAS HAD.
 * The Kansas Legislative Research Department — the Legislature's own agency, which drew these
 * districts — publishes the enacted plans as shapefiles at klrd.gov:
 *   Senate  "Liberty 3"     klrd.gov/wp-content/uploads/2023/11/Liberty_3.zip
 *   House   "Free State 3F" klrd.gov/wp-content/uploads/2023/11/Freestate-3F.zip
 * Those two names are not a label this repo chose. They are the names the Kansas Supreme Court
 * uses for the two maps it reviewed: "the two maps at issue here—colloquially known as the Kansas
 * State Senate map 'Liberty 3' and the Kansas State House map 'Free State 3F'—were approved by
 * bipartisan majorities" (No. 125,083, slip op. at 3). Kentucky had to settle for the LRC's
 * current-geometry map service; Kansas publishes the passed artifact. Both answer a plain HTTPS
 * request: no WAF, no Playwright, unlike Ohio's Secretary of State.
 *
 * 🔴🔴 KANSAS GIVES NO STRUCTURAL DISCRIMINATOR, EXACTLY AS KENTUCKY DID. Measured 2026-09-26 by
 * parsing the .dbf inside each zip directly, TIGER 2022, 2023, 2024 and 2025 are all:
 *   sldu   40 records, MTFCC G5210, SLDUST '001'..'040', 0 letters, 0 zeros, contiguous
 *   sldl  125 records, MTFCC G5220, SLDLST '001'..'125', 0 letters, 0 zeros, contiguous
 * A count check, a code-set check and a contiguity check ALL pass every vintage. Nothing about the
 * file dates the map. North Dakota could be dated by its own code set; Kansas cannot.
 * ⚠ AND THE ONE FIELD THAT LOOKS LIKE A DISCRIMINATOR IS MISLEADING, THE SAME WAY IT WAS IN
 * KENTUCKY. LSY reads 2022 in TIGER 2022/2023 and 2024 in TIGER 2024/2025, which reads like a new
 * plan. It is a Census bookkeeping refresh: statewide ALAND moves from 211,753,641,384 to
 * 211,754,288,230 across all four vintages — 0.0003% — and every internal point stays put.
 *
 * 🔴🔴 THE CONTROL THAT MATTERS IS THE PRIOR PLAN, AND IT IS WHY THIS SCRIPT ASSERTS ZERO MOVED
 * RATHER THAN A PERCENTAGE. Kansas's previous map is the 2012 court-drawn plan (Essex v. Kobach,
 * 874 F. Supp. 2d 1069 (D. Kan. 2012)), carried by TIGER 2020. Run against the 2022 enacted plan
 * it still agrees:
 *   Senate  35 of 40  (87.5%)   — 5 districts moved
 *   House  112 of 125 (89.6%)   — 13 districts moved
 * ▶ SO A THRESHOLD TEST PASSES A DECADE-OLD SUPERSEDED MAP HERE. This reproduces North Dakota's
 * finding (92% passes a struck-down plan) inside Kansas, against the real prior plan rather than a
 * stale vintage. The discriminator is NOT the agreement rate — it is that the correct plan moves
 * EXACTLY ZERO districts and the wrong one does not. Anyone relaxing MOVED === 0 to "≥90% agree"
 * re-admits the 2012 map. Do not.
 *
 * 🔴 A KANSAS DISTRICT CODE IS PADDED ON ONE SIDE AND NOT THE OTHER. The authority serves
 * DISTRICT = '39' / '84' (unpadded); TIGER serves SLDUST/SLDLST = '039' / '084' (zero-padded to
 * three). A raw string compare agrees on NOTHING and looks exactly like a wrong vintage. Both
 * sides are verified numeric before they are normalised, and the check refuses a non-numeric code
 * rather than casting one — the family of defect that '04A' (ND), '08A' (MN) and 'H001' (KY) are.
 *
 * WHY THERE IS ONLY ONE PLAN. Both legislative maps live in ONE bill — Substitute for Senate Bill
 * 563 — not two. (ks.md said the House map was "HB 2736"; it is not, and there is no such House
 * map.) SB 563 was introduced 2022-03-14 carrying maps for both chambers; the House amended it on
 * 2022-03-21 to its own preferred House map, which is why the Free State 3F file carries an
 * internal date of 2022-03-21. Signed by Governor Kelly 2022-04-15, published in the Kansas
 * Register 2022-04-21. Kansas Constitution art. 10, § 1(b) then makes Supreme Court review
 * AUTOMATIC AND MANDATORY — the Attorney General must petition within 15 days, which distinguishes
 * Kansas from every other slice in this program, where review happens only if someone sues. AG
 * Schmidt petitioned 2022-04-25; the court announced 2022-05-18 and filed its opinion 2022-06-21,
 * upholding Sub. SB 563 in full and ordering no remedial map. The one intervenor, Senator Thomas
 * Holland, contested the procedure and the boundaries of Senate Districts 3 and 9 and lost.
 * ▶ SO TIGER 2022 AGREEING IS A PASS HERE, NOT A FAILURE — the Kentucky direction, the opposite of
 * North Dakota. One plan has governed since 2022 and governs the 2026 election. This script states
 * that expectation in advance and asserts it, because an expectation formed after the measurement
 * is not evidence.
 * ⚠ The 2025 congressional remap push is NOT a legislative-map event and must not be read as one.
 * Kansas Republicans tried to force a November 2025 special session to redraw the four US House
 * districts; House leadership ended the push on 2025-11-05 without a session, so no map of any
 * kind was enacted. Art. 10, § 1(a) puts the next legislative reapportionment in 2032.
 *
 * 🔴 THE geo_id COLLISION IS WITH COUNTIES, AS IN PA, SC, OH, ND AND KY. Loaded geo_ids will run
 * 20001..20040 (sldu) and 20001..20125 (sldl). Measured against production 2026-09-26: Kansas has
 * 105 county rows, geo_id 20001..20209, ALL odd-numbered — 20 of them collide with the Senate
 * range and 63 with the House range. Every join must pair geo_id with mtfcc/district_type; see
 * src/lib/geoIdGuard.ts.
 * 🟢 UNLIKE KENTUCKY, THIS SLICE'S OWN COUNTY ESCAPES: Sedgwick County is 20173, above both
 * ranges. Fayette County was 21067 and collided with House District 67. That is luck of the
 * numbering, not a property of the loader, so it changes nothing about the guard.
 *
 * THE TWO CONTROLS, both of which must fail as required or this script exits 1:
 *   1. WRONG CHAMBER — House points against the SENATE authority, and Senate points against the
 *      HOUSE authority. Measured 2026-09-26: 0 of 125 and 0 of 40. Kentucky's equivalent agreed
 *      3 of 100 by numeric coincidence; Kansas's chamber sizes (40 vs 125) leave no overlap.
 *   2. PRIOR PLAN — TIGER 2020, which carries the 2012 court-drawn map, against the 2022 enacted
 *      plan. Must move a non-zero number of districts in BOTH chambers. This is the control that
 *      proves the method can see a real Kansas plan change rather than merely reporting agreement.
 * A verifier that cannot fail has proved nothing.
 *
 * Usage:  node scripts/verify-ks-tiger-vintage.mjs [--vintage 2024] [--workdir <dir>] [--self-test]
 * Exit:   0 proof complete AND both controls failed as required; 1 otherwise.
 *         --self-test requires the 2012 plan to agree, so that run MUST exit 1. Watch it fail
 *         before trusting a green run — the two controls watch the COMPARISON fail, which is not
 *         the same as watching the ASSERTION fail.
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
/** Carries the 2012 court-drawn plan. Must DISAGREE. */
const PRIOR_PLAN_VINTAGE = '2020';
/** --self-test adds the 2012 plan to the set that is required to agree, so the PROOF gate must
 *  report a failure and exit 1. Run it before trusting a green run: a gate nobody has watched
 *  fail is not evidence that it fires. Controls 1 and 2 watch the COMPARISON fail; this watches
 *  the ASSERTION fail, which is a different thing. */
const SELF_TEST = argv.includes('--self-test');
/** Every vintage that must agree, because one plan has governed since 2022. */
const AGREEING_VINTAGES = SELF_TEST
  ? ['2022', '2023', '2024', '2025', PRIOR_PLAN_VINTAGE]
  : ['2022', '2023', '2024', '2025'];
const WORKDIR = argOf('--workdir') ?? fs.mkdtempSync(path.join(os.tmpdir(), 'ks-tiger-'));
fs.mkdirSync(WORKDIR, { recursive: true });

/** The Legislature's own agency publishes the enacted plan. Basenames inside each zip carry
 *  spaces and a "for KLRD TR" suffix — they are the publisher's, not ours, so they are matched
 *  by extension rather than by an assumed name. */
const AUTHORITY = {
  sldu: { url: 'https://klrd.gov/wp-content/uploads/2023/11/Liberty_3.zip', plan: 'Liberty 3' },
  sldl: { url: 'https://klrd.gov/wp-content/uploads/2023/11/Freestate-3F.zip', plan: 'Free State 3F' },
};
const EXPECTED = { sldu: 40, sldl: 125 };
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

/** 🔴 Never cast a district code to a number. Verify it is numeric, THEN normalise the padding —
 *  the authority is unpadded ('39') and TIGER is zero-padded ('039'). */
const normaliseCode = (raw, where) => {
  const s = String(raw);
  if (!/^\d+$/.test(s)) throw new Error(`${where}: non-numeric district code ${JSON.stringify(s)}`);
  return String(parseInt(s, 10));
};

async function readAuthority(layer) {
  const { url, plan } = AUTHORITY[layer];
  const zipPath = path.join(WORKDIR, `${layer}-authority.zip`);
  if (!fs.existsSync(zipPath)) fs.writeFileSync(zipPath, await fetchBuffer(url));
  const zip = new AdmZip(zipPath);
  const dir = path.join(WORKDIR, `${layer}-authority`);
  fs.mkdirSync(dir, { recursive: true });
  let stem = null;
  for (const entry of zip.getEntries()) {
    const ext = path.extname(entry.entryName).toLowerCase();
    if (!['.shp', '.dbf', '.shx', '.prj'].includes(ext)) continue;
    fs.writeFileSync(path.join(dir, path.basename(entry.entryName)), entry.getData());
    if (ext === '.shp') stem = path.basename(entry.entryName, entry.entryName.slice(-4));
  }
  if (!stem) throw new Error(`${plan}: no .shp inside ${url}`);
  const src = await shapefile.open(path.join(dir, `${stem}.shp`), path.join(dir, `${stem}.dbf`));
  const rows = [];
  for (;;) {
    const r = await src.read();
    if (r.done) break;
    const p = r.value.properties;
    rows.push({
      code: normaliseCode(p.DISTRICT, `${plan} DISTRICT`),
      raw: String(p.DISTRICT),
      members: Number(p.MEMBERS),
      geom: r.value.geometry,
    });
  }
  return { plan, rows };
}

/** TIGER internal points. INTPTLAT/INTPTLON carry a leading '+' that parseFloat tolerates only
 *  after it is stripped on some platforms — strip it explicitly rather than rely on that. */
async function readTiger(vintage, layer) {
  const base = `tl_${vintage}_20_${layer}`;
  const zipPath = path.join(WORKDIR, `${base}.zip`);
  if (!fs.existsSync(zipPath)) {
    const url = `https://www2.census.gov/geo/tiger/TIGER${vintage}/${layer.toUpperCase()}/${base}.zip`;
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
      code: normaliseCode(p[field], `TIGER ${vintage} ${field}`),
      raw: String(p[field]),
      lsy: String(p.LSY ?? ''),
      mtfcc: String(p.MTFCC ?? ''),
      aland: Number(p.ALAND),
      lat: parseFloat(String(p.INTPTLAT).replace('+', '')),
      lon: parseFloat(String(p.INTPTLON).replace('+', '')),
    });
  }
  return rows;
}

/** Locate every TIGER internal point inside the authority's polygons and report agreement. */
function compare(points, polys, label) {
  let agree = 0;
  let notFound = 0;
  let ambiguous = 0;
  const moved = [];
  for (const d of points) {
    const hits = polys.filter((o) => geomHas([d.lon, d.lat], o.geom)).map((o) => o.code);
    if (hits.length === 0) {
      notFound++;
      continue;
    }
    if (hits.length > 1) ambiguous++;
    if (hits.includes(d.code)) agree++;
    else moved.push(`${d.raw}->${hits.join('|')}`);
  }
  const pct = ((agree / points.length) * 100).toFixed(1);
  console.log(
    `  ${label}: agree ${agree}/${points.length} (${pct}%) · moved ${moved.length} · ` +
      `notFound ${notFound} · ambiguous ${ambiguous}`,
  );
  if (moved.length) {
    console.log(`      moved: ${moved.slice(0, 15).join(', ')}${moved.length > 15 ? ` … (+${moved.length - 15})` : ''}`);
  }
  return { agree, total: points.length, moved: moved.length, notFound, ambiguous };
}

async function main() {
  const failures = [];
  console.log(`KS TIGER vintage proof — workdir ${WORKDIR}`);
  if (SELF_TEST) {
    console.log(
      `⚠ --self-test: TIGER ${PRIOR_PLAN_VINTAGE} (the 2012 plan) has been added to the set that ` +
        'must agree.\n  This run is REQUIRED to fail. A green --self-test means the gate does not fire.',
    );
  }
  console.log('');

  // ---- The authority ------------------------------------------------------------------------
  console.log('AUTHORITY — the enacted plans, published by the Kansas Legislative Research Department');
  const auth = {};
  for (const layer of ['sldu', 'sldl']) {
    const a = await readAuthority(layer);
    auth[layer] = a;
    const singleMember = a.rows.every((r) => r.members === 1);
    console.log(
      `  ${CHAMBER[layer]} "${a.plan}": ${a.rows.length} polygons · MEMBERS all 1: ${singleMember} · ` +
        `codes unpadded (e.g. '${a.rows[0].raw}')`,
    );
    if (a.rows.length !== EXPECTED[layer]) {
      failures.push(`${a.plan} has ${a.rows.length} polygons, expected ${EXPECTED[layer]}`);
    }
    // Both chambers are single-member in Kansas, so polygon count IS seat count — unlike ND and SD.
    if (!singleMember) failures.push(`${a.plan} carries a multi-member district; seat count != polygon count`);
    const codes = new Set(a.rows.map((r) => r.code));
    for (let i = 1; i <= EXPECTED[layer]; i++) {
      if (!codes.has(String(i))) failures.push(`${a.plan} is missing district ${i}`);
    }
  }

  // ---- Nothing structural dates the map -----------------------------------------------------
  console.log('\nSTRUCTURE — recorded to show it CANNOT date the map, not as evidence that it can');
  for (const layer of ['sldu', 'sldl']) {
    for (const v of AGREEING_VINTAGES) {
      const rows = await readTiger(v, layer);
      const lsy = [...new Set(rows.map((r) => r.lsy))].join('/');
      const sorted = rows.map((r) => r.raw).sort();
      console.log(
        `  TIGER ${v} ${layer}: ${rows.length} records · LSY=${lsy} · ` +
          `codes ${sorted[0]}..${sorted[sorted.length - 1]} · ALAND=${rows.reduce((a, r) => a + r.aland, 0)}`,
      );
      if (rows.length !== EXPECTED[layer]) {
        failures.push(`TIGER ${v} ${layer} has ${rows.length} records, expected ${EXPECTED[layer]}`);
      }
    }
  }

  // ---- The proof ----------------------------------------------------------------------------
  console.log('\nPROOF — every TIGER vintage since the plan was enacted must agree EXACTLY');
  for (const v of AGREEING_VINTAGES) {
    for (const layer of ['sldu', 'sldl']) {
      const r = compare(
        await readTiger(v, layer),
        auth[layer].rows,
        `TIGER ${v} ${layer} vs ${auth[layer].plan}`.padEnd(40),
      );
      // 🔴 ZERO MOVED, never a percentage. The 2012 plan scores 87.5% / 89.6% below.
      if (r.moved !== 0 || r.notFound !== 0 || r.agree !== EXPECTED[layer]) {
        failures.push(
          `TIGER ${v} ${layer} does not carry ${auth[layer].plan}: ` +
            `${r.agree}/${r.total} agree, ${r.moved} moved, ${r.notFound} not found`,
        );
      }
    }
  }

  // ---- Control 1: wrong chamber -------------------------------------------------------------
  console.log('\nCONTROL 1 — wrong chamber. The comparison MUST fail when pointed at the other map.');
  for (const [pointLayer, polyLayer] of [
    ['sldl', 'sldu'],
    ['sldu', 'sldl'],
  ]) {
    const r = compare(
      await readTiger(VINTAGE, pointLayer),
      auth[polyLayer].rows,
      `TIGER ${VINTAGE} ${pointLayer} vs ${auth[polyLayer].plan}`.padEnd(40),
    );
    if (r.agree !== 0) {
      // A handful of numeric coincidences would be tolerable (Kentucky had 3 of 100); wholesale
      // agreement would mean the comparison is not reading the geometry at all.
      if (r.agree > EXPECTED[pointLayer] * 0.1) {
        failures.push(`control 1 did not fail: ${pointLayer} agrees ${r.agree}/${r.total} with the wrong chamber`);
      } else {
        console.log(`      (${r.agree} numeric coincidence(s) — tolerated, as in KY-1)`);
      }
    }
  }

  // ---- Control 2: the prior plan ------------------------------------------------------------
  console.log(
    `\nCONTROL 2 — the 2012 court-drawn plan (TIGER ${PRIOR_PLAN_VINTAGE}). It MUST move districts.\n` +
      '  🔴 Read the agreement RATE here before trusting any threshold: a superseded decade-old map\n' +
      '     still scores ~88%. Only "moved === 0" separates the plans.',
  );
  for (const layer of ['sldu', 'sldl']) {
    const r = compare(
      await readTiger(PRIOR_PLAN_VINTAGE, layer),
      auth[layer].rows,
      `TIGER ${PRIOR_PLAN_VINTAGE} ${layer} vs ${auth[layer].plan}`.padEnd(40),
    );
    if (r.moved === 0) {
      failures.push(
        `control 2 did not fail: the 2012 plan moved 0 ${CHAMBER[layer]} districts, so this ` +
          'comparison cannot tell two real Kansas plans apart',
      );
    }
  }

  console.log('');
  if (failures.length) {
    console.log('🔴 FAILED');
    for (const f of failures) console.log(`  - ${f}`);
    process.exit(1);
  }
  console.log(
    '🟢 PROVEN — TIGER FIPS 20 carries Substitute for Senate Bill 563: the Senate map "Liberty 3"\n' +
      '   and the House map "Free State 3F", enacted 2022-04-15 and upheld by the Kansas Supreme\n' +
      '   Court in No. 125,083 (announced 2022-05-18, filed 2022-06-21). Both controls failed as\n' +
      '   required. 40 Senate + 125 House.',
  );
}

main().catch((e) => {
  console.error(`🔴 ${e.message}`);
  process.exit(1);
});
