#!/usr/bin/env node
/**
 * measure-sd-tiger-legislative.mjs — Knight program, slice 15 (SD), wave SD-1.
 *
 * Answers ONE question: how many polygons does TIGER file for South Dakota's state legislative
 * chambers, and what district codes do they carry?
 *
 * WHY THIS SCRIPT EXISTS. South Dakota's House is multi-member AND partly single-member, and
 * 🔴🔴 A SEAT COUNT OF 70 PASSES ON BOTH A RIGHT AND A WRONG STRUCTURE: 33 whole districts
 * electing two each (66) plus four single-member subdistricts (4) is 70, and so is a flat 35x2.
 * The seat total therefore proves nothing. The polygon count does.
 *
 * ── MEASURED 2026-09-28, TIGER 2024 FIPS 46 ─────────────────────────────────────────────────
 *   sldl   37 records, MTFCC G5220, LSY 2024, FUNCSTAT N, 0 'ZZZ'
 *          codes 001..025, 027, 029..035  (33 WHOLE districts)  +  26A, 26B, 28A, 28B  (4)
 *          🔴 THERE IS NO '026' AND NO '028' POLYGON. TIGER files those two districts ONLY as
 *          their subdistricts, so the House code set is NOT contiguous and a gate asserting
 *          001..035 contiguous FAILS CORRECTLY on the House.
 *   sldu   35 records, MTFCC G5210, LSY 2024, FUNCSTAT N, 0 'ZZZ'
 *          codes 001..035, contiguous, NO letters — the Senate keeps 26 and 28 WHOLE.
 *
 * So the House is 37 polygons carrying 70 seats: 33 x 2 + 4 x 1. The Senate is 35 for 35.
 * ▶ The multi-member claim carried into this slice is now PROVED against the file, and the
 *   subdistricts are 26A/26B/28A/28B exactly — no others.
 *
 * ── 🔴🔴 THE COUNT CANNOT DATE THE MAP, AND NEITHER CAN THE CODE SET ────────────────────────
 * Measured across four vintages on 2026-09-28. Every one is 37 records with the IDENTICAL code
 * set, including TIGER 2020, which carries the SUPERSEDED pre-2021 plan:
 *   TIGER 2020  37 records, LSY 2018, same 33 + 26A/26B/28A/28B
 *   TIGER 2022  37 records, LSY 2022, same
 *   TIGER 2024  37 records, LSY 2024, same
 *   TIGER 2025  37 records, LSY 2024, same
 * South Dakota's subdistrict structure survived the 2021 redistricting unchanged, so a count
 * check, a letter check and a code-set check ALL pass on a decade-old superseded map. This
 * reproduces the Kansas and Kentucky findings: nothing about the file dates the plan.
 * ⚠ LSY LOOKS LIKE A DISCRIMINATOR AND IS NOT — it tracks the Census refresh, not the plan, the
 *   same trap KS-1 documented. Do not date an SD map from LSY.
 * ▶ SD-1's vintage proof must therefore be GEOMETRIC — identity anchors whose district number
 *   differs between the pre- and post-2021 plans, in the shape MN, PA and ND used. That work is
 *   still open.
 *
 * ── HOW THE COUNT IS TAKEN ──────────────────────────────────────────────────────────────────
 * Twice, by independent routes:
 *   (a) the .dbf header's own record count (bytes 4..7, little-endian int32), read with no
 *       shapefile library — the file's self-description;
 *   (b) the number of feature rows the shapefile reader actually yields.
 * If they disagree the file is not what it claims, and the script exits non-zero.
 *
 * A positive control runs FIRST: a bogus FIPS must fail to download. A fetch path that cannot
 * fail cannot prove that a success means anything — the rule two silently-broken detectors on
 * 2026-09-04 paid for.
 *
 * ── TRAPS FOR ANY CALLER ────────────────────────────────────────────────────────────────────
 * 🔴 A SOUTH DAKOTA HOUSE DISTRICT IS NOT A NUMBER. '26A' is a label. Never cast it to an int,
 *    and never use a helper that validates codes as numeric — `normaliseCode` in
 *    verify-ks-tiger-vintage.mjs throws on '26A' by design.
 * 🔴 THE FIELD IS THREE CHARACTERS WIDE AND THE PADDING RULE DIFFERS: numeric codes are zero
 *    padded ('004'), lettered ones are not ('26A', never '026A'). GEOID is state FIPS + that
 *    code, so '46004' and '4626A' are both 5 characters.
 * 🔴 AN ASCII SORT MISPLACES THE SUBDISTRICTS. '26A' sorts AFTER '035' because '0' < '2'.
 *    Numerically they belong between 025 and 027. Sort on a parsed (number, letter) pair.
 *
 * Usage:
 *   node scripts/measure-sd-tiger-legislative.mjs              # TIGER 2024
 *   VINTAGE=2020 node scripts/measure-sd-tiger-legislative.mjs # any other vintage
 *   WORKDIR=/tmp/sd node scripts/measure-sd-tiger-legislative.mjs
 */
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import AdmZip from 'adm-zip';
import * as shapefile from 'shapefile';

