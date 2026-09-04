#!/usr/bin/env node
/**
 * Fail if two migrations share a slot — a slot being a numeric prefix, optionally inside a
 * per-author namespace (see NAMESPACES below).
 *
 * Migrations are applied one at a time by hand; the number is a filename label for humans
 * (see CLAUDE.md). Two files sharing a slot make every cross-reference to that number ambiguous.
 *
 * ── THREE CHECKS, AND WHY EACH IS NEEDED ───────────────────────────────────────────────────────
 *
 * A. **ADDED-VS-CLAIMED** — files added on this branch that reuse a slot claimed anywhere the repo
 *    can see: on the base branch, on ANY remote-tracking ref, or by each other. This is the
 *    pre-push signal and it catches the ordinary mistake.
 *
 * B. **TREE SCAN** — duplicate slots anywhere in the migrations directory, regardless of what git
 *    thinks was "added".
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
 * 🔴 CHECK A NOW READS EVERY REMOTE-TRACKING REF, NOT JUST THE BASE BRANCH.
 * Comparing only against base left a second hole: a number claimed on a colleague's PUSHED but
 * UNMERGED branch was invisible, so the check green-lit taking it. Verified on 2026-08-21 —
 * `1827_austin_travis_offices.sql` was on `origin/feat/austin-tx-deep-seed` and not on master, and
 * the check raised nothing against a fresh file taking 1827. Scanning all of `refs/remotes/` closes
 * the half of this problem a tool CAN see. The other half — two authors both taking the next free
 * number before EITHER pushes — is not observable from any repo state, and is what NAMESPACES are
 * for. A number claimed on an abandoned branch stays claimed; delete the dead remote branch rather
 * than working around the warning.
 *
 * ── NAMESPACES (opt-in, per author) ────────────────────────────────────────────────────────────
 * A filename may carry a leading author namespace: `CA_1849_local_people_role_nullable.sql`.
 * `CA_1849` and `1849` are DIFFERENT slots, so two authors working from their own namespace cannot
 * collide with each other at all, without coordinating on a shared counter — which is the failure
 * mode above. Duplicates WITHIN a namespace are still caught. A namespace is 1–8 alphanumerics
 * starting with a letter, compared case-insensitively.
 *
 * This exists so the option is safe: before it, a `CA_`-prefixed file failed the `^(\d+)_` regex and
 * was silently invisible to BOTH checks. Adopting it is a convention decision, not a tooling one.
 *
 * ── WHY HISTORY IS ALLOWLISTED RATHER THAN RENAMED ─────────────────────────────────────────────
 * master carries ~23 duplicate groups going back to 047. Renaming an applied migration desynchronises
 * its filename from the order it actually ran in, and the number can already be embedded in prod data
 * (`source` columns, COMMENTs — see CLAUDE.md). So known pairs are listed in KNOWN_DUPLICATES with a
 * reason, and anything NOT listed fails. Adding to that list is a deliberate act with a note, not a
 * way to silence the check.
 *
 * FLOOR applies only to un-namespaced slots: legacy history is all un-namespaced, so a namespaced
 * slot is always checked no matter how small its number.
 *
 * Usage:
 *   node scripts/check-migration-numbers.mjs              # diff against origin/master (or master)
 *   BASE_REF=origin/main node scripts/check-migration-numbers.mjs
 *   node scripts/check-migration-numbers.mjs --list-duplicates   # report every duplicate, exit 0
 */
import { execFileSync } from "node:child_process";
import { readdirSync } from "node:fs";
import { slotOf } from "./lib/migration-slots.mjs";
import path from "node:path";

const FLOOR = 1419;
const MIGRATIONS_DIR = "backend/migrations";
// Optional `NS_` author namespace, then the number. The namespace group must start with a letter so
// that `1516_222_fairview_...` still reads as slot 1516, and `generate_md_house.ps1` still reads as
// nothing at all.
const LIST_ONLY = process.argv.includes("--list-duplicates");

