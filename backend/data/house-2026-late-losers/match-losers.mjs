// Match AP's own ballot for each of the five CC_0447 late-called U.S. House races against our
// race_candidates rows, and emit the set of rows that can be recorded as `lost`.
//
// 🔴 THE RULE (CC_0351): A LOSER IS RECORDED BECAUSE AP'S BALLOT NAMES THEM.
//    "Everyone in a called race who is not the winner lost" is the inference this refuses.
//    Our table still carries people who were never on the November ballot; CC_0351 nearly
//    recorded Lindsey Graham, dead since 2026-07-11, as having lost an election he was not in.
//    A row of ours that AP's ballot does not list is left exactly as it is.
//
// 🔴 AN AGGREGATE LINE IS NOT A PERSON, AND A REGEX CANNOT TELL THE TWO APART.
//    AP's ME-02 ballot carries BOTH kinds at once:
//      "Blank Votes"           -> no `first` at all  -> NOT a person, 6,021 votes
//      "Gregory Ward (write-in)" -> first "Gregory"  -> a person, 125 votes
//    A predicate on the words "write in" merges them, and one on "blank" misses the general
//    case (CC_0351 met the same shape spelled "Total Write-ins"). The discriminator used here
//    is the ABSENCE of `first`, which holds for both spellings.
//
// 🔴 AP'S `incumbent` IS AN ATTRIBUTE OF THE SEAT, NOT A BALLOT LINE — SO THE TEST NEEDS
//    THREE BRANCHES, AND CC_0447 WROTE IT WITH TWO.
//    CC_0447 compared AP's incumbent with AP's winner and turned the answer into prose:
//      winner id == incumbent id  ->  "Incumbent re-elected"
//      winner id != incumbent id  ->  "defeating incumbent X"
//    The second branch is false whenever the incumbent was not a candidate. It put
//    "defeating incumbent Jared Golden" on a voter-facing page for fifteen hours: Golden held
//    ME-02 and retired, so Paul LePage beat Matthew Dunlap for an OPEN seat and defeated no
//    incumbent (`CC_0452` corrected the row; `backend/data/me02-open-seat-2026/OPEN-SEAT.md`).
//    ⚠ Four of the five races came out right, which is why it shipped. A rule can be right most
//    of the time and still be the wrong rule.
//
//    The missing question is not about the winner at all:
//      ▶ IS THE INCUMBENT'S CANDIDATE ID ON A LOSING BALLOT LINE?
//        yes -> the winner defeated the incumbent
//        no  -> the incumbent was NOT ON THE BALLOT, and the winner defeated no incumbent here
//
//    ⚠ IT IS NOT A RARE CASE. Run over AP's committed 470-race federal capture
//    (`backend/data/federal-2026-losers/ap-ballots-2026-11-04.json`), the branch CC_0447 got
//    wrong is the MAJORITY of its own population: of the 96 called races where the winner is not
//    the incumbent, 70 had no incumbent on the ballot and 26 were a real defeat. The two-branch
//    rule would have written 70 false claims, not one.
//
//    🔴 The incumbent is found by AP's CANDIDATE ID, never by name. TX-22's winner is the
//    incumbent's twin brother and CA-04's ballot has carried two Websters, so a surname test
//    answers the wrong question. And because an open seat is a claim that a name is ABSENT,
//    the absence is cross-checked: a line whose NAME matches the incumbent while its ID does
//    not is reported as `open_seat_disputed` and classified as nothing. One of the two
//    identifiers is then wrong, and this file cannot say which.
//
// 🔴 AN OPEN SEAT IS PROVED BY THE BALLOT. WHY THE INCUMBENT LEFT IS NOT.
//    AP publishes who held the seat, never whether they retired, died, were term-limited or
//    ran for something else. `sanctioned_claim` therefore says only what the ballot supports.
//    Source the reason separately before any citation states one.
//
// Both inputs are committed files, so this runs with no database and no dependencies:
//
//   node match-losers.mjs --ap ap-ballots-2026-11-17.json --ours before-values.json --out .
//
// --ap and --ours each let a control hand the matcher tampered input and watch the output move.
//
// 🔴 THE 470-RACE FIGURE ABOVE IS RE-RUNNABLE, NOT ASSERTED. `--seats-only` classifies seats
// against any AP capture and needs no rows of ours, so the claim can be checked rather than
// believed — which is the only reason it is quoted in a comment at all:
//
//   node match-losers.mjs --seats-only --ap ../federal-2026-losers/ap-ballots-2026-11-04.json

