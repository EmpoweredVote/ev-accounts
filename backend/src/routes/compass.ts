import { Router } from 'express';
import { z } from 'zod';
import { supabaseAdmin, adminRpc } from '../lib/supabase.js';
import { requireAuth, optionalAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { createUserClient } from '../lib/supabase.js';
import { promoteCompassImportDraft, getCompassCompleteness } from '../lib/compassService.js';
import type { Request, Response } from 'express';

/**
 * Compass routes (read + write).
 *
 * Architecture rules enforced here:
 *   - Service-role client is NOT used directly — architecture.test.ts bans it from routes/
 *   - All supabaseAdmin usage goes through lib/ service functions
 *   - Public reference data (topics, categories, politicians): supabaseAdmin via direct query
 *   - Owner-read routes (answers, selected-topics): createUserClient (RLS enforced)
 *   - Server-side computations (progress): compassService via RPC
 *   - Write routes (POST /answers, PUT /selected-topics): supabaseAdmin RPC
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
// Uses supabaseAdmin for all reads — public reference data, no RLS sensitivity.
// ---------------------------------------------------------------------------

router.get('/topics', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const { data: topics, error: topicsError } = await supabaseAdmin
      .schema('inform')
      .from('compass_topics')
      .select('id,title,short_title,question_text,is_live,version')
      .eq('is_live', true)
      .order('created_at', { ascending: true });

    if (topicsError) throw topicsError;

    if (!topics || topics.length === 0) {
      res.status(200).json([]);
      return;
    }

    const topicIds = topics.map(t => t.id);

    // Fetch stances for all topics in one query
    const { data: stances, error: stancesError } = await supabaseAdmin
      .schema('inform')
      .from('compass_stances')
      .select('topic_id,id,value,text')
      .in('topic_id', topicIds)
      .order('value', { ascending: true });

    if (stancesError) throw stancesError;

    // Fetch categories for all topics in one query
    const { data: topicCategories, error: catsError } = await supabaseAdmin
      .schema('inform')
      .from('compass_topic_categories')
      .select('topic_id,compass_categories(id,title)')
      .in('topic_id', topicIds);

    if (catsError) throw catsError;

    // Fetch role scopes for all topics in one query
    const { data: topicRoles, error: rolesError } = await supabaseAdmin
      .schema('inform')
      .from('compass_topic_roles')
      .select('topic_id,role_scope,is_required')
      .in('topic_id', topicIds);

    if (rolesError) throw rolesError;

    // Assemble nested response
    const result = topics.map(topic => ({
      ...topic,
      stances: (stances ?? [])
        .filter(s => s.topic_id === topic.id)
        .map(({ topic_id: _tid, ...s }) => s),
      categories: (topicCategories ?? [])
        .filter(c => c.topic_id === topic.id)
        .map(c => {
          const cat = c.compass_categories as { id: string; title: string } | null;
          return cat ? { category_id: cat.id, title: cat.title } : null;
        })
        .filter(Boolean),
      roles: (topicRoles ?? [])
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
// Uses supabaseAdmin — public reference data.
// ---------------------------------------------------------------------------

router.get('/categories', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const { data: categories, error: catError } = await supabaseAdmin
      .schema('inform')
      .from('compass_categories')
      .select('id,title')
      .order('title', { ascending: true });

    if (catError) throw catError;

    const { data: topicCats, error: topicCatError } = await supabaseAdmin
      .schema('inform')
      .from('compass_topic_categories')
      .select('category_id,compass_topics!inner(id,title,short_title,question_text,is_live)')
      .eq('compass_topics.is_live', true)
      .order('compass_topics.title', { ascending: true });

    if (topicCatError) throw topicCatError;

    const result = (categories ?? []).map(cat => ({
      ...cat,
      topics: (topicCats ?? [])
        .filter(tc => tc.category_id === cat.id)
        .map(tc => {
          const t = tc.compass_topics as { id: string; title: string; short_title: string | null; question_text: string; is_live: boolean } | null;
          if (!t) return null;
          return {
            topic_id: t.id,
            title: t.title,
            short_title: t.short_title,
            question_text: t.question_text,
          };
        })
        .filter(Boolean),
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
// Uses supabaseAdmin — public reference data.
// ---------------------------------------------------------------------------

router.get('/politicians', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const { data, error } = await supabaseAdmin
      .schema('inform')
      .from('politicians')
      .select('id,first_name,last_name,preferred_name,full_name,office_title,photo_origin_url,is_active')
      .eq('is_active', true)
      .order('last_name', { ascending: true })
      .order('first_name', { ascending: true });

    if (error) throw error;

    res.status(200).json(data ?? []);
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
// Uses supabaseAdmin — public reference data.
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

      const { data, error } = await supabaseAdmin
        .schema('inform')
        .from('politician_answers')
        .select('topic_id,value')
        .eq('politician_id', politicianId)
        .order('topic_id', { ascending: true });

      if (error) throw error;

      res.status(200).json(data ?? []);
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
// Uses supabaseAdmin — public reference data.
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

      const { data, error } = await supabaseAdmin
        .schema('inform')
        .from('politician_context')
        .select('reasoning,sources')
        .eq('politician_id', politicianId)
        .eq('topic_id', topicId)
        .maybeSingle();

      if (error) throw error;

      if (!data) {
        res.status(404).json({
          code: 'NOT_FOUND',
          message: 'No context found for this politician and topic',
        });
        return;
      }

      res.status(200).json(data);
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
// Entire operation runs in a SECURITY DEFINER RPC (upsert_compass_answer).
// change_history record is ALWAYS inserted — even first calibration (old_value=NULL)
// and same-value recalibration. It is a full audit log.
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

  try {
    const { data, error } = await adminRpc('upsert_compass_answer', {
      p_user_id: authReq.userId,
      p_topic_id: topic_id,
      p_value: value,
      p_write_in_text: write_in_text ?? null,
      p_inverted: inverted,
    });

    if (error) {
      if (error.message === 'TOPIC_NOT_FOUND') {
        res.status(404).json({ code: 'TOPIC_NOT_FOUND', message: 'Topic not found or not live' });
        return;
      }
      throw new Error(error.message);
    }

    res.status(200).json(data);
  } catch (err) {
    console.error('[POST /compass/answers] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// PUT /api/compass/selected-topics
// Auth: required
// Saves the user's selected topic IDs after server-side validation.
// Validates ALL submitted IDs exist and are live before storing.
// Returns 403 NOT_CONNECTED if the user has no connected_profiles row.
// Uses supabaseAdmin — single UPDATE.
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
        const { data: validTopics, error: validateError } = await supabaseAdmin
          .schema('inform')
          .from('compass_topics')
          .select('id')
          .in('id', topic_ids)
          .eq('is_live', true);

        if (validateError) throw validateError;

        const validIds = new Set((validTopics ?? []).map(t => t.id));
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
      const { data: updatedRows, error: updateError } = await supabaseAdmin
        .schema('connect')
        .from('connected_profiles')
        .update({
          selected_topic_ids: JSON.stringify(topic_ids),
          updated_at: new Date().toISOString(),
        })
        .eq('user_id', authReq.userId)
        .select('id');

      if (updateError) throw updateError;

      if (!updatedRows || updatedRows.length === 0) {
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
