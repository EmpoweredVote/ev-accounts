import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';

const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
};
const TMP_DIR = process.env.TEMP || 'C:/Windows/Temp';

async function getWikimediaFileInfo(filename: string): Promise<{url: string, license: string}> {
  const apiUrl = `https://commons.wikimedia.org/w/api.php?action=query&titles=File:${encodeURIComponent(filename)}&prop=imageinfo&iiprop=url|extmetadata&format=json`;
  const resp = await fetch(apiUrl, { headers: HEADERS });
  const data: any = await resp.json();
  const pages = data?.query?.pages;
  if (pages) {
    for (const p of Object.values(pages) as any[]) {
      const ii = p.imageinfo?.[0];
      return { url: ii?.url || '', license: ii?.extmetadata?.LicenseShortName?.value || 'unknown' };
    }
  }
  return { url: '', license: '' };
}

async function downloadImage(url: string, name: string): Promise<Buffer | null> {
  try {
    const resp = await fetch(url, { headers: { ...HEADERS, 'Referer': url } });
    if (resp.status !== 200) {
      console.log(`  ${name}: FAILED ${resp.status}`);
      return null;
    }
    const buf = Buffer.from(await resp.arrayBuffer());
    const ext = url.endsWith('.png') ? 'png' : 'jpg';
    fs.writeFileSync(path.join(TMP_DIR, `sj-wiki-${name}.${ext}`), buf);
    console.log(`  ${name}: ${buf.length} bytes`);
    return buf;
  } catch (e: any) {
    console.log(`  ${name}: ERROR ${e.message}`);
    return null;
  }
}

async function main() {
  const wikiFiles = [
    { name: 'D3-Tordillos', file: 'Anthony Tordillos.png' },
    { name: 'D4-Cohen', file: 'David Cohen City of San Jose.jpg' },
    { name: 'D7-Doan', file: 'Bien Doan, San José City Councilman.png' },
    { name: 'D2-Campos', file: 'Pamela Campos, San José City Councilmember.jpg' },
    { name: 'D8-Candelas', file: 'Domingo Candelas, San José City Councilman.png' },
    { name: 'D9-Foley', file: 'Foley Pam - San José City Councilwoman.jpg' },
    { name: 'D5-Ortiz', file: 'Peter Ortiz, San José City Councilman.png' },
    { name: 'Mayor-Mahan', file: 'Matt Mahan portrait 2025.jpg' },
  ];

  console.log('Getting Wikimedia URLs and downloading images...\n');
  for (const w of wikiFiles) {
    const info = await getWikimediaFileInfo(w.file);
    console.log(`${w.name}:`);
    console.log(`  File: ${w.file}`);
    console.log(`  URL: ${info.url}`);
    console.log(`  License: ${info.license}`);
    if (info.url) {
      await downloadImage(info.url, w.name);
    }
    await new Promise(r => setTimeout(r, 200));
  }
}

main().catch(console.error);
