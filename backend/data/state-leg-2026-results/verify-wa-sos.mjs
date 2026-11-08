#!/usr/bin/env node
// A SECOND, INDEPENDENT READING OF EVERY WASHINGTON LEGISLATIVE CONTEST.
//
// Washington's Secretary of State publishes its own canvass through the same API its public
// results site reads: results.votewa.gov/results/public/api/elections/washington/20261103/data.
// It is authoritative for THE BALLOT and THE COUNT and it publishes NO winner flag at all
// (every isWinner is null) — so it settles who stood and how many votes they got, and AP
// supplies the call. Two sources, each used for the field it owns.
//
// 🔴 This exists because the name match is the dangerous step. AP prints "Kim Harless" where we
//   hold "Kim D. Harless" and "Mia Gregerson" where we hold "Mia Su-Ling Gregerson"; relaxing a
//   comparison until those match is how a namesake gets seated. The state's own ballot is the
//   thing that says which spelling belongs to which contest.
import fs from 'node:fs';

const waFile = process.argv[2];
const apDir = process.argv[3];
const outFile = process.argv[4];
if (!waFile || !apDir || !outFile) {
  console.error('usage: verify-wa-sos.mjs <wa-sos-data.json> <ap-dir> <out.json>');
  process.exit(2);
}
for (const p of [waFile, apDir + '/WA-metadata.json', apDir + '/WA-progress.json']) {
  const sz = fs.statSync(p).size;
  if (sz < 500) throw new Error(p + ' is ' + sz + ' bytes - a zero-byte file parses cleanly and yields nothing');
}

