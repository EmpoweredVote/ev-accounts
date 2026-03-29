/**
 * seed-traci-park-committees.ts — seed Traci Park's 3 missing LA Socrata committees
 * and trigger Socrata ingest for each newly-inserted source row.
 *
 * Usage:
 *   cd /c/EV-Accounts/backend && npx tsx scripts/seed-traci-park-committees.ts
 *
 * Requires environment variables:
 *   DATABASE_URL        — PostgreSQL connection string (in .env)
 *   SOCRATA_APP_TOKEN   — Socrata SODA API app token (recommended)
 *
 * What it does:
 *   1. Verifies existing source row (cmt_id 1449034) is present — aborts if not.
 *   2. INSERTs 3 missing committees via ON CONFLICT DO NOTHING.
 *   3. Logs all 4 la_socrata source rows for Traci Park.
 *   4. Triggers Socrata ingest for each new committee via direct function calls.
 *
 * IMPORTANT: All ingest is via direct function calls (not HTTP). Cloudflare blocks
 * POST to accounts.empowered.vote — never use curl/fetch against the deployed API.
 */

import 'dotenv/config';
import { Pool } from 'pg';
import { createSocrataAdapter } from '../src/lib/adapters/socrataAdapter.js';
import { runIngestion } from '../src/lib/adapters/runIngestion.js';
import type { PoliticianSource } from '../src/lib/campaignFinanceService.js';

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

const TRACI_PARK_ID = 'd0977350-df68-4cfe-822e-816ba13f9213';
const EXISTING_CMT_ID = '1449034';

const NEW_COMMITTEES = [
  {
    external_id: '1477137',
    notes: 'Traci Park for City Council 2026 — seeded by 004-multi-committee',
  },
  {
    external_id: '1442937',
    notes: 'Traci Park for Safe Council District 11 2022 — seeded by 004-multi-committee',
  },
  {
    external_id: '1439296',
    notes: 'Traci Park for City Council 2022 — seeded by 004-multi-committee',
  },
];

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

async function main() {
  const startMs = Date.now();
  console.log('[seed-traci-park-committees] Starting...');

  try {
    // Step 1: Verify existing source row (cmt_id 1449034) is untouched
    console.log(`[seed-traci-park-committees] Verifying existing row cmt_id=${EXISTING_CMT_ID}...`);
    const verifyRes = await pool.query<{ id: string; external_id: string; research_status: string }>(
      `SELECT id, external_id, research_status
       FROM transparent_motivations.politician_sources
       WHERE essentials_politician_id = $1
         AND source_system = 'la_socrata'
         AND external_id = $2`,
      [TRACI_PARK_ID, EXISTING_CMT_ID]
    );

    if (verifyRes.rows.length === 0) {
      console.error(
        `[seed-traci-park-committees] ABORT: existing source row for cmt_id=${EXISTING_CMT_ID} not found.` +
          ' Something is wrong — manual investigation required.'
      );
      process.exit(1);
    }

    const existing = verifyRes.rows[0];
    console.log(
      `[seed-traci-park-committees] Existing row confirmed: id=${existing.id}, ` +
        `external_id=${existing.external_id}, research_status=${existing.research_status}`
    );

    // Step 2: INSERT 3 missing committees via ON CONFLICT DO NOTHING
    console.log('[seed-traci-park-committees] Inserting 3 missing committees...');
    const insertedIds: string[] = [];

    for (const cmt of NEW_COMMITTEES) {
      const insertRes = await pool.query<{ id: string }>(
        `INSERT INTO transparent_motivations.politician_sources
           (essentials_politician_id, source_system, external_id, research_status, notes)
         VALUES ($1, 'la_socrata', $2, 'confirmed', $3)
         ON CONFLICT (essentials_politician_id, source_system, external_id) DO NOTHING
         RETURNING id`,
        [TRACI_PARK_ID, cmt.external_id, cmt.notes]
      );

      if (insertRes.rows.length > 0) {
        const newId = insertRes.rows[0].id;
        insertedIds.push(newId);
        console.log(
          `  [INSERT] cmt_id=${cmt.external_id} → source_id=${newId}`
        );
      } else {
        console.log(`  [SKIP] cmt_id=${cmt.external_id} already exists (ON CONFLICT DO NOTHING)`);
      }
    }

    // Step 3: Log all 4 la_socrata source rows to confirm state
    console.log('\n[seed-traci-park-committees] All la_socrata source rows for Traci Park:');
    const allSourcesRes = await pool.query<PoliticianSource>(
      `SELECT id, external_id, research_status, notes, created_at
       FROM transparent_motivations.politician_sources
       WHERE essentials_politician_id = $1
         AND source_system = 'la_socrata'
       ORDER BY external_id`,
      [TRACI_PARK_ID]
    );

    for (const row of allSourcesRes.rows) {
      const notesPreview = row.notes ? row.notes.substring(0, 60) : '';
      console.log(
        `  id=${row.id} | cmt_id=${row.external_id} | status=${row.research_status} | notes="${notesPreview}"`
      );
    }
    console.log(`  Total: ${allSourcesRes.rows.length} source row(s) (expected 4)`);

    // Step 4: Trigger Socrata ingest for each newly-inserted source row
    if (insertedIds.length === 0) {
      console.log('\n[seed-traci-park-committees] No new rows inserted — skipping ingest.');
    } else {
      console.log(`\n[seed-traci-park-committees] Triggering Socrata ingest for ${insertedIds.length} new source(s)...`);

      // Fetch the full source rows for the newly inserted IDs
      const newSourcesRes = await pool.query<PoliticianSource>(
        `SELECT id, essentials_politician_id, source_system, external_id,
                research_status, notes, created_at, updated_at
         FROM transparent_motivations.politician_sources
         WHERE id = ANY($1::uuid[])
         ORDER BY external_id`,
        [insertedIds]
      );

      for (const ps of newSourcesRes.rows) {
        console.log(`\n  [INGEST] cmt_id=${ps.external_id}, source_id=${ps.id}`);
        try {
          const adapter = createSocrataAdapter();
          await runIngestion(adapter, ps, '');
          console.log(`  [INGEST] cmt_id=${ps.external_id} — done`);
        } catch (err) {
          console.error(
            `  [INGEST] cmt_id=${ps.external_id} — error:`,
            err instanceof Error ? err.message : String(err)
          );
          // Non-aborting: continue to next committee
        }
      }
    }

    const durationMs = Date.now() - startMs;
    console.log(`\n[seed-traci-park-committees] Completed in ${(durationMs / 1000).toFixed(1)}s`);
    process.exit(0);
  } finally {
    await pool.end();
  }
}

main().catch(err => {
  console.error('[seed-traci-park-committees] Fatal error:', err);
  process.exit(1);
});
