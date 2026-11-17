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
// Both inputs are committed files, so this runs with no database and no dependencies:
//
//   node match-losers.mjs --ap ap-ballots-2026-11-17.json --ours before-values.json --out .
//
// --ap and --ours each let a control hand the matcher tampered input and watch the output move.

import fs from 'node:fs';
import path from 'node:path';

const argv = process.argv.slice(2);
const arg = (k) => { const i = argv.indexOf(k); return i === -1 ? undefined : argv[i + 1]; };
const AP_FILE = arg('--ap'), OURS_FILE = arg('--ours'), OUT_DIR = arg('--out');
if (!AP_FILE || !OURS_FILE || !OUT_DIR) {
  console.error('usage: --ap <ap-ballots.json> --ours <before-values.json> --out <dir>');
  process.exit(2);
}

const ap = JSON.parse(fs.readFileSync(AP_FILE, 'utf8'));
const ours = JSON.parse(fs.readFileSync(OURS_FILE, 'utf8')).rows;

// Folded only for COMPARISON. A folded string is never written to the database.
const fold = (s) => (s ?? '')
  .normalize('NFD').replace(/[̀-ͯ]/g, '')
  .toLowerCase().replace(/\(write-in\)/g, '').replace(/[^a-z]/g, '');

const losers = [], apNotHeld = [], oursApOmits = [], spelling = [], aggregates = [], ambiguous = [];

for (const race of ap.races) {
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

const w = (n, o) => fs.writeFileSync(path.join(OUT_DIR, n), JSON.stringify(o, null, 2) + '\n');
w('losers-2026-11-17.json', { generated_from: path.basename(AP_FILE), count: losers.length, losers });
w('ap-lists-we-hold-no-row-for.json', { count: apNotHeld.length, candidates: apNotHeld });
w('our-rows-ap-omits.json', { count: oursApOmits.length, rows: oursApOmits });
w('spelling-review.json', { count: spelling.length, rows: spelling });

console.log(`losers matched:                ${losers.length}`);
console.log(`AP lines we hold no row for:   ${apNotHeld.length}`);
console.log(`our rows AP's ballot omits:    ${oursApOmits.length}`);
console.log(`spelling differences:          ${spelling.length}`);
console.log(`ambiguous (refused):           ${ambiguous.length}`);
console.log(`aggregate lines excluded:      ${aggregates.length} -> ${aggregates.map((a) => `${a.last} (${a.votes})`).join(', ') || '(none)'}`);
