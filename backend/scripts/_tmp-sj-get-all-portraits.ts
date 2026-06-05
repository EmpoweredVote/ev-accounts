import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';

const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Referer': 'https://www.sanjoseca.gov/',
};
const TMP_DIR = process.env.TEMP || 'C:/Windows/Temp';

async function findPortraitsOnPage(name: string, url: string): Promise<Array<{id:string,ts:string,size:number,file:string}>> {
  const resp = await fetch(url, { headers: HEADERS });
  if (resp.status !== 200) return [];
  const html = await resp.text();
  const re = /showpublishedimage\/(\d+)\/(\d+)/g;
  let m;
  const results: Array<{id:string,ts:string,size:number,file:string}> = [];
  while ((m = re.exec(html)) !== null) {
    const ctx = html.substring(Math.max(0, m.index - 200), Math.min(html.length, m.index + 200));
    if (/facebook|twitter|instagram|linkedin|youtube|nextdoor|email|calendar|IG Logo|Center for Digital/i.test(ctx)) continue;
    const imgUrl = `https://www.sanjoseca.gov/home/showpublishedimage/${m[1]}/${m[2]}`;
    const r = await fetch(imgUrl, { headers: HEADERS });
    if (r.status !== 200) continue;
    const buf = Buffer.from(await r.arrayBuffer());
    if (buf.length < 10000) continue; // Skip tiny icons
    const ct = r.headers.get('content-type') || '';
    const ext = ct.includes('png') ? 'png' : 'jpg';
    const outFile = path.join(TMP_DIR, `sj-official-${name}-${m[1]}.${ext}`);
    fs.writeFileSync(outFile, buf);
    results.push({ id: m[1], ts: m[2], size: buf.length, file: outFile });
    console.log(`  ${name} → ${m[1]}/${m[2]}: ${buf.length} bytes → ${outFile}`);
  }
  return results;
}

// Get Wikimedia full-res URL
async function getWikiUrl(filename: string): Promise<{url:string,license:string}> {
  const apiUrl = `https://commons.wikimedia.org/w/api.php?action=query&titles=File:${encodeURIComponent(filename)}&prop=imageinfo&iiprop=url|extmetadata&format=json`;
  const r = await fetch(apiUrl, { headers: HEADERS });
  const d: any = await r.json();
  for (const p of Object.values(d?.query?.pages || {}) as any[]) {
    return {
      url: p.imageinfo?.[0]?.url || '',
      license: p.imageinfo?.[0]?.extmetadata?.LicenseShortName?.value || ''
    };
  }
  return { url: '', license: '' };
}

async function downloadWiki(name: string, url: string, ext: string): Promise<string> {
  await new Promise(r => setTimeout(r, 2000));
  const resp = await fetch(url, {
    headers: { 'User-Agent': 'EmpoweredVote/1.0 (civic data; jmadison@empowered.vote)' }
  });
  if (resp.status !== 200) { console.log(`  ${name}: FAILED ${resp.status}`); return ''; }
  const buf = Buffer.from(await resp.arrayBuffer());
  const outFile = path.join(TMP_DIR, `sj-final-${name}.${ext}`);
  fs.writeFileSync(outFile, buf);
  console.log(`  ${name}: ${buf.length} bytes → ${outFile}`);
  return outFile;
}

async function main() {
  // Priority 1: sanjoseca.gov bio pages with higher-res portraits
  console.log('=== sanjoseca.gov bio pages ===');

  // Cohen D4 bio page was found
  await findPortraitsOnPage('D4-Cohen', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-4/david-cohen-biography');
  await new Promise(r => setTimeout(r, 300));

  // Check Kamei D1 more carefully (already found 18393 at 248980 bytes)
  console.log('\nKamei D1 bio page images:');
  const kameiResp = await fetch('https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-1/the-team/rosemary-kamei', { headers: HEADERS });
  const kameiHtml = await kameiResp.text();
  // Find all sanjoseca.gov images with context
  const re1 = /showpublishedimage\/(\d+)\/(\d+)/g;
  let m;
  while ((m = re1.exec(kameiHtml)) !== null) {
    const ctx = kameiHtml.substring(Math.max(0, m.index - 200), Math.min(kameiHtml.length, m.index + 200));
    if (/rosemary|kamei|headshot|councilmember|district.1|bio|portrait/i.test(ctx)) {
      const imgUrl = `https://www.sanjoseca.gov/home/showpublishedimage/${m[1]}/${m[2]}`;
      const r = await fetch(imgUrl, { headers: HEADERS });
      if (r.status === 200) {
        const buf = Buffer.from(await r.arrayBuffer());
        console.log(`  ${m[1]}: ${buf.length} bytes`);
      }
    }
  }
  await new Promise(r => setTimeout(r, 300));

  // For remaining officials, get Wikimedia originals
  console.log('\n=== Wikimedia originals ===');
  const wikiFiles = [
    { name: 'D2-Campos', file: 'Pamela Campos, San José City Councilmember.jpg', ext: 'jpg' },
    { name: 'D3-Tordillos', file: 'Anthony Tordillos.png', ext: 'png' },
    { name: 'D5-Ortiz', file: 'Peter Ortiz, San José City Councilman.png', ext: 'png' },
    { name: 'D7-Doan', file: 'Bien Doan, San José City Councilman.png', ext: 'png' },
    { name: 'D8-Candelas', file: 'Domingo Candelas, San José City Councilman.png', ext: 'png' },
    { name: 'D10-Casey', file: 'George Casey, San José City Councilman.png', ext: 'png' },
  ];

  // First get their actual full-res URLs
  for (const wf of wikiFiles) {
    const info = await getWikiUrl(wf.file);
    console.log(`\n${wf.name}: ${info.url} (${info.license})`);
    if (info.url) {
      await downloadWiki(wf.name, info.url, wf.ext);
    }
    await new Promise(r => setTimeout(r, 500));
  }

  // Mahan full-res from Wikimedia
  console.log('\nMahan Wikimedia:');
  await downloadWiki('Mayor-Mahan', 'https://upload.wikimedia.org/wikipedia/commons/a/ae/Matt_Mahan_portrait_2025.jpg', 'jpg');

  // Foley from Wikimedia
  console.log('\nFoley Wikimedia:');
  await downloadWiki('D9-Foley', 'https://upload.wikimedia.org/wikipedia/commons/1/11/Foley_Pam_-_San_Jos%C3%A9_City_Councilwoman.jpg', 'jpg');
}

main().catch(console.error);
