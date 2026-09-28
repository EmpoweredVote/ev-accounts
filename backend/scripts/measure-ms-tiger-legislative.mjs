#!/usr/bin/env node
/**
 * measure-ms-tiger-legislative.mjs — Knight program, slice 16 (MS), wave MS-1.
 *
 * Answers ONE question: how many polygons does TIGER file for Mississippi's state legislative
 * chambers, what district codes do they carry, and does ANY of that change between vintages?
 *
 * WHY THIS SCRIPT EXISTS. Mississippi is the LAST state in the programme owing legislative
 * geography, and it is the one state where a mid-decade, court-ordered partial remap is known to
 * be in play. The programme's standing finding — measured in KS, KY and SD, in that order — is
 * that a polygon count, a code set and the LSY field can ALL pass on a superseded map. This
 * script establishes the shape and then proves, by measuring several vintages against each other,
 * whether anything inside the file can date it. It deliberately does NOT try to settle the
 * vintage: that is a geometric question against a Mississippi authority, and it is MS-1's job.
 *
 * ── HOW THE COUNT IS TAKEN ──────────────────────────────────────────────────────────────────
 * Twice, by independent routes, for every layer and every vintage:
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
 * 🔴 THE CODE SET IS NOT THE MAP. SD, KS and KY all proved this. Two vintages agreeing on
 *    '001'..'122' says only that the chamber's size is fixed, which for Mississippi it is
 *    (Miss. Const. art. 13 § 254 fixes the two chambers), so the code set can NEVER date the map.
 * 🔴 LSY TRACKS THE CENSUS REFRESH, NOT THE PLAN. Reported here so it can be seen NOT to move
 *    when a plan does.
 * 🔴 geo_id COLLIDES WITH COUNTIES, as in PA, SC, OH, ND, KY and SD. Mississippi's 82 counties
 *    are '28001'..'28163' odd, and Senate districts will be '28001'..'28052' — so roughly half
 *    the Senate range collides with a real county id, and Harrison County is '28047' while
 *    Senate District 47 is ALSO '28047'. Every join must pair geo_id with mtfcc.
 *
 * Usage:
 *   node scripts/measure-ms-tiger-legislative.mjs                 # 2022,2023,2024,2025
 *   VINTAGES=2024 node scripts/measure-ms-tiger-legislative.mjs   # one vintage
 *   WORKDIR=/tmp/ms node scripts/measure-ms-tiger-legislative.mjs
 */
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import AdmZip from 'adm-zip';
import * as shapefile from 'shapefile';

const WORKDIR = process.env.WORKDIR || path.join(process.cwd(), '_ms-tiger');
fs.mkdirSync(WORKDIR, { recursive: true });

const VINTAGES = (process.env.VINTAGES || '2022,2023,2024,2025').split(',').map((s) => s.trim());
const FIPS = '28';

/**
 * Expected shape. Miss. Const. art. 13 § 254 caps the Legislature and the apportionment
 * statutes fix it at 122 + 52, so this is a CONSTITUTIONAL shape and cannot date anything.
 * Asserted anyway so that drift is loud rather than cosmetic.
 */
const EXPECT = { sldl: 122, sldu: 52 };

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

