// Writing to the argument tree.
//
// routes/claims.ts reads the tree; this is the first thing that adds to it:
//
//   POST /claims/:parentId/children — attach a `supports` or `opposes` claim to a parent
//
// The path is bare because app.ts mounts this router under the Focused Communities mount points
// (/fc/api and /api/fc), exactly as for its siblings. Mounting is Task 8's.
//
// Four things in here are deliberate and worth reading before changing them:
//
//   1. 🔴 THE INSERT SUPPLIES FOUR COLUMNS. parent_claim_id, side, body, author_id — and nothing
//      else. path, depth and community_id are facts about the parent, derived by the database
//      (see "Position is not ours to set" below).
//   2. A hidden parent is a 404, not a 403, and is byte-identical to an absent one.
//   3. Validation runs before the rate limiter, so a malformed request never costs quota.
//   4. The response is the same Claim shape routes/claims.ts serializes, internals and all
//      withheld. The `Claim` type is imported rather than redeclared so the two cannot drift
//      without the compiler saying so.

import { Router } from 'express';
import type { Request, Response } from 'express';
import { pool } from '../config/database.js';
import { ts } from '../lib/sql.js';
import { requireAuth, type FcRequest } from '../middleware/auth.js';
import { requireConnected } from '../middleware/tierGuards.js';
import { postRateLimiter } from '../lib/rateLimit.js';
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
 *             rather than claims; agreement belongs in the Task 5 rating control, not in a child.
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

function badRequest(res: Response, code: string, message: string): void {
  res.status(400).json({ error: { code, message } });
}

/**
 * A query failed. The real message goes to the logs; the caller gets a fixed string.
 *
 * Same discipline as routes/claims.ts and deliberately unlike routes/threads.ts, which echoes
 * `err.message` back: a raw Postgres message names columns, constraints, types and sometimes
 * values, which turns a failed write into a schema probe.
 */
function internalError(res: Response, context: string, err: unknown): void {
  console.error(`[focused_communities] ${context}:`, (err as Error).message);
  res.status(500).json({
    error: { code: 'CLAIM_CREATE_FAILED', message: 'Could not create the claim' },
  });
}

// --- Serialization ---------------------------------------------------------

/** What RETURNING hands back — exactly the columns toClaim needs, and no others. */
interface InsertedClaimRow {
  id: string;
  side: ClaimSide | null;
  body: string;
  author_display_name: string | null;
  moderation_status: string;
  child_supports_count: number;
  child_opposes_count: number;
  merged_into_claim_id: string | null;
  created_at: string;
  updated_at: string;
}

const RETURNING_COLUMNS = `id, side, body, author_display_name, moderation_status,
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
 */
function toClaim(row: InsertedClaimRow): Claim {
  const isHidden = row.moderation_status !== 'visible';
  return {
    id: row.id,
    side: row.side,
    body: isHidden ? '' : row.body,
    authorPseudonym: isHidden ? null : (row.author_display_name ?? null),
    impact: null, // Task 5
    ratingCount: 0, // Task 5
    childSupports: row.child_supports_count,
    childOpposes: row.child_opposes_count,
    isHidden,
    mergedInto: row.merged_into_claim_id ?? null,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    myRating: null, // Task 5 — a claim nobody has rated, least of all its author
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
// Order is: canonicalise the id, validate the body, confirm the parent is there and visible,
// spend quota, write. Validation precedes the limiter (as in threads.ts and posts.ts) so a client
// bug cannot burn a writer's hourly allowance, and the parent check precedes it too so attaching
// to a claim that was withdrawn a second ago costs nothing either.
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

    // The parent, read once up front. This is a QUOTA GUARD, not the guarantee: attaching to a
    // claim that is absent or was withdrawn an hour ago should cost a writer nothing out of five
    // an hour, and finding that out needs a cheap read before the limiter. The guarantee that a
    // concurrently hidden parent cannot gain a child is the predicate in the INSERT below, and it
    // holds whether or not this read ran. See "Visibility is checked INSIDE the write".
    let parent: { moderation_status: string } | null;
    try {
      const { rows } = await pool.query<{ moderation_status: string }>(
        'SELECT moderation_status FROM connect.claims WHERE id = $1',
        [parentId]
      );
      parent = rows[0] ?? null;
    } catch (err) {
      // A database that cannot answer is not a missing claim. 404 here would tell the writer
      // their parent is gone, which is a different and much worse thing to be wrong about.
      internalError(res, `claim parent lookup ${parentId}`, err);
      return;
    }

    if (!parent || parent.moderation_status !== 'visible') {
      notFound(res);
      return;
    }

    const { success, reset } = await postRateLimiter.limit(`${RATE_LIMIT_NAMESPACE}${user.id}`);
    if (!success) {
      // reset is in milliseconds; Retry-After is in seconds
      res.set('Retry-After', String(Math.ceil((reset - Date.now()) / 1000)));
      res.status(429).json({ reason: 'rate_limited' });
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
          WHERE p.id = $1 AND p.moderation_status = 'visible'
            FOR UPDATE OF p
         RETURNING ${RETURNING_COLUMNS}`,
        [parentId, side, trimmedBody, user.id]
      );
      row = rows[0] ?? null;
    } catch (err) {
      internalError(res, `claim create under ${parentId}`, err);
      return;
    }

    // Zero rows is the race being caught, not a failure: the parent was hidden (or moved, or
    // merged) between the read above and this statement, and the locked re-evaluation dropped it.
    // It gets the same 404 as a parent that was already hidden — the writer cannot tell which,
    // and should not be able to.
    if (!row) {
      notFound(res);
      return;
    }

    // Cache invalidation is Task 8's, together with mounting this router: the node and shape
    // entries routes/claims.ts writes are keyed by claim id and column cursors, and the keys to
    // drop are the parent's node entries and the community's shape entry. Until that lands, a new
    // claim is invisible for up to CLAIM_TTL_SECONDS (30s) in the minimap and in its parent's
    // column. Deliberately NOT papered over here with a partial invalidation that drops one key
    // and leaves the rest, which is harder to reason about than a uniform 30-second lag.

    res.status(201).json({ data: toClaim(row) });
  }
);
