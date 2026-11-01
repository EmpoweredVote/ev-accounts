// Writing to the argument tree.
//
// routes/claims.ts reads the tree; this is what adds to it and rates it:
//
//   POST   /claims/:parentId/children — attach a `supports` or `opposes` claim to a parent
//   PUT    /claims/:claimId/rating    — this reader's 1-9 impact rating for one claim
//   PATCH  /claims/:claimId           — the author rewrites their own claim
//   DELETE /claims/:claimId           — 405: a claim is withdrawn, never removed
//   GET    /claims/:claimId/edits     — that claim's edit history, to anyone
//
// The paths are bare because app.ts mounts this router under the Focused Communities mount points
// (/fc/api and /api/fc), exactly as for its siblings.
//
// Five things in here are deliberate and worth reading before changing them:
//
//   1. 🔴 THE INSERT SUPPLIES FOUR COLUMNS. parent_claim_id, side, body, author_id — and nothing
//      else. path, depth and community_id are facts about the parent, derived by the database
//      (see "Position is not ours to set" below).
//   2. A hidden parent is a 404, not a 403, and is byte-identical to an absent one.
//   3. Validation runs before the rate limiter, so a malformed request never costs quota.
//   4. The response is the same Claim shape routes/claims.ts serializes, internals and all
//      withheld. The `Claim` type is imported rather than redeclared so the two cannot drift
//      without the compiler saying so.
//   5. 🔴 A RATING IS WRITTEN, NEVER SUMMED HERE. The route writes one row of
//      connect.claim_ratings; connect.bump_claim_rating_aggregate maintains rating_count and
//      rating_sum on the claim, and connect.claims.impact derives the mean from those (CA_0345).
//      The Bayesian formula exists in exactly one place and this file is not it.

import { Router } from 'express';
import type { Request, Response } from 'express';
import type { PoolClient } from 'pg';
import { pool } from '../config/database.js';
import { ts } from '../lib/sql.js';
import { requireAuth, type FcRequest } from '../middleware/auth.js';
import { requireConnected } from '../middleware/tierGuards.js';
import { postRateLimiter, ratingRateLimiter } from '../lib/rateLimit.js';
import { MAX_CLAIM_DEPTH } from '../lib/utils.js';
import type { Claim, ClaimSide } from './claims.js';

export const claimWritesRouter = Router();

// --- Request shape ---------------------------------------------------------

/**
 * The two sides, as the only two strings that count. Not a case-insensitive match and not a trim:
 * `side` is never typed by a human — a client picks one of two buttons — so 'Supports' means the
 * client is wrong, and quietly repairing it would let a broken client ship.
 */
const SIDES: readonly string[] = ['supports', 'opposes'];

/**
 * Body bounds. The database forbids only a blank body (claims_body_not_blank); these are the
 * interface's bounds, not the schema's, and both are named so the next person changes a number
 * rather than a condition.
 *
 * A claim is not a forum post. It is a single assertion that another claim supports or opposes,
 * and the whole value of the tree is that a long argument gets SPLIT into claims rather than
 * written as one. The house conventions are threads.ts:122 (title 5-150) and threads.ts:129
 * (body 10-5000); this takes the minimum from the second and goes an order of magnitude below it
 * at the top.
 *
 *   MIN 10  — the house minimum for a body. It rules out "Yes", "No." and "+1", which are votes
 *             rather than claims; agreement belongs in PUT /claims/:claimId/rating below, not in
 *             a child.
 *   MAX 500 — a claim needing 5,000 characters is several claims, and letting someone write it as
 *             one defeats the structure the tree exists to impose. 500 is also Kialo's own limit,
 *             and Kialo is the stated model for this feature.
 */
const BODY_MIN = 10;
const BODY_MAX = 500;

/**
 * A uuid in the one spelling Postgres gives back — the same guard, and the same reasoning, as
 * routes/claims.ts. Checked BEFORE the id reaches a query: a non-uuid cannot name a claim, so it
 * owes a 404 rather than an anonymous 500 from a 22P02 one layer down, and costs no round trip.
 */
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * Claim creation gets its OWN bucket inside the shared `fc:rl` window.
 *
 * The shape is deliberately the one postRateLimiter already enforces — 5 an hour, sliding — so
 * there is one answer in this module to "how often may somebody write?". What is NOT shared is
 * the counter: identifiers are namespaced, so arguing in the tree cannot exhaust the quota for
 * posting in a thread, or the reverse. Same limiter instance, two buckets.
 */
const RATE_LIMIT_NAMESPACE = 'claim:';

/**
 * Rating gets its own bucket AND its own limiter — a different window, not just a different
 * counter. postRateLimiter's 5 an hour is priced for permanent, moderatable text; a rating is one
 * integer, upserted, with no text and nothing to moderate, and five an hour would refuse a reader
 * part-way down their first column of children. See ratingRateLimiter in ../lib/rateLimit.ts.
 */
const RATING_RATE_LIMIT_NAMESPACE = 'rating:';

/**
 * The rating scale, as the only values that count. The same two bounds live in
 * connect.claim_ratings' CHECK (value BETWEEN 1 AND 9) (CA_0341) and in the neutral midpoint
 * CA_0345's impact formula is built on; the database is what BINDS, and this is what gives a
 * contributor a sentence instead of a 500 out of a constraint violation.
 *
 * 🔴 NINE POINTS, AND THE MIDPOINT MATTERS. 5 is neutral — it is the value an unrated claim's
 * impact already sits at — so a rating of 5 says "this changes nothing", which is a real answer
 * and not an abstention. There is no abstention: not rating is how you abstain.
 */
const RATING_MIN = 1;
const RATING_MAX = 9;

// --- Responses -------------------------------------------------------------

/**
 * Missing, malformed and hidden are ONE answer.
 *
 * Note this differs from the read side on purpose. GET /claims/:id serves a hidden claim as a
 * tombstone — 200, body and author withheld — because the claim is already visible as a tombstone
 * in its parent's column, and 404ing it would make the whole subtree beneath it unreachable.
 * Reading is about not orphaning what is there. WRITING UNDER one is a different question: a
 * hidden claim has been withdrawn from the argument, so there is nothing to attach to, and a 403
 * would confirm to the writer that a specific claim exists and was moderated. So: 404, with the
 * same body an absent id gets, so the two cannot be told apart.
 */
function notFound(res: Response): void {
  res.status(404).json({ error: { code: 'CLAIM_NOT_FOUND', message: 'Claim not found' } });
}

/**
 * A hidden ANCESTOR, told apart from a hidden parent.
 *
 * Still a 404 — there is nothing to attach to either way — but a contributor who just typed a
 * paragraph deserves to know whether it was THIS point that was removed or the discussion above
 * it, because only one of those suggests finding another place to make the argument.
 *
 * This discloses nothing the read API does not. GET /claims/:id serves any claim the caller can
 * name, and loadBreadcrumb already returns a hidden ancestor with an empty body — so anyone
 * holding this parent's id can already see that an ancestor was withdrawn. The hidden PARENT case
 * stays byte-identical to the absent one; that constraint is untouched.
 */
