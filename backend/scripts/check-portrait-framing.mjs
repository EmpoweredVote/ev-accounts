#!/usr/bin/env node
//
// check-portrait-framing — reject a headshot whose source is a DISC ON A FLAT MATTE
// rather than a rectangular photograph.
//
// Why this exists: two Fulton portraits in the Atlanta wave (2026-10-17) were circular
// crops. Cropped to the house 4:5 they keep a wedge of matte in all four corners. Licence,
// resolution, no-monochrome, face-centre and the source's own alt text ALL passed them.
// The operator caught them by eye on the contact sheet. Nothing else would have.
//
// Usage:
//   node scripts/check-portrait-framing.mjs <dir-of-jpegs> [--json]
//
// Exit 0 = no framed portraits. Exit 1 = framed portraits found, or the CONTROLS failed.
//
// 🔴 THE POSITIVE CONTROL IS TWO FIXTURES, NOT TWO ROWS OF WHATEVER IS BEING SCANNED.
// The first version of this gate named the two live rows as its control. Fixing those rows
// removed them from the set, and the next run printed "FRAMED: none" while proving nothing.
// A control the work itself deletes is not a control. Fixtures are fetched once and cached
// under <dir>/.framing-fixtures/. There is a NEGATIVE control too: a gate that answered YES
// to everything would otherwise read as passing.

import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const DIR = process.argv[2];
const AS_JSON = process.argv.includes('--json');
if (!DIR || !fs.existsSync(DIR)) {
  console.error('usage: check-portrait-framing.mjs <dir-of-jpegs> [--json]');
  process.exit(2);
}

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';
const FIXDIR = path.join(DIR, '.framing-fixtures');

// known circular-framed sources — the gate must flag both
const POSITIVE = [
  ['circle-green-clerk', 'https://www.fultonclerk.org/ImageRepository/Document?documentId=3397'],
  ['circle-white-sheriff', 'https://www.fultoncountyga.gov/-/media/Departments/Sheriff/Bio-Grid/Pat-Labat-Headshot-52021.png'],
];
// a known rectangular studio portrait — the gate must NOT flag it
const NEGATIVE = ['rect-council-portrait', 'https://citycouncil.atlantaga.gov/home/showpublishedimage/26305/639033835486070000'];

const W = 120, H = 150;

function renderFixture(name, url) {
  fs.mkdirSync(FIXDIR, { recursive: true });
  const jpg = path.join(FIXDIR, name + '.jpg');
  if (fs.existsSync(jpg)) return jpg;
  const src = path.join(FIXDIR, name + '.src');
  const buf = execFileSync(process.execPath, ['-e', `
    fetch(${JSON.stringify(url)}, { headers: { 'User-Agent': ${JSON.stringify(UA)}, 'Accept': 'image/*,*/*' } })
      .then(r => r.arrayBuffer())
      .then(a => process.stdout.write(Buffer.from(a)));
  `], { maxBuffer: 64 * 1024 * 1024, encoding: 'buffer' });
  fs.writeFileSync(src, buf);
  execFileSync('ffmpeg', ['-y', '-v', 'error', '-i', src,
    '-vf', "crop='min(iw,ih*4/5)':'min(ih,iw*5/4)',scale=600:750:flags=lanczos", '-q:v', '2', jpg]);
  return jpg;
}

function pixels(file) {
  const raw = path.join(FIXDIR, '_scan.rgb');
  fs.mkdirSync(FIXDIR, { recursive: true });
  execFileSync('ffmpeg', ['-y', '-v', 'error', '-i', file, '-vf', `scale=${W}:${H}`,
    '-pix_fmt', 'rgb24', '-f', 'rawvideo', raw]);
  const b = fs.readFileSync(raw);
  fs.unlinkSync(raw);
  return b;
}

const at = (b, x, y) => { const i = (y * W + x) * 3; return [b[i], b[i + 1], b[i + 2]]; };
const dist = (a, c) => Math.abs(a[0] - c[0]) + Math.abs(a[1] - c[1]) + Math.abs(a[2] - c[2]);