import fs from 'node:fs';
import path from 'node:path';

const argv = process.argv.slice(2);
const arg = (k) => { const i = argv.indexOf(k); return i === -1 ? undefined : argv[i + 1]; };
const SEATS_ONLY = argv.includes('--seats-only');
const AP_FILE = arg('--ap'), OURS_FILE = arg('--ours'), OUT_DIR = arg('--out');
if (!AP_FILE || (!SEATS_ONLY && (!OURS_FILE || !OUT_DIR))) {
  console.error('usage: --ap <ap-ballots.json> --ours <before-values.json> --out <dir>');
  console.error('       --ap <ap-ballots.json> --seats-only [--out <dir>]');
  process.exit(2);
}

const ap = JSON.parse(fs.readFileSync(AP_FILE, 'utf8'));
// AP's two committed captures disagree about the envelope: this one wraps its races in
// `{races: [...]}`, the federal one is a bare array. Read both, so the classifier runs on either.
const apRaces = ap.races ?? (Array.isArray(ap) ? ap : []);
const ours = SEATS_ONLY ? [] : JSON.parse(fs.readFileSync(OURS_FILE, 'utf8')).rows;

// Folded only for COMPARISON. A folded string is never written to the database.
const fold = (s) => (s ?? '')
  .normalize('NFD').replace(/[̀-ͯ]/g, '')
  .toLowerCase().replace(/\(write-in\)/g, '').replace(/[^a-z]/g, '');

const losers = [], apNotHeld = [], oursApOmits = [], spelling = [], aggregates = [], ambiguous = [];
const seats = [];

// A SEAT CAN HAVE TWO INCUMBENTS, AND AP PUBLISHES THEM AS A LIST. Redistricting pairs them:
// in 2026 AP gave FL-20 both Debbie Wasserman Schultz and Sheila Cherfilus-McCormick, and TX-37
// both Greg Casar and Lloyd Doggett. This capture spells one incumbent as an object and the
// federal capture spells several as an array; both are read, so the classifier ports to either
// without being rewritten, which is the point of putting it here.
const incumbentsOf = (race) => {
  const raw = race.ap_incumbent ?? race.incumbents ?? null;
  const list = raw == null ? [] : (Array.isArray(raw) ? raw : [raw]);
  return list.map((i) => ({
    candidate_id: i.candidate_id ?? i.apCandidateID ?? null,
    name: (i.name ?? `${i.first ?? ''} ${i.last ?? ''}`).trim(),
  })).filter((i) => i.candidate_id != null);
};
const lineName = (l) => (l.name ?? `${l.first ?? ''} ${l.last ?? ''}`).trim();
const lineId = (l) => l.candidate_id ?? l.apCandidateID ?? null;
const andList = (xs) => xs.length <= 1 ? (xs[0] ?? '')
  : `${xs.slice(0, -1).join(', ')} and ${xs[xs.length - 1]}`;
// A sanctioned claim is read by a voter, so it agrees with itself in number.
const plural = (xs, one, many) => (xs.length > 1 ? many : one);

