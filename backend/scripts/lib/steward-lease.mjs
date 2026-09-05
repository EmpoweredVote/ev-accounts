/**
 * How long a lease lasts, and what state one is in.
 *
 * Design: docs/superpowers/specs/2026-09-04-steward-coordination-design.md (§10)
 *
 * ── THE NUMBERS ARE MEASURED, NOT CHOSEN ─────────────────────────────────────────────────────
 *
 * §10 left this open: *"Eight hours is a guess. It wants to be longer than a working session and
 * shorter than a weekend."* Both halves were then measured against **52 real session transcripts
 * for this project** (`~/.claude/projects/C--EV-Accounts/*.jsonl`), taking each session's
 * wall-clock span from its first message to its last.
 *
 *   sessions of >=200 messages (real work, n=47) that OUTLIVE a lease of...
 *     4h ->  75% of all 52          8h -> 28/47  (60%)   <- the shipped guess
 *    12h -> 17/47  (36%)           16h -> 13/47  (28%)   <- the shipped worktree marker was 12h
 *    20h ->  4/47   (9%)  <- cliff 24h ->  3/47   (6%)   <- CHOSEN
 *    36h ->  1/47   (2%)           48h ->  0/47   (0%)   <- no longer shorter than a weekend
 *
 * 🔴 THE GUESS WAS WRONG, AND IN A DIRECTION NOBODY WOULD HAVE NOTICED. An 8-hour lease expired
 *    during 60% of real working sessions. Median session span is 10.2h; p90 is 18.8h. The
 *    distribution has a sharp cliff between 16h (28%) and 20h (9%) — that is the overnight
 *    boundary — so 24h sits past it while still clearing the design's "shorter than a weekend".
 *
 * ⚠ MEASURED ON ONE AUTHOR'S SESSIONS. These transcripts are Cantrell's, on this project only.
 *   Andrews' sessions are not in the sample, and the laptop's scan runs are not either. Re-measure
 *   with the script recorded in the design if either becomes a normal case.
 *
 * ── WHY THE NUMBER IS NOT THE WHOLE FIX ──────────────────────────────────────────────────────
 *
 * 🔴 THE TWO FAILURE MODES ARE NOT SYMMETRIC, so tuning one number cannot balance them.
 *
 *   Too LONG fails VISIBLY: the board names the holder and the timestamp, an obviously stale
 *     claim reads as stale, and `--takeover` is one command.
 *   Too SHORT fails SILENTLY: the row stops matching, nothing warns anybody, and two sessions
 *     write one jurisdiction believing they are alone. That is precisely the failure this whole
 *     design exists to remove.
 *
 * So the residual 6% is made LOUD instead of tuned away: `expiring-soon` announces a lease while
 * its holder can still `extend` it, and `recently-expired` keeps a lapsed claim on the board —
 * and in `claim`'s overlap warnings — so the next session is told "somebody was here and their
 * lease has just run out" rather than being told nothing at all.
 */

/**
 * Jurisdiction lease, in hours. p90 of measured session span is 18.8h; this clears it and the
 * 20h cliff, and stays under the design's weekend bound.
 */
export const LEASE_HOURS = 24;

/**
 * Worktree marker, in hours. THE SAME MEASUREMENT, deliberately: both answer "how long might a
 * session still be around?", both were measured on the same transcripts, so two different
 * numbers would be two guesses where there is one fact. The old 12h expired during 36% of
 * sessions, which made a live session's own directory read as free.
 */
export const MARKER_HOURS = LEASE_HOURS;

/**
 * How long a lapsed claim stays on the board after expiry.
 *
 * It has to survive until the NEXT session start, because that is when anyone reads the board.
 * Half a day is the smallest window that reliably spans a gap between sessions.
 */
export const EXPIRED_GRACE_HOURS = 12;

/** How long before expiry to start saying so, while `extend` can still be used. */
export const EXPIRY_WARN_HOURS = 2;

const HOUR = 3.6e6;

/** ms since epoch for a Date, an ISO string, or null — pg hands back any of them. */
function msOf(when) {
  if (when instanceof Date) return when.getTime();
  if (typeof when === "string") {
    const t = Date.parse(when);
    return Number.isNaN(t) ? null : t;
  }
  if (typeof when === "number") return when;
  return null;
}

/**
 * 'live' | 'expiring-soon' | 'recently-expired' | 'stale'
 *
 * ⚠ An unreadable timestamp is STALE, never live. Treating a value we cannot parse as a holding
 *   claim would block a jurisdiction on a parse bug, and treating it as live is the reading that
 *   cannot be noticed.
 */
export function leaseStatus(expiresAt, nowMs) {
  const t = msOf(expiresAt);
  if (t === null) return "stale";
  const left = t - nowMs;
  if (left > EXPIRY_WARN_HOURS * HOUR) return "live";
  if (left >= 0) return "expiring-soon";
  if (-left < EXPIRED_GRACE_HOURS * HOUR) return "recently-expired";
  return "stale";
}

/**
 * Split board rows into what blocks and what merely warns.
 *
 * 🔴 A LAPSED LEASE MUST NOT BLOCK, AND MUST STILL BE REPORTED. Those pull in opposite
 *    directions and both matter:
 *      * Blocking on it would make `--if-held skip` refuse a jurisdiction that is genuinely
 *        free — the whole point of an expiring lease is that it frees the scope — and a queue
 *        would grind to a halt behind a session that ended yesterday.
 *      * Dropping it silently is the 6% failure: the holder's lease ran out while they were
 *        still working, and the next session is told nothing.
 *    So `blocking` feeds the exclusion logic and `lapsed` feeds the warnings, and no row is in
 *    both. Anything past the grace window is in neither: it is genuinely old news.
 */
export function partitionBoard(rows, nowMs) {
  const blocking = [];
  const lapsed = [];
  for (const r of rows ?? []) {
    const status = leaseStatus(r.expires_at, nowMs);
    if (status === "live" || status === "expiring-soon") blocking.push({ ...r, status });
    else if (status === "recently-expired") lapsed.push({ ...r, status });
  }
  return { blocking, lapsed };
}

/** A compact age: "40m", "3h 30m", "1d 2h". Under half a minute reads "just now". */
export function humanAge(ms) {
  if (!(ms > 30000)) return "just now";
  const mins = Math.floor(ms / 60000);
  if (mins < 60) return `${mins}m`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) {
    const rem = mins % 60;
    return rem ? `${hours}h ${rem}m` : `${hours}h`;
  }
  const days = Math.floor(hours / 24);
  const rem = hours % 24;
  return rem ? `${days}d ${rem}h` : `${days}d`;
}

/**
 * The same age as a phrase: "3h 30m ago", or "just now".
 *
 * 🔴 THREE CALL SITES EACH WROTE `${humanAge(x)} ago`, AND ALL THREE PRINTED "just now ago" ON
 *    A FRESH ROW. Seen on the live board the first time a worktree registered itself. The bug
 *    is not the wording, it is that the suffix lived at the call sites: "just now" is the one
 *    value that already carries its own tense, so every caller had to remember an exception and
 *    none did. One function, one place to be wrong.
 */
export function humanAgo(ms) {
  const age = humanAge(ms);
  return age === "just now" ? age : `${age} ago`;
}
