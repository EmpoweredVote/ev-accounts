#!/usr/bin/env node
// Match AP's per-state legislative races to ours, and AP's ballot to our candidacies.
//
// WHAT IT REFUSES TO DO
//  - infer a loser from "not the winner" (CC_0351). A row AP's ballot does not name is left
//    untouched and reported, never written.
//  - read ballot order as a result (CC_0356). The winner is progress.json's winner === 'X';
//    metadata.json names nobody.
//  - trust the winner flag alone where a second reading is available: the flagged candidate
//    must also be AP's top vote-getter. That cross-check is INVALID for a ranked-choice race,
//    so it is skipped there and the race is reported, never silently recorded.
//
// SHAPE ASSERTIONS, because the wrong guess is silent (CC_0357):
//   metadata.candidates is an OBJECT MAP keyed by candidateID; progress.candidates is an ARRAY.
import fs from 'node:fs';
import path from 'node:path';

const apDir = process.argv[2];
const ourFile = process.argv[3];
const outFile = process.argv[4];
const overrideFile = process.argv[5];
if (!apDir || !ourFile || !outFile) {
  console.error('usage: analyse.mjs <ap-dir> <our-rows.json> <out.json> [name-overrides.json]');
  process.exit(2);
}

// Reviewed, hand-matched ballot lines. Keyed on AP's race id and candidate id, never on a name.
const overrides = new Map();
if (overrideFile) {
  const o = JSON.parse(fs.readFileSync(overrideFile, 'utf8'));
  for (const e of o.overrides) {
    const k = e.ap_race_id + ':' + e.ap_candidate_id;
    if (overrides.has(k)) throw new Error('duplicate override ' + k);
    if (!e.basis || e.basis.length < 40) throw new Error('override ' + k + ' carries no stated basis');
    overrides.set(k, e);
  }
}
const overridesUsed = new Set();

// AP ballot lines that are not people. Both carry votes and a percentage.
const NOT_A_PERSON = new Set(['100008', '100013']); // Total Write-ins / None of These Candidates

const fold = (s) => (s || '')
  .normalize('NFD').replace(/[̀-ͯ]/g, '')
  .toUpperCase().replace(/[^A-Z0-9]/g, '');

const stripWriteIn = (s) => (s || '').replace(/\s*\(write-?in\)\s*/gi, ' ').replace(/\s+/g, ' ').trim();

// Name tokens with nicknames, suffixes and punctuation removed. A nickname is whatever a ballot
// name puts in quotes or parentheses; a suffix is a generational one, never a surname.
const SUFFIX = /^(JR|SR|II|III|IV|V)$/;
const nameTokens = (s) => (s || '')
  .replace(/["“”‘’'][^"“”‘’']*["“”‘’']/g, ' ')
  .replace(/\([^)]*\)/g, ' ')
  .split(/[\s,]+/)
  .map((t) => fold(t))
  .filter((t) => t && !SUFFIX.test(t));

function apKey(st, m) {
  const pos = /position\s*(\d+)/i.exec(m.seatName || '');
  // MA (and any state whose seats are NAMED, not numbered) carries an internal seatNum that is
  // not a district number, so those are keyed on the folded seat name instead.
  const numbered = /^district\s*\d+/i.test(m.seatName || '');
  const base = numbered ? ('#' + m.seatNum) : ('@' + fold((m.seatName || '').replace(/\s*&\s*/g, ' AND ')));
  return st + '|' + m.officeID + '|' + base + (pos ? '|P' + pos[1] : '');
}

// 🔴 OUR SIDE OFFERS TWO CANDIDATE KEYS AND NEITHER IS RIGHT EVERYWHERE. Most states number
//   their seats, so ocd_id's sldl:/sldu: suffix is the district number AP publishes as seatNum.
//   Massachusetts NAMES them ("25th Middlesex"), and there the ocd suffix is an internal index
//   that happens to be a number — sldl:83 for the 25th Middlesex — so a numeric key matches
//   nothing and the race silently drops out. Both keys are offered and exactly one must resolve.
function ourKeys(r) {
  const st = r.state.toUpperCase();
  const office = r.district_type === 'STATE_LOWER' ? 'Y' : 'Z';
  const sld = /\/sld[lu]:(.+)$/.exec(r.ocd_id || '');
  const num = sld && /^\d+$/.test(sld[1]) ? sld[1] : null;
  const pos = /position\s*(\d+)/i.exec(r.office_title || '');
  const tail = pos ? '|P' + pos[1] : '';
  const keys = [];
  if (num !== null) keys.push(st + '|' + office + '|#' + String(Number(num)) + tail);
  const named = fold((r.district_label || '').replace(/\s+District$/i, '').replace(/\s*&\s*/g, ' AND '));
  if (named) keys.push(st + '|' + office + '|@' + named + tail);
  return keys;
}

