/**
 * §9 rule 4: is this worktree safe to delete?
 *
 * Design: docs/superpowers/specs/2026-09-04-steward-coordination-design.md (§9)
 *
 *   "Verify before deleting a worktree or branch: untracked-and-ignored count is zero, the
 *    branch is fully merged into origin/master, the merged content is byte-identical, and the
 *    repo stash count is unchanged. Run a positive control on any detector that reports
 *    'nothing found' — on 2026-09-04 two such detectors were silently broken and only a
 *    control exposed them."
 *
 * ── WHY THE RULE AS WRITTEN CANNOT PASS ──────────────────────────────────────────────────────
 *
 * 🔴 "UNTRACKED-AND-IGNORED COUNT IS ZERO" IS FALSE FOR EVERY WORKTREE THIS REPO EVER MAKES.
 *    Each one carries `node_modules` (~30,000 ignored files) and a `.env` copied from the main
 *    checkout. Run literally, the checklist fails on its first item every time — and a
 *    checklist whose first item always fails is one people stop reading. Measured three times
 *    on 2026-09-04, by hand, at four commands each.
 *
 *    So this asks the question the rule MEANS: **is there anything here that exists nowhere
 *    else?** `node_modules` is regenerable from the lockfile. A `.env` that has been COMPARED
 *    and found byte-identical to the main worktree's is a copy. Neither is unique content.
 *
 * ⚠ THE .env CARVE-OUT IS CONDITIONAL ON HAVING ACTUALLY COMPARED IT. An unverified .env is
 *   treated as unique: the one in a worktree could hold a credential that exists nowhere else,
 *   and deleting that is unrecoverable. The caller does the comparison; this only decides what
 *   the comparison means.
 *
 * 🔴 THE RULE'S CLOSING SENTENCE IS STRUCTURAL HERE, NOT ADVICE. `controlPassed` is a required
 *    input and a false value BLOCKS. A scan that reports "nothing found" is worth nothing until
 *    it has demonstrated it can find something — two detectors were silently broken that day
 *    and only a positive control exposed them.
 *
 * 🔴 EVERY FUNCTION HERE IS PURE. The runner owns git, the filesystem and the printing.
 */

/** Untracked paths that are, by their nature, not unique content. */
export const IGNORABLE = [
  /(^|\/)node_modules(\/|$)/,
  /(^|\/)\.env$/,
];

/**
 * Parse `git status --porcelain [-uall --ignored]` into the two facts the verdict needs.
 *
 * 🔴 A LEADING SPACE IN PORCELAIN IS DATA, NOT PADDING. The status field is exactly two columns
 *    wide and either may be a space: ` M path` is "tracked, modified in the worktree", `M  path`
 *    is "tracked, modified in the index". The runner used to `.trim()` the whole captured output
 *    and then take `slice(3)` of every line, which ate the leading space of the FIRST line only
 *    and therefore the first character of its path. On 2026-09-12 a real verdict named
 *    `ackend/data/seed-in-local-headshots-2026/harvest.json` — a file that does not exist.
 *    Never trim porcelain. Slice the columns.
 *
 * 🔴 UNTRACKED AND DIRTY-TRACKED ARE DIFFERENT FACTS. `??`/`!!` mean the path is not in git at
 *    all, so the FILE is what would be lost. Any other code means the file IS in git and the
 *    uncommitted EDIT is what would be lost. Folding the second into the first made the checker
 *    report a tracked file under "these exist nowhere else", which is not true of the file and
 *    understates what recovery would cost.
 *
 * @param {string} out raw, UNTRIMMED porcelain output
 * @returns {{untracked:string[], modified:string[]}}
 */
export function parsePorcelain(out) {
  const untracked = [];
  const modified = [];
  for (const line of String(out ?? "").split("\n")) {
    // "XY " plus at least one path character.
    if (line.length < 4) continue;
    const code = line.slice(0, 2);
    if (code.trim() === "") continue;
    let rest = line.slice(3);
    if (code === "??" || code === "!!") {
      untracked.push(unquotePath(rest));
      continue;
    }
    // A rename or copy prints "old -> new"; the new name is the one on disk.
    if (code.includes("R") || code.includes("C")) {
      const arrow = rest.lastIndexOf(" -> ");
      if (arrow !== -1) rest = rest.slice(arrow + 4);
    }
    modified.push(unquotePath(rest));
  }
  return { untracked, modified };
}

