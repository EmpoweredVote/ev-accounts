// Builds a self-contained contact sheet of the 105 Idaho legislature portraits.
// 🔴 NOTHING IN THIS REPO ASKS WHETHER A HEADSHOT CONTAINS A FACE — a seal, a map, a blank or a
// torso passes every automated check. This sheet exists so the whole batch is LOOKED AT before
// anything is written. Images are embedded as data: URIs so nothing depends on the source host.
import fs from 'node:fs';
import path from 'node:path';

const dir = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1'));
const rows = JSON.parse(fs.readFileSync(path.join(dir, 'roster-named.json'), 'utf8'));

const slugOf = (x) =>
  (x.chamber === 'Senate' ? 'sen' : 'hse') + '-' + String(x.district).padStart(2, '0') +
  (x.seat ? '-' + x.seat.toLowerCase() : '');

const ordered = [...rows].sort((a, b) =>
  (a.chamber === b.chamber ? 0 : a.chamber === 'Senate' ? -1 : 1) ||
  a.district - b.district || String(a.seat).localeCompare(String(b.seat)));

const part = Number(process.argv[2] || 1);
const PER = 54;
const slice = ordered.slice((part - 1) * PER, part * PER);

const cells = slice.map((x) => {
  const slug = slugOf(x);
  const file = path.join(dir, 'portraits', slug + '.jpg');
  const b64 = fs.readFileSync(file).toString('base64');
  const seat = x.seat ? ` Seat ${x.seat}` : '';
  const label = `${x.chamber === 'Senate' ? 'Sen' : 'Rep'} LD${x.district}${seat}`;
  return `<figure><img src="data:image/jpeg;base64,${b64}" alt="${x.full_name}">
    <figcaption><b>${x.full_name}</b><span>${label}</span><span class="s">${slug}</span></figcaption></figure>`;
}).join('\n');

const html = `<!doctype html><html><head><meta charset="utf-8">
<title>Idaho Legislature portraits — sheet ${part}</title>
<style>
 :root{color-scheme:light}
 body{margin:0;padding:24px;background:#f6f7f9;font:13px/1.4 -apple-system,Segoe UI,Roboto,sans-serif;color:#111}
 h1{font-size:18px;margin:0 0 4px}
 p.sub{margin:0 0 20px;color:#555}
 .grid{display:grid;grid-template-columns:repeat(9,1fr);gap:14px}
 figure{margin:0;background:#fff;border:1px solid #dfe3e8;border-radius:6px;overflow:hidden}
 img{width:100%;aspect-ratio:4/5;object-fit:cover;display:block;background:#eceff3}
 figcaption{padding:6px 6px 8px;display:flex;flex-direction:column;gap:1px}
 figcaption b{font-size:11px;line-height:1.25}
 figcaption span{font-size:10px;color:#666}
 figcaption .s{color:#9aa1a9;font-family:ui-monospace,Menlo,monospace;font-size:9px}
</style></head><body>
<h1>Idaho Legislature — official portraits, sheet ${part} of 2</h1>
<p class="sub">${slice.length} of 105 &middot; source: legislature.idaho.gov 2026 session directory &middot; looked at before CC_0314 was written</p>
<div class="grid">${cells}</div>
</body></html>`;

const out = path.join(dir, `_contact-sheet-${part}.html`);
fs.writeFileSync(out, html);
console.log(`sheet ${part}: ${slice.length} portraits -> ${out} (${(html.length / 1e6).toFixed(1)} MB)`);
