import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';

const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Referer': 'https://www.sanjoseca.gov/',
};
const TMP_DIR = process.env.TEMP || 'C:/Windows/Temp';

async function tryLarger(name: string, id: string, ts: string): Promise<void> {
  // Try without width constraint (maybe the small ones are via CSS sizing, not URL params)
  const baseUrl = `https://www.sanjoseca.gov/home/showpublishedimage/${id}/${ts}`;
  console.log(`\n${name} (${id}):`);

  // Try plain URL
  const r1 = await fetch(baseUrl, { headers: HEADERS });
  const ct1 = r1.headers.get('content-type') || '';
  const buf1 = Buffer.from(await r1.arrayBuffer());
  console.log(`  Plain: ${r1.status}, ${buf1.length} bytes, ${ct1}`);

  // Try with ?maxwidth=1200
  const r2 = await fetch(`${baseUrl}?maxwidth=1200`, { headers: HEADERS });
  const buf2 = Buffer.from(await r2.arrayBuffer());
  console.log(`  ?maxwidth=1200: ${r2.status}, ${buf2.length} bytes`);

  // Try with different pixel size approach: GovBuilder CivicPlus often has resizeimage endpoint
  const r3 = await fetch(`https://www.sanjoseca.gov/home/showpublishedimage/${id}/${ts}/original`, { headers: HEADERS });
  console.log(`  /original: ${r3.status}`);

  // Save the largest
  if (buf1.length > 0) {
    const ext = ct1.includes('png') ? 'png' : 'jpg';
    const outFile = path.join(TMP_DIR, `sj-large-${name}.${ext}`);
    fs.writeFileSync(outFile, buf1);
    console.log(`  Saved: ${outFile}`);
  }
}

async function tryAlternatePortrait(name: string, url: string): Promise<void> {
  // Try fetching from official bio page to find higher-res portrait ID
  console.log(`\n${name} bio page:`);
  const resp = await fetch(url, { headers: HEADERS });
  console.log(`  Status: ${resp.status}`);
  if (resp.status !== 200) return;
  const html = await resp.text();

  const regex = /showpublishedimage\/(\d+)\/(\d+)/g;
  let m;
  while ((m = regex.exec(html)) !== null) {
    const ctx = html.substring(Math.max(0, m.index - 200), Math.min(html.length, m.index + 200)).replace(/\s+/g, ' ');
    if (!/facebook|twitter|instagram|linkedin|youtube|nextdoor|IG Logo|Center for Digital|email|calendar/i.test(ctx)) {
      // Download to check size
      const imgUrl = `https://www.sanjoseca.gov/home/showpublishedimage/${m[1]}/${m[2]}`;
      const r = await fetch(imgUrl, { headers: HEADERS });
      const buf = Buffer.from(await r.arrayBuffer());
      if (buf.length > 30000) { // Only show substantial images
        const ext = (r.headers.get('content-type') || '').includes('png') ? 'png' : 'jpg';
        const outFile = path.join(TMP_DIR, `sj-bio-${name}-${m[1]}.${ext}`);
        fs.writeFileSync(outFile, buf);
        console.log(`  Found ${m[1]}/${m[2]}: ${buf.length} bytes → ${outFile}`);
        console.log(`    Context: ${ctx.substring(0, 150)}`);
      }
    }
  }
}

async function main() {
  // Check if Kamei's larger image (18393) is from her personal page, not dept page
  // The dept page shows 18264 (small), her bio page has 18393 (large)
  // This means each official's bio page has a larger portrait

  // Try the bio pages that returned 200 OK
  await tryAlternatePortrait('D2-Campos', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-2/councilmember-pamela-campos-biography');
  await new Promise(r => setTimeout(r, 300));

  await tryAlternatePortrait('D5-Ortiz', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-5/peter-ortiz-biography');
  await new Promise(r => setTimeout(r, 300));

  await tryAlternatePortrait('D5-Ortiz-b', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-5/peter-ortiz-biography/boards-committees');
  await new Promise(r => setTimeout(r, 300));

  // Try guessing biography page URLs
  const guesses = [
    ['D3-Tordillos', '/district-3/meet-your-councilmember'],
    ['D3-Tordillos', '/district-3/councilmember-tordillos-biography'],
    ['D3-Tordillos', '/district-3/councilmember-anthony-tordillos-biography'],
    ['D3-Tordillos', '/district-3/tordillos-biography'],
    ['D4-Cohen', '/district-4/councilmember-david-cohen-biography'],
    ['D4-Cohen', '/district-4/david-cohen-biography'],
    ['D4-Cohen', '/district-4/councilmember-cohen-biography'],
    ['D6-Mulcahy', '/district-6/councilmember-mulcahy-biography'],
    ['D6-Mulcahy', '/district-6/councilmember-michael-mulcahy-biography'],
    ['D6-Mulcahy', '/district-6/michael-mulcahy-biography'],
    ['D7-Doan', '/district-7/councilmember-doan-biography'],
    ['D7-Doan', '/district-7/councilmember-bien-doan-biography'],
    ['D8-Candelas', '/district-8/councilmember-candelas-biography'],
    ['D8-Candelas', '/district-8/councilmember-domingo-candelas-biography'],
    ['D9-Foley', '/district-9/councilmember-foley-biography'],
    ['D9-Foley', '/district-9/councilmember-pam-foley-biography'],
    ['D9-Foley', '/district-9/vice-mayor-pam-foley-biography'],
    ['D10-Casey', '/district-10/councilmember-casey-biography'],
    ['D10-Casey', '/district-10/councilmember-george-casey-biography'],
  ];

  const BASE = 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council';
  for (const [name, suffix] of guesses) {
    const resp = await fetch(`${BASE}${suffix}`, { headers: HEADERS });
    if (resp.status === 200) {
      console.log(`\nFOUND: ${name} at ${suffix}`);
      const html = await resp.text();
      const re = /showpublishedimage\/(\d+)\/(\d+)/g;
      let m;
      while ((m = re.exec(html)) !== null) {
        const ctx = html.substring(Math.max(0, m.index - 200), Math.min(html.length, m.index + 200)).replace(/\s+/g, ' ');
        if (!/facebook|twitter|instagram|linkedin|youtube|nextdoor|IG Logo|Center for Digital|email|calendar/i.test(ctx)) {
          const imgUrl = `https://www.sanjoseca.gov/home/showpublishedimage/${m[1]}/${m[2]}`;
          const r = await fetch(imgUrl, { headers: HEADERS });
          const buf = Buffer.from(await r.arrayBuffer());
          if (buf.length > 20000) {
            console.log(`  ${m[1]}: ${buf.length} bytes`);
          }
        }
      }
    }
    await new Promise(r => setTimeout(r, 100));
  }

  // Also check the Mulcahy page that returned 200 with portrait
  await tryAlternatePortrait('D6-Mulcahy', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-6/your-councilmember');
}

main().catch(console.error);
