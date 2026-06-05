import 'dotenv/config';
import { Pool } from 'pg';

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const SOURCE_PAGE = 'https://www.fremont.gov/government/mayor-city-council';
const CDN_BASE = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos';

const OFFICIALS = [
  { name: 'Raj Salwan', ext: -670001, id: '71124b00-549d-460c-8f84-41a01d99e037', 
    sourceUrl: 'https://www.fremont.gov/home/showpublishedimage/482/638791182509370000', license: 'public_domain' },
  { name: 'Teresa Keng', ext: -670010, id: 'fecd31b9-fc2e-4d90-80f2-15ac89fb0eff',
    sourceUrl: 'https://www.fremont.gov/home/showpublishedimage/6159/637981555727730000', license: 'public_domain' },
  { name: 'Desrie Campbell', ext: -670011, id: '28839e39-6db1-4253-94a4-94ae234c241e',
    sourceUrl: 'https://www.fremont.gov/home/showpublishedimage/6771/638072457065130000', license: 'public_domain' },
  { name: 'Kathy Kimberlin', ext: -670012, id: 'f886f6da-d08f-4294-81bc-faf4a1eaad4d',
    sourceUrl: 'https://www.fremont.gov/home/showpublishedimage/9621/638767001732970000', license: 'public_domain' },
  { name: 'Yang Shao', ext: -670013, id: '7db82a3d-5aa2-4150-996e-b170b50b47fe',
    sourceUrl: 'https://www.fremont.gov/home/showpublishedimage/10104/638767007145300000', license: 'public_domain' },
  { name: 'Yajing Zhang', ext: -670014, id: 'd6d492b6-cbaf-4398-9301-4fbd10da571f',
    sourceUrl: 'https://www.fremont.gov/home/showpublishedimage/9838/638767002190270000', license: 'public_domain' },
  { name: 'Raymond Liu', ext: -670015, id: '42e95c4c-4e02-4d60-805c-6a3d857dd95a',
    sourceUrl: 'https://www.fremont.gov/home/showpublishedimage/9840/638791182084370000', license: 'public_domain' },
];

async function run() {
  for (const official of OFFICIALS) {
    const storageUrl = `${CDN_BASE}/${official.id}-headshot.jpg`;
    
    // Insert politician_images row (idempotent)
    const insertRes = await pool.query(`
      INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
      SELECT gen_random_uuid(),
             $1::uuid,
             $2,
             'default',
             $3
      WHERE NOT EXISTS (
        SELECT 1 FROM essentials.politician_images WHERE politician_id = $1::uuid
      )
      RETURNING id
    `, [official.id, storageUrl, official.license]);
    
    const inserted = insertRes.rowCount;
    console.log(`${official.name}: politician_images INSERT rowCount=${inserted} (0=already exists)`);
    
    // Update photo_origin_url
    const updateRes = await pool.query(`
      UPDATE essentials.politicians
      SET photo_origin_url = $1
      WHERE id = $2::uuid AND photo_origin_url IS NULL
    `, [SOURCE_PAGE, official.id]);
    
    console.log(`${official.name}: photo_origin_url UPDATE rowCount=${updateRes.rowCount}`);
    console.log(`  Storage: ${storageUrl}`);
    console.log('');
  }
  
  // Verify final counts
  const verify = await pool.query(`
    SELECT ch.name AS chamber,
           COUNT(p.id) AS politicians_in_db,
           COUNT(pi.id) AS with_headshot,
           COUNT(p.id) - COUNT(pi.id) AS missing_headshot
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.id = p.office_id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
    LEFT JOIN essentials.politician_images pi ON pi.politician_id = p.id
    WHERE g.name='City of Fremont' AND g.state='CA'
      AND p.external_id BETWEEN -670015 AND -670001
      AND p.is_active = true AND p.is_vacant = false
    GROUP BY ch.name
    ORDER BY ch.name
  `);
  
  console.log('=== Coverage Verification ===');
  console.table(verify.rows);
  
  const photoCheck = await pool.query(`
    SELECT COUNT(*) as count FROM essentials.politicians
    WHERE external_id BETWEEN -670015 AND -670001
      AND photo_origin_url IS NOT NULL
  `);
  console.log('photo_origin_url set count:', photoCheck.rows[0].count);
  
  await pool.end();
}
run().catch(console.error);
