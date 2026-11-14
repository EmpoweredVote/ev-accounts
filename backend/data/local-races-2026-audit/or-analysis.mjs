#!/usr/bin/env node
// Turn Oregon's county exports into the ballot for each of our 2026-11-03 local races, and say
// which of them can honestly carry a result.
//
// SOURCES (committed under ./sources, pulled 2026-11-13 by fetch-or-county-export.mjs):
//   or-multnomah-export-2026-11-13.csv, or-washington-export-2026-11-13.csv
// and, for the ranked-choice contests only, Multnomah County's own published calls at
// rcvresults.multco.us, quoted in RCV_CALLS below.
//
// 🔴 OREGON PUBLISHES NO WINNER FLAG AND NO OUTSTANDING-BALLOT COUNT, so most of these contests
//    cannot be called by us at all. The rule here, stated once:
//
//    FORCED      -- the ballot carried no more candidates than there were seats. Everyone on it
//                   wins whatever else is counted, so the outcome does not depend on a bound.
//    RCV-CALLED  -- Multnomah County's ranked-choice reports NAME the winners. That is the
//                   publisher's call, not our arithmetic.
//    UNCALLED    -- contested, and nobody has called it. The ballot is recorded and the outcome is
//                   NOT. ▶ Oregon's counties certify within 20 days; the Secretary of State's own
//                   results page still reads UNOFFICIAL.
//
// 🔴 `PrecinctsReporting` IN THESE FILES READS "0/N" FOR EVERY CONTEST, IN A FILE FULL OF VOTES.
//    Oregon counts vote-by-mail ballots in batches, not by precinct, so the field that looks like
//    the completeness measure is simply unpopulated. It is not read here. A margin is not a bound,
//    and a field that says nothing is not a bound either.
//
// 🔴 EVERY RANKED-CHOICE CONTEST IN THE EXPORT CARRIES ZERO VOTES FOR EVERY CANDIDATE, because the
//    counts live at rcvresults.multco.us. Those zeros are never written anywhere -- the same trap
//    as AP reporting zero votes for an uncontested race, which reached production as prose once.
//
// ⚠ WOOD VILLAGE IS DELIBERATELY ABSENT. Its ballot has "Councilor, Position 1" and "Position 4";
//   we hold "Seat 1" and "Seat 2", and our Seat 2's holder, Charlene Gothard, is on the ballot for
//   the city's Position 1 -- so the two numbering schemes are not the same scheme. Worse, our Seat
//   1's holder John Miner was made MAYOR by the council in January 2023, which is the rotating-chair
//   shape that eats a council seat. Two rows, two unknowns, and no mapping that is not a guess.
import fs from 'node:fs';

const [outPath] = process.argv.slice(2);
if (!outPath) { console.error('usage: or-analysis.mjs <out.json>'); process.exit(2); }
const HERE = new URL('.', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');

function parse(text) {
  const rows = []; let row = [], cell = '', q = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (q) { if (c === '"' && text[i + 1] === '"') { cell += '"'; i++; } else if (c === '"') q = false; else cell += c; }
    else if (c === '"') q = true;
    else if (c === ',') { row.push(cell); cell = ''; }
    else if (c === '\n') { row.push(cell); rows.push(row); row = []; cell = ''; }
    else if (c !== '\r') cell += c;
  }
  if (cell || row.length) { row.push(cell); rows.push(row); }
  return rows.filter((r) => r.some((x) => x !== ''));
}

