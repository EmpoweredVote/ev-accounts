// Has Ballotpedia's count settled? Test it where an authoritative number exists.
//
// This piece has to take the RESULT from Ballotpedia, because AP publishes no race for these
// offices. Yesterday's lesson was that those pages are STALE FOR NUMBERS — Maine's governor read
// 261,518 there against AP's 382,760, a 32% shortfall. So the question is not "do I trust
// Ballotpedia" but "has it finished counting YET", and there is a way to measure that: the four
// offices AP DOES cover appear on the very same pages. Compare them.
import fs from 'node:fs';
const SP = process.argv[2];
const bpAll = JSON.parse(fs.readFileSync(`${SP}/bp-all-ballots.json`, 'utf8'));       // today
const bpYest = JSON.parse(fs.readFileSync(`${SP}/bp-ballots.json`, 'utf8'));          // yesterday
const ap = JSON.parse(fs.readFileSync(`${SP}/gap-ballots.json`, 'utf8'));             // AP, authoritative

const norm = s => (s || '').normalize('NFD').replace(/[̀-ͯ]/g, '')
  .toLowerCase().replace(/[^a-z ]/g, ' ').replace(/\s+/g, ' ').trim();
const SUF = new Set(['jr', 'sr', 'ii', 'iii', 'iv']);
const ends = s => { const t = norm(s).split(' ').filter(w => !SUF.has(w)); return t.length < 2 ? (t[0] || '') : `${t[0]} ${t[t.length - 1]}`; };
const OFFICE = { 'Governor': 'governor', 'Attorney General': 'attorney general', 'Lieutenant Governor': 'lieutenant governor', 'Secretary of State': 'secretary of state' };
const canonOffice = o => {
  const n = norm(o);
  if (/^secretary of (state|the commonwealth|the state)$/.test(n)) return 'secretary of state';
  return n;
};

const idx = (list) => { const m = new Map(); for (const r of list) m.set(`${r.st}|${canonOffice(r.office)}`, r); return m; };
const today = idx(bpAll), yest = idx(bpYest);

let compared = 0, agree = 0; const rows = [];
for (const r of ap) {
  const k = `${r.st}|${OFFICE[r.office]}`;
  const t = today.get(k);
  if (!t) continue;
  const apWin = r.candidates.find(c => c.winner);
  const bpWin = t.candidates.find(c => c.won);
  if (!apWin || !bpWin) continue;
  if (apWin.votes == null || bpWin.bpVotes == null || apWin.votes === 0) continue;
  const y = yest.get(k);
  const yWin = y ? y.candidates.find(c => c.won) : null;
  const ratio = bpWin.bpVotes / apWin.votes;
  const nameOk = ends(apWin.name.replace(/\s*\(write-in\)\s*$/i, '')) === ends(bpWin.name);
  compared++;
  if (ratio >= 0.995 && ratio <= 1.005 && nameOk) agree++;
  rows.push({ k, ap: apWin.votes, bpToday: bpWin.bpVotes, bpYest: yWin ? yWin.bpVotes : null, ratio: +ratio.toFixed(4), nameOk });
}
rows.sort((a, b) => a.ratio - b.ratio);
console.log(`AP races whose winner both sources count: ${compared}`);
console.log(`within 0.5% of AP's count AND same person: ${agree}  (${(100 * agree / compared).toFixed(1)}%)`);
console.log(`\nthe 12 furthest from AP:`);
for (const r of rows.slice(0, 12)) console.log(`  ${r.k.padEnd(34)} AP ${String(r.ap).padStart(9)}  BP today ${String(r.bpToday).padStart(9)}  (yesterday ${String(r.bpYest ?? '-').padStart(9)})  ratio ${r.ratio}${r.nameOk ? '' : '  🔴 DIFFERENT PERSON'}`);
console.log(`\nthe 3 closest:`);
for (const r of rows.slice(-3)) console.log(`  ${r.k.padEnd(34)} AP ${String(r.ap).padStart(9)}  BP today ${String(r.bpToday).padStart(9)}  ratio ${r.ratio}`);
const moved = rows.filter(r => r.bpYest != null && r.bpYest !== r.bpToday);
console.log(`\nBallotpedia counts that MOVED between 2026-11-05 and 2026-11-06: ${moved.length} of ${rows.filter(r => r.bpYest != null).length}`);
const winnerDisagree = rows.filter(r => !r.nameOk);
console.log(`winners where the two sources name DIFFERENT people: ${winnerDisagree.length}`);
