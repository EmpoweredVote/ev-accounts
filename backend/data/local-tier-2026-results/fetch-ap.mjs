#!/usr/bin/env node
// Fetch AP's own per-state results files for the state-legislative tier.
//
// 🔴 THE NATIONAL FILE DOES NOT CARRY THESE RACES. Every earlier pass in this programme read
//   results/national/{metadata,progress}.json, which holds 645 races across nine office types
//   and NOT ONE state-legislative contest. AP publishes them per state, at
//   results/races/<ST>/{metadata,progress}.json — 6,938 races across the 51 files, of which
//   5,759 are state-legislative. Found the same way the feed itself was: by watching the
//   network calls an AP state results page makes.
//
// 🔴 A BARE curl GETS 403 AND THE BODY IS GZIPPED — browser headers plus decompression.
// 🔴 A ZERO-BYTE BODY PARSES CLEANLY AND YIELDS NOTHING, which reads as "that state held no
//   elections" (CC_0360 met this on WI and WY, HTTP 202, three retries each). Every file is
//   size-checked and the office counts are printed, so a state that yields nothing is named.
import fs from 'node:fs';
import path from 'node:path';

const DATE = process.env.AP_DATE || '2026-11-03';
const BASE = `https://interactives.apelections.org/election-results/data-live/${DATE}/results/races`;
const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
  Referer: 'https://apnews.com/',
  'Accept-Encoding': 'gzip, deflate, br',
};
const MIN_BYTES = 500;

const states = (process.argv[2] || '').split(',').map((s) => s.trim().toUpperCase()).filter(Boolean);
const outDir = process.argv[3];
if (!states.length || !outDir) {
  console.error('usage: fetch-ap.mjs <ST,ST,...> <out-dir>');
  process.exit(2);
}
fs.mkdirSync(outDir, { recursive: true });

const LEG_OFFICE_IDS = new Set(['Y', 'Z']);
let failures = 0;

for (const st of states) {
  const files = {};
  for (const kind of ['metadata', 'progress']) {
    const url = `${BASE}/${st}/${kind}.json`;
    const res = await fetch(url, { headers: HEADERS });
    const text = await res.text();
    if (!res.ok) { console.error(`✗ ${st} ${kind}: HTTP ${res.status}`); failures++; continue; }
    // r.ok is never the test — the size is.
    if (text.length < MIN_BYTES) { console.error(`✗ ${st} ${kind}: ${text.length} bytes, under the ${MIN_BYTES}-byte floor`); failures++; continue; }
    let parsed;
    try { parsed = JSON.parse(text); } catch (e) { console.error(`✗ ${st} ${kind}: not JSON (${e.message})`); failures++; continue; }
    const p = path.join(outDir, `${st}-${kind}.json`);
    fs.writeFileSync(p, text);
    files[kind] = parsed;
  }
  if (!files.metadata || !files.progress) continue;
  const ids = Object.keys(files.metadata);
  const leg = ids.filter((k) => LEG_OFFICE_IDS.has(files.metadata[k].officeID));
  const called = leg.filter((k) => files.metadata[k].raceCallStatus === 'Called').length;
  const rcv = leg.filter((k) => files.metadata[k].rankedChoice).length;
  if (!leg.length) console.error(`⚠ ${st}: ${ids.length} races in the file and NOT ONE is state-legislative — say so rather than reading it as "no elections"`);
  console.log(`${st}: ${String(ids.length).padStart(4)} races, ${String(leg.length).padStart(4)} legislative, ${String(called).padStart(4)} called${rcv ? `, ${rcv} ranked-choice` : ''}`);
}

if (failures) { console.error(`\n${failures} file(s) failed — nothing downstream may treat this as a complete fetch`); process.exit(1); }
