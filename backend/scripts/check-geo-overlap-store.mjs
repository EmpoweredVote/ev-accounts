#!/usr/bin/env node
/**
 * check-geo-overlap-store — THE ANSWER DOES NOT CHANGE.
 *
 * CC_0511 moved overlap resolution from "recompute every hour" to "compute once
 * per boundary version and per resolver fingerprint, and keep the answer". The
 * whole design is subordinate to one claim: for every seed, the stored answer is
 * the answer a fresh computation gives. Not nearly. Not usually. Identically.
 *
 * WHAT IT COMPARES, per seed:
 *   1. the PAIR SET — what is stored in essentials.geo_overlap_pairs at the
 *      current (geofence_version, query_fingerprint), against a fresh run of
 *      OVERLAP_QUERY_SQL;
 *   2. the DISTRICT SET — the essentials.districts rows that survive
 *      MTFCC_DISTRICT_TYPE_GUARD for each of those pair sets. This is the one a
 *      voter actually sees, and it is not implied by (1): the guard admits a
 *      pair only for the district types its MTFCC may legitimately resolve to.
 *
 * 🔴 IT IMPORTS OVERLAP_QUERY_SQL AND MTFCC_DISTRICT_TYPE_GUARD, IT NEVER
 * RETYPES THEM. A checker carrying its own copy of the query it is checking
 * tests that the copy agrees with itself. That is why this runs under tsx: so a
 * .mjs script can import the TypeScript the service actually uses.
 *
 * THE SAMPLE IS NAMED, NOT DERIVED. One real seed from each of G4000, G4020,
 * G4110, G4040, G5200 and X0001, plus California (the 12,103-vertex outline
 * this work exists for) and Texas (254 counties).
 * ⚠ It is deliberately NOT taken from AREA_SEED_MTFCCS, the nearest-looking
 *   constant: that list holds neither G4000 — the layer this work warms — nor
 *   G5200, which getPoliticiansByArea passes on the split-district path. A
 *   sample drawn from it would have missed both seeds the work is about.
 *
 * 🔴 EVERY SEED PRINTS ITS NUMBERS, PASS OR FAIL, and the run prints how many
 * seeds and how many district rows it examined. A predicate of several
 * conditions fails for exactly one reason and nothing prints which; a passing
 * row that prints nothing leaves the verdict readable while the evidence for it
 * is not.
 *
 * 🔴 DISTRICT LABELS PRINT AT FULL WIDTH, beside ocd_id. Truncating a label
 * manufactures findings shaped exactly like duplicates: "Congressional District "
 * is 23 characters, so a 24-character column collapses every two-digit district
 * onto its first digit (2026-11-02, reported as a race-mapping bug, retracted).
 *
 * USAGE
 *   npm run check:geo-overlap-store            # the real check, against prod
 *   npm run check:geo-overlap-store:selftest   # the positive control
 *
 * EXIT CODES
 *   0  every seed identical (or, with --selftest, the detector went red as it
 *      must)
 *   1  a seed differs — the stored answer is not the computed answer
 *   2  the check could not run, or it ran blind (zero seeds or zero district
 *      rows examined, which is a broken detector reporting "nothing found")
 */
import 'dotenv/config';

import { pool } from '../src/lib/db.js';
import {
  OVERLAP_QUERY_SQL,
  OVERLAP_QUERY_FINGERPRINT,
  resolveOverlappingGeoPairs,
} from '../src/lib/essentialsBrowseService.js';
import { MTFCC_DISTRICT_TYPE_GUARD } from '../src/lib/geoIdGuard.js';

const SELFTEST = process.argv.includes('--selftest');

/**
 * One real seed from every layer that can be browsed, plus the two states whose
 * cost prompted this work. Verified present on prod 2026-11-24.
 */
const SAMPLE = [
  { geo_id: '06', mtfcc: 'G4000', label: 'California (12,103-vertex outline)' },
  { geo_id: '48', mtfcc: 'G4000', label: 'Texas (254 counties)' },
  { geo_id: '06001', mtfcc: 'G4020', label: 'Alameda County' },
  { geo_id: '0600296', mtfcc: 'G4110', label: 'Adelanto city' },
  { geo_id: '0600190020', mtfcc: 'G4040', label: 'Alameda CCD' },
  { geo_id: '0601', mtfcc: 'G5200', label: 'Congressional District 1 (CA)' },
  { geo_id: 'alhambra-council-district-1', mtfcc: 'X0001', label: 'Alhambra City Council District 1' },
];

