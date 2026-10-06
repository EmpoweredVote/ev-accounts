#!/usr/bin/env node
/**
 * Fetch the Biloxi portraits at their LARGEST published size and measure the real files.
 *
 * The displayed size is not the file: the council page renders 120x150 thumbnails from
 * 2025/06 while linking 2025/08 `-scaled` originals, and the Minnesota House case proved
 * a publisher can serve a far larger file at the same path under the same base name.
 * So every URL is measured, not assumed, and each fetch is checked for a soft-404 body.
 */
import fs from 'node:fs';
import path from 'node:path';
const UA = { 'User-Agent': 'EmpoweredVote-asset-probe/1.0 (chris@empowered.vote)' };
const OUT = 'data/seed-ms-2026/_assets/biloxi';
fs.mkdirSync(OUT, { recursive: true });

// ward -> person as PRODUCTION holds them, bound by WARD because the filenames are not
// trustworthy (Ward 6's file is misspelled "Glavin"; the 2025/06 copy also says Ward 5).
const WANT = [
  ['ward1', 'Wayne Gray',      'https://biloxi.ms.us/wp-content/uploads/2025/08/Ward-1-Wayne-Gray-scaled.jpg'],
  ['ward2', 'Anthony Marshall','https://biloxi.ms.us/wp-content/uploads/2025/08/Ward-2-Anthony-Marshall-scaled.jpg'],
  ['ward3', 'Robert Nail',     'https://biloxi.ms.us/wp-content/uploads/2025/08/Ward-3-Mike-Nail-scaled.jpg'],
  ['ward4', 'Jamie Creel',     'https://biloxi.ms.us/wp-content/uploads/2025/08/Ward-4-Jamie-Creel-scaled-1.jpg'],
  ['ward5', 'Paul Tisdale',    'https://biloxi.ms.us/wp-content/uploads/2025/08/Ward-5-Dr.-Paul-Tisdale-scaled.jpg'],
  ['ward6', 'Kenny Glavan',    'https://biloxi.ms.us/wp-content/uploads/2025/08/Ward-6-Kenny-Glavin-scaled.jpg'],
  ['ward7', 'David Shoemaker', 'https://biloxi.ms.us/wp-content/uploads/2025/08/Ward-7-David-Shoemaker-scaled.jpg'],
  // The mayor is published only as a landscape 300x225 render. Try the un-suffixed
  // original and the -scaled variant before accepting that size.
  ['mayor-a','Andrew Gilich',  'https://biloxi.ms.us/wp-content/uploads/2024/07/Mayor-at-city-hall-ed.jpg'],
  ['mayor-b','Andrew Gilich',  'https://biloxi.ms.us/wp-content/uploads/2024/07/Mayor-at-city-hall-ed-scaled.jpg'],
  ['mayor-c','Andrew Gilich',  'https://biloxi.ms.us/wp-content/uploads/2024/07/Mayor-at-city-hall-ed-300x225.jpg'],
  // CONTROL: must NOT exist. If this returns an image, every 200 above is meaningless.
  ['CONTROL','n/a',            'https://biloxi.ms.us/wp-content/uploads/2025/08/Ward-9-Nobody-At-All-scaled.jpg'],
];

const rows = [];
for (const [slug, person, url] of WANT) {
  try {
    const r = await fetch(url, { headers: UA });
    const buf = Buffer.from(await r.arrayBuffer());
    const isJpeg = buf[0] === 0xff && buf[1] === 0xd8;
    let dims = null;
    if (isJpeg) {
      // minimal SOF walk
      let o = 2;
      while (o < buf.length - 9) {
        if (buf[o] !== 0xff) { o++; continue; }
        const mk = buf[o + 1];
        if (mk >= 0xc0 && mk <= 0xcf && ![0xc4, 0xc8, 0xcc].includes(mk)) {
          dims = { h: buf.readUInt16BE(o + 5), w: buf.readUInt16BE(o + 7) }; break;
        }
        o += 2 + buf.readUInt16BE(o + 2);
      }
    }
    const row = { slug, person, url, status: r.status, bytes: buf.length, isJpeg, dims };
    rows.push(row);
    console.log(
      slug.padEnd(9) + String(r.status).padEnd(5) + String(buf.length).padStart(8) + 'B  ' +
      (isJpeg ? 'JPEG' : 'NOT-AN-IMAGE') + '  ' + (dims ? `${dims.w}x${dims.h}` : '')
    );
    if (isJpeg && slug !== 'CONTROL') fs.writeFileSync(path.join(OUT, slug + '.jpg'), buf);
  } catch (e) {
    console.log(slug.padEnd(9) + 'ERROR ' + e.message);
    rows.push({ slug, person, url, error: String(e.message) });
  }
}
const ctl = rows.find(r => r.slug === 'CONTROL');
console.log('\nCONTROL: ' + (ctl.isJpeg ? 'RETURNED AN IMAGE -- every 200 above is uninterpretable' : 'correctly not an image (status ' + ctl.status + ')'));
fs.writeFileSync('data/seed-ms-2026/_assets/biloxi-fetch.json', JSON.stringify(rows, null, 2));
