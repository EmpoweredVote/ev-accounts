import { and, eq } from 'drizzle-orm';
import { db } from '../db/index.js';
import { bobitProgress } from '../db/schema.js';
import { FEDERAL_SLUG } from '../config/federalCollection.js';

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
 * A session can carry `collectionSlug: null` -- sessionService sets `collectionMeta?.slug ??
 * null`, so a failed metadata lookup leaves it empty. Coalescing in exactly one place is what
 * stops a Federal player's crowd splitting across two keys: earned under one, read back under
 * the other.
 *
 * That coalescing is only worth anything if the default NAMES A REAL COLLECTION. It read
 * 'federal-civics' until 2026-10-11, which names none, so the one case this function exists to
 * protect was the one case it could not have survived. See `FEDERAL_SLUG`.
 */
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
 * The question ids this player already holds a bobit for IN ONE COLLECTION.
 *
 * Scoped rather than reusing `readBobits`, which pulls every bobit the player owns across all
 * 43 collections: this one runs on the answer-time path's sibling, session creation, where the
 * only rows that matter are the collection about to be played. `idx_bobit_progress_user_collection`
 * covers exactly this predicate.
 *
 * The caller passes the slug through `progressKey`, the SAME function the grant path uses, so
 * what is read back cannot drift from what was written.
 *
 * Returns an empty set rather than throwing. The caller is question selection, and a player
 * must never fail to start a match because their bobits could not be counted -- the cost of
 * the empty case is today's behaviour, which is the thing being improved rather than relied on.
 */
export async function readOwnedExternalIds(
  userId: string,
  collectionSlug: string,
): Promise<Set<string>> {
  try {
    const rows = await db
      .select({ questionExternalId: bobitProgress.questionExternalId })
      .from(bobitProgress)
      .where(
        and(
          eq(bobitProgress.userId, userId),
          eq(bobitProgress.collectionSlug, collectionSlug),
        ),
      );
    return new Set(rows.map(r => r.questionExternalId));
  } catch (error) {
    console.warn('Could not read owned bobits for question selection:', error);
    return new Set();
  }
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
