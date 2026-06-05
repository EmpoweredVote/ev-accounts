import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';

const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
};
const TMP_DIR = process.env.TEMP || 'C:/Windows/Temp';

// Download a squarespace image at higher quality
async function downloadSquarespace(name: string, url: string): Promise<string> {
  // Try to get max quality - remove format constraints
  const baseUrl = url.split('?')[0];
  const fullUrl = `${baseUrl}?format=original`;  // Try to get original quality
  const resp = await fetch(fullUrl, { headers: { ...HEADERS, 'Referer': url } });
  if (resp.status !== 200) {
    // Try without format
    const resp2 = await fetch(baseUrl, { headers: { ...HEADERS, 'Referer': url } });
    if (resp2.status !== 200) { console.log(`  ${name}: FAILED ${resp2.status}`); return ''; }
    const buf2 = Buffer.from(await resp2.arrayBuffer());
    const outFile = path.join(TMP_DIR, `sj-squarespace-${name}.jpg`);
    fs.writeFileSync(outFile, buf2);
    console.log(`  ${name}: ${buf2.length} bytes (no-format)`);
    return outFile;
  }
  const buf = Buffer.from(await resp.arrayBuffer());
  const outFile = path.join(TMP_DIR, `sj-squarespace-${name}.jpg`);
  fs.writeFileSync(outFile, buf);
  console.log(`  ${name}: ${buf.length} bytes`);
  return outFile;
}

async function scrapeSquarespaceForPortraits(name: string, siteUrl: string, contentId: string): Promise<void> {
  console.log(`\n=== ${name} from ${siteUrl} ===`);
  const resp = await fetch(siteUrl, { headers: { ...HEADERS, 'Referer': siteUrl }, redirect: 'follow' });
  if (resp.status !== 200) { console.log(`  Status: ${resp.status}`); return; }
  const html = await resp.text();

  // Find all high-res images (not thumbnails)
  // Squarespace serves at different formats. The original-size URL usually has format=1500w or original
  const dataImageRe = /data-image="(https:\/\/images\.squarespace-cdn\.com\/content\/v1\/${contentId}\/[^"]+\.(jpg|jpeg|png)[^"]*)"/gi;
  const dataSrcRe = /data-src="(https:\/\/images\.squarespace-cdn\.com\/content\/v1\/${contentId}\/[^"]+\.(jpg|jpeg|png)[^"]*)"/gi;
  const srcRe = /src="(https:\/\/images\.squarespace-cdn\.com\/content\/v1\/${contentId}\/[^"]+\.(jpg|jpeg|png)[^"]*)"/gi;

  const allImgs = new Set<string>();
  let m;
  for (const re of [dataImageRe, dataSrcRe, srcRe]) {
    while ((m = re.exec(html)) !== null) {
      const baseUrl = m[1].split('?')[0];
      allImgs.add(baseUrl);
    }
  }

  // Also search for JSON data-types
  const jsonRe = /"src":"(https:\/\/images\.squarespace-cdn\.com\/content\/v1\/${contentId}\/[^"]+\.(jpg|jpeg|png))"/g;
  while ((m = jsonRe.exec(html)) !== null) {
    allImgs.add(m[1].split('?')[0]);
  }

  console.log(`  Found ${allImgs.size} unique squarespace images`);

  // Download each non-logo image
  const toDownload: string[] = [];
  for (const img of allImgs) {
    const imgLower = img.toLowerCase();
    if (/logo|map|banner|icon|facebook|instagram|twitter|signature|email|youtube|nextdoor|award/i.test(imgLower)) continue;
    toDownload.push(img);
  }
  console.log(`  Non-logo images: ${toDownload.length}`);
  toDownload.slice(0, 8).forEach((u, i) => console.log(`    [${i}] ${u.replace('https://images.squarespace-cdn.com/content/v1/', '')}`));
}

async function main() {
  // D3 Tordillos - sjdistrict3.org
  await scrapeSquarespaceForPortraits('D3-Tordillos', 'https://www.sjdistrict3.org', '68dc1d398d83da7d0336165b');

  // D4 Cohen - sanjosedistrict4.com
  await scrapeSquarespaceForPortraits('D4-Cohen', 'https://www.sanjosedistrict4.com', '6201a5e40577d74133ad4cad');

  // D5 Ortiz - sjdistrict5.org
  await scrapeSquarespaceForPortraits('D5-Ortiz', 'https://www.sjdistrict5.org', '686ed8c3a2a217364edd7b9b');

  // D7 Doan - sjdistrict7.org
  await scrapeSquarespaceForPortraits('D7-Doan', 'https://www.sjdistrict7.org', '67e5a8b8296f5a5a0214b875');

  // D2 Campos - sjdistrict2.org
  await scrapeSquarespaceForPortraits('D2-Campos', 'https://www.sjdistrict2.org', '6942f53c3db83d0e41471664');

  // D8 Candelas - look for sjdistrict8.org or similar
  const candelas8 = await fetch('https://www.sjdistrict8.org', { headers: { ...HEADERS, 'Referer': 'https://www.sjdistrict8.org/' } });
  console.log('\nD8 Candelas sjdistrict8.org:', candelas8.status);

  // D10 Casey - sjdistrict10.org
  await scrapeSquarespaceForPortraits('D10-Casey', 'https://www.sjdistrict10.org', '67d36df71d3cca0e7ebe4c0e');
}

main().catch(console.error);
