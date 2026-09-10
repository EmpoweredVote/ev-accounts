/**
 * Pipeline Cron Orchestrator
 *
 * Runs once per nightly invocation. Preflights every registered lane
 * (resolve collection, auto-throttle, pool regulation), then makes ONE call to
 * runNightlyPipeline() for the lanes that survived preflight.
 *
 * The single call is the point: the feeds are fetched once and each story is
 * routed to exactly one lane, instead of every collection generating
 * independently from identical input.
 *
 * Per-lane isolation in preflight: each lane resolves in its own try/catch.
 * One lane failing preflight does not block the others.
 *
 * One generation_jobs row is written per served lane per run (by
 * run-pipeline.ts). For skipped lanes, this module writes the row directly.
 *
 * Auto-throttle: if a lane's collection has > 20 draft (status='draft')
 * questions, skip that lane for this run — it is left out of the pipeline call.
 *
 * Hard cap: maxQuestionsPerLane: 8 is passed to runNightlyPipeline().
 */

import { db } from '../db/index.js';
import { generationJobs, questions, collectionQuestions, collections } from '../db/schema.js';
import { eq, and, sql } from 'drizzle-orm';
import { regulatePool } from './poolRegulator.js';
import { runNightlyPipeline } from '../scripts/international/run-pipeline.js';
import { INTERNATIONAL_LANES, type LaneTarget } from '../scripts/international/laneTargets.js';

const DRAFT_THROTTLE_LIMIT = 20;
const MAX_QUESTIONS_PER_RUN = 8;

export async function runPipelineCron(): Promise<void> {
  const startTime = Date.now();
  console.log(`[pipelineCron] Starting nightly run — ${INTERNATIONAL_LANES.length} lane(s)`);

  if (INTERNATIONAL_LANES.length === 0) {
    console.log('[pipelineCron] No International lanes registered — skipping run');
    return;
  }

  // ── Preflight each lane ────────────────────────────────────────────────────
  const eligible: LaneTarget[] = [];

  for (const target of INTERNATIONAL_LANES) {
    const { lane, collectionSlug } = target;
    console.log(`[pipelineCron] Preflight: lane=${lane} slug=${collectionSlug}`);

    try {
      // ── Resolve collection ID ──────────────────────────────────────────────
      const [collectionRow] = await db
        .select({ id: collections.id })
        .from(collections)
        .where(eq(collections.slug, collectionSlug))
        .limit(1);

      if (!collectionRow) {
        // Not an error: lanes whose collections do not exist yet are simply
        // not served. runNightlyPipeline records the same skip in its notes.
        console.warn(
          `[pipelineCron] Collection not found in DB: ${collectionSlug} (lane=${lane}) — skipping lane`,
        );
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

      if (draftCount > DRAFT_THROTTLE_LIMIT) {
        console.log(
          `[pipelineCron] Throttle: ${collectionSlug} has ${draftCount} drafts > ${DRAFT_THROTTLE_LIMIT} — skipping`,
        );

        await db.insert(generationJobs).values({
          collectionSlug,
          status: 'skipped',
          questionsGenerated: 0,
          questionsFlagged: 0,
          questionsActivated: 0,
          feedsFailed: 0,
          reason: `auto-throttle: ${draftCount} pending review questions exceeds limit of ${DRAFT_THROTTLE_LIMIT}`,
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

      eligible.push(target);
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : String(err);
      console.error(`[pipelineCron] Error preflighting ${collectionSlug}: ${errorMsg}`);

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

  if (eligible.length === 0) {
    console.log('[pipelineCron] No lanes eligible this run — skipping generation');
    console.log(`[pipelineCron] Nightly run complete in ${Date.now() - startTime}ms`);
    return;
  }

  // ── One ingest, one pass, all eligible lanes ───────────────────────────────
  try {
    await runNightlyPipeline(eligible, { maxQuestionsPerLane: MAX_QUESTIONS_PER_RUN });
    console.log(
      `[pipelineCron] Completed lanes: ${eligible.map(t => t.lane).join(', ')}`,
    );
  } catch (err) {
    const errorMsg = err instanceof Error ? err.message : String(err);
    console.error(`[pipelineCron] Pipeline run failed: ${errorMsg}`);

    for (const target of eligible) {
      try {
        await db.insert(generationJobs).values({
          collectionSlug: target.collectionSlug,
          status: 'failed',
          questionsGenerated: 0,
          questionsFlagged: 0,
          questionsActivated: 0,
          feedsFailed: 0,
          reason: errorMsg.slice(0, 500),
        });
      } catch (jobErr) {
        console.error(
          `[pipelineCron] Could not write failed job row for ${target.collectionSlug}:`,
          jobErr,
        );
      }
    }
  }

  const durationMs = Date.now() - startTime;
  console.log(`[pipelineCron] Nightly run complete in ${durationMs}ms`);
}
