#!/usr/bin/env node
/**
 * Fail if a migration added on this branch reuses a numeric prefix.
 *
 * Migrations are applied by filename order (`psql -f` per file, see DEPLOY.md), so two files
 * sharing a prefix have no defined order relative to each other. master already carries 52 such
 * duplicate groups going back to 047 — renaming those would desynchronise filenames from the order
 * they actually ran in, so this guard is deliberately scoped to *newly added* files and says nothing
 * about history.
 *
 * Usage:
 *   node scripts/check-migration-numbers.mjs              # diff against origin/master (or master)
 *   BASE_REF=origin/main node scripts/check-migration-numbers.mjs
 *
 * With no usable git base it falls back to checking for duplicates at or above FLOOR, which is the
 * highest prefix that existed when this guard was written.
 */
import { execFileSync } from "node:child_process";
import { readdirSync } from "node:fs";
import path from "node:path";

const FLOOR = 1419;
const MIGRATIONS_DIR = "backend/migrations";
const NUMBERED = /^(\d+)_/;

const repoRoot = execFileSync("git", ["rev-parse", "--show-toplevel"], { encoding: "utf8" }).trim();
const git = (args) => execFileSync("git", args, { cwd: repoRoot, encoding: "utf8" }).trim();
const tryGit = (args) => {
  try {
    return git(args);
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
  // Files added on this branch relative to where it diverged from base.
  const mergeBase = tryGit(["merge-base", base, "HEAD"]) || base;
  const out = tryGit(["diff", "--diff-filter=A", "--name-only", `${mergeBase}..HEAD`, "--", MIGRATIONS_DIR]);
  const committed = out ? out.split("\n").filter(Boolean) : [];
  // ...plus anything staged or untracked, so the check is useful before you push.
  const staged = tryGit(["diff", "--cached", "--diff-filter=A", "--name-only", "--", MIGRATIONS_DIR]);
  const untracked = tryGit(["ls-files", "--others", "--exclude-standard", "--", MIGRATIONS_DIR]);
  return [...new Set([
    ...committed,
    ...(staged ? staged.split("\n").filter(Boolean) : []),
    ...(untracked ? untracked.split("\n").filter(Boolean) : []),
  ])];
}

function basePrefixes(base) {
  const out = tryGit(["ls-tree", "--name-only", base, `${MIGRATIONS_DIR}/`]);
  if (out === null) return null;
  const map = new Map();
  for (const f of out.split("\n").filter(Boolean)) {
    const p = prefixOf(f);
    if (p) map.set(p, path.basename(f));
  }
  return map;
}

function fallbackCheck() {
  // No git base: flag duplicates at or above FLOOR only, leaving legacy duplicates alone.
  const groups = new Map();
  for (const f of readdirSync(path.join(repoRoot, MIGRATIONS_DIR))) {
    const p = prefixOf(f);
    if (p && Number(p) >= FLOOR) {
      if (!groups.has(p)) groups.set(p, []);
      groups.get(p).push(f);
    }
  }
  return [...groups.entries()]
    .filter(([, files]) => files.length > 1)
    .map(([p, files]) => `  ${p}: ${files.join(", ")}`);
}

const base = resolveBase();
const baseMap = base ? basePrefixes(base) : null;
const problems = [];

if (!baseMap) {
  const dupes = fallbackCheck();
  if (dupes.length) {
    problems.push(`duplicate migration numbers at or above ${FLOOR}:`, ...dupes);
  } else {
    console.log(`No git base available; checked for duplicates >= ${FLOOR} only — clean.`);
  }
} else {
  const added = addedFiles(base).filter((f) => prefixOf(f));
  const seen = new Map();
  for (const f of added.sort()) {
    const p = prefixOf(f);
    const name = path.basename(f);
    if (baseMap.has(p) && baseMap.get(p) !== name) {
      problems.push(`  ${name} reuses prefix ${p}, already taken by ${baseMap.get(p)} on ${base}`);
    }
    if (seen.has(p)) {
      problems.push(`  ${name} collides with ${seen.get(p)} — both added on this branch`);
    }
    seen.set(p, name);
  }
  if (!problems.length) {
    console.log(`Migration numbering OK — ${added.length} added vs ${base} (${baseMap.size} existing prefixes).`);
  } else {
    const next = Math.max(
      ...[...baseMap.keys()].map(Number),
      ...added.map((f) => Number(prefixOf(f))),
      FLOOR - 1,
    ) + 1;
    problems.unshift("Migration number collision in newly added files:");
    problems.push("", `Next free number is ${next}. Rename the new file(s) and re-run:`,
      "  node backend/scripts/check-migration-numbers.mjs");
  }
}

if (problems.length) {
  console.error(problems.join("\n"));
  process.exit(1);
}
