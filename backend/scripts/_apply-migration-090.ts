/**
 * _apply-migration-090.ts — Applies migration 090 (Tier 3-4 TX cities)
 * Run: cd C:\EV-Accounts && npx tsx backend/scripts/_apply-migration-090.ts
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
    const preCheck = await pool.query(
      `SELECT COUNT(*) FROM essentials.governments WHERE geo_id = '4803300'`
    );
    if (parseInt(preCheck.rows[0].count) > 0) {
      console.log('SKIP — migration 090 already applied (Anna row exists)');
      process.exit(0);
    }

    console.log('Applying migration 090...');
    const filePath = path.resolve(process.cwd(), 'backend', 'migrations', '090_tx_tier34_cities.sql');
    const sql = fs.readFileSync(filePath, 'utf-8');
    await pool.query(sql);
    console.log('Migration applied. Verifying...');

    // Post-verify: count the 15 cities
    const postCheck = await pool.query(`
      SELECT COUNT(DISTINCT g.id) AS city_count
      FROM essentials.governments g
      WHERE g.geo_id IN (
        '4803300','4847496','4863432','4845012','4841800',
        '4825224','4875960','4825488',
        '4855152','4864220','4850760','4877740',
        '4844308','4838068','4808872'
      )
    `);
    const count = parseInt(postCheck.rows[0].city_count);
    if (count === 15) {
      console.log(`OK — ${count} Tier 3-4 city rows confirmed.`);
    } else {
      console.error(`FAIL — expected 15 cities, got ${count}`);
      process.exit(1);
    }

    // Princeton check
    const princeton = await pool.query(`
      SELECT c.official_count, COUNT(o.id) AS office_count
      FROM essentials.governments g
      JOIN essentials.chambers c ON c.government_id = g.id
      JOIN essentials.offices o ON o.chamber_id = c.id
      WHERE g.geo_id = '4863432'
      GROUP BY c.official_count
    `);
    const pr = princeton.rows[0];
    console.log(`Princeton: official_count=${pr.official_count}, office_count=${pr.office_count}`);
    if (parseInt(pr.official_count) === 8 && parseInt(pr.office_count) === 8) {
      console.log('Princeton 8-seat check PASSED');
    } else {
      console.error('Princeton 8-seat check FAILED');
      process.exit(1);
    }

    // Copeville check
    const copeville = await pool.query(`
      SELECT COUNT(*) FROM essentials.governments WHERE geo_id = '4816600'
    `);
    if (parseInt(copeville.rows[0].count) === 0) {
      console.log('Copeville absence check PASSED');
    } else {
      console.error('Copeville should not be present!');
      process.exit(1);
    }

    // Nonpartisan check
    const partisan = await pool.query(`
      SELECT COUNT(*) FROM essentials.offices o
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
      WHERE g.geo_id IN (
        '4803300','4847496','4863432','4845012','4841800',
        '4825224','4875960','4825488',
        '4855152','4864220','4850760','4877740',
        '4844308','4838068','4808872'
      ) AND o.partisan_type IS NOT NULL
    `);
    if (parseInt(partisan.rows[0].count) === 0) {
      console.log('Nonpartisan (NULL) check PASSED');
    } else {
      console.error(`partisan_type IS NOT NULL for ${partisan.rows[0].count} rows — FAIL`);
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
