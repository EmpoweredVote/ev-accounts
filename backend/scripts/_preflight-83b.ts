import { Client } from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

async function main() {
  const client = new Client({ connectionString: process.env['DATABASE_URL'], ssl: { rejectUnauthorized: false } });
  await client.connect();
  try {
    const r = await client.query("SELECT DISTINCT district_type, state FROM essentials.districts WHERE state IN ('or', 'OR') ORDER BY state, district_type");
    console.log('district_type + state combinations for OR:');
    for (const row of r.rows) {
      console.log(`  district_type=${row.district_type}  state=${row.state}`);
    }
  } finally {
    await client.end();
  }
}
main().catch((e: Error) => { console.error('ERROR:', e.message); process.exit(1); });
