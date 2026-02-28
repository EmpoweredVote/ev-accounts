/**
 * admin.ts — all /api/admin/* route handlers.
 *
 * All data access goes through adminService.ts (src/lib/).
 * This file imports named functions from adminService only — no direct DB client usage.
 *
 * Auth pattern: router.use(requireAuth, requireAdmin) applies both middlewares
 * to every route without per-route repetition (Civic Trivia pattern).
 *
 * Audit pattern: every mutation route calls logAdminAction() before returning
 * success (ADMN-05 requirement — every admin mutation must be logged).
 */

import { Router } from 'express';
import { z } from 'zod';
import { requireAuth } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import type { AuthenticatedRequest } from '../middleware/auth.js';
import {
  logAdminAction,
  listAccounts,
  getAccountDetail,
  setAccountStanding,
  adminDemote,
  listInvites,
  adminCreateInvite,
  revokeInvite,
  getInviteTree,
  adminGrantRole,
  adminRevokeRole,
  adminCreateTopic,
  adminUpdateTopic,
  adminUpdateStance,
  adminUpdatePoliticianAnswers,
  adminSetPoliticianContext,
  adminListPoliticians,
  getDashboardStats,
  getCronLog,
  getAdminMe,
} from '../lib/adminService.js';

const router = Router();

// Apply both middlewares to ALL admin routes — no per-route repetition
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
// Admin identity
// ---------------------------------------------------------------------------

/**
 * GET /api/admin/me
 * Returns { isAdmin: true } — confirms the caller has admin access.
 * Used by the admin UI to verify admin status after login.
 */
