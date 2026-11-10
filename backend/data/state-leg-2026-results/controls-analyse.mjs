#!/usr/bin/env node
// Controls for analyse.mjs. The migration re-asserts every pinned row against production, so
// these cover the things a migration CANNOT see — a race the matcher drops, a winner it
// records against nobody, a shape assumption that is silently wrong.
//
// 🔴 THE DANGEROUS FAILURE HERE IS SILENCE. A race that matches no key simply does not appear;
//   a progress file read as a map returns undefined for every candidate and reads as "no
//   results yet". Both are uniform answers, and a uniform answer is a broken detector until a
//   control says otherwise.
//
// Usage: node controls-analyse.mjs <ap-dir> <our-rows.json> <name-overrides.json>
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { execFileSync } from 'node:child_process';

const apDir = path.resolve(process.argv[2]);
const ourFile = path.resolve(process.argv[3]);
const overrides = path.resolve(process.argv[4]);
const analyser = path.resolve(path.dirname(process.argv[1]), 'analyse.mjs');

const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'cc0381-analyse-'));
const copyDir = (src, dst) => { fs.mkdirSync(dst, { recursive: true }); for (const f of fs.readdirSync(src)) fs.copyFileSync(path.join(src, f), path.join(dst, f)); };

function run(ap, our, ov) {
  const out = path.join(tmp, 'out-' + Math.random().toString(36).slice(2) + '.json');
  try {
    const stdout = execFileSync(process.execPath, [analyser, ap, our, out, ov], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
    return { ok: true, out: stdout, json: JSON.parse(fs.readFileSync(out, 'utf8')) };
  } catch (e) { return { ok: false, out: (e.stdout || '') + (e.stderr || '') }; }
}

const clean = run(apDir, ourFile, overrides);
if (!clean.ok) { console.error('the UNTAMPERED analyser failed — fix that before reading any control\n' + clean.out); process.exit(1); }
const baseWritable = clean.json.plan.filter((r) => !r.skip).length;
const baseRows = clean.json.plan.filter((r) => !r.skip).reduce((a, r) => a + r.writes.length, 0);
console.log('clean run: ' + clean.json.matched_races + ' races matched, ' + baseWritable + ' writable, ' + baseRows + ' rows\n');
if (clean.json.our_races_with_no_ap_race.length) { console.error('clean run already drops races — no control below is readable'); process.exit(1); }

const CONTROLS = [
  {
    name: 'A — a progress file whose candidates are a MAP must be refused, not read as empty',
    why: 'metadata.candidates is an object and progress.candidates is an array; the wrong guess returns undefined for every candidate and reads as a feed with no results in it',
    build: (ap) => {
      const p = path.join(ap, 'WI-progress.json');
      const d = JSON.parse(fs.readFileSync(p, 'utf8'));
      const meta = JSON.parse(fs.readFileSync(path.join(ap, 'WI-metadata.json'), 'utf8'));
      const k = Object.keys(d).find((x) => meta[x] && (meta[x].officeID === 'Y' || meta[x].officeID === 'Z'));
      d[k].candidates = Object.fromEntries(d[k].candidates.map((c) => [c.candidateID, c]));
      fs.writeFileSync(p, JSON.stringify(d));
    },
    expect: /progress\.candidates is not an ARRAY/,
  },
  {
    name: 'B — a zero-byte input must be refused, not parsed as a state that held no elections',
    why: 'CC_0360 met HTTP 202 with an empty body from a host that served 41 other states fine; an empty file parses cleanly and yields nothing',
    build: (ap) => fs.writeFileSync(path.join(ap, 'WI-metadata.json'), ''),
    expect: /bytes - a zero-byte file parses cleanly/,
  },
  {
    name: 'C — a race whose key stops matching must be REPORTED, never silently dropped',
    why: 'Massachusetts names its districts and its ocd suffix is an internal index, so a numeric key matched nothing and two real races vanished without a word',
    build: (ap) => {
      const p = path.join(ap, 'WI-metadata.json');
      const d = JSON.parse(fs.readFileSync(p, 'utf8'));
      const k = Object.keys(d).find((x) => d[x].officeID === 'Y' && d[x].seatName === 'District 1');
      d[k].seatName = 'District 999'; d[k].seatNum = '999';
      fs.writeFileSync(p, JSON.stringify(d));
    },
    check: (r) => r.ok && r.json.our_races_with_no_ap_race.length === 1
      && /NO AP race: 1/.test(r.out),
    describe: 'the dropped race is named in the report',
  },
  {
    name: 'D — a winner we hold no row for must BLOCK the race',
    why: 'a loser AP names and we do not hold is absent; a WINNER we do not hold is a result we would miss entirely',
    buildOur: (rows) => {
      // remove the winning candidacy of one Wisconsin race
      const i = rows.findIndex((x) => x.full_name === 'Joel Kitchens');
      rows.splice(i, 1);
      return rows;
    },
    check: (r) => r.ok && /matches no row of ours/.test(JSON.stringify(r.json.plan.filter((x) => x.skip === 'blocked'))),
    describe: 'the race is blocked and the missing winner is named',
  },
  {
    name: 'E — an override pointing at a row outside its race must be refused',
    why: 'a hand-written allowance is exactly where a wrong uuid hides, because nothing else checks it',
    buildOv: (o) => { o.overrides[0].rc_id = '00000000-0000-0000-0000-000000000000'; return o; },
    expect: /which is not in race/,
  },
  {
    name: 'F — an override that has stopped being needed must be refused, not carried',
    why: 'a stale allowance is an exemption with nothing behind it; CC_0378 shipped one and its own dry run refused it',
    buildOv: (o) => {
      o.overrides.push({ ap_race_id: '20261103WI50174', ap_candidate_id: '155928', ap_name: 'Joel Kitchens',
        rc_id: 'aee1d165-f78a-4986-a8c5-b222b6f9950b', our_name: 'Joel Kitchens',
        basis: 'a deliberately redundant allowance planted by control F — this row matches on its own exact name and needs no override at all' });
      return o;
    },
    expect: /was never used/,
  },
];

let bad = 0;
for (const c of CONTROLS) {
  const ap = path.join(tmp, 'ap-' + c.name[0]);
  copyDir(apDir, ap);
  let our = ourFile, ov = overrides;
  if (c.build) c.build(ap);
  if (c.buildOur) {
    our = path.join(tmp, 'our-' + c.name[0] + '.json');
    fs.writeFileSync(our, JSON.stringify(c.buildOur(JSON.parse(fs.readFileSync(ourFile, 'utf8')))));
  }
  if (c.buildOv) {
    ov = path.join(tmp, 'ov-' + c.name[0] + '.json');
    fs.writeFileSync(ov, JSON.stringify(c.buildOv(JSON.parse(fs.readFileSync(overrides, 'utf8')))));
  }
  const r = run(ap, our, ov);
  const fired = c.expect ? (!r.ok && c.expect.test(r.out)) : c.check(r);
  console.log('  ' + (fired ? 'ok  ' : 'FAIL') + '  ' + c.name);
  console.log('          ' + c.why + (c.describe ? ' — ' + c.describe : ''));
  if (!fired) { bad++; console.log('          ' + (r.out || '').split('\n').slice(0, 4).join('\n          ')); }
}
fs.rmSync(tmp, { recursive: true, force: true });
console.log('\n' + (CONTROLS.length - bad) + ' of ' + CONTROLS.length + ' controls fired.');
process.exit(bad ? 1 : 0);
