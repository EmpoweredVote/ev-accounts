import 'dotenv/config';
import { Pool } from 'pg';

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const res = await pool.query(`
  SELECT COUNT(*) as total_contributions,
         SUM(amount)::numeric(12,2) as total_amount,
         MIN(contribution_date) as earliest,
         MAX(contribution_date) as latest,
         COUNT(DISTINCT politician_source_id) as politicians_with_data
  FROM transparent_motivations.contributions
  WHERE data_source = 'la_county_netfile'
`);
console.log('Contributions summary:', res.rows[0]);

const top = await pool.query(`
  SELECT p.full_name, COUNT(c.id) as count, SUM(c.amount)::numeric(12,2) as total
  FROM transparent_motivations.contributions c
  JOIN transparent_motivations.politician_sources ps ON ps.id = c.politician_source_id
  JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
  WHERE c.data_source = 'la_county_netfile'
  GROUP BY p.full_name
  ORDER BY total DESC
  LIMIT 10
`);
console.log('\nTop 10 politicians by total raised:');
top.rows.forEach((r: any) => console.log(`  ${r.full_name}: ${r.count} contributions, $${r.total}`));

await pool.end();
