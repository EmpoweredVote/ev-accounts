// Reading the argument tree.
//
// A community's claims form a Kialo-style tree: one root claim per community, and every other
// claim `supports` or `opposes` its parent. A reader sees one claim at a time — its ancestry as a
// breadcrumb, and its children split into two columns. These routes serve exactly that view:
//
//   GET /communities/:id/claims/root  — the community's root claim, as a node
//   GET /claims/:claimId              — any claim, as a node
//
// Both answer `{ data: ClaimNode, meta }`. A third route serves the minimap that sits beside that
// view — the whole tree, as position only:
//
//   GET /communities/:id/claims/shape — every claim in the community, with no text at all
//
// Paths are bare because app.ts mounts this router under the Focused Communities mount points
// (/fc/api and /api/fc), exactly as for its siblings.
//
// Four things in here are deliberate and worth reading before changing them:
//   1. The breadcrumb is ONE query at any depth (see loadBreadcrumb).
//   2. A hidden claim is a tombstone, not a hole (see toClaim and the note on GET /claims/:id).
//   3. A column's ORDER BY, its keyset predicate and its cursor are one unit (see "Column order").
//   4. The shape payload never selects body, let alone serializes it (see "Tree shape").

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

/** What an anonymous body may be held for downstream — the same window the server holds it. */
const ANON_CACHE_CONTROL = `public, max-age=0, s-maxage=${CLAIM_TTL_SECONDS}`;

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
  /** Read to key the children queries on the indexed leading column. Never serialized. */
  community_id: string;
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

// --- Column order: ORDER BY, keyset predicate and cursor, together ----------
//
// These three are one unit. The ORDER BY decides what "the next page" means; the predicate has to
// express "strictly after this row" in exactly those keys; and the cursor has to carry exactly the
// values the predicate compares. If any one of them names a different set of keys than the other
// two, nothing fails to compile and nothing fails a test — the column just silently re-serves some
// children and permanently drops others. That is why columnCursorOf() lives beside
// columnKeysetPredicate() instead of being inlined at the call site: the value written into a
// cursor and the values read back out of it are produced three lines apart.
//
// TASK 5, the settled design. Task 5 adds `impact`, the rating aggregate a column is meant to be
// ranked by; until it exists, a column is ordered by recency alone. Adding it is NOT a matter of
// prefixing the ORDER BY — that alone is the exact silent bug described above. All three change:
//
//   1. ORDER BY becomes `c.impact DESC NULLS LAST, c.created_at DESC, c.id DESC`.
//   2. The cursor payload grows a third value, the impact of the last row served. encodeCursor /
//      decodeCursor in ../lib/utils.js carry only {t, id}, so this needs a wider payload (and the
//      validation in parseColumnCursor grows a third check).
//   3. The predicate becomes a three-term keyset with explicit NULLS LAST handling, because a null
//      impact sorts after every non-null one. "Strictly after the cursor" is then, in order:
//      a non-null cursor impact admits rows with a smaller impact and rows with a null impact; a
//      null cursor impact admits only other null-impact rows; and ties on impact fall through to
//      the existing (created_at, id) comparison. Note that `c.impact < $n::timestamptz` is what
//      you get if you merely repoint the old predicate at a numeric column.
//
// And the consequence to document in the API, not to engineer away: impact is mutable, so keyset
// paging over it is approximate. A child whose rating changes between two page requests can appear
// twice or not at all. Capping and sorting in JS would avoid that, but meta.cursor is already a
// shipped contract with a test behind it, so the approximation is the accepted trade.

const COLUMN_ORDER_BY = 'c.created_at DESC, c.id DESC';

/** The sort key of a row, as a cursor carries it. Must name exactly the ORDER BY keys. */
function columnCursorOf(claim: Claim): string {
  return encodeCursor(claim.createdAt, claim.id);
}

/**
 * "Strictly after `cursor`" under COLUMN_ORDER_BY. Appends its values to `params` and numbers the
 * placeholders from where they land, so the predicate does not care how many parameters precede it.
 */
function columnKeysetPredicate(cursor: ColumnCursor, params: unknown[]): string {
  params.push(cursor.t, cursor.id);
  const t = `$${params.length - 1}::timestamptz`;
  const id = `$${params.length}::uuid`;
  return `(c.created_at < ${t} OR (c.created_at = ${t} AND c.id < ${id}))`;
}

