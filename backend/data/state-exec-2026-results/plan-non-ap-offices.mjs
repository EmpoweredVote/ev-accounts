// Build the full plan: which Ballotpedia votebox feeds which of our races, split into the
// races to CREATE and the races to UPDATE, with every candidate resolved.
//
// 🔴 IN A TICKET STATE THE LIEUTENANT GOVERNOR'S TABLE ROW NAMES THE GOVERNOR. Ballotpedia
//    renders the LG contest as the gubernatorial ticket: the row reads "David Crowley /
//    Sarah Godlewski" and the ✔ is on Crowley, who is running for GOVERNOR. The NARRATIVE names
//    the actual lieutenant-governor candidates. Taking the row would seat six governors in six
//    lieutenant governors' chairs — CT, HI, MA, NM, PA, WI — each one entirely plausible.
//    So for a ticket LG votebox the candidate is the RUNNING MATE, and the narrative is checked.
import fs from 'node:fs';
const SP = process.argv[2];
const bp = JSON.parse(fs.readFileSync(`${SP}/bp-all-ballots.json`, 'utf8'));
const offices = JSON.parse(fs.readFileSync(`${SP}/offices.json`, 'utf8'));
const existing = JSON.parse(fs.readFileSync(`${SP}/existing11.json`, 'utf8'));
const STATES = JSON.parse(fs.readFileSync(`${SP}/all-states.json`, 'utf8'));

const norm = s => (s || '').toLowerCase().replace(/[^a-z0-9 ]/g, ' ').replace(/\s+/g, ' ').trim();
const nm = s => (s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z ]/g, ' ').replace(/\s+/g, ' ').trim();
const SUF = new Set(['jr', 'sr', 'ii', 'iii', 'iv']);
const ends = s => { const t = nm(s).split(' ').filter(w => !SUF.has(w)); return t.length < 2 ? (t[0] || '') : `${t[0]} ${t[t.length - 1]}`; };
const strip = (st, t) => {
  const name = (STATES[st] || '').toLowerCase();
  let s = norm(t);
  if (name && s.startsWith(name + ' ')) s = s.slice(name.length + 1);
  if (name && s.endsWith(' of ' + name)) s = s.slice(0, -(name.length + 4));
  if (s.startsWith(st.toLowerCase() + ' ')) s = s.slice(st.length + 1);
  return s.trim();
};
const ALIAS = {
  'treasurer': ['treasurer', 'state treasurer', 'treasurer of state', 'treasurer and receiver general', 'general treasurer'],
  'auditor': ['auditor', 'state auditor', 'auditor of state', 'auditor of the commonwealth'],
  'comptroller': ['comptroller', 'state comptroller', 'comptroller of public accounts', 'comptroller of state'],
  'controller': ['controller', 'state controller'],
  'superintendent of public instruction': ['superintendent of public instruction', 'state superintendent of schools', 'superintendent of schools'],
  'agriculture commissioner': ['agriculture commissioner', 'commissioner of agriculture'],
  'land commissioner': ['land commissioner'],
  'chief financial officer': ['chief financial officer'],
  'mine inspector': ['mine inspector', 'state mine inspector'],
  'lieutenant governor': ['lieutenant governor'],
  // AZ's Corporation Commission seats are titled plainly "Commissioner" in our offices
  'commissioner': ['commissioner', 'corporation commission 2 seats'],
};
const canon = t => { for (const [k, v] of Object.entries(ALIAS)) if (v.includes(t)) return k; return t; };

// the AP-covered offices are recorded already or waiting on AP — EXCEPT a Lieutenant Governor
// in a ticket state, which AP never publishes at all and which therefore falls through.
const AP_STATES_LG = new Set(['AL', 'AR', 'CA', 'GA', 'ID', 'NV', 'OK', 'RI', 'TX', 'VT']);
const AP_OFFICE = new Set(['governor', 'attorney general', 'secretary of state', 'secretary of the commonwealth', 'secretary of the state']);

const ourOffices = {};
for (const o of offices) (ourOffices[o.st] ||= []).push({ ...o, key: canon(strip(o.st, o.title)), races: Number(o.races_2026) });

// existing races, by office id
const exByOffice = {};
for (const r of existing) if (r.office_id) (exByOffice[r.office_id] ||= { race_id: r.race_id, seats: r.seats, title: r.title, st: r.st, rows: [] }).rows.push(r);