function tigerUrl(layer, fips = FIPS, vintage) {
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

/**
 * Sort key that keeps a lettered code beside its number rather than after '099'.
 * Mississippi is expected to file none, but SD proved that assuming so is how a subdistrict
 * gets silently dropped, so the ordering is defensive rather than trusting.
 */
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

async function measure(layer, vintage) {
  const url = tigerUrl(layer, FIPS, vintage);
  const base = `tl_${vintage}_${FIPS}_${layer}`;
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

  return { layer, vintage, url, bytes, sha, hdr, rows };
}

function report(m) {
  console.log(`\n${'-'.repeat(78)}`);
  console.log(`TIGER ${m.vintage}  LAYER ${m.layer.toUpperCase()}`);
  console.log('-'.repeat(78));
  console.log(`zip bytes         ${m.bytes.toLocaleString()}`);
  console.log(`zip sha256        ${m.sha}`);
  console.log(`.dbf header says  ${m.hdr.records} records  (header ${m.hdr.headerBytes} B, record ${m.hdr.recordBytes} B)`);
  console.log(`rows read         ${m.rows.length}`);
  const agree = m.hdr.records === m.rows.length;
  console.log(`independent counts AGREE: ${agree ? 'YES' : '🔴 NO — FILE IS NOT WHAT IT CLAIMS'}`);
  if (!agree) process.exitCode = 1;

  const codes = m.rows.map((r) => r.code).sort(byCode);
  const lettered = codes.filter((c) => /[A-Za-z]/.test(c));
  const uniq = (f) => [...new Set(m.rows.map(f))].sort();

  console.log(`MTFCC             ${uniq((r) => r.mtfcc).join(', ')}`);
  console.log(`LSY               ${uniq((r) => r.lsy).join(', ')}   ⚠ tracks the Census refresh, NOT the plan`);
  console.log(`FUNCSTAT          ${uniq((r) => r.funcstat).join(', ')}`);
  console.log(`geometry types    ${uniq((r) => r.geomType).join(', ')}`);
  console.log(`'ZZZ' pseudo-rows ${codes.filter((c) => c.toUpperCase() === 'ZZZ').length}`);
  console.log(`lettered codes    ${lettered.length}${lettered.length ? ` -> ${lettered.join(', ')}` : ''}`);

  // Contiguity, stated rather than assumed. SD's House is deliberately NOT contiguous.
  const numeric = codes.filter((c) => !/[A-Za-z]/.test(c)).map((c) => parseInt(c, 10)).sort((a, b) => a - b);
  const gaps = [];
  for (let i = 1; i <= numeric[numeric.length - 1]; i += 1) if (!numeric.includes(i)) gaps.push(i);
  console.log(`numeric range     ${numeric[0]}..${numeric[numeric.length - 1]}  ` +
    `${gaps.length === 0 ? 'CONTIGUOUS, no gaps' : `🔴 ${gaps.length} GAPS -> ${gaps.join(', ')}`}`);

  return { codes, lettered, codeSet: codes.join(' ') };
}

// ── Positive control: the fetch path must be able to FAIL. ───────────────────────────────────
let controlFired = false;
try {
  await fetchBuffer(tigerUrl('sldl', '99', VINTAGES[0]));
} catch (err) {
  controlFired = true;
  console.log(`positive control OK — bogus FIPS 99 refused: ${err.message.split(' for ')[0]}`);
}
if (!controlFired) {
  console.error('🔴 POSITIVE CONTROL DID NOT FIRE — a bogus FIPS downloaded. Every count below proves nothing.');
  process.exit(1);
}

const summary = [];
for (const vintage of VINTAGES) {
  for (const layer of ['sldl', 'sldu']) {
    const m = await measure(layer, vintage);
    const r = report(m);
    summary.push({ vintage, layer, n: m.rows.length, sha: m.sha, codeSet: r.codeSet, lsy: [...new Set(m.rows.map((x) => x.lsy))].join('/') });
  }
}

console.log(`\n${'='.repeat(78)}`);
console.log('ACROSS VINTAGES — can anything INSIDE the file date the map?');
console.log('='.repeat(78));
for (const layer of ['sldl', 'sldu']) {
  const rows = summary.filter((s) => s.layer === layer);
  const counts = new Set(rows.map((r) => r.n));
  const sets = new Set(rows.map((r) => r.codeSet));
  const shas = new Set(rows.map((r) => r.sha));
  console.log(`\n${layer.toUpperCase()}`);
  for (const r of rows) console.log(`  ${r.vintage}  ${String(r.n).padStart(3)} polygons  LSY ${r.lsy.padEnd(9)} sha ${r.sha.slice(0, 12)}`);
  console.log(`  distinct polygon counts : ${counts.size}  ${counts.size === 1 ? '🔴 a COUNT CANNOT DATE THIS MAP' : 'counts differ'}`);
  console.log(`  distinct code sets      : ${sets.size}  ${sets.size === 1 ? '🔴 a CODE SET CANNOT DATE THIS MAP' : 'code sets differ'}`);
  console.log(`  distinct file hashes    : ${shas.size}  ${shas.size === 1 ? 'byte-identical across vintages' : 'the BYTES differ — geometry moved somewhere'}`);
}
console.log('\n▶ A differing hash says the file changed; it does NOT say WHICH plan is operative.');
console.log('▶ The vintage proof must be GEOMETRIC, against a Mississippi authority that publishes');
console.log('  the competing plans. That is MS-1, and it is not this script.');

// ── Assert the shape this slice was planned against. Drift must be loud. ────────────────────
const problems = [];
for (const layer of ['sldl', 'sldu']) {
  for (const r of summary.filter((s) => s.layer === layer)) {
    if (r.n !== EXPECT[layer]) problems.push(`${layer} ${r.vintage}: ${r.n}, expected ${EXPECT[layer]}`);
  }
}
if (problems.length) {
  console.error(`\n🔴 SHAPE DRIFT: ${problems.join(' · ')}`);
  process.exitCode = 1;
} else {
  console.log(`\n✅ every vintage measured is sldl ${EXPECT.sldl} / sldu ${EXPECT.sldu}, the constitutional shape.`);
}
