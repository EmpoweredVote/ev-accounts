import { Client } from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

async function main() {
  const client = new Client({ connectionString: process.env['DATABASE_URL'], ssl: { rejectUnauthorized: false } });
  await client.connect();
  try {
    // Verify Corbett, OR coordinate (-122.2, 45.5) returns G4020 but NOT G4110
    const lon = -122.2;
    const lat = 45.5;
    console.log(`Testing coordinate (${lon}, ${lat}) — assumed Corbett OR (unincorporated Multnomah County)`);

    const r = await client.query(
      `SELECT geo_id, name, mtfcc, state
       FROM essentials.geofence_boundaries
       WHERE state = '41'
         AND ST_Covers(geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))
       ORDER BY mtfcc`,
      [lon, lat]
    );

    console.log(`Rows returned: ${r.rows.length}`);
    for (const row of r.rows) {
      console.log(`  mtfcc=${row.mtfcc}  geo_id=${row.geo_id}  name=${row.name}`);
    }

    const hasG4020 = r.rows.some((r: any) => r.mtfcc === 'G4020');
    const hasG4110 = r.rows.some((r: any) => r.mtfcc === 'G4110');

    console.log('\nVerification:');
    console.log(`  G4020 present: ${hasG4020} (must be true)`);
    console.log(`  G4110 absent:  ${!hasG4110} (must be true — no city boundary)`);

    if (hasG4020 && !hasG4110) {
      console.log('\nCoordinate VERIFIED: Corbett (-122.2, 45.5) is unincorporated Multnomah County');
    } else {
      console.log('\nWARNING: Coordinate may need adjustment');
      if (!hasG4020) console.log('  - G4020 missing: coordinate may be outside Multnomah County');
      if (hasG4110) console.log('  - G4110 present: coordinate is inside a city boundary');
    }
  } finally {
    await client.end();
  }
}
main().catch((e: Error) => { console.error('ERROR:', e.message); process.exit(1); });
