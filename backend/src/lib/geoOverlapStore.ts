/**
 * geoOverlapStore — the durable, version-invalidated store behind
 * `resolveOverlappingGeoPairs`.
 *
 * Everything that touches `essentials.geo_overlap_pairs` and
 * `essentials.geofence_version` lives here. This module knows nothing about the
 * resolver's SQL: it is *passed* a fingerprint. That keeps the dependency
 * one-way (essentialsBrowseService → geoOverlapStore) and avoids an import
 * cycle, while the SQL text itself stays in essentialsBrowseService.ts where
 * two source-pattern test files read it as text.
 *
 * Design: docs/superpowers/specs/2026-11-24-geo-overlap-precompute-design.md
 */

import { createHash } from 'node:crypto';

import { pool } from './db.js';
import type { GeoPair } from './geoIdGuard.js';

/**
 * Anything that can run a query: the shared pool, or ONE pooled client.
 *
 * 🔴 The warming job must run on a client of its own, because it raises
 * statement_timeout on that connection. Measured on prod 2026-11-24: `ev_api`
 * carries statement_timeout = 30 s, and the `US` row in the G4000 layer — the
 * whole country, not a state — resolves 40,899 pairs in 83 SECONDS. A SET on
 * the pool would land on an arbitrary connection, not necessarily the one the
 * next query uses. Everything else passes nothing and gets the pool, exactly as
 * before.
 */
export interface Queryable {
  query(text: string, values?: unknown[]): Promise<{ rows: any[]; rowCount: number | null }>;
}

/**
 * The identity of the resolver's answer-shaping code, as a short hex digest.
 *
 * 🔴 The input is the resolver's FINISHED SQL text, not a hand-maintained list
 * of constants. All four TypeScript values that change the answer —
 * UNRESOLVABLE_PAIR_MTFCCS, branch 3's seven-MTFCC list, branch 2's
 * ('G4110','G4120') exclusion and MIN_OVERLAP_FRACTION — are already
 * interpolated into, or written literally inside, that string. Hashing the
 * finished text therefore covers all four, and there is no second list that can
 * fall out of step with the first.
 *
 * 16 hex characters of SHA-256: this is a cache key, not a security boundary.
 */
export function fingerprintOf(sql: string): string {
  return createHash('sha256').update(sql, 'utf8').digest('hex').slice(0, 16);
}

/**
 * The composite key. `geo_id` is NOT unique on its own — `(mtfcc, geo_id)` is the
 * real key, and a 5-digit GEOID collides across layers (State House 35 and Salt
 * Lake County are both 49035). Every Map in this feature keys on this.
 */
export function seedKey(p: GeoPair): string {
  return `${p.geo_id}::${p.mtfcc}`;
}

/**
 * The kill switch. The design's named failure mode is a WRONG ANSWER NOBODY CAN
 * SEE, so the operator needs a way to stop reading the store without a migration
 * without applying or reverting a migration. Absent means ON: the store is the
 * normal path, and turning it off is the exception someone chose.
 *
 * ⚠ Read once, here, at module load — so changing it takes a restart. It is not
 * a live switch; it is a switch that needs no database change.
 *
 * ⚠ READ FROM process.env, NOT FROM ./env.js, AND THAT IS DELIBERATE. env.ts calls
 * process.exit(1) on an incomplete environment at module scope. This module is
 * imported by essentialsBrowseService.ts, so importing env.ts here would make
 * every test that imports that service require a full valid environment —
 * measured: it killed four unrelated test files outright. The zod entry in
 * env.ts remains the DECLARATION (and is what the ev-infra record is built
 * from); this is the read. The variable is an optional free string either way.
 */
const storeFlag = process.env.GEO_OVERLAP_STORE_ENABLED?.trim().toLowerCase();
export const OVERLAP_STORE_ENABLED = !(storeFlag === '0' || storeFlag === 'false');

/**
 * The current geofence version, AS A STRING.
 *
 * 🔴 `::text` in the query, and `string` in the signature, are the same decision
 * written twice. node-postgres hands a bigint back as text already; the hazard is
 * a later edit that parses it. Number.MAX_SAFE_INTEGER + 2 round-trips through a
 * JavaScript number as MAX_SAFE_INTEGER + 1 — the wrong version, silently, with
 * nothing thrown anywhere. Keep it text end to end; nothing in this feature does
 * arithmetic on it.
 *
 * Returns null when the row is absent, the table is absent, or the query throws
 * — a deploy that lands before the migration is applied, or a half-applied one.
 * The caller's job is to fall back to computing, not to 500.
 */
let warnedAboutVersionRead = false;

export async function readGeofenceVersion(db: Queryable = pool): Promise<string | null> {
  try {
    const { rows } = await db.query(
      `SELECT version::text AS version FROM essentials.geofence_version LIMIT 1`
    );
    return (rows[0]?.version as string | undefined) ?? null;
  } catch (err) {
    // ⚠ ONCE, NOT EVERY TIME. A silent catch turns "the store became
    // unreachable" into "every browse is 3.3 seconds and nothing anywhere says
    // why" — the degrade is correct and the silence is not. Warning on every
    // request instead would be noise nobody reads, which is the same thing by
    // another route.
    if (!warnedAboutVersionRead) {
      warnedAboutVersionRead = true;
      console.warn(
        '[geoOverlapStore] cannot read the geofence version — every overlap request will ' +
          'recompute from geometry until this is fixed. This warns once per process:',
        err instanceof Error ? err.message : err
      );
    }
    return null;
  }
}