// The three-branch test. It reads AP's ballot alone and never our rows, because the question is
// about AP's own two fields disagreeing — our table cannot adjudicate that.
const classifySeat = (race) => {
  const lines = race.all_lines ?? race.candidates ?? [];
  const incs = incumbentsOf(race);
  const base = { seat: race.seat, ap_race_id: race.ap_race_id ?? race.apRaceID,
                 our_race_id: race.our_race_id ?? null,
                 ap_incumbents: incs.map((i) => `${i.name} (id ${i.candidate_id})`) };

  const winners = lines.filter((l) => l.winner === true);
  if (winners.length !== 1) {
    return { ...base, seat_status: winners.length === 0 ? 'not_called' : 'multiple_winner_lines',
             winner: null, sanctioned_claim: null,
             why: `AP's ballot carries ${winners.length} winning lines; a seat cannot be classified.` };
  }
  const winner = winners[0];
  const whoWon = lineName(winner);
  const named = { ...base, winner: whoWon, winner_candidate_id: lineId(winner) };

  if (incs.length === 0) {
    return { ...named, seat_status: 'no_incumbent_published', sanctioned_claim: null,
             why: 'AP names no incumbent for this seat, so no claim about one can be made.' };
  }

  // Each incumbent is placed on the ballot by AP's CANDIDATE ID, never by name.
  const placed = incs.map((inc) => {
    const line = lines.find((l) => lineId(l) === inc.candidate_id) ?? null;
    if (line) {
      return { ...inc, on_ballot: true, outcome: line.winner === true ? 're_elected' : 'defeated',
               votes: line.votes ?? line.voteCount, pct: line.pct ?? line.votePct };
    }
    // Absent by id. An open-seat verdict is a claim that a name is NOT THERE, so the absence
    // gets a second detector that cannot fail the same way: does any line carry that name?
    const sameName = lines.filter((l) => fold(lineName(l)) === fold(inc.name));
    return { ...inc, on_ballot: false, outcome: sameName.length ? 'disputed' : 'not_on_ballot',
             name_also_on: sameName.map((l) => `${lineName(l)} (id ${lineId(l)})`) };
  });

  const disputed = placed.filter((p) => p.outcome === 'disputed');
  if (disputed.length) {
    return { ...named, seat_status: 'incumbency_disputed', incumbents: placed, sanctioned_claim: null,
             why: disputed.map((d) => `AP's incumbent id ${d.candidate_id} is on no line, but ` +
                  `${andList(d.name_also_on)} carries the name "${d.name}". Id and name disagree; ` +
                  `neither verdict is safe.`).join(' ') };
  }

  const reElected = placed.filter((p) => p.outcome === 're_elected');
  const defeated  = placed.filter((p) => p.outcome === 'defeated');
  const absent    = placed.filter((p) => p.outcome === 'not_on_ballot');
  const common    = { ...named, incumbents: placed };

  if (reElected.length && defeated.length) {
    return { ...common, seat_status: 'paired_incumbents',
             sanctioned_claim:
               `${plural(reElected, 'Incumbent', 'Incumbents')} ${andList(reElected.map((p) => p.name))} ` +
               `re-elected, defeating fellow ${plural(defeated, 'incumbent', 'incumbents')} ` +
               `${andList(defeated.map((p) => p.name))}.` };
  }
  if (reElected.length) {
    return { ...common, seat_status: 'incumbent_re_elected',
             sanctioned_claim: `${plural(reElected, 'Incumbent', 'Incumbents')} ` +
               `${andList(reElected.map((p) => p.name))} re-elected.` };
  }
  if (defeated.length) {
    return { ...common, seat_status: 'incumbent_defeated',
             sanctioned_claim: `${whoWon} defeated ${plural(defeated, 'incumbent', 'incumbents')} ` +
               `${andList(defeated.map((p) => p.name))}.` };
  }

  // 🔴 EVERY INCUMBENT IS ABSENT FROM THE BALLOT — WHICH IS NOT THE SAME CLAIM AS "OPEN SEAT",
  //    AND THE FIRST DRAFT OF THIS FILE SAID "OPEN SEAT" UNTIL THE 470-RACE RUN SHOWED WHY NOT.
  //    An incumbent is off the November ballot for four different reasons: retirement (ME-02's
  //    Jared Golden), a run for another office (NH-01's Chris Pappas, who won the Senate seat in
  //    the same capture), death, and A PRIMARY DEFEAT. The last one matters most here, because
  //    somebody DID beat that incumbent — just not in this election. What the ballot proves is
  //    only the absence, so that is all the claim says.
  return { ...common, seat_status: 'incumbent_not_on_ballot',
           sanctioned_claim:
             `${whoWon} defeated no incumbent in this election: ${race.seat}'s ` +
             `${plural(absent, 'incumbent', 'incumbents')}, ${andList(absent.map((p) => p.name))}, ` +
             `${plural(absent, 'was', 'were')} not on the ballot.`,
           claim_still_needs:
             'WHY the incumbent was off the ballot — retired, ran for another office, died, or ' +
             'lost a primary. AP does not publish it, these are four different facts about the ' +
             'same absence, and an incumbent beaten in a PRIMARY was still beaten by somebody. ' +
             'Source the reason before any citation states one, and never write "open seat" ' +
             'until you know which of the four it was.' };
};

