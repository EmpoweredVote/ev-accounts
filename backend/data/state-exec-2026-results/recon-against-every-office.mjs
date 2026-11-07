// Re-reconcile the voteboxes that "match no seat we hold" — this time against EVERY office,
// not just the STATE_EXEC ones.
//
// 🔴 THE FIRST RECONCILIATION FILTERED ON district_type = 'STATE_EXEC' AND THAT WAS THE WHOLE
//    ANSWER'S SHAPE. Utah's 15 State Board of Education districts are STATE_BOARD_EDUCATION and
//    California's 4 Board of Equalization districts are STATE_BOARD, so every one of them came
//    back as "we hold no such seat" — a false absence produced by my own WHERE clause, reported
//    as a fact about the data. A predicate reads the shape of a value, never what it is.
import fs from 'node:fs';
const SP = process.argv[2];
const bp = JSON.parse(fs.readFileSync(`${SP}/bp-all-ballots.json`, 'utf8'));
const every = JSON.parse(fs.readFileSync(`${SP}/everyoffice.json`, 'utf8'));
const STATES = JSON.parse(fs.readFileSync(`${SP}/all-states.json`, 'utf8'));
const done = JSON.parse(fs.readFileSync(`${SP}/plan.json`, 'utf8'));

const handled = new Set([...done.create, ...done.update].map(r => `${r.st}|${r.office}`));
const AP_OFFICE = new Set(['governor', 'attorney general', 'secretary of state', 'secretary of the commonwealth', 'secretary of the state', 'lieutenant governor']);

const norm = s => (s || '').toLowerCase().replace(/[^a-z0-9 ]/g, ' ').replace(/\s+/g, ' ').trim();
const strip = (st, t) => {
  const name = (STATES[st] || '').toLowerCase();
  let s = norm(t);
  if (name && s.startsWith(name + ' ')) s = s.slice(name.length + 1);
  if (name && s.endsWith(' of ' + name)) s = s.slice(0, -(name.length + 4));
  if (s.startsWith(st.toLowerCase() + ' ')) s = s.slice(st.length + 1);
  return s.trim();
};
// keep a trailing district/place number: it is the identity of the seat, not noise
const seatKey = (st, t) => strip(st, t).replace(/\s*\(\d+ seats?\)$/, '').trim();

const ours = {};
for (const o of every) (ours[o.st] ||= []).push({ ...o, key: seatKey(o.st, o.title), races: Number(o.races_2026), won: Number(o.winners) });

const rows = [];
for (const r of bp) {
  const k = seatKey(r.st, r.office);
  if (AP_OFFICE.has(k)) continue;
  if (handled.has(`${r.st}|${r.office}`)) continue;       // already done by CC_0360/CC_0361
  const winners = r.candidates.filter(c => c.won);
  // match on the full key, then on a loose "same words" comparison
  let hits = (ours[r.st] || []).filter(o => o.key === k);
  if (!hits.length) {
    const want = new Set(k.split(' ').filter(w => w.length > 2));
    hits = (ours[r.st] || []).filter(o => {
      const have = new Set(o.key.split(' ').filter(w => w.length > 2));
      if (!want.size || !have.size) return false;
      const inter = [...want].filter(w => have.has(w)).length;
      // require the digits to agree exactly if either side has one
      const dw = (k.match(/\d+/) || [])[0], dh = (o.key.match(/\d+/) || [])[0];
      if (dw !== dh) return false;
      return inter >= Math.min(want.size, have.size) * 0.6;
    });
  }
  rows.push({
    st: r.st, office: r.office, key: k, called: winners.length > 0, nWinners: winners.length,
    nCands: r.candidates.length,
    hits: hits.map(h => ({ title: h.title, type: h.district_type, geo: h.geo_id, office_id: h.office_id, races: h.races, won: h.won })),
  });
}

const b = { alreadyWon: [], haveRaceNoWinner: [], haveSeatNoRace: [], noSeat: [], ambiguous: [], uncalled: [] };
for (const r of rows) {
  if (!r.called) b.uncalled.push(r);
  else if (r.hits.length > 1) b.ambiguous.push(r);
  else if (r.hits.length === 0) b.noSeat.push(r);
  else if (r.hits[0].won > 0) b.alreadyWon.push(r);
  else if (r.hits[0].races > 0) b.haveRaceNoWinner.push(r);
  else b.haveSeatNoRace.push(r);
}
const sum = Object.values(b).reduce((n, v) => n + v.length, 0);
console.log(`voteboxes still outstanding: ${rows.length}`);
for (const [k, v] of Object.entries(b)) console.log(`  ${String(v.length).padStart(3)}  ${k}`);
if (sum !== rows.length) throw new Error(`BUCKETS DO NOT SUM: ${sum} vs ${rows.length}`);
console.log(`  (sum ${sum} ✔)`);
fs.writeFileSync(`${SP}/recon2.json`, JSON.stringify(b, null, 1));

const show = (t, l, f) => { if (!l.length) return; console.log(`\n=== ${t} (${l.length}) ===`); for (const r of l) console.log('  ' + f(r)); };
show('🟢 WE HOLD THE RACE ALREADY — just no winner recorded', b.haveRaceNoWinner,
  r => `${r.st} ${r.office}  ->  ${r.hits[0].type} "${r.hits[0].title}" geo=${r.hits[0].geo}`);
show('WE HOLD THE SEAT, NO 2026 RACE', b.haveSeatNoRace,
  r => `${r.st} ${r.office}  ->  ${r.hits[0].type} "${r.hits[0].title}" geo=${r.hits[0].geo}`);
show('AMBIGUOUS', b.ambiguous, r => `${r.st} ${r.office} -> ${r.hits.length}: ${r.hits.map(h => h.title).join(' | ')}`);
show('ALREADY RECORDED', b.alreadyWon, r => `${r.st} ${r.office}`);