// --- Request parameters ----------------------------------------------------

export interface ColumnCursor {
  t: string;
  id: string;
}

/**
 * A uuid in the one spelling Postgres gives back. Deliberately not a parser: uppercase,
 * brace-wrapped and hyphen-less forms are all accepted by `::uuid` and would each mint their own
 * cache entry for one row, so an id that is not already in canonical form is simply not an id here.
 * (The `i` flag is kept so a correctly-shaped uppercase id is recognised and then lowercased for
 * the key, rather than being rejected outright.)
 */
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * The exact shape `ts()` emits: `2026-04-17T12:00:00+00:00`, with one to six optional fractional
 * digits. The offset is `+00:00` on this database (session TimeZone is UTC); `Z` and other offsets
 * are admitted because the same expression emits them under a different session timezone, and a
 * cursor must stay readable if that ever changes.
 */
const ISO_TS_RE =
  /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d{1,6})?(?:Z|([+-])(\d{2}):(\d{2}))$/;

const DAYS_IN_MONTH = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

/**
 * Is this a timestamp Postgres will accept?
 *
 * `Number.isNaN(Date.parse(t))` is not that question. JavaScript's parser is a superset of
 * Postgres's: it reads `"1"` as the year 2001, `"x 1"` likewise, and rolls `2026-02-31` forward
 * into March, while `select '1'::timestamptz` is a hard 22007. A validator that accepts more than
 * its consumer does is not a validator — it just moves the failure one layer down, into an
 * anonymous 500. So the shape is pinned by regex and then the fields are range-checked, which is
 * where year 0000 (Postgres has no year zero), month 13, hour 25 and February 31 die.
 */
function isPostgresTimestamp(t: string): boolean {
  const m = ISO_TS_RE.exec(t);
  if (!m) return false;
  const [, y, mo, d, h, mi, s, , offH, offM] = m;
  const year = Number(y), month = Number(mo), day = Number(d);
  if (year < 1 || month < 1 || month > 12) return false;
  const leap = (year % 4 === 0 && year % 100 !== 0) || year % 400 === 0;
  const maxDay = month === 2 && leap ? 29 : DAYS_IN_MONTH[month - 1];
  if (day < 1 || day > maxDay) return false;
  if (Number(h) > 23 || Number(mi) > 59 || Number(s) > 59) return false;
  if (offH !== undefined && (Number(offH) > 14 || Number(offM) > 59)) return false;
  // Belt as well as braces: anything that survived the above and still will not parse is not ours.
  return !Number.isNaN(Date.parse(t));
}

/**
 * A cursor only counts once its CONTENTS are usable, not merely once it base64-decodes.
 * decodeCursor checks that `t` and `id` are strings; a string is neither a timestamptz nor a uuid,
 * and handing one straight to Postgres turns a crafted query string into an anonymous 500.
 *
 * The returned object is rebuilt field by field rather than passed through, so nothing a caller
 * smuggled into the encoded JSON can reach the cache key and fragment it.
 */
function parseColumnCursor(raw: unknown): ColumnCursor | null {
  if (typeof raw !== 'string') return null;
  const decoded = decodeCursor(raw);
  if (!decoded) return null;
  if (!UUID_RE.test(decoded.id)) return null;
  if (!isPostgresTimestamp(decoded.t)) return null;
  return { t: decoded.t, id: decoded.id.toLowerCase() };
}

interface ColumnParams {
  limit: number;
  supports: ColumnCursor | null;
  opposes: ColumnCursor | null;
}

/**
 * Parsed once per request and shared by the queries and the cache key, so the two always agree.
 *
 * A cursor that is PRESENT and unusable is a 400, not a silent restart at page one — and that
 * includes one that does not even base64-decode, so there is one rule here rather than two. A
 * cursor is never typed by a human: it is only ever echoed back from a response this API issued,
 * so an unusable one means the client is broken or the link was mangled. Serving page one in that
 * case answers a question nobody asked — the reader was on page three, the body comes back with
 * `hasMore: true`, and a paginating client appends the same duplicates forever, because the same
 * bad cursor keeps coming back. Refusing says what happened, once.
 *
 * This is a deliberate divergence from routes/threads.ts, which ignores a cursor it cannot read.
 */