/**
 * More than two seeds, from more than one layer. The design measured composition
 * on two-seed cases, including a nested one, and left this open.
 */
const COMPOSITION_SEEDS = [
  { geo_id: '06001', mtfcc: 'G4020' },
  { geo_id: '0600296', mtfcc: 'G4110' },
  { geo_id: '0601', mtfcc: 'G5200' },
];

const key = (p) => `${p.geo_id}::${p.mtfcc}`;
const sortedKeys = (pairs) => pairs.map(key).sort();
const sameSet = (a, b) => a.length === b.length && a.every((v, i) => v === b[i]);

// ───────────────────────────────────────────────────────────── readers ──

async function readVersion(client) {
  const { rows } = await client.query(
    `SELECT version::text AS version FROM essentials.geofence_version LIMIT 1`
  );
  return rows[0]?.version ?? null;
}

/** The stored answer, or null when this seed has no row at this exact key. */
async function readStored(client, seed, version, fingerprint) {
  const { rows } = await client.query(
    `SELECT pairs, pair_count
       FROM essentials.geo_overlap_pairs
      WHERE seed_geo_id = $1 AND seed_mtfcc = $2
        AND geofence_version = $3::bigint AND query_fingerprint = $4`,
    [seed.geo_id, seed.mtfcc, version, fingerprint]
  );
  if (rows.length === 0) return null;
  return { pairs: rows[0].pairs ?? [], pairCount: rows[0].pair_count };
}

/** A fresh run of the resolver's own SQL. No cache, no store. */
async function computePairs(client, seeds) {
  const { rows } = await client.query(OVERLAP_QUERY_SQL, [
    seeds.map((s) => s.geo_id),
    seeds.map((s) => s.mtfcc),
  ]);
  return rows.map((r) => ({ geo_id: r.geo_id, mtfcc: r.mtfcc }));
}

/** The districts a pair set reaches THROUGH THE GUARD — what a voter sees. */
async function districtsFor(client, pairs) {
  if (pairs.length === 0) return [];
  const { rows } = await client.query(
    `SELECT DISTINCT d.id::text AS id, d.geo_id, d.district_type, d.state, d.label, d.ocd_id
       FROM essentials.districts d
       JOIN unnest($1::text[], $2::text[]) AS gp(geo_id, mtfcc)
         ON gp.geo_id = d.geo_id AND ${MTFCC_DISTRICT_TYPE_GUARD}
      ORDER BY d.id::text`,
    [pairs.map((p) => p.geo_id), pairs.map((p) => p.mtfcc)]
  );
  return rows;
}

// ──────────────────────────────────────────────────────────── the check ──

/** Compare one seed. Returns a row for the report; never prints. */
async function compareSeed(client, seed, version, fingerprint) {
  const stored = await readStored(client, seed, version, fingerprint);
  const computed = await computePairs(client, [seed]);

  if (stored === null) {
    return { seed, status: 'NOT STORED', storedPairs: null, computedPairs: computed.length };
  }

  const storedKeys = sortedKeys(stored.pairs);
  const computedKeys = sortedKeys(computed);
  const pairsMatch = sameSet(storedKeys, computedKeys);

  const storedDistricts = await districtsFor(client, stored.pairs);
  const computedDistricts = await districtsFor(client, computed);
  const districtsMatch = sameSet(
    storedDistricts.map((d) => d.id),
    computedDistricts.map((d) => d.id)
  );

  // Which halves disagree, named separately — a verdict with one reason is a
  // verdict somebody can act on.
  const reasons = [];
  if (!pairsMatch) reasons.push('pair set differs');
  if (!districtsMatch) reasons.push('district set differs');
  if (stored.pairCount !== stored.pairs.length) {
    reasons.push(`pair_count ${stored.pairCount} != stored pairs ${stored.pairs.length}`);
  }

  return {
    seed,
    status: reasons.length === 0 ? 'OK' : 'DIFFERS',
    reasons,
    storedPairs: storedKeys.length,
    computedPairs: computedKeys.length,
    storedDistricts,
    computedDistricts,
    onlyStored: storedKeys.filter((k) => !computedKeys.includes(k)),
    onlyComputed: computedKeys.filter((k) => !storedKeys.includes(k)),
  };
}

