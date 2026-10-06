#!/usr/bin/env node
/**
 * Look for an undecorated portrait of Sheriff Matt Haley.
 *
 * The homepage/administration image is a cut-out inside a gold ring; removing the ring leaves
 * arc-shaped holes where it passed in front of his shoulders. His command staff, by contrast,
 * are published as PLAIN rectangular JPEGs on the same ImageKit account and rounded by a query
 * string -- so an undecorated original of the Sheriff may exist beside them.
 *
 * CONTROL: a filename that must not exist is requested from the same ImageKit path. ImageKit
 * returns a real image for a valid file and an error for an invalid one, so if the control
 * comes back as an image, nothing else here is interpretable.
 */
const UA = { 'User-Agent': 'EmpoweredVote-asset-probe/1.0 (chris@empowered.vote)' };
const IK = 'https://ik.imagekit.io/hcso/theme/assets/pages/';

const dims = (b) => {
  if (b.length > 24 && b[0] === 0x89 && b.subarray(1, 4).toString() === 'PNG')
    return { t: 'PNG', w: b.readUInt32BE(16), h: b.readUInt32BE(20) };
  if (b.length > 4 && b[0] === 0xff && b[1] === 0xd8) {
    let o = 2;
    while (o < b.length - 9) {
      if (b[o] !== 0xff) { o++; continue; }
      const mk = b[o + 1];
      if (mk >= 0xc0 && mk <= 0xcf && ![0xc4, 0xc8, 0xcc].includes(mk))
        return { t: 'JPEG', w: b.readUInt16BE(o + 7), h: b.readUInt16BE(o + 5) };
      o += 2 + b.readUInt16BE(o + 2);
    }
  }
  return null;
};

const NAMES = [
  'Matt-Haley,-Sheriff.jpg', 'Matt-Haley-Sheriff.jpg', 'Matt-Haley.jpg', 'MattHaley.jpg',
  'Sheriff-Matt-Haley.jpg', 'haley-portrait-final.jpg', 'Haley.jpg', 'sheriff.jpg',
  'sheriff-portrait.jpg', 'Matt-Haley,-Sheriff.png', 'sheriff-square.png', 'sheriff-full.png',
  'haley-portrait-final-2026-06-17.jpg',
  'ZZ-no-such-file-ms5.jpg',   // CONTROL
];

console.log('ImageKit sweep for an undecorated Haley portrait:\n');
for (const n of NAMES) {
  try {
    const r = await fetch(IK + encodeURIComponent(n).replace(/%2C/g, ','), { headers: UA });
    const b = Buffer.from(await r.arrayBuffer());
    const d = dims(b);
    const tag = n.startsWith('ZZ-') ? 'CONTROL ' : '        ';
    console.log(tag + String(r.status).padEnd(5) + String(b.length).padStart(9) + 'B  ' +
      (d ? `${d.t} ${d.w}x${d.h}` : 'not an image').padEnd(18) + n);
    if (n.startsWith('ZZ-')) console.log('        -> ' + (d ? 'CONTROL RETURNED AN IMAGE; results above prove nothing' : 'control correctly absent'));
  } catch (e) { console.log('        ERR ' + e.message.slice(0, 40) + '  ' + n); }
}

// Other HCSO pages that might carry a different photograph of him.
console.log('\nHCSO pages naming Haley, and the images on them:');
for (const p of ['administration', 'homepage', 'about', 'press-releases', 'community-relations']) {
  try {
    const r = await fetch('https://www.harrisoncountysheriff.com/' + p, { headers: UA });
    const html = await r.text();
    const soft = /\/404\?/.test(r.url);
    if (soft) { console.log(`  /${p}: soft-404, skipped`); continue; }
    const names = (html.match(/Haley/g) || []).length;
    const imgs = [...html.matchAll(/<img\b[^>]*>/gi)]
      .map((m) => {
        const s = /src\s*=\s*["']([^"']+)["']/i.exec(m[0]);
        const a = /alt\s*=\s*["']([^"']*)["']/i.exec(m[0]);
        return s && a && /haley|sheriff/i.test(a[1]) ? `${a[1]}  ${new URL(s[1], r.url).href}` : null;
      }).filter(Boolean);
    console.log(`  /${p}: HTTP ${r.status}, "Haley" x${names}` + (imgs.length ? '' : ', no matching image'));
    for (const i of imgs) console.log('       ' + i);
  } catch (e) { console.log(`  /${p}: ERR ${e.message}`); }
}