const WORKDIR = process.env.WORKDIR || path.join(process.cwd(), '_sd-tiger');
fs.mkdirSync(WORKDIR, { recursive: true });

const VINTAGE = process.env.VINTAGE || '2024';
const FIPS = '46';

/** Expected shape, TIGER 2024. Asserted at the end so a drift is loud rather than cosmetic. */
const EXPECT = { sldl: 37, sldu: 35 };
const EXPECT_SUBDISTRICTS = ['26A', '26B', '28A', '28B'];

async function fetchBuffer(url) {
  const res = await fetch(url, { redirect: 'follow' });
  if (!res.ok) throw new Error(`HTTP ${res.status} ${res.statusText} for ${url}`);
  const buf = Buffer.from(await res.arrayBuffer());
  // 🔴 A clean 200 lies in several ways — a parked domain, a soft 404, a truncated body. A TIGER
  // zip must actually start 'PK' and be substantial.
  if (buf.length < 10_000) throw new Error(`suspiciously small body (${buf.length} bytes) for ${url}`);
  if (buf[0] !== 0x50 || buf[1] !== 0x4b) {
    throw new Error(`not a zip (first bytes ${buf.subarray(0, 8).toString('hex')}) for ${url}`);
  }
  return buf;
}

function tigerUrl(layer, fips = FIPS, vintage = VINTAGE) {
  return `https://www2.census.gov/geo/tiger/TIGER${vintage}/${layer.toUpperCase()}/tl_${vintage}_${fips}_${layer}.zip`;
}

/** The .dbf header states its own record count at bytes 4..7. Read it with no library. */
function dbfHeaderRecordCount(dbfPath) {
  const fd = fs.openSync(dbfPath, 'r');
  const head = Buffer.alloc(32);
  fs.readSync(fd, head, 0, 32, 0);
  fs.closeSync(fd);
  return {
    records: head.readInt32LE(4),
    headerBytes: head.readInt16LE(8),
    recordBytes: head.readInt16LE(10),
  };
}

/** Sort key that puts 26A/26B between 025 and 027, which an ASCII sort does not. */
function codeOrder(code) {
  const m = /^(\d+)([A-Za-z]*)$/.exec(code);
  if (!m) return [Number.MAX_SAFE_INTEGER, code];
  return [parseInt(m[1], 10), m[2].toUpperCase()];
}
const byCode = (a, b) => {
  const [an, al] = codeOrder(a);
  const [bn, bl] = codeOrder(b);
  return an - bn || al.localeCompare(bl, 'en');
};

async function measure(layer) {
  const url = tigerUrl(layer);
  const base = `tl_${VINTAGE}_${FIPS}_${layer}`;
  const zipPath = path.join(WORKDIR, `${base}.zip`);
  if (!fs.existsSync(zipPath)) fs.writeFileSync(zipPath, await fetchBuffer(url));
  const bytes = fs.statSync(zipPath).size;
  const sha = crypto.createHash('sha256').update(fs.readFileSync(zipPath)).digest('hex');

  const zip = new AdmZip(zipPath);
  const names = zip.getEntries().map((e) => e.entryName);
  for (const ext of ['.shp', '.dbf', '.shx']) {
    const entry = zip.getEntry(base + ext);
    if (!entry) throw new Error(`${base}${ext} missing from ${base}.zip — entries: ${names.join(', ')}`);
    fs.writeFileSync(path.join(WORKDIR, base + ext), entry.getData());
  }

  const hdr = dbfHeaderRecordCount(path.join(WORKDIR, base + '.dbf'));

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
      code: String(p[field] ?? ''),
      geoid: String(p.GEOID ?? ''),
      namelsad: String(p.NAMELSAD ?? ''),
      mtfcc: String(p.MTFCC ?? ''),
      lsy: String(p.LSY ?? ''),
      funcstat: String(p.FUNCSTAT ?? ''),
      geomType: r.value.geometry?.type ?? null,
    });
  }

  return { layer, url, bytes, sha, hdr, rows };
}

