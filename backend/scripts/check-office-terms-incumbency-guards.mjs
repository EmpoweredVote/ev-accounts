#!/usr/bin/env node
/**
 * Fail if a migration writes essentials.office_terms without deciding what that does to incumbency.
 *
 * 🔴 THE DEFECT THIS EXISTS FOR. On 2026-11-11 CC_0394 put dates on 290 tenures and turned MASTER CI
 * red on `check:incumbency`. That gate rides the `reachability` job, which carries
 * `if: github.event_name != 'pull_request'` -- so it runs on push, schedule and manual dispatch and
 * NEVER on a pull request. It therefore did not fail on the PR that caused it. It failed on the NEXT
 * one, under somebody else's name. Six rows from CC_0394, a seventh when CC_0395 sharpened Allen TX's
 * mayor from "May 2026" to a real day, and CC_0396 to settle them three migrations downstream.
 *
 * 🔑 THE MECHANISM, AND IT IS NOT OBVIOUS FROM THE DIFF. `race_candidates.is_incumbent` means
 * "incumbent OF THE SEAT THIS RACE IS FOR, measured on the race's own election date". It is CACHED and
 * nothing recomputes it. So writing a `term_start` silently restates who held that seat on every
 * election day the term no longer covers, while the cached column still says what it said yesterday.
 * A migration can do this while touching no table any reviewer associates with elections.
 *
 * 🔑 THIS IS THE MASTER-ONLY-GATE RULE WEARING A LINT. CLAUDE.md: "a master-only gate cannot vet the
 * merge that trips it ... carry the check into the migration's own post-verify, as a delta, if you
 * need it to block the guilty change." `check:incumbency` reads live production data, so it cannot
 * run on a PR against a database the PR has not touched. This check reads TEXT, needs no database,
 * and runs on every PR -- it does not measure incumbency, it asks whether the author measured it.
 *
 * ⚠ WHY IT DEMANDS THE DELTA SNAPSHOT AND NOT MERELY THE WORDS "is_incumbent". A migration can
 * mention that column, or even assert something about it, and still never ask the question: the first
 * draft of the template reported only its scoped row count, so a plan table pointed at the wrong
 * column read "0 in scope" -- byte-identical to a legitimately race-less plan, with the gate switched
 * off. So what is required is `incumbency_before` plus BOTH halves of the before/after comparison.
 * Without a before-snapshot there is no delta, and a check on the TOTAL fails on other people's drift
 * (its first measurement found 429 rows of which 9 were real) and would push its author to "fix" rows
 * nobody had read.
 *
 * WHAT IT CANNOT DO. It reads text, never the database. It cannot tell whether the gate was pointed at
 * the right plan table -- the gate's own NOTICE and its empty-plan EXCEPTION are what cover that -- and
 * it cannot tell whether a `no-effect` claim is true. A green run here means "this migration asked the
 * question", not "this migration is correct".
 *
 * HISTORY IS GRANDFATHERED BY NUMBER, PLUS A RULE THE NUMBER CANNOT EXPRESS. 253 applied migrations
 * write office_terms, and editing an applied migration desynchronises the file from what actually ran.
 * But a floor alone leaves a hole: slots are RESERVED long before their file is written, and
 * `CC_0340` ("2026-11-03 US Senate: seat winners at 2027-01-03") sits reserved and unwritten BELOW
 * every floor while being exactly the kind of migration this governs. So a file ADDED on this branch
 * binds whatever its number is; the floors only excuse files that are already on the base.
 *
 * Usage:
 *   node scripts/check-office-terms-incumbency-guards.mjs
 *   node scripts/check-office-terms-incumbency-guards.mjs --list   # every writer incl. grandfathered
 */
import { readdirSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

/**
 * First migration this rule binds on, per namespace: one past the highest slot in use when the rule
 * landed (shared 1950, CA 373, CC 396 on 2026-11-11). A namespace missing here binds from its first.
 *
 * 🔴 DO NOT RAISE A FLOOR TO CLEAR A RED. A floor excuses migrations written before the rule existed.
 * Raising one excuses a migration written after it, which is the thing the rule is for.
 */
const FLOORS = { '': 1951, CA: 374, CC: 397 };
const floorOf = (ns) => FLOORS[ns] ?? 1;
const MIGRATIONS_DIR = 'backend/migrations';
const LIST_ALL = process.argv.includes('--list');

/**
 * What counts as a write that can move an incumbency answer. Each of these changes which election
 * days essentials.office_terms says a person covered.
 *
 * ⚠ An UPDATE is only caught when it ASSIGNS term_start or term_end. Appending provenance to `source`,
 * or correcting `start_precision`, cannot change who held a seat on a date, and making those trip the
 * check would train people to wave it through. The SET-list scan stops at FROM/WHERE/RETURNING/; so a
 * `term_start` appearing in a WHERE clause is not an assignment -- the same shape
 * check-office-occupancy.mjs uses for its own UPDATE pattern.
 */
const WRITES = [
  ['inserts a term', /INSERT\s+INTO\s+essentials\.office_terms\b/is],
  ['deletes a term', /DELETE\s+FROM\s+essentials\.office_terms\b/is],
  ['assigns term_start/term_end',
    /UPDATE\s+essentials\.office_terms\b[\s\S]{0,200}?\bSET\b(?:(?!\bFROM\b|\bWHERE\b|\bRETURNING\b|;)[\s\S])*?(?:^|[^\w.])(?:term_start|term_end)\s*=/is],
  ['calls seat_officeholder()', /\bessentials\.seat_officeholder\s*\(/is],
  ['calls vacate_office()', /\bessentials\.vacate_office\s*\(/is],
];

/**
 * The multi-seat half of reconcile-incumbency.mjs's expected-value predicate, verbatim. Requiring it
 * is what stops someone pasting a simplified gate: the seat-only rule called 128 sitting members
 * challengers on 2026-11-07 and turned master red on CC_0364's four board members, which is why the
 * chamber clause exists at all.
 * ⚠ If the script's predicate changes, change this too -- the self-test below asserts they agree, so a
 * drift fails this check rather than passing silently.
 */
const MULTISEAT_RULE = /r\.seats\s*>\s*1\s+AND\s+ro\.chamber_id\s+IS\s+NOT\s+NULL\s+AND\s+o2\.chamber_id\s*=\s*ro\.chamber_id/i;

/** The before-snapshot and both halves of the comparison. No before-snapshot, no delta. */
const GATE_PARTS = [
  ['the before-snapshot table `incumbency_before`', /\bincumbency_before\b/],
  ['the `drifted_before` half of the comparison', /\bdrifted_before\b/],
  ['the `drifted_after` half of the comparison', /\bdrifted_after\b/],
  ["reconcile-incumbency.mjs's multi-seat chamber rule", MULTISEAT_RULE],
];

/** The stated disposition. Free text after the dash; the value must be one of two. */
const DECISION = /^--\s*@incumbency-decision:\s*(gated|no-effect)\s*[—-]\s*(.+)$/im;
const PLACEHOLDER = /REPLACE THIS with the disposition/i;

const repoRoot = execFileSync('git', ['rev-parse', '--show-toplevel'], { encoding: 'utf8' }).trim();
const dir = path.join(repoRoot, MIGRATIONS_DIR);
const TEMPLATE = path.join(dir, '_templates/office_terms_incumbency_guard.sql');

// ── SELF-TEST ─────────────────────────────────────────────────────────────────────────────────────
// Without this the check can rot into a tautology: it would keep demanding a predicate the reconciler
// no longer uses, and keep passing, while enforcing nothing. Same failure this workstream keeps
// finding -- a tool's blind spot looks exactly like a clean result.
for (const [label, file, re, what] of [
  ['the reconciler', path.join(repoRoot, 'backend/scripts/reconcile-incumbency.mjs'), MULTISEAT_RULE, 'multi-seat chamber rule'],
  ['the template', TEMPLATE, MULTISEAT_RULE, 'multi-seat chamber rule'],
  ['the template', TEMPLATE, /\bincumbency_before\b/, 'before-snapshot table'],
  ['the template', TEMPLATE, /\bdrifted_after\b/, 'before/after comparison'],
]) {
  let src;
  try {
    src = readFileSync(file, 'utf8');
  } catch {
    console.error(`self-test failed: ${label} is missing — ${path.relative(repoRoot, file)}`);
    process.exit(1);
  }
  if (!re.test(src)) {
    console.error(
      `self-test failed: the ${what} this check enforces is no longer in ${label}\n` +
      `  ${path.relative(repoRoot, file)}\n\n` +
      'Either it moved and this script must be updated to match, or the template no longer hands out\n' +
      'the gate it is supposed to. Do NOT loosen the pattern: a lint enforcing a predicate nothing\n' +
      'else uses passes green and protects nothing.',
    );
    process.exit(1);
  }
}

/** `1758_x.sql` -> { ns: '', n: 1758 }; `CC_0037_x.sql` -> { ns: 'CC', n: 37 }; anything else -> null. */
const slotOf = (name) => {
  const m = /^(?:([A-Z]+)_)?(\d+)_/.exec(name);
  return m ? { ns: m[1] ?? '', n: Number(m[2]) } : null;
};
const labelOf = (o) => (o.ns ? `${o.ns}_${String(o.n).padStart(4, '0')}` : String(o.n));

/** SQL `--` comments removed, so a migration that only QUOTES a write in prose is not counted. */
const stripLineComments = (sql) => sql.replace(/--[^\n]*/g, '');

/**
 * Files added on this branch. A slot is RESERVED long before its file is written, so a reserved number
 * below a floor would otherwise arrive grandfathered — CC_0340 is exactly that, reserved for "seat the
 * 2026-11-03 US Senate winners" and unwritten. An added file binds whatever its number is.
 * On a push the base resolves to HEAD, so this set is empty and the floors do the work alone.
 */
function addedOnThisBranch() {
  const base = process.env.BASE_REF || 'origin/master';
  const names = new Set();
  const opts = { encoding: 'utf8', cwd: repoRoot, maxBuffer: 16 * 1024 * 1024 };
  const take = (out, strip) => {
    for (const line of out.split('\n')) {
      // ⚠ `--porcelain` reports MODIFIED files too, and a modified old migration is not a new one.
      // Only untracked (`??`) and staged-add (`A*`) mean "this file is not on the base". Counting a
      // ` M` would bind a migration applied years ago because someone fixed a typo in its header.
      if (strip && !/^(\?\?|A)/.test(line)) continue;
      const raw = strip ? line.slice(3) : line;
      const name = path.basename(raw.trim().replace(/^"|"$/g, ''));
      // Slot-bearing names only: `_templates/` and `_verify_*.sql` are never checked, so counting
      // them here would report "N added migration(s) bind" over files this script does not look at.
      if (name.endsWith('.sql') && slotOf(name) !== null) names.add(name);
    }
  };
  // Committed on the branch. This is what CI sees.
  try {
    take(execFileSync('git', ['diff', '--name-only', '--diff-filter=A', `${base}...HEAD`, '--', MIGRATIONS_DIR], opts), false);
  } catch { /* no base ref — shallow clone, fork, detached tree. Fall back to the floors. */ }
  // 🔴 AND NOT YET COMMITTED. A control planting a `CC_0340_*.sql` file below every floor passed
  // green until this existed: `git diff` compares COMMITS, so a migration you are still writing was
  // invisible and arrived grandfathered. The whole point of this clause is reserved slots — numbers
  // taken months before their file — so it has to see the file on disk, not only in history.
  try {
    take(execFileSync('git', ['status', '--porcelain', '--', MIGRATIONS_DIR], opts), true);
  } catch { /* same */ }
  return names;
}
const added = addedOnThisBranch();

const writers = [];
for (const name of readdirSync(dir).sort()) {
  if (!name.endsWith('.sql')) continue;
  const slot = slotOf(name);
  if (slot === null) continue;                   // _verify_*.sql, ad-hoc lookups, _templates/
  const src = readFileSync(path.join(dir, name), 'utf8');
  const body = stripLineComments(src);

  const kinds = WRITES.filter(([, re]) => re.test(body)).map(([k]) => k);
  if (kinds.length === 0) continue;

  const decision = DECISION.exec(src);
  const problems = [];
  if (!decision) {
    problems.push('no `-- @incumbency-decision: <gated|no-effect> — why` line');
  } else if (PLACEHOLDER.test(src)) {
    problems.push('the @incumbency-decision line is still the template placeholder');
  }
  if (!decision || decision[1] === 'gated') {
    for (const [what, re] of GATE_PARTS) if (!re.test(src)) problems.push(`is missing ${what}`);
  }

  writers.push({ name, ...slot, kinds, problems, decision: decision?.[1] ?? null });
}
// Shared sequence first, then each namespace, numerically within each — not the lexicographic order
// readdirSync gives, where '248' sorts after '1739' and the list reads as out of sequence.
writers.sort((a, b) => a.ns.localeCompare(b.ns) || a.n - b.n);

const isGrandfathered = (o) => o.n < floorOf(o.ns) && !added.has(o.name);
const failing = writers.filter((o) => o.problems.length > 0);
const grandfathered = failing.filter(isGrandfathered);
const live = failing.filter((o) => !isGrandfathered(o));

if (LIST_ALL) {
  console.log(`${writers.length} migration(s) write essentials.office_terms:\n`);
  for (const o of writers) {
    const floor = o.ns ? `${o.ns}_${floorOf(o.ns)}` : floorOf(o.ns);
    const tag = o.problems.length === 0 ? 'decided'
      : isGrandfathered(o) ? `grandfathered (<${floor})`
      : added.has(o.name) ? '🔴 UNDECIDED (added on this branch)' : '🔴 UNDECIDED';
    console.log(`  ${labelOf(o).padStart(7)}  [${tag}]  ${o.name}${o.decision ? `  → ${o.decision}` : ''}`);
    console.log(`             writes: ${o.kinds.join(', ')}`);
    if (!isGrandfathered(o)) for (const p of o.problems) console.log(`             - ${p}`);
  }
  process.exit(0);
}

if (live.length === 0) {
  const floors = Object.entries(FLOORS).map(([ns, n]) => (ns ? `${ns}_${n}` : n)).join(', ');
  // Count added WRITERS, not added migrations. "1 added migration binds" over a file this check never
  // looked at is the shape of a guard reporting coverage it does not have.
  const addedWriters = writers.filter((o) => added.has(o.name)).length;
  console.log(
    `Office-terms incumbency guards OK — ${writers.length} migration(s) write essentials.office_terms; ` +
    `${writers.length - failing.length} decided, ${grandfathered.length} grandfathered below ${floors}` +
    `${addedWriters ? `; ${addedWriters} added on this branch, binding regardless of number` : ''}.`,
  );
  process.exit(0);
}

console.error('Migration writes essentials.office_terms without deciding what that does to incumbency:\n');
for (const o of live) {
  console.error(`  ${o.name}  (${o.kinds.join(', ')})`);
  for (const p of o.problems) console.error(`    - ${p}`);
}
console.error(
  '\n`race_candidates.is_incumbent` means "incumbent OF THE SEAT THIS RACE IS FOR, on the race\'s own\n' +
  'election date". It is CACHED and nothing recomputes it, so writing a term date silently restates\n' +
  'who held that seat on every election day the term no longer covers. `check:incumbency` catches the\n' +
  'contradiction, but it runs on push and the schedule only, NEVER on a PR — so it fails on the next\n' +
  "merge under somebody else's name. CC_0394 did exactly this: 290 dates, 6 red rows, a 7th from\n" +
  'CC_0395, and CC_0396 to settle them three migrations later.\n' +
  '\n' +
  `Paste the delta gate from ${MIGRATIONS_DIR}/_templates/office_terms_incumbency_guard.sql, point it\n` +
  'at the politicians whose term rows you write — BOTH SIDES of a seating, because seat_officeholder()\n' +
  'closes the predecessor for you — and add:\n' +
  '\n' +
  '  -- @incumbency-decision: gated — <what this migration writes, and to whom>\n' +
  '\n' +
  'If it fires, read the person rather than reaching for `reconcile-incumbency.mjs --apply`, which\n' +
  'reads only the predicate: on those seven rows it would have published three sitting officeholders\n' +
  'as challengers for their own seats. A NEWCOMER means the date is right and the race row is stale; a\n' +
  "RE-ELECTED member means the race row is right and you have written their latest term's start as the\n" +
  "start of their whole tenure. CC_0396's header works the split.\n" +
  '\n' +
  'The other disposition, for a write that cannot move an incumbency answer:\n' +
  '\n' +
  '  -- @incumbency-decision: no-effect — <why>\n' +
  '\n' +
  'It is a claim a reviewer can check, so make it a checkable one. The two legitimate shapes are: every\n' +
  'office this touches is BRAND NEW and carries no race, or the rows written cover the same election\n' +
  'days they covered before. "There are probably no recent races" is not one of them — that is the\n' +
  "question the gate's own NOTICE answers, in numbers, at apply time.",
);
process.exit(1);
