/**
 * Pipeline Cron Orchestrator
 *
 * Runs once per nightly invocation. Iterates all registered International
 * collections, applies pool regulation, then calls runPipeline() for each.
 *
 * Per-collection isolation: each collection runs in its own try/catch.
 * One collection failing does not block the others.
 *
 * One generation_jobs row is written per collection per run (by run-pipeline.ts).
 * For skipped collections, this module writes the row directly.
 *
 * Auto-throttle: if a collection has > 20 draft (status='draft') questions,
 * skip the entire collection for this run — no RSS fetch, no Claude calls.
 *
 * Hard cap: maxQuestions: 8 is passed to runPipeline() on every call.
 */

import { db } from '../db/index.js';
import { generationJobs, questions, collectionQuestions, collections } from '../db/schema.js';
import { eq, and, sql } from 'drizzle-orm';
import { regulatePool } from './poolRegulator.js';
import { runPipeline, type InternationalLocaleConfig } from '../scripts/international/run-pipeline.js';

// ─── Registered International Collections ────────────────────────────────────

const INTERNATIONAL_COLLECTIONS: InternationalLocaleConfig[] = [
  { collectionSlug: 'war-in-iran', prefix: 'wiran', volatility: 'fast' },
  { collectionSlug: 'climate-agreements', prefix: 'clima', volatility: 'medium' },
];

export const DRAFT_THROTTLE_LIMIT = 20;

/**
 * Clusters processed per collection per run — NOT questions.
 *
 * Renamed from MAX_QUESTIONS_PER_RUN, which was what it claimed to be and not
 * what it did: run-pipeline slices `clusters`, and each cluster yields roughly
 * two questions, so a "cap" of 8 produced 13 questions on 2026-09-12
 * (generation_jobs id=282). Behaviour is unchanged here; only the name and the
 * claim are now true.
 */
const MAX_CLUSTERS_PER_RUN = 8;

/**
 * Why this registered collection must not generate tonight, or null to proceed.
 *
 * Pulled out of the loop so the judgement is testable without a database.
 *
 * The `is_active` check exists because retiring a collection in the database
 * did not stop the cron: `climate-agreements` was switched off on 2026-09-10
 * and the nightly run added ten more questions to it on 2026-09-12, because
 * the registry is a hardcoded array and nothing consulted the row. DB state is
 * now authoritative — switching a collection off stops the spend.
 *
 * Inactive is reported ahead of the throttle deliberately: a throttle reason
 * means "come back tomorrow", which is the wrong thing to record about a
 * collection that has been retired.
 */
export function skipReasonFor(input: {
  isActive: boolean;
  draftCount: number;
  draftLimit: number;
}): string | null {
  if (!input.isActive) {
    return 'inactive: collection is switched off (is_active = false)';
  }
  if (input.draftCount > input.draftLimit) {
    return `auto-throttle: ${input.draftCount} pending review questions exceeds limit of ${input.draftLimit}`;
  }
  return null;
}

export async function runPipelineCron(): Promise<void> {
  const startTime = Date.now();
  console.log(`[pipelineCron] Starting nightly run — ${INTERNATIONAL_COLLECTIONS.length} collection(s)`);

  if (INTERNATIONAL_COLLECTIONS.length === 0) {
    console.log('[pipelineCron] No International collections registered — skipping run');
    return;
  }

  for (const config of INTERNATIONAL_COLLECTIONS) {
    const { collectionSlug, prefix, volatility } = config;
    console.log(`[pipelineCron] Processing: ${collectionSlug}`);

    try {
      // ── Resolve collection ID ──────────────────────────────────────────────
      const [collectionRow] = await db
        .select({ id: collections.id, isActive: collections.isActive })
        .from(collections)
        .where(eq(collections.slug, collectionSlug))
        .limit(1);

      if (!collectionRow) {
        console.error(`[pipelineCron] Collection not found in DB: ${collectionSlug} — skipping`);
        continue;
      }

      const collectionId = collectionRow.id;

      // ── Auto-throttle: check draft count ───────────────────────────────────
      const draftCountResult = await db
        .select({ count: sql<number>`COUNT(*)::int` })
        .from(questions)
        .innerJoin(collectionQuestions, eq(collectionQuestions.questionId, questions.id))
        .where(
          and(
            eq(collectionQuestions.collectionId, collectionId),
            eq(questions.status, 'draft'),
          ),
        );

      const draftCount = draftCountResult[0]?.count ?? 0;

      const skipReason = skipReasonFor({
        isActive: collectionRow.isActive,
        draftCount,
        draftLimit: DRAFT_THROTTLE_LIMIT,
      });

      if (skipReason !== null) {
        console.log(`[pipelineCron] Skipping ${collectionSlug} — ${skipReason}`);

        await db.insert(generationJobs).values({
          collectionSlug,
          status: 'skipped',
          questionsGenerated: 0,
          questionsFlagged: 0,
          questionsActivated: 0,
          feedsFailed: 0,
          reason: skipReason,
        });

        continue;
      }

      // ── Pool regulation (before generation) ───────────────────────────────
      const regulationResult = await regulatePool(collectionId);
      if (regulationResult.archivedCount > 0) {
        console.log(
          `[pipelineCron] Regulated pool for ${collectionSlug}: archived ${regulationResult.archivedCount}, now ${regulationResult.currentEventsCount} current-events questions`,
        );
      }

      // ── Run pipeline (handles its own generation_jobs row) ─────────────────
      await runPipeline(collectionSlug, prefix, { volatility, maxQuestions: MAX_CLUSTERS_PER_RUN });

      console.log(`[pipelineCron] Completed: ${collectionSlug}`);
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : String(err);
      console.error(`[pipelineCron] Error processing ${collectionSlug}: ${errorMsg}`);

      try {
        await db.insert(generationJobs).values({
          collectionSlug,
          status: 'failed',
          questionsGenerated: 0,
          questionsFlagged: 0,
          questionsActivated: 0,
          feedsFailed: 0,
          reason: errorMsg.slice(0, 500),
        });
      } catch (jobErr) {
        console.error(`[pipelineCron] Could not write failed job row for ${collectionSlug}:`, jobErr);
      }
    }
  }

  const durationMs = Date.now() - startTime;
  console.log(`[pipelineCron] Nightly run complete in ${durationMs}ms`);
}
