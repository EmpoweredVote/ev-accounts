/**
 * sweep-in-legislature-headshots.mjs — fetch all 150 Indiana legislator portraits from iga.in.gov.
 *
 * 🔴 WHY THIS USES A BROWSER AND NOT curl/fetch.
 * iga.in.gov answers a non-browser client with HTTP 200, `content-type: text/html` and 691 bytes
 * of React shell — FOR THE IMAGE URLS TOO, not only for pages. `%{http_code}` reports success on
 * the failing path, and a 691-byte file named `.jpg` looks like a fetched portrait until you
 * decode it. IN-2 met the same wall on both KMZ downloads and `getLegislatorDetails`. Only an
 * in-page `fetch()` on the iga.in.gov origin returns the real bytes.
 *
 * 🔴 WHY THE EXTENSION IS DECIDED BY MAGIC NUMBER.
 * `legislator_mark_spencer_1.jpg`, served as `image/jpeg`, is a PNG. Both the URL and the header
 * lie. The sniffed magic number is the only honest answer, and it is what names the output file.
 *
 * 🔴 AND WHY THE USER AGENT IS SET. Measured 2026-09-11: headless Chromium with Playwright's
 * default `HeadlessChrome` UA is served the 691-byte shell for every image, and the page's own
 * <img> does not load either. The SAME headless browser with a real Chrome UA gets 120,801 bytes
 * of JPEG. Playwright is not the fix on this host — the UA is — and the rejection arrives as
 * HTTP 200, never a 403.
 *
 * 🔴 THE CONTROL IS PAIRED, AND THAT IS THE POINT. The first version asserted only that a bogus
 * lpid returns no image. That is satisfied when NOTHING returns an image: it certified a sweep in
 * which all 150 were blocked. A negative control needs a positive one taken in the same breath —
 * a known-good lpid that MUST decode. Both run again after the sweep, so a block that begins
 * midway is told apart from members the source genuinely lacks. Then a distinctness check over
 * the sha256 set catches a placeholder silhouette served to several members.
 *
 *   node scripts/sweep-in-legislature-headshots.mjs
 */
import { chromium } from 'playwright';
import { createHash } from 'node:crypto';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';

const ROOT = 'data/seed-in-legislature-2026/headshots';
const RAW = join(ROOT, 'raw');
mkdirSync(RAW, { recursive: true });

const roster = JSON.parse(readFileSync('data/in-legislature-roster.json', 'utf8')).roster;
const ANCHOR = 'https://iga.in.gov/legislative/2026/legislators/legislator_carolyn_jackson_1';
const imgUrl = (chamber, lpid) =>
  `https://iga.in.gov/images/legislators/124/2026/${chamber === 'STATE_UPPER' ? 'senate' : 'house'}/${lpid}.jpg`;

function sniff(buf) {
  if (buf.length >= 3 && buf[0] === 0xff && buf[1] === 0xd8 && buf[2] === 0xff) return 'jpg';
  if (buf.length >= 8 && buf.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) return 'png';
  if (buf.length >= 12 && buf.subarray(0, 4).toString('latin1') === 'RIFF' && buf.subarray(8, 12).toString('latin1') === 'WEBP') return 'webp';
  if (buf.length >= 4 && buf.subarray(0, 4).toString('latin1') === 'GIF8') return 'gif';
  return null;
}

// IGA_UA exists so the paired control can be WATCHED FAILING: run with IGA_UA=HeadlessChrome and
// the positive half must raise. A control nobody has seen fail is a decoration.
const UA = process.env.IGA_UA || 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36';
const browser = await chromium.launch();
const context = await browser.newContext({ userAgent: UA });
const page = await context.newPage();
await page.goto(ANCHOR, { waitUntil: 'domcontentloaded' });

// One fetch, inside the page, returning base64. Keeps the browser's TLS/network stack.
async function grab(url) {
  return page.evaluate(async (u) => {
    const r = await fetch(u);
    const b = new Uint8Array(await r.arrayBuffer());
    let s = '';
    for (let i = 0; i < b.length; i += 0x8000) s += String.fromCharCode.apply(null, b.subarray(i, i + 0x8000));
    return { status: r.status, ct: r.headers.get('content-type'), b64: btoa(s) };
  }, url);
}

