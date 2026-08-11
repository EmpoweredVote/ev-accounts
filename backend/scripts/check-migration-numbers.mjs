#!/usr/bin/env node
/**
 * Fail if two migrations share a numeric prefix.
 *
 * Migrations are applied by filename order (`psql -f` per file, see DEPLOY.md), so two files sharing
 * a prefix have no defined order relative to each other.
 *
 * ── TWO CHECKS, AND WHY BOTH ARE NEEDED ────────────────────────────────────────────────────────
 *
 * A. **ADDED-VS-BASE** — files added on this branch that reuse a prefix already on base, or each
 *    other's. This is the pre-push signal and it catches the ordinary mistake.
 *
 * B. **TREE SCAN** — duplicates at or above FLOOR anywhere in the migrations directory, regardless of
 *    what git thinks was "added".
 *
 * 🔴 CHECK B EXISTS BECAUSE CHECK A HAS A BLIND SPOT THAT LET A REAL COLLISION THROUGH.
 * On 2026-08-10 two parallel sessions both took 1681 (`1681_repoint_ca_municipal_urls_caveats_cleared`
 * and `1681_retire_md_chrome_only_stances`). Each ran this check before committing and each was told
 * "Migration numbering OK", because at the moment each ran, the other file was not yet on
 * `origin/master`. Once BOTH were pushed, `merge-base == HEAD`, so `--diff-filter=A` reported ZERO
 * added files and check A had nothing left to compare — the collision became permanently invisible to
 * it. Check B previously existed only as a FALLBACK for when no git base could be resolved, i.e. it
 * ran in the one situation this repo never hits. It now always runs.
 *
 * That failure is not exotic: it is the ordinary consequence of two long-lived sessions in a shared
 * worktree, which is how this repo is worked. A check whose green light depends on *when* you ran it
 * relative to someone else's push is not a check.
 *
 * ── WHY HISTORY IS ALLOWLISTED RATHER THAN RENAMED ─────────────────────────────────────────────
 * master carries ~23 duplicate groups going back to 047. Renaming an applied migration desynchronises
 * its filename from the order it actually ran in, and the number can already be embedded in prod data
 * (`source` columns, COMMENTs — see CLAUDE.md). So known pairs are listed in KNOWN_DUPLICATES with a
 * reason, and anything NOT listed fails. Adding to that list is a deliberate act with a note, not a
 * way to silence the check.
 *
 * Usage:
 *   node scripts/check-migration-numbers.mjs              # diff against origin/master (or master)
 *   BASE_REF=origin/main node scripts/check-migration-numbers.mjs
 *   node scripts/check-migration-numbers.mjs --list-duplicates   # report every duplicate, exit 0
 */
import { execFileSync } from "node:child_process";
import { readdirSync } from "node:fs";
import path from "node:path";

const FLOOR = 1419;
const MIGRATIONS_DIR = "backend/migrations";
const NUMBERED = /^(\d+)_/;
const LIST_ONLY = process.argv.includes("--list-duplicates");

/**
 * Duplicate prefixes that already exist and are NOT being renamed. Keyed by prefix; the value is why.
 * Only pairs at or above FLOOR need listing — below it, check B does not look.
 */
const KNOWN_DUPLICATES = {
  1527: "pre-existing pair (repair_prose_in_sources / repair_split_sources); both applied, renaming would desync filename from apply order",
  1681: "2026-08-10: two parallel sessions each took 1681 (repoint_ca_municipal_urls_caveats_cleared / retire_md_chrome_only_stances). Both applied to prod before either was pushed. This is the collision that motivated check B",
};