function printSeedRow(r) {
  const head = `  ${r.seed.mtfcc.padEnd(10)} ${r.seed.geo_id.padEnd(30)} ${r.seed.label ?? ''}`;
  if (r.status === 'NOT STORED') {
    console.log(`${head}\n      NOT STORED — computed ${r.computedPairs} pairs, nothing to compare`);
    return;
  }
  console.log(
    `${head}\n      pairs stored=${r.storedPairs} computed=${r.computedPairs}  ` +
      `districts stored=${r.storedDistricts.length} computed=${r.computedDistricts.length}  ` +
      `[${r.status}]`
  );
  if (r.status === 'DIFFERS') {
    for (const why of r.reasons) console.log(`      ↳ ${why}`);
    for (const k of r.onlyStored) console.log(`      ↳ only in the STORE:   ${k}`);
    for (const k of r.onlyComputed) console.log(`      ↳ only in the COMPUTE: ${k}`);
    // Full width. Never slice a district label.
    const byId = new Map(r.computedDistricts.map((d) => [d.id, d]));
    for (const d of r.storedDistricts) {
      if (!byId.has(d.id)) {
        console.log(`      ↳ district only in the STORE:   ${d.ocd_id ?? '(no ocd_id)'}  ${d.label}`);
      }
    }
    const storedIds = new Set(r.storedDistricts.map((d) => d.id));
    for (const d of r.computedDistricts) {
      if (!storedIds.has(d.id)) {
        console.log(`      ↳ district only in the COMPUTE: ${d.ocd_id ?? '(no ocd_id)'}  ${d.label}`);
      }
    }
  }
}

// ──────────────────────────────────────────────── staleness is unreachable ──

/**
 * The design's named anti-goal, so it gets its own check rather than riding
 * along inside another one: once the version moves, the stored row must become
 * UNREADABLE, not merely old. Everything here happens inside a transaction that
 * is rolled back, so prod sees none of it.
 */
async function checkStalenessUnreachable(client, fingerprint) {
  console.log('\n── staleness is unreachable ─────────────────────────────────');
  await client.query('BEGIN');
  await client.query("SET LOCAL lock_timeout = '10s'");
  try {
    const before = await readVersion(client);
    const seed = { geo_id: 'ZZ_CC0511_STALE', mtfcc: 'ZZTEST' };
    const marker = [{ geo_id: 'ZZ_MARKER', mtfcc: 'ZZTEST' }];

    await client.query(
      `INSERT INTO essentials.geo_overlap_pairs
         (seed_geo_id, seed_mtfcc, geofence_version, query_fingerprint, pairs, pair_count)
       VALUES ($1, $2, $3::bigint, $4, $5::jsonb, 1)`,
      [seed.geo_id, seed.mtfcc, before, fingerprint, JSON.stringify(marker)]
    );

    const readAtOldVersion = await readStored(client, seed, before, fingerprint);
    console.log(`  version ${before}: stored row is ${readAtOldVersion ? 'READABLE' : 'ABSENT'}` +
      `  (expected READABLE)`);
    if (!readAtOldVersion) {
      console.log('  🔴 the fixture did not apply — this control proved nothing');
      await client.query('ROLLBACK');
      return false;
    }

    // Move the version the way an ingest does: write a geofence row.
    await client.query(
      `INSERT INTO essentials.geofence_boundaries (geo_id, mtfcc, name)
       VALUES ('ZZ_CC0511_STALE_BUMP', 'ZZTEST', 'cc0511 staleness probe')`
    );
    const after = await readVersion(client);
    console.log(`  a geofence INSERT moved the version ${before} -> ${after}`);
    if (after === before) {
      console.log('  🔴 the version did not move — the trigger is not firing, so nothing was tested');
      await client.query('ROLLBACK');
      return false;
    }

    const readAtNewVersion = await readStored(client, seed, after, fingerprint);
    const ok = readAtNewVersion === null;
    console.log(
      `  version ${after}: stored row is ${readAtNewVersion ? 'READABLE' : 'ABSENT'}` +
        `  (expected ABSENT — the reader must recompute)  [${ok ? 'OK' : 'FAILED'}]`
    );
    return ok;
  } finally {
    await client.query('ROLLBACK');
  }
}

// ───────────────────────────────────────────────── composition by union ──

/**
 * More than two seeds, from more than one layer: the union of the per-seed
 * answers must equal the single multi-seed answer. That equality is what makes
 * "store one row per seed" a faithful representation of a multi-seed request.
 *
 * ⚠ Compared as ARRAYS IN MEMORY, never by piping ids through files. The
 *   design's own first run was bitten by a file with no trailing newline welding
 *   two ids into one, which reads as a difference that is not there.
 */
