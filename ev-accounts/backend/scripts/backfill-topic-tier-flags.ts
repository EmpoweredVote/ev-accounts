/**
 * backfill-topic-tier-flags.ts
 *
 * Populates inform.compass_topic_roles with one row per (topic, tier) pair,
 * based on the audit in docs/planning/topic-tier-audit.md.
 *
 * Idempotent via the (topic_id, role_scope) unique constraint added in
 * migration 059. Safe to re-run.
 *
 * Run:
 *   cd ev-accounts/backend
 *   set -a && source .env && set +a
 *   npx tsx scripts/backfill-topic-tier-flags.ts
 */

import 'dotenv/config';
import pg from 'pg';

const { Pool } = pg;

type Tier = 'federal' | 'state' | 'local';

// Derived from docs/planning/topic-tier-audit.md (approved 2026-04-11, revised).
// Each topic_key maps to the list of tiers at which it has actual jurisdiction.
// Tier flags do NOT gate compass rendering — they drive the compass builder
// badge, the essentials coverage callout, and research prioritization only.
const TIER_FLAGS: Record<string, Tier[]> = {
  'healthcare':        ['federal', 'state', 'local'],
  'abortion':          ['federal', 'state'],
  'tariffs':           ['federal'],
  'taxes':             ['federal', 'state', 'local'],
  'same-sex-marriage': ['federal', 'state'],
  'religious-freedom': ['federal', 'state', 'local'],
  'trans-athletes':    ['federal', 'state', 'local'],
  'ukraine-support':   ['federal'],
  'medicare/aid':      ['federal', 'state'],
  'fossil-fuels':      ['federal', 'state', 'local'],
  'voting-rights':     ['federal', 'state', 'local'],
  'deportation':       ['federal', 'state', 'local'],
  'social-security':   ['federal'],
  'ai-regulation':     ['federal', 'state'],
  'climate-change':    ['federal', 'state', 'local'],
  'civil-rights':      ['federal', 'state', 'local'],
  'housing':           ['federal', 'state', 'local'],
  'campaign-finance':  ['federal', 'state', 'local'],
  'immigration':       ['federal', 'state', 'local'],
  'misinformation':    ['federal', 'state'],
  'redistricting':     ['federal', 'state'],
  'school-vouchers':   ['federal', 'state'],
  'data-centers':      ['federal', 'state', 'local'],
  'homelessness':      ['federal', 'state', 'local'],
  'childcare':         ['federal', 'state', 'local'],
  'jail-capacity':     ['state', 'local'],
};

async function main() {
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });

  // Safe project ID confirmation (no password echo)
  const url = process.env.DATABASE_URL || '';
  const match = url.match(/postgres\.([a-z0-9]+):/);
  const projectId = match ? match[1] : 'UNKNOWN';
  console.log('Targeting project:', projectId);

  try {
    // Resolve topic_key → topic_id
    const { rows: topics } = await pool.query(
      `SELECT id, topic_key FROM inform.compass_topics WHERE is_live = true`
    );
    const topicKeyToId = new Map<string, string>(
      topics.map((t) => [t.topic_key, t.id])
    );

    const missingInDb: string[] = [];
    const missingInAudit: string[] = [];

    for (const key of Object.keys(TIER_FLAGS)) {
      if (!topicKeyToId.has(key)) missingInDb.push(key);
    }
    for (const t of topics) {
      if (!(t.topic_key in TIER_FLAGS)) missingInAudit.push(t.topic_key);
    }

    if (missingInDb.length > 0) {
      console.error('ERROR: Audit has topic_keys not present in DB:', missingInDb);
      process.exit(1);
    }
    if (missingInAudit.length > 0) {
      console.error('ERROR: DB has topic_keys not present in audit:', missingInAudit);
      console.error('Update docs/planning/topic-tier-audit.md and the TIER_FLAGS map in this script.');
      process.exit(1);
    }

    // Insert one row per (topic, tier) pair
    let inserted = 0;
    let skipped = 0;
    for (const [key, tiers] of Object.entries(TIER_FLAGS)) {
      const topicId = topicKeyToId.get(key)!;
      for (const tier of tiers) {
        const result = await pool.query(
          `INSERT INTO inform.compass_topic_roles (topic_id, role_scope)
           VALUES ($1, $2)
           ON CONFLICT (topic_id, role_scope) DO NOTHING`,
          [topicId, tier]
        );
        if (result.rowCount === 1) inserted++;
        else skipped++;
      }
    }

    console.log(`Inserted ${inserted} new rows, skipped ${skipped} existing rows.`);
    console.log(`Total topics: ${topics.length}, total (topic, tier) pairs: ${inserted + skipped}`);

    // Summary
    const { rows: summary } = await pool.query(
      `SELECT role_scope, COUNT(*) AS n
       FROM inform.compass_topic_roles
       GROUP BY role_scope
       ORDER BY role_scope`
    );
    console.log('Per-tier totals after backfill:');
    for (const r of summary) {
      console.log(`  ${r.role_scope}: ${r.n} topics`);
    }
  } finally {
    await pool.end();
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
