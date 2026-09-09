/**
 * The shared vocabulary for migration slots.
 *
 * Extracted from check-migration-numbers.mjs on 2026-09-04 so the collision CHECKER
 * and the steward ALLOCATOR cannot drift apart. If the two ever disagree about which
 * file occupies which slot, the allocator will hand out a number the checker already
 * considers taken — the exact failure the steward exists to end.
 *
 * Design: docs/superpowers/specs/2026-09-04-steward-coordination-design.md
 *
 * 🔴 THIS PARSER IS LOAD BEARING. Two rules it encodes are easy to get wrong:
 *   * Leading zeros are stripped, so CA_0001 and CA_1 are the SAME slot.
 *   * The namespace is part of the key, so CA_1500 and 1500 are DIFFERENT slots.
 */
import path from "node:path";
import { execFileSync } from "node:child_process";

/**
 * An optional namespace, an underscore, digits, an underscore. The namespace is 1-8
 * leading alphanumerics so that `1516_222_fairview_...` still reads as slot 1516 and
 * `generate_md_house.ps1` still reads as nothing at all.
 */
const NUMBERED = /^(?:([A-Za-z][A-Za-z0-9]{0,7})_)?(\d+)_/;

/** {ns, num, key} for a migration filename, or null if it is not a numbered migration. */
export function slotOf(file) {
  const m = NUMBERED.exec(path.basename(file));
  if (!m) return null;
  const ns = m[1] ? m[1].toUpperCase() : "";
  const num = m[2].replace(/^0+(?=\d)/, ""); // '047' and '47' are the same slot
  return { ns, num, key: ns ? `${ns}_${num}` : num };
}

/** The slot key alone, or null. Convenient for comparing two filenames. */
export function slotKey(file) {
  return slotOf(file)?.key ?? null;
}

const MIGRATIONS_DIR = "backend/migrations";

