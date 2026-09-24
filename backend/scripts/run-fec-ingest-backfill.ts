/**
 * run-fec-ingest-backfill.ts — resumable, rate-safe FEC Schedule A backfill,
 * single-cycle or multi-cycle (historical).
 *
 * Work unit is a (source, cycle) pair. A pair is "done" when a completed
 * ingestion_run exists for it — so re-runs skip finished work AND do not
 * re-fetch zero-donation pairs. Safe to Ctrl-C and re-run; it resumes.
 *
 * Which cycles per source:
 *   - Cycles come from the fec_candidate_cycles cache (the candidate's actual
 *     active cycles), intersected with [floor, currentCycle]. Run
 *     run-fec-fetch-cycles.ts first to populate it.
 *   - Uncached sources fall back to the current cycle only (logged as a count).
 *
 * Ordering: most-recent cycle first, pilot states (CA, IN) first within a cycle,
 * so the highest-value and pilot data lands first.
 *
 * Rate: the FEC adapter sleeps 4s/page internally; we add 3s between pairs.
 *
 * Usage: tsx scripts/run-fec-ingest-backfill.ts [floorYear] [limit] [maxMinutes]
 *   floorYear  — oldest cycle to ingest (default: current cycle => single cycle)
 *   limit      — max (source,cycle) pairs this run (default: all)
 *   maxMinutes — soft wall-clock budget (default: none)
 */

import 'dotenv/config';
import { pool } from '../src/lib/db.js';
import { runIngestion } from '../src/lib/adapters/runIngestion.js';
import { createFecAdapter } from '../src/lib/adapters/fecAdapter.js';
import { currentFecCycle } from '../src/lib/campaignFinanceScheduler.js';
import type { PoliticianSource } from '../src/lib/campaignFinanceService.js';

const CURRENT = parseInt(currentFecCycle(), 10);
const FLOOR = process.argv[2] ? parseInt(process.argv[2], 10) : CURRENT;
const LIMIT = process.argv[3] ? parseInt(process.argv[3], 10) : Infinity;
const MAX_MINUTES = process.argv[4] ? parseInt(process.argv[4], 10) : Infinity;
const SLEEP_BETWEEN_MS = 3000;
const PILOT_STATES = ['CA', 'IN'];

const sleep = (ms: number): Promise<void> => new Promise(r => setTimeout(r, ms));

interface WorkItem extends PoliticianSource { full_name: string; representing_state: string; cycle: string }

async function getPending(floor: number, current: number): Promise<WorkItem[]> {
  // Expand each confirmed source into (source, cycle) pairs from its cached active
  // cycles (or the current cycle if uncached), within [floor, current], excluding
  // pairs that already have a completed run. Pilot + recency ordered.
  const r = await pool.query<WorkItem>(
    `WITH src AS (
       -- One row per source. Occupancy resolves via office_current_holder (ADR 0002
       -- phase 5); a politician-rooted join fans out when someone holds two offices,
       -- so pick one: the seat in the source's own chamber, a held seat before a
       -- "Candidate for" placeholder, then lowest id for determinism.
       SELECT DISTINCT ON (ps.id)
              ps.id, ps.essentials_politician_id, ps.source_system, ps.external_id,
              ps.research_status, ps.notes, ps.created_at, ps.updated_at,
              p.full_name, o.representing_state,
              cc.election_years
       FROM transparent_motivations.politician_sources ps
       JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
       JOIN essentials.office_current_holder och ON och.politician_id = p.id
       JOIN essentials.offices o ON o.id = och.office_id
       JOIN essentials.chambers c ON c.id = o.chamber_id
       LEFT JOIN transparent_motivations.fec_candidate_cycles cc ON cc.external_id = ps.external_id
       WHERE ps.source_system LIKE 'fec%' AND ps.research_status='confirmed' AND ps.external_id <> ''
       ORDER BY ps.id,
                ((c.name LIKE 'U.S. Senate%') = (ps.source_system = 'fec_senate')) DESC,
                (COALESCE(o.title, '') ILIKE 'Candidate for%') ASC,
                o.id
     ),
     expanded AS (
       SELECT src.*,
              cyc AS cycle_int
       FROM src
       CROSS JOIN LATERAL unnest(
         CASE WHEN src.election_years IS NULL OR array_length(src.election_years,1) IS NULL
              THEN ARRAY[$2]::int[]            -- uncached: current cycle only
              ELSE src.election_years END
       ) AS cyc
       WHERE cyc BETWEEN $1 AND $2 AND cyc % 2 = 0
     )
     SELECT id, essentials_politician_id, source_system, external_id, research_status,
            notes, created_at, updated_at, full_name, representing_state,
            cycle_int::text AS cycle
     FROM expanded e
     WHERE NOT EXISTS (
       SELECT 1 FROM transparent_motivations.ingestion_runs ir
       WHERE ir.politician_source_id = e.id
         AND ir.adapter_name='fec' AND ir.election_cycle = e.cycle_int::text
         AND ir.status IN ('completed','completed_with_warning')
     )
     ORDER BY cycle_int DESC,
              (representing_state = ANY($3::text[])) DESC,
              representing_state, full_name`,
    [floor, current, PILOT_STATES]
  );
  return r.rows;
}

