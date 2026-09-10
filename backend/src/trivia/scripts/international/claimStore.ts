import type { FingerprintRow, FingerprintStore } from './claimGuard.js';
import type { SimilarityHit, SimilarityProbe } from './nearDuplicate.js';
import type { Lane } from './lanes.js';

/**
 * Postgres-backed implementations of the two injected interfaces.
 * Everything else in the dedup path is pure; this is the only DB surface.
 */

export function createFingerprintStore(): FingerprintStore {
  return {
    async findByTopicKey(topicKey: string, since: Date): Promise<FingerprintRow[]> {
      const { db } = await import('../../db/index.js');
      const { claimFingerprints } = await import('../../db/schema.js');
      const { and, eq, gte } = await import('drizzle-orm');

      const rows = await db
        .select({
          topicKey: claimFingerprints.topicKey,
          valueKey: claimFingerprints.valueKey,
          lane: claimFingerprints.lane,
          questionExternalId: claimFingerprints.questionExternalId,
          firstSeenAt: claimFingerprints.firstSeenAt,
        })
        .from(claimFingerprints)
        .where(
          and(
            eq(claimFingerprints.topicKey, topicKey),
            gte(claimFingerprints.firstSeenAt, since),
          ),
        );

      return rows.map(r => ({ ...r, lane: r.lane as Lane }));
    },

    async insert(row): Promise<void> {
      const { db } = await import('../../db/index.js');
      const { claimFingerprints } = await import('../../db/schema.js');

      await db
        .insert(claimFingerprints)
        .values({
          topicKey: row.topicKey,
          valueKey: row.valueKey,
          lane: row.lane,
          questionExternalId: row.questionExternalId,
          generationJobId: row.generationJobId,
          firstSeenAt: row.firstSeenAt,
        })
        .onConflictDoNothing();
    },
  };
}

export function createSimilarityProbe(): SimilarityProbe {
  return {
    async mostSimilar(
      text: string,
      collectionIds: readonly number[],
      since: Date,
    ): Promise<SimilarityHit | null> {
      if (collectionIds.length === 0) return null;

      const { db } = await import('../../db/index.js');
      const { sql } = await import('drizzle-orm');

      // Scoped through collection_questions, never by external_id prefix —
      // a shared prefix cross-links collections (the `ind` footgun).
      //
      // pg_trgm 1.6 lives in the `extensions` schema, which is not on the
      // `ctc_app` role's search_path — similarity() must be schema-qualified
      // or this fails with "function similarity(unknown, unknown) does not
      // exist" at runtime (tsc cannot catch a mistake inside raw SQL).
      //
      // `collectionIds` is interpolated as a plain array; drizzle's sql tag
      // expands a raw JS array chunk into a parenthesized, bound parameter
      // list (`IN ($1, $2, ...)`), so this stays fully parameterized without
      // needing a `sql.raw(...)::int[]` string-built ARRAY literal.
      const result = await db.execute(sql`
        SELECT q.external_id AS external_id,
               extensions.similarity(q.text, ${text}) AS sim
        FROM trivia.questions q
        JOIN trivia.collection_questions cq ON cq.question_id = q.id
        WHERE cq.collection_id IN ${collectionIds}
          AND q.created_at >= ${since.toISOString()}
          AND q.status IN ('active', 'expired')
        ORDER BY sim DESC
        LIMIT 1
      `);

      const row = (result as unknown as { rows?: Array<{ external_id: string; sim: number }> }).rows?.[0]
        ?? (result as unknown as Array<{ external_id: string; sim: number }>)[0];

      if (!row) return null;
      return { externalId: row.external_id, similarity: Number(row.sim) };
    },
  };
}

/** Housekeeping: drop fingerprints beyond the retention horizon. */
export async function pruneClaimFingerprints(olderThanDays: number): Promise<number> {
  const { db } = await import('../../db/index.js');
  const { claimFingerprints } = await import('../../db/schema.js');
  const { lt } = await import('drizzle-orm');

  const cutoff = new Date(Date.now() - olderThanDays * 24 * 60 * 60 * 1000);
  const deleted = await db
    .delete(claimFingerprints)
    .where(lt(claimFingerprints.firstSeenAt, cutoff))
    .returning({ id: claimFingerprints.id });

  return deleted.length;
}
