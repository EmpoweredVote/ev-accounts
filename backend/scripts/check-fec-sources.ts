import 'dotenv/config';
import { pool } from '../src/lib/db.js';

async function main() {
  // Check all fec sources
  const sources = await pool.query(`
    SELECT
      p.full_name,
      p.bioguide_id,
      c.name AS chamber,
      o.representing_state,
      ps.source_system,
      ps.research_status,
      ps.external_id,
      ps.notes
    FROM transparent_motivations.politician_sources ps
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    WHERE ps.source_system LIKE 'fec%'
      AND p.is_active = true
      AND p.is_vacant = false
      AND (c.name LIKE 'U.S. House%' OR c.name LIKE 'U.S. Senate%')
    ORDER BY ps.research_status, o.representing_state, p.full_name
  `);

  const confirmed = sources.rows.filter(r => r.research_status === 'confirmed');
  const needsResearch = sources.rows.filter(r => r.research_status === 'needs_research');
  const notApplicable = sources.rows.filter(r => r.research_status === 'not_applicable');

  console.log(`\n=== FEC SOURCE STATUS ===`);
  console.log(`Total: ${sources.rows.length}`);
  console.log(`Confirmed: ${confirmed.length}`);
  console.log(`Needs research: ${needsResearch.length}`);
  console.log(`Not applicable: ${notApplicable.length}`);

  if (confirmed.length > 0) {
    console.log(`\n--- CONFIRMED ---`);
    for (const r of confirmed) {
      console.log(`  ${r.representing_state} | ${r.chamber.replace('U.S. ', '')} | ${r.full_name} → ${r.external_id}`);
    }
  }

  if (needsResearch.length > 0) {
    console.log(`\n--- NEEDS RESEARCH ---`);
    for (const r of needsResearch) {
      const notes = r.notes ? r.notes.substring(0, 200) : '(no notes)';
      console.log(`  ${r.representing_state} | ${r.chamber.replace('U.S. ', '')} | ${r.full_name} | ext_id: ${r.external_id || 'none'} | notes: ${notes}`);
    }
  }

  // Also check total federal politicians
  const total = await pool.query(`
    SELECT COUNT(DISTINCT p.id) as cnt
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    WHERE p.is_active = true
      AND p.is_vacant = false
      AND (c.name LIKE 'U.S. House%' OR c.name LIKE 'U.S. Senate%')
  `);
  console.log(`\nTotal active federal politicians in DB: ${total.rows[0].cnt}`);

  process.exit(0);
}

main().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
