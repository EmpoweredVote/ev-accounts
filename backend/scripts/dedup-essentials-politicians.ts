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
 *
 * Campaign finance (migration 1668 onwards):
 *   transparent_motivations.politician_sources.essentials_politician_id has a
 *   FOREIGN KEY ... ON DELETE RESTRICT, so every source row must be detached before the spare
 *   politician can be deleted. This script already did that; what it did NOT do was look after
 *   the data hanging off a source row it dropped. Nothing references politician_sources by FK,
 *   so deleting a row that the canonical already had an equivalent of silently orphaned its
 *   contributions — the same defect migrations 1668/1669 cleaned up one level higher. Those rows
 *   are now folded into the canonical's twin source instead of being dropped on the floor.
 */

import 'dotenv/config';
import { Pool, PoolClient } from 'pg';
import { refreshSummaryAggForSource } from '../src/lib/campaignFinanceService.js';

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
      (o.holder_id IS NOT NULL) AS has_office,
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
    -- ADR 0002: "does this record hold a seat?" comes from office_terms, not offices.
    LEFT JOIN (
      SELECT DISTINCT ON (politician_id) politician_id AS holder_id
      FROM essentials.office_current_holder
      WHERE politician_id IS NOT NULL
    ) o ON o.holder_id = p.id
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

/**
 * Two rows sharing a full_name are NOT necessarily the same person, and merging two distinct
 * officeholders is unrecoverable: the spare's term, stances and contributions are moved onto
 * someone else and the spare row is deleted. Grouping by full_name is a name-collision detector,
 * not an identity test, so every group is screened before it is touched.
 *
 * Two signals, either of which proves the group holds more than one person:
 *
 *   1. SEAT CONFLICT — two rows hold office terms on real seats in different governments.
 *      "Candidate for ..." offices are excluded: they are candidacy placeholders, not seats, and
 *      counting them fires on every incumbent running for higher office (Barr, Moulton, Marshall
 *      all hold a seat AND a "Candidate for U.S. Senate" placeholder, and are one person each).
 *
 *   2. RACE CONFLICT — two rows are candidates in different races. A person contests one office
 *      per cycle, so two rows in two races are two people. This catches pairs that detector 1
 *      misses because the challenger holds no seat at all (e.g. "Mike Johnson" = the sitting
 *      U.S. Rep for District 4 and an unrelated District 7 candidate).
 *
 * Screened against the live corpus: 11 of 49 groups flagged, 10 of them genuinely distinct people
 * (Alex Padilla = an Inglewood councilmember and the U.S. Senator; Mike Rogers = three people).
 * The known false positive is a row whose only "seat" is a generic placeholder such as
 * "Indiana Elected Official" — Victoria Spartz trips detector 1 for that reason and is in fact one
 * person. A false positive costs a hand-review; a false negative destroys an officeholder, so the
 * check deliberately errs toward refusing.
 *
 * There is no bypass flag. A blocked group must be merged by hand in a migration, where the
 * reasoning is reviewable, rather than by a scripted heuristic.
 */