// -- AP side ---------------------------------------------------------------------------------
const apRaces = new Map();
const apByState = {};
const states = [...new Set(fs.readdirSync(apDir).filter((f) => f.endsWith('-metadata.json')).map((f) => f.slice(0, 2)))];

for (const st of states) {
  const mPath = path.join(apDir, st + '-metadata.json');
  const pPath = path.join(apDir, st + '-progress.json');
  for (const p of [mPath, pPath]) {
    const sz = fs.statSync(p).size;
    if (sz < 500) throw new Error(p + ' is ' + sz + ' bytes - a zero-byte file parses cleanly and yields nothing');
  }
  const meta = JSON.parse(fs.readFileSync(mPath, 'utf8'));
  const prog = JSON.parse(fs.readFileSync(pPath, 'utf8'));
  let n = 0;
  for (const [raceID, m] of Object.entries(meta)) {
    if (m.officeID !== 'Y' && m.officeID !== 'Z') continue;
    if (m.statePostal !== st) throw new Error(raceID + ': statePostal ' + m.statePostal + ' in the ' + st + ' file');
    if (Array.isArray(m.candidates)) throw new Error(raceID + ': metadata.candidates is an ARRAY - expected an object map keyed by candidateID');
    const pr = prog[raceID];
    if (!pr) throw new Error(raceID + ': in metadata.json and not in progress.json');
    if (!Array.isArray(pr.candidates)) throw new Error(raceID + ': progress.candidates is not an ARRAY - indexing it as a map returns undefined for every candidate');

    const ballot = [];
    for (const pc of pr.candidates) {
      const id = String(pc.candidateID);
      const md = m.candidates ? m.candidates[id] : null;
      if (!md) throw new Error(raceID + ': progress candidate ' + id + ' has no metadata entry');
      if (NOT_A_PERSON.has(id)) continue; // a ballot aggregate, not a person
      const isWriteIn = /\(write-?in\)/i.test((md.first || '') + ' ' + (md.last || ''));
      ballot.push({
        candidateID: id,
        first: stripWriteIn(md.first || ''),
        last: stripWriteIn(md.last || ''),
        party: md.party || null,
        incumbent: !!md.incumbent,
        isWriteIn,
        voteCount: pc.voteCount == null ? 0 : pc.voteCount,
        votePct: pc.votePct == null ? 0 : pc.votePct,
        winner: pc.winner === 'X',
        calledAt: pc.calledAt || null,
      });
    }
    const key = apKey(st, m);
    if (apRaces.has(key)) throw new Error('duplicate AP key ' + key + ' (' + raceID + ' and ' + apRaces.get(key).raceID + ')');
    apRaces.set(key, {
      key, raceID, state: st, officeID: m.officeID, officeName: m.officeName,
      seatName: m.seatName, seatNum: m.seatNum,
      callStatus: m.raceCallStatus, isCertified: !!m.isCertified,
      rankedChoice: !!m.rankedChoice,
      incumbentID: m.incumbentID ? String(m.incumbentID) : null,
      ballot,
    });
    n++;
  }
  apByState[st] = n;
}

// -- our side --------------------------------------------------------------------------------
const ourRows = JSON.parse(fs.readFileSync(ourFile, 'utf8'));
const ourRaces = new Map();
for (const row of ourRows) {
  let r = ourRaces.get(row.race_id);
  if (!r) {
    r = {
      race_id: row.race_id, state: row.state, district_type: row.district_type,
      ocd_id: row.ocd_id, district_label: row.district_label,
      office_id: row.office_id, office_title: row.office_title, seats: row.seats,
      current_holder_id: row.current_holder_id, current_holder_name: row.current_holder_name,
      candidates: [],
    };
    r.keys = ourKeys(r);
    ourRaces.set(row.race_id, r);
  }
  r.candidates.push(row);
}

// -- match races -----------------------------------------------------------------------------
const matched = [];
const ourUnmatched = [];
for (const r of ourRaces.values()) {
  const hits = r.keys.map((k) => apRaces.get(k)).filter(Boolean);
  const uniq = [...new Set(hits)];
  if (uniq.length > 1) throw new Error(r.district_label + ' (' + r.office_title + ') matches ' + uniq.length + ' AP races: ' + uniq.map((u) => u.raceID).join(', '));
  if (!uniq.length) { ourUnmatched.push(r); continue; }
  matched.push({ our: r, ap: uniq[0] });
}
const matchedApKeys = new Set(matched.map((m) => m.ap.key));
const apUnmatched = [...apRaces.values()].filter((a) => !matchedApKeys.has(a.key));

