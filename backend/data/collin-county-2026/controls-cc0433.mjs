#!/usr/bin/env node
// Positive controls for CC_0433. Each one plants ONE fault, runs the migration through
// dry-run-migration.mjs (which always rolls back), and requires the migration to RAISE with the
// message that gate owns.
//
// 🔴 WHY THIS FILE EXISTS. A migration whose gates have only ever been green proves nothing: a
// gate can pass for the wrong reason, and an earlier gate shadows a later one, so "it went red"
// is not "the gate I meant to test went red". Each control below therefore names the GATE it
// must fire on and asserts on that gate's own message, not merely on a non-zero exit.
//
// 🔴 AND A TAMPER THAT DID NOT APPLY LOOKS EXACTLY LIKE A PASS. `applyTamper` exits non-zero if
// its search text is not found, and every control asserts the tampered SQL differs from the
// original before it is run. An empty or unmodified file passes every gate it does not contain.
//
// Usage (from backend/):  node data/collin-county-2026/controls-cc0433.mjs
import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const SRC = process.argv[2]
  ?? 'C:/ev-accounts-collin/backend/migrations/CC_0433_blue_ridge_weston_tx_at_large_districts.sql';
const original = readFileSync(SRC, 'utf8');
const work = mkdtempSync(join(tmpdir(), 'cc0433-controls-'));

function applyTamper(name, find, replace) {
  if (!original.includes(find)) {
    console.error(`FATAL [${name}]: tamper text not found in the migration:\n  ${find}`);
    process.exit(2);
  }
  const tampered = original.replace(find, replace);
  if (tampered === original) {
    console.error(`FATAL [${name}]: replacement produced an identical file.`);
    process.exit(2);
  }
  const path = join(work, `${name}.sql`);
  writeFileSync(path, tampered);
  // The tamper must be PRESENT on disk, not merely intended.
  const back = readFileSync(path, 'utf8');
  if (back === original || !back.includes(replace.split('\n')[0])) {
    console.error(`FATAL [${name}]: tamper did not land on disk.`);
    process.exit(2);
  }
  return path;
}

function run(path) {
  try {
    const out = execFileSync('node', ['scripts/dry-run-migration.mjs', path],
      { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
    return { ok: true, out };
  } catch (e) {
    return { ok: false, out: `${e.stdout ?? ''}${e.stderr ?? ''}` };
  }
}

const CONTROLS = [
  {
    name: 'A-premise-lowry-untouched',
    gate: 'PREMISE 4 — Lowry Crossing still has its 4 district-less offices',
    // Repoint one Lowry Crossing seat at its city-wide district before the premise runs. This is
    // the exact mistake the header argues against, so the file must refuse to proceed.
    find: 'BEGIN;\n\n-- ── Premise ─',
    replace: "BEGIN;\n\nUPDATE essentials.offices SET district_id = '7534e932-59b2-45ed-bb94-0c2df9b696c3'"
      + " WHERE id = 'e7aee556-f447-440b-ac70-5b5709c6cdd4';\n\n-- ── Premise ─",
    expect: /still have its 4 district-less offices|still have 4 district-less offices/i,
  },
  {
    name: 'B-postverify-rows-repointed',
    gate: 'POST-VERIFY 1 — both offices repointed',
    // Neuter the Weston UPDATE. The column never changes, so the cheap column check must catch it.
    find: "UPDATE essentials.offices\n   SET district_id = '68755158-a11d-4b78-97ac-751661d10ded'\n"
      + " WHERE id = '93c204ca-9a24-4027-8952-811ca792a088'\n   AND district_id IS NULL;",
    replace: "UPDATE essentials.offices\n   SET district_id = '68755158-a11d-4b78-97ac-751661d10ded'\n"
      + " WHERE id = '93c204ca-9a24-4027-8952-811ca792a088'\n   AND district_id IS NULL AND false;",
    expect: /expected both offices repointed; 1 of 2/i,
  },
  {
    name: 'C-postverify-address-probe',
    gate: 'POST-VERIFY 2 — an address inside the city returns 6 offices',
    // 🔴 THE ONE THAT MATTERS, AND THE ONE AN EARLIER GATE WOULD OTHERWISE SHADOW. Both columns
    // are set correctly, so POST-VERIFY 1 passes cleanly; the geofence row that makes the city
    // reachable is deleted after the UPDATEs, so only a gate that actually walks the geometry
    // can see it. If this control goes green, the probe is decorative and the migration proves
    // nothing about whether a voter can reach these people.
    find: '-- ── Post-verify ─',
    replace: "DELETE FROM essentials.geofence_boundaries WHERE mtfcc = 'G4110' AND geo_id = '4808872';\n\n"
      + '-- ── Post-verify ─',
    expect: /an address inside Blue Ridge returns 0 of this city's offices, expected 6/i,
  },
];

let failures = 0;
console.log(`CC_0433 controls — migration: ${SRC}\n`);

// Baseline: the untampered file must be GREEN, or a red control proves nothing.
const base = run(SRC);
console.log(`[baseline] untampered file: ${base.ok ? 'GREEN' : 'RED'}`);
if (!base.ok) {
  console.error('FATAL: the untampered migration does not pass. Fix that before reading controls.');
  console.error(base.out);
  process.exit(1);
}

for (const c of CONTROLS) {
  const path = applyTamper(c.name, c.find, c.replace);
  const res = run(path);
  const fired = !res.ok && c.expect.test(res.out);
  const status = fired ? 'RED (correct)' : res.ok ? 'GREEN — CONTROL FAILED' : 'RED, WRONG GATE';
  console.log(`\n[${c.name}]`);
  console.log(`  gate   : ${c.gate}`);
  console.log(`  result : ${status}`);
  if (!fired) {
    failures++;
    console.log(`  ---- output ----\n${res.out.trim().split('\n').map(l => '  ' + l).join('\n')}`);
  } else {
    const line = res.out.split('\n').find(l => c.expect.test(l))?.trim();
    console.log(`  message: ${line}`);
  }
}

console.log(`\n${failures === 0
  ? 'ALL CONTROLS FIRED ON THEIR OWN GATE — the migration is observed, not merely green.'
  : `${failures} CONTROL(S) DID NOT FIRE — do not trust this migration's green.`}`);
process.exit(failures === 0 ? 0 : 1);