function ancestorHidden(res: Response): void {
  res.status(404).json({
    error: {
      code: 'ANCESTOR_NOT_VISIBLE',
      message: 'The discussion above this point was removed',
    },
  });
}

/**
 * The claim has been merged into another, so it is superseded rather than withdrawn. Used for a
 * parent that cannot take a child and for a claim that cannot take a rating — the same fact
 * about the same kind of row, and the message was already written to say "this point".
 *
 * 409 rather than 404: the claim is there, readable, and the write is refused because of its
 * state. The target id rides along so the client can offer the contributor the claim that now
 * carries this argument instead of silently losing what they wrote — or, for a rating, so it can
 * send the rating to the claim that readers will actually meet.
 */
function claimMerged(res: Response, mergedInto: string): void {
  res.status(409).json({
    error: {
      code: 'CLAIM_MERGED',
      message: 'This point has been merged into another claim',
      mergedInto,
    },
  });
}

function badRequest(res: Response, code: string, message: string): void {
  res.status(400).json({ error: { code, message } });
}

/** A request that is well-formed and refers to real things, but asks for something disallowed. */
function unprocessable(res: Response, code: string, message: string): void {
  res.status(422).json({ error: { code, message } });
}

/**
 * The four things that can fail in this file, as the caller is told about them.
 *
 * They are separate because "Could not create the claim" is a lie when a rating failed, and a
 * client that retries on one and not the other needs to be able to tell them apart. Frozen
 * objects so a handler cannot mutate the shared literal on its way out.
 */
const CREATE_FAILED = Object.freeze({
  code: 'CLAIM_CREATE_FAILED',
  message: 'Could not create the claim',
});
const RATING_FAILED = Object.freeze({
  code: 'CLAIM_RATING_FAILED',
  message: 'Could not save the rating',
});
const EDIT_FAILED = Object.freeze({
  code: 'CLAIM_EDIT_FAILED',
  message: 'Could not save the edit',
});
const EDITS_FETCH_FAILED = Object.freeze({
  code: 'CLAIM_EDITS_FETCH_FAILED',
  message: 'Could not read the edit history',
});

/**
 * A query failed. The real message goes to the logs; the caller gets a fixed string.
 *
 * Same discipline as routes/claims.ts and deliberately unlike routes/threads.ts, which echoes
 * `err.message` back: a raw Postgres message names columns, constraints, types and sometimes
 * values, which turns a failed write into a schema probe.
 */
function internalError(
  res: Response,
  context: string,
  err: unknown,
  failure: { code: string; message: string }
): void {
  console.error(`[focused_communities] ${context}:`, (err as Error).message);
  res.status(500).json({ error: { ...failure } });
}

// --- Serialization ---------------------------------------------------------

/** What RETURNING hands back — exactly the columns toClaim needs, and no others. */
interface InsertedClaimRow {
  id: string;
  side: ClaimSide | null;
  body: string;
  author_display_name: string | null;
  moderation_status: string;
  /**
   * NUMERIC, so node-postgres hands it over as a string. See ClaimRow.impact in
   * routes/claims.ts for why CA_0345 rounds it to four decimals.
   *
   * It is read back rather than assumed to be 5: `impact` is GENERATED ALWAYS, so a row
   * fresh out of INSERT ... RETURNING already carries whatever the formula says, and
   * hardcoding the neutral value here would be this file keeping a second copy of a
   * formula that is supposed to live in one place.
   */
  impact: string;
  rating_count: number;
  child_supports_count: number;
  child_opposes_count: number;
  merged_into_claim_id: string | null;
  created_at: string;
  updated_at: string;
}

const RETURNING_COLUMNS = `id, side, body, author_display_name, moderation_status,
            impact, rating_count,
            child_supports_count, child_opposes_count, merged_into_claim_id,
            ${ts('created_at')}, ${ts('updated_at')}`;

/**
 * The Claim shape, identical to routes/claims.ts's toClaim.
 *
 * It is written out again rather than imported because claims.ts does not export it, and this
 * task may not edit that file. The `Claim` return type is imported, though, so a field added or
 * renamed there fails to compile here rather than silently serving two shapes under one name.
 *
 * author_id, community_id, path, depth, moderation_status and the raw count column names never
 * appear in a response — isHidden is the only thing a reader learns about moderation. A row
 * created a millisecond ago is always visible, so the hidden branch is unreachable here; it is
 * kept so this function stays interchangeable with the reader's.
 *
 * `myRating` is a PARAMETER rather than a field of the row, because it is the one per-caller
 * value in a Claim and the two writers that build one know it from different places: a claim
 * created a millisecond ago has none (null, stated), and an edited claim may well have one the
 * author cast themselves (read back, see the edit route).
 */
function toClaim(row: InsertedClaimRow, myRating: number | null): Claim {
  const isHidden = row.moderation_status !== 'visible';
  return {
    id: row.id,
    side: row.side,
    body: isHidden ? '' : row.body,
    authorPseudonym: isHidden ? null : (row.author_display_name ?? null),
    impact: Number(row.impact),
    ratingCount: row.rating_count,
    childSupports: row.child_supports_count,
    childOpposes: row.child_opposes_count,
    isHidden,
    mergedInto: row.merged_into_claim_id ?? null,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    myRating,
  };
}

