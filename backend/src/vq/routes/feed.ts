/**
 * feed.ts
 * GET /api/feed         — Personalized quest feed with Redis cache-aside pattern.
 * GET /api/feed/bounty  — Bounty board: high-priority quests, pending submissions, earned bounties.
 *
 * Auth chain (both routes): requireAuth → requireNotSuspended → requireConnected
 *
 * Cache strategy:
 *   - Hit:  return cached JSON, cached: true
 *   - Miss: call Postgres RPC → cache result → return, cached: false
 *   - TTL:  FEED_CACHE_TTL (15 minutes)
 *   - Keys: feedCacheKey(userId) or onboardingCacheKey(userId)
 *
 * Cache invalidation hooks (best-effort, wrapped in try/catch):
 *   - On human submission:             submissions.ts → invalidateFeedCache
 *   - On veracity tier crossing:       veracityTracking.ts → invalidateFeedCache
 *   - On admin bounty quest creation:  Phase 7 integration point → invalidateAllFeedCaches
 */

import { Router } from 'express';
import { supabaseService } from '../lib/supabase.js';
import { redis } from '../lib/redis.js';
import { requireAuth } from '../middleware/auth.js';
import { requireConnected, requireNotSuspended } from '../middleware/tierGuards.js';
import { logger } from '../lib/logger.js';
import {
  FEED_CACHE_TTL,
  feedCacheKey,
  onboardingCacheKey,
  isOnboardingUser,
  getAllowedTiers,
  mapRpcResultToFeedItem,
  invalidateFeedCache,
} from '../services/feedScoring.js';
import {
  assignQuestsForUser,
  getSlotConfig,
  getNextRotationAt,
} from '../services/questRotation.js';
import type {
  FeedItem,
  FeedResponse,
  RotationInfo,
  BountyBoardResponse,
  PendingSubmission,
  EarnedBounty,
  CompletedSlot,
} from '../types/custom.js';
// Engine consolidation, Phase 4: build the /api/account/me composite in-process.
import { getAccountMe } from '../../lib/accountMeService.js';

const router = Router();

// Apply full auth chain to all feed routes
router.use(requireAuth, requireNotSuspended, requireConnected);

// ============================================================
// GET / — Personalized quest feed
// ============================================================