/**
 * The stored answers for the seeds that have one at this exact version AND this
 * exact fingerprint.
 *
 * 🔴 A MISS IS AN ABSENT KEY, AND THAT IS NOT THE SAME AS AN EMPTY ARRAY. A seed
 * can legitimately overlap nothing. Collapsing the two would make every
 * zero-pair seed recompute on every request forever, and the store would look
 * like it was working.
 */
export async function readStoredPairs(
  seeds: GeoPair[],
  version: string,
  fingerprint: string,
  db: Queryable = pool
): Promise<Map<string, GeoPair[]>> {
  const out = new Map<string, GeoPair[]>();
  if (seeds.length === 0) return out;

  const { rows } = await db.query(
    `SELECT p.seed_geo_id, p.seed_mtfcc, p.pairs
       FROM unnest($1::text[], $2::text[]) AS seed(geo_id, mtfcc)
       JOIN essentials.geo_overlap_pairs p
         ON p.seed_geo_id = seed.geo_id
        AND p.seed_mtfcc = seed.mtfcc
        AND p.geofence_version = $3::bigint
        AND p.query_fingerprint = $4`,
    [seeds.map((s) => s.geo_id), seeds.map((s) => s.mtfcc), version, fingerprint]
  );

  for (const r of rows) {
    out.set(seedKey({ geo_id: r.seed_geo_id as string, mtfcc: r.seed_mtfcc as string }),
            (r.pairs as GeoPair[]) ?? []);
  }
  return out;
}

/**
 * Store each seed's whole answer at the given version and fingerprint.
 *
 * 🔴 ON CONFLICT DO UPDATE, not INSERT. The warming job and a live request will
 * collide on (seed, version, fingerprint) — that is the normal case, not the
 * exceptional one, and a unique violation here would be a 500 on a request that
 * had just computed the right answer.
 *
 * ⚠ Duplicate seeds within ONE call are collapsed first, last writer winning.
 * ON CONFLICT DO UPDATE refuses a statement that proposes the same key twice
 * ("cannot affect row a second time"), which is the same 500 by another route.
 */
export async function writeStoredPairs(
  entries: Array<{ seed: GeoPair; pairs: GeoPair[] }>,
  version: string,
  fingerprint: string,
  db: Queryable = pool
): Promise<void> {
  const byKey = new Map<string, { seed: GeoPair; pairs: GeoPair[] }>();
  for (const e of entries) byKey.set(seedKey(e.seed), e);
  const rows = [...byKey.values()];
  if (rows.length === 0) return;

  await db.query(
    `INSERT INTO essentials.geo_overlap_pairs
       (seed_geo_id, seed_mtfcc, geofence_version, query_fingerprint, pairs, pair_count, computed_at)
     SELECT e.geo_id, e.mtfcc, $5::bigint, $6, e.pairs::jsonb, e.pair_count, now()
       FROM unnest($1::text[], $2::text[], $3::text[], $4::int[])
            AS e(geo_id, mtfcc, pairs, pair_count)
     ON CONFLICT (seed_geo_id, seed_mtfcc, geofence_version, query_fingerprint)
     DO UPDATE SET pairs       = EXCLUDED.pairs,
                   pair_count  = EXCLUDED.pair_count,
                   computed_at = EXCLUDED.computed_at`,
    [
      rows.map((e) => e.seed.geo_id),
      rows.map((e) => e.seed.mtfcc),
      rows.map((e) => JSON.stringify(e.pairs)),
      rows.map((e) => e.pairs.length),
      version,
      fingerprint,
    ]
  );
}

/**
 * The subset of `seeds` that exists in essentials.geofence_boundaries.
 *
 * 🔴 THIS IS WHAT KEEPS THE PRIMARY KEY OF A PERMANENT TABLE OUT OF A STRANGER'S
 * HANDS. /by-area and /elections-by-area take geo_id and mtfcc from an
 * unauthenticated request body, validated only as non-empty strings. Without this
 * filter, anyone could add rows to essentials.geo_overlap_pairs at will, forever,
 * by browsing an area that does not exist.
 *
 * Looked up by the (geo_id, mtfcc) key, so it is an index lookup per seed rather
 * than a scan.
 */
export async function filterSeedsPresent(seeds: GeoPair[], db: Queryable = pool): Promise<GeoPair[]> {
  if (seeds.length === 0) return [];
  const { rows } = await db.query(
    `SELECT DISTINCT gb.geo_id, gb.mtfcc
       FROM unnest($1::text[], $2::text[]) AS seed(geo_id, mtfcc)
       JOIN essentials.geofence_boundaries gb
         ON gb.geo_id = seed.geo_id AND gb.mtfcc = seed.mtfcc`,
    [seeds.map((s) => s.geo_id), seeds.map((s) => s.mtfcc)]
  );
  return rows.map((r) => ({ geo_id: r.geo_id as string, mtfcc: r.mtfcc as string }));
}

/**
 * Delete every row that answers a different question from the current one.
 *
 * 🔴 BOTH COLUMNS, AND THE PREDICATE IS `OR`. Sweeping on the version alone
 * would leave every row computed under a superseded RESOLVER sitting on disk at
 * the CURRENT version — readable, and wrong. That is the anti-goal.
 *
 * Returns the number of rows deleted.
 */
export async function sweepSupersededPairs(
  version: string,
  fingerprint: string,
  db: Queryable = pool
): Promise<number> {
  const res = await db.query(
    `DELETE FROM essentials.geo_overlap_pairs
      WHERE geofence_version IS DISTINCT FROM $1::bigint
         OR query_fingerprint IS DISTINCT FROM $2`,
    [version, fingerprint]
  );
  return res.rowCount ?? 0;
}
