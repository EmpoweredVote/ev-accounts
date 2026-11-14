#!/usr/bin/env node
// Apply A.R.S. § 9-821.01 to Pima County's published totals, and say who was elected when.
//
// THE RULE, QUOTED FROM azleg.gov/ars/9/00821-01.htm RATHER THAN SUMMARISED:
//
//   (D) "a city or town may by ordinance provide that at the primary election any candidate for the
//        office of mayor or city council who receives a majority of all votes cast at that election
//        for that office shall be declared elected to the office ... effective as of the date of the
//        general election, and a further election may not be held as to such candidate"
//
//   (F) "the majority of votes cast is determined by:
//        1. Calculating the total number of actual votes cast for all candidates for an office
//           whose names were LAWFULLY ON THE BALLOT for that office.
//        2. Dividing the sum ... by the number of seats to be filled for the office.
//        3. Dividing the number reached ... by two and rounding that number to the highest whole
//           number."
//
//   (G) "If more candidates receive a majority of votes cast than there are seats to be filled ...
//        the candidates who receive the highest number of votes equal to the number of seats ...
//        shall be declared elected"
//
//   (H) "If at the primary election no candidate receives the majority ... the number of candidates
//        who advance to the general or runoff election shall be equal in number to twice the number
//        of seats ... The candidates equal in number to the seats ... who receive the highest number
//        of votes at the general ... shall be declared elected"
//
// 🔴 WRITE-INS ARE OUT OF THE DENOMINATOR, AND THAT IS NOT A ROUNDING DETAIL. (F)(1) counts only
//    candidates "whose names were lawfully on the ballot", and a write-in's name is not. Marana's
//    aggregate write-in line alone is 4,680 votes; folding it in would move the threshold for every
//    candidate in the contest. Marana even had an OFFICIAL write-in candidate (Jackie Craig), who is
//    still not on the ballot.
//
// 🔴 THIS SCRIPT DOES NOT DECIDE WHETHER A CONTEST WAS ON A GIVEN BALLOT -- it is told. The ballot
//    question was settled from Pima County's two summary files (present in July, absent in
//    November) and from the Town of Marana's own published answer to "Will there be a General
//    Election?": "Maybe. A General Election will only be held if one or more Town races are not
//    decided at the Primary Election."
//
// ⚠ (D) SAYS "EFFECTIVE AS OF THE DATE OF THE GENERAL ELECTION", AND THAT IS A DIFFERENT FACT FROM
//    WHICH BALLOT CARRIED THE CONTEST. The contest was on the July ballot, so the race belongs to
//    the primary. The November effective date belongs to the term, not to the race.
import fs from 'node:fs';

const [primaryCsv, generalCsv, outPath] = process.argv.slice(2);
if (!primaryCsv || !generalCsv || !outPath) {
  console.error('usage: az-apply-9-821-01.mjs <pima-primary.csv> <pima-general.csv> <out.json>');
  process.exit(2);
}

function parseLine(t) {
  const row = []; let c = '', q = false;
  for (let i = 0; i < t.length; i++) {
    const ch = t[i];
    if (q) { if (ch === '"' && t[i + 1] === '"') { c += '"'; i++; } else if (ch === '"') q = false; else c += ch; }
    else if (ch === '"') q = true;
    else if (ch === ',') { row.push(c); c = ''; }
    else if (ch !== '\r') c += ch;
  }
  row.push(c); return row;
}

function readPima(path) {
  const lines = fs.readFileSync(path, 'utf8').split('\n').filter((l) => l.trim() !== '');
  const contests = parseLine(lines[0]);
  const cands = parseLine(lines[2]);
  const last = parseLine(lines[lines.length - 1]);
  if (!/COUNTY TOTALS/i.test(last[2] || '')) throw new Error(`${path}: last row is not COUNTY TOTALS`);
  const out = new Map();
  contests.forEach((name, i) => {
    if (!name) return;
    const who = (cands[i] || '').trim();
    if (!out.has(name)) out.set(name, { onBallot: [], writeIn: 0, over: 0, under: 0 });
    const v = Number((last[i] || '').replace(/,/g, '')) || 0;
    if (/^OVER VOTES$/i.test(who)) out.get(name).over = v;
    else if (/^UNDER VOTES$/i.test(who)) out.get(name).under = v;
    else if (/^write-?in$/i.test(who)) out.get(name).writeIn = v;
    else if (who) out.get(name).onBallot.push({ name: who, votes: v });
  });
  return out;
}

