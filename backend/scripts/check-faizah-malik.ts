import 'dotenv/config';
import pg from 'pg';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

// Find Faizah Malik and her compass stances
const pol = await pool.query(`
  SELECT p.id, p.full_name, p.slug, p.is_active, o.title, d.district_type, d.geo_id
  FROM essentials.politicians p
  LEFT JOIN essentials.offices o ON o.id = p.office_id
  LEFT JOIN essentials.districts d ON d.id = o.district_id
  WHERE p.full_name ILIKE '%faizah%' OR p.full_name ILIKE '%malik%'
`);
console.log('Politician rows:', JSON.stringify(pol.rows, null, 2));

if (pol.rows.length > 0) {
  const id = pol.rows[0].id;
  const stances = await pool.query(`
    SELECT cs.id, t.slug AS topic_slug, t.question, cs.value, cs.source_url, cs.notes
    FROM essentials.compass_stances cs
    JOIN essentials.compass_topics t ON t.id = cs.topic_id
    WHERE cs.politician_id = $1
    ORDER BY t.slug
  `, [id]);
  console.log(`\nCompass stances for id=${id}:`, JSON.stringify(stances.rows, null, 2));
}

await pool.end();
