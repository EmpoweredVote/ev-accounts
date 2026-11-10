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
//   node scripts/check-portrait-framing.mjs <work-dir> --from-json <faces.json> [--known FILE]
//
// Exit 0 = no NEW framed portraits. Exit 1 = new ones found, or the CONTROLS failed. Exit 2
// = it could not get a set to judge, or the --known file is malformed.
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
// 🟢 IN CI SINCE 2026-11-09, in the "headshot faces" job, on the Sunday full sweep only.
// It reads check-headshot-faces.py's own --json output rather than querying the database, so
// both detectors scan one list decided by one piece of SQL; it re-fetches each image and checks
// the download against the sha256 that run recorded, and reports rather than judges anything
// whose bytes moved in between. data/headshot-framing-known.json holds the flags already looked
// at, keyed on (url, sha256) like data/headshot-accepted-flags.json, each one declared either a
// DEFECT (real, unfixed, a queue that should only shrink) or ACCEPTED (a real photograph this
// gate reads wrong, with the reason). Only a flag in neither list fails the build. It is still
// runnable by hand over a directory during a sourcing run, which is what it was built for.
//
// 🔴🔴 MEASURED OVER ALL 9,481 PUBLISHED HEADSHOTS, 2026-11-09, BEFORE IT WENT INTO CI — AND
// THE FIRST VERSION FLAGGED 44, OF WHICH 33 WERE REAL PHOTOGRAPHS. Every one of those 33 was a
// subject cut out on plain white or shot against a seamless studio backdrop. The flood-fill
// repair above is what let them in: a seamless backdrop IS connected to the frame edge, so
// "surround" was answering yes correctly and the predicate had nothing left that could tell a
// backdrop from a matte. The old corner-agreement bound of 30 did not separate them either —
// the header used to claim "every real studio backdrop measured >= 24", and the nearest one in
// the published corpus measures 18.
//   ▶ WHAT SEPARATES THEM IS THAT A DISC IS ROUND. The gate already walked the four corner
//     diagonals, and it threw away the only number on that walk that mattered: HOW FAR along
//     each one the surround ended. It counted the walks instead. A disc or an oval ends at the
//     same distance on all four; a person ends at their hair on the top two and their
//     shoulders on the bottom two. Measured: the three positive fixtures read 0, 1 and 3;
//     every one of the 11 real manufactured surrounds in the corpus read 0 to 2; the nearest
//     real photograph reads 8, then 8, 11, 13, 13, 14, … DISC_SPREAD = 6 sits in that gap,
//     and the corpus went from 44 flags to 12.
//   ▶ A COUNT OF EVENTS THREW AWAY THE MEASUREMENT OF THE EVENTS. That is the lesson worth
//     keeping: "steps >= 3" asked how many diagonals left the matte, which both shapes answer
//     the same way, while the distances it had already computed told them apart completely.
//
// 🔴 ALL 11 IT FOUND HAD PASSED THE FACE GATE, and two of them are the STATE SEAL OF WASHINGTON
// and the GREAT SEAL OF NORTH CAROLINA — seals that contain a portrait, so a face detector
// clears them honestly. The rest are oval crops, pillarboxed photographs and framed ones. Two
// detectors over one corpus, answering different questions.
//
// ⚠ THE ONE FLAG IT STILL GETS WRONG IS IN THE KNOWN FILE WITH ITS REASON: a cut-out portrait
// on plain white satisfies the BORDER branch, because when the subject reaches no edge every
// edge line really is flat and one colour, so the branch cannot tell a uniform BACKGROUND from
// a FRAME. Left as it is rather than tuned away on a sample of one.

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { execFileSync } from 'node:child_process';

