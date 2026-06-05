import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';

const TMP_DIR = process.env.TEMP || 'C:/Windows/Temp';
const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
};

async function downloadAndSave(name: string, url: string): Promise<{file:string,size:number}|null> {
  const resp = await fetch(url, { headers: { ...HEADERS, 'Referer': url.includes('squarespace') ? 'https://www.sanjosedistrict4.com/' : url } });
  if (resp.status !== 200) { console.log(`  FAILED: ${resp.status}`); return null; }
  const buf = Buffer.from(await resp.arrayBuffer());
  const ct = resp.headers.get('content-type') || '';
  const ext = ct.includes('png') ? 'png' : 'webp';
  const outFile = path.join(TMP_DIR, `sj-final2-${name}.${ext}`);
  fs.writeFileSync(outFile, buf);
  console.log(`  ${buf.length} bytes → ${outFile}`);
  return { file: outFile, size: buf.length };
}

// Get Wikimedia URL
async function getWikiUrl(filename: string): Promise<string> {
  const apiUrl = `https://commons.wikimedia.org/w/api.php?action=query&titles=File:${encodeURIComponent(filename)}&prop=imageinfo&iiprop=url&format=json`;
  const r = await fetch(apiUrl, { headers: HEADERS });
  const d: any = await r.json();
  for (const p of Object.values(d?.query?.pages || {}) as any[]) {
    return p.imageinfo?.[0]?.url || '';
  }
  return '';
}

