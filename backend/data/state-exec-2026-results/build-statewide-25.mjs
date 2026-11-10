// Assemble everything CC_0363 needs: 25 chambers, districts, offices, terms, races, candidacies.
import fs from 'node:fs';
const SP = process.argv[2];
const sel = JSON.parse(fs.readFileSync(`${SP}/sel25.json`, 'utf8'));
const bp = JSON.parse(fs.readFileSync(`${SP}/bp-all-ballots.json`, 'utf8'));
const pols = JSON.parse(fs.readFileSync(`${SP}/all-politicians.json`, 'utf8'));
const elections = JSON.parse(fs.readFileSync(`${SP}/elections.json`, 'utf8'));
const STATES = JSON.parse(fs.readFileSync(`${SP}/all-states.json`, 'utf8'));
const GOV = JSON.parse(fs.readFileSync(`${SP}/governments.json`, 'utf8'));
const FIPS = JSON.parse(fs.readFileSync(`${SP}/fips.json`, 'utf8'));

const nm = s => (s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z ]/g, ' ').replace(/\s+/g, ' ').trim();
const SUF = new Set(['jr', 'sr', 'ii', 'iii', 'iv']);
const ends = s => { const t = nm(s).split(' ').filter(w => !SUF.has(w)); return t.length < 2 ? (t[0] || '') : `${t[0]} ${t[t.length - 1]}`; };
const byExact = new Map(), byEnds = new Map();
const push = (m, k, v) => { if (!k) return; if (!m.has(k)) m.set(k, []); m.get(k).push(v); };
for (const p of pols) { push(byExact, nm(p.full_name), p); push(byEnds, ends(p.full_name), p); }

const bpBy = new Map(bp.map(r => [`${r.st}|${r.office}`, r]));
const elecBy = {};
for (const st of new Set(sel.map(r => r.st))) {
  const hits = elections.filter(e => e.state === st);
  if (hits.length !== 1) throw new Error(`${st} has ${hits.length} election rows on 2026-11-03`);
  elecBy[st] = hits[0];
}

const slug = s => s.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
const resolve = (name) => {
  const e = (byExact.get(nm(name)) ?? []).filter(p => p.is_active);
  const n = (byEnds.get(ends(name)) ?? []).filter(p => p.is_active && nm(p.full_name) !== nm(name));
  return { exact: e, near: n };
};

const DEC = new Map(JSON.parse(fs.readFileSync(`${SP}/decisions25.json`, 'utf8')).map(d => [`${d.st}|${d.name}`, d]));
const seats = [], people = new Map(), problems = [];
for (const r of sel) {
  const v = bpBy.get(`${r.st}|${r.office}`);
  if (!v) throw new Error(`no votebox for ${r.st} ${r.office}`);
  const stateName = STATES[r.st];
  const fips = FIPS[r.st]; if (!fips) throw new Error(`no FIPS for ${r.st}`);
  const gov = GOV[r.st]; if (!gov) throw new Error(`no government_id for ${r.st}`);

  const cands = v.candidates.map(c => ({
    name: c.name, party: c.party, won: c.won, writeIn: c.writeIn, url: c.url,
    // Ballotpedia marks a withdrawal in the narrative, not a field
    withdrew: new RegExp(`${c.name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}[^.]{0,30}\\(Withdrew`, 'i').test(v.narrative || ''),
  }));
  if (cands.filter(c => c.won).length !== 1) problems.push(`${r.st} ${r.office}: ${cands.filter(c => c.won).length} winners`);

  for (const c of [...cands.map(c => c.name), r.holder]) {
    if (people.has(`${r.st}|${c}`)) continue;
    const res = resolve(c);
    const d = DEC.get(`${r.st}|${c}`);
    if (d && !d.why) throw new Error(`decision for ${r.st} ${c} carries no reason`);
    // 🔴 A NAME MATCH IS A HYPOTHESIS. Reading what each matched person already holds threw
    //    three out here — a California councillor, and two congressional candidates in the
    //    wrong states — exactly as it threw three out in CC_0359.
    people.set(`${r.st}|${c}`, { st: r.st, name: c, ...res,
      ruled: d ? (d.politicianId ? 'MATCH' : 'NEW') : null, ruledId: d ? d.politicianId : null, why: d ? d.why : null });
  }
  seats.push({
    st: r.st, office: r.office, stateName, fips, gov,
    holder: r.holder, how: r.how,
    chamberSlug: slug(`${r.office} of ${stateName}`),
    chamberFormal: `${r.office} of ${stateName}`,
    districtLabel: `${stateName} ${r.office}`,
    ocd: `ocd-division/country:us/state:${r.st.toLowerCase()}`,
    electionId: elecBy[r.st].id, electionName: elecBy[r.st].name,
    roleCanonical: /^comptroller$/i.test(r.office) ? 'comptroller' : null,
    cands,
  });
}
if (problems.length) { console.log('🔴 ' + problems.join('; ')); throw new Error('winner counts wrong'); }

fs.writeFileSync(`${SP}/seats25.json`, JSON.stringify(seats, null, 1));
console.log(`seats: ${seats.length}  candidacies: ${seats.reduce((n, s) => n + s.cands.length, 0)}  distinct people: ${people.size}`);
console.log(`withdrawals flagged: ${seats.flatMap(s => s.cands).filter(c => c.withdrew).length}`);

const need = [...people.values()];
const resolved = need.filter(p => p.exact.length === 1);
const multi = need.filter(p => p.exact.length > 1);
const nearOnly = need.filter(p => !p.exact.length && p.near.length);
const brandNew = need.filter(p => !p.exact.length && !p.near.length);
console.log(`\npeople: ${need.length}  exactly-one active match: ${resolved.length}  multiple: ${multi.length}  near-only: ${nearOnly.length}  new: ${brandNew.length}`);
if (multi.length) { console.log('🔴 MULTIPLE ACTIVE MATCHES — read each:'); for (const p of multi) console.log(`   ${p.st} "${p.name}" -> ${p.exact.map(x => `${x.full_name} ${x.id}`).join(', ')}`); }
if (nearOnly.length) { console.log('⚠ NEAR MATCH ONLY — read each:'); for (const p of nearOnly) console.log(`   ${p.st} "${p.name}" -> ${p.near.map(x => `${x.full_name} ${x.id}`).join(', ')}`); }
fs.writeFileSync(`${SP}/people25.json`, JSON.stringify(need, null, 1));