// --- Position is not ours to set -------------------------------------------
//
// 🔴 READ THIS BEFORE ADDING path, depth OR community_id TO THE INSERT BELOW.
//
// connect.derive_claim_position (CA_0341 §4a) is a BEFORE INSERT OR UPDATE OF parent_claim_id
// trigger. It looks the parent up FOR UPDATE and sets NEW.path, NEW.depth and NEW.community_id
// from it, DISCARDING whatever the statement supplied for those three. So sending them is not
// merely redundant — it is code that claims to decide something it does not decide, and the next
// reader has to run the trigger to find out which of the two is real.
//
// Two properties come from that trigger, and must not be reimplemented here:
//
//   * CONCURRENCY. FOR UPDATE on the parent serializes this insert against a curation move of the
//     same parent (Task 7). Computed in the route instead, the sequence is: we read P's path, a
//     maven moves P under G and sweeps P's descendants, we insert with the pre-move path — and
//     that child is absent from G's subtree forever, with nothing anywhere that notices. The
//     AFTER-INSERT count trigger's lock does not help: by the time it runs, the path is decided.
//   * EXISTENCE. A parent that is not there raises from the trigger, race-free. The lookup below
//     is therefore NOT an existence check wearing a different hat — it is there for `hidden`,
//     which the database has no opinion about, and for turning an absent parent into a clean 404
//     instead of a 500 out of a RAISE.
//
// The INSERT names four columns. That is the whole statement.
//
// --- Visibility is checked INSIDE the write, under the same lock --------------------------
//
// What the trigger does NOT do is notice that the parent has been HIDDEN. Hiding is a Task 7
// UPDATE of moderation_status; the derivation reads only path, depth and community_id, none of
// which hiding changes, so a child would sail straight through. A pre-flight SELECT does not
// close that either: it answers about an instant that is over by the time the INSERT runs, and
// the trigger's own FOR UPDATE makes it worse rather than better — our insert blocks on the
// in-flight hide, wakes AFTER it commits, finds path and depth unchanged, and cheerfully
// attaches a child to a claim that has just been withdrawn.
//
// So the predicate lives in the writing statement, under the row lock:
//
//   INSERT INTO connect.claims (…)
//   SELECT p.id, … FROM connect.claims p
//    WHERE p.id = $1 AND p.moderation_status = 'visible'
//      FOR UPDATE OF p
//
// This is the same mechanism §4a already relies on, stated in its own words: "T1 blocks, and when
// it wakes READ COMMITTED re-evaluates the lookup". That re-evaluation is the point. FOR UPDATE
// waits on the hider's row lock; when the hider commits, READ COMMITTED re-checks this statement's
// quals against the NEW row version, the row no longer satisfies `moderation_status = 'visible'`,
// the SELECT yields nothing and the INSERT inserts nothing. Zero rows back is not an error here —
// it is the race being caught, and it answers 404 like any other hidden parent. `EXPLAIN` confirms
// the shape the argument depends on: the filter sits on the scan BENEATH the LockRows node, so it
// is part of what gets re-evaluated, not applied before the wait.
//
// The same lock closes the moved-parent and merged-parent variants of the window, because all
// three are UPDATEs to the parent row that this now serializes against.
//
// --- Three more things the writing statement has to establish --------------------------------
//
// VISIBLE PARENT is necessary but not sufficient. Two further states make a child pointless or
// harmful, and both belong in the same statement for the same reason.
//
//   1. A HIDDEN ANCESTOR. A claim whose grandparent is hidden is unreachable — no reader can walk
//      down to it — and yet it still increments its parent's child_supports_count or
//      child_opposes_count. So it would corrupt the pro/con balance readers DO see while being
//      invisible itself, which is strictly worse than refusing it. The parent row already carries
//      `path`, its root-first ancestors, so the whole line is one NOT EXISTS away.
//
//      🔴 RESIDUAL RACE, DELIBERATELY LEFT OPEN: FOR UPDATE OF p locks the parent, not the
//      ancestors, so an ancestor hidden between this statement's snapshot and its commit still
//      admits one child. Closing it properly belongs to Task 7 — hiding a claim should mark or
//      reject its subtree — not to a wider lock here, which would serialize every write in a
//      community behind every other. This is a known gap with an owner, not an oversight.
//
//   2. A MERGED PARENT. merged_into_claim_id means the claim has been superseded: readers follow
//      the merge to the target, so a child hung here is live text nobody will ever meet.
//
//      🔴 DIRECT PARENT ONLY, AND THIS ASYMMETRY IS DELIBERATE. A merged ANCESTOR is NOT rejected.
//      Merging keeps the subtree readable — the merge is a redirect, not a removal — so a claim
//      under a merged ancestor is still reachable and still counted correctly. Hiding removes;
//      merging redirects. Do not "fix" this into symmetry with the ancestor rule above.
//
//   3. DEPTH is NOT in this statement. It is enforced by the route (a 422 the contributor can
//      understand) and by CA_0344's CHECK constraint (which binds postgres too, exempt from every
//      grant). Adding it here as a fourth predicate would turn an over-deep write into a silent
//      zero-row 404 that says nothing useful; letting the CHECK raise instead keeps the loud
//      failure loud. Task 7's move will hit that same constraint rather than silently deepening
//      the tree, which is the point of putting it in the table.
//
// WHY ONE STATEMENT RATHER THAN BEGIN / SELECT FOR UPDATE / INSERT / COMMIT
// The explicit transaction gives the identical guarantee and costs more to hold: this pool is
// max: 3 (config/database.ts) in front of a shared Supavisor pooler, so a checked-out client
// across four round trips ties up a third of the module's connections for the duration and adds a
// ROLLBACK-and-release path that has to be right on every branch. A single statement is its own
// transaction, cannot leak a client, and cannot be left open by an early return.
//
// NO NEW DEADLOCK. The lock order is unchanged — FOR UPDATE on the parent, then the AFTER INSERT
// count trigger's UPDATE of it — and this merely takes that first lock a moment earlier in the
// same transaction. The derivation trigger's own FOR UPDATE on the same row then finds a lock the
// transaction already holds, which is a no-op, not a wait. 🔴 Note this is FOR UPDATE and not FOR
// SHARE, for exactly the reason §4a gives: a shared lock here would need upgrading when the count
// trigger runs, which is the lock-upgrade deadlock that migration was written to avoid.

// --- Route -----------------------------------------------------------------

