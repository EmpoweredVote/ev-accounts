/**
 * backfill-chamber-engagement-level.ts
 *
 * Identifies administrative and retention-judge chambers by name pattern
 * and updates policy_engagement_level accordingly.
 *
 * Default mode: dry-run. Prints what would change.
 * With --apply: actually performs the updates inside a transaction.
 *
 * Run:
 *   cd ev-accounts/backend
 *   set -a && source .env && set +a
 *   npx tsx scripts/backfill-chamber-engagement-level.ts           # dry run
 *   npx tsx scripts/backfill-chamber-engagement-level.ts --apply   # commit changes
 */

import 'dotenv/config';
import pg from 'pg';

const { Pool } = pg;

// Chambers whose names match these patterns become engagement level 'none'
// (administrative offices — no policy positions, no compass).
const NONE_PATTERNS = [
  'Recorder',
  'Surveyor',
  'Auditor',
  'Coroner',
  'Assessor',
  'Circuit Court Clerk',
  'City Clerk',
  'Treasurer',
] as const;

// Chambers whose names match these patterns become engagement level 'record_only'
// (retention judges — voters decide on track record, not positions).
//
// NOTE: In Indiana, circuit court judges are CONTESTED in their first election
// and RETAINED in subsequent elections. For v1 we leave circuit court judges at
// 'full' and only mark appellate/supreme court as 'record_only'. The spec's
// open question #4 flags this as needing Indiana-specific verification.
const RECORD_ONLY_PATTERNS = [
  'Court of Appeals',   // "X Court of Appeals" naming
  'Appeals Court',      // "Indiana Appeals Court Judge - District N" naming
  'Supreme Court',
  'Appellate',
] as const;

async function main() {
  const apply = process.argv.includes('--apply');
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });

  // Safe project ID confirmation (no password echo)
  const url = process.env.DATABASE_URL || '';
  const match = url.match(/postgres\.([a-z0-9]+):/);
  const projectId = match ? match[1] : 'UNKNOWN';
  console.log('Targeting project:', projectId);

  try {
    // Fetch all chambers with their current engagement level
    const { rows: chambers } = await pool.query(
      `SELECT id, name, policy_engagement_level FROM essentials.chambers ORDER BY name`
    );

    const toNone: { id: string; name: string }[] = [];
    const toRecordOnly: { id: string; name: string }[] = [];

    for (const ch of chambers) {
      const matchesNone = NONE_PATTERNS.some((p) => ch.name.includes(p));
      const matchesRecord = RECORD_ONLY_PATTERNS.some((p) => ch.name.includes(p));

      // record_only takes priority if a chamber somehow matches both
      if (matchesRecord && ch.policy_engagement_level !== 'record_only') {
        toRecordOnly.push({ id: ch.id, name: ch.name });
      } else if (matchesNone && !matchesRecord && ch.policy_engagement_level !== 'none') {
        toNone.push({ id: ch.id, name: ch.name });
      }
    }

    console.log(`\n=== DRY RUN SUMMARY${apply ? ' (will apply)' : ''} ===\n`);
    console.log(`Total chambers: ${chambers.length}`);
    console.log(`Will set to 'none': ${toNone.length}`);
    for (const c of toNone) console.log(`  - ${c.name}`);
    console.log(`\nWill set to 'record_only': ${toRecordOnly.length}`);
    for (const c of toRecordOnly) console.log(`  - ${c.name}`);

    if (!apply) {
      console.log(`\nDry run complete. Re-run with --apply to commit changes.`);
      return;
    }

    // Actual updates inside a transaction
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      for (const c of toNone) {
        await client.query(
          `UPDATE essentials.chambers SET policy_engagement_level = 'none' WHERE id = $1`,
          [c.id]
        );
      }
      for (const c of toRecordOnly) {
        await client.query(
          `UPDATE essentials.chambers SET policy_engagement_level = 'record_only' WHERE id = $1`,
          [c.id]
        );
      }

      await client.query('COMMIT');
      console.log(`\nApplied: ${toNone.length} → none, ${toRecordOnly.length} → record_only.`);
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }

    // Post-verify
    const { rows: summary } = await pool.query(
      `SELECT policy_engagement_level, COUNT(*) AS n
       FROM essentials.chambers
       GROUP BY policy_engagement_level
       ORDER BY policy_engagement_level`
    );
    console.log('\nFinal counts by engagement level:');
    for (const r of summary) console.log(`  ${r.policy_engagement_level}: ${r.n}`);
  } finally {
    await pool.end();
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
