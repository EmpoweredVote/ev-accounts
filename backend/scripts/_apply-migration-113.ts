/**
 * _apply-migration-113.ts — Applies migration 113 (Judicial Compass Topics)
 * Run: cd C:\EV-Accounts && DATABASE_URL=$(grep DATABASE_URL /c/Users/Chris/AppData/Local/Temp/backend.env | cut -d= -f2-) npx tsx backend/scripts/_apply-migration-113.ts
 */
import 'dotenv/config';
import fs from 'fs';
import path from 'path';
import pg from 'pg';

const { Pool } = pg;

const JUDICIAL_TOPIC_KEYS = [
  'judicial-criminal-justice',
  'judicial-access-to-justice',
  'judicial-government-deference',
  'judicial-transparency',
  'judicial-interpretation',
  'judicial-bail-pretrial',
  'judicial-prosecution-priorities',
  'judicial-police-accountability',
];

async function main(): Promise<void> {
  const databaseUrl = process.env['DATABASE_URL'];
  if (!databaseUrl) {
    console.error('ERROR: DATABASE_URL is not set.');
    process.exit(1);
  }

  console.log('Connecting to DB...');
  const pool = new Pool({ connectionString: databaseUrl });

  try {
    // Pre-check: how many judicial topics already exist?
    const preCheck = await pool.query(
      `SELECT COUNT(*) FROM inform.compass_topics
       WHERE topic_key = ANY($1::text[]) AND is_live = true`,
      [JUDICIAL_TOPIC_KEYS]
    );
    const existingCount = parseInt(preCheck.rows[0].count);

    if (existingCount >= 8) {
      console.log(`SKIP — migration 113 already applied (${existingCount} judicial topics exist)`);

      // Still run post-verify to confirm DB integrity
      console.log('Running post-verify on existing data...');
    } else {
      console.log(`Found ${existingCount} of 8 judicial topics. Applying migration 113...`);
      const filePath = path.resolve(process.cwd(), 'backend', 'migrations', '113_judicial_compass_topics.sql');
      const sql = fs.readFileSync(filePath, 'utf-8');
      await pool.query(sql);
      console.log('Migration applied. Verifying...');
    }

    // Post-verify 1: confirm 8 topics with correct keys
    const topicsCheck = await pool.query(
      `SELECT topic_key FROM inform.compass_topics
       WHERE topic_key = ANY($1::text[]) AND is_live = true
       ORDER BY topic_key`,
      [JUDICIAL_TOPIC_KEYS]
    );
    const foundKeys = topicsCheck.rows.map((r: { topic_key: string }) => r.topic_key);
    if (foundKeys.length === 8) {
      console.log(`OK — 8 judicial topics confirmed.`);
      console.log(`  Keys: ${foundKeys.join(', ')}`);
    } else {
      console.error(`FAIL — expected 8 topics, got ${foundKeys.length}`);
      console.error(`  Found: ${foundKeys.join(', ')}`);
      process.exit(1);
    }

    // Post-verify 2: confirm 40 stances total across all 8 topics
    const stancesCheck = await pool.query(
      `SELECT COUNT(*) FROM inform.compass_stances s
       JOIN inform.compass_topics t ON t.id = s.topic_id
       WHERE t.topic_key = ANY($1::text[]) AND t.is_live = true`,
      [JUDICIAL_TOPIC_KEYS]
    );
    const stanceCount = parseInt(stancesCheck.rows[0].count);
    if (stanceCount === 40) {
      console.log(`OK — ${stanceCount} stances confirmed across 8 judicial topics.`);
    } else {
      console.error(`FAIL — expected 40 stances, got ${stanceCount}`);
      process.exit(1);
    }

    // Post-verify 3: confirm 8 role rows ALL with role_scope='judicial'
    const rolesCheck = await pool.query(
      `SELECT COUNT(*) FROM inform.compass_topic_roles r
       JOIN inform.compass_topics t ON t.id = r.topic_id
       WHERE t.topic_key = ANY($1::text[]) AND t.is_live = true`,
      [JUDICIAL_TOPIC_KEYS]
    );
    const roleCount = parseInt(rolesCheck.rows[0].count);
    if (roleCount === 8) {
      console.log(`OK — ${roleCount} role rows confirmed.`);
    } else {
      console.error(`FAIL — expected 8 role rows, got ${roleCount}`);
      process.exit(1);
    }

    // Post-verify 4: confirm all role rows have role_scope='judicial'
    const judicialRolesCheck = await pool.query(
      `SELECT COUNT(*) FROM inform.compass_topic_roles r
       JOIN inform.compass_topics t ON t.id = r.topic_id
       WHERE t.topic_key = ANY($1::text[]) AND t.is_live = true
         AND r.role_scope = 'judicial'`,
      [JUDICIAL_TOPIC_KEYS]
    );
    const judicialRoleCount = parseInt(judicialRolesCheck.rows[0].count);
    if (judicialRoleCount === 8) {
      console.log(`OK — all ${judicialRoleCount} role rows have role_scope='judicial'.`);
    } else {
      console.error(`FAIL — expected 8 judicial role rows, got ${judicialRoleCount}`);
      process.exit(1);
    }

    // Post-verify 5: confirm 0 non-judicial role rows for these topics
    const isolationCheck = await pool.query(
      `SELECT COUNT(*) FROM inform.compass_topic_roles r
       JOIN inform.compass_topics t ON t.id = r.topic_id
       WHERE t.topic_key = ANY($1::text[]) AND t.is_live = true
         AND r.role_scope IN ('federal', 'state', 'local')`,
      [JUDICIAL_TOPIC_KEYS]
    );
    const nonJudicialCount = parseInt(isolationCheck.rows[0].count);
    if (nonJudicialCount === 0) {
      console.log(`OK — isolation confirmed: 0 non-judicial role rows for judicial topics.`);
    } else {
      console.error(`FAIL — found ${nonJudicialCount} non-judicial role rows for judicial topics`);
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
