/**
 * _apply-migration-112.ts — Applies migration 112 (judicial compass schema)
 *
 * Phase 27 — Judicial Compass DB
 * Changes:
 *   1. Adds judicial_role column to inform.compass_topics
 *   2. Expands chk_role_scope_tier CHECK constraint to include 'judicial'
 *
 * Run: cd C:\EV-Accounts && DATABASE_URL=$(grep DATABASE_URL /c/Users/Chris/AppData/Local/Temp/backend.env | cut -d= -f2-) npx tsx backend/scripts/_apply-migration-112.ts
 */
import 'dotenv/config';
import fs from 'fs';
import path from 'path';
import pg from 'pg';

const { Pool } = pg;

async function main(): Promise<void> {
  const databaseUrl = process.env['DATABASE_URL'];
  if (!databaseUrl) {
    console.error('ERROR: DATABASE_URL is not set.');
    process.exit(1);
  }

  console.log('Connecting to DB...');
  const pool = new Pool({ connectionString: databaseUrl });

  try {
    // Pre-check: has this migration already been applied?
    const preCheck = await pool.query(`
      SELECT COUNT(*) FROM information_schema.columns
      WHERE table_schema = 'inform'
        AND table_name = 'compass_topics'
        AND column_name = 'judicial_role'
    `);
    if (parseInt(preCheck.rows[0].count) > 0) {
      console.log('SKIP — migration 112 already applied (judicial_role column exists)');
      process.exit(0);
    }

    console.log('Applying migration 112...');
    const filePath = path.resolve(process.cwd(), 'backend', 'migrations', '112_judicial_compass_schema.sql');
    const sql = fs.readFileSync(filePath, 'utf-8');
    await pool.query(sql);
    console.log('Migration applied. Verifying...');

    // Post-verify 1: judicial_role column exists on inform.compass_topics (nullable)
    const colCheck = await pool.query(`
      SELECT column_name, is_nullable, data_type
      FROM information_schema.columns
      WHERE table_schema = 'inform'
        AND table_name = 'compass_topics'
        AND column_name = 'judicial_role'
    `);
    if (colCheck.rows.length === 1 && colCheck.rows[0].is_nullable === 'YES') {
      console.log(`OK — judicial_role column exists on inform.compass_topics (nullable=${colCheck.rows[0].is_nullable}, type=${colCheck.rows[0].data_type})`);
    } else {
      console.error('FAIL — judicial_role column not found or not nullable');
      process.exit(1);
    }

    // Post-verify 2: chk_role_scope_tier constraint includes 'judicial'
    const constraintCheck = await pool.query(`
      SELECT constraint_name, check_clause
      FROM information_schema.check_constraints
      WHERE constraint_schema = 'inform'
        AND constraint_name = 'chk_role_scope_tier'
    `);
    if (constraintCheck.rows.length === 1 && constraintCheck.rows[0].check_clause.includes('judicial')) {
      console.log(`OK — chk_role_scope_tier includes 'judicial': ${constraintCheck.rows[0].check_clause}`);
    } else {
      console.error('FAIL — chk_role_scope_tier constraint not found or does not include judicial');
      process.exit(1);
    }

    console.log('All checks passed.');
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