router.get('/', async (req: any, res: any) => {
  const userId = req.userId as string;

  // --------------------------------------------------------
  // Fetch account data from Accounts (jurisdiction + VR gating fields)
  // No lat/lng from client — Connected Accounts already have location on file.
  // --------------------------------------------------------
  let hasLocation = false;
  let userDistricts: string[] | null = null;
  let verificationRating: number | null = null;
  let redGemQuestsUnlocked = true; // default open for backwards compatibility
  let userLevel = 1;
  try {
    // In-process (Phase 4): build the account composite directly instead of an HTTP
    // loopback to /api/account/me. Fail open on errors (defaults above stay).
    const meData = await getAccountMe(req.accessToken, req.userId) as {
      jurisdiction?: {
        congressional_district_name: string | null;
        state_senate_district_name: string | null;
        state_house_district_name: string | null;
        county_name: string | null;
        school_district_name: string | null;
      } | null;
      vq_hold_active?: boolean;
      vq_hold_until?: string | null;
      red_gem_quests_unlocked?: boolean;
      verification_rating?: number | null;
      xp?: { level: number } | null;
    };

    // VQ hold check — MUST come before cache read
    if (meData.vq_hold_active === true) {
      return res.status(403).json({
        error: 'Verification hold active',
        code: 'VQ_HOLD_ACTIVE',
        hold_until: meData.vq_hold_until ?? null,
      });
    }

    if (meData.jurisdiction) {
      hasLocation = true;
      userDistricts = Object.values(meData.jurisdiction).filter(Boolean) as string[];
    }
    verificationRating = meData.verification_rating ?? null;
    redGemQuestsUnlocked = meData.red_gem_quests_unlocked ?? true;
    userLevel = meData.xp?.level ?? 1;
  } catch (err) {
    logger.warn('getAccountMe for feed failed', { userId, error: String(err) });
  }

  // --------------------------------------------------------
  // Step 1: Fetch user veracity profile (total_submissions + accuracy_rate)
  // --------------------------------------------------------
  let totalSubmissions = 0;
  let accuracyRate: number | null = null;

  try {
    const profileResult = await supabaseService
      .schema('validation_quests')
      .from('user_veracity_profiles')
      .select('total_submissions, accuracy_rate')
      .eq('user_id', userId)
      .maybeSingle();

    if (
      profileResult &&
      typeof profileResult === 'object' &&
      'data' in profileResult &&
      profileResult.data
    ) {
      const profile = (profileResult as { data: unknown }).data as {
        total_submissions: number;
        accuracy_rate: number | null;
      };
      totalSubmissions = profile.total_submissions ?? 0;
      accuracyRate = profile.accuracy_rate ?? null;
    }
  } catch (err) {
    // No profile — treat as new user (totalSubmissions=0, accuracyRate=null)
    logger.warn('Failed to fetch veracity profile for feed', { userId, error: String(err) });
  }

  // --------------------------------------------------------
  // Step 2: Determine onboarding status and pick cache key
  // --------------------------------------------------------
  const isOnboarding = isOnboardingUser(totalSubmissions, accuracyRate);
  const cacheKey = isOnboarding ? onboardingCacheKey(userId) : feedCacheKey(userId);

  // --------------------------------------------------------
  // Step 3: Fetch completed slots (always fresh — never cached in Redis)
  // Finds quests the user has already submitted in the current rotation window.
  // --------------------------------------------------------
  let completedSlots: CompletedSlot[] = [];
  try {
    // 1. Get active (non-expired) assignments for this user
    const assignmentsResult = await supabaseService
      .schema('validation_quests')
      .from('user_quest_assignments')
      .select('quest_id')
      .eq('user_id', userId)
      .gt('expires_at', new Date().toISOString()) as {
        data: Array<{ quest_id: string }> | null;
        error: unknown;
      };

    const activeAssignedIds = (assignmentsResult.data ?? []).map((a) => a.quest_id);

    if (activeAssignedIds.length > 0) {
      // 2. Find which of those the user has submitted to
      const submissionsResult = await supabaseService
        .schema('validation_quests')
        .from('verification_submissions')
        .select('quest_id, created_at')
        .eq('user_id', userId)
        .in('quest_id', activeAssignedIds) as {
          data: Array<{ quest_id: string; created_at: string }> | null;
          error: unknown;
        };

      const submittedRows = submissionsResult.data ?? [];

      if (submittedRows.length > 0) {
        const submittedQuestIds = submittedRows.map((s) => s.quest_id);
        const submittedAtMap = new Map<string, string>();
        for (const s of submittedRows) {
          // Keep earliest submission if multiple exist (dedup)
          if (!submittedAtMap.has(s.quest_id)) {
            submittedAtMap.set(s.quest_id, s.created_at);
          }
        }

        // 3. Fetch quest text for submitted quest IDs
        const questTextsResult = await supabaseService
          .schema('validation_quests')
          .from('verification_quests')
          .select('id, question_text, gem_quest_type')
          .in('id', submittedQuestIds) as {
            data: Array<{ id: string; question_text: string; gem_quest_type: string }> | null;
            error: unknown;
          };

        const questTextMap = new Map<string, string>();
        const questGemTypeMap = new Map<string, string>();
        for (const q of questTextsResult.data ?? []) {
          questTextMap.set(q.id, q.question_text);
          questGemTypeMap.set(q.id, q.gem_quest_type);
        }

        // 4. Compute gem_type via consensus_records (same pattern as Step 6)
        const completedConsensusResult = await supabaseService
          .schema('validation_quests')
          .from('consensus_records')
          .select('quest_id, confidence_level')
          .in('quest_id', submittedQuestIds) as {
            data: Array<{ quest_id: string; confidence_level: string }> | null;
            error: unknown;
          };

        const completedConsensusMap = new Map<string, string>();
        for (const cr of completedConsensusResult.data ?? []) {
          completedConsensusMap.set(cr.quest_id, cr.confidence_level);
        }

        // 5. Build CompletedSlot array
        completedSlots = submittedQuestIds
          .filter((id) => questTextMap.has(id))
          .map((id) => {
            const storedGemQuestType = questGemTypeMap.get(id);
            const confidenceLevel = completedConsensusMap.get(id);
            const gemType: 'yellow' | 'red' =
              storedGemQuestType === 'yellow'
                ? 'yellow'
                : !confidenceLevel || confidenceLevel === 'conflicting'
                  ? 'red'
                  : 'yellow';
            return {
              quest_id: id,
              question_text: questTextMap.get(id)!,
              gem_type: gemType,
              submitted_at: submittedAtMap.get(id)!,
            };
          });
      }
    }
  } catch (err) {
    logger.warn('Failed to fetch completed slots for feed', { userId, error: String(err) });
    completedSlots = [];
  }

  // --------------------------------------------------------
  // Step 4: Check Redis cache
  // --------------------------------------------------------
  try {
    const cached = await redis.get(cacheKey);
    if (cached !== null) {
      const parsed = JSON.parse(cached) as { feedItems: FeedItem[]; rotationInfo: RotationInfo };
      // rotationInfo.next_rotation_at may be stale if cached near boundary — recompute cheaply
      const freshRotationInfo: RotationInfo = {
        next_rotation_at: getNextRotationAt().toISOString(),
        slot_count: getSlotConfig(userLevel).maxSlots,
        slots_used: parsed.feedItems.length,
      };
      const response: FeedResponse = {
        quests: parsed.feedItems,
        completed_slots: completedSlots,
        cached: true,
        is_onboarding: isOnboarding,
        rotation_info: freshRotationInfo,
        has_location: hasLocation,
        verification_rating: verificationRating,
        red_gem_quests_unlocked: redGemQuestsUnlocked,
      };
      return res.status(200).json(response);
    }
  } catch (err) {
    // Cache read error — proceed to assignment
    logger.warn('Redis cache read failed for feed', { userId, cacheKey, error: String(err) });
  }

  // --------------------------------------------------------
  // Step 5: Cache miss — assign quest slots
  // --------------------------------------------------------
  let assignedQuestIds: string[];
  try {
    assignedQuestIds = await assignQuestsForUser(userId, userLevel, userDistricts, redGemQuestsUnlocked);
  } catch (err) {
    logger.error('Failed to assign quests for user', { userId, error: String(err) });
    return res.status(500).json({ error: 'Failed to load quest feed' });
  }

  // --------------------------------------------------------
  // Step 6: Fetch quest details for assigned IDs
  // --------------------------------------------------------
  let feedItems: FeedItem[] = [];

  if (assignedQuestIds.length > 0) {
    const questsResult = await supabaseService
      .schema('validation_quests')
      .from('verification_quests')
      .select('id, question_text, gem_reward, difficulty_tier, gem_quest_type')
      .in('id', assignedQuestIds)
      .eq('status', 'active') as {
        data: Array<{
          id: string;
          question_text: string;
          gem_reward: number;
          difficulty_tier: number;
          gem_quest_type: string;
        }> | null;
        error: unknown;
      };

    const questRows = questsResult.data ?? [];

    // Fetch consensus records to compute gem_type
    const questIds = questRows.map((q) => q.id);
    let gemTypeMap = new Map<string, 'yellow' | 'red'>();

    if (questIds.length > 0) {
      const consensusResult = await supabaseService
        .schema('validation_quests')
        .from('consensus_records')
        .select('quest_id, confidence_level')
        .in('quest_id', questIds) as {
          data: Array<{ quest_id: string; confidence_level: string }> | null;
          error: unknown;
        };

      const consensusMap = new Map<string, string>();
      for (const cr of consensusResult.data ?? []) {
        consensusMap.set(cr.quest_id, cr.confidence_level);
      }

      for (const q of questRows) {
        const confidenceLevel = consensusMap.get(q.id);
        // Yellow quests (immediate-grading) always show as yellow; red/discovery quests
        // use consensus state to compute display type.
        const gemType: 'yellow' | 'red' =
          q.gem_quest_type === 'yellow'
            ? 'yellow'
            : !confidenceLevel || confidenceLevel === 'conflicting'
              ? 'red'
              : 'yellow';
        gemTypeMap.set(q.id, gemType);
      }
    }

    feedItems = questRows.map((q) => ({
      quest_id: q.id,
      question_text: q.question_text,
      gem_type: gemTypeMap.get(q.id) ?? 'red',
      gem_count: q.gem_reward,
      composite_score: 0,
      score_breakdown: { geo: 0, difficulty: 0, confidence: 0, bounty: 0 },
    }));
  }

  // --------------------------------------------------------
  // Step 7: Build rotation info and cache result
  // --------------------------------------------------------
  const rotationInfo: RotationInfo = {
    next_rotation_at: getNextRotationAt().toISOString(),
    slot_count: getSlotConfig(userLevel).maxSlots,
    slots_used: feedItems.length,
  };

  // Cache result (best-effort)
  try {
    await redis.set(cacheKey, JSON.stringify({ feedItems, rotationInfo }), FEED_CACHE_TTL);
  } catch (err) {
    logger.warn('Failed to cache feed result', { userId, cacheKey, error: String(err) });
  }

  const response: FeedResponse = {
    quests: feedItems,
    completed_slots: completedSlots,
    cached: false,
    is_onboarding: isOnboarding,
    rotation_info: rotationInfo,
    has_location: hasLocation,
    verification_rating: verificationRating,
    red_gem_quests_unlocked: redGemQuestsUnlocked,
  };
  return res.status(200).json(response);
});

