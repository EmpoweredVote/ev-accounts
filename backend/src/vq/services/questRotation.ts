/**
 * questRotation.ts
 * Slot-based quest rotation system.
 *
 * Each user has a fixed number of quest slots (3 at levels 1-4, 5 at levels 5+)
 * that are filled with eligible quests and refresh daily at 4am UTC.
 *
 * Exports:
 *   getSlotConfig      — slot count + red quest unlock by level
 *   getNextRotationAt  — next 4am UTC boundary
 *   assignQuestsForUser — fill a user's assignment slots for the current rotation window
 *   runRotationPass    — system-wide sweep called by the 4am cron
 */

import { supabaseService } from '../lib/supabase.js';
import { isOnboardingUser, invalidateFeedCache } from './feedScoring.js';
import { logger } from '../lib/logger.js';

// ============================================================
// Slot configuration
// ============================================================

export interface SlotConfig {
  maxSlots: number;
  allowRed: boolean;
}

/**
 * Returns the slot configuration for a given user level.
 * - Level 1–4:  3 slots, no red quests
 * - Level 5–9:  5 slots, no red quests
 * - Level 10+:  5 slots, red quests unlocked
 */
export function getSlotConfig(level: number): SlotConfig {
  if (level >= 10) {
    return { maxSlots: 5, allowRed: true };
  }
  if (level >= 5) {
    return { maxSlots: 5, allowRed: false };
  }
  return { maxSlots: 3, allowRed: false };
}

// ============================================================
// Rotation window boundary
// ============================================================

/**
 * Returns the next 4am UTC boundary from the current time.
 * If current UTC time is before 4am, returns today at 4am UTC.
 * Otherwise returns tomorrow at 4am UTC.
 */
export function getNextRotationAt(): Date {
  const now = new Date();
  const todayAt4am = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), 4, 0, 0, 0),
  );

  if (now < todayAt4am) {
    return todayAt4am;
  }

  // Tomorrow at 4am UTC
  const tomorrow = new Date(todayAt4am);
  tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);
  return tomorrow;
}

// ============================================================
// Fisher-Yates shuffle
// ============================================================

function shuffle<T>(arr: T[]): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

// ============================================================
// Per-user assignment
// ============================================================

/**
 * Ensure a user has their quest slots filled for the current rotation window.
 *
 * Idempotent within a rotation window: if the user already has maxSlots active
 * assignments, returns them unchanged. Otherwise fills empty slots from the
 * eligible quest pool (personalized or onboarding feed RPC result).
 *
 * Returns: array of active quest_ids (existing + newly assigned).
 */
