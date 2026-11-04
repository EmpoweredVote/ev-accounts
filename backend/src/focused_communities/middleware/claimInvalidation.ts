// Dropping what a claim write made stale.
//
// routes/claims.ts caches two things by hand: one `fc:claims:shape:{communityId}` entry per
// community, and one `fc:claim:{id|root}:{id}:{params}` entry per node page per cursor
// combination. Both are written with CLAIM_TTL_SECONDS (30s). This is the `del` side of that,
// and it is ONE middleware rather than a line in each of the six write handlers:
//
//   * it keys off "a non-GET under /claims/ that answered 2xx", so a write route added later is
//     covered by construction rather than by someone remembering;
//   * the routes it covers live in two files this task does not own, and a route file that has
//     to know about cache keys is a route file that eventually disagrees with the reader about
//     what they are.
//
// It is mounted ABOVE the three claim routers in app.ts and no-ops on everything else.
//
// --- What is exact, and what is only approximate -----------------------------------------------
//
// 🔴 THIS DOES NOT FULLY INVALIDATE THE NODE PAGES, AND IT MUST NOT CLAIM TO.
//
// EXACT: `fc:claims:shape:{communityId}`. The shape payload takes no parameters, so a community
// has exactly one entry and this deletes it on every write. The minimap is never stale.
//
// APPROXIMATE: the node pages. `claimCacheKey` varies on
// `JSON.stringify({ limit, supports, opposes })` — `limit` is a range and the two cursors are
// opaque base64 strings, so the live combinations cannot be enumerated, and the shared cache
// offers exact-key deletes only (src/lib/cache.ts: there is no pattern delete). The alternative,
// folding an epoch into the key and bumping it on write, buys precision for a Redis round trip
// on EVERY read of routes whose whole purpose is to be cheap. So what is deleted is the
// DEFAULT-parameter page — page one of both columns, which is the page every link into the tree
// lands on — for each claim this write changed, in the `id` namespace plus the community's
// `root` namespace entry.
//
// BOUNDED STALENESS OF 30 SECONDS, DELIBERATELY CHOSEN. A reader holding a deep cursor page can
// see a moved claim in its old position, or an edited body in a descendant's breadcrumb, for up
// to CLAIM_TTL_SECONDS. Nothing is wrong, only old — and it is the same staleness
// `public, max-age=0, s-maxage=30` already promises every anonymous reader through the CDN, with
// the shape map beside it already correct. Two more things sit inside that bound on purpose: a
// grandparent's column shows each child's `childSupports`/`childOpposes`, and a descendant's
// breadcrumb shows its ancestors' bodies, so the invalidation walks one level up and not the
// whole ancestry.
//
// --- Lower case, on this side too --------------------------------------------------------------
//
// Every read lowercases its id before the id reaches a key, because Postgres reads `{A0EEBC99-…}`,
// the hyphenless spelling and every mixed case as the same row. A delete that did not match would
// name a key nobody ever wrote while the live entry survived, which is worse than not deleting at
// all — it looks like it worked. Ids out of Postgres are already canonical; the one out of
// `req.path` is not, so it is treated as the untrusted one.

import type { Request, Response, NextFunction } from 'express';
import { pool } from '../config/database.js';
import { cacheDel } from './cache.js';
import { touchedClaims } from './claimsTouched.js';
import { claimCacheKey, shapeCacheKey } from '../routes/claims.js';

/** Same shape the claim routes accept, and the same refusal: a non-uuid names no claim. */
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** `/claims/<id>` and anything beneath it: children, rate, move, merge, hide, the claim itself. */
const CLAIM_WRITE_PATH = /^\/claims\/([^/]+)(?:\/|$)/;

/**
 * How many node entries one write may delete.
 *
 * A move sweeps a whole subtree and every row in it serves a path-derived breadcrumb, so the id
 * list is unbounded in principle. Each delete is a round trip, and this runs before the write's
 * response is sent (see below), so the burst is capped and the overflow is left to expire — which
 * is the regime the rest of this file already describes, applied to the rare very large move.
 */
const MAX_NODE_KEYS = 100;

function warn(message: string): void {
  console.warn(`[focused_communities] claim cache invalidation: ${message}`);
}

/** The claim named by the URL, canonical, or null when this is not a claim write. */
function subjectOf(path: string): string | null {
  const match = CLAIM_WRITE_PATH.exec(path);
  if (!match) return null;
  const raw = match[1] as string;
  return UUID_RE.test(raw) ? raw.toLowerCase() : null;
}