async function detectDistinctPersons(ids: string[]): Promise<string[]> {
  const conflicts: string[] = [];

  const seatRes = await pool.query<{ n: string; distinct_seats: string; detail: string }>(
    `WITH seats AS (
       SELECT p.id,
              string_agg(DISTINCT coalesce(g.name, '(orphan office)') || ' / ' || o.title, ' + ') AS seat
       FROM essentials.politicians p
       JOIN essentials.office_terms t ON t.politician_id = p.id
       JOIN essentials.offices o ON o.id = t.office_id
       LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
       LEFT JOIN essentials.governments g ON g.id = ch.government_id
       WHERE p.id = ANY($1::uuid[])
         AND o.title NOT ILIKE 'Candidate for%'
       GROUP BY p.id
     )
     SELECT count(*) AS n, count(DISTINCT seat) AS distinct_seats,
            string_agg(seat, '  ||  ') AS detail
     FROM seats`,
    [ids]
  );
  const seat = seatRes.rows[0];
  if (Number(seat?.n ?? 0) > 1 && Number(seat?.distinct_seats ?? 0) > 1) {
    conflicts.push(`holds two real seats in different governments: ${seat.detail}`);
  }

  const raceRes = await pool.query<{ n: string; distinct_races: string; detail: string }>(
    `WITH cands AS (
       SELECT p.id, string_agg(DISTINCT ra.position_name, ' + ') AS race
       FROM essentials.politicians p
       JOIN essentials.race_candidates rc ON rc.politician_id = p.id
       JOIN essentials.races ra ON ra.id = rc.race_id
       WHERE p.id = ANY($1::uuid[])
       GROUP BY p.id
     )
     SELECT count(*) AS n, count(DISTINCT race) AS distinct_races,
            string_agg(race, '  ||  ') AS detail
     FROM cands`,
    [ids]
  );
  const race = raceRes.rows[0];
  if (Number(race?.n ?? 0) > 1 && Number(race?.distinct_races ?? 0) > 1) {
    conflicts.push(`is a candidate in two different races: ${race.detail}`);
  }

  return conflicts;
}

/**
 * Non-blocking risk note. Neither detector above fires when one row is a bare stub, yet a stub can
 * still carry campaign finance sources that a merge would reattribute to whoever wins. That is the
 * same failure mode as the surname-substring mislinks (migrations 1664/1665), so it is surfaced
 * rather than silently accepted — but it is not proof of anything, so it does not block.
 */
async function financeRiskNote(spareIds: string[]): Promise<string | null> {
  const res = await pool.query<{ cnt: string }>(
    `SELECT COUNT(*) AS cnt FROM transparent_motivations.politician_sources
     WHERE essentials_politician_id = ANY($1::uuid[])`,
    [spareIds]
  );
  const n = Number(res.rows[0]?.cnt ?? 0);
  return n > 0
    ? `${n} campaign finance source(s) on the spare row(s) will be reattributed to the canonical record`
    : null;
}

interface RerouteResult {
  officesRerouted: number;
  contactsRerouted: number;
  imagesRerouted: number;
  degreesRerouted: number;
  experiencesRerouted: number;
  sourcesRerouted: number;
  sourcesDeleted: number;
  contributionsMoved: number;
  ingestArtefactsMoved: number;
  /** Canonical source ids that received contributions and need their agg recomputed post-commit. */
  aggRefreshTargets: string[];
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
    // 23505 = unique_violation. 23P01 = exclusion_violation, which is what
    // essentials.office_terms raises (office_terms_no_overlap) when the canonical record already
    // holds an overlapping term on the same office — i.e. both records occupy the same seat, which
    // is precisely what a merge exists to collapse. Both mean "the target already has this
    // relationship", so both fall through to dropping the spare's row.
    if (err.code === '23505' || err.code === '23P01') {
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
    contributionsMoved: 0,
    ingestArtefactsMoved: 0,
    aggRefreshTargets: [],
    addressesRerouted: 0,
    identifiersRerouted: 0,
    committeesRerouted: 0,
    empoweredProfilesRerouted: 0,
    politicianAnswersRerouted: 0,
    politicianContextRerouted: 0,
    idBridgeRerouted: 0,
  };

