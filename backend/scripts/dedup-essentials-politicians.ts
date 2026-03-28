/**
 * dedup-essentials-politicians.ts — deduplicate active rows in essentials.politicians.
 *
 * Usage:
 *   npx tsx backend/scripts/dedup-essentials-politicians.ts          # dry-run (no changes)
 *   npx tsx backend/scripts/dedup-essentials-politicians.ts --execute # apply changes
 *
 * Requires environment variable:
 *   DATABASE_URL — PostgreSQL connection string (in .env)
 *
 * What it does:
 *   1. Finds all active politicians whose full_name appears more than once.
 *   2. Selects a canonical row per duplicate group using a priority score:
 *      - Has a politician_sources row (+3)
 *      - Has an offices row (+2)
 *      - Count of non-null columns (+0..N)
 *      - Has photo_origin_url (+1)
 *      - Tiebreaker: earliest created_at
 *   3. Re-routes all FK references from spare rows to the canonical row.
 *   4. Deletes spare rows.
 */

import 'dotenv/config';
import { Pool, PoolClient } from 'pg';

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

const isDryRun = !process.argv.includes('--execute');

interface DuplicateGroup {
  full_name: string;
  cnt: number;
  ids: string[];
}

interface PoliticianScore {
  id: string;
  has_source: boolean;
  has_office: boolean;
  non_null_count: number;
  has_photo: boolean;
  last_synced: Date | null;
  score: number;
}

async function findDuplicateGroups(): Promise<DuplicateGroup[]> {
  const result = await pool.query<DuplicateGroup>(`
    SELECT full_name, COUNT(*) as cnt, array_agg(id ORDER BY last_synced NULLS LAST) as ids
    FROM essentials.politicians
    WHERE is_active = true
    GROUP BY full_name
    HAVING COUNT(*) > 1
    ORDER BY full_name;
  `);
  return result.rows;
}

async function scoreGroup(ids: string[]): Promise<PoliticianScore[]> {
  // Query all columns + join to sources and offices for scoring
  const result = await pool.query(`
    SELECT
      p.id,
      (ps.essentials_politician_id IS NOT NULL) AS has_source,
      (o.politician_id IS NOT NULL) AS has_office,
      (
        (p.full_name IS NOT NULL)::int +
        (p.first_name IS NOT NULL)::int +
        (p.last_name IS NOT NULL)::int +
        (p.photo_origin_url IS NOT NULL)::int +
        (p.bio_text IS NOT NULL)::int +
        (p.party IS NOT NULL)::int +
        (p.party_short_name IS NOT NULL)::int +
        (p.slug IS NOT NULL)::int +
        (p.bioguide_id IS NOT NULL)::int +
        (p.external_id IS NOT NULL)::int +
        (p.external_global_id IS NOT NULL)::int +
        (p.photo_custom_url IS NOT NULL)::int +
        (p.last_synced IS NOT NULL)::int +
        (p.leg_data_fetched_at IS NOT NULL)::int +
        (p.total_years_in_office IS NOT NULL)::int +
        (p.data_source IS NOT NULL)::int
      ) AS non_null_count,
      (p.photo_origin_url IS NOT NULL) AS has_photo,
      p.last_synced
    FROM essentials.politicians p
    LEFT JOIN (
      SELECT DISTINCT ON (essentials_politician_id) essentials_politician_id
      FROM transparent_motivations.politician_sources
    ) ps ON ps.essentials_politician_id = p.id
    LEFT JOIN (
      SELECT DISTINCT ON (politician_id) politician_id
      FROM essentials.offices
    ) o ON o.politician_id = p.id
    WHERE p.id = ANY($1::uuid[])
    ORDER BY p.id;
  `, [ids]);

  return result.rows.map(row => ({
    id: row.id,
    has_source: row.has_source,
    has_office: row.has_office,
    non_null_count: parseInt(row.non_null_count, 10),
    has_photo: row.has_photo,
    last_synced: row.last_synced ? new Date(row.last_synced) : null,
    score:
      (row.has_source ? 3 : 0) +
      (row.has_office ? 2 : 0) +
      parseInt(row.non_null_count, 10) +
      (row.has_photo ? 1 : 0),
  }));
}