function parseColumnParams(req: Request): { params: ColumnParams } | { invalid: string } {
  const supports = req.query.supportsCursor;
  const opposes = req.query.opposesCursor;
  const parsedSupports = supports === undefined ? null : parseColumnCursor(supports);
  if (supports !== undefined && parsedSupports === null) return { invalid: 'supportsCursor' };
  const parsedOpposes = opposes === undefined ? null : parseColumnCursor(opposes);
  if (opposes !== undefined && parsedOpposes === null) return { invalid: 'opposesCursor' };
  return {
    params: {
      limit: parseLimit(req.query.limit as string | undefined, COLUMN_PAGE_SIZE),
      supports: parsedSupports,
      opposes: parsedOpposes,
    },
  };
}

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
async function loadBreadcrumb(claimId: string, path: string[] | null): Promise<BreadcrumbItem[]> {
  if (!path || path.length === 0) return [];
  const { rows } = await pool.query<BreadcrumbRow>(
    `SELECT c.id, c.body, c.side, c.moderation_status
       FROM connect.claims c
      WHERE c.id = ANY($1::uuid[])
      ORDER BY array_position($1::uuid[], c.id)`,
    [path]
  );
  if (rows.length !== path.length) {
    // The breadcrumb shortens rather than fails, but a path pointing at a row that is not there
    // means the tree is damaged; say so once rather than letting it look like a shallow claim.
    console.warn(
      `[focused_communities] claim ${claimId}: breadcrumb resolved ${rows.length} of ${path.length} ancestors`
    );
  }
  return rows.map((r) => ({
    id: r.id,
    body: r.moderation_status === 'visible' ? r.body : '',
    side: r.side,
  }));
}

/**
 * One column of children, bounded.
 *
 * community_id leads the WHERE because claims_community_parent_idx is on
 * (community_id, parent_claim_id): without it this is a sequential scan of every community's
 * claims plus a sort, twice per request, on the hottest read in the feature.
 *
 * Hidden children are included (as tombstones) — a column shows what is there, and filtering them
 * out would silently contradict the parent's child counts.
 */
async function loadColumn(
  communityId: string,
  parentId: string,
  side: ClaimSide,
  cursor: ColumnCursor | null,
  limit: number
): Promise<{ claims: Claim[]; page: ColumnPage }> {
  const params: unknown[] = [communityId, parentId, side];
  const where = ['c.community_id = $1', 'c.parent_claim_id = $2', 'c.side = $3'];
  if (cursor) where.push(columnKeysetPredicate(cursor, params));
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
      cursor: hasMore && last ? columnCursorOf(last) : null,
      hasMore,
    },
  };
}

