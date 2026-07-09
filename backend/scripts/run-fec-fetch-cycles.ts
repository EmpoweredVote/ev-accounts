/**
 * run-fec-fetch-cycles.ts — populate transparent_motivations.fec_candidate_cycles.
 *
 * For each distinct FEC candidate ID among confirmed sources that is not already
 * cached, fetch the candidate's active two-year cycles from the FEC candidates
 * endpoint and store them. The historical backfill then only ingests cycles a
 * candidate actually filed in — avoiding tens of thousands of empty attempts.
 *
 * One API call per unique candidate (~600). Throttled to respect the 1,000/hr key.
 * Idempotent + resumable: cached IDs are skipped, so re-running only fills gaps.
 *
 * Usage: tsx scripts/run-fec-fetch-cycles.ts
 */

import 'dotenv/config';
import { pool } from '../src/lib/db.js';

const SLEEP_MS = 1500;
const sleep = (ms: number): Promise<void> => new Promise(r => setTimeout(r, ms));

/** Round any year up to its even FEC cycle (odd -> +1). */
const toCycle = (y: number): number => (y % 2 !== 0 ? y + 1 : y);

async function fetchCycles(candidateId: string, apiKey: string): Promise<number[]> {
  const url = `https://api.open.fec.gov/v1/candidates/?api_key=${apiKey}&candidate_id=${encodeURIComponent(candidateId)}&per_page=1`;
  let delay = 1000;
  for (let attempt = 0; attempt <= 3; attempt++) {
    const resp = await fetch(url, { signal: AbortSignal.timeout(30_000) });
    if (resp.status === 429) {
      if (attempt === 3) throw new Error('429 after retries');
      await sleep(delay); delay = Math.min(delay * 2, 60_000); continue;
    }
    if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
    const data = await resp.json() as { results?: Array<{ cycles?: number[]; election_years?: number[] }> };
    const c = data.results?.[0];
    const set = new Set<number>();
    for (const y of c?.cycles ?? []) set.add(toCycle(y));
    for (const y of c?.election_years ?? []) set.add(toCycle(y));
    return [...set].sort((a, b) => b - a);
  }
  return [];
}

async function main() {
  const apiKey = process.env.FEC_API_KEY;
  if (!apiKey) { console.error('ERROR: FEC_API_KEY not set'); process.exit(1); }

  const pending = await pool.query<{ external_id: string }>(`
    SELECT DISTINCT ps.external_id
    FROM transparent_motivations.politician_sources ps
    WHERE ps.source_system LIKE 'fec%' AND ps.research_status='confirmed'
      AND ps.external_id <> ''
      AND NOT EXISTS (
        SELECT 1 FROM transparent_motivations.fec_candidate_cycles cc
        WHERE cc.external_id = ps.external_id
      )
  `);
  const ids = pending.rows.map(r => r.external_id);
  console.log(`[fetch-cycles] uncached candidate IDs: ${ids.length}`);

  let ok = 0, failed = 0;
  for (let i = 0; i < ids.length; i++) {
    const id = ids[i]!;
    if (i > 0) await sleep(SLEEP_MS);
    try {
      const cycles = await fetchCycles(id, apiKey);
      await pool.query(
        `INSERT INTO transparent_motivations.fec_candidate_cycles (external_id, election_years, fetched_at)
         VALUES ($1, $2, now())
         ON CONFLICT (external_id) DO UPDATE SET election_years=EXCLUDED.election_years, fetched_at=now()`,
        [id, cycles]
      );
      ok++;
      if ((i + 1) % 50 === 0 || i === ids.length - 1) {
        console.log(`[fetch-cycles] ${i + 1}/${ids.length} ${id} -> [${cycles.join(',')}]`);
      }
    } catch (err) {
      failed++;
      console.error(`[fetch-cycles] ✗ ${id}: ${err instanceof Error ? err.message : String(err)}`);
    }
  }
  console.log(`\n[fetch-cycles] done. ok=${ok} failed=${failed}`);
  await pool.end();
  process.exit(0);
}

main().catch(err => { console.error('[fetch-cycles] Fatal:', err); process.exit(1); });