// ============================================================
// POST /initialize — Eager session initialization
// Assigns quest slots for the user if none exist. Called by
// the frontend immediately after SSO session establishment so
// quests are ready regardless of which page the user lands on.
// ============================================================

router.post('/initialize', async (req: any, res: any) => {
  const userId = req.userId as string;

  // Fetch account context (level + districts + red gate)
  let userLevel = 1;
  let userDistricts: string[] | null = null;
  let redGemQuestsUnlocked = true;
  try {
    // In-process (Phase 4): build the account composite directly. Fail open.
    const meData = await getAccountMe(req.accessToken, req.userId) as {
      jurisdiction?: {
        congressional_district_name: string | null;
        state_senate_district_name: string | null;
        state_house_district_name: string | null;
        county_name: string | null;
        school_district_name: string | null;
      } | null;
      red_gem_quests_unlocked?: boolean;
      xp?: { level: number } | null;
    };
    if (meData.jurisdiction) {
      userDistricts = Object.values(meData.jurisdiction).filter(Boolean) as string[];
    }
    redGemQuestsUnlocked = meData.red_gem_quests_unlocked ?? true;
    userLevel = meData.xp?.level ?? 1;
  } catch (err) {
    logger.warn('getAccountMe in session initialize failed', { userId, error: String(err) });
  }

  // Check for existing active assignments — zero means first session
  let isFirstSession = false;
  try {
    const countResult = await supabaseService
      .schema('validation_quests')
      .from('user_quest_assignments')
      .select('quest_id', { count: 'exact', head: true })
      .eq('user_id', userId)
      .gt('expires_at', new Date().toISOString()) as {
        count: number | null;
        error: unknown;
      };
    isFirstSession = (countResult.count ?? 0) === 0;
  } catch (err) {
    logger.warn('Failed to count assignments in session initialize', { userId, error: String(err) });
  }

  if (!isFirstSession) {
    return res.status(200).json({ is_first_session: false, quests_assigned: 0 });
  }

  let questsAssigned = 0;
  try {
    const assigned = await assignQuestsForUser(userId, userLevel, userDistricts, redGemQuestsUnlocked);
    questsAssigned = assigned.length;
    await invalidateFeedCache(userId);
  } catch (err) {
    logger.error('Failed to assign quests in session initialize', { userId, error: String(err) });
  }

  return res.status(200).json({ is_first_session: true, quests_assigned: questsAssigned });
});

