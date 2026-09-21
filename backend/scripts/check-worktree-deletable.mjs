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

// `--abbrev-ref HEAD` answers the STRING "HEAD" on a detached checkout, which is not a branch
// name. Passing it through produced the advice `git push origin --delete HEAD` — a command that
// names no branch anyone meant to delete. A detached worktree has no branch advice to give.
const branchRaw = git(wt, ["rev-parse", "--abbrev-ref", "HEAD"], true);
const branch = branchRaw === "HEAD" ? null : branchRaw;
const head = git(wt, ["rev-parse", "HEAD"], true);
if (!head) { console.error(`${wt}: not a git worktree`); process.exit(2); }

git(wt, ["fetch", "origin", "--quiet"], true);

// 0. WHICH BRANCH IS "UPSTREAM" HERE?
//
// 🔴 `origin/master` WAS HARDCODED, AND THAT IS A FACT ABOUT THIS REPO, NOT ABOUT GIT. Pointed at
//    an essentials worktree on 2026-09-20 this asked about a ref that does not exist there — that
//    repo's default branch is `main` — and reported the missing answer as two refusals,
//    `not-merged` and `content-unknown`, for a branch that was merged. It fails SAFE, so it was a
//    nuisance rather than a hazard; but a checker that refuses every main-default repo is one
//    people learn to --force past, and then it is not a checker at all.
//
// Resolution order, most authoritative first. 🟢 THE ANSWER AND ITS SOURCE ARE PRINTED, so a wrong
// one is visible in the report rather than buried inside a verdict.
//
// ⚠ EVERY CANDIDATE IS CHECKED FOR EXISTENCE BEFORE IT IS RETURNED, and that is not
//    belt-and-braces. `symbolic-ref` happily resolves to a branch that is GONE — a control run
//    against a repo whose remote refs had all been deleted still got `origin/trunk` back, and the
//    comparisons below then failed against a ref that is not there and printed
//    `content identical: UNKNOWN`. That is the same false refusal this block exists to remove,
//    re-entering through the fix for it.
const exists = (ref) => git(wt, ["rev-parse", "--verify", "--quiet", ref], true) !== null;
const resolveDefaultBranch = () => {
  // What the remote said its default was, recorded at clone time. Cheap, and offline.
  const sym = git(wt, ["symbolic-ref", "--short", "refs/remotes/origin/HEAD"], true);
  if (sym && exists(sym)) return { ref: sym, how: "refs/remotes/origin/HEAD" };
  // That ref is missing on clones made before it existed, and after `git remote prune`. Ask the
  // remote directly — one round trip, and only on this path.
  const shown = git(wt, ["remote", "show", "origin"], true);
  const m = shown && shown.match(/HEAD branch:\s*(\S+)/);
  if (m && m[1] !== "(unknown)" && exists("origin/" + m[1])) {
    return { ref: "origin/" + m[1], how: "git remote show origin" };
  }
  // Last resort, and the report calls it a guess. A guess that reads like a measurement is the
  // exact defect this block exists to remove.
  for (const guess of ["origin/main", "origin/master"]) {
    if (exists(guess)) {
      return { ref: guess, how: "GUESSED — origin/HEAD is unset; run `git remote set-head origin -a`" };
    }
  }
  return null;
};
const def = resolveDefaultBranch();
if (!def) {
  // Fatal, not "block with a reason": every check below compares against this ref, and comparing
  // against a ref that does not exist is what produced the false refusal in the first place.
  console.error(wt + ": cannot resolve the remote's default branch — no refs/remotes/origin/HEAD, "
    + "no HEAD branch from `git remote show origin`, and neither origin/main nor origin/master "
    + "exists. Fix with `git remote set-head origin -a`.");
  process.exit(2);
}
const MAIN = def.ref;

// 1. Is this work upstream — BY EITHER ROUTE?
//
// 🔴 ANCESTRY IS ONLY ONE ROUTE, AND NOT THE ONE THIS REPO USES. A squash merge replays the whole
//    branch as ONE NEW COMMIT, so a fully and permanently merged branch's tip is never an ancestor
//    of master. `merge-base --is-ancestor` answers NO for it. Minutes after PR #486 was squashed
//    onto master, this check refused to let go of #486's own worktree for exactly that reason —
//    and the three merges before it were squashes too. A false "you would drop commits" on the
//    common case teaches people to pass --force, which is how the check stops being read at all.
const isAncestor = git(wt, ["merge-base", "--is-ancestor", head, MAIN], true) !== null;

