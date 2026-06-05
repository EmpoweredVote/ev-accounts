import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';

const TMP_DIR = process.env.TEMP || 'C:/Windows/Temp';
const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Referer': 'https://www.sjdistrict3.org/',
};

// Download CM Tordillos First Day photo at max quality
const url = 'https://images.squarespace-cdn.com/content/v1/68dc1d398d83da7d0336165b/51c8e8fe-edad-4a15-89b7-0906009f2f9f/CM+Tordillos+First+Day.png?format=2500w';
const resp = await fetch(url, { headers: HEADERS });
console.log('Status:', resp.status, 'Type:', resp.headers.get('content-type'));
const buf = Buffer.from(await resp.arrayBuffer());
const outFile = path.join(TMP_DIR, 'sj-tordillos-first-day.webp');
fs.writeFileSync(outFile, buf);
console.log(`${buf.length} bytes → ${outFile}`);

// Also check the landing image dimensions (1570302 bytes)
console.log('\nLanding image already saved at:', path.join(TMP_DIR, 'sj-tordillos-landing-full.webp'));
