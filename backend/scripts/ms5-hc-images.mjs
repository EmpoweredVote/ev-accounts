#!/usr/bin/env node
/**
 * Harrison County portraits. The county's HTML is behind a Cloudflare challenge that refuses
 * every Node persona, but its FILES are served from cms9files.revize.com and fetch normally --
 * so the page URLs were read in Playwright and only the images are pulled here.
 * Each fetch is checked for an actual image, with a control that must NOT be one.
 */
import fs from 'node:fs';
const UA = { 'User-Agent': 'EmpoweredVote-asset-probe/1.0 (chris@empowered.vote)' };
const OUT = 'data/seed-ms-2026/_assets/harrison';
fs.mkdirSync(OUT, { recursive: true });
// The county's pages carry <base href="https://www.harrisoncountyms.gov/">, so every relative
// src resolves against the SITE ROOT, not the page directory. A raw src attribute is not the URL.
const BOS = 'https://www.harrisoncountyms.gov/';

const WANT = [
  ['d1',      'Dan Cuevas',      'Supervisor, District 1', BOS + 'IMG_1799.1.jpg'],
  ['d2',      'Rebecca Powers',  'Supervisor, District 2', BOS + 'Becca_2.jpg'],
  ['d3',      'Marlin Ladner',   'Supervisor, District 3', BOS + 'hc_ml-2016.jpg'],
  ['d4',      'Kent Jones',      'Supervisor, District 4', BOS + 'hc_kj-2016.jpg'],
  ['d5',      'Nathan Barrett',  'Supervisor, District 5', BOS + 'Nathan.5.1.jpg'],
  ['circuit', 'Justin Wetzel',   'Circuit Clerk',          BOS + 'images/JustinWetzelCountyPhoto.jpg'],
  ['assessor','Paula Ladner',    'Tax Assessor',           BOS + 'Paula__ - Copy.jpg'],
  ['collector','Sharon Barnett', 'Tax Collector',          BOS + 'images/hc-san.jpg'],
  ['CONTROL', 'n/a',             'n/a',                    BOS + 'no-such-portrait-ms5.jpg'],
];

const dims = (b) => {
  if (!(b[0] === 0xff && b[1] === 0xd8)) return null;
  let o = 2;
  while (o < b.length - 9) {
    if (b[o] !== 0xff) { o++; continue; }
    const mk = b[o + 1];
    if (mk >= 0xc0 && mk <= 0xcf && ![0xc4, 0xc8, 0xcc].includes(mk))
      return { h: b.readUInt16BE(o + 5), w: b.readUInt16BE(o + 7) };
    o += 2 + b.readUInt16BE(o + 2);
  }
  return null;
};

const rows = [];
for (const [slug, name, title, url] of WANT) {
  try {
    const r = await fetch(encodeURI(url), { headers: UA, redirect: 'follow' });
    const buf = Buffer.from(await r.arrayBuffer());
    const d = dims(buf);
    console.log(slug.padEnd(10) + String(r.status).padEnd(5) + String(buf.length).padStart(8) + 'B  ' +
      (d ? `${d.w}x${d.h}` : 'NOT-A-JPEG').padEnd(12) + (r.url !== encodeURI(url) ? '-> ' + r.url.slice(0, 55) : ''));
    if (d && slug !== 'CONTROL') { fs.writeFileSync(`${OUT}/${slug}.jpg`, buf); rows.push({ slug, name, title, url, w: d.w, h: d.h, bytes: buf.length }); }
    if (slug === 'CONTROL') console.log('CONTROL: ' + (d ? 'RETURNED AN IMAGE -- results above are uninterpretable' : 'correctly not an image'));
  } catch (e) { console.log(slug.padEnd(10) + 'ERROR ' + e.message); }
}
fs.writeFileSync('data/seed-ms-2026/_assets/harrison-fetch.json', JSON.stringify(rows, null, 2));
console.log(`\n${rows.length} portraits saved`);
