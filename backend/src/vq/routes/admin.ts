import { Router } from 'express';
import { supabaseService } from '../lib/supabase.js';
import { requireAuth } from '../middleware/auth.js';
import { requireStaff } from '../middleware/tierGuards.js';
import {
  createAdminQuestSchema,
  adminBulkQuestSchema,
  ageWaiverSchema,
  suspendSchema,
  adminOverrideSchema,
  resolveContestSchema,
} from '../types/api.js';
import { DIFFICULTY_REWARDS } from '../types/custom.js';
import type { VerificationQuest } from '../types/database.types.js';
import { invalidateAllFeedCaches } from '../services/feedScoring.js';
import { executeAdminOverride, resolveContestation } from '../services/adminOverride.js';
import { logger } from '../lib/logger.js';

const router = Router();

// ============================================================
// Helpers
// ============================================================

/**
 * Log an admin action to the admin_override_log audit table.
 * Non-fatal: errors are logged but do not abort the action.
 */
async function logAdminAction(params: {
  admin_user_id: string;
  action_type: string;
  target_type: string;
  target_id: string;
  reasoning: string;
  metadata?: Record<string, unknown>;
}): Promise<void> {
  try {
    const { error } = await supabaseService
      .schema('validation_quests')
      .from('admin_override_log')
      .insert({
        admin_user_id: params.admin_user_id,
        action_type: params.action_type,
        target_type: params.target_type,
        target_id: params.target_id,
        reasoning: params.reasoning,
        metadata: params.metadata ?? {},
      });

    if (error) {
      logger.error('Failed to write admin_override_log', {
        action_type: params.action_type,
        error: error.message,
      });
    }
  } catch (err) {
    logger.error('Exception writing admin_override_log', { err });
  }
}

/**
 * Build a verification_quest row from admin quest creation data.
 * Applies DIFFICULTY_REWARDS lookup, bounty override, WKT geometry, and gem_quest_type.
 */
function buildQuestRow(
  data: ReturnType<typeof createAdminQuestSchema.parse>,
  createdBy: string,
): Record<string, unknown> {
  const {
    type,
    question_text,
    difficulty_tier,
    geographic_scope,
    jurisdiction_name,
    correct_answer,
    politician_id,
    topic_id,
    confirmed_value,
    jurisdiction_geometry,
    priority_level,
    gem_reward_override,
    gem_quest_type,
    bridging_waived,
  } = data;

  const rewards = DIFFICULTY_REWARDS[difficulty_tier];

  const gem_reward =
    gem_reward_override !== undefined && gem_reward_override >= 30
      ? gem_reward_override
      : rewards.gems;

  const effective_priority_level =
    gem_reward_override !== undefined && gem_reward_override >= 30
      ? ('high' as const)
      : priority_level;

  const row: Record<string, unknown> = {
    type,
    question_text,
    difficulty_tier,
    geographic_scope,
    xp_reward: rewards.xp,
    gem_reward,
    priority_level: effective_priority_level,
    status: 'active',
    created_by: createdBy,
    gem_quest_type,
    bridging_waived,
    jurisdiction_name: jurisdiction_name ?? null,
    correct_answer: correct_answer ?? null,
    politician_id: politician_id ?? null,
    topic_id: topic_id ?? null,
    confirmed_value: confirmed_value ?? null,
  };

  if (jurisdiction_geometry) {
    const { lat, lng } = jurisdiction_geometry;
    row.jurisdiction_geometry = `SRID=4326;POINT(${lng} ${lat})`;
  }

  return row;
}

// ============================================================
// GET /api/admin/jurisdictions — Return distinct jurisdiction names for autocomplete
// ============================================================

router.get('/jurisdictions', requireAuth, requireStaff, async (_req: any, res: any) => {
  const { data, error } = await supabaseService
    .schema('validation_quests')
    .from('verification_quests')
    .select('jurisdiction_name')
    .not('jurisdiction_name', 'is', null);

  if (error) {
    logger.error('Admin failed to fetch jurisdictions', { error: error.message });
    return res.status(500).json({ error: 'Failed to fetch jurisdictions' });
  }

  const rows = (data ?? []) as { jurisdiction_name: string }[];
  const names = [...new Set(rows.map((r) => r.jurisdiction_name))].sort();

  return res.status(200).json(names);
});