// Read every county file into one contest map.
//
// 🔴🔴 A COUNTY EXPORT CARRIES THAT COUNTY'S SUBTOTAL, NOT THE CONTEST'S TOTAL, AND A CONTEST CAN
//    STRADDLE A COUNTY LINE. The first version of this reader assumed the files would agree and
//    asserted it; the assertion fired at once on US Senator, where Jeff Merkley reads 301,848 in
//    Multnomah and 176,244 in Washington. Those are two parts of one number. Had the reader instead
//    taken "the first file wins", every Portland-wide contest would have been silently understated
//    by the share of the city that lives in Washington and Clackamas counties.
//    ▶ Anchor on the candidate and SUM. Each file is read exactly once, so a sum cannot double.
const contests = new Map();
for (const f of ['or-multnomah-export-2026-11-13.csv', 'or-washington-export-2026-11-13.csv']) {
  const rows = parse(fs.readFileSync(`${HERE}sources/${f}`, 'utf8'));
  const h = rows[0].map((s) => s.trim());
  const ix = Object.fromEntries(h.map((x, i) => [x, i]));
  for (const r of rows.slice(1)) {
    const name = (r[ix.ContestName] || '').replace(/ - view results at.*$/, '').trim();
    const id = String(r[ix.CandidateID]).trim();
    if (!contests.has(name)) contests.set(name, { voteFor: Number(r[ix.VoteFor]), cands: new Map(), writeIn: 0 });
    const c = contests.get(name);
    // 🔴 Candidate id 9901 is "Write-in", an aggregate line and not a person. It is dropped by ID,
    //    never by reading the name -- but it is KEPT as a number, because a contest is only
    //    uncontested if the write-in line cannot beat the lowest winner.
    if (id === '9901') { c.writeIn += Number(String(r[ix.CandidateVotes]).replace(/,/g, '')) || 0; continue; }
    // ⚠ A nickname in parentheses is an annotation, not part of the name. The parentheses MUST be
    //   escaped; written /([^)]*)/g this matches the empty string everywhere and erases every name.
    const who = String(r[ix.CandidateName]).replace(/\([^)]*\)/g, ' ').replace(/\s+/g, ' ').trim();
    const votes = Number(String(r[ix.CandidateVotes]).replace(/,/g, '')) || 0;
    if (!c.cands.has(id)) c.cands.set(id, { id, who, votes: 0, counties: 0 });
    const entry = c.cands.get(id);
    if (entry.who !== who) throw new Error(`${name}: candidate id ${id} is "${entry.who}" in one county file and "${who}" in another`);
    entry.votes += votes;
    entry.counties += 1;
  }
}

// Multnomah County's own words, from its ranked-choice reports. These are the publisher's calls.
const RCV_CALLS = {
  'City of Portland, Councilor, District 3': { seats: 3, won: ['Steve Novick', 'Angelita Morillo', 'Tiffany Koyama Lane'],
    quote: '"3 Seats Up for Election ... Steve Novick, Angelita Morillo and Tiffany Koyama Lane reached the threshold of 21,045 votes and are leading"' },
  'City of Portland, Councilor, District 4': { seats: 3, won: ['Mitch Green', 'Olivia Clark'], partial: true,
    quote: '"3 Seats Up for Election ... Mitch Green and Olivia Clark reached the threshold of 18,686 votes and are leading" -- only two of the three named' },
  'Multnomah County Commission, Chair': { seats: 1, won: ['Shannon Singleton'],
    quote: '"Shannon Singleton reached the threshold of 155,641 votes and is leading"' },
  'Multnomah County Commissioner, District 2': { seats: 1, won: ['Bri Williams'],
    quote: '"Bri Williams reached the threshold of 43,295 votes and is leading"' },
  'City of Portland, Auditor': { seats: 1, won: ['Simone Rede'],
    quote: '"Simone Rede reached the threshold of 97,264 votes and is leading"' },
};

