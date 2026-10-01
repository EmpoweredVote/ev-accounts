#!/usr/bin/env node
import fs from 'node:fs';
const UA = { 'User-Agent': 'EmpoweredVote-asset-probe/1.0 (chris@empowered.vote)' };
const OUT = 'data/seed-ms-2026/_assets/harrison';
fs.mkdirSync(OUT, { recursive: true });

// The sheriff's Administration page may carry a rectangular portrait; the homepage one is a
// circle crop, and a transparent circle flattened into a 4:5 JPEG would ship with hard corners.
const r = await fetch('https://www.harrisoncountysheriff.com/administration', { headers: UA });
const html = await r.text();
console.log('administration HTTP', r.status, html.length, 'final', r.url);
for (const m of html.matchAll(/<img\b[^>]*>/gi)) {
  const s = /src\s*=\s*["']([^"']+)["']/i.exec(m[0]);
  const a = /alt\s*=\s*["']([^"']*)["']/i.exec(m[0]);
  if (s && !/menus|ico|logo|sprite/i.test(s[1])) console.log('   ' + new URL(s[1], r.url).href + '\n      alt=' + JSON.stringify(a ? a[1] : null));
}

const info = (b) => {
  if (b[0] === 0x89 && b.subarray(1,4).toString() === 'PNG')
    return { type:'PNG', w: b.readUInt32BE(16), h: b.readUInt32BE(20), alpha: [4,6].includes(b[25]) };
  if (b[0] === 0xff && b[1] === 0xd8) {
    let o = 2;
    while (o < b.length - 9) {
      if (b[o] !== 0xff) { o++; continue; }
      const mk = b[o+1];
      if (mk >= 0xc0 && mk <= 0xcf && ![0xc4,0xc8,0xcc].includes(mk)) return { type:'JPEG', w: b.readUInt16BE(o+7), h: b.readUInt16BE(o+5), alpha:false };
      o += 2 + b.readUInt16BE(o+2);
    }
  }
  return { type:'?', w:0, h:0 };
};

const GRAB = [
  ['sheriff-circle',      'https://ik.imagekit.io/hcso/theme/assets/pages/sheriff-circle.png'],
  ['sheriff-circle-orig', 'https://ik.imagekit.io/hcso/theme/assets/pages/sheriff-circle.png?tr=orig-true'],
  ['chancery-thrash',     'http://harrisoncountymschanceryclerk.gov/_images/hc_athrash_3a.jpg'],
];
console.log('');
for (const [slug, url] of GRAB) {
  const rr = await fetch(url, { headers: UA });
  const buf = Buffer.from(await rr.arrayBuffer());
  const i = info(buf);
  console.log(slug.padEnd(22) + rr.status + '  ' + String(buf.length).padStart(8) + 'B  ' + i.type + ' ' + i.w + 'x' + i.h + (i.alpha ? '  HAS ALPHA' : ''));
  if (i.w) fs.writeFileSync(`${OUT}/${slug}.${i.type === 'PNG' ? 'png' : 'jpg'}`, buf);
}
