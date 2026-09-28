#!/usr/bin/env node
/**
 * build-ks-portrait-manifest.mjs — Knight program, wave KS-5.
 *
 * Builds the roster of Kansas legislator portrait URLs from kslegislature.gov, and measures every
 * image before anything is imported. Writes JSON; touches no database and uploads nothing.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────
 * 🔴 THIS SITE'S PAGINATOR CLAMPS INSTEAD OF ENDING. KS-2 paid for it reading the journals:
 * `per_page=200` returns FEWER rows than the default 20, and the last page repeats for ever. So
 * this pages at the site's own `per_page=20`, stops at a KNOWN TOTAL (125 House, 40 Senate), and
 * aborts if a page returns nothing new — a repeat is a clamp, not an end.
 *
 * 🔴 A MEMBER WITH NO PHOTO GETS A PLACEHOLDER IN THE BROWSER, NOT AN ERROR. Every member page
 * carries `onerror="this.src='/static/li_pics/fallback.<hash>.jpg'"`. A scraper reading `src` gets
 * the member path, which 404s honestly — but the placeholder is also directly fetchable, so any
 * pipeline that follows a fallback would import a silhouette under a real name. Every download is
 * therefore hashed and compared against the placeholder's own bytes.
 *
 * ⚠ A LARGER FILE IS NOT A LARGER IMAGE. `?width=1200` on a portrait returns a file nearly twice
 * the bytes — and the identical 205x300 pixels. The host alternates between two JPEG encodings of
 * the same image and ignores the parameter. The SC-5 rule (the resize can be in the query string,
 * 150px -> 2944px) was tested here and does NOT hold; `_large` and `.png` are hard 404s. So the
 * upscale factor this manifest reports is real and cannot be engineered away at this source.
 *
 * 🟢 EVERY PORTRAIT CARRIES A PER-IMAGE `alt` WITH THE MEMBER'S NAME. That is the only thing that
 * catches the wrong-person error, so the manifest records it and flags any mismatch against the
 * roster name rather than trusting the filename slug.
 *
 * Usage:
 *   node scripts/build-ks-portrait-manifest.mjs            # writes the manifest
 *   node scripts/build-ks-portrait-manifest.mjs --sample=8 # measure only N per chamber, for a probe
 */
import fs from 'node:fs';
import path from 'node:path';

const UA = { 'User-Agent': 'ev-accounts/ks-slice14', Accept: 'text/html' };
const BASE = 'https://kslegislature.gov';
const OUT = 'data/seed-ks-2026/ks-portrait-manifest.json';
const PICDIR = 'data/seed-ks-2026/portraits';

const CHAMBERS = [
  { key: 'house', label: 'Kansas House of Representatives', url: '/b2025_26/house/representatives/', expect: 125 },
  { key: 'senate', label: 'Kansas Senate', url: '/b2025_26/senate/senators/', expect: 40 },
];

const arg = (k) => process.argv.find((a) => a.startsWith(`--${k}=`))?.split('=')[1];
const SAMPLE = arg('sample') ? Number(arg('sample')) : null;

const fail = (m) => { console.error(`\n🔴 ${m}`); process.exit(1); };
const sha1 = async (buf) => {
  const d = await crypto.subtle.digest('SHA-1', buf);
  return [...new Uint8Array(d)].map((b) => b.toString(16).padStart(2, '0')).join('');
};

async function getText(url, label) {
  const r = await fetch(url, { headers: UA });
  const t = await r.text();
  if (!r.ok) fail(`${label}: HTTP ${r.status}`);
  return t;
}

