/**
 * Was this migration slot RESERVED, and by whom?
 *
 * Design: docs/superpowers/specs/2026-09-04-steward-coordination-design.md (§5, §6 step 5)
 *
 * ── WHY A SECOND CHECK, WHEN THE ALLOCATOR IS ALREADY ATOMIC ─────────────────────────────────
 *
 * `steward.claim_migration_slot` cannot hand one number to two people: the PRIMARY KEY on
 * (namespace, num) makes it impossible. But that guarantee only covers people who ASK. A number
 * taken by hand is invisible to the table, so the next allocator call reads a max that does not
 * include it and hands it out again — the 1681 collision rebuilt on top of its own fix.
 *
 * So the allocator is the ALLOCATOR and this is the AUDITOR of the allocator's authority:
 * every newly added migration file must sit in a slot its own author reserved.
 *
 * ⚠ THE REF SCAN IN check-migration-numbers.mjs IS NOT REPLACED BY THIS, and must not be. It
 *   needs no network and no credentials, so it still works when the steward does not, and it
 *   catches anyone who bypassed the steward entirely. Two independent detectors; keeping both
 *   is what stops the new system becoming a single point of failure.
 *
 * ── THE FLIP FROM WARN TO FAIL IS SURVIVED BY A CEILING, NOT BY A DATE ───────────────────────
 *
 * The design made "not reserved at all" a WARNING first, because every branch in flight had
 * unreserved slots and turning it straight to a failure would fail PRs that did nothing wrong.
 * A calendar cutover would not have fixed that: a branch cut last week still carries its
 * hand-picked number today.
 *
 * ENFORCED_ABOVE solves it structurally. Every slot at or below a namespace's ceiling predates
 * the allocator and is grandfathered; every slot above it was created after the seed, so its
 * author had `steward slot` available and is expected to have used it. Measured on 2026-09-04,
 * against every local and remote ref: ZERO slots sat above these ceilings anywhere, so the flip
 * failed nothing that already existed.
 *
 * 🔴 EVERY FUNCTION HERE IS PURE. The checker owns git and the database; this owns the verdict.
 */

/** How a seeded row attributes itself. Must match steward-seed.mjs. */
export const HISTORICAL_HOLDER = "(historical)";

/**
 * The highest slot per namespace that predates enforcement.
 *
 * 🔴 THESE ARE MEASUREMENTS, NOT PREFERENCES, AND THEY DO NOT MOVE. They are `max(num)` per
 *    namespace in steward.migration_slots immediately after the git-history seed
 *    (2026-09-04: 1,852 rows). Raising one would grandfather a number somebody took by hand
 *    AFTER the allocator was available, which is the single thing this check exists to catch.
 *    A new namespace is deliberately absent: unknown namespaces are enforced from their first
 *    number, so inventing a prefix is not a way around the allocator.
 */
export const ENFORCED_ABOVE = Object.freeze({
  "": 1852,   // the shared plain sequence, still live: 1852 was taken 2026-08-31
  CA: 103,    // Andrews
  CC: 72,     // Cantrell
});

/** Normalise an email for comparison, and say whether it came from GitHub's noreply domain. */
function identityOf(email) {
  if (typeof email !== "string") return null;
  const text = email.trim().toLowerCase();
  if (!text) return null;
  const at = text.lastIndexOf("@");
  if (at < 1) return { full: text, local: text, noreply: false };
  // GitHub prefixes the login with the numeric user id: 34817036+chrisandrewsedu@...
  const local = text.slice(0, at).replace(/^\d+\+/, "");
  const domain = text.slice(at + 1);
  return { full: `${local}@${domain}`, local, noreply: domain === "users.noreply.github.com" };
}

