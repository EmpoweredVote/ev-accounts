/**
 * compassAdmin.ts — admin-gated compass routes at /api/compass/* paths.
 *
 * Purpose: CompassV2 expects admin CRUD at Go-compatible URL paths such as
 * /api/compass/topics/create and /api/compass/politicians/:id/answers.
 * These same mutations also exist at /api/admin/compass/* (admin.ts) but
 * CompassV2 uses the shorter Go-server-style paths.
 *
 * This router is mounted AFTER compassRouter in index.ts so that public
 * compass routes (GET /topics, GET /answers, etc.) are matched first.
 * Routes here are all admin-only — blanket middleware applied at router level.
 *
 * Audit pattern: every mutation route calls logAdminAction() before returning
 * success (ADMN-05 requirement — every admin mutation must be logged).
 */

import { Router } from 'express';
import { z } from 'zod';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import { adminRpc } from '../lib/supabase.js';
import { pool } from '../lib/db.js';
import {
  logAdminAction,
  adminCreateTopicWithStances,
  adminUpdateTopic,
  adminUpdateStance,
  adminAssignTopicCategories,
  adminSetPoliticianContext,
} from '../lib/adminService.js';

const router = Router();

// Apply both middlewares to ALL routes on this router — no per-route repetition.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
router.use(requireAuth as any, requireAdmin as any);

// ---------------------------------------------------------------------------
// Helper: extract actor id from request (requireAuth attaches userId)
// ---------------------------------------------------------------------------

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function actorId(req: any): string {
  return (req as AuthenticatedRequest).userId;
}

// ---------------------------------------------------------------------------
// Validation schemas
// ---------------------------------------------------------------------------

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const CreateTopicSchema = z.object({
  title: z.string().min(1),
  short_title: z.string().optional(),
  question_text: z.string().min(1),
  level: z.array(z.string()).optional(),
  is_live: z.boolean().optional(),
  stances: z.array(z.object({
    value: z.number().int().min(1).max(5),
    text: z.string().min(1),
  })).optional(),
  category_ids: z.array(z.string().uuid()).optional(),
});

const UpdateTopicSchema = z.object({
  id: z.string().uuid(),
  title: z.string().min(1).optional(),
  short_title: z.string().optional(),
  question_text: z.string().min(1).optional(),
  is_live: z.boolean().optional(),
  level: z.array(z.string()).optional(),
});

const UpdateCategoriesSchema = z.object({
  topic_id: z.string().uuid(),
  category_ids: z.array(z.string().uuid()),
});

const UpdateStanceSchema = z.object({
  id: z.string().uuid(),
  text: z.string().min(1),
});

const PoliticianAnswersSchema = z.object({
  answers: z.array(z.object({
    topic_id: z.string().uuid(),
    value: z.number().multipleOf(0.5).min(0.5).max(5.5),
  })),
});

const PoliticianContextSchema = z.object({
  politician_id: z.string().uuid(),
  topic_id: z.string().uuid(),
  reasoning: z.string().min(1),
  sources: z.array(z.string()).optional(),
});

// ---------------------------------------------------------------------------
// POST /api/compass/topics/create
// Admin: atomic topic + stances + optional category assignment.
// ---------------------------------------------------------------------------

/**
 * POST /api/compass/topics/create
 * Create a compass topic with stances and optional category assignments atomically.
 * Mirrors POST /api/admin/compass/topics but at the Go-compatible URL path.
 */
