/**
 * §9 rules 1 and 3, observed at commit time.
 *
 * Design: docs/superpowers/specs/2026-09-04-steward-coordination-design.md (§9)
 *
 *   1. One session owns a worktree. If you are going to commit, work in your own.
 *   3. Always commit with an explicit pathspec — `git commit -F msg -- <path>`. Staging
 *      carefully is not enough, because it is the OTHER session's `git add -A` that sweeps
 *      your files in.
 *
 * ── THEY ARE ONE SIGNAL, NOT TWO ─────────────────────────────────────────────────────────────
 *
 * Rule 3 exists BECAUSE of rule 1. A pathspec-less commit alone in your own worktree harms
 * nobody; the same commit in a checkout another session is using is the failure that was
 * actually recorded. So this grades the warning by whether anyone else is really there, and
 * only the combination shouts. A warning that fires on every commit is one people stop reading,
 * and this one has to stay credible to be worth anything.
 *
 * ── HOW RULE 3 IS DETECTABLE AT ALL ──────────────────────────────────────────────────────────
 *
 * 🔴 GIT TELLS US, AND THIS IS THE WHOLE REASON THE RULE CAN HAVE AN OBSERVER. A partial commit
 *    (`git commit -- <path>`) builds a TEMPORARY index, so `GIT_INDEX_FILE` in the hook points
 *    at `.git/next-index-<pid>.lock` rather than `.git/index`. Nothing else in a pre-commit
 *    hook distinguishes the two — the staged set looks identical. Verified against real git
 *    before this was written, because the whole check rests on it.
 *
 * 🔴 EVERY FUNCTION HERE IS PURE. The runner owns git, the database and the printing.
 */

/**
 * How recently another session must have been seen in this worktree to count as present.
 *
 * A marker is a "last seen" record, not a liveness proof — nothing releases it when a terminal
 * closes. Treating a two-day-old marker as an active session would make the alarm fire
 * constantly, and an alarm that always fires is one nobody reads.
 */
export const OTHER_SESSION_WINDOW_HOURS = 12;

const HOUR = 3.6e6;

/** Was this commit made with an explicit pathspec? */
export function pathspecUsed(gitIndexFile) {
  if (typeof gitIndexFile !== "string" || !gitIndexFile) return false;
  return /next-index-\d+/.test(gitIndexFile);
}

function msOf(when) {
  if (when instanceof Date) return when.getTime();
  if (typeof when === "number") return when;
  if (typeof when === "string") {
    const t = Date.parse(when);
    return Number.isNaN(t) ? null : t;
  }
  return null;
}

/**
 * What to say before this commit lands.
 *
 * @param {object} args
 * @param {boolean} args.pathspec          from pathspecUsed()
 * @param {Array} args.markers             live worktree markers for THIS worktree's scope
 * @param {{holder:string,machine:string}} args.me
 * @param {number} args.nowMs
 * @returns {Array<{kind:'no-pathspec'|'shared-worktree', severity:'note'|'alarm', others:Array}>}
 */
export function commitNotices({ pathspec, markers, me, nowMs }) {
  // Another session = a different (email, hostname) pair, seen recently. The design makes the
  // holder (email, hostname) because one author's two machines collide as readily as two people.
  const others = (markers ?? []).filter((m) => {
    if (m.holder === me.holder && m.machine === me.machine) return false;
    const seen = msOf(m.started_at);
    if (seen === null) return false;                  // unknown age is not "recent"
    return nowMs - seen < OTHER_SESSION_WINDOW_HOURS * HOUR;
  });

  if (!pathspec) {
    return [{ kind: "no-pathspec", severity: others.length ? "alarm" : "note", others }];
  }
  if (others.length) {
    return [{ kind: "shared-worktree", severity: "note", others }];
  }
  return [];
}
