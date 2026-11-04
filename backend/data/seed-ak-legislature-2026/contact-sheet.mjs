// Builds a self-contained contact sheet of the 60 Alaska legislature portraits.
// 🔴 NOTHING IN THIS REPO ASKS WHETHER A HEADSHOT CONTAINS A FACE — a seal, a map, a blank or a
// torso passes every automated check. This sheet exists so the whole batch is LOOKED AT before
// anything is written. Images are embedded as data: URIs so nothing depends on the source host.
//
//   node contact-sheet.mjs <portraitDir> <outDir>
//
// Writes sheet-1.html and sheet-2.html, 30 cells each, ordered Senate A..T then House 1..40.
import fs from 'node:fs';
import path from 'node:path';

const portraitDir = process.argv[2];
const outDir = process.argv[3];
if (!portraitDir || !outDir) {
  console.error('usage: node contact-sheet.mjs <portraitDir> <outDir>');
  process.exit(2);
}

const dir = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1'));
const roster = JSON.parse(fs.readFileSync(path.join(dir, 'roster-final.json'), 'utf8'));

const ordered = [...roster].sort((a, b) =>
  (a.chamber === b.chamber ? 0 : a.chamber === 'Senate' ? -1 : 1) ||
  String(a.district_code).localeCompare(String(b.district_code), undefined, { numeric: true }));

const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

const PER = 30;
for (let part = 1; part <= 2; part++) {
  const slice = ordered.slice((part - 1) * PER, part * PER);
  const cells = slice.map((x) => {
    const file = path.join(portraitDir, x.member_code.toUpperCase() + '.jpg');
    let img = '<div class="missing">NO FILE</div>';
    let bytes = 0;
    if (fs.existsSync(file)) {
      const buf = fs.readFileSync(file);
      bytes = buf.length;
      img = `<img src="data:image/jpeg;base64,${buf.toString('base64')}" alt="">`;
    }
    const seat = x.chamber === 'Senate' ? `Senate ${x.district_code}` : `House ${x.district_code}`;
    return `<figure>
      ${img}
      <figcaption>
        <b>${esc(x.full_name)}</b>
        <span>${esc(seat)} · ${esc(x.member_code.toUpperCase())}</span>
        <span>${esc(x.party_akleg || '')} · ${esc(x.home_city || '')}</span>
        <span class="b">${(bytes / 1024).toFixed(0)} KB</span>
      </figcaption>
    </figure>`;
  }).join('\n');

  const html = `<!doctype html><meta charset="utf-8">
<title>Alaska Legislature portraits — sheet ${part} of 2</title>
<style>
  body { background:#14171c; color:#e8ecf2; font:13px/1.35 system-ui,sans-serif; margin:16px; }
  h1 { font-size:16px; margin:0 0 12px; font-weight:600; }
  .grid { display:grid; grid-template-columns:repeat(6,1fr); gap:10px; }
  figure { margin:0; background:#1d222a; border-radius:6px; overflow:hidden; }
  img { display:block; width:100%; aspect-ratio:450/600; object-fit:cover; background:#000; }
  .missing { display:grid; place-items:center; aspect-ratio:450/600; background:#4a1d1d; color:#ffb4b4; font-weight:700; }
  figcaption { padding:6px 7px 8px; display:flex; flex-direction:column; gap:2px; }
  figcaption b { font-size:12px; }
  figcaption span { font-size:10.5px; color:#9aa6b6; }
  figcaption .b { color:#6b7787; }
</style>
<h1>Alaska Legislature — 60 portraits, sheet ${part} of 2 (akleg.gov /images/legislators/450x600/)</h1>
<div class="grid">
${cells}
</div>`;
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(path.join(outDir, `sheet-${part}.html`), html);
  console.log(`sheet-${part}.html — ${slice.length} cells`);
}
