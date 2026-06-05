import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';

const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
};

const TMP_DIR = process.env.TEMP || 'C:/Windows/Temp';

async function download(name: string, url: string, referer?: string): Promise<void> {
  console.log(`Downloading: ${name}`);
  const resp = await fetch(url, {
    headers: {
      ...HEADERS,
      'Referer': referer || url,
    }
  });
  console.log(`  Status: ${resp.status}, Type: ${resp.headers.get('content-type')}`);
  if (resp.status !== 200) return;
  const buf = Buffer.from(await resp.arrayBuffer());
  const ext = url.includes('.png') ? 'png' : 'jpg';
  const tmpFile = path.join(TMP_DIR, `sj-preview-${name}.${ext}`);
  fs.writeFileSync(tmpFile, buf);
  console.log(`  Size: ${buf.length} bytes → ${tmpFile}`);
}

async function main() {
  // D3 Tordillos landing image (need to check if portrait or banner)
  await download('D3-Tordillos-landing',
    'https://images.squarespace-cdn.com/content/v1/68dc1d398d83da7d0336165b/265abb99-2103-4102-83ed-303e5b4034e3/Website+Landing+Image.png');

  // D2 Campos portrait - try the "Councilmember+Campos+and+Constituent.jpg"
  await download('D2-Campos-constituent',
    'https://images.squarespace-cdn.com/content/v1/6942f53c3db83d0e41471664/80844ee0-5655-4a0e-95dd-159b9b23842c/Councilmember+Campos+and+Constituent.jpg');

  // D4 Cohen "cohen at city hall 2"
  await download('D4-Cohen-cityhall',
    'https://images.squarespace-cdn.com/content/v1/6201a5e40577d74133ad4cad/756eaf72-18b7-44b0-9036-3a560af75d95/cohen+at+city+hall+2.jpg');

  // D7 Doan - CM Doan with Children
  await download('D7-Doan-children',
    'https://images.squarespace-cdn.com/content/v1/67e5a8b8296f5a5a0214b875/0d63fb05-a2b7-467a-b55b-390e6df2cf06/CM+Doan+with+Children.jpg');

  // D10 Casey
  await download('D10-Casey-photo',
    'https://images.squarespace-cdn.com/content/v1/67d36df71d3cca0e7ebe4c0e/824d19c7-6a09-482a-8000-c2faa6c4dee9/George+Casey+higher+quality+square+photo.jpg');
}

main().catch(console.error);