const fold = (s) => (s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toUpperCase().replace(/[^A-Z0-9]/g, '');

const wa = JSON.parse(fs.readFileSync(waFile, 'utf8'));
if (!Array.isArray(wa.ballotItems)) throw new Error('wa.ballotItems is not an array');

// "Legislative District 49 - State Representative Pos. 1" / "... - State Senator"
const waRaces = new Map();
for (const b of wa.ballotItems) {
  const name = b.name && b.name[0] ? b.name[0].text : '';
  const m = /^Legislative District (\d+)\s*-\s*State (Representative Pos\. (\d)|Senator)/i.exec(name);
  if (!m) continue;
  const key = 'WA|' + (m[3] ? 'Y' : 'Z') + '|#' + Number(m[1]) + (m[3] ? '|P' + m[3] : '');
  const opts = (b.summaryResults && b.summaryResults.ballotOptions) || [];
  if (waRaces.has(key)) throw new Error('duplicate WA SoS key ' + key);
  waRaces.set(key, {
    key, title: name,
    candidates: opts.map((o) => ({
      name: o.name && o.name[0] ? o.name[0].text : '',
      votes: o.voteCount == null ? 0 : o.voteCount,
      party: o.party ? o.party.abbreviation : null,
      isWriteIn: !!o.isWriteIn,
      isWinner: o.isWinner,
    })),
  });
}

const meta = JSON.parse(fs.readFileSync(apDir + '/WA-metadata.json', 'utf8'));
const prog = JSON.parse(fs.readFileSync(apDir + '/WA-progress.json', 'utf8'));
const apRaces = new Map();
for (const [raceID, m] of Object.entries(meta)) {
  if (m.officeID !== 'Y' && m.officeID !== 'Z') continue;
  const pos = /position\s*(\d+)/i.exec(m.seatName || '');
  const key = 'WA|' + m.officeID + '|#' + Number(m.seatNum) + (pos ? '|P' + pos[1] : '');
  const pr = prog[raceID];
  if (!Array.isArray(pr.candidates)) throw new Error(raceID + ': progress.candidates is not an ARRAY');
  apRaces.set(key, {
    key, raceID, callStatus: m.raceCallStatus,
    candidates: pr.candidates
      .filter((pc) => !['100008', '100013'].includes(String(pc.candidateID)))
      .map((pc) => {
        const md = m.candidates[String(pc.candidateID)];
        return { name: ((md.first || '') + ' ' + (md.last || '')).replace(/\s+/g, ' ').trim(), votes: pc.voteCount == null ? 0 : pc.voteCount, winner: pc.winner === 'X' };
      }),
  });
}

// A POSITIVE CONTROL. "No disagreement found" is worthless from a comparison that cannot see
// anything: assert the two sides actually joined before any silence below is allowed to count.
const joined = [...apRaces.keys()].filter((k) => waRaces.has(k));
if (joined.length < 100) throw new Error('only ' + joined.length + ' of ' + apRaces.size + ' AP races joined to a WA SoS contest - the comparison below would pass vacuously');

const report = { generated_at: new Date().toISOString(), ap_races: apRaces.size, wa_sos_races: waRaces.size, joined: joined.length, rows: [], disagreements: [], ap_only: [], wa_only: [] };
let nameExact = 0, nameVariant = 0, voteAgree = 0, voteDisagree = 0;

for (const key of joined) {
  const ap = apRaces.get(key);
  const sos = waRaces.get(key);
  const usedSos = new Set();
  for (const a of ap.candidates) {
    // match AP's candidate to the state's ballot line on the folded full string first, then on
    // first+last tokens — the state prints the name AS FILED, which is the longer form.
    let hit = sos.candidates.find((s, i) => !usedSos.has(i) && fold(s.name) === fold(a.name));
    let variant = false;
    if (!hit) {
      const at = fold(a.name.split(/\s+/)[0]) + '|' + fold(a.name.split(/\s+/).slice(-1)[0]);
      const cands = sos.candidates.filter((s, i) => {
        if (usedSos.has(i)) return false;
        const t = s.name.replace(/[",]/g, ' ').split(/\s+/).filter(Boolean);
        const st = fold(t[0]) + '|' + fold(t[t.length - 1]);
        const stNoSuffix = fold(t[0]) + '|' + fold(t.filter((x) => !/^(JR|SR|II|III|IV)\.?$/i.test(x)).slice(-1)[0]);
        return st === at || stNoSuffix === at;
      });
      if (cands.length === 1) { hit = cands[0]; variant = true; }
    }
    if (!hit) { report.ap_only.push({ race: key, ap_name: a.name, ap_votes: a.votes, state_ballot: sos.candidates.map((s) => s.name) }); continue; }
    usedSos.add(sos.candidates.indexOf(hit));
    if (variant) nameVariant++; else nameExact++;
    const agree = hit.votes === a.votes;
    if (agree) voteAgree++; else { voteDisagree++; report.disagreements.push({ race: key, ap_name: a.name, sos_name: hit.name, ap_votes: a.votes, sos_votes: hit.votes, call_status: ap.callStatus }); }
    report.rows.push({ race: key, ap_name: a.name, sos_name: hit.name, name_variant: variant, ap_votes: a.votes, sos_votes: hit.votes, winner: a.winner });
  }
  sos.candidates.forEach((s, i) => { if (!usedSos.has(i)) report.wa_only.push({ race: key, sos_name: s.name, sos_votes: s.votes }); });
}

const sosWinnerFlags = [...waRaces.values()].flatMap((r) => r.candidates).filter((c) => c.isWinner !== null).length;
report.summary = { nameExact, nameVariant, voteAgree, voteDisagree, sos_rows_carrying_a_winner_flag: sosWinnerFlags };
fs.writeFileSync(outFile, JSON.stringify(report, null, 1));

console.log('AP WA legislative races: ' + apRaces.size + ' | WA SoS contests: ' + waRaces.size + ' | joined: ' + joined.length);
console.log('names: ' + nameExact + ' identical, ' + nameVariant + ' the state prints longer (middle name or suffix)');
console.log('votes: ' + voteAgree + ' agree, ' + voteDisagree + ' disagree');
console.log('WA SoS rows carrying a winner flag: ' + sosWinnerFlags + '  (the state canvasses; it does not call)');
console.log('on AP and not on the state ballot: ' + report.ap_only.length + ' | on the state ballot and not AP: ' + report.wa_only.length);
if (report.ap_only.length) { console.log('\n-- AP names the state ballot does not --'); for (const r of report.ap_only) console.log('  ' + r.race + ' AP "' + r.ap_name + '" vs state ' + JSON.stringify(r.state_ballot)); }
console.log('\n-- the name variants, which are the rows worth reading --');
for (const r of report.rows.filter((x) => x.name_variant)) console.log('  ' + r.race.padEnd(14) + ' AP "' + r.ap_name + '"  =  state "' + r.sos_name + '"   ' + r.ap_votes + ' / ' + r.sos_votes + (r.winner ? '  WINNER' : ''));
if (report.disagreements.length) { console.log('\n-- vote disagreements --'); for (const r of report.disagreements.slice(0, 30)) console.log('  ' + r.race + ' ' + r.ap_name + ': AP ' + r.ap_votes + ' vs state ' + r.sos_votes); }
console.log('\nwrote ' + outFile);
