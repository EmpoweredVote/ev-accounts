import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';

const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Referer': 'https://www.sanjoseca.gov/your-government/city-council',
};

const TMP_DIR = process.env.TEMP || 'C:/Windows/Temp';

async function downloadAndCheckSize(name: string, url: string): Promise<{w: number, h: number, size: number}|null> {
  const resp = await fetch(url, { headers: HEADERS });
  if (resp.status !== 200) { console.log(`  ${name}: FAILED ${resp.status}`); return null; }
  const buf = Buffer.from(await resp.arrayBuffer());
  const tmpFile = path.join(TMP_DIR, `sj-portrait-${name}.jpg`);
  fs.writeFileSync(tmpFile, buf);
  return { w: 0, h: 0, size: buf.length }; // Will check with Python
}

async function main() {
  // Try to find portraits for all districts on sanjoseca.gov
  // The URL pattern is /home/showpublishedimage/{id}/{timestamp}
  // Kamei = 18393, Mulcahy = 23362
  // Try to find pages for other officials

  // Check the main city council page for portrait images
  console.log('Checking main council page for portraits...');
  const mainResp = await fetch('https://www.sanjoseca.gov/your-government/city-council', { headers: HEADERS });
  const mainHtml = await mainResp.text();

  // Find image IDs with useful context
  const regex = /showpublishedimage\/(\d+)\/(\d+)/g;
  let m;
  const portraits: {id: string, ts: string, ctx: string}[] = [];
  while ((m = regex.exec(mainHtml)) !== null) {
    const ctx = mainHtml.substring(Math.max(0, m.index - 300), Math.min(mainHtml.length, m.index + 300)).replace(/\s+/g, ' ');
    if (!/facebook|twitter|instagram|linkedin|youtube|nextdoor|IG Logo|Center for Digital|logo/i.test(ctx)) {
      portraits.push({ id: m[1], ts: m[2], ctx });
    }
  }
  console.log(`Found ${portraits.length} non-nav portraits on main page`);
  portraits.forEach(p => console.log(`  ${p.id}/${p.ts}: ${p.ctx.substring(0, 200)}`));

  console.log('\nChecking /departments-offices page...');
  const deptResp = await fetch('https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council', { headers: HEADERS });
  const deptHtml = await deptResp.text();
  const regex2 = /showpublishedimage\/(\d+)\/(\d+)/g;
  const portraits2: string[] = [];
  while ((m = regex2.exec(deptHtml)) !== null) {
    const ctx = deptHtml.substring(Math.max(0, m.index - 300), Math.min(deptHtml.length, m.index + 300)).replace(/\s+/g, ' ');
    if (!/facebook|twitter|instagram|linkedin|youtube|nextdoor|IG Logo|Center for Digital|logo/i.test(ctx)) {
      portraits2.push(`  ${m[1]}/${m[2]}: ${ctx.substring(0, 200)}`);
    }
  }
  console.log(`Found ${portraits2.length} non-nav portraits on dept page`);
  portraits2.forEach(p => console.log(p));

  // Check each council district's biography/meet-councilmember pages
  const pages = [
    ['D2-Campos', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-2/councilmember-pamela-campos-biography'],
    ['D3-Tordillos', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-3/councilmember-anthony-tordillos'],
    ['D3-Tordillos-b', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-3/meet-councilmember'],
    ['D4-Cohen', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-4/david-cohen'],
    ['D5-Ortiz', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-5/peter-ortiz-biography'],
    ['D7-Doan', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-7/councilmember-bien-doan'],
    ['D7-Doan-b', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-7/bio'],
    ['D8-Candelas', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-8/councilmember-domingo-candelas'],
    ['D9-Foley', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-9/councilmember-pam-foley'],
    ['D9-Foley-b', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-9/meet-vice-mayor-foley'],
    ['D10-Casey', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-10/councilmember-george-casey'],
    ['D10-Casey-b', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-10/george-casey'],
  ];

  for (const [name, url] of pages) {
    await new Promise(r => setTimeout(r, 200));
    const resp = await fetch(url, { headers: HEADERS });
    if (resp.status !== 200) {
      console.log(`\n${name}: ${resp.status}`);
      continue;
    }
    const html = await resp.text();
    const imgs: string[] = [];
    const re = /showpublishedimage\/(\d+)\/(\d+)/g;
    while ((m = re.exec(html)) !== null) {
      const ctx = html.substring(Math.max(0, m.index - 250), Math.min(html.length, m.index + 200)).replace(/\s+/g, ' ');
      if (!/facebook|twitter|instagram|linkedin|youtube|nextdoor|IG Logo|Center for Digital|Digital Cities|logo/i.test(ctx)) {
        imgs.push(`  ${m[1]}/${m[2]}: ${ctx.substring(0, 200)}`);
      }
    }
    if (imgs.length > 0) {
      console.log(`\n${name} (200 OK):`);
      imgs.forEach(i => console.log(i));
    } else {
      console.log(`\n${name}: 200 OK, no portrait images`);
    }
  }
}

main().catch(console.error);
