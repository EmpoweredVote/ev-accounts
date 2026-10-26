import { Router } from 'express';
import type { Request, Response } from 'express';
import { pool } from '../config/database.js';
import { ts } from '../lib/sql.js';
import { cacheMiddleware, TTL } from '../middleware/cache.js';
import { encodeCursor, decodeCursor, parseLimit } from '../lib/utils.js';

export const communitiesRouter = Router();

const COMMUNITY_COLUMNS = `id, slug, name, description, member_count, thread_count, topic_id, slice_label, ${ts('created_at')}`;

interface CommunityRow {
  id: string;
  slug: string;
  name: string;
  description: string | null;
  member_count: number;
  thread_count: number;
  topic_id: string | null;
  slice_label: string | null;
  created_at: string;
}

function toCommunity(c: CommunityRow) {
  return {
    id: c.id,
    slug: c.slug,
    name: c.name,
    description: c.description,
    memberCount: c.member_count,
    threadCount: c.thread_count,
    topicId: c.topic_id,
    sliceLabel: c.slice_label,
    createdAt: c.created_at,
  };
}

/** PostgREST .single(): exactly one row, else nothing. */
function single<T>(rows: T[]): T | null {
  return rows.length === 1 ? rows[0] : null;
}

communitiesRouter.get('/communities', cacheMiddleware(TTL.COMMUNITIES), async (req: Request, res: Response) => {
  const q = req.query.q as string | undefined;
  const sort = (req.query.sort as string) === 'popular' ? 'popular' : 'newest';
  const limit = parseLimit(req.query.limit as string | undefined, 40);
  const cursor = req.query.cursor as string | undefined;

  // Column names come from this fixed pair only — never from the request.
  const sortColumn = sort === 'popular' ? 'member_count' : 'created_at';
  const sortCast = sort === 'popular' ? 'int' : 'timestamptz';

  const where: string[] = [];
  const params: unknown[] = [];
  if (q) {
    params.push(q);
    where.push(`(name ILIKE '%' || $${params.length} || '%' OR description ILIKE '%' || $${params.length} || '%')`);
  }
  if (cursor) {
    const decoded = decodeCursor(cursor);
    if (decoded) {
      params.push(decoded.t, decoded.id);
      const t = `$${params.length - 1}::${sortCast}`;
      const id = `$${params.length}::uuid`;
      where.push(`(${sortColumn} < ${t} OR (${sortColumn} = ${t} AND id < ${id}))`);
    }
  }
  params.push(limit + 1);

  let rows: CommunityRow[];
  try {
    ({ rows } = await pool.query<CommunityRow>(
      `SELECT ${COMMUNITY_COLUMNS} FROM connect.communities
       ${where.length ? `WHERE ${where.join(' AND ')}` : ''}
       ORDER BY ${sortColumn} DESC, id DESC
       LIMIT $${params.length}`,
      params
    ));
  } catch (err) {
    res.status(500).json({ error: { code: 'COMMUNITIES_FETCH_FAILED', message: (err as Error).message } });
    return;
  }

  const hasMore = rows.length > limit;
  const items = rows.slice(0, limit).map(toCommunity);

  const nextCursor = hasMore && items.length > 0
    ? encodeCursor(
        String(items[items.length - 1][sort === 'popular' ? 'memberCount' : 'createdAt']),
        items[items.length - 1].id
      )
    : null;

  res.json({
    data: items,
    meta: { cursor: nextCursor, hasMore },
  });
});

communitiesRouter.get('/communities/:id', cacheMiddleware(TTL.COMMUNITIES), async (req: Request, res: Response) => {
  let data: CommunityRow | null = null;
  try {
    // A malformed id throws 22P02 and lands in the catch: a 404, as PostgREST's error was.
    const { rows } = await pool.query<CommunityRow>(
      `SELECT ${COMMUNITY_COLUMNS} FROM connect.communities WHERE id = $1`,
      [req.params.id]
    );
    data = single(rows);
  } catch {
    // a malformed id throws (22P02): treated as not found, as before
  }

  if (!data) {
    res.status(404).json({ error: { code: 'COMMUNITY_NOT_FOUND', message: 'Community not found' } });
    return;
  }

  res.json({ data: toCommunity(data) });
});

communitiesRouter.get('/communities/by-slug/:slug', cacheMiddleware(TTL.COMMUNITIES), async (req: Request, res: Response) => {
  const { slug } = req.params;

  let data: CommunityRow | null = null;
  try {
    // Primary: exact slug match.
    const exact = await pool.query<CommunityRow>(
      `SELECT ${COMMUNITY_COLUMNS} FROM connect.communities WHERE slug = $1`,
      [slug]
    );
    data = single(exact.rows);

    // Fallback: slug may have been renamed — check history.
    if (!data) {
      const renamed = await pool.query<CommunityRow>(
        `SELECT ${COMMUNITY_COLUMNS} FROM connect.communities WHERE slug_history @> ARRAY[$1]::text[]`,
        [slug]
      );
      data = single(renamed.rows);
    }
  } catch {
    // a malformed id throws (22P02): treated as not found, as before
  }

  if (!data) {
    res.status(404).json({ error: { code: 'COMMUNITY_NOT_FOUND', message: 'Community not found' } });
    return;
  }

  res.json({ data: toCommunity(data) });
});