export async function assignQuestsForUser(
  userId: string,
  level: number,
  districts?: string[] | null,
  allowRed?: boolean,
): Promise<string[]> {
  const nextRotationAt = getNextRotationAt();
  const slotConfig = getSlotConfig(level);
  // VR gate overrides level-based allowRed — if explicitly passed, it takes precedence
  if (allowRed !== undefined) {
    slotConfig.allowRed = allowRed;
  }

  // --------------------------------------------------------
  // Step 1: Delete expired assignments for this user
  // --------------------------------------------------------
  await supabaseService
    .schema('validation_quests')
    .from('user_quest_assignments')
    .delete()
    .eq('user_id', userId)
    .lte('expires_at', new Date().toISOString());

  // --------------------------------------------------------
  // Step 2: Fetch active assignments
  // --------------------------------------------------------
  const activeResult = await supabaseService
    .schema('validation_quests')
    .from('user_quest_assignments')
    .select('quest_id')
    .eq('user_id', userId)
    .gt('expires_at', new Date().toISOString()) as {
      data: Array<{ quest_id: string }> | null;
      error: unknown;
    };

  let existingQuestIds: string[] = (activeResult.data ?? []).map((row) => row.quest_id);

  // --------------------------------------------------------
  // Step 2b: Remove already-submitted quests from active assignments
  // Assignments persist until rotation expiry, not until submission. A user
  // who submits a quest mid-rotation still has it in user_quest_assignments.
  // Query submissions now and clean up any stale assignment rows so they
  // don't consume slot capacity or appear in the active feed.
  // --------------------------------------------------------
  if (existingQuestIds.length > 0) {
    const submittedActiveResult = await supabaseService
      .schema('validation_quests')
      .from('verification_submissions')
      .select('quest_id')
      .eq('user_id', userId)
      .in('quest_id', existingQuestIds) as {
        data: Array<{ quest_id: string }> | null;
        error: unknown;
      };

    const submittedActiveSet = new Set(
      (submittedActiveResult.data ?? []).map((s) => s.quest_id),
    );

    if (submittedActiveSet.size > 0) {
      existingQuestIds = existingQuestIds.filter((id) => !submittedActiveSet.has(id));

      await supabaseService
        .schema('validation_quests')
        .from('user_quest_assignments')
        .delete()
        .eq('user_id', userId)
        .in('quest_id', Array.from(submittedActiveSet));

      logger.info('Cleaned submitted quests from active assignments', {
        userId,
        count: submittedActiveSet.size,
      });

      // Slots freed by submission are spent for this rotation — don't refill them.
      // The user's daily quota was set at the start of the rotation; completing a
      // quest doesn't earn an extra slot, it just removes that quest from the feed.
      return existingQuestIds;
    }
  }

  // If already at capacity, return existing assignments
  if (existingQuestIds.length >= slotConfig.maxSlots) {
    return existingQuestIds;
  }

  const needed = slotConfig.maxSlots - existingQuestIds.length;

  // --------------------------------------------------------
  // Step 3: Fetch veracity profile to determine onboarding status
  // --------------------------------------------------------
  let totalSubmissions = 0;
  let accuracyRate: number | null = null;

  try {
    const profileResult = await supabaseService
      .schema('validation_quests')
      .from('user_veracity_profiles')
      .select('total_submissions, accuracy_rate')
      .eq('user_id', userId)
      .maybeSingle() as {
        data: { total_submissions: number; accuracy_rate: number | null } | null;
        error: unknown;
      };

    if (profileResult.data) {
      totalSubmissions = profileResult.data.total_submissions ?? 0;
      accuracyRate = profileResult.data.accuracy_rate ?? null;
    }
  } catch (err) {
    logger.warn('Failed to fetch veracity profile in assignQuestsForUser', {
      userId,
      error: String(err),
    });
  }

  const isOnboarding = isOnboardingUser(totalSubmissions, accuracyRate);

  // --------------------------------------------------------
  // Step 4: Fetch candidate quest IDs
  // When red quests are not allowed, query yellow quests directly — the feed
  // RPCs use LIMIT 15 and yellow quests are rare enough to be crowded out by
  // red quests in the scored result set.
  // --------------------------------------------------------
  const existingSet = new Set(existingQuestIds);
  let candidateIds: string[];

  if (!slotConfig.allowRed) {
    // Direct query: all active yellow quests (small set — typically < 20)
    const [yellowResult, submittedResult] = await Promise.all([
      supabaseService
        .schema('validation_quests')
        .from('verification_quests')
        .select('id')
        .eq('status', 'active')
        .eq('gem_quest_type', 'yellow') as unknown as Promise<{ data: Array<{ id: string }> | null; error: unknown }>,
      supabaseService
        .schema('validation_quests')
        .from('verification_submissions')
        .select('quest_id')
        .eq('user_id', userId) as unknown as Promise<{ data: Array<{ quest_id: string }> | null; error: unknown }>,
    ]);

    const submittedSet = new Set((submittedResult.data ?? []).map((s) => s.quest_id));
    const allYellow = (yellowResult.data ?? []).map((r) => r.id);
    candidateIds = allYellow.filter((id) => !existingSet.has(id) && !submittedSet.has(id));
  } else {
    // Use scored RPC for mixed red+yellow pool
    let rpcResult: { data: unknown[] | null; error: unknown };

    if (isOnboarding) {
      rpcResult = await supabaseService
        .schema('validation_quests')
        .rpc('get_onboarding_feed', {
          p_user_id: userId,
          p_user_districts: districts ?? null,
        }) as { data: unknown[] | null; error: unknown };
    } else {
      rpcResult = await supabaseService
        .schema('validation_quests')
        .rpc('get_personalized_feed', {
          p_user_id: userId,
          p_user_districts: districts ?? null,
          p_veracity_rate: accuracyRate ?? null,
        }) as { data: unknown[] | null; error: unknown };
    }

    if ((rpcResult as { error: unknown }).error) {
      logger.error('RPC failed in assignQuestsForUser', {
        userId,
        isOnboarding,
        error: String((rpcResult as { error: unknown }).error),
      });
      return existingQuestIds;
    }

    const rpcRows = ((rpcResult.data ?? []) as Record<string, unknown>[]);
    const allCandidateIds = rpcRows.map((row) => row['quest_id'] as string);
    candidateIds = allCandidateIds.filter((id) => !existingSet.has(id));
  }

  // --------------------------------------------------------
  // Step 5b: Prepend pinned quests (bypass red/yellow gate — PRIO-02/PRIO-03)
  // Pinned quests appear at the top of every user's candidate pool regardless
  // of VR gate or gem_quest_type. Already-assigned quests are excluded via existingSet.
  // --------------------------------------------------------
  const pinnedResult = await supabaseService
    .schema('validation_quests')
    .from('verification_quests')
    .select('id')
    .eq('status', 'active')
    .eq('pinned', true) as unknown as { data: Array<{ id: string }> | null; error: unknown };

  const pinnedIds = (pinnedResult.data ?? []).map((r) => r.id).filter((id) => !existingSet.has(id));
  const pinnedSet = new Set(pinnedIds);
  candidateIds = [...pinnedIds, ...candidateIds.filter((id) => !pinnedSet.has(id))];

  // --------------------------------------------------------
  // Step 6: Remove quests the user already submitted to
  // --------------------------------------------------------
  if (candidateIds.length > 0) {
    const submittedResult = await supabaseService
      .schema('validation_quests')
      .from('verification_submissions')
      .select('quest_id')
      .eq('user_id', userId)
      .in('quest_id', candidateIds) as {
        data: Array<{ quest_id: string }> | null;
        error: unknown;
      };

    const submittedSet = new Set((submittedResult.data ?? []).map((s) => s.quest_id));
    candidateIds = candidateIds.filter((id) => !submittedSet.has(id));
  }

  // --------------------------------------------------------
  // Step 7: Shuffle and pick
  // --------------------------------------------------------
  const shuffled = shuffle(candidateIds);
  const picks = shuffled.slice(0, needed);

  // --------------------------------------------------------
  // Step 8: Insert new assignments
  // --------------------------------------------------------
  if (picks.length > 0) {
    const rows = picks.map((questId) => ({
      user_id: userId,
      quest_id: questId,
      expires_at: nextRotationAt.toISOString(),
    }));

    const insertResult = await supabaseService
      .schema('validation_quests')
      .from('user_quest_assignments')
      .upsert(rows, { onConflict: 'user_id,quest_id,expires_at', ignoreDuplicates: true });

    if ((insertResult as { error: unknown }).error) {
      logger.warn('Failed to insert quest assignments', {
        userId,
        error: String((insertResult as { error: unknown }).error),
      });
    }
  }

  return [...existingQuestIds, ...picks];
}

