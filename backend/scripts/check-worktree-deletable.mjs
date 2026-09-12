#!/usr/bin/env node
/**
 * §9 rule 4, as one command instead of four remembered ones.
 *
 *   node scripts/check-worktree-deletable.mjs <path-to-worktree>
 *   npm run steward --prefix backend -- can-delete /c/ev-accounts-topic
 *
 * Verdict logic: backend/scripts/lib/worktree-safety.mjs (pure, tested)
 * Design: docs/superpowers/specs/2026-09-04-steward-coordination-design.md (§9)
 *
 * Exit 0 = safe to delete. Exit 1 = do not delete, reasons printed. Exit 2 = bad usage.
 *
 * ── WHY THIS EXISTS ──────────────────────────────────────────────────────────────────────────
 *
 * The rule was four checks a person had to remember, and it was run by hand three times on
 * 2026-09-04 at roughly four commands each. Worse, run LITERALLY it can never pass: every
 * worktree here carries node_modules and a .env copy, so "untracked-and-ignored count is zero"
 * is false every time. A checklist whose first item always fails is one people stop reading.
 *
 * 🔴 IT PLANTS ITS OWN POSITIVE CONTROL. The rule's closing sentence says to run one on any
 *    detector reporting "nothing found", because two detectors were silently broken that day
 *    and only a control exposed them. So this writes a file into the worktree, confirms its own
 *    untracked scan SEES it, removes it, and refuses to give a verdict if the scan came back
 *    blind. "Nothing found" from an unproven detector is not evidence.
 */
import { execFileSync } from "node:child_process";
import { existsSync, writeFileSync, rmSync, readFileSync } from "node:fs";
import path from "node:path";

import { parsePorcelain, verdictFor } from "./lib/worktree-safety.mjs";

const target = process.argv[2];
if (!target || target.startsWith("--")) {
  console.error("usage: check-worktree-deletable.mjs <path-to-worktree>");
  process.exit(2);
}
const wt = path.resolve(target);
if (!existsSync(wt)) { console.error(`${wt}: no such directory`); process.exit(2); }

/**
 * 🔴 maxBuffer IS LOAD BEARING, AND ITS ABSENCE PRODUCED EXACTLY THE FAILURE THIS FILE EXISTS
 *    TO CATCH. `git status --porcelain -uall --ignored` lists ~30,000 ignored paths here —
 *    about 1.4 MB — which overflows execFileSync's 1 MB default and throws ENOBUFS. The
 *    `allowFail` catch below then swallowed it and returned an EMPTY scan, so the verdict read
 *    "0 untracked paths, SAFE TO DELETE" for a worktree full of files.
 *
 *    It was caught on the very first run, by this script's own positive control, before it
 *    could give a wrong answer. That is the whole argument for the control in one incident:
 *    a broken detector and a clean worktree are indistinguishable from the output alone.
 */
const git = (cwd, args, allowFail = false, { raw = false } = {}) => {
  try {
    const out = execFileSync("git", args, {
      cwd, encoding: "utf8", stdio: ["ignore", "pipe", "ignore"], maxBuffer: 64 * 1024 * 1024,
    });
    /**
     * 🔴 `raw` IS LOAD BEARING FOR PORCELAIN, AND ITS ABSENCE CORRUPTED A REAL VERDICT.
     *    `git status --porcelain` puts the status in two fixed columns and EITHER MAY BE A
     *    SPACE — ` M path` is "tracked, modified in the worktree". Trimming the whole captured
     *    output removes the leading space of the FIRST line only, after which `slice(3)` eats
     *    the first character of that path. On 2026-09-12 this printed
     *    `ackend/data/seed-in-local-headshots-2026/harvest.json` as a blocker: a real file,
     *    named wrongly, under a heading that did not describe it. Never trim porcelain.
     */
    return raw ? out : out.trim();
  } catch (e) {
    if (allowFail) return null;
    throw e;
  }
};

const branch = git(wt, ["rev-parse", "--abbrev-ref", "HEAD"], true);
const head = git(wt, ["rev-parse", "HEAD"], true);
if (!head) { console.error(`${wt}: not a git worktree`); process.exit(2); }

git(wt, ["fetch", "origin", "--quiet"], true);

// 1. Fully merged into origin/master?
const merged = git(wt, ["merge-base", "--is-ancestor", head, "origin/master"], true) !== null;

