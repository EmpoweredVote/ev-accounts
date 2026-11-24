#!/usr/bin/env node
/**
 * Run a suite of CONTROLS against a chain of migrations, and record WHICH GATE each one fired on.
 *
 * ── WHY THIS EXISTS ─────────────────────────────────────────────────────────────────────────
 *
 * `dry-run-migration.mjs` rehearses one file. `rehearse-migration-chain.mjs` rehearses several in
 * one rolled-back transaction. Neither of them breaks anything on purpose — and a gate nobody has
 * seen go red is not a gate.
 *
 * Step 7 of the state-seating recipe ("watch one control fail") has been done by hand for every
 * state in the 2026 pass, and the hand-rolled driver has been rewritten THREE TIMES — Washington,
 * Utah, Oregon — each time re-learning the same four things the hard way. They are the four this
 * file enforces:
 *
 * 1. 🔴 **A TAMPER THAT DID NOT APPLY IS A CONTROL THAT PROVED NOTHING, AND IT LOOKS LIKE A PASS.**
 *    On 2026-10-26 a `sed` that built a tamper file failed on a quoting error, left a 0-byte file,
 *    and the dry run reported `DRY RUN OK` on it — an empty migration passes every gate it does
 *    not contain. So `buildTamper` REFUSES a needle that does not occur exactly once, and re-reads
 *    the file it wrote to confirm the replacement is present and the original is gone.
 *
 * 2. 🔴🔴 **"EIGHTEEN OF EIGHTEEN WENT RED" IS A UNIFORM ANSWER, AND A BROKEN HARNESS PRODUCES
 *    EXACTLY THAT.** A bad path, a dead connection, a stray argument — every control goes red and
 *    the suite reads as a triumph. So the UNTAMPERED chain is run first, through the same code
 *    path, and must come back GREEN. **A control suite needs a control.** If it fails, nothing
 *    below it is reported, because nothing below it would mean anything.
 *
 * 3. 🔴🔴 **A GATE NO CONTROL REACHES IS A GATE NOBODY HAS TESTED, AND TWO GATES CATCHING ONE
 *    FAULT IS WHAT HIDES IT.** Gates run in order, so a tamper stopped by an earlier one says
 *    nothing about the later one — and the earlier gate firing looks like success. This file
 *    parses the gate out of the rehearser's `FAILED — <gate>: <message>` line and prints it
 *    beside the gate the control was AIMED at. A mismatch is reported as a **BACKSTOP**, not as a
 *    pass: the control did its job, and the gate it was aimed at is still untested.
 *
 * 4. ⚠ **A CONTROL PROVES A VERIFIER CAN FAIL. IT DOES NOT PROVE THE VERIFIER READ THE RIGHT
 *    ROWS.** So the failure MESSAGE is printed in full, not just the gate name. Oregon's C4 is the
 *    worked example: making a gate blind to Washington reported "118 rows ... are not Washington
 *    legislative rows", and that 118 is the evidence the gate was reading real rows rather than
 *    passing vacuously over an empty set.
 *
 * ── USAGE ───────────────────────────────────────────────────────────────────────────────────
 *
 *   node scripts/run-migration-controls.mjs <spec.mjs> [--only C4,C11] [--keep]
 *   node scripts/run-migration-controls.mjs <spec.mjs> --check   # build every tamper, run nothing
 *   node scripts/run-migration-controls.mjs --self-test
 *
 * `--check` touches no database. It builds every tamper in the spec and reports any whose needle
 * is missing or not unique — which is how a spec rots once somebody edits a migration, and it is
 * silent otherwise because a bad needle is only discovered when that one control happens to run.
 *
 * The spec is an ES module whose default export is:
 *
 *   export default {
 *     name: 'OR 2026',
 *     files: { dates: 'migrations/CC_0491_….sql', people: '…', seating: '…' },
 *     controls: [
 *       { id: 'C1', label: 'write the first Monday instead of the second',
 *         aimedAt: 'assertion 3b',
 *         chain: [ { tamper: 'dates', find: "…", replace: "…" } ] },
 *       { id: 'C10', label: 'a winner row re-pointed at another person',
 *         aimedAt: 'P1 digest',
 *         chain: [ 'dates', 'people', { sql: 'UPDATE …;' }, 'seating' ] },
 *     ],
 *   };
 *
 * A `chain` entry is one of:
 *   • a file KEY            — that file, untampered
 *   • `{ tamper, find, replace }` — that file with ONE exact replacement (refused unless unique)
 *   • `{ sql }`             — raw SQL run inside the same transaction, BEFORE the files after it.
 *                             Use it for a fault in the DATA rather than in a migration.
 *
 * 🔴 **CHANGE ONE THING PER TAMPER.** A tamper that trips three assertions at once tells you the
 *    suite is alive but not which guard holds which claim.
 *
 * 🔴 **THIS TOOL CANNOT COMMIT.** Every chain runs through `rehearse-migration-chain.mjs`, which
 *    has no COMMIT in it and rolls back in a `finally`. It is still READ-WRITE against production
 *    inside that transaction, so run it against the state the files were written for.
 *
 * ⚠ **A SUITE CANNOT BE RE-RUN AFTER ITS MIGRATIONS ARE APPLIED.** Every seating file asks "have
 *    I already run?" first, so once the chain is in production the negative control fails and the
 *    suite refuses to report — correctly. Keep the spec as the record of what was run, not as a
 *    regression test.
 */
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const HERE = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1'));
const REHEARSE = path.join(HERE, 'rehearse-migration-chain.mjs');

