// Feed scoring service — cache key management, cache invalidation, tier gating, and RPC mapping.
// Pure logic + Redis only. No database calls — those happen in route handlers.

import { redis } from '../lib/redis.js';
import type { FeedItem } from '../types/custom.js';

// Cache TTL: 15 minutes
export const FEED_CACHE_TTL = 900;

// ============================================================
// Cache key helpers
// ============================================================

export function feedCacheKey(userId: string): string {
  return `feed:user:${userId}`;
}

export function onboardingCacheKey(userId: string): string {
  return `feed:onboarding:${userId}`;
}

// ============================================================
// Cache invalidation
// ============================================================

/**
 * Invalidate both the personalized feed cache and the onboarding feed cache
 * for a specific user. Called when the user submits a quest or crosses a
 * veracity tier threshold (75% or 85%).
 */
export async function invalidateFeedCache(userId: string): Promise<void> {
  await redis.del(feedCacheKey(userId));
  await redis.del(onboardingCacheKey(userId));
}

/**
 * Invalidate all feed caches across all users (both personalized and onboarding).
 * Called when an admin creates a new bounty quest that affects many users.
 * Returns the total number of deleted cache keys.
 */
export async function invalidateAllFeedCaches(): Promise<number> {
  const userDeleted = await redis.scanDel('feed:user:*');
  const onboardingDeleted = await redis.scanDel('feed:onboarding:*');
  return userDeleted + onboardingDeleted;
}

// ============================================================
// Onboarding detection
// ============================================================

/**
 * Determines if a user is in the onboarding path.
 * Onboarding users receive tier 1-2 local quests with a guided experience.
 * Graduation criteria: 10+ completed quests AND 80%+ veracity rate.
 */
export function isOnboardingUser(
  totalSubmissions: number,
  accuracyRate: number | null,
): boolean {
  return totalSubmissions < 10 || accuracyRate === null || accuracyRate < 80;
}

// ============================================================
// Difficulty tier gating
// ============================================================

/**
 * Returns the difficulty tiers a user is allowed to see based on their veracity rate.
 * Mirrors the logic in the get_personalized_feed Postgres function.
 *
 * NULL / < 75%  => tiers 1-2  (beginner — local, knowable quests only)
 * < 85%         => tiers 2-4  (intermediate — broader but not expert quests)
 * >= 85%        => tiers 1-5  (all tiers — full quest library)
 */
export function getAllowedTiers(veracityRate: number | null): number[] {
  if (veracityRate === null || veracityRate < 75) {
    return [1, 2];
  }
  if (veracityRate < 85) {
    return [2, 3, 4];
  }
  return [1, 2, 3, 4, 5];
}

// ============================================================
// RPC result mapping
// ============================================================

/**
 * Maps a raw Postgres RPC result row to the client-facing FeedItem type.
 *
 * IMPORTANT: geographic_scope is intentionally excluded from FeedItem per CONTEXT.md
 * minimal card decision (question text + gem reward only — no geographic tag in v1).
 * The RPC returns geographic_scope internally but it is not forwarded to the client.
 */
export function mapRpcResultToFeedItem(row: Record<string, unknown>): FeedItem {
  return {
    quest_id: row['quest_id'] as string,
    question_text: row['question_text'] as string,
    gem_type: (row['gem_type'] as 'yellow' | 'red'),
    gem_count: row['gem_reward'] as number,
    composite_score: row['composite_score'] as number,
    score_breakdown: {
      geo: row['geo_score'] as number,
      difficulty: row['difficulty_score'] as number,
      confidence: row['confidence_score'] as number,
      bounty: row['bounty_score'] as number,
    },
  };
}
