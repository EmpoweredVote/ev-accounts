/**
 * Worktree registration: which directory a session started in, and what moved since.
 *
 * Design: docs/superpowers/specs/2026-09-04-steward-coordination-design.md (§9, §6 step 6, §10)
 *
 * ── WHY THIS IS A MARKER AND NOT A CLAIM ─────────────────────────────────────────────────────
 *
 * Collision B — a shared worktree's HEAD moving under a running session — is machine-local, so
 * the design fixed it with a rule and sequenced a `worktree:` claim scope LAST, "if still worth
 * it by then", to make the rule visible rather than merely written down.
 *
 * It is still worth it, measured: `C:\EV-Accounts` changed branch three times under one session
 * on 2026-09-04, and changed again while this was being built. A rule that is written down and
 * broken twice in one day needs an observer.
 *
 * 🔴 BUT IT IS NOT A LEASE, AND CALLING IT ONE WOULD MAKE THE BOARD LIE. A session that ends
 *    releases nothing — there is no hook for "the human closed the terminal" — so a live row
 *    means "a session STARTED here at T", never "a session is running here now". Everything
 *    below therefore reports LAST SEEN, and registration takes the marker over unconditionally,
 *    because the newest session genuinely is the newest thing to have started there.
 *
 *    That inverts the ownership rule that governs jurisdiction claims, and deliberately: for a
 *    jurisdiction the holder's work is the fact being protected, so `--if-held warn` refuses to
 *    steal. Here the fact IS "who most recently started", so the newest writer is correct and
 *    there is nothing to protect. What would otherwise be lost — that somebody else was there —
 *    is not discarded but REPORTED, at session start, before you touch anything.
 *
 * 🔴 EVERY FUNCTION HERE IS PURE. The CLI owns git, the database and the printing.
 */

/**
 * `worktree:<canonical path>`.
 *
 * 🔴 THIS IS THE ONE THING THAT MUST BE RIGHT, AND IT FAILS SILENTLY. The exclusion constraint
 *    compares scope STRINGS. Two sessions in one directory registering `worktree:C:/EV-Accounts`
 *    and `worktree:/c/ev-accounts` do not collide, do not warn, and the feature does nothing
 *    while appearing to work. This machine spells its own paths three ways — Git Bash gives
 *    `/c/ev-accounts`, PowerShell gives `C:\EV-Accounts`, `git rev-parse --show-toplevel` gives
 *    `C:/EV-Accounts` — and all three reach this function.
 *
 * ⚠ CASE IS FOLDED ONLY FOR A DRIVE-LETTER PATH. NTFS is case-insensitive, so on Windows two
 *   spellings are one directory. POSIX paths are case-SENSITIVE: folding `/home/Chris` and
 *   `/home/chris` together would merge two real worktrees into one scope — the inverse error,
 *   and just as silent as the first.
 */
export function canonicalWorktreeScope(rawPath) {
  if (typeof rawPath !== "string" || !rawPath.trim()) {
    throw new Error("canonicalWorktreeScope needs a path; an empty one would claim scope \"worktree:\"");
  }
  let p = rawPath.trim().replace(/\\/g, "/").replace(/\/{2,}/g, "/");

  // Git Bash spells C:\foo as /c/foo. The segment must be a SINGLE letter — /cats/foo is a
  // directory called cats, not drive C.
  const gitBash = /^\/([A-Za-z])(\/|$)/.exec(p);
  if (gitBash) p = `${gitBash[1]}:${p.slice(2) || "/"}`;

  const drive = /^([A-Za-z]):(\/.*)?$/.exec(p);
  if (drive) {
    const tail = (drive[2] ?? "/").replace(/\/+$/, "");
    return `worktree:${drive[1].toLowerCase()}:${(tail || "/").toLowerCase()}`;
  }
  return `worktree:${p.length > 1 ? p.replace(/\/+$/, "") : p}`;
}

/**
 * What changed since the last session registered in this directory.
 *
 * @param {{holder:string, machine:string, branch:string|null}} current
 * @param {{holder:string, machine:string, label:string|null, started_at:Date}|null} previous
 * @returns {Array<{kind:'other-session'|'head-moved', was?:string, now?:string, previous:object}>}
 */
export function worktreeNotices(current, previous) {
  if (!previous) return [];
  const out = [];

  // The same email on a different box is a different session: the design makes the holder
  // (email, hostname) because one author's two machines collide as readily as two people.
  if (previous.holder !== current.holder || previous.machine !== current.machine) {
    out.push({ kind: "other-session", previous });
  }

  // A row with no recorded branch cannot tell you HEAD moved, and neither can a detached HEAD
  // now. Reporting "was null, now feat/x" would manufacture an alarm out of a missing field.
  if (previous.label && current.branch && previous.label !== current.branch) {
    out.push({ kind: "head-moved", was: previous.label, now: current.branch, previous });
  }

  return out;
}
