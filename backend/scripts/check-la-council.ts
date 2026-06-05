import 'dotenv/config';
import pg from 'pg';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const cols = await pool.query(`SELECT column_name FROM information_schema.columns WHERE table_schema='essentials' AND table_name='districts' ORDER BY ordinal_position`);
console.log('districts columns:', cols.rows.map((r: any) => r.column_name));

const cols2 = await pool.query(`SELECT column_name FROM information_schema.columns WHERE table_schema='essentials' AND table_name='offices' ORDER BY ordinal_position`);
console.log('offices columns:', cols2.rows.map((r: any) => r.column_name));

const res = await pool.query(`
  SELECT p.full_name, o.title, d.geo_id, d.label, d.district_id
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.id = p.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '0644000'
    AND ch.name ILIKE '%council%'
  ORDER BY d.geo_id
`);

console.log(JSON.stringify(res.rows, null, 2));
await pool.end();