for (const race of apRaces) {
  seats.push(classifySeat(race));
  if (SEATS_ONLY) continue;
  const mine = ours.filter((r) => r.race_id === race.our_race_id);
  const seen = new Set();

  for (const line of race.all_lines) {
    if (line.first === null || line.first === undefined) {
      aggregates.push({ seat: race.seat, last: line.last, votes: line.votes });
      continue;
    }
    if (line.winner) continue;

    const apFirst = fold(line.first), apLast = fold(line.last);
    let hit = mine.filter((r) => fold(r.first_name) === apFirst && fold(r.last_name) === apLast);
    let how = 'exact';
    if (hit.length === 0) {
      // Our last_name sometimes swallows a middle name ("Tessa" / "Lynn Hodge").
      hit = mine.filter((r) => fold(r.first_name) === apFirst && fold(r.last_name).endsWith(apLast));
      how = 'last_name ends with AP last, first names agree';
    }
    if (hit.length > 1) {
      ambiguous.push({ seat: race.seat, ap: `${line.first} ${line.last}`,
                       candidates: hit.map((r) => r.full_name) });
      continue;
    }
    if (hit.length === 0) {
      apNotHeld.push({ seat: race.seat, ap_candidate_id: line.candidate_id,
                       ap: `${line.first} ${line.last}`, party: line.party,
                       votes: line.votes, pct: line.pct,
                       named_write_in: /\(write-in\)/i.test(line.last) });
      continue;
    }
    const row = hit[0];
    seen.add(row.rc_id);
    if (fold(row.full_name) !== fold(`${line.first} ${line.last}`)) {
      spelling.push({ seat: race.seat, ap: `${line.first} ${line.last}`, ours: row.full_name, how });
    }
    losers.push({
      seat: race.seat, state: row.state, geo_id: row.geo_id,
      rc_id: row.rc_id, race_id: row.race_id, ap_race_id: race.ap_race_id,
      our_full_name: row.full_name, our_last_name: row.last_name,
      ap_first: line.first, ap_last: line.last, ap_candidate_id: line.candidate_id,
      party: line.party, votes: line.votes, pct: line.pct,
      named_write_in_on_ap_ballot: /\(write-in\)/i.test(line.last),
      matched_how: how,
      is_incumbent: row.is_incumbent, candidate_status: row.candidate_status,
      result_before: row.result, result_certainty_before: row.result_certainty,
      result_source_before: row.result_source, result_recorded_at_before: row.result_recorded_at,
    });
  }

  for (const row of mine) {
    if (row.result === 'won' || seen.has(row.rc_id)) continue;
    oursApOmits.push({ seat: race.seat, rc_id: row.rc_id, full_name: row.full_name,
                       candidate_status: row.candidate_status, is_write_in: row.is_write_in,
                       result: row.result, source: row.source });
  }
}

