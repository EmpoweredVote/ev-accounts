// Reading the argument tree.
//
// A community's claims form a Kialo-style tree: one root claim per community, and every other
// claim `supports` or `opposes` its parent. A reader sees one claim at a time — its ancestry as a
// breadcrumb, and its children split into two columns. These two routes serve exactly that view:
//
//   GET /communities/:id/claims/root  — the community's root claim, as a node
//   GET /claims/:claimId              — any claim, as a node
//
// Both answer `{ data: ClaimNode, meta }`. Paths are bare because app.ts mounts this router under
// the Focused Communities mount points (/fc/api and /api/fc), exactly as for its siblings.
//
// Three things in here are deliberate and worth reading before changing them:
//   1. The breadcrumb is ONE query at any depth (see loadBreadcrumb).
//   2. A hidden claim is a tombstone, not a hole (see toClaim and the note on GET /claims/:id).
//   3. Column ordering has a single home (see COLUMN_ORDER_BY) so Task 5 can drop `impact` in.

import { Router } from 'express';
import type { Request, Response } from 'express';
import { pool } from '../config/database.js';
import { ts } from '../lib/sql.js';
import { cache } from '../../lib/cache.js';
import { encodeCursor, decodeCursor, parseLimit } from '../lib/utils.js';

export const claimsRouter = Router();

/** Short, like the thread list: a live tree changes as people argue in it. */
const CLAIM_TTL_SECONDS = 30;

/** Children per column per request. A claim with 500 children serves a page, never 500 rows. */
const COLUMN_PAGE_SIZE = 20;

// --- Types -----------------------------------------------------------------

export type ClaimSide = 'supports' | 'opposes';

export interface Claim {
  id: string;
  side: ClaimSide | null;
  body: string;
  authorPseudonym: string | null;
  /** The Task 5 rating aggregate. Null until it exists. */
  impact: number | null;
  ratingCount: number;
  childSupports: number;
  childOpposes: number;
  isHidden: boolean;
  mergedInto: string | null;
  createdAt: string;
  updatedAt: string;
  /** The caller's own rating, which only the server can know. Task 5 fills it; null until then. */
  myRating: number | null;
}

export interface BreadcrumbItem {
  id: string;
  body: string;
  side: ClaimSide | null;
}

export interface ClaimNode {
  claim: Claim;
  breadcrumb: BreadcrumbItem[];
  supports: Claim[];
  opposes: Claim[];
}

/** One column's pagination state. Same shape as the thread list's meta, once per column. */
export interface ColumnPage {
  cursor: string | null;
  hasMore: boolean;
}

export interface ClaimNodeMeta {
  supports: ColumnPage;
  opposes: ColumnPage;
}

interface ClaimRow {
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

interface RootedClaimRow extends ClaimRow {
  /** Root-first ancestor ids, excluding self. A root's is empty. */
  path: string[] | null;
}

interface BreadcrumbRow {
  id: string;
  body: string;
  side: ClaimSide | null;
  moderation_status: string;
}

// --- SQL -------------------------------------------------------------------

const CLAIM_COLUMNS = `c.id, c.side, c.body, c.author_display_name, c.moderation_status,
         c.child_supports_count, c.child_opposes_count, c.merged_into_claim_id,
         ${ts('c.created_at')}, ${ts('c.updated_at')}`;

// Column ordering lives here and nowhere else.
//
// Task 5 adds `impact`, the rating aggregate each column is meant to be ranked by. It does not
// exist yet, so until it does a column is ordered by recency alone. When it lands, this block is
// the whole change: put `c.impact DESC NULLS LAST,` in front of COLUMN_ORDER_BY and point
// COLUMN_CURSOR_COLUMN at whatever remains the cursor's tiebreak. Nothing else in this file names
// a sort column — loadColumn builds its ORDER BY, its keyset predicate and its cursor from these
// two constants, so there is no second copy to miss.
const COLUMN_CURSOR_COLUMN = 'c.created_at';
const COLUMN_ORDER_BY = `${COLUMN_CURSOR_COLUMN} DESC, c.id DESC`;

// --- Serialization ---------------------------------------------------------

/**
 * A hidden claim is served as a tombstone, not omitted: its body and author are withheld, but its
 * id, side, timestamps and child counts remain so the subtree under it stays navigable. Hiding one
 * claim must not orphan every argument beneath it.
 *
 * author_id, community_id, path, depth, moderation_status and the raw count column names never
 * appear in a response — isHidden is the only thing a reader learns about moderation.
 */
function toClaim(row: ClaimRow): Claim {
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
    myRating: null, // Task 5
  };
}

