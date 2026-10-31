import fs from 'node:fs';
const rows = JSON.parse(fs.readFileSync('roster-final.json','utf8'));
const SUFFIX = /^(Jr\.?|Sr\.?|II|III|IV|V)$/i;
// Surname particles that belong WITH the following token, measured against this roster:
// 'Den Hartog' and 'Vander Woude' are single surnames, not middle names.
const PARTICLE = /^(Den|Vander|Van|Von|De|Del|Della|La|Le|Mac|Mc|St\.?|O')$/i;
const out = [];
for (const r of rows) {
  let n = r.full_name.replace(/"[^"]*"/g, ' ').replace(/\s+/g,' ').trim();   // drop "Jim" nicknames
  let toks = n.split(' ');
  let suffix = null;
  if (SUFFIX.test(toks[toks.length-1])) suffix = toks.pop();
  const first = toks.shift();
  // drop middle initials (single letter, optional period)
  const rest = toks.filter(t => !/^[A-Za-z]\.?$/.test(t));
  let last;
  if (rest.length <= 1) last = rest[0] ?? first;
  else if (PARTICLE.test(rest[rest.length-2])) last = rest.slice(-2).join(' ');
  else last = rest[rest.length-1];
  out.push({ ...r, first_name: first, last_name: last, suffix, bp_name: r.bp_name });
}
fs.writeFileSync('roster-named.json', JSON.stringify(out, null, 2));
// Flag any row where our last_name is not the last token of Ballotpedia's rendering
const odd = out.filter(x => x.bp_name && x.bp_name.split(' ').slice(-1)[0].toLowerCase() !== x.last_name.split(' ').slice(-1)[0].toLowerCase());
console.log('rows:', out.length, '| multi-word surnames:', out.filter(x=>x.last_name.includes(' ')).map(x=>x.last_name).join(', '));
console.log('suffixes:', out.filter(x=>x.suffix).map(x=>x.full_name+' ['+x.suffix+']').join(', ') || '(none)');
console.log('last-token disagreement with Ballotpedia:', odd.length);
for (const x of odd) console.log('   ', x.full_name, '-> last="'+x.last_name+'"  vs BP "'+x.bp_name+'"');
