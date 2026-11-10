#!/usr/bin/env node
// Controls for analyse-results.mjs. Every check in that file is a detector, and a detector
// that has only ever said "fine" has proved nothing.
//
// 🔴 EACH TAMPER IS ASSERTED PRESENT IN THE TAMPERED FILE BEFORE THE ANALYSER RUNS. A sed
//   that silently matched nothing has produced a 0-byte file that "passed" every gate it did
//   not contain; here the check would simply re-run the clean data and report a pass.
// 🔴 EACH TAMPER LEAVES EVERYTHING ELSE CORRECT, so only the gate under test can catch it.
//   A tamper that trips an earlier gate tells you the suite is alive, not which guard holds
//   which claim.
//
// Usage: node controls-analyse.mjs <dataDir> [stamp]
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { execFileSync } from 'node:child_process';

const src = path.resolve(process.argv[2] || '.');
const stamp = process.argv[3] || '2026-11-08';
const analyser = path.join(src, 'analyse-results.mjs');
const FILES = [`la-election-data-${stamp}.json`, `la-counter-data-${stamp}.json`,
  `la-text-results-${stamp}.html`, `sb-results-${stamp}.html`, `our-candidacies-${stamp}.json`];

function freshDir() {
  const d = fs.mkdtempSync(path.join(os.tmpdir(), 'ca-sd-control-'));
  for (const f of FILES) fs.copyFileSync(path.join(src, f), path.join(d, f));
  return d;
}
const read = (d, f) => fs.readFileSync(path.join(d, f), 'utf8');
const write = (d, f, s) => fs.writeFileSync(path.join(d, f), s);

function run(d) {
  try {
    return { ok: true, out: execFileSync(process.execPath, [analyser, d, stamp], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }) };
  } catch (e) {
    return { ok: false, out: (e.stdout || '') + (e.stderr || '') };
  }
}