  // office_terms — ADR 0002: occupancy lives here, NOT on essentials.offices (politician_id was
  // dropped in phase 5). Re-point the spare's tenures to the canonical record; the seat rows
  // themselves are shared and need no change. Guarded by office_terms_no_overlap, so if the
  // canonical record already holds an overlapping term on the same office the spare's duplicate
  // term is dropped instead (see updateOrDelete).
  const [officesR] = await updateOrDelete(
    client, 'sp_office_terms',
    `UPDATE essentials.office_terms SET politician_id = $1 WHERE politician_id = $2`,
    `DELETE FROM essentials.office_terms WHERE politician_id = $1`,
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

  // politician_sources — unique constraint on (essentials_politician_id, source_system, external_id).
  // Every one of the spare's source rows MUST be moved or deleted here: since migration 1668 the
  // column carries a FOREIGN KEY ... ON DELETE RESTRICT, so the politician delete below fails if
  // any source is left pointing at the spare. That is the intended behaviour — it is what stops a
  // merge from silently stranding a politician's finance data.
  //
  // Multi-committee support: check each spare source row individually.
  //   canonical already has the same (source_system, external_id) → same committee, fold the spare
  //     into the canonical row: MOVE its data across, then drop the now-empty row.
  //   pair is distinct (different committee) → reroute the row itself to canonical.
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
      const twin = await client.query<{ id: string }>(
        `SELECT id FROM transparent_motivations.politician_sources
         WHERE essentials_politician_id = $1 AND source_system = $2 AND external_id = $3
         LIMIT 1`,
        [canonicalId, src.source_system, src.external_id]
      );

      if ((twin.rowCount ?? 0) > 0) {
        const canonicalSourceId = twin.rows[0].id;

        // Nothing references politician_sources by FK, so deleting this row would NOT raise —
        // it would silently orphan every contribution hanging off it. Move the data first.
        //
        // contributions is unique on (data_source, source_transaction_id), which does not include
        // politician_source_id, so the same transaction cannot already exist under the canonical
        // source and this UPDATE cannot conflict.
        const movedContribs = await client.query(
          `UPDATE transparent_motivations.contributions
           SET politician_source_id = $1 WHERE politician_source_id = $2`,
          [canonicalSourceId, src.id]
        );
        result.contributionsMoved += movedContribs.rowCount ?? 0;
        if ((movedContribs.rowCount ?? 0) > 0 && !result.aggRefreshTargets.includes(canonicalSourceId)) {
          result.aggRefreshTargets.push(canonicalSourceId);
        }

        // ingestion_runs and committees are keyed by their own id — a plain move is safe.
        const movedRuns = await client.query(
          `UPDATE transparent_motivations.ingestion_runs
           SET politician_source_id = $1 WHERE politician_source_id = $2`,
          [canonicalSourceId, src.id]
        );
        const movedCommittees = await client.query(
          `UPDATE transparent_motivations.committees
           SET politician_source_id = $1 WHERE politician_source_id = $2`,
          [canonicalSourceId, src.id]
        );
        result.ingestArtefactsMoved += (movedRuns.rowCount ?? 0) + (movedCommittees.rowCount ?? 0);

        // fec_ingest_window_progress is keyed by
        // (politician_source_id, election_cycle, committee_id, window_start, window_end), so the
        // canonical source may already have covered the same window. It is a resumability
        // bookmark, not data: on collision the spare's row is redundant and gets dropped.
        const [movedWindows] = await updateOrDelete(
          client, `sp_windows_${deletedCount}`,
          `UPDATE transparent_motivations.fec_ingest_window_progress
           SET politician_source_id = $1 WHERE politician_source_id = $2`,
          `DELETE FROM transparent_motivations.fec_ingest_window_progress WHERE politician_source_id = $1`,
          [canonicalSourceId, src.id]
        );
        result.ingestArtefactsMoved += movedWindows;

        // contribution_summary_agg is a derived cache keyed by (politician_source_id,
        // election_cycle) — never move it, it is recomputed from the contributions we just moved.
        // Drop BOTH sides: the spare's rows are dead, and the canonical's are now stale because
        // they predate the contributions we just folded in. Deleting rather than leaving them
        // stale is what makes the post-commit refresh optional — getSummary falls back to a live
        // scan for any cycle with no agg row, so a failed refresh costs speed, never accuracy.
        // Leaving them in place would quietly undercount the profile instead.
        await client.query(
          `DELETE FROM transparent_motivations.contribution_summary_agg
           WHERE politician_source_id = ANY($1::uuid[])`,
          [[src.id, canonicalSourceId]]
        );

        await client.query(
          `DELETE FROM transparent_motivations.politician_sources WHERE id = $1`,
          [src.id]
        );
        deletedCount++;
      } else {
        // Distinct committee: reroute spare's source row to canonical. Contributions ride along
        // untouched — they reference the source row, which keeps its id.
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

  // Belt and braces: prove no source still points at the spare before deleting it. Without this
  // the FK would reject the delete with a bare constraint error naming neither politician.
  const leftover = await client.query<{ cnt: string }>(
    `SELECT COUNT(*) AS cnt FROM transparent_motivations.politician_sources
     WHERE essentials_politician_id = $1`,
    [spareId]
  );
  if (Number(leftover.rows[0].cnt) > 0) {
    throw new Error(
      `refusing to delete politician ${spareId}: ${leftover.rows[0].cnt} politician_sources row(s) ` +
      `still reference it (FK politician_sources_essentials_politician_id_fkey would block this)`
    );
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
    console.log(`    Would reroute politician_sources; where canonical already holds the same`);
    console.log(`      (source_system, external_id), would MOVE that row's contributions,`);
    console.log(`      ingestion_runs, committees and window bookmarks onto the canonical source`);
    console.log(`      first, then drop the emptied row and recompute its summary agg`);
    console.log(`    Would DELETE essentials.politicians WHERE id = '${spare.id}'`);
  }
}

async function main() {
  console.log(`[dedup-essentials-politicians] Mode: ${isDryRun ? 'DRY-RUN (no changes)' : 'EXECUTE'}`);
  console.log('[dedup-essentials-politicians] Finding duplicate active politicians...');

  const startMs = Date.now();

  const blocked: Array<{ name: string; reasons: string[] }> = [];

  const summary = {
    groupsProcessed: 0,
    groupsBlocked: 0,
    sparesDeleted: 0,
    officesRerouted: 0,
    contactsRerouted: 0,
    imagesRerouted: 0,
    degreesRerouted: 0,
    experiencesRerouted: 0,
    sourcesRerouted: 0,
    sourcesDeleted: 0,
    contributionsMoved: 0,
    ingestArtefactsMoved: 0,
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
      // Screen BEFORE scoring is acted on: a name collision must never reach the merge path,
      // in dry-run or execute.
      const conflicts = await detectDistinctPersons(group.ids);
      if (conflicts.length > 0) {
        console.log(`\n--- BLOCKED: "${group.full_name}" (${group.ids.length} rows) ---`);
        for (const c of conflicts) console.log(`  ! ${c}`);
        console.log(`  These rows are NOT the same person. Skipping — merge by hand in a migration`);
        console.log(`  if review shows otherwise (a generic placeholder seat can trip this).`);
        summary.groupsBlocked++;
        blocked.push({ name: group.full_name, reasons: conflicts });
        continue;
      }

      const scores = await scoreGroup(group.ids);
      const { canonical, spares } = selectCanonical(scores);

      const risk = await financeRiskNote(spares.map(s => s.id));
      if (risk) console.log(`\n  NOTE ("${group.full_name}"): ${risk}`);

      if (isDryRun) {
        await printDryRunGroup(group.full_name, canonical, spares);
        summary.groupsProcessed++;
        summary.sparesDeleted += spares.length;
        continue;
      }

      // Execute mode: use a transaction per group
      const aggRefreshTargets = new Set<string>();
      const client = await pool.connect();
      try {
        await client.query('BEGIN');

        console.log(`\n--- Processing: "${group.full_name}" (${spares.length + 1} rows) ---`);
        console.log(`  Canonical: ${canonical.id} (score=${canonical.score})`);

        for (const spare of spares) {
          console.log(`  Rerouting spare: ${spare.id}`);
          const rerouteResult = await rerouteFKsForSpare(client, canonical.id, spare.id);
          console.log(`    offices=${rerouteResult.officesRerouted}, contacts=${rerouteResult.contactsRerouted}, images=${rerouteResult.imagesRerouted}, degrees=${rerouteResult.degreesRerouted}, experiences=${rerouteResult.experiencesRerouted}, sources_rerouted=${rerouteResult.sourcesRerouted}, sources_folded=${rerouteResult.sourcesDeleted}, contributions_moved=${rerouteResult.contributionsMoved}, ingest_artefacts_moved=${rerouteResult.ingestArtefactsMoved}`);

          for (const target of rerouteResult.aggRefreshTargets) aggRefreshTargets.add(target);
          summary.contributionsMoved += rerouteResult.contributionsMoved;
          summary.ingestArtefactsMoved += rerouteResult.ingestArtefactsMoved;
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

      // Post-commit: recompute the agg for any canonical source that absorbed contributions.
      // Deliberately outside the transaction — refreshSummaryAggForSource uses the service pool,
      // and it must read committed data. A failure here is not fatal: the agg rows for the moved
      // cycles were deleted, so getSummary falls back to a live scan and still reports correctly.
      for (const sourceId of aggRefreshTargets) {
        try {
          await refreshSummaryAggForSource(sourceId);
          console.log(`  Refreshed summary agg for source ${sourceId}.`);
        } catch (err) {
          console.warn(
            `  WARN: agg refresh failed for source ${sourceId}. Totals stay CORRECT — the stale agg ` +
            `rows were deleted in the transaction, so getSummary serves this source by live scan. ` +
            `Re-run scripts/030-backfill-summary-agg.ts to restore the cache and the fast path.`,
            err instanceof Error ? err.message : String(err)
          );
        }
      }
    }

    const durationMs = Date.now() - startMs;

    console.log('\n=== DEDUP SUMMARY ===');
    if (isDryRun) {
      console.log('(DRY-RUN — no changes made)');
    }
    console.log(`Groups processed:      ${summary.groupsProcessed}`);
    console.log(`Groups BLOCKED (not one person): ${summary.groupsBlocked}`);
    console.log(`Spares deleted:        ${summary.sparesDeleted}`);
    console.log(`Offices rerouted:      ${summary.officesRerouted}`);
    console.log(`Contacts rerouted:     ${summary.contactsRerouted}`);
    console.log(`Images rerouted:       ${summary.imagesRerouted}`);
    console.log(`Degrees rerouted:      ${summary.degreesRerouted}`);
    console.log(`Experiences rerouted:  ${summary.experiencesRerouted}`);
    console.log(`Sources rerouted:      ${summary.sourcesRerouted}`);
    console.log(`Sources folded into canonical twin: ${summary.sourcesDeleted}`);
    console.log(`Contributions moved:   ${summary.contributionsMoved}`);
    console.log(`Ingest artefacts moved: ${summary.ingestArtefactsMoved}`);
    console.log(`Addresses rerouted:    ${summary.addressesRerouted}`);
    console.log(`Identifiers rerouted:  ${summary.identifiersRerouted}`);
    console.log(`Committees rerouted:   ${summary.committeesRerouted}`);
    console.log(`Empowered profiles rerouted: ${summary.empoweredProfilesRerouted}`);
    console.log(`Politician answers rerouted: ${summary.politicianAnswersRerouted}`);
    console.log(`Politician context rerouted: ${summary.politicianContextRerouted}`);
    console.log(`ID bridge rerouted:    ${summary.idBridgeRerouted}`);
    if (blocked.length > 0) {
      console.log(`\n=== BLOCKED GROUPS (${blocked.length}) — these are not duplicates ===`);
      for (const b of blocked) {
        console.log(`  ${b.name}`);
        for (const r of b.reasons) console.log(`    - ${r}`);
      }
      console.log(`\nEach needs a hand-written migration, not a scripted merge.`);
    }

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