// (F): threshold from the on-ballot votes only.
function threshold(onBallot, seats) {
  const sum = onBallot.reduce((a, b) => a + b.votes, 0);          // (F)(1)
  const perSeat = sum / seats;                                     // (F)(2)
  return { sum, perSeat, majority: Math.ceil(perSeat / 2) };       // (F)(3) "rounding to the highest whole number"
}

const primary = readPima(primaryCsv);
const general = readPima(generalCsv);

// What we hold, and how many seats each carries, taken from production and stated here so the
// reader can see what the arithmetic was applied to.
const CONTESTS = [
  { ours: 'Marana Mayor',             seats: 1, primaryKey: 'Mayor - Town of Marana' },
  { ours: 'Marana Town Council',      seats: 4, primaryKey: 'Council Member - Town of Marana' },
  { ours: 'Oro Valley Mayor',         seats: 1, primaryKey: 'Mayor - Town of Oro Valley' },
  { ours: 'Oro Valley Town Council',  seats: 3, primaryKey: 'Council Member - Town of Oro Valley' },
  { ours: 'Sahuarita Town Council',   seats: 3, primaryKey: 'Council Member - Town of Sahuarita' },
  { ours: 'South Tucson City Council', seats: 3,
    primaryKey: 'Council Member - City of South Tucson City of South Tucson',
    generalKey: 'Council Member City of South Tucson' },
];

