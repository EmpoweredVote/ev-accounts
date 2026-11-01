// Maven curation of the argument tree.
//
//   POST /claims/:claimId/move   { newParentId, side }  — re-parent a claim and its whole subtree
//   POST /claims/:claimId/merge  { targetClaimId }      — supersede a claim by another
//   POST /claims/:claimId/hide                          — withdraw a claim's text
//
// The paths are bare because app.ts mounts this router under the Focused Communities mount
// points (/fc/api and /api/fc), exactly as for its siblings. Mounting is Task 8's.
//
// 🔴 THIS IS THE ONLY FILE IN THE MODULE THAT REWRITES ROWS OTHER THAN THE ONE BEING ACTED ON.
// Everything else here follows from that. Six things are deliberate and worth reading before
// changing a line:
//
//   1. 🔴 THE DESCENDANT SWEEP NAMES `path` AND `depth`, AND NOTHING ELSE — in particular NOT
//      parent_claim_id. See "The trigger fires on mention" below. This reads like a harmless
//      omission and is the single most dangerous line in the file to "tidy".
//   2. Every refusal happens BEFORE any write, inside the same transaction that holds the row
//      locks, so a 409 is a 409 and not a half-applied move.
//   3. A cycle is checked TWICE and in two different ways, because parentage and merge
//      redirects are two different graphs with two different (and only one enforced) rules.
//   4. 🔴 impact, rating_count, rating_sum, child_supports_count and child_opposes_count are
//      never written here. `impact` is GENERATED ALWAYS … STORED and an UPDATE naming it is an
//      error; the other four belong to connect.bump_claim_rating_aggregate and
//      connect.bump_claim_child_counts, which the writes below fire correctly by themselves.
//   5. path, depth and community_id for the CURATED claim are not written either — the
//      derivation trigger owns them. The sweep writes path and depth for its DESCENDANTS,
//      which that trigger deliberately does not cover (CA_0341 §4a says so in its own header).
//   6. Nothing is ever deleted. A merged claim keeps its id, its URL, its body and its history.
//
// --- The trigger fires on MENTION, not on change ----------------------------------------------
//
//   CREATE TRIGGER trg_claims_derive_position
//   BEFORE INSERT OR UPDATE OF parent_claim_id ON connect.claims
//   FOR EACH ROW EXECUTE FUNCTION connect.derive_claim_position()
//
// There is NO WHEN clause. Any UPDATE whose SET list merely NAMES parent_claim_id fires it, even
// when assigning the identical value, and derive_claim_position() then overwrites path, depth and
// community_id from the row's parent as that parent reads AT THAT INSTANT. A descendant's parent
// has not changed during a sweep, and letting the trigger recompute its position mid-sweep would
// derive it from rows that are themselves half-rewritten. So the sweep says nothing about
// parentage; it splices.
//
// By contrast trg_claims_bump_child_counts_move is AFTER UPDATE OF parent_claim_id, side WITH a
// WHEN (OLD.parent_claim_id IS DISTINCT FROM NEW.parent_claim_id OR OLD.side IS DISTINCT FROM
// NEW.side), so it is safe from the same trap: it debits the old parent and credits the new one
// when the claim itself moves, and stays silent otherwise.
//
// --- Order of operations for a move -----------------------------------------------------------
//
// The claim's own parent_claim_id (and side) go FIRST, so the derivation trigger gives it a
// correct path, depth and community_id. Only then is its subtree swept, using the values the
// claim has just landed on. A single `UPDATE … WHERE path @> ARRAY[:claimId]` does the whole
// subtree in one statement, but it has to run AFTER the claim itself and it has to SPLICE:
//
//   new descendant path  = <claim's new path> || <claim> || <the part of its old path below the claim>
//   new descendant depth = old depth + (claim's new depth − claim's old depth)
//
// Postgres array slices are 1-indexed and the first `oldDepth + 1` elements of a descendant's
// path are the claim's old ancestors followed by the claim itself, so the tail starts at
// `oldDepth + 2`. Array concatenation renormalizes the lower bound to 1, so the result is a
// well-formed path and cardinality(path) = depth — which claims_root_or_child_shape checks on
// every row the sweep touches, and which is therefore the database's own audit of this
// arithmetic rather than something this file merely asserts.
//
// --- Why a transaction, and why a locking read inside it ---------------------------------------
//
// connect.log_claim_edit reads current_setting('fc.actor_id', true) and RAISES when it is unset:
// claim_edits.actor_id is NOT NULL, and an unattributed curation is exactly the thing the audit
// trail exists to prevent. set_config(…, true) is transaction-local, so the setting and the
// writes must share one transaction — the shape routes/claimWrites.ts's PATCH settled, and the
// reason this file holds a pool client at all (the pool is max: 3 behind a shared Supavisor
// pooler, so this is reserved for the rare write).
//
// Given a transaction, the pre-flight read goes INSIDE it with FOR UPDATE rather than on the
// pool. A move is several statements that must agree about the same two rows; read outside, the
// claim could be moved, hidden or merged by another maven between the decision and the writes,
// and the result would be a half-correct sweep nothing anywhere would notice. The two rows are
// locked in id order so two mavens curating the same corner of a tree queue rather than deadlock.
//
// 🔴 TWO LOCKS THIS DELIBERATELY DOES NOT TAKE. (a) The OLD parent, which the count trigger
// updates afterwards — including it would need a second round trip to learn its id, and the
// failure mode without it is a detected deadlock (a retryable 500), not a corrupt tree.
// (b) The descendants. The depth-cap check below reads the deepest one without holding it, so a
// child inserted deep in the subtree between the check and the commit can still push the tree
// past the cap; CA_0344's CHECK constraint is the backstop that makes that a loud failure rather
// than a silent one. Locking a whole subtree would serialize every write in the community behind
// every curation.

import { Router } from 'express';
import type { Request, Response, NextFunction } from 'express';
import type { PoolClient } from 'pg';
import { pool } from '../config/database.js';
import { ts } from '../lib/sql.js';
import { requireAuth } from '../middleware/auth.js';
import { markClaimsTouched } from '../middleware/claimsTouched.js';
import { MAX_CLAIM_DEPTH } from '../lib/utils.js';
import { requireAdmin } from '../../middleware/requireAdmin.js';
import { checkRole, getCachedUserRoles } from '../../lib/roleService.js';
import type { AuthenticatedRequest } from '../../middleware/auth.js';
import type { Claim, ClaimSide } from './claims.js';

export const claimCurationRouter = Router();

// --- Request shape ---------------------------------------------------------

