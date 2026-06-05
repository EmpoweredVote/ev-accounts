import 'dotenv/config';
import { Pool } from 'pg';

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

async function run() {
  // Coverage query
  const coverage = await pool.query(`
    SELECT ch.name AS chamber,
           COUNT(p.id) AS politicians_in_db,
           COUNT(pi.id) AS with_headshot,
           COUNT(p.id) - COUNT(pi.id) AS missing_headshot
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.id = p.office_id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
    LEFT JOIN essentials.politician_images pi ON pi.politician_id = p.id
    WHERE g.name='City of Fremont' AND g.state='CA'
      AND p.external_id BETWEEN -670015 AND -670001
      AND p.is_active = true AND p.is_vacant = false
    GROUP BY ch.name
    ORDER BY ch.name
  `);
  
  console.log('=== Coverage Table ===');
  coverage.rows.forEach(r => console.log(JSON.stringify(r)));
  
  // photo_origin_url count
  const urlCount = await pool.query(`
    SELECT COUNT(*) as count FROM essentials.politicians
    WHERE external_id BETWEEN -670015 AND -670001
      AND photo_origin_url IS NOT NULL
  `);
  console.log('\nphoto_origin_url set:', urlCount.rows[0].count);
  
  // Per-politician detail
  const detail = await pool.query(`
    SELECT p.external_id, p.full_name, p.photo_origin_url, pi.url, pi.photo_license
    FROM essentials.politicians p
    LEFT JOIN essentials.politician_images pi ON pi.politician_id = p.id
    WHERE p.external_id BETWEEN -670015 AND -670001
    ORDER BY p.external_id
  `);
  
  console.log('\n=== Per-Politician Detail ===');
  detail.rows.forEach(r => console.log(
    `${r.external_id} | ${r.full_name.padEnd(20)} | license=${r.photo_license} | url_set=${!!r.url} | origin_set=${!!r.photo_origin_url}`
  ));
  
  // Migration file check
  const fs = await import('fs');
  const migFile = 'C:/EV-Accounts/backend/migrations/212_fremont_headshots.sql';
  const exists = fs.existsSync(migFile);
  console.log('\n=== Migration File ===');
  console.log('Exists:', exists);
  if (exists) {
    const content = fs.readFileSync(migFile, 'utf8');
    const insertCount = (content.match(/INSERT INTO essentials\.politician_images/g) || []).length;
    const hasAuditHeader = content.includes('AUDIT ONLY');
    const hasNotInLedger = content.includes('NOT applied via the Supabase migrations ledger');
    console.log('INSERT count:', insertCount);
    console.log('Has AUDIT ONLY header:', hasAuditHeader);
    console.log('Has "NOT applied via ledger":', hasNotInLedger);
  }
  
  await pool.end();
}
run().catch(console.error);
