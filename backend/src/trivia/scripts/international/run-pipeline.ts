// The nightly news pipeline: ingest once, route each story to exactly one
// lane, then generate per lane.
//
// Usage:
//   npx tsx src/trivia/scripts/international/run-pipeline.ts
//   npx tsx src/trivia/scripts/international/run-pipeline.ts --dry-run

import 'dotenv/config';
import { fileURLToPath } from 'url';
import { fetchAllFeeds, INTERNATIONAL_FEEDS, type FeedResult } from './rss-ingestor.js';
import { clusterArticles, extractClaim } from './claim-extractor.js';
import {
  generateQuestions,
  writePassingQuestions,
  type GeneratedQuestion,
} from './question-generator.js';
import type { Lane } from './lanes.js';
import { fingerprintClaim } from './claimFingerprint.js';
import { makeClaimGuard } from './claimGuard.js';
import { makeNearDuplicateCheck } from './nearDuplicate.js';
import {
  createFingerprintStore,
  createSimilarityProbe,
  pruneClaimFingerprints,
} from './claimStore.js';
import { INTERNATIONAL_LANES, type LaneTarget } from './laneTargets.js';

// ─── Per-lane counters ────────────────────────────────────────────────────────

interface LaneStats {
  generated: number;
  blocked: number;
  duplicates: number;
  contradictions: number;
  nearDuplicates: number;
  degenerate: number;
}

function emptyStats(): LaneStats {
  return {
    generated: 0,
    blocked: 0,
    duplicates: 0,
    contradictions: 0,
    nearDuplicates: 0,
    degenerate: 0,
  };
}

// ─── Pipeline ─────────────────────────────────────────────────────────────────

