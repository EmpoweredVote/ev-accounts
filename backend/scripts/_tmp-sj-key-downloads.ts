import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';

const TMP_DIR = process.env.TEMP || 'C:/Windows/Temp';
const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
};

async function dl(name: string, url: string): Promise<void> {
  console.log(`\n${name}:`);
  const resp = await fetch(url, { headers: { ...HEADERS, 'Referer': url } });
  console.log(`  Status: ${resp.status}, Type: ${resp.headers.get('content-type')}`);
  if (resp.status !== 200) return;
  const buf = Buffer.from(await resp.arrayBuffer());
  const ct = resp.headers.get('content-type') || '';
  const ext = ct.includes('png') ? 'png' : ct.includes('webp') ? 'webp' : 'jpg';
  const outFile = path.join(TMP_DIR, `sj-key-${name}.${ext}`);
  fs.writeFileSync(outFile, buf);
  console.log(`  ${buf.length} bytes → ${outFile}`);
}

async function main() {
  // D2 Campos official portrait
  await dl('D2-Campos-official',
    'https://images.squarespace-cdn.com/content/v1/6942f53c3db83d0e41471664/d9561bd5-aae8-4d86-99df-390794b8bfed/Official+Portrait-Councilmember+Campos.jpg?format=2500w');
  await new Promise(r => setTimeout(r, 300));

  // D4 Cohen Davidatstorm.png (1600x1600 square)
  await dl('D4-Cohen-davidatstorm',
    'https://images.squarespace-cdn.com/content/v1/6201a5e40577d74133ad4cad/d95c1d21-c133-483a-b929-d1ebcbd43456/Davidatstorm.png?format=2500w');
  await new Promise(r => setTimeout(r, 300));

  // D4 Cohen city council address (4016x2859 - wide)
  await dl('D4-Cohen-council',
    'https://images.squarespace-cdn.com/content/v1/6201a5e40577d74133ad4cad/756eaf72-18b7-44b0-9036-3a560af75d95/cohen+at+city+hall+2.jpg?format=2500w');
  await new Promise(r => setTimeout(r, 300));

  // D5 Ortiz - try the Instagram image (might show Ortiz)
  await dl('D5-Ortiz-instagram',
    'https://images.squarespace-cdn.com/content/v1/686ed8c3a2a217364edd7b9b/44b45907-8de8-4a83-8e75-0255506f797e/485436311_17957403578914446_2558032533985757755_n+%281%29.jpg?format=2500w');
  await new Promise(r => setTimeout(r, 300));

  // D7 Doan - CM Doan with Children photo
  await dl('D7-Doan-children',
    'https://images.squarespace-cdn.com/content/v1/67e5a8b8296f5a5a0214b875/0d63fb05-a2b7-467a-b55b-390e6df2cf06/CM+Doan+with+Children.jpg?format=2500w');
  await new Promise(r => setTimeout(r, 300));

  // D7 Doan 20250403_121148 (might be Doan portrait)
  await dl('D7-Doan-2025',
    'https://images.squarespace-cdn.com/content/v1/67e5a8b8296f5a5a0214b875/b59b78d5-138b-42d3-ab33-a26ea57d84de/20250403_121148.jpg?format=2500w');
  await new Promise(r => setTimeout(r, 300));

  // D10 Casey higher quality square (already downloaded but verify dimensions)
  await dl('D10-Casey-square',
    'https://images.squarespace-cdn.com/content/v1/67d36df71d3cca0e7ebe4c0e/824d19c7-6a09-482a-8000-c2faa6c4dee9/George+Casey+higher+quality+square+photo.jpg?format=2500w');
  await new Promise(r => setTimeout(r, 300));

  // D3 Tordillos - "Website Landing Image" is 1200x630 landscape
  // Try the "other" image from sjdistrict3.org
  await dl('D3-Tordillos-squarespace',
    'https://images.squarespace-cdn.com/content/v1/68dc1d398d83da7d0336165b/265abb99-2103-4102-83ed-303e5b4034e3/Website+Landing+Image.png?format=2500w');
}

main().catch(console.error);