/** The two sides, as the only two strings that count. Same rule, and reasoning, as the writes. */
const SIDES: readonly string[] = ['supports', 'opposes'];

/**
 * A uuid in the one spelling Postgres gives back. Checked BEFORE the id reaches a query, and
 * before a client is checked out of the pool: a non-uuid cannot name a claim, so it owes a 404
 * rather than an anonymous 500 out of a 22P02 one layer down.
 */
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** The role slug that may curate. The same one routes/seasons.ts reads for draft visibility. */
const MAVEN_ROLE = 'maven';

// --- Responses -------------------------------------------------------------

/**
 * The three failures a curation request can end in, as the caller is told about them.
 *
 * Separate codes because "Could not move the claim" is a lie when a merge failed, and a client
 * that retries one and not another needs to tell them apart. Frozen so a handler cannot mutate
 * the shared literal on its way out.
 */
const MOVE_FAILED = Object.freeze({ code: 'CLAIM_MOVE_FAILED', message: 'Could not move the claim' });
const MERGE_FAILED = Object.freeze({ code: 'CLAIM_MERGE_FAILED', message: 'Could not merge the claim' });
const HIDE_FAILED = Object.freeze({ code: 'CLAIM_HIDE_FAILED', message: 'Could not hide the claim' });
const CURATION_FAILED = Object.freeze({
  code: 'CLAIM_CURATION_FAILED',
  message: 'Could not complete the curation',
});

/**
 * A query failed. The real message goes to the logs; the caller gets a fixed string — the same
 * discipline as routes/claims.ts and routes/claimWrites.ts. A raw Postgres message names columns,
 * constraints and sometimes values, which turns a failed write into a schema probe.
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

function badRequest(res: Response, code: string, message: string): void {
  res.status(400).json({ error: { code, message } });
}

/**
 * A refusal carried OUT of the transaction rather than answered inside it.
 *
 * Every check below runs with a pool client checked out and a transaction open, and the client
 * has to be back in the pool before anything is serialized — a max: 3 pool cannot afford a
 * connection held for the length of a response. So a check sets this, the block ROLLBACKs and
 * exits, the `finally` releases, and only then is the answer written.
 */
interface Refusal {
  status: number;
  code: string;
  message: string;
  /** The merge target, on the one refusal that has somewhere to send the caller. */
  mergedInto?: string;
}

const notFound: Refusal = { status: 404, code: 'CLAIM_NOT_FOUND', message: 'Claim not found' };

/**
 * A community's question is not a claim anyone curates.
 *
 * All 61 roots have parent_claim_id IS NULL, side IS NULL, depth 0 and author_id IS NULL: they
 * are seeded by trg_communities_seed_root_claim from the community's name, not written by a
 * contributor. Moving one violates claims_root_or_child_shape outright; hiding one would blank
 * the question the whole page is about; and merging one — in either direction — says that the
 * question is a point somebody made, which it is not.
 */
const rootNotCuratable: Refusal = {
  status: 409,
  code: 'ROOT_NOT_CURATABLE',
  message: "A community's question is not a claim anyone curates",
};

/**
 * 422, and a sentence with no number in it, matching routes/claimWrites.ts. "50" is not something
 * the reader can act on and the cap may move; what they can act on is "pick a shallower parent".
 * CA_0344's CHECK stays as the backstop — this only makes the common case legible instead of a
 * constraint violation surfacing as an anonymous 500.
 */
const maxDepthReached: Refusal = {
  status: 422,
  code: 'MAX_DEPTH_REACHED',
  message: 'This discussion has reached its maximum depth',
};

function answer(res: Response, refusal: Refusal): void {
  const body: { code: string; message: string; mergedInto?: string } = {
    code: refusal.code,
    message: refusal.message,
  };
  if (refusal.mergedInto !== undefined) body.mergedInto = refusal.mergedInto;
  res.status(refusal.status).json({ error: body });
}

// --- Who may curate --------------------------------------------------------
//
// 🔴 MAVEN **OR** ADMIN CANNOT BE WRITTEN AS A CHAIN OF THE TWO SHARED MIDDLEWARES. Express
// middleware composes with AND: requireRole('maven') 403s an admin who is not a maven, and
// requireAdmin 403s a maven who is not an admin, so `requireRole('maven'), requireAdmin` means
// "both" in either order. Hence one local guard. Neither shared middleware is given OR
// semantics, and neither is wrapped or re-implemented here. (requireAdmin was later given a
// 503 branch so that "could not ask" is distinguishable from "not an admin" — see holdsAdmin.
// That is a change to what it REPORTS, not to who it admits, and every caller that branches on
// `res.headersSent` is unaffected.)
//
// The maven half is the same call routes/seasons.ts already makes — getCachedUserRoles plus the
// pure checkRole — so there is one answer in this module to "is this person a maven?".
//
// The admin half CALLS requireAdmin rather than repeating its query, and that is a constraint
// rather than a preference: requireAdmin reads public.admin_users through supabaseAdmin, and
// tests/integration/architecture.test.ts scans all of backend/src for that identifier and fails
// on any file not on its ALLOWED list. Repeating the lookup here would mean either turning that
// suite red or quietly widening the list for a route file. Calling the middleware does neither.
//
// 🔴 THERE IS NO requireConnected IN FRONT OF THESE ROUTES, AND THAT IS NOT AN OVERSIGHT.
// Curation is authorised by ROLE, not by tier: an admin who never upgraded past Inform must
// still be able to withdraw a claim, and a role is a stronger statement about a person than a
// tier is. The engine's requireAuth, which fc's requireAuth wraps, still enforces revocation,
// deletion and suspension.

/**
 * requireAdmin's answer, as a question.
 *
 * The middleware reports by WRITING to the response; here its verdict is one half of a decision,
 * so it gets a sink — a Response-shaped object that sends nothing — and the verdict is read off
 * whether `next` was called. A throw propagates: a Supabase that cannot answer is a 500, not a
 * 403 (see the guard).
 *
 * 🔴 AND A THROW IS NOT THE ONLY WAY THE LOOKUP CAN FAIL TO ANSWER. postgrest-js resolves on a
 * transport error rather than throwing it, so an unreachable Supabase reaches requireAdmin as a
 * populated `error` and not as an exception. That used to arrive here as a plain `false` —
 * indistinguishable from "this person is not an admin" — and the guard then told an admin in
 * the middle of an outage that curating is a maven action. Fail-closed, but it is the exact
 * misdiagnosis the paragraph below was written to prevent, and it was the one place in this
 * module where the documented fail-safe was not implemented.
 *
 * So the sink RECORDS THE STATUS. requireAdmin now writes 403 for "not an admin" and 503 for
 * "could not ask" (see src/middleware/requireAdmin.ts), and anything that is neither `next()`
 * nor a 403 is treated as an unanswered question and thrown — which requireMavenOrAdmin's catch
 * turns into a 500, the same answer a Redis outage on the maven half already gets. A status the
 * sink never saw is also an unanswered question: a middleware that returned without calling
 * next and without writing has told us nothing.
 */