// ============================================================
// GET /api/admin/quests — ADMIN-LIST: List all quests with health signals
// ============================================================

router.get('/quests', requireAuth, requireStaff, async (req: any, res: any) => {
  const page = Math.max(1, parseInt(String(req.query.page ?? '1'), 10) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(String(req.query.limit ?? '50'), 10) || 50));
  const from = (page - 1) * limit;
  const to = from + limit - 1;

  const gem_quest_type = req.query.gem_quest_type as string | undefined;
  const status = req.query.status as string | undefined;
  const jurisdiction_name = req.query.jurisdiction_name as string | undefined;

  let query = supabaseService
    .schema('validation_quests')
    .from('verification_quests')
    .select(
      'id, type, gem_quest_type, question_text, status, jurisdiction_name, submission_count, priority_level, pinned, promoted_to_yellow_at, correct_answer, created_at, updated_at, gem_reward',
      { count: 'exact' },
    )
    .order('pinned', { ascending: false })
    .order('created_at', { ascending: false })
    .range(from, to);

  if (gem_quest_type) query = query.eq('gem_quest_type', gem_quest_type);
  if (status) query = query.eq('status', status);
  if (jurisdiction_name) query = query.eq('jurisdiction_name', jurisdiction_name);

  const { data: quests, error, count } = await (query as any);

  if (error) {
    logger.error('Admin failed to fetch quest list', { error: error.message });
    return res.status(500).json({ error: 'Failed to fetch quests' });
  }

  const questList = (quests ?? []) as any[];
  const total = count ?? 0;
  const total_pages = Math.ceil(total / limit);

  // Fetch Red health signals via separate queries on the result set
  const questIds: string[] = questList.map((q: any) => q.id);

  let lastSubmissionByQuest: Record<string, string> = {};
  let confidenceByQuest: Record<string, string> = {};

  if (questIds.length > 0) {
    // Last submission per quest — fetch ordered desc, deduplicate by quest_id
    const { data: submissions } = await supabaseService
      .schema('validation_quests')
      .from('verification_submissions')
      .select('quest_id, created_at')
      .in('quest_id', questIds)
      .order('created_at', { ascending: false });

    if (submissions) {
      for (const sub of submissions as any[]) {
        if (!lastSubmissionByQuest[sub.quest_id]) {
          lastSubmissionByQuest[sub.quest_id] = sub.created_at;
        }
      }
    }

    // Consensus confidence per quest
    const { data: consensusRecords } = await supabaseService
      .schema('validation_quests')
      .from('consensus_records')
      .select('quest_id, confidence_level')
      .in('quest_id', questIds);

    if (consensusRecords) {
      for (const cr of consensusRecords as any[]) {
        confidenceByQuest[cr.quest_id] = cr.confidence_level;
      }
    }
  }

  const enrichedQuests = questList.map((q: any) => {
    const lastSubAt = lastSubmissionByQuest[q.id] ?? null;
    const days_since_last_submission = lastSubAt
      ? Math.floor((Date.now() - new Date(lastSubAt).getTime()) / (1000 * 60 * 60 * 24))
      : null;

    return {
      id: q.id,
      type: q.type,
      gem_quest_type: q.gem_quest_type,
      question_text: q.question_text,
      status: q.status,
      jurisdiction_name: q.jurisdiction_name,
      submission_count: q.submission_count,
      priority_level: q.priority_level,
      pinned: q.pinned,
      promoted_to_yellow_at: q.promoted_to_yellow_at,
      correct_answer: q.correct_answer,
      gem_reward: q.gem_reward,
      created_at: q.created_at,
      updated_at: q.updated_at,
      // Red health signals
      is_conflicting: q.status === 'under_review',
      days_since_last_submission,
      consensus_confidence: confidenceByQuest[q.id] ?? null,
    };
  });

  return res.status(200).json({
    quests: enrichedQuests,
    pagination: { page, limit, total, total_pages },
  });
});

