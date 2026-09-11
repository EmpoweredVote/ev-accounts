// The nightly news pipeline: ingest once, route each story to exactly one
// lane, then generate per lane.
//
// Usage:
//   npx tsx src/trivia/scripts/international/run-pipeline.ts
//   npx tsx src/trivia/scripts/international/run-pipeline.ts --dry-run

import 'dotenv/config';
import { fileURLToPath } from 'url';
import { fetchAllFeeds, INTERNATIONAL_FEEDS, type FeedResult } from './rss-ingestor.js';
import {
  CLAIM_SKIP_REASONS,
  clusterArticles,
  extractClaim,
  type ClaimSkipReason,
} from './claim-extractor.js';
import {
  generateQuestions,
  writePassingQuestions,
  type GeneratedQuestion,
} from './question-generator.js';
import type { Lane } from './lanes.js';
import { fingerprintClaim } from './claimFingerprint.js';
import { makeClaimGuard, type ClaimVerdict } from './claimGuard.js';
import { MIN_ENTITY_OVERLAP, normalizeEntities } from './claimIdentity.js';
import { makeNearDuplicateCheck } from './nearDuplicate.js';
import {
  createFingerprintStore,
  createSimilarityProbe,
  pruneClaimFingerprints,
} from './claimStore.js';
import {
  INTERNATIONAL_LANES,
  isDegenerate,
  isSystemicClusterFailure,
  partitionRejections,
  partitionTargets,
  type LaneTarget,
  type Rejection,
} from './laneTargets.js';

// ─── Per-lane counters ────────────────────────────────────────────────────────

interface LaneStats {
  generated: number;
  blocked: number;
  duplicates: number;
  contradictions: number;
  nearDuplicates: number;
  degenerate: number;
  /**
   * Claims decided by the prose fallback because the cluster carried fewer
   * than two usable shared entities. The count that tells us whether the
   * entity rule is actually reaching most claims — see logIdentityBasis.
   */
  identityFallbacks: number;
  /** Clusters routed here after the lane had already hit maxQuestionsPerLane. */
  capped: number;
  /** One quality-gate reason per blocked candidate, so a lane that blocks
   *  everything is diagnosable and not merely countable. */
  blockReasons: string[];
}

function emptyStats(): LaneStats {
  return {
    generated: 0,
    blocked: 0,
    duplicates: 0,
    contradictions: 0,
    nearDuplicates: 0,
    degenerate: 0,
    identityFallbacks: 0,
    capped: 0,
    blockReasons: [],
  };
}

/**
 * Emit the identity evidence for one claim check, on one grep-able tag.
 *
 * MIN_ENTITY_OVERLAP is a hypothesis, not a measurement — there were no
 * cross-day entity measurements to tune it against when it was set. These
 * lines are how it gets tuned: every value match is logged with its computed
 * overlap whether it passed or missed, so a week of real runs yields the
 * distribution of near-misses and matches. `grep '\[DedupOverlap\]'` over the
 * run logs is the whole analysis.
 *
 * A near-miss is the interesting record: a value matched and the overlap did
 * not clear the floor, so a question was generated that may or may not have
 * been a duplicate. A cluster of near-misses at 0.30 says the floor is too
 * high; matches bunched at 0.99 say it could be raised.
 */
function logIdentityBasis(
  verdict: ClaimVerdict,
  entities: readonly string[],
  clusterTitle: string,
): void {
  const usable = normalizeEntities(entities);

  if (verdict.mode === 'topic-fallback') {
    // Logged even when there are no candidates to compare against: the rate
    // at which clusters arrive with too few shared entities is itself the
    // thing to watch. It should now be rare — `sharedEntities` became the
    // pairwise union of joining overlaps, where it was previously the
    // all-articles intersection and emptied out on every cluster larger than
    // two. A fallback rate that stays high is a signal the union is not
    // delivering either.
    console.warn(
      `[DedupOverlap] basis=topic-fallback usableEntities=${usable.length} ` +
      `verdict=${verdict.kind} cluster="${clusterTitle}"`,
    );
  }

  for (const o of verdict.overlaps) {
    console.log(
      `[DedupOverlap] basis=${o.basis} overlap=${o.overlap.toFixed(3)} ` +
      `threshold=${MIN_ENTITY_OVERLAP} matched=${o.matched} ` +
      `usableEntities=${usable.length} existingEntities=${o.existing.entities.length} ` +
      `valueKey="${o.existing.valueKey}" existing=${o.existing.questionExternalId ?? 'unknown'}`,
    );
  }
}

