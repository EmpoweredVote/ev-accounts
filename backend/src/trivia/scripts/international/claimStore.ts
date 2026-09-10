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

      // Upsert, not `onConflictDoNothing`. The unique index is on
      // (topic_key, value_key); the Layer 1 check window is 14 days
      // (CLAIM_WINDOW_DAYS) and the prune horizon is 30. With DO NOTHING a
      // claim first seen on day 0 falls out of findByTopicKey's window on
      // day 15, so check() calls it `new`, a question is generated, and
      // record() then silently does nothing — leaving first_seen_at at day 0
      // and repeating the same regeneration every night until the day-30
      // prune. Refreshing the row restarts the window instead, so a
      // re-covered claim is remembered from the night it was re-covered.
      //
      // Within-run idempotence is preserved: these are separate statements,
      // so the second record of an identical claim in one run updates the
      // row it just inserted rather than adding a second one.
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
        .onConflictDoUpdate({
          target: [claimFingerprints.topicKey, claimFingerprints.valueKey],
          set: {
            firstSeenAt: row.firstSeenAt,
            questionExternalId: row.questionExternalId,
            generationJobId: row.generationJobId,
          },
        });
    },
  };
}

export function createSimilarityProbe(): SimilarityProbe {
  return {
    async mostSimilar(
      text: string,
      collectionIds: readonly number[],
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
      //
      // Deliberately NOT bounded by q.created_at. Generated questions expire
      // in ~4 days and are archived, so the only questions older than a
      // couple of weeks in a lane's collection are the hand-written evergreen
      // ones (the curated wiran-00** spine, and the curated Climate Change
      // set to come). A created_at window therefore blinded Layer 2 to
      // exactly the questions Layer 1 cannot cover either — curated questions
      // have no fingerprint rows — leaving a structural blind spot at the
      // curated/generated boundary. The query stays bounded by collection and
      // status; at ~100 questions per collection the extra similarity()
      // evaluations are negligible.
      const result = await db.execute(sql`
        SELECT q.external_id AS external_id,
               extensions.similarity(q.text, ${text}) AS sim
        FROM trivia.questions q
        JOIN trivia.collection_questions cq ON cq.question_id = q.id
        WHERE cq.collection_id IN ${collectionIds}
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