async function holdsAdmin(req: Request): Promise<boolean> {
  let allowed = false;
  let status: number | null = null;
  const sink = {
    status: (code: number) => {
      status = code;
      return sink;
    },
    json: () => sink,
  } as unknown as Response;
  await requireAdmin(req, sink, (() => {
    allowed = true;
  }) as NextFunction);
  if (allowed) return true;
  if (status === 403) return false;
  throw new Error(`admin lookup did not answer (status ${status ?? 'none'})`);
}

async function requireMavenOrAdmin(req: Request, res: Response, next: NextFunction): Promise<void> {
  const userId = (req as AuthenticatedRequest).userId;

  let allowed: boolean;
  try {
    // 🔴 SHORT-CIRCUIT, AND THE ORDER IS A COST DECISION. The role grants are cached in Redis;
    // the admin_users lookup is a round trip to Supabase. A maven never pays for the second.
    allowed = checkRole(await getCachedUserRoles(userId), MAVEN_ROLE) || (await holdsAdmin(req));
  } catch (err) {
    // 🔴 A LOOKUP THAT FAILED IS NOT A CALLER WITHOUT THE ROLE. 403 here would tell a maven
    // they are not one — sending them to ask for a role they already hold — and would make a
    // Redis or Supabase outage look like a permissions change.
    internalError(res, `curation authorisation for ${userId}`, err, CURATION_FAILED);
    return;
  }

  if (!allowed) {
    // 403 and not 404. The 404-not-403 convention elsewhere in the module is about not
    // disclosing which claims exist or who wrote them; this answer is about the CALLER, is the
    // same for every id, and so teaches nothing about the tree. Telling a contributor plainly
    // that curation is a maven action is better than pretending the endpoint is missing.
    res.status(403).json({
      error: { code: 'MAVEN_REQUIRED', message: 'Curating the argument tree is a maven action' },
    });
    return;
  }

  // next() is called OUTSIDE the try: the handler it runs is async, and a synchronous throw on
  // its way to the first await would otherwise be caught here and answered as an authorisation
  // failure on a response that may already have started.
  next();
}

const curator = [...requireAuth, requireMavenOrAdmin];

// --- Serialization ---------------------------------------------------------

/**
 * What RETURNING hands back. The first block is exactly what toClaim needs; the last three are
 * internal and never serialized.
 */
interface CuratedClaimRow {
  id: string;
  side: ClaimSide | null;
  body: string;
  author_display_name: string | null;
  moderation_status: string;
  /** NUMERIC, so node-postgres hands it over as a string. Read back, never computed here. */
  impact: string;
  rating_count: number;
  child_supports_count: number;
  child_opposes_count: number;
  merged_into_claim_id: string | null;
  created_at: string;
  updated_at: string;
  /** The claim's position AFTER the trigger has derived it — what the sweep splices onto. */
  path: string[];
  depth: number;
  /** INTEGER or NULL — this curator's own 1-9 rating of the claim they just curated. */
  my_rating: number | null;
}

/**
 * The serializer's columns, plus the two the sweep needs and the caller's own rating.
 *
 * Written out again rather than imported from routes/claimWrites.ts, which does not export it;
 * the `Claim` RETURN TYPE is imported from routes/claims.ts, so a field added or renamed there
 * fails to compile here rather than silently serving two shapes under one name.
 */
const RETURNING_COLUMNS = `id, side, body, author_display_name, moderation_status,
            impact, rating_count,
            child_supports_count, child_opposes_count, merged_into_claim_id,
            ${ts('created_at')}, ${ts('updated_at')},
            path, depth`;

/**
 * The Claim shape, identical to routes/claims.ts's toClaim and routes/claimWrites.ts's.
 *
 * author_id, community_id, path, depth, moderation_status and the raw count column names never
 * appear in a response — isHidden is the only thing a reader learns about moderation. A hidden
 * claim comes back as the tombstone Task 2 serves: empty body, no pseudonym, counts intact, so
 * the structure survives and only the withdrawn text is withheld.
 *
 * `myRating` is READ BACK rather than stated null. It is the one per-caller field in a Claim, and
 * a maven may well have rated a claim before curating it; a response that said otherwise would
 * wipe that rating out of a client that replaces its local copy with this body.
 */
function toClaim(row: CuratedClaimRow): Claim {
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
    myRating: row.my_rating ?? null,
  };
}

/** The caller's own rating, as a correlated subselect on the RETURNING of each write. */
const MY_RATING = (claimParam: string, actorParam: string) =>
  `(SELECT r.value FROM connect.claim_ratings r
              WHERE r.claim_id = ${claimParam} AND r.user_id = ${actorParam}::uuid) AS my_rating`;

// --- The locking pre-read --------------------------------------------------

/** Everything a move or a merge decides on, for both rows, under one lock. */
interface CurationRow {
  id: string;
  parent_claim_id: string | null;
  community_id: string;
  depth: number;
  moderation_status: string;
  merged_into_claim_id: string | null;
  /** True when the CURATED claim appears in this row's path — i.e. this row is beneath it. */
  under_moving_claim: boolean;
  has_hidden_ancestor: boolean;
  /** The deepest row in the curated claim's subtree, or 0 when it has none. */
  deepest_descendant: number;
  /**
   * This row's GRANDparent, for cache invalidation only — never for a decision.
   *
   * On the curated claim it is the OLD grandparent, which nothing else in a move knows: once
   * the claim is re-parented, the row no longer names its old parent, let alone the level above
   * it. A grandparent's column shows each child's childSupports/childOpposes, so the old
   * parent's counts changing makes the old grandparent's page stale exactly as the new
   * grandparent's is (middleware/claimInvalidation.ts states the one-level-up rule).
   */
  parent_parent_claim_id: string | null;
}

