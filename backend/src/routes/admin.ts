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
import { invalidateRoleCache } from '../lib/roleService.js';
import {
  sanctionInvitee,
  clearSlotLock,
  setInviteCapOverride,
  getInviteOverrides,
} from '../lib/inviteQuotaService.js';
import {
  logAdminAction,
  listAccounts,
  getAccountDetail,
  setAccountStanding,
  adminDemote,
  getAdminXpHistory,
  listInvites,
  adminCreateInvite,
  revokeInvite,
  getInviteTree,
  adminGrantRole,
  adminRevokeRole,
  adminUpdateTopic,
  adminUpdateStance,
  adminUpdatePoliticianAnswers,
  adminSetPoliticianContext,
  adminListPoliticians,
  getDashboardStats,
  getCronLog,
  getAdminMe,
  adminCreateTopicWithRevision,
  adminListTopics,
  adminCreatePolitician,
  adminUpdatePolitician,
  adminListCategories,
  adminCreateCategory,
  adminAssignTopicCategories,
  getTopicStances,
  promoteToConnected,
  getPromotionHistory,
  getGlobalPromotionLog,
  getAdminEmailById,
  updateVerificationRating,
  deleteAccount,
  listAccessRequests,
  writeRoleAuditLog,
  getRoleAuditLog,
  listRoles,
  getAccountJurisdictions,
} from '../lib/adminService.js';
import { getCoverage, listCoverageStates } from '../lib/coverageService.js';
import { getStateScores, getCountyScores } from '../lib/coverageMapService.js';
import { getFederalDelegation } from '../lib/federalCoverage.js';
import { getElectionsStateScores, getElectionsCountyScores } from '../lib/electionsMapService.js';
import {
  listPendingResearchReview,
  getResearchReviewWithLadder,
  resolveResearchReview,
  rejectResearchReview,
} from '../lib/researchEvidenceService.js';
import {
  listCandidatesWithPending, listPendingEvidence, acceptEvidence, rejectEvidence,
  rehomeEvidence, evidenceReviewMetrics,
} from '../lib/evidenceReviewService.js';

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
// Data coverage tracker
// ---------------------------------------------------------------------------

/**
 * GET /api/admin/coverage?state=ut
 * Returns the per-jurisdiction coverage rows + jurisdiction rules for a state,
 * with the auto columns (populated/headshots/stances/last_researched) recomputed
 * live from the DB. Also returns the list of states that have a coverage file.
 */