// ─── Pipeline ─────────────────────────────────────────────────────────────────

/**
 * Ingest the feeds once, route each story to exactly one lane, then generate
 * for that lane only.
 *
 * `maxQuestionsPerLane` is a **soft** cap, deliberately. It is checked before
 * a cluster is generated, so a lane sitting at 7 with a cap of 8 can still
 * accept a whole batch and finish at 9 or 10. Clusters skipped once a lane is
 * at or over its cap are counted in that lane's `capped` stat, so the job row
 * shows that material was left on the table rather than implying the feeds
 * ran dry.
 *
 * Nothing is skipped silently: every rejection lands in `generation_jobs.notes`,
 * including rejections that belong to no served lane (`no-target`,
 * `missing-collection`, and cluster errors thrown before a lane was resolved),
 * which are spliced into every served lane's notes.
 */
export async function runNightlyPipeline(
  targets: readonly LaneTarget[],
  options: { dryRun?: boolean; maxQuestionsPerLane?: number } = {},
): Promise<{ status: 'success' | 'failed' }> {
  const { dryRun = false, maxQuestionsPerLane } = options;

  console.log(`[run-pipeline] Nightly run — ${targets.length} lane(s)${dryRun ? ' (DRY RUN)' : ''}`);

  if (targets.length === 0) {
    console.log('[run-pipeline] No lanes registered — nothing to do');
    return { status: 'success' };
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

  // A lane whose collection does not exist yet is skipped, not fatal — see
  // partitionTargets.
  const { served: servedTargets, missing: missingTargets } = partitionTargets(
    targets,
    new Set(idBySlug.keys()),
  );

  const missingLanes: Rejection[] = missingTargets.map(t => {
    console.warn(
      `[run-pipeline] Collection not found, skipping lane=${t.lane} slug=${t.collectionSlug}`,
    );
    return {
      reason: 'missing-collection',
      lane: t.lane,
      collectionSlug: t.collectionSlug,
    };
  });

  if (servedTargets.length === 0) {
    // Effectively unreachable from the cron: it preflights every lane's
    // collection and returns early when none is eligible, so it only ever
    // calls this with lanes whose collections it has already resolved. This
    // exists for the CLI path, where a throw is the only way to say "nothing
    // at all resolved" — it is NOT a reinstatement of the
    // abort-on-any-missing-lane behaviour a correction deliberately removed.
    // A lane whose collection is missing is still skipped with a warning and
    // a `missing-collection` note; only ZERO served lanes throws.
    throw new Error(
      `No lane collections found in DB — nothing to serve (checked: ${slugs.join(', ')})`,
    );
  }

  const targetByLane = new Map(servedTargets.map(t => [t.lane, t]));
  const allCollectionIds = servedTargets.map(t => idBySlug.get(t.collectionSlug)!);

  // ── Run-level state, visible to the finally block ────────────────────────
  // Declared before job-row creation (below) so a DB error partway through
  // that loop can mark the run failed and still be seen by finalisation.
  let pipelineStatus: 'success' | 'failed' = 'success';
  let fatalError: string | null = null;

  // ── One generation_jobs row per served lane ──────────────────────────────
  const jobIdByLane = new Map<Lane, number>();
  if (!dryRun) {
    try {
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
    } catch (err) {
      // A transient DB error partway through this loop must not leave the
      // rows already created stuck at status='running' while pipelineCron's
      // catch inserts competing 'failed' rows for the same lanes — that's
      // the exact duplicate-contradictory-rows defect this pipeline was just
      // fixed for, reached by a different route. The finally block below
      // finalises every row jobIdByLane actually holds (see its lookup
      // there); anything after this point that expected a lane to have a
      // job simply skips that lane. Deliberately not rethrown, same as the
      // fatal-error path further down: rethrowing is what causes the cron to
      // duplicate rows.
      fatalError = err instanceof Error ? err.message : String(err);
      pipelineStatus = 'failed';
      console.error(
        `[run-pipeline] Fatal error creating generation_jobs rows — finalising the ${jobIdByLane.size} row(s) already created: ${fatalError}`,
      );
    }
  }

  const stats = new Map<Lane, LaneStats>(servedTargets.map(t => [t.lane, emptyStats()]));
  const rejections: Rejection[] = [];
  let feedResults: FeedResult[] = [];
  let feedsFailed = 0;
  let clusterCount = 0;
  let clusterErrors = 0;
  let clustersAttempted = 0;

  // One counter per reason a cluster yielded no claim. A single
  // `lowConfidenceSkipped` conflated a low-confidence tier, an unexpected
  // content-block type, a JSON parse failure and an API error — so the notes
  // could not tell "the feeds gave us nothing usable" from "the Anthropic
  // call is failing", which is the first thing anyone will need to know.
  const claimSkips: Record<ClaimSkipReason, number> = {
    'low-confidence': 0,
    'unexpected-content-block': 0,
    'unparseable-response': 0,
    'api-error': 0,
  };

  // Where the router actually sent each story, counted at lane resolution and
  // covering EVERY lane — including lanes this run does not serve.
  //
  // `laneDistribution` in the notes means "questions generated, per served
  // lane", which is a different thing: with one served lane, a night where 60
  // of 68 stories routed to `world` shows up as `{iran: 2}` plus 60
  // individual `no-target` rejection entries. Recoverable, but not
  // summarised. This is the histogram the spec's mitigation for "routing
  // misclassifies a story class systematically" — log lane distribution per
  // run, review after the first week — actually needs.
  //
  // Written as a literal rather than derived from LANE_PRECEDENCE so tsc
  // fails here if a lane is ever added to the union.
  const routedByLane: Record<Lane, number> = { iran: 0, climate: 0, us: 0, world: 0 };

  // Everything from here on is wrapped: the job rows already exist, so they
  // must be finalised even if the run dies half way. Before this was in a
  // `finally`, one throwing cluster stranded every lane's row at
  // status='running'/generated=0 — including lanes whose questions had
  // already been written and committed.
  try {
    // ── Ingest ONCE ────────────────────────────────────────────────────────
    if (pipelineStatus === 'failed') {
      // generation_jobs row creation already failed fatally (see above) —
      // nothing to route or generate for. feedResults stays [], so clusters
      // below resolves to 0 and the cluster loop is a no-op; execution falls
      // straight through to finalising whatever rows were actually created.
      console.log('[run-pipeline] Skipping feed ingest — generation_jobs row creation already failed');
    } else {
      try {
        feedResults = await fetchAllFeeds(INTERNATIONAL_FEEDS);
      } catch (err) {
        fatalError = err instanceof Error ? err.message : String(err);
        console.error(`[run-pipeline] Fatal error during feed fetch: ${fatalError}`);
        pipelineStatus = 'failed';
      }
    }

    feedsFailed = feedResults.filter(r => r.error).length;
    for (const result of feedResults) {
      console.log(
        result.error
          ? `[${result.feedName}] FAILED (${result.feedUrl}): ${result.error}`
          : `[${result.feedName}] ${result.articles.length} articles ready`,
      );
    }

    // A total feed blackout is the pipeline's most likely failure mode — the
    // feed set is three, and feed rot is silent. `fetchAllFeeds` does not
    // throw when individual feeds fail, it reports per-feed `error` fields, so
    // every-feed-failed produces zero articles, zero clusters, and
    // clustersAttempted === 0, which the systemic-cluster check below skips by
    // its own guard. Without this the run finalises as 'success' with zero
    // questions — indistinguishable from a quiet news night, and `status` is
    // the only detection surface anything reads.
    //
    // The `feedResults.length > 0` guard matters: a fatal throw inside
    // `fetchAllFeeds` leaves feedResults empty and has already set
    // pipelineStatus/fatalError above, so this must not double-report it.
    if (feedResults.length > 0 && feedsFailed === feedResults.length) {
      pipelineStatus = 'failed';
      fatalError ??= `All ${feedsFailed} feeds failed`;
      console.error(
        `[run-pipeline] Every feed failed (${feedsFailed}/${feedResults.length}) — marking run failed`,
      );
    }

    const allArticles = feedResults.flatMap(r => r.articles);
    const clusters = clusterArticles(allArticles);
    clusterCount = clusters.length;
    console.log(`[Pipeline] ${allArticles.length} articles → ${clusters.length} clusters`);

    // ── Guards ─────────────────────────────────────────────────────────────
    const guard = makeClaimGuard(createFingerprintStore());
    const checkNearDuplicate = makeNearDuplicateCheck(createSimilarityProbe());

    for (const cluster of clusters) {
      // Hoisted so the catch below can attribute the failure to a lane when
      // one had already been resolved.
      let laneForCluster: Lane | undefined;

      try {
        // Counted here, at the point the per-cluster try block is entered —
        // not at successful completion — so it measures attempts, and the
        // systemic-failure check below (clusterErrors >= clustersAttempted)
        // has a real denominator.
        clustersAttempted++;

        if (dryRun) {
          console.log(`[DryRun] cluster: "${cluster.representativeTitle}"`);
          continue;
        }

        const extraction = await extractClaim(cluster);
        if (!extraction.ok) {
          claimSkips[extraction.reason]++;
          console.log(
            `[Pipeline] No usable claim (${extraction.reason}) — skipping cluster: "${cluster.representativeTitle}"`,
          );
          continue;
        }
        const claimResult = extraction.claim;

        laneForCluster = claimResult.lane;
        routedByLane[claimResult.lane]++;

        const target = targetByLane.get(claimResult.lane);
        if (!target) {
          console.log(`[Pipeline] No target registered for lane=${claimResult.lane} — skipping`);
          rejections.push({
            reason: 'no-target',
            lane: claimResult.lane,
            subject: claimResult.subject,
            cluster: cluster.representativeTitle,
          });
          continue;
        }

        const laneStats = stats.get(target.lane)!;
        if (maxQuestionsPerLane !== undefined && laneStats.generated >= maxQuestionsPerLane) {
          if (laneStats.capped === 0) {
            console.log(
              `[Pipeline] lane=${target.lane} at maxQuestionsPerLane=${maxQuestionsPerLane} (${laneStats.generated} generated) — remaining clusters for this lane will be skipped`,
            );
          }
          laneStats.capped++;
          continue;
        }

        // ── Layer 1: claim fingerprint ───────────────────────────────────────
        const keys = fingerprintClaim(claimResult);

        // Reject before the guard: recording a half-blank key would make every
        // later claim normalising to it read as a duplicate of it.
        if (isDegenerate(keys)) {
          laneStats.degenerate++;
          console.warn(`[Dedup] degenerate claim (blank subject/attribute/value) — skipping: "${claimResult.claim}"`);
          rejections.push({
            reason: 'degenerate-claim',
            lane: target.lane,
            claim: claimResult.claim,
            topicKey: keys.topicKey,
            valueKey: keys.valueKey,
          });
          continue;
        }

        // `cluster.sharedEntities` is read straight off the cluster rather
        // than threaded through ClaimResult: the entities describe the story,
        // not the extracted triple, and the cluster is in scope here.
        const verdict = await guard.check(keys, cluster.sharedEntities);
        logIdentityBasis(verdict, cluster.sharedEntities, cluster.representativeTitle);
        if (verdict.mode === 'topic-fallback') laneStats.identityFallbacks++;

        if (verdict.kind === 'duplicate') {
          laneStats.duplicates++;
          console.log(
            `[Dedup] duplicate of ${verdict.existing.questionExternalId ?? '(unknown)'} ` +
            `(basis=${verdict.basis} overlap=${verdict.overlap.toFixed(3)}) — ` +
            `"${claimResult.subject} / ${claimResult.attribute}"`,
          );
          rejections.push({
            reason: 'duplicate-claim', lane: target.lane, topicKey: keys.topicKey,
            valueKey: keys.valueKey, existing: verdict.existing.questionExternalId,
            basis: verdict.basis, overlap: verdict.overlap,
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

        // ── Generate ─────────────────────────────────────────────────────────
        const candidates = await generateQuestions(claimResult);
        const failing = candidates.filter(q => !q.qualityGate.passed);
        laneStats.blocked += failing.length;
        laneStats.blockReasons.push(...failing.map(q => q.qualityGate.reason));

        let passing = candidates.filter(q => q.qualityGate.passed);

        // ── Layer 2: trigram net, per candidate ──────────────────────────────
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
        // `jobId !== undefined` is belt-and-braces: it is unreachable here.
        // The only route to a lane without a job id is the job-creation catch
        // above, which sets pipelineStatus = 'failed', which skips feed
        // ingest, which leaves this cluster loop a no-op. Kept so the code is
        // safe if that coupling is ever broken — no need to re-derive it.
        if (passing.length > 0 && jobId !== undefined) {
          const written = await writePassingQuestions(
            passing, claimResult, idBySlug.get(target.collectionSlug)!,
            jobId, target.prefix, target.volatility,
          );
          laneStats.generated += written.length;

          // Recorded whenever at least one candidate survived the gates
          // (`passing.length > 0`) — not strictly when a row was written. If
          // every insert hits an external_id conflict, `written` is empty and
          // the fingerprint is still recorded, with questionExternalId: null.
          // That is benign: a conflict means the id already exists, so the
          // content IS present. What is deliberately not remembered is a
          // claim whose candidates were ALL rejected by the gates, so a
          // transient failure does not suppress the story permanently.
          await guard.record(
            keys, cluster.sharedEntities, target.lane, written[0]?.externalId ?? null, jobId,
          );
        }
      } catch (err) {
        // One bad cluster must not cost every lane the rest of the run.
        const errorMsg = err instanceof Error ? err.message : String(err);
        clusterErrors++;
        console.error(
          `[Pipeline] Cluster failed (lane=${laneForCluster ?? 'unresolved'}), continuing: "${cluster.representativeTitle}": ${errorMsg}`,
        );
        rejections.push({
          reason: 'cluster-error',
          lane: laneForCluster,
          cluster: cluster.representativeTitle,
          error: errorMsg,
        });
      }
    }

    // See isSystemicClusterFailure for why "every attempted cluster threw" is
    // the bar, and why zero attempts is not a failure.
    if (isSystemicClusterFailure(clustersAttempted, clusterErrors)) {
      pipelineStatus = 'failed';
      fatalError = fatalError ?? (
        `All ${clustersAttempted} attempted cluster(s) errored — systemic failure, not isolated per-cluster faults`
      );
      console.error(
        `[run-pipeline] Every attempted cluster errored (${clusterErrors}/${clustersAttempted}) — marking run failed`,
      );
    }

    // Extractor-side twin of the feed-blackout guard above. `extractClaim`
    // reports a failure as a discriminated reason counted into `claimSkips`
    // — it does not throw — so an Anthropic API outage lands entirely in
    // `claimSkips['api-error']` and never touches `clusterErrors`. Without
    // this, the guard above never fires and the run finalises as 'success'
    // with zero questions generated: the exact failure this file's other
    // systemic-failure guard exists to catch, just reached from the other
    // counter.
    if (isSystemicClusterFailure(clustersAttempted, claimSkips['api-error'])) {
      pipelineStatus = 'failed';
      fatalError ??= `All ${clustersAttempted} clusters failed extraction with api-error`;
      console.error(
        `[run-pipeline] Every attempted cluster failed extraction with api-error (${claimSkips['api-error']}/${clustersAttempted}) — marking run failed`,
      );
    }
  } catch (err) {
    fatalError = err instanceof Error ? err.message : String(err);
    pipelineStatus = 'failed';
    console.error(
      `[run-pipeline] Fatal error mid-run — finalising job rows anyway: ${fatalError}`,
    );
  } finally {
    // ── Finalise each lane's job row ───────────────────────────────────────
    if (!dryRun) {
      const claimSkipTotal = CLAIM_SKIP_REASONS.reduce((n, r) => n + claimSkips[r], 0);
      console.log(
        `[Pipeline] ${clusterCount} clusters, ${clustersAttempted} attempted, ` +
        `${claimSkipTotal} with no usable claim ` +
        `(${CLAIM_SKIP_REASONS.map(r => `${r}=${claimSkips[r]}`).join(', ')}), ` +
        `${clusterErrors} cluster error(s)`,
      );

      // Rejections that belong to no served lane are spliced into every
      // served lane's notes, so nothing is dropped — see partitionRejections.
      const partitioned = partitionRejections(rejections, new Set(stats.keys()));

      for (const t of servedTargets) {
        const s = stats.get(t.lane)!;
        const jobId = jobIdByLane.get(t.lane);
        if (jobId === undefined) {
          // Row creation itself failed for this lane before it ever got a
          // generation_jobs row (see the try/catch around that loop above)
          // — there is nothing to finalise, and nothing left running for
          // pipelineCron's catch to collide with.
          console.warn(`[run-pipeline] lane=${t.lane}: no generation_jobs row was created — nothing to finalise`);
          continue;
        }
        console.log(
          `[Pipeline] lane=${t.lane}: ${s.generated} generated, ${s.blocked} blocked, ` +
          `${s.duplicates} duplicate, ${s.contradictions} contradiction, ` +
          `${s.nearDuplicates} near-duplicate, ${s.degenerate} degenerate, ` +
          `${s.capped} over-cap, ${s.identityFallbacks} prose-fallback`,
        );

        try {
          await db
            .update(generationJobs)
            .set({
              status: pipelineStatus,
              questionsGenerated: s.generated,
              questionsFlagged: s.blocked,
              questionsActivated: s.generated,
              feedsFailed,
              reason: fatalError ? fatalError.slice(0, 500) : null,
              notes: {
                feedStats: feedResults.map(r => ({
                  feedUrl: r.feedUrl,
                  articlesFound: r.articles.length,
                  articlesSkipped: r.articlesSkipped,
                  ...(r.error ? { error: r.error } : {}),
                })),
                clusters: clusterCount,
                claimSkips,
                clusterErrors,
                clustersAttempted,
                // Questions GENERATED, per SERVED lane. `routedByLane` is the
                // routing histogram — all lanes, counted at resolution.
                laneDistribution: Object.fromEntries(
                  [...stats.entries()].map(([lane, v]) => [lane, v.generated]),
                ),
                routedByLane,
                dedup: {
                  duplicates: s.duplicates,
                  contradictions: s.contradictions,
                  nearDuplicates: s.nearDuplicates,
                  degenerate: s.degenerate,
                },
                capped: s.capped,
                ...(maxQuestionsPerLane !== undefined ? { maxQuestionsPerLane } : {}),
                blockReasons: s.blockReasons,
                rejections: [
                  ...missingLanes,
                  ...partitioned.unroutable,
                  ...partitioned.forLane(t.lane),
                ],
              },
              updatedAt: sql`NOW()`,
            })
            .where(eq(generationJobs.id, jobId));
        } catch (updateErr) {
          // Keep going: one unwritable row must not strand the others.
          console.error(
            `[run-pipeline] Could not finalise generation_jobs id=${jobId} (lane=${t.lane}):`,
            updateErr,
          );
        }
      }

      try {
        const pruned = await pruneClaimFingerprints(30);
        console.log(`[Pipeline] Pruned ${pruned} fingerprints older than 30 days`);
      } catch (pruneErr) {
        console.error('[run-pipeline] Fingerprint prune failed:', pruneErr);
      }
    }
  }

  console.log(`[run-pipeline] Pipeline complete (status=${pipelineStatus}).`);
  return { status: pipelineStatus };
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