async function main() {
  // D4 Cohen - check the /team or /meet-councilmember page
  console.log('=== D4 Cohen about page ===');
  const resp4 = await fetch('https://www.sanjosedistrict4.com/david-cohen', {
    headers: { ...HEADERS, 'Referer': 'https://www.sanjosedistrict4.com/' }
  });
  console.log(`  /david-cohen: ${resp4.status}`);
  if (resp4.status !== 200) {
    // Try the main page - look for high-res Cohen portrait specifically
    const resp4b = await fetch('https://www.sanjosedistrict4.com', {
      headers: { ...HEADERS, 'Referer': 'https://www.sanjosedistrict4.com/' }
    });
    const html = await resp4b.text();
    // Cohen's name in alt or nearby context
    const re = /https:\/\/images\.squarespace-cdn\.com[^\s"'<>]+cohen[^\s"'<>]*\.(?:jpg|jpeg|png)/gi;
    let m;
    while ((m = re.exec(html)) !== null) {
      console.log(`  Cohen match: ${m[0]}`);
    }
    // Also check "David"
    const re2 = /alt="([^"]*david[^"]*|[^"]*cohen[^"]*)"[^>]*>/gi;
    while ((m = re2.exec(html)) !== null) {
      const ctx = html.substring(Math.max(0, m.index - 100), Math.min(html.length, m.index + 200));
      console.log(`  Alt context: ${ctx.replace(/\s+/g,' ')}`);
    }
  }
  await new Promise(r => setTimeout(r, 300));

  // D10 Casey - download the "George Casey higher quality square photo"
  console.log('\n=== D10 Casey portrait ===');
  await downloadAndSave('D10-Casey',
    'https://images.squarespace-cdn.com/content/v1/67d36df71d3cca0e7ebe4c0e/824d19c7-6a09-482a-8000-c2faa6c4dee9/George+Casey+higher+quality+square+photo.jpg?format=2500w');
  await new Promise(r => setTimeout(r, 300));

  // D3 Tordillos - check the Wikimedia file more carefully
  // Anthony Tordillos.png is 200x200 but maybe there's a larger version on Commons
  console.log('\n=== D3 Tordillos - search for better source ===');
  // Check if sanjoseca.gov has a bio page we haven't found yet
  const sjUrls = [
    'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-3/anthony-tordillos',
    'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-3/councilmember-tordillos',
    'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-3/tordillos',
    'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-3/meet-anthony-tordillos',
  ];
  for (const url of sjUrls) {
    const r = await fetch(url, { headers: HEADERS });
    if (r.status === 200) {
      console.log(`  FOUND: ${url}`);
      const html = await r.text();
      const re = /showpublishedimage\/(\d+)\/(\d+)/g;
      let m;
      while ((m = re.exec(html)) !== null) {
        const ctx = html.substring(Math.max(0, m.index - 150), Math.min(html.length, m.index + 200));
        if (!/email|calendar|facebook|twitter|instagram|linkedin|youtube|nextdoor|IG Logo|Center for Digital/i.test(ctx)) {
          const imgR = await fetch(`https://www.sanjoseca.gov/home/showpublishedimage/${m[1]}/${m[2]}`, { headers: HEADERS });
          const buf = Buffer.from(await imgR.arrayBuffer());
          if (buf.length > 40000) console.log(`    ${m[1]}: ${buf.length} bytes`);
        }
      }
    }
    await new Promise(r => setTimeout(r, 100));
  }

  // D5 Ortiz - check if there's a bio photo on sjdistrict5.org
  console.log('\n=== D5 Ortiz sjdistrict5.org /about ===');
  const resp5 = await fetch('https://www.sjdistrict5.org/about', {
    headers: { ...HEADERS, 'Referer': 'https://www.sjdistrict5.org/' }
  });
  if (resp5.status === 200) {
    const html5 = await resp5.text();
    const re = /https:\/\/images\.squarespace-cdn\.com[^\s"'<>]+\.(?:jpg|jpeg|png)/gi;
    const imgs = new Set<string>();
    let m;
    while ((m = re.exec(html5)) !== null) imgs.add(m[0].split('?')[0]);
    console.log(`  Found ${imgs.size} images:`);
    Array.from(imgs).filter(u => !/logo|map|banner|icon/i.test(u)).slice(0, 5).forEach(u => console.log(`    ${u.replace('https://images.squarespace-cdn.com/content/v1/686ed8c3a2a217364edd7b9b/', '')}`));
  }

  // D2 Campos - try the /team page
  console.log('\n=== D2 Campos sjdistrict2.org /team ===');
  const resp2 = await fetch('https://www.sjdistrict2.org/team', {
    headers: { ...HEADERS, 'Referer': 'https://www.sjdistrict2.org/' }
  });
  console.log(`  Status: ${resp2.status}`);
  if (resp2.status === 200) {
    const html2 = await resp2.text();
    const re = /https:\/\/images\.squarespace-cdn\.com[^\s"'<>]+\.(?:jpg|jpeg|png)/gi;
    const imgs = new Set<string>();
    let m;
    while ((m = re.exec(html2)) !== null) imgs.add(m[0].split('?')[0]);
    console.log(`  Found ${imgs.size} images`);
    Array.from(imgs).filter(u => !/logo|map|banner|icon/i.test(u)).slice(0, 5).forEach(u =>
      console.log(`    ${u.replace('https://images.squarespace-cdn.com/content/v1/6942f53c3db83d0e41471664/', '')}`));
  }

  // Download D2 Campos sjdistrict2.org images to check dimensions
  console.log('\n=== D2 Campos image download and check ===');
  const campos_imgs = [
    'https://images.squarespace-cdn.com/content/v1/6942f53c3db83d0e41471664/80844ee0-5655-4a0e-95dd-159b9b23842c/Councilmember+Campos+and+Constituent.jpg',
    'https://images.squarespace-cdn.com/content/v1/6942f53c3db83d0e41471664/1778893297122-PZLKNOCKXWT85YDTDHYB/image-asset.jpeg',
  ];
  for (const [i, url] of campos_imgs.entries()) {
    console.log(`  Campos img ${i}:`);
    await downloadAndSave(`D2-Campos-${i}`, url);
    await new Promise(r => setTimeout(r, 200));
  }
}

main().catch(console.error);
