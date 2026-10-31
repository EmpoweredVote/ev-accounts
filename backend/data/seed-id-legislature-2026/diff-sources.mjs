import fs from 'node:fs';
import path from 'node:path';
const dir = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1'));

const clean = (s) => s.replace(/&nbsp;/g,' ').replace(/&#39;|&#039;/g,"'").replace(/&amp;/g,'&')
  .replace(/<[^>]+>/g,'').replace(/\s+/g,' ').trim();

function bp(file) {
  const html = fs.readFileSync(path.join(dir, file), 'utf8');
  const start = html.indexOf('id="officeholder-table"');
  const body = html.slice(start, html.indexOf('</table>', start));
  const rows = [];
  for (const m of body.matchAll(/<tr>([\s\S]*?)<\/tr>/g)) {
    const tds = [...m[1].matchAll(/<td[^>]*>([\s\S]*?)<\/td>/g)].map(x => clean(x[1]));
    if (tds.length < 4) continue;
    const dm = /District\s+(\d+)([AB])?$/.exec(tds[0]);
    if (!dm) continue;
    rows.push({ district: Number(dm[1]), seat: dm[2] ?? null, name: tds[1], party: tds[2], assumed: tds[3], office: tds[0] });
  }
  return rows;
}

const roster = JSON.parse(fs.readFileSync(path.join(dir, 'roster-legislature.json'), 'utf8'));
const bpS = bp('bp_senate.html'), bpH = bp('bp_house.html');
console.log(`Ballotpedia rows — Senate ${bpS.length}, House ${bpH.length}`);
console.log(`Legislature rows — Senate ${roster.senate.length}, House ${roster.house.length}`);

// Normalise a name to compare across sources: drop middle initials and punctuation.
const norm = (s) => s.toLowerCase().replace(/[.,]/g,'').replace(/\s+/g,' ').trim();
const keyOf = (r) => `${r.district}${r.seat ?? ''}`;

function diff(mine, theirs, label) {
  const tm = new Map(theirs.map(r => [keyOf(r), r]));
  const mm = new Map(mine.map(r => [keyOf(r), r]));
  const issues = [];
  for (const [k, r] of mm) {
    const t = tm.get(k);
    if (!t) { issues.push(`${label} ${k}: present in legislature roster (${r.full_name}), ABSENT from Ballotpedia`); continue; }
    const a = norm(r.full_name), b = norm(t.name);
    const aTok = a.split(' '), bTok = b.split(' ');
    const sameEnds = aTok[0] === bTok[0] && aTok[aTok.length-1] === bTok[bTok.length-1];
    if (a !== b && !sameEnds) issues.push(`${label} ${k}: NAME DISAGREES — legislature "${r.full_name}" vs Ballotpedia "${t.name}"`);
    if (!t.party.toLowerCase().startsWith(r.party.toLowerCase().slice(0,8)))
      issues.push(`${label} ${k}: PARTY DISAGREES — legislature "${r.party}" vs Ballotpedia "${t.party}" (${r.full_name})`);
  }
  for (const [k, t] of tm) if (!mm.has(k)) issues.push(`${label} ${k}: present in Ballotpedia (${t.name}), ABSENT from legislature roster`);
  return issues;
}

const all = [...diff(roster.senate, bpS, 'SEN'), ...diff(roster.house, bpH, 'HSE')];
console.log(`\n=== DISAGREEMENTS: ${all.length} ===`);
for (const i of all) console.log('  ' + i);

// Assumed-office date distribution — the Dec 1 rule should dominate.
const dates = {};
for (const r of [...bpS, ...bpH]) dates[r.assumed] = (dates[r.assumed] || 0) + 1;
console.log('\n=== Ballotpedia "date assumed office" distribution ===');
for (const [d, n] of Object.entries(dates).sort((a,b)=>b[1]-a[1])) console.log(`  ${String(n).padStart(3)}  ${d}`);

fs.writeFileSync(path.join(dir, 'ballotpedia-rows.json'), JSON.stringify({ senate: bpS, house: bpH }, null, 2));