// ============================================================
// GET /bounty — Bounty board
// ============================================================

router.get('/bounty', async (req: any, res: any) => {
  const userId = req.userId as string;

  try {
    // Three parallel queries
    const [highPriorityResult, pendingSubsResult, earnedBountiesResult] = await Promise.all([
      // a. High-priority / high-gem-reward quests
      supabaseService
        .schema('validation_quests')
        .from('verification_quests')
        .select('id, question_text, gem_reward, geographic_scope, priority_level')
        .eq('status', 'active')
        .or('priority_level.eq.high,gem_reward.gte.30'),

      // b. User's pending submissions (no outcome yet)
      supabaseService
        .schema('validation_quests')
        .from('verification_submissions')
        .select('id, quest_id, answer_text, created_at')
        .eq('user_id', userId)
        .is('outcome', null),

      // c. User's earned bounties (correct submissions)
      supabaseService
        .schema('validation_quests')
        .from('verification_submissions')
        .select('id, quest_id, outcome, created_at')
        .eq('user_id', userId)
        .eq('outcome', 'correct'),
    ]);

    // --------------------------------------------------------
    // Process high-priority quests
    // --------------------------------------------------------
    const highPriorityRaw = highPriorityResult.data ?? [];

    // Find quests user has already submitted to (to exclude them)
    const highPriorityQuestIds = highPriorityRaw.map((q) => q.id);
    let alreadySubmittedIds: string[] = [];

    if (highPriorityQuestIds.length > 0) {
      const submittedResult = await supabaseService
        .schema('validation_quests')
        .from('verification_submissions')
        .select('quest_id')
        .eq('user_id', userId)
        .in('quest_id', highPriorityQuestIds) as {
          data: Array<{ quest_id: string }> | null;
          error: unknown;
        };

      alreadySubmittedIds = (submittedResult.data ?? []).map((s) => s.quest_id);
    }

    // Filter out already-submitted quests
    const filteredHighPriority = highPriorityRaw.filter(
      (q) => !alreadySubmittedIds.includes(q.id)
    );

    // Fetch consensus records to determine gem_type
    let gemTypeMap: Map<string, 'yellow' | 'red'> = new Map();
    if (filteredHighPriority.length > 0) {
      const filteredIds = filteredHighPriority.map((q) => q.id);
      const consensusResult = await supabaseService
        .schema('validation_quests')
        .from('consensus_records')
        .select('quest_id, confidence_level')
        .in('quest_id', filteredIds) as {
          data: Array<{ quest_id: string; confidence_level: string }> | null;
          error: unknown;
        };

      const consensusMap = new Map<string, string>();
      for (const cr of consensusResult.data ?? []) {
        consensusMap.set(cr.quest_id, cr.confidence_level);
      }

      for (const q of filteredHighPriority) {
        const confidenceLevel = consensusMap.get(q.id);
        // No consensus or conflicting → red (civic impact); otherwise yellow (accuracy)
        const gemType: 'yellow' | 'red' =
          !confidenceLevel || confidenceLevel === 'conflicting' ? 'red' : 'yellow';
        gemTypeMap.set(q.id, gemType);
      }
    }

    const highPriorityItems: FeedItem[] = filteredHighPriority.map((q) => ({
      quest_id: q.id,
      question_text: q.question_text,
      gem_type: gemTypeMap.get(q.id) ?? 'red',
      gem_count: q.gem_reward,
      composite_score: 0,
      score_breakdown: { geo: 0, difficulty: 0, confidence: 0, bounty: 0 },
    }));

    // --------------------------------------------------------
    // Process pending submissions
    // --------------------------------------------------------
    const pendingSubsRaw = pendingSubsResult.data ?? [];
    let pendingSubmissions: PendingSubmission[] = [];

    if (pendingSubsRaw.length > 0) {
      const pendingQuestIds = [...new Set(pendingSubsRaw.map((s) => s.quest_id))];
      const questTextsResult = await supabaseService
        .schema('validation_quests')
        .from('verification_quests')
        .select('id, question_text')
        .in('id', pendingQuestIds) as {
          data: Array<{ id: string; question_text: string }> | null;
          error: unknown;
        };

      const questTextMap = new Map<string, string>();
      for (const q of questTextsResult.data ?? []) {
        questTextMap.set(q.id, q.question_text);
      }

      pendingSubmissions = pendingSubsRaw.map((s) => ({
        submission_id: s.id,
        quest_id: s.quest_id,
        question_text: questTextMap.get(s.quest_id) ?? '',
        answer_text: s.answer_text,
        submitted_at: s.created_at,
      }));
    }

    // --------------------------------------------------------
    // Process earned bounties
    // --------------------------------------------------------
    const earnedBountiesRaw = earnedBountiesResult.data ?? [];
    let earnedBounties: EarnedBounty[] = [];

    if (earnedBountiesRaw.length > 0) {
      const earnedQuestIds = [...new Set(earnedBountiesRaw.map((s) => s.quest_id))];
      const earnedQuestsResult = await supabaseService
        .schema('validation_quests')
        .from('verification_quests')
        .select('id, question_text, gem_reward, priority_level')
        .in('id', earnedQuestIds) as {
          data: Array<{
            id: string;
            question_text: string;
            gem_reward: number;
            priority_level: string;
          }> | null;
          error: unknown;
        };

      const earnedQuestMap = new Map<
        string,
        { question_text: string; gem_reward: number; priority_level: string }
      >();
      for (const q of earnedQuestsResult.data ?? []) {
        earnedQuestMap.set(q.id, {
          question_text: q.question_text,
          gem_reward: q.gem_reward,
          priority_level: q.priority_level,
        });
      }

      // Fetch consensus records for earned quest IDs to determine gem_type
      const earnedConsensusResult = await supabaseService
        .schema('validation_quests')
        .from('consensus_records')
        .select('quest_id, confidence_level, finalized_at')
        .in('quest_id', earnedQuestIds) as {
          data: Array<{
            quest_id: string;
            confidence_level: string;
            finalized_at: string | null;
          }> | null;
          error: unknown;
        };

      const earnedConsensusMap = new Map<
        string,
        { confidence_level: string; finalized_at: string | null }
      >();
      for (const cr of earnedConsensusResult.data ?? []) {
        earnedConsensusMap.set(cr.quest_id, {
          confidence_level: cr.confidence_level,
          finalized_at: cr.finalized_at,
        });
      }

      // Filter to bounty quests only (priority_level = 'high' OR gem_reward >= 30)
      const bountySubmissions = earnedBountiesRaw.filter((s) => {
        const quest = earnedQuestMap.get(s.quest_id);
        if (!quest) return false;
        return quest.priority_level === 'high' || quest.gem_reward >= 30;
      });

      earnedBounties = bountySubmissions.map((s) => {
        const quest = earnedQuestMap.get(s.quest_id)!;
        const consensusInfo = earnedConsensusMap.get(s.quest_id);
        const gemType: 'yellow' | 'red' =
          !consensusInfo || consensusInfo.confidence_level === 'conflicting' ? 'red' : 'yellow';

        return {
          submission_id: s.id,
          quest_id: s.quest_id,
          question_text: quest.question_text,
          gem_reward: quest.gem_reward,
          gem_type: gemType,
          outcome: 'correct' as const,
          finalized_at: consensusInfo?.finalized_at ?? null,
        };
      });
    }

    const response: BountyBoardResponse = {
      high_priority: highPriorityItems,
      pending_submissions: pendingSubmissions,
      earned_bounties: earnedBounties,
    };

    return res.status(200).json(response);
  } catch (err) {
    logger.error('Failed to load bounty board', { userId, error: String(err) });
    return res.status(500).json({ error: 'Failed to load bounty board' });
  }
});

export default router;