async function checkComposition(client) {
  console.log('\n── composition: per-seed union == multi-seed compute ────────');
  const perSeed = [];
  for (const s of COMPOSITION_SEEDS) {
    const pairs = await computePairs(client, [s]);
    perSeed.push(...pairs);
    console.log(`  ${s.mtfcc.padEnd(10)} ${s.geo_id.padEnd(30)} ${pairs.length} pairs`);
  }
  const unionKeys = [...new Set(perSeed.map(key))].sort();
  const together = await computePairs(client, COMPOSITION_SEEDS);
  const togetherKeys = [...new Set(together.map(key))].sort();

  const ok = sameSet(unionKeys, togetherKeys);
  console.log(
    `  union of ${COMPOSITION_SEEDS.length} per-seed results = ${unionKeys.length} pairs;` +
      ` one ${COMPOSITION_SEEDS.length}-seed query = ${togetherKeys.length} pairs  [${ok ? 'OK' : 'FAILED'}]`
  );
  if (!ok) {
    for (const k of unionKeys.filter((x) => !togetherKeys.includes(x))) {
      console.log(`  ↳ only in the per-seed union: ${k}`);
    }
    for (const k of togetherKeys.filter((x) => !unionKeys.includes(x))) {
      console.log(`  ↳ only in the multi-seed run: ${k}`);
    }
  }

  // Positive control: the comparison must be able to SEE a difference. Remove
  // one row and require a red. Without this, an equality that always holds
  // because both sides are empty reads exactly like a pass.
  if (unionKeys.length === 0) {
    console.log('  🔴 both sides are empty — this comparison tested nothing');
    return false;
  }
  const tampered = unionKeys.slice(1);
  const controlRed = !sameSet(tampered, togetherKeys);
  console.log(
    `  positive control: union with 1 of ${unionKeys.length} rows removed reads as ` +
      `${controlRed ? 'DIFFERENT' : 'THE SAME'}  [${controlRed ? 'OK' : 'FAILED — the comparison is blind'}]`
  );
  return ok && controlRed;
}

// ────────────────────────────────────────────────────── the positive control ──

/**
 * Plant a fault, watch the detector go red, then roll it back.
 *
 * 🔴 THE TAMPER IS ASSERTED PRESENT BEFORE THE RED IS BELIEVED. A tamper that
 * did not apply is a control that proved nothing, and it looks exactly like a
 * pass (2026-10-26: a sed that produced a 0-byte migration, on which the dry run
 * reported OK).
 */
async function runSelftest(client, version, fingerprint) {
  console.log('\n══ SELFTEST: does this check actually detect a wrong stored answer? ══\n');

  // Find a sample seed that is stored AND has at least one pair to remove.
  let victim = null;
  for (const seed of SAMPLE) {
    const stored = await readStored(client, seed, version, fingerprint);
    if (stored && stored.pairs.length > 0) {
      victim = { seed, before: stored };
      break;
    }
  }
  if (!victim) {
    console.error('🔴 no stored seed with pairs to tamper — run the real check first. Exit 2.');
    return 2;
  }
  console.log(
    `  victim: ${victim.seed.mtfcc} ${victim.seed.geo_id} (${victim.seed.label}), ` +
      `${victim.before.pairs.length} pairs stored`
  );

  await client.query('BEGIN');
  try {
    // Remove element 0 and leave pair_count alone: one changed thing, so a red
    // names one guard.
    await client.query(
      `UPDATE essentials.geo_overlap_pairs
          SET pairs = pairs - 0
        WHERE seed_geo_id = $1 AND seed_mtfcc = $2
          AND geofence_version = $3::bigint AND query_fingerprint = $4`,
      [victim.seed.geo_id, victim.seed.mtfcc, version, fingerprint]
    );

    // ASSERT THE TAMPER IS PRESENT.
    const after = await readStored(client, victim.seed, version, fingerprint);
    const applied =
      after !== null &&
      after.pairs.length === victim.before.pairs.length - 1 &&
      after.pairCount !== after.pairs.length;
    console.log(
      `  tamper: pairs ${victim.before.pairs.length} -> ${after?.pairs.length}, ` +
        `pair_count still ${after?.pairCount}  [${applied ? 'PRESENT' : 'DID NOT APPLY'}]`
    );
    if (!applied) {
      console.error('🔴 the tamper did not apply, so a red would prove nothing. Exit 2.');
      return 2;
    }

    // Now the detector.
    const r = await compareSeed(client, victim.seed, version, fingerprint);
    printSeedRow(r);

    const districtRows = (r.storedDistricts?.length ?? 0) + (r.computedDistricts?.length ?? 0);
    console.log(`\n  seeds examined: 1   district rows examined: ${districtRows}`);
    if (districtRows === 0) {
      console.error(
        '🔴 the comparison examined ZERO district rows. It can fail, but not on the rows that matter. Exit 2.'
      );
      return 2;
    }

    if (r.status !== 'DIFFERS') {
      console.error('🔴 THE DETECTOR DID NOT GO RED ON A ROW IT WAS TOLD IS WRONG. Exit 1.');
      return 1;
    }
    console.log(
      `\n✅ SELFTEST PASSED — the tamper was present, and the check went red on ` +
        `${victim.seed.mtfcc} ${victim.seed.geo_id}, naming the pair that was removed.`
    );
    return 0;
  } finally {
    await client.query('ROLLBACK');
    const restored = await readStored(client, victim.seed, version, fingerprint);
    console.log(
      `  rolled back: ${victim.seed.geo_id} is back to ${restored?.pairs.length} pairs ` +
        `(was ${victim.before.pairs.length} before the tamper)`
    );
  }
}

