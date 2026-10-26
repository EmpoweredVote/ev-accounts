import { Router } from 'express';
import type { Request, Response } from 'express';
import { pool } from '../config/database.js';
import { ts } from '../lib/sql.js';
import { cacheMiddleware, cacheDel, TTL } from '../middleware/cache.js';
import { parseLimit } from '../lib/utils.js';
import { requireAuth, type FcRequest } from '../middleware/auth.js';
import { requireConnected } from '../middleware/tierGuards.js';
import { postRateLimiter } from '../lib/rateLimit.js';

export const postsRouter = Router();

const POST_COLUMNS = `id, body, author_display_name, ${ts('created_at')}, ${ts('updated_at')}`;

interface PostRow {
  id: string;
  body: string;
  author_display_name: string;
  created_at: string;
  updated_at: string;
}

/** Visibility of one thread: 'visible' | other status | null (missing or malformed id). */
async function threadStatus(threadId: string): Promise<{ moderation_status: string } | null> {
  try {
    const { rows } = await pool.query(
      'SELECT moderation_status FROM connect.threads WHERE id = $1',
      [threadId]
    );
    return rows.length === 1 ? rows[0] : null;
  } catch {
    return null;
  }
}

// GET /api/threads/:id — thread detail with full body
postsRouter.get('/threads/:id', cacheMiddleware(TTL.THREAD_DETAIL), async (req: Request, res: Response) => {
  let data: {
    id: string; title: string; body: string; author_display_name: string; reply_count: number;
    created_at: string; last_activity_at: string; updated_at: string; moderation_status: string;
  } | null = null;
  try {
    const { rows } = await pool.query(
      `SELECT id, title, body, author_display_name, reply_count, ${ts('created_at')},
              ${ts('last_activity_at')}, ${ts('updated_at')}, moderation_status
       FROM connect.threads WHERE id = $1`,
      [req.params.id]
    );
    data = rows.length === 1 ? rows[0] : null;
  } catch {
    // a malformed id throws (22P02): treated as not found, as before
  }

  // Missing and hidden threads both return 404 — do not reveal existence
  if (!data || data.moderation_status !== 'visible') {
    res.status(404).json({
      error: { code: 'THREAD_NOT_FOUND', message: 'Thread not found' },
    });
    return;
  }

  res.json({
    data: {
      id: data.id,
      title: data.title,
      body: data.body,  // full markdown, NOT an excerpt
      authorPseudonym: data.author_display_name,
      replyCount: data.reply_count,
      createdAt: data.created_at,
      lastActivityAt: data.last_activity_at,
      updatedAt: data.updated_at,
      isEdited: data.updated_at !== data.created_at,
      // moderation_status intentionally excluded from response
    },
  });
});

// GET /api/threads/:id/posts — flat chronological reply list
postsRouter.get('/threads/:id/posts', cacheMiddleware(TTL.THREAD_DETAIL), async (req: Request, res: Response) => {
  const threadId = req.params.id as string;
  const limit = parseLimit(req.query.limit as string | undefined, 50);

  // Verify thread exists and is visible
  const thread = await threadStatus(threadId);
  if (!thread || thread.moderation_status !== 'visible') {
    res.status(404).json({
      error: { code: 'THREAD_NOT_FOUND', message: 'Thread not found' },
    });
    return;
  }

  let rows: PostRow[];
  try {
    ({ rows } = await pool.query<PostRow>(
      `SELECT id, author_display_name, body, ${ts('created_at')}, ${ts('updated_at')}
       FROM connect.posts
       WHERE thread_id = $1 AND moderation_status = 'visible'
       ORDER BY created_at ASC
       LIMIT $2`,
      [threadId, limit]
    ));
  } catch (err) {
    res.status(500).json({
      error: { code: 'POSTS_FETCH_FAILED', message: (err as Error).message },
    });
    return;
  }

  const posts = rows.map(p => ({
    id: p.id,
    authorPseudonym: p.author_display_name,
    body: p.body,
    createdAt: p.created_at,
    updatedAt: p.updated_at,
    isEdited: p.updated_at !== p.created_at,
  }));

  // No cursor/meta for posts — flat list with limit (v1)
  res.json({ data: posts });
});

// PATCH /api/posts/:id — edit a post body (ownership-checked, no rate limit)
postsRouter.patch('/posts/:id', ...requireAuth, requireConnected, async (req: Request, res: Response) => {
  const user = (req as FcRequest).user!;
  const { body } = req.body as { body?: unknown };

  if (body === undefined) {
    res.status(422).json({ errors: { body: 'Body is required' } });
    return;
  }

  const trimmedBody = (typeof body === 'string' ? body : '').trim();
  if (trimmedBody.length < 5 || trimmedBody.length > 5000) {
    res.status(422).json({ errors: { body: 'Body must be 5-5,000 characters' } });
    return;
  }

  // Ownership check — return 404 for non-author to hide existence
  let existing: { author_id: string; thread_id: string; moderation_status: string } | null = null;
  try {
    const { rows } = await pool.query(
      'SELECT author_id, thread_id, moderation_status FROM connect.posts WHERE id = $1',
      [req.params.id]
    );
    existing = rows.length === 1 ? rows[0] : null;
  } catch {
    // a malformed id throws (22P02): treated as not found, as before
  }

  if (!existing || existing.author_id !== user.id || existing.moderation_status !== 'visible') {
    res.status(404).json({ error: { code: 'POST_NOT_FOUND', message: 'Post not found' } });
    return;
  }

  // DB trigger trg_log_post_edit fires AFTER UPDATE when body actually changed
  let data: PostRow | null = null;
  let updateError: string | undefined;
  try {
    const { rows } = await pool.query<PostRow>(
      `UPDATE connect.posts SET body = $1, updated_at = $2 WHERE id = $3 RETURNING ${POST_COLUMNS}`,
      [trimmedBody, new Date().toISOString(), req.params.id]
    );
    data = rows.length === 1 ? rows[0] : null;
  } catch (err) {
    updateError = (err as Error).message;
  }

  if (!data) {
    res.status(500).json({ error: { code: 'POST_UPDATE_FAILED', message: updateError } });
    return;
  }

  // Invalidate the thread's posts list cache
  await cacheDel(`fc:/threads/${existing.thread_id}/posts:${JSON.stringify({})}`);

  res.status(200).json({
    data: {
      id: data.id,
      body: data.body,
      authorPseudonym: data.author_display_name,
      createdAt: data.created_at,
      updatedAt: data.updated_at,
      isEdited: data.updated_at !== data.created_at,
    },
  });
});

