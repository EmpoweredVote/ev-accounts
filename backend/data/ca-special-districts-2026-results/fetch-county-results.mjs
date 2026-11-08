#!/usr/bin/env node
// Fetch the raw 2026-11-03 results for the two counties that run the special-district
// contests handing over on 2026-12-04.
//
// LA County RR/CC serves results from a small JSON API that the results.lavote.gov page
// itself calls. It comes in TWO pieces and NEITHER is usable alone:
//   GetElectionData — contests + candidates + candidate ids. Every Votes field is 0 and every
//                     Winner flag is false. This is the BALLOT, not the result. Reading it
//                     alone reports a complete election in which nobody got a vote.
//   GetCounterData  — the counts, keyed by candidate id (ReferenceType 'CAND'), plus
//                     per-contest counters (CBLT ballots cast, CUV undervotes, COV overvotes,
//                     WRTN-nn write-ins, NSEL-nn "not selected" per seat position).
// The join of the two is checked against results.lavote.gov/text-results/<id>, which the
// server renders independently from the same data — a free second reading of every number.
//
// San Bernardino County serves one server-rendered HTML page per election.
//
// Usage:  node fetch-county-results.mjs [outputDir]
import fs from 'node:fs/promises';
import path from 'node:path';

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';
const LA_ELECTION_ID = 4348;           // 2026-11-03 General, from GetMenuElections?year=2026
const SB_URL = 'https://results.rov.sbcounty.gov/Results/20261103/';
const outDir = process.argv[2] || path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1'));

async function get(url, referer) {
  const r = await fetch(url, { headers: { 'User-Agent': UA, Referer: referer, 'X-Requested-With': 'XMLHttpRequest' } });
  const body = await r.text();
  // 🔴 r.ok is never the test. A WAF answers 200 with a challenge body and a dead host has
  //    answered 202 with zero bytes; a zero-byte file parses cleanly and yields nothing, which
  //    reads as "this county held no elections".
  if (body.length === 0) throw new Error(`${url}: HTTP ${r.status} with a ZERO-BYTE body`);
  return { status: r.status, body };
}

const stamp = new Date().toISOString().slice(0, 10);
const wrote = [];
async function save(name, text) {
  const p = path.join(outDir, name);
  await fs.writeFile(p, text);
  wrote.push(`${name}  ${text.length.toLocaleString()} bytes`);
}

const la = 'https://results.lavote.gov';
const ed = await get(`${la}/ElectionResults/GetElectionData?electionID=${LA_ELECTION_ID}`, la + '/');
const cd = await get(`${la}/ElectionResults/GetCounterData?electionID=${LA_ELECTION_ID}`, la + '/');
const tx = await get(`${la}/text-results/${LA_ELECTION_ID}`, la + '/');
const sb = await get(SB_URL, SB_URL);

// assert on CONTENT, never on the status code
const edJson = JSON.parse(ed.body), cdJson = JSON.parse(cd.body);
const nCand = cdJson.Data.filter((r) => r.ReferenceType === 'CAND').length;
if (nCand < 500) throw new Error(`LA counter data holds only ${nCand} candidate rows — expected the full ballot`);
if (!/WRIGHTWOOD COMMUNITY SERVICES DISTRICT/i.test(sb.body)) throw new Error('the San Bernardino page does not mention Wrightwood CSD');
if (!/text-results|Candidate\(s\)/i.test(tx.body)) throw new Error('the LA text-results page did not render contests');

await save(`la-election-data-${stamp}.json`, ed.body);
await save(`la-counter-data-${stamp}.json`, cd.body);
await save(`la-text-results-${stamp}.html`, tx.body);
await save(`sb-results-${stamp}.html`, sb.body);

console.log(`LA GetElectionData  contests across ${edJson.Data.ContestGroups.length} groups, timestamp ${edJson.TimeStamp}`);
console.log(`LA GetCounterData   ${cdJson.Data.length} counter rows, ${nCand} of them candidate counts, timestamp ${cdJson.TimeStamp}`);
console.log(`SB results page     ${sb.body.length.toLocaleString()} bytes`);
console.log(wrote.map((w) => '  wrote ' + w).join('\n'));
