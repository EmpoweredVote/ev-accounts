#!/usr/bin/env node
/**
 * Extract every candidate portrait on the Biloxi city-council page WITH ITS ALT TEXT.
 *
 * The alt is not decoration. A filename is not evidence of who is pictured -- Biloxi's own
 * uploads include `Ward-6-Kenny-Glavin-scaled.jpg` for Kenny GLAVAN -- and a contact sheet
 * is blind whenever the wrong person is also plausible. The per-image alt is what catches it.
 */
import fs from 'node:fs';

const URL_ = 'https://biloxi.ms.us/departments/city-council/';
const r = await fetch(URL_, { headers: { 'User-Agent': 'EmpoweredVote-asset-probe/1.0 (chris@empowered.vote)' } });
const html = await r.text();
console.log('HTTP', r.status, html.length, 'chars from', r.url);

const imgs = [];
const re = /<img\b[^>]*>/gi;
let m;
while ((m = re.exec(html))) {
  const tag = m[0];
  const attr = (n) => {
    // The backslashes MUST be doubled: this is a string handed to new RegExp, so '\s' would be
    // collapsed to a literal 's' before the regex ever sees it. It read '\s' first, which made the
    // pattern `srcs*=s*"..."` -- zero-or-more literal 's' characters instead of whitespace. It
    // matched anyway, because s* also matches empty, so the extraction was right for the wrong
    // reason and only eslint's no-useless-escape noticed.
    const a = new RegExp(n + '\\s*=\\s*"([^"]*)"', 'i').exec(tag);
    return a ? a[1] : null;
  };
  const src = attr('src') || attr('data-src');
  if (!src) continue;
  imgs.push({ src, alt: attr('alt'), title: attr('title'), w: attr('width'), h: attr('height'), cls: attr('class') });
}

const uploads = imgs.filter(i => /wp-content\/uploads/i.test(i.src));
console.log(`\n${imgs.length} <img> total, ${uploads.length} under wp-content/uploads\n`);
for (const i of uploads) {
  console.log('  src : ' + i.src);
  console.log('  alt : ' + JSON.stringify(i.alt) + '   size ' + i.w + 'x' + i.h);
  console.log('');
}

// Names as production holds them, so the page can be matched against the seated roster.
const SEATED = ['Wayne Gray','Anthony Marshall','Robert Nail','Jamie Creel','Paul Tisdale','Kenny Glavan','David Shoemaker','Andrew Gilich'];
console.log('--- does the PAGE name each seated official? (text, not filename) ---');
const text = html.replace(/<[^>]*>/g, ' ').replace(/&nbsp;/g,' ').replace(/\s+/g, ' ');
for (const n of SEATED) {
  const last = n.split(' ').pop();
  console.log(`  ${n.padEnd(20)} full:${text.includes(n) ? 'YES' : 'no '}  surname:${text.includes(last) ? 'YES' : 'no '}`);
}
// Negative control: a person who must NOT be on this page.
console.log(`  ${'CONTROL Zebediah Quux'.padEnd(20)} full:${text.includes('Zebediah Quux') ? 'YES -- DETECTOR BROKEN' : 'no (correct)'}`);

fs.writeFileSync('data/seed-ms-2026/_assets/biloxi-council-imgs.json', JSON.stringify({ url: r.url, imgs }, null, 2));
