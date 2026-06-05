import 'dotenv/config';
import { Pool } from 'pg';
import AdmZip from 'adm-zip';
import iconv from 'iconv-lite';
import { parse } from 'csv-parse/sync';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

async function run() {
  // Check if Marissa Roy is in essentials.politicians
  const res = await pool.query(`
    SELECT p.id, p.full_name, o.title
    FROM essentials.politicians p
    LEFT JOIN essentials.offices o ON o.politician_id = p.id
    WHERE p.full_name ILIKE '%marissa%roy%'
       OR p.full_name ILIKE '%roy%marissa%'
  `);
  console.log('Marissa Roy in DB:', res.rows);

  // Check existing politician_sources for Marissa Roy
  if (res.rows.length > 0) {
    const pid = res.rows[0].id;
    const srRes = await pool.query(`
      SELECT * FROM transparent_motivations.politician_sources
      WHERE essentials_politician_id = $1
    `, [pid]);
    console.log('politician_sources for Marissa Roy:', srRes.rows);
  }

  // Look at Cal-Access ZIP for Roy filers
  const zip = new AdmZip('C:/Users/Chris/AppData/Local/Temp/dbwebexport.zip');
  const entry = zip.getEntry('CalAccess/DATA/FILERNAME_CD.TSV');
  const rawBytes = entry!.getData();
  const utf8 = iconv.decode(rawBytes, 'win1252');
  const rows = parse(utf8, { delimiter: '\t', columns: true, relax_column_count: true, quote: false, skip_empty_lines: true, trim: true }) as any[];

  // Find ROY-related LOS ANGELES filers
  const royRows = rows.filter((r: any) => {
    const city = (r.CITY ?? '').toUpperCase();
    const naml = (r.NAML ?? '').toUpperCase();
    return city === 'LOS ANGELES' && naml.includes('ROY') && naml.includes('ATTORNEY');
  });
  console.log('\nRoy + Attorney LOS ANGELES FILERNAME rows:', royRows.slice(0, 5).map((r: any) => ({
    FILER_ID: r.FILER_ID,
    NAML: r.NAML,
    NAMF: r.NAMF,
  })));

  await pool.end();
}

run().catch(console.error);