// ============================================================
// PATCH /api/admin/quests/:id/pin — PRIO-02: Pin a quest
// ============================================================

router.patch('/quests/:id/pin', requireAuth, requireStaff, async (req: any, res: any) => {
  const questId = req.params.id;

  const { data: quest, error: fetchError } = await supabaseService
    .schema('validation_quests')
    .from('verification_quests')
    .select('id')
    .eq('id', questId)
    .maybeSingle();

  if (fetchError) {
    logger.error('Admin pin: failed to fetch quest', { questId, error: fetchError.message });
    return res.status(500).json({ error: 'Failed to fetch quest' });
  }

  if (!quest) {
    return res.status(404).json({ error: 'Quest not found' });
  }

  const { error: updateError } = await supabaseService
    .schema('validation_quests')
    .from('verification_quests')
    .update({ pinned: true, updated_at: new Date().toISOString() })
    .eq('id', questId);

  if (updateError) {
    logger.error('Admin pin: failed to update quest', { questId, error: updateError.message });
    return res.status(500).json({ error: 'Failed to pin quest' });
  }

  await logAdminAction({
    admin_user_id: req.userId,
    action_type: 'quest_pinned',
    target_type: 'quest',
    target_id: questId,
    reasoning: `Admin pinned quest`,
  });

  try {
    await invalidateAllFeedCaches();
  } catch (err) {
    logger.error('Failed to invalidate feed caches after quest pin', { err });
  }

  return res.status(200).json({ success: true, quest_id: questId, pinned: true });
});

// ============================================================
// PATCH /api/admin/quests/:id/unpin — PRIO-03: Unpin a quest
// ============================================================

router.patch('/quests/:id/unpin', requireAuth, requireStaff, async (req: any, res: any) => {
  const questId = req.params.id;

  const { data: quest, error: fetchError } = await supabaseService
    .schema('validation_quests')
    .from('verification_quests')
    .select('id')
    .eq('id', questId)
    .maybeSingle();

  if (fetchError) {
    logger.error('Admin unpin: failed to fetch quest', { questId, error: fetchError.message });
    return res.status(500).json({ error: 'Failed to fetch quest' });
  }

  if (!quest) {
    return res.status(404).json({ error: 'Quest not found' });
  }

  const { error: updateError } = await supabaseService
    .schema('validation_quests')
    .from('verification_quests')
    .update({ pinned: false, updated_at: new Date().toISOString() })
    .eq('id', questId);

  if (updateError) {
    logger.error('Admin unpin: failed to update quest', { questId, error: updateError.message });
    return res.status(500).json({ error: 'Failed to unpin quest' });
  }

  await logAdminAction({
    admin_user_id: req.userId,
    action_type: 'quest_unpinned',
    target_type: 'quest',
    target_id: questId,
    reasoning: `Admin unpinned quest`,
  });

  try {
    await invalidateAllFeedCaches();
  } catch (err) {
    logger.error('Failed to invalidate feed caches after quest unpin', { err });
  }

  return res.status(200).json({ success: true, quest_id: questId, pinned: false });
});

// ============================================================
// POST /api/admin/quests — ADMIN-01: Create quest
// ============================================================

