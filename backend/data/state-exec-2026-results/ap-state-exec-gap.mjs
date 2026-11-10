// Full reconciliation: every AP state-executive race against our STATE_EXEC offices.
import fs from 'node:fs';
const SP = process.argv[2];
const md = JSON.parse(fs.readFileSync(`${SP}/ap-state/metadata.json`, 'utf8'));
const pgRaw = JSON.parse(fs.readFileSync(`${SP}/ap-state/progress.json`, 'utf8'));
const offices = JSON.parse(fs.readFileSync(`${SP}/offices.json`, 'utf8'));

const STATE_NAME = {AL:'Alabama',AK:'Alaska',AZ:'Arizona',AR:'Arkansas',CA:'California',CO:'Colorado',CT:'Connecticut',DE:'Delaware',FL:'Florida',GA:'Georgia',HI:'Hawaii',ID:'Idaho',IL:'Illinois',IN:'Indiana',IA:'Iowa',KS:'Kansas',KY:'Kentucky',LA:'Louisiana',ME:'Maine',MD:'Maryland',MA:'Massachusetts',MI:'Michigan',MN:'Minnesota',MS:'Mississippi',MO:'Missouri',MT:'Montana',NE:'Nebraska',NV:'Nevada',NH:'New Hampshire',NJ:'New Jersey',NM:'New Mexico',NY:'New York',NC:'North Carolina',ND:'North Dakota',OH:'Ohio',OK:'Oklahoma',OR:'Oregon',PA:'Pennsylvania',RI:'Rhode Island',SC:'South Carolina',SD:'South Dakota',TN:'Tennessee',TX:'Texas',UT:'Utah',VT:'Vermont',VA:'Virginia',WA:'Washington',WV:'West Virginia',WI:'Wisconsin',WY:'Wyoming',PR:'Puerto Rico',DC:'District of Columbia'};

// our office titles carry the state name in some states ("Texas Governor") and not others ("Governor")
const strip = (st, t) => {
  const name = STATE_NAME[st] || '';
  let s = t.trim();
  if (name && s.toLowerCase().startsWith(name.toLowerCase() + ' ')) s = s.slice(name.length + 1);
  if (s.toLowerCase().startsWith(st.toLowerCase() + ' ')) s = s.slice(st.length + 1);
  return s.trim().toLowerCase();
};
const AP_TO_OURS = {
  'governor': ['governor'],
  'lieutenant governor': ['lieutenant governor', 'lt governor', 'lt. governor'],
  'attorney general': ['attorney general'],
  'secretary of state': ['secretary of state'],
  'railroad commissioner': ['railroad commissioner'],
};

// 🔴 count(*) is bigint and the pg driver returns bigint as a STRING. "0" !== 0, so every
//    numeric comparison below silently failed and 94 of 98 races fell into no bucket at all.
//    Caught because the buckets did not sum to the total — print the sum, always.
const byState = {};
for (const o of offices) {
  const races = Number(o.races_2026), won = Number(o.winners_recorded);
  if (!Number.isFinite(races) || !Number.isFinite(won)) throw new Error(`non-numeric counts on ${o.st} ${o.title}`);
  (byState[o.st] ||= []).push({ ...o, races_2026: races, winners_recorded: won, key: strip(o.st, o.title) });
}

const EXEC = new Set(Object.keys(AP_TO_OURS).map(k => k));
const rows = [];
for (const [id, r] of Object.entries(md)) {
  const office = (r.officeName || '').toLowerCase();
  if (!EXEC.has(office)) continue;
  const p = pgRaw[id] || {};
  const cs = Array.isArray(p.candidates) ? p.candidates : [];
  const w = cs.filter(c => c.winner === 'X');
  const nameOf = cid => { const c = Object.values(r.candidates || {}).find(x => x.candidateID === cid);
                          return c ? `${c.first || ''} ${c.last}`.trim() + ` (${c.party})` : cid; };
  const st = r.statePostal;
  const cands = AP_TO_OURS[office];
  const ours = (byState[st] || []).filter(o => cands.includes(o.key));
  rows.push({
    st, office: r.officeName, called: r.raceCallStatus === 'Called', winner: w.length ? nameOf(w[0].candidateID) : null,
    pct: w.length ? w[0].votePct : null, eevp: p.eevp,
    seat: ours.length === 1 ? 'yes' : (ours.length === 0 ? 'NO SEAT' : `${ours.length} matches`),
    race2026: ours.length === 1 ? ours[0].races_2026 : null,
    recorded: ours.length === 1 ? ours[0].winners_recorded : null,
  });
}
rows.sort((a, b) => a.st.localeCompare(b.st) || a.office.localeCompare(b.office));

const called = rows.filter(r => r.winner);
const recorded = called.filter(r => r.recorded === 1);
const haveSeatNoRace = called.filter(r => r.seat === 'yes' && r.race2026 === 0);
const noSeat = called.filter(r => r.seat === 'NO SEAT');
const ambiguous = called.filter(r => r.seat !== 'yes' && r.seat !== 'NO SEAT');
const raceNotRecorded = called.filter(r => r.race2026 > 0 && r.recorded === 0);

console.log(`AP state-executive races: ${rows.length}  |  with a winner: ${called.length}  |  uncalled: ${rows.length - called.length}`);
console.log(`  recorded by us          : ${recorded.length}`);
console.log(`  seat exists, NO 2026 race: ${haveSeatNoRace.length}   <-- the gap`);
console.log(`  no seat at all           : ${noSeat.length}`);
console.log(`  ambiguous seat match     : ${ambiguous.length}`);
console.log(`  race exists but unrecorded: ${raceNotRecorded.length}`);
const sum = recorded.length + haveSeatNoRace.length + noSeat.length + ambiguous.length + raceNotRecorded.length;
if (sum !== called.length) throw new Error(`BUCKETS DO NOT SUM: ${sum} classified vs ${called.length} called — the classification is broken, not the data`);
console.log(`  (buckets sum to ${sum} = ${called.length} called ✔)`);

console.log('\n=== CALLED BY AP, SEAT EXISTS, NO 2026 RACE ROW (we can hold no result) ===');
const g = {};
for (const r of haveSeatNoRace) (g[r.st] ||= []).push(`${r.office} → ${r.winner} ${r.pct}%`);
for (const [st, v] of Object.entries(g).sort()) console.log(`  ${st}: ${v.join('  |  ')}`);

if (noSeat.length) { console.log('\n=== CALLED BY AP, WE HOLD NO SUCH SEAT ===');
  for (const r of noSeat) console.log(`  ${r.st} ${r.office} → ${r.winner} ${r.pct}%`); }
if (ambiguous.length) { console.log('\n=== AMBIGUOUS SEAT MATCH — read these by hand ===');
  for (const r of ambiguous) console.log(`  ${r.st} ${r.office}: ${r.seat}`); }
if (raceNotRecorded.length) { console.log('\n=== 🔴 RACE ROW EXISTS AND WE DID NOT RECORD IT ===');
  for (const r of raceNotRecorded) console.log(`  ${r.st} ${r.office} → ${r.winner} ${r.pct}%`); }
console.log('\n=== AP STATE-EXEC RACES NOT YET CALLED ===');
for (const r of rows.filter(x => !x.winner)) console.log(`  ${r.st} ${r.office}  (${r.called ? 'Called but no winner flag' : 'uncalled'}, eevp=${r.eevp})`);