// --- Loading ---------------------------------------------------------------

/**
 * The ancestry, root-first, in ONE query at any depth.
 *
 * `path` already holds every ancestor id in order, so there is nothing to walk: fetch the set and
 * let `array_position` restore the order. A 40-deep claim costs the same one query as a 1-deep one.
 */
async function loadBreadcrumb(path: string[] | null): Promise<BreadcrumbItem[]> {
  if (!path || path.length === 0) return [];
  const { rows } = await pool.query<BreadcrumbRow>(
    `SELECT c.id, c.body, c.side, c.moderation_status
       FROM connect.claims c
      WHERE c.id = ANY($1::uuid[])
      ORDER BY array_position($1::uuid[], c.id)`,
    [path]
  );
  return rows.map((r) => ({
    id: r.id,
    body: r.moderation_status === 'visible' ? r.body : '',
    side: r.side,
  }));
}

/**
 * One column of children, bounded. Hidden children are included (as tombstones) — a column shows
 * what is there, and filtering them out would silently renumber a parent's child counts.
 */
async function loadColumn(
  parentId: string,
  side: ClaimSide,
  rawCursor: string | undefined,
  limit: number
): Promise<{ claims: Claim[]; page: ColumnPage }> {
  const params: unknown[] = [parentId, side];
  const where = ['c.parent_claim_id = $1', 'c.side = $2'];

  const decoded = rawCursor ? decodeCursor(rawCursor) : null;
  if (decoded) {
    params.push(decoded.t, decoded.id);
    where.push(
      `(${COLUMN_CURSOR_COLUMN} < $3::timestamptz` +
        ` OR (${COLUMN_CURSOR_COLUMN} = $3::timestamptz AND c.id < $4::uuid))`
    );
  }
  params.push(limit + 1);

  const { rows } = await pool.query<ClaimRow>(
    `SELECT ${CLAIM_COLUMNS}
       FROM connect.claims c
      WHERE ${where.join(' AND ')}
      ORDER BY ${COLUMN_ORDER_BY}
      LIMIT $${params.length}`,
    params
  );

  const hasMore = rows.length > limit;
  const claims = rows.slice(0, limit).map(toClaim);
  const last = claims[claims.length - 1];
  return {
    claims,
    page: {
      cursor: hasMore && last ? encodeCursor(last.createdAt, last.id) : null,
      hasMore,
    },
  };
}

/** The claim, its breadcrumb and both columns: at most four queries, whatever the depth. */
async function buildNode(
  row: RootedClaimRow,
  req: Request
): Promise<{ data: ClaimNode; meta: ClaimNodeMeta }> {
  const limit = parseLimit(req.query.limit as string | undefined, COLUMN_PAGE_SIZE);
  const [breadcrumb, supports, opposes] = await Promise.all([
    loadBreadcrumb(row.path),
    loadColumn(row.id, 'supports', req.query.supportsCursor as string | undefined, limit),
    loadColumn(row.id, 'opposes', req.query.opposesCursor as string | undefined, limit),
  ]);
  return {
    data: {
      claim: toClaim(row),
      breadcrumb,
      supports: supports.claims,
      opposes: opposes.claims,
    },
    meta: { supports: supports.page, opposes: opposes.page },
  };
}

// --- Caching ---------------------------------------------------------------
//
// The shared cacheMiddleware keys on path + query with NO caller identity, so it may only ever
// hold a body that has no caller identity in it either. Today these are anonymous reads and every
// body qualifies — but Task 5 puts the caller's own rating in `myRating`, and a body carrying one
// reader's rating must never be handed to another. So the cache is driven by hand here, behind two
// guards that are code rather than a comment someone has to notice:
//
//   - isShareable() refuses to STORE a body that carries any caller-specific field. The day
//     myRating stops being null, these bodies stop entering the shared cache by themselves.
//   - a request that carries credentials never READS the shared (anonymous) body, and is marked
//     private, no-store so nothing downstream keeps it either.

