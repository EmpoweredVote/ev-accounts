/**
 * applyMigrations.ts — Applies migrations 026–029 to a Postgres database.
 *
 * IMPORTANT: DATABASE_URL must be the DIRECT connection string, NOT the pooler URL.
 *   Direct:  postgresql://postgres.<ref>:<pwd>@db.<ref>.supabase.co:5432/postgres
 *   Pooler:  postgresql://postgres.<ref>:<pwd>@aws-0-<region>.pooler.supabase.com:6543/postgres
 *
 * Multi-statement migrations fail on the pooler (port 6543). Always use port 5432
 * with the db.<ref>.supabase.co host.
 *
 * Usage (from repo root):
 *   DATABASE_URL="postgresql://..." npx tsx backend/scripts/applyMigrations.ts
 */

import 'dotenv/config';
import fs from 'fs';
import path from 'path';
import pg from 'pg';

const { Pool } = pg;

// ---------------------------------------------------------------------------
// Migration definitions — applied in strict order
// ---------------------------------------------------------------------------

interface Migration {
  file: string;
  label: string;
}

const MIGRATIONS: Migration[] = [
  { file: '026_inform_schema_repair_and_candidates.sql', label: '026' },
  { file: '027_rpc_reset_compass_answers.sql',           label: '027' },
  { file: '028_rpc_import_compass_calibrations.sql',     label: '028' },
  { file: '029_compass_admin_rpcs.sql',                  label: '029' },
];

// ---------------------------------------------------------------------------
// Verification queries
// Pre-verify: should return 0 rows when migration has NOT been applied.
// Post-verify: should return 1+ rows when migration HAS been applied.
// ---------------------------------------------------------------------------

const PRE_VERIFY_QUERIES: Record<string, string> = {
  '026': `SELECT column_name FROM information_schema.columns WHERE table_schema='inform' AND table_name='politicians' AND column_name='is_candidate'`,
  '027': `SELECT proname FROM pg_proc WHERE proname='reset_compass_answers'`,
  '028': `SELECT proname FROM pg_proc WHERE proname='import_compass_calibrations'`,
  '029': `SELECT proname FROM pg_proc WHERE proname='admin_create_topic_with_stances'`,
};

const POST_VERIFY_QUERIES: Record<string, string> = {
  '026': `SELECT column_name FROM information_schema.columns WHERE table_schema='inform' AND table_name='politicians' AND column_name='is_candidate'`,
  '027': `SELECT proname FROM pg_proc WHERE proname='reset_compass_answers'`,
  '028': `SELECT proname FROM pg_proc WHERE proname='import_compass_calibrations'`,
  '029': `SELECT proname FROM pg_proc WHERE proname='admin_create_topic_with_stances'`,
};

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  const databaseUrl = process.env['DATABASE_URL'];
  if (!databaseUrl) {
    console.error(
      'ERROR: DATABASE_URL is not set.\n' +
      'Set it to the DIRECT connection string (port 5432, db.<ref>.supabase.co).\n' +
      'Example:\n' +
      '  DATABASE_URL="postgresql://postgres.<ref>:<pwd>@db.<ref>.supabase.co:5432/postgres" \\\n' +
      '    npx tsx backend/scripts/applyMigrations.ts'
    );
    process.exit(1);
  }

  const pool = new Pool({ connectionString: databaseUrl });

  try {
    for (const migration of MIGRATIONS) {
      const { file, label } = migration;

      // --- Pre-verify: check if already applied ---
      const preQuery = PRE_VERIFY_QUERIES[label];
      const preResult = await pool.query(preQuery);

      if (preResult.rowCount !== null && preResult.rowCount > 0) {
        console.log(`[${label}] SKIP — already applied`);
        continue;
      }

      // --- Apply ---
      console.log(`[${label}] Applying...`);

      const filePath = path.resolve(process.cwd(), 'backend', 'migrations', file);
      const sql = fs.readFileSync(filePath, 'utf-8');

      await pool.query(sql);

      // --- Post-verify: confirm migration succeeded ---
      const postQuery = POST_VERIFY_QUERIES[label];
      const postResult = await pool.query(postQuery);

      if (!postResult.rowCount || postResult.rowCount < 1) {
        console.error(`[${label}] FAIL — post-verification failed`);
        process.exit(1);
      }

      console.log(`[${label}] OK`);
    }

    console.log('All migrations applied successfully.');
    process.exit(0);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error('ERROR:', message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

main();