/**
 * Read and lock the curated claim and its destination in one statement.
 *
 * ORDER BY c.id with FOR UPDATE so two concurrent curations of the same pair take the two row
 * locks in the same order. FOR UPDATE OF c names only the outer table: the EXISTS and the
 * deepest-descendant aggregate are plain subqueries and lock nothing.
 *
 * `deepest_descendant` is the same value on both rows — it is a fact about the curated claim, not
 * about the row it is attached to — and it rides along here rather than in a statement of its own
 * so the whole decision is taken from one snapshot.
 *
 * `parent_parent_claim_id` is read off `path` rather than through a second lookup on the parent.
 * A claim's path is its ancestors from the root down, EXCLUDING itself, so for a row at depth d
 * it holds d elements with the parent last — path[d] is the parent and path[d-1] is the
 * grandparent. (claims_root_or_child_shape audits cardinality(path) = depth on every swept row,
 * so that is a guaranteed shape, not an assumption.) Out-of-range subscripts are NULL in
 * Postgres, so a depth-1 claim and a root both yield NULL with no special case. It is used for
 * cache invalidation only and never for a decision, which is why it does not matter that the
 * subscript reads an unlocked column of the same locked row.
 */
const LOCK_PAIR = `
    SELECT c.id,
           c.parent_claim_id,
           c.community_id,
           c.depth,
           c.moderation_status,
           c.merged_into_claim_id,
           ($1::uuid = ANY (c.path)) AS under_moving_claim,
           EXISTS (SELECT 1 FROM connect.claims a
                    WHERE a.id = ANY (c.path) AND a.moderation_status <> 'visible')
             AS has_hidden_ancestor,
           (SELECT COALESCE(MAX(d.depth), 0) FROM connect.claims d
             WHERE d.path @> ARRAY[$1::uuid]) AS deepest_descendant,
           c.path[array_length(c.path, 1) - 1] AS parent_parent_claim_id
      FROM connect.claims c
     WHERE c.id = ANY (ARRAY[$1::uuid, $2::uuid])
     ORDER BY c.id
       FOR UPDATE OF c`;

/**
 * The descendant sweep, for a move and for a merge alike.
 *
 * 🔴 THE SET LIST IS `path` AND `depth`. NOT parent_claim_id — see the header. NOT community_id,
 * because a curation across communities is refused, so no descendant changes community. NOT
 * updated_at: trg_log_claim_edit does not fire for a path or depth change (its WHEN clause names
 * body, parent_claim_id, side, merged_into_claim_id and moderation_status), so moving updated_at
 * here would mark rows as changed with no history row behind it — the same bargain PATCH
 * /claims/:claimId strikes with the trigger, kept on the other side of the file.
 *
 *   $1  the curated claim
 *   $2  the prefix that replaces the claim's old ancestry: <new ancestors of the claim's
 *       children> — for a move, the claim's new path plus the claim; for a merge, the target's
 *       path plus the target
 *   $3  where the surviving tail of each descendant's path begins (1-indexed: oldDepth + 2)
 *   $4  how much every descendant's depth shifts
 *
 * RETURNING id, and read at both call sites. Each swept row's breadcrumb is derived from the
 * `path` this statement just rewrote, so each one has a cached node page that is now wrong, and
 * these ids are the only record of which rows they were — the curation response names none of
 * them. middleware/claimInvalidation.ts is the reader; markClaimsTouched is how it gets them.
 */
const SWEEP = `
    UPDATE connect.claims d
       SET path  = $2::uuid[] || d.path[($3::int):],
           depth = d.depth + $4::int
     WHERE d.path @> ARRAY[$1::uuid]
 RETURNING d.id`;

/** The slice bound and the shift, from the two depths they are derived from. */
function sliceFrom(oldDepth: number): number {
  return oldDepth + 2;
}

/**
 * Does the whole subtree still fit under the cap once it lands at `newDepth`?
 *
 * `deepest` is the deepest row beneath the claim, or 0 when there are none, so it is floored at
 * the claim's own depth before the shift is applied — otherwise a childless claim would be
 * measured as if it sat at the root.
 */
function fitsUnderCap(claimDepth: number, deepest: number, newDepth: number): boolean {
  return Math.max(deepest, claimDepth) + (newDepth - claimDepth) <= MAX_CLAIM_DEPTH;
}

// --- POST /claims/:claimId/move --------------------------------------------
//
// Re-parent a claim, and with it everything beneath it.
//
// The refusals, in the order they are taken — each one before any write:
//
//   itself            409  the one-hop cycle (claims_no_self_parent is the backstop)
//   absent            404  either id
//   a root            409  R53: the community's question is not anyone's contribution
//   already merged    409  the SUBJECT, not the parent. A merged claim has no children left to
//                          relocate and moving it only relocates the redirect.
//
// 🔴 A HIDDEN SUBJECT IS DELIBERATELY MOVABLE, AND THAT IS THE ONLY STATE OF THE CURATED CLAIM
// THIS ROUTE DOES NOT REFUSE. Hiding withdraws one claim's TEXT; it does not withdraw the
// subtree, which stays in the tree and stays readable under the tombstone (see the hide route's
// header). So a hidden claim is frequently exactly the row a maven needs to move — it is
// carrying live arguments that are in the wrong place. Refusing the move would strand them
// with no route to fix it, since nothing unhides. The destination's state is still checked:
// NEW_PARENT_NOT_VISIBLE keeps the subtree from landing somewhere unreachable.
//   its own descendant 409 the longer cycle (claims_not_own_ancestor is the backstop). A ring is
//                          unreachable from the root and every recursive walk over it hangs.
//   another community 409  derive_claim_position copies community_id from the parent, so this
//                          would silently relocate the claim AND its subtree into a different
//                          question. A maven who genuinely wants that has to ask for a feature.
//   hidden / unreachable / merged parent
//                     409  the same three states POST /claims/:parentId/children refuses, for
//                          the same reason, except that here it would be a whole subtree of text
//                          nobody will ever meet rather than one claim.
//   too deep          422  R54, with the constraint still behind it.

