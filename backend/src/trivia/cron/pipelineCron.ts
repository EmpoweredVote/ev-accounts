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
 * Soft cap: maxQuestionsPerLane: 8 is passed to runNightlyPipeline(). It is
 * checked before a cluster is generated, not after, so a lane sitting at 7
 * can still accept a whole batch and finish at 9 or 10 — treat it as a
 * per-run ceiling target, not a hard limit.
 */

import { db } from '../db/index.js';
import { generationJobs, questions, collectionQuestions, collections } from '../db/schema.js';
import { eq, and, sql } from 'drizzle-orm';
import { regulatePool } from './poolRegulator.js';
import { runNightlyPipeline } from '../scripts/international/run-pipeline.js';
import { INTERNATIONAL_LANES, type LaneTarget } from '../scripts/international/laneTargets.js';

export const DRAFT_THROTTLE_LIMIT = 20;

/**
 * Why this lane must not generate tonight, or null to proceed.
 *
 * Pulled out of the preflight loop so the judgement is testable without a
 * database.
 *
 * The `is_active` check exists because retiring a collection in the database
 * did not stop the cron. `climate-agreements` was switched off on 2026-09-10
 * and the nightly run added ten more questions to it on 2026-09-12
 * (generation_jobs id=283): preflight resolved the collection by slug, selected
 * only its `id`, and nothing consulted the row. Lane routing removed that
 * collection from the registry, which closed the specific leak but not the
 * defect — `laneTargets.ts` has no `is_active` reference either, so switching
 * off `war-in-iran` would repeat it. The database is now authoritative.
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
        .select({ id: collections.id, isActive: collections.isActive })
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

      const skipReason = skipReasonFor({
        isActive: collectionRow.isActive,
        draftCount,
        draftLimit: DRAFT_THROTTLE_LIMIT,
      });

      if (skipReason !== null) {
        console.log(`[pipelineCron] Skipping lane=${lane} ${collectionSlug} — ${skipReason}`);

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
    const result = await runNightlyPipeline(eligible, { maxQuestionsPerLane: MAX_QUESTIONS_PER_RUN });
    if (result.status === 'success') {
      console.log(
        `[pipelineCron] Completed lanes: ${eligible.map(t => t.lane).join(', ')}`,
      );
    } else {
      // The pipeline records its own fatal error on the job rows it already
      // wrote and deliberately does not rethrow (rethrowing here is what
      // caused pipelineCron to duplicate those rows with a competing
      // 'failed' insert) — so this is not the catch block below, and
      // "Completed lanes" would otherwise print even on a run that failed
      // internally.
      console.warn(
        `[pipelineCron] Pipeline finished with status=failed — lanes: ${eligible.map(t => t.lane).join(', ')} (see generation_jobs for per-lane detail)`,
      );
    }
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
