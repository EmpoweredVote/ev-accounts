import 'dotenv/config';
import { Pool } from 'pg';
import { readFileSync } from 'fs';
import path from 'path';

/**
 * Applies migration 771 (Utah local chamber linkage + duplicate cleanup) and
 * runs smoke tests. Safe to re-run (the migration is idempotent).
 *
 * Dry-run: pass --dry-run to execute inside a transaction and ROLLBACK, printing
 * the same smoke-test counts WITHOUT persisting any change.
 *   npx tsx scripts/_apply-migration-771.ts --dry-run
 */
const DRY_RUN = process.argv.includes('--dry-run');

const pool = new Pool({ connectionString: process.env['DATABASE_URL'], ssl: { rejectUnauthorized: false } });

const sql = readFileSync(path.join(process.cwd(), 'migrations', '771_fix_utah_local_chamber_linkage.sql'), 'utf8');

const SMOKE = `
  SELECT
    (SELECT count(*) FROM essentials.governments
       WHERE state='ut' AND type='City') AS ut_city_governments,
    (SELECT count(*) FROM essentials.offices o
       JOIN essentials.districts d ON d.id=o.district_id
       JOIN essentials.politicians p ON p.id=o.politician_id
       WHERE d.district_type IN ('LOCAL','LOCAL_EXEC')
         AND o.chamber_id IS NULL AND p.is_active=true) AS remaining_null_chamber_active,
    (SELECT count(*) FROM essentials.chambers ch
       JOIN essentials.governments g ON g.id=ch.government_id
       WHERE g.state='ut' AND g.type='City' AND ch.name ILIKE '%council%') AS ut_city_council_chambers;
`;

try {
  if (DRY_RUN) {
    // Run the migration body (which itself contains BEGIN/COMMIT) inside an
    // outer transaction we force-rollback. We strip the inner COMMIT so the
    // outer ROLLBACK governs, leaving the database untouched.
    const body = sql.replace(/^\s*BEGIN;\s*$/m, '').replace(/^\s*COMMIT;\s*$/m, '');
    await pool.query('BEGIN');
    await pool.query(body);
    const { rows } = await pool.query(SMOKE);
    console.log('[DRY RUN] post-migration counts (rolled back):', rows[0]);
    await pool.query('ROLLBACK');
    console.log('[DRY RUN] rolled back — no changes persisted.');
  } else {
    await pool.query(sql);
    console.log('Migration 771 applied successfully');
    const { rows } = await pool.query(SMOKE);
    console.log('Smoke counts:', rows[0]);
    console.log('Expected: ut_city_governments grew by ~26; remaining_null_chamber_active = 0.');
  }
} catch (err) {
  console.error('Migration 771 failed:', err);
  process.exitCode = 1;
} finally {
  await pool.end();
}