// Our race rows, as production holds them after CC_0422, mapped to the contest that filled them.
// The mapping is written out rather than matched, because the names differ in every city.
const MAP = [
  ['e7f7ee0d-6806-4919-b5fa-a7ead87ca40f', 'Fairview City Council Position 4', 'City of Fairview, Councilor, Position 4', 1],
  ['cba78b59-0450-46e3-8e76-90f7c82d5878', 'Fairview City Council Position 5', 'City of Fairview, Councilor, Position 5', 1],
  ['439d4367-b45e-42bd-b289-270c942d34ea', 'Fairview City Council Position 6', 'City of Fairview, Councilor, Position 6', 1],
  ['ebcee8b9-4ff2-48c7-afcd-f035e1c9031c', 'Fairview Mayor', 'City of Fairview, Mayor', 1],
  ['ad814d48-ec19-471a-801f-6e36c40641f6', 'Gresham City Council Position 2', 'City of Gresham, Councilor, Position 2', 1],
  ['6776e801-e2fa-48f6-820a-7e018dd46857', 'Gresham City Council Position 4', 'City of Gresham, Councilor, Position 4', 1],
  ['9675ce05-4ccb-48aa-9482-d5fdffeba962', 'Gresham City Council Position 6', 'City of Gresham, Councilor, Position 6', 1],
  ['2fa94afa-14c7-4eca-a6ab-42c4fa979f0f', 'Gresham Mayor', 'City of Gresham, Mayor', 1],
  ['8d577858-74d8-405c-a47b-e667fdd95c18', 'Hillsboro City Council Ward 1 Position A', 'City of Hillsboro, Council Member, Ward 1, Position A', 1],
  ['59f7ba66-a8e0-4954-a0aa-0a5fabb12846', 'Hillsboro City Council Ward 2 Position A', 'City of Hillsboro, Council Member, Ward 2, Position A', 1],
  ['3079029f-bbe1-457e-ba27-27616478638f', 'Hillsboro City Council Ward 3 Position A', 'City of Hillsboro, Council Member, Ward 3, Position A', 1],
  ['ca38e3d3-7fa1-4a09-a702-1a0fefd03173', 'Tualatin City Council Position 1', 'City of Tualatin, Council Member, Position 1', 1],
  ['676f746b-b01a-41b1-9224-78aea0b2df20', 'Tualatin City Council Position 3', 'City of Tualatin, Council Member, Position 3', 1],
  ['bde1e616-a61e-46e2-94ce-3b87b1ab34f1', 'Forest Grove Mayor', 'City of Forest Grove, Mayor', 1],
  ['65128ac1-4908-4e18-8c43-7ccc92b44f43', 'Sherwood Mayor', 'City of Sherwood, Mayor', 1],
  ['83472b5e-a161-4833-a7c0-c3ff82fe1893', 'Tigard Mayor', 'City of Tigard, Mayor', 1],
  ['17d6cce5-ddac-4127-8d8d-03ddcd2ed9ef', 'Forest Grove City Council', 'City of Forest Grove, Council Members (Vote For 3)', 3],
  ['2b0e2732-ac82-4815-9ced-ea62980280f7', 'Sherwood City Council', 'City of Sherwood, Council Members (Vote For 3)', 3],
  ['115c8ccb-aa65-4b7d-b323-3d86e8efbd93', 'Tigard City Council', 'City of Tigard, Council Members (Vote For 3)', 3],
  ['96757017-1342-445c-bd96-61001665be56', 'Maywood Park City Council', 'City of Maywood Park, Councilor (Vote For 3)', 3],
  ['0da8e1fd-cb33-4987-a5b1-519f5dbd76db', 'Troutdale City Council', 'City of Troutdale, Councilor (Vote For 3)', 3],
  ['26cf6ba1-0e5a-44bf-8f1e-96c804b206ab', 'Portland City Auditor', 'City of Portland, Auditor', 1],
  ['ff402093-3aad-4d15-8440-11daf360a7e9', 'Portland City Council District 3', 'City of Portland, Councilor, District 3', 3],
  ['df1d7c03-3ee0-46c2-9e03-1a5b04629fe0', 'Portland City Council District 4', 'City of Portland, Councilor, District 4', 3],
  ['826ee33d-51d8-4c6a-af55-50d8417934e5', 'Multnomah County Chair', 'Multnomah County Commission, Chair', 1],
  ['e1e20a92-e125-46a5-a0ad-69756c81b3d7', 'Multnomah County Commissioner District 2', 'Multnomah County Commissioner, District 2', 1],
];

// The people our roster currently seats in each of these bodies, read from production on
// 2026-11-14. For a multi-seat contest every sitting member of the body is an incumbent on that
// ballot, so all of them are listed.
const HOLDERS = {
  'Fairview City Council Position 4': ['Jenni Weber'],
  'Fairview City Council Position 5': ['Steve Owen'],
  'Fairview City Council Position 6': ['Paul Copeland'],
  'Fairview Mayor': ['Keith Kudrna'],
  'Gresham City Council Position 2': ['Eddy Morales'],
  'Gresham City Council Position 4': ['Jerry Hinton'],
  'Gresham City Council Position 6': ['Janine Gladfelter'],
  'Gresham Mayor': ['Travis Stovall'],
  'Hillsboro City Council Ward 1 Position A': ['Cristian Salgado'],
  'Hillsboro City Council Ward 2 Position A': ['Kipperlyn Sinclair'],
  'Hillsboro City Council Ward 3 Position A': ['Olivia Alcaire'],
  'Tualatin City Council Position 1': ['María Reyes'],
  'Tualatin City Council Position 3': ['Bridget Brooks'],
  'Forest Grove Mayor': ['Malynda Wenzl'],
  'Sherwood Mayor': ['Tim Rosener'],
  'Tigard Mayor': ['Yi-Kang Hu'],
  'Forest Grove City Council': ['Angel Falconer', 'Brian Schimmel', 'Donna Gustafson', 'Karen Martinez', 'Mariana Valenzuela', 'Michael Marshall'],
  'Sherwood City Council': ['Dan Standke', 'Doug Scott', 'Keith Mays', 'Kim Young', 'Renee Brouse', 'Taylor Giles'],
  'Tigard City Council': ['Faraz Ghoddusi', 'Heather Robbins', 'Jake Schlack', 'Jeanette Shaw', 'Maureen Wolf', 'Tom Anderson'],
  'Maywood Park City Council': ['Jeff Baltzell', 'Miriam Berman', 'Thomas Welander'],
  'Troutdale City Council': ['Carol Allen', 'Geoffrey Wunn', 'Glenn White', 'Jesse Davidson', 'John Leamy', 'Zach Andrews'],
  'Portland City Auditor': ['Simone Rede'],
  'Portland City Council District 3': ['Angelita Morillo', 'Steve Novick', 'Tiffany Koyama Lane'],
  'Portland City Council District 4': ['Eric Zimmerman', 'Mitch Green', 'Olivia Clark'],
  'Multnomah County Chair': ['Jessica Vega Pederson'],
  'Multnomah County Commissioner District 2': ['Shannon Singleton'],
};