const DIR = process.argv[2];
const AS_JSON = process.argv.includes('--json');
const flag = (name) => {
  const i = process.argv.indexOf(name);
  return i > 0 ? process.argv[i + 1] : null;
};
// 🔴 THE CORPUS COMES FROM THE FACE GATE'S OWN RESULT FILE, NOT FROM A SECOND QUERY.
// check-headshot-faces.py --json writes one record per published image: url, name, id, the
// publishing column, and THE SHA256 OF THE BYTES IT JUDGED. Reading that file means both gates
// scan the same list, decided by the same SQL, in the same run — there is no second corpus
// definition to drift out of step with the first, and no reason to touch that script at all.
// Images are fetched into <dir>/.corpus/<sha>.jpg and the download is skipped on a re-run.
const FROM_JSON = flag('--from-json');
// Flags already looked at, keyed on (url, sha256) exactly as data/headshot-accepted-flags.json
// is — the hash is the load-bearing half, because our storage overwrites a file IN PLACE, so a
// URL-keyed record would go on muting a path after a completely different picture was uploaded
// to it. Each entry declares which of two opposite things it is:
//   "defect"    a real manufactured surround, not yet re-sourced. A WORK QUEUE. It stays red in
//               the listing, it just does not fail the build a second time.
//   "accepted"  a real photograph this gate is wrong about, with the reason written down.
// 🔴 THEY ARE NOT INTERCHANGEABLE AND THE COUNT OF EACH IS THE POINT. A defect filed as an
// acceptance is a defect nobody will ever fix.
const KNOWN = flag('--known');
if (!DIR || (!fs.existsSync(DIR) && !FROM_JSON)) {
  console.error('usage: check-portrait-framing.mjs <dir-of-jpegs> [--json] [--known FILE]');
  console.error('       check-portrait-framing.mjs <work-dir> --from-json <check-headshot-faces --json output> [--known FILE]');
  process.exit(2);
}
fs.mkdirSync(DIR, { recursive: true });

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
    '-show_entries', 'stream=width,height', '-of', 'csv=p=0', file],
    { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
  return out.trim().split(',').map(Number);
}

const house = (inFile, outFile, pre = []) => execFileSync('ffmpeg', ['-y', '-v', 'error', '-i', inFile,
  '-vf', [...pre, "crop='min(iw,ih*4/5)':'min(ih,iw*5/4)'", 'scale=600:750:flags=lanczos'].join(','),
  '-q:v', '2', outFile], { stdio: ['ignore', 'ignore', 'pipe'] });

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
  // 🔴 CAPTURE ffmpeg's STDERR, DO NOT INHERIT IT. execFileSync sends a child's stderr to the
  // parent's unless stdio says otherwise, and a corpus sweep hits enough WebP files with a
  // malformed EXIF block to bury the gate's own output in thousands of warnings about images
  // that decoded perfectly. A real failure still arrives as a non-zero exit, and the message
  // is then read off the thrown error — which is where a diagnostic belongs anyway.
  execFileSync('ffmpeg', ['-y', '-v', 'error', '-i', file, '-vf', `scale=${W}:${H}`,
    '-pix_fmt', 'rgb24', '-f', 'rawvideo', raw], { stdio: ['ignore', 'ignore', 'pipe'] });
  const b = fs.readFileSync(raw);
  fs.unlinkSync(raw);
  return b;
}

const at = (b, x, y) => { const i = (y * W + x) * 3; return [b[i], b[i + 1], b[i + 2]]; };
const dist = (a, c) => Math.abs(a[0] - c[0]) + Math.abs(a[1] - c[1]) + Math.abs(a[2] - c[2]);
const meanOf = (px) => [0, 1, 2].map(k => px.reduce((s, p) => s + p[k], 0) / px.length);
const spreadOf = (px) => { const m = meanOf(px); return Math.sqrt(px.reduce((s, p) => s + dist(p, m) ** 2, 0) / px.length); };