async function main() {
  if (!process.env.FEC_API_KEY) { console.error('ERROR: FEC_API_KEY not set'); process.exit(1); }
  if (!process.env.DATABASE_URL) { console.error('ERROR: DATABASE_URL not set'); process.exit(1); }

  const pending = await getPending(FLOOR, CURRENT);
  const todo = pending.slice(0, LIMIT === Infinity ? pending.length : LIMIT);

  const uncached = await pool.query<{ n: string }>(
    `SELECT COUNT(*) n FROM transparent_motivations.politician_sources ps
     WHERE ps.source_system LIKE 'fec%' AND ps.research_status='confirmed' AND ps.external_id<>''
       AND NOT EXISTS (SELECT 1 FROM transparent_motivations.fec_candidate_cycles cc WHERE cc.external_id=ps.external_id)`
  );

  console.log(`[fec-backfill] floor=${FLOOR} current=${CURRENT} pending_pairs=${pending.length} ` +
    `processing=${todo.length} uncached_sources=${uncached.rows[0]?.n ?? '?'} ` +
    `limit=${LIMIT} maxMinutes=${MAX_MINUTES}`);

  const startMs = Date.now();
  let ok = 0, failed = 0, totalRows = 0;

  for (let i = 0; i < todo.length; i++) {
    if ((Date.now() - startMs) / 60000 >= MAX_MINUTES) {
      console.log(`[fec-backfill] wall-clock budget reached — stopping after ${i} pairs.`);
      break;
    }
    const w = todo[i]!;
    if (i > 0) await sleep(SLEEP_BETWEEN_MS);

    const t0 = Date.now();
    try {
      await runIngestion(createFecAdapter(w.cycle), w, w.cycle);
      const c = await pool.query<{ n: string }>(
        `SELECT COUNT(*) n FROM transparent_motivations.contributions
         WHERE data_source='fec' AND politician_source_id=$1 AND election_cycle=$2`,
        [w.id, w.cycle]
      );
      const n = Number(c.rows[0]?.n ?? 0);
      totalRows += n; ok++;
      const pilot = PILOT_STATES.includes(w.representing_state) ? '★' : ' ';
      console.log(`[fec-backfill] ${pilot} ${i + 1}/${todo.length} [${w.cycle}] ${w.representing_state} ${w.full_name} ` +
        `(${w.external_id}) → ${n} rows [${((Date.now() - t0) / 1000).toFixed(0)}s]`);
    } catch (err) {
      failed++;
      console.error(`[fec-backfill] ✗ ${i + 1}/${todo.length} [${w.cycle}] ${w.full_name} (${w.external_id}): ` +
        (err instanceof Error ? err.message : String(err)));
    }
  }

  const remaining = await getPending(FLOOR, CURRENT);
  console.log(`\n=== FEC BACKFILL SUMMARY (floor ${FLOOR}) ===`);
  console.log(`Pairs OK: ${ok}  Failed: ${failed}  Rows on processed pairs: ${totalRows}`);
  console.log(`Pairs still pending: ${remaining.length}`);
  console.log(`Elapsed: ${((Date.now() - startMs) / 60000).toFixed(1)} min`);

  await pool.end();
  process.exit(0);
}

main().catch(err => { console.error('[fec-backfill] Fatal:', err); process.exit(1); });
