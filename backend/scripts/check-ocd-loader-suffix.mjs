#!/usr/bin/env node
/**
 * check-ocd-loader-suffix.mjs — the static half of the OCD-ID suffix guard.
 *
 * Dependency-free (no `npm ci`, no database), so it lives as a step in the `static guards` job and
 * runs on every push and PR. Its companion `check:ocd-suffixes` checks the DATA and needs a
 * database; this one checks the CODE that writes it.
 *
 * 🔴 WHY BOTH. The data check gates the END STATE, which is the rule — but it can only fail AFTER
 * a bad load has run, and the loads here are ad-hoc: someone runs the loader by hand against
 * production. This one fails on the pull request that would cause it. Neither replaces the other.
 *
 * ── WHAT IT ASSERTS ──────────────────────────────────────────────────────────────────────────
 *
 * In `scripts/load-state-tiger-boundaries.ts`, the OCD-ID for the `sldu`/`sldl` layers must be
 * built from `ocdDistrictSuffix(...)` and must NOT be built from a bare `parseInt` of the district
 * code. `parseInt('01A', 10)` is `1`, and that silently dropped letter is the entire defect:
 * Minnesota's 134 House districts collapsed to 67 in a dry run, and Maryland shipped 84 damaged
 * rows across two tables before `CC_0113` repaired them on 2026-09-16.
 *
 * ⚠ THIS IS A TEXT CHECK AND IT KNOWS IT. It cannot prove the suffix is correct — that is what
 *   `ocdDistrictSuffix.test.ts`'s 13 cases and the data guard are for. It proves only that the
 *   ONE rule with ONE correct definition is still being called, and that the specific wrong idiom
 *   has not come back. A text check that overreaches becomes a text check people delete.
 *
 *   npm run check:ocd-loader --prefix backend
 */
import { readFileSync, existsSync } from 'node:fs';
import path from 'node:path';

const LOADER = path.join(import.meta.dirname, 'load-state-tiger-boundaries.ts');
const HELPER = path.join(import.meta.dirname, '..', 'src', 'lib', 'ocdDistrictSuffix.ts');

const problems = [];

// ── 0. The positive control. A scan of a file that is not there finds nothing, and would pass. ──
for (const [label, file] of [['loader', LOADER], ['helper', HELPER]]) {
  if (!existsSync(file)) {
    problems.push(
      `the ${label} ${path.relative(process.cwd(), file)} does not exist. This guard reads it by ` +
        `path, so a rename makes every check below vacuous — point it at the new path rather than ` +
        `letting it pass on a missing file.`,
    );
  }
}

if (!problems.length) {
  const src = readFileSync(LOADER, 'utf8');

  // Comments are BLANKED, not deleted, so reported line numbers still match the real file. The
  // first draft deleted them and reported line 1832 for a call on line 1912.
  const code = src
    .replace(/\/\*[\s\S]*?\*\//g, (m) => m.replace(/[^\n]/g, ' '))
    .split('\n')
    .map((l) => l.replace(/\/\/.*$/, ''))
    .join('\n');

  // 1. The helper must be imported and called.
  if (!/\bocdDistrictSuffix\s*\(/.test(code)) {
    problems.push(
      `load-state-tiger-boundaries.ts never calls ocdDistrictSuffix(). The OCD-ID suffix rule has ` +
        `exactly one correct definition and it lives in src/lib/ocdDistrictSuffix.ts — inlining it ` +
        `again is how 'parseInt(districtNum, 10)' survived long enough to reach Maryland.`,
    );
  }

  // 2. 🔴 SCOPED TO THE sldu/sldl CASE, AND THAT SCOPE IS THE POINT. The first draft scanned the
  //    whole file and flagged `parseInt(districtNum ?? '0', 10)` in the `cd` case — where it is
  //    CORRECT, because congressional district codes are plain numbers ('01', '00' = at-large).
  //    A guard that fires on correct code is a guard that gets deleted. Only the state-legislative
  //    branch is subject to the letter rule.
  const start = code.search(/^\s*case\s+'sldu':/m);
  if (start < 0) {
    problems.push(
      `load-state-tiger-boundaries.ts has no \`case 'sldu':\` branch. This guard locates the ` +
        `state-legislative OCD-ID derivation by that label, so a restructure makes it vacuous — ` +
        `re-point it rather than leaving it to pass on a branch it can no longer find.`,
    );
  } else {
    // The branch runs to the next case label at the same level (sldl shares the sldu body).
    const rest = code.slice(start);
    const nextCase = rest.search(/^\s*(?:case\s+'(?!sldl')[^']*':|default:)/m);
    const block = nextCase > 0 ? rest.slice(0, nextCase) : rest;
    const lineOffset = code.slice(0, start).split('\n').length;

    if (!/\bocdDistrictSuffix\s*\(/.test(block)) {
      problems.push(
        `the sldu/sldl branch does not call ocdDistrictSuffix(). That branch is the one subject to ` +
          `the trailing-letter rule — MN is '01A'..'67B', MD's delegates are 1A/1B/1C, and ND/SD ` +
          `use subdistricts too.`,
      );
    }

    const badIdiom = /parseInt\s*\(/;
    for (const [i, line] of block.split('\n').entries()) {
      if (badIdiom.test(line)) {
        problems.push(
          `load-state-tiger-boundaries.ts:${lineOffset + i} uses parseInt inside the sldu/sldl ` +
            `branch: "${line.trim().slice(0, 90)}". parseInt('01A', 10) is 1 — the letter is ` +
            `dropped and 1A/1B/1C collapse onto one OCD-ID. Use ocdDistrictSuffix().`,
        );
      }
    }
  }
}

if (problems.length) {
  console.error(`✗ OCD-ID loader guard: ${problems.length} problem(s)`);
  for (const p of problems) console.error(`    - ${p}`);
  process.exit(1);
}

console.log('OCD-ID loader guard OK — the SLD suffix is derived via ocdDistrictSuffix(), not parseInt.');
