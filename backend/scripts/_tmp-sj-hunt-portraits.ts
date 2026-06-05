import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';

const HEADERS_SJ = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Referer': 'https://www.sanjoseca.gov/',
};

const TMP_DIR = process.env.TEMP || 'C:/Windows/Temp';
const BASE = 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council';

// Find all images > 50000 bytes on a page (indicates a high-res portrait, not icon)
async function findLargeImages(name: string, url: string): Promise<void> {
  const resp = await fetch(url, { headers: HEADERS_SJ });
  if (resp.status !== 200) { console.log(`  ${name}: ${resp.status}`); return; }
  const html = await resp.text();

  const re = /showpublishedimage\/(\d+)\/(\d+)/g;
  let m;
  const seen = new Set<string>();
  const found: Array<{id:string,ts:string,size:number,ctx:string,ext:string}> = [];

  while ((m = re.exec(html)) !== null) {
    const key = m[1];
    if (seen.has(key)) continue;
    seen.add(key);

    const ctx = html.substring(Math.max(0, m.index - 200), Math.min(html.length, m.index + 300)).replace(/\s+/g, ' ');
    if (/email|calendar|facebook|twitter|instagram|linkedin|youtube|nextdoor|IG Logo|logo/i.test(ctx)) continue;

    const imgUrl = `https://www.sanjoseca.gov/home/showpublishedimage/${m[1]}/${m[2]}`;
    const r = await fetch(imgUrl, { headers: HEADERS_SJ });
    if (r.status !== 200) continue;
    const buf = Buffer.from(await r.arrayBuffer());
    if (buf.length < 40000) continue; // Only large images
    const ct = r.headers.get('content-type') || '';
    const ext = ct.includes('png') ? 'png' : 'jpg';
    const outFile = path.join(TMP_DIR, `sj-hunt-${name}-${m[1]}.${ext}`);
    fs.writeFileSync(outFile, buf);
    found.push({ id: m[1], ts: m[2], size: buf.length, ctx: ctx.substring(0, 150), ext });
  }

  if (found.length > 0) {
    console.log(`  ${name}: found ${found.length} large images`);
    found.forEach(f => console.log(`    ${f.id}: ${f.size} bytes (${f.ext}) - ${f.ctx}`));
  } else {
    console.log(`  ${name}: no large images found`);
  }
}

async function main() {
  // Try many URL patterns for each official
  const urls = [
    // Mayor Mahan
    ['Mayor-Mahan', `${BASE}/mayor-s-office/-NID-282`],
    ['Mayor-Mahan-b', `${BASE}/mayor-s-office/mayor-s-biography`],
    ['Mayor-Mahan-c', `${BASE}/mayor-s-office/about-mayor-mahan`],
    ['Mayor-Mahan-d', `${BASE}/mayor-s-office`],

    // D1 Kamei - already found 18393, but keeping for reference
    // ['D1-Kamei', `${BASE}/district-1/the-team/rosemary-kamei`],  // Known good

    // D2 Campos
    ['D2-Campos', `${BASE}/district-2`],
    ['D2-Campos-b', `${BASE}/district-2/councilmember-pamela-campos-biography`],
    ['D2-Campos-c', `${BASE}/district-2/meet-councilmember`],
    ['D2-Campos-d', `${BASE}/district-2/pamela-campos-biography`],

    // D3 Tordillos
    ['D3-Tordillos', `${BASE}/district-3`],
    ['D3-Tordillos-b', `${BASE}/district-3/councilmember`],
    ['D3-Tordillos-c', 'https://www.sjdistrict3.org/d3-office'],
    ['D3-Tordillos-d', 'https://www.sjdistrict3.org/our-team'],

    // D4 Cohen
    ['D4-Cohen', `${BASE}/district-4`],
    ['D4-Cohen-b', `${BASE}/district-4/david-cohen-biography`],
    ['D4-Cohen-c', `${BASE}/district-4/councilmember-cohen`],

    // D5 Ortiz
    ['D5-Ortiz', `${BASE}/district-5`],
    ['D5-Ortiz-b', `${BASE}/district-5/peter-ortiz-biography`],
    ['D5-Ortiz-c', 'https://www.sjdistrict5.org/about'],

    // D7 Doan
    ['D7-Doan', `${BASE}/district-7`],
    ['D7-Doan-b', 'https://www.sjdistrict7.org/about-councilmember-doan'],
    ['D7-Doan-c', 'https://www.sjdistrict7.org/about_me'],

    // D8 Candelas
    ['D8-Candelas', `${BASE}/district-8`],

    // D9 Foley
    ['D9-Foley', `${BASE}/district-9`],

    // D10 Casey
    ['D10-Casey', `${BASE}/district-10`],
    ['D10-Casey-b', 'https://www.sjdistrict10.org/about'],
    ['D10-Casey-c', 'https://www.sjdistrict10.org/george-casey'],
    ['D10-Casey-d', 'https://www.sjdistrict10.org/our-team'],
    ['D10-Casey-e', 'https://www.sjdistrict10.org/meet-casey'],
  ];

  for (const [name, url] of urls) {
    await findLargeImages(name, url);
    await new Promise(r => setTimeout(r, 250));
  }
}

main().catch(console.error);