/**
 * Never rejects. A write that has already committed must not be reported as a failure because a
 * cache could not be reached — but it must leave a trace, so each way of coming up short warns
 * with the claim it was working on.
 */
async function invalidate(subject: string, res: Response): Promise<void> {
  const ids = new Set<string>([subject, ...touchedClaims(res)]);
  let communityId: string | null = null;

  // One PK read, after the write has committed. It answers both of the things the URL cannot:
  // which community's shape map to drop, and which parent's column this claim appears in.
  try {
    const { rows } = await pool.query<{ community_id: string; parent_claim_id: string | null }>(
      `SELECT c.community_id, c.parent_claim_id FROM connect.claims c WHERE c.id = $1`,
      [subject]
    );
    const row = rows[0];
    if (!row) {
      warn(`claim ${subject} could not be read back; its community's shape map will expire instead`);
    } else {
      communityId = row.community_id.toLowerCase();
      if (row.parent_claim_id) ids.add(row.parent_claim_id.toLowerCase());
    }
  } catch (err) {
    warn(`community lookup for claim ${subject} failed: ${(err as Error).message}`);
  }

  const keys: string[] = [];
  if (communityId !== null) {
    // The shape map, and the community's root node page. The root page is dropped on every write
    // in the community rather than only when the write reached depth 0 or 1: after the fact that
    // question costs another query to answer and a wrong answer leaves the most-read page in the
    // tree stale, while a wrong-way-round answer costs one recomputation of a page whose entry
    // was going to expire within 30 seconds anyway.
    keys.push(shapeCacheKey(communityId), claimCacheKey('root', communityId));
  }

  const nodes = [...ids];
  if (nodes.length > MAX_NODE_KEYS) {
    warn(
      `claim ${subject} touched ${nodes.length} nodes; dropping the first ${MAX_NODE_KEYS} ` +
        `and letting the rest expire`
    );
  }
  for (const id of nodes.slice(0, MAX_NODE_KEYS)) keys.push(claimCacheKey('id', id));

  // cacheDel already swallows a per-key failure (src/focused_communities/middleware/cache.ts).
  // The catch is for the day it stops doing that: an invalidation error may not turn a committed
  // write into a 500.
  await cacheDel(...keys).catch((err: Error) => warn(`delete failed: ${err.message}`));
}

/**
 * Drop the entries a successful claim write made stale, BEFORE its response is sent.
 *
 * Deleting first is what routes/posts.ts and routes/threads.ts already do, and it is what closes
 * the read-after-write window: a client that re-reads the moment it sees its own 200 would
 * otherwise be served the entry this write invalidated.
 *
 * Only a 2xx is a write. A 401, a 403, a 404 or a refusal wrote nothing, and `DELETE /claims/:id`
 * answers 405, so they all pass straight through with res.json untouched.
 */
export function claimWriteInvalidation(req: Request, res: Response, next: NextFunction): void {
  if (req.method === 'GET' || req.method === 'HEAD') {
    next();
    return;
  }
  const subject = subjectOf(req.path);
  if (subject === null) {
    next();
    return;
  }

  const sendJson = res.json.bind(res);
  res.json = ((body: unknown) => {
    // Restore first: this wrapper fires once, and a second res.json on the same response (an
    // error after a body) must not queue a second invalidation behind a send that cannot happen.
    res.json = sendJson;
    if (res.statusCode < 200 || res.statusCode >= 300) return sendJson(body);
    // 🔴 THE CATCH IS BEFORE THE THEN, SO THE BODY IS SENT ON EXACTLY ONE PATH AND ON EVERY
    // PATH. invalidate() is written never to reject — it guards its pool.query and attaches a
    // .catch to cacheDel — but "written never to" is an audit, not a guarantee, and the cost of
    // being wrong is specific: no sendJson, no error handler (this wrapper has already restored
    // res.json), and a client holding an open socket until timeout on a request whose write
    // COMMITTED. That is the one outcome this whole file exists to prevent. Recovering here
    // makes it unconditional. A rejection handler attached AFTER .then would also fire when
    // sendJson itself threw, and would then try to send the body a second time.
    void invalidate(subject, res)
      .catch((err: Error) => warn(`invalidation for claim ${subject} threw: ${err.message}`))
      .then(() => {
        sendJson(body);
      });
    return res;
  }) as Response['json'];

  next();
}
