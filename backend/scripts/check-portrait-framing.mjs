#!/usr/bin/env node
//
// check-portrait-framing — reject a headshot whose source is a MANUFACTURED SURROUND
// rather than a rectangular photograph. Two shapes qualify:
//   DISC    a circular crop sitting on a flat matte
//   BORDER  a rectangular photograph letterboxed inside a flat frame
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
// 🔴 THE POSITIVE CONTROL IS FIXTURES, NOT TWO ROWS OF WHATEVER IS BEING SCANNED.
// The first version of this gate named the two live rows as its control. Fixing those rows
// removed them from the set, and the next run printed "FRAMED: none" while proving nothing.
// A control the work itself deletes is not a control. Fixtures are fetched once and cached
// under <dir>/.framing-fixtures/. There are NEGATIVE controls too: a gate that answered YES
// to everything would otherwise read as passing.
//
// 🔴🔴 FIXED 2026-11-09 — THIS GATE PASSED A PURE-BLACK BORDER, AND THE EYE CAUGHT IT.
// Walnut Valley's published portrait of Theresa Lee (4800x6000) carries a black frame of
// 505/504/161/160 px. The gate returned FRAMED: none with both fixtures passing. Measured
// afterwards, it satisfied FOUR of the five old conditions and failed on exactly one:
// centrePct = 10 against a required < 4.
//   ▶ THE MECHANISM: the old centre test asked "is the middle THE SAME COLOUR as the
//     surround", which is not the same question as "is the middle PART OF the surround".
//     Lee's matte is near-black, and dark hair, a dark jacket and shadow are near-black in
//     every portrait ever taken, so the subject itself voted the frame innocent. Both
//     fixtures were a GREEN matte and a WHITE matte — colours that cannot occur in a
//     subject — so no fixture had ever exercised a dark surround. ⚠ A control set that is
//     uniform in a property the detector depends on cannot test that property.
//   ▶ THE REPAIR, two parts, both chosen from measurements over the 14 approved crops of
//     the CC_0383 batch plus every fixture (none of them a false positive):
//       1. Surround membership is now an EDGE-CONNECTED FLOOD FILL, not a colour match.
//          A surround touches the frame edge; dark hair in the middle of a face does not.
//          On the same corpus the colour test read up to 11.8% inside the centre ellipse
//          while the flood fill reads 0.0% on every row — it answers the right question.
//       2. A BORDER BRANCH was added, because the disc tests cannot see a rectangular
//          frame STRUCTURALLY: a disc of full width touches the left and right edges at
//          their midpoints, so no side of a disc image is flat along its whole length,
//          and a per-side test is the only thing that sees a letterbox. Measured over the
//          same corpus, Lee's file is the ONLY row with any flat border depth
//          ([4,4,12,12] px of 120x150, colour agreement 0, contrast 81); every approved
//          crop, the de-bordered twin and all three old fixtures read depth 0.
//   ▶ AND IT NOW PRINTS EVERY ROW IT SCANNED, not only its hits. The reason Lee's pass was
//     undiagnosable for a day is that a passing row produced no numbers at all.
//
// ⚠ This gate is hand-run during a photo sourcing run. It is NOT in CI and NOT in
// package.json, so nothing runs it for you.

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

// known manufactured surrounds — the gate must flag every one
const POSITIVE = [
  ['circle-green-clerk', 'https://www.fultonclerk.org/ImageRepository/Document?documentId=3397'],
  ['circle-white-sheriff', 'https://www.fultoncountyga.gov/-/media/Departments/Sheriff/Bio-Grid/Pat-Labat-Headshot-52021.png'],
  // the row this gate used to pass. A DARK matte, which is the case both other fixtures miss.
  ['border-black-wvwd-lee', 'https://walnutvalleywater.gov/wp-content/uploads/2022/12/2019-Lee-Director-3-16x20-1.jpg'],
];
// known rectangular photographs — the gate must NOT flag either
const NEGATIVE = [
  ['rect-council-portrait', 'https://citycouncil.atlantaga.gov/home/showpublishedimage/26305/639033835486070000'],
  // 🔴 THE SAME PHOTOGRAPH AS border-black-wvwd-lee WITH THE FRAME CUT OFF. The strongest
  // negative available: subject, studio, lens and compression all held constant, so the only
  // thing it can be answering is the border. Built by cropping the POSITIVE fixture at the
  // insets measured off that file, and the build ASSERTS the source is still 4800x6000 — if
  // the district republishes the portrait the fixture fails loudly instead of cropping air.
  ['rect-wvwd-lee-deborder', { deborder: 'border-black-wvwd-lee', expect: [4800, 6000], crop: [505, 504, 161, 160] }],
];