// 2. Content comparison — ALWAYS MEASURED.
//
// 🔴 THIS USED TO SIT INSIDE `if (merged)`, so when ancestry said NO it never ran, and its
//    variable kept the initial `true`. The report then printed `content identical : yes` for a
//    comparison that had not happened. That is worse than the wrong verdict above it: it is a
//    reassuring answer from a test nobody performed. Now it is a tri-state, and 'unknown' BLOCKS.
//
//    Compare only the paths this branch TOUCHED. A whole-repo diff would report every other
//    change merged since, which is not this branch's business.
const base = git(wt, ["merge-base", head, MAIN], true);
let contentState = "unknown";
let differing = [];
let comparedCount = 0;
if (base) {
  const touched = git(wt, ["diff", "--name-only", `${base}..${head}`], true);
  if (touched !== null) {
    const files = touched.split("\n").filter(Boolean);
    comparedCount = files.length;
    if (files.length === 0) {
      contentState = "same";   // the branch changed nothing; there is nothing to lose
    } else {
      const out = git(wt, ["diff", "--name-only", head, MAIN, "--", ...files], true);
      if (out !== null) {
        differing = out.split("\n").filter(Boolean);
        contentState = differing.length === 0 ? "same" : "differs";
      }
    }
  }
}

// `git cherry` compares by PATCH-ID. It catches a single-commit branch that was squashed, but NOT
// a multi-commit one — squashing three commits produces a patch that equals none of them. So it is
// corroboration for the REPORT, never the gate. The gate is the content comparison above, which
// answers the question that actually matters: does master already carry what this branch wrote?
let patchUpstream = false;
if (!isAncestor) {
  const cherry = git(wt, ["cherry", MAIN, head], true);
  if (cherry !== null) {
    const lines = cherry.split("\n").filter(Boolean);
    patchUpstream = lines.length > 0 && lines.every((l) => l.startsWith("-"));
  }
}
const upstream = isAncestor ? "ancestor" : (contentState === "same" ? "squash" : "none");

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
  upstream, contentState, stashDelta, untracked, modified, envIdentical, controlPassed,
});

console.log(`${wt}  [${branch ?? "detached"}]`);
const upstreamNote = {
  ancestor: `yes — ${MAIN} contains this commit`,
  squash: `yes — not an ancestor, but ${MAIN} already carries this branch's content${
    patchUpstream ? " (and its patch is upstream)" : ""}. This is what a squash merge leaves`,
  none: "NO",
}[upstream];
console.log(`  compares against          : ${MAIN}  (via ${def.how})`);
console.log(`  work is upstream          : ${upstreamNote}`);
console.log(`  content identical         : ${
  contentState === "same" ? `yes (${comparedCount} path(s) compared)`
  : contentState === "differs" ? `NO (${differing.slice(0, 5).join(", ")})`
  : "UNKNOWN — the comparison could not be made, so this blocks"}`);
console.log(`  stash count               : ${stashCount}${baseline === null
  ? "  (no STASH_BASELINE given — not compared; set it to check the delta)" : `  (baseline ${baseline}, delta ${stashDelta})`}`);
console.log(`  untracked scan control    : ${controlPassed ? "PASSED — the scan can see a planted file" : "FAILED — the scan is blind"}`);
console.log(`  ignorable, not unique     : ${v.ignored.length} path(s)`);
console.log(`  tracked, uncommitted edits: ${modified.length} file(s)`);

if (v.safe) {
  console.log("\nSAFE TO DELETE. Nothing here exists only here.");
  console.log(`  git worktree remove --force ${wt}   # --force is for node_modules/.env, checked above`);
  if (branch) {
    // `git branch -d` refuses a squash-merged branch — its tip is not an ancestor, which is the
    // very thing this check now looks past. Advising -d there sends people into an error they
    // resolve with -D anyway, having lost the reason it was safe. Say -D, and say why.
    const flag = upstream === "squash" ? "-D" : "-d";
    const note = upstream === "squash"
      ? "   # -D because the tip is not an ancestor; the content check above is why that is safe"
      : "";
    console.log(`  git branch ${flag} ${branch}${note}`);
    console.log(`  git push origin --delete ${branch}   # optional — this repo keeps merged branches`);
  }
  process.exit(0);
}

console.error("\nDO NOT DELETE:");
for (const b of v.blockers) {
  console.error(`  🔴 ${b.kind}: ${b.why}`);
  for (const f of (b.files ?? []).slice(0, 20)) console.error(`       ${f}`);
  if ((b.files ?? []).length > 20) console.error(`       … and ${b.files.length - 20} more`);
}
process.exit(1);
