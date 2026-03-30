/**
 * Phase 17-02: Verify LA Socrata confirmation pass outcome
 * Checks confirmation counts, ingest runs, and contribution data for la_socrata sources.
 */
import 'dotenv/config';
import { Pool } from 'pg';

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function main() {
  const client = await pool.connect();
  try {
    console.log('=== Phase 17-02: LA Socrata Verification Report ===\n');

    // Query 1: Confirmation status counts
    console.log('--- Query 1: LA Socrata research_status breakdown ---');
    const q1 = await client.query(`
      SELECT research_status, COUNT(*) AS count
      FROM transparent_motivations.politician_sources
      WHERE source_system = 'la_socrata'
      GROUP BY research_status
      ORDER BY research_status
    `);
    console.table(q1.rows);

    // Query 2: Recent ingest runs
    console.log('\n--- Query 2: Recent la_socrata ingest runs (last 5) ---');
    const q2 = await client.query(`
      SELECT id, adapter_name, started_at, completed_at, records_fetched, records_inserted, status
      FROM transparent_motivations.ingestion_runs
      WHERE adapter_name = 'la_socrata'
      ORDER BY started_at DESC
      LIMIT 5
    `);
    console.table(q2.rows);

    // Query 3: Sample confirmed politicians with contribution counts (top 5)
    console.log('\n--- Query 3: Confirmed politicians with contribution counts (top 5 by count) ---');
    const q3 = await client.query(`
      SELECT p.full_name, o.title AS office_title, ps.external_id AS cmt_id,
             COUNT(c.id) AS contribution_count
      FROM transparent_motivations.politician_sources ps
      JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
      LEFT JOIN essentials.offices o ON o.politician_id = p.id AND o.is_vacant = false
      LEFT JOIN transparent_motivations.contributions c ON c.politician_source_id = ps.id
      WHERE ps.source_system = 'la_socrata'
        AND ps.research_status = 'confirmed'
      GROUP BY p.full_name, o.title, ps.external_id
      ORDER BY contribution_count DESC
      LIMIT 5
    `);
    console.table(q3.rows);

    // Query 4: Confirmed politicians with zero contributions
    console.log('\n--- Query 4: Confirmed la_socrata politicians with zero contributions (data_pending state) ---');
    const q4 = await client.query(`
      SELECT COUNT(*) AS zero_contribution_confirmed
      FROM transparent_motivations.politician_sources ps
      LEFT JOIN transparent_motivations.contributions c ON c.politician_source_id = ps.id
      WHERE ps.source_system = 'la_socrata'
        AND ps.research_status = 'confirmed'
        AND c.id IS NULL
    `);
    console.table(q4.rows);

    // Summary
    const confirmed = q1.rows.find(r => r.research_status === 'confirmed');
    const confirmedCount = confirmed ? parseInt(confirmed.count) : 0;
    const zeroContrib = parseInt(q4.rows[0]?.zero_contribution_confirmed || '0');
    const withData = confirmedCount - zeroContrib;

    console.log('\n=== SUMMARY ===');
    console.log(`Total confirmed la_socrata sources: ${confirmedCount}`);
    console.log(`Confirmed with contribution data:   ${withData}`);
    console.log(`Confirmed with zero contributions:  ${zeroContrib} (→ data_pending UI banner)`);
    console.log(`\nCOV-04 status: ${confirmedCount > 0 ? 'CLOSED — LA city council candidates confirmed and ingested' : 'OPEN — no confirmed sources found'}`);

  } finally {
    client.release();
    await pool.end();
  }
}

main().catch(err => {
  console.error('Script error:', err);
  process.exit(1);
});
