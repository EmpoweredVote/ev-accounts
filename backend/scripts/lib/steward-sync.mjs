/**
 * Reconciling steward.migration_slots against what git actually holds.
 *
 * Design: docs/superpowers/specs/2026-09-04-steward-coordination-design.md (§5)
 *
 *   "`steward sync` reconciles: reservations that now have a matching file on a ref become
 *    `written`; reservations older than fourteen days with no file are flagged for cleanup."
 *
 * That half was never built. `sync --seed` shipped insert-only, so a reservation stayed
 * `reserved` for ever: `CC_0074` sat on the board as an outstanding reservation while its
 * migration was merged to master. The board's whole value is being true, and a permanent
 * false entry on it is worse than a missing feature — it teaches people to skim the board.
 *
 * ── THE RULE THIS HAS TO NOT BREAK ───────────────────────────────────────────────────────────
 *
 * 🔴 THE SEEDER'S RULE IS "A SLOT ALREADY PRESENT IS NEVER REWRITTEN", because it could be a
 *    live reservation someone is relying on, and overwriting one would hand a number to two
 *    people while telling both it was theirs. This module is the first code that rewrites an
 *    existing row, and it satisfies that rule from the other side rather than breaking it:
 *
 *      A PROMOTION HAPPENS ONLY WHEN A FILE EXISTS FOR THE SLOT — which is proof the
 *      reservation was used, by the person who holds it, and is therefore no longer live.
 *
 *    Everything without that proof is REPORTED and never written. Nothing here abandons a
 *    reservation, changes a holder, or resolves a disagreement on its own.
 *
 * 🔴 EVERY FUNCTION HERE IS PURE. The CLI owns git, the database and the writing.
 */

/**
 * How old a reservation with no file must be before it is worth mentioning.
 *
 * The design's number. It is a REPORTING threshold, not an expiry: a fourteen-day-old
 * reservation may still belong to a long-running branch — several in this repo live for weeks —
 * and abandoning somebody else's slot on a timer is the kind of helpfulness that loses work.
 * Reserving a number and never using it is explicitly harmless (CLAUDE.md: holes cost nothing),
 * so the cost of a false flag is a sentence of output and the cost of a wrong write is a lost
 * migration.
 */
export const STALE_DAYS = 14;

const DAY = 86400000;

/** ms since epoch for a Date, an ISO string, or null. */
function msOf(when) {
  if (when instanceof Date) return when.getTime();
  if (typeof when === "number") return when;
  if (typeof when === "string") {
    const t = Date.parse(when);
    return Number.isNaN(t) ? null : t;
  }
  return null;
}

const keyOf = (namespace, num) => `${namespace ?? ""} ${Number(num)}`;

/**
 * What the table and git disagree about.
 *
 * @param {Array<{namespace:string,num:number,filename:string}>} gitSlots from historicalSlots()
 * @param {Array<object>} tableRows                                       steward.migration_slots
 * @param {number} nowMs
 * @returns {{promote:Array, fillFilename:Array, stale:Array, drift:Array, conflict:Array}}
 *
 *   promote      reserved, and the file now exists          -> WRITE state='written' + filename
 *   fillFilename written, but the row never recorded which  -> WRITE filename
 *   stale        reserved, no file, older than STALE_DAYS   -> REPORT ONLY
 *   drift        written, and git says a different filename -> REPORT ONLY
 *   conflict     abandoned, yet a file occupies the slot    -> REPORT ONLY
 */
export function reconcile(gitSlots, tableRows, nowMs) {
  const byKey = new Map();
  for (const s of gitSlots ?? []) byKey.set(keyOf(s.namespace, s.num), s);

  const out = { promote: [], fillFilename: [], stale: [], drift: [], conflict: [] };

  for (const row of tableRows ?? []) {
    const git = byKey.get(keyOf(row.namespace, row.num));
    const base = { namespace: row.namespace, num: Number(row.num), claimed_by: row.claimed_by, purpose: row.purpose };

    if (!git) {
      // 🔴 AN UNREADABLE CLAIM DATE IS NOT OLD. Treating "I cannot tell how old this is" as
      //    "old enough to flag" would put live reservations on a cleanup list on a parse bug.
      if (row.state !== "reserved") continue;
      const claimed = msOf(row.claimed_at);
      if (claimed === null) continue;
      const ageDays = (nowMs - claimed) / DAY;
      if (ageDays > STALE_DAYS) out.stale.push({ ...base, claimed_at: row.claimed_at, ageDays });
      continue;
    }

    if (row.state === "reserved") {
      out.promote.push({ ...base, filename: git.filename, refs: git.refs });
      continue;
    }

    if (row.state === "abandoned") {
      // Somebody reused a dead number. check:reservations catches this for a file ADDED on a
      // branch; a file that reached master another way is invisible to it, and visible here.
      out.conflict.push({ ...base, filename: git.filename, refs: git.refs });
      continue;
    }

    // state === 'written'
    if (!row.filename) {
      out.fillFilename.push({ ...base, filename: git.filename });
    } else if (row.filename !== git.filename) {
      // Either a rename of an applied migration — which CLAUDE.md forbids, because the number
      // is embedded in production data — or two files sharing a slot. Both want a human.
      out.drift.push({ ...base, was: row.filename, now: git.filename, refs: git.refs });
    }
  }

  return out;
}
