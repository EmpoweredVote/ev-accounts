#!/usr/bin/env node
// Join the two counties' raw extracts to our 19 races, and decide which contests can be
// CALLED from a semi-official count.
//
// 🔴 NEITHER COUNTY PUBLISHES A WINNER FLAG. AP does, and every federal and state-executive
//   pass in this programme leaned on it. Here the call is OURS, so it is made by arithmetic
//   and nothing else: a contest is callable only when the trailing candidate could not
//   overtake the leader EVEN IF EVERY BALLOT STILL UNCOUNTED IN THAT CONTEST BROKE THEIR WAY
//   and the leader gained none. That is a bound, not a projection about how late ballots lean.
//
// 🔴 THE PER-CONTEST OUTSTANDING FIGURE DOES NOT EXIST. Only a countywide one is published.
//   It is apportioned here by the contest's own share of ballots cast, and then multiplied by
//   SAFETY, because outstanding ballots are not spread evenly across a county: SAFETY=3
//   tolerates a district holding three times its proportional share of what is left.
//
// 🔴 EACH RACE IS ANCHORED ON ITS CANDIDATE SET, NOT ON ITS TITLE. A title match is a guess
//   about what a name means; the set of people on the ballot is a fact. The title is then
//   checked against the district name afterwards, as an independent second reading.
import fs from 'node:fs';
import path from 'node:path';

const dir = process.argv[2] || '.';
const stamp = process.argv[3] || '2026-11-08';
const SAFETY = Number(process.env.SAFETY || 3);

// LA RR/CC, lavote.gov "Post-Election Night Ballot Count Update", read 2026-11-08:
// 3,041,114 ballots counted (51.47% turnout); preliminary estimate of outstanding ballots
// 131,000 = 94,000 vote-by-mail + 32,000 conditional-registration + 5,000 provisional.
const LA_COUNTED = 3041114;
const LA_OUTSTANDING = 131000;