function selectCanonical(scores: PoliticianScore[]): { canonical: PoliticianScore; spares: PoliticianScore[] } {
  const sorted = [...scores].sort((a, b) => {
    if (b.score !== a.score) return b.score - a.score;
    // Tiebreaker: earliest last_synced (null = never synced = lower priority)
    const aTime = a.last_synced ? a.last_synced.getTime() : Infinity;
    const bTime = b.last_synced ? b.last_synced.getTime() : Infinity;
    return aTime - bTime;
  });
  const [canonical, ...spares] = sorted;
  return { canonical, spares };
}

interface RerouteResult {
  officesRerouted: number;
  contactsRerouted: number;
  imagesRerouted: number;
  degreesRerouted: number;
  experiencesRerouted: number;
  sourcesRerouted: number;
  sourcesDeleted: number;
  // Additional FK tables discovered during execution
  addressesRerouted: number;
  identifiersRerouted: number;
  committeesRerouted: number;
  empoweredProfilesRerouted: number;
  politicianAnswersRerouted: number;
  politicianContextRerouted: number;
  idBridgeRerouted: number;
}

/**
 * Helper: attempt UPDATE with SAVEPOINT. On unique constraint violation (23505),
 * DELETE the spare's row(s) instead. Returns [rerouted, deleted].
 */
async function updateOrDelete(
  client: PoolClient,
  savepointName: string,
  updateSql: string,
  deleteSql: string,
  params: [string, string]
): Promise<[number, number]> {
  await client.query(`SAVEPOINT ${savepointName}`);
  try {
    const res = await client.query(updateSql, params);
    await client.query(`RELEASE SAVEPOINT ${savepointName}`);
    return [res.rowCount ?? 0, 0];
  } catch (err: any) {
    await client.query(`ROLLBACK TO SAVEPOINT ${savepointName}`);
    if (err.code === '23505') {
      const delRes = await client.query(deleteSql, [params[1]]);
      return [0, delRes.rowCount ?? 0];
    }
    throw err;
  }
}

