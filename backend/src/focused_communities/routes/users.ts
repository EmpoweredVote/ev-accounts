import { Router } from 'express';
import type { Request, Response } from 'express';
import { pool } from '../config/database.js';
import { ts } from '../lib/sql.js';
import { encodeCursor, decodeCursor, parseLimit, generateExcerpt } from '../lib/utils.js';
import { requireAuth, type FcRequest } from '../middleware/auth.js';

export const usersRouter = Router();

// GET /api/users/:id/posts — cursor-paginated post history for the authenticated user
// Self-only gate: :id must match the authenticated user's ID (returns 403 for mismatch)
// No cacheMiddleware — auth-gated user-specific data must never be cached
usersRouter.get('/users/:id/posts', ...requireAuth, async (req: Request, res: Response) => {
  const user = (req as FcRequest).user!;
  // Self-only gate: user can only retrieve their own post history
  if (req.params.id !== user.id) {
    res.status(403).json({
      error: { code: 'FORBIDDEN', message: 'You can only view your own post history' },
    });
    return;
  }

  const limit = parseLimit(req.query.limit as string | undefined, 20);
  const cursor = req.query.cursor as string | undefined;

  const params: unknown[] = [user.id];
  const where = [`p.author_id = $1`, `p.moderation_status = 'visible'`];
  if (cursor) {
    const decoded = decodeCursor(cursor);
    if (decoded) {
      params.push(decoded.t, decoded.id);
      where.push(`(p.created_at < $2::timestamptz OR (p.created_at = $2::timestamptz AND p.id < $3::uuid))`);
    }
  }
  params.push(limit + 1);

  let rows: Array<{
    id: string; body: string; author_display_name: string; created_at: string; updated_at: string;
    thread_id: string; thread_title: string; community_id: string; community_name: string; community_slug: string;
  }>;
  try {
    // Inner joins, as the PostgREST !inner embeds were.
    ({ rows } = await pool.query(
      `SELECT p.id, p.body, p.author_display_name, ${ts('p.created_at')}, ${ts('p.updated_at')},
              t.id AS thread_id, t.title AS thread_title, t.community_id,
              c.name AS community_name, c.slug AS community_slug
       FROM connect.posts p
       JOIN connect.threads t ON t.id = p.thread_id
       JOIN connect.communities c ON c.id = t.community_id
       WHERE ${where.join(' AND ')}
       ORDER BY p.created_at DESC, p.id DESC
       LIMIT $${params.length}`,
      params
    ));
  } catch (err) {
    res.status(500).json({
      error: { code: 'POST_HISTORY_FETCH_FAILED', message: (err as Error).message },
    });
    return;
  }

  const hasMore = rows.length > limit;
  const items = rows.slice(0, limit).map(p => ({
    postId: p.id,
    threadId: p.thread_id,
    threadTitle: p.thread_title,
    communityId: p.community_id,
    communityName: p.community_name,
    communitySlug: p.community_slug,
    postExcerpt: generateExcerpt(p.body, 200),
    createdAt: p.created_at,
    isEdited: p.updated_at !== p.created_at,
    authorPseudonym: p.author_display_name,
  }));

  const nextCursor = hasMore && items.length > 0
    ? encodeCursor(items[items.length - 1].createdAt, items[items.length - 1].postId)
    : null;

  res.json({ data: items, meta: { cursor: nextCursor, hasMore } });
});