const NEAR = 24;       // same colour family (L1 over RGB)
const FLAT_LINE = 12;  // a scan line is "flat along its length" below this spread
// A disc's four diagonal step-out distances may differ by at most this much. MEASURED, not
// chosen — see the header.
const DISC_SPREAD = 6;

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

  // The diagonal walk: a disc steps out of matte into content on every corner diagonal.
  // 🔴 HOW FAR ALONG EACH DIAGONAL IT STEPS OUT IS WHAT SEPARATES A DISC FROM A PERSON ON A
  // FLAT BACKGROUND, AND COUNTING THE STEPS DOES NOT ASK IT. A disc is radially symmetric, so
  // all four distances are the SAME. A subject cut out on white, or shot against a seamless
  // backdrop, also steps out on all four diagonals — into hair at the top and shoulders at the
  // bottom, at distances that are nothing like each other.
  let steps = 0;
  const stepAt = [];
  for (const [sx, sy, dx, dy] of [[0, 0, 1, 1], [W - 1, 0, -1, 1], [0, H - 1, 1, -1], [W - 1, H - 1, -1, -1]]) {
    let x = sx, y = sy, seenMatte = 0, stepped = false, where = -1;
    for (let t = 0; t < Math.min(W, H) / 2; t++) {
      if (dist(at(b, Math.round(x), Math.round(y)), bg) < NEAR) { if (!stepped) seenMatte++; }
      else if (seenMatte >= 6) { stepped = true; where = t; break; }
      x += dx * 0.8; y += dy;
    }
    if (stepped) { steps++; stepAt.push(where); }
  }
  // 999 when some diagonal never left the surround: a shape that is not closed is not a disc.
  const discSpread = stepAt.length === 4 ? Math.max(...stepAt) - Math.min(...stepAt) : 999;

  const disc = cornerFlat && agree < 30 && surroundPct > 12 && centreSurroundPct < 4
    && steps >= 3 && discSpread < DISC_SPREAD;
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
    steps, stepAt, discSpread,
    borderDepths: bm.depths, borderColourAgree: bm.colourAgree, borderContrast: bm.contrast,
    disc, bordered: bm.bordered,
    kind: kinds.join('+') || '',
    framed: disc || bm.bordered,
  };
}

const ROW = (label, r) => `  ${label.padEnd(40)} flat=${String(r.cornerFlat).padEnd(5)}`
  + ` agree=${String(r.agree).padEnd(4)} surround=${String(r.surroundPct).padEnd(5)}`
  + ` ctrSurr=${String(r.centreSurroundPct).padEnd(5)} steps=${r.steps}`
  + ` spread=${String(r.discSpread).padEnd(4)}`
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

// Fetch the face gate's corpus into <DIR>/.corpus, named by the sha256 IT recorded.
const manifest = {};
let SCAN_DIR = DIR;
if (FROM_JSON) {
  SCAN_DIR = path.join(DIR, '.corpus');
  fs.mkdirSync(SCAN_DIR, { recursive: true });
  const faceRows = JSON.parse(fs.readFileSync(FROM_JSON, 'utf8'));
  const wanted = faceRows.filter(r => r && r.url && r.sha256);
  console.log(`fetching ${wanted.length} image(s) named in ${FROM_JSON}`
    + ` (${faceRows.length - wanted.length} had no bytes to hash and are skipped)`);
  let got = 0, cached = 0, failed = 0, drifted = 0;
  const queue = wanted.slice();
  const take = async () => {
    for (let r = queue.shift(); r; r = queue.shift()) {
      const dest = path.join(SCAN_DIR, r.sha256 + '.jpg');
      manifest[r.sha256 + '.jpg'] = { url: r.url, name: r.name, id: r.id, sites: r.sites || [] };
      if (fs.existsSync(dest)) { cached++; continue; }
      try {
        const res = await fetch(r.url, { headers: { 'User-Agent': UA, Accept: 'image/*,*/*' } });
        if (!res.ok) { failed++; continue; }
        const buf = Buffer.from(await res.arrayBuffer());
        // 🔴 CHECK THE HASH. The face gate fetched this URL minutes ago; our storage overwrites
        // in place, so the bytes CAN have changed underneath. If they have, the (url, sha256)
        // key this gate is about to judge against is not the one the face gate recorded, and a
        // silent mismatch would quietly make every recorded judgement on that row meaningless.
        const sha = crypto.createHash('sha256').update(buf).digest('hex');
        if (sha !== r.sha256) { drifted++; manifest[r.sha256 + '.jpg'].drifted = sha; continue; }
        fs.writeFileSync(dest, buf);
        got++;
      } catch { failed++; }
    }
  };
  await Promise.all(Array.from({ length: 16 }, take));
  console.log(`  fetched ${got}, already cached ${cached}, would not fetch ${failed}, changed under us ${drifted}`);
  if (drifted) console.log('  (a changed file is left for the NEXT run, when the face gate will have rehashed it)');
  if (!got && !cached) { console.error('nothing fetched — refusing to report a verdict on an empty set'); process.exit(2); }
}