function report(m) {
  console.log(`\n${'='.repeat(78)}`);
  console.log(`LAYER ${m.layer.toUpperCase()}  —  ${m.url}`);
  console.log('='.repeat(78));
  console.log(`zip bytes        ${m.bytes.toLocaleString()}`);
  console.log(`zip sha256       ${m.sha}`);
  console.log(`.dbf header says ${m.hdr.records} records  (header ${m.hdr.headerBytes} B, record ${m.hdr.recordBytes} B)`);
  console.log(`rows read        ${m.rows.length}`);
  const agree = m.hdr.records === m.rows.length;
  console.log(`independent counts AGREE: ${agree ? 'YES' : '🔴 NO — FILE IS NOT WHAT IT CLAIMS'}`);
  if (!agree) process.exitCode = 1;

  const codes = m.rows.map((r) => r.code).sort(byCode);
  const lettered = codes.filter((c) => /[A-Za-z]/.test(c));
  const uniq = (f) => [...new Set(m.rows.map(f))].sort();

  console.log(`MTFCC            ${uniq((r) => r.mtfcc).join(', ')}`);
  console.log(`LSY              ${uniq((r) => r.lsy).join(', ')}   ⚠ tracks the Census refresh, NOT the plan`);
  console.log(`FUNCSTAT         ${uniq((r) => r.funcstat).join(', ')}`);
  console.log(`geometry types   ${uniq((r) => r.geomType).join(', ')}`);
  console.log(`'ZZZ' pseudo-rows ${codes.filter((c) => c.toUpperCase() === 'ZZZ').length}`);
  console.log(`lettered codes   ${lettered.length}${lettered.length ? ` -> ${lettered.join(', ')}` : ''}`);
  console.log(`\nall ${codes.length} codes, in NUMERIC order:`);
  console.log('  ' + codes.join(' '));
  for (const r of m.rows.filter((x) => /[A-Za-z]/.test(x.code)).sort((a, b) => byCode(a.code, b.code))) {
    console.log(`  ${r.code.padEnd(5)} GEOID ${r.geoid.padEnd(7)} ${r.namelsad}`);
  }
  return { codes, lettered };
}

// ── Positive control: the fetch path must be able to FAIL. ───────────────────────────────────
let controlFired = false;
try {
  await fetchBuffer(tigerUrl('sldl', '99'));
} catch (err) {
  controlFired = true;
  console.log(`positive control OK — bogus FIPS 99 refused: ${err.message.split(' for ')[0]}`);
}
if (!controlFired) {
  console.error('🔴 POSITIVE CONTROL DID NOT FIRE — a bogus FIPS downloaded. Every count below proves nothing.');
  process.exit(1);
}

const sldl = await measure('sldl');
const sldu = await measure('sldu');
const lower = report(sldl);
report(sldu);

console.log(`\n${'='.repeat(78)}`);
console.log(`TIGER ${VINTAGE} FIPS 46:  sldl = ${sldl.rows.length} polygons,  sldu = ${sldu.rows.length} polygons`);
console.log(`House = ${lower.codes.length - lower.lettered.length} whole districts x 2 seats + ${lower.lettered.length} subdistricts x 1 seat = ${(lower.codes.length - lower.lettered.length) * 2 + lower.lettered.length} seats`);
console.log('='.repeat(78));

// ── Assert the shape this slice was planned against. Drift must be loud. ────────────────────
const problems = [];
if (sldl.rows.length !== EXPECT.sldl) problems.push(`sldl ${sldl.rows.length}, expected ${EXPECT.sldl}`);
if (sldu.rows.length !== EXPECT.sldu) problems.push(`sldu ${sldu.rows.length}, expected ${EXPECT.sldu}`);
const gotSub = lower.lettered.join(',');
if (gotSub !== EXPECT_SUBDISTRICTS.join(',')) {
  problems.push(`subdistricts [${gotSub}], expected [${EXPECT_SUBDISTRICTS.join(',')}]`);
}
if (problems.length) {
  console.error(`\n🔴 SHAPE DRIFT: ${problems.join(' · ')}`);
  process.exitCode = 1;
} else {
  console.log('\n✅ shape matches the 2026-09-28 measurement recorded in this file.');
}