/**
 * Undo git's C-style quoting. Git wraps a path in double quotes and octal-escapes its bytes
 * whenever it contains a control character, a quote, a backslash or (without core.quotePath=off)
 * anything non-ASCII, so a path with an accent arrives octal-escaped as `"caf\303\251.png"`.
 * UTF-8; decoding per character would mangle every accented filename.
 */
export function unquotePath(raw) {
  if (raw.length < 2 || raw[0] !== '"' || raw[raw.length - 1] !== '"') return raw;
  const body = raw.slice(1, -1);
  const bytes = [];
  const simple = { n: 10, t: 9, r: 13, b: 8, f: 12, v: 11, a: 7, '"': 34, "\\": 92 };
  for (let i = 0; i < body.length; i += 1) {
    if (body[i] !== "\\") {
      for (const b of new TextEncoder().encode(body[i])) bytes.push(b);
      continue;
    }
    const next = body[i += 1];
    if (next >= "0" && next <= "7") {
      bytes.push(parseInt(body.slice(i, i + 3), 8));
      i += 2;
    } else {
      bytes.push(simple[next] ?? next.charCodeAt(0));
    }
  }
  return new TextDecoder().decode(new Uint8Array(bytes));
}

/**
 * @param {object} facts
 * @param {boolean} facts.merged            branch fully contained in origin/master
 * @param {boolean} facts.identicalContent  merged tree matches this branch's tip byte for byte
 * @param {number}  facts.stashDelta        change in the repo-wide stash count during the work
 * @param {string[]} facts.untracked        untracked-and-ignored paths present
 * @param {string[]} facts.modified         TRACKED paths carrying uncommitted changes
 * @param {boolean} facts.envIdentical      a .env here was compared and matched
 * @param {boolean} facts.controlPassed     the untracked scan proved it can detect a planted file
 * @returns {{safe:boolean, blockers:Array, ignored:string[]}}
 */
export function verdictFor(facts) {
  const blockers = [];
  const ignored = [];
  const unique = [];

  for (const p of facts.untracked ?? []) {
    const path = String(p).replace(/\\/g, "/");
    const ignorable = IGNORABLE.some((r) => r.test(path));
    // A .env only counts as a copy once it has been compared.
    const isEnv = /(^|\/)\.env$/.test(path);
    if (ignorable && (!isEnv || facts.envIdentical)) ignored.push(path);
    else unique.push(path);
  }

  if (!facts.merged) {
    blockers.push({
      kind: "not-merged",
      why: "the branch is not fully contained in origin/master — deleting it would drop commits",
    });
  }
  if (!facts.identicalContent) {
    blockers.push({
      kind: "content-differs",
      why: "what merged is not byte-identical to this branch's tip; something did not land",
    });
  }
  if (facts.stashDelta !== 0) {
    blockers.push({
      kind: "stash-changed",
      why: `the repo stash count moved by ${facts.stashDelta > 0 ? "+" : ""}${facts.stashDelta}. `
        + "Stashes are shared across worktrees and are usually somebody else's",
    });
  }
  if (unique.length) {
    blockers.push({
      kind: "unique-files",
      files: unique,
      why: "these exist nowhere else and deleting them is unrecoverable",
    });
  }
  const dirty = (facts.modified ?? []).map((p) => String(p).replace(/\\/g, "/"));
  if (dirty.length) {
    blockers.push({
      kind: "dirty-tracked",
      files: dirty,
      why: "these tracked files carry uncommitted changes. The FILE is in git; the EDIT is not, "
        + "and deleting the worktree drops it",
    });
  }
  if (!facts.controlPassed) {
    blockers.push({
      kind: "control-failed",
      why: "the untracked scan could not find a file planted on purpose, so its 'nothing found' "
        + "proves nothing. Two detectors were silently broken this way on 2026-09-04",
    });
  }

  return { safe: blockers.length === 0, blockers, ignored };
}