async function rerouteFKsForSpare(
  client: PoolClient,
  canonicalId: string,
  spareId: string
): Promise<RerouteResult> {
  const result: RerouteResult = {
    officesRerouted: 0,
    contactsRerouted: 0,
    imagesRerouted: 0,
    degreesRerouted: 0,
    experiencesRerouted: 0,
    sourcesRerouted: 0,
    sourcesDeleted: 0,
    addressesRerouted: 0,
    identifiersRerouted: 0,
    committeesRerouted: 0,
    empoweredProfilesRerouted: 0,
    politicianAnswersRerouted: 0,
    politicianContextRerouted: 0,
    idBridgeRerouted: 0,
  };

  // offices — unique constraint on politician_id
  const [officesR] = await updateOrDelete(
    client, 'sp_offices',
    `UPDATE essentials.offices SET politician_id = $1 WHERE politician_id = $2`,
    `DELETE FROM essentials.offices WHERE politician_id = $1`,
    [canonicalId, spareId]
  );
  result.officesRerouted = officesR;

  // politician_contacts (no unique constraint on politician_id alone)
  const contactsRes = await client.query(
    `UPDATE essentials.politician_contacts SET politician_id = $1 WHERE politician_id = $2`,
    [canonicalId, spareId]
  );
  result.contactsRerouted = contactsRes.rowCount ?? 0;

  // politician_images (no unique constraint on politician_id alone)
  const imagesRes = await client.query(
    `UPDATE essentials.politician_images SET politician_id = $1 WHERE politician_id = $2`,
    [canonicalId, spareId]
  );
  result.imagesRerouted = imagesRes.rowCount ?? 0;

  // degrees
  const degreesRes = await client.query(
    `UPDATE essentials.degrees SET politician_id = $1 WHERE politician_id = $2`,
    [canonicalId, spareId]
  );
  result.degreesRerouted = degreesRes.rowCount ?? 0;

  // experiences
  const experiencesRes = await client.query(
    `UPDATE essentials.experiences SET politician_id = $1 WHERE politician_id = $2`,
    [canonicalId, spareId]
  );
  result.experiencesRerouted = experiencesRes.rowCount ?? 0;

  // addresses
  const [addressesR] = await updateOrDelete(
    client, 'sp_addresses',
    `UPDATE essentials.addresses SET politician_id = $1 WHERE politician_id = $2`,
    `DELETE FROM essentials.addresses WHERE politician_id = $1`,
    [canonicalId, spareId]
  );
  result.addressesRerouted = addressesR;

  // identifiers
  const [identifiersR] = await updateOrDelete(
    client, 'sp_identifiers',
    `UPDATE essentials.identifiers SET politician_id = $1 WHERE politician_id = $2`,
    `DELETE FROM essentials.identifiers WHERE politician_id = $1`,
    [canonicalId, spareId]
  );
  result.identifiersRerouted = identifiersR;

  // politician_committees
  const [committeesR] = await updateOrDelete(
    client, 'sp_committees',
    `UPDATE essentials.politician_committees SET politician_id = $1 WHERE politician_id = $2`,
    `DELETE FROM essentials.politician_committees WHERE politician_id = $1`,
    [canonicalId, spareId]
  );
  result.committeesRerouted = committeesR;

  // empower.empowered_profiles
  const [empoweredR] = await updateOrDelete(
    client, 'sp_empowered',
    `UPDATE empower.empowered_profiles SET politician_id = $1 WHERE politician_id = $2`,
    `DELETE FROM empower.empowered_profiles WHERE politician_id = $1`,
    [canonicalId, spareId]
  );
  result.empoweredProfilesRerouted = empoweredR;

  // inform.politician_answers
  const [answersR] = await updateOrDelete(
    client, 'sp_answers',
    `UPDATE inform.politician_answers SET politician_id = $1 WHERE politician_id = $2`,
    `DELETE FROM inform.politician_answers WHERE politician_id = $1`,
    [canonicalId, spareId]
  );
  result.politicianAnswersRerouted = answersR;

  // inform.politician_context
  const [contextR] = await updateOrDelete(
    client, 'sp_context',
    `UPDATE inform.politician_context SET politician_id = $1 WHERE politician_id = $2`,
    `DELETE FROM inform.politician_context WHERE politician_id = $1`,
    [canonicalId, spareId]
  );
  result.politicianContextRerouted = contextR;

  // public.politician_id_bridge
  const [bridgeR] = await updateOrDelete(
    client, 'sp_bridge',
    `UPDATE public.politician_id_bridge SET essentials_id = $1 WHERE essentials_id = $2`,
    `DELETE FROM public.politician_id_bridge WHERE essentials_id = $1`,
    [canonicalId, spareId]
  );
  result.idBridgeRerouted = bridgeR;

  // politician_sources — unique constraint on (essentials_politician_id, source_system, external_id)
  // Multi-committee support: check each spare source row individually.
  // If canonical already has the same (source_system, external_id) pair → delete (true duplicate).
  // If the pair is distinct (different committee) → reroute to canonical.
  await client.query('SAVEPOINT sp_sources');
  try {
    const spareSourcesRes = await client.query(
      `SELECT id, source_system, external_id
       FROM transparent_motivations.politician_sources
       WHERE essentials_politician_id = $1`,
      [spareId]
    );
    await client.query('RELEASE SAVEPOINT sp_sources');

    let deletedCount = 0;
    let reroutedCount = 0;

    for (const src of spareSourcesRes.rows) {
      const exists = await client.query(
        `SELECT 1 FROM transparent_motivations.politician_sources
         WHERE essentials_politician_id = $1 AND source_system = $2 AND external_id = $3`,
        [canonicalId, src.source_system, src.external_id]
      );
      if ((exists.rowCount ?? 0) > 0) {
        // True duplicate: canonical already has this (source_system, external_id) — delete spare's row
        await client.query(
          `DELETE FROM transparent_motivations.politician_sources WHERE id = $1`,
          [src.id]
        );
        deletedCount++;
      } else {
        // Distinct committee: reroute spare's source row to canonical
        await client.query(
          `UPDATE transparent_motivations.politician_sources SET essentials_politician_id = $1 WHERE id = $2`,
          [canonicalId, src.id]
        );
        reroutedCount++;
      }
    }

    result.sourcesRerouted = reroutedCount;
    result.sourcesDeleted = deletedCount;
  } catch (err: any) {
    await client.query('ROLLBACK TO SAVEPOINT sp_sources');
    throw err;
  }

  // Delete the spare politician
  await client.query(
    `DELETE FROM essentials.politicians WHERE id = $1`,
    [spareId]
  );

  return result;
}