// POST /claims/:parentId/children — attach a claim to a parent, on one side or the other.
//
// Order is: canonicalise the id, validate the request, SPEND QUOTA, read the parent, write.
//
// Validation precedes the limiter (as in threads.ts and posts.ts) so a client bug cannot burn a
// writer's hourly allowance — validation needs no database and tells the caller nothing it did
// not already know.
//
// 🔴 THE LIMITER PRECEDES THE PARENT LOOKUP, and that ordering is the security property, not a
// detail. The lookup answers "is this uuid a real, visible, unmerged claim?". Behind the limiter
// that question costs quota; in front of it, an unlimited stream of failed lookups costs nothing
// and the endpoint becomes a free existence oracle over claim ids — a caller could enumerate
// which uuids are real claims without ever spending a token. The price is that attaching to a
// claim withdrawn a second ago now costs one of five an hour. That is the right trade: it is
// five an hour, it is recoverable by waiting, and the alternative is unbounded and silent.
claimWritesRouter.post(
  '/claims/:parentId/children',
  ...requireAuth,
  requireConnected,
  async (req: Request, res: Response) => {
    const user = (req as FcRequest).user!;

    const raw = req.params.parentId as string;
    if (!UUID_RE.test(raw)) {
      notFound(res); // names no claim: no query run
      return;
    }
    const parentId = raw.toLowerCase();

    const { side, body } = req.body as { side?: unknown; body?: unknown };

    if (typeof side !== 'string' || !SIDES.includes(side)) {
      badRequest(res, 'INVALID_SIDE', "side must be 'supports' or 'opposes'");
      return;
    }

    const trimmedBody = (typeof body === 'string' ? body : '').trim();
    if (trimmedBody.length < BODY_MIN || trimmedBody.length > BODY_MAX) {
      badRequest(res, 'INVALID_BODY', `body must be ${BODY_MIN}-${BODY_MAX} characters`);
      return;
    }

    // 🔴 FAIL CLOSED. A limiter that cannot answer refuses the write; it does not wave it
    // through. Everything written here is permanent — there is no DELETE grant on
    // connect.claims (CA_0341), so spam has to be hidden by a maven one claim at a time, and
    // there is no undo. Failing open during a Redis outage trades a recoverable inconvenience
    // (a contributor retries in a minute) for an unrecoverable one (an unbounded flood of rows
    // nobody can remove). Note the limiter already degrades to an always-allow stub when
    // Upstash is simply unconfigured (lib/rateLimit.ts), so reaching this catch means a
    // configured limiter actually failed — which is exactly when caution is worth its cost.
    let success: boolean;
    let reset: number;
    try {
      ({ success, reset } = await postRateLimiter.limit(`${RATE_LIMIT_NAMESPACE}${user.id}`));
    } catch (err) {
      internalError(res, `claim rate limit for ${user.id}`, err, CREATE_FAILED);
      return;
    }
    if (!success) {
      // reset is in milliseconds; Retry-After is in seconds
      res.set('Retry-After', String(Math.ceil((reset - Date.now()) / 1000)));
      res.status(429).json({ reason: 'rate_limited' });
      return;
    }

    // The parent, read once. This exists to produce a DISTINGUISHABLE error — withdrawn point
    // versus withdrawn discussion versus merged versus too deep — none of which a zero-row
    // INSERT could tell apart. It is not the guarantee: the predicates in the writing statement
    // below hold whether or not this read ran. See "Visibility is checked INSIDE the write".
    interface ParentState {
      moderation_status: string;
      merged_into_claim_id: string | null;
      depth: number;
      has_hidden_ancestor: boolean;
    }
    let parent: ParentState | null;
    try {
      const { rows } = await pool.query<ParentState>(
        `SELECT p.moderation_status, p.merged_into_claim_id, p.depth,
                EXISTS (SELECT 1 FROM connect.claims a
                         WHERE a.id = ANY (p.path) AND a.moderation_status <> 'visible')
                  AS has_hidden_ancestor
           FROM connect.claims p
          WHERE p.id = $1`,
        [parentId]
      );
      parent = rows[0] ?? null;
    } catch (err) {
      // A database that cannot answer is not a missing claim. 404 here would tell the writer
      // their parent is gone, which is a different and much worse thing to be wrong about.
      internalError(res, `claim parent lookup ${parentId}`, err, CREATE_FAILED);
      return;
    }

    // Absent and hidden stay byte-identical, and neither is ever a 403.
    if (!parent || parent.moderation_status !== 'visible') {
      notFound(res);
      return;
    }

    // Unreachable subtree: still a 404, but one the contributor can act on differently.
    if (parent.has_hidden_ancestor) {
      ancestorHidden(res);
      return;
    }

    // Superseded, not removed — so 409 with somewhere to go. Direct parent only; see the comment
    // block above for why a merged ANCESTOR is deliberately allowed.
    if (parent.merged_into_claim_id !== null) {
      claimMerged(res, parent.merged_into_claim_id);
      return;
    }

    // A child of a parent at the cap would be MAX_CLAIM_DEPTH + 1. The message names no number:
    // "50" is not something the reader can do anything with, and the cap may move.
    if (parent.depth >= MAX_CLAIM_DEPTH) {
      unprocessable(res, 'MAX_DEPTH_REACHED', 'This discussion has reached its maximum depth');
      return;
    }

    // Four columns. trg_claims_derive_position fills path, depth and community_id from the parent;
    // trg_claims_snapshot_display_name fills author_display_name from author_id — which is why no
    // name the route can see, pseudonym or legal, is ever written here.
    // The child's own counts start at 0 by default; the AFTER INSERT count trigger moves the
    // PARENT's count for this side. Neither is the route's to write.
    let row: InsertedClaimRow | null;
    try {
      const { rows } = await pool.query<InsertedClaimRow>(
        `INSERT INTO connect.claims (parent_claim_id, side, body, author_id)
         SELECT p.id, $2::text, $3::text, $4::uuid
           FROM connect.claims p
          WHERE p.id = $1
            AND p.moderation_status = 'visible'
            AND p.merged_into_claim_id IS NULL
            AND NOT EXISTS (
                  SELECT 1 FROM connect.claims a
                   WHERE a.id = ANY (p.path) AND a.moderation_status <> 'visible'
                )
            FOR UPDATE OF p
         RETURNING ${RETURNING_COLUMNS}`,
        [parentId, side, trimmedBody, user.id]
      );
      row = rows[0] ?? null;
    } catch (err) {
      internalError(res, `claim create under ${parentId}`, err, CREATE_FAILED);
      return;
    }

    // Zero rows is a race being caught, not a failure: between the read above and this statement
    // the parent was hidden, merged, or moved under something hidden, and the locked
    // re-evaluation dropped it. Which of those it was is not worth a second round trip to find
    // out — the contributor retries and the read above then tells them precisely. So: the plain
    // 404, the same one an already-hidden parent gets.
    if (!row) {
      notFound(res);
      return;
    }

    // Cache invalidation is NOT done here, and not because it is missing. It lives in
    // middleware/claimInvalidation.ts, mounted above this router, which fires on any non-GET
    // under /claims/ that answered 2xx — so this handler, and any write route added after it, is
    // covered without anyone remembering. What that buys and what it does not is written out
    // there: the community's shape entry is dropped exactly, the default-parameter node pages are
    // dropped for the claims this write changed, and anything keyed by a deeper cursor carries a
    // deliberate 30-second staleness. Do not add a second, partial invalidation here.

    // 🔴 myRating is null, and not because it is unimplemented. A claim created a millisecond
    // ago has no ratings — least of all from its author, who does not get a free one for
    // writing it — so it is null and `impact` is the neutral 5 the prior puts an unrated claim
    // at. This is the only field in the response this route states rather than reads back,
    // because the row it would read is one this statement did not and must not create.
    res.status(201).json({ data: toClaim(row, null) });
  }
);