// DELETE /api/posts/:id — not allowed (Memory over Moderation principle)
postsRouter.delete('/posts/:id', (_req, res) => {
  res.setHeader('Allow', 'GET, PATCH');
  res.status(405).json({ error: { code: 'DELETE_NOT_ALLOWED', message: 'Posts cannot be deleted' } });
});

// GET /api/posts/:id/edits — public edit history (Memory over Moderation — no auth required)
postsRouter.get('/posts/:id/edits', async (req: Request, res: Response) => {
  // Verify post exists and is visible
  let visible = false;
  try {
    const { rows } = await pool.query(
      'SELECT moderation_status FROM connect.posts WHERE id = $1',
      [req.params.id]
    );
    visible = rows.length === 1 && rows[0].moderation_status === 'visible';
  } catch {
    // a malformed id throws (22P02): treated as not found, as before
  }

  if (!visible) {
    res.status(404).json({ error: { code: 'POST_NOT_FOUND', message: 'Post not found' } });
    return;
  }

  let rows: Array<{ id: string; old_body: string | null; edited_at: string }>;
  try {
    ({ rows } = await pool.query(
      `SELECT id, old_body, ${ts('edited_at')} FROM connect.post_edits
       WHERE post_id = $1 ORDER BY edited_at DESC`,
      [req.params.id]
    ));
  } catch (err) {
    res.status(500).json({ error: { code: 'EDITS_FETCH_FAILED', message: (err as Error).message } });
    return;
  }

  res.json({
    data: rows.map(e => ({
      id: e.id,
      oldBody: e.old_body,
      editedAt: e.edited_at,
    })),
  });
});

// POST /api/threads/:id/posts — reply to a thread
// Requires: connected or empowered account with active standing
// Rate limited: shared 5-post/hour bucket per user (same as thread creation)
postsRouter.post(
  '/threads/:id/posts',
  ...requireAuth,
  requireConnected,
  async (req: Request, res: Response) => {
    const user = (req as FcRequest).user!;
    const threadId = req.params.id as string;

    // Verify thread exists and is visible before doing anything else
    const thread = await threadStatus(threadId);
    if (!thread || thread.moderation_status !== 'visible') {
      res.status(404).json({
        error: { code: 'THREAD_NOT_FOUND', message: 'Thread not found' },
      });
      return;
    }

    // Validation
    const { body } = req.body as { body?: unknown };
    const errors: Record<string, string> = {};

    const trimmedBody = (typeof body === 'string' ? body : '').trim();
    if (trimmedBody.length < 5 || trimmedBody.length > 5000) {
      errors.body = 'Body must be 5-5,000 characters';
    }

    if (Object.keys(errors).length > 0) {
      res.status(422).json({ errors });
      return;
    }

    // Rate limiting — shared bucket with thread creation
    const { success, reset } = await postRateLimiter.limit(user.id);
    if (!success) {
      // reset is in milliseconds; Retry-After is in seconds
      res.set('Retry-After', String(Math.ceil((reset - Date.now()) / 1000)));
      res.status(429).json({ reason: 'rate_limited' });
      return;
    }

    // Insert post — trg_posts_snapshot_display_name fires BEFORE INSERT
    // and populates author_display_name automatically from connected_profiles
    let data: PostRow | null = null;
    let insertError: string | undefined;
    try {
      const { rows } = await pool.query<PostRow>(
        `INSERT INTO connect.posts (thread_id, author_id, body) VALUES ($1, $2, $3)
         RETURNING ${POST_COLUMNS}`,
        [threadId, user.id, trimmedBody]
      );
      data = rows[0] ?? null;
    } catch (err) {
      insertError = (err as Error).message;
    }

    if (!data) {
      res.status(500).json({
        error: { code: 'POST_CREATE_FAILED', message: insertError },
      });
      return;
    }

    // Bump the thread's reply_count and last_activity_at. The standalone read the count
    // first and wrote count + 1, which loses a reply when two land at once; the increment
    // is now done in the UPDATE itself. Same result otherwise. Errors are ignored, as before.
    await pool
      .query(
        'UPDATE connect.threads SET reply_count = reply_count + 1, last_activity_at = $1 WHERE id = $2',
        [new Date().toISOString(), threadId]
      )
      .catch((err: Error) => console.warn('[focused_communities] reply_count bump failed:', err.message));

    // Invalidate thread detail and posts list cache entries
    await cacheDel(
      `fc:/threads/${threadId}:${JSON.stringify({})}`,
      `fc:/threads/${threadId}/posts:${JSON.stringify({})}`,
    );

    res.status(201).json({
      data: {
        id: data.id,
        body: data.body,
        authorPseudonym: data.author_display_name,
        createdAt: data.created_at,
        updatedAt: data.updated_at,
        isEdited: false,
      },
    });
  }
);