// ============================================================
// System-wide rotation pass
// ============================================================

/**
 * runRotationPass — system-wide sweep called by the 4am cron.
 *
 * 1. Deletes all expired assignments across all users.
 * 2. Fetches distinct user_ids active in the last 30 days.
 * 3. Re-assigns quests for each active user (sequential, not parallel).
 */
export async function runRotationPass(): Promise<void> {
  logger.info('Quest rotation pass starting');

  // --------------------------------------------------------
  // Step 1: Clean up all expired assignments
  // --------------------------------------------------------
  const cleanupResult = await supabaseService
    .schema('validation_quests')
    .from('user_quest_assignments')
    .delete()
    .lte('expires_at', new Date().toISOString());

  logger.info('Cleaned up expired quest assignments', {
    error: (cleanupResult as { error: unknown }).error
      ? String((cleanupResult as { error: unknown }).error)
      : null,
  });

  // --------------------------------------------------------
  // Step 2: Collect active user_ids (last 30 days)
  // --------------------------------------------------------
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();

  const [submissionUsersResult, assignmentUsersResult] = await Promise.all([
    supabaseService
      .schema('validation_quests')
      .from('verification_submissions')
      .select('user_id')
      .gte('created_at', thirtyDaysAgo) as unknown as Promise<{
        data: Array<{ user_id: string }> | null;
        error: unknown;
      }>,

    supabaseService
      .schema('validation_quests')
      .from('user_quest_assignments')
      .select('user_id')
      .gte('assigned_at', thirtyDaysAgo) as unknown as Promise<{
        data: Array<{ user_id: string }> | null;
        error: unknown;
      }>,
  ]);

  const activeUserIds = new Set<string>();
  for (const row of submissionUsersResult.data ?? []) {
    activeUserIds.add(row.user_id);
  }
  for (const row of assignmentUsersResult.data ?? []) {
    activeUserIds.add(row.user_id);
  }

  logger.info('Quest rotation pass: active users found', { count: activeUserIds.size });

  // --------------------------------------------------------
  // Step 3: Assign quests for each active user (sequential)
  // --------------------------------------------------------
  let completed = 0;
  let failed = 0;

  for (const userId of activeUserIds) {
    try {
      // Fetch level from connect.connected_profiles
      const profileResult = await supabaseService
        .schema('connect')
        .from('connected_profiles')
        .select('xp')
        .eq('user_id', userId)
        .maybeSingle() as {
          data: { xp: { level: number } | null } | null;
          error: unknown;
        };

      const level = profileResult.data?.xp?.level ?? 1;

      // Assign quests (no coords — rotation is location-agnostic)
      await assignQuestsForUser(userId, level);

      // Invalidate feed cache so next request fetches fresh assignments
      await invalidateFeedCache(userId);

      completed++;
    } catch (err) {
      logger.error('Failed to assign quests for user in rotation pass', {
        userId,
        error: String(err),
      });
      failed++;
    }
  }

  logger.info('Quest rotation pass complete', { completed, failed });
}