const argv = process.argv.slice(2);
const SELF_TEST = argv.includes('--self-test');
const CHECK_ONLY = argv.includes('--check');
const KEEP = argv.includes('--keep');
// ⚠ `onlyArg` is read ONLY when --only is actually present. Computing it unconditionally makes
//   `argv.indexOf('--only')` return -1, so `argv[0]` — the spec path — becomes the "only" value
//   and is then excluded from the search for the spec. Caught by the first real invocation.
const onlyIdx = argv.indexOf('--only');
const onlyArg = onlyIdx === -1 ? null : argv[onlyIdx + 1];
const ONLY = onlyArg ? new Set(onlyArg.split(',').map((s) => s.trim())) : null;
const specPath = argv.find((a, i) => !a.startsWith('--') && !(onlyIdx >= 0 && i === onlyIdx + 1));

if (!SELF_TEST && !specPath) {
  console.error('usage: node scripts/run-migration-controls.mjs <spec.mjs> [--only C4,C11] [--keep]');
  console.error('       node scripts/run-migration-controls.mjs --self-test');
  process.exit(2);
}
if (!fs.existsSync(REHEARSE)) {
  console.error(`REFUSED: cannot find the rehearser beside this script (${REHEARSE}).`);
  process.exit(2);
}

const workDir = fs.mkdtempSync(path.join(os.tmpdir(), 'migration-controls-'));
const cleanup = () => { if (!KEEP) fs.rmSync(workDir, { recursive: true, force: true }); };

// ── The tamper builder ──────────────────────────────────────────────────────────────────────
// 🔴 Refuses a needle that is not unique, and PROVES the replacement landed before anything runs.
function buildTamper(id, srcPath, find, replace) {
  if (!fs.existsSync(srcPath)) throw new Error(`[${id}] TAMPER REFUSED: no such file — ${srcPath}`);
  const src = fs.readFileSync(srcPath, 'utf8');
  const n = src.split(find).length - 1;
  if (n !== 1) {
    throw new Error(
      `[${id}] TAMPER REFUSED: the needle occurs ${n} time(s) in ${path.basename(srcPath)}, ` +
      `expected exactly 1. A tamper that lands in the wrong place, or does not land at all, ` +
      `looks exactly like a pass.\n  needle: ${JSON.stringify(find.slice(0, 160))}`);
  }
  if (replace === find) throw new Error(`[${id}] TAMPER REFUSED: the replacement is identical to the needle.`);
  const out = path.join(workDir, `${id}__${path.basename(srcPath)}`);
  fs.writeFileSync(out, src.replace(find, replace));
  const back = fs.readFileSync(out, 'utf8');
  if (!back.includes(replace)) throw new Error(`[${id}] TAMPER REFUSED: the replacement is NOT present in the written file.`);
  if (back.includes(find)) throw new Error(`[${id}] TAMPER REFUSED: the original text is STILL present in the written file.`);
  if (back.length === 0) throw new Error(`[${id}] TAMPER REFUSED: the written file is empty.`);
  return out;
}