claimCurationRouter.post('/claims/:claimId/move', ...curator, async (req: Request, res: Response) => {
  const actorId = (req as AuthenticatedRequest).userId;

  const raw = req.params.claimId as string;
  if (!UUID_RE.test(raw)) {
    answer(res, notFound); // names no claim: no client checked out, no query run
    return;
  }
  const claimId = raw.toLowerCase();

  const { newParentId, side } = req.body as { newParentId?: unknown; side?: unknown };

  if (typeof newParentId !== 'string' || !UUID_RE.test(newParentId)) {
    badRequest(res, 'INVALID_NEW_PARENT', 'newParentId must be a claim id');
    return;
  }
  const parentId = newParentId.toLowerCase();

  if (typeof side !== 'string' || !SIDES.includes(side)) {
    badRequest(res, 'INVALID_SIDE', "side must be 'supports' or 'opposes'");
    return;
  }

  // The one-hop cycle, answered before a client is checked out. It also keeps the locking read
  // below unambiguous: ARRAY[$1, $2] with two equal ids returns one row, and "the claim" and
  // "the new parent" would be the same object.
  if (parentId === claimId) {
    answer(res, { status: 409, code: 'MOVE_WOULD_CYCLE', message: 'A claim cannot be moved under itself' });
    return;
  }

  let client: PoolClient;
  try {
    client = await pool.connect();
  } catch (err) {
    internalError(res, `claim move connect ${claimId}`, err, MOVE_FAILED);
    return;
  }

  let row: CuratedClaimRow | null = null;
  let refusal: Refusal | null = null;
  let failure: unknown = null;
  try {
    await client.query('BEGIN');
    // is_local = true: the setting dies with this transaction and cannot reach the next request
    // that checks out this connection and attribute that person's curation to this one.
    await client.query("SELECT set_config('fc.actor_id', $1, true)", [actorId]);

    const { rows: locked } = await client.query<CurationRow>(LOCK_PAIR, [claimId, parentId]);
    const claim = locked.find((r) => r.id === claimId) ?? null;
    const parent = locked.find((r) => r.id === parentId) ?? null;

    if (!claim) refusal = notFound;
    else if (claim.parent_claim_id === null) refusal = rootNotCuratable;
    else if (claim.merged_into_claim_id !== null) {
      // 🔴 THE SUBJECT'S OWN STATE, WHICH THIS ROUTE USED TO IGNORE ENTIRELY. See the header.
      // A merged claim is superseded: its children were re-parented onto the target when the
      // merge happened, so there is no subtree left to relocate and all a move would do is
      // relocate the redirect — putting the stub that says "this point is now made over there"
      // under a parent whose argument it is no longer part of. Same code and sentence as
      // /merge's refusal of an already-merged subject, because it is the same fact about the
      // same row, and the target rides along for the same reason.
      refusal = {
        status: 409,
        code: 'CLAIM_ALREADY_MERGED',
        message: 'This claim has already been merged into another',
        mergedInto: claim.merged_into_claim_id,
      };
    } else if (!parent) {
      // A maven is a trusted role: "which of the two ids was wrong?" is the first thing they
      // will ask and there is nothing here to withhold from them.
      refusal = { status: 404, code: 'NEW_PARENT_NOT_FOUND', message: 'New parent claim not found' };
    } else if (parent.under_moving_claim) {
      refusal = {
        status: 409,
        code: 'MOVE_WOULD_CYCLE',
        message: 'A claim cannot be moved beneath its own argument',
      };
    } else if (parent.community_id !== claim.community_id) {
      refusal = {
        status: 409,
        code: 'CROSS_COMMUNITY',
        message: 'A claim cannot be moved into another community',
      };
    } else if (parent.moderation_status !== 'visible' || parent.has_hidden_ancestor) {
      refusal = {
        status: 409,
        code: 'NEW_PARENT_NOT_VISIBLE',
        message: 'That part of the discussion has been removed',
      };
    } else if (parent.merged_into_claim_id !== null) {
      refusal = {
        status: 409,
        code: 'NEW_PARENT_MERGED',
        message: 'That claim has been merged into another',
        mergedInto: parent.merged_into_claim_id,
      };
    } else if (!fitsUnderCap(claim.depth, claim.deepest_descendant, parent.depth + 1)) {
      refusal = maxDepthReached;
    }

    if (!refusal) {
      const claimRow = locked.find((r) => r.id === claimId)!;

      // The claim itself. THREE columns: the trigger derives path, depth and community_id, and
      // the count triggers move the old and new parents' child counts. updated_at moves only
      // when something actually changed, because trg_log_claim_edit's WHEN clause means a
      // restated parent and side write no history row — and a timestamp that says "changed"
      // with nothing behind it is worse than one that says nothing. In SET, the unqualified
      // column names on the right-hand side are the OLD values, which is what makes that work.
      const { rows: moved } = await client.query<CuratedClaimRow>(
        `UPDATE connect.claims
            SET parent_claim_id = $2::uuid,
                side = $3::text,
                updated_at = CASE WHEN parent_claim_id IS DISTINCT FROM $2::uuid
                                    OR side IS DISTINCT FROM $3::text
                                  THEN now() ELSE updated_at END
          WHERE id = $1 AND parent_claim_id IS NOT NULL
         RETURNING ${RETURNING_COLUMNS},
                   ${MY_RATING('$1', '$4')}`,
        [claimId, parentId, side, actorId]
      );
      row = moved[0] ?? null;
      if (!row) {
        // The row was read and LOCKED a statement ago in this same transaction, and
        // connect.claims has no DELETE grant, so there is no ordinary way to be here. A 404
        // would be a guess about why; a 500 is the honest answer.
        throw new Error('the claim vanished between its locking read and its move');
      }

      // ...and then its subtree, spliced onto where the claim has just landed.
      //
      // 🔴 NOT WHEN THE PARENT DID NOT CHANGE. A move to the claim's current parent — a side
      // flip, or a client resending a request it was not sure landed — passes every refusal,
      // and the UPDATE above is already a no-op by design (the derivation is idempotent, the
      // count and log triggers' WHEN clauses do not fire, updated_at is guarded by its CASE).
      // The sweep is the one statement that was not: it would rewrite every descendant's path
      // and depth to the values they already hold, producing a dead tuple per row, churn on
      // claims_path_gin_idx, and up to MAX_NODE_KEYS cache deletes for rows nobody changed.
      //
      // The parent is the whole test. `side` does not appear in any descendant's path or
      // depth, and a parent that is unchanged means trg_claims_derive_position re-derived the
      // same path and the same depth for the claim, so every splice below it is the identity.
      // A move to a DIFFERENT parent at the same depth still changes paths, which is why this
      // compares ids and not depths. Both sides are canonical lowercase — `parentId` from the
      // request, `claimRow.parent_claim_id` out of Postgres.
      const reparented = claimRow.parent_claim_id !== parentId;
      const swept = reparented
        ? (
            await client.query<{ id: string }>(SWEEP, [
              claimId,
              [...row.path, claimId],
              sliceFrom(claimRow.depth),
              row.depth - claimRow.depth,
            ])
          ).rows
        : [];

      // What this write made stale beyond the claim itself, which the middleware works out on
      // its own: the OLD parent, which the row no longer names, and the old parent's OWN parent;
      // the new parent and ITS parent, whose columns and child counts both ends of the move just
      // changed; and every swept descendant, whose breadcrumb was rebuilt a statement ago.
      // Marking is not deleting — the middleware acts only if this transaction commits and the
      // response is a 2xx.
      //
      // 🔴 BOTH GRANDPARENTS, NOT ONLY THE NEW ONE. middleware/claimInvalidation.ts says the
      // invalidation "walks one level up" because a grandparent's column shows each child's
      // childSupports/childOpposes. A move changes those counts on the old parent exactly as it
      // does on the new one, so leaving the old grandparent out made the rule true on the
      // receiving side only — one stale count on one cached page, inside the documented 30s
      // bound, but by accident rather than by choice. claimRow.parent_parent_claim_id is the
      // old side's equivalent of parent.parent_claim_id; markClaimsTouched drops the nulls and
      // de-duplicates downstream, so a no-op move naming the same id twice costs nothing.
      markClaimsTouched(
        res,
        claimRow.parent_claim_id,
        claimRow.parent_parent_claim_id,
        parentId,
        parent?.parent_claim_id,
        ...swept.map((d) => d.id)
      );
    }

    // COMMIT on the refusal path too: nothing was written, and ending the transaction the same
    // way either way leaves this block one exit. ROLLBACK is used instead, because a refusal
    // that committed would still have taken and held row locks for no reason and reads oddly in
    // a log next to the write it declined to make.
    await client.query(refusal ? 'ROLLBACK' : 'COMMIT');
  } catch (err) {
    failure = err;
    await client.query('ROLLBACK').catch(() => {});
  } finally {
    client.release();
  }

  if (failure) {
    internalError(res, `claim move ${claimId}`, failure, MOVE_FAILED);
    return;
  }
  if (refusal) {
    answer(res, refusal);
    return;
  }

  // The cache entries this made stale are dropped by middleware/claimInvalidation.ts, which
  // wraps this res.json: the ids above reached it through markClaimsTouched. See the note at the
  // foot of this file for what a curation write makes stale, and what is only bounded.
  res.json({ data: toClaim(row!) });
});

