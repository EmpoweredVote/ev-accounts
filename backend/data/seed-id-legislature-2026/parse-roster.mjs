// Parses the Idaho Legislature's own membership pages into a roster JSON.
// Source of record for the ID legislature wave. Raw bytes in, structured rows out —
// nothing here is summarised by a model.
import fs from 'node:fs';
import path from 'node:path';

const dir = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1'));

const clean = (s) => s
  .replace(/&nbsp;/g, ' ').replace(/&#8217;/g, "'").replace(/&amp;/g, '&')
  .replace(/&#8220;|&#8221;/g, '"').replace(/&ntilde;/g, 'ñ').replace(/&eacute;/g, 'é')
  .replace(/&#038;/g, '&').replace(/&quot;/g, '"').replace(/&#8211;/g, '-')
  .replace(/<[^>]+>/g, '').replace(/\s+/g, ' ').trim();

function parse(file, chamber) {
  const html = fs.readFileSync(path.join(dir, file), 'utf8');
  // Each member is one <p> opening with <strong>NAME</strong>(PARTY)<br />
  const blocks = html.split(/<div class="wpb_column vc_column_container col-xs-mobile-fullwidth col-sm-4/).slice(1);
  const rows = [];
  for (const b of blocks) {
    const nameM = /<p><strong>([^<]+)<\/strong>\s*\(([A-Z])\)/.exec(b);
    if (!nameM) continue;
    const distM = /\?yr=\d+&(?:#038;)?district=(\d+)">District\s*(\d+)<\/a>/.exec(b);
    if (!distM) continue;
    const seatM = /(?:House|Senate)\s+Seat\s+([AB])/.exec(b);
    const emailM = /mailto:([^"]+)"/.exec(b);
    const termM = /(\d+)<sup>(?:st|nd|rd|th)<\/sup>\s*term/.exec(b);
    // ⚠ Some members list a PO Box before the city, so the city is preceded by '&nbsp;'
    // rather than '<br />'. Requiring the <br /> matched only 51 of 105 — a silent half-miss.
    const cityM = /([A-Za-z .'\-]+),&nbsp;ID&nbsp;(\d{5})/.exec(b);
    const idM = /topic_id=(\d+)/.exec(b);

    const full = clean(nameM[1]);
    rows.push({
      chamber,
      district: Number(distM[2]),
      seat: seatM ? seatM[1] : null,
      full_name: full,
      party: nameM[2] === 'R' ? 'Republican' : nameM[2] === 'D' ? 'Democrat' : nameM[2],
      email: emailM ? emailM[1] : null,
      term_ordinal: termM ? Number(termM[1]) : null,
      city: cityM ? clean(cityM[1]) : null,
      zip: cityM ? cityM[2] : null,
      leg_id: idM ? idM[1] : null,
    });
  }
  return rows;
}

const senate = parse('senate_members.html', 'Senate');
const house  = parse('house_members.html', 'House');

// Portrait URLs are keyed by the same leg_id, from the page's own <img src>.
function photos(file) {
  const html = fs.readFileSync(path.join(dir, file), 'utf8');
  const m = new Map();
  // 🔴 THE SURNAME SEGMENT CAN CONTAIN A SPACE. A first pass used [A-Za-z'-]+ and silently
  // missed exactly two of 105 portraits — 'Den Hartog3124.jpg' (Sen. Lori Den Hartog) and
  // 'Vander Woude67.jpg' (Rep. John Vander Woude). Nothing errored; the two rows just came
  // back photo:null, which reads as "the legislature has no portrait for them". It was the
  // per-chamber count check that exposed it, not the regex.
  // The space must be percent-encoded for the fetch but NOT for the match.
  for (const x of html.matchAll(/src="(\/wp-content\/uploads\/sessioninfo\/\d+\/directory\/([A-Za-z' \-]+?)(\d+)\.jpg)"/g)) {
    m.set(x[3], 'https://legislature.idaho.gov' + x[1].replace(/ /g, '%20'));
  }
  return m;
}
const sp = photos('senate_members.html'), hp = photos('house_members.html');
for (const r of senate) r.photo = sp.get(r.leg_id) ?? null;
for (const r of house)  r.photo = hp.get(r.leg_id) ?? null;

const out = { pulled: new Date().toISOString().slice(0,10), senate, house };
fs.writeFileSync(path.join(dir, 'roster-legislature.json'), JSON.stringify(out, null, 2));

console.log(`Senate rows: ${senate.length}   House rows: ${house.length}`);
console.log(`Senate districts distinct: ${new Set(senate.map(r=>r.district)).size}`);
console.log(`House districts distinct:  ${new Set(house.map(r=>r.district)).size}`);
console.log(`House seats A: ${house.filter(r=>r.seat==='A').length}  B: ${house.filter(r=>r.seat==='B').length}  null: ${house.filter(r=>!r.seat).length}`);
console.log(`Senate seat field set on: ${senate.filter(r=>r.seat).length}`);
console.log(`Missing photo: senate ${senate.filter(r=>!r.photo).length}, house ${house.filter(r=>!r.photo).length}`);
console.log(`Party split — Senate: ${JSON.stringify(senate.reduce((a,r)=>(a[r.party]=(a[r.party]||0)+1,a),{}))}`);
console.log(`Party split — House:  ${JSON.stringify(house.reduce((a,r)=>(a[r.party]=(a[r.party]||0)+1,a),{}))}`);
