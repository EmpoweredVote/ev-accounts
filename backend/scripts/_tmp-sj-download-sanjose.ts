import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';

const TMP_DIR = process.env.TEMP || 'C:/Windows/Temp';

const SJ_HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
};

async function download(name: string, url: string, referer: string): Promise<void> {
  console.log(`Downloading ${name}: ${url}`);
  const resp = await fetch(url, {
    headers: {
      ...SJ_HEADERS,
      'Referer': referer,
    }
  });
  console.log(`  Status: ${resp.status}, Type: ${resp.headers.get('content-type')}`);
  if (resp.status !== 200) {
    console.log(`  FAILED`);
    return;
  }
  const buf = Buffer.from(await resp.arrayBuffer());
  const outFile = path.join(TMP_DIR, `sj-sanjoseca-${name}.jpg`);
  fs.writeFileSync(outFile, buf);
  console.log(`  ${buf.length} bytes → ${outFile}`);
}

// Download Kamei and Mulcahy portraits via Node fetch (bypasses 403 WAF)
await download(
  'Kamei',
  'https://www.sanjoseca.gov/home/showpublishedimage/18393/638145599495300000',
  'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-1/the-team/rosemary-kamei'
);

await download(
  'Mulcahy',
  'https://www.sanjoseca.gov/home/showpublishedimage/23362/639001978590570000',
  'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-6/your-councilmember'
);
