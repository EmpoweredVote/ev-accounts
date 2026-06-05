import { Client } from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

async function main() {
  const client = new Client({ connectionString: process.env.DATABASE_URL });
  await client.connect();

  // Q1: Applied migrations
  const migs = await client.query("SELECT version FROM supabase_migrations.schema_migrations ORDER BY version::integer DESC LIMIT 30");
  console.log('=== APPLIED MIGRATIONS (last 30) ===');
  migs.rows.forEach((r: any) => console.log(r.version));
  console.log('');

  // Check specific migrations 171 and 182
  const m171 = await client.query("SELECT version FROM supabase_migrations.schema_migrations WHERE version='171'");
  const m182 = await client.query("SELECT version FROM supabase_migrations.schema_migrations WHERE version='182'");
  console.log('Migration 171 applied:', m171.rows.length > 0 ? 'YES' : 'NO');
  console.log('Migration 182 applied:', m182.rows.length > 0 ? 'YES' : 'NO');
  console.log('');

  // Q2: CA Governor race rows
  const govRaces = await client.query("SELECT id, title, race_type, primary_party, election_id FROM essentials.races WHERE title ILIKE '%governor%' ORDER BY title");
  console.log('=== CA GOVERNOR RACE ROWS ===');
  govRaces.rows.forEach((r: any) => console.log(JSON.stringify(r)));
  console.log('');

  // Q3: Governor race candidates
  const govCands = await client.query(`SELECT rc.id, COALESCE(p.full_name, 'NULL politician') as full_name, p.external_id, rc.race_id, rc.party 
    FROM essentials.race_candidates rc 
    LEFT JOIN essentials.politicians p ON p.id = rc.politician_id 
    WHERE rc.race_id IN (SELECT id FROM essentials.races WHERE title ILIKE '%governor%')
    ORDER BY rc.party, COALESCE(p.full_name, '')`);
  console.log('=== GOVERNOR RACE CANDIDATES ===');
  govCands.rows.forEach((r: any) => console.log(JSON.stringify(r)));
  console.log('');

  // Q4: CA Governor politicians (-6003xxx range)
  const govPols = await client.query("SELECT id, full_name, external_id, party FROM essentials.politicians WHERE external_id BETWEEN -6003999 AND -6003000 ORDER BY external_id");
  console.log('=== CA GOVERNOR POLITICIANS (-6003xxx) ===');
  govPols.rows.forEach((r: any) => console.log(JSON.stringify(r)));
  console.log('');

  // Q5: LAUSD in governments table
  const lausd = await client.query("SELECT id, name, geo_id, state FROM essentials.governments WHERE name ILIKE '%lausd%' OR name ILIKE '%unified school%'");
  console.log('=== LAUSD GOVERNMENT ROW ===');
  lausd.rows.forEach((r: any) => console.log(JSON.stringify(r)));
  console.log('');

  // Q6: LAUSD in chambers
  const lausdChambers = await client.query("SELECT id, name, slug FROM essentials.chambers WHERE name ILIKE '%lausd%' OR name ILIKE '%board of education%'");
  console.log('=== LAUSD CHAMBERS ===');
  lausdChambers.rows.forEach((r: any) => console.log(JSON.stringify(r)));
  console.log('');

  // Q7: LA government row
  const laGov = await client.query("SELECT id, name, geo_id, state FROM essentials.governments WHERE geo_id = '0644000' OR name ILIKE '%los angeles%'");
  console.log('=== LA GOVERNMENT ROWS ===');
  laGov.rows.forEach((r: any) => console.log(JSON.stringify(r)));
  console.log('');

  // Q8: LA chambers
  const laChambers = await client.query(`SELECT c.id, c.name, c.slug, g.name as gov_name 
    FROM essentials.chambers c 
    JOIN essentials.governments g ON g.id = c.government_id 
    WHERE g.geo_id = '0644000' OR g.name ILIKE '%los angeles%'
    ORDER BY c.name`);
  console.log('=== LA CHAMBERS ===');
  laChambers.rows.forEach((r: any) => console.log(JSON.stringify(r)));
  console.log('');

  // Q9: lavote.gov election ID - check discovery_jurisdictions
  const lavote = await client.query(`SELECT id, name, election_authority_url, election_id_external, state, cron_active 
    FROM essentials.discovery_jurisdictions 
    WHERE state = 'CA' OR name ILIKE '%angeles%' OR election_authority_url ILIKE '%lavote%'`);
  console.log('=== LA DISCOVERY JURISDICTIONS ===');
  lavote.rows.forEach((r: any) => console.log(JSON.stringify(r)));
  console.log('');

  // Q10: CA elections/races for Governor
  const caElections = await client.query(`SELECT e.id, e.name, e.election_date, e.state, e.jurisdiction_id 
    FROM essentials.elections e 
    WHERE e.state = 'CA' OR e.name ILIKE '%california%' OR e.name ILIKE '%governor%'
    ORDER BY e.election_date`);
  console.log('=== CA ELECTIONS ===');
  caElections.rows.forEach((r: any) => console.log(JSON.stringify(r)));
  console.log('');

  // Q11: All CA races to understand current structure
  const caRaces = await client.query(`SELECT r.id, r.title, r.race_type, r.primary_party, r.election_id, e.name as election_name
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    WHERE e.state = 'CA' OR r.title ILIKE '%governor%'
    ORDER BY r.title`);
  console.log('=== CA RACES ===');
  caRaces.rows.forEach((r: any) => console.log(JSON.stringify(r)));
  console.log('');

  // Q12: LAUSD politicians (-6004xxx)  
  const lausdPols = await client.query("SELECT id, full_name, external_id FROM essentials.politicians WHERE external_id BETWEEN -6004999 AND -6004000 ORDER BY external_id");
  console.log('=== LAUSD POLITICIANS (-6004xxx) ===');
  lausdPols.rows.forEach((r: any) => console.log(JSON.stringify(r)));
  console.log('');

  await client.end();
}

main().catch(console.error);
