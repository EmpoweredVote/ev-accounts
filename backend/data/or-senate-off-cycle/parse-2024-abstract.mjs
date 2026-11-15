#!/usr/bin/env node
// Which Oregon legislative districts were ON the November 5, 2024 ballot?
//
// Source: Oregon Secretary of State, "2024 November General Election Official Results",
// records.sos.state.or.us RecordViewer uri=13735458 (35 pages, 1,185,360 bytes; the response's
// Content-Length matched the bytes received), converted with `pdftotext -layout`.
//
// 🔴 THE VOTE COUNTS IN THIS CONVERSION ARE MANGLED AND ARE NOT READ. pdftotext's layout mode
//    drifts the county columns here exactly as it did on the Massachusetts city PDFs -- Sherman
//    County (≈1,800 people) prints 325,927 in the presidential table. The only things taken from
//    this file are STRUCTURAL: which contest headings exist. No number in it is used anywhere.
//
// 🔴 A HEADING IS NOT ALWAYS ALONE ON ITS LINE. The first reader of this file required the whole
//    line to be "<N>th District" and reported 40 of Oregon's 60 House districts and 5 of its 6
//    congressional districts -- a parser gap that would have read as a calendar fact. The layout
//    converter merges a heading into the candidate row below it on many pages
//    ("10th District  **Gomberg  Misc."), so the match is anchored at the START of the line only.
//
// ⚠ ", Position N" AFTER A DISTRICT IS A JUDICIAL CONTEST, NOT A LEGISLATIVE ONE -- circuit court
//    judgeships are numbered by judicial district and seat ("13th District, Position 5"). Those
//    headings are excluded by shape.
//
// THE CONTROL IS THE HOUSE. Every one of Oregon's 60 House seats is elected every two years, and
// all 6 congressional seats likewise. If this reader does not return 60 and 6, it is blind and its
// senate answer means nothing. Only then is "15 of 30 senate districts" a finding and not an
// artefact. It has already earned its keep twice: it caught the merged-heading gap above, and then
// caught a CRLF bug that made the reader return zero of everything.
import fs from 'node:fs';

const [txtPath] = process.argv.slice(2);
if (!txtPath) { console.error('usage: parse-2024-abstract.mjs <abstract.txt>'); process.exit(2); }

const DISTRICT = /^ *(\d+)(?:st|nd|rd|th) District(?!,)/;     // start of line; ", Position" excluded
const CONTEST = /^ *(State Senator|State Representative|US Representative)(?: +|$)/;

// ⚠ The converter emits CRLF. A trailing \r at the end of a heading line made every contest regex
//   miss, and the reader returned zero of everything -- caught by the House control on its first
//   run, before the senate answer could be believed.
const lines = fs.readFileSync(txtPath, 'utf8').split(/\r?\n/);
let contest = null;
const found = new Map();
for (const line of lines) {
  const c = line.match(CONTEST);
  if (c) { contest = c[1]; continue; }
  const d = line.match(DISTRICT);
  if (!d) continue;
  if (!contest) continue;                                      // anything before the first contest
  if (!found.has(contest)) found.set(contest, new Set());
  found.get(contest).add(Number(d[1]));
}

const got = (k) => [...(found.get(k) || [])].sort((a, b) => a - b);
const house = got('State Representative');
const cong = got('US Representative');
const senate = got('State Senator');
const upTo = (n) => Array.from({ length: n }, (_, i) => i + 1);

const problems = [];
if (house.length !== 60) problems.push(`the reader found ${house.length} of Oregon's 60 House districts, so it is blind`);
if (cong.length !== 6) problems.push(`the reader found ${cong.length} of Oregon's 6 congressional districts, so it is blind`);

console.log(JSON.stringify({
  source: txtPath,
  control: { houseDistrictsFound: house.length, congressionalFound: cong.length, pass: problems.length === 0 },
  senateOn2024Ballot: senate,
  senateOn2024BallotCount: senate.length,
  senateNotOn2024Ballot: upTo(30).filter((n) => !senate.includes(n)),
  houseMissing: upTo(60).filter((n) => !house.includes(n)),
}, null, 2));
if (problems.length) { console.error(`\n🔴 ${problems.join('; ')}`); process.exit(1); }