function buildSql(id, i, sql) {
  const out = path.join(workDir, `${id}__${i}__data.sql`);
  fs.writeFileSync(out, sql);
  const back = fs.readFileSync(out, 'utf8');
  if (back.trim() !== sql.trim()) throw new Error(`[${id}] DATA TAMPER REFUSED: the file did not write back identically.`);
  return out;
}

function resolveChain(id, chain, files) {
  return chain.map((entry, i) => {
    if (typeof entry === 'string') {
      const p = files[entry];
      if (!p) throw new Error(`[${id}] no file named "${entry}" in the spec's \`files\`.`);
      return p;
    }
    if (entry && entry.sql) return buildSql(id, i, entry.sql);
    if (entry && entry.tamper) {
      const p = files[entry.tamper];
      if (!p) throw new Error(`[${id}] no file named "${entry.tamper}" in the spec's \`files\`.`);
      return buildTamper(id, p, entry.find, entry.replace);
    }
    throw new Error(`[${id}] chain entry ${i} is neither a file key, a {sql}, nor a {tamper}.`);
  });
}

// ── One run ─────────────────────────────────────────────────────────────────────────────────
function runChain(chainPaths) {
  try {
    const out = execFileSync('node', [REHEARSE, ...chainPaths],
      { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], maxBuffer: 32 * 1024 * 1024 });
    return { red: false, out };
  } catch (e) {
    return { red: true, out: `${e.stdout || ''}\n${e.stderr || ''}` };
  }
}

// 🔴 A RED THAT IS NOT A CONTROL RESULT MUST NOT BE REPORTED AS ONE. If the rehearser never
//    reached an assertion — no DATABASE_URL, an unreachable host, a refused file — every control
//    goes red for a reason that has nothing to do with the migrations, and the suite reads as a
//    triumph with the negative control as its only honest signal. ▶ READ WHAT THE RED SAYS.
//    Caught on 2026-11-23 by running --self-test from a worktree, whose .env is empty: the
//    harness said "the clean chain did not pass" and suggested the migrations were already
//    applied, when the real cause was a missing credential.
function environmentFailure(out) {
  if (/FAILED\s+[—-]\s+/.test(out)) return null;              // it reached an assertion; real result
  const m = out.match(/^\s*(DATABASE_URL[^\n]*|REFUSED[^\n]*|.*ECONNREFUSED.*|.*ENOTFOUND.*|.*password authentication failed.*|.*SKIPPED:[^\n]*)$/im);
  if (m) return m[1].trim();
  if (/Cannot find module|no such file or directory/i.test(out)) return (out.match(/[^\n]*(?:Cannot find module|no such file or directory)[^\n]*/i) || [])[0].trim();
  return null;
}

// The rehearser prints `FAILED — <gate>: <message>` on an assertion. Parse the gate out of it so a
// control can be recorded by the gate it ACTUALLY fired on.
function parseFailure(out) {
  const m = out.match(/FAILED\s+[—-]\s+([^\n]+)/);
  if (!m) return { gate: '(no FAILED line)', message: '(the run failed without an assertion message — read the output)' };
  const message = m[1].trim();
  const g = message.match(/^((?:P\d+[a-z]?|\d+[a-z]?|incumbency guard))\s*:/);
  return { gate: g ? g[1] : '(unparsed)', message };
}