// 🔴 THE VERDICT IS CHECKED AGAINST A SYSTEM THAT IS NOT AP. `race_candidates.is_incumbent`
// means "incumbent OF THE SEAT THIS RACE IS FOR" (ruled 2026-11-04) and is reconciled against
// our own `office_terms` by `backend/scripts/reconcile-incumbency.mjs`. So it answers AP's
// question from the other side, and the two can be made to disagree. Checking a classifier
// against the file it classified would prove nothing; this does not.
const crossCheck = [];
if (!SEATS_ONLY) {
  for (const s of seats) {
    const flagged = ours.filter((r) => r.race_id === s.our_race_id && r.is_incumbent === true);
    const names = flagged.map((r) => r.full_name);
    const onBallot = (s.incumbents ?? []).filter((p) => p.on_ballot === true);
    let disagreement = null;
    if (onBallot.length === 0 && s.seat_status === 'incumbent_not_on_ballot' && flagged.length) {
      disagreement = `AP puts no incumbent on this ballot, but we flag ${names.join(', ')} as the ` +
                     `seat's incumbent. One of the two is wrong.`;
    } else if (onBallot.length) {
      const missing = onBallot.filter((p) => !names.some((n) => fold(n) === fold(p.name)));
      if (missing.length) {
        disagreement = `AP puts ${missing.map((p) => p.name).join(', ')} on this ballot as the ` +
                       `seat's incumbent; our rows flag ${names.join(', ') || 'nobody'}.`;
      }
    }
    crossCheck.push({ seat: s.seat, ap_says: s.seat_status, we_flag: names, disagreement });
  }
}
const disagreements = crossCheck.filter((c) => c.disagreement);

const counts = seats.reduce((a, s) => ({ ...a, [s.seat_status]: (a[s.seat_status] ?? 0) + 1 }), {});
const w = (n, o) => fs.writeFileSync(path.join(OUT_DIR, n), JSON.stringify(o, null, 2) + '\n');
if (OUT_DIR) {
  if (!SEATS_ONLY) {
    w('losers-2026-11-17.json', { generated_from: path.basename(AP_FILE), count: losers.length, losers });
    w('ap-lists-we-hold-no-row-for.json', { count: apNotHeld.length, candidates: apNotHeld });
    w('our-rows-ap-omits.json', { count: oursApOmits.length, rows: oursApOmits });
    w('spelling-review.json', { count: spelling.length, rows: spelling });
  }
  w('seat-incumbency-2026-11-17.json', {
    generated_from: path.basename(AP_FILE),
    rule: "AP's `incumbent` describes the SEAT, not a ballot line. The winner defeated the " +
          "incumbent only where the incumbent's AP candidate id sits on a LOSING line. Absent " +
          "from every line, the incumbent was NOT ON THE BALLOT — which is not yet 'open seat', " +
          "because a primary defeat looks identical here and somebody did beat them.",
    races_examined: seats.length,
    counts,
    cross_check_against_our_is_incumbent: SEATS_ONLY ? null : {
      checked: crossCheck.length, disagreements: disagreements.length, rows: crossCheck,
    },
    seats,
  });
}

if (!SEATS_ONLY) {
  console.log(`losers matched:                ${losers.length}`);
  console.log(`AP lines we hold no row for:   ${apNotHeld.length}`);
  console.log(`our rows AP's ballot omits:    ${oursApOmits.length}`);
  console.log(`spelling differences:          ${spelling.length}`);
  console.log(`ambiguous (refused):           ${ambiguous.length}`);
  console.log(`aggregate lines excluded:      ${aggregates.length} -> ${aggregates.map((a) => `${a.last} (${a.votes})`).join(', ') || '(none)'}`);
}

// Read the COUNT, not the verdict: a classifier that examined no races prints a clean sheet.
console.log(`\nseats classified:              ${seats.length} race(s) examined`);
console.log(Object.entries(counts).map(([k, v]) => `  ${String(v).padStart(4)}  ${k}`).join('\n')
            || '  (none)');
if (seats.length <= 40) {
  console.log('');
  for (const s of seats) {
    console.log(`  ${s.seat.padEnd(6)} ${s.seat_status.padEnd(23)} ${s.sanctioned_claim ?? '-- ' + s.why}`);
  }
}
const unsafe = seats.filter((s) => s.sanctioned_claim === null);
if (unsafe.length) {
  console.log(`\n🔴 ${unsafe.length} seat(s) carry NO sanctioned claim. Write nothing about an ` +
              `incumbent for: ${unsafe.map((s) => s.seat).join(', ')}`);
}

if (!SEATS_ONLY) {
  console.log(`\ncross-check vs our own is_incumbent: ${crossCheck.length} race(s) compared, ` +
              `${disagreements.length} disagreement(s)`);
  for (const d of disagreements) console.log(`  🔴 ${d.seat}: ${d.disagreement}`);
}
