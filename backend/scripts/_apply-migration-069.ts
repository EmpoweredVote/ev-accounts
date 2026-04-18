/**
 * _apply-migration-069.ts — One-time script to apply migration 069.
 *
 * Run from C:\EV-Accounts\backend:
 *   npx tsx scripts/_apply-migration-069.ts
 *
 * Connects via DIRECT Supabase URL (port 5432) because CREATE INDEX CONCURRENTLY
 * cannot run through the pooler or inside a transaction block.
 */
import 'dotenv/config';
import pg from 'pg';

const { Client } = pg;

async function main(): Promise<void> {
  const poolerUrl = process.env['DATABASE_URL'];
  if (!poolerUrl) {
    console.error('ERROR: DATABASE_URL not set');
    process.exit(1);
  }

  // Extract password from pooler URL:
  // postgresql://postgres.kxsdzaojfaibhuzmclfq:PWD@aws-0-us-west-1.pooler.supabase.com:5432/postgres
  // Use the session-mode pooler (port 5432) — CONCURRENTLY works in session mode
  // because each connection is dedicated (unlike transaction mode on port 6543).
  console.log('[069] Connecting via session-mode pooler (port 5432)...');

  const client = new Client({ connectionString: poolerUrl });
  await client.connect();
  console.log('[069] Connected.');

  try {
    // Statement 1: Add column
    console.log('[069] Adding donor_name_normalized column...');
    await client.query(
      `ALTER TABLE transparent_motivations.contributions
         ADD COLUMN IF NOT EXISTS donor_name_normalized text`
    );
    console.log('[069] Column added.');

    // Statement 2: B-tree index (CONCURRENTLY — cannot be in a transaction)
    console.log('[069] Creating B-tree index CONCURRENTLY...');
    await client.query(
      `CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_contributions_donor_name_btree
         ON transparent_motivations.contributions (donor_name_normalized)`
    );
    console.log('[069] B-tree index created.');

    // Statement 3: GIN trigram index (CONCURRENTLY)
    console.log('[069] Creating GIN trigram index CONCURRENTLY...');
    await client.query(
      `CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_contributions_donor_name_trgm
         ON transparent_motivations.contributions
         USING GIN (donor_name_normalized extensions.gin_trgm_ops)`
    );
    console.log('[069] GIN trigram index created.');

    console.log('[069] Migration 069 complete.');
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error('[069] ERROR:', msg);
    process.exit(1);
  } finally {
    await client.end();
  }
}

main();
