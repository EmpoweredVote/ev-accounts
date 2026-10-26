import { Router } from 'express';
import type { Request, Response } from 'express';
import { pool } from '../config/database.js';
import { ts } from '../lib/sql.js';
import { cacheMiddleware, cacheDel, TTL } from '../middleware/cache.js';
import { encodeCursor, decodeCursor, parseLimit, generateExcerpt } from '../lib/utils.js';
import { requireAuth, type FcRequest } from '../middleware/auth.js';
import { requireConnected } from '../middleware/tierGuards.js';
import { postRateLimiter } from '../lib/rateLimit.js';

export const threadsRouter = Router();

const THREAD_DETAIL_COLUMNS = `id, title, body, author_display_name, reply_count, ${ts('created_at')}, ${ts('last_activity_at')}, ${ts('updated_at')}`;

interface ThreadRow {
  id: string;
  title: string;
  body: string;
  author_display_name: string;
  reply_count: number;
  created_at: string;
  last_activity_at: string;
  updated_at: string;
}

function toThread(data: ThreadRow) {
  return {
    id: data.id,
    title: data.title,
    body: data.body,
    authorPseudonym: data.author_display_name,
    replyCount: data.reply_count,
    createdAt: data.created_at,
    lastActivityAt: data.last_activity_at,
    updatedAt: data.updated_at,
    isEdited: data.updated_at !== data.created_at,
  };
}

threadsRouter.get('/communities/:id/threads', cacheMiddleware(TTL.THREAD_LIST), async (req: Request, res: Response) => {
  const communityId = req.params.id;
  // 'active' is the default sort; only 'newest' overrides it.
  // Unknown values silently fall back to 'active' — standard REST behavior for optional sort params.
  const sort = (req.query.sort as string) === 'newest' ? 'newest' : 'active';
  const limit = parseLimit(req.query.limit as string | undefined, 20);
  const cursor = req.query.cursor as string | undefined;

  // Column name comes from this fixed pair only — never from the request.
  const sortColumn = sort === 'newest' ? 'created_at' : 'last_activity_at';

  const params: unknown[] = [communityId];
  const where = [`community_id = $1`, `moderation_status = 'visible'`];
  if (cursor) {
    const decoded = decodeCursor(cursor);
    if (decoded) {
      params.push(decoded.t, decoded.id);
      where.push(
        `(${sortColumn} < $2::timestamptz OR (${sortColumn} = $2::timestamptz AND id < $3::uuid))`
      );
    }
  }
  params.push(limit + 1);

  let rows: Array<Omit<ThreadRow, 'updated_at'>>;
  try {
    ({ rows } = await pool.query(
      `SELECT id, title, body, author_display_name, reply_count, ${ts('created_at')}, ${ts('last_activity_at')}
       FROM connect.threads
       WHERE ${where.join(' AND ')}
       ORDER BY ${sortColumn} DESC, id DESC
       LIMIT $${params.length}`,
      params
    ));
  } catch (err) {
    res.status(500).json({
      error: { code: 'THREADS_FETCH_FAILED', message: (err as Error).message },
    });
    return;
  }

  const hasMore = rows.length > limit;
  const items = rows.slice(0, limit).map(t => ({
    id: t.id,
    title: t.title,
    excerpt: generateExcerpt(t.body),
    authorPseudonym: t.author_display_name,
    replyCount: t.reply_count,
    createdAt: t.created_at,
    lastActivityAt: t.last_activity_at,
  }));

  const nextCursor = hasMore && items.length > 0
    ? encodeCursor(
        items[items.length - 1][sort === 'newest' ? 'createdAt' : 'lastActivityAt'],
        items[items.length - 1].id
      )
    : null;

  res.json({
    data: items,
    meta: { cursor: nextCursor, hasMore },
  });
});

// PATCH /api/threads/:id — edit thread title and/or body (ownership-checked, no rate limit)
threadsRouter.patch('/threads/:id', ...requireAuth, requireConnected, async (req: Request, res: Response) => {
  const user = (req as FcRequest).user!;
  const { title, body } = req.body as { title?: unknown; body?: unknown };

  // At least one field must be provided
  if (title === undefined && body === undefined) {
    res.status(422).json({ errors: { _: 'At least one of title or body is required' } });
    return;
  }

  const errors: Record<string, string> = {};
  let trimmedTitle = '';
  let trimmedBody = '';

  if (title !== undefined) {
    trimmedTitle = (typeof title === 'string' ? title : '').trim();
    if (trimmedTitle.length < 5 || trimmedTitle.length > 150) {
      errors.title = 'Title must be 5-150 characters';
    }
  }

  if (body !== undefined) {
    trimmedBody = (typeof body === 'string' ? body : '').trim();
    if (trimmedBody.length < 10 || trimmedBody.length > 5000) {
      errors.body = 'Body must be 10-5,000 characters';
    }
  }

  if (Object.keys(errors).length > 0) {
    res.status(422).json({ errors });
    return;
  }

  // Ownership check — the role bypasses RLS, so we check manually.
  // Return 404 (not 403) for non-author — hides existence of content.
  let existing: { author_id: string; moderation_status: string } | null = null;
  try {
    const { rows } = await pool.query(
      'SELECT author_id, moderation_status FROM connect.threads WHERE id = $1',
      [req.params.id]
    );
    existing = rows.length === 1 ? rows[0] : null;
  } catch {
    // a malformed id throws (22P02): treated as not found, as before
  }

  if (!existing || existing.author_id !== user.id || existing.moderation_status !== 'visible') {
    res.status(404).json({ error: { code: 'THREAD_NOT_FOUND', message: 'Thread not found' } });
    return;
  }

  // Partial update — only the fields that were provided. Column names are fixed literals.
  const sets: string[] = [];
  const params: unknown[] = [];
  if (title !== undefined) { params.push(trimmedTitle); sets.push(`title = $${params.length}`); }
  if (body !== undefined) { params.push(trimmedBody); sets.push(`body = $${params.length}`); }
  params.push(new Date().toISOString());
  sets.push(`updated_at = $${params.length}`);
  params.push(req.params.id);

  // DB trigger trg_log_thread_edit fires AFTER UPDATE when title or body actually changed
  let data: ThreadRow | null = null;
  let updateError: string | undefined;
  try {
    const { rows } = await pool.query<ThreadRow>(
      `UPDATE connect.threads SET ${sets.join(', ')} WHERE id = $${params.length}
       RETURNING ${THREAD_DETAIL_COLUMNS}`,
      params
    );
    data = rows.length === 1 ? rows[0] : null;
  } catch (err) {
    updateError = (err as Error).message;
  }

  if (!data) {
    res.status(500).json({ error: { code: 'THREAD_UPDATE_FAILED', message: updateError } });
    return;
  }

  // Invalidate thread detail cache
  await cacheDel(`fc:/threads/${req.params.id}:${JSON.stringify({})}`);

  res.status(200).json({ data: toThread(data) });
});