function claimCacheKey(claimId: string, req: Request): string {
  const limit = parseLimit(req.query.limit as string | undefined, COLUMN_PAGE_SIZE);
  const supportsCursor = (req.query.supportsCursor as string | undefined) ?? '';
  const opposesCursor = (req.query.opposesCursor as string | undefined) ?? '';
  return `fc:claim:${claimId}:${limit}:${supportsCursor}:${opposesCursor}`;
}

/** True only while nothing in the body depends on who asked. */
function isShareable(node: ClaimNode): boolean {
  return [node.claim, ...node.supports, ...node.opposes].every((c) => c.myRating === null);
}

function carriesCredentials(req: Request): boolean {
  return Boolean(req.headers.authorization) || Boolean((req as Request & { userId?: string }).userId);
}

// --- Routes ----------------------------------------------------------------

function notFound(res: Response): void {
  res.status(404).json({ error: { code: 'CLAIM_NOT_FOUND', message: 'Claim not found' } });
}

/**
 * Serve one claim as a node. `lookup` returns the claim row or null; a null — missing id,
 * malformed id, a community with no root — is a 404, never a 403: which claims exist is not
 * something an error code should teach.
 */
async function serveNode(
  req: Request,
  res: Response,
  cacheId: string,
  lookup: () => Promise<RootedClaimRow | null>
): Promise<void> {
  const key = claimCacheKey(cacheId, req);
  const personalized = carriesCredentials(req);
  if (personalized) {
    res.set('Cache-Control', 'private, no-store');
  } else {
    const cached = await cache.get<unknown>(key);
    if (cached !== null) {
      res.json(cached);
      return;
    }
  }

  let row: RootedClaimRow | null = null;
  try {
    row = await lookup();
  } catch {
    // a malformed id throws (22P02): treated as not found, as elsewhere in this module
  }
  if (!row) {
    notFound(res);
    return;
  }

  let body: { data: ClaimNode; meta: ClaimNodeMeta };
  try {
    body = await buildNode(row, req);
  } catch (err) {
    res.status(500).json({ error: { code: 'CLAIM_FETCH_FAILED', message: (err as Error).message } });
    return;
  }

  if (!personalized && isShareable(body.data)) {
    await cache.set(key, body, CLAIM_TTL_SECONDS).catch(() => {});
  }
  res.json(body);
}

// GET /communities/:id/claims/root — the community's single root claim, as a node.
// Served by claims_one_root_per_community (unique, partial, on community_id WHERE parent IS NULL).
claimsRouter.get('/communities/:id/claims/root', async (req: Request, res: Response) => {
  await serveNode(req, res, `root:${req.params.id}`, async () => {
    const { rows } = await pool.query<RootedClaimRow>(
      `SELECT ${CLAIM_COLUMNS}, c.path
         FROM connect.claims c
        WHERE c.community_id = $1 AND c.parent_claim_id IS NULL`,
      [req.params.id]
    );
    return rows[0] ?? null;
  });
});

// GET /claims/:claimId — any claim, as a node.
//
// A hidden claim answers 200 with a tombstone node rather than 404. It is not an exception to
// "hidden content 404s": a hidden claim is already visible as a tombstone in its parent's column,
// so 404 here would hide nothing while making the whole subtree beneath it unreachable. The body
// and the author are what hiding withholds, and toClaim withholds them. An id that does not exist,
// or is not a uuid, still 404s — and nothing here ever answers 403.
claimsRouter.get('/claims/:claimId', async (req: Request, res: Response) => {
  const claimId = req.params.claimId as string;
  await serveNode(req, res, claimId, async () => {
    const { rows } = await pool.query<RootedClaimRow>(
      `SELECT ${CLAIM_COLUMNS}, c.path FROM connect.claims c WHERE c.id = $1`,
      [claimId]
    );
    return rows[0] ?? null;
  });
});
