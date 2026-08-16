#!/usr/bin/env node
/**
 * check-cal-access-predicate.mjs — keep confirm-cal-access.ts from silently coming back to life.
 *
 * 🔴 THE DEFECT THIS EXISTS FOR. Audited 2026-08-16. `confirm-cal-access.ts` links Cal-Access
 * committees to politicians on the LAST SPACE-DELIMITED TOKEN of `full_name` — not on the
 * `last_name` column sitting on the same row. "Gracey Van Der Mark" becomes "mark" and claims 391
 * committees containing the given name Mark; "Jesse Avila Jr" becomes "jr" and claims 116; "Walter
 * Allen III" becomes "iii". Even where the token IS the surname it does not identify a person —
 * "Traci Park" matched Buena Park, Menlo Park and East Bay Regional Park District. Its
 * `hasSignalWord()` guard admits rather than filters, because every candidate committee name
 * contains FOR or COMMITTEE or ELECT. And the script generates and confirms in ONE pass, so nothing
 * independent ever checked it: 7,836 of 7,853 links came back "confirmed", displaying $42.3M.
 *
 * 🔑 WHY A CI CHECK AND NOT JUST A COMMENT. The script is inert only by accident — migration 1463
 * dropped `essentials.offices.politician_id`, which it still joins on, so it throws at runtime.
 * Repairing that join is a one-line change that would re-run the identical predicate at full scale.
 * The abort block in the script is the real guard; this check keeps the abort honest.
 *
 * THE RULE ENFORCED, and it is deliberately narrow:
 *
 *     You may delete the abort ONLY once the last-token rule is gone from the file.
 *
 * So exactly one of these must hold:
 *   (a) the abort is present  — script stays disabled, predicate untouched; or
 *   (b) `parts[parts.length - 1]` no longer appears — the predicate was actually replaced.
 *
 * Deleting the abort while keeping the last-token rule is the one combination that fails, because
 * that is the combination that re-creates the defect. Fixing the predicate and dropping the abort
 * passes, which is the outcome this is trying to reach — it is a ratchet, not a freeze.
 *
 * ⚠ Do NOT satisfy this by renaming the variable or reformatting the slice. If you are here to make
 * the check go green rather than to replace the matching rule, you are re-creating a $42.3M defect.
 */

import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const HERE = dirname(fileURLToPath(import.meta.url));
const TARGET = join(HERE, 'confirm-cal-access.ts');

// The abort's env var. Distinctive enough that nobody writes it by accident.
const ABORT = 'CAL_ACCESS_PREDICATE_REPLACED';
// The defective rule itself, whitespace-insensitive.
const LAST_TOKEN_RULE = /parts\s*\[\s*parts\.length\s*-\s*1\s*\]/;

if (!existsSync(TARGET)) {
  // Deleting the script outright is a legitimate way to retire the defect.
  console.log('Cal-Access predicate OK — confirm-cal-access.ts no longer exists.');
  process.exit(0);
}

/**
 * Strip comments before testing for the rule.
 *
 * ⚠ Learned the hard way: the tripwire block inside confirm-cal-access.ts *documents* the defective
 * rule by quoting it, and the abort message names it too. Matching against the raw file therefore
 * reports the rule as present forever — the ratchet could never open, and someone who correctly
 * replaced the predicate would be told they had not. A guard that can only ever say "still broken"
 * is not a guard. Test the CODE, not the prose describing it.
 */
function stripComments(s) {
  return s.replace(/\/\*[\s\S]*?\*\//g, ' ').replace(/(^|[^:])\/\/[^\n]*/g, '$1');
}

const src = readFileSync(TARGET, 'utf8');
const code = stripComments(src);
const hasAbort = code.includes(ABORT);
const hasLastTokenRule = LAST_TOKEN_RULE.test(code);

if (hasAbort || !hasLastTokenRule) {
  const state = hasAbort
    ? (hasLastTokenRule
        ? 'abort present, last-token rule still in place — script correctly disabled'
        : 'predicate replaced, abort still present — safe to remove the abort now')
    : 'predicate replaced and abort removed — re-enabled deliberately';
  console.log(`Cal-Access predicate OK — ${state}.`);
  process.exit(0);
}

console.error(
  '\nconfirm-cal-access.ts has been re-enabled WITHOUT replacing its matching predicate:\n' +
  '\n' +
  `  - the ${ABORT} abort has been removed\n` +
  '  - but `parts[parts.length - 1]` is still there, so it still matches committees on the\n' +
  '    LAST SPACE-DELIMITED TOKEN of full_name\n' +
  '\n' +
  'That rule turns "Gracey Van Der Mark" into "mark" (391 committees containing the given name\n' +
  'Mark), "Jesse Avila Jr" into "jr" (116), "Walter Allen III" into "iii" (25). It ignores the\n' +
  '`last_name` column on the very same row. Running it again re-creates 7,853 links across 578\n' +
  'active politicians displaying $42.3M — the state audited on 2026-08-16.\n' +
  '\n' +
  'A correct predicate must:\n' +
  '  - match on essentials.politicians.last_name, never on a token split out of full_name;\n' +
  '  - require the given name adjacent to the surname, or corroborate against the Cal-Access\n' +
  '    candidate-name / office / district / year fields — committee_name alone cannot identify\n' +
  '    a person;\n' +
  '  - confirm in a SEPARATE pass using a DIFFERENT test from the one that generated the match.\n' +
  '    This script does both in one pass, which is why 7,836 of 7,853 came back "confirmed".\n' +
  '\n' +
  'See memory `cal_access_lasttoken_mislinks`, migration 1788 (the conflation that surfaced it)\n' +
  'and migration 1789 (bucket-A cleanup).\n'
);
process.exit(1);
