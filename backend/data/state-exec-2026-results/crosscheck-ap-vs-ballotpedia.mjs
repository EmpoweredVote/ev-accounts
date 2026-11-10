// Cross-check AP's ballot against Ballotpedia's, race by race, for the 73 gap races.
//
// Two INDEPENDENT sources for the same contest. AP supplies every number and the winner
// flag; Ballotpedia supplies identity (full name spelling, a per-person article URL) and a
// second opinion on party. A disagreement is a FINDING, not noise — AP truncates names
// ("T. Shannon"), and a search summary already proved stale once on a withdrawn candidate.
import fs from 'node:fs';
const SP = process.argv[2];
const ap = JSON.parse(fs.readFileSync(`${SP}/gap-ballots.json`, 'utf8'));
const bp = JSON.parse(fs.readFileSync(`${SP}/bp-ballots.json`, 'utf8'));

const norm = s => (s || '').normalize('NFD').replace(/[̀-ͯ]/g, '')
  .toLowerCase().replace(/[^a-z ]/g, ' ').replace(/\s+/g, ' ').trim();
const SUF = new Set(['jr', 'sr', 'ii', 'iii', 'iv', 'v']);
const lastOf = s => { const t = norm(s).split(' ').filter(w => !SUF.has(w)); return t[t.length - 1] || ''; };
const firstOf = s => { const t = norm(s).split(' ').filter(w => !SUF.has(w)); return t[0] || ''; };

// Ballotpedia's office title for the seat AP calls X
const OFFICE = {
  'Governor': ['Governor'],
  'Attorney General': ['Attorney General'],
  'Lieutenant Governor': ['Lieutenant Governor'],
  'Secretary of State': ['Secretary of State', 'Secretary of the Commonwealth', 'Secretary of the State'],
};
// AP's party code -> the words Ballotpedia prints. ⚠ Ballotpedia writes a FUSION ticket as
// "D / Working Families Party" and spells minor parties out in full, so the comparison is
// "does Ballotpedia's label contain any of these", not string equality.
const PARTY = {
  GOP: ['R', 'Republican'], Dem: ['D', 'Democratic'], Lib: ['L', 'Libertarian'], Grn: ['G', 'Green'],
  Ind: ['Independent', 'Unaffiliated', 'Unenrolled', 'No Party', 'Nonpartisan', 'Non-Affiliated'],
  NPA: ['No Party', 'Independent', 'Unaffiliated'], Oth: null,
  CST: ['Constitution', 'C'], UST: ['U.S. Taxpayers', 'Taxpayers'], NLP: ['Natural Law'],
  WCP: ['Working Class'], AFi: ['America First'], LMN: ['Lincoln'], NWk: ['New Way'],
  PAG: ['Pag'], UCz: ['United Citizens'], PJP: ['Peace'], Prg: ['Progressive'],
};
const partyAgrees = (apCode, bpLabel) => {
  const want = PARTY[apCode];
  if (!want || !bpLabel) return true;                       // nothing to compare
  const l = bpLabel.toLowerCase();
  return want.some(w => w.length <= 2 ? new RegExp(`(^|[^a-z])${w.toLowerCase()}([^a-z]|$)`).test(l) : l.includes(w.toLowerCase()));
};

const bpIndex = new Map();
for (const r of bp) bpIndex.set(`${r.st}|${norm(r.office)}`, r);

const report = [], pairs = [];
let matchedRaces = 0;
for (const r of ap) {
  let b = null;
  for (const t of (OFFICE[r.office] || [])) { b = bpIndex.get(`${r.st}|${norm(t)}`); if (b) break; }
  if (!b) { report.push(`🔴 ${r.st} ${r.office}: NO Ballotpedia general-election table found`); continue; }
  matchedRaces++;
  const WRITEIN = /\s*\(write-in\)\s*$/i;      // AP puts write-in status INSIDE the name string
  const apC = r.candidates.filter(c => c.apId !== '100008')
    .map(c => ({ ...c, clean: c.name.replace(WRITEIN, '').trim(), isWriteIn: WRITEIN.test(c.name) }));
  const used = new Set();
  for (const c of apC) {
    // pair on last name within the race, then confirm the first name agrees or one is an initial
    const cands = b.candidates.filter(x => lastOf(x.name) === lastOf(c.clean) && !used.has(x.name));
    let m = cands.find(x => firstOf(x.name) === firstOf(c.clean));
    if (!m && cands.length === 1) m = cands[0];
    if (!m) { report.push(`🔴 ${r.st} ${r.office}: AP has "${c.clean}" (${c.party}) ${c.pct}% — Ballotpedia's table does not list that surname`); continue; }
    used.add(m.name);
    if (!partyAgrees(c.party, m.party))
      report.push(`⚠ ${r.st} ${r.office}: party differs for ${c.clean} — AP "${c.party}" vs Ballotpedia "${m.party}"`);
    if (norm(c.clean) !== norm(m.name))
      report.push(`NAME ${r.st} ${r.office}: AP "${c.clean}" vs Ballotpedia "${m.name}"`);
    if (c.winner !== m.won)
      report.push(`🔴 ${r.st} ${r.office}: WINNER DISAGREES for ${c.clean} — AP won=${c.winner}, Ballotpedia won=${m.won}`);
    if (c.isWriteIn !== m.writeIn)
      report.push(`⚠ ${r.st} ${r.office}: write-in flag differs for ${c.clean} — AP ${c.isWriteIn}, Ballotpedia ${m.writeIn}`);
    pairs.push({ st: r.st, office: r.office, apId: c.apId, apName: c.clean, bpName: m.name, bpUrl: m.url, bpParty: m.party, apParty: c.party, bpWriteIn: m.writeIn, bpRunningMate: m.runningMate, bpPct: m.bpPct, bpVotes: m.bpVotes });
  }
  for (const x of b.candidates) if (!used.has(x.name))
    report.push(`⚠ ${r.st} ${r.office}: Ballotpedia lists "${x.name}" (${x.party})${x.writeIn ? ' write-in' : ''} and AP's ballot does not`);
}
fs.writeFileSync(`${SP}/bp-pairs.json`, JSON.stringify(pairs, null, 1));
console.log(`AP gap races:                 ${ap.length}`);
console.log(`paired with a Ballotpedia tbl:${matchedRaces}`);
console.log(`AP candidacies paired:        ${pairs.length}`);
console.log(`\n=== ${report.length} DISAGREEMENT(S) ===`);
for (const l of report) console.log('  ' + l);
