import 'dotenv/config';
import * as fs from 'fs';

const POLITICIAN_ID = '7b527446-d801-42c6-9233-053c2b02e128';
const SUPABASE_URL = process.env.SUPABASE_URL!;
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const CDN_BASE = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos';

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
  if (!resp.ok) {
    const body = await resp.text();
    throw new Error(`Upload failed: ${resp.status} ${body}`);
  }
  return `${CDN_BASE}/${filename}`;
}

async function main() {
  const imagePath = 'C:/EV-Accounts/backend/scripts/tordillos-headshot.jpg';
  console.log(`Reading processed headshot from: ${imagePath}`);
  const data = fs.readFileSync(imagePath);
  console.log(`File size: ${data.length} bytes`);

  console.log(`Uploading to Supabase Storage for politician_id: ${POLITICIAN_ID}`);
  const url = await uploadToStorage(POLITICIAN_ID, data);
  console.log(`Uploaded successfully: ${url}`);

  // The URL in politician_images already uses this same path pattern, so no DB update needed
  // unless we want to update photo_license from 'public_domain' to 'cc-by-sa-4.0'
  console.log('\nNote: Source is Run on Climate (runonclimate.org) - CC BY-SA 4.0 license (attribution: City of San Jose / Anthony Tordillos campaign)');
  console.log('Consider updating photo_license from public_domain to cc-by-sa-4.0 if needed.');
  console.log('\nDone.');
}

main().catch(e => { console.error(e); process.exit(1); });
