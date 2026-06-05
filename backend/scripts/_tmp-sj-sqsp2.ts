import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';

const TMP_DIR = process.env.TEMP || 'C:/Windows/Temp';
const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
};

async function downloadImg(name: string, url: string): Promise<{file:string,size:number}|null> {
  const resp = await fetch(url, { headers: { ...HEADERS, 'Referer': url } });
  if (resp.status !== 200) return null;
  const buf = Buffer.from(await resp.arrayBuffer());
  const ext = url.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
  const outFile = path.join(TMP_DIR, `sj-sqsp-${name}.${ext}`);
  fs.writeFileSync(outFile, buf);
  return { file: outFile, size: buf.length };
}

async function findPortraitsOnPage(name: string, siteUrl: string): Promise<void> {
  console.log(`\n=== ${name} (${siteUrl}) ===`);
  const resp = await fetch(siteUrl, { headers: { ...HEADERS, 'Referer': siteUrl }, redirect: 'follow' });
  if (resp.status !== 200) { console.log(`  Status: ${resp.status}`); return; }
  const html = await resp.text();

  // Simple regex - find any squarespace image URL
  const re = /https:\/\/images\.squarespace-cdn\.com\/content\/v1\/[a-f0-9]+\/[^\s"'<>]+\.(jpg|jpeg|png)/gi;
  const allUrls = new Set<string>();
  let m;
  while ((m = re.exec(html)) !== null) {
    const url = m[0].split('?')[0]; // Remove query params
    allUrls.add(url);
  }

  // Also find static1.squarespace.com
  const re2 = /https?:\/\/static1\.squarespace\.com\/static\/[^\s"'<>]+\.(jpg|jpeg|png)/gi;
  while ((m = re2.exec(html)) !== null) {
    allUrls.add(m[0].split('?')[0]);
  }

  const filtered = Array.from(allUrls).filter(u =>
    !/logo|map|banner|icon|favicon|signature|email|youtube|nextdoor|award|certificate/i.test(u)
  );
  console.log(`  ${allUrls.size} total images, ${filtered.length} non-logo`);
  filtered.slice(0, 8).forEach((u, i) => {
    const shortU = u.replace('https://images.squarespace-cdn.com/content/v1/', '').replace('https://static1.squarespace.com/static/', '');
    console.log(`    [${i}] ${shortU}`);
  });
}

// D8 Candelas - check sjdistrict8.org
async function checkCandelas(): Promise<void> {
  console.log('\n=== D8 Candelas sjdistrict8.org ===');
  const resp = await fetch('https://www.sjdistrict8.org', {
    headers: { ...HEADERS, 'Referer': 'https://www.sjdistrict8.org/' },
    redirect: 'follow'
  });
  console.log(`Status: ${resp.status}, URL: ${resp.url}`);
  if (resp.status !== 200) return;
  const html = await resp.text();
  // Find any images
  const re = /src="([^"]+\.(jpg|jpeg|png))[^"]*"/gi;
  let m;
  while ((m = re.exec(html)) !== null) {
    if (!/logo|banner|icon/i.test(m[1])) console.log(`  ${m[1].substring(0, 150)}`);
  }
}

async function main() {
  await findPortraitsOnPage('D2-Campos', 'https://www.sjdistrict2.org');
  await findPortraitsOnPage('D3-Tordillos', 'https://www.sjdistrict3.org');
  await findPortraitsOnPage('D4-Cohen', 'https://www.sanjosedistrict4.com');
  await findPortraitsOnPage('D5-Ortiz', 'https://www.sjdistrict5.org');
  await findPortraitsOnPage('D7-Doan', 'https://www.sjdistrict7.org');
  await findPortraitsOnPage('D10-Casey', 'https://www.sjdistrict10.org');
  await checkCandelas();
}

main().catch(console.error);
