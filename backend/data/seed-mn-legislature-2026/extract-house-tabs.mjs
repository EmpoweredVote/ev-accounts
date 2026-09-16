/**
 * Split https://www.house.mn.gov/members/ into its five tabs and extract each one's roster.
 *
 * The page is one document holding Alphabetical, District Order, Leadership, Republican and DFL
 * lists. They do NOT all agree -- the Leadership tab is stale for 47A -- so they are extracted
 * separately and reconciled by scripts/build-mn-legislature-roster.mjs, never merged here.
 *
 * 🔴 NAMES ARE HTML-ENCODED IN THIS PAGE. `Mar&#237;a Isa P&#233;rez-Vega` is one of them, and a
 * raw regex capture writes the mojibake straight into a voter-facing field. Entities are decoded.
 */
import fs from 'fs';

const TABS = ['Alpha', 'District', 'Leadership', 'GOP', 'DFL'];
const html = fs.readFileSync('_house-members.html', 'utf8');

const NAMED = { amp: '&', lt: '<', gt: '>', quot: '"', apos: "'", nbsp: ' ', rsquo: '’', lsquo: '‘', ndash: '–', mdash: '—' };
const decode = (s) =>
  s
    .replace(/&#x([0-9a-fA-F]+);/g, (_, h) => String.fromCodePoint(parseInt(h, 16)))
    .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(Number(d)))
    .replace(/&([a-zA-Z]+);/g, (_, n) => (n in NAMED ? NAMED[n] : `&${n};`))
    .replace(/\s+/g, ' ')
    .trim();

const offsets = TABS.map((t) => ({ t, i: html.indexOf(`id="${t}"`) })).sort((a, b) => a.i - b.i);
if (offsets.some((o) => o.i < 0)) throw new Error(`tab anchor missing: ${JSON.stringify(offsets)}`);

const summary = [];
for (let k = 0; k < offsets.length; k++) {
  const seg = html.slice(offsets[k].i, k + 1 < offsets.length ? offsets[k + 1].i : html.length);
  const re = /<a href="\/members\/profile\/(\d+)"><b>([^<]+?)\s*\(([0-9]{1,2}[AB]),\s*([A-Z]+)\)<\/b><\/a>/g;
  const map = new Map();
  let m, n = 0;
  while ((m = re.exec(seg))) {
    n++;
    const dist = m[3].replace(/^0+(?=\d)/, '');
    map.set(dist, { pid: m[1], name: decode(m[2]), party: m[4] });
  }
  fs.writeFileSync(`_tab-${offsets[k].t}.json`, JSON.stringify([...map.entries()], null, 1));
  summary.push({ tab: offsets[k].t, matches: n, distinct: map.size });
}
console.table(summary);

// Positive control: the decoder must actually have fired on this page.
const encoded = (html.match(/<b>[^<]*&#\d+;[^<]*\([0-9]{1,2}[AB],/g) || []).length;
const alpha = new Map(JSON.parse(fs.readFileSync('_tab-Alpha.json', 'utf8')));
const leftEncoded = [...alpha.values()].filter((v) => /&#|&[a-z]+;/i.test(v.name));
console.log(`encoded names present in the page: ${encoded}; still encoded after decode: ${leftEncoded.length}`);
if (encoded === 0) throw new Error('control failed: no encoded name found, so the decoder was never exercised');
if (leftEncoded.length) throw new Error(`control failed: ${JSON.stringify(leftEncoded)}`);
console.log('decoder control OK');
