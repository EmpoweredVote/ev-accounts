/**
 * ingest-la-june2026-candidates.ts — Ingest Socrata contribution data for
 * the 19 LA June 2026 candidates whose politician_sources were seeded on 2026-05-06.
 *
 * Sources seeded directly via SQL before this script:
 *   Adam Miller (1488039), Aida Ashouri (1482178), Andrej Selivra (1486173),
 *   Ankur Patel (1487198), Asaad Alnajjar (1479527), Bryant Acosta (1485314),
 *   John Logsdon (1490340), John McKinney (1487830), Nithya Raman (1487932),
 *   Rae Chen Huang (1484729), Raquel Zamora (1485501), Spencer Pratt (1485940),
 *   Tish Hyman (1485984)
 *   — plus Karen Bass (1471359), Nithya Raman (1425985), Rocio Rivas (1478485)
 *     already had confirmed sources from prior phases.
 *
 * IMPORTANT: Never trigger via HTTP POST — Cloudflare blocks POST to
 * accounts.empowered.vote. Must use runAdapterForAll direct function call.
 *
 * Usage:
 *   npx tsx scripts/ingest-la-june2026-candidates.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';
import { runAdapterForAll } from '../src/lib/campaignFinanceScheduler.js';

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

const JUNE_2026_CANDIDATES = [
  'Karen Ruth Bass',
  'Nithya Raman',
  'Rae Chen Huang',
  'Bryant Acosta',
  'Spencer Pratt',
  'Adam Miller',
  'Aida Ashouri',
  'John Logsdon',
  'Rocio Rivas',
  'Asaad Alnajjar',
  'Andrej Selivra',
  'Tish Hyman',
  'Andrew K. Kim',
  'Nelson Cheng',
  'John McKinney',
  'Juanita Lopez',
  'Raquel Zamora',
  'Ankur Patel',
  'Suzy Kim',
];

async function verifySources(): Promise<void> {
  const res = await pool.query<{
    full_name: string;
    count: string;
    cmt_ids: string;
  }>(
    `SELECT
       p.full_name,
       COUNT(ps.id)::text AS count,
       string_agg(ps.external_id, ', ' ORDER BY ps.external_id) AS cmt_ids
     FROM essentials.politicians p
     LEFT JOIN transparent_motivations.politician_sources ps
       ON ps.essentials_politician_id = p.id
       AND ps.source_system = 'la_socrata'
       AND ps.research_status = 'confirmed'
     WHERE p.full_name = ANY($1::text[])
     GROUP BY p.full_name
     ORDER BY p.full_name`,
    [JUNE_2026_CANDIDATES]
  );

  console.log('\n=== LA June 2026 Candidate Sources ===');
  let withSource = 0;
  let withoutSource = 0;
  for (const row of res.rows) {
    const n = parseInt(row.count);
    const status = n > 0 ? `✓ cmt_ids: ${row.cmt_ids}` : '✗ NO CONFIRMED SOURCE';
    console.log(`  ${row.full_name.padEnd(22)} ${status}`);
    if (n > 0) withSource++; else withoutSource++;
  }
  console.log(`\n  With confirmed source: ${withSource}`);
  console.log(`  Without source:        ${withoutSource} (no Socrata data available)`);
  console.log('');
}

async function main(): Promise<void> {
  const startMs = Date.now();
  console.log('[ingest-la-june2026-candidates] Starting...');

  await verifySources();

  console.log('[ingest-la-june2026-candidates] Triggering runAdapterForAll("la_socrata")...');
  console.log('(This ingests ALL confirmed la_socrata sources — new candidates + refresh existing)\n');

  await runAdapterForAll('la_socrata');

  const durationMs = Date.now() - startMs;
  console.log(`\n[ingest-la-june2026-candidates] Complete in ${(durationMs / 1000).toFixed(1)}s`);
}

main()
  .then(async () => {
    await pool.end();
    process.exit(0);
  })
  .catch(async err => {
    console.error('[ingest-la-june2026-candidates] Fatal error:', err);
    await pool.end();
    process.exit(1);
  });
