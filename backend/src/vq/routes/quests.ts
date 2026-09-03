import { Router } from 'express';
import { supabaseService } from '../lib/supabase.js';
import { requireAuth } from '../middleware/auth.js';
import { requireConnected, requireNotSuspended } from '../middleware/tierGuards.js';
import { createQuestSchema } from '../types/api.js';
import type { QuestResponse } from '../types/api.js';
import { DIFFICULTY_REWARDS } from '../types/custom.js';
import type { VerificationQuest } from '../types/database.types.js';
import { logger } from '../lib/logger.js';

const router = Router();

/**
 * Map a database verification_quest row to the API QuestResponse shape.
 * is_bounty: true when gem_reward >= 30 (bounty threshold).
 */
function toQuestResponse(quest: VerificationQuest, gemType: 'yellow' | 'red'): QuestResponse {
  return {
    id: quest.id,
    type: quest.type,
    question_text: quest.question_text,
    difficulty_tier: quest.difficulty_tier,
    geographic_scope: quest.geographic_scope,
    xp_reward: quest.xp_reward,
    gem_reward: quest.gem_reward,
    priority_level: quest.priority_level,
    status: quest.status,
    submission_count: quest.submission_count,
    is_bounty: quest.gem_reward >= 30,
    gem_type: gemType,
    politician_id: (quest as any).politician_id ?? null,
    topic_id: (quest as any).topic_id ?? null,
    confirmed_value: (quest as any).confirmed_value ?? null,
    created_at: quest.created_at,
    updated_at: quest.updated_at,
  };
}

// ============================================================
// POST /api/quests — Create a new verification quest
// ============================================================

router.post('/', requireAuth, requireNotSuspended, requireConnected, async (req: any, res: any) => {
  // Validate request body with Zod
  const result = createQuestSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(422).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid quest data',
        details: result.error.issues,
      },
    });
  }

  const {
    type,
    question_text,
    difficulty_tier,
    geographic_scope,
    jurisdiction_geometry,
    priority_level,
    gem_reward_override,
  } = result.data;

  // Derive rewards from difficulty tier
  const rewards = DIFFICULTY_REWARDS[difficulty_tier];

  // Bounty logic: gem_reward_override >= 30 sets custom gem reward and forces high priority
  const gem_reward =
    gem_reward_override !== undefined && gem_reward_override >= 30
      ? gem_reward_override
      : rewards.gems;

  const effective_priority_level =
    gem_reward_override !== undefined && gem_reward_override >= 30
      ? ('high' as const)
      : priority_level;

  // Build the row to insert
  const row: Record<string, unknown> = {
    type,
    question_text,
    difficulty_tier,
    geographic_scope,
    xp_reward: rewards.xp,
    gem_reward,
    priority_level: effective_priority_level,
    status: 'active',
    created_by: req.userId,
  };

  // Add PostGIS geometry if provided — stored as WKT with SRID
  if (jurisdiction_geometry) {
    const { lat, lng } = jurisdiction_geometry;
    row.jurisdiction_geometry = `SRID=4326;POINT(${lng} ${lat})`;
  }

  const { data: quest, error } = await supabaseService
    .schema('validation_quests')
    .from('verification_quests')
    .insert(row)
    .select()
    .single();

  if (error) {
    logger.error('Failed to create quest', { error: error.message, code: error.code });
    return res.status(500).json({ error: 'Failed to create quest' });
  }

  return res.status(201).json(toQuestResponse(quest as VerificationQuest, 'red'));
});

// ============================================================
// GET /api/quests/:id — Read a quest by ID
// ============================================================

router.get('/:id', async (req: any, res: any) => {
  const { data: quest, error } = await supabaseService
    .schema('validation_quests')
    .from('verification_quests')
    .select('*')
    .eq('id', req.params.id)
    .single();

  if (error) {
    // PGRST116 = "The result contains 0 rows" (not found)
    if (error.code === 'PGRST116') {
      return res.status(404).json({ error: 'Quest not found' });
    }
    logger.error('Failed to fetch quest', { error: error.message, code: error.code, id: req.params.id });
    return res.status(500).json({ error: 'Failed to fetch quest' });
  }

  // Compute gem_type from consensus state — same logic as feed RPC:
  // red = no consensus yet or conflicting, yellow = progressing toward consensus
  const { data: consensus } = await supabaseService
    .schema('validation_quests')
    .from('consensus_records')
    .select('confidence_level')
    .eq('quest_id', req.params.id)
    .maybeSingle();

  const questRow = quest as VerificationQuest & { gem_quest_type?: string };
  const gemType: 'yellow' | 'red' =
    questRow.gem_quest_type === 'yellow'
      ? 'yellow'
      : !consensus || consensus.confidence_level === 'conflicting'
        ? 'red'
        : 'yellow';

  return res.status(200).json(toQuestResponse(quest as VerificationQuest, gemType));
});

export default router;
