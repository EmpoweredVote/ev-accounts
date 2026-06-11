/**
 * Ingest ~49 missing US state outlines + 1 US/nation outline into
 * essentials.geofence_boundaries (mtfcc='G4000'), so Read & Rank statewide and
 * federal-statewide races resolve a real boundary.
 *
 * - geo_id = 2-digit state FIPS (matches the existing California row, geo_id '06');
 *   the nation row uses geo_id = 'US'.
 * - Idempotent: ON CONFLICT (geo_id, mtfcc) DO NOTHING. Re-running is safe and
 *   never mutates existing rows (California is simply skipped).
 * - PROD GUARD: aborts unless DATABASE_URL targets the prod ref kxsdzaojfaibhuzmclfq.
 * - Source: Census 2010 cartographic boundary states, 20m (FIPS in props.STATE).
 *
 * Run:  npx tsx scripts/ingest-state-nation-outlines.ts /tmp/us_states_20m.json
 */
import { config as loadEnv } from 'dotenv';
import { Pool } from 'pg';
import { readFileSync } from 'node:fs';

// Load DATABASE_URL from the main checkout's backend/.env (worktree has no .env).
loadEnv({ path: '/Users/chrisandrews/Documents/GitHub/ev-accounts/backend/.env' });

const PROD_REF = 'kxsdzaojfaibhuzmclfq';
const DATABASE_URL = process.env['DATABASE_URL'];
if (!DATABASE_URL) { console.error('No DATABASE_URL found.'); process.exit(1); }
if (!DATABASE_URL.includes(PROD_REF)) {
  console.error(`ABORT: DATABASE_URL is not the prod project (${PROD_REF}). Refusing to write.`);
  process.exit(1);
}

// 50 states + DC. Territories (PR 72, etc.) intentionally excluded.
const FIPS_TO_USPS: Record<string, string> = {
  '01': 'AL', '02': 'AK', '04': 'AZ', '05': 'AR', '06': 'CA', '08': 'CO', '09': 'CT',
  '10': 'DE', '11': 'DC', '12': 'FL', '13': 'GA', '15': 'HI', '16': 'ID', '17': 'IL',
  '18': 'IN', '19': 'IA', '20': 'KS', '21': 'KY', '22': 'LA', '23': 'ME', '24': 'MD',
  '25': 'MA', '26': 'MI', '27': 'MN', '28': 'MS', '29': 'MO', '30': 'MT', '31': 'NE',
  '32': 'NV', '33': 'NH', '34': 'NJ', '35': 'NM', '36': 'NY', '37': 'NC', '38': 'ND',
  '39': 'OH', '40': 'OK', '41': 'OR', '42': 'PA', '44': 'RI', '45': 'SC', '46': 'SD',
  '47': 'TN', '48': 'TX', '49': 'UT', '50': 'VT', '51': 'VA', '53': 'WA', '54': 'WV',
  '55': 'WI', '56': 'WY',
};

interface Feature { properties: { STATE: string; NAME: string }; geometry: unknown }

const file = process.argv[2] ?? '/tmp/us_states_20m.json';
const fc = JSON.parse(readFileSync(file, 'utf8')) as { features: Feature[] };

const pool = new Pool({ connectionString: DATABASE_URL, ssl: { rejectUnauthorized: false } });

async function main(): Promise<void> {
  const before = await pool.query(`SELECT count(*)::int AS n FROM essentials.geofence_boundaries WHERE mtfcc='G4000'`);
  const ca = await pool.query(`SELECT geo_id, name FROM essentials.geofence_boundaries WHERE mtfcc='G4000' AND geo_id='06'`);
  if (ca.rows.length === 0 || ca.rows[0].name !== 'California') {
    console.error('ABORT: expected the California G4000 row (geo_id 06) on prod. Wrong DB?');
    process.exit(1);
  }
  console.log(`Pre-flight OK. Existing G4000 rows: ${before.rows[0].n} (CA present).`);

  let inserted = 0, skipped = 0;
  for (const f of fc.features) {
    const fips = f.properties.STATE;
    const usps = FIPS_TO_USPS[fips];
    if (!usps) { skipped++; continue; } // territory / non-state
    const res = await pool.query(
      `INSERT INTO essentials.geofence_boundaries (geo_id, mtfcc, name, state, geometry, source)
       VALUES ($1, 'G4000', $2, $3, ST_Multi(ST_SetSRID(ST_GeomFromGeoJSON($4), 4326)), 'census_cb_2010_20m')
       ON CONFLICT (geo_id, mtfcc) DO NOTHING`,
      [fips, f.properties.NAME, usps, JSON.stringify(f.geometry)],
    );
    if (res.rowCount && res.rowCount > 0) inserted++; else skipped++;
  }
  console.log(`States: inserted ${inserted}, skipped ${skipped} (existing or non-state).`);

  // US/nation outline = union of the state polygons. Idempotent.
  const us = await pool.query(
    `INSERT INTO essentials.geofence_boundaries (geo_id, mtfcc, name, state, geometry, source)
     SELECT 'US', 'G4000', 'United States', NULL,
            ST_Multi(ST_Union(geometry)), 'derived_union_states'
     FROM essentials.geofence_boundaries
     WHERE mtfcc='G4000' AND geo_id ~ '^[0-9]{2}$'
     ON CONFLICT (geo_id, mtfcc) DO NOTHING`,
  );
  console.log(`Nation (US) row: ${us.rowCount && us.rowCount > 0 ? 'inserted' : 'already present'}.`);

  const after = await pool.query(`SELECT count(*)::int AS n FROM essentials.geofence_boundaries WHERE mtfcc='G4000'`);
  console.log(`Done. G4000 rows now: ${after.rows[0].n} (expected ~52: 50 states + DC + US).`);
  await pool.end();
}

main().catch((e) => { console.error('Ingest failed:', e); process.exit(1); });