const W = 120, H = 150;

function fetchTo(url, dest) {
  const buf = execFileSync(process.execPath, ['-e', `
    fetch(${JSON.stringify(url)}, { headers: { 'User-Agent': ${JSON.stringify(UA)}, 'Accept': 'image/*,*/*' } })
      .then(r => r.arrayBuffer())
      .then(a => process.stdout.write(Buffer.from(a)));
  `], { maxBuffer: 64 * 1024 * 1024, encoding: 'buffer' });
  fs.writeFileSync(dest, buf);
}

function probeSize(file) {
  const out = execFileSync('ffprobe', ['-v', 'error', '-select_streams', 'v:0',
    '-show_entries', 'stream=width,height', '-of', 'csv=p=0', file], { encoding: 'utf8' });
  return out.trim().split(',').map(Number);
}

const house = (inFile, outFile, pre = []) => execFileSync('ffmpeg', ['-y', '-v', 'error', '-i', inFile,
  '-vf', [...pre, "crop='min(iw,ih*4/5)':'min(ih,iw*5/4)'", 'scale=600:750:flags=lanczos'].join(','),
  '-q:v', '2', outFile]);

function renderFixture(name, spec) {
  fs.mkdirSync(FIXDIR, { recursive: true });
  const jpg = path.join(FIXDIR, name + '.jpg');
  if (fs.existsSync(jpg)) return jpg;

  if (typeof spec === 'object' && spec.deborder) {
    // derived from a POSITIVE fixture's own downloaded bytes, never from the scanned set
    const src = path.join(FIXDIR, spec.deborder + '.src');
    if (!fs.existsSync(src)) {
      const parent = POSITIVE.find(([n]) => n === spec.deborder);
      if (!parent) throw new Error(`deborder parent ${spec.deborder} is not a positive fixture`);
      fetchTo(parent[1], src);
    }
    const [w, h] = probeSize(src);
    if (w !== spec.expect[0] || h !== spec.expect[1]) {
      throw new Error(`${name}: source is now ${w}x${h}, not ${spec.expect.join('x')} — the measured `
        + `crop ${spec.crop.join('/')} no longer describes this file. Re-measure the border before trusting it.`);
    }
    const [l, r, t, b] = spec.crop;
    house(src, jpg, [`crop=${w - l - r}:${h - t - b}:${l}:${t}`]);
    return jpg;
  }

  const src = path.join(FIXDIR, name + '.src');
  if (!fs.existsSync(src)) fetchTo(spec, src);
  house(src, jpg);
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
const meanOf = (px) => [0, 1, 2].map(k => px.reduce((s, p) => s + p[k], 0) / px.length);
const spreadOf = (px) => { const m = meanOf(px); return Math.sqrt(px.reduce((s, p) => s + dist(p, m) ** 2, 0) / px.length); };

const NEAR = 24;      // same colour family (L1 over RGB)
const FLAT_LINE = 12; // a scan line is "flat along its length" below this spread

// one scan line parallel to an edge, at depth d from it
function edgeLine(b, side, d) {
  const px = [];
  if (side === 'top') for (let x = 0; x < W; x++) px.push(at(b, x, d));
  else if (side === 'bottom') for (let x = 0; x < W; x++) px.push(at(b, x, H - 1 - d));
  else if (side === 'left') for (let y = 0; y < H; y++) px.push(at(b, d, y));
  else for (let y = 0; y < H; y++) px.push(at(b, W - 1 - d, y));
  return px;
}

// BORDER: a flat rectangular frame. Measured per side, because a frame is the one surround
// that is flat ALONG THE WHOLE LENGTH of every edge — which is exactly what a disc is not.
function borderMetrics(b) {
  const sides = {};
  for (const side of ['top', 'bottom', 'left', 'right']) {
    const c0 = meanOf(edgeLine(b, side, 0));
    const maxD = Math.floor((side === 'top' || side === 'bottom' ? H : W) / 3);
    let depth = 0;
    for (let d = 0; d < maxD; d++) {
      const px = edgeLine(b, side, d);
      if (spreadOf(px) < FLAT_LINE && dist(meanOf(px), c0) < NEAR) depth = d + 1; else break;
    }
    sides[side] = { colour: c0, depth };
  }
  const order = ['top', 'bottom', 'left', 'right'];
  const depths = order.map(s => sides[s].depth);
  const cols = order.map(s => sides[s].colour);
  const colourAgree = Math.max(...cols.map(a => Math.max(...cols.map(c => dist(a, c)))));
  const frame = meanOf(cols);

  const t = Math.max(1, sides.top.depth), bo = Math.max(1, sides.bottom.depth);
  const l = Math.max(1, sides.left.depth), r = Math.max(1, sides.right.depth);
  const inner = [];
  for (let y = t + 2; y < H - bo - 2; y++) for (let x = l + 2; x < W - r - 2; x++) inner.push(at(b, x, y));
  const contrast = inner.length ? dist(meanOf(inner), frame) : 0;

  return {
    depths, minDepth: Math.min(...depths),
    colourAgree: +colourAgree.toFixed(0), contrast: +contrast.toFixed(0),
    // a real frame is >= 2px of the 120x150 scan on EVERY side, one colour all the way
    // round, and a different thing from what it encloses.
    bordered: Math.min(...depths) >= 2 && colourAgree < 30 && contrast > 40,
  };
}

function analyse(file) {
  const b = pixels(file);
  const S = 10;
  const corners = [[0, 0], [W - S, 0], [0, H - S], [W - S, H - S]].map(([ox, oy]) => {
    const px = [];
    for (let y = oy; y < oy + S; y++) for (let x = ox; x < ox + S; x++) px.push(at(b, x, y));
    const mean = meanOf(px);
    return { mean, sd: spreadOf(px) };
  });
  const cornerFlat = corners.every(c => c.sd < 14);
  // the disc discriminator: a disc on matte has four IDENTICAL corners (agreement ~0);
  // every real studio backdrop measured >= 24.
  const agree = Math.max(...corners.map(c1 => Math.max(...corners.map(c2 => dist(c1.mean, c2.mean)))));
  const bg = meanOf(corners.map(c => c.mean));

  // 🔴 SURROUND MEMBERSHIP IS CONNECTION TO THE EDGE, NOT COLOUR. Flood fill inward from
  // every edge pixel over the matte colour family. Dark hair in the middle of a face shares
  // the colour of a black matte and is not reachable from the frame; that distinction is the
  // whole repair. `matteColourPct` is kept and REPORTED, never tested, so the next reader can
  // see the two diverge on a dark surround instead of having to measure it again.
  const seen = new Uint8Array(W * H);
  const stack = [];
  const push = (x, y) => {
    if (x < 0 || y < 0 || x >= W || y >= H) return;
    const i = y * W + x;
    if (seen[i] || dist(at(b, x, y), bg) >= NEAR) return;
    seen[i] = 1; stack.push(x, y);
  };
  for (let x = 0; x < W; x++) { push(x, 0); push(x, H - 1); }
  for (let y = 0; y < H; y++) { push(0, y); push(W - 1, y); }
  while (stack.length) {
    const y = stack.pop(), x = stack.pop();
    push(x + 1, y); push(x - 1, y); push(x, y + 1); push(x, y - 1);
  }

  let colourMass = 0, surround = 0, centreSurround = 0, centreColour = 0, centreN = 0;
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const sameColour = dist(at(b, x, y), bg) < NEAR;
    const isSurround = seen[y * W + x] === 1;
    if (sameColour) colourMass++;
    if (isSurround) surround++;
    const cx = x - W / 2, cy = y - H / 2;
    if (Math.hypot(cx / (W / 2), cy / (H / 2)) < 0.45) {
      centreN++;
      if (sameColour) centreColour++;
      if (isSurround) centreSurround++;
    }
  }
  const surroundPct = 100 * surround / (W * H);
  const centreSurroundPct = 100 * centreSurround / centreN;

  // the diagonal walk: a disc steps out of matte into content on every corner diagonal
  let steps = 0;
  for (const [sx, sy, dx, dy] of [[0, 0, 1, 1], [W - 1, 0, -1, 1], [0, H - 1, 1, -1], [W - 1, H - 1, -1, -1]]) {
    let x = sx, y = sy, seenMatte = 0, stepped = false;
    for (let t = 0; t < Math.min(W, H) / 2; t++) {
      if (dist(at(b, Math.round(x), Math.round(y)), bg) < NEAR) { if (!stepped) seenMatte++; }
      else if (seenMatte >= 6) { stepped = true; break; }
      x += dx * 0.8; y += dy;
    }
    if (stepped) steps++;
  }

  const disc = cornerFlat && agree < 30 && surroundPct > 12 && centreSurroundPct < 4 && steps >= 3;
  const bm = borderMetrics(b);
  const kinds = [];
  if (disc) kinds.push('DISC');
  if (bm.bordered) kinds.push('BORDER');

  return {
    cornerFlat, agree: +agree.toFixed(0),
    surroundPct: +surroundPct.toFixed(1),
    matteColourPct: +(100 * colourMass / (W * H)).toFixed(1),
    centreSurroundPct: +centreSurroundPct.toFixed(1),
    centreColourPct: +(100 * centreColour / centreN).toFixed(1),
    steps,
    borderDepths: bm.depths, borderColourAgree: bm.colourAgree, borderContrast: bm.contrast,
    disc, bordered: bm.bordered,
    kind: kinds.join('+') || '',
    framed: disc || bm.bordered,
  };
}