// --- Rating a claim --------------------------------------------------------
//
// PUT /claims/:claimId/rating — "how much does this claim move the argument?", 1 to 9.
//
// 🔴 WHAT THIS ROUTE DOES NOT DO: arithmetic. It writes ONE row of connect.claim_ratings. The
// trigger connect.bump_claim_rating_aggregate keeps rating_count and rating_sum on the claim in
// step with that table, and connect.claims.impact is a generated column deriving the
// Bayesian-weighted mean from the two (CA_0345, rulings R37/R38). Computing the mean here would
// put the formula in two places, and the two would drift the first time the prior weight moved.
// The route's whole contribution to the number is sending the value through unchanged.
//
// PUT, NOT POST, AND THAT IS THE CONTRACT. A person has at most one rating per claim
// (claim_ratings_one_per_user, UNIQUE on (claim_id, user_id)), so this is idempotent: the same
// request twice leaves the same single row, and a different value replaces rather than adds. The
// statement says so in SQL — ON CONFLICT ... DO UPDATE — rather than reading first and branching,
// which would race another tab belonging to the same person.
//
// --- Why a rating is allowed where a child claim is not --------------------------------------
//
// Three of the four refusals on POST /children are deliberately absent here:
//
//   * A HIDDEN ANCESTOR does not block a rating. A child claim under one is unreachable text
//     that still moves its parent's visible child counts, which is why it is refused. A rating
//     adds no text, creates no node and moves no count a reader can see on another claim — it
//     annotates a row that already exists. Rating something you reached by its id is harmless,
//     and the extra NOT EXISTS over c.path would buy nothing for the cost of a scan.
//   * THE DEPTH CAP does not apply: nothing here gets deeper.
//   * The claim's OWN hiding and merging DO apply, for the reasons below.
//
// A HIDDEN claim is a 404, byte-identical to an absent one, exactly as on the write route. Its
// body is withheld from every reader, so a rating of it is a rating of something the rater cannot
// read; and 403 would confirm that a specific id names a claim somebody moderated.
//
// A MERGED claim is a 409 naming the target. The claim is readable and the refusal is about its
// state: readers follow the merge, so ratings left on the superseded copy split the signal for
// one argument across two rows and the impact a reader sees is the smaller half. The target id
// rides along so a client can re-send the rating where it will count. Note this is the opposite
// asymmetry to the child route's: there, a merged ANCESTOR is fine because the subtree is still
// reachable. Here there is no ancestor question at all.
//
// --- Shape of the write -----------------------------------------------------------------------
//
// Both predicates sit in the WRITING statement under FOR UPDATE OF c, not only in a read before
// it, for the same reason the child insert does: a pre-flight SELECT answers about an instant
// that is over by the time the write runs. FOR UPDATE waits on a concurrent hide or merge of the
// claim; when that commits, READ COMMITTED re-evaluates these quals against the new row version,
// the SELECT yields nothing and nothing is inserted. Zero rows is the race being caught.
//
// 🔴 TWO STATEMENTS, AND THE SECOND ONE IS NOT OPTIONAL. The aggregate cannot be read back from
// the upsert's own RETURNING, and not because of where the columns live: the trigger that moves
// them is an AFTER trigger, so it has not run when that statement's output is produced. Folding
// the read into a CTE on the same statement has the identical problem and hides it better — the
// SELECT would see the pre-trigger snapshot and the route would answer with the impact from
// BEFORE this rating. So the aggregate is read in a second statement, after the first has
// committed. Each is its own transaction through pool.query, so no client is held across the two
// (this pool is max: 3 behind a shared pooler; see the note on the child insert).
//
// The read-back is a fresh number, not a frozen one: another rater may have moved it in between.
// That is correct — `impact` is a live aggregate, not a receipt for this request — and it is why
// the response carries the aggregate rather than an echo of what was sent.
//
// --- The two snapshot columns -------------------------------------------------------------
//
// rater_account_age_days and rater_verification_status are written on every rating, including a
// re-rate, although the aggregate ignores both today. They are properties of the rater AT THE
// MOMENT OF RATING and cannot be reconstructed afterwards: an account that verifies next month
// must not retroactively reweight what it said today (CA_0341 section 2 says the same from the
// schema side). Writing them later is impossible; writing them now is two fields on a row that
// is being written anyway. The re-rate refreshes them because a replaced value is a NEW rating
// cast at a new moment, and a snapshot describing the value it no longer accompanies would be
// worse than none.
//
// Both come off the account composite requireAuth already loaded — getAccountMe returns
// public.users.created_at and the connected profile's verification_status, and loadUser spreads
// the whole thing onto req.user. So this costs no query, and in particular needs nothing from the
// `inform` schema, which focused_communities_app cannot reach. Either may be null (see
// raterSnapshot); null is recorded as null and never guessed at.

/** What the second statement reads back: the live aggregate, after the trigger has run. */
interface ClaimAggregateRow {
  impact: string;
  rating_count: number;
}

/** What the classifying lookup reads when the write matched nothing. */
interface RatedClaimState {
  moderation_status: string;
  merged_into_claim_id: string | null;
}

/**
 * The rater, as they were at this instant.
 *
 * 🔴 NULL IS AN ANSWER, AND INVENTING ONE IS NOT. If the composite does not carry a usable
 * created_at — it is optional on AccountUser because that interface narrows a record assembled
 * from several tables — the age is recorded as NULL, which reads as "not known at the time"
 * rather than as "a brand new account", which 0 would.
 *
 * The clamp at 0 is for clock skew between this process and the database that stamped
 * created_at, which can make a seconds-old account look negative. A negative age is not a fact
 * about anybody; 0 for an account made moments ago is.
 */
function raterSnapshot(user: FcRequest['user']): {
  ageDays: number | null;
  verification: string | null;
} {
  const created = user?.created_at ? Date.parse(user.created_at) : NaN;
  const ageDays = Number.isFinite(created)
    ? Math.max(0, Math.floor((Date.now() - created) / 86_400_000))
    : null;
  return { ageDays, verification: user?.connected_profile?.verification_status ?? null };
}