// ── The suite ───────────────────────────────────────────────────────────────────────────────
async function runSuite(spec) {
  const files = Object.fromEntries(Object.entries(spec.files).map(([k, v]) => [k, path.resolve(v)]));
  for (const [k, v] of Object.entries(files)) {
    if (!fs.existsSync(v)) { console.error(`REFUSED: spec file "${k}" does not exist — ${v}`); return 2; }
  }
  const cleanChain = spec.cleanChain ? spec.cleanChain.map((k) => files[k]) : Object.values(files);

  console.log(`\n══ ${spec.name || 'controls'} — ${spec.controls.length} control(s)`);
  console.log(`   chain: ${cleanChain.map((p) => path.basename(p)).join(' → ')}`);

  // ── --check: build every tamper and run nothing. Touches no database. ──────────────────────
  if (CHECK_ONLY) {
    let bad = 0;
    for (const c of spec.controls) {
      try {
        resolveChain(c.id, c.chain, files);
        const kinds = c.chain.filter((e) => e && e.tamper).length;
        console.log(`   🟢 ${c.id.padEnd(5)} ${kinds} tamper(s) build and are present — ${c.label}`);
      } catch (err) {
        bad++;
        console.error(`   🔴 ${c.id.padEnd(5)} ${err.message.split('\n')[0]}`);
        if (err.message.includes('needle:')) console.error(`         ${err.message.split('\n')[1] || ''}`);
      }
    }
    console.log(bad === 0
      ? `\n   🟢 all ${spec.controls.length} control(s) build. Nothing was run and no database was touched.`
      : `\n   🔴 ${bad} control(s) do NOT build — their needles no longer match the migrations.`);
    return bad === 0 ? 0 : 1;
  }

  // 🔴🔴 THE NEGATIVE CONTROL, FIRST AND THROUGH THE SAME CODE PATH.
  console.log('\n── C0 — the UNTAMPERED chain (negative control; this one must PASS)');
  const neg = runChain(cleanChain);
  if (neg.red) {
    const env = environmentFailure(neg.out);
    if (env) {
      console.error('🔴 REFUSED — the chain never reached an assertion, so this is NOT a control result.');
      console.error(`   ${env}`);
      console.error('\n   ▶ Fix the environment and run again. Nothing below would mean anything:');
      console.error('     every control would go red for a reason that has nothing to do with the migrations.');
      console.error('     (The rehearser needs DATABASE_URL — run from the main checkout, not a worktree.)');
      return 2;
    }
    const { gate, message } = parseFailure(neg.out);
    console.error('🔴 C0 FAILED — the clean chain did not pass, so NO control below would mean anything.');
    console.error(`   fired on: ${gate}`);
    console.error(`   ${message}`);
    console.error('\n   ⚠ If these migrations are already applied, that is the expected answer and this');
    console.error('     suite can no longer be run — a seating file asks "have I already run?" first.');
    return 2;
  }
  console.log('🟢 C0 passed. The harness is not failing everything.');

  const results = [];
  for (const c of spec.controls) {
    if (ONLY && !ONLY.has(c.id)) continue;
    let chainPaths;
    try {
      chainPaths = resolveChain(c.id, c.chain, files);
    } catch (err) {
      console.error(`\n🔴 ${c.id} — ${err.message}`);
      results.push({ ...c, red: false, gate: '(tamper refused)', message: err.message, refused: true });
      continue;
    }
    const r = runChain(chainPaths);
    const { gate, message } = r.red ? parseFailure(r.out) : { gate: '(none)', message: '(the chain PASSED — this control proved nothing)' };
    const backstop = r.red && c.aimedAt && !matchesAim(gate, c.aimedAt);
    results.push({ ...c, red: r.red, gate, message, backstop });

    console.log(`\n${r.red ? '🟢 RED' : '🔴 DID NOT FIRE'}  ${c.id} — ${c.label}`);
    console.log(`      aimed at: ${c.aimedAt || '(unstated)'}`);
    console.log(`      fired on: ${gate}${backstop ? '   ⚠ EARLIER GATE — the aimed-at gate is still UNTESTED' : ''}`);
    console.log(`      ${message}`);
  }

  // ── The ledger ────────────────────────────────────────────────────────────────────────────
  const fired = results.filter((r) => r.red).length;
  const backstops = results.filter((r) => r.backstop);
  console.log('\n══ summary');
  console.log(`   ${fired} of ${results.length} controls went red; the negative control passed.`);
  for (const r of results) {
    const mark = r.red ? (r.backstop ? '⚠' : '🟢') : '🔴';
    console.log(`   ${mark}  ${String(r.gate).padEnd(18)} ${r.id} — ${r.label}`);
  }
  if (backstops.length) {
    console.log('\n   ⚠ These fired on an EARLIER gate than they were aimed at. Each did its job, and the');
    console.log('     gate it was aimed at remains untested — record that rather than contriving around it:');
    for (const r of backstops) console.log(`       ${r.id}: aimed at ${r.aimedAt}, fired on ${r.gate}`);
  }
  const dud = results.filter((r) => !r.red);
  if (dud.length) {
    console.log('\n   🔴 These did NOT go red. A control that cannot trip the comparison tests nothing:');
    for (const r of dud) console.log(`       ${r.id} — ${r.label}${r.refused ? ' (tamper refused — fix the needle)' : ''}`);
    return 1;
  }
  return 0;
}