router.get('/me', async (req, res) => {
  try {
    const result = await getAdminMe((req as AuthenticatedRequest).userId);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ---------------------------------------------------------------------------
// Dashboard
// ---------------------------------------------------------------------------

/**
 * GET /api/admin/dashboard
 * Returns cohort statistics: users by tier, standing, pending verifications,
 * recent invites, and active invite code counts.
 * ADMN-04
 */
router.get('/dashboard', async (_req, res) => {
  try {
    const stats = await getDashboardStats();
    res.json(stats);
  } catch (err) {
    console.error('[admin/dashboard] error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ---------------------------------------------------------------------------
// Accounts
// ---------------------------------------------------------------------------

const AccountsQuerySchema = z.object({
  search: z.string().optional(),
  tier: z.enum(['inform', 'connected', 'empowered']).optional(),
  standing: z.enum(['active', 'suspended']).optional(),
  page: z.coerce.number().int().min(1).default(1),
});

const DemoteSchema = z.object({
  reason: z.record(z.unknown()).optional(),
});

/**
 * GET /api/admin/accounts
 * List accounts with optional search + filter by tier and standing. Paginated.
 */
router.get('/accounts', async (req, res) => {
  try {
    const parsed = AccountsQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid query parameters', details: parsed.error.flatten() });
      return;
    }
    const { search, tier, standing, page } = parsed.data;
    const result = await listAccounts({ search, tier, standing, page });
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/admin/accounts/:userId
 * Full account detail including tolerance_rating, legal_name, roles, audit log.
 * Every access is logged to admin_audit_log (ADMN-02).
 */
router.get('/accounts/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const detail = await getAccountDetail(userId);
    // ADMN-02: log every admin view of sensitive account details
    await logAdminAction(actorId(req), 'view_account_detail', userId, {
      viewed_fields: ['tolerance_rating', 'legal_name', 'roles', 'audit_log'],
    });
    res.json(detail);
  } catch (err) {
    const e = err as { code?: string };
    if (e.code === 'NOT_FOUND') {
      res.status(404).json({ error: 'User not found' });
      return;
    }
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * POST /api/admin/accounts/:userId/suspend
 * Set account_standing = 'suspended' on connected_profiles. ADMN-03.
 */
router.post('/accounts/:userId/suspend', async (req, res) => {
  try {
    const { userId } = req.params;
    await setAccountStanding(userId, 'suspended');
    await logAdminAction(actorId(req), 'suspend_account', userId);
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * POST /api/admin/accounts/:userId/unsuspend
 * Set account_standing = 'active' on connected_profiles. ADMN-03.
 */
router.post('/accounts/:userId/unsuspend', async (req, res) => {
  try {
    const { userId } = req.params;
    await setAccountStanding(userId, 'active');
    await logAdminAction(actorId(req), 'unsuspend_account', userId);
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * POST /api/admin/accounts/:userId/demote
 * Call execute_demotion for an Empowered user. ADMN-03.
 */
router.post('/accounts/:userId/demote', async (req, res) => {
  try {
    const { userId } = req.params;
    const parsed = DemoteSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid request body', details: parsed.error.flatten() });
      return;
    }
    const reason = parsed.data.reason ?? { source: 'admin_manual' };
    await adminDemote(userId, reason);
    await logAdminAction(actorId(req), 'demote_account', userId, { reason });
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ---------------------------------------------------------------------------
// Invites
// ---------------------------------------------------------------------------

// IMPORTANT: /invites/tree must be registered BEFORE /invites/:codeId
// to prevent Express from treating "tree" as a codeId param.

/**
 * GET /api/admin/invites/tree
 * Return React Flow-compatible full cohort invite tree (all invite chains).
 * ADMN-01
 */
router.get('/invites/tree', async (req, res) => {
  try {
    const tree = await getInviteTree();
    await logAdminAction(actorId(req), 'view_invite_tree', null);
    res.json(tree);
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/admin/invites/tree/:userId
 * Return React Flow-compatible invite subtree rooted at a specific user.
 * ADMN-01
 */
router.get('/invites/tree/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const tree = await getInviteTree(userId);
    await logAdminAction(actorId(req), 'view_invite_subtree', userId);
    res.json(tree);
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

const InvitesQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
});

const CreateInviteSchema = z.object({
  recipient_email: z.string().email().optional(),
});

/**
 * GET /api/admin/invites
 * List all invite codes with creator and claimer info. Paginated.
 */
router.get('/invites', async (req, res) => {
  try {
    const parsed = InvitesQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid query parameters', details: parsed.error.flatten() });
      return;
    }
    const result = await listInvites({ page: parsed.data.page });
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * POST /api/admin/invites
 * Create a new admin invite code. ADMN-01.
 */
router.post('/invites', async (req, res) => {
  try {
    const parsed = CreateInviteSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid request body', details: parsed.error.flatten() });
      return;
    }
    const actor = actorId(req);
    const invite = await adminCreateInvite(actor, parsed.data.recipient_email);
    await logAdminAction(actor, 'create_invite_code', null, {
      invite_id: (invite as Record<string, unknown>).id,
      recipient_email: parsed.data.recipient_email,
    });
    res.status(201).json(invite);
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * DELETE /api/admin/invites/:codeId
 * Revoke an active invite code. ADMN-01.
 */
router.delete('/invites/:codeId', async (req, res) => {
  try {
    const { codeId } = req.params;
    await revokeInvite(codeId);
    await logAdminAction(actorId(req), 'revoke_invite_code', null, {
      code_id: codeId,
    });
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ---------------------------------------------------------------------------
// Roles (deferred from Phase 6)
// ---------------------------------------------------------------------------

const RoleActionSchema = z.object({
  user_id: z.string().uuid(),
  role_slug: z.string().min(1),
});

/**
 * POST /api/admin/roles/grant
 * Grant a role to a user. Delegates to roleService.grantRole(). CIVIC-02.
 */
router.post('/roles/grant', async (req, res) => {
  try {
    const parsed = RoleActionSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid request body', details: parsed.error.flatten() });
      return;
    }
    const { user_id, role_slug } = parsed.data;
    await adminGrantRole(user_id, role_slug);
    await logAdminAction(actorId(req), 'grant_role', user_id, {
      role_slug,
    });
    res.json({ ok: true });
  } catch (err) {
    const e = err as { code?: string; message?: string };
    if (
      e.code === 'ROLE_NOT_FOUND' ||
      e.code === 'ROLE_INACTIVE' ||
      e.code === 'TIER_INELIGIBLE' ||
      e.code === 'ROLE_ALREADY_GRANTED' ||
      e.code === 'ROLE_CONFLICT'
    ) {
      res.status(400).json({ error: e.message, code: e.code });
      return;
    }
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * POST /api/admin/roles/revoke
 * Revoke a role from a user. Delegates to roleService.revokeRole(). CIVIC-02.
 */
router.post('/roles/revoke', async (req, res) => {
  try {
    const parsed = RoleActionSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid request body', details: parsed.error.flatten() });
      return;
    }
    const { user_id, role_slug } = parsed.data;
    await adminRevokeRole(user_id, role_slug);
    await logAdminAction(actorId(req), 'revoke_role', user_id, {
      role_slug,
    });
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ---------------------------------------------------------------------------
// Compass admin (deferred from Phase 4)
// ---------------------------------------------------------------------------

const CreateTopicSchema = z.object({
  title: z.string().min(1),
  short_title: z.string().optional(),
  question_text: z.string().min(1),
  is_live: z.boolean().optional(),
});

const UpdateTopicSchema = z.object({
  title: z.string().min(1).optional(),
  short_title: z.string().optional(),
  question_text: z.string().min(1).optional(),
  is_live: z.boolean().optional(),
});

const UpdateStanceSchema = z.object({
  text: z.string().min(1).optional(),
  value: z.number().int().min(1).max(5).optional(),
});

const PoliticianAnswersSchema = z.object({
  answers: z.array(
    z.object({
      topic_id: z.string().uuid(),
      value: z.number().int().min(1).max(5),
    })
  ),
});

const PoliticianContextSchema = z.object({
  reasoning: z.string().min(1),
  sources: z.array(z.string()).optional(),
});

/**
 * POST /api/admin/compass/topics
 * Create a new compass topic. Phase 4 deferred route.
 */
router.post('/compass/topics', async (req, res) => {
  try {
    const parsed = CreateTopicSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid request body', details: parsed.error.flatten() });
      return;
    }
    const topic = await adminCreateTopic(parsed.data);
    await logAdminAction(actorId(req), 'create_compass_topic', null, {
      topic_id: (topic as Record<string, unknown>).id,
      title: parsed.data.title,
    });
    res.status(201).json(topic);
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * PUT /api/admin/compass/topics/:id
 * Update a compass topic. Phase 4 deferred route.
 * CRITICAL: when is_live transitions to true, went_live_at is set automatically.
 */
router.put('/compass/topics/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const parsed = UpdateTopicSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid request body', details: parsed.error.flatten() });
      return;
    }
    const topic = await adminUpdateTopic(id, parsed.data);
    await logAdminAction(actorId(req), 'update_compass_topic', null, {
      topic_id: id,
      changes: parsed.data,
    });
    res.json(topic);
  } catch (err) {
    const e = err as { code?: string };
    if (e.code === 'NOT_FOUND') {
      res.status(404).json({ error: 'Topic not found' });
      return;
    }
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * PUT /api/admin/compass/stances/:id
 * Update a compass stance. Phase 4 deferred route.
 */
router.put('/compass/stances/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const parsed = UpdateStanceSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid request body', details: parsed.error.flatten() });
      return;
    }
    if (Object.keys(parsed.data).length === 0) {
      res.status(400).json({ error: 'No fields to update' });
      return;
    }
    const stance = await adminUpdateStance(id, parsed.data);
    await logAdminAction(actorId(req), 'update_compass_stance', null, {
      stance_id: id,
      changes: parsed.data,
    });
    res.json(stance);
  } catch (err) {
    const e = err as { code?: string };
    if (e.code === 'NOT_FOUND') {
      res.status(404).json({ error: 'Stance not found' });
      return;
    }
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * PUT /api/admin/compass/politicians/:id/answers
 * Upsert politician answers (bulk). Phase 4 deferred route.
 */
router.put('/compass/politicians/:id/answers', async (req, res) => {
  try {
    const { id } = req.params;
    const parsed = PoliticianAnswersSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid request body', details: parsed.error.flatten() });
      return;
    }
    await adminUpdatePoliticianAnswers(id, parsed.data.answers);
    await logAdminAction(actorId(req), 'update_politician_answers', null, {
      politician_id: id,
      answer_count: parsed.data.answers.length,
    });
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * POST /api/admin/compass/politicians/:id/context
 * Upsert politician context (reasoning + sources). Phase 4 deferred route.
 */
router.post('/compass/politicians/:id/context', async (req, res) => {
  try {
    const { id } = req.params;
    const { topic_id, ...bodyWithoutTopicId } = req.body as { topic_id?: string; [key: string]: unknown };

    if (!topic_id || typeof topic_id !== 'string') {
      res.status(400).json({ error: 'topic_id is required' });
      return;
    }

    const parsed = PoliticianContextSchema.safeParse(bodyWithoutTopicId);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid request body', details: parsed.error.flatten() });
      return;
    }

    const context = await adminSetPoliticianContext(id, topic_id, parsed.data);
    await logAdminAction(
      actorId(req),
      'update_politician_context',
      null,
      { politician_id: id, topic_id }
    );
    res.json(context);
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/admin/essentials/politicians
 * List all politicians including inactive (admin view). Phase 4 deferred route.
 */
router.get('/essentials/politicians', async (_req, res) => {
  try {
    const politicians = await adminListPoliticians();
    res.json({ politicians });
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ---------------------------------------------------------------------------
// Cron log
// ---------------------------------------------------------------------------

const CronLogQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
});

/**
 * GET /api/admin/cron-log
 * List calibration_lapse_runs entries. Paginated.
 */
router.get('/cron-log', async (req, res) => {
  try {
    const parsed = CronLogQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid query parameters', details: parsed.error.flatten() });
      return;
    }
    const result = await getCronLog({ page: parsed.data.page });
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