/** Pull (slug, name, photo) triples out of one roster page. */
function parsePage(html) {
  const out = [];
  // Each card links the member and carries their portrait with an alt naming them.
  const cards = html.split(/<a\s+[^>]*href="\/b2025_26\/legislators\//i).slice(1);
  for (const c of cards) {
    const slug = c.match(/^([a-z0-9_]+)\//i)?.[1];
    if (!slug) continue;
    const pic = c.match(/\/static\/li_pics\/([a-z0-9_.]+)\.jpg/i)?.[1];
    const alt = c.match(/<img[^>]*alt="([^"]*)"/i)?.[1];
    const name = alt || c.match(/>([^<>{}]{3,60})<\/(?:span|h[23]|strong)>/)?.[1];
    out.push({ slug, pic: pic ?? null, alt: alt ?? null, name: name?.trim() ?? null });
  }
  return out;
}

async function collect(ch) {
  const seen = new Map();
  for (let page = 1; page <= 40; page++) {
    const url = `${BASE}${ch.url}?page=${page}&party=&q=&sort=name&dir=asc&per_page=20`;
    const html = await getText(url, `${ch.key} page ${page}`);
    const rows = parsePage(html);
    const before = seen.size;
    for (const r of rows) if (!seen.has(r.slug)) seen.set(r.slug, r);
    // 🔴 A page that adds nothing is the CLAMP, not the end.
    if (seen.size === before) {
      if (seen.size < ch.expect) {
        fail(`${ch.key}: page ${page} added no new members and only ${seen.size}/${ch.expect} are ` +
             `collected. The paginator has clamped — it repeats its last page rather than ending.`);
      }
      break;
    }
    if (seen.size >= ch.expect) break;
  }
  if (seen.size !== ch.expect) {
    fail(`${ch.key}: collected ${seen.size} members, expected ${ch.expect}. Refusing a partial roster.`);
  }
  return [...seen.values()];
}

// The placeholder's own bytes, so a silhouette can never be imported under a real name.
const fallbackBuf = await (await fetch(`${BASE}/static/li_pics/fallback.8b887e28e491.jpg`, { headers: UA })).arrayBuffer();
const FALLBACK_SHA = await sha1(fallbackBuf);
console.log(`placeholder sha1 ${FALLBACK_SHA.slice(0, 12)} (${fallbackBuf.byteLength} bytes) — every download is compared against it\n`);

fs.mkdirSync(PICDIR, { recursive: true });
const manifest = [];
for (const ch of CHAMBERS) {
  const members = await collect(ch);
  console.log(`${ch.label}: ${members.length} members collected`);
  const take = SAMPLE ? members.slice(0, SAMPLE) : members;
  let n = 0;
  for (const m of take) {
    const picSlug = m.pic ?? m.slug;
    const url = `${BASE}/static/li_pics/${picSlug}.jpg`;
    const r = await fetch(url, { headers: { 'User-Agent': UA['User-Agent'] } });
    const rec = {
      chamber: ch.label, slug: m.slug, name: m.name, alt: m.alt, url,
      status: r.status, bytes: 0, width: null, height: null,
      is_placeholder: false, upscale: null, notes: [],
    };
    if (r.ok) {
      const buf = await r.arrayBuffer();
      rec.bytes = buf.byteLength;
      const hash = await sha1(buf);
      rec.is_placeholder = hash === FALLBACK_SHA;
      // ⚠ Dimensions are NOT read here. A hand-rolled SOF walker returned null on some of these
      // files, and a null size reported as "no upscale" is worse than no number at all. The bytes
      // are saved and measure-ks-portraits.py decodes them properly.
      rec.file = `${PICDIR}/${picSlug}.jpg`;
      fs.writeFileSync(rec.file, Buffer.from(buf));
    }
    if (rec.status !== 200) rec.notes.push('NO PHOTO PUBLISHED');
    if (rec.is_placeholder) rec.notes.push('PLACEHOLDER SILHOUETTE — do not import');
    if (!rec.alt) rec.notes.push('NO ALT — identity unverified, look at the face');
    else if (m.name && rec.alt.trim() !== m.name.trim()) rec.notes.push(`ALT DISAGREES WITH ROSTER: "${rec.alt}"`);
    if (rec.upscale && rec.upscale > 1) rec.notes.push(`upscale ${rec.upscale}x`);
    manifest.push(rec);
    if (++n % 25 === 0) console.log(`  …${n}/${take.length}`);
  }
}

fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, JSON.stringify(manifest, null, 1));

const ok = manifest.filter((m) => m.status === 200 && !m.is_placeholder);
const missing = manifest.filter((m) => m.status !== 200);
const placeholder = manifest.filter((m) => m.is_placeholder);
const noAlt = manifest.filter((m) => !m.alt);
const mismatch = manifest.filter((m) => m.notes.some((n) => n.startsWith('ALT DISAGREES')));

console.log(`\nwrote ${OUT}`);
console.log(`  usable            ${ok.length}`);
console.log(`  no photo (404)    ${missing.length}`);
console.log(`  placeholder       ${placeholder.length}`);
console.log(`  no alt            ${noAlt.length}`);
console.log(`  alt ≠ roster name ${mismatch.length}`);
console.log(`  saved to          ${PICDIR}/`);
console.log('');
console.log('▶ now run: python scripts/measure-ks-portraits.py   (decodes every file and adds sizes)');
