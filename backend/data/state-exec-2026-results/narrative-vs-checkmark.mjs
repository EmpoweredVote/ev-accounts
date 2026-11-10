// Cross-check Ballotpedia's winner CHECKMARK against its own NARRATIVE SENTENCE.
//
// These 37 races have no AP race, so there is no second source for the outcome. But the page
// states the outcome TWICE, by two different mechanisms: a CSS class on a table row
// (`tr.results_row.winner`) and a sentence written by an editor ("X defeated Y..."). They are
// produced separately, so one can be wrong while the other is right, and a disagreement is a
// finding. This is not as good as a second source. It is what the source itself makes available.
import fs from 'node:fs';
const SP = process.argv[2];
const recon = JSON.parse(fs.readFileSync(`${SP}/bp-recon.json`, 'utf8'));
const bp = JSON.parse(fs.readFileSync(`${SP}/bp-all-ballots.json`, 'utf8'));
const want = new Set(recon.rows.filter(r => !r.isAp && r.called && r.nSeats === 1).map(r => `${r.st}|${r.office}`));

const norm = s => (s || '').normalize('NFD').replace(/[̀-ͯ]/g, '')
  .toLowerCase().replace(/[^a-z ]/g, ' ').replace(/\s+/g, ' ').trim();
const SUF = new Set(['jr', 'sr', 'ii', 'iii', 'iv']);
const ends = s => { const t = norm(s).split(' ').filter(w => !SUF.has(w)); return t.length < 2 ? (t[0] || '') : `${t[0]} ${t[t.length - 1]}`; };

// "A defeated B and C in the general election for ..." / "A won election in the general election for ..."
const VERB = /\b(defeated|won election|advanced to a runoff|won in the general election)\b/i;

let ok = 0; const problems = [], noNarrative = [];
for (const r of bp) {
  const k = `${r.st}|${r.office}`;
  if (!want.has(k)) continue;
  const w = r.candidates.filter(c => c.won);
  const n = r.narrative || '';
  if (!n.trim()) { noNarrative.push(`${k}: winner flagged "${w.map(c => c.name).join(', ')}" but the page prints NO narrative sentence`); continue; }
  if (!VERB.test(n)) { problems.push(`${k}: narrative states no outcome verb — "${n.slice(0, 120)}"`); continue; }
  // the sentence must OPEN with the flagged winner (optionally "Incumbent <name>")
  const lead = n.replace(/^Incumbent\s+/i, '').split(/\s+\(|\s+defeated|\s+won\b/)[0].trim();
  const hit = w.find(c => ends(c.name) === ends(lead) || (c.runningMate && ends(c.runningMate) === ends(lead)));
  if (!hit) problems.push(`${k}: the ✔ is on "${w.map(c => c.name).join(', ')}" but the sentence leads with "${lead}" — "${n.slice(0, 140)}"`);
  else ok++;
}
console.log(`races to record: ${want.size}`);
console.log(`checkmark and narrative name the same winner: ${ok}`);
console.log(`\n${noNarrative.length} race(s) with a flag and NO sentence:`);
for (const p of noNarrative) console.log('  ⚠ ' + p);
console.log(`\n${problems.length} disagreement(s):`);
for (const p of problems) console.log('  🔴 ' + p);
if (ok + problems.length + noNarrative.length !== want.size) throw new Error(`BUCKETS DO NOT SUM: ${ok + problems.length + noNarrative.length} vs ${want.size}`);
console.log(`  (buckets sum to ${want.size} ✔)`);