// DELETE /api/threads/:id — not allowed (Memory over Moderation principle)
threadsRouter.delete('/threads/:id', (_req, res) => {
  res.setHeader('Allow', 'GET, PATCH');
  res.status(405).json({ error: { code: 'DELETE_NOT_ALLOWED', message: 'Threads cannot be deleted' } });
});

// GET /api/threads/:id/edits — public edit history (Memory over Moderation — no auth required)
threadsRouter.get('/threads/:id/edits', async (req: Request, res: Response) => {
  // Verify thread exists and is visible
  let visible = false;
  try {
    const { rows } = await pool.query(
      'SELECT moderation_status FROM connect.threads WHERE id = $1',
      [req.params.id]
    );
    visible = rows.length === 1 && rows[0].moderation_status === 'visible';
  } catch {
    // a malformed id throws (22P02): treated as not found, as before
  }

  if (!visible) {
    res.status(404).json({ error: { code: 'THREAD_NOT_FOUND', message: 'Thread not found' } });
    return;
  }

  let rows: Array<{ id: string; old_title: string | null; old_body: string | null; edited_at: string }>;
  try {
    ({ rows } = await pool.query(
      `SELECT id, old_title, old_body, ${ts('edited_at')} FROM connect.thread_edits
       WHERE thread_id = $1 ORDER BY edited_at DESC`,
      [req.params.id]
    ));
  } catch (err) {
    res.status(500).json({ error: { code: 'EDITS_FETCH_FAILED', message: (err as Error).message } });
    return;
  }

  res.json({
    data: rows.map(e => ({
      id: e.id,
      oldTitle: e.old_title,
      oldBody: e.old_body,
      editedAt: e.edited_at,
    })),
  });
});

// POST /api/communities/:id/threads — create a new thread
// Requires: connected or empowered account with active standing
// Rate limited: shared 5-post/hour bucket per user
threadsRouter.post(
  '/communities/:id/threads',
  ...requireAuth,
  requireConnected,
  async (req: Request, res: Response) => {
    const user = (req as FcRequest).user!;
    const { title, body } = req.body as { title?: unknown; body?: unknown };
    const errors: Record<string, string> = {};

    const trimmedTitle = (typeof title === 'string' ? title : '').trim();
    if (trimmedTitle.length < 5 || trimmedTitle.length > 150) {
      errors.title = 'Title must be 5-150 characters';
    }

    const trimmedBody = (typeof body === 'string' ? body : '').trim();
    if (trimmedBody.length < 10 || trimmedBody.length > 5000) {
      errors.body = 'Body must be 10-5,000 characters';
    }

    if (Object.keys(errors).length > 0) {
      res.status(422).json({ errors });
      return;
    }

    // Rate limiting — shared bucket with reply posting
    const { success, reset } = await postRateLimiter.limit(user.id);
    if (!success) {
      // reset is in milliseconds; Retry-After is in seconds
      res.set('Retry-After', String(Math.ceil((reset - Date.now()) / 1000)));
      res.status(429).json({ reason: 'rate_limited' });
      return;
    }

    // Insert thread — trg_threads_snapshot_display_name fires BEFORE INSERT
    // and populates author_display_name automatically from connected_profiles
    let data: ThreadRow | null = null;
    let insertError: string | undefined;
    try {
      const { rows } = await pool.query<ThreadRow>(
        `INSERT INTO connect.threads (community_id, author_id, title, body)
         VALUES ($1, $2, $3, $4)
         RETURNING ${THREAD_DETAIL_COLUMNS}`,
        [req.params.id, user.id, trimmedTitle, trimmedBody]
      );
      data = rows[0] ?? null;
    } catch (err) {
      insertError = (err as Error).message;
    }

    if (!data) {
      res.status(500).json({
        error: { code: 'THREAD_CREATE_FAILED', message: insertError },
      });
      return;
    }

    // Invalidate thread list cache for this community (default query params)
    await cacheDel(`fc:/communities/${req.params.id}/threads:${JSON.stringify({})}`);

    res.status(201).json({ data: { ...toThread(data), isEdited: false } });
  }
);
