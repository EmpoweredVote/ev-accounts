#!/usr/bin/env node
/**
 * Fail if a migration deletes stance answers without deciding what happens to their context.
 *
 * 🔴 THE DEFECT THIS EXISTS FOR. Between 2026-08-12 and 2026-08-13, seven passes deleted rows from
 * `inform.politician_answers` and left the reasoning in `inform.politician_context` behind -- 1735
 * (judicial scope), 1738/1739 (Berkeley), and the four Maryland chairs passes. Each decision about the
 * ANSWER was correct. None of them made a decision about the CONTEXT, so each silently created
 * ORPHAN_CONTEXT violations: reasoning that still argues a position, now attached to no chair.
 * `ORPHAN_CONTEXT` went 50 -> 224, CI stayed red for 19 runs, and unwinding it took three migrations.
 *
 * 🔑 A SCHEMA CONSTRAINT CANNOT DO THIS JOB, WHICH IS WHY IT IS A LINT. The obvious fix -- an FK or
 * trigger requiring every context row to have an answer -- is WRONG here: 404 rows are
 * context-without-answer BY DESIGN (documented blanks; see project_empty_sources_are_legitimate). The
 * property being enforced is not "context implies answer", it is "whoever removed an answer THOUGHT
 * ABOUT the context". That is a property of the change, not of the data, so it belongs in CI.
 *
 * ⚠ WHY THIS CHECKS FOR THE CARVE-OUT PREDICATE AND NOT MERELY FOR THE WORD "politician_context".
 * 1735 already contained a guard mentioning `politician_context` and a RAISE EXCEPTION -- its guard 2
 * asserted the blanked rows KEPT their context, the OPPOSITE property, and passed green. A looser test
 * would have waved all seven through. So the requirement is that the migration runs the gate's own
 * ORPHAN_CONTEXT predicate, whose regexes are distinctive enough that nobody writes them by accident.
 * Measured against history: of the 51 migrations that delete answers, ZERO satisfy it.
 *
 * WHAT IT CANNOT DO. It reads text, never the database. It cannot tell whether the guard was pointed
 * at the right temp table, or whether a `rewritten-as-blank` claim is true. It makes the author stop
 * and record a decision; check-stance-sources.mjs is what proves the outcome. A green run here means
 * "this migration ran the orphan test", not "this migration is correct".
 *
 * HISTORY IS GRANDFATHERED BY NUMBER, NOT ALLOWLISTED BY NAME. All 51 offenders are already applied to
 * prod, and editing an applied migration desynchronises the file from what actually ran. A 51-entry
 * allowlist would also be read as 51 exceptions rather than one cutoff. FLOOR says plainly: this rule
 * governs migrations written from here on.
 *
 * Usage:
 *   node scripts/check-answer-delete-guards.mjs
 *   node scripts/check-answer-delete-guards.mjs --list    # show every offender incl. grandfathered
 */
import { readdirSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

/**
 * First migration this rule binds on. 1757 is the last one written before the rule existed; everything
 * at or below it predates the guard and is already applied.
 */
const FLOOR = 1758;
const MIGRATIONS_DIR = 'backend/migrations';
const LIST_ALL = process.argv.includes('--list');

/** Deletes from the stance answers table, tolerant of newlines, aliases and USING clauses. */
const DELETES_ANSWERS = /DELETE\s+FROM\s+inform\.politician_answers\b/is;

/**
 * The gate's ORPHAN_CONTEXT carve-out, verbatim. Matching on this rather than on a comment marker is
 * what makes the check load-bearing: you cannot satisfy it without actually running the orphan test.
 * ⚠ If check-stance-sources.mjs ever changes this predicate, change it here too -- they are asserted
 * to agree by the self-test below, so a drift fails this script rather than passing silently.
 */
const ORPHAN_PREDICATE = /no \(scorable \|substantive \|specific \|detailed \)\?public record/i;

/** The stated disposition. Free text after the em dash; the value itself must be one of four. */
const DECISION = /^--\s*@context-decision:\s*(deleted|rewritten-as-blank|kept-already-blank|no-context-rows)\s*[—-]\s*(.+)$/im;
const PLACEHOLDER = /REPLACE THIS with the disposition/i;

const repoRoot = execFileSync('git', ['rev-parse', '--show-toplevel'], { encoding: 'utf8' }).trim();
const dir = path.join(repoRoot, MIGRATIONS_DIR);

// ── SELF-TEST: the predicate above must still be present in the gate and in the template ───────────
// Without this the check can rot into a tautology -- it would keep passing while enforcing a predicate
// the gate no longer uses. Same failure the workstream keeps finding: a tool's gap looks like a clean
// result.
for (const [label, file] of [
  ['the gate', path.join(repoRoot, 'backend/scripts/check-stance-sources.mjs')],
  ['the template', path.join(dir, '_templates/answer_delete_context_guard.sql')],
]) {
  const src = readFileSync(file, 'utf8');
  if (!ORPHAN_PREDICATE.test(src)) {
    console.error(
      `self-test failed: the ORPHAN_CONTEXT predicate this check enforces is no longer in ${label}\n` +
      `  ${path.relative(repoRoot, file)}\n\n` +
      'Either the predicate moved and ORPHAN_PREDICATE here must be updated to match, or the template\n' +
      'no longer contains the guard it is supposed to hand out. Do not "fix" this by loosening the\n' +
      'pattern: a guard enforcing a predicate the gate does not use passes green and protects nothing.',
    );
    process.exit(1);
  }
}

const numberOf = (name) => {
  const m = /^(\d+)_/.exec(name);
  return m ? Number(m[1]) : null;
};

const offenders = [];
for (const name of readdirSync(dir).sort()) {
  if (!name.endsWith('.sql')) continue;
  const n = numberOf(name);
  if (n === null) continue;                      // _verify_*.sql, ad-hoc lookups, _templates/
  const src = readFileSync(path.join(dir, name), 'utf8');
  if (!DELETES_ANSWERS.test(src)) continue;

  const decision = DECISION.exec(src);
  const problems = [];
  if (!decision) {
    problems.push('no `-- @context-decision: <deleted|rewritten-as-blank|kept-already-blank|no-context-rows> — why` line');
  } else if (PLACEHOLDER.test(src)) {
    problems.push('the @context-decision line is still the template placeholder');
  }
  if (!ORPHAN_PREDICATE.test(src)) {
    problems.push("does not run the gate's ORPHAN_CONTEXT predicate against the rows it deleted");
  }

  offenders.push({ name, n, problems, decision: decision?.[1] ?? null });
}
// Numeric, not the lexicographic order readdirSync gives: '248' sorting after '1739' makes the
// grandfathered list read as though something is out of sequence.
offenders.sort((a, b) => a.n - b.n);

const failing = offenders.filter((o) => o.problems.length > 0);
const grandfathered = failing.filter((o) => o.n < FLOOR);
const live = failing.filter((o) => o.n >= FLOOR);

if (LIST_ALL) {
  console.log(`${offenders.length} migration(s) delete from inform.politician_answers:\n`);
  for (const o of offenders) {
    const tag = o.problems.length === 0 ? 'guarded' : o.n < FLOOR ? `grandfathered (<${FLOOR})` : '🔴 UNGUARDED';
    console.log(`  ${String(o.n).padStart(4)}  [${tag}]  ${o.name}${o.decision ? `  → ${o.decision}` : ''}`);
    for (const p of o.problems) if (o.n >= FLOOR) console.log(`          - ${p}`);
  }
  process.exit(0);
}

if (live.length === 0) {
  console.log(
    `Answer-delete context guards OK — ${offenders.length} migration(s) delete stance answers; ` +
    `${offenders.length - failing.length} guarded, ${grandfathered.length} grandfathered below ${FLOOR}.`,
  );
  process.exit(0);
}

console.error('Migration deletes stance answers without deciding what happens to their context:\n');
for (const o of live) {
  console.error(`  ${o.name}`);
  for (const p of o.problems) console.error(`    - ${p}`);
}
console.error(
  '\nDeleting an answer removes the chair; the reasoning that argued for it survives, still asserting\n' +
  'a position, now attached to nothing. It is not published while the pair has no answer -- but write\n' +
  'an answer for that pair later and Citations.jsx renders the old prose verbatim under "Why this\n' +
  'position?". Seven passes did exactly this on 2026-08-12/13 and took ORPHAN_CONTEXT from 50 to 224.\n' +
  '\n' +
  `Paste the guard from ${MIGRATIONS_DIR}/_templates/answer_delete_context_guard.sql, point it at the\n` +
  'temp table holding the pairs you deleted, and state the disposition. If it fires, the pass is\n' +
  'half-finished: either the question does not apply to these people (delete the context, capturing it\n' +
  'first) or it does and the record was read (rewrite it as a documented blank).\n' +
  '\n' +
  '⚠ Do NOT satisfy this by widening the carve-out regex in check-stance-sources.mjs. Widening exempts\n' +
  'rows nobody has read, which is the opposite of what the guard is for.',
);
process.exit(1);