const repoRoot = execFileSync("git", ["rev-parse", "--show-toplevel"], { encoding: "utf8" }).trim();
const git = (args) => execFileSync("git", args, { cwd: repoRoot, encoding: "utf8" }).trim();
// stderr is swallowed on purpose: a missing ref is an expected outcome here, and letting git print
// `fatal: Not a valid object name ...` makes a clean run look like a failure.
const tryGit = (args) => {
  try {
    return execFileSync("git", args, { cwd: repoRoot, encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim();
  } catch {
    return null;
  }
};

const prefixOf = (file) => {
  const m = NUMBERED.exec(path.basename(file));
  return m ? m[1].replace(/^0+(?=\d)/, "") : null;   // '047' and '47' are the same slot
};

function resolveBase() {
  if (process.env.BASE_REF) return process.env.BASE_REF;
  for (const ref of ["origin/master", "origin/main", "master", "main"]) {
    if (tryGit(["rev-parse", "--verify", "--quiet", ref])) return ref;
  }
  return null;
}

function addedFiles(base) {
  const mergeBase = tryGit(["merge-base", base, "HEAD"]) || base;
  const out = tryGit(["diff", "--diff-filter=A", "--name-only", `${mergeBase}..HEAD`, "--", MIGRATIONS_DIR]);
  const committed = out ? out.split("\n").filter(Boolean) : [];
  // ...plus anything staged or untracked, so the check is useful before you commit.
  const staged = tryGit(["diff", "--cached", "--diff-filter=A", "--name-only", "--", MIGRATIONS_DIR]);
  const untracked = tryGit(["ls-files", "--others", "--exclude-standard", "--", MIGRATIONS_DIR]);
  return [...new Set([
    ...committed,
    ...(staged ? staged.split("\n").filter(Boolean) : []),
    ...(untracked ? untracked.split("\n").filter(Boolean) : []),
  ])];
}

/**
 * prefix -> [filenames] on `base`. 🔴 An ARRAY, not a single name: the previous version used
 * `map.set(prefix, name)`, which silently kept only the last file for a prefix and so could never
 * observe that base itself already held a collision.
 */
function basePrefixes(base) {
  const out = tryGit(["ls-tree", "--name-only", base, `${MIGRATIONS_DIR}/`]);
  if (out === null) return null;
  const map = new Map();
  for (const f of out.split("\n").filter(Boolean)) {
    const p = prefixOf(f);
    if (!p) continue;
    if (!map.has(p)) map.set(p, []);
    map.get(p).push(path.basename(f));
  }
  return map;
}

/** Every duplicate group in the working tree, whatever its number. */
function treeDuplicates() {
  const groups = new Map();
  for (const f of readdirSync(path.join(repoRoot, MIGRATIONS_DIR))) {
    const p = prefixOf(f);
    if (!p) continue;
    if (!groups.has(p)) groups.set(p, []);
    groups.get(p).push(f);
  }
  return [...groups.entries()]
    .filter(([, files]) => files.length > 1)
    .map(([p, files]) => ({ prefix: p, files: files.sort() }))
    .sort((a, b) => Number(a.prefix) - Number(b.prefix));
}

const allDupes = treeDuplicates();

if (LIST_ONLY) {
  console.log(`${allDupes.length} duplicate prefix group(s) in ${MIGRATIONS_DIR}:`);
  for (const { prefix, files } of allDupes) {
    const known = KNOWN_DUPLICATES[prefix];
    const tag = Number(prefix) < FLOOR ? "below FLOOR" : known ? "allowlisted" : "🔴 UNEXPECTED";
    console.log(`  ${prefix.padStart(4)}  [${tag}]  ${files.join(", ")}`);
    if (known) console.log(`        ${known}`);
  }
  process.exit(0);
}

const base = resolveBase();
const baseMap = base ? basePrefixes(base) : null;
const problems = [];

// ── CHECK B: tree scan (always runs) ───────────────────────────────────────────────────────────
const unexpected = allDupes.filter(({ prefix }) => Number(prefix) >= FLOOR && !KNOWN_DUPLICATES[prefix]);
for (const { prefix, files } of unexpected) {
  problems.push(`  ${prefix}: ${files.join(", ")}`);
}
if (unexpected.length) {
  problems.unshift(`Duplicate migration numbers at or above ${FLOOR} (tree scan):`);
  problems.push(
    "",
    "This fires even when git shows nothing 'added' — which is exactly how the 1681 collision hid.",
    "Rename the newer file to the next free number, or, if it is already applied to prod and renaming",
    "would desync the filename from its apply order, add it to KNOWN_DUPLICATES with a reason.",
    "",
  );
}

// ── CHECK A: added-vs-base ─────────────────────────────────────────────────────────────────────
if (!baseMap) {
  if (!unexpected.length) {
    console.log(`No git base available; tree scan only — no unexpected duplicates >= ${FLOOR}.`);
  }
} else {
  const added = addedFiles(base).filter((f) => prefixOf(f));
  const seen = new Map();
  const aProblems = [];
  for (const f of added.sort()) {
    const p = prefixOf(f);
    const name = path.basename(f);
    const onBase = (baseMap.get(p) || []).filter((b) => b !== name);
    if (onBase.length) {
      aProblems.push(`  ${name} reuses prefix ${p}, already taken by ${onBase.join(", ")} on ${base}`);
    }
    if (seen.has(p)) {
      aProblems.push(`  ${name} collides with ${seen.get(p)} — both added on this branch`);
    }
    seen.set(p, name);
  }
  if (aProblems.length) {
    problems.push("Migration number collision in newly added files:", ...aProblems);
    const next = Math.max(
      ...[...baseMap.keys()].map(Number),
      ...added.map((f) => Number(prefixOf(f))),
      FLOOR - 1,
    ) + 1;
    problems.push("", `Next free number is ${next}. Rename and re-run this check.`);
  } else if (!problems.length) {
    const allowed = Object.keys(KNOWN_DUPLICATES).length;
    console.log(
      `Migration numbering OK — ${added.length} added vs ${base}; ` +
      `${baseMap.size} prefixes on base; tree scan clean above ${FLOOR} ` +
      `(${allowed} allowlisted duplicate${allowed === 1 ? "" : "s"}).`
    );
  }
}

if (problems.length) {
  console.error(problems.join("\n"));
  process.exit(1);
}