async function printDryRunGroup(
  fullName: string,
  canonical: PoliticianScore,
  spares: PoliticianScore[]
): Promise<void> {
  console.log(`\n--- Group: "${fullName}" (${spares.length + 1} rows) ---`);
  const canonicalSync = canonical.last_synced ? canonical.last_synced.toISOString().slice(0, 10) : 'never';
  console.log(`  Canonical: ${canonical.id} (score=${canonical.score}, source=${canonical.has_source}, office=${canonical.has_office}, photo=${canonical.has_photo}, last_synced=${canonicalSync})`);

  for (const spare of spares) {
    const spareSync = spare.last_synced ? spare.last_synced.toISOString().slice(0, 10) : 'never';
    console.log(`  Spare:     ${spare.id} (score=${spare.score}, source=${spare.has_source}, office=${spare.has_office}, photo=${spare.has_photo}, last_synced=${spareSync})`);
    console.log(`    Would reroute: offices, politician_contacts, politician_images, degrees, experiences`);
    console.log(`    Would reroute politician_sources (or DELETE if canonical already has same source_system)`);
    console.log(`    Would DELETE essentials.politicians WHERE id = '${spare.id}'`);
  }
}

async function main() {
  console.log(`[dedup-essentials-politicians] Mode: ${isDryRun ? 'DRY-RUN (no changes)' : 'EXECUTE'}`);
  console.log('[dedup-essentials-politicians] Finding duplicate active politicians...');

  const startMs = Date.now();

  const summary = {
    groupsProcessed: 0,
    sparesDeleted: 0,
    officesRerouted: 0,
    contactsRerouted: 0,
    imagesRerouted: 0,
    degreesRerouted: 0,
    experiencesRerouted: 0,
    sourcesRerouted: 0,
    sourcesDeleted: 0,
    addressesRerouted: 0,
    identifiersRerouted: 0,
    committeesRerouted: 0,
    empoweredProfilesRerouted: 0,
    politicianAnswersRerouted: 0,
    politicianContextRerouted: 0,
    idBridgeRerouted: 0,
  };

  try {
    const groups = await findDuplicateGroups();

    if (groups.length === 0) {
      console.log('[dedup-essentials-politicians] No duplicate groups found — nothing to do.');
    } else {
      console.log(`[dedup-essentials-politicians] Found ${groups.length} duplicate group(s).`);
    }

    for (const group of groups) {
      const scores = await scoreGroup(group.ids);
      const { canonical, spares } = selectCanonical(scores);

      if (isDryRun) {
        await printDryRunGroup(group.full_name, canonical, spares);
        summary.groupsProcessed++;
        summary.sparesDeleted += spares.length;
        continue;
      }

      // Execute mode: use a transaction per group
      const client = await pool.connect();
      try {
        await client.query('BEGIN');

        console.log(`\n--- Processing: "${group.full_name}" (${spares.length + 1} rows) ---`);
        console.log(`  Canonical: ${canonical.id} (score=${canonical.score})`);

        for (const spare of spares) {
          console.log(`  Rerouting spare: ${spare.id}`);
          const rerouteResult = await rerouteFKsForSpare(client, canonical.id, spare.id);
          console.log(`    offices=${rerouteResult.officesRerouted}, contacts=${rerouteResult.contactsRerouted}, images=${rerouteResult.imagesRerouted}, degrees=${rerouteResult.degreesRerouted}, experiences=${rerouteResult.experiencesRerouted}, sources_rerouted=${rerouteResult.sourcesRerouted}, sources_deleted=${rerouteResult.sourcesDeleted}`);

          summary.officesRerouted += rerouteResult.officesRerouted;
          summary.contactsRerouted += rerouteResult.contactsRerouted;
          summary.imagesRerouted += rerouteResult.imagesRerouted;
          summary.degreesRerouted += rerouteResult.degreesRerouted;
          summary.experiencesRerouted += rerouteResult.experiencesRerouted;
          summary.sourcesRerouted += rerouteResult.sourcesRerouted;
          summary.sourcesDeleted += rerouteResult.sourcesDeleted;
          summary.addressesRerouted += rerouteResult.addressesRerouted;
          summary.identifiersRerouted += rerouteResult.identifiersRerouted;
          summary.committeesRerouted += rerouteResult.committeesRerouted;
          summary.empoweredProfilesRerouted += rerouteResult.empoweredProfilesRerouted;
          summary.politicianAnswersRerouted += rerouteResult.politicianAnswersRerouted;
          summary.politicianContextRerouted += rerouteResult.politicianContextRerouted;
          summary.idBridgeRerouted += rerouteResult.idBridgeRerouted;
          summary.sparesDeleted++;
        }

        await client.query('COMMIT');
        summary.groupsProcessed++;
        console.log(`  Committed group "${group.full_name}".`);
      } catch (err) {
        await client.query('ROLLBACK');
        console.error(`  ERROR: rolled back group "${group.full_name}":`, err);
        throw err;
      } finally {
        client.release();
      }
    }

    const durationMs = Date.now() - startMs;

    console.log('\n=== DEDUP SUMMARY ===');
    if (isDryRun) {
      console.log('(DRY-RUN — no changes made)');
    }
    console.log(`Groups processed:      ${summary.groupsProcessed}`);
    console.log(`Spares deleted:        ${summary.sparesDeleted}`);
    console.log(`Offices rerouted:      ${summary.officesRerouted}`);
    console.log(`Contacts rerouted:     ${summary.contactsRerouted}`);
    console.log(`Images rerouted:       ${summary.imagesRerouted}`);
    console.log(`Degrees rerouted:      ${summary.degreesRerouted}`);
    console.log(`Experiences rerouted:  ${summary.experiencesRerouted}`);
    console.log(`Sources rerouted:      ${summary.sourcesRerouted}`);
    console.log(`Sources deleted (conflict): ${summary.sourcesDeleted}`);
    console.log(`Addresses rerouted:    ${summary.addressesRerouted}`);
    console.log(`Identifiers rerouted:  ${summary.identifiersRerouted}`);
    console.log(`Committees rerouted:   ${summary.committeesRerouted}`);
    console.log(`Empowered profiles rerouted: ${summary.empoweredProfilesRerouted}`);
    console.log(`Politician answers rerouted: ${summary.politicianAnswersRerouted}`);
    console.log(`Politician context rerouted: ${summary.politicianContextRerouted}`);
    console.log(`ID bridge rerouted:    ${summary.idBridgeRerouted}`);
    console.log(`\nCompleted in ${(durationMs / 1000).toFixed(1)}s`);

    process.exit(0);
  } finally {
    await pool.end();
  }
}

main().catch(err => {
  console.error('[dedup-essentials-politicians] Fatal error:', err);
  process.exit(1);
});
