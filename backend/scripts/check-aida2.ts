import 'dotenv/config';
import pg from 'pg';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const polId = '0f6484bd-2fc1-4071-9648-d7b8a950d29c';

// politician_images
const imgs = await pool.query(`SELECT * FROM essentials.politician_images WHERE politician_id = $1`, [polId]);
console.log('politician_images:', JSON.stringify(imgs.rows, null, 2));

// Check what getCandidateById actually returns
const rcId = '688dd4cd-8b75-4935-96a4-e0aec5b345f8';
const result = await pool.query(`
  SELECT
    rc.id           AS candidate_id,
    rc.full_name,
    rc.first_name,
    rc.last_name,
    COALESCE(rc.photo_url, pi.url) AS photo_url,
    rc.is_incumbent,
    rc.politician_id,
    r.position_name,
    e.election_date::text AS election_date,
    e.election_type
  FROM essentials.race_candidates rc
  JOIN essentials.races r ON r.id = rc.race_id
  JOIN essentials.elections e ON e.id = r.election_id
  LEFT JOIN LATERAL (
    SELECT url FROM essentials.politician_images
    WHERE politician_id = rc.politician_id AND type = 'default'
    LIMIT 1
  ) pi ON rc.politician_id IS NOT NULL
  WHERE rc.id = $1
    AND rc.candidate_status != 'withdrawn'
`, [rcId]);
console.log('getCandidateById result:', JSON.stringify(result.rows, null, 2));

await pool.end();