router.post('/quests', requireAuth, requireStaff, async (req: any, res: any) => {
  const result = createAdminQuestSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(422).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid quest data',
        details: result.error.issues,
      },
    });
  }

  const row = buildQuestRow(result.data, req.userId);

  const { data: quest, error } = await supabaseService
    .schema('validation_quests')
    .from('verification_quests')
    .insert(row)
    .select()
    .single();

  if (error) {
    logger.error('Admin failed to create quest', { error: error.message, code: error.code });
    return res.status(500).json({ error: 'Failed to create quest' });
  }

  await logAdminAction({
    admin_user_id: req.userId,
    action_type: 'quest_created',
    target_type: 'quest',
    target_id: (quest as VerificationQuest).id,
    reasoning: `Admin created quest: ${result.data.question_text}`,
    metadata: { gem_quest_type: result.data.gem_quest_type },
  });

  // Invalidate all feed caches — new quest may appear in any user's feed
  try {
    await invalidateAllFeedCaches();
  } catch (err) {
    logger.error('Failed to invalidate feed caches after quest creation', { err });
  }

  const q = quest as VerificationQuest;
  return res.status(201).json({
    id: q.id,
    type: q.type,
    question_text: q.question_text,
    difficulty_tier: q.difficulty_tier,
    geographic_scope: q.geographic_scope,
    xp_reward: q.xp_reward,
    gem_reward: q.gem_reward,
    priority_level: q.priority_level,
    status: q.status,
    submission_count: q.submission_count,
    gem_quest_type: q.gem_quest_type,
    bridging_waived: q.bridging_waived,
    is_bounty: q.gem_reward >= 30,
    created_at: q.created_at,
    updated_at: q.updated_at,
  });
});

// ============================================================
// GET /api/admin/quests/:id/submissions — ADMIN-02: View all submissions
// ============================================================

router.get('/quests/:id/submissions', requireAuth, requireStaff, async (req: any, res: any) => {
  const { data: submissions, error } = await supabaseService
    .schema('validation_quests')
    .from('verification_submissions')
    .select('id, user_id, submitter_type, answer_text, sources, outcome, created_at, veracity_suspended')
    .eq('quest_id', req.params.id)
    .order('created_at', { ascending: false });

  if (error) {
    logger.error('Admin failed to fetch submissions', {
      error: error.message,
      quest_id: req.params.id,
    });
    return res.status(500).json({ error: 'Failed to fetch submissions' });
  }

  return res.status(200).json(submissions ?? []);
});

// ============================================================
// POST /api/admin/users/:userId/age-waiver — ADMIN-04
// ============================================================

router.post('/users/:userId/age-waiver', requireAuth, requireStaff, async (req: any, res: any) => {
  const result = ageWaiverSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(422).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid request',
        details: result.error.issues,
      },
    });
  }

  const { userId } = req.params;

  // Check that the veracity profile exists
  const { data: profile, error: fetchError } = await supabaseService
    .schema('validation_quests')
    .from('user_veracity_profiles')
    .select('user_id')
    .eq('user_id', userId)
    .maybeSingle();

  if (fetchError) {
    logger.error('Failed to fetch user veracity profile', { error: fetchError.message });
    return res.status(500).json({ error: 'Failed to fetch user profile' });
  }

  if (!profile) {
    return res.status(404).json({ error: 'User veracity profile not found' });
  }

  const { error: updateError } = await supabaseService
    .schema('validation_quests')
    .from('user_veracity_profiles')
    .update({ age_waiver_granted: true })
    .eq('user_id', userId);

  if (updateError) {
    logger.error('Failed to grant age waiver', { error: updateError.message });
    return res.status(500).json({ error: 'Failed to grant age waiver' });
  }

  await logAdminAction({
    admin_user_id: req.userId,
    action_type: 'age_waiver_granted',
    target_type: 'user',
    target_id: userId,
    reasoning: result.data.reasoning,
  });

  return res.status(200).json({
    success: true,
    user_id: userId,
    age_waiver_granted: true,
  });
});

// ============================================================
// POST /api/admin/users/:userId/suspend — ADMIN-06: Suspend user
// ============================================================