// ---- THE PAIRED CONTROL. Negative alone is worthless: it passes when everything is blocked.
const CTL_BOGUS = imgUrl('STATE_LOWER', 'legislator_nobody_at_all_999');
const CTL_GOOD = imgUrl('STATE_LOWER', 'legislator_carolyn_jackson_1');
async function pairedControl(when) {
  const neg = await grab(CTL_BOGUS); const negBuf = Buffer.from(neg.b64, 'base64'); const negFmt = sniff(negBuf);
  const pos = await grab(CTL_GOOD);  const posBuf = Buffer.from(pos.b64, 'base64'); const posFmt = sniff(posBuf);
  console.log(`CONTROL ${when}  negative(bogus lpid): ${neg.status} ${neg.ct} ${negBuf.length}B -> ${negFmt ?? 'not an image'}`);
  console.log(`CONTROL ${when}  positive(known good): ${pos.status} ${pos.ct} ${posBuf.length}B -> ${posFmt ?? 'not an image'}`);
  if (negFmt !== null) throw new Error(`CONTROL ${when} FAILED: a legislator who does not exist returned a decodable image.`);
  if (posFmt === null) throw new Error(`CONTROL ${when} FAILED: a known-good legislator returned no image — the sweep is blocked, not the source empty.`);
  return { when, negative_bytes: negBuf.length, negative_sniffed: negFmt, positive_bytes: posBuf.length, positive_sniffed: posFmt };
}
const ctlBefore = await pairedControl('BEFORE');

const rows = [];
for (const m of roster) {
  const url = imgUrl(m.chamber, m.iga_lpid);
  let rec = {
    chamber: m.chamber, district: m.district, full_name: m.full_name, iga_lpid: m.iga_lpid, url,
  };
  try {
    const r = await grab(url);
    const buf = Buffer.from(r.b64, 'base64');
    const fmt = sniff(buf);
    rec = { ...rec, status: r.status, content_type: r.ct, bytes: buf.length, format: fmt,
            sha256: createHash('sha256').update(buf).digest('hex') };
    if (fmt) {
      rec.file = `${m.iga_lpid}.${fmt}`;
      writeFileSync(join(RAW, rec.file), buf);
    } else {
      rec.note = 'NOT AN IMAGE — shell or error body';
    }
  } catch (e) {
    rec = { ...rec, status: null, note: `FETCH THREW: ${e}` };
  }
  rows.push(rec);
  const tag = rec.format ? `${rec.format} ${rec.bytes}` : `🔴 ${rec.note}`;
  console.log(`${rec.chamber === 'STATE_UPPER' ? 'SD' : 'HD'}-${String(rec.district).padEnd(3)} ${rec.full_name.padEnd(26)} ${tag}`);
}

// The same pair again: a block that began midway looks exactly like a source missing members.
const ctlAfter = await pairedControl('AFTER');
await browser.close();

writeFileSync(join(ROOT, 'manifest.json'),
  JSON.stringify({ generated_at: new Date().toISOString(),
                   source: 'iga.in.gov/images/legislators/124/2026/{chamber}/{iga_lpid}.jpg',
                   controls: [ctlBefore, ctlAfter],
                   control_urls: { negative: CTL_BOGUS, positive: CTL_GOOD },
                   rows }, null, 2));

// ---- CONTROL 2, AFTER the sweep: distinctness. A placeholder served to several members
// would otherwise read as full coverage.
const ok = rows.filter((r) => r.format);
const hashes = new Set(ok.map((r) => r.sha256));
console.log(`\n${ok.length} of ${rows.length} decoded. ${hashes.size} distinct sha256.`);
if (hashes.size !== ok.length) {
  const seen = new Map();
  for (const r of ok) { (seen.get(r.sha256) ?? seen.set(r.sha256, []).get(r.sha256)).push(r.full_name); }
  for (const [h, names] of seen) if (names.length > 1) console.log(`🔴 SHARED IMAGE ${h.slice(0, 12)}: ${names.join(', ')}`);
}
const byFmt = {};
for (const r of ok) byFmt[r.format] = (byFmt[r.format] ?? 0) + 1;
console.log('formats:', byFmt);
for (const r of rows.filter((x) => !x.format)) console.log(`🔴 NO IMAGE: ${r.chamber} ${r.district} ${r.full_name} — ${r.note}`);