// A loose match: "P1" matches an aim of "P1 digest"; "3b" matches "assertion 3b".
function matchesAim(gate, aim) {
  const a = String(aim).toLowerCase();
  const g = String(gate).toLowerCase();
  if (g === '(unparsed)' || g === '(no failed line)') return false;
  return new RegExp(`(^|[^0-9a-z])${g.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}([^0-9a-z]|$)`).test(a);
}

// ── Self-test ───────────────────────────────────────────────────────────────────────────────
// 🔴 A TOOL NOBODY HAS WATCHED FAIL IS NOT A TOOL. This builds a throwaway migration with one
//    known gate, proves the negative control passes and a tamper trips that gate, and proves the
//    tamper builder REFUSES a needle that is absent or not unique.
async function selfTest() {
  console.log('── self-test: the harness itself');
  const ok = path.join(workDir, 'selftest_ok.sql');
  fs.writeFileSync(ok, [
    'BEGIN;',
    'DO $$',
    'DECLARE n bigint;',
    'BEGIN',
    '  SELECT count(*) INTO n FROM essentials.politicians;',
    "  IF n < 1 THEN RAISE EXCEPTION 'P1: politicians is empty (%)', n; END IF;",
    "  RAISE NOTICE 'selftest: % politicians', n;",
    'END $$;',
    'COMMIT;',
  ].join('\n'));

  let failures = 0;

  // 1. The tamper builder must REFUSE an absent needle and a non-unique one.
  for (const [what, needle] of [['absent', 'THIS TEXT IS NOT IN THE FILE'], ['non-unique', 'END']]) {
    try {
      buildTamper('selftest', ok, needle, 'x');
      console.error(`🔴 self-test: the tamper builder ACCEPTED a ${what} needle. That is the defect this tool exists to stop.`);
      failures++;
    } catch (err) {
      console.log(`🟢 self-test: tamper builder refused a ${what} needle — ${err.message.split('\n')[0].slice(0, 110)}`);
    }
  }

  // 2. A real tamper must build, and must be present in the written file.
  const tampered = buildTamper('selftest', ok, 'IF n < 1 THEN', 'IF n < 999999999 THEN');
  console.log(`🟢 self-test: tamper built and verified present — ${path.basename(tampered)}`);

  // 3. The negative control must pass and the tamper must fire on P1.
  const code = await runSuite({
    name: 'self-test',
    files: { ok },
    cleanChain: ['ok'],
    controls: [{
      id: 'S1',
      label: 'the politicians gate made impossible to satisfy',
      aimedAt: 'P1',
      chain: [{ tamper: 'ok', find: 'IF n < 1 THEN', replace: 'IF n < 999999999 THEN' }],
    }],
  });
  if (code !== 0) { console.error('🔴 self-test: the suite did not come back clean.'); failures++; }

  console.log(failures === 0
    ? '\n🟢 SELF-TEST PASSED — the builder refuses bad tampers, the negative control passes, and a planted fault fires on the gate it was aimed at.'
    : `\n🔴 SELF-TEST FAILED — ${failures} problem(s) above.`);
  return failures === 0 ? 0 : 1;
}

let exitCode = 2;
try {
  if (SELF_TEST) {
    exitCode = await selfTest();
  } else {
    const mod = await import(pathToFileURL(path.resolve(specPath)).href);
    const spec = mod.default;
    if (!spec || !spec.files || !Array.isArray(spec.controls)) {
      console.error('REFUSED: the spec must default-export { files, controls }.');
      exitCode = 2;
    } else {
      exitCode = await runSuite(spec);
    }
  }
} catch (err) {
  console.error(`REFUSED: ${err.message}`);
  exitCode = 2;
} finally {
  cleanup();
}
process.exit(exitCode);