// ⚠ `unaccent` IS NOT INSTALLED ON PROD, so accents are folded here rather than in SQL. Tualatin's
//   holder is "María Reyes" and the ballot prints "Maria Antonieta Reyes": an accent AND a middle
//   name, so an exact comparison would have called a sitting councillor a challenger.
const fold = (s) => s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z ]/g, ' ').replace(/\s+/g, ' ').trim();
const firstLast = (s) => { const p = fold(s).split(' '); return p.length < 2 ? fold(s) : `${p[0]} ${p[p.length - 1]}`; };

// A named ladder, so a loose match is visible as a loose match rather than hiding inside a boolean.
function incumbencyOf(candidate, holders) {
  for (const h of holders) if (fold(h) === fold(candidate)) return { incumbent: true, basis: 'exact-full-name' };
  for (const h of holders) if (firstLast(h) === firstLast(candidate)) return { incumbent: true, basis: 'first-and-last-only' };
  return { incumbent: false, basis: null };
}

const out = [];
for (const [raceId, ours, key, seats] of MAP) {
  const c = contests.get(key);
  if (!c) throw new Error(`the county exports have no contest named ${JSON.stringify(key)}`);
  const cands = [...c.cands.values()].sort((a, b) => b.votes - a.votes);
  const rcv = RCV_CALLS[key];

  let basis, rows;
  if (rcv) {
    // 🔴 The export's VoteFor is 1 for these and the county says 3. The county's own report wins,
    //    and no vote figure from the export is used at all.
    basis = 'rcv-called';
    const wonSet = new Set(rcv.won);
    for (const n of rcv.won) {
      if (!cands.some((x) => x.who === n)) throw new Error(`${key}: the county names ${n} as winning, but that name is not on the export's ballot`);
    }
    rows = cands.map((x) => ({ ...x, votes: null,
      result: wonSet.has(x.who) ? 'won' : (rcv.partial ? null : 'lost') }));
  } else if (cands.length <= seats && c.writeIn < cands[cands.length - 1].votes) {
    // 🔴 "FEWER CANDIDATES THAN SEATS" IS NOT ENOUGH ON ITS OWN. Oregon prints an aggregate
    //    write-in line, and a write-in can win an Oregon local race -- Maine's House 24 was decided
    //    by a declared write-in in the legislative wave. So a contest counts as forced only if the
    //    WHOLE write-in line, treated as if it were one person, still loses to the lowest named
    //    winner. That is the most favourable possible reading for a write-in, and it is the right
    //    bar: the line is an aggregate, so no individual write-in can exceed it.
    basis = 'forced';
    rows = cands.map((x) => ({ ...x, result: 'won' }));
  } else {
    basis = 'uncalled';
    rows = cands.map((x) => ({ ...x, result: null }));
  }

  const holders = HOLDERS[ours];
  if (!holders) throw new Error(`no sitting-member list for ${ours}`);
  rows = rows.map((x) => { const inc = incumbencyOf(x.who, holders); return { ...x, ...inc }; });

  out.push({ raceId, ours, contest: key, seats, basis,
    sittingMembers: holders,
    incumbentsOnBallot: rows.filter((x) => x.incumbent).map((x) => `${x.who} (${x.basis})`),
    exportVoteFor: c.voteFor,
    margin: (!rcv && cands.length > seats) ? cands[seats - 1].votes - cands[seats].votes : null,
    quote: rcv?.quote || null,
    writeInLine: c.writeIn,
    candidates: rows });
}

const tally = out.reduce((a, x) => { a[x.basis] = (a[x.basis] || 0) + 1; return a; }, {});
fs.writeFileSync(outPath, `${JSON.stringify({ generated: new Date().toISOString(), basisCounts: tally, contests: out }, null, 2)}\n`);
for (const r of out) {
  const won = r.candidates.filter((x) => x.result === 'won').length;
  const none = r.candidates.filter((x) => x.result === null).length;
  console.log(`${r.basis.padEnd(11)} ${String(r.seats)}st ${r.ours.padEnd(42)} ${String(r.candidates.length).padStart(2)} cands, ${won} won, ${none} no result${r.margin != null ? `, margin ${r.margin}` : ''}`);
}
console.log(`\n${JSON.stringify(tally)}  —  ${out.reduce((a, x) => a + x.candidates.length, 0)} candidacies across ${out.length} races`);
console.log(`wrote ${outPath}`);