const known = KNOWN && fs.existsSync(KNOWN)
  ? JSON.parse(fs.readFileSync(KNOWN, 'utf8')) : { entries: [] };
const keyOf = (r) => `${r.url || ''} ${String(r.file || '').replace(/\.jpe?g$/i, '')}`;
const knownKeys = new Map((known.entries || []).map(e => [`${e.url} ${e.sha256}`, e]));
for (const e of known.entries || []) {
  if (e.kind !== 'defect' && e.kind !== 'accepted') {
    console.error(`${KNOWN}: entry "${e.name || e.url}" has kind "${e.kind}" — it must say which of the two it is.`);
    process.exit(2);
  }
}

// 🔴 UNDER --from-json THE SET IS THE MANIFEST, NOT WHATEVER IS IN THE DIRECTORY. The cache is
// content-addressed, so a file whose bytes changed leaves its OLD copy sitting there under the
// old hash. A readdir would scan that orphan, find no manifest row for it, and report it as a
// NEW framed portrait belonging to nobody — a finding manufactured entirely by the cache.
const files = (FROM_JSON
  ? Object.keys(manifest).filter(f => fs.existsSync(path.join(SCAN_DIR, f)))
  : fs.readdirSync(SCAN_DIR).filter(f => /\.(jpe?g|png)$/i.test(f))).sort();
const rows = [];
for (const f of files) {
  const who = manifest[f] || {};
  // 🔴 ONE UNREADABLE FILE MUST NOT END THE SWEEP. Over a hand-picked directory a throw is
  // survivable; over a whole published corpus it means the other 9,000 rows are never judged,
  // and the failure reads as "the gate is broken" rather than "this one file is not an image".
  try {
    rows.push({ file: f, ...who, ...analyse(path.join(SCAN_DIR, f)) });
  } catch (e) {
    const detail = (e.stderr && e.stderr.toString().trim().split('\n').pop()) || e.message || String(e);
    rows.push({ file: f, ...who, unreadable: true, error: String(detail).slice(0, 140), framed: false });
  }
}
for (const r of rows) r.known = knownKeys.get(keyOf(r)) || null;
const hits = rows.filter(r => r.framed);
const fresh = hits.filter(r => !r.known);
const queued = hits.filter(r => r.known && r.known.kind === 'defect');
const excused = hits.filter(r => r.known && r.known.kind !== 'defect');
const resolved = (known.entries || []).filter(e =>
  !hits.some(h => keyOf(h) === `${e.url} ${e.sha256}`));
const unreadable = rows.filter(r => r.unreadable);

// A row that satisfies every disc condition but one is the shape Lee's black border had, and
// for a day it printed nothing at all. Name the single condition that saved each near miss.
const NEAR_MISS = (r) => {
  if (r.unreadable || r.framed) return null;
  const fails = [];
  if (!r.cornerFlat) fails.push('corners not flat');
  if (!(r.agree < 30)) fails.push(`corner agreement ${r.agree}`);
  if (!(r.surroundPct > 12)) fails.push(`surround only ${r.surroundPct}%`);
  if (!(r.centreSurroundPct < 4)) fails.push(`centre ${r.centreSurroundPct}% surround`);
  if (!(r.steps >= 3)) fails.push(`steps ${r.steps}`);
  if (!(r.discSpread < DISC_SPREAD)) fails.push(`diagonal spread ${r.discSpread}`);
  return fails.length === 1 ? fails[0] : null;
};

