import 'dotenv/config';
import { pool } from '../src/lib/db.js';

async function main() {
  // Get all sources for Adam Schiff
  const schiff = await pool.query(`
    SELECT
      p.id AS politician_id,
      p.full_name,
      ps.id AS source_id,
      ps.source_system,
      ps.research_status,
      ps.external_id,
      ps.notes
    FROM transparent_motivations.politician_sources ps
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
    WHERE p.full_name ILIKE '%schiff%'
    ORDER BY ps.research_status
  `);

  console.log('Adam Schiff sources:');
  for (const r of schiff.rows) {
    console.log(`  source_id: ${r.source_id}`);
    console.log(`  politician_id: ${r.politician_id}`);
    console.log(`  source_system: ${r.source_system}`);
    console.log(`  research_status: ${r.research_status}`);
    console.log(`  external_id: ${r.external_id}`);
    console.log(`  notes: ${r.notes}`);
    console.log('');
  }

  // Also get Jim Banks sources
  const banks = await pool.query(`
    SELECT
      p.id AS politician_id,
      p.full_name,
      ps.id AS source_id,
      ps.source_system,
      ps.research_status,
      ps.external_id,
      ps.notes
    FROM transparent_motivations.politician_sources ps
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
    WHERE p.full_name ILIKE '%banks%'
    ORDER BY ps.research_status
  `);

  console.log('\nJim Banks sources:');
  for (const r of banks.rows) {
    console.log(`  source_id: ${r.source_id}`);
    console.log(`  source_system: ${r.source_system}`);
    console.log(`  research_status: ${r.research_status}`);
    console.log(`  external_id: ${r.external_id}`);
    console.log(`  notes: ${r.notes}`);
    console.log('');
  }

  process.exit(0);
}

main().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
