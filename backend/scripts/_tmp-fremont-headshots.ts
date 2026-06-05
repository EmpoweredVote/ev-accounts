import 'dotenv/config';
import { Pool } from 'pg';
import * as fs from 'fs';
import * as path from 'path';

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

// All fremont.gov URLs confirmed working with Node fetch + Referer header
const OFFICIALS = [
  { name: 'Raj Salwan', ext: -670001, id: '71124b00-549d-460c-8f84-41a01d99e037', 
    url: 'https://www.fremont.gov/home/showpublishedimage/482/638791182509370000',
    license: 'public_domain' },
  { name: 'Teresa Keng', ext: -670010, id: 'fecd31b9-fc2e-4d90-80f2-15ac89fb0eff',
    url: 'https://www.fremont.gov/home/showpublishedimage/6159/637981555727730000',
    license: 'public_domain' },
  { name: 'Desrie Campbell', ext: -670011, id: '28839e39-6db1-4253-94a4-94ae234c241e',
    url: 'https://www.fremont.gov/home/showpublishedimage/6771/638072457065130000',
    license: 'public_domain' },
  { name: 'Kathy Kimberlin', ext: -670012, id: 'f886f6da-d08f-4294-81bc-faf4a1eaad4d',
    url: 'https://www.fremont.gov/home/showpublishedimage/9621/638767001732970000',
    license: 'public_domain' },
  { name: 'Yang Shao', ext: -670013, id: '7db82a3d-5aa2-4150-996e-b170b50b47fe',
    url: 'https://www.fremont.gov/home/showpublishedimage/10104/638767007145300000',
    license: 'public_domain' },
  { name: 'Yajing Zhang', ext: -670014, id: 'd6d492b6-cbaf-4398-9301-4fbd10da571f',
    url: 'https://www.fremont.gov/home/showpublishedimage/9838/638767002190270000',
    license: 'public_domain' },
  { name: 'Raymond Liu', ext: -670015, id: '42e95c4c-4e02-4d60-805c-6a3d857dd95a',
    url: 'https://www.fremont.gov/home/showpublishedimage/9840/638791182084370000',
    license: 'public_domain' },
];

const SOURCE_PAGE = 'https://www.fremont.gov/government/mayor-city-council';
const SUPABASE_URL = process.env.SUPABASE_URL!;
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const CDN_BASE = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos';
const TMP_DIR = process.env.TEMP || 'C:/Windows/Temp';

async function downloadImage(url: string): Promise<Buffer> {
  const resp = await fetch(url, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Referer': 'https://www.fremont.gov/government/mayor-city-council',
    }
  });
  if (!resp.ok) throw new Error(`Download failed: ${resp.status} for ${url}`);
  const buf = await resp.arrayBuffer();
  return Buffer.from(buf);
}

async function uploadToStorage(politicianId: string, data: Buffer): Promise<string> {
  const filename = `${politicianId}-headshot.jpg`;
  const resp = await fetch(`${SUPABASE_URL}/storage/v1/object/politician_photos/${filename}`, {
    method: 'PUT',
    headers: {
      'Authorization': `Bearer ${SERVICE_KEY}`,
      'Content-Type': 'image/jpeg',
      'x-upsert': 'true',
    },
    body: data,
  });
  const text = await resp.text();
  if (resp.status !== 200 && resp.status !== 201) {
    throw new Error(`Upload failed: ${resp.status} ${text}`);
  }
  return `${CDN_BASE}/${filename}`;
}

async function run() {
  console.log('Starting Fremont headshot download + upload...\n');
  
  for (const official of OFFICIALS) {
    console.log(`Processing: ${official.name} (${official.ext})`);
    
    try {
      // Download image
      const imgBuf = await downloadImage(official.url);
      console.log(`  Downloaded: ${imgBuf.length} bytes from fremont.gov`);
      
      // Save to temp file for PIL processing
      const tmpFile = path.join(TMP_DIR, `${official.id}-raw.jpg`);
      fs.writeFileSync(tmpFile, imgBuf);
      console.log(`  Saved to: ${tmpFile}`);
      
      console.log(`  Image downloaded OK. PIL processing will be done in Python next step.`);
      console.log(`  Source URL: ${official.url}`);
      console.log('');
    } catch (err) {
      console.error(`  ERROR for ${official.name}:`, err);
    }
  }
  
  await pool.end();
}
run().catch(console.error);