// -- match candidates inside a matched race --------------------------------------------------
const plan = [];
for (const pair of matched) {
  const our = pair.our;
  const ap = pair.ap;
  const rec = {
    race_id: our.race_id, state: our.state, chamber: our.district_type,
    district_label: our.district_label, office_title: our.office_title, seats: our.seats,
    ap_race_id: ap.raceID, ap_seat: ap.officeName + ' / ' + ap.seatName,
    call_status: ap.callStatus, ranked_choice: ap.rankedChoice, is_certified: ap.isCertified,
    current_holder_name: our.current_holder_name,
    writes: [], ours_not_on_ap: [], ap_not_in_ours: [], blockers: [],
  };

  const winners = ap.ballot.filter((b) => b.winner);
  const top = [...ap.ballot].sort((a, b) => b.voteCount - a.voteCount);

  if (ap.callStatus !== 'Called') { rec.skip = 'AP has not called it (' + ap.callStatus + ')'; plan.push(rec); continue; }
  if (!winners.length) { rec.blockers.push('AP says Called and flags no winner'); }
  if (winners.length && winners.length !== our.seats) rec.blockers.push('AP flags ' + winners.length + ' winner(s) against races.seats = ' + our.seats);
  // 🔴 A TOP-VOTE-GETTER CHECK OVER AN ALL-ZERO BALLOT COMPARES NOTHING AND PASSES. AP calls a
  //   single-candidate race on the BALLOT, not the count, and publishes 0 votes for everyone in
  //   it (19 of Washington's 122, every one of them unopposed). That is fine where there is one
  //   name and vacuous the moment there are two, so the shape is asserted rather than assumed.
  //   It is NOT vacuous when every name on the ballot wins — an unopposed 2-seat Arizona House
  //   race with exactly 2 candidates makes no ordering decision at all, so there is nothing a
  //   transposition could get wrong. The gate therefore fires only where AP would have had to
  //   choose: more candidates than winners, and no votes to choose on.
  const apTotal = ap.ballot.reduce((a, b) => a + b.voteCount, 0);
  if (apTotal === 0 && ap.ballot.length > winners.length) rec.blockers.push('AP publishes 0 votes for all ' + ap.ballot.length + ' candidates but flags only ' + winners.length + ' winner(s) - the top-vote-getter cross-check would be vacuous');
  rec.ap_all_zero = apTotal === 0;

  if (winners.length) {
    if (!ap.rankedChoice) {
      const cut = top.slice(0, winners.length).map((b) => b.candidateID).sort().join(',');
      const flagged = winners.map((b) => b.candidateID).sort().join(',');
      if (cut !== flagged) rec.blockers.push('AP flagged winner is not its own top vote-getter');
    } else {
      rec.blockers.push('ranked-choice: the top-vote-getter cross-check is invalid here');
    }
  }

  // name match, each direction reported separately - they mean opposite things
  const used = new Set();
  for (const b of ap.ballot) {
    const fullKey = fold(b.first + ' ' + b.last);
    const flKey = fold(b.first) + '|' + fold(b.last);
    let hits = our.candidates.filter((c) => !used.has(c.rc_id) && (
      fold(c.full_name) === fullKey || (fold(c.first_name) + '|' + fold(c.last_name)) === flKey
    ));
    let basis = hits.length === 1 ? (fold(hits[0].full_name) === fullKey ? 'exact-full-name' : 'exact-first-last') : null;

    // BASIS 'reviewed': a hand-checked override, keyed on AP's ids and carrying its evidence.
    if (!hits.length) {
      const ov = overrides.get(ap.raceID + ':' + b.candidateID);
      if (ov) {
        if (overridesUsed.has(ap.raceID + ':' + b.candidateID)) throw new Error('override used twice');
        const row = our.candidates.find((c) => c.rc_id === ov.rc_id);
        if (!row) throw new Error('override ' + ov.ap_name + ' names rc_id ' + ov.rc_id + ', which is not in race ' + ap.raceID);
        if (used.has(row.rc_id)) throw new Error('override ' + ov.ap_name + ' names a row already matched to another AP candidate');
        if (fold(row.full_name) !== fold(ov.our_name)) throw new Error('override ' + ov.ap_name + ' expects our row to read "' + ov.our_name + '" and it reads "' + row.full_name + '"');
        overridesUsed.add(ap.raceID + ':' + b.candidateID);
        hits = [row]; basis = 'reviewed';
      }
    }

    // BASIS 'holder': AP flags this candidate as the seat's incumbent AND our own
    // office_current_holder names, for that same office, the politician our row links to.
    // Two independent assertions, neither of them a name comparison. It is the rung CC_0359
    // found needs no reading, and it settles 18 spelling disagreements here on its own.
    if (!hits.length && b.incumbent && our.current_holder_id) {
      const byHolder = our.candidates.filter((c) => !used.has(c.rc_id) && c.politician_id && c.politician_id === our.current_holder_id);
      if (byHolder.length === 1) { hits = byHolder; basis = 'holder'; }
      else if (byHolder.length > 1) rec.blockers.push('the incumbent basis matches ' + byHolder.length + ' of our rows');
    }

    // BASIS 'first-last-tokens': the same human written at different lengths. Our ballot names
    // carry nicknames in quotes or parentheses ("Robert (Chili) Hicks", 'Juan "Jerry" Garcia'),
    // middle names and generational suffixes; AP strips all of those and sometimes TRUNCATES a
    // first name to an initial ("A. Anderson" for "A. Dane Anderson"). The test is deliberately
    // narrow — FIRST token equal AND LAST token equal once nicknames, suffixes and punctuation
    // are removed — and it must land on exactly ONE unmatched row in the contest. It never
    // relaxes the surname, which is the thing a namesake shares.
    // 🔴 Washington's own canvass is what proves this is safe rather than convenient: all 25 of
    //   its name variants carry the SAME VOTE COUNT on both sources. See verify-wa-sos.mjs.
    if (!hits.length) {
      const apT = nameTokens(b.first + ' ' + b.last);
      if (apT.length >= 2) {
        const cands = our.candidates.filter((c) => {
          if (used.has(c.rc_id)) return false;
          const t = nameTokens(c.full_name);
          return t.length >= 2 && t[0] === apT[0] && t[t.length - 1] === apT[apT.length - 1];
        });
        if (cands.length === 1) { hits = cands; basis = 'first-last-tokens'; }
        else if (cands.length > 1) rec.blockers.push('token match for AP "' + b.first + ' ' + b.last + '" lands on ' + cands.length + ' of our rows');
      }
    }

    if (hits.length === 1) {
      used.add(hits[0].rc_id);
      rec.writes.push({
        rc_id: hits[0].rc_id, our_name: hits[0].full_name, ap_name: (b.first + ' ' + b.last).trim(),
        match_basis: basis,
        politician_id: hits[0].politician_id, is_incumbent: hits[0].is_incumbent,
        ap_incumbent: b.incumbent, ap_candidate_id: b.candidateID,
        party: b.party, votes: b.voteCount, pct: b.votePct, is_write_in: b.isWriteIn,
        outcome: b.winner ? 'won' : 'lost',
        prior_result: hits[0].result, prior_certainty: hits[0].result_certainty,
        prior_source: hits[0].result_source,
        spelling_differs: fold(hits[0].full_name) !== fullKey,
      });
    } else if (hits.length > 1) {
      rec.blockers.push('AP "' + b.first + ' ' + b.last + '" matches ' + hits.length + ' of our rows');
    } else {
      // someone on the ballot we hold no row for BLOCKS when they won - that is a winner we
      // would otherwise miss entirely.
      rec.ap_not_in_ours.push({ ap_name: (b.first + ' ' + b.last).trim(), party: b.party, votes: b.voteCount, winner: b.winner });
      if (b.winner) rec.blockers.push('AP WINNER "' + b.first + ' ' + b.last + '" matches no row of ours');
    }
  }
  for (const c of our.candidates) {
    if (!used.has(c.rc_id)) rec.ours_not_on_ap.push({ rc_id: c.rc_id, name: c.full_name, result: c.result, candidate_status: c.candidate_status });
  }

  // a row already carrying a result other than 'advanced' is a citation we would lose
  for (const w of rec.writes) {
    if (w.prior_result && w.prior_result !== 'advanced') rec.blockers.push(w.our_name + ' already carries result=' + w.prior_result);
  }

  if (rec.blockers.length) rec.skip = 'blocked';
  plan.push(rec);
}