/**
 * Duplicate slots that already exist and are NOT being renamed. Keyed by slot; the value is why.
 * Only un-namespaced slots at or above FLOOR need listing — below it, check B does not look.
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

const prefixOf = (file) => slotOf(file)?.key ?? null;
/** Slots below FLOOR are legacy and unchecked by the tree scan — but only un-namespaced ones. */
const belowFloor = (slot) => slot.ns === "" && Number(slot.num) < FLOOR;

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
 * Every ref worth scanning, minus the trailing-HEAD symrefs that just alias another entry.
 *
 * 🔴 refs/heads/ IS NOT OPTIONAL, AND LEAVING IT OUT COST US CC_0045 AND CC_0046.
 * This scanned `refs/remotes/` alone until 2026-09-02. That is blind to any
 * branch that has not been pushed — and this repo is checked out as SEVERAL GIT
 * WORKTREES (EV-Accounts, ev-accounts-coverage, ev-accounts-knight), each
 * sitting on its own local branch, all sharing one object store. Work commits in
 * one worktree and is invisible here until someone pushes it.
 *
 * That is exactly what happened: `knight/ga-5-macon-bibb` took CC_0045/0046/0047
 * at 08:13 in the knight worktree and was never pushed; the compass stream took
 * CC_0045 fifteen minutes later and merged it to master. This script reported
 * "Migration numbering OK" the whole time, with two slots duplicated and BOTH
 * SIDES ALREADY APPLIED TO PROD.
 *
 * Local refs are cheap to include and the label() helper below already strips
 * the refs/heads/ prefix — the enumeration was the only thing missing.
 */
function scannableRefs() {
  const out = tryGit(["for-each-ref", "--format=%(refname)", "refs/heads/", "refs/remotes/"]);
  if (!out) return [];
  return out.split("\n").filter(Boolean).filter((r) => !r.endsWith("/HEAD"));
}