// Order is: canonicalise the id, validate the value, SPEND QUOTA, write, read the aggregate back.
//
// 🔴 THE LIMITER PRECEDES EVERY LOOKUP, for the reason spelled out on the child route: behind it,
// "is this uuid a real, visible, unmerged claim?" costs quota; in front of it the endpoint is a
// free existence oracle over claim ids. That holds harder here than there, because this route is
// cheap enough to be generous with (60 an hour) and so would be the better oracle of the two.
//
// Validation still precedes the limiter: it needs no database and tells the caller nothing it did
// not already know, so a client bug must not burn a reader's allowance.
claimWritesRouter.put(
  '/claims/:claimId/rating',
  ...requireAuth,
  requireConnected,
  async (req: Request, res: Response) => {
    const user = (req as FcRequest).user!;

    const raw = req.params.claimId as string;
    if (!UUID_RE.test(raw)) {
      notFound(res); // names no claim: no query run
      return;
    }
    const claimId = raw.toLowerCase();

    const { value } = req.body as { value?: unknown };

    // A whole number, as a number. Not a numeric string and not 4.5: `value` is never typed by a
    // human — a client picks one of nine positions on a scale — so '7' or 7.5 means the client is
    // wrong, and quietly repairing it would let a broken client ship. Same reasoning as `side`.
    // Number.isInteger is also what rules out NaN and Infinity, which >= 1 && <= 9 would not.
    if (
      typeof value !== 'number' ||
      !Number.isInteger(value) ||
      value < RATING_MIN ||
      value > RATING_MAX
    ) {
      badRequest(
        res,
        'INVALID_RATING',
        `value must be a whole number from ${RATING_MIN} to ${RATING_MAX}`
      );
      return;
    }

    // Fail CLOSED, as the child route does: a limiter that cannot answer refuses the write.
    // Milder consequences here — a rating is one integer and can be re-cast — but a Redis outage
    // is exactly when an unmetered write endpoint is worth the least and costs the most.
    let success: boolean;
    let reset: number;
    try {
      ({ success, reset } = await ratingRateLimiter.limit(
        `${RATING_RATE_LIMIT_NAMESPACE}${user.id}`
      ));
    } catch (err) {
      internalError(res, `claim rating rate limit for ${user.id}`, err, RATING_FAILED);
      return;
    }
    if (!success) {
      // reset is in milliseconds; Retry-After is in seconds
      res.set('Retry-After', String(Math.ceil((reset - Date.now()) / 1000)));
      res.status(429).json({ reason: 'rate_limited' });
      return;
    }

    const { ageDays, verification } = raterSnapshot(user);

    let rated: boolean;
    try {
      const { rows } = await pool.query<{ claim_id: string }>(
        `INSERT INTO connect.claim_ratings
                     (claim_id, user_id, value, rater_account_age_days, rater_verification_status)
         SELECT c.id, $2::uuid, $3::int, $4::int, $5::text
           FROM connect.claims c
          WHERE c.id = $1
            AND c.moderation_status = 'visible'
            AND c.merged_into_claim_id IS NULL
            AND c.parent_claim_id IS NOT NULL
            FOR UPDATE OF c
         ON CONFLICT (claim_id, user_id) DO UPDATE
            SET value                     = EXCLUDED.value,
                rater_account_age_days    = EXCLUDED.rater_account_age_days,
                rater_verification_status = EXCLUDED.rater_verification_status,
                updated_at                = now()
         RETURNING claim_id`,
        [claimId, user.id, value, ageDays, verification]
      );
      rated = rows.length > 0;
    } catch (err) {
      internalError(res, `claim rating on ${claimId}`, err, RATING_FAILED);
      return;
    }

    // Zero rows: the claim is absent, hidden, merged or a ROOT — or was one of those by the time
    // the locked statement re-evaluated its quals. Unlike the child route, the classifying lookup
    // runs HERE rather than before the write, so the happy path costs two round trips and only a
    // refusal pays for a third. Nothing is lost by the ordering: the question is about the
    // claim's state, and the state that matters is the one the write saw.
    if (!rated) {
      let claim: RatedClaimState | null;
      try {
        const { rows } = await pool.query<RatedClaimState>(
          `SELECT c.moderation_status, c.merged_into_claim_id
             FROM connect.claims c
            WHERE c.id = $1`,
          [claimId]
        );
        claim = rows[0] ?? null;
      } catch (err) {
        // A database that cannot answer is not a missing claim. 404 here would tell the rater
        // the claim is gone, which is a different and much worse thing to be wrong about.
        internalError(res, `claim rating lookup ${claimId}`, err, RATING_FAILED);
        return;
      }

      // Merged is the one refusal with somewhere to go. A hidden claim that is ALSO merged stays
      // hidden first: the 404 withholds more, and a withdrawn claim's merge target is not
      // something this route should volunteer. Absent and hidden stay byte-identical, and
      // neither is ever a 403.
      if (claim && claim.moderation_status === 'visible' && claim.merged_into_claim_id !== null) {
        claimMerged(res, claim.merged_into_claim_id);
        return;
      }
      // 🔴 A ROOT CANNOT BE RATED, and the refusal is a 404 like every other.
      //
      // A root is the community's question, seeded by trg_communities_seed_root_claim with no
      // author and no side. It is not a proposition anybody advanced, so "how much weight does
      // this deserve" has no meaning for it — and an impact on a root is not inert: it is served
      // on the root node body and drawn as the depth-0 dot on the minimap, where it reads as a
      // rating of the topic itself. The id is one public GET away, so this was reachable by any
      // connected account.
      //
      // Every other write in the module already refuses a root — move, merge and hide by R53,
      // edit by R44's author check falling through on author_id IS NULL. Rating was the one hole.
      // It is 404 rather than 422 for the reason the rest of this branch is: the rater learns
      // nothing about the claim from the refusal.
      notFound(res);
      return;
    }

    // The aggregate, after the AFTER trigger. See "Shape of the write" for why this cannot be
    // folded into the statement above.
    let aggregate: ClaimAggregateRow | null;
    try {
      const { rows } = await pool.query<ClaimAggregateRow>(
        `SELECT c.impact, c.rating_count FROM connect.claims c WHERE c.id = $1`,
        [claimId]
      );
      aggregate = rows[0] ?? null;
    } catch (err) {
      internalError(res, `claim rating aggregate ${claimId}`, err, RATING_FAILED);
      return;
    }

    if (!aggregate) {
      // The upsert matched this row a moment ago and connect.claims has no DELETE grant, so
      // there is no ordinary way to be here. 500 rather than 404: the rating WAS stored, and
      // telling the caller the claim does not exist would be the worse lie.
      internalError(
        res,
        `claim rating aggregate ${claimId}`,
        new Error('the claim vanished between its rating and the read-back'),
        RATING_FAILED
      );
      return;
    }

    // 🔴 THE RATER'S OWN VALUE IS NOT ECHOED, AND NO OTHER PERSON'S EVER APPEARS. The response is
    // the aggregate and nothing else: an individual rating is readable only as `myRating` on the
    // claim's own node, only by the person who cast it. The caller already knows what they just
    // sent, so echoing it would add nothing and would make this body look like one that could
    // carry somebody else's.
    //
    // A rating moves `impact` on the claim, which changes its node body, its parent's column
    // ordering and the community's shape payload. All three are dropped by
    // middleware/claimInvalidation.ts, mounted above this router — see the note on the create
    // handler. The rater sees their own rating immediately whatever the cache holds: their reads
    // carry credentials and a personalized body is never cached (isShareable in routes/claims.ts).
    res.json({
      data: { impact: Number(aggregate.impact), ratingCount: aggregate.rating_count },
    });
  }
);