/**
 * Are these two addresses the same person?
 *
 * 🔴 EXACT STRING EQUALITY WOULD SHIP A FALSE FAILURE. A reservation records `git config
 *    user.email`, but the commit this check reads in CI can carry GitHub's noreply form of the
 *    same person — 171 migration commits in this repo are authored by
 *    `34817036+chrisandrewsedu@users.noreply.github.com`. Comparing the raw strings reports
 *    "reserved by someone else" about a slot its own holder is committing, and the author has
 *    no way to make it pass.
 *
 * The relaxation is bounded to that domain: local parts are compared only when at least one
 * side is a noreply address. A general local-part rule would make chris@empowered.vote and
 * chris@example.com the same person.
 */
export function holdersMatch(a, b) {
  const x = identityOf(a);
  const y = identityOf(b);
  if (!x || !y) return false;
  if (x.full === y.full) return true;
  return (x.noreply || y.noreply) && x.local === y.local;
}

/** The command that would have produced this slot legitimately. */
function askFor(ns) {
  return ns ? `npm run steward --prefix backend -- slot ${ns} --purpose "..."`
    : `npm run steward --prefix backend -- slot shared --purpose "..."`;
}

/**
 * The verdict on one newly added migration file.
 *
 * @param {object} args
 * @param {{ns:string,num:string,key:string}} args.slot   from slotOf()
 * @param {string} args.filename                          basename, for the message
 * @param {string} args.author                            commit author, or git config locally
 * @param {object|null} args.row                          the steward.migration_slots row, if any
 * @returns {{verdict:string, ok:boolean, message:string}}
 */
export function classifyReservation({ slot, filename, author, row }) {
  const where = slot.ns ? `namespace ${slot.ns}` : "the shared sequence";

  if (!row) {
    const ceiling = ENFORCED_ABOVE[slot.ns] ?? 0;
    if (Number(slot.num) <= ceiling) {
      return {
        verdict: "legacy",
        ok: true,
        message: `${filename}: slot ${slot.key} predates the allocator (${where} is enforced above ${ceiling})`,
      };
    }
    return {
      verdict: "unreserved",
      ok: false,
      message: `${filename}: slot ${slot.key} was never reserved. Numbers above ${ceiling} in `
        + `${where} come from the allocator, so this one was counted by hand — which is invisible `
        + `to every other session until you push. Ask for one and rename:\n      ${askFor(slot.ns)}`,
    };
  }

  // 🔴 ABANDONED IS TESTED BEFORE OWNERSHIP, AND THE ORDER IS THE WHOLE RULE. Abandonment is a
  //    fact about the SLOT, not about who holds it, so `holdersMatch` first would let you
  //    quietly revive a number you yourself abandoned — the one case most likely to happen,
  //    since the abandoned rows in this table are all one author's. Caught by its own test
  //    failing, which is why the test says "rather than quietly reviving it".
  if (row.state === "abandoned") {
    return {
      verdict: "abandoned",
      ok: false,
      message: `${filename}: slot ${slot.key} was reserved and then ABANDONED by ${row.claimed_by} `
        + `("${row.purpose}"). Why it was abandoned is not recorded anywhere the next reader will `
        + `look, and a fresh number is one command away:\n      ${askFor(slot.ns)}`,
    };
  }

  if (row.claimed_by === HISTORICAL_HOLDER) {
    return {
      verdict: "historical",
      ok: false,
      message: `${filename}: slot ${slot.key} is already spent on history`
        + `${row.filename ? ` (${row.filename})` : ""}. Rename to a fresh number:\n      ${askFor(slot.ns)}`,
    };
  }

  if (holdersMatch(row.claimed_by, author)) {
    return {
      verdict: "yours",
      ok: true,
      message: `${filename}: slot ${slot.key} reserved by ${row.claimed_by} (${row.state})`,
    };
  }

  return {
    verdict: "other-holder",
    ok: false,
    message: `${filename}: slot ${slot.key} is reserved by ${row.claimed_by}`
      + `${row.branch ? ` on ${row.branch}` : ""} ("${row.purpose}"), and this file is authored by `
      + `${author}. This is the collision, caught before merge. Rename:\n      ${askFor(slot.ns)}`,
  };
}