const norm = (s) => (s || '').normalize('NFD').replace(/[̀-ͯ]/g, '')
  .toUpperCase().replace(/["'.,]/g, '').replace(/\s+/g, ' ').trim();

// 🔴 THE SERVER-RENDERED PAGES WRITE ACCENTS AS NUMERIC ENTITIES — "LA CA&#xD1;ADA",
//   "ERIK PE&#xD1;A". Leaving them encoded made three candidates in two contests come back
//   "absent from the text-results page", which reads exactly like a real disagreement between
//   two sources. It was my own parser. ▶ Decode before you compare, and never report a
//   mismatch a normalisation step could have produced.
const unent = (s) => s
  .replace(/&#x([0-9a-f]+);/gi, (_, h) => String.fromCodePoint(parseInt(h, 16)))
  .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(Number(d)))
  .replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&')
  .replace(/&#39;/g, "'").replace(/&rsquo;/g, "'").replace(/&quot;/g, '"');

// ── LA: the ballot (GetElectionData) joined to the counts (GetCounterData) ──
const ed = JSON.parse(fs.readFileSync(path.join(dir, `la-election-data-${stamp}.json`), 'utf8'));
const cd = JSON.parse(fs.readFileSync(path.join(dir, `la-counter-data-${stamp}.json`), 'utf8'));
const votes = new Map();
const ctr = new Map();
for (const r of cd.Data) {
  if (r.ReferenceType === 'CAND') votes.set(r.ReferenceID, r.Value);
  else {
    if (!ctr.has(r.ReferenceID)) ctr.set(r.ReferenceID, {});
    ctr.get(r.ReferenceID)[r.ReferenceType] = r.Value;
  }
}
const laContests = ed.Data.ContestGroups.flatMap((g) => g.Contests.map((c) => ({
  county: 'Los Angeles',
  group: g.Name,
  id: String(c.ID),
  title: c.Title,
  voteFor: c.VoteFor,
  note: c.AdditionalText || '',
  ballots: (ctr.get(c.ID) || {}).CBLT ?? null,
  candidates: (c.Candidates || []).map((k) => ({ name: k.Name, votes: votes.get(k.ID) ?? null })),
})));
// 🔴 GetElectionData alone is all zeros. If the join failed we would report a complete
//    election in which nobody got a vote, so prove the join carries numbers before using it.
const laTotal = laContests.flatMap((c) => c.candidates).reduce((a, b) => a + (b.votes || 0), 0);
if (laTotal < 1e6) throw new Error(`the LA join produced only ${laTotal} votes in all — GetCounterData did not attach`);

// ── LA second reading: the server-rendered text-results page, parsed independently ──
const txt = fs.readFileSync(path.join(dir, `la-text-results-${stamp}.html`), 'utf8');
const plain = unent(txt.replace(/<[^>]+>/g, '\n')).split('\n').map((s) => s.trim()).filter(Boolean);
const titleSet = new Set(laContests.map((c) => norm(c.title)));
const textVotes = new Map(); // "contest :: candidate" (both normalised) -> votes
{
  let contest = null;
  for (let i = 0; i < plain.length; i++) {
    const line = plain[i];
    if (titleSet.has(norm(line))) { contest = norm(line); continue; }
    const m = /^(.*?)\s*\(([A-Z]{1,3})\)$/.exec(line);
    if (contest && m && /^[\d,]+$/.test(plain[i + 1] || '')) {
      textVotes.set(`${contest} :: ${norm(m[1])}`, Number(plain[i + 1].replace(/,/g, '')));
    }
  }
}
if (textVotes.size < 500) throw new Error(`the text-results second reading found only ${textVotes.size} candidate lines`);
// 🔴 A POSITIVE CONTROL BEFORE ANY "ABSENT FROM THE TEXT PAGE" IS BELIEVED. These two carry
//   an Ñ written as a numeric entity, which is precisely what the decoder above exists for;
//   without it they came back absent and that read as a source disagreement.
for (const probe of ['LA CAÑADA IRRIGATION DISTRICT MEMBER BOARD OF DIRECTORS DIVISION 4 :: HELEN GRACE AVILA OLIVARES',
  'VALLEY COUNTY WATER DISTRICT MEMBER BOARD OF DIRECTORS :: ERIK PEÑA']) {
  if (!textVotes.has(norm(probe.split(' :: ')[0]) + ' :: ' + norm(probe.split(' :: ')[1]))) {
    throw new Error(`the text-results index cannot see a line known to exist (${probe}) — every "absent" below would be vacuous`);
  }
}

// ── San Bernardino: one server-rendered page ──
const sbHtml = fs.readFileSync(path.join(dir, `sb-results-${stamp}.html`), 'utf8');
const sbPlain = unent(sbHtml.replace(/<[^>]+>/g, '\n')).split('\n').map((s) => s.trim()).filter(Boolean);
const sbContests = [];
for (let i = 0; i < sbPlain.length; i++) {
  const m = /^(.*?)\s*\(Vote for\s+(\d+)\)$/.exec(sbPlain[i]);
  if (!m) continue;
  const c = {
    county: 'San Bernardino', group: 'San Bernardino', id: `SB:${norm(m[1])}`, title: m[1],
    voteFor: `Vote for no more than ${['', 'one', 'two', 'three', 'four', 'five'][Number(m[2])] || m[2]}`,
    note: '', ballots: null, registered: null, candidates: [],
  };
  for (let j = i + 1; j < sbPlain.length && j < i + 120; j++) {
    const cast = /^([\d,]+)\s*\/\s*([\d,]+)$/.exec(sbPlain[j]);
    if (cast && c.ballots === null) {
      c.ballots = Number(cast[1].replace(/,/g, ''));
      c.registered = Number(cast[2].replace(/,/g, ''));
    }
    if (/^Total Votes$/i.test(sbPlain[j])) break;
    if (/^[A-ZÀ-Þ][A-Za-zÀ-ÿ'".\- ]+$/.test(sbPlain[j])
      && /^[\d,]+$/.test(sbPlain[j + 1] || '') && /^[\d.]+%$/.test(sbPlain[j + 2] || '')) {
      c.candidates.push({ name: sbPlain[j], votes: Number(sbPlain[j + 1].replace(/,/g, '')) });
    }
  }
  if (c.candidates.length) sbContests.push(c);
}
if (sbContests.length < 10) throw new Error(`the San Bernardino parser found only ${sbContests.length} contests`);

const allContests = [...laContests, ...sbContests];

// ── anchor each of our races on its candidate set ──
const ours = JSON.parse(fs.readFileSync(path.join(dir, `our-candidacies-${stamp}.json`), 'utf8'));
const byRace = new Map();
for (const r of ours) {
  if (!byRace.has(r.race_id)) byRace.set(r.race_id, { ...r, cands: [] });
  byRace.get(r.race_id).cands.push(r);
}

const report = [];
for (const race of byRace.values()) {
  const want = new Set(race.cands.map((c) => norm(c.full_name)));
  const hits = allContests.filter((c) => {
    const have = new Set(c.candidates.map((k) => norm(k.name)));
    return have.size === want.size && [...want].every((n) => have.has(n));
  });
  const row = {
    district: race.district_label, office_title: race.office_title, office_id: race.office_id,
    race_id: race.race_id, seats: race.seats, is_vacant: race.is_vacant,
    anchor: null, count: null, ranked: null, problems: [], callable: false,
  };
  // 🔴🔴 A SPECIAL DISTRICT CAN STRADDLE A COUNTY LINE, AND THEN EACH COUNTY PUBLISHES ONLY
  //   ITS OWN SLICE — a complete-looking contest, with every candidate on it, counted from a
  //   fraction of the ballots. Wrightwood CSD is one: Los Angeles holds 71 ballots and San
  //   Bernardino 1,309, and LA files it under "Recreation and Park", not "Water Districts".
  //   Reading either county alone would have ranked the board on 5% or 95% of its electorate.
  //   ▶ When the same candidate set appears in more than one county, SUM them.
  if (hits.length === 0) {
    row.problems.push('NO county contest has exactly this candidate set');
    report.push(row);
    continue;
  }
  const counties = [...new Set(hits.map((h) => h.county))];
  if (hits.length > 1 && counties.length !== hits.length) {
    row.problems.push(`${hits.length} contests in ${counties.length} counties share this candidate set — two of them are in the same county`);
    report.push(row);
    continue;
  }
  const c = hits.length === 1 ? hits[0] : {
    county: counties.join(' + '),
    group: hits.map((h) => h.group).join(' + '),
    id: hits.map((h) => h.id).join(' + '),
    title: hits.map((h) => h.title).join(' + '),
    voteFor: hits[0].voteFor,
    note: `combined across ${counties.length} counties`,
    ballots: hits.every((h) => h.ballots !== null) ? hits.reduce((a, h) => a + h.ballots, 0) : null,
    candidates: hits[0].candidates.map((k) => ({
      name: k.name,
      votes: hits.reduce((a, h) => a + (h.candidates.find((x) => norm(x.name) === norm(k.name))?.votes ?? 0), 0),
      per_county: Object.fromEntries(hits.map((h) => [h.county, h.candidates.find((x) => norm(x.name) === norm(k.name))?.votes ?? null])),
    })),
  };
  row.anchor = {
    county: c.county, contest_id: c.id, title: c.title, voteFor: c.voteFor, note: c.note,
    ballots: c.ballots, counties, per_county_ballots: Object.fromEntries(hits.map((h) => [h.county, h.ballots])),
  };
  // A contest LA itself flags as shared, but which we matched in LA alone, is a slice we have
  // mistaken for the whole thing. Refuse it rather than rank a board on part of its electorate.
  if (hits.length === 1 && /shared with/i.test(c.note || '')) {
    row.problems.push(`the county flags this contest as shared ("${c.note}") and only one county's slice was found`);
  }

  // independent second reading: the contest title must also name this district
  const key = norm(race.district_label).replace(/ - DIVISION \d+| - TRUSTEE AREA \d+/, '');
  const head = key.split(' ').filter((w) => w.length > 3).slice(0, 3);
  if (!head.every((w) => norm(c.title).includes(w))) {
    row.problems.push(`title "${c.title}" does not name "${race.district_label}"`);
  }

  // every LA number re-read from the independently rendered text page — a second reading of
  // the same data, produced by the server rather than by this join
  for (const h of hits.filter((x) => x.county === 'Los Angeles')) {
    for (const k of h.candidates) {
      const t = textVotes.get(`${norm(h.title)} :: ${norm(k.name)}`);
      if (t === undefined) row.problems.push(`${k.name}: absent from the text-results page`);
      else if (t !== k.votes) row.problems.push(`${k.name}: the API says ${k.votes}, the text page says ${t}`);
    }
  }

  // our seat count must agree with the county's own "vote for" instruction
  const WORD = { one: 1, two: 2, three: 3, four: 4, five: 5 };
  const vf = /no more than (one|two|three|four|five)/i.exec(c.voteFor || '');
  const countySeats = vf ? WORD[vf[1].toLowerCase()] : 1;
  if (countySeats !== race.seats) row.problems.push(`we hold seats=${race.seats}, the county ballot says "${c.voteFor || 'vote for 1'}"`);

  const ranked = [...c.candidates].sort((a, b) => b.votes - a.votes)
    .map((k) => ({ ...k, rc: race.cands.find((x) => norm(x.full_name) === norm(k.name)) }));
  const lead = ranked[race.seats - 1];
  const chase = ranked[race.seats];
  const margin = chase ? lead.votes - chase.votes : lead.votes;

  // Only Los Angeles publishes an outstanding-ballot estimate. A contest with any share of its
  // electorate in another county cannot be bounded at all, so it is never callable here.
  const laOnly = counties.length === 1 && counties[0] === 'Los Angeles';
  const estOut = laOnly && c.ballots ? Math.ceil((c.ballots / LA_COUNTED) * LA_OUTSTANDING) : null;
  row.count = {
    ballots: c.ballots, est_outstanding: estOut, safety: SAFETY,
    bound: estOut === null ? null : estOut * SAFETY, margin, unopposed: !chase,
  };
  row.ranked = ranked.map((k, i) => ({
    rank: i + 1, name: k.name, votes: k.votes, rc_id: k.rc?.rc_id,
    politician_id: k.rc?.politician_id, incumbent: k.rc?.is_incumbent,
    outcome: i < race.seats ? 'won' : 'lost',
  }));
  if (estOut === null) {
    row.problems.push(counties.length > 1
      ? `spans ${counties.join(' and ')}; San Bernardino publishes no outstanding-ballot estimate, so the margin cannot be bounded`
      : 'no outstanding-ballot figure for this county — the margin cannot be bounded');
  }
  row.callable = row.problems.length === 0 && margin > estOut * SAFETY;
  report.push(row);
}

const callable = report.filter((r) => r.callable);
const seats = callable.reduce((a, r) => a + r.seats, 0);
console.log(`LA ${LA_COUNTED.toLocaleString()} counted / ${LA_OUTSTANDING.toLocaleString()} outstanding (${(100 * LA_OUTSTANDING / LA_COUNTED).toFixed(2)}%), safety x${SAFETY}`);
console.log(`races ${report.length} · anchored ${report.filter((r) => r.anchor).length} · callable ${callable.length} (${seats} seats) · held back ${report.length - callable.length}\n`);
for (const r of report.sort((a, b) => Number(b.callable) - Number(a.callable) || a.district.localeCompare(b.district))) {
  const c = r.count;
  console.log(`${r.callable ? '[CALL]' : '[HOLD]'} ${r.district} — ${r.office_title} (${r.seats} seat${r.seats > 1 ? 's' : ''})`);
  if (c) {
    console.log(`     margin ${c.margin.toLocaleString()} vs bound ${c.bound === null ? '?' : c.bound.toLocaleString()}`
      + ` (${c.ballots === null ? '?' : c.ballots.toLocaleString()} ballots -> est ${c.est_outstanding === null ? '?' : c.est_outstanding.toLocaleString()} outstanding x${SAFETY})`
      + `${c.unopposed ? '  UNOPPOSED' : ''}`);
  }
  for (const k of r.ranked || []) {
    console.log(`       ${k.rank}. ${String(k.votes).padStart(7)}  ${k.outcome.toUpperCase().padEnd(4)} ${k.name}`
      + `${k.incumbent ? '  (incumbent)' : ''}${k.politician_id ? '' : '  [no politician row]'}`);
  }
  for (const p of r.problems) console.log(`     !! ${p}`);
}
fs.writeFileSync(path.join(dir, `analysis-${stamp}.json`),
  JSON.stringify({ generated: stamp, safety: SAFETY, la: { counted: LA_COUNTED, outstanding: LA_OUTSTANDING }, report }, null, 1));
console.log(`\nwrote analysis-${stamp}.json`);