const ROW = (label, r) => `  ${label.padEnd(40)} flat=${String(r.cornerFlat).padEnd(5)}`
  + ` agree=${String(r.agree).padEnd(4)} surround=${String(r.surroundPct).padEnd(5)}`
  + ` ctrSurr=${String(r.centreSurroundPct).padEnd(5)} steps=${r.steps}`
  + ` | border=${JSON.stringify(r.borderDepths).padEnd(16)} bAgree=${String(r.borderColourAgree).padEnd(4)}`
  + ` bContrast=${String(r.borderContrast).padEnd(4)} | ${r.framed ? 'FRAMED ' + r.kind : '-'}`;

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
for (const [name, spec] of NEGATIVE) {
  let r;
  try { r = analyse(renderFixture(name, spec)); }
  catch (e) { console.error(`negative control ${name} could not be built: ${e.message}`); process.exit(1); }
  controlLog.push({ control: 'negative', name, ...r });
  if (r.framed) controlsOk = false;
}

if (!AS_JSON) {
  console.log('controls:');
  for (const c of controlLog) {
    const want = c.control === 'positive' ? 'YES' : 'no';
    const got = c.framed ? 'YES' : 'no';
    console.log(ROW(`${c.control === 'positive' ? '+' : '-'} ${c.name}`, c)
      + `  want=${want} got=${got}${want === got ? '' : '  *** CONTROL FAILED ***'}`);
  }
}
if (!controlsOk) {
  console.error('\n*** CONTROLS FAILED — the gate is blind. Its verdict on the set below is meaningless. ***');
  process.exit(1);
}

