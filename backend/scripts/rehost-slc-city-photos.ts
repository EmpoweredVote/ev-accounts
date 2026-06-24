#!/usr/bin/env -S npx tsx
// One-shot photo rehost for SLC city officials missing politician_images.
// Fetches each source URL, uploads to Supabase politician_photos bucket,
// dual-writes to politician_images + politicians.photo_custom_url.
//
// Run: cd ev-accounts/backend && npx tsx scripts/rehost-slc-city-photos.ts
import 'dotenv/config';
import pg from 'pg';
import { rehostPhoto } from './lib/photo-rehost';

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// politician_id | external_id | photo_url
// Omit rows where photo_url is NOT_FOUND (Taylorsville D1/D2/D3/D5, CH D2)
const PHOTOS: Array<{ id: string; ext: number; name: string; url: string }> = [
  // ── Sandy ────────────────────────────────────────────────────────────────
  { id: '6a7b2e72-1ea1-4b1c-8227-eb0cc2565227', ext: -327774, name: 'Monica Zoltanski',    url: 'https://content.civicplus.com/api/assets/b83b30d2-ec50-4e1c-b393-33aeecb72016' },
  { id: '90d02e71-f112-48ac-86cf-311a92c61455', ext: -309335, name: 'Brooke Christensen',  url: 'https://content.civicplus.com/api/assets/474c8f96-ca69-4bcd-b03f-09db00ca8ae4' },
  { id: 'fd7359a8-a1f4-44f5-af1f-37e1ea5b672e', ext: -309340, name: 'Alison Stroud',       url: 'https://content.civicplus.com/api/assets/9ba09490-23aa-4ba2-9f71-a0f41bca5183' },
  { id: 'd3ccda67-a03c-45f2-a5ef-f5e7b7bfb71f', ext: -309338, name: 'Kris Nicholl',        url: 'https://content.civicplus.com/api/assets/c1d95f90-1d9a-46f9-95af-d2f8dfb1f1bf' },
  { id: '37acb609-8bf5-4cfe-905a-7d865d667b44', ext: -309336, name: 'Marci Houseman',      url: 'https://content.civicplus.com/api/assets/83d2422d-f1f3-42e8-910a-c33e8dc47e48' },
  { id: '6f9bfd38-0eff-46ba-9ac8-a2cfc0d4b7b3', ext: -309341, name: 'Cyndi Sharkey',       url: 'https://content.civicplus.com/api/assets/25b702f6-cc7c-46a7-842a-be37d6b1de02' },
  { id: '9d16a139-5287-4959-9dcb-edfa2fa8bf8b', ext: -309342, name: 'Aaron Dekeyzer',      url: 'https://content.civicplus.com/api/assets/ed590e47-459b-4dc7-9277-28863e7652a1' },
  { id: 'b2931ade-6e14-4b02-8e3a-5874234940f6', ext: -309343, name: "Brooke D'Sousa",      url: 'https://content.civicplus.com/api/assets/08c23784-1076-4d43-82c1-5547df94a43e' },
  // ── Holladay ─────────────────────────────────────────────────────────────
  { id: '7668128f-c46c-4af8-af70-04a6ccb8cad8', ext: -303650, name: 'Paul Fotheringham',   url: 'https://cms3.revize.com/revize/cityofholladay/Document%20Center/Government/Mayor%20And%20Council/Paul.jpg' },
  { id: '5e96ba97-bcb9-4d0b-a569-26bca15ac74a', ext: -346654, name: 'David Sundwall',      url: 'https://cms3.revize.com/revize/cityofholladay/Document%20Center/Government/Mayor%20And%20Council/david.jpg' },
  { id: '1f770a02-bafe-4e24-805f-ba52d6198a89', ext: -360720, name: 'Matt Durham',         url: 'https://cms3.revize.com/revize/cityofholladay/Document%20Center/Government/Mayor%20And%20Council/Matt.jpg' },
  { id: '3228669e-be5c-49da-af47-043f8083f86f', ext: -398812, name: 'Natalie Bradley',     url: 'https://cms3.revize.com/revize/cityofholladay/Document%20Center/Government/Mayor%20And%20Council/Natalie.jpg' },
  { id: '21a5e008-9df2-444d-b6cf-203f5d09ff63', ext: -318253, name: 'Drew Quinn',          url: 'https://cms3.revize.com/revize/cityofholladay/Document%20Center/Government/Mayor%20And%20Council/Drew.jpg' },
  { id: '749ea765-4c78-4288-928d-516b3af1b2b9', ext: -329627, name: 'Emily Gray',          url: 'https://cms3.revize.com/revize/cityofholladay/Document%20Center/Government/Mayor%20And%20Council/emily.jpg' },
  // ── Taylorsville (2 found; Burgess/Cochran/Barbieri/Knudsen skipped — no public URL) ─
  { id: 'fe8f7910-872f-4ff6-ba5d-8ccfb332294d', ext: -379213, name: 'Kristie S. Overson',  url: 'https://static.wixstatic.com/media/d8612a_b96807da22934922921cc5cd16f5e714~mv2.jpg' },
  { id: '465e1617-a76b-491f-84ac-16f283f01963', ext: -301807, name: 'Meredith Harker',     url: 'https://cdn.kslnewsradio.com/kslnewsradio/wp-content/uploads/2021/07/Untitled-design-29-620x370.png' },
  // ── South Salt Lake ───────────────────────────────────────────────────────
  { id: '3c9917c8-6426-4a68-a086-44c8edf2d0d5', ext: -327106, name: 'Joy Glad',            url: 'https://www.sslc.gov/ImageRepository/Document?documentID=4154' },
  { id: '619fc595-e896-4cc1-8151-64b1836f0b9e', ext: -373453, name: 'Corey Thomas',        url: 'https://www.sslc.gov/ImageRepository/Document?documentID=3141' },
  { id: 'c179c8c0-8eae-48a3-b402-3fbaed58ee95', ext: -362131, name: 'Sharla Bynum',        url: 'https://www.sslc.gov/ImageRepository/Document?documentID=3099' },
  { id: '37cb521f-ff99-4166-acf2-79bca812bdc3', ext: -310359, name: 'Nick Mitchell',       url: 'https://www.sslc.gov/ImageRepository/Document?documentID=1867' },
  { id: 'aa23b271-898f-4455-bea4-ec115ba653df', ext: -320173, name: 'Irvin Jones',         url: 'https://www.sslc.gov/ImageRepository/Document?documentID=4149' },
  { id: '3d74af4f-3144-4e75-8731-fa2139eae9da', ext: -368244, name: 'Ray deWolfe',         url: 'https://www.sslc.gov/ImageRepository/Document?documentID=3109' },
  { id: '76d850b3-3b84-41f7-987c-03bc5652dd58', ext: -368245, name: 'Clarissa Williams',   url: 'https://www.sslc.gov/ImageRepository/Document?documentID=4173' },
  // ── Bluffdale ─────────────────────────────────────────────────────────────
  { id: 'd80bd161-1a9b-4005-9564-698907eca70d', ext: -378578, name: 'Natalie Hall',        url: 'https://www.bluffdale.gov/ImageRepository/Document?documentID=4537' },
  { id: 'b0c0f9b4-6b4d-4d9a-a866-cf9c47ffc02b', ext: -321449, name: 'Greg Wilding',       url: 'https://www.bluffdale.gov/ImageRepository/Document?documentID=6191' },
  { id: '9dc47ce2-e840-429a-b22c-1928013423fa', ext: -321450, name: 'Steve Austin',        url: 'https://www.bluffdale.gov/ImageRepository/Document?documentID=6193' },
  { id: '4e8b5704-2300-4a19-8d5a-3fa32b8dd6d5', ext: -321451, name: 'Alan Lord',           url: 'https://www.bluffdale.gov/ImageRepository/Document?documentID=6797' },
  { id: 'a0acbfdf-9797-4eef-a3c7-4b9d859ff360', ext: -321452, name: 'Wendy Aston',        url: 'https://www.bluffdale.gov/ImageRepository/Document?documentID=4657' },
  { id: '1c391a9f-570d-4ddc-86d8-08406e41aa03', ext: -321453, name: 'Mackey Smith',        url: 'https://www.bluffdale.gov/ImageRepository/Document?documentID=9251' },
  // ── Cottonwood Heights (4 found; Hyland skipped — no public URL) ──────────
  { id: 'a20d3450-ff54-4017-bab3-0292aacb4e02', ext: -305752, name: 'Gay Lynn Bennion',   url: 'https://images.squarespace-cdn.com/content/v1/68dc4165766c20324d73347f/9aaaaac7-6f6f-4549-b8e6-bf3adc5ff3e7/GLB.jpg' },
  { id: '42687b5a-95d2-4344-a471-2e71f23f56ef', ext: -389556, name: 'Matt Holton',        url: 'https://wfwrdutah.gov/sites/default/files/2024-02/Matt%20Holton.png' },
  { id: '1d5cd26d-5f0a-45b2-bdd2-bb946e575f6b', ext: -388074, name: 'Shawn Newell',       url: 'https://assets.civicengine.com/uploads/candidate/headshot/588556/588556.jpg' },
  { id: '9fb47d1e-a7d8-4fbc-a641-0cb28afc5df9', ext: -317608, name: 'Ellen Birrell',      url: 'https://images.squarespace-cdn.com/content/v1/611b4b2d2c85772524c992dd/1629355196866-O8DZZTZWFYUP0OI9JZFF/ellen_headshot_dark.jpg' },
  // ── Midvale fix (Bonnie Billings — 404 on old path, new 2025 folder) ──────
  { id: 'd9f44809-267b-4cca-8c36-24572d1c13ed', ext: -328814, name: 'Bonnie Billings',    url: 'https://www.midvale.utah.gov/revize_photo_gallery/Government/City%20Council/2025%20Headshots/Bonnie%20Billings.jpg' },
];

async function main() {
  let ok = 0; let fail = 0;
  for (const { id, ext, name, url } of PHOTOS) {
    const client = await pool.connect();
    try {
      const cdnUrl = await rehostPhoto(client, id, ext, url);
      if (cdnUrl) {
        console.log(`[ok] ${name} → ${cdnUrl}`);
        ok++;
      } else {
        fail++;
      }
    } catch (e) {
      console.error(`[err] ${name}: ${(e as Error).message}`);
      fail++;
    } finally {
      client.release();
    }
  }
  console.log(`\nDone: ${ok} uploaded, ${fail} failed`);
  console.log(`Skipped (no public URL): Taylorsville D1/D2/D3/D5 (Burgess/Cochran/Barbieri/Knudsen), Cottonwood Heights D2 (Suzanne Hyland)`);
  await pool.end();
}

main().catch(e => { console.error('[FATAL]', e); process.exit(1); });