const label = (ref) => ref.replace(/^refs\/remotes\//, "").replace(/^refs\/heads\//, "");

/**
 * slot key -> {slot, byName: Map(basename -> Set(ref label))} across the base branch AND every
 * remote-tracking ref. 🔴 byName is a MAP OF NAMES, not a single name: an earlier version used
 * `map.set(prefix, name)`, which silently kept only the last file for a slot and so could never
 * observe that base itself already held a collision. Tracking which refs claim each name is what
 * lets the failure message say *where* the number went.
 *
 * Returns null if no ref could be read at all, so callers can fall back to the tree scan alone.
 */
function claimedSlots(base) {
  const refs = [...new Set([...(base ? [base] : []), ...scannableRefs()])];
  const map = new Map();
  let read = false;
  for (const ref of refs) {
    const out = tryGit(["ls-tree", "--name-only", ref, `${MIGRATIONS_DIR}/`]);
    if (out === null) continue;
    read = true;
    for (const f of out.split("\n").filter(Boolean)) {
      const slot = slotOf(f);
      if (!slot) continue;
      const name = path.basename(f);
      if (!map.has(slot.key)) map.set(slot.key, { slot, byName: new Map() });
      const { byName } = map.get(slot.key);
      if (!byName.has(name)) byName.set(name, new Set());
      byName.get(name).add(label(ref));
    }
  }
  return read ? map : null;
}

/** Every duplicate slot group in the working tree, whatever its number. */
function treeDuplicates() {
  const groups = new Map();
  for (const f of readdirSync(path.join(repoRoot, MIGRATIONS_DIR))) {
    const slot = slotOf(f);
    if (!slot) continue;
    if (!groups.has(slot.key)) groups.set(slot.key, { slot, files: [] });
    groups.get(slot.key).files.push(f);
  }
  return [...groups.values()]
    .filter(({ files }) => files.length > 1)
    .map(({ slot, files }) => ({ slot, files: files.sort() }))
    .sort((a, b) => a.slot.ns.localeCompare(b.slot.ns) || Number(a.slot.num) - Number(b.slot.num));
}

/**
 * Lowest free number in `ns`, counting every claim the repo can see plus anything added here.
 * Namespaced counters start at 1; the shared un-namespaced one never goes below FLOOR.
 */
function nextFree(ns, claimed, added) {
  const nums = [];
  for (const { slot } of (claimed?.values() ?? [])) if (slot.ns === ns) nums.push(Number(slot.num));
  for (const f of added) {
    const slot = slotOf(f);
    if (slot && slot.ns === ns) nums.push(Number(slot.num));
  }
  return Math.max(ns === "" ? FLOOR - 1 : 0, ...nums) + 1;
}

const allDupes = treeDuplicates();
const base = resolveBase();
const claimed = claimedSlots(base);

if (LIST_ONLY) {
  console.log(`${allDupes.length} duplicate slot group(s) in ${MIGRATIONS_DIR}:`);
  for (const { slot, files } of allDupes) {
    const known = KNOWN_DUPLICATES[slot.key];
    const tag = belowFloor(slot) ? "below FLOOR" : known ? "allowlisted" : "🔴 UNEXPECTED";
    console.log(`  ${slot.key.padStart(6)}  [${tag}]  ${files.join(", ")}`);
    if (known) console.log(`        ${known}`);
  }
  // Informational only: slots claimed by different filenames on different refs. These are NOT
  // failures here — check A fails them for whoever is adding one — but they are invisible in a
  // single working tree, so listing them is the only way to notice they exist.
  const crossRef = [...(claimed?.values() ?? [])]
    .filter(({ slot, byName }) => byName.size > 1 && !belowFloor(slot) && !KNOWN_DUPLICATES[slot.key])
    .sort((a, b) => Number(a.slot.num) - Number(b.slot.num));
  console.log(`\n${crossRef.length} slot(s) claimed by different filenames across refs:`);
  for (const { slot, byName } of crossRef) {
    console.log(`  ${slot.key}`);
    for (const [name, refs] of [...byName].sort()) console.log(`      ${name}  (${[...refs].sort().join(", ")})`);
  }
  process.exit(0);
}

const problems = [];

// ── CHECK B: tree scan (always runs) ───────────────────────────────────────────────────────────
const unexpected = allDupes.filter(({ slot }) => !belowFloor(slot) && !KNOWN_DUPLICATES[slot.key]);
for (const { slot, files } of unexpected) {
  problems.push(`  ${slot.key}: ${files.join(", ")}`);
}
if (unexpected.length) {
  problems.unshift(`Duplicate migration slots in the working tree (tree scan):`);
  problems.push(
    "",
    "This fires even when git shows nothing 'added' — which is exactly how the 1681 collision hid.",
    "Rename the newer file to the next free number, or, if it is already applied to prod and renaming",
    "would desync the filename from its apply order, add it to KNOWN_DUPLICATES with a reason.",
    "",
  );
}

// ── CHECK A: added-vs-claimed (base + every remote-tracking ref) ───────────────────────────────
if (!claimed) {
  if (!unexpected.length) {
    console.log(`No refs available to compare against; tree scan only — no unexpected duplicate slots.`);
  }
} else {
  const added = addedFiles(base).filter((f) => prefixOf(f));
  const seen = new Map();
  const aProblems = [];
  let firstNs = null;
  for (const f of added.sort()) {
    const slot = slotOf(f);
    const name = path.basename(f);
    const entry = claimed.get(slot.key);
    for (const [other, refs] of entry?.byName ?? []) {
      // Skip my own filename: once this branch is pushed it appears on a remote-tracking ref too,
      // and matching it against itself would fail the check forever after the first push.
      if (other === name) continue;
      aProblems.push(`  ${name} reuses slot ${slot.key}, already taken by ${other} on ${[...refs].sort().join(", ")}`);
      firstNs ??= slot.ns;
    }
    if (seen.has(slot.key)) {
      aProblems.push(`  ${name} collides with ${seen.get(slot.key)} — both added on this branch`);
      firstNs ??= slot.ns;
    }
    seen.set(slot.key, name);
  }
  if (aProblems.length) {
    problems.push("Migration slot collision in newly added files:", ...aProblems);
    const ns = firstNs ?? "";
    const next = nextFree(ns, claimed, added);
    problems.push("", `Next free number in ${ns ? `namespace ${ns}` : "the shared sequence"} is ${next}. Rename and re-run this check.`);
  } else if (!problems.length) {
    const allowed = Object.keys(KNOWN_DUPLICATES).length;
    const refCount = new Set([...(base ? [base] : []), ...scannableRefs()]).size;
    console.log(
      `Migration numbering OK — ${added.length} added vs ${base}; ` +
      `${claimed.size} slots claimed across ${refCount} ref(s); tree scan clean ` +
      `(${allowed} allowlisted duplicate${allowed === 1 ? "" : "s"}).`
    );
  }
}

if (problems.length) {
  console.error(problems.join("\n"));
  process.exit(1);
}
