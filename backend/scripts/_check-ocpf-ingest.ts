import 'dotenv/config';
import pg from 'pg';
const pool = new pg.Pool({ connectionString: process.env['DATABASE_URL'] });

// politician_sources uses essentials_politician_id
// contributions uses contribution_date, not date
// politician_sources.politician_id vs essentials_politician_id

const counts = await pool.query(`
  SELECT COUNT(*) as total, MIN(contribution_date) as earliest, MAX(contribution_date) as latest
  FROM transparent_motivations.contributions
  WHERE data_source = 'ocpf'
`);
console.log('OCPF contributions:', JSON.stringify(counts.rows[0]));

const perPol = await pool.query(`
  SELECT p.full_name, COUNT(c.id) as contributions, SUM(c.amount) as total_raised
  FROM transparent_motivations.contributions c
  JOIN transparent_motivations.politician_sources ps ON ps.id = c.politician_source_id
  JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
  WHERE c.data_source = 'ocpf'
  GROUP BY p.full_name
  ORDER BY contributions DESC
`);
console.log('\nPer politician:');
if (perPol.rows.length === 0) console.log('  (none — no contributions ingested yet)');
perPol.rows.forEach((r: Record<string, unknown>) =>
  console.log(`  ${r['full_name']}: ${r['contributions']} contributions, $${Number(r['total_raised']).toLocaleString()}`)
);

// ingestion_runs — check column name
const runCols = await pool.query(`
  SELECT column_name FROM information_schema.columns
  WHERE table_schema = 'transparent_motivations' AND table_name = 'ingestion_runs'
  ORDER BY ordinal_position
`);
console.log('\ningestion_runs columns:', runCols.rows.map((r: Record<string, unknown>) => r['column_name']).join(', '));

const runs = await pool.query(`
  SELECT ir.status, ir.records_fetched, ir.records_inserted, ir.error_message,
         ps.external_id, p.full_name
  FROM transparent_motivations.ingestion_runs ir
  JOIN transparent_motivations.politician_sources ps ON ps.id = ir.politician_source_id
  JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
  WHERE ps.source_system = 'ocpf'
  ORDER BY ir.started_at DESC
  LIMIT 30
`);
console.log('\nOCPF ingestion runs:');
if (runs.rows.length === 0) console.log('  (none)');
runs.rows.forEach((r: Record<string, unknown>) =>
  console.log(`  [${r['status']}] ${r['full_name']} cpfId=${r['external_id']} fetched=${r['records_fetched']} inserted=${r['records_inserted']} err=${r['error_message'] ?? '-'}`)
);

await pool.end();