// --- POST /claims/:claimId/merge -------------------------------------------
//
// One claim supersedes another. Readers of the merged claim are offered the target.
//
// 🔴 NOTHING IS DELETED AND NOTHING IS FOLDED. The merged claim keeps its id, its URL, its body
// and its history; GET /claims/:id serves it with `mergedInto` set so the client can offer the
// target. Task 3 ruled (R28) that the target may be ABSENT from that payload, so a client walks
// the chain a hop at a time — which is also why a target that is itself merged is allowed here.
//
// What moves and what does not:
//
//   CHILDREN MOVE. They are re-parented onto the target, keeping their side: a merge says the two
//   claims are the same point, so the arguments for and against it still are. Each re-parent is a
//   move and carries everything the move route does — the derivation trigger fires per child, the
//   count triggers debit the merged claim and credit the target, and what is below the children
//   needs the same splice.
//
//   A HIDDEN SUBJECT IS DELIBERATELY MERGEABLE. The subject's moderation_status is the one
//   state of the curated claim this route does not refuse, and it is the same decision /move
//   takes for the same reason: hiding withdraws a claim's text, not the live subtree beneath
//   it, so a hidden claim can still be the one whose children belong under the target. The
//   claim stays hidden afterwards — the merge writes merged_into_claim_id and nothing else —
//   and hidden-AND-merged is a state the module already anticipates (routes/claimWrites.ts's
//   rating refusal orders the two). The subject's merged_into_claim_id IS refused, below.
//
//   RATINGS DO NOT MOVE, AND THAT NEEDS NO CODE. connect.bump_claim_rating_aggregate keys on
//   claim_ratings.claim_id, which a merge does not touch, so the ratings stay on the merged claim
//   and the target's aggregate does not change. "Discards the merged claim's ratings" describes
//   the ABSENCE of a transfer, not an action — and writing rating_count or rating_sum to simulate
//   one would fight the trigger and trip claims_rating_totals_coherent, while writing `impact` is
//   an error outright: it is GENERATED ALWAYS … STORED.

/** What the bounded merge-chain walk answers. */
interface MergeChainRow {
  /** True when following merged_into_claim_id from the target reaches the claim being merged. */
  reaches_claim: boolean | null;
  /** How far the walk got. Hitting the ceiling means it could not prove the chain terminates. */
  hops: number | null;
}

/**
 * 🔴 THE SECOND CYCLE CHECK, AND IT IS NOT THE FIRST ONE IN DISGUISE.
 *
 * claims_not_own_ancestor (CHECK (NOT (path @> ARRAY[id]))) constrains PARENTAGE. Nothing in the
 * schema constrains merged_into_claim_id — no constraint, no trigger — so a merge chain (A→B→C)
 * and a merge CYCLE (A→B→A) are both possible today, and only the first is wanted. A cycle is not
 * reachable through the UI and is very hard to unpick by hand once it exists, because every read
 * that follows it hangs or recurses.
 *
 * The walk is BOUNDED, and the bound is itself a refusal: an unbounded walk over a cycle that is
 * already there is not a wrong answer, it is a hung request. MAX_CLAIM_DEPTH is a generous
 * ceiling for a chain of supersessions that should realistically be one or two hops.
 */
const MERGE_CHAIN = `
    WITH RECURSIVE chain(id, merged_into, hops) AS (
      SELECT c.id, c.merged_into_claim_id, 1
        FROM connect.claims c
       WHERE c.id = $2
      UNION ALL
      SELECT n.id, n.merged_into_claim_id, chain.hops + 1
        FROM chain
        JOIN connect.claims n ON n.id = chain.merged_into
       WHERE chain.hops < $3::int
    )
    SELECT bool_or(chain.id = $1) AS reaches_claim,
           max(chain.hops)        AS hops
      FROM chain`;