// --- Editing a claim -------------------------------------------------------
//
// PATCH /claims/:claimId — the author rewrites their own claim.
//
// 🔴 THIS IS THE ONE ROUTE IN THE MODULE THAT HOLDS A POOL CLIENT ACROSS ROUND TRIPS, and the
// reason is connect.log_claim_edit. That trigger reads current_setting('fc.actor_id', true) and
// RAISES when it is unset — claim_edits.actor_id is NOT NULL, and an edit with no recorded actor
// is an unaudited edit — so the setting and the UPDATE must be in the SAME transaction. There is
// no way to say that in one statement:
//
//   * set_config(…, true) is transaction-local, and a single pool.query is its own transaction,
//     so the setting would be gone before the UPDATE's trigger ran.
//   * set_config(…, false) would survive, which is worse: it would survive onto the next request
//     that checks out the same connection, and attribute THAT person's edit to this one.
//   * A CTE — WITH cfg AS (SELECT set_config(…)) UPDATE … — is not a guarantee. The evaluation
//     order of a CTE relative to a data-modifying statement's AFTER triggers is not something to
//     bet a NOT NULL audit column on.
//
// So: BEGIN, set_config, UPDATE, COMMIT, and the client goes back in a `finally`. The pool is
// max: 3 behind a shared Supavisor pooler, which is exactly why this is the only place that does
// it: edits are rare and unmetered, while creates and ratings — the frequent writes — keep their
// single statement. Nothing else goes inside the transaction, and in particular there is NO
// pre-flight SELECT in it: everything the route needs to decide is in the UPDATE's own WHERE.
//
// --- Why the ownership test is a predicate and not a read -------------------------------------
//
// `author_id = $caller` sits in the UPDATE, so a non-author's statement matches no row. The
// answer is 404, NOT 403, and the difference matters: 403 confirms both that this uuid names a
// claim and that somebody else wrote it. 404 says neither, and stays byte-identical to the answer
// for an id that names nothing at all.
//
// That also settles a case with no special code in it. Every root claim has author_id IS NULL —
// a root is the community's question, seeded by trg_communities_seed_root_claim, not anyone's
// contribution — and `NULL = $caller` is NULL, therefore not true, for every caller. A root is
// uneditable through this route by the same predicate that keeps strangers out. Do not "fix" the
// NULL comparison.
//
// --- What an edit must not disturb ------------------------------------------------------------
//
// The SET list is two columns, and the rest of the row is other people's arithmetic:
//
//   * rating_count and rating_sum belong to connect.bump_claim_rating_aggregate, and `impact` is
//     GENERATED ALWAYS from them (CA_0345). 🔴 RATINGS CAST AGAINST THE OLD WORDING CARRY OVER TO
//     THE NEW ONE VERBATIM. That is deliberate — the brief allows editing a claim that already
//     has ratings and children — but it is a real consequence: an author can rewrite a claim out
//     from under twenty ratings. Resetting the aggregate instead would make the first rating
//     freeze a typo forever, which is worse, and is why this is left as it is rather than solved
//     here.
//   * path, depth and community_id belong to trg_claims_derive_position, which is BEFORE INSERT
//     OR UPDATE OF parent_claim_id — a body edit does not fire it, and must not start to.
//     CA_0344's claims_depth_within_cap is therefore untouched.
//   * child_supports_count and child_opposes_count belong to the count triggers.
//
// --- A no-op edit succeeds, and manufactures nothing -------------------------------------------
//
// trg_log_claim_edit is AFTER UPDATE … WHEN (OLD.body IS DISTINCT FROM NEW.body OR …), so
// resending the identical body writes no history row. The route agrees with the trigger rather
// than 422ing: a client retrying a request it is not sure landed gets 200 and the claim, and
// cannot manufacture history by doing it twice.
//
// The CASE on updated_at is the other half of that agreement, and it is ours rather than the
// trigger's. connect.claims has no touch trigger — "updated_at is set by the routes", CA_0341 —
// so an unconditional `updated_at = now()` would move the one timestamp a reader uses to tell an
// edited claim from an untouched one, with no history row behind it. In SET, the unqualified
// `body` on the right-hand side is the OLD value, which is what makes the comparison work.

/** The UPDATE's RETURNING: the serializer's columns, plus this caller's own rating. */
interface EditedClaimRow extends InsertedClaimRow {
  /** INTEGER or NULL — the author's own 1-9 rating of the claim they just edited. */
  my_rating: number | null;
}

/** What the classifying lookup reads when the UPDATE matched nothing. */
interface EditedClaimState {
  merged_into_claim_id: string | null;
}

claimWritesRouter.patch(
  '/claims/:claimId',
  ...requireAuth,
  requireConnected,
  async (req: Request, res: Response) => {
    const user = (req as FcRequest).user!;

    const raw = req.params.claimId as string;
    if (!UUID_RE.test(raw)) {
      notFound(res); // names no claim: no client checked out, no query run
      return;
    }
    const claimId = raw.toLowerCase();

    // 🔴 THE CREATE ROUTE'S BOUNDS, NOT A SECOND PAIR. An edit that could produce a body POST
    // /claims/:parentId/children would have refused is a hole, not a feature — so the constants
    // and the sentence the caller gets are both the same ones.
    const { body } = req.body as { body?: unknown };
    const trimmedBody = (typeof body === 'string' ? body : '').trim();
    if (trimmedBody.length < BODY_MIN || trimmedBody.length > BODY_MAX) {
      badRequest(res, 'INVALID_BODY', `body must be ${BODY_MIN}-${BODY_MAX} characters`);
      return;
    }

    // 🔴 NO RATE LIMITER, matching PATCH /posts/:id. An edit creates no row a maven has to
    // moderate and adds nothing to the tree — it replaces text that already cost the author one
    // of their five an hour. Metering it would leave a contributor stuck with a typo, and the
    // existence-oracle argument that puts the limiter in front of the lookups on the other two
    // routes does not apply: this one answers 404 for every claim the caller did not write, so
    // it teaches nothing about which uuids are real.

    let client: PoolClient;
    try {
      client = await pool.connect();
    } catch (err) {
      internalError(res, `claim edit connect ${claimId}`, err, EDIT_FAILED);
      return;
    }

    // The failure is CARRIED out of the block rather than answered inside it, so the client is
    // back in the pool before anything is serialized — on the thrown path as well as the happy
    // one. A max: 3 pool cannot afford a connection held for the length of a response.
    let row: EditedClaimRow | null = null;
    let failure: unknown = null;
    try {
      await client.query('BEGIN');
      // is_local = true: the setting dies with this transaction and cannot reach the next
      // request that checks out this connection.
      await client.query("SELECT set_config('fc.actor_id', $1, true)", [user.id]);
      const { rows } = await client.query<EditedClaimRow>(
        `UPDATE connect.claims
            SET body = $2::text,
                updated_at = CASE WHEN body IS DISTINCT FROM $2::text THEN now() ELSE updated_at END
          WHERE id = $1
            AND author_id = $3::uuid
            AND moderation_status = 'visible'
            AND merged_into_claim_id IS NULL
         RETURNING ${RETURNING_COLUMNS},
                   (SELECT r.value FROM connect.claim_ratings r
                     WHERE r.claim_id = $1 AND r.user_id = $3::uuid) AS my_rating`,
        [claimId, trimmedBody, user.id]
      );
      row = rows[0] ?? null;
      // COMMIT on both paths: a zero-row UPDATE wrote nothing, and ending the transaction the
      // same way either way leaves this block one exit.
      await client.query('COMMIT');
    } catch (err) {
      failure = err;
      await client.query('ROLLBACK').catch(() => {});
    } finally {
      client.release();
    }

    if (failure) {
      internalError(res, `claim edit ${claimId}`, failure, EDIT_FAILED);
      return;
    }

    // Zero rows: the claim is absent, hidden, merged, or not this caller's — or was one of those
    // by the time the UPDATE took the row lock and READ COMMITTED re-evaluated its quals against
    // the new version. Only one of those has anywhere to send the author, so the classifying
    // lookup runs HERE, on the pool, and only a refusal pays for it.
    if (!row) {
      let claim: EditedClaimState | null;
      try {
        // 🔴 SCOPED TO THE CALLER'S OWN VISIBLE CLAIMS. This query exists to produce a 409, and a
        // 409 names a merge target; asked without `author_id = $2`, it would hand that target to
        // anybody who guessed the id, and would turn the 404 back into an existence oracle.
        const { rows } = await pool.query<EditedClaimState>(
          `SELECT c.merged_into_claim_id
             FROM connect.claims c
            WHERE c.id = $1 AND c.author_id = $2::uuid AND c.moderation_status = 'visible'`,
          [claimId, user.id]
        );
        claim = rows[0] ?? null;
      } catch (err) {
        // A database that cannot answer is not a missing claim. 404 here would tell an author
        // their own claim is gone, which is a different and much worse thing to be wrong about.
        internalError(res, `claim edit lookup ${claimId}`, err, EDIT_FAILED);
        return;
      }

      // Superseded, not withdrawn: readers follow the merge to the target, so a rewrite of this
      // copy is text nobody will meet. Same answer, and the same reasoning, as a merged parent on
      // POST /children. Everything else — absent, hidden, somebody else's — is the one 404.
      if (claim && claim.merged_into_claim_id !== null) {
        claimMerged(res, claim.merged_into_claim_id);
        return;
      }
      notFound(res);
      return;
    }

    // An edit changes the claim's node body, its entry in its parent's column and the community's
    // shape payload. All three are dropped by middleware/claimInvalidation.ts, mounted above this
    // router — see the note on the create handler. The author sees their own new text immediately
    // whatever the cache holds: their reads carry credentials and are never cached.
    //
    // 🔴 One thing stays inside the 30-second bound on purpose: a descendant's breadcrumb carries
    // this claim's body, and the invalidation walks one level up rather than the whole subtree.

    // myRating is READ BACK rather than stated null. It is the one per-caller field in a Claim,
    // and an author may well have rated their own claim before fixing a typo in it; a response
    // that said otherwise would wipe that rating out of a client that replaces its local copy.
    res.json({ data: toClaim(row, row.my_rating ?? null) });
  }
);