router.get('/coverage', async (req, res) => {
  try {
    const states = listCoverageStates();
    if (states.length === 0) {
      res.json({ states: [], coverage: null });
      return;
    }
    const requested = String(req.query.state ?? states[0]).toLowerCase();
    const state = states.includes(requested) ? requested : states[0];
    const coverage = await getCoverage(state);
    res.json({ states, coverage });
  } catch (err) {
    console.error('[admin/coverage] error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/admin/coverage/map?level=state
 * GET /api/admin/coverage/map?level=county&state=ut
 * Choropleth scores: one composite-completeness % per geography. `level=state`
 * returns a score per tracked state (untracked states omitted → client paints
 * them "not started"); `level=county` returns per-county scores + the
 * jurisdictions inside each county for the drill-down panel. ?refresh=1 busts
 * the in-process cache.
 * ?metric=elections switches to the elections overlay: race coverage (races with
 * >=1 candidate) for each state's nearest upcoming election + that election's date.
 */
router.get('/coverage/map', async (req, res) => {
  try {
    const level = String(req.query.level ?? 'state');
    const metric = String(req.query.metric ?? 'completeness');
    const refresh = req.query.refresh === '1' || req.query.refresh === 'true';
    const elections = metric === 'elections';

    if (level === 'county') {
      const state = String(req.query.state ?? '').toLowerCase();
      if (!state) {
        res.status(400).json({ error: 'state query param required for level=county' });
        return;
      }
      if (elections) {
        const data = await getElectionsCountyScores(state, { refresh });
        res.json(data ?? { state, state_fips: null, election_date: null, election_type: null, counties: [] });
        return;
      }
      const data = await getCountyScores(state, { refresh });
      res.json(data ?? { state, state_fips: null, counties: [] });
      return;
    }

    if (elections) {
      res.json({ states: await getElectionsStateScores({ refresh }) });
      return;
    }
    res.json({ states: await getStateScores({ refresh }) });
  } catch (err) {
    console.error('[admin/coverage/map] error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/admin/coverage/federal?state=ut
 * Per-member federal + state-office roster for one state (any of the 56 — no
 * coverage YAML required): U.S. Senate, U.S. House, governor, statewide execs,
 * state legislature, plus tracked challengers. Non-voting seats carry their
 * representation_note (ADR 0003) — the client must render it with the seat.
 */
router.get('/coverage/federal', async (req, res) => {
  try {
    const state = String(req.query.state ?? '').toLowerCase();
    if (!/^[a-z]{2}$/.test(state)) {
      res.status(400).json({ error: 'state query param required (2-letter code)' });
      return;
    }
    res.json({ state, members: await getFederalDelegation(state) });
  } catch (err) {
    console.error('[admin/coverage/federal] error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ---------------------------------------------------------------------------
// Access requests
// ---------------------------------------------------------------------------

/**
 * GET /api/admin/access-requests
 * Returns all access requests sorted newest-first.
 */
router.get('/access-requests', async (_req, res) => {
  try {
    const requests = await listAccessRequests();
    res.json({ requests });
  } catch (err) {
    console.error('[admin/access-requests] error:', err);
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
  reason: z.record(z.string(), z.unknown()).optional(),
});

const InviteCapSchema = z.object({
  cap: z.union([z.literal(-1), z.number().int().min(1), z.null()]),
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
 * Full account detail including tolerance_rating, roles, audit log. The
 * Connect legal_name is vaulted (id_vault) and never returned here.
 * Every access is logged to admin_audit_log (ADMN-02).
 */
router.get('/accounts/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const detail = await getAccountDetail(userId);
    // ADMN-02: log every admin view of sensitive account details
    await logAdminAction(actorId(req), 'view_account_detail', userId, {
      viewed_fields: ['tolerance_rating', 'roles', 'audit_log'],
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
 * GET /api/admin/accounts/:userId/jurisdictions
 * Returns jurisdiction geoids from the user's connected_profile.
 * Used by GrantRoleModal to show clickable geoid hints.
 */
router.get('/accounts/:userId/jurisdictions', async (req, res) => {
  try {
    const { userId } = req.params;
    const jurisdictions = await getAccountJurisdictions(userId);
    res.json(jurisdictions ?? {});
  } catch (err) {
    console.error('[admin/jurisdictions] error:', err);
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
    // Phase 59: Lock inviter's slot + adjust TR + notify (non-blocking)
    try {
      await sanctionInvitee(userId);
    } catch (err) {
      console.error('[admin/suspend] sanction_invitee failed for', userId, ':', err);
      // Non-blocking: suspension succeeded, accountability is best-effort
    }
    res.json({ ok: true });
  } catch (err) {
    console.error('[admin/suspend] error for userId', req.params.userId, ':', err);
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
    // Phase 59: Free inviter's locked slot on reinstatement (non-blocking)
    try {
      await clearSlotLock(userId);
    } catch (err) {
      console.error('[admin/unsuspend] clearSlotLock failed for', userId, ':', err);
      // Non-blocking: unsuspension succeeded, slot unlock is best-effort
    }
    res.json({ ok: true });
  } catch (err) {
    console.error('[admin/unsuspend] error for userId', req.params.userId, ':', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ---------------------------------------------------------------------------
// Invite cap overrides (Phase 59)
// ---------------------------------------------------------------------------

/**
 * POST /api/admin/accounts/:userId/invite-cap-override
 * Set (or clear) an explicit invite quota override for a user.
 *   cap = -1       → unlimited
 *   cap = N (≥1)   → explicit cap (used if larger than level cap)
 *   cap = null     → remove override, revert to level-based cap
 * Logs to admin_audit_log.
 */
router.post('/accounts/:userId/invite-cap-override', async (req, res) => {
  try {
    const { userId } = req.params;
    const parsed = InviteCapSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: parsed.error.issues[0]?.message });
      return;
    }
    await setInviteCapOverride(userId, parsed.data.cap);
    await logAdminAction(actorId(req), 'set_invite_cap_override', userId, {
      cap: parsed.data.cap,
    });
    res.json({ ok: true });
  } catch (err) {
    console.error('[admin/invite-cap-override] error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/admin/invite-overrides
 * List all users with an active invite_cap_override, including effective_cap.
 */
router.get('/invite-overrides', async (_req, res) => {
  try {
    const overrides = await getInviteOverrides();
    res.json(overrides);
  } catch (err) {
    console.error('[admin/invite-overrides] error:', err);
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

const PromoteSchema = z.object({
  note: z.string().max(500).optional(),
});

const PromotionLogQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
});

/**
 * POST /api/admin/accounts/:userId/promote
 * Promote an Inform-tier user to Connected. Creates connected_profiles row and
 * tier_promotion_log entry atomically via promote_to_connected RPC.
 * Returns 409 if user is already Connected or Empowered.
 * Returns 404 if user does not exist.
 */
router.post('/accounts/:userId/promote', async (req, res) => {
  try {
    const { userId } = req.params;
    const parsed = PromoteSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid request body', details: parsed.error.flatten() });
      return;
    }

    const adminId = actorId(req);

    // Resolve admin email server-side via supabaseAdmin.auth.admin.getUserById
    // (delegated to adminService to avoid supabaseAdmin in routes — architecture rule).
    const adminEmail = await getAdminEmailById(adminId);
    if (!adminEmail) {
      res.status(500).json({ error: 'Failed to resolve admin identity' });
      return;
    }

    await promoteToConnected(adminId, adminEmail, userId, parsed.data.note);
    await logAdminAction(actorId(req), 'promote_to_connected', userId, {
      previous_tier: 'inform',
      new_tier: 'connected',
      note: parsed.data.note ?? null,
    });

    res.json({ ok: true });
  } catch (err) {
    const e = err as { code?: string };
    if (e.code === 'NOT_FOUND') {
      res.status(404).json({ error: 'User not found' });
      return;
    }
    if (e.code === 'ALREADY_CONNECTED') {
      res.status(409).json({ error: 'User is already Connected or Empowered' });
      return;
    }
    res.status(500).json({ error: 'Internal server error' });
  }
});

const VerificationRatingSchema = z.object({
  verification_rating: z.number().int().min(0).max(150).optional(),
  clear_hold: z.boolean().optional(),
}).refine(
  (d) => d.verification_rating !== undefined || d.clear_hold === true,
  { message: 'Must provide verification_rating or clear_hold: true' }
);

/**
 * PATCH /api/admin/accounts/:userId/verification-rating
 * Manually override a user's verification_rating and/or clear vq_hold_until.
 * VR-05. Calls logAdminAction before returning 200.
 */
router.patch('/accounts/:userId/verification-rating', async (req, res) => {
  try {
    const { userId } = req.params;
    const parsed = VerificationRatingSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid request body', details: parsed.error.flatten() });
      return;
    }
    await updateVerificationRating(userId, {
      rating: parsed.data.verification_rating,
      clearHold: parsed.data.clear_hold,
    });
    await logAdminAction(actorId(req), 'update_verification_rating', userId, {
      changes: parsed.data,
    });
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

const XpHistoryQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
});

/**
 * GET /api/admin/accounts/:userId/xp-history
 * Paginated XP transaction history for a Connected user. Admin only.
 * Returns 25 transactions per page in reverse chronological order.
 * XPADM-02
 */
router.get('/accounts/:userId/xp-history', async (req, res) => {
  try {
    const { userId } = req.params;
    const parsed = XpHistoryQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid query parameters', details: parsed.error.flatten() });
      return;
    }
    const result = await getAdminXpHistory(userId, parsed.data.page);
    res.json(result);
  } catch (err) {
    console.error('[admin/xp-history] error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/admin/accounts/:userId/promotion-history
 * Paginated promotion log for a specific user (reverse chronological).
 */
router.get('/accounts/:userId/promotion-history', async (req, res) => {
  try {
    const { userId } = req.params;
    const parsed = PromotionLogQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid query parameters', details: parsed.error.flatten() });
      return;
    }
    const result = await getPromotionHistory(userId, parsed.data.page);
    res.json(result);
  } catch (err) {
    console.error('[admin/promotion-history] error:', err);
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
    console.error('[admin/revoke-invite] error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ---------------------------------------------------------------------------
// Roles (deferred from Phase 6)
// ---------------------------------------------------------------------------

const RoleActionSchema = z.object({
  user_id: z.string().uuid(),
  role_slug: z.string().min(1),
  feature_scope: z.string().optional(),
  jurisdiction_geoid: z.string().nullable().optional(),
  resource_id: z.string().nullable().optional(),
});

/**
 * GET /api/admin/roles
 * List all active roles available to grant.
 */
router.get('/roles', async (_req, res) => {
  try {
    const roles = await listRoles();
    res.json({ roles });
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
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
    const { user_id, role_slug, feature_scope, jurisdiction_geoid, resource_id } = parsed.data;
    const resolvedScope = feature_scope ?? 'platform';
    await adminGrantRole(user_id, role_slug, resolvedScope, jurisdiction_geoid ?? null, resource_id ?? null, actorId(req));
    await invalidateRoleCache(user_id);
    await writeRoleAuditLog(actorId(req), user_id, 'granted', role_slug, resolvedScope, jurisdiction_geoid ?? null, resource_id ?? null);
    await logAdminAction(actorId(req), 'grant_role', user_id, {
      role_slug,
      feature_scope: resolvedScope,
      jurisdiction_geoid: jurisdiction_geoid ?? null,
      resource_id: resource_id ?? null,
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
    const { user_id, role_slug, feature_scope, jurisdiction_geoid, resource_id } = parsed.data;
    const resolvedScope = feature_scope ?? 'platform';
    await adminRevokeRole(user_id, role_slug, resolvedScope, jurisdiction_geoid ?? null, resource_id ?? null);
    await invalidateRoleCache(user_id);
    await writeRoleAuditLog(actorId(req), user_id, 'revoked', role_slug, resolvedScope, jurisdiction_geoid ?? null, resource_id ?? null);
    await logAdminAction(actorId(req), 'revoke_role', user_id, {
      role_slug,
      feature_scope: resolvedScope,
      jurisdiction_geoid: jurisdiction_geoid ?? null,
      resource_id: resource_id ?? null,
    });
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ---------------------------------------------------------------------------
// Role audit log
// ---------------------------------------------------------------------------

const AuditLogQuerySchema = z.object({
  feature_scope: z.string().optional(),
  jurisdiction_geoid: z.string().optional(),
  from_date: z.string().optional(),
  to_date: z.string().optional(),
  page: z.coerce.number().int().min(1).default(1),
  page_size: z.coerce.number().int().min(1).max(50).default(25),
});

/**
 * GET /api/admin/role-audit-log
 * Returns paginated, filterable entries from public.role_audit_log.
 */
router.get('/role-audit-log', async (req, res) => {
  try {
    const parsed = AuditLogQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid query parameters', details: parsed.error.flatten() });
      return;
    }
    const result = await getRoleAuditLog(parsed.data);
    res.json(result);
  } catch (err) {
    console.error('[admin/role-audit-log] error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ---------------------------------------------------------------------------
// Compass admin (deferred from Phase 4)
// ---------------------------------------------------------------------------

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
      // min(0): 0 is a BLANK. Note UpdateStanceSchema above keeps min(1) —
      // that one is a LADDER RUNG, and there is no rung 0.
      value: z.number().int().min(0).max(5),
    })
  ),
});

const PoliticianContextSchema = z.object({
  reasoning: z.string().min(1),
  sources: z.array(z.string()).optional(),
});

// A topic is created on the revision model (CA_0026): it needs a full 5-rung
// ladder to display on the season read path and to be pinnable into a season,
// so exactly 5 non-empty stances (values 1..5) are required at creation.
const CreateTopicWithStancesSchema = z.object({
  title: z.string().min(1),
  question_text: z.string().min(1),
  short_title: z.string().optional(),
  is_live: z.boolean().optional(),
  stances: z.array(z.object({
    value: z.number().int().min(1).max(5),
    text: z.string().min(1),
  })).length(5, 'exactly 5 stances (values 1..5) are required'),
});

const CreatePoliticianSchema = z.object({
  first_name: z.string().min(1),
  last_name: z.string().min(1),
  preferred_name: z.string().optional(),
  full_name: z.string().optional(),
  office_title: z.string().optional(),
  photo_origin_url: z.string().optional(),
  is_candidate: z.boolean().optional(),
});

const UpdatePoliticianSchema = z.object({
  first_name: z.string().min(1).optional(),
  last_name: z.string().min(1).optional(),
  preferred_name: z.string().optional(),
  full_name: z.string().optional(),
  office_title: z.string().optional(),
  photo_origin_url: z.string().optional(),
  is_active: z.boolean().optional(),
  is_candidate: z.boolean().optional(),
});

const CreateCategorySchema = z.object({
  title: z.string().min(1),
});

const AssignCategoriesSchema = z.object({
  category_ids: z.array(z.string().uuid()),
});

/**
 * GET /api/admin/compass/topics
 * List all compass topics (including non-live drafts). CADM-01.
 */
router.get('/compass/topics', async (_req, res) => {
  try {
    const topics = await adminListTopics();
    res.json({ topics });
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * POST /api/admin/compass/topics
 * Create a compass topic with optional stances array (atomic). CADM-02.
 */
router.post('/compass/topics', async (req, res) => {
  try {
    const parsed = CreateTopicWithStancesSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid request body', details: parsed.error.flatten() });
      return;
    }
    const result = await adminCreateTopicWithRevision({ ...parsed.data, actorId: actorId(req) });
    await logAdminAction(actorId(req), 'create_compass_topic', null, {
      topic_id: ((result as Record<string, unknown>).topic as Record<string, unknown>).id,
      title: parsed.data.title,
      stance_count: (parsed.data.stances ?? []).length,
    });
    res.status(201).json(result);
  } catch (err) {
    const e = err as { code?: string };
    if (e.code === 'VALIDATION_ERROR') {
      res.status(400).json({ error: (err as Error).message });
      return;
    }
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * PATCH /api/admin/compass/topics/:id
 * Update a compass topic. CADM-02 update path.
 * CRITICAL: when is_live transitions to true, went_live_at is set automatically.
 */
router.patch('/compass/topics/:id', async (req, res) => {
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
 * GET /api/admin/compass/topics/:id/stances
 * Returns all stances for a topic as a plain array. CADM-gap.
 */
router.get('/compass/topics/:id/stances', async (req, res) => {
  try {
    const stances = await getTopicStances(req.params.id);
    res.json(stances);
  } catch (err) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal server error' });
  }
});

/**
 * PATCH /api/admin/compass/stances/:id
 * Update a compass stance. CADM-09 backend requirement.
 */
router.patch('/compass/stances/:id', async (req, res) => {
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
 * GET /api/admin/compass/categories
 * List all compass categories. CADM-05.
 */
router.get('/compass/categories', async (_req, res) => {
  try {
    const categories = await adminListCategories();
    res.json({ categories });
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * POST /api/admin/compass/categories
 * Create a new compass category. CADM-06.
 */
router.post('/compass/categories', async (req, res) => {
  try {
    const parsed = CreateCategorySchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid request body', details: parsed.error.flatten() });
      return;
    }
    const category = await adminCreateCategory(parsed.data);
    await logAdminAction(actorId(req), 'create_compass_category', null, {
      category_id: (category as Record<string, unknown>).id,
      title: parsed.data.title,
    });
    res.status(201).json(category);
  } catch (err) {
    const e = err as { code?: string };
    if (e.code === 'DUPLICATE_TITLE') {
      res.status(400).json({ error: 'Category title already exists' });
      return;
    }
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * PUT /api/admin/compass/topics/:id/categories
 * Assign categories to a compass topic (replaces all). CADM-07.
 */
router.put('/compass/topics/:id/categories', async (req, res) => {
  try {
    const { id } = req.params;
    const parsed = AssignCategoriesSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid request body', details: parsed.error.flatten() });
      return;
    }
    await adminAssignTopicCategories(id, parsed.data.category_ids);
    await logAdminAction(actorId(req), 'assign_topic_categories', null, {
      topic_id: id,
      category_ids: parsed.data.category_ids,
    });
    res.json({ ok: true });
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
 * GET /api/admin/compass/politicians
 * List all politicians including inactive (admin view). CADM-03 list path.
 */
router.get('/compass/politicians', async (_req, res) => {
  try {
    const politicians = await adminListPoliticians();
    res.json({ politicians });
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * POST /api/admin/compass/politicians
 * Create a new politician record. CADM-03.
 */
router.post('/compass/politicians', async (req, res) => {
  try {
    const parsed = CreatePoliticianSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid request body', details: parsed.error.flatten() });
      return;
    }
    const politician = await adminCreatePolitician(parsed.data);
    await logAdminAction(actorId(req), 'create_politician', null, {
      politician_id: (politician as Record<string, unknown>).id,
      full_name: parsed.data.full_name ?? `${parsed.data.first_name} ${parsed.data.last_name}`,
    });
    res.status(201).json(politician);
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * PATCH /api/admin/compass/politicians/:id
 * Update a politician record. CADM-04.
 */
router.patch('/compass/politicians/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const parsed = UpdatePoliticianSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid request body', details: parsed.error.flatten() });
      return;
    }
    if (Object.keys(parsed.data).length === 0) {
      res.status(400).json({ error: 'No fields to update' });
      return;
    }
    const politician = await adminUpdatePolitician(id, parsed.data);
    await logAdminAction(actorId(req), 'update_politician', null, {
      politician_id: id,
      changes: parsed.data,
    });
    res.json(politician);
  } catch (err) {
    const e = err as { code?: string };
    if (e.code === 'NOT_FOUND') {
      res.status(404).json({ error: 'Politician not found' });
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

    // actorId(req) is the editor of record for this row — the same identity the
    // audit log gets, so the two cannot disagree about who made the change.
    const context = await adminSetPoliticianContext(id, topic_id, parsed.data, actorId(req));
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
// Global promotion log
// ---------------------------------------------------------------------------

/**
 * GET /api/admin/promotions
 * Paginated global promotion log across all users and admins.
 * Each entry includes target_display_name (batch-fetched, not a join).
 */
router.get('/promotions', async (req, res) => {
  try {
    const parsed = PromotionLogQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid query parameters', details: parsed.error.flatten() });
      return;
    }
    const result = await getGlobalPromotionLog(parsed.data.page);
    res.json(result);
  } catch (err) {
    console.error('[admin/promotions] error:', err);
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

// ---------------------------------------------------------------------------
// Account deletion
// ---------------------------------------------------------------------------

/**
 * DELETE /api/admin/accounts/:userId
 * Hard-deletes a user from auth.users, which cascades to all child records.
 * Cannot be used to delete your own account (returns 400).
 * Returns 404 if user does not exist.
 */
router.delete('/accounts/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    await logAdminAction(actorId(req), 'delete_account', userId, {});
    await deleteAccount(actorId(req), userId);
    res.json({ ok: true });
  } catch (err) {
    const e = err as { code?: string };
    if (e.code === 'SELF_DELETE') {
      res.status(400).json({ error: 'Cannot delete your own account' });
      return;
    }
    if (e.code === 'NOT_FOUND') {
      res.status(404).json({ error: 'User not found' });
      return;
    }
    console.error('[admin/delete-account] error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ---------------------------------------------------------------------------
// Research review queue

router.get('/research-review', async (_req, res) => {
  try {
    const rows = await listPendingResearchReview();
    res.json(rows);
  } catch (err) {
    console.error('[admin/research-review] GET error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/research-review/:id', async (req, res) => {
  try {
    // Detail page (task 5): carries the ladder text (question + five rungs) alongside the row, so
    // the reviewer checks the proposal against the ladder without a second client-side fetch.
    const row = await getResearchReviewWithLadder(req.params.id);
    if (!row) { res.status(404).json({ error: 'Not found' }); return; }
    res.json(row);
  } catch (err) {
    console.error('[admin/research-review/:id] GET error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/research-review/:id/resolve', async (req: any, res) => {
  try {
    const { humanVerifiedUrls, valueOverride, reasoningOverride } = (req.body ?? {}) as {
      humanVerifiedUrls?: string[];
      valueOverride?: number | null;
      reasoningOverride?: string;
    };
    // Reject a malformed body before it reaches the service (NOT the "R1" ruling referenced
    // elsewhere in this file — citations on approval; this is approval INPUT validation, added in
    // the 2026-09-23 polish pass). The service repeats the valueOverride check (defence in depth —
    // it is also reachable directly, e.g. from a script), but only the route can turn a bad shape
    // into a clean 400 instead of a 500/crash.
    if (humanVerifiedUrls !== undefined
      && (!Array.isArray(humanVerifiedUrls) || !humanVerifiedUrls.every((u) => typeof u === 'string'))) {
      res.status(400).json({ error: 'humanVerifiedUrls must be an array of strings' });
      return;
    }
    if (valueOverride !== undefined && valueOverride !== null
      && (!Number.isInteger(valueOverride) || valueOverride < 1 || valueOverride > 5)) {
      res.status(400).json({ error: 'valueOverride must be an integer 1-5' });
      return;
    }
    if (reasoningOverride !== undefined && typeof reasoningOverride !== 'string') {
      res.status(400).json({ error: 'reasoningOverride must be a string' });
      return;
    }
    const { ladderRevisionUnknown } = await resolveResearchReview(
      req.params.id, actorId(req), humanVerifiedUrls ?? [], valueOverride, reasoningOverride);
    // ladderRevisionUnknown: a legacy row (queued before CA_0264), approved without a ladder check.
    res.json({ ok: true, ladderRevisionUnknown });
  } catch (err: any) {
    if (err.code === 'NOT_FOUND') { res.status(404).json({ error: 'Not found' }); return; }
    if (err.code === 'INCOMPLETE') { res.status(422).json({ error: err.message }); return; }
    // Not pending: already resolved/rejected (or unresolved_politician) — never re-approved.
    // Or the ladder was re-pinned since the row was researched (CA_0264) — re-research it.
    if (err.code === 'CONFLICT') { res.status(409).json({ error: err.message }); return; }
    console.error('[admin/research-review/:id/resolve] error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/research-review/:id/reject', async (req: any, res) => {
  try {
    const { notes } = (req.body ?? {}) as { notes?: string };
    await rejectResearchReview(req.params.id, actorId(req), notes);
    res.json({ ok: true });
  } catch (err) {
    const code = (err as { code?: string }).code;
    if (code === 'NOT_FOUND') { res.status(404).json({ error: 'Not found' }); return; }
    // I5: only a pending row can be rejected — a resolved row's published stance must stay audited.
    if (code === 'CONFLICT') { res.status(409).json({ error: (err as Error).message }); return; }
    console.error('[admin/research-review/:id/reject] error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ---------------------------------------------------------------------------
// Evidence review

// NOTE: /evidence/candidates and /evidence/metrics must be declared before any
// /evidence/:id/... route below, or the literal paths get shadowed by :id.
router.get('/evidence/candidates', async (_req, res) => {
  try { res.json(await listCandidatesWithPending()); }
  catch (err) { console.error('[admin/evidence/candidates]', err); res.status(500).json({ error: 'failed' }); }
});
router.get('/evidence/metrics', async (_req, res) => {
  try { res.json(await evidenceReviewMetrics()); }
  catch (err) { console.error('[admin/evidence/metrics]', err); res.status(500).json({ error: 'failed' }); }
});
router.get('/evidence', async (req, res) => {
  try {
    const { politician_id, issue, machine_status } = req.query as Record<string, string>;
    if (!politician_id) return res.status(400).json({ error: 'politician_id required' });
    res.json(await listPendingEvidence(politician_id, { issue, machineStatus: machine_status }));
  } catch (err) { console.error('[admin/evidence]', err); res.status(500).json({ error: 'failed' }); }
});
router.post('/evidence/:id/accept', async (req: any, res) => {
  try { await acceptEvidence(req.params.id, actorId(req)); res.json({ ok: true }); }
  catch (err) { console.error('[admin/evidence/accept]', err); res.status(500).json({ error: 'failed' }); }
});
router.post('/evidence/:id/reject', async (req: any, res) => {
  try {
    const { reason, note } = req.body ?? {};
    await rejectEvidence(req.params.id, actorId(req), reason, note);
    res.json({ ok: true });
  } catch (err: any) {
    if (/invalid reject reason/.test(err?.message)) return res.status(400).json({ error: err.message });
    console.error('[admin/evidence/reject]', err); res.status(500).json({ error: 'failed' });
  }
});
router.post('/evidence/:id/rehome', async (req: any, res) => {
  try {
    const { topic_id, issue } = req.body ?? {};
    await rehomeEvidence(req.params.id, { topicId: topic_id ?? null, issue }, actorId(req));
    res.json({ ok: true });
  } catch (err: any) {
    if (/issue/.test(err?.message)) return res.status(400).json({ error: err.message });
    console.error('[admin/evidence/rehome]', err); res.status(500).json({ error: 'failed' });
  }
});

export default router;
