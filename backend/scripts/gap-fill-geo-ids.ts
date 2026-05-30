#!/usr/bin/env -S npx tsx
/**
 * gap-fill-geo-ids.ts
 *
 * Phase 133 / POL-01 — populate `essentials.districts.geo_id` for UT layers.
 * TS port of the CA-era `gap_fill_geo_ids.py` (per Phase 133 D-05).
 *
 * Idempotent: every UPDATE statement guards with `AND geo_id IS NULL` so a
 * second run is a no-op (Pitfall 7 — TIGER-set geo_ids never overwritten).
 *
 * Layers covered (these are the layers TIGER's loader does NOT populate):
 *   - LOCAL / LOCAL_EXEC OCD-ID copy (city councils, mayors, county-internal seats)
 *   - STATE_BOARD OCD-ID copy (sboe:{N})
 *   - SLC mayor LOCAL_EXEC analogue (D-09 Claude's Discretion):
 *       ocd-division/country:us/state:ut/place:salt_lake_city
 *   - COUNTY OCD-ID copy (covers any rows the TIGER loader missed)
 *
 * Note: cd119/sldu/sldl/unsd/place/county already have geo_id populated by
 * Phase 131's TIGER loader (it joins TIGER GEOID directly). This script only
 * fills the layers TIGER doesn't cover.
 *
 * Usage:
 *   cd ev-accounts/backend
 *   set -a && source .env && set +a
 *   npx tsx scripts/gap-fill-geo-ids.ts --dry-run   # report rowcounts only
 *   npx tsx scripts/gap-fill-geo-ids.ts             # apply updates
 *
 * Re-running with no new rows is safe: every rule logs `updated 0 rows`.
 */
import 'dotenv/config';
import pg from 'pg';

const { Pool } = pg;

const DRY_RUN = process.argv.includes('--dry-run');

interface Rule {
  layer: string;
  update_sql: string; // executed when !DRY_RUN
  count_sql: string; // executed when DRY_RUN — same WHERE, returns rowcount estimate
}

const RULES: Rule[] = [
  {
    layer: 'UT LOCAL/LOCAL_EXEC OCD-ID copy',
    update_sql: `
      UPDATE essentials.districts SET geo_id = ocd_id
       WHERE state = 'UT' AND geo_id IS NULL
         AND district_type IN ('LOCAL', 'LOCAL_EXEC')
         AND ocd_id LIKE 'ocd-division/country:us/state:ut/%';
    `,
    count_sql: `
      SELECT COUNT(*)::text AS c FROM essentials.districts
       WHERE state = 'UT' AND geo_id IS NULL
         AND district_type IN ('LOCAL', 'LOCAL_EXEC')
         AND ocd_id LIKE 'ocd-division/country:us/state:ut/%';
    `,
  },
  {
    layer: 'UT STATE_BOARD OCD-ID copy',
    update_sql: `
      UPDATE essentials.districts SET geo_id = ocd_id
       WHERE state = 'UT' AND geo_id IS NULL
         AND district_type = 'STATE_BOARD';
    `,
    count_sql: `
      SELECT COUNT(*)::text AS c FROM essentials.districts
       WHERE state = 'UT' AND geo_id IS NULL
         AND district_type = 'STATE_BOARD';
    `,
  },
  {
    layer: 'UT SLC mayor LOCAL_EXEC analogue (Claude Discretion / D-09)',
    update_sql: `
      UPDATE essentials.districts
         SET geo_id = 'ocd-division/country:us/state:ut/place:salt_lake_city'
       WHERE state = 'UT' AND geo_id IS NULL
         AND district_type = 'LOCAL_EXEC'
         AND ocd_id LIKE '%place:salt_lake_city%';
    `,
    count_sql: `
      SELECT COUNT(*)::text AS c FROM essentials.districts
       WHERE state = 'UT' AND geo_id IS NULL
         AND district_type = 'LOCAL_EXEC'
         AND ocd_id LIKE '%place:salt_lake_city%';
    `,
  },
  {
    layer: 'UT COUNTY OCD-ID copy (catch any rows missed by TIGER loader)',
    update_sql: `
      UPDATE essentials.districts SET geo_id = ocd_id
       WHERE state = 'UT' AND geo_id IS NULL
         AND district_type = 'COUNTY'
         AND ocd_id LIKE 'ocd-division/country:us/state:ut/county:%';
    `,
    count_sql: `
      SELECT COUNT(*)::text AS c FROM essentials.districts
       WHERE state = 'UT' AND geo_id IS NULL
         AND district_type = 'COUNTY'
         AND ocd_id LIKE 'ocd-division/country:us/state:ut/county:%';
    `,
  },
];

async function main(): Promise<void> {
  if (!process.env.DATABASE_URL) {
    console.error('[gap-fill-geo-ids] FATAL: DATABASE_URL not set');
    process.exit(1);
  }
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
  });
  try {
    for (const r of RULES) {
      if (DRY_RUN) {
        const { rows } = await pool.query<{ c: string }>(r.count_sql);
        console.log(`[dry] ${r.layer}: would update ${rows[0].c} rows`);
      } else {
        const res = await pool.query(r.update_sql);
        console.log(`[run] ${r.layer}: updated ${res.rowCount ?? 0} rows`);
      }
    }
  } finally {
    await pool.end();
  }
}

main().catch((e) => {
  console.error('[gap-fill-geo-ids] FATAL', e);
  process.exit(1);
});