router.post('/users/:userId/suspend', requireAuth, requireStaff, async (req: any, res: any) => {
  const result = suspendSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(422).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid request',
        details: result.error.issues,
      },
    });
  }

  const { userId } = req.params;

  // Check that the veracity profile exists
  const { data: profile, error: fetchError } = await supabaseService
    .schema('validation_quests')
    .from('user_veracity_profiles')
    .select('user_id')
    .eq('user_id', userId)
    .maybeSingle();

  if (fetchError) {
    logger.error('Failed to fetch user veracity profile for suspension', {
      error: fetchError.message,
    });
    return res.status(500).json({ error: 'Failed to fetch user profile' });
  }

  if (!profile) {
    return res.status(404).json({ error: 'User veracity profile not found' });
  }

  const { error: updateError } = await supabaseService
    .schema('validation_quests')
    .from('user_veracity_profiles')
    .update({
      restriction_state: 'suspended',
      restriction_reason: `Admin suspension: ${result.data.reasoning}`,
    })
    .eq('user_id', userId);

  if (updateError) {
    logger.error('Failed to suspend user', { error: updateError.message });
    return res.status(500).json({ error: 'Failed to suspend user' });
  }

  await logAdminAction({
    admin_user_id: req.userId,
    action_type: 'user_suspended',
    target_type: 'user',
    target_id: userId,
    reasoning: result.data.reasoning,
  });

  return res.status(200).json({ success: true, user_id: userId, restriction_state: 'suspended' });
});

// ============================================================
// POST /api/admin/users/:userId/unsuspend — ADMIN-06: Unsuspend user
// ============================================================

router.post('/users/:userId/unsuspend', requireAuth, requireStaff, async (req: any, res: any) => {
  const result = suspendSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(422).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid request',
        details: result.error.issues,
      },
    });
  }

  const { userId } = req.params;

  // Check that the veracity profile exists
  const { data: profile, error: fetchError } = await supabaseService
    .schema('validation_quests')
    .from('user_veracity_profiles')
    .select('user_id')
    .eq('user_id', userId)
    .maybeSingle();

  if (fetchError) {
    logger.error('Failed to fetch user veracity profile for unsuspension', {
      error: fetchError.message,
    });
    return res.status(500).json({ error: 'Failed to fetch user profile' });
  }

  if (!profile) {
    return res.status(404).json({ error: 'User veracity profile not found' });
  }

  const { error: updateError } = await supabaseService
    .schema('validation_quests')
    .from('user_veracity_profiles')
    .update({
      restriction_state: 'none',
      restriction_reason: null,
    })
    .eq('user_id', userId);

  if (updateError) {
    logger.error('Failed to unsuspend user', { error: updateError.message });
    return res.status(500).json({ error: 'Failed to unsuspend user' });
  }

  await logAdminAction({
    admin_user_id: req.userId,
    action_type: 'user_unsuspended',
    target_type: 'user',
    target_id: userId,
    reasoning: result.data.reasoning,
  });

  return res.status(200).json({ success: true, user_id: userId, restriction_state: 'none' });
});

// ============================================================
// GET /api/admin/ai-agents — ADMIN-07: AI agent accuracy stats
// ============================================================

router.get('/ai-agents', requireAuth, requireStaff, async (req: any, res: any) => {
  const { data: agents, error: agentsError } = await supabaseService
    .schema('validation_quests')
    .from('ai_agent_credentials')
    .select('id, agent_name, is_active')
    .eq('is_active', true);

  if (agentsError) {
    logger.error('Failed to fetch AI agents', { error: agentsError.message });
    return res.status(500).json({ error: 'Failed to fetch AI agents' });
  }

  if (!agents || agents.length === 0) {
    return res.status(200).json([]);
  }

  const stats = await Promise.all(
    agents.map(async (agent) => {
      const { data: submissions } = await supabaseService
        .schema('validation_quests')
        .from('verification_submissions')
        .select('outcome')
        .eq('user_id', agent.id);

      const all = submissions ?? [];
      const total_submissions = all.length;
      const correct_count = all.filter((s: any) => s.outcome === 'correct').length;
      const incorrect_count = all.filter((s: any) => s.outcome === 'incorrect').length;
      const pending_count = all.filter((s: any) => s.outcome === 'pending' || s.outcome === null).length;
      const resolved = correct_count + incorrect_count;
      const accuracy_rate = resolved > 0 ? Math.round((correct_count / resolved) * 100) : null;

      return {
        agent_id: agent.id,
        agent_name: agent.agent_name,
        total_submissions,
        correct_count,
        incorrect_count,
        pending_count,
        accuracy_rate,
      };
    }),
  );

  return res.status(200).json(stats);
});