// 🔴🔴 A CONTEST IS NOT DECIDED ALL AT ONCE. The first version of this file assumed every seat in a
//    contest is filled at the same election, and it got South Tucson wrong: it put all three seats
//    at the general and declared Aguirre, Baca and Federico elected. In fact Roxanna Valenzuela
//    cleared the (F) majority at the PRIMARY and took one seat there, leaving TWO, so the general
//    elected only the top two and Federico came third.
//
// 🟢 THE FILE ITSELF CARRIES THE PROOF, AND IT IS A COUNT RATHER THAN A JUDGEMENT. (H) advances
//    "twice the number of seats to be filled". South Tucson's general lists FOUR candidates. Four is
//    twice two, not twice three. So the number of candidates on the general ballot states how many
//    seats were still open, independently of any threshold arithmetic -- and that is asserted below,
//    so this mistake cannot be made again quietly.
const report = [];
for (const c of CONTESTS) {
  const p = primary.get(c.primaryKey);
  if (!p) throw new Error(`the primary file has no contest "${c.primaryKey}"`);
  const inGeneral = c.generalKey ? general.has(c.generalKey) : false;
  const g = inGeneral ? general.get(c.generalKey) : null;

  const t = threshold(p.onBallot, c.seats);                              // (F), on the FULL seat count
  const pRanked = [...p.onBallot].sort((a, b) => b.votes - a.votes);
  const cleared = pRanked.filter((x) => x.votes >= t.majority);
  const seatedAtPrimary = cleared.slice(0, c.seats);                     // (D) + (G)
  const remaining = c.seats - seatedAtPrimary.length;

  // ⚠ "DID NOT WIN" IS NOT "ADVANCED". Under (H) only twice the number of open seats goes forward,
  //   so in South Tucson four of the seven who missed the majority advanced and three did not. The
  //   first version of this file called all seven "advanced", which would have told a reader that
  //   Zeke Cook, Diana Moreno-Sears and Christopher Dodson were on a November ballot they were never
  //   on. Advancing is read from the general ballot itself, not inferred from losing.
  // ⚠ THERE ARE THREE WAYS TO NOT WIN A PRIMARY HERE, AND THEY ARE DIFFERENT CLAIMS. If the contest
  //   was settled outright in July, a non-winner simply LOST. If seats were left open, (H) sends
  //   twice that many forward: those are ADVANCED, and the rest are NOT_NOMINATED. A first pass
  //   called all seven South Tucson non-winners "advanced", putting three people on a ballot they
  //   were never on; a second pass over-corrected and called the eight losers of the five settled
  //   contests "not_nominated", which asserts a runoff that never existed.
  const advancedNames = new Set((g?.onBallot || []).map((x) => x.name));
  const rows = [];
  for (const x of pRanked) {
    const won = seatedAtPrimary.includes(x);
    let result;
    if (won) result = 'won';
    else if (remaining === 0) result = 'lost';                 // nothing went forward: the contest ended here
    else result = advancedNames.has(x.name) ? 'advanced' : 'not_nominated';
    rows.push({ name: x.name, votes: x.votes, election: 'primary 2026-07-21', result });
  }

  if (remaining === 0) {
    if (inGeneral) throw new Error(`${c.ours}: every seat was filled at the primary, yet the contest is also on the general ballot`);
  } else {
    if (!inGeneral) throw new Error(`${c.ours}: ${remaining} seat(s) were left open at the primary and the contest is absent from the general ballot`);
    const expectAdvancing = remaining * 2;                               // (H)
    if (g.onBallot.length !== expectAdvancing) {
      throw new Error(`${c.ours}: ${g.onBallot.length} candidates are on the general ballot but (H) advances twice the ${remaining} open seat(s), which is ${expectAdvancing}. The seat arithmetic and the ballot disagree -- stop.`);
    }
    const gRanked = [...g.onBallot].sort((a, b) => b.votes - a.votes);
    const electedAtGeneral = gRanked.slice(0, remaining);
    for (const x of gRanked) {
      rows.push({ name: x.name, votes: x.votes, election: 'general 2026-11-03',
        result: electedAtGeneral.includes(x) ? 'won' : 'lost' });
    }
    report.push({
      contest: c.ours, seats: c.seats, threshold: t,
      seatsFilledAtPrimary: seatedAtPrimary.map((x) => x.name),
      seatsLeftForGeneral: remaining,
      advancingCount: g.onBallot.length, advancingExpected: expectAdvancing,
      electedAtGeneral: electedAtGeneral.map((x) => x.name),
      marginLastInToFirstOut: gRanked.length > remaining ? gRanked[remaining - 1].votes - gRanked[remaining].votes : null,
      rows, writeIn: { primary: p.writeIn, general: g.writeIn },
      note: `${cleared.length} of ${p.onBallot.length} cleared the (F) majority of ${t.majority} at the primary and ${seatedAtPrimary.length} seat(s) were taken there; ${remaining} went to the general, where (H) put ${expectAdvancing} candidates on the ballot.`,
    });
    continue;
  }

  report.push({
    contest: c.ours, seats: c.seats, threshold: t,
    seatsFilledAtPrimary: seatedAtPrimary.map((x) => x.name),
    seatsLeftForGeneral: 0, advancingCount: 0, advancingExpected: 0,
    electedAtGeneral: [], marginLastInToFirstOut: null,
    rows, writeIn: { primary: p.writeIn, general: null },
    note: `${cleared.length} of ${p.onBallot.length} candidates cleared the (F) majority of ${t.majority}; (G) seats the top ${c.seats}, and no general contest was held.`,
  });
}

fs.writeFileSync(outPath, `${JSON.stringify({ generated: new Date().toISOString(), statute: 'A.R.S. 9-821.01', contests: report }, null, 2)}\n`);
for (const r of report) {
  console.log(`\n${r.contest}  — ${r.seats} seat(s)`);
  console.log(`   (F) on-ballot votes ${r.threshold.sum}, ÷${r.seats} = ${r.threshold.perSeat.toFixed(2)}, ÷2 rounded up = majority ${r.threshold.majority}`);
  for (const v of r.rows) {
    console.log(`      ${v.election === 'primary 2026-07-21' ? 'JUL' : 'NOV'} ${String(v.votes).padStart(6)}  ${v.result.toUpperCase().padEnd(8)}  ${v.name}`);
  }
  console.log(`      write-in lines: primary ${r.writeIn.primary}${r.writeIn.general != null ? `, general ${r.writeIn.general}` : ''} (excluded from the (F) denominator)`);
  if (r.seatsLeftForGeneral) console.log(`      🟢 ${r.advancingCount} on the general ballot = twice the ${r.seatsLeftForGeneral} open seat(s), as (H) requires`);
  if (r.marginLastInToFirstOut != null) console.log(`      margin, last elected to first not elected: ${r.marginLastInToFirstOut}`);
  console.log(`   ${r.note}`);
}
console.log(`\nwrote ${outPath}`);