// ──────────────────────────────────────────────────────────────── main ──

async function main() {
  const client = await pool.connect();
  let exit = 0;
  try {
    const version = await readVersion(client);
    if (version === null) {
      console.error('🔴 essentials.geofence_version is unreadable — CC_0511 is not applied here. Exit 2.');
      return 2;
    }
    console.log(`geofence_version = ${version}`);
    console.log(`query_fingerprint = ${OVERLAP_QUERY_FINGERPRINT}`);

    if (SELFTEST) {
      return await runSelftest(client, version, OVERLAP_QUERY_FINGERPRINT);
    }

    // Warm any sample seed that is not stored, through the REAL read path, so
    // the comparison below has something of production's making to check.
    for (const seed of SAMPLE) {
      if ((await readStored(client, seed, version, OVERLAP_QUERY_FINGERPRINT)) === null) {
        process.stdout.write(`  warming ${seed.mtfcc} ${seed.geo_id} … `);
        const t0 = Date.now();
        await resolveOverlappingGeoPairs([{ geo_id: seed.geo_id, mtfcc: seed.mtfcc }]);
        console.log(`${Date.now() - t0} ms`);
      }
    }

    console.log('\n── stored answer vs fresh compute ──────────────────────────');
    let districtRowsExamined = 0;
    let seedsCompared = 0;
    for (const seed of SAMPLE) {
      const r = await compareSeed(client, seed, version, OVERLAP_QUERY_FINGERPRINT);
      printSeedRow(r);
      if (r.status !== 'NOT STORED') {
        seedsCompared += 1;
        districtRowsExamined += r.storedDistricts.length + r.computedDistricts.length;
      }
      if (r.status === 'DIFFERS') exit = 1;
    }

    console.log(
      `\n  seeds in sample: ${SAMPLE.length}   seeds compared: ${seedsCompared}   ` +
        `district rows examined: ${districtRowsExamined}`
    );
    // A detector that reports "nothing found" having looked at nothing is a
    // broken detector, not a clean database.
    if (seedsCompared === 0 || districtRowsExamined === 0) {
      console.error(
        '🔴 THIS RUN WAS BLIND: it compared ' +
          `${seedsCompared} seeds and ${districtRowsExamined} district rows. Exit 2.`
      );
      return 2;
    }

    const stale = await checkStalenessUnreachable(client, OVERLAP_QUERY_FINGERPRINT);
    if (!stale) exit = exit || 1;

    const composed = await checkComposition(client);
    if (!composed) exit = exit || 1;

    console.log(
      exit === 0
        ? '\n✅ THE ANSWER DOES NOT CHANGE — every compared seed is identical, staleness is ' +
            'unreachable, and the per-seed answers compose.'
        : '\n🔴 SOMETHING DIFFERS. Read the per-seed lines above; each names its own reason.'
    );
    return exit;
  } finally {
    client.release();
    await pool.end();
  }
}

main()
  .then((code) => process.exit(code))
  .catch((err) => {
    console.error('check-geo-overlap-store failed:', err);
    process.exit(2);
  });