// An override that has stopped being needed is a stale allowance, and a stale allowance is the
// thing CC_0378's dry run refused. Gate the allowance, not just the rule.
for (const k of overrides.keys()) {
  if (!overridesUsed.has(k)) throw new Error('override ' + k + ' (' + overrides.get(k).ap_name + ') was never used - it has stopped matching and must be re-checked, not carried');
}

const basisCount = {};
for (const r of plan) for (const w of r.writes) basisCount[w.match_basis] = (basisCount[w.match_basis] || 0) + 1;

const out = {
  generated_at: new Date().toISOString(),
  match_basis_counts: basisCount,
  ap_dir: apDir, our_file: ourFile,
  ap_legislative_races_by_state: apByState,
  our_races: ourRaces.size,
  matched_races: matched.length,
  our_races_with_no_ap_race: ourUnmatched.map((r) => ({ race_id: r.race_id, state: r.state, key: r.keys.join(" or "), label: r.district_label, office: r.office_title })),
  ap_races_we_hold_no_race_for: apUnmatched.length,
  plan,
};
fs.writeFileSync(outFile, JSON.stringify(out, null, 1));

// -- report ----------------------------------------------------------------------------------
const writable = plan.filter((r) => !r.skip);
const byState = {};
for (const r of plan) {
  if (!byState[r.state]) byState[r.state] = { races: 0, writable: 0, uncalled: 0, blocked: 0, rows: 0, won: 0, lost: 0 };
  const s = byState[r.state];
  s.races++;
  if (!r.skip) {
    s.writable++;
    s.rows += r.writes.length;
    s.won += r.writes.filter((w) => w.outcome === 'won').length;
    s.lost += r.writes.filter((w) => w.outcome === 'lost').length;
  } else if (r.skip === 'blocked') s.blocked++;
  else s.uncalled++;
}
console.log('AP legislative races read: ' + apRaces.size + ' across ' + Object.keys(apByState).length + ' states');
console.log('our races: ' + ourRaces.size + ' - matched to an AP race: ' + matched.length + ' - ours with NO AP race: ' + ourUnmatched.length);
console.log('AP legislative races in these states we hold no race for: ' + apUnmatched.length);
console.log('');
console.log('state  races  writable  uncalled  blocked   rows    won   lost');
const tot = { races: 0, writable: 0, uncalled: 0, blocked: 0, rows: 0, won: 0, lost: 0 };
for (const st of Object.keys(byState).sort()) {
  const s = byState[st];
  for (const k of Object.keys(tot)) tot[k] += s[k];
  console.log(st.padEnd(6) + String(s.races).padStart(5) + String(s.writable).padStart(10) + String(s.uncalled).padStart(10) + String(s.blocked).padStart(9) + String(s.rows).padStart(7) + String(s.won).padStart(7) + String(s.lost).padStart(7));
}
console.log('TOTAL ' + String(tot.races).padStart(5) + String(tot.writable).padStart(10) + String(tot.uncalled).padStart(10) + String(tot.blocked).padStart(9) + String(tot.rows).padStart(7) + String(tot.won).padStart(7) + String(tot.lost).padStart(7));