// ============================================================
// PATCH /api/admin/quests/:id/priority — PRIO-01: Update quest priority
// ============================================================

router.patch('/quests/:id/priority', requireAuth, requireStaff, async (req: any, res: any) => {
  const questId = req.params.id;
  const { priority_level } = req.body;

  if (!['high', 'standard', 'low'].includes(priority_level)) {
    return res.status(400).json({ error: 'priority_level must be high, standard, or low' });
  }

  const { error } = await supabaseService
    .schema('validation_quests')
    .from('verification_quests')
    .update({ priority_level })
    .eq('id', questId);

  if (error) {
    logger.error('Admin priority update: failed', { questId, error: error.message });
    return res.status(500).json({ error: error.message });
  }

  await logAdminAction({
    admin_user_id: req.userId,
    action_type: 'priority_update',
    target_type: 'quest',
    target_id: questId,
    reasoning: `Admin set priority to ${priority_level}`,
    metadata: { priority_level },
  });

  try {
    await invalidateAllFeedCaches();
  } catch (err) {
    logger.error('Failed to invalidate feed caches after priority update', { err });
  }

  return res.status(200).json({ success: true });
});

// ============================================================
// GET /api/admin/quests/promotions — PROM-01: List recently promoted quests
// ============================================================

router.get('/quests/promotions', requireAuth, requireStaff, async (_req: any, res: any) => {
  const since = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();

  const { data, error } = await supabaseService
    .schema('validation_quests')
    .from('verification_quests')
    .select('id, question_text, jurisdiction_name, gem_quest_type, promoted_to_yellow_at, correct_answer')
    .not('promoted_to_yellow_at', 'is', null)
    .gte('promoted_to_yellow_at', since)
    .order('promoted_to_yellow_at', { ascending: false });

  if (error) {
    logger.error('Admin promotions: failed to fetch', { error: error.message });
    return res.status(500).json({ error: error.message });
  }

  return res.status(200).json({ promotions: data ?? [] });
});

// ============================================================
// POST /api/admin/quests/:id/revert — REVERT-01: Revert yellow quest back to red
// ============================================================

router.post('/quests/:id/revert', requireAuth, requireStaff, async (req: any, res: any) => {
  const questId = req.params.id;

  const { error } = await supabaseService
    .schema('validation_quests')
    .from('verification_quests')
    .update({
      correct_answer: null,
      gem_quest_type: 'red',
      promoted_to_yellow_at: null,
      status: 'active',
    })
    .eq('id', questId);

  if (error) {
    logger.error('Admin revert: failed', { questId, error: error.message });
    return res.status(500).json({ error: error.message });
  }

  await logAdminAction({
    admin_user_id: req.userId,
    action_type: 'revert_to_red',
    target_type: 'quest',
    target_id: questId,
    reasoning: 'Admin manually reverted yellow quest back to red',
    metadata: { reverted_at: new Date().toISOString() },
  });

  try {
    await invalidateAllFeedCaches();
  } catch (err) {
    logger.error('Failed to invalidate feed caches after quest revert', { err });
  }

  return res.status(200).json({ success: true });
});

// ============================================================
// POST /api/admin/quests/bulk — ADMIN-08: Bulk quest import
// ============================================================

router.post('/quests/bulk', requireAuth, requireStaff, async (req: any, res: any) => {
  const result = adminBulkQuestSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(422).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid bulk quest data',
        details: result.error.issues,
      },
    });
  }

  if (result.data.length === 0) {
    return res.status(201).json({ imported: 0, quests: [] });
  }

  const rows = result.data.map((questData) => buildQuestRow(questData, req.userId));

  const { data, error } = await supabaseService
    .schema('validation_quests')
    .from('verification_quests')
    .upsert(rows, { onConflict: 'question_text' })
    .select();

  if (error) {
    logger.error('Admin bulk import failed', { error: error.message, count: rows.length });
    return res.status(500).json({ error: 'Bulk import failed' });
  }

  // Use a sentinel target_id for bulk operations (no single target)
  await logAdminAction({
    admin_user_id: req.userId,
    action_type: 'bulk_import',
    target_type: 'bulk',
    target_id: '00000000-0000-0000-0000-000000000000',
    reasoning: `Admin bulk imported ${rows.length} quests`,
    metadata: { count: rows.length },
  });

  try {
    await invalidateAllFeedCaches();
  } catch (err) {
    logger.error('Failed to invalidate feed caches after bulk import', { err });
  }

  return res.status(201).json({ imported: (data ?? []).length, quests: data ?? [] });
});