function tryGit(cwd, args) {
  try {
    return execFileSync("git", args, { cwd, encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim();
  } catch {
    return null;
  }
}

/**
 * Every ref worth scanning, minus the trailing-HEAD symrefs that just alias another entry.
 *
 * 🔴 refs/heads/ IS NOT OPTIONAL. This repo is checked out as SEVERAL WORKTREES sharing one
 * object store, each on its own local branch. Work committed in one worktree is invisible to
 * the others until someone pushes. Scanning only refs/remotes/ is what let CC_0045 be taken
 * twice on 2026-09-02, with both sides applied to production.
 */
export function scannableRefs(repoRoot) {
  const out = tryGit(repoRoot, ["for-each-ref", "--format=%(refname)", "refs/heads/", "refs/remotes/"]);
  if (!out) return [];
  return out.split("\n").filter(Boolean).filter((r) => !r.endsWith("/HEAD"));
}

const label = (ref) => ref.replace(/^refs\/remotes\//, "").replace(/^refs\/heads\//, "");

/**
 * Every migration slot this repository has ever claimed, on any ref, as rows ready to seed
 * steward.migration_slots: {namespace, num, key, filename, refs}.
 *
 * One row per SLOT, not per file — a slot carried by five refs is still one claimed number.
 * `num` is a Number because the allocator compares and increments it; `slotOf` returns it as
 * a string because the checker uses it as a map key.
 */
/**
 * The base ref to diff against: BASE_REF if CI set it, else the first of these that exists.
 * Returns null when none can be read, so callers can fall back to a tree scan alone.
 */
export function resolveBase(repoRoot) {
  if (process.env.BASE_REF) return process.env.BASE_REF;
  for (const ref of ["origin/master", "origin/main", "master", "main"]) {
    if (tryGit(repoRoot, ["rev-parse", "--verify", "--quiet", ref])) return ref;
  }
  return null;
}

/**
 * Migration files ADDED on this branch: committed since the merge base, plus anything staged
 * or merely untracked, so the check is useful before you commit.
 *
 * 🔴 EXTRACTED SO THE TWO CHECKS CANNOT DISAGREE ABOUT WHAT "NEW" MEANS. The collision scan
 *    and the reservation check both answer questions about newly added files. If one of them
 *    counted untracked files and the other did not, a slot could be reserved-by-someone-else
 *    and reported by neither — each believing the other was looking.
 */
export function addedMigrationFiles(repoRoot, base) {
  const mergeBase = tryGit(repoRoot, ["merge-base", base, "HEAD"]) || base;
  const committed = tryGit(repoRoot, ["diff", "--diff-filter=A", "--name-only", `${mergeBase}..HEAD`, "--", MIGRATIONS_DIR]);
  const staged = tryGit(repoRoot, ["diff", "--cached", "--diff-filter=A", "--name-only", "--", MIGRATIONS_DIR]);
  const untracked = tryGit(repoRoot, ["ls-files", "--others", "--exclude-standard", "--", MIGRATIONS_DIR]);
  const split = (out) => (out ? out.split("\n").filter(Boolean) : []);
  return [...new Set([...split(committed), ...split(staged), ...split(untracked)])];
}

/**
 * Who added this file: the author of the commit that introduced it, or — for a file that is
 * only staged or untracked — whoever is about to commit it.
 *
 * ⚠ THE COMMIT AUTHOR IS NOT NECESSARILY `git config user.email`. On a squash merge, or
 *   anything committed through the GitHub UI, it is the noreply form of that person. Callers
 *   compare with `holdersMatch`, not with `===`, for exactly that reason.
 */
export function authorOfAddedFile(repoRoot, base, file) {
  const mergeBase = tryGit(repoRoot, ["merge-base", base, "HEAD"]) || base;
  const out = tryGit(repoRoot, ["log", "--diff-filter=A", "--format=%ae", "-1", `${mergeBase}..HEAD`, "--", file]);
  if (out) return out.split("\n")[0].trim();
  return tryGit(repoRoot, ["config", "user.email"]) || null;
}

/** Every basename slot `key` carries on `ref`, as a Map key -> basename. */
function slotNamesOn(repoRoot, ref) {
  const seen = new Map();
  if (!ref) return seen;
  const out = tryGit(repoRoot, ["ls-tree", "--name-only", "-r", ref, `${MIGRATIONS_DIR}/`]);
  if (out === null) return seen;
  for (const file of out.split("\n").filter(Boolean)) {
    const slot = slotOf(file);
    if (slot && !seen.has(slot.key)) seen.set(slot.key, path.basename(file));
  }
  return seen;
}

/**
 * 🔴 WHICH NAME A SLOT REPORTS MUST NOT DEPEND ON REF SCAN ORDER.
 *
 * This used to keep the FIRST basename it met per slot. `for-each-ref` lists refs sorted by
 * refname with heads before remotes, so for a slot whose file was renamed, the winner was
 * whichever branch happened to sort first — a property of local branch NAMES, not of the
 * repository's history.
 *
 * That put a wrong name on the board and made `sync` disagree with itself across machines.
 * Measured 2026-09-09: CA_0077 was recorded as `CA_0077_pin_education_topics_season2.sql`,
 * the loser of a collision that PR #367 had already resolved in master's favour, because the
 * seed ran where a stale branch sorted first. `sync` then reported drift on one checkout and
 * nothing on another, for the same row.
 *
 * So the base ref decides: it is the tree everyone shares, and it is what "this slot is that
 * file" means. Only when no base ref carries the slot — a number claimed solely on branches —
 * is there nothing authoritative to read, and then the fallback is still deterministic: the
 * name the most refs carry, ties broken by name.
 *
 * 🔴 THE FALLBACK IS NOT THE FIX, AND MUST NOT BE READ AS ONE. Measured on this repo the same
 *    day: CA_0077's retired name sits on 67 refs and the name master carries on 33, because
 *    stale branches outnumber live ones and every one of them predates the rename. A popularity
 *    rule would have chosen the wrong file too — just stably. It earns its place only where
 *    there is no base-ref answer at all, and `onBase: false` marks every row that used it.
 *
 * ⚠ THE ALTERNATIVES ARE KEPT, NOT DISCARDED. `names` lists every basename with the refs
 *   behind it, so a caller can say WHICH other file claims the slot instead of only that one
 *   does. `onBase` says whether `filename` was read from the base ref or picked by fallback,
 *   because those two deserve different wording in a warning.
 */
function chooseName(names, baseName) {
  if (baseName && names.has(baseName)) return { filename: baseName, onBase: true };
  const ranked = [...names.entries()].sort((a, b) =>
    b[1].length - a[1].length || a[0].localeCompare(b[0]));
  return { filename: ranked[0]?.[0] ?? null, onBase: false };
}

export function historicalSlots(repoRoot) {
  const bySlot = new Map();
  for (const ref of scannableRefs(repoRoot)) {
    const out = tryGit(repoRoot, ["ls-tree", "--name-only", "-r", ref, `${MIGRATIONS_DIR}/`]);
    if (out === null) continue;
    for (const file of out.split("\n").filter(Boolean)) {
      const slot = slotOf(file);
      if (!slot) continue;
      if (!bySlot.has(slot.key)) {
        bySlot.set(slot.key, {
          namespace: slot.ns,
          num: Number(slot.num),
          key: slot.key,
          filename: null,      // decided below, from the base ref
          onBase: false,
          names: new Map(),    // basename -> refs carrying it
          refs: [],
        });
      }
      const row = bySlot.get(slot.key);
      const l = label(ref);
      if (!row.refs.includes(l)) row.refs.push(l);
      const name = path.basename(file);
      if (!row.names.has(name)) row.names.set(name, []);
      if (!row.names.get(name).includes(l)) row.names.get(name).push(l);
    }
  }

  const baseNames = slotNamesOn(repoRoot, resolveBase(repoRoot));
  for (const row of bySlot.values()) {
    const { filename, onBase } = chooseName(row.names, baseNames.get(row.key));
    row.filename = filename;
    row.onBase = onBase;
    row.names = [...row.names.entries()]
      .map(([name, refs]) => ({ filename: name, refs }))
      .sort((a, b) => b.refs.length - a.refs.length || a.filename.localeCompare(b.filename));
  }

  return [...bySlot.values()].sort((a, b) =>
    a.namespace === b.namespace ? a.num - b.num : a.namespace.localeCompare(b.namespace));
}
