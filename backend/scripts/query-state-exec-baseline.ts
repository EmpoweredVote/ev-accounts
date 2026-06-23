/**
 * query-state-exec-baseline.ts
 * Phase 141 research: get exact prod baseline for STATE_EXEC records.
 * Run: node --import tsx scripts/query-state-exec-baseline.ts
 * from C:/EV-Accounts/backend with env loaded.
 */
import 'dotenv/config';
import { Pool } from 'pg';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

async function main() {
  const client = await pool.connect();
  try {
    // Q1: STATE_EXEC district counts per state
    console.log('\n=== Q1: STATE_EXEC district counts per state ===');
    const q1 = await client.query(`
      SELECT state, COUNT(*) as district_count
      FROM essentials.districts
      WHERE district_type = 'STATE_EXEC'
      GROUP BY state
      ORDER BY state
    `);
    console.log(JSON.stringify(q1.rows, null, 2));

    // Q2: All STATE_EXEC records with details
    console.log('\n=== Q2: All STATE_EXEC records (politician, title, role_canonical, stances) ===');
    const q2 = await client.query(`
      SELECT
        d.state,
        d.label,
        d.geo_id,
        p.full_name,
        p.external_id,
        p.is_appointed,
        o.is_appointed_position,
        o.role_canonical,
        o.title,
        COUNT(pa.id) as stance_count
      FROM essentials.districts d
      JOIN essentials.offices o ON o.district_id = d.id
      JOIN essentials.politicians p ON p.id = o.politician_id
      LEFT JOIN inform.politician_answers pa ON pa.politician_id = p.id
      WHERE d.district_type = 'STATE_EXEC'
      GROUP BY d.state, d.label, d.geo_id, p.full_name, p.external_id, p.is_appointed,
               o.is_appointed_position, o.role_canonical, o.title
      ORDER BY d.state, d.label
    `);
    console.log(JSON.stringify(q2.rows, null, 2));

    // Q3: negative external_ids (all, for collision check)
    console.log('\n=== Q3: All negative external_ids ===');
    const q3 = await client.query(`
      SELECT external_id
      FROM essentials.politicians
      WHERE external_id < 0
      ORDER BY external_id
    `);
    console.log('Total negative IDs:', q3.rows.length);
    const ids = q3.rows.map(r => parseInt(r.external_id));
    console.log('Min (most negative):', Math.min(...ids));
    console.log('Max (least negative):', Math.max(...ids));
    console.log('All negative IDs:', JSON.stringify(ids));

    // Q4: UT-specific (check for NULL external_ids)
    console.log('\n=== Q4: UT STATE_EXEC politicians (check NULL external_ids) ===');
    const q4 = await client.query(`
      SELECT p.full_name, p.external_id, d.label, o.title, o.role_canonical
      FROM essentials.politicians p
      JOIN essentials.offices o ON o.politician_id = p.id
      JOIN essentials.districts d ON d.id = o.district_id
      WHERE d.district_type = 'STATE_EXEC' AND d.state = 'UT'
      ORDER BY d.label
    `);
    console.log(JSON.stringify(q4.rows, null, 2));

    // Q5: government rows for states
    console.log('\n=== Q5: State government rows (State of X) ===');
    const q5 = await client.query(`
      SELECT name, state, id
      FROM essentials.governments
      WHERE name LIKE 'State of %' OR name LIKE 'Commonwealth of %'
      ORDER BY state
    `);
    console.log('Count:', q5.rows.length);
    console.log(JSON.stringify(q5.rows.map(r => ({ name: r.name, state: r.state })), null, 2));

    // Q6: existing STATE_EXEC for the 9 states - look for Big 5 gaps
    console.log('\n=== Q6: Big-5 role gap analysis per seeded state ===');
    const q6 = await client.query(`
      SELECT
        d.state,
        d.label,
        o.role_canonical,
        o.is_appointed_position,
        p.full_name,
        p.is_appointed
      FROM essentials.districts d
      JOIN essentials.offices o ON o.district_id = d.id
      JOIN essentials.politicians p ON p.id = o.politician_id
      WHERE d.district_type = 'STATE_EXEC'
        AND d.state IN ('CA','IN','MA','MD','ME','OR','TX','UT','VA')
      ORDER BY d.state, d.label
    `);
    console.log(JSON.stringify(q6.rows, null, 2));

    // Q7: check for any fips*100000+seq collision range
    console.log('\n=== Q7: Collision check for -(fips*100000+seq) range ===');
    const q7 = await client.query(`
      SELECT external_id
      FROM essentials.politicians
      WHERE external_id < -56000
      ORDER BY external_id
    `);
    console.log('IDs below -56000 (state exec candidate range):', q7.rows.length);
    console.log(JSON.stringify(q7.rows.map(r => r.external_id), null, 2));

    // Q8: IN specific - what STATE_EXEC records exist
    console.log('\n=== Q8: IN STATE_EXEC full detail ===');
    const q8 = await client.query(`
      SELECT d.label, o.title, o.role_canonical, p.full_name, p.external_id, p.is_appointed
      FROM essentials.districts d
      JOIN essentials.offices o ON o.district_id = d.id
      JOIN essentials.politicians p ON p.id = o.politician_id
      WHERE d.district_type = 'STATE_EXEC' AND d.state = 'IN'
      ORDER BY d.label
    `);
    console.log(JSON.stringify(q8.rows, null, 2));

  } finally {
    client.release();
    await pool.end();
  }
}

main().catch(e => { console.error(e); process.exit(1); });
