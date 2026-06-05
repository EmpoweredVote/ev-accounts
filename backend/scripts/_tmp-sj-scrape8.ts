import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import sharp from 'sharp';

const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Accept': '*/*',
};

const TMP_DIR = process.env.TEMP || 'C:/Windows/Temp';

async function getWikimediaFileInfo(filename: string): Promise<{url: string, license: string}> {
  const url = `https://commons.wikimedia.org/w/api.php?action=query&titles=File:${encodeURIComponent(filename)}&prop=imageinfo&iiprop=url|extmetadata&format=json`;
  const resp = await fetch(url, { headers: HEADERS });
  const data: any = await resp.json();
  const pages = data?.query?.pages;
  if (pages) {
    for (const p of Object.values(pages) as any[]) {
      const ii = p.imageinfo?.[0];
      return {
        url: ii?.url || '',
        license: ii?.extmetadata?.LicenseShortName?.value || 'unknown'
      };
    }
  }
  return { url: '', license: '' };
}

async function downloadAndCheckDimensions(url: string, name: string): Promise<void> {
  console.log(`\nChecking: ${name}`);
  console.log(`  URL: ${url}`);
  try {
    const resp = await fetch(url, { headers: { ...HEADERS, 'Referer': url } });
    if (resp.status !== 200) { console.log(`  FAILED: ${resp.status}`); return; }
    const buf = Buffer.from(await resp.arrayBuffer());
    console.log(`  Downloaded: ${buf.length} bytes`);

    // Use sharp to check dimensions
    const meta = await sharp(buf).metadata();
    console.log(`  Dimensions: ${meta.width}x${meta.height} (${meta.format})`);
    const ratio = (meta.height || 0) / (meta.width || 1);
    console.log(`  Aspect ratio: ${ratio.toFixed(2)} (${ratio > 1 ? 'portrait' : ratio < 0.9 ? 'landscape/banner' : 'square'})`);

    // Save for visual inspection
    const tmpFile = path.join(TMP_DIR, `sj-check-${name.replace(/[^a-z0-9]/gi, '-')}.jpg`);
    await sharp(buf).jpeg({ quality: 85 }).toFile(tmpFile);
    console.log(`  Saved: ${tmpFile}`);
  } catch (err: any) {
    console.log(`  ERROR: ${err.message}`);
  }
}

async function main() {
  // Get Ortiz Wikimedia URL
  const ortizInfo = await getWikimediaFileInfo('Peter Ortiz, San José City Councilman.png');
  console.log('\n=== Ortiz Wikimedia ===');
  console.log(`  URL: ${ortizInfo.url}`);
  console.log(`  License: ${ortizInfo.license}`);

  // Check D3 Tordillos "Website Landing Image" - is it a portrait or banner?
  await downloadAndCheckDimensions(
    'https://images.squarespace-cdn.com/content/v1/68dc1d398d83da7d0336165b/265abb99-2103-4102-83ed-303e5b4034e3/Website+Landing+Image.png',
    'Tordillos-landing'
  );

  // Check D2 Campos - try the most recent images which may be event photos
  // Let me get the Campos sanjoseca.gov portrait page
  const camposResp = await fetch('https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-2/councilmember-pamela-campos-biography', {
    headers: { ...HEADERS, 'Referer': 'https://www.sanjoseca.gov/' }
  });
  const camposHtml = await camposResp.text();
  console.log('\n=== Campos D2 sanjoseca.gov biography page ===');
  console.log('Status:', camposResp.status);
  // Find any images
  const imgRe = /showpublishedimage\/(\d+)\/(\d+)/g;
  let m;
  const imgs: string[] = [];
  while ((m = imgRe.exec(camposHtml)) !== null) {
    const ctx = camposHtml.substring(Math.max(0, m.index - 300), Math.min(camposHtml.length, m.index + 200));
    if (!/facebook|twitter|instagram|linkedin|youtube|nextdoor|IG Logo|Center for Digital/i.test(ctx)) {
      imgs.push(`  ${m[1]}/${m[2]}: ${ctx.replace(/\s+/g, ' ').substring(0,200)}`);
    }
  }
  if (imgs.length > 0) imgs.forEach(i => console.log(i));
  else console.log('  No portrait images found on biography page');

  // Also check squarespace images
  const sqRe = /squarespace-cdn\.com\/content\/v1\/6942f53c3db83d0e41471664\/[^\s"'?]+\.(jpg|jpeg|png)/gi;
  const sqImgs = new Set<string>();
  while ((m = sqRe.exec(camposHtml)) !== null) sqImgs.add('https://' + m[0]);
  if (sqImgs.size > 0) {
    console.log('  Squarespace images:');
    Array.from(sqImgs).slice(0, 5).forEach(u => console.log('  ', u));
  }

  // Check sjdistrict2.org about/bio pages
  for (const path of ['/councilmember', '/bio', '/councilmember-campos', '/pamela-campos']) {
    const r = await fetch(`https://www.sjdistrict2.org${path}`, {
      headers: { ...HEADERS, 'Referer': 'https://www.sjdistrict2.org/' },
      redirect: 'follow'
    });
    if (r.status === 200) {
      const h = await r.text();
      const sqRe2 = /data-src="(https:\/\/images\.squarespace-cdn\.com\/content\/v1\/6942f53c3db83d0e41471664\/[^"]+\.(jpg|jpeg|png))"/gi;
      const found: string[] = [];
      let m2;
      while ((m2 = sqRe2.exec(h)) !== null) {
        if (!/logo|map|banner|icon|email|signature/i.test(m2[1])) found.push(m2[1]);
      }
      if (found.length > 0) {
        console.log(`\n  sjdistrict2.org${path}:`);
        found.slice(0, 5).forEach(u => console.log('  ', u.replace('https://images.squarespace-cdn.com', '')));
      }
    }
    await new Promise(resolve => setTimeout(resolve, 200));
  }
}

main().catch(console.error);
