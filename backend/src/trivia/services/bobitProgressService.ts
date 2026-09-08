import { and, eq } from 'drizzle-orm';
import { db } from '../db/index.js';
import { bobitProgress } from '../db/schema.js';

/**
 * Per-account bobit progress -- which questions a player has a collection bobit for.
 *
 * Stage 4 of the bobit collection design. Every function here is safe to call
 * fire-and-forget: the only caller is the answer path, and a player must never lose a
 * match because their crowd could not be written. Signed-out players keep their progress
 * in the browser instead (Stage 3's localStorage driver), so nothing here handles them.
 */

/**
 * The slug a collection's progress is stored under.
 *
 * A Federal default session carries `collectionSlug: null` (sessionService sets
 * `collectionMeta?.slug ?? null`), but the frontend defaults that same value to
 * 'federal-civics'. Coalescing in exactly one place is what stops a Federal player's crowd
 * splitting across two keys -- earned under one, read back under the other.
 */
export const FEDERAL_SLUG = 'federal-civics';

export function progressKey(slug: string | null | undefined): string {
  return slug ?? FEDERAL_SLUG;
}

/**
 * Record that a player has earned this question's bobit.
 *
 * Idempotent by primary key. `onConflictDoNothing` rather than an upsert on purpose: a
 * question answered correctly again must not bump `earned_at`, because nothing should be
 * able to reorder a crowd the player has already arranged in their head.
 */
export async function grantBobit(
  userId: string,
  collectionSlug: string,
  questionExternalId: string,
): Promise<void> {
  await db
    .insert(bobitProgress)
    .values({ userId, collectionSlug, questionExternalId })
    .onConflictDoNothing();
}

/** Take a bobit away. Deleting one that was never granted is a no-op, by design. */
export async function revokeBobit(
  userId: string,
  questionExternalId: string,
): Promise<void> {
  await db
    .delete(bobitProgress)
    .where(
      and(
        eq(bobitProgress.userId, userId),
        eq(bobitProgress.questionExternalId, questionExternalId),
      ),
    );
}

/**
 * Every bobit this player owns, grouped by collection slug.
 *
 * One indexed read serves the whole crowd. Grouped server-side so the client gets the exact
 * shape its progress store keeps and needs no reshaping on the hot path.
 */
export async function readBobits(userId: string): Promise<Record<string, string[]>> {
  const rows = await db
    .select({
      collectionSlug: bobitProgress.collectionSlug,
      questionExternalId: bobitProgress.questionExternalId,
    })
    .from(bobitProgress)
    .where(eq(bobitProgress.userId, userId));

  const out: Record<string, string[]> = {};
  for (const row of rows) {
    (out[row.collectionSlug] ??= []).push(row.questionExternalId);
  }
  return out;
}
