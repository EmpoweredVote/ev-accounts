/**
 * _verify-migration-069.ts — Verify migration 069 applied correctly.
 * Run: npx tsx scripts/_verify-migration-069.ts
 */
import 'dotenv/config';
import pg from 'pg';

const { Client } = pg;

async function main(): Promise<void> {
  const url = process.env['DATABASE_URL'];
  if (!url) { console.error('DATABASE_URL not set'); process.exit(1); }
  const client = new Client({ connectionString: url });
  await client.connect();

  // Verify column
  const colResult = await client.query(`
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns
    WHERE table_schema = 'transparent_motivations'
      AND table_name = 'contributions'
      AND column_name = 'donor_name_normalized'
  `);
  console.log('Column check:', colResult.rows);

  // Verify indexes
  const idxResult = await client.query(`
    SELECT indexname, indexdef
    FROM pg_indexes
    WHERE schemaname = 'transparent_motivations'
      AND tablename = 'contributions'
      AND indexname LIKE '%donor_name%'
  `);
  console.log('Index check:');
  for (const row of idxResult.rows) {
    console.log(' -', row.indexname, ':', row.indexdef);
  }

  await client.end();
}

main();