const files = fs.readdirSync(DIR).filter(f => /\.(jpe?g|png)$/i.test(f)).sort();
const rows = [];
for (const f of files) rows.push({ file: f, ...analyse(path.join(DIR, f)) });
const hits = rows.filter(r => r.framed);

if (AS_JSON) {
  console.log(JSON.stringify({ controls: controlLog, controlsOk, scanned: files.length, rows, framed: hits }, null, 2));
} else {
  // 🔴 EVERY ROW, NOT ONLY THE HITS. A row that passes with no numbers printed is a row
  // nobody can diagnose later — which is exactly how a black border survived a day.
  console.log(`\ncontrols passed. scanned ${files.length} image(s):`);
  for (const r of rows) console.log(ROW(r.file, r));
  if (hits.length) {
    console.log('\nFRAMED — a manufactured surround, not a rectangular photograph:');
    for (const h of hits) {
      console.log(h.kind.includes('BORDER')
        ? `  ${h.file}  BORDER: flat frame ${h.borderDepths.join('/')} px of ${W}x${H}, one colour (agreement ${h.borderColourAgree}), contrast ${h.borderContrast}`
        : `  ${h.file}  DISC: corner agreement ${h.agree}, matte ${h.surroundPct}% of frame`);
    }
  } else {
    console.log('\nFRAMED: none');
  }
}
process.exit(hits.length ? 1 : 0);
