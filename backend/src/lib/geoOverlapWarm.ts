/**
 * geoOverlapWarm — store every state's overlap answer before anyone asks for it,
 * then delete the answers to questions nobody is asking any more.
 *
 * WHY IT EXISTS. The durable store (CC_0511) removes the hourly recompute, but a
 * COLD store still makes the first visitor pay for it, and for a state that is
 * 3.3 seconds even warm — branch 3 runs ST_Intersection against a 12,103-vertex
 * outline for California. Civic Spaces reported it as a 7,199 ms app-boot call.
 * Warming the 53 G4000 seeds means no member is ever that first visitor.
 *
 * WHAT IT DOES, in this order:
 *   1. read the version;
 *   2. list the seeds of `seedMtfcc` (default G4000);
 *   3. skip the ones already stored at this (version, fingerprint);
 *   4. compute the rest and write them in ONE upsert;
 *   5. THEN sweep rows at any other version or fingerprint;
 *   6. log one line carrying all five numbers.
 *
 * 🔴 THE SWEEP IS LAST, AND THAT IS NOT TIDINESS. Sweeping first would leave a
 * window in which nothing at all is warm — the cold 7-second call this work
 * exists to remove, manufactured by the job that exists to prevent it.
 *
 * 🟢 IT IS A NEAR NO-OP WHEN EVERYTHING IS CURRENT: three queries and no
 * geometry. That matters because GEO_OVERLAP_WARM_ON_BOOT makes every API
 * instance run it on every deploy. A bounded, correct stampede on a cold store
 * is the trade the design accepts; an unbounded one on every restart is not.
 *
 * ⚠ THE SEED LISTING, MEASURED ON PROD 2026-11-24 WITH `EXPLAIN` (never ANALYZE):
 *
 *     Index Only Scan using geofence_boundaries_geo_id_mtfcc_key
 *       on geofence_boundaries  (cost=0.42..1296.42 rows=91 width=13)
 *       Index Cond: (mtfcc = 'G4000'::text)
 *
 *   The unique key is `(geo_id, mtfcc)` and Postgres 17 cannot skip into the
 *   middle of a composite index, so `mtfcc = …` does NOT lead it and the scan
 *   walks the whole index. It is still cheap — ~1,296, and INDEX ONLY, so it
 *   never touches the 158 MB heap. It returns 53 rows (estimate 91).
 *   🔴 SELECT geo_id, mtfcc ONLY. Adding `geometry` would detoast every polygon
 *   in the table to list 53 state outlines.
 *
 * ⚠ Render cron schedules live in EmpoweredVote/ev-infra's render.yaml, never
 *   here. This module ships the job; its schedule is a PR to that repo.
 *
 * Design: docs/superpowers/specs/2026-11-24-geo-overlap-precompute-design.md
 */

import { pool } from './db.js';
import type { GeoPair } from './geoIdGuard.js';
import { computeOverlapPairs, OVERLAP_QUERY_FINGERPRINT } from './essentialsBrowseService.js';
import {
  seedKey,
  readGeofenceVersion,
  readStoredPairs,
  writeStoredPairs,
  sweepSupersededPairs,
} from './geoOverlapStore.js';

export interface WarmResult {
  /** The geofence version everything was written at, or null if it was unreadable. */
  version: string | null;
  /** The resolver fingerprint those rows were written under. */
  fingerprint: string;
  /** Seeds computed and stored by this run. */
  computed: number;
  /** Seeds already stored at this (version, fingerprint) — the skipped ones. */
  alreadyCurrent: number;
  /** Rows deleted because they answered a superseded question. */
  swept: number;
}

export async function warmGeoOverlapPairs(
  opts: { seedMtfcc?: string; dryRun?: boolean } = {}
): Promise<WarmResult> {
  const seedMtfcc = opts.seedMtfcc ?? 'G4000';
  const dryRun = opts.dryRun ?? false;
  const fingerprint = OVERLAP_QUERY_FINGERPRINT;
  const started = Date.now();

  // 1. The version, first. Everything written below is tagged with this value,
  //    and a run that cannot read it must not guess one.
  const version = await readGeofenceVersion();
  if (version === null) {
    console.log(
      `[geo-overlap-warm] no geofence version readable — nothing warmed. ` +
        `This is the expected shape of a deploy that landed before CC_0511 was applied.`
    );
    return { version: null, fingerprint, computed: 0, alreadyCurrent: 0, swept: 0 };
  }

  // 2. The seeds.
  const { rows } = await pool.query(
    `SELECT geo_id, mtfcc
       FROM essentials.geofence_boundaries
      WHERE mtfcc = $1
      ORDER BY geo_id`,
    [seedMtfcc]
  );
  const seeds: GeoPair[] = rows.map((r) => ({
    geo_id: r.geo_id as string,
    mtfcc: r.mtfcc as string,
  }));

  // 3. What is already current. A hit here is a seed this run must not touch.
  const stored = await readStoredPairs(seeds, version, fingerprint);
  const alreadyCurrent = stored.size;
  const missing = seeds.filter((s) => !stored.has(seedKey(s)));

  // 4. Compute the rest, then write them all in ONE upsert.
  //
  // ⚠ No filterSeedsPresent here, deliberately: these seeds came OUT of
  //   geofence_boundaries three queries ago, so the check that keeps the read
  //   path's caller-supplied seeds out of the primary key has nothing to do.
  const entries: Array<{ seed: GeoPair; pairs: GeoPair[] }> = [];
  for (const seed of missing) {
    entries.push({ seed, pairs: await computeOverlapPairs([seed]) });
  }
  if (entries.length > 0 && !dryRun) {
    await writeStoredPairs(entries, version, fingerprint);
  }

  // 5. The sweep, LAST. See the header.
  const swept = dryRun ? 0 : await sweepSupersededPairs(version, fingerprint);

  const result: WarmResult = {
    version,
    fingerprint,
    computed: entries.length,
    alreadyCurrent,
    swept,
  };

  // 6. One line, all five numbers, and the elapsed time. A green run can be a
  //    no-op; this is how a reader tells which it was without re-deriving it.
  console.log(
    `[geo-overlap-warm]${dryRun ? ' DRY RUN' : ''} mtfcc=${seedMtfcc} ` +
      `version=${version} fingerprint=${fingerprint} seeds=${seeds.length} ` +
      `computed=${result.computed} alreadyCurrent=${result.alreadyCurrent} ` +
      `swept=${result.swept} in ${Date.now() - started}ms`
  );

  return result;
}