function analyse(file) {
  const b = pixels(file);
  const S = 10;
  const corners = [[0, 0], [W - S, 0], [0, H - S], [W - S, H - S]].map(([ox, oy]) => {
    const px = [];
    for (let y = oy; y < oy + S; y++) for (let x = ox; x < ox + S; x++) px.push(at(b, x, y));
    const mean = [0, 1, 2].map(k => px.reduce((s, p) => s + p[k], 0) / px.length);
    const sd = Math.sqrt(px.reduce((s, p) => s + dist(p, mean) ** 2, 0) / px.length);
    return { mean, sd };
  });
  const cornerFlat = corners.every(c => c.sd < 14);
  // the discriminator: a disc on matte has four IDENTICAL corners (agreement ~0);
  // every real studio backdrop measured >= 24.
  const agree = Math.max(...corners.map(c1 => Math.max(...corners.map(c2 => dist(c1.mean, c2.mean)))));
  const bg = [0, 1, 2].map(k => corners.reduce((s, c) => s + c.mean[k], 0) / 4);

  let mass = 0, centreMatch = 0, centreN = 0;
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const near = dist(at(b, x, y), bg) < 24;
    if (near) mass++;
    const cx = x - W / 2, cy = y - H / 2;
    if (Math.hypot(cx / (W / 2), cy / (H / 2)) < 0.45) { centreN++; if (near) centreMatch++; }
  }
  const massPct = 100 * mass / (W * H);
  const centrePct = 100 * centreMatch / centreN;

  let steps = 0;
  for (const [sx, sy, dx, dy] of [[0, 0, 1, 1], [W - 1, 0, -1, 1], [0, H - 1, 1, -1], [W - 1, H - 1, -1, -1]]) {
    let x = sx, y = sy, seenMatte = 0, stepped = false;
    for (let t = 0; t < Math.min(W, H) / 2; t++) {
      if (dist(at(b, Math.round(x), Math.round(y)), bg) < 24) { if (!stepped) seenMatte++; }
      else if (seenMatte >= 6) { stepped = true; break; }
      x += dx * 0.8; y += dy;
    }
    if (stepped) steps++;
  }

  return {
    cornerFlat, agree: +agree.toFixed(0), massPct: +massPct.toFixed(1),
    centrePct: +centrePct.toFixed(1), steps,
    framed: cornerFlat && agree < 30 && massPct > 12 && centrePct < 4 && steps >= 3,
  };
}

// ---- controls run FIRST; the scan below means nothing until they pass ----
let controlsOk = true;
const controlLog = [];
for (const [name, url] of POSITIVE) {
  let r;
  try { r = analyse(renderFixture(name, url)); }
  catch (e) { console.error(`control ${name} could not be built: ${e.message}`); process.exit(1); }
  controlLog.push({ control: 'positive', name, ...r });
  if (!r.framed) controlsOk = false;
}
try {
  const r = analyse(renderFixture(NEGATIVE[0], NEGATIVE[1]));
  controlLog.push({ control: 'negative', name: NEGATIVE[0], ...r });
  if (r.framed) controlsOk = false;
} catch (e) { console.error(`negative control could not be built: ${e.message}`); process.exit(1); }

if (!AS_JSON) {
  console.log('controls:');
  for (const c of controlLog) {
    const want = c.control === 'positive' ? 'YES' : 'no';
    const got = c.framed ? 'YES' : 'no';
    console.log(`  ${c.control.padEnd(8)} ${c.name.padEnd(24)} agree=${String(c.agree).padEnd(4)} mass=${String(c.massPct).padEnd(6)} want=${want} got=${got} ${want === got ? '' : '  *** CONTROL FAILED ***'}`);
  }
}
if (!controlsOk) {
  console.error('\n*** CONTROLS FAILED — the gate is blind. Its verdict on the set below is meaningless. ***');
  process.exit(1);
}

const files = fs.readdirSync(DIR).filter(f => /\.(jpe?g|png)$/i.test(f)).sort();
const hits = [];
for (const f of files) {
  const r = analyse(path.join(DIR, f));
  if (r.framed) hits.push({ file: f, ...r });
}

if (AS_JSON) {
  console.log(JSON.stringify({ controls: controlLog, controlsOk, scanned: files.length, framed: hits }, null, 2));
} else {
  console.log(`\ncontrols passed. scanned ${files.length} image(s).`);
  if (hits.length) {
    console.log('FRAMED — these are discs on a matte, not rectangular portraits:');
    for (const h of hits) console.log(`  ${h.file}  (corner agreement ${h.agree}, matte ${h.massPct}% of frame)`);
  } else {
    console.log('FRAMED: none');
  }
}
process.exit(hits.length ? 1 : 0);