const create = [], update = [], skipped = [];
for (const r of bp) {
  const key = canon(strip(r.st, r.office));
  const isLG = key === 'lieutenant governor';
  if (AP_OFFICE.has(key)) { continue; }
  if (isLG && AP_STATES_LG.has(r.st)) { continue; }          // AP publishes it; not this pass
  const winners = r.candidates.filter(c => c.won);
  if (!winners.length) { skipped.push({ ...r, why: 'Ballotpedia marks no winner' }); continue; }
  let seats = (ourOffices[r.st] || []).filter(o => o.key === key);
  // ⚠ Arizona holds FIVE offices plainly titled "Commissioner" — the Corporation Commission's
  //   seats. Exactly one of them carries a 2026-11-03 race, and that race has seats = 2 and the
  //   same five candidates Ballotpedia lists, so the pin is to that race, not a guess among five.
  if (r.st === 'AZ' && key === 'commissioner') seats = seats.filter(o => o.office_id === '686d5bbc-4170-4925-910e-a47368ac3cf3');
  if (seats.length !== 1) { skipped.push({ st: r.st, office: r.office, why: seats.length ? `${seats.length} of our seats match "${key}"` : `we hold no seat matching "${key}"` }); continue; }
  const seat = seats[0];

  // 🔴 ticket LG: the person is the RUNNING MATE, and the narrative must name them
  const ticket = isLG && r.candidates.some(c => c.runningMate);
  const people = r.candidates.map(c => ({
    name: ticket ? (c.runningMate || null) : c.name,
    ticketHead: ticket ? c.name : null,
    party: c.party, won: c.won, writeIn: c.writeIn,
    // on a ticket row the FIRST link is the governor's article and the second the running
    // mate's — giving the mate the first one would cite the wrong person entirely
    url: ticket ? (c.mateUrl ?? null) : c.url,
    bpPct: c.bpPct,
  })).filter(c => c.name);
  if (ticket) {
    const lead = (r.narrative || '').replace(/^Incumbent\s+/i, '').split(/\s+\(|\s+defeated|\s+won\b/)[0].trim();
    const w = people.find(p => p.won);
    if (!w || ends(w.name) !== ends(lead)) { skipped.push({ st: r.st, office: r.office, why: `ticket LG: the running mate on the winning row is "${w ? w.name : '(none)'}" but the sentence leads with "${lead}"` }); continue; }
  }

  const row = { st: r.st, office: r.office, key, officeId: seat.office_id, ourTitle: seat.title, ticket, narrative: r.narrative, people, nWinners: winners.length };
  if (seat.races === 0) create.push(row);
  else if (exByOffice[seat.office_id]) update.push({ ...row, existing: exByOffice[seat.office_id] });
  else skipped.push({ st: r.st, office: r.office, why: 'a 2026 race exists on this seat and already holds a winner' });
}

fs.writeFileSync(`${SP}/plan.json`, JSON.stringify({ create, update, skipped }, null, 1));
console.log(`CREATE: ${create.length} races, ${create.reduce((n, r) => n + r.people.length, 0)} candidacies`);
console.log(`UPDATE: ${update.length} races, ${update.reduce((n, r) => n + r.people.length, 0)} candidacies`);
console.log(`skipped: ${skipped.length}`);

console.log(`\n=== CREATE ===`);
for (const r of create) console.log(`  ${r.st} ${r.ourTitle.padEnd(34)} ${r.people.length} cands${r.ticket ? '  [TICKET: running mates]' : ''}  winner: ${r.people.find(p => p.won).name}`);
console.log(`\n=== UPDATE (a race already exists; its rows must line up) ===`);
for (const r of update) {
  const ours = r.existing.rows.map(x => x.full_name);
  const theirs = r.people.map(p => p.name);
  const onlyOurs = r.existing.rows.filter(x => !r.people.some(p => ends(p.name) === ends(x.full_name)));
  const onlyTheirs = r.people.filter(p => !r.existing.rows.some(x => ends(p.name) === ends(x.full_name)));
  console.log(`  ${r.st} ${r.ourTitle} — seats=${r.existing.seats}, ${r.nWinners} winner(s), our rows ${ours.length}, their ballot ${theirs.length}`);
  if (onlyTheirs.length) console.log(`      🔴 ON BALLOTPEDIA'S BALLOT, NOT IN OUR RACE: ${onlyTheirs.map(p => p.name).join(', ')}`);
  if (onlyOurs.length) console.log(`      ⚠ in our race, not on Ballotpedia's ballot: ${onlyOurs.map(x => `${x.full_name} [${x.result || 'NULL'}]`).join(', ')}`);
}
console.log(`\n=== SKIPPED ===`);
for (const r of skipped) console.log(`  ${r.st} ${r.office}: ${r.why}`);