claimCurationRouter.post('/claims/:claimId/merge', ...curator, async (req: Request, res: Response) => {
  const actorId = (req as AuthenticatedRequest).userId;

  const raw = req.params.claimId as string;
  if (!UUID_RE.test(raw)) {
    answer(res, notFound);
    return;
  }
  const claimId = raw.toLowerCase();

  const { targetClaimId } = req.body as { targetClaimId?: unknown };
  if (typeof targetClaimId !== 'string' || !UUID_RE.test(targetClaimId)) {
    badRequest(res, 'INVALID_MERGE_TARGET', 'targetClaimId must be a claim id');
    return;
  }
  const targetId = targetClaimId.toLowerCase();

  if (targetId === claimId) {
    answer(res, { status: 409, code: 'MERGE_WOULD_CYCLE', message: 'A claim cannot be merged into itself' });
    return;
  }

  let client: PoolClient;
  try {
    client = await pool.connect();
  } catch (err) {
    internalError(res, `claim merge connect ${claimId}`, err, MERGE_FAILED);
    return;
  }

  let row: CuratedClaimRow | null = null;
  let refusal: Refusal | null = null;
  let failure: unknown = null;
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('fc.actor_id', $1, true)", [actorId]);

    const { rows: locked } = await client.query<CurationRow>(LOCK_PAIR, [claimId, targetId]);
    const claim = locked.find((r) => r.id === claimId) ?? null;
    const target = locked.find((r) => r.id === targetId) ?? null;

    if (!claim) refusal = notFound;
    else if (claim.parent_claim_id === null) refusal = rootNotCuratable;
    else if (claim.merged_into_claim_id !== null) {
      // Re-pointing an existing merge is not a merge. The children were re-parented onto the
      // first target when it happened, so a second one would move nothing and would strand
      // readers mid-chain. connect.claim_edits has an `unmerge` kind for undoing it first.
      refusal = {
        status: 409,
        code: 'CLAIM_ALREADY_MERGED',
        message: 'This claim has already been merged into another',
        mergedInto: claim.merged_into_claim_id,
      };
    } else if (!target) {
      refusal = { status: 404, code: 'MERGE_TARGET_NOT_FOUND', message: 'Merge target claim not found' };
    } else if (target.parent_claim_id === null) {
      refusal = rootNotCuratable;
    } else if (target.under_moving_claim) {
      refusal = {
        status: 409,
        code: 'MERGE_WOULD_CYCLE',
        message: 'A claim cannot be merged into its own argument',
      };
    } else if (target.community_id !== claim.community_id) {
      refusal = {
        status: 409,
        code: 'CROSS_COMMUNITY',
        message: 'A claim cannot be merged into another community',
      };
    } else if (target.moderation_status !== 'visible' || target.has_hidden_ancestor) {
      // The merge would redirect every reader of this claim to a tombstone, and would hang the
      // re-parented children under an ancestor nobody can read past.
      refusal = {
        status: 409,
        code: 'MERGE_TARGET_NOT_VISIBLE',
        message: 'That part of the discussion has been removed',
      };
    } else if (!fitsUnderCap(claim.depth, claim.deepest_descendant, target.depth)) {
      // The transplant shifts every descendant by (target.depth − claim.depth): a child of the
      // merged claim becomes a child of the target. Same arithmetic as a move, one level up.
      refusal = maxDepthReached;
    }

    if (!refusal) {
      const { rows: chain } = await client.query<MergeChainRow>(MERGE_CHAIN, [
        claimId,
        targetId,
        MAX_CLAIM_DEPTH,
      ]);
      const walk = chain[0];
      if (walk?.reaches_claim) {
        refusal = {
          status: 409,
          code: 'MERGE_WOULD_CYCLE',
          message: 'That merge would point this claim back at itself',
        };
      } else if ((walk?.hops ?? 0) >= MAX_CLAIM_DEPTH) {
        refusal = {
          status: 409,
          code: 'MERGE_CHAIN_TOO_LONG',
          message: 'That claim already sits at the end of a long chain of merges',
        };
      }
    }

    if (!refusal) {
      const claimRow = locked.find((r) => r.id === claimId)!;
      const targetRow = locked.find((r) => r.id === targetId)!;

      // The children, onto the target. `side` is untouched. updated_at moves unconditionally
      // because every matched row genuinely changed parent — the target is not the claim — so
      // trg_log_claim_edit writes a `move` row for each one and the timestamp has history
      // behind it.
      const { rows: children } = await client.query<{ id: string; path: string[]; depth: number }>(
        `UPDATE connect.claims
            SET parent_claim_id = $2::uuid,
                updated_at = now()
          WHERE parent_claim_id = $1
         RETURNING id, path, depth`,
        [claimId, targetId]
      );

      if (children.length > 0) {
        // 🔴 WHAT THIS SWEEPS, AND WHY IT IS NOT THE CHILDREN. The statement above fired
        // trg_claims_derive_position for each child, which gave it the target's path — so a
        // child's path no longer contains the merged claim, and `path @> ARRAY[claim]` passes
        // straight over it. What is still matched is everything BELOW those children, whose
        // paths do still run through the merged claim. Sweeping a child again would splice an
        // already-correct path a second time; the predicate excludes them for free, and this
        // comment is here because that looks like luck rather than design.
        const prefix = [...(children[0] as { path: string[] }).path];
        const { rows: swept } = await client.query<{ id: string }>(SWEEP, [
          claimId,
          prefix,
          sliceFrom(claimRow.depth),
          targetRow.depth - claimRow.depth,
        ]);
        markClaimsTouched(res, ...swept.map((d) => d.id));
      }

      // The target gained every one of those children, so its column and its child counts moved
      // and so did the page its own parent serves. The children themselves changed parent, which
      // is their breadcrumb. See the move route for why marking here is safe before the commit.
      markClaimsTouched(
        res,
        targetId,
        targetRow.parent_claim_id,
        ...children.map((c) => c.id)
      );

      // The redirect itself. TWO columns: merged_into_claim_id and the timestamp. Nothing is
      // deleted, the body stays, the ratings stay, and the child counts have already been
      // debited by the count trigger as each child moved.
      const { rows: merged } = await client.query<CuratedClaimRow>(
        `UPDATE connect.claims
            SET merged_into_claim_id = $2::uuid,
                updated_at = now()
          WHERE id = $1 AND parent_claim_id IS NOT NULL
         RETURNING ${RETURNING_COLUMNS},
                   ${MY_RATING('$1', '$3')}`,
        [claimId, targetId, actorId]
      );
      row = merged[0] ?? null;
      if (!row) {
        throw new Error('the claim vanished between its locking read and its merge');
      }
    }

    await client.query(refusal ? 'ROLLBACK' : 'COMMIT');
  } catch (err) {
    failure = err;
    await client.query('ROLLBACK').catch(() => {});
  } finally {
    client.release();
  }

  if (failure) {
    internalError(res, `claim merge ${claimId}`, failure, MERGE_FAILED);
    return;
  }
  if (refusal) {
    answer(res, refusal);
    return;
  }

  res.json({ data: toClaim(row!) });
});