// 2. Merged content byte-identical? Compare the branch tip's tree against origin/master for
//    the paths this branch actually touched — a diff over the whole repo would report every
//    OTHER change merged since, which is not this branch's business.
let identicalContent = true;
let differing = [];
if (merged) {
  const base = git(wt, ["merge-base", head, "origin/master"], true);
  const touched = git(wt, ["diff", "--name-only", `${base}..${head}`], true);
  const files = touched ? touched.split("\n").filter(Boolean) : [];
  if (files.length) {
    const out = git(wt, ["diff", "--name-only", head, "origin/master", "--", ...files], true);
    differing = out ? out.split("\n").filter(Boolean) : [];
    identicalContent = differing.length === 0;
  }
}

// 3. Stash count. Stashes are SHARED across worktrees and are usually somebody else's, so the
//    honest measure is whether the count moved while this branch existed. Without a recorded
//    baseline the best available answer is the current count, reported for a human to judge.
const stashList = git(wt, ["stash", "list"], true);
const stashCount = stashList ? stashList.split("\n").filter(Boolean).length : 0;
const baselineRaw = process.env.STASH_BASELINE;
const baseline = baselineRaw === undefined ? null : Number(baselineRaw);
const stashDelta = baseline === null || Number.isNaN(baseline) ? 0 : stashCount - baseline;

// 4. Untracked-and-ignored, WITH a positive control.
const scan = () => parsePorcelain(
  git(wt, ["status", "--porcelain", "-uall", "--ignored"], true, { raw: true }) ?? "",
);
const CONTROL = "_deletable-scan-control.tmp";
const controlPath = path.join(wt, CONTROL);
let controlPassed = false;
try {
  writeFileSync(controlPath, "positive control for the untracked scan; safe to delete\n");
  controlPassed = scan().untracked.some((p) => p.replace(/\\/g, "/").endsWith(CONTROL));
} finally {
  rmSync(controlPath, { force: true });
}
const status = scan();
const untracked = status.untracked.filter((p) => !p.replace(/\\/g, "/").endsWith(CONTROL));
// A tracked file with uncommitted edits is a DIFFERENT fact from an untracked one: the file is
// in git and recoverable, the edit is not. Folding it into `untracked` reported it as something
// that "exists nowhere else", which understated the loss and mislabelled the fix.
const modified = status.modified;

// The .env carve-out is conditional on actually comparing it.
const envHere = path.join(wt, "backend", ".env");
const envMain = path.join(process.cwd(), "..", "backend", ".env");
let envIdentical = false;
try {
  envIdentical = existsSync(envHere) && existsSync(envMain)
    && readFileSync(envHere).equals(readFileSync(envMain));
} catch { envIdentical = false; }
if (!untracked.some((p) => /(^|[\\/])\.env$/.test(p))) envIdentical = true;  // none present: moot

const v = verdictFor({
  merged, identicalContent, stashDelta, untracked, modified, envIdentical, controlPassed,
});

console.log(`${wt}  [${branch ?? "detached"}]`);
console.log(`  merged into origin/master : ${merged ? "yes" : "NO"}`);
console.log(`  content identical         : ${identicalContent ? "yes" : `NO (${differing.slice(0, 5).join(", ")})`}`);
console.log(`  stash count               : ${stashCount}${baseline === null
  ? "  (no STASH_BASELINE given — not compared; set it to check the delta)" : `  (baseline ${baseline}, delta ${stashDelta})`}`);
console.log(`  untracked scan control    : ${controlPassed ? "PASSED — the scan can see a planted file" : "FAILED — the scan is blind"}`);
console.log(`  ignorable, not unique     : ${v.ignored.length} path(s)`);
console.log(`  tracked, uncommitted edits: ${modified.length} file(s)`);

if (v.safe) {
  console.log("\nSAFE TO DELETE. Nothing here exists only here.");
  console.log(`  git worktree remove --force ${wt}   # --force is for node_modules/.env, checked above`);
  if (branch) console.log(`  git branch -d ${branch} && git push origin --delete ${branch}`);
  process.exit(0);
}

console.error("\nDO NOT DELETE:");
for (const b of v.blockers) {
  console.error(`  🔴 ${b.kind}: ${b.why}`);
  for (const f of (b.files ?? []).slice(0, 20)) console.error(`       ${f}`);
  if ((b.files ?? []).length > 20) console.error(`       … and ${b.files.length - 20} more`);
}
process.exit(1);