export async function runNightlyPipeline(
  targets: readonly LaneTarget[],
  options: { dryRun?: boolean; maxQuestionsPerLane?: number } = {},
): Promise<void> {
  const { dryRun = false, maxQuestionsPerLane } = options;

  console.log(`[run-pipeline] Nightly run — ${targets.length} lane(s)${dryRun ? ' (DRY RUN)' : ''}`);

  if (targets.length === 0) {
    console.log('[run-pipeline] No lanes registered — nothing to do');
    return;
  }

  // ── Lazy DB imports (ESM pattern) ────────────────────────────────────────
  const { db } = await import('../../db/index.js');
  const { generationJobs, collections } = await import('../../db/schema.js');
  const { eq, inArray, sql } = await import('drizzle-orm');

  // ── Resolve every lane's collection up front ─────────────────────────────
  const slugs = targets.map(t => t.collectionSlug);
  const rows = await db
    .select({ id: collections.id, slug: collections.slug })
    .from(collections)
    .where(inArray(collections.slug, slugs));

  const idBySlug = new Map(rows.map(r => [r.slug, r.id]));

  // A lane whose collection does not exist yet is skipped, not fatal: three of
  // the four lanes' collections are created in a later plan, and throwing here
  // would abort the whole run and take the working lanes down with it.
  const servedTargets = targets.filter(t => idBySlug.has(t.collectionSlug));
  const missingLanes: Array<Record<string, unknown>> = [];

  for (const t of targets) {
    if (!idBySlug.has(t.collectionSlug)) {
      console.warn(
        `[run-pipeline] Collection not found, skipping lane=${t.lane} slug=${t.collectionSlug}`,
      );
      missingLanes.push({
        reason: 'missing-collection',
        lane: t.lane,
        collectionSlug: t.collectionSlug,
      });
    }
  }

  if (servedTargets.length === 0) {
    throw new Error(
      `No lane collections found in DB — nothing to serve (checked: ${slugs.join(', ')})`,
    );
  }

  const targetByLane = new Map(servedTargets.map(t => [t.lane, t]));
  const allCollectionIds = servedTargets.map(t => idBySlug.get(t.collectionSlug)!);

  // ── One generation_jobs row per served lane ──────────────────────────────
  const jobIdByLane = new Map<Lane, number>();
  if (!dryRun) {
    for (const t of servedTargets) {
      const [job] = await db
        .insert(generationJobs)
        .values({
          collectionSlug: t.collectionSlug,
          status: 'running',
          questionsGenerated: 0,
          questionsFlagged: 0,
          questionsActivated: 0,
          feedsFailed: 0,
        })
        .returning({ id: generationJobs.id });
      jobIdByLane.set(t.lane, job.id);
      console.log(`[run-pipeline] lane=${t.lane}: generation_jobs id=${job.id}`);
    }
  }

  // ── Ingest ONCE ──────────────────────────────────────────────────────────
  let feedResults: FeedResult[] = [];
  let pipelineStatus: 'success' | 'failed' = 'success';
  try {
    feedResults = await fetchAllFeeds(INTERNATIONAL_FEEDS);
  } catch (err) {
    const errorMsg = err instanceof Error ? err.message : String(err);
    console.error(`[run-pipeline] Fatal error during feed fetch: ${errorMsg}`);
    pipelineStatus = 'failed';
  }

  const feedsFailed = feedResults.filter(r => r.error).length;
  for (const result of feedResults) {
    console.log(
      result.error
        ? `[${result.feedName}] FAILED (${result.feedUrl}): ${result.error}`
        : `[${result.feedName}] ${result.articles.length} articles ready`,
    );
  }

  const allArticles = feedResults.flatMap(r => r.articles);
  const clusters = clusterArticles(allArticles);
  console.log(`[Pipeline] ${allArticles.length} articles → ${clusters.length} clusters`);

  // ── Guards ───────────────────────────────────────────────────────────────
  const guard = makeClaimGuard(createFingerprintStore());
  const checkNearDuplicate = makeNearDuplicateCheck(createSimilarityProbe());

  const stats = new Map<Lane, LaneStats>(servedTargets.map(t => [t.lane, emptyStats()]));
  const rejections: Array<Record<string, unknown>> = [];

  for (const cluster of clusters) {
    const claimResult = dryRun ? null : await extractClaim(cluster);
    if (!claimResult) {
      if (dryRun) console.log(`[DryRun] cluster: "${cluster.representativeTitle}"`);
      continue;
    }

    const target = targetByLane.get(claimResult.lane);
    if (!target) {
      console.log(`[Pipeline] No target registered for lane=${claimResult.lane} — skipping`);
      rejections.push({ reason: 'no-target', lane: claimResult.lane, subject: claimResult.subject });
      continue;
    }

    const laneStats = stats.get(target.lane)!;
    if (maxQuestionsPerLane !== undefined && laneStats.generated >= maxQuestionsPerLane) {
      continue;
    }

    // ── Layer 1: claim fingerprint ─────────────────────────────────────────
    const keys = fingerprintClaim(claimResult);

    // A blank subject/attribute/value is schema-compliant but fingerprints to
    // topicKey "|" and valueKey "". Recording one would make every later
    // malformed claim read as a duplicate of it, so reject before the guard.
    if (keys.topicKey.replace('|', '').trim() === '' || keys.valueKey.trim() === '') {
      laneStats.degenerate++;
      console.warn(`[Dedup] degenerate claim (blank subject/attribute/value) — skipping: "${claimResult.claim}"`);
      rejections.push({ reason: 'degenerate-claim', lane: target.lane, claim: claimResult.claim });
      continue;
    }

    const verdict = await guard.check(keys);

    if (verdict.kind === 'duplicate') {
      laneStats.duplicates++;
      console.log(`[Dedup] duplicate of ${verdict.existing.questionExternalId ?? '(unknown)'} — "${claimResult.subject} / ${claimResult.attribute}"`);
      rejections.push({
        reason: 'duplicate-claim', lane: target.lane, topicKey: keys.topicKey,
        valueKey: keys.valueKey, existing: verdict.existing.questionExternalId,
      });
      continue;
    }

    if (verdict.kind === 'contradiction') {
      laneStats.contradictions++;
      console.warn(`[Dedup] CONTRADICTION: "${keys.topicKey}" was ${verdict.existing.valueKey} (${verdict.existing.questionExternalId ?? 'unknown'}), now ${keys.valueKey} — skipping`);
      rejections.push({
        reason: 'contradiction', lane: target.lane, topicKey: keys.topicKey,
        newValue: keys.valueKey, existingValue: verdict.existing.valueKey,
        existing: verdict.existing.questionExternalId,
      });
      continue;
    }

    // ── Generate ───────────────────────────────────────────────────────────
    const candidates = await generateQuestions(claimResult);
    const failing = candidates.filter(q => !q.qualityGate.passed);
    laneStats.blocked += failing.length;

    let passing = candidates.filter(q => q.qualityGate.passed);

    // ── Layer 2: trigram net, per candidate ────────────────────────────────
    const survivors: GeneratedQuestion[] = [];
    for (const q of passing) {
      const hit = await checkNearDuplicate(q.text, allCollectionIds);
      if (hit) {
        laneStats.nearDuplicates++;
        console.log(`[Dedup] near-duplicate of ${hit.externalId} (sim=${hit.similarity.toFixed(2)}) — skipping`);
        rejections.push({
          reason: 'near-duplicate', lane: target.lane,
          existing: hit.externalId, similarity: hit.similarity,
        });
        continue;
      }
      survivors.push(q);
    }
    passing = survivors;

    const jobId = jobIdByLane.get(target.lane);
    if (passing.length > 0 && jobId !== undefined) {
      const written = await writePassingQuestions(
        passing, claimResult, idBySlug.get(target.collectionSlug)!,
        jobId, target.prefix, target.volatility,
      );
      laneStats.generated += written.length;

      // Recorded only when something was actually published: a claim whose
      // candidates were all rejected is deliberately not remembered, so a
      // transient failure does not suppress the story permanently.
      await guard.record(keys, target.lane, written[0]?.externalId ?? null, jobId);
    }
  }

  // ── Finalise each lane's job row ─────────────────────────────────────────
  if (!dryRun) {
    for (const t of servedTargets) {
      const s = stats.get(t.lane)!;
      const jobId = jobIdByLane.get(t.lane)!;
      console.log(
        `[Pipeline] lane=${t.lane}: ${s.generated} generated, ${s.blocked} blocked, ` +
        `${s.duplicates} duplicate, ${s.contradictions} contradiction, ` +
        `${s.nearDuplicates} near-duplicate, ${s.degenerate} degenerate`,
      );
      await db
        .update(generationJobs)
        .set({
          status: pipelineStatus,
          questionsGenerated: s.generated,
          questionsFlagged: s.blocked,
          questionsActivated: s.generated,
          feedsFailed,
          notes: {
            feedStats: feedResults.map(r => ({
              feedUrl: r.feedUrl,
              articlesFound: r.articles.length,
              articlesSkipped: r.articlesSkipped,
              ...(r.error ? { error: r.error } : {}),
            })),
            laneDistribution: Object.fromEntries(
              [...stats.entries()].map(([lane, v]) => [lane, v.generated]),
            ),
            dedup: {
              duplicates: s.duplicates,
              contradictions: s.contradictions,
              nearDuplicates: s.nearDuplicates,
              degenerate: s.degenerate,
            },
            rejections: [...missingLanes, ...rejections.filter(r => r.lane === t.lane)],
          } as never,
          updatedAt: sql`NOW()`,
        })
        .where(eq(generationJobs.id, jobId));
    }

    const pruned = await pruneClaimFingerprints(30);
    console.log(`[Pipeline] Pruned ${pruned} fingerprints older than 30 days`);
  }

  console.log('[run-pipeline] Pipeline complete.');
}

// ─── Entry Point ──────────────────────────────────────────────────────────────

// Guard: only run CLI if this file is executed directly (not imported)
const isDirectRun = process.argv[1] && (
  process.argv[1] === fileURLToPath(import.meta.url) ||
  process.argv[1].endsWith('/run-pipeline.ts') ||
  process.argv[1].endsWith('/run-pipeline.js')
);
if (isDirectRun) {
  const dryRun = process.argv.includes('--dry-run');
  runNightlyPipeline(INTERNATIONAL_LANES, { dryRun }).catch((err) => {
    console.error('[run-pipeline] Fatal:', err);
    process.exit(1);
  });
}