// --- POST /claims/:claimId/hide --------------------------------------------
//
// Withdraw a claim's text. The claim stays, as the tombstone Task 2 serves: empty body, no
// pseudonym, counts intact.
//
// 🔴 HIDE DOES NOT TOUCH DESCENDANTS, AND THAT IS CONSISTENT WITH THE WRITE SIDE RATHER THAN IN
// TENSION WITH IT. The two halves look contradictory and both are right:
//
//   * An EXISTING child of a hidden claim stays in the tree and stays readable. The hidden claim
//     renders as a tombstone, so the structure survives and only the removed text is withheld —
//     404ing the subtree would punish everyone who argued underneath for one person's post.
//   * A NEW child may not be added beneath it (routes/claimWrites.ts refuses a hidden ancestor),
//     because a claim nobody can read is not something anyone can argue with.
//
// Do not "fix" this into symmetry in either direction.
//
// WHAT HIDE OWES THE WRITE SIDE. POST /claims/:parentId/children closes the hidden-ancestor hole
// at write time but leaves a narrow race, because its FOR UPDATE OF p locks the PARENT and not
// the ancestors. The FOR UPDATE below closes the common case — a child inserted directly under
// the claim being hidden blocks on this lock and, when it wakes, READ COMMITTED re-evaluates its
// `moderation_status = 'visible'` qual against the new row version and inserts nothing. The
// RESIDUAL window, left open deliberately, is a claim inserted under a DESCENDANT of this one in
// the instant before the hide commits. Closing that would mean locking the whole subtree, which
// would serialize every write in the community behind every hide, for a race that costs one
// unreachable claim a maven can hide in turn.
//
// IDEMPOTENT, AND IT MANUFACTURES NOTHING. trg_log_claim_edit is AFTER UPDATE … WHEN (…
// OR OLD.moderation_status IS DISTINCT FROM NEW.moderation_status), so hiding an already-hidden
// claim writes no history row. The route agrees with the trigger rather than 409ing: a client
// retrying a request it is not sure landed gets the tombstone back, and cannot manufacture a
// moderation record by sending it twice. The CASE on updated_at is the other half of that
// agreement — connect.claims has no touch trigger, so an unconditional now() would move the one
// timestamp a reader uses to tell a changed claim from an untouched one with nothing behind it.

/** What the locking read needs to answer, which is only "is it there, and is it a root?". */
interface HideTargetRow {
  id: string;
  parent_claim_id: string | null;
  moderation_status: string;
}

claimCurationRouter.post('/claims/:claimId/hide', ...curator, async (req: Request, res: Response) => {
  const actorId = (req as AuthenticatedRequest).userId;

  const raw = req.params.claimId as string;
  if (!UUID_RE.test(raw)) {
    answer(res, notFound);
    return;
  }
  const claimId = raw.toLowerCase();

  let client: PoolClient;
  try {
    client = await pool.connect();
  } catch (err) {
    internalError(res, `claim hide connect ${claimId}`, err, HIDE_FAILED);
    return;
  }

  let row: CuratedClaimRow | null = null;
  let refusal: Refusal | null = null;
  let failure: unknown = null;
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('fc.actor_id', $1, true)", [actorId]);

    const { rows: locked } = await client.query<HideTargetRow>(
      `SELECT c.id, c.parent_claim_id, c.moderation_status
         FROM connect.claims c
        WHERE c.id = $1
          FOR UPDATE OF c`,
      [claimId]
    );
    const claim = locked[0] ?? null;

    if (!claim) refusal = notFound;
    else if (claim.parent_claim_id === null) refusal = rootNotCuratable;

    if (!refusal) {
      const { rows: hidden } = await client.query<CuratedClaimRow>(
        `UPDATE connect.claims
            SET moderation_status = 'hidden',
                updated_at = CASE WHEN moderation_status IS DISTINCT FROM 'hidden'
                                  THEN now() ELSE updated_at END
          WHERE id = $1 AND parent_claim_id IS NOT NULL
         RETURNING ${RETURNING_COLUMNS},
                   ${MY_RATING('$1', '$2')}`,
        [claimId, actorId]
      );
      row = hidden[0] ?? null;
      if (!row) {
        throw new Error('the claim vanished between its locking read and its hide');
      }
    }

    await client.query(refusal ? 'ROLLBACK' : 'COMMIT');
  } catch (err) {
    failure = err;
    await client.query('ROLLBACK').catch(() => {});
  } finally {
    client.release();
  }

  if (failure) {
    internalError(res, `claim hide ${claimId}`, failure, HIDE_FAILED);
    return;
  }
  if (refusal) {
    answer(res, refusal);
    return;
  }

  res.json({ data: toClaim(row!) });
});

// --- What a curation write makes stale -------------------------------------
//
// This is the list, written here because this file is the one that knows which rows moved.
// middleware/claimInvalidation.ts acts on it; what it does with each line is noted below, and
// its own header says why the node pages are dropped only for the default cursor page.
//
//   fc:claims:shape:{communityId}            — every one of the three. The shape payload is the
//                                              whole tree's structure, which is exactly what a
//                                              move rearranges, a merge re-parents and a hide
//                                              turns into a tombstone.
//   fc:claim:id:{claimId}:{params}           — the curated claim's own node, for every cursor
//                                              combination, since `params` is part of the key.
//   fc:claim:id:{oldParentId}:{params}       — a move and a merge change a column's contents and
//   fc:claim:id:{newParentId|targetId}:{…}     its child counts at BOTH ends.
//   fc:claim:id:{id}:{params} for every claim whose `path` changed — i.e. the whole swept
//                                              subtree, because each of those nodes serves a
//                                              breadcrumb built from its path.
//   fc:claim:root:{communityId}:{params}     — when the claim or its new parent is a child of
//                                              the root, or when the subtree reaches it.
//
// The subtree list is not knowable from the response, so the sweep is where it is collected:
// SWEEP now carries `RETURNING d.id` and both call sites read it, at no extra round trip.
//
// HOW MUCH OF THAT ACTUALLY HAPPENS. The shape key is deleted exactly — it takes no parameters,
// so a community has one entry. The node keys are deleted for the DEFAULT cursor page only:
// `params` is part of the key, `limit` is a range and the cursors are opaque, so "every cursor
// combination" is not enumerable and the shared cache has no pattern delete. A deep cursor page
// therefore keeps the old arrangement for up to CLAIM_TTL_SECONDS (30s) — the same bound
// `s-maxage=30` already gives every anonymous reader, with a correct shape map beside it. That
// is a chosen bound, not an oversight, and middleware/claimInvalidation.ts spells out the
// alternative that was rejected and why.