const CONTROLS = [
  {
    name: 'A — a vote count changed in the API extract must break the text-page cross-check',
    tamper(d) {
      const j = JSON.parse(read(d, `la-counter-data-${stamp}.json`));
      // Theresa Lee, Walnut Valley Division 3 (candidate id 25830): 3698 -> 3600
      const row = j.Data.find((r) => r.ReferenceType === 'CAND' && r.ReferenceID === 25830);
      if (!row || row.Value !== 3698) throw new Error('control A: the row it targets is not where it was');
      row.Value = 3600;
      write(d, `la-counter-data-${stamp}.json`, JSON.stringify(j));
      return (txt) => /"Value":3600/.test(txt) && !/"ReferenceID":25830,"Value":3698/.test(txt);
    },
    file: () => `la-counter-data-${stamp}.json`,
    expect: (r) => /THERESA LEE: the API says 3600, the text page says 3698/.test(r.out),
  },
  {
    name: 'B — a candidate renamed on our side must lose the contest anchor entirely',
    tamper(d) {
      const j = JSON.parse(read(d, `our-candidacies-${stamp}.json`));
      const row = j.find((r) => r.full_name === 'Kenny Shu');
      if (!row) throw new Error('control B: Kenny Shu is not in the snapshot');
      row.full_name = 'Kenny Shoe';
      row.last_name = 'Shoe';
      write(d, `our-candidacies-${stamp}.json`, JSON.stringify(j, null, 1));
      return (txt) => /Kenny Shoe/.test(txt);
    },
    file: () => `our-candidacies-${stamp}.json`,
    expect: (r) => /Walnut Valley Water District - Division 3[\s\S]*?NO county contest has exactly this candidate set/.test(r.out),
  },
  {
    name: 'C — a seat count that disagrees with the county ballot must be refused',
    tamper(d) {
      const j = JSON.parse(read(d, `our-candidacies-${stamp}.json`));
      const rows = j.filter((r) => r.district_label === 'Crescenta Valley Water District');
      if (rows.length !== 4 || rows[0].seats !== 3) throw new Error('control C: Crescenta Valley is not 4 candidates for 3 seats');
      for (const r of rows) r.seats = 2;
      write(d, `our-candidacies-${stamp}.json`, JSON.stringify(j, null, 1));
      return (txt) => /"seats": 2/.test(txt);
    },
    file: () => `our-candidacies-${stamp}.json`,
    expect: (r) => /we hold seats=2, the county ballot says "Vote for no more than three"/.test(r.out),
  },
  {
    name: 'D — losing one county of a shared district must refuse the contest, not rank it on the other slice',
    tamper(d) {
      // ⚠ A FIRST DRAFT RENAMED THE HEADING AND THE CONTEST STILL MERGED — correctly, because
      //   the anchor is the candidate SET and not the title. Take the slice away instead:
      //   rename San Bernardino's five candidates so its contest no longer matches ours and
      //   only Los Angeles's 71 ballots are left to rank a 1,380-ballot board on.
      let h = read(d, `sb-results-${stamp}.html`);
      const names = ['WES ZUBER', 'JASON AGRAZ', 'RUSS DREW', 'ERIN C. DEGROOT', 'DAVID E. SCHOENWETTER'];
      for (const n of names) {
        if (h.split(n).length - 1 !== 1) throw new Error(`control D: "${n}" does not occur exactly once in the San Bernardino page`);
        h = h.replace(n, n.replace(/[AEIOU]/, 'Y'));
      }
      write(d, `sb-results-${stamp}.html`, h);
      return (txt) => names.every((n) => !txt.includes(n));
    },
    file: () => `sb-results-${stamp}.html`,
    expect: (r) => /Wrightwood[\s\S]*?the county flags this contest as shared[\s\S]*?Shared with San Bernardino County/.test(r.out),
  },
  {
    name: 'E — a margin inside the bound must turn a CALL into a HOLD',
    tamper(d) {
      const j = JSON.parse(read(d, `la-counter-data-${stamp}.json`));
      // Foothill Division 5: Atwater 3286 vs Razavian 2301, margin 985, bound 915.
      // Lift the loser to 2400 and the margin (886) falls inside the bound.
      const row = j.Data.find((r) => r.ReferenceType === 'CAND' && r.ReferenceID === 26198);
      if (!row || row.Value !== 2301) throw new Error('control E: the row it targets is not where it was');
      row.Value = 2400;
      write(d, `la-counter-data-${stamp}.json`, JSON.stringify(j));
      return (txt) => /"Value":2400/.test(txt);
    },
    file: () => `la-counter-data-${stamp}.json`,
    // ⚠ this tamper also breaks the text-page cross-check, which is the point of the pairing:
    // it proves the DECISIVENESS line moved, and the cross-check firing is expected noise.
    expect: (r) => /\[HOLD\] Foothill Municipal Water District - Division 5/.test(r.out)
      && /margin 886 vs bound 915/.test(r.out),
  },
  {
    name: 'F — the all-zero ballot feed alone must refuse to be read as a result',
    tamper(d) {
      const j = JSON.parse(read(d, `la-counter-data-${stamp}.json`));
      const before = j.Data.filter((r) => r.ReferenceType === 'CAND').length;
      if (before < 1000) throw new Error('control F: the candidate counts are not where they were');
      for (const r of j.Data) if (r.ReferenceType === 'CAND') r.Value = 0;
      write(d, `la-counter-data-${stamp}.json`, JSON.stringify(j));
      return (txt) => !/"ReferenceType":"CAND","Value":[1-9]/.test(txt);
    },
    file: () => `la-counter-data-${stamp}.json`,
    expect: (r) => /the LA join produced only 0 votes in all/.test(r.out),
  },
  {
    name: 'G — an accent decoder that stops working must raise, not report three absences',
    tamper(d) {
      const h = read(d, `la-text-results-${stamp}.html`);
      if (!/LA CA&#xD1;ADA IRRIGATION DISTRICT/.test(h)) throw new Error('control G: the entity is not where it was');
      // re-encode the entity so the decoder cannot resolve it
      write(d, `la-text-results-${stamp}.html`, h.replace(/&#xD1;/g, '&Ntilde;'));
      return (txt) => !/&#xD1;/.test(txt) && /&Ntilde;/.test(txt);
    },
    file: () => `la-text-results-${stamp}.html`,
    expect: (r) => /the text-results index cannot see a line known to exist/.test(r.out),
  },
];

// the clean run must pass first, or every "it failed" below means nothing
const clean = run(src);
if (!clean.ok) { console.error('the UNTAMPERED run failed — fix that before reading any control\n' + clean.out); process.exit(1); }
const baseline = /callable (\d+) \((\d+) seats\)/.exec(clean.out);
console.log(`clean run: ${baseline ? baseline[0] : '??'}\n`);

let bad = 0;
for (const c of CONTROLS) {
  const d = freshDir();
  let present;
  try { present = c.tamper(d); } catch (e) { console.log(`  FAIL  ${c.name}\n        could not plant the tamper: ${e.message}`); bad++; continue; }
  // 🔴 assert the tamper actually landed before believing anything the analyser says
  if (!present(read(d, c.file()))) { console.log(`  FAIL  ${c.name}\n        the tamper did not land in ${c.file()} — this control proved nothing`); bad++; continue; }
  const r = run(d);
  const caught = c.expect(r);
  console.log(`  ${caught ? 'ok  ' : 'FAIL'}  ${c.name}`);
  if (!caught) { bad++; console.log(r.out.split('\n').filter((l) => /!!|Error|HOLD|CALL/.test(l)).slice(0, 12).map((l) => '        ' + l).join('\n')); }
  fs.rmSync(d, { recursive: true, force: true });
}
console.log(`\n${CONTROLS.length - bad} of ${CONTROLS.length} controls fired.`);
process.exit(bad ? 1 : 0);
