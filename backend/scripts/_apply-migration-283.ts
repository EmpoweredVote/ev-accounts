import 'dotenv/config';
import { Pool } from 'pg';
import { readFileSync } from 'fs';
import path from 'path';

const pool = new Pool({ connectionString: process.env['DATABASE_URL'], ssl: { rejectUnauthorized: false } });

const sql = readFileSync(
  path.join(process.cwd(), '..', 'supabase', 'migrations', '20260607000001_283_phase104_city_official_remediation.sql'),
  'utf8'
);

try {
  await pool.query(sql);
  console.log('Migration 283 applied successfully');

  // Smoke check V1: v2.5 city-official cohort unsourced stances (STAX-03 target: 0)
  const r1 = await pool.query(`
    SELECT COUNT(*) AS city_unsourced_count
    FROM inform.politician_answers pa
    LEFT JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
    JOIN essentials.politicians p ON p.id = pa.politician_id
    WHERE p.external_id BETWEEN -689999 AND -630000
      AND (p.external_id < -669999 OR p.external_id > -660000)
      AND p.is_active = true
      AND (
        pc.politician_id IS NULL
        OR pc.sources IS NULL
        OR array_length(pc.sources, 1) IS NULL
        OR NOT EXISTS (
          SELECT 1 FROM unnest(pc.sources) AS s(url)
          WHERE url IS NOT NULL AND trim(url) <> ''
        )
      )
  `);
  const v1 = parseInt(r1.rows[0].city_unsourced_count, 10);
  console.log(`V1 city-cohort unsourced count: ${v1} (target: 0)`);
  if (v1 !== 0) {
    console.log('WARNING: STAX-03 V1 not satisfied — unsourced stances remain in city cohort');
  }

  // Smoke check V2: v2.5 city-official cohort weak-source stances (STAX-03 target: 0)
  const r2 = await pool.query(`
    SELECT COUNT(*) AS city_weak_count
    FROM inform.politician_answers pa
    JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
    JOIN essentials.politicians p ON p.id = pa.politician_id
    WHERE p.external_id BETWEEN -689999 AND -630000
      AND (p.external_id < -669999 OR p.external_id > -660000)
      AND p.is_active = true
      AND pc.sources IS NOT NULL
      AND array_length(pc.sources, 1) IS NOT NULL
      AND EXISTS (
        SELECT 1 FROM unnest(pc.sources) s(u)
        WHERE u IS NOT NULL AND trim(u) != ''
      )
      AND NOT EXISTS (
        SELECT 1 FROM unnest(pc.sources) AS s(url)
        WHERE url IS NOT NULL AND trim(url) <> ''
          AND url !~ '^https?://[^/]+/?$'
      )
  `);
  const v2 = parseInt(r2.rows[0].city_weak_count, 10);
  console.log(`V2 city-cohort weak-source count: ${v2} (target: 0)`);
  if (v2 !== 0) {
    console.log('WARNING: STAX-03 V2 not satisfied — weak-source-only stances remain in city cohort');
  }

  if (v1 === 0 && v2 === 0) {
    console.log('STAX-03 SATISFIED: V1=0, V2=0');
  }

} catch (e: any) {
  console.error('Error applying migration 283:', e.message);
  process.exit(1);
} finally {
  await pool.end();
}
