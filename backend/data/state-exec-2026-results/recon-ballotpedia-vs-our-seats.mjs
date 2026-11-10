// Reconcile every Ballotpedia 2026 general-election state-executive votebox against the
// STATE_EXEC seats we hold, and say which bucket each falls in.
//
// Run FROM THE SOURCE'S LIST, not ours — that is the whole lesson of CC_0359. A seat we do not
// hold produces no row and no error on our side.
import fs from 'node:fs';
const SP = process.argv[2];
const bp = JSON.parse(fs.readFileSync(`${SP}/bp-all-ballots.json`, 'utf8'));
const offices = JSON.parse(fs.readFileSync(`${SP}/offices.json`, 'utf8'));
const STATES = JSON.parse(fs.readFileSync(`${SP}/all-states.json`, 'utf8'));

// AP covers exactly these four. They are recorded already (CC_0357/0358/0359) or waiting on AP.
const AP_OFFICES = new Set(['governor', 'lieutenant governor', 'attorney general', 'secretary of state',
                            'secretary of the commonwealth', 'secretary of the state']);

const norm = s => (s || '').toLowerCase().replace(/[^a-z0-9 ]/g, ' ').replace(/\s+/g, ' ').trim();
// our titles sometimes carry the state ("Texas Governor"), Ballotpedia's sometimes do not
const strip = (st, t) => {
  const name = (STATES[st] || '').toLowerCase();
  let s = norm(t);
  if (name && s.startsWith(name + ' ')) s = s.slice(name.length + 1);
  if (name && s.endsWith(' of ' + name)) s = s.slice(0, -(name.length + 4));
  if (s.startsWith(st.toLowerCase() + ' ')) s = s.slice(st.length + 1);
  return s.trim();
};
// the same seat under two house styles
const ALIAS = {
  // ⚠ Each line is a state's house style for the SAME seat, and a missing one reads as
  //   "we hold no such seat" — a false absence, not a finding. Rhode Island's treasurer is the
  //   "General Treasurer", Texas's comptroller the "Comptroller of Public Accounts", Indiana's
  //   the "Comptroller of State". All three came back unmatched until these were added.
  'treasurer': ['treasurer', 'state treasurer', 'treasurer of state', 'treasurer and receiver general', 'general treasurer'],
  'auditor': ['auditor', 'state auditor', 'auditor of state', 'auditor of the commonwealth'],
  'comptroller': ['comptroller', 'state comptroller', 'comptroller of public accounts', 'comptroller of state'],
  'controller': ['controller', 'state controller'],
  'insurance commissioner': ['insurance commissioner', 'commissioner of insurance'],
  'labor commissioner': ['labor commissioner', 'commissioner of labor'],
  'superintendent of public instruction': ['superintendent of public instruction', 'state superintendent of schools', 'superintendent of schools', 'secretary of education'],
  'agriculture commissioner': ['agriculture commissioner', 'commissioner of agriculture', 'secretary of agriculture', 'director of agriculture', 'commissioner of agriculture and industries'],
  'land commissioner': ['land commissioner', 'commissioner of public lands', 'commissioner of state lands'],
  'chief financial officer': ['chief financial officer'],
  'railroad commissioner': ['railroad commissioner'],
  'mine inspector': ['mine inspector', 'state mine inspector'],
};
const canon = t => { for (const [k, v] of Object.entries(ALIAS)) if (v.includes(t)) return k; return t; };

const ours = {};
for (const o of offices) {
  (ours[o.st] ||= []).push({ ...o, key: canon(strip(o.st, o.title)), races: Number(o.races_2026), won: Number(o.winners_recorded) });
}

const rows = [];
for (const r of bp) {
  const k = canon(strip(r.st, r.office));
  const isAp = AP_OFFICES.has(k);
  const seats = (ours[r.st] || []).filter(o => o.key === k);
  const winners = r.candidates.filter(c => c.won);
  rows.push({
    st: r.st, office: r.office, key: k, isAp,
    nWinners: winners.length, called: winners.length > 0,
    nCands: r.candidates.length,
    seat: seats.length === 1 ? seats[0] : null,
    nSeats: seats.length,
    narrative: r.narrative,
  });
}

const b = { apOffice: [], uncalled: [], noSeat: [], ambiguous: [], haveRaceAndWinner: [], haveRaceNoWinner: [], seatNoRace: [] };
for (const r of rows) {
  if (r.isAp) b.apOffice.push(r);
  else if (!r.called) b.uncalled.push(r);
  else if (r.nSeats === 0) b.noSeat.push(r);
  else if (r.nSeats > 1) b.ambiguous.push(r);
  else if (r.seat.races === 0) b.seatNoRace.push(r);
  else if (r.seat.won > 0) b.haveRaceAndWinner.push(r);
  else b.haveRaceNoWinner.push(r);
}
const sum = Object.values(b).reduce((n, v) => n + v.length, 0);
console.log(`Ballotpedia general-election voteboxes: ${rows.length}`);
for (const [k, v] of Object.entries(b)) console.log(`  ${String(v.length).padStart(4)}  ${k}`);
if (sum !== rows.length) throw new Error(`BUCKETS DO NOT SUM: ${sum} vs ${rows.length}`);
console.log(`  (sum ${sum} ✔)`);

const show = (label, list, f) => { if (!list.length) return; console.log(`\n=== ${label} (${list.length}) ===`); for (const r of list) console.log('  ' + f(r)); };
show('WE HOLD THE SEAT, NO 2026 RACE ROW — the work', b.seatNoRace, r => `${r.st} ${r.office}  [${r.key}]  ${r.nCands} cands`);
show('WE HOLD THE RACE, NO WINNER RECORDED — also the work, but an UPDATE', b.haveRaceNoWinner, r => `${r.st} ${r.office}  [${r.key}]  ${r.nCands} cands`);
show('ALREADY RECORDED', b.haveRaceAndWinner, r => `${r.st} ${r.office}`);
show('NO SEAT OF OURS MATCHES', b.noSeat, r => `${r.st} ${r.office}  [${r.key}]`);
show('AMBIGUOUS — more than one of our seats matches', b.ambiguous, r => `${r.st} ${r.office}  [${r.key}] x${r.nSeats}`);
show('BALLOTPEDIA MARKS NO WINNER', b.uncalled, r => `${r.st} ${r.office}`);
fs.writeFileSync(`${SP}/bp-recon.json`, JSON.stringify({ rows, buckets: Object.fromEntries(Object.entries(b).map(([k, v]) => [k, v.length])) }, null, 1));