// DELETE /claims/:claimId — never.
//
// Memory over Moderation, as for threads and posts, and here it is more than a convention:
// CA_0341 revokes DELETE and TRUNCATE on connect.claims from every role this process could be,
// precisely so "a claim is withdrawn, not removed" cannot be undone by a future route. A claim is
// hidden by a maven (Task 7) and its tombstone stays where readers can see it.
//
// 405 and not 404: the resource is there, and the Allow header names the methods that do work, so
// a client learns what to send instead. No auth in front of it — whether a claim can be deleted
// is a fact about the resource, not about the caller, and 401ing first would make it look like an
// authenticated caller might get a different answer.
claimWritesRouter.delete('/claims/:claimId', (_req: Request, res: Response) => {
  res.setHeader('Allow', 'GET, PATCH');
  res.status(405).json({
    error: { code: 'DELETE_NOT_ALLOWED', message: 'Claims cannot be deleted' },
  });
});

// --- The edit history ------------------------------------------------------
//
// GET /claims/:claimId/edits — what this claim used to say, to anyone.
//
// Unauthenticated, like GET /posts/:id/edits: the point of keeping the history is that a reader
// can see a claim was rewritten after people argued with it, and a history only its author can
// read would not do that.
//
// 🔴 THREE THINGS ARE WITHHELD, AND EACH IS A SEPARATE DECISION.
//
//   1. THE ACTOR. connect.claim_edits.actor_id is a raw account uuid and NOT NULL. Serving it
//      from an anonymous endpoint would publish a stable identifier for every editor, and this
//      project treats account data as off-limits by default. The column is not even SELECTed:
//      `by_author` is computed in SQL, so no account uuid reaches this process. There is no
//      display name on claim_edits to serve instead, and inventing one is not an option — naming
//      editors is a later, deliberate transparency decision, and additive when it is made.
//
//   2. THE CURATION ROWS. log_claim_edit writes five kinds; four of them — move, merge, unmerge,
//      hide — are Task 7's Maven actions, and this serves only the rewrite kind. A withdrawal row
//      carries old_body, so serving it would hand back the exact text the tombstone exists to
//      withhold, past a guard that was reviewed and built on purpose. And publishing who moved or
//      merged what, and when, is a moderation record nobody has decided to make public.
//
//   3. A HIDDEN CLAIM'S HISTORY, ENTIRELY. A withdrawn claim answers with an empty history, the
//      same shape as a claim nobody has edited. This matches its node: GET /claims/:id serves a
//      hidden claim as a 200 tombstone rather than 404, because it is already visible as one in
//      its parent's column — so this discloses nothing that read does not, and the body, which is
//      what hiding withholds, is withheld here too. An id that names nothing still 404s.
//
// --- There is no new_body, and that is not an omission to patch around -------------------------
//
// One claim_edits row records the text BEFORE one edit. So the text AFTER an entry is the
// oldBody of the entry above it in this list, and for the newest entry it is the claim's CURRENT
// body, which the caller already has from the claim itself. Newest-first is what makes that
// reading work, and it is the order GET /posts/:id/edits already serves. Do not synthesize an
// `after` field here: it would duplicate the next row for all but one entry and guess for that
// one, on an endpoint whose whole value is that nothing in it is guessed.

/** One history row, as the query hands it back. Note what is absent: the actor, and the kind. */
interface ClaimEditRow {
  id: string;
  old_body: string | null;
  by_author: boolean;
  edited_at: string;
}

claimWritesRouter.get('/claims/:claimId/edits', async (req: Request, res: Response) => {
  const raw = req.params.claimId as string;
  if (!UUID_RE.test(raw)) {
    notFound(res); // names no claim: no query run
    return;
  }
  const claimId = raw.toLowerCase();

  // The claim first, for the two answers the history query cannot give: 404 for an id that names
  // nothing, and an empty history for one that has been withdrawn.
  let claim: { moderation_status: string } | null;
  try {
    const { rows } = await pool.query<{ moderation_status: string }>(
      `SELECT c.moderation_status FROM connect.claims c WHERE c.id = $1`,
      [claimId]
    );
    claim = rows[0] ?? null;
  } catch (err) {
    internalError(res, `claim edits visibility ${claimId}`, err, EDITS_FETCH_FAILED);
    return;
  }

  if (!claim) {
    notFound(res);
    return;
  }
  if (claim.moderation_status !== 'visible') {
    // The tombstone, in this endpoint's shape. The history query does not run, so a hidden
    // claim's old bodies are never even read out of the table.
    res.json({ data: [] });
    return;
  }

  let history: ClaimEditRow[];
  try {
    ({ rows: history } = await pool.query<ClaimEditRow>(
      `SELECT e.id,
              e.old_body,
              (e.actor_id IS NOT DISTINCT FROM c.author_id) AS by_author,
              ${ts('e.edited_at')}
         FROM connect.claim_edits e
         JOIN connect.claims c ON c.id = e.claim_id
        WHERE e.claim_id = $1 AND e.kind = 'edit'
        ORDER BY e.edited_at DESC`,
      [claimId]
    ));
  } catch (err) {
    // 🔴 A FIXED STRING, unlike GET /posts/:id/edits, which echoes err.message. This endpoint is
    // anonymous, and a raw Postgres message names tables, columns and types — the difference
    // between a dull 500 and a schema probe.
    internalError(res, `claim edits ${claimId}`, err, EDITS_FETCH_FAILED);
    return;
  }

  res.json({
    data: history.map((e) => ({
      id: e.id,
      oldBody: e.old_body,
      // True when this edit was the claim's own author. IS NOT DISTINCT FROM, so a root claim's
      // NULL author_id reads false rather than null: a maven editing a root is not its author.
      byAuthor: e.by_author,
      editedAt: e.edited_at,
    })),
  });
});
