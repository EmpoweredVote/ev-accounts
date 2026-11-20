/**
 * CLI: build the candidate set for one state.
 *
 *   npm run banners:candidates --prefix backend -- NE [outDir]
 *
 * Resumable. Re-running picks up only counties left unswept by an earlier run.
 */
import 'dotenv/config';
import path from 'node:path';
import pg from 'pg';
import { buildStateCandidates } from './build-state-candidates.js';

const [, , stateArg, outArg] = process.argv;
if (!stateArg) {
  process.stderr.write('usage: banners:candidates <STATE_USPS> [outDir]\n');
  process.exit(2);
}
const outDir = outArg ?? path.join('data', 'county-banners', stateArg.toUpperCase());

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
try {
  const rows = await buildStateCandidates(stateArg, outDir, {
    query: async (sql, params) => (await pool.query(sql, params as unknown[])).rows,
  });
  const swept = rows.filter((r) => r.swept).length;
  const withCandidates = rows.filter((r) => r.candidates.length > 0).length;
  const rejected = rows.reduce((acc, r) => {
    for (const [k, v] of Object.entries(r.rejected)) acc[k] = (acc[k] ?? 0) + v;
    return acc;
  }, {} as Record<string, number>);
  // Read these numbers. A green exit code is not evidence the run did anything.
  process.stdout.write(`\n${stateArg.toUpperCase()}: ${rows.length} counties, ${swept} swept, ${withCandidates} with at least one candidate\n`);
  process.stdout.write(`rejected: ${JSON.stringify(rejected)}\n`);
  process.stdout.write(`unswept: ${rows.filter((r) => !r.swept).map((r) => r.geoid).join(', ') || 'none'}\n`);
  process.stdout.write(`-> ${outDir}\n`);
} finally {
  await pool.end();
}
