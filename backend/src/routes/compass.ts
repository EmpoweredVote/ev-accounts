import { Router } from 'express';
import { z } from 'zod';
import { pool } from '../lib/db.js';
import { requireAuth, optionalAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { createUserClient } from '../lib/supabase.js';
import { promoteCompassImportDraft, getCompassCompleteness } from '../lib/compassService.js';
import type { Request, Response } from 'express';

/**
 * Compass routes (read + write).
 *
 * Architecture rules enforced here:
 *   - Service-role client is NOT used — architecture.test.ts bans it from routes/
 *   - Public reference data (topics, categories, politicians): pg pool only
 *   - Owner-read routes (answers, selected-topics): createUserClient (RLS enforced)
 *   - Server-side computations (progress): compassService via pg pool
 *   - Write routes (POST /answers, PUT /selected-topics): pg pool with transactions
 *
 * Route ordering: specific paths before parameterized paths to prevent
 * Express routing conflicts (e.g., /politicians before /politicians/:id).
 */

const router = Router();

// ---------------------------------------------------------------------------
// Validation schemas
// ---------------------------------------------------------------------------

const batchAnswersSchema = z.object({
  ids: z.array(z.string().uuid()).min(1).max(100),
});

const postAnswerSchema = z.object({
  topic_id: z.string().uuid(),
  value: z.number().int().min(1).max(5),
  write_in_text: z.string().max(500).optional(),
  inverted: z.boolean().optional().default(false),
});

const putSelectedTopicsSchema = z.object({
  topic_ids: z.array(z.string().uuid()).min(0).max(50),
});

const VALID_ROLE_SCOPES = ['city_council', 'state_legislature', 'us_congress', 'president'] as const;

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// ---------------------------------------------------------------------------
// GET /api/compass/topics
// Auth: optional — works unauthenticated
// Returns all live topics with nested stances, categories, and role scopes.
// Uses pg pool for all reads — public reference data, no RLS sensitivity.
// ---------------------------------------------------------------------------

router.get('/topics', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const { rows: topics } = await pool.query<{
      id: string;
      title: string;
      short_title: string | null;
      question_text: string;
      is_live: boolean;
      version: number;
    }>(
      'SELECT id, title, short_title, question_text, is_live, version FROM inform.compass_topics WHERE is_live = true ORDER BY created_at ASC'
    );

    if (topics.length === 0) {
      res.status(200).json([]);
      return;
    }

    const topicIds = topics.map(t => t.id);

    // Fetch stances for all topics in one query
    const { rows: stances } = await pool.query<{
      topic_id: string;
      id: string;
      value: number;
      text: string;
    }>(
      'SELECT topic_id, id, value, text FROM inform.compass_stances WHERE topic_id = ANY($1::uuid[]) ORDER BY value ASC',
      [topicIds]
    );

    // Fetch categories for all topics in one query
    const { rows: topicCategories } = await pool.query<{
      topic_id: string;
      category_id: string;
      title: string;
    }>(
      `SELECT tc.topic_id, c.id AS category_id, c.title
       FROM inform.compass_topic_categories tc
       JOIN inform.compass_categories c ON c.id = tc.category_id
       WHERE tc.topic_id = ANY($1::uuid[])`,
      [topicIds]
    );

    // Fetch role scopes for all topics in one query
    const { rows: topicRoles } = await pool.query<{
      topic_id: string;
      role_scope: string;
      is_required: boolean;
    }>(
      'SELECT topic_id, role_scope, is_required FROM inform.compass_topic_roles WHERE topic_id = ANY($1::uuid[])',
      [topicIds]
    );

    // Assemble nested response — strip topic_id from nested objects
    const result = topics.map(topic => ({
      ...topic,
      stances: stances
        .filter(s => s.topic_id === topic.id)
        .map(({ topic_id: _tid, ...s }) => s),
      categories: topicCategories
        .filter(c => c.topic_id === topic.id)
        .map(({ topic_id: _tid, ...c }) => c),
      roles: topicRoles
        .filter(r => r.topic_id === topic.id)
        .map(({ topic_id: _tid, ...r }) => r),
    }));

    res.status(200).json(result);
  } catch (err) {
    console.error('[GET /compass/topics] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/compass/categories
// Auth: optional — works unauthenticated
// Returns all categories with their nested live topics.
// Uses pg pool — public reference data.
// ---------------------------------------------------------------------------

router.get('/categories', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const { rows: categories } = await pool.query<{
      id: string;
      title: string;
    }>('SELECT id, title FROM inform.compass_categories ORDER BY title ASC');

    const { rows: topicCats } = await pool.query<{
      category_id: string;
      topic_id: string;
      title: string;
      short_title: string | null;
      question_text: string;
    }>(
      `SELECT tc.category_id, t.id AS topic_id, t.title, t.short_title, t.question_text
       FROM inform.compass_topic_categories tc
       JOIN inform.compass_topics t ON t.id = tc.topic_id
       WHERE t.is_live = true
       ORDER BY t.title ASC`
    );

    const result = categories.map(cat => ({
      ...cat,
      topics: topicCats
        .filter(tc => tc.category_id === cat.id)
        .map(({ category_id: _cid, ...t }) => t),
    }));

    res.status(200).json(result);
  } catch (err) {
    console.error('[GET /compass/categories] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/compass/answers
// Auth: required
// Returns user's own compass responses including the inverted field.
// Triggers lazy promotion of compass_import_draft on first call (non-fatal).
// Uses createUserClient — RLS enforces owner-only access to compass_responses.
// ---------------------------------------------------------------------------

router.get('/answers', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const authReq = req as AuthenticatedRequest;

  try {
    // Lazy promotion — non-fatal if it fails (draft preserved for retry)
    await promoteCompassImportDraft(authReq.userId);

    const db = createUserClient(authReq.accessToken);
    const { data, error } = await db
      .schema('inform')
      .from('compass_responses')
      .select('topic_id, value, write_in_text, visibility, inverted, created_at, updated_at');

    if (error) {
      console.error('[GET /compass/answers] Supabase error:', error);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
      return;
    }

    res.status(200).json(data ?? []);
  } catch (err) {
    console.error('[GET /compass/answers] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/compass/answers/batch
// Auth: required
// Returns answers for a specific list of topic IDs.
// Body: { ids: string[] } — array of topic UUID strings (1-100 items).
// Uses createUserClient — RLS enforces owner-only access.
// ---------------------------------------------------------------------------

router.post('/answers/batch', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const authReq = req as AuthenticatedRequest;

  const parsed = batchAnswersSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: parsed.error.issues[0]?.message ?? 'Invalid request body',
    });
    return;
  }

  try {
    const db = createUserClient(authReq.accessToken);
    const { data, error } = await db
      .schema('inform')
      .from('compass_responses')
      .select('topic_id, value, write_in_text')
      .in('topic_id', parsed.data.ids);

    if (error) {
      console.error('[POST /compass/answers/batch] Supabase error:', error);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
      return;
    }

    res.status(200).json(data ?? []);
  } catch (err) {
    console.error('[POST /compass/answers/batch] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/compass/selected-topics
// Auth: required
// Returns the user's saved topic IDs from connect.connected_profiles.
// Uses createUserClient — RLS enforces owner-only access to connected_profiles.
// Returns 403 NOT_CONNECTED if the user has not completed the Connect flow.
// ---------------------------------------------------------------------------

router.get(
  '/selected-topics',
  requireAuth,
  async (req: Request, res: Response): Promise<void> => {
    const authReq = req as AuthenticatedRequest;

    try {
      const db = createUserClient(authReq.accessToken);
      const { data, error } = await db
        .schema('connect')
        .from('connected_profiles')
        .select('selected_topic_ids')
        .eq('user_id', authReq.userId)
        .maybeSingle();

      if (error) {
        console.error('[GET /compass/selected-topics] Supabase error:', error);
        res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
        return;
      }

      if (!data) {
        res.status(403).json({
          code: 'NOT_CONNECTED',
          message: 'Complete the Connect flow to use selected topics',
        });
        return;
      }

      res.status(200).json({ topic_ids: data.selected_topic_ids ?? [] });
    } catch (err) {
      console.error('[GET /compass/selected-topics] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// ---------------------------------------------------------------------------
// GET /api/compass/progress
// Auth: required
// Returns calibration completeness score.
// Optional query param: ?role= (city_council|state_legislature|us_congress|president)
// When role is provided, only counts topics required for that role scope.
// When role is absent, counts all live topics.
// ---------------------------------------------------------------------------

router.get('/progress', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const authReq = req as AuthenticatedRequest;

  try {
    const roleParam = typeof req.query.role === 'string' ? req.query.role : undefined;

    if (roleParam !== undefined && !(VALID_ROLE_SCOPES as readonly string[]).includes(roleParam)) {
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: `Invalid role. Must be one of: ${VALID_ROLE_SCOPES.join(', ')}`,
      });
      return;
    }

    const progress = await getCompassCompleteness(authReq.userId, roleParam);
    res.status(200).json(progress);
  } catch (err) {
    console.error('[GET /compass/progress] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/compass/politicians
// Auth: optional — works unauthenticated
// Returns all active politicians ordered by name.
// Uses pg pool — public reference data.
// ---------------------------------------------------------------------------

router.get('/politicians', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const { rows } = await pool.query<{
      id: string;
      first_name: string;
      last_name: string;
      preferred_name: string | null;
      full_name: string | null;
      office_title: string | null;
      photo_origin_url: string | null;
      is_active: boolean;
    }>(
      `SELECT id, first_name, last_name, preferred_name, full_name, office_title,
              photo_origin_url, is_active
       FROM inform.politicians
       WHERE is_active = true
       ORDER BY last_name ASC, first_name ASC`
    );

    res.status(200).json(rows);
  } catch (err) {
    console.error('[GET /compass/politicians] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/compass/politicians/:id/answers
// Auth: optional — works unauthenticated
// Returns a politician's stances on all topics they have answered.
// Validates UUID format; returns empty array if politician has no answers.
// Uses pg pool — public reference data.
// ---------------------------------------------------------------------------

router.get(
  '/politicians/:id/answers',
  optionalAuth,
  async (req: Request, res: Response): Promise<void> => {
    try {
      const politicianId = req.params.id as string;

      if (!UUID_REGEX.test(politicianId)) {
        res
          .status(422)
          .json({ code: 'VALIDATION_ERROR', message: 'Invalid politician ID format' });
        return;
      }

      const { rows } = await pool.query<{
        topic_id: string;
        value: number;
      }>(
        'SELECT topic_id, value FROM inform.politician_answers WHERE politician_id = $1 ORDER BY topic_id ASC',
        [politicianId]
      );

      res.status(200).json(rows);
    } catch (err) {
      console.error('[GET /compass/politicians/:id/answers] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// ---------------------------------------------------------------------------
// GET /api/compass/politicians/:id/:topicId/context
// Auth: optional — works unauthenticated
// Returns reasoning and sources for a politician's stance on a topic.
// Returns 404 if no context record exists (context is optional, answers are not).
// Uses pg pool — public reference data.
// ---------------------------------------------------------------------------

router.get(
  '/politicians/:id/:topicId/context',
  optionalAuth,
  async (req: Request, res: Response): Promise<void> => {
    try {
      const politicianId = req.params.id as string;
      const topicId = req.params.topicId as string;

      if (!UUID_REGEX.test(politicianId) || !UUID_REGEX.test(topicId)) {
        res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid ID format' });
        return;
      }

      const { rows } = await pool.query<{
        reasoning: string;
        sources: string[];
      }>(
        'SELECT reasoning, sources FROM inform.politician_context WHERE politician_id = $1 AND topic_id = $2',
        [politicianId, topicId]
      );

      if (rows.length === 0) {
        res.status(404).json({
          code: 'NOT_FOUND',
          message: 'No context found for this politician and topic',
        });
        return;
      }

      res.status(200).json(rows[0]);
    } catch (err) {
      console.error('[GET /compass/politicians/:id/:topicId/context] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// ---------------------------------------------------------------------------
// POST /api/compass/answers
// Auth: required
// Upserts a single compass response and atomically appends to change_history.
// Entire operation runs in a single pg BEGIN/COMMIT transaction.
// change_history record is ALWAYS inserted — even first calibration (old_value=NULL)
// and same-value recalibration. It is a full audit log.
// Uses pg pool directly — compass_responses/change_history have no RLS write
// policies; all writes go via pg pool or SECURITY DEFINER functions.
// ---------------------------------------------------------------------------

router.post('/answers', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const authReq = req as AuthenticatedRequest;

  const parsed = postAnswerSchema.safeParse(req.body);
  if (!parsed.success) {
    const firstIssue = parsed.error.issues[0];
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: firstIssue?.message ?? 'Invalid request body',
    });
    return;
  }

  const { topic_id, value, write_in_text, inverted } = parsed.data;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Step 1: Validate topic exists and is live before writing
    const { rows: topicRows } = await client.query<{ id: string }>(
      'SELECT id FROM inform.compass_topics WHERE id = $1 AND is_live = true',
      [topic_id]
    );
    if (topicRows.length === 0) {
      await client.query('ROLLBACK');
      res.status(404).json({ code: 'TOPIC_NOT_FOUND', message: 'Topic not found or not live' });
      return;
    }

    // Step 2: Read existing response BEFORE UPSERT to capture old_value for audit
    const { rows: existing } = await client.query<{ value: number }>(
      'SELECT value FROM inform.compass_responses WHERE user_id = $1 AND topic_id = $2',
      [authReq.userId, topic_id]
    );
    const oldValue = existing[0]?.value ?? null;

    // Step 3: UPSERT the response — updates value, write_in_text, inverted, updated_at
    const { rows: upserted } = await client.query<{
      topic_id: string;
      value: number;
      write_in_text: string | null;
      inverted: boolean;
      visibility: string;
      created_at: string;
      updated_at: string;
    }>(
      `INSERT INTO inform.compass_responses (user_id, topic_id, value, write_in_text, inverted, updated_at)
       VALUES ($1, $2, $3, $4, $5, now())
       ON CONFLICT (user_id, topic_id) DO UPDATE
         SET value         = EXCLUDED.value,
             write_in_text = EXCLUDED.write_in_text,
             inverted      = EXCLUDED.inverted,
             updated_at    = now()
       RETURNING topic_id, value, write_in_text, inverted, visibility, created_at, updated_at`,
      [authReq.userId, topic_id, value, write_in_text ?? null, inverted]
    );

    // Step 4: Append to change_history (ALWAYS — even first calibration and same-value re-calibration)
    await client.query(
      `INSERT INTO inform.compass_change_history (user_id, topic_id, old_value, new_value)
       VALUES ($1, $2, $3, $4)`,
      [authReq.userId, topic_id, oldValue, value]
    );

    await client.query('COMMIT');

    res.status(200).json(upserted[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('[POST /compass/answers] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  } finally {
    client.release();
  }
});

// ---------------------------------------------------------------------------
// PUT /api/compass/selected-topics
// Auth: required
// Saves the user's selected topic IDs after server-side validation.
// Validates ALL submitted IDs exist and are live before storing.
// Returns 403 NOT_CONNECTED if the user has no connected_profiles row.
// Uses pg pool — single UPDATE, no transaction needed.
// ---------------------------------------------------------------------------

router.put(
  '/selected-topics',
  requireAuth,
  async (req: Request, res: Response): Promise<void> => {
    const authReq = req as AuthenticatedRequest;

    const parsed = putSelectedTopicsSchema.safeParse(req.body);
    if (!parsed.success) {
      const firstIssue = parsed.error.issues[0];
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: firstIssue?.message ?? 'Invalid request body',
      });
      return;
    }

    const { topic_ids } = parsed.data;

    try {
      // Validate all submitted topic IDs exist and are live
      if (topic_ids.length > 0) {
        const { rows: validTopics } = await pool.query<{ id: string }>(
          'SELECT id FROM inform.compass_topics WHERE id = ANY($1::uuid[]) AND is_live = true',
          [topic_ids]
        );

        const validIds = new Set(validTopics.map(t => t.id));
        const invalidIds = topic_ids.filter(id => !validIds.has(id));

        if (invalidIds.length > 0) {
          res.status(422).json({
            code: 'INVALID_TOPIC_IDS',
            message: `The following topic IDs are invalid or not live: ${invalidIds.join(', ')}`,
            invalid_ids: invalidIds,
          });
          return;
        }
      }

      // Store validated IDs in connected_profiles.selected_topic_ids
      const { rowCount } = await pool.query(
        `UPDATE connect.connected_profiles
            SET selected_topic_ids = $1, updated_at = now()
          WHERE user_id = $2`,
        [JSON.stringify(topic_ids), authReq.userId]
      );

      if (rowCount === 0) {
        res
          .status(403)
          .json({ code: 'NOT_CONNECTED', message: 'Complete the Connect flow first' });
        return;
      }

      res.status(200).json({ topic_ids });
    } catch (err) {
      console.error('[PUT /compass/selected-topics] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

export default router;
