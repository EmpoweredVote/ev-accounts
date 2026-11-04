import fs from 'node:fs';
const r = JSON.parse(fs.readFileSync('roster-legislature.json','utf8'));
const bp = JSON.parse(fs.readFileSync('ballotpedia-rows.json','utf8'));
const bpm = new Map([...bp.senate.map(x=>['S'+x.district,x]), ...bp.house.map(x=>['H'+x.district+x.seat,x])]);

// Ballotpedia's "date assumed office" is the start of CONTINUOUS occupancy for this chamber.
// Year-only values become start_precision='year'; full dates become 'day'.
const MONTHS = {January:'01',February:'02',March:'03',April:'04',May:'05',June:'06',July:'07',August:'08',September:'09',October:'10',November:'11',December:'12'};
function toTerm(s) {
  if (!s) return { date: null, precision: 'unknown' };
  let m = /^([A-Za-z]+) (\d{1,2}), (\d{4})$/.exec(s);
  if (m) return { date: `${m[3]}-${MONTHS[m[1]]}-${String(m[2]).padStart(2,'0')}`, precision: 'day' };
  m = /^(\d{4})$/.exec(s);
  if (m) return { date: `${m[1]}-01-01`, precision: 'year' };
  return { date: null, precision: 'unknown' };
}

const rows = [];
for (const s of r.senate.sort((a,b)=>a.district-b.district))
  rows.push({ key:'S'+s.district, chamber:'Senate', district:s.district, seat:null, ...s });
for (const h of r.house.sort((a,b)=>a.district-b.district || a.seat.localeCompare(b.seat)))
  rows.push({ key:'H'+h.district+h.seat, chamber:'House', district:h.district, seat:h.seat, ...h });

for (const x of rows) {
  const b = bpm.get(x.key);
  const t = toTerm(b && b.assumed);
  x.term_start = t.date; x.start_precision = t.precision; x.bp_assumed = b ? b.assumed : null;
  x.bp_name = b ? b.name : null;
}
fs.writeFileSync('roster-final.json', JSON.stringify(rows, null, 2));

const md = rows.map(x =>
  `| ${x.chamber} | ${x.district}${x.seat ? ' '+x.seat : ''} | ${x.full_name} | ${x.party} | ${x.city} | ${x.term_start} | ${x.start_precision} |`
).join('\n');
fs.writeFileSync('_roster_table.md', md);

const prec = rows.reduce((a,x)=>(a[x.start_precision]=(a[x.start_precision]||0)+1,a),{});
console.log('rows:', rows.length, '| precision split:', JSON.stringify(prec));
console.log('null term_start:', rows.filter(x=>!x.term_start).length);