if (AS_JSON) {
  console.log(JSON.stringify({ controls: controlLog, controlsOk, scanned: files.length,
    rows, framed: hits, fresh, resolved, unreadable }, null, 2));
} else {
  // 🔴 EVERY ROW, NOT ONLY THE HITS. A row that passes with no numbers printed is a row
  // nobody can diagnose later — which is exactly how a black border survived a day.
  // ⚠ Over a whole published corpus that is ~9,500 lines nobody reads, so past a few hundred
  // images the per-row dump moves to --json and the console keeps what the rule was FOR:
  // every hit, and every row that failed exactly ONE condition.
  console.log(`\ncontrols passed. scanned ${files.length} image(s):`);
  if (files.length <= 200) {
    for (const r of rows) console.log(r.unreadable ? `  ${r.file.padEnd(40)} UNREADABLE — ${r.error}` : ROW(r.file, r));
  } else {
    const near = rows.map(r => [r, NEAR_MISS(r)]).filter(([, m]) => m);
    console.log('  (per-row numbers are in --json; the near misses below are the rest of that rule)');
    console.log(`\n${near.length} row(s) failed EXACTLY ONE disc condition — the shape the Lee border had:`);
    for (const [r, m] of near.slice(0, 40)) console.log(`  ${String(r.name || r.file).slice(0, 34).padEnd(34)} saved only by: ${m}`);
    if (near.length > 40) console.log(`  … and ${near.length - 40} more, in --json`);
  }
  if (unreadable.length) {
    console.log(`\n${unreadable.length} file(s) could not be read as an image:`);
    for (const u of unreadable.slice(0, 20)) console.log(`  ${String(u.name || u.file).slice(0, 34).padEnd(34)} ${u.error}`);
  }
  if (hits.length) {
    console.log('\nFRAMED — a manufactured surround, not a rectangular photograph:');
    for (const h of hits) {
      const who = h.name ? `${String(h.name).slice(0, 28).padEnd(28)} ` : '';
      const mark = !h.known ? ' NEW  ' : (h.known.kind === 'defect' ? ' TODO ' : ' OK   ');
      console.log(mark + who + (h.kind.includes('BORDER')
        ? `BORDER: flat frame ${h.borderDepths.join('/')} px of ${W}x${H}, one colour (agreement ${h.borderColourAgree}), contrast ${h.borderContrast}`
        : `DISC: corner agreement ${h.agree}, matte ${h.surroundPct}% of frame, diagonal spread ${h.discSpread}`)
        + (h.url ? `\n        ${h.url}` : `  [${h.file}]`));
    }
    if (queued.length || excused.length) console.log(`\n  recorded in ${KNOWN}:`);
    if (queued.length) console.log(`    DEFECT    ${String(queued.length).padStart(4)} — real manufactured surrounds, still published, owed a re-source.`);
    if (excused.length) console.log(`    ACCEPTED  ${String(excused.length).padStart(4)} — real photographs this gate reads wrong, reason recorded.`);
  } else {
    console.log('\nFRAMED: none');
  }
  if (resolved.length) {
    console.log(`\n${resolved.length} recorded defect(s) no longer flag. Re-sourced, or the bytes changed — drop them from ${KNOWN}:`);
    for (const e of resolved) console.log(`  ${String(e.name || e.url).slice(0, 60)}`);
  }
  if (fresh.length) {
    console.log(`\n${fresh.length} NEW framed portrait(s). LOOK AT THESE. A manufactured surround is not`);
    console.log('a photograph of the person: re-source it, or crop the surround off.');
  }
}
process.exit(fresh.length ? 1 : 0);
