// Contact sheet for the 15 Boise + Ada County portraits.
// 🔴 TWO OF THESE HAVE POSITIONAL FILENAMES — 'mayor-2024-web.png' names the OFFICE and
// 'B-0043-5x300-1.jpg' names nothing at all. That is exactly where a wrong-person error hides,
// so both are flagged in the caption and must be read against the name under the frame.
// 🔴 The Ada County SHERIFF is deliberately absent: his office publishes a logo and a banner and
// no portrait, and a blank beats shipping a logo as a man's face.
import fs from 'node:fs';
import path from 'node:path';

const here = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1'));
const BO = path.join(here, 'portraits');
const AD = path.join(here, '..', 'seed-ada-county-2026', 'portraits');

const ITEMS = [
  { f: path.join(BO, 'mayor.png'),         name: 'Lauren McLean',      office: 'Mayor of Boise',                     flag: 'positional filename: mayor-2024-web.png' },
  { f: path.join(BO, 'council-1.jpg'),     name: 'Luci Willits',       office: 'Boise Council District 1' },
  { f: path.join(BO, 'council-2.jpg'),     name: 'Colin Nash',         office: 'Boise Council District 2' },
  { f: path.join(BO, 'council-3.jpg'),     name: 'Kathy Corless',      office: 'Boise Council District 3' },
  { f: path.join(BO, 'council-4.jpg'),     name: 'Jordan Morales',     office: 'Boise Council District 4' },
  { f: path.join(BO, 'council-5.jpg'),     name: 'Meredith Stead',     office: 'Boise Council District 5' },
  { f: path.join(BO, 'council-6.jpg'),     name: 'Jimmy Hallyburton',  office: 'Boise Council District 6' },
  { f: path.join(AD, 'commissioner-1.jpg'),name: 'Ryan Davidson',      office: 'Ada Commissioner District 1' },
  { f: path.join(AD, 'commissioner-2.jpg'),name: 'Rod Beck',           office: 'Ada Commissioner District 2' },
  { f: path.join(AD, 'commissioner-3.jpg'),name: 'Tom Dayley',         office: 'Ada Commissioner District 3' },
  { f: path.join(AD, 'clerk.jpg'),         name: 'Trent Tripple',      office: 'Ada Clerk of the District Court' },
  { f: path.join(AD, 'treasurer.jpg'),     name: 'Elizabeth Mahn',     office: 'Ada Treasurer' },
  { f: path.join(AD, 'assessor.jpg'),      name: 'Rebecca W. Arnold',  office: 'Ada Assessor' },
  { f: path.join(AD, 'coroner.jpg'),       name: 'Richard D. Riffle',  office: 'Ada Coroner',                        flag: 'opaque filename: B-0043-5x300-1.jpg' },
  { f: path.join(AD, 'prosecutor.jpg'),    name: 'Jan M. Bennetts',    office: 'Ada Prosecuting Attorney' },
];

const cells = ITEMS.map((it) => {
  const ext = path.extname(it.f).toLowerCase() === '.png' ? 'png' : 'jpeg';
  const b64 = fs.readFileSync(it.f).toString('base64');
  const kb = (fs.statSync(it.f).size / 1024).toFixed(0);
  return `<figure${it.flag ? ' class="flag"' : ''}>
    <img src="data:image/${ext};base64,${b64}" alt="${it.name}">
    <figcaption><b>${it.name}</b><span>${it.office}</span>
      <span class="s">${path.basename(it.f)} &middot; ${kb} KB</span>
      ${it.flag ? `<span class="w">⚠ ${it.flag} — verify the face</span>` : ''}</figcaption></figure>`;
}).join('\n');

const html = `<!doctype html><html><head><meta charset="utf-8">
<title>Boise + Ada County portraits</title>
<style>
 :root{color-scheme:light}
 body{margin:0;padding:24px;background:#f6f7f9;font:13px/1.4 -apple-system,Segoe UI,Roboto,sans-serif;color:#111}
 h1{font-size:18px;margin:0 0 4px} p.sub{margin:0 0 20px;color:#555}
 .grid{display:grid;grid-template-columns:repeat(5,1fr);gap:16px}
 figure{margin:0;background:#fff;border:1px solid #dfe3e8;border-radius:6px;overflow:hidden}
 figure.flag{border-color:#e0a800;box-shadow:0 0 0 2px #ffe9a8 inset}
 img{width:100%;aspect-ratio:4/5;object-fit:cover;display:block;background:#eceff3}
 figcaption{padding:8px;display:flex;flex-direction:column;gap:2px}
 figcaption b{font-size:13px} figcaption span{font-size:11px;color:#666}
 figcaption .s{color:#9aa1a9;font-family:ui-monospace,Menlo,monospace;font-size:10px}
 figcaption .w{color:#9a6b00;font-size:10px;font-weight:600}
</style></head><body>
<h1>Boise and Ada County — officeholder portraits</h1>
<p class="sub">15 of 16 seats &middot; the Ada County Sheriff is deliberately absent: his office publishes a logo and a banner, no portrait &middot; 2 flagged for a positional or opaque filename</p>
<div class="grid">${cells}</div>
</body></html>`;

fs.writeFileSync(path.join(here, '_local-contact-sheet.html'), html);
console.log(`${ITEMS.length} portraits -> _local-contact-sheet.html (${(html.length / 1e6).toFixed(1)} MB)`);
