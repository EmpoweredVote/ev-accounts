/**
 * compare-in-small-against-openstates.mjs — for every IGA portrait below 600x750, fetch the
 * Open States `image` URL and measure it, so the larger of the two can be kept.
 *
 * 🔴 SIZE DOES NOT OUTRANK SOURCE. The Open States column is a mixed bag: caucus sites (official),
 * Ballotpedia thumbnails, a vendor bucket literally named `enview-dev-public-general`, four
 * campaign sites, and one asset filed under `/banners/`. A campaign photo that happens to be
 * bigger is still not press/official/PD. Each row is therefore tagged with its host class, and
 * a win by a non-official host is REPORTED rather than applied.
 *
 * 🔴 AND PIXEL COUNT IS NOT SIZE EITHER. A crop out of a wide banner can carry more pixels than a
 * portrait while holding less face. Rows are compared on `usable` — the height of the largest 4:5
 * box the image can yield, min(h, w/0.8) — not on w*h.
 *
 * Uses APIRequestContext (no CORS, browser-like stack) with a real Chrome UA, for the reason in
 * sweep-in-legislature-headshots.mjs.
 */
import { chromium } from 'playwright';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';

const ROOT = 'data/seed-in-legislature-2026/headshots';
const ALT = join(ROOT, 'alt');
mkdirSync(ALT, { recursive: true });
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36';

const measured = JSON.parse(readFileSync(join(ROOT, 'measured.json'), 'utf8'));
const roster = JSON.parse(readFileSync('data/in-legislature-roster.json', 'utf8')).roster;
const osByLpid = new Map(roster.map((m) => [m.iga_lpid, (m.openstates_image || '').trim()]));

// Host classes. OFFICIAL = the chamber's or caucus's own publication, plus Ballotpedia, which this
// programme has used since GA. CAMPAIGN and AGGREGATOR fail the press/official/PD rule.
const CLASS = [
  [/(^|\.)indianahouserepublicans\.com$/, 'OFFICIAL caucus'],
  [/(^|\.)indianahousedemocrats\.org$/, 'OFFICIAL caucus'],
  [/(^|\.)indianasenatedemocrats\.org$/, 'OFFICIAL caucus'],
  [/(^|\.)cdn\.zephyrcms\.com$/, 'OFFICIAL caucus CDN (Senate GOP)'],
  [/(^|\.)s3\.amazonaws\.com$/, 'Ballotpedia'],
  [/(^|\.)storage\.googleapis\.com$/, 'AGGREGATOR vendor bucket'],
  [/(^|\.)static\.wixstatic\.com$/, 'CAMPAIGN site'],
  [/(^|\.)img1\.wsimg\.com$/, 'CAMPAIGN site'],
  [/(^|\.)cdn\.myocv\.com$/, 'CAMPAIGN site'],
  [/(^|\.)friendsoftonyisa\.com$/, 'CAMPAIGN site'],
];
const classify = (u) => {
  if (!u) return 'NONE';
  const h = new URL(u).hostname;
  if (/\/banners\//.test(u)) return 'OFFICIAL caucus (BANNER asset, not a headshot)';
  for (const [re, c] of CLASS) if (re.test(h)) return c;
  return `UNCLASSIFIED ${h}`;
};

function sniff(b) {
  if (b.length >= 3 && b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff) return 'jpg';
  if (b.length >= 8 && b.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) return 'png';
  if (b.length >= 12 && b.subarray(0, 4).toString('latin1') === 'RIFF' && b.subarray(8, 12).toString('latin1') === 'WEBP') return 'webp';
  if (b.length >= 4 && b.subarray(0, 4).toString('latin1') === 'GIF8') return 'gif';
  return null;
}

const small = measured.filter((m) => m.w < 600 || m.h < 750);
console.log(`${small.length} IGA portraits below 600x750.\n`);

const browser = await chromium.launch();
const ctx = await browser.newContext({ userAgent: UA });

// Paired control on THIS fetch path too — a known-good caucus image and a bogus one on the
// same host. Without it, "every Open States URL is dead" reads as a finding about the source.
const goodOs = roster.find((m) => /indianahouserepublicans\.com/.test(m.openstates_image || ''))?.openstates_image;
const negOs = new URL(goodOs).origin + '/no-such-image-at-all-9f2c.jpg';
for (const [label, u, mustDecode] of [['positive', goodOs, true], ['negative', negOs, false]]) {
  const r = await ctx.request.get(u, { failOnStatusCode: false });
  const b = Buffer.from(await r.body());
  const fmt = sniff(b);
  console.log(`CONTROL ${label.padEnd(8)} ${r.status()} ${b.length}B -> ${fmt ?? 'not an image'}`);
  if (mustDecode && !fmt) throw new Error('CONTROL FAILED: a known-good caucus image did not decode — this fetch path is blocked.');
  if (!mustDecode && fmt) throw new Error('CONTROL FAILED: a URL for no image returned one.');
}
console.log('');

const rows = [];
for (const m of small) {
  const u = osByLpid.get(m.iga_lpid);
  const rec = { chamber: m.chamber, district: m.district, full_name: m.full_name, iga_lpid: m.iga_lpid,
                iga: { w: m.w, h: m.h, bytes: m.bytes, format: m.format, file: m.file },
                openstates_url: u || null, host_class: classify(u) };
  if (u) {
    try {
      const r = await ctx.request.get(u, { failOnStatusCode: false });
      const b = Buffer.from(await r.body());
      const fmt = sniff(b);
      rec.os = { status: r.status(), bytes: b.length, format: fmt };
      if (fmt) {
        rec.os.file = `${m.iga_lpid}.os.${fmt}`;
        writeFileSync(join(ALT, rec.os.file), b);
      } else rec.os.note = 'NOT AN IMAGE';
    } catch (e) { rec.os = { note: `THREW ${e}` }; }
  }
  rows.push(rec);
}
await browser.close();
writeFileSync(join(ROOT, 'small-compare.json'), JSON.stringify(rows, null, 2));
console.log(`wrote ${ROOT}/small-compare.json — ${rows.filter((r) => r.os?.file).length} alternates downloaded`);