const blocked = plan.filter((r) => r.skip === 'blocked');
console.log('');
console.log('--- ' + blocked.length + ' blocked races, every blocker named ---');
for (const r of blocked) console.log('  ' + r.state + ' ' + r.district_label + ' | ' + r.office_title + ': ' + r.blockers.join(' ; '));

const spellingDiffs = writable.flatMap((r) => r.writes.filter((w) => w.spelling_differs).map((w) => r.state + ' ' + r.district_label + ': ours "' + w.our_name + '" / AP "' + w.ap_name + '"'));
console.log('');
console.log('--- ' + spellingDiffs.length + ' matched rows where the spelling differs (read these, not the matches) ---');
for (const d of spellingDiffs) console.log('  ' + d);

const ourExtra = writable.flatMap((r) => r.ours_not_on_ap.map((o) => r.state + ' ' + r.district_label + ': "' + o.name + '" result=' + (o.result || 'NULL') + ' status=' + (o.candidate_status || '-')));
console.log('');
console.log('--- ' + ourExtra.length + ' of our rows AP ballot does not name (left UNTOUCHED) ---');
for (const d of ourExtra.slice(0, 40)) console.log('  ' + d);
if (ourExtra.length > 40) console.log('  ... and ' + (ourExtra.length - 40) + ' more, all in the JSON');

const apExtra = writable.flatMap((r) => r.ap_not_in_ours.map((o) => r.state + ' ' + r.district_label + ': AP "' + o.ap_name + '" (' + o.party + ', ' + o.votes + ') we hold no row'));
console.log('');
console.log('--- ' + apExtra.length + ' on AP ballots in writable races we hold no row for ---');
for (const d of apExtra.slice(0, 40)) console.log('  ' + d);
if (apExtra.length > 40) console.log('  ... and ' + (apExtra.length - 40) + ' more, all in the JSON');

console.log('');
console.log('wrote ' + outFile);