// ============================================================
// POST /api/admin/quests/:id/override — ADMIN-03: Override conflicting consensus
// ============================================================

router.post('/quests/:id/override', requireAuth, requireStaff, async (req: any, res: any) => {
  const result = adminOverrideSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(422).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid override data',
        details: result.error.issues,
      },
    });
  }

  const questId = req.params.id;

  // Verify quest exists and is in a state that allows override
  const { data: quest, error: questFetchError } = await supabaseService
    .schema('validation_quests')
    .from('verification_quests')
    .select('id, status')
    .eq('id', questId)
    .maybeSingle();

  if (questFetchError) {
    logger.error('Admin override: failed to fetch quest', {
      questId,
      error: questFetchError.message,
    });
    return res.status(500).json({ error: 'Failed to fetch quest' });
  }

  if (!quest) {
    return res.status(404).json({ error: 'Quest not found' });
  }

  const questStatus = (quest as any).status;
  if (questStatus !== 'under_review' && questStatus !== 'active') {
    return res.status(422).json({
      error: {
        code: 'INVALID_STATUS',
        message: `Quest must be in under_review or active status to override (current: ${questStatus})`,
      },
    });
  }

  try {
    await executeAdminOverride({
      questId,
      adminUserId: req.userId,
      canonicalAnswer: result.data.canonical_answer,
      reasoning: result.data.reasoning,
    });
  } catch (err) {
    logger.error('Admin override: cascade failed', { questId, error: String(err) });
    return res.status(500).json({ error: 'Override cascade failed' });
  }

  return res.status(200).json({
    success: true,
    quest_id: questId,
    canonical_answer: result.data.canonical_answer,
    status: 'consensus_reached',
  });
});

// ============================================================
// POST /api/admin/contests/:id/resolve — ADMIN-05: Resolve contestation
// ============================================================

router.post('/contests/:id/resolve', requireAuth, requireStaff, async (req: any, res: any) => {
  const result = resolveContestSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(422).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid resolution data',
        details: result.error.issues,
      },
    });
  }

  const contestId = req.params.id;

  // Verify contest exists and is in a resolvable state
  const { data: contest, error: contestFetchError } = await supabaseService
    .schema('validation_quests')
    .from('quest_contests')
    .select('id, status')
    .eq('id', contestId)
    .maybeSingle();

  if (contestFetchError) {
    logger.error('Admin resolve contest: failed to fetch contest', {
      contestId,
      error: contestFetchError.message,
    });
    return res.status(500).json({ error: 'Failed to fetch contest' });
  }

  if (!contest) {
    return res.status(404).json({ error: 'Contest not found' });
  }

  const contestStatus = (contest as any).status;
  if (contestStatus !== 'pending' && contestStatus !== 'under_review') {
    return res.status(422).json({
      error: {
        code: 'INVALID_STATUS',
        message: `Contest must be in pending or under_review status (current: ${contestStatus})`,
      },
    });
  }

  try {
    await resolveContestation({
      contestId,
      adminUserId: req.userId,
      decision: result.data.decision,
      reasoning: result.data.reasoning,
    });
  } catch (err) {
    logger.error('Admin resolve contest: failed', { contestId, error: String(err) });
    return res.status(500).json({ error: 'Failed to resolve contest' });
  }

  const newStatus =
    result.data.decision === 'approve' ? 'resolved_overturned' : 'resolved_upheld';

  return res.status(200).json({
    success: true,
    contest_id: contestId,
    decision: result.data.decision,
    new_status: newStatus,
  });
});

export default router;