router.post('/topics/create', async (req, res): Promise<void> => {
  const parsed = CreateTopicSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: parsed.error.issues[0]?.message ?? 'Invalid request body',
    });
    return;
  }

  try {
    const { category_ids, level, ...topicData } = parsed.data;

    const result = await adminCreateTopicWithStances(topicData);

    // Assign categories if provided
    if (category_ids && category_ids.length > 0) {
      const topicId = ((result as Record<string, unknown>).topic as Record<string, unknown>).id as string;
      await adminAssignTopicCategories(topicId, category_ids);
    }

    await logAdminAction(actorId(req), 'compass:topic:create', null, {
      topic_id: ((result as Record<string, unknown>).topic as Record<string, unknown>).id,
      title: parsed.data.title,
      stance_count: (parsed.data.stances ?? []).length,
    });

    res.status(201).json(result);
  } catch (err) {
    const e = err as { code?: string };
    if (e.code === 'VALIDATION_ERROR') {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: (err as Error).message });
      return;
    }
    console.error('[POST /compass/topics/create] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// PATCH /api/compass/topics/update
// Admin: update topic metadata.
// ---------------------------------------------------------------------------

/**
 * PATCH /api/compass/topics/update
 * Update a compass topic's metadata. Body must include id (UUID) plus any
 * fields to update: title, short_title, question_text, is_live, level.
 */
router.patch('/topics/update', async (req, res): Promise<void> => {
  const parsed = UpdateTopicSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: parsed.error.issues[0]?.message ?? 'Invalid request body',
    });
    return;
  }

  const { id, ...changes } = parsed.data;

  try {
    const topic = await adminUpdateTopic(id, changes);

    await logAdminAction(actorId(req), 'compass:topic:update', null, {
      topic_id: id,
      changes,
    });

    res.status(200).json(topic);
  } catch (err) {
    const e = err as { code?: string };
    if (e.code === 'NOT_FOUND') {
      res.status(404).json({ code: 'NOT_FOUND', message: 'Topic not found' });
      return;
    }
    console.error('[PATCH /compass/topics/update] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// DELETE /api/compass/topics/delete/:id
// Admin: delete topic, blocked if responses exist.
// ---------------------------------------------------------------------------

/**
 * DELETE /api/compass/topics/delete/:id
 * Delete a compass topic. Returns 422 if the topic has existing user responses
 * (set is_live=false to archive instead). Returns 204 on success.
 */
router.delete('/topics/delete/:id', async (req, res): Promise<void> => {
  const id = req.params.id as string;

  if (!UUID_REGEX.test(id)) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid topic ID format' });
    return;
  }

  try {
    // Guard: reject deletion if users have already responded to this topic
    const countResult = await pool.query<{ count: string }>(
      'SELECT COUNT(*)::text AS count FROM inform.compass_responses WHERE topic_id = $1',
      [id]
    );
    const responseCount = parseInt(countResult.rows[0]?.count ?? '0', 10);

    if (responseCount > 0) {
      res.status(422).json({
        code: 'TOPIC_HAS_RESPONSES',
        message: 'Cannot delete topic with existing responses. Set is_live=false to archive.',
      });
      return;
    }

    // Delete topic-category mappings explicitly (stances cascade via FK)
    await pool.query(
      'DELETE FROM inform.compass_topic_categories WHERE topic_id = $1',
      [id]
    );

    // Delete the topic itself
    await pool.query(
      'DELETE FROM inform.compass_topics WHERE id = $1',
      [id]
    );

    await logAdminAction(actorId(req), 'compass:topic:delete', null, { topic_id: id });

    res.status(204).send();
  } catch (err) {
    console.error('[DELETE /compass/topics/delete/:id] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// PATCH /api/compass/topics/categories/update
// Admin: reassign topic-category mappings.
// ---------------------------------------------------------------------------

/**
 * PATCH /api/compass/topics/categories/update
 * Replace all category assignments for a topic.
 * Body: { topic_id: string, category_ids: string[] }
 */
router.patch('/topics/categories/update', async (req, res): Promise<void> => {
  const parsed = UpdateCategoriesSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: parsed.error.issues[0]?.message ?? 'Invalid request body',
    });
    return;
  }

  try {
    await adminAssignTopicCategories(parsed.data.topic_id, parsed.data.category_ids);

    await logAdminAction(actorId(req), 'compass:topic:categories:update', null, {
      topic_id: parsed.data.topic_id,
      category_ids: parsed.data.category_ids,
    });

    res.status(200).json({ ok: true });
  } catch (err) {
    const e = err as { code?: string };
    if (e.code === 'NOT_FOUND') {
      res.status(404).json({ code: 'NOT_FOUND', message: 'Topic not found' });
      return;
    }
    console.error('[PATCH /compass/topics/categories/update] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// PATCH /api/compass/stances/update
// Admin: update stance text.
// ---------------------------------------------------------------------------

/**
 * PATCH /api/compass/stances/update
 * Update a compass stance's text.
 * Body: { id: string, text: string }
 */
router.patch('/stances/update', async (req, res): Promise<void> => {
  const parsed = UpdateStanceSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: parsed.error.issues[0]?.message ?? 'Invalid request body',
    });
    return;
  }

  try {
    const stance = await adminUpdateStance(parsed.data.id, { text: parsed.data.text });

    await logAdminAction(actorId(req), 'compass:stance:update', null, {
      stance_id: parsed.data.id,
      changes: { text: parsed.data.text },
    });

    res.status(200).json(stance);
  } catch (err) {
    const e = err as { code?: string };
    if (e.code === 'NOT_FOUND') {
      res.status(404).json({ code: 'NOT_FOUND', message: 'Stance not found' });
      return;
    }
    console.error('[PATCH /compass/stances/update] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/compass/politicians/context
// Admin: add/update politician reasoning + sources.
// NOTE: Registered BEFORE /politicians/:id/answers to prevent Express treating
// "context" as a politician ID param on a different pattern.
// ---------------------------------------------------------------------------

/**
 * POST /api/compass/politicians/context
 * Upsert politician context (reasoning + sources) for a specific topic.
 * Body: { politician_id, topic_id, reasoning, sources? }
 */
router.post('/politicians/context', async (req, res): Promise<void> => {
  const parsed = PoliticianContextSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: parsed.error.issues[0]?.message ?? 'Invalid request body',
    });
    return;
  }

  try {
    const context = await adminSetPoliticianContext(
      parsed.data.politician_id,
      parsed.data.topic_id,
      { reasoning: parsed.data.reasoning, sources: parsed.data.sources }
    );

    await logAdminAction(actorId(req), 'compass:politician:context:update', null, {
      politician_id: parsed.data.politician_id,
      topic_id: parsed.data.topic_id,
    });

    res.status(200).json(context);
  } catch (err) {
    console.error('[POST /compass/politicians/context] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// PUT /api/compass/politicians/:id/answers
// Admin: full replacement of politician answers (delete + upsert via RPC).
// NOTE: Registered AFTER /politicians/context to avoid :id capturing "context".
// ---------------------------------------------------------------------------

/**
 * PUT /api/compass/politicians/:id/answers
 * Full replacement of all politician answers for a given politician.
 * Deletes all existing answers then inserts the provided set atomically
 * via the admin_update_politician_answers RPC (updated in Plan 01 migration).
 * Body: { answers: [{ topic_id: string, value: number (0.5 steps, 0.5–5.5) }] }
 */
router.put('/politicians/:id/answers', async (req, res): Promise<void> => {
  const id = req.params.id as string;

  if (!UUID_REGEX.test(id)) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid politician ID format' });
    return;
  }

  const parsed = PoliticianAnswersSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: parsed.error.issues[0]?.message ?? 'Invalid request body',
    });
    return;
  }

  try {
    const { data, error } = await adminRpc('admin_update_politician_answers', {
      p_politician_id: id,
      p_answers: JSON.stringify(parsed.data.answers),
    });

    if (error) throw new Error(error.message);

    await logAdminAction(actorId(req), 'compass:politician:answers:replace', null, {
      politician_id: id,
      answer_count: parsed.data.answers.length,
    });

    res.status(200).json({ replaced: parsed.data.answers.length, data });
  } catch (err) {
    console.error('[PUT /compass/politicians/:id/answers] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