/** The claim, its breadcrumb and both columns: at most four queries, whatever the depth. */
async function buildNode(
  row: RootedClaimRow,
  params: ColumnParams
): Promise<{ data: ClaimNode; meta: ClaimNodeMeta }> {
  const [breadcrumb, supports, opposes] = await Promise.all([
    loadBreadcrumb(row.id, row.path),
    loadColumn(row.community_id, row.id, 'supports', params.supports, params.limit),
    loadColumn(row.community_id, row.id, 'opposes', params.opposes, params.limit),
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
//     private, no-store so nothing downstream keeps it either. Identity in this codebase arrives
//     only as an Authorization: Bearer header (middleware/auth.ts) — there is no cookie path.

/**
 * Which route is asking, so that two routes cannot name one key. `root:<id>` and `id:<id>` used to
 * share a namespace, which meant `GET /claims/root:<community-uuid>` built the identical key as
 * that community's root request and, once the root was cached, answered 200 with the root's body
 * for an id that is not a claim id at all and owes a 404. The ids reaching these are uuid-shaped
 * and lowercased by the routes, so one row has exactly one key.
 */
type CacheNamespace = 'id' | 'root';

/**
 * The key is built from the DECODED, normalized cursors, never from the raw query strings: raw
 * strings joined with a delimiter let two different requests mint one key (a cursor containing the
 * delimiter), and every distinct piece of garbage would otherwise get its own entry for a body
 * identical to page one's.
 */
function claimCacheKey(ns: CacheNamespace, id: string, params: ColumnParams): string {
  return `fc:claim:${ns}:${id}:${JSON.stringify({
    limit: params.limit,
    supports: params.supports,
    opposes: params.opposes,
  })}`;
}

/** True only while nothing in the body depends on who asked. Exported so it can be tested. */
export function isShareable(node: ClaimNode): boolean {
  return [node.claim, ...node.supports, ...node.opposes].every((c) => c.myRating === null);
}

/**
 * The only path by which a node body reaches the shared cache. Exported as a seam so the guard can
 * be tested directly — while myRating is hardcoded null, nothing else can produce a body that
 * exercises it.
 */
export async function cacheNodeIfShareable(
  key: string,
  body: { data: ClaimNode; meta: ClaimNodeMeta }
): Promise<void> {
  if (!isShareable(body.data)) return;
  await cache.set(key, body, CLAIM_TTL_SECONDS).catch(() => {});
}

function carriesCredentials(req: Request): boolean {
  return Boolean(req.headers.authorization) || Boolean((req as Request & { userId?: string }).userId);
}

// --- Routes ----------------------------------------------------------------

/**
 * Every error here is no-store. A 404 or a 500 is a fact about this instant — the claim may exist
 * a second from now, the database may be back — and a shared cache left to its own heuristics will
 * happily hold a transient one for minutes.
 */
function notFound(res: Response): void {
  res.set('Cache-Control', 'no-store');
  res.status(404).json({ error: { code: 'CLAIM_NOT_FOUND', message: 'Claim not found' } });
}

/**
 * A query failed. The real message is for the logs; the caller gets a fixed string.
 *
 * A raw Postgres message in an anonymous response is the one hole in this module's leak discipline:
 * it names columns, types and sometimes values, and it is the difference between a bad cursor
 * costing an attacker a dull 500 and handing them a schema probe.
 */
function internalError(res: Response, context: string, err: unknown): void {
  console.error(`[focused_communities] ${context}:`, (err as Error).message);
  res.set('Cache-Control', 'no-store');
  res.status(500).json({
    error: { code: 'CLAIM_FETCH_FAILED', message: 'Could not read the claim' },
  });
}

/** A cursor the client sent that this API could not have issued. */
function invalidCursor(res: Response, field: string): void {
  res.set('Cache-Control', 'no-store');
  res.status(400).json({
    error: { code: 'INVALID_CURSOR', message: `${field} is not a cursor this API issued` },
  });
}

/**
 * Serve one claim as a node. `lookup` returns the claim row or null; a null — missing id,
 * malformed id, a community with no root — is a 404, never a 403: which claims exist is not
 * something an error code should teach.
 *
 * `id` is already uuid-shaped and lowercased when it gets here: the routes check that before the
 * id reaches either the cache key or the database.
 */
async function serveNode(
  req: Request,
  res: Response,
  ns: CacheNamespace,
  id: string,
  lookup: () => Promise<RootedClaimRow | null>
): Promise<void> {
  const parsed = parseColumnParams(req);
  if ('invalid' in parsed) {
    res.set('Vary', 'Authorization');
    invalidCursor(res, parsed.invalid);
    return;
  }
  const params = parsed.params;
  const key = claimCacheKey(ns, id, params);
  const personalized = carriesCredentials(req);

  // The body varies on Authorization today (the cache branch) and will vary in its content as
  // soon as Task 5 lands, so every response says so, including the errors.
  res.set('Vary', 'Authorization');

  if (personalized) {
    res.set('Cache-Control', 'private, no-store');
  } else {
    const cached = await cache.get<unknown>(key);
    if (cached !== null) {
      res.set('Cache-Control', ANON_CACHE_CONTROL);
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
    body = await buildNode(row, params);
  } catch (err) {
    internalError(res, `claim node ${id}`, err);
    return;
  }

  if (!personalized) {
    await cacheNodeIfShareable(key, body);
    res.set('Cache-Control', ANON_CACHE_CONTROL);
  }
  res.json(body);
}

// GET /communities/:id/claims/root — the community's single root claim, as a node.
// Served by claims_one_root_per_community (unique, partial, on community_id WHERE parent IS NULL).
claimsRouter.get('/communities/:id/claims/root', async (req: Request, res: Response) => {
  const raw = req.params.id as string;
  if (!UUID_RE.test(raw)) {
    notFound(res); // names no community: no key minted, no query run
    return;
  }
  const communityId = raw.toLowerCase();
  await serveNode(req, res, 'root', communityId, async () => {
    const { rows } = await pool.query<RootedClaimRow>(
      `SELECT ${CLAIM_COLUMNS}, c.path, c.community_id
         FROM connect.claims c
        WHERE c.community_id = $1 AND c.parent_claim_id IS NULL`,
      [communityId]
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
//
// The uuid check happens BEFORE the id reaches the cache key or the database, not only because a
// non-uuid cannot name a claim, but because an unconstrained id in a key is a way to reach another
// route's entries.
claimsRouter.get('/claims/:claimId', async (req: Request, res: Response) => {
  const raw = req.params.claimId as string;
  if (!UUID_RE.test(raw)) {
    notFound(res);
    return;
  }
  const claimId = raw.toLowerCase();
  await serveNode(req, res, 'id', claimId, async () => {
    const { rows } = await pool.query<RootedClaimRow>(
      `SELECT ${CLAIM_COLUMNS}, c.path, c.community_id FROM connect.claims c WHERE c.id = $1`,
      [claimId]
    );
    return rows[0] ?? null;
  });
});

// --- Tree shape: the whole argument as position only ------------------------
//
// GET /communities/:id/claims/shape answers `{ data: ShapeNode[], meta }` — every claim in the
// community reduced to where it sits. The node routes above serve ONE claim with its text; this
// serves EVERY claim with none, so the frontend can draw a small coloured map of the whole
// argument with the reader's position marked.
//
// Four properties hold this route up:
//
//   1. NO TEXT, EVER. `body` is not merely stripped in the serializer — it is never selected. A
//      whole-tree payload is the one response large enough that a hidden claim's wording could
//      ride along unnoticed, so the SQL is the guard, not a filter someone has to remember.
//   2. HIDDEN CLAIMS ARE INCLUDED, AND MARKED. The columns tombstone a hidden claim rather than
//      drop it, so a map that omitted one would disagree with what the reader can plainly see
//      beside it. Drawing one as an ordinary node is the same disagreement moved: a minimap exists
//      to show the pro/con balance at each depth, and counting a withdrawn claim as a live one
//      misstates exactly that. So `isHidden` rides along — it leaks nothing, being already on
//      every ClaimNode the same reader can fetch, and the payload still carries no text.
//   3. MERGED CLAIMS ARE INCLUDED, AND MARKED. Same principle, sharper consequence. A merged-away
//      claim is a DUPLICATE of another claim — often one drawn beside it — so drawing both as
//      live nodes inflates that side by exactly the number of merges: the map draws one argument
//      as two. `mergedInto` is an id, not wording, and ClaimNode already carries it for the same
//      reader. What it is NOT is a promise that the target is in this payload: see ShapeNode.
//   4. BOUNDED, AND HONEST ABOUT WHERE IT STOPS. A community page loads this on every view, so the
//      payload has a hard cap — and says not just THAT it was cut but how deep it is still whole
//      (see ShapeMeta.completeThroughDepth).

/**
 * The hard cap on nodes in one shape payload.
 *
 * At roughly 190 bytes of JSON per node (two or three uuids and four short fields) this bounds the
 * body at ~380 KB uncompressed, and far less over the wire since every key name repeats. It is a
 * ceiling, not a typical size: it is well above any community's tree today and above the size at
 * which a minimap stops being legible — a few thousand dots in a thumbnail is already a smear — so
 * in practice nothing truncates, and the cap exists to keep a runaway tree from turning the
 * hottest read on the page into a megabyte.
 *
 * Exported because it is part of the contract: a client that sees `truncated: true` is seeing
 * exactly this many nodes.
 */
export const SHAPE_NODE_LIMIT = 2000;

export interface ShapeNode {
  id: string;
  parentId: string | null;
  side: ClaimSide | null;
  depth: number;
  /** The Task 5 rating aggregate, for colouring the map. Null until it exists. */
  impact: number | null;
  /** Mapped exactly as toClaim does it, so the map and the columns agree about one claim. */
  isHidden: boolean;
  /**
   * The claim this one was merged into, when it was: a duplicate argument folded onto another.
   * Drawing a merged claim as a live one inflates that side by exactly the number of merges — the
   * map draws one argument as two — which is why the flag is here. It is an id, never wording,
   * and ClaimNode carries the same field for the same reader.
   *
   * What the schema guarantees about the target is only this: claims_merged_into_claim_id_fkey
   * makes it a real row of connect.claims, and claims_no_self_merge keeps it from being this
   * claim. In particular it is NOT guaranteed to appear in `data`. Nothing pins the target to the
   * same community, and nothing makes it shallower than the claim that names it, so a target can
   * sit below the truncation cut or in the partial boundary level.
   *
   * So the contract is: look the id up in `data`; if it is there, fold this node onto it. If it
   * is NOT there, draw this node as an ordinary node — a visible duplicate is better than a node
   * that vanishes into nothing — and do not read the absence as bad data. And do not assume one
   * hop: A merged into B and B merged into C is allowed, so a client that folds must follow the
   * chain and bound the walk, since nothing in the schema forbids a cycle either. This endpoint
   * resolves none of that; it reports the edge it was given.
   */
  mergedInto: string | null;
}

export interface ShapeMeta {
  /** True when the tree is larger than SHAPE_NODE_LIMIT and the deepest nodes were cut. */
  truncated: boolean;
  /**
   * The deepest level this payload is known to hold WHOLE — or null when nothing was cut.
   *
   * `truncated` alone cannot say where the map stops being true, and the gap falls on the one
   * thing a minimap exists to show. The cut lands at an arbitrary point INSIDE a depth level,
   * because the tie-break is `id` and an id is a random uuid: the siblings that survive at the
   * boundary depth are an unmarked, arbitrary sample. A level holding 400 supports and 390
   * opposes, cut four nodes in, renders as "3 supports, 1 oppose" — and looks finished. Per-depth
   * pro/con balance is the entire purpose of the thing.
   *
   * So the contract is: at depths <= completeThroughDepth every claim of the community is present
   * and a tally is true. Deeper than that, the nodes present are a sample and no count, balance or
   * "this branch died out" may be drawn from them. null with `truncated: false` means the whole
   * tree is here; read the two fields together, never this one alone.
   *
   * Derived from the first row that did NOT fit — the one extra row the query already fetches.
   * That is sound because ORDER BY depth, id returns a prefix in which every node at depth d is
   * preceded by all nodes at depth < d: derive_claim_position sets depth := parent.depth + 1, and
   * claims_root_or_child_shape pins cardinality(path) = depth. So the first row past the cap names
   * the first level that is incomplete, and everything above it is whole.
   *
   * `0` is a legitimate value, and it means only the root is whole. It is NOT "nothing was cut",
   * so `if (meta.completeThroughDepth)` is a bug: null is the one encoding of "the question does
   * not apply", and the two fields are read together or not at all.
   */
  completeThroughDepth: number | null;
}

interface ShapeRow {
  id: string;
  parent_claim_id: string | null;
  side: ClaimSide | null;
  depth: number;
  /** Read only to derive isHidden. The raw column is never serialized, here or anywhere. */
  moderation_status: string;
  merged_into_claim_id: string | null;
}

/**
 * ORDER BY depth, id — the brief's order, and the one that makes truncation survivable: cutting at
 * a LIMIT drops the DEEPEST nodes, which is the right end to lose. A map missing its deep tips is
 * still a map; one missing a trunk node would have orphaned everything under it. What it does NOT
 * make survivable on its own is the boundary level, which is why meta carries completeThroughDepth.
 *
 * community_id is the whole WHERE clause and the leading column of claims_community_parent_idx, so
 * this is an index scan plus a top-N sort, never a sequential scan of every community's claims.
 * Nothing filters on moderation_status: see property 2 above.
 */
const SHAPE_SQL = `SELECT c.id, c.parent_claim_id, c.side, c.depth, c.moderation_status,
             c.merged_into_claim_id
       FROM connect.claims c
      WHERE c.community_id = $1
      ORDER BY c.depth, c.id
      LIMIT $2`;

/** The allowlist, built by construction. A column not named here cannot reach a reader. */
function toShapeNode(row: ShapeRow): ShapeNode {
  return {
    id: row.id,
    parentId: row.parent_claim_id ?? null,
    side: row.side,
    depth: row.depth,
    impact: null, // Task 5
    isHidden: row.moderation_status !== 'visible',
    mergedInto: row.merged_into_claim_id ?? null,
  };
}

/**
 * The cache key, built by hand for the same reason the node routes build theirs by hand: the
 * shared cacheMiddleware keys on path AND query, and Task 8 has to be able to delete this entry on
 * every claim write without knowing which query strings were ever served under it. There is no
 * query to vary on here and no caller identity in the body, so one entry per community is the
 * whole cache — and `fc:claims:shape:{communityId}` is exactly the key Task 8 deletes.
 *
 * It takes a canonical, lower-case uuid and nothing else. See the route.
 *
 * Note what is deliberately missing: the node routes' isShareable guard. It exists because Task 5
 * puts the caller's own rating in a ClaimNode, and a body carrying one reader's rating must never
 * be handed to another. A ShapeNode has no such field and no room for one — it is tree position
 * plus two flags every reader sees alike. If a caller-varying field is ever added to it, this
 * route must grow the same guard and the same credentials branch that serveNode has.
 */
function shapeCacheKey(communityId: string): string {
  return `fc:claims:shape:${communityId}`;
}

// GET /communities/:id/claims/shape — the whole tree's shape, for the minimap.
//
// A community with no claims is a 404, as its root is: there is no argument to map, and the page
// is already showing that. A real query failure is a 500, because an empty map is a claim about
// the tree and this route does not make claims it cannot support.
//
// The id is checked and lower-cased BEFORE it reaches the cache key or the database, as it now is
// on both node routes. An id that is not a uuid names no community, so it 404s having minted no
// key and run no query. And canonicalising matters even for an id that IS one: Postgres reads
// `{A0EEBC99-…}`, the hyphenless spelling and every mixed case as the same row, so a key built
// from the raw text would give each spelling its own ~380 KB entry on the shared Upstash instance
// — the exact quota exhaustion src/lib/cache.ts records as a P1 — and Task 8's `del` of the
// lower-case key would miss every one of them, leaving stale maps behind each alias.
claimsRouter.get('/communities/:id/claims/shape', async (req: Request, res: Response) => {
  const raw = req.params.id as string;
  if (!UUID_RE.test(raw)) {
    notFound(res); // names no community: no key minted, no query run
    return;
  }
  const communityId = raw.toLowerCase();
  const key = shapeCacheKey(communityId);

  const cached = await cache.get<unknown>(key);
  if (cached !== null) {
    res.set('Cache-Control', ANON_CACHE_CONTROL);
    res.json(cached);
    return;
  }

  let rows: ShapeRow[];
  try {
    // One more than the cap, so "there is more" — and where it stopped — is observed, not guessed.
    ({ rows } = await pool.query<ShapeRow>(SHAPE_SQL, [communityId, SHAPE_NODE_LIMIT + 1]));
  } catch (err) {
    // No 22P02 branch: UUID_RE ran before the query, so the id cannot be malformed by now.
    internalError(res, `claim shape ${communityId}`, err);
    return;
  }

  if (rows.length === 0) {
    notFound(res);
    return;
  }

  // The first row that did not fit is what tells the reader where the map stops being whole: its
  // own depth is the one cut part-way through, so every level above it is complete.
  //
  // `- 1` cannot go negative, and is deliberately not clamped. claims_one_root_per_community
  // (UNIQUE, partial, on community_id WHERE parent_claim_id IS NULL) allows exactly one depth-0
  // row per community, so with a cap in the thousands the first row past it is always at depth
  // >= 1. A defensive Math.max(0, …) here would buy nothing today and would quietly swallow the
  // real bug — a second root — on the day that constraint changes.
  const firstCut = rows[SHAPE_NODE_LIMIT];
  const body: { data: ShapeNode[]; meta: ShapeMeta } = {
    data: rows.slice(0, SHAPE_NODE_LIMIT).map(toShapeNode),
    meta: {
      truncated: firstCut !== undefined,
      completeThroughDepth: firstCut === undefined ? null : firstCut.depth - 1,
    },
  };

  await cache.set(key, body, CLAIM_TTL_SECONDS).catch(() => {});
  res.set('Cache-Control', ANON_CACHE_CONTROL);
  res.json(body);
});
