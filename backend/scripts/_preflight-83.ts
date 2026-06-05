import { Client } from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

async function main() {
  const client = new Client({ connectionString: process.env['DATABASE_URL'], ssl: { rejectUnauthorized: false } });
  await client.connect();
  try {
    const r1 = await client.query("SELECT COUNT(*) as cnt FROM essentials.politicians WHERE external_id IN (-410001, -410010, -410011, -410012, -410013)");
    console.log('1. External_id range (must be 0):', r1.rows[0].cnt);

    const r2 = await client.query("SELECT geo_id, name, mtfcc, state FROM essentials.geofence_boundaries WHERE geo_id = '41051' AND mtfcc = 'G4020'");
    console.log('2. G4020 geofence rows (must be 1):', r2.rows.length);
    if (r2.rows[0]) console.log('   Row:', JSON.stringify(r2.rows[0]));

    const r3 = await client.query("SELECT COUNT(*) as cnt FROM essentials.governments WHERE name = 'Multnomah County, Oregon, US'");
    console.log('3. Multnomah County gov row (must be 0):', r3.rows[0].cnt);

    const r4 = await client.query("SELECT DISTINCT state FROM essentials.districts WHERE state LIKE '%or%' OR state LIKE '%OR%' LIMIT 10");
    console.log('4. districts.state or/OR values:', r4.rows.map((r: { state: string }) => r.state).join(', '));

    console.log('\nPre-flight DONE');
  } finally {
    await client.end();
  }
}
main().catch((e: Error) => { console.error('ERROR:', e.message); process.exit(1); });
