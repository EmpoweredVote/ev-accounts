import type { FingerprintRow, FingerprintStore } from './claimGuard.js';
import type { ClaimKeys } from './claimFingerprint.js';
import type { SimilarityHit, SimilarityProbe } from './nearDuplicate.js';
import type { Lane } from './lanes.js';

/**
 * Postgres-backed implementations of the two injected interfaces.
 * Everything else in the dedup path is pure; this is the only DB surface.
 */

export function createFingerprintStore(): FingerprintStore {
  return {
    async findCandidates(keys: ClaimKeys, since: Date): Promise<FingerprintRow[]> {
      const { db } = await import('../../db/index.js');
      const { claimFingerprints } = await import('../../db/schema.js');
      const { and, eq, gte, or } = await import('drizzle-orm');

      // Two candidate pools in one round trip: value-key matches feed the
      // duplicate rule (compared on entities in the guard), topic-key matches
      // feed best-effort contradiction detection. Served by the two partial
      // indexes the migration adds — the old unique index on
      // (topic_key, value_key) can no longer cover a value-key-only lookup.
      const rows = await db
        .select({
          topicKey: claimFingerprints.topicKey,
          valueKey: claimFingerprints.valueKey,
          entities: claimFingerprints.entities,
          lane: claimFingerprints.lane,
          questionExternalId: claimFingerprints.questionExternalId,
          firstSeenAt: claimFingerprints.firstSeenAt,
        })
        .from(claimFingerprints)
        .where(
          and(
            gte(claimFingerprints.firstSeenAt, since),
            or(
              eq(claimFingerprints.topicKey, keys.topicKey),
              eq(claimFingerprints.valueKey, keys.valueKey),
            ),
          ),
        );

      // `entities ?? []` is not dead defence: the column is NOT NULL, but
      // drizzle types an array column as possibly-null on some paths and a
      // null here would crash normalisation rather than degrade to the
      // fallback.
      return rows.map(r => ({ ...r, entities: r.entities ?? [], lane: r.lane as Lane }));
    },

    async insert(row): Promise<void> {
      const { db } = await import('../../db/index.js');
      const { claimFingerprints } = await import('../../db/schema.js');

      // A plain insert, no ON CONFLICT — and that is a change, so here is why.
      //
      // This used to upsert on (topic_key, value_key), the pair that carried
      // the old unique index. The migration drops that index, because under
      // the new rule the pair is no longer an identity: the same fact gets a
      // DIFFERENT topic_key on every run the model re-phrases it (the whole
      // Mokha finding), so there is no key to conflict on any more. Drizzle
      // requires a unique index to target, so ON CONFLICT cannot be kept even
      // if we wanted it.
      //
      // The behaviour the old upsert protected is preserved anyway. Its
      // purpose was window refresh: the check window is 14 days
      // (CLAIM_WINDOW_DAYS) and the prune horizon is 30, so a claim first
      // seen on day 0 falls out of the check window on day 15, is regenerated,
      // and with DO NOTHING the re-record silently did nothing — leaving
      // first_seen_at at day 0 and repeating that regeneration nightly until
      // the day-30 prune. An unconditional insert writes a row with a fresh
      // first_seen_at, which restarts the window just as the UPDATE did.
      //
      // The cost is row growth where the old form updated in place: a claim
      // re-covered after falling out of the window now leaves two rows rather
      // than one. Bounded and small — `record` is only called when questions
      // were actually generated, a duplicate check short-circuits before it,
      // and the 30-day prune collects the rest.
      await db
        .insert(claimFingerprints)
        .values({
          topicKey: row.topicKey,
          valueKey: row.valueKey,
          entities: row.entities,
          lane: row.lane,
          questionExternalId: row.questionExternalId,
          generationJobId: row.generationJobId,
          firstSeenAt: row.firstSeenAt,
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
